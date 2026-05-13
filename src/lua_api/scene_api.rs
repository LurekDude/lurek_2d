use super::SharedState;
use crate::scene::depth_sorter::DepthSorter;
use crate::scene::stack::{SceneId, SceneStack};
use crate::scene::transition::{EasingType, TransitionType};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;
struct SceneState {
    stack: SceneStack,
    scene_refs: HashMap<SceneId, LuaRegistryKey>,
    data_refs: HashMap<String, LuaRegistryKey>,
    scene_ready_pending: HashSet<SceneId>,
    preload_callbacks: HashMap<String, LuaRegistryKey>,
    preloaded_names: HashSet<String>,
}
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
pub struct LuaDepthSorter {
    inner: Rc<RefCell<DepthSorter>>,
    callbacks: Rc<RefCell<Vec<LuaRegistryKey>>>,
}
impl LuaUserData for LuaDepthSorter {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("add", |lua, this, (callback, depth): (LuaFunction, f32)| {
            let key = lua.create_registry_value(callback)?;
            let mut cbs = this.callbacks.borrow_mut();
            let index = cbs.len();
            cbs.push(key);
            this.inner.borrow_mut().add(index, depth);
            Ok(())
        });
        methods.add_method("addObject", |lua, this, obj: LuaTable| {
            let depth: f32 = obj.get::<_, f32>("depth").unwrap_or(0.0);
            let key = lua.create_registry_value(obj)?;
            let mut cbs = this.callbacks.borrow_mut();
            let index = cbs.len();
            cbs.push(key);
            this.inner.borrow_mut().add_object(index, depth);
            Ok(())
        });
        methods.add_method("sort", |_, this, ()| {
            this.inner.borrow_mut().sort();
            Ok(())
        });
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
        methods.add_method("setStable", |_, this, stable: bool| {
            this.inner.borrow_mut().set_stable(stable);
            Ok(())
        });
        methods.add_method("isStable", |_, this, ()| {
            Ok(this.inner.borrow().is_stable())
        });
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            this.callbacks.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("getCount", |_, this, ()| {
            Ok(this.inner.borrow().get_count())
        });
        methods.add_method("type", |_, _, ()| Ok("LDepthSorter"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDepthSorter" || name == "Object")
        });
    }
}
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
    let st = state.clone();
    tbl.set("pop", lua.create_function(
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
    let st = state.clone();
    tbl.set(
        "process",
        lua.create_function(move |lua, dt: f64| {
            let mut s = st.borrow_mut();
            let active_ids: Vec<SceneId> = s.stack.get_active_ids_ordered_by_layer();
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
    let st = state.clone();
    tbl.set(
        "processPhysics",
        lua.create_function(move |lua, dt: f64| {
            let s = st.borrow();
            let active_ids: Vec<SceneId> = s.stack.get_active_ids_ordered_by_layer();
            for id in &active_ids {
                if let Some(key) = s.scene_refs.get(id) {
                    let _ = call_scene_method(lua, key, "process_physics", dt);
                }
            }
            Ok(())
        })?,
    )?;
    let st = state.clone();
    tbl.set(
        "processLate",
        lua.create_function(move |lua, dt: f64| {
            let s = st.borrow();
            let active_ids: Vec<SceneId> = s.stack.get_active_ids_ordered_by_layer();
            for id in &active_ids {
                if let Some(key) = s.scene_refs.get(id) {
                    let _ = call_scene_method(lua, key, "process_late", dt);
                }
            }
            Ok(())
        })?,
    )?;
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
    let st = state.clone();
    tbl.set(
        "getStackSize",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_stack_size()))?,
    )?;
    let st = state.clone();
    tbl.set(
        "depth",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_stack_size()))?,
    )?;
    let st = state.clone();
    tbl.set(
        "isEmpty",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.is_empty()))?,
    )?;
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
    let st = state.clone();
    tbl.set(
        "setCurrentLayer",
        lua.create_function(move |_, layer: i32| {
            let mut s = st.borrow_mut();
            if let Some(top_id) = s.stack.get_current() {
                s.stack.set_scene_layer(top_id, layer);
                return Ok(true);
            }
            Ok(false)
        })?,
    )?;
    let st = state.clone();
    tbl.set(
        "getCurrentLayer",
        lua.create_function(move |_, ()| {
            let s = st.borrow();
            if let Some(top_id) = s.stack.get_current() {
                return Ok(s.stack.get_scene_layer(top_id));
            }
            Ok(0)
        })?,
    )?;
    let st = state.clone();
    tbl.set(
        "isTransitioning",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.is_transitioning()))?,
    )?;
    let st = state.clone();
    tbl.set(
        "getTransitionProgress",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_transition_progress()))?,
    )?;
    let st = state.clone();
    tbl.set(
        "queueTransition",
        lua.create_function(
            move |_, (transition, duration, easing): (String, f32, Option<String>)| {
                let trans = TransitionType::from_lua_str(transition.as_str());
                let eas = easing
                    .as_deref()
                    .map(EasingType::from_lua_str)
                    .unwrap_or_default();
                st.borrow_mut().stack.queue_transition(trans, duration, eas);
                Ok(())
            },
        )?,
    )?;
    let st = state.clone();
    tbl.set(
        "getQueuedTransitionCount",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.queued_transition_count()))?,
    )?;
    let st = state.clone();
    tbl.set(
        "clearQueuedTransitions",
        lua.create_function(move |_, ()| {
            st.borrow_mut().stack.clear_transition_queue();
            Ok(())
        })?,
    )?;
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
    let st = state.clone();
    tbl.set(
        "hasRegistered",
        lua.create_function(move |_, name: String| Ok(st.borrow().stack.has_registered(&name)))?,
    )?;
    let st = state.clone();
    tbl.set(
        "unregisterScene",
        lua.create_function(move |_, name: String| {
            st.borrow_mut().stack.unregister_scene(&name);
            Ok(())
        })?,
    )?;
    let st = state.clone();
    tbl.set(
        "getRegisteredNames",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_registered_names()))?,
    )?;
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
    let st = state.clone();
    tbl.set(
        "hasData",
        lua.create_function(move |_, key: String| Ok(st.borrow().stack.has_data(&key)))?,
    )?;
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
    tbl.set(
        "newDepthSorter",
        lua.create_function(|_, ()| {
            Ok(LuaDepthSorter {
                inner: Rc::new(RefCell::new(DepthSorter::new())),
                callbacks: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;
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
    let st = state.clone();
    tbl.set(
        "getTransitionProgressEased",
        lua.create_function(move |_, ()| Ok(st.borrow().stack.get_transition_progress_eased()))?,
    )?;
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
    let st = state.clone();
    tbl.set(
        "getActiveScenes",
        lua.create_function(move |lua, ()| {
            let s = st.borrow();
            let active_ids: Vec<SceneId> = s.stack.get_active_ids_ordered_by_layer();
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
    let st = state.clone();
    tbl.set(
        "isPreloaded",
        lua.create_function(move |_, name: String| {
            Ok(st.borrow().preloaded_names.contains(&name))
        })?,
    )?;
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
                };
                if loader_opt.is_some() {
                    st.borrow_mut().preloaded_names.insert(name.clone());
                }
                if let Some(loader) = &loader_opt {
                    let _ = loader.call::<_, ()>(());
                }
                let mut s = st.borrow_mut();
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
    tbl.set(
        "getTransitionTypes",
        lua.create_function(|lua, ()| {
            let tbl = lua.create_table()?;
            let types = [
                "none",
                "fade",
                "slideleft",
                "slideright",
                "slideup",
                "slidedown",
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
    let st = state.clone();
    tbl.set(
        "serializeScene",
        lua.create_function(move |lua, ()| {
            let s = st.borrow();
            let snap = lua.create_table()?;
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
    let st = state.clone();
    tbl.set(
        "deserializeScene",
        lua.create_function(move |lua, snapshot: LuaTable| {
            let mut s = st.borrow_mut();
            if let Ok(data) = snapshot.get::<_, LuaTable>("data") {
                for pair in data.pairs::<String, LuaValue>() {
                    let (k, v) = pair?;
                    let reg_key = lua.create_registry_value(v)?;
                    if let Some(old) = s.data_refs.remove(&k) {
                        lua.remove_registry_value(old)?;
                    }
                    s.data_refs.insert(k, reg_key);
                }
            }
            Ok(())
        })?,
    )?;
    let trans_tbl = lua.create_table()?;
    trans_tbl.set(
        "fade",
        lua.create_function(|lua, duration: Option<f32>| {
            let t = lua.create_table()?;
            t.set("type", "fade")?;
            t.set("duration", duration.unwrap_or(0.5))?;
            Ok(t)
        })?,
    )?;
    trans_tbl.set(
        "slide",
        lua.create_function(
            |lua, (direction, duration): (Option<String>, Option<f32>)| {
                let t = lua.create_table()?;
                let dir = match direction.as_deref().unwrap_or("left") {
                    "left" | "slideleft" => "slideleft",
                    "right" | "slideright" => "slideright",
                    "up" | "slideup" => "slideup",
                    "down" | "slidedown" => "slidedown",
                    _ => "slideleft",
                };
                t.set("type", dir)?;
                t.set("duration", duration.unwrap_or(0.4))?;
                Ok(t)
            },
        )?,
    )?;
    trans_tbl.set(
        "wipe",
        lua.create_function(|lua, duration: Option<f32>| {
            let t = lua.create_table()?;
            t.set("type", "wipe")?;
            t.set("duration", duration.unwrap_or(0.5))?;
            Ok(t)
        })?,
    )?;
    trans_tbl.set(
        "iris",
        lua.create_function(|lua, duration: Option<f32>| {
            let t = lua.create_table()?;
            t.set("type", "iris")?;
            t.set("duration", duration.unwrap_or(0.6))?;
            Ok(t)
        })?,
    )?;
    tbl.set("transitions", trans_tbl)?;
    lurek.set("scene", tbl.clone())?;
    Ok(())
}
