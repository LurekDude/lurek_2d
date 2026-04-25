-- @module library.rpc
--- @status full
--- @description Pure-Lua Remote Procedure Call library built on `lurek.network`.
--- Enables calling functions on remote peers over ENet with automatic
--- JSON serialisation via `lurek.serial`. Supports request/response,
--- fire-and-forget, and broadcast patterns.
--- @see lurek.network
--- @see lurek.serial.toJson
--- @see lurek.serial.fromJson
---
--- ## RPC Protocol
---
--- Messages are serialised via `lurek.serial.toJson` / `lurek.serial.fromJson`.
--- Three message types flow over the wire:
---
--- - **rpc_call**: `{type="rpc_call", id=N, name="fn", args={...}}`
---   Sender expects an `rpc_response` back with the matching `id`.
--- - **rpc_response**: `{type="rpc_response", id=N, success=bool, result={...}}`
---   Returned by the callee after executing the handler for `rpc_call`.
--- - **rpc_notify**: `{type="rpc_notify", name="fn", args={...}, peer_id=N}`
---   Fire-and-forget; no response is sent back. `peer_id` is included so
---   broadcast handlers can identify the originator.
---
--- ## Error Handling
---
--- Set a global error callback via `onError(fn)`. The callback receives a
--- single string describing the error context (includes the method name when
--- available). Handler exceptions during `rpc_call` are caught and sent back
--- as `{success=false, result={error_string}}` to the caller.
---
--- ## Request ID Limits
---
--- The internal request ID counter is a Lua number. In LuaJIT (double-
--- precision float) integers are exact up to 2^53. Call `resetIdCounter()`
--- to reset to 1 if your application may exceed this range.

local M = {}

-- LuaJIT exposes `unpack` as a global; Lua 5.4 only via `table.unpack`.
-- Cache once at module load so per-call dispatch stays branchless.
local _unpack = table.unpack or unpack

-- Encode/decode helpers: prefer `lurek.serial.toJson/fromJson` (per P1 map);
-- fall back to `lurek.network.pack/unpack` (MessagePack) when codec is
-- unavailable in the host VM (e.g. headless test contexts).
local function _encode(t)
    if lurek and lurek.serial and lurek.serial.toJson then
        return lurek.serial.toJson(t)
    end
    return lurek.network.pack(t)
end
local function _decode(s)
    if lurek and lurek.serial and lurek.serial.fromJson then
        return lurek.serial.fromJson(s)
    end
    return lurek.network.unpack(s)
end

--- Default timeout for pending RPC responses (seconds). 0 = no timeout.
-- @field DEFAULT_TIMEOUT number
M.DEFAULT_TIMEOUT = 30

---------------------------------------------------------------------------
-- RPC Manager
---------------------------------------------------------------------------

local RPC = {}
RPC.__index = RPC

--- Create a new RPC manager attached to a NetworkHost.
--- @tparam userdata host  A `lurek.network.newHost/newServer/newClient` host.
--- @tparam[opt=0] number channel  The ENet channel used for RPC traffic.
--- @tparam[opt=30] number timeout  Default timeout in seconds for pending calls. 0 = no timeout.
--- @treturn RPC  A new RPC manager instance.
function M.new(host, channel, timeout)
    if timeout ~= nil and (type(timeout) ~= "number" or timeout < 0) then
        error("RPC.new: timeout must be a non-negative number", 2)
    end
    local self = setmetatable({}, RPC)
    self._host      = host
    self._channel   = channel or 0
    self._handlers  = {}
    self._pending   = {}   -- id → {callback, method, expires}
    self._next_id   = 1
    self._on_error  = nil
    self._timeout   = timeout or M.DEFAULT_TIMEOUT
    self._log       = false
    return self
end

--- Enable or disable debug logging via `lurek.log`.
--- When enabled, RPC calls, responses, and errors are logged at debug level.
--- @tparam boolean enabled  `true` to enable, `false` to disable.
function RPC:setLogging(enabled)
    self._log = (enabled == true)
end

