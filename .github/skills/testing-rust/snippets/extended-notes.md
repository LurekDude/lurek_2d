**Float rule:** `assert!((actual - expected).abs() < 1e-5)` — NEVER `assert_eq!` on `f32`/`f64`.

**Boundary conditions required:**
- Zero values
- Negative values
- Large values
- Empty collections
- Single-element collections

---

### 3. Adding a New Lua Test File
### 3.1 Create the Lua file

**Unit test** — tests one `lurek.*` module in isolation:

> See [../examples/3-1-create-the-lua-file.lua](../examples/3-1-create-the-lua-file.lua) for the example.

**Integration test** — crosses two modules (`tests/lua/integration/test_<a>_<b>.lua`):
> See [../examples/3-1-create-the-lua-file-2.lua](../examples/3-1-create-the-lua-file-2.lua) for the example.

**Stress test** (`tests/lua/stress/test_<name>_stress.lua`):
> See [../examples/3-1-create-the-lua-file-3.lua](../examples/3-1-create-the-lua-file-3.lua) for the example.

**Validation test** (`tests/lua/validation/test_<name>.lua`):
> See [../examples/3-1-create-the-lua-file-4.lua](../examples/3-1-create-the-lua-file-4.lua) for the example.

### 3.2 Harness Registration

Lua test files are **not** auto-discovered in this repository. After creating a new `.lua` file, add the matching `#[test]` entry to `tests/lua/harness.rs`.

Required pattern:
> See [../examples/3-2-harness-registration.rs](../examples/3-2-harness-registration.rs) for the example.

---

### 4. Lua BDD Framework API Reference
The framework is provided by `tests/lua/init.lua` and loaded automatically. Do not require/import it.

### Test structure
> See [../examples/test-structure.lua](../examples/test-structure.lua) for the example.

- `describe(name, fn)` — defines a test suite; errors in setup are caught and reported
- `it(name, fn)` — defines one test case; failure is recorded but execution continues
- `test_summary()` — prints pass/fail totals; must be the last call in every test file

### Lua test documentation standard

- Top-of-file comments are plain prose only. They explain what the file tests and any headless or evidence constraints.
- Do **not** use `-- @description` as a file-level banner.
- Keep the file header short. It is plain prose, not a docstring block.
- Every `describe()` block requires exactly one `-- @description <text>` line immediately above it.
- The `describe()` comment block owns only that `@description` line. Do not attach `@covers`, `@evidence`, `@golden`, or other markers to `describe()`.
- Every `it()` block requires exactly one `-- @description <text>` line immediately above it.
- Place ownership markers such as `@covers`, `@evidence`, `@golden`, and similar metadata on the `it()` block that actually asserts or produces the behavior.
- Use `-- @description <text>` without a colon. `-- @description:` is legacy and should be normalized.
- `-- @category: ...` markers are not part of the standard and must not be added.
- Nested `describe()` blocks are allowed when they express a real API grouping. Keep nesting shallow; prefer at most two levels.
- `test_summary()` must be the last non-empty line in the file. Never write `return test_summary()`.
- Audit and normalize with `python tools/audit/lua_test_structure_audit.py` and `python tools/audit/lua_test_structure_audit.py --fix`. The default audit now enforces the marker-ownership rule; use `--allow-legacy-describe-markers` only as a temporary escape hatch while repairing older files.

### Assertions

| Function | Use for |
|---|---|
| `expect_equal(expected, actual, msg)` | Strings, integers, booleans — exact match |
| `expect_not_equal(a, b, msg)` | Assert values differ |
| `expect_near(expected, actual, tol, msg)` | All floats; `tol` default `0.0001` |
| `expect_true(val, msg)` | Value is truthy (non-false, non-nil) |
| `expect_false(val, msg)` | Value is falsy |
| `expect_nil(val, msg)` | Value is nil |
| `expect_not_nil(val, msg)` | Value is not nil |
| `expect_type(type_str, val, msg)` | `type(val) == type_str` (e.g., `"table"`, `"function"`, `"number"`) |
| `expect_error(fn, msg)` | `fn()` must raise a Lua error |
| `expect_no_error(fn, msg)` | `fn()` must not raise a Lua error |
| `expect_greater(a, b, msg)` | Assert `a > b` |
| `expect_less(a, b, msg)` | Assert `a < b` |
| `expect_in_range(val, min, max, msg)` | Assert `min <= val <= max` |
| `expect_contains(tbl, value, msg)` | Assert `value` appears in table |
| `expect_match(str, pattern, msg)` | Assert Lua string pattern matches |
| `expect_length(tbl, n, msg)` | Assert `#tbl == n` |
| `expect_deep_equal(expected, actual, msg)` | Recursive table equality |

