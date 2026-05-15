# serial

## General Info

- Module group: `Foundations`
- Source path: `src/serial/`
- Lua API path(s): `src/lua_api/serial_api.rs`
- Primary Lua namespace: `lurek.serial`
- Rust test path(s): None found in the workspace
- Lua test path(s): None found in the workspace

## Summary

The `serial` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Foundations group rather than absorb behavior owned by those neighbors.

## Files

- `codec.rs`: - Format detection, decoding, and encoding for the serial module.
- `csv.rs`: - Parse CSV text or streams into `SerialValue` sequences of maps or arrays.
- `ini.rs`: - Parse INI text into a nested `SerialValue` map.
- `json.rs`: - Parse JSON strings into the engine's `SerialValue` intermediate representation.
- `lua_table.rs`: - Bidirectional conversion between Lua tables and a typed serial value tree.
- `mod.rs`: - Serialization and deserialization for multiple formats (JSON, TOML, CSV, XML, MsgPack, INI) - Unified codec interface with auto-detection and round-trip encode/decode - Schema validation and default application for structured data - Lua table ↔ Rust value bridging via SerialVal
- `msgpack.rs`: - MessagePack binary encoding and decoding for SerialValue trees.
- `schema.rs`: - Validate a `SerialValue` tree against a schema describing expected types, ranges, and structure.
- `toml.rs`: - Parse TOML strings into engine-internal `SerialValue` trees.
- `xml.rs`: - Parse XML strings into a SerialValue tree using roxmltree.

## Types

- `SerialFormat` (`enum`, `codec.rs`): Supported serialization formats.
- `DecodeOptions` (`struct`, `codec.rs`): Options controlling text decoding behavior.
- `EncodeOptions` (`struct`, `codec.rs`): Options controlling encoding behavior.
- `EncodedValue` (`enum`, `codec.rs`): Result of encoding a value — either UTF-8 text or raw bytes.
- `CsvOptions` (`struct`, `csv.rs`): Options controlling CSV parsing and serialization behavior.
- `SerialValue` (`enum`, `lua_table.rs`): Type-erased value tree used for Lua-to-Rust serialization.
- `MsgValue` (`enum`, `msgpack.rs`): Intermediate value type used for MessagePack serialization roundtrips.

## Functions

- `SerialFormat::parse` (`codec.rs`): Parse a format name string into a `SerialFormat` variant.
- `SerialFormat::from_extension` (`codec.rs`): Detect format from a file path extension.
- `SerialFormat::as_str` (`codec.rs`): Return the canonical string name for this format.
- `detect_format` (`codec.rs`): Detect the serialization format of a text string by content inspection.
- `decode_text` (`codec.rs`): Decode a text string into a `SerialValue`, optionally specifying the format.
- `decode_bytes` (`codec.rs`): Decode a binary byte slice into a `SerialValue` using the given format.
- `encode` (`codec.rs`): Encode a `SerialValue` into the specified format.
- `from_csv` (`csv.rs`): Parse a CSV string into a `SerialValue` sequence.
- `from_csv_reader` (`csv.rs`): Parse CSV from any `Read` source into a `SerialValue` sequence.
- `to_csv` (`csv.rs`): Serialize a `SerialValue` sequence of rows into a CSV string.
- `from_ini` (`ini.rs`): Parse an INI-formatted string into a `SerialValue::Map`.
- `from_json` (`json.rs`): Parse a JSON string into a `SerialValue` tree.
- `to_json` (`json.rs`): Encode a `SerialValue` tree to a JSON string.
- `to_lua` (`lua_table.rs`): Convert a `SerialValue` tree into a Lua value (tables for Seq/Map).
- `from_lua` (`lua_table.rs`): Convert a Lua value into a `SerialValue` tree, detecting arrays automatically.
- `encode` (`msgpack.rs`): Encode a SerialValue tree into MessagePack bytes.
- `decode` (`msgpack.rs`): Decode MessagePack bytes into a SerialValue tree.
- `encode_json` (`msgpack.rs`): Encode a serde_json Value into MessagePack bytes.
- `decode_json` (`msgpack.rs`): Decode MessagePack bytes into a serde_json Value.
- `validate` (`schema.rs`): Validate a serial value tree against a schema, logging the pass/fail result.
- `apply_defaults` (`schema.rs`): Fill missing fields in a value tree with defaults defined in the schema.
- `parse_toml` (`toml.rs`): Parse a raw TOML string into a `toml::Value` tree.
- `from_toml` (`toml.rs`): Parse a TOML string and convert it into a `SerialValue`.
- `encode_toml` (`toml.rs`): Encode a `toml::Value` table into a TOML-formatted string.
- `to_toml` (`toml.rs`): Convert a `SerialValue` into a TOML-encoded string.
- `decode` (`xml.rs`): Parse an XML string and return the root element as a SerialValue tree.

