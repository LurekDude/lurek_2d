//! `lurek.serial` â€” Format-agnostic string serialization: JSON, TOML, and CSV.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::serial::{
    lua_table::{from_lua, to_lua},
    CsvOptions,
};

/// Extract the first byte from an optional delimiter string, defaulting to comma.
fn parse_delimiter(delim: Option<String>) -> u8 {
    delim
        .as_deref()
        .and_then(|d| d.as_bytes().first().copied())
        .unwrap_or(b',')
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.serial` API table with the Lua VM.
///
/// @param lua : &Lua
/// @param lurek : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- fromJson --
    /// Parses a JSON string and returns a Lua table.
    /// @param s : string
    /// @return table
    tbl.set(
        "fromJson",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_json(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;

    // -- toJson --
    /// Serializes a Lua value to a JSON string.
    /// @param value : table
    /// @param pretty : boolean?
    /// @return string
    tbl.set(
        "toJson",
        lua.create_function(|_, (value, pretty): (LuaValue, Option<bool>)| {
            let val = from_lua(&value)?;
            crate::serial::to_json(&val, pretty.unwrap_or(false)).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- fromToml --
    /// Parses a TOML string and returns a Lua table.
    /// @param s : string
    /// @return table
    tbl.set(
        "fromToml",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_toml(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;

    // -- toToml --
    /// Serializes a Lua table to a TOML string.
    /// @param value : table
    /// @return string
    tbl.set(
        "toToml",
        lua.create_function(|_, value: LuaValue| {
            let val = from_lua(&value)?;
            crate::serial::to_toml(&val).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- fromCsv --
    /// Parses a CSV string and returns a sequence of row tables.
    /// @param s : string
    /// @param delimiter : string?
    /// @param has_headers : boolean?
    /// @return table
    tbl.set(
        "fromCsv",
        lua.create_function(
            |lua, (s, delim, headers): (String, Option<String>, Option<bool>)| {
                let opts = CsvOptions {
                    delimiter: parse_delimiter(delim),
                    has_headers: headers.unwrap_or(true),
                };
                let val = crate::serial::from_csv(&s, opts).map_err(LuaError::RuntimeError)?;
                to_lua(lua, &val)
            },
        )?,
    )?;

    // -- toCsv --
    /// Serializes a sequence of row tables to a CSV string.
    /// @param value : table
    /// @param delimiter : string?
    /// @param has_headers : boolean?
    /// @return string
    tbl.set(
        "toCsv",
        lua.create_function(
            |_, (value, delim, headers): (LuaValue, Option<String>, Option<bool>)| {
                let opts = CsvOptions {
                    delimiter: parse_delimiter(delim),
                    has_headers: headers.unwrap_or(true),
                };
                let val = from_lua(&value)?;
                crate::serial::to_csv(&val, opts).map_err(LuaError::RuntimeError)
            },
        )?,
    )?;

    // -- encodeMsgPack --
    /// Encodes a Lua table to a binary MessagePack string.
    /// @param value : table
    /// @return string
    tbl.set(
        "encodeMsgPack",
        lua.create_function(|lua, value: LuaValue| {
            if !matches!(value, LuaValue::Table(_)) {
                return Err(LuaError::RuntimeError(
                    "encodeMsgPack: argument must be a table".to_string(),
                ));
            }
            let val = from_lua(&value)?;
            let bytes = crate::serial::to_msgpack(&val).map_err(LuaError::RuntimeError)?;
            lua.create_string(&bytes)
        })?,
    )?;

    // -- decodeMsgPack --
    /// Decodes a binary MessagePack string into a Lua table.
    /// @param bytes : string
    /// @return table
    tbl.set(
        "decodeMsgPack",
        lua.create_function(|lua, bytes: mlua::String| {
            let val =
                crate::serial::from_msgpack(bytes.as_bytes()).map_err(LuaError::RuntimeError)?;
            crate::serial::lua_table::to_lua(lua, &val)
        })?,
    )?;

    // -- decodeXml --
    /// Parses an XML string and returns a nested Lua table.
    ///
    /// Each element becomes a table with keys: `tag` (string), `attrs` (table, optional),
    /// `text` (string, optional), `children` (sequence, optional).
    /// @param s : string
    /// @return table
    tbl.set(
        "decodeXml",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_xml(&s).map_err(LuaError::RuntimeError)?;
            crate::serial::lua_table::to_lua(lua, &val)
        })?,
    )?;

    // -- validate --
    /// Validates a Lua table against a schema table.
    ///
    /// Returns `true` on success, or `false` plus an error message string on failure.
    /// @param value  : table
    /// @param schema : table
    /// boolean, string?
    tbl.set(
        "validate",
        lua.create_function(|_, (value, schema): (LuaValue, LuaValue)| {
            let val = from_lua(&value)?;
            let sch = from_lua(&schema)?;
            match crate::serial::validate_schema(&val, &sch) {
                Ok(()) => Ok((true, None::<String>)),
                Err(msg) => Ok((false, Some(msg))),
            }
        })?,
    )?;

    /// Namespace containing the serial API module.
    /// Provides serialization primitives and configuration parsers.
    lurek.set("serial", tbl)?;
    Ok(())
}
