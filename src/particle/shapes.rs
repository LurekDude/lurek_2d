//! `ParticleShape` enum: per-particle primitive geometry used by the renderer to draw each particle.
//! Owns the shape type definition; render interpretation lives in `render::renderer`.
//! Serialisable; matched to `ParticleRenderShape` in `emitter::build_render_commands`.

/// Geometric primitive used to draw a single particle.
#[derive(Clone, Debug, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum ParticleShape {
    /// Solid axis-aligned square (default).
    #[default]
    Square,
    /// Solid circle.
    Circle,
    /// Equilateral triangle pointing up.
    Triangle,
    /// Narrow elongated diamond oriented along the velocity vector.
    Spark,
    /// Axis-aligned diamond (rotated square).
    Diamond,
    /// Irregular polygon with `edges` vertices; appearance seeded per-particle.
    Shrapnel {
        /// Number of polygon vertices; clamped to a minimum of 3.
        edges: u8,
    },
    /// Rectangle stretched by `aspect` ratio along the velocity direction.
    Ray {
        /// Width-to-height ratio; values > 1.0 elongate along the emission direction.
        aspect: f32,
    },
    /// Soft rounded blob.
    Puff,
    /// Hollow ring; `thickness` is expressed as a fraction of the outer radius.
    Ring {
        /// Fraction of the outer radius that forms the ring wall, in `(0.0, 1.0)`.
        thickness: f32,
    },
    /// Pill-shaped capsule oriented along the velocity direction.
    Capsule,
}
