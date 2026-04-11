//! TOML parsing and serialization for Lurek2D.
//!
//! Converts between TOML strings and `SerialValue` using the `toml` crate.
//! Provides the functionality previously in `data::toml_convert`.

use super::lua_table::SerialValue;
use indexmap::IndexMap;

/// Parse a TOML string into a `SerialValue`.
///
/// # Parameters
/// - `s` — `&str`. TOML text.
///
/// # Returns
/// `Result<SerialValue, String>`.
pub fn from_toml(s: &str) -> Result<SerialValue, String> {
    let v: toml::Value = s
        .parse::<toml::Value>()
        .map_err(|e| format!("TOML parse error: {e}"))?;
    Ok(toml_to_serial(v))
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
    match &tv {
        toml::Value::Table(t) => toml::to_string(t).map_err(|e| format!("TOML encode error: {e}")),
        _ => Err("to_toml: root value must be a map".to_string()),
    }
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::serial::lua_table::SerialValue;

    #[test]
    fn round_trip_simple_table() {
        let src = "[section]\nkey = \"value\"\nnum = 42\n";
        let parsed = from_toml(src).unwrap();
        let back = to_toml(&parsed).unwrap();
        // Should round-trip without error; check key presence
        assert!(back.contains("key"));
        assert!(back.contains("value"));
    }

    #[test]
    fn from_toml_integer_preserved() {
        let src = "[t]\nn = 7\n";
        let parsed = from_toml(src).unwrap();
        match parsed {
            SerialValue::Map(m) => match m.get("t") {
                Some(SerialValue::Map(inner)) => {
                    assert!(matches!(inner.get("n"), Some(SerialValue::Int(7))));
                }
                _ => panic!("expected nested map"),
            },
            other => panic!("expected Map, got {:?}", other),
        }
    }
}
