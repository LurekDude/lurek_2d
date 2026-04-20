//! Particle emitter configuration types and enums.

use super::shapes::ParticleShape;
use crate::runtime::resource_keys::TextureKey;

/// Area distribution mode for particle emission.
///
/// # Variants
/// - `None` â€” All particles spawn at the emitter center (no area spread).
/// - `Uniform` â€” Uniform random distribution inside a rectangle.
/// - `Normal` â€” Gaussian-approximated distribution inside a rectangle.
/// - `Ellipse` â€” Uniform random distribution inside an ellipse.
/// - `BorderEllipse` â€” Random distribution on the border of an ellipse.
/// - `BorderRectangle` â€” Random distribution on the border of a rectangle.
#[derive(Clone, Debug, Default, PartialEq)]
pub enum AreaDistribution {
    /// No area â€” all particles spawn at the emitter center.
    #[default]
    None,
    /// Uniform random distribution inside a rectangle.
    Uniform,
    /// Normal (Gaussian-approximated) distribution inside a rectangle.
    Normal,
    /// Uniform random distribution inside an ellipse.
    Ellipse,
    /// Random distribution on the border of an ellipse.
    BorderEllipse,
    /// Random distribution on the border of a rectangle.
    BorderRectangle,
}

/// Insert mode controlling where new particles are placed in the particle list.
///
/// # Variants
/// - `Top` â€” New particles added to the end of the list (drawn on top, default).
/// - `Bottom` â€” New particles added to the front of the list (drawn behind existing particles).
/// - `Random` â€” New particles inserted at a random position in the list.
#[derive(Clone, Debug, Default, PartialEq)]
pub enum InsertMode {
    /// New particles are added to the end (drawn on top).
    #[default]
    Top,
    /// New particles are added to the front (drawn behind).
    Bottom,
    /// New particles are inserted at a random position.
    Random,
}

/// Emitter lifecycle state controlling whether the system emits and updates particles.
///
/// # Variants
/// - `Active` â€” Emitting and updating particles each frame.
/// - `Paused` â€” Particles freeze in place; no new emissions and no physics updates.
/// - `Stopped` â€” No new emissions; existing particles continue ageing until dead.
#[derive(Clone, Debug, PartialEq)]
pub enum EmitterState {
    /// Emitting particles and updating existing ones.
    Active,
    /// Existing particles freeze in place; no new particles are emitted.
    Paused,
    /// No new particles emitted; existing particles continue updating until they die.
    Stopped,
}

/// Emission shape controlling where new particles spawn relative to the emitter.
///
/// # Variants
/// - `Point` â€” All particles spawn at the emitter center.
/// - `Circle` â€” Particles spawn within or on the edge of a circle.
/// - `Rectangle` â€” Particles spawn within a rectangle centered on the emitter.
/// - `Ring` â€” Particles spawn within an annulus (ring between two radii).
/// - `Line` â€” Particles spawn along a line segment.
/// - `Cone` â€” Particles spawn within a cone sector.
/// - `Star` â€” Particles spawn on the points or edges of a star polygon.
/// - `Spiral` â€” Particles spawn along an Archimedean spiral.
#[derive(Clone, Debug, Default, PartialEq)]
pub enum EmissionShape {
    /// All particles spawn at the emitter center.
    #[default]
    Point,
    /// Particles spawn within or on the edge of a circle.
    Circle {
        /// Circle radius.
        radius: f32,
        /// If true, fill the circle; if false, spawn on the edge only.
        fill: bool,
    },
    /// Particles spawn within a rectangle centered on the emitter.
    Rectangle {
        /// Rectangle width.
        width: f32,
        /// Rectangle height.
        height: f32,
    },
    /// Particles spawn within a ring (annulus).
    Ring {
        /// Inner radius of the ring.
        inner_radius: f32,
        /// Outer radius of the ring.
        outer_radius: f32,
    },
    /// Particles spawn along a line segment.
    Line {
        /// Length of the line.
        length: f32,
        /// Angle of the line in radians.
        angle: f32,
    },
    /// Particles spawn within a cone sector.
    Cone {
        /// Cone radius.
        radius: f32,
        /// Cone center angle in radians.
        angle: f32,
        /// Angular spread of the cone.
        spread: f32,
    },
    /// Particles spawn on the points or edges of a star polygon.
    Star {
        /// Number of star points (minimum 3).
        points: u32,
        /// Outer tip radius in pixels.
        outer_radius: f32,
        /// Inner notch radius in pixels.
        inner_radius: f32,
    },
    /// Particles spawn along an Archimedean spiral.
    Spiral {
        /// Number of full revolutions of the spiral.
        revolutions: f32,
        /// Maximum radius of the spiral in pixels.
        radius: f32,
    },
}

