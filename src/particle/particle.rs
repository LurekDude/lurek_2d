//! `Particle` — per-particle mutable state updated every frame by `ParticleSystem::update`.
//! Owns position, velocity, life counter, rotation, and per-instance acceleration overrides.
//! Deliberately small; config data stays in `ParticleConfig`, not per-particle.

/// Per-particle state owned by the `ParticleSystem` pool.
#[derive(Clone, Debug)]
pub struct Particle {
    /// Current X position relative to the emitter origin.
    pub x: f32,
    /// Current Y position relative to the emitter origin.
    pub y: f32,
    /// Current X velocity in pixels per second.
    pub vx: f32,
    /// Current Y velocity in pixels per second.
    pub vy: f32,
    /// Remaining lifetime in seconds; particle is removed when this reaches zero.
    pub life: f32,
    /// Total lifetime at spawn, used to compute normalised `t = 1 - life/max_life`.
    pub max_life: f32,
    /// Current rotation angle in radians.
    pub rotation: f32,
    /// Angular velocity in radians per second.
    pub spin: f32,
    /// Per-particle radial acceleration override in pixels/sec^2.
    pub radial_accel: f32,
    /// Per-particle tangential acceleration override in pixels/sec^2.
    pub tangential_accel: f32,
    /// Per-particle linear damping coefficient.
    pub linear_damping: f32,
    /// Per-particle size variation factor in `[0.0, 1.0]`.
    pub size_variation: f32,
    /// X position at spawn time; used as origin for radial/tangential acceleration.
    pub origin_x: f32,
    /// Y position at spawn time; used as origin for radial/tangential acceleration.
    pub origin_y: f32,
    /// Seeded random value used for deterministic shrapnel polygon generation.
    pub shape_seed: u32,
}
