# network

## General Info

- Module group: `Core Runtime`
- Source path: `src/network/`
- Lua API path(s): `src/lua_api/network_api.rs`
- Primary Lua namespace: `lurek.network`
- Rust test path(s): tests/rust/unit/network_tests.rs
- Lua test path(s): tests/lua/unit/test_network.lua, tests/lua/unit/test_network_constants.lua, tests/lua/unit/test_network_pack_unpack.lua, tests/lua/unit/test_network_roles.lua, tests/lua/unit/test_network_runtimer.lua, tests/lua/security/test_network_security.lua

## Summary

The `network` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Core Runtime group rather than absorb behavior owned by those neighbors.

## Files

- `constants.rs`: Compile-time limits and defaults (MAX_PEERS=4096, DEFAULT_PEERS=16, DEFAULT_CHANNELS=2, HTTP_TIMEOUT_SECS=30, TCP_BUFFER_SIZE=65536, WS_BUFFER_SIZE=65536).
- `error.rs`: `NetworkError` enum with variants: ConnectionFailed, SendFailed, InvalidPeer, InvalidAddress, Http, WebSocket, Tcp, Serialization, Thread.
- `host.rs`: ENet host wrapper with `HostRole` enum; factory methods `create_server`, `create_client`.
- `http.rs`: HTTP client via `ureq`. `HttpResponse` struct, `execute_request` function.
- `lobby.rs`: LAN lobby discovery via UDP broadcast.
- `message.rs`: MessagePack serialization. `NetValue` enum, `pack`/`unpack` functions.
- `mod.rs`: Module root — declares all 8 sub-modules.
- `net_thread.rs`: Background I/O thread. `NetworkRuntime`, `NetworkRequest`, `NetworkResponse`, `TcpEvent`, `WsEvent`.
- `tcp.rs`: Non-blocking TCP with `TcpConnectionManager`.
- `websocket.rs`: WebSocket client with `WebSocketManager`.

## Types

- `NetworkError` (`enum`, `error.rs`): Errors for ENet, HTTP, TCP, WebSocket, serialization, and threading.
- `HostRole` (`enum`, `host.rs`): Server, Client, or Host (peer-to-peer).
- `NetworkHost` (`struct`, `host.rs`): Wraps `rusty_enet::Host<UdpSocket>` with role and limit enforcement.
- `NetworkEvent` (`enum`, `host.rs`): Result of a single `NetworkHost::service` call.
- `PeerStats` (`struct`, `host.rs`): Per-peer statistics snapshot.
- `HttpResponse` (`struct`, `http.rs`): HTTP response with status, body, headers, error.
- `LobbyInfo` (`struct`, `lobby.rs`): Metadata about a discoverable game lobby.
- `NetValue` (`enum`, `message.rs`): Nil, Bool, Integer, Float, String, Array, Map — serializable Lua values.
- `NetworkRequest` (`enum`, `net_thread.rs`): HttpRequest, TcpConnect, TcpSend, TcpClose, WsConnect, WsSend, WsClose, Shutdown.
- `NetworkResponse` (`enum`, `net_thread.rs`): HttpResponse, TcpEvent, WebSocketEvent.
- `TcpEvent` (`enum`, `net_thread.rs`): Connected, Data, Disconnected, Error.
- `WsEvent` (`enum`, `net_thread.rs`): Open, Text, Binary, Close, Error.
- `NetworkRuntime` (`struct`, `net_thread.rs`): Background I/O thread with mpsc channel bridge.
- `TcpConnectionManager` (`struct`, `tcp.rs`): Manages multiple non-blocking TCP connections.
- `WebSocketManager` (`struct`, `websocket.rs`): Manages multiple WebSocket connections.

## Functions

