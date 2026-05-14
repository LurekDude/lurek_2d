
use super::http;
use super::tcp::TcpConnectionManager;
use super::websocket::WebSocketManager;
use std::sync::mpsc;
use std::thread;
/// Commands sent from the game thread to the background network thread.
#[derive(Debug)]
pub enum NetworkRequest {
    /// Perform a blocking HTTP request and post a `NetworkResponse::HttpResponse` when done.
    HttpRequest {
        /// Caller-assigned correlation ID echoed back in the response.
        id: u64,
        /// HTTP method string (e.g. `"GET"`, `"POST"`).
        method: String,
        /// Target URL.
        url: String,
        /// Additional request headers.
        headers: Vec<(String, String)>,
        /// Optional request body bytes.
        body: Option<Vec<u8>>,
        /// Request timeout in seconds; `0` means no timeout.
        timeout_secs: u64,
    },
    /// Open a TCP connection identified by `id`.
    TcpConnect {
        /// Caller-assigned connection ID used in all subsequent TCP requests.
        id: u64,
        /// Remote address in `host:port` format.
        address: String,
        /// Connection timeout in milliseconds.
        timeout_ms: u64,
    },
    /// Send raw bytes over the TCP connection with the given `id`.
    TcpSend {
        /// Connection ID returned from `TcpConnect`.
        id: u64,
        /// Payload bytes to send.
        data: Vec<u8>,
    },
    /// Close the TCP connection with the given `id`.
    TcpClose {
        /// Connection ID to close.
        id: u64,
    },
    /// Open a WebSocket connection identified by `id`.
    WebSocketConnect {
        /// Caller-assigned connection ID used in all subsequent WebSocket requests.
        id: u64,
        /// WebSocket URL (`ws://` or `wss://`).
        url: String,
        /// Sub-protocol negotiation list; empty to skip negotiation.
        protocols: Vec<String>,
    },
    /// Send a frame over the WebSocket connection.
    WebSocketSend {
        /// Connection ID.
        id: u64,
        /// Frame payload bytes.
        data: Vec<u8>,
        /// `true` for a text frame, `false` for a binary frame.
        is_text: bool,
    },
    /// Close the WebSocket connection with the given `id`.
    WebSocketClose {
        /// Connection ID.
        id: u64,
        /// WebSocket close status code (e.g. `1000` for normal closure).
        code: u16,
        /// Human-readable close reason sent in the close frame.
        reason: String,
    },
    /// Signal the network thread to exit its event loop.
    Shutdown,
}
/// Responses posted from the background network thread back to the game thread.
#[derive(Debug)]
pub enum NetworkResponse {
    /// Completed HTTP response for the given correlation `id`.
    HttpResponse {
        /// Correlation ID matching the originating `NetworkRequest::HttpRequest`.
        id: u64,
        /// HTTP status code; `0` when the request failed before a response arrived.
        status: u16,
        /// Response body bytes.
        body: Vec<u8>,
        /// Response headers.
        headers: Vec<(String, String)>,
        /// Error message when the request failed; `None` on success.
        error: Option<String>,
    },
    /// Event from a TCP connection.
    TcpEvent {
        /// Connection ID.
        id: u64,
        /// The specific TCP lifecycle event.
        event: TcpEvent,
    },
    /// Event from a WebSocket connection.
    WebSocketEvent {
        /// Connection ID.
        id: u64,
        /// The specific WebSocket lifecycle event.
        event: WsEvent,
    },
}
/// Lifecycle events emitted by the TCP connection manager.
#[derive(Debug, Clone)]
pub enum TcpEvent {
    /// TCP handshake completed; the connection is ready to send.
    Connected,
    /// Data bytes arrived on the stream.
    Data(Vec<u8>),
    /// The remote end closed the connection; message gives the reason.
    Disconnected(String),
    /// A socket-level error occurred; message gives details.
    Error(String),
}
/// Lifecycle events emitted by the WebSocket manager.
#[derive(Debug, Clone)]
pub enum WsEvent {
    /// WebSocket handshake completed; the connection is open.
    Open,
    /// A UTF-8 text frame arrived.
    Text(String),
    /// A binary frame arrived.
    Binary(Vec<u8>),
    /// The connection was closed; `code` is the WebSocket status code.
    Close { code: u16, reason: String },
    /// A WebSocket protocol or I/O error occurred.
    Error(String),
}
/// Handle that owns the background `lurek-network` thread and MPSC channels.
pub struct NetworkRuntime {
    /// Sender end of the request channel to the background thread.
    sender: mpsc::Sender<NetworkRequest>,
    /// Receiver end of the response channel from the background thread.
    receiver: mpsc::Receiver<NetworkResponse>,
    /// Join handle for the background thread; `None` after `shutdown` completes.
    handle: Option<thread::JoinHandle<()>>,
    /// Monotonically increasing counter used to generate unique request IDs.
    next_id: u64,
}
impl NetworkRuntime {
    /// Spawn the background `lurek-network` thread and return the runtime handle; returns error on thread spawn failure.
    pub fn new() -> Result<Self, String> {
        let (req_tx, req_rx) = mpsc::channel::<NetworkRequest>();
        let (resp_tx, resp_rx) = mpsc::channel::<NetworkResponse>();
        let handle = thread::Builder::new()
            .name("lurek-network".to_string())
            .spawn(move || {
                Self::thread_main(req_rx, resp_tx);
            })
            .map_err(|e| format!("failed to spawn network thread: {e}"))?;
        Ok(Self {
            sender: req_tx,
            receiver: resp_rx,
            handle: Some(handle),
            next_id: 0,
        })
    }
    /// Allocate and return the next unique request ID.
    pub fn next_request_id(&mut self) -> u64 {
        self.next_id += 1;
        self.next_id
    }
    /// Send a request to the background thread; returns `false` if the thread has exited.
    pub fn send(&self, request: NetworkRequest) -> bool {
        self.sender.send(request).is_ok()
    }
    /// Drain all pending responses from the background thread without blocking.
    pub fn poll(&self) -> Vec<NetworkResponse> {
        let mut responses = Vec::new();
        while let Ok(resp) = self.receiver.try_recv() {
            responses.push(resp);
        }
        responses
    }
    /// Send `Shutdown` to the background thread and block until it exits.
    pub fn shutdown(&mut self) {
        if self.handle.is_some() {
            let _ = self.sender.send(NetworkRequest::Shutdown);
            if let Some(handle) = self.handle.take() {
                let _ = handle.join();
            }
        }
    }
    /// Return `true` if the background thread is still running.
    pub fn is_running(&self) -> bool {
        self.handle.is_some()
    }
    /// Queue an HTTP request and return its correlation ID; returns error if the thread is not running.
    pub fn http_request(
        &mut self,
        method: &str,
        url: &str,
        headers: Option<&[(String, String)]>,
        body: Option<&str>,
        timeout_secs: Option<u64>,
    ) -> Result<u64, String> {
        let id = self.next_request_id();
        let ok = self.send(NetworkRequest::HttpRequest {
            id,
            method: method.to_string(),
            url: url.to_string(),
            headers: headers.map(|h| h.to_vec()).unwrap_or_default(),
            body: body.map(|b| b.as_bytes().to_vec()),
            timeout_secs: timeout_secs.unwrap_or(super::constants::HTTP_TIMEOUT_SECS),
        });
        if ok {
            Ok(id)
        } else {
            Err("network thread not running".to_string())
        }
    }
    /// Open a TCP connection to `address` with a 5-second timeout; return its connection ID or error.
    pub fn tcp_connect(&mut self, address: &str) -> Result<u64, String> {
        let id = self.next_request_id();
        let ok = self.send(NetworkRequest::TcpConnect {
            id,
            address: address.to_string(),
            timeout_ms: 5000,
        });
        if ok {
            Ok(id)
        } else {
            Err("network thread not running".to_string())
        }
    }
    /// Send raw bytes over an existing TCP connection; returns error if the thread is not running.
    pub fn tcp_send(&mut self, id: u64, data: &[u8]) -> Result<(), String> {
        let ok = self.send(NetworkRequest::TcpSend {
            id,
            data: data.to_vec(),
        });
        if ok {
            Ok(())
        } else {
            Err("network thread not running".to_string())
        }
    }
    /// Close an existing TCP connection; returns error if the thread is not running.
    pub fn tcp_close(&mut self, id: u64) -> Result<(), String> {
        let ok = self.send(NetworkRequest::TcpClose { id });
        if ok {
            Ok(())
        } else {
            Err("network thread not running".to_string())
        }
    }
    /// Open a WebSocket connection to `url`; return its connection ID or error.
    pub fn ws_connect(&mut self, url: &str) -> Result<u64, String> {
        let id = self.next_request_id();
        let ok = self.send(NetworkRequest::WebSocketConnect {
            id,
            url: url.to_string(),
            protocols: Vec::new(),
        });
        if ok {
            Ok(id)
        } else {
            Err("network thread not running".to_string())
        }
    }
    /// Send a UTF-8 text frame over an existing WebSocket connection.
    pub fn ws_send(&mut self, id: u64, data: &str) -> Result<(), String> {
        let ok = self.send(NetworkRequest::WebSocketSend {
            id,
            data: data.as_bytes().to_vec(),
            is_text: true,
        });
        if ok {
            Ok(())
        } else {
            Err("network thread not running".to_string())
        }
    }
    /// Send a normal close frame (1000) over an existing WebSocket connection.
    pub fn ws_close(&mut self, id: u64) -> Result<(), String> {
        let ok = self.send(NetworkRequest::WebSocketClose {
            id,
            code: 1000,
            reason: String::new(),
        });
        if ok {
            Ok(())
        } else {
            Err("network thread not running".to_string())
        }
    }
    /// Background thread entry point: poll transports and dispatch requests until `Shutdown`.
    fn thread_main(req_rx: mpsc::Receiver<NetworkRequest>, resp_tx: mpsc::Sender<NetworkResponse>) {
        let mut tcp_manager = TcpConnectionManager::new();
        let mut ws_manager = WebSocketManager::new();
        loop {
            tcp_manager.poll_all(&resp_tx);
            ws_manager.poll_all(&resp_tx);
            match req_rx.recv_timeout(std::time::Duration::from_millis(10)) {
                Ok(NetworkRequest::Shutdown) => break,
                Ok(request) => {
                    Self::handle_request(request, &resp_tx, &mut tcp_manager, &mut ws_manager);
                }
                Err(mpsc::RecvTimeoutError::Timeout) => {}
                Err(mpsc::RecvTimeoutError::Disconnected) => break,
            }
        }
        tcp_manager.close_all();
        ws_manager.close_all();
    }
    /// Route one `NetworkRequest` to the appropriate transport manager.
    fn handle_request(
        request: NetworkRequest,
        resp_tx: &mpsc::Sender<NetworkResponse>,
        tcp_manager: &mut TcpConnectionManager,
        ws_manager: &mut WebSocketManager,
    ) {
        match request {
            NetworkRequest::HttpRequest {
                id,
                method,
                url,
                headers,
                body,
                timeout_secs,
            } => {
                let response =
                    http::execute_request(&method, &url, &headers, body.as_deref(), timeout_secs);
                let _ = resp_tx.send(NetworkResponse::HttpResponse {
                    id,
                    status: response.status,
                    body: response.body,
                    headers: response.headers,
                    error: response.error,
                });
            }
            NetworkRequest::TcpConnect {
                id,
                address,
                timeout_ms,
            } => {
                tcp_manager.connect(id, &address, timeout_ms, resp_tx);
            }
            NetworkRequest::TcpSend { id, data } => {
                tcp_manager.send(id, &data, resp_tx);
            }
            NetworkRequest::TcpClose { id } => {
                tcp_manager.close(id, resp_tx);
            }
            NetworkRequest::WebSocketConnect { id, url, protocols } => {
                ws_manager.connect(id, &url, &protocols, resp_tx);
            }
            NetworkRequest::WebSocketSend { id, data, is_text } => {
                ws_manager.send(id, &data, is_text, resp_tx);
            }
            NetworkRequest::WebSocketClose { id, code, reason } => {
                ws_manager.close(id, code, &reason, resp_tx);
            }
            NetworkRequest::Shutdown => {}
        }
    }
}
/// Create a `NetworkRuntime`, panicking on thread spawn failure.
impl Default for NetworkRuntime {
    fn default() -> Self {
        Self::new().expect("failed to spawn network thread")
    }
}
/// Shut down the network thread when the runtime is dropped.
impl Drop for NetworkRuntime {
    fn drop(&mut self) {
        self.shutdown();
    }
}
