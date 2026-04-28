---
name: library-authoring
description: "Load this skill when creating or updating a library/ module, its docs, example, or harness registration. Skip it for engine Rust, single examples, or full game demos."
---
# library-authoring

## Mission
- Own library/ module layout, docs, examples, and test registration.

## When To Load
- Create a library.
- Refactor a library.
- Regenerate library docs.
- Add harness registration for library tests.

## When To Skip
- Engine Rust work.
- Single examples.
- Full demos.

## Domain Knowledge
- library/ is pure Lua.
- Keep init.lua as the entry point.
- Keep example.lua and tests in sync with the library.
- Use LDoc tags consistently.
- Update harness registration when tests change.

## Companion File Index
- None.

## References
- library/
- tests/lua/harness.rs
- tools/docs/gen_lib_docs.py