- `NetworkHost::new` (`host.rs`): Create a new ENet host bound to `bind_addr`.
- `NetworkHost::service` (`host.rs`): Poll for one network event.
- `NetworkHost::connect` (`host.rs`): Initiate a connection to a remote host.
- `NetworkHost::send` (`host.rs`): Send a packet to a specific peer.
- `NetworkHost::send_bytes` (`host.rs`): Send raw bytes to a specific peer with a reliability flag.
- `NetworkHost::broadcast` (`host.rs`): Broadcast a packet to all connected peers.
- `NetworkHost::broadcast_bytes` (`host.rs`): Broadcast raw bytes to all connected peers with a reliability flag.
- `NetworkHost::flush` (`host.rs`): Flush all queued packets without waiting for the next `service()`.
- `NetworkHost::disconnect` (`host.rs`): Request graceful disconnection from a peer.
- `NetworkHost::disconnect_now` (`host.rs`): Immediately disconnect a peer without handshake.
- `NetworkHost::disconnect_later` (`host.rs`): Disconnect a peer after all queued packets have been sent.
- `NetworkHost::reset_peer` (`host.rs`): Reset a peer connection immediately without notifying the remote side.
- `NetworkHost::ping` (`host.rs`): Send a ping to a peer to measure RTT.
- `NetworkHost::round_trip_time` (`host.rs`): Get the round-trip time estimate for a peer.
- `NetworkHost::peer_state` (`host.rs`): Get the connection state of a peer as a string.
- `NetworkHost::peer_address` (`host.rs`): Get the remote address of a peer.
- `NetworkHost::local_address` (`host.rs`): Get the local bind address.
- `NetworkHost::peer_limit` (`host.rs`): Get the number of allocated peer slots.
- `NetworkHost::channel_limit` (`host.rs`): Get the channel limit.
- `NetworkHost::set_channel_limit` (`host.rs`): Set the channel limit for future connections.
- `NetworkHost::bandwidth_limit` (`host.rs`): Get the bandwidth limits.
- `NetworkHost::set_bandwidth_limit` (`host.rs`): Set bandwidth limits.
- `NetworkHost::connected_peer_count` (`host.rs`): Get the number of currently connected peers.
- `NetworkHost::destroy` (`host.rs`): Destroy the host, closing the underlying socket.
- `NetworkHost::is_destroyed` (`host.rs`): Returns `true` if the host has been destroyed.
- `NetworkHost::connected_peer_ids` (`host.rs`): Get the IDs of all currently connected peers.
- `NetworkHost::create_server` (`host.rs`): Create a server host that binds to a port and accepts connections.
- `NetworkHost::create_client` (`host.rs`): Create a client host that connects to a remote server.
- `NetworkHost::role` (`host.rs`): Get the multiplayer role of this host.
- `NetworkHost::set_role` (`host.rs`): Set the multiplayer role of this host.
- `NetworkHost::peer_stats` (`host.rs`): Get per-peer statistics.
- `execute_request` (`http.rs`): Execute an HTTP request synchronously (called from the network thread).
- `LobbyInfo::to_wire` (`lobby.rs`): Serialises this lobby record into the wire format.
- `LobbyInfo::from_wire` (`lobby.rs`): Parses a lobby record from the wire format.
- `broadcast_lobby` (`lobby.rs`): Broadcasts a lobby announcement to the subnet once.
- `discover_lobbies` (`lobby.rs`): Listens for lobby announcements on [`LOBBY_PORT`] for `timeout_ms` milliseconds.
- `pack` (`message.rs`): Serialize a [`NetValue`] to MessagePack bytes.
- `unpack` (`message.rs`): Deserialize MessagePack bytes into a [`NetValue`].
- `estimate_size` (`message.rs`): Estimate the serialized size of a [`NetValue`] without allocating.
- `NetworkRuntime::new` (`net_thread.rs`): Create a new `NetworkRuntime`, spawning the background I/O thread.
- `NetworkRuntime::next_request_id` (`net_thread.rs`): Generate the next unique request ID.
- `NetworkRuntime::send` (`net_thread.rs`): Send a request to the network thread.
- `NetworkRuntime::poll` (`net_thread.rs`): Drain all completed responses from the network thread.
- `NetworkRuntime::shutdown` (`net_thread.rs`): Shut down the network thread gracefully.
- `NetworkRuntime::is_running` (`net_thread.rs`): Returns `true` if the background thread is still alive.
- `NetworkRuntime::http_request` (`net_thread.rs`): Send an HTTP request to the network thread.
- `NetworkRuntime::tcp_connect` (`net_thread.rs`): Open a TCP connection on the network thread.
- `NetworkRuntime::tcp_send` (`net_thread.rs`): Send data on a TCP connection.
- `NetworkRuntime::tcp_close` (`net_thread.rs`): Close a TCP connection.
- `NetworkRuntime::ws_connect` (`net_thread.rs`): Open a WebSocket connection on the network thread.
- `NetworkRuntime::ws_send` (`net_thread.rs`): Send a text message on a WebSocket connection.
- `NetworkRuntime::ws_close` (`net_thread.rs`): Close a WebSocket connection.
- `TcpConnectionManager::new` (`tcp.rs`): Create a new empty connection manager.
- `TcpConnectionManager::connect` (`tcp.rs`): Open a new TCP connection to the given address.
- `TcpConnectionManager::send` (`tcp.rs`): Send data on an existing TCP connection.
- `TcpConnectionManager::close` (`tcp.rs`): Close a TCP connection.
- `TcpConnectionManager::poll_all` (`tcp.rs`): Poll all active connections for incoming data.
- `TcpConnectionManager::close_all` (`tcp.rs`): Close all active TCP connections.
- `TcpConnectionManager::is_empty` (`tcp.rs`): Returns `true` if there are no active TCP connections.
- `WebSocketManager::new` (`websocket.rs`): Create a new empty WebSocket manager.
- `WebSocketManager::is_empty` (`websocket.rs`): Returns `true` if there are no active WebSocket connections.
- `WebSocketManager::connect` (`websocket.rs`): Open a new WebSocket connection.
- `WebSocketManager::send` (`websocket.rs`): Send data on an existing WebSocket connection.
- `WebSocketManager::close` (`websocket.rs`): Close a WebSocket connection with a close frame.
- `WebSocketManager::poll_all` (`websocket.rs`): Poll all active WebSocket connections for incoming messages.
- `WebSocketManager::close_all` (`websocket.rs`): Close all active WebSocket connections.

