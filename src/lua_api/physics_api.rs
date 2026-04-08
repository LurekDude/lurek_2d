//! `luna.physics` — Rigid-body physics simulation, collision detection, joints, and raycasting.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use super::SharedState;
use crate::math::Vec2;
use crate::physics::{Body, BodyType, RaycastHit, Shape, World};

// -------------------------------------------------------------------------------
// Helper: parse BodyType from string
// -------------------------------------------------------------------------------

fn parse_body_type(s: &str) -> LuaResult<BodyType> {
    match s {
        "static" => Ok(BodyType::Static),
        "dynamic" => Ok(BodyType::Dynamic),
        "kinematic" => Ok(BodyType::Kinematic),
        "sensor" => Ok(BodyType::Sensor),
        _ => Err(LuaError::external(format!(
            "invalid body type '{}': expected static, dynamic, kinematic, or sensor",
            s
        ))),
    }
}

/// Like parse_body_type but coerces any unknown string to Dynamic instead of erroring.
fn parse_body_type_lenient(s: &str) -> BodyType {
    match s {
        "static" => BodyType::Static,
        "kinematic" => BodyType::Kinematic,
        "sensor" => BodyType::Sensor,
        _ => BodyType::Dynamic,
    }
}

// -------------------------------------------------------------------------------
// Helper: parse Shape from string + args
// -------------------------------------------------------------------------------

fn shape_from_lua(lua: &Lua, shape_type: &str, args: LuaMultiValue) -> LuaResult<Shape> {
    let mut float_args: Vec<f32> = Vec::new();
    let mut closed = false;
    let mut iter = args.into_iter();
    let first = iter.next().unwrap_or(LuaValue::Nil);
    if matches!(shape_type, "polygon" | "chain") {
        let tbl: LuaTable = lua.unpack(first)?;
        let len = tbl.raw_len();
        let mut i = 1i64;
        while i < len as i64 {
            float_args.push(tbl.raw_get(i)?);
            float_args.push(tbl.raw_get(i + 1)?);
            i += 2;
        }
        if shape_type == "chain" {
            closed = lua
                .unpack(iter.next().unwrap_or(LuaValue::Boolean(false)))
                .unwrap_or(false);
        }
    } else {
        float_args.push(lua.unpack(first)?);
        for v in iter {
            if let Ok(f) = lua.unpack::<f32>(v) {
                float_args.push(f);
            }
        }
    }
    Shape::from_parts(shape_type, &float_args, closed).map_err(LuaError::runtime)
}

// -------------------------------------------------------------------------------
// Helper: convert RaycastHit to a Lua table
// -------------------------------------------------------------------------------

fn raycast_hit_to_table<'lua>(lua: &'lua Lua, hit: &RaycastHit) -> LuaResult<LuaTable<'lua>> {
    let tbl = lua.create_table()?;
    tbl.set("bodyId", hit.body_id)?;
    tbl.set("x", hit.point.0)?;
    tbl.set("y", hit.point.1)?;
    tbl.set("normalX", hit.normal.0)?;
    tbl.set("normalY", hit.normal.1)?;
    tbl.set("toi", hit.toi)?;
    Ok(tbl)
}

// -------------------------------------------------------------------------------
// LuaWorld UserData
// -------------------------------------------------------------------------------

/// Lua-side handle wrapping a physics World.
#[derive(Clone)]
pub struct LuaWorld {
    world: Rc<RefCell<World>>,
}

