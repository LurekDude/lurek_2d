//! 2D point light data container for lighting systems.
//!
//! This module is part of Luna2D's `graphics` subsystem and provides the implementation
//! details for light2d-related operations and data management.
//! Key types exported from this module: `Light2D`.
//! Primary functions: `new()`, `set_position()`, `get_position()`, `set_radius()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::graphics::Color;

/// 2D point light with position, radius, color, and intensity.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `radius` — `f32`.
/// - `color` — `Color`.
/// - `intensity` — `f32`.
/// - `enabled` — `bool`.
///
/// Stores all parameters needed to describe a circular light source
/// in 2D space: position, reach, tint, brightness, and on/off state.
pub struct Light2D {
    /// X position of the light in world space.
    pub x: f32,
    /// Y position of the light in world space.
    pub y: f32,
    /// Radius of the light's influence area.
    pub radius: f32,
    /// Tint color of the light.
    pub color: Color,
    /// Brightness multiplier (0.0 = off, 1.0 = normal).
    pub intensity: f32,
    /// Whether the light is active.
    pub enabled: bool,
}

impl Light2D {
    /// Creates a new white light at `(x, y)` with the given radius.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `radius` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Defaults: color = white, intensity = 1.0, enabled = true.
    pub fn new(x: f32, y: f32, radius: f32) -> Self {
        Self {
            x,
            y,
            radius,
            color: Color::WHITE,
            intensity: 1.0,
            enabled: true,
        }
    }

    /// Sets the light's world-space position. Replaces the current position value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn set_position(&mut self, x: f32, y: f32) {
        self.x = x;
        self.y = y;
    }

    /// Returns the light's world-space position as `(x, y)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_position(&self) -> (f32, f32) {
        (self.x, self.y)
    }

    /// Sets the light's influence radius. Replaces the current radius value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `radius` — `f32`.
    pub fn set_radius(&mut self, radius: f32) {
        self.radius = radius;
    }

    /// Returns the light's influence radius. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_radius(&self) -> f32 {
        self.radius
    }

    /// Sets the light's tint color. Replaces the current color value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_color(&mut self, color: Color) {
        self.color = color;
    }

    /// Returns the light's tint color. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Color`.
    pub fn get_color(&self) -> Color {
        self.color
    }

    /// Sets the light's brightness multiplier. Replaces the current intensity value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `intensity` — `f32`.
    pub fn set_intensity(&mut self, intensity: f32) {
        self.intensity = intensity;
    }

    /// Returns the light's brightness multiplier.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_intensity(&self) -> f32 {
        self.intensity
    }

    /// Sets whether the light is active. Replaces the current enabled value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_enabled(&mut self, enabled: bool) {
        self.enabled = enabled;
    }

    /// Returns whether the light is active. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }
}
