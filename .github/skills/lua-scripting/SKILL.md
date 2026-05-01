---
name: lua-scripting
description: "Load this skill when writing or reviewing Lua game scripts and lurek.* usage. Skip it for engine Rust or API design."
---
# lua-scripting

## Mission
- Own Lua game-script structure, lurek.* usage, and script-level clarity.

## When To Load
- Write a Lua game script.
- Review lurek.* usage in content or tests.
- Build a script example or demo.
- Check Lua-side structure and callback flow.

## When To Skip
- Engine Rust code.
- Public API design.

## Domain Knowledge
- Use `lurek.*` only — no bare globals, no engine-prefixed names, no alternative top-level tables. All public engine API is under `lurek.*`. A script that calls `engine.draw()` or uses a bare `draw()` is broken, not just style-inconsistent.
- State lifecycle rule: `lurek.game.on_init` sets up state, `lurek.game.on_process(dt)` mutates state, `lurek.game.on_render` draws from state. Do not mutate game state inside `on_render`; do not call draw functions inside `on_process`. Mixing these callbacks causes undefined behavior.
- Multiply all movement, physics, tween, and timer increments by `dt` (the delta-time argument in `on_process`). Hardcoded per-frame increments break at non-60-FPS rates and in headless tests.
- Local variable scope: keep state in `local` variables or explicit state tables, never in module-level upvalues that persist across scene transitions. Stale upvalues from a previous scene are a common source of hard-to-trace bugs.
- Asset paths must be relative to the game's content root (the folder containing `conf.lua`). Use forward slashes. Never hardcode absolute paths or `..` traversal — GameFS will reject them.
- Content structure: `content/examples/<module>/` holds single-concept demos for one API; `content/games/<name>/` holds multi-file playable demos with a `conf.lua` and `main.lua`; `tests/lua/unit/` holds assertion-only proof files that call `test_summary()` at the end. Do not mix these styles.
- When writing a demo or example, every `lurek.*` call used must also appear in `docs/api/lurek.md`. If you find a call that does not appear there, either it is undocumented (file an issue) or it is a private function that should not be called from content.
- Harness-registered Lua test files must end with `test_summary()` and use `assert_equal`, `assert_true`, `assert_false`, `assert_near` from the test harness. Do not use plain `assert()` — it gives no context on failure.
- Library modules under `library/<name>/init.lua` expose a single table. Usage: `local Inv = lurek.require("library/inventory")`. The library must not call `lurek.game.on_*` — it provides state and logic that the game script wires to callbacks.
- `conf.lua` fields map directly to `src/runtime/config.rs` fields. The source of truth for valid keys and defaults is that file. When writing a config template, read it before guessing defaults.
- Run `python tools/validate/validate_game.py` on new game folders to verify `conf.lua` structure, required files, and harness registration before committing.
## Companion File Index
- None.

## References
- content/games/
- content/examples/
- tests/lua/
- docs/api/lurek.md
