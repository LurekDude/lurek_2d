//! Particle system module providing emitter-based 2D particle effects.
//!
//! A `ParticleSystem` spawns short-lived `Particle` entities each frame,
//! advancing their position, velocity, and lifetime. Dead particles are
//! recycled, keeping allocation bounded by `ParticleConfig::max_particles`.
//!
//! Supports multi-stop size/color/alpha interpolation, emission shapes,
//! radial/tangential acceleration, linear damping, relative mode, and texture-based rendering.

/// System sub-module.
pub mod system;
pub use system::*;
