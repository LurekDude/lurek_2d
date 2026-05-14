//! Core Sprite type: a positioned, scaled, rotated, and tinted texture reference.
//! Owns Sprite and its transform/color setters; does not own draw commands or texture upload.
//! Callers read Sprite fields to emit RenderCommands in the render pipeline.
//! Key dependencies: math::Vec2, math::Color.

use crate::math::Color;
use crate::math::Vec2;

/// A single drawable texture instance with position, scale, rotation, and colour tint.
pub struct Sprite {
    /// Index of the texture resource used to draw this sprite.
    pub texture_id: usize,
    /// World-space position of the sprite anchor in pixels.
    pub position: Vec2,
    /// Non-uniform scale applied to the sprite dimensions; (1, 1) = no scale.
    pub scale: Vec2,
    /// Rotation angle in radians counter-clockwise around the anchor.
    pub rotation: f32,
    /// Colour tint multiplied with the texture samples; WHITE = no tint.
    pub color: Color,
}
/// Constructor and transform setters for Sprite.
impl Sprite {
    /// Create a sprite at position with identity scale, zero rotation, and white tint.
    pub fn new(texture_id: usize, position: Vec2) -> Self {
        Sprite {
            texture_id,
            position,
            scale: Vec2::ONE,
            rotation: 0.0,
            color: Color::WHITE,
        }
    }
    /// Set the world-space position to (x, y).
    pub fn set_position(&mut self, x: f32, y: f32) {
        self.position = Vec2::new(x, y);
    }
    /// Set the non-uniform scale to (sx, sy).
    pub fn set_scale(&mut self, sx: f32, sy: f32) {
        self.scale = Vec2::new(sx, sy);
    }
    /// Set the rotation angle in radians.
    pub fn set_rotation(&mut self, rotation: f32) {
        self.rotation = rotation;
    }
    /// Replace the colour tint.
    pub fn set_color(&mut self, color: Color) {
        self.color = color;
    }
}
