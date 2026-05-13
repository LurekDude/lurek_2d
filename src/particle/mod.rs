pub mod config;
pub mod emission;
pub mod emitter;
pub mod math;
#[allow(clippy::module_inception)]
pub mod particle;
pub mod physics_collision;
pub mod presets;
pub mod render;
pub mod shapes;
pub mod visualization;
pub use config::{
    AreaDistribution, EmissionShape, EmitterState, InsertMode, ParticleConfig, RelativeMode,
};
pub use emitter::ParticleSystem;
pub use math::{interpolate_alphas, interpolate_colors, interpolate_sizes, lerp};
pub use particle::Particle;
pub use shapes::ParticleShape;
pub mod trail;
pub use trail::{Trail, TrailPoint};
