-- content/examples/network.lua
-- Scaffolded coverage of the lurek.network API (38 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/network_api.rs   (Lua binding, arg types, return shape)
--   * src/network/                 (semantics, side effects)
--   * docs/specs/network.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/network.lua

-- ── lurek.network.* functions ──

--@api-stub: lurek.network.newHost
-- Creates a new network host bound to the given address.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: lurek.network.newHost
  local _todo = "TODO: write a real lurek.network.newHost usage example"
  print(_todo)
end

--@api-stub: lurek.network.newServer
-- Creates a server host that binds to a port and accepts connections.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: lurek.network.newServer
  local _todo = "TODO: write a real lurek.network.newServer usage example"
  print(_todo)
end

--@api-stub: lurek.network.newClient
-- Creates a client host that connects to a remote server.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: lurek.network.newClient
  local _todo = "TODO: write a real lurek.network.newClient usage example"
  print(_todo)
end

--@api-stub: lurek.network.newRuntime
-- Creates a background network runtime for async HTTP, TCP, and WebSocket.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: lurek.network.newRuntime
  local _todo = "TODO: write a real lurek.network.newRuntime usage example"
  print(_todo)
end

--@api-stub: lurek.network.pack
-- Serializes a Lua value to a binary MessagePack string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: lurek.network.pack
  local _todo = "TODO: write a real lurek.network.pack usage example"
  print(_todo)
end

--@api-stub: lurek.network.unpack
-- Deserializes a MessagePack binary string back to a Lua value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: lurek.network.unpack
  local _todo = "TODO: write a real lurek.network.unpack usage example"
  print(_todo)
end

--@api-stub: lurek.network.createLobby
-- Creates a LobbyInfo record and broadcasts it once on the local network.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: lurek.network.createLobby
  local _todo = "TODO: write a real lurek.network.createLobby usage example"
  print(_todo)
end

--@api-stub: lurek.network.discoverLobbies
-- Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: lurek.network.discoverLobbies
  local _todo = "TODO: write a real lurek.network.discoverLobbies usage example"
  print(_todo)
end

--@api-stub: lurek.network.syncEntity
-- Convenience helper: packs an entity snapshot and broadcasts it to all peers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: lurek.network.syncEntity
  local _todo = "TODO: write a real lurek.network.syncEntity usage example"
  print(_todo)
end

-- ── NetworkHost methods ──

--@api-stub: NetworkHost:service
-- Polls the network for one event, returning an event table or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:service
  local _todo = "TODO: write a real NetworkHost:service usage example"
  print(_todo)
end

--@api-stub: NetworkHost:flush
-- Flushes all pending sends immediately.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:flush
  local _todo = "TODO: write a real NetworkHost:flush usage example"
  print(_todo)
end

--@api-stub: NetworkHost:resetPeer
-- Resets a peer connection immediately without notifying the remote side.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:resetPeer
  local _todo = "TODO: write a real NetworkHost:resetPeer usage example"
  print(_todo)
end

--@api-stub: NetworkHost:ping
-- Sends a ping to a peer to measure round-trip time.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:ping
  local _todo = "TODO: write a real NetworkHost:ping usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getRoundTripTime
-- Returns the round-trip time estimate for a peer in milliseconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getRoundTripTime
  local _todo = "TODO: write a real NetworkHost:getRoundTripTime usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getPeerState
-- Returns the connection state of a peer as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getPeerState
  local _todo = "TODO: write a real NetworkHost:getPeerState usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getPeerAddress
-- Returns the remote address of a peer, or nil if unavailable.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getPeerAddress
  local _todo = "TODO: write a real NetworkHost:getPeerAddress usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getAddress
-- Returns the local bind address as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getAddress
  local _todo = "TODO: write a real NetworkHost:getAddress usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getPeerLimit
-- Returns the maximum number of peer slots.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getPeerLimit
  local _todo = "TODO: write a real NetworkHost:getPeerLimit usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getChannelLimit
-- Returns the maximum number of channels per connection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getChannelLimit
  local _todo = "TODO: write a real NetworkHost:getChannelLimit usage example"
  print(_todo)
end

--@api-stub: NetworkHost:setChannelLimit
-- Sets the channel limit for future connections.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:setChannelLimit
  local _todo = "TODO: write a real NetworkHost:setChannelLimit usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getBandwidthLimit
-- Returns the bandwidth limits as a table with incoming and outgoing fields.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getBandwidthLimit
  local _todo = "TODO: write a real NetworkHost:getBandwidthLimit usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getConnectedPeerCount
-- Returns the number of currently connected peers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getConnectedPeerCount
  local _todo = "TODO: write a real NetworkHost:getConnectedPeerCount usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getConnectedPeerIds
-- Returns a table of connected peer IDs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getConnectedPeerIds
  local _todo = "TODO: write a real NetworkHost:getConnectedPeerIds usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getPeerStats
-- Returns a statistics table for a peer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getPeerStats
  local _todo = "TODO: write a real NetworkHost:getPeerStats usage example"
  print(_todo)
end

--@api-stub: NetworkHost:destroy
-- Destroys the host, closing the underlying socket.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:destroy
  local _todo = "TODO: write a real NetworkHost:destroy usage example"
  print(_todo)
end

--@api-stub: NetworkHost:isDestroyed
-- Returns true if the host has been destroyed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:isDestroyed
  local _todo = "TODO: write a real NetworkHost:isDestroyed usage example"
  print(_todo)
end

--@api-stub: NetworkHost:getRole
-- Returns the multiplayer role of this host ("server", "client", or "host").
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:getRole
  local _todo = "TODO: write a real NetworkHost:getRole usage example"
  print(_todo)
end

--@api-stub: NetworkHost:isServer
-- Returns true if this host was created as a server.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:isServer
  local _todo = "TODO: write a real NetworkHost:isServer usage example"
  print(_todo)
end

--@api-stub: NetworkHost:isClient
-- Returns true if this host was created as a client.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkHost:isClient
  local _todo = "TODO: write a real NetworkHost:isClient usage example"
  print(_todo)
end

-- ── NetworkRuntime methods ──

--@api-stub: NetworkRuntime:httpRequest
-- Sends an HTTP request asynchronously.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkRuntime:httpRequest
  local _todo = "TODO: write a real NetworkRuntime:httpRequest usage example"
  print(_todo)
end

--@api-stub: NetworkRuntime:tcpConnect
-- Opens a TCP connection to a remote address.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkRuntime:tcpConnect
  local _todo = "TODO: write a real NetworkRuntime:tcpConnect usage example"
  print(_todo)
end

--@api-stub: NetworkRuntime:tcpSend
-- Sends data over a TCP connection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkRuntime:tcpSend
  local _todo = "TODO: write a real NetworkRuntime:tcpSend usage example"
  print(_todo)
end

--@api-stub: NetworkRuntime:tcpClose
-- Closes the TCP connection identified by the given connection handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkRuntime:tcpClose
  local _todo = "TODO: write a real NetworkRuntime:tcpClose usage example"
  print(_todo)
end

--@api-stub: NetworkRuntime:wsConnect
-- Opens a WebSocket connection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkRuntime:wsConnect
  local _todo = "TODO: write a real NetworkRuntime:wsConnect usage example"
  print(_todo)
end

--@api-stub: NetworkRuntime:wsSend
-- Sends a text message over a WebSocket connection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkRuntime:wsSend
  local _todo = "TODO: write a real NetworkRuntime:wsSend usage example"
  print(_todo)
end

--@api-stub: NetworkRuntime:wsClose
-- Closes a WebSocket connection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkRuntime:wsClose
  local _todo = "TODO: write a real NetworkRuntime:wsClose usage example"
  print(_todo)
end

--@api-stub: NetworkRuntime:poll
-- Polls for completed async responses (HTTP, TCP events, WebSocket events).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkRuntime:poll
  local _todo = "TODO: write a real NetworkRuntime:poll usage example"
  print(_todo)
end

--@api-stub: NetworkRuntime:shutdown
-- Shuts down the background network thread.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/network_api.rs and docs/specs/network.md).
do  -- TODO: NetworkRuntime:shutdown
  local _todo = "TODO: write a real NetworkRuntime:shutdown usage example"
  print(_todo)
end

