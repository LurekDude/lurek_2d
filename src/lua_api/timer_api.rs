//! Timer Api implementation for the `lua_api` subsystem.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for timer api-related operations and data management.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use crate::timer::Scheduler;

/// Lua wrapper around a [`Scheduler`] that stores both numeric and named callback references.
///
/// Methods mirror the Rust `Scheduler` API, accepting Lua functions as callbacks.
/// Callbacks are stored as Lua registry keys so the GC cannot collect them while scheduled.
struct LuaScheduler {
    scheduler: Scheduler,
    /// Callback storage keyed by numeric event ID.
    callbacks: HashMap<u32, LuaRegistryKey>,
    /// Maps human-readable event names → numeric event IDs for named events.
    named_ids: HashMap<String, u32>,
}

impl LuaScheduler {
    fn new() -> Self {
        Self {
            scheduler: Scheduler::new(),
            callbacks: HashMap::new(),
            named_ids: HashMap::new(),
        }
    }

    /// Remove callback registry key for an expired/cancelled event ID.
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

impl mlua::UserData for LuaScheduler {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // ── Scheduling ────────────────────────────────────────────────────

        // Schedule `fn` to fire once after `delay` seconds. Returns event ID.
        /// Calls a Lua function after the given delay in seconds.
        /// @param delay : number
        /// @param func : function
        /// @return any
        methods.add_method_mut("after", |lua, this, (delay, func): (f64, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let id = this.scheduler.after(delay);
            this.callbacks.insert(id, key);
            Ok(id)
        });

