--- BDD tests for library.lobby
local lobby_mod = require("library.lobby")

---------------------------------------------------------------------------
-- Room Creation
---------------------------------------------------------------------------

-- @description Covers room creation, duplicate detection, and option validation.
describe("Room Creation", function()
    -- @covers library.lobby.createRoom
    -- @description Verifies a room can be created with default options and appears in listings.
    it("creates a room with defaults", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:createRoom("alpha")
        expect_equal(ok, true)
        expect_equal(err, nil)
        expect_equal(L:getRoomCount(), 1)
    end)

    -- @covers library.lobby.createRoom
    -- @description Verifies room options (maxPlayers, password, data) are accepted.
    it("creates a room with custom options", function()
        local L = lobby_mod.new(nil)
        local ok = L:createRoom("bravo", { maxPlayers = 4, password = "secret", data = { mode = "ranked" } })
        expect_equal(ok, true)
        local rooms = L:listRooms()
        expect_equal(#rooms, 1)
        expect_equal(rooms[1].maxPlayers, 4)
        expect_equal(rooms[1].hasPassword, true)
    end)

    -- @covers library.lobby.createRoom
    -- @description Attempting to create a room with a duplicate name fails.
    it("rejects duplicate room name", function()
        local L = lobby_mod.new(nil)
        L:createRoom("dup")
        local ok, err = L:createRoom("dup")
        expect_equal(ok, false)
        expect_equal(err, "room already exists")
    end)

    -- @covers library.lobby.createRoom
    -- @description Empty or non-string room names are rejected.
    it("rejects empty room name", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:createRoom("")
        expect_equal(ok, false)
        expect_equal(err, "room name must be a non-empty string")
    end)

    -- @covers library.lobby.createRoom
    -- @description Non-string room name is rejected.
    it("rejects non-string room name", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:createRoom(123)
        expect_equal(ok, false)
        expect_equal(err, "room name must be a non-empty string")
    end)

    -- @covers library.lobby.createRoom
    -- @description Invalid maxPlayers is rejected.
    it("rejects invalid maxPlayers", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:createRoom("bad", { maxPlayers = 0 })
        expect_equal(ok, false)
        expect_equal(err, "maxPlayers must be a positive number")

        ok, err = L:createRoom("bad2", { maxPlayers = -1 })
        expect_equal(ok, false)
        expect_equal(err, "maxPlayers must be a positive number")
    end)
end)

---------------------------------------------------------------------------
-- Room Removal
---------------------------------------------------------------------------

-- @description Covers room removal and auto-removal of empty rooms.
describe("Room Removal", function()
    -- @covers library.lobby.removeRoom
    -- @description Removing a room decrements count and clears from listings.
    it("removes an existing room", function()
        local L = lobby_mod.new(nil)
        L:createRoom("temp")
        expect_equal(L:getRoomCount(), 1)
        L:removeRoom("temp")
        expect_equal(L:getRoomCount(), 0)
    end)

    -- @covers library.lobby.removeRoom
    -- @description Removing a non-existent room is a no-op.
    it("no-op for non-existent room", function()
        local L = lobby_mod.new(nil)
        L:removeRoom("ghost")
        expect_equal(L:getRoomCount(), 0)
    end)
end)

---------------------------------------------------------------------------
-- Join / Leave
---------------------------------------------------------------------------

-- @description Covers joining rooms, leaving rooms, and edge cases.
describe("Join / Leave", function()
    -- @covers library.lobby.joinRoom
    -- @description Local player can join a room and is tracked as peer 0.
    it("local player joins a room", function()
        local L = lobby_mod.new(nil)
        L:setPlayerName("Alice")
        L:createRoom("room1")
        local ok = L:joinRoom("room1")
        expect_equal(ok, true)
        expect_equal(L:getCurrentRoom(), "room1")
        local players = L:getPlayers()
        expect_equal(#players, 1)
        expect_equal(players[1].name, "Alice")
    end)

    -- @covers library.lobby.joinRoom
    -- @description Remote peer joins with explicit peer_id.
    it("remote peer joins a room", function()
        local L = lobby_mod.new(nil)
        L:createRoom("room1")
        local ok = L:joinRoom("room1", 42, "Bob")
        expect_equal(ok, true)
        local players = L:getPlayers("room1")
        expect_equal(#players, 1)
        expect_equal(players[1].peer_id, 42)
        expect_equal(players[1].name, "Bob")
    end)

    -- @covers library.lobby.joinRoom
    -- @description Joining a non-existent room fails.
    it("rejects join to non-existent room", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:joinRoom("nowhere")
        expect_equal(ok, false)
        expect_equal(err, "room not found")
    end)

    -- @covers library.lobby.joinRoom
    -- @description Joining a full room fails.
    it("rejects join to full room", function()
        local L = lobby_mod.new(nil)
        L:createRoom("tiny", { maxPlayers = 1 })
        L:joinRoom("tiny", 1, "A")
        local ok, err = L:joinRoom("tiny", 2, "B")
        expect_equal(ok, false)
        expect_equal(err, "room full")
    end)

    -- @covers library.lobby.joinRoom
    -- @description Joining the same room twice with the same peer_id fails.
    it("rejects duplicate join", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 1, "A")
        local ok, err = L:joinRoom("r", 1, "A")
        expect_equal(ok, false)
        expect_equal(err, "player already in room")
    end)

    -- @covers library.lobby.leaveRoom
    -- @description Local player leaves and room tracking is cleared.
    it("local player leaves a room", function()
        local L = lobby_mod.new(nil)
        L:createRoom("room1")
        L:joinRoom("room1")
        local ok = L:leaveRoom()
        expect_equal(ok, true)
        expect_equal(L:getCurrentRoom(), nil)
    end)

    -- @covers library.lobby.leaveRoom
    -- @description Leaving with no room set returns false and an error.
    it("warns when leaving with no room", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:leaveRoom()
        expect_equal(ok, false)
        expect_equal(err, "not in a room")
    end)

    -- @covers library.lobby.leaveRoom
    -- @description Remote peer leave via peer_id.
    it("remote peer leaves a room", function()
        local L = lobby_mod.new(nil)
        L:createRoom("room1")
        L:joinRoom("room1", 10, "Peer10")
        L:joinRoom("room1", 20, "Peer20")
        local ok = L:leaveRoom(10)
        expect_equal(ok, true)
        local players = L:getPlayers("room1")
        expect_equal(#players, 1)
        expect_equal(players[1].peer_id, 20)
    end)

    -- @covers library.lobby.leaveRoom
    -- @description Room is auto-removed when the last player leaves.
    it("auto-removes empty room after last leave", function()
        local L = lobby_mod.new(nil)
        L:createRoom("solo")
        L:joinRoom("solo", 1, "Lonely")
        L:leaveRoom(1)
        expect_equal(L:getRoomCount(), 0)
    end)
end)

---------------------------------------------------------------------------
-- Password Protection
---------------------------------------------------------------------------

-- @description Covers password-protected room join validation.
describe("Password Protection", function()
    -- @covers library.lobby.joinRoom
    -- @description Joining a password-protected room without a password fails.
    it("rejects join without password", function()
        local L = lobby_mod.new(nil)
        L:createRoom("vault", { password = "abc123" })
        local ok, err = L:joinRoom("vault", 1, "Hacker")
        expect_equal(ok, false)
        expect_equal(err, "incorrect password")
    end)

    -- @covers library.lobby.joinRoom
    -- @description Joining with wrong password fails.
    it("rejects join with wrong password", function()
        local L = lobby_mod.new(nil)
        L:createRoom("vault", { password = "abc123" })
        local ok, err = L:joinRoom("vault", 1, "Hacker", "wrong")
        expect_equal(ok, false)
        expect_equal(err, "incorrect password")
    end)

    -- @covers library.lobby.joinRoom
    -- @description Joining with correct password succeeds.
    it("accepts join with correct password", function()
        local L = lobby_mod.new(nil)
        L:createRoom("vault", { password = "abc123" })
        local ok = L:joinRoom("vault", 1, "VIP", "abc123")
        expect_equal(ok, true)
        expect_equal(#L:getPlayers("vault"), 1)
    end)

    -- @covers library.lobby.joinRoom
    -- @description No-password room accepts join without password arg.
    it("open room accepts join without password", function()
        local L = lobby_mod.new(nil)
        L:createRoom("open")
        local ok = L:joinRoom("open", 1, "Anyone")
        expect_equal(ok, true)
    end)
end)

---------------------------------------------------------------------------
-- Ready State
---------------------------------------------------------------------------

-- @description Covers player ready-check toggling and room-wide readiness.
describe("Ready State", function()
    -- @covers library.lobby.setReady
    -- @description Local player can toggle ready state.
    it("sets local player ready", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r")
        L:setReady(true)
        local players = L:getPlayers()
        expect_equal(players[1].ready, true)
    end)

    -- @covers library.lobby.setReady
    -- @description Server can set ready for a remote peer.
    it("sets remote peer ready", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 5, "P5")
        L:setReady(true, 5)
        local players = L:getPlayers("r")
        expect_equal(players[1].ready, true)
    end)

    -- @covers library.lobby.setReady
    -- @description Toggling ready back to false works.
    it("toggles ready off", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r")
        L:setReady(true)
        L:setReady(false)
        local players = L:getPlayers()
        expect_equal(players[1].ready, false)
    end)

    -- @covers library.lobby.isAllReady
    -- @description isAllReady requires at least 2 players all ready.
    it("all ready with 2+ players", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r")
        L:joinRoom("r", 1, "P1")
        L:setReady(true)
        L:setReady(true, 1)
        expect_equal(L:isAllReady(), true)
    end)

    -- @covers library.lobby.isAllReady
    -- @description isAllReady returns false with only 1 player even if ready.
    it("not all ready with only 1 player", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r")
        L:setReady(true)
        expect_equal(L:isAllReady(), false)
    end)

    -- @covers library.lobby.isAllReady
    -- @description isAllReady returns false when one player is not ready.
    it("not all ready when one is unready", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r")
        L:joinRoom("r", 1, "P1")
        L:setReady(true)
        -- peer 1 is not ready
        expect_equal(L:isAllReady(), false)
    end)
end)

---------------------------------------------------------------------------
-- Host Election
---------------------------------------------------------------------------

-- @description Covers deterministic host election on join/leave.
describe("Host Election", function()
    -- @covers library.lobby.joinRoom library.lobby.getHost
    -- @description First player to join becomes host.
    it("first joiner becomes host", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 10, "First")
        L:joinRoom("r", 20, "Second")
        expect_equal(L:getHost("r"), 10)
    end)

    -- @covers library.lobby.leaveRoom library.lobby.getHost
    -- @description When host leaves, earliest remaining joiner becomes host.
    it("re-elects host deterministically on host leave", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 10, "First")
        L:joinRoom("r", 5, "Second")
        L:joinRoom("r", 20, "Third")
        -- Host is 10 (first to join)
        expect_equal(L:getHost("r"), 10)
        -- Remove host
        L:leaveRoom(10)
        -- Next host should be 5 (second to join, earliest remaining)
        expect_equal(L:getHost("r"), 5)
    end)

    -- @covers library.lobby.leaveRoom library.lobby.getHost
    -- @description Non-host leaving does not change host.
    it("non-host leave does not change host", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 1, "A")
        L:joinRoom("r", 2, "B")
        expect_equal(L:getHost("r"), 1)
        L:leaveRoom(2)
        expect_equal(L:getHost("r"), 1)
    end)

    -- @covers library.lobby.leaveRoom library.lobby.getHost
    -- @description Host is nil after all players leave.
    it("host is nil when room empties", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 1, "A")
        L:leaveRoom(1)
        -- Room auto-removed, but test getHost on nil room
        expect_equal(L:getHost("r"), nil)
    end)
