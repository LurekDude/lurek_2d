use super::image_data::ImageData;
use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::TextureKey;
impl ImageData {
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
    pub fn draw_to_image(&self) -> ImageData {
        self.clone()
    }
}
