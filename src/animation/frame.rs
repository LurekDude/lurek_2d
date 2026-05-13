//! Animation frame geometry and optional per-frame duration.
//! Owns `AnimFrame` and the `AnimationFrame` alias.
//! Does not own texture data; it only stores quad coordinates.
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
