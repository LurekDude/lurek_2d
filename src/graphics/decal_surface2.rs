//! Persistent surface for stamping decal textures.
//!
//! A simple data container describing an off-screen render target
//! onto which decals can be composited.
//!
//! This module is part of Luna2D's `graphics` subsystem and provides the implementation
//! details for decal surface-related operations and data management.
//! Key types exported from this module: `DecalSurface`.
//! Primary functions: `new()`, `get_dimensions()`, `get_width()`, `get_height()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Persistent render target for stamping decals.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
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
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        Self { width, height }
    }

    /// Returns the surface dimensions as `(width, height)`.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Returns the surface width in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_width(&self) -> u32 {
        self.width
    }

    /// Returns the surface height in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_height(&self) -> u32 {
        self.height
    }
}
