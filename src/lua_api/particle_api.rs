//! `luna.particles` — Emitter-based 2D particle systems and trail ribbons.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::engine::resource_keys::ParticleKey;
use crate::particle::{ParticleConfig, ParticleSystem, Trail};

// -------------------------------------------------------------------------------
// Config table → ParticleConfig marshalling
// -------------------------------------------------------------------------------


// -------------------------------------------------------------------------------
// LuaParticleSystem UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a particle system stored in SharedState.
///
/// # Fields
/// - `state` — `Rc<RefCell<SharedState>>`. Shared engine state.
/// - `key` — `ParticleKey`. Slot key for the backing particle system.
#[derive(Clone)]
pub struct LuaParticleSystem {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: ParticleKey,
}

impl LuaUserData for LuaParticleSystem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Advances the particle simulation by dt seconds.
        /// @param dt : number
        /// @return nil
        methods.add_method("update", |_, this, dt: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.update(dt);
            }
            Ok(())
        });

        // -- emit --
        /// Emits a burst of the given number of particles.
        /// @param count : integer
        /// @return nil
        methods.add_method("emit", |_, this, count: u32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.emit(count);
            }
            Ok(())
        });

        // -- start --
        /// Starts or restarts particle emission.
        /// @return nil
        methods.add_method("start", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.start();
            }
            Ok(())
        });

        // -- stop --
        /// Stops particle emission immediately.
        /// @return nil
        methods.add_method("stop", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.stop();
            }
            Ok(())
        });

        // -- pause --
        /// Pauses the emitter.
        /// @return nil
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.pause();
            }
            Ok(())
        });

        // -- resume --
        /// Resumes a paused emitter.
        /// @return nil
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.resume();
            }
            Ok(())
        });

        // -- reset --
        /// Removes all particles and resets the emitter.
        /// @return nil
        methods.add_method("reset", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.reset();
            }
            Ok(())
        });

        // -- moveTo --
        /// Moves the emitter to the given world position.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("moveTo", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.move_to(x, y);
            }
            Ok(())
        });

        // -- count --
        /// Returns the number of living particles.
        /// @return integer
        methods.add_method("count", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).map_or(0, |ps| ps.count()))
        });

        // -- isActive --
        /// Returns true if the emitter is currently emitting or has live particles.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_some_and(|ps| ps.is_active()))
        });

        // -- isPaused --
        /// Returns true if the emitter is paused.
        /// @return boolean
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_some_and(|ps| ps.is_paused()))
        });

        // -- isStopped --
        /// Returns true if the emitter is stopped.
        /// @return boolean
        methods.add_method("isStopped", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_none_or(|ps| ps.is_stopped()))
        });

        // -- isEmpty --
        /// Returns true if there are no live particles.
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_none_or(|ps| ps.is_empty()))
        });

        // -- isFull --
        /// Returns true if the system has reached max_particles.
        /// @return boolean
        methods.add_method("isFull", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_some_and(|ps| ps.is_full()))
        });

        // -- release --
        /// Removes the particle system from the engine, freeing its slot.
        /// @return nil
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            st.particle_systems.remove(this.key);
            Ok(true)
        });

        // -- getCount --
        /// Returns the number of living particles (alias for count).
        /// @return integer
        methods.add_method("getCount", |_, this, ()| {
            let st = this.state.borrow();
            let key = this.key;
            if !st.particle_systems.contains_key(key) {
                return Err(LuaError::runtime("ParticleSystem handle is invalid (released)"));
            }
            Ok(st.particle_systems.get(key).map_or(0, |ps| ps.count() as i64))
        });

        // -- type --
        /// Returns the type name "ParticleSystem".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("ParticleSystem"));

        // -- typeOf --
        /// Returns true if this matches the given type name.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ParticleSystem" || name == "Drawable" || name == "Object")
        });

        // -- setPosition --
        /// Sets the emitter world position.
        /// @param x : number
        /// @param y : number
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.emitter_x = x;
                ps.emitter_y = y;
            }
            Ok(())
        });

        // -- getPosition --
        /// Returns the emitter world position.
        /// @return number, number
        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let (x, y) = st.particle_systems.get(this.key).map_or((0.0_f32, 0.0_f32), |ps| (ps.emitter_x, ps.emitter_y));
            Ok((x, y))
        });

        // -- setEmissionRate --
        /// Sets particles emitted per second.
        /// @param rate : number
        methods.add_method("setEmissionRate", |_, this, rate: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.emission_rate = rate;
            }
            Ok(())
        });

        // -- getEmissionRate --
        /// Returns particles emitted per second.
        /// @return number
        methods.add_method("getEmissionRate", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).map_or(0.0_f32, |ps| ps.config.emission_rate))
        });

        // -- setParticleLifetime --
        /// Sets min and max particle lifetime in seconds.
        /// @param min : number
        /// @param max : number
        methods.add_method("setParticleLifetime", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.lifetime_min = min;
                ps.config.lifetime_max = max;
            }
            Ok(())
        });

        // -- getParticleLifetime --
        /// Returns min and max particle lifetime.
        /// @return number, number
        methods.add_method("getParticleLifetime", |_, this, ()| {
            let st = this.state.borrow();
            let (mn, mx) = st.particle_systems.get(this.key).map_or((1.0_f32, 2.0_f32), |ps| (ps.config.lifetime_min, ps.config.lifetime_max));
            Ok((mn, mx))
        });

        // -- setEmitterLifetime --
        /// Sets how long the emitter runs before auto-stopping. Negative = infinite.
        /// @param t : number
        methods.add_method("setEmitterLifetime", |_, this, t: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.emitter_lifetime = t;
            }
            Ok(())
        });

        // -- getEmitterLifetime --
        /// Returns the emitter lifetime.
        /// @return number
        methods.add_method("getEmitterLifetime", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).map_or(-1.0_f32, |ps| ps.config.emitter_lifetime))
        });

        // -- setSpeed --
        /// Sets min/max initial speed.
        /// @param min : number
        /// @param max : number
        methods.add_method("setSpeed", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.speed_min = min;
                ps.config.speed_max = max;
            }
            Ok(())
        });

        // -- getSpeed --
        /// Returns min/max initial speed.
        /// @return number, number
        methods.add_method("getSpeed", |_, this, ()| {
            let st = this.state.borrow();
            let (mn, mx) = st.particle_systems.get(this.key).map_or((50.0_f32, 100.0_f32), |ps| (ps.config.speed_min, ps.config.speed_max));
            Ok((mn, mx))
        });

        // -- setDirection --
        /// Sets emission direction in radians.
        /// @param dir : number
        methods.add_method("setDirection", |_, this, dir: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.direction = dir;
            }
            Ok(())
        });

        // -- getDirection --
        /// Returns emission direction in radians.
        /// @return number
        methods.add_method("getDirection", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).map_or(0.0_f32, |ps| ps.config.direction))
        });

        // -- setSpread --
        /// Sets emission spread (half-angle cone) in radians.
        /// @param spread : number
        methods.add_method("setSpread", |_, this, spread: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.spread = spread;
            }
            Ok(())
        });

        // -- getSpread --
        /// Returns emission spread.
        /// @return number
        methods.add_method("getSpread", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).map_or(0.0_f32, |ps| ps.config.spread))
        });

        // -- setLinearAcceleration --
        /// Sets linear acceleration range.
        /// @param xmin : number
        /// @param ymin : number
        /// @param xmax : number
        /// @param ymax : number
        methods.add_method("setLinearAcceleration", |_, this, (xmin, ymin, xmax, ymax): (f32, f32, f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.linear_accel_x_min = xmin;
                ps.config.linear_accel_y_min = ymin;
                ps.config.linear_accel_x_max = xmax;
                ps.config.linear_accel_y_max = ymax;
            }
            Ok(())
        });

        // -- getLinearAcceleration --
        /// Returns linear acceleration range.
        /// @return number, number, number, number
        methods.add_method("getLinearAcceleration", |_, this, ()| {
            let st = this.state.borrow();
            let (xmin, ymin, xmax, ymax) = st.particle_systems.get(this.key).map_or((0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32), |ps| (ps.config.linear_accel_x_min, ps.config.linear_accel_y_min, ps.config.linear_accel_x_max, ps.config.linear_accel_y_max));
            Ok((xmin, ymin, xmax, ymax))
        });

        // -- setRadialAcceleration --
        /// Sets radial acceleration range.
        /// @param min : number
        /// @param max : number
        methods.add_method("setRadialAcceleration", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.radial_accel_min = min;
                ps.config.radial_accel_max = max;
            }
            Ok(())
        });

        // -- getRadialAcceleration --
        /// Returns radial acceleration range.
        /// @return number, number
        methods.add_method("getRadialAcceleration", |_, this, ()| {
            let st = this.state.borrow();
            let (mn, mx) = st.particle_systems.get(this.key).map_or((0.0_f32, 0.0_f32), |ps| (ps.config.radial_accel_min, ps.config.radial_accel_max));
            Ok((mn, mx))
        });

        // -- setTangentialAcceleration --
        /// Sets tangential acceleration range.
        /// @param min : number
        /// @param max : number
        methods.add_method("setTangentialAcceleration", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.tangential_accel_min = min;
                ps.config.tangential_accel_max = max;
            }
            Ok(())
        });

        // -- getTangentialAcceleration --
        /// Returns tangential acceleration range.
        /// @return number, number
        methods.add_method("getTangentialAcceleration", |_, this, ()| {
            let st = this.state.borrow();
            let (mn, mx) = st.particle_systems.get(this.key).map_or((0.0_f32, 0.0_f32), |ps| (ps.config.tangential_accel_min, ps.config.tangential_accel_max));
            Ok((mn, mx))
        });

        // -- setLinearDamping --
        /// Sets linear damping range.
        /// @param min : number
        /// @param max : number
        methods.add_method("setLinearDamping", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.linear_damping_min = min;
                ps.config.linear_damping_max = max;
            }
            Ok(())
        });

        // -- getLinearDamping --
        /// Returns linear damping range.
        /// @return number, number
        methods.add_method("getLinearDamping", |_, this, ()| {
            let st = this.state.borrow();
            let (mn, mx) = st.particle_systems.get(this.key).map_or((0.0_f32, 0.0_f32), |ps| (ps.config.linear_damping_min, ps.config.linear_damping_max));
            Ok((mn, mx))
        });

        // -- setSizes --
        /// Sets size keyframes (varargs: each number is one keyframe).
        /// @param ... : number
        methods.add_method("setSizes", |_, this, sizes: LuaMultiValue| {
            let mut v: Vec<f32> = Vec::new();
            for val in sizes.iter() {
                if let LuaValue::Number(n) = val {
                    v.push(*n as f32);
                } else if let LuaValue::Integer(n) = val {
                    v.push(*n as f32);
                }
            }
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.sizes = v;
            }
            Ok(())
        });

        // -- getSizes --
        /// Returns size keyframes as a Lua table.
        /// @return table
        methods.add_method("getSizes", |lua, this, ()| {
            let st = this.state.borrow();
            let sizes = st.particle_systems.get(this.key).map_or(vec![4.0_f32, 1.0_f32], |ps| ps.config.sizes.clone());
            let tbl = lua.create_table()?;
            for (i, s) in sizes.iter().enumerate() {
                tbl.set(i + 1, *s)?;
            }
            Ok(tbl)
        });

        // -- setSizeVariation --
        /// Sets size variation (0–1).
        /// @param v : number
        methods.add_method("setSizeVariation", |_, this, v: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.size_variation = v;
            }
            Ok(())
        });

        // -- getSizeVariation --
        /// Returns size variation.
        /// @return number
        methods.add_method("getSizeVariation", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).map_or(0.0_f32, |ps| ps.config.size_variation))
        });

        // -- setRotation --
        /// Sets initial rotation range in radians.
        /// @param min : number
        /// @param max : number
        methods.add_method("setRotation", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.rotation_min = min;
                ps.config.rotation_max = max;
            }
            Ok(())
        });

        // -- getRotation --
        /// Returns initial rotation range.
        /// @return number, number
        methods.add_method("getRotation", |_, this, ()| {
            let st = this.state.borrow();
            let (mn, mx) = st.particle_systems.get(this.key).map_or((0.0_f32, 0.0_f32), |ps| (ps.config.rotation_min, ps.config.rotation_max));
            Ok((mn, mx))
        });

        // -- setSpin --
        /// Sets angular velocity range.
        /// @param min : number
        /// @param max : number
        methods.add_method("setSpin", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.spin_min = min;
                ps.config.spin_max = max;
            }
            Ok(())
        });

        // -- getSpin --
        /// Returns angular velocity range.
        /// @return number, number
        methods.add_method("getSpin", |_, this, ()| {
            let st = this.state.borrow();
            let (mn, mx) = st.particle_systems.get(this.key).map_or((0.0_f32, 0.0_f32), |ps| (ps.config.spin_min, ps.config.spin_max));
            Ok((mn, mx))
        });

        // -- setSpinVariation --
        /// Sets spin variation (0–1).
        /// @param v : number
        methods.add_method("setSpinVariation", |_, this, v: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.spin_variation = v;
            }
            Ok(())
        });

        // -- getSpinVariation --
        /// Returns spin variation.
        /// @return number
        methods.add_method("getSpinVariation", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).map_or(0.0_f32, |ps| ps.config.spin_variation))
        });

        // -- setRelativeRotation --
        /// Sets whether particle rotation follows velocity direction.
        /// @param v : boolean
        methods.add_method("setRelativeRotation", |_, this, v: bool| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.relative_rotation = v;
            }
            Ok(())
        });

        // -- hasRelativeRotation --
        /// Returns whether relative rotation is enabled.
        /// @return boolean
        methods.add_method("hasRelativeRotation", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).is_some_and(|ps| ps.config.relative_rotation))
        });

        // -- setColors --
        /// Sets color keyframes. Each arg is a table {r, g, b, a}.
        /// @param ... : table
        methods.add_method("setColors", |_, this, colors: LuaMultiValue| {
            let mut v: Vec<[f32; 4]> = Vec::new();
            for val in colors.iter() {
                if let LuaValue::Table(t) = val {
                    let r: f32 = t.get::<_, Option<f32>>(1)?.unwrap_or(1.0);
                    let g: f32 = t.get::<_, Option<f32>>(2)?.unwrap_or(1.0);
                    let b: f32 = t.get::<_, Option<f32>>(3)?.unwrap_or(1.0);
                    let a: f32 = t.get::<_, Option<f32>>(4)?.unwrap_or(1.0);
                    v.push([r, g, b, a]);
                }
            }
            if !v.is_empty() {
                let mut st = this.state.borrow_mut();
                if let Some(ps) = st.particle_systems.get_mut(this.key) {
                    ps.config.colors = v;
                }
            }
            Ok(())
        });

        // -- getColors --
        /// Returns color keyframes as a table of {r,g,b,a} tables.
        /// @return table
        methods.add_method("getColors", |lua, this, ()| {
            let st = this.state.borrow();
            let colors = st.particle_systems.get(this.key).map_or(vec![], |ps| ps.config.colors.clone());
            let tbl = lua.create_table()?;
            for (i, c) in colors.iter().enumerate() {
                let ct = lua.create_table()?;
                ct.set(1, c[0])?;
                ct.set(2, c[1])?;
                ct.set(3, c[2])?;
                ct.set(4, c[3])?;
                tbl.set(i + 1, ct)?;
            }
            Ok(tbl)
        });

        // -- setOffset --
        /// Sets the render origin offset.
        /// @param ox : number
        /// @param oy : number
        methods.add_method("setOffset", |_, this, (ox, oy): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.offset_x = ox;
                ps.config.offset_y = oy;
            }
            Ok(())
        });

        // -- getOffset --
        /// Returns the render origin offset.
        /// @return number, number
        methods.add_method("getOffset", |_, this, ()| {
            let st = this.state.borrow();
            let (ox, oy) = st.particle_systems.get(this.key).map_or((0.0_f32, 0.0_f32), |ps| (ps.config.offset_x, ps.config.offset_y));
            Ok((ox, oy))
        });

        // -- setInsertMode --
        /// Sets the insert mode: "top", "bottom", or "random".
        /// @param mode : string
        methods.add_method("setInsertMode", |_, this, mode: String| {
            use crate::particle::InsertMode;
            let im = match mode.as_str() {
                "bottom" => InsertMode::Bottom,
                "random" => InsertMode::Random,
                _ => InsertMode::Top,
            };
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.insert_mode = im;
            }
            Ok(())
        });

        // -- getInsertMode --
        /// Returns the insert mode as a string.
        /// @return string
        methods.add_method("getInsertMode", |_, this, ()| {
            use crate::particle::InsertMode;
            let st = this.state.borrow();
            let mode = st.particle_systems.get(this.key).map_or("top", |ps| match ps.config.insert_mode {
                InsertMode::Bottom => "bottom",
                InsertMode::Random => "random",
                _ => "top",
            });
            Ok(mode.to_string())
        });

        // -- setBufferSize --
        /// Sets the maximum number of particles (resizes the pool).
        /// @param n : integer
        methods.add_method("setBufferSize", |_, this, n: u32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.max_particles = n;
                ps.particles.reserve(n as usize);
            }
            Ok(())
        });

        // -- getBufferSize --
        /// Returns the maximum particle count.
        /// @return integer
        methods.add_method("getBufferSize", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).map_or(256_u32, |ps| ps.config.max_particles))
        });

        // -- setEmissionArea --
        /// Sets emission area distribution and size.
        /// @param dist : string  "none"|"uniform"|"normal"|"ellipse"|"borderellipse"|"borderrectangle"
        /// @param w : number
        /// @param h : number
        /// @param angle : number?
        /// @param dir_relative : boolean?
        methods.add_method("setEmissionArea", |_, this, (dist, w, h, angle, dir_rel): (String, f32, f32, Option<f32>, Option<bool>)| {
            use crate::particle::AreaDistribution;
            let d = match dist.to_lowercase().as_str() {
                "uniform" => AreaDistribution::Uniform,
                "normal" => AreaDistribution::Normal,
                "ellipse" => AreaDistribution::Ellipse,
                "borderellipse" => AreaDistribution::BorderEllipse,
                "borderrectangle" => AreaDistribution::BorderRectangle,
                _ => AreaDistribution::None,
            };
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.area_distribution = d;
                ps.config.area_width = w;
                ps.config.area_height = h;
                if let Some(a) = angle { ps.config.area_angle = a; }
                if let Some(dr) = dir_rel { ps.config.area_direction_relative = dr; }
            }
            Ok(())
        });

        // -- getEmissionArea --
        /// Returns emission area: dist-string, w, h.
        /// @return string, number, number
        methods.add_method("getEmissionArea", |_, this, ()| {
            use crate::particle::AreaDistribution;
            let st = this.state.borrow();
            let (dist_str, w, h) = st.particle_systems.get(this.key).map_or(("none".to_string(), 0.0_f32, 0.0_f32), |ps| {
                let d = match ps.config.area_distribution {
                    AreaDistribution::Uniform => "uniform",
                    AreaDistribution::Normal => "normal",
                    AreaDistribution::Ellipse => "ellipse",
                    AreaDistribution::BorderEllipse => "borderellipse",
                    AreaDistribution::BorderRectangle => "borderrectangle",
                    _ => "none",
                };
                (d.to_string(), ps.config.area_width, ps.config.area_height)
            });
            Ok((dist_str, w, h))
        });

        // -- setShape --
        /// Sets the particle draw shape.
        /// @param shape : string  "square"|"circle"|"triangle"|"spark"|"diamond"
        methods.add_method("setShape", |_, this, shape: String| {
            use crate::particle::ParticleShape;
            let s = match shape.as_str() {
                "circle" => ParticleShape::Circle,
                "triangle" => ParticleShape::Triangle,
                "spark" => ParticleShape::Spark,
                "diamond" => ParticleShape::Diamond,
                "square" => ParticleShape::Square,
                other => return Err(LuaError::runtime(format!("unknown particle shape: {other}"))),
            };
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.shape = s;
            }
            Ok(())
        });

        // -- getShape --
        /// Returns the particle draw shape as a string.
        /// @return string
        methods.add_method("getShape", |_, this, ()| {
            use crate::particle::ParticleShape;
            let st = this.state.borrow();
            let shape = st.particle_systems.get(this.key).map_or("square", |ps| match ps.config.shape {
                ParticleShape::Circle => "circle",
                ParticleShape::Triangle => "triangle",
                ParticleShape::Spark => "spark",
                ParticleShape::Diamond => "diamond",
                _ => "square",
            });
            Ok(shape.to_string())
        });

        // -- getGravity --
        /// Returns gravity (x, y).
        /// @return number, number
        methods.add_method("getGravity", |_, this, ()| {
            let st = this.state.borrow();
            let (gx, gy) = st.particle_systems.get(this.key).map_or((0.0_f32, 0.0_f32), |ps| (ps.config.gravity_x, ps.config.gravity_y));
            Ok((gx, gy))
        });

        // -- setGravity --
        /// Sets gravity (x, y).
        /// @param gx : number
        /// @param gy : number
        methods.add_method("setGravity", |_, this, (gx, gy): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.gravity_x = gx;
                ps.config.gravity_y = gy;
            }
            Ok(())
        });

        // -- clone --
        /// Creates a copy of this particle system (config only, no live particles).
        /// @return ParticleSystem
        methods.add_method("clone", |lua, this, ()| {
            let (state, new_ps) = {
                let st = this.state.borrow();
                let ps = st.particle_systems.get(this.key)
                    .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
                (this.state.clone(), ps.clone_config())
            };
            let key = state.borrow_mut().particle_systems.insert(new_ps);
            lua.create_userdata(LuaParticleSystem { state, key })
        });
    }
}

