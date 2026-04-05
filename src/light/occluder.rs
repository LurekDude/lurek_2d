//! Polygon shadow caster for the 2D lighting system.

use crate::math::Vec2;

/// Polygon shadow caster that blocks light.
///
/// # Fields
/// - `vertices` — `Vec<Vec2>`.
/// - `position` — `Vec2`.
/// - `opacity` — `f32`.
/// - `light_mask` — `u16`.
/// - `enabled` — `bool`.
///
/// An occluder defines a convex or concave polygon that casts shadows
/// when placed between a light source and the scene. The `light_mask`
/// field controls which lights this occluder interacts with.
pub struct Occluder {
    /// Polygon vertices in local space.
    pub vertices: Vec<Vec2>,
    /// Translation offset applied to all vertices.
    pub position: Vec2,
    /// Shadow opacity from 0.0 (transparent) to 1.0 (fully opaque).
    pub opacity: f32,
    /// Bitmask controlling which lights this occluder blocks.
    pub light_mask: u16,
    /// Whether this occluder is active.
    pub enabled: bool,
}

impl Occluder {
    /// Creates a new occluder from the given polygon vertices.
    ///
    /// # Parameters
    /// - `vertices` — `Vec<Vec2>`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// # Panics
    /// Panics if vertex count is less than 3 or greater than 256.
    ///
    /// Defaults: position = origin, opacity = 1.0, light_mask = 0xFFFF, enabled = true.
    pub fn new(vertices: Vec<Vec2>) -> Self {
        assert!(
            vertices.len() >= 3 && vertices.len() <= 256,
            "Occluder vertex count must be 3..=256, got {}",
            vertices.len()
        );
        Self {
            vertices,
            position: Vec2::ZERO,
            opacity: 1.0,
            light_mask: 0xFFFF,
            enabled: true,
        }
    }

    /// Sets the polygon vertices.
    ///
    /// # Parameters
    /// - `vertices` — `Vec<Vec2>`.
    ///
    /// # Panics
    /// Panics if vertex count is less than 3 or greater than 256.
    pub fn set_vertices(&mut self, vertices: Vec<Vec2>) {
        assert!(
            vertices.len() >= 3 && vertices.len() <= 256,
            "Occluder vertex count must be 3..=256, got {}",
            vertices.len()
        );
        self.vertices = vertices;
    }

    /// Returns a reference to the polygon vertices.
    ///
    /// # Returns
    /// `&[Vec2]`.
    pub fn get_vertices(&self) -> &[Vec2] {
        &self.vertices
    }

    /// Sets the translation offset.
    ///
    /// # Parameters
    /// - `position` — `Vec2`.
    pub fn set_position(&mut self, position: Vec2) {
        self.position = position;
    }

    /// Returns the translation offset.
    ///
    /// # Returns
    /// `Vec2`.
    pub fn get_position(&self) -> Vec2 {
        self.position
    }

    /// Sets the shadow opacity (0.0–1.0).
    ///
    /// # Parameters
    /// - `opacity` — `f32`.
    pub fn set_opacity(&mut self, opacity: f32) {
        self.opacity = opacity;
    }

    /// Returns the shadow opacity.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_opacity(&self) -> f32 {
        self.opacity
    }

    /// Sets the light interaction bitmask.
    ///
    /// # Parameters
    /// - `mask` — `u16`.
    pub fn set_light_mask(&mut self, mask: u16) {
        self.light_mask = mask;
    }

    /// Returns the light interaction bitmask.
    ///
    /// # Returns
    /// `u16`.
    pub fn get_light_mask(&self) -> u16 {
        self.light_mask
    }

    /// Sets whether this occluder is active.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_enabled(&mut self, enabled: bool) {
        self.enabled = enabled;
    }

    /// Returns whether this occluder is active.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }
}
