//! `lurek.tween` - Property tweening, sequencing, and spring animation helpers.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::tween::{
    builtin_easing_names, LuaTween, LuaTweenParallel, LuaTweenSequence, ParallelEntry,
    SequenceStep, SpringSystem, TweenEngine, TweenState,
};

/// Lua-side wrapper around the pure-Rust [`TweenState`] timing core.
pub struct LuaTweenState {
    inner: TweenState,
}

impl LuaUserData for LuaTweenState {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        fields.add_field_method_get("paused", |_, this| Ok(this.inner.paused));
        fields.add_field_method_set("paused", |_, this, paused: bool| {
            this.inner.paused = paused;
            Ok(())
        });
    }

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- tick --
        /// Advances the tween state by `dt` seconds.
        /// @param | dt | number | Delta time in seconds.
        /// @return | boolean | True when the tween state reached completion.
        methods.add_method_mut("tick", |_, this, dt: f64| Ok(this.inner.tick(dt)));

        // -- isComplete --
        /// Returns whether the tween state has completed.
        /// @return | boolean | True when playback is complete.
        methods.add_method("isComplete", |_, this, ()| Ok(this.inner.is_complete()));

        // -- t --
        /// Returns the raw 0..1 playback progress.
        /// @return | number | Raw playback progress in the range 0 to 1.
        methods.add_method("t", |_, this, ()| Ok(this.inner.t_raw() as f64));

        // -- lerp --
        /// Interpolates from `start` to `finish` using the eased tween progress.
        /// @param | start | number | Range start value.
        /// @param | finish | number | Range end value.
        /// @return | number | Interpolated value at the current eased progress.
        methods.add_method("lerp", |_, this, (start, finish): (f64, f64)| {
            Ok(this.inner.lerp(start, finish))
        });

        // -- reset --
        /// Resets the tween state to elapsed time zero.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | The literal type name.
        methods.add_method("type", |_, _, ()| Ok("LTweenState"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the object matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenState" || name == "Object")
        });
    }
}

/// Lua-side spring handle: wraps [`SpringSystem`] and a registry reference to the target table.
///
/// Created via `lurek.tween.spring(target_table, fields_table, opts?)`. The handle drives
/// per-axis spring simulation and writes updated positions back to the Lua target table
/// on every update call.
///
/// # Fields
/// - `system` - `SpringSystem`. The multi-axis damped spring simulation.
/// - `target_table_key` - `Option<LuaRegistryKey>`. Registry key for the animated Lua table.
/// - `on_settle_key` - `Option<LuaRegistryKey>`. Optional callback fired when all axes settle.
/// - `field_names` - `Vec<String>`. Ordered list of field names being animated.
/// - `active` - `bool`. `false` once settled or cancelled.
pub struct LuaSpring {
    /// The multi-axis spring simulation.
    pub system: SpringSystem,
    /// Registry key for the Lua table being animated.
    pub target_table_key: Option<LuaRegistryKey>,
    /// Optional callback fired when all axes settle.
    pub on_settle_key: Option<LuaRegistryKey>,
    /// Field names animated by this spring.
    pub field_names: Vec<String>,
    /// Whether the spring is still active.
    pub active: bool,
}

impl LuaSpring {
    /// Advances the spring by `dt` seconds and returns whether it settled.
    /// @param | lua | Lua | Active Lua state used for registry access.
    /// @param | dt | number | Delta time in seconds.
    /// @return | boolean | True when all spring axes settled.
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

/// Registers the `lurek.tween` property tweening API.
/// Registers the `lurek.tween` module and its userdata types.
/// @param | lua | Lua | Active Lua state used to create the module table.
/// @param | lurek | table | Root `lurek` table that receives the module.
/// @param | _state | SharedState | Shared engine state placeholder for registration.
/// @return | nil | No value is returned.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let engine = Rc::new(RefCell::new(TweenEngine::new()));

