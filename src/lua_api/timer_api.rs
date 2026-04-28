//! `lurek.timer` - Frame timing, FPS tracking, and scheduled Lua callbacks.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;

use crate::timer::Scheduler;

// ---------------------------------------------------------------------------
// LuaScheduler UserData
// ---------------------------------------------------------------------------

/// Lua-side wrapper around a [`Scheduler`] with per-event callback storage.
pub struct LuaScheduler {
    scheduler: Scheduler,
    callbacks: HashMap<u32, LuaRegistryKey>,
    named_ids: HashMap<String, u32>,
}

impl LuaScheduler {
    // Creates a new empty scheduler with no pending events.
    fn new() -> Self {
        Self {
            scheduler: Scheduler::new(),
            callbacks: HashMap::new(),
            named_ids: HashMap::new(),
        }
    }

    // Remove a callback registry key for an expired or cancelled event.
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
        /// @param | delay | number | Delay in seconds.
        /// @param | callback | function | Callback function.
        /// @return | integer | Scheduled event ID.
        methods.add_method_mut("after", |lua, this, (delay, func): (f64, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let id = this.scheduler.after(delay);
            this.callbacks.insert(id, key);
            Ok(id)
        });

        // -- afterFrames --
        /// Schedules a callback to fire once after `n` frames.
        /// @param | n | integer | Number of frames to wait.
        /// @param | callback | function | Callback function.
        /// @return | integer | Scheduled event ID.
        methods.add_method_mut("afterFrames", |lua, this, (n, func): (u64, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let id = this.scheduler.after_frames(n);
            this.callbacks.insert(id, key);
            Ok(id)
        });

