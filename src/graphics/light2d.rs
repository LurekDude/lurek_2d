//! 2D point light data container for lighting systems.

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

    /// Sets the light's world-space position.
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

    /// Sets the light's influence radius.
    ///
    /// # Parameters
    /// - `radius` — `f32`.
    pub fn set_radius(&mut self, radius: f32) {
        self.radius = radius;
    }

    /// Returns the light's influence radius.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_radius(&self) -> f32 {
        self.radius
    }

    /// Sets the light's tint color.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_color(&mut self, color: Color) {
        self.color = color;
    }

    /// Returns the light's tint color.
    ///
    /// # Returns
    /// `Color`.
    pub fn get_color(&self) -> Color {
        self.color
    }

    /// Sets the light's brightness multiplier.
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

    /// Sets whether the light is active.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_enabled(&mut self, enabled: bool) {
        self.enabled = enabled;
    }

    /// Returns whether the light is active.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }
}
