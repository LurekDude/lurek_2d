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
- After adding tests, run `python tools/audit/test_coverage.py` and `python tools/audit/lua_api_test_coverage.py` to confirm that coverage registration matches the touched suite.
- Folder marker rules (enforced by `python tools/audit/lua_test_structure_audit.py`):
  - `tests/lua/unit/` -> `-- @covers ...`
  - `tests/lua/security/` -> `-- @security ...`
  - `tests/lua/integration/` -> `-- @integration ...`
  - `tests/lua/stress/` -> `-- @stress ...`
  - `tests/lua/evidence/` -> `-- @evidence ...`
  - Marker lines must sit directly above the `it()` they annotate and be indented exactly like that `it()`.
  - For `@covers` in unit tests: mark only symbols that are called and assertion-backed in that same `it()`.
  - `-- @tests` is **forbidden**.
- Manual cleanup workflow for existing suites:
  - Work in batches of **max 3 Lua files**.
  - Read each file fully before editing.
  - Apply **manual** marker corrections (no bulk repo-wide rewrite pass).
  - After each 3-file batch, run `python tools/audit/lua_test_structure_audit.py --path <file>` for each touched file and proceed only if all pass.
  - Use helper scripts only for detection/reporting, not for blind mass edits.
- Demo tests go in `tests/lua/content/games/test_<name>.lua` and `tests/demo_smoke_tests.rs` — not in `tests/lua/unit/`. Mixing demo tests with unit tests defeats the purpose of both suites.

## Test Type Matrix (Authoritative)

Each Lua test family has a distinct goal, marker set, and acceptance rule. Do not mix them.

- **Lua Unit (`tests/lua/unit/`)**
  - Goal: verify single public module contracts (`lurek.*`) in isolation-level scenarios.
  - Marker above each `it()`: `-- @covers ...`
  - Required style: mark only symbols whose behavior is validated by assertions inside that `it()`.
  - Not allowed: integration-only markers (`@integration`, `@security`, `@stress`, `@evidence`) as the primary marker.

- **Lua Integration (`tests/lua/integration/`)**
  - Goal: verify behavior across at least two subsystems (for example, pathfind + minimap, save + network).
  - Marker above each `it()`: `-- @integration ...`
  - Multiple `-- @integration` lines above one `it()` are valid when the test asserts multiple integration symbols.
  - Every listed integration symbol must be called and assertion-backed inside that same `it()`.
  - Required style: assert cross-module contract effects (inputs/outputs/observable state), not internal algorithm shape.
  - Not allowed: brittle route-shape assumptions unless engine spec guarantees exact shape.

- **Lua Security (`tests/lua/security/`)**
  - Goal: reject malformed or hostile inputs; verify safe failure behavior.
  - Marker above each `it()`: `-- @security ...`
  - Required style: explicit invalid input + explicit expected safe outcome (`expect_error`, clamped output, no crash contract).
  - Not allowed: assertions based on assumptions that conflict with current supported API contracts.

- **Lua Stress (`tests/lua/stress/`)**
  - Goal: throughput/stability under high load.
  - Marker above each `it()`: `-- @stress ...`
  - Required style: deterministic loops and bounded checks (no ambient timing assumptions unless explicitly tolerated).
  - Not allowed: "no crash = pass" without at least one measurable post-condition.

- **Lua Evidence (`tests/lua/evidence/`)**
  - Goal: produce reproducible artifacts/output to support behavior claims.
  - Marker above each `it()`: `-- @evidence ...`
  - Required style: explicit evidence path/content checks where available.
  - Not allowed: silent pass paths without rationale for unavailable environment features.

- **Lua Config / Library / Demo suites**
  - Goal: suite-specific contracts; follow local conventions in those directories.
  - Marker policy: keep existing local marker scheme; do not force unit-marker style if suite has separate semantics.
  - Not allowed: migrating tests between families just to satisfy marker tooling.

