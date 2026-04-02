//! Helper types and utilities for the physics API.

use crate::lua_api::lua_types::{add_type_methods, LunaType};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::Vec2;
use crate::physics::{BodyType, Shape, World};


/// Parses a body type string into a `BodyType` enum value.
pub(super) fn parse_body_type(s: &str) -> BodyType {
    match s {
        "static" => BodyType::Static,
        "dynamic" => BodyType::Dynamic,
        "kinematic" => BodyType::Kinematic,
        "sensor" => BodyType::Sensor,
        _ => BodyType::Dynamic,
    }
}

/// Lua UserData wrapper for a physics world.
///
/// # Fields
/// - `worlds` ÔÇö Shared vector of all physics worlds.
/// - `index` ÔÇö Index of this world in the vector.
/// - `begin_contact_cb` ÔÇö Optional Lua callback for contact-start events.
/// - `end_contact_cb` ÔÇö Optional Lua callback for contact-end events.
#[derive(Clone)]
pub struct LuaWorld {
    pub(crate) worlds: Rc<RefCell<Vec<World>>>,
    pub(crate) index: usize,
    pub(crate) begin_contact_cb: Rc<RefCell<Option<mlua::RegistryKey>>>,
    pub(crate) end_contact_cb: Rc<RefCell<Option<mlua::RegistryKey>>>,
}

impl LunaType for LuaWorld {
    const TYPE_NAME: &'static str = "World";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Advances the physics simulation by `dt` seconds, resolving collisions and integrating forces.
        ///
        /// # Parameters
        /// - `dt` ÔÇö `number`: Elapsed simulation time in seconds.
        methods.add_method("step", |lua, this, dt: f32| {
            // Step the world
            {
                let mut ws = this.worlds.borrow_mut();
                if let Some(world) = ws.get_mut(this.index) {
                    world.step(dt);
                }
            }

            // Dispatch beginContact callbacks
            if let Some(ref key) = *this.begin_contact_cb.borrow() {
                let func: LuaFunction = lua.registry_value(key)?;
                let events: Vec<(usize, usize)> = {
                    let ws = this.worlds.borrow();
                    ws.get(this.index)
                        .map(|w| w.get_begin_contact_events().to_vec())
                        .unwrap_or_default()
                };
                for (a, b) in events {
                    let body_a = LuaBody {
                        worlds: this.worlds.clone(),
                        world_index: this.index,
                        body_index: a,
                    };
                    let body_b = LuaBody {
                        worlds: this.worlds.clone(),
                        world_index: this.index,
                        body_index: b,
                    };
                    func.call::<_, ()>((body_a, body_b))?;
                }
            }

            // Dispatch endContact callbacks
            if let Some(ref key) = *this.end_contact_cb.borrow() {
                let func: LuaFunction = lua.registry_value(key)?;
                let events: Vec<(usize, usize)> = {
                    let ws = this.worlds.borrow();
                    ws.get(this.index)
                        .map(|w| w.get_end_contact_events().to_vec())
                        .unwrap_or_default()
                };
                for (a, b) in events {
                    let body_a = LuaBody {
                        worlds: this.worlds.clone(),
                        world_index: this.index,
                        body_index: a,
                    };
                    let body_b = LuaBody {
                        worlds: this.worlds.clone(),
                        world_index: this.index,
                        body_index: b,
                    };
                    func.call::<_, ()>((body_a, body_b))?;
                }
            }

            Ok(())
        });

        /// Registers collision begin/end callback functions for this physics world.
        ///
        /// # Parameters
        /// - `beginContact` ÔÇö Called with (body1, body2) when two bodies start touching.
        /// - `endContact` ÔÇö Called with (body1, body2) when they separate.
        methods.add_method("setCallbacks", |lua, this, callbacks: LuaTable| {
            if let Ok(f) = callbacks.get::<_, LuaFunction>("beginContact") {
                let key = lua.create_registry_value(f)?;
                *this.begin_contact_cb.borrow_mut() = Some(key);
            }
            if let Ok(f) = callbacks.get::<_, LuaFunction>("endContact") {
                let key = lua.create_registry_value(f)?;
                *this.end_contact_cb.borrow_mut() = Some(key);
            }
            Ok(())
        });

