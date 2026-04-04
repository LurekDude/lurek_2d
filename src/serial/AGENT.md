# `serial` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Core Engine Subsystems |
| **Lua API** | `luna.serial` |
| **Source** | `src/serial/` |
| **Tests** | `tests/unit/serial_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_serial.lua` |

## Summary

The serial module provides format-agnostic serialization and deserialization
for the Luna2D engine. It supports JSON, TOML, CSV, and YAML formats through a
shared `SerialValue` intermediate type that maps cleanly to Lua tables.

All parsers return a `SerialValue` tree and all encoders accept one. The Lua
API (`luna.serial.*`) converts between `SerialValue` and Lua tables
automatically. Map keys are always strings; sequences use consecutive integer
indices when returned to Lua.

Binary data persistence belongs in `src/binary/` (`luna.binary.*`).
Full save-game orchestration belongs in `src/savegame/` (`luna.savegame.*`).

## Architecture

```
serial/
  │
  ├── SerialValue ── shared intermediate type (Null/Bool/Int/Float/Str/Seq/Map)
  │                  Map uses IndexMap<String, SerialValue> for insertion order
  │
  ├── json ── from_json / to_json via serde_json
  │
  ├── toml ── from_toml / to_toml via toml = "0.8"
  │
  ├── csv ── from_csv / to_csv via csv = "1" with CsvOptions
  │
  └── yaml ── from_yaml / to_yaml via serde_yml = "0.9"
```

## Source Files

| File | Purpose |
|------|---------|
| `lua_table.rs` | `SerialValue` intermediate enum and `SerialError` type |
| `json.rs` | JSON parsing and encoding |
| `toml.rs` | TOML parsing and encoding (migrated from `binary::toml_convert`) |
| `csv.rs` | CSV parsing and encoding with configurable delimiter and header options |
| `yaml.rs` | YAML parsing and encoding |

## Submodules

### `serial::lua_table`

Shared intermediate type.

- **`SerialValue`** (enum): `Null`, `Bool(bool)`, `Int(i64)`, `Float(f64)`, `Str(String)`, `Seq(Vec<SerialValue>)`, `Map(IndexMap<String, SerialValue>)`.

### `serial::json`

JSON serialization using `serde_json`.

- **`from_json`** (fn): Parse a JSON string into `SerialValue`. Errors prefixed with `"JSON parse error: "`.
- **`to_json`** (fn): Encode `SerialValue` to JSON string. Pass `pretty = true` for indented output.

### `serial::toml`

TOML serialization using the `toml` crate.

- **`from_toml`** (fn): Parse a TOML string into `SerialValue`. Errors prefixed with `"TOML parse error: "`.
- **`to_toml`** (fn): Encode `SerialValue` to TOML string. Errors prefixed with `"TOML encode error: "`.

### `serial::csv`

CSV serialization using the `csv` crate.

- **`CsvOptions`** (struct): `delimiter: u8` (default `b','`), `has_headers: bool` (default `true`). Implements `Default`.
- **`from_csv`** (fn): Parse CSV into `SerialValue::Seq` of `SerialValue::Map` rows. Header row becomes map keys when `has_headers = true`.
- **`to_csv`** (fn): Encode `SerialValue` (Seq of Maps or Seq of Seqs) to CSV string.

### `serial::yaml`

YAML serialization using `serde_yml`.

- **`from_yaml`** (fn): Parse a YAML string into `SerialValue`. Errors prefixed with `"YAML parse error: "`.
- **`to_yaml`** (fn): Encode `SerialValue` to YAML string. Errors prefixed with `"YAML encode error: "`.

## Lua API

Exposed under `luna.serial.*` by `src/lua_api/serial_api.rs`.

| Lua Function | Description |
|---|---|
| `luna.serial.fromJson(str)` | Parse JSON string → Lua table |
| `luna.serial.toJson(table, pretty?)` | Encode Lua table → JSON string |
| `luna.serial.fromToml(str)` | Parse TOML string → Lua table |
| `luna.serial.toToml(table)` | Encode Lua table → TOML string |
| `luna.serial.fromCsv(str, delimiter?, hasHeaders?)` | Parse CSV → Lua table (seq of maps) |
| `luna.serial.toCsv(table, delimiter?, hasHeaders?)` | Encode Lua table → CSV string |
| `luna.serial.fromYaml(str)` | Parse YAML string → Lua table |
| `luna.serial.toYaml(table)` | Encode Lua table → YAML string |

## Conventions

- All `from_*` functions propagate errors to Lua as descriptive `LuaError` messages
- `to_*` functions accept any Lua table; sequences are detected by consecutive integer keys from 1
- `nil` values in Lua tables map to `SerialValue::Null` and are preserved through round-trips (YAML and JSON only; TOML does not support null)
- Floats that are whole numbers (e.g. `42.0`) are coerced to `Int` when converting from Lua to `SerialValue`
