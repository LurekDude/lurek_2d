---
description: "Load when creating or updating a library/ module, its docs, example, or harness registration. Skip for engine Rust, single examples, or full game demos."
alwaysApply: false
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
- Each library lives under library/<name>/ with init.lua as the entry point and example.lua as the first happy-path consumer.
- tests/lua/library/ plus tests/lua/harness.rs move with library API changes.
- Library docs come from LDoc tags and tools/docs/gen_lib_docs.py, not from a second manual API copy.
- library/ is pure Lua and should expose reusable author-facing helpers that compose lurek.* APIs.
- Keep the public surface small, named clearly, and example-driven.
- README and example.lua should make the library usable without reading engine source.
- Libraries are reusable Lua surfaces for game authors and modders.
- A library should expose a clear, narrow public API.
- Prefer stable data shapes and module names because library code tends to be copied into content faster than core engine APIs change.

## References
- library/
- tests/lua/library/
- tests/lua/harness.rs
- tools/docs/gen_lib_docs.py
