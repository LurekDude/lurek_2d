//! Network subsystem — TCP, WebSocket, HTTP, lobby, relay, and game-state sync.
//! Owns all outbound and inbound socket lifecycle, message framing, and peer management.
//! Does not own Lua bindings (those live in `src/lua_api/network_api.rs`) or save state.
//! Key dependencies: `tokio` runtime on the net thread, `message` framing, `error` types.

/// Shared numeric limits and protocol constants used across all network layers.
pub mod constants;
/// `NetworkError` type covering socket, protocol, and framing failures.
pub mod error;
/// Host-side peer management: accept loop, peer registry, and disconnect handling.
pub mod host;
/// Blocking HTTP GET/POST helpers used for matchmaking and asset fetching.
pub mod http;
/// Lobby state machine: room creation, join, leave, and member list tracking.
pub mod lobby;
/// `NetMessage` enum and binary framing used on every transport.
pub mod message;
/// Game-state snapshot diffing and reliable sync packets sent between peers.
pub mod net_sync;
/// Background Tokio thread that owns the async socket runtime; started at engine init.
pub mod net_thread;
/// Relay server client: punch-through, forwarding, and relay session lifecycle.
pub mod relay;
/// Raw TCP transport: connect, send, receive, and graceful close.
pub mod tcp;
/// WebSocket transport wrapping `tungstenite`; mirrors the TCP interface.
pub mod websocket;
