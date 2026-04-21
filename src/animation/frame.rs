//! [`AnimFrame`] â€” a single animation frame with a source rectangle and optional duration.

use crate::math::Rect;

/// A single animation frame with a source rectangle and optional duration.
///
/// # Fields
/// - `quad` â€” `Rect`.
/// - `duration` â€” `f32`.
///
/// If `duration` is `0.0`, the owning clip's FPS controls timing instead.
#[derive(Debug, Clone)]
pub struct AnimFrame {
    /// Source rectangle (quad) within the sprite-sheet texture.
    pub quad: Rect,
    /// Per-frame duration override in seconds. When `> 0.0` this value
    /// takes priority over the clip's FPS.
    pub duration: f32,
}

// â”€â”€ Backward-compatibility alias â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Backward-compatible alias for [`AnimFrame`].
///
/// Existing code that imports `AnimationFrame` from `crate::graphics` will
/// continue to compile after the Phase 24 rewrite.
pub type AnimationFrame = AnimFrame;
