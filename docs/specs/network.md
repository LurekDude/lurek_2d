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
- `net_sync.rs`: - Entity snapshot capture and wire serialization for networked state.
- `net_thread.rs`: Background I/O thread. `NetworkRuntime`, `NetworkRequest`, `NetworkResponse`, `TcpEvent`, `WsEvent`.
- `relay.rs`: - Relay ticket encoding and decoding for room+peer identification over the wire.
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
- `RoomInfo` (`struct`, `lobby.rs`): Room advertisement stored in the in-process registry; used when a relay server is not available.
- `NetValue` (`enum`, `message.rs`): Nil, Bool, Integer, Float, String, Array, Map — serializable Lua values.
- `EntitySnapshot` (`struct`, `net_sync.rs`): Point-in-time position and velocity snapshot for one networked entity.
- `NetworkRequest` (`enum`, `net_thread.rs`): HttpRequest, TcpConnect, TcpSend, TcpClose, WsConnect, WsSend, WsClose, Shutdown.
- `NetworkResponse` (`enum`, `net_thread.rs`): HttpResponse, TcpEvent, WebSocketEvent.
- `TcpEvent` (`enum`, `net_thread.rs`): Connected, Data, Disconnected, Error.
- `WsEvent` (`enum`, `net_thread.rs`): Open, Text, Binary, Close, Error.
- `NetworkRuntime` (`struct`, `net_thread.rs`): Background I/O thread with mpsc channel bridge.
- `RelayTicket` (`struct`, `relay.rs`): Relay session ticket identifying a room and the connecting peer.
- `TcpConnectionManager` (`struct`, `tcp.rs`): Manages multiple non-blocking TCP connections.
- `WebSocketManager` (`struct`, `websocket.rs`): Manages multiple WebSocket connections.

## Functions

