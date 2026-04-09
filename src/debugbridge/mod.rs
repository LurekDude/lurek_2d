//! TCP debug bridge for connecting external tools to a running Lurek2D game.
//!
//! Exposes a JSON-over-TCP server (127.0.0.1 only) that external tools such as
//! the VS Code extension and MCP server can connect to for runtime inspection
//! and control.  Network I/O runs on a background thread; methods that require
//! Lua access are queued for dispatch on the main thread via `poll()`.
//!
//! # Sub-modules
//! | Module | Purpose |
//! |---|---|
//! | [`bridge`] | [`BridgeShared`] and related data types |
//! | [`server`] | TCP accept loop and client message dispatch |

pub mod bridge;
pub mod server;

pub use bridge::{BridgeShared, PendingRequest, PendingResponse, PrintEntry, SharedBridge};
pub use server::{handle_client_message, server_thread};
