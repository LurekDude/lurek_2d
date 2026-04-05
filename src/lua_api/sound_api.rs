//! `luna.sound` Lua API bindings.
//!
//! Auto-generated stub. Fill in `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::SharedState;

/// Registers the `luna.sound` API table.
///
/// @param lua : &Lua
/// @param luna : &LuaTable<'_>
/// @param state : Rc<RefCell<SharedState>>
/// @return LuaResult<()>
pub fn register(lua: &Lua, luna: &LuaTable<'_>, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    luna.set("sound", tbl)?;
    Ok(())
}
