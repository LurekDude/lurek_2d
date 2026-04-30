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
- Demos live under content/games/<category>/<name> and should be runnable with main.lua plus conf.lua or conf.toml, so the folder itself remains a self-contained showcase unit.
- README.md should explain the demo goal quickly, the capability family it proves, and how to run it; screen.png is supporting material, not the contract.
- Demo smoke coverage currently lives in tests/demo_smoke_tests.rs and Lua smoke files under tests/lua/demos/, so new demos should fit that verification model instead of living as untracked content.
- A demo should showcase one capability cluster clearly, not become a dumping ground for unrelated APIs or a pseudo-game that obscures what is under test.
- If the demo exposes public API behavior, keep related docs, examples, and any affected smoke or load tests in sync with the same capability.
- Prefer small, robust setup over heavy content that hides the engine feature being demonstrated; the point is clear evidence, not asset volume.
- Good demo content should make both the success path and the likely regression path obvious so a broken engine feature is visible quickly.
- Registration, load tests, and smoke coverage should line up with the current tests/demo_smoke_tests.rs and other demo-oriented checks already in the repo.
- Asset choices in a demo should support the feature being shown, not introduce unrelated complexity that makes failures harder to attribute.
- Demos are broader than examples but still narrower than full games; they should be playable enough to demonstrate behavior without turning into open-ended content maintenance.
- This skill owns runnable showcase content, demo folder shape, and demo-level sync work, not generic examples, reusable library layout, or engine Rust implementation.
## Companion File Index
- None.

## References
- content/games/
- tests/lua/demos/
- tests/demo_smoke_tests.rs
- tests/games_load_test.rs
