//! Math helper functions for particle interpolation and random sampling.

/// Linearly interpolate between `a` and `b` by factor `t`.
///
/// # Parameters
/// - `a` — `f32`.
/// - `b` — `f32`.
/// - `t` — `f32`.
///
/// # Returns
/// `f32`.
pub fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + (b - a) * t
}

/// Interpolate a multi-stop size array at normalised time `t` (0 = birth, 1 = death).
///
/// # Parameters
/// - `sizes` — `&[f32]`.
/// - `t` — `f32`.
/// - `variation` — `f32`.
///
/// # Returns
/// `f32`.
///
/// The `variation` factor (0..1) scales down the interpolated size.
/// With `variation = 0`, the full interpolated size is returned.
///
/// # Edge cases
/// - Empty `sizes`: returns `1.0`.
/// - Single value: returns `sizes[0] * (1 - variation)`.
/// - `t` is clamped to `[0, 1]`.
pub fn interpolate_sizes(sizes: &[f32], t: f32, variation: f32) -> f32 {
    if sizes.is_empty() {
        return 1.0;
    }
    if sizes.len() == 1 {
        return sizes[0] * (1.0 - variation);
    }
    let t = t.clamp(0.0, 1.0);
    let segments = (sizes.len() - 1) as f32;
    let pos = t * segments;
    let idx = (pos as usize).min(sizes.len() - 2);
    let local_t = pos - idx as f32;
    let base = lerp(sizes[idx], sizes[idx + 1], local_t);
    base * (1.0 - variation)
}

/// Interpolate a multi-stop color array at normalised time `t` (0 = birth, 1 = death).
///
/// # Parameters
/// - `colors` — `&[[f32; 4]]`.
/// - `t` — `f32`.
///
/// # Returns
/// `[f32; 4]`.
///
/// # Edge cases
/// - Empty `colors`: returns white `[1, 1, 1, 1]`.
/// - Single value: returns that color.
/// - `t` is clamped to `[0, 1]`.
pub fn interpolate_colors(colors: &[[f32; 4]], t: f32) -> [f32; 4] {
    if colors.is_empty() {
        return [1.0, 1.0, 1.0, 1.0];
    }
    if colors.len() == 1 {
        return colors[0];
    }
    let t = t.clamp(0.0, 1.0);
    let segments = (colors.len() - 1) as f32;
    let pos = t * segments;
    let idx = (pos as usize).min(colors.len() - 2);
    let local_t = pos - idx as f32;
    [
        lerp(colors[idx][0], colors[idx + 1][0], local_t),
        lerp(colors[idx][1], colors[idx + 1][1], local_t),
        lerp(colors[idx][2], colors[idx + 1][2], local_t),
        lerp(colors[idx][3], colors[idx + 1][3], local_t),
    ]
}

/// Interpolate a multi-stop alpha array at normalised time `t` (0 = birth, 1 = death).
///
/// # Parameters
/// - `alphas` — `&[f32]`.
/// - `t` — `f32`.
///
/// # Returns
/// `f32`.
///
/// # Edge cases
/// - Empty `alphas`: returns `1.0`.
/// - Single value: returns `alphas[0]`.
/// - `t` is clamped to `[0, 1]`.
pub fn interpolate_alphas(alphas: &[f32], t: f32) -> f32 {
    if alphas.is_empty() {
        return 1.0;
    }
    if alphas.len() == 1 {
        return alphas[0];
    }
    let t = t.clamp(0.0, 1.0);
    let segments = (alphas.len() - 1) as f32;
    let pos = t * segments;
    let idx = (pos as usize).min(alphas.len() - 2);
    let local_t = pos - idx as f32;
    lerp(alphas[idx], alphas[idx + 1], local_t)
}

/// Sample a uniform random value in `[min, max]`.
///
/// # Parameters
/// - `min` — `f32`.
/// - `max` — `f32`.
///
/// # Returns
/// `f32`.
pub(crate) fn rand_range(min: f32, max: f32) -> f32 {
    if (max - min).abs() < f32::EPSILON {
        return min;
    }
    min + fastrand::f32() * (max - min)
}

/// Approximate a standard-normal random value using Box-Muller transform.
///
/// # Returns
/// `f32`.
pub(crate) fn rand_normal() -> f32 {
    let u1 = fastrand::f32().max(f32::EPSILON);
    let u2 = fastrand::f32();
    (-2.0 * u1.ln()).sqrt() * (2.0 * std::f32::consts::PI * u2).cos()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lerp_midpoint_is_average() {
        let result = lerp(0.0, 10.0, 0.5);
        assert!((result - 5.0).abs() < 1e-5);
    }

    #[test]
    fn interpolate_sizes_empty_returns_one() {
        assert!((interpolate_sizes(&[], 0.5, 0.0) - 1.0).abs() < 1e-5);
    }

    #[test]
    fn interpolate_sizes_single_value_with_zero_variation() {
        assert!((interpolate_sizes(&[4.0], 0.5, 0.0) - 4.0).abs() < 1e-5);
    }

    #[test]
    fn interpolate_sizes_multi_stop_at_start_and_end() {
        let sizes = [0.0f32, 10.0];
        assert!((interpolate_sizes(&sizes, 0.0, 0.0) - 0.0).abs() < 1e-5);
        assert!((interpolate_sizes(&sizes, 1.0, 0.0) - 10.0).abs() < 1e-5);
    }
}
