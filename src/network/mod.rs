//! UDP networking via ENet — reliable packet transport for multiplayer games.
//!
//! This module wraps the [`rusty_enet`] crate to provide both a high-level
//! `lurek.network` API (options tables, event tables, camelCase) and a raw
//! `lurek.net` / `enet` API (direct ENet signatures, underscore naming,
//! multi-value returns).
//!
//! An ENet host acts as both server and client endpoint simultaneously:
//! binding to a port enables incoming connections, while connecting to a
//! remote address creates outgoing ones. The single `service(timeout)`
//! event pump drives all I/O.
//!
//! # Architecture
//!
//! - **Tier 1** module — depends only on Baseline (`math`, `engine`).
//! - [`host`] — `NetworkHost` wrapper around `rusty_enet::Host<UdpSocket>`.
//! - [`error`] — `NetworkError` enum for Lua-friendly error messages.
//! - [`constants`] — Compile-time limits (`MAX_PEERS`, `MAX_CHANNELS`).

/// Compile-time limits and defaults for the networking subsystem.
pub mod constants;

/// Network-specific error types.
pub mod error;

/// ENet host wrapper.
pub mod host;
