//! Shared numeric limits and protocol constants for the network subsystem.
//! All transport layers (TCP, WebSocket) and the lobby read from this file.
//! Does not own logic; change values here to tune network capacity globally.

/// Hard ceiling on simultaneous peer connections across all transports.
pub const MAX_PEERS: usize = 4096;
/// Default peer slot count used when the game does not specify a capacity.
pub const DEFAULT_PEERS: usize = 64;
/// Hard ceiling on logical channels per connection.
pub const MAX_CHANNELS: usize = 255;
/// Default channel count used when the game does not configure channels.
pub const DEFAULT_CHANNELS: usize = 2;
/// Seconds before an HTTP request is aborted with a timeout error.
pub const HTTP_TIMEOUT_SECS: u64 = 30;
/// Byte capacity of the read/write buffer for each TCP connection.
pub const TCP_BUFFER_SIZE: usize = 65536;
/// Byte capacity of the read/write buffer for each WebSocket connection.
pub const WS_BUFFER_SIZE: usize = 65536;
