//! Schema validation for Lurek2D serialized values.
//!
//! Validates a `SerialValue` against a declarative schema expressed as another
//! `SerialValue::Map`. No external crates required — pure Rust logic operating
//! on `SerialValue` trees. No mlua imports; all Lua bridging lives in
//! `src/lua_api/serial_api.rs`.
//!
//! # Schema Format
//!
//! A schema is a `SerialValue::Map` with the following optional keys:
//!
//! | Key        | Type           | Meaning                                          |
//! |------------|----------------|--------------------------------------------------|
//! | `type`     | string         | `"string"`, `"number"`, `"boolean"`, `"table"`, `"null"`, `"any"` |
//! | `required` | boolean        | Causes validation to fail if value is `Null`     |
//! | `min`      | number / int   | Minimum numeric value (inclusive)                |
//! | `max`      | number / int   | Maximum numeric value (inclusive)                |
//! | `minlen`   | int            | Minimum string length (bytes)                    |
//! | `maxlen`   | int            | Maximum string length (bytes)                    |
//! | `fields`   | map of schemas | Required / optional table fields                 |
//! | `items`    | schema         | Schema that every element of a sequence must match |
//!
//! # Example
//!
//! ```
//! // { type="table", fields={ name={type="string",required=true}, level={type="number",min=1,max=100} } }
//! ```

use super::lua_table::SerialValue;
use crate::log_msg;
use crate::runtime::log_messages::{SR07_SCHEMA_PASS, SR08_SCHEMA_FAIL};

// ── Validation core ───────────────────────────────────────────────────────────

/// Validate `value` against `schema`, returning `Ok(())` or `Err(description)`.
///
/// # Parameters
/// - `value` — `&SerialValue`. The value to validate.
/// - `schema` — `&SerialValue`. The schema map.
/// - `path`   — `&str`. Dot-separated path used in error messages (pass `""` at root).
fn validate_at(value: &SerialValue, schema: &SerialValue, path: &str) -> Result<(), String> {
    let schema_map = match schema {
        SerialValue::Map(m) => m,
        _ => {
            return Err(format!("{path}: schema must be a table"));
        }
    };

    // ── required ──────────────────────────────────────────────────────────────
    let required = match schema_map.get("required") {
        Some(SerialValue::Bool(b)) => *b,
        _ => false,
    };
    if matches!(value, SerialValue::Null) {
        if required {
            return Err(format!("{path}: required field is nil"));
        }
        // Null and not required — skip further checks
        return Ok(());
    }

    // ── type check ────────────────────────────────────────────────────────────
    if let Some(SerialValue::Str(expected_type)) = schema_map.get("type") {
        let type_ok = match expected_type.as_str() {
            "string" => matches!(value, SerialValue::Str(_)),
            "number" => matches!(value, SerialValue::Int(_) | SerialValue::Float(_)),
            "boolean" => matches!(value, SerialValue::Bool(_)),
            "table" => matches!(value, SerialValue::Map(_) | SerialValue::Seq(_)),
            "null" => matches!(value, SerialValue::Null),
            "any" => true,
            other => {
                return Err(format!("{path}: unknown schema type '{other}'"));
            }
        };
        if !type_ok {
            let actual = type_name(value);
            return Err(format!(
                "{path}: expected type '{expected_type}' but got '{actual}'"
            ));
        }
    }

    // ── numeric range ─────────────────────────────────────────────────────────
    if let Some(min) = schema_map.get("min") {
        let min_f = to_f64(min).ok_or_else(|| format!("{path}: schema 'min' must be a number"))?;
        let val_f =
            numeric_f64(value).ok_or_else(|| format!("{path}: 'min' requires a numeric value"))?;
        if val_f < min_f {
            return Err(format!("{path}: value {val_f} is less than min {min_f}"));
        }
    }
    if let Some(max) = schema_map.get("max") {
        let max_f = to_f64(max).ok_or_else(|| format!("{path}: schema 'max' must be a number"))?;
        let val_f =
            numeric_f64(value).ok_or_else(|| format!("{path}: 'max' requires a numeric value"))?;
        if val_f > max_f {
            return Err(format!("{path}: value {val_f} is greater than max {max_f}"));
        }
    }

    // ── string length ─────────────────────────────────────────────────────────
    if let Some(minlen) = schema_map.get("minlen") {
        let min_n = to_usize(minlen)
            .ok_or_else(|| format!("{path}: schema 'minlen' must be a non-negative integer"))?;
        let len =
            string_len(value).ok_or_else(|| format!("{path}: 'minlen' requires a string value"))?;
        if len < min_n {
            return Err(format!(
                "{path}: string length {len} is less than minlen {min_n}"
            ));
        }
    }
    if let Some(maxlen) = schema_map.get("maxlen") {
        let max_n = to_usize(maxlen)
            .ok_or_else(|| format!("{path}: schema 'maxlen' must be a non-negative integer"))?;
        let len =
            string_len(value).ok_or_else(|| format!("{path}: 'maxlen' requires a string value"))?;
        if len > max_n {
            return Err(format!(
                "{path}: string length {len} is greater than maxlen {max_n}"
            ));
        }
    }

    // ── table fields ──────────────────────────────────────────────────────────
    if let Some(SerialValue::Map(field_schemas)) = schema_map.get("fields") {
        let val_map = match value {
            SerialValue::Map(m) => m,
            _ => {
                return Err(format!("{path}: 'fields' requires a table value"));
            }
        };
        for (field_name, field_schema) in field_schemas {
            let child_path = if path.is_empty() {
                field_name.clone()
            } else {
                format!("{path}.{field_name}")
            };
            let child_val = val_map.get(field_name).unwrap_or(&SerialValue::Null);
            validate_at(child_val, field_schema, &child_path)?;
        }
    }

    // ── sequence items ────────────────────────────────────────────────────────
    if let Some(item_schema) = schema_map.get("items") {
        match value {
            SerialValue::Seq(s) => {
                for (i, item) in s.iter().enumerate() {
                    let item_path = format!("{path}[{i}]");
                    validate_at(item, item_schema, &item_path)?;
                }
            }
            // An empty Lua table `{}` is serialised as Map({}); treat it as an
            // empty sequence that vacuously satisfies the items constraint.
            SerialValue::Map(m) if m.is_empty() => {}
            _ => {
                return Err(format!("{path}: 'items' requires a sequence (array) value"));
            }
        }
    }

    Ok(())
}

