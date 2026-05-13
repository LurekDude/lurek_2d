use std::time::Instant;
#[derive(Debug, Clone)]
pub struct TimeAnchor {
    start: Instant,
}
impl TimeAnchor {
    pub fn new() -> Self {
        Self {
            start: Instant::now(),
        }
    }
    pub fn elapsed_seconds(&self) -> f64 {
        self.start.elapsed().as_secs_f64()
    }
}
impl Default for TimeAnchor {
    fn default() -> Self {
        Self::new()
    }
}
