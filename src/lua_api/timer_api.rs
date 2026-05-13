use super::SharedState;
use crate::timer::Scheduler;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;
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
        methods.add_method_mut("after", |lua, this, (delay, func): (f64, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let id = this.scheduler.after(delay);
            this.callbacks.insert(id, key);
            Ok(id)
        });
        methods.add_method_mut("afterFrames", |lua, this, (n, func): (u64, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let id = this.scheduler.after_frames(n);
            this.callbacks.insert(id, key);
            Ok(id)
        });
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
        methods.add_method_mut(
            "every",
            |lua, this, (interval, func, count): (f64, LuaFunction, Option<i32>)| {
                let key = lua.create_registry_value(func)?;
                let id = this.scheduler.every(interval, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                Ok(id)
            },
        );
        methods.add_method_mut(
            "everyFrames",
            |lua, this, (n, func, count): (u64, LuaFunction, Option<i32>)| {
                let key = lua.create_registry_value(func)?;
                let id = this.scheduler.every_frames(n, count.unwrap_or(-1));
                this.callbacks.insert(id, key);
                Ok(id)
            },
        );
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
        methods.add_method_mut("cancel", |lua, this, id: u32| {
            let removed = this.scheduler.cancel(id);
            if removed {
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                this.named_ids.retain(|_, v| *v != id);
            }
            Ok(removed)
        });
        methods.add_method_mut("cancelNamed", |lua, this, name: String| {
            if let Some(id) = this.named_ids.remove(&name) {
                this.scheduler.cancel(id);
                Self::remove_callback(lua, &mut this.callbacks, id)?;
                Ok(true)
            } else {
                Ok(false)
            }
        });
        methods.add_method_mut("cancelAll", |lua, this, ()| {
            let n = this.scheduler.cancel_all();
            for (_, key) in this.callbacks.drain() {
                lua.remove_registry_value(key)?;
            }
            this.named_ids.clear();
            Ok(n)
        });
        methods.add_method_mut("pause", |_, this, id: u32| Ok(this.scheduler.pause(id)));
        methods.add_method_mut("resume", |_, this, id: u32| Ok(this.scheduler.resume(id)));
        methods.add_method("isPaused", |_, this, id: u32| {
            Ok(this.scheduler.is_paused(id))
        });
        methods.add_method_mut("pauseNamed", |_, this, name: String| {
            Ok(this.scheduler.pause_named(&name))
        });
        methods.add_method_mut("resumeNamed", |_, this, name: String| {
            Ok(this.scheduler.resume_named(&name))
        });
        methods.add_method("isPausedNamed", |_, this, name: String| {
            Ok(this.scheduler.is_paused_named(&name))
        });
        methods.add_method("getRemaining", |_, this, id: u32| {
            match this.scheduler.get_remaining(id) {
                Some(value) => Ok((true, value)),
                None => Ok((false, 0.0)),
            }
        });
        methods.add_method("getInterval", |_, this, id: u32| {
            match this.scheduler.get_interval(id) {
                Some(value) => Ok((true, value)),
                None => Ok((false, 0.0)),
            }
        });
        methods.add_method("getRepeatCount", |_, this, id: u32| {
            match this.scheduler.get_repeat_count(id) {
                Some(value) => Ok((true, value)),
                None => Ok((false, 0)),
            }
        });
        methods.add_method("getCount", |_, this, ()| Ok(this.scheduler.count() as u32));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.scheduler.is_empty()));
        methods.add_method_mut("setInterval", |_, this, (id, interval): (u32, f64)| {
            Ok(this.scheduler.set_interval(id, interval))
        });
        methods.add_method_mut("resetEvent", |_, this, id: u32| {
            Ok(this.scheduler.reset_event(id))
        });
        methods.add_method_mut("setTimeScale", |_, this, scale: f64| {
            this.scheduler.set_time_scale(scale);
            Ok(())
        });
        methods.add_method("getTimeScale", |_, this, ()| {
            Ok(this.scheduler.get_time_scale())
        });
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
        methods.add_method("type", |_, _, ()| Ok("LScheduler"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LScheduler" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    tbl.set(
        "getDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().delta_time))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getFPS",
        lua.create_function(move |_, ()| Ok(s.borrow().fps))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getTime",
        lua.create_function(move |_, ()| Ok(s.borrow().total_time))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getAverageDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.average_delta()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getFrameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.frame_count()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "step",
        lua.create_function(move |_, ()| Ok(s.borrow_mut().step_timer()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getMicroTime",
        lua.create_function(move |_, ()| Ok(s.borrow().clock.elapsed()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getPhysicsDelta",
        lua.create_function(move |_, ()| Ok(s.borrow().physics_run.fixed_dt))?,
    )?;
    let s = state.clone();
    tbl.set(
        "setPhysicsDelta",
        lua.create_function(move |_, dt: f64| {
            let clamped = dt.clamp(1.0 / 240.0, 1.0 / 10.0);
            s.borrow_mut().physics_run.fixed_dt = clamped;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getPhysicsMaxSteps",
        lua.create_function(move |_, ()| Ok(s.borrow().physics_run.max_steps))?,
    )?;
    let s = state.clone();
    tbl.set(
        "setPhysicsMaxSteps",
        lua.create_function(move |_, n: u32| {
            s.borrow_mut().physics_run.max_steps = n.clamp(1, 64);
            Ok(())
        })?,
    )?;
    tbl.set(
        "sleep",
        lua.create_function(|_, seconds: f64| {
            crate::timer::sleep(seconds);
            Ok(())
        })?,
    )?;
    tbl.set(
        "newScheduler",
        lua.create_function(|lua, ()| lua.create_userdata(LuaScheduler::new()))?,
    )?;
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
    let sa = smooth_alpha.clone();
    tbl.set(
        "setSmoothingFactor",
        lua.create_function(move |_, alpha: f64| {
            *sa.borrow_mut() = alpha.clamp(0.01, 1.0);
            Ok(())
        })?,
    )?;
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
    let wait_fn: LuaValue = tbl.get("waitSeconds")?;
    tbl.set("delay", wait_fn)?;
    lurek.set("timer", tbl)?;
    Ok(())
}
