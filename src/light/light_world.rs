//! Resource pool and state for the 2D lighting system.

use slotmap::SlotMap;

use crate::engine::resource_keys::{LightKey, OccluderKey};
use crate::light::light2d::Light2D;
use crate::light::occluder::Occluder;
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
}

impl Default for LightWorld {
    fn default() -> Self {
        Self::new()
    }
}