--- Register a function callable from remote peers.
--- @tparam string name   Unique RPC function name.
--- @tparam function fn   Handler: `fn(peer_id, arg1, arg2, ...)` → returns results.
function RPC:register(name, fn)
    if type(name) ~= "string" or name == "" then
        error("RPC:register: name must be a non-empty string", 2)
    end
    if type(fn) ~= "function" then
        error("RPC:register: fn must be a function", 2)
    end
    self._handlers[name] = fn
end

--- Unregister a previously registered function.
--- @tparam string name  The RPC function name to remove.
function RPC:unregister(name)
    self._handlers[name] = nil
end

--- Set a global error handler for RPC processing errors.
--- The callback receives a single string that includes error context
--- (method name, peer ID) when available.
--- @tparam function fn  `fn(error_string)` — called on RPC processing errors.
function RPC:onError(fn)
    if fn ~= nil and type(fn) ~= "function" then
        error("RPC:onError: fn must be a function or nil", 2)
    end
    self._on_error = fn
end

--- Call a function on a specific remote peer (request/response pattern).
--- When a matching `rpc_response` arrives in `poll()`, the `callback` is
--- invoked with `(success, result_table)`.
--- @tparam number peer_id  Target peer.
--- @tparam string name     Function name registered on the remote side.
--- @tparam function callback  `fn(success, result)` — called when the response arrives.
--- @param ... any           Arguments (must be MessagePack-serializable).
--- @treturn number          Request ID for the pending call.
function RPC:call(peer_id, name, callback, ...)
    if type(name) ~= "string" or name == "" then
        error("RPC:call: name must be a non-empty string", 2)
    end
    if type(callback) ~= "function" then
        error("RPC:call: callback must be a function", 2)
    end
    local id = self._next_id
    self._next_id = self._next_id + 1
    local expires = 0
    if self._timeout > 0 then
        expires = os.clock() + self._timeout
    end
    self._pending[id] = {
        callback = callback,
        method   = name,
        expires  = expires,
    }
    local msg = _encode({
        type = "rpc_call",
        id   = id,
        name = name,
        args = { ... },
    })
    self._host:send(peer_id, self._channel, msg, true)
    if self._log and lurek.log then
        lurek.log.debug("[RPC] call id=" .. tostring(id) .. " method=" .. name .. " peer=" .. tostring(peer_id))
    end
    return id
end

--- Fire-and-forget call: no response expected.
--- Includes `peer_id` in the wire message so broadcast handlers on the
--- receiving side can identify the originator.
--- @tparam number peer_id  Target peer.
--- @tparam string name     Function name registered on the remote side.
--- @param ... any           Arguments (must be MessagePack-serializable).
function RPC:notify(peer_id, name, ...)
    if type(name) ~= "string" or name == "" then
        error("RPC:notify: name must be a non-empty string", 2)
    end
    local msg = _encode({
        type    = "rpc_notify",
        name    = name,
        args    = { ... },
        peer_id = peer_id,
    })
    self._host:send(peer_id, self._channel, msg, true)
    if self._log and lurek.log then
        lurek.log.debug("[RPC] notify method=" .. name .. " peer=" .. tostring(peer_id))
    end
end

--- Broadcast an RPC call to all connected peers (fire-and-forget).
--- Includes `peer_id = 0` in the wire message (server/broadcast origin).
--- @tparam string name  Function name registered on remote peers.
--- @param ... any        Arguments (must be MessagePack-serializable).
function RPC:broadcast(name, ...)
    if type(name) ~= "string" or name == "" then
        error("RPC:broadcast: name must be a non-empty string", 2)
    end
    local msg = _encode({
        type    = "rpc_notify",
        name    = name,
        args    = { ... },
        peer_id = 0,
    })
    self._host:broadcast(self._channel, msg, true)
    if self._log and lurek.log then
        lurek.log.debug("[RPC] broadcast method=" .. name)
    end
end

--- Reset the internal request ID counter back to 1.
--- Useful for long-running servers to avoid exceeding the 2^53 integer
--- precision limit of Lua numbers (LuaJIT doubles).
--- **Warning**: Only call this when no pending calls are in flight.
function RPC:resetIdCounter()
    self._next_id = 1
end

--- Get the current request ID counter value.
--- @treturn number  The next ID that will be assigned.
function RPC:getNextId()
    return self._next_id
end

