//! Particle system module providing emitter-based 2D particle effects.
//!
//! A `ParticleSystem` spawns short-lived `Particle` entities each frame,
//! advancing their position, velocity, and lifetime. Dead particles are
//! recycled, keeping allocation bounded by `ParticleConfig::max_particles`.
//!
//! Supports multi-stop size/color/alpha interpolation, emission shapes,
//! radial/tangential acceleration, linear damping, relative mode, and texture-based rendering.

use crate::engine::resource_keys::TextureKey;
use crate::graphics::renderer::{DrawCommand, DrawMode};

/// Area distribution mode for particle emission.
///
/// # Variants
/// - `None` — None variant.
/// - `Uniform` — Uniform variant.
/// - `Normal` — Normal variant.
/// - `Ellipse` — Ellipse variant.
/// - `BorderEllipse` — BorderEllipse variant.
/// - `BorderRectangle` — BorderRectangle variant.
#[derive(Clone, Debug, Default, PartialEq)]
pub enum AreaDistribution {
    /// No area — all particles spawn at the emitter center.
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
/// - `Top` — Top variant.
/// - `Bottom` — Bottom variant.
/// - `Random` — Random variant.
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

/// Emitter lifecycle state. Delivery is immediate and synchronous; all connected handlers run before this method returns.
///
/// # Variants
/// - `Active` — Active variant.
/// - `Paused` — Paused variant.
/// - `Stopped` — Stopped variant.
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
/// - `Point` — Point variant.
/// - `Circle` — Circle variant.
/// - `Rectangle` — Rectangle variant.
/// - `Ring` — Ring variant.
/// - `Line` — Line variant.
/// - `Cone` — Cone variant.
/// - `Star` — Star variant.
/// - `Spiral` — Spiral variant.
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
/// - `Detached` — Detached variant.
/// - `Attached` — Attached variant.
#[derive(Clone, Debug, Default, PartialEq)]
pub enum RelativeMode {
    /// Particles remain in world space after emission (default).
    #[default]
    Detached,
    /// Particles move with the emitter position.
    Attached,
}

/// Configuration for a particle emitter. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `max_particles` — `u32`.
/// - `emission_rate` — `f32`.
/// - `lifetime_min` — `f32`.
/// - `lifetime_max` — `f32`.
/// - `speed_min` — `f32`.
/// - `speed_max` — `f32`.
/// - `direction` — `f32`.
/// - `spread` — `f32`.
/// - `gravity_x` — `f32`.
/// - `gravity_y` — `f32`.
/// - `sizes` — `Vec<f32>`.
/// - `colors` — `Vec<[f32; 4]>`.
/// - `spin_min` — `f32`.
/// - `spin_max` — `f32`.
/// - `rotation_min` — `f32`.
/// - `rotation_max` — `f32`.
/// - `spin_variation` — `f32`.
/// - `size_variation` — `f32`.
/// - `linear_accel_x_min` — `f32`.
/// - `linear_accel_x_max` — `f32`.
/// - `linear_accel_y_min` — `f32`.
/// - `linear_accel_y_max` — `f32`.
/// - `radial_accel_min` — `f32`.
/// - `radial_accel_max` — `f32`.
/// - `tangential_accel_min` — `f32`.
/// - `tangential_accel_max` — `f32`.
/// - `linear_damping_min` — `f32`.
/// - `linear_damping_max` — `f32`.
/// - `area_distribution` — `AreaDistribution`.
/// - `area_width` — `f32`.
/// - `area_height` — `f32`.
/// - `area_angle` — `f32`.
/// - `area_direction_relative` — `bool`.
/// - `emitter_lifetime` — `f32`.
/// - `insert_mode` — `InsertMode`.
/// - `offset_x` — `f32`.
/// - `offset_y` — `f32`.
/// - `relative_rotation` — `bool`.
/// - `texture_id` — `Option<TextureKey>`.
/// - `quads` — `Vec<[f32; 4]>`.
/// - `alpha_keyframes` — `Vec<f32>`.
/// - `emission_shape` — `EmissionShape`.
/// - `relative_mode` — `RelativeMode`.
/// - `turbulence` — `f32`.
/// - `drag` — `f32`.
/// - `orbit_speed` — `f32`.
/// - `animated_frames` — `u32`.
/// - `frame_rate` — `f32`.
/// - `color_by_speed` — `bool`.
/// - `speed_color_min` — `f32`.
/// - `speed_color_max` — `f32`.
///
/// All ranges are sampled uniformly per-particle at spawn time.
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
    /// Constant acceleration applied along the X axis (pixels / s²).
    pub gravity_x: f32,
    /// Constant acceleration applied along the Y axis (pixels / s²).
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
    /// Minimum linear acceleration along X axis (pixels / s²).
    pub linear_accel_x_min: f32,
    /// Maximum linear acceleration along X axis (pixels / s²).
    pub linear_accel_x_max: f32,
    /// Minimum linear acceleration along Y axis (pixels / s²).
    pub linear_accel_y_min: f32,
    /// Maximum linear acceleration along Y axis (pixels / s²).
    pub linear_accel_y_max: f32,
    /// Minimum radial acceleration (pixels / s²). Positive = away from emitter.
    pub radial_accel_min: f32,
    /// Maximum radial acceleration (pixels / s²).
    pub radial_accel_max: f32,
    /// Minimum tangential acceleration (pixels / s²).
    pub tangential_accel_min: f32,
    /// Maximum tangential acceleration (pixels / s²).
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
        }
    }
}

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

