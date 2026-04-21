--- Pure-Lua lobby and room management built on `lurek.network`.
--
-- Provides room creation, joining, player tracking, ready-check
-- coordination, host election, and password protection for multiplayer
-- pre-game lobbies.
--
-- Room lifecycle:
--
--   1. Server creates a room via `createRoom(name, opts)`.
--   2. Players join with `joinRoom(name, ...)`.  The first player becomes host.
--   3. Players toggle ready state with `setReady(ready, ...)`.
--   4. When `isAllReady()` returns true the host may start the game.
--   5. Players leave with `leaveRoom(...)`; host is re-elected automatically.
--   6. An empty room is removed automatically.
--
-- Player states: **not-ready** (default on join) → **ready** (via setReady).
--
-- @module library.lobby
-- @status full
-- @see lurek.network
-- @see lurek.patterns.newEventBus
-- @see lurek.serial.toJson
--
-- Wire format note: messages between peers are encoded with
-- `lurek.network.pack` / `lurek.network.unpack` (MessagePack — the canonical
-- ENet payload format). For human-readable persistence (e.g. saved lobby
-- state), use `lurek.serial.toJson` / `lurek.serial.fromJson`.
local M = {}

local log_info  = (lurek and lurek.log and lurek.log.info)  or function() end
local log_warn  = (lurek and lurek.log and lurek.log.warn)  or function() end
local log_debug = (lurek and lurek.log and lurek.log.debug) or function() end

--- Try to obtain a `lurek.patterns.newEventBus()` instance.
-- Returns nil silently if `lurek.patterns` is unavailable (headless tests,
-- module gated off, or older runtime).
-- @local
-- @treturn userdata|nil EventBus userdata or nil.
local function _try_new_event_bus()
    if lurek and lurek.patterns and type(lurek.patterns.newEventBus) == "function" then
        local ok, bus = pcall(lurek.patterns.newEventBus, "library.lobby")
        if ok then return bus end
    end
    return nil
end

---------------------------------------------------------------------------
-- Room (internal)
---------------------------------------------------------------------------

local Room = {}
Room.__index = Room

--- Create a new Room instance.
--- @tparam string name        Unique room name.
--- @tparam[opt] table opts    `{ maxPlayers=8, password=nil, data={} }`.
--- @treturn Room
function Room._new(name, opts)
    local self = setmetatable({}, Room)
    self.name        = name
    self.max_players = (opts and opts.maxPlayers) or 8
    self.password    = (opts and opts.password) or nil
    self.data        = (opts and opts.data) or {}
    self.players     = {}   -- { peer_id = { name, ready, data } }
    self.host_peer   = nil  -- peer_id of the current room host
    self._join_order = {}   -- array of peer_ids in join order
    return self
end

--- Add a player to the room.
--- @tparam number peer_id  Peer identifier.
--- @tparam[opt] string name  Display name (defaults to "Player<peer_id>").
--- @tparam[opt] table data   Arbitrary per-player data.
--- @treturn boolean success
--- @treturn string|nil error
function Room:addPlayer(peer_id, name, data)
    if self.players[peer_id] then
        return false, "player already in room"
    end
    if self:getPlayerCount() >= self.max_players then
        return false, "room full"
    end
    self.players[peer_id] = {
        name  = name or ("Player" .. tostring(peer_id)),
        ready = false,
        data  = data or {},
    }
    table.insert(self._join_order, peer_id)
    if not self.host_peer then
        self.host_peer = peer_id
    end
    return true
end

--- Remove a player from the room.  Re-elects host deterministically
--- by picking the earliest-joined remaining player.
--- @tparam number peer_id  Peer identifier to remove.
function Room:removePlayer(peer_id)
    self.players[peer_id] = nil
    -- Remove from join order
    for i = #self._join_order, 1, -1 do
        if self._join_order[i] == peer_id then
            table.remove(self._join_order, i)
            break
        end
    end
    -- Re-elect host: earliest joined player still present
    if self.host_peer == peer_id then
        self.host_peer = nil
        for _, pid in ipairs(self._join_order) do
            if self.players[pid] then
                self.host_peer = pid
                break
            end
        end
    end
end

--- Return the number of players currently in this room.
--- @treturn number
function Room:getPlayerCount()
    local n = 0
    for _ in pairs(self.players) do n = n + 1 end
    return n
end

