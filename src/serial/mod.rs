//! Format-agnostic serialization: JSON, TOML, CSV, MessagePack, XML, and schema validation.
//!
//! Provides `SerialValue` as a common intermediate representation and per-format
//! modules that parse/serialize strings to/from `SerialValue`. No file I/O —
//! callers supply strings and receive strings back.
//! YAML has been removed — use TOML for human-authored config (design-assumption B-05).

/// CSV parsing and serialization via the csv crate.
pub mod csv;
/// JSON parsing and serialization via serde_json.
pub mod json;
/// Shared intermediate representation for all serial formats.
pub mod lua_table;
/// MessagePack encoding and decoding via rmp-serde.
pub mod msgpack;
/// Schema validation for SerialValue trees.
pub mod schema;
/// TOML parsing and serialization via the toml crate.
pub mod toml;
/// XML parsing (read-only) via roxmltree.
pub mod xml;
// pub mod yaml; // YAML removed: use TOML instead (design-assumption B-05). serde_yml dep dropped.

pub use csv::{from_csv, to_csv, CsvOptions};
pub use json::{from_json, to_json};
pub use lua_table::SerialValue;
pub use msgpack::{decode as from_msgpack, encode as to_msgpack};
pub use schema::validate as validate_schema;
pub use toml::{from_toml, to_toml};
pub use xml::decode as from_xml;
