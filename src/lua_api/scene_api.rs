//! `lurek.scene` — Scene stack management, transitions, registry, and depth-sorted rendering.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;

use crate::scene::depth_sorter::DepthSorter;
use crate::scene::stack::{SceneId, SceneStack};
use crate::scene::transition::TransitionType;

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
        /// @param callback : function
        /// @param depth : number
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
        /// @param obj : table
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
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    let state = Rc::new(RefCell::new(SceneState {
        stack: SceneStack::new(),
        scene_refs: HashMap::new(),
        data_refs: HashMap::new(),
        scene_ready_pending: HashSet::new(),
    }));

    // ── Stack operations ─────────────────────────────────────────────────

    // -- push --
    /// Pushes a scene table onto the stack with an optional transition.
    /// @param scene : table
    /// @param transition : string?
    /// @param duration : number?
    /// @param params : table?
    /// @return nil
    let st = state.clone();
    tbl.set(
        "push",
        lua.create_function(
            move |lua,
                  (scene, transition, duration, params): (
                LuaTable,
                Option<String>,
                Option<f32>,
                Option<LuaValue>,
            )| {
                let trans = transition
                    .as_deref()
                    .map(TransitionType::from_lua_str)
                    .unwrap_or(TransitionType::None);
                let dur = duration.unwrap_or(0.0);

                let mut s = st.borrow_mut();
                let scene_id = s.stack.next_scene_id();
                let key = lua.create_registry_value(scene)?;

                let prev_id = s.stack.push(scene_id, trans, dur);
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
    /// Pops the top scene from the stack with an optional transition.
    /// @param transition : string?
    /// @param duration : number?
    /// @return nil
    let st = state.clone();
    tbl.set(
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

                if let Some(popped_key) = s.scene_refs.remove(&popped_id) {
                    let _ = call_scene_method(lua, &popped_key, "leave", ());
                }

                if let Some(rid) = revealed_id {
                    if let Some(revealed_key) = s.scene_refs.get(&rid) {
                        let _ = call_scene_method(lua, revealed_key, "resume", ());
                    }
                }

                Ok(())
            },
        )?,
    )?;

    // -- switchTo --
    /// Replaces the top scene with a new one, calling leave and enter callbacks.
    /// @param scene : table
    /// @param transition : string?
    /// @param duration : number?
    /// @param params : table?
    /// @return nil
    let st = state.clone();
    tbl.set(
        "switchTo",
        lua.create_function(
            move |lua,
                  (scene, transition, duration, params): (
                LuaTable,
                Option<String>,
                Option<f32>,
                Option<LuaValue>,
            )| {
                let trans = transition
                    .as_deref()
                    .map(TransitionType::from_lua_str)
                    .unwrap_or(TransitionType::None);
                let dur = duration.unwrap_or(0.0);

                let mut s = st.borrow_mut();
                let scene_id = s.stack.next_scene_id();
                let key = lua.create_registry_value(scene)?;

                let old_id = s.stack.switch_to(scene_id, trans, dur);
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
    /// @param name : string
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
    /// @param dt : number
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
    /// Calls `scene:ready(self)` on the top scene if not yet fired, then `scene:process(dt)`.
    /// Preferred over `update` — matches the engine's main-loop naming.
    /// @param dt : number
    /// @return nil
    let st = state.clone();
    tbl.set(
        "process",
        lua.create_function(move |lua, dt: f64| {
            let mut s = st.borrow_mut();
            if let Some(top_id) = s.stack.get_current() {
                // Fire ready once, on the first process tick after enter.
                if s.scene_ready_pending.remove(&top_id) {
                    if let Some(top_key) = s.scene_refs.get(&top_id) {
                        let _ = call_scene_method(lua, top_key, "ready", ());
                    }
                }
                if let Some(top_key) = s.scene_refs.get(&top_id) {
                    let _ = call_scene_method(lua, top_key, "process", dt);
                }
            }
            Ok(())
        })?,
    )?;

    // -- processPhysics --
    /// Calls `scene:process_physics(dt)` on the topmost scene (fixed timestep).
    /// @param dt : number
    /// @return nil
    let st = state.clone();
    tbl.set(
        "processPhysics",
        lua.create_function(move |lua, dt: f64| {
            let s = st.borrow();
            if let Some(top_id) = s.stack.get_current() {
                if let Some(top_key) = s.scene_refs.get(&top_id) {
                    let _ = call_scene_method(lua, top_key, "process_physics", dt);
                }
            }
            Ok(())
        })?,
    )?;

    // -- processLate --
    /// Calls `scene:process_late(dt)` on the topmost scene (after process, before render).
    /// @param dt : number
    /// @return nil
    let st = state.clone();
    tbl.set(
        "processLate",
        lua.create_function(move |lua, dt: f64| {
            let s = st.borrow();
            if let Some(top_id) = s.stack.get_current() {
                if let Some(top_key) = s.scene_refs.get(&top_id) {
                    let _ = call_scene_method(lua, top_key, "process_late", dt);
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

    // ── Stack query ──────────────────────────────────────────────────────

    // -- getStackSize --
    /// Returns the number of scenes on the stack.
    /// @return integer
    let st = state.clone();
    tbl.set(
        "getStackSize",
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

    // ── Transitions ──────────────────────────────────────────────────────

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

    // ── Registry ─────────────────────────────────────────────────────────

    // -- registerScene --
    /// Registers a scene table by name for later retrieval.
    /// @param name : string
    /// @param scene : table
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
    /// @param name : string
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
    /// @param name : string
    /// @return boolean
    let st = state.clone();
    tbl.set(
        "hasRegistered",
        lua.create_function(move |_, name: String| Ok(st.borrow().stack.has_registered(&name)))?,
    )?;

    // -- unregisterScene --
    /// Removes a scene from the registry by name.
    /// @param name : string
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

    // ── Data store ───────────────────────────────────────────────────────

    // -- setData --
    /// Stores a value in the inter-scene data store under the given key.
    /// @param key : string
    /// @param value : table
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
    /// @param key : string
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
    /// @param key : string
    /// @return boolean
    let st = state.clone();
    tbl.set(
        "hasData",
        lua.create_function(move |_, key: String| Ok(st.borrow().stack.has_data(&key)))?,
    )?;

    // -- removeData --
    /// Removes a value from the inter-scene data store by key.
    /// @param key : string
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

    // ── Factory ──────────────────────────────────────────────────────────

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

    // ── Scene helpers ─────────────────────────────────────────────────────

    // Expose `lurek.scene` in the global namespace BEFORE running inline Lua so
    // that `lurek.scene` is resolvable when the snippet executes.
    luna.set("scene", tbl.clone())?;

    // Inline Lua helpers registered directly so they have zero Rust overhead.
    // `lurek.scene.new(def)` — creates a scene instance from a methods table.
    // `lurek.scene.define(def)` — creates a reusable scene class (callable constructor).
    lua.load(
        r#"
local _tbl = luna.scene

--- luna.scene.new(def) — create a scene instance directly from a methods table.
--- @param def table  A table of optional scene callbacks (ready, process, render, …).
--- @return table     A new scene instance whose metatable delegates to `def`.
function _tbl.new(def)
    def = def or {}
    def.__index = def
    return setmetatable({}, def)
end

--- luna.scene.define(def) — create a reusable scene class.
--- Returns a zero-argument constructor function that produces new instances.
--- @param def table  A table of optional scene callbacks shared across instances.
--- @return function  Constructor: call it (no args) to get a fresh scene instance.
function _tbl.define(def)
    def = def or {}
    def.__index = def
    return function()
        return setmetatable({}, def)
    end
end
    "#,
    )
    .exec()?;

    Ok(())
}