## Lua API Reference

- Binding path(s): `src/lua_api/network_api.rs`
- Namespace: `lurek.network`

### Module Functions
- `lurek.network.newHost`: Creates a new network host bound to the given address.
- `lurek.network.newServer`: Creates a server host that binds to a port and accepts connections.
- `lurek.network.newClient`: Creates a client host that connects to a remote server.
- `lurek.network.newRuntime`: Creates a background network runtime for async HTTP, TCP, and WebSocket.
- `lurek.network.pack`: Serializes a Lua value to a binary MessagePack string.
- `lurek.network.unpack`: Deserializes a MessagePack binary string back to a Lua value.
- `lurek.network.createLobby`: Creates a LobbyInfo record and broadcasts it once on the local network.
- `lurek.network.discoverLobbies`: Listens for LAN lobby announcements for `timeout_ms` milliseconds (default 500).
- `lurek.network.syncEntity`: Convenience helper: packs an entity snapshot and broadcasts it to all peers.

### `LNetworkHost` Methods
- `LNetworkHost:service`: Polls the network for one event, returning an event table or nil.
- `LNetworkHost:connect`: Initiates a connection to a remote host, returning the peer ID.
- `LNetworkHost:send`: Sends data to a specific peer on a channel.
- `LNetworkHost:broadcast`: Broadcasts data to all connected peers on a channel.
- `LNetworkHost:flush`: Flushes all pending sends immediately.
- `LNetworkHost:disconnect`: Gracefully disconnects a peer.
- `LNetworkHost:disconnectNow`: Immediately disconnects a peer without handshake.
- `LNetworkHost:disconnectLater`: Disconnects a peer after all queued packets have been sent.
- `LNetworkHost:resetPeer`: Resets a peer connection immediately without notifying the remote side.
- `LNetworkHost:ping`: Sends a ping to a peer to measure round-trip time.
- `LNetworkHost:getRoundTripTime`: Returns the round-trip time estimate for a peer in milliseconds.
- `LNetworkHost:getPeerState`: Returns the connection state of a peer as a string.
- `LNetworkHost:getPeerAddress`: Returns the remote address of a peer, or nil if unavailable.
- `LNetworkHost:getAddress`: Returns the local bind address as a string.
- `LNetworkHost:getPeerLimit`: Returns the maximum number of peer slots.
- `LNetworkHost:getChannelLimit`: Returns the maximum number of channels per connection.
- `LNetworkHost:setChannelLimit`: Sets the channel limit for future connections.
- `LNetworkHost:getBandwidthLimit`: Returns the bandwidth limits as a table with incoming and outgoing fields.
- `LNetworkHost:setBandwidthLimit`: Sets the bandwidth limits in bytes per second.
- `LNetworkHost:getConnectedPeerCount`: Returns the number of currently connected peers.
- `LNetworkHost:getConnectedPeerIds`: Returns a table of connected peer IDs.
- `LNetworkHost:getPeerStats`: Returns a statistics table for a peer.
- `LNetworkHost:destroy`: Destroys the host, closing the underlying socket.
- `LNetworkHost:isDestroyed`: Returns true if the host has been destroyed.
- `LNetworkHost:getRole`: Returns the multiplayer role of this host ("server", "client", or "host").
- `LNetworkHost:isServer`: Returns true if this host was created as a server.
- `LNetworkHost:isClient`: Returns true if this host was created as a client.
- `LNetworkHost:type`: Returns the type name of this object.
- `LNetworkHost:typeOf`: Returns true if this object is of the given type.

