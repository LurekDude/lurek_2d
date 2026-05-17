-- content/examples/network.lua
-- lurek.network API examples: ENet hosts, async HTTP/TCP/WebSocket, lobbies, rooms, relay, prediction.
-- Run: cargo run -- content/examples/network.lua

--@api-stub: lurek.network.newHost
-- Creates a network host from an options table
do
  -- newHost creates a raw ENet host bound to a specific address.
  -- Use this when you need full control over peer-to-peer topology (not client/server).
  -- Options:
  --   addr       = "ip:port"  (required) local bind address; use port 0 for OS-assigned
  --   maxPeers   = number     (optional, default 32) max simultaneous connections
  --   channels   = number     (optional, default 2)  logical channels per peer
  --   inBandwidth  = number   (optional) incoming bandwidth cap in bytes/sec, 0 = unlimited
  --   outBandwidth = number   (optional) outgoing bandwidth cap in bytes/sec, 0 = unlimited
  local host = lurek.network.newHost{
    addr = "0.0.0.0:5555",
    maxPeers = 32,
    channels = 2,
  }
  -- The host is ready to accept connections or connect to others.
  lurek.log.info("listening on " .. host:getAddress(), "net")
  -- Always destroy when done to release the port and memory.
  host:destroy()
end

--@api-stub: lurek.network.newServer
-- Creates a server host from an options table
do
  -- newServer is a convenience wrapper around newHost with role = "server".
  -- Servers are authoritative — they accept incoming client connections.
  -- Options:
  --   port       = number  (required) port to listen on
  --   maxPeers   = number  (optional, default 32) max clients
  --   channels   = number  (optional, default 2)  channel count
  -- Typical multiplayer setup: one server, many clients.
  local server = lurek.network.newServer{
    port = 5555,
    maxPeers = 16,
    channels = 2,
  }
  lurek.log.info("server up on " .. server:getAddress(), "net")
  server:destroy()
end

--@api-stub: lurek.network.newClient
-- Creates a client host and connects to an address
do
  -- newClient creates a host with role = "client" and immediately attempts
  -- to connect to the given address. If the server is unreachable, the
  -- connect will eventually time out (signaled via service() as a disconnect event).
  -- Options:
  --   addr     = "ip:port"  (required) remote server address
  --   channels = number     (optional) channel count to negotiate
  --   data     = number     (optional) connect handshake data (e.g. protocol version)
  pcall(function()
    local client = lurek.network.newClient{
      addr = "127.0.0.1:5555",
      channels = 2,
    }
    -- After creation, poll client:service() in your game loop.
    -- A "connect" event means the server accepted us.
    lurek.log.info("dialling " .. client:getAddress(), "net")
    client:destroy()
  end)
end

--@api-stub: lurek.network.newRuntime
-- Creates a background network runtime
do
  -- The NetworkRuntime runs async I/O on a background thread, separate from
  -- ENet hosts. Use it for HTTP requests, TCP streams, and WebSocket connections
  -- that should not block your game loop.
  -- Poll results each frame with rt:poll().
  local rt = lurek.network.newRuntime()
  -- Fire-and-forget GET — response will appear in poll() later.
  rt:httpGet("http://127.0.0.1:9/version")
  -- Shut down cleanly when the game exits.
  function lurek.quit() rt:shutdown() end
end

