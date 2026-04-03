//! Registers the `luna.particle.*` particle-system API.
//!

use std::cell::RefCell;
use std::rc::Rc;
use crate::lua_api::SharedState;
use crate::particle::{AreaDistribution, EmissionShape, ParticleConfig, ParticleSystem, RelativeMode, InsertMode};
use crate::engine::resource_keys::{ParticleKey, TextureKey};
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use slotmap::{SlotMap, Key};
use mlua::prelude::*;

// ── Helper types ──────────────────────────────────────────────────────────
pub(super) fn invalid_particle_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released particle system handle",
        function_name
    ))
}

pub(super) fn ensure_particle_exists(
    particle_systems: &SlotMap<ParticleKey, ParticleSystem>,
    key: ParticleKey,
    function_name: &str,
) -> LuaResult<()> {
    if particle_systems.contains_key(key) {
        Ok(())
    } else {
        Err(invalid_particle_handle(function_name))
    }
}

pub(super) fn require_particle_key(
    particle_systems: &SlotMap<ParticleKey, ParticleSystem>,
    val: &LuaValue,
    function_name: &str,
) -> LuaResult<ParticleKey> {
    let key = particle_key_from_value(val)?;
    ensure_particle_exists(particle_systems, key, function_name)?;
    Ok(key)
}

pub(super) fn particle_system<'a>(
    particle_systems: &'a SlotMap<ParticleKey, ParticleSystem>,
    key: ParticleKey,
    function_name: &str,
) -> LuaResult<&'a ParticleSystem> {
    particle_systems
        .get(key)
        .ok_or_else(|| invalid_particle_handle(function_name))
}

pub(super) fn particle_system_mut<'a>(
    particle_systems: &'a mut SlotMap<ParticleKey, ParticleSystem>,
    key: ParticleKey,
    function_name: &str,
) -> LuaResult<&'a mut ParticleSystem> {
    particle_systems
        .get_mut(key)
        .ok_or_else(|| invalid_particle_handle(function_name))
}

