//! `lurek.tween` - Provides value tweening with easing functions, sequences, parallel groups, and property animation for smooth game transitions.

use super::SharedState;
use crate::tween::{
    builtin_easing_names, LuaTween, LuaTweenParallel, LuaTweenSequence, ParallelEntry,
    SequenceStep, SpringSystem, TweenEngine, TweenState,
};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Lua-exposed standalone tween state for manual interpolation without automatic property updates.
pub struct LuaTweenState {
    inner: TweenState,
}
impl LuaUserData for LuaTweenState {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        // -- paused --
        /// Whether this tween state is paused. Set to `true` to freeze progress, `false` to resume.
        /// @param | paused | boolean | Pause flag.
        fields.add_field_method_get("paused", |_, this| Ok(this.inner.paused));
        fields.add_field_method_set("paused", |_, this, paused: bool| {
            this.inner.paused = paused;
            Ok(())
        });
    }
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- tick --
        /// Advances the tween state by the given delta time and returns the eased interpolation value (0..1).
        /// @param | dt | number | Delta time in seconds to advance.
        /// @return | number | Eased value between 0 and 1.
        methods.add_method_mut("tick", |_, this, dt: f64| Ok(this.inner.tick(dt)));

        // -- isComplete --
        /// Returns whether this tween state has finished its full duration.
        /// @return | boolean | `true` if the tween has reached its end.
        methods.add_method("isComplete", |_, this, ()| Ok(this.inner.is_complete()));

        // -- t --
        /// Returns the raw (un-eased) progress value from 0.0 to 1.0.
        /// @return | number | Linear progress ratio.
        methods.add_method("t", |_, this, ()| Ok(this.inner.t_raw() as f64));

        // -- lerp --
        /// Linearly interpolates between two values using the current eased progress.
        /// @param | start | number | Value at progress 0.
        /// @param | finish | number | Value at progress 1.
        /// @return | number | Interpolated value.
        methods.add_method("lerp", |_, this, (start, finish): (f64, f64)| {
            Ok(this.inner.lerp(start, finish))
        });

        // -- reset --
        /// Resets the tween state to the beginning so it can be replayed.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always `"LTweenState"`.
        methods.add_method("type", |_, _, ()| Ok("LTweenState"));

        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against (`"LTweenState"` or `"Object"`).
        /// @return | boolean | `true` if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenState" || name == "Object")
        });
    }
}
/// Lua-exposed spring physics simulation that smoothly animates table fields toward target values with configurable stiffness and damping.
pub struct LuaSpring {
    pub system: SpringSystem,
    pub target_table_key: Option<LuaRegistryKey>,
    pub on_settle_key: Option<LuaRegistryKey>,
    pub field_names: Vec<String>,
    pub active: bool,
}
impl LuaSpring {
    pub fn tick_with(&mut self, lua: &Lua, dt: f64) -> LuaResult<bool> {
        self.system.update(dt as f32);
        if let Some(ref tgt_key) = self.target_table_key {
            let tbl: LuaTable = lua.registry_value(tgt_key)?;
            for (name, axis) in &self.system.axes {
                tbl.set(name.as_str(), axis.position as f64)?;
            }
        }
        if self.system.is_settled() {
            if let Some(k) = self.on_settle_key.take() {
                let f: LuaFunction = lua.registry_value(&k)?;
                let _ = f.call::<_, ()>(());
                lua.remove_registry_value(k)?;
            }
            self.active = false;
            Ok(true)
        } else {
            Ok(false)
        }
    }
}
/// Registers the `lurek.tween` module, exposing tweening, sequencing, parallel groups, springs, and easing utilities to Lua.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let engine = Rc::new(RefCell::new(TweenEngine::new()));
    // -- update --
    /// Advances all active tweens, sequences, parallels, and springs by the given delta time. Call once per frame.
    /// @param | dt | number | Delta time in seconds since the last frame.
    let s = engine.clone();
    tbl.set(
        "update",
        lua.create_function(move |lua, dt: f64| {
            TweenEngine::update(&s, lua, dt)?;
            let spring_keys = std::mem::take(&mut s.borrow_mut().active_springs);
            let mut still_active = Vec::with_capacity(spring_keys.len());
            for key in spring_keys {
                let ud: LuaAnyUserData = lua.registry_value(&key)?;
                let done = {
                    let mut sp = ud.borrow_mut::<LuaSpring>()?;
                    if !sp.active {
                        true
                    } else {
                        sp.tick_with(lua, dt)?
                    }
                };
                if done {
                    lua.remove_registry_value(key)?;
                } else {
                    still_active.push(key);
                }
            }
            s.borrow_mut().active_springs = still_active;
            Ok(())
        })?,
    )?;
    // -- tween --
    /// Creates and starts a property tween that smoothly interpolates numeric fields on the target table over the given duration.
    /// @param | duration | number | Duration in seconds for the tween.
    /// @param | target | table | The table whose fields will be animated.
    /// @param | fields | table | Key-value pairs mapping field names to their target end values.
    /// @param | easing | ?string | Easing function name (default `"linear"`).
    /// @return | LTween | The active tween handle.
    let s = engine.clone();
    tbl.set(
        "tween",
        lua.create_function(
            move |lua,
                  (duration, target, fields_tbl, easing): (
                f64,
                LuaTable,
                LuaTable,
                Option<String>,
            )| {
                let easing_name = easing.as_deref().unwrap_or("linear");
                let mut fields = Vec::new();
                let mut end_values = Vec::new();
                for pair in fields_tbl.pairs::<String, f64>() {
                    let (k, v) = pair?;
                    fields.push(k);
                    end_values.push(v);
                }
                let tw = LuaTween::new(lua, duration, target, fields, end_values, easing_name)?;
                let ud = lua.create_userdata(tw)?;
                let key = lua.create_registry_value(ud.clone())?;
                s.borrow_mut().active_tweens.push(key);
                Ok(ud)
            },
        )?,
    )?;
    // -- sequence --
    /// Creates a new empty tween sequence. Chain `.tween()`, `.delay()`, and `.callback()` steps, then call `:start()`.
    /// @return | LTweenSequence | The new sequence handle.
    let s = engine.clone();
    tbl.set(
        "sequence",
        lua.create_function(move |lua, ()| {
            let seq = LuaTweenSequence::new();
            let ud = lua.create_userdata(seq)?;
            let key = lua.create_registry_value(ud.clone())?;
            s.borrow_mut().active_seqs.push(key);
            Ok(ud)
        })?,
    )?;
    // -- parallel --
    /// Creates a new empty parallel tween group. Add tweens with `:tween()` or `:add()`, then call `:start()` to run them simultaneously.
    /// @return | LTweenParallel | The new parallel group handle.
    let s = engine.clone();
    tbl.set(
        "parallel",
        lua.create_function(move |lua, ()| {
            let par = LuaTweenParallel::new();
            let ud = lua.create_userdata(par)?;
            let key = lua.create_registry_value(ud.clone())?;
            s.borrow_mut().active_pars.push(key);
            Ok(ud)
        })?,
    )?;
    // -- delay --
    /// Creates a one-shot delay. After the specified seconds elapse, the optional callback is invoked.
    /// @param | seconds | number | Duration to wait in seconds.
    /// @param | cb | ?function | Optional callback fired when the delay completes.
    /// @return | LTweenSequence | A sequence handle representing the delay.
    let s = engine.clone();
    tbl.set(
        "delay",
        lua.create_function(move |lua, (seconds, cb): (f64, Option<LuaFunction>)| {
            use crate::tween::SequenceStep;
            let callback = if let Some(f) = cb {
                Some(lua.create_registry_value(f)?)
            } else {
                None
            };
            let mut seq = LuaTweenSequence::new();
            seq.steps.push(SequenceStep::Delay {
                duration: seconds.max(0.0),
                elapsed: 0.0,
                callback,
            });
            seq.active = true;
            let ud = lua.create_userdata(seq)?;
            let key = lua.create_registry_value(ud.clone())?;
            s.borrow_mut().active_seqs.push(key);
            Ok(ud)
        })?,
    )?;
    // -- cancelAll --
    /// Immediately cancels all active tweens, sequences, parallels, and springs managed by the tween engine.
    let s = engine.clone();
    tbl.set(
        "cancelAll",
        lua.create_function(move |lua, ()| {
            TweenEngine::cancel_all(&s, lua)?;
            let spring_keys = std::mem::take(&mut s.borrow_mut().active_springs);
            for key in spring_keys {
                let ud: LuaAnyUserData = lua.registry_value(&key)?;
                {
                    let mut sp = ud.borrow_mut::<LuaSpring>()?;
                    sp.active = false;
                    if let Some(k) = sp.on_settle_key.take() {
                        lua.remove_registry_value(k)?;
                    }
                }
                lua.remove_registry_value(key)?;
            }
            Ok(())
        })?,
    )?;
    // -- getActiveCount --
    /// Returns the total number of currently active tweens, sequences, and parallels.
    /// @return | number | Count of active tween objects.
    let s = engine.clone();
    tbl.set(
        "getActiveCount",
        lua.create_function(move |_, ()| Ok(s.borrow().active_count()))?,
    )?;
    // -- registerEasing --
    /// Registers a custom easing function by name. The function receives a progress value (0..1) and must return an eased value.
    /// @param | name | string | Unique name for the custom easing.
    /// @param | f | function | Easing function `f(t) -> number` where t is 0..1.
    let s = engine.clone();
    tbl.set(
        "registerEasing",
        lua.create_function(move |lua, (name, f): (String, LuaFunction)| {
            let mut state = s.borrow_mut();
            if let Some(old) = state.custom_easings.remove(&name) {
                lua.remove_registry_value(old)?;
            }
            let key = lua.create_registry_value(f)?;
            state.custom_easings.insert(name, key);
            Ok(())
        })?,
    )?;
    // -- getEasingNames --
    /// Returns an array of all available easing function names, including both built-in and custom-registered easings.
    /// @return | table | Array of easing name strings.
    let s = engine.clone();
    tbl.set(
        "getEasingNames",
        lua.create_function(move |lua, ()| {
            let out = lua.create_table()?;
            let state = s.borrow();
            let mut i = 1i64;
            for name in builtin_easing_names() {
                out.set(i, *name)?;
                i += 1;
            }
            for name in state.custom_easings.keys() {
                out.set(i, name.as_str())?;
                i += 1;
            }
            Ok(out)
        })?,
    )?;
    // -- newState --
    /// Creates a standalone tween state for manual interpolation. Useful when you need eased progress without automatic property updates.
    /// @param | duration | number | Duration in seconds.
    /// @param | easing | ?string | Easing function name (default `"linear"`).
    /// @return | LTweenState | The new tween state handle.
    tbl.set(
        "newState",
        lua.create_function(|lua, (duration, easing): (f64, Option<String>)| {
            lua.create_userdata(LuaTweenState {
                inner: TweenState::new(duration, easing.as_deref().unwrap_or("linear")),
            })
        })?,
    )?;
    // -- to --
    /// Creates and starts a property tween with a different parameter order: target first, then fields, duration, easing.
    /// @param | target | table | The table whose fields will be animated.
    /// @param | fields | table | Key-value pairs mapping field names to their target end values.
    /// @param | duration | number | Duration in seconds.
    /// @param | easing | ?string | Easing function name (default `"linear"`).
    /// @return | LTween | The active tween handle.
    let s = engine.clone();
    tbl.set(
        "to",
        lua.create_function(
            move |lua,
                  (target, fields_tbl, duration, easing): (
                LuaTable,
                LuaTable,
                f64,
                Option<String>,
            )| {
                let easing_name = easing.as_deref().unwrap_or("linear");
                let mut fields = Vec::new();
                let mut end_values = Vec::new();
                for pair in fields_tbl.pairs::<String, f64>() {
                    let (k, v) = pair?;
                    fields.push(k);
                    end_values.push(v);
                }
                let tw = LuaTween::new(lua, duration, target, fields, end_values, easing_name)?;
                let ud = lua.create_userdata(tw)?;
                let key = lua.create_registry_value(ud.clone())?;
                s.borrow_mut().active_tweens.push(key);
                Ok(ud)
            },
        )?,
    )?;
    // -- tweenChain --
    /// Creates a sequence from a table of step descriptors. Each step is a table with `duration`, `target`, `fields`, optional `easing`, optional `callback`, or a `delay` key for pauses.
    /// @param | steps | table | Array of step tables describing the chain.
    /// @return | LTweenSequence | The active sequence handle.
    let s = engine.clone();
    tbl.set(
        "tweenChain",
        lua.create_function(move |lua, steps: LuaTable| {
            let mut seq = LuaTweenSequence::new();
            let len = steps.raw_len();
            for i in 1..=len {
                let step: LuaTable = steps.raw_get(i)?;
                if let Ok(delay) = step.get::<_, f64>("delay") {
                    let callback = step
                        .get::<_, LuaFunction>("callback")
                        .ok()
                        .map(|f| lua.create_registry_value(f))
                        .transpose()?;
                    seq.steps.push(SequenceStep::Delay {
                        duration: delay.max(0.0),
                        elapsed: 0.0,
                        callback,
                    });
                    continue;
                }
                let duration: f64 = step.get("duration")?;
                let target: LuaTable = step.get("target")?;
                let fields_tbl: LuaTable = step.get("fields")?;
                let easing_name = step
                    .get::<_, String>("easing")
                    .unwrap_or_else(|_| "linear".to_string());
                let target_key = lua.create_registry_value(target)?;
                let mut fields = Vec::new();
                let mut end_values = Vec::new();
                for pair in fields_tbl.pairs::<String, f64>() {
                    let (k, v) = pair?;
                    fields.push(k);
                    end_values.push(v);
                }
                let n = fields.len();
                seq.steps.push(SequenceStep::Tween {
                    state: TweenState::new(duration, &easing_name),
                    target_key,
                    fields,
                    end_values,
                    start_values: Vec::with_capacity(n),
                    starts_captured: false,
                });
                if let Ok(cb) = step.get::<_, LuaFunction>("callback") {
                    seq.steps
                        .push(SequenceStep::Callback(lua.create_registry_value(cb)?));
                }
            }
            seq.active = true;
            let ud = lua.create_userdata(seq)?;
            let key = lua.create_registry_value(ud.clone())?;
            s.borrow_mut().active_seqs.push(key);
            Ok(ud)
        })?,
    )?;
    // -- tweenColor --
    /// Creates and starts a color tween that smoothly interpolates r, g, b, and/or a fields on the target table.
    /// @param | duration | number | Duration in seconds.
    /// @param | target | table | The table containing color fields (`r`, `g`, `b`, `a`).
    /// @param | color | table | Target color values as `{r=, g=, b=, a=}`. Only present keys are tweened.
    /// @param | easing | ?string | Easing function name (default `"linear"`).
    /// @return | LTween | The active tween handle.
    let s = engine.clone();
    tbl.set(
        "tweenColor",
        lua.create_function(
            move |lua,
                  (duration, target, color_tbl, easing): (
                f64,
                LuaTable,
                LuaTable,
                Option<String>,
            )| {
                let easing_name = easing.as_deref().unwrap_or("linear");
                let mut fields = Vec::new();
                let mut end_values = Vec::new();
                for key in ["r", "g", "b", "a"] {
                    if let Ok(value) = color_tbl.get::<_, f64>(key) {
                        fields.push(key.to_string());
                        end_values.push(value);
                    }
                }
                let tw = LuaTween::new(lua, duration, target, fields, end_values, easing_name)?;
                let ud = lua.create_userdata(tw)?;
                let key = lua.create_registry_value(ud.clone())?;
                s.borrow_mut().active_tweens.push(key);
                Ok(ud)
            },
        )?,
    )?;
    // -- spring --
    /// Creates a spring-physics animation that smoothly drives table fields toward target values with bounce and settle behavior.
    /// @param | target | table | The table whose fields will be animated by the spring.
    /// @param | fields | table | Key-value pairs mapping field names to their spring target values.
    /// @param | opts | ?table | Optional settings: `stiffness` (default 100), `damping` (default 10), `precision` (default 0.001).
    /// @return | LSpring | The active spring handle.
    let s = engine.clone();
    tbl.set(
        "spring",
        lua.create_function(
            move |lua, (target_tbl, fields_tbl, opts): (LuaTable, LuaTable, Option<LuaTable>)| {
                let stiffness: f32 = opts
                    .as_ref()
                    .and_then(|o| o.get::<_, f32>("stiffness").ok())
                    .unwrap_or(100.0);
                let damping: f32 = opts
                    .as_ref()
                    .and_then(|o| o.get::<_, f32>("damping").ok())
                    .unwrap_or(10.0);
                let precision: f32 = opts
                    .as_ref()
                    .and_then(|o| o.get::<_, f32>("precision").ok())
                    .unwrap_or(0.001);
                let mut system = SpringSystem::new(stiffness, damping, precision);
                let mut field_names = Vec::new();
                for pair in fields_tbl.pairs::<String, f64>() {
                    let (name, target_val) = pair?;
                    let current: f64 = target_tbl.get(name.as_str()).unwrap_or(0.0);
                    system.add_axis(name.clone(), current as f32, target_val as f32);
                    field_names.push(name);
                }
                let target_table_key = lua.create_registry_value(target_tbl)?;
                let sp = LuaSpring {
                    system,
                    target_table_key: Some(target_table_key),
                    on_settle_key: None,
                    field_names,
                    active: true,
                };
                let ud = lua.create_userdata(sp)?;
                let key = lua.create_registry_value(ud.clone())?;
                s.borrow_mut().active_springs.push(key);
                Ok(ud)
            },
        )?,
    )?;
    lurek.set("tween", tbl)?;
    Ok(())
}
impl LuaUserData for LuaTween {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- cancel --
        /// Cancels this tween immediately, fires the onCancel callback if set, and resumes any coroutines waiting on it.
        methods.add_function("cancel", |lua, ud: LuaAnyUserData| {
            let mut tw = ud.borrow_mut::<LuaTween>()?;
            tw.active = false;
            if let Some(k) = tw.on_cancel.take() {
                if let Ok(f) = lua.registry_value::<LuaFunction>(&k) {
                    let _ = f.call::<_, ()>(());
                }
                lua.remove_registry_value(k)?;
            }
            tw.resume_waiters(lua)?;
            Ok(())
        });

