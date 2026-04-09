//! Extended shape types for physics bodies.
//!
//! Provides polygon, edge, and chain shapes beyond the basic rect/circle.
//!
//! This module is part of Lurek2D's `physics` subsystem and provides the implementation
//! details for shape-related operations and data management.
//! Key types exported from this module: `Shape`.
//! Primary functions: `to_rapier_collider()`, `regular_polygon()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

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

    /// Creates a `Shape` from a type string and flat float argument list.
    ///
    /// For `polygon` and `chain`, `args` contains interleaved x/y vertex pairs.
    /// For `chain`, `closed` controls whether the chain forms a loop.
    ///
    /// # Parameters
    /// - `shape_type` — One of `rectangle`, `circle`, `polygon`, `edge`, `chain`.
    /// - `args` — Flat f32 arg list extracted from Lua multivalue.
    /// - `closed` — Only used for `chain`; ignored for other types.
    ///
    /// # Returns
    /// `Ok(Shape)` on success, `Err(String)` for invalid types or insufficient args.
    pub fn from_parts(shape_type: &str, args: &[f32], closed: bool) -> Result<Self, String> {
        match shape_type {
            "rectangle" => {
                if args.len() < 2 { return Err("rectangle requires w, h".into()); }
                Ok(Shape::Rect { width: args[0], height: args[1] })
            }
            "circle" => {
                if args.is_empty() { return Err("circle requires radius".into()); }
                Ok(Shape::Circle { radius: args[0] })
            }
            "polygon" => {
                if args.len() < 6 { return Err("polygon requires at least 3 vertex pairs".into()); }
                let mut verts = Vec::new();
                let mut i = 0;
                while i + 1 < args.len() { verts.push(Vec2::new(args[i], args[i + 1])); i += 2; }
                Ok(Shape::Polygon { vertices: verts })
            }
            "edge" => {
                if args.len() < 4 { return Err("edge requires x1,y1,x2,y2".into()); }
                Ok(Shape::Edge { v1: Vec2::new(args[0], args[1]), v2: Vec2::new(args[2], args[3]) })
            }
            "chain" => {
                if args.len() < 4 { return Err("chain requires at least 2 vertex pairs".into()); }
                let mut verts = Vec::new();
                let mut i = 0;
                while i + 1 < args.len() { verts.push(Vec2::new(args[i], args[i + 1])); i += 2; }
                Ok(Shape::Chain { vertices: verts, closed })
            }
            _ => Err(format!(
                "invalid shape type '{}': expected rectangle, circle, polygon, edge, or chain",
                shape_type
            )),
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

/// A standalone shape value holding geometry and default fixture parameters.
///
/// Created via `lurek.physics.newCircleShape` et al. and attached to bodies
/// with `lurek.physics.attachShape`. Can be reused across multiple bodies.
///
/// # Fields
/// - `shape` — `Shape`. The underlying collision geometry.
/// - `density` — `f32`. Mass density (default 1.0).
/// - `friction` — `f32`. Surface friction coefficient (default 0.5).
/// - `restitution` — `f32`. Bounciness: 0 = inelastic, 1 = fully elastic (default 0.0).
/// - `sensor` — `bool`. If true, the shape detects overlaps without physical response.
#[derive(Debug, Clone)]
pub struct StandaloneShape {
    /// The underlying collision geometry.
    pub shape: Shape,
    /// Mass density (default 1.0).
    pub density: f32,
    /// Surface friction coefficient (default 0.5).
    pub friction: f32,
    /// Bounciness: 0 = inelastic, 1 = fully elastic (default 0.0).
    pub restitution: f32,
    /// If true, the shape detects overlaps but produces no physical forces.
    pub sensor: bool,
}

impl StandaloneShape {
    /// Creates a new `StandaloneShape` with default fixture parameters.
    ///
    /// # Parameters
    /// - `shape` — `Shape`. The collision geometry.
    ///
    /// # Returns
    /// `StandaloneShape` with density=1.0, friction=0.5, restitution=0.0, sensor=false.
    pub fn new(shape: Shape) -> Self {
        StandaloneShape {
            shape,
            density: 1.0,
            friction: 0.5,
            restitution: 0.0,
            sensor: false,
        }
    }

    /// Returns the shape type name.
    ///
    /// # Returns
    /// One of `"circle"`, `"rectangle"`, `"polygon"`, `"edge"`, `"chain"`.
    pub fn get_type(&self) -> &str {
        match &self.shape {
            Shape::Circle { .. } => "circle",
            Shape::Rect { .. } => "rectangle",
            Shape::Polygon { .. } => "polygon",
            Shape::Edge { .. } => "edge",
            Shape::Chain { .. } => "chain",
        }
    }

    /// Returns the radius for circle shapes.
    ///
    /// # Returns
    /// `Some(f32)` for `Shape::Circle`; `None` for all other variants.
    pub fn get_radius(&self) -> Option<f32> {
        if let Shape::Circle { radius } = &self.shape {
            Some(*radius)
        } else {
            None
        }
    }

    /// Returns an axis-aligned bounding box for this shape as `(min_x, min_y, max_x, max_y)`.
    ///
    /// All coordinates are shape-local (centred at origin).
    ///
    /// # Returns
    /// `(f32, f32, f32, f32)` — min_x, min_y, max_x, max_y.
    pub fn get_bounding_box(&self) -> (f32, f32, f32, f32) {
        match &self.shape {
            Shape::Circle { radius } => (-radius, -radius, *radius, *radius),
            Shape::Rect { width, height } => {
                let hw = width / 2.0;
                let hh = height / 2.0;
                (-hw, -hh, hw, hh)
            }
            Shape::Polygon { vertices } => {
                let (mut min_x, mut min_y) = (f32::MAX, f32::MAX);
                let (mut max_x, mut max_y) = (f32::MIN, f32::MIN);
                for v in vertices {
                    min_x = min_x.min(v.x);
                    min_y = min_y.min(v.y);
                    max_x = max_x.max(v.x);
                    max_y = max_y.max(v.y);
                }
                (min_x, min_y, max_x, max_y)
            }
            Shape::Edge { v1, v2 } => (
                v1.x.min(v2.x),
                v1.y.min(v2.y),
                v1.x.max(v2.x),
                v1.y.max(v2.y),
            ),
            Shape::Chain { vertices, .. } => {
                let (mut min_x, mut min_y) = (f32::MAX, f32::MAX);
                let (mut max_x, mut max_y) = (f32::MIN, f32::MIN);
                for v in vertices {
                    min_x = min_x.min(v.x);
                    min_y = min_y.min(v.y);
                    max_x = max_x.max(v.x);
                    max_y = max_y.max(v.y);
                }
                (min_x, min_y, max_x, max_y)
            }
        }
    }
}
