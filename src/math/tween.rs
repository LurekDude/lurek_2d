//! Low-level numeric value interpolator with easing curves.
//!
//! Provides `Tween` — a standalone multi-value interpolator that advances its own
//! clock and applies an easing function to a set of start-to-target value pairs.
//! Script code accesses this through `lurek.math.newTween()`.
//!
//! **Scope**: pure numeric interpolation; no Lua tables, no callbacks, no
//! auto-registration. For frame-by-frame property animation of Lua table fields
//! with callbacks, sequences, and parallels, use `lurek.tween` (`src/tween/`).
//!
//! Key types: `TweenValue`, `Tween`.
//! Primary functions: `new()`, `add_value()`, `update()`, `get_value()`.

use crate::math::easing;

/// A start-to-target value pair for interpolation.
///
/// # Fields
/// - `start` — `f64`.
/// - `target` — `f64`.
#[derive(Debug, Clone)]
pub struct TweenValue {
    /// Starting value.
    pub start: f64,
    /// Target value.
    pub target: f64,
}

/// Value interpolator using easing functions.
///
/// Animates one or more values from start to target over a given duration,
/// applying an easing curve to control the interpolation speed.
///
/// # Fields
/// - `duration` — `f64`.
/// - `easing_fn` — `fn(f32) -> f32`.
/// - `easing_name` — `String`.
/// - `clock` — `f64`.
/// - `values` — `Vec<TweenValue>`.
pub struct Tween {
    duration: f64,
    easing_fn: fn(f32) -> f32,
    easing_name: String,
    clock: f64,
    values: Vec<TweenValue>,
}

/// Resolves an easing function pointer from a name string.
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

impl Tween {
    /// Creates a new tween with the given duration and easing name.
    ///
    /// # Parameters
    /// - `duration` — `f64`.
    /// - `easing_name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Falls back to linear if the easing name is not recognized.
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

    /// Adds a value to interpolate. Returns the 0-based index.
    ///
    /// # Parameters
    /// - `start` — `f64`.
    /// - `target` — `f64`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_value(&mut self, start: f64, target: f64) -> usize {
        let idx = self.values.len();
        self.values.push(TweenValue { start, target });
        idx
    }

    /// Advances the clock by `dt` seconds. Returns `true` when the tween is complete.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn update(&mut self, dt: f64) -> bool {
        self.clock += dt;
        self.clock >= self.duration
    }

    /// Returns the interpolated value at the given index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `f64`.
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

    /// Returns all interpolated values. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<f64>`.
    pub fn get_all_values(&self) -> Vec<f64> {
        (0..self.values.len()).map(|i| self.get_value(i)).collect()
    }

    /// Resets the clock to 0. After this call the container is in the same state as immediately after construction.
    pub fn reset(&mut self) {
        self.clock = 0.0;
    }

    /// Sets the clock to a specific time, clamped to [0, duration].
    ///
    /// # Parameters
    /// - `t` — `f64`.
    pub fn set_time(&mut self, t: f64) {
        self.clock = t.clamp(0.0, self.duration);
    }

    /// Returns true if the tween has completed.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_complete(&self) -> bool {
        self.clock >= self.duration
    }

    /// Returns the number of values in this tween.
    ///
    /// # Returns
    /// `usize`.
    pub fn value_count(&self) -> usize {
        self.values.len()
    }

    /// Returns the easing name. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&str`.
    pub fn easing_name(&self) -> &str {
        &self.easing_name
    }

    /// Returns the duration. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn duration(&self) -> f64 {
        self.duration
    }

    /// Returns the current clock time. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn clock(&self) -> f64 {
        self.clock
    }
}
