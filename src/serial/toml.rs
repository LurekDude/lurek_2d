//! TOML parsing and serialization for Lurek2D.
//!
//! Converts between TOML strings and `SerialValue` using the `toml` crate.
//! Provides the functionality previously in `data::toml_convert`.

use super::lua_table::SerialValue;
use indexmap::IndexMap;

/// Parse a TOML string into a raw `toml::Value` (lower-level).
///
/// This provides direct access to the toml crate's native type, useful when
/// you need to inspect TOML structure without converting to `SerialValue`.
///
/// # Parameters
/// - `input` — `&str`. TOML text.
///
/// # Returns
/// `Result<toml::Value, String>`.
pub fn parse_toml(input: &str) -> Result<toml::Value, String> {
    input
        .parse::<toml::Value>()
        .map_err(|e| format!("TOML parse error: {e}"))
}

/// Parse a TOML string into a `SerialValue`.
///
/// # Parameters
/// - `s` — `&str`. TOML text.
///
/// # Returns
/// `Result<SerialValue, String>`.
pub fn from_toml(s: &str) -> Result<SerialValue, String> {
    let v = parse_toml(s)?;
    Ok(toml_to_serial(v))
}

/// Encode a `toml::Value` into a TOML string (lower-level).
///
/// Only table values are accepted at the top level because the TOML spec
/// requires documents to be tables. Non-table values produce an error.
///
/// # Parameters
/// - `value` — `&toml::Value`.
///
/// # Returns
/// `Result<String, String>`.
pub fn encode_toml(value: &toml::Value) -> Result<String, String> {
    match value {
        toml::Value::Table(t) => toml::to_string(t).map_err(|e| format!("TOML encode error: {e}")),
        _ => Err("encode_toml expects a table value".into()),
    }
}

/// Serialize a `SerialValue` to a TOML string.
///
/// # Parameters
/// - `val` — `&SerialValue`. Value to serialize (must be a `Map` at root).
///
/// # Returns
/// `Result<String, String>`.
pub fn to_toml(val: &SerialValue) -> Result<String, String> {
    let tv = serial_to_toml(val)?;
    encode_toml(&tv)
}

/// Convert a `toml::Value` to `SerialValue`.
fn toml_to_serial(v: toml::Value) -> SerialValue {
    match v {
        toml::Value::String(s) => SerialValue::Str(s),
        toml::Value::Integer(n) => SerialValue::Int(n),
        toml::Value::Float(f) => SerialValue::Float(f),
        toml::Value::Boolean(b) => SerialValue::Bool(b),
        toml::Value::Datetime(dt) => SerialValue::Str(dt.to_string()),
        toml::Value::Array(arr) => SerialValue::Seq(arr.into_iter().map(toml_to_serial).collect()),
        toml::Value::Table(map) => {
            let mut ordered = IndexMap::new();
            for (k, v) in map {
                ordered.insert(k, toml_to_serial(v));
            }
            SerialValue::Map(ordered)
        }
    }
}

/// Convert a `SerialValue` to `toml::Value`.
fn serial_to_toml(val: &SerialValue) -> Result<toml::Value, String> {
    match val {
        SerialValue::Null => Err("to_toml: null values are not supported in TOML".to_string()),
        SerialValue::Bool(b) => Ok(toml::Value::Boolean(*b)),
        SerialValue::Int(n) => Ok(toml::Value::Integer(*n)),
        SerialValue::Float(f) => Ok(toml::Value::Float(*f)),
        SerialValue::Str(s) => Ok(toml::Value::String(s.clone())),
        SerialValue::Seq(arr) => {
            let res: Result<Vec<_>, _> = arr.iter().map(serial_to_toml).collect();
            Ok(toml::Value::Array(res?))
        }
        SerialValue::Map(map) => {
            let mut table = toml::map::Map::new();
            for (k, v) in map {
                table.insert(k.clone(), serial_to_toml(v)?);
            }
            Ok(toml::Value::Table(table))
        }
    }
}
