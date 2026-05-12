//! Pure-Rust timing and easing state for the tween system.
//!
//! This module provides the numeric core of the tween system without any
//! Lua dependencies. Lua-specific property binding, table-field access, and
//! UserData handle types live in `src/tween/handle.rs` and the active-pool
//! driver lives in `src/tween/engine.rs`.

use crate::math::easing;

/// Pure numeric tween timing state: elapsed time, easing function, and pause flag.
///
/// This type tracks how far along a tween is and computes the eased interpolation
/// factor `t` (0.0..=1.0). It does not store start/end values — those are managed
/// by the Lua binding layer (`LuaTween`) which lazily captures start values from
/// the target Lua table on first tick.
///
/// # Fields
/// - `duration` — `f64`. Total tween duration in seconds.
/// - `elapsed` — `f64`. Elapsed playback time in seconds.
/// - `easing_fn` — `fn(f32) -> f32`. Built-in easing function pointer.
/// - `paused` — `bool`. True when the tween is paused.
pub struct TweenState {
    /// Total tween duration in seconds.
    pub duration: f64,
    /// Elapsed playback time in seconds.
    pub elapsed: f64,
    /// Easing function applied to the raw 0..=1 progress.
    easing_fn: fn(f32) -> f32,
    /// Whether this tween is currently paused.
    pub paused: bool,
}

impl TweenState {
    /// Creates a new tween state with the given duration and easing name.
    ///
    /// If `easing_name` is not recognised, `"linear"` is used as the fallback.
    /// A duration of zero or less is clamped to a very small positive value so
    /// that `t_raw` never divides by zero.
    ///
    /// # Parameters
    /// - `duration` — `f64`. Duration in seconds.
    /// - `easing_name` — `&str`. Name of the built-in easing (e.g. `"cubicOut"`).
    ///
    /// # Returns
    /// `Self`.
    pub fn new(duration: f64, easing_name: &str) -> Self {
        Self {
            duration: duration.max(0.0001),
            elapsed: 0.0,
            easing_fn: resolve_easing(easing_name).unwrap_or(easing::linear),
            paused: false,
        }
    }

    /// Advances the elapsed time by `dt` seconds. Returns `true` when the tween
    /// has reached or exceeded its duration.
    ///
    /// If the tween is paused, `dt` is ignored and the method returns `false`.
    ///
    /// # Parameters
    /// - `dt` — `f64`. Delta-time in seconds.
    ///
    /// # Returns
    /// `bool` — `true` if the tween is now complete.
    pub fn tick(&mut self, dt: f64) -> bool {
        if self.paused {
            return false;
        }
        self.elapsed += dt;
        self.elapsed >= self.duration
    }

    /// Resets elapsed time to 0 so the tween plays from the beginning.
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
    }

    /// Returns the raw (un-eased) 0..=1 progress factor.
    ///
    /// # Returns
    /// `f32` — Clamped linear progress.
    pub fn t_raw(&self) -> f32 {
        if self.duration <= 0.0 {
            return 1.0;
        }
        (self.elapsed / self.duration).clamp(0.0, 1.0) as f32
    }

    /// Returns the eased 0..=1 progress factor using the chosen easing function.
    ///
    /// Note: some easing functions (elastic, back) briefly exceed the [0, 1] range
    /// to produce overshoot or anticipation effects — this is intentional.
    ///
    /// # Returns
    /// `f64` — Eased progress.
    pub fn t_eased(&self) -> f64 {
        (self.easing_fn)(self.t_raw()) as f64
    }

    /// Linearly interpolates from `start` to `end` using the eased progress factor.
    ///
    /// # Parameters
    /// - `start` — `f64`. Start value.
    /// - `end` — `f64`. End value.
    ///
    /// # Returns
    /// `f64` — Interpolated value.
    pub fn lerp(&self, start: f64, end: f64) -> f64 {
        start + (end - start) * self.t_eased()
    }

    /// Returns `true` if elapsed has reached or exceeded the duration.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_complete(&self) -> bool {
        self.elapsed >= self.duration
    }
}

/// Resolves a named easing function to a function pointer.
///
/// Returns `None` if the name is not a known built-in easing. The caller is
/// responsible for substituting a default (typically `easing::linear`).
///
/// # Parameters
/// - `name` — `&str`. Case-insensitive easing name.
///
/// # Returns
/// `Option<fn(f32) -> f32>`.
pub fn resolve_easing(name: &str) -> Option<fn(f32) -> f32> {
    easing::resolve_easing_fn(name).or_else(|| match name.to_lowercase().as_str() {
        "quadin" | "easeinquad" => Some(easing::ease_in_quad),
        "quadout" | "easeoutquad" => Some(easing::ease_out_quad),
        "quadinout" | "easeinoutquad" => Some(easing::ease_in_out_quad),
        "cubicin" | "easeincubic" => Some(easing::ease_in_cubic),
        "cubicout" | "easeoutcubic" => Some(easing::ease_out_cubic),
        "cubicinout" | "easeinoutcubic" => Some(easing::ease_in_out_cubic),
        "quartin" | "easeinquart" => Some(easing::ease_in_quart),
        "quartout" | "easeoutquart" => Some(easing::ease_out_quart),
        "quartinout" | "easeinoutquart" => Some(easing::ease_in_out_quart),
        "sinein" | "easeinsine" => Some(easing::ease_in_sine),
        "sineout" | "easeoutsine" => Some(easing::ease_out_sine),
        "sineinout" | "easeinoutsine" => Some(easing::ease_in_out_sine),
        "expoin" | "easeinexpo" => Some(easing::ease_in_expo),
        "expoout" | "easeoutexpo" => Some(easing::ease_out_expo),
        "expoinout" | "easeinoutexpo" => Some(easing::ease_in_out_expo),
        "elasticin" | "easeinelastic" => Some(easing::ease_in_elastic),
        "elasticout" | "easeoutelastic" => Some(easing::ease_out_elastic),
        "bouncein" | "easeinbounce" => Some(easing::ease_in_bounce),
        "bounceout" | "easeoutbounce" => Some(easing::ease_out_bounce),
        "backin" | "easeinback" => Some(easing::ease_in_back),
        "backout" | "easeoutback" => Some(easing::ease_out_back),
        _ => None,
    })
}

/// Returns all built-in easing names as a static slice.
///
/// # Returns
/// `&'static [&'static str]`.
pub fn builtin_easing_names() -> &'static [&'static str] {
    &[
        "linear",
        "quadIn",
        "quadOut",
        "quadInOut",
        "cubicIn",
        "cubicOut",
        "cubicInOut",
        "quartIn",
        "quartOut",
        "quartInOut",
        "sineIn",
        "sineOut",
        "sineInOut",
        "expoIn",
        "expoOut",
        "expoInOut",
        "elasticIn",
        "elasticOut",
        "bounceIn",
        "bounceOut",
        "backIn",
        "backOut",
    ]
}
