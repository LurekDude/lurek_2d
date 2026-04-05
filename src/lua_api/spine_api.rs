//! `luna.spine` Lua API bindings.
//!
//! Auto-generated skeleton from `src/spine/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaSkeleton ────────────────────────────────────────────────────────────

pub struct LuaSkeleton(/* TODO: add key + state fields */);


impl LuaSkeleton {
    /// Finds a bone by name and returns its index.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param name : str
    /// @return integer?
    pub fn find_bone(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Finds a slot by name and returns its index.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param name : str
    /// @return integer?
    pub fn find_slot(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaSkeleton {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("findBone", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("findSlot", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.spine.* functions ──────────────────────────────────────────

/// Creates a bone with a parent index and local offset.
///
///
/// # Parameters
/// - `name` — `impl Into<String>` ...
/// - `parent` — `integer` ...
/// - `x` — `number` ...
/// - `y` — `number` ...
///
/// # Returns
/// `Bone`.
///
/// @param name : impl Into<String>
/// @param parent : integer
/// @param x : number
/// @param y : number
/// @return Bone
pub fn with_parent(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a bone to the skeleton and returns its index.
///
/// Bones must be added in topological order (parent before child).
///
///
/// # Parameters
/// - `bone` — `Bone` ...
///
/// # Returns
/// `integer`.
///
/// @param bone : Bone
/// @return integer
pub fn add_bone(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a slot to the skeleton and returns its index.
///
///
/// # Parameters
/// - `slot` — `Slot` ...
///
/// # Returns
/// `integer`.
///
/// @param slot : Slot
/// @return integer
pub fn add_slot(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.spine` API table.
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
    tbl.set("withParent", lua.create_function(with_parent)?)?;
    tbl.set("addBone", lua.create_function(add_bone)?)?;
    tbl.set("addSlot", lua.create_function(add_slot)?)?;
    luna.set("spine", tbl)?;
    Ok(())
}
