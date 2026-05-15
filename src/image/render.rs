//! - Convert an image buffer into GPU render commands for on-screen display.
//! - Provide cloning helpers to snapshot pixel data as standalone values.
//! - Bridge between ImageData and the engine's RenderCommand pipeline.

use super::image_data::ImageData;
use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::TextureKey;

/// Rendering and snapshot helpers for image buffers.
impl ImageData {
    /// Generate draw commands for this image buffer at the given screen position.
    pub fn generate_render_commands(
        &self,
        texture_key: TextureKey,
        x: f32,
        y: f32,
    ) -> Vec<RenderCommand> {
        vec![RenderCommand::DrawImage {
            texture_key,
            x,
            y,
            effect: None,
        }]
    }
    /// Clone the image buffer into a standalone image value.
    pub fn draw_to_image(&self) -> ImageData {
        self.clone()
    }
}
