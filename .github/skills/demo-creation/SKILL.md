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
- Demos live under content/games/<category>/<name> and should be runnable with main.lua plus conf.lua or conf.toml.
- README.md must explain the demo goal fast; screen.png is optional support, not the contract.
- Demo smoke coverage currently lives in tests/demo_smoke_tests.rs and Lua smoke files under tests/lua/demos/.
- A demo should showcase one capability cluster clearly, not become a dumping ground for unrelated APIs.
- If the demo exposes public API behavior, keep related docs and examples in sync with the same capability.
- Prefer small, robust setup over heavy content that hides the engine feature being demonstrated.
- Demo registration and smoke coverage should line up with tests/demo_smoke_tests.rs and the Lua smoke/demo files already checked into tests/lua/demos/.
- A good demo highlights one capability family, has readable content flow, and makes failure modes obvious when the engine feature regresses.
- Demo-creation owns runnable showcase content, not generic example coverage or reusable library layout.
## Companion File Index
- None.

## References
- content/games/
- tests/lua/demos/
- tests/demo_smoke_tests.rs
- tests/games_load_test.rs
