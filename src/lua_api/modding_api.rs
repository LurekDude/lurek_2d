//! `luna.modding` Lua API bindings.
//!
//! Auto-generated skeleton from `src/modding/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaModManager ────────────────────────────────────────────────────────────

pub struct LuaModManager(/* TODO: add key + state fields */);


impl LuaModManager {
    /// Get a reference to a mod by ID.
    ///
    /// @param id : str
    /// @return Option<
    pub fn get_mod(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Check if a mod is registered. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// @param id : str
    /// @return boolean
    pub fn has_mod(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of registered mods. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return integer
    pub fn mod_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get mods in their effective load order. Returns an error if the source data is malformed or missing.
    ///
    ///
    /// @return Vec<
    pub fn load_order(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns a reference to the current custom load order, if any.
    ///
    ///
    /// @return Option<
    pub fn get_custom_load_order(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// List mod IDs whose dependencies are missing.
    ///
    ///
    /// @return table
    pub fn validate_dependencies(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Check for circular dependency cycles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return boolean
    pub fn has_circular_dependencies(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaModManager {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getMod", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasMod", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("modCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("loadOrder", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCustomLoadOrder", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("validateDependencies", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasCircularDependencies", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.modding.* functions ──────────────────────────────────────────

/// Register a mod with the manager. Panics in debug mode if the same entity is registered twice.
///
///
/// @param info : ModInfo
pub fn register_mod(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a mod by ID. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param id : str
/// @return boolean
pub fn unregister_mod(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Get a mutable reference to a mod by ID.
///
/// @param id : str
/// @return Option<
pub fn get_mod_mut(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set an explicit load order by providing a list of mod IDs.
///
///
/// @param order : table
pub fn set_load_order(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Scan a directory for mods and register them.
///
/// @param path : str
/// @return table
pub fn scan_folder(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Mark a registered mod for hot-reload. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param id : str
/// @return boolean
pub fn mark_for_reload(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.modding` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("registerMod", lua.create_function(register_mod)?)?;
    tbl.set("unregisterMod", lua.create_function(unregister_mod)?)?;
    tbl.set("getModMut", lua.create_function(get_mod_mut)?)?;
    tbl.set("setLoadOrder", lua.create_function(set_load_order)?)?;
    tbl.set("scanFolder", lua.create_function(scan_folder)?)?;
    tbl.set("markForReload", lua.create_function(mark_for_reload)?)?;
    luna.set("modding", tbl)?;
    Ok(())
}
