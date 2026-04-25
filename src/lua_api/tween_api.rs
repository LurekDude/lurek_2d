//! `lurek.tween` â€” thin Lua registration wrapper for the property tween system.
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
//! `TweenEngine` is a module-local `Rc<RefCell<â€¦>>` that tracks all active handle
//! objects via `LuaRegistryKey` references. Lua scripts hold UserData handles and
//! keep them alive for the duration of the animation. The engine never ticks tweens
//! automatically â€” the script must call `lurek.tween.update(dt)` from `lurek.process`.

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
        /// @param dt number
        /// @return boolean
        methods.add_method_mut("tick", |_, this, dt: f64| Ok(this.inner.tick(dt)));

        // -- isComplete --
        /// Returns whether the tween state has completed.
        /// @return boolean
        methods.add_method("isComplete", |_, this, ()| Ok(this.inner.is_complete()));

        // -- t --
        /// Returns the raw 0..1 playback progress.
        /// @return number
        methods.add_method("t", |_, this, ()| Ok(this.inner.t_raw() as f64));

        // -- lerp --
        /// Interpolates from `start` to `finish` using the eased tween progress.
        /// @param start number
        /// @param finish number
        /// @return number
        methods.add_method("lerp", |_, this, (start, finish): (f64, f64)| {
            Ok(this.inner.lerp(start, finish))
        });

        // -- reset --
        /// Resets the tween state to elapsed time zero.
        /// @return nil
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LTweenState"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
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
/// - `system` â€” `SpringSystem`. The multi-axis damped spring simulation.
/// - `target_table_key` â€” `Option<LuaRegistryKey>`. Registry key for the animated Lua table.
/// - `on_settle_key` â€” `Option<LuaRegistryKey>`. Optional callback fired when all axes settle.
/// - `field_names` â€” `Vec<String>`. Ordered list of field names being animated.
/// - `active` â€” `bool`. `false` once settled or cancelled.
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
    /// Advances the spring by `dt` seconds, writes positions to the target table,
    /// fires the settle callback if all axes converge, and returns `true` when done.
    ///
    /// @param lua &Lua
    /// - `dt` â€” `f64` â€” Delta-time in seconds.
    ///
    /// `LuaResult<bool>` â€” `true` when settled / done, `false` while still moving.
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
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param _state Rc<RefCell<SharedState>>
///
///
/// Exposes factory functions (`tween`, `sequence`, `parallel`, `delay`), lifecycle
/// utilities (`update`, `cancelAll`, `getActiveCount`), and easing introspection
/// (`registerEasing`, `getEasingNames`). Three UserData types â€” `LuaTween`,
/// `LuaTweenSequence`, and `LuaTweenParallel` â€” are registered via
/// `lua.register_userdata_type`.
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param _state Rc<RefCell<SharedState>>
/// @return LuaResult<()>
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let engine = Rc::new(RefCell::new(TweenEngine::new()));

    // â”€â”€â”€ update â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Advances all active tweens, sequences, and parallels by `dt` seconds.
    /// Call this once per frame from `lurek.process(dt)`.
    /// @param dt number
    /// @return nil
    let s = engine.clone();
    // â”€â”€â”€ Bindings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    tbl.set(
        "update",
        lua.create_function(move |lua, dt: f64| {
            TweenEngine::update(&s, lua, dt)?;
            // â”€â”€ springs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    // â”€â”€â”€ tween â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new property tween and registers it for automatic updating.
    /// `target` is any Lua table; `fields` maps field names to their end values.
    /// Start values are captured lazily on the first `update()` call.
    /// @param duration number
    /// @param target table
    /// @param fields table
    /// @param easing? string
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

    // â”€â”€â”€ sequence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    // â”€â”€â”€ parallel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    // â”€â”€â”€ delay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
    /// Convenience wrapper around `sequence():delay():start()`.
    /// @param seconds number
    /// @param fn function
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

    // â”€â”€â”€ cancelAll â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Cancels all active tweens, sequences, parallels, and springs immediately.
    /// @return nil
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

    // â”€â”€â”€ getActiveCount â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Returns the number of currently active tween objects (tweens + seqs + pars).
    /// @return integer
    let s = engine.clone();
    tbl.set(
        "getActiveCount",
        lua.create_function(move |_, ()| Ok(s.borrow().active_count()))?,
    )?;

    // â”€â”€â”€ registerEasing â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Registers a custom easing function under `name`. `fn(t)` receives 0..1, returns 0..1.
    /// Overwrites any previous function registered under the same name.
    /// @param name string
    /// @param fn function
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

    // â”€â”€â”€ getEasingNames â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    // â”€â”€â”€ newState â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a standalone tween timing state without registering it with the engine.
    /// Useful for unit-style Lua tests and custom interpolation flows.
    /// @param duration number
    /// @param easing? string
    /// @return TweenState
    tbl.set(
        "newState",
        lua.create_function(|lua, (duration, easing): (f64, Option<String>)| {
            lua.create_userdata(LuaTweenState {
                inner: TweenState::new(duration, easing.as_deref().unwrap_or("linear")),
            })
        })?,
    )?;

    // â”€â”€â”€ to â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Sugar for `tween()` with `target` first â€” natural read order.
    /// Equivalent to `lurek.tween.tween(duration, target, fields, easing)`.
    /// @param target table
    /// @param fields table
    /// @param duration number
    /// @param easing string?
    /// @return Tween
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

    // â”€â”€â”€ spring â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a physics-based spring animation that drives named fields on `target_table`
    /// toward the values in `fields_table`. Current field values are read immediately as
    /// starting positions. Tick via `:update(dt)` or `lurek.tween.update(dt)`.
    ///
    /// `opts` may contain: `stiffness` (default 100), `damping` (default 10),
    /// `precision` (default 0.001).
    /// @param target_table table
    /// @param fields_table table
    /// @param opts table?
    /// @return Spring
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

/// A managed interpolation from start to end values over time.
impl LuaUserData for LuaTween {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // â”€â”€ cancel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

        // â”€â”€ pause â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Pauses this tween; time stops advancing but the tween is not cancelled.
        /// @return nil
        methods.add_method_mut("pause", |_, this, ()| {
            this.paused = true;
            Ok(())
        });

        // â”€â”€ resume â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Resumes a paused tween, continuing from the position where it was paused.
        /// @return nil
        methods.add_method_mut("resume", |_, this, ()| {
            this.paused = false;
            Ok(())
        });

        // â”€â”€ isActive â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Returns true if the tween is still running (not completed or cancelled).
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // â”€â”€ getProgress â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
        /// @return number
        methods.add_method("getProgress", |_, this, ()| Ok(this.state.t_raw() as f64));

        // â”€â”€ setRepeat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
        /// @param n integer
        /// @return nil
        methods.add_method_mut("setRepeat", |_, this, n: i32| {
            this.repeat_count = n;
            this.cycles_remaining = n;
            Ok(())
        });

        // â”€â”€ setYoyo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Enables or disables yoyo (ping-pong) on each repeat cycle.
        /// @param enabled boolean
        /// @return nil
        methods.add_method_mut("setYoyo", |_, this, enabled: bool| {
            this.yoyo = enabled;
            Ok(())
        });

        // â”€â”€ onComplete â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Sets a callback to fire when the tween finishes all cycles. Returns self for chaining.
        /// @param self Tween
        /// @param f function
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

        // â”€â”€ onUpdate â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Sets a callback called every tick with the current eased `t` (0..=1). Returns self.
        /// @param self Tween
        /// @param f function
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

        // â”€â”€ onCancel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Sets a callback called when the tween is cancelled. Returns self.
        /// @param self Tween
        /// @param f function
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

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LTween"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTween" || name == "Object")
        });
    }
}

