use super::net_thread::{NetworkResponse, TcpEvent};
use log::{debug, warn};
use std::collections::HashMap;
use std::io::{self, Read, Write};
use std::net::TcpStream;
use std::sync::mpsc;
use std::time::Duration;
pub struct TcpConnectionManager {
    connections: HashMap<u64, TcpStream>,
    poll_cursor: usize,
}
impl TcpConnectionManager {
    pub fn new() -> Self {
        Self {
            connections: HashMap::new(),
            poll_cursor: 0,
        }
    }
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
    pub fn close(&mut self, id: u64, resp_tx: &mpsc::Sender<NetworkResponse>) {
        if self.connections.remove(&id).is_some() {
            let _ = resp_tx.send(NetworkResponse::TcpEvent {
                id,
                event: TcpEvent::Disconnected("closed by local".to_string()),
            });
        }
    }
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
    pub fn close_all(&mut self) {
        self.connections.clear();
    }
    pub fn is_empty(&self) -> bool {
        self.connections.is_empty()
    }
}
impl Default for TcpConnectionManager {
    fn default() -> Self {
        Self::new()
    }
}
