//! Extended physics API registrations (second half of `register`).

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::Vec2;
use crate::physics::{Body, Shape, World};

#[allow(unused_imports)]
use super::helpers::*;

pub(super) fn register_ext(
    lua: &Lua,
    physics: &LuaTable,
    worlds: &Rc<RefCell<Vec<World>>>,
) -> LuaResult<()> {
    // ÔöÇÔöÇ Phase 07 Part 2: Extended body constructors ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.newPolygonBody(world_id, x, y, vertices, body_type) -> body_id
    // vertices = {x1, y1, x2, y2, ...} flat table
    /// Creates a convex polygon body defined by a list of local-space vertices.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `type` ÔÇö Body type: 'static', 'dynamic', or 'kinematic'.
    /// - `x` ÔÇö World X position for the body's origin.
    /// - `y` ÔÇö World Y position for the body's origin.
    /// - `vertices` ÔÇö Flat or nested table of (x, y) polygon vertices in local space.
    ///
    /// # Returns
    /// New body ID.
    let w = worlds.clone();
    physics.set(
        "newPolygonBody",
        lua.create_function(
            move |_, (world_id_val, x, y, verts, bt): (LuaValue, f32, f32, LuaTable, String)| {
                let mut vertices = Vec::new();
                let len = verts.raw_len();
                let mut i = 1;
                while i < len {
                    let vx: f32 = verts.get(i)?;
                    let vy: f32 = verts.get(i + 1)?;
                    vertices.push(Vec2::new(vx, vy));
                    i += 2;
                }
                let body = Body::new_polygon(x, y, vertices, parse_body_type(&bt));
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let id = world.add_body(body);
                    return Ok(LuaBody {
                        worlds: w.clone(),
                        world_index: world_id,
                        body_index: id,
                    });
                }
                Ok(LuaBody {
                    worlds: w.clone(),
                    world_index: world_id,
                    body_index: 0,
                })
            },
        )?,
    )?;

    // luna.physics.newEdgeBody(world_id, x, y, x1, y1, x2, y2, body_type) -> body_id
    /// Creates a single-segment edge body connecting two points in world space.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `x1`, `y1` ÔÇö Start point in world units.
    /// - `x2`, `y2` ÔÇö End point in world units.
    ///
    /// # Returns
    /// New body ID.
    let w = worlds.clone();
    physics.set(
        "newEdgeBody",
        lua.create_function(
            move |_,
                  (world_id_val, x, y, x1, y1, x2, y2, bt): (
                LuaValue,
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
                String,
            )| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body = Body::new_edge(
                    x,
                    y,
                    Vec2::new(x1, y1),
                    Vec2::new(x2, y2),
                    parse_body_type(&bt),
                );
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let id = world.add_body(body);
                    return Ok(LuaBody {
                        worlds: w.clone(),
                        world_index: world_id,
                        body_index: id,
                    });
                }
                Ok(LuaBody {
                    worlds: w.clone(),
                    world_index: world_id,
                    body_index: 0,
                })
            },
        )?,
    )?;

    // luna.physics.newChainBody(world_id, x, y, vertices, closed, body_type) -> body_id
    /// Creates a static chain body from a list of connected edge segments.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `vertices` ÔÇö Flat or nested table of (x, y) chain vertices.
    /// - `closed` ÔÇö Optional boolean; true to close the chain into a loop.
    ///
    /// # Returns
    /// New body ID.
    let w = worlds.clone();
    physics.set(
        "newChainBody",
        lua.create_function(
            move |_,
                  (world_id_val, x, y, verts, closed, bt): (
                LuaValue,
                f32,
                f32,
                LuaTable,
                bool,
                String,
            )| {
                let mut vertices = Vec::new();
                let len = verts.raw_len();
                let mut i = 1;
                while i < len {
                    let vx: f32 = verts.get(i)?;
                    let vy: f32 = verts.get(i + 1)?;
                    vertices.push(Vec2::new(vx, vy));
                    i += 2;
                }
                let world_id = world_index_from_value(&world_id_val)?;
                let body = Body::new_chain(x, y, vertices, closed, parse_body_type(&bt));
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let id = world.add_body(body);
                    return Ok(LuaBody {
                        worlds: w.clone(),
                        world_index: world_id,
                        body_index: id,
                    });
                }
                Ok(LuaBody {
                    worlds: w.clone(),
                    world_index: world_id,
                    body_index: 0,
                })
            },
        )?,
    )?;

    // ÔöÇÔöÇ Phase 07 Part 2: Additional joint types ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.addWheelJoint(world_id, bodyA, bodyB, ax, ay, axisX, axisY) -> joint_id
    /// Adds a wheel joint combining a revolute motor and a prismatic spring for vehicle suspension.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body1` ÔÇö Chassis body ID.
    /// - `body2` ÔÇö Wheel body ID.
    /// - `ax`, `ay` ÔÇö World-space anchor point.
    /// - `axisX`, `axisY` ÔÇö Suspension axis direction.
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addWheelJoint",
        lua.create_function(
            move |_,
                  (world_id_val, body_a, body_b, ax, ay, axis_x, axis_y): (
                LuaValue,
                usize,
                usize,
                f32,
                f32,
                f32,
                f32,
            )| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    return Ok(world.add_wheel_joint(body_a, body_b, ax, ay, axis_x, axis_y));
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.addFrictionJoint(world_id, bodyA, bodyB, ax, ay, maxForce, maxTorque) -> joint_id
    /// Adds a friction joint that resists relative movement and rotation between two bodies.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body1` ÔÇö First body ID.
    /// - `body2` ÔÇö Second body ID.
    /// - `ax`, `ay` ÔÇö World-space anchor point.
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addFrictionJoint",
        lua.create_function(
            move |_,
                  (world_id_val, body_a, body_b, ax, ay, max_force, max_torque): (
                LuaValue,
                usize,
                usize,
                f32,
                f32,
                f32,
                f32,
            )| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    return Ok(
                        world.add_friction_joint(body_a, body_b, ax, ay, max_force, max_torque)
                    );
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.addMotorJoint(world_id, bodyA, bodyB, correctionFactor) -> joint_id
    /// Adds a motor joint that drives one body toward a target position relative to another.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body1` ÔÇö First body ID (reference).
    /// - `body2` ÔÇö Second body ID (driven).
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addMotorJoint",
        lua.create_function(
            move |_, (world_id_val, body_a, body_b, cf): (LuaValue, usize, usize, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    return Ok(world.add_motor_joint(body_a, body_b, cf));
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.addMouseJoint(world_id, body_id, targetX, targetY, maxForce) -> joint_id
    /// Adds a mouse joint that applies a spring force pulling a body toward a target point.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID to control.
    /// - `x`, `y` ÔÇö Initial target position in world coordinates.
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addMouseJoint",
        lua.create_function(
            move |_, (world_id_val, body_id_val, tx, ty, mf): (LuaValue, LuaValue, f32, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    return Ok(world.add_mouse_joint(body_id, tx, ty, mf));
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.setMouseJointTarget(world_id, joint_id, x, y)
    /// Updates the target world-space point that the mouse joint pulls the body toward.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `joint` ÔÇö Mouse joint ID.
    /// - `x` ÔÇö New target X in world units.
    /// - `y` ÔÇö New target Y in world units.
    let w = worlds.clone();
    physics.set(
        "setMouseJointTarget",
        lua.create_function(
            move |_, (world_id_val, joint_id, x, y): (LuaValue, usize, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_mouse_joint_target(joint_id, x, y);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.addPulleyJoint(world_id, bodyA, bodyB, ax, ay) -> joint_id (stub)
    /// Adds a pulley joint linking two bodies through a rope of fixed total length.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body1` ÔÇö First body ID.
    /// - `body2` ÔÇö Second body ID.
    /// - `gx1`, `gy1` ÔÇö Ground anchor for body1 in world coordinates.
    /// - `gx2`, `gy2` ÔÇö Ground anchor for body2 in world coordinates.
    /// - `ax1`, `ay1` ÔÇö Body1 attachment point in local coordinates.
    /// - `ax2`, `ay2` ÔÇö Body2 attachment point in local coordinates.
    /// - `ratio` ÔÇö Pulley ratio (1.0 = symmetric).
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addPulleyJoint",
        lua.create_function(
            move |_, (world_id_val, body_a, body_b, ax, ay): (LuaValue, usize, usize, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    return Ok(world.add_pulley_joint(body_a, body_b, ax, ay));
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.addGearJoint(world_id, bodyA, bodyB, ax, ay) -> joint_id (stub)
    /// Adds a gear joint that couples two revolute or prismatic joints so they move in sync.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `joint1` ÔÇö First revolute or prismatic joint ID.
    /// - `joint2` ÔÇö Second revolute or prismatic joint ID.
    /// - `ratio` ÔÇö Gear ratio between the two joints.
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addGearJoint",
        lua.create_function(
            move |_, (world_id_val, body_a, body_b, ax, ay): (LuaValue, usize, usize, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    return Ok(world.add_gear_joint(body_a, body_b, ax, ay));
                }
                Ok(0usize)
            },
        )?,
    )?;

    // ÔöÇÔöÇ Phase 07 Part 2: Joint property accessors ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.setJointMotorSpeed(world_id, joint_id, speed)
    /// Sets the target motor speed for a motorized revolute or prismatic joint.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `joint` ÔÇö Joint ID.
    /// - `speed` ÔÇö Target speed in rad/s (revolute) or m/s (prismatic).
    let w = worlds.clone();
    physics.set(
        "setJointMotorSpeed",
        lua.create_function(
            move |_, (world_id_val, joint_id, speed): (LuaValue, usize, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_joint_motor_speed(joint_id, speed);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.getJointMotorSpeed(world_id, joint_id) -> speed
    /// Returns the target motor speed of a revolute or prismatic joint.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `joint` ÔÇö Joint ID.
    ///
    /// # Returns
    /// Motor speed in rad/s (revolute) or m/s (prismatic).
    let w = worlds.clone();
    physics.set(
        "getJointMotorSpeed",
        lua.create_function(move |_, (world_id_val, joint_id): (LuaValue, usize)| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                return Ok(world.get_joint_motor_speed(joint_id));
            }
            Ok(0.0f32)
        })?,
    )?;

    // luna.physics.setJointLimitsEnabled(world_id, joint_id, enabled)
    /// Enables or disables the angular/linear limit constraints on a joint.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `joint` ÔÇö Joint ID.
    /// - `enabled` ÔÇö true to enforce limits, false to disable them.
    let w = worlds.clone();
    physics.set(
        "setJointLimitsEnabled",
        lua.create_function(
            move |_, (world_id_val, joint_id, enabled): (LuaValue, usize, bool)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_joint_limits_enabled(joint_id, enabled);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.setJointLimits(world_id, joint_id, lower, upper)
    /// Sets the lower and upper angular or linear limits on a constrained joint.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `joint` ÔÇö Joint ID.
    /// - `lower` ÔÇö Lower limit value (angle in radians or distance).
    /// - `upper` ÔÇö Upper limit value.
    let w = worlds.clone();
    physics.set(
        "setJointLimits",
        lua.create_function(
            move |_, (world_id_val, joint_id, lower, upper): (LuaValue, usize, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_joint_limits(joint_id, lower, upper);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.getJointLimits(world_id, joint_id) -> lower, upper
    /// Returns the lower and upper angular or linear limits set on the joint.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `joint` ÔÇö Joint ID.
    ///
    /// # Returns
    /// lower limit and upper limit values.
    let w = worlds.clone();
    physics.set(
        "getJointLimits",
        lua.create_function(move |_, (world_id_val, joint_id): (LuaValue, usize)| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                let (lo, hi) = world.get_joint_limits(joint_id);
                return Ok((lo, hi));
            }
            Ok((0.0f32, 0.0f32))
        })?,
    )?;

    // luna.physics.getJointType(world_id, joint_id) -> string
    /// Returns a string describing the type of the given joint.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `joint` ÔÇö Joint ID.
    ///
    /// # Returns
    /// Type string such as 'revolute', 'prismatic', 'distance', etc.
    let w = worlds.clone();
    physics.set(
        "getJointType",
        lua.create_function(move |_, (world_id_val, joint_id): (LuaValue, usize)| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                return Ok(world.get_joint_type(joint_id).to_string());
            }
            Ok("unknown".to_string())
        })?,
    )?;

    // ÔöÇÔöÇ Phase 07 Part 2: Meter scaling ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.setMeter(world_id, pixels_per_meter)
    /// Sets the pixels-per-meter ratio used to convert physics world units to screen pixels.
    ///
    /// # Parameters
    /// - `meter` ÔÇö Number of pixels that represent one physics meter.
    let w = worlds.clone();
    physics.set(
        "setMeter",
        lua.create_function(move |_, (world_id_val, ppm): (LuaValue, f32)| {
            let world_id = world_index_from_value(&world_id_val)?;
            let mut ws = w.borrow_mut();
            if let Some(world) = ws.get_mut(world_id) {
                world.set_meter(ppm);
            }
            Ok(())
        })?,
    )?;

    // luna.physics.getMeter(world_id) -> pixels_per_meter
    /// Returns the current pixels-per-meter scale set on the physics world.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID to query.
    ///
    /// # Returns
    /// Pixels-per-meter as a number.
    let w = worlds.clone();
    physics.set(
        "getMeter",
        lua.create_function(move |_, world_id_val: LuaValue| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                return Ok(world.get_meter());
            }
            Ok(1.0f32)
        })?,
    )?;

    // ÔöÇÔöÇ Phase 07 Part 2: Contact queries ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.getContacts(world_id) -> table of {bodyA, bodyB, nx, ny, touching}
    /// Returns a table of all currently active collision contact manifolds in the world.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    ///
    /// # Returns
    /// Table of contact records, each with body1, body2, nx, ny, and overlap fields.
    let w = worlds.clone();
    physics.set(
        "getContacts",
        lua.create_function(move |lua, world_id_val: LuaValue| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                let contacts = world.get_contacts();
                let table = lua.create_table()?;
                for (i, c) in contacts.iter().enumerate() {
                    let entry = lua.create_table()?;
                    /// Body a.
                    entry.set(
                        "bodyA",
                        LuaBody {
                            worlds: w.clone(),
                            world_index: world_id,
                            body_index: c.body_a,
                        },
                    )?;
                    /// Body b.
                    entry.set(
                        "bodyB",
                        LuaBody {
                            worlds: w.clone(),
                            world_index: world_id,
                            body_index: c.body_b,
                        },
                    )?;
                    /// Nx.
                    entry.set("nx", c.normal_x)?;
                    /// Ny.
                    entry.set("ny", c.normal_y)?;
                    /// Touching.
                    entry.set("touching", c.is_touching)?;
                    table.set(i + 1, entry)?;
                }
                return Ok(table);
            }
            lua.create_table()
        })?,
    )?;

    // luna.physics.getBodyContacts(world_id, body_id) -> table of {bodyA, bodyB, nx, ny, touching}
    /// Returns all active contact manifolds where this body touches another body.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID to query.
    ///
    /// # Returns
    /// Table of contact records for this body's current collisions.
    let w = worlds.clone();
    physics.set(
        "getBodyContacts",
        lua.create_function(
            move |lua, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    let contacts = world.get_body_contacts(body_id);
                    let table = lua.create_table()?;
                    for (i, c) in contacts.iter().enumerate() {
                        let entry = lua.create_table()?;
                        /// Body a.
                        entry.set(
                            "bodyA",
                            LuaBody {
                                worlds: w.clone(),
                                world_index: world_id,
                                body_index: c.body_a,
                            },
                        )?;
                        /// Body b.
                        entry.set(
                            "bodyB",
                            LuaBody {
                                worlds: w.clone(),
                                world_index: world_id,
                                body_index: c.body_b,
                            },
                        )?;
                        /// Nx.
                        entry.set("nx", c.normal_x)?;
                        /// Ny.
                        entry.set("ny", c.normal_y)?;
                        /// Touching.
                        entry.set("touching", c.is_touching)?;
                        table.set(i + 1, entry)?;
                    }
                    return Ok(table);
                }
                lua.create_table()
            },
        )?,
    )?;

    // ÔöÇÔöÇ New Phase 07 bindings: body property getters ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.getGravityScale(world_id, body_id) -> scale
    /// Returns the per-body gravity scale factor applied to the world gravity vector.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    ///
    /// # Returns
    /// Gravity scale as a number (1.0 = normal gravity, 0.0 = no gravity).
    let w = worlds.clone();
    physics.set(
        "getGravityScale",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    return Ok(world.get_gravity_scale(body_id));
                }
                Ok(1.0f32)
            },
        )?,
    )?;

    // luna.physics.isFixedRotation(world_id, body_id) -> bool
    /// Returns whether the body's rotation is locked and prevented from changing.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    ///
    /// # Returns
    /// true if rotation is fixed, false if it is free.
    let w = worlds.clone();
    physics.set(
        "isFixedRotation",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    return Ok(world.is_fixed_rotation(body_id));
                }
                Ok(false)
            },
        )?,
    )?;

    // luna.physics.getLinearDamping(world_id, body_id) -> damping
    /// Returns the linear damping coefficient that gradually slows the body's movement.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    ///
    /// # Returns
    /// Linear damping coefficient as a non-negative number.
    let w = worlds.clone();
    physics.set(
        "getLinearDamping",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    return Ok(world.get_linear_damping(body_id));
                }
                Ok(0.0f32)
            },
        )?,
    )?;

    // luna.physics.getAngularDamping(world_id, body_id) -> damping
    /// Returns the angular damping coefficient of the body that slows its rotation over time.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    ///
    /// # Returns
    /// Angular damping coefficient as a non-negative number.
    let w = worlds.clone();
    physics.set(
        "getAngularDamping",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    return Ok(world.get_angular_damping(body_id));
                }
                Ok(0.0f32)
            },
        )?,
    )?;

    // luna.physics.applyForceAtPoint(world_id, body_id, fx, fy, px, py)
    /// Applies a world-space force at a given point on the body, potentially adding torque.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Target body ID.
    /// - `fx`, `fy` ÔÇö Force vector in Newtons.
    /// - `px`, `py` ÔÇö World-space point of application.
    let w = worlds.clone();
    physics.set(
        "applyForceAtPoint",
        lua.create_function(
            move |_,
                  (world_id_val, body_id_val, fx, fy, px, py): (
                LuaValue,
                LuaValue,
                f32,
                f32,
                f32,
                f32,
            )| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.apply_force_at_point(body_id, fx, fy, px, py);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.applyAngularImpulse(world_id, body_id, impulse)
    /// Applies an instantaneous angular impulse to the body, changing its spin velocity.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Target body ID.
    /// - `impulse` ÔÇö Angular impulse magnitude in N┬Ěm┬Ěs.
    let w = worlds.clone();
    physics.set(
        "applyAngularImpulse",
        lua.create_function(
            move |_, (world_id_val, body_id_val, impulse): (LuaValue, LuaValue, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.apply_angular_impulse(body_id, impulse);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.getJointCount(world_id) -> count
    /// Returns the total number of joints currently active in the physics world.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    ///
    /// # Returns
    /// Joint count as an integer.
    let w = worlds.clone();
    physics.set(
        "getJointCount",
        lua.create_function(move |_, world_id_val: LuaValue| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                return Ok(world.joint_count());
            }
            Ok(0usize)
        })?,
    )?;

    // luna.physics.getBodies(world_id) -> {body_id, ...}
    /// Returns a table of all body IDs currently registered in the physics world.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID to query.
    ///
    /// # Returns
    /// Table of body ID integers.
    let w = worlds.clone();
    physics.set(
        "getBodies",
        lua.create_function(move |lua, world_id_val: LuaValue| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            let table = lua.create_table()?;
            if let Some(world) = ws.get(world_id) {
                for (i, id) in world.get_body_ids().into_iter().enumerate() {
                    table.set(i + 1, id)?;
                }
            }
            Ok(table)
        })?,
    )?;

    // luna.physics.getJoints(world_id) -> {joint_id, ...}
    /// Returns a table of all joint IDs currently active in the physics world.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID to query.
    ///
    /// # Returns
    /// Table of joint ID integers.
    let w = worlds.clone();
    physics.set(
        "getJoints",
        lua.create_function(move |lua, world_id_val: LuaValue| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            let table = lua.create_table()?;
            if let Some(world) = ws.get(world_id) {
                for (i, id) in world.get_joint_ids().into_iter().enumerate() {
                    table.set(i + 1, id)?;
                }
            }
            Ok(table)
        })?,
    )?;

    // luna.physics.destroyWorld(world_id)
    /// Destroys a physics world and frees all associated resources.
    let w = worlds.clone();
    physics.set(
        "destroyWorld",
        lua.create_function(move |_, world_id_val: LuaValue| {
            let world_id = world_index_from_value(&world_id_val)?;
            let mut ws = w.borrow_mut();
            if let Some(world) = ws.get_mut(world_id) {
                world.clear();
            }
            Ok(())
        })?,
    )?;

    // luna.physics.newRegularPolygonBody(world_id, x, y, radius, sides, body_type) -> body_id
    /// Creates a new regular polygon body.
    let w = worlds.clone();
    physics.set(
        "newRegularPolygonBody",
        lua.create_function(
            move |_,
                  (world_id_val, x, y, radius, sides, bt): (
                LuaValue,
                f32,
                f32,
                f32,
                u32,
                String,
            )| {
                let vertices =
                    if let Shape::Polygon { vertices } = Shape::regular_polygon(radius, sides) {
                        vertices
                    } else {
                        Vec::new()
                    };
                let body = Body::new_polygon(x, y, vertices, parse_body_type(&bt));
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let id = world.add_body(body);
                    return Ok(LuaBody {
                        worlds: w.clone(),
                        world_index: world_id,
                        body_index: id,
                    });
                }
                Ok(LuaBody {
                    worlds: w.clone(),
                    world_index: world_id,
                    body_index: 0,
                })
            },
        )?,
    )?;

    /// Physics.
    Ok(())
}
