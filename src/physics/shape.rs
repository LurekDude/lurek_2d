use crate::math::Vec2;
use rapier2d::prelude::*;
#[derive(Debug, Clone, PartialEq)]
pub enum Shape {
    Rect { width: f32, height: f32 },
    Circle { radius: f32 },
    Polygon { vertices: Vec<Vec2> },
    Edge { v1: Vec2, v2: Vec2 },
    Chain { vertices: Vec<Vec2>, closed: bool },
}
impl Shape {
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
#[derive(Debug, Clone)]
pub struct StandaloneShape {
    pub shape: Shape,
    pub density: f32,
    pub friction: f32,
    pub restitution: f32,
    pub sensor: bool,
}
impl StandaloneShape {
    pub fn new(shape: Shape) -> Self {
        StandaloneShape {
            shape,
            density: 1.0,
            friction: 0.5,
            restitution: 0.0,
            sensor: false,
        }
    }
    pub fn get_type(&self) -> &str {
        match &self.shape {
            Shape::Circle { .. } => "circle",
            Shape::Rect { .. } => "rectangle",
            Shape::Polygon { .. } => "polygon",
            Shape::Edge { .. } => "edge",
            Shape::Chain { .. } => "chain",
        }
    }
    pub fn get_radius(&self) -> Option<f32> {
        if let Shape::Circle { radius } = &self.shape {
            Some(*radius)
        } else {
            None
        }
    }
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
