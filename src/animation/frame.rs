//! Represent one animation frame and compatibility aliases.

use crate::math::Rect;

// ---- Type: AnimFrame ----

/// A single animation frame with a source rectangle and optional duration.
#[derive(Debug, Clone)]
pub struct AnimFrame {
    /// Source rectangle (quad) within the sprite-sheet texture.
    pub quad: Rect,
    /// Per-frame duration override in seconds. When `> 0.0` this value
    /// takes priority over the clip's FPS.
    pub duration: f32,
}

impl AnimFrame {
    // ---- Implementation: AnimFrame ----
    /// Create a new frame from source quad and duration.
    pub fn new(quad: Rect, duration: f32) -> Self {
        Self { quad, duration }
    }
}

// ---- Type: AnimationFrame Alias ----

/// Deprecated name for `AnimFrame`; retained for compatibility.
pub type AnimationFrame = AnimFrame;
