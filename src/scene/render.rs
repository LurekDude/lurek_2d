use super::stack::SceneStack;
use crate::image::ImageData;
use crate::render::renderer::RenderCommand;
impl SceneStack {
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        Vec::new()
    }
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
        img.fill(12, 12, 18, 255);
        img
    }
}
