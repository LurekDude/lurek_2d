//! `luna.tween` — thin Lua registration wrapper for the property tween system.
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

use crate::tween::{builtin_easing_names, LuaTween, LuaTweenParallel, LuaTweenSequence, TweenEngine};

/// Registers the `lurek.tween` property tweening API.
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
        lua.create_function(
            move |lua, (seconds, cb): (f64, Option<LuaFunction>)| {
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
            },
        )?,
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
