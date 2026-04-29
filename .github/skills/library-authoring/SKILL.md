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
- Each library lives under library/<name>/ with init.lua as entry point and example.lua as the first happy-path consumer.
- tests/lua/library/ plus tests/lua/harness.rs move with library API changes; do not update one without the others.
- Library docs come from LDoc tags and tools/docs/gen_lib_docs.py, not a second manual API copy.
- library/ is pure Lua and should expose reusable author-facing helpers, not mirror engine internals.
- Keep the public surface small and example-driven.
- README and example should make the library usable without reading engine source.
- Libraries are reusable Lua surfaces for game authors and modders, so example.lua, tests/lua/library/, and generated library docs must all tell the same story.
- A library should expose a clear, narrow public API instead of becoming a second engine namespace.
- The skill owns reusable Lua package shape and support files, not one-off examples or engine demos.
## Companion File Index
- None.

## References
- library/
- tests/lua/library/
- tests/lua/harness.rs
- tools/docs/gen_lib_docs.py
