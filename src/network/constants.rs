//! Compile-time limits and defaults for the networking subsystem.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Maximum number of simultaneous peer connections a single host supports.
///
/// Luna2D targets small-scale multiplayer (LAN party, co-op). The engine
/// hard-caps at 8 peers; the recommended default for new hosts is 4.
pub const MAX_PEERS: usize = 8;

/// Default number of peers when no explicit value is provided.
pub const DEFAULT_PEERS: usize = 4;

/// Maximum number of independent ENet channels per connection.
///
/// ENet supports up to 255 channels. Luna2D defaults to a more modest
/// ceiling to keep memory usage predictable on integrated GPUs.
pub const MAX_CHANNELS: usize = 255;

/// Default channel count for new connections when none is specified.
pub const DEFAULT_CHANNELS: usize = 1;
