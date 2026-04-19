---
description: Write a new integration test suite for a Lurek2D module. Use when a module lacks test coverage or new public API needs validation. Produc...
agent: Tester
---
# Create Integration Test

## Goal

Write a new integration test suite for a Lurek2D module. Use when a module lacks test coverage or new public API needs validation. Produc... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `MODULE` — the module to test (e.g., `math`, `physics`, `graphics`, `input`, `audio`)
- `FUNCTIONS` — list of public functions/types to cover
- `REGRESSION` — optional: a specific bug scenario to add as a regression test

## Steps

1. Load [skill: rust-coding](.github/skills/rust-coding/SKILL.md), [skill: testing-rust](.github/skills/testing-rust/SKILL.md) before changing any files.
2. Load skill `testing-rust/SKILL.md`
3. Read the module's `src/<module>/mod.rs` to understand what's public
4. Open (or create) `tests/<module>_tests.rs`
5. For each public type and function:
6. Float comparison rules:
7. NEVER `assert_eq!(3.14_f32, some_float)` — use `assert!((val - expected).abs() < 1e-5)`
8. No I/O, no window, no network in integration tests
9. If testing `audio::Mixer`, the test must still pass when no audio hardware is present
10. Run: `cargo test <module>_tests` to verify

## Success Criteria

- [ ] `tests/<module>_tests.rs` with tests covering all specified public functions
- [ ] Verified: `cargo test` passes

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-integration-test <description> <module> <module_name>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: rust-coding, testing-rust
- **Inputs required**: description, module, module_name
