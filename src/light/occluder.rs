//! - Convex polygon shape that blocks light and casts shadows in the 2D lighting system.
//! - Vertex management: construction from Vec2 list or flat coordinate arrays, runtime replacement.
//! - Per-occluder properties: world position offset, shadow opacity, light-layer bitmask, enabled toggle.

use crate::math::Vec2;

/// Convex polygon shape that blocks light and casts shadows in `LightWorld`.
pub struct Occluder {
    /// Polygon vertices in local space; must be 3..=512 elements.
    pub vertices: Vec<Vec2>,
    /// World-space offset applied to all vertices during shadow projection.
    pub position: Vec2,
    /// Shadow opacity in [0.0, 1.0]; 1.0 = fully opaque, 0.0 = transparent.
    pub opacity: f32,
    /// Bitmask selecting which lights this occluder casts shadows for.
    pub light_mask: u16,
    /// Whether this occluder participates in shadow computation; when false, it is skipped.
    pub enabled: bool,
}
impl Occluder {
    /// Create an occluder from vertices; panics if count is outside 3..=512.
    pub fn new(vertices: Vec<Vec2>) -> Self {
        assert!(
            vertices.len() >= 3 && vertices.len() <= 512,
            "Occluder vertex count must be 3..=512, got {}",
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
    /// Replace vertices; panics if new count is outside 3..=512.
    pub fn set_vertices(&mut self, vertices: Vec<Vec2>) {
        assert!(
            vertices.len() >= 3 && vertices.len() <= 512,
            "Occluder vertex count must be 3..=512, got {}",
            vertices.len()
        );
        self.vertices = vertices;
    }
    /// Build an occluder from a flat `[x, y, x, y, ...]` coordinate slice; returns error on invalid length.
    pub fn from_flat_coords(flat: &[f32]) -> Result<Self, String> {
        if flat.len() < 6 || flat.len() > 1024 || !flat.len().is_multiple_of(2) {
            return Err(format!(
                "vertex array must have 6..=1024 coordinates (3..=512 vertices), got {}",
                flat.len()
            ));
        }
        let verts: Vec<Vec2> = flat.chunks(2).map(|c| Vec2::new(c[0], c[1])).collect();
        Ok(Self::new(verts))
    }
    /// Return the vertex slice. This function is part of the public API.
    pub fn get_vertices(&self) -> &[Vec2] {
        &self.vertices
    }
    /// Set the world-space position offset.
    pub fn set_position(&mut self, position: Vec2) {
        self.position = position;
    }
    /// Return the world-space position offset.
    pub fn get_position(&self) -> Vec2 {
        self.position
    }
    /// Set shadow opacity; expected range [0.0, 1.0].
    pub fn set_opacity(&mut self, opacity: f32) {
        self.opacity = opacity;
    }
    /// Return shadow opacity. This function is part of the public API.
    pub fn get_opacity(&self) -> f32 {
        self.opacity
    }
    /// Set the light-layer bitmask.
    pub fn set_light_mask(&mut self, mask: u16) {
        self.light_mask = mask;
    }
    /// Return the light-layer bitmask.
    pub fn get_light_mask(&self) -> u16 {
        self.light_mask
    }
    /// Enable or disable this occluder.
    pub fn set_enabled(&mut self, enabled: bool) {
        self.enabled = enabled;
    }
    /// Return whether this occluder is enabled.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }
}
