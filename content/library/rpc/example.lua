--- Example usage for library.rpc.
-- Run with: lua content/library/rpc/example.lua
-- Simulates two endpoints (server peer 1, client peer 2) talking over an
-- in-process channel. No real network or lurek.network is required: a
-- mock host with send / broadcast / service is wired so messages are
-- delivered synchronously between the two RPC managers.
-- @module example.rpc

local M = require("library.rpc")

-- ── 1. In-process loopback host pair ──────────────────────────────────────────
-- Two hosts share inbox queues. host_a:send(peer, ch, data) appends to
-- host_b's inbox (and vice versa); :service() pops the next event.
local function new_host_pair()
    local a, b = { id = 1, _inbox = {} }, { id = 2, _inbox = {} }
    local function make(self, other)
        function self:send(_peer, _ch, data) other._inbox[#other._inbox + 1] = data end
        function self:broadcast(_ch, data, _rel) other._inbox[#other._inbox + 1] = data end
        function self:service()
            local d = table.remove(self._inbox, 1)
            if not d then return nil end
            return { type = "receive", peer = (self == a) and 2 or 1, data = d }
        end
    end
    make(a, b); make(b, a)
    return a, b
end

local host_server, host_client = new_host_pair()

-- The library's _encode/_decode prefer lurek.serial but fall back to
-- lurek.network.pack when codec is missing. Provide a minimal pack/unpack
-- pair (passes the table through identity) so the example runs in any
-- plain Lua VM that has no engine context.
lurek = lurek or {}
lurek.network = lurek.network or {
    pack   = function(t) return t end,
    unpack = function(t) return t end,
}

-- ── 2. Build server and client RPC managers ───────────────────────────────────
local server = M.new(host_server, 0, 5)
local client = M.new(host_client, 0, 5)
print(string.format("[example.rpc] server handlers=%d default_timeout=%d",
    server:getHandlerCount(), M.DEFAULT_TIMEOUT))

-- ── 3. Register handlers on the server ────────────────────────────────────────
server:register("add", function(peer_id, a, b)
    print(string.format("[example.rpc] (server) 'add' from peer %d: %d + %d", peer_id, a, b))
    return a + b
end)

server:register("greet", function(peer_id, name)
    return "hello " .. tostring(name) .. " from peer " .. tostring(peer_id)
end)

local notify_log = {}
server:register("ping", function(peer_id, msg)
    notify_log[#notify_log + 1] = string.format("peer=%d msg=%s", peer_id, tostring(msg))
end)

-- ── 4. Client → server: request/response via :call ────────────────────────────
local results = {}
client:call(1, "add", function(success, result)
    results.add = { success = success, value = result and result[1] }
end, 7, 35)

client:call(1, "greet", function(success, result)
    results.greet = { success = success, value = result and result[1] }
end, "Alice")

-- ── 5. Drive both sides — server consumes calls, then client consumes responses
print(string.format("[example.rpc] pending before poll: client=%d", client:getPendingCount()))
server:poll()  -- server reads two rpc_call frames and sends responses back
client:poll()  -- client reads the two rpc_response frames and fires callbacks
print(string.format("[example.rpc] pending after poll:  client=%d", client:getPendingCount()))

print(string.format("[example.rpc] add result success=%s value=%s",
    tostring(results.add.success),   tostring(results.add.value)))
print(string.format("[example.rpc] greet result success=%s value=%s",
    tostring(results.greet.success), tostring(results.greet.value)))

-- ── 6. Fire-and-forget notify (no response expected) ──────────────────────────
client:notify(1, "ping", "from-client")
client:notify(1, "ping", "again")
server:poll()
print(string.format("[example.rpc] server received %d notifies: %s",
    #notify_log, table.concat(notify_log, " | ")))

-- ── 7. Error path: unknown method → on_error callback fires ───────────────────
local err_log = {}
server:onError(function(msg) err_log[#err_log + 1] = msg end)
client:notify(1, "missing_method", "x")
server:poll()
print(string.format("[example.rpc] error log: %s",
    err_log[1] or "<none>"))

print("[example.rpc] done.")
