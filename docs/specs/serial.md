# `serial` — Agent Reference

| Property         | Value                                                |
|------------------|------------------------------------------------------|
| **Tier**         | Tier 2 — Engine Extensions                           |
| **Status**       | Implemented — Full                                   |
| **Lua API**      | `lurek.codec`                                        |
| **Source**        | `src/serial/`                                        |
| **Rust Tests**   | `tests/rust/unit/serial_tests.rs`                    |
| **Lua Tests**    | `tests/lua/unit/test_serial.lua`                     |
| **Architecture** | —                                                    |

## Summary

The `serial` module provides format-agnostic serialization and deserialization for structured data in Lurek2D. It defines `SerialValue`, a common intermediate representation with seven variants (Null, Bool, Int, Float, Str, Seq, Map) that every format driver produces and consumes. This design allows a Lua script to load a JSON file, mutate the resulting value tree, and re-serialize it as TOML — or vice versa — without any format-specific knowledge in the game code.

Three format drivers are active: **JSON** (via `serde_json`), **TOML** (via the `toml` crate), and **CSV** (via the `csv` crate with `indexmap` for ordered column maps). A fourth driver, **YAML** (via `serde_yml`), exists on disk as `yaml.rs` but is commented out of `mod.rs` and not compiled; design constraint B-05 prohibits YAML anywhere in the project, so TOML is the canonical human-authored config format and JSON handles external interop. The `lua_table.rs` file is named after its primary use case — bridging Lua tables and text formats — but its `SerialValue` enum is format-neutral and used by all drivers.

The module performs pure string-in / string-out transformations; it contains no file I/O, no GPU interaction, no audio, and no physics. Callers supply raw text and receive parsed `SerialValue` trees (or serialized strings). File loading is handled by `lurek.fs` or `lurek.data`. The Lua API layer (`serial_api.rs`) provides bidirectional conversion between `SerialValue` and Lua tables via two internal helpers (`serial_value_to_lua` and `lua_value_to_serial`) that handle integer/float discrimination, sequence vs. map detection, and string-key enforcement.

**Scope boundary**: `serial` owns text format parsing and serialization only. Binary serialization (`pack`/`unpack`) belongs to `data`. Save-file orchestration belongs to `savegame`. Configuration loading (`conf.lua`) belongs to `engine`.

## Architecture

```
                      ┌─────────────────────────────┐
                      │       lurek.codec (Lua)      │
                      │  fromJson  toJson            │
                      │  fromToml  toToml            │
                      │  fromCsv   toCsv             │
                      └──────────┬──────────────────┘
                                 │  serial_api.rs
                  ┌──────────────┼──────────────────┐
                  │   lua_value_to_serial  /         │
                  │   serial_value_to_lua            │
                  └──────────────┬──────────────────┘
                                 │
                      ┌──────────▼──────────┐
                      │    SerialValue      │
                      │  (lua_table.rs)     │
                      │  Null│Bool│Int│Float │
                      │  Str │Seq │Map      │
                      └──┬───┬───┬───┬──────┘
                         │   │   │   │
              ┌──────────┘   │   │   └─────────────┐
              ▼              ▼   ▼                  ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐
        │ json.rs  │  │ toml.rs  │  │  csv.rs  │  │  yaml.rs     │
        │serde_json│  │toml crate│  │csv crate │  │(disabled)    │
        └──────────┘  └──────────┘  └──────────┘  └──────────────┘
```

## Source Files

| File           | Purpose                                                                                   |
|----------------|-------------------------------------------------------------------------------------------|
| `mod.rs`       | Module root — declares submodules, re-exports public functions and types.                 |
| `lua_table.rs` | Defines `SerialValue`, the common intermediate representation shared by all format drivers.|
| `json.rs`      | JSON parsing (`from_json`) and serialization (`to_json`) via `serde_json`.                |
| `toml.rs`      | TOML parsing (`from_toml`) and serialization (`to_toml`) via the `toml` crate.            |
| `csv.rs`       | CSV parsing (`from_csv`) and serialization (`to_csv`) via the `csv` crate with `CsvOptions`.|
| `yaml.rs`      | YAML parsing and serialization via `serde_yml`. **Disabled** — commented out in `mod.rs`. |

## Submodules

### `serial::lua_table`

Defines the common intermediate representation shared by all format drivers.