**Never use `assert()` directly** — it aborts the suite rather than recording a failure.

### Performance and Golden helpers

> See [../examples/performance-and-golden-helpers.lua](../examples/performance-and-golden-helpers.lua) for the example.

---

### 5. Headless VM — What Is / Is Not Available
`harness.rs` creates the VM via `create_test_vm()`, which is a full Lurek2D VM but **without a window, GPU, or audio device**. All `lurek.*` API tables are registered.

| Available in Lua tests | Not available |
|---|---|
| `lurek.math.*` | `lurek.render.draw*` (no GPU) |
| `lurek.physics.*` | `lurek.audio.newSource` (no audio device) |
| `lurek.timer.*` | Any API that calls `winit` window methods |
| `lurek.input.*` (state, no events) | `lurek.window.setSize` |
| `lurek.ecs.*` | Rendering commands |
| `lurek.data.*`, `lurek.save.*` | — |
| `lurek.tilemap.*`, `lurek.ai.*` | — |
| Built-in Lua: `math.*`, `string.*`, `table.*` | — |

**Important:** Use built-in `math.rad()` / `math.abs()` for pure math operations in tests — not `lurek.math.*` — to avoid introducing test dependencies on the math binding.

---

### 6. Test VM Helpers (Rust Side)
Both helpers are defined in `tests/lua/harness.rs` and reused across all Lua-dispatching test suites.

> See [../examples/6-test-vm-helpers-rust-side.rs](../examples/6-test-vm-helpers-rust-side.rs) for the example.

For Rust-only integration tests that need a Lua VM call a variant from the appropriate test file's own helpers (e.g., `make_audio_vm()` in `audio_tests.rs`).

---

### 7. Coverage and Quality Tools
### Running quality gates
> See [running-quality-gates.ps1](running-quality-gates.ps1) for the example.

### Analytics tools
> See [analytics-tools.ps1](analytics-tools.ps1) for the example.

### Adding missing docs
> See [adding-missing-docs.ps1](adding-missing-docs.ps1) for the example.

### What "covered" means
- **Rust module covered**: `tests/<module>_tests.rs` exists AND has ≥1 `#[test]` for every `pub fn`
- **Lua module covered**: `tests/lua/unit/test_<module>.lua` exists AND is registered in `harness.rs`
- **New API covered**: at least one test added in the same PR/commit that adds the API

---

### 8. Golden Tests
### Rust golden tests (byte-level)

Rust golden tests compare deterministic engine-internal output against a committed baseline file.

**Baseline files:** `tests/rust/golden/expected/<category>/<name>.<ext>`
**Runtime output:** `tests/rust/golden/actual/<category>/` (git-ignored)

Categories now focus on renderer/internal artifacts, for example `image/` and `raycaster/`.

**To add a new Rust golden test:**
1. Add expected file to `tests/rust/golden/expected/<category>/`
2. Add a `#[test]` in `tests/rust/golden/harness.rs` using `assert_golden("category/name.ext", ...)`
3. Run once to confirm match: `cargo test --test golden_tests`

**To update a baseline** (when intentional output change):
> See [rust-golden-tests-byte-level.ps1](rust-golden-tests-byte-level.ps1) for the example.

### Lua golden tests (compare-only files)

Lua golden tests compare an evidence file against a committed sample under `tests/lua/golden/`. They do **not** create content inline.

> See [../examples/lua-golden-tests-compare-only-files.lua](../examples/lua-golden-tests-compare-only-files.lua) for the example.

**Rules for Lua golden tests:**
- Golden files compare only; they must not call `lurek.*`, `savePNG`, `saveWAV`, or write files.
- The evidence artifact must already exist from an evidence test.
- Samples live in `tests/lua/golden/<module>/` or `tests/lua/golden/`.
- All Lua golden test files live in `tests/lua/golden/test_<module>_golden.lua`.
- Use `expect_golden_text_match()` or `expect_golden_file_match()` from `tests/lua/init.lua`.

---

