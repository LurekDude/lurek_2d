//! Easing state and easing name resolver for the tween subsystem.
//! Owns `TweenState`, `resolve_easing`, and `builtin_easing_names`.
//! Does not own tween handles or spring logic. Depends on `crate::math::easing`.

use crate::math::easing;

/// Per-tween progress tracker storing elapsed time, duration, easing function, and pause state.
pub struct TweenState {
    /// Total duration of the tween in seconds; clamped to >= 0.0001.
    pub duration: f64,
    /// Seconds elapsed since the tween started.
    pub elapsed: f64,
    /// Resolved easing function `f(t: f32) -> f32` in [0,1] â†’ [0,1].
    easing_fn: fn(f32) -> f32,
    /// True when `tick` should not advance `elapsed`.
    pub paused: bool,
}

impl TweenState {
    /// Create a new state with the given `duration` and easing name; falls back to linear on unknown names.
    pub fn new(duration: f64, easing_name: &str) -> Self {
        Self {
            duration: duration.max(0.0001),
            elapsed: 0.0,
            easing_fn: resolve_easing(easing_name).unwrap_or(easing::linear),
            paused: false,
        }
    }

    /// Advance elapsed time by `dt` when not paused; return true if the tween has reached or passed its duration.
    pub fn tick(&mut self, dt: f64) -> bool {
        if self.paused {
            return false;
        }
        self.elapsed += dt;
        self.elapsed >= self.duration
    }

    /// Reset `elapsed` to zero so the tween plays from the beginning.
    pub fn reset(&mut self) {
        self.elapsed = 0.0;
    }

    /// Return raw (uneased) progress in [0.0, 1.0]; returns 1.0 when duration is zero.
    pub fn t_raw(&self) -> f32 {
        if self.duration <= 0.0 {
            return 1.0;
        }
        (self.elapsed / self.duration).clamp(0.0, 1.0) as f32
    }

    /// Return eased progress in [0.0, 1.0] by applying the resolved easing function to `t_raw`.
    pub fn t_eased(&self) -> f64 {
        (self.easing_fn)(self.t_raw()) as f64
    }

    /// Return `start + (end - start) * t_eased()`.
    pub fn lerp(&self, start: f64, end: f64) -> f64 {
        start + (end - start) * self.t_eased()
    }

    /// Return true when elapsed >= duration.
    pub fn is_complete(&self) -> bool {
        self.elapsed >= self.duration
    }
}

/// Resolve an easing name string to a function pointer; return `None` for unknown names.
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

/// Return a static slice of all built-in easing names recognised by `resolve_easing`.
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