/// Relative mode controlling whether particles move with the emitter.
///
/// # Variants
/// - `Detached` â€” Particles remain in world space after emission (default).
/// - `Attached` â€” Particles move with the emitter position each frame.
#[derive(Clone, Debug, Default, PartialEq)]
pub enum RelativeMode {
    /// Particles remain in world space after emission (default).
    #[default]
    Detached,
    /// Particles move with the emitter position.
    Attached,
}

/// A point attractor that pulls (or repels) nearby particles toward a world-space location.
///
/// Added to a `ParticleSystem` instance via `ParticleSystem::add_attractor`.
/// Multiple attractors are independently accumulated each physics step.
///
/// # Fields
/// - `x` â€” World-space X coordinate of the attractor.
/// - `y` â€” World-space Y coordinate of the attractor.
/// - `strength` â€” Force magnitude in pixels/sÂ˛. Positive attracts; negative repels.
/// - `radius` â€” Influence radius in pixels. Particles outside this range are unaffected.
#[derive(Clone, Debug, PartialEq)]
pub struct Attractor {
    /// World-space X coordinate of the attractor.
    pub x: f32,
    /// World-space Y coordinate of the attractor.
    pub y: f32,
    /// Force magnitude (pixels/sÂ˛). Positive = attraction, negative = repulsion.
    pub strength: f32,
    /// Influence radius in pixels. Particles beyond this distance are unaffected.
    pub radius: f32,
}

/// Axis-aligned rectangular boundaries for particle bounce / containment.
///
/// When set on a `ParticleSystem`, particles that leave the bounds have their
/// velocity component on the crossing axis negated and scaled by `restitution`.
///
/// # Fields
/// - `x_min` / `x_max` â€” Horizontal bounds in world space (pixels).
/// - `y_min` / `y_max` â€” Vertical bounds in world space (pixels).
/// - `restitution` â€” Velocity retention factor on bounce (0 = inelastic, 1 = perfectly elastic).
#[derive(Clone, Debug, PartialEq)]
pub struct BounceBounds {
    /// Left boundary (world-space pixels).
    pub x_min: f32,
    /// Right boundary (world-space pixels).
    pub x_max: f32,
    /// Top boundary (world-space pixels, Y increases downward).
    pub y_min: f32,
    /// Bottom boundary (world-space pixels).
    pub y_max: f32,
    /// Coefficient of restitution on bounce (0 = stops, 1 = no energy loss). Clamped to 0â€“1.
    pub restitution: f32,
}

