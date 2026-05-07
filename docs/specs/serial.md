# serial

## Overview

`serial` is a Foundations module that converts between engine values and text or binary serialization formats.
It is format-agnostic through `SerialValue` and performs no filesystem I/O.

Supported formats:
- JSON
- TOML
- CSV
- MessagePack
- XML (decode only)
- INI (decode only)

YAML is intentionally not supported (constraint B-05).

## Ownership

`serial` owns:
- The `SerialValue` intermediate representation.
- Format adapters in `src/serial/`.
- Schema validation and schema-default patching.
- Unified runtime codec dispatch and auto-detection.

`serial` does not own:
- File reads/writes (`filesystem`, `save` own persistence).
- Lua binding registration (`src/lua_api/serial_api.rs` owns binding glue only).
- Domain-level save semantics.

## Public API

Rust (`src/serial/mod.rs` re-exports):
- `from_json`, `to_json`
- `from_toml`, `to_toml`
- `from_ini`
- `from_csv`, `from_csv_reader`, `to_csv`, `CsvOptions`
- `from_msgpack`, `to_msgpack`
- `from_xml`
- `validate_schema`, `apply_schema_defaults`
- Unified codec API:
  - `SerialFormat`
  - `detect_format`
  - `decode_text`, `decode_bytes`
  - `encode`
  - `DecodeOptions`, `EncodeOptions`, `EncodedValue`

Lua (`lurek.serial`):
- Existing format functions: `fromJson`, `toJson`, `fromToml`, `toToml`, `fromIni`, `fromCsv`, `toCsv`, `encodeMsgPack`, `decodeMsgPack`, `decodeXml`, `validate`
- Unified helpers: `detectFormat`, `decode`, `encode`, `applyDefaults`

## Invariants

- `serial` is pure conversion logic with no direct file I/O.
- `SerialValue::Map` keys are string-only.
- CSV options use single-byte delimiters.
- XML encode is unsupported by design.
- MessagePack decode rejects trailing bytes after root payload.
- Schema validation reports field paths on failure.
- Schema defaults are applied recursively via `default`, `fields`, and `items`.

## Dependencies

Tier: Foundations.

Direct dependencies are codec libraries and core containers:
- `serde_json`
- `toml`
- `csv`
- `rmp-serde`
- `roxmltree`
- `indexmap`

Dependency direction:
- Lower-tier imports only (utility/runtime logging types).
- Higher tiers may depend on `serial`.
- `serial` must not depend on feature-system or platform-service modules.

## Test Coverage

Rust:
- `tests/rust/unit/serial_tests.rs`

Lua:
- `tests/lua/unit/test_serial_core_unit.lua`
- `tests/lua/golden/test_serial_golden.lua`
- `tests/lua/stress/test_serial_stress.lua`
- `tests/lua/integration/test_serial_filesystem.lua`

Coverage scope:
- Lua API behavior for all public `lurek.serial.*` functions.
- Rust internals for Lua bridge, codec dispatch, streaming CSV reader, and schema defaults.

## References

- Source: `src/serial/`
- Lua binding: `src/lua_api/serial_api.rs`
- Example usage: `content/examples/serial.lua`
- Architecture constraints: `docs/architecture/philosophy.md`
- Changelog: `docs/CHANGELOG.md`