        // -- afterNamed --
        /// Schedules a named one-shot callback, replacing any existing event with the same name.
        /// @param | name | string | Scheduler event name.
        /// @param | delay | number | Delay in seconds.
        /// @param | callback | function | Callback function.
        /// @return | integer | Scheduled event ID.
        methods.add_method_mut("afterNamed", |lua, this, (name, delay, func): (String, f64, LuaFunction)| {
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
        /// @param | interval | number | Interval in seconds.
        /// @param | callback | function | Callback function.
        /// @param | count | integer? | Optional repeat count; defaults to infinite.
        /// @return | integer | Scheduled event ID.
        methods.add_method_mut("every", |lua, this, (interval, func, count): (f64, LuaFunction, Option<i32>)| {
                let key = lua.create_registry_value(func)?;
                let id = this.scheduler.every(interval, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                Ok(id)
            },
        );

        // -- everyFrames --
        /// Schedules a callback to fire every `n` frames.
        /// @param | n | integer | Frame interval between callbacks.
        /// @param | func | function | Callback function.
        /// @param | count | integer? | Optional repeat count; defaults to infinite.
        /// @return | integer | Scheduled event ID.
        methods.add_method_mut("everyFrames", |lua, this, (n, func, count): (u64, LuaFunction, Option<i32>)| {
                let key = lua.create_registry_value(func)?;
                let id = this.scheduler.every_frames(n, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                Ok(id)
            },
        );

        // -- everyNamed --
        /// Schedules a named repeating callback, replacing any existing event with the same name.
        /// @param | name | string | Scheduler event name.
        /// @param | interval | number | Interval in seconds.
        /// @param | callback | function | Callback function.
        /// @param | count | integer? | Optional repeat count; defaults to infinite.
        /// @return | integer | Scheduled event ID.
        methods.add_method_mut("everyNamed", |lua, this, (name, interval, func, count): (String, f64, LuaFunction, Option<i32>)| {
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
        /// @param | id | integer | Scheduled event ID.
        /// @return | boolean | True if the scheduled event was found and cancelled.
        methods.add_method_mut("cancel", |lua, this, id: u32| {
            let removed = this.scheduler.cancel(id);
            if removed {
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                this.named_ids.retain(|_, v| *v != id);
            }
            Ok(removed)
        });

        // -- cancelNamed --
        /// Cancels and removes a previously scheduled event identified by its string name assigned via `afterNamed` or `everyNamed`.
        /// @param | name | string | The string name given when the event was scheduled
        /// @return | boolean | True if the named event existed and was cancelled
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
        /// @return | integer | Returned integer.
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
        /// @param | id | integer | Scheduled event ID.
        /// @return | boolean | True if the event was found and paused.
        methods.add_method_mut("pause", |_, this, id: u32| Ok(this.scheduler.pause(id)));

        // -- resume --
        /// Resumes a paused event by its ID.
        /// @param | id | integer | Scheduled event ID.
        /// @return | boolean | True if the event was found and resumed.
        methods.add_method_mut("resume", |_, this, id: u32| Ok(this.scheduler.resume(id)));

        // -- isPaused --
        /// Returns whether the given event is currently paused.
        /// @param | id | integer | Scheduled event ID.
        /// @return | boolean | True when the event is currently paused.
        methods.add_method("isPaused", |_, this, id: u32| {
            Ok(this.scheduler.is_paused(id))
        });

        // -- pauseNamed --
        /// Temporarily suspends the named scheduled event so it stops accumulating time.
        /// @param | name | string | The string name of the event to pause
        /// @return | boolean | True if the named event existed and was paused
        methods.add_method_mut("pauseNamed", |_, this, name: String| {
            Ok(this.scheduler.pause_named(&name))
        });

        // -- resumeNamed --
        /// Resumes a previously paused named event so it continues accumulating time.
        /// @param | name | string | The string name of the event to resume
        /// @return | boolean | True if the named event existed and was resumed
        methods.add_method_mut("resumeNamed", |_, this, name: String| {
            Ok(this.scheduler.resume_named(&name))
        });

        // -- isPausedNamed --
        /// Checks whether the named scheduled event is currently in the paused state.
        /// @param | name | string | The string name of the event to check
        /// @return | boolean | True if the named event is paused
        methods.add_method("isPausedNamed", |_, this, name: String| {
            Ok(this.scheduler.is_paused_named(&name))
        });

        // -- getRemaining --
        /// Returns whether the event exists and how many seconds remain until it fires next.
        /// @param | id | integer | The event identifier to query
        /// @return | boolean | True when the event exists.
        /// @return | number | Remaining seconds until the event fires next.
        methods.add_method("getRemaining", |_, this, id: u32| {
            match this.scheduler.get_remaining(id) {
                Some(value) => Ok((true, value)),
                None => Ok((false, 0.0)),
            }
        });

        // -- getInterval --
        /// Returns whether the event exists and its configured base interval in seconds.
        /// @param | id | integer | The event identifier to query
        /// @return | boolean | True when the event exists.
        /// @return | number | Configured base interval in seconds.
        methods.add_method("getInterval", |_, this, id: u32| {
            match this.scheduler.get_interval(id) {
                Some(value) => Ok((true, value)),
                None => Ok((false, 0.0)),
            }
        });

        // -- getRepeatCount --
        /// Returns whether the event exists and its remaining repetition count.
        /// @param | id | integer | The event identifier to query
        /// @return | boolean | True when the event exists.
        /// @return | integer | Remaining repetition count.
        methods.add_method("getRepeatCount", |_, this, id: u32| {
            match this.scheduler.get_repeat_count(id) {
                Some(value) => Ok((true, value)),
                None => Ok((false, 0)),
            }
        });

        // -- getCount --
        /// Returns the total number of currently active (not yet completed or cancelled) events in this scheduler instance.
        /// @return | integer | The count of active scheduled events
        methods.add_method("getCount", |_, this, ()| Ok(this.scheduler.count() as u32));

        // -- isEmpty --
        /// Returns true if this scheduler has zero active events.
        /// @return | boolean | True if there are no active events
        methods.add_method("isEmpty", |_, this, ()| Ok(this.scheduler.is_empty()));

        // -- setInterval --
        /// Modifies the repeat interval of an already-scheduled repeating event.
        /// @param | id | integer | The event identifier to modify
        /// @param | interval | number | The new interval in seconds
        /// @return | boolean | True if the event existed and its interval was changed
        methods.add_method_mut("setInterval", |_, this, (id, interval): (u32, f64)| {
            Ok(this.scheduler.set_interval(id, interval))
        });

        // -- resetEvent --
        /// Resets the countdown for a scheduled event back to its full configured interval, as if it had just been created.
        /// @param | id | integer | The event identifier to reset
        /// @return | boolean | True if the event existed and was reset
        methods.add_method_mut("resetEvent", |_, this, id: u32| {
            Ok(this.scheduler.reset_event(id))
        });

        // -- setTimeScale --
        /// Sets a time-scale multiplier that affects all events in this scheduler.
        /// @param | scale | number | The time-scale multiplier (0.0 or greater)
        /// @return | nil | No return value.
        methods.add_method_mut("setTimeScale", |_, this, scale: f64| {
            this.scheduler.set_time_scale(scale);
            Ok(())
        });

        // -- getTimeScale --
        /// Returns the current time-scale multiplier for this scheduler instance.
        /// @return | number | The active time-scale multiplier
        methods.add_method("getTimeScale", |_, this, ()| {
            Ok(this.scheduler.get_time_scale())
        });

        // -- update --
        /// Advances all time-based events in this scheduler by `dt` seconds (scaled by the scheduler's time-scale multiplier).
        /// @param | dt | number | Delta time in seconds since the last update call
        /// @return | integer | The number of callbacks that were fired
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

        // -- updateFrames --
        /// Advances all frame-based events by one frame tick.
        /// @return | integer | The number of callbacks that were fired
        methods.add_method_mut("updateFrames", |lua, this, ()| {
            let fired_ids = this.scheduler.update_frames();
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

        // -- type --
        /// Returns the string type name of this userdata object.
        /// @return | string | The type name (e.g. "LScheduler", "LCamera", "LSignal")
        methods.add_method("type", |_, _, ()| Ok("LScheduler"));

        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | The type name to check against (e.g. "LScheduler", "Object")
        /// @return | boolean | True if this object matches the given type name
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LScheduler" || name == "Object")
        });
    }
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

/// Registers the `lurek.timer` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- getDelta --
    /// Returns the time elapsed since the previous frame in seconds.
    /// @return | number | Delta time in seconds for the current frame
    let s = state.clone();
    tbl.set("getDelta", lua.create_function(move |_, ()| Ok(s.borrow().delta_time))?,
    )?;

    // -- getFPS --
    /// Returns the current instantaneous frames-per-second as measured by the engine clock.
    /// @return | number | The current FPS value
    let s = state.clone();
    tbl.set("getFPS", lua.create_function(move |_, ()| Ok(s.borrow().fps))?,
    )?;

    // -- getTime --
    /// Returns the total wall-clock time that has elapsed since the engine was initialised, in seconds.
    /// @return | number | Total elapsed seconds since engine start
    let s = state.clone();
    tbl.set("getTime", lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
    )?;

    // -- getAverageDelta --
    /// Returns a rolling average of recent frame delta times in seconds.
    /// @return | number | Rolling average delta time in seconds
    let s = state.clone();
    tbl.set("getAverageDelta", lua.create_function(move |_, ()| Ok(s.borrow().clock.average_delta()))?,
    )?;

    // -- getFrameCount --
    /// Returns the total number of frames that have been rendered since the engine was initialised.
    /// @return | integer | Total frame count since engine start
    let s = state.clone();
    tbl.set("getFrameCount", lua.create_function(move |_, ()| Ok(s.borrow().clock.frame_count()))?,
    )?;

    // -- step --
    /// Manually advances the engine timer by one frame tick and returns the resulting delta time.
    /// @return | number | The delta time for the stepped frame
    let s = state.clone();
    tbl.set("step", lua.create_function(move |_, ()| Ok(s.borrow_mut().step_timer()))?,
    )?;

    // -- getMicroTime --
    /// Returns the high-resolution (microsecond-precision) elapsed time since engine start in seconds.
    /// @return | number | High-resolution elapsed seconds
    let s = state.clone();
    tbl.set("getMicroTime", lua.create_function(move |_, ()| Ok(s.borrow().clock.elapsed()))?,
    )?;

    // -- getPhysicsDelta --
    /// Returns the fixed timestep interval used by the `process_physics` callback loop, in seconds.
    /// @return | number | The fixed physics timestep in seconds
    let s = state.clone();
    tbl.set("getPhysicsDelta", lua.create_function(move |_, ()| Ok(s.borrow().physics_fixed_dt))?,
    )?;

    // -- setPhysicsDelta --
    /// Sets the fixed timestep interval for the `process_physics` callback loop, in seconds.
    /// @param | dt | number | The desired fixed timestep in seconds
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set("setPhysicsDelta", lua.create_function(move |_, dt: f64| {
            let clamped = dt.clamp(1.0 / 240.0, 1.0 / 10.0);
            s.borrow_mut().physics_fixed_dt = clamped;
            Ok(())
        })?,
    )?;

    // -- getPhysicsMaxSteps --
    /// Returns the maximum number of physics simulation sub-steps that the engine will perform in a single frame.
    /// @return | integer | The maximum physics sub-steps per frame
    let s = state.clone();
    tbl.set("getPhysicsMaxSteps", lua.create_function(move |_, ()| Ok(s.borrow().physics_max_steps))?,
    )?;

    // -- setPhysicsMaxSteps --
    /// Sets the maximum number of physics simulation sub-steps allowed per frame.
    /// @param | n | integer | The desired maximum sub-step count (clamped to 1-64)
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set("setPhysicsMaxSteps", lua.create_function(move |_, n: u32| {
            s.borrow_mut().physics_max_steps = n.clamp(1, 64);
            Ok(())
        })?,
    )?;

    // -- sleep --
    /// Blocks the current thread for the specified number of seconds using an OS-level sleep.
    /// @param | seconds | number | Duration to sleep in seconds
    /// @return | nil | No return value.
    tbl.set("sleep", lua.create_function(|_, seconds: f64| {
            crate::timer::sleep(seconds);
            Ok(())
        })?,
    )?;

    // -- newScheduler --
    /// Creates and returns a new independent Scheduler userdata object for managing timed and frame-based callbacks.
    /// @return | LScheduler | A new scheduler instance
    tbl.set("newScheduler", lua.create_function(|lua, ()| lua.create_userdata(LuaScheduler::new()))?,
    )?;

    // -- chain --
    /// Creates a new Scheduler pre-loaded with a sequence of one-shot callbacks that fire in order with cumulative delays.
    /// @param | steps | table | Array of {delay: number, func: function} entries
    /// @return | LScheduler | A new scheduler pre-loaded with the chained callbacks
    tbl.set("chain", lua.create_function(|lua, steps: LuaTable| {
            let mut sched = LuaScheduler::new();
            let mut accumulated: f64 = 0.0;
            let len = steps.raw_len();
            for i in 1..=len {
                let step: LuaTable = steps.raw_get(i)?;
                let delay: f64 = step.get("delay").unwrap_or(0.0);
                let func: Option<LuaFunction> = step.get("func")?;
                accumulated += delay.max(0.0);
                if let Some(f) = func {
                    let key = lua.create_registry_value(f)?;
                    let id = sched.scheduler.after(accumulated);
                    sched.callbacks.insert(id, key);
                }
            }
            lua.create_userdata(sched)
        })?,
    )?;

    // Real-clock timer list: (deadline_instant, callback_key).
    let real_timers: Rc<RefCell<Vec<(std::time::Instant, LuaRegistryKey)>>> =
        Rc::new(RefCell::new(Vec::new()));

    // -- afterReal --
    /// Schedules a one-shot callback that fires after `delay` wall-clock seconds, completely unaffected by the engine's time scale or pause state.
    /// @param | delay | number | Wall-clock seconds to wait before firing
    /// @param | func | function | The Lua function to call when the deadline arrives
    /// @return | nil | No return value.
    let rt = real_timers.clone();
    tbl.set("afterReal", lua.create_function(move |lua, (delay, func): (f64, LuaFunction)| {
            let deadline =
                std::time::Instant::now() + std::time::Duration::from_secs_f64(delay.max(0.0));
            let key = lua.create_registry_value(func)?;
            rt.borrow_mut().push((deadline, key));
            Ok(())
        })?,
    )?;

    // -- tickRealTimers --
    /// Checks all registered real-time timers and fires any whose wall-clock deadline has passed.
    /// @return | integer | The number of real-time callbacks that fired
    let rt = real_timers;
    tbl.set("tickRealTimers", lua.create_function(move |lua, ()| {
            let now = std::time::Instant::now();
            let mut timers = rt.borrow_mut();
            let mut fired = 0u32;
            let mut remaining = Vec::new();
            for (deadline, key) in timers.drain(..) {
                if now >= deadline {
                    if let Ok(func) = lua.registry_value::<LuaFunction>(&key) {
                        let _ = func.call::<_, ()>(());
                    }
                    lua.remove_registry_value(key)?;
                    fired += 1;
                } else {
                    remaining.push((deadline, key));
                }
            }
            *timers = remaining;
            Ok(fired)
        })?,
    )?;

    // Smoothed-delta state " exponential moving average of frame deltas.
    let smoothed: Rc<RefCell<f64>> = Rc::new(RefCell::new(0.0));
    let smooth_alpha: Rc<RefCell<f64>> = Rc::new(RefCell::new(0.1));

    // -- setSmoothingFactor --
    /// Sets the exponential moving-average smoothing factor (alpha) used by `getSmoothedDelta`.
    /// @param | alpha | number | Smoothing factor between 0.01 (very smooth) and 1.0 (raw)
    /// @return | nil | No return value.
    let sa = smooth_alpha.clone();
    tbl.set("setSmoothingFactor", lua.create_function(move |_, alpha: f64| {
            *sa.borrow_mut() = alpha.clamp(0.01, 1.0);
            Ok(())
        })?,
    )?;

    // -- getSmoothedDelta --
    /// Returns the exponentially smoothed frame delta time in seconds.
    /// @return | number | The smoothed delta time in seconds
    let s = state.clone();
    let smoothed_ref = smoothed.clone();
    let alpha_ref = smooth_alpha.clone();
    tbl.set("getSmoothedDelta", lua.create_function(move |_, ()| {
            let dt = s.borrow().delta_time;
            let alpha = *alpha_ref.borrow();
            let mut sm = smoothed_ref.borrow_mut();
            if *sm == 0.0 {
                *sm = dt;
            } else {
                *sm = alpha * dt + (1.0 - alpha) * *sm;
            }
            Ok(*sm)
        })?,
    )?;

    // Coroutine wait lists.
    // Each entry: (LuaRegistryKey holding the LuaThread, deadline Instant)
    let wait_secs: Rc<RefCell<Vec<(LuaRegistryKey, std::time::Instant)>>> =
        Rc::new(RefCell::new(Vec::new()));

    // Coroutine frame-wait list.
    // Each entry: (LuaRegistryKey holding the LuaThread, target frame_count)
    let wait_frames: Rc<RefCell<Vec<(LuaRegistryKey, u64)>>> = Rc::new(RefCell::new(Vec::new()));

    // -- waitSeconds --
    /// Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
    /// @param | seconds | number | Minimum wall-clock seconds to wait
    /// @return | nil | No return value.
    let ws = wait_secs.clone();
    tbl.set("waitSeconds", lua.create_function(move |lua, seconds: f64| {
            let deadline =
                std::time::Instant::now() + std::time::Duration::from_secs_f64(seconds.max(0.0));
            let co_tbl: LuaTable = lua.globals().get("coroutine")?;
            let running_fn: LuaFunction = co_tbl.get("running")?;
            let thread_val: LuaValue = running_fn.call(())?;
            if matches!(thread_val, LuaValue::Nil) {
                return Err(LuaError::RuntimeError(
                    "lurek.timer.waitSeconds: must be called from within a coroutine".into(),
                ));
            }
            let key = lua.create_registry_value(thread_val)?;
            ws.borrow_mut().push((key, deadline));
            let yield_fn: LuaFunction = co_tbl.get("yield")?;
            yield_fn.call::<_, ()>(())?;
            Ok(())
        })?,
    )?;

    // -- waitFrames --
    /// Yields the current Lua coroutine until at least `frames` engine frames have elapsed.
    /// @param | frames | integer | Number of engine frames to wait
    /// @return | nil | No return value.
    let wf = wait_frames.clone();
    let s_wf = state.clone();
    tbl.set("waitFrames", lua.create_function(move |lua, frames: u64| {
            let target = s_wf.borrow().clock.frame_count() + frames;
            let co_tbl: LuaTable = lua.globals().get("coroutine")?;
            let running_fn: LuaFunction = co_tbl.get("running")?;
            let thread_val: LuaValue = running_fn.call(())?;
            if matches!(thread_val, LuaValue::Nil) {
                return Err(LuaError::RuntimeError(
                    "lurek.timer.waitFrames: must be called from within a coroutine".into(),
                ));
            }
            let key = lua.create_registry_value(thread_val)?;
            wf.borrow_mut().push((key, target));
            let yield_fn: LuaFunction = co_tbl.get("yield")?;
            yield_fn.call::<_, ()>(())?;
            Ok(())
        })?,
    )?;

    // -- tickWaits --
    /// Resumes all coroutines waiting via `waitSeconds` or `waitFrames` whose deadline or frame target has been reached.
    /// @return | integer | Number of coroutines resumed in this tick
    let ws_tick = wait_secs;
    let wf_tick = wait_frames;
    let s_tick = state.clone();
    tbl.set("tickWaits", lua.create_function(move |lua, ()| {
            let now = std::time::Instant::now();
            let current_frame = s_tick.borrow().clock.frame_count();
            let mut resumed = 0u32;

            // Time-based waits.
            let mut pending_s = ws_tick.borrow_mut();
            let mut still_s: Vec<(LuaRegistryKey, std::time::Instant)> = Vec::new();
            let mut ready_s: Vec<LuaRegistryKey> = Vec::new();
            for (key, deadline) in pending_s.drain(..) {
                if now >= deadline {
                    ready_s.push(key);
                } else {
                    still_s.push((key, deadline));
                }
            }
            *pending_s = still_s;
            drop(pending_s);

            for key in ready_s {
                if let Ok(LuaValue::Thread(thread)) = lua.registry_value::<LuaValue>(&key) {
                    let _ = thread.resume::<_, ()>(());
                    resumed += 1;
                }
                lua.remove_registry_value(key)?;
            }

            // Frame-based waits.
            let mut pending_f = wf_tick.borrow_mut();
            let mut still_f: Vec<(LuaRegistryKey, u64)> = Vec::new();
            let mut ready_f: Vec<LuaRegistryKey> = Vec::new();
            for (key, target) in pending_f.drain(..) {
                if current_frame >= target {
                    ready_f.push(key);
                } else {
                    still_f.push((key, target));
                }
            }
            *pending_f = still_f;
            drop(pending_f);

            for key in ready_f {
                if let Ok(LuaValue::Thread(thread)) = lua.registry_value::<LuaValue>(&key) {
                    let _ = thread.resume::<_, ()>(());
                    resumed += 1;
                }
                lua.remove_registry_value(key)?;
            }

            Ok(resumed)
        })?,
    )?;

    let wait_fn: LuaValue = tbl.get("waitSeconds")?;
    // -- delay --
    /// Semantic alias for `waitSeconds`.
    /// @param | seconds | number | Minimum seconds to yield
    /// @return | nil | No return value.
    tbl.set("delay", wait_fn)?;

    lurek.set("timer", tbl)?;
    Ok(())
}
