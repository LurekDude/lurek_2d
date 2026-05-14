//! Bridge helpers that convert `ImageData` into `RenderCommand` payloads.
//! Owns the `generate_render_commands` and `draw_to_image` helpers on `ImageData`.
//! Does not own GPU pipeline state — callers submit returned commands to the renderer.
//! Depends on `RenderCommand` from `src/render/` and `TextureKey` from runtime resource keys.

use super::image_data::ImageData;
use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::TextureKey;
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
