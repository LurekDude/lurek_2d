--- @module library.netstate
--- @description Pure-Lua network state synchronization and turn-based game support.
--- Built on `lurek.network`, provides automatic state replication between peers
--- with per-key versioning, change callbacks, authority control, delta updates,
--- and turn-based game management.
---
--- **Authority model**: One peer is the *authority* (typically the server).
--- Only the authority can write state via `set()`. Non-authority peers receive
--- delta updates and full-state snapshots. Authority is set at construction
--- and can be toggled with `setAuthority()`.
---
--- **Per-key versioning**: Each key maintains its own monotonically increasing
--- version number. When a delta arrives, only entries whose version exceeds
--- the locally stored per-key version are applied — preventing stale replays
--- even under concurrent updates.
---
--- **Turn-based protocol**: Optional. When `turnBased = true`, the authority
--- manages a turn counter and a rotating peer order. `beginTurn()` advances
--- the turn and broadcasts the change. Clients receive turn events via `onTurn`.
---
--- **Limitation**: `requestFullState()` has no built-in timeout. If the authority
--- never responds, the client will not receive a snapshot. Callers should
--- implement their own timer-based retry or use `onFullStateTimeout` callback.
local M = {}

---------------------------------------------------------------------------
-- Optional logging via lurek.log (if available)
---------------------------------------------------------------------------

local _log_enabled = false
local _log_fn = nil

--- Enable or disable debug logging.
--- When enabled, state changes, authority violations, sync events, and turn
--- changes are logged via `lurek.log.debug` (if available) or a custom function.
--- @tparam boolean enabled  Whether to enable logging.
--- @tparam[opt] function custom_log  Optional `fn(msg)` override. If nil, uses
---   `lurek.log.debug` when available, otherwise logging is silently skipped.
function M.setLogging(enabled, custom_log)
    _log_enabled = enabled
    if custom_log and type(custom_log) == "function" then
        _log_fn = custom_log
    elseif enabled then
        -- Try lurek.log.debug if available
        local ok = pcall(function()
            if lurek and lurek.log and type(lurek.log.debug) == "function" then
                _log_fn = function(msg) lurek.log.debug("[netstate] " .. msg) end
            end
        end)
        if not ok or not _log_fn then
            _log_fn = nil  -- silently skip if unavailable
        end
    else
        _log_fn = nil
    end
end

local function _log(msg)
    if _log_enabled and _log_fn then
        _log_fn(msg)
    end
end

---------------------------------------------------------------------------
-- NetState Manager
---------------------------------------------------------------------------

local NetState = {}
NetState.__index = NetState

--- Create a new network state synchronization manager.
---
--- The `host` parameter is a `lurek.network` host (server, client, or host).
--- If `opts.authority` is not provided, authority defaults to `host:isServer()`
--- when the host supports it, otherwise `false`.
---
--- @tparam userdata|nil host  A `lurek.network.newHost/newServer/newClient` host,
---   or nil for offline/testing mode (network operations become no-ops).
--- @tparam[opt] table opts  Configuration options:
---   - `channel` (number, default 0): Network channel for messages.
---   - `authority` (boolean): Override authority detection.
---   - `turnBased` (boolean, default false): Enable turn-based protocol.
---   - `maxDirtyKeys` (number|nil): Maximum number of dirty keys tracked per
---     sync cycle. When exceeded, oldest dirty keys are evicted. Nil = unlimited.
--- @treturn NetState  A new NetState manager instance.
function M.new(host, opts)
    local self = setmetatable({}, NetState)
    self._host    = host
    self._channel = (opts and type(opts.channel) == "number") and opts.channel or 0

    -- Authority: explicit opt > host:isServer() > false
    if opts and opts.authority ~= nil then
        self._authority = not not opts.authority
    elseif host and type(host.isServer) == "function" then
        self._authority = host:isServer()
    else
        self._authority = false
    end

    self._state     = {}   -- { key = { value, version, owner } }
    self._callbacks  = {}   -- { key = { fn, ... } }
    self._dirty      = {}   -- keys changed since last sync
    self._dirty_order = {}  -- insertion-order list for maxDirtyKeys eviction
    self._max_dirty  = (opts and type(opts.maxDirtyKeys) == "number" and opts.maxDirtyKeys > 0)
                       and opts.maxDirtyKeys or nil
    self._on_change  = nil  -- global change callback

    -- Turn-based support
    self._turn_based   = (opts and opts.turnBased) or false
    self._current_turn = 0
    self._turn_peer    = nil
    self._turn_order   = {}  -- { peer_id, peer_id, ... }
    self._turn_index   = 1
    self._on_turn      = nil

    -- Full-state request timeout callback
    self._on_full_state_timeout = nil

    _log("created, authority=" .. tostring(self._authority)
         .. " channel=" .. tostring(self._channel)
         .. " turnBased=" .. tostring(self._turn_based))
    return self
