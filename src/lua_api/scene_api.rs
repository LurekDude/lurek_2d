//! `lurek.scene` â€” Scene stack management, transitions, registry, and depth-sorted rendering.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;

use crate::scene::depth_sorter::DepthSorter;
use crate::scene::stack::{SceneId, SceneStack};
use crate::scene::transition::{EasingType, TransitionType};

// -------------------------------------------------------------------------------
// SceneState
// -------------------------------------------------------------------------------

/// Internal state managed by the scene API layer.
struct SceneState {
    /// The LIFO scene stack with registry and transition support.
    stack: SceneStack,
    /// Maps each SceneId to its Lua table stored in the registry.
    scene_refs: HashMap<SceneId, LuaRegistryKey>,
    /// Maps string keys to Lua values stored in the registry.
    data_refs: HashMap<String, LuaRegistryKey>,
    /// Scenes whose `ready` callback has not yet fired (fires on first process tick).
    scene_ready_pending: HashSet<SceneId>,
    /// Pending preload listeners: scene name â†’ loader function registry key.
    preload_callbacks: HashMap<String, LuaRegistryKey>,
    /// Names of scenes that have been successfully preloaded.
    preloaded_names: HashSet<String>,
}

// -------------------------------------------------------------------------------
// Helper
// -------------------------------------------------------------------------------

/// Calls an optional method on a scene table stored in the Lua registry.
fn call_scene_method<'a>(
    lua: &'a Lua,
    scene_key: &LuaRegistryKey,
    method: &str,
    args: impl IntoLuaMulti<'a>,
) -> LuaResult<()> {
    let table: LuaTable = lua.registry_value(scene_key)?;
    if let Ok(func) = table.get::<_, LuaFunction>(method) {
        func.call::<_, ()>((table.clone(), args))?;
    }
    Ok(())
}

// -------------------------------------------------------------------------------
// LuaDepthSorter UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`DepthSorter`] with registry-stored callbacks.
pub struct LuaDepthSorter {
    inner: Rc<RefCell<DepthSorter>>,
    callbacks: Rc<RefCell<Vec<LuaRegistryKey>>>,
}

impl LuaUserData for LuaDepthSorter {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Registers a draw callback at the given depth layer.
        /// @param callback function
        /// @param depth number
        /// @return nil
        methods.add_method("add", |lua, this, (callback, depth): (LuaFunction, f32)| {
            let key = lua.create_registry_value(callback)?;
            let mut cbs = this.callbacks.borrow_mut();
            let index = cbs.len();
            cbs.push(key);
            this.inner.borrow_mut().add(index, depth);
            Ok(())
        });

        // -- addObject --
        /// Registers a table object with a draw method at the given depth.
        /// @param obj table
        /// @return nil
        methods.add_method("addObject", |lua, this, obj: LuaTable| {
            let depth: f32 = obj.get::<_, f32>("depth").unwrap_or(0.0);
            let key = lua.create_registry_value(obj)?;
            let mut cbs = this.callbacks.borrow_mut();
            let index = cbs.len();
            cbs.push(key);
            this.inner.borrow_mut().add_object(index, depth);
            Ok(())
        });

        // -- sort --
        /// Sorts all registered callbacks by depth ascending.
        /// @return nil
        methods.add_method("sort", |_, this, ()| {
            this.inner.borrow_mut().sort();
            Ok(())
        });

        // -- flush --
        /// Calls all draw callbacks in sorted depth order, then clears.
        /// @return nil
        methods.add_method("flush", |lua, this, ()| {
            let entries: Vec<(usize, bool)> = {
                let mut sorter = this.inner.borrow_mut();
                sorter
                    .sorted_entries()
                    .iter()
                    .map(|e| (e.callback_index, e.is_object))
                    .collect()
            };

            let cbs = this.callbacks.borrow();
            for (idx, is_object) in &entries {
                if let Some(key) = cbs.get(*idx) {
                    if *is_object {
                        if let Ok(obj) = lua.registry_value::<LuaTable>(key) {
                            if let Ok(func) = obj.get::<_, LuaFunction>("drawSorted") {
                                let _ = func.call::<_, ()>(obj.clone());
                            }
                        }
                    } else if let Ok(func) = lua.registry_value::<LuaFunction>(key) {
                        let _ = func.call::<_, ()>(());
                    }
                }
            }

            this.inner.borrow_mut().clear();
            drop(cbs);
            this.callbacks.borrow_mut().clear();
            Ok(())
        });

