---
name: documentation
description: "Load this skill when writing or updating Lurek2D documentation: API reference, architecture docs, tutorials, README, or code comments. It owns doc style, structure, and accuracy verification. Skip it for code implementation."
---

# Documentation — Lurek2D Engine

## Load When

- Writing or updating `docs/` files
- Updating `README.md`
- Writing code comments for complex algorithms
- Creating tutorials or getting-started guides
- Documenting new API functions

## Owns

- Documentation structure and style
- API reference format and accuracy
- Architecture documentation
- Tutorial and getting-started content
- Code comment conventions

## Does Not Cover

- CAG file documentation → use `tools-cag-validation` skill
- Code implementation → use `rust-coding` skill
- API design decisions → use `lua-api-design` skill

## Live Repository Contracts

- `docs/API/lua_api_reference_generated.md` — generated Lua API reference (do not hand-edit)
- `docs/architecture/engine-architecture.md` — module structure, tier system, rendering pipeline
- `docs/architecture/philosophy.md` — design assumptions, binding constraints, Zen of Luna
- `docs/architecture/test-framework.md` — test suite architecture and quality gates
- `README.md` — project overview and quick start

## Layer Model Terminology

Always use these exact terms when writing architecture or API documentation:

| Term | Meaning |
|------|---------|
| **Baseline** | Always-on substrate: `src/math/` (leaf) + `src/engine/` (lifecycle) |
| **Tier 1** | Core engine subsystems built on Baseline only |
| **Tier 2** | Reusable engine extensions built on Baseline + Tier 1 |
| **Tier 3 Lunasome** | Pure-Lua standard libraries under `content/library/` — NOT Rust source |
| **bridge layer** | `src/lua_api/` — registers `lurek.*`; not a numbered tier |

`lua_api` is the bridge layer, not "Tier 3." Tier 3 Lunasome lives in `content/library/` and is pure Lua.

Legacy gameplay Rust modules still under `src/` (`battle`, `cardgame`, `combat`, etc.) are **migration-state** — being superseded by `content/library/` equivalents. Document them as deprecated, not as active Tier 3.

## Testing Docs Conventions

The test suite has three distinct categories — always distinguish them:

| Category | Location | How to run |
|----------|----------|-----------|
| Engine integration tests | `tests/unit/`, `tests/rust/ext/`, `tests/rust/game/`, `tests/rust/stress/` | `cargo test --test <name>` |
| Lua BDD harness | `tests/lua/harness.rs` dispatches `tests/lua/**/*.lua` | `cargo test lua_test_<module>` |
| Example smoke runs | `content/demos/<name>/` or `examples/<name>/` directories | `cargo run -- content/demos/<name>` |

Never conflate these. A failing integration test and a failing cargo run are different problems.

## Decision Rules

- **Accuracy first**: Every documented API must match the actual code signature
- **Working examples**: Code snippets in docs must be runnable
- **One source of truth**: Don't duplicate information across doc files — cross-reference
- **Lua perspective**: API reference written for Lua script authors, not Rust developers
- **Function format**: `lurek.module.function(param1, param2)` — Returns: description
- **Layer model terms**: Always use the exact terms from the table above (e.g., "Tier 1", "bridge layer")
- **require("library.*)**: In code examples, `require("library.combat")` etc. refer to shipped Lua modules under `content/library/` — never describe `content/library/` as Rust source
- **Example paths**: Run commands must use real directory names from `content/demos/` or `examples/` — not invented paths
- **Architecture docs**: Must reflect current module structure — update when modules change
- **Markdown style**: Headers with `##`, code blocks with language tags, tables for reference data

## Avoid

- Linking to other game engines as references or comparisons
- Documenting files or API functions that do not exist in the codebase
- Inventing workflows not reflected in the actual engine code
- Using stale or deprecated function signatures
- Treating `content/library/` as Rust source — it is pure Lua
- Describing planned or future features as if they currently exist
