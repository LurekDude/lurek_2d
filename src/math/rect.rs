use super::vec2::Vec2;
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Rect {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}
impl Rect {
    pub fn new(x: f32, y: f32, width: f32, height: f32) -> Self {
        Rect {
            x,
            y,
            width,
            height,
        }
    }
    pub fn center(&self) -> Vec2 {
        Vec2::new(self.x + self.width / 2.0, self.y + self.height / 2.0)
    }
    pub fn area(&self) -> f32 {
        self.width * self.height
    }
    pub fn contains(&self, point_x: f32, point_y: f32) -> bool {
        point_x >= self.x
            && point_x <= self.x + self.width
            && point_y >= self.y
            && point_y <= self.y + self.height
    }
    pub fn intersects(&self, other: &Rect) -> bool {
        self.x < other.x + other.width
            && self.x + self.width > other.x
            && self.y < other.y + other.height
            && self.y + self.height > other.y
    }
    pub fn intersect(&self, other: &Rect) -> Rect {
        let left = self.x.max(other.x);
        let top = self.y.max(other.y);
        let right = (self.x + self.width).min(other.x + other.width);
        let bottom = (self.y + self.height).min(other.y + other.height);
        if right > left && bottom > top {
            Rect::new(left, top, right - left, bottom - top)
        } else {
            Rect::new(0.0, 0.0, 0.0, 0.0)
        }
    }
    pub fn union(&self, other: &Rect) -> Rect {
        let left = self.x.min(other.x);
        let top = self.y.min(other.y);
        let right = (self.x + self.width).max(other.x + other.width);
        let bottom = (self.y + self.height).max(other.y + other.height);
        Rect::new(left, top, right - left, bottom - top)
    }
    pub fn from_center(cx: f32, cy: f32, w: f32, h: f32) -> Rect {
        Rect::new(cx - w / 2.0, cy - h / 2.0, w, h)
    }
    pub fn from_points(points: &[(f32, f32)]) -> Rect {
        if points.is_empty() {
            return Rect::new(0.0, 0.0, 0.0, 0.0);
        }
        let mut min_x = f32::MAX;
        let mut min_y = f32::MAX;
        let mut max_x = f32::MIN;
        let mut max_y = f32::MIN;
        for &(px, py) in points {
            if px < min_x {
                min_x = px;
            }
            if py < min_y {
                min_y = py;
            }
            if px > max_x {
                max_x = px;
            }
            if py > max_y {
                max_y = py;
            }
        }
        Rect::new(min_x, min_y, max_x - min_x, max_y - min_y)
    }
}