## Lua API Reference

- Binding path(s): `src/lua_api/serial_api.rs`
- Namespace: `lurek.serial`

### Module Functions
- `lurek.serial.fromJson`: Parses a JSON string into a Lua table. Use this to load configuration files, network responses, or any structured data stored as JSON.
- `lurek.serial.toJson`: Serializes a Lua value (table, string, number, boolean, or nil) into a JSON string. Useful for saving game state, writing config files, or preparing network payloads.
- `lurek.serial.fromToml`: Parses a TOML string into a Lua table. Ideal for loading game configuration files, level definitions, and engine settings stored in TOML format.
- `lurek.serial.fromIni`: Parses an INI-format string into a Lua table. Sections become nested tables, and key-value pairs become string fields. Useful for legacy config files or simple settings.
- `lurek.serial.toToml`: Serializes a Lua table into a TOML-formatted string. Use this to write configuration files, save structured settings, or export data in a human-readable format.
- `lurek.serial.fromCsv`: Parses a CSV string into a Lua table (array of rows). Each row is either a keyed table (when headers are present) or an indexed array of field values. Useful for loading spreadsheet exports, leaderboard data, or tabular game data.
- `lurek.serial.toCsv`: Serializes a Lua table (array of row tables) into a CSV-formatted string. Each row table should have consistent keys or be an indexed array. Use this to export leaderboards, save tabular data, or generate spreadsheet-compatible output.
- `lurek.serial.encodeMsgPack`: Encodes a Lua table into a compact binary MessagePack string. MessagePack is faster and smaller than JSON, making it ideal for save files, network packets, or any scenario where performance matters more than human readability. The argument must be a table.
- `lurek.serial.decodeMsgPack`: Decodes a binary MessagePack string back into a Lua table. Use this to read save files, network packets, or any data previously encoded with encodeMsgPack.
- `lurek.serial.decodeXml`: Parses an XML string into a Lua table structure. Elements become nested tables with tag names as keys. Useful for loading Tiled map exports, SVG data, UI layout definitions, or other XML-based game assets.
- `lurek.serial.validate`: Validates a Lua value against a schema table. The schema defines expected types, required fields, and constraints. Returns a success boolean and an optional error message string describing the first validation failure. Use this to verify save data integrity or user-provided configuration before processing.
- `lurek.serial.detectFormat`: Attempts to auto-detect the serialization format of a string by inspecting its content (e.g., leading `{` for JSON, `[section]` for INI, XML declaration for XML). Returns the format name or nil if detection fails. Useful for loading user-provided files where the format is unknown.
- `lurek.serial.decode`: Universal decoder that parses a string payload into a Lua table using the specified format. If no format is given, auto-detects from the content. Supports JSON, TOML, CSV, XML, INI, and MessagePack. Use this as a single entry point when handling files of varying or unknown formats.
- `lurek.serial.encode`: Universal encoder that serializes a Lua value into the specified format. Supports JSON, TOML, CSV, and MessagePack. Returns a string (text for JSON/TOML/CSV, binary for MessagePack). Use this as a single entry point for all serialization needs.
- `lurek.serial.applyDefaults`: Merges a schema's default values into a data table, filling in any missing fields without overwriting existing ones. Use this to ensure game config or save data always has complete fields even when the user provides only partial overrides.

## References

- `runtime`: Imports or references `src/runtime/`. Cross-group dependency from `Foundations` into `Core Runtime`.

## Notes

- Keep this module reference synchronized with `src/serial/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
