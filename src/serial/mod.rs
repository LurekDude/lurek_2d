//! Format-agnostic serialization: JSON, TOML, CSV, MessagePack, XML, and schema validation.
//!
//! Provides `SerialValue` as a common intermediate representation and per-format
//! modules that parse/serialize strings to/from `SerialValue`. No file I/O —
//! callers supply strings and receive strings back.
//! YAML has been removed — use TOML for human-authored config (design-assumption B-05).

/// Unified dispatch API for encode/decode and format auto-detection.
pub mod codec;
/// CSV parsing and serialization via the csv crate.
pub mod csv;
/// INI parsing helpers for read-only configuration decoding.
pub mod ini;
/// JSON parsing and serialization via serde_json.
pub mod json;
/// `SerialValue` type definition and Lua↔`SerialValue` bidirectional conversion.
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

pub use codec::{
    decode_bytes, decode_text, detect_format, encode, DecodeOptions, EncodeOptions, EncodedValue,
    SerialFormat,
};
pub use csv::{from_csv, from_csv_reader, to_csv, CsvOptions};
pub use ini::from_ini;
pub use json::{from_json, to_json};
pub use lua_table::SerialValue;
pub use msgpack::{decode as from_msgpack, decode_json, encode as to_msgpack, encode_json};
pub use schema::{apply_defaults as apply_schema_defaults, validate as validate_schema};
pub use toml::{encode_toml, from_toml, parse_toml, to_toml};
pub use xml::decode as from_xml;
