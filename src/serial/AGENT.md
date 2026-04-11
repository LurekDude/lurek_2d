# serial

## Module Info
- Module name: `serial`
- Module group: `Foundations`
- Spec path: `docs/specs/serial.md`
- Lua API path(s): `src/lua_api/serial_api.rs`
- Rust test path(s): `tests/rust/unit/serial_tests.rs`; inline tests in `src/serial/csv.rs`, `src/serial/json.rs`, `src/serial/toml.rs`, `src/serial/yaml.rs`
- Lua test path(s): `tests/lua/unit/test_serial.lua`

## Module Purpose
The `serial` module owns structured text serialization for Lurek2D. It defines `SerialValue` as a format-neutral intermediate tree and then converts between that tree and concrete text formats such as JSON, TOML, and CSV.

This module exists so the Lua API can expose one consistent `lurek.codec` namespace instead of making game code learn different crate-specific value models. The module's core design is that each format driver only needs to translate to and from `SerialValue`, while the Lua bridge handles table conversion separately.

`serial` intentionally does not own binary packing, compression, hashing, or raw byte-buffer manipulation; those belong to `src/data/`. It also does not own file I/O, save orchestration, or config loading policy. The `yaml.rs` file remains on disk, but the live module surface excludes YAML by commenting it out in `mod.rs` to respect the repository's TOML-over-YAML rule.

## Files
- `mod.rs`: Declares the active format drivers and re-exports the public serialization surface used by the Lua bridge and Rust callers.
- `csv.rs`: Parses and writes CSV using `CsvOptions`, with support for header-based row maps or positional row sequences.
- `json.rs`: Converts between JSON text and `SerialValue`, including the module's only built-in structured success logging.
- `lua_table.rs`: Defines `SerialValue` plus generic conversion between that tree and Lua values and tables.
- `toml.rs`: Converts between TOML text and `SerialValue`, enforcing TOML-specific constraints such as a table root and no null values.
- `yaml.rs`: Implements YAML conversion helpers on disk, but the module root does not compile or re-export it.

## Key Types
- `SerialValue`: Common intermediate representation shared by every active text format driver. It is the central type that keeps JSON, TOML, CSV, and Lua-table conversion decoupled from one another.
- `CsvOptions`: Configuration for CSV parsing and encoding. It controls delimiter choice and whether the first row should be treated as headers.