// ── Helpers ───────────────────────────────────────────────────────────────────

fn type_name(val: &SerialValue) -> &'static str {
    match val {
        SerialValue::Null => "null",
        SerialValue::Bool(_) => "boolean",
        SerialValue::Int(_) | SerialValue::Float(_) => "number",
        SerialValue::Str(_) => "string",
        SerialValue::Seq(_) => "table",
        SerialValue::Map(_) => "table",
    }
}

fn numeric_f64(val: &SerialValue) -> Option<f64> {
    match val {
        SerialValue::Int(n) => Some(*n as f64),
        SerialValue::Float(f) => Some(*f),
        _ => None,
    }
}

fn to_f64(val: &SerialValue) -> Option<f64> {
    match val {
        SerialValue::Int(n) => Some(*n as f64),
        SerialValue::Float(f) => Some(*f),
        _ => None,
    }
}

fn to_usize(val: &SerialValue) -> Option<usize> {
    match val {
        SerialValue::Int(n) if *n >= 0 => Some(*n as usize),
        _ => None,
    }
}

fn string_len(val: &SerialValue) -> Option<usize> {
    match val {
        SerialValue::Str(s) => Some(s.len()),
        _ => None,
    }
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Validate a `SerialValue` tree against a schema.
///
/// Returns `Ok(())` when the value conforms to the schema, or
/// `Err(description)` with a human-readable error including the field path.
///
/// # Parameters
/// - `value`  — `&SerialValue`. The value to validate.
/// - `schema` — `&SerialValue`. Declarative schema (must be a `SerialValue::Map`).
///
/// # Returns
/// `Result<(), String>`.
pub fn validate(value: &SerialValue, schema: &SerialValue) -> Result<(), String> {
    match validate_at(value, schema, "") {
        Ok(()) => {
            log_msg!(debug, SR07_SCHEMA_PASS);
            Ok(())
        }
        Err(msg) => {
            log_msg!(debug, SR08_SCHEMA_FAIL);
            Err(msg)
        }
    }
}

/// Apply schema defaults to a value tree.
///
/// The schema may provide a `default` key at any node. When the current value
/// is `Null`, that default value is used. For table fields and sequence items,
/// defaults are applied recursively.
pub fn apply_defaults(value: &SerialValue, schema: &SerialValue) -> Result<SerialValue, String> {
    apply_defaults_at(value, schema)
}

fn apply_defaults_at(value: &SerialValue, schema: &SerialValue) -> Result<SerialValue, String> {
    let schema_map = match schema {
        SerialValue::Map(m) => m,
        _ => return Err("schema must be a table".to_string()),
    };

    if matches!(value, SerialValue::Null) {
        if let Some(default) = schema_map.get("default") {
            return Ok(default.clone());
        }
        return Ok(SerialValue::Null);
    }

    let mut current = value.clone();

    if let Some(SerialValue::Map(field_schemas)) = schema_map.get("fields") {
        let mut merged = match &current {
            SerialValue::Map(m) => m.clone(),
            _ => {
                return Err("schema 'fields' requires a table value".to_string());
            }
        };

        for (field_name, field_schema) in field_schemas {
            let existing = merged.get(field_name).cloned().unwrap_or(SerialValue::Null);
            let patched = apply_defaults_at(&existing, field_schema)?;
            if !matches!(patched, SerialValue::Null) {
                merged.insert(field_name.clone(), patched);
            }
        }

        current = SerialValue::Map(merged);
    }

    if let Some(item_schema) = schema_map.get("items") {
        match &current {
            SerialValue::Seq(items) => {
                let mut out = Vec::with_capacity(items.len());
                for item in items {
                    out.push(apply_defaults_at(item, item_schema)?);
                }
                current = SerialValue::Seq(out);
            }
            SerialValue::Map(m) if m.is_empty() => {
                current = SerialValue::Seq(Vec::new());
            }
            _ => {
                return Err("schema 'items' requires a sequence (array) value".to_string());
            }
        }
    }

    Ok(current)
}
