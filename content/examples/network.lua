-- content/examples/network.lua
-- Hand-written coverage of the lurek.network API (38 items).
--
-- The lurek.network namespace covers two distinct subsystems: ENet-based
-- real-time peer-to-peer hosts (NetworkHost) used for in-game multiplayer,
-- and a background NetworkRuntime that runs HTTP / TCP / WebSocket I/O
-- off the main thread. Both must be polled every frame to surface events.
--
-- Run: cargo run -- content/examples/network.lua
---@diagnostic disable: cast-local-type
-- pcall() is used throughout to construct host objects; the nil-guard pattern
-- (ok, handle = pcall(...); if not ok then handle = nil end) is intentional.

-- â”€â”€ lurek.network.* functions â”€â”€

--@api-stub: lurek.network.newHost
-- Creates a new network host bound to the given address.
-- Use when you want a generic peer host (no fixed server/client role) bound to a specific local address.
-- if false then -- lurek.network.newHost
--   local host = lurek.network.newHost{ addr = "0.0.0.0:5555", maxPeers = 32, channels = 2 }
--   lurek.log.info("listening on " .. host:getAddress(), "net")
--   host:destroy()
-- end

--@api-stub: lurek.network.newServer
-- Creates a server host that binds to a port and accepts connections.
-- Preferred over newHost for the authoritative side of a session: requires a port and accepts inbound peers.
-- if false then -- lurek.network.newServer
--   local server = lurek.network.newServer{ port = 5555, maxPeers = 16, channels = 2 }
--   lurek.log.info("server up on " .. server:getAddress(), "net")
--   server:destroy()
-- end

--@api-stub: lurek.network.newClient
-- Creates a client host that connects to a remote server.
-- Use this on the joining side; it both creates the local socket and initiates the connect handshake.
-- if false then -- lurek.network.newClient
--   pcall(function()
--     local client = lurek.network.newClient{ addr = "192.168.1.50:5555", channels = 2 }
--     lurek.log.info("dialling " .. client:getAddress(), "net")
--     client:destroy()
--   end)
-- end

--@api-stub: lurek.network.newRuntime
-- Creates a background network runtime for async HTTP, TCP, and WebSocket.
-- Spawn one runtime at startup and reuse it; it owns a worker thread, so creating many is wasteful.
-- if false then -- lurek.network.newRuntime
--   local rt = lurek.network.newRuntime()
--   rt:httpGet("https://api.example.com/version")
--   function lurek.quit() rt:shutdown() end
-- end

