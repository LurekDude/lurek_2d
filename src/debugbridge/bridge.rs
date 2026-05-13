//! Scope: Shared state types for TCP debug bridge communication.
//! This file defines PendingRequest, PendingResponse, PrintEntry, and BridgeShared.
//! It owns request/response queuing, print history, and performance metrics.

use std::collections::VecDeque;
use std::sync::{Arc, Mutex};
use std::time::Instant;

/// A request from a TCP client that requires main-thread (Lua) execution.
///
/// # Fields
/// - `id` — `u64`.
/// - `method` — `String`.
/// - `params` — `serde_json::Value`.
/// - `client_idx` — `usize`.
#[derive(Clone)]
pub struct PendingRequest {
    /// JSON-RPC request id.
    pub id: u64,
    /// Method name (e.g. `"eval"`, `"getLocals"`).
    pub method: String,
    /// Raw JSON parameters.
    pub params: serde_json::Value,
    /// Index into the server-thread client list that sent this request.
    pub client_idx: usize,
}

/// A response produced on the main thread for delivery back to a TCP client.
///
/// # Fields
/// - `id` — `u64`.
/// - `result` — `serde_json::Value`.
/// - `client_idx` — `usize`.
#[derive(Clone)]
pub struct PendingResponse {
    /// Matches the `id` from the originating [`PendingRequest`].
    pub id: u64,
    /// JSON result payload.
    pub result: serde_json::Value,
    /// Index into the server-thread client list to receive the response.
    pub client_idx: usize,
}

/// A single structured print log entry captured from `lurek.print`.
///
/// # Fields
/// - `timestamp` — `f64`.
/// - `message` — `String`.
/// - `source` — `String`.
/// - `line` — `u32`.
#[derive(Clone, serde::Serialize)]
pub struct PrintEntry {
    /// Seconds since bridge start when this entry was recorded.
    pub timestamp: f64,
    /// The formatted message string.
    pub message: String,
    /// Lua source file name.
    pub source: String,
    /// Lua source line number.
    pub line: u32,
}

/// State shared between the TCP server background thread and the Lua main thread.
///
/// # Fields
/// - `pending_requests` — `VecDeque<PendingRequest>`.
/// - `pending_responses` — `VecDeque<PendingResponse>`.
/// - `broadcast_queue` — `VecDeque<String>`.
/// - `print_history` — `VecDeque<PrintEntry>`.
/// - `max_print_history` — `usize`.
/// - `frame_times` — `VecDeque<f64>`.
/// - `max_frame_times` — `usize`.
/// - `screenshot_requested` — `bool`.
/// - `screenshot_scale` — `u32`.
/// - `client_count` — `usize`.
/// - `port` — `u16`.
/// - `protocol_version` — `u32`.
/// - `capabilities` — `Vec<String>`.
/// - `handshake_nonce` — `String`.
/// - `hot_reload_requested` — `bool`.
/// - `epoch` — `Instant`.
pub struct BridgeShared {
    /// Requests waiting for main-thread (Lua) execution.
    pub pending_requests: VecDeque<PendingRequest>,
    /// Responses waiting to be written back to TCP clients.
    pub pending_responses: VecDeque<PendingResponse>,
    /// JSON event strings broadcast to all connected clients.
    pub broadcast_queue: VecDeque<String>,
    /// Circular print history buffer.
    pub print_history: VecDeque<PrintEntry>,
    /// Maximum number of print entries to retain.
    pub max_print_history: usize,
    /// Recent frame delta-time values (seconds).
    pub frame_times: VecDeque<f64>,
    /// Maximum number of frame-time samples to retain.
    pub max_frame_times: usize,
    /// Running frame-time sum used to avoid rescanning in get_performance().
    perf_sum: f64,
    /// Cached frame-time minimum.
    perf_min: f64,
    /// Cached frame-time maximum.
    perf_max: f64,
    /// Set to `true` when a screenshot has been requested via the bridge.
    pub screenshot_requested: bool,
    /// Downscale factor for the next screenshot (1–8).
    pub screenshot_scale: u32,
    /// Number of currently connected TCP clients.
    pub client_count: usize,
    /// Port the server is bound to.
    pub port: u16,
    /// Protocol version expected by this server.
    pub protocol_version: u32,
    /// Supported capability names announced during hello.
    pub capabilities: Vec<String>,
    /// One-time nonce clients must echo in `hello` before using non-hello methods.
    pub handshake_nonce: String,
    /// Set to true when a remote client requests hot reload.
    pub hot_reload_requested: bool,
    /// Epoch used for `elapsed()` timestamps.
    pub epoch: Instant,
}

