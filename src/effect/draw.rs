use super::stack::PostFxStack;
use crate::image::ImageData;
impl PostFxStack {
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);
        let has_enabled = self.enabled.iter().any(|&e| e);
        if has_enabled {
            img.fill(45, 20, 65, 255);
        } else {
            img.fill(18, 18, 18, 255);
        }
        img
    }
}
