//! sRGB gamma ↔ linear color space conversion.
//!
//! Implements the standard IEC 61966-2-1 (sRGB) transfer functions for
//! converting between gamma-encoded sRGB and linear light values.

/// Convert a single sRGB gamma-space color component to linear space.
///
/// Input and output in `[0.0, 1.0]`. Uses the standard IEC 61966-2-1 sRGB transfer function.
///
/// # Parameters
/// - `c` — gamma-encoded sRGB channel value in `[0.0, 1.0]`
///
/// # Returns
/// Linear-light value in `[0.0, 1.0]`.
pub fn gamma_to_linear(c: f32) -> f32 {
    if c <= 0.04045 {
        c / 12.92
    } else {
        ((c + 0.055) / 1.055).powf(2.4)
    }
}

/// Convert a single linear-space color component to sRGB gamma space.
///
/// Input and output in `[0.0, 1.0]`. Uses the standard IEC 61966-2-1 sRGB inverse transfer function.
///
/// # Parameters
/// - `c` — linear-light channel value in `[0.0, 1.0]`
///
/// # Returns
/// Gamma-encoded sRGB value in `[0.0, 1.0]`.
pub fn linear_to_gamma(c: f32) -> f32 {
    if c <= 0.0031308 {
        c * 12.92
    } else {
        1.055 * c.powf(1.0 / 2.4) - 0.055
    }
}
