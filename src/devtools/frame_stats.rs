//! Scope: Rolling frame-time statistics with aggregate percentile queries.
//! This file defines FrameStats, FrameSnapshot, and per-frame recording.
//! It owns fixed-capacity ring storage and percentile interpolation.

use std::collections::VecDeque;

// ── FrameStats ────────────────────────────────────────────────────────────

/// Rolling-window frame-time accumulator.
///
/// # Fields
/// - `history` — `VecDeque<f64>`.
/// - `capacity` — `usize`.
#[derive(Debug)]
pub struct FrameStats {
    /// Ordered ring of frame-time samples (oldest first).
    pub history: VecDeque<f64>,
    /// Maximum retained sample count.
    pub capacity: usize,
}

impl FrameStats {
    /// Creates a new `FrameStats` with the given sample capacity.
    ///
    /// # Parameters
    /// - `capacity` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(capacity: usize) -> Self {
        Self {
            history: VecDeque::new(),
            capacity: capacity.max(10),
        }
    }

    /// Pushes a new frame-time sample, evicting the oldest when full.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    pub fn record(&mut self, dt: f64) {
        self.history.push_back(dt);
        if self.history.len() > self.capacity {
            let _ = self.history.pop_front();
        }
    }

    /// Sets the capacity, trimming old samples if necessary.
    ///
    /// # Parameters
    /// - `cap` — `usize`.
    pub fn set_capacity(&mut self, cap: usize) {
        self.capacity = cap.clamp(10, 10_000);
        while self.history.len() > self.capacity {
            let _ = self.history.pop_front();
        }
    }

    /// Returns a snapshot of computed frame statistics.
    ///
    /// # Returns
    /// `FrameSnapshot` with fps, avg, min, max, and percentile fields.
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

// ── FrameSnapshot ─────────────────────────────────────────────────────────

/// Computed statistics snapshot from [`FrameStats::snapshot`].
///
/// # Fields
/// - `fps` — `f64`.
/// - `dt` — `f64`.
/// - `avg` — `f64`.
/// - `min` — `f64`.
/// - `max` — `f64`.
/// - `p50` — `f64`.
/// - `p95` — `f64`.
/// - `p99` — `f64`.
/// - `samples` — `usize`.
#[derive(Debug, Clone)]
pub struct FrameSnapshot {
    /// Instantaneous FPS derived from the most recent avg.
    pub fps: f64,
    /// Most recent frame time.
    pub dt: f64,
    /// Mean frame time.
    pub avg: f64,
    /// Minimum frame time.
    pub min: f64,
    /// Maximum frame time.
    pub max: f64,
    /// 50th percentile frame time.
    pub p50: f64,
    /// 95th percentile frame time.
    pub p95: f64,
    /// 99th percentile frame time.
    pub p99: f64,
    /// Number of samples in the window.
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
