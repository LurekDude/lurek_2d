//! Persistent surface for stamping decal textures.
//!
//! A simple data container describing an off-screen render target
//! onto which decals can be composited.

/// Persistent render target for stamping decals.
///
/// Stores the target dimensions. Actual pixel data and GPU resources
/// are managed separately by the renderer.
pub struct DecalSurface {
    /// Width of the surface in pixels.
    pub width: u32,
    /// Height of the surface in pixels.
    pub height: u32,
}

impl DecalSurface {
    /// Creates a new decal surface with the given pixel dimensions.
    pub fn new(width: u32, height: u32) -> Self {
        Self { width, height }
    }

    /// Returns the surface dimensions as `(width, height)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Returns the surface width in pixels.
    pub fn get_width(&self) -> u32 {
        self.width
    }

    /// Returns the surface height in pixels.
    pub fn get_height(&self) -> u32 {
        self.height
    }
}
