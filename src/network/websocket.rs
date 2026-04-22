//! WebSocket client connections managed on the network thread.
//!
//! Uses the `tungstenite` crate for RFC 6455 compliant WebSocket
//! communication. Each connection is identified by a `u64` ID assigned
//! by the [`NetworkRuntime`](super::net_thread::NetworkRuntime).
//!
//! # Architecture
//!
//! WebSocket connections use `tungstenite::WebSocket<MaybeTlsStream<TcpStream>>`
//! in non-blocking mode. The network thread polls each socket for incoming
//! frames and sends events to the main thread via `mpsc`.
//!
//! # TLS
//!
//! HTTPS (`wss://`) connections use the `rustls` TLS backend via
//! tungstenite's native-tls integration.

use std::collections::HashMap;
use std::net::TcpStream;
use std::sync::mpsc;

use log::{debug, warn};
use tungstenite::protocol::Message;
use tungstenite::stream::MaybeTlsStream;
use tungstenite::WebSocket;

use super::net_thread::{NetworkResponse, WsEvent};

/// Manages multiple WebSocket connections on the network thread.
///
/// # Fields
/// - `connections` — Map of connection ID → WebSocket stream.
pub struct WebSocketManager {
    /// Active WebSocket connections indexed by their unique ID.
    connections: HashMap<u64, WebSocket<MaybeTlsStream<TcpStream>>>,
}

impl WebSocketManager {
    /// Create a new empty WebSocket manager.
    ///
    /// # Returns
    /// `WebSocketManager`.
    pub fn new() -> Self {
        Self {
            connections: HashMap::new(),
        }
    }

    /// Returns `true` if there are no active WebSocket connections.
    pub fn is_empty(&self) -> bool {
        self.connections.is_empty()
    }