## Marker and Docstring Rules (Hard Requirements)
- **Marker accuracy (CRITICAL)**:
  - A marker symbol must correspond to a call that TESTS the symbol, not merely uses it.
  - If `local x = lurek.module.new()` appears with NO assertion validating `new()` contract, DO NOT mark `lurek.module.new`.
  - Setup calls without assertions are **invisible to markers** — remove them from the marker list.
  - Example violation: calling `lurek.animation.new()` to create an object but never asserting the object's type/fields/behavior. REMOVE that marker.
  - Example correct: calling `lurek.animation.new()` AND asserting `expect_type("userdata", anim)` or similar. KEEP that marker.
- Marker placement:
  - Marker lines must be directly above `it()`.
  - Marker indentation must exactly match the indentation of `it()`.
  - No blank line between the last marker and `it()`.

- Marker choice:
  - Use one primary family marker by file family (`@covers`, `@integration`, `@security`, `@stress`, `@evidence`).
  - Do not mix family markers in one `it()` unless explicitly required by a validator rule.
  - Never do blind cross-family marker rewrites (for example repo-wide `@security -> @covers` or `@covers -> @security`). Any migration must be scoped per folder and validated per file.

- Symbol accuracy:
  - Marker symbols must correspond to calls made in that `it()` body.
  - Marker symbols must be assertion-backed in that same `it()`; usage without verification is forbidden.
  - Do not add markers for symbols not called in the test body.

- Assertion-backed coverage examples:
  - Valid `@covers`: call `lurek.compute.zeros(...)` and assert returned tensor shape/type/values.
  - Invalid `@covers`: call `lurek.compute.zeros(...)` only to feed another function, with no assertion on `zeros` behavior.
  - Valid constructor `@covers`: call `newX()` and assert defaults/fields/type.
  - Invalid constructor `@covers`: call `newX()` only as helper setup, no constructor contract assertions.

- Forbidden markers:
  - `-- @tests` is forbidden.

- Describe marker:
  - Keep `-- @describe` before each `describe(...)` block for readability and audit consistency.

## Integration Test Design Rules

- **File placement rule**: Only place tests in `tests/lua/integration/` if they test behavior across at least TWO modules from different subsystems.
  - Example valid integration: animation drives sprite on screen (animation + render subsystems).
  - Example invalid (move to unit): animation frame counter increments (animation only — zero subsystem interaction).
  - Example valid integration: input (keyboard) changes active animation (input + animation).
  - Example invalid (move to unit): calling `lurek.animation.new()` and asserting it returns a table (zero interaction with any other module).

- Integration tests must prove subsystem interaction, not internal path geometry.
- Avoid testing single-module contracts through integration files — those belong in `tests/lua/unit/`.
- Prefer stable invariants:
  - endpoint correctness,
  - object lifecycle (`create`, `replace`, `clear`),
  - serialization/deserialization round-trip,
  - callback/event propagation.
- Avoid brittle invariants unless spec guarantees them:
  - exact path length,
  - exact node-by-node route,
  - exact ID reuse/non-reuse behavior.

## Security Test Design Rules

- Use "supported contract first" principle: do not assert rejection for inputs that API intentionally supports.
- Every rejection test must tie to one explicit invalidity reason:
  - type mismatch,
  - range violation,
  - malformed payload,
  - forbidden operation.
- Every acceptance test of edge input must still assert at least one correctness post-condition.

## Definition of Done (Per Changed Test File)

- File-level checks:
  - `python tools/audit/lua_test_structure_audit.py --path <file>` passes.
  - Markers match file family rules above.

- Execution checks:
  - Run the specific target test (`cargo test --test lua_tests <target> -- --test-threads 1`).
  - If user asks for batch processing, run full relevant batch and report exact failing targets.

- Reporting checks:
  - If a full suite fails, identify the first failing file and first failing assertion line.
  - Do not report unrelated tests as root cause for the currently edited file.
## Companion File Index

None - all guidance is inline.

## References
- tests/lua/
- tests/rust/unit/
- tools/audit/test_coverage.py
- tools/audit/lua_api_test_coverage.py