--- Check whether all players are ready (minimum 2 players required).
--- @treturn boolean
function Room:isAllReady()
    local count = 0
    for _, p in pairs(self.players) do
        if not p.ready then return false end
        count = count + 1
    end
    return count >= 2  -- at least 2 players required
end

--- Return the current host peer_id (or nil if empty).
--- @treturn number|nil
function Room:getHost()
    return self.host_peer
end

---------------------------------------------------------------------------
-- Lobby Manager
---------------------------------------------------------------------------

local Lobby = {}
Lobby.__index = Lobby

--- Create a new lobby manager.
---
--- The lobby coordinates room creation, joining, leaving, ready-checks,
--- and host election.  Pass a network host for online use, or `nil` for
--- local-only / offline lobby management (e.g. tests).
---
--- @tparam[opt] userdata host  A `lurek.network.newHost` / `lurek.network.newServer`
---   host.  May be `nil` for offline / test usage.
--- @tparam[opt=0] number channel  ENet channel for lobby traffic.
--- @treturn Lobby
function M.new(host, channel)
    local self = setmetatable({}, Lobby)
    self._host       = host
    self._channel    = channel or 0
    self._rooms      = {}   -- { name = Room }
    self._peer_rooms = {}   -- { peer_id = room_name } reverse lookup
    self._my_room    = nil  -- current room name (client-side / local player)
    self._my_name    = "Player"
    self._on_event   = nil
    -- Optional `lurek.patterns.newEventBus` for typed pub-sub of lifecycle
    -- events. Lazily created; nil if `lurek.patterns` is unavailable.
    self._event_bus  = _try_new_event_bus()
    return self
end

--- Return the underlying `EventBus` (optional, may be nil).
-- When non-nil, `:on(event, callback)` lets multiple listeners subscribe to
-- the same lifecycle event without overwriting each other.  Event names match
-- the strings passed to `:onEvent(fn)` (`room_created`, `room_removed`,
-- `player_joined`, `player_left`, `player_ready`, `host_changed`,
-- `player_disconnected`).
-- @treturn userdata|nil  `EventBus` userdata, or nil if `lurek.patterns` is
--   unavailable in this runtime.
-- @see lurek.patterns.newEventBus
function Lobby:getEventBus()
    return self._event_bus
end

--- Set the local player name used when joining rooms.
--- @tparam string name  Non-empty display name.
function Lobby:setPlayerName(name)
    if type(name) ~= "string" or name == "" then
        log_warn("[lobby] setPlayerName: name must be a non-empty string")
        return
    end
    self._my_name = name
end

--- Register a callback for lobby events.
--
-- For multi-listener pub-sub, prefer `:getEventBus():on(event, fn)` when
-- `lurek.patterns` is available.
--
-- @tparam function fn  `fn(event_type, data)` where event_type is one of:
--   `"room_created"`, `"room_removed"`, `"player_joined"`, `"player_left"`,
--   `"player_ready"`, `"host_changed"`, `"player_disconnected"`.
-- @see Lobby:getEventBus
function Lobby:onEvent(fn)
    self._on_event = fn
end

--- @local
--- Internal: emit a lifecycle event to both the legacy single callback and
-- the optional `lurek.patterns.newEventBus`. Safe when either is absent.
-- @tparam string event_type
-- @tparam table data
function Lobby:_emit(event_type, data)
    if self._on_event then
        local ok, err = pcall(self._on_event, event_type, data)
        if not ok then log_warn("[lobby] onEvent callback error: " .. tostring(err)) end
    end
    if self._event_bus then
        local ok, err = pcall(function() self._event_bus:emit(event_type, data) end)
        if not ok then log_warn("[lobby] EventBus emit error: " .. tostring(err)) end
    end
end

--- Create a new room (server-side).
--- @tparam string name       Room name (unique, non-empty).
--- @tparam[opt] table opts   `{ maxPlayers=8, password=nil, data={} }`.
--- @treturn boolean success
--- @treturn string|nil error
function Lobby:createRoom(name, opts)
    if type(name) ~= "string" or name == "" then
        return false, "room name must be a non-empty string"
    end
    if self._rooms[name] then
        return false, "room already exists"
    end
    if opts and opts.maxPlayers ~= nil then
        if type(opts.maxPlayers) ~= "number" or opts.maxPlayers < 1 then
            return false, "maxPlayers must be a positive number"
        end
    end
    self._rooms[name] = Room._new(name, opts)
    log_info("[lobby] room created: " .. name)
    if self._on_event or self._event_bus then
        self:_emit("room_created", { name = name })
    end
    return true
