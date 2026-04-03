//! Registers the `luna.entity.*` ECS universe API.
//!
//! Exposes `Universe` as Lua UserData (`LuaUniverse`) with entity lifecycle,
//! component operations, querying, systems, tags, layers, and blueprints.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for entity api-related operations and data management.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::entity::Universe;

use super::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// LuaUniverse
// ---------------------------------------------------------------------------

/// Lua wrapper around a [`Universe`] ECS world.
#[derive(Clone)]
struct LuaUniverse {
    inner: Rc<RefCell<Universe>>,
}

impl LunaType for LuaUniverse {
    const TYPE_NAME: &'static str = "Universe";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Universe", "Object"];
}

impl LuaUserData for LuaUniverse {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // === Entity Lifecycle ===

        /// Creates a new entity in this universe and returns its numeric ID.
        /// @return any
        ///
        /// # Returns
        /// `integer` — entity ID.
        methods.add_method("spawn", |_, this, ()| Ok(this.inner.borrow_mut().spawn()));

        /// Destroys the entity with the given `id`, freeing its slot for reuse.
        /// @param id : integer
        ///
        /// # Parameters
        /// - `id` — `integer`: Entity ID returned by `spawn`.
        methods.add_method("kill", |lua, this, id: u32| {
            this.inner.borrow_mut().kill(id, lua)
        });

