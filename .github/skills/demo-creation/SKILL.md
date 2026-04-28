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
- Demos live in content/games/.
- Core files are conf.lua or conf.toml, main.lua, README.md, and screen.png when needed.
- Keep each demo runnable and self-explanatory.
- Register new demos where the repo expects them.
- Keep examples and docs in sync with the demo.

## Companion File Index
- None.

## References
- content/games/
- tests/lua/content/games/
- tests/demo_smoke_tests.rs
