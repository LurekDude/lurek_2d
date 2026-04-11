//! Particle emitter struct and update/draw logic.

use super::config::{EmissionShape, EmitterState, InsertMode, ParticleConfig};
use super::emission::{emission_offset, emission_shape_offset};
use super::math::{
    interpolate_alphas, interpolate_colors, interpolate_sizes, rand_normal, rand_range,
};
use super::particle::Particle;
use crate::runtime::log_messages::{PE01, PE02, PE03, PE04};
use crate::render::renderer::{ParticleInstance, ParticleRenderShape, RenderCommand};
use crate::log_msg;
use crate::particle::shapes::ParticleShape;

/// An emitter-based particle system.
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
/// then `build_render_commands(ox, oy)` to obtain the `RenderCommand` list for rendering.
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
        log_msg!(debug, PE01);
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
        log_msg!(debug, PE04);
        self.particles.clear();
        self.emit_accumulator = 0.0;
        self.emitter_age = 0.0;
    }

    /// Activates the emitter, beginning particle emission.
    pub fn start(&mut self) {
        log_msg!(debug, PE02);
        self.state = EmitterState::Active;
        self.emitter_age = 0.0;
    }

    /// Stops the emitter. Existing particles continue updating until they die.
    pub fn stop(&mut self) {
        log_msg!(debug, PE03);
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

    /// Generates `RenderCommand`s for rendering all live particles.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    ///
    /// All particles are batched into a single `DrawParticleSystem` command. Each particle
    /// is sized and colored by multi-stop interpolation based on remaining lifetime.
    /// When `alpha_keyframes` are set, the alpha channel is overridden independently.
    ///
    /// # Parameters
    /// - `ox` — World X offset added to each particle position.
    /// - `oy` — World Y offset added to each particle position.
    pub fn build_render_commands(&self, ox: f32, oy: f32) -> Vec<RenderCommand> {
        if self.particles.is_empty() {
            return Vec::new();
        }

        let mut instances = Vec::with_capacity(self.particles.len());

        for p in &self.particles {
            let t = 1.0 - (p.life / p.max_life);
            let size = interpolate_sizes(&self.config.sizes, t, p.size_variation);

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
            if !self.config.alpha_keyframes.is_empty() {
                a = interpolate_alphas(&self.config.alpha_keyframes, t);
            }

            let px = ox + self.emitter_x + p.x;
            let py = oy + self.emitter_y + p.y;

            let render_shape = match self.config.shape {
                ParticleShape::Square => ParticleRenderShape::Square,
                ParticleShape::Circle => ParticleRenderShape::Circle,
                ParticleShape::Triangle => ParticleRenderShape::Triangle,
                ParticleShape::Spark => ParticleRenderShape::Spark,
                ParticleShape::Diamond => ParticleRenderShape::Diamond,
            };

            let (texture_key, quad, quad_tex_dims) = if let Some(tex_key) = self.config.texture_id {
                if !self.config.quads.is_empty() {
                    let quad_idx = if self.config.animated_frames > 0 {
                        let age = p.max_life - p.life;
                        (age * self.config.frame_rate) as usize
                            % (self.config.animated_frames as usize).min(self.config.quads.len())
                    } else {
                        ((t * self.config.quads.len() as f32) as usize)
                            .min(self.config.quads.len() - 1)
                    };
                    let [qx, qy, qw, qh] = self.config.quads[quad_idx];
                    (Some(tex_key), Some([qx, qy, qw, qh]), Some((qw, qh)))
                } else {
                    (Some(tex_key), None, None)
                }
            } else {
                (None, None, None)
            };

            instances.push(ParticleInstance {
                x: px,
                y: py,
                r,
                g,
                b,
                a,
                rotation: p.rotation,
                size,
                shape: render_shape,
                texture_key,
                quad,
                quad_tex_dims,
            });
        }

        vec![RenderCommand::DrawParticleSystem {
            particles: instances,
        }]
    }

    // ------------------------------------------------------------------
    // Visualization
    // ------------------------------------------------------------------

    /// Render all live particles to an image as colored circles.
    ///
    /// Each particle is drawn with its color interpolated from age. The emitter
    /// position is marked with a white dot.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width.
    /// - `height` — `u32`. Output image height.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(15, 15, 25, 255);
        let w = width as i32;
        let h = height as i32;
        for p in &self.particles {
            if p.life > 0.0 {
                let px = (p.x + self.emitter_x) as i32;
                let py = (p.y + self.emitter_y) as i32;
                if px < -10 || px > w + 10 || py < -10 || py > h + 10 {
                    continue;
                }
                let t = 1.0 - (p.life / p.max_life);
                let r = (255.0 * (1.0 - t * 0.5)) as u8;
                let g = (128.0 * (1.0 - t)) as u8;
                let b = 0u8;
                let size = (4.0f32 * (1.0 - t)).max(1.0) as i32;
                // Safe circle draw
                let y0 = (py - size).max(0);
                let y1 = (py + size + 1).min(h);
                let x0 = (px - size).max(0);
                let x1 = (px + size + 1).min(w);
                let r2 = (size * size) as i64;
                for sy in y0..y1 {
                    let dy = (sy - py) as i64;
                    for sx in x0..x1 {
                        let dx = (sx - px) as i64;
                        if dx * dx + dy * dy <= r2 {
                            img.set_pixel(sx as u32, sy as u32, r, g, b, 200);
                        }
                    }
                }
            }
        }
        // Emitter marker
        img.draw_circle(
            self.emitter_x as i32,
            self.emitter_y as i32,
            3,
            255,
            255,
            255,
            255,
        );
        img
    }

    /// Render an explosion burst: particles radiate from center with
    /// age-based red-to-yellow coloring.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_explosion_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(10, 8, 15, 255);
        for p in &self.particles {
            let t = p.life / p.max_life;
            let r = 255u8;
            let g = (t * 200.0) as u8;
            let b = (t * 60.0) as u8;
            let size = (3.0 + t * 4.0) as u32;
            img.draw_circle(p.x as i32, p.y as i32, size, r, g, b, (t * 255.0) as u8);
        }
        img.draw_label("EXPLOSION", 4, 4, 255, 160, 60);
        img
    }

    /// Render particles styled as falling rain streaks.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_rain_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(30, 35, 50, 255);
        for p in &self.particles {
            let t = p.life / p.max_life;
            let alpha = (t * 200.0) as u8 + 30;
            img.draw_line(
                p.x as i32,
                p.y as i32,
                p.x as i32,
                p.y as i32 + 6,
                140,
                160,
                220,
                alpha,
            );
        }
        img.draw_label("RAIN", 4, 4, 140, 180, 255);
        img
    }

    /// Render particles as hot orange sparks with short trails.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_spark_trail_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(10, 8, 12, 255);
        for p in &self.particles {
            let t = p.life / p.max_life;
            let r = 255u8;
            let g = (80.0 + t * 150.0) as u8;
            let b = (t * 50.0) as u8;
            img.draw_circle(p.x as i32, p.y as i32, 2, r, g, b, (t * 255.0) as u8);
            img.draw_line(
                p.x as i32,
                p.y as i32,
                p.x as i32 - 3,
                p.y as i32 + 3,
                r / 2,
                g / 2,
                b / 2,
                (t * 128.0) as u8,
            );
        }
        img.draw_label("SPARKS", 4, 4, 255, 200, 80);
        img
    }

    /// Render a lifecycle strip showing the particle count at each step.
    ///
    /// `snapshots` contains pairs of (step_index, particle_count). Each
    /// step is drawn as a column bar, with a dot marking the count percentage.
    ///
    /// # Parameters
    /// - `snapshots` — `&[(u32, usize)]`. (step, count) pairs.
    /// - `max_particles` — `usize`. Max capacity for scaling.
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    /// Render particles over a provided background image.
    ///
    /// Particles are drawn on top of `bg` without overwriting pixels that
    /// fall outside particle areas. The background pixels are preserved
    /// where no particle overlaps.
    ///
    /// # Parameters
    /// - `bg` — `crate::image::ImageData`. Background image to composite over.
    ///
    /// # Returns
    /// `crate::image::ImageData`.
    pub fn draw_over_image(&self, mut bg: crate::image::ImageData) -> crate::image::ImageData {
        let w = bg.width() as i32;
        let h = bg.height() as i32;
        for p in &self.particles {
            if p.life <= 0.0 {
                continue;
            }
            let px = (p.x + self.emitter_x) as i32;
            let py = (p.y + self.emitter_y) as i32;
            if px < -10 || px > w + 10 || py < -10 || py > h + 10 {
                continue;
            }
            let t = 1.0 - (p.life / p.max_life);
            let r = (255.0 * (1.0 - t * 0.5)) as u8;
            let g = (128.0 * (1.0 - t)) as u8;
            let b = 0u8;
            let size = (4.0f32 * (1.0 - t)).max(1.0) as i32;
            let y0 = (py - size).max(0);
            let y1 = (py + size + 1).min(h);
            let x0 = (px - size).max(0);
            let x1 = (px + size + 1).min(w);
            let r2 = (size * size) as i64;
            for sy in y0..y1 {
                let dy = (sy - py) as i64;
                for sx in x0..x1 {
                    let dx = (sx - px) as i64;
                    if dx * dx + dy * dy <= r2 {
                        bg.set_pixel(sx as u32, sy as u32, r, g, b, 200);
                    }
                }
            }
        }
        bg.draw_circle(
            self.emitter_x as i32,
            self.emitter_y as i32,
            3,
            255,
            255,
            255,
            255,
        );
        bg
    }

    /// Paint live spark particles onto an existing mutable image.
    ///
    /// Draws each live particle as a coloured dot using heat-map colours
    /// (yellow-hot at full life, red at end of life). Unlike
    /// `render_spark_trail_to_image`, this does not create a new canvas —
    /// it composites directly onto the supplied `img`.
    ///
    /// # Parameters
    /// - `img` — `&mut crate::image::ImageData`. Target canvas to paint onto.
    pub fn paint_onto(&self, img: &mut crate::image::ImageData) {
        let w = img.width() as i32;
        let h = img.height() as i32;
        for p in &self.particles {
            if p.life <= 0.0 {
                continue;
            }
            let px = p.x as i32;
            let py = p.y as i32;
            if px < 0 || px >= w || py < 0 || py >= h {
                continue;
            }
            let age_frac = 1.0 - p.life / p.max_life;
            let r = 255u8;
            let g = (220.0 * (1.0 - age_frac)) as u8;
            let b = (80.0 * (1.0 - age_frac * 0.8)) as u8;
            img.set_pixel(px as u32, py as u32, r, g, b, 255);
        }
    }

    /// Renders a bar chart of particle lifecycle counts over time into an `ImageData` frame.
    pub fn draw_lifecycle_to_image(
        snapshots: &[(u32, usize)],
        max_particles: usize,
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(15, 15, 25, 255);
        img.draw_label("LIFECYCLE", 4, 4, 180, 220, 255);
        if snapshots.is_empty() || max_particles == 0 {
            return img;
        }
        let bar_w = (width as f32 / snapshots.len().max(1) as f32) as u32;
        let plot_h = height - 24;
        for (i, &(_step, count)) in snapshots.iter().enumerate() {
            let t = count as f32 / max_particles as f32;
            let bar_h = (t * plot_h as f32) as u32;
            let x = i as u32 * bar_w;
            let y = height - bar_h;
            let r = (t * 200.0) as u8 + 40;
            let g = ((1.0 - t) * 200.0) as u8 + 40;
            for bx in 0..bar_w.saturating_sub(1) {
                for by in 0..bar_h {
                    if (x + bx) < width && (y + by) < height {
                        img.set_pixel(x + bx, y + by, r, g, 80, 200);
                    }
                }
            }
        }
        img
    }
}

#[cfg(test)]
mod tests {
    use super::super::config::{EmissionShape, ParticleConfig, RelativeMode};
    use super::super::emission::emission_shape_offset;
    use super::super::math::{interpolate_alphas, interpolate_colors, interpolate_sizes, lerp};
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
        let count = sys.count();
        assert!(count > 0);
        let cmds = sys.build_render_commands(0.0, 0.0);
        // All particles are batched into a single DrawParticleSystem command
        assert_eq!(cmds.len(), 1);
        if let crate::render::renderer::RenderCommand::DrawParticleSystem { particles } = &cmds[0]
        {
            assert_eq!(particles.len(), count);
        } else {
            panic!("expected DrawParticleSystem");
        }
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
        let cmds = sys.build_render_commands(0.0, 0.0);
        // Should have commands; alpha should be driven by alpha_keyframes
        assert!(!cmds.is_empty());
    }
}
