//! `DecalSurface` — a fixed-size surface used as a paint target for persistent decals.
//! Carries only pixel dimensions; does not own GPU textures or pixel data.
//! Consumed by the Lua decal API and the GPU renderer upload path.

/// Paint-target surface for persistent world decals; holds pixel dimensions only.
pub struct DecalSurface {
    /// Pixel width of this surface.
    pub width: u32,
    /// Pixel height of this surface.
    pub height: u32,
}

impl DecalSurface {
    /// Create a `DecalSurface` sized `width` × `height` pixels.
    pub fn new(width: u32, height: u32) -> Self {
        Self { width, height }
    }
    /// Return `(width, height)` as a tuple.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    /// Return the pixel width.
    pub fn get_width(&self) -> u32 {
        self.width
    }
    /// Return the pixel height.
    pub fn get_height(&self) -> u32 {
        self.height
    }
}
