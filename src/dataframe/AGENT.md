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

## Purpose

The `dataframe` module provides an in-memory, column-major tabular data engine with named columns, a functional query API, serialization to multiple formats, and a hand-rolled SQL subset parser and executor. It is a Tier 2 engine extension that depends only on `math` and `engine` from the baseline layer.

## Source Files

| File        | Purpose                                                        |
|-------------|----------------------------------------------------------------|
| `mod.rs`    | Module root; re-exports `CellValue`, `ColRef`, `DataFrame`, `Database` and declares submodules |
| `frame.rs`  | Core `DataFrame` and `Database` types, `CellValue` enum, column/row CRUD, random data generation |
| `query.rs`  | Functional query methods: `filter`, `sort`, `head`, `tail`, `slice`, `select_columns`, `unique`, `group_by`, `join`, `merge`, `count_by`, `drop_nil`, `sample`, plus numeric analytics (`sum`, `mean`, `min_val`, `max_val`, `median`, `stddev`, `variance`, `describe`, `fill_nil`) |
| `serial.rs` | Serialization: `from_csv`/`to_csv` (RFC 4180), `from_json`/`to_json`, `from_binary`/`to_binary` (LVDF v1), `to_string_table` (ASCII debug), `Database::to_json` |
| `sql.rs`    | SQL tokenizer, recursive-descent parser, and executor for `query_sql` (single DataFrame) and `query_sql_database` (multi-table Database with JOIN) |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/dataframe.md`](../../docs/specs/dataframe.md)

_Update both this file **and** `docs/specs/dataframe.md` whenever source files, public types, or Lua bindings change._
