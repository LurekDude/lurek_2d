//! Ready-to-use parallax layer presets for common background setups.

use crate::parallax::ParallaxLayer;
use crate::render::BlendMode;
use crate::runtime::resource_keys::TextureKey;

/// Creates a far-background preset layer.
pub fn far_background(texture_key: TextureKey, texture_w: f32, texture_h: f32) -> ParallaxLayer {
    let mut layer = ParallaxLayer::new(texture_key, texture_w, texture_h);
    layer.scroll_factor = [0.15, 0.05];
    layer.repeat_x = true;
    layer.repeat_y = false;
    layer.z = -200;
    layer.opacity = 0.8;
    layer
}

/// Creates a mid-background preset layer.
pub fn mid_background(texture_key: TextureKey, texture_w: f32, texture_h: f32) -> ParallaxLayer {
    let mut layer = ParallaxLayer::new(texture_key, texture_w, texture_h);
    layer.scroll_factor = [0.45, 0.15];
    layer.repeat_x = true;
    layer.repeat_y = false;
    layer.z = -100;
    layer.opacity = 0.9;
    layer
}

/// Creates a foreground-fog preset with additive blending and gentle autoscroll.
pub fn foreground_fog(texture_key: TextureKey, texture_w: f32, texture_h: f32) -> ParallaxLayer {
    let mut layer = ParallaxLayer::new(texture_key, texture_w, texture_h);
    layer.scroll_factor = [0.9, 0.4];
    layer.autoscroll = [8.0, 0.0];
    layer.repeat_x = true;
    layer.repeat_y = true;
    layer.tiling = true;
    layer.opacity = 0.35;
    layer.blend_mode = BlendMode::Screen;
    layer.set_motion_stretch(true, 0.002, 1.4);
    layer.z = 50;
    layer
}
