//! Registers the `luna.physics.*` physics API.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::Vec2;
use crate::physics::{Body, World};

mod helpers;
pub(super) mod ext;
#[allow(unused_imports)]
use helpers::*;

pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let physics = lua.create_table()?;

    // Store worlds in a RefCell so closures can share them
    let worlds: Rc<RefCell<Vec<World>>> = Rc::new(RefCell::new(Vec::new()));

    // luna.physics.newWorld(gx, gy) -> world_id
    /// Creates a new physics simulation world.
    let w = worlds.clone();
    physics.set(
        "newWorld",
        lua.create_function(move |_, (gx, gy): (f32, f32)| {
            let mut ws = w.borrow_mut();
            let world = World::new(gx, gy);
            let id = ws.len();
            ws.push(world);
            Ok(LuaWorld {
                worlds: w.clone(),
                index: id,
                begin_contact_cb: Rc::new(RefCell::new(None)),
                end_contact_cb: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;

    // luna.physics.newBody(world_id, x, y, body_type) -> body_id
    /// Creates a rigid body in the given world.
    let w = worlds.clone();
    physics.set(
        "newBody",
        lua.create_function(
            move |_, (world_id_val, x, y, btype): (LuaValue, f32, f32, String)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let bt = parse_body_type(&btype);
                    let body = Body::new(x, y, bt);
                    let id = world.add_body(body);
                    Ok(LuaBody {
                        worlds: w.clone(),
                        world_index: world_id,
                        body_index: id,
                    })
                } else {
                    Err(LuaError::RuntimeError("Invalid world id".into()))
                }
            },
        )?,
    )?;

    // luna.physics.setBodySize(world_id, body_id, w, h)
    /// Sets the width and height dimensions of the body's collision shape.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID to resize.
    /// - `width` ÔÇö New shape width in world units.
    /// - `height` ÔÇö New shape height in world units.
    let w = worlds.clone();
    physics.set(
        "setBodySize",
        lua.create_function(
            move |_, (world_id_val, body_id_val, bw, bh): (LuaValue, LuaValue, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    if let Some(body) = world.get_body_mut(body_id) {
                        body.width = bw;
                        body.height = bh;
                    }
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.getBody(world_id, body_id) -> x, y, vx, vy
    /// Returns the body object table for the given body ID within the world.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID to look up.
    ///
    /// # Returns
    /// Body property table, or nil if the ID is not found.
    let w = worlds.clone();
    physics.set(
        "getBody",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    if let Some(body) = world.get_body(body_id) {
                        return Ok((
                            body.position.x,
                            body.position.y,
                            body.velocity.x,
                            body.velocity.y,
                        ));
                    }
                }
                Ok((0.0f32, 0.0f32, 0.0f32, 0.0f32))
            },
        )?,
    )?;

    // luna.physics.setBodyVelocity(world_id, body_id, vx, vy)
    /// Sets the linear velocity of a physics body.
    let w = worlds.clone();
    physics.set(
        "setBodyVelocity",
        lua.create_function(
            move |_, (world_id_val, body_id_val, vx, vy): (LuaValue, LuaValue, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    if let Some(body) = world.get_body_mut(body_id) {
                        body.velocity = Vec2::new(vx, vy);
                    }
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.step(world_id, dt)
    /// Advances the physics simulation by the given timestep in seconds.
    let w = worlds.clone();
    physics.set(
        "step",
        lua.create_function(move |_, (world_id_val, dt): (LuaValue, f32)| {
            let world_id = world_index_from_value(&world_id_val)?;
            let mut ws = w.borrow_mut();
            if let Some(world) = ws.get_mut(world_id) {
                world.step(dt);
            }
            Ok(())
        })?,
    )?;

    // ÔöÇÔöÇ Circle body creation ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.newCircleBody(world_id, x, y, radius, body_type) -> body_id
    /// Creates a circle-shaped physics body at the given world position.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `type` ÔÇö Body type: 'static', 'dynamic', or 'kinematic'.
    /// - `x` ÔÇö Center X in world units.
    /// - `y` ÔÇö Center Y in world units.
    /// - `radius` ÔÇö Circle radius in world units.
    ///
    /// # Returns
    /// New body ID.
    let w = worlds.clone();
    physics.set(
        "newCircleBody",
        lua.create_function(
            move |_, (world_id_val, x, y, radius, btype): (LuaValue, f32, f32, f32, String)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let bt = parse_body_type(&btype);
                    let body = Body::new_circle(x, y, radius, bt);
                    let id = world.add_body(body);
                    Ok(LuaBody {
                        worlds: w.clone(),
                        world_index: world_id,
                        body_index: id,
                    })
                } else {
                    Err(LuaError::RuntimeError("Invalid world id".into()))
                }
            },
        )?,
    )?;

    // ÔöÇÔöÇ Extended body properties ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.setBodyPosition(world_id, body_id, x, y)
    /// Sets the position of a physics body.
    let w = worlds.clone();
    physics.set(
        "setBodyPosition",
        lua.create_function(
            move |_, (world_id_val, body_id_val, x, y): (LuaValue, LuaValue, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_body_position(body_id, x, y);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.getBodyAngle(world_id, body_id) -> radians
    /// Returns the current rotation angle (radians) of a physics body.
    let w = worlds.clone();
    physics.set(
        "getBodyAngle",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    return Ok(world.get_body_angle(body_id));
                }
                Ok(0.0f32)
            },
        )?,
    )?;

    // luna.physics.setBodyAngle(world_id, body_id, angle)
    /// Sets the rotation angle (radians) of a physics body.
    let w = worlds.clone();
    physics.set(
        "setBodyAngle",
        lua.create_function(
            move |_, (world_id_val, body_id_val, angle): (LuaValue, LuaValue, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_body_angle(body_id, angle);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.getBodyMass(world_id, body_id) -> mass
    /// Returns the mass of a physics body.
    let w = worlds.clone();
    physics.set(
        "getBodyMass",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    return Ok(world.get_body_mass(body_id));
                }
                Ok(0.0f32)
            },
        )?,
    )?;

    // luna.physics.setBodyMass(world_id, body_id, mass)
    /// Overrides the simulated mass of the body with the given value.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    /// - `mass` ÔÇö New mass in physics units.
    let w = worlds.clone();
    physics.set(
        "setBodyMass",
        lua.create_function(
            move |_, (world_id_val, body_id_val, mass): (LuaValue, LuaValue, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_body_mass(body_id, mass);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.applyForce(world_id, body_id, fx, fy)
    /// Applies a force vector to a body at its center of mass.
    let w = worlds.clone();
    physics.set(
        "applyForce",
        lua.create_function(
            move |_, (world_id_val, body_id_val, fx, fy): (LuaValue, LuaValue, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.apply_force(body_id, fx, fy);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.applyTorque(world_id, body_id, torque)
    /// Applies a rotational torque to a body.
    let w = worlds.clone();
    physics.set(
        "applyTorque",
        lua.create_function(
            move |_, (world_id_val, body_id_val, torque): (LuaValue, LuaValue, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.apply_torque(body_id, torque);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.setAngularVelocity(world_id, body_id, omega)
    /// Sets the angular velocity of the body to the given value in radians per second.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    /// - `omega` ÔÇö Angular velocity in radians per second.
    let w = worlds.clone();
    physics.set(
        "setAngularVelocity",
        lua.create_function(
            move |_, (world_id_val, body_id_val, omega): (LuaValue, LuaValue, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_angular_velocity(body_id, omega);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.getAngularVelocity(world_id, body_id) -> omega
    /// Returns the current angular velocity of the body in radians per second.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    ///
    /// # Returns
    /// Angular velocity in radians per second.
    let w = worlds.clone();
    physics.set(
        "getAngularVelocity",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    return Ok(world.get_angular_velocity(body_id));
                }
                Ok(0.0f32)
            },
        )?,
    )?;

    // luna.physics.setFixedRotation(world_id, body_id, fixed)
    /// Locks or unlocks the body's rotation axis so it cannot spin in the simulation.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    /// - `fixed` ÔÇö true to prevent rotation, false to allow it.
    let w = worlds.clone();
    physics.set(
        "setFixedRotation",
        lua.create_function(
            move |_, (world_id_val, body_id_val, fixed): (LuaValue, LuaValue, bool)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_fixed_rotation(body_id, fixed);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.setLinearDamping(world_id, body_id, damping)
    /// Sets the linear damping coefficient that gradually slows the body's movement.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    /// - `damping` ÔÇö Non-negative damping coefficient.
    let w = worlds.clone();
    physics.set(
        "setLinearDamping",
        lua.create_function(
            move |_, (world_id_val, body_id_val, damping): (LuaValue, LuaValue, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_linear_damping(body_id, damping);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.setAngularDamping(world_id, body_id, damping)
    /// Sets the angular damping coefficient that gradually reduces the body's spin.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    /// - `damping` ÔÇö Non-negative damping coefficient.
    let w = worlds.clone();
    physics.set(
        "setAngularDamping",
        lua.create_function(
            move |_, (world_id_val, body_id_val, damping): (LuaValue, LuaValue, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_angular_damping(body_id, damping);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.setGravityScale(world_id, body_id, scale)
    /// Sets a per-body multiplier applied to the world gravity vector for this body.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    /// - `scale` ÔÇö Gravity scale (1.0 = full gravity, 0.0 = weightless).
    let w = worlds.clone();
    physics.set(
        "setGravityScale",
        lua.create_function(
            move |_, (world_id_val, body_id_val, scale): (LuaValue, LuaValue, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_gravity_scale(body_id, scale);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.setBullet(world_id, body_id, bullet)
    /// Enables continuous collision detection (CCD) on a body to prevent tunneling at high speeds.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID to configure.
    /// - `enable` ÔÇö true to enable CCD, false to disable.
    let w = worlds.clone();
    physics.set(
        "setBullet",
        lua.create_function(
            move |_, (world_id_val, body_id_val, bullet): (LuaValue, LuaValue, bool)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_bullet(body_id, bullet);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.isBullet(world_id, body_id) -> bool
    /// Returns whether continuous collision detection (CCD) is enabled on the body.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    ///
    /// # Returns
    /// true if CCD is active, false otherwise.
    let w = worlds.clone();
    physics.set(
        "isBullet",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                let result = ws
                    .get(world_id)
                    .map(|world| world.is_bullet(body_id))
                    .unwrap_or(false);
                Ok(result)
            },
        )?,
    )?;

    // luna.physics.getBodyType(world_id, body_id) -> "static"/"dynamic"/"kinematic"/"sensor"
    /// Returns the type string of the given body.
    let w = worlds.clone();
    physics.set(
        "getBodyType",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    return Ok(world.get_body_type_str(body_id).to_string());
                }
                Ok("dynamic".to_string())
            },
        )?,
    )?;

    // luna.physics.setBodyType(world_id, body_id, type_str)
    /// Sets the body type: 'dynamic', 'static', or 'kinematic'.
    let w = worlds.clone();
    physics.set(
        "setBodyType",
        lua.create_function(
            move |_, (world_id_val, body_id_val, btype): (LuaValue, LuaValue, String)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let bt = parse_body_type(&btype);
                    world.set_body_type(body_id, bt);
                }
                Ok(())
            },
        )?,
    )?;

    // ÔöÇÔöÇ World management ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.setGravity(world_id, gx, gy)
    /// Sets the global gravity vector for the world.
    let w = worlds.clone();
    physics.set(
        "setGravity",
        lua.create_function(move |_, (world_id_val, gx, gy): (LuaValue, f32, f32)| {
            let world_id = world_index_from_value(&world_id_val)?;
            let mut ws = w.borrow_mut();
            if let Some(world) = ws.get_mut(world_id) {
                world.set_gravity(gx, gy);
            }
            Ok(())
        })?,
    )?;

    // luna.physics.getGravity(world_id) -> gx, gy
    /// Returns the global gravity vector (gx, gy).
    let w = worlds.clone();
    physics.set(
        "getGravity",
        lua.create_function(move |_, world_id_val: LuaValue| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                let (gx, gy) = world.get_gravity();
                return Ok((gx, gy));
            }
            Ok((0.0f32, 0.0f32))
        })?,
    )?;

    // luna.physics.getBodyCount(world_id) -> count
    /// Returns the number of bodies in the world.
    let w = worlds.clone();
    physics.set(
        "getBodyCount",
        lua.create_function(move |_, world_id_val: LuaValue| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                return Ok(world.body_count());
            }
            Ok(0usize)
        })?,
    )?;

    // luna.physics.setSleepingAllowed(world_id, body_id, allowed)
    /// Sets whether the body is allowed to enter a sleep state when it comes to rest.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    /// - `allowed` ÔÇö true to allow sleeping, false to keep the body always awake.
    let w = worlds.clone();
    physics.set(
        "setSleepingAllowed",
        lua.create_function(
            move |_, (world_id_val, body_id_val, allowed): (LuaValue, LuaValue, bool)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.set_sleeping_allowed(body_id, allowed);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.isSleepingAllowed(world_id, body_id) -> bool
    /// Returns whether the body is allowed to enter a sleep state when inactive.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body` ÔÇö Body ID.
    ///
    /// # Returns
    /// true if sleeping is permitted, false if the body is always active.
    let w = worlds.clone();
    physics.set(
        "isSleepingAllowed",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    return Ok(world.is_sleeping_allowed(body_id));
                }
                Ok(true)
            },
        )?,
    )?;

    // luna.physics.destroyBody(world_id, body_id)
    /// Removes a body from the physics world.
    let w = worlds.clone();
    physics.set(
        "destroyBody",
        lua.create_function(
            move |_, (world_id_val, body_id_val): (LuaValue, LuaValue)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.destroy_body(body_id);
                }
                Ok(())
            },
        )?,
    )?;

    // luna.physics.destroyJoint(world_id, joint_id)
    /// Removes the given joint from the world and frees its resources.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID that owns the joint.
    /// - `joint` ÔÇö Joint ID to destroy.
    let w = worlds.clone();
    physics.set(
        "destroyJoint",
        lua.create_function(move |_, (world_id_val, joint_id): (LuaValue, usize)| {
            let world_id = world_index_from_value(&world_id_val)?;
            let mut ws = w.borrow_mut();
            if let Some(world) = ws.get_mut(world_id) {
                world.destroy_joint(joint_id);
            }
            Ok(())
        })?,
    )?;

    // ÔöÇÔöÇ Collision events ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.getCollisions(world_id) -> table of {body_a, body_b}
    /// Returns all collision pairs currently overlapping in the physics world.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    ///
    /// # Returns
    /// Table of {bodyA, bodyB, nx, ny, overlap} collision records.
    let w = worlds.clone();
    physics.set(
        "getCollisions",
        lua.create_function(move |lua, world_id_val: LuaValue| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                let events = world.get_collision_events();
                let table = lua.create_table()?;
                for (i, ev) in events.iter().enumerate() {
                    let pair = lua.create_table()?;
                    /// Body_a.
                    pair.set(
                        "body_a",
                        LuaBody {
                            worlds: w.clone(),
                            world_index: world_id,
                            body_index: ev.body_a,
                        },
                    )?;
                    /// Body_b.
                    pair.set(
                        "body_b",
                        LuaBody {
                            worlds: w.clone(),
                            world_index: world_id,
                            body_index: ev.body_b,
                        },
                    )?;
                    table.set(i + 1, pair)?;
                }
                return Ok(table);
            }
            lua.create_table()
        })?,
    )?;

    // ÔöÇÔöÇ Raycasting ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.raycast(world_id, x1, y1, x2, y2) -> {body_id, x, y, nx, ny, toi} or nil
    /// Casts a ray from the origin in the given direction and returns the first body hit.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID to cast in.
    /// - `x1` ÔÇö Ray origin X in world units.
    /// - `y1` ÔÇö Ray origin Y in world units.
    /// - `x2` ÔÇö Ray end X in world units.
    /// - `y2` ÔÇö Ray end Y in world units.
    ///
    /// # Returns
    /// Body ID, hit x, hit y, and surface normal nx, ny; or nil if no hit.
    let w = worlds.clone();
    physics.set(
        "raycast",
        lua.create_function(
            move |lua, (world_id_val, x1, y1, x2, y2): (LuaValue, f32, f32, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    let dx = x2 - x1;
                    let dy = y2 - y1;
                    let max_dist = (dx * dx + dy * dy).sqrt();
                    if let Some(hit) = world.raycast_closest(x1, y1, dx, dy, max_dist) {
                        let table = lua.create_table()?;
                        /// Body_id.
                        table.set(
                            "body_id",
                            LuaBody {
                                worlds: w.clone(),
                                world_index: world_id,
                                body_index: hit.body_id,
                            },
                        )?;
                        /// X.
                        table.set("x", hit.point.0)?;
                        /// Y.
                        table.set("y", hit.point.1)?;
                        /// Nx.
                        table.set("nx", hit.normal.0)?;
                        /// Ny.
                        table.set("ny", hit.normal.1)?;
                        /// Toi.
                        table.set("toi", hit.toi)?;
                        return Ok(LuaValue::Table(table));
                    }
                }
                Ok(LuaValue::Nil)
            },
        )?,
    )?;

    // luna.physics.raycastAll(world_id, x1, y1, x2, y2) -> table of hits
    /// Casts a ray and returns every body it intersects, sorted by distance.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID to cast in.
    /// - `x1` ÔÇö Ray origin X in world units.
    /// - `y1` ÔÇö Ray origin Y in world units.
    /// - `x2` ÔÇö Ray end X in world units.
    /// - `y2` ÔÇö Ray end Y in world units.
    ///
    /// # Returns
    /// Table of {body, x, y, nx, ny, fraction} hit records ordered by fraction.
    let w = worlds.clone();
    physics.set(
        "raycastAll",
        lua.create_function(
            move |lua, (world_id_val, x1, y1, x2, y2): (LuaValue, f32, f32, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    let dx = x2 - x1;
                    let dy = y2 - y1;
                    let max_dist = (dx * dx + dy * dy).sqrt();
                    let hits = world.raycast_all(x1, y1, dx, dy, max_dist);
                    let table = lua.create_table()?;
                    for (i, hit) in hits.iter().enumerate() {
                        let entry = lua.create_table()?;
                        /// Body_id.
                        entry.set(
                            "body_id",
                            LuaBody {
                                worlds: w.clone(),
                                world_index: world_id,
                                body_index: hit.body_id,
                            },
                        )?;
                        /// X.
                        entry.set("x", hit.point.0)?;
                        /// Y.
                        entry.set("y", hit.point.1)?;
                        /// Nx.
                        entry.set("nx", hit.normal.0)?;
                        /// Ny.
                        entry.set("ny", hit.normal.1)?;
                        /// Toi.
                        entry.set("toi", hit.toi)?;
                        table.set(i + 1, entry)?;
                    }
                    return Ok(table);
                }
                lua.create_table()
            },
        )?,
    )?;

    // ÔöÇÔöÇ Spatial queries ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.queryBoundingBox(world_id, x, y, w, h) -> table of body_ids
    /// Returns all bodies whose axis-aligned bounding boxes overlap the given query rectangle.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `x1` ÔÇö Left edge of the query box in world units.
    /// - `y1` ÔÇö Top edge of the query box in world units.
    /// - `x2` ÔÇö Right edge in world units.
    /// - `y2` ÔÇö Bottom edge in world units.
    ///
    /// # Returns
    /// Table of body IDs whose AABBs intersect the query box.
    let w = worlds.clone();
    physics.set(
        "queryBoundingBox",
        lua.create_function(
            move |lua, (world_id_val, x, y, qw, qh): (LuaValue, f32, f32, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let ws = w.borrow();
                if let Some(world) = ws.get(world_id) {
                    let ids = world.query_aabb(x, y, qw, qh);
                    let table = lua.create_table()?;
                    for (i, &id) in ids.iter().enumerate() {
                        table.set(
                            i + 1,
                            LuaBody {
                                worlds: w.clone(),
                                world_index: world_id,
                                body_index: id,
                            },
                        )?;
                    }
                    return Ok(table);
                }
                lua.create_table()
            },
        )?,
    )?;

    // ÔöÇÔöÇ Joint API ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.physics.addRevoluteJoint(world_id, bodyA, bodyB, ax, ay) -> joint_id
    /// Adds a revolute joint that constrains two bodies to rotate around a shared anchor point.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body1` ÔÇö First body ID.
    /// - `body2` ÔÇö Second body ID.
    /// - `ax`, `ay` ÔÇö World-space anchor point to revolve around.
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addRevoluteJoint",
        lua.create_function(
            move |_, (world_id_val, body_a, body_b, ax, ay): (LuaValue, usize, usize, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let jid = world.add_revolute_joint(body_a, body_b, ax, ay);
                    return Ok(jid);
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.addDistanceJoint(world_id, bodyA, bodyB, ax1, ay1, ax2, ay2, length) -> joint_id
    /// Adds a distance joint that maintains a fixed separation between two body anchor points.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body1` ÔÇö First body ID.
    /// - `body2` ÔÇö Second body ID.
    /// - `x1`, `y1` ÔÇö Anchor on body1 in local coordinates.
    /// - `x2`, `y2` ÔÇö Anchor on body2 in local coordinates.
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addDistanceJoint",
        lua.create_function(
            move |_,
                  (world_id_val, body_a, body_b, ax1, ay1, ax2, ay2, length): (
                LuaValue,
                usize,
                usize,
                f32,
                f32,
                f32,
                f32,
                f32,
            )| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let jid = world.add_distance_joint(body_a, body_b, ax1, ay1, ax2, ay2, length);
                    return Ok(jid);
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.addPrismaticJoint(world_id, bodyA, bodyB, ax, ay, axisX, axisY) -> joint_id
    /// Adds a prismatic joint that constrains two bodies to slide along a single axis.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body1` ÔÇö First body ID.
    /// - `body2` ÔÇö Second body ID.
    /// - `ax`, `ay` ÔÇö World-space anchor point.
    /// - `axisX`, `axisY` ÔÇö Slide axis direction (unit vector).
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addPrismaticJoint",
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
                    let jid = world.add_prismatic_joint(body_a, body_b, ax, ay, axis_x, axis_y);
                    return Ok(jid);
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.addWeldJoint(world_id, bodyA, bodyB, ax, ay) -> joint_id
    /// Adds a weld joint that rigidly fixes the relative position and angle of two bodies.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body1` ÔÇö First body ID.
    /// - `body2` ÔÇö Second body ID.
    /// - `ax`, `ay` ÔÇö World-space anchor point for the weld.
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addWeldJoint",
        lua.create_function(
            move |_, (world_id_val, body_a, body_b, ax, ay): (LuaValue, usize, usize, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let jid = world.add_weld_joint(body_a, body_b, ax, ay);
                    return Ok(jid);
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.addRopeJoint(world_id, bodyA, bodyB, ax1, ay1, ax2, ay2, maxLength) -> joint_id
    /// Adds a rope joint that enforces a maximum distance between two body anchor points.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `body1` ÔÇö First body ID.
    /// - `body2` ÔÇö Second body ID.
    /// - `x1`, `y1` ÔÇö Anchor on body1 in local coordinates.
    /// - `x2`, `y2` ÔÇö Anchor on body2 in local coordinates.
    /// - `maxLength` ÔÇö Maximum allowed distance in world units.
    ///
    /// # Returns
    /// New joint ID.
    let w = worlds.clone();
    physics.set(
        "addRopeJoint",
        lua.create_function(
            move |_,
                  (world_id_val, body_a, body_b, ax1, ay1, ax2, ay2, max_len): (
                LuaValue,
                usize,
                usize,
                f32,
                f32,
                f32,
                f32,
                f32,
            )| {
                let world_id = world_index_from_value(&world_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    let jid = world.add_rope_joint(body_a, body_b, ax1, ay1, ax2, ay2, max_len);
                    return Ok(jid);
                }
                Ok(0usize)
            },
        )?,
    )?;

    // luna.physics.getJointBodies(world_id, joint_id) -> bodyA, bodyB
    /// Returns the two body IDs connected by the given joint.
    ///
    /// # Parameters
    /// - `world` ÔÇö World ID.
    /// - `joint` ÔÇö Joint ID to query.
    ///
    /// # Returns
    /// body1 ID and body2 ID.
    let w = worlds.clone();
    physics.set(
        "getJointBodies",
        lua.create_function(move |_, (world_id_val, joint_id): (LuaValue, usize)| {
            let world_id = world_index_from_value(&world_id_val)?;
            let ws = w.borrow();
            if let Some(world) = ws.get(world_id) {
                if let Some((a, b)) = world.get_joint_bodies(joint_id) {
                    return Ok((a, b));
                }
            }
            Ok((0usize, 0usize))
        })?,
    )?;

    // luna.physics.applyImpulse(world_id, body_id, ix, iy)
    /// Applies an instantaneous impulse to a body.
    let w = worlds.clone();
    physics.set(
        "applyImpulse",
        lua.create_function(
            move |_, (world_id_val, body_id_val, ix, iy): (LuaValue, LuaValue, f32, f32)| {
                let world_id = world_index_from_value(&world_id_val)?;
                let body_id = body_index_from_value(&body_id_val)?;
                let mut ws = w.borrow_mut();
                if let Some(world) = ws.get_mut(world_id) {
                    world.apply_impulse(body_id, ix, iy);
                }
                Ok(())
            },
        )?,
    )?;


    ext::register_ext(lua, &physics, &worlds)?;

    luna.set("physics", physics)?;
    Ok(())
}
