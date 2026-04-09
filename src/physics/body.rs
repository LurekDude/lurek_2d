//! Body implementation for the `physics` subsystem.
//!
//! This module is part of Lurek2D's `physics` subsystem and provides the implementation
//! details for body-related operations and data management.
//! Key types exported from this module: `BodyType`, `BodyShape`, `Body`.
//! Primary functions: `new()`, `new_circle()`, `new_polygon()`, `new_edge()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.
//!
use crate::engine::log_messages::{BD01, BD02, BD03};
use crate::log_msg;
use crate::math::{Rect, Vec2};
use crate::physics::shape::Shape;

/// Determines whether a physics body is affected by forces and gravity.
///
/// # Variants
/// - `Static` — Immovable body; does not respond to gravity or impulses. Used for terrain.
/// - `Dynamic` — Movable body; subject to gravity, forces, and velocity integration.
/// - `Sensor` — Trigger volume; detects overlaps but does not resolve collisions.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BodyType {
    Static,
    Dynamic,
    /// User-controlled position; not affected by gravity or forces.
    Kinematic,
    Sensor,
}

/// Describes the collision geometry of a body.
///
/// # Variants
/// - `Rect { width, height }` — Axis-aligned rectangle (AABB). Default shape.
/// - `Circle { radius }` — Circle; uses distance-based collision detection.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum BodyShape {
    /// Axis-aligned rectangle with the given full width and height.
    Rect {
        /// Full width of the rectangle.
        width: f32,
        /// Full height of the rectangle.
        height: f32,
    },
    /// Circle with the given radius.
    Circle {
        /// Radius of the circle.
        radius: f32,
    },
}

/// A rigid body with position, velocity, mass, shape, and restitution.
///
/// Bodies live in a `World` and are identified by their index. Use `World::get_body_mut`
/// to access and modify them each frame.
///
/// # Fields
/// - `position` — World-space centre position.
/// - `velocity` — Linear velocity in world units per second.
/// - `mass` — Mass in kg.
/// - `body_type` — Static, Dynamic, Kinematic, or Sensor.
/// - `shape` — Collision geometry (Rect or Circle).
/// - `restitution` — Bounciness coefficient.
/// - `layer` / `mask` — Collision filter bitmasks.
/// - `friction` — Friction coefficient.
/// - `angle` — Angular orientation in radians.
/// - `angular_velocity` — Spin rate in radians/s.
/// - `shape_ext` — Extended shape override (polygon, edge, chain).
pub struct Body {
    /// World-space centre position.
    pub position: Vec2,
    /// Linear velocity in world units per second.
    pub velocity: Vec2,
    /// Mass in kg; used for impulse resolution.
    pub mass: f32,
    /// Whether the body is `Static`, `Dynamic`, or `Sensor`.
    pub body_type: BodyType,
    /// Collision geometry (`Rect` or `Circle`).
    pub shape: BodyShape,
    /// Bounciness coefficient, `[0.0, 1.0]`.
    pub restitution: f32,
    /// Collision layer bitmask.
    pub layer: u32,
    /// Collision mask bitmask.
    pub mask: u32,
    /// Convenience width field (mirrors Rect shape or circle diameter).
    pub width: f32,
    /// Convenience height field (mirrors Rect shape or circle diameter).
    pub height: f32,
    /// Friction coefficient, `[0.0, 1.0]`.
    pub friction: f32,
    /// Angular orientation in radians.
    pub angle: f32,
    /// Angular velocity in radians per second.
    pub angular_velocity: f32,
    /// Extended shape that overrides `shape` when set.
    /// Used for polygon, edge, and chain shapes.
    pub shape_ext: Option<Shape>,
}

impl Body {
    /// Creates a new rectangular `Body` at position `(x, y)` of the given `body_type`.
    ///
    /// Defaults: velocity = `Vec2::ZERO`, mass = 1.0, size = 32x32, restitution = 0.3, layer/mask = 1.
    ///
    /// # Parameters
    /// - `x` — X position.
    /// - `y` — Y position.
    /// - `body_type` — Static, Dynamic, Kinematic, or Sensor.
    ///
    /// # Returns
    /// A newly-initialised `Body`.
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

    /// Creates a new circular `Body` at position `(x, y)` of the given `body_type`.
    ///
    /// Defaults: velocity = `Vec2::ZERO`, mass = 1.0, restitution = 0.3, layer/mask = 1.
    ///
    /// # Parameters
    /// - `x` — X position.
    /// - `y` — Y position.
    /// - `radius` — Circle radius.
    /// - `body_type` — Static, Dynamic, Kinematic, or Sensor.
    ///
    /// # Returns
    /// A newly-initialised circular `Body`.
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