### 9. Marker Annotations — `@covers`
Lua test files declare which API functions they verify using `-- @covers` markers. The coverage scanner (`tools/audit/lua_api_test_coverage.py`) reads these for accurate per-function tracking.

### Syntax

> See [../examples/syntax.lua](../examples/syntax.lua) for the example.

**Placement rules:**
- One `-- @covers` line per API function
- Place the block **before** the `describe` or `it` that tests the function
- Module functions: `-- @covers lurek.<module>.<function>`
- UserData methods: `-- @covers <ClassName>:<method>`
- The scanner regex: `^--\s*@covers\s+(lurek\.\w+\.\w+|\w+:\w+)\s*$`

**Describe-block naming as implicit coverage:**

Name every `describe()` block after the exact API function it tests. The scanner extracts these as secondary coverage Evidence:

> See [../examples/syntax-2.lua](../examples/syntax-2.lua) for the example.

**Running the scanner:**
> See [syntax-3.ps1](syntax-3.ps1) for the example.

---

### 10. Evidence-Based Testing
Some API functions can only be proven correct through observable side effects. Evidence testing provides three tiers.

### Tier 1 — Headless State Readback (preferred)

Query engine state after API calls. Works in the headless test VM without GPU or audio.

> See [../examples/tier-1-headless-state-readback-preferred.lua](../examples/tier-1-headless-state-readback-preferred.lua) for the example.

### Tier 2 — Canvas Pixel Readback (headless GPU simulation)

Draw to a Canvas and read pixels back. Proves rendering functions produce output.

> See [../examples/tier-2-canvas-pixel-readback-headless.lua](../examples/tier-2-canvas-pixel-readback-headless.lua) for the example.

### Tier 3 — Runtime Smoke Tests (GPU required)

Full rendering pipeline with screenshot. Lives in `tests/rust/ext/` only — not callable from headless Lua tests.

> See [../examples/tier-3-runtime-smoke-tests-gpu.rs](../examples/tier-3-runtime-smoke-tests-gpu.rs) for the example.

### Evidence Tags in Test Files

| Tag | Purpose |
|---|---|
| `-- @evidence pixel` | Test uses Canvas pixel readback for visual proof |
| `-- @evidence file` | Test writes an output file as evidence |
| `-- @evidence skip` | Operation requires GPU/audio; xit'd in headless mode; document skip reason inline |
| `-- @stress` | Test measures throughput performance |
| `-- @golden` | Test compares against a golden baseline |

### Evidence Artifact Contract (MANDATORY)

Every `it()` block in an `evidence/` file **MUST** satisfy all of the following:

1. **Produce at least one artifact.** Call `expect_evidence_created(path)` after writing the file. An `it()` that only calls `pending()` is a **contract violation** — the harness will count the test as failed.
2. **Use `evidence_output_dir("module")` for all paths.** Never hard-code `tests/output/`. Always call `ensure_evidence_dir("module")` in `before_each`.
3. **GPU-limited operations use `xit()` + a text artifact.** If an operation requires a live GPU context (canvas rendering, texture readback), mark the GPU rendering test as `xit()` (with `-- @evidence skip` and a comment explaining why). Still provide at least one headless test in the same file that writes a text/JSON artifact (e.g. API surface manifest via `io.open`).
4. **Placeholder evidence files are banned.** A file whose only content is `pending(...)` has no artifacts and must be replaced with a real implementation before merge. This applies to every `evidence/` layer file for every module.

### Evidence File Naming Contract

File naming follows **TST-06** strictly:

```
tests/lua/evidence/test_<module>_evidence.lua
```

- `<module>` is the **Rust source module name** (`src/<module>/`) — e.g. `math`, `physics`, `ui`, `image`.
- The layer suffix is always `_evidence` — never `_ev`, `_artifacts`, or a sub-feature name.
- One file per module. Sub-features (bezier, easing, noise, geometry) that are sub-modules of `src/math/` belong in `test_math_evidence.lua` OR have their own dedicated `test_<submodule>_evidence.lua` only if they are separately registered in `tests/lua/harness.rs` AND correspond to a distinct `src/<submodule>/` directory.
- No per-sub-feature splits within a module — merge into the single canonical file.

---

