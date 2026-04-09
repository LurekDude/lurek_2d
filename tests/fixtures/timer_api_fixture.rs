//! `luna.time` — Frame timing and scheduled callback API.
//!
//! Provides delta time, total elapsed time, FPS tracking, and a Scheduler
//! object for delayed and repeating Lua callbacks.

use super::SharedState;
use crate::timer::{Clock, Scheduler};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

// ─────────────────────────────────────────────────────────────────────────────
// LuaScheduler UserData
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-side wrapper around a [`Scheduler`].
///
/// Represents a scheduled event manager. Create one with
/// `lurek.time.newScheduler()` and call `scheduler:step(dt)` every frame.
pub struct LuaScheduler {
    inner: Scheduler,
    callback_key: Option<LuaRegistryKey>,
}

impl LuaUserData for LuaScheduler {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- after --
        /// Schedules a function to fire once after a delay.
        /// @param delay : number
        /// @param func : function
        /// @return integer
        methods.add_method_mut("after", |lua, this, (delay, func): (f64, LuaFunction)| {
            this.callback_key = Some(lua.create_registry_value(func)?);
            Ok(this.inner.after(delay))
        });

        // -- every --
        /// Schedules a function to fire repeatedly at the given interval.
        /// @param interval : number
        /// @param func : function
        /// @param count : integer?
        /// @return integer
        methods.add_method_mut(
            "every",
            |lua, this, (interval, func, count): (f64, LuaFunction, Option<i32>)| {
                this.callback_key = Some(lua.create_registry_value(func)?);
                Ok(this.inner.every(interval, count.unwrap_or(-1)))
            },
        );

        // -- cancel --
        /// Cancels a scheduled event by its ID.
        /// @param id : integer
        /// @return nil
        methods.add_method_mut("cancel", |_, this, id: u32| {
            this.inner.cancel(id);
            Ok(())
        });

        // -- step --
        /// Advances the scheduler by dt seconds, firing any due callbacks.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("step", |_, this, dt: f64| {
            this.inner.step(dt);
            Ok(())
        });

        // -- count --
        /// Returns the number of active scheduled events.
        /// @return integer
        methods.add_method("count", |_, this, ()| Ok(this.inner.count()));

        // -- clear --
        /// Cancels all scheduled events.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- __tostring --
        /// Returns a debug description of the scheduler.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("Scheduler(active={})", this.inner.count()))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// register
// ─────────────────────────────────────────────────────────────────────────────

/// Registers the `lurek.time` API table with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- getDelta --
    /// Returns the delta time in seconds since the last frame.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.dt()))?,
    )?;

    // -- getTime --
    /// Returns the total elapsed game time in seconds.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getTime",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.total()))?,
    )?;

    // -- getFPS --
    /// Returns the current frames-per-second counter.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getFPS",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.fps()))?,
    )?;

    // -- sleep --
    /// Suspends execution for the given number of seconds.
    /// @param seconds : number
    /// @return nil
    tbl.set(
        "sleep",
        lua.create_function(move |_, seconds: f64| {
            crate::timer::sleep(seconds);
            Ok(())
        })?,
    )?;

    // -- setTimeScale --
    /// Sets the global time scale applied to delta time.
    /// @param scale : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setTimeScale",
        lua.create_function(move |_, scale: f64| {
            s.borrow_mut().clock.set_time_scale(scale as f32);
            Ok(())
        })?,
    )?;

    // -- newScheduler --
    /// Creates a new Scheduler object for delayed and repeating callbacks.
    /// @return Scheduler
    tbl.set(
        "newScheduler",
        lua.create_function(move |lua, ()| {
            lua.create_userdata(LuaScheduler {
                inner: Scheduler::new(),
                callback_key: None,
            })
        })?,
    )?;

    luna.set("time", tbl)?;
    Ok(())
}
