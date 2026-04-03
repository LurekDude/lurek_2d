//! Particle shape enum defining the geometric primitive used to render untextured particles.

/// Geometric shape used when drawing untextured particles.
///
/// Defaults to `ParticleShape::Square` for backward compatibility with the original rectangle-only renderer.
/// The shape is passed through to the GPU renderer as `ParticleRenderShape`; see `DrawParticleSystem` in
/// `src/graphics/renderer.rs` for the matching render-side enum.
///
/// # Variants
/// - `Square` — Square variant.
/// - `Circle` — Circle variant.
/// - `Triangle` — Triangle variant.
/// - `Spark` — Spark variant.
/// - `Diamond` — Diamond variant.
#[derive(Clone, Debug, Default, PartialEq)]
pub enum ParticleShape {
    /// Axis-aligned filled square. Backward-compatible default. Size is the side length.
    #[default]
    Square,
    /// Filled circle. Size is the diameter.
    Circle,
    /// Filled equilateral triangle, rotated by the particle's `rotation` field. Size is the circumradius.
    Triangle,
    /// Thin line segment (1px stroke) oriented along the particle's velocity direction.
    /// Rendered length = `size * 3.0`; always uses the particle's current rotation.
    Spark,
    /// Filled diamond (square rotated 45°). Size is the diagonal length.
    Diamond,
}
