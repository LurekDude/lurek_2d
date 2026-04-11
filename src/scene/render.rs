//! Render-command generation and CPU drawing for the scene module.
//!
//! [`SceneStack`] is a pure ID-based LIFO stack — it stores no render data,
//! only scene identifiers. GPU rendering is driven by Lua-side `draw()`
//! callbacks; the Rust domain layer has no scene content to iterate.
//!
//! These implementations satisfy the render-command interface contract so
//! that `SceneStack` participates uniformly in the engine draw pipeline.
//! Pure CPU — no wgpu, winit, or mlua imports.

use crate::image::ImageData;
use crate::render::renderer::RenderCommand;

use super::stack::SceneStack;

impl SceneStack {
    /// Generate GPU render commands for the active scene.
    ///
    /// Returns an empty vec because scene draw data lives exclusively in
    /// Lua-side callbacks. The Rust domain stack holds only scene IDs and
    /// has no geometry to emit.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        Vec::new()
    }

    /// Render the scene stack state to a CPU image for headless testing.
    ///
    /// Returns a blank dark image because scene geometry exists only in
    /// Lua-side callbacks and cannot be reconstructed on the CPU side.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width in pixels.
    /// - `height` — `u32`. Output image height in pixels.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
        img.fill(12, 12, 18, 255);
        img
    }
}

// ── Tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generate_render_commands_always_empty() {
        let mut stack = SceneStack::new();
        let _ = stack.next_scene_id();
        let cmds = stack.generate_render_commands();
        assert!(cmds.is_empty(), "scene stack should return no render commands");
    }

    #[test]
    fn draw_to_image_correct_dimensions() {
        let stack = SceneStack::new();
        let img = stack.draw_to_image(320, 240);
        assert_eq!(img.width(), 320);
        assert_eq!(img.height(), 240);
    }

    #[test]
    fn draw_to_image_returns_dark_background() {
        let stack = SceneStack::new();
        let img = stack.draw_to_image(16, 16);
        if let Some((r, _, _, _)) = img.get_pixel(0, 0) {
            assert!(r < 30, "expected dark background pixel");
        }
    }
}
