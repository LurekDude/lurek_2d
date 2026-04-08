# `docs` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.docs`                                            |
| **Source**       | `src/docs/`                                            |
| **Rust Tests**   | —                                                      |
| **Lua Tests**    | `tests/lua/unit/test_docs.lua`                         |
| **Architecture** | —                                                      |

## Purpose

The `docs` module provides a structured API documentation catalog for the `luna.*` Lua API surface. It defines `DocEntry`, `ParamInfo`, and `ReturnInfo` data types to describe individual API entries, an in-memory `Catalog` for aggregating and querying those entries, and a `ValidationReport` / `QualityReport` pipeline for measuring documentation coverage and completeness. The Lua API at `luna.docs.*` can scan live bindings at runtime, load entries from TOML files, validate catalog coverage against the live API surface, compute per-module quality scores, and export VS Code IntelliSense JSON. This module is consumed by the VS Code extension and the MCP server for IntelliSense completions and hover documentation.

## Source Files

| File           | Purpose                                                                          |
|----------------|----------------------------------------------------------------------------------|
| `entry.rs`     | `DocEntry`, `ParamInfo`, `ReturnInfo` — data types for a single API entry        |
| `catalog.rs`   | `Catalog` — in-memory registry with search, filter, and query helpers            |
| `report.rs`    | `ValidationReport`, `QualityReport`, `quality_score()`, `quality_grade()`        |
| `mod.rs`       | Re-exports all public types                                                       |

## Full Specification

See [`specs/docs.md`](../../../specs/docs.md) for full architecture, type details, Lua API, examples, and notes.
