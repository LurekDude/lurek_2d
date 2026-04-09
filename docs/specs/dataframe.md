# `dataframe` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.dataframe`                                     |
| **Source**      | `src/dataframe/`                                     |
| **Rust Tests** | `tests/rust/unit/dataframe_tests.rs`                 |
| **Lua Tests**  | `tests/lua/unit/test_dataframe.lua`                  |
| **Architecture** | —                                                  |

## Summary

The `dataframe` module provides an in-memory, column-major tabular data engine with named columns, a functional query API, serialization to multiple formats, and a hand-rolled SQL subset parser and executor. It is a Tier 2 engine extension that depends only on `math` and `engine` from the baseline layer.

Each cell is represented by the `CellValue` enum (`Nil`, `Number(f64)`, `Text(String)`, `Bool(bool)`), giving columns heterogeneous-but-typed data. Data is stored column-major (`data[col_index][row_index]`) for cache-friendly column scans, aggregation, and analytics. All query methods (`filter`, `sort`, `group_by`, `join`, `head`, `tail`, `slice`, `select_columns`, `unique`, `drop_nil`, `sample`) return new `DataFrame` instances without mutating the source, enabling composable pipelines from Lua.

The module includes a complete SQL subset: a hand-rolled tokenizer, recursive-descent parser, and execution engine supporting `SELECT`, `WHERE` (with `AND`/`OR`/`NOT`/`LIKE`/`IN`), `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT`/`OFFSET`, `JOIN`, and aggregate functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`). SQL queries can target a single `DataFrame` or a multi-table `Database` catalog.

Three serialization formats are supported: RFC 4180 CSV (with auto type-detection on import), JSON (array-of-objects), and LVDF — a compact binary format (`"LVDF"` magic, version 1) for fast save/load cycles. An ASCII pretty-printer (`to_string_table`) is also provided for debug display.

The `Database` type acts as a named catalog of `DataFrame` tables, supporting add/remove/get/merge operations and cross-table SQL `JOIN` queries. Deterministic random data generation (`DataFrame::random`) supports type hints (`"int"`, `"float"`, `"bool"`, `"name"`, `"id"`, `"string"`, `"email"`, `"date"`, `"phone"`, `"uuid"`, `"sentence"`) using an internal xorshift64 PRNG, making it useful for test data and procedural content.

This module is **not** for real-time per-frame simulation arrays — use `compute` (`NdArray`) for that. `dataframe` is designed for structured game data: loot tables, stat sheets, leaderboards, level databases, dialogue CSV imports, telemetry logs, and any tabular dataset that benefits from filter/sort/group/aggregate workflows.

## Architecture

```
lurek.dataframe.*  (Lua API — src/lua_api/dataframe_api.rs)
        |
        v
  +-----------------------------------------------------+
  |  DataFrame (column-major: data[col][row])           |
  |  +---------------+  +----------------------+        |
  |  | CellValue     |  | ColRef               |        |
  |  | Nil|Num|Txt|  |  | Name(String)         |        |
  |  | Bool          |  | Index(usize, 1-based) |        |
  |  +---------------+  +----------------------+        |
  |-----------------------------------------------------|
  |  frame.rs  -- Core types + column/row/random ops    |
  |  query.rs  -- filter/sort/join/group_by/analytics   |
  |  serial.rs -- CSV / JSON / LVDF binary / ASCII table|
  |  sql.rs    -- Tokenizer -> Parser -> Executor       |
  |-----------------------------------------------------|
  |  Database (HashMap<String, DataFrame>)              |
  |  Named catalog for multi-table SQL queries          |
  +-----------------------------------------------------+
        |
        v
  engine (SharedState, EngineError)  +  math (leaf)
