//! `lurek.particle` â€” Emitter-based 2D particle systems and trail ribbons.

use super::callback_registry::CallbackRegistry;
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::particle::visualization as particle_vis;
use crate::particle::{
    AreaDistribution, EmissionShape, InsertMode, ParticleConfig, ParticleShape, ParticleSystem,
    RelativeMode, Trail,
};
use crate::runtime::resource_keys::ParticleKey;

// -------------------------------------------------------------------------------
// Config table â†’ ParticleConfig marshalling
// -------------------------------------------------------------------------------

// -------------------------------------------------------------------------------
// LuaParticleSystem UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a particle system stored in SharedState.
///
/// # Fields
/// - `state` â€” `Rc<RefCell<SharedState>>`.
/// - `key` â€” `ParticleKey`.
/// Fields: state (Rc<RefCell<SharedState>>), key (ParticleKey).
#[derive(Clone)]
pub struct LuaParticleSystem {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: ParticleKey,
    pub(crate) custom_callbacks: Rc<RefCell<CallbackRegistry>>,
    pub(crate) custom_shape_id: Option<u32>,
    pub(crate) death_batch_id: Option<u32>,
}

impl LuaUserData for LuaParticleSystem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Advances the particle simulation by dt seconds.
        /// @param dt number
        /// @return nil
        methods.add_method("update", |lua, this, dt: f32| {
            // Phase 1: domain update
            {
                let mut st = this.state.borrow_mut();
                if let Some(ps) = st.particle_systems.get_mut(this.key) {
                    ps.update(dt);
                }
            }
            // Phase 2: apply custom emission offsets
            {
                let indices: Vec<usize> = {
                    let mut st = this.state.borrow_mut();
                    st.particle_systems
                        .get_mut(this.key)
                        .map(|ps| ps.drain_custom_offsets())
                        .unwrap_or_default()
                };
                if let Some(cb_id) = this.custom_shape_id {
                    if !indices.is_empty() {
                        let reg = this.custom_callbacks.borrow();
                        for idx in indices {
                            if let Ok((ox, oy)) = reg.invoke::<_, (f32, f32)>(cb_id, lua, ()) {
                                let mut st = this.state.borrow_mut();
                                if let Some(ps) = st.particle_systems.get_mut(this.key) {
                                    if let Some(p) = ps.particles.get_mut(idx) {
                                        p.x = ox;
                                        p.y = oy;
                                        p.origin_x = ox;
                                        p.origin_y = oy;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Phase 3: invoke death-batch callback
            {
                let deaths: Vec<(f32, f32, f32, f32)> = {
                    let mut st = this.state.borrow_mut();
                    st.particle_systems
                        .get_mut(this.key)
                        .map(|ps| ps.drain_pending_deaths())
                        .unwrap_or_default()
                };
                if let Some(cb_id) = this.death_batch_id {
                    if !deaths.is_empty() {
                        let batch = lua.create_table()?;
                        for (i, (x, y, vx, vy)) in deaths.iter().enumerate() {
                            let entry = lua.create_table()?;
                            entry.set("x", *x)?;
                            entry.set("y", *y)?;
                            entry.set("vx", *vx)?;
                            entry.set("vy", *vy)?;
                            batch.set(i + 1, entry)?;
                        }
                        let reg = this.custom_callbacks.borrow();
                        let _ = reg.invoke::<_, LuaMultiValue>(cb_id, lua, batch);
                    }
                }
            }
            Ok(())
        });

        // -- emit --
        /// Emits a burst of the given number of particles.
        /// @param count integer
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
        /// Pauses particle emission; existing particles continue to simulate.
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
        /// @param x number
        /// @param y number
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
                return Err(LuaError::runtime(
                    "ParticleSystem handle is invalid (released)",
                ));
            }
            Ok(st
                .particle_systems
                .get(key)
                .map_or(0, |ps| ps.count() as i64))
        });

        // -- type --
        /// Returns the type name "ParticleSystem".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("ParticleSystem"));

        // -- typeOf --
        /// Returns true if this matches the given type name.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ParticleSystem" || name == "Drawable" || name == "Object")
        });

        // -- setPosition --
        /// Sets the emitter world position.
        /// @param x number
        /// @param y number
        /// @return nil
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
            let (x, y) = st
                .particle_systems
                .get(this.key)
                .map_or((0.0_f32, 0.0_f32), |ps| (ps.emitter_x, ps.emitter_y));
            Ok((x, y))
        });

        // -- setEmissionRate --
        /// Sets particles emitted per second.
        /// @param rate number
        /// @return nil
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
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.emission_rate))
        });

        // -- setParticleLifetime --
        /// Sets min and max particle lifetime in seconds.
        /// @param min number
        /// @param max number
        /// @return nil
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
            let (mn, mx) = st
                .particle_systems
                .get(this.key)
                .map_or((1.0_f32, 2.0_f32), |ps| {
                    (ps.config.lifetime_min, ps.config.lifetime_max)
                });
            Ok((mn, mx))
        });

        // -- setEmitterLifetime --
        /// Sets how long the emitter runs before auto-stopping. Negative = infinite.
        /// @param t number
        /// @return nil
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
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(-1.0_f32, |ps| ps.config.emitter_lifetime))
        });

        // -- setSpeed --
        /// Sets min/max initial speed.
        /// @param min number
        /// @param max number
        /// @return nil
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
            let (mn, mx) = st
                .particle_systems
                .get(this.key)
                .map_or((50.0_f32, 100.0_f32), |ps| {
                    (ps.config.speed_min, ps.config.speed_max)
                });
            Ok((mn, mx))
        });

        // -- setDirection --
        /// Sets emission direction in radians.
        /// @param dir number
        /// @return nil
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
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.direction))
        });

        // -- setSpread --
        /// Sets emission spread (half-angle cone) in radians.
        /// @param spread number
        /// @return nil
        methods.add_method("setSpread", |_, this, spread: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.spread = spread;
            }
            Ok(())
        });

        // -- getSpread --
        /// Returns the half-angle spread in radians for the emission cone.
        /// @return number
        methods.add_method("getSpread", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.spread))
        });

        // -- setLinearAcceleration --
        /// Sets linear acceleration range.
        /// @param xmin number
        /// @param ymin number
        /// @param xmax number
        /// @param ymax number
        /// @return nil
        methods.add_method(
            "setLinearAcceleration",
            |_, this, (xmin, ymin, xmax, ymax): (f32, f32, f32, f32)| {
                let mut st = this.state.borrow_mut();
                if let Some(ps) = st.particle_systems.get_mut(this.key) {
                    ps.config.linear_accel_x_min = xmin;
                    ps.config.linear_accel_y_min = ymin;
                    ps.config.linear_accel_x_max = xmax;
                    ps.config.linear_accel_y_max = ymax;
                }
                Ok(())
            },
        );

        // -- getLinearAcceleration --
        /// Returns linear acceleration range.
        /// @return number, number, number, number
        methods.add_method("getLinearAcceleration", |_, this, ()| {
            let st = this.state.borrow();
            let (xmin, ymin, xmax, ymax) = st.particle_systems.get(this.key).map_or(
                (0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32),
                |ps| {
                    (
                        ps.config.linear_accel_x_min,
                        ps.config.linear_accel_y_min,
                        ps.config.linear_accel_x_max,
                        ps.config.linear_accel_y_max,
                    )
                },
            );
            Ok((xmin, ymin, xmax, ymax))
        });

        // -- setRadialAcceleration --
        /// Sets radial acceleration range.
        /// @param min number
        /// @param max number
        /// @return nil
        methods.add_method(
            "setRadialAcceleration",
            |_, this, (min, max): (f32, f32)| {
                let mut st = this.state.borrow_mut();
                if let Some(ps) = st.particle_systems.get_mut(this.key) {
                    ps.config.radial_accel_min = min;
                    ps.config.radial_accel_max = max;
                }
                Ok(())
            },
        );

        // -- getRadialAcceleration --
        /// Returns radial acceleration range.
        /// @return number, number
        methods.add_method("getRadialAcceleration", |_, this, ()| {
            let st = this.state.borrow();
            let (mn, mx) = st
                .particle_systems
                .get(this.key)
                .map_or((0.0_f32, 0.0_f32), |ps| {
                    (ps.config.radial_accel_min, ps.config.radial_accel_max)
                });
            Ok((mn, mx))
        });

        // -- setTangentialAcceleration --
        /// Sets tangential acceleration range.
        /// @param min number
        /// @param max number
        /// @return nil
        methods.add_method(
            "setTangentialAcceleration",
            |_, this, (min, max): (f32, f32)| {
                let mut st = this.state.borrow_mut();
                if let Some(ps) = st.particle_systems.get_mut(this.key) {
                    ps.config.tangential_accel_min = min;
                    ps.config.tangential_accel_max = max;
                }
                Ok(())
            },
        );

        // -- getTangentialAcceleration --
        /// Returns tangential acceleration range.
        /// @return number, number
        methods.add_method("getTangentialAcceleration", |_, this, ()| {
            let st = this.state.borrow();
            let (mn, mx) = st
                .particle_systems
                .get(this.key)
                .map_or((0.0_f32, 0.0_f32), |ps| {
                    (
                        ps.config.tangential_accel_min,
                        ps.config.tangential_accel_max,
                    )
                });
            Ok((mn, mx))
        });

        // -- setLinearDamping --
        /// Sets linear damping range.
        /// @param min number
        /// @param max number
        /// @return nil
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
            let (mn, mx) = st
                .particle_systems
                .get(this.key)
                .map_or((0.0_f32, 0.0_f32), |ps| {
                    (ps.config.linear_damping_min, ps.config.linear_damping_max)
                });
            Ok((mn, mx))
        });

        // -- setSizes --
        /// Sets size keyframes (varargs: each number is one keyframe).
        /// @param ... : number
        /// @return nil
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
            let sizes = st
                .particle_systems
                .get(this.key)
                .map_or(vec![4.0_f32, 1.0_f32], |ps| ps.config.sizes.clone());
            let tbl = lua.create_table()?;
            for (i, s) in sizes.iter().enumerate() {
                tbl.set(i + 1, *s)?;
            }
            Ok(tbl)
        });

        // -- setSizeVariation --
        /// Sets size variation (0â€“1).
        /// @param v number
        /// @return nil
        methods.add_method("setSizeVariation", |_, this, v: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.size_variation = v;
            }
            Ok(())
        });

        // -- getSizeVariation --
        /// Returns the maximum random size variation applied to newly emitted particles.
        /// @return number
        methods.add_method("getSizeVariation", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.size_variation))
        });

        // -- setRotation --
        /// Sets initial rotation range in radians.
        /// @param min number
        /// @param max number
        /// @return nil
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
            let (mn, mx) = st
                .particle_systems
                .get(this.key)
                .map_or((0.0_f32, 0.0_f32), |ps| {
                    (ps.config.rotation_min, ps.config.rotation_max)
                });
            Ok((mn, mx))
        });

        // -- setSpin --
        /// Sets angular velocity range.
        /// @param min number
        /// @param max number
        /// @return nil
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
            let (mn, mx) = st
                .particle_systems
                .get(this.key)
                .map_or((0.0_f32, 0.0_f32), |ps| {
                    (ps.config.spin_min, ps.config.spin_max)
                });
            Ok((mn, mx))
        });

        // -- setSpinVariation --
        /// Sets spin variation (0â€“1).
        /// @param v number
        /// @return nil
        methods.add_method("setSpinVariation", |_, this, v: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.spin_variation = v;
            }
            Ok(())
        });

        // -- getSpinVariation --
        /// Returns the maximum random angular velocity variation for new particles.
        /// @return number
        methods.add_method("getSpinVariation", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.spin_variation))
        });

        // -- setRelativeRotation --
        /// Sets whether particle rotation follows velocity direction.
        /// @param v boolean
        /// @return nil
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
            Ok(st
                .particle_systems
                .get(this.key)
                .is_some_and(|ps| ps.config.relative_rotation))
        });

        // -- setColors --
        /// Sets color keyframes. Each arg is a table {r, g, b, a}.
        /// @param ... : table
        /// @return nil
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
            let colors = st
                .particle_systems
                .get(this.key)
                .map_or(vec![], |ps| ps.config.colors.clone());
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
        /// @param ox number
        /// @param oy number
        /// @return nil
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
            let (ox, oy) = st
                .particle_systems
                .get(this.key)
                .map_or((0.0_f32, 0.0_f32), |ps| {
                    (ps.config.offset_x, ps.config.offset_y)
                });
            Ok((ox, oy))
        });

        // -- setInsertMode --
        /// Sets the insert mode: "top", "bottom", or "random".
        /// @param mode string
        /// @return nil
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
            let mode =
                st.particle_systems
                    .get(this.key)
                    .map_or("top", |ps| match ps.config.insert_mode {
                        InsertMode::Bottom => "bottom",
                        InsertMode::Random => "random",
                        _ => "top",
                    });
            Ok(mode.to_string())
        });

        // -- setBufferSize --
        /// Sets the maximum number of particles (resizes the pool).
        /// @param n integer
        /// @return nil
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
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(256_u32, |ps| ps.config.max_particles))
        });

        // -- setEmissionArea --
        /// Sets emission area distribution and size.
        /// @param dist string  "none"|"uniform"|"normal"|"ellipse"|"borderellipse"|"borderrectangle"
        /// @param w number
        /// @param h number
        /// @param angle number?
        /// @param dir_relative boolean?
        /// @return nil
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
        /// string, number, number
        /// @return nil
        methods.add_method("getEmissionArea", |_, this, ()| {
            use crate::particle::AreaDistribution;
            let st = this.state.borrow();
            let (dist_str, w, h) = st.particle_systems.get(this.key).map_or(
                ("none".to_string(), 0.0_f32, 0.0_f32),
                |ps| {
                    let d = match ps.config.area_distribution {
                        AreaDistribution::Uniform => "uniform",
                        AreaDistribution::Normal => "normal",
                        AreaDistribution::Ellipse => "ellipse",
                        AreaDistribution::BorderEllipse => "borderellipse",
                        AreaDistribution::BorderRectangle => "borderrectangle",
                        _ => "none",
                    };
                    (d.to_string(), ps.config.area_width, ps.config.area_height)
                },
            );
            Ok((dist_str, w, h))
        });

        // -- setShape --
        /// Sets the particle draw shape.
        /// @param shape string  "square"|"circle"|"triangle"|"spark"|"diamond"|"shrapnel"|"ray"|"puff"|"ring"|"capsule"
        /// @return nil
        methods.add_method("setShape", |_, this, shape: String| {
            use crate::particle::ParticleShape;
            let s = match shape.as_str() {
                "circle" => ParticleShape::Circle,
                "triangle" => ParticleShape::Triangle,
                "spark" => ParticleShape::Spark,
                "diamond" => ParticleShape::Diamond,
                "square" => ParticleShape::Square,
                "shrapnel" => ParticleShape::Shrapnel { edges: 6 },
                "ray" => ParticleShape::Ray { aspect: 4.0 },
                "puff" => ParticleShape::Puff,
                "ring" => ParticleShape::Ring { thickness: 0.2 },
                "capsule" => ParticleShape::Capsule,
                other => {
                    return Err(LuaError::runtime(format!(
                        "unknown particle shape: {other}"
                    )))
                }
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
            let shape =
                st.particle_systems
                    .get(this.key)
                    .map_or("square", |ps| match ps.config.shape {
                        ParticleShape::Circle => "circle",
                        ParticleShape::Triangle => "triangle",
                        ParticleShape::Spark => "spark",
                        ParticleShape::Diamond => "diamond",
                        ParticleShape::Shrapnel { .. } => "shrapnel",
                        ParticleShape::Ray { .. } => "ray",
                        ParticleShape::Puff => "puff",
                        ParticleShape::Ring { .. } => "ring",
                        ParticleShape::Capsule => "capsule",
                        _ => "square",
                    });
            Ok(shape.to_string())
        });

        // -- getGravity --
        /// Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
        /// @return number, number
        methods.add_method("getGravity", |_, this, ()| {
            let st = this.state.borrow();
            let (gx, gy) = st
                .particle_systems
                .get(this.key)
                .map_or((0.0_f32, 0.0_f32), |ps| {
                    (ps.config.gravity_x, ps.config.gravity_y)
                });
            Ok((gx, gy))
        });

        // -- setGravity --
        /// Sets the gravity acceleration applied to all active particles each frame.
        /// @param gx number
        /// @param gy number
        /// @return nil
        methods.add_method("setGravity", |_, this, (gx, gy): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.gravity_x = gx;
                ps.config.gravity_y = gy;
            }
            Ok(())
        });

        // -- render --
        /// Renders all live particles to the GPU command queue.
        ///
        /// Calls `build_render_commands` on the particle system, expands textured
        /// particles into per-sprite `RenderCommand` variants (DrawQuad / DrawImageEx),
        /// and forwards untextured particles as a single `DrawParticleSystem` batch
        /// command that the GPU renderer tessellates in one draw call.
        /// Must be called inside `lurek.render`.
        ///
        /// @param ox number?  World X offset added to every particle (default 0).
        /// @param oy number?  World Y offset added to every particle (default 0).
        /// @return nil
        methods.add_method("render", |_, this, (ox, oy): (Option<f32>, Option<f32>)| {
            let ox = ox.unwrap_or(0.0);
            let oy = oy.unwrap_or(0.0);
            // Snapshot particles while borrowing immutably; drop borrow before borrow_mut.
            let cmds = {
                let st = this.state.borrow();
                match st.particle_systems.get(this.key) {
                    Some(ps) => ps.build_render_commands(ox, oy),
                    None => return Ok(()),
                }
            };
            // Textured particles expand to DrawQuad / DrawImageEx.
            // Untextured particles are forwarded as a single DrawParticleSystem batch
            // so the GPU renderer can tessellate all shapes in one colour draw call.
            let expanded = crate::particle::render::expand_particle_commands(cmds);
            let mut st = this.state.borrow_mut();
            st.render_commands.extend(expanded);
            Ok(())
        });

        // -- clone --
        /// Creates a copy of this particle system (config only, no live particles).
        /// @return ParticleSystem
        methods.add_method("clone", |lua, this, ()| {
            let (state, new_ps) = {
                let st = this.state.borrow();
                let ps = st.particle_systems.get(this.key).ok_or_else(|| {
                    LuaError::runtime("ParticleSystem handle is invalid (released)")
                })?;
                (this.state.clone(), ps.clone_config())
            };
            let key = state.borrow_mut().particle_systems.insert(new_ps);
            lua.create_userdata(LuaParticleSystem {
                state,
                key,
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
                custom_shape_id: None,
                death_batch_id: None,
            })
        });

        // -- drawToImage --
        /// Renders all live particles to a CPU ImageData.
        /// @param width integer
        /// @param height integer
        /// @return ImageData
        methods.add_method("drawToImage", |_, this, (w, h): (u32, u32)| {
            let st = this.state.borrow();
            let ps = st
                .particle_systems
                .get(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            let img = particle_vis::draw_to_image(ps, w, h);
            Ok(img)
        });

        // -- toImage --
        /// Alias for `drawToImage`. Renders all live particles to a CPU ImageData.
        /// @param width integer
        /// @param height integer
        /// @return ImageData
        methods.add_method("toImage", |_, this, (w, h): (u32, u32)| {
            let st = this.state.borrow();
            let ps = st
                .particle_systems
                .get(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            let img = particle_vis::draw_to_image(ps, w, h);
            Ok(img)
        });

        // -- warmUp --
        /// Pre-simulates the particle system for `seconds` so it appears fully
        /// populated on first render. Clamped to 30 seconds to avoid runaway
        /// simulation cost.
        /// @param seconds number
        /// @return nil
        methods.add_method_mut("warmUp", |_, this, seconds: f32| {
            let mut st = this.state.borrow_mut();
            let ps = st
                .particle_systems
                .get_mut(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            ps.warm_up(seconds);
            Ok(())
        });

        // -- addAttractor --
        /// Adds a gravity well that pulls (positive strength) or repels
        /// (negative strength) all live particles within `radius` pixels.
        /// @param x number
        /// @param y number
        /// @param strength number
        /// @param radius number
        /// @return nil
        methods.add_method_mut(
            "addAttractor",
            |_, this, (x, y, strength, radius): (f32, f32, f32, f32)| {
                let mut st = this.state.borrow_mut();
                let ps = st.particle_systems.get_mut(this.key).ok_or_else(|| {
                    LuaError::runtime("ParticleSystem handle is invalid (released)")
                })?;
                ps.add_attractor(x, y, strength, radius);
                Ok(())
            },
        );

        // -- clearAttractors --
        /// Removes all attractors from this particle system.
        /// @return nil
        methods.add_method_mut("clearAttractors", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let ps = st
                .particle_systems
                .get_mut(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            ps.clear_attractors();
            Ok(())
        });

        // -- getAttractorCount --
        /// Returns the number of attractors currently registered on this system.
        /// @return integer
        methods.add_method("getAttractorCount", |_, this, ()| {
            let st = this.state.borrow();
            let ps = st
                .particle_systems
                .get(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            Ok(ps.attractor_count() as u32)
        });

        // -- setBounds --
        /// Constrains all particles to an axis-aligned bounding rectangle.
        /// Particles that cross a wall have their velocity component along that
        /// axis reversed and scaled by `restitution` (0 = stick, 1 = elastic).
        /// @param xmin number
        /// @param xmax number
        /// @param ymin number
        /// @param ymax number
        /// @param restitution number
        /// @return nil
        methods.add_method_mut(
            "setBounds",
            |_, this, (xmin, xmax, ymin, ymax, restitution): (f32, f32, f32, f32, f32)| {
                let mut st = this.state.borrow_mut();
                let ps = st.particle_systems.get_mut(this.key).ok_or_else(|| {
                    LuaError::runtime("ParticleSystem handle is invalid (released)")
                })?;
                ps.set_bounds(xmin, xmax, ymin, ymax, restitution);
                Ok(())
            },
        );

        // -- clearBounds --
        /// Removes the bounding rectangle so particles can move freely.
        /// @return nil
        methods.add_method_mut("clearBounds", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let ps = st
                .particle_systems
                .get_mut(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            ps.clear_bounds();
            Ok(())
        });

        // -- addSubEmitter --
        /// Attaches a sub-emitter that bursts when a particle dies.
        ///
        /// `config_tbl` uses the same keys as `lurek.particle.new(opts)`.
        /// `burst_count` defaults to 1.
        /// @param config_tbl table
        /// @param burst_count number?
        /// @return nil
        methods.add_method_mut(
            "addSubEmitter",
            |_, this, (config_tbl, burst_count): (LuaTable, Option<u32>)| {
                let mut st = this.state.borrow_mut();
                let ps = st.particle_systems.get_mut(this.key).ok_or_else(|| {
                    LuaError::runtime("ParticleSystem handle is invalid (released)")
                })?;
                let sub_cfg = ParticleConfig::from_lua_opts(&config_tbl)?;
                ps.config.death_emitter = Some(Box::new(sub_cfg));
                ps.config.death_burst_count = burst_count.unwrap_or(1);
                Ok(())
            },
        );

        // -- setFlipbook --
        /// Configures sprite-sheet flipbook animation by dividing the texture into a grid.
        ///
        /// Automatically computes `cols * rows` UV quads and sets `animated_frames` / `frame_rate`.
        /// @param cols number -- columns in the sprite sheet
        /// @param rows number -- rows in the sprite sheet
        /// @param fps number -- animation speed in frames per second
        /// @return nil
        methods.add_method_mut(
            "setFlipbook",
            |_, this, (cols, rows, fps): (u32, u32, f32)| {
                if cols == 0 || rows == 0 {
                    return Err(LuaError::runtime("setFlipbook: cols and rows must be > 0"));
                }
                let mut st = this.state.borrow_mut();
                let ps = st.particle_systems.get_mut(this.key).ok_or_else(|| {
                    LuaError::runtime("ParticleSystem handle is invalid (released)")
                })?;
                let cell_w = 1.0_f32 / cols as f32;
                let cell_h = 1.0_f32 / rows as f32;
                let total = (cols * rows) as usize;
                let mut quads = Vec::with_capacity(total);
                for row in 0..rows {
                    for col in 0..cols {
                        quads.push([col as f32 * cell_w, row as f32 * cell_h, cell_w, cell_h]);
                    }
                }
                ps.config.quads = quads;
                ps.config.animated_frames = cols * rows;
                ps.config.frame_rate = fps;
                Ok(())
            },
        );

        // -- getFlipbook --
        /// Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
        /// number?, number?, number?
        /// @return nil
        methods.add_method("getFlipbook", |_, this, ()| {
            let st = this.state.borrow();
            let ps = st
                .particle_systems
                .get(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            let total = ps.config.animated_frames as usize;
            if total == 0 || ps.config.quads.is_empty() {
                return Ok((None::<i64>, None::<i64>, None::<f64>));
            }
            let cell_w = ps.config.quads[0][2];
            let cols = (1.0_f32 / cell_w).round() as u32;
            let rows = if cols > 0 {
                (total as u32).div_ceil(cols)
            } else {
                1
            };
            let fps = ps.config.frame_rate;
            Ok((Some(cols as i64), Some(rows as i64), Some(fps as f64)))
        });

        // ── Extensibility ──────────────────────────────────────────────────────

        // -- addSubSystem --
        /// Adds a child emitter that updates and renders with this system.
        /// @param config table  same format as lurek.particle.newSystem config
        /// @return index : integer  1-based index of the new sub-system
        methods.add_method_mut("addSubSystem", |_, this, config_tbl: LuaTable| {
            let config = ParticleConfig::from_lua_opts(&config_tbl)?;
            let mut st = this.state.borrow_mut();
            let ps = st.particle_systems.get_mut(this.key).ok_or_else(|| {
                LuaError::runtime("ParticleSystem handle is invalid (released)")
            })?;
            let idx = ps.add_sub_system(config);
            Ok((idx + 1) as i64)
        });

        // -- subSystemCount --
        /// Returns the number of direct child sub-systems attached to this emitter.
        /// @return count : integer
        methods.add_method("subSystemCount", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0_i64, |ps| ps.sub_system_count() as i64))
        });

        // -- setCustomEmissionShape --
        /// Sets a Lua function that returns (offset_x, offset_y) for each newly spawned
        /// particle when the emission shape is delegated to Lua.  The callback takes no
        /// arguments and is called once per particle per emit step.
        /// @param fn function  () -> number, number
        /// @return nil
        methods.add_method_mut("setCustomEmissionShape", |lua, this, cb: LuaFunction| {
            let key = lua.create_registry_value(cb)?;
            let id = this.custom_callbacks.borrow_mut().register(key);
            this.custom_shape_id = Some(id);
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.emission_shape = EmissionShape::Custom { callback_id: id };
            }
            Ok(())
        });

        // -- setOnDeathBatch --
        /// Sets a Lua function called after each update() with all particles that died
        /// during that frame.  The callback receives a table array where each entry is
        /// { x, y, vx, vy } in world space.
        /// @param fn function  (batch: table) -> nil
        /// @return nil
        methods.add_method_mut("setOnDeathBatch", |lua, this, cb: LuaFunction| {
            let key = lua.create_registry_value(cb)?;
            let id = this.custom_callbacks.borrow_mut().register(key);
            this.death_batch_id = Some(id);
            Ok(())
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
        /// @param x number
        /// @param y number
        /// @return nil
        methods.add_method_mut("pushPoint", |_, this, (x, y): (f32, f32)| {
            this.inner.push_point(x, y);
            Ok(())
        });

        // -- update --
        /// Ages trail points and removes expired ones.
        /// @param dt number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- setWidth --
        /// Sets the start and end width of the trail ribbon.
        /// @param start_width number
        /// @param end_width number
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
        /// @param lifetime number
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
        /// @param distance number
        /// @return nil
        methods.add_method_mut("setMinDistance", |_, this, distance: f32| {
            this.inner.set_min_distance(distance);
            Ok(())
        });

        // -- setHeadColor --
        /// Sets the colour at the newest end of the trail.
        /// @param r number
        /// @param g number
        /// @param b number
        /// @param a number
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
        /// @param r number
        /// @param g number
        /// @param b number
        /// @param a number
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

        // -- drawToImage --
        /// Renders the trail ribbon to a CPU ImageData.
        /// @param width integer
        /// @param height integer
        /// @return ImageData
        methods.add_method("drawToImage", |_, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            Ok(img)
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.particle` API table with the Lua VM.
///
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param state Rc<RefCell<SharedState>>
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param state Rc<RefCell<SharedState>>
/// @return LuaResult<()>
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newSystem --
    /// Creates a new particle system and stores it in the engine pool.
    /// @param config table
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
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
                custom_shape_id: None,
                death_batch_id: None,
            })
        })?,
    )?;

    // -- newTrail --
    /// Creates a new trail ribbon effect.
    /// @param lifetime number
    /// @param start_width number
    /// @return Trail
    tbl.set(
        "newTrail",
        lua.create_function(|lua, (lifetime, start_width): (f32, f32)| {
            lua.create_userdata(LuaTrail {
                inner: Trail::new(lifetime, start_width),
            })
        })?,
    )?;

    // -- fromTOML --
    /// Creates a new particle system from a TOML config file.
    /// @param path string  Path to the TOML config file.
    /// @return ParticleSystem
    let s_toml = state.clone();
    tbl.set(
        "fromTOML",
        lua.create_function(move |lua, path: String| {
            let toml_str = std::fs::read_to_string(&path)
                .map_err(|e| LuaError::runtime(format!("fromTOML: cannot read '{path}': {e}")))?;
            let cfg = ParticleConfig::from_toml_str(&toml_str)
                .map_err(|e| LuaError::runtime(format!("fromTOML: parse error in '{path}': {e}")))?;
            let ps = ParticleSystem::new(cfg);
            let key = s_toml.borrow_mut().particle_systems.insert(ps);
            lua.create_userdata(LuaParticleSystem {
                state: s_toml.clone(),
                key,
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
                custom_shape_id: None,
                death_batch_id: None,
            })
        })?,
    )?;

    // -- Flat wrapper helpers --
    // These forward the flat `lurek.particle.X(ps, ...)` style to the OOP UserData methods.
    // They accept (LuaAnyUserData, LuaMultiValue) and call the method via the registry.
    let flat_methods: &[&str] = &[
        "update",
        "emit",
        "start",
        "stop",
        "pause",
        "resume",
        "reset",
        "moveTo",
        "isActive",
        "isPaused",
        "isStopped",
        "isEmpty",
        "isFull",
        "release",
        "getCount",
        "setPosition",
        "getPosition",
        "setEmissionRate",
        "getEmissionRate",
        "setParticleLifetime",
        "getParticleLifetime",
        "setEmitterLifetime",
        "getEmitterLifetime",
        "setSpeed",
        "getSpeed",
        "setDirection",
        "getDirection",
        "setSpread",
        "getSpread",
        "setLinearAcceleration",
        "getLinearAcceleration",
        "setRadialAcceleration",
        "getRadialAcceleration",
        "setTangentialAcceleration",
        "getTangentialAcceleration",
        "setLinearDamping",
        "getLinearDamping",
        "setSizes",
        "getSizes",
        "setSizeVariation",
        "getSizeVariation",
        "setRotation",
        "getRotation",
        "setSpin",
        "getSpin",
        "setSpinVariation",
        "getSpinVariation",
        "setRelativeRotation",
        "hasRelativeRotation",
        "setColors",
        "getColors",
        "setOffset",
        "getOffset",
        "setInsertMode",
        "getInsertMode",
        "setBufferSize",
        "getBufferSize",
        "setEmissionArea",
        "getEmissionArea",
        "setShape",
        "getShape",
        "getGravity",
        "setGravity",
        "type",
        "typeOf",
        "clone",
        "addSubSystem",
        "subSystemCount",
        "setCustomEmissionShape",
        "setOnDeathBatch",
    ];
    for &method_name in flat_methods {
        let mn = method_name.to_string();
        tbl.set(
            method_name,
            lua.create_function(move |_, args: LuaMultiValue| {
                let mut iter = args.iter();
                let ps_ud = match iter.next() {
                    Some(LuaValue::UserData(ud)) => ud.clone(),
                    _ => {
                        return Err(LuaError::runtime(
                            "expected ParticleSystem as first argument",
                        ))
                    }
                };
                let rest: LuaMultiValue = iter.cloned().collect();
                let method: LuaFunction = ps_ud.get(mn.as_str())?;
                let result: LuaMultiValue = method.call((ps_ud, rest))?;
                Ok(result)
            })?,
        )?;
    }

    /// Namespace containing the particle API module.
    /// Provides high performance particle emission rendering and updating.
    lurek.set("particle", tbl)?;
    Ok(())
}

impl ParticleConfig {
    /// from_lua_opts.
    ///
    /// @param t &LuaTable
    ///
    /// @return LuaResult<Self>
    pub fn from_lua_opts(t: &LuaTable) -> LuaResult<Self> {
        let mut c = ParticleConfig::default();
        if let Ok(v) = t.get::<_, u32>("maxParticles") {
            c.max_particles = v;
        }
        if let Ok(v) = t.get::<_, f32>("emissionRate") {
            c.emission_rate = v;
        }
        if let Ok(v) = t.get::<_, f32>("lifetimeMin") {
            c.lifetime_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("lifetimeMax") {
            c.lifetime_max = v;
        }
        if let Ok(v) = t.get::<_, f32>("speedMin") {
            c.speed_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("speedMax") {
            c.speed_max = v;
        }
        if let Ok(v) = t.get::<_, f32>("direction") {
            c.direction = v;
        }
        if let Ok(v) = t.get::<_, f32>("spread") {
            c.spread = v;
        }
        if let Ok(v) = t.get::<_, f32>("gravityX") {
            c.gravity_x = v;
        }
        if let Ok(v) = t.get::<_, f32>("gravityY") {
            c.gravity_y = v;
        }
        if let Ok(v) = t.get::<_, f32>("spinMin") {
            c.spin_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("spinMax") {
            c.spin_max = v;
        }
        if let Ok(v) = t.get::<_, f32>("spinVariation") {
            c.spin_variation = v;
        }
        if let Ok(v) = t.get::<_, f32>("sizeVariation") {
            c.size_variation = v;
        }
        if let Ok(v) = t.get::<_, f32>("rotationMin") {
            c.rotation_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("rotationMax") {
            c.rotation_max = v;
        }
        if let Ok(v) = t.get::<_, f32>("emitterLifetime") {
            c.emitter_lifetime = v;
        }
        if let Ok(v) = t.get::<_, f32>("linearAccelXMin") {
            c.linear_accel_x_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("linearAccelXMax") {
            c.linear_accel_x_max = v;
        }
        if let Ok(v) = t.get::<_, f32>("linearAccelYMin") {
            c.linear_accel_y_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("linearAccelYMax") {
            c.linear_accel_y_max = v;
        }
        if let Ok(v) = t.get::<_, f32>("radialAccelMin") {
            c.radial_accel_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("radialAccelMax") {
            c.radial_accel_max = v;
        }
        if let Ok(v) = t.get::<_, f32>("tangentialAccelMin") {
            c.tangential_accel_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("tangentialAccelMax") {
            c.tangential_accel_max = v;
        }
        if let Ok(v) = t.get::<_, f32>("linearDampingMin") {
            c.linear_damping_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("linearDampingMax") {
            c.linear_damping_max = v;
        }
        if let Ok(v) = t.get::<_, f32>("areaWidth") {
            c.area_width = v;
        }
        if let Ok(v) = t.get::<_, f32>("areaHeight") {
            c.area_height = v;
        }
        if let Ok(v) = t.get::<_, f32>("areaAngle") {
            c.area_angle = v;
        }
        if let Ok(v) = t.get::<_, bool>("areaDirectionRelative") {
            c.area_direction_relative = v;
        }
        if let Ok(v) = t.get::<_, bool>("relativeRotation") {
            c.relative_rotation = v;
        }
        if let Ok(v) = t.get::<_, f32>("offsetX") {
            c.offset_x = v;
        }
        if let Ok(v) = t.get::<_, f32>("offsetY") {
            c.offset_y = v;
        }
        if let Ok(v) = t.get::<_, f32>("turbulence") {
            c.turbulence = v;
        }
        if let Ok(v) = t.get::<_, f32>("drag") {
            c.drag = v;
        }
        if let Ok(v) = t.get::<_, f32>("orbitSpeed") {
            c.orbit_speed = v;
        }
        if let Ok(v) = t.get::<_, u32>("animatedFrames") {
            c.animated_frames = v;
        }
        if let Ok(v) = t.get::<_, f32>("frameRate") {
            c.frame_rate = v;
        }
        if let Ok(v) = t.get::<_, bool>("colorBySpeed") {
            c.color_by_speed = v;
        }
        if let Ok(v) = t.get::<_, f32>("speedColorMin") {
            c.speed_color_min = v;
        }
        if let Ok(v) = t.get::<_, f32>("speedColorMax") {
            c.speed_color_max = v;
        }

        // sizes: table of floats
        if let Ok(st) = t.get::<_, LuaTable>("sizes") {
            let mut sizes = Vec::new();
            for i in 1..=32 {
                match st.get::<_, f32>(i) {
                    Ok(v) => sizes.push(v),
                    Err(_) => break,
                }
            }
            if !sizes.is_empty() {
                c.sizes = sizes;
            }
        }

        // colors: table of {r, g, b, a}
        if let Ok(ct) = t.get::<_, LuaTable>("colors") {
            let mut colors = Vec::new();
            for i in 1..=16 {
                match ct.get::<_, LuaTable>(i) {
                    Ok(entry) => {
                        let r = entry.get::<_, f32>(1).unwrap_or(1.0);
                        let g = entry.get::<_, f32>(2).unwrap_or(1.0);
                        let b = entry.get::<_, f32>(3).unwrap_or(1.0);
                        let a = entry.get::<_, f32>(4).unwrap_or(1.0);
                        colors.push([r, g, b, a]);
                    }
                    Err(_) => break,
                }
            }
            if !colors.is_empty() {
                c.colors = colors;
            }
        }

        // alphaKeyframes: table of floats
        if let Ok(at) = t.get::<_, LuaTable>("alphaKeyframes") {
            let mut alphas = Vec::new();
            for i in 1..=16 {
                match at.get::<_, f32>(i) {
                    Ok(v) => alphas.push(v),
                    Err(_) => break,
                }
            }
            if !alphas.is_empty() {
                c.alpha_keyframes = alphas;
            }
        }

        // areaDistribution: string â†’ enum
        if let Ok(v) = t.get::<_, String>("areaDistribution") {
            c.area_distribution = match v.as_str() {
                "uniform" => AreaDistribution::Uniform,
                "normal" => AreaDistribution::Normal,
                "ellipse" => AreaDistribution::Ellipse,
                "borderRectangle" => AreaDistribution::BorderRectangle,
                "borderEllipse" => AreaDistribution::BorderEllipse,
                _ => AreaDistribution::default(),
            };
        }

        // insertMode: string â†’ enum
        if let Ok(v) = t.get::<_, String>("insertMode") {
            c.insert_mode = match v.as_str() {
                "top" => InsertMode::Top,
                "bottom" => InsertMode::Bottom,
                "random" => InsertMode::Random,
                _ => InsertMode::default(),
            };
        }

        // emissionShape: string â†’ enum
        if let Ok(v) = t.get::<_, String>("emissionShape") {
            c.emission_shape = match v.as_str() {
                "point" => EmissionShape::Point,
                "circle" => EmissionShape::Circle {
                    radius: 50.0,
                    fill: true,
                },
                "rectangle" => EmissionShape::Rectangle {
                    width: 100.0,
                    height: 100.0,
                },
                "ring" => EmissionShape::Ring {
                    inner_radius: 20.0,
                    outer_radius: 50.0,
                },
                "line" => EmissionShape::Line {
                    length: 100.0,
                    angle: 0.0,
                },
                "cone" => EmissionShape::Cone {
                    radius: 50.0,
                    angle: 0.0,
                    spread: 0.5,
                },
                "star" => EmissionShape::Star {
                    points: 5,
                    outer_radius: 50.0,
                    inner_radius: 25.0,
                },
                "spiral" => EmissionShape::Spiral {
                    revolutions: 2.0,
                    radius: 50.0,
                },
                _ => EmissionShape::default(),
            };
        }

        // relativeMode: string â†’ enum
        if let Ok(v) = t.get::<_, String>("relativeMode") {
            c.relative_mode = match v.as_str() {
                "attached" => RelativeMode::Attached,
                _ => RelativeMode::Detached,
            };
        }

        // shape: string â†’ ParticleShape
        if let Ok(v) = t.get::<_, String>("shape") {
            c.shape = match v.as_str() {
                "square" => ParticleShape::Square,
                "circle" => ParticleShape::Circle,
                "triangle" => ParticleShape::Triangle,
                "spark" => ParticleShape::Spark,
                "diamond" => ParticleShape::Diamond,
                "puff" => ParticleShape::Puff,
                "capsule" => ParticleShape::Capsule,
                "shrapnel" => {
                    let edges = t.get::<_, u8>("shrapnelEdges").unwrap_or(c.shrapnel_edges);
                    ParticleShape::Shrapnel { edges }
                }
                "ray" => {
                    let aspect = t.get::<_, f32>("rayAspect").unwrap_or(c.ray_aspect);
                    ParticleShape::Ray { aspect }
                }
                "ring" => {
                    let thickness = t.get::<_, f32>("ringThickness").unwrap_or(c.ring_thickness);
                    ParticleShape::Ring { thickness }
                }
                _ => ParticleShape::Square,
            };
        }

        // shape-specific config overrides
        if let Ok(v) = t.get::<_, u8>("shrapnelEdges") {
            c.shrapnel_edges = v;
        }
        if let Ok(v) = t.get::<_, f32>("rayAspect") {
            c.ray_aspect = v;
        }
        if let Ok(v) = t.get::<_, f32>("ringThickness") {
            c.ring_thickness = v;
        }
        if let Ok(v) = t.get::<_, u32>("deathBurstCount") {
            c.death_burst_count = v;
        }

        // deathEmitter: table â†’ sub-emitter config (recursive)
        if let Ok(sub_tbl) = t.get::<_, LuaTable>("deathEmitter") {
            c.death_emitter = Some(Box::new(ParticleConfig::from_lua_opts(&sub_tbl)?));
        }

        Ok(c)
    }
}
