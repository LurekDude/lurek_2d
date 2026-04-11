//! Shared state types for the Lurek2D TCP debug bridge.
//!
//! These types are exchanged between the TCP server thread and the Lua main
//! thread without any Lua dependency.  All fields are intentionally `pub` so
//! both threads can read and write them through the shared `Arc<Mutex<BridgeShared>>`.

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
/// - `print_history` — `Vec<PrintEntry>`.
/// - `max_print_history` — `usize`.
/// - `frame_times` — `Vec<f64>`.
/// - `max_frame_times` — `usize`.
/// - `screenshot_requested` — `bool`.
/// - `screenshot_scale` — `u32`.
/// - `client_count` — `usize`.
/// - `port` — `u16`.
/// - `epoch` — `Instant`.
pub struct BridgeShared {
    /// Requests waiting for main-thread (Lua) execution.
    pub pending_requests: VecDeque<PendingRequest>,
    /// Responses waiting to be written back to TCP clients.
    pub pending_responses: VecDeque<PendingResponse>,
    /// JSON event strings broadcast to all connected clients.
    pub broadcast_queue: VecDeque<String>,
    /// Circular print history buffer.
    pub print_history: Vec<PrintEntry>,
    /// Maximum number of print entries to retain.
    pub max_print_history: usize,
    /// Recent frame delta-time values (seconds).
    pub frame_times: Vec<f64>,
    /// Maximum number of frame-time samples to retain.
    pub max_frame_times: usize,
    /// Set to `true` when a screenshot has been requested via the bridge.
    pub screenshot_requested: bool,
    /// Downscale factor for the next screenshot (1–8).
    pub screenshot_scale: u32,
    /// Number of currently connected TCP clients.
    pub client_count: usize,
    /// Port the server is bound to.
    pub port: u16,
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
            print_history: Vec::new(),
            max_print_history: 2000,
            frame_times: Vec::new(),
            max_frame_times: 300,
            screenshot_requested: false,
            screenshot_scale: 1,
            client_count: 0,
            port: 0,
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
        let sum: f64 = self.frame_times.iter().sum();
        let avg = sum / n;
        let min = self.frame_times.iter().cloned().fold(f64::MAX, f64::min);
        let max = self.frame_times.iter().cloned().fold(0.0_f64, f64::max);
        let last = *self.frame_times.last().unwrap_or(&0.0);
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
        self.print_history.push(entry);
        if self.print_history.len() > self.max_print_history {
            self.print_history.remove(0);
        }
    }

    /// Appends a delta-time sample to the frame-time ring buffer.
    ///
    /// Evicts the oldest sample when the buffer exceeds `max_frame_times`.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    pub fn record_frame(&mut self, dt: f64) {
        self.frame_times.push(dt);
        if self.frame_times.len() > self.max_frame_times {
            self.frame_times.remove(0);
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
            self.print_history.remove(0);
        }
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
        let event = serde_json::json!({
            "event": "print",
            "data": {
                "timestamp": ts,
                "message": msg,
                "source": source,
                "line": line
            }
        });
        self.broadcast_queue.push_back(event.to_string());
    }
}

impl Default for BridgeShared {
    fn default() -> Self {
        Self::new()
    }
}

/// Type alias for the shared state handle passed between threads.
pub type SharedBridge = Arc<Mutex<BridgeShared>>;