impl LuaUserData for LuaWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- step --
        /// Advances the physics simulation by dt seconds.
        /// @param dt : number
        /// @return nil
        methods.add_method("step", |_, this, dt: f32| {
            this.world.borrow_mut().step(dt);
            Ok(())
        });

        // -- clear --
        /// Resets the world, removing all bodies and joints.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            this.world.borrow_mut().clear();
            Ok(())
        });

        // -- getGravity --
        /// Returns the gravity vector (gx, gy).
        /// @return number, number
        methods.add_method("getGravity", |_, this, ()| {
            Ok(this.world.borrow().get_gravity())
        });

        // -- setGravity --
        /// Sets the gravity vector.
        /// @param gx : number
        /// @param gy : number
        /// @return nil
        methods.add_method("setGravity", |_, this, (gx, gy): (f32, f32)| {
            this.world.borrow_mut().set_gravity(gx, gy);
            Ok(())
        });

        // -- setMeter --
        /// Sets the pixels-per-meter scaling factor.
        /// @param ppm : number
        /// @return nil
        methods.add_method("setMeter", |_, this, ppm: f32| {
            this.world.borrow_mut().set_meter(ppm);
            Ok(())
        });

        // -- getMeter --
        /// Returns the pixels-per-meter scaling factor.
        /// @return number
        methods.add_method("getMeter", |_, this, ()| {
            Ok(this.world.borrow().get_meter())
        });

        // -- toPhysics --
        /// Converts a pixel value to physics units.
        /// @param px : number
        /// @return number
        methods.add_method("toPhysics", |_, this, px: f32| {
            Ok(this.world.borrow().to_physics(px))
        });

        // -- toPixels --
        /// Converts a physics-unit value to pixels.
        /// @param m : number
        /// @return number
        methods.add_method("toPixels", |_, this, m: f32| {
            Ok(this.world.borrow().to_pixels(m))
        });

        // -- getBodyCount --
        /// Returns the total number of bodies in the world.
        /// @return integer
        methods.add_method("getBodyCount", |_, this, ()| {
            Ok(this.world.borrow().body_count())
        });

        // -- getBodyIds --
        /// Returns all body IDs in the world.
        /// @return table
        methods.add_method("getBodyIds", |_, this, ()| {
            Ok(this.world.borrow().get_body_ids())
        });

        // -- destroyBody --
        /// Removes a body from the world.
        /// @param id : integer
        /// @return nil
        methods.add_method("destroyBody", |_, this, id: usize| {
            this.world.borrow_mut().destroy_body(id);
            Ok(())
        });

        // -- newBody --
        /// Creates a new rectangular body and adds it to the world.
        /// @param x : number
        /// @param y : number
        /// @param bodyType : string
        /// @return Body
        methods.add_method(
            "newBody",
            |_, this, (x, y, bt): (f32, f32, String)| {
                let body_type = parse_body_type(&bt)?;
                let body = Body::new(x, y, body_type);
                let id = this.world.borrow_mut().add_body(body);
                Ok(LuaBody {
                    world: Rc::clone(&this.world),
                    id,
                })
            },
        );

        // -- newCircleBody --
        /// Creates a new circular body and adds it to the world.
        /// @param x : number
        /// @param y : number
        /// @param radius : number
        /// @param bodyType : string
        /// @return Body
        methods.add_method(
            "newCircleBody",
            |_, this, (x, y, radius, bt): (f32, f32, f32, String)| {
                let body_type = parse_body_type(&bt)?;
                let body = Body::new_circle(x, y, radius, body_type);
                let id = this.world.borrow_mut().add_body(body);
                Ok(LuaBody {
                    world: Rc::clone(&this.world),
                    id,
                })
            },
        );

        // -- newPolygonBody --
        /// Creates a new polygon body from a flat vertex table and adds it to the world.
        /// @param x : number
        /// @param y : number
        /// @param vertices : table
        /// @param bodyType : string
        /// @return Body
        methods.add_method(
            "newPolygonBody",
            |_, this, (x, y, tbl, bt): (f32, f32, LuaTable, String)| {
                let body_type = parse_body_type(&bt)?;
                let mut verts = Vec::new();
                let len = tbl.raw_len();
                let mut i = 1;
                while i < len {
                    let vx: f32 = tbl.raw_get(i)?;
                    let vy: f32 = tbl.raw_get(i + 1)?;
                    verts.push(Vec2::new(vx, vy));
                    i += 2;
                }
                let body = Body::new_polygon(x, y, verts, body_type);
                let id = this.world.borrow_mut().add_body(body);
                Ok(LuaBody {
                    world: Rc::clone(&this.world),
                    id,
                })
            },
        );

        // -- newEdgeBody --
        /// Creates a new edge (line segment) body and adds it to the world.
        /// @param x : number
        /// @param y : number
        /// @param x1 : number
        /// @param y1 : number
        /// @param x2 : number
        /// @param y2 : number
        /// @param bodyType : string
        /// @return Body
        #[allow(clippy::too_many_arguments)]
        methods.add_method(
            "newEdgeBody",
            |_, this, (x, y, x1, y1, x2, y2, bt): (f32, f32, f32, f32, f32, f32, String)| {
                let body_type = parse_body_type(&bt)?;
                let body =
                    Body::new_edge(x, y, Vec2::new(x1, y1), Vec2::new(x2, y2), body_type);
                let id = this.world.borrow_mut().add_body(body);
                Ok(LuaBody {
                    world: Rc::clone(&this.world),
                    id,
                })
            },
        );

        // -- newChainBody --
        /// Creates a new chain body from a flat vertex table and adds it to the world.
        /// @param x : number
        /// @param y : number
        /// @param vertices : table
        /// @param closed : boolean
        /// @param bodyType : string
        /// @return Body
        methods.add_method(
            "newChainBody",
            |_, this, (x, y, tbl, closed, bt): (f32, f32, LuaTable, bool, String)| {
                let body_type = parse_body_type(&bt)?;
                let mut verts = Vec::new();
                let len = tbl.raw_len();
                let mut i = 1;
                while i < len {
                    let vx: f32 = tbl.raw_get(i)?;
                    let vy: f32 = tbl.raw_get(i + 1)?;
                    verts.push(Vec2::new(vx, vy));
                    i += 2;
                }
                let body = Body::new_chain(x, y, verts, closed, body_type);
                let id = this.world.borrow_mut().add_body(body);
                Ok(LuaBody {
                    world: Rc::clone(&this.world),
                    id,
                })
            },
        );

        // -- addFixture --
        /// Adds an extra fixture (collider) to a body.
        /// @param bodyId : integer
        /// @param shapeType : string
        /// @param ... : varies
        /// @return integer
        methods.add_method(
            "addFixture",
            |lua,
             this,
             (body_id, shape_type, density, friction, restitution, sensor, args): (
                usize,
                String,
                f32,
                f32,
                f32,
                bool,
                LuaMultiValue,
            )| {
                let shape = shape_from_lua(lua, &shape_type, args)?;
                let idx = this
                    .world
                    .borrow_mut()
                    .add_fixture(body_id, shape, density, friction, restitution, sensor);
                Ok(idx)
            },
        );

        // -- fixtureCount --
        /// Returns the number of fixtures on a body.
        /// @param bodyId : integer
        /// @return integer
        methods.add_method("fixtureCount", |_, this, body_id: usize| {
            Ok(this.world.borrow().fixture_count(body_id))
        });

        // -- setFixtureFriction --
        /// Sets friction on a fixture by index.
        /// @param bodyId : integer
        /// @param fixtureIdx : integer
        /// @param friction : number
        methods.add_method(
            "setFixtureFriction",
            |_, this, (body_id, fix_idx, friction): (usize, usize, f32)| {
                this.world
                    .borrow_mut()
                    .set_fixture_friction(body_id, fix_idx, friction);
                Ok(())
            },
        );

        // -- setFixtureRestitution --
        /// Sets restitution on a fixture by index.
        /// @param bodyId : integer
        /// @param fixtureIdx : integer
        /// @param restitution : number
        methods.add_method(
            "setFixtureRestitution",
            |_, this, (body_id, fix_idx, restitution): (usize, usize, f32)| {
                this.world
                    .borrow_mut()
                    .set_fixture_restitution(body_id, fix_idx, restitution);
                Ok(())
            },
        );

        // -- setFixtureSensor --
        /// Sets whether a fixture is a sensor.
        /// @param bodyId : integer
        /// @param fixtureIdx : integer
        /// @param sensor : boolean
        methods.add_method(
            "setFixtureSensor",
            |_, this, (body_id, fix_idx, sensor): (usize, usize, bool)| {
                this.world
                    .borrow_mut()
                    .set_fixture_sensor(body_id, fix_idx, sensor);
                Ok(())
            },
        );

        // ── Joint creation ────────────────────────────────────────────────

        // -- addRevoluteJoint --
        /// Creates a revolute (pin) joint between two bodies.
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param anchorX : number
        /// @param anchorY : number
        /// @return integer
        methods.add_method(
            "addRevoluteJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_revolute_joint(a, b, ax, ay))
            },
        );

        // -- addDistanceJoint --
        /// Creates a distance joint between two bodies.
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param ax1 : number
        /// @param ay1 : number
        /// @param ax2 : number
        /// @param ay2 : number
        /// @param length : number
        /// @return integer
        #[allow(clippy::too_many_arguments)]
        methods.add_method(
            "addDistanceJoint",
            |_, this, (a, b, ax1, ay1, ax2, ay2, len): (usize, usize, f32, f32, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_distance_joint(a, b, ax1, ay1, ax2, ay2, len))
            },
        );

        // -- addPrismaticJoint --
        /// Creates a prismatic (slider) joint between two bodies.
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param anchorX : number
        /// @param anchorY : number
        /// @param axisX : number
        /// @param axisY : number
        /// @return integer
        methods.add_method(
            "addPrismaticJoint",
            |_, this, (a, b, ax, ay, axis_x, axis_y): (usize, usize, f32, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_prismatic_joint(a, b, ax, ay, axis_x, axis_y))
            },
        );

        // -- addWeldJoint --
        /// Creates a weld (rigid) joint between two bodies.
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param anchorX : number
        /// @param anchorY : number
        /// @return integer
        methods.add_method(
            "addWeldJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_weld_joint(a, b, ax, ay))
            },
        );

        // -- addRopeJoint --
        /// Creates a rope joint with a maximum distance.
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param ax1 : number
        /// @param ay1 : number
        /// @param ax2 : number
        /// @param ay2 : number
        /// @param maxLength : number
        /// @return integer
        #[allow(clippy::too_many_arguments)]
        methods.add_method(
            "addRopeJoint",
            |_, this, (a, b, ax1, ay1, ax2, ay2, max): (usize, usize, f32, f32, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_rope_joint(a, b, ax1, ay1, ax2, ay2, max))
            },
        );

        // -- addWheelJoint --
        /// Creates a wheel joint (prismatic + rotation).
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param anchorX : number
        /// @param anchorY : number
        /// @param axisX : number
        /// @param axisY : number
        /// @return integer
        methods.add_method(
            "addWheelJoint",
            |_, this, (a, b, ax, ay, axis_x, axis_y): (usize, usize, f32, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_wheel_joint(a, b, ax, ay, axis_x, axis_y))
            },
        );

        // -- addFrictionJoint --
        /// Creates a friction joint that resists relative motion.
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param anchorX : number
        /// @param anchorY : number
        /// @param maxForce : number
        /// @param maxTorque : number
        /// @return integer
        methods.add_method(
            "addFrictionJoint",
            |_, this, (a, b, ax, ay, max_f, max_t): (usize, usize, f32, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_friction_joint(a, b, ax, ay, max_f, max_t))
            },
        );

        // -- addMotorJoint --
        /// Creates a motor joint that drives body_b toward body_a.
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param correctionFactor : number
        /// @return integer
        methods.add_method(
            "addMotorJoint",
            |_, this, (a, b, factor): (usize, usize, f32)| {
                Ok(this.world.borrow_mut().add_motor_joint(a, b, factor))
            },
        );

        // -- addMouseJoint --
        /// Creates a mouse joint connecting a body to a target point.
        /// @param bodyId : integer
        /// @param targetX : number
        /// @param targetY : number
        /// @param maxForce : number
        /// @return integer
        methods.add_method(
            "addMouseJoint",
            |_, this, (body_id, tx, ty, max_f): (usize, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_mouse_joint(body_id, tx, ty, max_f))
            },
        );

        // -- addPulleyJoint --
        /// Creates a pulley joint (stub — falls back to weld joint).
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param anchorX : number
        /// @param anchorY : number
        /// @return integer
        methods.add_method(
            "addPulleyJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_pulley_joint(a, b, ax, ay))
            },
        );

        // -- addGearJoint --
        /// Creates a gear joint (stub — falls back to weld joint).
        /// @param bodyA : integer
        /// @param bodyB : integer
        /// @param anchorX : number
        /// @param anchorY : number
        /// @return integer
        methods.add_method(
            "addGearJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_gear_joint(a, b, ax, ay))
            },
        );

        // ── Joint management ──────────────────────────────────────────────

        // -- jointCount --
        /// Returns the total number of joints.
        /// @return integer
        methods.add_method("jointCount", |_, this, ()| {
            Ok(this.world.borrow().joint_count())
        });

        // -- getJointIds --
        /// Returns all joint IDs.
        /// @return table
        methods.add_method("getJointIds", |_, this, ()| {
            Ok(this.world.borrow().get_joint_ids())
        });

        // -- getJointBodies --
        /// Returns the two body IDs connected by a joint.
        /// @param jointId : integer
        /// @return integer, integer
        methods.add_method("getJointBodies", |_, this, jid: usize| {
            match this.world.borrow().get_joint_bodies(jid) {
                Some((a, b)) => Ok((a, b)),
                None => Err(LuaError::external(format!("invalid joint id: {}", jid))),
            }
        });

        // -- destroyJoint --
        /// Removes a joint from the world.
        /// @param jointId : integer
        /// @return nil
        methods.add_method("destroyJoint", |_, this, jid: usize| {
            this.world.borrow_mut().destroy_joint(jid);
            Ok(())
        });

        // -- getJointType --
        /// Returns the type name of a joint.
        /// @param jointId : integer
        /// @return string
        methods.add_method("getJointType", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_type(jid).to_string())
        });

        // -- setJointMotorSpeed --
        /// Sets the motor speed on a joint's angular axis.
        /// @param jointId : integer
        /// @param speed : number
        methods.add_method(
            "setJointMotorSpeed",
            |_, this, (jid, speed): (usize, f32)| {
                this.world.borrow_mut().set_joint_motor_speed(jid, speed);
                Ok(())
            },
        );

        // -- getJointMotorSpeed --
        /// Returns the motor speed on a joint's angular axis.
        /// @param jointId : integer
        /// @return number
        methods.add_method("getJointMotorSpeed", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_motor_speed(jid))
        });

        // -- setJointLimitsEnabled --
        /// Enables or disables angular limits on a joint.
        /// @param jointId : integer
        /// @param enabled : boolean
        methods.add_method(
            "setJointLimitsEnabled",
            |_, this, (jid, enabled): (usize, bool)| {
                this.world
                    .borrow_mut()
                    .set_joint_limits_enabled(jid, enabled);
                Ok(())
            },
        );

        // -- setJointLimits --
        /// Sets the angular limits on a joint.
        /// @param jointId : integer
        /// @param lower : number
        /// @param upper : number
        methods.add_method(
            "setJointLimits",
            |_, this, (jid, lower, upper): (usize, f32, f32)| {
                this.world.borrow_mut().set_joint_limits(jid, lower, upper);
                Ok(())
            },
        );

        // -- getJointLimits --
        /// Returns the angular limits on a joint.
        /// @param jointId : integer
        /// @return number, number
        methods.add_method("getJointLimits", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_limits(jid))
        });

        // -- setMouseJointTarget --
        /// Updates the target position of a mouse joint.
        /// @param jointId : integer
        /// @param x : number
        /// @param y : number
        methods.add_method(
            "setMouseJointTarget",
            |_, this, (jid, x, y): (usize, f32, f32)| {
                this.world.borrow_mut().set_mouse_joint_target(jid, x, y);
                Ok(())
            },
        );

        // ── Raycast and spatial queries ───────────────────────────────────

        // -- raycast --
        /// Casts a ray and returns the nearest hit, or nil.
        /// @param x1 : number
        /// @param y1 : number
        /// @param x2 : number
        /// @param y2 : number
        /// @return table|nil
        methods.add_method(
            "raycast",
            |lua, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
                match this.world.borrow().raycast(x1, y1, x2, y2) {
                    Some(hit) => Ok(LuaValue::Table(raycast_hit_to_table(lua, &hit)?)),
                    None => Ok(LuaValue::Nil),
                }
            },
        );

        // -- raycastClosest --
        /// Casts a ray and returns the closest hit using the query pipeline.
        /// @param x1 : number
        /// @param y1 : number
        /// @param dx : number
        /// @param dy : number
        /// @param maxDist : number
        /// @return table|nil
        methods.add_method(
            "raycastClosest",
            |lua, this, (x1, y1, dx, dy, max_dist): (f32, f32, f32, f32, f32)| {
                match this.world.borrow().raycast_closest(x1, y1, dx, dy, max_dist) {
                    Some(hit) => Ok(LuaValue::Table(raycast_hit_to_table(lua, &hit)?)),
                    None => Ok(LuaValue::Nil),
                }
            },
        );

        // -- raycastAll --
        /// Casts a ray and returns all hits.
        /// @param x1 : number
        /// @param y1 : number
        /// @param dx : number
        /// @param dy : number
        /// @param maxDist : number
        /// @return table
        methods.add_method(
            "raycastAll",
            |lua, this, (x1, y1, dx, dy, max_dist): (f32, f32, f32, f32, f32)| {
                let hits = this.world.borrow().raycast_all(x1, y1, dx, dy, max_dist);
                let result = lua.create_table()?;
                for (i, hit) in hits.iter().enumerate() {
                    result.set(i + 1, raycast_hit_to_table(lua, hit)?)?;
                }
                Ok(result)
            },
        );

        // -- queryAABB --
        /// Returns body IDs within an axis-aligned bounding box.
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        /// @return table
        methods.add_method(
            "queryAABB",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                Ok(this.world.borrow().query_aabb(x, y, w, h))
            },
        );

        // -- getBodyAtPoint --
        /// Returns the body ID at a world-space point, or nil.
        /// @param x : number
        /// @param y : number
        /// @return integer|nil
        methods.add_method("getBodyAtPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.world.borrow().get_body_at_point(x, y))
        });

        // ── Collision events ──────────────────────────────────────────────

        // -- getCollisionEvents --
        /// Returns collision events from the last step.
        /// @return table
        methods.add_method("getCollisionEvents", |lua, this, ()| {
            let w = this.world.borrow();
            let events = w.get_collision_events();
            let result = lua.create_table()?;
            for (i, evt) in events.iter().enumerate() {
                let tbl = lua.create_table()?;
                tbl.set("bodyA", evt.body_a)?;
                tbl.set("bodyB", evt.body_b)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });

        // -- getBeginContactEvents --
        /// Returns begin-contact events from the last step.
        /// @return table
        methods.add_method("getBeginContactEvents", |lua, this, ()| {
            let w = this.world.borrow();
            let events = w.get_begin_contact_events();
            let result = lua.create_table()?;
            for (i, (a, b)) in events.iter().enumerate() {
                let tbl = lua.create_table()?;
                tbl.set("bodyA", *a)?;
                tbl.set("bodyB", *b)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });

        // -- getEndContactEvents --
        /// Returns end-contact events from the last step.
        /// @return table
        methods.add_method("getEndContactEvents", |lua, this, ()| {
            let w = this.world.borrow();
            let events = w.get_end_contact_events();
            let result = lua.create_table()?;
            for (i, (a, b)) in events.iter().enumerate() {
                let tbl = lua.create_table()?;
                tbl.set("bodyA", *a)?;
                tbl.set("bodyB", *b)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });

        // -- getContacts --
        /// Returns all contact pairs from the narrow phase.
        /// @return table
        methods.add_method("getContacts", |lua, this, ()| {
            let contacts = this.world.borrow().get_contacts();
            let result = lua.create_table()?;
            for (i, c) in contacts.iter().enumerate() {
                let tbl = lua.create_table()?;
                tbl.set("bodyA", c.body_a)?;
                tbl.set("bodyB", c.body_b)?;
                tbl.set("normalX", c.normal_x)?;
                tbl.set("normalY", c.normal_y)?;
                tbl.set("isTouching", c.is_touching)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });

        // -- getBodyContacts --
        /// Returns contacts involving a specific body.
        /// @param bodyId : integer
        /// @return table
        methods.add_method("getBodyContacts", |lua, this, body_id: usize| {
            let contacts = this.world.borrow().get_body_contacts(body_id);
            let result = lua.create_table()?;
            for (i, c) in contacts.iter().enumerate() {
                let tbl = lua.create_table()?;
                tbl.set("bodyA", c.body_a)?;
                tbl.set("bodyB", c.body_b)?;
                tbl.set("normalX", c.normal_x)?;
                tbl.set("normalY", c.normal_y)?;
                tbl.set("isTouching", c.is_touching)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });

        // -- setBodyType --
        /// Changes the body type.
        /// @param bodyId : integer
        /// @param bodyType : string
        methods.add_method(
            "setBodyType",
            |_, this, (id, bt): (usize, String)| {
                let body_type = parse_body_type(&bt)?;
                this.world.borrow_mut().set_body_type(id, body_type);
                Ok(())
            },
        );

        // -- getBodyType --
        /// Returns the body type as a string.
        /// @param bodyId : integer
        /// @return string
        methods.add_method("getBodyType", |_, this, id: usize| {
            Ok(this.world.borrow().get_body_type_str(id).to_string())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaBody UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a physics body accessed through its world.
#[derive(Clone)]
pub struct LuaBody {
    world: Rc<RefCell<World>>,
    id: usize,
}

impl LuaUserData for LuaBody {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getId --
        /// Returns the body's integer ID.
        /// @return integer
        methods.add_method("getId", |_, this, ()| Ok(this.id));

        // -- getPosition --
        /// Returns the body position (x, y).
        /// @return number, number
        methods.add_method("getPosition", |_, this, ()| {
            let w = this.world.borrow();
            match w.get_body(this.id) {
                Some(b) => Ok((b.position.x, b.position.y)),
                None => Ok((0.0, 0.0)),
            }
        });

        // -- setPosition --
        /// Sets the body position.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            this.world.borrow_mut().set_body_position(this.id, x, y);
            Ok(())
        });

        // -- getX --
        /// Returns the body X position.
        /// @return number
        methods.add_method("getX", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.position.x))
        });

        // -- getY --
        /// Returns the body Y position.
        /// @return number
        methods.add_method("getY", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.position.y))
        });

        // -- getVelocity --
        /// Returns the body velocity (vx, vy).
        /// @return number, number
        methods.add_method("getVelocity", |_, this, ()| {
            let w = this.world.borrow();
            match w.get_body(this.id) {
                Some(b) => Ok((b.velocity.x, b.velocity.y)),
                None => Ok((0.0, 0.0)),
            }
        });

        // -- setVelocity --
        /// Sets the body velocity.
        /// @param vx : number
        /// @param vy : number
        /// @return nil
        methods.add_method("setVelocity", |_, this, (vx, vy): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.velocity.x = vx;
                b.velocity.y = vy;
            }
            Ok(())
        });

        // -- getAngle --
        /// Returns the body angle in radians.
        /// @return number
        methods.add_method("getAngle", |_, this, ()| {
            Ok(this.world.borrow().get_body_angle(this.id))
        });

        // -- setAngle --
        /// Sets the body angle in radians.
        /// @param angle : number
        /// @return nil
        methods.add_method("setAngle", |_, this, angle: f32| {
            this.world.borrow_mut().set_body_angle(this.id, angle);
            Ok(())
        });

        // -- getAngularVelocity --
        /// Returns the angular velocity in radians/s.
        /// @return number
        methods.add_method("getAngularVelocity", |_, this, ()| {
            Ok(this.world.borrow().get_angular_velocity(this.id))
        });

        // -- setAngularVelocity --
        /// Sets the angular velocity.
        /// @param omega : number
        /// @return nil
        methods.add_method("setAngularVelocity", |_, this, omega: f32| {
            this.world
                .borrow_mut()
                .set_angular_velocity(this.id, omega);
            Ok(())
        });

        // -- getMass --
        /// Returns the body mass.
        /// @return number
        methods.add_method("getMass", |_, this, ()| {
            Ok(this.world.borrow().get_body_mass(this.id))
        });

        // -- setMass --
        /// Sets the body mass.
        /// @param mass : number
        /// @return nil
        methods.add_method("setMass", |_, this, mass: f32| {
            this.world.borrow_mut().set_body_mass(this.id, mass);
            Ok(())
        });

        // -- getType --
        /// Returns the body type as a string.
        /// @return string
        methods.add_method("getType", |_, this, ()| {
            Ok(this
                .world
                .borrow()
                .get_body_type_str(this.id)
                .to_string())
        });

        // -- setType --
        /// Sets the body type.
        /// @param bodyType : string
        /// @return nil
        methods.add_method("setType", |_, this, bt: String| {
            let body_type = parse_body_type(&bt)?;
            this.world.borrow_mut().set_body_type(this.id, body_type);
            Ok(())
        });

        // -- getWidth --
        /// Returns the body width.
        /// @return number
        methods.add_method("getWidth", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.width))
        });

        // -- getHeight --
        /// Returns the body height.
        /// @return number
        methods.add_method("getHeight", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.height))
        });

        // -- getFriction --
        /// Returns the body friction coefficient.
        /// @return number
        methods.add_method("getFriction", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.5, |b| b.friction))
        });

        // -- setFriction --
        /// Sets the body friction coefficient.
        /// @param friction : number
        /// @return nil
        methods.add_method("setFriction", |_, this, friction: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.friction = friction;
            }
            Ok(())
        });

        // -- getRestitution --
        /// Returns the body restitution (bounciness).
        /// @return number
        methods.add_method("getRestitution", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.3, |b| b.restitution))
        });

        // -- setRestitution --
        /// Sets the body restitution (bounciness).
        /// @param restitution : number
        /// @return nil
        methods.add_method("setRestitution", |_, this, restitution: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.restitution = restitution;
            }
            Ok(())
        });

        // -- getLayer --
        /// Returns the collision layer bitmask.
        /// @return integer
        methods.add_method("getLayer", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(1u32, |b| b.layer))
        });

        // -- setLayer --
        /// Sets the collision layer bitmask.
        /// @param layer : integer
        /// @return nil
        methods.add_method("setLayer", |_, this, layer: u32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.layer = layer;
            }
            Ok(())
        });

        // -- getMask --
        /// Returns the collision mask bitmask.
        /// @return integer
        methods.add_method("getMask", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(1u32, |b| b.mask))
        });

        // -- setMask --
        /// Sets the collision mask bitmask.
        /// @param mask : integer
        /// @return nil
        methods.add_method("setMask", |_, this, mask: u32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.mask = mask;
            }
            Ok(())
        });

        // -- applyImpulse --
        /// Applies a linear impulse to the body.
        /// @param ix : number
        /// @param iy : number
        /// @return nil
        methods.add_method("applyImpulse", |_, this, (ix, iy): (f32, f32)| {
            this.world.borrow_mut().apply_impulse(this.id, ix, iy);
            Ok(())
        });

        // -- applyForce --
        /// Applies a continuous force to the body.
        /// @param fx : number
        /// @param fy : number
        /// @return nil
        methods.add_method("applyForce", |_, this, (fx, fy): (f32, f32)| {
            this.world.borrow_mut().apply_force(this.id, fx, fy);
            Ok(())
        });

        // -- applyTorque --
        /// Applies a torque (rotational force).
        /// @param torque : number
        /// @return nil
        methods.add_method("applyTorque", |_, this, torque: f32| {
            this.world.borrow_mut().apply_torque(this.id, torque);
            Ok(())
        });

        // -- applyForceAtPoint --
        /// Applies a force at a specific world-space point.
        /// @param fx : number
        /// @param fy : number
        /// @param px : number
        /// @param py : number
        methods.add_method(
            "applyForceAtPoint",
            |_, this, (fx, fy, px, py): (f32, f32, f32, f32)| {
                this.world
                    .borrow_mut()
                    .apply_force_at_point(this.id, fx, fy, px, py);
                Ok(())
            },
        );

        // -- applyAngularImpulse --
        /// Applies an angular impulse.
        /// @param impulse : number
        /// @return nil
        methods.add_method("applyAngularImpulse", |_, this, impulse: f32| {
            this.world
                .borrow_mut()
                .apply_angular_impulse(this.id, impulse);
            Ok(())
        });

        // -- getGravityScale --
        /// Returns the per-body gravity multiplier.
        /// @return number
        methods.add_method("getGravityScale", |_, this, ()| {
            Ok(this.world.borrow().get_gravity_scale(this.id))
        });

        // -- setGravityScale --
        /// Sets the per-body gravity multiplier.
        /// @param scale : number
        /// @return nil
        methods.add_method("setGravityScale", |_, this, scale: f32| {
            this.world
                .borrow_mut()
                .set_gravity_scale(this.id, scale);
            Ok(())
        });

        // -- isFixedRotation --
        /// Returns whether rotation is locked.
        /// @return boolean
        methods.add_method("isFixedRotation", |_, this, ()| {
            Ok(this.world.borrow().is_fixed_rotation(this.id))
        });

        // -- setFixedRotation --
        /// Locks or unlocks rotation.
        /// @param fixed : boolean
        /// @return nil
        methods.add_method("setFixedRotation", |_, this, fixed: bool| {
            this.world
                .borrow_mut()
                .set_fixed_rotation(this.id, fixed);
            Ok(())
        });

        // -- getLinearDamping --
        /// Returns the linear damping coefficient.
        /// @return number
        methods.add_method("getLinearDamping", |_, this, ()| {
            Ok(this.world.borrow().get_linear_damping(this.id))
        });

        // -- setLinearDamping --
        /// Sets the linear damping coefficient.
        /// @param damping : number
        /// @return nil
        methods.add_method("setLinearDamping", |_, this, damping: f32| {
            this.world
                .borrow_mut()
                .set_linear_damping(this.id, damping);
            Ok(())
        });

        // -- getAngularDamping --
        /// Returns the angular damping coefficient.
        /// @return number
        methods.add_method("getAngularDamping", |_, this, ()| {
            Ok(this.world.borrow().get_angular_damping(this.id))
        });

        // -- setAngularDamping --
        /// Sets the angular damping coefficient.
        /// @param damping : number
        /// @return nil
        methods.add_method("setAngularDamping", |_, this, damping: f32| {
            this.world
                .borrow_mut()
                .set_angular_damping(this.id, damping);
            Ok(())
        });

        // -- isBullet --
        /// Returns whether CCD is enabled.
        /// @return boolean
        methods.add_method("isBullet", |_, this, ()| {
            Ok(this.world.borrow().is_bullet(this.id))
        });

        // -- setBullet --
        /// Enables or disables CCD.
        /// @param bullet : boolean
        /// @return nil
        methods.add_method("setBullet", |_, this, bullet: bool| {
            this.world.borrow_mut().set_bullet(this.id, bullet);
            Ok(())
        });

        // -- isSleepingAllowed --
        /// Returns whether the body can sleep.
        /// @return boolean
        methods.add_method("isSleepingAllowed", |_, this, ()| {
            Ok(this.world.borrow().is_sleeping_allowed(this.id))
        });

        // -- setSleepingAllowed --
        /// Sets whether the body can sleep.
        /// @param allowed : boolean
        /// @return nil
        methods.add_method("setSleepingAllowed", |_, this, allowed: bool| {
            this.world
                .borrow_mut()
                .set_sleeping_allowed(this.id, allowed);
            Ok(())
        });

        // -- destroy --
        /// Removes this body from the world.
        /// @return nil
        methods.add_method("destroy", |_, this, ()| {
            this.world.borrow_mut().destroy_body(this.id);
            Ok(())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaPhysicsShape UserData
// -------------------------------------------------------------------------------

/// Internal data for a standalone Lua physics shape.
struct LuaPhysicsShapeData {
    shape: Shape,
    density: f32,
    friction: f32,
    restitution: f32,
    sensor: bool,
}

/// Lua-side standalone shape object (circle, rectangle, edge, polygon, chain).
///
/// Created via `luna.physics.newCircleShape`, `newRectangleShape`, etc.
/// Attach to a body with `luna.physics.attachShape(body, shape)`.
#[derive(Clone)]
pub struct LuaPhysicsShape {
    inner: Rc<RefCell<LuaPhysicsShapeData>>,
}

impl LuaPhysicsShape {
    fn new(shape: Shape) -> Self {
        Self {
            inner: Rc::new(RefCell::new(LuaPhysicsShapeData {
                shape,
                density: 1.0,
                friction: 0.2,
                restitution: 0.0,
                sensor: false,
            })),
        }
    }
}

impl LuaUserData for LuaPhysicsShape {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getType --
        /// Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
        /// @return string
        methods.add_method("getType", |_, this, ()| {
            let name = match this.inner.borrow().shape {
                Shape::Circle { .. } => "circle",
                Shape::Rect { .. } => "rectangle",
                Shape::Polygon { .. } => "polygon",
                Shape::Edge { .. } => "edge",
                Shape::Chain { .. } => "chain",
            };
            Ok(name)
        });

        // -- getRadius --
        /// Returns the radius. Only valid for circle shapes.
        /// @return number
        methods.add_method("getRadius", |_, this, ()| {
            match this.inner.borrow().shape {
                Shape::Circle { radius } => Ok(radius),
                _ => Err(LuaError::RuntimeError(
                    "getRadius: shape is not a circle".to_string(),
                )),
            }
        });

        // -- getBoundingBox --
        /// Returns the axis-aligned bounding box (x1, y1, x2, y2).
        /// @return number, number, number, number
        methods.add_method("getBoundingBox", |_, this, ()| {
            let d = this.inner.borrow();
            let (x1, y1, x2, y2) = match &d.shape {
                Shape::Circle { radius } => (-radius, -radius, *radius, *radius),
                Shape::Rect { width, height } => {
                    (-width / 2.0, -height / 2.0, *width / 2.0, *height / 2.0)
                }
                Shape::Edge { v1, v2 } => (
                    v1.x.min(v2.x),
                    v1.y.min(v2.y),
                    v1.x.max(v2.x),
                    v1.y.max(v2.y),
                ),
                Shape::Polygon { vertices } | Shape::Chain { vertices, .. } => {
                    let mut min_x = f32::INFINITY;
                    let mut min_y = f32::INFINITY;
                    let mut max_x = f32::NEG_INFINITY;
                    let mut max_y = f32::NEG_INFINITY;
                    for v in vertices {
                        min_x = min_x.min(v.x);
                        min_y = min_y.min(v.y);
                        max_x = max_x.max(v.x);
                        max_y = max_y.max(v.y);
                    }
                    (min_x, min_y, max_x, max_y)
                }
            };
            Ok((x1, y1, x2, y2))
        });

        // -- setDensity --
        /// Sets the density for this shape (used when attaching to a body).
        /// @param density : number
        /// @return nil
        methods.add_method("setDensity", |_, this, density: f32| {
            this.inner.borrow_mut().density = density;
            Ok(())
        });

        // -- setFriction --
        /// Sets the friction coefficient.
        /// @param friction : number
        /// @return nil
        methods.add_method("setFriction", |_, this, friction: f32| {
            this.inner.borrow_mut().friction = friction;
            Ok(())
        });

        // -- setRestitution --
        /// Sets the restitution (bounciness) coefficient.
        /// @param restitution : number
        /// @return nil
        methods.add_method("setRestitution", |_, this, restitution: f32| {
            this.inner.borrow_mut().restitution = restitution;
            Ok(())
        });

        // -- setSensor --
        /// Sets whether this shape is a sensor (non-colliding trigger).
        /// @param sensor : boolean
        /// @return nil
        methods.add_method("setSensor", |_, this, sensor: bool| {
            this.inner.borrow_mut().sensor = sensor;
            Ok(())
        });

        // -- destroy --
        /// Releases this shape handle (GC handles cleanup).
        /// @return nil
        methods.add_method("destroy", |_, _this, ()| Ok(()));
    }
}

// -------------------------------------------------------------------------------
// Registration
// -------------------------------------------------------------------------------

/// Registers the `luna.physics` API namespace.
///
/// # Parameters
/// - `lua` — `&Lua`. The Lua VM.
/// - `luna` — `&LuaTable`. The top-level `luna` table to register into.
/// - `state` — `Rc<RefCell<SharedState>>`. Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newWorld --
    /// Creates a new physics world with the given gravity vector.
    /// @param gx : number
    /// @param gy : number
    /// @return World
    tbl.set(
        "newWorld",
        lua.create_function(|_, (gx, gy): (f32, f32)| {
            Ok(LuaWorld {
                world: Rc::new(RefCell::new(World::new(gx, gy))),
            })
        })?,
    )?;

    // -- step -- (flat wrapper)
    /// Advances the physics world by dt seconds.
    /// @param world : World
    /// @param dt : number
    /// @return nil
    tbl.set(
        "step",
        lua.create_function(|_, (world_ud, dt): (LuaAnyUserData, f32)| {
            let world = world_ud.borrow::<LuaWorld>()?;
            world.world.borrow_mut().step(dt);
            Ok(())
        })?,
    )?;

    // -- destroyWorld -- (flat wrapper)
    /// Marks a physics world for destruction. Subsequent operations on the world
    /// will be no-ops or return gracefully.
    /// @param world : World
    /// @return nil
    tbl.set(
        "destroyWorld",
        lua.create_function(|_, _world_ud: LuaAnyUserData| {
            // No-op: the world is garbage-collected when all references drop.
            Ok(())
        })?,
    )?;

    // -- newBody -- (flat wrapper)
    /// Creates a new rectangular body in the given world.
    /// @param world : World
    /// @param x : number
    /// @param y : number
    /// @param bodyType : string
    /// @return Body
    tbl.set(
        "newBody",
        lua.create_function(
            |_, (world_ud, x, y, bt): (LuaAnyUserData, f32, f32, String)| {
                let world = world_ud.borrow::<LuaWorld>()?;
                let body_type = parse_body_type_lenient(&bt);
                let body = Body::new(x, y, body_type);
                let id = world.world.borrow_mut().add_body(body);
                Ok(LuaBody {
                    world: Rc::clone(&world.world),
                    id,
                })
            },
        )?,
    )?;

    // -- getBody -- (flat)
    /// Returns the position and velocity of a body (x, y, vx, vy).
    /// @param world : World  (kept for API symmetry; body already holds the world ref)
    /// @param body : Body
    /// @return number, number, number, number
    tbl.set(
        "getBody",
        lua.create_function(|_, (_world_ud, body_ud): (LuaAnyUserData, LuaAnyUserData)| {
            let body = body_ud.borrow::<LuaBody>()?;
            let w = body.world.borrow();
            let (x, y) = w
                .get_body(body.id)
                .map_or((0.0_f32, 0.0_f32), |b| (b.position.x, b.position.y));
            let (vx, vy) = w
                .get_body(body.id)
                .map_or((0.0_f32, 0.0_f32), |b| (b.velocity.x, b.velocity.y));
            Ok((x, y, vx, vy))
        })?,
    )?;

    // -- setBodyVelocity -- (flat)
    /// Sets the velocity of a body.
    /// @param world : World  (kept for API symmetry)
    /// @param body : Body
    /// @param vx : number
    /// @param vy : number
    /// @return nil
    tbl.set(
        "setBodyVelocity",
        lua.create_function(
            |_, (_world_ud, body_ud, vx, vy): (LuaAnyUserData, LuaAnyUserData, f32, f32)| {
                let body = body_ud.borrow::<LuaBody>()?;
                let mut w = body.world.borrow_mut();
                if let Some(b) = w.get_body_mut(body.id) {
                    b.velocity.x = vx;
                    b.velocity.y = vy;
                }
                Ok(())
            },
        )?,
    )?;

    // -- isSleepingAllowed -- (flat)
    /// Returns whether the body is allowed to sleep.
    /// @param world : World  (kept for API symmetry)
    /// @param body : Body
    /// @return boolean
    tbl.set(
        "isSleepingAllowed",
        lua.create_function(|_, (_world_ud, body_ud): (LuaAnyUserData, LuaAnyUserData)| {
            let body = body_ud.borrow::<LuaBody>()?;
            let allowed = body.world.borrow().is_sleeping_allowed(body.id);
            Ok(allowed)
        })?,
    )?;

    // -- setSleepingAllowed -- (flat)
    /// Sets whether the body is allowed to sleep.
    /// @param world : World  (kept for API symmetry)
    /// @param body : Body
    /// @param allowed : boolean
    /// @return nil
    tbl.set(
        "setSleepingAllowed",
        lua.create_function(
            |_, (_world_ud, body_ud, allowed): (LuaAnyUserData, LuaAnyUserData, bool)| {
                let body = body_ud.borrow::<LuaBody>()?;
                body.world
                    .borrow_mut()
                    .set_sleeping_allowed(body.id, allowed);
                Ok(())
            },
        )?,
    )?;

    // -- newRectangleShape --
    /// Creates a rectangle shape userdata.
    /// @param width : number
    /// @param height : number
    /// @return Shape
    tbl.set(
        "newRectangleShape",
        lua.create_function(|_, (w, h): (f32, f32)| {
            Ok(LuaPhysicsShape::new(Shape::Rect {
                width: w,
                height: h,
            }))
        })?,
    )?;

    // -- newCircleShape --
    /// Creates a circle shape userdata.
    /// @param radius : number
    /// @return Shape
    tbl.set(
        "newCircleShape",
        lua.create_function(|_, r: f32| Ok(LuaPhysicsShape::new(Shape::Circle { radius: r })))?,
    )?;

    // -- newEdgeShape --
    /// Creates an edge (line segment) shape userdata.
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @return Shape
    tbl.set(
        "newEdgeShape",
        lua.create_function(|_, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            Ok(LuaPhysicsShape::new(Shape::Edge {
                v1: crate::math::Vec2::new(x1, y1),
                v2: crate::math::Vec2::new(x2, y2),
            }))
        })?,
    )?;

    // -- newPolygonShape --
    /// Creates a convex polygon shape userdata from flat variadic vertex pairs.
    /// Requires at least 3 vertices (6 numbers).
    /// @param x1 y1 x2 y2 x3 y3 ... : numbers
    /// @return Shape
    tbl.set(
        "newPolygonShape",
        lua.create_function(|_, coords: mlua::Variadic<f32>| {
            if coords.len() < 6 || !coords.len().is_multiple_of(2) {
                return Err(LuaError::RuntimeError(
                    "newPolygonShape: requires at least 3 vertex pairs (6 numbers)".to_string(),
                ));
            }
            let vertices: Vec<crate::math::Vec2> = coords
                .chunks(2)
                .map(|c| crate::math::Vec2::new(c[0], c[1]))
                .collect();
            Ok(LuaPhysicsShape::new(Shape::Polygon { vertices }))
        })?,
    )?;

    // -- newChainShape --
    /// Creates a chain shape userdata from flat variadic vertex pairs.
    /// @param closed : boolean  whether the chain closes back to start
    /// @param x1 y1 x2 y2 ... : numbers  (at least 2 pairs)
    /// @return Shape
    tbl.set(
        "newChainShape",
        lua.create_function(|_, (closed, coords): (bool, mlua::Variadic<f32>)| {
            if coords.len() < 4 || coords.len() % 2 != 0 {
                return Err(LuaError::RuntimeError(
                    "newChainShape: requires at least 2 vertex pairs (4 numbers)".to_string(),
                ));
            }
            let vertices: Vec<crate::math::Vec2> = coords
                .chunks(2)
                .map(|c| crate::math::Vec2::new(c[0], c[1]))
                .collect();
            Ok(LuaPhysicsShape::new(Shape::Chain { vertices, closed }))
        })?,
    )?;

    // -- attachShape --
    /// Attaches a standalone shape to a body as an additional fixture.
    /// @param body : Body
    /// @param shape : Shape
    /// @return nil
    tbl.set(
        "attachShape",
        lua.create_function(|_, (body_ud, shape_ud): (LuaAnyUserData, LuaAnyUserData)| {
            let body = body_ud.borrow::<LuaBody>()?;
            let shape_lua = shape_ud.borrow::<LuaPhysicsShape>()?;
            let d = shape_lua.inner.borrow();
            body.world.borrow_mut().add_fixture(
                body.id,
                d.shape.clone(),
                d.density,
                d.friction,
                d.restitution,
                d.sensor,
            );
            Ok(())
        })?,
    )?;

    // -- getCollisions --
    /// Returns all collision events from the last simulation step.
    /// Each entry is a table with keys: body_a, body_b.
    /// @param world : World
    /// @return table
    tbl.set(
        "getCollisions",
        lua.create_function(|lua, world_ud: LuaAnyUserData| {
            let world_lua = world_ud.borrow::<LuaWorld>()?;
            let world = world_lua.world.borrow();
            let events = world.get_collision_events();
            let tbl = lua.create_table()?;
            for (i, contact) in events.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("body_a", contact.body_a)?;
                entry.set("body_b", contact.body_b)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;

    luna.set("physics", tbl)?;
    Ok(())
}