        /// Returns the current world gravity vector.
        ///
        /// # Returns
        /// Two numbers `gx, gy`.
        methods.add_method("getGravity", |_, this, ()| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.index) {
                let (gx, gy) = world.get_gravity();
                return Ok((gx, gy));
            }
            Ok((0.0f32, 0.0f32))
        });

        /// Sets world gravity. Default is `(0, 9.81)` (downward).
        ///
        /// # Parameters
        /// - `x` ÔÇö `number`: Horizontal gravity component.
        /// - `y` ÔÇö `number`: Vertical gravity component.
        methods.add_method("setGravity", |_, this, (gx, gy): (f32, f32)| {
            let mut ws = this.worlds.borrow_mut();
            if let Some(world) = ws.get_mut(this.index) {
                world.set_gravity(gx, gy);
            }
            Ok(())
        });

        methods.add_method(
            "setSleepingAllowed",
            |_, this, (body_id, allowed): (usize, bool)| {
                let mut ws = this.worlds.borrow_mut();
                if let Some(world) = ws.get_mut(this.index) {
                    world.set_sleeping_allowed(body_id, allowed);
                }
                Ok(())
            },
        );

        /// Returns whether bodies in this world are allowed to enter a sleep state.
        ///
        /// # Returns
        /// true if sleeping is permitted globally, false if all bodies stay awake.
        methods.add_method("isSleepingAllowed", |_, this, body_id: usize| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.index) {
                return Ok(world.is_sleeping_allowed(body_id));
            }
            Ok(true)
        });

        /// Returns the number of bodies in the world.
        methods.add_method("getBodyCount", |_, this, ()| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.index) {
                return Ok(world.body_count());
            }
            Ok(0usize)
        });

        /// Returns a table of all currently active collision pairs in this physics world.
        ///
        /// # Returns
        /// Table of {bodyA, bodyB, nx, ny, overlap} collision records.
        methods.add_method("getCollisions", |lua, this, ()| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.index) {
                let events = world.get_collision_events();
                let table = lua.create_table()?;
                for (i, ev) in events.iter().enumerate() {
                    let pair = lua.create_table()?;
                    /// Body_a.
                    pair.set(
                        "body_a",
                        LuaBody {
                            worlds: this.worlds.clone(),
                            world_index: this.index,
                            body_index: ev.body_a,
                        },
                    )?;
                    /// Body_b.
                    pair.set(
                        "body_b",
                        LuaBody {
                            worlds: this.worlds.clone(),
                            world_index: this.index,
                            body_index: ev.body_b,
                        },
                    )?;
                    table.set(i + 1, pair)?;
                }
                return Ok(table);
            }
            lua.create_table()
        });
    }
}

/// Lua UserData wrapper for a physics body.
///
/// # Fields
/// - `worlds` ÔÇö Shared vector of all physics worlds.
/// - `world_index` ÔÇö Index of the body's parent world.
/// - `body_index` ÔÇö Index of this body within the world.
#[derive(Clone)]
pub struct LuaBody {
    pub(crate) worlds: Rc<RefCell<Vec<World>>>,
    pub(crate) world_index: usize,
    pub(crate) body_index: usize,
}

