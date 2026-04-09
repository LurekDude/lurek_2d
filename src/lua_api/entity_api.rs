//! `lurek.entity` - Lightweight ECS with entity lifecycle, components, tags, layers, and blueprints.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::entity::Universe;

// -------------------------------------------------------------------------------
// LuaUniverse UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Universe`] ECS world.
#[derive(Clone)]
pub struct LuaUniverse {
    inner: Rc<RefCell<Universe>>,
}

impl LuaUserData for LuaUniverse {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- spawn --
        /// Creates a new entity and returns its packed ID.
        /// @return integer
        methods.add_method("spawn", |_, this, ()| {
            Ok(this.inner.borrow_mut().spawn())
        });

        // -- kill --
        /// Destroys the entity with the given ID, freeing its slot for reuse.
        /// @param id : integer
        /// @return nil
        methods.add_method("kill", |lua, this, id: u32| {
            this.inner.borrow_mut().kill(id, lua)
        });

        // -- isAlive --
        /// Returns true if the entity ID is currently alive.
        /// @param id : integer
        /// @return boolean
        methods.add_method("isAlive", |_, this, id: u32| {
            Ok(this.inner.borrow().is_alive(id))
        });

        // -- set --
        /// Sets a component value on an entity.
        /// @param id : integer
        /// @param name : string
        /// @param value : table
        /// @return nil
        methods.add_method("set", |lua, this, (id, name, value): (u32, String, LuaValue)| {
            this.inner.borrow_mut().set_component(lua, id, &name, value)
        });