### 9. Checklist — New Test Before Merge
- [ ] Every new public `fn`/`struct` has at least one test
- [ ] New Rust test does not use `assert_eq!` on `f32`/`f64`
- [ ] New Lua test file ends with `test_summary()`
- [ ] New Lua test file is registered in `tests/lua/harness.rs`
- [ ] `cargo test` exits 0 locally
- [ ] `cargo clippy -- -D warnings` exits 0 locally
- [ ] No `#[ignore]` without a comment
- [ ] No disk I/O outside `tests/rust/golden/actual/` or a temp dir
- [ ] `#[should_panic]` includes `expected = "..."` with the expected panic substring
- [ ] No `std::thread::sleep` — use deterministic `clock.tick()` with fixed dt instead
- [ ] No network I/O of any kind
- [ ] Integration tests do not call private functions — use `pub(crate)` or `#[cfg(test)]` inline modules for test-only access
- [ ] Test is independently runnable — does not depend on execution order or shared mutable globals

---

### 10. API Coverage Markers (`-- @covers`)
When writing Lua tests, annotate which API functions are covered using `-- @covers` markers. This enables the coverage scanner to track per-function coverage accurately.

### Syntax

> See [../examples/syntax-4.lua](../examples/syntax-4.lua) for the example.

### Rules

- One `-- @covers` per line, placed **before** the `describe` or `it` block
- Prefer the closest block that actually owns the assertion rather than a broad file-global list.
- Module functions: `-- @covers lurek.<module>.<function>`
- UserData methods: `-- @covers <ClassName>:<method>`
- The scanner regex: `^--\s*@covers\s+((?:lurek\.\w+\.\w+)|(?:\w+:\w+))\s*$`
- Coverage without markers still works via heuristic fallback, but markers are preferred

### Coverage Scanner

> See [coverage-scanner.ps1](coverage-scanner.ps1) for the example.

---

### 11. Evidence-Based Testing Patterns
Some API functions cannot be verified by return values alone. Use these patterns to produce observable evidence:

### Canvas Pixel Readback (Headless)

> See [../examples/canvas-pixel-readback-headless.lua](../examples/canvas-pixel-readback-headless.lua) for the example.

### File Evidence

> See [../examples/file-evidence.lua](../examples/file-evidence.lua) for the example.

### Runtime Smoke Tests (GPU Required)

For tests requiring actual GPU rendering, use `tests/rust/ext/` with the smoke test infrastructure:
> See [../examples/runtime-smoke-tests-gpu-required.rs](../examples/runtime-smoke-tests-gpu-required.rs) for the example.

---

### 12. Golden Test Conventions
### Lua Golden Tests

Write golden tests in `tests/lua/golden/` for deterministic operations:

> See [../examples/lua-golden-tests.lua](../examples/lua-golden-tests.lua) for the example.

### Key Rules

- Use fixed seeds for any random/procedural operations
- Use `string.format("%.6f", val)` for float formatting
- Compare against committed sample files, not inline literals.
- If a Lua-facing contract can be expressed as an artifact, prefer Lua evidence + Lua golden.
- Keep Rust golden tests for engine-internal renderer/output checks that are not Lua API contracts.
- Run `python tools/audit/lua_evidence_golden_contract_audit.py` after evidence/golden edits.

### Stress Test Output Format

All stress tests should print `[PERF]` lines for parseable performance data:

> See [../examples/stress-test-output-format.lua](../examples/stress-test-output-format.lua) for the example.

---

### 13. Describe-Block Coverage Naming
Name every `describe()` block that targets a specific API function after that function. This enables the coverage scanner to extract per-method test counts without requiring explicit `-- @covers` annotations.

### Recognized Patterns

> See [../examples/recognized-patterns.lua](../examples/recognized-patterns.lua) for the example.

### Example: Well-Named Describe Blocks

> See [../examples/example-well-named-describe-blocks.lua](../examples/example-well-named-describe-blocks.lua) for the example.

### Coverage Score Per Method (0–4)

- +1 if ≥1 `it()` calls
- +1 if ≥3 `it()` calls
- +1 if any `it()` contains `expect_error` or `pcall`
- +1 if the describe block has a `-- @evidence` annotation

Use this system to prioritize which modules to improve: a module averaging <2/4 needs more error tests or evidence.

---

### 14. Integration Test Rules
Integration tests live in `tests/lua/integration/` and target two or more **named modules** in one scenario. Rules:

