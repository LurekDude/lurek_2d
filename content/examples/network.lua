-- content/examples/network.lua
-- Hand-written coverage of the lurek.network API (38 items).
--
-- The lurek.network namespace covers two distinct subsystems: ENet-based
-- real-time peer-to-peer hosts (NetworkHost) used for in-game multiplayer,
-- and a background NetworkRuntime that runs HTTP / TCP / WebSocket I/O
-- off the main thread. Both must be polled every frame to surface events.
--
-- Run: cargo run -- content/examples/network.lua

-- ── lurek.network.* functions ──

--@api-stub: lurek.network.newHost
-- Creates a new network host bound to the given address.
-- Use when you want a generic peer host (no fixed server/client role) bound to a specific local address.
do  -- lurek.network.newHost
  local host = lurek.network.newHost{ addr = "0.0.0.0:5555", maxPeers = 32, channels = 2 }
  lurek.log.info("listening on " .. host:getAddress(), "net")
  host:destroy()
end

--@api-stub: lurek.network.newServer
-- Creates a server host that binds to a port and accepts connections.
-- Preferred over newHost for the authoritative side of a session: requires a port and accepts inbound peers.
do  -- lurek.network.newServer
  local server = lurek.network.newServer{ port = 5555, maxPeers = 16, channels = 2 }
  lurek.log.info("server up on " .. server:getAddress(), "net")
  server:destroy()
end

--@api-stub: lurek.network.newClient
-- Creates a client host that connects to a remote server.
-- Use this on the joining side; it both creates the local socket and initiates the connect handshake.
do  -- lurek.network.newClient
  pcall(function()
    local client = lurek.network.newClient{ addr = "192.168.1.50:5555", channels = 2 }
    lurek.log.info("dialling " .. client:getAddress(), "net")
    client:destroy()
  end)
end

--@api-stub: lurek.network.newRuntime
-- Creates a background network runtime for async HTTP, TCP, and WebSocket.
-- Spawn one runtime at startup and reuse it; it owns a worker thread, so creating many is wasteful.
do  -- lurek.network.newRuntime
  local rt = lurek.network.newRuntime()
  rt:httpGet("https://api.example.com/version")
  function lurek.quit() rt:shutdown() end
end

