# `docs` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `lurek.docs`                                            |
| **Source**       | `src/docs/`                                            |
| **Rust Tests**   | `tests/rust/unit/docs_tests.rs`                        |
| **Lua Tests**    | `tests/lua/unit/test_docs.lua`                         |
| **Architecture** | —                                                      |

## Purpose

The `docs` module provides API documentation management, runtime reflection, and game-data validation:

1. **Catalog / Validation** — `DocEntry`, `Catalog`, `ValidationReport`, `QualityReport` — scan live bindings, load TOML annotations, validate coverage and quality.
2. **Schema validation** — `Schema`, `FieldRule`, `SchemaResult` — lightweight runtime data-validator for game config, save-state, and mod manifests. Defined in `src/docs/schema.rs`.
3. **Live reflection** — `lurek.docs.reflectLive(ns?)` walks the live `lurek.*` Lua table and returns a structured name/type description; `lurek.docs.reflectTable(t, name?)` reflects any arbitrary Lua table.

## Source Files

| File           | Purpose                                                                          |
|----------------|----------------------------------------------------------------------------------|
| `entry.rs`     | `DocEntry`, `ParamInfo`, `ReturnInfo` — data types for a single API entry        |
| `catalog.rs`   | `Catalog` — in-memory registry with search, filter, and query helpers            |
| `report.rs`    | `ValidationReport`, `QualityReport`, `quality_score()`, `quality_grade()`        |
| `schema.rs`    | `Schema`, `FieldRule`, `FieldType`, `SchemaError`, `SchemaResult` — data validation |
| `export.rs`    | `export_all`, `export_completions`, `export_hover`, `export_signatures`          |
| `mod.rs`       | Re-exports all public types                                                       |

## Key Types

| Type | Description |
|------|-------------|
| `Catalog` | Principal type for the `docs` module. |
| `ParamInfo` | Principal type for the `docs` module. |
| `ReturnInfo` | Principal type for the `docs` module. |
| `DocEntry` | Principal type for the `docs` module. |
| `ValidationReport` | Principal type for the `docs` module. |
| `QualityReport` | Principal type for the `docs` module. |
| `FieldType` | Principal type for the `docs` module. |
| `FieldRule` | Principal type for the `docs` module. |
| `SchemaError` | Principal type for the `docs` module. |
| `SchemaResult` | Principal type for the `docs` module. |
| `Schema` | Principal type for the `docs` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.docs.missing()` | See `docs/specs/docs.md`. |
| `lurek.docs.phantom()` | See `docs/specs/docs.md`. |
| `lurek.docs.incomplete()` | See `docs/specs/docs.md`. |
| `lurek.docs.overallScore()` | See `docs/specs/docs.md`. |
| `lurek.docs.grade()` | See `docs/specs/docs.md`. |
| `lurek.docs.moduleScores()` | See `docs/specs/docs.md`. |
| `lurek.docs.scan()` | See `docs/specs/docs.md`. |
| `lurek.docs.scanModule()` | See `docs/specs/docs.md`. |
| `lurek.docs.loadToml()` | See `docs/specs/docs.md`. |
| `lurek.docs.loadAll()` | See `docs/specs/docs.md`. |
| `lurek.docs.describe()` | See `docs/specs/docs.md`. |
| `lurek.docs.setParamInfo()` | See `docs/specs/docs.md`. |
| `lurek.docs.setReturnInfo()` | See `docs/specs/docs.md`. |
| `lurek.docs.getCatalog()` | See `docs/specs/docs.md`. |
| `lurek.docs.resetCatalog()` | See `docs/specs/docs.md`. |
| `lurek.docs.validate()` | See `docs/specs/docs.md`. |
| `lurek.docs.validateModule()` | See `docs/specs/docs.md`. |
| `lurek.docs.checkStaleness()` | See `docs/specs/docs.md`. |
| `lurek.docs.stale()` | See `docs/specs/docs.md`. |
| `lurek.docs.current()` | See `docs/specs/docs.md`. |

## Full Specification

See [`docs/specs/docs.md`](../../../docs/specs/docs.md) for full architecture, type details, Lua API, examples, and notes.
