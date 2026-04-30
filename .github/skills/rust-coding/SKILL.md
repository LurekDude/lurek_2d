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
- mod.rs files stay thin in this repo; public logic, data types, and helpers belong in sibling files, with module roots limited to exports, attributes, and doc comments.
- No #[cfg(test)] blocks belong in src/, and product logic should not be pushed into src/lua_api/ for convenience; binding files stay thin and engine behavior stays in src/<module>/.
- Thin Wrapper Rule and docs/specs sync rules are part of normal Rust work here, not optional cleanup, so implementation changes should keep module contracts and ownership legible.
- Prefer root-cause fixes over defensive layering, explicit error propagation over silent fallback, and narrow validation before broader cleanups or speculative refactors.
- Safe, idiomatic Rust in this codebase means clear ownership, small mutation surfaces, predictable module boundaries, and no hidden policy spread across unrelated files.
- Keep unsafe tiny, justified, and wrapped in stable invariants; if safety depends on order or lifetime assumptions, make that relationship obvious in surrounding code.
- Respect the runtime constraints that shape implementation choices: desktop only, wgpu 22 only, LuaJIT as primary runtime, and isolated Lua VMs across thread boundaries.
- Prefer existing domain modules and helper types before inventing parallel abstractions; consistency across src/ matters more here than importing a fresh pattern from another project.
- Public Rust changes often imply adjacent sync work in specs, tests, examples, or changelog files, so implementation is not complete when the compiler alone is green.
- The repo favors explicit file staging, one logical change per commit, and minimal unrelated churn.
## Companion File Index
- None.

## References
- src/
- docs/specs/
- tests/rust/unit/
- tests/lua/
