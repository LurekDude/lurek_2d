//! Format-agnostic serialization: JSON, TOML, CSV, YAML, and Lua tables.
//!
//! Provides `SerialValue` as a common intermediate representation and per-format
//! modules that parse/serialize strings to/from `SerialValue`. No file I/O —
//! callers supply strings and receive strings back.

/// Shared intermediate representation for all serial formats.
pub mod lua_table;
/// JSON parsing and serialization via serde_json.
pub mod json;
/// TOML parsing and serialization via the toml crate.
pub mod toml;
/// CSV parsing and serialization via the csv crate.
pub mod csv;
/// YAML parsing and serialization via serde_yml.
pub mod yaml;

pub use json::{from_json, to_json};
pub use toml::{from_toml, to_toml};
pub use csv::{from_csv, to_csv, CsvOptions};
pub use yaml::{from_yaml, to_yaml};
pub use lua_table::SerialValue;