- `NetworkHost::new` (`host.rs`): Create and bind a new ENet host; returns `PeerLimitExceeded` if `peer_count` exceeds `MAX_PEERS`.
- `NetworkHost::service` (`host.rs`): Poll the ENet host for one pending event; returns `None` when the queue is empty.
- `NetworkHost::connect` (`host.rs`): Initiate a connection to `address` and return the assigned `PeerID` on success.
- `NetworkHost::send` (`host.rs`): Send a pre-built `Packet` to the given peer on `channel_id`.
- `NetworkHost::send_bytes` (`host.rs`): Send raw bytes to a peer; uses reliable ordered delivery when `reliable` is `true`.
- `NetworkHost::broadcast` (`host.rs`): Broadcast a pre-built `Packet` to all connected peers on `channel_id`.
- `NetworkHost::broadcast_bytes` (`host.rs`): Broadcast raw bytes to all connected peers; uses reliable delivery when `reliable` is `true`.
- `NetworkHost::flush` (`host.rs`): Flush the host's outgoing packet queue to the socket immediately.
- `NetworkHost::disconnect` (`host.rs`): Begin a graceful ENet disconnect handshake with the peer.
- `NetworkHost::disconnect_now` (`host.rs`): Immediately forcibly disconnect the peer without a handshake.
- `NetworkHost::disconnect_later` (`host.rs`): Queue a graceful disconnect after all queued outgoing packets have been sent.
- `NetworkHost::reset_peer` (`host.rs`): Reset a peer's state to `Disconnected` without sending any disconnect notification.
- `NetworkHost::ping` (`host.rs`): Send a ping packet to the peer to refresh the round-trip-time estimate.
- `NetworkHost::round_trip_time` (`host.rs`): Return the current measured round-trip time for the peer; returns `InvalidPeer` if unknown.
- `NetworkHost::peer_state` (`host.rs`): Return the ENet connection state of the peer as a static string label.
- `NetworkHost::peer_address` (`host.rs`): Return the remote socket address of the peer, or `None` if the address is not available.
- `NetworkHost::local_address` (`host.rs`): Return the local socket address this host is bound to.
- `NetworkHost::peer_limit` (`host.rs`): Return the maximum number of peer slots configured for this host.
- `NetworkHost::channel_limit` (`host.rs`): Return the current per-peer channel count limit.
- `NetworkHost::set_channel_limit` (`host.rs`): Set the per-peer channel count limit; returns `Enet` error if rejected.
- `NetworkHost::bandwidth_limit` (`host.rs`): Return the current `(incoming, outgoing)` bandwidth limits in bytes/sec; `None` means unlimited.
- `NetworkHost::set_bandwidth_limit` (`host.rs`): Set the incoming and outgoing bandwidth limits in bytes/sec; `None` removes the limit.
- `NetworkHost::connected_peer_count` (`host.rs`): Return the number of currently connected peers.
- `NetworkHost::destroy` (`host.rs`): Drop the inner ENet host, releasing the socket; subsequent calls to methods return `HostDestroyed`.
- `NetworkHost::is_destroyed` (`host.rs`): Return `true` if `destroy()` has been called and the host is no longer usable.
- `NetworkHost::connected_peer_ids` (`host.rs`): Return a list of `PeerID` values for all currently connected peers.
- `NetworkHost::create_server` (`host.rs`): Convenience constructor that binds a server on `0.0.0.0:<port>` with `Server` role.
- `NetworkHost::create_client` (`host.rs`): Convenience constructor that binds an ephemeral port, connects to `address`, and sets `Client` role.
- `NetworkHost::role` (`host.rs`): Return the current `HostRole` of this host.
- `NetworkHost::set_role` (`host.rs`): Override the host role; used when role is determined after creation.
- `NetworkHost::peer_stats` (`host.rs`): Collect and return a `PeerStats` snapshot for the given peer; returns `InvalidPeer` if unknown.
- `execute_request` (`http.rs`): Execute an HTTP request synchronously (called from the network thread).
- `LobbyInfo::to_wire` (`lobby.rs`): Encode this `LobbyInfo` as a `key=value;...` wire string for UDP broadcast.
- `LobbyInfo::from_wire` (`lobby.rs`): Parse a wire string back into a `LobbyInfo`; uses `sender` IP when `host` field is absent; returns `None` on malformed input.
- `broadcast_lobby` (`lobby.rs`): Broadcasts a lobby announcement to the subnet once.
- `discover_lobbies` (`lobby.rs`): Listens for lobby announcements on [`LOBBY_PORT`] for `timeout_ms` milliseconds.
- `create_room` (`lobby.rs`): Create a room entry in the global registry and return a clone of the new `RoomInfo`.
- `list_rooms` (`lobby.rs`): Return a snapshot of all rooms currently in the global registry.
- `join_room` (`lobby.rs`): Increment the player count for the given room and return the updated `RoomInfo`; returns `None` when full or not found.
- `leave_room` (`lobby.rs`): Decrement the player count for the given room and return the updated `RoomInfo`; returns `None` when not found.
- `pack` (`message.rs`): Serialize a [`NetValue`] to MessagePack bytes.
- `unpack` (`message.rs`): Deserialize MessagePack bytes into a [`NetValue`].
- `estimate_size` (`message.rs`): Estimate the serialized size of a [`NetValue`] without allocating.
- `EntitySnapshot::to_netvalue` (`net_sync.rs`): Encode this snapshot as a `NetValue::Map` suitable for wire transmission.
- `EntitySnapshot::from_netvalue` (`net_sync.rs`): Decode an `EntitySnapshot` from a `NetValue::Map`; returns `None` on missing or wrong-typed fields.
- `predict_linear` (`net_sync.rs`): Return a linearly extrapolated snapshot one tick ahead of `snapshot` using its velocity and `dt` seconds.
- `reconcile` (`net_sync.rs`): Blend `predicted` toward `authoritative` by factor `alpha` (0.0 = keep predicted, 1.0 = snap to authoritative).
- `NetworkRuntime::new` (`net_thread.rs`): Spawn the background `lurek-network` thread and return the runtime handle; returns error on thread spawn failure.
- `NetworkRuntime::next_request_id` (`net_thread.rs`): Allocate and return the next unique request ID.
- `NetworkRuntime::send` (`net_thread.rs`): Send a request to the background thread; returns `false` if the thread has exited.
- `NetworkRuntime::poll` (`net_thread.rs`): Drain all pending responses from the background thread without blocking.
- `NetworkRuntime::shutdown` (`net_thread.rs`): Send `Shutdown` to the background thread and block until it exits.
- `NetworkRuntime::is_running` (`net_thread.rs`): Return `true` if the background thread is still running.
- `NetworkRuntime::http_request` (`net_thread.rs`): Queue an HTTP request and return its correlation ID; returns error if the thread is not running.
- `NetworkRuntime::tcp_connect` (`net_thread.rs`): Open a TCP connection to `address` with a 5-second timeout; return its connection ID or error.
- `NetworkRuntime::tcp_send` (`net_thread.rs`): Send raw bytes over an existing TCP connection; returns error if the thread is not running.
- `NetworkRuntime::tcp_close` (`net_thread.rs`): Close an existing TCP connection; returns error if the thread is not running.
- `NetworkRuntime::ws_connect` (`net_thread.rs`): Open a WebSocket connection to `url`; return its connection ID or error.
- `NetworkRuntime::ws_send` (`net_thread.rs`): Send a UTF-8 text frame over an existing WebSocket connection.
- `NetworkRuntime::ws_close` (`net_thread.rs`): Send a normal close frame (1000) over an existing WebSocket connection.
- `encode_ticket` (`relay.rs`): Encode a `RelayTicket` as a `"room_id|peer_id"` string for wire transport.
- `decode_ticket` (`relay.rs`): Parse a `"room_id|peer_id"` token back into a `RelayTicket`; returns `None` if either part is empty.
- `make_punch_probe` (`relay.rs`): Build a UDP hole-punch probe payload for the given `peer_id`.
- `parse_punch_probe` (`relay.rs`): Parse a UDP hole-punch probe and return the embedded peer ID; returns `None` if the magic prefix is absent.
- `TcpConnectionManager::new` (`tcp.rs`): Create an empty connection manager.
- `TcpConnectionManager::connect` (`tcp.rs`): Connect to `address` with a `timeout_ms` deadline; posts `Connected` or `Error` to `resp_tx`.
- `TcpConnectionManager::send` (`tcp.rs`): Write `data` to the connection with the given `id`; posts `Error` and removes the connection on failure.
- `TcpConnectionManager::close` (`tcp.rs`): Remove and close the connection with the given `id`; posts `Disconnected` when found.
- `TcpConnectionManager::poll_all` (`tcp.rs`): Non-blocking poll of all connections in round-robin order; posts `Data`, `Disconnected`, or `Error` events.
- `TcpConnectionManager::close_all` (`tcp.rs`): Drop all active connections without posting events; called on shutdown.
- `TcpConnectionManager::is_empty` (`tcp.rs`): Return `true` when no connections are currently tracked.
- `WebSocketManager::new` (`websocket.rs`): Create an empty WebSocket manager with no connections.
- `WebSocketManager::is_empty` (`websocket.rs`): Return `true` when there are no established connections.
- `WebSocketManager::connect` (`websocket.rs`): Spawn a helper thread to perform the TLS/TCP WebSocket handshake to `url`; resolves via `poll_all`.
- `WebSocketManager::send` (`websocket.rs`): Send `data` as a text or binary WebSocket frame; posts `Error` to `resp_tx` if the connection is missing or fails.
- `WebSocketManager::close` (`websocket.rs`): Send a WebSocket close frame with `code` and `reason`, drain until the server close, then post `Close`.
- `WebSocketManager::poll_all` (`websocket.rs`): Non-blocking poll of pending connects and all live connections; posts events to `resp_tx`.
- `WebSocketManager::close_all` (`websocket.rs`): Drop all pending and live connections; called on network thread shutdown.