    /// Creates a new polygon `Body` at position `(x, y)` with the given vertices.
    ///
    /// Vertices define a convex polygon (max 8 vertices). The body's width/height
    /// are computed from the bounding box of the vertices.
    ///
    /// # Parameters
    /// - `x` — X position.
    /// - `y` — Y position.
    /// - `vertices` — Convex polygon vertices.
    /// - `body_type` — Static, Dynamic, Kinematic, or Sensor.
    ///
    /// # Returns
    /// A newly-initialised polygon `Body`.
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

    /// Creates a new edge (line segment) `Body` between two local points.
    ///
    /// The body position `(x, y)` is the world-space origin of the edge.
    ///
    /// # Parameters
    /// - `x` — Origin X position.
    /// - `y` — Origin Y position.
    /// - `v1` — Start vertex.
    /// - `v2` — End vertex.
    /// - `body_type` — Static, Dynamic, Kinematic, or Sensor.
    ///
    /// # Returns
    /// A newly-initialised edge `Body`.
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

    /// Creates a new chain `Body` from a series of connected vertices.
    ///
    /// The body position `(x, y)` is the world-space origin of the chain.
    ///
    /// # Parameters
    /// - `x` — Origin X position.
    /// - `y` — Origin Y position.
    /// - `vertices` — Chain vertices.
    /// - `closed` — Whether the chain forms a closed loop.
    /// - `body_type` — Static, Dynamic, Kinematic, or Sensor.
    ///
    /// # Returns
    /// A newly-initialised chain `Body`.
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

    /// Returns the axis-aligned bounding box for this body centered at `position`.
    ///
    /// For `Circle` shapes, the bounding box encloses the full diameter.
    ///
    /// # Returns
    /// A `Rect` representing the AABB.
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

    /// Returns `true` if this body participates in collision layer filtering with `other`.
    ///
    /// Both bodies must accept each other's layer for collision to occur.
    ///
    /// # Parameters
    /// - `other` — The other body to check against.
    ///
    /// # Returns
    /// `true` if both bodies accept each other's layer.
    pub fn collides_with_layer(&self, other: &Body) -> bool {
        (self.layer & other.mask) != 0 && (other.layer & self.mask) != 0
    }

    /// Returns the AABB of this body as a flat `(x, y, width, height)` tuple.
    ///
    /// Convenience wrapper around `bounding_box()` for ergonomic Lua binding return values.
    ///
    /// # Returns
    /// `(x, y, width, height)` — position and size of the bounding box.
    pub fn get_bounding_box(&self) -> (f32, f32, f32, f32) {
        let r = self.bounding_box();
        (r.x, r.y, r.width, r.height)
    }

    /// Returns the body type as a static string slice.
    ///
    /// Used for Lua binding where the type name must be a plain string.
    ///
    /// # Returns
    /// One of `"static"`, `"dynamic"`, `"kinematic"`, or `"sensor"`.
    pub fn get_type(&self) -> &'static str {
        match self.body_type {
            BodyType::Static => "static",
            BodyType::Dynamic => "dynamic",
            BodyType::Kinematic => "kinematic",
            BodyType::Sensor => "sensor",
        }
    }

    /// Transforms a point from body-local coordinates to world coordinates.
    ///
    /// Applies the body's rotation and then translates by the body's position.
    ///
    /// # Parameters
    /// - `local_x` — `f32`. X coordinate in body-local space.
    /// - `local_y` — `f32`. Y coordinate in body-local space.
    ///
    /// # Returns
    /// `(f32, f32)` — world-space `(x, y)`.
    pub fn get_world_point(&self, local_x: f32, local_y: f32) -> (f32, f32) {
        let cos_a = self.angle.cos();
        let sin_a = self.angle.sin();
        let wx = self.position.x + local_x * cos_a - local_y * sin_a;
        let wy = self.position.y + local_x * sin_a + local_y * cos_a;
        (wx, wy)
    }

    /// Transforms a point from world coordinates to body-local coordinates.
    ///
    /// Translates relative to the body's position, then applies the inverse rotation.
    ///
    /// # Parameters
    /// - `world_x` — `f32`. X coordinate in world space.
    /// - `world_y` — `f32`. Y coordinate in world space.
    ///
    /// # Returns
    /// `(f32, f32)` — body-local `(x, y)`.
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
