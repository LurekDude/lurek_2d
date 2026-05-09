# Lurek2D — Test Framework Architecture

Source of truth for the test suite structure, placement rules, BDD framework, golden tests, and CI quality gates.

Companion documents: [engine-architecture.md](engine-architecture.md) · [philosophy.md](philosophy.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Test Placement Rules](#test-placement-rules)
3. [Two-Layer Test Model](#two-layer-test-model)
4. [Directory Layout](#directory-layout)
5. [Rust Test Suites](#rust-test-suites)
6. [Lua BDD Test Framework](#lua-bdd-test-framework)
7. [Lua Test Documentation Standard](#lua-test-documentation-standard)
8. [Golden Tests](#golden-tests)
9. [Naming Conventions](#naming-conventions)
10. [Float Comparison Rules](#float-comparison-rules)
11. [Running Tests](#running-tests)
12. [Quality Gates](#quality-gates)
13. [Test Coverage Tooling](#test-coverage-tooling)
14. [Evidence-Based Testing](#evidence-based-testing)
15. [Demo Tests](#demo-tests)

---

## Overview

Lurek2D uses a **two-layer test system** executed through `cargo test`:

1. **Rust tests** — compiled test binaries exercising engine modules directly via crate imports (unit, stress, golden, config, security, ext).
2. **Lua BDD tests** — `.lua` scripts using `describe`/`it`/`expect_*` framework, dispatched by a Rust harness (unit, library, integration, stress, security, golden, config, demos).

Both layers run **headless** — no window, no GPU, no audio device required. This enables CI/CD and parallel execution without display servers.

**Examples vs Demos:**

| | `content/examples/` | `content/games/` |
|---|---|---|
| Purpose | Documentation — shows one `lurek.*` API in isolation | Fully functional game showcases |
| Tested? | No — read-only reference scripts | Yes — every demo must have a test |
| Format | Single-file, commented | Folder with `main.lua` + optional `conf.toml` |

---

## Test Placement Rules

Constraints **TST-01** through **TST-06** from [philosophy.md § Testing Constraints](philosophy.md#testing-constraints) are binding. Summary:

| ID | Rule |
|----|------|
| **TST-01** | Lua-first. Behaviour reachable via `lurek.*` must be tested in Lua. Rust tests must not duplicate `lurek.*`-reachable coverage. |
| **TST-02** | Rust unit tests live in `tests/rust/unit/<module>_tests.rs`. Inline `#[cfg(test)]` blocks in `src/**/*.rs` are **banned**. |
| **TST-03** | `src/lua_api/<module>_api.rs` holds only `impl LuaUserData`, registration, and type conversions. No business logic. |
| **TST-04** | Every `mod.rs` holds only `pub mod`, `pub use`, attributes, and doc comments. No definitions. |
| **TST-05** | Demo tests: headless Lua tests in `tests/lua/demos/test_<name>.lua`; screenshot tests in `tests/demo_smoke_tests.rs` with `#[ignore]`. Never put demo tests in `tests/lua/unit/`. |
| **TST-06** | One file per module per layer. No split per-sub-feature files. Name: `test_<module>_<layer>.lua`. |

> **Migration note (2026-04-20).** Existing inline `#[cfg(test)]` blocks are tracked for relocation under session `testing-cleanup-20260420`. No new inline blocks are accepted.

### Decision Tree

1. **Reachable via any `lurek.*` function, userdata, or callback?** → Lua test in `tests/lua/unit/test_<module>.lua` (single module) or `tests/lua/integration/test_<a>_<b>.lua` (≥2 namespaces). This is TST-01 — the default path.

2. **Private internal helper** — no Lua exposure? → Rust unit test in `tests/rust/unit/<module>_tests.rs`. Register binary in `Cargo.toml`. TST-02.

3. **Test for a game demo in `content/games/`?** → Headless Lua test in `tests/lua/demos/test_<name>.lua` (TST-05) + `#[ignore]` screenshot test in `tests/demo_smoke_tests.rs`.

4. **Anything else** (integration, golden, stress, evidence, config, security) → choose the matching subfolder in `tests/rust/` or `tests/lua/`.

When both 1 and 2 apply, choose 1 (Lua-first). Promote private helpers to `pub(crate)` and cover through the Lua surface.

### Banned Patterns

| Pattern | Constraint | Fix |
|---------|------------|-----|
| `#[cfg(test)] mod tests` inside any `src/**/*.rs` | TST-02 | Relocate to `tests/rust/unit/<module>_tests.rs` |
| Business logic in `src/lua_api/*_api.rs` | TST-03 | Move logic to `src/<module>/`, call from thin wrapper |
| `fn`, `struct`, `enum`, or `impl` in any `mod.rs` | TST-04 | Move to sibling file; keep `mod.rs` as re-export switchboard |
| Duplicating `lurek.*`-reachable test in Rust | TST-01 | Delete Rust duplicate, keep Lua test |
| Demo tests in `tests/lua/unit/` | TST-05 | Move to `tests/lua/demos/` |
| Split per-sub-feature test files | TST-06 | Merge into single canonical `test_<module>_<layer>.lua` |

### Enforcement — Audit Scripts

Under `tools/audit/`:

| Script | Enforces |
|--------|----------|
| `inline_test_audit.py` | TST-02 — lists every inline `#[cfg(test)]` block with relocation target |
| `thin_wrapper_audit.py` | TST-03 — flags business-logic violations inside `src/lua_api/` |
| `thin_modrs_audit.py` | TST-04 — flags disallowed definitions inside any `mod.rs` |
| `test_coverage.py` | TST-01 — reports undercovered `lurek.*` surface |
| `lua_test_structure_audit.py` | BDD documentation standard |
| `lua_evidence_golden_contract_audit.py` | Evidence/golden separation |

### Harness Registration

Lua tests are registered **manually** in `tests/lua/harness.rs`. Auto-discovery is intentionally not used. An unregistered `.lua` file will never be executed by `cargo test`.

---

## Two-Layer Test Model

```
cargo test
  │
  ├── Rust test binaries ─────────────────────────────────────────
  │   tests/rust/unit/          Engine module Rust contracts
  │   tests/rust/stress/        Throughput + allocation tests
  │   tests/rust/golden/        Snapshot: graphics/audio/text
  │   tests/rust/config/        Config loading + validation
  │   tests/rust/security/      Sandbox audit, path traversal
  │   tests/rust/ext/           Cross-module Rust smoke tests
  │
  └── Lua BDD harness ────────────────────────────────────────────
      tests/lua/harness.rs
      ├── unit/         One file per engine module (API surface)
      ├── library/      One file per Lunasome library
      ├── integration/  Tests between ≥2 modules
      ├── stress/       Throughput + allocation from Lua
      ├── security/     Sandboxing + input validation
      ├── golden/       Deterministic output comparison
      ├── config/       Configuration loading tests
      └── demos/        One file per demo in content/games/
```

**Why two layers:**
- Rust tests cover internal engine contracts: struct invariants, error handling, resource lifecycle, mathematical correctness.
- Lua tests cover the public `lurek.*` API surface from the user's perspective — the same VM game scripts use.
- Library tests (`tests/lua/library/`) exclusively test Lunasome pure-Lua libraries.

---

## Directory Layout

```
tests/
├── fixtures/            Shared test assets (images, audio, data files)
├── output/              Evidence artefact output (git-ignored)
├── samples/             Golden comparison baselines (committed)
│
├── rust/
│   ├── unit/            One file per engine module (Rust contracts)
│   │   ├── math_tests.rs
│   │   ├── physics_tests.rs
│   │   ├── render_tests.rs
│   │   └── ...
│   ├── stress/          Raw Rust-level throughput tests
│   ├── golden/          Snapshot tests (harness.rs + expected/)
│   ├── config/          TOML config loading + validation
│   ├── security/        Sandbox + path-traversal audits
│   └── ext/             Cross-module Rust smoke tests
│
└── lua/
    ├── harness.rs       Rust harness — one #[test] per .lua file
    ├── init.lua         BDD framework (describe/it/expect_*)
    ├── unit/            One file per lurek.* namespace
    ├── library/         One file per Lunasome library
    ├── integration/     Tests between ≥2 modules
    ├── stress/          Throughput + allocation from Lua
    ├── security/        Sandboxing + input validation
    ├── golden/          Deterministic output comparison
    ├── config/          Config loading tests
    └── demos/           One file per content/games/ demo
        ├── _common_checks.lua
        └── test_<name>.lua
```

All Rust test binaries are **explicitly registered** in `Cargo.toml` under `[[test]]` sections. Unregistered `.rs` files in `tests/` are not discovered by `cargo test`.

### tests/rust/game/ — Retired

`tests/rust/game/` previously held Rust tests for game systems (battle, cardgame, combat, crafting, inventory, quest, stats). Those systems are now pure-Lua libraries in `library/`. Their tests live in `tests/lua/library/`. Do not add new files there.

---

## Rust Test Suites

**Scope rule:** All public API methods must be tested in Lua. Rust tests cover private/internal code only — struct invariants, internal algorithms, resource lifecycle, and implementation details with no `lurek.*` surface.

| Category | Path | Scope |
|---|---|---|
| Integration | `tests/rust/unit/` | Internal Rust types + private methods not exposed to Lua |
| Stress | `tests/rust/stress/` | Raw Rust-level throughput (no Lua boundary) |
| Golden | `tests/rust/golden/` | Byte-level snapshot comparison |
| Config | `tests/rust/config/` | TOML loading + validation |
| Security | `tests/rust/security/` | Sandbox audit, path-traversal guards |
| Ext | `tests/rust/ext/` | Cross-module Rust smoke tests |

**Test naming convention:** `<module>_<what>_<expected_behaviour>()`. Example: `vec2_add_returns_component_wise_sum`.

---

## Lua BDD Test Framework

All Lua tests use the custom BDD framework in `tests/lua/init.lua`, loaded automatically by `create_test_vm()`.

### Categories

| Category | Path | Scope | Naming |
|---|---|---|---|
| Unit | `tests/lua/unit/` | One module per file | `test_<module>.lua` |
| Library | `tests/lua/library/` | One Lunasome library | `test_library_<name>.lua` |
| Integration | `tests/lua/integration/` | ≥2 modules | `test_<modA>_<modB>.lua` |
| Stress | `tests/lua/stress/` | Throughput + allocation | `test_<module>_stress.lua` |
| Security | `tests/lua/security/` | Sandboxing + input validation | — |
| Golden | `tests/lua/golden/` | Deterministic output | `test_<module>_golden.lua` |
| Config | `tests/lua/config/` | Configuration loading | — |
| Demos | `tests/lua/demos/` | One per `content/games/` demo | `test_<name>.lua` |

### Framework Functions

| Function | Purpose |
|---|---|
| `describe(name, fn)` | Group tests under a named section |
| `it(name, fn)` | Define a single test case |
| `before_each(fn)` / `after_each(fn)` | Hooks around each `it()` |
| `expect_equal(expected, actual, msg)` | Strict equality (string, int, bool) |
| `expect_near(expected, actual, tol, msg)` | Float proximity; `tol` defaults to `1e-5` |
| `expect_true(val, msg)` / `expect_false(val, msg)` | Truthy/falsy |
| `expect_nil(val, msg)` / `expect_not_nil(val, msg)` | Nil checks |
| `expect_type(type_str, val, msg)` | `type(val) == type_str` |
| `expect_error(fn, msg)` | Assert fn raises a Lua error |
| `expect_no_error(fn, msg)` | Assert fn does not raise |
| `expect_greater(a, b, msg)` / `expect_less(a, b, msg)` | Numeric comparisons |
| `expect_in_range(val, min, max, msg)` | Bounds check |
| `expect_contains(tbl, value, msg)` | Table membership |
| `expect_match(str, pattern, msg)` | Lua string pattern match |
| `expect_length(tbl, n, msg)` | `#tbl == n` |
| `expect_deep_equal(expected, actual, msg)` | Recursive table equality |
| `measure(name, count, fn)` | Run fn, print `[PERF]` line, return `elapsed, ops_per_sec` |
| `expect_canvas_pixel(surface, x, y, r, g, b, a, tol, msg)` | Pixel RGBA check |
| `test_summary()` | **Mandatory** — must be the last call in every file |

### Integration Test Rule

An integration test must exercise at least two distinct `lurek.*` module namespaces. Testing one module with complex data does not qualify.

---

## Lua Test Documentation Standard

Three comment layers — do not mix them:

1. **File header** — plain `-- ...` prose at top. Explains coverage and headless constraints. No `@description`.
2. **Suite description** — one `-- @describe <text>` line immediately above each `describe()` block.
3. **Case description** — optional plain comment lines above each `it()` block when needed for clarity.

**Rules:**
- File header uses plain comments only — no `-- @description`, no `-- @category:`.
- `-- @category: ...` markers are forbidden everywhere.
- `test_summary()` must be the last non-empty line in every file.
- `return test_summary()` is forbidden — use bare `test_summary()`.
- Marker annotations belong on `it()` blocks and are folder-specific:
    - `tests/lua/unit/` -> `@covers`
    - `tests/lua/security/` -> `@security`
    - `tests/lua/integration/` -> `@integration`
    - `tests/lua/stress/` -> `@stress`
    - `tests/lua/evidence/` -> `@evidence`
- Max two levels of nested `describe()`.

**Standard template:**

```lua
-- tests/lua/unit/test_modulename.lua
-- Exercises lurek.modulename constructors, error handling, and edge cases.
-- Headless-safe: no window, GPU, or audio required.

-- @describe Groups namespace-level checks for lurek.modulename.
describe("lurek.modulename", function()
    -- @describe Covers constructor behavior and default object state.
    describe("new()", function()
        -- @covers lurek.modulename.new
        -- Verifies new() returns a userdata object.
        it("returns a userdata object", function()
            local value = lurek.modulename.new()
            expect_not_nil(value)
        end)
    end)
end)

test_summary()
```

**Audit:**
```powershell
python tools/audit/lua_test_structure_audit.py
python tools/audit/lua_test_structure_audit.py --fix
```

---

## Golden Tests

Golden tests compare evidence output against committed baseline samples.

**Rules:**
1. **Golden tests ONLY compare.** They read an evidence file and a golden sample, then assert they match. No content creation.
2. **Evidence tests must run first.** If the evidence file does not exist, the golden test fails with a clear message.
3. **Golden samples live in `tests/lua/golden/samples/<module>/`** — committed to git, human-reviewed.
4. **Golden tests must not call `lurek.*` APIs, `savePNG`, `saveWAV`, or write files.** Content creation belongs in the evidence layer.
5. **Every golden test uses BDD structure** and the `-- @golden` marker.
6. Use `expect_golden_file_match()` for binary (PNG, WAV) or `expect_golden_text_match()` for text (normalises whitespace/line endings).

**Directory structure:**
```
tests/lua/golden/
├── test_<module>_golden.lua          Golden test script
└── samples/                          Committed baseline files
    ├── math/constants.txt
    ├── physics/draw_debug.png
    └── audio/sine_440hz.wav

tests/lua/evidence/output/            Generated at test run (git-ignored)
└── math/constants.txt
```

**Golden test template:**
```lua
-- @golden
-- @covers lurek.<module>.<function>

describe("golden: <module> <description>", function()
    it("matches golden sample for <artifact>", function()
        local evidence = evidence_output_dir("<module>") .. "<filename>"
        local golden = "tests/lua/golden/samples/<module>/<filename>"
        expect_golden_file_match(evidence, golden)
    end)
end)

test_summary()
```

---

## Naming Conventions

| Context | Pattern | Example |
|---------|---------|---------|
| Rust test function | `<module>_<what>_<expected>` | `vec2_add_returns_component_wise_sum` |
| Rust test binary | `<module>_tests` | `math_tests` |
| Lua unit file | `test_<module>.lua` | `test_math.lua` |
| Lua library file | `test_library_<name>.lua` | `test_library_combat.lua` |
| Lua integration file | `test_<modA>_<modB>.lua` | `test_physics_timer.lua` |
| Lua demo file | `test_<name>.lua` | `test_globe_demo.lua` |
| Lua golden file | `test_<module>_golden.lua` | `test_physics_golden.lua` |

---

## Float Comparison Rules

Never use `==` for floats. Use:

| Need | Function | Default tolerance |
|------|----------|------------------|
| Lua test | `expect_near(expected, actual, tol)` | `1e-5` |
| Rust test | `assert!((a - b).abs() < 1e-5)` | 1e-5 |
| Physics positions | `1e-3` tolerance | — |
| Render coordinates | `0.5` tolerance (half pixel) | — |

---

## Running Tests

```powershell
# All tests
cargo test

# Single Rust binary
cargo test --test math_tests

# Single Lua test
cargo test --test lua_tests test_math

# All demo screenshot tests (needs GPU + pre-built binary)
cargo test --test demo_smoke_tests -- --include-ignored

# Parallel runner (CI)
python tools/dev/parallel_cargo.py test rust
python tools/dev/parallel_cargo.py test lua
```

---

## Quality Gates

Both gates must pass before every merge:

| Gate | Command |
|------|---------|
| All tests pass | `cargo test` |
| No clippy warnings | `cargo clippy -- -D warnings` |
| No undocumented public items | `python tools/docs/collect_docs.py --report-missing` |
| (CAG changes) | `python tools/validate/cag_validate.py` |

---

## Test Coverage Tooling

| Tool | Purpose |
|------|---------|
| `tools/audit/test_coverage.py` | Reports undercovered `lurek.*` surface (TST-01) |
| `tools/audit/inline_test_audit.py` | Lists `#[cfg(test)]` in src/ (TST-02) |
| `tools/audit/thin_wrapper_audit.py` | Flags business logic in `lua_api/` (TST-03) |
| `tools/audit/thin_modrs_audit.py` | Flags definitions in `mod.rs` (TST-04) |
| `tools/audit/lua_test_structure_audit.py` | BDD documentation standard |
| `tools/audit/lua_evidence_golden_contract_audit.py` | Evidence/golden separation |

---

## Evidence-Based Testing

Evidence tests produce **artefacts** (images, text files, audio) from actual engine output. They are in `tests/lua/evidence/` and write to `tests/lua/evidence/output/` (git-ignored). Golden tests then compare those artefacts against committed samples in `tests/lua/golden/samples/`.

**Two-step pattern:**
1. Evidence test runs, calls `lurek.*`, saves output to `output/<module>/`.
2. Golden test reads saved output and committed sample, asserts they match.

Never mix steps — an `it()` block must do either production or comparison, never both.

---

## Demo Tests

### Headless Demo Tests (`tests/lua/demos/`)

Every folder in `content/games/` must have exactly one `test_<name>.lua` in `tests/lua/demos/`. Each test:
- Loads the demo's `main.lua` via `dofile()` or static analysis
- Verifies the demo initialises without error
- Runs at least one frame cycle headlessly
- Does NOT require GPU, audio, or window

### Screenshot Smoke Tests (`tests/demo_smoke_tests.rs`)

All functions in this file are `#[ignore]`. They spawn the real `lurek2d` binary with `--screenshot=<path> --screenshot-frames=180` and assert the output PNG is valid (exists, > 2 KiB, PNG magic bytes `\x89PNG`). Require a pre-built binary and real display.

```powershell
# Run one demo screenshot test
cargo test --test demo_smoke_tests demo_smoke_globe_demo -- --include-ignored
```

| Concern | Lua demo test | Screenshot test |
|---------|--------------|----------------|
| Runs headless? | Yes | No — needs GPU |
| Runs in CI by default? | Yes | No (`#[ignore]`) |
| Catches wrong callback names? | Yes (static analysis) | No |
| Catches crash at frame 180? | No | Yes |
| Verifies rendered output? | No | Yes (PNG magic + size) |
