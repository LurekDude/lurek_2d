//! `lurek.particle` -- Lua bindings for particle systems, trails, presets, TOML configs, physics collision, custom emission callbacks, death callbacks, and module-level forwarding helpers.

use super::callback_registry::CallbackRegistry;
use super::physics_api::LuaWorld;
use super::SharedState;
use crate::particle::visualization as particle_vis;
use crate::particle::{physics_collision, presets as particle_presets};
use crate::particle::{
    AreaDistribution, EmissionShape, InsertMode, ParticleConfig, ParticleShape, ParticleSystem,
    RelativeMode, Trail,
};
use crate::physics::World;
use crate::runtime::resource_keys::ParticleKey;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
#[derive(Clone)]
/// Lua-side handle for a particle system stored in shared runtime state.
pub struct LuaParticleSystem {
    /// Shared runtime state containing particle system storage and render commands.
    pub(crate) state: Rc<RefCell<SharedState>>,
    /// Key of the particle system in shared storage.
    pub(crate) key: ParticleKey,
    /// Registry for custom emission and death callbacks owned by this handle.
    pub(crate) custom_callbacks: Rc<RefCell<CallbackRegistry>>,
    /// Optional custom emission callback id.
    pub(crate) custom_shape_id: Option<u32>,
    /// Optional death batch callback id.
    pub(crate) death_batch_id: Option<u32>,
    /// Optional physics world used for collision probes.
    pub(crate) collision_world: Option<Rc<RefCell<World>>>,
    /// Probe radius for particle physics collision.
    pub(crate) collision_probe_radius: f32,
    /// Restitution used for particle physics collision.
    pub(crate) collision_restitution: f32,
}
/// Provides Lua methods for particle playback, configuration, rendering, collision, callbacks, and sub-systems.
impl LuaUserData for LuaParticleSystem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Updates the particle system, applies optional physics collision, and invokes pending callbacks.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("update", |lua, this, dt: f32| {
            {
                let mut st = this.state.borrow_mut();
                if let Some(ps) = st.particle_systems.get_mut(this.key) {
                    ps.update(dt);
                }
            }
            {
                if let Some(world) = &this.collision_world {
                    let mut st = this.state.borrow_mut();
                    if let Some(ps) = st.particle_systems.get_mut(this.key) {
                        physics_collision::collide_with_world(
                            ps,
                            &world.borrow(),
                            this.collision_probe_radius,
                            this.collision_restitution,
                        );
                    }
                }
            }
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
        /// Emits particles immediately. This method is available to Lua scripts.
        /// @param | count | integer | Number of particles to emit.
        /// @return | nil | No value is returned.
        methods.add_method("emit", |_, this, count: u32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.emit(count);
            }
            Ok(())
        });
        // -- start --
        /// Starts particle emission. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method("start", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.start();
            }
            Ok(())
        });
        // -- stop --
        /// Stops particle emission. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method("stop", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.stop();
            }
            Ok(())
        });
        // -- pause --
        /// Pauses particle emission and updates.
        /// @return | nil | No value is returned.
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.pause();
            }
            Ok(())
        });
        // -- resume --
        /// Resumes a paused particle system. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.resume();
            }
            Ok(())
        });
        // -- reset --
        /// Resets particles and emitter state.
        /// @return | nil | No value is returned.
        methods.add_method("reset", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.reset();
            }
            Ok(())
        });
        // -- moveTo --
        /// Moves the particle emitter. This method is available to Lua scripts.
        /// @param | x | number | Emitter x coordinate.
        /// @param | y | number | Emitter y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method("moveTo", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.move_to(x, y);
            }
            Ok(())
        });
        // -- count --
        /// Returns the current particle count.
        /// @return | integer | Particle count.
        methods.add_method("count", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.particle_systems.get(this.key).map_or(0, |ps| ps.count()))
        });
        // -- isActive --
        /// Returns whether the particle system is active.
        /// @return | boolean | True when active.
        methods.add_method("isActive", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_some_and(|ps| ps.is_active()))
        });
        // -- isPaused --
        /// Returns whether the particle system is paused.
        /// @return | boolean | True when paused.
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_some_and(|ps| ps.is_paused()))
        });
        // -- isStopped --
        /// Returns whether the particle system is stopped or missing.
        /// @return | boolean | True when stopped.
        methods.add_method("isStopped", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_none_or(|ps| ps.is_stopped()))
        });
        // -- isEmpty --
        /// Returns whether the particle system has no particles or is missing.
        /// @return | boolean | True when empty.
        methods.add_method("isEmpty", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_none_or(|ps| ps.is_empty()))
        });
        // -- isFull --
        /// Returns whether the particle system has reached capacity.
        /// @return | boolean | True when full.
        methods.add_method("isFull", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_some_and(|ps| ps.is_full()))
        });
        // -- release --
        /// Releases the particle system from shared storage.
        /// @return | boolean | True after release.
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            st.particle_systems.remove(this.key);
            Ok(true)
        });
        // -- getCount --
        /// Returns particle count and errors if the handle was released.
        /// @return | integer | Particle count.
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
        /// Returns the Lua-visible type name for this particle system handle.
        /// @return | string | The string `LParticleSystem`.
        methods.add_method("type", |_, _, ()| Ok("LParticleSystem"));
        // -- typeOf --
        /// Returns whether this particle system handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LParticleSystem`, `ParticleSystem`, `Drawable`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LParticleSystem"
                || name == "ParticleSystem"
                || name == "Drawable"
                || name == "Object")
        });
        // -- setPosition --
        /// Sets emitter position. This method is available to Lua scripts.
        /// @param | x | number | Emitter x coordinate.
        /// @param | y | number | Emitter y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.emitter_x = x;
                ps.emitter_y = y;
            }
            Ok(())
        });
        // -- getPosition --
        /// Returns emitter position. This method is available to Lua scripts.
        /// @return | number | Emitter x coordinate.
        /// @return | number | Emitter y coordinate.
        methods.add_method("getPosition", |_, this, ()| {
            let st = this.state.borrow();
            let (x, y) = st
                .particle_systems
                .get(this.key)
                .map_or((0.0_f32, 0.0_f32), |ps| (ps.emitter_x, ps.emitter_y));
            Ok((x, y))
        });
        // -- setEmissionRate --
        /// Sets emission rate. This method is available to Lua scripts.
        /// @param | rate | number | Particles per second.
        /// @return | nil | No value is returned.
        methods.add_method("setEmissionRate", |_, this, rate: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.emission_rate = rate;
            }
            Ok(())
        });
        // -- getEmissionRate --
        /// Returns emission rate. This method is available to Lua scripts.
        /// @return | number | Particles per second.
        methods.add_method("getEmissionRate", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.emission_rate))
        });
        // -- setParticleLifetime --
        /// Sets particle lifetime range. This method is available to Lua scripts.
        /// @param | min | number | Minimum lifetime.
        /// @param | max | number | Maximum lifetime.
        /// @return | nil | No value is returned.
        methods.add_method("setParticleLifetime", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.lifetime_min = min;
                ps.config.lifetime_max = max;
            }
            Ok(())
        });
        // -- getParticleLifetime --
        /// Returns particle lifetime range. This method is available to Lua scripts.
        /// @return | number | Minimum lifetime.
        /// @return | number | Maximum lifetime.
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
        /// Sets emitter lifetime. This method is available to Lua scripts.
        /// @param | t | number | Emitter lifetime.
        /// @return | nil | No value is returned.
        methods.add_method("setEmitterLifetime", |_, this, t: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.emitter_lifetime = t;
            }
            Ok(())
        });
        // -- getEmitterLifetime --
        /// Returns emitter lifetime. This method is available to Lua scripts.
        /// @return | number | Emitter lifetime.
        methods.add_method("getEmitterLifetime", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(-1.0_f32, |ps| ps.config.emitter_lifetime))
        });
        // -- setSpeed --
        /// Sets particle speed range. This method is available to Lua scripts.
        /// @param | min | number | Minimum speed.
        /// @param | max | number | Maximum speed.
        /// @return | nil | No value is returned.
        methods.add_method("setSpeed", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.speed_min = min;
                ps.config.speed_max = max;
            }
            Ok(())
        });
        // -- getSpeed --
        /// Returns particle speed range. This method is available to Lua scripts.
        /// @return | number | Minimum speed.
        /// @return | number | Maximum speed.
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
        /// Sets emission direction. This method is available to Lua scripts.
        /// @param | dir | number | Direction angle.
        /// @return | nil | No value is returned.
        methods.add_method("setDirection", |_, this, dir: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.direction = dir;
            }
            Ok(())
        });
        // -- getDirection --
        /// Returns emission direction. This method is available to Lua scripts.
        /// @return | number | Direction angle.
        methods.add_method("getDirection", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.direction))
        });
        // -- setSpread --
        /// Sets emission spread. This method is available to Lua scripts.
        /// @param | spread | number | Spread angle.
        /// @return | nil | No value is returned.
        methods.add_method("setSpread", |_, this, spread: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.spread = spread;
            }
            Ok(())
        });
        // -- getSpread --
        /// Returns emission spread. This method is available to Lua scripts.
        /// @return | number | Spread angle.
        methods.add_method("getSpread", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.spread))
        });
        // -- setLinearAcceleration --
        /// Sets linear acceleration range. This method is available to Lua scripts.
        /// @param | xmin | number | Lua argument for `xmin`.
        /// @param | ymin | number | Lua argument for `ymin`.
        /// @param | xmax | number | Lua argument for `xmax`.
        /// @param | ymax | number | Lua argument for `ymax`.
        /// @return | nil | No value is returned.
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
        /// @return | number | Minimum x acceleration.
        /// @return | number | Minimum y acceleration.
        /// @return | number | Maximum x acceleration.
        /// @return | number | Maximum y acceleration.
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
        /// Sets radial acceleration range. This method is available to Lua scripts.
        /// @param | min | number | Lua argument for `min`.
        /// @param | max | number | Lua argument for `max`.
        /// @return | nil | No value is returned.
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
        /// @return | number | Minimum acceleration.
        /// @return | number | Maximum acceleration.
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
        /// @param | min | number | Lua argument for `min`.
        /// @param | max | number | Lua argument for `max`.
        /// @return | nil | No value is returned.
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
        /// @return | number | Minimum acceleration.
        /// @return | number | Maximum acceleration.
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
        /// Sets linear damping range. This method is available to Lua scripts.
        /// @param | min | number | Lua argument for `min`.
        /// @param | max | number | Lua argument for `max`.
        /// @return | nil | No value is returned.
        methods.add_method("setLinearDamping", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.linear_damping_min = min;
                ps.config.linear_damping_max = max;
            }
            Ok(())
        });
        // -- getLinearDamping --
        /// Returns linear damping range. This method is available to Lua scripts.
        /// @return | number | Minimum damping.
        /// @return | number | Maximum damping.
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
        /// Sets particle size keyframes from numeric arguments.
        /// @param | sizes | number | One or more size values.
        /// @return | nil | No value is returned.
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
        /// Returns particle size keyframes. This method is available to Lua scripts.
        /// @return | table | Array table of size values.
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
        /// Sets size variation. This method is available to Lua scripts.
        /// @param | v | number | Size variation.
        /// @return | nil | No value is returned.
        methods.add_method("setSizeVariation", |_, this, v: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.size_variation = v;
            }
            Ok(())
        });
        // -- getSizeVariation --
        /// Returns size variation. This method is available to Lua scripts.
        /// @return | number | Size variation.
        methods.add_method("getSizeVariation", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.size_variation))
        });
        // -- setRotation --
        /// Sets particle rotation range. This method is available to Lua scripts.
        /// @param | min | number | Lua argument for `min`.
        /// @param | max | number | Lua argument for `max`.
        /// @return | nil | No value is returned.
        methods.add_method("setRotation", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.rotation_min = min;
                ps.config.rotation_max = max;
            }
            Ok(())
        });
        // -- getRotation --
        /// Returns particle rotation range. This method is available to Lua scripts.
        /// @return | number | Minimum rotation.
        /// @return | number | Maximum rotation.
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
        /// Sets particle spin range. This method is available to Lua scripts.
        /// @param | min | number | Lua argument for `min`.
        /// @param | max | number | Lua argument for `max`.
        /// @return | nil | No value is returned.
        methods.add_method("setSpin", |_, this, (min, max): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.spin_min = min;
                ps.config.spin_max = max;
            }
            Ok(())
        });
        // -- getSpin --
        /// Returns particle spin range. This method is available to Lua scripts.
        /// @return | number | Minimum spin.
        /// @return | number | Maximum spin.
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
        /// Sets spin variation. This method is available to Lua scripts.
        /// @param | v | number | Lua argument for `v`.
        /// @return | nil | No value is returned.
        methods.add_method("setSpinVariation", |_, this, v: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.spin_variation = v;
            }
            Ok(())
        });
        // -- getSpinVariation --
        /// Returns spin variation. This method is available to Lua scripts.
        /// @return | number | Spin variation.
        methods.add_method("getSpinVariation", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0.0_f32, |ps| ps.config.spin_variation))
        });
        // -- setRelativeRotation --
        /// Sets whether particle rotation is relative to movement.
        /// @param | v | boolean | Relative rotation flag.
        /// @return | nil | No value is returned.
        methods.add_method("setRelativeRotation", |_, this, v: bool| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.relative_rotation = v;
            }
            Ok(())
        });
        // -- hasRelativeRotation --
        /// Returns whether relative rotation is enabled.
        /// @return | boolean | True when relative rotation is enabled.
        methods.add_method("hasRelativeRotation", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .is_some_and(|ps| ps.config.relative_rotation))
        });
        // -- setColors --
        /// Sets particle color keyframes from RGBA tables.
        /// @param | colors | table | One or more color tables.
        /// @return | nil | No value is returned.
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
        /// Returns particle color keyframes.
        /// @return | table | Array table of RGBA color tables.
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
        /// Sets particle spawn offset. This method is available to Lua scripts.
        /// @param | ox | number | Lua argument for `ox`.
        /// @param | oy | number | Lua argument for `oy`.
        /// @return | nil | No value is returned.
        methods.add_method("setOffset", |_, this, (ox, oy): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.offset_x = ox;
                ps.config.offset_y = oy;
            }
            Ok(())
        });
        // -- getOffset --
        /// Returns particle spawn offset. This method is available to Lua scripts.
        /// @return | number | Offset x.
        /// @return | number | Offset y.
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
        /// Sets particle insert mode. This method is available to Lua scripts.
        /// @param | mode | string | Insert mode: `top`, `bottom`, or `random`.
        /// @return | nil | No value is returned.
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
        /// Returns particle insert mode. This method is available to Lua scripts.
        /// @return | string | Insert mode name.
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
        /// Sets maximum particle buffer size.
        /// @param | n | integer | Maximum particle count.
        /// @return | nil | No value is returned.
        methods.add_method("setBufferSize", |_, this, n: u32| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.max_particles = n;
                ps.particles.reserve(n as usize);
            }
            Ok(())
        });
        // -- getBufferSize --
        /// Returns maximum particle buffer size.
        /// @return | integer | Maximum particle count.
        methods.add_method("getBufferSize", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(256_u32, |ps| ps.config.max_particles))
        });
        // -- setEmissionArea --
        /// Sets emission area distribution and size.
        /// @param | dist | string | Distribution name.
        /// @param | w | number | Area width.
        /// @param | h | number | Area height.
        /// @param | angle | number | Optional area angle.
        /// @param | dir_rel | boolean | Optional direction-relative flag.
        /// @return | nil | No value is returned.
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
        /// Returns emission area distribution and size.
        /// @return | string | Distribution name.
        /// @return | number | Area width.
        /// @return | number | Area height.
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
        /// Sets particle shape. This method is available to Lua scripts.
        /// @param | shape | string | Shape name.
        /// @return | nil | No value is returned.
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
        /// Returns particle shape. This method is available to Lua scripts.
        /// @return | string | Shape name.
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
        /// Returns particle gravity. This method is available to Lua scripts.
        /// @return | number | Gravity x.
        /// @return | number | Gravity y.
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
        /// Sets particle gravity. This method is available to Lua scripts.
        /// @param | gx | number | Gravity x.
        /// @param | gy | number | Gravity y.
        /// @return | nil | No value is returned.
        methods.add_method("setGravity", |_, this, (gx, gy): (f32, f32)| {
            let mut st = this.state.borrow_mut();
            if let Some(ps) = st.particle_systems.get_mut(this.key) {
                ps.config.gravity_x = gx;
                ps.config.gravity_y = gy;
            }
            Ok(())
        });
        // -- render --
        /// Enqueues particle render commands with an optional offset.
        /// @param | ox | number | Optional x offset.
        /// @param | oy | number | Optional y offset.
        /// @return | nil | No value is returned.
        methods.add_method("render", |_, this, (ox, oy): (Option<f32>, Option<f32>)| {
            let ox = ox.unwrap_or(0.0);
            let oy = oy.unwrap_or(0.0);
            let cmds = {
                let st = this.state.borrow();
                match st.particle_systems.get(this.key) {
                    Some(ps) => ps.build_render_commands(ox, oy),
                    None => return Ok(()),
                }
            };
            let expanded = crate::particle::render::expand_particle_commands(cmds);
            let mut st = this.state.borrow_mut();
            st.render_commands.extend(expanded);
            Ok(())
        });
        // -- clone --
        /// Clones this particle system configuration into a new system handle.
        /// @return | LParticleSystem | New particle system handle.
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
                collision_world: None,
                collision_probe_radius: 1.0,
                collision_restitution: 0.6,
            })
        });
        // -- drawToImage --
        /// Draws particles to image data. This method is available to Lua scripts.
        /// @param | w | integer | Image width.
        /// @param | h | integer | Image height.
        /// @return | LuaValue | Image data returned by the particle visualization module.
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
        /// Draws particles to image data. This method is available to Lua scripts.
        /// @param | w | integer | Image width.
        /// @param | h | integer | Image height.
        /// @return | LuaValue | Image data returned by the particle visualization module.
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
        /// Advances the system by a warm-up duration.
        /// @param | seconds | number | Warm-up duration in seconds.
        /// @return | nil | No value is returned.
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
        /// Adds an attractor to the particle system.
        /// @param | x | number | Numeric `x` argument for this call.
        /// @param | y | number | Numeric `y` argument for this call.
        /// @param | strength | number | Lua argument for `strength`.
        /// @param | radius | number | Numeric `radius` argument for this call.
        /// @return | nil | No value is returned.
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
        /// Clears all attractors. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
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
        /// Returns attractor count. This method is available to Lua scripts.
        /// @return | integer | Attractor count.
        methods.add_method("getAttractorCount", |_, this, ()| {
            let st = this.state.borrow();
            let ps = st
                .particle_systems
                .get(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            Ok(ps.attractor_count() as u32)
        });
        // -- setBounds --
        /// Sets collision bounds for particles.
        /// @param | xmin | number | Lua argument for `xmin`.
        /// @param | xmax | number | Lua argument for `xmax`.
        /// @param | ymin | number | Lua argument for `ymin`.
        /// @param | ymax | number | Lua argument for `ymax`.
        /// @param | restitution | number | Lua argument for `restitution`.
        /// @return | nil | No value is returned.
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
        /// Clears collision bounds. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearBounds", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let ps = st
                .particle_systems
                .get_mut(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            ps.clear_bounds();
            Ok(())
        });
        // -- setCollidesWithPhysics --
        /// Enables particle collision against a physics world.
        /// @param | world_ud | LWorld | Physics world handle.
        /// @param | probe_radius | number | Optional collision probe radius.
        /// @param | restitution | number | Optional restitution.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setCollidesWithPhysics",
            |_, this, (world_ud, probe_radius, restitution): (LuaAnyUserData, Option<f32>, Option<f32>)| {
                let world = world_ud.borrow::<LuaWorld>()?;
                this.collision_world = Some(world.world_handle());
                this.collision_probe_radius = probe_radius.unwrap_or(1.0).max(0.1);
                this.collision_restitution = restitution.unwrap_or(0.6).clamp(0.0, 1.0);
                Ok(())
            },
        );
        // -- clearCollidesWithPhysics --
        /// Disables particle collision against a physics world.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearCollidesWithPhysics", |_, this, ()| {
            this.collision_world = None;
            Ok(())
        });
        // -- hasCollidesWithPhysics --
        /// Returns whether particle physics collision is enabled.
        /// @return | boolean | True when collision is enabled.
        methods.add_method("hasCollidesWithPhysics", |_, this, ()| {
            Ok(this.collision_world.is_some())
        });
        // -- addSubEmitter --
        /// Configures a death sub-emitter from a config table.
        /// @param | config_tbl | table | Particle config table.
        /// @param | burst_count | integer | Optional burst count.
        /// @return | nil | No value is returned.
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
        /// Sets flipbook grid and frame rate. This method is available to Lua scripts.
        /// @param | cols | integer | Lua argument for `cols`.
        /// @param | rows | integer | Lua argument for `rows`.
        /// @param | fps | number | Lua argument for `fps`.
        /// @return | nil | No value is returned.
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
        /// Returns flipbook grid and frame rate when configured.
        /// @return | integer | Column count, or nil when unconfigured.
        /// @return | integer | Row count, or nil when unconfigured.
        /// @return | number | Frame rate, or nil when unconfigured.
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
        // -- addSubSystem --
        /// Adds a particle sub-system from a config table.
        /// @param | config_tbl | table | Particle config table.
        /// @return | integer | One-based sub-system index.
        methods.add_method_mut("addSubSystem", |_, this, config_tbl: LuaTable| {
            let config = ParticleConfig::from_lua_opts(&config_tbl)?;
            let mut st = this.state.borrow_mut();
            let ps = st
                .particle_systems
                .get_mut(this.key)
                .ok_or_else(|| LuaError::runtime("ParticleSystem handle is invalid (released)"))?;
            let idx = ps.add_sub_system(config);
            Ok((idx + 1) as i64)
        });
        // -- subSystemCount --
        /// Returns particle sub-system count.
        /// @return | integer | Sub-system count.
        methods.add_method("subSystemCount", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st
                .particle_systems
                .get(this.key)
                .map_or(0_i64, |ps| ps.sub_system_count() as i64))
        });
        // -- setCustomEmissionShape --
        /// Sets a Lua callback for custom emission positions.
        /// @param | cb | function | Callback returning an x/y position.
        /// @return | nil | No value is returned.
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
        /// Sets a Lua callback invoked with batched particle death records.
        /// @param | cb | function | Death batch callback.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setOnDeathBatch", |lua, this, cb: LuaFunction| {
            let key = lua.create_registry_value(cb)?;
            let id = this.custom_callbacks.borrow_mut().register(key);
            this.death_batch_id = Some(id);
            Ok(())
        });
    }
}
/// Lua-side wrapper for a trail effect.
pub struct LuaTrail {
    /// Wrapped trail data.
    inner: Trail,
}
/// Provides Lua methods for trail point updates, style, image export, and type helpers.
impl LuaUserData for LuaTrail {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- pushPoint --
        /// Adds a point to the trail. This method is available to Lua scripts.
        /// @param | x | number | Numeric `x` argument for this call.
        /// @param | y | number | Numeric `y` argument for this call.
        /// @return | nil | No value is returned.
        methods.add_method_mut("pushPoint", |_, this, (x, y): (f32, f32)| {
            this.inner.push_point(x, y);
            Ok(())
        });
        // -- update --
        /// Updates trail point lifetimes. This method is available to Lua scripts.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });
        // -- setWidth --
        /// Sets trail start and optional end width.
        /// @param | start | number | Lua argument for `start`.
        /// @param | end | number? | Lua argument for `end`.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setWidth", |_, this, (start, end): (f32, Option<f32>)| {
            this.inner.set_width(start, end);
            Ok(())
        });
        // -- getWidth --
        /// Returns trail width settings. This method is available to Lua scripts.
        /// @return | LuaValue | Width tuple from the trail module.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));
        // -- setLifetime --
        /// Sets trail point lifetime. This method is available to Lua scripts.
        /// @param | lifetime | number | Lua argument for `lifetime`.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLifetime", |_, this, lifetime: f32| {
            this.inner.set_lifetime(lifetime);
            Ok(())
        });
        // -- getLifetime --
        /// Returns trail point lifetime. This method is available to Lua scripts.
        /// @return | number | Lifetime in seconds.
        methods.add_method("getLifetime", |_, this, ()| Ok(this.inner.get_lifetime()));
        // -- setMinDistance --
        /// Sets minimum distance between trail points.
        /// @param | distance | number | Lua argument for `distance`.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setMinDistance", |_, this, distance: f32| {
            this.inner.set_min_distance(distance);
            Ok(())
        });
        // -- setHeadColor --
        /// Sets trail head color. This method is available to Lua scripts.
        /// @param | r | number | Lua argument for `r`.
        /// @param | g | number | Lua argument for `g`.
        /// @param | b | number | Lua argument for `b`.
        /// @param | a | number | Lua argument for `a`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setHeadColor",
            |_, this, (r, g, b, a): (f32, f32, f32, f32)| {
                this.inner
                    .set_head_color(crate::math::color::Color::new(r, g, b, a));
                Ok(())
            },
        );
        // -- setTailColor --
        /// Sets trail tail color. This method is available to Lua scripts.
        /// @param | r | number | Lua argument for `r`.
        /// @param | g | number | Lua argument for `g`.
        /// @param | b | number | Lua argument for `b`.
        /// @param | a | number | Lua argument for `a`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setTailColor",
            |_, this, (r, g, b, a): (f32, f32, f32, f32)| {
                this.inner
                    .set_tail_color(crate::math::color::Color::new(r, g, b, a));
                Ok(())
            },
        );
        // -- getPointCount --
        /// Returns trail point count. This method is available to Lua scripts.
        /// @return | integer | Point count.
        methods.add_method("getPointCount", |_, this, ()| {
            Ok(this.inner.get_point_count())
        });
        // -- clear --
        /// Clears all trail points. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- drawToImage --
        /// Draws the trail to image data. This method is available to Lua scripts.
        /// @param | w | integer | Lua argument for `w`.
        /// @param | h | integer | Lua argument for `h`.
        /// @return | LuaValue | Image data returned by the trail module.
        methods.add_method("drawToImage", |_, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            Ok(img)
        });
        // -- type --
        /// Returns the Lua-visible type name for this trail handle.
        /// @return | string | The string `LTrail`.
        methods.add_method("type", |_, _, ()| Ok("LTrail"));
        // -- typeOf --
        /// Returns whether this trail handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LTrail` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTrail" || name == "Object")
        });
    }
}
/// Registers the `lurek.particle` module.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    // -- newSystem --
    /// Creates a particle system from an optional config table.
    /// @param | config | table | Optional particle config table.
    /// @return | LParticleSystem | New particle system handle.
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
                collision_world: None,
                collision_probe_radius: 1.0,
                collision_restitution: 0.6,
            })
        })?,
    )?;
    // -- newTrail --
    /// Creates a trail effect. This function is exposed to Lua scripts.
    /// @param | lifetime | number | Trail point lifetime.
    /// @param | start_width | number | Trail start width.
    /// @return | LTrail | New trail handle.
    tbl.set(
        "newTrail",
        lua.create_function(|lua, (lifetime, start_width): (f32, f32)| {
            lua.create_userdata(LuaTrail {
                inner: Trail::new(lifetime, start_width),
            })
        })?,
    )?;
    let s_toml = state.clone();
    // -- fromTOML --
    /// Creates a particle system from a TOML config file.
    /// @param | path | string | TOML file path.
    /// @return | LParticleSystem | New particle system handle.
    tbl.set(
        "fromTOML",
        lua.create_function(move |lua, path: String| {
            let toml_str = std::fs::read_to_string(&path)
                .map_err(|e| LuaError::runtime(format!("fromTOML: cannot read '{path}': {e}")))?;
            let cfg = ParticleConfig::from_toml_str(&toml_str).map_err(|e| {
                LuaError::runtime(format!("fromTOML: parse error in '{path}': {e}"))
            })?;
            let ps = ParticleSystem::new(cfg);
            let key = s_toml.borrow_mut().particle_systems.insert(ps);
            lua.create_userdata(LuaParticleSystem {
                state: s_toml.clone(),
                key,
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
                custom_shape_id: None,
                death_batch_id: None,
                collision_world: None,
                collision_probe_radius: 1.0,
                collision_restitution: 0.6,
            })
        })?,
    )?;
    let s_preset = state.clone();
    // -- newPreset --
    /// Creates a particle system from a named preset.
    /// @param | name | string | Preset name: `fire`, `smoke`, `rain`, `snow`, or `sparks`.
    /// @return | LParticleSystem | New particle system handle.
    tbl.set(
        "newPreset",
        lua.create_function(move |lua, name: String| {
            let cfg = match name.as_str() {
                "fire" => particle_presets::fire(),
                "smoke" => particle_presets::smoke(),
                "rain" => particle_presets::rain(),
                "snow" => particle_presets::snow(),
                "sparks" => particle_presets::sparks(),
                _ => {
                    return Err(LuaError::runtime(format!(
                        "unknown particle preset '{name}'"
                    )))
                }
            };
            let key = s_preset
                .borrow_mut()
                .particle_systems
                .insert(ParticleSystem::new(cfg));
            lua.create_userdata(LuaParticleSystem {
                state: s_preset.clone(),
                key,
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
                custom_shape_id: None,
                death_batch_id: None,
                collision_world: None,
                collision_probe_radius: 1.0,
                collision_restitution: 0.6,
            })
        })?,
    )?;
    /// Particle system method names also exposed as module-level forwarding functions.
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
        "setCollidesWithPhysics",
        "clearCollidesWithPhysics",
        "hasCollidesWithPhysics",
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
    lurek.set("particle", tbl)?;
    Ok(())
}
impl ParticleConfig {
    /// Builds a particle config from a Lua options table.
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
        if let Ok(v) = t.get::<_, String>("insertMode") {
            c.insert_mode = match v.as_str() {
                "top" => InsertMode::Top,
                "bottom" => InsertMode::Bottom,
                "random" => InsertMode::Random,
                _ => InsertMode::default(),
            };
        }
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
        if let Ok(v) = t.get::<_, String>("relativeMode") {
            c.relative_mode = match v.as_str() {
                "attached" => RelativeMode::Attached,
                _ => RelativeMode::Detached,
            };
        }
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
        if let Ok(sub_tbl) = t.get::<_, LuaTable>("deathEmitter") {
            c.death_emitter = Some(Box::new(ParticleConfig::from_lua_opts(&sub_tbl)?));
        }
        Ok(c)
    }
}
