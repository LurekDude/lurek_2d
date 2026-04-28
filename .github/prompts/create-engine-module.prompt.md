---
description: "Create a new engine module in src/."
---

# Create Engine Module

## Goal
- Add a new module to the Lurek2D engine with the correct file structure, dependency direction, and registration.

## Inputs
- **Module name**: lowercase, single word (e.g., particles, animation)
- **Responsibility**: What the module owns
- **Dependencies**: Which existing modules it needs (must follow dependency rules)

## Steps
- Load module-architecture, rust-coding before changing any files.
- Create directory src/<module>/
- Create src/<module>/mod.rs with module-level docs and re-exports
- Create type files (e.g., src/<module>/type_name.rs)
- Add pub mod <module>; to src/lib.rs
- Verify dependency direction: only depends on math (no cross-domain)
- Create integration test: tests/<module>_tests.rs
- Run cargo build, cargo test, cargo clippy

## Success Criteria
- [ ] New src/<module>/ directory with mod.rs and type files
- [ ] Updated src/lib.rs with module registration
- [ ] New tests/<module>_tests.rs
- [ ] Verified: compilation, tests, clippy all pass

## Anti-patterns
- Adding a file to an existing module
- Refactoring existing module boundaries

## Example Invocation
- /create-engine-module <module>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: module-architecture, rust-coding
- **Inputs required**: module
