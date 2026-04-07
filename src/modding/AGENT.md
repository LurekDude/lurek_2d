# `modding` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.modding`                                       |
| **Source**     | `src/modding/`                                       |
| **Rust Tests** | `tests/rust/unit/modding_tests.rs`                   |
| **Lua Tests**  | `tests/lua/unit/test_modding.lua`                    |
| **Architecture** | —                                                  |

## Purpose

The modding module provides infrastructure for player-created mods — the
ability for end users to add, replace, or extend game content without modifying
the original game files. It is a Tier 2 engine extension that depends only on
Baseline (`engine`, `math`) and uses the `toml` crate for manifest parsing and
`std::fs` for directory scanning. No Tier 1 runtime modules are imported.

## Source Files

| File              | Purpose                                                       |
|-------------------|---------------------------------------------------------------|
| `mod.rs`          | Module root — re-exports `mod_manager` submodule              |
| `mod_manager.rs`  | `ModInfo` struct and `ModManager` registry with all operations |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/modding.md`](../../specs/modding.md)

_Update both this file **and** `specs/modding.md` whenever source files, public types, or Lua bindings change._