- Both module namespaces must appear in the file (`lurek.physics.*` AND `lurek.timer.*`, for example)
- Name the file `test_<module1>_<module2>[_<module3>].lua`
- Register a corresponding `#[test] fn lua_test_integration_<name>()` in harness.rs
- Three-way integrations (three modules) are high-value — prioritize those over simple two-way repeats
- Do not use this category for single-module lifecycle tests — those belong in `tests/lua/unit/`

Current volume target: **58+ integration tests** (Phase 1: 29 done; Phase 2: 29 planned).

---

### 15. Test Scope Decision Rules
Every public and private API in the Lurek2D engine has an assigned test scope. Follow these rules when deciding where a test belongs:

### Public API → Lua BDD Test

Any `pub fn` that is exposed through the `lurek.*` Lua namespace **must** have at least one Lua BDD test in `tests/lua/unit/test_<module>.lua`. This is the primary coverage layer for the engine API.

- Test the function via Lua calls, not by importing Rust types
- Use `describe` / `it` BDD structure with `@covers` markers
- All assertions use `expect_*` helpers — never raw `assert()`
- Every test file must end with `test_summary()`

### Private / Internal Rust → Rust `#[test]`

Private methods, `pub(crate)` helpers, and internal algorithms that have no `lurek.*` binding **must** be tested in Rust unit tests (`#[cfg(test)]` modules) or integration tests in `tests/rust/`.

- These are implementation details not reachable from Lua
- Use standard Rust `assert!` / `assert_eq!` patterns
- Float rule: `assert!((actual - expected).abs() < 1e-5)`

### Evidence Tests — File Output Required

Evidence test files (`tests/lua/evidence/`) prove that side-effect-producing APIs produce real, inspectable output on disk. Rules:

- **MUST save a file** — every evidence test MUST produce at least one actual file (PNG, audio, text, .obj, .json). An evidence test that does not write a file is **invalid**.
- The `it()` block passes if the file was created at the expected path without errors; fails if the write threw an error.
- **Never add value assertions** about the content — no `expect_equal`, no pixel checks, no format inspection. That is the golden test's job.
- Evidence tests are for human-in-the-loop review (open the PNGs, listen to the audio) and as source material for golden tests.
- Each evidence test writes to `tests/lua/evidence/output/<module>/` and the directory must exist before the test runs (create it at the top of the file or in a setup block).- **MUST use the module's `lurek.*` API** — The output content MUST be produced by calling the `lurek.*` module under test. An evidence test that draws shapes manually using only `setPixel` / `fill` / `drawRect` without exercising any meaningful domain module API is **invalid** and must be rewritten or deleted.
- **Litmus test (read before writing any evidence test):** "If the module's Lua API was removed, would the output PNG/file look different?" If NO — the test is invalid. It only tests `newImageData`, not the module.
- **Four mandatory steps:** (1) CREATE — instantiate the module object via `lurek.*` API; (2) CONFIGURE — call API methods to set module state; (3) EXECUTE — run the module to produce output (update loop, findPath, etc.); (4) DUMP — save what the module produced to a file. Steps 1–3 must touch the module being evidenced.
> See [../examples/evidence-tests-file-output-required.lua](../examples/evidence-tests-file-output-required.lua) for the example.

### Golden Tests — Compare Only

Golden test files (`tests/lua/golden/`) verify that deterministic evidence output matches a saved reference baseline.

**Golden Test Contract — MANDATORY:**
- A golden test is a **comparison harness only**. It must NEVER contain logic that creates content.
- **Never call `lurek.*` module API to produce new output** in a golden test — that belongs in the evidence test.
- **Never write new files** in a golden test — evidence tests do the writing; golden tests only compare.
- Every `it()` block in a golden test must call a comparison helper (`expect_files_equal`, `expect_png_near`, `expect_text_equal`, etc.) and nothing else.
- Reference sample files live in `tests/lua/golden/<module>/` — committed once, never changed except to intentionally update a baseline.
- **If a golden test contains content-creation code, move it** to the corresponding evidence test immediately.

Golden tests fail when output diverges from the baseline. They do NOT produce output themselves.

> See [../examples/golden-tests-compare-only.lua](../examples/golden-tests-compare-only.lua) for the example.

### `@covers` Markers — Required

Every Lua test file must declare its coverage at the top of the file using `-- @covers` markers:

> See [../examples/covers-markers-required.lua](../examples/covers-markers-required.lua) for the example.

These markers are consumed by `tools/audit/lua_api_test_coverage.py` and are mandatory for accurate coverage reporting.
