//! Composable per-frame overlay system.
//!
//! [`Overlay`] aggregates ambient, atmospheric, weather, and screen
//! effect sub-states and ticks them each frame.

use super::ambient::AmbientState;
use super::atmosphere::{
    CloudState, FilmGrainState, FogState, HeatHazeState, LightningState, VignetteState,
};
use super::screen_effects::{FadeState, FlashState, ShakeState};
use super::weather::{WeatherParticle, WeatherState, WeatherType};
use crate::engine::log_messages::{OV01, OV02, OV03};
use crate::log_msg;

/// Composable per-frame screen-effect overlay managing multiple visual subsystems.
///
/// All subsystems start inactive and can be enabled independently. Each
/// frame the game loop should call `update(dt)` to advance the simulation,
/// then use `get_shake_offset`, `get_flash_alpha`, etc. (or the Lua API
/// methods) to read back values for the renderer. No GPU objects are stored
/// here; this struct is a pure data model.
///
/// Typical Lua usage:
/// ```lua
/// local o = lurek.effect.newOverlay(800, 600)
/// o:setWeather("rain")   -- enable rain
/// o:setWeatherEnabled(true)
/// o:flash(1, 1, 1)        -- quick white flash
/// -- in lurek.update(dt):
/// o:update(dt)
/// ```
///
/// # Fields
/// - `width` ÔÇö `u32` ÔÇö Overlay canvas width in pixels.
/// - `height` ÔÇö `u32` ÔÇö Overlay canvas height in pixels.
/// - `weather` ÔÇö Weather particle subsystem.
/// - `ambient` ÔÇö Ambient lighting with time-of-day colour cycling.
/// - `flash` ÔÇö One-shot screen flash effect.
/// - `shake` ÔÇö Camera-shake effect with decaying PRNG offsets.
/// - `fade` ÔÇö Full-screen colour fade effect.
/// - `clouds` ÔÇö Scrolling cloud shadow overlay.
/// - `fog` ÔÇö Uniform atmospheric fog tint.
/// - `heat_haze` ÔÇö Distortion strength for shimmer effects.
/// - `vignette` ÔÇö Screen-edge darkening.
/// - `film_grain` ÔÇö Per-frame random noise overlay.
/// - `lightning` ÔÇö Hard single-frame lightning flash.
pub struct Overlay {
    /// Overlay width in pixels.
    pub width: u32,
    /// Overlay height in pixels.
    pub height: u32,
    /// Weather particle subsystem.
    pub weather: WeatherState,
    /// Ambient lighting with time-of-day.
    pub ambient: AmbientState,
    /// Screen flash effect.
    pub flash: FlashState,
    /// Screen shake effect.
    pub shake: ShakeState,
    /// Screen fade effect.
    pub fade: FadeState,
    /// Cloud shadow overlay.
    pub clouds: CloudState,
    /// Atmospheric fog.
    pub fog: FogState,
    /// Heat haze distortion.
    pub heat_haze: HeatHazeState,
    /// Vignette screen edge darkening.
    pub vignette: VignetteState,
    /// Film grain noise.
    pub film_grain: FilmGrainState,
    /// Lightning flash.
    pub lightning: LightningState,
}

