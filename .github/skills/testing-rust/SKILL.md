---
name: testing-rust
description: "Load this skill when writing or organizing tests for the Luna2D engine. It owns test patterns, float comparison strategies, test naming, and integration test architecture for both Rust and Lua BDD tests. Skip it for writing production code."
---

# Testing — Luna2D Engine

## Load When

- Writing new tests in `tests/` or `tests/lua/`
- Adding a Lua test registration entry to `tests/lua/harness.rs`
- Reviewing or improving test coverage for a module
- Fixing test failures or flaky tests
- Organizing or auditing test structure
- Running quality gates before a commit

## Owns

- Rust integration test patterns (`tests/<module>_tests.rs`)
- Lua BDD test patterns and framework API (`tests/lua/*/test_*.lua`)
- Harness registration (`tests/lua/harness.rs`)
- Float comparison strategy (Rust and Lua)
- Test naming conventions
- Coverage tools

## Does Not Cover

- Fixing production bugs found by tests → route to Developer
- Performance benchmarking → `performance-profiling` skill
- CI/CD pipeline setup → `ci-cd-pipeline` skill
- Lua API design → `lua-api-design` skill

---

## 1. Test Architecture Overview

Luna2D has a **two-layer test system** that runs entirely via `cargo test`:

| Layer | Location | Runner |
|---|---|---|
| Rust integration | `tests/<module>_tests.rs` | Cargo auto-discovery |
| Rust stress | `tests/stress/<name>_tests.rs` | `[[test]]` in `Cargo.toml` |
| Rust golden | `tests/golden_tests.rs` | Cargo auto-discovery |
| Lua BDD (unit) | `tests/lua/unit/test_<module>.lua` | `tests/lua/harness.rs` via `cargo test` |
| Lua BDD (integration) | `tests/lua/integration/test_<a>_<b>.lua` | `tests/lua/harness.rs` via `cargo test` |
| Lua BDD (stress) | `tests/lua/stress/test_<name>_stress.lua` | `tests/lua/harness.rs` via `cargo test` |
| Lua BDD (validation) | `tests/lua/validation/test_<name>.lua` | `tests/lua/harness.rs` via `cargo test` |

```
tests/
├── *.rs                      ← Rust integration tests (auto-discovered)
├── golden_tests.rs           ← golden binary comparison harness
├── stress/                   ← slow Rust benchmarks (Cargo.toml [[test]])
├── lua/
│   ├── init.lua              ← BDD framework (describe/it/expect_* globals)
│   ├── harness.rs            ← Rust dispatcher — 1 #[test] per Lua file
│   ├── unit/                 ← test_<module>.lua
│   ├── integration/          ← test_<a>_<b>.lua
│   ├── stress/               ← test_<name>_stress.lua
│   ├── validation/           ← test_<name>.lua
│   └── golden/               ← deterministic golden output tests
└── golden/
    ├── expected/             ← committed baseline artifacts
    └── actual/               ← runtime output (.gitignore-d)
```

---

## 2. Adding a New Rust Integration Test File

**Step 1 — Create the file** at `tests/<module>_tests.rs`. Cargo discovers all `tests/*.rs` automatically; no Cargo.toml entry needed.

**Step 2 — Skeleton:**
```rust
//! Integration tests for luna2d::<module>.

use luna2d::<module>::SomeType;

// ── Basic Construction ────────────────────────────────────────────────────────

#[test]
fn new_creates_default_state() {
    let t = SomeType::new();
    assert_eq!(t.count(), 0);
}

// ── Boundary Conditions ───────────────────────────────────────────────────────

#[test]
fn zero_input_returns_identity() {
    let result = SomeType::transform(0.0, 0.0);
    assert!((result - 0.0).abs() < 1e-5);
}
```

**Step 3 — Run:**
```powershell
cargo test --test <module>_tests
```