end

--- Remove a room (server-side).  All players in the room are evicted.
--- @tparam string name  Room name to remove.
function Lobby:removeRoom(name)
    local room = self._rooms[name]
    if not room then return end
    -- Clean up peer→room reverse map
    for pid, _ in pairs(room.players) do
        self._peer_rooms[pid] = nil
    end
    self._rooms[name] = nil
    if self._my_room == name then
        self._my_room = nil
    end
    log_info("[lobby] room removed: " .. name)
    if self._on_event or self._event_bus then
        self:_emit("room_removed", { name = name })
    end
end

--- Join a room by name (local or via network message).
---
--- When `peer_id` is nil the local player joins (using peer 0 internally).
--- When `peer_id` is provided the server records that remote peer.
---
--- @tparam string name           Room name to join.
--- @tparam[opt] number peer_id   Peer joining (server-side).  Nil for local.
--- @tparam[opt] string player_name  Display name override.
--- @tparam[opt] string password  Room password (required if room has one).
--- @treturn boolean success
--- @treturn string|nil error
function Lobby:joinRoom(name, peer_id, player_name, password)
    if type(name) ~= "string" or name == "" then
        return false, "room name must be a non-empty string"
    end
    local room = self._rooms[name]
    if not room then
        return false, "room not found"
    end
    -- Password validation
    if room.password then
        if password ~= room.password then
            return false, "incorrect password"
        end
    end
    local pid   = peer_id or 0
    if type(pid) ~= "number" then
        return false, "peer_id must be a number"
    end
    local pname = player_name or self._my_name
    local ok, err = room:addPlayer(pid, pname)
    if not ok then return false, err end

    self._peer_rooms[pid] = name
    if not peer_id then
        self._my_room = name
    end
    log_info("[lobby] player " .. tostring(pid) .. " (" .. pname .. ") joined room: " .. name)
    if self._on_event or self._event_bus then
        self:_emit("player_joined", { room = name, peer_id = pid, name = pname })
    end
    return true
end

--- Leave a room.
---
--- When `peer_id` is nil the local player leaves their current room.
--- When `peer_id` is provided the server removes that remote peer from
--- whichever room they are in.
---
--- @tparam[opt] number peer_id  Peer leaving (server-side).  Nil for local.
--- @treturn boolean success
--- @treturn string|nil error
function Lobby:leaveRoom(peer_id)
    local pid = peer_id or 0
    local room_name
    if peer_id then
        room_name = self._peer_rooms[pid]
    else
        room_name = self._my_room
    end
    if not room_name then
        log_warn("[lobby] leaveRoom: player " .. tostring(pid) .. " is not in any room")
        return false, "not in a room"
    end
    local room = self._rooms[room_name]
    if not room then
        -- Room was already removed
        self._peer_rooms[pid] = nil
        if not peer_id then self._my_room = nil end
        return false, "room not found"
    end
    local old_host = room.host_peer
    room:removePlayer(pid)
    self._peer_rooms[pid] = nil
    log_info("[lobby] player " .. tostring(pid) .. " left room: " .. room_name)
    if self._on_event or self._event_bus then
        self:_emit("player_left", { room = room_name, peer_id = pid })
    end
    -- Notify host change
    if old_host == pid and room.host_peer and room.host_peer ~= old_host then
        log_info("[lobby] new host in " .. room_name .. ": " .. tostring(room.host_peer))
        if self._on_event or self._event_bus then
            self:_emit("host_changed", { room = room_name, new_host = room.host_peer })
        end
    end
    -- Auto-remove empty rooms
    if room:getPlayerCount() == 0 then
        self._rooms[room_name] = nil
        log_debug("[lobby] auto-removed empty room: " .. room_name)
    end
    if not peer_id then
        self._my_room = nil
    end
    return true
end

--- List all available rooms.
--- @treturn table  Array of `{ name, players, maxPlayers, hasPassword }` tables.
function Lobby:listRooms()
    local list = {}
    for name, room in pairs(self._rooms) do
        table.insert(list, {
            name        = name,
            players     = room:getPlayerCount(),
            maxPlayers  = room.max_players,
            hasPassword = room.password ~= nil,
        })
    end
    return list
end

