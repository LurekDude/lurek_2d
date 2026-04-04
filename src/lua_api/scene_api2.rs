//! Registers the `luna.scene.*` scene stack, registry, data store, and depth-sorter API.
//!
//! The scene stack manages a LIFO stack of Lua scene tables with optional
//! visual transitions. Scene tables are stored via `mlua::RegistryKey` and
//! identified by `SceneId`. Inter-scene data is stored similarly.
//!
//! The `DepthSorter` UserData batches draw callbacks by depth for ordered
//! compositing each frame.
#![allow(unused_doc_comments)]

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use mlua::prelude::*;

use crate::scene::depth_sorter::DepthSorter;
use crate::scene::stack::{SceneId, SceneStack};
use crate::scene::transition::TransitionType;

use super::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// Internal state
// ---------------------------------------------------------------------------

/// All scene-related state managed by the Lua API layer.
struct SceneState {
    /// The LIFO scene stack with registry and transition support.
    stack: SceneStack,
    /// Maps each `SceneId` to its Lua table stored in the registry.
    scene_refs: HashMap<SceneId, LuaRegistryKey>,
    /// Maps string keys to Lua values stored in the registry (inter-scene data).
    data_refs: HashMap<String, LuaRegistryKey>,
}

// ---------------------------------------------------------------------------
// DepthSorter UserData wrapper
// ---------------------------------------------------------------------------

/// Lua wrapper around a [`DepthSorter`] with registry-stored callbacks.
#[derive(Clone)]
struct LuaDepthSorter {
    /// The underlying depth sorter.
    inner: Rc<RefCell<DepthSorter>>,
    /// Registry keys for stored callbacks/objects, indexed by `callback_index`.
    callbacks: Rc<RefCell<Vec<LuaRegistryKey>>>,
}

impl LunaType for LuaDepthSorter {
    const TYPE_NAME: &'static str = "DepthSorter";
    const TYPE_HIERARCHY: &'static [&'static str] = &["DepthSorter", "Object"];
}

impl LuaUserData for LuaDepthSorter {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Registers a draw callback at the given depth layer. Higher `depth` values draw in front.
        /// @param callback : function
        /// @param depth : number
        ///
        /// # Parameters
        /// - `callback` — `function`: Draw callback `function()` called when flushing this layer.
        /// - `depth` — `number`: Depth value determining draw order (lower = drawn first).
        methods.add_method("add", |lua, this, (callback, depth): (LuaFunction, f32)| {
            let key = lua.create_registry_value(callback)?;
            let mut cbs = this.callbacks.borrow_mut();
            let index = cbs.len();
            cbs.push(key);
            this.inner.borrow_mut().add(index, depth);
            Ok(())
        });

        /// Registers a table object with a `draw` method at the given depth.
        /// @param obj : table
        ///
        /// # Parameters
        /// - `obj` — `table`: Object with a `draw()` method. Uses `obj.depth` if no explicit depth is provided.
        methods.add_method("addObject", |lua, this, obj: LuaTable| {
            let depth: f32 = obj.get::<_, f32>("depth").unwrap_or(0.0);
            let key = lua.create_registry_value(obj)?;
            let mut cbs = this.callbacks.borrow_mut();
            let index = cbs.len();
            cbs.push(key);
            this.inner.borrow_mut().add_object(index, depth);
            Ok(())
        });

        /// Sorts all registered callbacks and objects by their depth values (ascending).
        methods.add_method("sort", |_, this, ()| {
            this.inner.borrow_mut().sort();
            Ok(())
        });

        /// Calls all registered draw callbacks and object `draw()` methods in sorted depth order, then clears the list.
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

            // Clear after flushing
            this.inner.borrow_mut().clear();
            drop(cbs);
            this.callbacks.borrow_mut().clear();
            Ok(())
        });

        /// Removes all registered callbacks and objects without calling them.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            this.callbacks.borrow_mut().clear();
            Ok(())
        });

        /// Returns the number of callbacks and objects currently registered.
        /// @return any
        ///
        /// # Returns
        /// `integer` — number of registered draw entries.
        methods.add_method("getCount", |_, this, ()| {
            Ok(this.inner.borrow().get_count())
        });
    }
}

