//! `luna.time` - Frame timing, FPS tracking, and scheduled Lua callbacks.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;

use crate::timer::Scheduler;

// -------------------------------------------------------------------------------
// LuaScheduler UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Scheduler`] with per-event callback storage.
pub struct LuaScheduler {
    scheduler: Scheduler,
    callbacks: HashMap<u32, LuaRegistryKey>,
    named_ids: HashMap<String, u32>,
}

impl LuaScheduler {
    /// Creates a new empty scheduler with no pending events.
    fn new() -> Self {
        Self {
            scheduler: Scheduler::new(),
            callbacks: HashMap::new(),
            named_ids: HashMap::new(),
        }
    }

    /// Remove a callback registry key for an expired or cancelled event.
    fn remove_callback(
        lua: &Lua,
        callbacks: &mut HashMap<u32, LuaRegistryKey>,
        id: u32,
    ) -> LuaResult<()> {
        if let Some(key) = callbacks.remove(&id) {
            lua.remove_registry_value(key)?;
        }
        Ok(())
    }
}

impl LuaUserData for LuaScheduler {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- after --
        /// Schedules a callback to fire once after a delay.
        /// @param delay : number
        /// @param func : function
        /// @return integer
        methods.add_method_mut("after", |lua, this, (delay, func): (f64, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let id = this.scheduler.after(delay);
            this.callbacks.insert(id, key);
            Ok(id)
        });

        // -- afterNamed --
        /// Schedules a named one-shot callback, replacing any existing event with the same name.
        /// @param name : string
        /// @param delay : number
        /// @param func : function
        /// @return integer
        methods.add_method_mut(
            "afterNamed",
            |lua, this, (name, delay, func): (String, f64, LuaFunction)| {
                if let Some(old_id) = this.named_ids.remove(&name) {
                    this.scheduler.cancel(old_id);
                    Self::remove_callback(lua, &mut this.callbacks, old_id)?;
                }
                let key = lua.create_registry_value(func)?;
                let id = this.scheduler.after_named(name.clone(), delay);
                this.callbacks.insert(id, key);
                this.named_ids.insert(name, id);
                Ok(id)
            },
        );

