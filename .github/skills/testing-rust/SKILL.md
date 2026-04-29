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
- TST-01 is the main split: lurek.*-reachable behavior goes to tests/lua/, Rust-only internals go to tests/rust/unit/.
- No tests live in src/ and Lua files end with test_summary() plus @covers markers for coverage tools.
- Prefer headless state readback, then pixel readback, then smoke-only evidence when stronger proof is impossible.
- Use expect_near or float epsilon checks, never direct float equality.
- Harness registration and Cargo test-target registration move with new suites.
- Coverage tools already exist: test_coverage.py and lua_api_test_coverage.py.
- The repo already has strong Lua-first rules, headless coverage boundaries, and coverage tooling, so test work should follow those rules instead of inventing ad hoc placement.
- Harness registration, @covers markers, and evidence strength are part of the contract, not optional polish.
- This skill owns test-layer choice, assertions, and coverage practice, not production fixes.
## Companion File Index

None - all guidance is inline.

## References
- tests/lua/
- tests/rust/unit/
- tools/audit/test_coverage.py
- tools/audit/lua_api_test_coverage.py
