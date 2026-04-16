//! `lurek.time` - Frame timing, FPS tracking, and scheduled Lua callbacks.

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

        // -- pauseNamed --
        /// Pauses a scheduled event by its string name.
        /// @param name : string
        /// @return boolean
        methods.add_method_mut("pauseNamed", |_, this, name: String| {
            Ok(this.scheduler.pause_named(&name))
        });

        // -- resumeNamed --
        /// Resumes a paused event by its string name.
        /// @param name : string
        /// @return boolean
        methods.add_method_mut("resumeNamed", |_, this, name: String| {
            Ok(this.scheduler.resume_named(&name))
        });

        // -- isPausedNamed --
        /// Returns whether the named event is currently paused.
        /// @param name : string
        /// @return boolean
        methods.add_method("isPausedNamed", |_, this, name: String| {
            Ok(this.scheduler.is_paused_named(&name))
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
///
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
///
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

    // -- getFrameCount --
    /// Returns the total number of frames rendered since engine start.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getFrameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.frame_count()))?,
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

    // -- getPhysicsMaxSteps --
    /// Returns the maximum number of physics sub-steps allowed per frame.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getPhysicsMaxSteps",
        lua.create_function(move |_, ()| Ok(s.borrow().physics_max_steps))?,
    )?;

    // -- setPhysicsMaxSteps --
    /// Sets the maximum number of physics sub-steps allowed per frame (clamped 1–64).
    /// @param n : integer
    let s = state.clone();
    tbl.set(
        "setPhysicsMaxSteps",
        lua.create_function(move |_, n: u32| {
            s.borrow_mut().physics_max_steps = n.clamp(1, 64);
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

    // -- chain --
    /// Creates a new Scheduler loaded with a sequenced one-shot chain.
    /// Each step fires after the previous step's delay has elapsed (additive).
    /// Returns the scheduler so the caller can drive it with `:update(dt)`.
    /// @param steps : table   array of `{delay: number, func: function}` entries
    /// @return Scheduler
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

    // Real-clock timer list: (deadline_instant, callback_key).
    let real_timers: Rc<RefCell<Vec<(std::time::Instant, LuaRegistryKey)>>> =
        Rc::new(RefCell::new(Vec::new()));

    // -- afterReal --
    /// Schedules a one-shot callback that fires after `delay` wall-clock seconds,
    /// unaffected by engine time scale. Call `lurek.time.tickRealTimers()` once
    /// per frame to poll for expired timers.
    /// @param delay : number   wall-clock seconds to wait
    /// @param func : function
    /// @return nil
    let rt = real_timers.clone();
    tbl.set(
        "afterReal",
        lua.create_function(move |lua, (delay, func): (f64, LuaFunction)| {
            let deadline = std::time::Instant::now()
                + std::time::Duration::from_secs_f64(delay.max(0.0));
            let key = lua.create_registry_value(func)?;
            rt.borrow_mut().push((deadline, key));
            Ok(())
        })?,
    )?;

    // -- tickRealTimers --
    /// Fires and removes all real-clock timers whose wall-clock deadline has passed.
    /// Call once per frame inside `lurek.process` to drain expired timers.
    /// integer  number of callbacks fired
    let rt = real_timers;
    /// Advances all real-time timers by one tick; called automatically each frame.
    ///
    /// @return table|nil
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

    // Smoothed-delta state — exponential moving average of frame deltas.
    let smoothed: Rc<RefCell<f64>> = Rc::new(RefCell::new(0.0));
    let smooth_alpha: Rc<RefCell<f64>> = Rc::new(RefCell::new(0.1));

    // -- setSmoothingFactor --
    /// Sets the smoothing factor (alpha) for `getSmoothedDelta`. Must be in [0.01, 1.0].
    /// Lower values smooth more aggressively; 1.0 disables smoothing.
    /// @param alpha : number
    /// @return nil
    let sa = smooth_alpha.clone();
    tbl.set(
        "setSmoothingFactor",
        lua.create_function(move |_, alpha: f64| {
            *sa.borrow_mut() = alpha.clamp(0.01, 1.0);
            Ok(())
        })?,
    )?;

    // -- getSmoothedDelta --
    /// Returns the exponential moving-average of frame deltas in seconds.
    /// Call once per frame to update the average; the first call seeds from the
    /// current raw delta.
    /// @return number
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

    // Coroutine wait lists.
    // Each entry: (LuaRegistryKey holding the LuaThread, deadline Instant)
    let wait_secs: Rc<RefCell<Vec<(LuaRegistryKey, std::time::Instant)>>> =
        Rc::new(RefCell::new(Vec::new()));

    // Coroutine frame-wait list.
    // Each entry: (LuaRegistryKey holding the LuaThread, target frame_count)
    let wait_frames: Rc<RefCell<Vec<(LuaRegistryKey, u64)>>> =
        Rc::new(RefCell::new(Vec::new()));

    // -- waitSeconds --
    /// Yields the current Lua coroutine for at least `seconds` wall-clock seconds.
    /// Must be called from within a `coroutine.wrap`'d or `coroutine.create`'d
    /// function. Call `lurek.time.tickWaits()` once per frame in `lurek.process`
    /// to resume expired waits.
    ///
    /// @param seconds : number
    /// @return nil
    let ws = wait_secs.clone();
    tbl.set(
        "waitSeconds",
        lua.create_function(move |lua, seconds: f64| {
            let deadline = std::time::Instant::now()
                + std::time::Duration::from_secs_f64(seconds.max(0.0));
            let co_tbl: LuaTable = lua.globals().get("coroutine")?;
            let running_fn: LuaFunction = co_tbl.get("running")?;
            let thread_val: LuaValue = running_fn.call(())?;
            if matches!(thread_val, LuaValue::Nil) {
                return Err(LuaError::RuntimeError(
                    "lurek.time.waitSeconds: must be called from within a coroutine".into(),
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
    /// Yields the current Lua coroutine for at least `frames` engine frames.
    /// Must be called from within a coroutine. Call `lurek.time.tickWaits()` once
    /// per frame to resume expired waits.
    ///
    /// @param frames : integer
    /// @return nil
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
                    "lurek.time.waitFrames: must be called from within a coroutine".into(),
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
    /// Resumes all coroutines waiting via `waitSeconds` or `waitFrames` whose
    /// deadline or frame target has been reached. Call once per frame inside
    /// `lurek.process` alongside `lurek.time.tickRealTimers()`.
    ///
    /// integer  number of coroutines resumed
    let ws_tick = wait_secs;
    let wf_tick = wait_frames;
    let s_tick = state.clone();
    /// Advances all `lurek.timer.wait()` coroutines by one tick; called each frame.
    ///
    /// @return table|nil
    tbl.set(
        "tickWaits",
        lua.create_function(move |lua, ()| {
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

    luna.set("time", tbl)?;
    Ok(())
}
