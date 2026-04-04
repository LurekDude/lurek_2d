---
applyTo: "docs/**"
---

# Documentation Instructions

All files in `docs/` must accurately reflect the current Luna2D runtime, Lua API, and layer model. Documentation should describe the active four-layer model as Baseline, Tier 1, Tier 2, and Tier 3 Lunasome. `lua_api` is the bridge above the engine layers, not a numbered tier.

## Core Rules

- **API reference must match implementation**: Lua API documentation in `docs/API/` must match the actual `luna.*` surface exposed from `src/lua_api/`
- **Architecture docs must use the current layer model**: Baseline runtime substrate, Tier 1 core engine subsystems, Tier 2 reusable engine extensions, Tier 3 Lunasome in `library/`
- **Legacy Rust gameplay modules need explicit framing**: when docs mention gameplay-oriented Rust modules under `src/`, describe them as migration-state or legacy engine code, not as the active Tier 3 target architecture
- **Testing docs must separate responsibilities**: distinguish registered engine test binaries, Lua/library tests through `tests/lua/harness.rs`, and example smoke checks via `cargo run -- examples/<name>`
- **Version numbers come from Cargo.toml**: never hardcode dependency versions in docs

## Layer / Boundary Rules

| File / Area | Owns | Must not contain |
|---|---|---|
| `docs/API/` | Public `luna.*` API docs and shipped library semantics when documented | Rust-private implementation details |
| `docs/architecture.md` | Baseline / Tier 1 / Tier 2 / Tier 3 Lunasome model and migration notes | Tutorial content |
| Example snippets in docs | Runnable example code and real import patterns | Fake `tests/examples/` or library test paths |

## Compliance

- When documentation shows `require("library.*")`, it must refer only to shipped modules under `library/`
- Example run commands must use real example directories under `examples/`
- New architecture guidance must mention that lower engine layers do not depend on Tier 3 Lunasome
- If docs describe tests, use the actual registered layout from `Cargo.toml` and `tests/lua/harness.rs`

## Avoid

- Links to other game engines that could imply copying or plagiarism
- Documenting nonexistent files or invented workflows
- Stale examples that use deprecated function signatures
- Treating `library/` as Rust source or treating `src/` gameplay modules as the active Lua standard-library layer
- Documenting planned or future features as if they exist
