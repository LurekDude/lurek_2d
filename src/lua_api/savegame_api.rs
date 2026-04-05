//! `luna.savegame` Lua API bindings.
//!
//! Auto-generated skeleton from `src/savegame/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaSaveManager ────────────────────────────────────────────────────────────

pub struct LuaSaveManager(/* TODO: add key + state fields */);


impl LuaSaveManager {
    /// Get the current schema version.
    ///
    ///
    /// @return integer
    pub fn schema_version(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get migration versions >=`from` and < current, in ascending order.
    ///
    /// @param from : integer
    /// @return table
    pub fn applicable_migrations(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Whether data is dirty.
    ///
    ///
    /// @return boolean
    pub fn is_dirty(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaSaveManager {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("schemaVersion", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("applicableMigrations", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isDirty", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("schemaVersion", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("applicableMigrations", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isDirty", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.savegame.* functions ──────────────────────────────────────────

/// Unregister a collector by name.
///
///
/// @param name : str
pub fn unregister(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the current schema version.
///
///
/// @param version : integer
pub fn set_schema_version(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Record a migration version key.
///
///
/// @param from_version : integer
pub fn add_migration(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Enable auto-save with interval and target slot.
///
///
/// @param interval : number
/// @param slot : impl Into<String>
pub fn enable_auto_save(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advance the auto-save timer. Returns `Some(slot)` if a save should trigger.
///
/// @param dt : number
/// @return string?
pub fn update(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Serialize a simple Lua-compatible value hierarchy into a `return { ... }` string.
///
/// Supports nil, bool, number (f64), string, and nested tables (HashMap).
/// Does not handle userdata, functions, or circular references.
///
/// @param data : HashMap<String, SaveValue>
/// @param depth : integer
/// @return Result<String
pub fn serialize_table(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Serialize a single value.
///
/// @param value : SaveValue
/// @param depth : integer
/// @return Result<String
pub fn serialize_value(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Unregister a collector by name. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// @param name : str
/// Set the current schema version. Replaces the current schema version value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param version : integer
/// Record a migration version key. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// @param from_version : integer
/// Enable auto-save with interval and target slot.
///
///
/// @param interval : number
/// @param slot : impl Into<String>
/// Advance the auto-save timer. Returns `Some(slot)` if a save should trigger.
///
/// @param dt : number
/// @return string?
/// Serialize a simple Lua-compatible value hierarchy into a `return { ... }` string.
///
/// @param data : HashMap<String, SaveValue>
/// @param depth : integer
/// @return Result<String
/// Serialize a single value. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param value : SaveValue
/// @param depth : integer
/// @return Result<String
/// Registers the `luna.savegame` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("unregister", lua.create_function(unregister)?)?;
    tbl.set("setSchemaVersion", lua.create_function(set_schema_version)?)?;
    tbl.set("addMigration", lua.create_function(add_migration)?)?;
    tbl.set("enableAutoSave", lua.create_function(enable_auto_save)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("serializeTable", lua.create_function(serialize_table)?)?;
    tbl.set("serializeValue", lua.create_function(serialize_value)?)?;
    tbl.set("unregister", lua.create_function(unregister)?)?;
    tbl.set("setSchemaVersion", lua.create_function(set_schema_version)?)?;
    tbl.set("addMigration", lua.create_function(add_migration)?)?;
    tbl.set("enableAutoSave", lua.create_function(enable_auto_save)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("serializeTable", lua.create_function(serialize_table)?)?;
    tbl.set("serializeValue", lua.create_function(serialize_value)?)?;
    luna.set("savegame", tbl)?;
    Ok(())
}
