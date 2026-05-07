//! `lurek.ecs` - Lightweight ECS with entity lifecycle, components, tags, layers, and blueprints.
//!
//! Wraps [`crate::ecs::Universe`] as `LuaUniverse` userdata. Supports spawn/kill,
//! per-entity component CRUD, tag flags, named layers, queries, blueprints, and
//! component add/remove observer callbacks.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::ecs::Universe;
use std::collections::HashMap;

// -------------------------------------------------------------------------------
// LuaUniverse UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Universe`] ECS world.
#[derive(Clone)]
pub struct LuaUniverse {
    inner: Rc<RefCell<Universe>>,
    /// Component-added observer callbacks keyed by component name.
    add_observers: Rc<RefCell<HashMap<String, Vec<LuaRegistryKey>>>>,
    /// Component-removed observer callbacks keyed by component name.
    remove_observers: Rc<RefCell<HashMap<String, Vec<LuaRegistryKey>>>>,
}

impl LuaUserData for LuaUniverse {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- spawn --
        /// Creates a new entity and returns its packed ID.
        /// @return | integer | Packed entity ID.
        methods.add_method("spawn", |_, this, ()| Ok(this.inner.borrow_mut().spawn()));

        // -- kill --
        /// Destroys the entity with the given ID, freeing its slot for reuse.
        /// @param | id | integer | Entity ID to destroy.
        /// @return | nil | No value is returned.
        methods.add_method("kill", |lua, this, id: u32| {
            this.inner.borrow_mut().kill(id, lua)
        });

        // -- isAlive --
        /// Returns true if the entity ID is currently alive.
        /// @param | id | integer | Entity ID to check.
        /// @return | boolean | True when the entity is alive.
        methods.add_method("isAlive", |_, this, id: u32| {
            Ok(this.inner.borrow().is_alive(id))
        });

        // -- set --
        /// Sets a component value on an entity.
        /// @param | id | integer | Entity ID to modify.
        /// @param | name | string | Component name.
        /// @param | value | any | Component value to store.
        /// @return | nil | No value is returned.
        methods.add_method("set", |lua, this, (id, name, value): (u32, String, LuaValue)| {
                this.inner.borrow_mut().set_component(lua, id, &name, value)
            },
        );

