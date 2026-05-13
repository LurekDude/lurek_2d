use thiserror::Error;
#[derive(Debug, Error)]
pub enum NetworkError {
    #[error("peer count {requested} exceeds maximum of {max}")]
    PeerLimitExceeded { requested: usize, max: usize },
    #[error("network I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("ENet error: {0}")]
    Enet(String),
    #[error("host has been destroyed")]
    HostDestroyed,
    #[error("invalid peer index {0}")]
    InvalidPeer(usize),
    #[error("invalid bind address: {0}")]
    InvalidAddress(String),
    #[error("HTTP error: {0}")]
    Http(String),
    #[error("WebSocket error: {0}")]
    WebSocket(String),
    #[error("TCP error: {0}")]
    Tcp(String),
    #[error("serialization error: {0}")]
    Serialization(String),
    #[error("network thread error: {0}")]
    Thread(String),
}
