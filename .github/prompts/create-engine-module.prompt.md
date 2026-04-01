---
description: "Create a new engine module in src/ with correct structure, dependencies, and registration."
---

# Create Engine Module

## Purpose

Add a new module to the Luna2D engine with the correct file structure, dependency direction, and registration.

## Use When

- Adding an entirely new subsystem (e.g., networking, particles, animation)
- The functionality doesn't fit in any existing module

## Do Not Use When

- Adding a file to an existing module
- Refactoring existing module boundaries

## Inputs

- **Module name**: lowercase, single word (e.g., `particles`, `animation`)
- **Responsibility**: What the module owns
- **Dependencies**: Which existing modules it needs (must follow dependency rules)

## Steps

1. Create directory `src/<module>/`
2. Create `src/<module>/mod.rs` with module-level docs and re-exports
3. Create type files (e.g., `src/<module>/type_name.rs`)
4. Add `pub mod <module>;` to `src/lib.rs`
5. Verify dependency direction: only depends on `math` (no cross-domain)
6. Create integration test: `tests/<module>_tests.rs`
7. Run `cargo build`, `cargo test`, `cargo clippy`

## Outputs

- New `src/<module>/` directory with `mod.rs` and type files
- Updated `src/lib.rs` with module registration
- New `tests/<module>_tests.rs`
- Verified: compilation, tests, clippy all pass

## Acceptance

- [ ] Module directory and files created
- [ ] `mod.rs` has re-exports
- [ ] `lib.rs` updated with `pub mod`
- [ ] Dependency direction correct (only `math` allowed for domain modules)
- [ ] Integration test exists
- [ ] `cargo build` passes
- [ ] `cargo test` passes

## References

- `module-architecture` skill
- `rust-coding` skill
