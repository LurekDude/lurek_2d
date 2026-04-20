//! Particle system module providing emitter-based 2D particle effects.
//!
//! **Tier**: Tier 2 — Engine Extensions.
//!
//! A `ParticleSystem` spawns short-lived `Particle` entities each frame,
//! advancing their position, velocity, and lifetime. Dead particles are
//! recycled, keeping allocation bounded by `ParticleConfig::max_particles`.
//!
//! Supports multi-stop size/color/alpha interpolation, emission shapes,
//! radial/tangential acceleration, linear damping, relative mode, texture-based rendering,
//! and ten built-in geometric particle shapes (Square, Circle, Triangle, Spark, Diamond,
//! Shrapnel, Ray, Puff, Ring, Capsule).
//!
//! ## Sub-files
//!
//! | File | Purpose |
//! |------|---------|
//! | `config.rs`   | Enums (`AreaDistribution`, `InsertMode`, `EmitterState`, `EmissionShape`, `RelativeMode`) and `ParticleConfig` (~50 fields) |
//! | `shapes.rs`   | `ParticleShape` enum — ten geometric render primitives |
//! | `particle.rs` | `Particle` per-particle live state (pos, vel, life, rotation, …) |
//! | `emitter.rs`  | `ParticleSystem` simulation loop, physics integration, and `build_render_commands()` |
//! | `math.rs`     | Math helpers: `lerp`, `interpolate_sizes`, `interpolate_colors`, `interpolate_alphas` |
//! | `emission.rs` | Spawn-offset calculators for area distribution and emission shapes |
//! | `render.rs`   | `generate_render_commands()` wrappers for `ParticleSystem` and `Trail` |
//! | `trail.rs`    | `Trail` / `TrailPoint` — fading ribbon effect attached to moving objects |
//! | `visualization.rs` | CPU-side diagnostic renderers (`draw_to_image`, `draw_explosion_to_image`, etc.) |

/// Emitter configuration enums and `ParticleConfig` struct.
pub mod config;
/// Particle spawn-offset helpers for area distribution and emission shapes.
pub mod emission;
/// `ParticleSystem` simulation and draw-command generation.
pub mod emitter;
/// Math helpers for particle interpolation and random sampling.
pub mod math;
/// Per-particle live state struct.
#[allow(clippy::module_inception)]
pub mod particle;
/// GPU render-command generation interface (`generate_render_commands()` wrappers).
pub mod render;
/// `ParticleShape` geometric render primitive enum.
pub mod shapes;
/// Visualization / diagnostic renderers for headless image output.
pub mod visualization;

pub use config::{
    AreaDistribution, EmissionShape, EmitterState, InsertMode, ParticleConfig, RelativeMode,
};
pub use emitter::ParticleSystem;
pub use math::{interpolate_alphas, interpolate_colors, interpolate_sizes, lerp};
pub use particle::Particle;
pub use shapes::ParticleShape;
/// Time-fading ribbon effect (trail renderer).
pub mod trail;
pub use trail::{Trail, TrailPoint};
