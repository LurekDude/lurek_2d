# `serial` — Agent Reference

| Property         | Value                                                |
|------------------|------------------------------------------------------|
| **Tier**         | Tier 2 — Engine Extensions                           |
| **Status**       | Implemented — Full                                   |
| **Lua API**      | `luna.serial`                                        |
| **Source**        | `src/serial/`                                        |
| **Rust Tests**   | `tests/rust/unit/serial_tests.rs`                    |
| **Lua Tests**    | `tests/lua/unit/test_serial.lua`                     |
| **Architecture** | —                                                    |

## Purpose

The `serial` module provides format-agnostic serialization and deserialization for structured data in Luna2D. It defines `SerialValue`, a common intermediate representation with seven variants (Null, Bool, Int, Float, Str, Seq, Map) that every format driver produces and consumes. This design allows a Lua script to load a JSON file, mutate the resulting value tree, and re-serialize it as TOML — or vice versa — without any format-specific knowledge in the game code.

## Source Files

| File           | Purpose                                                                                   |
|----------------|-------------------------------------------------------------------------------------------|
| `mod.rs`       | Module root — declares submodules, re-exports public functions and types.                 |
| `lua_table.rs` | Defines `SerialValue`, the common intermediate representation shared by all format drivers.|
| `json.rs`      | JSON parsing (`from_json`) and serialization (`to_json`) via `serde_json`.                |
| `toml.rs`      | TOML parsing (`from_toml`) and serialization (`to_toml`) via the `toml` crate.            |
| `csv.rs`       | CSV parsing (`from_csv`) and serialization (`to_csv`) via the `csv` crate with `CsvOptions`.|
| `yaml.rs`      | YAML parsing and serialization via `serde_yml`. **Disabled** — commented out in `mod.rs`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/serial.md`](../../specs/serial.md)

_Update both this file **and** `specs/serial.md` whenever source files, public types, or Lua bindings change._