/// Extract a `ParticleKey` from either a `LuaParticleSystem` UserData or a numeric ID.
///
/// Callers validate liveness against their current `SharedState` borrow so stale-handle
/// errors keep the right function context and never re-borrow the state from userdata.
pub(super) fn particle_key_from_value(val: &LuaValue) -> LuaResult<ParticleKey> {
    match val {
        LuaValue::UserData(ud) => {
            let ps = ud.borrow::<LuaParticleSystem>()?;
            Ok(ps.key)
        }
        LuaValue::Integer(id) => Ok(ParticleKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        LuaValue::Number(id) => Ok(ParticleKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        _ => Err(LuaError::RuntimeError(
            "Expected ParticleSystem or particle system id".into(),
        )),
    }
}

/// Helper: parse a Lua color table `{r, g, b, a}` into `[f32; 4]`.
pub(super) fn parse_color(c: &LuaTable, default_a: f32) -> LuaResult<[f32; 4]> {
    let r: f32 = c.get(1i32).unwrap_or(1.0);
    let g: f32 = c.get(2i32).unwrap_or(1.0);
    let b: f32 = c.get(3i32).unwrap_or(1.0);
    let a: f32 = c.get(4i32).unwrap_or(default_a);
    Ok([r, g, b, a])
}

/// Lua UserData wrapper for a particle system resource.
///
/// # Fields
/// - `state` ÔÇö `Rc<RefCell<SharedState>>`.
/// - `key` ÔÇö `ParticleKey`.
///
/// Wraps a `ParticleKey` and shared state reference so the Lua side
/// can call methods like `ps:update(dt)`, `ps:start()` directly.
#[derive(Clone)]
pub struct LuaParticleSystem {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: ParticleKey,
}

impl LunaType for LuaParticleSystem {
    const TYPE_NAME: &'static str = "ParticleSystem";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Drawable", "Object"];
}

impl LuaUserData for LuaParticleSystem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Advances the simulation by `dt` seconds.
        ///
        /// # Parameters
        /// - `dt` ÔÇö `number`.
        methods.add_method("update", |_, this, dt: f32| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:update")?;
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.update(dt);
            }
            Ok(())
        });

        /// Begins execution.
        ///
        /// # Returns
        /// The result.
        methods.add_method("start", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:start")?;
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.start();
            }
            Ok(())
        });

        /// Stops playback.
        ///
        /// # Returns
        /// The result.
        methods.add_method("stop", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:stop")?;
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.stop();
            }
            Ok(())
        });

        /// Pauses playback.
        ///
        /// # Returns
        /// The result.
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:pause")?;
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.pause();
            }
            Ok(())
        });

        /// Resets state to initial values.
        ///
        /// # Returns
        /// The result.
        methods.add_method("reset", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:reset")?;
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.reset();
            }
            Ok(())
        });

        /// Returns the count.
        ///
        /// # Returns
        /// The current count.
        methods.add_method("getCount", |_, this, ()| {
            let st = this.state.borrow();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:getCount")?;
            Ok(st
                .particle_systems
                .get(this.key)
                .map(|ps| ps.count())
                .unwrap_or(0))
        });

        /// Returns `true` if active.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isActive", |_, this, ()| {
            let st = this.state.borrow();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:isActive")?;
            Ok(st
                .particle_systems
                .get(this.key)
                .map(|ps| ps.is_active())
                .unwrap_or(false))
        });

        /// Returns `true` if paused.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:isPaused")?;
            Ok(st
                .particle_systems
                .get(this.key)
                .map(|ps| ps.is_paused())
                .unwrap_or(false))
        });

        /// Returns `true` if stopped.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isStopped", |_, this, ()| {
            let st = this.state.borrow();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:isStopped")?;
            Ok(st
                .particle_systems
                .get(this.key)
                .map(|ps| ps.is_stopped())
                .unwrap_or(true))
        });

        /// Sets the position.
        ///
        /// # Parameters
        /// - `x` ÔÇö `number`.
        /// - `y` ÔÇö `number`.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:setPosition")?;
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.emitter_x = x;
                ps.emitter_y = y;
            }
            Ok(())
        });

        /// Returns the position.
        ///
        /// # Returns
        /// The current position.
        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:getPosition")?;
            match st.particle_systems.get(this.key) {
                Some(ps) => Ok((ps.emitter_x, ps.emitter_y)),
                None => Ok((0.0, 0.0)),
            }
        });

        /// Emits an event.
        ///
        /// # Parameters
        /// - `count` ÔÇö `integer`.
        methods.add_method("emit", |_, this, count: u32| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:emit")?;
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.emit(count);
            }
            Ok(())
        });

        /// Sets the emission rate.
        ///
        /// # Parameters
        /// - `rate` ÔÇö `number`.
        methods.add_method("setEmissionRate", |_, this, rate: f32| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(
                &st.particle_systems,
                this.key,
                "ParticleSystem:setEmissionRate",
            )?;
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.emission_rate = rate;
            }
            Ok(())
        });

        /// Returns a deep copy of this object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clone", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:clone")?;
            let cloned = st
                .particle_systems
                .get(this.key)
                .map(|ps| ps.clone_config())
                .ok_or_else(|| invalid_particle_handle("ParticleSystem:clone"))?;
            let new_key = st.particle_systems.insert(cloned);
            Ok(LuaParticleSystem {
                state: this.state.clone(),
                key: new_key,
            })
        });

        /// Sets the gravity.
        ///
        /// # Parameters
        /// - `gx` ÔÇö `number`.
        /// - `gy` ÔÇö `number`.
        methods.add_method("setGravity", |_, this, (gx, gy): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:setGravity")?;
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.gravity_x = gx;
                ps.config.gravity_y = gy;
            }
            Ok(())
        });

        /// Returns the gravity.
        ///
        /// # Returns
        /// The current gravity.
        methods.add_method("getGravity", |_, this, ()| {
            let st = this.state.borrow();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:getGravity")?;
            match st.particle_systems.get(this.key) {
                Some(ps) => Ok((ps.config.gravity_x, ps.config.gravity_y)),
                None => Ok((0.0, 0.0)),
            }
        });

        /// Sets the alphas.
        ///
        /// # Parameters
        /// - `args` ÔÇö `LuaMultiValue`.
        methods.add_method("setAlphas", |_, this, args: LuaMultiValue| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:setAlphas")?;
            let mut alphas = Vec::new();
            for v in args.iter() {
                if let Some(n) = lua_value_to_f64(v) {
                    alphas.push(n as f32);
                }
            }
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.alpha_keyframes = alphas;
            }
            Ok(())
        });

        /// Returns the alphas.
        ///
        /// # Returns
        /// The current alphas.
        methods.add_method("getAlphas", |lua, this, ()| {
            let st = this.state.borrow();
            ensure_particle_exists(&st.particle_systems, this.key, "ParticleSystem:getAlphas")?;
            match st.particle_systems.get(this.key) {
                Some(ps) => {
                    let t = lua.create_table()?;
                    for (i, a) in ps.config.alpha_keyframes.iter().enumerate() {
                        t.set(i as i32 + 1, *a)?;
                    }
                    Ok(t)
                }
                None => lua.create_table(),
            }
        });

        methods.add_method(
            "setEmissionShape",
            |_, this, (shape, args): (String, Option<LuaTable>)| {
                let mut st = this.state.borrow_mut();
                ensure_particle_exists(
                    &st.particle_systems,
                    this.key,
                    "ParticleSystem:setEmissionShape",
                )?;
                let es = parse_emission_shape(&shape, args.as_ref());
                if let Some(ps) = st.particle_systems.get_mut(this.key) {
                    ps.config.emission_shape = es;
                }
                Ok(())
            },
        );

        /// Returns the emission shape.
        ///
        /// # Returns
        /// The current emission shape.
        methods.add_method("getEmissionShape", |lua, this, ()| {
            let st = this.state.borrow();
            ensure_particle_exists(
                &st.particle_systems,
                this.key,
                "ParticleSystem:getEmissionShape",
            )?;
            match st.particle_systems.get(this.key) {
                Some(ps) => emission_shape_to_lua(lua, &ps.config.emission_shape),
                None => {
                    let t = lua.create_table()?;
                    t.set("type", "point")?;
                    Ok(t)
                }
            }
        });

        /// Sets the relative mode.
        ///
        /// # Parameters
        /// - `mode` ÔÇö `string`.
        methods.add_method("setRelativeMode", |_, this, mode: String| {
            let mut st = this.state.borrow_mut();
            ensure_particle_exists(
                &st.particle_systems,
                this.key,
                "ParticleSystem:setRelativeMode",
            )?;
            let rm = match mode.to_lowercase().as_str() {
                "attached" => RelativeMode::Attached,
                _ => RelativeMode::Detached,
            };
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.relative_mode = rm;
            }
            Ok(())
        });

        /// Returns the relative mode.
        ///
        /// # Returns
        /// The current relative mode.
        methods.add_method("getRelativeMode", |_, this, ()| {
            let st = this.state.borrow();
            ensure_particle_exists(
                &st.particle_systems,
                this.key,
                "ParticleSystem:getRelativeMode",
            )?;
            match st.particle_systems.get(this.key) {
                Some(ps) => Ok(match ps.config.relative_mode {
                    RelativeMode::Attached => "attached".to_string(),
                    RelativeMode::Detached => "detached".to_string(),
                }),
                None => Ok("detached".to_string()),
            }
        });
    }
}