/// Configuration for a particle emitter. Controls emission rate, lifetime,
/// physics, rendering, and the full set of per-particle randomisation ranges.
///
/// All range fields (e.g. `speed_min` / `speed_max`) are sampled uniformly per particle at spawn.
///
/// # Fields
/// - `max_particles` â€” `u32`. Pool size cap.
/// - `emission_rate` â€” `f32`. Particles per second.
/// - `lifetime_min` / `lifetime_max` â€” `f32`. Particle lifetime range in seconds.
/// - `speed_min` / `speed_max` â€” `f32`. Initial speed range.
/// - `direction` â€” `f32`. Base emission angle in radians.
/// - `spread` â€” `f32`. Angular spread around `direction`.
/// - `sizes` â€” `Vec<f32>`. Keyframe sizes over particle lifetime.
/// - `colors` â€” `Vec<[f32; 4]>`. RGBA colour gradient keyframes.
/// - `emission_shape` â€” `EmissionShape`. Spawn-point distribution shape.
/// - `relative_mode` â€” `RelativeMode`. Whether particles follow the emitter.
/// - `shape` â€” `ParticleShape`. Rendered primitive type (point, rect, sprite).
/// - (additional fields: gravity, accel, damping, turbulence, drag, orbit, animation, etc.)
#[derive(Clone, Debug)]
pub struct ParticleConfig {
    /// Maximum number of live particles (pool size).
    pub max_particles: u32,
    /// Particles emitted per second while active.
    pub emission_rate: f32,
    /// Minimum lifetime of a particle in seconds.
    pub lifetime_min: f32,
    /// Maximum lifetime of a particle in seconds.
    pub lifetime_max: f32,
    /// Minimum initial speed (pixels / second).
    pub speed_min: f32,
    /// Maximum initial speed (pixels / second).
    pub speed_max: f32,
    /// Base emission direction in radians (0 = right).
    pub direction: f32,
    /// Half-angle of the emission cone in radians.
    pub spread: f32,
    /// Constant acceleration applied along the X axis (pixels / sÂ˛).
    pub gravity_x: f32,
    /// Constant acceleration applied along the Y axis (pixels / sÂ˛).
    pub gravity_y: f32,
    /// Multi-stop particle sizes interpolated over lifetime. Replaces size_start/size_end.
    pub sizes: Vec<f32>,
    /// Multi-stop particle colors interpolated over lifetime. Replaces color_start/color_end.
    pub colors: Vec<[f32; 4]>,
    /// Minimum angular velocity in radians / second.
    pub spin_min: f32,
    /// Maximum angular velocity in radians / second.
    pub spin_max: f32,
    /// Minimum initial rotation in radians.
    pub rotation_min: f32,
    /// Maximum initial rotation in radians.
    pub rotation_max: f32,
    /// Amount of spin variation (0 = none, 1 = full).
    pub spin_variation: f32,
    /// Amount of size variation (0 = none, 1 = full).
    pub size_variation: f32,
    /// Minimum linear acceleration along X axis (pixels / sÂ˛).
    pub linear_accel_x_min: f32,
    /// Maximum linear acceleration along X axis (pixels / sÂ˛).
    pub linear_accel_x_max: f32,
    /// Minimum linear acceleration along Y axis (pixels / sÂ˛).
    pub linear_accel_y_min: f32,
    /// Maximum linear acceleration along Y axis (pixels / sÂ˛).
    pub linear_accel_y_max: f32,
    /// Minimum radial acceleration (pixels / sÂ˛). Positive = away from emitter.
    pub radial_accel_min: f32,
    /// Maximum radial acceleration (pixels / sÂ˛).
    pub radial_accel_max: f32,
    /// Minimum tangential acceleration (pixels / sÂ˛).
    pub tangential_accel_min: f32,
    /// Maximum tangential acceleration (pixels / sÂ˛).
    pub tangential_accel_max: f32,
    /// Minimum linear damping factor.
    pub linear_damping_min: f32,
    /// Maximum linear damping factor.
    pub linear_damping_max: f32,
    /// Area distribution mode for emission.
    pub area_distribution: AreaDistribution,
    /// Width of the emission area in pixels.
    pub area_width: f32,
    /// Height of the emission area in pixels.
    pub area_height: f32,
    /// Rotation angle of the emission area in radians.
    pub area_angle: f32,
    /// Whether emission direction is relative to area angle.
    pub area_direction_relative: bool,
    /// Emitter lifetime in seconds. Negative means infinite.
    pub emitter_lifetime: f32,
    /// Insert mode for new particles.
    pub insert_mode: InsertMode,
    /// Render origin X offset for particles.
    pub offset_x: f32,
    /// Render origin Y offset for particles.
    pub offset_y: f32,
    /// Whether particle rotation follows velocity direction.
    pub relative_rotation: bool,
    /// Optional texture key for textured particle rendering.
    pub texture_id: Option<TextureKey>,
    /// Quad sub-regions for sprite-sheet particle rendering `[x, y, w, h]`.
    pub quads: Vec<[f32; 4]>,
    /// Alpha keyframes interpolated independently over particle lifetime.
    /// When non-empty, overrides the alpha channel from `colors`.
    pub alpha_keyframes: Vec<f32>,
    /// Emission shape controlling spawn position distribution.
    pub emission_shape: EmissionShape,
    /// Relative mode: whether particles move with the emitter or stay in world space.
    pub relative_mode: RelativeMode,
    /// Per-frame turbulence magnitude (pixels/s). Adds Gaussian noise to velocity each update.
    /// Zero (default) disables turbulence.
    pub turbulence: f32,
    /// Quadratic drag coefficient. Slows fast particles quickly while barely affecting slow ones.
    /// Formula: `velocity *= 1 / (1 + |velocity| * drag * dt)`. Zero (default) disables drag.
    pub drag: f32,
    /// Orbit angular speed in radians/second. Rotates the velocity vector around the emitter
    /// each frame, producing circular or spiral flight paths. Zero (default) disables orbit.
    pub orbit_speed: f32,
    /// Number of animation frames in the sprite sheet. When > 0, particles cycle through
    /// `quads[0..animated_frames]` at `frame_rate` FPS regardless of lifetime progress.
    /// When 0 (default) the existing lifetime-based quad selection is used.
    pub animated_frames: u32,
    /// Animation playback speed in frames per second. Only used when `animated_frames > 0`.
    pub frame_rate: f32,
    /// When `true`, color is interpolated by the particle's current speed rather than lifetime.
    /// `speed_color_min` maps to the first `colors` stop; `speed_color_max` to the last.
    pub color_by_speed: bool,
    /// Speed (pixels/s) that maps to the first color stop when `color_by_speed` is `true`.
    pub speed_color_min: f32,
    /// Speed (pixels/s) that maps to the last color stop when `color_by_speed` is `true`.
    pub speed_color_max: f32,
    /// Geometric shape used when drawing untextured particles.
    /// Ignored when `texture_id` is `Some(_)`.
    /// Defaults to `ParticleShape::Square` for backward compatibility.
    pub shape: ParticleShape,
    /// Optional `ParticleConfig` for a child emitter that bursts at each dead particle's position.
    /// When `Some`, `death_burst_count` particles are spawned using this config whenever a particle dies.
    pub death_emitter: Option<Box<ParticleConfig>>,
    /// Number of particles to burst from the death position when `death_emitter` is set.
    /// Ignored when `death_emitter` is `None`. Default is 0.
    pub death_burst_count: u32,
    /// Optional shrapnel edge count override, stored separately so the main `shape` field
    /// can remain `Shrapnel { edges }` without needing pattern-match to extract.
    /// Used for config-builder ergonomics in the Lua API only; mirrors `shape`'s `edges` value.
    pub shrapnel_edges: u8,
    /// Optional ray aspect ratio (length-to-width), mirroring `shape`'s `aspect` value.
    /// Used for config-builder ergonomics in the Lua API only.
    pub ray_aspect: f32,
    /// Optional ring thickness as a fraction of particle size (0â€“1), mirroring `shape`'s `thickness`.
    /// Used for config-builder ergonomics in the Lua API only.
    pub ring_thickness: f32,
}

