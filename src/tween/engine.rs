//! Active tween pool and frame-tick orchestration.
//!
//! # Purpose
//!
//! `TweenEngine` owns registry references to all live `LuaTween`, `LuaTweenSequence`,
//! and `LuaTweenParallel` objects. It drives the entire tween system by iterating over
//! those references each frame, delegating to each object's `tick_with()` method, and
//! releasing registry entries when objects complete or are cancelled.
//!
//! # Architecture note
//!
//! `TweenEngine` is instantiated once per Lua VM inside `lurek.tween`'s `register()`
//! call and held in an `Rc<RefCell<TweenEngine>>` shared among all closures in the
//! `lurek.tween.*` namespace. Domain types (`LuaTween`, `LuaTweenSequence`,
//! `LuaTweenParallel`) and the thin Lua wrapper live in sibling modules.
//!
//! # Relationship to mlua
//!
//! This module intentionally depends on `mlua` because it manages `LuaRegistryKey`
//! lifetimes for Lua UserData objects. This is domain logic, not Lua API glue.

use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use crate::tween::handle::{LuaTween, LuaTweenParallel, LuaTweenSequence};

/// Active-object pool and frame-tick driver for the `lurek.tween` system.
///
/// Tracks all live `LuaTween`, `LuaTweenSequence`, `LuaTweenParallel`, and `LuaSpring`
/// objects via `LuaRegistryKey` handles, preventing premature garbage collection.
/// Each frame, `update()` drives every tween object and the Lua API layer ticks springs.
///
/// # Fields
/// - `active_tweens` — `Vec<LuaRegistryKey>`. Registry references to live `LuaTween`.
/// - `active_seqs` — `Vec<LuaRegistryKey>`. Registry references to live `LuaTweenSequence`.
/// - `active_pars` — `Vec<LuaRegistryKey>`. Registry references to live `LuaTweenParallel`.
/// - `active_springs` — `Vec<LuaRegistryKey>`. Registry references to live `LuaSpring`.
/// - `custom_easings` — `HashMap<String, LuaRegistryKey>`. Name → Lua easing function.
pub struct TweenEngine {
    /// Registry references to all currently tracked `LuaTween` objects.
    pub active_tweens: Vec<LuaRegistryKey>,
    /// Registry references to all currently tracked `LuaTweenSequence` objects.
    pub active_seqs: Vec<LuaRegistryKey>,
    /// Registry references to all currently tracked `LuaTweenParallel` objects.
    pub active_pars: Vec<LuaRegistryKey>,
    /// Registry references to all currently tracked `LuaSpring` objects.
    pub active_springs: Vec<LuaRegistryKey>,
    /// User-registered easing functions: name → registry key for the Lua function.
    pub custom_easings: HashMap<String, LuaRegistryKey>,
}

