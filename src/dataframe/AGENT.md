# `dataframe` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Engine Extensions |
| **Lua API** | `luna.dataframe` |
| **Source** | `src/dataframe/` |
| **Tests** | `tests/dataframe_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_dataframe.lua` |

## Summary

The dataframe module provides an in-memory typed tabular data structure with
named columns, designed for bulk data operations that would be tedious or slow
to implement in pure Lua loops.  Games use it for a wide range of structured
data tasks: importing level databases from CSV (object placements, enemy spawn
tables, dialogue lines), building and sorting high-score leaderboards,
aggregating telemetry event logs, and running GROUP-BY-style aggregations over
lists of game objects — all without writing manual iteration code.

Each `DataFrame` column is typed (string, integer, float, or boolean) and
operations such as `filter`, `sort`, `join`, `group_by`, and aggregate
functions (`sum`, `mean`, `count`, `min`, `max`) produce new DataFrames
without mutating the original, composing into readable pipelines from Lua.
CSV import and export with configurable delimiters and optional header rows
allow straightforward data interchange with spreadsheets and external
tooling.

## Architecture

```
DataFrame (column-oriented table)
  │
  ├── CellValue ── Nil | Number(f64) | Text(String) | Bool(bool)
  │
  ├── frame.rs ── DataFrame + Database (named table registry)
  │     ├── Column operations ── add/remove/rename columns
  │     ├── Row operations ── add/get/set/remove rows
  │     └── Random data generation with type hints
  │
  ├── query.rs ── functional query API
  │     ├── Filter / Sort / Slice / Select
  │     ├── Group By / Unique / Join (inner + left)
  │     ├── Aggregation ── count_by, merge
  │     └── Statistics ── sum/mean/min/max/median/variance/stddev/describe
  │
  ├── serial.rs ── serialization formats
  │     ├── CSV ── RFC 4180 compliant, auto-detect types
  │     ├── JSON ── array-of-objects format
  │     ├── LVDF ── Luna binary format (magic "LVDF" v1)
  │     └── ASCII table ── pretty-printed text table
  │
  └── sql.rs ── SQL query engine
        ├── Tokenizer ── hand-rolled lexer
        ├── Parser ── recursive-descent
        ├── SELECT / FROM / WHERE / GROUP BY / HAVING
        ├── ORDER BY / LIMIT / OFFSET / JOIN
        ├── Aggregates ── COUNT / SUM / AVG / MIN / MAX
        ├── LIKE ── dynamic programming pattern matching
        └── Logical ── AND / OR / NOT / IN
```

## Source Files

| File | Purpose |
|------|---------|
| `frame.rs` | Core DataFrame and Database types with CellValue cells |
| `query.rs` | DataFrame query, filter, sort, join, analytics, and mutation |
| `serial.rs` | CSV, JSON, and LVDF binary serialization for DataFrame |
| `sql.rs` | SQL-like query parser and executor for DataFrame |

## Submodules

### `dataframe::frame`

Core DataFrame and Database types with CellValue cells.

- **`CellValue`** (enum): A single cell value in a DataFrame column.
- **`ColRef`** (enum): Column reference: string name or 1-based integer index.
- **`DataFrame`** (struct): In-memory column-major tabular data. Consult the module-level documentation for the broader usage context and...
- **`Database`** (struct): Named catalog of DataFrames. Consult the module-level documentation for the broader usage context and preconditions.

### `dataframe::query`

DataFrame query, filter, sort, join, analytics, and mutation.

### `dataframe::serial`

CSV, JSON, and LVDF binary serialization for DataFrame.

- **`from_csv`** (fn): Parse a CSV string into a DataFrame. Returns a fully initialised instance with all fields set to their initial values.
- **`from_json`** (fn): Parse JSON (array-of-objects) into a DataFrame.
- **`from_binary`** (fn): Deserialize a DataFrame from LVDF binary format.

### `dataframe::sql`

SQL-like query parser and executor for DataFrame.

- **`query_sql`** (fn): Execute a SQL query on a single DataFrame.
- **`query_sql_database`** (fn): Execute a SQL query on a Database (supports FROM and JOIN).

## Key Types

### Structs

#### `dataframe::frame::DataFrame`

In-memory column-major tabular data. Consult the module-level documentation for the broader usage context and...

#### `dataframe::frame::Database`

Named catalog of DataFrames. Consult the module-level documentation for the broader usage context and preconditions.

### Enums

#### `dataframe::frame::CellValue`

A single cell value in a DataFrame column.

#### `dataframe::frame::ColRef`

Column reference: string name or 1-based integer index.

## Public Functions

- **`from_binary()`** `serial::` — Deserialize a DataFrame from LVDF binary format.
- **`from_csv()`** `serial::` — Parse a CSV string into a DataFrame. Returns a fully initialised instance with all fields set to their initial values.
- **`from_json()`** `serial::` — Parse JSON (array-of-objects) into a DataFrame.
- **`query_sql()`** `sql::` — Execute a SQL query on a single DataFrame.
- **`query_sql_database()`** `sql::` — Execute a SQL query on a Database (supports FROM and JOIN).

## Lua API

Exposed under `luna.dataframe.*` by `src/lua_api/dataframe_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 2 |
| `fn` | 5 |
| `mod` | 4 |
| `struct` | 2 |
| **Total** | **13** |

