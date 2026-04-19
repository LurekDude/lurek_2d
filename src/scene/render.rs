//! Render-command generation and CPU drawing for the scene module.
//!
//! [`SceneStack`] is a pure ID-based LIFO stack â€” it stores no render data,
//! only scene identifiers. GPU rendering is driven by Lua-side `draw()`
//! callbacks; the Rust domain layer has no scene content to iterate.
//!
//! These implementations satisfy the render-command interface contract so
//! that `SceneStack` participates uniformly in the engine draw pipeline.
//! Pure CPU â€” no wgpu, winit, or mlua imports.

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
    /// - `width` â€” `u32`. Output image width in pixels.
    /// - `height` â€” `u32`. Output image height in pixels.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
        img.fill(12, 12, 18, 255);
        img
    }
}

// â”€â”€ Tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// Tests migrated to tests/rust/unit/scene_tests.rs
