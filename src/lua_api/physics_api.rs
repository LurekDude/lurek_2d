//! `lurek.physics` — 2D rigid-body physics: worlds, bodies, shapes, joints, raycasting, collision queries, terrain, cellular simulation, and debug drawing via Rapier2D.

use super::SharedState;
use crate::math::Vec2;
use crate::physics::{
    Body, BodyType, CellType, CellularWorld, PhysicsZone, RaycastHit, Shape, TerrainMap, World,
};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
/// Parses a strict Lua body type string into the corresponding engine body type.
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
/// Parses a Lua body type string but falls back to `Dynamic` for unknown values.
fn parse_body_type_lenient(s: &str) -> BodyType {
    match s {
        "static" => BodyType::Static,
        "kinematic" => BodyType::Kinematic,
        "sensor" => BodyType::Sensor,
        _ => BodyType::Dynamic,
    }
}
/// Converts Lua shape constructor arguments into an engine physics shape definition.
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
/// Serializes a physics raycast hit into the Lua table shape exposed by the bindings.
fn raycast_hit_to_table<'lua>(lua: &'lua Lua, hit: &RaycastHit) -> LuaResult<LuaTable<'lua>> {
    let tbl = lua.create_table()?;
    /// Performs the 'bodyId' operation.
    tbl.set("bodyId", hit.body_id)?;
    /// Performs the 'x' operation.
    tbl.set("x", hit.point.0)?;
    /// Performs the 'y' operation.
    tbl.set("y", hit.point.1)?;
    /// Performs the 'normalX' operation.
    tbl.set("normalX", hit.normal.0)?;
    /// Performs the 'normalY' operation.
    tbl.set("normalY", hit.normal.1)?;
    /// Performs the 'toi' operation.
    tbl.set("toi", hit.toi)?;
    Ok(tbl)
}
/// A physics world that manages rigid bodies, joints, collision detection, and simulation stepping.
/// Created via `lurek.physics.newWorld(gx, gy)` and exposes all world-level operations to Lua.
#[derive(Clone)]
pub struct LuaWorld {
    world: Rc<RefCell<World>>,
    begin_contact_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    end_contact_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    body_data: Rc<RefCell<HashMap<usize, LuaRegistryKey>>>,
}
impl LuaWorld {
    /// World handle. This function is part of the public API.
    pub(crate) fn world_handle(&self) -> Rc<RefCell<World>> {
        self.world.clone()
    }
}
impl LuaUserData for LuaWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- drawDebug --
        /// Renders a debug visualization of all physics bodies onto a software ImageData target.
        /// @param | target | LImageData | The image to draw debug shapes onto.
        /// @param | r | integer? | Red channel (0-255, default 0).
        /// @param | g | integer? | Green channel (0-255, default 255).
        /// @param | b | integer? | Blue channel (0-255, default 0).
        /// @param | a | integer? | Alpha channel (0-255, default 255).
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
        // -- step --
        /// Advances the physics simulation by a time delta and fires any registered contact callbacks.
        /// @param | dt | number | Time step in seconds (e.g. 1/60 for 60 FPS).
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
        // -- clear --
        /// Removes all bodies and joints from the world, resetting it to an empty state.
        methods.add_method("clear", |_, this, ()| {
            this.world.borrow_mut().clear();
            Ok(())
        });
        // -- getGravity --
        /// Returns the current world gravity vector.
        /// @return | number | Gravity X component in world units per second squared.
        /// @return | number | Gravity Y component in world units per second squared.
        methods.add_method("getGravity", |_, this, ()| {
            Ok(this.world.borrow().get_gravity())
        });
        // -- setGravity --
        /// Sets the world gravity vector. Affects all dynamic bodies.
        /// @param | gx | number | Horizontal gravity component.
        /// @param | gy | number | Vertical gravity component (positive = down in screen space).
        methods.add_method("setGravity", |_, this, (gx, gy): (f32, f32)| {
            this.world.borrow_mut().set_gravity(gx, gy);
            Ok(())
        });
        // -- setMeter --
        /// Sets the pixels-per-meter scale used to convert between pixel coordinates and physics units.
        /// @param | ppm | number | Pixels per meter (e.g. 64 means 64 px = 1 meter in physics).
        methods.add_method("setMeter", |_, this, ppm: f32| {
            this.world.borrow_mut().set_meter(ppm);
            Ok(())
        });
        // -- getMeter --
        /// Returns the current pixels-per-meter scale.
        /// @return | number | Pixels per meter.
        methods.add_method("getMeter", |_, this, ()| {
            Ok(this.world.borrow().get_meter())
        });
        // -- toPhysics --
        /// Converts a pixel measurement to physics-world meters using the current meter scale.
        /// @param | px | number | Value in pixels.
        /// @return | number | Equivalent value in physics meters.
        methods.add_method("toPhysics", |_, this, px: f32| {
            Ok(this.world.borrow().to_physics(px))
        });
        // -- toPixels --
        /// Converts a physics-world meter measurement to pixels using the current meter scale.
        /// @param | m | number | Value in physics meters.
        /// @return | number | Equivalent value in pixels.
        methods.add_method("toPixels", |_, this, m: f32| {
            Ok(this.world.borrow().to_pixels(m))
        });
        // -- getBodyCount --
        /// Returns the total number of active bodies in the world.
        /// @return | integer | Body count.
        methods.add_method("getBodyCount", |_, this, ()| {
            Ok(this.world.borrow().body_count())
        });
        // -- getBodyIds --
        /// Returns a sequential table of all body IDs currently in the world.
        /// @return | integer[] | Body ID numbers.
        methods.add_method("getBodyIds", |_, this, ()| {
            Ok(this.world.borrow().get_body_ids())
        });
        // -- destroyBody --
        /// Removes a body from the world by its ID, along with all attached fixtures and joints.
        /// @param | id | integer | The body ID to destroy.
        methods.add_method("destroyBody", |_, this, id: usize| {
            this.world.borrow_mut().destroy_body(id);
            Ok(())
        });
        // -- newBody --
        /// Creates a new physics body at the given position with the specified type.
        /// @param | x | number | Initial X position in world coordinates.
        /// @param | y | number | Initial Y position in world coordinates.
        /// @param | bodyType | string | One of "static", "dynamic", "kinematic", or "sensor".
        /// @return | LBody | The newly created body handle.
        methods.add_method("newBody", |_, this, (x, y, bt): (f32, f32, String)| {
            let body_type = parse_body_type(&bt)?;
            let body = Body::new(x, y, body_type);
            let id = this.world.borrow_mut().add_body(body);
            Ok(LuaBody {
                world: Rc::clone(&this.world),
                id,
            })
        });
        // -- newCircleBody --
        /// Creates a new body with a circle collider already attached.
        /// @param | x | number | Initial X position in world coordinates.
        /// @param | y | number | Initial Y position in world coordinates.
        /// @param | radius | number | Circle radius in world units.
        /// @param | bodyType | string | One of "static", "dynamic", "kinematic", or "sensor".
        /// @return | LBody | The newly created body handle.
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
        /// Creates a new body with a convex polygon collider defined by vertex pairs.
        /// @param | x | number | Initial X position in world coordinates.
        /// @param | y | number | Initial Y position in world coordinates.
        /// @param | vertices | table | Flat array of vertex coordinates {x1,y1,x2,y2,...}.
        /// @param | bodyType | string | One of "static", "dynamic", "kinematic", or "sensor".
        /// @return | LBody | The newly created body handle.
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
        /// Creates a new body with an edge (line segment) collider between two local points.
        /// @param | x | number | Body X position in world coordinates.
        /// @param | y | number | Body Y position in world coordinates.
        /// @param | x1 | number | Edge start X relative to body.
        /// @param | y1 | number | Edge start Y relative to body.
        /// @param | x2 | number | Edge end X relative to body.
        /// @param | y2 | number | Edge end Y relative to body.
        /// @param | bodyType | string | One of "static", "dynamic", "kinematic", or "sensor".
        /// @return | LBody | The newly created body handle.
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
        // -- newChainBody --
        /// Creates a new body with a chain (polyline) collider. Useful for terrain edges.
        /// @param | x | number | Body X position in world coordinates.
        /// @param | y | number | Body Y position in world coordinates.
        /// @param | vertices | table | Flat array of vertex coordinates {x1,y1,x2,y2,...}.
        /// @param | closed | boolean | If true, connects the last vertex back to the first.
        /// @param | bodyType | string | One of "static", "dynamic", "kinematic", or "sensor".
        /// @return | LBody | The newly created body handle.
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
        /// Attaches a new collider shape to an existing body with material properties.
        /// @param | bodyId | number | The target body ID.
        /// @param | shapeType | string | Shape kind: "circle", "rectangle", "polygon", "edge", or "chain".
        /// @param | density | number | Mass density (affects dynamic body mass calculation).
        /// @param | friction | number | Surface friction coefficient (0 = ice, 1 = rubber).
        /// @param | restitution | number | Bounciness (0 = no bounce, 1 = perfectly elastic).
        /// @param | sensor | boolean | If true, detects overlaps without generating collision response.
        /// @param | ... | number | Shape-specific size arguments (radius, width/height, or vertex list).
        /// @return | integer | The fixture index on the body.
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
        // -- fixtureCount --
        /// Returns how many fixtures (colliders) are attached to a body.
        /// @param | bodyId | integer | The body to query.
        /// @return | integer | Number of attached fixtures.
        methods.add_method("fixtureCount", |_, this, body_id: usize| {
            Ok(this.world.borrow().fixture_count(body_id))
        });
        // -- setFixtureFriction --
        /// Updates the friction coefficient of a specific fixture on a body.
        /// @param | bodyId | integer | The body ID.
        /// @param | fixtureIndex | integer | Zero-based fixture index on the body.
        /// @param | friction | number | New friction value (0–1 typical range).
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
        /// Updates the restitution (bounciness) of a specific fixture on a body.
        /// @param | bodyId | integer | The body ID.
        /// @param | fixtureIndex | integer | Zero-based fixture index on the body.
        /// @param | restitution | number | New restitution value (0 = no bounce, 1 = full bounce).
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
        /// Toggles whether a fixture acts as a sensor (overlap detection only, no physical response).
        /// @param | bodyId | integer | The body ID.
        /// @param | fixtureIndex | integer | Zero-based fixture index on the body.
        /// @param | sensor | boolean | True to make it a sensor, false for solid collision.
        methods.add_method(
            "setFixtureSensor",
            |_, this, (body_id, fix_idx, sensor): (usize, usize, bool)| {
                this.world
                    .borrow_mut()
                    .set_fixture_sensor(body_id, fix_idx, sensor);
                Ok(())
            },
        );
        // -- addRevoluteJoint --
        /// Creates a revolute (hinge) joint connecting two bodies at an anchor point. Bodies can rotate freely around the anchor.
        /// @param | bodyA | integer | First body ID.
        /// @param | bodyB | integer | Second body ID.
        /// @param | anchorX | number | Anchor X in world coordinates.
        /// @param | anchorY | number | Anchor Y in world coordinates.
        /// @return | integer | The joint ID.
        methods.add_method(
            "addRevoluteJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_revolute_joint(a, b, ax, ay))
            },
        );
        // -- addDistanceJoint --
        /// Creates a distance joint that keeps two bodies at a fixed distance apart, like a rigid rod.
        /// @param | bodyA | integer | First body ID.
        /// @param | bodyB | integer | Second body ID.
        /// @param | anchorAX | number | Local anchor X on body A.
        /// @param | anchorAY | number | Local anchor Y on body A.
        /// @param | anchorBX | number | Local anchor X on body B.
        /// @param | anchorBY | number | Local anchor Y on body B.
        /// @param | length | number | Target distance between anchors.
        /// @return | integer | The joint ID.
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
        /// Creates a prismatic (slider) joint that constrains body B to move along an axis relative to body A.
        /// @param | bodyA | integer | First body ID.
        /// @param | bodyB | integer | Second body ID.
        /// @param | anchorX | number | Anchor X in world coordinates.
        /// @param | anchorY | number | Anchor Y in world coordinates.
        /// @param | axisX | number | Slide axis X direction.
        /// @param | axisY | number | Slide axis Y direction.
        /// @return | integer | The joint ID.
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
        /// Creates a weld joint that rigidly connects two bodies at an anchor point (no relative movement).
        /// @param | bodyA | integer | First body ID.
        /// @param | bodyB | integer | Second body ID.
        /// @param | anchorX | number | Anchor X in world coordinates.
        /// @param | anchorY | number | Anchor Y in world coordinates.
        /// @return | integer | The joint ID.
        methods.add_method(
            "addWeldJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_weld_joint(a, b, ax, ay))
            },
        );
        // -- addRopeJoint --
        /// Creates a rope joint limiting the maximum distance between two anchor points on two bodies.
        /// @param | bodyA | integer | First body ID.
        /// @param | bodyB | integer | Second body ID.
        /// @param | anchorAX | number | Local anchor X on body A.
        /// @param | anchorAY | number | Local anchor Y on body A.
        /// @param | anchorBX | number | Local anchor X on body B.
        /// @param | anchorBY | number | Local anchor Y on body B.
        /// @param | maxLength | number | Maximum allowed distance between anchors.
        /// @return | integer | The joint ID.
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
        /// Creates a wheel joint simulating a suspension: allows rotation and linear movement along an axis.
        /// @param | bodyA | integer | First body ID (chassis).
        /// @param | bodyB | integer | Second body ID (wheel).
        /// @param | anchorX | number | Anchor X in world coordinates.
        /// @param | anchorY | number | Anchor Y in world coordinates.
        /// @param | axisX | number | Suspension axis X direction.
        /// @param | axisY | number | Suspension axis Y direction.
        /// @return | integer | The joint ID.
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
        /// Creates a friction joint that applies resistance to relative motion between two bodies.
        /// @param | bodyA | integer | First body ID.
        /// @param | bodyB | integer | Second body ID.
        /// @param | anchorX | number | Anchor X in world coordinates.
        /// @param | anchorY | number | Anchor Y in world coordinates.
        /// @param | maxForce | number | Maximum friction force.
        /// @param | maxTorque | number | Maximum friction torque.
        /// @return | integer | The joint ID.
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
        /// Creates a motor joint that drives body B toward a target offset from body A using a correction factor.
        /// @param | bodyA | integer | First body ID.
        /// @param | bodyB | integer | Second body ID.
        /// @param | factor | number | Correction factor (0–1), higher = faster convergence.
        /// @return | integer | The joint ID.
        methods.add_method(
            "addMotorJoint",
            |_, this, (a, b, factor): (usize, usize, f32)| {
                Ok(this.world.borrow_mut().add_motor_joint(a, b, factor))
            },
        );
        // -- addMouseJoint --
        /// Creates a mouse joint that pulls a body toward a world target point with spring-like force.
        /// @param | bodyId | integer | The body to pull.
        /// @param | targetX | number | Initial target X in world coordinates.
        /// @param | targetY | number | Initial target Y in world coordinates.
        /// @param | maxForce | number | Maximum force applied to reach the target.
        /// @return | integer | The joint ID.
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
        /// Creates a pulley joint connecting two bodies so that movement of one affects the other inversely.
        /// @param | bodyA | integer | First body ID.
        /// @param | bodyB | integer | Second body ID.
        /// @param | anchorX | number | Shared anchor X.
        /// @param | anchorY | number | Shared anchor Y.
        /// @return | integer | The joint ID.
        methods.add_method(
            "addPulleyJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_pulley_joint(a, b, ax, ay))
            },
        );
        // -- addGearJoint --
        /// Creates a gear joint that synchronizes rotation between two bodies at an anchor.
        /// @param | bodyA | integer | First body ID.
        /// @param | bodyB | integer | Second body ID.
        /// @param | anchorX | number | Gear anchor X.
        /// @param | anchorY | number | Gear anchor Y.
        /// @return | integer | The joint ID.
        methods.add_method(
            "addGearJoint",
            |_, this, (a, b, ax, ay): (usize, usize, f32, f32)| {
                Ok(this.world.borrow_mut().add_gear_joint(a, b, ax, ay))
            },
        );
        // -- jointCount --
        /// Returns the total number of joints in the world.
        /// @return | integer | Joint count.
        methods.add_method("jointCount", |_, this, ()| {
            Ok(this.world.borrow().joint_count())
        });
        // -- getJointIds --
        /// Returns a sequential table of all joint IDs currently in the world.
        /// @return | integer[] | Joint ID numbers.
        methods.add_method("getJointIds", |_, this, ()| {
            Ok(this.world.borrow().get_joint_ids())
        });
        // -- getJointBodies --
        /// Returns the two body IDs connected by a joint.
        /// @param | jointId | integer | The joint ID to query.
        /// @return | integer | Body A ID.
        /// @return | integer | Body B ID.
        methods.add_method("getJointBodies", |_, this, jid: usize| {
            match this.world.borrow().get_joint_bodies(jid) {
                Some((a, b)) => Ok((a, b)),
                None => Err(LuaError::external(format!("invalid joint id: {}", jid))),
            }
        });
        // -- destroyJoint --
        /// Removes a joint from the world, disconnecting the two bodies it linked.
        /// @param | jointId | integer | The joint ID to destroy.
        methods.add_method("destroyJoint", |_, this, jid: usize| {
            this.world.borrow_mut().destroy_joint(jid);
            Ok(())
        });
        // -- getJointType --
        /// Returns the type name of a joint (e.g. "revolute", "distance", "prismatic").
        /// @param | jointId | integer | The joint ID.
        /// @return | string | The joint type name.
        methods.add_method("getJointType", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_type(jid).to_string())
        });
        // -- setJointMotorSpeed --
        /// Sets the motor speed on a motorized joint (revolute or prismatic).
        /// @param | jointId | integer | The joint ID.
        /// @param | speed | number | Desired motor speed (radians/sec for revolute, meters/sec for prismatic).
        methods.add_method(
            "setJointMotorSpeed",
            |_, this, (jid, speed): (usize, f32)| {
                this.world.borrow_mut().set_joint_motor_speed(jid, speed);
                Ok(())
            },
        );
        // -- getJointMotorSpeed --
        /// Returns the current motor speed setting of a joint.
        /// @param | jointId | integer | The joint ID.
        /// @return | number | Motor speed value.
        methods.add_method("getJointMotorSpeed", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_motor_speed(jid))
        });
        // -- setJointLimitsEnabled --
        /// Enables or disables angular/linear limits on a joint.
        /// @param | jointId | integer | The joint ID.
        /// @param | enabled | boolean | True to enforce limits, false to allow free movement.
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
        /// Sets the lower and upper bounds for a joint's limited range of motion.
        /// @param | jointId | integer | The joint ID.
        /// @param | lower | number | Lower limit (radians or meters depending on joint type).
        /// @param | upper | number | Upper limit.
        methods.add_method(
            "setJointLimits",
            |_, this, (jid, lower, upper): (usize, f32, f32)| {
                this.world.borrow_mut().set_joint_limits(jid, lower, upper);
                Ok(())
            },
        );
        // -- getJointLimits --
        /// Returns the lower and upper limit values for a joint.
        /// @param | jointId | integer | The joint ID.
        /// @return | number | Lower limit.
        /// @return | number | Upper limit.
        methods.add_method("getJointLimits", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_limits(jid))
        });
        // -- setMouseJointTarget --
        /// Moves the target position of a mouse joint, causing the attached body to follow.
        /// @param | jointId | integer | The mouse joint ID.
        /// @param | x | number | New target X in world coordinates.
        /// @param | y | number | New target Y in world coordinates.
        methods.add_method(
            "setMouseJointTarget",
            |_, this, (jid, x, y): (usize, f32, f32)| {
                this.world.borrow_mut().set_mouse_joint_target(jid, x, y);
                Ok(())
            },
        );
        // -- raycast --
        /// Casts a ray from point (x1,y1) to (x2,y2) and returns the first body hit, or nil.
        /// @param | x1 | number | Ray origin X.
        /// @param | y1 | number | Ray origin Y.
        /// @param | x2 | number | Ray end X.
        /// @param | y2 | number | Ray end Y.
        /// @return | table | Hit info {bodyId, x, y, normalX, normalY, toi} or nil if no hit.
        /// @field | bodyId | integer | BodyId.
        /// @field | x | number | X.
        /// @field | y | number | Y.
        /// @field | normalX | number | NormalX.
        /// @field | normalY | number | NormalY.
        /// @field | toi | number | Toi.
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
        // -- raycastClosest --
        /// Casts a directional ray from a point and returns the closest hit within max distance.
        /// @param | x | number | Ray origin X.
        /// @param | y | number | Ray origin Y.
        /// @param | dx | number | Ray direction X (does not need to be normalized).
        /// @param | dy | number | Ray direction Y.
        /// @param | maxDist | number | Maximum ray travel distance.
        /// @return | table | Hit info {bodyId, x, y, normalX, normalY, toi} or nil if no hit.
        /// @field | bodyId | integer | BodyId.
        /// @field | x | number | X.
        /// @field | y | number | Y.
        /// @field | normalX | number | NormalX.
        /// @field | normalY | number | NormalY.
        /// @field | toi | number | Toi.
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
        // -- raycastAll --
        /// Casts a directional ray and returns all bodies hit within max distance as a table of results.
        /// @param | x | number | Ray origin X.
        /// @param | y | number | Ray origin Y.
        /// @param | dx | number | Ray direction X.
        /// @param | dy | number | Ray direction Y.
        /// @param | maxDist | number | Maximum ray travel distance.
        /// @return | table | Array of hit tables {bodyId, x, y, normalX, normalY, toi}.
        /// @field | bodyId | integer | BodyId.
        /// @field | x | number | X.
        /// @field | y | number | Y.
        /// @field | normalX | number | NormalX.
        /// @field | normalY | number | NormalY.
        /// @field | toi | number | Toi.
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
        /// Returns all body IDs whose axis-aligned bounding boxes overlap the given rectangle.
        /// @param | x | number | Query rectangle left X.
        /// @param | y | number | Query rectangle top Y.
        /// @param | w | number | Query rectangle width.
        /// @param | h | number | Query rectangle height.
        /// @return | integer[] | Body ID numbers found in the region.
        methods.add_method(
            "queryAABB",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                Ok(this.world.borrow().query_aabb(x, y, w, h))
            },
        );
        // -- getBodyAtPoint --
        /// Returns the body ID at a specific world point, or nil if no body is there.
        /// @param | x | number | Query point X.
        /// @param | y | number | Query point Y.
        /// @return | integer | Body ID at the point, or nil.
        methods.add_method("getBodyAtPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.world.borrow().get_body_at_point(x, y))
        });
        // -- getCollisionEvents --
        /// Returns all collision events from the last step as a table of {bodyA, bodyB} pairs.
        /// @return | table | Array of collision event tables.
        /// @field | bodyA | integer | Body A id.
        /// @field | bodyB | integer | Body B id.
        methods.add_method("getCollisionEvents", |lua, this, ()| {
            let w = this.world.borrow();
            let events = w.get_collision_events();
            let result = lua.create_table()?;
            for (i, evt) in events.iter().enumerate() {
                let tbl = lua.create_table()?;
                /// Performs the 'bodyA' operation.
                tbl.set("bodyA", evt.body_a)?;
                /// Performs the 'bodyB' operation.
                tbl.set("bodyB", evt.body_b)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });
        // -- getBeginContactEvents --
        /// Returns contact-begin events from the last step (pairs of bodies that started touching).
        /// @return | table | Array of {bodyA, bodyB} tables.
        /// @field | bodyA | integer | BodyA.
        /// @field | bodyB | integer | BodyB.
        methods.add_method("getBeginContactEvents", |lua, this, ()| {
            let w = this.world.borrow();
            let events = w.get_begin_contact_events();
            let result = lua.create_table()?;
            for (i, (a, b)) in events.iter().enumerate() {
                let tbl = lua.create_table()?;
                /// Performs the 'bodyA' operation.
                tbl.set("bodyA", *a)?;
                /// Performs the 'bodyB' operation.
                tbl.set("bodyB", *b)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });
        // -- getEndContactEvents --
        /// Returns contact-end events from the last step (pairs of bodies that stopped touching).
        /// @return | table | Array of {bodyA, bodyB} tables.
        /// @field | bodyA | integer | BodyA.
        /// @field | bodyB | integer | BodyB.
        methods.add_method("getEndContactEvents", |lua, this, ()| {
            let w = this.world.borrow();
            let events = w.get_end_contact_events();
            let result = lua.create_table()?;
            for (i, (a, b)) in events.iter().enumerate() {
                let tbl = lua.create_table()?;
                /// Performs the 'bodyA' operation.
                tbl.set("bodyA", *a)?;
                /// Performs the 'bodyB' operation.
                tbl.set("bodyB", *b)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });
        // -- getContacts --
        /// Returns all currently active contact manifolds with normals and touching state.
        /// @return | table | Array of {bodyA, bodyB, normalX, normalY, isTouching} tables.
        /// @field | bodyA | integer | BodyA.
        /// @field | bodyB | integer | BodyB.
        /// @field | normalX | number | NormalX.
        /// @field | normalY | number | NormalY.
        /// @field | isTouching | boolean | IsTouching.
        methods.add_method("getContacts", |lua, this, ()| {
            let contacts = this.world.borrow().get_contacts();
            let result = lua.create_table()?;
            for (i, c) in contacts.iter().enumerate() {
                let tbl = lua.create_table()?;
                /// Performs the 'bodyA' operation.
                tbl.set("bodyA", c.body_a)?;
                /// Performs the 'bodyB' operation.
                tbl.set("bodyB", c.body_b)?;
                /// Performs the 'normalX' operation.
                tbl.set("normalX", c.normal_x)?;
                /// Performs the 'normalY' operation.
                tbl.set("normalY", c.normal_y)?;
                /// Performs the 'isTouching' operation.
                tbl.set("isTouching", c.is_touching)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });
        // -- getBodyContacts --
        /// Returns all contacts involving a specific body.
        /// @param | bodyId | integer | The body to query contacts for.
        /// @return | table | Array of {bodyA, bodyB, normalX, normalY, isTouching} tables.
        /// @field | bodyA | integer | BodyA.
        /// @field | bodyB | integer | BodyB.
        /// @field | normalX | number | NormalX.
        /// @field | normalY | number | NormalY.
        /// @field | isTouching | boolean | IsTouching.
        methods.add_method("getBodyContacts", |lua, this, body_id: usize| {
            let contacts = this.world.borrow().get_body_contacts(body_id);
            let result = lua.create_table()?;
            for (i, c) in contacts.iter().enumerate() {
                let tbl = lua.create_table()?;
                /// Performs the 'bodyA' operation.
                tbl.set("bodyA", c.body_a)?;
                /// Performs the 'bodyB' operation.
                tbl.set("bodyB", c.body_b)?;
                /// Performs the 'normalX' operation.
                tbl.set("normalX", c.normal_x)?;
                /// Performs the 'normalY' operation.
                tbl.set("normalY", c.normal_y)?;
                /// Performs the 'isTouching' operation.
                tbl.set("isTouching", c.is_touching)?;
                result.set(i + 1, tbl)?;
            }
            Ok(result)
        });
        // -- setBodyType --
        /// Changes the type of an existing body (e.g. from "dynamic" to "static").
        /// @param | id | integer | The body ID.
        /// @param | bodyType | string | New type: "static", "dynamic", "kinematic", or "sensor".
        methods.add_method("setBodyType", |_, this, (id, bt): (usize, String)| {
            let body_type = parse_body_type(&bt)?;
            this.world.borrow_mut().set_body_type(id, body_type);
            Ok(())
        });
        // -- getBodyType --
        /// Returns the type name of a body as a string.
        /// @param | id | integer | The body ID.
        /// @return | string | Body type: "static", "dynamic", "kinematic", or "sensor".
        methods.add_method("getBodyType", |_, this, id: usize| {
            Ok(this.world.borrow().get_body_type_str(id).to_string())
        });
        // -- setBeginContact --
        /// Registers a callback function invoked whenever two bodies begin touching.
        /// @param | callback | function | Called with (bodyIdA, bodyIdB) on each new contact.
        methods.add_method("setBeginContact", |lua, this, f: LuaFunction| {
            *this.begin_contact_key.borrow_mut() = Some(lua.create_registry_value(f)?);
            Ok(())
        });
        // -- clearBeginContact --
        /// Removes the begin-contact callback so it is no longer called.
        methods.add_method("clearBeginContact", |_, this, ()| {
            *this.begin_contact_key.borrow_mut() = None;
            Ok(())
        });
        // -- setEndContact --
        /// Registers a callback function invoked whenever two bodies stop touching.
        /// @param | callback | function | Called with (bodyIdA, bodyIdB) on each ended contact.
        methods.add_method("setEndContact", |lua, this, f: LuaFunction| {
            *this.end_contact_key.borrow_mut() = Some(lua.create_registry_value(f)?);
            Ok(())
        });
        // -- clearEndContact --
        /// Removes the end-contact callback so it is no longer called.
        methods.add_method("clearEndContact", |_, this, ()| {
            *this.end_contact_key.borrow_mut() = None;
            Ok(())
        });
        // -- setBodyData --
        /// Attaches arbitrary Lua data to a body ID for later retrieval (e.g. entity reference, tag).
        /// @param | id | integer | The body ID.
        /// @param | value | table | Lua value to associate with this body (table, number, string, etc.).
        methods.add_method(
            "setBodyData",
            |lua, this, (id, value): (usize, LuaValue)| {
                let key = lua.create_registry_value(value)?;
                this.body_data.borrow_mut().insert(id, key);
                Ok(())
            },
        );
        // -- getBodyData --
        /// Retrieves the Lua data previously attached to a body, or nil if none was set.
        /// @param | id | integer | The body ID.
        /// @return | table | The stored value, or nil if none was set.
        methods.add_method("getBodyData", |lua, this, id: usize| {
            let map = this.body_data.borrow();
            match map.get(&id) {
                Some(key) => lua.registry_value::<LuaValue>(key),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- clearBodyData --
        /// Removes and releases the Lua data attached to a body.
        /// @param | id | integer | The body ID.
        methods.add_method("clearBodyData", |lua, this, id: usize| {
            let removed = this.body_data.borrow_mut().remove(&id);
            if let Some(key) = removed {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- setBodyCCD --
        /// Enables or disables continuous collision detection (bullet mode) on a body to prevent tunneling.
        /// @param | id | integer | The body ID.
        /// @param | enabled | boolean | True to enable CCD.
        methods.add_method("setBodyCCD", |_, this, (id, enabled): (usize, bool)| {
            this.world.borrow_mut().set_bullet(id, enabled);
            Ok(())
        });
        // -- getBodyCCD --
        /// Returns whether continuous collision detection is enabled on a body.
        /// @param | id | integer | The body ID.
        /// @return | boolean | True if CCD is enabled.
        methods.add_method("getBodyCCD", |_, this, id: usize| {
            Ok(this.world.borrow().is_bullet(id))
        });
        // -- setBodyOneWay --
        /// Marks a body as a one-way platform: other bodies can pass through from the opposite side of the normal.
        /// @param | id | integer | The body ID.
        /// @param | nx | number | One-way normal X (points toward the blocking side).
        /// @param | ny | number | One-way normal Y.
        methods.add_method(
            "setBodyOneWay",
            |_, this, (id, nx, ny): (usize, f32, f32)| {
                this.world.borrow_mut().set_body_one_way(id, nx, ny);
                Ok(())
            },
        );
        // -- clearBodyOneWay --
        /// Removes the one-way platform behavior from a body, making it block from all directions.
        /// @param | id | integer | The body ID.
        methods.add_method("clearBodyOneWay", |_, this, id: usize| {
            this.world.borrow_mut().clear_body_one_way(id);
            Ok(())
        });
        // -- getBodyOneWay --
        /// Returns the one-way platform normal for a body, or nil,nil if not set.
        /// @param | id | integer | The body ID.
        /// @return | number | Normal X, or nil if not a one-way body.
        /// @return | number | Normal Y, or nil if not a one-way body.
        methods.add_method("getBodyOneWay", |_, this, id: usize| {
            match this.world.borrow().get_body_one_way(id) {
                Some((nx, ny)) => Ok((Some(nx), Some(ny))),
                None => Ok((None, None)),
            }
        });
        // -- setJointBreakForce --
        /// Sets the maximum force a joint can withstand before it breaks and is automatically destroyed.
        /// @param | jointId | integer | The joint ID.
        /// @param | force | number | Break threshold force (use math.huge for unbreakable).
        methods.add_method("setJointBreakForce", |_, this, (jid, f): (usize, f32)| {
            this.world.borrow_mut().set_joint_break_force(jid, f);
            Ok(())
        });
        // -- getJointBreakForce --
        /// Returns the break force threshold for a joint.
        /// @param | jointId | integer | The joint ID.
        /// @return | number | Break force value.
        methods.add_method("getJointBreakForce", |_, this, jid: usize| {
            Ok(this.world.borrow().get_joint_break_force(jid))
        });
        // -- isBodySleeping --
        /// Returns whether a body is currently in the sleeping (inactive) state.
        /// @param | id | integer | The body ID.
        /// @return | boolean | True if the body is sleeping.
        methods.add_method("isBodySleeping", |_, this, id: usize| {
            Ok(this.world.borrow().is_body_sleeping(id))
        });
        // -- wakeUpBody --
        /// Forces a sleeping body to wake up and participate in simulation again.
        /// @param | id | integer | The body ID.
        methods.add_method("wakeUpBody", |_, this, id: usize| {
            this.world.borrow_mut().wake_up_body(id);
            Ok(())
        });
        // -- sleepBody --
        /// Forces a body into the sleeping state, pausing its simulation until disturbed.
        /// @param | id | integer | The body ID.
        methods.add_method("sleepBody", |_, this, id: usize| {
            this.world.borrow_mut().sleep_body(id);
            Ok(())
        });
        // -- setSolverIterations --
        /// Sets the number of velocity solver iterations. Higher values improve stability at the cost of performance.
        /// @param | n | integer | Number of iterations (default is typically 4–8).
        methods.add_method("setSolverIterations", |_, this, n: usize| {
            this.world.borrow_mut().set_solver_iterations(n);
            Ok(())
        });
        // -- getSolverIterations --
        /// Returns the current number of velocity solver iterations.
        /// @return | integer | Iteration count.
        methods.add_method("getSolverIterations", |_, this, ()| {
            Ok(this.world.borrow().get_solver_iterations())
        });
        // -- newBodies --
        /// Batch-creates multiple bodies at once for better performance. Each entry is {x, y, type}.
        /// @param | specs | table | Array of tables: {{x, y, "dynamic"}, {x, y, "static"}, ...}.
        /// @return | integer[] | Body ID numbers in creation order.
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
        // -- stepFixed --
        /// Performs fixed-timestep physics stepping, consuming accumulated time. Returns the leftover time.
        /// @param | accumulator | number | Accumulated time since last frame (seconds).
        /// @param | stepDt | number | Fixed step size (e.g. 1/60).
        /// @param | maxSteps | integer | Maximum sub-steps per call to prevent spiral of death.
        /// @return | number | Remaining unstepped time to carry into next frame.
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
        // -- addZone --
        /// Creates a rectangular physics zone for area-based effects (custom gravity, damping overrides).
        /// @param | x | number | Zone left X.
        /// @param | y | number | Zone top Y.
        /// @param | w | number | Zone width.
        /// @param | h | number | Zone height.
        /// @return | LZone | The zone handle.
        methods.add_method_mut("addZone", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            let zone = PhysicsZone::new_rect(0, x, y, w, h);
            let id = this.world.borrow_mut().add_zone(zone);
            Ok(LuaZone {
                zone_id: id,
                world: this.world.clone(),
            })
        });
        // -- getZoneEvents --
        /// Returns all zone enter/leave events from the last step.
        /// @return | table | Array of {zone_id, body_id, kind} tables where kind is "enter" or "leave".
        /// @field | zone_id | integer | Zone_id.
        /// @field | body_id | integer | Body_id.
        /// @field | kind | string | Kind.
        methods.add_method("getZoneEvents", |lua, this, ()| {
            let w = this.world.borrow();
            let events = w.get_zone_events();
            let tbl = lua.create_table()?;
            for (i, evt) in events.iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'zone_id' operation.
                row.set("zone_id", evt.zone_id)?;
                /// Performs the 'body_id' operation.
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
        // -- type --
        /// Returns the type name of this object ("LWorld").
        /// @return | string | "LWorld".
        methods.add_method("type", |_, _, ()| Ok("LWorld"));
        // -- typeOf --
        /// Checks if this object is of a given type name. Supports inheritance (always matches "Object").
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the object matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LWorld" || name == "Object")
        });
    }
}
/// A physics zone that applies area-based effects (gravity overrides, damping) to bodies within its bounds.
#[derive(Clone)]
pub struct LuaZone {
    zone_id: usize,
    world: Rc<RefCell<World>>,
}
impl LuaUserData for LuaZone {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getId --
        /// Returns the unique ID of this zone. This method is available to Lua scripts.
        /// @return | integer | Zone ID.
        methods.add_method("getId", |_, this, ()| Ok(this.zone_id));
        // -- setEnabled --
        /// Enables or disables this zone. Disabled zones have no effect on bodies.
        /// @param | enabled | boolean | True to enable, false to disable.
        methods.add_method("setEnabled", |_, this, enabled: bool| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.enabled = enabled;
            }
            Ok(())
        });
        // -- setPriority --
        /// Sets the priority of this zone. Higher-priority zones take precedence when overlapping.
        /// @param | priority | integer | Integer priority value.
        methods.add_method("setPriority", |_, this, priority: i32| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.priority = priority;
            }
            Ok(())
        });
        // -- setLayerMask --
        /// Sets a bitmask controlling which body layers this zone affects.
        /// @param | mask | integer | Layer bitmask (bitwise AND with body layer must be nonzero).
        methods.add_method("setLayerMask", |_, this, mask: u32| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.layer_mask = mask;
            }
            Ok(())
        });
        // -- setCircle --
        /// Changes this zone's shape to a circle (overrides the initial rectangle).
        /// @param | cx | number | Center X.
        /// @param | cy | number | Center Y.
        /// @param | radius | number | Circle radius.
        methods.add_method("setCircle", |_, this, (cx, cy, radius): (f32, f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.set_circle(cx, cy, radius);
            }
            Ok(())
        });
        // -- setGravityDirectional --
        /// Sets the zone to apply a constant directional gravity to bodies inside.
        /// @param | gx | number | Gravity X component.
        /// @param | gy | number | Gravity Y component.
        methods.add_method("setGravityDirectional", |_, this, (gx, gy): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.set_gravity_directional(gx, gy);
            }
            Ok(())
        });
        // -- setGravityPoint --
        /// Sets the zone to attract bodies toward a center point with a given strength.
        /// @param | cx | number | Attractor center X.
        /// @param | cy | number | Attractor center Y.
        /// @param | strength | number | Pull force magnitude.
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
        // -- setGravityRepulsor --
        /// Sets the zone to push bodies away from a center point with a given strength.
        /// @param | cx | number | Repulsor center X.
        /// @param | cy | number | Repulsor center Y.
        /// @param | strength | number | Push force magnitude.
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
        // -- setGravityZero --
        /// Sets the zone to cancel all gravity for bodies inside (zero-G area).
        methods.add_method("setGravityZero", |_, this, ()| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.set_gravity_zero();
            }
            Ok(())
        });
        // -- setLinearDampingOverride --
        /// Overrides the linear damping of bodies inside this zone, or nil to use each body's own value.
        /// @param | value | number? | Damping override, or nil to clear.
        methods.add_method("setLinearDampingOverride", |_, this, value: Option<f32>| {
            let mut w = this.world.borrow_mut();
            if let Some(z) = w.zone_mut(this.zone_id) {
                z.linear_damping_override = value;
            }
            Ok(())
        });
        // -- setAngularDampingOverride --
        /// Overrides the angular damping of bodies inside this zone, or nil to use each body's own value.
        /// @param | value | number? | Damping override, or nil to clear.
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
        // -- destroy --
        /// Removes this zone from the world. Bodies will no longer be affected by it.
        methods.add_method("destroy", |_, this, ()| {
            this.world.borrow_mut().remove_zone(this.zone_id);
            Ok(())
        });
        // -- type --
        /// Returns the type name of this object ("LZone").
        /// @return | string | "LZone".
        methods.add_method("type", |_, _, ()| Ok("LZone"));
        // -- typeOf --
        /// Checks if this object is of a given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the object matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LZone" || name == "Object")
        });
    }
}
/// A destructible terrain map backed by a grid of solid/empty cells. Generates physics colliders on flush.
#[derive(Clone)]
pub struct LuaTerrain {
    terrain: Rc<RefCell<TerrainMap>>,
    world: Rc<RefCell<World>>,
}
impl LuaUserData for LuaTerrain {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setCell --
        /// Sets a single terrain cell to solid or empty.
        /// @param | cx | integer | Cell column (0-based).
        /// @param | cy | integer | Cell row (0-based).
        /// @param | solid | boolean | True for solid, false for empty.
        methods.add_method_mut("setCell", |_, this, (cx, cy, solid): (u32, u32, bool)| {
            this.terrain.borrow_mut().set_cell(cx, cy, solid);
            Ok(())
        });
        // -- getCell --
        /// Returns whether a cell is solid. This method is available to Lua scripts.
        /// @param | cx | integer | Cell column.
        /// @param | cy | integer | Cell row.
        /// @return | boolean | True if the cell is solid.
        methods.add_method("getCell", |_, this, (cx, cy): (u32, u32)| {
            Ok(this.terrain.borrow().get_cell(cx, cy))
        });
        // -- fillCircle --
        /// Fills or clears a circular region of terrain cells.
        /// @param | wx | number | Circle center X in world coordinates.
        /// @param | wy | number | Circle center Y in world coordinates.
        /// @param | radius | number | Circle radius in world units.
        /// @param | solid | boolean | True to fill solid, false to carve empty.
        methods.add_method_mut(
            "fillCircle",
            |_, this, (wx, wy, radius, solid): (f32, f32, f32, bool)| {
                this.terrain.borrow_mut().fill_circle(wx, wy, radius, solid);
                Ok(())
            },
        );
        // -- fillRect --
        /// Fills or clears a rectangular region of terrain cells.
        /// @param | wx | number | Rectangle left X in world coordinates.
        /// @param | wy | number | Rectangle top Y in world coordinates.
        /// @param | w | number | Rectangle width.
        /// @param | h | number | Rectangle height.
        /// @param | solid | boolean | True to fill solid, false to carve empty.
        methods.add_method_mut(
            "fillRect",
            |_, this, (wx, wy, w, h, solid): (f32, f32, f32, f32, bool)| {
                this.terrain.borrow_mut().fill_rect(wx, wy, w, h, solid);
                Ok(())
            },
        );
        // -- fillAll --
        /// Sets all terrain cells to either solid or empty.
        /// @param | solid | boolean | True to fill everything solid, false to clear.
        methods.add_method_mut("fillAll", |_, this, solid: bool| {
            this.terrain.borrow_mut().fill_all(solid);
            Ok(())
        });
        // -- flush --
        /// Regenerates physics colliders from the current terrain grid state. Call after modifying cells.
        methods.add_method_mut("flush", |_, this, ()| {
            this.terrain
                .borrow_mut()
                .flush(&mut this.world.borrow_mut());
            Ok(())
        });
        // -- isDirty --
        /// Returns true if terrain cells have been modified since the last flush.
        /// @return | boolean | True if a flush is needed.
        methods.add_method("isDirty", |_, this, ()| {
            Ok(this.terrain.borrow().is_dirty())
        });
        // -- collapseColumns --
        /// Optimizes terrain by merging vertically adjacent solid cells into larger colliders.
        /// @return | integer | Number of columns collapsed.
        methods.add_method_mut("collapseColumns", |_, this, ()| {
            Ok(this.terrain.borrow_mut().collapse_columns())
        });
        // -- solidPositions --
        /// Returns all solid cell positions as a table of {x, y} entries.
        /// @return | table | Array of tables with x and y fields (cell coordinates).
        /// @field | x | integer | Cell x coordinate.
        /// @field | y | integer | Cell y coordinate.
        methods.add_method("solidPositions", |lua, this, ()| {
            let positions = this.terrain.borrow().solid_cell_positions();
            let tbl = lua.create_table()?;
            for (i, (x, y)) in positions.iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'x' operation.
                row.set("x", *x)?;
                /// Performs the 'y' operation.
                row.set("y", *y)?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        });
        // -- spawnDebris --
        /// Spawns small dynamic debris bodies at the given positions (for destruction effects).
        /// @param | positions | table | Array of {x, y} tables in world coordinates.
        /// @param | mass | number | Mass of each debris body.
        /// @param | restitution | number | Bounciness of debris bodies.
        /// @return | integer[] | Array of body IDs for the spawned debris.
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
        // -- toImageData --
        /// Renders the terrain grid to raw RGBA pixel data with solid and empty colors.
        /// @param | sr | integer | Solid color red (0-255).
        /// @param | sg | integer | Solid color green.
        /// @param | sb | integer | Solid color blue.
        /// @param | er | integer | Empty color red.
        /// @param | eg | integer | Empty color green.
        /// @param | eb | integer | Empty color blue.
        /// @return | string | Raw RGBA pixel bytes.
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
        // -- toBytes --
        /// Serializes the terrain grid to a compact binary format for saving.
        /// @return | string | Binary terrain data.
        methods.add_method("toBytes", |lua, this, ()| {
            lua.create_string(this.terrain.borrow().to_bytes())
        });
        // -- loadFromBytes --
        /// Restores terrain grid state from binary data previously produced by toBytes.
        /// @param | data | string | Binary terrain data.
        /// @return | boolean | True if loading succeeded.
        methods.add_method_mut("loadFromBytes", |_, this, data: LuaString| {
            Ok(this.terrain.borrow_mut().load_from_bytes(data.as_bytes()))
        });
        // -- type --
        /// Returns the type name of this object ("LTerrain").
        /// @return | string | "LTerrain".
        methods.add_method("type", |_, _, ()| Ok("LTerrain"));
        // -- typeOf --
        /// Checks if this object is of a given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the object matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTerrain" || name == "Object")
        });
    }
}
/// A cellular automaton simulation grid (sand, water, fire, gas, rock) for particle-like physics effects.
#[derive(Clone)]
pub struct LuaCellular {
    sim: Rc<RefCell<CellularWorld>>,
}
impl LuaUserData for LuaCellular {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setCell --
        /// Sets a single cell in the cellular grid to a specific material type.
        /// @param | cx | integer | Cell column (0-based).
        /// @param | cy | integer | Cell row (0-based).
        /// @param | cellType | integer | Material type constant (CELL_AIR, CELL_SAND, etc.).
        methods.add_method_mut("setCell", |_, this, (cx, cy, t): (u32, u32, u8)| {
            this.sim.borrow_mut().set_cell(cx, cy, CellType::from_u8(t));
            Ok(())
        });
        // -- getCell --
        /// Returns the material type of a cell at the given grid position.
        /// @param | cx | integer | Cell column.
        /// @param | cy | integer | Cell row.
        /// @return | integer | Material type constant.
        methods.add_method("getCell", |_, this, (cx, cy): (u32, u32)| {
            Ok(this.sim.borrow().get_cell(cx, cy) as u8)
        });
        // -- fillRect --
        /// Fills a rectangular region of cells with a material type.
        /// @param | cx0 | integer | Top-left cell column.
        /// @param | cy0 | integer | Top-left cell row.
        /// @param | cw | integer | Width in cells.
        /// @param | ch | integer | Height in cells.
        /// @param | cellType | integer | Material type constant.
        methods.add_method_mut(
            "fillRect",
            |_, this, (cx0, cy0, cw, ch, t): (u32, u32, u32, u32, u8)| {
                this.sim
                    .borrow_mut()
                    .fill_rect(cx0, cy0, cw, ch, CellType::from_u8(t));
                Ok(())
            },
        );
        // -- fillCircle --
        /// Fills a circular region of cells with a material type.
        /// @param | cx | integer | Center cell column.
        /// @param | cy | integer | Center cell row.
        /// @param | r | integer | Radius in cells.
        /// @param | cellType | integer | Material type constant.
        methods.add_method_mut(
            "fillCircle",
            |_, this, (cx, cy, r, t): (u32, u32, u32, u8)| {
                this.sim
                    .borrow_mut()
                    .fill_circle(cx, cy, r, CellType::from_u8(t));
                Ok(())
            },
        );
        // -- step --
        /// Advances the cellular simulation by one tick (particles fall, flow, burn, etc.).
        methods.add_method_mut("step", |_, this, ()| {
            this.sim.borrow_mut().step();
            Ok(())
        });
        // -- stepN --
        /// Advances the cellular simulation by N ticks in a single call.
        /// @param | n | integer | Number of simulation ticks to run.
        methods.add_method_mut("stepN", |_, this, n: u32| {
            this.sim.borrow_mut().step_n(n);
            Ok(())
        });
        // -- toImageData --
        /// Renders the entire cellular grid to raw RGBA pixel data using the default material palette.
        /// @return | string | Raw RGBA pixel bytes (width * height * 4).
        methods.add_method("toImageData", |lua, this, ()| {
            let buf = this
                .sim
                .borrow()
                .to_image_data(crate::physics::default_palette);
            lua.create_string(&buf)
        });
        // -- toImageDataRegion --
        /// Renders a rectangular sub-region of the cellular grid to raw RGBA pixel data.
        /// @param | cx0 | integer | Top-left cell column.
        /// @param | cy0 | integer | Top-left cell row.
        /// @param | cw | integer | Width in cells.
        /// @param | ch | integer | Height in cells.
        /// @return | string | Raw RGBA pixel bytes (cw * ch * 4).
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
        // -- countCells --
        /// Counts how many cells of a given material type exist in the grid.
        /// @param | cellType | integer | Material type constant to count.
        /// @return | integer | Cell count.
        methods.add_method("countCells", |_, this, t: u8| {
            Ok(this.sim.borrow().count_cells(CellType::from_u8(t)))
        });
        // -- findCells --
        /// Returns positions of all cells matching a material type.
        /// @param | cellType | integer | Material type constant to find.
        /// @return | table | Array of {x, y} tables with cell coordinates.
        /// @field | x | number | X.
        /// @field | y | number | Y.
        methods.add_method("findCells", |lua, this, t: u8| {
            let positions = this.sim.borrow().find_cells(CellType::from_u8(t));
            let tbl = lua.create_table()?;
            for (i, (cx, cy)) in positions.iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'x' operation.
                row.set("x", *cx)?;
                /// Performs the 'y' operation.
                row.set("y", *cy)?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        });
        // -- toBytes --
        /// Serializes the cellular grid to a compact binary format for saving.
        /// @return | string | Binary cellular data.
        methods.add_method("toBytes", |lua, this, ()| {
            lua.create_string(this.sim.borrow().to_bytes())
        });
        // -- loadFromBytes --
        /// Restores cellular grid state from binary data previously produced by toBytes.
        /// @param | data | string | Binary cellular data.
        /// @return | boolean | True if loading succeeded, false if data was invalid.
        methods.add_method_mut("loadFromBytes", |_, this, data: LuaString| {
            match CellularWorld::from_bytes(data.as_bytes()) {
                Some(loaded) => {
                    *this.sim.borrow_mut() = loaded;
                    Ok(true)
                }
                None => Ok(false),
            }
        });
        // -- type --
        /// Returns the type name of this object ("LCellular").
        /// @return | string | "LCellular".
        methods.add_method("type", |_, _, ()| Ok("LCellular"));
        // -- typeOf --
        /// Checks if this object is of a given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the object matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCellular" || name == "Object")
        });
    }
}
/// A handle to a single physics body in the world, providing per-body manipulation methods.
#[derive(Clone)]
pub struct LuaBody {
    world: Rc<RefCell<World>>,
    id: usize,
}
impl LuaUserData for LuaBody {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getId --
        /// Returns the unique numeric ID of this body within the world.
        /// @return | integer | Body ID.
        methods.add_method("getId", |_, this, ()| Ok(this.id));
        // -- getPosition --
        /// Returns the current world-space position of this body.
        /// @return | number | X coordinate.
        /// @return | number | Y coordinate.
        methods.add_method("getPosition", |_, this, ()| {
            let w = this.world.borrow();
            match w.get_body(this.id) {
                Some(b) => Ok((b.position.x, b.position.y)),
                None => Ok((0.0, 0.0)),
            }
        });
        // -- setPosition --
        /// Teleports the body to a new world-space position (does not apply physics forces).
        /// @param | x | number | New X position.
        /// @param | y | number | New Y position.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            this.world.borrow_mut().set_body_position(this.id, x, y);
            Ok(())
        });
        // -- getX --
        /// Returns only the X component of the body's position.
        /// @return | number | X coordinate.
        methods.add_method("getX", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.position.x))
        });
        // -- getY --
        /// Returns only the Y component of the body's position.
        /// @return | number | Y coordinate.
        methods.add_method("getY", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.position.y))
        });
        // -- getVelocity --
        /// Returns the body's current linear velocity.
        /// @return | number | Velocity X component.
        /// @return | number | Velocity Y component.
        methods.add_method("getVelocity", |_, this, ()| {
            let w = this.world.borrow();
            match w.get_body(this.id) {
                Some(b) => Ok((b.velocity.x, b.velocity.y)),
                None => Ok((0.0, 0.0)),
            }
        });
        // -- setVelocity --
        /// Directly sets the body's linear velocity.
        /// @param | vx | number | Velocity X component.
        /// @param | vy | number | Velocity Y component.
        methods.add_method("setVelocity", |_, this, (vx, vy): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.velocity.x = vx;
                b.velocity.y = vy;
            }
            Ok(())
        });
        // -- getAngle --
        /// Returns the body's rotation angle in radians.
        /// @return | number | Angle in radians.
        methods.add_method("getAngle", |_, this, ()| {
            Ok(this.world.borrow().get_body_angle(this.id))
        });
        // -- setAngle --
        /// Sets the body's rotation angle directly.
        /// @param | angle | number | New angle in radians.
        methods.add_method("setAngle", |_, this, angle: f32| {
            this.world.borrow_mut().set_body_angle(this.id, angle);
            Ok(())
        });
        // -- getAngularVelocity --
        /// Returns the body's angular (rotational) velocity.
        /// @return | number | Angular velocity in radians per second.
        methods.add_method("getAngularVelocity", |_, this, ()| {
            Ok(this.world.borrow().get_angular_velocity(this.id))
        });
        // -- setAngularVelocity --
        /// Sets the body's angular velocity directly.
        /// @param | omega | number | Angular velocity in radians per second.
        methods.add_method("setAngularVelocity", |_, this, omega: f32| {
            this.world.borrow_mut().set_angular_velocity(this.id, omega);
            Ok(())
        });
        // -- getMass --
        /// Returns the body's total mass (computed from density and fixture areas).
        /// @return | number | Mass in kilograms.
        methods.add_method("getMass", |_, this, ()| {
            Ok(this.world.borrow().get_body_mass(this.id))
        });
        // -- setMass --
        /// Overrides the body's mass directly.
        /// @param | mass | number | New mass value.
        methods.add_method("setMass", |_, this, mass: f32| {
            this.world.borrow_mut().set_body_mass(this.id, mass);
            Ok(())
        });
        // -- getType --
        /// Returns the body's type as a string.
        /// @return | string | Body type: "static", "dynamic", "kinematic", or "sensor".
        methods.add_method("getType", |_, this, ()| {
            Ok(this.world.borrow().get_body_type_str(this.id).to_string())
        });
        // -- setType --
        /// Changes the body's type at runtime.
        /// @param | bodyType | string | New type: "static", "dynamic", "kinematic", or "sensor".
        methods.add_method("setType", |_, this, bt: String| {
            let body_type = parse_body_type(&bt)?;
            this.world.borrow_mut().set_body_type(this.id, body_type);
            Ok(())
        });
        // -- getWidth --
        /// Returns the body's bounding width (from its primary shape).
        /// @return | number | Width in world units.
        methods.add_method("getWidth", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.width))
        });
        // -- getHeight --
        /// Returns the body's bounding height (from its primary shape).
        /// @return | number | Height in world units.
        methods.add_method("getHeight", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.0, |b| b.height))
        });
        // -- getFriction --
        /// Returns the body's friction coefficient.
        /// @return | number | Friction value.
        methods.add_method("getFriction", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.5, |b| b.friction))
        });
        // -- setFriction --
        /// Sets the body's friction coefficient.
        /// @param | friction | number | New friction value (0 = ice, 1 = rubber).
        methods.add_method("setFriction", |_, this, friction: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.friction = friction;
            }
            Ok(())
        });
        // -- getRestitution --
        /// Returns the body's restitution (bounciness) value.
        /// @return | number | Restitution (0 = no bounce, 1 = perfectly elastic).
        methods.add_method("getRestitution", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(0.3, |b| b.restitution))
        });
        // -- setRestitution --
        /// Sets the body's restitution (bounciness) value.
        /// @param | restitution | number | New restitution (0–1).
        methods.add_method("setRestitution", |_, this, restitution: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.restitution = restitution;
            }
            Ok(())
        });
        // -- getLayer --
        /// Returns the body's collision layer bitmask.
        /// @return | integer | Layer bitmask.
        methods.add_method("getLayer", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(1u32, |b| b.layer))
        });
        // -- setLayer --
        /// Sets the body's collision layer bitmask (which layers this body belongs to).
        /// @param | layer | integer | Layer bitmask.
        methods.add_method("setLayer", |_, this, layer: u32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.layer = layer;
            }
            Ok(())
        });
        // -- getMask --
        /// Returns the body's collision mask (which layers this body can collide with).
        /// @return | integer | Mask bitmask.
        methods.add_method("getMask", |_, this, ()| {
            let w = this.world.borrow();
            Ok(w.get_body(this.id).map_or(1u32, |b| b.mask))
        });
        // -- setMask --
        /// Sets the body's collision mask (which layers this body can collide with).
        /// @param | mask | integer | Collision mask bitmask.
        methods.add_method("setMask", |_, this, mask: u32| {
            let mut w = this.world.borrow_mut();
            if let Some(b) = w.get_body_mut(this.id) {
                b.mask = mask;
            }
            Ok(())
        });
        // -- applyImpulse --
        /// Applies an instantaneous linear impulse to the body's center of mass.
        /// @param | ix | number | Impulse X component.
        /// @param | iy | number | Impulse Y component.
        methods.add_method("applyImpulse", |_, this, (ix, iy): (f32, f32)| {
            this.world.borrow_mut().apply_impulse(this.id, ix, iy);
            Ok(())
        });
        // -- applyForce --
        /// Applies a continuous force to the body's center of mass (accumulates over the step).
        /// @param | fx | number | Force X component.
        /// @param | fy | number | Force Y component.
        methods.add_method("applyForce", |_, this, (fx, fy): (f32, f32)| {
            this.world.borrow_mut().apply_force(this.id, fx, fy);
            Ok(())
        });
        // -- applyTorque --
        /// Applies a rotational torque to the body.
        /// @param | torque | number | Torque value (positive = counter-clockwise).
        methods.add_method("applyTorque", |_, this, torque: f32| {
            this.world.borrow_mut().apply_torque(this.id, torque);
            Ok(())
        });
        // -- applyForceAtPoint --
        /// Applies a force at a specific world point, generating both linear and angular acceleration.
        /// @param | fx | number | Force X component.
        /// @param | fy | number | Force Y component.
        /// @param | px | number | Application point X in world coordinates.
        /// @param | py | number | Application point Y in world coordinates.
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
        /// Applies an instantaneous angular impulse (spin) to the body.
        /// @param | impulse | number | Angular impulse value.
        methods.add_method("applyAngularImpulse", |_, this, impulse: f32| {
            this.world
                .borrow_mut()
                .apply_angular_impulse(this.id, impulse);
            Ok(())
        });
        // -- getGravityScale --
        /// Returns the gravity scale multiplier for this body (1.0 = normal gravity).
        /// @return | number | Gravity scale.
        methods.add_method("getGravityScale", |_, this, ()| {
            Ok(this.world.borrow().get_gravity_scale(this.id))
        });
        // -- setGravityScale --
        /// Sets a per-body gravity scale multiplier (0 = no gravity, 2 = double gravity, -1 = inverted).
        /// @param | scale | number | Gravity scale factor.
        methods.add_method("setGravityScale", |_, this, scale: f32| {
            this.world.borrow_mut().set_gravity_scale(this.id, scale);
            Ok(())
        });
        // -- isFixedRotation --
        /// Returns whether the body's rotation is locked.
        /// @return | boolean | True if rotation is fixed.
        methods.add_method("isFixedRotation", |_, this, ()| {
            Ok(this.world.borrow().is_fixed_rotation(this.id))
        });
        // -- setFixedRotation --
        /// Locks or unlocks the body's rotation. Useful for player characters.
        /// @param | fixed | boolean | True to prevent rotation.
        methods.add_method("setFixedRotation", |_, this, fixed: bool| {
            this.world.borrow_mut().set_fixed_rotation(this.id, fixed);
            Ok(())
        });
        // -- getLinearDamping --
        /// Returns the linear damping factor (velocity decay rate, like air resistance).
        /// @return | number | Damping value.
        methods.add_method("getLinearDamping", |_, this, ()| {
            Ok(this.world.borrow().get_linear_damping(this.id))
        });
        // -- setLinearDamping --
        /// Sets the linear damping factor (higher = more velocity decay per step).
        /// @param | damping | number | Damping value (0 = no damping).
        methods.add_method("setLinearDamping", |_, this, damping: f32| {
            this.world.borrow_mut().set_linear_damping(this.id, damping);
            Ok(())
        });
        // -- getAngularDamping --
        /// Returns the angular damping factor (rotational decay rate).
        /// @return | number | Angular damping value.
        methods.add_method("getAngularDamping", |_, this, ()| {
            Ok(this.world.borrow().get_angular_damping(this.id))
        });
        // -- setAngularDamping --
        /// Sets the angular damping factor (higher = rotation decays faster).
        /// @param | damping | number | Angular damping value.
        methods.add_method("setAngularDamping", |_, this, damping: f32| {
            this.world
                .borrow_mut()
                .set_angular_damping(this.id, damping);
            Ok(())
        });
        // -- isBullet --
        /// Returns whether continuous collision detection (bullet mode) is enabled for this body.
        /// @return | boolean | True if CCD is active.
        methods.add_method("isBullet", |_, this, ()| {
            Ok(this.world.borrow().is_bullet(this.id))
        });
        // -- setBullet --
        /// Enables or disables continuous collision detection to prevent fast-moving tunneling.
        /// @param | bullet | boolean | True to enable CCD.
        methods.add_method("setBullet", |_, this, bullet: bool| {
            this.world.borrow_mut().set_bullet(this.id, bullet);
            Ok(())
        });
        // -- isSleepingAllowed --
        /// Returns whether the body is allowed to enter sleep state when at rest.
        /// @return | boolean | True if sleeping is allowed.
        methods.add_method("isSleepingAllowed", |_, this, ()| {
            Ok(this.world.borrow().is_sleeping_allowed(this.id))
        });
        // -- setSleepingAllowed --
        /// Controls whether the body can enter sleep state. Disable for bodies that must stay active.
        /// @param | allowed | boolean | True to allow sleeping.
        methods.add_method("setSleepingAllowed", |_, this, allowed: bool| {
            this.world
                .borrow_mut()
                .set_sleeping_allowed(this.id, allowed);
            Ok(())
        });
        // -- destroy --
        /// Destroys this body, removing it from the world along with all fixtures and joints.
        methods.add_method("destroy", |_, this, ()| {
            this.world.borrow_mut().destroy_body(this.id);
            Ok(())
        });
        // -- isSleeping --
        /// Returns whether this body is currently in the sleeping (inactive) state.
        /// @return | boolean | True if sleeping.
        methods.add_method("isSleeping", |_, this, ()| {
            Ok(this.world.borrow().is_body_sleeping(this.id))
        });
        // -- wakeUp --
        /// Wakes the body from sleep, making it active in the simulation again.
        methods.add_method("wakeUp", |_, this, ()| {
            this.world.borrow_mut().wake_up_body(this.id);
            Ok(())
        });
        // -- sleep --
        /// Forces the body into sleep state, pausing its simulation until disturbed.
        methods.add_method("sleep", |_, this, ()| {
            this.world.borrow_mut().sleep_body(this.id);
            Ok(())
        });
        // -- type --
        /// Returns the type name of this object ("LBody").
        /// @return | string | "LBody".
        methods.add_method("type", |_, _, ()| Ok("LBody"));
        // -- typeOf --
        /// Checks if this object is of a given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the object matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBody" || name == "Object")
        });
    }
}
/// Stores raw shape geometry and default fixture material properties for a Lua shape handle.
struct LuaPhysicsShapeData {
    /// Collision geometry attached to bodies created from this handle.
    shape: Shape,
    /// Density applied to attached fixtures.
    density: f32,
    /// Friction coefficient applied to attached fixtures.
    friction: f32,
    /// Restitution coefficient applied to attached fixtures.
    restitution: f32,
    /// Whether attached fixtures should behave as sensors only.
    sensor: bool,
}
/// A standalone collision shape with material properties, to be attached to bodies via `attachShape`.
#[derive(Clone)]
pub struct LuaPhysicsShape {
    inner: Rc<RefCell<LuaPhysicsShapeData>>,
}
impl LuaPhysicsShape {
    /// Creates a Lua shape wrapper with default density, friction, restitution, and sensor settings.
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
        /// Returns the shape kind as a string: "circle", "rectangle", "polygon", "edge", or "chain".
        /// @return | string | Shape type name.
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
        /// Returns the radius of a circle shape. Errors if called on a non-circle shape.
        /// @return | number | Circle radius.
        methods.add_method("getRadius", |_, this, ()| match this.inner.borrow().shape {
            Shape::Circle { radius } => Ok(radius),
            _ => Err(LuaError::RuntimeError(
                "getRadius: shape is not a circle".to_string(),
            )),
        });
        // -- getBoundingBox --
        /// Returns the axis-aligned bounding box of the shape in local coordinates.
        /// @return | number | Minimum X.
        /// @return | number | Minimum Y.
        /// @return | number | Maximum X.
        /// @return | number | Maximum Y.
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
        /// Sets the density used when this shape is attached to a body (affects mass calculation).
        /// @param | density | number | Mass density.
        methods.add_method("setDensity", |_, this, density: f32| {
            this.inner.borrow_mut().density = density;
            Ok(())
        });
        // -- setFriction --
        /// Sets the friction coefficient for this shape.
        /// @param | friction | number | Friction (0 = ice, 1 = rubber).
        methods.add_method("setFriction", |_, this, friction: f32| {
            this.inner.borrow_mut().friction = friction;
            Ok(())
        });
        // -- setRestitution --
        /// Sets the restitution (bounciness) for this shape.
        /// @param | restitution | number | Restitution (0\u20131).
        methods.add_method("setRestitution", |_, this, restitution: f32| {
            this.inner.borrow_mut().restitution = restitution;
            Ok(())
        });
        // -- setSensor --
        /// Marks this shape as a sensor (overlap detection only, no physical response).
        /// @param | sensor | boolean | True for sensor mode.
        methods.add_method("setSensor", |_, this, sensor: bool| {
            this.inner.borrow_mut().sensor = sensor;
            Ok(())
        });
        // -- destroy --
        /// No-op placeholder for API consistency. Shapes are freed when no longer referenced.
        methods.add_method("destroy", |_, _this, ()| Ok(()));
        // -- type --
        /// Returns the type name of this object ("LPhysicsShape").
        /// @return | string | "LPhysicsShape".
        methods.add_method("type", |_, _, ()| Ok("LPhysicsShape"));
        // -- typeOf --
        /// Checks if this object is of a given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the object matches.
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
/// Registers the `lurek.physics` module table and all its free functions onto the given Lua table.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newWorld --
    /// Creates a new physics world with the given gravity vector.
    /// @param | gx | number | Gravity X component.
    /// @param | gy | number | Gravity Y component (positive = down).
    /// @return | LWorld | The new physics world.
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
    // -- step --
    /// Steps a physics world forward by dt seconds (free-function variant).
    /// @param | world | LWorld | The world to step.
    /// @param | dt | number | Time step in seconds.
    tbl.set(
        "step",
        lua.create_function(|_, (world_ud, dt): (LuaAnyUserData, f32)| {
            let world = world_ud.borrow::<LuaWorld>()?;
            world.world.borrow_mut().step(dt);
            Ok(())
        })?,
    )?;
    // -- destroyWorld --
    /// No-op placeholder for API parity. Worlds are freed when no longer referenced.
    /// @param | world | LWorld | The world to destroy.
    tbl.set(
        "destroyWorld",
        lua.create_function(|_, _world_ud: LuaAnyUserData| Ok(()))?,
    )?;
    // -- newBody --
    /// Creates a new body in a world (free-function variant).
    /// @param | world | LWorld | The target world.
    /// @param | x | number | Initial X position.
    /// @param | y | number | Initial Y position.
    /// @param | bodyType | string | Body type: "static", "dynamic", "kinematic", or "sensor".
    /// @return | LBody | The newly created body.
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
    // -- getBody --
    /// Returns position and velocity of a body (free-function variant for quick queries).
    /// @param | world | LWorld | The world.
    /// @param | body | LBody | The body to query.
    /// @return | number | X position.
    /// @return | number | Y position.
    /// @return | number | Velocity X.
    /// @return | number | Velocity Y.
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
    // -- setBodyVelocity --
    /// Sets a body's velocity (free-function variant).
    /// @param | world | LWorld | The world.
    /// @param | body | LBody | The body.
    /// @param | vx | number | Velocity X.
    /// @param | vy | number | Velocity Y.
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
    // -- isSleepingAllowed --
    /// Checks if sleeping is allowed on a body (free-function variant).
    /// @param | world | LWorld | The world.
    /// @param | body | LBody | The body.
    /// @return | boolean | True if sleeping is allowed.
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
    // -- setSleepingAllowed --
    /// Sets whether a body is allowed to sleep (free-function variant).
    /// @param | world | LWorld | The world.
    /// @param | body | LBody | The body.
    /// @param | allowed | boolean | True to allow sleeping.
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
    /// Creates a rectangle collision shape with the given dimensions.
    /// @param | w | number | Width.
    /// @param | h | number | Height.
    /// @return | LPhysicsShape | The shape object.
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
    /// Creates a circle collision shape with the given radius.
    /// @param | r | number | Radius.
    /// @return | LPhysicsShape | The shape object.
    tbl.set(
        "newCircleShape",
        lua.create_function(|_, r: f32| Ok(LuaPhysicsShape::new(Shape::Circle { radius: r })))?,
    )?;
    // -- newEdgeShape --
    /// Creates an edge (line segment) collision shape between two local points.
    /// @param | x1 | number | Start X.
    /// @param | y1 | number | Start Y.
    /// @param | x2 | number | End X.
    /// @param | y2 | number | End Y.
    /// @return | LPhysicsShape | The shape object.
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
    /// Creates a convex polygon collision shape from vertex coordinate pairs.
    /// @param | ... | number | Alternating x,y coordinates (minimum 3 pairs = 6 numbers).
    /// @return | LPhysicsShape | The shape object.
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
    /// Creates a chain (polyline) collision shape. Useful for terrain outlines.
    /// @param | closed | boolean | If true, connects last vertex to first.
    /// @param | ... | number | Alternating x,y coordinates (minimum 2 pairs = 4 numbers).
    /// @return | LPhysicsShape | The shape object.
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
    /// Attaches a previously created shape to a body, using the shape's stored material properties.
    /// @param | body | LBody | The target body.
    /// @param | shape | LPhysicsShape | The shape to attach.
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
    /// Returns all collision events from the last world step as {body_a, body_b} pairs.
    /// @param | world | LWorld | The world to query.
    /// @return | table | Array of collision event tables.
    /// @field | body_a | integer | Body A id.
    /// @field | body_b | integer | Body B id.
    tbl.set(
        "getCollisions",
        lua.create_function(|lua, world_ud: LuaAnyUserData| {
            let world_lua = world_ud.borrow::<LuaWorld>()?;
            let world = world_lua.world.borrow();
            let events = world.get_collision_events();
            let tbl = lua.create_table()?;
            for (i, contact) in events.iter().enumerate() {
                let entry = lua.create_table()?;
                /// Performs the 'body_a' operation.
                entry.set("body_a", contact.body_a)?;
                /// Performs the 'body_b' operation.
                entry.set("body_b", contact.body_b)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        })?,
    )?;
    // -- debugDraw --
    /// Enables or disables automatic physics debug overlay rendering for the next frame.
    /// @param | enable | boolean | True to show debug shapes.
    let s = state.clone();
    tbl.set(
        "debugDraw",
        lua.create_function(move |_, enable: bool| {
            s.borrow_mut().physics_run.debug_draw = enable;
            Ok(())
        })?,
    )?;
    // -- drawDebugGpu --
    /// Queues a GPU-rendered physics debug visualization using the world's current body state.
    /// @param | world | LWorld | The world to visualize.
    /// @param | config | table? | Optional config: {bodyColor, staticColor, sleepColor, sensorColor, lineWidth}.
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
    // -- newTerrain --
    /// Creates a destructible terrain grid linked to a physics world for automatic collider generation.
    /// @param | width | integer | Grid width in cells.
    /// @param | height | integer | Grid height in cells.
    /// @param | cellSize | number | World-space size of each cell.
    /// @param | world | LWorld | The physics world that will own the generated colliders.
    /// @return | LTerrain | The terrain object.
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
    // -- newCellular --
    /// Creates a new cellular automaton simulation grid for particle-like physics (sand, water, fire).
    /// @param | width | integer | Grid width in cells.
    /// @param | height | integer | Grid height in cells.
    /// @return | LCellular | The cellular simulation object.
    tbl.set(
        "newCellular",
        lua.create_function(move |_, (width, height): (u32, u32)| {
            Ok(LuaCellular {
                sim: Rc::new(RefCell::new(CellularWorld::new(width, height))),
            })
        })?,
    )?;
    /// Cell type constant: air — passable empty cell for cellular simulation.
    tbl.set("CELL_AIR", CellType::Air as u8)?;
    /// Cell type constant: sand — granular solid that falls and piles.
    tbl.set("CELL_SAND", CellType::Sand as u8)?;
    /// Cell type constant: water — liquid that flows and spreads.
    tbl.set("CELL_WATER", CellType::Water as u8)?;
    /// Cell type constant: rock — immovable solid barrier.
    tbl.set("CELL_ROCK", CellType::Rock as u8)?;
    /// Cell type constant: fire — active combustion that spreads and consumes.
    tbl.set("CELL_FIRE", CellType::Fire as u8)?;
    /// Cell type constant: gas — diffusing vapor that rises.
    tbl.set("CELL_GAS", CellType::Gas as u8)?;
    // -- testAABB --
    /// Tests whether two axis-aligned bounding boxes overlap. Lightweight collision check without physics world.
    /// @param | ax | number | First rect X.
    /// @param | ay | number | First rect Y.
    /// @param | aw | number | First rect width.
    /// @param | ah | number | First rect height.
    /// @param | bx | number | Second rect X.
    /// @param | by | number | Second rect Y.
    /// @param | bw | number | Second rect width.
    /// @param | bh | number | Second rect height.
    /// @return | boolean | True if the rectangles overlap.
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
    // -- testCircles --
    /// Tests whether two circles overlap. Lightweight collision check without physics world.
    /// @param | ax | number | First circle center X.
    /// @param | ay | number | First circle center Y.
    /// @param | ar | number | First circle radius.
    /// @param | bx | number | Second circle center X.
    /// @param | by | number | Second circle center Y.
    /// @param | br | number | Second circle radius.
    /// @return | boolean | True if the circles overlap.
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
    // -- testPoint --
    /// Tests whether a point lies inside an AABB. Lightweight check without physics world.
    /// @param | px | number | Point X.
    /// @param | py | number | Point Y.
    /// @param | ax | number | Rect X.
    /// @param | ay | number | Rect Y.
    /// @param | aw | number | Rect width.
    /// @param | ah | number | Rect height.
    /// @return | boolean | True if the point is inside.
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
    // -- testCircleAABB --
    /// Tests whether a circle overlaps an AABB. Lightweight check without physics world.
    /// @param | cx | number | Circle center X.
    /// @param | cy | number | Circle center Y.
    /// @param | cr | number | Circle radius.
    /// @param | ax | number | Rect X.
    /// @param | ay | number | Rect Y.
    /// @param | aw | number | Rect width.
    /// @param | ah | number | Rect height.
    /// @return | boolean | True if circle and AABB overlap.
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
    /// Performs the 'physics' operation.
    luna.set("physics", tbl)?;
    Ok(())
}
