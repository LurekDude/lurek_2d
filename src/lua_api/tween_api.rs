//! `lurek.tween` — thin Lua registration wrapper for the property tween system.
//!
//! # Purpose
//!
//! This file is a **registration-only** wrapper following the Thin Wrapper Rule:
//! it contains `pub fn register()` and the closure bodies that delegate immediately
//! to domain types in `src/tween/`. All business logic, structs, and state machines
//! live in `src/tween/handle.rs` (`LuaTween`, `LuaTweenSequence`, `LuaTweenParallel`)
//! and `src/tween/engine.rs` (`TweenEngine`).
//!
//! # Architecture
//!
//! `TweenEngine` is a module-local `Rc<RefCell<…>>` that tracks all active handle
//! objects via `LuaRegistryKey` references. Lua scripts hold UserData handles and
//! keep them alive for the duration of the animation. The engine never ticks tweens
//! automatically — the script must call `lurek.tween.update(dt)` from `lurek.process`.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::tween::{
    builtin_easing_names, LuaTween, LuaTweenParallel, LuaTweenSequence, ParallelEntry,
    SequenceStep, TweenEngine, TweenState,
};

/// Registers the `lurek.tween` property tweening API.
///
///
/// Exposes factory functions (`tween`, `sequence`, `parallel`, `delay`), lifecycle
/// utilities (`update`, `cancelAll`, `getActiveCount`), and easing introspection
/// (`registerEasing`, `getEasingNames`). Three UserData types — `LuaTween`,
/// `LuaTweenSequence`, and `LuaTweenParallel` — are registered via
/// `lua.register_userdata_type`.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
/// @return LuaResult<()>
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let engine = Rc::new(RefCell::new(TweenEngine::new()));

    // ─── update ───────────────────────────────────────────────────────────
    /// Advances all active tweens, sequences, and parallels by `dt` seconds.
    /// Call this once per frame from `lurek.process(dt)`.
    /// @param dt : number
    /// @return nil
    let s = engine.clone();
    // ─── Bindings ─────────────────────────────────────────────────────────────────
    tbl.set(
        "update",
        lua.create_function(move |lua, dt: f64| TweenEngine::update(&s, lua, dt))?,
    )?;

    // ─── tween ────────────────────────────────────────────────────────────
    /// Creates a new property tween and registers it for automatic updating.
    /// `target` is any Lua table; `fields` maps field names to their end values.
    /// Start values are captured lazily on the first `update()` call.
    /// @param duration : number
    /// @param target : table
    /// @param fields : table
    /// @param easing : string
    /// @return Tween
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

    // ─── sequence ─────────────────────────────────────────────────────────
    /// Creates an empty TweenSequence. Add steps with :tween(), :delay(), :callback(),
    /// then call :start() to begin and register it for updating.
    /// @return TweenSequence
    let s = engine.clone();
    tbl.set(
        "sequence",
        lua.create_function(move |lua, ()| {
            let seq = LuaTweenSequence::new();
            let ud = lua.create_userdata(seq)?;
            // Pre-register; :start() activates it (active=false means update skips it).
            let key = lua.create_registry_value(ud.clone())?;
            s.borrow_mut().active_seqs.push(key);
            Ok(ud)
        })?,
    )?;

    // ─── parallel ─────────────────────────────────────────────────────────
    /// Creates an empty TweenParallel. Add entries with :tween() or :add(tween),
    /// then call :start() to begin execution.
    /// @return TweenParallel
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

    // ─── delay ────────────────────────────────────────────────────────────
    /// Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
    /// Convenience wrapper around `sequence():delay():start()`.
    /// @param seconds : number
    /// @param fn : function
    /// @return TweenSequence
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

    // ─── cancelAll ────────────────────────────────────────────────────────
    /// Cancels all active tweens, sequences, and parallels immediately.
    /// @return nil
    let s = engine.clone();
    tbl.set(
        "cancelAll",
        lua.create_function(move |lua, ()| TweenEngine::cancel_all(&s, lua))?,
    )?;

    // ─── getActiveCount ───────────────────────────────────────────────────
    /// Returns the number of currently active tween objects (tweens + seqs + pars).
    /// @return integer
    let s = engine.clone();
    tbl.set(
        "getActiveCount",
        lua.create_function(move |_, ()| Ok(s.borrow().active_count()))?,
    )?;

    // ─── registerEasing ───────────────────────────────────────────────────
    /// Registers a custom easing function under `name`. `fn(t)` receives 0..1, returns 0..1.
    /// Overwrites any previous function registered under the same name.
    /// @param name : string
    /// @param fn : function
    /// @return nil
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

    // ─── getEasingNames ───────────────────────────────────────────────────
    /// Returns a list of all available easing names (built-in + custom).
    /// @return table
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

    luna.set("tween", tbl)?;
    Ok(())
}

/// A managed interpolation from start to end values over time.
impl LuaUserData for LuaTween {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // ── cancel ────────────────────────────────────────────────────────
        /// Cancels this tween immediately; fires the `onCancel` callback if set.
        /// @return nil
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