--- Get players in a specific room (or current room if name is nil).
--- @tparam[opt] string name  Room name.  Defaults to the local player's room.
--- @treturn table  Array of `{ peer_id, name, ready }` tables.
function Lobby:getPlayers(name)
    local room = self._rooms[name or self._my_room]
    if not room then return {} end
    local list = {}
    for pid, p in pairs(room.players) do
        table.insert(list, {
            peer_id = pid,
            name    = p.name,
            ready   = p.ready,
        })
    end
    return list
end

--- Set ready state for a player.
---
--- When `peer_id` is nil the local player's ready state is updated in their
--- current room.  When `peer_id` is provided the server looks up that peer's
--- room via the internal reverse map (unified code path).
---
--- @tparam boolean ready      New ready state.
--- @tparam[opt] number peer_id  Peer (server-side).  Nil for local player.
function Lobby:setReady(ready, peer_id)
    local pid = peer_id or 0
    local room_name
    if peer_id then
        room_name = self._peer_rooms[pid]
    else
        room_name = self._my_room
    end
    if not room_name then return end
    local room = self._rooms[room_name]
    if not room then return end
    local player = room.players[pid]
    if player then
        player.ready = (ready == true)
        log_debug("[lobby] player " .. tostring(pid) .. " ready=" .. tostring(ready) .. " in " .. room_name)
        if self._on_event or self._event_bus then
            self:_emit("player_ready", {
                room = room_name, peer_id = pid, ready = player.ready,
            })
        end
    end
end

--- Check if all players in the current room are ready.
--- @treturn boolean
function Lobby:isAllReady()
    local room = self._rooms[self._my_room]
    if not room then return false end
    return room:isAllReady()
end

--- Get the current room name (client-side / local player).
--- @treturn string|nil
function Lobby:getCurrentRoom()
    return self._my_room
end

--- Get the host peer_id for a room (or the local player's room).
--- @tparam[opt] string name  Room name.  Defaults to local player's room.
--- @treturn number|nil
function Lobby:getHost(name)
    local room = self._rooms[name or self._my_room]
    if not room then return nil end
    return room.host_peer
end

--- Get the number of rooms.
--- @treturn number
function Lobby:getRoomCount()
    local n = 0
    for _ in pairs(self._rooms) do n = n + 1 end
    return n
end

--- Process incoming lobby network messages.  Call once per frame.
--- @treturn table  Array of processed events.
function Lobby:poll()
    if not self._host then return {} end
    local events = {}
    local ev = self._host:service()
    while ev do
        if ev.type == "receive" then
            local ok, data = pcall(lurek.network.unpack, ev.data)
            if ok and type(data) == "table" and data.type == "lobby" then
                self:_handle(ev.peer, data, events)
            end
        elseif ev.type == "disconnect" then
            -- Remove disconnected peer from their room
            local room_name = self._peer_rooms[ev.peer]
            if room_name then
                local room = self._rooms[room_name]
                if room and room.players[ev.peer] then
                    room:removePlayer(ev.peer)
                    self._peer_rooms[ev.peer] = nil
                    local e = { type = "player_disconnected", peer_id = ev.peer, room = room_name }
                    table.insert(events, e)
                    if self._on_event or self._event_bus then self:_emit("player_disconnected", e) end
                    if room:getPlayerCount() == 0 then
                        self._rooms[room_name] = nil
                    end
                end
            end
        end
        ev = self._host:service()
    end
    return events
end

--- Internal: handle a decoded lobby message from a peer.
--- @tparam number peer_id  Sender peer.
--- @tparam table data      Decoded lobby message.
--- @tparam table events    Accumulator for emitted events.
function Lobby:_handle(peer_id, data, events)
    local action = data.action
    if action == "join" then
        local ok, err = self:joinRoom(data.room, peer_id, data.name, data.password)
        if ok then
            table.insert(events, { type = "join", peer_id = peer_id, room = data.room })
        end
    elseif action == "leave" then
        self:leaveRoom(peer_id)
        table.insert(events, { type = "leave", peer_id = peer_id })
    elseif action == "ready" then
        self:setReady(data.ready, peer_id)
        table.insert(events, { type = "ready", peer_id = peer_id, ready = data.ready })
    elseif action == "list" then
        local rooms = self:listRooms()
        if self._host and self._host.send then
            local resp = lurek.network.pack({ type = "lobby", action = "list_response", rooms = rooms })
            self._host:send(peer_id, self._channel, resp, true)
        end
    end
end

return M
