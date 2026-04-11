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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn draw_to_image_correct_dimensions() {
        let stack = PostFxStack::new(800, 600);
        let img = stack.draw_to_image(320, 240);
        assert_eq!(img.width(), 320);
        assert_eq!(img.height(), 240);
    }

    #[test]
    fn draw_to_image_empty_stack_is_dark() {
        let stack = PostFxStack::new(800, 600);
        let img = stack.draw_to_image(16, 16);
        if let Some((r, g, b, _)) = img.get_pixel(0, 0) {
            assert!(r < 30 && g < 30 && b < 30, "empty stack should be dark");
        }
    }

    #[test]
    fn draw_to_image_enabled_stack_is_tinted() {
        let mut stack = PostFxStack::new(800, 600);
        stack.add(0);
        let img = stack.draw_to_image(16, 16);
        if let Some((_, _, b, _)) = img.get_pixel(0, 0) {
            assert!(b > 30, "enabled stack should have visible violet tint");
        }
    }
}
