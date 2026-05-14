//! Physics shape definitions for `Body` and standalone colliders.
//! `Shape` describes the geometry; `StandaloneShape` wraps it with material properties.
//! Translation to rapier2d colliders happens here via `to_rapier_collider`.

use crate::math::Vec2;
use rapier2d::prelude::*;

/// Physics primitive shape used in `Body` and `StandaloneShape`.
#[derive(Debug, Clone, PartialEq)]
pub enum Shape {
    /// Axis-aligned box.
    Rect { width: f32, height: f32 },
    /// Circle.
    Circle { radius: f32 },
    /// Convex polygon (3–8 vertices).
    Polygon { vertices: Vec<Vec2> },
    /// Single line segment.
    Edge { v1: Vec2, v2: Vec2 },
    /// Open or closed polyline.
    Chain { vertices: Vec<Vec2>, closed: bool },
}
/// Conversion helpers for `Shape`.
impl Shape {
    /// Convert this shape to a rapier `ColliderBuilder`; return `None` for degenerate inputs.
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
    /// Parse a shape from a string type tag and flat argument list; `closed` applies to chains.
    pub fn from_parts(shape_type: &str, args: &[f32], closed: bool) -> Result<Self, String> {
        match shape_type {
            "rectangle" => {
                if args.len() < 2 {
                    return Err("rectangle requires w, h".into());
                }
                Ok(Shape::Rect {
                    width: args[0],
                    height: args[1],
                })
            }
            "circle" => {
                if args.is_empty() {
                    return Err("circle requires radius".into());
                }
                Ok(Shape::Circle { radius: args[0] })
            }
            "polygon" => {
                if args.len() < 6 {
                    return Err("polygon requires at least 3 vertex pairs".into());
                }
                let mut verts = Vec::new();
                let mut i = 0;
                while i + 1 < args.len() {
                    verts.push(Vec2::new(args[i], args[i + 1]));
                    i += 2;
                }
                Ok(Shape::Polygon { vertices: verts })
            }
            "edge" => {
                if args.len() < 4 {
                    return Err("edge requires x1,y1,x2,y2".into());
                }
                Ok(Shape::Edge {
                    v1: Vec2::new(args[0], args[1]),
                    v2: Vec2::new(args[2], args[3]),
                })
            }
            "chain" => {
                if args.len() < 4 {
                    return Err("chain requires at least 2 vertex pairs".into());
                }
                let mut verts = Vec::new();
                let mut i = 0;
                while i + 1 < args.len() {
                    verts.push(Vec2::new(args[i], args[i + 1]));
                    i += 2;
                }
                Ok(Shape::Chain {
                    vertices: verts,
                    closed,
                })
            }
            _ => Err(format!(
                "invalid shape type '{}': expected rectangle, circle, polygon, edge, or chain",
                shape_type
            )),
        }
    }
    /// Create a regular convex polygon with `sides` (clamped 3–8) inscribed in `radius`.
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
/// A `Shape` combined with material properties for standalone collision testing.
#[derive(Debug, Clone)]
pub struct StandaloneShape {
    /// Underlying geometry.
    pub shape: Shape,
    /// Mass per area unit.
    pub density: f32,
    /// Friction coefficient 0.0..=1.0.
    pub friction: f32,
    /// Restitution coefficient 0.0..=1.0.
    pub restitution: f32,
    /// When true, this shape detects overlaps without generating forces.
    pub sensor: bool,
}
/// Accessors for `StandaloneShape`.
impl StandaloneShape {
    /// Create a standalone shape with default material values.
    pub fn new(shape: Shape) -> Self {
        StandaloneShape {
            shape,
            density: 1.0,
            friction: 0.5,
            restitution: 0.0,
            sensor: false,
        }
    }
    /// Return a static string label for the shape type.
    pub fn get_type(&self) -> &str {
        match &self.shape {
            Shape::Circle { .. } => "circle",
            Shape::Rect { .. } => "rectangle",
            Shape::Polygon { .. } => "polygon",
            Shape::Edge { .. } => "edge",
            Shape::Chain { .. } => "chain",
        }
    }
    /// Return the circle radius when the inner shape is a `Circle`; otherwise `None`.
    pub fn get_radius(&self) -> Option<f32> {
        if let Shape::Circle { radius } = &self.shape {
            Some(*radius)
        } else {
            None
        }
    }
    /// Return the local-space AABB as `(min_x, min_y, max_x, max_y)`.
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
