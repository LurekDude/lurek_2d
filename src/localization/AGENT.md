# `localization` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `lurek.localization`                                    |
| **Source**       | `src/localization/`                                    |
| **Rust Tests**   | `tests/rust/unit/localization_tests.rs`                |
| **Lua Tests**    | `tests/lua/unit/test_localization.lua`                 |
| **Architecture** | —                                                      |

## Purpose

The `localization` module provides the internationalization (i18n) backend for Lurek2D. It manages a multi-locale string catalog with dot-path key access, a fallback chain so missing keys automatically resolve to a parent locale, `{variable}` placeholder interpolation, and CLDR-inspired plural form selection. The module is **pure Rust** with no mlua dependency; all Lua plumbing lives in `src/lua_api/localization_api.rs`. It is gated by `modules.localization = true` in `conf.lua`. It does **not** handle date/time formatting, bi-directional text, or number formatting — only string lookup and substitution.

## Source Files

| File               | Purpose                                                                              |
|--------------------|--------------------------------------------------------------------------------------|
| `catalog.rs`       | `Catalog`, `CatalogError` — locale string tables with dot-path keys and fallback chains |
| `interpolation.rs` | `interpolate`, `interpolate_pairs` — `{name}` placeholder substitution              |
| `plural.rs`        | `PluralForm`, `pluralize`, `pluralize_slavic` — CLDR plural category selection      |
| `mod.rs`           | Re-exports all public types                                                          |

## Full Specification

See [`docs/specs/localization.md`](../../../docs/specs/localization.md) for full architecture, type details, Lua API, examples, and notes.