## Lua API Reference

- Binding path(s): `src/lua_api/network_api.rs`
- Namespace: `lurek.network`

### Module Functions
- `lurek.network.newHost`: Creates a network host from an options table.
- `lurek.network.newServer`: Creates a server host from an options table.
- `lurek.network.newClient`: Creates a client host and connects to an address.
- `lurek.network.newRuntime`: Creates a background network runtime.
- `lurek.network.pack`: Packs a supported Lua value into a binary network message string.
- `lurek.network.unpack`: Unpacks a binary network message string into Lua values.
- `lurek.network.createLobby`: Broadcasts lobby information and returns it as a table.
- `lurek.network.discoverLobbies`: Discovers broadcast lobbies.
- `lurek.network.createRoom`: Creates a local room record.
- `lurek.network.listRooms`: Lists known local room records.
- `lurek.network.joinRoom`: Joins a room by id when available.
- `lurek.network.leaveRoom`: Leaves a room by id when available.
- `lurek.network.syncEntity`: Broadcasts a packed entity sync payload through a network host.
- `lurek.network.newRelayTicket`: Creates an encoded relay ticket.
- `lurek.network.parseRelayTicket`: Parses an encoded relay ticket.
- `lurek.network.makePunchProbe`: Creates a relay punch probe payload for a peer id.
- `lurek.network.parsePunchProbe`: Parses a relay punch probe payload.
- `lurek.network.predictLinear`: Predicts an entity snapshot forward by linear velocity.
- `lurek.network.reconcileSnapshot`: Reconciles a predicted snapshot toward an authoritative snapshot.