**Naming rules:**
- Function name: `<subject>_<scenario>_<expected>` — e.g., `body_zero_velocity_stays_still`
- No `test_` prefix — redundant; hurts `cargo test` output readability
- Section headers: `// ── Category ───────────...` for grouping

**Float rule:** `assert!((actual - expected).abs() < 1e-5)` — NEVER `assert_eq!` on `f32`/`f64`.

**Boundary conditions required:**
- Zero values
- Negative values
- Large values
- Empty collections
- Single-element collections

---

## 3. Adding a New Lua Test File

### 3.1 Create the Lua file

**Unit test** — tests one `luna.*` module in isolation:

```lua
-- tests/lua/unit/test_<module>.lua
-- Luna2D <Module> API Tests

describe("luna.<module> module exists", function()
    it("is a table", function()
        expect_type("table", luna.<module>)
    end)
end)

describe("luna.<module>.<function>", function()
    it("returns expected type", function()
        local result = luna.<module>.<function>(...)
        expect_not_nil(result)
        expect_type("number", result)
    end)

    it("numeric results match within tolerance", function()
        expect_near(3.14159, luna.<module>.pi, 0.0001)
    end)
end)

test_summary()  -- REQUIRED: must be last line in every Lua test file
```

**Integration test** — crosses two modules (`tests/lua/integration/test_<a>_<b>.lua`):
```lua
describe("<a> + <b> integration", function()
    it("uses <a> output as <b> input", function()
        local world_id = luna.physics.newWorld(0, 100)
        local body_id = luna.physics.newBody(world_id, 50, 50, "dynamic")
        local x, y = body_id:getPosition()
        expect_near(50, x, 0.1)
        luna.physics.destroyWorld(world_id)
    end)
end)
test_summary()
```

**Stress test** (`tests/lua/stress/test_<name>_stress.lua`):
```lua
describe("<name> stress", function()
    it("handles N iterations without error", function()
        for i = 1, 10000 do
            -- exercise the hot path
        end
        expect_true(true, "completed without error")
    end)
end)
test_summary()
```

**Validation test** (`tests/lua/validation/test_<name>.lua`):
```lua
describe("<name> contract", function()
    it("rejects invalid argument type", function()
        expect_error(function()
            luna.<module>.<fn>("not_a_number")
        end)
    end)
end)
test_summary()
```

### 3.2 Register in harness.rs

**Every Lua test file must have exactly one dispatcher entry** in `tests/lua/harness.rs`:

```rust
// Unit test
#[test]
fn lua_test_<module>() {
    run_lua_test("unit/test_<module>.lua");
}

// Integration test
#[test]
fn lua_integration_<a>_<b>() {
    run_lua_test("integration/test_<a>_<b>.lua");
}

// Stress test
#[test]
fn lua_stress_<name>() {
    run_lua_test("stress/test_<name>_stress.lua");
}

// Validation test
#[test]
fn lua_validation_<name>() {
    run_lua_test("validation/test_<name>.lua");
}
```

Place the entry in the corresponding section (look for `// === Unit Tests ===`, `// === Stress Tests ===`, etc.)

**Run a single Lua dispatcher:**
```powershell
cargo test lua_test_<module>
cargo test -- --nocapture   # show print() output from Lua tests
```

---

## 4. Lua BDD Framework API Reference

The framework is provided by `tests/lua/init.lua` and loaded automatically. Do not require/import it.

### Test structure
```lua
describe("suite name", function()
    it("description of one behaviour", function()
        -- assertions here
    end)
end)
test_summary()
```

- `describe(name, fn)` — defines a test suite; errors in setup are caught and reported
- `it(name, fn)` — defines one test case; failure is recorded but execution continues
- `test_summary()` — prints pass/fail totals; must be the last call in every test file

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

**Never use `assert()` directly** — it aborts the suite rather than recording a failure.

---

## 5. Headless VM — What Is / Is Not Available