        // -- setStable --
        /// Sets whether equal-depth entries preserve insertion order.
        /// @param stable boolean
        /// @return nil
        methods.add_method("setStable", |_, this, stable: bool| {
            this.inner.borrow_mut().set_stable(stable);
            Ok(())
        });

        // -- isStable --
        /// Returns true if stable sort mode is enabled.
        /// @return boolean
        methods.add_method("isStable", |_, this, ()| {
            Ok(this.inner.borrow().is_stable())
        });

        // -- clear --
        /// Removes all registered callbacks without calling them.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            this.callbacks.borrow_mut().clear();
            Ok(())
        });

        // -- getCount --
        /// Returns the number of registered draw entries.
        /// @return integer
        methods.add_method("getCount", |_, this, ()| {
            Ok(this.inner.borrow().get_count())
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.scene` API table with the Lua VM.
///
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param _state Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    let state = Rc::new(RefCell::new(SceneState {
        stack: SceneStack::new(),
        scene_refs: HashMap::new(),
        data_refs: HashMap::new(),
        scene_ready_pending: HashSet::new(),
        preload_callbacks: HashMap::new(),
        preloaded_names: HashSet::new(),
    }));

    // â”€â”€ Stack operations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- push --
    /// Pushes a scene table onto the stack with an optional transition and easing.
    /// @param scene table
    /// @param transition string?
    /// @param duration number?
    /// @param easing string?
    /// @param params table?
    /// @return nil
    let st = state.clone();
    tbl.set(
        "push",
        lua.create_function(
            move |lua,
                  (scene, transition, duration, easing, params): (
                LuaTable,
                Option<String>,
                Option<f32>,
                Option<String>,
                Option<LuaValue>,
            )| {
                let trans = transition
                    .as_deref()
                    .map(TransitionType::from_lua_str)
                    .unwrap_or(TransitionType::None);
                let dur = duration.unwrap_or(0.0);
                let eas = easing
                    .as_deref()
                    .map(EasingType::from_lua_str)
                    .unwrap_or_default();

                let mut s = st.borrow_mut();
                let scene_id = s.stack.next_scene_id();
                let key = lua.create_registry_value(scene)?;

                let prev_id = s.stack.push(scene_id, trans, dur, eas);
                if let Some(pid) = prev_id {
                    if let Some(prev_key) = s.scene_refs.get(&pid) {
                        let _ = call_scene_method(lua, prev_key, "pause", ());
                    }
                }

                s.scene_refs.insert(scene_id, key);
                s.scene_ready_pending.insert(scene_id);

                let params_arg = params.unwrap_or(LuaValue::Nil);
                if let Some(new_key) = s.scene_refs.get(&scene_id) {
                    let _ = call_scene_method(lua, new_key, "enter", params_arg);
                }

                Ok(())
            },
        )?,
    )?;

    // -- pop --
    /// Pops the top scene from the stack with an optional transition and easing.
    /// @param transition string?
    /// @param duration number?
    /// @param easing string?
    /// @return nil
    let st = state.clone();
    tbl.set(
        "pop",
        lua.create_function(
            move |lua, (transition, duration, easing): (Option<String>, Option<f32>, Option<String>)| {
                let trans = transition
                    .as_deref()
                    .map(TransitionType::from_lua_str)
                    .unwrap_or(TransitionType::None);
                let dur = duration.unwrap_or(0.0);
                let eas = easing.as_deref().map(EasingType::from_lua_str).unwrap_or_default();

                let mut s = st.borrow_mut();
                let was_overlay = s.stack.get_current().map(|id| s.stack.is_overlay(id)).unwrap_or(false);
                let (popped_id, revealed_id) =
                    s.stack.pop(trans, dur, eas).map_err(LuaError::RuntimeError)?;

                if let Some(popped_key) = s.scene_refs.remove(&popped_id) {
                    let _ = call_scene_method(lua, &popped_key, "leave", ());
                }

                // Only resume the revealed scene when the popped one was NOT an overlay.
                if !was_overlay {
                    if let Some(rid) = revealed_id {
                        if let Some(revealed_key) = s.scene_refs.get(&rid) {
                            let _ = call_scene_method(lua, revealed_key, "resume", ());
                        }
                    }
                }

                Ok(())
            },
        )?,
    )?;

    // -- switchTo --
    /// Replaces the top scene with a new one, calling leave and enter callbacks.
    /// @param scene table
    /// @param transition string?
    /// @param duration number?
    /// @param easing string?
    /// @param params table?
    /// @return nil
    let st = state.clone();
    tbl.set(
        "switchTo",
        lua.create_function(
            move |lua,
                  (scene, transition, duration, easing, params): (
                LuaTable,
                Option<String>,
                Option<f32>,
                Option<String>,
                Option<LuaValue>,
            )| {
                let trans = transition
                    .as_deref()
                    .map(TransitionType::from_lua_str)
                    .unwrap_or(TransitionType::None);
                let dur = duration.unwrap_or(0.0);
                let eas = easing
                    .as_deref()
                    .map(EasingType::from_lua_str)
                    .unwrap_or_default();

                let mut s = st.borrow_mut();
                let scene_id = s.stack.next_scene_id();
                let key = lua.create_registry_value(scene)?;

                let old_id = s.stack.switch_to(scene_id, trans, dur, eas);
                if let Some(oid) = old_id {
                    if let Some(old_key) = s.scene_refs.remove(&oid) {
                        let _ = call_scene_method(lua, &old_key, "leave", ());
                    }
                }

                s.scene_refs.insert(scene_id, key);
                s.scene_ready_pending.insert(scene_id);

                let params_arg = params.unwrap_or(LuaValue::Nil);
                if let Some(new_key) = s.scene_refs.get(&scene_id) {
                    let _ = call_scene_method(lua, new_key, "enter", params_arg);
                }

                Ok(())
            },
        )?,
    )?;

    // -- clear --
    /// Clears all scenes from the stack, calling leave on each.
    /// @return nil
    let st = state.clone();
    tbl.set(
        "clear",
        lua.create_function(move |lua, ()| {
            let mut s = st.borrow_mut();
            let removed = s.stack.clear();

            for id in &removed {
                if let Some(scene_key) = s.scene_refs.remove(id) {
                    let _ = call_scene_method(lua, &scene_key, "leave", ());
                }
            }

            Ok(())
        })?,
    )?;

    // -- popTo --
    /// Pops scenes until the named scene is on top, calling leave on each removed.
    /// @param name string
    /// @return boolean
    let st = state.clone();
    tbl.set(
        "popTo",
        lua.create_function(move |lua, name: String| {
            let mut s = st.borrow_mut();
            let target_id = match s.stack.pop_to(&name) {
                Some(id) => id,
                None => return Ok(false),
            };

            let popped_ids = s.stack.pop_until(target_id);

            for id in &popped_ids {
                if let Some(scene_key) = s.scene_refs.remove(id) {
                    let _ = call_scene_method(lua, &scene_key, "leave", ());
                }
            }

            if let Some(top_key) = s.stack.get_current().and_then(|id| s.scene_refs.get(&id)) {
                let _ = call_scene_method(lua, top_key, "resume", ());
            }

            Ok(true)
        })?,
    )?;

    // -- update --
    /// Updates the top scene and any active transition (legacy name; prefer `process`).
    /// Calls `scene:update(dt)` on the topmost scene only.
    /// @param dt number
    /// @return nil
    let st = state.clone();
    tbl.set(
        "update",
        lua.create_function(move |lua, dt: f32| {
            let mut s = st.borrow_mut();
            s.stack.update_transition(dt);

            if let Some(top_id) = s.stack.get_current() {
                if let Some(top_key) = s.scene_refs.get(&top_id) {
                    let _ = call_scene_method(lua, top_key, "update", dt);
                }
            }

            Ok(())
        })?,
    )?;

    // -- process --
    /// Calls `scene:ready(self)` once per scene on the first tick after enter,
    /// then `scene:process(dt)` on all active scenes (top-only unless overlays are present).
    /// @param dt number
    /// @return nil
    let st = state.clone();
    tbl.set(
        "process",
        lua.create_function(move |lua, dt: f64| {
            let mut s = st.borrow_mut();
            let active_ids: Vec<SceneId> = s.stack.get_active_ids().to_vec();
            for id in &active_ids {
                if s.scene_ready_pending.remove(id) {
                    if let Some(key) = s.scene_refs.get(id) {
                        let _ = call_scene_method(lua, key, "ready", ());
                    }
                }
                if let Some(key) = s.scene_refs.get(id) {
                    let _ = call_scene_method(lua, key, "process", dt);
                }
            }
            Ok(())
        })?,
    )?;

    // -- processPhysics --
    /// Calls `scene:process_physics(dt)` on all active scenes (fixed timestep).
    /// When overlays are present, all scenes in the stack receive the callback.
    /// @param dt number
    /// @return nil
    let st = state.clone();
    tbl.set(
        "processPhysics",
        lua.create_function(move |lua, dt: f64| {
            let s = st.borrow();
            let active_ids: Vec<SceneId> = s.stack.get_active_ids().to_vec();
            for id in &active_ids {
                if let Some(key) = s.scene_refs.get(id) {
                    let _ = call_scene_method(lua, key, "process_physics", dt);
                }
            }
            Ok(())
        })?,
    )?;

    // -- processLate --
    /// Calls `scene:process_late(dt)` on all active scenes (after process, before render).
    /// When overlays are present, all scenes in the stack receive the callback.
    /// @param dt number
    /// @return nil
    let st = state.clone();
    tbl.set(
        "processLate",
        lua.create_function(move |lua, dt: f64| {
            let s = st.borrow();
            let active_ids: Vec<SceneId> = s.stack.get_active_ids().to_vec();
            for id in &active_ids {
                if let Some(key) = s.scene_refs.get(id) {
                    let _ = call_scene_method(lua, key, "process_late", dt);
                }
            }
            Ok(())
        })?,
    )?;

    // -- draw --
    /// Draws all scenes in the stack from bottom to top (legacy name; prefer `render`).
    /// Calls `scene:draw()` on every scene in the stack.
    /// @return nil
    let st = state.clone();
    tbl.set(
        "draw",
        lua.create_function(move |lua, ()| {
            let s = st.borrow();
            let all_ids: Vec<SceneId> = s.stack.get_all().to_vec();

            for id in &all_ids {
                if let Some(scene_key) = s.scene_refs.get(id) {
                    let _ = call_scene_method(lua, scene_key, "draw", ());
                }
            }

            Ok(())
        })?,
    )?;

    // -- render --
    /// Draws all scenes in the stack from bottom to top.
    /// Calls `scene:render(self)` on every scene. Preferred over `draw`.
    /// @return nil
    let st = state.clone();
    tbl.set(
        "render",
        lua.create_function(move |lua, ()| {
            let s = st.borrow();
            let all_ids: Vec<SceneId> = s.stack.get_all().to_vec();

            for id in &all_ids {
                if let Some(scene_key) = s.scene_refs.get(id) {
                    let _ = call_scene_method(lua, scene_key, "render", ());
                }
            }

            Ok(())
        })?,
    )?;

    // -- renderUi --
    /// Draws UI overlay for all scenes in the stack from bottom to top.
    /// Calls `scene:render_ui(self)` on every scene in the stack.
    /// @return nil
    let st = state.clone();
    tbl.set(
        "renderUi",
        lua.create_function(move |lua, ()| {
            let s = st.borrow();
            let all_ids: Vec<SceneId> = s.stack.get_all().to_vec();

            for id in &all_ids {
                if let Some(scene_key) = s.scene_refs.get(id) {
                    let _ = call_scene_method(lua, scene_key, "render_ui", ());
                }
            }

            Ok(())
        })?,
    )?;

    // â”€â”€ Stack query â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- getStackSize --
    /// Returns the number of scenes on the stack.
    /// @return integer
    let st = state.clone();
    tbl.set(
        "getStackSize",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_stack_size()))?,
    )?;

    // -- depth --
    /// Returns the number of scenes on the stack.
    /// Alias for `getStackSize`; provided for ergonomic use in game scripts.
    /// @return integer
    let st = state.clone();
    tbl.set(
        "depth",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_stack_size()))?,
    )?;

    // -- isEmpty --
    /// Returns true if the scene stack is empty.
    /// @return boolean
    let st = state.clone();
    tbl.set(
        "isEmpty",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.is_empty()))?,
    )?;

    // -- getCurrent --
    /// Returns the current top scene table, or nil if the stack is empty.
    /// @return table?
    let st = state.clone();
    tbl.set(
        "getCurrent",
        lua.create_function(move |lua, ()| {
            let s = st.borrow();
            if let Some(top_id) = s.stack.get_current() {
                if let Some(key) = s.scene_refs.get(&top_id) {
                    let table: LuaTable = lua.registry_value(key)?;
                    return Ok(LuaValue::Table(table));
                }
            }
            Ok(LuaValue::Nil)
        })?,
    )?;

    // â”€â”€ Transitions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- isTransitioning --
    /// Returns true if a scene transition is currently active.
    /// @return boolean
    let st = state.clone();
    tbl.set(
        "isTransitioning",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.is_transitioning()))?,
    )?;

    // -- getTransitionProgress --
    /// Returns the transition progress from 0.0 to 1.0.
    /// @return number
    let st = state.clone();
    tbl.set(
        "getTransitionProgress",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_transition_progress()))?,
    )?;

    // â”€â”€ Registry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- registerScene --
    /// Registers a scene table by name for later retrieval.
    /// @param name string
    /// @param scene table
    /// @return nil
    let st = state.clone();
    tbl.set(
        "registerScene",
        lua.create_function(move |lua, (name, scene): (String, LuaTable)| {
            let mut s = st.borrow_mut();
            let scene_id = s.stack.next_scene_id();
            let key = lua.create_registry_value(scene)?;
            s.stack.register_scene(name, scene_id);
            s.scene_refs.insert(scene_id, key);
            Ok(())
        })?,
    )?;

    // -- getRegistered --
    /// Returns a registered scene table by name, or nil if not found.
    /// @param name string
    /// @return table?
    let st = state.clone();
    tbl.set(
        "getRegistered",
        lua.create_function(move |lua, name: String| {
            let s = st.borrow();
            if let Some(scene_id) = s.stack.get_registered(&name) {
                if let Some(key) = s.scene_refs.get(&scene_id) {
                    let table: LuaTable = lua.registry_value(key)?;
                    return Ok(LuaValue::Table(table));
                }
            }
            Ok(LuaValue::Nil)
        })?,
    )?;

    // -- hasRegistered --
    /// Returns true if a scene is registered under the given name.
    /// @param name string
    /// @return boolean
    let st = state.clone();
    tbl.set(
        "hasRegistered",
        lua.create_function(move |_, name: String| Ok(st.borrow().stack.has_registered(&name)))?,
    )?;

    // -- unregisterScene --
    /// Removes a scene from the registry by name.
    /// @param name string
    /// @return nil
    let st = state.clone();
    tbl.set(
        "unregisterScene",
        lua.create_function(move |_, name: String| {
            st.borrow_mut().stack.unregister_scene(&name);
            Ok(())
        })?,
    )?;

    // -- getRegisteredNames --
    /// Returns a list of all registered scene names.
    /// @return table
    let st = state.clone();
    tbl.set(
        "getRegisteredNames",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_registered_names()))?,
    )?;

    // â”€â”€ Data store â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- setData --
    /// Stores a value in the inter-scene data store under the given key.
    /// @param key string
    /// @param value table
    /// @return nil
    let st = state.clone();
    tbl.set(
        "setData",
        lua.create_function(move |lua, (key, value): (String, LuaValue)| {
            let mut s = st.borrow_mut();
            let value_id = s.stack.next_scene_id();
            let reg_key = lua.create_registry_value(value)?;
            s.stack.set_data(key.clone(), value_id);
            s.data_refs.insert(key, reg_key);
            Ok(())
        })?,
    )?;

    // -- getData --
    /// Returns a value from the inter-scene data store, or nil if not found.
    /// @param key string
    /// @return table?
    let st = state.clone();
    tbl.set(
        "getData",
        lua.create_function(move |lua, key: String| {
            let s = st.borrow();
            if let Some(reg_key) = s.data_refs.get(&key) {
                let value: LuaValue = lua.registry_value(reg_key)?;
                return Ok(value);
            }
            Ok(LuaValue::Nil)
        })?,
    )?;

    // -- hasData --
    /// Returns true if the given key exists in the data store.
    /// @param key string
    /// @return boolean
    let st = state.clone();
    tbl.set(
        "hasData",
        lua.create_function(move |_, key: String| Ok(st.borrow().stack.has_data(&key)))?,
    )?;

    // -- removeData --
    /// Removes a value from the inter-scene data store by key.
    /// @param key string
    /// @return nil
    let st = state.clone();
    tbl.set(
        "removeData",
        lua.create_function(move |_, key: String| {
            let mut s = st.borrow_mut();
            s.stack.remove_data(&key);
            s.data_refs.remove(&key);
            Ok(())
        })?,
    )?;

    // â”€â”€ Factory â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- newDepthSorter --
    /// Creates a new DepthSorter for z-ordered draw batching.
    /// @return DepthSorter
    tbl.set(
        "newDepthSorter",
        lua.create_function(|_, ()| {
            Ok(LuaDepthSorter {
                inner: Rc::new(RefCell::new(DepthSorter::new())),
                callbacks: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;

    // â”€â”€ Scene helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // `lurek.scene.new(def)` â€” creates a scene instance directly from a methods table.
    // Implemented as a Rust closure using mlua set_metatable instead of setmetatable,
    // keeping no embedded Lua strings in the api file.
    /// Creates a scene instance directly from a methods table.
    /// @param def table?
    /// @return table
    tbl.set(
        "new",
        lua.create_function(|lua, def: Option<LuaTable>| {
            let def = match def {
                Some(t) => t,
                None => lua.create_table()?,
            };
            def.set("__index", def.clone())?;
            let instance: LuaTable = lua.create_table()?;
            instance.set_metatable(Some(def));
            Ok(instance)
        })?,
    )?;

    // `lurek.scene.newScene(def)` â€” alias for `new`.
    /// Alias for `lurek.scene.new`. Creates a scene instance from a methods table.
    /// @param def table?
    /// @return table
    tbl.set(
        "newScene",
        lua.create_function(|lua, def: Option<LuaTable>| {
            let def = match def {
                Some(t) => t,
                None => lua.create_table()?,
            };
            def.set("__index", def.clone())?;
            let instance: LuaTable = lua.create_table()?;
            instance.set_metatable(Some(def));
            Ok(instance)
        })?,
    )?;

    // `lurek.scene.define(def)` â€” creates a reusable scene class (callable constructor).
    // The definition table is stored in the Lua registry so the returned constructor
    // closure can access it across multiple calls without holding a borrow.
    /// Creates a reusable scene class â€” returns a zero-argument constructor function.
    /// @param def table?
    /// @return function
    tbl.set(
        "define",
        lua.create_function(|lua, def: Option<LuaTable>| {
            let def = match def {
                Some(t) => t,
                None => lua.create_table()?,
            };
            def.set("__index", def.clone())?;
            let key = lua.create_registry_value(def)?;
            let ctor = lua.create_function(move |inner_lua, ()| {
                let def: LuaTable = inner_lua.registry_value(&key)?;
                let instance: LuaTable = inner_lua.create_table()?;
                instance.set_metatable(Some(def));
                Ok(instance)
            })?;
            Ok(ctor)
        })?,
    )?;

    // â”€â”€ Transition (eased) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- getTransitionProgressEased --
    /// Returns the easing-adjusted transition progress from 0.0 to 1.0.
    /// @return number
    let st = state.clone();
    tbl.set(
        "getTransitionProgressEased",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_transition_progress_eased()))?,
    )?;

    // â”€â”€ Overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- pushOverlay --
    /// Pushes a scene as a non-pausing overlay over the current top scene.
    /// The background scene continues to receive process and render calls.
    /// @param scene table
    /// @param transition string?
    /// @param duration number?
    /// @param easing string?
    /// @param params table?
    /// @return nil
    let st = state.clone();
    tbl.set(
        "pushOverlay",
        lua.create_function(
            move |lua,
                  (scene, transition, duration, easing, params): (
                LuaTable,
                Option<String>,
                Option<f32>,
                Option<String>,
                Option<LuaValue>,
            )| {
                let trans = transition
                    .as_deref()
                    .map(TransitionType::from_lua_str)
                    .unwrap_or(TransitionType::None);
                let dur = duration.unwrap_or(0.0);
                let eas = easing
                    .as_deref()
                    .map(EasingType::from_lua_str)
                    .unwrap_or_default();

                let mut s = st.borrow_mut();
                let scene_id = s.stack.next_scene_id();
                let key = lua.create_registry_value(scene)?;

                // push_overlay does NOT pause the background scene.
                let _prev = s.stack.push_overlay(scene_id, trans, dur, eas);

                s.scene_refs.insert(scene_id, key);
                s.scene_ready_pending.insert(scene_id);

                let params_arg = params.unwrap_or(LuaValue::Nil);
                if let Some(new_key) = s.scene_refs.get(&scene_id) {
                    let _ = call_scene_method(lua, new_key, "enter", params_arg);
                }

                Ok(())
            },
        )?,
    )?;

    // -- isOverlay --
    /// Returns true if the current top scene was pushed as an overlay.
    /// @return boolean
    let st = state.clone();
    tbl.set(
        "isOverlay",
        lua.create_function(move |_, ()| {
            let s = st.borrow();
            let is_ov = s
                .stack
                .get_current()
                .map(|id| s.stack.is_overlay(id))
                .unwrap_or(false);
            Ok(is_ov)
        })?,
    )?;

    // -- getActiveScenes --
    /// Returns a table array of all active scene tables.
    /// When overlays are present, all scenes in the stack are included.
    /// @return table
    let st = state.clone();
    tbl.set(
        "getActiveScenes",
        lua.create_function(move |lua, ()| {
            let s = st.borrow();
            let active_ids: Vec<SceneId> = s.stack.get_active_ids().to_vec();
            let result = lua.create_table()?;
            for (i, id) in active_ids.iter().enumerate() {
                if let Some(key) = s.scene_refs.get(id) {
                    let table: LuaTable = lua.registry_value(key)?;
                    result.raw_set(i + 1, table)?;
                }
            }
            Ok(result)
        })?,
    )?;

    // â”€â”€ Preload â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- preload --
    /// Registers a loader function for a named scene. The loader is called
    /// once when `pushPreloaded` is first invoked for that name, allowing
    /// assets to be loaded before the scene is pushed.
    /// @param name string
    /// @param loader function
    /// @return nil
    let st = state.clone();
    tbl.set(
        "preload",
        lua.create_function(move |lua, (name, loader): (String, LuaFunction)| {
            let mut s = st.borrow_mut();
            let key = lua.create_registry_value(loader)?;
            s.preload_callbacks.insert(name, key);
            Ok(())
        })?,
    )?;

    // -- isPreloaded --
    /// Returns true if the named scene has been preloaded.
    /// @param name string
    /// @return boolean
    let st = state.clone();
    tbl.set(
        "isPreloaded",
        lua.create_function(move |_, name: String| {
            Ok(st.borrow().preloaded_names.contains(&name))
        })?,
    )?;

    // -- pushPreloaded --
    /// Pushes a registered scene by name, running its loader if not yet preloaded.
    /// @param name string
    /// @param transition string?
    /// @param duration number?
    /// @param easing string?
    /// @param params table?
    /// @return nil
    let st = state.clone();
    tbl.set(
        "pushPreloaded",
        lua.create_function(
            move |lua,
                  (name, transition, duration, easing, params): (
                String,
                Option<String>,
                Option<f32>,
                Option<String>,
                Option<LuaValue>,
            )| {
                let trans = transition
                    .as_deref()
                    .map(TransitionType::from_lua_str)
                    .unwrap_or(TransitionType::None);
                let dur = duration.unwrap_or(0.0);
                let eas = easing
                    .as_deref()
                    .map(EasingType::from_lua_str)
                    .unwrap_or_default();
                let params_val = params.unwrap_or(LuaValue::Nil);

                // Retrieve the loader (if any) with an immutable borrow, then drop
                // the borrow BEFORE calling it so that the loader can re-enter the
                // scene API (e.g. call lurek.scene.registerScene) without panicking.
                let loader_opt: Option<LuaFunction> = {
                    let s = st.borrow();
                    if !s.preloaded_names.contains(&name) {
                        if let Some(key) = s.preload_callbacks.get(&name) {
                            lua.registry_value::<LuaFunction>(key).ok()
                        } else {
                            None
                        }
                    } else {
                        None
                    }
                }; // immutable borrow dropped

                // Mark the scene as preloaded (separate mutable borrow).
                if loader_opt.is_some() {
                    st.borrow_mut().preloaded_names.insert(name.clone());
                }

                // Call the loader without holding the state borrow.
                if let Some(loader) = &loader_opt {
                    let _ = loader.call::<_, ()>(());
                }

                let mut s = st.borrow_mut();

                // Push from the named registry.
                if let Some(scene_id) = s.stack.get_registered(&name) {
                    let prev_id = s.stack.push(scene_id, trans, dur, eas);
                    if let Some(pid) = prev_id {
                        if let Some(prev_key) = s.scene_refs.get(&pid) {
                            let _ = call_scene_method(lua, prev_key, "pause", ());
                        }
                    }
                    s.scene_ready_pending.insert(scene_id);
                    if let Some(key) = s.scene_refs.get(&scene_id) {
                        let _ = call_scene_method(lua, key, "enter", params_val);
                    }
                }

                Ok(())
            },
        )?,
    )?;

    /// Namespace containing the scene API module.
    /// Provides scene lifecycle flow execution and state.
    lurek.set("scene", tbl.clone())?;

    // -- getTransitionTypes --
    /// Returns a table listing all supported transition type strings.
    /// @return table
    tbl.set(
        "getTransitionTypes",
        lua.create_function(|lua, ()| {
            let tbl = lua.create_table()?;
            let types = [
                "none",
                "fade",
                "left",
                "right",
                "up",
                "down",
                "wipe",
                "iris",
                "zoom",
                "crossfade",
            ];
            for (i, t) in types.iter().enumerate() {
                tbl.set(i + 1, *t)?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- serialize --
    /// Returns a snapshot of the scene stack as a Lua table: { stack=[name...], data={key=val} }.
    /// @return table
    let st = state.clone();
    tbl.set(
        "serializeScene",
        lua.create_function(move |lua, ()| {
            let s = st.borrow();
            let snap = lua.create_table()?;

            // Scene name stack â€” build idâ†’name reverse map from registry
            let stack_names = lua.create_table()?;
            let mut id_to_name: std::collections::HashMap<crate::scene::stack::SceneId, String> =
                std::collections::HashMap::new();
            for name in s.stack.get_registered_names() {
                if let Some(id) = s.stack.get_registered(&name) {
                    id_to_name.insert(id, name);
                }
            }
            for (i, &id) in s.stack.get_all().iter().enumerate() {
                if let Some(name) = id_to_name.get(&id) {
                    stack_names.set(i + 1, name.as_str())?;
                }
            }
            snap.set("stack", stack_names)?;

            // Data refs (scene user data)
            let data_snap = lua.create_table()?;
            for (key, reg_key) in &s.data_refs {
                if let Ok(val) = lua.registry_value::<LuaValue>(reg_key) {
                    data_snap.set(key.as_str(), val)?;
                }
            }
            snap.set("data", data_snap)?;

            Ok(snap)
        })?,
    )?;

    // -- deserializeScene --
    /// Restores scene data_refs from a snapshot produced by serializeScene().
    /// Only data keys are restored; the scene stack itself is not manipulated.
    /// @param snapshot table
    /// @return nil
    let st = state.clone();
    tbl.set(
        "deserializeScene",
        lua.create_function(move |lua, snapshot: LuaTable| {
            let mut s = st.borrow_mut();

            // Restore data_refs entries
            if let Ok(data) = snapshot.get::<_, LuaTable>("data") {
                for pair in data.pairs::<String, LuaValue>() {
                    let (k, v) = pair?;
                    let reg_key = lua.create_registry_value(v)?;
                    // Remove old entry if present
                    if let Some(old) = s.data_refs.remove(&k) {
                        lua.remove_registry_value(old)?;
                    }
                    s.data_refs.insert(k, reg_key);
                }
            }

            Ok(())
        })?,
    )?;

    // â”€â”€ Built-in Transition Library â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // -- transitions --
    /// Pre-built named transition factory functions.  Each function accepts optional
    /// configuration arguments and returns a table with `type` and `duration` fields
    /// compatible with the existing push/switchTo/pop transition parameters.
    ///
    /// Example:
    ///   local cfg = lurek.scene.transitions.fade(0.5)
    ///   lurek.scene.push(myScene, cfg.type, cfg.duration)
    let trans_tbl = lua.create_table()?;

    // transitions.fade(duration?) â†’ {type="fade", duration=0.5}
    /// Returns a fade cross-dissolve transition config table.
    /// @return table|nil
    /// @param duration number?  â€” default 0.5
    /// table  â€” { type : string, duration : number }
    trans_tbl.set(
        "fade",
        lua.create_function(|lua, duration: Option<f32>| {
            let t = lua.create_table()?;
            t.set("type", "fade")?;
            t.set("duration", duration.unwrap_or(0.5))?;
            Ok(t)
        })?,
    )?;

    // transitions.slide(direction?, duration?) â†’ {type=direction, duration=0.4}
    /// Returns a directional slide transition config table.
    /// @return table|nil
    /// @param direction string?  â€” "left" | "right" | "up" | "down" (default "left")
    /// @param duration number?  â€” default 0.4
    /// table  â€” { type : string, duration : number }
    trans_tbl.set(
        "slide",
        lua.create_function(
            |lua, (direction, duration): (Option<String>, Option<f32>)| {
                let t = lua.create_table()?;
                let dir = direction.as_deref().unwrap_or("left").to_string();
                t.set("type", dir)?;
                t.set("duration", duration.unwrap_or(0.4))?;
                Ok(t)
            },
        )?,
    )?;

    // transitions.wipe(duration?) â†’ {type="wipe", duration=0.5}
    /// Returns a wipe/curtain transition config table.
    /// @return table|nil
    /// @param duration number?  â€” default 0.5
    /// table  â€” { type : string, duration : number }
    trans_tbl.set(
        "wipe",
        lua.create_function(|lua, duration: Option<f32>| {
            let t = lua.create_table()?;
            t.set("type", "wipe")?;
            t.set("duration", duration.unwrap_or(0.5))?;
            Ok(t)
        })?,
    )?;

    // transitions.iris(duration?) â†’ {type="iris", duration=0.6}
    /// Returns an iris in/out (circular reveal) transition config table.
    /// @return table|nil
    /// @param duration number?  â€” default 0.6
    /// table  â€” { type : string, duration : number }
    trans_tbl.set(
        "iris",
        lua.create_function(|lua, duration: Option<f32>| {
            let t = lua.create_table()?;
            t.set("type", "iris")?;
            t.set("duration", duration.unwrap_or(0.6))?;
            Ok(t)
        })?,
    )?;

    /// Built-in transition presets table with `fade`, `slide`, and `iris` entries.
    tbl.set("transitions", trans_tbl)?;

    Ok(())
}
