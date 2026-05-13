use super::vec2::Vec2;
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Circle {
    pub x: f32,
    pub y: f32,
    pub radius: f32,
}
impl Circle {
    pub fn new(x: f32, y: f32, radius: f32) -> Self {
        Circle {
            x,
            y,
            radius: radius.max(0.0),
        }
    }
    pub fn center(&self) -> Vec2 {
        Vec2::new(self.x, self.y)
    }
    pub fn area(&self) -> f32 {
        std::f32::consts::PI * self.radius * self.radius
    }
    pub fn perimeter(&self) -> f32 {
        2.0 * std::f32::consts::PI * self.radius
    }
    pub fn contains(&self, px: f32, py: f32) -> bool {
        let dx = px - self.x;
        let dy = py - self.y;
        dx * dx + dy * dy <= self.radius * self.radius
    }
    pub fn intersects(&self, other: &Circle) -> bool {
        let dx = other.x - self.x;
        let dy = other.y - self.y;
        let sum_r = self.radius + other.radius;
        dx * dx + dy * dy < sum_r * sum_r
    }
    pub fn aabb(&self) -> (f32, f32, f32, f32) {
        (
            self.x - self.radius,
            self.y - self.radius,
            self.x + self.radius,
            self.y + self.radius,
        )
    }
}
