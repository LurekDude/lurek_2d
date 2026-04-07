//! `SerialValue`: shared intermediate representation for all serial format modules.
//!
//! All format modules (json, toml, csv, yaml) convert to/from `SerialValue`.
//! `Lua-table` is the canonical name because the primary use case is bridging
//! between Lua tables and text serialization formats.

use indexmap::IndexMap;
use mlua::prelude::{Lua, LuaResult, LuaValue};

/// A Luna2D serializable value — the common intermediate representation
/// shared by all serial format modules.
///
/// # Variants
/// - `Null` — Absent or nil value.
/// - `Bool` — Boolean.
/// - `Int` — 64-bit signed integer.
/// - `Float` — 64-bit floating-point.
/// - `Str` — UTF-8 string.
/// - `Seq` — Ordered sequence of values.
/// - `Map` — Ordered string-keyed map of values.
#[derive(Debug, Clone)]
pub enum SerialValue {
    /// Absent or nil value.
    Null,
    /// Boolean value.
    Bool(bool),
    /// 64-bit signed integer.
    Int(i64),
    /// 64-bit floating-point.
    Float(f64),
    /// UTF-8 string.
    Str(String),
    /// Ordered sequence of values.
    Seq(Vec<SerialValue>),
    /// Ordered string-keyed map of values.
    Map(IndexMap<String, SerialValue>),
}

/// Converts a `SerialValue` tree into a Lua value tree.
///
/// # Parameters
/// - `lua` — `&Lua`. The active Lua state.
/// - `val` — `&SerialValue`. The value to convert.
///
/// # Returns
/// `LuaResult<LuaValue<'lua>>`.
pub fn to_lua<'lua>(lua: &'lua Lua, val: &SerialValue) -> LuaResult<LuaValue<'lua>> {
    match val {
        SerialValue::Null => Ok(LuaValue::Nil),
        SerialValue::Bool(b) => Ok(LuaValue::Boolean(*b)),
        SerialValue::Int(n) => Ok(LuaValue::Integer(*n)),
        SerialValue::Float(f) => Ok(LuaValue::Number(*f)),
        SerialValue::Str(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        SerialValue::Seq(arr) => {
            let t = lua.create_table()?;
            for (i, v) in arr.iter().enumerate() {
                t.set(i as i64 + 1, to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(t))
        }
        SerialValue::Map(map) => {
            let t = lua.create_table()?;
            for (k, v) in map {
                t.set(k.as_str(), to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(t))
        }
    }
}

/// Converts a Lua value tree into a `SerialValue` tree.
///
/// # Parameters
/// - `val` — `&LuaValue`. The Lua value to convert.
///
/// # Returns
/// `LuaResult<SerialValue>`.
pub fn from_lua(val: &LuaValue) -> LuaResult<SerialValue> {
    match val {
        LuaValue::Nil => Ok(SerialValue::Null),
        LuaValue::Boolean(b) => Ok(SerialValue::Bool(*b)),
        LuaValue::Integer(n) => Ok(SerialValue::Int(*n)),
        LuaValue::Number(f) => {
            if f.fract() == 0.0 && *f >= i64::MIN as f64 && *f <= i64::MAX as f64 {
                Ok(SerialValue::Int(*f as i64))
            } else {
                Ok(SerialValue::Float(*f))
            }
        }
        LuaValue::String(s) => Ok(SerialValue::Str(
            s.to_str()
                .map_err(|e| mlua::Error::RuntimeError(format!("Invalid UTF-8: {e}")))?
                .to_string(),
        )),
        LuaValue::Table(t) => {
            let raw_len = t.raw_len();
            if raw_len > 0 {
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
                        arr.push(from_lua(&v)?);
                    }
                    return Ok(SerialValue::Seq(arr));
                }
            }
            let mut map = IndexMap::new();
            for pair in t.clone().pairs::<LuaValue, LuaValue>() {
                let (k, v) = pair?;
                let key = match &k {
                    LuaValue::String(s) => s
                        .to_str()
                        .map_err(|e| mlua::Error::RuntimeError(format!("Invalid UTF-8 key: {e}")))?
                        .to_string(),
                    LuaValue::Integer(n) => n.to_string(),
                    LuaValue::Number(f) => f.to_string(),
                    _ => {
                        return Err(mlua::Error::RuntimeError(
                            "serial: table keys must be strings or numbers".to_string(),
                        ))
                    }
                };
                map.insert(key, from_lua(&v)?);
            }
            Ok(SerialValue::Map(map))
        }
        _ => Err(mlua::Error::RuntimeError(
            "serial: unsupported Lua value type".to_string(),
        )),
    }
}