end

--- Set whether this instance is the authority (can write state).
--- @tparam boolean auth  True to grant authority, false to revoke.
function NetState:setAuthority(auth)
    if type(auth) ~= "boolean" then return end
    local old = self._authority
    self._authority = auth
    if old ~= auth then
        _log("authority changed: " .. tostring(old) .. " -> " .. tostring(auth))
    end
end

--- Check if this instance is the authority.
--- @treturn boolean  True if this peer is the authority.
function NetState:isAuthority()
    return self._authority
end

--- Set a global change callback fired for any key change.
--- @tparam function fn  Callback signature: `fn(key, value, old_value, peer_id)`.
function NetState:onChange(fn)
    if fn ~= nil and type(fn) ~= "function" then return end
    self._on_change = fn
end

--- Register a callback invoked if a full-state request times out.
--- The caller is responsible for implementing timer logic and calling this
--- callback from their own timeout handler.
--- @tparam function fn  Callback signature: `fn()`.
function NetState:onFullStateTimeout(fn)
    if fn ~= nil and type(fn) ~= "function" then return end
    self._on_full_state_timeout = fn
end

-- -----------------------------------------------------------------------
-- State access
-- -----------------------------------------------------------------------

--- Set a synced value. Only the authority can set values.
--- Non-authority calls are rejected and return `false, "not authority"`.
--- Keys must be non-empty strings.
--- @tparam string key  The state key (must be a non-empty string).
--- @param value  Any MessagePack-serializable value.
--- @treturn boolean  True if the value was set successfully.
--- @treturn string|nil  Error message on failure.
function NetState:set(key, value)
    if type(key) ~= "string" or key == "" then
        return false, "key must be a non-empty string"
    end
    if not self._authority then
        _log("set rejected (not authority): key=" .. key)
        return false, "not authority"
    end

    local entry = self._state[key]
    local old_value = entry and entry.value or nil
    local old_version = entry and entry.version or 0

    -- Per-key versioning: increment the key's own version
    local new_version = old_version + 1
    self._state[key] = {
        value   = value,
        version = new_version,
        owner   = 0,  -- local authority
    }
    self:_markDirty(key)

    -- Fire callbacks
    self:_fireCallbacks(key, value, old_value, 0)
    _log("set: key=" .. key .. " version=" .. tostring(new_version))
    return true
end

--- Get the current value of a synced key.
--- @tparam string key  The state key.
--- @treturn any|nil  The value, or nil if not set.
function NetState:get(key)
    if type(key) ~= "string" then return nil end
    local entry = self._state[key]
    return entry and entry.value or nil
end

--- Get the per-key version number.
--- @tparam string key  The state key.
--- @treturn number  The version for this key, or 0 if not set.
function NetState:getKeyVersion(key)
    if type(key) ~= "string" then return 0 end
    local entry = self._state[key]
    return entry and entry.version or 0
end

--- Get all synced state as a flat table.
--- @treturn table  `{ key = value, ... }` snapshot of current state.
function NetState:getAll()
    local t = {}
    for key, entry in pairs(self._state) do
        t[key] = entry.value
    end
    return t
end

