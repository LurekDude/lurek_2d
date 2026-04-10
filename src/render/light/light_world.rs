//! Resource pool and state for the 2D lighting system.

use slotmap::SlotMap;

use crate::runtime::log_messages::{LW01_LIGHT_WORLD_INIT, LW02_LIGHT_ADD};
use crate::runtime::resource_keys::{LightKey, OccluderKey};
use crate::render::light::light2d::Light2D;
use crate::render::light::occluder::Occluder;
use crate::log_msg;
use crate::math::Color;

/// Resource pool and state for the 2D lighting system.
///
/// # Fields
/// - `lights` — `SlotMap<LightKey, Light2D>`.
/// - `occluders` — `SlotMap<OccluderKey, Occluder>`.
/// - `ambient` — `Color`.
/// - `enabled` — `bool`.
/// - `max_lights` — `u16`.
///
/// Owns all light sources and shadow occluders. The renderer reads this
/// each frame to produce the lighting pass. `enabled` auto-activates
/// when the first light is added.
pub struct LightWorld {
    /// All active light sources, indexed by generational key.
    pub lights: SlotMap<LightKey, Light2D>,
    /// All active shadow occluders, indexed by generational key.
    pub occluders: SlotMap<OccluderKey, Occluder>,
    /// Global ambient light color applied before any point lights.
    pub ambient: Color,
    /// Whether the lighting system is active (auto-enables on first light).
    pub enabled: bool,
    /// Maximum number of lights processed per frame.
    pub max_lights: u16,
}

impl LightWorld {
    /// Creates a new empty `LightWorld` with default settings.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Defaults: ambient = (0.1, 0.1, 0.1, 1.0), enabled = false, max_lights = 64.
    pub fn new() -> Self {
        log_msg!(debug, LW01_LIGHT_WORLD_INIT);
        Self {
            lights: SlotMap::with_key(),
            occluders: SlotMap::with_key(),
            ambient: Color::new(0.1, 0.1, 0.1, 1.0),
            enabled: false,
            max_lights: 64,
        }
    }

    /// Inserts a light and returns its key. Auto-enables the system on first light.
    ///
    /// # Parameters
    /// - `light` — `Light2D`.
    ///
    /// # Returns
    /// `LightKey`.
    pub fn add_light(&mut self, light: Light2D) -> LightKey {
        log_msg!(debug, LW02_LIGHT_ADD);
        if !self.enabled {
            self.enabled = true;
        }
        self.lights.insert(light)
    }

    /// Inserts an occluder and returns its key.
    ///
    /// # Parameters
    /// - `occluder` — `Occluder`.
    ///
    /// # Returns
    /// `OccluderKey`.
    pub fn add_occluder(&mut self, occluder: Occluder) -> OccluderKey {
        self.occluders.insert(occluder)
    }

    /// Removes a light by key, returning it if found.
    ///
    /// # Parameters
    /// - `key` — `LightKey`.
    ///
    /// # Returns
    /// `Option<Light2D>`.
    pub fn remove_light(&mut self, key: LightKey) -> Option<Light2D> {
        self.lights.remove(key)
    }

    /// Removes an occluder by key, returning it if found.
    ///
    /// # Parameters
    /// - `key` — `OccluderKey`.
    ///
    /// # Returns
    /// `Option<Occluder>`.
    pub fn remove_occluder(&mut self, key: OccluderKey) -> Option<Occluder> {
        self.occluders.remove(key)
    }

    /// Returns a shared reference to a light by key.
    ///
    /// # Parameters
    /// - `key` — `LightKey`.
    ///
    /// # Returns
    /// `Option<&Light2D>`.
    pub fn get_light(&self, key: LightKey) -> Option<&Light2D> {
        self.lights.get(key)
    }

    /// Returns a mutable reference to a light by key.
    ///
    /// # Parameters
    /// - `key` — `LightKey`.
    ///
    /// # Returns
    /// `Option<&mut Light2D>`.
    pub fn get_light_mut(&mut self, key: LightKey) -> Option<&mut Light2D> {
        self.lights.get_mut(key)
    }

    /// Returns a shared reference to an occluder by key.
    ///
    /// # Parameters
    /// - `key` — `OccluderKey`.
    ///
    /// # Returns
    /// `Option<&Occluder>`.
    pub fn get_occluder(&self, key: OccluderKey) -> Option<&Occluder> {
        self.occluders.get(key)
    }

    /// Returns a mutable reference to an occluder by key.
    ///
    /// # Parameters
    /// - `key` — `OccluderKey`.
    ///
    /// # Returns
    /// `Option<&mut Occluder>`.
    pub fn get_occluder_mut(&mut self, key: OccluderKey) -> Option<&mut Occluder> {
        self.occluders.get_mut(key)
    }