        // Schedule named one-shot: `afterNamed(name, delay, fn)`. Returns ID.
        // Replaces any existing event with the same name.
        methods.add_method_mut(
            "afterNamed",
            |lua, this, (name, delay, func): (String, f64, LuaFunction)| {
                // Cancel existing named event if any
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

        // Schedule `fn` to fire every `interval` seconds (`count` times, -1=infinite). Returns ID.
        methods.add_method_mut(
            "every",
            |lua, this, (interval, func, count): (f64, LuaFunction, Option<i32>)| {
                let key = lua.create_registry_value(func)?;
                let id = this.scheduler.every(interval, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                Ok(id)
            },
        );

        // Schedule named repeating: `everyNamed(name, interval, fn, count?)`. Returns ID.
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

        // ── Cancellation ──────────────────────────────────────────────────

        // Cancel event by numeric ID. Returns true if found.
        /// Cancels a scheduled timer callback.
        /// @param id : integer
        /// @return any
        methods.add_method_mut("cancel", |lua, this, id: u32| {
            let removed = this.scheduler.cancel(id);
            if removed {
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                this.named_ids.retain(|_, v| *v != id);
            }
            Ok(removed)
        });

        // Cancel event by name. Returns true if found.
        /// Cancels a specific named timer that was scheduled on this scheduler.
        /// @param name : string
        /// @return boolean
        ///
        /// # Parameters
        /// - `name` — Name string used when the timer was created.
        methods.add_method_mut("cancelNamed", |lua, this, name: String| {
            if let Some(id) = this.named_ids.remove(&name) {
                this.scheduler.cancel(id);
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // Cancel all events. Returns count cancelled.
        /// Cancels and removes every pending timer entry from this scheduler.
        /// @return any
        methods.add_method_mut("cancelAll", |lua, this, ()| {
            let n = this.scheduler.cancel_all();
            for (_, key) in this.callbacks.drain() {
                lua.remove_registry_value(key)?;
            }
            this.named_ids.clear();
            Ok(n)
        });

        // ── Pause / Resume ────────────────────────────────────────────────

        // Pause event by ID. Returns true if found.
        /// Pauses the scheduler so no pending callbacks fire until resumed.
        /// @param id : integer
        /// @return any
        methods.add_method_mut("pause", |_, this, id: u32| Ok(this.scheduler.pause(id)));

        // Resume event by ID. Returns true if found.
        /// Resumes a paused scheduler, allowing its callbacks to fire again.
        /// @param id : integer
        /// @return any
        methods.add_method_mut("resume", |_, this, id: u32| Ok(this.scheduler.resume(id)));

        // Returns true if event ID is currently paused.
        /// Returns whether the scheduler is currently paused and not advancing timers.
        /// @param id : integer
        /// @return any
        ///
        /// # Returns
        /// true if paused, false if running.
        methods.add_method("isPaused", |_, this, id: u32| {
            Ok(this.scheduler.is_paused(id))
        });

        // ── Queries ───────────────────────────────────────────────────────

        // Returns seconds remaining until next fire for event ID, or nil.
        /// Returns the time remaining before the next invocation of the given timer.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — Timer ID returned when the timer was created.
        ///
        /// # Returns
        /// Remaining time in seconds.
        methods.add_method("getRemaining", |_, this, id: u32| {
            Ok(this.scheduler.get_remaining(id))
        });

        // Returns the base interval for event ID, or nil.
        /// Returns the repeat interval of the given timer entry in seconds.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — Timer ID returned when the timer was created.
        ///
        /// # Returns
        /// Interval in seconds, or nil for one-shot timers.
        methods.add_method("getInterval", |_, this, id: u32| {
            Ok(this.scheduler.get_interval(id))
        });

        // Returns the repeat count remaining (-1=infinite) for event ID, or nil.
        /// Returns how many times the given timer has fired since it was created.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — Timer ID.
        ///
        /// # Returns
        /// Fire count as an integer.
        methods.add_method("getRepeatCount", |_, this, id: u32| {
            Ok(this.scheduler.get_repeat_count(id))
        });

        // Returns active event count.
        /// Returns the number of active timer entries currently in the scheduler.
        /// @return integer
        ///
        /// # Returns
        /// Active timer count as an integer.
        methods.add_method("getCount", |_, this, ()| Ok(this.scheduler.count() as u32));

        // Returns true if no events are scheduled.
        /// Returns whether the scheduler has no active timer entries.
        /// @return boolean
        ///
        /// # Returns
        /// true if the scheduler queue is empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.scheduler.is_empty()));

        // ── Modification ──────────────────────────────────────────────────

        // Change the interval of a repeating event ID. Returns true if found.
        /// Changes the repeat interval of an existing timer without recreating it.
        /// @param id : integer
        /// @param interval : number
        /// @return any
        ///
        /// # Parameters
        /// - `id` — Timer ID.
        /// - `interval` — New interval in seconds.
        methods.add_method_mut("setInterval", |_, this, (id, interval): (u32, f64)| {
            Ok(this.scheduler.set_interval(id, interval))
        });

        // Reset remaining time of event ID back to its original interval. Returns true if found.
        /// Resets the elapsed time of the given timer so it fires again after its full interval.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — Timer ID to reset.
        methods.add_method_mut("resetEvent", |_, this, id: u32| {
            Ok(this.scheduler.reset_event(id))
        });

        // ── Time Scale ────────────────────────────────────────────────────

        // Set global time-scale for this scheduler (0 = frozen, 1 = normal, 2 = double speed).
        /// Sets a time-scale factor that speeds up or slows down all timers in the scheduler.
        /// @param scale : number
        ///
        /// # Parameters
        /// - `scale` — Time multiplier (1.0 = real time, 2.0 = double speed).
        methods.add_method_mut("setTimeScale", |_, this, scale: f64| {
            this.scheduler.set_time_scale(scale);
            Ok(())
        });

        // Get current time-scale.
        /// Returns the current time-scale factor applied to all timers in this scheduler.
        /// @return any
        ///
        /// # Returns
        /// Time scale as a number (1.0 = real time, 0.5 = half speed).
        methods.add_method("getTimeScale", |_, this, ()| {
            Ok(this.scheduler.get_time_scale())
        });

        // ── Update ────────────────────────────────────────────────────────

        // Advance all non-paused timers by `dt` seconds.
        // Fires registered Lua callbacks for each expired event.
        // Returns the number of callbacks that fired.
        /// Advances all pending timers by dt seconds.
        /// @param dt : number
        /// @return any
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
            // Clean up callbacks for events that no longer exist
            let active_ids: std::collections::HashSet<u32> =
                this.scheduler.active_ids().into_iter().collect();
            let dead: Vec<u32> = this
                .callbacks
                .keys()
                .filter(|id| !active_ids.contains(id))
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

/// Registers `luna.timer.*` functions into the Lua VM.
///
/// Provides frame-timing utilities: delta time, FPS, total time, average delta,
/// high-precision timing, manual step control, and thread sleep.
///
/// # Parameters
/// - `lua` — The active Lua VM instance.
/// - `luna` — The `luna` global table to attach functions to.
/// - `state` — Shared engine state accessed by the registered closures.
///
/// # Returns
/// `LuaResult<()>` — Ok if all functions were registered successfully; Lua error otherwise.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let timer = lua.create_table()?;

    /// Returns the delta time (seconds) for the current frame.
    let s = state.clone();
    /// @return any
    timer.set(
        "getDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().delta_time))?,
    )?;

    /// Returns the measured frames-per-second for the current frame.
    let s = state.clone();
    /// @return any
    timer.set(
        "getFPS",
        lua.create_function(move |_, ()| Ok(s.borrow().fps))?,
    )?;

    /// Returns the total elapsed time in seconds since engine start.
    let s = state.clone();
    /// @return any
    timer.set(
        "getTime",
        lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
    )?;

    /// Returns the rolling-average frame delta time in seconds.
    let s = state.clone();
    /// @return any
    timer.set(
        "getAverageDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.average_delta()))?,
    )?;

    /// Advances the timer by one step (called automatically each frame).
    let s = state.clone();
    /// @return any
    timer.set(
        "step",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            let dt = st.clock.tick();
            st.delta_time = dt;
            st.total_time = st.clock.total();
            st.fps = st.clock.fps();
            Ok(dt)
        })?,
    )?;

    let start_time = std::time::Instant::now();
    /// Returns the high-resolution monotonic timer value in microseconds.
    ///
    /// # Returns
    /// Elapsed microseconds as a 64-bit integer.
    timer.set(
        "getMicroTime",
        lua.create_function(move |_, ()| Ok(start_time.elapsed().as_secs_f64()))?,
    )?;

    /// Suspends execution for the given number of seconds.
    /// @param seconds : number
    timer.set(
        "sleep",
        lua.create_function(|_, seconds: f64| {
            if seconds > 0.0 {
                std::thread::sleep(std::time::Duration::from_secs_f64(seconds));
            }
            Ok(())
        })?,
    )?;

    // luna.timer.newScheduler() -> Scheduler userdata
    /// Creates an independent timer scheduler for managing a set of callbacks.
    ///
    /// # Returns
    /// New Scheduler object with its own after/every/update interface.
    timer.set(
        "newScheduler",
        lua.create_function(move |lua, ()| lua.create_userdata(LuaScheduler::new()))?,
    )?;

    /// Timer.
    luna.set("timer", timer)?;
    Ok(())
}