--- Get the number of pending (unresolved) RPC calls.
--- @treturn number
function RPC:getPendingCount()
    local n = 0
    for _ in pairs(self._pending) do n = n + 1 end
    return n
end

--- Set the timeout for future pending calls (seconds). 0 = no timeout.
--- @tparam number seconds  Timeout in seconds. Must be >= 0.
function RPC:setTimeout(seconds)
    if type(seconds) ~= "number" or seconds < 0 then
        error("RPC:setTimeout: seconds must be a non-negative number", 2)
    end
    self._timeout = seconds
end

--- Process incoming RPC messages. Call once per frame in `lurek.process(dt)`.
--- Dispatches received RPC calls to registered handlers and invokes pending
--- call callbacks when matching responses arrive. Also expires timed-out
--- pending calls.
--- @treturn table  Array of `{id, success, result}` response tables (may be empty).
function RPC:poll()
    local responses = {}
    local ev = self._host:service()
    while ev do
        if ev.type == "receive" then
            local ok, data = pcall(_decode, ev.data)
            if ok and type(data) == "table" then
                self:_dispatch(ev.peer, data, responses)
            elseif self._on_error then
                self._on_error("RPC: failed to unpack message from peer " .. tostring(ev.peer))
            end
        end
        ev = self._host:service()
    end
    self:_expireTimeouts()
    return responses
end

--- Internal: expire pending calls that have exceeded their timeout.
function RPC:_expireTimeouts()
    local now = os.clock()
    local expired = {}
    for id, entry in pairs(self._pending) do
        if entry.expires > 0 and now >= entry.expires then
            expired[#expired + 1] = id
        end
    end
    for _, id in ipairs(expired) do
        local entry = self._pending[id]
        self._pending[id] = nil
        if entry.callback then
            entry.callback(false, { "RPC timeout for method '" .. entry.method .. "'" })
        end
        if self._on_error then
            self._on_error("RPC: timeout for call id=" .. id .. " method='" .. entry.method .. "'")
        end
        if self._log and lurek.log then
            lurek.log.debug("[RPC] timeout id=" .. id .. " method=" .. entry.method)
        end
    end
end

--- Internal: dispatch a decoded RPC message.
--- @tparam number peer_id  The originating peer.
--- @tparam table data  Decoded message table.
--- @tparam table responses  Accumulator for response entries.
function RPC:_dispatch(peer_id, data, responses)
    if data.type == "rpc_call" and data.name then
        local handler = self._handlers[data.name]
        if handler then
            -- `_unpack` resolves to `table.unpack` on Lua 5.4 (where bare
            -- `unpack` is removed) and to the global `unpack` on LuaJIT.
            local result = { pcall(handler, peer_id, _unpack(data.args or {})) }
            local success = table.remove(result, 1)
            if data.id and data.id > 0 then
                local resp = _encode({
                    type    = "rpc_response",
                    id      = data.id,
                    success = success,
                    result  = result,
                })
                self._host:send(peer_id, self._channel, resp, true)
            end
            if self._log and lurek.log then
                lurek.log.debug("[RPC] handled call method=" .. data.name .. " success=" .. tostring(success))
            end
        elseif self._on_error then
            self._on_error("RPC: no handler for '" .. tostring(data.name) .. "'")
        end
    elseif data.type == "rpc_notify" and data.name then
        local handler = self._handlers[data.name]
        if handler then
            local ok, err = pcall(handler, peer_id, _unpack(data.args or {}))
            if not ok and self._on_error then
                self._on_error("RPC notify error in '" .. tostring(data.name) .. "': " .. tostring(err))
            end
        end
    elseif data.type == "rpc_response" then
        local entry = self._pending[data.id]
        if entry then
            self._pending[data.id] = nil
            if entry.callback then
                entry.callback(data.success, data.result)
            end
            if self._log and lurek.log then
                lurek.log.debug("[RPC] response id=" .. tostring(data.id) .. " success=" .. tostring(data.success))
            end
        end
        table.insert(responses, {
            id      = data.id,
            success = data.success,
            result  = data.result,
        })
    end
end

--- Get the number of registered RPC handlers.
--- @treturn number
function RPC:getHandlerCount()
    local n = 0
    for _ in pairs(self._handlers) do n = n + 1 end
    return n
end

return M