// ---------------------------------------------------------------------------
// Helper: call an optional method on a scene table stored in the registry
// ---------------------------------------------------------------------------

/// Safely call an optional method on a scene table stored in the Lua registry.
///
/// If the table has the named method, calls it with `(self, args...)`.
/// If the method does not exist, silently succeeds.
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

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.scene` table with scene stack, registry, data store,
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
/// and depth-sorter factory functions.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let scene_table = lua.create_table()?;

    let state = Rc::new(RefCell::new(SceneState {
        stack: SceneStack::new(),
        scene_refs: HashMap::new(),
        data_refs: HashMap::new(),
    }));

    // =======================================================================
    // Scene stack operations
    // =======================================================================

    // luna.scene.push(scene [, transition [, duration]])
    {
        let st = state.clone();
        /// Adds an item.
        ///
        /// @param scene : table
        /// @param transition : string?
        /// @param duration : number?
        scene_table.set(
            "push",
            lua.create_function(
                move |lua, (scene, transition, duration): (LuaTable, Option<String>, Option<f32>)| {
                    let trans = transition
                        .as_deref()
                        .map(TransitionType::from_lua_str)
                        .unwrap_or(TransitionType::None);
                    let dur = duration.unwrap_or(0.0);

                    let mut s = st.borrow_mut();
                    let scene_id = s.stack.next_scene_id();
                    let key = lua.create_registry_value(scene.clone())?;

                    // Call pause() on previous top scene
                    let prev_id = s.stack.push(scene_id, trans, dur);
                    if let Some(pid) = prev_id {
                        if let Some(prev_key) = s.scene_refs.get(&pid) {
                            let _ = call_scene_method(lua, prev_key, "pause", ());
                        }
                    }

                    s.scene_refs.insert(scene_id, key);

                    // Call enter() on the new scene
                    if let Some(new_key) = s.scene_refs.get(&scene_id) {
                        let _ = call_scene_method(lua, new_key, "enter", ());
                    }

                    Ok(())
                },
            )?,
        )?;
    }

    // luna.scene.pop([transition [, duration]])
    {
        let st = state.clone();
        /// Removes an item.
        ///
        /// @param transition : string?
        /// @param duration : number?
        scene_table.set(
            "pop",
            lua.create_function(
                move |lua, (transition, duration): (Option<String>, Option<f32>)| {
                    let trans = transition
                        .as_deref()
                        .map(TransitionType::from_lua_str)
                        .unwrap_or(TransitionType::None);
                    let dur = duration.unwrap_or(0.0);

                    let mut s = st.borrow_mut();
                    let (popped_id, revealed_id) =
                        s.stack.pop(trans, dur).map_err(LuaError::RuntimeError)?;

                    // Call leave() on the popped scene
                    if let Some(popped_key) = s.scene_refs.remove(&popped_id) {
                        let _ = call_scene_method(lua, &popped_key, "leave", ());
                    }

                    // Call resume() on the revealed scene
                    if let Some(rid) = revealed_id {
                        if let Some(revealed_key) = s.scene_refs.get(&rid) {
                            let _ = call_scene_method(lua, revealed_key, "resume", ());
                        }
                    }

                    Ok(())
                },
            )?,
        )?;
    }

    // luna.scene.switchTo(scene [, transition [, duration]])
    {
        let st = state.clone();
        /// Switch to.
        ///
        /// @param scene : table
        /// @param transition : string?
        /// @param duration : number?
        scene_table.set(
            "switchTo",
            lua.create_function(
                move |lua, (scene, transition, duration): (LuaTable, Option<String>, Option<f32>)| {
                    let trans = transition
                        .as_deref()
                        .map(TransitionType::from_lua_str)
                        .unwrap_or(TransitionType::None);
                    let dur = duration.unwrap_or(0.0);

                    let mut s = st.borrow_mut();
                    let scene_id = s.stack.next_scene_id();
                    let key = lua.create_registry_value(scene.clone())?;

                    // Call leave() on old top scene
                    let old_id = s.stack.switch_to(scene_id, trans, dur);
                    if let Some(oid) = old_id {
                        if let Some(old_key) = s.scene_refs.remove(&oid) {
                            let _ = call_scene_method(lua, &old_key, "leave", ());
                        }
                    }

                    s.scene_refs.insert(scene_id, key);

                    // Call enter() on new scene
                    if let Some(new_key) = s.scene_refs.get(&scene_id) {
                        let _ = call_scene_method(lua, new_key, "enter", ());
                    }

                    Ok(())
                },
            )?,
        )?;
    }

    // luna.scene.clear()
    {
        let st = state.clone();
        /// Clears the state.
        ///
        scene_table.set(
            "clear",
            lua.create_function(move |lua, ()| {
                let mut s = st.borrow_mut();
                let removed = s.stack.clear();

                // Call leave() on each removed scene
                for id in &removed {
                    if let Some(scene_key) = s.scene_refs.remove(id) {
                        let _ = call_scene_method(lua, &scene_key, "leave", ());
                    }
                }

                Ok(())
            })?,
        )?;
    }

    // luna.scene.popTo(name) → bool
    {
        let st = state.clone();
        /// Removes to.
        ///
        /// @param name : string
        /// @return boolean
        scene_table.set(
            "popTo",
            lua.create_function(move |lua, name: String| {
                let mut s = st.borrow_mut();
                let target_id = match s.stack.pop_to(&name) {
                    Some(id) => id,
                    None => return Ok(false),
                };

                let popped_ids = s.stack.pop_until(target_id);

                // Call leave() on each popped scene
                for id in &popped_ids {
                    if let Some(scene_key) = s.scene_refs.remove(id) {
                        let _ = call_scene_method(lua, &scene_key, "leave", ());
                    }
                }

                // Call resume() on the now-top scene
                if let Some(top_key) = s.stack.get_current().and_then(|id| s.scene_refs.get(&id)) {
                    let _ = call_scene_method(lua, top_key, "resume", ());
                }

                Ok(true)
            })?,
        )?;
    }

    // luna.scene.update(dt)
    {
        let st = state.clone();
        /// Update.
        ///
        /// @param dt : number
        scene_table.set(
            "update",
            lua.create_function(move |lua, dt: f32| {
                let mut s = st.borrow_mut();
                s.stack.update_transition(dt);

                // Call update(self, dt) on top scene only
                if let Some(top_id) = s.stack.get_current() {
                    if let Some(top_key) = s.scene_refs.get(&top_id) {
                        let _ = call_scene_method(lua, top_key, "update", dt);
                    }
                }

                Ok(())
            })?,
        )?;
    }

    // luna.scene.draw()
    {
        let st = state.clone();
        /// Draw.
        ///
        scene_table.set(
            "draw",
            lua.create_function(move |lua, ()| {
                let s = st.borrow();
                let all_ids: Vec<SceneId> = s.stack.get_all().to_vec();

                // Call draw(self) on all scenes bottom-to-top
                for id in &all_ids {
                    if let Some(scene_key) = s.scene_refs.get(id) {
                        let _ = call_scene_method(lua, scene_key, "draw", ());
                    }
                }

                Ok(())
            })?,
        )?;
    }

    // =======================================================================
    // Stack query
    // =======================================================================

    // luna.scene.getStackSize() → number
    {
        let st = state.clone();
        /// Returns the stack size.
        ///
        /// @return any
        scene_table.set(
            "getStackSize",
            lua.create_function(move |_, ()| Ok(st.borrow().stack.get_stack_size()))?,
        )?;
    }

    // luna.scene.isEmpty() → bool
    {
        let st = state.clone();
        /// Returns true if empty.
        ///
        /// @return boolean
        scene_table.set(
            "isEmpty",
            lua.create_function(move |_, ()| Ok(st.borrow().stack.is_empty()))?,
        )?;
    }

    // luna.scene.getCurrent() → table|nil
    {
        let st = state.clone();
        /// Returns the current.
        ///
        /// @return any
        scene_table.set(
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
    }

    // =======================================================================
    // Transitions
    // =======================================================================

    // luna.scene.isTransitioning() → bool
    {
        let st = state.clone();
        /// Returns true if transitioning.
        ///
        /// @return any
        scene_table.set(
            "isTransitioning",
            lua.create_function(move |_, ()| Ok(st.borrow().stack.is_transitioning()))?,
        )?;
    }

    // luna.scene.getTransitionProgress() → number [0,1]
    {
        let st = state.clone();
        /// Returns the transition progress.
        ///
        /// @return any
        scene_table.set(
            "getTransitionProgress",
            lua.create_function(move |_, ()| Ok(st.borrow().stack.get_transition_progress()))?,
        )?;
    }

    // =======================================================================
    // Registry
    // =======================================================================

    // luna.scene.registerScene(name, scene)
    {
        let st = state.clone();
        /// Register scene.
        ///
        /// @param name : string
        /// @param scene : table
        scene_table.set(
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
    }

    // luna.scene.getRegistered(name) → table|nil
    {
        let st = state.clone();
        /// Returns the registered.
        ///
        /// @param name : string
        /// @return any
        scene_table.set(
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
    }

    // luna.scene.hasRegistered(name) → bool
    {
        let st = state.clone();
        /// Returns true if registered.
        ///
        /// @param name : string
        /// @return any
        scene_table.set(
            "hasRegistered",
            lua.create_function(move |_, name: String| {
                Ok(st.borrow().stack.has_registered(&name))
            })?,
        )?;
    }

    // luna.scene.unregisterScene(name)
    {
        let st = state.clone();
        /// Unregister scene.
        ///
        /// @param name : string
        scene_table.set(
            "unregisterScene",
            lua.create_function(move |_, name: String| {
                st.borrow_mut().stack.unregister_scene(&name);
                Ok(())
            })?,
        )?;
    }

    // luna.scene.getRegisteredNames() → {string}
    {
        let st = state.clone();
        /// Returns the registered names.
        ///
        /// @return any
        scene_table.set(
            "getRegisteredNames",
            lua.create_function(move |_, ()| Ok(st.borrow().stack.get_registered_names()))?,
        )?;
    }

    // =======================================================================
    // Data store
    // =======================================================================

    // luna.scene.setData(key, value)
    {
        let st = state.clone();
        /// Sets the data.
        ///
        /// @param key : string
        /// @param value : any
        scene_table.set(
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
    }

    // luna.scene.getData(key) → any|nil
    {
        let st = state.clone();
        /// Returns the data.
        ///
        /// @param key : string
        /// @return any
        scene_table.set(
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
    }

    // luna.scene.hasData(key) → bool
    {
        let st = state.clone();
        /// Returns true if data.
        ///
        /// @param key : string
        /// @return any
        scene_table.set(
            "hasData",
            lua.create_function(move |_, key: String| Ok(st.borrow().stack.has_data(&key)))?,
        )?;
    }

    // luna.scene.removeData(key)
    {
        let st = state.clone();
        /// Removes data.
        ///
        /// @param key : string
        scene_table.set(
            "removeData",
            lua.create_function(move |_, key: String| {
                let mut s = st.borrow_mut();
                s.stack.remove_data(&key);
                s.data_refs.remove(&key);
                Ok(())
            })?,
        )?;
    }

    // =======================================================================
    // Factory
    // =======================================================================

    // luna.scene.newDepthSorter() → DepthSorter
    /// New depth sorter.
    ///
    /// @return any
    scene_table.set(
        "newDepthSorter",
        lua.create_function(|_, ()| {
            Ok(LuaDepthSorter {
                inner: Rc::new(RefCell::new(DepthSorter::new())),
                callbacks: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;

    /// Scene on this DepthSorter.
    ///
    /// # Returns
    /// The result.
    luna.set("scene", scene_table)?;
    Ok(())
}
