---
description: "Create one new Rust engine module with spec, tests, and correct layout."
---

# Create Engine Module

## Goal
- Create one bounded Rust engine module with correct ownership.

## Inputs
- Module name and purpose.
- Tier placement in the five-group architecture.
- Required public surface.
- Validation gate.

## Steps
1. Load module-architecture, rust-coding, and testing-rust before acting.
2. Read src/lib.rs, Cargo.toml, and docs/specs/README.md before adding any files.
3. Create the module directory and files following mod.rs-thin rules. Write the matching docs/specs/<module>.md immediately.
4. Implement the minimal public surface from the accepted contract. Push business logic into the module directory, not into src/lua_api/.
5. Write Rust unit tests in tests/rust/unit/<module>_tests.rs if the module has Rust-only internal behavior.
6. Update src/lib.rs, update docs/specs/README.md, and run cargo check then the narrowest cargo test for the new module.

## Success Criteria
- [ ] Module fits the declared tier and import direction.
- [ ] docs/specs/<module>.md exists and is correct.
- [ ] mod.rs is thin.
- [ ] cargo check and targeted tests pass.
- [ ] No unrelated drift was introduced.

## Example Invocation
- /create-engine-module module=minimap tier=feature-systems