        // -- pause --
        /// Pauses this tween so it stops advancing until resumed.
        methods.add_method_mut("pause", |_, this, ()| {
            this.paused = true;
            Ok(())
        });

        // -- resume --
        /// Resumes a paused tween so it continues advancing.
        methods.add_method_mut("resume", |_, this, ()| {
            this.paused = false;
            Ok(())
        });

        // -- isActive --
        /// Returns whether this tween is still running (not cancelled or completed).
        /// @return | boolean | `true` if the tween is active.
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // -- getProgress --
        /// Returns the eased progress of this tween as a value from 0.0 to 1.0.
        /// @return | number | Eased progress ratio.
        methods.add_method("getProgress", |_, this, ()| Ok(this.progress()));

        // -- getElapsed --
        /// Returns the number of seconds that have elapsed since the tween started.
        /// @return | number | Elapsed time in seconds.
        methods.add_method("getElapsed", |_, this, ()| Ok(this.elapsed()));

        // -- getDuration --
        /// Returns the total duration of this tween in seconds.
        /// @return | number | Total duration.
        methods.add_method("getDuration", |_, this, ()| Ok(this.state.duration));

        // -- getRemaining --
        /// Returns the number of seconds remaining until this tween completes.
        /// @return | number | Remaining time in seconds.
        methods.add_method("getRemaining", |_, this, ()| Ok(this.remaining()));
        // -- getFields --
        /// Returns an array of field names being tweened on the target table.
        /// @return | table | Array of field name strings.
        methods.add_method("getFields", |lua, this, ()| {
            let out = lua.create_table()?;
            for (idx, field) in this.fields.iter().enumerate() {
                out.set((idx + 1) as i64, field.as_str())?;
            }
            Ok(out)
        });
        // -- setRelative --
        /// Sets whether the tween end values are relative to the start values instead of absolute.
        /// @param | enabled | boolean | `true` for relative mode, `false` for absolute.
        methods.add_method_mut("setRelative", |_, this, enabled: bool| {
            this.set_relative(enabled);
            Ok(())
        });
        // -- relative --
        /// Chainable version of `setRelative`. Returns the tween for fluent API usage.
        /// @param | enabled | boolean | `true` for relative mode.
        /// @return | LTween | The same tween handle for chaining.
        methods.add_function("relative", |_, (ud, enabled): (LuaAnyUserData, bool)| {
            ud.borrow_mut::<LuaTween>()?.set_relative(enabled);
            Ok(ud)
        });

