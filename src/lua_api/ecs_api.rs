//! `lurek.ecs` -- Entity-component-system bindings for creating universes, managing entities and components, running Lua systems, querying tags and blueprints, serializing state, and tracking hierarchy and relation data.

use super::SharedState;
use crate::ecs::Universe;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
#[derive(Clone)]
/// Lua-side handle for one ECS universe.
pub struct LuaUniverse {
    /// Shared ECS universe storage used by all cloned Lua handles.
    inner: Rc<RefCell<Universe>>,
    /// Registered callbacks keyed by component name for add events.
    add_observers: Rc<RefCell<HashMap<String, Vec<LuaRegistryKey>>>>,
    /// Registered callbacks keyed by component name for remove events.
    remove_observers: Rc<RefCell<HashMap<String, Vec<LuaRegistryKey>>>>,
}
/// Provides Lua methods for ECS entity, component, system, tag, blueprint, hierarchy, observer, and relation operations.
impl LuaUserData for LuaUniverse {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- spawn --
        /// Creates a new entity in this universe.
        /// @return | integer | Numeric entity id for the spawned entity.
        methods.add_method("spawn", |_, this, ()| Ok(this.inner.borrow_mut().spawn()));
        // -- kill --
        /// Deletes an entity and removes its components from this universe.
        /// @param | id | integer | Entity id to delete.
        /// @return | nil | No value is returned.
        methods.add_method("kill", |lua, this, id: u32| {
            this.inner.borrow_mut().kill(id, lua)
        });
        // -- isAlive --
        /// Returns whether an entity id currently exists in this universe.
        /// @param | id | integer | Entity id to test.
        /// @return | boolean | True when the entity is alive.
        methods.add_method("isAlive", |_, this, id: u32| {
            Ok(this.inner.borrow().is_alive(id))
        });
        // -- set --
        /// Stores or replaces a component value on an entity.
        /// @param | id | integer | Entity id that receives the component.
        /// @param | name | string | Component name.
        /// @param | value | LuaValue | Lua value stored as the component payload.
        /// @return | nil | No value is returned.
        methods.add_method(
            "set",
            |lua, this, (id, name, value): (u32, String, LuaValue)| {
                this.inner.borrow_mut().set_component(lua, id, &name, value)
            },
        );
        // -- get --
        /// Returns a component value from an entity.
        /// @param | id | integer | Entity id to read.
        /// @param | name | string | Component name to read.
        /// @return | LuaValue | Stored component value, or nil when the entity does not have that component.
        methods.add_method("get", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().get_component(lua, id, &name)
        });
        // -- has --
        /// Returns whether an entity has a named component.
        /// @param | id | integer | Entity id to inspect.
        /// @param | name | string | Component name to check.
        /// @return | boolean | True when the component exists on the entity.
        methods.add_method("has", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().has_component(lua, id, &name)
        });
        // -- remove --
        /// Removes a named component from an entity.
        /// @param | id | integer | Entity id to mutate.
        /// @param | name | string | Component name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("remove", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().remove_component(lua, id, &name)
        });
        // -- getComponents --
        /// Returns component names currently stored on an entity.
        /// @param | id | integer | Entity id to inspect.
        /// @return | table | Array table of component name strings.
        methods.add_method("getComponents", |lua, this, id: u32| {
            this.inner.borrow().get_component_names(lua, id)
        });
        // -- query --
        /// Returns entities that have all component names passed as varargs.
        /// @param | ... | string | Component names that every returned entity must have.
        /// @return | table | Array table of matching entity ids.
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
        // -- each --
        /// Iterates entities with one component and calls a Lua callback for each match.
        /// @param | name | string | Component name used to select entities.
        /// @param | callback | function | Callback invoked by the ECS backend for each matching entity.
        /// @return | nil | No value is returned.
        methods.add_method(
            "each",
            |lua, this, (name, callback): (String, LuaFunction)| {
                this.inner.borrow().each(lua, &name, callback)
            },
        );
        // -- getEntities --
        /// Returns all live entity ids in this universe.
        /// @return | table | Array table of live entity ids.
        methods.add_method("getEntities", |_, this, ()| {
            Ok(this.inner.borrow().get_entities())
        });
        // -- getEntityCount --
        /// Returns the number of live entities in this universe.
        /// @return | integer | Live entity count.
        methods.add_method("getEntityCount", |_, this, ()| {
            Ok(this.inner.borrow().get_entity_count())
        });
        // -- addSystem --
        /// Registers a Lua system table with optional phase, priority, name, and dependency metadata.
        /// @param | system | table | System table containing update, render, draw, or event methods.
        /// @param | opts | table | Optional table with priority, phase, name, and after fields.
        /// @return | nil | No value is returned.
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
        // -- removeSystem --
        /// Removes a previously registered Lua system table.
        /// @param | system | table | System table to remove from this universe.
        /// @return | nil | No value is returned.
        methods.add_method("removeSystem", |lua, this, system: LuaTable| {
            this.inner.borrow_mut().remove_system(lua, system)
        });
        // -- update --
        /// Runs registered update-phase systems with a frame delta.
        /// @param | dt | number | Frame delta time in seconds.
        /// @return | nil | No value is returned.
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
        // -- render --
        /// Runs registered render-phase systems using their render or draw callbacks.
        /// @return | nil | No value is returned.
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
        // -- emit --
        /// Calls matching event-named functions on registered systems.
        /// @param | event | string | Function name looked up on each system table.
        /// @param | ... | LuaValue | Extra values forwarded after the system and universe arguments.
        /// @return | nil | No value is returned.
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
        // -- getSystemCount --
        /// Returns the number of registered systems.
        /// @return | integer | Registered system count.
        methods.add_method("getSystemCount", |lua, this, ()| {
            this.inner.borrow().get_system_count(lua)
        });
        // -- updatePhase --
        /// Runs registered systems assigned to a named phase.
        /// @param | phase | string | System phase name to run.
        /// @param | dt | number | Frame delta time in seconds.
        /// @return | nil | No value is returned.
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
        // -- getDirtyEntities --
        /// Returns entities marked dirty by recent ECS mutations.
        /// @return | table | Array table of dirty entity ids.
        methods.add_method("getDirtyEntities", |lua, this, ()| {
            let ids = this.inner.borrow().get_dirty_entities();
            let t = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                t.set(i + 1, *id)?;
            }
            Ok(LuaValue::Table(t))
        });
        // -- queryMulti --
        /// Iterates entities that have all component names from a table.
        /// @param | names_table | table | Array table of component names.
        /// @param | callback | function | Callback invoked by the ECS backend for each matching entity.
        /// @return | nil | No value is returned.
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
        // -- snapshot --
        /// Serializes this universe into a Lua table snapshot.
        /// @return | table | Snapshot table containing entities and component state.
        methods.add_method("snapshot", |lua, this, ()| {
            this.inner.borrow().serialize_to_table(lua)
        });
        // -- applySnapshot --
        /// Replaces this universe state from a Lua table snapshot.
        /// @param | snapshot | table | Snapshot table previously produced by `snapshot` or `serialize`.
        /// @return | nil | No value is returned.
        methods.add_method("applySnapshot", |lua, this, snapshot: LuaTable| {
            this.inner
                .borrow_mut()
                .deserialize_from_table(lua, snapshot)
        });
        // -- takeSnapshotDiff --
        /// Returns and clears accumulated ECS snapshot diff data.
        /// @return | table | Diff table with added_components, removed_components, deleted_entities, and dirty_entities arrays.
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
        // -- clear --
        /// Clears all entities, components, systems, and ECS state from this universe.
        /// @return | nil | No value is returned.
        methods.add_method("clear", |lua, this, ()| this.inner.borrow_mut().clear(lua));
        // -- release --
        /// Releases universe contents by clearing all ECS state.
        /// @return | nil | No value is returned.
        methods.add_method("release", |lua, this, ()| {
            this.inner.borrow_mut().clear(lua)
        });
        // -- addTag --
        /// Adds a string tag to an entity. This method is available to Lua scripts.
        /// @param | id | integer | Entity id to tag.
        /// @param | tag | string | Tag name to add.
        /// @return | nil | No value is returned.
        methods.add_method("addTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().add_tag(id, &tag);
            Ok(())
        });
        // -- removeTag --
        /// Removes a string tag from an entity.
        /// @param | id | integer | Entity id to update.
        /// @param | tag | string | Tag name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().remove_tag(id, &tag);
            Ok(())
        });
        // -- hasTag --
        /// Returns whether an entity has a string tag.
        /// @param | id | integer | Entity id to inspect.
        /// @param | tag | string | Tag name to check.
        /// @return | boolean | True when the entity has the tag.
        methods.add_method("hasTag", |_, this, (id, tag): (u32, String)| {
            Ok(this.inner.borrow().has_tag(id, &tag))
        });
        // -- getTags --
        /// Returns string tags assigned to an entity.
        /// @param | id | integer | Entity id to inspect.
        /// @return | table | Array table of tag names.
        methods.add_method("getTags", |_, this, id: u32| {
            Ok(this.inner.borrow().get_tags(id))
        });
        // -- getEntitiesByTag --
        /// Returns entities that have a string tag.
        /// @param | tag | string | Tag name used for lookup.
        /// @return | table | Array table of matching entity ids.
        methods.add_method("getEntitiesByTag", |_, this, tag: String| {
            Ok(this.inner.borrow().get_entities_by_tag(&tag))
        });
        // -- setLayer --
        /// Assigns a numeric layer to an entity.
        /// @param | id | integer | Entity id to update.
        /// @param | layer | integer | Layer value stored on the entity.
        /// @return | nil | No value is returned.
        methods.add_method("setLayer", |_, this, (id, layer): (u32, i32)| {
            this.inner.borrow_mut().set_layer(id, layer);
            Ok(())
        });
        // -- getLayer --
        /// Returns the numeric layer assigned to an entity.
        /// @param | id | integer | Entity id to inspect.
        /// @return | integer | Layer value, using the ECS default when no explicit layer exists.
        methods.add_method("getLayer", |_, this, id: u32| {
            Ok(this.inner.borrow().get_layer(id))
        });
        // -- getEntitiesByLayer --
        /// Returns entities assigned to a numeric layer.
        /// @param | layer | integer | Layer value used for lookup.
        /// @return | table | Array table of matching entity ids.
        methods.add_method("getEntitiesByLayer", |_, this, layer: i32| {
            Ok(this.inner.borrow().get_entities_by_layer(layer))
        });
        // -- getEntitiesSorted --
        /// Returns live entities sorted by ECS layer and stable entity ordering.
        /// @return | table | Array table of sorted entity ids.
        methods.add_method("getEntitiesSorted", |_, this, ()| {
            Ok(this.inner.borrow().get_entities_sorted())
        });
        // -- defineTag --
        /// Defines a bitmap tag name and assigns it a bit slot.
        /// @param | name | string | Bitmap tag name to define.
        /// @return | integer | Bit index assigned to the tag.
        methods.add_method("defineTag", |_, this, name: String| {
            this.inner.borrow_mut().define_tag(&name)
        });
        // -- bitmapTag --
        /// Adds a bitmap tag to an entity, defining the tag if needed.
        /// @param | id | integer | Entity id to tag.
        /// @param | name | string | Bitmap tag name.
        /// @return | integer | Bit index used by the bitmap tag.
        methods.add_method("bitmapTag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_tag(id, &name)
        });
        // -- bitmapUntag --
        /// Removes a bitmap tag from an entity.
        /// @param | id | integer | Entity id to update.
        /// @param | name | string | Bitmap tag name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("bitmapUntag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_untag(id, &name);
            Ok(())
        });
        // -- hasBitmapTag --
        /// Returns whether an entity has a bitmap tag.
        /// @param | id | integer | Entity id to inspect.
        /// @param | name | string | Bitmap tag name to check.
        /// @return | boolean | True when the entity has the bitmap tag.
        methods.add_method("hasBitmapTag", |_, this, (id, name): (u32, String)| {
            Ok(this.inner.borrow().has_bitmap_tag(id, &name))
        });
        // -- queryBitmapTag --
        /// Returns entities with one bitmap tag.
        /// @param | name | string | Bitmap tag name used for lookup.
        /// @return | table | Array table of matching entity ids.
        methods.add_method("queryBitmapTag", |_, this, name: String| {
            Ok(this.inner.borrow().query_bitmap_tag(&name))
        });
        // -- queryBitmapAny --
        /// Returns entities with at least one bitmap tag from a list.
        /// @param | names | table | Array table of bitmap tag names.
        /// @return | table | Array table of matching entity ids.
        methods.add_method("queryBitmapAny", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_any(&name_vec))
        });
        // -- queryBitmapAll --
        /// Returns entities that have every bitmap tag from a list.
        /// @param | names | table | Array table of bitmap tag names.
        /// @return | table | Array table of matching entity ids.
        methods.add_method("queryBitmapAll", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_all(&name_vec))
        });
        // -- getBitmapTagBit --
        /// Returns the bit index assigned to a bitmap tag name.
        /// @param | name | string | Bitmap tag name to inspect.
        /// @return | LuaValue | Bit index when the tag exists, or nil when the tag is undefined.
        methods.add_method("getBitmapTagBit", |_, this, name: String| {
            Ok(this.inner.borrow().get_bitmap_tag_bit(&name))
        });
        // -- defineBlueprint --
        /// Defines a named entity blueprint from a component table.
        /// @param | name | string | Blueprint name.
        /// @param | components | table | Component table copied when the blueprint is spawned.
        /// @return | nil | No value is returned.
        methods.add_method(
            "defineBlueprint",
            |lua, this, (name, components): (String, LuaTable)| {
                this.inner
                    .borrow_mut()
                    .define_blueprint(lua, &name, components)
            },
        );
        // -- extendBlueprint --
        /// Defines a blueprint that inherits from a parent blueprint and applies overrides.
        /// @param | name | string | Child blueprint name to define.
        /// @param | parent | string | Existing parent blueprint name.
        /// @param | overrides | table | Component overrides applied over the parent definition.
        /// @return | nil | No value is returned.
        methods.add_method(
            "extendBlueprint",
            |lua, this, (name, parent, overrides): (String, String, LuaTable)| {
                this.inner
                    .borrow_mut()
                    .extend_blueprint(lua, &name, &parent, overrides)
            },
        );
        // -- spawnBlueprint --
        /// Spawns an entity from a named blueprint with optional component overrides.
        /// @param | name | string | Blueprint name to instantiate.
        /// @param | overrides | table | Optional component overrides applied to this spawn.
        /// @return | integer | Entity id created from the blueprint.
        methods.add_method(
            "spawnBlueprint",
            |lua, this, (name, overrides): (String, Option<LuaTable>)| {
                this.inner
                    .borrow_mut()
                    .spawn_blueprint(lua, &name, overrides)
            },
        );
        // -- hasBlueprint --
        /// Returns whether a named blueprint exists.
        /// @param | name | string | Blueprint name to check.
        /// @return | boolean | True when the blueprint is registered.
        methods.add_method("hasBlueprint", |lua, this, name: String| {
            this.inner.borrow().has_blueprint(lua, &name)
        });
        // -- removeBlueprint --
        /// Removes a named blueprint from this universe.
        /// @param | name | string | Blueprint name to remove.
        /// @return | boolean | True when a blueprint was removed.
        methods.add_method("removeBlueprint", |lua, this, name: String| {
            this.inner.borrow().remove_blueprint(lua, &name)
        });
        // -- listBlueprints --
        /// Returns names of all registered blueprints.
        /// @return | table | Array table of blueprint names.
        methods.add_method("listBlueprints", |lua, this, ()| {
            this.inner.borrow().list_blueprints(lua)
        });
        // -- getBlueprintComponents --
        /// Returns the component table stored for a blueprint.
        /// @param | name | string | Blueprint name to inspect.
        /// @return | table | Blueprint component table.
        methods.add_method("getBlueprintComponents", |lua, this, name: String| {
            this.inner.borrow().get_blueprint_components(lua, &name)
        });
        // -- setParent --
        /// Sets or clears the parent entity for a child entity.
        /// @param | child_id | integer | Entity id whose parent changes.
        /// @param | parent_id | integer | Optional parent entity id; nil clears the parent.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setParent",
            |_, this, (child_id, parent_id): (u32, Option<u32>)| {
                this.inner.borrow_mut().set_parent(child_id, parent_id);
                Ok(())
            },
        );
        // -- getParent --
        /// Returns the parent entity id for a child entity.
        /// @param | child_id | integer | Entity id whose parent is read.
        /// @return | LuaValue | Parent entity id, or nil when the entity has no parent.
        methods.add_method("getParent", |_, this, child_id: u32| {
            Ok(this.inner.borrow().get_parent(child_id))
        });
        // -- getChildren --
        /// Returns child entity ids for a parent entity.
        /// @param | parent_id | integer | Parent entity id to inspect.
        /// @return | table | Array table of child entity ids.
        methods.add_method("getChildren", |_, this, parent_id: u32| {
            Ok(this.inner.borrow().get_children(parent_id))
        });
        // -- killRecursive --
        /// Deletes an entity and all descendant entities in its hierarchy.
        /// @param | id | integer | Root entity id to delete.
        /// @return | nil | No value is returned.
        methods.add_method("killRecursive", |lua, this, id: u32| {
            this.inner.borrow_mut().kill_recursive(id, lua)
        });
        // -- queryNot --
        /// Returns entities that include one component set and exclude another component set.
        /// @param | with_tbl | table | Array table of required component names.
        /// @param | without_tbl | table | Array table of forbidden component names.
        /// @return | table | Array table of matching entity ids.
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
        // -- serialize --
        /// Serializes this universe into a Lua table snapshot.
        /// @return | table | Snapshot table containing entities and component state.
        methods.add_method("serialize", |lua, this, ()| {
            this.inner.borrow().serialize_to_table(lua)
        });
        // -- deserialize --
        /// Replaces this universe state from a serialized Lua snapshot.
        /// @param | snapshot | table | Snapshot table previously produced by `serialize` or `snapshot`.
        /// @return | nil | No value is returned.
        methods.add_method("deserialize", |lua, this, snapshot: LuaTable| {
            this.inner
                .borrow_mut()
                .deserialize_from_table(lua, snapshot)
        });
        // -- onComponentAdded --
        /// Registers a callback for queued component-add events with a given component name.
        /// @param | name | string | Component name whose add events are observed.
        /// @param | cb | function | Callback receiving entity id and component name.
        /// @return | nil | No value is returned.
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
        // -- onComponentRemoved --
        /// Registers a callback for queued component-remove events with a given component name.
        /// @param | name | string | Component name whose remove events are observed.
        /// @param | cb | function | Callback receiving entity id and component name.
        /// @return | nil | No value is returned.
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
        // -- flushObservers --
        /// Delivers queued component add and remove events to registered observer callbacks.
        /// @return | nil | No value is returned.
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
        // -- spawnBulk --
        /// Spawns multiple entities from a blueprint using shared optional overrides.
        /// @param | name | string | Blueprint name to instantiate.
        /// @param | count | integer | Number of entities to spawn.
        /// @param | overrides | table | Optional component overrides applied to each spawned entity.
        /// @return | table | Array table of spawned entity ids.
        methods.add_method(
            "spawnBulk",
            |lua, this, (name, count, overrides): (String, usize, Option<LuaTable>)| {
                this.inner
                    .borrow_mut()
                    .spawn_bulk(lua, &name, count, overrides)
            },
        );
        // -- addRelation --
        /// Adds a named directed relation from one entity to another.
        /// @param | from | integer | Source entity id.
        /// @param | name | string | Relation name.
        /// @param | to | integer | Target entity id.
        /// @return | nil | No value is returned.
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
        // -- getRelated --
        /// Returns targets linked from an entity by a named relation.
        /// @param | from | integer | Source entity id.
        /// @param | name | string | Relation name.
        /// @return | table | Array table of related target entity ids.
        methods.add_method("getRelated", |lua, this, (from, name): (u32, String)| {
            let inner = this.inner.borrow();
            let ids = inner.relationships.get_links(from, &name);
            let tbl = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                tbl.set(i + 1, *id)?;
            }
            Ok(tbl)
        });
        // -- removeRelation --
        /// Removes a named directed relation between two entities.
        /// @param | from | integer | Source entity id.
        /// @param | name | string | Relation name.
        /// @param | to | integer | Target entity id.
        /// @return | nil | No value is returned.
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
        // -- clearRelations --
        /// Removes every target for one named relation from an entity.
        /// @param | from | integer | Source entity id.
        /// @param | name | string | Relation name to clear.
        /// @return | nil | No value is returned.
        methods.add_method("clearRelations", |_, this, (from, name): (u32, String)| {
            this.inner
                .borrow_mut()
                .relationships
                .clear_links(from, &name);
            Ok(())
        });
        // -- hasRelation --
        /// Returns whether a named directed relation exists between two entities.
        /// @param | from | integer | Source entity id.
        /// @param | name | string | Relation name.
        /// @param | to | integer | Target entity id.
        /// @return | boolean | True when the relation exists.
        methods.add_method(
            "hasRelation",
            |_, this, (from, name, to): (u32, String, u32)| {
                Ok(this.inner.borrow().relationships.has_link(from, &name, to))
            },
        );
        // -- type --
        /// Returns the Lua-visible type name for this universe handle.
        /// @return | string | The string `LUniverse`.
        methods.add_method("type", |_, _, ()| Ok("LUniverse"));
        // -- typeOf --
        /// Returns whether this universe handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LUniverse` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LUniverse" || name == "Object")
        });
    }
}
/// Registers the `lurek.ecs` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newUniverse --
    /// Creates an empty ECS universe for entity, component, system, and relationship management.
    /// @return | LUniverse | New universe handle.
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