--- Register a callback for changes to a specific key.
--- @tparam string key  The state key to watch.
--- @tparam function fn  Callback signature: `fn(value, old_value, peer_id)`.
function NetState:onChanged(key, fn)
    if type(key) ~= "string" or key == "" then return end
    if type(fn) ~= "function" then return end
    if not self._callbacks[key] then
        self._callbacks[key] = {}
    end
    table.insert(self._callbacks[key], fn)
end

--- Remove all callbacks for a key.
--- @tparam string key  The state key.
function NetState:clearCallbacks(key)
    if type(key) ~= "string" then return end
    self._callbacks[key] = nil
end

--- Get the highest version number across all keys.
--- @treturn number  The maximum per-key version, or 0 if no state exists.
function NetState:getVersion()
    local max_v = 0
    for _, entry in pairs(self._state) do
        if entry.version > max_v then max_v = entry.version end
    end
    return max_v
end

--- Get the number of synced keys.
--- @treturn number  Count of keys in the state table.
function NetState:getKeyCount()
    local n = 0
    for _ in pairs(self._state) do n = n + 1 end
    return n
end

--- Get the number of dirty (unsent) keys.
--- @treturn number  Count of keys pending sync.
function NetState:getDirtyCount()
    local n = 0
    for _ in pairs(self._dirty) do n = n + 1 end
    return n
end

--- Check if a key exists in the state.
--- @tparam string key  The state key.
--- @treturn boolean  True if the key has been set.
function NetState:hasKey(key)
    if type(key) ~= "string" then return false end
    return self._state[key] ~= nil
end

--- Remove a key from the synced state. Authority only.
--- @tparam string key  The state key to remove.
--- @treturn boolean  True if the key was removed.
--- @treturn string|nil  Error message on failure.
function NetState:remove(key)
    if type(key) ~= "string" or key == "" then
        return false, "key must be a non-empty string"
    end
    if not self._authority then
        return false, "not authority"
    end
    if not self._state[key] then
        return false, "key not found"
    end
    local old_value = self._state[key].value
    self._state[key] = nil
    self:_markDirty(key)
    self:_fireCallbacks(key, nil, old_value, 0)
    _log("remove: key=" .. key)
    return true
end

-- -----------------------------------------------------------------------
-- Turn-based support
-- -----------------------------------------------------------------------

