//! Rect implementation for the `math` subsystem.
//!
//! This module is part of Luna2D's `math` subsystem and provides the implementation
//! details for rect-related operations and data management.
//! Key types exported from this module: `Rect`.
//! Primary functions: `new()`, `center()`, `area()`, `contains()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use super::vec2::Vec2;

/// An axis-aligned rectangle defined by its top-left corner and dimensions.
///
/// Used for AABB collision detection, UI layout, and camera viewport clipping.
///
/// # Fields
/// - `x` — X coordinate of the top-left corner.
/// - `y` — Y coordinate of the top-left corner.
/// - `width` — Width in pixels or world units.
/// - `height` — Height in pixels or world units.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Rect {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}

impl Rect {
    /// Creates a new `Rect` at `(x, y)` with the given `width` and `height`.
    ///
    /// # Parameters
    /// - `x` — Left edge X coordinate.
    /// - `y` — Top edge Y coordinate.
    /// - `width` — Rectangle width.
    /// - `height` — Rectangle height.
    ///
    /// # Returns
    /// A new `Rect`.
    pub fn new(x: f32, y: f32, width: f32, height: f32) -> Self {
        Rect {
            x,
            y,
            width,
            height,
        }
    }

    /// Returns the center point of the rectangle.
    ///
    /// # Returns
    /// `Vec2` — The midpoint `(x + width/2, y + height/2)`.
    pub fn center(&self) -> Vec2 {
        Vec2::new(self.x + self.width / 2.0, self.y + self.height / 2.0)
    }

    /// Returns the area of the rectangle. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f32` — `width × height`.
    pub fn area(&self) -> f32 {
        self.width * self.height
    }

    /// Returns `true` if the given point lies within or on the boundary of the rectangle.
    ///
    /// # Parameters
    /// - `point_x` — X coordinate of the point to test.
    /// - `point_y` — Y coordinate of the point to test.
    ///
    /// # Returns
    /// `bool` — `true` if the point is inside or on the edge.
    pub fn contains(&self, point_x: f32, point_y: f32) -> bool {
        point_x >= self.x
            && point_x <= self.x + self.width
            && point_y >= self.y
            && point_y <= self.y + self.height
    }

    /// Returns `true` if this rectangle overlaps with `other`.
    ///
    /// Touch (shared edge) is not considered an intersection; the overlap must be positive.
    ///
    /// # Parameters
    /// - `other` — The rectangle to test against.
    ///
    /// # Returns
    /// `bool` — `true` if the two rectangles have positive-area overlap.
    pub fn intersects(&self, other: &Rect) -> bool {
        self.x < other.x + other.width
            && self.x + self.width > other.x
            && self.y < other.y + other.height
            && self.y + self.height > other.y
    }

    /// Computes the rectangle intersection of `self` and `other`.
    ///
    /// Returns a zero-area rectangle at the origin if the two rectangles do not overlap.
    ///
    /// # Parameters
    /// - `other` — `&Rect`.
    ///
    /// # Returns
    /// `Rect`.
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
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn new_fields_correct() {
        let r = Rect::new(10.0, 20.0, 100.0, 50.0);
        assert!((r.x - 10.0).abs() < 1e-5);
        assert!((r.y - 20.0).abs() < 1e-5);
        assert!((r.width - 100.0).abs() < 1e-5);
        assert!((r.height - 50.0).abs() < 1e-5);
    }

    // ── Geometry ──────────────────────────────────────────────────────────────

    #[test]
    fn center_midpoint_correct() {
        let r = Rect::new(10.0, 20.0, 100.0, 50.0);
        let c = r.center();
        assert!((c.x - 60.0).abs() < 1e-5);
        assert!((c.y - 45.0).abs() < 1e-5);
    }

    #[test]
    fn area_product_correct() {
        let r = Rect::new(0.0, 0.0, 100.0, 50.0);
        assert!((r.area() - 5000.0).abs() < 1e-5);
    }

    #[test]
    fn zero_area_rect_area_zero() {
        let r = Rect::new(5.0, 5.0, 0.0, 0.0);
        assert!((r.area()).abs() < 1e-5);
    }

    // ── Contains ─────────────────────────────────────────────────────────────

    #[test]
    fn contains_inside_true() {
        let r = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(r.contains(50.0, 50.0));
    }

    #[test]
    fn contains_outside_false() {
        let r = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(!r.contains(200.0, 200.0));
    }

    #[test]
    fn contains_on_edge_true() {
        let r = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(r.contains(0.0, 0.0));
        assert!(r.contains(100.0, 100.0));
    }

    // ── Intersects ───────────────────────────────────────────────────────────

    #[test]
    fn intersects_overlapping_true() {
        let a = Rect::new(0.0, 0.0, 10.0, 10.0);
        let b = Rect::new(5.0, 5.0, 10.0, 10.0);
        assert!(a.intersects(&b));
    }

    #[test]
    fn intersects_non_overlapping_false() {
        let a = Rect::new(0.0, 0.0, 10.0, 10.0);
        let b = Rect::new(20.0, 20.0, 10.0, 10.0);
        assert!(!a.intersects(&b));
    }

    #[test]
    fn intersect_overlap_area_correct() {
        let a = Rect::new(0.0, 0.0, 10.0, 10.0);
        let b = Rect::new(5.0, 5.0, 10.0, 10.0);
        let overlap = a.intersect(&b);
        assert!((overlap.x - 5.0).abs() < 1e-5);
        assert!((overlap.y - 5.0).abs() < 1e-5);
        assert!((overlap.width - 5.0).abs() < 1e-5);
        assert!((overlap.height - 5.0).abs() < 1e-5);
    }

    #[test]
    fn intersect_non_overlapping_returns_zero_rect() {
        let a = Rect::new(0.0, 0.0, 5.0, 5.0);
        let b = Rect::new(10.0, 10.0, 5.0, 5.0);
        let overlap = a.intersect(&b);
        assert!((overlap.area()).abs() < 1e-5);
    }
}
