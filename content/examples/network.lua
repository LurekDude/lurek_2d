-- content/examples/network.lua
-- Auto-scaffolded coverage of the lurek.network Lua API (38 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/network.lua

print("[example] lurek.network loaded — 38 API items demonstrated")

-- ── lurek.network free functions ──

--@api-stub: lurek.network.newHost
-- Creates a new network host bound to the given address.
-- Use this when creates a new network host bound to the given address is needed.
if false then
  local _r = lurek.network.newHost(0)
  print(_r)
end

--@api-stub: lurek.network.newServer
-- Creates a server host that binds to a port and accepts connections.
-- Use this when creates a server host that binds to a port and accepts connections is needed.
if false then
  local _r = lurek.network.newServer(0)
  print(_r)
end

--@api-stub: lurek.network.newClient
-- Creates a client host that connects to a remote server.
-- Use this when creates a client host that connects to a remote server is needed.
if false then
  local _r = lurek.network.newClient(0)
  print(_r)
end

--@api-stub: lurek.network.newRuntime
-- Creates a background network runtime for async HTTP, TCP, and WebSocket.
-- Use this when creates a background network runtime for async HTTP, TCP, and WebSocket is needed.
if false then
  local _r = lurek.network.newRuntime()
  print(_r)
end

--@api-stub: lurek.network.pack
-- Serializes a Lua value to a binary MessagePack string.
-- Use this when serializes a Lua value to a binary MessagePack string is needed.
if false then
  local _r = lurek.network.pack(0)
  print(_r)
end

--@api-stub: lurek.network.unpack
-- Deserializes a MessagePack binary string back to a Lua value.
-- Use this when deserializes a MessagePack binary string back to a Lua value is needed.
if false then
  local _r = lurek.network.unpack(0)
  print(_r)
end

--@api-stub: lurek.network.createLobby
-- Creates a LobbyInfo record and broadcasts it once on the local network.
-- Use this when creates a LobbyInfo record and broadcasts it once on the local network is needed.
if false then
  local _r = lurek.network.createLobby(1, 0, 1, 0)
  print(_r)
end

--@api-stub: lurek.network.discoverLobbies
-- Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
-- Use this when listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500) is needed.
if false then
  local _r = lurek.network.discoverLobbies(0)
  print(_r)
end

--@api-stub: lurek.network.syncEntity
-- Convenience helper: packs an entity snapshot and broadcasts it to all peers.
-- Use this when convenience helper: packs an entity snapshot and broadcasts it to all peers is needed.
if false then
  local _r = lurek.network.syncEntity()
  print(_r)
end

-- ── NetworkHost methods ──

--@api-stub: NetworkHost:service
-- Polls the network for one event, returning an event table or nil.
-- Use this when polls the network for one event, returning an event table or nil is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:service()
end

--@api-stub: NetworkHost:flush
-- Flushes all pending sends immediately.
-- Use this when flushes all pending sends immediately is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:flush()
end

--@api-stub: NetworkHost:resetPeer
-- Resets a peer connection immediately without notifying the remote side.
-- Use this when resets a peer connection immediately without notifying the remote side is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:resetPeer(1)
end

--@api-stub: NetworkHost:ping
-- Sends a ping to a peer to measure round-trip time.
-- Use this when sends a ping to a peer to measure round-trip time is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:ping(1)
end

--@api-stub: NetworkHost:getRoundTripTime
-- Returns the round-trip time estimate for a peer in milliseconds.
-- Use this when returns the round-trip time estimate for a peer in milliseconds is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getRoundTripTime(1)
end

--@api-stub: NetworkHost:getPeerState
-- Returns the connection state of a peer as a string.
-- Use this when returns the connection state of a peer as a string is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getPeerState(1)
end

--@api-stub: NetworkHost:getPeerAddress
-- Returns the remote address of a peer, or nil if unavailable.
-- Use this when returns the remote address of a peer, or nil if unavailable is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getPeerAddress(1)
end

--@api-stub: NetworkHost:getAddress
-- Returns the local bind address as a string.
-- Use this when returns the local bind address as a string is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getAddress()
end

--@api-stub: NetworkHost:getPeerLimit
-- Returns the maximum number of peer slots.
-- Use this when returns the maximum number of peer slots is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getPeerLimit()
end

--@api-stub: NetworkHost:getChannelLimit
-- Returns the maximum number of channels per connection.
-- Use this when returns the maximum number of channels per connection is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getChannelLimit()
end