// -------------------------------------------------------------------------------
// LuaTrail UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Trail`] ribbon effect.
pub struct LuaTrail {
    inner: Trail,
}

impl LuaUserData for LuaTrail {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- pushPoint --
        /// Appends a new point to the trail head.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method_mut("pushPoint", |_, this, (x, y): (f32, f32)| {
            this.inner.push_point(x, y);
            Ok(())
        });

        // -- update --
        /// Ages trail points and removes expired ones.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- setWidth --
        /// Sets the start and end width of the trail ribbon.
        /// @param start_width : number
        /// @param end_width : number
        /// @return nil
        methods.add_method_mut("setWidth", |_, this, (start, end): (f32, Option<f32>)| {
            this.inner.set_width(start, end);
            Ok(())
        });

        // -- getWidth --
        /// Returns the start and end width.
        /// @return number, number
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));

        // -- setLifetime --
        /// Sets how long each trail point persists in seconds.
        /// @param lifetime : number
        /// @return nil
        methods.add_method_mut("setLifetime", |_, this, lifetime: f32| {
            this.inner.set_lifetime(lifetime);
            Ok(())
        });

        // -- getLifetime --
        /// Returns the trail point lifetime in seconds.
        /// @return number
        methods.add_method("getLifetime", |_, this, ()| Ok(this.inner.get_lifetime()));

        // -- setMinDistance --
        /// Sets the minimum distance between trail points.
        /// @param distance : number
        /// @return nil
        methods.add_method_mut("setMinDistance", |_, this, distance: f32| {
            this.inner.set_min_distance(distance);
            Ok(())
        });

        // -- setHeadColor --
        /// Sets the colour at the newest end of the trail.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        /// @return nil
        methods.add_method_mut(
            "setHeadColor",
            |_, this, (r, g, b, a): (f32, f32, f32, f32)| {
                this.inner
                    .set_head_color(crate::math::color::Color::new(r, g, b, a));
                Ok(())
            },
        );

        // -- setTailColor --
        /// Sets the colour at the oldest end of the trail.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        /// @return nil
        methods.add_method_mut(
            "setTailColor",
            |_, this, (r, g, b, a): (f32, f32, f32, f32)| {
                this.inner
                    .set_tail_color(crate::math::color::Color::new(r, g, b, a));
                Ok(())
            },
        );

        // -- getPointCount --
        /// Returns the number of active trail points.
        /// @return integer
        methods.add_method("getPointCount", |_, this, ()| {
            Ok(this.inner.get_point_count())
        });

        // -- clear --
        /// Removes all trail points.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.particles` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`. The Lua VM.
