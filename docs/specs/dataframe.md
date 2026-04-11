# `dataframe` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundations |
| **Status** | Implemented |
| **Lua API** | `lurek.dataframe` |
| **Source** | `src/dataframe/` |
| **Rust Tests** | `tests/rust/unit/dataframe_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_dataframe.lua`; `tests/lua/stress/test_dataframe_stress.lua`; `tests/lua/integration/test_compute_dataframe.lua`; `tests/lua/golden/test_dataframe_golden.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Foundations` |

---

## Summary

The `dataframe` module owns named-column tabular data in Lurek2D. It provides an in-memory `DataFrame` type for structured records, a `Database` catalog for multiple named tables, and the query, serialization, and SQL helpers needed to work with that data from Lua.

This module exists to cover the part of data processing that raw byte buffers and ndarrays do not solve well: heterogeneous rows with named fields, table joins, grouping, descriptive statistics, and lightweight ad hoc querying. Its storage is column-major so scans, filters, and numeric analytics can work one column at a time without forcing callers to manually reorganize row data.

`dataframe` intentionally does not own low-level binary buffer manipulation, compression, or dense numeric tensor math. Use `src/data/` for raw bytes and pack formats, and `src/compute/` for homogeneous numeric arrays and grid operations. It also does not own persistent storage APIs; callers bring strings or tables in, and the filesystem layer handles loading and saving.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Foundations responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.dataframe.* (Lua API — src/lua_api/dataframe_api.rs)
    |
    v
src/dataframe/mod.rs
    |- frame.rs - frame
    |- query.rs - query
    |- serial.rs - serial
    |- sql.rs - sql
