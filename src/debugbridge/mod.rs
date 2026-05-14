//! Group transport and shared state for the debug bridge JSON-RPC channel.
//! Keep server loop and shared buffers isolated from gameplay runtime code.
//! Do not implement editor protocol policy outside these bridge components.
//! Depend on TCP transport, serde JSON payloads, and synchronized state.

/// Expose shared bridge state and pending request or response buffers.
pub mod bridge;
/// Expose TCP server loop and JSON-RPC message dispatch handlers.
pub mod server;
/// Re-export shared bridge state and queue item types for integration code.
pub use bridge::{BridgeShared, PendingRequest, PendingResponse, PrintEntry, SharedBridge};
/// Re-export server entry points for network thread startup and message handling.
pub use server::{handle_client_message, server_thread};
