---
name: testing-rust
description: "Load this skill when writing or organizing tests for the Luna2D engine. It owns test patterns, float comparison strategies, test naming, and integration test architecture. Skip it for writing production code or Lua scripts."
---

# Testing Rust — Luna2D Engine

## Load When

- Writing new tests in `tests/` or inline `#[cfg(test)]` modules
- Reviewing test coverage for a module
- Fixing test failures or flaky tests
- Organizing test structure

## Owns

- Test naming conventions and organization
- Float comparison with tolerance
- Integration test patterns (`tests/<module>_tests.rs`)
- Unit test patterns (inline `#[cfg(test)]` modules)
- Test helper utilities

## Does Not Cover

- Fixing production bugs found by tests → route to Developer
- Performance benchmarking → use `performance-profiling` skill
- CI/CD test pipeline → use `ci-cd-pipeline` skill

## Live Repository Contracts

- `tests/math_tests.rs` — Vec2, Mat3, Rect tests
- `tests/physics_tests.rs` — Body, World, Collision tests
- `tests/graphics_tests.rs` — Color, DrawCommand tests
- `tests/input_tests.rs` — Keyboard, Mouse state tests
- `tests/audio_tests.rs` — AudioSource tests

## Decision Rules

- **Integration tests**: `tests/<module>_tests.rs` — test public API from outside the crate
- **Unit tests**: `#[cfg(test)] mod tests { }` inside `src/` files for internal logic
- **Test naming**: `test_<subject>_<scenario>_<expected>` (e.g., `test_vec2_add_positive_values`)
- **Float tolerance**: `assert!((actual - expected).abs() < 1e-5)` — NEVER `assert_eq!` on floats
- **One concern per test**: Each test function checks one logical scenario
- **Edge cases required**: Zero values, negative values, empty collections, boundary conditions
- **Deterministic**: No random inputs, no timing dependencies, no external state
- **Import from crate**: `use luna2d::module::Type;` — not from internal paths
- **Run all tests**: `cargo test` must pass with 0 failures before any change is accepted
