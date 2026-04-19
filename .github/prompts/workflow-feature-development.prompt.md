---
description: "Full feature development workflow from design to merged code. Use when starting, extending, or refactoring a Lurek2D feature. Orchestrate..."
agent: Manager
tools: [tools/audit/audit_module.py, tools/audit/test_coverage.py, tools/dist/dist.ps1, tools/docs/collect_docs.py, tools/docs/gen_docs_lua.py, tools/gen_all_docs.py]
---
# Workflow Feature Development

## Goal

Full feature development workflow from design to merged code. Use when starting, extending, or refactoring a Lurek2D feature. Orchestrate... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `FEATURE_DESC` — one paragraph describing the feature and its game-developer-facing value
- `AFFECTED_MODULES` — list of `src/` modules that will change (e.g., `physics/`, `lua_api/`)
- `PRIORITY` — `p1` (blocks other work), `p2` (normal), `p3` (nice-to-have)

## Steps

1. Load [skill: documentation](.github/skills/documentation/SKILL.md), [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md), [skill: lua-rust-bridge](.github/skills/lua-rust-bridge/SKILL.md), [skill: module-architecture](.github/skills/module-architecture/SKILL.md), [skill: rust-coding](.github/skills/rust-coding/SKILL.md), [skill: testing-rust](.github/skills/testing-rust/SKILL.md) before changing any files.
2. Read `docs/architecture/philosophy.md`, `docs/architecture/engine-architecture.md`, and `docs/architecture/test-framework.md` in full before any implementation.
3. Load all skills relevant to the affected domain (e.g., `lua-api-design`, `lua-rust-bridge`, `testing-rust`, `rust-coding`, `module-architecture`).
4. Read `docs/specs/<module>.md` for every affected module — this is the single source of truth for current behaviour and API.
5. Confirm the feature fits within the binding constraints (A-01 … B-05). If it conflicts, stop and raise the conflict before proceeding.
6. Load skill `lua-api-design/SKILL.md`.
7. Route to **Lua-Designer**: design the `lurek.*` API surface.
8. Provide: feature description, affected namespace, reference engine equivalent if any.
9. Get back: finalized function signatures, Lua usage example, parameter defaults.
10. Route to **Architect** if the feature needs a new module or changes module boundaries.
11. Provide: current dependency graph, proposed new module or boundary change.
12. Get back: approved module structure and dependency direction — DAG invariant confirmed.

## Success Criteria

- [ ] Working Rust implementation in `src/<module>/` — domain logic only, no mlua
- [ ] Thin `src/lua_api/<module>_api.rs` wrapper registering all new public methods
- [ ] Updated `src/<module>/IDEA.md`
- [ ] Minimal `src/<module>/mod.rs` — declarations only
- [ ] File-level `//!` on every `.rs` file touched
- [ ] Lua BDD tests in `tests/lua/` registered in `tests/lua/harness.rs`
- [ ] Rust unit tests in `tests/rust/unit/` only for private internals
- [ ] Expanded docstrings on all public items; `python tools/docs/collect_docs.py --report-missing` exits 0
- [ ] Updated `docs/specs/<module>.md`; spec MDs removed from `src/`
- [ ] Regenerated `docs/API/lua-api.md` via `python tools/gen_all_docs.py`
- [ ] `content/examples/<module>.lua` demonstrating the new API
- [ ] `docs/CHANGELOG.md` entry; `Cargo.toml` version bumped if MINOR/MAJOR

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/workflow-feature-development <SharedState> <category> <expected> <module> <name> <scenario> <submodule>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: documentation, lua-api-design, lua-rust-bridge, module-architecture, rust-coding, testing-rust
- **Inputs required**: SharedState, category, expected, module, name, scenario, submodule
