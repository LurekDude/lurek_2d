use super::SharedState;
use crate::math::Vec2;
use crate::physics::{
    Body, BodyType, CellType, CellularWorld, PhysicsZone, RaycastHit, Shape, TerrainMap, World,
};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
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
fn parse_body_type_lenient(s: &str) -> BodyType {
    match s {
        "static" => BodyType::Static,
        "kinematic" => BodyType::Kinematic,
        "sensor" => BodyType::Sensor,
        _ => BodyType::Dynamic,
    }
}
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
#[derive(Clone)]
pub struct LuaWorld {
    world: Rc<RefCell<World>>,
    begin_contact_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    end_contact_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    body_data: Rc<RefCell<HashMap<usize, LuaRegistryKey>>>,
}
impl LuaWorld {
    pub(crate) fn world_handle(&self) -> Rc<RefCell<World>> {
        self.world.clone()
    }
}
impl LuaUserData for LuaWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method(
            "drawDebug",
            |_,
             this,
             (target, r, g, b, a): (
                mlua::AnyUserData,
                Option<u8>,
                Option<u8>,
                Option<u8>,
                Option<u8>,
            )| {
                let mut target_ref =
                    target.borrow_mut::<crate::lua_api::render_api::LuaImageData>()?;
                this.world.borrow().draw_debug_to_image(
                    &mut target_ref.inner,
                    r.unwrap_or(0),
                    g.unwrap_or(255),
                    b.unwrap_or(0),
                    a.unwrap_or(255),
                );
                Ok(())
            },
        );
        methods.add_method("step", |lua, this, dt: f32| {
            this.world.borrow_mut().step(dt);
            let begins: Vec<(usize, usize)> =
                this.world.borrow().get_begin_contact_events().to_vec();
            let ends: Vec<(usize, usize)> = this.world.borrow().get_end_contact_events().to_vec();
            if let Some(key) = &*this.begin_contact_key.borrow() {
                let cb: LuaFunction = lua.registry_value(key)?;
                for (a, b) in begins {
                    cb.call::<_, ()>((a, b))?;
                }
            }
            if let Some(key) = &*this.end_contact_key.borrow() {
                let cb: LuaFunction = lua.registry_value(key)?;
                for (a, b) in ends {
                    cb.call::<_, ()>((a, b))?;
                }
            }
            Ok(())
        });
        methods.add_method("clear", |_, this, ()| {
            this.world.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("getGravity", |_, this, ()| {
            Ok(this.world.borrow().get_gravity())
        });
        methods.add_method("setGravity", |_, this, (gx, gy): (f32, f32)| {
            this.world.borrow_mut().set_gravity(gx, gy);
            Ok(())
        });
        methods.add_method("setMeter", |_, this, ppm: f32| {
            this.world.borrow_mut().set_meter(ppm);
            Ok(())
        });
        methods.add_method("getMeter", |_, this, ()| {
            Ok(this.world.borrow().get_meter())
        });
        methods.add_method("toPhysics", |_, this, px: f32| {
            Ok(this.world.borrow().to_physics(px))
        });
        methods.add_method("toPixels", |_, this, m: f32| {
            Ok(this.world.borrow().to_pixels(m))
        });
        methods.add_method("getBodyCount", |_, this, ()| {
            Ok(this.world.borrow().body_count())
        });
        methods.add_method("getBodyIds", |_, this, ()| {
            Ok(this.world.borrow().get_body_ids())
        });
        methods.add_method("destroyBody", |_, this, id: usize| {
            this.world.borrow_mut().destroy_body(id);
            Ok(())
        });
        methods.add_method("newBody", |_, this, (x, y, bt): (f32, f32, String)| {
            let body_type = parse_body_type(&bt)?;
            let body = Body::new(x, y, body_type);
            let id = this.world.borrow_mut().add_body(body);
            Ok(LuaBody {
                world: Rc::clone(&this.world),
                id,
            })
        });
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
        #[allow(clippy::too_many_arguments)]
        methods.add_method(
            "newEdgeBody",
            |_, this, (x, y, x1, y1, x2, y2, bt): (f32, f32, f32, f32, f32, f32, String)| {
                let body_type = parse_body_type(&bt)?;
                let body = Body::new_edge(x, y, Vec2::new(x1, y1), Vec2::new(x2, y2), body_type);
                let id = this.world.borrow_mut().add_body(body);
                Ok(LuaBody {
                    world: Rc::clone(&this.world),
                    id,
                })
            },
        );
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
                let idx = this.world.borrow_mut().add_fixture(
                    body_id,
                    shape,
                    density,
                    friction,
                    restitution,
                    sensor,
                );
                Ok(idx)
            },
        );
        methods.add_method("fixtureCount", |_, this, body_id: usize| {
            Ok(this.world.borrow().fixture_count(body_id))
        });
        methods.add_method(
            "setFixtureFriction",
            |_, this, (body_id, fix_idx, friction): (usize, usize, f32)| {
                this.world
                    .borrow_mut()
                    .set_fixture_friction(body_id, fix_idx, friction);
                Ok(())
            },
        );
        methods.add_method(
            "setFixtureRestitution",
            |_, this, (body_id, fix_idx, restitution): (usize, usize, f32)| {
                this.world
                    .borrow_mut()
                    .set_fixture_restitution(body_id, fix_idx, restitution);
                Ok(())
            },
        );
        methods.add_method(
            "setFixtureSensor",
            |_, this, (body_id, fix_idx, sensor): (usize, usize, bool)| {
                this.world
                    .borrow_mut()
                    .set_fixture_sensor(body_id, fix_idx, sensor);
                Ok(())
            },
        );
        methods.add_method(
            "addRevoluteJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_revolute_joint(a, b, ax, ay))
            },
        );
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
        methods.add_method(
            "addPrismaticJoint",
            |_, this, (a, b, ax, ay, axis_x, axis_y): (usize, usize, f32, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_prismatic_joint(a, b, ax, ay, axis_x, axis_y))
            },
        );
        methods.add_method(
            "addWeldJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_weld_joint(a, b, ax, ay))
            },
        );
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
        methods.add_method(
            "addWheelJoint",
            |_, this, (a, b, ax, ay, axis_x, axis_y): (usize, usize, f32, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_wheel_joint(a, b, ax, ay, axis_x, axis_y))
            },
        );
        methods.add_method(
            "addFrictionJoint",
            |_, this, (a, b, ax, ay, max_f, max_t): (usize, usize, f32, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_friction_joint(a, b, ax, ay, max_f, max_t))
            },
        );
        methods.add_method(
            "addMotorJoint",
            |_, this, (a, b, factor): (usize, usize, f32)| {
                Ok(this.world.borrow_mut().add_motor_joint(a, b, factor))
            },
        );
        methods.add_method(
            "addMouseJoint",
            |_, this, (body_id, tx, ty, max_f): (usize, f32, f32, f32)| {
                Ok(this
                    .world
                    .borrow_mut()
                    .add_mouse_joint(body_id, tx, ty, max_f))
            },
        );
        methods.add_method(
            "addPulleyJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_pulley_joint(a, b, ax, ay))
            },
        );
        methods.add_method(
            "addGearJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_gear_joint(a, b, ax, ay))
            },
        );
        methods.add_method("jointCount", |_, this, ()| {
            Ok(this.world.borrow().joint_count())
        });
        methods.add_method("getJointIds", |_, this, ()| {
            Ok(this.world.borrow().get_joint_ids())
        });
        methods.add_method("getJointBodies", |_, this, jid: usize| {
            match this.world.borrow().get_joint_bodies(jid) {
                Some((a, b)) => Ok((a, b)),
                None => Err(LuaError::external(format!("invalid joint id: {}", jid))),
            }
        });
        methods.add_method("destroyJoint", |_, this, jid: usize| {
            this.world.borrow_mut().destroy_joint(jid);
            Ok(())
        });
        methods.add_method("getJointType", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_type(jid).to_string())
        });
        methods.add_method(
            "setJointMotorSpeed",
            |_, this, (jid, speed): (usize, f32)| {
                this.world.borrow_mut().set_joint_motor_speed(jid, speed);
                Ok(())
            },
        );
        methods.add_method("getJointMotorSpeed", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_motor_speed(jid))
        });
        methods.add_method(
            "setJointLimitsEnabled",
            |_, this, (jid, enabled): (usize, bool)| {
                this.world
                    .borrow_mut()
                    .set_joint_limits_enabled(jid, enabled);
                Ok(())
            },
        );
        methods.add_method(
            "setJointLimits",
            |_, this, (jid, lower, upper): (usize, f32, f32)| {
                this.world.borrow_mut().set_joint_limits(jid, lower, upper);
                Ok(())
            },
        );
        methods.add_method("getJointLimits", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_limits(jid))
        });
        methods.add_method(
            "setMouseJointTarget",
            |_, this, (jid, x, y): (usize, f32, f32)| {
                this.world.borrow_mut().set_mouse_joint_target(jid, x, y);
                Ok(())
            },
        );
        methods.add_method(
            "raycast",
            |lua, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| match this
                .world
                .borrow()
                .raycast(x1, y1, x2, y2)
            {
                Some(hit) => Ok(LuaValue::Table(raycast_hit_to_table(lua, &hit)?)),
                None => Ok(LuaValue::Nil),
            },
        );
        methods.add_method(
            "raycastClosest",
            |lua, this, (x1, y1, dx, dy, max_dist): (f32, f32, f32, f32, f32)| match this
                .world
                .borrow()
                .raycast_closest(x1, y1, dx, dy, max_dist)
            {
                Some(hit) => Ok(LuaValue::Table(raycast_hit_to_table(lua, &hit)?)),
                None => Ok(LuaValue::Nil),
            },
        );
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
        methods.add_method(
            "queryAABB",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                Ok(this.world.borrow().query_aabb(x, y, w, h))
            },
        );
        methods.add_method("getBodyAtPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.world.borrow().get_body_at_point(x, y))
        });
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
        methods.add_method("setBodyType", |_, this, (id, bt): (usize, String)| {
            let body_type = parse_body_type(&bt)?;
            this.world.borrow_mut().set_body_type(id, body_type);
            Ok(())
        });
        methods.add_method("getBodyType", |_, this, id: usize| {
            Ok(this.world.borrow().get_body_type_str(id).to_string())
        });
        methods.add_method("setBeginContact", |lua, this, f: LuaFunction| {
            *this.begin_contact_key.borrow_mut() = Some(lua.create_registry_value(f)?);
            Ok(())
        });
        methods.add_method("clearBeginContact", |_, this, ()| {
            *this.begin_contact_key.borrow_mut() = None;
            Ok(())
        });
        methods.add_method("setEndContact", |lua, this, f: LuaFunction| {
            *this.end_contact_key.borrow_mut() = Some(lua.create_registry_value(f)?);
            Ok(())
        });
        methods.add_method("clearEndContact", |_, this, ()| {
            *this.end_contact_key.borrow_mut() = None;
            Ok(())
        });
        methods.add_method(
            "setBodyData",
            |lua, this, (id, value): (usize, LuaValue)| {
                let key = lua.create_registry_value(value)?;
                this.body_data.borrow_mut().insert(id, key);
                Ok(())
            },
        );
        methods.add_method("getBodyData", |lua, this, id: usize| {
            let map = this.body_data.borrow();
            match map.get(&id) {
                Some(key) => lua.registry_value::<LuaValue>(key),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("clearBodyData", |lua, this, id: usize| {
            let removed = this.body_data.borrow_mut().remove(&id);
            if let Some(key) = removed {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("setBodyCCD", |_, this, (id, enabled): (usize, bool)| {
            this.world.borrow_mut().set_bullet(id, enabled);
            Ok(())
        });
        methods.add_method("getBodyCCD", |_, this, id: usize| {
            Ok(this.world.borrow().is_bullet(id))
        });
        methods.add_method(
            "setBodyOneWay",
            |_, this, (id, nx, ny): (usize, f32, f32)| {
                this.world.borrow_mut().set_body_one_way(id, nx, ny);
                Ok(())
            },
        );
        methods.add_method("clearBodyOneWay", |_, this, id: usize| {
            this.world.borrow_mut().clear_body_one_way(id);
            Ok(())
        });
        methods.add_method("getBodyOneWay", |_, this, id: usize| {
            match this.world.borrow().get_body_one_way(id) {
                Some((nx, ny)) => Ok((Some(nx), Some(ny))),
                None => Ok((None, None)),
            }
        });
        methods.add_method("setJointBreakForce", |_, this, (jid, f): (usize, f32)| {
            this.world.borrow_mut().set_joint_break_force(jid, f);
            Ok(())
        });
        methods.add_method("getJointBreakForce", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_break_force(jid))
        });
        methods.add_method("isBodySleeping", |_, this, id: usize| {
            Ok(this.world.borrow().is_body_sleeping(id))
        });
        methods.add_method("wakeUpBody", |_, this, id: usize| {
            this.world.borrow_mut().wake_up_body(id);
            Ok(())
        });
        methods.add_method("sleepBody", |_, this, id: usize| {
            this.world.borrow_mut().sleep_body(id);
            Ok(())
        });
        methods.add_method("setSolverIterations", |_, this, n: usize| {
            this.world.borrow_mut().set_solver_iterations(n);
            Ok(())
        });
        methods.add_method("getSolverIterations", |_, this, ()| {
            Ok(this.world.borrow().get_solver_iterations())
        });
        methods.add_method("newBodies", |_, this, specs: LuaTable| {
            let mut pairs: Vec<(f32, f32, BodyType)> = Vec::new();
            for entry in specs.sequence_values::<LuaTable>() {
                let t = entry?;
                let x: f32 = t.get(1)?;
                let y: f32 = t.get(2)?;
                let bt_str: String = t.get(3)?;
                pairs.push((x, y, parse_body_type_lenient(&bt_str)));
            }
            let ids = this.world.borrow_mut().add_bodies(pairs);
            Ok(ids)
        });
        methods.add_method_mut(
            "stepFixed",
            |_, this, (accum, step_dt, max_steps): (f32, f32, u32)| {
                let (_, remainder) = this
                    .world
                    .borrow_mut()
                    .step_fixed(accum, step_dt, max_steps);
                Ok(remainder)
            },
        );
        methods.add_method_mut("addZone", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            let zone = PhysicsZone::new_rect(0, x, y, w, h);
            let id = this.world.borrow_mut().add_zone(zone);
            Ok(LuaZone {
                zone_id: id,
                world: this.world.clone(),
            })
        });
        methods.add_method("getZoneEvents", |lua, this, ()| {
            let w = this.world.borrow();
            let events = w.get_zone_events();
            let tbl = lua.create_table()?;
            for (i, evt) in events.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("zone_id", evt.zone_id)?;
                row.set("body_id", evt.body_id)?;
                row.set(
                    "kind",
                    match evt.kind {
                        crate::physics::ZoneEventKind::Enter => "enter",
                        crate::physics::ZoneEventKind::Leave => "leave",
                    },
                )?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        });
        methods.add_method("type", |_, _, ()| Ok("LWorld"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LWorld" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaZone {
    zone_id: usize,
    world: Rc<RefCell<World>>,
}
impl LuaUserData for LuaZone {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getId", |_, this, ()| Ok(this.zone_id));
        methods.add_method("setEnabled", |_, this, enabled: bool| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.enabled = enabled;
            }
            Ok(())
        });
        methods.add_method("setPriority", |_, this, priority: i32| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.priority = priority;
            }
            Ok(())
        });
        methods.add_method("setLayerMask", |_, this, mask: u32| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.layer_mask = mask;
            }
            Ok(())
        });
        methods.add_method("setCircle", |_, this, (cx, cy, radius): (f32, f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.set_circle(cx, cy, radius);
            }
            Ok(())
        });
        methods.add_method("setGravityDirectional", |_, this, (gx, gy): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.set_gravity_directional(gx, gy);
            }
            Ok(())
        });
        methods.add_method(
            "setGravityPoint",
            |_, this, (cx, cy, strength): (f32, f32, f32)| {
                let mut w = this.world.borrow_mut();
                if let Some(z) = w.zone_mut(this.zone_id) {
                    z.set_gravity_point(cx, cy, strength);
                }
                Ok(())
            },
        );
        methods.add_method(
            "setGravityRepulsor",
            |_, this, (cx, cy, strength): (f32, f32, f32)| {
                let mut w = this.world.borrow_mut();
                if let Some(z) = w.zone_mut(this.zone_id) {
                    z.set_gravity_repulsor(cx, cy, strength);
                }
                Ok(())
            },
        );
        methods.add_method("setGravityZero", |_, this, ()| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.set_gravity_zero();
            }
            Ok(())
        });
        methods.add_method("setLinearDampingOverride", |_, this, value: Option<f32>| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.linear_damping_override = value;
            }
            Ok(())
        });
        methods.add_method(
            "setAngularDampingOverride",
            |_, this, value: Option<f32>| {
                let mut w = this.world.borrow_mut();
                if let Some(z) = w.zone_mut(this.zone_id) {
                    z.angular_damping_override = value;
                }
                Ok(())
            },
        );
        methods.add_method("destroy", |_, this, ()| {
            this.world.borrow_mut().remove_zone(this.zone_id);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LZone"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LZone" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaTerrain {
    terrain: Rc<RefCell<TerrainMap>>,
    world: Rc<RefCell<World>>,
}
impl LuaUserData for LuaTerrain {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("setCell", |_, this, (cx, cy, solid): (u32, u32, bool)| {
            this.terrain.borrow_mut().set_cell(cx, cy, solid);
            Ok(())
        });
        methods.add_method("getCell", |_, this, (cx, cy): (u32, u32)| {
            Ok(this.terrain.borrow().get_cell(cx, cy))
        });
        methods.add_method_mut(
            "fillCircle",
            |_, this, (wx, wy, radius, solid): (f32, f32, f32, bool)| {
                this.terrain.borrow_mut().fill_circle(wx, wy, radius, solid);
                Ok(())
            },
        );
        methods.add_method_mut(
            "fillRect",
            |_, this, (wx, wy, w, h, solid): (f32, f32, f32, f32, bool)| {
                this.terrain.borrow_mut().fill_rect(wx, wy, w, h, solid);
                Ok(())
            },
        );
        methods.add_method_mut("fillAll", |_, this, solid: bool| {
            this.terrain.borrow_mut().fill_all(solid);
            Ok(())
        });
        methods.add_method_mut("flush", |_, this, ()| {
            this.terrain
                .borrow_mut()
                .flush(&mut this.world.borrow_mut());
            Ok(())
        });
        methods.add_method("isDirty", |_, this, ()| {
            Ok(this.terrain.borrow().is_dirty())
        });
        methods.add_method_mut("collapseColumns", |_, this, ()| {
            Ok(this.terrain.borrow_mut().collapse_columns())
        });
        methods.add_method("solidPositions", |lua, this, ()| {
            let positions = this.terrain.borrow().solid_cell_positions();
            let tbl = lua.create_table()?;
            for (i, (x, y)) in positions.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("x", *x)?;
                row.set("y", *y)?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        });
        methods.add_method_mut(
            "spawnDebris",
            |lua, this, (positions, mass, restitution): (LuaTable, f32, f32)| {
                let mut pts: Vec<(f32, f32)> = Vec::new();
                for i in 1..=positions.raw_len() {
                    let row: LuaTable = positions.raw_get(i)?;
                    let x: f32 = row.get("x")?;
                    let y: f32 = row.get("y")?;
                    pts.push((x, y));
                }
                let ids = this.terrain.borrow().spawn_debris_at(
                    &mut this.world.borrow_mut(),
                    &pts,
                    mass,
                    restitution,
                );
                let tbl = lua.create_table()?;
                for (i, id) in ids.iter().enumerate() {
                    tbl.set(i + 1, *id)?;
                }
                Ok(tbl)
            },
        );
        methods.add_method(
            "toImageData",
            |lua, this, (sr, sg, sb, er, eg, eb): (u8, u8, u8, u8, u8, u8)| {
                let buf = this
                    .terrain
                    .borrow()
                    .to_image_data([sr, sg, sb, 255], [er, eg, eb, 255]);
                lua.create_string(&buf)
            },
        );
        methods.add_method("toBytes", |lua, this, ()| {
            lua.create_string(this.terrain.borrow().to_bytes())
        });
        methods.add_method_mut("loadFromBytes", |_, this, data: LuaString| {
            Ok(this.terrain.borrow_mut().load_from_bytes(data.as_bytes()))
        });
        methods.add_method("type", |_, _, ()| Ok("LTerrain"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTerrain" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaCellular {
    sim: Rc<RefCell<CellularWorld>>,
}
impl LuaUserData for LuaCellular {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("setCell", |_, this, (cx, cy, t): (u32, u32, u8)| {
            this.sim.borrow_mut().set_cell(cx, cy, CellType::from_u8(t));
            Ok(())
        });
        methods.add_method("getCell", |_, this, (cx, cy): (u32, u32)| {
            Ok(this.sim.borrow().get_cell(cx, cy) as u8)
        });
        methods.add_method_mut(
            "fillRect",
            |_, this, (cx0, cy0, cw, ch, t): (u32, u32, u32, u32, u8)| {
                this.sim
                    .borrow_mut()
                    .fill_rect(cx0, cy0, cw, ch, CellType::from_u8(t));
                Ok(())
            },
        );
        methods.add_method_mut(
            "fillCircle",
            |_, this, (cx, cy, r, t): (u32, u32, u32, u8)| {
                this.sim
                    .borrow_mut()
                    .fill_circle(cx, cy, r, CellType::from_u8(t));
                Ok(())
            },
        );
        methods.add_method_mut("step", |_, this, ()| {
            this.sim.borrow_mut().step();
            Ok(())
        });
        methods.add_method_mut("stepN", |_, this, n: u32| {
            this.sim.borrow_mut().step_n(n);
            Ok(())
        });
        methods.add_method("toImageData", |lua, this, ()| {
            let buf = this
                .sim
                .borrow()
                .to_image_data(crate::physics::default_palette);
            lua.create_string(&buf)
        });
        methods.add_method(
            "toImageDataRegion",
            |lua, this, (cx0, cy0, cw, ch): (u32, u32, u32, u32)| {
                let buf = this.sim.borrow().to_image_data_region(
                    cx0,
                    cy0,
                    cw,
                    ch,
                    crate::physics::default_palette,
                );
                lua.create_string(&buf)
            },
        );
        methods.add_method("countCells", |_, this, t: u8| {
            Ok(this.sim.borrow().count_cells(CellType::from_u8(t)))
        });
        methods.add_method("findCells", |lua, this, t: u8| {
            let positions = this.sim.borrow().find_cells(CellType::from_u8(t));
            let tbl = lua.create_table()?;
            for (i, (cx, cy)) in positions.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("x", *cx)?;
                row.set("y", *cy)?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        });
        methods.add_method("toBytes", |lua, this, ()| {
            lua.create_string(this.sim.borrow().to_bytes())
        });
        methods.add_method_mut("loadFromBytes", |_, this, data: LuaString| {
            match CellularWorld::from_bytes(data.as_bytes()) {
                Some(loaded) => {
                    *this.sim.borrow_mut() = loaded;
                    Ok(true)
                }
                None => Ok(false),
            }
        });
        methods.add_method("type", |_, _, ()| Ok("LCellular"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCellular" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaBody {
    world: Rc<RefCell<World>>,
    id: usize,
}
impl LuaUserData for LuaBody {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getId", |_, this, ()| Ok(this.id));
        methods.add_method("getPosition", |_, this, ()| {
            let w = this.world.borrow();
            match w.get_body(this.id) {
                Some(b) => Ok((b.position.x, b.position.y)),
                None => Ok((0.0, 0.0)),
            }
        });
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            this.world.borrow_mut().set_body_position(this.id, x, y);
            Ok(())
        });
        methods.add_method("getX", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.position.x))
        });
        methods.add_method("getY", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.position.y))
        });
        methods.add_method("getVelocity", |_, this, ()| {
            let w = this.world.borrow();
            match w.get_body(this.id) {
                Some(b) => Ok((b.velocity.x, b.velocity.y)),
                None => Ok((0.0, 0.0)),
            }
        });
        methods.add_method("setVelocity", |_, this, (vx, vy): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.velocity.x = vx;
                b.velocity.y = vy;
            }
            Ok(())
        });
        methods.add_method("getAngle", |_, this, ()| {
            Ok(this.world.borrow().get_body_angle(this.id))
        });
        methods.add_method("setAngle", |_, this, angle: f32| {
            this.world.borrow_mut().set_body_angle(this.id, angle);
            Ok(())
        });
        methods.add_method("getAngularVelocity", |_, this, ()| {
            Ok(this.world.borrow().get_angular_velocity(this.id))
        });
        methods.add_method("setAngularVelocity", |_, this, omega: f32| {
            this.world.borrow_mut().set_angular_velocity(this.id, omega);
            Ok(())
        });
        methods.add_method("getMass", |_, this, ()| {
            Ok(this.world.borrow().get_body_mass(this.id))
        });
        methods.add_method("setMass", |_, this, mass: f32| {
            this.world.borrow_mut().set_body_mass(this.id, mass);
            Ok(())
        });
        methods.add_method("getType", |_, this, ()| {
            Ok(this.world.borrow().get_body_type_str(this.id).to_string())
        });
        methods.add_method("setType", |_, this, bt: String| {
            let body_type = parse_body_type(&bt)?;
            this.world.borrow_mut().set_body_type(this.id, body_type);
            Ok(())
        });
        methods.add_method("getWidth", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.width))
        });
        methods.add_method("getHeight", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.height))
        });
        methods.add_method("getFriction", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.5, |b| b.friction))
        });
        methods.add_method("setFriction", |_, this, friction: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.friction = friction;
            }
            Ok(())
        });
        methods.add_method("getRestitution", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.3, |b| b.restitution))
        });
        methods.add_method("setRestitution", |_, this, restitution: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.restitution = restitution;
            }
            Ok(())
        });
        methods.add_method("getLayer", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(1u32, |b| b.layer))
        });
        methods.add_method("setLayer", |_, this, layer: u32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.layer = layer;
            }
            Ok(())
        });
        methods.add_method("getMask", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(1u32, |b| b.mask))
        });
        methods.add_method("setMask", |_, this, mask: u32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.mask = mask;
            }
            Ok(())
        });
        methods.add_method("applyImpulse", |_, this, (ix, iy): (f32, f32)| {
            this.world.borrow_mut().apply_impulse(this.id, ix, iy);
            Ok(())
        });
        methods.add_method("applyForce", |_, this, (fx, fy): (f32, f32)| {
            this.world.borrow_mut().apply_force(this.id, fx, fy);
            Ok(())
        });
        methods.add_method("applyTorque", |_, this, torque: f32| {
            this.world.borrow_mut().apply_torque(this.id, torque);
            Ok(())
        });
        methods.add_method(
            "applyForceAtPoint",
            |_, this, (fx, fy, px, py): (f32, f32, f32, f32)| {
                this.world
                    .borrow_mut()
                    .apply_force_at_point(this.id, fx, fy, px, py);
                Ok(())
            },
        );
        methods.add_method("applyAngularImpulse", |_, this, impulse: f32| {
            this.world
                .borrow_mut()
                .apply_angular_impulse(this.id, impulse);
            Ok(())
        });
        methods.add_method("getGravityScale", |_, this, ()| {
            Ok(this.world.borrow().get_gravity_scale(this.id))
        });
        methods.add_method("setGravityScale", |_, this, scale: f32| {
            this.world.borrow_mut().set_gravity_scale(this.id, scale);
            Ok(())
        });
        methods.add_method("isFixedRotation", |_, this, ()| {
            Ok(this.world.borrow().is_fixed_rotation(this.id))
        });
        methods.add_method("setFixedRotation", |_, this, fixed: bool| {
            this.world.borrow_mut().set_fixed_rotation(this.id, fixed);
            Ok(())
        });
        methods.add_method("getLinearDamping", |_, this, ()| {
            Ok(this.world.borrow().get_linear_damping(this.id))
        });
        methods.add_method("setLinearDamping", |_, this, damping: f32| {
            this.world.borrow_mut().set_linear_damping(this.id, damping);
            Ok(())
        });
        methods.add_method("getAngularDamping", |_, this, ()| {
            Ok(this.world.borrow().get_angular_damping(this.id))
        });
        methods.add_method("setAngularDamping", |_, this, damping: f32| {
            this.world
                .borrow_mut()
                .set_angular_damping(this.id, damping);
            Ok(())
        });
        methods.add_method("isBullet", |_, this, ()| {
            Ok(this.world.borrow().is_bullet(this.id))
        });
        methods.add_method("setBullet", |_, this, bullet: bool| {
            this.world.borrow_mut().set_bullet(this.id, bullet);
            Ok(())
        });
        methods.add_method("isSleepingAllowed", |_, this, ()| {
            Ok(this.world.borrow().is_sleeping_allowed(this.id))
        });
        methods.add_method("setSleepingAllowed", |_, this, allowed: bool| {
            this.world
                .borrow_mut()
                .set_sleeping_allowed(this.id, allowed);
            Ok(())
        });
        methods.add_method("destroy", |_, this, ()| {
            this.world.borrow_mut().destroy_body(this.id);
            Ok(())
        });
        methods.add_method("isSleeping", |_, this, ()| {
            Ok(this.world.borrow().is_body_sleeping(this.id))
        });
        methods.add_method("wakeUp", |_, this, ()| {
            this.world.borrow_mut().wake_up_body(this.id);
            Ok(())
        });
        methods.add_method("sleep", |_, this, ()| {
            this.world.borrow_mut().sleep_body(this.id);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LBody"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBody" || name == "Object")
        });
    }
}
struct LuaPhysicsShapeData {
    shape: Shape,
    density: f32,
    friction: f32,
    restitution: f32,
    sensor: bool,
}
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
        methods.add_method("getRadius", |_, this, ()| match this.inner.borrow().shape {
            Shape::Circle { radius } => Ok(radius),
            _ => Err(LuaError::RuntimeError(
                "getRadius: shape is not a circle".to_string(),
            )),
        });
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
        methods.add_method("setDensity", |_, this, density: f32| {
            this.inner.borrow_mut().density = density;
            Ok(())
        });
        methods.add_method("setFriction", |_, this, friction: f32| {
            this.inner.borrow_mut().friction = friction;
            Ok(())
        });
        methods.add_method("setRestitution", |_, this, restitution: f32| {
            this.inner.borrow_mut().restitution = restitution;
            Ok(())
        });
        methods.add_method("setSensor", |_, this, sensor: bool| {
            this.inner.borrow_mut().sensor = sensor;
            Ok(())
        });
        methods.add_method("destroy", |_, _this, ()| Ok(()));
        methods.add_method("type", |_, _, ()| Ok("LPhysicsShape"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPhysicsShape" || name == "Object")
        });
    }
}
impl From<crate::physics::PhysicsShapeSnapshot> for crate::render::renderer::PhysicsDebugShape {
    fn from(s: crate::physics::PhysicsShapeSnapshot) -> Self {
        Self {
            x: s.x,
            y: s.y,
            half_w: s.half_w,
            half_h: s.half_h,
            angle: s.angle,
            is_static: s.is_static,
            is_sleeping: s.is_sleeping,
            is_sensor: s.is_sensor,
            is_circle: s.is_circle,
            hull_verts: s.hull_verts,
        }
    }
}
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newWorld",
        lua.create_function(|_, (gx, gy): (f32, f32)| {
            Ok(LuaWorld {
                world: Rc::new(RefCell::new(World::new(gx, gy))),
                begin_contact_key: Rc::new(RefCell::new(None)),
                end_contact_key: Rc::new(RefCell::new(None)),
                body_data: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    tbl.set(
        "step",
        lua.create_function(|_, (world_ud, dt): (LuaAnyUserData, f32)| {
            let world = world_ud.borrow::<LuaWorld>()?;
            world.world.borrow_mut().step(dt);
            Ok(())
        })?,
    )?;
    tbl.set(
        "destroyWorld",
        lua.create_function(|_, _world_ud: LuaAnyUserData| Ok(()))?,
    )?;
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
    tbl.set(
        "getBody",
        lua.create_function(
            |_, (_world_ud, body_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let body = body_ud.borrow::<LuaBody>()?;
                let w = body.world.borrow();
                let (x, y) = w
                    .get_body(body.id)
                    .map_or((0.0_f32, 0.0_f32), |b| (b.position.x, b.position.y));
                let (vx, vy) = w
                    .get_body(body.id)
                    .map_or((0.0_f32, 0.0_f32), |b| (b.velocity.x, b.velocity.y));
                Ok((x, y, vx, vy))
            },
        )?,
    )?;
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
    tbl.set(
        "isSleepingAllowed",
        lua.create_function(
            |_, (_world_ud, body_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let body = body_ud.borrow::<LuaBody>()?;
                let allowed = body.world.borrow().is_sleeping_allowed(body.id);
                Ok(allowed)
            },
        )?,
    )?;
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
    tbl.set(
        "newRectangleShape",
        lua.create_function(|_, (w, h): (f32, f32)| {
            Ok(LuaPhysicsShape::new(Shape::Rect {
                width: w,
                height: h,
            }))
        })?,
    )?;
    tbl.set(
        "newCircleShape",
        lua.create_function(|_, r: f32| Ok(LuaPhysicsShape::new(Shape::Circle { radius: r })))?,
    )?;
    tbl.set(
        "newEdgeShape",
        lua.create_function(|_, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            Ok(LuaPhysicsShape::new(Shape::Edge {
                v1: crate::math::Vec2::new(x1, y1),
                v2: crate::math::Vec2::new(x2, y2),
            }))
        })?,
    )?;
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
    let s = state.clone();
    tbl.set(
        "debugDraw",
        lua.create_function(move |_, enable: bool| {
            s.borrow_mut().physics_run.debug_draw = enable;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "drawDebugGpu",
        lua.create_function(
            move |_, (world_ud, config_val): (LuaAnyUserData, LuaValue)| {
                let world_ref = world_ud.borrow::<LuaWorld>()?;
                let shapes: Vec<crate::render::renderer::PhysicsDebugShape> = world_ref
                    .world
                    .borrow()
                    .extract_shape_snapshots()
                    .into_iter()
                    .map(Into::into)
                    .collect();
                let mut cfg = crate::render::renderer::PhysicsDebugConfig::default();
                if let LuaValue::Table(tbl) = config_val {
                    if let Ok(v) = tbl.get::<_, LuaTable>("bodyColor") {
                        cfg.body_color = [
                            v.get::<_, f32>(1).unwrap_or(cfg.body_color[0]),
                            v.get::<_, f32>(2).unwrap_or(cfg.body_color[1]),
                            v.get::<_, f32>(3).unwrap_or(cfg.body_color[2]),
                            v.get::<_, f32>(4).unwrap_or(cfg.body_color[3]),
                        ];
                    }
                    if let Ok(v) = tbl.get::<_, LuaTable>("staticColor") {
                        cfg.static_color = [
                            v.get::<_, f32>(1).unwrap_or(cfg.static_color[0]),
                            v.get::<_, f32>(2).unwrap_or(cfg.static_color[1]),
                            v.get::<_, f32>(3).unwrap_or(cfg.static_color[2]),
                            v.get::<_, f32>(4).unwrap_or(cfg.static_color[3]),
                        ];
                    }
                    if let Ok(v) = tbl.get::<_, LuaTable>("sleepColor") {
                        cfg.sleep_color = [
                            v.get::<_, f32>(1).unwrap_or(cfg.sleep_color[0]),
                            v.get::<_, f32>(2).unwrap_or(cfg.sleep_color[1]),
                            v.get::<_, f32>(3).unwrap_or(cfg.sleep_color[2]),
                            v.get::<_, f32>(4).unwrap_or(cfg.sleep_color[3]),
                        ];
                    }
                    if let Ok(v) = tbl.get::<_, LuaTable>("sensorColor") {
                        cfg.sensor_color = [
                            v.get::<_, f32>(1).unwrap_or(cfg.sensor_color[0]),
                            v.get::<_, f32>(2).unwrap_or(cfg.sensor_color[1]),
                            v.get::<_, f32>(3).unwrap_or(cfg.sensor_color[2]),
                            v.get::<_, f32>(4).unwrap_or(cfg.sensor_color[3]),
                        ];
                    }
                    if let Ok(w) = tbl.get::<_, f32>("lineWidth") {
                        cfg.line_width = w;
                    }
                }
                s.borrow_mut().render_commands.push(
                    crate::render::renderer::RenderCommand::DrawPhysicsDebug {
                        shapes,
                        config: cfg,
                    },
                );
                Ok(())
            },
        )?,
    )?;
    tbl.set(
        "newTerrain",
        lua.create_function({
            move |_, (width, height, cell_size, world_ud): (u32, u32, f32, mlua::AnyUserData)| {
                let world_handle: std::cell::Ref<LuaWorld> = world_ud.borrow::<LuaWorld>()?;
                let terrain = TerrainMap::new(width, height, cell_size);
                Ok(LuaTerrain {
                    terrain: Rc::new(RefCell::new(terrain)),
                    world: world_handle.world.clone(),
                })
            }
        })?,
    )?;
    tbl.set(
        "newCellular",
        lua.create_function(move |_, (width, height): (u32, u32)| {
            Ok(LuaCellular {
                sim: Rc::new(RefCell::new(CellularWorld::new(width, height))),
            })
        })?,
    )?;
    tbl.set("CELL_AIR", CellType::Air as u8)?;
    tbl.set("CELL_SAND", CellType::Sand as u8)?;
    tbl.set("CELL_WATER", CellType::Water as u8)?;
    tbl.set("CELL_ROCK", CellType::Rock as u8)?;
    tbl.set("CELL_FIRE", CellType::Fire as u8)?;
    tbl.set("CELL_GAS", CellType::Gas as u8)?;
    tbl.set(
        "testAABB",
        lua.create_function(
            |_, (ax, ay, aw, ah, bx, by, bw, bh): (f32, f32, f32, f32, f32, f32, f32, f32)| {
                Ok(crate::physics::collision_helpers::test_aabb(
                    ax, ay, aw, ah, bx, by, bw, bh,
                ))
            },
        )?,
    )?;
    tbl.set(
        "testCircles",
        lua.create_function(
            |_, (ax, ay, ar, bx, by, br): (f32, f32, f32, f32, f32, f32)| {
                Ok(crate::physics::collision_helpers::test_circles(
                    ax, ay, ar, bx, by, br,
                ))
            },
        )?,
    )?;
    tbl.set(
        "testPoint",
        lua.create_function(
            |_, (px, py, ax, ay, aw, ah): (f32, f32, f32, f32, f32, f32)| {
                Ok(crate::physics::collision_helpers::test_point_aabb(
                    px, py, ax, ay, aw, ah,
                ))
            },
        )?,
    )?;
    tbl.set(
        "testCircleAABB",
        lua.create_function(
            |_, (cx, cy, cr, ax, ay, aw, ah): (f32, f32, f32, f32, f32, f32, f32)| {
                Ok(crate::physics::collision_helpers::test_circle_aabb(
                    cx, cy, cr, ax, ay, aw, ah,
                ))
            },
        )?,
    )?;
    luna.set("physics", tbl)?;
    Ok(())
}