/// A chained sequence of animations that run one after another.
impl LuaUserData for LuaTweenSequence {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // â”€â”€ tween â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Appends a tween step: animates `fields` on `target` over `duration`. Returns self.
        /// @param self TweenSequence
        /// @param duration number
        /// @param target table
        /// @param fields table
        /// @param easing? string
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

        // â”€â”€ delay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Appends a delay step that waits `seconds` before proceeding. Returns self.
        /// @param self TweenSequence
        /// @param seconds number
        /// @param fn function
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

        // â”€â”€ callback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Appends an immediate callback step. Returns self.
        /// @param self TweenSequence
        /// @param fn function
        /// @return TweenSequence
        methods.add_function("callback", |lua, (ud, f): (LuaAnyUserData, LuaFunction)| {
            let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
            let key = lua.create_registry_value(f)?;
            seq.steps.push(SequenceStep::Callback(key));
            drop(seq);
            Ok(ud)
        });

        // â”€â”€ start â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Marks the sequence as active so `lurek.tween.update(dt)` begins ticking it. Returns self.
        /// @param self TweenSequence
        /// @return TweenSequence
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenSequence>()?.active = true;
            Ok(ud)
        });

        // â”€â”€ cancel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Cancels the sequence and stops all pending steps.
        /// @return nil
        methods.add_method_mut("cancel", |_, this, ()| {
            this.active = false;
            Ok(())
        });

        // â”€â”€ isActive â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Returns true if the sequence has been started and has not yet completed.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // â”€â”€ onComplete â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Sets a callback fired when all steps complete. Returns self.
        /// @param self TweenSequence
        /// @param fn function
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

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LTweenSequence"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenSequence" || name == "Object")
        });
    }
}

