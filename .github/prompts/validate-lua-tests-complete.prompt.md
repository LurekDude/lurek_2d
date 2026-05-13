---
name: validate-lua-tests-complete
description: >-
  Iterate through all Lua test files in tests/lua/, validate each against
  skill guidelines and architecture, run structure + coverage audits, execute tests,
  fix problems without asking, and move to next file until entire folder is validated.
  100% real test coverage required — no placeholders or stubs.
---

# Lua Test Validation Pipeline (Complete)

## Goal
- Validate Lua tests file-by-file and fix issues in place so structure, marker semantics, and execution quality are consistent with tester skill rules.

## Inputs
- Target path: entire `tests/lua/` or a scoped subdirectory/file.
- Applicable architecture constraints from `docs/architecture/test-framework.md`.
- Current tester skill marker and integration rules.

## Steps
- Use the workflow in **One-File Workflow** below, processing files sequentially.
- For integration files, require cross-module assertions in every `it()`.
- After each touched file, run structure audit and scoped test execution.
- After the target set is done, run final suite validation.

## Success Criteria
- [ ] Each processed file passes structure audit.
- [ ] Scoped tests for touched files pass.
- [ ] Final validation command exits 0.
- [ ] Markers are assertion-backed and aligned with file family semantics.

## Anti-patterns
- Marker-only tests with no contract assertion.
- Declaring integration coverage for setup-only calls.
- Grouped markers above `describe()` instead of per `it()`.
- Single-module tests kept in integration folder.

## Scope
- **Input**: Entire `tests/lua/` folder or subdirectory (user specifies at runtime)
- **Target**: Every `.lua` file that is a test (matches `test_*.lua` or `*_test.lua` pattern)
- **Output**: All files audited, passing scoped test runs, coverage validation complete, problems fixed in-place

## One-File Workflow

For each test file:

1. **Read & Understand**
   - Determine test type: feature test, adversarial probe, negative case, or integration test
   - Cross-check file against [docs/specs](../../docs/architecture/test-framework.md) test-layer rules
   - Verify test location matches Lua-first policy: lurek.*-reachable behavior lives here, Rust-only internals belong in tests/rust/

2. **Validate Structure (First Audit)**
   - Run `python tools/audit/lua_test_structure_audit.py` scoped to this file (or batch by feature)
   - Check results for:
     - Missing or misplaced suite markers (`@covers/@security/@integration/@stress/@evidence`)
     - Indentation errors (markers must align with their `it()`)
     - Forbidden `@tests` markers
     - `describe()` blocks with grouped markers at top (invalid; move markers down)
     - Determinism issues: no timestamps, no random seeds, no flaky waits
   - **If problems found**: Fix them using the audit's diagnostic output—do NOT ask permission

3. **Check Test Coverage (Second Audit)**
   - Run `python tools/audit/test_coverage.py` to check API coverage for the module under test
   - If lurek.* symbols reachable from this file are not covered:
     - Identify which symbols are missing coverage
     - Check if existing tests can be extended (prefer)
     - Or write new `it()` blocks to cover missing behavior
     - Ensure every new `it()` has the correct suite marker above it (same indentation as the `it()` itself)
   - Repeat until coverage ≥ 100% for the targeted API surface or file is justified as non-covering (e.g., smoke test, edge case only)

4. **Execute Test Run (Scoped)**
   - Run the test target for this file:
    - If registered in `tests/lua/harness.rs`: `cargo test --test harness -- <test_name> --nocapture`
     - Or directly: `cargo test --test <file_name> -- --nocapture`
   - Capture output: exit code, test count, any errors or panics
   - **If test fails**:
     - Read error message carefully
     - Determine root cause: wrong assertion, missing setup, broken API call, or environmental issue
     - Fix the test (not production code); re-run to confirm pass
     - Do NOT skip or @ignore without explicit justification (rare edge cases only)

5. **Verify No Warnings or Problems**
   - Check full `cargo test` output for warnings (clippy, compiler, test framework)
   - If unused imports, dead code, or type issues appear: remove them
   - Ensure test runs in headless mode (no windowed graphics tests)