        // -- get --
        /// Returns the component value for an entity, or nil if missing.
        /// @param | id | integer | Entity ID to read.
        /// @param | name | string | Component name.
        /// @return | table | Component value when present.
        methods.add_method("get", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().get_component(lua, id, &name)
        });

        // -- has --
        /// Returns true if the entity has the named component.
        /// @param | id | integer | Entity ID to inspect.
        /// @param | name | string | Component name.
        /// @return | boolean | True when the component exists.
        methods.add_method("has", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().has_component(lua, id, &name)
        });

        // -- remove --
        /// Removes a component from an entity.
        /// @param | id | integer | Entity ID to modify.
        /// @param | name | string | Component name.
        /// @return | nil | No value is returned.
        methods.add_method("remove", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().remove_component(lua, id, &name)
        });

        // -- getComponents --
        /// Returns all component names for an entity.
        /// @param | id | integer | Entity ID to inspect.
        /// @return | table | Array of component names.
        methods.add_method("getComponents", |lua, this, id: u32| {
            this.inner.borrow().get_component_names(lua, id)
        });

        // -- query --
        /// Returns entity IDs that have all listed component names.
        /// @param | ... | string | Component names that must all exist.
        /// @return | table | Array of matching entity IDs.
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
        /// Calls callback(id, value) for every entity with the named component.
        /// @param | name | string | Component name to iterate.
        /// @param | callback | function | Callback called with each entity ID and value.
        /// @return | nil | No value is returned.
        methods.add_method("each", |lua, this, (name, callback): (String, LuaFunction)| {
                this.inner.borrow().each(lua, &name, callback)
            },
        );

        // -- getEntities --
        /// Returns all alive entity IDs.
        /// @return | table | Array of alive entity IDs.
        methods.add_method("getEntities", |_, this, ()| {
            Ok(this.inner.borrow().get_entities())
        });

        // -- getEntityCount --
        /// Returns the number of alive entities.
        /// @return | integer | Number of alive entities.
        methods.add_method("getEntityCount", |_, this, ()| {
            Ok(this.inner.borrow().get_entity_count())
        });

        // -- addSystem --
        /// Adds a system table to the universe with an optional priority (lower = earlier) and phase.
        /// @param | system | table | System table to register.
        /// @param | opts | table? | Optional table with `priority` integer and `phase` string fields.
        /// @return | nil | No value is returned.
        methods.add_method("addSystem", |lua, this, (system, opts): (LuaTable, Option<LuaTable>)| {
                let priority = opts
                    .as_ref()
                    .and_then(|o| o.get::<_, i32>("priority").ok())
                    .unwrap_or(0);
                let phase = opts
                    .as_ref()
                    .and_then(|o| o.get::<_, String>("phase").ok())
                    .unwrap_or_default();
                this.inner.borrow_mut().add_system(lua, system, priority, phase)
            },
        );

        // -- removeSystem --
        /// Removes a system table from the universe.
        /// @param | system | table | System table to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeSystem", |lua, this, system: LuaTable| {
            this.inner.borrow_mut().remove_system(lua, system)
        });

        // -- update --
        /// Calls update(system, world, dt) on each system in the "update" phase in priority order.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("update", |lua, this, dt: f64| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let order = this.inner.borrow().get_sorted_system_indices_for_phase("update");
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
        /// Calls render(system, world) on each system in the "render" phase in priority order; falls back to draw(system, world).
        /// @return | nil | No value is returned.
        methods.add_method("render", |lua, this, ()| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let order = this.inner.borrow().get_sorted_system_indices_for_phase("render");
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
        /// Emits a named event to all systems that implement the handler, in priority order.
        /// @param | event | string | Event name to invoke on each system.
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
        /// @return | integer | Number of registered systems.
        methods.add_method("getSystemCount", |lua, this, ()| {
            this.inner.borrow().get_system_count(lua)
        });

        // -- updatePhase --
        /// Calls the named lifecycle method on each system that belongs to the given phase, in priority order.
        ///
        /// The handler name defaults to `"update"`.  The world is passed as the second argument after the
        /// system table itself, followed by `dt`.
        ///
        /// @param | phase | string | Phase name, e.g. `"pre_update"`, `"update"`, `"post_update"` or any custom name.
        /// @param | dt | number | Delta time in seconds.
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
        /// Returns entity IDs whose components changed since the last flushObservers / takeObserverEvents call.
        ///
        /// The returned list is sorted.  The set is automatically cleared by `flushObservers` and
        /// `takeObserverEvents`.
        ///
        /// @return | table | Array of entity IDs (integers).
        methods.add_method("getDirtyEntities", |lua, this, ()| {
            let ids = this.inner.borrow().get_dirty_entities();
            let t = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                t.set(i + 1, *id)?;
            }
            Ok(LuaValue::Table(t))
        });

        // -- queryMulti --
        /// Iterates every alive entity that has ALL the listed components and calls the callback with
        /// `callback(id, comp1, comp2, …)` in the same order as the `names` table.
        ///
        /// This avoids a second `getComponent` lookup inside the loop compared to a plain `query`.
        ///
        /// @param | names | table | Array of component name strings.
        /// @param | callback | function | Called as `callback(id, val1, val2, …)` for each matching entity.
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
        /// Serializes the entire universe state to a Lua table.  Alias for serialize.
        ///
        /// The snapshot can be restored with applySnapshot.
        ///
        /// @return | table | Snapshot table.
        methods.add_method("snapshot", |lua, this, ()| {
            this.inner.borrow().serialize_to_table(lua)
        });

        // -- applySnapshot --
        /// Restores the universe from a snapshot table produced by snapshot.  Alias for deserialize.
        ///
        /// All current state is replaced by the snapshot.
        ///
        /// @param | snapshot | table | Snapshot table previously returned by snapshot.
        /// @return | nil | No value is returned.
        methods.add_method("applySnapshot", |lua, this, snapshot: LuaTable| {
            this.inner.borrow_mut().deserialize_from_table(lua, snapshot)
        });

        // -- clear --
        /// Removes all entities, components, tags, layers, and systems. Blueprints are preserved.
        /// @return | nil | No value is returned.
        methods.add_method("clear", |lua, this, ()| this.inner.borrow_mut().clear(lua));

        // -- release --
        /// Releases all universe state, equivalent to clear.
        /// @return | nil | No value is returned.
        methods.add_method("release", |lua, this, ()| {
            this.inner.borrow_mut().clear(lua)
        });

        // -- addTag --
        /// Attaches a string tag to an entity.
        /// @param | id | integer | Entity ID to tag.
        /// @param | tag | string | Tag name to attach.
        /// @return | nil | No value is returned.
        methods.add_method("addTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().add_tag(id, &tag);
            Ok(())
        });

        // -- removeTag --
        /// Removes a string tag from an entity.
        /// @param | id | integer | Entity ID to update.
        /// @param | tag | string | Tag name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().remove_tag(id, &tag);
            Ok(())
        });

        // -- hasTag --
        /// Returns true if the entity carries the given tag.
        /// @param | id | integer | Entity ID to inspect.
        /// @param | tag | string | Tag name to check.
        /// @return | boolean | True when the entity has the tag.
        methods.add_method("hasTag", |_, this, (id, tag): (u32, String)| {
            Ok(this.inner.borrow().has_tag(id, &tag))
        });

        // -- getTags --
        /// Returns all string tags for an entity.
        /// @param | id | integer | Entity ID to inspect.
        /// @return | table | Array of tag names.
        methods.add_method("getTags", |_, this, id: u32| {
            Ok(this.inner.borrow().get_tags(id))
        });

        // -- getEntitiesByTag --
        /// Returns all alive entities with the given string tag.
        /// @param | tag | string | Tag name to query.
        /// @return | table | Array of matching entity IDs.
        methods.add_method("getEntitiesByTag", |_, this, tag: String| {
            Ok(this.inner.borrow().get_entities_by_tag(&tag))
        });

        // -- setLayer --
        /// Sets the layer for an entity.
        /// @param | id | integer | Entity ID to update.
        /// @param | layer | integer | Layer index to assign.
        /// @return | nil | No value is returned.
        methods.add_method("setLayer", |_, this, (id, layer): (u32, i32)| {
            this.inner.borrow_mut().set_layer(id, layer);
            Ok(())
        });

        // -- getLayer --
        /// Returns the layer for an entity, defaulting to zero.
        /// @param | id | integer | Entity ID to inspect.
        /// @return | integer | Assigned layer index.
        methods.add_method("getLayer", |_, this, id: u32| {
            Ok(this.inner.borrow().get_layer(id))
        });

        // -- getEntitiesByLayer --
        /// Returns all alive entities on a specific layer.
        /// @param | layer | integer | Layer index to query.
        /// @return | table | Array of matching entity IDs.
        methods.add_method("getEntitiesByLayer", |_, this, layer: i32| {
            Ok(this.inner.borrow().get_entities_by_layer(layer))
        });

        // -- getEntitiesSorted --
        /// Returns all alive entities sorted by layer then ID.
        /// @return | table | Array of entity IDs sorted by layer then ID.
        methods.add_method("getEntitiesSorted", |_, this, ()| {
            Ok(this.inner.borrow().get_entities_sorted())
        });

        // -- defineTag --
        /// Defines a bitmap tag name, returning its bit index.
        /// @param | name | string | Bitmap tag name to define.
        /// @return | integer | Assigned bit index.
        methods.add_method("defineTag", |_, this, name: String| {
            this.inner.borrow_mut().define_tag(&name)
        });

        // -- bitmapTag --
        /// Adds a bitmap tag to an entity.
        /// @param | id | integer | Entity ID to update.
        /// @param | name | string | Bitmap tag name to add.
        /// @return | nil | No value is returned.
        methods.add_method("bitmapTag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_tag(id, &name)
        });

        // -- bitmapUntag --
        /// Removes a bitmap tag from an entity.
        /// @param | id | integer | Entity ID to update.
        /// @param | name | string | Bitmap tag name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("bitmapUntag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_untag(id, &name);
            Ok(())
        });

        // -- hasBitmapTag --
        /// Returns true if the entity has the given bitmap tag.
        /// @param | id | integer | Entity ID to inspect.
        /// @param | name | string | Bitmap tag name to check.
        /// @return | boolean | True when the bitmap tag is present.
        methods.add_method("hasBitmapTag", |_, this, (id, name): (u32, String)| {
            Ok(this.inner.borrow().has_bitmap_tag(id, &name))
        });

        // -- queryBitmapTag --
        /// Returns all alive entities with the given bitmap tag.
        /// @param | name | string | Bitmap tag name to query.
        /// @return | table | Array of matching entity IDs.
        methods.add_method("queryBitmapTag", |_, this, name: String| {
            Ok(this.inner.borrow().query_bitmap_tag(&name))
        });

        // -- queryBitmapAny --
        /// Returns all alive entities with any of the listed bitmap tags.
        /// @param | names | table | Array of bitmap tag names.
        /// @return | table | Array of matching entity IDs.
        methods.add_method("queryBitmapAny", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_any(&name_vec))
        });

        // -- queryBitmapAll --
        /// Returns all alive entities with all of the listed bitmap tags.
        /// @param | names | table | Array of bitmap tag names.
        /// @return | table | Array of matching entity IDs.
        methods.add_method("queryBitmapAll", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_all(&name_vec))
        });

        // -- getBitmapTagBit --
        /// Returns the bit index for a bitmap tag name, or nil if undefined.
        /// @param | name | string | Bitmap tag name to look up.
        /// @return | integer | Bit index for the tag when it is defined.
        methods.add_method("getBitmapTagBit", |_, this, name: String| {
            Ok(this.inner.borrow().get_bitmap_tag_bit(&name))
        });

        // -- defineBlueprint --
        /// Defines a blueprint from a component table.
        /// @param | name | string | Blueprint name.
        /// @param | components | table | Component table for the blueprint.
        /// @return | nil | No value is returned.
        methods.add_method("defineBlueprint", |lua, this, (name, components): (String, LuaTable)| {
                this.inner
                    .borrow_mut()
                    .define_blueprint(lua, &name, components)
            },
        );

        // -- extendBlueprint --
        /// Defines a blueprint by extending a parent with overrides.
        /// @param | name | string | Blueprint name to create.
        /// @param | parent | string | Parent blueprint name.
        /// @param | overrides | table | Component overrides to apply.
        /// @return | nil | No value is returned.
        methods.add_method("extendBlueprint", |lua, this, (name, parent, overrides): (String, String, LuaTable)| {
                this.inner
                    .borrow_mut()
                    .extend_blueprint(lua, &name, &parent, overrides)
            },
        );

        // -- spawnBlueprint --
        /// Spawns an entity from a blueprint with optional overrides.
        /// @param | name | string | Blueprint name to spawn.
        /// @param | overrides | table? | Optional component overrides.
        /// @return | integer | Spawned entity ID.
        methods.add_method("spawnBlueprint", |lua, this, (name, overrides): (String, Option<LuaTable>)| {
                this.inner
                    .borrow_mut()
                    .spawn_blueprint(lua, &name, overrides)
            },
        );

        // -- hasBlueprint --
        /// Returns true if a blueprint with the given name exists.
        /// @param | name | string | Blueprint name to check.
        /// @return | boolean | True when the blueprint exists.
        methods.add_method("hasBlueprint", |lua, this, name: String| {
            this.inner.borrow().has_blueprint(lua, &name)
        });

        // -- removeBlueprint --
        /// Removes a blueprint definition.
        /// @param | name | string | Blueprint name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeBlueprint", |lua, this, name: String| {
            this.inner.borrow().remove_blueprint(lua, &name)
        });

        // -- listBlueprints --
        /// Returns all defined blueprint names.
        /// @return | table | Array of blueprint names.
        methods.add_method("listBlueprints", |lua, this, ()| {
            this.inner.borrow().list_blueprints(lua)
        });

        // -- getBlueprintComponents --
        /// Returns a deep copy of a blueprint's component table, or nil.
        /// @param | name | string | Blueprint name to read.
        /// @return | table | Component table for the blueprint.
        methods.add_method("getBlueprintComponents", |lua, this, name: String| {
            this.inner.borrow().get_blueprint_components(lua, &name)
        });

        // -- setParent --
        /// Sets or clears the parent of an entity.
        /// @param | child_id | integer | Child entity ID.
        /// @param | parent_id | integer? | Parent entity ID, or nil to clear it.
        /// @return | nil | No value is returned.
        methods.add_method("setParent", |_, this, (child_id, parent_id): (u32, Option<u32>)| {
                this.inner.borrow_mut().set_parent(child_id, parent_id);
                Ok(())
            },
        );

        // -- getParent --
        /// Returns the parent entity ID, or nil if unparented.
        /// @param | child_id | integer | Child entity ID.
        /// @return | integer | Parent entity ID when one is set.
        methods.add_method("getParent", |_, this, child_id: u32| {
            Ok(this.inner.borrow().get_parent(child_id))
        });

        // -- getChildren --
        /// Returns all direct child entity IDs.
        /// @param | parent_id | integer | Parent entity ID.
        /// @return | table | Array of child entity IDs.
        methods.add_method("getChildren", |_, this, parent_id: u32| {
            Ok(this.inner.borrow().get_children(parent_id))
        });

        // -- killRecursive --
        /// Kills an entity and all its descendants recursively.
        /// @param | id | integer | Root entity ID to destroy.
        /// @return | nil | No value is returned.
        methods.add_method("killRecursive", |lua, this, id: u32| {
            this.inner.borrow_mut().kill_recursive(id, lua)
        });

        // -- queryNot --
        /// Returns entity IDs that have all `with` components and none of the `without` components.
        /// @param | with_table | table | Component names that must exist.
        /// @param | without_table | table | Component names that must not exist.
        /// @return | table | Array of matching entity IDs.
        methods.add_method("queryNot", |lua, this, (with_tbl, without_tbl): (LuaTable, LuaTable)| {
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
        /// Serializes all alive entities to a Lua table snapshot.
        /// @return | table | Snapshot table of all alive entities.
        methods.add_method("serialize", |lua, this, ()| {
            this.inner.borrow().serialize_to_table(lua)
        });

        // -- deserialize --
        /// Restores entity state from a snapshot produced by serialize() while preserving blueprints and systems.
        /// @param | snapshot | table | Snapshot table to load.
        /// @return | nil | No value is returned.
        methods.add_method("deserialize", |lua, this, snapshot: LuaTable| {
            this.inner
                .borrow_mut()
                .deserialize_from_table(lua, snapshot)
        });

        // -- onComponentAdded --
        /// Registers a callback for component-added events that is dispatched by flushObservers().
        /// @param | name | string | Component name to observe.
        /// @param | callback | function | Callback receiving entity_id and component_name.
        /// @return | nil | No value is returned.
        methods.add_method("onComponentAdded", |lua, this, (name, cb): (String, LuaFunction)| {
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
        /// Registers a callback for component-removed events that is dispatched by flushObservers().
        /// @param | name | string | Component name to observe.
        /// @param | callback | function | Callback receiving entity_id and component_name.
        /// @return | nil | No value is returned.
        methods.add_method("onComponentRemoved", |lua, this, (name, cb): (String, LuaFunction)| {
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
        /// Dispatches all pending component-add and component-remove events to registered callbacks.
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
                    let _ = keys; // avoid lint
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
        /// Spawns `count` entities from a blueprint, returns an array of entity IDs.
        /// @param | name | string | Blueprint name to spawn.
        /// @param | count | integer | Number of entities to create.
        /// @param | overrides | table? | Optional component overrides.
        /// @return | table | Array of spawned entity IDs.
        methods.add_method("spawnBulk", |lua, this, (name, count, overrides): (String, usize, Option<LuaTable>)| {
                this.inner
                    .borrow_mut()
                    .spawn_bulk(lua, &name, count, overrides)
            },
        );

        // -- addRelation --
        /// Adds a directed named relationship from entity `from` to entity `to`, ignoring duplicates.
        /// @param | from | integer | Source entity ID.
        /// @param | name | string | Relationship name.
        /// @param | to | integer | Target entity ID.
        /// @return | nil | No value is returned.
        methods.add_method("addRelation", |_, this, (from, name, to): (u32, String, u32)| {
                this.inner
                    .borrow_mut()
                    .relationships
                    .add_link(from, &name, to);
                Ok(())
            },
        );

        // -- getRelated --
        /// Returns all entity IDs reachable from `from` via the named relationship.
        /// @param | from | integer | Source entity ID.
        /// @param | name | string | Relationship name.
        /// @return | table | Array of related entity IDs.
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
        /// Removes the directed named relationship from entity `from` to entity `to`.
        /// @param | from | integer | Source entity ID.
        /// @param | name | string | Relationship name.
        /// @param | to | integer | Target entity ID.
        /// @return | nil | No value is returned.
        methods.add_method("removeRelation", |_, this, (from, name, to): (u32, String, u32)| {
                this.inner
                    .borrow_mut()
                    .relationships
                    .remove_link(from, &name, to);
                Ok(())
            },
        );

        // -- clearRelations --
        /// Removes all directed named relationships of type `name` from entity `from`.
        /// @param | from | integer | Source entity ID.
        /// @param | name | string | Relationship name.
        /// @return | nil | No value is returned.
        methods.add_method("clearRelations", |_, this, (from, name): (u32, String)| {
            this.inner
                .borrow_mut()
                .relationships
                .clear_links(from, &name);
            Ok(())
        });

        // -- hasRelation --
        /// Returns true if a directed named relationship from `from` to `to` exists.
        /// @param | from | integer | Source entity ID.
        /// @param | name | string | Relationship name.
        /// @param | to | integer | Target entity ID.
        /// @return | boolean | True when the relationship exists.
        methods.add_method("hasRelation", |_, this, (from, name, to): (u32, String, u32)| {
                Ok(this.inner.borrow().relationships.has_link(from, &name, to))
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name.
        methods.add_method("type", |_, _, ()| Ok("LUniverse"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LUniverse" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.ecs` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newUniverse --
    /// Creates a new empty ECS universe.
    /// @return | LUniverse | New ECS universe wrapper.
    tbl.set("newUniverse", lua.create_function(|_, ()| {
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
