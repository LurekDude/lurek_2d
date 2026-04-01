//! Standard easing functions for smooth animation and interpolation.
//!
//! Each function takes a normalised progress value `t` in `[0.0, 1.0]` and
//! returns the eased value, also in `[0.0, 1.0]` for most curves.

use std::f32::consts::PI;

/// Linear interpolation — no easing.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn linear(t: f32) -> f32 {
    t
}

/// Quadratic ease-in — starts slow, accelerates.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_quad(t: f32) -> f32 {
    t * t
}

/// Quadratic ease-out — starts fast, decelerates.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_out_quad(t: f32) -> f32 {
    t * (2.0 - t)
}

/// Quadratic ease-in-out — slow start and end, fast middle.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_out_quad(t: f32) -> f32 {
    if t < 0.5 {
        2.0 * t * t
    } else {
        -1.0 + (4.0 - 2.0 * t) * t
    }
}

/// Cubic ease-in — starts slow, accelerates sharply.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_cubic(t: f32) -> f32 {
    t * t * t
}

/// Cubic ease-out — starts fast, decelerates sharply.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_out_cubic(t: f32) -> f32 {
    let u = t - 1.0;
    u * u * u + 1.0
}

/// Cubic ease-in-out — smooth S-curve.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_out_cubic(t: f32) -> f32 {
    if t < 0.5 {
        4.0 * t * t * t
    } else {
        let u = 2.0 * t - 2.0;
        0.5 * u * u * u + 1.0
    }
}

/// Quartic ease-in — very slow start.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_quart(t: f32) -> f32 {
    t * t * t * t
}

/// Quartic ease-out — very slow end.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_out_quart(t: f32) -> f32 {
    let u = t - 1.0;
    1.0 - u * u * u * u
}

/// Quartic ease-in-out — pronounced S-curve.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_out_quart(t: f32) -> f32 {
    if t < 0.5 {
        8.0 * t * t * t * t
    } else {
        let u = t - 1.0;
        1.0 - 8.0 * u * u * u * u
    }
}

/// Sinusoidal ease-in — gentle sine-based acceleration.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_sine(t: f32) -> f32 {
    1.0 - (t * PI / 2.0).cos()
}

/// Sinusoidal ease-out — gentle sine-based deceleration.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_out_sine(t: f32) -> f32 {
    (t * PI / 2.0).sin()
}

/// Sinusoidal ease-in-out — gentle S-curve.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_out_sine(t: f32) -> f32 {
    0.5 * (1.0 - (PI * t).cos())
}

/// Exponential ease-in — very slow start, rapid acceleration.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_expo(t: f32) -> f32 {
    if t <= 0.0 {
        0.0
    } else {
        (2.0_f32).powf(10.0 * (t - 1.0))
    }
}

/// Exponential ease-out — rapid start, very slow end.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_out_expo(t: f32) -> f32 {
    if t >= 1.0 {
        1.0
    } else {
        1.0 - (2.0_f32).powf(-10.0 * t)
    }
}

/// Exponential ease-in-out — sharp S-curve with exponential tails.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_out_expo(t: f32) -> f32 {
    if t <= 0.0 {
        return 0.0;
    }
    if t >= 1.0 {
        return 1.0;
    }
    if t < 0.5 {
        0.5 * (2.0_f32).powf(20.0 * t - 10.0)
    } else {
        1.0 - 0.5 * (2.0_f32).powf(-20.0 * t + 10.0)
    }
}

/// Elastic ease-in — spring-like overshoot at the start.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_elastic(t: f32) -> f32 {
    if t <= 0.0 {
        return 0.0;
    }
    if t >= 1.0 {
        return 1.0;
    }
    let p = 0.3_f32;
    -(2.0_f32.powf(10.0 * (t - 1.0)) * ((t - 1.0 - p / 4.0) * 2.0 * PI / p).sin())
}