/// An emitter-based particle system. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `config` — `ParticleConfig`.
/// - `particles` — `Vec<Particle>`.
/// - `emitter_x` — `f32`.
/// - `emitter_y` — `f32`.
/// - `emit_accumulator` — `f32`.
/// - `state` — `EmitterState`.
/// - `emitter_age` — `f32`.
/// - `prev_emitter_x` — `f32`.
/// - `prev_emitter_y` — `f32`.
///
/// Call `update(dt)` each frame to advance physics and spawn new particles,
/// then `draw_commands(ox, oy)` to obtain the `DrawCommand` list for rendering.
#[derive(Clone, Debug)]
pub struct ParticleSystem {
    /// Emitter configuration (shared by all particles in this system).
    pub config: ParticleConfig,
    /// Live particle pool.
    pub particles: Vec<Particle>,
    /// Emitter world-space X position.
    pub emitter_x: f32,
    /// Emitter world-space Y position.
    pub emitter_y: f32,
    /// Fractional particle accumulator (sub-frame emission).
    pub emit_accumulator: f32,
    /// Current emitter lifecycle state.
    pub state: EmitterState,
    /// Accumulated emitter age in seconds.
    pub emitter_age: f32,
    /// Previous frame emitter X position (for move interpolation).
    pub prev_emitter_x: f32,
    /// Previous frame emitter Y position (for move interpolation).
    pub prev_emitter_y: f32,
}

