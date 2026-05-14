//! Easing curve math used internally by the scene transition system.
//! Owns bounce_out and any future curve helpers; does not own transition state or draw logic.
//! Used only by transition.rs — crate-internal visibility via pub(crate).

/// Evaluate the bounce-out easing curve for t in [0, 1]; returns 1 at t=1.
pub(crate) fn bounce_out(t: f32) -> f32 {
    const N1: f32 = 7.5625;
    const D1: f32 = 2.75;
    if t < 1.0 / D1 {
        N1 * t * t
    } else if t < 2.0 / D1 {
        let t = t - 1.5 / D1;
        N1 * t * t + 0.75
    } else if t < 2.5 / D1 {
        let t = t - 2.25 / D1;
        N1 * t * t + 0.9375
    } else {
        let t = t - 2.625 / D1;
        N1 * t * t + 0.984_375
    }
}