    // -- update -------------------------------------------------
    /// Advances all active tweens, sequences, parallels, and springs by `dt` seconds.
    /// @param | dt | number | Delta time in seconds for this frame.
    /// @return | nil | No value is returned.
    let s = engine.clone();
    // -- Bindings -------------------------------------------------
    tbl.set("update", lua.create_function(move |lua, dt: f64| {
            TweenEngine::update(&s, lua, dt)?;
            // -- springs -------------------------------------------------
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

    // -- tween -------------------------------------------------
    /// Creates a property tween and registers it for automatic updating.
    /// @param | duration | number | Tween duration in seconds.
    /// @param | target | table | Lua table whose numeric fields will be animated.
    /// @param | fields | table | Mapping of field names to target values.
    /// @param | easing | string? | Optional easing name; defaults to `linear`.
    /// @return | LTween | New tween handle.
    let s = engine.clone();
    tbl.set("tween", lua.create_function(
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

    // -- sequence -------------------------------------------------
    /// Creates an empty tween sequence handle.
    /// @return | LTweenSequence | New sequence handle.
    let s = engine.clone();
    tbl.set("sequence", lua.create_function(move |lua, ()| {
            let seq = LuaTweenSequence::new();
            let ud = lua.create_userdata(seq)?;
            // Pre-register; :start() activates it (active=false means update skips it).
            let key = lua.create_registry_value(ud.clone())?;
            s.borrow_mut().active_seqs.push(key);
            Ok(ud)
        })?,
    )?;

    // -- parallel -------------------------------------------------
    /// Creates an empty parallel tween handle.
    /// @return | LTweenParallel | New parallel handle.
    let s = engine.clone();
    tbl.set("parallel", lua.create_function(move |lua, ()| {
            let par = LuaTweenParallel::new();
            let ud = lua.create_userdata(par)?;
            let key = lua.create_registry_value(ud.clone())?;
            s.borrow_mut().active_pars.push(key);
            Ok(ud)
        })?,
    )?;

    // -- delay -------------------------------------------------
    /// Creates a started delay sequence that waits and then optionally calls a callback.
    /// @param | seconds | number | Delay duration in seconds.
    /// @param | fn | function? | Optional callback to run after the delay.
    /// @return | LTweenSequence | Started sequence handle.
    let s = engine.clone();
    tbl.set("delay", lua.create_function(move |lua, (seconds, cb): (f64, Option<LuaFunction>)| {
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

    // -- cancelAll -------------------------------------------------
    /// Cancels all active tweens, sequences, parallels, and springs immediately.
    /// @return | nil | No value is returned.
    let s = engine.clone();
    tbl.set("cancelAll", lua.create_function(move |lua, ()| {
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

    // -- getActiveCount -------------------------------------------------
    /// Returns the number of currently active tween objects.
    /// @return | integer | Count of active tweens, sequences, parallels, and springs.
    let s = engine.clone();
    tbl.set("getActiveCount", lua.create_function(move |_, ()| Ok(s.borrow().active_count()))?,
    )?;

    // -- registerEasing -------------------------------------------------
    /// Registers a custom easing function under `name`.
    /// @param | name | string | Easing name used by later tween calls.
    /// @param | fn | function | Callback that maps progress from 0..1 to 0..1.
    /// @return | nil | No value is returned.
    let s = engine.clone();
    tbl.set("registerEasing", lua.create_function(move |lua, (name, f): (String, LuaFunction)| {
            let mut state = s.borrow_mut();
            if let Some(old) = state.custom_easings.remove(&name) {
                lua.remove_registry_value(old)?;
            }
            let key = lua.create_registry_value(f)?;
            state.custom_easings.insert(name, key);
            Ok(())
        })?,
    )?;

    // -- getEasingNames -------------------------------------------------
    /// Returns all available built-in and custom easing names.
    /// @return | table | Array-style table of easing names.
    let s = engine.clone();
    tbl.set("getEasingNames", lua.create_function(move |lua, ()| {
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

    // -- newState -------------------------------------------------
    /// Creates a standalone tween state that is not registered with the engine.
    /// @param | duration | number | Tween duration in seconds.
    /// @param | easing | string? | Optional easing name; defaults to `linear`.
    /// @return | LTweenState | New standalone tween state.
    tbl.set("newState", lua.create_function(|lua, (duration, easing): (f64, Option<String>)| {
            lua.create_userdata(LuaTweenState {
                inner: TweenState::new(duration, easing.as_deref().unwrap_or("linear")),
            })
        })?,
    )?;

    // -- to -------------------------------------------------
    /// Creates a tween using `target` as the first argument.
    /// @param | target | table | Lua table whose numeric fields will be animated.
    /// @param | fields | table | Mapping of field names to target values.
    /// @param | duration | number | Tween duration in seconds.
    /// @param | easing | string? | Optional easing name; defaults to `linear`.
    /// @return | LTween | New tween handle.
    let s = engine.clone();
    tbl.set("to", lua.create_function(
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

    // -- spring -------------------------------------------------
    /// Creates a spring animation that drives named table fields toward target values.
    /// @param | target_table | table | Lua table whose numeric fields will be animated.
    /// @param | fields_table | table | Mapping of field names to target values.
    /// @param | opts | table? | Optional stiffness, damping, and precision settings.
    /// @return | LSpring | New spring handle.
    let s = engine.clone();
    tbl.set("spring", lua.create_function(
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

/// A managed interpolation from start to end values over time.
impl LuaUserData for LuaTween {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- cancel -------------------------------------------------
        /// Cancels this tween immediately; fires the `onCancel` callback if set.
        /// @return | nil | No value is returned.
        methods.add_function("cancel", |lua, ud: LuaAnyUserData| {
            let mut tw = ud.borrow_mut::<LuaTween>()?;
            tw.active = false;
            if let Some(k) = tw.on_cancel.take() {
                if let Ok(f) = lua.registry_value::<LuaFunction>(&k) {
                    let _ = f.call::<_, ()>(());
                }
                lua.remove_registry_value(k)?;
            }
            Ok(())
        });

        // -- pause -------------------------------------------------
        /// Pauses this tween; time stops advancing but the tween is not cancelled.
        /// @return | nil | No value is returned.
        methods.add_method_mut("pause", |_, this, ()| {
            this.paused = true;
            Ok(())
        });

        // -- resume -------------------------------------------------
        /// Resumes a paused tween, continuing from the position where it was paused.
        /// @return | nil | No value is returned.
        methods.add_method_mut("resume", |_, this, ()| {
            this.paused = false;
            Ok(())
        });

        // -- isActive -------------------------------------------------
        /// Returns true if the tween is still running (not completed or cancelled).
        /// @return | boolean | True when the tween is still active.
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // -- getProgress -------------------------------------------------
        /// Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
        /// @return | number | Raw playback progress in the range 0 to 1.
        methods.add_method("getProgress", |_, this, ()| Ok(this.state.t_raw() as f64));

        // -- setRepeat -------------------------------------------------
        /// Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
        /// @param | n | integer | Extra cycles after the first; use -1 for infinite repeats.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setRepeat", |_, this, n: i32| {
            this.repeat_count = n;
            this.cycles_remaining = n;
            Ok(())
        });

        // -- setYoyo -------------------------------------------------
        /// Enables or disables yoyo (ping-pong) on each repeat cycle.
        /// @param | enabled | boolean | True to reverse direction on each repeat cycle.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setYoyo", |_, this, enabled: bool| {
            this.yoyo = enabled;
            Ok(())
        });

        // -- onComplete -------------------------------------------------
        /// Sets a callback to fire when the tween finishes all cycles.
        /// @param | self | LTween | Tween handle returned for chaining.
        /// @param | f | function | Callback to run when the tween completes.
        /// @return | LTween | The same tween handle.
        methods.add_function("onComplete", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
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

        // -- onUpdate -------------------------------------------------
        /// Sets a callback called every tick with the current eased progress.
        /// @param | self | LTween | Tween handle returned for chaining.
        /// @param | f | function | Callback that receives the current eased progress.
        /// @return | LTween | The same tween handle.
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

        // -- onCancel -------------------------------------------------
        /// Sets a callback called when the tween is cancelled.
        /// @param | self | LTween | Tween handle returned for chaining.
        /// @param | f | function | Callback to run when the tween is cancelled.
        /// @return | LTween | The same tween handle.
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
        /// @return | string | The literal type name.
        methods.add_method("type", |_, _, ()| Ok("LTween"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the object matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTween" || name == "Object")
        });
    }
}

/// A chained sequence of animations that run one after another.
impl LuaUserData for LuaTweenSequence {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- tween -------------------------------------------------
        /// Appends a tween step to the sequence.
        /// @param | self | LTweenSequence | Sequence handle returned for chaining.
        /// @param | duration | number | Tween duration in seconds.
        /// @param | target | table | Lua table whose numeric fields will be animated.
        /// @param | fields | table | Mapping of field names to target values.
        /// @param | easing | string? | Optional easing name; defaults to `linear`.
        /// @return | LTweenSequence | The same sequence handle.
        methods.add_function("tween", |lua,
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

        // -- delay -------------------------------------------------
        /// Appends a delay step to the sequence.
        /// @param | self | LTweenSequence | Sequence handle returned for chaining.
        /// @param | seconds | number | Delay duration in seconds.
        /// @param | fn | function? | Optional callback to run after the delay.
        /// @return | LTweenSequence | The same sequence handle.
        methods.add_function("delay", |lua, (ud, seconds, cb): (LuaAnyUserData, f64, Option<LuaFunction>)| {
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

        // -- callback -------------------------------------------------
        /// Appends an immediate callback step to the sequence.
        /// @param | self | LTweenSequence | Sequence handle returned for chaining.
        /// @param | fn | function | Callback to run at this step.
        /// @return | LTweenSequence | The same sequence handle.
        methods.add_function("callback", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
            let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
            let key = lua.create_registry_value(f)?;
            seq.steps.push(SequenceStep::Callback(key));
            drop(seq);
            Ok(ud)
        });

        // -- start -------------------------------------------------
        /// Marks the sequence as active so `lurek.tween.update(dt)` begins ticking it.
        /// @param | self | LTweenSequence | Sequence handle returned for chaining.
        /// @return | LTweenSequence | The same sequence handle.
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenSequence>()?.active = true;
            Ok(ud)
        });

        // -- cancel -------------------------------------------------
        /// Cancels the sequence and stops all pending steps.
        /// @return | nil | No value is returned.
        methods.add_method_mut("cancel", |_, this, ()| {
            this.active = false;
            Ok(())
        });

        // -- isActive -------------------------------------------------
        /// Returns true if the sequence has been started and has not yet completed.
        /// @return | boolean | True when the sequence is active.
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // -- onComplete -------------------------------------------------
        /// Sets a callback fired when all steps complete.
        /// @param | self | LTweenSequence | Sequence handle returned for chaining.
        /// @param | fn | function | Callback to run when the sequence completes.
        /// @return | LTweenSequence | The same sequence handle.
        methods.add_function("onComplete", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
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
        /// @return | string | The literal type name.
        methods.add_method("type", |_, _, ()| Ok("LTweenSequence"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the object matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenSequence" || name == "Object")
        });
    }
}

/// A group of animations that run simultaneously over the same duration.
impl LuaUserData for LuaTweenParallel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add -------------------------------------------------
        /// Adds an existing tween handle to the parallel group.
        /// @param | self | LTweenParallel | Parallel handle that receives the tween.
        /// @param | tween | LTween | Tween handle to add to the group.
        /// @return | nil | No value is returned.
        methods.add_function("add", |lua, (par_ud, tw_ud): (LuaAnyUserData, LuaAnyUserData)| {
                // Extract tween data into an embedded ParallelEntry, mark original as owned.
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

        // -- tween -------------------------------------------------
        /// Creates and adds an inline tween entry to the parallel group.
        /// @param | self | LTweenParallel | Parallel handle returned for chaining.
        /// @param | duration | number | Tween duration in seconds.
        /// @param | target | table | Lua table whose numeric fields will be animated.
        /// @param | fields | table | Mapping of field names to target values.
        /// @param | easing | string? | Optional easing name; defaults to `linear`.
        /// @return | LTweenParallel | The same parallel handle.
        methods.add_function("tween", |lua,
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

        // -- start -------------------------------------------------
        /// Marks the parallel as active.
        /// @param | self | LTweenParallel | Parallel handle returned for chaining.
        /// @return | LTweenParallel | The same parallel handle.
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenParallel>()?.active = true;
            Ok(ud)
        });

        // -- cancel -------------------------------------------------
        /// Cancels the parallel group immediately.
        /// @return | nil | No value is returned.
        methods.add_method_mut("cancel", |_, this, ()| {
            this.active = false;
            Ok(())
        });

        // -- isActive -------------------------------------------------
        /// Returns true if the parallel is running and not yet complete.
        /// @return | boolean | True when the parallel is active.
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // -- onComplete -------------------------------------------------
        /// Sets a callback fired when all child tweens finish.
        /// @param | self | LTweenParallel | Parallel handle returned for chaining.
        /// @param | fn | function | Callback to run when the parallel group completes.
        /// @return | LTweenParallel | The same parallel handle.
        methods.add_function("onComplete", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
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
        /// @return | string | The literal type name.
        methods.add_method("type", |_, _, ()| Ok("LTweenParallel"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the object matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenParallel" || name == "Object")
        });
    }
}

/// A physics-based spring animation handle.
impl LuaUserData for LuaSpring {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update -------------------------------------------------
        /// Advances the spring by `dt` seconds.
        /// @param | dt | number | Delta time in seconds.
        /// @return | boolean | True while the spring is still moving.
        methods.add_method_mut("update", |lua, this, dt: f64| {
            if !this.active {
                return Ok(false);
            }
            // tick_with returns true=done; invert for "still moving"
            this.tick_with(lua, dt).map(|done| !done)
        });

        // -- isSettled -------------------------------------------------
        /// Returns whether all spring axes have settled.
        /// @return | boolean | True when all axes converged within precision.
        methods.add_method("isSettled", |_, this, ()| Ok(this.system.is_settled()));

        // -- isActive -------------------------------------------------
        /// Returns whether the spring is still active.
        /// @return | boolean | True when the spring has not been cancelled or settled.
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // -- setTarget -------------------------------------------------
        /// Updates target values for all fields present in `fields_table`.
        /// @param | fields_table | table | Mapping of field names to new target values.
        /// @return | nil | No value is returned.
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

        // -- setStiffness -------------------------------------------------
        /// Updates the stiffness constant on all axes.
        /// @param | value | number | New stiffness value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setStiffness", |_, this, value: f32| {
            this.system.stiffness = value;
            for axis in this.system.axes.values_mut() {
                axis.stiffness = value;
            }
            Ok(())
        });

        // -- setDamping -------------------------------------------------
        /// Updates the damping coefficient on all axes.
        /// @param | value | number | New damping value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setDamping", |_, this, value: f32| {
            this.system.damping = value;
            for axis in this.system.axes.values_mut() {
                axis.damping = value;
            }
            Ok(())
        });

        // -- cancel -------------------------------------------------
        /// Stops the spring.
        /// @return | nil | No value is returned.
        methods.add_method_mut("cancel", |lua, this, ()| {
            this.active = false;
            if let Some(k) = this.on_settle_key.take() {
                lua.remove_registry_value(k)?;
            }
            Ok(())
        });

        // -- getPosition -------------------------------------------------
        /// Returns the current interpolated position for the named field.
        /// @param | field | string | Field name to read from the spring system.
        /// @return | number | Current field position; missing fields yield `nil` at runtime.
        methods.add_method("getPosition", |_, this, field: String| {
            Ok(this.system.get_position(&field).map(|p| p as f64))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | The literal type name.
        methods.add_method("type", |_, _, ()| Ok("LSpring"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the object matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpring" || name == "Object")
        });
    }
}
