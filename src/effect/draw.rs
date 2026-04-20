//! CPU software-rendering fallback for the effect module.
//!
//! Provides `draw_to_image()` on [`PostFxStack`] for headless testing.
//! GPU post-processing render commands live in `src/effect/render.rs`.
//! Pure CPU — no wgpu, winit, or mlua imports.

use crate::image::ImageData;

use super::stack::PostFxStack;

impl PostFxStack {
    /// Render the post-processing stack to a CPU image for headless testing.
    ///
    /// Returns a solid image whose colour indicates whether the stack has any
    /// enabled effects: a violet tint when active, dark grey when inactive.
    /// No GPU shader passes are applied; this is a CPU-only representation.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width in pixels.
    /// - `height` — `u32`. Output image height in pixels.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);

        let has_enabled = self.enabled.iter().any(|&e| e);
        if has_enabled {
            // Violet tint to indicate an active post-fx stack.
            img.fill(45, 20, 65, 255);
        } else {
            img.fill(18, 18, 18, 255);
        }

        img
    }
}

// ── Tests ────────────────────────────────────────────────────────────────────
