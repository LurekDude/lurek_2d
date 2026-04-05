//! Registers the `luna.serial.*` format serialization API.
//!
//! Provides `luna.serial` with functions to parse and serialize JSON, TOML, and CSV
//! to/from Lua tables. YAML removed — use TOML for config (design-assumption B-05).
//! No file I/O — strings in, strings out.

use mlua::prelude::*;

use crate::serial::{CsvOptions, SerialValue};
use indexmap::IndexMap;

/// Registers the `luna.serial` table on the provided `luna` namespace.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let serial_table = lua.create_table()?;

    // luna.serial.fromJson(str) -> table
    /// Parses a JSON string and returns a Lua table.
    /// @param s : string
    serial_table.set(
        "fromJson",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_json(&s).map_err(LuaError::RuntimeError)?;
            serial_value_to_lua(lua, &val)
        })?,
    )?;

    // luna.serial.toJson(table, pretty?) -> string
    /// Serializes a Lua table to a JSON string.
    /// @param table : table
    /// @param pretty : boolean?
    serial_table.set(
        "toJson",
        lua.create_function(|_, (table, pretty): (LuaValue, Option<bool>)| {
            let val = lua_value_to_serial(&table)?;
            crate::serial::to_json(&val, pretty.unwrap_or(false)).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // luna.serial.fromToml(str) -> table
    /// Parses a TOML string and returns a Lua table.
    /// @param s : string
    serial_table.set(
        "fromToml",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_toml(&s).map_err(LuaError::RuntimeError)?;
            serial_value_to_lua(lua, &val)
        })?,
    )?;

    // luna.serial.toToml(table) -> string
    /// Serializes a Lua table to a TOML string.
    /// @param table : table
    serial_table.set(
        "toToml",
        lua.create_function(|_, table: LuaValue| {
            let val = lua_value_to_serial(&table)?;
            crate::serial::to_toml(&val).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // luna.serial.fromCsv(str, delimiter?, hasHeaders?) -> table
    /// Parses a CSV string and returns a Lua table (sequence of row tables).
    /// @param s : string
    /// @param delimiter : string?
    /// @param has_headers : boolean?
    serial_table.set(
        "fromCsv",
        lua.create_function(
            |lua, (s, delim, headers): (String, Option<String>, Option<bool>)| {
                let delimiter = delim
                    .as_deref()
                    .and_then(|d| d.as_bytes().first().copied())
                    .unwrap_or(b',');
                let opts = CsvOptions {
                    delimiter,
                    has_headers: headers.unwrap_or(true),
                };
                let val = crate::serial::from_csv(&s, opts).map_err(LuaError::RuntimeError)?;
                serial_value_to_lua(lua, &val)
            },
        )?,
    )?;

    // luna.serial.toCsv(table, delimiter?, hasHeaders?) -> string
    /// Serializes a Lua table (sequence of row tables) to a CSV string.
    /// @param table : table
    /// @param delimiter : string?
    /// @param has_headers : boolean?
    serial_table.set(
        "toCsv",
        lua.create_function(
            |_, (table, delim, headers): (LuaValue, Option<String>, Option<bool>)| {
                let delimiter = delim
                    .as_deref()
                    .and_then(|d| d.as_bytes().first().copied())
                    .unwrap_or(b',');
                let opts = CsvOptions {
                    delimiter,
                    has_headers: headers.unwrap_or(true),
                };
                let val = lua_value_to_serial(&table)?;
                crate::serial::to_csv(&val, opts).map_err(LuaError::RuntimeError)
            },
        )?,
    )?;

    // luna.serial.fromYaml / toYaml removed: YAML dep (serde_yml) dropped from Cargo.toml.
    // Use luna.serial.fromToml / toToml instead.

    luna.set("serial", serial_table)?;
    Ok(())
}

// ── Conversion helpers ────────────────────────────────────────────────────────

/// Convert a `SerialValue` to a Lua value.
fn serial_value_to_lua<'lua>(lua: &'lua Lua, val: &SerialValue) -> LuaResult<LuaValue<'lua>> {
    match val {
        SerialValue::Null => Ok(LuaValue::Nil),
        SerialValue::Bool(b) => Ok(LuaValue::Boolean(*b)),
        SerialValue::Int(n) => Ok(LuaValue::Integer(*n)),
        SerialValue::Float(f) => Ok(LuaValue::Number(*f)),
        SerialValue::Str(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        SerialValue::Seq(arr) => {
            let t = lua.create_table()?;
            for (i, v) in arr.iter().enumerate() {
                t.set(i as i64 + 1, serial_value_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(t))
        }
        SerialValue::Map(map) => {
            let t = lua.create_table()?;
            for (k, v) in map {
                t.set(k.as_str(), serial_value_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(t))
        }
    }
}

/// Convert a Lua value to a `SerialValue`.
fn lua_value_to_serial(val: &LuaValue) -> LuaResult<SerialValue> {
    match val {
        LuaValue::Nil => Ok(SerialValue::Null),
        LuaValue::Boolean(b) => Ok(SerialValue::Bool(*b)),
        LuaValue::Integer(n) => Ok(SerialValue::Int(*n)),
        LuaValue::Number(f) => {
            // If the float has no fractional part, store as Int for cleaner output
            if f.fract() == 0.0 && *f >= i64::MIN as f64 && *f <= i64::MAX as f64 {
                Ok(SerialValue::Int(*f as i64))
            } else {
                Ok(SerialValue::Float(*f))
            }
        }
        LuaValue::String(s) => Ok(SerialValue::Str(
            s.to_str()
                .map_err(|e| LuaError::RuntimeError(format!("Invalid UTF-8: {e}")))?
                .to_string(),
        )),
        LuaValue::Table(t) => {
            // Detect sequence vs map by checking if keys are sequential integers
            let raw_len = t.raw_len();
            if raw_len > 0 {
                // Check if all keys 1..=raw_len exist (sequence table)
                let mut is_seq = true;
                for i in 1..=raw_len as i64 {
                    let v: LuaValue = t.get(i)?;
                    if v == LuaValue::Nil {
                        is_seq = false;
                        break;
                    }
                }
                if is_seq {
                    let mut arr = Vec::with_capacity(raw_len);
                    for i in 1..=raw_len as i64 {
                        let v: LuaValue = t.get(i)?;
                        arr.push(lua_value_to_serial(&v)?);
                    }
                    return Ok(SerialValue::Seq(arr));
                }
            }
            // Treat as a string-keyed map
            let mut map = IndexMap::new();
            for pair in t.clone().pairs::<LuaValue, LuaValue>() {
                let (k, v) = pair?;
                let key = match &k {
                    LuaValue::String(s) => s
                        .to_str()
                        .map_err(|e| LuaError::RuntimeError(format!("Invalid UTF-8 key: {e}")))?
                        .to_string(),
                    LuaValue::Integer(n) => n.to_string(),
                    LuaValue::Number(f) => f.to_string(),
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "serial: table keys must be strings or numbers".to_string(),
                        ))
                    }
                };
                map.insert(key, lua_value_to_serial(&v)?);
            }
            Ok(SerialValue::Map(map))
        }
        _ => Err(LuaError::RuntimeError(
            "serial: unsupported Lua value type".to_string(),
        )),
    }
}
