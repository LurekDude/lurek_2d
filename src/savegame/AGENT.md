# `savegame` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extensions                           |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.savegame`                                      |
| **Source**     | `src/savegame/`                                      |
| **Rust Tests** | `tests/rust/unit/savegame_tests.rs`                  |
| **Lua Tests**  | `tests/lua/unit/test_savegame.lua`                   |

## Purpose

The savegame module provides a pure-data save manager for slot-based game save/load
with schema versioning, dirty-state tracking, auto-save timers, and Lua-literal
serialisation.  `SaveManager` is the central struct that tracks named collector
modules, migration version chains, and an auto-save timer that only fires when
the in-memory state is dirty.  The serialisation subsystem converts a `HashMap<String,
SaveValue>` tree into a `return { key = value, ... }` Lua-literal string that
`loadfile()` can deserialise without any custom parser — no JSON, no MessagePack,
just valid Lua source.

## Source Files

| File           | Purpose                                                                                 |
|----------------|-----------------------------------------------------------------------------------------|
| `mod.rs`       | Module root: `SlotMeta`, `SaveManager`, `SaveValue` enum, `serialize_table`/`serialize_value` functions, private Lua-string helpers, inline unit tests |
| `save_data.rs` | Alternate copy of save data types (orphaned — not declared via `mod save_data;` in `mod.rs`) |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/savegame.md`](../../specs/savegame.md)

_Update both this file **and** `specs/savegame.md` whenever source files, public types, or Lua bindings change._
