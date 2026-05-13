#[derive(Debug, Clone)]
pub struct Throttle {
    pub interval: f64,
    pub elapsed: f64,
    pub leading: bool,
    pub fire_count: u64,
    pub enabled: bool,
}
impl Throttle {
    pub fn new(interval: f64) -> Self {
        Self {
            interval: interval.max(0.0),
            elapsed: interval,
            leading: true,
            fire_count: 0,
            enabled: true,
        }
    }
    pub fn update(&mut self, dt: f64) -> bool {
        if !self.enabled {
            return false;
        }
        self.elapsed += dt;
        if self.elapsed >= self.interval {
            self.elapsed = 0.0;
            self.fire_count += 1;
            return true;
        }
        false
    }
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
    }
    pub fn progress(&self) -> f64 {
        if self.interval <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.interval).min(1.0)
        }
    }
}
#[derive(Debug, Clone)]
pub struct Debounce {
    pub wait: f64,
    pub pending: bool,
    remaining: f64,
    pub fire_count: u64,
    pub enabled: bool,
}
impl Debounce {
    pub fn new(wait: f64) -> Self {
        Self {
            wait: wait.max(0.0),
            pending: false,
            remaining: 0.0,
            fire_count: 0,
            enabled: true,
        }
    }
    pub fn trigger(&mut self) {
        self.pending = true;
        self.remaining = self.wait;
    }
    pub fn update(&mut self, dt: f64) -> bool {
        if !self.enabled || !self.pending {
            return false;
        }
        self.remaining -= dt;
        if self.remaining <= 0.0 {
            self.pending = false;
            self.remaining = 0.0;
            self.fire_count += 1;
            return true;
        }
        false
    }
    pub fn cancel(&mut self) {
        self.pending = false;
        self.remaining = 0.0;
    }
}
