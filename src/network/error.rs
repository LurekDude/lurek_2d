//! Network-specific error types.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use thiserror::Error;

/// Errors produced by the networking subsystem.
///
/// # Variants
/// - `PeerLimitExceeded` — The requested peer count exceeds `MAX_PEERS`.
/// - `Io` — A socket-level I/O error occurred.
/// - `Enet` — An ENet-internal error surfaced from `rusty_enet`.
/// - `HostDestroyed` — The host has already been destroyed; further calls are invalid.
/// - `InvalidPeer` — The addressed peer index is out of range.
/// - `InvalidAddress` — Failed to parse a bind address string.
#[derive(Debug, Error)]
pub enum NetworkError {
    /// The requested peer count exceeds [`super::constants::MAX_PEERS`].
    #[error("peer count {requested} exceeds maximum of {max}")]
    PeerLimitExceeded {
        /// The value the caller asked for.
        requested: usize,
        /// The hard-coded ceiling.
        max: usize,
    },

    /// A socket-level I/O error occurred.
    #[error("network I/O error: {0}")]
    Io(#[from] std::io::Error),

    /// An ENet-internal error surfaced from `rusty_enet`.
    #[error("ENet error: {0}")]
    Enet(String),

    /// The host has already been destroyed; further calls are invalid.
    #[error("host has been destroyed")]
    HostDestroyed,

    /// The addressed peer index is out of range.
    #[error("invalid peer index {0}")]
    InvalidPeer(usize),

    /// Failed to parse a bind address string (expected `"*:port"` or `"host:port"`).
    #[error("invalid bind address: {0}")]
    InvalidAddress(String),
}
