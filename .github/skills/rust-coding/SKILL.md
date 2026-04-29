---
name: rust-coding
description: "Load this skill when writing or reviewing Rust engine code. It owns safe Rust conventions, error patterns, module structure, and idiomatic style. Skip it for Lua scripts, CAG files, or docs."
---
# rust-coding

## Mission
- Own safe, idiomatic Rust patterns for the engine codebase.

## When To Load
- Write Rust code.
- Review Rust code.
- Refactor Rust modules.

## When To Skip
- Lua scripts.
- CAG files.
- Docs-only work.

## Domain Knowledge
- mod.rs files stay thin; public logic belongs in sibling files, not module roots.
- No #[cfg(test)] blocks in src/ and no product logic pushed into src/lua_api for convenience.
- Thin Wrapper Rule and docs/specs sync rules are part of normal Rust work here.
- Prefer root-cause fixes, explicit error propagation, narrow validation first, and no warning suppression hacks.
- Keep unsafe tiny, justified, and surrounded by stable invariants.
- Stage explicit files only and keep one logical change per commit.
- Safe, idiomatic Rust here includes thin mod.rs, explicit error flow, source-of-truth specs, and no test hacks inside src/.
- The repo values narrow validation first, root-cause fixes, and minimal unrelated churn over broad cleanup passes.
- This skill owns core implementation behavior and style, not CAG files or Lua authoring.
## Companion File Index
- None.

## References
- src/
- docs/specs/
- tests/rust/unit/
- tests/lua/
