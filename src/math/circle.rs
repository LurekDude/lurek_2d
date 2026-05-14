use super::vec2::Vec2;

/// Axis-aligned circle defined by center position and non-negative radius.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Circle {
    /// X coordinate of the center.
    pub x: f32,
    /// Y coordinate of the center.
    pub y: f32,
    /// Radius; clamped to >= 0 on construction.
    pub radius: f32,
}

impl Circle {
    /// Construct a Circle; radius is clamped to >= 0.
    pub fn new(x: f32, y: f32, radius: f32) -> Self {
        Circle {
            x,
            y,
            radius: radius.max(0.0),
        }
    }

    /// Return the center as a Vec2.
    pub fn center(&self) -> Vec2 {
        Vec2::new(self.x, self.y)
    }

    /// Return π × r².
    pub fn area(&self) -> f32 {
        std::f32::consts::PI * self.radius * self.radius
    }

    /// Return 2 × π × r.
    pub fn perimeter(&self) -> f32 {
        2.0 * std::f32::consts::PI * self.radius
    }

    /// Return true when `(px, py)` lies inside or on the boundary of this circle.
    pub fn contains(&self, px: f32, py: f32) -> bool {
        let dx = px - self.x;
        let dy = py - self.y;
        dx * dx + dy * dy <= self.radius * self.radius
    }

    /// Return true when this circle and `other` overlap (touching counts as intersection).
    pub fn intersects(&self, other: &Circle) -> bool {
        let dx = other.x - self.x;
        let dy = other.y - self.y;
        let sum_r = self.radius + other.radius;
        dx * dx + dy * dy < sum_r * sum_r
    }

    /// Return the axis-aligned bounding box as `(min_x, min_y, max_x, max_y)`.
    pub fn aabb(&self) -> (f32, f32, f32, f32) {
        (
            self.x - self.radius,
            self.y - self.radius,
            self.x + self.radius,
            self.y + self.radius,
        )
    }
}
