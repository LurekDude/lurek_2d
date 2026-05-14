
use thiserror::Error;

/// All error conditions that can occur in the network subsystem.
#[derive(Debug, Error)]
pub enum NetworkError {
    /// Caller requested more peer slots than `MAX_PEERS` allows.
    #[error("peer count {requested} exceeds maximum of {max}")]
    PeerLimitExceeded { requested: usize, max: usize },
    /// Underlying OS I/O failure on a socket or file descriptor.
    #[error("network I/O error: {0}")]
    Io(#[from] std::io::Error),
    /// ENet library reported an error; message is the ENet error string.
    #[error("ENet error: {0}")]
    Enet(String),
    /// Operation attempted after the host was dropped or shut down.
    #[error("host has been destroyed")]
    HostDestroyed,
    /// Peer slot index is out of range for the current host capacity.
    #[error("invalid peer index {0}")]
    InvalidPeer(usize),
    /// Bind address string could not be parsed into a socket address.
    #[error("invalid bind address: {0}")]
    InvalidAddress(String),
    /// HTTP request or response processing failed; message includes status or reason.
    #[error("HTTP error: {0}")]
    Http(String),
    /// WebSocket handshake or frame processing failed.
    #[error("WebSocket error: {0}")]
    WebSocket(String),
    /// TCP stream read or write failed at the protocol level.
    #[error("TCP error: {0}")]
    Tcp(String),
    /// Message encode or decode failed during framing.
    #[error("serialization error: {0}")]
    Serialization(String),
    /// Background network thread reported a fatal error or panicked.
    #[error("network thread error: {0}")]
    Thread(String),
}