--@api-stub: lurek.network.pack
-- Packs a supported Lua value into a binary network message string
do
  -- pack serializes Lua tables, numbers, strings, booleans, and nil into a
  -- compact binary format suitable for sending over network hosts.
  -- Supported types: nil, boolean, integer, number, string, table (array or map).
  -- Nested tables are allowed. Functions, userdata, and threads are NOT supported.
  local snapshot = { x = 128.5, y = 64.0, hp = 87, weapon = "rifle" }
  local bytes = lurek.network.pack(snapshot)
  -- The result is a binary string — send it with host:send() or host:broadcast().
  lurek.log.debug("packed " .. #bytes .. " bytes", "net")
end

--@api-stub: lurek.network.unpack
-- Unpacks a binary network message string into Lua values
do
  -- unpack is the inverse of pack — it restores the original Lua value from bytes.
  -- Use this on the receiving end when you get data from a "receive" event.
  local payload = lurek.network.pack({ id = 42, action = "fire" })
  local msg = lurek.network.unpack(payload)
  if msg then
    -- msg is now a table identical to the original.
    lurek.log.info("received action=" .. msg.action .. " id=" .. msg.id, "net")
  end
end

--@api-stub: lurek.network.createLobby
-- Broadcasts lobby information and returns it as a table
do
  -- createLobby advertises a game session on the local network via UDP broadcast.
  -- Other players on the same LAN can find it with discoverLobbies().
  -- Parameters: name, port, current_player_count (default 1), max_players (default 8).
  -- Returns a lobby info table: { name, port, player_count, max_players, host }.
  local lobby = lurek.network.createLobby("Tom's Co-op", 5555, 1, 4)
  lurek.log.info("advertised lobby " .. lobby.name .. " on port " .. lobby.port, "net")
end

--@api-stub: lurek.network.discoverLobbies
-- Discovers broadcast lobbies
do
  -- discoverLobbies listens for UDP broadcast packets from createLobby calls
  -- on the local network. It blocks for up to timeout_ms (default 500) then
  -- returns all lobbies found.
  -- Each entry: { name, port, player_count, max_players, host }.
  local lobbies = lurek.network.discoverLobbies(750)
  for i, info in ipairs(lobbies) do
    -- Show discovered lobbies in a server browser UI.
    lurek.log.info(i .. ": " .. info.name .. " " .. info.host .. ":" .. info.port, "lobby")
  end
end

--@api-stub: lurek.network.createRoom
-- Creates a local room record
do
  -- Rooms are in-memory matchmaking records for organizing players before
  -- a game starts. They exist only in the current process (not networked).
  -- Useful for local lobby screens, split-screen selection, or testing.
  -- Parameters: name, host_id, max_players (default 8).
  -- Returns: { id, name, host, player_count, max_players }.
  local room = lurek.network.createRoom("Ranked-1", "hostA", 6)
  -- Join our own room (increments player_count).
  local same = lurek.network.joinRoom(room.id)
  lurek.log.info("room " .. room.id .. " players=" .. (same and same.player_count or 0), "match")
  -- List all rooms currently tracked.
  local _all = lurek.network.listRooms()
  -- Leave and clean up.
  lurek.network.leaveRoom(room.id)
end

--@api-stub: lurek.network.joinRoom
-- Joins a room by id when available
do
  -- joinRoom increments the player count in an existing room.
  -- Returns the updated room info table, or nil if the room id does not exist.
  local room = lurek.network.createRoom("casual", "hostB", 3)
  local joined = lurek.network.joinRoom(room.id)
  if joined then
    local joined_room = joined --[[@as {id: string, player_count: integer}]]
    lurek.log.debug("joined room=" .. joined_room.id .. " count=" .. joined_room.player_count, "match")
  end
end

--@api-stub: lurek.network.leaveRoom
-- Leaves a room by id when available
do
  -- leaveRoom decrements the player count. Returns the updated room info,
  -- or nil if the room does not exist.
  local room = lurek.network.createRoom("coop", "hostC", 3)
  local _ = lurek.network.joinRoom(room.id)
  local left = lurek.network.leaveRoom(room.id)
  if left then
    local left_room = left --[[@as {id: string}]]
    lurek.log.debug("left room=" .. left_room.id, "match")
  end
end

--@api-stub: lurek.network.listRooms
-- Lists known local room records
do
  -- Returns an array of all room info tables currently tracked in memory.
  -- Useful for rendering a room browser or debugging matchmaking.
  local rooms = lurek.network.listRooms()
  lurek.log.debug("room count=" .. #rooms, "match")
end

--@api-stub: lurek.network.newRelayTicket
-- Creates an encoded relay ticket
do
  -- Relay tickets encode a room_id + peer_id pair into a single opaque string.
  -- Exchange tickets between peers so they know who to punch through to.
  -- Workflow: create ticket → send to relay server → relay forwards to partner →
  -- partner parses → partner sends a punch probe back.
  local ticket = lurek.network.newRelayTicket("room-1", "peer-A")
  local parsed = lurek.network.parseRelayTicket(ticket)
  if parsed then
    -- Build a UDP probe so the remote peer can learn our public address.
    local probe = lurek.network.makePunchProbe(parsed.peer_id)
    local from_peer = lurek.network.parsePunchProbe(probe)
    lurek.log.debug("relay ticket peer=" .. tostring(from_peer), "relay")
  end
end

--@api-stub: lurek.network.parseRelayTicket
-- Parses an encoded relay ticket
do
  -- parseRelayTicket decodes a ticket string back into { room_id, peer_id }.
  -- Returns nil if the token is malformed or corrupted.
  local token = lurek.network.newRelayTicket("room-2", "peer-B")
  local parsed = lurek.network.parseRelayTicket(token)
  if parsed then lurek.log.debug(parsed.room_id .. ":" .. parsed.peer_id, "relay") end
end

--@api-stub: lurek.network.makePunchProbe
-- Creates a relay punch probe payload for a peer id
do
  -- A punch probe is a small binary payload containing a peer id.
  -- Send this via UDP to punch through NAT — the other side parses it
  -- to learn your identity and respond.
  local probe = lurek.network.makePunchProbe("peer-C")
  lurek.log.debug("probe bytes=" .. #probe, "relay")
end

--@api-stub: lurek.network.parsePunchProbe
-- Parses a relay punch probe payload
do
  -- parsePunchProbe extracts the peer id from a received probe payload.
  -- Returns nil if the payload is invalid.
  local probe = lurek.network.makePunchProbe("peer-D")
  local who = lurek.network.parsePunchProbe(probe)
  lurek.log.debug("probe peer=" .. tostring(who), "relay")
end

--@api-stub: lurek.network.predictLinear
-- Predicts an entity snapshot forward by linear velocity
do
  -- Client-side prediction: move an entity forward using its velocity and dt
  -- so the player sees smooth motion between server ticks.
  -- Snapshot fields: id, tick, x, y, vx, vy.
  -- Returns a new snapshot with x/y advanced by vx*dt / vy*dt and tick+1.
  local now = { id = 1, tick = 10, x = 0.0, y = 0.0, vx = 2.0, vy = 0.0 }
  local predicted = lurek.network.predictLinear(now, 0.1)
  -- predicted.x is now 0.2 (0.0 + 2.0 * 0.1)
  -- When the server snapshot arrives, reconcile to correct drift.
  local server = { id = 1, tick = 11, x = 0.18, y = 0.0, vx = 2.0, vy = 0.0 }
  local smooth = lurek.network.reconcileSnapshot(predicted, server, 0.5)
  lurek.log.debug("reconciled x=" .. smooth.x, "net-sync")
end

--@api-stub: lurek.network.reconcileSnapshot
-- Reconciles a predicted snapshot toward an authoritative snapshot
do
  -- reconcileSnapshot blends a client-predicted state toward the server truth.
  -- alpha controls the blend: 0.0 = keep predicted, 1.0 = snap to server.
  -- Typical values: 0.3-0.6 for smooth correction without visible snapping.
  -- Fields are interpolated: out.x = lerp(pred.x, auth.x, alpha).
  local predicted = { id = 2, tick = 20, x = 1.0, y = 0.0, vx = 1.0, vy = 0.0 }
  local server = { id = 2, tick = 20, x = 1.2, y = 0.1, vx = 1.0, vy = 0.0 }
  local out = lurek.network.reconcileSnapshot(predicted, server, 0.5)
  -- out.x = 1.1 (halfway between 1.0 and 1.2)
  lurek.log.debug("reconciled snapshot tick=" .. out.tick, "net-sync")
end

--@api-stub: lurek.network.syncEntity
-- Broadcasts a packed entity sync payload through a network host
do
  -- syncEntity is a convenience that packs an entity table and broadcasts it
  -- to all peers on the given channel. Combines pack + broadcast in one call.
  -- Parameters: host, entity_id, data_table, channel (default 0), reliable (default false).
  -- Use reliable=false for frequent position updates (unreliable is faster).
  -- Use reliable=true for important state changes (spawn, death, score).
  local server = lurek.network.newServer{ port = 5555, maxPeers = 8 }
  local player = { x = 100.0, y = 200.0, hp = 80 }
  lurek.network.syncEntity(server, 1, player, 0, false)
  server:destroy()
end

--@api-stub: LNetworkHost:service
-- Polls the host for the next incoming network event and returns it, or nil if none.
do
  -- service() must be called every frame (or at your network tick rate).
  -- It returns one event per call: { type, peer_id, ... } or nil.
  -- Event types:
  --   "connect"    — a peer connected. Fields: peer_id, data.
  --   "disconnect" — a peer disconnected. Fields: peer_id, data.
  --   "receive"    — data arrived. Fields: peer_id, channel_id, data (binary string).
  -- Call in a loop to drain all pending events each frame.
  local host = lurek.network.newServer{ port = 5556, maxPeers = 8 }
  function lurek.process(dt)
    local ev = host:service()
    while ev do
      if ev.type == "connect" then
        lurek.log.info("peer " .. ev.peer_id .. " joined", "net")
      elseif ev.type == "receive" then
        local msg = lurek.network.unpack(ev.data)
        lurek.log.debug("got " .. #ev.data .. " bytes from peer " .. ev.peer_id, "net")
      elseif ev.type == "disconnect" then
        lurek.log.info("peer " .. ev.peer_id .. " left", "net")
      end
      ev = host:service()
    end
  end
end

--@api-stub: LNetworkHost:flush
-- Sends all queued outgoing packets on this host immediately without waiting for service.
do
  -- Normally packets are flushed at each service() call. Use flush() when you
  -- need packets sent immediately (e.g. just before destroying the host or at
  -- the end of a frame where service() won't be called again).
  local host = lurek.network.newServer{ port = 5557, maxPeers = 8 }
  host:broadcast(0, lurek.network.pack({ event = "round_end" }), true)
  host:flush()
end

--@api-stub: LNetworkHost:resetPeer
-- Forcibly resets a peer connection by id without sending a graceful disconnect message.
do
  -- resetPeer immediately drops a peer with no farewell packet. The remote
  -- side will eventually time out. Use for kicking cheaters or cleaning up
  -- peers that stopped responding to pings.
  local host = lurek.network.newServer{ port = 5558, maxPeers = 8 }
  local cheater_peer_id = 3
  host:resetPeer(cheater_peer_id)
  lurek.log.warn("force-reset peer " .. cheater_peer_id, "net")
end

--@api-stub: LNetworkHost:ping
-- Sends a ping packet to a peer to trigger a round-trip time measurement.
do
  -- ping() sends a lightweight probe; the RTT result is available later via
  -- getRoundTripTime(). ENet pings automatically at intervals, but call this
  -- manually if you need a fresh measurement right now.
  local host = lurek.network.newServer{ port = 5559, maxPeers = 8 }
  local peer_id = 1
  host:ping(peer_id)
end

--@api-stub: LNetworkHost:getRoundTripTime
-- Returns the last measured round-trip time in milliseconds for a connected peer.
do
  -- getRoundTripTime returns the smoothed RTT from the last ping exchange.
  -- Use it to display latency in the HUD or to adjust prediction/interpolation.
  local host = lurek.network.newServer{ port = 5560, maxPeers = 8 }
  local rtt_ms = host:getRoundTripTime(1)
  if rtt_ms > 150 then
    lurek.log.warn("high latency: " .. rtt_ms .. " ms", "net")
  end
end

--@api-stub: LNetworkHost:getPeerState
-- Returns the current connection state string for a given peer id, such as "connected".
do
  -- Possible states: "disconnected", "connecting", "acknowledging_connect",
  -- "connection_pending", "connection_succeeded", "connected",
  -- "disconnect_later", "disconnecting", "acknowledging_disconnect", "zombie".
  -- Only send data to peers in "connected" state.
  local host = lurek.network.newServer{ port = 5561, maxPeers = 8 }
  local state = host:getPeerState(1)
  if state == "connected" then
    host:send(1, 0, "hello", true)
  end
end

--@api-stub: LNetworkHost:getPeerAddress
-- Returns the remote IP address and port string for a connected peer id, or nil.
do
  -- Useful for logging, banning by IP, or displaying player connections
  -- in a server admin panel.
  local host = lurek.network.newServer{ port = 5562, maxPeers = 8 }
  local addr = host:getPeerAddress(1)
  if addr then lurek.log.info("peer 1 at " .. addr, "net") end
end

--@api-stub: LNetworkHost:getAddress
-- Returns the local bound address and port string for this host.
do
  -- When binding to port 0 the OS assigns a random port.
  -- Use getAddress() to find out which port was actually assigned.
  local host = lurek.network.newHost{ addr = "0.0.0.0:0", maxPeers = 4 }
  local bound = host:getAddress()
  lurek.log.info("bound to " .. bound, "net")
end

--@api-stub: LNetworkHost:getPeerLimit
-- Returns the maximum number of peers this host was configured to accept.
do
  -- Use to display "players: N / max" in a server browser or HUD.
  local host = lurek.network.newServer{ port = 5563, maxPeers = 16 }
  local cap = host:getPeerLimit()
  lurek.log.info("max players: " .. cap, "net")
end

--@api-stub: LNetworkHost:getChannelLimit
-- Returns the number of channels currently configured on this host.
do
  -- Channels let you multiplex different traffic types on one connection.
  -- Common pattern: channel 0 = game state, channel 1 = chat, channel 2 = voice.
  local host = lurek.network.newServer{ port = 5564, maxPeers = 8, channels = 4 }
  local channels = host:getChannelLimit()
  assert(channels >= 2, "need at least 2 channels for state+chat")
end

--@api-stub: LNetworkHost:setChannelLimit
-- Sets the maximum number of channels this host will negotiate with connecting peers.
do
  -- Call before peers connect. Both sides negotiate to the lower channel count.
  -- Increasing channels after connections are established has no effect on
  -- already-connected peers.
  local host = lurek.network.newHost{ addr = "0.0.0.0:0", maxPeers = 8 }
  host:setChannelLimit(4)
  lurek.log.info("now negotiating " .. host:getChannelLimit() .. " channels", "net")
end

--@api-stub: LNetworkHost:getBandwidthLimit
-- Returns the configured incoming and outgoing bandwidth limits in bytes per second.
do
  -- Returns a table: { incoming = number, outgoing = number }.
  -- 0 means unlimited. Use to display throttle settings in admin UI.
  pcall(function()
    local host = lurek.network.newServer{ port = 5565, maxPeers = 8 }
    local bw = host:getBandwidthLimit()
    lurek.log.info("bw in=" .. tostring(bw.incoming) .. " out=" .. tostring(bw.outgoing) .. " B/s", "net")
    host:destroy()
  end)
end

--@api-stub: LNetworkHost:getConnectedPeerCount
-- Returns the number of peers currently in a connected state on this host.
do
  -- Use for "players online" display or to check if the server is full
  -- before advertising in the lobby.
  local host = lurek.network.newServer{ port = 5566, maxPeers = 8 }
  local n = host:getConnectedPeerCount()
  lurek.log.info("players online: " .. n, "net")
end

--@api-stub: LNetworkHost:getConnectedPeerIds
-- Returns a list of all peer ids that are currently connected to this host.
do
  -- Iterate over connected peers to send targeted messages, collect state,
  -- or broadcast a welcome packet to everyone.
  local host = lurek.network.newServer{ port = 5567, maxPeers = 8 }
  for _, pid in ipairs(host:getConnectedPeerIds()) do
    host:send(pid, 1, lurek.network.pack({ welcome = true }), true)
  end
end

--@api-stub: LNetworkHost:getPeerStats
-- Returns a table of packet and byte send and receive statistics for a peer.
do
  -- Stats table fields:
  --   round_trip_time, round_trip_time_variance,
  --   packets_sent, packets_lost, packet_loss,
  --   incoming_bandwidth, outgoing_bandwidth,
  --   incoming_data_total, outgoing_data_total.
  -- Use for network quality monitoring and adaptive bitrate logic.
  local host = lurek.network.newServer{ port = 5568, maxPeers = 8 }
  local stats = host:getPeerStats(1)
  lurek.log.debug("peer 1 sent=" .. stats.packets_sent .. " lost=" .. stats.packets_lost, "net")
end

--@api-stub: LNetworkHost:destroy
-- Destroys this host and releases all ENet resources and peer connections.
do
  -- After destroy(), the host cannot be used. All peers are forcibly disconnected.
  -- Always call in lurek.quit() to release the bound port cleanly.
  local host = lurek.network.newServer{ port = 5569, maxPeers = 8 }
  function lurek.quit()
    host:destroy()
  end
end

--@api-stub: LNetworkHost:isDestroyed
-- Returns true if this host has already been destroyed and can no longer be used.
do
  -- Check before using a host reference that might have been destroyed
  -- elsewhere (e.g. in a quit handler).
  local host = lurek.network.newServer{ port = 5570, maxPeers = 8 }
  host:destroy()
  if host:isDestroyed() then lurek.log.info("host shut down cleanly", "net") end
end

--@api-stub: LNetworkHost:getRole
-- Returns the role string of this host, either "server", "client", or "host".
do
  -- Use getRole() to branch logic: servers run authoritative simulation,
  -- clients run prediction, raw hosts handle custom topologies.
  local host = lurek.network.newServer{ port = 5571, maxPeers = 8 }
  local role = host:getRole()
  lurek.log.info("running as " .. role, "net")
end

--@api-stub: LNetworkHost:isServer
-- Returns true if this host was created with newServer and is running as an authority.
do
  -- Convenience check — equivalent to host:getRole() == "server".
  -- Use to guard server-only logic like world simulation or anti-cheat.
  local host = lurek.network.newServer{ port = 5572, maxPeers = 8 }
  if host:isServer() then
    lurek.log.info("authoritative tick enabled", "net")
  end
end

--@api-stub: LNetworkHost:isClient
-- Returns true if this host was created with newClient and is running as a client.
do
  -- Use to guard client-only logic like input prediction or interpolation.
  local client = lurek.network.newClient{ addr = "127.0.0.1:5555" }
  if client:isClient() then
    lurek.log.info("running prediction-only logic", "net")
  end
end

--@api-stub: LNetworkRuntime:httpRequest
-- Submits a configurable HTTP request asynchronously and returns a request id for polling.
do
  -- httpRequest is the most flexible HTTP method. Provide an options table:
  --   url     = string   (required)
  --   method  = string   (optional, default "GET") — "GET", "POST", "PUT", "DELETE", etc.
  --   headers = table    (optional) key-value header pairs
  --   body    = string   (optional) request body for POST/PUT
  --   timeout = number   (optional) timeout in seconds
  -- Returns a request id — poll rt:poll() to get the response asynchronously.
  local rt = lurek.network.newRuntime()
  local req_id = rt:httpRequest{
    method = "POST",
    url = "http://127.0.0.1:9/scores",
    headers = { ["Content-Type"] = "application/json" },
    body = '{"name":"tom","score":4200}',
    timeout = 5,
  }
  lurek.log.info("submitted score request id=" .. req_id, "net")
end

--@api-stub: LNetworkRuntime:tcpConnect
-- Opens an async TCP connection to a host address and returns a connection id.
do
  -- tcpConnect opens a persistent TCP stream to a remote server.
  -- Use for custom protocols, login servers, or any ordered byte-stream needs.
  -- The connection is non-blocking — poll rt:poll() for connect/data events.
  local rt = lurek.network.newRuntime()
  local conn = rt:tcpConnect("127.0.0.1:9")
  lurek.log.info("dialling tcp conn=" .. conn, "net")
end

--@api-stub: LNetworkRuntime:tcpSend
-- Sends a string payload over an open TCP connection identified by its connection id.
do
  -- tcpSend writes bytes into the TCP stream. The data is buffered and flushed
  -- by the background runtime. Use line terminators or length prefixes for framing.
  local rt = lurek.network.newRuntime()
  local conn = rt:tcpConnect("127.0.0.1:9")
  rt:tcpSend(conn, "LOGIN tom\n")
end

--@api-stub: LNetworkRuntime:tcpClose
-- Closes an open TCP connection by its connection id and releases the slot.
do
  -- After tcpClose, the connection id becomes invalid. Any pending data
  -- in the write buffer may or may not be sent (use flush patterns if needed).
  local rt = lurek.network.newRuntime()
  local conn = rt:tcpConnect("127.0.0.1:9")
  rt:tcpClose(conn)
end

--@api-stub: LNetworkRuntime:wsConnect
-- Opens an async WebSocket connection to a URL and returns a connection id.
do
  -- wsConnect starts a WebSocket handshake with a remote server.
  -- Use WebSockets for lobby chat, real-time leaderboards, or matchmaking.
  -- The URL must start with ws:// or wss://.
  -- Poll rt:poll() for connect confirmation and incoming messages.
  local rt = lurek.network.newRuntime()
  local ws = rt:wsConnect("ws://127.0.0.1:9/lobby")
  lurek.log.info("opening websocket id=" .. ws, "net")
end

--@api-stub: LNetworkRuntime:wsSend
-- Sends a text or binary message over an open WebSocket connection by id.
do
  -- wsSend transmits a string as a WebSocket text frame.
  -- Use JSON for structured messages. Binary frames use raw byte strings.
  local rt = lurek.network.newRuntime()
  local ws = rt:wsConnect("ws://127.0.0.1:9/lobby")
  rt:wsSend(ws, '{"chat":"hello everyone!"}')
end

--@api-stub: LNetworkRuntime:wsClose
-- Closes an open WebSocket connection by its connection id.
do
  -- wsClose sends a WebSocket close frame and releases the connection slot.
  local rt = lurek.network.newRuntime()
  local ws = rt:wsConnect("ws://127.0.0.1:9/lobby")
  rt:wsClose(ws)
end

--@api-stub: LNetworkRuntime:poll
-- Collects and returns all pending responses from async HTTP, TCP, and WebSocket operations.
do
  -- poll() returns an array of response tables. Each has a "type" field:
  --   "http"      — HTTP response. Fields: request_id, status, headers, body.
  --   "tcp_data"  — TCP data received. Fields: id, data.
  --   "tcp_close" — TCP connection closed. Fields: id.
  --   "ws_msg"    — WebSocket message. Fields: id, data.
  --   "ws_close"  — WebSocket closed. Fields: id.
  --   "error"     — Operation failed. Fields: request_id or id, error.
  -- Call every frame to process all pending network responses.
  local rt = lurek.network.newRuntime()
  function lurek.process(dt)
    for _, resp in ipairs(rt:poll()) do
      if resp.type == "http" then
        lurek.log.info("http status=" .. resp.status, "net")
      elseif resp.type == "ws_msg" then
        lurek.log.info("ws: " .. resp.data, "net")
      end
    end
  end
end

--@api-stub: LNetworkRuntime:shutdown
-- Shuts down the network runtime and cancels all pending async network operations.
do
  -- shutdown() stops the background thread and drops all open connections.
  -- Always call in lurek.quit() to ensure clean resource release.
  local rt = lurek.network.newRuntime()
  function lurek.quit()
    rt:shutdown()
  end
end

--@api-stub: LNetworkHost:broadcast
-- Sends a packet to all currently connected peers on a channel with optional reliability.
do
  -- broadcast sends the same data to every connected peer at once.
  -- Parameters: channel_id, data (binary string), reliable (default true).
  -- Use reliable=true for important game events (round start, score update).
  -- Use reliable=false for high-frequency updates (positions, animations).
  local host = lurek.network.newServer({port=7777, maxPeers=32})
  host:broadcast(0, lurek.network.pack({ event = "round_start", map = "arena" }), true)
  lurek.log.info("broadcast sent to all peers", "network")
end

--@api-stub: LNetworkHost:connect
-- Initiates a connection from this client host to a remote server address string.
do
  -- connect() can be called on any host (not just clients) to initiate a
  -- connection to a remote address. Returns the peer_id assigned to this connection.
  -- Parameters: address_string, channels (default 1), connect_data (default 0).
  -- The connect_data value is delivered to the remote in the "connect" event.
  local client = lurek.network.newClient({addr="127.0.0.1:7777"})
  local ok, err = pcall(function()
    local peer = client:connect("127.0.0.1:7777")
    lurek.log.info("connect initiated, peer_id=" .. peer, "network")
  end)
  if not ok then lurek.log.info("connect: no server available", "network") end
end

--@api-stub: LNetworkHost:disconnect
-- Sends a graceful disconnect request to a peer and waits for acknowledgement.
do
  -- disconnect sends a disconnect command and waits for the remote to ack.
  -- The remote will receive a "disconnect" event via service().
  -- Use for clean player logout or session end.
  -- Optional second parameter: disconnect data (integer) passed to remote.
  local host = lurek.network.newServer({port=7778, maxPeers=8})
  host:disconnect(1)
  lurek.log.info("disconnect requested for peer 1", "network")
end

--@api-stub: LNetworkHost:disconnectLater
-- Queues a graceful disconnect to be sent only after all pending outgoing packets are delivered.
do
  -- disconnectLater ensures all queued reliable packets are delivered before
  -- the disconnect fires. Use when you need to send final data (game results,
  -- goodbye message) and then cleanly close the connection.
  local host = lurek.network.newServer({port=7779, maxPeers=8})
  host:send(1, 0, lurek.network.pack({ result = "victory", score = 1500 }), true)
  host:disconnectLater(1)
  lurek.log.info("disconnect-later queued after final data", "network")
end

--@api-stub: LNetworkHost:disconnectNow
-- Immediately terminates a peer connection without waiting for any pending packets.
do
  -- disconnectNow drops the peer instantly. Pending outgoing data is lost.
  -- Use for emergency kicks (detected exploit, server shutting down NOW).
  local host = lurek.network.newServer({port=7780, maxPeers=8})
  host:disconnectNow(1)
  lurek.log.info("disconnect-now issued — peer dropped", "network")
end

--@api-stub: LNetworkRuntime:httpGet
-- Submits an async HTTP GET request to a URL and returns a request id for polling.
do
  -- httpGet is a shorthand for httpRequest with method="GET".
  -- Optional second parameter: headers table.
  -- Returns a request id — match it in poll() responses.
  local rt = lurek.network.newRuntime()
  local id = rt:httpGet("http://127.0.0.1:9/leaderboard", { ["Accept"] = "application/json" })
  lurek.log.info("GET leaderboard, request id=" .. id, "network")
end

--@api-stub: LNetworkRuntime:httpPost
-- Submits an async HTTP POST request with a string body and returns a request id.
do
  -- httpPost is a shorthand for httpRequest with method="POST".
  -- Parameters: url, body_string, optional headers table.
  -- Use for submitting scores, saving game state to a backend, or auth tokens.
  local rt = lurek.network.newRuntime()
  local id = rt:httpPost(
    "http://127.0.0.1:9/save",
    '{"slot":1,"data":"..."}',
    { ["Content-Type"] = "application/json" }
  )
  lurek.log.info("POST save, request id=" .. id, "network")
end

--@api-stub: LNetworkHost:send
-- Sends a packet to a specific peer on a given channel with optional reliable delivery.
do
  -- send targets a single peer (unlike broadcast which hits everyone).
  -- Parameters: peer_id, channel_id, data (binary string), reliable (default true).
  -- Use for private messages, targeted state corrections, or peer-specific commands.
  local host = lurek.network.newServer({port=7781, maxPeers=8})
  local player_state = lurek.network.pack({ x = 50, y = 120, anim = "run" })
  host:send(1, 0, player_state, false)
  lurek.log.info("sent state to peer 1 (unreliable)", "network")
end

--@api-stub: LNetworkHost:setBandwidthLimit
-- Sets the incoming and outgoing bandwidth limits for this host in bytes per second.
do
  -- Throttle bandwidth to prevent saturating slow connections.
  -- Parameters: incoming_limit, outgoing_limit (bytes per second).
  -- Pass 0 for unlimited. Limits are enforced by ENet's bandwidth management.
  local host = lurek.network.newServer({port=7782, maxPeers=8})
  host:setBandwidthLimit(128000, 64000)
  lurek.log.info("bandwidth capped: 128KB/s in, 64KB/s out", "network")
end

--@api-stub: LNetworkRuntime:type
-- Returns the Lua-visible type name for this network host handle
do
  -- type() returns "LNetworkHost" — useful for type-checking in generic code.
  local host = lurek.network.newServer{ port = 5573, maxPeers = 4 }
  lurek.log.info("LNetworkHost:type = " .. host:type(), "net")
  host:destroy()
end

--@api-stub: LNetworkRuntime:typeOf
-- Returns whether this network host handle matches a supported type name
do
  -- typeOf checks against "LNetworkHost" and "Object".
  -- Use for duck-typing checks when receiving userdata from other modules.
  local host = lurek.network.newServer{ port = 5574, maxPeers = 4 }
  lurek.log.info("is LNetworkHost: " .. tostring(host:typeOf("LNetworkHost")), "net")
  lurek.log.info("is Object: " .. tostring(host:typeOf("Object")), "net")
  host:destroy()
end

--@api-stub: LNetworkRuntime:type
-- Returns the Lua-visible type name string for this network runtime handle.
do
  -- type() returns "LNetworkRuntime".
  local rt = lurek.network.newRuntime()
  lurek.log.info(rt:type(), "net")
  rt:shutdown()
end

--@api-stub: LNetworkRuntime:typeOf
-- Returns true if this network runtime handle matches the given type name string.
do
  -- typeOf checks against "LNetworkRuntime" and "Object".
  local rt = lurek.network.newRuntime()
  lurek.log.info("is LNetworkRuntime: " .. tostring(rt:typeOf("LNetworkRuntime")), "net")
  rt:shutdown()
end

print("content/examples/network.lua")

-- =============================================================================
-- STUBS: 38 uncovered lurek.network API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LNetworkHost methods
-- -----------------------------------------------------------------------------
