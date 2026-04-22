-- content/examples/network.lua
-- Practical usage examples for the lurek.network API (38 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.network.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/network.lua

print("[example] lurek.network — 38 API entries")

-- ── lurek.network.* free functions ──

--@api-stub: lurek.network.newHost
-- Creates a new network host bound to the given address.
-- Call when you need to create a new host.
local ok, obj = pcall(function() return lurek.network.newHost({}) end)
if ok and obj then print("created:", obj) end
print("lurek.network.newHost ok=", ok)

--@api-stub: lurek.network.newServer
-- Creates a server host that binds to a port and accepts connections.
-- Call when you need to create a new server.
local ok, obj = pcall(function() return lurek.network.newServer({}) end)
if ok and obj then print("created:", obj) end
print("lurek.network.newServer ok=", ok)

--@api-stub: lurek.network.newClient
-- Creates a client host that connects to a remote server.
-- Call when you need to create a new client.
local ok, obj = pcall(function() return lurek.network.newClient({}) end)
if ok and obj then print("created:", obj) end
print("lurek.network.newClient ok=", ok)

--@api-stub: lurek.network.newRuntime
-- Creates a background network runtime for async HTTP, TCP, and WebSocket.
-- Call when you need to create a new runtime.
local ok, obj = pcall(function() return lurek.network.newRuntime() end)
if ok and obj then print("created:", obj) end
print("lurek.network.newRuntime ok=", ok)

--@api-stub: lurek.network.pack
-- Serializes a Lua value to a binary MessagePack string.
-- Call when you need to invoke pack.
local ok, result = pcall(function() return lurek.network.pack(nil) end)
if ok then print("lurek.network.pack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.network.unpack
-- Deserializes a MessagePack binary string back to a Lua value.
-- Call when you need to invoke unpack.
local ok, result = pcall(function() return lurek.network.unpack({}) end)
if ok then print("lurek.network.unpack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.network.createLobby
-- Creates a LobbyInfo record and broadcasts it once on the local network.
-- Call when you need to create a new lobby.
local ok, obj = pcall(function() return lurek.network.createLobby("name", nil, 10, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.network.createLobby ok=", ok)

--@api-stub: lurek.network.discoverLobbies
-- Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
-- Call when you need to invoke discover lobbies.
local ok, result = pcall(function() return lurek.network.discoverLobbies(nil) end)
if ok then print("lurek.network.discoverLobbies ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.network.syncEntity
-- Convenience helper: packs an entity snapshot and broadcasts it to all peers.
-- Call when you need to invoke sync entity.
local ok, result = pcall(function() return lurek.network.syncEntity() end)
if ok then print("lurek.network.syncEntity ->", result)
else print("unavailable:", result) end

-- ── NetworkHost methods ──

--@api-stub: NetworkHost:service
-- Polls the network for one event, returning an event table or nil.
-- Call when you need to invoke service.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:service() end)
  print("NetworkHost:service ->", ok, result)
end

--@api-stub: NetworkHost:flush
-- Flushes all pending sends immediately.
-- Call when you need to invoke flush.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:flush() end)
  print("NetworkHost:flush ->", ok, result)
end

--@api-stub: NetworkHost:resetPeer
-- Resets a peer connection immediately without notifying the remote side.
-- Call when you need to invoke reset peer.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:resetPeer(1) end)
  print("NetworkHost:resetPeer ->", ok, result)
end

--@api-stub: NetworkHost:ping
-- Sends a ping to a peer to measure round-trip time.
-- Call when you need to invoke ping.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:ping(1) end)
  print("NetworkHost:ping ->", ok, result)
end

--@api-stub: NetworkHost:getRoundTripTime
-- Returns the round-trip time estimate for a peer in milliseconds.
-- Call when you need to read round trip time.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getRoundTripTime(1) end)
  print("NetworkHost:getRoundTripTime ->", ok, result)
end

--@api-stub: NetworkHost:getPeerState
-- Returns the connection state of a peer as a string.
-- Call when you need to read peer state.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getPeerState(1) end)
  print("NetworkHost:getPeerState ->", ok, result)
end

--@api-stub: NetworkHost:getPeerAddress
-- Returns the remote address of a peer, or nil if unavailable.
-- Call when you need to read peer address.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getPeerAddress(1) end)
  print("NetworkHost:getPeerAddress ->", ok, result)
end

--@api-stub: NetworkHost:getAddress
-- Returns the local bind address as a string.
-- Call when you need to read address.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getAddress() end)
  print("NetworkHost:getAddress ->", ok, result)
end

--@api-stub: NetworkHost:getPeerLimit
-- Returns the maximum number of peer slots.
-- Call when you need to read peer limit.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getPeerLimit() end)
  print("NetworkHost:getPeerLimit ->", ok, result)
end

--@api-stub: NetworkHost:getChannelLimit
-- Returns the maximum number of channels per connection.
-- Call when you need to read channel limit.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getChannelLimit() end)
  print("NetworkHost:getChannelLimit ->", ok, result)
end

--@api-stub: NetworkHost:setChannelLimit
-- Sets the channel limit for future connections.
-- Call when you need to assign channel limit.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:setChannelLimit(nil) end)
  print("NetworkHost:setChannelLimit ->", ok, result)
end

