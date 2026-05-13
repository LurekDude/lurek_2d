use crate::log_msg;
use crate::math::{Rect, Vec2};
use crate::physics::shape::Shape;
use crate::runtime::log_messages::{BD01, BD02, BD03};
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BodyType {
    Static,
    Dynamic,
    Kinematic,
    Sensor,
}
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum BodyShape {
    Rect { width: f32, height: f32 },
    Circle { radius: f32 },
}
pub struct Body {
    pub position: Vec2,
    pub velocity: Vec2,
    pub mass: f32,
    pub body_type: BodyType,
    pub shape: BodyShape,
    pub restitution: f32,
    pub layer: u32,
    pub mask: u32,
    pub width: f32,
    pub height: f32,
    pub friction: f32,
    pub angle: f32,
    pub angular_velocity: f32,
    pub shape_ext: Option<Shape>,
}
impl Body {
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
    pub fn collides_with_layer(&self, other: &Body) -> bool {
        (self.layer & other.mask) != 0 && (other.layer & self.mask) != 0
    }
    pub fn get_bounding_box(&self) -> (f32, f32, f32, f32) {
        let r = self.bounding_box();
        (r.x, r.y, r.width, r.height)
    }
    pub fn get_type(&self) -> &'static str {
        match self.body_type {
            BodyType::Static => "static",
            BodyType::Dynamic => "dynamic",
            BodyType::Kinematic => "kinematic",
            BodyType::Sensor => "sensor",
        }
    }
    pub fn get_world_point(&self, local_x: f32, local_y: f32) -> (f32, f32) {
        let cos_a = self.angle.cos();
        let sin_a = self.angle.sin();
        let wx = self.position.x + local_x * cos_a - local_y * sin_a;
        let wy = self.position.y + local_x * sin_a + local_y * cos_a;
        (wx, wy)
    }
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
