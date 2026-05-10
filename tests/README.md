# Lurek2D Test Suite Overview

Lurek2D uses a two-layer test system executed through cargo:

- Rust tests in tests/rust/ for engine internals.
- Lua BDD tests in tests/lua/ for lurek.* behavior.

This file is a short contributor guide. The architecture source of truth is docs/architecture/test-framework.md.

## Quick Commands

| Goal | Command |
|---|---|
| Full quality gate | python tools/dev/parallel_cargo.py fmt check ; python tools/dev/parallel_cargo.py clippy --deny-warnings ; python tools/dev/parallel_cargo.py test rust ; python tools/dev/parallel_cargo.py test lua |
| Run Rust tests only | python tools/dev/parallel_cargo.py test rust |
| Run Lua tests only | python tools/dev/parallel_cargo.py test lua |
| Strict Lua API coverage | python tools/audit/lua_api_test_coverage.py --strict --threshold 50 |
| Describe gate | python tools/audit/lua_api_test_coverage.py --strict --describe-threshold <N> |
| Analytics JSON | python tools/audit/test_analytics.py --json |
| Analytics HTML | python tools/audit/test_analytics.py --html |
| Perf Regression Gate | python tools/audit/perf_regression_gate.py --min-stress-pct 35 |
| Generate Contract Tests | python tools/audit/gen_lua_contract_tests.py |
| Mutation Report | python tools/audit/mutation_report.py |

## Directory Layout

- tests/rust/unit/: per-module Rust unit tests for private/internal logic.
- tests/rust/stress/: Rust load and throughput checks.
- tests/rust/golden/: deterministic Rust golden checks.
- tests/rust/config/: configuration tests.
- tests/rust/security/: sandbox and path safety tests.
- tests/rust/ext/: cross-module Rust smoke tests.
- tests/lua/harness.rs: explicit registration of Lua test files.
- tests/lua/unit/: one file per module for lurek.* API contracts.
- tests/lua/library/: one file per pure-Lua library.
- tests/lua/integration/: tests touching at least 2 modules.
- tests/lua/stress/: high iteration Lua load tests.
- tests/lua/security/: hostile input and safety behavior.
- tests/lua/evidence/: runtime evidence production.
- tests/lua/golden/: deterministic comparison against baselines.
- tests/lua/config/: Lua config tests.
- tests/lua/demos/: one test per content/games demo.

## Marker Rules

Folder marker mapping is strict:

- tests/lua/unit/ -> @covers
- tests/lua/security/ -> @security
- tests/lua/integration/ -> @integration
- tests/lua/stress/ -> @stress
- tests/lua/evidence/ -> @evidence

Rules:

- Markers must be directly above the it() they annotate.
- Marker indentation must match that it() block.
- @covers entries must be assertion-backed in the same it().
- @tests is forbidden.

## Evidence and Golden

Use a two-step flow:

1. Evidence tests create artifacts from runtime behavior.
2. Golden tests compare output to committed baselines.

Do not mix production and comparison in one it() case.

## Harness and Registration

Lua tests are not auto-discovered. Every new Lua file must be registered in tests/lua/harness.rs.
An unregistered file will not run under cargo test.

## CI and Artifacts

Workflow .github/workflows/test-analytics.yml runs on Windows and Linux and publishes:

- logs/data/lua_api_test_coverage.json
- logs/reports/lua_api_test_coverage.md
- logs/data/test_analytics.json
- logs/reports/test_analytics.html

## Notes

- Never edit generated API docs manually.
- Keep tests deterministic: fixed seeds, fixed dt, no wall-clock assumptions.
- Use expect_near for float comparisons in Lua tests.