/// Elastic ease-out — spring-like overshoot at the end.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_out_elastic(t: f32) -> f32 {
    if t <= 0.0 {
        return 0.0;
    }
    if t >= 1.0 {
        return 1.0;
    }
    let p = 0.3_f32;
    2.0_f32.powf(-10.0 * t) * ((t - p / 4.0) * 2.0 * PI / p).sin() + 1.0
}

/// Bounce ease-out — simulates a bouncing ball landing.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_out_bounce(t: f32) -> f32 {
    if t < 1.0 / 2.75 {
        7.5625 * t * t
    } else if t < 2.0 / 2.75 {
        let t = t - 1.5 / 2.75;
        7.5625 * t * t + 0.75
    } else if t < 2.5 / 2.75 {
        let t = t - 2.25 / 2.75;
        7.5625 * t * t + 0.9375
    } else {
        let t = t - 2.625 / 2.75;
        7.5625 * t * t + 0.984375
    }
}

/// Bounce ease-in — simulates a bouncing ball launching.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_bounce(t: f32) -> f32 {
    1.0 - ease_out_bounce(1.0 - t)
}

/// Back ease-in — pulls back before accelerating past the start.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_in_back(t: f32) -> f32 {
    let s = 1.70158_f32;
    t * t * ((s + 1.0) * t - s)
}

/// Back ease-out — overshoots the target then settles back.
///
/// # Parameters
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// Eased output; typically in `[0.0, 1.0]` (may overshoot for elastic, back, and bounce curves).
pub fn ease_out_back(t: f32) -> f32 {
    let s = 1.70158_f32;
    let u = t - 1.0;
    u * u * ((s + 1.0) * u + s) + 1.0
}