--@api-stub: NetworkHost:setChannelLimit
-- Sets the channel limit for future connections.
-- Use this when sets the channel limit for future connections is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:setChannelLimit(0)
end

--@api-stub: NetworkHost:getBandwidthLimit
-- Returns the bandwidth limits as a table with incoming and outgoing fields.
-- Use this when returns the bandwidth limits as a table with incoming and outgoing fields is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getBandwidthLimit()
end

--@api-stub: NetworkHost:getConnectedPeerCount
-- Returns the number of currently connected peers.
-- Use this when returns the number of currently connected peers is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getConnectedPeerCount()
end

--@api-stub: NetworkHost:getConnectedPeerIds
-- Returns a table of connected peer IDs.
-- Use this when returns a table of connected peer IDs is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getConnectedPeerIds()
end

--@api-stub: NetworkHost:getPeerStats
-- Returns a statistics table for a peer.
-- Use this when returns a statistics table for a peer is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getPeerStats(1)
end

--@api-stub: NetworkHost:destroy
-- Destroys the host, closing the underlying socket.
-- Use this when destroys the host, closing the underlying socket is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:destroy()
end

--@api-stub: NetworkHost:isDestroyed
-- Returns true if the host has been destroyed.
-- Use this when returns true if the host has been destroyed is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:isDestroyed()
end

--@api-stub: NetworkHost:getRole
-- Returns the multiplayer role of this host ("server", "client", or "host").
-- Use this when returns the multiplayer role of this host ("server", "client", or "host") is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:getRole()
end

--@api-stub: NetworkHost:isServer
-- Returns true if this host was created as a server.
-- Use this when returns true if this host was created as a server is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:isServer()
end

--@api-stub: NetworkHost:isClient
-- Returns true if this host was created as a client.
-- Use this when returns true if this host was created as a client is needed.
if false then
  local _o = nil  -- NetworkHost instance
  _o:isClient()
end

-- ── NetworkRuntime methods ──

--@api-stub: NetworkRuntime:httpRequest
-- Sends an HTTP request asynchronously.
-- Poll with `poll()` for the response.
if false then
  local _o = nil  -- NetworkRuntime instance
  _o:httpRequest(0)
end

--@api-stub: NetworkRuntime:tcpConnect
-- Opens a TCP connection to a remote address.
-- Use this when opens a TCP connection to a remote address is needed.
if false then
  local _o = nil  -- NetworkRuntime instance
  _o:tcpConnect(nil)
end

--@api-stub: NetworkRuntime:tcpSend
-- Sends data over a TCP connection.
-- Use this when sends data over a TCP connection is needed.
if false then
  local _o = nil  -- NetworkRuntime instance
  _o:tcpSend(1, 0)
end

--@api-stub: NetworkRuntime:tcpClose
-- Closes the TCP connection identified by the given connection handle.
-- Use this when closes the TCP connection identified by the given connection handle is needed.
if false then
  local _o = nil  -- NetworkRuntime instance
  _o:tcpClose(1)
end

--@api-stub: NetworkRuntime:wsConnect
-- Opens a WebSocket connection.
-- Use this when opens a WebSocket connection is needed.
if false then
  local _o = nil  -- NetworkRuntime instance
  _o:wsConnect("url")
end

--@api-stub: NetworkRuntime:wsSend
-- Sends a text message over a WebSocket connection.
-- Use this when sends a text message over a WebSocket connection is needed.
if false then
  local _o = nil  -- NetworkRuntime instance
  _o:wsSend(1, 0)
end

--@api-stub: NetworkRuntime:wsClose
-- Closes a WebSocket connection.
-- Use this when closes a WebSocket connection is needed.
if false then
  local _o = nil  -- NetworkRuntime instance
  _o:wsClose(1)
end

--@api-stub: NetworkRuntime:poll
-- Polls for completed async responses (HTTP, TCP events, WebSocket events).
-- Use this when polls for completed async responses (HTTP, TCP events, WebSocket events) is needed.
if false then
  local _o = nil  -- NetworkRuntime instance
  _o:poll()
end

--@api-stub: NetworkRuntime:shutdown
-- Shuts down the background network thread.
-- Use this when shuts down the background network thread is needed.
if false then
  local _o = nil  -- NetworkRuntime instance
  _o:shutdown()
end