impl Default for ParticleConfig {
    fn default() -> Self {
        Self {
            max_particles: 256,
            emission_rate: 10.0,
            lifetime_min: 1.0,
            lifetime_max: 2.0,
            speed_min: 50.0,
            speed_max: 100.0,
            direction: -std::f32::consts::FRAC_PI_2,
            spread: std::f32::consts::FRAC_PI_4,
            gravity_x: 0.0,
            gravity_y: 0.0,
            sizes: vec![4.0, 1.0],
            colors: vec![[1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 0.0]],
            spin_min: 0.0,
            spin_max: 0.0,
            rotation_min: 0.0,
            rotation_max: 0.0,
            spin_variation: 0.0,
            size_variation: 0.0,
            linear_accel_x_min: 0.0,
            linear_accel_x_max: 0.0,
            linear_accel_y_min: 0.0,
            linear_accel_y_max: 0.0,
            radial_accel_min: 0.0,
            radial_accel_max: 0.0,
            tangential_accel_min: 0.0,
            tangential_accel_max: 0.0,
            linear_damping_min: 0.0,
            linear_damping_max: 0.0,
            area_distribution: AreaDistribution::None,
            area_width: 0.0,
            area_height: 0.0,
            area_angle: 0.0,
            area_direction_relative: false,
            emitter_lifetime: -1.0,
            insert_mode: InsertMode::Top,
            offset_x: 0.0,
            offset_y: 0.0,
            relative_rotation: false,
            texture_id: None,
            quads: Vec::new(),
            alpha_keyframes: Vec::new(),
            emission_shape: EmissionShape::default(),
            relative_mode: RelativeMode::default(),
            turbulence: 0.0,
            drag: 0.0,
            orbit_speed: 0.0,
            animated_frames: 0,
            frame_rate: 12.0,
            color_by_speed: false,
            speed_color_min: 0.0,
            speed_color_max: 200.0,
            shape: ParticleShape::default(),
            death_emitter: None,
            death_burst_count: 0,
            shrapnel_edges: 6,
            ray_aspect: 4.0,
            ring_thickness: 0.2,
        }
    }
}