impl TweenEngine {
    /// Creates an empty `TweenEngine` with no active objects.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            active_tweens: Vec::new(),
            active_seqs: Vec::new(),
            active_pars: Vec::new(),
            active_springs: Vec::new(),
            custom_easings: HashMap::new(),
        }
    }

    /// Advances all active tweens, sequences, and parallels by `dt` seconds.
    ///
    /// Objects that complete or have been externally cancelled are removed from the
    /// tracking lists and their registry entries are freed. The `on_cancel` callback
    /// fires for tweens that were cancelled externally before this call.
    ///
    /// # Parameters
    /// - `this_rc` — `&Rc<RefCell<TweenEngine>>`. Shared reference to self.
    /// - `lua` — `&Lua`. Active Lua VM.
    /// - `dt` — `f64`. Delta-time in seconds.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn update(this_rc: &Rc<RefCell<Self>>, lua: &Lua, dt: f64) -> LuaResult<()> {
        // ── standalone tweens ─────────────────────────────────────────────
        let tween_keys = std::mem::take(&mut this_rc.borrow_mut().active_tweens);
        let mut still_active_tweens = Vec::with_capacity(tween_keys.len());
        for key in tween_keys {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            let done = {
                let mut tw = ud.borrow_mut::<LuaTween>()?;
                if tw.owned_by_parent || !tw.active {
                    if !tw.active {
                        if let Some(k) = tw.on_cancel.take() {
                            let f: LuaFunction = lua.registry_value(&k)?;
                            let _ = f.call::<_, ()>(());
                            lua.remove_registry_value(k)?;
                        }
                    }
                    true
                } else {
                    tw.tick_with(lua, dt)?
                }
            };
            if done {
                lua.remove_registry_value(key)?;
            } else {
                still_active_tweens.push(key);
            }
        }
        this_rc.borrow_mut().active_tweens = still_active_tweens;

        // ── sequences ─────────────────────────────────────────────────────
        let seq_keys = std::mem::take(&mut this_rc.borrow_mut().active_seqs);
        let mut still_active_seqs = Vec::with_capacity(seq_keys.len());
        for key in seq_keys {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            let done = {
                let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
                if !seq.active {
                    true
                } else {
                    seq.tick_with(lua, dt)?
                }
            };
            if done {
                lua.remove_registry_value(key)?;
            } else {
                still_active_seqs.push(key);
            }
        }
        this_rc.borrow_mut().active_seqs = still_active_seqs;

        // ── parallels ─────────────────────────────────────────────────────
        let par_keys = std::mem::take(&mut this_rc.borrow_mut().active_pars);
        let mut still_active_pars = Vec::with_capacity(par_keys.len());
        for key in par_keys {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            let done = {
                let mut par = ud.borrow_mut::<LuaTweenParallel>()?;
                if !par.active {
                    true
                } else {
                    par.tick_with(lua, dt)?
                }
            };
            if done {
                lua.remove_registry_value(key)?;
            } else {
                still_active_pars.push(key);
            }
        }
        this_rc.borrow_mut().active_pars = still_active_pars;

        Ok(())
    }

    /// Cancels and removes all active tweens, sequences, and parallels.
    ///
    /// The `on_cancel` callback fires for each tween that has one set. After this
    /// call, `update()` has nothing to tick until new objects are registered.
    ///
    /// # Parameters
    /// - `this_rc` — `&Rc<RefCell<TweenEngine>>`.
    /// - `lua` — `&Lua`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn cancel_all(this_rc: &Rc<RefCell<Self>>, lua: &Lua) -> LuaResult<()> {
        let (tweens, seqs, pars) = {
            let mut s = this_rc.borrow_mut();
            (
                std::mem::take(&mut s.active_tweens),
                std::mem::take(&mut s.active_seqs),
                std::mem::take(&mut s.active_pars),
            )
        };
        for key in tweens {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            {
                let mut tw = ud.borrow_mut::<LuaTween>()?;
                tw.active = false;
                if let Some(k) = tw.on_cancel.take() {
                    let f: LuaFunction = lua.registry_value(&k)?;
                    let _ = f.call::<_, ()>(());
                    lua.remove_registry_value(k)?;
                }
            }
            lua.remove_registry_value(key)?;
        }
        for key in seqs {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            {
                ud.borrow_mut::<LuaTweenSequence>()?.active = false;
            }
            lua.remove_registry_value(key)?;
        }
        for key in pars {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            {
                ud.borrow_mut::<LuaTweenParallel>()?.active = false;
            }
            lua.remove_registry_value(key)?;
        }
        Ok(())
    }

    /// Returns the total number of currently tracked objects (tweens + seqs + pars + springs).
    ///
    /// # Returns
    /// `usize`.
    pub fn active_count(&self) -> usize {
        self.active_tweens.len()
            + self.active_seqs.len()
            + self.active_pars.len()
            + self.active_springs.len()
    }
}

impl Default for TweenEngine {
    /// Creates an empty `TweenEngine`. Delegates to `TweenEngine::new()`.
    fn default() -> Self {
        Self::new()
    }
}
