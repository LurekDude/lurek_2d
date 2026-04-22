//! Particle shape enum defining the geometric primitive used to render untextured particles.

/// Geometric shape used when drawing untextured particles.
///
/// Defaults to `ParticleShape::Square` for backward compatibility with the original rectangle-only renderer.
/// The shape is passed through to the GPU renderer as `ParticleRenderShape`; see `DrawParticleSystem` in
/// `src/graphics/renderer.rs` for the matching render-side enum.
///
/// # Variants
/// - `Square` â€” Axis-aligned filled square.
/// - `Circle` â€” Filled circle.
/// - `Triangle` â€” Filled equilateral triangle.
/// - `Spark` â€” Thin 1px line segment oriented along velocity.
/// - `Diamond` â€” Filled diamond (square rotated 45Â°).
/// - `Shrapnel` â€” Random jagged polygon (deterministic per particle). `edges` controls vertex count (3â€“12).
/// - `Ray` â€” Elongated filled rectangle. `aspect` controls length-to-width ratio (default 4.0).
/// - `Puff` â€” Soft filled circle with more tessellation segments than `Circle` for a smoother look.
/// - `Ring` â€” Hollow ring (annulus). `thickness` controls the ring band width as a fraction of particle size.
/// - `Capsule` â€” Rectangle with hemispherical caps oriented along the particle's rotation.
#[derive(Clone, Debug, Default, PartialEq, serde::Serialize, serde::Deserialize)]
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
    /// Filled diamond (square rotated 45Â°). Size is the diagonal length.
    Diamond,
    /// Random jagged polygon with deterministic shape from `Particle::shape_seed`.
    /// `edges` clamps to 3â€“12 vertices for controlled jaggedness; default is 6.
    Shrapnel {
        /// Number of polygon vertices (3â€“12). Values outside range are clamped.
        edges: u8,
    },
    /// Elongated filled rectangle oriented along `particle.rotation`.
    /// `aspect` is the length-to-width ratio; a value of 4.0 gives a 4Ă— longer shape.
    Ray {
        /// Length-to-width ratio. Defaults to 4.0 when 0.0 or negative is supplied.
        aspect: f32,
    },
    /// Soft filled circle with 24 tessellation segments. Visually smoother than `Circle` (12 segs).
    Puff,
    /// Hollow ring (annulus). `thickness` is the band width as a fraction of the particle's size (0â€“1).
    Ring {
        /// Band width relative to particle size (0.0â€“1.0). Clamped to a minimum of 0.05.
        thickness: f32,
    },
    /// Filled capsule (rectangle + two hemispherical caps), oriented along `particle.rotation`.
    Capsule,
}