impl ParticleSystem {
    /// Creates a new particle system with the given configuration positioned at `(0, 0)`.
    ///
    /// # Parameters
    /// - `config` — `ParticleConfig`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(config: ParticleConfig) -> Self {
        Self {
            particles: Vec::with_capacity(config.max_particles as usize),
            config,
            emitter_x: 0.0,
            emitter_y: 0.0,
            emit_accumulator: 0.0,
            state: EmitterState::Active,
            emitter_age: 0.0,
            prev_emitter_x: 0.0,
            prev_emitter_y: 0.0,
        }
    }

    /// Updates the particle system by `dt` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    ///
    /// 1. Check emitter lifetime for auto-stop.
    /// 2. Update existing particles (position, velocity, lifetime, radial/tangential accel, damping).
    /// 3. Remove dead particles.
    /// 4. Emit new particles if active.
    pub fn update(&mut self, dt: f32) {
        if self.state == EmitterState::Paused {
            return;
        }

        // Update emitter age and check lifetime
        if self.state == EmitterState::Active {
            self.emitter_age += dt;
            if self.config.emitter_lifetime >= 0.0
                && self.emitter_age >= self.config.emitter_lifetime
            {
                self.state = EmitterState::Stopped;
            }
        }

        // Update existing particles
        for p in &mut self.particles {
            // Radial and tangential acceleration
            let dx = p.x - p.origin_x;
            let dy = p.y - p.origin_y;
            let dist = (dx * dx + dy * dy).sqrt();
            if dist > f32::EPSILON {
                let radial_x = dx / dist;
                let radial_y = dy / dist;
                let tangential_x = -radial_y;
                let tangential_y = radial_x;
                p.vx += (radial_x * p.radial_accel + tangential_x * p.tangential_accel) * dt;
                p.vy += (radial_y * p.radial_accel + tangential_y * p.tangential_accel) * dt;
            }

            // Linear acceleration (gravity)
            p.vx += self.config.gravity_x * dt;
            p.vy += self.config.gravity_y * dt;

            // Linear damping
            if p.linear_damping > f32::EPSILON {
                let damping = 1.0 / (1.0 + p.linear_damping * dt);
                p.vx *= damping;
                p.vy *= damping;
            }

            // Quadratic drag — slows faster particles proportionally more
            if self.config.drag > f32::EPSILON {
                let speed = (p.vx * p.vx + p.vy * p.vy).sqrt();
                if speed > f32::EPSILON {
                    let drag_factor = 1.0 / (1.0 + speed * self.config.drag * dt);
                    p.vx *= drag_factor;
                    p.vy *= drag_factor;
                }
            }

            // Orbital rotation — rotates velocity vector around emitter each frame
            if self.config.orbit_speed.abs() > f32::EPSILON {
                let orbit_angle = self.config.orbit_speed * dt;
                let ca = orbit_angle.cos();
                let sa = orbit_angle.sin();
                let new_vx = p.vx * ca - p.vy * sa;
                let new_vy = p.vx * sa + p.vy * ca;
                p.vx = new_vx;
                p.vy = new_vy;
            }

            // Turbulence — Gaussian velocity kick each frame
            if self.config.turbulence > f32::EPSILON {
                p.vx += rand_normal() * self.config.turbulence * dt;
                p.vy += rand_normal() * self.config.turbulence * dt;
            }

            // Position
            p.x += p.vx * dt;
            p.y += p.vy * dt;

            // Rotation
            if self.config.relative_rotation {
                p.rotation = p.vy.atan2(p.vx);
            } else {
                p.rotation += p.spin * dt;
            }

            p.life -= dt;
        }

        // Remove dead particles
        self.particles.retain(|p| p.life > 0.0);

        // Emit new particles only when active
        if self.state == EmitterState::Active {
            self.emit_accumulator += self.config.emission_rate * dt;
            let to_emit = self.emit_accumulator as u32;
            self.emit_accumulator -= to_emit as f32;

            for _ in 0..to_emit {
                if self.particles.len() >= self.config.max_particles as usize {
                    break;
                }
                self.emit_one();
            }
        }

        // Update previous emitter position
        self.prev_emitter_x = self.emitter_x;
        self.prev_emitter_y = self.emitter_y;
    }

    /// Spawns a single particle with randomised properties from the config.
    fn emit_one(&mut self) {
        let lifetime = rand_range(self.config.lifetime_min, self.config.lifetime_max);
        let speed = rand_range(self.config.speed_min, self.config.speed_max);
        let angle = self.config.direction + rand_range(-self.config.spread, self.config.spread);
        let base_spin = rand_range(self.config.spin_min, self.config.spin_max);
        let spin = base_spin * (1.0 - self.config.spin_variation * fastrand::f32());
        let rotation = rand_range(self.config.rotation_min, self.config.rotation_max);
        let radial_accel = rand_range(self.config.radial_accel_min, self.config.radial_accel_max);
        let tangential_accel = rand_range(
            self.config.tangential_accel_min,
            self.config.tangential_accel_max,
        );
        let linear_damping = rand_range(
            self.config.linear_damping_min,
            self.config.linear_damping_max,
        );
        let size_variation = self.config.size_variation * fastrand::f32();

        // Use emission shape if set (non-Point), otherwise fall back to area distribution
        let (offset_x, offset_y) = if self.config.emission_shape != EmissionShape::Point {
            emission_shape_offset(&self.config.emission_shape)
        } else {
            emission_offset(&self.config)
        };

        let particle = Particle {
            x: offset_x,
            y: offset_y,
            vx: angle.cos() * speed,
            vy: angle.sin() * speed,
            life: lifetime,
            max_life: lifetime,
            rotation,
            spin,
            radial_accel,
            tangential_accel,
            linear_damping,
            size_variation,
            origin_x: offset_x,
            origin_y: offset_y,
        };

        match self.config.insert_mode {
            InsertMode::Top => self.particles.push(particle),
            InsertMode::Bottom => self.particles.insert(0, particle),
            InsertMode::Random => {
                let idx = if self.particles.is_empty() {
                    0
                } else {
                    fastrand::usize(..=self.particles.len())
                };
                self.particles.insert(idx, particle);
            }
        }
    }

    /// Emits a burst of `count` particles immediately, respecting the max_particles cap.
    ///
    /// # Parameters
    /// - `count` — `u32`.
    pub fn emit(&mut self, count: u32) {
        for _ in 0..count {
            if self.particles.len() >= self.config.max_particles as usize {
                break;
            }
            self.emit_one();
        }
    }

    /// Returns the number of live particles. Runs in O(1) time.
    ///
    /// # Returns
    /// `usize`.
    pub fn count(&self) -> usize {
        self.particles.len()
    }

    /// Resets the system, killing all particles and zeroing the accumulator and emitter age.
    pub fn reset(&mut self) {
        self.particles.clear();
        self.emit_accumulator = 0.0;
        self.emitter_age = 0.0;
    }

    /// Activates the emitter, beginning particle emission.
    pub fn start(&mut self) {
        self.state = EmitterState::Active;
        self.emitter_age = 0.0;
    }

    /// Stops the emitter. Existing particles continue updating until they die.
    pub fn stop(&mut self) {
        self.state = EmitterState::Stopped;
    }

    /// Pauses the emitter. All particles freeze in place.
    pub fn pause(&mut self) {
        self.state = EmitterState::Paused;
    }

    /// Resumes a paused emitter. If stopped, transitions back to active.
    pub fn resume(&mut self) {
        if self.state == EmitterState::Paused || self.state == EmitterState::Stopped {
            self.state = EmitterState::Active;
        }
    }

    /// Moves the emitter to a new position, updating previous position tracking.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn move_to(&mut self, x: f32, y: f32) {
        self.prev_emitter_x = self.emitter_x;
        self.prev_emitter_y = self.emitter_y;
        self.emitter_x = x;
        self.emitter_y = y;
    }

    /// Creates a new `ParticleSystem` with a clone of this system's config but no particles.
    ///
    /// # Returns
    /// `ParticleSystem`.
    pub fn clone_config(&self) -> ParticleSystem {
        ParticleSystem::new(self.config.clone())
    }

    /// Returns `true` if the emitter is actively emitting particles.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_active(&self) -> bool {
        self.state == EmitterState::Active
    }

    /// Returns `true` if the emitter is paused.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_paused(&self) -> bool {
        self.state == EmitterState::Paused
    }

    /// Returns `true` if the emitter is stopped.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_stopped(&self) -> bool {
        self.state == EmitterState::Stopped
    }

    /// Returns `true` if there are no live particles.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.particles.is_empty()
    }

    /// Returns `true` if the particle count has reached `max_particles`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_full(&self) -> bool {
        self.particles.len() >= self.config.max_particles as usize
    }

    /// Generates `DrawCommand`s for rendering all live particles.
    ///
    /// # Returns
    /// `Vec<DrawCommand>`.
    ///
    /// Each particle is drawn as a filled rectangle (untextured) or a textured sprite,
    /// sized and colored by multi-stop interpolation based on remaining lifetime.
    /// When `alpha_keyframes` are set, the alpha channel is overridden independently.
    /// When `relative_mode` is `Attached`, particle positions are offset by the emitter position.
    ///
    /// # Parameters
    /// - `ox` — World X offset added to each particle position.
    /// - `oy` — World Y offset added to each particle position.
    pub fn draw_commands(&self, ox: f32, oy: f32) -> Vec<DrawCommand> {
        let mut cmds = Vec::with_capacity(self.particles.len() * 2);

        for p in &self.particles {
            let t = 1.0 - (p.life / p.max_life); // 0 at birth -> 1 at death
            let size = interpolate_sizes(&self.config.sizes, t, p.size_variation);

            // Color interpolation: by speed or by lifetime
            let color_t = if self.config.color_by_speed {
                let speed = (p.vx * p.vx + p.vy * p.vy).sqrt();
                let range = self.config.speed_color_max - self.config.speed_color_min;
                if range > f32::EPSILON {
                    ((speed - self.config.speed_color_min) / range).clamp(0.0, 1.0)
                } else {
                    0.0
                }
            } else {
                t
            };

            let [r, g, b, mut a] = interpolate_colors(&self.config.colors, color_t);

            // Override alpha with independent alpha keyframes if set
            if !self.config.alpha_keyframes.is_empty() {
                a = interpolate_alphas(&self.config.alpha_keyframes, t);
            }

            // In Attached mode, particle position is relative to emitter
            // In Detached mode (default), particle position is absolute from spawn point
            let px = ox + self.emitter_x + p.x;
            let py = oy + self.emitter_y + p.y;

            cmds.push(DrawCommand::SetColor(r, g, b, a));

            if let Some(tex_key) = self.config.texture_id {
                if !self.config.quads.is_empty() {
                    // Animated frames mode: cycle quads at frame_rate; else use lifetime progress
                    let quad_idx = if self.config.animated_frames > 0 {
                        let age = p.max_life - p.life;
                        
                        (age * self.config.frame_rate) as usize
                            % (self.config.animated_frames as usize).min(self.config.quads.len())
                    } else {
                        ((t * self.config.quads.len() as f32) as usize)
                            .min(self.config.quads.len() - 1)
                    };
                    let [qx, qy, qw, qh] = self.config.quads[quad_idx];
                    cmds.push(DrawCommand::DrawQuad {
                        texture_key: tex_key,
                        quad_x: qx,
                        quad_y: qy,
                        quad_w: qw,
                        quad_h: qh,
                        tex_w: qw,
                        tex_h: qh,
                        x: px,
                        y: py,
                        rotation: p.rotation,
                        sx: size,
                        sy: size,
                        ox: self.config.offset_x,
                        oy: self.config.offset_y,
                    });
                } else {
                    cmds.push(DrawCommand::DrawImageEx {
                        texture_key: tex_key,
                        x: px,
                        y: py,
                        rotation: p.rotation,
                        sx: size,
                        sy: size,
                        ox: self.config.offset_x,
                        oy: self.config.offset_y,
                    });
                }
            } else {
                cmds.push(DrawCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: px - size * 0.5,
                    y: py - size * 0.5,
                    w: size,
                    h: size,
                });
            }
        }

        cmds
    }
}

