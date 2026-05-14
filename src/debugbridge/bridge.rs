//! Hold synchronized debug bridge state shared between runtime and TCP server.
//! Keep request queues, print history, and performance sampling in one place.
//! Do not own socket accept loops or JSON message parsing in this module.
//! Depend on synchronized queues, timestamps, and serde JSON values.

use std::collections::VecDeque;
use std::sync::{Arc, Mutex};
use std::time::Instant;
#[derive(Clone)]
/// Represent one client request queued for runtime-side processing.
pub struct PendingRequest {
    /// Store request identifier used for response correlation.
    pub id: u64,
    /// Store requested method name.
    pub method: String,
    /// Store request parameter payload.
    pub params: serde_json::Value,
    /// Store index of the client connection that sent this request.
    pub client_idx: usize,
}
#[derive(Clone)]
/// Represent one pending response queued for server-side delivery.
pub struct PendingResponse {
    /// Store response identifier matching the original request id.
    pub id: u64,
    /// Store response payload result object.
    pub result: serde_json::Value,
    /// Store index of the target client connection.
    pub client_idx: usize,
}
#[derive(Clone, serde::Serialize)]
/// Represent one captured print event for history and bridge broadcast.
pub struct PrintEntry {
    /// Store elapsed timestamp in seconds from bridge epoch.
    pub timestamp: f64,
    /// Store captured print text.
    pub message: String,
    /// Store source label associated with the print message.
    pub source: String,
    /// Store source line number when available.
    pub line: u32,
}
/// Hold shared bridge queues, telemetry windows, and session configuration.
pub struct BridgeShared {
    /// Queue runtime-bound requests received from clients.
    pub pending_requests: VecDeque<PendingRequest>,
    /// Queue client-bound responses produced by runtime handlers.
    pub pending_responses: VecDeque<PendingResponse>,
    /// Queue broadcast event payloads to send to all clients.
    pub broadcast_queue: VecDeque<String>,
    /// Store bounded print history captured from runtime output.
    pub print_history: VecDeque<PrintEntry>,
    /// Define maximum number of print rows retained.
    pub max_print_history: usize,
    /// Store recent frame delta samples in seconds.
    pub frame_times: VecDeque<f64>,
    /// Define maximum number of frame samples retained.
    pub max_frame_times: usize,
    /// Accumulate frame delta sum for average computation.
    perf_sum: f64,
    /// Track minimum frame delta in retained samples.
    perf_min: f64,
    /// Track maximum frame delta in retained samples.
    perf_max: f64,
    /// Flag that runtime should capture a screenshot on next opportunity.
    pub screenshot_requested: bool,
    /// Store screenshot scale multiplier requested by a client.
    pub screenshot_scale: u32,
    /// Store current count of connected clients.
    pub client_count: usize,
    /// Store server port used by the debug bridge listener.
    pub port: u16,
    /// Store negotiated protocol version required for hello handshake.
    pub protocol_version: u32,
    /// Store capability names advertised to clients.
    pub capabilities: Vec<String>,
    /// Store nonce required for authenticated request methods.
    pub handshake_nonce: String,
    /// Flag that runtime should run hot-reload processing.
    pub hot_reload_requested: bool,
    /// Store epoch instant used for relative timestamps.
    pub epoch: Instant,
}
impl BridgeShared {
    /// Create initialized shared bridge state and return it.
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
            handshake_nonce: format!(
                "{:x}",
                Instant::now().elapsed().as_nanos() ^ 0xA5A5_5A5A_u128
            ),
            hot_reload_requested: false,
            epoch: Instant::now(),
        }
    }
    /// Return elapsed time in seconds from bridge epoch.
    pub fn elapsed(&self) -> f64 {
        self.epoch.elapsed().as_secs_f64()
    }
    /// Return current performance metrics as a JSON object.
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
    /// Append a print row to history and enforce retention bounds.
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
    /// Record one frame delta and update rolling performance aggregates.
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
                if (old - self.perf_min).abs() < f64::EPSILON
                    || (old - self.perf_max).abs() < f64::EPSILON
                {
                    self.recompute_perf_bounds();
                }
            }
        }
    }
    /// Set max print history and trim oldest rows beyond the new limit.
    pub fn set_max_print_history(&mut self, max: usize) {
        self.max_print_history = max.clamp(1, 100_000);
        while self.print_history.len() > self.max_print_history {
            let _ = self.print_history.pop_front();
        }
    }
    /// Drain all pending responses and return them as a vector.
    pub(crate) fn drain_responses(&mut self) -> Vec<PendingResponse> {
        self.pending_responses.drain(..).collect()
    }
    /// Queue one broadcast event payload and return unit.
    pub(crate) fn queue_broadcast_json(&mut self, event: &str, data: serde_json::Value) {
        let payload = serde_json::json!({
            "event": event,
            "data": data
        });
        self.broadcast_queue.push_back(payload.to_string());
    }
    /// Capture print entry and queue matching broadcast payload.
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
    /// Recompute min, max, and sum from retained frame samples.
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
/// Provide default shared state equivalent to a fresh bridge instance.
impl Default for BridgeShared {
    fn default() -> Self {
        Self::new()
    }
}
/// Alias shared synchronized bridge state used by runtime integration points.
pub type SharedBridge = Arc<Mutex<BridgeShared>>;