        // ── pause ─────────────────────────────────────────────────────────
        /// Pauses this tween; time stops advancing but the tween is not cancelled.
        /// @return nil
        methods.add_method_mut("pause", |_, this, ()| {
            this.paused = true;
            Ok(())
        });

        // ── resume ────────────────────────────────────────────────────────
        /// Resumes a paused tween.
        /// @return nil
        methods.add_method_mut("resume", |_, this, ()| {
            this.paused = false;
            Ok(())
        });

        // ── isActive ──────────────────────────────────────────────────────
        /// Returns true if the tween is still running (not completed or cancelled).
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // ── getProgress ───────────────────────────────────────────────────
        /// Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
        /// @return number
        methods.add_method("getProgress", |_, this, ()| Ok(this.state.t_raw() as f64));

        // ── setRepeat ─────────────────────────────────────────────────────
        /// Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
        /// @param n : integer
        /// @return nil
        methods.add_method_mut("setRepeat", |_, this, n: i32| {
            this.repeat_count = n;
            this.cycles_remaining = n;
            Ok(())
        });

        // ── setYoyo ───────────────────────────────────────────────────────
        /// Enables or disables yoyo (ping-pong) on each repeat cycle.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setYoyo", |_, this, enabled: bool| {
            this.yoyo = enabled;
            Ok(())
        });

        // ── onComplete ────────────────────────────────────────────────────
        /// Sets a callback to fire when the tween finishes all cycles. Returns self for chaining.
        /// @param fn : function
        /// @return Tween
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

        // ── onUpdate ──────────────────────────────────────────────────────
        /// Sets a callback called every tick with the current eased `t` (0..=1). Returns self.
        /// @param fn : function
        /// @return Tween
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

        // ── onCancel ──────────────────────────────────────────────────────
        /// Sets a callback called when the tween is cancelled. Returns self.
        /// @param fn : function
        /// @return Tween
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
    }
}

/// A chained sequence of animations that run one after another.
impl LuaUserData for LuaTweenSequence {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // ── tween ─────────────────────────────────────────────────────────
        /// Appends a tween step: animates `fields` on `target` over `duration`. Returns self.
        /// @param duration : number
        /// @param target : table
        /// @param fields : table
        /// @param easing : string
        /// @return TweenSequence
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

        // ── delay ─────────────────────────────────────────────────────────
        /// Appends a delay step that waits `seconds` before proceeding. Returns self.
        /// @param seconds : number
        /// @param fn : function
        /// @return TweenSequence
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

        // ── callback ──────────────────────────────────────────────────────
        /// Appends an immediate callback step. Returns self.
        /// @param fn : function
        /// @return TweenSequence
        methods.add_function("callback", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
            let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
            let key = lua.create_registry_value(f)?;
            seq.steps.push(SequenceStep::Callback(key));
            drop(seq);
            Ok(ud)
        });

        // ── start ─────────────────────────────────────────────────────────
        /// Marks the sequence as active so `lurek.tween.update(dt)` begins ticking it. Returns self.
        /// @return TweenSequence
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenSequence>()?.active = true;
            Ok(ud)
        });

        // ── cancel ────────────────────────────────────────────────────────
        /// Cancels the sequence and stops all pending steps.
        /// @return nil
        methods.add_method_mut("cancel", |_, this, ()| {
            this.active = false;
            Ok(())
        });

        // ── isActive ──────────────────────────────────────────────────────
        /// Returns true if the sequence has been started and has not yet completed.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // ── onComplete ────────────────────────────────────────────────────
        /// Sets a callback fired when all steps complete. Returns self.
        /// @param fn : function
        /// @return TweenSequence
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
    }
}

/// A group of animations that run simultaneously over the same duration.
impl LuaUserData for LuaTweenParallel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // ── add ───────────────────────────────────────────────────────────
        /// Adds an existing LuaTween to the parallel group; marks the tween as owned.
        /// @param tween : Tween
        /// @return nil
        methods.add_function(
            "add",
            |lua, (par_ud, tw_ud): (LuaAnyUserData, LuaAnyUserData)| {
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

        // ── tween ─────────────────────────────────────────────────────────
        /// Creates and adds an inline tween entry to the parallel group. Returns self.
        /// @param duration : number
        /// @param target : table
        /// @param fields : table
        /// @param easing : string
        /// @return TweenParallel
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

        // ── start ─────────────────────────────────────────────────────────
        /// Marks the parallel as active. Returns self.
        /// @return TweenParallel
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenParallel>()?.active = true;
            Ok(ud)
        });

        // ── cancel ────────────────────────────────────────────────────────
        /// Cancels the parallel group immediately.
        /// @return nil
        methods.add_method_mut("cancel", |_, this, ()| {
            this.active = false;
            Ok(())
        });

        // ── isActive ──────────────────────────────────────────────────────
        /// Returns true if the parallel is running and not yet complete.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // ── onComplete ────────────────────────────────────────────────────
        /// Sets a callback fired when all child tweens finish. Returns self.
        /// @param fn : function
        /// @return TweenParallel
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
    }
}
