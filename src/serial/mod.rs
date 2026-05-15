//! - Serialization and deserialization for multiple formats (JSON, TOML, CSV, XML, MsgPack, INI)
//! - Unified codec interface with auto-detection and round-trip encode/decode
//! - Schema validation and default application for structured data
//! - Lua table ↔ Rust value bridging via SerialValue

/// Unified codec: format detection, encode, and decode entry points.
pub mod codec;
/// CSV parsing and generation with configurable options.
pub mod csv;
/// INI file parser. This module is publicly re-exported.
pub mod ini;
/// JSON serialization and deserialization.
pub mod json;
/// SerialValue type bridging Lua tables and Rust data.
pub mod lua_table;
/// MessagePack binary encode/decode.
pub mod msgpack;
/// Schema validation and default-value application.
pub mod schema;
/// TOML parsing and encoding. This module is publicly re-exported.
pub mod toml;
/// XML decoding. This module is publicly re-exported.
pub mod xml;
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
