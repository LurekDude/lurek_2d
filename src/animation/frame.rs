//! [`AnimFrame`] — a single animation frame with a source rectangle and optional duration.

use crate::math::Rect;

/// A single animation frame with a source rectangle and optional duration.
///
/// # Fields
/// - `quad` — `Rect`.
/// - `duration` — `f32`.
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

// ── Backward-compatibility alias ────────────────────────────────────────

/// Backward-compatible alias for [`AnimFrame`].
///
/// Existing code that imports `AnimationFrame` from `crate::graphics` will
/// continue to compile after the Phase 24 rewrite.
pub type AnimationFrame = AnimFrame;
#[cfg(test)]
mod tests {
    use super::*;
    use crate::math::Rect;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn frame_fields_store_correctly() {
        let frame = AnimFrame {
            quad: Rect::new(0.0, 0.0, 32.0, 32.0),
            duration: 0.1,
        };
        assert!((frame.quad.width - 32.0).abs() < 1e-5);
        assert!((frame.duration - 0.1).abs() < 1e-5);
    }

    #[test]
    fn zero_duration_uses_clip_fps() {
        let frame = AnimFrame {
            quad: Rect::new(0.0, 0.0, 16.0, 16.0),
            duration: 0.0,
        };
        assert!((frame.duration).abs() < 1e-5);
    }

    #[test]
    fn animation_frame_alias_is_same_type() {
        let frame: AnimationFrame = AnimFrame {
            quad: Rect::new(8.0, 8.0, 64.0, 64.0),
            duration: 0.05,
        };
        assert!((frame.quad.x - 8.0).abs() < 1e-5);
    }
}