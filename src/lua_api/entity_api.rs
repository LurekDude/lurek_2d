//! `luna.entity` Lua API bindings.
//!
//! Auto-generated skeleton from `src/entity/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaRelationType ────────────────────────────────────────────────────────────

pub struct LuaRelationType(/* TODO: add key + state fields */);


impl LuaRelationType {
    /// Return `true` if `level` is a valid level for this type.
    ///
    ///
    /// # Parameters
    /// - `level` — `str` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param level : str
    /// @return boolean
    pub fn has_level(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaRelationType {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("hasLevel", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaRelationshipManager ────────────────────────────────────────────────────────────

pub struct LuaRelationshipManager(/* TODO: add key + state fields */);


impl LuaRelationshipManager {
    /// Get a reference to a relation type definition.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param name : str
    /// @return Option<
    pub fn get_type(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the names of all defined relation types.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn type_names(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the numeric relation value between two entities.
    ///
    ///
    /// # Parameters
    /// - `a` — `integer` ...
    /// - `b` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param a : integer
    /// @param b : integer
    /// @return number
    pub fn get_value(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the level for a relation type between two entities.
    ///
    /// Falls back to the type's `default_level` if no explicit level has been set.
    /// Returns `None` if the type name is unknown.
    ///
    ///
    /// # Parameters
    /// - `a` — `integer` ...
    /// - `b` — `integer` ...
    /// - `ype_name` — `str` ...
    ///
    /// # Returns
    /// `string?`.
    ///
    /// @param a : integer
    /// @param b : integer
    /// @param ype_name : str
    /// @return string?
    pub fn get_level(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return `true` if a relationship record exists for this pair.
    ///
    ///
    /// # Parameters
    /// - `a` — `integer` ...
    /// - `b` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param a : integer
    /// @param b : integer
    /// @return boolean
    pub fn has_relation(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get all relationships involving a given entity.
    ///
    ///
    /// # Parameters
    /// - `entity_id` — `integer` ...
    ///
    /// # Returns
    /// `Vec<`.
    ///
    /// @param entity_id : integer
    /// @return Vec<
    pub fn all_relations_for(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get all relationships as an iterator. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `impl`.
    ///
    /// @return impl
    pub fn all_relations(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the total number of relationship records.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn relation_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaRelationshipManager {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getType", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("typeNames", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getValue", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLevel", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasRelation", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("allRelationsFor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("allRelations", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("relationCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaUniverse ────────────────────────────────────────────────────────────

pub struct LuaUniverse(/* TODO: add key + state fields */);


impl LuaUniverse {
    /// get_system_store. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `lua` — `'lua Lua` ...
    ///
    /// # Returns
    /// `LuaResult<Table<`.
    ///
    /// @param lua : 'lua Lua
    /// @return LuaResult<Table<
    pub fn get_system_store(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the parent of `entity`, or `None` if unparented.
    ///
    ///
    /// # Parameters
    /// - `entity` — `integer` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param entity : integer
    /// @return integer?
    pub fn get_parent(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the direct children of `entity`. Returns an empty `Vec` if none.
    ///
    ///
    /// # Parameters
    /// - `entity` — `integer` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param entity : integer
    /// @return table
    pub fn get_children(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether an entity ID is currently alive.
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param id : integer
    /// @return boolean
    pub fn is_alive(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of alive entities. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_entity_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns all alive entity IDs (unordered).
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn get_entities(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether an entity has a named component.
    ///
    ///
    /// # Parameters
    /// - `lua` — `Lua` ...
    /// - `id` — `integer` ...
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `LuaResult<bool>`.
    ///
    /// @param lua : Lua
    /// @param id : integer
    /// @param name : str
    /// @return LuaResult<bool>
    pub fn has_component(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Removes a component from an entity. Returns the removed value if present, or `None` when the key did not exist.
    ///
    ///
    /// # Parameters
    /// - `lua` — `Lua` ...
    /// - `id` — `integer` ...
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `LuaResult<()>`.
    ///
    /// @param lua : Lua
    /// @param id : integer
    /// @param name : str
    /// @return LuaResult<()>
    pub fn remove_component(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all component names for an entity.
    ///
    ///
    /// # Parameters
    /// - `lua` — `Lua` ...
    /// - `id` — `integer` ...
    ///
    /// # Returns
    /// `LuaResult<Vec<String>>`.
    ///
    /// @param lua : Lua
    /// @param id : integer
    /// @return LuaResult<Vec<String>>
    pub fn get_component_names(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all alive entities that have ALL listed component names.
    ///
    ///
    /// # Parameters
    /// - `lua` — `Lua` ...
    /// - `names` — `[String]` ...
    ///
    /// # Returns
    /// `LuaResult<Vec<u32>>`.
    ///
    /// @param lua : Lua
    /// @param names : [String]
    /// @return LuaResult<Vec<u32>>
    pub fn query(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Calls `callback(id, value)` for every alive entity that has the named component.
    ///
    ///
    /// # Parameters
    /// - `lua` — `Lua` ...
    /// - `name` — `str` ...
    /// - `callback` — `Function` ...
    ///
    /// # Returns
    /// `LuaResult<()>`.
    ///
    /// @param lua : Lua
    /// @param name : str
    /// @param callback : Function
    /// @return LuaResult<()>
    pub fn each(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether an entity has a specific string tag.
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    /// - `tag` — `str` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param id : integer
    /// @param tag : str
    /// @return boolean
    pub fn has_tag(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all string tags for an entity. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param id : integer
    /// @return table
    pub fn get_tags(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all alive entities that have the given string tag.
    ///
    ///
    /// # Parameters
    /// - `tag` — `str` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param tag : str
    /// @return table
    pub fn get_entities_by_tag(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether an entity has a specific bitmap tag.
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param id : integer
    /// @param name : str
    /// @return boolean
    pub fn has_bitmap_tag(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all alive entities with the given bitmap tag.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param name : str
    /// @return table
    pub fn query_bitmap_tag(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all alive entities that have ANY of the listed bitmap tags.
    ///
    ///
    /// # Parameters
    /// - `names` — `[String]` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param names : [String]
    /// @return table
    pub fn query_bitmap_any(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all alive entities that have ALL of the listed bitmap tags.
    ///
    ///
    /// # Parameters
    /// - `names` — `[String]` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param names : [String]
    /// @return table
    pub fn query_bitmap_all(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the bit index for a bitmap tag name, if defined.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `u8?`.
    ///
    /// @param name : str
    /// @return u8?
    pub fn get_bitmap_tag_bit(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the layer for an entity (defaults to 0).
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param id : integer
    /// @return integer
    pub fn get_layer(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all alive entities on a specific layer.
    ///
    ///
    /// # Parameters
    /// - `layer` — `integer` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param layer : integer
    /// @return table
    pub fn get_entities_by_layer(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all alive entities sorted by layer (ascending), then by ID.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn get_entities_sorted(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether a blueprint with the given name exists.
    ///
    ///
    /// # Parameters
    /// - `lua` — `Lua` ...
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `LuaResult<bool>`.
    ///
    /// @param lua : Lua
    /// @param name : str
    /// @return LuaResult<bool>
    pub fn has_blueprint(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Removes a blueprint definition. Returns the removed value if present, or `None` when the key did not exist.
    ///
    ///
    /// # Parameters
    /// - `lua` — `Lua` ...
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `LuaResult<()>`.
    ///
    /// @param lua : Lua
    /// @param name : str
    /// @return LuaResult<()>
    pub fn remove_blueprint(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Lists all defined blueprint names. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Parameters
    /// - `lua` — `Lua` ...
    ///
    /// # Returns
    /// `LuaResult<Vec<String>>`.
    ///
    /// @param lua : Lua
    /// @return LuaResult<Vec<String>>
    pub fn list_blueprints(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of registered systems.
    ///
    ///
    /// # Parameters
    /// - `lua` — `Lua` ...
    ///
    /// # Returns
    /// `LuaResult<usize>`.
    ///
    /// @param lua : Lua
    /// @return LuaResult<usize>
    pub fn get_system_count(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaUniverse {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSystemStore", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getParent", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getChildren", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isAlive", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEntityCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEntities", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasComponent", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("removeComponent", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getComponentNames", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("query", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("each", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasTag", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTags", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEntitiesByTag", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasBitmapTag", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("queryBitmapTag", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("queryBitmapAny", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("queryBitmapAll", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBitmapTagBit", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLayer", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEntitiesByLayer", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEntitiesSorted", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasBlueprint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("removeBlueprint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("listBlueprints", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSystemCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.entity.* functions ──────────────────────────────────────────

/// Define a named relation type with a set of valid levels.
///
/// Replaces any existing type with the same name.
///
///
/// # Parameters
/// - `name` — `str` ...
/// - `levels` — `table` ...
/// - `default_level` — `str` ...
///
/// @param name : str
/// @param levels : table
/// @param default_level : str
pub fn define_type(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a relation type. Returns `true` if it existed.
///
/// Existing relationships keep their data but the removed type's levels
/// are cleaned from all records.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// # Returns
/// `boolean`.
///
/// @param name : str
/// @return boolean
pub fn remove_type(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the numeric relation value between two entities.
///
///
/// # Parameters
/// - `a` — `integer` ...
/// - `b` — `integer` ...
/// - `value` — `number` ...
///
/// @param a : integer
/// @param b : integer
/// @param value : number
pub fn set_value(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adjust the numeric relation value by `delta`.
///
///
/// # Parameters
/// - `a` — `integer` ...
/// - `b` — `integer` ...
/// - `delta` — `number` ...
///
/// @param a : integer
/// @param b : integer
/// @param delta : number
pub fn adjust_value(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the named level for a relation type between two entities.
///
/// Returns `false` if the type is unknown or the level is not valid for that type.
///
///
/// # Parameters
/// - `a` — `integer` ...
/// - `b` — `integer` ...
/// - `ype_name` — `str` ...
/// - `level` — `str` ...
///
/// # Returns
/// `boolean`.
///
/// @param a : integer
/// @param b : integer
/// @param ype_name : str
/// @param level : str
/// @return boolean
pub fn set_level(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a relationship record. Returns `true` if it existed.
///
///
/// # Parameters
/// - `a` — `integer` ...
/// - `b` — `integer` ...
///
/// # Returns
/// `boolean`.
///
/// @param a : integer
/// @param b : integer
/// @return boolean
pub fn remove_relation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Spawns a new entity and returns its ID. Recycles from the free list when possible.
///
///
/// # Returns
/// `integer`.
///
/// @return integer
pub fn spawn(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Kills an entity, cleaning up all associated data and recycling the ID.
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `lua` — `Lua` ...
///
/// # Returns
/// `LuaResult<()>`.
///
/// @param id : integer
/// @param lua : Lua
/// @return LuaResult<()>
pub fn kill(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets or clears the parent of `entity`. Pass `Some(parent_id)` to attach, `None` to detach.
///
///
/// # Parameters
/// - `entity` — `integer` ...
/// - `parent` — `integer?` ...
///
/// @param entity : integer
/// @param parent : integer?
pub fn set_parent(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Kills `root` and all of its descendants recursively.
///
///
/// # Parameters
/// - `root` — `integer` ...
/// - `lua` — `Lua` ...
///
/// # Returns
/// `LuaResult<()>`.
///
/// @param root : integer
/// @param lua : Lua
/// @return LuaResult<()>
pub fn kill_recursive(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets a component value on an entity. Replaces the current component value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `lua` — `Lua` ...
/// - `id` — `integer` ...
/// - `name` — `str` ...
/// - `value` — `any` ...
///
/// # Returns
/// `LuaResult<()>`.
///
/// @param lua : Lua
/// @param id : integer
/// @param name : str
/// @param value : any
/// @return LuaResult<()>
pub fn set_component(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Gets a component value from an entity (returns Nil if missing or dead).
///
///
/// # Parameters
/// - `lua` — `'lua Lua` ...
/// - `id` — `integer` ...
/// - `name` — `str` ...
///
/// # Returns
/// `LuaResult<LuaValue<`.
///
/// @param lua : 'lua Lua
/// @param id : integer
/// @param name : str
/// @return LuaResult<LuaValue<
pub fn get_component(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a string tag to an entity (no-op if already present or entity is dead).
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `tag` — `str` ...
///
/// @param id : integer
/// @param tag : str
pub fn add_tag(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a string tag from an entity. Returns the removed value if present, or `None` when the key did not exist.
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `tag` — `str` ...
///
/// @param id : integer
/// @param tag : str
pub fn remove_tag(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Defines a bitmap tag name, returning its bit index.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// # Returns
/// `LuaResult<u8>`.
///
/// @param name : str
/// @return LuaResult<u8>
pub fn define_tag(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a bitmap tag to an entity (auto-defines the tag if needed).
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `name` — `str` ...
///
/// # Returns
/// `LuaResult<()>`.
///
/// @param id : integer
/// @param name : str
/// @return LuaResult<()>
pub fn bitmap_tag(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a bitmap tag from an entity. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `name` — `str` ...
///
/// @param id : integer
/// @param name : str
pub fn bitmap_untag(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the layer for an entity (default layer is 0).
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `layer` — `integer` ...
///
/// @param id : integer
/// @param layer : integer
pub fn set_layer(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Defines a blueprint by deep-copying the given component table.
///
///
/// # Parameters
/// - `lua` — `Lua` ...
/// - `name` — `str` ...
/// - `components` — `Table` ...
///
/// # Returns
/// `LuaResult<()>`.
///
/// @param lua : Lua
/// @param name : str
/// @param components : Table
/// @return LuaResult<()>
pub fn define_blueprint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Defines a blueprint by extending a parent blueprint with overrides.
///
///
/// # Parameters
/// - `lua` — `Lua` ...
/// - `name` — `str` ...
/// - `parent` — `str` ...
/// - `overrides` — `Table` ...
///
/// # Returns
/// `LuaResult<()>`.
///
/// @param lua : Lua
/// @param name : str
/// @param parent : str
/// @param overrides : Table
/// @return LuaResult<()>
pub fn extend_blueprint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Spawns an entity from a blueprint, applying optional overrides.
///
///
/// # Parameters
/// - `lua` — `Lua` ...
/// - `name` — `str` ...
/// - `overrides` — `Table?` ...
///
/// # Returns
/// `LuaResult<u32>`.
///
/// @param lua : Lua
/// @param name : str
/// @param overrides : Table?
/// @return LuaResult<u32>
pub fn spawn_blueprint(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns a deep copy of a blueprint's component table, or Nil if not found.
///
///
/// # Parameters
/// - `lua` — `'lua Lua` ...
/// - `name` — `str` ...
///
/// # Returns
/// `LuaResult<LuaValue<`.
///
/// @param lua : 'lua Lua
/// @param name : str
/// @return LuaResult<LuaValue<
pub fn get_blueprint_components(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a system (Lua table) to the system list.
///
///
/// # Parameters
/// - `lua` — `Lua` ...
/// - `system` — `Table` ...
///
/// # Returns
/// `LuaResult<()>`.
///
/// @param lua : Lua
/// @param system : Table
/// @return LuaResult<()>
pub fn add_system(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a system by pointer identity from the system list.
///
///
/// # Parameters
/// - `lua` — `Lua` ...
/// - `system` — `Table` ...
///
/// # Returns
/// `LuaResult<()>`.
///
/// @param lua : Lua
/// @param system : Table
/// @return LuaResult<()>
pub fn remove_system(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Clears all entities, components, tags, layers, and systems. Blueprints are preserved.
///
///
/// # Parameters
/// - `lua` — `Lua` ...
///
/// # Returns
/// `LuaResult<()>`.
///
/// @param lua : Lua
/// @return LuaResult<()>
pub fn clear(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Deep-copies a Lua table recursively. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `lua` — `'lua Lua` ...
/// - `t` — `Table<'lua>` ...
///
/// # Returns
/// `LuaResult<Table<`.
///
/// @param lua : 'lua Lua
/// @param t : Table<'lua>
/// @return LuaResult<Table<
pub fn deep_copy_table(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.entity` API table.
///
/// # Parameters
/// - `lua` — `&Lua` The Lua VM.
/// - `luna` — `&LuaTable<'_>` The top-level `luna` table.
/// - `state` — `Rc<RefCell<SharedState>>` Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("defineType", lua.create_function(define_type)?)?;
    tbl.set("removeType", lua.create_function(remove_type)?)?;
    tbl.set("setValue", lua.create_function(set_value)?)?;
    tbl.set("adjustValue", lua.create_function(adjust_value)?)?;
    tbl.set("setLevel", lua.create_function(set_level)?)?;
    tbl.set("removeRelation", lua.create_function(remove_relation)?)?;
    tbl.set("spawn", lua.create_function(spawn)?)?;
    tbl.set("kill", lua.create_function(kill)?)?;
    tbl.set("setParent", lua.create_function(set_parent)?)?;
    tbl.set("killRecursive", lua.create_function(kill_recursive)?)?;
    tbl.set("setComponent", lua.create_function(set_component)?)?;
    tbl.set("getComponent", lua.create_function(get_component)?)?;
    tbl.set("addTag", lua.create_function(add_tag)?)?;
    tbl.set("removeTag", lua.create_function(remove_tag)?)?;
    tbl.set("defineTag", lua.create_function(define_tag)?)?;
    tbl.set("bitmapTag", lua.create_function(bitmap_tag)?)?;
    tbl.set("bitmapUntag", lua.create_function(bitmap_untag)?)?;
    tbl.set("setLayer", lua.create_function(set_layer)?)?;
    tbl.set("defineBlueprint", lua.create_function(define_blueprint)?)?;
    tbl.set("extendBlueprint", lua.create_function(extend_blueprint)?)?;
    tbl.set("spawnBlueprint", lua.create_function(spawn_blueprint)?)?;
    tbl.set("getBlueprintComponents", lua.create_function(get_blueprint_components)?)?;
    tbl.set("addSystem", lua.create_function(add_system)?)?;
    tbl.set("removeSystem", lua.create_function(remove_system)?)?;
    tbl.set("clear", lua.create_function(clear)?)?;
    tbl.set("deepCopyTable", lua.create_function(deep_copy_table)?)?;
    luna.set("entity", tbl)?;
    Ok(())
}
