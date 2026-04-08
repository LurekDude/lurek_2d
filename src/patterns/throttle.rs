//! Rate-limiting primitives: throttle and debounce.
//!
//! [`Throttle`] ensures a callback fires **at most once** per time window
//! (leading-edge). [`Debounce`] delays a callback until the input stream
//! is idle for a configured duration (trailing-edge). Both are pure-Rust
//! timers; callback invocation is handled in the Lua API layer.

// ── Throttle ──────────────────────────────────────────────────────────────

/// Enforces a minimum interval between callback invocations (leading-edge).
///
/// Call [`Throttle::update`] each game tick; it returns `true` when a callback
/// should fire and resets the internal timer.
///
/// # Fields
/// - `interval` — `f64`.
/// - `elapsed` — `f64`.
/// - `leading` — `bool`.
#[derive(Debug, Clone)]
pub struct Throttle {
    /// Minimum time (seconds) between invocations.
    pub interval: f64,
    /// Accumulated time since last fire.
    pub elapsed: f64,
    /// When `true`, fires on the first call in a new window (leading edge).
    pub leading: bool,
    /// Number of times this throttle has fired.
    pub fire_count: u64,
    /// Whether the throttle is currently active (enabled).
    pub enabled: bool,
}

impl Throttle {
    /// Creates a throttle that fires at most once per `interval` seconds.
    ///
    /// # Parameters
    /// - `interval` — `f64`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(interval: f64) -> Self {
        Self {
            interval: interval.max(0.0),
            // Start at interval so first call fires immediately
            elapsed: interval,
            leading: true,
            fire_count: 0,
            enabled: true,
        }
    }

    /// Advances time by `dt` seconds and returns `true` if the callback should fire.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn update(&mut self, dt: f64) -> bool {
        if !self.enabled { return false; }
        self.elapsed += dt;
        if self.elapsed >= self.interval {
            self.elapsed = 0.0;
            self.fire_count += 1;
            return true;
        }
        false
    }

    /// Resets the elapsed counter forcing the next `update` to not fire (unless
    /// interval is 0).
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
    }

    /// Returns the normalised progress through the current interval in `[0, 1]`.
    ///
    /// # Returns
    /// `f64`.
    pub fn progress(&self) -> f64 {
        if self.interval <= 0.0 { 1.0 } else { (self.elapsed / self.interval).min(1.0) }
    }
}

// ── Debounce ──────────────────────────────────────────────────────────────

/// Delays callback invocation until the input stream is idle (trailing-edge).
///
/// Call [`Debounce::trigger`] whenever an event arrives to reset the wait
/// timer. Call [`Debounce::update`] each tick; it returns `true` when the
/// wait has expired after a trigger.
///
/// # Fields
/// - `wait` — `f64`.
/// - `pending` — `bool`.
#[derive(Debug, Clone)]
pub struct Debounce {
    /// Required idle time (seconds) before firing.
    pub wait: f64,
    /// Whether a trigger is pending (timer counting down).
    pub pending: bool,
    remaining: f64,
    /// Total fire count since creation.
    pub fire_count: u64,
    /// Whether the debounce is currently active (enabled).
    pub enabled: bool,
}

impl Debounce {
    /// Creates a debounce with the given idle `wait` duration.
    ///
    /// # Parameters
    /// - `wait` — `f64`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(wait: f64) -> Self {
        Self {
            wait: wait.max(0.0),
            pending: false,
            remaining: 0.0,
            fire_count: 0,
            enabled: true,
        }
    }

    /// Records an input event, resetting the idle timer.
    pub fn trigger(&mut self) {
        self.pending = true;
        self.remaining = self.wait;
    }

    /// Advances time by `dt` seconds. Returns `true` and clears the pending
    /// flag when the idle wait expires after a trigger.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn update(&mut self, dt: f64) -> bool {
        if !self.enabled || !self.pending { return false; }
        self.remaining -= dt;
        if self.remaining <= 0.0 {
            self.pending = false;
            self.remaining = 0.0;
            self.fire_count += 1;
            return true;
        }
        false
    }

    /// Cancels any pending trigger without firing.
    pub fn cancel(&mut self) {
        self.pending = false;
        self.remaining = 0.0;
    }
}
