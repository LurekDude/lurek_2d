
//! - Defines the single-frame record used by the animation runtime to pair a source rectangle with optional per-frame timing.
//! - Keeps the minimal frame payload shared by clips, controllers, previews, and imported metadata.
//! - Preserves the older public alias so existing code can keep referring to the same frame type through its legacy name.

use crate::math::Rect;
/// Frame rectangle and duration.
#[derive(Debug, Clone)]
pub struct AnimFrame {
    /// Source rectangle for the frame.
    pub quad: Rect,
    /// Duration in seconds; 0 uses clip FPS.
    pub duration: f32,
}
impl AnimFrame {
    /// Create a new animation frame.
    pub fn new(quad: Rect, duration: f32) -> Self {
        Self { quad, duration }
    }
}
/// Backward-compatible alias for `AnimFrame`.
pub type AnimationFrame = AnimFrame;
