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
- Each library lives under library/<name>/ with init.lua as the entry point and example.lua as the first happy-path consumer, so package shape should stay predictable across modules.
- tests/lua/library/ plus tests/lua/harness.rs move with library API changes; updating one without the others leaves the library effectively undiscoverable or unverified.
- Library docs come from LDoc tags and tools/docs/gen_lib_docs.py, not from a second manual API copy, so documentation fixes should start in the source comments.
- library/ is pure Lua and should expose reusable author-facing helpers that compose lurek.* APIs, not mirror engine internals or create a second core runtime.
- Keep the public surface small, named clearly, and example-driven; a library should solve one family of author problems without becoming a grab bag.
- README and example.lua should make the library usable without reading engine source, while tests/lua/library/ should prove the important contracts headlessly.
- Libraries are reusable Lua surfaces for game authors and modders, so example.lua, tests, and generated docs must all tell the same story about the module.
- A library should expose a clear, narrow public API instead of becoming a second engine namespace or a dumping ground for unrelated helpers.
- If a library wraps or composes a lurek.* surface, keep the public terminology aligned and use LDoc cross-links where that helps discoverability.
- Prefer stable data shapes and module names because library code tends to be copied into content faster than core engine APIs change.
- This skill owns reusable Lua package shape, source comments, examples, and harness registration, not one-off examples, demo content, or engine Rust implementation.
## Companion File Index
- None.

## References
- library/
- tests/lua/library/
- tests/lua/harness.rs
- tools/docs/gen_lib_docs.py