- **`SerialValue`** (enum): A seven-variant tagged union representing any serializable value — Null, Bool, Int, Float, Str, Seq, or Map. Maps use `IndexMap<String, SerialValue>` for insertion-order preservation.

### `serial::json`

JSON parsing and serialization via `serde_json`. Converts between `serde_json::Value` and `SerialValue` through internal `json_to_serial` / `serial_to_json` helpers. Emits structured log messages (`SR01_JSON_OK`, `SR03_JSON_ENC`) on success.

### `serial::toml`

TOML parsing and serialization via the `toml` crate. The `to_toml` function requires a `Map` at the root (TOML spec mandates a top-level table). Datetime values are preserved as strings during parsing. Null values produce an error during serialization because TOML has no null type.

### `serial::csv`

CSV parsing and serialization via the `csv` crate. Uses `CsvOptions` to configure the delimiter byte and header presence.

- **`CsvOptions`** (struct): Configuration for CSV parsing/serialization — `delimiter` (`u8`, default `b','`) and `has_headers` (`bool`, default `true`).

When `has_headers` is true, each parsed row is a `SerialValue::Map` keyed by column headers. When false, each row is a `SerialValue::Seq` of string values. Complex nested values are serialized as the literal string `"[complex]"`.

### `serial::yaml` *(disabled)*

YAML parsing and serialization via `serde_yml`. The submodule is **commented out** in `mod.rs` and is not compiled. It remains on disk for potential future use but is excluded per design constraint B-05.

## Key Types

### Structs

#### `serial::csv::CsvOptions`

Options for CSV parsing and serialization. Controls the field delimiter byte (`delimiter`, default `b','`) and whether the first row is treated as a header row (`has_headers`, default `true`). Implements `Default`.

**Fields:**
- `delimiter` — `u8` — field separator byte.
- `has_headers` — `bool` — whether the first row contains column headers.

### Enums

#### `serial::lua_table::SerialValue`

The common intermediate representation shared by all serial format modules. Every format driver converts native crate values (e.g., `serde_json::Value`, `toml::Value`) to and from this type.

**Variants:**
- `Null` — absent or nil value.
- `Bool(bool)` — boolean.
- `Int(i64)` — 64-bit signed integer.
- `Float(f64)` — 64-bit floating-point.
- `Str(String)` — UTF-8 string.
- `Seq(Vec<SerialValue>)` — ordered sequence of values.
- `Map(IndexMap<String, SerialValue>)` — ordered string-keyed map (insertion order preserved via `indexmap`).

Derives `Debug` and `Clone`.

## Lua API

Exposed under `lurek.codec.*` by `src/lua_api/serial_api.rs`. The API provides six functions covering three formats (JSON, TOML, CSV), each with a parse (`from*`) and serialize (`to*`) direction. Two internal helper functions (`serial_value_to_lua` and `lua_value_to_serial`) handle bidirectional conversion between `SerialValue` trees and Lua tables. Integer/float discrimination is performed automatically: whole-number floats within `i64` range are promoted to `Int`.

| Function                                      | Description                                                        |
|-----------------------------------------------|--------------------------------------------------------------------|
| `lurek.codec.fromJson(s)`                     | Parse a JSON string, return a Lua table.                           |
| `lurek.codec.toJson(value, pretty?)`          | Serialize a Lua value to a JSON string. `pretty` defaults to false.|
| `lurek.codec.fromToml(s)`                     | Parse a TOML string, return a Lua table.                           |
| `lurek.codec.toToml(value)`                   | Serialize a Lua table to a TOML string. Root must be a table.      |
| `lurek.codec.fromCsv(s, delimiter?, headers?)`| Parse a CSV string. `delimiter` defaults to `","`, `headers` to true.|
| `lurek.codec.toCsv(value, delimiter?, headers?)`| Serialize a sequence of row tables to a CSV string.              |

## Lua Examples

```lua
-- JSON round-trip
function lurek.init()
    local data = { name = "Lurek2D", version = 4, features = { "physics", "audio" } }

    -- Serialize to JSON (pretty-printed)
    local json = lurek.codec.toJson(data, true)
    print(json)

    -- Parse back
    local parsed = lurek.codec.fromJson(json)
    print(parsed.name)       -- "Lurek2D"
    print(parsed.version)    -- 4
    print(parsed.features[1]) -- "physics"
end
```

