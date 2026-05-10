//! Shared Lua table helper functions for ECS and related modules.

use mlua::{Lua, Result as LuaResult, Table, Value as LuaValue};

/// Deep-copies a Lua table recursively.
pub fn deep_copy_table<'lua>(lua: &'lua Lua, t: &Table<'lua>) -> LuaResult<Table<'lua>> {
    let copy = lua.create_table()?;
    for pair in t.clone().pairs::<LuaValue, LuaValue>() {
        let (k, v) = pair?;
        let v_copy = match v {
            LuaValue::Table(ref inner) => LuaValue::Table(deep_copy_table(lua, inner)?),
            other => other,
        };
        copy.set(k, v_copy)?;
    }
    Ok(copy)
}