### `LNetworkRuntime` Methods
- `LNetworkRuntime:httpRequest`: Sends an HTTP request asynchronously. Poll with `poll()` for the response.
- `LNetworkRuntime:httpGet`: Convenience: sends an HTTP GET request.
- `LNetworkRuntime:httpPost`: Convenience: sends an HTTP POST request.
- `LNetworkRuntime:tcpConnect`: Opens a TCP connection to a remote address.
- `LNetworkRuntime:tcpSend`: Sends data over a TCP connection.
- `LNetworkRuntime:tcpClose`: Closes the TCP connection identified by the given connection handle.
- `LNetworkRuntime:wsConnect`: Opens a WebSocket connection.
- `LNetworkRuntime:wsSend`: Sends a text message over a WebSocket connection.
- `LNetworkRuntime:wsClose`: Closes a WebSocket connection.
- `LNetworkRuntime:poll`: Polls for completed async responses (HTTP, TCP events, WebSocket events).
- `LNetworkRuntime:shutdown`: Shuts down the background network thread.
- `LNetworkRuntime:type`: Returns the type name of this object.
- `LNetworkRuntime:typeOf`: Returns true if this object is of the given type.

## References

- `runtime`: Imports runtime config from `src/runtime/`.

## Notes

- All non-ENet I/O runs on the background `NetworkRuntime` thread — the Lua VM never blocks.
- `HostRole` is metadata only — it does not change ENet behaviour, just helps game code distinguish server from client.
- MessagePack pack/unpack supports Nil, Bool, Integer, Float, String, Array (sequential table), Map (string-keyed table). Functions and userdata cannot be serialized.
- `constants.rs` and `error.rs` had duplicate definitions (copy-paste errors) — fixed in P3-C review (2026-04-18).
- Keep this module reference synchronized with `src/network/` and any matching Lua bindings.

### New in 0.14.1

- `lurek.network.newHost` and `newServer` accept `maxPeers` as the preferred peer-limit key; `peers` is retained as a legacy alias.

## 2026-05 Backlog Closure

- Added local matchmaking room helpers in `src/network/lobby.rs`:
	- `create_room`, `list_rooms`, `join_room`, `leave_room`.
- Added relay/NAT punch helper module `src/network/relay.rs`:
	- relay ticket encode/decode, punch probe make/parse.
- Added entity sync helper module `src/network/net_sync.rs`:
	- `EntitySnapshot`, `predict_linear`, `reconcile`.
- Exposed new Lua API helpers:
	- `createRoom`, `listRooms`, `joinRoom`, `leaveRoom`
	- `newRelayTicket`, `parseRelayTicket`, `makePunchProbe`, `parsePunchProbe`
	- `predictLinear`, `reconcileSnapshot`
- Improved runtime performance characteristics:
	- WebSocket connect path made asynchronous to avoid network-thread stalls.
	- TCP poll order switched to round-robin fairness.
- Quality adjustment:
	- `DEFAULT_PEERS` changed to `64` from `166` and tests updated.
