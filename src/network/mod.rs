//! Game networking toolkit — ENet UDP, TCP, HTTP, WebSocket, and MessagePack.
//!
//! This module provides a layered networking API for multiplayer games:
//!
//! - **Layer 1 — Transport**: ENet reliable UDP ([`host`]), raw TCP ([`tcp`]),
//!   async HTTP ([`http`]), and WebSocket ([`websocket`]) clients.
//! - **Layer 2 — Serialization**: Compact binary message format via
//!   MessagePack ([`message`]) for efficient network transport.
//! - **Layer 3 — Threading**: A dedicated network I/O thread ([`net_thread`])
//!   with `mpsc` bridge keeps transport non-blocking for the Lua VM.
//!
//! ENet hosts act as both server and client endpoints simultaneously:
//! binding to a port enables incoming connections, while connecting to a
//! remote address creates outgoing ones. The single `service(timeout)`
//! event pump drives all UDP I/O.
//!
//! HTTP, TCP, and WebSocket operations run on the [`NetworkRuntime`](net_thread::NetworkRuntime)
//! background thread. The main engine thread polls completed responses
//! once per frame, before `lurek.process(dt)` fires.
//!
//! # Architecture
//!
//! - **Core Runtime** tier — no Platform Services or Feature Systems deps.
//! - [`host`] — `NetworkHost` wrapper around `rusty_enet::Host<UdpSocket>`.
//! - [`http`] — Async HTTP client via `ureq` on the network thread.
//! - [`tcp`] — Non-blocking TCP connections on the network thread.
//! - [`websocket`] — WebSocket client via `tungstenite` on the network thread.
//! - [`message`] — MessagePack serialization (Lua table ↔ compact binary).
//! - [`net_thread`] — Dedicated I/O thread with `mpsc` request/response channels.
//! - [`error`] — `NetworkError` enum covering all transport types.
//! - [`constants`] — Compile-time limits and defaults.

/// Compile-time limits and defaults for the networking subsystem.
pub mod constants;

/// Network-specific error types.
pub mod error;

/// ENet host wrapper.
pub mod host;

/// HTTP client for async web requests on the network thread.
pub mod http;

/// Binary message serialization via MessagePack.
pub mod message;

/// Dedicated network I/O thread with mpsc bridge to the main engine thread.
pub mod net_thread;

/// Non-blocking TCP client connections managed on the network thread.
pub mod tcp;

/// WebSocket client connections managed on the network thread.
pub mod websockesocket`] — WebSocket client via `tungstenite` on the network thread.
//! - [`message`] — MessagePack serialization (Lua table ↔ compact binary).
//! - [`net_thread`] — Dedicated I/O thread with `mpsc` request/response channels.
//! - [`error`] — `NetworkError` enum covering all transport types.
//! - [`constants`] — Compile-time limits and defaults.

/// Compile-time limits and defaults for the networking subsystem.
pub mod constants;

/// Network-specific error types.
pub mod error;

/// ENet host wrapper.
pub mod host;

/// HTTP client for async web requests on the network thread.
pub mod http;

/// Binary message serialization via MessagePack.
pub mod message;

/// Dedicated network I/O thread with mpsc bridge to the main engine thread.
pub mod net_thread;

/// Non-blocking TCP client connections managed on the network thread.
pub mod tcp;

/// WebSocket client connections managed on the network thread.
pub mod websocket;

/// LAN lobby broadcast and discovery via UDP.
pub mod lobby;
