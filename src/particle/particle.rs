//! Individual particle data structure.

/// A single particle managed by a `ParticleSystem`.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `vx` — `f32`.
/// - `vy` — `f32`.
/// - `life` — `f32`.
/// - `max_life` — `f32`.
/// - `rotation` — `f32`.
/// - `spin` — `f32`.
/// - `radial_accel` — `f32`.
/// - `tangential_accel` — `f32`.
/// - `linear_damping` — `f32`.
/// - `size_variation` — `f32`.
/// - `origin_x` — `f32`.
/// - `origin_y` — `f32`.
#[derive(Clone, Debug)]
pub struct Particle {
    /// X position relative to emitter origin.
    pub x: f32,
    /// Y position relative to emitter origin.
    pub y: f32,
    /// Velocity X component (pixels / second).
    pub vx: f32,
    /// Velocity Y component (pixels / second).
    pub vy: f32,
    /// Remaining lifetime in seconds.
    pub life: f32,
    /// Total lifetime at spawn (for interpolation ratio).
    pub max_life: f32,
    /// Current rotation in radians.
    pub rotation: f32,
    /// Angular velocity in radians / second.
    pub spin: f32,
    /// Per-particle radial acceleration (pixels / s²).
    pub radial_accel: f32,
    /// Per-particle tangential acceleration (pixels / s²).
    pub tangential_accel: f32,
    /// Per-particle linear damping factor.
    pub linear_damping: f32,
    /// Per-particle size variation factor (0..1).
    pub size_variation: f32,
    /// Birth X offset (for radial direction reference).
    pub origin_x: f32,
    /// Birth Y offset (for radial direction reference).
    pub origin_y: f32,
}