```lua
-- TOML config parsing
function lurek.init()
    local toml_str = lurek.fs.read("settings.toml")
    local cfg = lurek.codec.fromToml(toml_str)
    print(cfg.window.title)
    print(cfg.window.width)

    -- Modify and write back
    cfg.window.width = 1920
    local out = lurek.codec.toToml(cfg)
    lurek.fs.write("settings.toml", out)
end
```

```lua
-- CSV data loading
function lurek.init()
    local csv_text = "name,score\nalice,100\nbob,85\n"
    local rows = lurek.codec.fromCsv(csv_text)
    for i, row in ipairs(rows) do
        print(row.name .. ": " .. row.score)
    end

    -- Tab-separated with custom delimiter
    local tsv = lurek.codec.fromCsv("a\tb\n1\t2", "\t")
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 1     |
| `enum`     | 1     |
| `fn` (pub) | 6     |
| **Total**  | **8** |

Note: counts reflect the active (compiled) surface only. The disabled `yaml.rs` adds 2 more pub functions that are not re-exported.

## References

| Module       | Relationship | Notes                                                            |
|--------------|--------------|------------------------------------------------------------------|
| `math`       | Imports from | Baseline leaf — `serial` has no direct math dependency.          |
| `engine`     | Imports from | Uses `log_messages` constants (`SR01_JSON_OK`, `SR03_JSON_ENC`). |
| `data`       | Similar      | `data` owns binary formats (pack/unpack, compression, hashing) and exposes `parseToml`/`encodeToml` for lightweight TOML conversion in binary pipelines. `serial` (`lurek.codec`) is the canonical text-format entry point — use it for format-agnostic code that may need JSON, TOML, or CSV interchangeably on the same code path. |
| `savegame`   | Related      | `savegame` orchestrates save/load; may use `serial` for structured data persistence. |
| `filesystem` | Related      | `filesystem` provides file I/O; `serial` provides string parsing. Combine them for file-based config. |
| `lua_api`    | Imported by  | `serial_api.rs` binds the public API to `lurek.codec.*`.         |

## Notes

- **Constraint B-05**: TOML is the human-authored config format; JSON is for external interop. YAML is not used anywhere in the project. The `yaml.rs` file is kept on disk but commented out of `mod.rs` and the `serde_yml` dependency has been dropped.
- **No file I/O**: The module is purely string-in / string-out. Game scripts combine `lurek.fs.read()` with `lurek.codec.fromJson()` (or similar) to load structured data from files.
- **Map ordering**: `SerialValue::Map` uses `IndexMap` (from the `indexmap` crate) to preserve insertion order. This is important for CSV column ordering and for producing stable TOML/JSON output.
- **Integer promotion**: The `lua_value_to_serial` helper in `serial_api.rs` promotes whole-number Lua floats to `SerialValue::Int` when they fit in `i64` range.
- **TOML root constraint**: `to_toml` requires the root value to be a Map (i.e., a Lua table with string keys). Calling it with a sequence or scalar produces an error.
- **CSV field flattening**: When serializing, nested `Seq` or `Map` values inside a CSV row are rendered as the literal string `"[complex]"` rather than erroring, since CSV has no nested-structure syntax.
- **Logging**: Only the JSON driver emits structured log messages (`SR01`, `SR03`) on parse/encode success. TOML and CSV drivers do not log.
- **Error handling**: All format drivers return `Result<_, String>` with descriptive error messages prefixed by the format name (e.g., `"JSON parse error: ..."`, `"TOML encode error: ..."`). The Lua API converts these to `LuaError::RuntimeError`.

## Lua Examples

```lua
-- Example: Basic serial usage
function lurek.init()
    -- Encode a Lua table to a binary blob
    local obj = lurek.codec.serial()
end

function lurek.process(dt)
    -- Decode and apply the stored blob each frame if needed
end
```

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 1 |
| `enum`   | 1 |
| `fn`     | 8 |
| **Total** | **10** |

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `engine` | Imports from | Uses SharedState, EngineError |
| `math` | Imports from | Vec2, Color, Rect |
| `lua_api` | Imported by | Binds public API to Lua |
| `savegame` | Used by | Serialises save-game structs via `lurek.codec.serial()` |

## Notes

Key facts an agent must know before editing this module:
- External crate constraints (version, thread-safety, API limitations)
- Hardware or OS-specific behaviour (e.g., headless fallback on CI)
- Known limitations or intentional omissions
- Best practices and anti-patterns for this module
- What Lua scripts will break if the API changes
