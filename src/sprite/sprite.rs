use crate::math::Color;
use crate::math::Vec2;
pub struct Sprite {
    pub texture_id: usize,
    pub position: Vec2,
    pub scale: Vec2,
    pub rotation: f32,
    pub color: Color,
}
impl Sprite {
    pub fn new(texture_id: usize, position: Vec2) -> Self {
        Sprite {
            texture_id,
            position,
            scale: Vec2::ONE,
            rotation: 0.0,
            color: Color::WHITE,
        }
    }
    pub fn set_position(&mut self, x: f32, y: f32) {
        self.position = Vec2::new(x, y);
    }
    pub fn set_scale(&mut self, sx: f32, sy: f32) {
        self.scale = Vec2::new(sx, sy);
    }
    pub fn set_rotation(&mut self, rotation: f32) {
        self.rotation = rotation;
    }
    pub fn set_color(&mut self, color: Color) {
        self.color = color;
    }
}
