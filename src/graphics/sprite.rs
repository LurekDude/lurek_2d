//! Sprite implementation for the `graphics` subsystem.
//!
//! This module is part of Luna2D's `graphics` subsystem and provides the implementation
//! details for sprite-related operations and data management.
//! Key types exported from this module: `Sprite`.
//! Primary functions: `new()`, `set_position()`, `set_scale()`, `set_rotation()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use crate::graphics::Color;
use crate::math::Vec2;

/// A textured game object with position, scale, rotation, and tint color.
///
/// `Sprite` acts as a transform + tint wrapper around a `Texture`. It does not own
/// the texture; it references it by id in the renderer's texture atlas.
///
/// # Fields
/// - `texture_id` — Index into the renderer's texture atlas.
/// - `position` — World-space position of the sprite's origin.
/// - `scale` — Per-axis scale factor; `Vec2::ONE` = original size.
/// - `rotation` — Rotation in radians.
/// - `color` — Multiplicative tint applied to the texture; `Color::WHITE` = no tint.
pub struct Sprite {
    pub texture_id: usize,
    pub position: Vec2,
    pub scale: Vec2,
    pub rotation: f32,
    pub color: Color,
}

impl Sprite {
    /// Creates a new `Sprite` at `position` using the texture identified by `texture_id`.
    ///
    /// Defaults: scale = `Vec2::ONE`, rotation = 0.0, color = `Color::WHITE`.
    ///
    /// # Parameters
    /// - `texture_id` — Index into the renderer texture atlas.
    /// - `position` — Initial world-space position.
    ///
    /// # Returns
    /// A new `Sprite` ready for use.
    pub fn new(texture_id: usize, position: Vec2) -> Self {
        Sprite {
            texture_id,
            position,
            scale: Vec2::ONE,
            rotation: 0.0,
            color: Color::WHITE,
        }
    }

    /// Sets the world-space position of the sprite.
    ///
    /// # Parameters
    /// - `x` — New horizontal position.
    /// - `y` — New vertical position.
    pub fn set_position(&mut self, x: f32, y: f32) {
        self.position = Vec2::new(x, y);
    }

    /// Sets the per-axis scale of the sprite. Replaces the current scale value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `sx` — Horizontal scale factor.
    /// - `sy` — Vertical scale factor.
    pub fn set_scale(&mut self, sx: f32, sy: f32) {
        self.scale = Vec2::new(sx, sy);
    }

    /// Sets the rotation of the sprite in radians.
    ///
    /// # Parameters
    /// - `rotation` — Rotation angle in radians.
    pub fn set_rotation(&mut self, rotation: f32) {
        self.rotation = rotation;
    }

    /// Sets the multiplicative tint color applied to the sprite.
    ///
    /// # Parameters
    /// - `color` — New tint color; use `Color::WHITE` for no tint.
    pub fn set_color(&mut self, color: Color) {
        self.color = color;
    }
}