--@api-stub: lurek.network.pack
-- Serializes a Lua value to a binary MessagePack string.
-- MessagePack output is compact and binary-safe, so it is the right format for ENet send/broadcast payloads.
-- if false then -- lurek.network.pack
--   local snapshot = { x = 128.5, y = 64.0, hp = 87, weapon = "rifle" }
--   local bytes = lurek.network.pack(snapshot)
--   lurek.log.debug("packed " .. #bytes .. " bytes", "net")
-- end

--@api-stub: lurek.network.unpack
-- Deserializes a MessagePack binary string back to a Lua value.
-- Always unpack the data you received before reading fields; ENet payloads are opaque strings on the wire.
-- if false then -- lurek.network.unpack
--   local payload = lurek.network.pack({ id = 42, action = "fire" })
--   local msg = lurek.network.unpack(payload)
--   lurek.log.info("received action=" .. msg.action .. " id=" .. msg.id, "net")
-- end

--@api-stub: lurek.network.createLobby
-- Creates a LobbyInfo record and broadcasts it once on the local network.
-- Call this once on the host so LAN browsers can find the session; re-broadcast on player count changes.
-- if false then -- lurek.network.createLobby
--   local lobby = lurek.network.createLobby("Tom's Co-op", 5555, 1, 4)
--   lurek.log.info("advertised lobby " .. lobby.name .. " on port " .. lobby.port, "net")
-- end

--@api-stub: lurek.network.discoverLobbies
-- Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
-- Block briefly during a server-browser screen; the timeout caps how long the call sleeps before returning.
-- if false then -- lurek.network.discoverLobbies
--   local lobbies = lurek.network.discoverLobbies(750)
--   for i, info in ipairs(lobbies) do
--     lurek.log.info(i .. ": " .. info.name .. " " .. info.host .. ":" .. info.port, "lobby")
--   end
-- end

--@api-stub: lurek.network.syncEntity
-- Convenience helper: packs an entity snapshot and broadcasts it to all peers.
-- Use for fire-and-forget state replication of fast-moving entities; pass reliable=false to keep latency low.
-- if false then -- lurek.network.syncEntity
--   local server = lurek.network.newServer{ port = 5555, maxPeers = 8 }
--   local player = { x = 100.0, y = 200.0, hp = 80 }
--   lurek.network.syncEntity(server, 1, player, 0, false)
--   server:destroy()
-- end


-- â”€â”€ NetworkHost methods â”€â”€

--@api-stub: LNetworkHost:service
-- Polls the network for one event, returning an event table or nil.
-- Call this in lurek.process every frame and dispatch on event.type ("connect", "disconnect", "receive").
-- if false then -- NetworkHost:service
--   local host = lurek.network.newServer{ port = 5556, maxPeers = 8 }
--   function lurek.process(dt)
--     local ev = host:service()
--     if ev and ev.type == "receive" then lurek.log.debug("got " .. #ev.data .. " bytes", "net") end
--   end
-- end

--@api-stub: LNetworkHost:flush
-- Flushes all pending sends immediately.
-- Call after a burst of urgent sends (e.g. end-of-frame state) to push packets out without waiting for service().
-- if false then -- NetworkHost:flush
--   local host = lurek.network.newServer{ port = 5557, maxPeers = 8 }
--   host:broadcast(0, lurek.network.pack({ event = "round_end" }), true)
--   host:flush()
-- end

--@api-stub: LNetworkHost:resetPeer
-- Resets a peer connection immediately without notifying the remote side.
-- Use for misbehaving peers you want gone immediately; the remote side will not get a clean disconnect notice.
-- if false then -- NetworkHost:resetPeer
--   local host = lurek.network.newServer{ port = 5558, maxPeers = 8 }
--   local cheater_peer_id = 3
--   host:resetPeer(cheater_peer_id)
--   lurek.log.warn("force-reset peer " .. cheater_peer_id, "net")
-- end

--@api-stub: LNetworkHost:ping
-- Sends a ping to a peer to measure round-trip time.
-- Pings are normally automatic; call this only to force an immediate RTT update before reading getRoundTripTime.
-- if false then -- NetworkHost:ping
--   local host = lurek.network.newServer{ port = 5559, maxPeers = 8 }
--   local peer_id = 1
--   host:ping(peer_id)
-- end

--@api-stub: LNetworkHost:getRoundTripTime
-- Returns the round-trip time estimate for a peer in milliseconds.
-- Read this each second to render a latency meter; the value is in milliseconds.
-- if false then -- NetworkHost:getRoundTripTime
--   local host = lurek.network.newServer{ port = 5560, maxPeers = 8 }
--   local rtt_ms = host:getRoundTripTime(1)
--   if rtt_ms > 150 then lurek.log.warn("high latency: " .. rtt_ms .. " ms", "net") end
-- end

--@api-stub: LNetworkHost:getPeerState
-- Returns the connection state of a peer as a string.
-- Branch on the state string before sending; sends to a non-"connected" peer raise an error.
-- if false then -- NetworkHost:getPeerState
--   local host = lurek.network.newServer{ port = 5561, maxPeers = 8 }
--   local state = host:getPeerState(1)
--   if state == "connected" then host:send(1, 0, "hello", true) end
-- end

--@api-stub: LNetworkHost:getPeerAddress
-- Returns the remote address of a peer, or nil if unavailable.
-- Useful for logging and ban lists; returns nil if the peer slot is empty or the address is not yet known.
-- if false then -- NetworkHost:getPeerAddress
--   local host = lurek.network.newServer{ port = 5562, maxPeers = 8 }
--   local addr = host:getPeerAddress(1)
--   if addr then lurek.log.info("peer 1 at " .. addr, "net") end
-- end

--@api-stub: LNetworkHost:getAddress
-- Returns the local bind address as a string.
-- Useful right after newHost{ addr = "0.0.0.0:0" } to discover which ephemeral port the OS picked.
-- if false then -- NetworkHost:getAddress
--   local host = lurek.network.newHost{ addr = "0.0.0.0:0", maxPeers = 4 }
--   local bound = host:getAddress()
--   lurek.log.info("bound to " .. bound, "net")
-- end

--@api-stub: LNetworkHost:getPeerLimit
-- Returns the maximum number of peer slots.
-- Compare against getConnectedPeerCount to decide whether to advertise the lobby as full.
-- if false then -- NetworkHost:getPeerLimit
--   local host = lurek.network.newServer{ port = 5563, maxPeers = 16 }
--   local cap = host:getPeerLimit()
--   lurek.log.info("max players: " .. cap, "net")
-- end

--@api-stub: LNetworkHost:getChannelLimit
-- Returns the maximum number of channels per connection.
-- Use when wiring a channel-aware protocol (e.g. channel 0 = state, 1 = chat) to validate your assumed channel count.
-- if false then -- NetworkHost:getChannelLimit
--   local host = lurek.network.newServer{ port = 5564, maxPeers = 8, channels = 4 }
--   local channels = host:getChannelLimit()
--   assert(channels >= 2, "need at least 2 channels for state+chat")
-- end

--@api-stub: LNetworkHost:setChannelLimit
-- Sets the channel limit for future connections.
-- Apply before any peer connects; existing connections keep the channel count they negotiated.
-- if false then -- NetworkHost:setChannelLimit
--   local host = lurek.network.newHost{ addr = "0.0.0.0:0", maxPeers = 8 }
--   host:setChannelLimit(4)
--   lurek.log.info("now negotiating " .. host:getChannelLimit() .. " channels", "net")
-- end

--@api-stub: LNetworkHost:getBandwidthLimit
-- Returns the bandwidth limits as a table with incoming and outgoing fields.
-- Show in a debug overlay; returned values are bytes/second, 0 means unlimited.
-- if false then -- NetworkHost:getBandwidthLimit
--   pcall(function()
--     local host = lurek.network.newServer{ port = 5565, maxPeers = 8 }
--     local bw = host:getBandwidthLimit()
--     lurek.log.info("bw in=" .. tostring(bw.incoming) .. " out=" .. tostring(bw.outgoing) .. " B/s", "net")
--     host:destroy()
--   end)
-- end

--@api-stub: LNetworkHost:getConnectedPeerCount
-- Returns the number of currently connected peers.
-- Poll once per second for a player counter; cheaper than iterating getConnectedPeerIds.
-- if false then -- NetworkHost:getConnectedPeerCount
--   local host = lurek.network.newServer{ port = 5566, maxPeers = 8 }
--   local n = host:getConnectedPeerCount()
--   lurek.log.info("players online: " .. n, "net")
-- end

--@api-stub: LNetworkHost:getConnectedPeerIds
-- Returns a table of connected peer IDs.
-- Iterate to fan-out per-peer messages (e.g. private inventory updates) instead of broadcasting.
-- if false then -- NetworkHost:getConnectedPeerIds
--   local host = lurek.network.newServer{ port = 5567, maxPeers = 8 }
--   for _, pid in ipairs(host:getConnectedPeerIds()) do
--     host:send(pid, 1, lurek.network.pack({ welcome = true }), true)
--   end
-- end

--@api-stub: LNetworkHost:getPeerStats
-- Returns a statistics table for a peer.
-- Inspect packets_sent / packets_lost in a debug HUD to spot lossy clients before they desync.
-- if false then -- NetworkHost:getPeerStats
--   local host = lurek.network.newServer{ port = 5568, maxPeers = 8 }
--   local stats = host:getPeerStats(1)
--   lurek.log.debug("peer 1 sent=" .. stats.packets_sent .. " lost=" .. stats.packets_lost, "net")
-- end

--@api-stub: LNetworkHost:destroy
-- Destroys the host, closing the underlying socket.
-- Always call from lurek.quit so the OS releases the UDP socket; safe to call once on a host already destroyed.
-- if false then -- NetworkHost:destroy
--   local host = lurek.network.newServer{ port = 5569, maxPeers = 8 }
--   function lurek.quit()
--     host:destroy()
--   end
-- end

--@api-stub: LNetworkHost:isDestroyed
-- Returns true if the host has been destroyed.
-- Guard service / send loops with this so a hot-reload that nukes the host does not crash the next frame.
-- if false then -- NetworkHost:isDestroyed
--   local host = lurek.network.newServer{ port = 5570, maxPeers = 8 }
--   host:destroy()
--   if host:isDestroyed() then lurek.log.info("host shut down cleanly", "net") end
-- end

--@api-stub: LNetworkHost:getRole
-- Returns the multiplayer role of this host ("server", "client", or "host").
-- Use to share one update path for client and server while still printing the right diagnostic strings.
-- if false then -- NetworkHost:getRole
--   local host = lurek.network.newServer{ port = 5571, maxPeers = 8 }
--   local role = host:getRole()
--   lurek.log.info("running as " .. role, "net")
-- end

--@api-stub: LNetworkHost:isServer
-- Returns true if this host was created as a server.
-- Branch on this when authoritative logic (spawning, scoring) must only run on the server side.
-- if false then -- NetworkHost:isServer
--   local host = lurek.network.newServer{ port = 5572, maxPeers = 8 }
--   if host:isServer() then
--     lurek.log.info("authoritative tick enabled", "net")
--   end
-- end

--@api-stub: LNetworkHost:isClient
-- Returns true if this host was created as a client.
-- Use to skip server-only code paths (spawning, validation) on joiners while still sharing the loop.
-- if false then -- NetworkHost:isClient
--   local client = lurek.network.newClient{ addr = "127.0.0.1:5555" }
--   if client:isClient() then
--     lurek.log.info("running prediction-only logic", "net")
--   end
-- end


-- â”€â”€ NetworkRuntime methods â”€â”€

--@api-stub: LNetworkRuntime:httpRequest
-- Sends an HTTP request asynchronously.
-- Pass a fully formed table once; correlate the returned request id with poll() responses to read the result.
-- if false then -- NetworkRuntime:httpRequest
--   local rt = lurek.network.newRuntime()
--   local req_id = rt:httpRequest{
--     method = "POST", url = "https://api.example.com/scores",
--     headers = { ["Content-Type"] = "application/json" },
--     body = '{"name":"tom","score":4200}', timeout = 5000,
--   }
--   lurek.log.info("submitted score request id=" .. req_id, "net")
-- end

--@api-stub: LNetworkRuntime:tcpConnect
-- Opens a TCP connection to a remote address.
-- Returns a connection id immediately; the actual socket open is signalled by a poll() event with event="connected".
-- if false then -- NetworkRuntime:tcpConnect
--   local rt = lurek.network.newRuntime()
--   local conn = rt:tcpConnect("game.example.com:7777")
--   lurek.log.info("dialling tcp conn=" .. conn, "net")
-- end

--@api-stub: LNetworkRuntime:tcpSend
-- Sends data over a TCP connection.
-- Frame your own messages (length prefix or newline) before calling; the runtime sends raw bytes.
-- if false then -- NetworkRuntime:tcpSend
--   local rt = lurek.network.newRuntime()
--   local conn = rt:tcpConnect("game.example.com:7777")
--   rt:tcpSend(conn, "LOGIN tom\n")
-- end

--@api-stub: LNetworkRuntime:tcpClose
-- Closes the TCP connection identified by the given connection handle.
-- Close as soon as you receive your final response; leaving sockets open leaks file descriptors over long sessions.
-- if false then -- NetworkRuntime:tcpClose
--   local rt = lurek.network.newRuntime()
--   local conn = rt:tcpConnect("game.example.com:7777")
--   rt:tcpClose(conn)
-- end

--@api-stub: LNetworkRuntime:wsConnect
-- Opens a WebSocket connection.
-- Use ws:// for plaintext (LAN, dev) and wss:// for production; both return a connection id you correlate via poll().
-- if false then -- NetworkRuntime:wsConnect
--   local rt = lurek.network.newRuntime()
--   local ws = rt:wsConnect("wss://chat.example.com/lobby")
--   lurek.log.info("opening websocket id=" .. ws, "net")
-- end

--@api-stub: LNetworkRuntime:wsSend
-- Sends a text message over a WebSocket connection.
-- Sends a single text frame; for binary frames serialise with lurek.network.pack and send via the binary channel.
-- if false then -- NetworkRuntime:wsSend
--   local rt = lurek.network.newRuntime()
--   local ws = rt:wsConnect("wss://chat.example.com/lobby")
--   rt:wsSend(ws, '{"chat":"hello"}')
-- end

--@api-stub: LNetworkRuntime:wsClose
-- Closes a WebSocket connection.
-- Close cleanly when the player leaves the chat screen; the server will send a close frame back via poll().
-- if false then -- NetworkRuntime:wsClose
--   local rt = lurek.network.newRuntime()
--   local ws = rt:wsConnect("wss://chat.example.com/lobby")
--   rt:wsClose(ws)
-- end

--@api-stub: LNetworkRuntime:poll
-- Polls for completed async responses (HTTP, TCP events, WebSocket events).
-- Drain every frame in lurek.process; each entry has a .type ("http", "tcp", "websocket") and event-specific fields.
-- if false then -- NetworkRuntime:poll
--   local rt = lurek.network.newRuntime()
--   function lurek.process(dt)
--     for _, resp in ipairs(rt:poll()) do
--       if resp.type == "http" then lurek.log.info("http " .. resp.status, "net") end
--     end
--   end
-- end

--@api-stub: LNetworkRuntime:shutdown
-- Shuts down the background network thread.
-- Call from lurek.quit so the worker thread joins cleanly; the runtime is unusable after this.
-- if false then -- NetworkRuntime:shutdown
--   local rt = lurek.network.newRuntime()
--   function lurek.quit()
--     rt:shutdown()
--   end
-- end

--@api-stub: LNetworkHost:broadcast
-- Sends a message to all connected peers on the specified channel.
-- Efficient for authoritative-state updates; peers filter by channel number.
-- if false then -- NetworkHost:broadcast
--   local host = lurek.network.newServer({port=7777, maxPeers=32})
--   host:broadcast(0, "state_update", true)
--   lurek.log.info("broadcast sent", "network")
-- end

--@api-stub: LNetworkHost:connect
-- Attempts to connect this client host to a remote server address and port.
-- Returns a peer handle; the connection is established asynchronously via service().
-- if false then -- NetworkHost:connect
--   local client = lurek.network.newClient({addr="127.0.0.1:7777"})
--   local ok, err = pcall(function()
--     local peer = client:connect("127.0.0.1:7777")
--     lurek.log.info("connect initiated", "network")
--   end)
--   if not ok then lurek.log.info("connect: no server available", "network") end
-- end

--@api-stub: LNetworkHost:disconnect
-- Sends a disconnect notification and flushes all queued data before closing.
-- Graceful disconnect; peer receives ENet disconnect event after data drains.
-- if false then -- NetworkHost:disconnect
--   local host = lurek.network.newServer({port=7778, maxPeers=8})
--   host:disconnect(1)
--   lurek.log.info("disconnect requested", "network")
-- end

--@api-stub: LNetworkHost:disconnectLater
-- Queues a disconnect that fires only after all outgoing packets are delivered.
-- Use when you need the remote to receive a final message before the channel closes.
-- if false then -- NetworkHost:disconnectLater
--   local host = lurek.network.newServer({port=7779, maxPeers=8})
--   host:send(1, 0, "game_over", true)
--   host:disconnectLater(1)
--   lurek.log.info("disconnect-later queued", "network")
-- end

--@api-stub: LNetworkHost:disconnectNow
-- Closes the connection immediately without waiting for queued packets.
-- Use for timeout handling or when the connection is already known to be dead.
-- if false then -- NetworkHost:disconnectNow
--   local host = lurek.network.newServer({port=7780, maxPeers=8})
--   host:disconnectNow(1)
--   lurek.log.info("disconnect-now issued", "network")
-- end

--@api-stub: LNetworkRuntime:httpGet
-- Issues an asynchronous HTTP GET request to the given URL.
-- poll() returns the response; subscribe to its result in the next frame.
-- if false then -- NetworkRuntime:httpGet
--   local rt = lurek.network.newRuntime()
--   local id = rt:httpGet("https://httpbin.org/get")
--   lurek.log.info("GET id=" .. id, "network")
-- end

--@api-stub: LNetworkRuntime:httpPost
-- Issues an asynchronous HTTP POST request with a JSON or form body.
-- Pass headers table and body string; response arrives via the callback.
-- if false then -- NetworkRuntime:httpPost
--   local rt = lurek.network.newRuntime()
--   local id = rt:httpPost("https://httpbin.org/post", '{"key":"val"}')
--   lurek.log.info("POST id=" .. id, "network")
-- end

--@api-stub: LNetworkHost:send
-- Sends a packet to a single peer on the given channel.
-- channel is a 0-based integer; mode is "reliable", "unsequenced", or "unreliable".
-- if false then -- NetworkHost:send
--   local host = lurek.network.newServer({port=7781, maxPeers=8})
--   host:send(1, 0, "ping", true)
--   lurek.log.info("packet sent to peer 1", "network")
-- end

--@api-stub: LNetworkHost:setBandwidthLimit
-- Sets incoming and outgoing bandwidth caps (bytes/sec) on the host.
-- 0 = unlimited; use to simulate poor network conditions during testing.
-- if false then -- NetworkHost:setBandwidthLimit
--   local host = lurek.network.newServer({port=7782, maxPeers=8})
--   host:setBandwidthLimit(128000, 64000)
--   lurek.log.info("bandwidth limits set", "network")
-- end

-- =============================================================================
-- STUBS: 2 uncovered lurek.network API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.network.newHost -----------------------------------------
--@api-stub: lurek.network.newHost
-- Creates a new network host bound to the given address.
-- if false then -- lurek.network.newHost
--   local ok, host = pcall(lurek.network.newHost, { address = "127.0.0.1", port = 0 })
--   lurek.log.info("newHost ok=" .. tostring(ok), "network")
-- end

-- -----------------------------------------------------------------------------
-- NetworkRuntime methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- STUBS: 6 uncovered lurek.network API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.network.newHost -----------------------------------------
--@api-stub: LNetworkHost:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LNetworkHost:type
--   local ok, network_host_obj = pcall(lurek.network.newHost, 7777)
--   if not ok then network_host_obj = nil end
--   local t = network_host_obj and network_host_obj:type() or "LNetworkHost"
--   lurek.log.info("LNetworkHost:type = " .. t, "network")
-- end
--@api-stub: LNetworkHost:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LNetworkHost:typeOf
--   local ok2, network_host_obj2 = pcall(lurek.network.newHost, 7778)
--   if not ok2 then network_host_obj2 = nil end
--   lurek.log.info("is LNetworkHost: " .. tostring(network_host_obj2 and network_host_obj2:typeOf("LNetworkHost") or false), "network")
--   lurek.log.info("is wrong: " .. tostring(network_host_obj2 and network_host_obj2:typeOf("Unknown") or false), "network")
-- end
--@api-stub: LNetworkRuntime:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LNetworkRuntime:type
--   local network_runtime_obj = lurek.network.newRuntime()
--   local t = network_runtime_obj:type()
--   lurek.log.info("LNetworkRuntime:type = " .. t, "network")
-- end
--@api-stub: LNetworkRuntime:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LNetworkRuntime:typeOf
--   local network_runtime_obj = lurek.network.newRuntime()
--   lurek.log.info("is LNetworkRuntime: " .. tostring(network_runtime_obj:typeOf("LNetworkRuntime")), "network")
--   lurek.log.info("is wrong: " .. tostring(network_runtime_obj:typeOf("Unknown")), "network")
-- end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


