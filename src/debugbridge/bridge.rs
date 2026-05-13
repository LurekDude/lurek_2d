use std::collections::VecDeque;
use std::sync::{Arc, Mutex};
use std::time::Instant;
#[derive(Clone)]
pub struct PendingRequest {
    pub id: u64,
    pub method: String,
    pub params: serde_json::Value,
    pub client_idx: usize,
}
#[derive(Clone)]
pub struct PendingResponse {
    pub id: u64,
    pub result: serde_json::Value,
    pub client_idx: usize,
}
#[derive(Clone, serde::Serialize)]
pub struct PrintEntry {
    pub timestamp: f64,
    pub message: String,
    pub source: String,
    pub line: u32,
}
pub struct BridgeShared {
    pub pending_requests: VecDeque<PendingRequest>,
    pub pending_responses: VecDeque<PendingResponse>,
    pub broadcast_queue: VecDeque<String>,
    pub print_history: VecDeque<PrintEntry>,
    pub max_print_history: usize,
    pub frame_times: VecDeque<f64>,
    pub max_frame_times: usize,
    perf_sum: f64,
    perf_min: f64,
    perf_max: f64,
    pub screenshot_requested: bool,
    pub screenshot_scale: u32,
    pub client_count: usize,
    pub port: u16,
    pub protocol_version: u32,
    pub capabilities: Vec<String>,
    pub handshake_nonce: String,
    pub hot_reload_requested: bool,
    pub epoch: Instant,
}
impl BridgeShared {
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
    pub fn elapsed(&self) -> f64 {
        self.epoch.elapsed().as_secs_f64()
    }
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
    pub fn set_max_print_history(&mut self, max: usize) {
        self.max_print_history = max.clamp(1, 100_000);
        while self.print_history.len() > self.max_print_history {
            let _ = self.print_history.pop_front();
        }
    }
    pub(crate) fn drain_responses(&mut self) -> Vec<PendingResponse> {
        self.pending_responses.drain(..).collect()
    }
    pub(crate) fn queue_broadcast_json(&mut self, event: &str, data: serde_json::Value) {
        let payload = serde_json::json!({
            "event": event,
            "data": data
        });
        self.broadcast_queue.push_back(payload.to_string());
    }
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
pub type SharedBridge = Arc<Mutex<BridgeShared>>;
