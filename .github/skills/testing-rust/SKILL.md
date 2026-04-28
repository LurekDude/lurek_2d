---
name: testing-rust
description: "Load this skill when writing Rust unit tests in tests/rust/unit/ for Rust-only internals. Skip it for Lua tests, feature work, or tests for lurek.* behavior."
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

**TST-01 (critical rule):** any behaviour reachable via lurek.* MUST be tested in Lua under tests/lua/. Rust unit tests are reserved for internal code not exposed to Lua.

**TST-02:** no #[cfg(test)] blocks in src/. All Rust unit tests live in tests/rust/unit/<module>_tests.rs.

**TST-06:** one file per module per test layer. Files named test_<module>_<layer>.lua. Layers: unit/, evidence/, golden/, stress/, security/, config/.

**Lua test pattern (BDD):** describe("module", function() ... it("does X", function() ... end) ... end). End every test file with test_summary(). Assertions: expect_equal(a, b), expect_near(a, b, tolerance), expect_true(x), expect_error(fn), expect_contains(str, sub).

**@covers markers:** every Lua test function includes -- @covers lurek.<module>.<function> for coverage tracking by tools/audit/lua_api_test_coverage.py.

**Float comparison:** never assert_eq! on floats. Use (actual - expected).abs() < 1e-5 in Rust. In Lua use expect_near(a, b, 0.001).

**Evidence tiers (strongest to weakest):** (1) Headless state readback - call API, read state back, assert. (2) Canvas pixel readback - render to canvas, read pixels, check values. (3) Runtime smoke - call API and assert no error (weakest).

**Headless VM availability:** math, thread, timer (read-only), filesystem (read-only), data, image, ecs, tilemap, ai are available in headless tests. render, audio, physics, input require a window and are NOT available headless.

**Coverage tools:** tools/audit/test_coverage.py (cross-reference pub items vs test files), tools/audit/lua_api_test_coverage.py --report (Lua API coverage via @covers markers).

## Companion File Index

None - all guidance is inline.

## References

- tests/lua/ - Lua test suites
- tests/rust/unit/ - Rust unit test files
- tools/audit/test_coverage.py - test coverage metrics
- tools/audit/lua_api_test_coverage.py - Lua @covers coverage

