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
    fn remove_callback(lua: &Lua, callbacks: &mut HashMap<u32, LuaRegistryKey>, id: u32) -> LuaResult<()> {
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
                let id = this.scheduler.every_named(name.clone(), interval, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                this.named_ids.insert(name, id);
                Ok(id)
            },
        );

        // ── Cancellation ──────────────────────────────────────────────────

        // Cancel event by numeric ID. Returns true if found.
        methods.add_method_mut("cancel", |lua, this, id: u32| {
            let removed = this.scheduler.cancel(id);
            if removed {
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                this.named_ids.retain(|_, v| *v != id);
            }
            Ok(removed)
        });

        // Cancel event by name. Returns true if found.
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
        methods.add_method_mut("pause", |_, this, id: u32| Ok(this.scheduler.pause(id)));

        // Resume event by ID. Returns true if found.
        methods.add_method_mut("resume", |_, this, id: u32| Ok(this.scheduler.resume(id)));

        // Returns true if event ID is currently paused.
        methods.add_method("isPaused", |_, this, id: u32| Ok(this.scheduler.is_paused(id)));

        // ── Queries ───────────────────────────────────────────────────────

        // Returns seconds remaining until next fire for event ID, or nil.
        methods.add_method("getRemaining", |_, this, id: u32| {
            Ok(this.scheduler.get_remaining(id))
        });

        // Returns the base interval for event ID, or nil.
        methods.add_method("getInterval", |_, this, id: u32| {
            Ok(this.scheduler.get_interval(id))
        });

        // Returns the repeat count remaining (-1=infinite) for event ID, or nil.
        methods.add_method("getRepeatCount", |_, this, id: u32| {
            Ok(this.scheduler.get_repeat_count(id))
        });

        // Returns active event count.
        methods.add_method("getCount", |_, this, ()| Ok(this.scheduler.count() as u32));

        // Returns true if no events are scheduled.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.scheduler.is_empty()));

        // ── Modification ──────────────────────────────────────────────────

        // Change the interval of a repeating event ID. Returns true if found.
        methods.add_method_mut("setInterval", |_, this, (id, interval): (u32, f64)| {
            Ok(this.scheduler.set_interval(id, interval))
        });

        // Reset remaining time of event ID back to its original interval. Returns true if found.
        methods.add_method_mut("resetEvent", |_, this, id: u32| {
            Ok(this.scheduler.reset_event(id))
        });

        // ── Time Scale ────────────────────────────────────────────────────

        // Set global time-scale for this scheduler (0 = frozen, 1 = normal, 2 = double speed).
        methods.add_method_mut("setTimeScale", |_, this, scale: f64| {
            this.scheduler.set_time_scale(scale);
            Ok(())
        });

        // Get current time-scale.
        methods.add_method("getTimeScale", |_, this, ()| {
            Ok(this.scheduler.get_time_scale())
        });

        // ── Update ────────────────────────────────────────────────────────

        // Advance all non-paused timers by `dt` seconds.
        // Fires registered Lua callbacks for each expired event.
        // Returns the number of callbacks that fired.
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

    let s = state.clone();
    timer.set(
        "getDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().delta_time))?,
    )?;

    let s = state.clone();
    timer.set(
        "getFPS",
        lua.create_function(move |_, ()| Ok(s.borrow().fps))?,
    )?;

    let s = state.clone();
    timer.set(
        "getTime",
        lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
    )?;

    let s = state.clone();
    timer.set(
        "getAverageDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.average_delta()))?,
    )?;

    let s = state.clone();
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
    timer.set(
        "getMicroTime",
        lua.create_function(move |_, ()| Ok(start_time.elapsed().as_secs_f64()))?,
    )?;

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
    timer.set(
        "newScheduler",
        lua.create_function(move |lua, ()| lua.create_userdata(LuaScheduler::new()))?,
    )?;

    luna.set("timer", timer)?;
    Ok(())
}
