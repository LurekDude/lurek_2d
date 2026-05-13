use super::http;
use super::tcp::TcpConnectionManager;
use super::websocket::WebSocketManager;
use std::sync::mpsc;
use std::thread;
#[derive(Debug)]
pub enum NetworkRequest {
    HttpRequest {
        id: u64,
        method: String,
        url: String,
        headers: Vec<(String, String)>,
        body: Option<Vec<u8>>,
        timeout_secs: u64,
    },
    TcpConnect {
        id: u64,
        address: String,
        timeout_ms: u64,
    },
    TcpSend {
        id: u64,
        data: Vec<u8>,
    },
    TcpClose {
        id: u64,
    },
    WebSocketConnect {
        id: u64,
        url: String,
        protocols: Vec<String>,
    },
    WebSocketSend {
        id: u64,
        data: Vec<u8>,
        is_text: bool,
    },
    WebSocketClose {
        id: u64,
        code: u16,
        reason: String,
    },
    Shutdown,
}
#[derive(Debug)]
pub enum NetworkResponse {
    HttpResponse {
        id: u64,
        status: u16,
        body: Vec<u8>,
        headers: Vec<(String, String)>,
        error: Option<String>,
    },
    TcpEvent {
        id: u64,
        event: TcpEvent,
    },
    WebSocketEvent {
        id: u64,
        event: WsEvent,
    },
}
#[derive(Debug, Clone)]
pub enum TcpEvent {
    Connected,
    Data(Vec<u8>),
    Disconnected(String),
    Error(String),
}
#[derive(Debug, Clone)]
pub enum WsEvent {
    Open,
    Text(String),
    Binary(Vec<u8>),
    Close { code: u16, reason: String },
    Error(String),
}
pub struct NetworkRuntime {
    sender: mpsc::Sender<NetworkRequest>,
    receiver: mpsc::Receiver<NetworkResponse>,
    handle: Option<thread::JoinHandle<()>>,
    next_id: u64,
}
impl NetworkRuntime {
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
    pub fn next_request_id(&mut self) -> u64 {
        self.next_id += 1;
        self.next_id
    }
    pub fn send(&self, request: NetworkRequest) -> bool {
        self.sender.send(request).is_ok()
    }
    pub fn poll(&self) -> Vec<NetworkResponse> {
        let mut responses = Vec::new();
        while let Ok(resp) = self.receiver.try_recv() {
            responses.push(resp);
        }
        responses
    }
    pub fn shutdown(&mut self) {
        if self.handle.is_some() {
            let _ = self.sender.send(NetworkRequest::Shutdown);
            if let Some(handle) = self.handle.take() {
                let _ = handle.join();
            }
        }
    }
    pub fn is_running(&self) -> bool {
        self.handle.is_some()
    }
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
    pub fn tcp_close(&mut self, id: u64) -> Result<(), String> {
        let ok = self.send(NetworkRequest::TcpClose { id });
        if ok {
            Ok(())
        } else {
            Err("network thread not running".to_string())
        }
    }
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
impl Default for NetworkRuntime {
    fn default() -> Self {
        Self::new().expect("failed to spawn network thread")
    }
}
impl Drop for NetworkRuntime {
    fn drop(&mut self) {
        self.shutdown();
    }
}
