
use super::net_thread::{NetworkResponse, WsEvent};
use log::{debug, warn};
use std::collections::HashMap;
use std::net::TcpStream;
use std::sync::mpsc;
use std::thread;
use tungstenite::protocol::Message;
use tungstenite::stream::MaybeTlsStream;
use tungstenite::WebSocket;
/// Pool of active WebSocket connections and in-flight connect operations.
pub struct WebSocketManager {
    /// Established WebSocket connections keyed by caller-assigned ID.
    connections: HashMap<u64, WebSocket<MaybeTlsStream<TcpStream>>>,
    /// Connections whose background connect thread has not yet resolved.
    pending_connects: Vec<PendingConnect>,
}
/// In-flight WebSocket handshake spawned on a helper thread.
struct PendingConnect {
    /// Caller-assigned connection ID.
    id: u64,
    /// Channel that receives the completed socket or an error string.
    rx: mpsc::Receiver<Result<WebSocket<MaybeTlsStream<TcpStream>>, String>>,
}
impl WebSocketManager {
    /// Create an empty WebSocket manager with no connections.
    pub fn new() -> Self {
        Self {
            connections: HashMap::new(),
            pending_connects: Vec::new(),
        }
    }
    /// Return `true` when there are no established connections.
    pub fn is_empty(&self) -> bool {
        self.connections.is_empty()
    }
    /// Spawn a helper thread to perform the TLS/TCP WebSocket handshake to `url`; resolves via `poll_all`.
    pub fn connect(
        &mut self,
        id: u64,
        url: &str,
        _protocols: &[String],
        _resp_tx: &mpsc::Sender<NetworkResponse>,
    ) {
        debug!("WebSocket connecting to {}", url);
        let url_s = url.to_string();
        let (tx, rx) = mpsc::channel();
        thread::Builder::new()
            .name(format!("lurek-ws-connect-{id}"))
            .spawn(move || {
                let result = match tungstenite::connect(&url_s) {
                    Ok((socket, _)) => Ok(socket),
                    Err(e) => Err(format!("connect error: {e}")),
                };
                let _ = tx.send(result);
            })
            .ok();
        self.pending_connects.push(PendingConnect { id, rx });
    }
    /// Send `data` as a text or binary WebSocket frame; posts `Error` to `resp_tx` if the connection is missing or fails.
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
    /// Send a WebSocket close frame with `code` and `reason`, drain until the server close, then post `Close`.
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
    /// Non-blocking poll of pending connects and all live connections; posts events to `resp_tx`.
    pub fn poll_all(&mut self, resp_tx: &mpsc::Sender<NetworkResponse>) {
        self.poll_pending_connects(resp_tx);
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
                Ok(Message::Ping(_)) | Ok(Message::Pong(_)) | Ok(Message::Frame(_)) => {}
                Err(tungstenite::Error::Io(ref e))
                    if e.kind() == std::io::ErrorKind::WouldBlock => {}
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
    /// Check each pending connect for completion; move resolved sockets into `connections`.
    fn poll_pending_connects(&mut self, resp_tx: &mpsc::Sender<NetworkResponse>) {
        let mut retained = Vec::with_capacity(self.pending_connects.len());
        for pending in self.pending_connects.drain(..) {
            match pending.rx.try_recv() {
                Ok(Ok(socket)) => {
                    if let MaybeTlsStream::Plain(ref tcp) = socket.get_ref() {
                        let _ = tcp.set_nonblocking(true);
                    }
                    self.connections.insert(pending.id, socket);
                    let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                        id: pending.id,
                        event: WsEvent::Open,
                    });
                }
                Ok(Err(err)) => {
                    warn!("WebSocket connect error on {}: {}", pending.id, err);
                    let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                        id: pending.id,
                        event: WsEvent::Error(err),
                    });
                }
                Err(mpsc::TryRecvError::Empty) => retained.push(pending),
                Err(mpsc::TryRecvError::Disconnected) => {
                    let _ = resp_tx.send(NetworkResponse::WebSocketEvent {
                        id: pending.id,
                        event: WsEvent::Error("connect worker disconnected".to_string()),
                    });
                }
            }
        }
        self.pending_connects = retained;
    }
    /// Drop all pending and live connections; called on network thread shutdown.
    pub fn close_all(&mut self) {
        self.pending_connects.clear();
        for (_, mut socket) in self.connections.drain() {
            let _ = socket.close(None);
        }
    }
}
/// Create an empty `WebSocketManager`.
impl Default for WebSocketManager {
    fn default() -> Self {
        Self::new()
    }
}