/// Parse an emission shape from a Lua string name and optional parameters table.
pub(super) fn parse_emission_shape(shape: &str, args: Option<&LuaTable>) -> EmissionShape {
    match shape.to_lowercase().as_str() {
        "circle" => {
            let radius = args
                .and_then(|t| t.get::<_, f32>("radius").ok())
                .unwrap_or(10.0);
            let fill = args
                .and_then(|t| t.get::<_, bool>("fill").ok())
                .unwrap_or(true);
            EmissionShape::Circle { radius, fill }
        }
        "rectangle" => {
            let w = args
                .and_then(|t| t.get::<_, f32>("width").ok())
                .unwrap_or(20.0);
            let h = args
                .and_then(|t| t.get::<_, f32>("height").ok())
                .unwrap_or(20.0);
            EmissionShape::Rectangle {
                width: w,
                height: h,
            }
        }
        "ring" => {
            let inner = args
                .and_then(|t| t.get::<_, f32>("innerRadius").ok())
                .unwrap_or(5.0);
            let outer = args
                .and_then(|t| t.get::<_, f32>("outerRadius").ok())
                .unwrap_or(10.0);
            EmissionShape::Ring {
                inner_radius: inner,
                outer_radius: outer,
            }
        }
        "line" => {
            let length = args
                .and_then(|t| t.get::<_, f32>("length").ok())
                .unwrap_or(20.0);
            let angle = args
                .and_then(|t| t.get::<_, f32>("angle").ok())
                .unwrap_or(0.0);
            EmissionShape::Line { length, angle }
        }
        "cone" => {
            let radius = args
                .and_then(|t| t.get::<_, f32>("radius").ok())
                .unwrap_or(10.0);
            let angle = args
                .and_then(|t| t.get::<_, f32>("angle").ok())
                .unwrap_or(0.0);
            let spread = args
                .and_then(|t| t.get::<_, f32>("spread").ok())
                .unwrap_or(0.5);
            EmissionShape::Cone {
                radius,
                angle,
                spread,
            }
        }
        "star" => {
            let points = args
                .and_then(|t| t.get::<_, u32>("points").ok())
                .unwrap_or(5);
            let outer_radius = args
                .and_then(|t| t.get::<_, f32>("outerRadius").ok())
                .unwrap_or(20.0);
            let inner_radius = args
                .and_then(|t| t.get::<_, f32>("innerRadius").ok())
                .unwrap_or(8.0);
            EmissionShape::Star {
                points,
                outer_radius,
                inner_radius,
            }
        }
        "spiral" => {
            let revolutions = args
                .and_then(|t| t.get::<_, f32>("revolutions").ok())
                .unwrap_or(2.0);
            let radius = args
                .and_then(|t| t.get::<_, f32>("radius").ok())
                .unwrap_or(30.0);
            EmissionShape::Spiral {
                revolutions,
                radius,
            }
        }
        _ => EmissionShape::Point,
    }
}

/// Convert an `EmissionShape` to a Lua table with type and parameter fields.
pub(super) fn emission_shape_to_lua<'lua>(lua: &'lua Lua, shape: &EmissionShape) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    match shape {
        EmissionShape::Point => {
            t.set("type", "point")?;
        }
        EmissionShape::Circle { radius, fill } => {
            t.set("type", "circle")?;
            /// Radius on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("radius", *radius)?;
            /// Fill on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("fill", *fill)?;
        }
        EmissionShape::Rectangle { width, height } => {
            t.set("type", "rectangle")?;
            /// Width on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("width", *width)?;
            /// Height on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("height", *height)?;
        }
        EmissionShape::Ring {
            inner_radius,
            outer_radius,
        } => {
            t.set("type", "ring")?;
            /// Inner radius on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("innerRadius", *inner_radius)?;
            /// Outer radius on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("outerRadius", *outer_radius)?;
        }
        EmissionShape::Line { length, angle } => {
            t.set("type", "line")?;
            /// Returns the number of items.
            ///
            /// # Returns
            /// `integer`.
            t.set("length", *length)?;
            /// Angle on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("angle", *angle)?;
        }
        EmissionShape::Cone {
            radius,
            angle,
            spread,
        } => {
            t.set("type", "cone")?;
            /// Radius on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("radius", *radius)?;
            /// Angle on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("angle", *angle)?;
            /// Spread on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("spread", *spread)?;
        }
        EmissionShape::Star {
            points,
            outer_radius,
            inner_radius,
        } => {
            t.set("type", "star")?;
            /// Points on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("points", *points)?;
            /// Outer radius on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("outerRadius", *outer_radius)?;
            /// Inner radius on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("innerRadius", *inner_radius)?;
        }
        EmissionShape::Spiral {
            revolutions,
            radius,
        } => {
            t.set("type", "spiral")?;
            /// Revolutions on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("revolutions", *revolutions)?;
            /// Radius on this ParticleSystem.
            ///
            /// # Returns
            /// The result.
            t.set("radius", *radius)?;
        }
    }
    Ok(t)
}

/// Helper to extract an f64 from a `LuaValue`.
pub(super) fn lua_value_to_f64(v: &LuaValue) -> Option<f64> {
    match v {
        LuaValue::Integer(i) => Some(*i as f64),
        LuaValue::Number(n) => Some(*n),
        _ => None,
    }
}