/// A group of animations that run simultaneously over the same duration.
impl LuaUserData for LuaTweenParallel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // â”€â”€ add â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Adds an existing LuaTween to the parallel group; marks the tween as owned.
        /// @param self TweenParallel
        /// @param tween Tween
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

        // â”€â”€ tween â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Creates and adds an inline tween entry to the parallel group. Returns self.
        /// @param self TweenParallel
        /// @param duration number
        /// @param target table
        /// @param fields table
        /// @param easing? string
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

        // â”€â”€ start â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Marks the parallel as active. Returns self.
        /// @param self TweenParallel
        /// @return TweenParallel
        methods.add_function("start", |_lua, ud: LuaAnyUserData| {
            ud.borrow_mut::<LuaTweenParallel>()?.active = true;
            Ok(ud)
        });

        // â”€â”€ cancel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Cancels the parallel group immediately.
        /// @return nil
        methods.add_method_mut("cancel", |_, this, ()| {
            this.active = false;
            Ok(())
        });

        // â”€â”€ isActive â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Returns true if the parallel is running and not yet complete.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // â”€â”€ onComplete â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Sets a callback fired when all child tweens finish. Returns self.
        /// @param self TweenParallel
        /// @param fn function
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

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LTweenParallel"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTweenParallel" || name == "Object")
        });
    }
}

/// A physics-based spring animation handle.
impl LuaUserData for LuaSpring {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // â”€â”€ update â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Advances the spring by `dt` seconds and writes positions to the target table.
        /// Returns `true` while still moving, `false` when settled.
        /// @param dt number
        /// @return boolean
        methods.add_method_mut("update", |lua, this, dt: f64| {
            if !this.active {
                return Ok(false);
            }
            // tick_with returns true=done; invert for "still moving"
            this.tick_with(lua, dt).map(|done| !done)
        });

        // â”€â”€ isSettled â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Returns `true` when all spring axes have converged within `precision`.
        /// @return boolean
        methods.add_method("isSettled", |_, this, ()| Ok(this.system.is_settled()));

        // â”€â”€ isActive â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Returns `true` if the spring has not been cancelled or settled.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| Ok(this.active));

        // â”€â”€ setTarget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Updates target values for all fields present in `fields_table`.
        /// Clears the settled flag so the spring responds to the new targets.
        /// @param fields_table table
        /// @return nil
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

        // â”€â”€ setStiffness â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Updates the stiffness constant on all axes.
        /// @param value number
        /// @return nil
        methods.add_method_mut("setStiffness", |_, this, value: f32| {
            this.system.stiffness = value;
            for axis in this.system.axes.values_mut() {
                axis.stiffness = value;
            }
            Ok(())
        });

        // â”€â”€ setDamping â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Updates the damping coefficient on all axes.
        /// @param value number
        /// @return nil
        methods.add_method_mut("setDamping", |_, this, value: f32| {
            this.system.damping = value;
            for axis in this.system.axes.values_mut() {
                axis.damping = value;
            }
            Ok(())
        });

        // â”€â”€ cancel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Stops the spring. The engine will drop it on the next `update(dt)` call.
        /// @return nil
        methods.add_method_mut("cancel", |lua, this, ()| {
            this.active = false;
            if let Some(k) = this.on_settle_key.take() {
                lua.remove_registry_value(k)?;
            }
            Ok(())
        });

        // â”€â”€ getPosition â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// Returns the current interpolated position for the named field, or `nil`.
        /// @param field string
        /// @return number?
        methods.add_method("getPosition", |_, this, field: String| {
            Ok(this.system.get_position(&field).map(|p| p as f64))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LSpring"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpring" || name == "Object")
        });
    }
}