```

## Source Files

| File        | Purpose                                                        |
|-------------|----------------------------------------------------------------|
| `mod.rs`    | Module root; re-exports `CellValue`, `ColRef`, `DataFrame`, `Database` and declares submodules |
| `frame.rs`  | Core `DataFrame` and `Database` types, `CellValue` enum, column/row CRUD, random data generation |
| `query.rs`  | Functional query methods: `filter`, `sort`, `head`, `tail`, `slice`, `select_columns`, `unique`, `group_by`, `join`, `merge`, `count_by`, `drop_nil`, `sample`, plus numeric analytics (`sum`, `mean`, `min_val`, `max_val`, `median`, `stddev`, `variance`, `describe`, `fill_nil`) |
| `serial.rs` | Serialization: `from_csv`/`to_csv` (RFC 4180), `from_json`/`to_json`, `from_binary`/`to_binary` (LVDF v1), `to_string_table` (ASCII debug), `Database::to_json` |
| `sql.rs`    | SQL tokenizer, recursive-descent parser, and executor for `query_sql` (single DataFrame) and `query_sql_database` (multi-table Database with JOIN) |

## Submodules

### `dataframe::frame`

Core DataFrame and Database types with CellValue cells.

- **`CellValue`** (enum) — A single cell value: `Nil`, `Number(f64)`, `Text(String)`, `Bool(bool)`. Implements `Display`, `PartialEq`, and `cmp_for_sort` for cross-type ordering.
- **`ColRef`** (enum) — Column reference by `Name(String)` or 1-based `Index(usize)`. Resolved to 0-based via `DataFrame::resolve_col`.
- **`DataFrame`** (struct) — In-memory column-major table with `column_names: Vec<String>` and `data: Vec<Vec<CellValue>>`. Stores data as `data[col_index][row_index]`.
- **`Database`** (struct) — Named catalog of DataFrames stored in a `HashMap<String, DataFrame>`. Supports add/remove/get/merge/list/clear and cross-table SQL queries.

### `dataframe::query`

DataFrame query, filter, sort, join, analytics, and mutation. All query methods are implemented as `impl DataFrame` methods. Key operations:

- **Filtering**: `filter(col, op, val)` with ops `==`, `!=`, `<`, `<=`, `>`, `>=`, `contains`
- **Sorting**: `sort(col, ascending)` — stable sort, nils sort to end
- **Slicing**: `head(n)`, `tail(n)`, `slice(start, end)`
- **Projection**: `select_columns(cols)`
- **Grouping**: `group_by(col)`, `unique(col)`, `count_by(col)`
- **Joining**: `join(other, this_col, other_col, join_type)` — `"inner"` or `"left"`
- **Mutation**: `merge(other)` — append rows in-place
- **Nil handling**: `drop_nil(col)`, `fill_nil(col, val)`
- **Sampling**: `sample(n, seed)` — Fisher-Yates shuffle
- **Analytics**: `sum`, `mean`, `min_val`, `max_val`, `median`, `stddev`, `variance`, `describe`

### `dataframe::serial`

CSV, JSON, and LVDF binary serialization/deserialization for DataFrame.

- **`from_csv(s)`** (fn) — Parse RFC 4180 CSV with auto type-detection (f64 then bool then Text).
- **`from_json(s)`** (fn) — Parse JSON array-of-objects into a DataFrame.
- **`from_binary(data)`** (fn) — Deserialize from LVDF binary format (magic `"LVDF"`, version 1).
- **`DataFrame::to_csv()`** — Serialize to CSV string.
- **`DataFrame::to_json()`** — Serialize to JSON array-of-objects string.
- **`DataFrame::to_binary()`** — Serialize to LVDF binary format.
- **`DataFrame::to_string_table()`** — Format as ASCII table for debug display.
- **`Database::to_json()`** — Serialize all tables to a JSON object string.

### `dataframe::sql`

SQL-like query parser and executor for DataFrame.

- **`query_sql(df, sql)`** (fn) — Execute a SQL query on a single DataFrame.
- **`query_sql_database(db, sql)`** (fn) — Execute a SQL query on a Database (supports `FROM` and `JOIN`).
- Supports: `SELECT` (columns, `*`, aggregates), `WHERE` (`AND`/`OR`/`NOT`/`LIKE`/`IN`/comparisons), `GROUP BY`, `HAVING`, `ORDER BY` (`ASC`/`DESC`), `LIMIT`, `OFFSET`, `JOIN ... ON`.
- Aggregate functions: `COUNT(*)`, `COUNT(col)`, `SUM(col)`, `AVG(col)`, `MIN(col)`, `MAX(col)`.
- LIKE pattern matching uses dynamic programming (`%` = any sequence, `_` = any single char).

## Key Types

### Structs

#### `dataframe::frame::DataFrame`

In-memory column-major tabular data. Stores named columns of `CellValue` cells with `data[col_index][row_index]` layout. Provides column/row CRUD, query methods (filter, sort, join, group_by), analytics (sum, mean, median, stddev, variance, describe), serialization (CSV, JSON, LVDF binary, ASCII table), SQL query execution, and deterministic random data generation.

Public methods (46): `new`, `nrows`, `ncols`, `columns`, `count`, `resolve_col`, `add_column`, `remove_column`, `rename_column`, `get_column`, `add_row`, `remove_row`, `get_row`, `get_value`, `set_value`, `clone_df`, `column_data_mut`, `from_raw`, `raw_data`, `random`, `filter`, `sort`, `head`, `tail`, `slice`, `select_columns`, `unique`, `group_by`, `join`, `merge`, `count_by`, `drop_nil`, `sample`, `sum`, `mean`, `min_val`, `max_val`, `median`, `stddev`, `variance`, `describe`, `fill_nil`, `to_csv`, `to_json`, `to_binary`, `to_string_table`.

#### `dataframe::frame::Database`

Named catalog of DataFrames backed by `HashMap<String, DataFrame>`. Supports add/remove/get/list/merge/clear operations and cross-table SQL queries via `query_sql_database`.

Public methods (12): `new`, `add_table`, `get_table`, `get_table_mut`, `remove_table`, `has_table`, `list_tables`, `table_count`, `clear`, `merge`, `clone_db`, `to_json`.

### Enums

#### `dataframe::frame::CellValue`

A single cell value in a DataFrame column.

- `Nil` — Missing or null value.
- `Number(f64)` — 64-bit floating-point number.
- `Text(String)` — UTF-8 string.
- `Bool(bool)` — Boolean value.

Public methods (5): `is_nil`, `as_number`, `as_text`, `as_bool`, `cmp_for_sort`.

#### `dataframe::frame::ColRef`

Column reference: string name or 1-based integer index.

- `Name(String)` — Reference by column name.
- `Index(usize)` — Reference by 1-based column index (converted to 0-based by `resolve_col`).

## Lua API

Exposed under `lurek.dataframe.*` by `src/lua_api/dataframe_api.rs`. Two UserData types are registered: `LuaDataFrame` (wrapping `Rc<RefCell<DataFrame>>`) and `LuaDatabase` (wrapping `Rc<RefCell<Database>>`). Row indices in the Lua API are **1-based**.

### Module Functions (`lurek.dataframe.*`)

| Function | Signature | Description |
|----------|-----------|-------------|
| `newDataFrame` | `() -> DataFrame` | Creates a new empty DataFrame |
| `newDatabase` | `() -> Database` | Creates a new empty Database |
| `fromTable` | `(rows: table) -> DataFrame` | Creates a DataFrame from an array of row tables |
| `fromCSV` | `(s: string) -> DataFrame` | Parses a CSV string into a DataFrame |
| `fromJSON` | `(s: string) -> DataFrame` | Parses a JSON string into a DataFrame |
| `fromBinary` | `(s: string) -> DataFrame` | Deserializes an LVDF binary string into a DataFrame |
| `random` | `(defs: table, n: integer, seed?: integer) -> DataFrame` | Generates random data from column type-hint definitions |

### DataFrame Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `nrows` | `() -> integer` | Returns row count |
| `ncols` | `() -> integer` | Returns column count |
| `columns` | `() -> table` | Returns column names |
| `count` | `() -> integer` | Alias for `nrows` |
| `addColumn` | `(name: string, default?: value) -> nil` | Adds a column with optional default |
| `removeColumn` | `(col: string\|integer) -> nil` | Removes a column |
| `rename` | `(col: string\|integer, new_name: string) -> nil` | Renames a column |
| `getColumn` | `(col: string\|integer) -> table` | Returns all values in a column |
| `addRow` | `(row?: table) -> integer` | Adds a row, returns 1-based index |
| `removeRow` | `(row: integer) -> nil` | Removes a row (1-based) |
| `getRow` | `(row: integer) -> table` | Returns a row as name-value pairs (1-based) |
| `getValue` | `(row: integer, col: string\|integer) -> value` | Gets a single cell (1-based row) |
| `setValue` | `(row: integer, col: string\|integer, val: value) -> nil` | Sets a single cell (1-based row) |
| `filter` | `(col, op: string, val) -> DataFrame` | Filters rows by condition |
| `sort` | `(col, ascending?: boolean) -> DataFrame` | Sorts by column (default ascending) |
| `head` | `(n?: integer) -> DataFrame` | First n rows (default 5) |
| `tail` | `(n?: integer) -> DataFrame` | Last n rows (default 5) |
| `slice` | `(start: integer, end: integer) -> DataFrame` | Row range (1-based, inclusive) |
| `select` | `(cols...) -> DataFrame` | Column projection |
| `unique` | `(col) -> table` | Unique values in a column |
| `groupBy` | `(col) -> table` | Groups by column, returns table of DataFrames |
| `join` | `(other, this_col, other_col, type?: string) -> DataFrame` | Join (inner/left) |
| `merge` | `(other: DataFrame) -> nil` | Append rows in-place |
| `countBy` | `(col) -> DataFrame` | Count distinct values |
| `dropNil` | `(col) -> DataFrame` | Remove rows where column is nil |
| `sample` | `(n: integer, seed?: integer) -> DataFrame` | Random sample |
| `describe` | `() -> DataFrame` | Descriptive statistics for numeric columns |
| `sum` | `(col) -> number` | Sum of numeric values |
| `mean` | `(col) -> number` | Mean of numeric values |
| `min` | `(col) -> number` | Minimum numeric value |
| `max` | `(col) -> number` | Maximum numeric value |
| `median` | `(col) -> number` | Median of numeric values |
| `stddev` | `(col) -> number` | Population standard deviation |
| `variance` | `(col) -> number` | Population variance |
| `fillNil` | `(col, val) -> nil` | Replace nil values in-place |
| `apply` | `(col, func: function) -> nil` | Apply function to each cell in a column |
| `toCSV` | `() -> string` | Serialize to CSV |
| `toJSON` | `() -> string` | Serialize to JSON |
| `toBinary` | `() -> string` | Serialize to LVDF binary |
| `toTable` | `() -> table` | Convert to Lua table of row tables |
| `toString` | `() -> string` | ASCII table representation |
| `query` | `(sql: string) -> DataFrame` | Execute SQL query |
| `clone` | `() -> DataFrame` | Deep copy |

### Database Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `addTable` | `(name: string, df: DataFrame) -> nil` | Add or replace a table |
| `getTable` | `(name: string) -> DataFrame?` | Get a table by name (copy) |
| `removeTable` | `(name: string) -> nil` | Remove a table |
| `hasTable` | `(name: string) -> boolean` | Check if table exists |
| `listTables` | `() -> table` | List all table names |
| `tableCount` | `() -> integer` | Number of tables |
| `clear` | `() -> nil` | Remove all tables |
| `merge` | `(other: Database) -> nil` | Merge tables from another Database |
| `toJSON` | `() -> string` | Serialize all tables to JSON |
| `query` | `(sql: string) -> DataFrame` | Execute SQL with FROM/JOIN |

## Lua Examples

```lua
function lurek.init()
    -- Create from inline data
    local df = lurek.dataframe.fromTable({
        { name = "Alice", score = 95, active = true },
        { name = "Bob",   score = 82, active = false },
        { name = "Carol", score = 91, active = true },
        { name = "Dave",  score = 78, active = true },
    })

    -- Query pipeline: filter, sort, analytics
    local active = df:filter("active", "==", true)
    local sorted = active:sort("score", false) -- descending
    local top2   = sorted:head(2)

    print("Top 2 active scores:")
    print(top2:toString())
    print("Mean score:", active:mean("score"))

    -- SQL query
    local high = df:query("SELECT name, score FROM data WHERE score > 85 ORDER BY score DESC")
    print(high:toString())

    -- CSV round-trip
    local csv = df:toCSV()
    local reloaded = lurek.dataframe.fromCSV(csv)

    -- Random data generation
    local rng_df = lurek.dataframe.random({
        { "id",    "id" },
        { "name",  "name" },
        { "email", "email" },
        { "score", "float" },
    }, 100, 42)

    -- Database with SQL JOIN
    local db = lurek.dataframe.newDatabase()
    db:addTable("users", lurek.dataframe.fromTable({
        { id = 1, name = "Alice" },
        { id = 2, name = "Bob" },
    }))
    db:addTable("scores", lurek.dataframe.fromTable({
        { user_id = 1, points = 95 },
        { user_id = 2, points = 82 },
    }))
    local joined = db:query("SELECT name, points FROM users JOIN scores ON id = user_id")
    print(joined:toString())
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 2     |
| `enum`     | 2     |
| `fn`       | 68    |
| **Total**  | **72** |

