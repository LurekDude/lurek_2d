-- content/examples/network.lua
-- Lurek2D lurek.network API Reference
-- Run with: cargo run -- content/examples/network

-- =============================================================================
-- lurek.network — UDP peer-to-peer (ENet), TCP, WebSocket, HTTP, lobbies
--
-- NetworkHost wraps ENet for reliable/unreliable UDP channels with peer
-- management.  NetworkRuntime provides HTTP requests, TCP sockets, and
-- WebSocket connections for REST APIs and chat systems.
-- =============================================================================

-- ---- Stub: lurek.network.newHost -----------------------------------------
--@api-stub: lurek.network.newHost
-- Create a raw ENet host for custom networking.  Bind to port 7777 with
-- a max of 32 peers and 2 channels.
local host = lurek.network.newHost("0.0.0.0:7777", 32, 2)
print("network host created on port 7777, max 32 peers")

-- ---- Stub: lurek.network.newServer ---------------------------------------
--@api-stub: lurek.network.newServer
-- Create a server host that listens for incoming client connections.
local server = lurek.network.newServer(7778, 16)
print("server listening on port 7778, max 16 players")

-- ---- Stub: lurek.network.newClient ---------------------------------------
--@api-stub: lurek.network.newClient
-- Create a client host that connects to a remote server.
local client = lurek.network.newClient("127.0.0.1:7778")
print("client connecting to 127.0.0.1:7778")