--@api-stub: NetworkHost:getBandwidthLimit
-- Returns the bandwidth limits as a table with incoming and outgoing fields.
-- Call when you need to read bandwidth limit.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getBandwidthLimit() end)
  print("NetworkHost:getBandwidthLimit ->", ok, result)
end

--@api-stub: NetworkHost:getConnectedPeerCount
-- Returns the number of currently connected peers.
-- Call when you need to read connected peer count.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getConnectedPeerCount() end)
  print("NetworkHost:getConnectedPeerCount ->", ok, result)
end

--@api-stub: NetworkHost:getConnectedPeerIds
-- Returns a table of connected peer IDs.
-- Call when you need to read connected peer ids.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getConnectedPeerIds() end)
  print("NetworkHost:getConnectedPeerIds ->", ok, result)
end

--@api-stub: NetworkHost:getPeerStats
-- Returns a statistics table for a peer.
-- Call when you need to read peer stats.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getPeerStats(1) end)
  print("NetworkHost:getPeerStats ->", ok, result)
end

--@api-stub: NetworkHost:destroy
-- Destroys the host, closing the underlying socket.
-- Call when you need to invoke destroy.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:destroy() end)
  print("NetworkHost:destroy ->", ok, result)
end

--@api-stub: NetworkHost:isDestroyed
-- Returns true if the host has been destroyed.
-- Call when you need to check is destroyed.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:isDestroyed() end)
  print("NetworkHost:isDestroyed ->", ok, result)
end

--@api-stub: NetworkHost:getRole
-- Returns the multiplayer role of this host ("server", "client", or "host").
-- Call when you need to read role.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:getRole() end)
  print("NetworkHost:getRole ->", ok, result)
end

--@api-stub: NetworkHost:isServer
-- Returns true if this host was created as a server.
-- Call when you need to check is server.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:isServer() end)
  print("NetworkHost:isServer ->", ok, result)
end

--@api-stub: NetworkHost:isClient
-- Returns true if this host was created as a client.
-- Call when you need to check is client.
-- Build a NetworkHost via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkHost(...)
if instance then
  local ok, result = pcall(function() return instance:isClient() end)
  print("NetworkHost:isClient ->", ok, result)
end

-- ── NetworkRuntime methods ──

--@api-stub: NetworkRuntime:httpRequest
-- Sends an HTTP request asynchronously.
-- Poll with `poll()` for the response.
-- Build a NetworkRuntime via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkRuntime(...)
if instance then
  local ok, result = pcall(function() return instance:httpRequest({}) end)
  print("NetworkRuntime:httpRequest ->", ok, result)
end

--@api-stub: NetworkRuntime:tcpConnect
-- Opens a TCP connection to a remote address.
-- Call when you need to invoke tcp connect.
-- Build a NetworkRuntime via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkRuntime(...)
if instance then
  local ok, result = pcall(function() return instance:tcpConnect(nil) end)
  print("NetworkRuntime:tcpConnect ->", ok, result)
end

--@api-stub: NetworkRuntime:tcpSend
-- Sends data over a TCP connection.
-- Call when you need to invoke tcp send.
-- Build a NetworkRuntime via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkRuntime(...)
if instance then
  local ok, result = pcall(function() return instance:tcpSend(1, {}) end)
  print("NetworkRuntime:tcpSend ->", ok, result)
end

--@api-stub: NetworkRuntime:tcpClose
-- Closes the TCP connection identified by the given connection handle.
-- Call when you need to invoke tcp close.
-- Build a NetworkRuntime via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkRuntime(...)
if instance then
  local ok, result = pcall(function() return instance:tcpClose(1) end)
  print("NetworkRuntime:tcpClose ->", ok, result)
end

--@api-stub: NetworkRuntime:wsConnect
-- Opens a WebSocket connection.
-- Call when you need to invoke ws connect.
-- Build a NetworkRuntime via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkRuntime(...)
if instance then
  local ok, result = pcall(function() return instance:wsConnect("https://example.com") end)
  print("NetworkRuntime:wsConnect ->", ok, result)
end

--@api-stub: NetworkRuntime:wsSend
-- Sends a text message over a WebSocket connection.
-- Call when you need to invoke ws send.
-- Build a NetworkRuntime via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkRuntime(...)
if instance then
  local ok, result = pcall(function() return instance:wsSend(1, {}) end)
  print("NetworkRuntime:wsSend ->", ok, result)
end

--@api-stub: NetworkRuntime:wsClose
-- Closes a WebSocket connection.
-- Call when you need to invoke ws close.
-- Build a NetworkRuntime via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkRuntime(...)
if instance then
  local ok, result = pcall(function() return instance:wsClose(1) end)
  print("NetworkRuntime:wsClose ->", ok, result)
end

--@api-stub: NetworkRuntime:poll
-- Polls for completed async responses (HTTP, TCP events, WebSocket events).
-- Call when you need to invoke poll.
-- Build a NetworkRuntime via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkRuntime(...)
if instance then
  local ok, result = pcall(function() return instance:poll() end)
  print("NetworkRuntime:poll ->", ok, result)
end

--@api-stub: NetworkRuntime:shutdown
-- Shuts down the background network thread.
-- Call when you need to invoke shutdown.
-- Build a NetworkRuntime via the appropriate lurek.network.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.network.newNetworkRuntime(...)
if instance then
  local ok, result = pcall(function() return instance:shutdown() end)
  print("NetworkRuntime:shutdown ->", ok, result)
end

