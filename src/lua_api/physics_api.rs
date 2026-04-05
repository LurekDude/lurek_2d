//! `luna.physics` Lua API bindings.
//!
//! Auto-generated skeleton from `src/physics/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaBody ────────────────────────────────────────────────────────────

pub struct LuaBody(/* TODO: add key + state fields */);


impl LuaBody {
    /// Returns `true` if this body participates in collision layer filtering with `other`.
    ///
    /// Both bodies must accept each other's layer for collision to occur.
    ///
    ///
    /// # Parameters
    /// - `other` — `The` ...
    ///
    /// # Returns
    /// `true`.
    ///
    /// @param other : The
    /// @return true
    pub fn collides_with_layer(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Transforms a point from body-local coordinates to world coordinates.
    ///
    /// Applies the body's rotation and then translates by the body's position.
    ///
    ///
    /// # Parameters
    /// - `local_x` — `number` ...
    /// - `local_y` — `number` ...
    ///
    /// @param local_x : number
    /// @param local_y : number
    pub fn get_world_point(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Transforms a point from world coordinates to body-local coordinates.
    ///
    /// Translates relative to the body's position, then applies the inverse rotation.
    ///
    ///
    /// # Parameters
    /// - `world_x` — `number` ...
    /// - `world_y` — `number` ...
    ///
    /// @param world_x : number
    /// @param world_y : number
    pub fn get_local_point(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaBody {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("collidesWithLayer", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getWorldPoint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLocalPoint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaStandaloneShape ────────────────────────────────────────────────────────────

pub struct LuaStandaloneShape(/* TODO: add key + state fields */);


impl LuaStandaloneShape {
    /// Returns the shape type name.
    ///
    ///
    /// # Returns
    /// `One`.
    ///
    /// @return One
    pub fn get_type(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the radius for circle shapes.
    ///
    ///
    /// # Returns
    /// `Some(f32)`.
    ///
    /// @return Some(f32)
    pub fn get_radius(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaStandaloneShape {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getType", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRadius", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaWorld ────────────────────────────────────────────────────────────

pub struct LuaWorld(/* TODO: add key + state fields */);


impl LuaWorld {
    /// Returns the number of fixtures on a body (1 = primary only).
    ///
    ///
    /// # Parameters
    /// - `body_id` — `Index` ...
    ///
    /// # Returns
    /// `Fixture`.
    ///
    /// @param body_id : Index
    /// @return Fixture
    pub fn fixture_count(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns an immutable reference to body `id`, or `None` if out of range.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// @param id : Body
    pub fn get_body(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of bodies. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `The`.
    ///
    /// @return The
    pub fn body_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Casts a ray from `(x1, y1)` toward `(x2, y2)` and returns the nearest hit.
    ///
    /// Uses a brute-force O(n) test against all colliders.
    ///
    ///
    /// # Parameters
    /// - `x1` — `Ray` ...
    /// - `y1` — `Ray` ...
    /// - `x2` — `Ray` ...
    /// - `y2` — `Ray` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param x1 : Ray
    /// @param y1 : Ray
    /// @param x2 : Ray
    /// @param y2 : Ray
    /// @return The
    pub fn raycast(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the angular velocity of a body. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `Angular`.
    ///
    /// @param id : Body
    /// @return Angular
    pub fn get_angular_velocity(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the angle (rotation) of a body in radians.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param id : Body
    /// @return The
    pub fn get_body_angle(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the mass of a body. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param id : Body
    /// @return The
    pub fn get_body_mass(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the gravity scale multiplier for a body.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param id : Body
    /// @return The
    pub fn get_gravity_scale(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if the body has rotation locked.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `true`.
    ///
    /// @param id : Body
    /// @return true
    pub fn is_fixed_rotation(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the linear damping coefficient for a body.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param id : Body
    /// @return The
    pub fn get_linear_damping(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the angular damping coefficient for a body.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param id : Body
    /// @return The
    pub fn get_angular_damping(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether CCD is enabled for a body.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `true`.
    ///
    /// @param id : Body
    /// @return true
    pub fn is_bullet(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the body type as a string. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `One`.
    ///
    /// @param id : Body
    /// @return One
    pub fn get_body_type_str(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether sleeping is allowed for a body.
    ///
    ///
    /// # Parameters
    /// - `id` — `Body` ...
    ///
    /// # Returns
    /// `true`.
    ///
    /// @param id : Body
    /// @return true
    pub fn is_sleeping_allowed(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of joints. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `The`.
    ///
    /// @return The
    pub fn joint_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the two body IDs connected by a joint.
    ///
    ///
    /// # Parameters
    /// - `joint_id` — `Joint` ...
    ///
    /// @param joint_id : Joint
    pub fn get_joint_bodies(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns body IDs with colliders intersecting the given AABB.
    ///
    ///
    /// # Parameters
    /// - `x` — `AABB` ...
    /// - `y` — `AABB` ...
    /// - `w` — `AABB` ...
    /// - `h` — `AABB` ...
    ///
    /// @param x : AABB
    /// @param y : AABB
    /// @param w : AABB
    /// @param h : AABB
    pub fn query_aabb(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the first body whose collider contains the given world-space point.
    ///
    /// Uses a point-sized AABB query filter.
    ///
    ///
    /// # Parameters
    /// - `x` — `World-space` ...
    /// - `y` — `World-space` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param x : World-space
    /// @param y : World-space
    /// @return integer?
    pub fn get_body_at_point(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the motor target velocity on the angular axis of a joint.
    ///
    ///
    /// # Parameters
    /// - `joint_id` — `Joint` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param joint_id : Joint
    /// @return The
    pub fn get_joint_motor_speed(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the angular limits `(lower, upper)` on a joint.
    ///
    ///
    /// # Parameters
    /// - `joint_id` — `Joint` ...
    ///
    /// @param joint_id : Joint
    pub fn get_joint_limits(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the type name of a joint. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `joint_id` — `Joint` ...
    ///
    /// # Returns
    /// `One`.
    ///
    /// @param joint_id : Joint
    /// @return One
    pub fn get_joint_type(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the pixels-per-meter scaling factor.
    ///
    ///
    /// # Returns
    /// `The`.
    ///
    /// @return The
    pub fn get_meter(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Converts a pixel value to physics units.
    ///
    ///
    /// # Parameters
    /// - `px` — `Pixel` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param px : Pixel
    /// @return The
    pub fn to_physics(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Converts a physics-unit value to pixels.
    ///
    ///
    /// # Parameters
    /// - `m` — `Physics-unit` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param m : Physics-unit
    /// @return The
    pub fn to_pixels(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns contacts involving a specific body.
    ///
    ///
    /// # Parameters
    /// - `body_id` — `Body` ...
    ///
    /// @param body_id : Body
    pub fn get_body_contacts(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaWorld {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("fixtureCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBody", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("bodyCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("raycast", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAngularVelocity", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBodyAngle", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBodyMass", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getGravityScale", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isFixedRotation", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLinearDamping", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAngularDamping", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isBullet", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBodyTypeStr", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isSleepingAllowed", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("jointCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getJointBodies", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("queryAabb", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBodyAtPoint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getJointMotorSpeed", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getJointLimits", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getJointType", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getMeter", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("toPhysics", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("toPixels", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBodyContacts", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.physics.* functions ──────────────────────────────────────────

/// Creates a new circular `Body` at position `(x, y)` of the given `body_type`.
///
/// Defaults: velocity = `Vec2::ZERO`, mass = 1.0, restitution = 0.3, layer/mask = 1.
///
///
/// # Parameters
/// - `x` — `X` ...
/// - `y` — `Y` ...
/// - `radius` — `Circle` ...
/// - `body_type` — `Static,` ...
///
/// @param x : X
/// @param y : Y
/// @param radius : Circle
/// @param body_type : Static,
pub fn new_circle(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a new polygon `Body` at position `(x, y)` with the given vertices.
///
/// Vertices define a convex polygon (max 8 vertices). The body's width/height
/// are computed from the bounding box of the vertices.
///
///
/// # Parameters
/// - `x` — `X` ...
/// - `y` — `Y` ...
/// - `vertices` — `Convex` ...
/// - `body_type` — `Static,` ...
///
/// @param x : X
/// @param y : Y
/// @param vertices : Convex
/// @param body_type : Static,
pub fn new_polygon(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a new edge (line segment) `Body` between two local points.
///
/// The body position `(x, y)` is the world-space origin of the edge.
///
///
/// # Parameters
/// - `x` — `Origin` ...
/// - `y` — `Origin` ...
/// - `v1` — `Start` ...
/// - `v2` — `End` ...
/// - `body_type` — `Static,` ...
///
/// @param x : Origin
/// @param y : Origin
/// @param v1 : Start
/// @param v2 : End
/// @param body_type : Static,
pub fn new_edge(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a new chain `Body` from a series of connected vertices.
///
/// The body position `(x, y)` is the world-space origin of the chain.
///
///
/// # Parameters
/// - `x` — `Origin` ...
/// - `y` — `Origin` ...
/// - `vertices` — `Chain` ...
/// - `closed` — `Whether` ...
/// - `body_type` — `Static,` ...
///
/// @param x : Origin
/// @param y : Origin
/// @param vertices : Chain
/// @param closed : Whether
/// @param body_type : Static,
pub fn new_chain(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a regular polygon with the given radius and number of sides.
///
/// Vertices are placed on a circle of the given radius, evenly spaced.
/// Minimum 3 sides, maximum 8 sides (clamped).
///
///
/// # Parameters
/// - `radius` — `Circumscribed` ...
/// - `sides` — `Number` ...
///
/// @param radius : Circumscribed
/// @param sides : Number
pub fn regular_polygon(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a `body` to the world and returns its stable integer id.
///
///
/// # Parameters
/// - `body` — `The` ...
///
/// # Returns
/// `The`.
///
/// @param body : The
/// @return The
pub fn add_body(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds an extra fixture (collider) to an existing body.
///
/// Returns the fixture index (0 = primary, 1+ = extra fixtures).
///
///
/// # Parameters
/// - `body_id` — `Index` ...
/// - `shape` — `Collision` ...
/// - `density` — `Mass` ...
/// - `friction` — `Surface` ...
/// - `restitution` — `Bounciness` ...
/// - `sensor` — `Whether` ...
///
/// # Returns
/// `The`.
///
/// @param body_id : Index
/// @param shape : Collision
/// @param density : Mass
/// @param friction : Surface
/// @param restitution : Bounciness
/// @param sensor : Whether
/// @return The
pub fn add_fixture(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the friction of a fixture by index.
///
/// Index 0 = primary fixture, 1+ = extra fixtures.
///
///
/// # Parameters
/// - `body_id` — `Index` ...
/// - `fixture_idx` — `Fixture` ...
/// - `friction` — `New` ...
///
/// @param body_id : Index
/// @param fixture_idx : Fixture
/// @param friction : New
pub fn set_fixture_friction(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the restitution of a fixture by index.
///
///
/// # Parameters
/// - `body_id` — `Index` ...
/// - `fixture_idx` — `Fixture` ...
/// - `restitution` — `New` ...
///
/// @param body_id : Index
/// @param fixture_idx : Fixture
/// @param restitution : New
pub fn set_fixture_restitution(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets whether a fixture is a sensor. Replaces the current fixture sensor value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `body_id` — `Index` ...
/// - `fixture_idx` — `Fixture` ...
/// - `sensor` — `Whether` ...
///
/// @param body_id : Index
/// @param fixture_idx : Fixture
/// @param sensor : Whether
pub fn set_fixture_sensor(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns a mutable reference to body `id`, or `None` if out of range.
///
/// Shape, restitution, layer, mask, velocity, and position mutations are
/// flushed into the rapier simulation on the next `step()` call.
///
///
/// # Parameters
/// - `id` — `Body` ...
///
/// @param id : Body
pub fn get_body_mut(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a revolute (pin) joint between two bodies at a local anchor on body_a.
///
/// Returns a stable joint id.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `anchor_x` — `Local` ...
/// - `anchor_y` — `Local` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param anchor_x : Local
/// @param anchor_y : Local
/// @return The
pub fn add_revolute_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advances the simulation by `dt` seconds.
///
/// 1. Rebuild rapier colliders for bodies with changed shape/properties.
/// 2. Push all body positions/velocities into rapier.
/// 3. Step the rapier pipeline.
/// 4. Read back positions/velocities for Dynamic bodies.
/// 5. Record collision events.
///
///
/// # Parameters
/// - `dt` — `Time` ...
///
/// @param dt : Time
pub fn step(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies a linear impulse directly to a body in the rapier simulation.
///
/// Has no effect on static or sensor bodies.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `ix` — `Impulse` ...
/// - `iy` — `Impulse` ...
///
/// @param id : Body
/// @param ix : Impulse
/// @param iy : Impulse
pub fn apply_impulse(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Teleports a body to a new position. Replaces the current body position value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `x` — `New` ...
/// - `y` — `New` ...
///
/// @param id : Body
/// @param x : New
/// @param y : New
pub fn set_body_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies a continuous force to a body (accumulated over the next step).
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `fx` — `Force` ...
/// - `fy` — `Force` ...
///
/// @param id : Body
/// @param fx : Force
/// @param fy : Force
pub fn apply_force(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies a torque (rotational force) to a body.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `torque` — `Torque` ...
///
/// @param id : Body
/// @param torque : Torque
pub fn apply_torque(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the angular velocity (spin rate) of a body.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `omega` — `Angular` ...
///
/// @param id : Body
/// @param omega : Angular
pub fn set_angular_velocity(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the angle (rotation) of a body in radians.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `angle` — `New` ...
///
/// @param id : Body
/// @param angle : New
pub fn set_body_angle(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the mass of a body. Replaces the current body mass value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `mass` — `New` ...
///
/// @param id : Body
/// @param mass : New
pub fn set_body_mass(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the per-body gravity multiplier. Replaces the current gravity scale value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `scale` — `Gravity` ...
///
/// @param id : Body
/// @param scale : Gravity
pub fn set_gravity_scale(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Locks or unlocks rotation for a body. Replaces the current fixed rotation value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `fixed` — `true` ...
///
/// @param id : Body
/// @param fixed : true
pub fn set_fixed_rotation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets linear damping (air resistance) for a body.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `damping` — `Damping` ...
///
/// @param id : Body
/// @param damping : Damping
pub fn set_linear_damping(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets angular damping (rotational resistance) for a body.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `damping` — `Damping` ...
///
/// @param id : Body
/// @param damping : Damping
pub fn set_angular_damping(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Enables or disables continuous collision detection (CCD) for a body.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `bullet` — `true` ...
///
/// @param id : Body
/// @param bullet : true
pub fn set_bullet(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies a force at a specific world-space point on a body.
///
/// A force applied off-centre generates torque in addition to linear acceleration.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `fx` — `Force` ...
/// - `fy` — `Force` ...
/// - `px` — `Application` ...
/// - `py` — `Application` ...
///
/// @param id : Body
/// @param fx : Force
/// @param fy : Force
/// @param px : Application
/// @param py : Application
pub fn apply_force_at_point(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies an angular (rotational) impulse to a body.
///
/// Mirrors the resulting angular velocity into the body cache so that
/// the next `step()` sync does not discard it.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `impulse` — `Angular` ...
///
/// @param id : Body
/// @param impulse : Angular
pub fn apply_angular_impulse(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Changes the body type of an existing body.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `bt` — `New` ...
///
/// @param id : Body
/// @param bt : New
pub fn set_body_type(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the gravity vector. Replaces the current gravity value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `gx` — `Horizontal` ...
/// - `gy` — `Vertical` ...
///
/// @param gx : Horizontal
/// @param gy : Vertical
pub fn set_gravity(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets whether sleeping is allowed for a body.
///
/// When sleeping is allowed, the physics engine can deactivate stationary
/// bodies to save CPU. When disabled, the body stays awake indefinitely.
///
///
/// # Parameters
/// - `id` — `Body` ...
/// - `allowed` — `true` ...
///
/// @param id : Body
/// @param allowed : true
pub fn set_sleeping_allowed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a body from the world by disabling it in rapier.
///
/// The body slot is kept to preserve stable IDs. The body is set to Static
/// and its rapier rigid body is disabled.
///
///
/// # Parameters
/// - `id` — `Body` ...
///
/// @param id : Body
pub fn destroy_body(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a distance joint that tries to maintain a fixed distance between two bodies.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `ax1` — `Local` ...
/// - `ay1` — `Local` ...
/// - `ax2` — `Local` ...
/// - `ay2` — `Local` ...
/// - `length` — `Rest` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param ax1 : Local
/// @param ay1 : Local
/// @param ax2 : Local
/// @param ay2 : Local
/// @param length : Rest
/// @return The
pub fn add_distance_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a prismatic (slider) joint allowing motion along one axis.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `anchor_x` — `Local` ...
/// - `anchor_y` — `Local` ...
/// - `axis_x` — `Slide` ...
/// - `axis_y` — `Slide` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param anchor_x : Local
/// @param anchor_y : Local
/// @param axis_x : Slide
/// @param axis_y : Slide
/// @return The
pub fn add_prismatic_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a weld (rigid) joint that locks two bodies together.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `anchor_x` — `Local` ...
/// - `anchor_y` — `Local` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param anchor_x : Local
/// @param anchor_y : Local
/// @return The
pub fn add_weld_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a rope joint with a maximum distance constraint.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `ax1` — `Local` ...
/// - `ay1` — `Local` ...
/// - `ax2` — `Local` ...
/// - `ay2` — `Local` ...
/// - `max_length` — `Maximum` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param ax1 : Local
/// @param ay1 : Local
/// @param ax2 : Local
/// @param ay2 : Local
/// @param max_length : Maximum
/// @return The
pub fn add_rope_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a joint from the world. After this call the associated key is invalid and must not be reused.
///
///
/// # Parameters
/// - `joint_id` — `Joint` ...
///
/// @param joint_id : Joint
pub fn destroy_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Casts a ray and returns the closest hit using the query pipeline.
///
///
/// # Parameters
/// - `x1` — `Ray` ...
/// - `y1` — `Ray` ...
/// - `dx` — `Ray` ...
/// - `dy` — `Ray` ...
/// - `max_dist` — `Maximum` ...
///
/// # Returns
/// `The`.
///
/// @param x1 : Ray
/// @param y1 : Ray
/// @param dx : Ray
/// @param dy : Ray
/// @param max_dist : Maximum
/// @return The
pub fn raycast_closest(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Casts a ray and returns all hits along it.
///
///
/// # Parameters
/// - `x1` — `Ray` ...
/// - `y1` — `Ray` ...
/// - `dx` — `Ray` ...
/// - `dy` — `Ray` ...
/// - `max_dist` — `Maximum` ...
///
/// @param x1 : Ray
/// @param y1 : Ray
/// @param dx : Ray
/// @param dy : Ray
/// @param max_dist : Maximum
pub fn raycast_all(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a wheel joint (prismatic + rotation) between two bodies.
///
/// Allows translation along the given axis and free rotation.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `anchor_x` — `Local` ...
/// - `anchor_y` — `Local` ...
/// - `axis_x` — `Slide` ...
/// - `axis_y` — `Slide` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param anchor_x : Local
/// @param anchor_y : Local
/// @param axis_x : Slide
/// @param axis_y : Slide
/// @return The
pub fn add_wheel_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a friction joint that resists relative motion between two bodies.
///
/// Uses a fixed joint with velocity motors tuned to the given force/torque limits.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `anchor_x` — `Local` ...
/// - `anchor_y` — `Local` ...
/// - `max_force` — `Maximum` ...
/// - `max_torque` — `Maximum` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param anchor_x : Local
/// @param anchor_y : Local
/// @param max_force : Maximum
/// @param max_torque : Maximum
/// @return The
pub fn add_friction_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a motor joint that drives body_b toward body_a's frame.
///
/// The correction factor controls how aggressively the motor corrects position.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `correction_factor` — `Motor` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param correction_factor : Motor
/// @return The
pub fn add_motor_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a mouse joint that connects a body to a target point via a spring.
///
/// Internally creates a kinematic anchor body at the target position
/// and a spring joint between the body and the anchor.
///
///
/// # Parameters
/// - `body_id` — `Index` ...
/// - `target_x` — `Initial` ...
/// - `target_y` — `Initial` ...
/// - `max_force` — `Maximum` ...
///
/// # Returns
/// `The`.
///
/// @param body_id : Index
/// @param target_x : Initial
/// @param target_y : Initial
/// @param max_force : Maximum
/// @return The
pub fn add_mouse_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Updates the target position of a mouse joint.
///
///
/// # Parameters
/// - `joint_id` — `Joint` ...
/// - `x` — `New` ...
/// - `y` — `New` ...
///
/// @param joint_id : Joint
/// @param x : New
/// @param y : New
pub fn set_mouse_joint_target(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Stub: pulley joint is not supported by rapier2d. Returns a fixed joint fallback.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `anchor_x` — `Local` ...
/// - `anchor_y` — `Local` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param anchor_x : Local
/// @param anchor_y : Local
/// @return The
pub fn add_pulley_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Stub: gear joint is not supported by rapier2d. Returns a fixed joint fallback.
///
///
/// # Parameters
/// - `body_a` — `Index` ...
/// - `body_b` — `Index` ...
/// - `anchor_x` — `Local` ...
/// - `anchor_y` — `Local` ...
///
/// # Returns
/// `The`.
///
/// @param body_a : Index
/// @param body_b : Index
/// @param anchor_x : Local
/// @param anchor_y : Local
/// @return The
pub fn add_gear_joint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the motor speed on the angular axis of a joint.
///
///
/// # Parameters
/// - `joint_id` — `Joint` ...
/// - `speed` — `Target` ...
///
/// @param joint_id : Joint
/// @param speed : Target
pub fn set_joint_motor_speed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Enables or disables limits on the angular axis of a joint.
///
///
/// # Parameters
/// - `joint_id` — `Joint` ...
/// - `enabled` — `true` ...
///
/// @param joint_id : Joint
/// @param enabled : true
pub fn set_joint_limits_enabled(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the angular limits (lower, upper) on a joint in radians.
///
///
/// # Parameters
/// - `joint_id` — `Joint` ...
/// - `lower` — `Lower` ...
/// - `upper` — `Upper` ...
///
/// @param joint_id : Joint
/// @param lower : Lower
/// @param upper : Upper
pub fn set_joint_limits(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the pixels-per-meter scaling factor.
///
///
/// # Parameters
/// - `ppm` — `Pixels` ...
///
/// @param ppm : Pixels
pub fn set_meter(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.physics` API table.
///
/// # Parameters
/// - `lua` — `&Lua` The Lua VM.
/// - `luna` — `&LuaTable<'_>` The top-level `luna` table.
/// - `state` — `Rc<RefCell<SharedState>>` Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("newCircle", lua.create_function(new_circle)?)?;
    tbl.set("newPolygon", lua.create_function(new_polygon)?)?;
    tbl.set("newEdge", lua.create_function(new_edge)?)?;
    tbl.set("newChain", lua.create_function(new_chain)?)?;
    tbl.set("regularPolygon", lua.create_function(regular_polygon)?)?;
    tbl.set("addBody", lua.create_function(add_body)?)?;
    tbl.set("addFixture", lua.create_function(add_fixture)?)?;
    tbl.set("setFixtureFriction", lua.create_function(set_fixture_friction)?)?;
    tbl.set("setFixtureRestitution", lua.create_function(set_fixture_restitution)?)?;
    tbl.set("setFixtureSensor", lua.create_function(set_fixture_sensor)?)?;
    tbl.set("getBodyMut", lua.create_function(get_body_mut)?)?;
    tbl.set("addRevoluteJoint", lua.create_function(add_revolute_joint)?)?;
    tbl.set("step", lua.create_function(step)?)?;
    tbl.set("applyImpulse", lua.create_function(apply_impulse)?)?;
    tbl.set("setBodyPosition", lua.create_function(set_body_position)?)?;
    tbl.set("applyForce", lua.create_function(apply_force)?)?;
    tbl.set("applyTorque", lua.create_function(apply_torque)?)?;
    tbl.set("setAngularVelocity", lua.create_function(set_angular_velocity)?)?;
    tbl.set("setBodyAngle", lua.create_function(set_body_angle)?)?;
    tbl.set("setBodyMass", lua.create_function(set_body_mass)?)?;
    tbl.set("setGravityScale", lua.create_function(set_gravity_scale)?)?;
    tbl.set("setFixedRotation", lua.create_function(set_fixed_rotation)?)?;
    tbl.set("setLinearDamping", lua.create_function(set_linear_damping)?)?;
    tbl.set("setAngularDamping", lua.create_function(set_angular_damping)?)?;
    tbl.set("setBullet", lua.create_function(set_bullet)?)?;
    tbl.set("applyForceAtPoint", lua.create_function(apply_force_at_point)?)?;
    tbl.set("applyAngularImpulse", lua.create_function(apply_angular_impulse)?)?;
    tbl.set("setBodyType", lua.create_function(set_body_type)?)?;
    tbl.set("setGravity", lua.create_function(set_gravity)?)?;
    tbl.set("setSleepingAllowed", lua.create_function(set_sleeping_allowed)?)?;
    tbl.set("destroyBody", lua.create_function(destroy_body)?)?;
    tbl.set("addDistanceJoint", lua.create_function(add_distance_joint)?)?;
    tbl.set("addPrismaticJoint", lua.create_function(add_prismatic_joint)?)?;
    tbl.set("addWeldJoint", lua.create_function(add_weld_joint)?)?;
    tbl.set("addRopeJoint", lua.create_function(add_rope_joint)?)?;
    tbl.set("destroyJoint", lua.create_function(destroy_joint)?)?;
    tbl.set("raycastClosest", lua.create_function(raycast_closest)?)?;
    tbl.set("raycastAll", lua.create_function(raycast_all)?)?;
    tbl.set("addWheelJoint", lua.create_function(add_wheel_joint)?)?;
    tbl.set("addFrictionJoint", lua.create_function(add_friction_joint)?)?;
    tbl.set("addMotorJoint", lua.create_function(add_motor_joint)?)?;
    tbl.set("addMouseJoint", lua.create_function(add_mouse_joint)?)?;
    tbl.set("setMouseJointTarget", lua.create_function(set_mouse_joint_target)?)?;
    tbl.set("addPulleyJoint", lua.create_function(add_pulley_joint)?)?;
    tbl.set("addGearJoint", lua.create_function(add_gear_joint)?)?;
    tbl.set("setJointMotorSpeed", lua.create_function(set_joint_motor_speed)?)?;
    tbl.set("setJointLimitsEnabled", lua.create_function(set_joint_limits_enabled)?)?;
    tbl.set("setJointLimits", lua.create_function(set_joint_limits)?)?;
    tbl.set("setMeter", lua.create_function(set_meter)?)?;
    luna.set("physics", tbl)?;
    Ok(())
}
