---
name: save-data
description: "Load this skill when implementing save/load logic, table serialization, autosave, or save versioning in Luna2D Lua scripts. Skip it for read-only asset loading, filesystem sandboxing internals, or audio/physics code."
---

# Save Data — Luna2D Engine

## Load When

- Writing persistent game state (scores, progress, settings) to disk
- Implementing autosave or checkpoint systems in Lua scripts
- Adding save versioning or migration logic
- Debugging corrupt or missing save files

## Owns

- `luna.filesystem.write` / `luna.filesystem.read` usage patterns for saves
- Lua table serialization (recursive Lua-source strategy)
- Save file location convention (`save/` subdirectory)
- Atomic write pattern to prevent corruption on crash
- Dirty-flag + interval autosave pattern
- Save versioning with a mandatory `version` field

## Does Not Cover

- Network, cloud, or encrypted saves — not supported by the engine
- `GameFS` sandbox implementation → use `lua-sandbox-design` skill
- General filesystem API naming → use `lua-api-design` skill

## Live Repository Contracts

- `src/filesystem/vfs.rs` — `GameFS::write_string`: **only allows paths under `save/`**; paths outside return an access-denied error
- `src/lua_api/filesystem_api.rs` — `luna.filesystem.read(path)`, `luna.filesystem.write(path, data)`, `luna.filesystem.exists(path)`; paths are relative to `game_dir`

## Decision Rules

### Save location — always `save/`
All save paths must begin with `save/` (e.g. `save/slot1.lua`). `GameFS` enforces this at the Rust level; any other path returns an error.

### Serialization — recursive Lua-source pattern
No JSON or msgpack is available. Serialize tables as Lua source and reload with `load()`:

> See [example_1.lua](example_1.lua) for the serialization — recursive lua-source pattern code example.

### Atomic writes — temp-then-rename
Write to `save/slot1.tmp` first, then overwrite `save/slot1.lua`. `GameFS` allows any path under `save/`, so both steps are permitted:

> See [example_2.lua](example_2.lua) for the atomic writes — temp-then-rename code example.

*(True atomic rename requires Rust-side `fs::rename`; until that binding exists, the two-write pattern reduces the corruption window.)*

### Autosave — dirty flag + timer, never in `luna.draw()`
> See [example_3.lua](example_3.lua) for the autosave — dirty flag + timer, never in `luna.draw()` code example.
Never call `save()` inside `luna.draw()` — I/O blocks the render thread.

### Save versioning — `version` field is mandatory
Every save table must include `version = <number>`. On load, check the field and migrate:

> See [example_4.lua](example_4.lua) for the save versioning — `version` field is mandatory code example.

### Anti-patterns

- **Save on every frame** — use dirty flag + interval instead
- **Save outside `save/`** — the sandbox blocks it; don't try `../` paths
- **No version field** — makes future migration impossible; always include it
- **Saving in `luna.draw()`** — use `luna.update()` only