end)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

-- @description Covers event callback invocations for lobby actions.
describe("Events", function()
    -- @covers library.lobby.onEvent
    -- @description Event callback fires for room creation, join, leave, ready, and host change.
    it("fires events for room lifecycle", function()
        local L = lobby_mod.new(nil)
        local events = {}
        L:onEvent(function(etype, data)
            table.insert(events, { type = etype, data = data })
        end)
        L:createRoom("r")
        L:joinRoom("r", 1, "A")
        L:joinRoom("r", 2, "B")
        L:setReady(true, 1)
        L:leaveRoom(1)

        -- Expect: room_created, player_joined x2, player_ready, player_left, host_changed
        local types = {}
        for _, e in ipairs(events) do
            table.insert(types, e.type)
        end
        expect_equal(types[1], "room_created")
        expect_equal(types[2], "player_joined")
        expect_equal(types[3], "player_joined")
        expect_equal(types[4], "player_ready")
        expect_equal(types[5], "player_left")
        expect_equal(types[6], "host_changed")
    end)
end)

---------------------------------------------------------------------------
-- Listing & Querying
---------------------------------------------------------------------------

-- @description Covers listing rooms and querying player lists.
describe("Listing", function()
    -- @covers library.lobby.listRooms
    -- @description listRooms returns correct info for multiple rooms.
    it("lists multiple rooms", function()
        local L = lobby_mod.new(nil)
        L:createRoom("a")
        L:createRoom("b", { maxPlayers = 2, password = "pw" })
        local rooms = L:listRooms()
        expect_equal(#rooms, 2)
        -- Find room b
        local b_room
        for _, r in ipairs(rooms) do
            if r.name == "b" then b_room = r end
        end
        expect_equal(b_room.maxPlayers, 2)
        expect_equal(b_room.hasPassword, true)
    end)

    -- @covers library.lobby.getPlayers
    -- @description getPlayers returns empty table for unknown room.
    it("getPlayers empty for unknown room", function()
        local L = lobby_mod.new(nil)
        local players = L:getPlayers("nonexistent")
        expect_equal(#players, 0)
    end)

    -- @covers library.lobby.getRoomCount
    -- @description getRoomCount tracks room creation and removal.
    it("getRoomCount tracks changes", function()
        local L = lobby_mod.new(nil)
        expect_equal(L:getRoomCount(), 0)
        L:createRoom("x")
        L:createRoom("y")
        expect_equal(L:getRoomCount(), 2)
        L:removeRoom("x")
        expect_equal(L:getRoomCount(), 1)
    end)
end)

---------------------------------------------------------------------------
-- Player Name
---------------------------------------------------------------------------

-- @description Covers setPlayerName validation.
describe("Player Name", function()
    -- @covers library.lobby.setPlayerName
    -- @description Rejects empty and non-string names.
    it("rejects empty name", function()
        local L = lobby_mod.new(nil)
        L:setPlayerName("Valid")
        L:setPlayerName("")  -- should be rejected
        -- Name should still be "Valid" since empty was rejected
        L:createRoom("r")
        L:joinRoom("r")
        local players = L:getPlayers()
        expect_equal(players[1].name, "Valid")
    end)

    -- @covers library.lobby.setPlayerName
    -- @description Non-string name is rejected.
    it("rejects non-string name", function()
        local L = lobby_mod.new(nil)
        L:setPlayerName("Good")
        L:setPlayerName(42)  -- rejected
        L:createRoom("r")
        L:joinRoom("r")
        local players = L:getPlayers()
        expect_equal(players[1].name, "Good")
    end)
end)

---------------------------------------------------------------------------
-- Input Validation
---------------------------------------------------------------------------

-- @description Covers input validation edge cases.
describe("Input Validation", function()
    -- @covers library.lobby.joinRoom
    -- @description joinRoom rejects empty room name.
    it("rejects empty room name on join", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:joinRoom("")
        expect_equal(ok, false)
        expect_equal(err, "room name must be a non-empty string")
    end)

    -- @covers library.lobby.joinRoom
    -- @description joinRoom rejects nil room name.
    it("rejects nil room name on join", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:joinRoom(nil)
        expect_equal(ok, false)
        expect_equal(err, "room name must be a non-empty string")
    end)
end)

test_summary()