-- ---- Stub: lurek.network.pack --------------------------------------------
--@api-stub: lurek.network.pack
-- Pack a game event into a compact binary message for network sending.
local msg = lurek.network.pack({ type = "move", x = 100.5, y = 200.3 })
print("packed network message: " .. #msg .. " bytes")

-- ---- Stub: lurek.network.unpack ------------------------------------------
--@api-stub: lurek.network.unpack
-- Unpack a received binary message back to a Lua table.
local event = lurek.network.unpack(msg)
print("unpacked: type=" .. event.type .. " x=" .. event.x)

-- ---- Stub: lurek.network.createLobby -------------------------------------
--@api-stub: lurek.network.createLobby
-- Create a game lobby that other players can discover and join.
local lobby = lurek.network.createLobby({
    name = "Boss Rush Room",
    max_players = 4,
    map = "dungeon_3",
})
print("lobby created: " .. tostring(lobby))

-- ---- Stub: lurek.network.discoverLobbies ---------------------------------
--@api-stub: lurek.network.discoverLobbies
-- Discover available lobbies on the local network for a server browser.
local lobbies = lurek.network.discoverLobbies()
print("discovered " .. #(lobbies or {}) .. " lobbies")
for i, l in ipairs(lobbies or {}) do
    print(string.format("  %d) %s (%d/%d players)", i, l.name, l.players, l.max_players))
end

-- ---- Stub: lurek.network.syncEntity --------------------------------------
--@api-stub: lurek.network.syncEntity
-- Synchronize an entity's position across all connected peers.
lurek.network.syncEntity(host, {
    id = 1,
    x = 150.0,
    y = 300.0,
    vx = 5.0,
    vy = -2.0,
})
print("entity 1 state synced to all peers")


-- =============================================================================
-- NetworkHost — ENet peer-to-peer operations
-- =============================================================================

-- ---- Stub: NetworkHost:service -------------------------------------------
--@api-stub: NetworkHost:service
-- Poll for network events (connect, disconnect, receive).  Call every
-- frame with a short timeout.
local evt = host:service(0)
if evt then
    print("network event: " .. tostring(evt.type))
else
    print("no network events this frame")
end

-- ---- Stub: NetworkHost:flush ---------------------------------------------
--@api-stub: NetworkHost:flush
-- Force-send all queued packets immediately (useful before disconnect).
host:flush()
print("outgoing packets flushed")

-- ---- Stub: NetworkHost:disconnect ----------------------------------------
--@api-stub: NetworkHost:disconnect
-- Gracefully disconnect a peer by ID with a timeout for acknowledgement.
host:disconnect(0)
print("peer 0 disconnect requested (graceful)")

-- ---- Stub: NetworkHost:disconnectNow -------------------------------------
--@api-stub: NetworkHost:disconnectNow
-- Immediately drop a peer without waiting for acknowledgement (kick).
host:disconnectNow(0)
print("peer 0 disconnected immediately (kicked)")

-- ---- Stub: NetworkHost:resetPeer -----------------------------------------
--@api-stub: NetworkHost:resetPeer
-- Reset a peer's connection state after a timeout or error.
host:resetPeer(0)
print("peer 0 connection state reset")

-- ---- Stub: NetworkHost:ping ----------------------------------------------
--@api-stub: NetworkHost:ping
-- Send a ping to measure round-trip time.
host:ping(0)
print("ping sent to peer 0")

-- ---- Stub: NetworkHost:getRoundTripTime ----------------------------------
--@api-stub: NetworkHost:getRoundTripTime
-- Display the latency to a peer in the scoreboard.
local rtt = host:getRoundTripTime(0)
print("peer 0 RTT: " .. tostring(rtt) .. " ms")

-- ---- Stub: NetworkHost:getPeerState --------------------------------------
--@api-stub: NetworkHost:getPeerState
-- Check if a peer is still connected before sending data.
local state = host:getPeerState(0)
print("peer 0 state: " .. tostring(state))

-- ---- Stub: NetworkHost:getPeerAddress ------------------------------------
--@api-stub: NetworkHost:getPeerAddress
-- Log the IP address of a connecting peer for admin/ban purposes.
local addr = host:getPeerAddress(0)
print("peer 0 address: " .. tostring(addr))

-- ---- Stub: NetworkHost:getAddress ----------------------------------------
--@api-stub: NetworkHost:getAddress
-- Display the host's own address for sharing with friends.
local my_addr = host:getAddress()
print("host address: " .. tostring(my_addr))

-- ---- Stub: NetworkHost:getPeerLimit --------------------------------------
--@api-stub: NetworkHost:getPeerLimit
-- Show the max peer count in the server info panel.
local max_peers = host:getPeerLimit()
print("max peers: " .. tostring(max_peers))

-- ---- Stub: NetworkHost:getChannelLimit -----------------------------------
--@api-stub: NetworkHost:getChannelLimit
-- Display the channel count for debugging protocol issues.
local channels = host:getChannelLimit()
print("channel limit: " .. tostring(channels))

-- ---- Stub: NetworkHost:setChannelLimit -----------------------------------
--@api-stub: NetworkHost:setChannelLimit
-- Increase channels to 4 for a game that separates reliable chat,
-- unreliable position, reliable events, and voice.
host:setChannelLimit(4)
print("channel limit set to 4")

-- ---- Stub: NetworkHost:getBandwidthLimit ---------------------------------
--@api-stub: NetworkHost:getBandwidthLimit
-- Read bandwidth limits for network diagnostics.
local bw_in, bw_out = host:getBandwidthLimit()
print(string.format("bandwidth: in=%s out=%s", tostring(bw_in), tostring(bw_out)))

-- ---- Stub: NetworkHost:getConnectedPeerCount -----------------------------
--@api-stub: NetworkHost:getConnectedPeerCount
-- Display player count in the lobby: "3/16 players".
local connected = host:getConnectedPeerCount()
print("connected peers: " .. tostring(connected))

-- ---- Stub: NetworkHost:getConnectedPeerIds -------------------------------
--@api-stub: NetworkHost:getConnectedPeerIds
-- Iterate connected peers to broadcast a game state snapshot.
local peer_ids = host:getConnectedPeerIds()
print("connected peer IDs: " .. table.concat(peer_ids or {}, ", "))

-- ---- Stub: NetworkHost:getPeerStats --------------------------------------
--@api-stub: NetworkHost:getPeerStats
-- Show detailed stats for a peer in the network debug panel.
local stats = host:getPeerStats(0)
if stats then
    print(string.format("peer 0 stats: sent=%d recv=%d loss=%.1f%%",
        stats.packets_sent or 0, stats.packets_received or 0, stats.packet_loss or 0))
end

-- ---- Stub: NetworkHost:destroy -------------------------------------------
--@api-stub: NetworkHost:destroy
-- Destroy the host when shutting down the multiplayer session.
host:destroy()
print("network host destroyed")

-- ---- Stub: NetworkHost:isDestroyed ---------------------------------------
--@api-stub: NetworkHost:isDestroyed
-- Guard against using a destroyed host.
local destroyed = host:isDestroyed()
print("host destroyed: " .. tostring(destroyed))

-- ---- Stub: NetworkHost:getRole -------------------------------------------
--@api-stub: NetworkHost:getRole
-- Display the host's role (server/client) in the HUD.
local role = server:getRole()
print("server role: " .. tostring(role))

-- ---- Stub: NetworkHost:isServer ------------------------------------------
--@api-stub: NetworkHost:isServer
-- Branch logic based on whether this is the authoritative server.
print("is server: " .. tostring(server:isServer()))

-- ---- Stub: NetworkHost:isClient ------------------------------------------
--@api-stub: NetworkHost:isClient
-- Branch logic for client-side prediction.
print("client is client: " .. tostring(client:isClient()))


-- =============================================================================
-- NetworkRuntime — HTTP, TCP, WebSocket
-- =============================================================================

-- ---- Stub: lurek.network.newRuntime --------------------------------------
--@api-stub: lurek.network.newRuntime
-- Create a runtime for HTTP/TCP/WebSocket operations.
local runtime = lurek.network.newRuntime()
print("network runtime created")

-- ---- Stub: NetworkRuntime:httpRequest ------------------------------------
--@api-stub: NetworkRuntime:httpRequest
-- Fetch a leaderboard from a REST API.
runtime:httpRequest("GET", "https://api.example.com/leaderboard", {
    headers = { ["Authorization"] = "Bearer token123" },
    callback = function(status, body)
        print(string.format("  HTTP %d: %d bytes", status, #body))
    end,
})
print("HTTP GET leaderboard request queued")

-- ---- Stub: NetworkRuntime:tcpConnect -------------------------------------
--@api-stub: NetworkRuntime:tcpConnect
-- Open a TCP connection to a chat relay server.
local tcp_id = runtime:tcpConnect("chat.example.com", 9000)
print("TCP connecting to chat.example.com:9000 (id: " .. tostring(tcp_id) .. ")")

-- ---- Stub: NetworkRuntime:tcpSend ----------------------------------------
--@api-stub: NetworkRuntime:tcpSend
-- Send a chat message over TCP.
runtime:tcpSend(tcp_id, "Hello from Lurek2D!\n")
print("TCP message sent")

-- ---- Stub: NetworkRuntime:tcpClose ---------------------------------------
--@api-stub: NetworkRuntime:tcpClose
-- Close the TCP connection when leaving the chat.
runtime:tcpClose(tcp_id)
print("TCP connection closed")

-- ---- Stub: NetworkRuntime:wsConnect --------------------------------------
--@api-stub: NetworkRuntime:wsConnect
-- Open a WebSocket connection for real-time multiplayer sync.
local ws_id = runtime:wsConnect("wss://game.example.com/sync")
print("WebSocket connecting (id: " .. tostring(ws_id) .. ")")

-- ---- Stub: NetworkRuntime:wsSend -----------------------------------------
--@api-stub: NetworkRuntime:wsSend
-- Send a player position update over WebSocket.
runtime:wsSend(ws_id, '{"type":"pos","x":100,"y":200}')
print("WebSocket message sent")

-- ---- Stub: NetworkRuntime:wsClose ----------------------------------------
--@api-stub: NetworkRuntime:wsClose
-- Close the WebSocket when disconnecting.
runtime:wsClose(ws_id)
print("WebSocket closed")

-- ---- Stub: NetworkRuntime:poll -------------------------------------------
--@api-stub: NetworkRuntime:poll
-- Poll all runtime connections for incoming data.  Call every frame.
local events = runtime:poll()
print("runtime poll: " .. tostring(#(events or {})) .. " events")

-- ---- Stub: NetworkRuntime:shutdown ---------------------------------------
--@api-stub: NetworkRuntime:shutdown
-- Shut down all runtime connections cleanly on game exit.
runtime:shutdown()
print("network runtime shut down")
-- content/examples/network.lua
-- Lurek2D lurek.network API Reference
-- Run with: cargo run -- content/examples/network

-- =============================================================================
-- STUBS: 40 uncovered lurek.network API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.network.newHost -----------------------------------------
--@api-stub: lurek.network.newHost
-- Create a generic peer-to-peer host -- useful for LAN co-op where every
-- player can both send and receive without a dedicated server.
local host = lurek.network.newHost({ address = "*", port = 7777, peers = 8, channels = 2 })
print("host bound at:", host:getAddress())

-- ---- Stub: lurek.network.newServer ---------------------------------------
--@api-stub: lurek.network.newServer
-- Create a dedicated server host -- clients connect to it, it never connects
-- outward.  `peers` sets the maximum simultaneous players.
local server = lurek.network.newServer({ port = 7777, peers = 16, channels = 2 })
print("server listening on port 7777, role:", server:getRole())

-- ---- Stub: lurek.network.newClient ---------------------------------------
--@api-stub: lurek.network.newClient
-- Create a client that connects to a known server address -- the `connect`
-- event arrives on the next service() call once the handshake completes.
local client = lurek.network.newClient({ address = "127.0.0.1", port = 7777, channels = 2 })
print("client created, role:", client:getRole())

-- ---- Stub: lurek.network.newRuntime --------------------------------------
--@api-stub: lurek.network.newRuntime
-- Create a background runtime for async HTTP, TCP, and WebSocket requests --
-- the game loop stays responsive while network I/O runs on a worker thread.
local rt = lurek.network.newRuntime()
print("async network runtime started")

-- ---- Stub: lurek.network.pack --------------------------------------------
--@api-stub: lurek.network.pack
-- Serialise any Lua value to a compact binary MessagePack blob ready to
-- send over ENet -- more efficient than JSON for frequent game-state updates.
local payload = { pos = { x = 100.5, y = 200.0 }, hp = 80 }
local packed = lurek.network.pack(payload)
print("packed", #packed, "bytes")

-- ---- Stub: lurek.network.unpack ------------------------------------------
--@api-stub: lurek.network.unpack
-- Deserialise a MessagePack blob back to a Lua table on the receiver side --
-- always unpack before reading individual fields.
local payload = { pos = { x = 100.5, y = 200.0 }, hp = 80 }
local blob = lurek.network.pack(payload)
local decoded = lurek.network.unpack(blob)
if decoded then
    print("received hp:", decoded.hp)
end

-- ---- Stub: lurek.network.createLobby -------------------------------------
--@api-stub: lurek.network.createLobby
-- Broadcast your game session over LAN so other players on the same network
-- can discover and join without manually entering an IP address.
local lobby = lurek.network.createLobby("my_game", 7777, 1, 4)
if lobby then
    print("lobby created, session:", lobby.name)
end

-- ---- Stub: lurek.network.discoverLobbies ---------------------------------
--@api-stub: lurek.network.discoverLobbies
-- Scan the LAN for active game sessions and present them in a lobby browser
-- without requiring players to know the server's IP address.
local lobbies = lurek.network.discoverLobbies(600)  -- wait 600 ms
if lobbies then
    print("found", #lobbies, "lobby/lobbies")
    for _, l in ipairs(lobbies) do
        print(" ", l.name, "at", l.address, "port", l.port)
    end
end

-- ---- Stub: lurek.network.syncEntity --------------------------------------
--@api-stub: lurek.network.syncEntity
-- Broadcast a packed entity snapshot to all connected peers in one call --
-- use in lurek.process() on the server each frame for authoritative state.
local entity = { id = 42, x = 150.0, y = 80.0, hp = 95 }
lurek.network.syncEntity(server, entity)

-- -----------------------------------------------------------------------------
-- NetworkHost methods
-- -----------------------------------------------------------------------------

-- ---- Stub: NetworkHost:service -------------------------------------------
--@api-stub: NetworkHost:service
-- Poll for one network event per call -- call in lurek.process() in a loop
-- until service() returns nil to drain the entire incoming queue.
local event = server:service()
if event then
    print("event:", event.type, "peer:", event.peer_id)
end

-- ---- Stub: NetworkHost:flush ---------------------------------------------
--@api-stub: NetworkHost:flush
-- Force immediate delivery of queued outgoing packets -- useful at the end
-- of a frame to minimise latency when send() is called many times per tick.
server:flush()
print("pending sends flushed")

-- ---- Stub: NetworkHost:disconnect ----------------------------------------
--@api-stub: NetworkHost:disconnect
-- Politely disconnect a peer -- the remote side receives a DISCONNECT event.
-- Use this when a player leaves the game voluntarily (quit, end of match).
server:disconnect(1, 0)  -- peer_id = 1, data = 0
print("disconnect signal sent to peer 1")

-- ---- Stub: NetworkHost:disconnectNow -------------------------------------
--@api-stub: NetworkHost:disconnectNow
-- Hard disconnect without the ENet handshake -- use when the peer is
-- unresponsive or when you need to kick them instantly (e.g. anti-cheat).
server:disconnectNow(2, 0)
print("peer 2 force-disconnected")

-- ---- Stub: NetworkHost:resetPeer -----------------------------------------
--@api-stub: NetworkHost:resetPeer
-- Silently drop the peer without sending a notification -- use when the
-- remote side is already gone (timeout) and there is nothing to notify.
server:resetPeer(3)
print("peer 3 silently reset")

-- ---- Stub: NetworkHost:ping ----------------------------------------------
--@api-stub: NetworkHost:ping
-- Measure round-trip time to a peer for lag display in the scoreboard --
-- the result appears on the next service() call as a PING event.
server:ping(1)
print("ping sent to peer 1")

-- ---- Stub: NetworkHost:getRoundTripTime ----------------------------------
--@api-stub: NetworkHost:getRoundTripTime
-- Read RTT to decide whether to display a lag warning overlay --
-- above ~150 ms most games show a warning icon in the player list.
local rtt = server:getRoundTripTime(1)
print(string.format("peer 1 RTT: %d ms", rtt or 0))

-- ---- Stub: NetworkHost:getPeerState --------------------------------------
--@api-stub: NetworkHost:getPeerState
-- Read the connection state before sending to skip peers that are still
-- in the handshake phase and not yet ready to receive game data.
local state = server:getPeerState(1)
print("peer 1 state:", state)  -- "connected", "connecting", "disconnected"

-- ---- Stub: NetworkHost:getPeerAddress ------------------------------------
--@api-stub: NetworkHost:getPeerAddress
-- Log the remote IP in the server's player registry and use it for
-- IP-ban enforcement before allowing a peer to join the session.
local addr = server:getPeerAddress(1)
print("peer 1 address:", addr or "unknown")

-- ---- Stub: NetworkHost:getAddress ----------------------------------------
--@api-stub: NetworkHost:getAddress
-- Read the local bind address to display in the lobby browser so other
-- players can connect using the correct IP and port.
local addr = server:getAddress()
print("server listening at:", addr)

-- ---- Stub: NetworkHost:getPeerLimit --------------------------------------
--@api-stub: NetworkHost:getPeerLimit
-- Read the peer limit to display remaining open slots in the lobby browser
-- and to reject join requests when the server is full.
local limit = server:getPeerLimit()
local connected = server:getConnectedPeerCount()
print(string.format("players: %d / %d", connected, limit))

-- ---- Stub: NetworkHost:getChannelLimit -----------------------------------
--@api-stub: NetworkHost:getChannelLimit
-- Read the channel count to confirm it matches the value used by clients --
-- a mismatch causes silent packet drops that are hard to diagnose.
print("channels per connection:", server:getChannelLimit())

-- ---- Stub: NetworkHost:setChannelLimit -----------------------------------
--@api-stub: NetworkHost:setChannelLimit
-- Increase the channel limit when you need separate reliable and unreliable
-- streams (e.g. channel 0 = critical events, channel 1 = position updates).
server:setChannelLimit(4)
print("channel limit set to 4")

-- ---- Stub: NetworkHost:getBandwidthLimit ---------------------------------
--@api-stub: NetworkHost:getBandwidthLimit
-- Check the configured bandwidth cap to display throttle status in a
-- developer overlay or to adapt game-state broadcast frequency.
local bw = server:getBandwidthLimit()
print("incoming:", bw.incoming, "B/s  outgoing:", bw.outgoing, "B/s")

-- ---- Stub: NetworkHost:getConnectedPeerCount -----------------------------
--@api-stub: NetworkHost:getConnectedPeerCount
-- Poll this each frame to update the player count display and to decide
-- whether to start or end a match based on minimum player requirements.
print("connected players:", server:getConnectedPeerCount())

-- ---- Stub: NetworkHost:getConnectedPeerIds -------------------------------
--@api-stub: NetworkHost:getConnectedPeerIds
-- Enumerate all connected peers to broadcast a message to every player or
-- to build the scoreboard without maintaining a separate player ID list.
local ids = server:getConnectedPeerIds()
print("connected peer IDs:")
for _, id in ipairs(ids) do
    print("  peer", id, "@", server:getPeerAddress(id))
end

-- ---- Stub: NetworkHost:getPeerStats --------------------------------------
--@api-stub: NetworkHost:getPeerStats
-- Log stats to the developer overlay to diagnose packet loss and
-- latency spikes during play-testing.
local stats = server:getPeerStats(1)
if stats then
    print(string.format("peer 1: RTT %d ms, sent %d, recv %d",
          stats.rtt or 0, stats.packets_sent or 0, stats.packets_recv or 0))
end

-- ---- Stub: NetworkHost:destroy -------------------------------------------
--@api-stub: NetworkHost:destroy
-- Close the socket and release ENet resources when the session ends --
-- call this during scene cleanup so the port is freed for the next game.
if not server:isDestroyed() then
    server:destroy()
    print("server socket closed")
end

-- ---- Stub: NetworkHost:isDestroyed ---------------------------------------
--@api-stub: NetworkHost:isDestroyed
-- Guard all network calls with isDestroyed() to prevent use-after-destroy
-- errors when the host is cleaned up during scene transitions.
if server:isDestroyed() then
    print("host already destroyed -- skip network calls")
end

-- ---- Stub: NetworkHost:getRole -------------------------------------------
--@api-stub: NetworkHost:getRole
-- Read the role to drive different code paths on the same code base --
-- server runs authority logic, client runs prediction and reconciliation.
print("role:", server:getRole())  -- "server"

-- ---- Stub: NetworkHost:isServer ------------------------------------------
--@api-stub: NetworkHost:isServer
-- Use to branch authority logic -- only the server modifies game state;
-- clients send inputs and wait for state updates.
if server:isServer() then
    print("running authoritative game logic")
end

-- ---- Stub: NetworkHost:isClient ------------------------------------------
--@api-stub: NetworkHost:isClient
-- Use to branch prediction logic -- clients run speculative movement and
-- apply server corrections when the authoritative update arrives.
if client:isClient() then
    print("running client prediction")
end

-- -----------------------------------------------------------------------------
-- NetworkRuntime methods
-- -----------------------------------------------------------------------------

-- ---- Stub: NetworkRuntime:httpRequest ------------------------------------
--@api-stub: NetworkRuntime:httpRequest
-- Fetch leaderboard data, patch notes, or authentication tokens without
-- blocking the game loop -- responses arrive via poll().
rt:httpRequest({
    method  = "GET",
    url     = "https://api.example.com/scores?game=lurek",
    id      = "leaderboard",
})
print("HTTP GET dispatched")

-- ---- Stub: NetworkRuntime:tcpConnect -------------------------------------
--@api-stub: NetworkRuntime:tcpConnect
-- Open a raw TCP connection to a custom game server or chat backend --
-- returns a connection handle used in subsequent tcpSend / tcpClose calls.
local conn_id = rt:tcpConnect("127.0.0.1:8080")
print("TCP connection handle:", conn_id)

-- ---- Stub: NetworkRuntime:tcpSend ----------------------------------------
--@api-stub: NetworkRuntime:tcpSend
-- Send raw bytes over the TCP connection -- use for custom protocols where
-- you control the framing (e.g. a length-prefixed message format).
local conn_id = 1
rt:tcpSend(conn_id, "HELLO lurek\n")
print("TCP message sent")

-- ---- Stub: NetworkRuntime:tcpClose ---------------------------------------
--@api-stub: NetworkRuntime:tcpClose
-- Close the TCP connection cleanly when the session ends or the server
-- sends a logout response -- prevents the OS from leaving sockets in TIME_WAIT.
local conn_id = 1
rt:tcpClose(conn_id)
print("TCP connection", conn_id, "closed")

-- ---- Stub: NetworkRuntime:wsConnect --------------------------------------
--@api-stub: NetworkRuntime:wsConnect
-- Connect to a WebSocket server for live chat, matchmaking, or push
-- notifications -- the connection is identified by an integer handle.
local ws_id = rt:wsConnect("ws://localhost:9001/match")
print("WebSocket handle:", ws_id)

-- ---- Stub: NetworkRuntime:wsSend -----------------------------------------
--@api-stub: NetworkRuntime:wsSend
-- Push a JSON or plain-text message to the WebSocket server -- use for
-- real-time chat, matchmaking requests, or inventory sync events.
local ws_id = 1
rt:wsSend(ws_id, '{"action":"find_match","mode":"ranked"}')
print("WebSocket message sent")

-- ---- Stub: NetworkRuntime:wsClose ----------------------------------------
--@api-stub: NetworkRuntime:wsClose
-- Gracefully close the WebSocket when leaving the lobby or ending the
-- session so the server is notified rather than timing out the connection.
local ws_id = 1
rt:wsClose(ws_id)
print("WebSocket closed")

-- ---- Stub: NetworkRuntime:poll -------------------------------------------
--@api-stub: NetworkRuntime:poll
-- Drain all completed async responses each frame -- call in lurek.process()
-- and dispatch events by type ("http", "tcp_data", "ws_message", etc.).
local events = rt:poll()
for _, ev in ipairs(events) do
    if ev.type == "http" then
        print("HTTP response id=", ev.id, "status=", ev.status)
    elseif ev.type == "ws_message" then
        print("WS message:", ev.data)
    end
end

-- ---- Stub: NetworkRuntime:shutdown ---------------------------------------
--@api-stub: NetworkRuntime:shutdown
-- Stop the background network thread cleanly when the game exits or the
-- player navigates to the main menu -- prevents thread leaks between scenes.
rt:shutdown()
print("async network runtime shut down")
