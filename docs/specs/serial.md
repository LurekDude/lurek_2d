# `serial` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundations |
| **Status** | Implemented |
| **Lua API** | `lurek.codec` |
| **Source** | `src/serial/` |
| **Rust Tests** | `tests/rust/unit/serial_tests.rs`; inline tests in `src/serial/csv.rs`, `src/serial/json.rs`, `src/serial/toml.rs`, `src/serial/yaml.rs` |
| **Lua Tests** | `tests/lua/unit/test_serial.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Foundations` |

---

## Summary

The `serial` module owns structured text serialization for Lurek2D. It defines `SerialValue` as a format-neutral intermediate tree and then converts between that tree and concrete text formats such as JSON, TOML, and CSV.

This module exists so the Lua API can expose one consistent `lurek.codec` namespace instead of making game code learn different crate-specific value models. The module's core design is that each format driver only needs to translate to and from `SerialValue`, while the Lua bridge handles table conversion separately.

`serial` intentionally does not own binary packing, compression, hashing, or raw byte-buffer manipulation; those belong to `src/data/`. It also does not own file I/O, save orchestration, or config loading policy. The `yaml.rs` file remains on disk, but the live module surface excludes YAML by commenting it out in `mod.rs` to respect the repository's TOML-over-YAML rule.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Foundations responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.codec.* (Lua API — src/lua_api/serial_api.rs)
    |
    v
src/serial/mod.rs
    |- csv.rs - csv
    |- json.rs - json
    |- lua_table.rs - lua_table
    |- toml.rs - toml
    |- yaml.rs - yaml
```

---

## Source Files

| File | Purpose |
|------|---------|
| `csv.rs` | Parses and writes CSV using `CsvOptions`, with support for header-based row maps or positional row sequences. |
| `json.rs` | Converts between JSON text and `SerialValue`, including the module's only built-in structured success logging. |
| `lua_table.rs` | Defines `SerialValue` plus generic conversion between that tree and Lua values and tables. |
| `mod.rs` | Declares the active format drivers and re-exports the public serialization surface used by the Lua bridge and Rust callers. |
| `toml.rs` | Converts between TOML text and `SerialValue`, enforcing TOML-specific constraints such as a table root and no null values. |
| `yaml.rs` | Implements YAML conversion helpers on disk, but the module root does not compile or re-export it. |

---

## Submodules

### `serial::csv`

Parses and writes CSV using `CsvOptions`, with support for header-based row maps or positional row sequences.

- **`CsvOptions`** (struct): Options for CSV parsing and serialization.

### `serial::json`

Converts between JSON text and `SerialValue`, including the module's only built-in structured success logging.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `serial::lua_table`

Defines `SerialValue` plus generic conversion between that tree and Lua values and tables.

- **`SerialValue`** (enum): A Lurek2D serializable value — the common intermediate representation shared by all serial format modules.

### `serial::toml`

Converts between TOML text and `SerialValue`, enforcing TOML-specific constraints such as a table root and no null values.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `serial::yaml`

Implements YAML conversion helpers on disk, but the module root does not compile or re-export it.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `SerialValue`

Common intermediate representation shared by every active text format driver.

#### `CsvOptions`

Configuration for CSV parsing and encoding.

---

## Lua API

Exposed under `lurek.codec.*` by `src/lua_api/serial_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.serial.fromJson` | Parses a JSON string and returns a Lua table. |
| `lurek.serial.toJson` | Serializes a Lua value to a JSON string. |
| `lurek.serial.fromToml` | Parses a TOML string and returns a Lua table. |
| `lurek.serial.toToml` | Serializes a Lua table to a TOML string. |
| `lurek.serial.fromCsv` | Parses a CSV string and returns a sequence of row tables. |
| `lurek.serial.toCsv` | Serializes a sequence of row tables to a CSV string. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.codec.
if lurek.codec then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 1 |
| `enum` | 1 |
| `fn` (Lua API) | 6 |
| **Total** | **8** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Foundations to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/serial/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
