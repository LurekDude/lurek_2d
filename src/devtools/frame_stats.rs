//! Track frame delta samples and compute percentile timing summaries.
//! Keep rolling-window statistics deterministic for debug HUD displays.
//! Do not read clocks directly or own profiler zone nesting behavior.
//! Depend on numeric vectors and bounded deque storage.

use std::collections::VecDeque;
#[derive(Debug)]
/// Store a bounded history of frame delta samples for aggregate stats.
pub struct FrameStats {
    /// Hold recent frame delta values in seconds.
    pub history: VecDeque<f64>,
    /// Define maximum number of samples retained in history.
    pub capacity: usize,
}
impl FrameStats {
    /// Create frame stats with bounded capacity and return the instance.
    pub fn new(capacity: usize) -> Self {
        Self {
            history: VecDeque::new(),
            capacity: capacity.max(10),
        }
    }
    /// Append one frame delta sample and drop oldest samples past capacity.
    pub fn record(&mut self, dt: f64) {
        self.history.push_back(dt);
        if self.history.len() > self.capacity {
            let _ = self.history.pop_front();
        }
    }
    /// Set the sample capacity and trim stored history to the new bound.
    pub fn set_capacity(&mut self, cap: usize) {
        self.capacity = cap.clamp(10, 10_000);
        while self.history.len() > self.capacity {
            let _ = self.history.pop_front();
        }
    }
    /// Compute aggregate frame metrics and return zeros when history is empty.
    pub fn snapshot(&self) -> FrameSnapshot {
        if self.history.is_empty() {
            return FrameSnapshot::zero();
        }
        let mut sorted: Vec<f64> = self.history.iter().copied().collect();
        sorted.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
        let n = sorted.len();
        let sum: f64 = sorted.iter().sum();
        let avg = sum / n as f64;
        let pct = |p: f64| {
            let idx = ((p / 100.0) * (n as f64 - 1.0)).round() as usize;
            sorted[idx.min(n - 1)]
        };
        FrameSnapshot {
            fps: if avg > 0.0 { 1.0 / avg } else { 0.0 },
            dt: *sorted.last().unwrap_or(&0.0),
            avg,
            min: sorted[0],
            max: sorted[n - 1],
            p50: pct(50.0),
            p95: pct(95.0),
            p99: pct(99.0),
            samples: n,
        }
    }
}
/// Provide default frame stats with a 300-sample rolling window.
impl Default for FrameStats {
    fn default() -> Self {
        Self::new(300)
    }
}
#[derive(Debug, Clone)]
/// Hold computed frame-time and FPS summary metrics from sampled history.
pub struct FrameSnapshot {
    /// Store estimated frames per second derived from average delta.
    pub fps: f64,
    /// Store most recent frame delta value in seconds.
    pub dt: f64,
    /// Store average frame delta across retained samples.
    pub avg: f64,
    /// Store minimum frame delta observed in retained samples.
    pub min: f64,
    /// Store maximum frame delta observed in retained samples.
    pub max: f64,
    /// Store median-like 50th percentile frame delta.
    pub p50: f64,
    /// Store 95th percentile frame delta for tail-latency tracking.
    pub p95: f64,
    /// Store 99th percentile frame delta for worst-frame tracking.
    pub p99: f64,
    /// Store number of samples included in this snapshot.
    pub samples: usize,
}
impl FrameSnapshot {
    /// Create a zeroed snapshot and return it for empty-history cases.
    fn zero() -> Self {
        Self {
            fps: 0.0,
            dt: 0.0,
            avg: 0.0,
            min: 0.0,
            max: 0.0,
            p50: 0.0,
            p95: 0.0,
            p99: 0.0,
            samples: 0,
        }
    }
}
