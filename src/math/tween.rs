//! Value interpolator with easing curves.
//!
//! Uses easing functions from `crate::math::easing` to smoothly interpolate
//! between start and target values over a duration.
//!
//! This module is part of Luna2D's `math` subsystem and provides the implementation
//! details for tween-related operations and data management.
//! Key types exported from this module: `TweenValue`, `Tween`.
//! Primary functions: `new()`, `add_value()`, `update()`, `get_value()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

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
    match name.to_lowercase().as_str() {
        "linear" => Some(easing::linear),
        "inquad" | "easeinquad" => Some(easing::ease_in_quad),
        "outquad" | "easeoutquad" => Some(easing::ease_out_quad),
        "inoutquad" | "easeinoutquad" => Some(easing::ease_in_out_quad),
        "incubic" | "easeincubic" => Some(easing::ease_in_cubic),
        "outcubic" | "easeoutcubic" => Some(easing::ease_out_cubic),
        "inoutcubic" | "easeinoutcubic" => Some(easing::ease_in_out_cubic),
        "inquart" | "easeinquart" => Some(easing::ease_in_quart),
        "outquart" | "easeoutquart" => Some(easing::ease_out_quart),
        "inoutquart" | "easeinoutquart" => Some(easing::ease_in_out_quart),
        "insine" | "easeinsine" => Some(easing::ease_in_sine),
        "outsine" | "easeoutsine" => Some(easing::ease_out_sine),
        "inoutsine" | "easeinoutsine" => Some(easing::ease_in_out_sine),
        "inexpo" | "easeinexpo" => Some(easing::ease_in_expo),
        "outexpo" | "easeoutexpo" => Some(easing::ease_out_expo),
        "inoutexpo" | "easeinoutexpo" => Some(easing::ease_in_out_expo),
        "inelastic" | "easeinelastic" => Some(easing::ease_in_elastic),
        "outelastic" | "easeoutelastic" => Some(easing::ease_out_elastic),
        "outbounce" | "easeoutbounce" => Some(easing::ease_out_bounce),
        "inbounce" | "easeinbounce" => Some(easing::ease_in_bounce),
        "inback" | "easeinback" => Some(easing::ease_in_back),
        "outback" | "easeoutback" => Some(easing::ease_out_back),
        _ => None,
    }
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_linear_tween() {
        let mut tw = Tween::new(1.0, "linear");
        tw.add_value(0.0, 100.0);
        tw.set_time(0.5);
        let v = tw.get_value(0);
        assert!((v - 50.0).abs() < 1e-3);
    }

    #[test]
    fn test_tween_complete() {
        let mut tw = Tween::new(2.0, "linear");
        tw.add_value(0.0, 10.0);
        assert!(!tw.is_complete());
        tw.update(1.0);
        assert!(!tw.is_complete());
        tw.update(1.5);
        assert!(tw.is_complete());
    }

    #[test]
    fn test_tween_reset() {
        let mut tw = Tween::new(1.0, "linear");
        tw.add_value(0.0, 100.0);
        tw.update(1.0);
        assert!(tw.is_complete());
        tw.reset();
        assert!(!tw.is_complete());
        assert!((tw.get_value(0) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_easing_quad() {
        let mut tw = Tween::new(1.0, "inQuad");
        tw.add_value(0.0, 100.0);
        tw.set_time(0.5);
        // ease_in_quad(0.5) = 0.25
        let v = tw.get_value(0);
        assert!((v - 25.0).abs() < 1e-3);
    }

    #[test]
    fn test_multiple_values() {
        let mut tw = Tween::new(1.0, "linear");
        let i0 = tw.add_value(0.0, 100.0);
        let i1 = tw.add_value(50.0, 150.0);
        tw.set_time(0.5);
        assert!((tw.get_value(i0) - 50.0).abs() < 1e-3);
        assert!((tw.get_value(i1) - 100.0).abs() < 1e-3);
    }

    #[test]
    fn test_get_all_values() {
        let mut tw = Tween::new(1.0, "linear");
        tw.add_value(0.0, 10.0);
        tw.add_value(100.0, 200.0);
        tw.set_time(1.0);
        let vals = tw.get_all_values();
        assert_eq!(vals.len(), 2);
        assert!((vals[0] - 10.0).abs() < 1e-3);
        assert!((vals[1] - 200.0).abs() < 1e-3);
    }

    #[test]
    fn test_unknown_easing_fallback() {
        let mut tw = Tween::new(1.0, "nonexistent");
        tw.add_value(0.0, 100.0);
        tw.set_time(0.5);
        // Falls back to linear
        assert!((tw.get_value(0) - 50.0).abs() < 1e-3);
    }
}
