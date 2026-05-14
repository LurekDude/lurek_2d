//! Particle system module: emitters, configs, physics collision, trails, and renderer integration.
//! Owns all particle lifecycle logic from emission through update, rendering, and trail tracking.
//! Does not own the renderer pipeline or physics world; both are accessed via dedicated integration files.

/// Particle emitter configuration: shape, rate, lifetime, and per-particle property ranges.
pub mod config;
/// Emission strategy: burst, continuous, and lifetime-gated emission logic.
pub mod emission;
/// `ParticleSystem` — the main emitter update loop and particle pool manager.
pub mod emitter;
/// Math helpers: linear interpolation, colour/size/alpha keyframe evaluation.
pub mod math;
#[allow(clippy::module_inception)]
/// `Particle` — per-particle state: position, velocity, life, colour, and size.
pub mod particle;
/// Physics-driven collision response for particles against rapier colliders.
pub mod physics_collision;
/// Named preset constructors returning ready-to-use `ParticleConfig` values.
pub mod presets;
/// Translates particle state into `RenderCommand` streams for the renderer.
pub mod render;
/// Spawn-shape geometry helpers: circle, rect, cone, and point distributions.
pub mod shapes;
/// Particle trail system: `Trail` manager and `TrailPoint` ribbon segments.
pub mod trail;
/// Debug/editor visualisation overlays for emitter bounds and particle vectors.
pub mod visualization;
pub use config::{
    AreaDistribution, EmissionShape, EmitterState, InsertMode, ParticleConfig, RelativeMode,
};
pub use emitter::ParticleSystem;
pub use math::{interpolate_alphas, interpolate_colors, interpolate_sizes, lerp};
pub use particle::Particle;
pub use shapes::ParticleShape;
pub use trail::{Trail, TrailPoint};
