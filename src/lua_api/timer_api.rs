//! `lurek.timer` - Provides time management with delta time, fixed timestep, cooldowns, delays, intervals, and frame counting.

use super::SharedState;
use crate::timer::Scheduler;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;

/// A Lua-exposed event scheduler that fires callbacks after timed delays or frame counts, with support for repeating intervals, named entries, pausing, and time-scaling.
pub struct LuaScheduler {
    scheduler: Scheduler,
    callbacks: HashMap<u32, LuaRegistryKey>,
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
        /// Schedules a one-shot callback to fire after the given delay in seconds. Returns an event ID that can be used to cancel, pause, or query the event.
        /// @param | delay | number | Time in seconds before the callback fires.
        /// @param | func | function | Callback to invoke when the delay elapses.
        /// @return | number | Unique event ID for this scheduled callback.
        methods.add_method_mut("after", |lua, this, (delay, func): (f64, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let id = this.scheduler.after(delay);
            this.callbacks.insert(id, key);
            Ok(id)
        });
        // -- afterFrames --
        /// Schedules a one-shot callback to fire after the given number of frames. Returns an event ID for management.
        /// @param | n | number | Number of frames to wait before the callback fires.
        /// @param | func | function | Callback to invoke when the frame count elapses.
        /// @return | number | Unique event ID for this scheduled callback.
        methods.add_method_mut("afterFrames", |lua, this, (n, func): (u64, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let id = this.scheduler.after_frames(n);
            this.callbacks.insert(id, key);
            Ok(id)
        });
        // -- afterNamed --
        /// Schedules a named one-shot callback after a delay in seconds. If a callback with the same name already exists, the old one is cancelled and replaced. Useful for debouncing or resettable delays.
        /// @param | name | string | Unique name for this scheduled event.
        /// @param | delay | number | Time in seconds before the callback fires.
        /// @param | func | function | Callback to invoke when the delay elapses.
        /// @return | number | Unique event ID for this scheduled callback.
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
        /// Schedules a repeating callback that fires at a fixed interval in seconds. Pass a positive count to limit repetitions, or omit/pass -1 to repeat indefinitely.
        /// @param | interval | number | Time in seconds between each invocation.
        /// @param | func | function | Callback to invoke on each interval tick.
        /// @param | count | number? | Maximum number of times to fire. Defaults to -1 (infinite).
        /// @return | number | Unique event ID for this repeating callback.
        methods.add_method_mut(
            "every",
            |lua, this, (interval, func, count): (f64, LuaFunction, Option<i32>)| {
                let key = lua.create_registry_value(func)?;
                let id = this.scheduler.every(interval, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                Ok(id)
            },
        );
        // -- everyFrames --
        /// Schedules a repeating callback that fires every N frames. Pass a positive count to limit repetitions, or omit/pass -1 to repeat indefinitely.
        /// @param | n | number | Number of frames between each invocation.
        /// @param | func | function | Callback to invoke on each frame-interval tick.
        /// @param | count | number? | Maximum number of times to fire. Defaults to -1 (infinite).
        /// @return | number | Unique event ID for this repeating callback.
        methods.add_method_mut(
            "everyFrames",
            |lua, this, (n, func, count): (u64, LuaFunction, Option<i32>)| {
                let key = lua.create_registry_value(func)?;
                let id = this.scheduler.every_frames(n, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                Ok(id)
            },
        );
        // -- everyNamed --
        /// Schedules a named repeating callback at a fixed interval. If a callback with the same name already exists, the old one is cancelled and replaced. Useful for restartable periodic effects like health regeneration or status ticks.
        /// @param | name | string | Unique name for this repeating event.
        /// @param | interval | number | Time in seconds between each invocation.
        /// @param | func | function | Callback to invoke on each interval tick.
        /// @param | count | number? | Maximum number of times to fire. Defaults to -1 (infinite).
        /// @return | number | Unique event ID for this repeating callback.
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
        /// Cancels a scheduled event by its ID. Returns true if the event was found and removed, false if it did not exist.
        /// @param | id | number | Event ID returned by after, every, or their variants.
        /// @return | boolean | True if the event was found and cancelled.
        methods.add_method_mut("cancel", |lua, this, id: u32| {
            let removed = this.scheduler.cancel(id);
            if removed {
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                this.named_ids.retain(|_, v| *v != id);
            }
            Ok(removed)
        });
        // -- cancelNamed --
        /// Cancels a named scheduled event. Returns true if the named event was found and removed.
        /// @param | name | string | The name used when scheduling with afterNamed or everyNamed.
        /// @return | boolean | True if the named event was found and cancelled.
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
        /// Cancels all scheduled events in this scheduler and frees their callbacks. Returns the number of events that were removed.
        /// @return | number | Count of events that were cancelled.
        methods.add_method_mut("cancelAll", |lua, this, ()| {
            let n = this.scheduler.cancel_all();
            for (_, key) in this.callbacks.drain() {
                lua.remove_registry_value(key)?;
            }
            this.named_ids.clear();
            Ok(n)
        });
        // -- pause --
        /// Pauses a scheduled event so it stops accumulating time. Returns true if the event was found and paused.
        /// @param | id | number | Event ID to pause.
        /// @return | boolean | True if the event exists and was paused.
        methods.add_method_mut("pause", |_, this, id: u32| Ok(this.scheduler.pause(id)));
        // -- resume --
        /// Resumes a previously paused event so it continues accumulating time. Returns true if the event was found and resumed.
        /// @param | id | number | Event ID to resume.
        /// @return | boolean | True if the event exists and was resumed.
        methods.add_method_mut("resume", |_, this, id: u32| Ok(this.scheduler.resume(id)));
        // -- isPaused --
        /// Checks whether a scheduled event is currently paused.
        /// @param | id | number | Event ID to check.
        /// @return | boolean | True if the event is paused, false if running or not found.
        methods.add_method("isPaused", |_, this, id: u32| {
            Ok(this.scheduler.is_paused(id))
        });
        // -- pauseNamed --
        /// Pauses a named scheduled event. Returns true if the named event was found and paused.
        /// @param | name | string | The name used when scheduling.
        /// @return | boolean | True if the named event exists and was paused.
        methods.add_method_mut("pauseNamed", |_, this, name: String| {
            Ok(this.scheduler.pause_named(&name))
        });
        // -- resumeNamed --
        /// Resumes a previously paused named event. Returns true if the named event was found and resumed.
        /// @param | name | string | The name used when scheduling.
        /// @return | boolean | True if the named event exists and was resumed.
        methods.add_method_mut("resumeNamed", |_, this, name: String| {
            Ok(this.scheduler.resume_named(&name))
        });
        // -- isPausedNamed --
        /// Checks whether a named scheduled event is currently paused.
        /// @param | name | string | The name used when scheduling.
        /// @return | boolean | True if the named event is paused.
        methods.add_method("isPausedNamed", |_, this, name: String| {
            Ok(this.scheduler.is_paused_named(&name))
        });
        // -- getRemaining --
        /// Returns the remaining time in seconds before the event fires. The first return value indicates whether the event was found; the second is the remaining time (0.0 if not found).
        /// @param | id | number | Event ID to query.
        /// @return | boolean | True if the event exists.
        /// @return | number | Remaining time in seconds, or 0.0 if not found.
        methods.add_method("getRemaining", |_, this, id: u32| {
            match this.scheduler.get_remaining(id) {
                Some(value) => Ok((true, value)),
                None => Ok((false, 0.0)),
            }
        });
        // -- getInterval --
        /// Returns the interval duration in seconds for a repeating event. The first return value indicates whether the event was found; the second is the interval (0.0 if not found).
        /// @param | id | number | Event ID to query.
        /// @return | boolean | True if the event exists.
        /// @return | number | Interval in seconds, or 0.0 if not found.
        methods.add_method("getInterval", |_, this, id: u32| {
            match this.scheduler.get_interval(id) {
                Some(value) => Ok((true, value)),
                None => Ok((false, 0.0)),
            }
        });
        // -- getRepeatCount --
        /// Returns the remaining repeat count for a repeating event. The first return value indicates whether the event was found; the second is the count (0 if not found). A value of -1 means infinite repeats.
        /// @param | id | number | Event ID to query.
        /// @return | boolean | True if the event exists.
        /// @return | number | Remaining repeat count, or 0 if not found.
        methods.add_method("getRepeatCount", |_, this, id: u32| {
            match this.scheduler.get_repeat_count(id) {
                Some(value) => Ok((true, value)),
                None => Ok((false, 0)),
            }
        });
        // -- getCount --
        /// Returns the total number of active scheduled events in this scheduler.
        /// @return | number | Count of active events.
        methods.add_method("getCount", |_, this, ()| Ok(this.scheduler.count() as u32));
        // -- isEmpty --
        /// Returns true if the scheduler has no active events.
        /// @return | boolean | True when no events are scheduled.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.scheduler.is_empty()));
        // -- setInterval --
        /// Changes the interval duration in seconds for an existing repeating event. Returns true if the event was found and updated.
        /// @param | id | number | Event ID of the repeating event.
        /// @param | interval | number | New interval duration in seconds.
        /// @return | boolean | True if the event was found and its interval updated.
        methods.add_method_mut("setInterval", |_, this, (id, interval): (u32, f64)| {
            Ok(this.scheduler.set_interval(id, interval))
        });
        // -- resetEvent --
        /// Resets the elapsed time of a scheduled event back to zero, restarting its delay or interval countdown. Returns true if the event was found and reset.
        /// @param | id | number | Event ID to reset.
        /// @return | boolean | True if the event was found and reset.
        methods.add_method_mut("resetEvent", |_, this, id: u32| {
            Ok(this.scheduler.reset_event(id))
        });
        // -- setTimeScale --
        /// Sets the time scale multiplier for this scheduler. A value of 2.0 makes events fire twice as fast; 0.5 makes them fire at half speed. Does not affect frame-based events.
        /// @param | scale | number | Time scale multiplier (1.0 = normal speed).
        methods.add_method_mut("setTimeScale", |_, this, scale: f64| {
            this.scheduler.set_time_scale(scale);
            Ok(())
        });
        // -- getTimeScale --
        /// Returns the current time scale multiplier for this scheduler.
        /// @return | number | Current time scale (1.0 = normal speed).
        methods.add_method("getTimeScale", |_, this, ()| {
            Ok(this.scheduler.get_time_scale())
        });
        // -- update --
        /// Advances all time-based events by dt seconds, fires any callbacks whose delay has elapsed, and cleans up completed one-shot events. Call this once per frame with delta time. Returns the number of callbacks that fired.
        /// @param | dt | number | Delta time in seconds since the last update.
        /// @return | number | Count of callbacks that fired during this update.
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
        /// Advances all frame-based events by one frame, fires any callbacks whose frame count has been reached, and cleans up completed one-shot events. Call this once per frame. Returns the number of callbacks that fired.
        /// @return | number | Count of callbacks that fired during this frame update.
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
        /// Returns the type name of this object as a string.
        /// @return | string | Always "LScheduler".
        methods.add_method("type", |_, _, ()| Ok("LScheduler"));
        // -- typeOf --
        /// Checks whether this object matches the given type name. Accepts "LScheduler" or "Object".
        /// @param | name | string | Type name to check against.
        /// @return | boolean | True if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LScheduler" || name == "Object")
        });
    }
}
/// Registers the `lurek.timer` module, exposing delta time, FPS, frame counting, physics timestep, scheduler creation, coroutine-based waits, and real-time timer utilities.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- getDelta --
    /// Returns the time in seconds elapsed since the last frame. Use this to make movement and animations frame-rate independent.
    /// @return | number | Delta time in seconds.
    let s = state.clone();
    tbl.set(
        "getDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().delta_time))?,
    )?;
    // -- getFPS --
    /// Returns the current frames-per-second count. Useful for performance monitoring overlays and debug HUDs.
    /// @return | number | Current FPS.
    let s = state.clone();
    tbl.set(
        "getFPS",
        lua.create_function(move |_, ()| Ok(s.borrow().fps))?,
    )?;
    // -- getTime --
    /// Returns the total elapsed game time in seconds since the engine started. Useful for time-based animations, effects, and shader uniforms.
    /// @return | number | Total elapsed time in seconds.
    let s = state.clone();
    tbl.set(
        "getTime",
        lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
    )?;
    // -- getAverageDelta --
    /// Returns the smoothed average delta time in seconds over a recent window of frames. More stable than getDelta for display or adaptive logic.
    /// @return | number | Average delta time in seconds.
    let s = state.clone();
    tbl.set(
        "getAverageDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.average_delta()))?,
    )?;
    // -- getFrameCount --
    /// Returns the total number of frames rendered since the engine started.
    /// @return | number | Total frame count.
    let s = state.clone();
    tbl.set(
        "getFrameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.frame_count()))?,
    )?;
    // -- step --
    /// Advances the internal clock by one tick and returns the delta time for that tick. Typically called by the engine loop; game scripts rarely need this.
    /// @return | number | Delta time in seconds for the step.
    let s = state.clone();
    tbl.set(
        "step",
        lua.create_function(move |_, ()| Ok(s.borrow_mut().step_timer()))?,
    )?;
    // -- getMicroTime --
    /// Returns high-resolution elapsed time in seconds since engine start. Useful for precise benchmarking and profiling.
    /// @return | number | Elapsed time in seconds with sub-microsecond precision.
    let s = state.clone();
    tbl.set(
        "getMicroTime",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.elapsed()))?,
    )?;
    // -- getPhysicsDelta --
    /// Returns the fixed timestep used for physics simulation in seconds. The default is typically 1/60.
    /// @return | number | Fixed physics delta time in seconds.
    let s = state.clone();
    tbl.set(
        "getPhysicsDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().physics_run.fixed_dt))?,
    )?;
    // -- setPhysicsDelta --
    /// Sets the fixed timestep for physics simulation. Clamped between 1/240 and 1/10 seconds. Lower values increase accuracy but cost more CPU.
    /// @param | dt | number | Desired fixed delta time in seconds.
    let s = state.clone();
    tbl.set(
        "setPhysicsDelta",
        lua.create_function(move |_, dt: f64| {
            let clamped = dt.clamp(1.0 / 240.0, 1.0 / 10.0);
            s.borrow_mut().physics_run.fixed_dt = clamped;
            Ok(())
        })?,
    )?;
    // -- getPhysicsMaxSteps --
    /// Returns the maximum number of physics steps allowed per frame. Prevents the spiral of death when the game runs slowly.
    /// @return | number | Maximum physics steps per frame.
    let s = state.clone();
    tbl.set(
        "getPhysicsMaxSteps",
        lua.create_function(move |_, ()| Ok(s.borrow().physics_run.max_steps))?,
    )?;
    // -- setPhysicsMaxSteps --
    /// Sets the maximum number of physics steps allowed per frame. Clamped between 1 and 64. Higher values improve accuracy under lag but cost more CPU.
    /// @param | n | number | Maximum physics steps per frame.
    let s = state.clone();
    tbl.set(
        "setPhysicsMaxSteps",
        lua.create_function(move |_, n: u32| {
            s.borrow_mut().physics_run.max_steps = n.clamp(1, 64);
            Ok(())
        })?,
    )?;
    // -- sleep --
    /// Blocks the current thread for the given number of seconds. Use sparingly — this halts the entire game loop. Intended for loading screens or synchronization.
    /// @param | seconds | number | Duration to sleep in seconds.
    tbl.set(
        "sleep",
        lua.create_function(|_, seconds: f64| {
            crate::timer::sleep(seconds);
            Ok(())
        })?,
    )?;
    // -- newScheduler --
    /// Creates a new LScheduler instance for managing timed and frame-based callbacks independently from the global timer. Each scheduler has its own time scale and event list.
    /// @return | LScheduler | A new scheduler object.
    tbl.set(
        "newScheduler",
        lua.create_function(|lua, ()| lua.create_userdata(LuaScheduler::new()))?,
    )?;
    // -- chain --
    /// Creates a scheduler pre-loaded with a sequence of delayed callbacks. Each step is a table with an optional `delay` (seconds) and optional `func` (callback). Delays accumulate so each step fires after the sum of all preceding delays. Returns the scheduler for manual update calls.
    /// @param | steps | table | Array of step tables, each with optional fields `delay` (number) and `func` (function).
    /// @return | LScheduler | A new scheduler pre-loaded with the chained events.
    tbl.set(
        "chain",
        lua.create_function(|lua, steps: LuaTable| {
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
    let real_timers: Rc<RefCell<Vec<(std::time::Instant, LuaRegistryKey)>>> =
        Rc::new(RefCell::new(Vec::new()));
    // -- afterReal --
    /// Schedules a one-shot callback based on real (wall-clock) time, unaffected by game pausing or time scaling. Use for UI fade-outs, notifications, or anything that should run on real time.
    /// @param | delay | number | Real-time delay in seconds before the callback fires.
    /// @param | func | function | Callback to invoke when the real-time deadline is reached.
    let rt = real_timers.clone();
    tbl.set(
        "afterReal",
        lua.create_function(move |lua, (delay, func): (f64, LuaFunction)| {
            let deadline =
                std::time::Instant::now() + std::time::Duration::from_secs_f64(delay.max(0.0));
            let key = lua.create_registry_value(func)?;
            rt.borrow_mut().push((deadline, key));
            Ok(())
        })?,
    )?;
    // -- tickRealTimers --
    /// Checks all real-time timers and fires any whose deadline has passed. Returns the number of callbacks that fired. Call this once per frame after afterReal scheduling.
    /// @return | number | Count of real-time callbacks that fired.
    let rt = real_timers;
    tbl.set(
        "tickRealTimers",
        lua.create_function(move |lua, ()| {
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
    let smoothed: Rc<RefCell<f64>> = Rc::new(RefCell::new(0.0));
    let smooth_alpha: Rc<RefCell<f64>> = Rc::new(RefCell::new(0.1));
    // -- setSmoothingFactor --
    /// Sets the exponential smoothing factor used by getSmoothedDelta. Lower values produce smoother (more lagged) results; higher values track changes faster. Clamped to [0.01, 1.0].
    /// @param | alpha | number | Smoothing factor between 0.01 and 1.0.
    let sa = smooth_alpha.clone();
    tbl.set(
        "setSmoothingFactor",
        lua.create_function(move |_, alpha: f64| {
            *sa.borrow_mut() = alpha.clamp(0.01, 1.0);
            Ok(())
        })?,
    )?;
    // -- getSmoothedDelta --
    /// Returns an exponentially smoothed delta time in seconds, reducing frame-to-frame jitter. Call once per frame for consistent results. The smoothing factor is set via setSmoothingFactor.
    /// @return | number | Smoothed delta time in seconds.
    let s = state.clone();
    let smoothed_ref = smoothed.clone();
    let alpha_ref = smooth_alpha.clone();
    tbl.set(
        "getSmoothedDelta",
        lua.create_function(move |_, ()| {
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
    let wait_secs: Rc<RefCell<Vec<(LuaRegistryKey, std::time::Instant)>>> =
        Rc::new(RefCell::new(Vec::new()));
    let wait_frames: Rc<RefCell<Vec<(LuaRegistryKey, u64)>>> = Rc::new(RefCell::new(Vec::new()));
    // -- waitSeconds --
    /// Yields the current coroutine for the given number of real-time seconds. Must be called from within a coroutine. The coroutine is resumed automatically when tickWaits is called and the deadline has passed.
    /// @param | seconds | number | Real-time seconds to wait.
    let ws = wait_secs.clone();
    tbl.set(
        "waitSeconds",
        lua.create_function(move |lua, seconds: f64| {
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
    /// Yields the current coroutine for the given number of frames. Must be called from within a coroutine. The coroutine is resumed automatically when tickWaits is called and the target frame count has been reached.
    /// @param | frames | number | Number of frames to wait.
    let wf = wait_frames.clone();
    let s_wf = state.clone();
    tbl.set(
        "waitFrames",
        lua.create_function(move |lua, frames: u64| {
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
    /// Checks all pending waitSeconds and waitFrames coroutines, resumes any whose deadline or frame target has been reached, and cleans up completed entries. Returns the number of coroutines that were resumed. Call once per frame.
    /// @return | number | Count of coroutines resumed.
    let ws_tick = wait_secs;
    let wf_tick = wait_frames;
    let s_tick = state.clone();
    tbl.set(
        "tickWaits",
        lua.create_function(move |lua, ()| {
            let now = std::time::Instant::now();
            let current_frame = s_tick.borrow().clock.frame_count();
            let mut resumed = 0u32;
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
    // -- delay --
    /// Alias for waitSeconds. Yields the current coroutine for the given number of seconds.
    let wait_fn: LuaValue = tbl.get("waitSeconds")?;
    tbl.set("delay", wait_fn)?;
    lurek.set("timer", tbl)?;
    Ok(())
}