--- Set the turn order (array of peer IDs).
--- Resets the turn index to 1 and turn counter to 0.
--- @tparam table order  Array of peer IDs: `{ peer_id_1, peer_id_2, ... }`.
---   Each element must be a number. Invalid entries are silently filtered.
function NetState:setTurnOrder(order)
    if type(order) ~= "table" then return end
    local valid = {}
    for _, v in ipairs(order) do
        if type(v) == "number" then
            valid[#valid + 1] = v
        end
    end
    self._turn_order = valid
    self._turn_index = 1
    self._current_turn = 0
    self._turn_peer = nil
    _log("setTurnOrder: " .. tostring(#valid) .. " peers")
end

--- Begin a new turn. Advances to the next player in the turn order.
--- Only the authority should call this. If the turn order is empty,
--- the turn counter advances but `turn_peer` remains nil.
--- @treturn number  The new turn number.
--- @treturn number|nil  The peer whose turn it is, or nil if order is empty.
function NetState:beginTurn()
    if not self._authority then return self._current_turn, self._turn_peer end

    self._current_turn = self._current_turn + 1

    if #self._turn_order > 0 then
        -- Clamp index to valid range (defensive, in case order was resized)
        if self._turn_index < 1 or self._turn_index > #self._turn_order then
            self._turn_index = 1
        end
        self._turn_peer = self._turn_order[self._turn_index]
        self._turn_index = self._turn_index + 1
        if self._turn_index > #self._turn_order then
            self._turn_index = 1
        end
    else
        -- Empty turn order: peer is nil (guarded)
        self._turn_peer = nil
    end

    -- Broadcast turn change
    self:_broadcastTurn()

    if self._on_turn then
        self._on_turn(self._current_turn, self._turn_peer)
    end

    _log("beginTurn: turn=" .. tostring(self._current_turn)
         .. " peer=" .. tostring(self._turn_peer))
    return self._current_turn, self._turn_peer
end

--- End the current turn. Alias for `beginTurn()` — advances to next.
--- @treturn number  The new turn number.
--- @treturn number|nil  The peer whose turn it is.
function NetState:endTurn()
    return self:beginTurn()
end

--- Get the current turn number.
--- @treturn number  The current turn counter value.
function NetState:getCurrentTurn()
    return self._current_turn
end

--- Get the peer ID whose turn it currently is.
--- @treturn number|nil  The current turn peer, or nil if not set.
function NetState:getTurnPeer()
    return self._turn_peer
end

--- Register a callback for turn changes.
--- @tparam function fn  Callback signature: `fn(turn_number, peer_id)`.
function NetState:onTurn(fn)
    if fn ~= nil and type(fn) ~= "function" then return end
    self._on_turn = fn
end

--- Check if it is a specific peer's turn.
--- @tparam number peer_id  The peer to check.
--- @treturn boolean  True if it is this peer's turn.
function NetState:isTurn(peer_id)
    if type(peer_id) ~= "number" then return false end
    return self._turn_peer == peer_id
end

-- -----------------------------------------------------------------------
-- Sync: call once per frame
-- -----------------------------------------------------------------------

--- Broadcast all dirty state to connected peers.
--- Call once per frame after all `set()` calls (e.g. at end of `lurek.process(dt)`).
--- Requires a valid host; no-op if host is nil or instance is not authority.
function NetState:sync()
    if not self._authority then return end
    if not self._host then return end

    local dirty_count = 0
    for _ in pairs(self._dirty) do dirty_count = dirty_count + 1 end
    if dirty_count == 0 then return end

    -- Build delta update
    local delta = {}
    for key in pairs(self._dirty) do
        local entry = self._state[key]
        if entry then
            delta[key] = { value = entry.value, version = entry.version }
        else
            -- Key was removed
            delta[key] = { value = nil, version = 0, removed = true }
        end
    end

    local pack_fn = lurek and lurek.network and lurek.network.pack
    if not pack_fn then return end

    local msg = pack_fn({
        type   = "netstate",
        action = "delta",
        delta  = delta,
    })
    self._host:broadcast(self._channel, msg, true)

    self._dirty = {}
    self._dirty_order = {}
    _log("sync: sent " .. tostring(dirty_count) .. " dirty keys")
end

--- Process incoming state updates from the network. Call once per frame.
--- Requires a valid host; returns empty table if host is nil.
--- @treturn table  Array of `{ key, value, old_value, peer_id }` change events.
function NetState:poll()
    local changes = {}
    if not self._host then return changes end

    local ev = self._host:service()
    while ev do
        if ev.type == "receive" then
            local unpack_fn = lurek and lurek.network and lurek.network.unpack
            if unpack_fn then
                local ok, data = pcall(unpack_fn, ev.data)
                if ok and type(data) == "table" and data.type == "netstate" then
                    self:_handle(ev.peer, data, changes)
                end
            end
        end
        ev = self._host:service()
    end
    return changes
end

-- -----------------------------------------------------------------------
-- Internals
-- -----------------------------------------------------------------------

--- Mark a key as dirty, respecting the maxDirtyKeys limit.
--- @tparam string key  The key to mark dirty.
function NetState:_markDirty(key)
    if not self._dirty[key] then
        self._dirty[key] = true
        self._dirty_order[#self._dirty_order + 1] = key

        -- Enforce max dirty keys limit by evicting oldest
        if self._max_dirty and #self._dirty_order > self._max_dirty then
            local evict = table.remove(self._dirty_order, 1)
            self._dirty[evict] = nil
            _log("dirty evicted (maxDirtyKeys): " .. evict)
        end
    end
end

function NetState:_handle(peer_id, data, changes)
    if data.action == "delta" and not self._authority then
        -- Apply delta from authority using per-key version comparison
        for key, entry in pairs(data.delta or {}) do
            if type(key) == "string" and type(entry) == "table" then
                local old = self._state[key]
                local old_value = old and old.value or nil
                local old_version = old and old.version or 0
                local new_version = entry.version or 0

                if new_version > old_version then
                    if entry.removed then
                        self._state[key] = nil
                    else
                        self._state[key] = {
                            value   = entry.value,
                            version = new_version,
                            owner   = peer_id,
                        }
                    end
                    self:_fireCallbacks(key, entry.removed and nil or entry.value, old_value, peer_id)
                    table.insert(changes, {
                        key       = key,
                        value     = entry.removed and nil or entry.value,
                        old_value = old_value,
                        peer_id   = peer_id,
                    })
                    _log("delta applied: key=" .. key .. " v=" .. tostring(new_version))
                else
                    _log("delta skipped (stale): key=" .. key
                         .. " remote_v=" .. tostring(new_version)
                         .. " local_v=" .. tostring(old_version))
                end
            end
        end
    elseif data.action == "full_request" and self._authority then
        -- Peer requested full state snapshot
        _log("full_request from peer " .. tostring(peer_id))
        self:_sendFullState(peer_id)
    elseif data.action == "full" and not self._authority then
        -- Received full state snapshot
        _log("full state received from peer " .. tostring(peer_id))
        for key, entry in pairs(data.state or {}) do
            if type(key) == "string" and type(entry) == "table" then
                local old = self._state[key]
                local old_value = old and old.value or nil
                self._state[key] = {
                    value   = entry.value,
                    version = entry.version or 0,
                    owner   = peer_id,
                }
                self:_fireCallbacks(key, entry.value, old_value, peer_id)
            end
        end
    elseif data.action == "turn" then
        self._current_turn = data.turn or 0
        self._turn_peer    = data.peer  -- may be nil if order is empty
        if self._on_turn then
            self._on_turn(self._current_turn, self._turn_peer)
        end
        _log("turn received: turn=" .. tostring(self._current_turn)
             .. " peer=" .. tostring(self._turn_peer))
    end
end

function NetState:_sendFullState(peer_id)
    if not self._host then return end
    local state = {}
    for key, entry in pairs(self._state) do
        state[key] = { value = entry.value, version = entry.version }
    end

    local pack_fn = lurek and lurek.network and lurek.network.pack
    if not pack_fn then return end

    local msg = pack_fn({
        type    = "netstate",
        action  = "full",
        state   = state,
        version = self:getVersion(),
    })
    self._host:send(peer_id, self._channel, msg, true)
end

function NetState:_broadcastTurn()
    if not self._host then return end

    local pack_fn = lurek and lurek.network and lurek.network.pack
    if not pack_fn then return end

    local msg = pack_fn({
        type   = "netstate",
        action = "turn",
        turn   = self._current_turn,
        peer   = self._turn_peer,
    })
    self._host:broadcast(self._channel, msg, true)
end

function NetState:_fireCallbacks(key, value, old_value, peer_id)
    -- Key-specific callbacks
    local cbs = self._callbacks[key]
    if cbs then
        for _, fn in ipairs(cbs) do
            fn(value, old_value, peer_id)
        end
    end
    -- Global callback
    if self._on_change then
        self._on_change(key, value, old_value, peer_id)
    end
end

--- Request a full state snapshot from the authority.
--- Useful when a client joins mid-game.
---
--- **Limitation**: This method has no built-in timeout. If the authority never
--- responds, the client will not receive a snapshot. Callers should implement
--- their own timer-based retry, e.g.:
---
---     ns:requestFullState()
---     local deadline = lurek.timer.getTime() + 5.0
---     -- In process loop: if lurek.timer.getTime() > deadline then retry or invoke
---     --   ns:onFullStateTimeout callback
---
--- @treturn boolean  False if this instance is the authority (no-op), true if sent.
function NetState:requestFullState()
    if self._authority then return false end
    if not self._host then return false end

    local pack_fn = lurek and lurek.network and lurek.network.pack
    if not pack_fn then return false end

    local msg = pack_fn({
        type   = "netstate",
        action = "full_request",
    })
    self._host:broadcast(self._channel, msg, true)
    _log("requestFullState sent")
    return true
end

return M
