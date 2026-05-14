//! Non-blocking TCP connection manager for the background network thread.
//! Owns a map of live `TcpStream` connections keyed by caller-assigned ID.
//! Does not own the event loop or thread; called by `net_thread::NetworkRuntime::thread_main`.
//! Key dependencies: `TcpStream` from std, `net_thread::{NetworkResponse, TcpEvent}`.

use super::net_thread::{NetworkResponse, TcpEvent};
use log::{debug, warn};
use std::collections::HashMap;
use std::io::{self, Read, Write};
use std::net::TcpStream;
use std::sync::mpsc;
use std::time::Duration;
/// Pool of non-blocking TCP streams managed by the background network thread.
pub struct TcpConnectionManager {
    /// Active streams keyed by the caller-assigned connection ID.
    connections: HashMap<u64, TcpStream>,
    /// Round-robin cursor used to spread `poll_all` reads across connections.
    poll_cursor: usize,
}
impl TcpConnectionManager {
    /// Create an empty connection manager.
    pub fn new() -> Self {
        Self {
            connections: HashMap::new(),
            poll_cursor: 0,
        }
    }
    /// Connect to `address` with a `timeout_ms` deadline; posts `Connected` or `Error` to `resp_tx`.
    pub fn connect(
        &mut self,
        id: u64,
        address: &str,
        timeout_ms: u64,
        resp_tx: &mpsc::Sender<NetworkResponse>,
    ) {
        debug!("TCP connecting to {}", address);
        let timeout = if timeout_ms > 0 {
            Duration::from_millis(timeout_ms)
        } else {
            Duration::from_secs(5)
        };
        match address.parse::<std::net::SocketAddr>() {
            Ok(addr) => match TcpStream::connect_timeout(&addr, timeout) {
                Ok(stream) => {
                    if let Err(e) = stream.set_nonblocking(true) {
                        warn!("TCP failed to set non-blocking: {}", e);
                        let _ = resp_tx.send(NetworkResponse::TcpEvent {
                            id,
                            event: TcpEvent::Error(format!("failed to set non-blocking: {e}")),
                        });
                        return;
                    }
                    self.connections.insert(id, stream);
                    let _ = resp_tx.send(NetworkResponse::TcpEvent {
                        id,
                        event: TcpEvent::Connected,
                    });
                }
                Err(e) => {
                    warn!("TCP connect error to {}: {}", address, e);
                    let _ = resp_tx.send(NetworkResponse::TcpEvent {
                        id,
                        event: TcpEvent::Error(format!("connect error: {e}")),
                    });
                }
            },
            Err(e) => match std::net::ToSocketAddrs::to_socket_addrs(&address) {
                Ok(mut addrs) => {
                    if let Some(addr) = addrs.next() {
                        match TcpStream::connect_timeout(&addr, timeout) {
                            Ok(stream) => {
                                if let Err(e) = stream.set_nonblocking(true) {
                                    let _ = resp_tx.send(NetworkResponse::TcpEvent {
                                        id,
                                        event: TcpEvent::Error(format!(
                                            "failed to set non-blocking: {e}"
                                        )),
                                    });
                                    return;
                                }
                                self.connections.insert(id, stream);
                                let _ = resp_tx.send(NetworkResponse::TcpEvent {
                                    id,
                                    event: TcpEvent::Connected,
                                });
                            }
                            Err(e) => {
                                let _ = resp_tx.send(NetworkResponse::TcpEvent {
                                    id,
                                    event: TcpEvent::Error(format!("connect error: {e}")),
                                });
                            }
                        }
                    } else {
                        let _ = resp_tx.send(NetworkResponse::TcpEvent {
                            id,
                            event: TcpEvent::Error(format!("no addresses found for: {address}")),
                        });
                    }
                }
                Err(_) => {
                    let _ = resp_tx.send(NetworkResponse::TcpEvent {
                        id,
                        event: TcpEvent::Error(format!("invalid address: {e}")),
                    });
                }
            },
        }
    }
    /// Write `data` to the connection with the given `id`; posts `Error` and removes the connection on failure.
    pub fn send(&mut self, id: u64, data: &[u8], resp_tx: &mpsc::Sender<NetworkResponse>) {
        if let Some(stream) = self.connections.get_mut(&id) {
            if let Err(e) = stream.write_all(data) {
                warn!("TCP send error on connection {}: {}", id, e);
                let _ = resp_tx.send(NetworkResponse::TcpEvent {
                    id,
                    event: TcpEvent::Error(format!("send error: {e}")),
                });
                self.connections.remove(&id);
            }
        } else {
            let _ = resp_tx.send(NetworkResponse::TcpEvent {
                id,
                event: TcpEvent::Error("connection not found".to_string()),
            });
        }
    }
    /// Remove and close the connection with the given `id`; posts `Disconnected` when found.
    pub fn close(&mut self, id: u64, resp_tx: &mpsc::Sender<NetworkResponse>) {
        if self.connections.remove(&id).is_some() {
            let _ = resp_tx.send(NetworkResponse::TcpEvent {
                id,
                event: TcpEvent::Disconnected("closed by local".to_string()),
            });
        }
    }
    /// Non-blocking poll of all connections in round-robin order; posts `Data`, `Disconnected`, or `Error` events.
    pub fn poll_all(&mut self, resp_tx: &mpsc::Sender<NetworkResponse>) {
        let mut to_remove = Vec::new();
        let mut ids: Vec<u64> = self.connections.keys().copied().collect();
        if ids.is_empty() {
            return;
        }
        ids.sort_unstable();
        let start = self.poll_cursor % ids.len();
        ids.rotate_left(start);
        self.poll_cursor = (self.poll_cursor + 1) % ids.len().max(1);
        for id in ids {
            let Some(stream) = self.connections.get_mut(&id) else {
                continue;
            };
            let mut buf = [0u8; super::constants::TCP_BUFFER_SIZE];
            match stream.read(&mut buf) {
                Ok(0) => {
                    let _ = resp_tx.send(NetworkResponse::TcpEvent {
                        id,
                        event: TcpEvent::Disconnected("closed by remote".to_string()),
                    });
                    to_remove.push(id);
                }
                Ok(n) => {
                    let _ = resp_tx.send(NetworkResponse::TcpEvent {
                        id,
                        event: TcpEvent::Data(buf[..n].to_vec()),
                    });
                }
                Err(ref e) if e.kind() == io::ErrorKind::WouldBlock => {}
                Err(e) => {
                    let _ = resp_tx.send(NetworkResponse::TcpEvent {
                        id,
                        event: TcpEvent::Error(format!("read error: {e}")),
                    });
                    to_remove.push(id);
                }
            }
        }
        for id in to_remove {
            self.connections.remove(&id);
        }
    }
    /// Drop all active connections without posting events; called on shutdown.
    pub fn close_all(&mut self) {
        self.connections.clear();
    }
    /// Return `true` when no connections are currently tracked.
    pub fn is_empty(&self) -> bool {
        self.connections.is_empty()
    }
}
/// Create an empty `TcpConnectionManager`.
impl Default for TcpConnectionManager {
    fn default() -> Self {
        Self::new()
    }
}