6. **Finalize & Move Next**
   - Confirm this file is now clean: passes audits, all tests pass, coverage ≥ 100% (or justified), no warnings
   - Log filename and outcome to work session notes (if in session mode)
   - Proceed to next file

## Batch & Session Management
- **Session artifact**: Save progress in `work/<session-name>/lua_validation_log.txt` as you complete each file (append one line per file: status, any notes)
- **Harness update**: If a new Lua test file is created, ensure `tests/lua/harness.rs` includes its module registration
- **Final validation**: After all files in target folder are validated, run full test suite:
  ```bash
  cargo test --test harness -- --nocapture
  ```
  Confirm exit code 0 and no failures.

## Critical Rules

- **Real tests only**: No `TODO` in test bodies, no marker-only stubs (e.g., `describe("feature", () -> it("test", () -> pass()))`). Every `it()` must exercise the actual API and make real assertions.
- **Assertion-backed markers (CRITICAL)**: A marker symbol must correspond to a call that TESTS (not merely uses) the symbol.
  - INVALID: `local anim = lurek.animation.new()` with NO assertion on anim. Remove `lurek.animation.new` from marker.
  - VALID: `local anim = lurek.animation.new()` AND `expect_type("userdata", anim)`. Keep marker.
  - Setup calls without assertions are invisible to markers — do NOT mark them.
- **Suite markers required**:
  - `tests/lua/unit/` -> `@covers`
  - `tests/lua/security/` -> `@security`
  - `tests/lua/integration/` -> `@integration`
  - `tests/lua/stress/` -> `@stress`
  - `tests/lua/evidence/` -> `@evidence`
  Every `it()` must have the correct marker on the line immediately above it, at the same indentation level.
- **@integration markers required (integration)**: Every `it()` in `tests/lua/integration/` must have one or more `-- @integration` lines immediately above it.
  - Multiple `-- @integration` lines are valid and expected when a test validates multiple symbols.
  - Every listed integration symbol must be called and assertion-backed in the same `it()`.
  - The test must prove cross-module behavior — if it tests only a single module, move it to `tests/lua/unit/`.
  - INVALID: test calls `lurek.animation.new()` + methods but asserts animation frame counter only (zero interaction with other modules).
  - VALID: test calls animation + render, proves that animation frame drives sprite output on screen.
- **No grouped markers**: Do NOT place suite markers above a `describe()`. Each `it()` owns its own marker.
- **No @tests marker**: The old `-- @tests` syntax is forbidden. Use suite markers only.
- **Determinism**: Tests must not depend on order, random state, or filesystem timing. Use fixtures or mocks.
- **One probe per attack**: Adversarial tests dedicate one file/script per hypothesis (e.g., `test_raycaster_overflow_probe.lua`). This keeps attribution clear.
- **Test layer separation**: Lua-reachable lurek.* behavior is tested here. Pure Rust internals go to `tests/rust/unit/<module>_tests.rs`. Do not duplicate or skip one layer to avoid writing the other.
- **Coverage is real**: Use `test_coverage.py` output to guide; don't fake coverage by writing tests that don't actually call the API.

## Example Invocations

```
/validate-lua-tests-complete

  Validate all of tests/lua/:
  - Read each file
  - Run structure audit (lua_test_structure_audit.py)
  - Run coverage audit (test_coverage.py)
  - Execute tests
  - Fix problems (structure, coverage gaps, test failures)
  - Move to next file
  - When complete, run final full test suite

/validate-lua-tests-complete tests/lua/features/

  Same workflow, but scoped to tests/lua/features/ only.

/validate-lua-tests-complete tests/lua/test_raycaster.lua

  Validate a single file (structure, coverage, execute, verify).
  Useful for spot-checks or rework after a code change.
```

## Related Customizations
- **Narrow coverage check**: `/validate-lua-tests-raycaster` — coverage audit only for raycaster API
- **Adversarial probes only**: `/create-lua-adversarial-tests` — write sandbox escape, overflow, and type-confusion probes
- **Marker cleanup**: `/fix-lua-test-markers` — automatic per-file marker repair and indentation fix