    /// Returns the number of lights in the world.
    ///
    /// # Returns
    /// `usize`.
    pub fn light_count(&self) -> usize {
        self.lights.len()
    }

    /// Returns the number of occluders in the world.
    ///
    /// # Returns
    /// `usize`.
    pub fn occluder_count(&self) -> usize {
        self.occluders.len()
    }

    /// Removes all lights and occluders, resets ambient to default.
    pub fn clear(&mut self) {
        self.lights.clear();
        self.occluders.clear();
        self.ambient = Color::new(0.1, 0.1, 0.1, 1.0);
    }

    /// Returns `true` if any light in the world is enabled.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_active_lights(&self) -> bool {
        self.lights.values().any(|l| l.enabled)
    }

    /// Sets the enabled state for all lights in the given group.
    ///
    /// # Parameters
    /// - `group_id` — `u16`.
    /// - `enabled` — `bool`.
    pub fn set_group_enabled(&mut self, group_id: u16, enabled: bool) {
        for light in self.lights.values_mut() {
            if light.group_id == group_id {
                light.enabled = enabled;
            }
        }
    }

    /// Sets the intensity for all lights in the given group.
    ///
    /// # Parameters
    /// - `group_id` — `u16`.
    /// - `intensity` — `f32`.
    pub fn set_group_intensity(&mut self, group_id: u16, intensity: f32) {
        for light in self.lights.values_mut() {
            if light.group_id == group_id {
                light.intensity = intensity;
            }
        }
    }

    /// Sets the color for all lights in the given group.
    ///
    /// # Parameters
    /// - `group_id` — `u16`.
    /// - `color` — `Color`.
    pub fn set_group_color(&mut self, group_id: u16, color: Color) {
        for light in self.lights.values_mut() {
            if light.group_id == group_id {
                light.color = color;
            }
        }
    }

    /// Returns the number of lights in the given group.
    ///
    /// # Parameters
    /// - `group_id` — `u16`.
    ///
    /// # Returns
    /// `usize`.
    pub fn group_count(&self, group_id: u16) -> usize {
        self.lights
            .values()
            .filter(|l| l.group_id == group_id)
            .count()
    }

    /// Advances flicker phase for all lights with flicker enabled.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    pub fn advance_flickers(&mut self, dt: f32) {
        for light in self.lights.values_mut() {
            light.flicker.advance(dt);
        }
    }

    /// Render the accumulated lightmap to an image.
    ///
    /// Each pixel accumulates additive light contributions from all lights using
    /// quadratic distance falloff. Occluders are drawn as dark rectangles.
    /// Light source centers are marked with bright dots.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width.
    /// - `height` — `u32`. Output image height.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(10, 10, 15, 255);

        // Collect light parameters
        let light_params: Vec<(f32, f32, f32, f32, f32, f32)> = self
            .lights
            .values()
            .map(|l| (l.x, l.y, l.radius, l.color.r, l.color.g, l.color.b))
            .collect();

        // Accumulate light per pixel
        for y in 0..height {
            for x in 0..width {
                let mut fr = 10.0f32;
                let mut fg = 10.0f32;
                let mut fb = 15.0f32;
                for &(lx, ly, radius, lr, lg, lb) in &light_params {
                    let dx = x as f32 - lx;
                    let dy = y as f32 - ly;
                    let dist = (dx * dx + dy * dy).sqrt();
                    let atten = (1.0 - dist / radius).max(0.0);
                    let atten = atten * atten; // quadratic falloff
                    fr += lr * atten * 200.0;
                    fg += lg * atten * 200.0;
                    fb += lb * atten * 200.0;
                }
                img.set_pixel(x, y, fr.min(255.0) as u8, fg.min(255.0) as u8, fb.min(255.0) as u8, 255);
            }
        }

        // Draw occluders as dark rectangles (simplified bounding box)
        for occ in self.occluders.values() {
            let verts = &occ.vertices;
            if verts.len() >= 2 {
                let mut min_x = f32::MAX;
                let mut min_y = f32::MAX;
                let mut max_x = f32::MIN;
                let mut max_y = f32::MIN;
                for v in verts {
                    min_x = min_x.min(v.x);
                    min_y = min_y.min(v.y);
                    max_x = max_x.max(v.x);
                    max_y = max_y.max(v.y);
                }
                img.draw_rect(
                    min_x as i32, min_y as i32,
                    (max_x - min_x) as u32, (max_y - min_y) as u32,
                    20, 20, 25, 255,
                );
            }
        }

        // Draw light source markers
        for l in self.lights.values() {
            img.draw_circle(l.x as i32, l.y as i32, 5, 255, 240, 100, 255);
        }
        img
    }

}

impl Default for LightWorld {
    fn default() -> Self {
        Self::new()
    }
}