`harness.rs` creates the VM via `create_test_vm()`, which is a full Luna2D VM but **without a window, GPU, or audio device**. All `luna.*` API tables are registered.

| Available in Lua tests | Not available |
|---|---|
| `luna.math.*` | `luna.graphics.draw*` (no GPU) |
| `luna.physics.*` | `luna.audio.newSource` (no audio device) |
| `luna.timer.*` | Any API that calls `winit` window methods |
| `luna.input.*` (state, no events) | `luna.window.setSize` |
| `luna.entity.*` | Rendering commands |
| `luna.data.*`, `luna.savegame.*` | — |
| `luna.tilemap.*`, `luna.ai.*` | — |
| Built-in Lua: `math.*`, `string.*`, `table.*` | — |

**Important:** Use built-in `math.rad()` / `math.abs()` for pure math operations in tests — not `luna.math.*` — to avoid introducing test dependencies on the math binding.

---

## 6. Test VM Helpers (Rust Side)

Both helpers are defined in `tests/lua/harness.rs` and reused across all Lua-dispatching test suites.

```rust
// Full VM with test framework loaded — use for Lua test files
fn create_test_vm() -> mlua::Lua { ... }

// Returns (Rc<RefCell<SharedState>>, Lua) for stateful Rust-side tests
fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) { ... }
```

For Rust-only integration tests that need a Lua VM call a variant from the appropriate test file's own helpers (e.g., `make_audio_vm()` in `audio_tests.rs`).

---

## 7. Coverage and Quality Tools

### Running quality gates
```powershell
cargo test                          # all tests — must exit 0
cargo test --test <module>_tests    # one Rust file
cargo test lua_test_<module>        # one Lua unit test dispatch
cargo clippy -- -D warnings         # lint — must exit 0
cargo fmt --check                   # format check
```

### Analytics tools
```powershell
python tools/test_coverage.py                  # coverage metrics → docs/API/test_coverage.json
python tools/integration_coverage.py           # Lua integration coverage map
python tools/collect_docs.py --report-missing  # undocumented public items (exit 1 if any)
python tools/quality_report.py                 # combined quality snapshot
```

### Adding missing docs
```powershell
python tools/collect_docs.py --suggest         # starter /// lines for undocumented items
```

### What "covered" means
- **Rust module covered**: `tests/<module>_tests.rs` exists AND has ≥1 `#[test]` for every `pub fn`
- **Lua module covered**: `tests/lua/unit/test_<module>.lua` exists AND is registered in `harness.rs`
- **New API covered**: at least one test added in the same PR/commit that adds the API

---

## 8. Golden Tests

Golden tests compare deterministic binary/text output against a committed baseline file.

**Baseline files:** `tests/golden/expected/<category>/<name>.<ext>`
**Runtime output:** `tests/golden/actual/<category>/` (git-ignored)

Categories: `encoding/`, `hashes/`, `compression/`, `images/`, `config/`, `sound/`

**To add a new golden test:**
1. Add expected file to `tests/golden/expected/<category>/`
2. Add a `#[test]` in `tests/golden_tests.rs` using `assert_golden("category/name.ext", ...)`
3. Run once to confirm match: `cargo test --test golden_tests`

**To update a baseline** (when intentional output change):
```powershell
cargo test --test golden_tests -- --nocapture
# copy tests/golden/actual/<file> to tests/golden/expected/<file>
```

---

## 9. Checklist — New Test Before Merge

- [ ] Every new public `fn`/`struct` has at least one test
- [ ] New Rust test does not use `assert_eq!` on `f32`/`f64`
- [ ] New Lua test file ends with `test_summary()`
- [ ] New Lua test file is registered in `tests/lua/harness.rs`
- [ ] `cargo test` exits 0 locally
- [ ] `cargo clippy -- -D warnings` exits 0 locally
- [ ] No `#[ignore]` without a comment
- [ ] No disk I/O outside `tests/golden/actual/` or a temp dir
