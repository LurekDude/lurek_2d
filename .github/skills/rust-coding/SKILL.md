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
- Prefer clear ownership and small public surfaces.
- Keep unsafe small and justified.
- Keep domain logic out of thin wrapper layers.
- Follow existing module style.
- Use narrow validation first, then wider gates.
- Keep fixes at the root cause.

## Companion File Index
- None.

## References
- src/
- docs/specs/
- Cargo.toml
