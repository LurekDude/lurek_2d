//! Helper functions for the particle API.
//!
//! Private utilities shared between `mod.rs` (register first half)
//! and `ext.rs` (register second half).

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::resource_keys::ParticleKey;
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::lua_api::SharedState;
use crate::particle::{
    EmissionShape, ParticleSystem, RelativeMode,
};
use slotmap::SlotMap;


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
