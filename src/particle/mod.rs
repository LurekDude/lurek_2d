//! Particle system module providing emitter-based 2D particle effects.
//!
//! A `ParticleSystem` spawns short-lived `Particle` entities each frame,
//! advancing their position, velocity, and lifetime. Dead particles are
//! recycled, keeping allocation bounded by `ParticleConfig::max_particles`.
//!
//! Supports multi-stop size/color/alpha interpolation, emission shapes,
//! radial/tangential acceleration, linear damping, relative mode, texture-based rendering,
//! and five built-in geometric particle shapes (Square, Circle, Triangle, Spark, Diamond).

pub mod config;
pub mod emission;
pub mod emitter;
pub mod math;
#[allow(clippy::module_inception)]
pub mod particle;
pub mod shapes;

pub use config::{
    AreaDistribution, EmissionShape, EmitterState, InsertMode, ParticleConfig, RelativeMode,
};
pub use emitter::ParticleSystem;
pub use math::{interpolate_alphas, interpolate_colors, interpolate_sizes, lerp};
pub use particle::Particle;
pub use shapes::ParticleShape;