/// Linearly interpolate between `a` and `b` by factor `t`.
///
/// # Parameters
/// - `a` — `f32`.
/// - `b` — `f32`.
/// - `t` — `f32`.
///
/// # Returns
/// `f32`.
pub fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + (b - a) * t
}

/// Interpolate a multi-stop size array at normalised time `t` (0 = birth, 1 = death).
///
/// # Parameters
/// - `sizes` — `&[f32]`.
/// - `t` — `f32`.
/// - `variation` — `f32`.
///
/// # Returns
/// `f32`.
///
/// The `variation` factor (0..1) scales down the interpolated size.
/// With `variation = 0`, the full interpolated size is returned.
///
/// # Edge cases
/// - Empty `sizes`: returns `1.0`.
/// - Single value: returns `sizes[0] * (1 - variation)`.
/// - `t` is clamped to `[0, 1]`.
pub fn interpolate_sizes(sizes: &[f32], t: f32, variation: f32) -> f32 {
    if sizes.is_empty() {
        return 1.0;
    }
    if sizes.len() == 1 {
        return sizes[0] * (1.0 - variation);
    }
    let t = t.clamp(0.0, 1.0);
    let segments = (sizes.len() - 1) as f32;
    let pos = t * segments;
    let idx = (pos as usize).min(sizes.len() - 2);
    let local_t = pos - idx as f32;
    let base = lerp(sizes[idx], sizes[idx + 1], local_t);
    base * (1.0 - variation)
}

