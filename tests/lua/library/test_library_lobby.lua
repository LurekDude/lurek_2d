--- BDD tests for library.lobby
local lobby_mod = require("library.lobby")

---------------------------------------------------------------------------
-- Room Creation
---------------------------------------------------------------------------

describe("Room Creation", function()
    it("creates a room with defaults", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:createRoom("alpha")
        expect_equal(ok, true)
        expect_equal(err, nil)
        expect_equal(L:getRoomCount(), 1)
    end)

    it("creates a room with custom options", function()
        local L = lobby_mod.new(nil)
        local ok = L:createRoom("bravo", { maxPlayers = 4, password = "secret", data = { mode = "ranked" } })
        expect_equal(ok, true)
        local rooms = L:listRooms()
        expect_equal(#rooms, 1)
        expect_equal(rooms[1].maxPlayers, 4)
        expect_equal(rooms[1].hasPassword, true)
    end)

    it("rejects duplicate room name", function()
        local L = lobby_mod.new(nil)
        L:createRoom("dup")
        local ok, err = L:createRoom("dup")
        expect_equal(ok, false)
        expect_equal(err, "room already exists")
    end)

    it("rejects empty room name", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:createRoom("")
        expect_equal(ok, false)
        expect_equal(err, "room name must be a non-empty string")
    end)

    it("rejects non-string room name", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:createRoom(123)
        expect_equal(ok, false)
        expect_equal(err, "room name must be a non-empty string")
    end)

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

describe("Room Removal", function()
    it("removes an existing room", function()
        local L = lobby_mod.new(nil)
        L:createRoom("temp")
        expect_equal(L:getRoomCount(), 1)
        L:removeRoom("temp")
        expect_equal(L:getRoomCount(), 0)
    end)

    it("no-op for non-existent room", function()
        local L = lobby_mod.new(nil)
        L:removeRoom("ghost")
        expect_equal(L:getRoomCount(), 0)
    end)
end)

---------------------------------------------------------------------------
-- Join / Leave
---------------------------------------------------------------------------

describe("Join / Leave", function()
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

    it("rejects join to non-existent room", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:joinRoom("nowhere")
        expect_equal(ok, false)
        expect_equal(err, "room not found")
    end)

    it("rejects join to full room", function()
        local L = lobby_mod.new(nil)
        L:createRoom("tiny", { maxPlayers = 1 })
        L:joinRoom("tiny", 1, "A")
        local ok, err = L:joinRoom("tiny", 2, "B")
        expect_equal(ok, false)
        expect_equal(err, "room full")
    end)

    it("rejects duplicate join", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 1, "A")
        local ok, err = L:joinRoom("r", 1, "A")
        expect_equal(ok, false)
        expect_equal(err, "player already in room")
    end)

    it("local player leaves a room", function()
        local L = lobby_mod.new(nil)
        L:createRoom("room1")
        L:joinRoom("room1")
        local ok = L:leaveRoom()
        expect_equal(ok, true)
        expect_equal(L:getCurrentRoom(), nil)
    end)

    it("warns when leaving with no room", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:leaveRoom()
        expect_equal(ok, false)
        expect_equal(err, "not in a room")
    end)

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

describe("Password Protection", function()
    it("rejects join without password", function()
        local L = lobby_mod.new(nil)
        L:createRoom("vault", { password = "abc123" })
        local ok, err = L:joinRoom("vault", 1, "Hacker")
        expect_equal(ok, false)
        expect_equal(err, "incorrect password")
    end)

    it("rejects join with wrong password", function()
        local L = lobby_mod.new(nil)
        L:createRoom("vault", { password = "abc123" })
        local ok, err = L:joinRoom("vault", 1, "Hacker", "wrong")
        expect_equal(ok, false)
        expect_equal(err, "incorrect password")
    end)

    it("accepts join with correct password", function()
        local L = lobby_mod.new(nil)
        L:createRoom("vault", { password = "abc123" })
        local ok = L:joinRoom("vault", 1, "VIP", "abc123")
        expect_equal(ok, true)
        expect_equal(#L:getPlayers("vault"), 1)
    end)

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

describe("Ready State", function()
    it("sets local player ready", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r")
        L:setReady(true)
        local players = L:getPlayers()
        expect_equal(players[1].ready, true)
    end)

    it("sets remote peer ready", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 5, "P5")
        L:setReady(true, 5)
        local players = L:getPlayers("r")
        expect_equal(players[1].ready, true)
    end)

    it("toggles ready off", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r")
        L:setReady(true)
        L:setReady(false)
        local players = L:getPlayers()
        expect_equal(players[1].ready, false)
    end)

    it("all ready with 2+ players", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r")
        L:joinRoom("r", 1, "P1")
        L:setReady(true)
        L:setReady(true, 1)
        expect_equal(L:isAllReady(), true)
    end)

    it("not all ready with only 1 player", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r")
        L:setReady(true)
        expect_equal(L:isAllReady(), false)
    end)

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

describe("Host Election", function()
    it("first joiner becomes host", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 10, "First")
        L:joinRoom("r", 20, "Second")
        expect_equal(L:getHost("r"), 10)
    end)

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

    it("non-host leave does not change host", function()
        local L = lobby_mod.new(nil)
        L:createRoom("r")
        L:joinRoom("r", 1, "A")
        L:joinRoom("r", 2, "B")
        expect_equal(L:getHost("r"), 1)
        L:leaveRoom(2)
        expect_equal(L:getHost("r"), 1)
    end)

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

describe("Events", function()
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

describe("Listing", function()
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

    it("getPlayers empty for unknown room", function()
        local L = lobby_mod.new(nil)
        local players = L:getPlayers("nonexistent")
        expect_equal(#players, 0)
    end)

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

describe("Player Name", function()
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

describe("Input Validation", function()
    it("rejects empty room name on join", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:joinRoom("")
        expect_equal(ok, false)
        expect_equal(err, "room name must be a non-empty string")
    end)

    it("rejects nil room name on join", function()
        local L = lobby_mod.new(nil)
        local ok, err = L:joinRoom(nil)
        expect_equal(ok, false)
        expect_equal(err, "room name must be a non-empty string")
    end)
end)
test_summary()
