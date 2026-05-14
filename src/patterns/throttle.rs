
/// Timer that fires at most once per `interval` seconds.
#[derive(Debug, Clone)]
pub struct Throttle {
    /// Minimum seconds between firings.
    pub interval: f64,
    /// Seconds elapsed since last fire.
    pub elapsed: f64,
    /// When true, fires on the leading edge at creation.
    pub leading: bool,
    /// Total number of times this throttle has fired.
    pub fire_count: u64,
    /// When false, `update` always returns false.
    pub enabled: bool,
}
/// All methods for `Throttle`.
impl Throttle {
    /// Create a throttle that fires every `interval` seconds.
    pub fn new(interval: f64) -> Self {
        Self {
            interval: interval.max(0.0),
            elapsed: interval,
            leading: true,
            fire_count: 0,
            enabled: true,
        }
    }
    /// Advance by `dt` seconds; return true when the interval elapsed and a fire occurs.
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
    /// Reset the elapsed counter, delaying the next fire by a full interval.
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
    }
    /// Return normalized progress toward the next fire in `0.0..=1.0`.
    pub fn progress(&self) -> f64 {
        if self.interval <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.interval).min(1.0)
        }
    }
}
/// Timer that fires once after `wait` seconds of quiet time following a trigger.
#[derive(Debug, Clone)]
pub struct Debounce {
    /// Seconds to wait after the last trigger before firing.
    pub wait: f64,
    /// True when a trigger is pending.
    pub pending: bool,
    /// Seconds remaining until fire.
    remaining: f64,
    /// Total number of times this debounce has fired.
    pub fire_count: u64,
    /// When false, `update` always returns false.
    pub enabled: bool,
}
/// All methods for `Debounce`.
impl Debounce {
    /// Create a debounce that fires after `wait` seconds of inactivity.
    pub fn new(wait: f64) -> Self {
        Self {
            wait: wait.max(0.0),
            pending: false,
            remaining: 0.0,
            fire_count: 0,
            enabled: true,
        }
    }
    /// Arm the debounce, restarting the `wait` countdown.
    pub fn trigger(&mut self) {
        self.pending = true;
        self.remaining = self.wait;
    }
    /// Advance by `dt` seconds; return true when `wait` expires and the pending event fires.
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
    /// Cancel a pending trigger without firing.
    pub fn cancel(&mut self) {
        self.pending = false;
        self.remaining = 0.0;
    }
}
