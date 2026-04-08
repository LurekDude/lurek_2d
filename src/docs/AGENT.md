# `docs` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.docs`                                            |
| **Source**       | `src/docs/`                                            |
| **Rust Tests**   | `tests/rust/unit/docs_tests.rs`                        |
| **Lua Tests**    | `tests/lua/unit/test_docs.lua`                         |
| **Architecture** | —                                                      |

## Purpose

The `docs` module provides API documentation management, runtime reflection, and game-data validation:

1. **Catalog / Validation** — `DocEntry`, `Catalog`, `ValidationReport`, `QualityReport` — scan live bindings, load TOML annotations, validate coverage and quality.
2. **Schema validation** — `Schema`, `FieldRule`, `SchemaResult` — lightweight runtime data-validator for game config, save-state, and mod manifests. Defined in `src/docs/schema.rs`.
3. **Live reflection** — `luna.docs.reflectLive(ns?)` walks the live `luna.*` Lua table and returns a structured name/type description; `luna.docs.reflectTable(t, name?)` reflects any arbitrary Lua table.

## Source Files

| File           | Purpose                                                                          |
|----------------|----------------------------------------------------------------------------------|
| `entry.rs`     | `DocEntry`, `ParamInfo`, `ReturnInfo` — data types for a single API entry        |
| `catalog.rs`   | `Catalog` — in-memory registry with search, filter, and query helpers            |
| `report.rs`    | `ValidationReport`, `QualityReport`, `quality_score()`, `quality_grade()`        |
| `schema.rs`    | `Schema`, `FieldRule`, `FieldType`, `SchemaError`, `SchemaResult` — data validation |
| `export.rs`    | `export_all`, `export_completions`, `export_hover`, `export_signatures`          |
| `mod.rs`       | Re-exports all public types                                                       |

## Full Specification

See [`specs/docs.md`](../../../specs/docs.md) for full architecture, type details, Lua API, examples, and notes.
