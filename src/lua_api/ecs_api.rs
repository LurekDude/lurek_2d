use super::SharedState;
use crate::ecs::Universe;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
#[derive(Clone)]
pub struct LuaUniverse {
    inner: Rc<RefCell<Universe>>,
    add_observers: Rc<RefCell<HashMap<String, Vec<LuaRegistryKey>>>>,
    remove_observers: Rc<RefCell<HashMap<String, Vec<LuaRegistryKey>>>>,
}
impl LuaUserData for LuaUniverse {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("spawn", |_, this, ()| Ok(this.inner.borrow_mut().spawn()));
        methods.add_method("kill", |lua, this, id: u32| {
            this.inner.borrow_mut().kill(id, lua)
        });
        methods.add_method("isAlive", |_, this, id: u32| {
            Ok(this.inner.borrow().is_alive(id))
        });
        methods.add_method(
            "set",
            |lua, this, (id, name, value): (u32, String, LuaValue)| {
                this.inner.borrow_mut().set_component(lua, id, &name, value)
            },
        );
        methods.add_method("get", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().get_component(lua, id, &name)
        });
        methods.add_method("has", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().has_component(lua, id, &name)
        });
        methods.add_method("remove", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().remove_component(lua, id, &name)
        });
        methods.add_method("getComponents", |lua, this, id: u32| {
            this.inner.borrow().get_component_names(lua, id)
        });
        methods.add_method("query", |lua, this, args: LuaMultiValue| {
            let names: Vec<String> = args
                .into_iter()
                .filter_map(|v| match v {
                    LuaValue::String(s) => s.to_str().ok().map(|s| s.to_string()),
                    _ => None,
                })
                .collect();
            this.inner.borrow().query(lua, &names)
        });
        methods.add_method(
            "each",
            |lua, this, (name, callback): (String, LuaFunction)| {
                this.inner.borrow().each(lua, &name, callback)
            },
        );
        methods.add_method("getEntities", |_, this, ()| {
            Ok(this.inner.borrow().get_entities())
        });
        methods.add_method("getEntityCount", |_, this, ()| {
            Ok(this.inner.borrow().get_entity_count())
        });
        methods.add_method(
            "addSystem",
            |lua, this, (system, opts): (LuaTable, Option<LuaTable>)| {
                let priority = opts
                    .as_ref()
                    .and_then(|o| o.get::<_, i32>("priority").ok())
                    .unwrap_or(0);
                let phase = opts
                    .as_ref()
                    .and_then(|o| o.get::<_, String>("phase").ok())
                    .unwrap_or_default();
                let name = opts
                    .as_ref()
                    .and_then(|o| o.get::<_, String>("name").ok())
                    .unwrap_or_default();
                let deps: Vec<String> = opts
                    .as_ref()
                    .and_then(|o| o.get::<_, LuaTable>("after").ok())
                    .map(|t| {
                        t.sequence_values::<String>()
                            .filter_map(|r| r.ok())
                            .collect()
                    })
                    .unwrap_or_default();
                this.inner
                    .borrow_mut()
                    .add_system(lua, system, priority, phase, name, deps)
            },
        );
        methods.add_method("removeSystem", |lua, this, system: LuaTable| {
            this.inner.borrow_mut().remove_system(lua, system)
        });
        methods.add_method("update", |lua, this, dt: f64| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let order = this
                .inner
                .borrow()
                .get_sorted_system_indices_for_phase("update");
            let store = this.inner.borrow().get_system_store(lua)?;
            let world = this.clone();
            for i in order {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>("update") {
                    func.call::<_, ()>((system.clone(), world.clone(), dt))?;
                }
            }
            Ok(())
        });
        methods.add_method("render", |lua, this, ()| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let order = this
                .inner
                .borrow()
                .get_sorted_system_indices_for_phase("render");
            let store = this.inner.borrow().get_system_store(lua)?;
            let world = this.clone();
            for i in order {
                let system: LuaTable = store.get(i)?;
                let func = system
                    .get::<_, LuaFunction>("render")
                    .or_else(|_| system.get::<_, LuaFunction>("draw"));
                if let Ok(f) = func {
                    f.call::<_, ()>((system.clone(), world.clone()))?;
                }
            }
            Ok(())
        });
        methods.add_method("emit", |lua, this, args: LuaMultiValue| {
            let mut args_iter = args.into_iter();
            let event: String = match args_iter.next() {
                Some(LuaValue::String(s)) => s.to_str()?.to_string(),
                _ => {
                    return Err(LuaError::runtime(
                        "emit() requires event name as first argument",
                    ))
                }
            };
            let extra_args: Vec<LuaValue> = args_iter.collect();
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let order = this.inner.borrow().get_sorted_system_indices_all();
            let store = this.inner.borrow().get_system_store(lua)?;
            let world = this.clone();
            for i in order {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>(event.as_str()) {
                    let mut call_args = Vec::with_capacity(2 + extra_args.len());
                    call_args.push(LuaValue::Table(system.clone()));
                    call_args.push(LuaValue::UserData(lua.create_userdata(world.clone())?));
                    call_args.extend(extra_args.iter().cloned());
                    func.call::<_, ()>(LuaMultiValue::from_vec(call_args))?;
                }
            }
            Ok(())
        });
        methods.add_method("getSystemCount", |lua, this, ()| {
            this.inner.borrow().get_system_count(lua)
        });
        methods.add_method("updatePhase", |lua, this, (phase, dt): (String, f64)| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let order = this
                .inner
                .borrow()
                .get_sorted_system_indices_for_phase(&phase);
            let store = this.inner.borrow().get_system_store(lua)?;
            let world = this.clone();
            for i in order {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>("update") {
                    func.call::<_, ()>((system.clone(), world.clone(), dt))?;
                }
            }
            Ok(())
        });
        methods.add_method("getDirtyEntities", |lua, this, ()| {
            let ids = this.inner.borrow().get_dirty_entities();
            let t = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                t.set(i + 1, *id)?;
            }
            Ok(LuaValue::Table(t))
        });
        methods.add_method(
            "queryMulti",
            |lua, this, (names_table, callback): (LuaTable, LuaFunction)| {
                let mut names: Vec<String> = Vec::new();
                for pair in names_table.sequence_values::<String>() {
                    names.push(pair?);
                }
                this.inner.borrow().query_multi(lua, &names, callback)
            },
        );
        methods.add_method("snapshot", |lua, this, ()| {
            this.inner.borrow().serialize_to_table(lua)
        });
        methods.add_method("applySnapshot", |lua, this, snapshot: LuaTable| {
            this.inner
                .borrow_mut()
                .deserialize_from_table(lua, snapshot)
        });
        methods.add_method("takeSnapshotDiff", |lua, this, ()| {
            let diff = this.inner.borrow_mut().take_snapshot_diff();
            let out = lua.create_table()?;
            let added = lua.create_table()?;
            for (i, (id, name)) in diff.added_components.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("entity_id", *id)?;
                entry.set("name", name.clone())?;
                added.set(i + 1, entry)?;
            }
            out.set("added_components", added)?;
            let removed = lua.create_table()?;
            for (i, (id, name)) in diff.removed_components.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("entity_id", *id)?;
                entry.set("name", name.clone())?;
                removed.set(i + 1, entry)?;
            }
            out.set("removed_components", removed)?;
            let deleted = lua.create_table()?;
            for (i, id) in diff.deleted_entities.iter().enumerate() {
                deleted.set(i + 1, *id)?;
            }
            out.set("deleted_entities", deleted)?;
            let dirty = lua.create_table()?;
            for (i, id) in diff.dirty_entities.iter().enumerate() {
                dirty.set(i + 1, *id)?;
            }
            out.set("dirty_entities", dirty)?;
            Ok(out)
        });
        methods.add_method("clear", |lua, this, ()| this.inner.borrow_mut().clear(lua));
        methods.add_method("release", |lua, this, ()| {
            this.inner.borrow_mut().clear(lua)
        });
        methods.add_method("addTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().add_tag(id, &tag);
            Ok(())
        });
        methods.add_method("removeTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().remove_tag(id, &tag);
            Ok(())
        });
        methods.add_method("hasTag", |_, this, (id, tag): (u32, String)| {
            Ok(this.inner.borrow().has_tag(id, &tag))
        });
        methods.add_method("getTags", |_, this, id: u32| {
            Ok(this.inner.borrow().get_tags(id))
        });
        methods.add_method("getEntitiesByTag", |_, this, tag: String| {
            Ok(this.inner.borrow().get_entities_by_tag(&tag))
        });
        methods.add_method("setLayer", |_, this, (id, layer): (u32, i32)| {
            this.inner.borrow_mut().set_layer(id, layer);
            Ok(())
        });
        methods.add_method("getLayer", |_, this, id: u32| {
            Ok(this.inner.borrow().get_layer(id))
        });
        methods.add_method("getEntitiesByLayer", |_, this, layer: i32| {
            Ok(this.inner.borrow().get_entities_by_layer(layer))
        });
        methods.add_method("getEntitiesSorted", |_, this, ()| {
            Ok(this.inner.borrow().get_entities_sorted())
        });
        methods.add_method("defineTag", |_, this, name: String| {
            this.inner.borrow_mut().define_tag(&name)
        });
        methods.add_method("bitmapTag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_tag(id, &name)
        });
        methods.add_method("bitmapUntag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_untag(id, &name);
            Ok(())
        });
        methods.add_method("hasBitmapTag", |_, this, (id, name): (u32, String)| {
            Ok(this.inner.borrow().has_bitmap_tag(id, &name))
        });
        methods.add_method("queryBitmapTag", |_, this, name: String| {
            Ok(this.inner.borrow().query_bitmap_tag(&name))
        });
        methods.add_method("queryBitmapAny", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_any(&name_vec))
        });
        methods.add_method("queryBitmapAll", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_all(&name_vec))
        });
        methods.add_method("getBitmapTagBit", |_, this, name: String| {
            Ok(this.inner.borrow().get_bitmap_tag_bit(&name))
        });
        methods.add_method(
            "defineBlueprint",
            |lua, this, (name, components): (String, LuaTable)| {
                this.inner
                    .borrow_mut()
                    .define_blueprint(lua, &name, components)
            },
        );
        methods.add_method(
            "extendBlueprint",
            |lua, this, (name, parent, overrides): (String, String, LuaTable)| {
                this.inner
                    .borrow_mut()
                    .extend_blueprint(lua, &name, &parent, overrides)
            },
        );
        methods.add_method(
            "spawnBlueprint",
            |lua, this, (name, overrides): (String, Option<LuaTable>)| {
                this.inner
                    .borrow_mut()
                    .spawn_blueprint(lua, &name, overrides)
            },
        );
        methods.add_method("hasBlueprint", |lua, this, name: String| {
            this.inner.borrow().has_blueprint(lua, &name)
        });
        methods.add_method("removeBlueprint", |lua, this, name: String| {
            this.inner.borrow().remove_blueprint(lua, &name)
        });
        methods.add_method("listBlueprints", |lua, this, ()| {
            this.inner.borrow().list_blueprints(lua)
        });
        methods.add_method("getBlueprintComponents", |lua, this, name: String| {
            this.inner.borrow().get_blueprint_components(lua, &name)
        });
        methods.add_method(
            "setParent",
            |_, this, (child_id, parent_id): (u32, Option<u32>)| {
                this.inner.borrow_mut().set_parent(child_id, parent_id);
                Ok(())
            },
        );
        methods.add_method("getParent", |_, this, child_id: u32| {
            Ok(this.inner.borrow().get_parent(child_id))
        });
        methods.add_method("getChildren", |_, this, parent_id: u32| {
            Ok(this.inner.borrow().get_children(parent_id))
        });
        methods.add_method("killRecursive", |lua, this, id: u32| {
            this.inner.borrow_mut().kill_recursive(id, lua)
        });
        methods.add_method(
            "queryNot",
            |lua, this, (with_tbl, without_tbl): (LuaTable, LuaTable)| {
                let with_names: Vec<String> = with_tbl
                    .sequence_values::<String>()
                    .collect::<LuaResult<_>>()?;
                let without_names: Vec<String> = without_tbl
                    .sequence_values::<String>()
                    .collect::<LuaResult<_>>()?;
                this.inner
                    .borrow()
                    .query_not(lua, &with_names, &without_names)
            },
        );
        methods.add_method("serialize", |lua, this, ()| {
            this.inner.borrow().serialize_to_table(lua)
        });
        methods.add_method("deserialize", |lua, this, snapshot: LuaTable| {
            this.inner
                .borrow_mut()
                .deserialize_from_table(lua, snapshot)
        });
        methods.add_method(
            "onComponentAdded",
            |lua, this, (name, cb): (String, LuaFunction)| {
                let key = lua.create_registry_value(cb)?;
                this.add_observers
                    .borrow_mut()
                    .entry(name)
                    .or_default()
                    .push(key);
                Ok(())
            },
        );
        methods.add_method(
            "onComponentRemoved",
            |lua, this, (name, cb): (String, LuaFunction)| {
                let key = lua.create_registry_value(cb)?;
                this.remove_observers
                    .borrow_mut()
                    .entry(name)
                    .or_default()
                    .push(key);
                Ok(())
            },
        );
        methods.add_method("flushObservers", |lua, this, ()| {
            let (add_evs, remove_evs) = this.inner.borrow_mut().take_component_events();
            for (id, name) in &add_evs {
                if let Some(keys) = this
                    .add_observers
                    .borrow()
                    .get(name.as_str())
                    .map(|v| v.len())
                {
                    let _ = keys;
                }
                let keys_opt: Option<Vec<LuaFunction>> = {
                    let obs = this.add_observers.borrow();
                    obs.get(name.as_str()).map(|keys| {
                        keys.iter()
                            .filter_map(|k| lua.registry_value::<LuaFunction>(k).ok())
                            .collect()
                    })
                };
                if let Some(fns) = keys_opt {
                    for f in fns {
                        f.call::<_, ()>((*id, name.as_str()))?;
                    }
                }
            }
            for (id, name) in &remove_evs {
                let keys_opt: Option<Vec<LuaFunction>> = {
                    let obs = this.remove_observers.borrow();
                    obs.get(name.as_str()).map(|keys| {
                        keys.iter()
                            .filter_map(|k| lua.registry_value::<LuaFunction>(k).ok())
                            .collect()
                    })
                };
                if let Some(fns) = keys_opt {
                    for f in fns {
                        f.call::<_, ()>((*id, name.as_str()))?;
                    }
                }
            }
            Ok(())
        });
        methods.add_method(
            "spawnBulk",
            |lua, this, (name, count, overrides): (String, usize, Option<LuaTable>)| {
                this.inner
                    .borrow_mut()
                    .spawn_bulk(lua, &name, count, overrides)
            },
        );
        methods.add_method(
            "addRelation",
            |_, this, (from, name, to): (u32, String, u32)| {
                this.inner
                    .borrow_mut()
                    .relationships
                    .add_link(from, &name, to);
                Ok(())
            },
        );
        methods.add_method("getRelated", |lua, this, (from, name): (u32, String)| {
            let inner = this.inner.borrow();
            let ids = inner.relationships.get_links(from, &name);
            let tbl = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                tbl.set(i + 1, *id)?;
            }
            Ok(tbl)
        });
        methods.add_method(
            "removeRelation",
            |_, this, (from, name, to): (u32, String, u32)| {
                this.inner
                    .borrow_mut()
                    .relationships
                    .remove_link(from, &name, to);
                Ok(())
            },
        );
        methods.add_method("clearRelations", |_, this, (from, name): (u32, String)| {
            this.inner
                .borrow_mut()
                .relationships
                .clear_links(from, &name);
            Ok(())
        });
        methods.add_method(
            "hasRelation",
            |_, this, (from, name, to): (u32, String, u32)| {
                Ok(this.inner.borrow().relationships.has_link(from, &name, to))
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LUniverse"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LUniverse" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newUniverse",
        lua.create_function(|_, ()| {
            Ok(LuaUniverse {
                inner: Rc::new(RefCell::new(Universe::new())),
                add_observers: Rc::new(RefCell::new(HashMap::new())),
                remove_observers: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    lurek.set("ecs", tbl)?;
    Ok(())
}