/// - `luna` — `&LuaTable`. The top-level `luna` table to register into.
/// - `state` — `Rc<RefCell<SharedState>>`. Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newSystem --
    /// Creates a new particle system and stores it in the engine pool.
    /// @param config : table
    /// @return ParticleSystem
    let s = state.clone();
    tbl.set(
        "newSystem",
        lua.create_function(move |lua, config: Option<LuaTable>| {
            let cfg = match config {
                Some(t) => ParticleConfig::from_lua_opts(&t)?,
                None => ParticleConfig::default(),
            };
            let ps = ParticleSystem::new(cfg);
            let mut st = s.borrow_mut();
            let key = st.particle_systems.insert(ps);
            lua.create_userdata(LuaParticleSystem {
                state: s.clone(),
                key,
            })
        })?,
    )?;

    // -- newTrail --
    /// Creates a new trail ribbon effect.
    /// @param lifetime : number
    /// @param start_width : number
    /// @return Trail
    tbl.set(
        "newTrail",
        lua.create_function(|lua, (lifetime, start_width): (f32, f32)| {
            lua.create_userdata(LuaTrail {
                inner: Trail::new(lifetime, start_width),
            })
        })?,
    )?;

    // -- Flat wrapper helpers --
    // These forward the flat `luna.particles.X(ps, ...)` style to the OOP UserData methods.
    // They accept (LuaAnyUserData, LuaMultiValue) and call the method via the registry.
    let flat_methods: &[&str] = &[
        "update", "emit", "start", "stop", "pause", "resume", "reset", "moveTo",
        "isActive", "isPaused", "isStopped", "isEmpty", "isFull", "release", "getCount",
        "setPosition", "getPosition", "setEmissionRate", "getEmissionRate",
        "setParticleLifetime", "getParticleLifetime", "setEmitterLifetime", "getEmitterLifetime",
        "setSpeed", "getSpeed", "setDirection", "getDirection", "setSpread", "getSpread",
        "setLinearAcceleration", "getLinearAcceleration", "setRadialAcceleration", "getRadialAcceleration",
        "setTangentialAcceleration", "getTangentialAcceleration", "setLinearDamping", "getLinearDamping",
        "setSizes", "getSizes", "setSizeVariation", "getSizeVariation", "setRotation", "getRotation",
        "setSpin", "getSpin", "setSpinVariation", "getSpinVariation",
        "setRelativeRotation", "hasRelativeRotation", "setColors", "getColors",
        "setOffset", "getOffset", "setInsertMode", "getInsertMode",
        "setBufferSize", "getBufferSize", "setEmissionArea", "getEmissionArea",
        "setShape", "getShape", "getGravity", "setGravity", "type", "typeOf", "clone",
    ];
    for &method_name in flat_methods {
        let mn = method_name.to_string();
        tbl.set(method_name, lua.create_function(move |_, args: LuaMultiValue| {
            let mut iter = args.iter();
            let ps_ud = match iter.next() {
                Some(LuaValue::UserData(ud)) => ud.clone(),
                _ => return Err(LuaError::runtime("expected ParticleSystem as first argument")),
            };
            let rest: LuaMultiValue = iter.cloned().collect();
            let method: LuaFunction = ps_ud.get(mn.as_str())?;
            let result: LuaMultiValue = method.call((ps_ud, rest))?;
            Ok(result)
        })?)?;
    }

    luna.set("particles", tbl)?;
    Ok(())
}
