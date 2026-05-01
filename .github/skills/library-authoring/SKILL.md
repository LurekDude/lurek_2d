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
- Package layout is fixed: `library/<name>/init.lua` (entry point, all public API), `library/<name>/example.lua` (single happy-path consumer script), and `README.md` (one-paragraph summary and usage snippet). Every library must have all three. Missing one makes the library undiscoverable by the test harness and unclear to authors.
- How to register a library in the test harness: open `tests/lua/harness.rs`, find the `lua_library_*` test list, and add a `lua_library_<name>` entry pointing to `tests/lua/library/test_library_<name>.lua`. This file is what `cargo test --test lua` runs. Without the harness entry, the library is never tested in CI.
- How library documentation is generated: LDoc comment tags on public functions in `init.lua` are read by `tools/docs/gen_lib_docs.py`. Run `python tools/docs/gen_lib_docs.py` after any API change and check `docs/api/library.md` (or `docs/library/`) for the updated output. The doc comment format is `--- Summary line. @param name type desc @return type desc` — same as used in `docs/library/` spec files.
- Library modules are pure Lua. They may call `lurek.*` APIs but must not call internal engine symbols or reach into `src/` at runtime. If a library needs behavior the engine does not expose, that is a signal to add a `lurek.*` function, not to add a Rust dependency to the library.
- How to keep example.lua honest: `example.lua` must run headlessly via `cargo test --test examples_load_test` without error. It should call every major public function of the library at least once. If the library has conditional paths (e.g., different behavior based on input shape), show both paths in the example.
- Naming rules: public functions use `snake_case`. The module table returned by `init.lua` should be named to match the folder: `library/stats/init.lua` returns a table assigned to `stats`. Do not use `M` or `_M` as the return name — those patterns are opaque.
- When updating a library API: update `init.lua`, then update `example.lua` to call the new signature, then update `tests/lua/library/test_library_<name>.lua` to test the new behavior, then regenerate docs. All four in the same commit, no exceptions.
## Companion File Index
- None.

## References
- library/
- tests/lua/library/
- tests/lua/harness.rs
- tools/docs/gen_lib_docs.py
