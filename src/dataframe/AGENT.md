# dataframe

## Module Info
- Module name: `dataframe`
- Module group: `Foundations`
- Spec path: `docs/specs/dataframe.md`
- Lua API path(s): `src/lua_api/dataframe_api.rs`
- Rust test path(s): `tests/rust/unit/dataframe_tests.rs`
- Lua test path(s): `tests/lua/unit/test_dataframe.lua`; `tests/lua/stress/test_dataframe_stress.lua`; `tests/lua/integration/test_compute_dataframe.lua`; `tests/lua/golden/test_dataframe_golden.lua`

## Module Purpose
The `dataframe` module owns named-column tabular data in Lurek2D. It provides an in-memory `DataFrame` type for structured records, a `Database` catalog for multiple named tables, and the query, serialization, and SQL helpers needed to work with that data from Lua.

This module exists to cover the part of data processing that raw byte buffers and ndarrays do not solve well: heterogeneous rows with named fields, table joins, grouping, descriptive statistics, and lightweight ad hoc querying. Its storage is column-major so scans, filters, and numeric analytics can work one column at a time without forcing callers to manually reorganize row data.

`dataframe` intentionally does not own low-level binary buffer manipulation, compression, or dense numeric tensor math. Use `src/data/` for raw bytes and pack formats, and `src/compute/` for homogeneous numeric arrays and grid operations. It also does not own persistent storage APIs; callers bring strings or tables in, and the filesystem layer handles loading and saving.

## Files
- `mod.rs`: Declares the dataframe submodules and re-exports the main table and database types.
- `frame.rs`: Defines `CellValue`, `ColRef`, `DataFrame`, and `Database`, including column and row CRUD plus deterministic random test-data generation.
- `query.rs`: Implements most table-manipulation behavior such as filtering, sorting, slicing, projection, grouping, joins, sampling, nil handling, and numeric summary statistics.
- `serial.rs`: Handles DataFrame serialization and parsing for CSV, JSON, LVDF binary, and printable string-table output.
- `sql.rs`: Implements the hand-written SQL tokenizer, parser, expression evaluator, and execution engine for single-table and multi-table queries.

## Key Types
- `CellValue`: Per-cell tagged value used throughout the module. It keeps nil, number, text, and boolean data explicit without forcing every column to share one type.
- `ColRef`: Column selector that can resolve either a name or a 1-based index. It gives the Lua bridge and Rust helpers one shared way to address columns.
- `DataFrame`: Core column-major table type with named columns and query methods. Most module behavior is expressed as methods on this type.
- `Database`: Named collection of DataFrames used for multi-table workflows and SQL joins. It is deliberately small and acts as a query catalog rather than a storage engine.
- `LuaDataFrame`: Lua-facing shared wrapper over `DataFrame`. It keeps mlua-specific borrowing rules out of the domain module while exposing the full table API to scripts.
- `LuaDatabase`: Lua-facing shared wrapper over `Database`. It provides the Lua namespace for table catalogs and database-level queries.