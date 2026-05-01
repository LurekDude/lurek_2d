---
name: demo-creation
description: "Load this skill when creating demo projects in content/games/, including conf.lua, main.lua, README.md, and registration. Skip it for single examples, tests, or engine Rust code."
---
# demo-creation

## Mission
- Own demo folder structure, files, and registration flow.

## When To Load
- Create a new demo.
- Create many demos from a list.
- Update demo setup files or README.

## When To Skip
- Single example files.
- Test writing.
- Engine Rust code.

## Domain Knowledge
- Demo folder structure is mandatory: `content/games/<category>/<name>/conf.lua`, `main.lua`, `README.md`. Optional but recommended: `screen.png` (240×135), `assets/`. A demo folder missing `conf.lua` will fail `tests/games_load_test.rs`.
- `conf.lua` required keys: `title` (string), `width` (integer), `height` (integer). Optional recommended keys: `fps_target` (default 60), `vsync` (default true). Check `src/runtime/config.rs` for the full list and defaults before writing a conf template.
- After creating a demo, register it in three places: (1) `tests/games_load_test.rs` — add a `lua_game_<name>` test, (2) `tests/demo_smoke_tests.rs` — add a `#[ignore]` smoke test if screenshot evidence is needed, (3) `tests/lua/harness.rs` — add an entry if the demo has a Lua test file. Missing any registration means the demo is invisible to CI.
- Smoke tests in `tests/demo_smoke_tests.rs` run with `#[ignore]` and require a window. They are run manually or in dedicated CI jobs with a display. Do not make a smoke test part of the default `cargo test` run.
- README.md structure: one-line description, feature list (3-5 bullets), "How to run" section (one cargo command or task label), and "What to look for" section explaining the expected behavior. Keep it under 30 lines.
- Asset budget: demos should use only assets already in `assets/` (shared fonts, test images) or tiny purpose-specific assets in `content/games/<name>/assets/`. Do not add large binary assets to prove a small point.
- A demo that proves one capability cluster (e.g., particle systems, tilemap rendering, dialog flow) is more useful than a demo that proves many. If a demo grows beyond ~200 lines in `main.lua`, consider splitting it or promoting it to a full game.
- `content/games/<name>/` category choices: `demos/` (engine feature showcase), `tests/` (Lua-test-adjacent), `games/` (playable content). Do not place engine feature demos in `games/` or playable content in `demos/`.
- How to write `main.lua` for a demo: start with `function lurek.load()` for one-time setup (load assets, create physics world, initialize state), `function lurek.update(dt)` for per-frame logic, and `function lurek.draw()` for all draw calls. The demo must not use `require` on library modules unless demonstrating that specific library — bare `lurek.*` calls only.
## Companion File Index
- None.

## References
- content/games/
- tests/lua/demos/
- tests/demo_smoke_tests.rs
- tests/games_load_test.rs
