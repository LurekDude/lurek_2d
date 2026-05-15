//! - Multi-channel tween interpolator that drives values from start to target over a fixed duration.
//! - Easing resolution accepts both short names and `easeIn*`/`easeOut*` prefixed forms.
//! - Each tween holds an independent clock, supports reset, seek, and completion query.
//! - Channels are registered dynamically and interpolated per-frame via the resolved easing curve.
//! - Falls back to linear when an unknown easing name is provided.

use crate::math::easing;

/// Start/target pair for a single channel managed by a `Tween`.
#[derive(Debug, Clone)]
pub struct TweenValue {
    /// Starting value at t=0.
    pub start: f64,
    /// Target value at t=1 (end of tween).
    pub target: f64,
}

/// Multi-channel tween interpolator driven by an easing function over a fixed duration.
pub struct Tween {
    /// Total tween duration in seconds.
    duration: f64,
    /// Active easing function resolved from `easing_name`.
    easing_fn: fn(f32) -> f32,
    /// Human-readable name of the easing function, preserved for serialisation/debug.
    easing_name: String,
    /// Elapsed time since last `reset()`, in seconds.
    clock: f64,
    /// Registered start/target channel pairs.
    values: Vec<TweenValue>,
}

/// Resolve an easing name to a function pointer, accepting both short and `easeIn*` prefixed forms.
fn resolve_easing(name: &str) -> Option<fn(f32) -> f32> {
    easing::resolve_easing_fn(name).or_else(|| match name.to_lowercase().as_str() {
        "easeinquad" => Some(easing::ease_in_quad),
        "easeoutquad" => Some(easing::ease_out_quad),
        "easeinoutquad" => Some(easing::ease_in_out_quad),
        "easeincubic" => Some(easing::ease_in_cubic),
        "easeoutcubic" => Some(easing::ease_out_cubic),
        "easeinoutcubic" => Some(easing::ease_in_out_cubic),
        "easeinquart" => Some(easing::ease_in_quart),
        "easeoutquart" => Some(easing::ease_out_quart),
        "easeinoutquart" => Some(easing::ease_in_out_quart),
        "easeinsine" => Some(easing::ease_in_sine),
        "easeoutsine" => Some(easing::ease_out_sine),
        "easeinoutsine" => Some(easing::ease_in_out_sine),
        "easeinexpo" => Some(easing::ease_in_expo),
        "easeoutexpo" => Some(easing::ease_out_expo),
        "easeinoutexpo" => Some(easing::ease_in_out_expo),
        "easeinelastic" => Some(easing::ease_in_elastic),
        "easeoutelastic" => Some(easing::ease_out_elastic),
        "easeoutbounce" => Some(easing::ease_out_bounce),
        "easeinbounce" => Some(easing::ease_in_bounce),
        "easeinback" => Some(easing::ease_in_back),
        "easeoutback" => Some(easing::ease_out_back),
        _ => None,
    })
}

/// Multi-channel tween lifecycle: creation, channel registration, clock advancement, and value sampling.
impl Tween {
    /// Create a new Tween with the given `duration` (seconds) and named easing; falls back to linear when name is unknown.
    pub fn new(duration: f64, easing_name: &str) -> Self {
        let easing_fn = resolve_easing(easing_name).unwrap_or(easing::linear);
        Self {
            duration: duration.max(0.0),
            easing_fn,
            easing_name: easing_name.to_string(),
            clock: 0.0,
            values: Vec::new(),
        }
    }

    /// Register a `(start, target)` channel and return its index.
    pub fn add_value(&mut self, start: f64, target: f64) -> usize {
        let idx = self.values.len();
        self.values.push(TweenValue { start, target });
        idx
    }

    /// Advance the clock by `dt` seconds; returns true when the tween has completed.
    pub fn update(&mut self, dt: f64) -> bool {
        self.clock += dt;
        self.clock >= self.duration
    }

    /// Return the interpolated value for channel `index`; returns 0.0 for out-of-range index.
    pub fn get_value(&self, index: usize) -> f64 {
        if index >= self.values.len() {
            return 0.0;
        }
        let t = if self.duration <= 0.0 {
            1.0
        } else {
            (self.clock / self.duration).clamp(0.0, 1.0) as f32
        };
        let eased = (self.easing_fn)(t) as f64;
        let v = &self.values[index];
        v.start + (v.target - v.start) * eased
    }

    /// Return interpolated values for all registered channels.
    pub fn get_all_values(&self) -> Vec<f64> {
        (0..self.values.len()).map(|i| self.get_value(i)).collect()
    }

    /// Reset the clock to zero without clearing channels.
    pub fn reset(&mut self) {
        self.clock = 0.0;
    }

    /// Set the clock to a specific time `t`, clamped to `[0, duration]`.
    pub fn set_time(&mut self, t: f64) {
        self.clock = t.clamp(0.0, self.duration);
    }

    /// Return true when the clock has reached or passed the duration.
    pub fn is_complete(&self) -> bool {
        self.clock >= self.duration
    }

    /// Return the number of registered value channels.
    pub fn value_count(&self) -> usize {
        self.values.len()
    }

    /// Return the easing name string this tween was constructed with.
    pub fn easing_name(&self) -> &str {
        &self.easing_name
    }

    /// Return the total duration in seconds.
    pub fn duration(&self) -> f64 {
        self.duration
    }

    /// Return the current elapsed clock time in seconds.
    pub fn clock(&self) -> f64 {
        self.clock
    }
}