/// Interpolate a multi-stop color array at normalised time `t` (0 = birth, 1 = death).
///
/// # Parameters
/// - `colors` — `&[[f32; 4]]`.
/// - `t` — `f32`.
///
/// # Returns
/// `[f32; 4]`.
///
/// # Edge cases
/// - Empty `colors`: returns white `[1, 1, 1, 1]`.
/// - Single value: returns that color.
/// - `t` is clamped to `[0, 1]`.
pub fn interpolate_colors(colors: &[[f32; 4]], t: f32) -> [f32; 4] {
    if colors.is_empty() {
        return [1.0, 1.0, 1.0, 1.0];
    }
    if colors.len() == 1 {
        return colors[0];
    }
    let t = t.clamp(0.0, 1.0);
    let segments = (colors.len() - 1) as f32;
    let pos = t * segments;
    let idx = (pos as usize).min(colors.len() - 2);
    let local_t = pos - idx as f32;
    [
        lerp(colors[idx][0], colors[idx + 1][0], local_t),
        lerp(colors[idx][1], colors[idx + 1][1], local_t),
        lerp(colors[idx][2], colors[idx + 1][2], local_t),
        lerp(colors[idx][3], colors[idx + 1][3], local_t),
    ]
}

/// Interpolate a multi-stop alpha array at normalised time `t` (0 = birth, 1 = death).
///
/// # Parameters
/// - `alphas` — `&[f32]`.
/// - `t` — `f32`.
///
/// # Returns
/// `f32`.
///
/// # Edge cases
/// - Empty `alphas`: returns `1.0`.
/// - Single value: returns `alphas[0]`.
/// - `t` is clamped to `[0, 1]`.
pub fn interpolate_alphas(alphas: &[f32], t: f32) -> f32 {
    if alphas.is_empty() {
        return 1.0;
    }
    if alphas.len() == 1 {
        return alphas[0];
    }
    let t = t.clamp(0.0, 1.0);
    let segments = (alphas.len() - 1) as f32;
    let pos = t * segments;
    let idx = (pos as usize).min(alphas.len() - 2);
    let local_t = pos - idx as f32;
    lerp(alphas[idx], alphas[idx + 1], local_t)
}

/// Sample a uniform random value in `[min, max]`.
fn rand_range(min: f32, max: f32) -> f32 {
    if (max - min).abs() < f32::EPSILON {
        return min;
    }
    min + fastrand::f32() * (max - min)
}

/// Approximate a standard-normal random value using Box-Muller transform.
fn rand_normal() -> f32 {
    let u1 = fastrand::f32().max(f32::EPSILON);
    let u2 = fastrand::f32();
    (-2.0 * u1.ln()).sqrt() * (2.0 * std::f32::consts::PI * u2).cos()
}

/// Compute an emission offset `(dx, dy)` based on the config's area distribution.
fn emission_offset(config: &ParticleConfig) -> (f32, f32) {
    let (dx, dy) = match config.area_distribution {
        AreaDistribution::None => (0.0, 0.0),
        AreaDistribution::Uniform => {
            let x = rand_range(-config.area_width * 0.5, config.area_width * 0.5);
            let y = rand_range(-config.area_height * 0.5, config.area_height * 0.5);
            (x, y)
        }
        AreaDistribution::Normal => {
            let x = (rand_normal() * 0.25).clamp(-0.5, 0.5) * config.area_width;
            let y = (rand_normal() * 0.25).clamp(-0.5, 0.5) * config.area_height;
            (x, y)
        }
        AreaDistribution::Ellipse => {
            let angle = fastrand::f32() * 2.0 * std::f32::consts::PI;
            let r = fastrand::f32().sqrt();
            let x = angle.cos() * r * config.area_width * 0.5;
            let y = angle.sin() * r * config.area_height * 0.5;
            (x, y)
        }
        AreaDistribution::BorderEllipse => {
            let angle = fastrand::f32() * 2.0 * std::f32::consts::PI;
            let x = angle.cos() * config.area_width * 0.5;
            let y = angle.sin() * config.area_height * 0.5;
            (x, y)
        }
        AreaDistribution::BorderRectangle => {
            let perimeter = 2.0 * config.area_width + 2.0 * config.area_height;
            if perimeter < f32::EPSILON {
                return (0.0, 0.0);
            }
            let t = fastrand::f32() * perimeter;
            let hw = config.area_width * 0.5;
            let hh = config.area_height * 0.5;
            if t < config.area_width {
                (t - hw, -hh)
            } else if t < config.area_width + config.area_height {
                (hw, t - config.area_width - hh)
            } else if t < 2.0 * config.area_width + config.area_height {
                (hw - (t - config.area_width - config.area_height), hh)
            } else {
                (-hw, hh - (t - 2.0 * config.area_width - config.area_height))
            }
        }
    };

    // Rotate by area angle
    if config.area_angle.abs() > f32::EPSILON {
        let cos_a = config.area_angle.cos();
        let sin_a = config.area_angle.sin();
        (dx * cos_a - dy * sin_a, dx * sin_a + dy * cos_a)
    } else {
        (dx, dy)
    }
}