--@api-stub: lurek.network.pack
-- Serializes a Lua value to a binary MessagePack string.
-- MessagePack output is compact and binary-safe, so it is the right format for ENet send/broadcast payloads.
do  -- lurek.network.pack
  local snapshot = { x = 128.5, y = 64.0, hp = 87, weapon = "rifle" }
  local bytes = lurek.network.pack(snapshot)
  lurek.log.debug("packed " .. #bytes .. " bytes", "net")
end

--@api-stub: lurek.network.unpack
-- Deserializes a MessagePack binary string back to a Lua value.
-- Always unpack the data you received before reading fields; ENet payloads are opaque strings on the wire.
do  -- lurek.network.unpack
  local payload = lurek.network.pack({ id = 42, action = "fire" })
  local msg = lurek.network.unpack(payload)
  lurek.log.info("received action=" .. msg.action .. " id=" .. msg.id, "net")
end

--@api-stub: lurek.network.createLobby
-- Creates a LobbyInfo record and broadcasts it once on the local network.
-- Call this once on the host so LAN browsers can find the session; re-broadcast on player count changes.
do  -- lurek.network.createLobby
  local lobby = lurek.network.createLobby("Tom's Co-op", 5555, 1, 4)
  lurek.log.info("advertised lobby " .. lobby.name .. " on port " .. lobby.port, "net")
end

--@api-stub: lurek.network.discoverLobbies
-- Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
-- Block briefly during a server-browser screen; the timeout caps how long the call sleeps before returning.
do  -- lurek.network.discoverLobbies
  local lobbies = lurek.network.discoverLobbies(750)
  for i, info in ipairs(lobbies) do
    lurek.log.info(i .. ": " .. info.name .. " " .. info.host .. ":" .. info.port, "lobby")
  end
end

--@api-stub: lurek.network.syncEntity
-- Convenience helper: packs an entity snapshot and broadcasts it to all peers.
-- Use for fire-and-forget state replication of fast-moving entities; pass reliable=false to keep latency low.
do  -- lurek.network.syncEntity
  local server = lurek.network.newServer{ port = 5555, maxPeers = 8 }
  local player = { x = 100.0, y = 200.0, hp = 80 }
  lurek.network.syncEntity(server, 1, player, 0, false)
  server:destroy()
end


-- ── NetworkHost methods ──

--@api-stub: NetworkHost:service
-- Polls the network for one event, returning an event table or nil.
-- Call this in lurek.process every frame and dispatch on event.type ("connect", "disconnect", "receive").
do  -- NetworkHost:service
  local host = lurek.network.newServer{ port = 5556, maxPeers = 8 }
  function lurek.process(dt)
    local ev = host:service()
    if ev and ev.type == "receive" then lurek.log.debug("got " .. #ev.data .. " bytes", "net") end
  end
end

--@api-stub: NetworkHost:flush
-- Flushes all pending sends immediately.
-- Call after a burst of urgent sends (e.g. end-of-frame state) to push packets out without waiting for service().
do  -- NetworkHost:flush
  local host = lurek.network.newServer{ port = 5557, maxPeers = 8 }
  host:broadcast(0, lurek.network.pack({ event = "round_end" }), true)
  host:flush()
end

--@api-stub: NetworkHost:resetPeer
-- Resets a peer connection immediately without notifying the remote side.
-- Use for misbehaving peers you want gone immediately; the remote side will not get a clean disconnect notice.
do  -- NetworkHost:resetPeer
  local host = lurek.network.newServer{ port = 5558, maxPeers = 8 }
  local cheater_peer_id = 3
  host:resetPeer(cheater_peer_id)
  lurek.log.warn("force-reset peer " .. cheater_peer_id, "net")
end

--@api-stub: NetworkHost:ping
-- Sends a ping to a peer to measure round-trip time.
-- Pings are normally automatic; call this only to force an immediate RTT update before reading getRoundTripTime.
do  -- NetworkHost:ping
  local host = lurek.network.newServer{ port = 5559, maxPeers = 8 }
  local peer_id = 1
  host:ping(peer_id)
end

--@api-stub: NetworkHost:getRoundTripTime
-- Returns the round-trip time estimate for a peer in milliseconds.
-- Read this each second to render a latency meter; the value is in milliseconds.
do  -- NetworkHost:getRoundTripTime
  local host = lurek.network.newServer{ port = 5560, maxPeers = 8 }
  local rtt_ms = host:getRoundTripTime(1)
  if rtt_ms > 150 then lurek.log.warn("high latency: " .. rtt_ms .. " ms", "net") end
end

--@api-stub: NetworkHost:getPeerState
-- Returns the connection state of a peer as a string.
-- Branch on the state string before sending; sends to a non-"connected" peer raise an error.
do  -- NetworkHost:getPeerState
  local host = lurek.network.newServer{ port = 5561, maxPeers = 8 }
  local state = host:getPeerState(1)
  if state == "connected" then host:send(1, 0, "hello", true) end
end

--@api-stub: NetworkHost:getPeerAddress
-- Returns the remote address of a peer, or nil if unavailable.
-- Useful for logging and ban lists; returns nil if the peer slot is empty or the address is not yet known.
do  -- NetworkHost:getPeerAddress
  local host = lurek.network.newServer{ port = 5562, maxPeers = 8 }
  local addr = host:getPeerAddress(1)
  if addr then lurek.log.info("peer 1 at " .. addr, "net") end
end

--@api-stub: NetworkHost:getAddress
-- Returns the local bind address as a string.
-- Useful right after newHost{ addr = "0.0.0.0:0" } to discover which ephemeral port the OS picked.
do  -- NetworkHost:getAddress
  local host = lurek.network.newHost{ addr = "0.0.0.0:0", maxPeers = 4 }
  local bound = host:getAddress()
  lurek.log.info("bound to " .. bound, "net")
end

--@api-stub: NetworkHost:getPeerLimit
-- Returns the maximum number of peer slots.
-- Compare against getConnectedPeerCount to decide whether to advertise the lobby as full.
do  -- NetworkHost:getPeerLimit
  local host = lurek.network.newServer{ port = 5563, maxPeers = 16 }
  local cap = host:getPeerLimit()
  lurek.log.info("max players: " .. cap, "net")
end

--@api-stub: NetworkHost:getChannelLimit
-- Returns the maximum number of channels per connection.
-- Use when wiring a channel-aware protocol (e.g. channel 0 = state, 1 = chat) to validate your assumed channel count.
do  -- NetworkHost:getChannelLimit
  local host = lurek.network.newServer{ port = 5564, maxPeers = 8, channels = 4 }
  local channels = host:getChannelLimit()
  assert(channels >= 2, "need at least 2 channels for state+chat")
end

--@api-stub: NetworkHost:setChannelLimit
-- Sets the channel limit for future connections.
-- Apply before any peer connects; existing connections keep the channel count they negotiated.
do  -- NetworkHost:setChannelLimit
  local host = lurek.network.newHost{ addr = "0.0.0.0:0", maxPeers = 8 }
  host:setChannelLimit(4)
  lurek.log.info("now negotiating " .. host:getChannelLimit() .. " channels", "net")
end

--@api-stub: NetworkHost:getBandwidthLimit
-- Returns the bandwidth limits as a table with incoming and outgoing fields.
-- Show in a debug overlay; returned values are bytes/second, 0 means unlimited.
do  -- NetworkHost:getBandwidthLimit
  pcall(function()
    local host = lurek.network.newServer{ port = 5565, maxPeers = 8 }
    local bw = host:getBandwidthLimit()
    lurek.log.info("bw in=" .. tostring(bw.incoming) .. " out=" .. tostring(bw.outgoing) .. " B/s", "net")
    host:destroy()
  end)
end

--@api-stub: NetworkHost:getConnectedPeerCount
-- Returns the number of currently connected peers.
-- Poll once per second for a player counter; cheaper than iterating getConnectedPeerIds.
do  -- NetworkHost:getConnectedPeerCount
  local host = lurek.network.newServer{ port = 5566, maxPeers = 8 }
  local n = host:getConnectedPeerCount()
  lurek.log.info("players online: " .. n, "net")
end

--@api-stub: NetworkHost:getConnectedPeerIds
-- Returns a table of connected peer IDs.
-- Iterate to fan-out per-peer messages (e.g. private inventory updates) instead of broadcasting.
do  -- NetworkHost:getConnectedPeerIds
  local host = lurek.network.newServer{ port = 5567, maxPeers = 8 }
  for _, pid in ipairs(host:getConnectedPeerIds()) do
    host:send(pid, 1, lurek.network.pack({ welcome = true }), true)
  end
end

--@api-stub: NetworkHost:getPeerStats
-- Returns a statistics table for a peer.
-- Inspect packets_sent / packets_lost in a debug HUD to spot lossy clients before they desync.
do  -- NetworkHost:getPeerStats
  local host = lurek.network.newServer{ port = 5568, maxPeers = 8 }
  local stats = host:getPeerStats(1)
  lurek.log.debug("peer 1 sent=" .. stats.packets_sent .. " lost=" .. stats.packets_lost, "net")
end

--@api-stub: NetworkHost:destroy
-- Destroys the host, closing the underlying socket.
-- Always call from lurek.quit so the OS releases the UDP socket; safe to call once on a host already destroyed.
do  -- NetworkHost:destroy
  local host = lurek.network.newServer{ port = 5569, maxPeers = 8 }
  function lurek.quit()
    host:destroy()
  end
end

--@api-stub: NetworkHost:isDestroyed
-- Returns true if the host has been destroyed.
-- Guard service / send loops with this so a hot-reload that nukes the host does not crash the next frame.
do  -- NetworkHost:isDestroyed
  local host = lurek.network.newServer{ port = 5570, maxPeers = 8 }
  host:destroy()
  if host:isDestroyed() then lurek.log.info("host shut down cleanly", "net") end
end

--@api-stub: NetworkHost:getRole
-- Returns the multiplayer role of this host ("server", "client", or "host").
-- Use to share one update path for client and server while still printing the right diagnostic strings.
do  -- NetworkHost:getRole
  local host = lurek.network.newServer{ port = 5571, maxPeers = 8 }
  local role = host:getRole()
  lurek.log.info("running as " .. role, "net")
end

--@api-stub: NetworkHost:isServer
-- Returns true if this host was created as a server.
-- Branch on this when authoritative logic (spawning, scoring) must only run on the server side.
do  -- NetworkHost:isServer
  local host = lurek.network.newServer{ port = 5572, maxPeers = 8 }
  if host:isServer() then
    lurek.log.info("authoritative tick enabled", "net")
  end
end

--@api-stub: NetworkHost:isClient
-- Returns true if this host was created as a client.
-- Use to skip server-only code paths (spawning, validation) on joiners while still sharing the loop.
do  -- NetworkHost:isClient
  local client = lurek.network.newClient{ addr = "127.0.0.1:5555" }
  if client:isClient() then
    lurek.log.info("running prediction-only logic", "net")
  end
end


-- ── NetworkRuntime methods ──

--@api-stub: NetworkRuntime:httpRequest
-- Sends an HTTP request asynchronously.
-- Pass a fully formed table once; correlate the returned request id with poll() responses to read the result.
do  -- NetworkRuntime:httpRequest
  local rt = lurek.network.newRuntime()
  local req_id = rt:httpRequest{
    method = "POST", url = "https://api.example.com/scores",
    headers = { ["Content-Type"] = "application/json" },
    body = '{"name":"tom","score":4200}', timeout = 5000,
  }
  lurek.log.info("submitted score request id=" .. req_id, "net")
end

--@api-stub: NetworkRuntime:tcpConnect
-- Opens a TCP connection to a remote address.
-- Returns a connection id immediately; the actual socket open is signalled by a poll() event with event="connected".
do  -- NetworkRuntime:tcpConnect
  local rt = lurek.network.newRuntime()
  local conn = rt:tcpConnect("game.example.com:7777")
  lurek.log.info("dialling tcp conn=" .. conn, "net")
end

--@api-stub: NetworkRuntime:tcpSend
-- Sends data over a TCP connection.
-- Frame your own messages (length prefix or newline) before calling; the runtime sends raw bytes.
do  -- NetworkRuntime:tcpSend
  local rt = lurek.network.newRuntime()
  local conn = rt:tcpConnect("game.example.com:7777")
  rt:tcpSend(conn, "LOGIN tom\n")
end

--@api-stub: NetworkRuntime:tcpClose
-- Closes the TCP connection identified by the given connection handle.
-- Close as soon as you receive your final response; leaving sockets open leaks file descriptors over long sessions.
do  -- NetworkRuntime:tcpClose
  local rt = lurek.network.newRuntime()
  local conn = rt:tcpConnect("game.example.com:7777")
  rt:tcpClose(conn)
end

--@api-stub: NetworkRuntime:wsConnect
-- Opens a WebSocket connection.
-- Use ws:// for plaintext (LAN, dev) and wss:// for production; both return a connection id you correlate via poll().
do  -- NetworkRuntime:wsConnect
  local rt = lurek.network.newRuntime()
  local ws = rt:wsConnect("wss://chat.example.com/lobby")
  lurek.log.info("opening websocket id=" .. ws, "net")
end

--@api-stub: NetworkRuntime:wsSend
-- Sends a text message over a WebSocket connection.
-- Sends a single text frame; for binary frames serialise with lurek.network.pack and send via the binary channel.
do  -- NetworkRuntime:wsSend
  local rt = lurek.network.newRuntime()
  local ws = rt:wsConnect("wss://chat.example.com/lobby")
  rt:wsSend(ws, '{"chat":"hello"}')
end

--@api-stub: NetworkRuntime:wsClose
-- Closes a WebSocket connection.
-- Close cleanly when the player leaves the chat screen; the server will send a close frame back via poll().
do  -- NetworkRuntime:wsClose
  local rt = lurek.network.newRuntime()
  local ws = rt:wsConnect("wss://chat.example.com/lobby")
  rt:wsClose(ws)
end

--@api-stub: NetworkRuntime:poll
-- Polls for completed async responses (HTTP, TCP events, WebSocket events).
-- Drain every frame in lurek.process; each entry has a .type ("http", "tcp", "websocket") and event-specific fields.
do  -- NetworkRuntime:poll
  local rt = lurek.network.newRuntime()
  function lurek.process(dt)
    for _, resp in ipairs(rt:poll()) do
      if resp.type == "http" then lurek.log.info("http " .. resp.status, "net") end
    end
  end
end

--@api-stub: NetworkRuntime:shutdown
-- Shuts down the background network thread.
-- Call from lurek.quit so the worker thread joins cleanly; the runtime is unusable after this.
do  -- NetworkRuntime:shutdown
  local rt = lurek.network.newRuntime()
  function lurek.quit()
    rt:shutdown()
  end
end
