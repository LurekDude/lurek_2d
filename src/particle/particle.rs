//! Individual particle data structure.

/// A single particle managed by a `ParticleSystem`.
///
/// # Fields
/// - `x` â€” `f32`.
/// - `y` â€” `f32`.
/// - `vx` â€” `f32`.
/// - `vy` â€” `f32`.
/// - `life` â€” `f32`.
/// - `max_life` â€” `f32`.
/// - `rotation` â€” `f32`.
/// - `spin` â€” `f32`.
/// - `radial_accel` â€” `f32`.
/// - `tangential_accel` â€” `f32`.
/// - `linear_damping` â€” `f32`.
/// - `size_variation` â€” `f32`.
/// - `origin_x` â€” `f32`.
/// - `origin_y` â€” `f32`.
/// - `shape_seed` â€” `u32`. Per-particle random seed for deterministic shape generation.
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
    /// Per-particle radial acceleration (pixels / sÂ˛).
    pub radial_accel: f32,
    /// Per-particle tangential acceleration (pixels / sÂ˛).
    pub tangential_accel: f32,
    /// Per-particle linear damping factor.
    pub linear_damping: f32,
    /// Per-particle size variation factor (0..1).
    pub size_variation: f32,
    /// Birth X offset (for radial direction reference).
    pub origin_x: f32,
    /// Birth Y offset (for radial direction reference).
    pub origin_y: f32,
    /// Per-particle random seed for deterministic shape generation (e.g. `Shrapnel` polygon).
    /// Set once at spawn and never mutated; ensures each particle has a stable polygon across frames.
    pub shape_seed: u32,
}

