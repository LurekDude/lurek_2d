//! `lurek.serial` - Format-agnostic string serialization for JSON, TOML, and CSV.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::serial::{
    codec::{DecodeOptions, EncodeOptions, EncodedValue, SerialFormat},
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

fn csv_options_from_table(opts: Option<LuaTable>) -> LuaResult<CsvOptions> {
    let mut out = CsvOptions::default();
    if let Some(t) = opts {
        let delim: Option<String> = t.get("delimiter")?;
        let headers: Option<bool> = t.get("has_headers")?;
        out.delimiter = parse_delimiter(delim);
        out.has_headers = headers.unwrap_or(true);
    }
    Ok(out)
}

fn encode_options_from_table(opts: Option<LuaTable>) -> LuaResult<EncodeOptions> {
    let mut out = EncodeOptions::default();
    if let Some(t) = opts {
        let pretty: Option<bool> = t.get("pretty")?;
        out.json_pretty = pretty.unwrap_or(false);
        out.csv = csv_options_from_table(Some(t))?;
    }
    Ok(out)
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

    // -- fromIni --
    /// Parses an INI string and returns a Lua table.
    /// @param | s | string | INI source text to parse.
    /// @return | table | Parsed Lua table representation.
    tbl.set(
        "fromIni",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_ini(&s).map_err(LuaError::RuntimeError)?;
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

    // -- detectFormat --
    /// Detects input text format (`json`, `toml`, `csv`, or `xml`).
    /// @param | s | string | UTF-8 text payload to inspect.
    /// @return | string? | Detected format name or nil when unknown.
    tbl.set(
        "detectFormat",
        lua.create_function(|_, s: String| {
            Ok(crate::serial::detect_format(&s).map(|f| f.as_str().to_string()))
        })?,
    )?;

    // -- decode --
    /// Decodes input payload with explicit or auto-detected format.
    /// @param | payload | string | UTF-8 text (json/toml/csv/xml) or binary bytes for msgpack.
    /// @param | format | string? | Optional format: `json`, `toml`, `csv`, `xml`, `ini`, `msgpack`. Nil enables auto-detect (text only).
    /// @param | opts | table? | Optional options table: `delimiter`, `has_headers` (CSV).
    /// @return | table | Decoded Lua value tree.
    tbl.set(
        "decode",
        lua.create_function(
            |lua, (payload, format, opts): (LuaValue, Option<String>, Option<LuaTable>)| {
                let fmt = if let Some(name) = format.as_deref() {
                    Some(SerialFormat::parse(name).ok_or_else(|| {
                        LuaError::RuntimeError(
                            "decode: unknown format (expected json/toml/csv/xml/ini/msgpack)"
                                .to_string(),
                        )
                    })?)
                } else {
                    None
                };

                let val = match (payload, fmt) {
                    (LuaValue::String(bytes), Some(SerialFormat::MsgPack)) => {
                        crate::serial::decode_bytes(bytes.as_bytes().as_ref(), SerialFormat::MsgPack)
                            .map_err(LuaError::RuntimeError)?
                    }
                    (LuaValue::String(text), Some(f)) => {
                        let s = text
                            .to_str()
                            .map_err(|e| LuaError::RuntimeError(format!("decode: expected UTF-8 text: {e}")))?
                            .to_string();
                        crate::serial::decode_text(
                            &s,
                            Some(f),
                            DecodeOptions {
                                csv: csv_options_from_table(opts)?,
                            },
                        )
                        .map_err(LuaError::RuntimeError)?
                    }
                    (LuaValue::String(text), None) => {
                        let s = text
                            .to_str()
                            .map_err(|e| LuaError::RuntimeError(format!("decode: expected UTF-8 text for auto-detect: {e}")))?
                            .to_string();
                        crate::serial::decode_text(
                            &s,
                            None,
                            DecodeOptions {
                                csv: csv_options_from_table(opts)?,
                            },
                        )
                        .map_err(LuaError::RuntimeError)?
                    }
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "decode: payload must be a string".to_string(),
                        ));
                    }
                };

                to_lua(lua, &val)
            },
        )?,
    )?;

    // -- encode --
    /// Encodes a Lua value using the selected format.
    /// @param | value | any | Lua value to encode.
    /// @param | format | string | Format: `json`, `toml`, `csv`, or `msgpack`.
    /// @param | opts | table? | Optional options table: `pretty` (JSON), `delimiter` and `has_headers` (CSV).
    /// @return | string | Encoded UTF-8 text or binary bytes string for msgpack.
    tbl.set(
        "encode",
        lua.create_function(|lua, (value, format, opts): (LuaValue, String, Option<LuaTable>)| {
            let val = from_lua(&value)?;
            let fmt = SerialFormat::parse(&format).ok_or_else(|| {
                LuaError::RuntimeError(
                    "encode: unknown format (expected json/toml/csv/msgpack)".to_string(),
                )
            })?;
            let encoded = crate::serial::encode(&val, fmt, encode_options_from_table(opts)?)
                .map_err(LuaError::RuntimeError)?;

            match encoded {
                EncodedValue::Text(s) => lua.create_string(&s),
                EncodedValue::Binary(bytes) => lua.create_string(&bytes),
            }
        })?,
    )?;

    // -- applyDefaults --
    /// Applies schema `default` values recursively to a Lua value tree.
    /// @param | value | any | Lua value to patch.
    /// @param | schema | table | Schema table that may include `default`, `fields`, and `items`.
    /// @return | table | Patched value tree with defaults applied.
    tbl.set(
        "applyDefaults",
        lua.create_function(|lua, (value, schema): (LuaValue, LuaValue)| {
            let val = from_lua(&value)?;
            let sch = from_lua(&schema)?;
            let patched = crate::serial::apply_schema_defaults(&val, &sch)
                .map_err(LuaError::RuntimeError)?;
            to_lua(lua, &patched)
        })?,
    )?;

    lurek.set("serial", tbl)?;
    Ok(())
}
