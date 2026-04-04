//! `SerialValue`: shared intermediate representation for all serial format modules.
//!
//! All format modules (json, toml, csv, yaml) convert to/from `SerialValue`.
//! `Lua-table` is the canonical name because the primary use case is bridging
//! between Lua tables and text serialization formats.

use indexmap::IndexMap;

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
