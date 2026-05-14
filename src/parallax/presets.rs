//! Named preset constructors for common parallax layer configurations.
//! Returns fully-configured `ParallaxLayer` instances; callers add to their layer list unchanged.
//! Does not own textures; callers supply `TextureKey` values from the asset system.

use crate::parallax::ParallaxLayer;
use crate::render::BlendMode;
use crate::runtime::resource_keys::TextureKey;
/// Create a slow far-background layer (scroll factor ~0.15 horizontal); horizontal repeat, Z = -200, opacity 0.8.
pub fn far_background(texture_key: TextureKey, texture_w: f32, texture_h: f32) -> ParallaxLayer {
    let mut layer = ParallaxLayer::new(texture_key, texture_w, texture_h);
    layer.scroll_factor = [0.15, 0.05];
    layer.repeat_x = true;
    layer.repeat_y = false;
    layer.z = -200;
    layer.opacity = 0.8;
    layer
}
/// Create a mid-speed background layer (scroll factor ~0.45 horizontal); horizontal repeat, Z = -100, opacity 0.9.
pub fn mid_background(texture_key: TextureKey, texture_w: f32, texture_h: f32) -> ParallaxLayer {
    let mut layer = ParallaxLayer::new(texture_key, texture_w, texture_h);
    layer.scroll_factor = [0.45, 0.15];
    layer.repeat_x = true;
    layer.repeat_y = false;
    layer.z = -100;
    layer.opacity = 0.9;
    layer
}
/// Create a near-screen fog layer: fast scroll, tiled, Screen blend, 35% opacity, light motion-stretch blur, Z = 50.
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
