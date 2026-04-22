--- Example usage for library.lobby.
-- Run with: lua content/library/lobby/example.lua
-- Demonstrates offline lobby management — room creation, joining, ready
-- checks, host election, event observation. No real network required:
-- pass nil for the host argument.
-- @module example.lobby

local M = require("library.lobby")

-- ── 1. Create an offline lobby (no network host) ──────────────────────────────
local lobby = M.new(nil, 0)
lobby:setPlayerName("Alice")

-- ── 2. Observe lifecycle events via the legacy single-callback API ────────────
local events = {}
lobby:onEvent(function(event_type, data)
    events[#events + 1] = event_type
    print(string.format("[example.lobby] event '%s' data=%s",
        event_type, data and data.name or "<nil>"))
end)

-- ── 3. Create rooms (server side, peer_id ignored) ────────────────────────────
local ok, err = lobby:createRoom("dungeon", { maxPlayers = 4 })
assert(ok, err)
ok = lobby:createRoom("arena", { maxPlayers = 8, password = "secret" })
assert(ok)

print(string.format("[example.lobby] room count=%d", lobby:getRoomCount()))
local rooms = lobby:listRooms()
for _, r in ipairs(rooms) do
    print(string.format("[example.lobby] room '%s' players=%d/%d password=%s",
        r.name, r.players, r.maxPlayers, tostring(r.hasPassword)))
end

-- ── 4. Players join — Alice (peer 1) and Bob (peer 2) ─────────────────────────
ok, err = lobby:joinRoom("dungeon", 1, "Alice")
assert(ok, err)
ok, err = lobby:joinRoom("dungeon", 2, "Bob")
assert(ok, err)

-- Wrong password should be rejected
ok, err = lobby:joinRoom("arena", 3, "Mallory", "wrong")
print(string.format("[example.lobby] arena bad-password join ok=%s err=%s",
    tostring(ok), tostring(err)))

-- ── 5. Inspect the room ───────────────────────────────────────────────────────
local players = lobby:getPlayers("dungeon")
print(string.format("[example.lobby] dungeon has %d players", #players))
for _, p in ipairs(players) do
    print(string.format("[example.lobby]   peer=%d name=%s ready=%s",
        p.peer_id, p.name, tostring(p.ready)))
end

-- ── 6. Ready-check toggle and host election ───────────────────────────────────
lobby:setReady(true,  1)
lobby:setReady(true,  2)
print(string.format("[example.lobby] all ready? %s", tostring(lobby:isAllReady())))
print(string.format("[example.lobby] host of dungeon = peer %s",
    tostring(lobby:getHost("dungeon"))))

-- ── 7. Optional EventBus bridge (only if lurek.patterns is available) ─────────
local bus = lobby:getEventBus()
if bus then
    print("[example.lobby] EventBus is available; multi-listener pub-sub enabled")
    bus:on("room_removed", function(data)
        print(string.format("[example.lobby] (bus) room_removed: %s", data.name))
    end)
else
    print("[example.lobby] lurek.patterns not loaded; legacy callback only")
end

-- ── 8. Tear down a room ───────────────────────────────────────────────────────
lobby:removeRoom("arena")
print(string.format("[example.lobby] after remove, room count=%d", lobby:getRoomCount()))
print(string.format("[example.lobby] events captured: %s", table.concat(events, ",")))

print("[example.lobby] done.")
