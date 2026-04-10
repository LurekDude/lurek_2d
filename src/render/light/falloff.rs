//! Falloff mode enum for controlling how light intensity decays over distance.

/// How light intensity decays from center to edge.
///
/// # Variants
/// - `Linear` — Linear variant.
/// - `Smooth` — Smooth variant.
/// - `Constant` — Constant variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum FalloffMode {
    /// Linear ramp from full intensity at center to zero at edge.
    #[default]
    Linear,
    /// Quadratic ease-out for a softer falloff curve.
    Smooth,
    /// Full intensity inside the radius with a hard cutoff at the edge.
    Constant,
}
