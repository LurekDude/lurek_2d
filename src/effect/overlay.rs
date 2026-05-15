//! - Central `Overlay` struct owning every screen-space post-world effect state block.
//! - Per-frame update loop advancing weather particles, flash decay, shake decay, fade interpolation, cloud scroll, and lightning.
//! - Weather particle spawning and simulation for rain, snow, hail, dust, leaves, ash, and pollen modes.
//! - Trigger API for flash, camera shake, screen fade, and lightning flash events.
//! - Query helpers for shake offset, flash/lightning alpha, active state, and target dimensions.
//! - Render command builder emitting full-screen colored rectangles for flash, fade, lightning, and vignette overlays.
//! - Clear/reset restoring all subsystems to default inactive state.
//! - Debug visualization: state panels, flash frame strips, shake offset trails, fade transition strips, and combined trigger previews.

use super::ambient::AmbientState;
use super::atmosphere::{
    CloudState, FilmGrainState, FogState, HeatHazeState, LightningState, VignetteState,
};
use super::screen_effects::{FadeState, FlashState, ShakeState};
use super::weather::{WeatherParticle, WeatherState, WeatherType};
use crate::log_msg;
use crate::runtime::log_messages::{OV01, OV02, OV03};
/// Owns every screen-space overlay state block applied on top of world rendering.
pub struct Overlay {
    /// Current overlay target width in pixels.
    pub width: u32,
    /// Current overlay target height in pixels.
    pub height: u32,
    /// Weather particle simulation and configuration.
    pub weather: WeatherState,
    /// Ambient tint state derived from time-of-day.
    pub ambient: AmbientState,
    /// Timed flash overlay state.
    pub flash: FlashState,
    /// Camera shake state and offsets.
    pub shake: ShakeState,
    /// Timed fade overlay state.
    pub fade: FadeState,
    /// Cloud overlay configuration.
    pub clouds: CloudState,
    /// Fog overlay configuration.
    pub fog: FogState,
    /// Heat haze distortion configuration.
    pub heat_haze: HeatHazeState,
    /// Vignette darkening configuration.
    pub vignette: VignetteState,
    /// Film grain configuration.
    pub film_grain: FilmGrainState,
    /// Lightning flash overlay state.
    pub lightning: LightningState,
    /// Water distortion overlay configuration and timer.
    pub water: crate::effect::water_overlay::WaterOverlayState,
    /// Optional custom overlay shader name.
    pub custom_shader: Option<String>,
}
impl Overlay {
    /// Creates an overlay initialized with default state blocks for the target size.
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
            water: crate::effect::water_overlay::WaterOverlayState::default(),
            custom_shader: None,
        }
    }
    /// Advances every active overlay subsystem by `dt` seconds.
    pub fn update(&mut self, dt: f32) {
        if self.ambient.enabled {
            self.ambient.color = self.ambient.compute_color_from_time();
        }
        if self.weather.enabled && self.weather.weather_type != WeatherType::None {
            self.update_weather(dt);
        }
        if self.flash.active {
            self.flash.elapsed += dt;
            if self.flash.elapsed >= self.flash.duration {
                self.flash.active = false;
                self.flash.elapsed = 0.0;
            }
        }
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
        if self.clouds.enabled {
            self.clouds.offset += self.clouds.speed * dt;
        }
        if self.lightning.active {
            self.lightning.elapsed += dt;
            if self.lightning.elapsed >= self.lightning.duration {
                self.lightning.active = false;
                self.lightning.elapsed = 0.0;
            }
        }
        self.water.update(dt);
    }
    /// Advances particle spawn and movement for the active weather mode.
    fn update_weather(&mut self, dt: f32) {
        let max_particles = (self.weather.intensity * 200.0) as usize;
        let w = self.width as f32;
        let h = self.height as f32;
        self.weather.spawn_timer += dt;
        let spawn_interval = 1.0 / (self.weather.intensity * 100.0 + 1.0);
        while self.weather.spawn_timer >= spawn_interval
            && self.weather.particles.len() < max_particles
        {
            self.weather.spawn_timer -= spawn_interval;
            let particle = self.spawn_particle(w);
            self.weather.particles.push(particle);
        }
        let wind_x = self.weather.wind_speed * self.weather.wind_direction.cos();
        let wind_y = self.weather.wind_speed * self.weather.wind_direction.sin();
        for p in &mut self.weather.particles {
            p.x += (p.vx + wind_x) * dt;
            p.y += (p.vy + wind_y) * dt;
        }
        let mut i = 0;
        while i < self.weather.particles.len() {
            let p = &self.weather.particles[i];
            if p.x > -50.0 && p.x < w + 50.0 && p.y > -50.0 && p.y < h + 50.0 {
                i += 1;
            } else {
                self.weather.particles.swap_remove(i);
            }
        }
    }
    /// Creates one weather particle with parameters derived from the active weather mode.
    fn spawn_particle(&mut self, width: f32) -> WeatherParticle {
        let frac = self.weather.next_unit();
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
    /// Starts a flash overlay with the supplied color, alpha, and duration.
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
    /// Starts a camera shake with the supplied intensity and duration.
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
    /// Starts a fade toward the supplied target alpha over the given duration.
    pub fn trigger_fade(&mut self, r: f32, g: f32, b: f32, target_alpha: f32, duration: f32) {
        self.fade.start_alpha = self.fade.color[3];
        self.fade.active = true;
        self.fade.color = [r, g, b, self.fade.start_alpha];
        self.fade.target_alpha = target_alpha;
        self.fade.duration = duration;
        self.fade.elapsed = 0.0;
    }
    /// Starts a short lightning flash using the configured lightning state.
    pub fn trigger_lightning(&mut self) {
        self.lightning.active = true;
        self.lightning.elapsed = 0.0;
    }
    /// Returns the current camera shake offset.
    pub fn get_shake_offset(&self) -> (f32, f32) {
        (self.shake.offset_x, self.shake.offset_y)
    }
    /// Returns whether any overlay subsystem is currently enabled or animating.
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
            || self.water.enabled
    }
    /// Restores every overlay subsystem to its default inactive state.
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
        self.water = crate::effect::water_overlay::WaterOverlayState::default();
        self.custom_shader = None;
    }
    /// Updates the overlay target dimensions.
    pub fn resize(&mut self, width: u32, height: u32) {
        self.width = width;
        self.height = height;
    }
    /// Returns the overlay target width.
    pub fn get_width(&self) -> u32 {
        self.width
    }
    /// Returns the overlay target height.
    pub fn get_height(&self) -> u32 {
        self.height
    }
    /// Returns the overlay target dimensions as `(width, height)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    /// Computes the current flash alpha after time decay.
    pub fn get_flash_alpha(&self) -> f32 {
        if !self.flash.active {
            return 0.0;
        }
        let progress = self.flash.elapsed / self.flash.duration;
        self.flash.color[3] * (1.0 - progress)
    }
    /// Computes the current lightning flash alpha after time decay.
    pub fn get_lightning_alpha(&self) -> f32 {
        if !self.lightning.active {
            return 0.0;
        }
        let progress = self.lightning.elapsed / self.lightning.duration;
        self.lightning.color[3] * (1.0 - progress)
    }
    /// Builds render commands for currently active full-screen overlay layers.
    pub fn build_render_commands(&self) -> Vec<crate::render::renderer::RenderCommand> {
        use crate::render::renderer::{DrawMode, RenderCommand};
        let mut cmds = Vec::new();
        let w = self.width as f32;
        let h = self.height as f32;
        let flash_a = self.get_flash_alpha();
        if flash_a > 0.0 {
            let [r, g, b, _] = self.flash.color;
            cmds.push(RenderCommand::SetColor(r, g, b, flash_a));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: 0.0,
                y: 0.0,
                w,
                h,
            });
        }
        if self.fade.active && self.fade.color[3] > 0.0 {
            let [r, g, b, a] = self.fade.color;
            cmds.push(RenderCommand::SetColor(r, g, b, a));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: 0.0,
                y: 0.0,
                w,
                h,
            });
        }
        let lightning_a = self.get_lightning_alpha();
        if lightning_a > 0.0 {
            let [r, g, b, _] = self.lightning.color;
            cmds.push(RenderCommand::SetColor(r, g, b, lightning_a));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: 0.0,
                y: 0.0,
                w,
                h,
            });
        }
        if self.vignette.enabled && self.vignette.strength > 0.0 {
            let a = (self.vignette.strength * 0.5).clamp(0.0, 1.0);
            cmds.push(RenderCommand::SetColor(0.0, 0.0, 0.0, a));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: 0.0,
                y: 0.0,
                w,
                h,
            });
        }
        cmds
    }
    /// Renders a debug image showing current flash, shake, and fade state.
    pub fn draw_state_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(15, 15, 25, 255);
        let section_h = height / 3;
        let flash_alpha = self.get_flash_alpha();
        let fr = (self.flash.color[0] * 255.0) as u8;
        let fg = (self.flash.color[1] * 255.0) as u8;
        let fb = (self.flash.color[2] * 255.0) as u8;
        let bar_w = (flash_alpha * width as f32) as u32;
        img.draw_rect(
            0,
            0,
            bar_w,
            section_h,
            fr,
            fg,
            fb,
            (flash_alpha * 200.0) as u8,
        );
        img.draw_label("FLASH", 4, 4, 220, 220, 230);
        let (sx, sy) = self.get_shake_offset();
        let cy = section_h as i32 + section_h as i32 / 2;
        let cx = width as i32 / 2;
        img.draw_circle(cx + sx as i32, cy + sy as i32, 8, 80, 200, 255, 255);
        img.draw_label("SHAKE", 4, section_h as i32 + 4, 220, 220, 230);
        let fade_y = (section_h * 2) as i32;
        let fade_a = self.fade.color[3];
        let fade_val = (fade_a * 255.0) as u8;
        img.draw_rect(0, fade_y, width, section_h, 0, 0, 0, fade_val);
        img.draw_label("FADE", 4, fade_y + 4, 220, 220, 230);
        img
    }
    #[allow(clippy::too_many_arguments)]
    /// Renders a frame strip showing the time evolution of a flash overlay.
    pub fn draw_flash_sequence_to_image(
        &mut self,
        r: f32,
        g: f32,
        b: f32,
        alpha: f32,
        duration: f32,
        steps: &[f32],
        panel_w: u32,
        height: u32,
    ) -> crate::image::ImageData {
        self.trigger_flash(r, g, b, alpha, duration);
        let total_w = panel_w * steps.len() as u32;
        let mut img = crate::image::ImageData::new(total_w, height);
        img.fill(15, 15, 25, 255);
        for (frame, dt) in steps.iter().enumerate() {
            if *dt > 0.0 {
                self.update(*dt);
            }
            let flash_alpha = self.get_flash_alpha();
            let ox = (frame as u32 * panel_w) as i32;
            for y in 0..height {
                for x in 0..panel_w {
                    let base_r = 40u8;
                    let base_g = 60u8;
                    let base_b = 80u8;
                    let pr = (base_r as f32 + (255.0 - base_r as f32) * flash_alpha) as u8;
                    let pg = (base_g as f32 + (0.0 - base_g as f32) * flash_alpha).max(0.0) as u8;
                    let pb = (base_b as f32 + (0.0 - base_b as f32) * flash_alpha).max(0.0) as u8;
                    img.set_pixel((ox as u32) + x, y, pr, pg, pb, 255);
                }
            }
        }
        img
    }
    /// Renders a debug image showing a series of shake offsets as a trail.
    pub fn draw_shake_trail_to_image(
        offsets: &[(f32, f32)],
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(15, 15, 25, 255);
        let cx = width as i32 / 2;
        let cy = height as i32 / 2;
        img.draw_line(cx - 20, cy, cx + 20, cy, 60, 60, 80, 255);
        img.draw_line(cx, cy - 20, cx, cy + 20, 60, 60, 80, 255);
        for (i, &(ox, oy)) in offsets.iter().enumerate() {
            let t = i as f32 / offsets.len().max(1) as f32;
            let r = (100.0 + t * 155.0) as u8;
            let g = (200.0 - t * 100.0) as u8;
            let px = cx + ox as i32;
            let py = cy + oy as i32;
            if px >= 0 && py >= 0 && (px as u32) < width && (py as u32) < height {
                img.draw_circle(px, py, 3, r, g, 120, 200);
            }
        }
        img
    }
    /// Renders a frame strip showing fade alpha samples across multiple steps.
    pub fn draw_fade_transition_to_image(
        steps: &[f32],
        panel_w: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let total_w = panel_w * steps.len() as u32;
        let mut img = crate::image::ImageData::new(total_w, height);
        img.fill(15, 15, 25, 255);
        for (i, &alpha) in steps.iter().enumerate() {
            let ox = i as u32 * panel_w;
            for y in 0..height {
                for x in 0..panel_w {
                    let base = 180u8;
                    let v = (base as f32 * (1.0 - alpha)) as u8;
                    img.set_pixel(ox + x, y, v, v, v, 255);
                }
            }
        }
        img
    }
    /// Renders a debug panel previewing flash, shake, fade, and lightning triggers.
    pub fn draw_trigger_panel_to_image(
        &mut self,
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 18, 28, 255);
        let half_w = width / 2;
        let half_h = height / 2;
        self.trigger_flash(1.0, 0.0, 0.0, 0.8, 0.5);
        img.draw_rect(2, 2, half_w - 4, half_h - 4, 40, 10, 10, 255);
        img.draw_label("FLASH", 6, 6, 255, 80, 80);
        for dy in 0..(half_h - 30) {
            let t = 1.0 - (dy as f32 / (half_h - 30) as f32);
            let a = (t * 0.8 * 200.0) as u8;
            if a > 20 {
                for dx in 0..(half_w - 10) {
                    img.set_pixel(5 + dx, 22 + dy, 200, 20, 20, a);
                }
            }
        }
        self.clear();
        self.trigger_shake(15.0, 0.4);
        let (ox, oy) = self.get_shake_offset();
        img.draw_rect(
            half_w as i32 + 2,
            2,
            half_w - 4,
            half_h - 4,
            10,
            10,
            40,
            255,
        );
        img.draw_label("SHAKE", half_w as i32 + 6, 6, 100, 100, 255);
        let scx = half_w as i32 + half_w as i32 / 2;
        let scy = half_h as i32 / 2;
        img.draw_circle(scx, scy, 20, 40, 40, 80, 255);
        img.draw_circle(
            scx + (ox * 2.0) as i32,
            scy + (oy * 2.0) as i32,
            4,
            255,
            100,
            100,
            255,
        );
        self.clear();
        self.trigger_fade(0.0, 0.0, 0.0, 0.7, 1.0);
        img.draw_rect(
            2,
            half_h as i32 + 2,
            half_w - 4,
            half_h - 4,
            10,
            10,
            10,
            255,
        );
        img.draw_label("FADE", 6, half_h as i32 + 6, 180, 180, 200);
        for dx in 0..(half_w - 10) {
            let t = dx as f32 / (half_w - 10) as f32;
            let alpha = (t * 0.7 * 255.0) as u8;
            for dy in 0..(half_h - 30) {
                img.set_pixel(5 + dx, half_h + 22 + dy, 0, 0, 0, alpha);
            }
        }
        self.clear();
        self.trigger_lightning();
        img.draw_rect(
            half_w as i32 + 2,
            half_h as i32 + 2,
            half_w - 4,
            half_h - 4,
            20,
            20,
            30,
            255,
        );
        img.draw_label(
            "LIGHTNING",
            half_w as i32 + 6,
            half_h as i32 + 6,
            220,
            220,
            255,
        );
        for dy in 0..(half_h - 30) {
            for dx in 0..(half_w - 10) {
                let flash = 200u8.saturating_sub((dy * 2) as u8);
                img.set_pixel(
                    half_w + 5 + dx,
                    half_h + 22 + dy,
                    flash,
                    flash,
                    flash + 40,
                    180,
                );
            }
        }
        self.clear();
        img
    }
}
