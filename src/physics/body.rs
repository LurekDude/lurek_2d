//! Physics body definitions: `Body` struct, `BodyType`, `BodyShape`, and constructors.
//! Bodies are the data-only description sent to `World`; the world owns the actual simulation state.
//! Does not hold rapier handles; translation to rapier types happens in `world.rs`.

use crate::log_msg;
use crate::math::{Rect, Vec2};
use crate::physics::shape::Shape;
use crate::runtime::log_messages::{BD01, BD02, BD03};

/// Simulation role of a physics body.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BodyType {
    /// No movement; collides with dynamic bodies.
    Static,
    /// Mass-based simulation; affected by forces and gravity.
    Dynamic,
    /// Velocity-driven; not affected by forces.
    Kinematic,
    /// Non-colliding overlap detector.
    Sensor,
}
/// Primitive collision shape baked into the body descriptor.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum BodyShape {
    /// Axis-aligned bounding box.
    Rect { width: f32, height: f32 },
    /// Circle of the given radius.
    Circle { radius: f32 },
}
/// Data-only description of a physics body passed to `World` for simulation.
pub struct Body {
    /// World-space position.
    pub position: Vec2,
    /// Linear velocity in world units per second.
    pub velocity: Vec2,
    /// Body mass in kg.
    pub mass: f32,
    /// Simulation role.
    pub body_type: BodyType,
    /// Primary collision primitive.
    pub shape: BodyShape,
    /// Coefficient of restitution (bounciness) in 0.0..=1.0.
    pub restitution: f32,
    /// Bitmask for this body's collision category.
    pub layer: u32,
    /// Bitmask of which categories this body collides with.
    pub mask: u32,
    /// Width of the AABB-equivalent for the chosen shape.
    pub width: f32,
    /// Height of the AABB-equivalent for the chosen shape.
    pub height: f32,
    /// Coefficient of friction in 0.0..=1.0.
    pub friction: f32,
    /// Rotation in radians.
    pub angle: f32,
    /// Angular velocity in radians per second.
    pub angular_velocity: f32,
    /// Extended shape for polygon, edge, and chain bodies.
    pub shape_ext: Option<Shape>,
}
/// Construction and geometric helpers for `Body`.
impl Body {
    /// Create a rectangular body at `(x,y)` with default 32×32 dimensions.
    pub fn new(x: f32, y: f32, body_type: BodyType) -> Self {
        log_msg!(debug, BD01, "({},{})", x, y);
        Body {
            position: Vec2::new(x, y),
            velocity: Vec2::ZERO,
            mass: 1.0,
            body_type,
            shape: BodyShape::Rect {
                width: 32.0,
                height: 32.0,
            },
            restitution: 0.3,
            layer: 1,
            mask: 1,
            width: 32.0,
            height: 32.0,
            friction: 0.5,
            angle: 0.0,
            angular_velocity: 0.0,
            shape_ext: None,
        }
    }
    /// Create a circular body at `(x,y)` with the given `radius`.
    pub fn new_circle(x: f32, y: f32, radius: f32, body_type: BodyType) -> Self {
        log_msg!(debug, BD02, "({},{}) r={}", x, y, radius);
        Body {
            position: Vec2::new(x, y),
            velocity: Vec2::ZERO,
            mass: 1.0,
            body_type,
            shape: BodyShape::Circle { radius },
            restitution: 0.3,
            layer: 1,
            mask: 1,
            width: radius * 2.0,
            height: radius * 2.0,
            friction: 0.5,
            angle: 0.0,
            angular_velocity: 0.0,
            shape_ext: None,
        }
    }
    /// Create a polygon body at `(x,y)` from a vertex list; AABB derived from vertex bounds.
    pub fn new_polygon(x: f32, y: f32, vertices: Vec<Vec2>, body_type: BodyType) -> Self {
        let (mut min_x, mut min_y) = (f32::MAX, f32::MAX);
        let (mut max_x, mut max_y) = (f32::MIN, f32::MIN);
        for v in &vertices {
            min_x = min_x.min(v.x);
            min_y = min_y.min(v.y);
            max_x = max_x.max(v.x);
            max_y = max_y.max(v.y);
        }
        let w = max_x - min_x;
        let h = max_y - min_y;
        log_msg!(debug, BD03, "({},{})", x, y);
        Body {
            position: Vec2::new(x, y),
            velocity: Vec2::ZERO,
            mass: 1.0,
            body_type,
            shape: BodyShape::Rect {
                width: w,
                height: h,
            },
            restitution: 0.3,
            layer: 1,
            mask: 1,
            width: w,
            height: h,
            friction: 0.5,
            angle: 0.0,
            angular_velocity: 0.0,
            shape_ext: Some(Shape::Polygon { vertices }),
        }
    }
    /// Create an edge (line segment) body from `v1` to `v2` anchored at `(x,y)`.
    pub fn new_edge(x: f32, y: f32, v1: Vec2, v2: Vec2, body_type: BodyType) -> Self {
        let w = (v2.x - v1.x).abs().max(1.0);
        let h = (v2.y - v1.y).abs().max(1.0);
        Body {
            position: Vec2::new(x, y),
            velocity: Vec2::ZERO,
            mass: 1.0,
            body_type,
            shape: BodyShape::Rect {
                width: w,
                height: h,
            },
            restitution: 0.3,
            layer: 1,
            mask: 1,
            width: w,
            height: h,
            friction: 0.5,
            angle: 0.0,
            angular_velocity: 0.0,
            shape_ext: Some(Shape::Edge { v1, v2 }),
        }
    }
    /// Create a chain (open or closed polyline) body anchored at `(x,y)`.
    pub fn new_chain(
        x: f32,
        y: f32,
        vertices: Vec<Vec2>,
        closed: bool,
        body_type: BodyType,
    ) -> Self {
        let (mut min_x, mut min_y) = (f32::MAX, f32::MAX);
        let (mut max_x, mut max_y) = (f32::MIN, f32::MIN);
        for v in &vertices {
            min_x = min_x.min(v.x);
            min_y = min_y.min(v.y);
            max_x = max_x.max(v.x);
            max_y = max_y.max(v.y);
        }
        let w = (max_x - min_x).max(1.0);
        let h = (max_y - min_y).max(1.0);
        Body {
            position: Vec2::new(x, y),
            velocity: Vec2::ZERO,
            mass: 1.0,
            body_type,
            shape: BodyShape::Rect {
                width: w,
                height: h,
            },
            restitution: 0.3,
            layer: 1,
            mask: 1,
            width: w,
            height: h,
            friction: 0.5,
            angle: 0.0,
            angular_velocity: 0.0,
            shape_ext: Some(Shape::Chain { vertices, closed }),
        }
    }
    /// Return the axis-aligned bounding box of this body in world space.
    pub fn bounding_box(&self) -> Rect {
        match self.shape {
            BodyShape::Rect { width, height } => Rect::new(
                self.position.x - width / 2.0,
                self.position.y - height / 2.0,
                width,
                height,
            ),
            BodyShape::Circle { radius } => Rect::new(
                self.position.x - radius,
                self.position.y - radius,
                radius * 2.0,
                radius * 2.0,
            ),
        }
    }
    /// Return true when this body's layer and mask are compatible with `other`.
    pub fn collides_with_layer(&self, other: &Body) -> bool {
        (self.layer & other.mask) != 0 && (other.layer & self.mask) != 0
    }
    /// Return the bounding box as `(x, y, width, height)` tuple.
    pub fn get_bounding_box(&self) -> (f32, f32, f32, f32) {
        let r = self.bounding_box();
        (r.x, r.y, r.width, r.height)
    }
    /// Return the body type as a static string slice.
    pub fn get_type(&self) -> &'static str {
        match self.body_type {
            BodyType::Static => "static",
            BodyType::Dynamic => "dynamic",
            BodyType::Kinematic => "kinematic",
            BodyType::Sensor => "sensor",
        }
    }
    /// Convert a local-space offset to world-space position accounting for body rotation.
    pub fn get_world_point(&self, local_x: f32, local_y: f32) -> (f32, f32) {
        let cos_a = self.angle.cos();
        let sin_a = self.angle.sin();
        let wx = self.position.x + local_x * cos_a - local_y * sin_a;
        let wy = self.position.y + local_x * sin_a + local_y * cos_a;
        (wx, wy)
    }
    /// Convert a world-space position to a local-space offset accounting for body rotation.
    pub fn get_local_point(&self, world_x: f32, world_y: f32) -> (f32, f32) {
        let dx = world_x - self.position.x;
        let dy = world_y - self.position.y;
        let cos_a = self.angle.cos();
        let sin_a = self.angle.sin();
        let lx = dx * cos_a + dy * sin_a;
        let ly = -dx * sin_a + dy * cos_a;
        (lx, ly)
    }
}
