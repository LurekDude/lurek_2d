use crate::render::BlendMode;
use crate::render::ShaderPassDescriptor;
use crate::runtime::resource_keys::TextureKey;
use std::collections::HashMap;
const MIN_TILE_SIZE: f32 = 16.0;
pub struct ParallaxDrawBatch {
    pub texture_key: TextureKey,
    pub tiles: Vec<(f32, f32)>,
    pub sx: f32,
    pub sy: f32,
    pub color: [f32; 4],
    pub blend_mode: BlendMode,
    pub effect: Option<Vec<ShaderPassDescriptor>>,
}
pub struct ParallaxLayer {
    pub texture_key: TextureKey,
    pub texture_width: f32,
    pub texture_height: f32,
    pub scroll_factor: [f32; 2],
    pub offset: [f32; 2],
    pub autoscroll: [f32; 2],
    pub autoscroll_accum: [f32; 2],
    pub repeat_x: bool,
    pub repeat_y: bool,
    pub clamp_min: Option<[f32; 2]>,
    pub clamp_max: Option<[f32; 2]>,
    pub z: i32,
    pub opacity: f32,
    pub tint: [f32; 4],
    pub blend_mode: BlendMode,
    pub visible: bool,
    pub scale: [f32; 2],
    pub tiling: bool,
    pub tile_w: Option<f32>,
    pub tile_h: Option<f32>,
    pub depth: f32,
    pub effect_chain: Option<Vec<ShaderPassDescriptor>>,
    pub motion_stretch_enabled: bool,
    pub motion_stretch_strength: f32,
    pub motion_stretch_max_scale: f32,
}
impl ParallaxLayer {
    pub fn new(texture_key: TextureKey, texture_width: f32, texture_height: f32) -> Self {
        ParallaxLayer {
            texture_key,
            texture_width,
            texture_height,
            scroll_factor: [1.0, 0.0],
            offset: [0.0, 0.0],
            autoscroll: [0.0, 0.0],
            autoscroll_accum: [0.0, 0.0],
            repeat_x: true,
            repeat_y: false,
            clamp_min: None,
            clamp_max: None,
            z: 0,
            opacity: 1.0,
            tint: [1.0, 1.0, 1.0, 1.0],
            blend_mode: BlendMode::Alpha,
            visible: true,
            scale: [1.0, 1.0],
            tiling: false,
            tile_w: None,
            tile_h: None,
            depth: 0.0,
            effect_chain: None,
            motion_stretch_enabled: false,
            motion_stretch_strength: 0.001,
            motion_stretch_max_scale: 2.0,
        }
    }
    pub fn update(&mut self, dt: f32) {
        self.autoscroll_accum[0] += self.autoscroll[0] * dt;
        self.autoscroll_accum[1] += self.autoscroll[1] * dt;
        let (tw, th) = self.resolved_tile_dimensions();
        if tw > 0.0 {
            self.autoscroll_accum[0] = self.autoscroll_accum[0].rem_euclid(tw);
        }
        if th > 0.0 {
            self.autoscroll_accum[1] = self.autoscroll_accum[1].rem_euclid(th);
        }
    }
    fn resolved_tile_dimensions(&self) -> (f32, f32) {
        let base_w = self.texture_width * self.scale[0];
        let base_h = self.texture_height * self.scale[1];
        let tw = self.tile_w.unwrap_or(base_w).max(MIN_TILE_SIZE);
        let th = self.tile_h.unwrap_or(base_h).max(MIN_TILE_SIZE);
        (tw, th)
    }
    fn compute_pixel_offset(&self, cam_x: f32, cam_y: f32) -> (f32, f32) {
        let mut px = cam_x * self.scroll_factor[0] + self.offset[0] + self.autoscroll_accum[0];
        let mut py = cam_y * self.scroll_factor[1] + self.offset[1] + self.autoscroll_accum[1];
        if let (Some(mn), Some(mx)) = (self.clamp_min, self.clamp_max) {
            px = px.clamp(mn[0], mx[0]);
            py = py.clamp(mn[1], mx[1]);
        }
        (px, py)
    }
    pub fn build_draw_calls(
        &self,
        cam_x: f32,
        cam_y: f32,
        screen_w: f32,
        screen_h: f32,
    ) -> Option<ParallaxDrawBatch> {
        if !self.visible || self.opacity <= 0.0 {
            return None;
        }
        let (tex_w, tex_h) = self.resolved_tile_dimensions();
        let repeat_x = self.tiling || self.repeat_x;
        let repeat_y = self.tiling || self.repeat_y;
        if tex_w <= 0.0 || tex_h <= 0.0 {
            return None;
        }
        let (px, py) = self.compute_pixel_offset(cam_x, cam_y);
        let start_x = if repeat_x { -px.rem_euclid(tex_w) } else { -px };
        let start_y = if repeat_y { -py.rem_euclid(tex_h) } else { -py };
        let tiles = crate::parallax::tile_iter::collect_tiled_positions(
            start_x,
            start_y,
            tex_w,
            tex_h,
            repeat_x,
            repeat_y,
            [screen_w, screen_h],
        );
        let [tr, tg, tb, ta] = self.tint;
        let color = [tr, tg, tb, ta * self.opacity];
        let mut sx = if self.texture_width > 0.0 {
            tex_w / self.texture_width
        } else {
            self.scale[0]
        };
        let mut sy = if self.texture_height > 0.0 {
            tex_h / self.texture_height
        } else {
            self.scale[1]
        };
        let mut effect = self.effect_chain.clone();
        if self.motion_stretch_enabled {
            let speed_x = self.autoscroll[0].abs();
            let speed_y = self.autoscroll[1].abs();
            let max_extra = (self.motion_stretch_max_scale - 1.0).max(0.0);
            let sx_extra = (speed_x * self.motion_stretch_strength).min(max_extra);
            let sy_extra = (speed_y * self.motion_stretch_strength).min(max_extra);
            sx *= 1.0 + sx_extra;
            sy *= 1.0 + sy_extra;
            let speed = (speed_x * speed_x + speed_y * speed_y).sqrt();
            if speed > 1.0 {
                let mut params = HashMap::new();
                params.insert("strength".to_string(), (speed * 0.001).clamp(0.0, 1.0));
                params.insert(
                    "direction_x".to_string(),
                    if speed > 0.0 {
                        self.autoscroll[0] / speed
                    } else {
                        0.0
                    },
                );
                params.insert(
                    "direction_y".to_string(),
                    if speed > 0.0 {
                        self.autoscroll[1] / speed
                    } else {
                        0.0
                    },
                );
                let mut chain = effect.unwrap_or_default();
                chain.push(ShaderPassDescriptor {
                    effect_name: "motion_blur".to_string(),
                    params,
                    enabled: true,
                });
                effect = Some(chain);
            }
        }
        Some(ParallaxDrawBatch {
            texture_key: self.texture_key,
            tiles,
            sx,
            sy,
            color,
            blend_mode: self.blend_mode,
            effect,
        })
    }
    pub fn reset_autoscroll(&mut self) {
        self.autoscroll_accum = [0.0, 0.0];
    }
    pub fn set_tiling(&mut self, enabled: bool) {
        self.tiling = enabled;
    }
    pub fn get_tiling(&self) -> bool {
        self.tiling
    }
    pub fn set_tile_size(&mut self, w: f32, h: f32) {
        self.tile_w = if w > 0.0 {
            Some(w.max(MIN_TILE_SIZE))
        } else {
            None
        };
        self.tile_h = if h > 0.0 {
            Some(h.max(MIN_TILE_SIZE))
        } else {
            None
        };
    }
    pub fn set_depth(&mut self, z: f32) {
        self.depth = z;
    }
    pub fn get_depth(&self) -> f32 {
        self.depth
    }
    pub fn set_effect_chain(&mut self, chain: Vec<ShaderPassDescriptor>) {
        self.effect_chain = if chain.is_empty() { None } else { Some(chain) };
    }
    pub fn clear_effect_chain(&mut self) {
        self.effect_chain = None;
    }
    pub fn effect_count(&self) -> usize {
        self.effect_chain.as_ref().map_or(0, Vec::len)
    }
    pub fn set_motion_stretch(&mut self, enabled: bool, strength: f32, max_scale: f32) {
        self.motion_stretch_enabled = enabled;
        self.motion_stretch_strength = strength.max(0.0);
        self.motion_stretch_max_scale = max_scale.max(1.0);
    }
}
