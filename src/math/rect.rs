//! Axis-aligned rectangle defined by top-left corner and size.
//! Provides containment, intersection, union, and construction helpers.
//! Used by UI layout, camera bounds, collision broadphase, and texture sub-regions.
//! Does not own physics shapes — rapier uses its own AABB type.

use super::vec2::Vec2;

/// Axis-aligned rectangle with position and size; used for bounds, layout regions, and UV rects.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Rect {
    /// Left edge x coordinate.
    pub x: f32,
    /// Top edge y coordinate (y-down convention).
    pub y: f32,
    /// Width in the x direction; must be non-negative for correct containment checks.
    pub width: f32,
    /// Height in the y direction; must be non-negative for correct containment checks.
    pub height: f32,
}

impl Rect {
    /// Construct a Rect from top-left position and size.
    pub fn new(x: f32, y: f32, width: f32, height: f32) -> Self {
        Rect {
            x,
            y,
            width,
            height,
        }
    }

    /// Return the center point of this rectangle.
    pub fn center(&self) -> Vec2 {
        Vec2::new(self.x + self.width / 2.0, self.y + self.height / 2.0)
    }

    /// Return the area (width × height).
    pub fn area(&self) -> f32 {
        self.width * self.height
    }

    /// Return true when `(point_x, point_y)` lies inside or on the boundary of this rect.
    pub fn contains(&self, point_x: f32, point_y: f32) -> bool {
        point_x >= self.x
            && point_x <= self.x + self.width
            && point_y >= self.y
            && point_y <= self.y + self.height
    }

    /// Return true when this rect overlaps `other` (touching edges count as overlap).
    pub fn intersects(&self, other: &Rect) -> bool {
        self.x < other.x + other.width
            && self.x + self.width > other.x
            && self.y < other.y + other.height
            && self.y + self.height > other.y
    }

    /// Return the overlapping region of `self` and `other`; returns zero-size rect when disjoint.
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

    /// Return the smallest rect that contains both `self` and `other`.
    pub fn union(&self, other: &Rect) -> Rect {
        let left = self.x.min(other.x);
        let top = self.y.min(other.y);
        let right = (self.x + self.width).max(other.x + other.width);
        let bottom = (self.y + self.height).max(other.y + other.height);
        Rect::new(left, top, right - left, bottom - top)
    }

    /// Construct a rect centered at `(cx, cy)` with given `w` and `h`.
    pub fn from_center(cx: f32, cy: f32, w: f32, h: f32) -> Rect {
        Rect::new(cx - w / 2.0, cy - h / 2.0, w, h)
    }

    /// Return the tight bounding rect around a slice of `(x, y)` points; returns zero rect for empty slice.
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