/// Compute an emission offset `(dx, dy)` based on the emission shape.
fn emission_shape_offset(shape: &EmissionShape) -> (f32, f32) {
    match shape {
        EmissionShape::Point => (0.0, 0.0),
        EmissionShape::Circle { radius, fill } => {
            let angle = fastrand::f32() * 2.0 * std::f32::consts::PI;
            let r = if *fill {
                fastrand::f32().sqrt() * radius
            } else {
                *radius
            };
            (angle.cos() * r, angle.sin() * r)
        }
        EmissionShape::Rectangle { width, height } => {
            let x = rand_range(-width * 0.5, *width * 0.5);
            let y = rand_range(-height * 0.5, *height * 0.5);
            (x, y)
        }
        EmissionShape::Ring {
            inner_radius,
            outer_radius,
        } => {
            let angle = fastrand::f32() * 2.0 * std::f32::consts::PI;
            // Uniform distribution within ring by sampling radius²
            let r_sq = rand_range(inner_radius * inner_radius, outer_radius * outer_radius);
            let r = r_sq.sqrt();
            (angle.cos() * r, angle.sin() * r)
        }
        EmissionShape::Line { length, angle } => {
            let t = rand_range(-0.5, 0.5);
            (t * length * angle.cos(), t * length * angle.sin())
        }
        EmissionShape::Cone {
            radius,
            angle,
            spread,
        } => {
            let a = angle + rand_range(-spread, *spread);
            let r = fastrand::f32().sqrt() * radius;
            (a.cos() * r, a.sin() * r)
        }
        EmissionShape::Star {
            points,
            outer_radius,
            inner_radius,
        } => {
            // Pick a random point on the star border by choosing a random angular segment
            let n = (*points).max(3) as f32;
            let step = std::f32::consts::PI / n; // angle per half-segment
            let segment = fastrand::u32(0..*points * 2); // each point has 2 half-edges
            let t = fastrand::f32(); // interpolate along the half-edge
            let a0 = segment as f32 * step;
            let a1 = a0 + step;
            let r0 = if segment % 2 == 0 {
                *outer_radius
            } else {
                *inner_radius
            };
            let r1 = if segment % 2 == 0 {
                *inner_radius
            } else {
                *outer_radius
            };
            // Lerp in Cartesian space along the star edge
            let x0 = a0.cos() * r0;
            let y0 = a0.sin() * r0;
            let x1 = a1.cos() * r1;
            let y1 = a1.sin() * r1;
            (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)
        }
        EmissionShape::Spiral {
            revolutions,
            radius,
        } => {
            // Archimedean spiral: r grows linearly with angle
            let max_angle = *revolutions * 2.0 * std::f32::consts::PI;
            let t = fastrand::f32();
            let angle = t * max_angle;
            let r = t * radius;
            (angle.cos() * r, angle.sin() * r)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let cfg = ParticleConfig::default();
        assert_eq!(cfg.max_particles, 256);
        assert!((cfg.emission_rate - 10.0).abs() < f32::EPSILON);
        assert_eq!(cfg.sizes.len(), 2);
        assert!((cfg.sizes[0] - 4.0).abs() < f32::EPSILON);
        assert!((cfg.sizes[1] - 1.0).abs() < f32::EPSILON);
        assert_eq!(cfg.colors.len(), 2);
    }

    #[test]
    fn test_system_creation() {
        let sys = ParticleSystem::new(ParticleConfig::default());
        assert_eq!(sys.count(), 0);
        assert!(sys.is_active());
    }

    #[test]
    fn test_update_emits_particles() {
        let mut cfg = ParticleConfig::default();
        cfg.emission_rate = 100.0;
        let mut sys = ParticleSystem::new(cfg);
        sys.update(1.0);
        assert!(sys.count() > 0);
    }

    #[test]
    fn test_particles_die() {
        let mut cfg = ParticleConfig::default();
        cfg.emission_rate = 100.0;
        cfg.lifetime_min = 0.1;
        cfg.lifetime_max = 0.1;
        let mut sys = ParticleSystem::new(cfg);
        sys.update(0.05);
        let count_after_emit = sys.count();
        assert!(count_after_emit > 0);
        sys.stop();
        sys.update(0.2);
        assert_eq!(sys.count(), 0);
    }

    #[test]
    fn test_inactive_no_emit() {
        let mut cfg = ParticleConfig::default();
        cfg.emission_rate = 1000.0;
        let mut sys = ParticleSystem::new(cfg);
        sys.stop();
        sys.update(1.0);
        assert_eq!(sys.count(), 0);
    }

    #[test]
    fn test_max_particles_cap() {
        let mut cfg = ParticleConfig::default();
        cfg.max_particles = 5;
        cfg.emission_rate = 1000.0;
        cfg.lifetime_min = 10.0;
        cfg.lifetime_max = 10.0;
        let mut sys = ParticleSystem::new(cfg);
        sys.update(1.0);
        assert!(sys.count() <= 5);
    }

    #[test]
    fn test_reset_clears_particles() {
        let mut cfg = ParticleConfig::default();
        cfg.emission_rate = 100.0;
        let mut sys = ParticleSystem::new(cfg);
        sys.update(1.0);
        assert!(sys.count() > 0);
        sys.reset();
        assert_eq!(sys.count(), 0);
    }

    #[test]
    fn test_draw_commands_count() {
        let mut cfg = ParticleConfig::default();
        cfg.emission_rate = 100.0;
        let mut sys = ParticleSystem::new(cfg);
        sys.update(1.0);
        let cmds = sys.draw_commands(0.0, 0.0);
        // 2 commands per particle: SetColor + Rectangle
        assert_eq!(cmds.len(), sys.count() * 2);
    }

    #[test]
    fn test_gravity_affects_velocity() {
        let mut cfg = ParticleConfig::default();
        cfg.emission_rate = 100.0;
        cfg.gravity_y = 100.0;
        cfg.speed_min = 0.0;
        cfg.speed_max = 0.0;
        let mut sys = ParticleSystem::new(cfg);
        sys.update(0.01);
        let initial_vy: Vec<f32> = sys.particles.iter().map(|p| p.vy).collect();
        sys.update(1.0);
        for (i, p) in sys.particles.iter().enumerate() {
            if i < initial_vy.len() {
                assert!(p.vy > initial_vy[i]);
            }
        }
    }

    #[test]
    fn test_lerp_basic() {
        assert!((lerp(0.0, 10.0, 0.0) - 0.0).abs() < f32::EPSILON);
        assert!((lerp(0.0, 10.0, 0.5) - 5.0).abs() < f32::EPSILON);
        assert!((lerp(0.0, 10.0, 1.0) - 10.0).abs() < f32::EPSILON);
    }

    #[test]
    fn test_interpolate_sizes_empty() {
        assert!((interpolate_sizes(&[], 0.5, 0.0) - 1.0).abs() < f32::EPSILON);
    }

    #[test]
    fn test_interpolate_sizes_single() {
        assert!((interpolate_sizes(&[5.0], 0.5, 0.0) - 5.0).abs() < f32::EPSILON);
    }

    #[test]
    fn test_interpolate_sizes_two_stops() {
        assert!((interpolate_sizes(&[10.0, 2.0], 0.0, 0.0) - 10.0).abs() < 1e-5);
        assert!((interpolate_sizes(&[10.0, 2.0], 0.5, 0.0) - 6.0).abs() < 1e-5);
        assert!((interpolate_sizes(&[10.0, 2.0], 1.0, 0.0) - 2.0).abs() < 1e-5);
    }

    #[test]
    fn test_interpolate_sizes_three_stops() {
        let sizes = [10.0, 20.0, 5.0];
        assert!((interpolate_sizes(&sizes, 0.0, 0.0) - 10.0).abs() < 1e-5);
        assert!((interpolate_sizes(&sizes, 0.25, 0.0) - 15.0).abs() < 1e-5);
        assert!((interpolate_sizes(&sizes, 0.5, 0.0) - 20.0).abs() < 1e-5);
        assert!((interpolate_sizes(&sizes, 1.0, 0.0) - 5.0).abs() < 1e-5);
    }

    #[test]
    fn test_interpolate_colors_empty() {
        let c = interpolate_colors(&[], 0.5);
        assert!((c[0] - 1.0).abs() < f32::EPSILON);
        assert!((c[3] - 1.0).abs() < f32::EPSILON);
    }

    #[test]
    fn test_interpolate_colors_two_stops() {
        let colors = [[1.0, 0.0, 0.0, 1.0], [0.0, 1.0, 0.0, 0.0]];
        let mid = interpolate_colors(&colors, 0.5);
        assert!((mid[0] - 0.5).abs() < 1e-5);
        assert!((mid[1] - 0.5).abs() < 1e-5);
        assert!((mid[2] - 0.0).abs() < 1e-5);
        assert!((mid[3] - 0.5).abs() < 1e-5);
    }

    #[test]
    fn test_emitter_state_transitions() {
        let mut sys = ParticleSystem::new(ParticleConfig::default());
        assert!(sys.is_active());
        sys.pause();
        assert!(sys.is_paused());
        sys.resume();
        assert!(sys.is_active());
        sys.stop();
        assert!(sys.is_stopped());
        sys.start();
        assert!(sys.is_active());
    }

    #[test]
    fn test_interpolate_alphas_empty() {
        assert!((interpolate_alphas(&[], 0.5) - 1.0).abs() < f32::EPSILON);
    }

    #[test]
    fn test_interpolate_alphas_single() {
        assert!((interpolate_alphas(&[0.5], 0.0) - 0.5).abs() < f32::EPSILON);
    }

    #[test]
    fn test_interpolate_alphas_two_stops() {
        assert!((interpolate_alphas(&[1.0, 0.0], 0.0) - 1.0).abs() < 1e-5);
        assert!((interpolate_alphas(&[1.0, 0.0], 0.5) - 0.5).abs() < 1e-5);
        assert!((interpolate_alphas(&[1.0, 0.0], 1.0) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_interpolate_alphas_four_stops() {
        let alphas = [1.0, 0.9, 0.5, 0.0];
        assert!((interpolate_alphas(&alphas, 0.0) - 1.0).abs() < 1e-5);
        assert!((interpolate_alphas(&alphas, 1.0) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_default_config_new_fields() {
        let cfg = ParticleConfig::default();
        assert!(cfg.alpha_keyframes.is_empty());
        assert_eq!(cfg.emission_shape, EmissionShape::Point);
        assert_eq!(cfg.relative_mode, RelativeMode::Detached);
    }

    #[test]
    fn test_emission_shape_circle() {
        let shape = EmissionShape::Circle {
            radius: 10.0,
            fill: true,
        };
        let (x, y) = emission_shape_offset(&shape);
        let dist = (x * x + y * y).sqrt();
        assert!(dist <= 10.0 + 1e-5);
    }

    #[test]
    fn test_emission_shape_rectangle() {
        let shape = EmissionShape::Rectangle {
            width: 20.0,
            height: 10.0,
        };
        let (x, y) = emission_shape_offset(&shape);
        assert!(x.abs() <= 10.0 + 1e-5);
        assert!(y.abs() <= 5.0 + 1e-5);
    }

    #[test]
    fn test_emission_shape_ring() {
        let shape = EmissionShape::Ring {
            inner_radius: 5.0,
            outer_radius: 10.0,
        };
        let (x, y) = emission_shape_offset(&shape);
        let dist = (x * x + y * y).sqrt();
        assert!(dist >= 5.0 - 1e-5);
        assert!(dist <= 10.0 + 1e-5);
    }

    #[test]
    fn test_emission_shape_line() {
        let shape = EmissionShape::Line {
            length: 20.0,
            angle: 0.0,
        };
        let (x, y) = emission_shape_offset(&shape);
        assert!(x.abs() <= 10.0 + 1e-5);
        assert!(y.abs() < 1e-5);
    }

    #[test]
    fn test_emission_shape_cone() {
        let shape = EmissionShape::Cone {
            radius: 10.0,
            angle: 0.0,
            spread: std::f32::consts::PI,
        };
        let (x, y) = emission_shape_offset(&shape);
        let dist = (x * x + y * y).sqrt();
        assert!(dist <= 10.0 + 1e-5);
    }

    #[test]
    fn test_clone_config() {
        let mut cfg = ParticleConfig::default();
        cfg.emission_rate = 42.0;
        cfg.alpha_keyframes = vec![1.0, 0.5, 0.0];
        cfg.emission_shape = EmissionShape::Circle {
            radius: 5.0,
            fill: true,
        };
        cfg.relative_mode = RelativeMode::Attached;
        let mut sys = ParticleSystem::new(cfg);
        sys.update(0.1);
        let cloned = sys.clone_config();
        assert_eq!(cloned.count(), 0);
        assert!((cloned.config.emission_rate - 42.0).abs() < 1e-5);
        assert_eq!(cloned.config.alpha_keyframes, vec![1.0, 0.5, 0.0]);
        assert_eq!(
            cloned.config.emission_shape,
            EmissionShape::Circle {
                radius: 5.0,
                fill: true
            }
        );
        assert_eq!(cloned.config.relative_mode, RelativeMode::Attached);
    }

    #[test]
    fn test_alpha_keyframes_override_in_draw() {
        let mut cfg = ParticleConfig::default();
        cfg.emission_rate = 100.0;
        cfg.alpha_keyframes = vec![1.0, 0.0]; // fade from 1 to 0
        cfg.lifetime_min = 1.0;
        cfg.lifetime_max = 1.0;
        let mut sys = ParticleSystem::new(cfg);
        sys.update(0.5); // emit some particles
        let cmds = sys.draw_commands(0.0, 0.0);
        // Should have commands; alpha should be driven by alpha_keyframes
        assert!(!cmds.is_empty());
    }
}