### `LNetworkHost` Methods
- `LNetworkHost:service`: Polls the host for one network event.
- `LNetworkHost:connect`: Connects to a remote address.
- `LNetworkHost:send`: Sends bytes to a peer on a channel.
- `LNetworkHost:broadcast`: Broadcasts bytes to all connected peers on a channel.
- `LNetworkHost:flush`: Flushes queued outgoing network packets.
- `LNetworkHost:disconnect`: Requests a graceful peer disconnect.
- `LNetworkHost:disconnectNow`: Disconnects a peer immediately.
- `LNetworkHost:disconnectLater`: Schedules a peer disconnect after pending packets.
- `LNetworkHost:resetPeer`: Resets a peer connection.
- `LNetworkHost:ping`: Sends a ping to a peer.
- `LNetworkHost:getRoundTripTime`: Returns peer round trip time in milliseconds.
- `LNetworkHost:getPeerState`: Returns peer connection state.
- `LNetworkHost:getPeerAddress`: Returns peer socket address when available.
- `LNetworkHost:getAddress`: Returns local host socket address.
- `LNetworkHost:getPeerLimit`: Returns configured peer limit.
- `LNetworkHost:getChannelLimit`: Returns configured channel limit.
- `LNetworkHost:setChannelLimit`: Sets channel limit.
- `LNetworkHost:getBandwidthLimit`: Returns incoming and outgoing bandwidth limits.
- `LNetworkHost:setBandwidthLimit`: Sets incoming and outgoing bandwidth limits.
- `LNetworkHost:getConnectedPeerCount`: Returns connected peer count.
- `LNetworkHost:getConnectedPeerIds`: Returns ids for connected peers.
- `LNetworkHost:getPeerStats`: Returns statistics for a peer.
- `LNetworkHost:destroy`: Destroys the network host.
- `LNetworkHost:isDestroyed`: Returns whether the network host is destroyed.
- `LNetworkHost:getRole`: Returns host role string.
- `LNetworkHost:isServer`: Returns whether this host has server role.
- `LNetworkHost:isClient`: Returns whether this host has client role.
- `LNetworkHost:type`: Returns the Lua-visible type name for this network host handle.
- `LNetworkHost:typeOf`: Returns whether this network host handle matches a supported type name.

### `LNetworkRuntime` Methods
- `LNetworkRuntime:httpRequest`: Starts an HTTP request from an options table and returns its request id.
- `LNetworkRuntime:httpGet`: Starts an HTTP GET request.
- `LNetworkRuntime:httpPost`: Starts an HTTP POST request.
- `LNetworkRuntime:tcpConnect`: Opens a TCP connection.
- `LNetworkRuntime:tcpSend`: Sends bytes over a TCP connection.
- `LNetworkRuntime:tcpClose`: Closes a TCP connection.
- `LNetworkRuntime:wsConnect`: Opens a WebSocket connection.
- `LNetworkRuntime:wsSend`: Sends text over a WebSocket connection.
- `LNetworkRuntime:wsClose`: Closes a WebSocket connection.
- `LNetworkRuntime:poll`: Polls runtime responses for HTTP, TCP, and WebSocket operations.
- `LNetworkRuntime:shutdown`: Shuts down the network runtime.
- `LNetworkRuntime:type`: Returns the Lua-visible type name for this network runtime handle.
- `LNetworkRuntime:typeOf`: Returns whether this network runtime handle matches a supported type name.

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