        // -- await --
        /// Yields the current coroutine until this tween completes or is cancelled. Must be called from inside a coroutine.
        methods.add_function("await", |lua, ud: LuaAnyUserData| {
            let co_tbl: LuaTable = lua.globals().get("coroutine")?;
            let running_fn: LuaFunction = co_tbl.get("running")?;
            let thread_val: LuaValue = running_fn.call(())?;
            if matches!(thread_val, LuaValue::Nil) {
                return Err(LuaError::RuntimeError(
                    "LTween:await must be called from within a coroutine".to_string(),
                ));
            }
            {
                let mut tw = ud.borrow_mut::<LuaTween>()?;
                if !tw.active {
                    return Ok(());
                }
                tw.add_waiter(lua.create_registry_value(thread_val)?);
            }
            let yield_fn: LuaFunction = co_tbl.get("yield")?;
            yield_fn.call::<_, ()>(())?;
            Ok(())
        });
        // -- setRepeat --
        /// Sets how many times the tween should repeat after the first play. Use -1 for infinite repeat.
        /// @param | n | number | Number of additional repeats (0 = play once, -1 = infinite).
        methods.add_method_mut("setRepeat", |_, this, n: i32| {
            this.repeat_count = n;
            this.cycles_remaining = n;
            Ok(())
        });
        // -- setYoyo --
        /// Enables or disables yoyo mode, which reverses the tween direction on each repeat cycle.
        /// @param | enabled | boolean | `true` to enable yoyo, `false` to disable.
        methods.add_method_mut("setYoyo", |_, this, enabled: bool| {
            this.yoyo = enabled;
            Ok(())
        });
        methods.add_function(
            "onComplete",
            |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
                {
                    let mut tw = ud.borrow_mut::<LuaTween>()?;
                    if let Some(old) = tw.on_complete.take() {
                        lua.remove_registry_value(old)?;
                    }
                    tw.on_complete = Some(lua.create_registry_value(f)?);
                }
                Ok(ud)
            },
        );

        // -- onUpdate --
        /// Sets a callback to fire every frame while the tween is active. Returns the tween for chaining.
        /// @param | f | function | Callback invoked each frame.
        /// @return | LTween | The same tween handle for chaining.
        methods.add_function("onUpdate", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
            {
                let mut tw = ud.borrow_mut::<LuaTween>()?;
                if let Some(old) = tw.on_update.take() {
                    lua.remove_registry_value(old)?;
                }
                tw.on_update = Some(lua.create_registry_value(f)?);
            }
            Ok(ud)
        });

        // -- onCancel --
        /// Sets a callback to fire when the tween is cancelled. Returns the tween for chaining.
        /// @param | f | function | Callback invoked on cancellation.
        /// @return | LTween | The same tween handle for chaining.
        methods.add_function("onCancel", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
            {
                let mut tw = ud.borrow_mut::<LuaTween>()?;
                if let Some(old) = tw.on_cancel.take() {
                    lua.remove_registry_value(old)?;
                }
                tw.on_cancel = Some(lua.create_registry_value(f)?);
            }
            Ok(ud)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always `"LTween"`.
        methods.add_method("type", |_, _, ()| Ok("LTween"));

        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against (`"LTween"` or `"Object"`).
        /// @return | boolean | `true` if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTween" || name == "Object")
        });
    }
}
impl LuaUserData for LuaTweenSequence {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- tween --
        /// Appends a tween step to this sequence that animates numeric fields on the target table.
        /// @param | duration | number | Duration in seconds.
        /// @param | target | table | The table whose fields will be animated.
        /// @param | fields | table | Key-value pairs mapping field names to target end values.
        /// @param | easing | ?string | Easing function name (default `"linear"`).
        /// @return | LTweenSequence | This sequence for chaining.
        methods.add_function(
            "tween",
            |lua,
             (ud, duration, target, fields_tbl, easing): (
                LuaAnyUserData,
                f64,
                LuaTable,
                LuaTable,
                Option<String>,
            )| {
                let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
                let easing_name = easing.as_deref().unwrap_or("linear");
                let target_key = lua.create_registry_value(target)?;
                let mut fields = Vec::new();
                let mut end_values = Vec::new();
                for pair in fields_tbl.pairs::<String, f64>() {
                    let (k, v) = pair?;
                    fields.push(k);
                    end_values.push(v);
                }
                let n = fields.len();
                seq.steps.push(SequenceStep::Tween {
                    state: TweenState::new(duration, easing_name),
                    target_key,
                    fields,
                    end_values,
                    start_values: Vec::with_capacity(n),
                    starts_captured: false,
                });
                drop(seq);
                Ok(ud)
            },
        );