impl LunaType for LuaBody {
    const TYPE_NAME: &'static str = "Body";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaBody {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_meta_method(LuaMetaMethod::Eq, |_, this, other: LuaAnyUserData| {
            if let Ok(body) = other.borrow::<LuaBody>() {
                Ok(this.world_index == body.world_index && this.body_index == body.body_index)
            } else {
                Ok(false)
            }
        });

        /// Returns the body's current world-space position.
        ///
        /// # Returns
        /// Two numbers `x, y` in world units.
        methods.add_method("getPosition", |_, this, ()| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.world_index) {
                if let Some(body) = world.get_body(this.body_index) {
                    return Ok((body.position.x, body.position.y));
                }
            }
            Ok((0.0f32, 0.0f32))
        });

        /// Teleports the body to the given world-space position (bypasses collision detection).
        ///
        /// # Parameters
        /// - `x` ÔÇö `number`: Target X position.
        /// - `y` ÔÇö `number`: Target Y position.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut ws = this.worlds.borrow_mut();
            if let Some(world) = ws.get_mut(this.world_index) {
                world.set_body_position(this.body_index, x, y);
            }
            Ok(())
        });

        /// Returns the current linear velocity vector of the body.
        ///
        /// # Returns
        /// vx, vy velocity in world units per second.
        methods.add_method("getVelocity", |_, this, ()| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.world_index) {
                if let Some(body) = world.get_body(this.body_index) {
                    return Ok((body.velocity.x, body.velocity.y));
                }
            }
            Ok((0.0f32, 0.0f32))
        });

        /// Sets the body's linear velocity to the given (vx, vy) world-space vector.
        ///
        /// # Parameters
        /// - `vx` ÔÇö Velocity along the X axis in world units per second.
        /// - `vy` ÔÇö Velocity along the Y axis in world units per second.
        methods.add_method("setVelocity", |_, this, (vx, vy): (f32, f32)| {
            let mut ws = this.worlds.borrow_mut();
            if let Some(world) = ws.get_mut(this.world_index) {
                if let Some(body) = world.get_body_mut(this.body_index) {
                    body.velocity = Vec2::new(vx, vy);
                }
            }
            Ok(())
        });

        /// Returns the body's current rotation angle in radians.
        ///
        /// # Returns
        /// `number` ÔÇö angle in radians.
        methods.add_method("getAngle", |_, this, ()| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.world_index) {
                return Ok(world.get_body_angle(this.body_index));
            }
            Ok(0.0f32)
        });

        /// Sets the body's rotation to `angle` radians (bypasses physics).
        ///
        /// # Parameters
        /// - `angle` ÔÇö `number`: Target angle in radians.
        methods.add_method("setAngle", |_, this, angle: f32| {
            let mut ws = this.worlds.borrow_mut();
            if let Some(world) = ws.get_mut(this.world_index) {
                world.set_body_angle(this.body_index, angle);
            }
            Ok(())
        });

        /// Returns the total simulated mass of the body in physics units.
        ///
        /// # Returns
        /// Mass as a number in physics units.
        methods.add_method("getMass", |_, this, ()| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.world_index) {
                return Ok(world.get_body_mass(this.body_index));
            }
            Ok(0.0f32)
        });

        /// Resizes the body's primary collision shape to the given width and height.
        ///
        /// # Parameters
        /// - `width` ÔÇö New shape width in world units.
        /// - `height` ÔÇö New shape height in world units.
        methods.add_method("setSize", |_, this, (w, h): (f32, f32)| {
            let mut ws = this.worlds.borrow_mut();
            if let Some(world) = ws.get_mut(this.world_index) {
                if let Some(body) = world.get_body_mut(this.body_index) {
                    body.width = w;
                    body.height = h;
                }
            }
            Ok(())
        });

        /// Applies a continuous force (accumulates until the next physics step) to the body's centre of mass.
        ///
        /// # Parameters
        /// - `fx` ÔÇö `number`: Horizontal force component.
        /// - `fy` ÔÇö `number`: Vertical force component.
        methods.add_method("applyForce", |_, this, (fx, fy): (f32, f32)| {
            let mut ws = this.worlds.borrow_mut();
            if let Some(world) = ws.get_mut(this.world_index) {
                world.apply_force(this.body_index, fx, fy);
            }
            Ok(())
        });

        /// Applies an instantaneous impulse directly to the body's centre of mass.
        ///
        /// # Parameters
        /// - `ix` ÔÇö `number`: Horizontal impulse.
        /// - `iy` ÔÇö `number`: Vertical impulse.
        methods.add_method("applyImpulse", |_, this, (ix, iy): (f32, f32)| {
            let mut ws = this.worlds.borrow_mut();
            if let Some(world) = ws.get_mut(this.world_index) {
                world.apply_impulse(this.body_index, ix, iy);
            }
            Ok(())
        });

        /// Returns the type string of the given body.
        methods.add_method("getBodyType", |_, this, ()| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.world_index) {
                return Ok(world.get_body_type_str(this.body_index).to_string());
            }
            Ok("dynamic".to_string())
        });

        /// Destroys the body and removes it from its parent physics world immediately.
        methods.add_method("destroy", |_, this, ()| {
            let mut ws = this.worlds.borrow_mut();
            if let Some(world) = ws.get_mut(this.world_index) {
                world.destroy_body(this.body_index);
            }
            Ok(())
        });

        // ÔöÇÔöÇ Multi-fixture methods ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

        /// Adds a collision fixture to the body using the given shape definition table.
        ///
        /// # Parameters
        /// - `def` ÔÇö Table describing the fixture: shape, density, friction, restitution.
        ///
        /// # Returns
        /// Fixture ID for the newly attached fixture.
        methods.add_method("addFixture", |_, this, params: LuaTable| {
            let mut ws = this.worlds.borrow_mut();
            if let Some(world) = ws.get_mut(this.world_index) {
                let shape_type: String = params.get("shape").unwrap_or_else(|_| "rect".to_string());
                let friction: f32 = params.get("friction").unwrap_or(0.5);
                let restitution: f32 = params.get("restitution").unwrap_or(0.3);
                let density: f32 = params.get("density").unwrap_or(1.0);
                let sensor: bool = params.get("sensor").unwrap_or(false);

                let shape = match shape_type.as_str() {
                    "circle" => {
                        let radius: f32 = params.get("radius").unwrap_or(16.0);
                        Shape::Circle { radius }
                    }
                    "polygon" => {
                        let verts_table: LuaTable = params.get("vertices")?;
                        let mut vertices = Vec::new();
                        for pair in verts_table.sequence_values::<LuaTable>() {
                            let t = pair?;
                            let x: f32 = t.get("x").or_else(|_| t.get(1))?;
                            let y: f32 = t.get("y").or_else(|_| t.get(2))?;
                            vertices.push(Vec2::new(x, y));
                        }
                        Shape::Polygon { vertices }
                    }
                    "edge" => {
                        let x1: f32 = params.get("x1").unwrap_or(0.0);
                        let y1: f32 = params.get("y1").unwrap_or(0.0);
                        let x2: f32 = params.get("x2").unwrap_or(1.0);
                        let y2: f32 = params.get("y2").unwrap_or(0.0);
                        Shape::Edge {
                            v1: Vec2::new(x1, y1),
                            v2: Vec2::new(x2, y2),
                        }
                    }
                    _ => {
                        let width: f32 = params.get("width").unwrap_or(32.0);
                        let height: f32 = params.get("height").unwrap_or(32.0);
                        Shape::Rect { width, height }
                    }
                };

                let idx = world.add_fixture(
                    this.body_index,
                    shape,
                    density,
                    friction,
                    restitution,
                    sensor,
                );
                return Ok(idx);
            }
            Ok(0usize)
        });

        /// Returns the number of collision fixtures currently attached to the body.
        ///
        /// # Returns
        /// Fixture count as an integer.
        methods.add_method("getFixtureCount", |_, this, ()| {
            let ws = this.worlds.borrow();
            if let Some(world) = ws.get(this.world_index) {
                return Ok(world.fixture_count(this.body_index));
            }
            Ok(0usize)
        });

        methods.add_method(
            "setFixtureFriction",
            |_, this, (idx, friction): (usize, f32)| {
                let mut ws = this.worlds.borrow_mut();
                if let Some(world) = ws.get_mut(this.world_index) {
                    world.set_fixture_friction(this.body_index, idx, friction);
                }
                Ok(())
            },
        );

        methods.add_method(
            "setFixtureRestitution",
            |_, this, (idx, restitution): (usize, f32)| {
                let mut ws = this.worlds.borrow_mut();
                if let Some(world) = ws.get_mut(this.world_index) {
                    world.set_fixture_restitution(this.body_index, idx, restitution);
                }
                Ok(())
            },
        );

        methods.add_method(
            "setFixtureSensor",
            |_, this, (idx, sensor): (usize, bool)| {
                let mut ws = this.worlds.borrow_mut();
                if let Some(world) = ws.get_mut(this.world_index) {
                    world.set_fixture_sensor(this.body_index, idx, sensor);
                }
                Ok(())
            },
        );
    }
}

/// Extract a world index from either a `LuaWorld` UserData or an integer.
pub(super) fn world_index_from_value(val: &LuaValue) -> LuaResult<usize> {
    match val {
        LuaValue::UserData(ud) => {
            let w = ud.borrow::<LuaWorld>()?;
            Ok(w.index)
        }
        LuaValue::Integer(id) => Ok(*id as usize),
        LuaValue::Number(id) => Ok(*id as usize),
        _ => Err(LuaError::RuntimeError("Expected World or world id".into())),
    }
}

/// Extract a body index from either a `LuaBody` UserData or an integer.
pub(super) fn body_index_from_value(val: &LuaValue) -> LuaResult<usize> {
    match val {
        LuaValue::UserData(ud) => {
            let b = ud.borrow::<LuaBody>()?;
            Ok(b.body_index)
        }
        LuaValue::Integer(id) => Ok(*id as usize),
        LuaValue::Number(id) => Ok(*id as usize),
        _ => Err(LuaError::RuntimeError("Expected Body or body id".into())),
    }
}
