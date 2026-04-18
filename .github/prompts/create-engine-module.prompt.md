---
description: "Create a new engine module in src/ with correct structure, dependencies, and registration."
mode: agent
loads_skills: [module-architecture, rust-coding]
loads_tools: []
expected_agent: Developer
inputs_required: [module]
---

# Create Engine Module

## Goal

Add a new module to the Lurek2D engine with the correct file structure, dependency direction, and registration.

## Inputs

- **Module name**: lowercase, single word (e.g., `particles`, `animation`)
- **Responsibility**: What the module owns
- **Dependencies**: Which existing modules it needs (must follow dependency rules)

## Steps

1. Load [skill: module-architecture](.github/skills/module-architecture/SKILL.md), [skill: rust-coding](.github/skills/rust-coding/SKILL.md) before changing any files.
2. Create directory `src/<module>/`
3. Create `src/<module>/mod.rs` with module-level docs and re-exports
4. Create type files (e.g., `src/<module>/type_name.rs`)
5. Add `pub mod <module>;` to `src/lib.rs`
6. Verify dependency direction: only depends on `math` (no cross-domain)
7. Create integration test: `tests/<module>_tests.rs`
8. Run `cargo build`, `cargo test`, `cargo clippy`

## Success Criteria

- [ ] New `src/<module>/` directory with `mod.rs` and type files
- [ ] Updated `src/lib.rs` with module registration
- [ ] New `tests/<module>_tests.rs`
- [ ] Verified: compilation, tests, clippy all pass

## Anti-patterns

- Adding a file to an existing module
- Refactoring existing module boundaries

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-engine-module <module>`