        // -- delay --
        /// Appends a delay step to this sequence. Optionally fires a callback when the delay elapses.
        /// @param | seconds | number | Duration to wait in seconds.
        /// @param | cb | ?function | Optional callback fired after the delay.
        /// @return | LTweenSequence | This sequence for chaining.
        methods.add_function(
            "delay",
            |lua, (ud, seconds, cb): (LuaAnyUserData, f64, Option<LuaFunction>)| {
                let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
                let callback = if let Some(f) = cb {
                    Some(lua.create_registry_value(f)?)
                } else {
                    None
                };
                seq.steps.push(SequenceStep::Delay {
                    duration: seconds.max(0.0),
                    elapsed: 0.0,
                    callback,
                });
                drop(seq);
                Ok(ud)
            },
        );

        // -- callback --
        /// Appends a callback step to this sequence that fires when reached during playback.
        /// @param | f | function | Callback to invoke.
        /// @return | LTweenSequence | This sequence for chaining.
        methods.add_function("callback", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
            let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
            let key = lua.create_registry_value(f)?;
            seq.steps.push(SequenceStep::Callback(key));
            drop(seq);
            Ok(ud)
        });

        // -- start --
        /// Starts playback of this sequence from the first step.
        /// @return | LTweenSequence | This sequence for chaining.
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenSequence>()?.active = true;
            Ok(ud)
        });

        // -- cancel --
        /// Cancels this sequence immediately and resumes any coroutines waiting on it.
        methods.add_method_mut("cancel", |lua, this, ()| {
            this.active = false;
            this.resume_waiters(lua)?;
            Ok(())
        });

        // -- isActive --
        /// Returns whether this sequence is still running.
        /// @return | boolean | `true` if the sequence is active.
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // -- getProgress --
        /// Returns the overall progress ratio of this sequence from 0.0 to 1.0.
        /// @return | number | Progress ratio.
        methods.add_method("getProgress", |_, this, ()| Ok(this.progress_ratio()));

        // -- await --
        /// Yields the current coroutine until this sequence completes or is cancelled. Must be called from inside a coroutine.
        methods.add_function("await", |lua, ud: LuaAnyUserData| {
            let co_tbl: LuaTable = lua.globals().get("coroutine")?;
            let running_fn: LuaFunction = co_tbl.get("running")?;
            let thread_val: LuaValue = running_fn.call(())?;
            if matches!(thread_val, LuaValue::Nil) {
                return Err(LuaError::RuntimeError(
                    "LTweenSequence:await must be called from within a coroutine".to_string(),
                ));
            }
            {
                let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
                if !seq.active {
                    return Ok(());
                }
                seq.add_waiter(lua.create_registry_value(thread_val)?);
            }
            let yield_fn: LuaFunction = co_tbl.get("yield")?;
            yield_fn.call::<_, ()>(())?;
            Ok(())
        });

        // -- onComplete --
        /// Sets a callback to fire when the sequence finishes all steps. Returns the sequence for chaining.
        /// @param | f | function | Callback invoked on completion.
        /// @return | LTweenSequence | This sequence for chaining.
        methods.add_function(
            "onComplete",
            |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
                {
                    let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
                    if let Some(old) = seq.on_complete.take() {
                        lua.remove_registry_value(old)?;
                    }
                    seq.on_complete = Some(lua.create_registry_value(f)?);
                }
                Ok(ud)
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always `"LTweenSequence"`.
        methods.add_method("type", |_, _, ()| Ok("LTweenSequence"));

        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against (`"LTweenSequence"` or `"Object"`).
        /// @return | boolean | `true` if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenSequence" || name == "Object")
        });
    }
}
impl LuaUserData for LuaTweenParallel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Adds an existing tween handle to this parallel group. The tween becomes owned by the group.
        /// @param | tween | LTween | An active tween to run in parallel.
        methods.add_function(
            "add",
            |lua, (par_ud, tw_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let entry = {
                    let mut tw = tw_ud.borrow_mut::<LuaTween>()?;
                    tw.owned_by_parent = true;
                    let target_key =
                        lua.create_registry_value(lua.registry_value::<LuaTable>(&tw.target_key)?)?;
                    let n = tw.fields.len();
                    ParallelEntry {
                        state: TweenState::new(tw.state.duration, "linear"),
                        target_key,
                        fields: tw.fields.clone(),
                        end_values: tw.end_values.clone(),
                        start_values: Vec::with_capacity(n),
                        starts_captured: false,
                        done: false,
                    }
                };
                par_ud.borrow_mut::<LuaTweenParallel>()?.entries.push(entry);
                Ok(())
            },
        );

        // -- tween --
        /// Creates and adds a new tween step directly to this parallel group.
        /// @param | duration | number | Duration in seconds.
        /// @param | target | table | The table whose fields will be animated.
        /// @param | fields | table | Key-value pairs mapping field names to target end values.
        /// @param | easing | ?string | Easing function name (default `"linear"`).
        /// @return | LTweenParallel | This parallel group for chaining.
        methods.add_function(
            "tween",
            |lua,
             (ud, duration, target, fields_tbl, easing): (
                LuaAnyUserData,
                f64,
                LuaTable,
                LuaTable,
                Option<String>,
            )| {
                let mut par = ud.borrow_mut::<LuaTweenParallel>()?;
                let easing_name = easing.as_deref().unwrap_or("linear");
                let target_key = lua.create_registry_value(target)?;
                let mut fields = Vec::new();
                let mut end_values = Vec::new();
                for pair in fields_tbl.pairs::<String, f64>() {
                    let (k, v) = pair?;
                    fields.push(k);
                    end_values.push(v);
                }
                let n = fields.len();
                par.entries.push(ParallelEntry {
                    state: TweenState::new(duration, easing_name),
                    target_key,
                    fields,
                    end_values,
                    start_values: Vec::with_capacity(n),
                    starts_captured: false,
                    done: false,
                });
                drop(par);
                Ok(ud)
            },
        );

        // -- start --
        /// Starts all tweens in this parallel group simultaneously.
        /// @return | LTweenParallel | This parallel group for chaining.
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenParallel>()?.active = true;
            Ok(ud)
        });

        // -- cancel --
        /// Cancels all tweens in this parallel group immediately.
        methods.add_method_mut("cancel", |_, this, ()| {
            this.active = false;
            Ok(())
        });

        // -- isActive --
        /// Returns whether this parallel group is still running.
        /// @return | boolean | `true` if any tween in the group is still active.
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // -- onComplete --
        /// Sets a callback to fire when all tweens in this parallel group have finished. Returns the group for chaining.
        /// @param | f | function | Callback invoked on completion.
        /// @return | LTweenParallel | This parallel group for chaining.
        methods.add_function(
            "onComplete",
            |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
                {
                    let mut par = ud.borrow_mut::<LuaTweenParallel>()?;
                    if let Some(old) = par.on_complete.take() {
                        lua.remove_registry_value(old)?;
                    }
                    par.on_complete = Some(lua.create_registry_value(f)?);
                }
                Ok(ud)
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always `"LTweenParallel"`.
        methods.add_method("type", |_, _, ()| Ok("LTweenParallel"));

        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against (`"LTweenParallel"` or `"Object"`).
        /// @return | boolean | `true` if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenParallel" || name == "Object")
        });
    }
}
impl LuaUserData for LuaSpring {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Manually advances this spring by the given delta time and writes updated positions to the target table. Returns `true` if still animating, `false` if settled.
        /// @param | dt | number | Delta time in seconds.
        /// @return | boolean | `true` if the spring is still moving, `false` if settled.
        methods.add_method_mut("update", |lua, this, dt: f64| {
            if !this.active {
                return Ok(false);
            }
            this.tick_with(lua, dt).map(|done| !done)
        });