## References

| Module      | Relationship | Notes                                                                 |
|-------------|-------------|-----------------------------------------------------------------------|
| `engine`    | Imports from | Uses `log_messages` for structured logging constants                   |
| `math`      | Imports from | Leaf dependency (no direct type usage, but available per tier rules)   |
| `compute`   | Related      | `compute` stores flat `NdArray` for per-frame math; `dataframe` stores named column tables for structured data |
| `data`      | Related      | `data` handles raw binary buffers (ByteData); `dataframe` handles typed tabular data |
| `lua_api`   | Imported by  | `src/lua_api/dataframe_api.rs` registers `lurek.dataframe.*` with `LuaDataFrame` and `LuaDatabase` UserData |

## Notes

- **Column-major storage**: Data is `data[col_index][row_index]`, not row-major. Column scans for aggregation and filtering are cache-friendly; row iteration requires cross-column access.
- **Lua indexing**: All Lua-facing row indices are **1-based**. The `dataframe_api.rs` binding layer converts to 0-based via `validate_row()`. Column references accept either string names or 1-based integer indices via `ColRef`.
- **Immutable query results**: `filter`, `sort`, `join`, `head`, `tail`, `slice`, `select`, `groupBy`, `dropNil`, `sample`, `countBy`, `clone` all return **new** DataFrame instances. Only `addRow`, `removeRow`, `setValue`, `addColumn`, `removeColumn`, `rename`, `merge`, `fillNil`, and `apply` mutate in-place.
- **SQL subset**: The SQL engine is hand-rolled (no external parser crate). It supports a useful subset but not full SQL — no subqueries, no `CREATE`/`INSERT`/`UPDATE`/`DELETE`, no `UNION`, no window functions. `"right"` joins log a warning and return empty.
- **LVDF binary format**: Magic bytes `"LVDF"`, version 1. Tags: 0=Nil, 1=Number (8 bytes f64 LE), 2=Text (u32 LE length + UTF-8 bytes), 3=Bool (1 byte). Guards against unreasonable sizes (>10K cols or >10M rows).
- **Random data generation**: Uses an internal xorshift64 PRNG (not `fastrand`). Deterministic when a seed is provided. Type hints: `"int"`, `"float"`, `"bool"`, `"name"`, `"id"`, `"string"`, `"email"`, `"date"`, `"phone"`, `"uuid"`, `"sentence"`.
- **No external dependencies**: All CSV/JSON/SQL parsing is hand-rolled — no `csv`, `serde_json`, or `sqlparser` crate dependencies.
- **Thread safety**: `LuaDataFrame` and `LuaDatabase` use `Rc<RefCell<_>>` — not thread-safe. Each Lua VM gets its own instances.
- **Performance**: `unique` and `group_by` use O(n^2) dedup (linear scan for membership). Adequate for game-scale data (thousands of rows); not suitable for millions of rows.
- **Breaking change surface**: Renaming any `lurek.dataframe.*` function or changing `CellValue` variants will break Lua game scripts. The `toTable`/`fromTable` round-trip is the most commonly used pattern.
