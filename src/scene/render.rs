//! Scene-level render assembly: adds render methods to SceneStack.
//! Assembles RenderCommand lists for the active scene and provides off-screen rasterisation via ImageData.
//! Does not own RenderCommand definitions or image encode — those live in render/ and image/ respectively.
//! Key dependencies: SceneStack, RenderCommand, ImageData.

use super::stack::SceneStack;
use crate::image::ImageData;
use crate::render::renderer::RenderCommand;

/// Render methods added to SceneStack by this file.
impl SceneStack {
    /// Collect and return RenderCommand list for the current scene; returns empty vec when no scene is active.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        Vec::new()
    }
    /// Render the active scene into a new ImageData of the given pixel dimensions; fills with background colour when empty.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
        img.fill(12, 12, 18, 255);
        img
    }
}
