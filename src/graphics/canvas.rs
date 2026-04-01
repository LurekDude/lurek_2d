//! Off-screen render targets (canvases) for deferred compositing.
//!
//! A `Canvas` stores the logical dimensions of an off-screen texture that the
//! GPU renderer can draw to.  After rendering, the canvas can be composited to
//! the screen (or another canvas) as a regular image.

/// An off-screen render target with a fixed pixel resolution.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// The GPU-side texture is managed by `GpuRenderer`; this struct holds only the
/// logical metadata exposed to the Lua API.
#[derive(Debug, Clone)]
pub struct Canvas {
    /// Width of the canvas in pixels.
    pub width: u32,
    /// Height of the canvas in pixels.
    pub height: u32,
}

impl Canvas {
    /// Creates a new `Canvas` descriptor with the given dimensions.
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
}