    /// Open a new WebSocket connection.
    ///
    /// Sends a `WsEvent::Open` on success or `WsEvent::Error` on failure.
    ///
    /// # Parameters
    /// - `id` — Unique connection identifier.
    /// - `url` — WebSocket URL (`ws://` or `wss://`).
    /// - `_protocols` — Optional sub-protocol names (reserved for future use).
    /// - `resp_tx` — Channel for sending events to the main thread.
    pub fn connect(
        &mut self,
        id: u64,
        url: &str,
        _protocols: &[String],
        resp_tx: &mpsc::Sender<NetworkResponse>,
    ) {
        debug!("WebSocket connecting to {}", url);

        match tungstenite::connect(url) {
            Ok((socket, _response)) => {
                // Set the underlying TCP stream to non-blocking
                if let MaybeTlsStream::Plain(ref tcp) = socket.get_ref() {
                    let _ = tcp.set_nonblocking(true);
                }
                self.connections.insert(id, socket);
                let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                    id,
                    event: WsEvent::Open,
                });
            }
            Err(e) => {
                warn!("WebSocket connect error to {}: {}", url, e);
                let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                    id,
                    event: WsEvent::Error(format!("connect error: {e}")),
                });
            }
        }
    }

    /// Send data on an existing WebSocket connection.
    ///
    /// # Parameters
    /// - `id` — Connection identifier.
    /// - `data` — Data bytes to send.
    /// - `is_text` — `true` to send as text frame, `false` for binary.
    /// - `resp_tx` — Channel for sending error events.
    pub fn send(
        &mut self,
        id: u64,
        data: &[u8],
        is_text: bool,
        resp_tx: &mpsc::Sender<NetworkResponse>,
    ) {
        if let Some(socket) = self.connections.get_mut(&id) {
            let message = if is_text {
                Message::Text(String::from_utf8_lossy(data).into_owned().into())
            } else {
                Message::Binary(data.to_vec().into())
            };

            if let Err(e) = socket.send(message) {
                warn!("WebSocket send error on connection {}: {}", id, e);
                let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                    id,
                    event: WsEvent::Error(format!("send error: {e}")),
                });
            }
        } else {
            let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                id,
                event: WsEvent::Error("connection not found".to_string()),
            });
        }
    }

    /// Close a WebSocket connection with a close frame.
    ///
    /// # Parameters
    /// - `id` — Connection identifier.
    /// - `code` — WebSocket close code (e.g. 1000 for normal closure).
    /// - `reason` — Close reason string.
    /// - `resp_tx` — Channel for sending the close event.
    pub fn close(
        &mut self,
        id: u64,
        code: u16,
        reason: &str,
        resp_tx: &mpsc::Sender<NetworkResponse>,
    ) {
        if let Some(mut socket) = self.connections.remove(&id) {
            let close_frame = tungstenite::protocol::CloseFrame {
                code: tungstenite::protocol::frame::coding::CloseCode::from(code),
                reason: reason.to_string().into(),
            };
            let _ = socket.close(Some(close_frame));
            // Drain any remaining messages to complete the close handshake
            while let Ok(msg) = socket.read() {
                if matches!(msg, Message::Close(_)) {
                    break;
                }
            }
            let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                id,
                event: WsEvent::Close {
                    code,
                    reason: reason.to_string(),
                },
            });
        }
    }

    /// Poll all active WebSocket connections for incoming messages.
    ///
    /// Called once per network thread iteration. Non-blocking reads on each
    /// socket; sends `WsEvent::Text`, `WsEvent::Binary`, or `WsEvent::Close`.
    ///
    /// # Parameters
    /// - `resp_tx` — Channel for sending events to the main thread.
    pub fn poll_all(&mut self, resp_tx: &mpsc::Sender<NetworkResponse>) {
        let mut to_remove = Vec::new();

        for (&id, socket) in self.connections.iter_mut() {
            match socket.read() {
                Ok(Message::Text(text)) => {
                    let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                        id,
                        event: WsEvent::Text(text.to_string()),
                    });
                }
                Ok(Message::Binary(data)) => {
                    let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                        id,
                        event: WsEvent::Binary(data.to_vec()),
                    });
                }
                Ok(Message::Close(frame)) => {
                    let (code, reason) = frame
                        .map(|f| (f.code.into(), f.reason.to_string()))
                        .unwrap_or((1000, String::new()));
                    let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                        id,
                        event: WsEvent::Close { code, reason },
                    });
                    to_remove.push(id);
                }
                Ok(Message::Ping(_)) | Ok(Message::Pong(_)) | Ok(Message::Frame(_)) => {
                    // Handled automatically by tungstenite
                }
                Err(tungstenite::Error::Io(ref e))
                    if e.kind() == std::io::ErrorKind::WouldBlock =>
                {
                    // No data available, that's fine for non-blocking
                }
                Err(e) => {
                    let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                        id,
                        event: WsEvent::Error(format!("read error: {e}")),
                    });
                    to_remove.push(id);
                }
            }
        }

        for id in to_remove {
            self.connections.remove(&id);
        }
    }

    /// Close all active WebSocket connections.
    ///
    /// Called during network thread shutdown.
    pub fn close_all(&mut self) {
        for (_, mut socket) in self.connections.drain() {
            let _ = socket.close(None);
        }
    }
}

impl Default for WebSocketManager {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_manager_has_no_connections() {
        let mgr = WebSocketManager::new();
        assert!(mgr.connections.is_empty());
    }

    #[test]
    fn default_matches_new() {
        let mgr = WebSocketManager::default();
        assert!(mgr.connections.is_empty());
    }

    #[test]
    fn close_all_on_empty_is_noop() {
        let mut mgr = WebSocketManager::new();
        mgr.close_all();
        assert!(mgr.connections.is_empty());
    }

    #[test]
    fn send_to_nonexistent_sends_error() {
        let mut mgr = WebSocketManager::new();
        let (tx, rx) = mpsc::channel();
        mgr.send(77, b"msg", true, &tx);
        let resp = rx.try_recv().unwrap();
        if let NetworkResponse::WebSocketEvent { id, event } = resp {
            assert_eq!(id, 77);
            match event {
                WsEvent::Error(msg) => assert!(msg.contains("not found")),
                other => panic!("expected Error, got {:?}", other),
            }
        } else {
            panic!("expected WebSocketEvent");
        }
    }
}
