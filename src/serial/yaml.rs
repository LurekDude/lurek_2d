//! YAML parsing and serialization for Lurek2D.
//!
//! Converts between YAML strings and `SerialValue` using `serde_yml`.

use super::lua_table::SerialValue;
use indexmap::IndexMap;
use serde_yml::Value as YamlValue;

/// Parse a YAML string into a `SerialValue`.
///
/// # Parameters
/// - `s` — `&str`. YAML text.
///
/// # Returns
/// `Result<SerialValue, String>`.
pub fn from_yaml(s: &str) -> Result<SerialValue, String> {
    let v: YamlValue = serde_yml::from_str(s).map_err(|e| format!("YAML parse error: {e}"))?;
    Ok(yaml_to_serial(v))
}

/// Serialize a `SerialValue` to a YAML string.
///
/// # Parameters
/// - `val` — `&SerialValue`. Value to serialize.
///
/// # Returns
/// `Result<String, String>`.
pub fn to_yaml(val: &SerialValue) -> Result<String, String> {
    let yv = serial_to_yaml(val);
    serde_yml::to_string(&yv).map_err(|e| format!("YAML encode error: {e}"))
}

/// Convert a `serde_yml::Value` to `SerialValue`.
fn yaml_to_serial(v: YamlValue) -> SerialValue {
    match v {
        YamlValue::Null => SerialValue::Null,
        YamlValue::Bool(b) => SerialValue::Bool(b),
        YamlValue::Number(n) => {
            if let Some(i) = n.as_i64() {
                SerialValue::Int(i)
            } else {
                SerialValue::Float(n.as_f64().unwrap_or(0.0))
            }
        }
        YamlValue::String(s) => SerialValue::Str(s),
        YamlValue::Sequence(arr) => {
            SerialValue::Seq(arr.into_iter().map(yaml_to_serial).collect())
        }
        YamlValue::Mapping(map) => {
            let mut ordered = IndexMap::new();
            for (k, v) in map {
                let key = match k {
                    YamlValue::String(s) => s,
                    other => format!("{other:?}"),
                };
                ordered.insert(key, yaml_to_serial(v));
            }
            SerialValue::Map(ordered)
        }
        YamlValue::Tagged(tagged) => yaml_to_serial(tagged.value),
    }
}

/// Convert a `SerialValue` to `serde_yml::Value`.
fn serial_to_yaml(val: &SerialValue) -> YamlValue {
    match val {
        SerialValue::Null => YamlValue::Null,
        SerialValue::Bool(b) => YamlValue::Bool(*b),
        SerialValue::Int(n) => YamlValue::Number((*n).into()),
        SerialValue::Float(f) => {
            serde_yml::Number::from(*f).into()
        }
        SerialValue::Str(s) => YamlValue::String(s.clone()),
        SerialValue::Seq(arr) => {
            YamlValue::Sequence(arr.iter().map(serial_to_yaml).collect())
        }
        SerialValue::Map(map) => {
            let mut mapping = serde_yml::Mapping::new();
            for (k, v) in map {
                mapping.insert(YamlValue::String(k.clone()), serial_to_yaml(v));
            }
            YamlValue::Mapping(mapping)
        }
    }
}
