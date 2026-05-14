//! `SpriteProjection` result record produced when mapping a world-space billboard
//! to screen space for depth-buffered rendering. Consumed by `build_scene` and
//! `depth_buffer` to test occlusion and emit `BillboardSprite` quads.

/// Screen-space projection of a single world billboard; used for depth-buffer occlusion.
#[derive(Debug, Clone)]
pub struct SpriteProjection {
    /// Horizontal screen coordinate of the sprite center in pixels.
    pub screen_x: f32,
    /// Uniform pixel scale applied to the billboard quad.
    pub scale: f32,
    /// Perpendicular camera-plane distance to the sprite.
    pub distance: f32,
    /// False when the sprite is behind the camera or outside horizontal bounds.
    pub visible: bool,
}
