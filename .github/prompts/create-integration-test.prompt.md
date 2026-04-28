---
description: "Create a new integration test suite."
---

# Create Integration Test

## Goal
- Write a new integration test suite for a Lurek2D module. Use when a module lacks test coverage or new public API needs validation. Produc...

## Inputs
- MODULE the module to test (e.g., math, physics, graphics, input, audio)
- FUNCTIONS list of public functions/types to cover
- REGRESSION optional: a specific bug scenario to add as a regression test

## Steps
- Load rust-coding, testing-rust before changing any files.
- Load skill testing-rust/SKILL.md
- Read the module's src/<module>/mod.rs to understand what's public
- Open (or create) tests/<module>_tests.rs
- For each public type and function:
- Float comparison rules:
- NEVER assert_eq!(3.14_f32, some_float) use assert!((val - expected).abs() < 1e-5)
- No I/O, no window, no network in integration tests
- If testing audio::Mixer, the test must still pass when no audio hardware is present
- Run: cargo test <module>_tests to verify

## Success Criteria
- [ ] tests/<module>_tests.rs with tests covering all specified public functions
- [ ] Verified: cargo test passes

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /create-integration-test <description> <module> <module_name>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: rust-coding, testing-rust
- **Inputs required**: description, module, module_name
