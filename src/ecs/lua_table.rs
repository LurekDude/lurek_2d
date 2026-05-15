//! - Deep-copy utility for Lua tables via mlua.
//! - Recursively clones nested table structures by value.
//! - Used by ECS and other systems that need independent table snapshots.

use mlua::{Lua, Result as LuaResult, Table, Value as LuaValue};

/// Recursively clone a Lua table, preserving nested table structure by value.
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
