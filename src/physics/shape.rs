//! Extended shape types for physics bodies.
//!
//! Provides polygon, edge, and chain shapes beyond the basic rect/circle.
//!
//! This module is part of Luna2D's `physics` subsystem and provides the implementation
//! details for shape-related operations and data management.
//! Key types exported from this module: `Shape`.
//! Primary functions: `to_rapier_collider()`, `regular_polygon()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::math::Vec2;
use rapier2d::prelude::*;

/// Extended collision shape for physics bodies.
///
/// Goes beyond `BodyShape` to support convex polygons, edges, and chains.
///
/// # Variants
/// - `Rect` — Axis-aligned rectangle with width and height.
/// - `Circle` — Circle with a radius.
/// - `Polygon` — Convex polygon (max 8 vertices).
/// - `Edge` — Line segment between two points.
/// - `Chain` — Connected chain of edges, optionally closed.
#[derive(Debug, Clone, PartialEq)]
pub enum Shape {
    /// Axis-aligned rectangle.
    Rect {
        /// Full width.
        width: f32,
        /// Full height.
        height: f32,
    },
    /// Circle shape.
    Circle {
        /// Radius.
        radius: f32,
    },
    /// Convex polygon (max 8 vertices).
    Polygon {
        /// Polygon vertices in counter-clockwise order.
        vertices: Vec<Vec2>,
    },
    /// Line segment between two points.
    Edge {
        /// Start point.
        v1: Vec2,
        /// End point.
        v2: Vec2,
    },
    /// Connected chain of edges.
    Chain {
        /// Chain vertices.
        vertices: Vec<Vec2>,
        /// Whether the chain forms a closed loop.
        closed: bool,
    },
}

impl Shape {
    /// Converts this shape into a rapier2d `ColliderBuilder`.
    ///
    /// Returns `None` if the shape cannot be converted (e.g. degenerate convex hull).
    ///
    /// # Parameters
    /// - `&self` — The shape to convert.
    ///
    /// # Returns
    /// `Some(ColliderBuilder)` on success, `None` for degenerate geometry.
    pub(crate) fn to_rapier_collider(&self) -> Option<ColliderBuilder> {
        match self {
            Shape::Rect { width, height } => {
                Some(ColliderBuilder::cuboid(*width / 2.0, *height / 2.0))
            }
            Shape::Circle { radius } => Some(ColliderBuilder::ball(*radius)),
            Shape::Polygon { vertices } => {
                if vertices.len() < 3 || vertices.len() > 8 {
                    return None;
                }
                let points: Vec<Vector> = vertices.iter().map(|v| Vector::new(v.x, v.y)).collect();
                ColliderBuilder::convex_hull(&points)
            }
            Shape::Edge { v1, v2 } => Some(ColliderBuilder::segment(
                Vector::new(v1.x, v1.y),
                Vector::new(v2.x, v2.y),
            )),
            Shape::Chain { vertices, closed } => {
                if vertices.len() < 2 {
                    return None;
                }
                let mut points: Vec<Vector> =
                    vertices.iter().map(|v| Vector::new(v.x, v.y)).collect();
                if *closed && points.len() >= 3 {
                    points.push(points[0]);
                }
                Some(ColliderBuilder::polyline(points, None))
            }
        }
    }

    /// Creates a regular polygon with the given radius and number of sides.
    ///
    /// Vertices are placed on a circle of the given radius, evenly spaced.
    /// Minimum 3 sides, maximum 8 sides (clamped).
    ///
    /// # Parameters
    /// - `radius` — Circumscribed circle radius.
    /// - `sides` — Number of sides (clamped to 3–8).
    ///
    /// # Returns
    /// A `Shape::Polygon` with the computed vertices.
    pub fn regular_polygon(radius: f32, sides: u32) -> Self {
        let sides = sides.clamp(3, 8);
        let mut vertices = Vec::with_capacity(sides as usize);
        for i in 0..sides {
            let angle = 2.0 * std::f32::consts::PI * (i as f32) / (sides as f32);
            vertices.push(Vec2::new(radius * angle.cos(), radius * angle.sin()));
        }
        Shape::Polygon { vertices }
    }
}
