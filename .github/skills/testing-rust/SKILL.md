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
- TST-01 is the main split in this repo: behavior reachable through lurek.* belongs in tests/lua/, while Rust-only internals belong in tests/rust/unit/.
- No tests live in src/, and Lua test files should end with test_summary() plus accurate @covers markers so the existing coverage tools can attribute behavior correctly.
- File placement is part of the contract: Rust unit tests live under tests/rust/unit/<module>_tests.rs, Lua tests follow the test_<module>_<layer>.lua pattern, and demos have their own dedicated locations.
- Prefer headless state readback first, then pixel readback when rendering output matters, and use smoke-only evidence only when stronger assertions are not technically possible.
- Harness registration and Cargo target wiring move with new suites; a good test file is incomplete until the repo can actually discover and run it in the standard flows.
- Use expect_near or explicit epsilon checks for floats; direct float equality should be treated as a bug unless the value is intentionally exact and stable.
- Determinism matters more than clever setup: stable seeds, fixed dt, controlled fixtures, and narrow asset inputs beat large scenario scripts with hidden moving parts.
- Reuse existing fixtures, helpers, and harness patterns before inventing ad hoc scaffolding; consistency keeps failures interpretable across many modules.
- Coverage tools already exist, including test_coverage.py and lua_api_test_coverage.py, so missing coverage should be reported and closed using the repo's current metrics rather than informal guesses.
- Evidence strength should be stated implicitly in the test shape: direct state assertions are stronger than visual inference.
## Companion File Index

None - all guidance is inline.

## References
- tests/lua/
- tests/rust/unit/
- tools/audit/test_coverage.py
- tools/audit/lua_api_test_coverage.py
