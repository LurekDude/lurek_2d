---
name: testing-rust
description: "Load this skill when writing or reviewing Rust unit tests, Lua API tests, or test coverage rules. Skip it for feature implementation or non-test game scripting."
---
# testing-rust

## Mission

Own the testing strategy, file layout, assertion patterns, and coverage tooling for both Rust unit tests and Lua binding tests.

## When To Load

- Writing Rust unit tests for internal code in tests/rust/unit/
- Writing Lua tests for lurek.* API surface in tests/lua/
- Understanding which test layer to use for a given behaviour
- Checking test coverage metrics

## When To Skip

- Implementing features -> use rust-coding skill
- Lua scripting unrelated to tests -> use lua-scripting skill

## Domain Knowledge
- Lua-first split (TST-01): behavior reachable through `lurek.*` belongs in `tests/lua/unit/test_<module>_<layer>.lua`, Rust-only private internals in `tests/rust/unit/<module>_tests.rs`. When in doubt, the Lua layer is preferred — if it can be tested via the public API, it must be.
- Never put `#[cfg(test)]` in `src/`. Every test that uses `src/` code but is about private internals lives in `tests/rust/unit/<module>_tests.rs` as a separate binary target.
- File naming is enforced: Rust test files are `<module>_tests.rs` (with the `s`), Lua unit test files are `test_<module>_<layer>.lua`. A file that does not follow the naming convention is not discoverable by `parallel_cargo.py` or the Lua harness.
- Lua test file structure: each file ends with `test_summary()` and every test case uses `assert_equal`, `assert_true`, `assert_near`, or `assert_error` from the harness — not bare `assert()`. Missing `test_summary()` means the harness reports 0 tests, not a pass.
- New Lua test files must be registered in `tests/lua/harness.rs` under the correct suite. New Rust test binaries must be added to `Cargo.toml` as `[[test]]` targets with the correct `name` and `path`.
- Float comparison: use `assert_near(a, b, epsilon)` always. Direct `==` on floats in tests is a defect — CI will catch it intermittently on different build profiles or OS.
- Determinism checklist: fixed random seed (pass seed to lurek.math.random if used), fixed `dt` value (headless tests use `dt = 1/60`), no filesystem reads outside `tests/fixtures/`, no wall-clock time, no window.
- Test granularity: one failing reason per test. `test_body_position_after_one_step()` tests exactly that. `test_physics_all()` is not a valid test name — it makes regression attribution impossible.
- Evidence strength: prefer state-readback assertions over side-effect checks. `assert_equal(body.position.x, 5.0)` is stronger than `assert_true(on_contact_called)`. Use screenshot evidence only when pixel output is the only available signal.
- After adding tests, run `python tools/audit/test_coverage.py` and `python tools/audit/lua_api_test_coverage.py` to confirm that the new test registers as covering the target behavior. A test that covers behavior but has no `@covers` marker is invisible to coverage reports.
- Demo tests go in `tests/lua/content/games/test_<name>.lua` and `tests/demo_smoke_tests.rs` — not in `tests/lua/unit/`. Mixing demo tests with unit tests defeats the purpose of both suites.
## Companion File Index

None - all guidance is inline.

## References
- tests/lua/
- tests/rust/unit/
- tools/audit/test_coverage.py
- tools/audit/lua_api_test_coverage.py