// ── Extended registrations (second half) ──────────────────────────────────
fn register_ext(
    lua: &Lua,
    particle: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    // ÔöÇÔöÇ setSpread / getSpread ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSpread",
            lua.create_function(move |_, (id_val, spread): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setSpread")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setSpread")?;
                sys.config.spread = spread;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSpread",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getSpread")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getSpread")?;
                Ok(sys.config.spread)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setLinearAcceleration / getLinearAcceleration ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setLinearAcceleration",
            lua.create_function(
                move |_, (id_val, xmin, ymin, xmax, ymax): (LuaValue, f32, f32, f32, f32)| {
                    let mut st = s.borrow_mut();
                    let key = require_particle_key(
                        &st.particle_systems,
                        &id_val,
                        "luna.particle.setLinearAcceleration",
                    )?;
                    let sys = particle_system_mut(
                        &mut st.particle_systems,
                        key,
                        "luna.particle.setLinearAcceleration",
                    )?;
                    sys.config.linear_accel_x_min = xmin;
                    sys.config.linear_accel_y_min = ymin;
                    sys.config.linear_accel_x_max = xmax;
                    sys.config.linear_accel_y_max = ymax;
                    Ok(())
                },
            )?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getLinearAcceleration",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getLinearAcceleration",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getLinearAcceleration",
                )?;
                Ok((
                    sys.config.linear_accel_x_min,
                    sys.config.linear_accel_y_min,
                    sys.config.linear_accel_x_max,
                    sys.config.linear_accel_y_max,
                ))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setRadialAcceleration / getRadialAcceleration ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setRadialAcceleration",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setRadialAcceleration",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setRadialAcceleration",
                )?;
                sys.config.radial_accel_min = min;
                sys.config.radial_accel_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getRadialAcceleration",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getRadialAcceleration",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getRadialAcceleration",
                )?;
                Ok((sys.config.radial_accel_min, sys.config.radial_accel_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setTangentialAcceleration / getTangentialAcceleration ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setTangentialAcceleration",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setTangentialAcceleration",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setTangentialAcceleration",
                )?;
                sys.config.tangential_accel_min = min;
                sys.config.tangential_accel_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getTangentialAcceleration",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getTangentialAcceleration",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getTangentialAcceleration",
                )?;
                Ok((
                    sys.config.tangential_accel_min,
                    sys.config.tangential_accel_max,
                ))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setLinearDamping / getLinearDamping ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setLinearDamping",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setLinearDamping",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setLinearDamping",
                )?;
                sys.config.linear_damping_min = min;
                sys.config.linear_damping_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getLinearDamping",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getLinearDamping",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getLinearDamping")?;
                Ok((sys.config.linear_damping_min, sys.config.linear_damping_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSizes / getSizes ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSizes",
            lua.create_function(move |_, args: LuaMultiValue| {
                let mut iter = args.into_iter();
                let id_val = iter.next().ok_or_else(|| {
                    mlua::Error::RuntimeError(
                        "luna.particle.setSizes: expected particle system id".into(),
                    )
                })?;
                let mut sizes = Vec::new();
                for v in iter {
                    if let Some(f) = lua_value_to_f64(&v) {
                        sizes.push(f as f32);
                    }
                }
                if sizes.is_empty() {
                    return Err(mlua::Error::RuntimeError(
                        "luna.particle.setSizes: expected at least one size value".into(),
                    ));
                }
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setSizes")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setSizes")?;
                sys.config.sizes = sizes;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSizes",
            lua.create_function(move |lua, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getSizes")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getSizes")?;
                let tbl = lua.create_table()?;
                for (i, &sz) in sys.config.sizes.iter().enumerate() {
                    tbl.set(i as i32 + 1, sz)?;
                }
                Ok(LuaValue::Table(tbl))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSizeVariation / getSizeVariation ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSizeVariation",
            lua.create_function(move |_, (id_val, v): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setSizeVariation",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setSizeVariation",
                )?;
                sys.config.size_variation = v.clamp(0.0, 1.0);
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSizeVariation",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getSizeVariation",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getSizeVariation")?;
                Ok(sys.config.size_variation)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setRotation / getRotation ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setRotation",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setRotation",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setRotation",
                )?;
                sys.config.rotation_min = min;
                sys.config.rotation_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getRotation",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getRotation",
                )?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getRotation")?;
                Ok((sys.config.rotation_min, sys.config.rotation_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSpin / getSpin ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSpin",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setSpin")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setSpin")?;
                sys.config.spin_min = min;
                sys.config.spin_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSpin",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getSpin")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getSpin")?;
                Ok((sys.config.spin_min, sys.config.spin_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSpinVariation / getSpinVariation ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSpinVariation",
            lua.create_function(move |_, (id_val, v): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setSpinVariation",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setSpinVariation",
                )?;
                sys.config.spin_variation = v.clamp(0.0, 1.0);
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSpinVariation",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getSpinVariation",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getSpinVariation")?;
                Ok(sys.config.spin_variation)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setRelativeRotation / hasRelativeRotation ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setRelativeRotation",
            lua.create_function(move |_, (id_val, enable): (LuaValue, bool)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setRelativeRotation",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setRelativeRotation",
                )?;
                sys.config.relative_rotation = enable;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "hasRelativeRotation",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.hasRelativeRotation",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.hasRelativeRotation",
                )?;
                Ok(sys.config.relative_rotation)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setColors / getColors ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setColors",
            lua.create_function(move |_, args: LuaMultiValue| {
                let mut iter = args.into_iter();
                let id_val = iter.next().ok_or_else(|| {
                    mlua::Error::RuntimeError(
                        "luna.particle.setColors: expected particle system id".into(),
                    )
                })?;
                let mut colors = Vec::new();
                for v in iter {
                    if let LuaValue::Table(t) = v {
                        if let Ok(c) = parse_color(&t, 1.0) {
                            colors.push(c);
                        }
                    }
                }
                if colors.is_empty() {
                    return Err(mlua::Error::RuntimeError(
                        "luna.particle.setColors: expected at least one color table".into(),
                    ));
                }
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setColors")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setColors")?;
                sys.config.colors = colors;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getColors",
            lua.create_function(move |lua, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getColors")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getColors")?;
                let tbl = lua.create_table()?;
                for (i, c) in sys.config.colors.iter().enumerate() {
                    let ct = lua.create_table()?;
                    ct.set(1i32, c[0])?;
                    ct.set(2i32, c[1])?;
                    ct.set(3i32, c[2])?;
                    ct.set(4i32, c[3])?;
                    tbl.set(i as i32 + 1, ct)?;
                }
                Ok(LuaValue::Table(tbl))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setTexture / getTexture ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setTexture",
            lua.create_function(move |_, (id_val, tex_id): (LuaValue, u64)| {
                let tex_key = TextureKey::from(slotmap::KeyData::from_ffi(tex_id));
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setTexture",
                )?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setTexture")?;
                sys.config.texture_id = Some(tex_key);
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getTexture",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getTexture",
                )?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getTexture")?;
                if let Some(tex) = sys.config.texture_id {
                    Ok(LuaValue::Number(tex.data().as_ffi() as f64))
                } else {
                    Ok(LuaValue::Nil)
                }
            })?,
        )?;
    }

    // ÔöÇÔöÇ setOffset / getOffset ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setOffset",
            lua.create_function(move |_, (id_val, ox, oy): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setOffset")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setOffset")?;
                sys.config.offset_x = ox;
                sys.config.offset_y = oy;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getOffset",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getOffset")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getOffset")?;
                Ok((sys.config.offset_x, sys.config.offset_y))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setInsertMode / getInsertMode ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setInsertMode",
            lua.create_function(move |_, (id_val, mode): (LuaValue, String)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setInsertMode",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setInsertMode",
                )?;
                sys.config.insert_mode = match mode.as_str() {
                    "top" => InsertMode::Top,
                    "bottom" => InsertMode::Bottom,
                    "random" => InsertMode::Random,
                    _ => {
                        return Err(mlua::Error::RuntimeError(format!(
                            "luna.particle.setInsertMode: unknown mode '{}'",
                            mode
                        )));
                    }
                };
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getInsertMode",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getInsertMode",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getInsertMode")?;
                let mode_str = match sys.config.insert_mode {
                    InsertMode::Top => "top",
                    InsertMode::Bottom => "bottom",
                    InsertMode::Random => "random",
                };
                Ok(mode_str.to_string())
            })?,
        )?;
    }

    // ÔöÇÔöÇ setBufferSize / getBufferSize ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setBufferSize",
            lua.create_function(move |_, (id_val, size): (LuaValue, u32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setBufferSize",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setBufferSize",
                )?;
                sys.config.max_particles = size;
                sys.particles.truncate(size as usize);
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getBufferSize",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getBufferSize",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getBufferSize")?;
                Ok(sys.config.max_particles)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setQuads ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setQuads",
            lua.create_function(move |_, (id_val, quads_table): (LuaValue, LuaTable)| {
                let mut quads = Vec::new();
                for i in 1..=256 {
                    match quads_table.get::<_, LuaTable>(i) {
                        Ok(q) => {
                            let x: f32 = q.get(1i32).unwrap_or(0.0);
                            let y: f32 = q.get(2i32).unwrap_or(0.0);
                            let w: f32 = q.get(3i32).unwrap_or(0.0);
                            let h: f32 = q.get(4i32).unwrap_or(0.0);
                            quads.push([x, y, w, h]);
                        }
                        Err(_) => break,
                    }
                }
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setQuads")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setQuads")?;
                sys.config.quads = quads;
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ setGravity ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setGravity",
            lua.create_function(move |_, (id_val, gx, gy): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setGravity",
                )?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setGravity")?;
                sys.config.gravity_x = gx;
                sys.config.gravity_y = gy;
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ getGravity ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getGravity",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getGravity",
                )?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getGravity")?;
                Ok((sys.config.gravity_x, sys.config.gravity_y))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setAlphas ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setAlphas",
            lua.create_function(move |_, args: LuaMultiValue| {
                if args.is_empty() {
                    return Err(LuaError::RuntimeError(
                        "luna.particle.setAlphas: expected at least a particle system handle"
                            .into(),
                    ));
                }
                let id_val = &args[0];
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, id_val, "luna.particle.setAlphas")?;
                let mut alphas = Vec::new();
                for v in args.iter().skip(1) {
                    if let Some(n) = lua_value_to_f64(v) {
                        alphas.push(n as f32);
                    }
                }
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setAlphas")?;
                sys.config.alpha_keyframes = alphas;
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ getAlphas ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getAlphas",
            lua.create_function(move |lua, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getAlphas")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getAlphas")?;
                let t = lua.create_table()?;
                for (i, a) in sys.config.alpha_keyframes.iter().enumerate() {
                    t.set(i as i32 + 1, *a)?;
                }
                Ok(t)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setEmissionShape ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setEmissionShape",
            lua.create_function(
                move |_, (id_val, shape, args): (LuaValue, String, Option<LuaTable>)| {
                    let mut st = s.borrow_mut();
                    let key = require_particle_key(
                        &st.particle_systems,
                        &id_val,
                        "luna.particle.setEmissionShape",
                    )?;
                    let es = parse_emission_shape(&shape, args.as_ref());
                    let sys = particle_system_mut(
                        &mut st.particle_systems,
                        key,
                        "luna.particle.setEmissionShape",
                    )?;
                    sys.config.emission_shape = es;
                    Ok(())
                },
            )?,
        )?;
    }

    // ÔöÇÔöÇ getEmissionShape ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getEmissionShape",
            lua.create_function(move |lua, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getEmissionShape",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getEmissionShape")?;
                emission_shape_to_lua(lua, &sys.config.emission_shape)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setRelativeMode ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setRelativeMode",
            lua.create_function(move |_, (id_val, mode): (LuaValue, String)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setRelativeMode",
                )?;
                let rm = match mode.to_lowercase().as_str() {
                    "attached" => RelativeMode::Attached,
                    _ => RelativeMode::Detached,
                };
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setRelativeMode",
                )?;
                sys.config.relative_mode = rm;
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ getRelativeMode ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getRelativeMode",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getRelativeMode",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getRelativeMode")?;
                Ok(match sys.config.relative_mode {
                    RelativeMode::Attached => "attached".to_string(),
                    RelativeMode::Detached => "detached".to_string(),
                })
            })?,
        )?;
    }

    /// Particle on this ParticleSystem.
    ///
    /// # Returns
    /// The result.
    Ok(())
}


pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let particle = lua.create_table()?;

    // ÔöÇÔöÇ newSystem ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "newSystem",
            lua.create_function(move |_, config: Option<LuaTable>| {
                let mut cfg = ParticleConfig::default();
                if let Some(t) = config {
                    if let Ok(v) = t.get::<_, u32>("maxParticles") {
                        cfg.max_particles = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("emissionRate") {
                        cfg.emission_rate = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("lifetimeMin") {
                        cfg.lifetime_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("lifetimeMax") {
                        cfg.lifetime_max = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("speedMin") {
                        cfg.speed_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("speedMax") {
                        cfg.speed_max = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("direction") {
                        cfg.direction = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("spread") {
                        cfg.spread = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("gravityX") {
                        cfg.gravity_x = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("gravityY") {
                        cfg.gravity_y = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("spinMin") {
                        cfg.spin_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("spinMax") {
                        cfg.spin_max = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("emitterLifetime") {
                        cfg.emitter_lifetime = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("sizeVariation") {
                        cfg.size_variation = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("spinVariation") {
                        cfg.spin_variation = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("rotationMin") {
                        cfg.rotation_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("rotationMax") {
                        cfg.rotation_max = v;
                    }
                    if let Ok(v) = t.get::<_, bool>("relativeRotation") {
                        cfg.relative_rotation = v;
                    }

                    // Multi-stop sizes ÔÇö prefer `sizes` table, fall back to sizeStart/sizeEnd
                    let has_sizes = if let Ok(st) = t.get::<_, LuaTable>("sizes") {
                        let mut sizes = Vec::new();
                        for i in 1..=32 {
                            match st.get::<_, f32>(i) {
                                Ok(v) => sizes.push(v),
                                Err(_) => break,
                            }
                        }
                        if !sizes.is_empty() {
                            cfg.sizes = sizes;
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    };
                    if !has_sizes {
                        // Backward compat: sizeStart/sizeEnd -> sizes vec
                        let s0 = t.get::<_, f32>("sizeStart");
                        let s1 = t.get::<_, f32>("sizeEnd");
                        if let (Ok(start), Ok(end)) = (s0, s1) {
                            cfg.sizes = vec![start, end];
                        } else if let Ok(start) = t.get::<_, f32>("sizeStart") {
                            cfg.sizes = vec![start, cfg.sizes.last().copied().unwrap_or(1.0)];
                        } else if let Ok(end) = t.get::<_, f32>("sizeEnd") {
                            cfg.sizes = vec![cfg.sizes.first().copied().unwrap_or(4.0), end];
                        }
                    }

                    // Multi-stop colors ÔÇö prefer `colors` table, fall back to colorStart/colorEnd
                    let has_colors = if let Ok(ct) = t.get::<_, LuaTable>("colors") {
                        let mut colors = Vec::new();
                        for i in 1..=32 {
                            match ct.get::<_, LuaTable>(i) {
                                Ok(c) => {
                                    if let Ok(col) = parse_color(&c, 1.0) {
                                        colors.push(col);
                                    }
                                }
                                Err(_) => break,
                            }
                        }
                        if !colors.is_empty() {
                            cfg.colors = colors;
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    };
                    if !has_colors {
                        // Backward compat: colorStart/colorEnd -> colors vec
                        let cs = t
                            .get::<_, LuaTable>("colorStart")
                            .ok()
                            .and_then(|c| parse_color(&c, 1.0).ok());
                        let ce = t
                            .get::<_, LuaTable>("colorEnd")
                            .ok()
                            .and_then(|c| parse_color(&c, 0.0).ok());
                        match (cs, ce) {
                            (Some(s), Some(e)) => cfg.colors = vec![s, e],
                            (Some(s), None) => {
                                cfg.colors = vec![
                                    s,
                                    cfg.colors.last().copied().unwrap_or([1.0, 1.0, 1.0, 0.0]),
                                ]
                            }
                            (None, Some(e)) => {
                                cfg.colors = vec![
                                    cfg.colors.first().copied().unwrap_or([1.0, 1.0, 1.0, 1.0]),
                                    e,
                                ]
                            }
                            (None, None) => {}
                        }
                    }

                    // --- Alpha keyframes ---
                    if let Ok(at) = t.get::<_, LuaTable>("alphaKeyframes") {
                        let mut alphas = Vec::new();
                        for i in 1..=32 {
                            match at.get::<_, f32>(i) {
                                Ok(v) => alphas.push(v),
                                Err(_) => break,
                            }
                        }
                        if !alphas.is_empty() {
                            cfg.alpha_keyframes = alphas;
                        }
                    }

                    // --- Emission shape ---
                    if let Ok(shape_str) = t.get::<_, String>("emissionShape") {
                        cfg.emission_shape = match shape_str.to_lowercase().as_str() {
                            "point" => EmissionShape::Point,
                            "circle" => {
                                let radius = t.get::<_, f32>("emissionShapeRadius").unwrap_or(10.0);
                                let fill = t.get::<_, bool>("emissionShapeFill").unwrap_or(true);
                                EmissionShape::Circle { radius, fill }
                            }
                            "rectangle" => {
                                let w = t.get::<_, f32>("emissionShapeWidth").unwrap_or(20.0);
                                let h = t.get::<_, f32>("emissionShapeHeight").unwrap_or(20.0);
                                EmissionShape::Rectangle {
                                    width: w,
                                    height: h,
                                }
                            }
                            "ring" => {
                                let inner =
                                    t.get::<_, f32>("emissionShapeInnerRadius").unwrap_or(5.0);
                                let outer =
                                    t.get::<_, f32>("emissionShapeOuterRadius").unwrap_or(10.0);
                                EmissionShape::Ring {
                                    inner_radius: inner,
                                    outer_radius: outer,
                                }
                            }
                            "line" => {
                                let length = t.get::<_, f32>("emissionShapeLength").unwrap_or(20.0);
                                let angle = t.get::<_, f32>("emissionShapeAngle").unwrap_or(0.0);
                                EmissionShape::Line { length, angle }
                            }
                            "cone" => {
                                let radius = t.get::<_, f32>("emissionShapeRadius").unwrap_or(10.0);
                                let angle = t.get::<_, f32>("emissionShapeAngle").unwrap_or(0.0);
                                let spread = t.get::<_, f32>("emissionShapeSpread").unwrap_or(0.5);
                                EmissionShape::Cone {
                                    radius,
                                    angle,
                                    spread,
                                }
                            }
                            "star" => {
                                let points = t.get::<_, u32>("emissionShapePoints").unwrap_or(5);
                                let outer =
                                    t.get::<_, f32>("emissionShapeOuterRadius").unwrap_or(20.0);
                                let inner =
                                    t.get::<_, f32>("emissionShapeInnerRadius").unwrap_or(8.0);
                                EmissionShape::Star {
                                    points,
                                    outer_radius: outer,
                                    inner_radius: inner,
                                }
                            }
                            "spiral" => {
                                let revolutions =
                                    t.get::<_, f32>("emissionShapeRevolutions").unwrap_or(2.0);
                                let radius = t.get::<_, f32>("emissionShapeRadius").unwrap_or(30.0);
                                EmissionShape::Spiral {
                                    revolutions,
                                    radius,
                                }
                            }
                            _ => EmissionShape::Point,
                        };
                    }

                    // --- Relative mode ---
                    if let Ok(mode_str) = t.get::<_, String>("relativeMode") {
                        cfg.relative_mode = match mode_str.to_lowercase().as_str() {
                            "attached" => RelativeMode::Attached,
                            _ => RelativeMode::Detached,
                        };
                    }

                    // --- New physics fields ---
                    if let Ok(v) = t.get::<_, f32>("turbulence") {
                        cfg.turbulence = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("drag") {
                        cfg.drag = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("orbitSpeed") {
                        cfg.orbit_speed = v;
                    }
                    if let Ok(v) = t.get::<_, u32>("animatedFrames") {
                        cfg.animated_frames = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("frameRate") {
                        cfg.frame_rate = v;
                    }
                    if let Ok(v) = t.get::<_, bool>("colorBySpeed") {
                        cfg.color_by_speed = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("speedColorMin") {
                        cfg.speed_color_min = v;
                    }
                    if let Ok(v) = t.get::<_, f32>("speedColorMax") {
                        cfg.speed_color_max = v;
                    }
                }
                let mut st = s.borrow_mut();
                let key = st.particle_systems.insert(ParticleSystem::new(cfg));
                Ok(LuaParticleSystem {
                    state: s.clone(),
                    key,
                })
            })?,
        )?;
    }

    // ÔöÇÔöÇ update ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "update",
            lua.create_function(move |_, (id_val, dt): (LuaValue, f32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.update")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.update(dt);
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ draw ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "draw",
            lua.create_function(
                move |_, (id_val, x, y): (LuaValue, Option<f32>, Option<f32>)| {
                    let key = particle_key_from_value(&id_val)?;
                    let mut st = s.borrow_mut();
                    ensure_particle_exists(&st.particle_systems, key, "luna.particle.draw")?;
                    let cmds = if let Some(sys) = st.particle_systems.get(key) {
                        sys.draw_commands(x.unwrap_or(0.0), y.unwrap_or(0.0))
                    } else {
                        Vec::new()
                    };
                    st.draw_commands.extend(cmds);
                    Ok(())
                },
            )?,
        )?;
    }

    // ÔöÇÔöÇ start ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "start",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.start")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.start();
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ stop ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "stop",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.stop")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.stop();
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ pause ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "pause",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.pause")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.pause();
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ reset ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "reset",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.reset")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.reset();
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ emit ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "emit",
            lua.create_function(move |_, (id_val, count): (LuaValue, u32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.emit")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.emit(count);
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ clone ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "clone",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                let new_sys = st.particle_systems.get(key).map(|sys| sys.clone_config());
                if let Some(sys) = new_sys {
                    let new_key = st.particle_systems.insert(sys);
                    Ok(LuaParticleSystem {
                        state: s.clone(),
                        key: new_key,
                    })
                } else {
                    Err(mlua::Error::RuntimeError(
                        "luna.particle.clone: invalid particle system handle".into(),
                    ))
                }
            })?,
        )?;
    }

    // ÔöÇÔöÇ release ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "release",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                if st.particle_systems.remove(key).is_some() {
                    Ok(true)
                } else {
                    Err(mlua::Error::RuntimeError(
                        "luna.particle.release: invalid or already-released particle system handle"
                            .into(),
                    ))
                }
            })?,
        )?;
    }

    // ÔöÇÔöÇ getCount ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getCount",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.getCount")?;
                Ok(st.particle_systems.get(key).map(|s| s.count()).unwrap_or(0))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isActive ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isActive",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isActive")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_active())
                    .unwrap_or(false))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isPaused ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isPaused",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isPaused")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_paused())
                    .unwrap_or(false))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isStopped ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isStopped",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isStopped")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_stopped())
                    .unwrap_or(false))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isEmpty ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isEmpty",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isEmpty")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_empty())
                    .unwrap_or(true))
            })?,
        )?;
    }

    // ÔöÇÔöÇ isFull ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "isFull",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.isFull")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.is_full())
                    .unwrap_or(false))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setPosition ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setPosition",
            lua.create_function(move |_, (id_val, x, y): (LuaValue, f32, f32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.setPosition")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.emitter_x = x;
                    sys.emitter_y = y;
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ getPosition ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "getPosition",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.getPosition")?;
                if let Some(sys) = st.particle_systems.get(key) {
                    Ok((sys.emitter_x, sys.emitter_y))
                } else {
                    Ok((0.0, 0.0))
                }
            })?,
        )?;
    }

    // ÔöÇÔöÇ moveTo ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "moveTo",
            lua.create_function(move |_, (id_val, x, y): (LuaValue, f32, f32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.moveTo")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.move_to(x, y);
                }
                Ok(())
            })?,
        )?;
    }

    // ÔöÇÔöÇ setEmissionRate / getEmissionRate ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setEmissionRate",
            lua.create_function(move |_, (id_val, rate): (LuaValue, f32)| {
                let key = particle_key_from_value(&id_val)?;
                let mut st = s.borrow_mut();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.setEmissionRate")?;
                if let Some(sys) = st.particle_systems.get_mut(key) {
                    sys.config.emission_rate = rate;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getEmissionRate",
            lua.create_function(move |_, id_val: LuaValue| {
                let key = particle_key_from_value(&id_val)?;
                let st = s.borrow();
                ensure_particle_exists(&st.particle_systems, key, "luna.particle.getEmissionRate")?;
                Ok(st
                    .particle_systems
                    .get(key)
                    .map(|s| s.config.emission_rate)
                    .unwrap_or(0.0))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setEmissionArea / getEmissionArea ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setEmissionArea",
            lua.create_function(
                move |_,
                      (id_val, dist, w, h, angle, relative): (
                    LuaValue,
                    String,
                    f32,
                    f32,
                    Option<f32>,
                    Option<bool>,
                )| {
                    let mut st = s.borrow_mut();
                    let key = require_particle_key(
                        &st.particle_systems,
                        &id_val,
                        "luna.particle.setEmissionArea",
                    )?;
                    let sys = particle_system_mut(
                        &mut st.particle_systems,
                        key,
                        "luna.particle.setEmissionArea",
                    )?;
                    sys.config.area_distribution = match dist.as_str() {
                        "none" => AreaDistribution::None,
                        "uniform" => AreaDistribution::Uniform,
                        "normal" => AreaDistribution::Normal,
                        "ellipse" => AreaDistribution::Ellipse,
                        "borderellipse" => AreaDistribution::BorderEllipse,
                        "borderrectangle" => AreaDistribution::BorderRectangle,
                        _ => {
                            return Err(mlua::Error::RuntimeError(format!(
                                "luna.particle.setEmissionArea: unknown distribution '{}'",
                                dist
                            )));
                        }
                    };
                    sys.config.area_width = w;
                    sys.config.area_height = h;
                    sys.config.area_angle = angle.unwrap_or(0.0);
                    sys.config.area_direction_relative = relative.unwrap_or(false);
                    Ok(())
                },
            )?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getEmissionArea",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getEmissionArea",
                )?;
                let sys =
                    particle_system(&st.particle_systems, key, "luna.particle.getEmissionArea")?;
                let dist_str = match sys.config.area_distribution {
                    AreaDistribution::None => "none",
                    AreaDistribution::Uniform => "uniform",
                    AreaDistribution::Normal => "normal",
                    AreaDistribution::Ellipse => "ellipse",
                    AreaDistribution::BorderEllipse => "borderellipse",
                    AreaDistribution::BorderRectangle => "borderrectangle",
                };
                Ok((
                    dist_str.to_string(),
                    sys.config.area_width,
                    sys.config.area_height,
                    sys.config.area_angle,
                    sys.config.area_direction_relative,
                ))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setParticleLifetime / getParticleLifetime ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setParticleLifetime",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setParticleLifetime",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setParticleLifetime",
                )?;
                sys.config.lifetime_min = min;
                sys.config.lifetime_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getParticleLifetime",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getParticleLifetime",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getParticleLifetime",
                )?;
                Ok((sys.config.lifetime_min, sys.config.lifetime_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setEmitterLifetime / getEmitterLifetime ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setEmitterLifetime",
            lua.create_function(move |_, (id_val, lifetime): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setEmitterLifetime",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setEmitterLifetime",
                )?;
                sys.config.emitter_lifetime = lifetime;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getEmitterLifetime",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getEmitterLifetime",
                )?;
                let sys = particle_system(
                    &st.particle_systems,
                    key,
                    "luna.particle.getEmitterLifetime",
                )?;
                Ok(sys.config.emitter_lifetime)
            })?,
        )?;
    }

    // ÔöÇÔöÇ setSpeed / getSpeed ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setSpeed",
            lua.create_function(move |_, (id_val, min, max): (LuaValue, f32, f32)| {
                let mut st = s.borrow_mut();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.setSpeed")?;
                let sys =
                    particle_system_mut(&mut st.particle_systems, key, "luna.particle.setSpeed")?;
                sys.config.speed_min = min;
                sys.config.speed_max = max;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getSpeed",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key =
                    require_particle_key(&st.particle_systems, &id_val, "luna.particle.getSpeed")?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getSpeed")?;
                Ok((sys.config.speed_min, sys.config.speed_max))
            })?,
        )?;
    }

    // ÔöÇÔöÇ setDirection / getDirection ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
    {
        let s = Rc::clone(&state);
        particle.set(
            "setDirection",
            lua.create_function(move |_, (id_val, dir): (LuaValue, f32)| {
                let mut st = s.borrow_mut();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.setDirection",
                )?;
                let sys = particle_system_mut(
                    &mut st.particle_systems,
                    key,
                    "luna.particle.setDirection",
                )?;
                sys.config.direction = dir;
                Ok(())
            })?,
        )?;
    }
    {
        let s = Rc::clone(&state);
        particle.set(
            "getDirection",
            lua.create_function(move |_, id_val: LuaValue| {
                let st = s.borrow();
                let key = require_particle_key(
                    &st.particle_systems,
                    &id_val,
                    "luna.particle.getDirection",
                )?;
                let sys = particle_system(&st.particle_systems, key, "luna.particle.getDirection")?;
                Ok(sys.config.direction)
            })?,
        )?;
    }


    register_ext(lua, &particle, state.clone())?;

    luna.set("particle", particle)?;
    Ok(())
}
