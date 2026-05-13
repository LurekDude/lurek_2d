use super::SharedState;
use crate::tween::{
    builtin_easing_names, LuaTween, LuaTweenParallel, LuaTweenSequence, ParallelEntry,
    SequenceStep, SpringSystem, TweenEngine, TweenState,
};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
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
        methods.add_method_mut("tick", |_, this, dt: f64| Ok(this.inner.tick(dt)));
        methods.add_method("isComplete", |_, this, ()| Ok(this.inner.is_complete()));
        methods.add_method("t", |_, this, ()| Ok(this.inner.t_raw() as f64));
        methods.add_method("lerp", |_, this, (start, finish): (f64, f64)| {
            Ok(this.inner.lerp(start, finish))
        });
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LTweenState"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenState" || name == "Object")
        });
    }
}
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
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let engine = Rc::new(RefCell::new(TweenEngine::new()));
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
    let s = engine.clone();
    tbl.set(
        "getActiveCount",
        lua.create_function(move |_, ()| Ok(s.borrow().active_count()))?,
    )?;
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
    tbl.set(
        "newState",
        lua.create_function(|lua, (duration, easing): (f64, Option<String>)| {
            lua.create_userdata(LuaTweenState {
                inner: TweenState::new(duration, easing.as_deref().unwrap_or("linear")),
            })
        })?,
    )?;
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
        methods.add_method_mut("pause", |_, this, ()| {
            this.paused = true;
            Ok(())
        });
        methods.add_method_mut("resume", |_, this, ()| {
            this.paused = false;
            Ok(())
        });
        methods.add_method("isActive", |_, this, ()| Ok(this.active));
        methods.add_method("getProgress", |_, this, ()| Ok(this.progress()));
        methods.add_method("getElapsed", |_, this, ()| Ok(this.elapsed()));
        methods.add_method("getDuration", |_, this, ()| Ok(this.state.duration));
        methods.add_method("getRemaining", |_, this, ()| Ok(this.remaining()));
        methods.add_method("getFields", |lua, this, ()| {
            let out = lua.create_table()?;
            for (idx, field) in this.fields.iter().enumerate() {
                out.set((idx + 1) as i64, field.as_str())?;
            }
            Ok(out)
        });
        methods.add_method_mut("setRelative", |_, this, enabled: bool| {
            this.set_relative(enabled);
            Ok(())
        });
        methods.add_function("relative", |_, (ud, enabled): (LuaAnyUserData, bool)| {
            ud.borrow_mut::<LuaTween>()?.set_relative(enabled);
            Ok(ud)
        });
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
        methods.add_method_mut("setRepeat", |_, this, n: i32| {
            this.repeat_count = n;
            this.cycles_remaining = n;
            Ok(())
        });
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
        methods.add_method("type", |_, _, ()| Ok("LTween"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTween" || name == "Object")
        });
    }
}
impl LuaUserData for LuaTweenSequence {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_function("callback", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
            let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
            let key = lua.create_registry_value(f)?;
            seq.steps.push(SequenceStep::Callback(key));
            drop(seq);
            Ok(ud)
        });
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenSequence>()?.active = true;
            Ok(ud)
        });
        methods.add_method_mut("cancel", |lua, this, ()| {
            this.active = false;
            this.resume_waiters(lua)?;
            Ok(())
        });
        methods.add_method("isActive", |_, this, ()| Ok(this.active));
        methods.add_method("getProgress", |_, this, ()| Ok(this.progress_ratio()));
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
        methods.add_method("type", |_, _, ()| Ok("LTweenSequence"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenSequence" || name == "Object")
        });
    }
}
impl LuaUserData for LuaTweenParallel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenParallel>()?.active = true;
            Ok(ud)
        });
        methods.add_method_mut("cancel", |_, this, ()| {
            this.active = false;
            Ok(())
        });
        methods.add_method("isActive", |_, this, ()| Ok(this.active));
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
        methods.add_method("type", |_, _, ()| Ok("LTweenParallel"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenParallel" || name == "Object")
        });
    }
}
impl LuaUserData for LuaSpring {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("update", |lua, this, dt: f64| {
            if !this.active {
                return Ok(false);
            }
            this.tick_with(lua, dt).map(|done| !done)
        });
        methods.add_method("isSettled", |_, this, ()| Ok(this.system.is_settled()));
        methods.add_method("isActive", |_, this, ()| Ok(this.active));
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
        methods.add_method_mut("setStiffness", |_, this, value: f32| {
            this.system.stiffness = value;
            for axis in this.system.axes.values_mut() {
                axis.stiffness = value;
            }
            Ok(())
        });
        methods.add_method_mut("setDamping", |_, this, value: f32| {
            this.system.damping = value;
            for axis in this.system.axes.values_mut() {
                axis.damping = value;
            }
            Ok(())
        });
        methods.add_method_mut("cancel", |lua, this, ()| {
            this.active = false;
            if let Some(k) = this.on_settle_key.take() {
                lua.remove_registry_value(k)?;
            }
            Ok(())
        });
        methods.add_method("getPosition", |_, this, field: String| {
            Ok(this.system.get_position(&field).map(|p| p as f64))
        });
        methods.add_method("type", |_, _, ()| Ok("LSpring"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpring" || name == "Object")
        });
    }
}