        /// Returns `true` if the entity `id` is currently active in the universe.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`: Entity ID to test.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isAlive", |_, this, id: u32| {
            Ok(this.inner.borrow().is_alive(id))
        });

        // === Component Operations ===

        methods.add_method(
            "set",
            |lua, this, (id, name, value): (u32, String, LuaValue)| {
                this.inner.borrow_mut().set_component(lua, id, &name, value)
            },
        );

        /// Returns the current value.
        /// @param id : integer
        /// @param name : string
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current get.
        methods.add_method("get", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().get_component(lua, id, &name)
        });

        /// Returns `true` if the condition is met.
        /// @param id : integer
        /// @param name : string
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("has", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().has_component(lua, id, &name)
        });

        /// Removes the entry from the collection.
        /// @param id : integer
        /// @param name : string
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `name` — `string`.
        methods.add_method("remove", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().remove_component(lua, id, &name)
        });

        /// Returns the components.
        /// @param id : integer
        ///
        /// # Parameters
        /// - `id` — `integer`.
        ///
        /// # Returns
        /// The current components.
        methods.add_method("getComponents", |lua, this, id: u32| {
            this.inner.borrow().get_component_names(lua, id)
        });

        // === Querying ===

        /// Runs a query and returns matching results.
        /// @param args : MultiValue
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
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

        /// Returns the entities.
        /// @return any
        ///
        /// # Returns
        /// The current entities.
        methods.add_method("getEntities", |_, this, ()| {
            Ok(this.inner.borrow().get_entities())
        });

        /// Returns the entity count.
        /// @return any
        ///
        /// # Parameters
        /// - `system` — `table`.
        ///
        /// # Returns
        /// The current entity count.
        methods.add_method("getEntityCount", |_, this, ()| {
            Ok(this.inner.borrow().get_entity_count())
        });

        // === System Management ===

        /// Adds system to the collection.
        /// @param system : table
        ///
        /// # Parameters
        /// - `system` — `table`.
        methods.add_method("addSystem", |lua, this, system: LuaTable| {
            this.inner.borrow_mut().add_system(lua, system)
        });

        /// Removes system from the collection.
        /// @param system : table
        ///
        /// # Parameters
        /// - `system` — `table`.
        methods.add_method("removeSystem", |lua, this, system: LuaTable| {
            this.inner.borrow_mut().remove_system(lua, system)
        });

        /// Advances the simulation by `dt` seconds.
        /// @param dt : number
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("update", |lua, this, dt: f64| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let store = this.inner.borrow().get_system_store(lua)?;
            let world_clone = this.clone();
            for i in 1..=count {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>("update") {
                    func.call::<_, ()>((system.clone(), world_clone.clone(), dt))?;
                }
            }
            Ok(())
        });

        /// Draws to the current render target.
        ///
        /// # Returns
        /// The result.
        methods.add_method("draw", |lua, this, ()| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let store = this.inner.borrow().get_system_store(lua)?;
            let world_clone = this.clone();
            for i in 1..=count {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>("draw") {
                    func.call::<_, ()>((system.clone(), world_clone.clone()))?;
                }
            }
            Ok(())
        });

        /// Emits an event.
        /// @param args : MultiValue
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
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
            let world_clone = this.clone();
            for i in 1..=count {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>(event.as_str()) {
                    let mut call_args = Vec::with_capacity(2 + extra_args.len());
                    call_args.push(LuaValue::Table(system.clone()));
                    call_args.push(LuaValue::UserData(
                        lua.create_userdata(world_clone.clone())?,
                    ));
                    call_args.extend(extra_args.iter().cloned());
                    func.call::<_, ()>(LuaMultiValue::from_vec(call_args))?;
                }
            }
            Ok(())
        });

        /// Returns the system count.
        ///
        /// # Returns
        /// The current system count.
        methods.add_method("getSystemCount", |lua, this, ()| {
            this.inner.borrow().get_system_count(lua)
        });

        // === Lifecycle/Reset ===

        /// Removes all entries.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clear", |lua, this, ()| this.inner.borrow_mut().clear(lua));

        /// Releases the underlying resource handle.
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `tag` — `string`.
        methods.add_method("release", |lua, this, ()| {
            this.inner.borrow_mut().clear(lua)
        });

        // === String Tags ===

        /// Attaches a string tag to the entity, enabling fast tag-based group queries.
        /// @param id : integer
        /// @param tag : string
        ///
        /// # Parameters
        /// - `id` — `integer`: Entity ID.
        /// - `tag` — `string`: Tag label to add.
        methods.add_method("addTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().add_tag(id, &tag);
            Ok(())
        });

        /// Removes a string tag from the entity.
        /// @param id : integer
        /// @param tag : string
        ///
        /// # Parameters
        /// - `id` — `integer`: Entity ID.
        /// - `tag` — `string`: Tag to remove.
        methods.add_method("removeTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().remove_tag(id, &tag);
            Ok(())
        });

        /// Returns `true` if the entity carries the given tag.
        /// @param id : integer
        /// @param tag : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`: Entity ID.
        /// - `tag` — `string`: Tag to test.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTag", |_, this, (id, tag): (u32, String)| {
            Ok(this.inner.borrow().has_tag(id, &tag))
        });

        /// Returns the tags.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`.
        ///
        /// # Returns
        /// The current tags.
        methods.add_method("getTags", |_, this, id: u32| {
            Ok(this.inner.borrow().get_tags(id))
        });

        /// Returns the entities by tag.
        /// @param tag : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `layer` — `integer`.
        ///
        /// # Returns
        /// The current entities by tag.
        methods.add_method("getEntitiesByTag", |_, this, tag: String| {
            Ok(this.inner.borrow().get_entities_by_tag(&tag))
        });

        // === Layer System ===

        /// Sets the layer.
        /// @param id : integer
        /// @param layer : integer
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `layer` — `integer`.
        methods.add_method("setLayer", |_, this, (id, layer): (u32, i32)| {
            this.inner.borrow_mut().set_layer(id, layer);
            Ok(())
        });

        /// Returns the layer.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`.
        ///
        /// # Returns
        /// The current layer.
        methods.add_method("getLayer", |_, this, id: u32| {
            Ok(this.inner.borrow().get_layer(id))
        });

        /// Returns the entities by layer.
        /// @param layer : integer
        /// @return any
        ///
        /// # Parameters
        /// - `layer` — `integer`.
        ///
        /// # Returns
        /// The current entities by layer.
        methods.add_method("getEntitiesByLayer", |_, this, layer: i32| {
            Ok(this.inner.borrow().get_entities_by_layer(layer))
        });

        /// Returns the entities sorted.
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current entities sorted.
        methods.add_method("getEntitiesSorted", |_, this, ()| {
            Ok(this.inner.borrow().get_entities_sorted())
        });

        // === Bitmap Tags ===

        /// Define tag on this Universe.
        /// @param name : string
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `name` — `string`.
        methods.add_method("defineTag", |_, this, name: String| {
            this.inner.borrow_mut().define_tag(&name)
        });

        /// Bitmap tag on this Universe.
        /// @param id : integer
        /// @param name : string
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `name` — `string`.
        methods.add_method("bitmapTag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_tag(id, &name)
        });

        /// Bitmap untag on this Universe.
        /// @param id : integer
        /// @param name : string
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `name` — `string`.
        methods.add_method("bitmapUntag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_untag(id, &name);
            Ok(())
        });

        /// Returns `true` if bitmap tag.
        /// @param id : integer
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasBitmapTag", |_, this, (id, name): (u32, String)| {
            Ok(this.inner.borrow().has_bitmap_tag(id, &name))
        });

        /// Query bitmap tag on this Universe.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("queryBitmapTag", |_, this, name: String| {
            Ok(this.inner.borrow().query_bitmap_tag(&name))
        });

        /// Query bitmap any on this Universe.
        /// @param names : table
        /// @return any
        ///
        /// # Parameters
        /// - `names` — `table`.
        methods.add_method("queryBitmapAny", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_any(&name_vec))
        });

        /// Query bitmap all on this Universe.
        /// @param names : table
        /// @return any
        ///
        /// # Parameters
        /// - `names` — `table`.
        methods.add_method("queryBitmapAll", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_all(&name_vec))
        });

        /// Returns the bitmap tag bit.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current bitmap tag bit.
        methods.add_method("getBitmapTagBit", |_, this, name: String| {
            Ok(this.inner.borrow().get_bitmap_tag_bit(&name))
        });

        // === Blueprints ===

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

        /// Returns `true` if blueprint.
        /// @param name : string
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasBlueprint", |lua, this, name: String| {
            this.inner.borrow().has_blueprint(lua, &name)
        });

        /// Removes blueprint from the collection.
        /// @param name : string
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("removeBlueprint", |lua, this, name: String| {
            this.inner.borrow().remove_blueprint(lua, &name)
        });

        /// List blueprints on this Universe.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("listBlueprints", |lua, this, ()| {
            this.inner.borrow().list_blueprints(lua)
        });

        /// Returns the blueprint components.
        /// @param name : string
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current blueprint components.
        methods.add_method("getBlueprintComponents", |lua, this, name: String| {
            this.inner.borrow().get_blueprint_components(lua, &name)
        });
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.entity` table with the `newUniverse` factory function.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let entity = lua.create_table()?;

    /// New universe.
    ///
    /// @return any
    entity.set(
        "newUniverse",
        lua.create_function(|_lua, ()| {
            Ok(LuaUniverse {
                inner: Rc::new(RefCell::new(Universe::new())),
            })
        })?,
    )?;

    /// Entity on this Universe.
    ///
    /// # Returns
    /// The result.
    luna.set("entity", entity)?;
    Ok(())
}
