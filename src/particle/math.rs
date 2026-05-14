//! Math helpers for particle keyframe interpolation and random sampling.
//! Owns `interpolate_sizes`, `interpolate_colors`, `interpolate_alphas`, `rand_range`, and `rand_normal`.
//! Re-exports `lerp` from `crate::math` for convenience.
//! All functions are pure; no state is mutated.

pub use crate::math::lerp;
/// Evaluate the particle size at normalised lifetime `t` with optional per-particle `variation` in `[0.0, 1.0]`.
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
/// Evaluate the RGBA colour keyframe at normalised lifetime `t`; returns white when the slice is empty.
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
/// Evaluate the alpha keyframe at normalised lifetime `t`; returns 1.0 when the slice is empty.
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
/// Return a uniform random `f32` in `[min, max]`; returns `min` when the range is degenerate.
pub(crate) fn rand_range(min: f32, max: f32) -> f32 {
    if (max - min).abs() < f32::EPSILON {
        return min;
    }
    min + fastrand::f32() * (max - min)
}
/// Return a Box-Muller normal sample with mean 0 and std 1.
pub(crate) fn rand_normal() -> f32 {
    let u1 = fastrand::f32().max(f32::EPSILON);
    let u2 = fastrand::f32();
    (-2.0 * u1.ln()).sqrt() * (2.0 * std::f32::consts::PI * u2).cos()
}