impl Overlay {
    /// Creates a new overlay with the given dimensions.
    ///
    /// All subsystems are initialised to their `Default` state ÔÇö inactive,
    /// with sensible parameter values ready for use without further
    /// configuration. The `width` and `height` values are used by the
    /// weather particle spawner to determine screen bounds; update them
    /// with `resize` when the window changes size.
    ///
    /// # Parameters
    /// - `width` ÔÇö `u32` ÔÇö Overlay width in pixels.
    /// - `height` ÔÇö `u32` ÔÇö Overlay height in pixels.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        log_msg!(debug, OV01, "{}x{}", width, height);
        Self {
            width,
            height,
            weather: WeatherState::default(),
            ambient: AmbientState::default(),
            flash: FlashState::default(),
            shake: ShakeState::default(),
            fade: FadeState::default(),
            clouds: CloudState::default(),
            fog: FogState::default(),
            heat_haze: HeatHazeState::default(),
            vignette: VignetteState::default(),
            film_grain: FilmGrainState::default(),
            lightning: LightningState::default(),
        }
    }

    /// Advances all active effects by delta time.
    ///
    /// Update order each frame:
    /// 1. Ambient: if enabled, recomputes `color` from `time_of_day`.
    /// 2. Weather: spawns, moves, and culls particles.
    /// 3. Flash: advances `elapsed`; deactivates when `elapsed >= duration`.
    /// 4. Shake: advances `elapsed`, decays intensity, updates `offset_x/y`;
    ///    zeros out offsets and deactivates when done.
    /// 5. Fade: linearly interpolates `color[3]` toward `target_alpha`;
    ///    clamps and deactivates when complete.
    /// 6. Clouds: advances the internal `offset` scroll accumulator.
    /// 7. Lightning: advances `elapsed`; deactivates when done.
    ///
    /// Inactive subsystems incur only a branch check overhead.
    ///
    /// # Parameters
    /// - `dt` ÔÇö `f32` ÔÇö Frame delta time in seconds.
    pub fn update(&mut self, dt: f32) {
        // Update ambient colour from time-of-day
        if self.ambient.enabled {
            self.ambient.color = self.ambient.compute_color_from_time();
        }

        // Update weather particles
        if self.weather.enabled && self.weather.weather_type != WeatherType::None {
            self.update_weather(dt);
        }

        // Update flash
        if self.flash.active {
            self.flash.elapsed += dt;
            if self.flash.elapsed >= self.flash.duration {
                self.flash.active = false;
                self.flash.elapsed = 0.0;
            }
        }

        // Update shake
        if self.shake.active {
            self.shake.elapsed += dt;
            if self.shake.elapsed >= self.shake.duration {
                self.shake.active = false;
                self.shake.elapsed = 0.0;
                self.shake.offset_x = 0.0;
                self.shake.offset_y = 0.0;
            } else {
                let progress = self.shake.elapsed / self.shake.duration;
                let decay = 1.0 - progress;
                let rx = self.shake.next_random();
                let ry = self.shake.next_random();
                self.shake.offset_x = rx * self.shake.intensity * decay;
                self.shake.offset_y = ry * self.shake.intensity * decay;
            }
        }

        // Update fade
        if self.fade.active {
            self.fade.elapsed += dt;
            if self.fade.elapsed >= self.fade.duration {
                self.fade.active = false;
                self.fade.color[3] = self.fade.target_alpha;
            } else {
                let t = self.fade.elapsed / self.fade.duration;
                self.fade.color[3] =
                    self.fade.start_alpha + (self.fade.target_alpha - self.fade.start_alpha) * t;
            }
        }

        // Update cloud scroll
        if self.clouds.enabled {
            self.clouds.offset += self.clouds.speed * dt;
        }

        // Update lightning
        if self.lightning.active {
            self.lightning.elapsed += dt;
            if self.lightning.elapsed >= self.lightning.duration {
                self.lightning.active = false;
                self.lightning.elapsed = 0.0;
            }
        }
    }

    /// Updates weather particles: spawning, movement, and recycling.
    fn update_weather(&mut self, dt: f32) {
        let max_particles = (self.weather.intensity * 200.0) as usize;
        let w = self.width as f32;
        let h = self.height as f32;

        // Spawn new particles
        self.weather.spawn_timer += dt;
        let spawn_interval = 1.0 / (self.weather.intensity * 100.0 + 1.0);
        while self.weather.spawn_timer >= spawn_interval
            && self.weather.particles.len() < max_particles
        {
            self.weather.spawn_timer -= spawn_interval;
            let particle = self.spawn_particle(w);
            self.weather.particles.push(particle);
        }

        // Wind contribution
        let wind_x = self.weather.wind_speed * self.weather.wind_direction.cos();
        let wind_y = self.weather.wind_speed * self.weather.wind_direction.sin();

        // Move existing particles
        for p in &mut self.weather.particles {
            p.x += (p.vx + wind_x) * dt;
            p.y += (p.vy + wind_y) * dt;
        }

        // Remove off-screen particles
        self.weather
            .particles
            .retain(|p| p.x > -50.0 && p.x < w + 50.0 && p.y > -50.0 && p.y < h + 50.0);
    }

    /// Spawns a single weather particle at a random position along the top edge.
    fn spawn_particle(&self, width: f32) -> WeatherParticle {
        // Use a simple hash-based pseudo-random for deterministic-ish placement
        let seed = self.weather.particles.len() as f32;
        let frac = ((seed * 1.618033).fract() + 0.5).fract();
        let x = frac * width;

        let (vy, size, alpha) = match self.weather.weather_type {
            WeatherType::Rain => (200.0 + frac * 100.0, 2.0, 0.7),
            WeatherType::Snow => (30.0 + frac * 20.0, 3.0 + frac * 2.0, 0.9),
            WeatherType::Hail => (250.0 + frac * 50.0, 4.0, 0.8),
            WeatherType::Dust => (10.0 + frac * 15.0, 1.5, 0.4),
            WeatherType::Leaves => (40.0 + frac * 30.0, 5.0 + frac * 3.0, 0.8),
            WeatherType::Ash => (15.0 + frac * 10.0, 2.0, 0.5),
            WeatherType::Pollen => (5.0 + frac * 10.0, 1.0 + frac, 0.3),
            WeatherType::None => (0.0, 0.0, 0.0),
        };

        WeatherParticle {
            x,
            y: -10.0,
            vx: 0.0,
            vy,
            size,
            alpha,
        }
    }

    /// Triggers a screen flash with the given colour and duration.
    ///
    /// The flash immediately becomes active and starts fading out from the
    /// supplied alpha. Calling this while a flash is already in progress
    /// restarts it from the beginning with the new colour and duration ÔÇö
    /// there is no blending between the old and new flash.
    ///
    /// # Parameters
    /// - `r` ÔÇö `f32` ÔÇö Red channel (0.0ÔÇô1.0).
    /// - `g` ÔÇö `f32` ÔÇö Green channel (0.0ÔÇô1.0).
    /// - `b` ÔÇö `f32` ÔÇö Blue channel (0.0ÔÇô1.0).
    /// - `a` ÔÇö `f32` ÔÇö Starting alpha (0.0ÔÇô1.0).
    /// - `duration` ÔÇö `f32` ÔÇö Flash duration in seconds.
    pub fn trigger_flash(&mut self, r: f32, g: f32, b: f32, a: f32, duration: f32) {
        log_msg!(
            debug,
            OV02,
            "rgba=({:.2}, {:.2}, {:.2}, {:.2}) {:.3}s",
            r,
            g,
            b,
            a,
            duration
        );
        self.flash.active = true;
        self.flash.color = [r, g, b, a];
        self.flash.duration = duration;
        self.flash.elapsed = 0.0;
    }

    /// Triggers a screen shake with the given intensity and duration.
    ///
    /// The shake immediately activates and begins generating per-frame
    /// `offset_x`/`offset_y` values using the internal xorshift PRNG.
    /// The peak offset scales with `intensity` and decays linearly to zero
    /// by the end of `duration`. Calling while a shake is already active
    /// resets `elapsed` to zero and replaces intensity ÔÇö a second impact
    /// will restart the shake from full strength.
    ///
    /// # Parameters
    /// - `intensity` ÔÇö `f32` ÔÇö Peak shake magnitude in pixels.
    /// - `duration` ÔÇö `f32` ÔÇö Shake duration in seconds.
    pub fn trigger_shake(&mut self, intensity: f32, duration: f32) {
        log_msg!(
            debug,
            OV03,
            "intensity={} duration={:.3}s",
            intensity,
            duration
        );
        self.shake.active = true;
        self.shake.intensity = intensity;
        self.shake.duration = duration;
        self.shake.elapsed = 0.0;
        self.shake.offset_x = 0.0;
        self.shake.offset_y = 0.0;
    }

    /// Triggers a fade to the given colour.
    ///
    /// The `start_alpha` is captured from the current `color[3]` so that
    /// chained fades (e.g. fade-in followed by fade-out) transition
    /// smoothly without any visible jump. Calling while a fade is in
    /// progress re-captures `start_alpha` from the current interpolated
    /// value and restarts toward the new `target_alpha` and `duration`.
    ///
    /// # Parameters
    /// - `r` ÔÇö `f32` ÔÇö Red channel of the fill colour (0.0ÔÇô1.0).
    /// - `g` ÔÇö `f32` ÔÇö Green channel (0.0ÔÇô1.0).
    /// - `b` ÔÇö `f32` ÔÇö Blue channel (0.0ÔÇô1.0).
    /// - `target_alpha` ÔÇö `f32` ÔÇö Alpha to reach at the end (0.0ÔÇô1.0).
    /// - `duration` ÔÇö `f32` ÔÇö Fade duration in seconds.
    pub fn trigger_fade(&mut self, r: f32, g: f32, b: f32, target_alpha: f32, duration: f32) {
        self.fade.start_alpha = self.fade.color[3];
        self.fade.active = true;
        self.fade.color = [r, g, b, self.fade.start_alpha];
        self.fade.target_alpha = target_alpha;
        self.fade.duration = duration;
        self.fade.elapsed = 0.0;
    }

    /// Triggers a one-shot lightning flash effect.
    ///
    /// Sets `lightning.active = true` and resets `elapsed` to zero so the
    /// flash starts at full intensity. Calling this while a lightning flash
    /// is already in progress restarts it immediately from full brightness.
    /// The default flash colour is pale blue-white (0.9, 0.9, 1.0, 0.8);
    /// set `lightning.color` before calling to customise it.
    pub fn trigger_lightning(&mut self) {
        self.lightning.active = true;
        self.lightning.elapsed = 0.0;
    }

    /// Returns the current shake pixel offset.
    ///
    /// # Returns
    /// `(f32, f32)` ÔÇö x and y offsets.
    pub fn get_shake_offset(&self) -> (f32, f32) {
        (self.shake.offset_x, self.shake.offset_y)
    }

    /// Returns whether any effect is currently active.
    ///
    /// Returns `true` when at least one subsystem is either enabled or has
    /// a one-shot effect in progress: weather enabled, ambient enabled, flash
    /// active, shake active, fade active, clouds enabled, fog enabled, heat
    /// haze enabled, vignette enabled, film grain enabled, or lightning active.
    /// A fully cleared overlay (after `clear()`) returns `false`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_active(&self) -> bool {
        self.weather.enabled
            || self.ambient.enabled
            || self.flash.active
            || self.shake.active
            || self.fade.active
            || self.clouds.enabled
            || self.fog.enabled
            || self.heat_haze.enabled
            || self.vignette.enabled
            || self.film_grain.enabled
            || self.lightning.active
    }

    /// Resets all effects to their inactive defaults.
    ///
    /// Equivalent to replacing every subsystem field with its `Default`
    /// value. All live weather particles are dropped, one-shot effects
    /// (flash, shake, fade, lightning) are deactivated, and persistent
    /// effects (ambient, clouds, fog, heat haze, vignette, film grain)
    /// are disabled. Parameters such as intensity and colour are also
    /// reset to their initial values.
    pub fn clear(&mut self) {
        self.weather = WeatherState::default();
        self.ambient = AmbientState::default();
        self.flash = FlashState::default();
        self.shake = ShakeState::default();
        self.fade = FadeState::default();
        self.clouds = CloudState::default();
        self.fog = FogState::default();
        self.heat_haze = HeatHazeState::default();
        self.vignette = VignetteState::default();
        self.film_grain = FilmGrainState::default();
        self.lightning = LightningState::default();
    }

    /// Resizes the overlay canvas dimensions.
    ///
    /// Updates the internal width and height used by the weather particle
    /// spawner to determine screen bounds for culling. Call this whenever
    /// the window is resized so that particles are not spawned outside the
    /// visible area. Does not discard existing particles ÔÇö they will be
    /// culled naturally on the next `update` call if they are off-screen.
    ///
    /// # Parameters
    /// - `width` ÔÇö `u32` ÔÇö New overlay width in pixels.
    /// - `height` ÔÇö `u32` ÔÇö New overlay height in pixels.
    pub fn resize(&mut self, width: u32, height: u32) {
        self.width = width;
        self.height = height;
    }

    /// Returns the overlay canvas width in pixels.
    ///
    /// Reflects the value passed to `new` or the most recent `resize` call.
    ///
    /// # Returns
    /// `u32` ÔÇö Current canvas width in pixels.
    pub fn get_width(&self) -> u32 {
        self.width
    }

    /// Returns the overlay canvas height in pixels.
    ///
    /// Reflects the value passed to `new` or the most recent `resize` call.
    ///
    /// # Returns
    /// `u32` ÔÇö Current canvas height in pixels.
    pub fn get_height(&self) -> u32 {
        self.height
    }

    /// Returns both overlay canvas dimensions as `(width, height)`.
    ///
    /// Convenience accessor combining `get_width()` and `get_height()`.
    ///
    /// # Returns
    /// `(u32, u32)` ÔÇö Width and height in pixels.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Returns the current flash overlay alpha (0.0 when inactive).
    ///
    /// Linearly interpolates from `flash.color[3]` down to `0.0` over the
    /// flash `duration`. Returns exactly `0.0` when no flash is active,
    /// making it safe to skip the draw call when the value is zero.
    ///
    /// # Returns
    /// `f32` ÔÇö Current flash alpha in [0.0, flash.color[3]].
    pub fn get_flash_alpha(&self) -> f32 {
        if !self.flash.active {
            return 0.0;
        }
        let progress = self.flash.elapsed / self.flash.duration;
        self.flash.color[3] * (1.0 - progress)
    }

    /// Returns the current lightning overlay alpha (0.0 when inactive).
    ///
    /// Linearly interpolates from `lightning.color[3]` down to `0.0` over
    /// the lightning `duration`. Returns `0.0` when no lightning flash is
    /// active, allowing the renderer to skip the draw call cheaply.
    ///
    /// # Returns
    /// `f32` ÔÇö Current lightning alpha in [0.0, lightning.color[3]].
    pub fn get_lightning_alpha(&self) -> f32 {
        if !self.lightning.active {
            return 0.0;
        }
        let progress = self.lightning.elapsed / self.lightning.duration;
        self.lightning.color[3] * (1.0 - progress)
    }

    // ── CPU rendering ──

    /// Renders a diagnostic image showing the current overlay state.
    ///
    /// Visualises flash colour/alpha, shake offset, and fade level as
    /// coloured rectangles with numeric labels — useful for evidence tests.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn render_state_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(15, 15, 25, 255);

        let section_h = height / 3;

        // Flash state (top third)
        let flash_alpha = self.get_flash_alpha();
        let fr = (self.flash.color[0] * 255.0) as u8;
        let fg = (self.flash.color[1] * 255.0) as u8;
        let fb = (self.flash.color[2] * 255.0) as u8;
        let bar_w = (flash_alpha * width as f32) as u32;
        img.draw_rect(0, 0, bar_w, section_h, fr, fg, fb, (flash_alpha * 200.0) as u8);
        img.draw_label("FLASH", 4, 4, 220, 220, 230);

        // Shake state (middle third)
        let (sx, sy) = self.get_shake_offset();
        let cy = section_h as i32 + section_h as i32 / 2;
        let cx = width as i32 / 2;
        img.draw_circle(cx + sx as i32, cy + sy as i32, 8, 80, 200, 255, 255);
        img.draw_label("SHAKE", 4, section_h as i32 + 4, 220, 220, 230);

        // Fade state (bottom third)
        let fade_y = (section_h * 2) as i32;
        let fade_a = self.fade.color[3];
        let fade_val = (fade_a * 255.0) as u8;
        img.draw_rect(0, fade_y, width, section_h, 0, 0, 0, fade_val);
        img.draw_label("FADE", 4, fade_y + 4, 220, 220, 230);

        img
    }
}