impl BridgeShared {
    /// Creates a new `BridgeShared` with default capacities.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            pending_requests: VecDeque::new(),
            pending_responses: VecDeque::new(),
            broadcast_queue: VecDeque::new(),
            print_history: VecDeque::new(),
            max_print_history: 2000,
            frame_times: VecDeque::new(),
            max_frame_times: 300,
            perf_sum: 0.0,
            perf_min: 0.0,
            perf_max: 0.0,
            screenshot_requested: false,
            screenshot_scale: 1,
            client_count: 0,
            port: 0,
            protocol_version: 1,
            capabilities: vec![
                "hello".to_string(),
                "eval".to_string(),
                "stack".to_string(),
                "globals".to_string(),
                "locals".to_string(),
                "screenshot".to_string(),
                "hot_reload".to_string(),
                "inspect".to_string(),
            ],
            handshake_nonce: format!("{:x}", Instant::now().elapsed().as_nanos() ^ 0xA5A5_5A5A_u128),
            hot_reload_requested: false,
            epoch: Instant::now(),
        }
    }

    /// Returns seconds elapsed since the bridge was created.
    ///
    /// # Returns
    /// `f64`.
    pub fn elapsed(&self) -> f64 {
        self.epoch.elapsed().as_secs_f64()
    }

    /// Returns a JSON performance summary computed from recent frame-time data.
    ///
    /// # Returns
    /// `serde_json::Value`.
    pub fn get_performance(&self) -> serde_json::Value {
        if self.frame_times.is_empty() {
            return serde_json::json!({
                "fps": 0.0, "dt": 0.0, "avgDt": 0.0,
                "minDt": 0.0, "maxDt": 0.0
            });
        }
        let n = self.frame_times.len() as f64;
        let avg = self.perf_sum / n;
        let min = self.perf_min;
        let max = self.perf_max;
        let last = *self.frame_times.back().unwrap_or(&0.0);
        serde_json::json!({
            "fps": if avg > 0.0 { 1.0 / avg } else { 0.0 },
            "dt": last,
            "avgDt": avg,
            "minDt": min,
            "maxDt": max
        })
    }

    /// Appends a print entry to the history, evicting the oldest if the buffer is full.
    ///
    /// # Parameters
    /// - `msg` — `&str`.
    /// - `source` — `&str`.
    /// - `line` — `u32`.
    pub fn push_print(&mut self, msg: &str, source: &str, line: u32) {
        let entry = PrintEntry {
            timestamp: self.elapsed(),
            message: msg.to_string(),
            source: source.to_string(),
            line,
        };
        self.print_history.push_back(entry);
        if self.print_history.len() > self.max_print_history {
            let _ = self.print_history.pop_front();
        }
    }

    /// Appends a delta-time sample to the frame-time ring buffer.
    ///
    /// Evicts the oldest sample when the buffer exceeds `max_frame_times`.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    pub fn record_frame(&mut self, dt: f64) {
        self.frame_times.push_back(dt);
        self.perf_sum += dt;
        if self.frame_times.len() == 1 {
            self.perf_min = dt;
            self.perf_max = dt;
        } else {
            self.perf_min = self.perf_min.min(dt);
            self.perf_max = self.perf_max.max(dt);
        }

        if self.frame_times.len() > self.max_frame_times {
            if let Some(old) = self.frame_times.pop_front() {
                self.perf_sum -= old;
                if (old - self.perf_min).abs() < f64::EPSILON || (old - self.perf_max).abs() < f64::EPSILON {
                    self.recompute_perf_bounds();
                }
            }
        }
    }

    /// Sets the maximum print-history capacity and trims excess entries.
    ///
    /// `max` is clamped to `[1, 100000]`.
    ///
    /// # Parameters
    /// - `max` — `usize`.
    pub fn set_max_print_history(&mut self, max: usize) {
        self.max_print_history = max.clamp(1, 100_000);
        while self.print_history.len() > self.max_print_history {
            let _ = self.print_history.pop_front();
        }
    }

    /// Drains pending responses into a vector for easy server-side flush.
    ///
    /// # Returns
    /// `Vec<PendingResponse>`.
    pub(crate) fn drain_responses(&mut self) -> Vec<PendingResponse> {
        self.pending_responses.drain(..).collect()
    }

    /// Queues an event object into the broadcast queue.
    ///
    /// # Parameters
    /// - `event` — `&str`.
    /// - `data` — `serde_json::Value`.
    pub(crate) fn queue_broadcast_json(&mut self, event: &str, data: serde_json::Value) {
        let payload = serde_json::json!({
            "event": event,
            "data": data
        });
        self.broadcast_queue.push_back(payload.to_string());
    }

    /// Appends a print entry and queues a broadcast event for all connected clients.
    ///
    /// The broadcast JSON has the form `{"event":"print","data":{...}}`.
    ///
    /// # Parameters
    /// - `msg` — `&str`.
    /// - `source` — `&str`.
    /// - `line` — `u32`.
    pub fn capture_print_with_broadcast(&mut self, msg: &str, source: &str, line: u32) {
        self.push_print(msg, source, line);
        let ts = self.elapsed();
        self.queue_broadcast_json(
            "print",
            serde_json::json!({
                "timestamp": ts,
                "message": msg,
                "source": source,
                "line": line
            }),
        );
    }

    fn recompute_perf_bounds(&mut self) {
        if self.frame_times.is_empty() {
            self.perf_min = 0.0;
            self.perf_max = 0.0;
            self.perf_sum = 0.0;
            return;
        }
        let mut min = f64::MAX;
        let mut max = 0.0_f64;
        let mut sum = 0.0;
        for &v in &self.frame_times {
            min = min.min(v);
            max = max.max(v);
            sum += v;
        }
        self.perf_min = min;
        self.perf_max = max;
        self.perf_sum = sum;
    }
}

impl Default for BridgeShared {
    fn default() -> Self {
        Self::new()
    }
}

/// Type alias for the shared state handle passed between threads.
pub type SharedBridge = Arc<Mutex<BridgeShared>>;
