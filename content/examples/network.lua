-- content/examples/network.lua
-- lurek.network API examples.
-- Run: cargo run -- content/examples/network.lua

--@api-stub: lurek.network.newHost
-- Creates a network host from an options table
do
  local host = lurek.network.newHost{ addr = "0.0.0.0:5555", maxPeers = 32, channels = 2 }
  lurek.log.info("listening on " .. host:getAddress(), "net")
  host:destroy()
end

--@api-stub: lurek.network.newServer
-- Creates a server host from an options table
do
  local server = lurek.network.newServer{ port = 5555, maxPeers = 16, channels = 2 }
  lurek.log.info("server up on " .. server:getAddress(), "net")
  server:destroy()
end

--@api-stub: lurek.network.newClient
-- Creates a client host and connects to an address
do
  pcall(function()
    local client = lurek.network.newClient{ addr = "127.0.0.1:5555", channels = 2 }
    lurek.log.info("dialling " .. client:getAddress(), "net")
    client:destroy()
  end)
end

--@api-stub: lurek.network.newRuntime
-- Creates a background network runtime
do
  local rt = lurek.network.newRuntime()
  rt:httpGet("http://127.0.0.1:9/version")
  function lurek.quit() rt:shutdown() end
end

--@api-stub: lurek.network.pack
-- Packs a supported Lua value into a binary network message string
do
  local snapshot = { x = 128.5, y = 64.0, hp = 87, weapon = "rifle" }
  local bytes = lurek.network.pack(snapshot)
  lurek.log.debug("packed " .. #bytes .. " bytes", "net")
end

--@api-stub: lurek.network.unpack
-- Unpacks a binary network message string into Lua values
do
  local payload = lurek.network.pack({ id = 42, action = "fire" })
  local msg = lurek.network.unpack(payload)
  if msg then
    lurek.log.info("received action=" .. msg.action .. " id=" .. msg.id, "net")
  end
end

--@api-stub: lurek.network.createLobby
-- Broadcasts lobby information and returns it as a table
do
  local lobby = lurek.network.createLobby("Tom's Co-op", 5555, 1, 4)
  lurek.log.info("advertised lobby " .. lobby.name .. " on port " .. lobby.port, "net")
end

--@api-stub: lurek.network.discoverLobbies
-- Discovers broadcast lobbies
do
  local lobbies = lurek.network.discoverLobbies(750)
  for i, info in ipairs(lobbies) do
    lurek.log.info(i .. ": " .. info.name .. " " .. info.host .. ":" .. info.port, "lobby")
  end
end

--@api-stub: lurek.network.createRoom
-- Creates a local room record
do
  local room = lurek.network.createRoom("Ranked-1", "hostA", 6)
  local same = lurek.network.joinRoom(room.id)
  lurek.log.info("room " .. room.id .. " players=" .. (same and same.player_count or 0), "match")
  local _all = lurek.network.listRooms()
  lurek.network.leaveRoom(room.id)
end

--@api-stub: lurek.network.joinRoom
-- Joins a room by id when available
do
  local room = lurek.network.createRoom("casual", "hostB", 3)
  local joined = lurek.network.joinRoom(room.id)
  if joined then lurek.log.debug("joined room=" .. joined.id, "match") end
end

--@api-stub: lurek.network.leaveRoom
-- Leaves a room by id when available
do
  local room = lurek.network.createRoom("coop", "hostC", 3)
  local _ = lurek.network.joinRoom(room.id)
  local left = lurek.network.leaveRoom(room.id)
  if left then lurek.log.debug("left room=" .. left.id, "match") end
end

--@api-stub: lurek.network.listRooms
-- Lists known local room records
do
  local rooms = lurek.network.listRooms()
  lurek.log.debug("room count=" .. #rooms, "match")
end

--@api-stub: lurek.network.newRelayTicket
-- Creates an encoded relay ticket
do
  local ticket = lurek.network.newRelayTicket("room-1", "peer-A")
  local parsed = lurek.network.parseRelayTicket(ticket)
  if parsed then
    local probe = lurek.network.makePunchProbe(parsed.peer_id)
    local from_peer = lurek.network.parsePunchProbe(probe)
    lurek.log.debug("relay ticket peer=" .. tostring(from_peer), "relay")
  end
end

--@api-stub: lurek.network.parseRelayTicket
-- Parses an encoded relay ticket
do
  local token = lurek.network.newRelayTicket("room-2", "peer-B")
  local parsed = lurek.network.parseRelayTicket(token)
  if parsed then lurek.log.debug(parsed.room_id .. ":" .. parsed.peer_id, "relay") end
end

--@api-stub: lurek.network.makePunchProbe
-- Creates a relay punch probe payload for a peer id
do
  local probe = lurek.network.makePunchProbe("peer-C")
  lurek.log.debug("probe bytes=" .. #probe, "relay")
end

--@api-stub: lurek.network.parsePunchProbe
-- Parses a relay punch probe payload
do
  local probe = lurek.network.makePunchProbe("peer-D")
  local who = lurek.network.parsePunchProbe(probe)
  lurek.log.debug("probe peer=" .. tostring(who), "relay")
end

--@api-stub: lurek.network.predictLinear
-- Predicts an entity snapshot forward by linear velocity
do
  local now = { id = 1, tick = 10, x = 0.0, y = 0.0, vx = 2.0, vy = 0.0 }
  local predicted = lurek.network.predictLinear(now, 0.1)
  local server = { id = 1, tick = 11, x = 0.18, y = 0.0, vx = 2.0, vy = 0.0 }
  local smooth = lurek.network.reconcileSnapshot(predicted, server, 0.5)
  lurek.log.debug("reconciled x=" .. smooth.x, "net-sync")
end

--@api-stub: lurek.network.reconcileSnapshot
-- Reconciles a predicted snapshot toward an authoritative snapshot
do
  local predicted = { id = 2, tick = 20, x = 1.0, y = 0.0, vx = 1.0, vy = 0.0 }
  local server = { id = 2, tick = 20, x = 1.2, y = 0.1, vx = 1.0, vy = 0.0 }
  local out = lurek.network.reconcileSnapshot(predicted, server, 0.5)
  lurek.log.debug("reconciled snapshot tick=" .. out.tick, "net-sync")
end

--@api-stub: lurek.network.syncEntity
-- Broadcasts a packed entity sync payload through a network host
do
  local server = lurek.network.newServer{ port = 5555, maxPeers = 8 }
  local player = { x = 100.0, y = 200.0, hp = 80 }
  lurek.network.syncEntity(server, 1, player, 0, false)
  server:destroy()
end


--@api-stub: NetworkHost:service
-- Polls the host for the next incoming network event and returns it, or nil if none.
do
  local host = lurek.network.newServer{ port = 5556, maxPeers = 8 }
  function lurek.process(dt)
    local ev = host:service()
    if ev and ev.type == "receive" then lurek.log.debug("got " .. #ev.data .. " bytes", "net") end
  end
end

--@api-stub: NetworkHost:flush
-- Sends all queued outgoing packets on this host immediately without waiting for service.
do
  local host = lurek.network.newServer{ port = 5557, maxPeers = 8 }
  host:broadcast(0, lurek.network.pack({ event = "round_end" }), true)
  host:flush()
end

--@api-stub: NetworkHost:resetPeer
-- Forcibly resets a peer connection by id without sending a graceful disconnect message.
do
  local host = lurek.network.newServer{ port = 5558, maxPeers = 8 }
  local cheater_peer_id = 3
  host:resetPeer(cheater_peer_id)
  lurek.log.warn("force-reset peer " .. cheater_peer_id, "net")
end

--@api-stub: NetworkHost:ping
-- Sends a ping packet to a peer to trigger a round-trip time measurement.
do
  local host = lurek.network.newServer{ port = 5559, maxPeers = 8 }
  local peer_id = 1
  host:ping(peer_id)
end

--@api-stub: NetworkHost:getRoundTripTime
-- Returns the last measured round-trip time in milliseconds for a connected peer.
do
  local host = lurek.network.newServer{ port = 5560, maxPeers = 8 }
  local rtt_ms = host:getRoundTripTime(1)
  if rtt_ms > 150 then lurek.log.warn("high latency: " .. rtt_ms .. " ms", "net") end
end

--@api-stub: NetworkHost:getPeerState
-- Returns the current connection state string for a given peer id, such as "connected".
do
  local host = lurek.network.newServer{ port = 5561, maxPeers = 8 }
  local state = host:getPeerState(1)
  if state == "connected" then host:send(1, 0, "hello", true) end
end

--@api-stub: NetworkHost:getPeerAddress
-- Returns the remote IP address and port string for a connected peer id, or nil.
do
  local host = lurek.network.newServer{ port = 5562, maxPeers = 8 }
  local addr = host:getPeerAddress(1)
  if addr then lurek.log.info("peer 1 at " .. addr, "net") end
end

--@api-stub: NetworkHost:getAddress
-- Returns the local bound address and port string for this host.
do
  local host = lurek.network.newHost{ addr = "0.0.0.0:0", maxPeers = 4 }
  local bound = host:getAddress()
  lurek.log.info("bound to " .. bound, "net")
end

--@api-stub: NetworkHost:getPeerLimit
-- Returns the maximum number of peers this host was configured to accept.
do
  local host = lurek.network.newServer{ port = 5563, maxPeers = 16 }
  local cap = host:getPeerLimit()
  lurek.log.info("max players: " .. cap, "net")
end

--@api-stub: NetworkHost:getChannelLimit
-- Returns the number of channels currently configured on this host.
do
  local host = lurek.network.newServer{ port = 5564, maxPeers = 8, channels = 4 }
  local channels = host:getChannelLimit()
  assert(channels >= 2, "need at least 2 channels for state+chat")
end

--@api-stub: NetworkHost:setChannelLimit
-- Sets the maximum number of channels this host will negotiate with connecting peers.
do
  local host = lurek.network.newHost{ addr = "0.0.0.0:0", maxPeers = 8 }
  host:setChannelLimit(4)
  lurek.log.info("now negotiating " .. host:getChannelLimit() .. " channels", "net")
end

--@api-stub: NetworkHost:getBandwidthLimit
-- Returns the configured incoming and outgoing bandwidth limits in bytes per second.
do
  pcall(function()
    local host = lurek.network.newServer{ port = 5565, maxPeers = 8 }
    local bw = host:getBandwidthLimit()
    lurek.log.info("bw in=" .. tostring(bw.incoming) .. " out=" .. tostring(bw.outgoing) .. " B/s", "net")
    host:destroy()
  end)
end

--@api-stub: NetworkHost:getConnectedPeerCount
-- Returns the number of peers currently in a connected state on this host.
do
  local host = lurek.network.newServer{ port = 5566, maxPeers = 8 }
  local n = host:getConnectedPeerCount()
  lurek.log.info("players online: " .. n, "net")
end

--@api-stub: NetworkHost:getConnectedPeerIds
-- Returns a list of all peer ids that are currently connected to this host.
do
  local host = lurek.network.newServer{ port = 5567, maxPeers = 8 }
  for _, pid in ipairs(host:getConnectedPeerIds()) do
    host:send(pid, 1, lurek.network.pack({ welcome = true }), true)
  end
end

--@api-stub: NetworkHost:getPeerStats
-- Returns a table of packet and byte send and receive statistics for a peer.
do
  local host = lurek.network.newServer{ port = 5568, maxPeers = 8 }
  local stats = host:getPeerStats(1)
  lurek.log.debug("peer 1 sent=" .. stats.packets_sent .. " lost=" .. stats.packets_lost, "net")
end

--@api-stub: NetworkHost:destroy
-- Destroys this host and releases all ENet resources and peer connections.
do
  local host = lurek.network.newServer{ port = 5569, maxPeers = 8 }
  function lurek.quit()
    host:destroy()
  end
end

--@api-stub: NetworkHost:isDestroyed
-- Returns true if this host has already been destroyed and can no longer be used.
do
  local host = lurek.network.newServer{ port = 5570, maxPeers = 8 }
  host:destroy()
  if host:isDestroyed() then lurek.log.info("host shut down cleanly", "net") end
end

--@api-stub: NetworkHost:getRole
-- Returns the role string of this host, either "server", "client", or "host".
do
  local host = lurek.network.newServer{ port = 5571, maxPeers = 8 }
  local role = host:getRole()
  lurek.log.info("running as " .. role, "net")
end

--@api-stub: NetworkHost:isServer
-- Returns true if this host was created with newServer and is running as an authority.
do
  local host = lurek.network.newServer{ port = 5572, maxPeers = 8 }
  if host:isServer() then
    lurek.log.info("authoritative tick enabled", "net")
  end
end

--@api-stub: NetworkHost:isClient
-- Returns true if this host was created with newClient and is running as a client.
do
  local client = lurek.network.newClient{ addr = "127.0.0.1:5555" }
  if client:isClient() then
    lurek.log.info("running prediction-only logic", "net")
  end
end


--@api-stub: NetworkRuntime:httpRequest
-- Submits a configurable HTTP request asynchronously and returns a request id for polling.
do
  local rt = lurek.network.newRuntime()
  local req_id = rt:httpRequest{
    method = "POST", url = "http://127.0.0.1:9/scores",
    headers = { ["Content-Type"] = "application/json" },
    body = '{"name":"tom","score":4200}', timeout = 1,
  }
  lurek.log.info("submitted score request id=" .. req_id, "net")
end

--@api-stub: NetworkRuntime:tcpConnect
-- Opens an async TCP connection to a host address and returns a connection id.
do
  local rt = lurek.network.newRuntime()
  local conn = rt:tcpConnect("127.0.0.1:9")
  lurek.log.info("dialling tcp conn=" .. conn, "net")
end

--@api-stub: NetworkRuntime:tcpSend
-- Sends a string payload over an open TCP connection identified by its connection id.
do
  local rt = lurek.network.newRuntime()
  local conn = rt:tcpConnect("127.0.0.1:9")
  rt:tcpSend(conn, "LOGIN tom\n")
end

--@api-stub: NetworkRuntime:tcpClose
-- Closes an open TCP connection by its connection id and releases the slot.
do
  local rt = lurek.network.newRuntime()
  local conn = rt:tcpConnect("127.0.0.1:9")
  rt:tcpClose(conn)
end

--@api-stub: NetworkRuntime:wsConnect
-- Opens an async WebSocket connection to a URL and returns a connection id.
do
  local rt = lurek.network.newRuntime()
  local ws = rt:wsConnect("ws://127.0.0.1:9/lobby")
  lurek.log.info("opening websocket id=" .. ws, "net")
end

--@api-stub: NetworkRuntime:wsSend
-- Sends a text or binary message over an open WebSocket connection by id.
do
  local rt = lurek.network.newRuntime()
  local ws = rt:wsConnect("ws://127.0.0.1:9/lobby")
  rt:wsSend(ws, '{"chat":"hello"}')
end

--@api-stub: NetworkRuntime:wsClose
-- Closes an open WebSocket connection by its connection id.
do
  local rt = lurek.network.newRuntime()
  local ws = rt:wsConnect("ws://127.0.0.1:9/lobby")
  rt:wsClose(ws)
end

--@api-stub: NetworkRuntime:poll
-- Collects and returns all pending responses from async HTTP, TCP, and WebSocket operations.
do
  local rt = lurek.network.newRuntime()
  function lurek.process(dt)
    for _, resp in ipairs(rt:poll()) do
      if resp.type == "http" then lurek.log.info("http " .. resp.status, "net") end
    end
  end
end

--@api-stub: NetworkRuntime:shutdown
-- Shuts down the network runtime and cancels all pending async network operations.
do
  local rt = lurek.network.newRuntime()
  function lurek.quit()
    rt:shutdown()
  end
end

--@api-stub: NetworkHost:broadcast
-- Sends a packet to all currently connected peers on a channel with optional reliability.
do
  local host = lurek.network.newServer({port=7777, maxPeers=32})
  host:broadcast(0, "state_update", true)
  lurek.log.info("broadcast sent", "network")
end

--@api-stub: NetworkHost:connect
-- Initiates a connection from this client host to a remote server address string.
do
  local client = lurek.network.newClient({addr="127.0.0.1:7777"})
  local ok, err = pcall(function()
    local peer = client:connect("127.0.0.1:7777")
    lurek.log.info("connect initiated", "network")
  end)
  if not ok then lurek.log.info("connect: no server available", "network") end
end

--@api-stub: NetworkHost:disconnect
-- Sends a graceful disconnect request to a peer and waits for acknowledgement.
do
  local host = lurek.network.newServer({port=7778, maxPeers=8})
  host:disconnect(1)
  lurek.log.info("disconnect requested", "network")
end

--@api-stub: NetworkHost:disconnectLater
-- Queues a graceful disconnect to be sent only after all pending outgoing packets are delivered.
do
  local host = lurek.network.newServer({port=7779, maxPeers=8})
  host:send(1, 0, "game_over", true)
  host:disconnectLater(1)
  lurek.log.info("disconnect-later queued", "network")
end

--@api-stub: NetworkHost:disconnectNow
-- Immediately terminates a peer connection without waiting for any pending packets.
do
  local host = lurek.network.newServer({port=7780, maxPeers=8})
  host:disconnectNow(1)
  lurek.log.info("disconnect-now issued", "network")
end

--@api-stub: NetworkRuntime:httpGet
-- Submits an async HTTP GET request to a URL and returns a request id for polling.
do
  local rt = lurek.network.newRuntime()
  local id = rt:httpGet("http://127.0.0.1:9/get")
  lurek.log.info("GET id=" .. id, "network")
end

--@api-stub: NetworkRuntime:httpPost
-- Submits an async HTTP POST request with a string body and returns a request id.
do
  local rt = lurek.network.newRuntime()
  local id = rt:httpPost("http://127.0.0.1:9/post", '{"key":"val"}')
  lurek.log.info("POST id=" .. id, "network")
end

--@api-stub: NetworkHost:send
-- Sends a packet to a specific peer on a given channel with optional reliable delivery.
do
  local host = lurek.network.newServer({port=7781, maxPeers=8})
  host:send(1, 0, "ping", true)
  lurek.log.info("packet sent to peer 1", "network")
end

--@api-stub: NetworkHost:setBandwidthLimit
-- Sets the incoming and outgoing bandwidth limits for this host in bytes per second.
do
  local host = lurek.network.newServer({port=7782, maxPeers=8})
  host:setBandwidthLimit(128000, 64000)
  lurek.log.info("bandwidth limits set", "network")
end

--@api-stub: LNetworkHost:type
-- Returns the Lua-visible type name for this network host handle
do
  local host = lurek.network.newServer{ port = 5573, maxPeers = 4 }
  lurek.log.info("LNetworkHost:type = " .. host:type(), "net")
  host:destroy()
end
--@api-stub: LNetworkHost:typeOf
-- Returns whether this network host handle matches a supported type name
do
  local host = lurek.network.newServer{ port = 5574, maxPeers = 4 }
  lurek.log.info("is host: " .. tostring(host:typeOf("LNetworkHost")), "net")
  host:destroy()
end

--@api-stub: LNetworkRuntime:type
-- Returns the Lua-visible type name string for this network runtime handle.
do
  local rt = lurek.network.newRuntime()
  lurek.log.info(rt:type(), "net")
  rt:shutdown()
end

--@api-stub: LNetworkRuntime:typeOf
-- Returns true if this network runtime handle matches the given type name string.
do
  local rt = lurek.network.newRuntime()
  lurek.log.info(tostring(rt:typeOf("LNetworkRuntime")), "net")
  rt:shutdown()
end