/// Looks up an easing function by name and applies it to progress value `t`.
///
/// Supported names (case-insensitive): `"linear"`, `"inQuad"`, `"outQuad"`,
/// `"inOutQuad"`, `"inCubic"`, `"outCubic"`, `"inOutCubic"`, `"inQuart"`,
/// `"outQuart"`, `"inOutQuart"`, `"inSine"`, `"outSine"`, `"inOutSine"`,
/// `"inExpo"`, `"outExpo"`, `"inOutExpo"`, `"inElastic"`, `"outElastic"`,
/// `"outBounce"`, `"inBounce"`, `"inBack"`, `"outBack"`.
///
/// # Parameters
/// - `name` — easing name string (case-insensitive)
/// - `t` — normalised progress value in `[0.0, 1.0]`
///
/// # Returns
/// `Some(f32)` with the eased value, or `None` if the name is unrecognised.
pub fn apply(name: &str, t: f32) -> Option<f32> {
    match name.to_lowercase().as_str() {
        "linear" => Some(linear(t)),
        "inquad" => Some(ease_in_quad(t)),
        "outquad" => Some(ease_out_quad(t)),
        "inoutquad" => Some(ease_in_out_quad(t)),
        "incubic" => Some(ease_in_cubic(t)),
        "outcubic" => Some(ease_out_cubic(t)),
        "inoutcubic" => Some(ease_in_out_cubic(t)),
        "inquart" => Some(ease_in_quart(t)),
        "outquart" => Some(ease_out_quart(t)),
        "inoutquart" => Some(ease_in_out_quart(t)),
        "insine" => Some(ease_in_sine(t)),
        "outsine" => Some(ease_out_sine(t)),
        "inoutsine" => Some(ease_in_out_sine(t)),
        "inexpo" => Some(ease_in_expo(t)),
        "outexpo" => Some(ease_out_expo(t)),
        "inoutexpo" => Some(ease_in_out_expo(t)),
        "inelastic" => Some(ease_in_elastic(t)),
        "outelastic" => Some(ease_out_elastic(t)),
        "outbounce" => Some(ease_out_bounce(t)),
        "inbounce" => Some(ease_in_bounce(t)),
        "inback" => Some(ease_in_back(t)),
        "outback" => Some(ease_out_back(t)),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn approx(a: f32, b: f32) -> bool {
        (a - b).abs() < 1e-5
    }

    #[test]
    fn test_easing_boundaries_start_at_zero() {
        let funcs: Vec<(&str, fn(f32) -> f32)> = vec![
            ("linear", linear),
            ("ease_in_quad", ease_in_quad),
            ("ease_out_quad", ease_out_quad),
            ("ease_in_out_quad", ease_in_out_quad),
            ("ease_in_cubic", ease_in_cubic),
            ("ease_out_cubic", ease_out_cubic),
            ("ease_in_out_cubic", ease_in_out_cubic),
            ("ease_in_quart", ease_in_quart),
            ("ease_out_quart", ease_out_quart),
            ("ease_in_out_quart", ease_in_out_quart),
            ("ease_in_sine", ease_in_sine),
            ("ease_out_sine", ease_out_sine),
            ("ease_in_out_sine", ease_in_out_sine),
            ("ease_in_expo", ease_in_expo),
            ("ease_out_expo", ease_out_expo),
            ("ease_in_out_expo", ease_in_out_expo),
            ("ease_out_bounce", ease_out_bounce),
            ("ease_in_bounce", ease_in_bounce),
            ("ease_in_back", ease_in_back),
            ("ease_out_back", ease_out_back),
        ];
        for (name, f) in &funcs {
            assert!(
                approx(f(0.0), 0.0),
                "{name} did not start at 0.0: {}",
                f(0.0)
            );
        }
    }

    #[test]
    fn test_easing_boundaries_end_at_one() {
        let funcs: Vec<(&str, fn(f32) -> f32)> = vec![
            ("linear", linear),
            ("ease_in_quad", ease_in_quad),
            ("ease_out_quad", ease_out_quad),
            ("ease_in_out_quad", ease_in_out_quad),
            ("ease_in_cubic", ease_in_cubic),
            ("ease_out_cubic", ease_out_cubic),
            ("ease_in_out_cubic", ease_in_out_cubic),
            ("ease_in_quart", ease_in_quart),
            ("ease_out_quart", ease_out_quart),
            ("ease_in_out_quart", ease_in_out_quart),
            ("ease_in_sine", ease_in_sine),
            ("ease_out_sine", ease_out_sine),
            ("ease_in_out_sine", ease_in_out_sine),
            ("ease_in_expo", ease_in_expo),
            ("ease_out_expo", ease_out_expo),
            ("ease_in_out_expo", ease_in_out_expo),
            ("ease_out_bounce", ease_out_bounce),
            ("ease_in_bounce", ease_in_bounce),
            ("ease_out_back", ease_out_back),
        ];
        for (name, f) in &funcs {
            assert!(approx(f(1.0), 1.0), "{name} did not end at 1.0: {}", f(1.0));
        }
    }

    #[test]
    fn test_easing_midpoints() {
        assert!(approx(linear(0.5), 0.5));
        assert!(approx(ease_in_out_quad(0.5), 0.5));
        assert!(approx(ease_in_out_cubic(0.5), 0.5));
        assert!(approx(ease_in_out_sine(0.5), 0.5));
    }

    #[test]
    fn test_apply_lookup() {
        assert!(approx(apply("inQuad", 0.5).unwrap(), ease_in_quad(0.5)));
        assert!(approx(apply("outCubic", 0.5).unwrap(), ease_out_cubic(0.5)));
        assert!(approx(apply("linear", 1.0).unwrap(), 1.0));
        assert!(apply("nonexistent", 0.5).is_none());
    }

    #[test]
    fn test_apply_case_insensitive() {
        assert!(approx(apply("INQUAD", 0.5).unwrap(), ease_in_quad(0.5)));
        assert!(approx(apply("OutBounce", 1.0).unwrap(), 1.0));
    }

    #[test]
    fn test_elastic_boundaries() {
        assert!(approx(ease_in_elastic(0.0), 0.0));
        assert!(approx(ease_in_elastic(1.0), 1.0));
        assert!(approx(ease_out_elastic(0.0), 0.0));
        assert!(approx(ease_out_elastic(1.0), 1.0));
    }
}
