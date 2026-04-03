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
}
