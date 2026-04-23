---
name: library-authoring
description: "Load this skill when authoring or modifying a Lunasome library under library/: creating a new library, refactoring an existing one, fixing helper drift, regenerating the library docs, or registering a new test in tests/lua/harness.rs. Owns library folder layout, LDoc tag conventions, the runtime-namespace name table, and the gen_lib_docs.py workflow. Skip it for engine Rust code, content/examples/ single-file scripts (use examples-management), or content/games/ games (use demo-creation)."
---
# library-authoring

## Mission

Load this skill when authoring or modifying a Lunasome library under library/: creating a new library, refactoring an existing one, fixing helper drift, regenerating the library docs, or registering a new test in tests/lua/harness.rs. Owns library folder layout, LDoc tag conventions, the runtime-namespace name table, and the gen_lib_docs.py workflow. Skip it for engine Rust code, content/examples/ single-file scripts (use examples-management), or content/games/ games (use demo-creation).

## When To Load

- Creating a new library folder under `library/<name>/`
- Refactoring an existing library: helper deduplication, runtime-namespace fixes, docstring cleanup
- Adding or renaming a public function in a library `init.lua`
- Wiring a new library's test file into `tests/lua/harness.rs`
- Regenerating `docs/api/library.md` or `docs/reports/libs/<name>.md`
- Renaming/deprecating a library (e.g. `library.patterns` → `library.scheduler`)

## When To Skip

- Engine Rust code → use `rust-coding`
- `content/examples/` single-file API scripts → use `examples-management`
- `content/games/` playable games → use `demo-creation`
- Designing new `lurek.*` engine APIs → use `lua-api-design`

## Domain Knowledge

### Domain Knowledge
### Owns

- `library/<name>/` folder layout and the cross-artifact sync rule for libraries
- LDoc tag set used by `tools/docs/gen_lib_docs.py`
- Runtime-namespace name table (the `lurek.*` names libraries must call)
- Forbidden API list for library code
- Lua portability rules for libraries (LuaJIT + 5.4 fallback)
- `python tools/docs/gen_lib_docs.py [--check]` workflow

### Folder Layout (mandatory per library)

| File | Purpose |
|---|---|
| `library/<name>/init.lua` | Public API; returned by `require("library.<name>")` |
| `library/<name>/AGENT.md` | Module reference (purpose, deps, public surface) |
| `library/<name>/example.lua` | Self-contained runnable showcase |
| `tests/lua/library/test_library_<name>.lua` | BDD test, ends with `test_summary()` |
| `tests/lua/harness.rs` | `#[test] fn lua_test_library_<name>()` entry — manual, not auto-discovered |
| `docs/reports/libs/<name>.md` | Per-library API page (regen) |
| `docs/api/library.md` | Aggregate library reference (regen) |

Renames or deletions must update **all** of the above in the same commit. Deprecated libraries keep the old `init.lua` as a thin stub that `require`s the new name and logs a one-time deprecation warning.

### Runtime Namespace Names (CRITICAL)

`docs/api/lurek.md` and several spec files use historical names. The **runtime registers different names** — libraries must call the runtime names or they crash with `attempt to index nil`.

| Stale doc name | Runtime name | Notes |
|---|---|---|
| `lurek.image` | `lurek.image` | image loading + atlases |
| `lurek.serial` | `lurek.serial` | JSON / TOML / binary |
| `lurek.save` | `lurek.save` | SaveManager, collectors |
| `lurek.timer` | `lurek.timer` | `Scheduler:after` / `:every` |
| `lurek.ecs` | `lurek.ecs` | entity / component store |
| `lurek.mods` | `lurek.mods` | mod loader |
| `lurek.filesystem` | `lurek.filesystem` | sandboxed file IO |
| `lurek.pathfind` | `lurek.pathfind` | A* / Dijkstra |
| `lurek.effect` | `lurek.effect` | post-process passes |
| `lurek.particle` | `lurek.particle` | particle systems |
| `lurek.render` | `lurek.render` | low-level draw queue |
| `lurek.i18n` | `lurek.i18n` | translations |
| `lurek.runtime` | `lurek.runtime` | OS / window info |

Always grep the actual `src/lua_api/mod.rs` registration before introducing a new dependency.

### Forbidden API Calls From Library Code

Library code is the **headless** layer of the stack. It must not require a window, GPU, or audio device just to `require("library.<name>")`. The following APIs are forbidden inside `init.lua` (they may appear only in `@see` cross-references and in `example.lua`):

- `lurek.render.*` and any draw-call API
- `lurek.audio.play*` / device opening
- `lurek.window.*` (size, title, cursor)
- `lurek.input.*` polling at module load time
- `lurek.effect.*` shader passes

If a library needs to advertise rendering hooks, expose data (positions, sprite ids, colours) and document the consumer with `-- @see lurek.render.draw`.

### LDoc Tag Set (gen_lib_docs.py)

Every public function and table field uses LDoc tags. The generator parses:

| Tag | Use |
|---|---|
| `@module library.<name>` | Once at top of `init.lua` |
| `@status full\|partial\|stub\|proxy` | One per `@module` and per public fn |
| `@local` | Mark non-public helpers (suppressed in docs) |

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- [.github/copilot-instructions.md](../../copilot-instructions.md) — system prompt, library list, Cross-Artifact Sync
- [.github/skills/examples-management/SKILL.md](../examples-management/SKILL.md) — sibling skill for `content/examples/` and `content/games/`
- [.github/skills/lua-scripting/SKILL.md](../lua-scripting/SKILL.md) — `lurek.*` API usage idioms
- [.github/skills/documentation/SKILL.md](../documentation/SKILL.md) — generated-doc rules
- [tools/docs/gen_lib_docs.py](../../../tools/docs/gen_lib_docs.py) — library doc generator
- [tools/mods/mod_init.py](../../../tools/mods/mod_init.py) — scaffold a new `lurek-mod` plugin layout.
- [library/README.md](../../../library/README.md) — library index

## CAG Metadata

- **Related skills**: examples-management, lua-scripting, documentation, lua-api-design
