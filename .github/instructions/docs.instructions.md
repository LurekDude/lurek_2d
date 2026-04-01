---
applyTo: "docs/**"
---

# Documentation Instructions

All files in `docs/` must accurately reflect the current engine API and architecture. Documentation must be updated whenever the Lua API surface, module structure, or build process changes.

## Core Rules

- **API reference must match implementation**: every function in `docs/lua_api_reference.md` must exist in `src/lua_api/`; remove or update any that don't
- **Getting started commands must be tested**: the `cargo run -- examples/hello_world` command in `docs/getting_started.md` must work on a clean checkout
- **Version numbers come from Cargo.toml**: never hardcode dependency versions in docs — reference `Cargo.toml` as the source of truth
- **Architecture docs reflect current module structure**: `docs/architecture.md` must match the actual `src/` directory layout

## Layer / Boundary Rules

| File | Owns | Must not contain |
|---|---|---|
| `docs/lua_api_reference.md` | Complete `luna.*` API reference | Rust implementation details |
| `docs/architecture.md` | Pipeline, module structure, design decisions | Tutorial content |
| `docs/getting_started.md` | Build, run, first game tutorial | Full API reference |

## Compliance

- Key names documented as lowercase: `"space"`, `"escape"` — always consistent with `src/input/keyboard.rs`
- Function signatures must show actual parameter types and return values
- New modules added to `src/` must appear in `docs/architecture.md` within the same PR

## Avoid

- links to other game engines that could imply copying or plagiarism
- Documenting internal Rust types in user-facing docs — only document the `luna.*` Lua API
- Stale examples that use deprecated function signatures
- Omitting the `-- examples/` path separator when documenting `cargo run` usage
- Documenting planned/future features as if they exist
