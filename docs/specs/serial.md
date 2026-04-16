# serial

## General Info

- Module group: `Foundations`
- Source path: `src/serial/`
- Lua API path(s): `src/lua_api/serial_api.rs`
- Primary Lua namespace: `lurek.codec`
- Rust test path(s): tests/rust/unit/serial_tests.rs; inline tests in src/serial/csv.rs, src/serial/json.rs, src/serial/toml.rs, src/serial/yaml.rs
- Lua test path(s): tests/lua/unit/test_serial.lua

## Summary

The `serial` module provides Lurek2D's format-agnostic text serialization and deserialization. Its central type is `SerialValue`, a recursive enum — Null, Bool, Number(f64), Text(String), List(Vec<SerialValue>), Map(IndexMap<String, SerialValue>) — that can represent any hierarchical data.

Format modules operate on `SerialValue`, converting to and from format-specific string representations. **TOML** is the preferred human-authored config format (design assumption B-05): `serial::toml::to_string(v)` and `from_str(s)`. **JSON** is provided for external interop: `serial::json::to_string(v)` and `from_str(s)`. **CSV** supports configurable header presence, delimiter character, and quote character via `CsvOptions`: `to_csv(rows, opts)` and `from_csv(text, opts)`. **Lua table notation** emits a Lua-readable table literal for use in generated code. YAML is explicitly absent (design assumption B-05).

The module performs no file I/O — callers supply strings, receive strings. File reading and writing is the responsibility of `filesystem`. The `save` module uses `serial::to_toml` and `from_toml` to serialize save collector outputs. The `data/dataframe` serial submodules re-use `serial::CsvOptions` for DataFrame CSV round-trips.

A `Codec` helper trait provides a unified `encode(value)` / `decode(text)` interface implemented for all four formats, enabling code that needs to switch serialization format at runtime without branching on format names.

The new `rle.rs` source file adds `RleEncoder` and `RleDecoder`, a run-length encoding implementation for compressing repetitive binary sequences such as tilemap rows, sprite palette data, or binary save blobs. Lua scripts access these through `lurek.codec.*`, enabling lightweight in-process compression for data that benefits from RLE's simplicity and zero-dependency overhead without pulling in a full compression library.

**Scope boundary**: Foundations tier. Depends only on external crates (toml, serde_json, csv, indexmap). Lua bridge in `src/lua_api/serial_api.rs` as `lurek.codec.*`.

## Files

- `csv.rs`: Parses and writes CSV using `CsvOptions`, with support for header-based row maps or positional row sequences.
- `json.rs`: Converts between JSON text and `SerialValue`, including the module's only built-in structured success logging.
- `lua_table.rs`: Defines `SerialValue` plus generic conversion between that tree and Lua values and tables.
- `mod.rs`: Declares the active format drivers and re-exports the public serialization surface used by the Lua bridge and Rust callers.
- `msgpack.rs`: MessagePack encoding and decoding for Lurek2D.
- `schema.rs`: Schema validation for Lurek2D serialized values.
- `toml.rs`: Converts between TOML text and `SerialValue`, enforcing TOML-specific constraints such as a table root and no null values.
- `xml.rs`: XML parsing for Lurek2D (read-only).
- `yaml.rs`: Implements YAML conversion helpers on disk, but the module root does not compile or re-export it.

## Types

- `CsvOptions` (`struct`, `csv.rs`): Configuration for CSV parsing and encoding. It controls delimiter choice and whether the first row should be treated as headers.
- `SerialValue` (`enum`, `lua_table.rs`): Common intermediate representation shared by every active text format driver. It is the central type that keeps JSON, TOML, CSV, and Lua-table conversion decoupled from one another.
- `MsgValue` (`enum`, `msgpack.rs`): A serde-compatible mirror of `SerialValue` used as the msgpack bridge.

## Functions

- `from_csv` (`csv.rs`): Parse a CSV string into a `SerialValue`.
- `to_csv` (`csv.rs`): Serialize a `SerialValue` to a CSV string.
- `from_json` (`json.rs`): Parse a JSON string into a `SerialValue`.
- `to_json` (`json.rs`): Serialize a `SerialValue` to a JSON string.
- `to_lua` (`lua_table.rs`): Converts a `SerialValue` tree into a Lua value tree.
- `from_lua` (`lua_table.rs`): Converts a Lua value tree into a `SerialValue` tree.
- `encode` (`msgpack.rs`): Encode a `SerialValue` tree to MessagePack bytes.
- `decode` (`msgpack.rs`): Decode MessagePack bytes into a `SerialValue` tree.
- `validate` (`schema.rs`): Validate a `SerialValue` tree against a schema.
- `from_toml` (`toml.rs`): Parse a TOML string into a `SerialValue`.
- `to_toml` (`toml.rs`): Serialize a `SerialValue` to a TOML string.
- `decode` (`xml.rs`): Parse an XML string into a `SerialValue` tree.
- `from_yaml` (`yaml.rs`): Parse a YAML string into a `SerialValue`.
- `to_yaml` (`yaml.rs`): Serialize a `SerialValue` to a YAML string.

## Lua API Reference

- Binding path(s): `src/lua_api/serial_api.rs`
- Namespace: `lurek.codec`

### Module Functions
- `lurek.serial.fromJson`: Parses a JSON string and returns a Lua table.
- `lurek.serial.toJson`: Serializes a Lua value to a JSON string.
- `lurek.serial.fromToml`: Parses a TOML string and returns a Lua table.
- `lurek.serial.toToml`: Serializes a Lua table to a TOML string.
- `lurek.serial.fromCsv`: Parses a CSV string and returns a sequence of row tables.
- `lurek.serial.toCsv`: Serializes a sequence of row tables to a CSV string.
- `lurek.serial.encodeMsgPack`: Encodes a Lua table to a binary MessagePack string.
- `lurek.serial.decodeMsgPack`: Decodes a binary MessagePack string into a Lua table.
- `lurek.serial.decodeXml`: Parses an XML string and returns a nested Lua table.
- `lurek.serial.validate`: Validates a Lua table against a schema table.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/serial/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
