//! JSON parsing and serialization for Lurek2D.
//!
//! Converts between JSON strings and `SerialValue` using `serde_json`.

use super::lua_table::SerialValue;
use crate::engine::log_messages::{SR01_JSON_OK, SR03_JSON_ENC};
use crate::log_msg;
use indexmap::IndexMap;
use serde_json::Value as JsonValue;

/// Parse a JSON string into a `SerialValue`.
///
/// # Parameters
/// - `s` — `&str`. JSON text.
///
/// # Returns
/// `Result<SerialValue, String>`.
pub fn from_json(s: &str) -> Result<SerialValue, String> {
    let v: JsonValue = serde_json::from_str(s).map_err(|e| format!("JSON parse error: {e}"))?;
    log_msg!(debug, SR01_JSON_OK);
    Ok(json_to_serial(v))
}

/// Serialize a `SerialValue` to a JSON string.
///
/// # Parameters
/// - `val` — `&SerialValue`. Value to serialize.
/// - `pretty` — `bool`. Use pretty-printed output if true.
///
/// # Returns
/// `Result<String, String>`.
pub fn to_json(val: &SerialValue, pretty: bool) -> Result<String, String> {
    let jv = serial_to_json(val);
    let result = if pretty {
        serde_json::to_string_pretty(&jv).map_err(|e| format!("JSON encode error: {e}"))
    } else {
        serde_json::to_string(&jv).map_err(|e| format!("JSON encode error: {e}"))
    };
    if result.is_ok() {
        log_msg!(debug, SR03_JSON_ENC);
    }
    result
}

/// Convert a `serde_json::Value` to `SerialValue`.
fn json_to_serial(v: JsonValue) -> SerialValue {
    match v {
        JsonValue::Null => SerialValue::Null,
        JsonValue::Bool(b) => SerialValue::Bool(b),
        JsonValue::Number(n) => {
            if let Some(i) = n.as_i64() {
                SerialValue::Int(i)
            } else {
                SerialValue::Float(n.as_f64().unwrap_or(0.0))
            }
        }
        JsonValue::String(s) => SerialValue::Str(s),
        JsonValue::Array(arr) => SerialValue::Seq(arr.into_iter().map(json_to_serial).collect()),
        JsonValue::Object(map) => {
            let mut ordered = IndexMap::new();
            for (k, v) in map {
                ordered.insert(k, json_to_serial(v));
            }
            SerialValue::Map(ordered)
        }
    }
}

/// Convert a `SerialValue` to `serde_json::Value`.
fn serial_to_json(val: &SerialValue) -> JsonValue {
    match val {
        SerialValue::Null => JsonValue::Null,
        SerialValue::Bool(b) => JsonValue::Bool(*b),
        SerialValue::Int(n) => JsonValue::Number((*n).into()),
        SerialValue::Float(f) => serde_json::Number::from_f64(*f)
            .map(JsonValue::Number)
            .unwrap_or(JsonValue::Null),
        SerialValue::Str(s) => JsonValue::String(s.clone()),
        SerialValue::Seq(arr) => JsonValue::Array(arr.iter().map(serial_to_json).collect()),
        SerialValue::Map(map) => {
            let obj: serde_json::Map<_, _> = map
                .iter()
                .map(|(k, v)| (k.clone(), serial_to_json(v)))
                .collect();
            JsonValue::Object(obj)
        }
    }
}