        // -- isSettled --
        /// Returns whether all spring axes have reached their targets within the precision threshold.
        /// @return | boolean | `true` if the spring has settled.
        methods.add_method("isSettled", |_, this, ()| Ok(this.system.is_settled()));

        // -- isActive --
        /// Returns whether this spring is still actively animating.
        /// @return | boolean | `true` if active.
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // -- setTarget --
        /// Changes the spring target values for one or more axes. Re-activates the spring if it was settled.
        /// @param | fields | table | Key-value pairs mapping axis names to new target values.
        methods.add_method_mut("setTarget", |_, this, fields_tbl: LuaTable| {
            for pair in fields_tbl.pairs::<String, f64>() {
                let (k, v) = pair?;
                this.system.set_target(&k, v as f32);
            }
            if !this.system.is_settled() {
                this.active = true;
            }
            Ok(())
        });

        // -- setStiffness --
        /// Sets the spring stiffness for all axes. Higher values make the spring snap faster.
        /// @param | value | number | Stiffness coefficient (default 100).
        methods.add_method_mut("setStiffness", |_, this, value: f32| {
            this.system.stiffness = value;
            for axis in this.system.axes.values_mut() {
                axis.stiffness = value;
            }
            Ok(())
        });

        // -- setDamping --
        /// Sets the spring damping for all axes. Higher values reduce oscillation and overshoot.
        /// @param | value | number | Damping coefficient (default 10).
        methods.add_method_mut("setDamping", |_, this, value: f32| {
            this.system.damping = value;
            for axis in this.system.axes.values_mut() {
                axis.damping = value;
            }
            Ok(())
        });

        // -- cancel --
        /// Cancels this spring animation and cleans up the on-settle callback if one was registered.
        methods.add_method_mut("cancel", |lua, this, ()| {
            this.active = false;
            if let Some(k) = this.on_settle_key.take() {
                lua.remove_registry_value(k)?;
            }
            Ok(())
        });

        // -- getPosition --
        /// Returns the current position of the given spring axis, or `nil` if the axis does not exist.
        /// @param | field | string | Name of the axis to query.
        /// @return | ?number | Current position value, or `nil`.
        methods.add_method("getPosition", |_, this, field: String| {
            Ok(this.system.get_position(&field).map(|p| p as f64))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always `"LSpring"`.
        methods.add_method("type", |_, _, ()| Ok("LSpring"));

        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check against (`"LSpring"` or `"Object"`).
        /// @return | boolean | `true` if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpring" || name == "Object")
        });
    }
}
