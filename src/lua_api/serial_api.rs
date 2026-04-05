//! `luna.serial` Lua API bindings.
//!
//! Auto-generated skeleton from `src/serial/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::SharedState;

// ── luna.serial.* functions ──────────────────────────────────────────

/// Parse a CSV string into a `SerialValue`.
///
/// Returns a `SerialValue::Seq` of rows. Each row is a `SerialValue::Map`
/// keyed by column headers when `has_headers` is true, or a `SerialValue::Seq`
/// of string values otherwise.
///
///
/// # Parameters
/// - `s` — `str` ...
/// - `opts` — `CsvOptions` ...
///
/// # Returns
/// `Result<SerialValue`.
///
/// @param s : str
/// @param opts : CsvOptions
/// @return Result<SerialValue
pub fn from_csv(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Serialize a `SerialValue` to a CSV string.
///
/// Converts a `SerialValue::Seq` of `SerialValue::Map` rows to CSV.
///
///
/// # Parameters
/// - `val` — `SerialValue` ...
/// - `opts` — `CsvOptions` ...
///
/// # Returns
/// `Result<String`.
///
/// @param val : SerialValue
/// @param opts : CsvOptions
/// @return Result<String
pub fn to_csv(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a JSON string into a `SerialValue`.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Result<SerialValue`.
///
/// @param s : str
/// @return Result<SerialValue
pub fn from_json(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Serialize a `SerialValue` to a JSON string.
///
///
/// # Parameters
/// - `val` — `SerialValue` ...
/// - `pretty` — `boolean` ...
///
/// # Returns
/// `Result<String`.
///
/// @param val : SerialValue
/// @param pretty : boolean
/// @return Result<String
pub fn to_json(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a TOML string into a `SerialValue`.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Result<SerialValue`.
///
/// @param s : str
/// @return Result<SerialValue
pub fn from_toml(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Serialize a `SerialValue` to a TOML string.
///
///
/// # Parameters
/// - `val` — `SerialValue` ...
///
/// # Returns
/// `Result<String`.
///
/// @param val : SerialValue
/// @return Result<String
pub fn to_toml(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a YAML string into a `SerialValue`.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Result<SerialValue`.
///
/// @param s : str
/// @return Result<SerialValue
pub fn from_yaml(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Serialize a `SerialValue` to a YAML string.
///
///
/// # Parameters
/// - `val` — `SerialValue` ...
///
/// # Returns
/// `Result<String`.
///
/// @param val : SerialValue
/// @return Result<String
pub fn to_yaml(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.serial` API table.
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
    tbl.set("fromCsv", lua.create_function(from_csv)?)?;
    tbl.set("toCsv", lua.create_function(to_csv)?)?;
    tbl.set("fromJson", lua.create_function(from_json)?)?;
    tbl.set("toJson", lua.create_function(to_json)?)?;
    tbl.set("fromToml", lua.create_function(from_toml)?)?;
    tbl.set("toToml", lua.create_function(to_toml)?)?;
    tbl.set("fromYaml", lua.create_function(from_yaml)?)?;
    tbl.set("toYaml", lua.create_function(to_yaml)?)?;
    luna.set("serial", tbl)?;
    Ok(())
}
