//! Compile-time limits and defaults for the networking subsystem.
//!
//! All values are `pub const` and used by both the Rust domain layer
//! (`src/network/`) and the Lua binding layer (`src/lua_api/network_api.rs`).

/// Maximum number of simultaneous peer connections a single host supports.
///
/// Lurek2D supports up to 4096 peers for dedicated server scenarios.
/// The recommended default for new hosts is 16; most LAN games use fewer.
pub const MAX_PEERS: usize = 4096;

/// Default number of peers when no explicit value is provided.
pub const DEFAULT_PEERS: usize = 64;

/// Maximum number of independent ENet channels per connection.
///
/// ENet supports up to 255 channels. Lurek2D defaults to a more modest
/// ceiling to keep memory usage predictable on integrated GPUs.
pub const MAX_CHANNELS: usize = 255;

/// Default channel count for new connections when none is specified.
pub const DEFAULT_CHANNELS: usize = 2;

/// Default HTTP request timeout in seconds.
///
/// Applied when no explicit timeout is provided to `lurek.network.httpGet()`
/// and related functions. Zero means no timeout.
pub const HTTP_TIMEOUT_SECS: u64 = 30;

/// Read buffer size for TCP connections in bytes.
///
/// Each non-blocking read on a TCP socket attempts to fill a buffer of
/// this size. 64 KiB is generous for game-protocol messages.
pub const TCP_BUFFER_SIZE: usize = 65536;

/// Read buffer size for WebSocket connections in bytes.
///
/// Used internally by the WebSocket polling loop.
pub const WS_BUFFER_SIZE: usize = 65536;
