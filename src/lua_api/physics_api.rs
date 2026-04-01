use crate::lua_api::lua_types::{add_type_methods, LunaType};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::Vec2;
use crate::physics::{Body, BodyType, Shape, World};

/// Parses a body type string into a `BodyType` enum value.
fn parse_body_type(s: &str) -> BodyType {
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
/// - `worlds` — Shared vector of all physics worlds.
/// - `index` — Index of this world in the vector.
/// - `begin_contact_cb` — Optional Lua callback for contact-start events.
/// - `end_contact_cb` — Optional Lua callback for contact-end events.
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
        /// - `dt` — `number`: Elapsed simulation time in seconds.
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
        /// - `beginContact` — Called with (body1, body2) when two bodies start touching.
        /// - `endContact` — Called with (body1, body2) when they separate.
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
        /// - `x` — `number`: Horizontal gravity component.
        /// - `y` — `number`: Vertical gravity component.
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
/// - `worlds` — Shared vector of all physics worlds.
/// - `world_index` — Index of the body's parent world.
/// - `body_index` — Index of this body within the world.
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
        /// - `x` — `number`: Target X position.
        /// - `y` — `number`: Target Y position.
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
        /// - `vx` — Velocity along the X axis in world units per second.
        /// - `vy` — Velocity along the Y axis in world units per second.
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
        /// `number` — angle in radians.
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
        /// - `angle` — `number`: Target angle in radians.
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
        /// - `width` — New shape width in world units.
        /// - `height` — New shape height in world units.
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
        /// - `fx` — `number`: Horizontal force component.
        /// - `fy` — `number`: Vertical force component.
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
        /// - `ix` — `number`: Horizontal impulse.
        /// - `iy` — `number`: Vertical impulse.
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

        // ── Multi-fixture methods ─────────────────────────────────────────────

        /// Adds a collision fixture to the body using the given shape definition table.
        ///
        /// # Parameters
        /// - `def` — Table describing the fixture: shape, density, friction, restitution.
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
fn world_index_from_value(val: &LuaValue) -> LuaResult<usize> {
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
fn body_index_from_value(val: &LuaValue) -> LuaResult<usize> {
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

/// Registers all `luna.physics.*` world and body management functions into the Lua VM.
///
/// # Parameters
/// - `lua` — The Lua VM instance.
/// - `luna` — The top-level `luna` table.
///
/// # Returns
/// `Ok(())` on success.
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
    /// - `world` — World ID.
    /// - `body` — Body ID to resize.
    /// - `width` — New shape width in world units.
    /// - `height` — New shape height in world units.
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
    /// - `world` — World ID.
    /// - `body` — Body ID to look up.
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

    // ── Circle body creation ──────────────────────────────────────────────────

    // luna.physics.newCircleBody(world_id, x, y, radius, body_type) -> body_id
    /// Creates a circle-shaped physics body at the given world position.
    ///
    /// # Parameters
    /// - `world` — World ID.
    /// - `type` — Body type: 'static', 'dynamic', or 'kinematic'.
    /// - `x` — Center X in world units.
    /// - `y` — Center Y in world units.
    /// - `radius` — Circle radius in world units.
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

    // ── Extended body properties ──────────────────────────────────────────────

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
    /// - `world` — World ID.
    /// - `body` — Body ID.
    /// - `mass` — New mass in physics units.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
    /// - `omega` — Angular velocity in radians per second.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
    /// - `fixed` — true to prevent rotation, false to allow it.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
    /// - `damping` — Non-negative damping coefficient.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
    /// - `damping` — Non-negative damping coefficient.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
    /// - `scale` — Gravity scale (1.0 = full gravity, 0.0 = weightless).
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
    /// - `world` — World ID.
    /// - `body` — Body ID to configure.
    /// - `enable` — true to enable CCD, false to disable.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
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

    // ── World management ──────────────────────────────────────────────────────

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
    /// - `world` — World ID.
    /// - `body` — Body ID.
    /// - `allowed` — true to allow sleeping, false to keep the body always awake.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
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
    /// - `world` — World ID that owns the joint.
    /// - `joint` — Joint ID to destroy.
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

    // ── Collision events ──────────────────────────────────────────────────────

    // luna.physics.getCollisions(world_id) -> table of {body_a, body_b}
    /// Returns all collision pairs currently overlapping in the physics world.
    ///
    /// # Parameters
    /// - `world` — World ID.
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

    // ── Raycasting ────────────────────────────────────────────────────────────

    // luna.physics.raycast(world_id, x1, y1, x2, y2) -> {body_id, x, y, nx, ny, toi} or nil
    /// Casts a ray from the origin in the given direction and returns the first body hit.
    ///
    /// # Parameters
    /// - `world` — World ID to cast in.
    /// - `x1` — Ray origin X in world units.
    /// - `y1` — Ray origin Y in world units.
    /// - `x2` — Ray end X in world units.
    /// - `y2` — Ray end Y in world units.
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
    /// - `world` — World ID to cast in.
    /// - `x1` — Ray origin X in world units.
    /// - `y1` — Ray origin Y in world units.
    /// - `x2` — Ray end X in world units.
    /// - `y2` — Ray end Y in world units.
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

    // ── Spatial queries ───────────────────────────────────────────────────────

    // luna.physics.queryBoundingBox(world_id, x, y, w, h) -> table of body_ids
    /// Returns all bodies whose axis-aligned bounding boxes overlap the given query rectangle.
    ///
    /// # Parameters
    /// - `world` — World ID.
    /// - `x1` — Left edge of the query box in world units.
    /// - `y1` — Top edge of the query box in world units.
    /// - `x2` — Right edge in world units.
    /// - `y2` — Bottom edge in world units.
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

    // ── Joint API ─────────────────────────────────────────────────────────────

    // luna.physics.addRevoluteJoint(world_id, bodyA, bodyB, ax, ay) -> joint_id
    /// Adds a revolute joint that constrains two bodies to rotate around a shared anchor point.
    ///
    /// # Parameters
    /// - `world` — World ID.
    /// - `body1` — First body ID.
    /// - `body2` — Second body ID.
    /// - `ax`, `ay` — World-space anchor point to revolve around.
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
    /// - `world` — World ID.
    /// - `body1` — First body ID.
    /// - `body2` — Second body ID.
    /// - `x1`, `y1` — Anchor on body1 in local coordinates.
    /// - `x2`, `y2` — Anchor on body2 in local coordinates.
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
    /// - `world` — World ID.
    /// - `body1` — First body ID.
    /// - `body2` — Second body ID.
    /// - `ax`, `ay` — World-space anchor point.
    /// - `axisX`, `axisY` — Slide axis direction (unit vector).
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
    /// - `world` — World ID.
    /// - `body1` — First body ID.
    /// - `body2` — Second body ID.
    /// - `ax`, `ay` — World-space anchor point for the weld.
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
    /// - `world` — World ID.
    /// - `body1` — First body ID.
    /// - `body2` — Second body ID.
    /// - `x1`, `y1` — Anchor on body1 in local coordinates.
    /// - `x2`, `y2` — Anchor on body2 in local coordinates.
    /// - `maxLength` — Maximum allowed distance in world units.
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
    /// - `world` — World ID.
    /// - `joint` — Joint ID to query.
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

    // ── Phase 07 Part 2: Extended body constructors ───────────────────────────

    // luna.physics.newPolygonBody(world_id, x, y, vertices, body_type) -> body_id
    // vertices = {x1, y1, x2, y2, ...} flat table
    /// Creates a convex polygon body defined by a list of local-space vertices.
    ///
    /// # Parameters
    /// - `world` — World ID.
    /// - `type` — Body type: 'static', 'dynamic', or 'kinematic'.
    /// - `x` — World X position for the body's origin.
    /// - `y` — World Y position for the body's origin.
    /// - `vertices` — Flat or nested table of (x, y) polygon vertices in local space.
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
    /// - `world` — World ID.
    /// - `x1`, `y1` — Start point in world units.
    /// - `x2`, `y2` — End point in world units.
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
    /// - `world` — World ID.
    /// - `vertices` — Flat or nested table of (x, y) chain vertices.
    /// - `closed` — Optional boolean; true to close the chain into a loop.
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

    // ── Phase 07 Part 2: Additional joint types ──────────────────────────────

    // luna.physics.addWheelJoint(world_id, bodyA, bodyB, ax, ay, axisX, axisY) -> joint_id
    /// Adds a wheel joint combining a revolute motor and a prismatic spring for vehicle suspension.
    ///
    /// # Parameters
    /// - `world` — World ID.
    /// - `body1` — Chassis body ID.
    /// - `body2` — Wheel body ID.
    /// - `ax`, `ay` — World-space anchor point.
    /// - `axisX`, `axisY` — Suspension axis direction.
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
    /// - `world` — World ID.
    /// - `body1` — First body ID.
    /// - `body2` — Second body ID.
    /// - `ax`, `ay` — World-space anchor point.
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
    /// - `world` — World ID.
    /// - `body1` — First body ID (reference).
    /// - `body2` — Second body ID (driven).
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
    /// - `world` — World ID.
    /// - `body` — Body ID to control.
    /// - `x`, `y` — Initial target position in world coordinates.
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
    /// - `world` — World ID.
    /// - `joint` — Mouse joint ID.
    /// - `x` — New target X in world units.
    /// - `y` — New target Y in world units.
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
    /// - `world` — World ID.
    /// - `body1` — First body ID.
    /// - `body2` — Second body ID.
    /// - `gx1`, `gy1` — Ground anchor for body1 in world coordinates.
    /// - `gx2`, `gy2` — Ground anchor for body2 in world coordinates.
    /// - `ax1`, `ay1` — Body1 attachment point in local coordinates.
    /// - `ax2`, `ay2` — Body2 attachment point in local coordinates.
    /// - `ratio` — Pulley ratio (1.0 = symmetric).
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
    /// - `world` — World ID.
    /// - `joint1` — First revolute or prismatic joint ID.
    /// - `joint2` — Second revolute or prismatic joint ID.
    /// - `ratio` — Gear ratio between the two joints.
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

    // ── Phase 07 Part 2: Joint property accessors ────────────────────────────

    // luna.physics.setJointMotorSpeed(world_id, joint_id, speed)
    /// Sets the target motor speed for a motorized revolute or prismatic joint.
    ///
    /// # Parameters
    /// - `world` — World ID.
    /// - `joint` — Joint ID.
    /// - `speed` — Target speed in rad/s (revolute) or m/s (prismatic).
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
    /// - `world` — World ID.
    /// - `joint` — Joint ID.
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
    /// - `world` — World ID.
    /// - `joint` — Joint ID.
    /// - `enabled` — true to enforce limits, false to disable them.
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
    /// - `world` — World ID.
    /// - `joint` — Joint ID.
    /// - `lower` — Lower limit value (angle in radians or distance).
    /// - `upper` — Upper limit value.
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
    /// - `world` — World ID.
    /// - `joint` — Joint ID.
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
    /// - `world` — World ID.
    /// - `joint` — Joint ID.
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

    // ── Phase 07 Part 2: Meter scaling ───────────────────────────────────────

    // luna.physics.setMeter(world_id, pixels_per_meter)
    /// Sets the pixels-per-meter ratio used to convert physics world units to screen pixels.
    ///
    /// # Parameters
    /// - `meter` — Number of pixels that represent one physics meter.
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
    /// - `world` — World ID to query.
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

    // ── Phase 07 Part 2: Contact queries ─────────────────────────────────────

    // luna.physics.getContacts(world_id) -> table of {bodyA, bodyB, nx, ny, touching}
    /// Returns a table of all currently active collision contact manifolds in the world.
    ///
    /// # Parameters
    /// - `world` — World ID.
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
    /// - `world` — World ID.
    /// - `body` — Body ID to query.
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

    // ── New Phase 07 bindings: body property getters ─────────────────────────

    // luna.physics.getGravityScale(world_id, body_id) -> scale
    /// Returns the per-body gravity scale factor applied to the world gravity vector.
    ///
    /// # Parameters
    /// - `world` — World ID.
    /// - `body` — Body ID.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
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
    /// - `world` — World ID.
    /// - `body` — Body ID.
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
    /// - `world` — World ID.
    /// - `body` — Target body ID.
    /// - `fx`, `fy` — Force vector in Newtons.
    /// - `px`, `py` — World-space point of application.
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
    /// - `world` — World ID.
    /// - `body` — Target body ID.
    /// - `impulse` — Angular impulse magnitude in N·m·s.
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
    /// - `world` — World ID.
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
    /// - `world` — World ID to query.
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
    /// - `world` — World ID to query.
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
    luna.set("physics", physics)?;
    Ok(())
}
