use crate::light::light2d::Light2D;
use crate::light::light_type::LightType;
use crate::light::occluder::Occluder;
use crate::log_msg;
use crate::math::Color;
use crate::runtime::log_messages::{LW01_LIGHT_WORLD_INIT, LW02_LIGHT_ADD};
use crate::runtime::resource_keys::{LightKey, OccluderKey};
use slotmap::SlotMap;
pub struct LightWorld {
    pub lights: SlotMap<LightKey, Light2D>,
    pub occluders: SlotMap<OccluderKey, Occluder>,
    pub ambient: Color,
    pub enabled: bool,
    pub max_lights: u16,
    flicker_keys: Vec<LightKey>,
    flicker_index_dirty: bool,
}
#[derive(Debug, Clone)]
pub struct NormalMapLightHint {
    pub x: f32,
    pub y: f32,
    pub radius: f32,
    pub intensity: f32,
    pub direction: f32,
    pub path: String,
    pub strength: f32,
}
impl LightWorld {
    pub fn new() -> Self {
        log_msg!(trace, LW01_LIGHT_WORLD_INIT);
        Self {
            lights: SlotMap::with_key(),
            occluders: SlotMap::with_key(),
            ambient: Color::new(0.1, 0.1, 0.1, 1.0),
            enabled: false,
            max_lights: 64,
            flicker_keys: Vec::new(),
            flicker_index_dirty: true,
        }
    }
    pub fn add_light(&mut self, light: Light2D) -> LightKey {
        log_msg!(debug, LW02_LIGHT_ADD);
        if !self.enabled {
            self.enabled = true;
        }
        let key = self.lights.insert(light);
        self.flicker_index_dirty = true;
        key
    }
    pub fn add_occluder(&mut self, occluder: Occluder) -> OccluderKey {
        self.occluders.insert(occluder)
    }
    pub fn remove_light(&mut self, key: LightKey) -> Option<Light2D> {
        self.flicker_keys.retain(|k| *k != key);
        self.lights.remove(key)
    }
    pub fn remove_occluder(&mut self, key: OccluderKey) -> Option<Occluder> {
        self.occluders.remove(key)
    }
    pub fn get_light(&self, key: LightKey) -> Option<&Light2D> {
        self.lights.get(key)
    }
    pub fn get_light_mut(&mut self, key: LightKey) -> Option<&mut Light2D> {
        self.lights.get_mut(key)
    }
    pub fn get_occluder(&self, key: OccluderKey) -> Option<&Occluder> {
        self.occluders.get(key)
    }
    pub fn get_occluder_mut(&mut self, key: OccluderKey) -> Option<&mut Occluder> {
        self.occluders.get_mut(key)
    }
    pub fn light_count(&self) -> usize {
        self.lights.len()
    }
    pub fn occluder_count(&self) -> usize {
        self.occluders.len()
    }
    pub fn clear(&mut self) {
        self.lights.clear();
        self.occluders.clear();
        self.ambient = Color::new(0.1, 0.1, 0.1, 1.0);
        self.flicker_keys.clear();
        self.flicker_index_dirty = false;
    }
    pub fn has_active_lights(&self) -> bool {
        self.lights.values().any(|l| l.enabled)
    }
    pub fn set_group_enabled(&mut self, group_id: u16, enabled: bool) {
        for light in self.lights.values_mut() {
            if light.group_id == group_id {
                light.enabled = enabled;
            }
        }
    }
    pub fn set_group_intensity(&mut self, group_id: u16, intensity: f32) {
        for light in self.lights.values_mut() {
            if light.group_id == group_id {
                light.intensity = intensity;
            }
        }
    }
    pub fn set_group_color(&mut self, group_id: u16, color: Color) {
        for light in self.lights.values_mut() {
            if light.group_id == group_id {
                light.color = color;
            }
        }
    }
    pub fn group_count(&self, group_id: u16) -> usize {
        self.lights
            .values()
            .filter(|l| l.group_id == group_id)
            .count()
    }
    pub fn advance_flickers(&mut self, dt: f32) {
        if self.flicker_index_dirty {
            self.reindex_flickers();
        }
        let mut stale = false;
        for key in self.flicker_keys.iter().copied() {
            if let Some(light) = self.lights.get_mut(key) {
                if light.flicker.enabled {
                    light.flicker.advance(dt);
                }
            } else {
                stale = true;
            }
        }
        if stale {
            self.flicker_keys.retain(|k| self.lights.contains_key(*k));
        }
    }
    pub fn reindex_flickers(&mut self) {
        self.flicker_keys.clear();
        for (key, light) in self.lights.iter() {
            if light.flicker.enabled {
                self.flicker_keys.push(key);
            }
        }
        self.flicker_index_dirty = false;
    }
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(10, 10, 15, 255);
        let light_params: Vec<(f32, f32, f32, f32, f32, f32)> = self
            .lights
            .values()
            .map(|l| (l.x, l.y, l.radius, l.color.r, l.color.g, l.color.b))
            .collect();
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
                    let atten = atten * atten;
                    fr += lr * atten * 200.0;
                    fg += lg * atten * 200.0;
                    fb += lb * atten * 200.0;
                }
                img.set_pixel(
                    x,
                    y,
                    fr.min(255.0) as u8,
                    fg.min(255.0) as u8,
                    fb.min(255.0) as u8,
                    255,
                );
            }
        }
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
                    min_x as i32,
                    min_y as i32,
                    (max_x - min_x) as u32,
                    (max_y - min_y) as u32,
                    20,
                    20,
                    25,
                    255,
                );
            }
        }
        for l in self.lights.values() {
            img.draw_circle(l.x as i32, l.y as i32, 5, 255, 240, 100, 255);
        }
        img
    }
    pub fn ambient_color_hint(&self) -> [f32; 4] {
        [
            self.ambient.r,
            self.ambient.g,
            self.ambient.b,
            self.ambient.a,
        ]
    }
    pub fn directional_light_hints(&self) -> Vec<(f32, f32, f32)> {
        self.lights
            .values()
            .filter(|l| l.enabled && l.light_type == LightType::Directional)
            .map(|l| (l.x, l.y, l.direction))
            .collect()
    }
    pub fn normal_map_light_hints(&self) -> Vec<NormalMapLightHint> {
        self.lights
            .values()
            .filter(|l| l.enabled)
            .filter_map(|l| {
                l.get_normal_map_path().map(|path| NormalMapLightHint {
                    x: l.x,
                    y: l.y,
                    radius: l.radius,
                    intensity: l.intensity,
                    direction: l.direction,
                    path: path.to_string(),
                    strength: l.normal_strength,
                })
            })
            .collect()
    }
}
impl Default for LightWorld {
    fn default() -> Self {
        Self::new()
    }
}
