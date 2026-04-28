//! `lurek.serial` - Format-agnostic string serialization for JSON, TOML, and CSV.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::serial::{
    lua_table::{from_lua, to_lua},
    CsvOptions,
};

// Extract the first byte from an optional delimiter string, defaulting to comma.
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
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- fromJson --
    /// Parses a JSON string and returns a Lua table.
    /// @param | s | string | JSON source text to parse.
    /// @return | table | Parsed Lua table representation.
    tbl.set(
        "fromJson",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_json(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;

    // -- toJson --
    /// Serializes a Lua value to a JSON string.
    /// @param | value | any | Lua value to serialize.
    /// @param | pretty | boolean? | Whether to format the output with indentation.
    /// @return | string | Serialized JSON string.
    tbl.set(
        "toJson",
        lua.create_function(|_, (value, pretty): (LuaValue, Option<bool>)| {
            let val = from_lua(&value)?;
            crate::serial::to_json(&val, pretty.unwrap_or(false)).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- fromToml --
    /// Parses a TOML string and returns a Lua table.
    /// @param | s | string | TOML source text to parse.
    /// @return | table | Parsed Lua table representation.
    tbl.set(
        "fromToml",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_toml(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;

    // -- toToml --
    /// Serializes a Lua table to a TOML string.
    /// @param | value | any | Lua value to serialize.
    /// @return | string | Serialized TOML string.
    tbl.set(
        "toToml",
        lua.create_function(|_, value: LuaValue| {
            let val = from_lua(&value)?;
            crate::serial::to_toml(&val).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- fromCsv --
    /// Parses a CSV string and returns a sequence of row tables.
    /// @param | s | string | CSV source text to parse.
    /// @param | delimiter | string? | Optional single-character field delimiter.
    /// @param | has_headers | boolean? | Whether the first row should be treated as headers.
    /// @return | table | Parsed sequence of row tables.
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
    /// @param | value | any | Sequence of row tables to serialize.
    /// @param | delimiter | string? | Optional single-character field delimiter.
    /// @param | has_headers | boolean? | Whether to emit a header row.
    /// @return | string | Serialized CSV string.
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
    /// @param | value | table | Lua table to encode.
    /// @return | string | Binary MessagePack payload.
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
    /// @param | bytes | string | Binary MessagePack payload.
    /// @return | table | Decoded Lua table.
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
    /// @param | s | string | XML source text to parse into nested element tables.
    /// @return | table | Parsed XML tree with tag, attrs, text, and children fields.
    tbl.set(
        "decodeXml",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_xml(&s).map_err(LuaError::RuntimeError)?;
            crate::serial::lua_table::to_lua(lua, &val)
        })?,
    )?;

    // -- validate --
    /// Validates a Lua table against a schema table.
    /// @param | value | any | Lua value to validate.
    /// @param | schema | table | Schema table describing the expected structure.
    /// @return | boolean | True when the value matches the schema.
    /// @return | string | Validation failure message.
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

    lurek.set("serial", tbl)?;
    Ok(())
}
