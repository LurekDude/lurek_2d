//! `luna.particle` — Emitter-based 2D particle systems and trail ribbons.

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

/// Registers the `luna.particle` API table with the Lua VM.
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

    luna.set("particle", tbl)?;
    Ok(())
}
