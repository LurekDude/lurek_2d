---
description: "Load when creating demo projects in content/games/, including conf.lua, main.lua, README.md, and registration. Skip for single examples, tests, or engine Rust code."
alwaysApply: false
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
- README.md should explain the demo goal quickly, the capability family it proves, and how to run it.
- Demo smoke coverage lives in tests/demo_smoke_tests.rs and Lua smoke files under tests/lua/demos/.
- A demo should showcase one capability cluster clearly.
- If the demo exposes public API behavior, keep related docs, examples, and smoke or load tests in sync.
- Prefer small, robust setup over heavy content that hides the engine feature being demonstrated.
- Good demo content should make both the success path and the likely regression path obvious.

## References
- content/games/
- tests/lua/demos/
- tests/demo_smoke_tests.rs
- tests/games_load_test.rs