        // -- every --
        /// Schedules a callback to fire repeatedly at the given interval.
        /// @param interval : number
        /// @param func : function
        /// @param count : integer?
        /// @return integer
        methods.add_method_mut(
            "every",
            |lua, this, (interval, func, count): (f64, LuaFunction, Option<i32>)| {
                let key = lua.create_registry_value(func)?;
                let id = this.scheduler.every(interval, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                Ok(id)
            },
        );

        // -- everyNamed --
        /// Schedules a named repeating callback, replacing any existing event with the same name.
        /// @param name : string
        /// @param interval : number
        /// @param func : function
        /// @param count : integer?
        /// @return integer
        methods.add_method_mut(
            "everyNamed",
            |lua, this, (name, interval, func, count): (String, f64, LuaFunction, Option<i32>)| {
                if let Some(old_id) = this.named_ids.remove(&name) {
                    this.scheduler.cancel(old_id);
                    Self::remove_callback(lua, &mut this.callbacks, old_id)?;
                }
                let key = lua.create_registry_value(func)?;
                let id = this
                    .scheduler
                    .every_named(name.clone(), interval, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                this.named_ids.insert(name, id);
                Ok(id)
            },
        );

        // -- cancel --
        /// Cancels a scheduled event by its numeric ID.
        /// @param id : integer
        /// @return boolean
        methods.add_method_mut("cancel", |lua, this, id: u32| {
            let removed = this.scheduler.cancel(id);
            if removed {
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                this.named_ids.retain(|_, v| *v != id);
            }
            Ok(removed)
        });

        // -- cancelNamed --
        /// Cancels a scheduled event by its string name.
        /// @param name : string
        /// @return boolean
        methods.add_method_mut("cancelNamed", |lua, this, name: String| {
            if let Some(id) = this.named_ids.remove(&name) {
                this.scheduler.cancel(id);
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- cancelAll --
        /// Cancels all scheduled events and returns the count removed.
        /// @return integer
        methods.add_method_mut("cancelAll", |lua, this, ()| {
            let n = this.scheduler.cancel_all();
            for (_, key) in this.callbacks.drain() {
                lua.remove_registry_value(key)?;
            }
            this.named_ids.clear();
            Ok(n)
        });

        // -- pause --
        /// Pauses a scheduled event by its ID.
        /// @param id : integer
        /// @return boolean
        methods.add_method_mut("pause", |_, this, id: u32| Ok(this.scheduler.pause(id)));

        // -- resume --
        /// Resumes a paused event by its ID.
        /// @param id : integer
        /// @return boolean
        methods.add_method_mut("resume", |_, this, id: u32| Ok(this.scheduler.resume(id)));

        // -- isPaused --
        /// Returns whether the given event is currently paused.
        /// @param id : integer
        /// @return boolean
        methods.add_method("isPaused", |_, this, id: u32| {
            Ok(this.scheduler.is_paused(id))
        });

        // -- getRemaining --
        /// Returns the seconds remaining until the next fire for an event, or nil.
        /// @param id : integer
        /// @return number?
        methods.add_method("getRemaining", |_, this, id: u32| {
            Ok(this.scheduler.get_remaining(id))
        });

        // -- getInterval --
        /// Returns the base interval in seconds for an event, or nil.
        /// @param id : integer
        /// @return number?
        methods.add_method("getInterval", |_, this, id: u32| {
            Ok(this.scheduler.get_interval(id))
        });

        // -- getRepeatCount --
        /// Returns the repeat count remaining for an event, or nil.
        /// @param id : integer
        /// @return integer?
        methods.add_method("getRepeatCount", |_, this, id: u32| {
            Ok(this.scheduler.get_repeat_count(id))
        });

        // -- getCount --
        /// Returns the number of active scheduled events.
        /// @return integer
        methods.add_method("getCount", |_, this, ()| Ok(this.scheduler.count() as u32));

        // -- isEmpty --
        /// Returns whether the scheduler has no active events.
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.scheduler.is_empty()));

        // -- setInterval --
        /// Changes the repeat interval of an existing event.
        /// @param id : integer
        /// @param interval : number
        /// @return boolean
        methods.add_method_mut("setInterval", |_, this, (id, interval): (u32, f64)| {
            Ok(this.scheduler.set_interval(id, interval))
        });

        // -- resetEvent --
        /// Resets an event's remaining time back to its original interval.
        /// @param id : integer
        /// @return boolean
        methods.add_method_mut("resetEvent", |_, this, id: u32| {
            Ok(this.scheduler.reset_event(id))
        });

        // -- setTimeScale --
        /// Sets a global time-scale multiplier for this scheduler.
        /// @param scale : number
        /// @return nil
        methods.add_method_mut("setTimeScale", |_, this, scale: f64| {
            this.scheduler.set_time_scale(scale);
            Ok(())
        });

        // -- getTimeScale --
        /// Returns the current time-scale multiplier.
        /// @return number
        methods.add_method("getTimeScale", |_, this, ()| {
            Ok(this.scheduler.get_time_scale())
        });

        // -- update --
        /// Advances all timers by dt seconds, firing due callbacks.
        /// @param dt : number
        /// @return integer
        methods.add_method_mut("update", |lua, this, dt: f64| {
            let fired_ids = this.scheduler.update(dt);
            let fired_count = fired_ids.len() as u32;
            for &id in &fired_ids {
                if let Some(key) = this.callbacks.get(&id) {
                    if let Ok(func) = lua.registry_value::<LuaFunction>(key) {
                        let _ = func.call::<_, ()>(());
                    }
                }
            }
            let active: HashSet<u32> = this.scheduler.active_ids().into_iter().collect();
            let dead: Vec<u32> = this
                .callbacks
                .keys()
                .filter(|id| !active.contains(id))
                .copied()
                .collect();
            for id in dead {
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                this.named_ids.retain(|_, v| *v != id);
            }
            Ok(fired_count)
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.time` API table with the Lua VM.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- getDelta --
    /// Returns the delta time in seconds for the current frame.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().delta_time))?,
    )?;

    // -- getFPS --
    /// Returns the current frames-per-second measurement.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getFPS",
        lua.create_function(move |_, ()| Ok(s.borrow().fps))?,
    )?;

    // -- getTime --
    /// Returns the total elapsed time since engine start in seconds.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getTime",
        lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
    )?;

    // -- getAverageDelta --
    /// Returns the rolling-average frame delta time in seconds.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getAverageDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.average_delta()))?,
    )?;

    // -- step --
    /// Advances the timer by one frame, returning the delta time.
    /// @return number
    let s = state.clone();
    tbl.set(
        "step",
        lua.create_function(move |_, ()| Ok(s.borrow_mut().step_timer()))?,
    )?;

    // -- getMicroTime --
    /// Returns the high-resolution elapsed time since engine start in seconds.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getMicroTime",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.elapsed()))?,
    )?;

    // -- getPhysicsDelta --
    /// Returns the fixed timestep used by `process_physics` callbacks (seconds).
    /// @return number
    let s = state.clone();
    tbl.set(
        "getPhysicsDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().physics_fixed_dt))?,
    )?;

    // -- setPhysicsDelta --
    /// Sets the fixed timestep for `process_physics` callbacks (seconds).
    /// Clamped to [1/240, 1/10] to prevent instability.
    /// @param dt : number
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setPhysicsDelta",
        lua.create_function(move |_, dt: f64| {
            let clamped = dt.clamp(1.0 / 240.0, 1.0 / 10.0);
            s.borrow_mut().physics_fixed_dt = clamped;
            Ok(())
        })?,
    )?;

    // -- sleep --
    /// Suspends execution for the given number of seconds.
    /// @param seconds : number
    /// @return nil
    tbl.set(
        "sleep",
        lua.create_function(|_, seconds: f64| {
            crate::timer::sleep(seconds);
            Ok(())
        })?,
    )?;

    // -- newScheduler --
    /// Creates a new independent Scheduler for managing timed callbacks.
    /// @return Scheduler
    tbl.set(
        "newScheduler",
        lua.create_function(|lua, ()| lua.create_userdata(LuaScheduler::new()))?,
    )?;

    luna.set("time", tbl)?;
    Ok(())
}
