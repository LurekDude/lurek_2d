use std::collections::VecDeque;
#[derive(Debug)]
pub struct FrameStats {
    pub history: VecDeque<f64>,
    pub capacity: usize,
}
impl FrameStats {
    pub fn new(capacity: usize) -> Self {
        Self {
            history: VecDeque::new(),
            capacity: capacity.max(10),
        }
    }
    pub fn record(&mut self, dt: f64) {
        self.history.push_back(dt);
        if self.history.len() > self.capacity {
            let _ = self.history.pop_front();
        }
    }
    pub fn set_capacity(&mut self, cap: usize) {
        self.capacity = cap.clamp(10, 10_000);
        while self.history.len() > self.capacity {
            let _ = self.history.pop_front();
        }
    }
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
impl Default for FrameStats {
    fn default() -> Self {
        Self::new(300)
    }
}
#[derive(Debug, Clone)]
pub struct FrameSnapshot {
    pub fps: f64,
    pub dt: f64,
    pub avg: f64,
    pub min: f64,
    pub max: f64,
    pub p50: f64,
    pub p95: f64,
    pub p99: f64,
    pub samples: usize,
}
impl FrameSnapshot {
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