```

---

## Source Files

| File | Purpose |
|------|---------|
| `frame.rs` | Defines `CellValue`, `ColRef`, `DataFrame`, and `Database`, including column and row CRUD plus deterministic random test-data generation. |
| `mod.rs` | Declares the dataframe submodules and re-exports the main table and database types. |
| `query.rs` | Implements most table-manipulation behavior such as filtering, sorting, slicing, projection, grouping, joins, sampling, nil handling, and numeric summary statistics. |
| `serial.rs` | Handles DataFrame serialization and parsing for CSV, JSON, LVDF binary, and printable string-table output. |
| `sql.rs` | Implements the hand-written SQL tokenizer, parser, expression evaluator, and execution engine for single-table and multi-table queries. |

---

## Submodules

### `dataframe::frame`

Defines `CellValue`, `ColRef`, `DataFrame`, and `Database`, including column and row CRUD plus deterministic random test-data generation.

- **`CellValue`** (enum): A single cell value in a DataFrame column.
- **`ColRef`** (enum): Column reference: string name or 1-based integer index.
- **`DataFrame`** (struct): In-memory column-major tabular data.
- **`Database`** (struct): Named catalog of DataFrames.

### `dataframe::query`

Implements most table-manipulation behavior such as filtering, sorting, slicing, projection, grouping, joins, sampling, nil handling, and numeric summary statistics.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `dataframe::serial`

Handles DataFrame serialization and parsing for CSV, JSON, LVDF binary, and printable string-table output.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `dataframe::sql`

Implements the hand-written SQL tokenizer, parser, expression evaluator, and execution engine for single-table and multi-table queries.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `CellValue`

Per-cell tagged value used throughout the module.

#### `ColRef`

Column selector that can resolve either a name or a 1-based index.

#### `DataFrame`

Core column-major table type with named columns and query methods.

#### `Database`

Named collection of DataFrames used for multi-table workflows and SQL joins.

#### `LuaDataFrame`

Lua-facing shared wrapper over `DataFrame`.

#### `LuaDatabase`

Lua-facing shared wrapper over `Database`.

---

## Lua API

Exposed under `lurek.dataframe.*` by `src/lua_api/dataframe_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.dataframe.newDataFrame` | Creates a new empty DataFrame. |
| `lurek.dataframe.newDatabase` | Creates a new empty Database. |
| `lurek.dataframe.fromTable` | Creates a DataFrame from an array of row tables. |
| `lurek.dataframe.fromCSV` | Parses a CSV string into a DataFrame. |
| `lurek.dataframe.fromJSON` | Parses a JSON string into a DataFrame. |
| `lurek.dataframe.fromBinary` | Deserializes a binary LVDF string into a DataFrame. |
| `lurek.dataframe.random` | Generates a DataFrame with random data from column definitions. |

### `DataFrame` Methods

| Method | Description |
|--------|-------------|
| `dataframe:nrows(...)` | Returns the number of rows. |
| `dataframe:ncols(...)` | Returns the number of columns. |
| `dataframe:columns(...)` | Returns a table of column names. |
| `dataframe:count(...)` | Returns the row count (alias for nrows). |
| `dataframe:removeColumn(...)` | Removes a column by name or index. |
| `dataframe:rename(...)` | Renames a column. |
| `dataframe:getColumn(...)` | Returns all values in a column as a table. |
| `dataframe:addRow(...)` | Adds a row from an optional table of name-value pairs, returns 1-based index. |
| `dataframe:removeRow(...)` | Removes a row by 1-based index. |
| `dataframe:getRow(...)` | Returns a row as a table of name-value pairs. |
| `dataframe:getValue(...)` | Returns a single cell value. |
| `dataframe:head(...)` | Returns the first n rows (default 5). |
| `dataframe:tail(...)` | Returns the last n rows (default 5). |
| `dataframe:slice(...)` | Returns rows from start to end (1-based, inclusive). |
| `dataframe:select(...)` | Selects a subset of columns, returns a new DataFrame. |
| `dataframe:unique(...)` | Returns unique values in a column as a table. |
| `dataframe:groupBy(...)` | Groups rows by column value, returns a table of DataFrames keyed by value. |
| `dataframe:merge(...)` | Appends rows from another DataFrame in-place. |
| `dataframe:countBy(...)` | Counts distinct values in a column, returns a DataFrame with value and count columns. |
| `dataframe:dropNil(...)` | Removes rows where the given column is nil, returns a new DataFrame. |
| `dataframe:sample(...)` | Returns a random sample of n rows. |
| `dataframe:describe(...)` | Returns descriptive statistics for all numeric columns. |
| `dataframe:sum(...)` | Returns the sum of numeric values in a column. |
| `dataframe:mean(...)` | Returns the mean of numeric values in a column. |
| `dataframe:min(...)` | Returns the minimum numeric value in a column. |
| `dataframe:max(...)` | Returns the maximum numeric value in a column. |
| `dataframe:median(...)` | Returns the median of numeric values in a column. |
| `dataframe:stddev(...)` | Returns the population standard deviation of numeric values in a column. |
| `dataframe:variance(...)` | Returns the population variance of numeric values in a column. |
| `dataframe:fillNil(...)` | Replaces nil values in a column with the given value. |
| `dataframe:toCSV(...)` | Serializes this DataFrame to a CSV string. |
| `dataframe:toJSON(...)` | Serializes this DataFrame to a JSON string. |
| `dataframe:toBinary(...)` | Serializes this DataFrame to a binary LVDF string. |
| `dataframe:toTable(...)` | Converts this DataFrame to a Lua table of row tables. |
| `dataframe:toString(...)` | Returns a formatted string table representation. |
| `dataframe:query(...)` | Executes a SQL query against this DataFrame. |
| `dataframe:clone(...)` | Returns a deep copy of this DataFrame. |
| `dataframe:type(...)` | Returns the type name of this object. |
| `dataframe:typeOf(...)` | Returns true if this object is of the given type. |

### `Database` Methods

| Method | Description |
|--------|-------------|
| `database:getTable(...)` | Returns a copy of a table by name, or nil if not found. |
| `database:removeTable(...)` | Removes a table by name. |
| `database:hasTable(...)` | Returns true if a table with the given name exists. |
| `database:listTables(...)` | Returns a table of all table names. |
| `database:tableCount(...)` | Returns the number of tables. |
| `database:clear(...)` | Removes all tables. |
| `database:merge(...)` | Merges all tables from another Database into this one. |
| `database:toJSON(...)` | Serializes all tables to a JSON object string. |
| `database:query(...)` | Executes a SQL query against the database tables. |
| `database:type(...)` | Returns the type name of this object. |
| `database:typeOf(...)` | Returns true if this object is of the given type. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.dataframe.
if lurek.dataframe then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 2 |
| `enum` | 2 |
| `fn` (Lua API) | 57 |
| **Total** | **61** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Foundations to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/dataframe/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
