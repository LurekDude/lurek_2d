# `src/dataframe/` — Tabular Data and SQL Queries

## Purpose

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

### How It Works

`DataFrame` stores column data as a `Vec<DataColumn>` where each `DataColumn`
wraps a typed `Vec<Value>`.  Row operations scatter access across columns
(cache-unfriendly for row-major patterns) but column-wise aggregations —
the most common game-data query — are fast and contiguous.  This columnar
layout was chosen because game scripts typically query one column at a time
("sort by score", "sum all damage values") rather than reading whole rows.

Filtering builds an index vector — a `Vec<usize>` of row indices that pass the
predicate — before constructing the output DataFrame.  No row data is copied
for rows that are filtered out; only the passing indices' data is extracted.
This two-phase approach makes chained filters efficient even on large tables.

`join` uses hash-join semantics: the right-hand DataFrame is indexed by the
join key into a `HashMap<Value, Vec<usize>>`, then the left-hand DataFrame is
scanned once.  For the typical game use case (joining enemy stats onto a list
of spawned enemies by type ID) this is fast enough to run per scene load
without a noticeable pause.

### Dependency Direction

```
dataframe/ ──────► (none)
```

**Leaf module** — zero Luna2D dependencies. Pure data structure implementation.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `DataFrame`, `CellValue`, `ColRef`, `Database`.

**~8 lines** — pure re-exports.

---

### `frame.rs` — `DataFrame` (Core Table)

**~622 lines** | Column-oriented tabular data with typed cells.

#### Struct: `DataFrame`

```rust
pub struct DataFrame {
    column_names: Vec<String>,
    data: Vec<Vec<CellValue>>,   // data[row][col]
}
```

#### Enum: `CellValue`

`Nil | Number(f64) | Text(String) | Bool(bool)`

#### Enum: `ColRef`

`Name(String) | Index(usize)` — column reference by name or position.

#### Struct: `Database`

```rust
pub struct Database {
    tables: HashMap<String, DataFrame>,
}
```

Methods: `new`, `from_rows`, `add_column`, `remove_column`, `rename_column`,
`add_row`, `get_row`, `set_cell`, `get_cell`, `row_count`, `column_count`,
`column_names`, `random(rows, cols, hints)`.

**Design**: Row-major storage (data[row][col]) despite column-oriented API naming.
`random()` uses data hints to generate realistic test data.

---

### `query.rs` — Functional Query API

**~580 lines** | Chainable query operations on DataFrames.

| Operation | Purpose | Returns |
|-----------|---------|---------|
| `filter(df, col, op, val)` | Row filtering | New DataFrame |
| `sort(df, col, ascending)` | Sort by column | New DataFrame |
| `head(df, n)` / `tail(df, n)` | First/last N rows | New DataFrame |
| `slice(df, start, end)` | Row range | New DataFrame |
| `select_columns(df, cols)` | Column subset | New DataFrame |
| `group_by(df, col)` | Group into multiple DFs | HashMap |
| `unique(df, col)` | Deduplicate by column | New DataFrame |
| `join(df1, df2, col, type)` | Inner/left join | New DataFrame |
| `merge(df1, df2)` | Vertical concatenation | New DataFrame |
| `count_by(df, col)` | Value frequency | New DataFrame |
| `drop_nil(df, col)` | Remove nil rows | New DataFrame |
| `fill_nil(df, col, val)` | Replace nils | New DataFrame |
| `sample(df, n)` | Random sample | New DataFrame |

#### Statistics Functions

| Function | Returns |
|----------|---------|
| `sum`, `mean`, `min`, `max` | Single CellValue |
| `median`, `variance`, `stddev` | f64 |
| `describe(df, col)` | Summary DataFrame (count/mean/std/min/max) |

---

### `serial.rs` — Serialization Formats

**~656 lines** | Four I/O formats for DataFrame persistence.

| Format | Read Function | Write Function | Notes |
|--------|--------------|----------------|-------|
| CSV | `from_csv(string)` | `to_csv(df)` | RFC 4180, auto-detect Number/Bool/Nil |
| JSON | `from_json(string)` | `to_json(df)` | Array of objects format |
| LVDF | `from_lvdf(bytes)` | `to_lvdf(df)` | Binary: magic `"LVDF"` + version 1 + type tags |
| ASCII | — | `to_ascii_table(df)` | Pretty-printed table for display |

**Design**: CSV parser implements RFC 4180 with proper quoting rules and auto-detects
column types on read. LVDF is a compact binary format for fast save/load.

---

### `sql.rs` — SQL Query Engine

**~1040 lines** | Complete hand-rolled SQL engine with tokenizer, parser, and executor.

#### Architecture

```
SQL string → Tokenizer → Token stream → Parser → AST → Executor → DataFrame
```

#### Supported SQL

| Clause | Support |
|--------|---------|
| `SELECT` | Columns, `*`, aliases, aggregate functions |
| `FROM` | Table name (from Database) |
| `WHERE` | Comparison, LIKE, AND/OR/NOT, IN, IS NULL |
| `GROUP BY` | Single or multiple columns |
| `HAVING` | Post-aggregation filter |
| `ORDER BY` | ASC/DESC, multiple columns |
| `LIMIT` / `OFFSET` | Row limiting |
| `JOIN` | Inner join on equality condition |

#### Aggregate Functions

`COUNT` | `SUM` | `AVG` | `MIN` | `MAX`

**LIKE implementation**: Uses dynamic programming for pattern matching with `%` and
`_` wildcards (not regex).

**Design**: Entirely hand-rolled — no SQL parsing crate dependency. Recursive descent
parser produces an AST that's directly executed against DataFrame storage.

---

## Cross-Cutting Concerns

### Error Handling

SQL parsing errors include position information and expected vs actual token.
DataFrame operations return `Result<T, String>` for invalid column references.

### Lua Integration

The Lua bridge lives in `src/lua_api/dataframe_api.rs` (~700 lines), exposing
DataFrames as UserData under `luna.data.*` with SQL query support.

### Usage from Lua

```lua
-- Create a DataFrame
local df = luna.data.newDataFrame({"name", "age", "score"})
df:addRow({"Alice", 30, 95.5})
df:addRow({"Bob", 25, 87.0})

-- Query with SQL
local db = luna.data.newDatabase()
db:addTable("users", df)
local result = db:query("SELECT name, score FROM users WHERE age > 26 ORDER BY score DESC")

-- Functional operations
local filtered = luna.data.filter(df, "age", ">", 26)
local sorted = luna.data.sort(df, "score", false)

-- Statistics
local avg = luna.data.mean(df, "score")

-- Export
local csv_string = df:toCSV()
```
