//! `lurek.serial` — Data serialization and deserialization with JSON, TOML, CSV, XML, INI, and MessagePack encoding/decoding for game configuration, save data, and inter-system data exchange.

use super::SharedState;
use crate::serial::{
    codec::{DecodeOptions, EncodeOptions, EncodedValue, SerialFormat},
    lua_table::{from_lua, to_lua},
    CsvOptions,
};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
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
/// Registers the `lurek.serial` module into the Lua runtime.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- fromJson --
    /// Parses a JSON string into a Lua table. Use this to load configuration files, network responses, or any structured data stored as JSON.
    /// @param | text | string | A valid JSON string to parse.
    /// @return | table | The decoded Lua table representing the JSON structure.
    tbl.set(
        "fromJson",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_json(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;

    // -- toJson --
    /// Serializes a Lua value (table, string, number, boolean, or nil) into a JSON string. Useful for saving game state, writing config files, or preparing network payloads.
    /// @param | value | table | The Lua value to serialize into JSON.
    /// @param | pretty | boolean? | When true, outputs indented human-readable JSON. Defaults to false (compact).
    /// @return | string | The JSON-encoded string representation of the value.
    tbl.set(
        "toJson",
        lua.create_function(|_, (value, pretty): (LuaValue, Option<bool>)| {
            let val = from_lua(&value)?;
            crate::serial::to_json(&val, pretty.unwrap_or(false)).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- fromToml --
    /// Parses a TOML string into a Lua table. Ideal for loading game configuration files, level definitions, and engine settings stored in TOML format.
    /// @param | text | string | A valid TOML string to parse.
    /// @return | table | The decoded Lua table representing the TOML structure.
    tbl.set(
        "fromToml",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_toml(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;

    // -- fromIni --
    /// Parses an INI-format string into a Lua table. Sections become nested tables, and key-value pairs become string fields. Useful for legacy config files or simple settings.
    /// @param | text | string | A valid INI string to parse.
    /// @return | table | The decoded Lua table with section names as keys and their key-value pairs as nested tables.
    tbl.set(
        "fromIni",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_ini(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;

    // -- toToml --
    /// Serializes a Lua table into a TOML-formatted string. Use this to write configuration files, save structured settings, or export data in a human-readable format.
    /// @param | value | table | The Lua table to serialize into TOML.
    /// @return | string | The TOML-encoded string representation of the table.
    tbl.set(
        "toToml",
        lua.create_function(|_, value: LuaValue| {
            let val = from_lua(&value)?;
            crate::serial::to_toml(&val).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- fromCsv --
    /// Parses a CSV string into a Lua table (array of rows). Each row is either a keyed table (when headers are present) or an indexed array of field values. Useful for loading spreadsheet exports, leaderboard data, or tabular game data.
    /// @param | text | string | The CSV content to parse.
    /// @param | delimiter | string? | Single-character field delimiter. Defaults to comma (",").
    /// @param | hasHeaders | boolean? | When true, the first row is treated as column names and each data row becomes a keyed table. Defaults to true.
    /// @return | table | An array of row tables containing the parsed CSV data.
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
    /// Serializes a Lua table (array of row tables) into a CSV-formatted string. Each row table should have consistent keys or be an indexed array. Use this to export leaderboards, save tabular data, or generate spreadsheet-compatible output.
    /// @param | value | table | An array of row tables to serialize.
    /// @param | delimiter | string? | Single-character field delimiter. Defaults to comma (",").
    /// @param | hasHeaders | boolean? | When true, writes column names as the first row. Defaults to true.
    /// @return | string | The CSV-encoded string of the table data.
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
    /// Encodes a Lua table into a compact binary MessagePack string. MessagePack is faster and smaller than JSON, making it ideal for save files, network packets, or any scenario where performance matters more than human readability. The argument must be a table.
    /// @param | value | table | The Lua table to encode. Must be a table (not a primitive).
    /// @return | string | A binary string containing the MessagePack-encoded data.
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
    /// Decodes a binary MessagePack string back into a Lua table. Use this to read save files, network packets, or any data previously encoded with encodeMsgPack.
    /// @param | bytes | string | A binary string containing valid MessagePack data.
    /// @return | table | The decoded Lua table from the MessagePack payload.
    tbl.set(
        "decodeMsgPack",
        lua.create_function(|lua, bytes: mlua::String| {
            let val =
                crate::serial::from_msgpack(bytes.as_bytes()).map_err(LuaError::RuntimeError)?;
            crate::serial::lua_table::to_lua(lua, &val)
        })?,
    )?;

    // -- decodeXml --
    /// Parses an XML string into a Lua table structure. Elements become nested tables with tag names as keys. Useful for loading Tiled map exports, SVG data, UI layout definitions, or other XML-based game assets.
    /// @param | text | string | A valid XML string to parse.
    /// @return | table | A nested Lua table representing the XML document structure.
    tbl.set(
        "decodeXml",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_xml(&s).map_err(LuaError::RuntimeError)?;
            crate::serial::lua_table::to_lua(lua, &val)
        })?,
    )?;

    // -- validate --
    /// Validates a Lua value against a schema table. The schema defines expected types, required fields, and constraints. Returns a success boolean and an optional error message string describing the first validation failure. Use this to verify save data integrity or user-provided configuration before processing.
    /// @param | value | table | The data to validate.
    /// @param | schema | table | A schema table defining the expected structure and constraints.
    /// @return | boolean | True if validation passes, false otherwise.
    /// @return | string? | An error message describing the validation failure, or nil on success.
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
    /// Attempts to auto-detect the serialization format of a string by inspecting its content (e.g., leading `{` for JSON, `[section]` for INI, XML declaration for XML). Returns the format name or nil if detection fails. Useful for loading user-provided files where the format is unknown.
    /// @param | text | string | The raw text content to analyze.
    /// @return | string? | The detected format name ("json", "toml", "csv", "xml", "ini") or nil if unrecognized.
    tbl.set(
        "detectFormat",
        lua.create_function(|_, s: String| {
            Ok(crate::serial::detect_format(&s).map(|f| f.as_str().to_string()))
        })?,
    )?;

    // -- decode --
    /// Universal decoder that parses a string payload into a Lua table using the specified format. If no format is given, auto-detects from the content. Supports JSON, TOML, CSV, XML, INI, and MessagePack. Use this as a single entry point when handling files of varying or unknown formats.
    /// @param | payload | string | The raw string (or binary for msgpack) to decode.
    /// @param | format | string? | Format hint: "json", "toml", "csv", "xml", "ini", or "msgpack". Nil triggers auto-detection.
    /// @param | opts | table? | Optional settings table. For CSV: `delimiter` (string) and `has_headers` (boolean).
    /// @return | table | The decoded Lua table.
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
                        crate::serial::decode_bytes(bytes.as_bytes(), SerialFormat::MsgPack)
                            .map_err(LuaError::RuntimeError)?
                    }
                    (LuaValue::String(text), Some(f)) => {
                        let s = text
                            .to_str()
                            .map_err(|e| {
                                LuaError::RuntimeError(format!("decode: expected UTF-8 text: {e}"))
                            })?
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
                            .map_err(|e| {
                                LuaError::RuntimeError(format!(
                                    "decode: expected UTF-8 text for auto-detect: {e}"
                                ))
                            })?
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
    /// Universal encoder that serializes a Lua value into the specified format. Supports JSON, TOML, CSV, and MessagePack. Returns a string (text for JSON/TOML/CSV, binary for MessagePack). Use this as a single entry point for all serialization needs.
    /// @param | value | table | The Lua value to encode.
    /// @param | format | string | Target format: "json", "toml", "csv", or "msgpack".
    /// @param | opts | table? | Optional settings table. For JSON: `pretty` (boolean). For CSV: `delimiter` (string) and `has_headers` (boolean).
    /// @return | string | The encoded string (text or binary depending on format).
    tbl.set(
        "encode",
        lua.create_function(
            |lua, (value, format, opts): (LuaValue, String, Option<LuaTable>)| {
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
            },
        )?,
    )?;

    // -- applyDefaults --
    /// Merges a schema's default values into a data table, filling in any missing fields without overwriting existing ones. Use this to ensure game config or save data always has complete fields even when the user provides only partial overrides.
    /// @param | value | table | The data table that may have missing fields.
    /// @param | schema | table | A schema table containing `default` entries for fields.
    /// @return | table | A new table with defaults applied for any absent fields.
    tbl.set(
        "applyDefaults",
        lua.create_function(|lua, (value, schema): (LuaValue, LuaValue)| {
            let val = from_lua(&value)?;
            let sch = from_lua(&schema)?;
            let patched =
                crate::serial::apply_schema_defaults(&val, &sch).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &patched)
        })?,
    )?;
    lurek.set("serial", tbl)?;
    Ok(())
}