        // -- get --
        /// Returns the component value for an entity, or nil if missing.
        /// @param id : integer
        /// @param name : string
        /// @return table
        methods.add_method("get", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().get_component(lua, id, &name)
        });

        // -- has --
        /// Returns true if the entity has the named component.
        /// @param id : integer
        /// @param name : string
        /// @return boolean
        methods.add_method("has", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().has_component(lua, id, &name)
        });

        // -- remove --
        /// Removes a component from an entity.
        /// @param id : integer
        /// @param name : string
        /// @return nil
        methods.add_method("remove", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().remove_component(lua, id, &name)
        });

        // -- getComponents --
        /// Returns all component names for an entity.
        /// @param id : integer
        /// @return table
        methods.add_method("getComponents", |lua, this, id: u32| {
            this.inner.borrow().get_component_names(lua, id)
        });

        // -- query --
        /// Returns entity IDs that have all listed component names.
        /// @param names : string
        /// @return table
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
        /// @param name : string
        /// @param callback : function
        /// @return nil
        methods.add_method("each", |lua, this, (name, callback): (String, LuaFunction)| {
            this.inner.borrow().each(lua, &name, callback)
        });

        // -- getEntities --
        /// Returns all alive entity IDs.
        /// @return table
        methods.add_method("getEntities", |_, this, ()| {
            Ok(this.inner.borrow().get_entities())
        });

        // -- getEntityCount --
        /// Returns the number of alive entities.
        /// @return integer
        methods.add_method("getEntityCount", |_, this, ()| {
            Ok(this.inner.borrow().get_entity_count())
        });

        // -- addSystem --
        /// Adds a system table to the universe.
        /// @param system : table
        /// @return nil
        methods.add_method("addSystem", |lua, this, system: LuaTable| {
            this.inner.borrow_mut().add_system(lua, system)
        });

        // -- removeSystem --
        /// Removes a system table from the universe.
        /// @param system : table
        /// @return nil
        methods.add_method("removeSystem", |lua, this, system: LuaTable| {
            this.inner.borrow_mut().remove_system(lua, system)
        });

        // -- update --
        /// Calls update(system, world, dt) on each registered system.
        /// @param dt : number
        /// @return nil
        methods.add_method("update", |lua, this, dt: f64| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let store = this.inner.borrow().get_system_store(lua)?;
            let world = this.clone();
            for i in 1..=count {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>("update") {
                    func.call::<_, ()>((system.clone(), world.clone(), dt))?;
                }
            }
            Ok(())
        });

        // -- draw --
        /// Calls draw(system, world) on each registered system.
        /// @return nil
        methods.add_method("draw", |lua, this, ()| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let store = this.inner.borrow().get_system_store(lua)?;
            let world = this.clone();
            for i in 1..=count {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>("draw") {
                    func.call::<_, ()>((system.clone(), world.clone()))?;
                }
            }
            Ok(())
        });

        // -- emit --
        /// Emits a named event to all systems that implement the handler.
        /// @param event : string
        /// @return nil
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
            let store = this.inner.borrow().get_system_store(lua)?;
            let world = this.clone();
            for i in 1..=count {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>(event.as_str()) {
                    let mut call_args = Vec::with_capacity(2 + extra_args.len());
                    call_args.push(LuaValue::Table(system.clone()));
                    call_args.push(LuaValue::UserData(
                        lua.create_userdata(world.clone())?,
                    ));
                    call_args.extend(extra_args.iter().cloned());
                    func.call::<_, ()>(LuaMultiValue::from_vec(call_args))?;
                }
            }
            Ok(())
        });

        // -- getSystemCount --
        /// Returns the number of registered systems.
        /// @return integer
        methods.add_method("getSystemCount", |lua, this, ()| {
            this.inner.borrow().get_system_count(lua)
        });

        // -- clear --
        /// Removes all entities, components, tags, layers, and systems. Blueprints are preserved.
        /// @return nil
        methods.add_method("clear", |lua, this, ()| {
            this.inner.borrow_mut().clear(lua)
        });

        // -- release --
        /// Releases all universe state, equivalent to clear.
        /// @return nil
        methods.add_method("release", |lua, this, ()| {
            this.inner.borrow_mut().clear(lua)
        });

        // -- addTag --
        /// Attaches a string tag to an entity.
        /// @param id : integer
        /// @param tag : string
        /// @return nil
        methods.add_method("addTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().add_tag(id, &tag);
            Ok(())
        });

        // -- removeTag --
        /// Removes a string tag from an entity.
        /// @param id : integer
        /// @param tag : string
        /// @return nil
        methods.add_method("removeTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().remove_tag(id, &tag);
            Ok(())
        });

        // -- hasTag --
        /// Returns true if the entity carries the given tag.
        /// @param id : integer
        /// @param tag : string
        /// @return boolean
        methods.add_method("hasTag", |_, this, (id, tag): (u32, String)| {
            Ok(this.inner.borrow().has_tag(id, &tag))
        });

        // -- getTags --
        /// Returns all string tags for an entity.
        /// @param id : integer
        /// @return table
        methods.add_method("getTags", |_, this, id: u32| {
            Ok(this.inner.borrow().get_tags(id))
        });

        // -- getEntitiesByTag --
        /// Returns all alive entities with the given string tag.
        /// @param tag : string
        /// @return table
        methods.add_method("getEntitiesByTag", |_, this, tag: String| {
            Ok(this.inner.borrow().get_entities_by_tag(&tag))
        });

        // -- setLayer --
        /// Sets the layer for an entity.
        /// @param id : integer
        /// @param layer : integer
        /// @return nil
        methods.add_method("setLayer", |_, this, (id, layer): (u32, i32)| {
            this.inner.borrow_mut().set_layer(id, layer);
            Ok(())
        });

        // -- getLayer --
        /// Returns the layer for an entity, defaulting to zero.
        /// @param id : integer
        /// @return integer
        methods.add_method("getLayer", |_, this, id: u32| {
            Ok(this.inner.borrow().get_layer(id))
        });

        // -- getEntitiesByLayer --
        /// Returns all alive entities on a specific layer.
        /// @param layer : integer
        /// @return table
        methods.add_method("getEntitiesByLayer", |_, this, layer: i32| {
            Ok(this.inner.borrow().get_entities_by_layer(layer))
        });

        // -- getEntitiesSorted --
        /// Returns all alive entities sorted by layer then ID.
        /// @return table
        methods.add_method("getEntitiesSorted", |_, this, ()| {
            Ok(this.inner.borrow().get_entities_sorted())
        });

        // -- defineTag --
        /// Defines a bitmap tag name, returning its bit index.
        /// @param name : string
        /// @return integer
        methods.add_method("defineTag", |_, this, name: String| {
            this.inner.borrow_mut().define_tag(&name)
        });

        // -- bitmapTag --
        /// Adds a bitmap tag to an entity.
        /// @param id : integer
        /// @param name : string
        /// @return nil
        methods.add_method("bitmapTag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_tag(id, &name)
        });

        // -- bitmapUntag --
        /// Removes a bitmap tag from an entity.
        /// @param id : integer
        /// @param name : string
        /// @return nil
        methods.add_method("bitmapUntag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_untag(id, &name);
            Ok(())
        });

        // -- hasBitmapTag --
        /// Returns true if the entity has the given bitmap tag.
        /// @param id : integer
        /// @param name : string
        /// @return boolean
        methods.add_method("hasBitmapTag", |_, this, (id, name): (u32, String)| {
            Ok(this.inner.borrow().has_bitmap_tag(id, &name))
        });

        // -- queryBitmapTag --
        /// Returns all alive entities with the given bitmap tag.
        /// @param name : string
        /// @return table
        methods.add_method("queryBitmapTag", |_, this, name: String| {
            Ok(this.inner.borrow().query_bitmap_tag(&name))
        });

        // -- queryBitmapAny --
        /// Returns all alive entities with any of the listed bitmap tags.
        /// @param names : table
        /// @return table
        methods.add_method("queryBitmapAny", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_any(&name_vec))
        });

        // -- queryBitmapAll --
        /// Returns all alive entities with all of the listed bitmap tags.
        /// @param names : table
        /// @return table
        methods.add_method("queryBitmapAll", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_all(&name_vec))
        });

        // -- getBitmapTagBit --
        /// Returns the bit index for a bitmap tag name, or nil if undefined.
        /// @param name : string
        /// @return integer?
        methods.add_method("getBitmapTagBit", |_, this, name: String| {
            Ok(this.inner.borrow().get_bitmap_tag_bit(&name))
        });

        // -- defineBlueprint --
        /// Defines a blueprint from a component table.
        /// @param name : string
        /// @param components : table
        /// @return nil
        methods.add_method(
            "defineBlueprint",
            |lua, this, (name, components): (String, LuaTable)| {
                this.inner.borrow_mut().define_blueprint(lua, &name, components)
            },
        );

        // -- extendBlueprint --
        /// Defines a blueprint by extending a parent with overrides.
        /// @param name : string
        /// @param parent : string
        /// @param overrides : table
        /// @return nil
        methods.add_method(
            "extendBlueprint",
            |lua, this, (name, parent, overrides): (String, String, LuaTable)| {
                this.inner
                    .borrow_mut()
                    .extend_blueprint(lua, &name, &parent, overrides)
            },
        );

        // -- spawnBlueprint --
        /// Spawns an entity from a blueprint with optional overrides.
        /// @param name : string
        /// @param overrides : table?
        /// @return integer
        methods.add_method(
            "spawnBlueprint",
            |lua, this, (name, overrides): (String, Option<LuaTable>)| {
                this.inner
                    .borrow_mut()
                    .spawn_blueprint(lua, &name, overrides)
            },
        );

        // -- hasBlueprint --
        /// Returns true if a blueprint with the given name exists.
        /// @param name : string
        /// @return boolean
        methods.add_method("hasBlueprint", |lua, this, name: String| {
            this.inner.borrow().has_blueprint(lua, &name)
        });

        // -- removeBlueprint --
        /// Removes a blueprint definition.
        /// @param name : string
        /// @return nil
        methods.add_method("removeBlueprint", |lua, this, name: String| {
            this.inner.borrow().remove_blueprint(lua, &name)
        });

        // -- listBlueprints --
        /// Returns all defined blueprint names.
        /// @return table
        methods.add_method("listBlueprints", |lua, this, ()| {
            this.inner.borrow().list_blueprints(lua)
        });

        // -- getBlueprintComponents --
        /// Returns a deep copy of a blueprint's component table, or nil.
        /// @param name : string
        /// @return table
        methods.add_method("getBlueprintComponents", |lua, this, name: String| {
            this.inner.borrow().get_blueprint_components(lua, &name)
        });

        // -- setParent --
        /// Sets or clears the parent of an entity.
        /// @param child_id : integer
        /// @param parent_id : integer?
        /// @return nil
        methods.add_method(
            "setParent",
            |_, this, (child_id, parent_id): (u32, Option<u32>)| {
                this.inner.borrow_mut().set_parent(child_id, parent_id);
                Ok(())
            },
        );

        // -- getParent --
        /// Returns the parent entity ID, or nil if unparented.
        /// @param child_id : integer
        /// @return integer?
        methods.add_method("getParent", |_, this, child_id: u32| {
            Ok(this.inner.borrow().get_parent(child_id))
        });

        // -- getChildren --
        /// Returns all direct child entity IDs.
        /// @param parent_id : integer
        /// @return table
        methods.add_method("getChildren", |_, this, parent_id: u32| {
            Ok(this.inner.borrow().get_children(parent_id))
        });

        // -- killRecursive --
        /// Kills an entity and all its descendants recursively.
        /// @param id : integer
        /// @return nil
        methods.add_method("killRecursive", |lua, this, id: u32| {
            this.inner.borrow_mut().kill_recursive(id, lua)
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.entity` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newUniverse --
    /// Creates a new empty ECS universe.
    /// @return Universe
    tbl.set(
        "newUniverse",
        lua.create_function(|_, ()| {
            Ok(LuaUniverse {
                inner: Rc::new(RefCell::new(Universe::new())),
            })
        })?,
    )?;

    luna.set("entity", tbl)?;
    Ok(())
}
