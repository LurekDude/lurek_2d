//! Scope: Shared monotonic time reference for logger and profiler.
//! This file defines TimeAnchor and elapsed-time calculation.
//! It owns clock reference and relative timing for subsystem events.

use std::time::Instant;

/// Monotonic elapsed-time anchor.
#[derive(Debug, Clone)]
pub struct TimeAnchor {
    start: Instant,
}

impl TimeAnchor {
    /// Creates a new anchor starting at `Instant::now()`.
    pub fn new() -> Self {
        Self {
            start: Instant::now(),
        }
    }

    /// Returns elapsed seconds from anchor creation.
    pub fn elapsed_seconds(&self) -> f64 {
        self.start.elapsed().as_secs_f64()
    }
}

impl Default for TimeAnchor {
    fn default() -> Self {
        Self::new()
    }
}
