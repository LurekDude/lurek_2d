---
description: "Write a new integration test suite for a Lurek2D module. Use when a module lacks test coverage or new public API needs validation. Produces tests/<module>_tests.rs."
---

# Create Integration Test

**Purpose**: Write a complete integration test suite for a Lurek2D engine module.
**Use When**: A module has no tests, new public functions were added without tests, or a bug was fixed and needs a regression test.
**Do Not Use When**: Writing unit tests for private functions (those go in `#[cfg(test)]` inside `src/`).
**Scope**: `tests/<module>_tests.rs`.

## Inputs

- `MODULE` — the module to test (e.g., `math`, `physics`, `graphics`, `input`, `audio`)
- `FUNCTIONS` — list of public functions/types to cover
- `REGRESSION` — optional: a specific bug scenario to add as a regression test

## Steps

1. Load skill `testing-rust/SKILL.md`
2. Read the module's `src/<module>/mod.rs` to understand what's public
3. Open (or create) `tests/<module>_tests.rs`
4. For each public type and function:
   a. Write at least one happy-path test
   b. Write at least one edge-case test (zero values, empty collections, boundary conditions)
   c. If a bug was reported, write a specific regression test with a comment: `// Regression: <description>`
5. Float comparison rules:
   - NEVER `assert_eq!(3.14_f32, some_float)` — use `assert!((val - expected).abs() < 1e-5)`
6. No I/O, no window, no network in integration tests
7. If testing `audio::Mixer`, the test must still pass when no audio hardware is present
8. Run: `cargo test <module>_tests` to verify

## Outputs

- `tests/<module>_tests.rs` with tests covering all specified public functions
- Verified: `cargo test` passes

## Acceptance

- [ ] All specified public functions have at least one test
- [ ] Float comparisons use epsilon — not `assert_eq!`
- [ ] No `#[ignore]` without a documented reason
- [ ] `cargo test` passes (including the new tests)
- [ ] Regression test added if a specific bug was provided

## References

**Required Skills**: `testing-rust`, `rust-coding`
**Suggested Agents**: `Tester`
**Commands**:
```powershell
cargo test
cargo test <module_name>
```
**Docs**: `tests/` directory, module `src/<module>/mod.rs`
