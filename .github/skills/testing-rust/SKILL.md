---
name: testing-rust
description: "Load this skill when writing or organizing tests for the Lurek2D engine. It owns test patterns, float comparison strategies, test naming, and integration test architecture for both Rust and Lua BDD tests. Skip it for writing production code."
---

# Testing — Lurek2D Engine

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

Lurek2D has a **two-layer test system** that runs entirely via `cargo test`:

| Layer | Location | Runner |
|---|---|---|
| Rust integration | `tests/<module>_tests.rs` | Cargo auto-discovery |
| Rust stress | `tests/rust/stress/<name>_tests.rs` | `[[test]]` in `Cargo.toml` |
| Rust golden | `tests/rust/golden/harness.rs` | Cargo auto-discovery |
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

**Unit test** — tests one `lurek.*` module in isolation:

```lua
-- tests/lua/unit/test_<module>.lua
-- Lurek2D <Module> API Tests

describe("lurek.<module> module exists", function()
    it("is a table", function()
        expect_type("table", lurek.<module>)
    end)
end)

describe("lurek.<module>.<function>", function()
    it("returns expected type", function()
        local result = lurek.<module>.<function>(...)
        expect_not_nil(result)
        expect_type("number", result)
    end)

    it("numeric results match within tolerance", function()
        expect_near(3.14159, lurek.<module>.pi, 0.0001)
    end)
end)

test_summary()  -- REQUIRED: must be last line in every Lua test file
```

**Integration test** — crosses two modules (`tests/lua/integration/test_<a>_<b>.lua`):
```lua
describe("<a> + <b> integration", function()
    it("uses <a> output as <b> input", function()
        local world_id = lurek.physics.newWorld(0, 100)
        local body_id = lurek.physics.newBody(world_id, 50, 50, "dynamic")
        local x, y = body_id:getPosition()
        expect_near(50, x, 0.1)
        lurek.physics.destroyWorld(world_id)
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
            lurek.<module>.<fn>("not_a_number")
        end)
    end)
end)
test_summary()
```

### 3.2 Auto-Registration

All Lua testing files (	est_*.lua) placed in 	ests/lua/ or its subdirectories are **automatically discovered and registered by uild.rs**.

You DO NOT need to edit 	ests/lua/harness.rs. Creating the .lua file is sufficient.

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
| `expect_greater(a, b, msg)` | Assert `a > b` |
| `expect_less(a, b, msg)` | Assert `a < b` |
| `expect_in_range(val, min, max, msg)` | Assert `min <= val <= max` |
| `expect_contains(tbl, value, msg)` | Assert `value` appears in table |
| `expect_match(str, pattern, msg)` | Assert Lua string pattern matches |
| `expect_length(tbl, n, msg)` | Assert `#tbl == n` |
| `expect_deep_equal(expected, actual, msg)` | Recursive table equality |

**Never use `assert()` directly** — it aborts the suite rather than recording a failure.

### Performance and Golden helpers

```lua
-- measure(name, count, fn) — wraps fn(), prints [PERF] line, returns elapsed, ops_per_sec
local elapsed, ops = measure("ecs_create", 10000, function()
    for i = 1, 10000 do lurek.ecs.newEntity() end
end)
expect_less(elapsed, 1.0, "10k ECS entity creates must finish under 1s")

-- expect_golden(name, data, expected) — deterministic inline comparison
expect_golden("path_result", lurek.pathfinding.findPath(...), "[(1,1),(2,1),(3,1)]")

-- expect_canvas_pixel(canvas, x, y, r, g, b, a, tolerance, msg)
-- Reads canvas:getPixel(x, y) and checks each RGBA channel within tolerance
local canvas = lurek.gfx.newCanvas(64, 64)
canvas:renderTo(function()
    lurek.gfx.setColor(1, 0, 0, 1)
    lurek.gfx.rectangle("fill", 0, 0, 64, 64)
end)
expect_canvas_pixel(canvas, 32, 32, 1.0, 0.0, 0.0, 1.0, 0.05, "center pixel must be red")
```

---

## 5. Headless VM — What Is / Is Not Available

`harness.rs` creates the VM via `create_test_vm()`, which is a full Lurek2D VM but **without a window, GPU, or audio device**. All `lurek.*` API tables are registered.

| Available in Lua tests | Not available |
|---|---|
| `lurek.math.*` | `lurek.gfx.draw*` (no GPU) |
| `lurek.physics.*` | `lurek.audio.newSource` (no audio device) |
| `lurek.time.*` | Any API that calls `winit` window methods |
| `lurek.input.*` (state, no events) | `lurek.window.setSize` |
| `lurek.ecs.*` | Rendering commands |
| `lurek.data.*`, `lurek.savegame.*` | — |
| `lurek.tilemap.*`, `lurek.ai.*` | — |
| Built-in Lua: `math.*`, `string.*`, `table.*` | — |

**Important:** Use built-in `math.rad()` / `math.abs()` for pure math operations in tests — not `lurek.math.*` — to avoid introducing test dependencies on the math binding.

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
python tools/audit/test_coverage.py                  # coverage metrics → docs/logs/test_coverage.json
python tools/audit/integration_coverage.py           # Lua integration coverage map
python tools/docs/collect_docs.py --report-missing  # undocumented public items (exit 1 if any)
python tools/audit/quality_report.py                 # combined quality snapshot
python tools/audit/lua_api_test_coverage.py          # per-function API coverage (marker + heuristic)
python tools/audit/test_analytics.py --worst 10     # 10 lowest-scoring modules (planned)
```

### Adding missing docs
```powershell
python tools/docs/collect_docs.py --suggest         # starter /// lines for undocumented items
```

### What "covered" means
- **Rust module covered**: `tests/<module>_tests.rs` exists AND has ≥1 `#[test]` for every `pub fn`
- **Lua module covered**: `tests/lua/unit/test_<module>.lua` exists AND is registered in `harness.rs`
- **New API covered**: at least one test added in the same PR/commit that adds the API

---

## 8. Golden Tests

### Rust golden tests (byte-level)

Golden tests compare deterministic binary/text output against a committed baseline file.

**Baseline files:** `tests/rust/golden/expected/<category>/<name>.<ext>`
**Runtime output:** `tests/rust/golden/actual/<category>/` (git-ignored)

Categories: `encoding/`, `hashes/`, `compression/`, `images/`, `config/`, `sound/`

**To add a new Rust golden test:**
1. Add expected file to `tests/rust/golden/expected/<category>/`
2. Add a `#[test]` in `tests/rust/golden/harness.rs` using `assert_golden("category/name.ext", ...)`
3. Run once to confirm match: `cargo test --test golden_tests`

**To update a baseline** (when intentional output change):
```powershell
cargo test --test golden_tests -- --nocapture
# copy tests/rust/golden/actual/<file> to tests/rust/golden/expected/<file>
```

### Lua golden tests (inline expected string)

Lua golden tests use the `expect_golden(name, data, expected)` helper from `init.lua`. The expected value is an **inline string** — no external file dependency, no git-ignored output directory.

```lua
-- tests/lua/golden/test_pathfinding_golden.lua
-- Golden tests for lurek.pathfinding — seeded results must be deterministic

describe("pathfinding golden", function()
    it("A* on fixed 5x5 grid produces exact path", function()
        local grid = lurek.pathfinding.newGrid(5, 5)
        local path = lurek.pathfinding.findPath(grid, 0, 0, 4, 4)
        expect_golden("astar_5x5", path, "[(0,0),(1,1),(2,2),(3,3),(4,4)]")
    end)
end)

test_summary()
```

**Rules for Lua golden tests:**
- The expected string must be deterministic — use seeded RNG, fixed input, or pure math
- Format values with fixed precision: `string.format("%.4f", val)` not `tostring(val)`
- Use LuaJIT-safe formatting — avoid `%g` which may differ between Lua versions
- If output is a table, format it with a canonical serializer, not `tostring(tbl)`
- All Lua golden test files live in `tests/lua/golden/test_<module>_golden.lua`

---

## 9. Marker Annotations — `@covers`

Lua test files declare which API functions they verify using `-- @covers` markers. The coverage scanner (`tools/audit/lua_api_test_coverage.py`) reads these for accurate per-function tracking.

### Syntax

```lua
-- @covers lurek.physics.newWorld
-- @covers lurek.physics.newBody
-- @covers Body:applyForce
describe("lurek.physics world creation", function()
    it("creates a world with gravity", function()
        local world = lurek.physics.newWorld(0, 980)
        expect_not_nil(world)
    end)
end)
```

**Placement rules:**
- One `-- @covers` line per API function
- Place the block **before** the `describe` or `it` that tests the function
- Module functions: `-- @covers lurek.<module>.<function>`
- UserData methods: `-- @covers <ClassName>:<method>`
- The scanner regex: `^--\s*@covers\s+(lurek\.\w+\.\w+|\w+:\w+)\s*$`

**Describe-block naming as implicit coverage:**

Name every `describe()` block after the exact API function it tests. The scanner extracts these as secondary coverage Evidence:

```lua
describe("lurek.audio.newBus", function()  -- module function
    it("creates bus with given name", ...)
    it("rejects empty name", ...)           -- error path earns a bonus score point
end)

describe("AudioBus:setVolume", function()  -- UserData method
    it("stores volume", ...)
    it("clamps to [0,1]", ...)
end)
```

**Running the scanner:**
```powershell
python tools/audit/lua_api_test_coverage.py                # per-module coverage bars
python tools/audit/lua_api_test_coverage.py --json         # JSON output
python tools/audit/lua_api_test_coverage.py --markdown     # Markdown report
python tools/audit/lua_api_test_coverage.py --suggest      # suggest missing markers
python tools/audit/lua_api_test_coverage.py --strict --threshold 40  # exit 1 if below 40%
```

---

## 10. Evidence-Based Testing

Some API functions can only be proven correct through observable side effects. Evidence testing provides three tiers.

### Tier 1 — Headless State Readback (preferred)

Query engine state after API calls. Works in the headless test VM without GPU or audio.

```lua
describe("Body:applyForce", function()
    it("changes velocity after step", function()
        local world = lurek.physics.newWorld(0, 0)  -- no gravity
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:applyForce(100, 0)
        lurek.physics.step(world, 1.0 / 60)
        local vx, vy = body:getLinearVelocity()
        expect_greater(vx, 0, "force must produce positive x velocity")
    end)
end)
```

### Tier 2 — Canvas Pixel Readback (headless GPU simulation)

Draw to a Canvas and read pixels back. Proves rendering functions produce output.

```lua
-- @covers lurek.gfx.rectangle
-- @evidence pixel
describe("lurek.gfx.rectangle", function()
    it("fills rectangle region with current color", function()
        local canvas = lurek.gfx.newCanvas(64, 64)
        canvas:renderTo(function()
            lurek.gfx.setColor(1, 0, 0, 1)
            lurek.gfx.rectangle("fill", 0, 0, 64, 64)
        end)
        expect_canvas_pixel(canvas, 32, 32, 1.0, 0.0, 0.0, 1.0, 0.05,
            "center pixel must be red after filled rectangle")
    end)
end)
```

### Tier 3 — Runtime Smoke Tests (GPU required)

Full rendering pipeline with screenshot. Lives in `tests/rust/ext/` only — not callable from headless Lua tests.

```rust
// tests/rust/ext/graphics_runtime_smoke_tests.rs
#[test]
fn rectangle_render_smoke() {
    // Launch game process, render one frame, save screenshot, compare pixel
}
```

### Evidence Tags in Test Files

| Tag | Purpose |
|---|---|
| `-- @evidence pixel` | Test uses Canvas pixel readback for visual proof |
| `-- @evidence file` | Test writes an output file as evidence |
| `-- @stress` | Test measures throughput performance |
| `-- @golden` | Test compares against a golden baseline |

---

## 9. Checklist — New Test Before Merge

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

## 10. API Coverage Markers (`-- @covers`)

When writing Lua tests, annotate which API functions are covered using `-- @covers` markers. This enables the coverage scanner to track per-function coverage accurately.

### Syntax

```lua
-- @covers lurek.physics.newWorld
-- @covers lurek.physics.newBody
describe("lurek.physics world creation", function()
    it("creates a world", function()
        local world = lurek.physics.newWorld(0, 980)
        expect_not_nil(world)
    end)
end)

-- @covers Body:getPosition
-- @covers Body:applyForce
describe("Body methods", function()
    it("gets position after force", function()
        -- ...
    end)
end)
```

### Rules

- One `-- @covers` per line, placed **before** the `describe` or `it` block
- Module functions: `-- @covers lurek.<module>.<function>`
- UserData methods: `-- @covers <ClassName>:<method>`
- The scanner regex: `^--\s*@covers\s+((?:lurek\.\w+\.\w+)|(?:\w+:\w+))\s*$`
- Coverage without markers still works via heuristic fallback, but markers are preferred

### Coverage Scanner

```powershell
python tools/audit/lua_api_test_coverage.py              # summary with per-module bars
python tools/audit/lua_api_test_coverage.py --json        # JSON output
python tools/audit/lua_api_test_coverage.py --markdown    # markdown report
python tools/audit/lua_api_test_coverage.py --suggest     # show uncovered functions
python tools/audit/lua_api_test_coverage.py --strict --threshold 40  # CI gate
```

---

## 11. Evidence-Based Testing Patterns

Some API functions cannot be verified by return values alone. Use these patterns to produce observable evidence:

### Canvas Pixel Readback (Headless)

```lua
-- Verify drawing actually produces pixels
local canvas = lurek.gfx.newCanvas(100, 100)
canvas:renderTo(function()
    lurek.gfx.setColor(1, 0, 0, 1)
    lurek.gfx.rectangle("fill", 0, 0, 100, 100)
end)
local r, g, b, a = canvas:getPixel(50, 50)
expect_near(1.0, r, 0.01)  -- proves rectangle was drawn
```

### File Evidence

```lua
-- Verify file I/O by writing and reading back
lurek.filesystem.write("test_output.txt", "hello")
local content = lurek.filesystem.read("test_output.txt")
expect_equal("hello", content)
```

### Runtime Smoke Tests (GPU Required)

For tests requiring actual GPU rendering, use `tests/rust/ext/` with the smoke test infrastructure:
```rust
// tests/rust/ext/light_smoke_tests.rs
#[test]
fn light_illumination_visible() {
    // Launch example with --smoke flag
    // Capture screenshot via lurek.gfx.saveScreenshot()
    // Verify pixel values in the saved PNG
}
```

---

## 12. Golden Test Conventions

### Lua Golden Tests

Write golden tests in `tests/lua/golden/` for deterministic operations:

```lua
-- tests/lua/golden/test_data_golden.lua
describe("JSON round-trip golden", function()
    it("encodes table to expected JSON string", function()
        local data = { name = "test", value = 42 }
        local json = lurek.data.encode(data, "json")
        local expected = '{"name":"test","value":42}'
        expect_equal(expected, json)
    end)
end)
test_summary()
```

### Key Rules

- Use fixed seeds for any random/procedural operations
- Use `string.format("%.6f", val)` for float formatting
- Compare inline expected data (not external files) for Lua golden tests
- For binary golden tests, use the Rust golden harness in `tests/rust/golden/`
- The two-track golden approach: (a) Lua headless state golden (draw-list contents, bone positions, config snapshots) and (b) Rust pixel golden (PNG byte comparison in `tests/rust/golden/expected/image/`)

### Stress Test Output Format

All stress tests should print `[PERF]` lines for parseable performance data:

```lua
print(string.format("[PERF] %s: %d ops in %.3fs (%.0f ops/sec)",
    name, count, elapsed, count / elapsed))
```

---

## 13. Describe-Block Coverage Naming

Name every `describe()` block that targets a specific API function after that function. This enables the coverage scanner to extract per-method test counts without requiring explicit `-- @covers` annotations.

### Recognized Patterns

```lua
describe("lurek.<module>.<function>", function()  -- module-level function
    ...
end)

describe("<ClassName>:<method>", function()        -- UserData method
    ...
end)

describe("lurek.<module> error handling", function() -- module-scoped group
    ...
end)
```

### Example: Well-Named Describe Blocks

```lua
describe("lurek.audio.newBus", function()     -- scanner recognizes pattern
    it("creates bus with given name", ...)
    it("bus is retrievable by name", ...)
    it("rejects empty name", function()
        expect_error(function() lurek.audio.newBus("") end)
    end)
    it("rejects duplicate name", ...)
end)

describe("AudioBus:setVolume", function()     -- UserData method pattern
    it("stores value correctly", ...)
    it("clamps to [0,1]", ...)
end)
```

### Coverage Score Per Method (0–4)

- +1 if ≥1 `it()` calls
- +1 if ≥3 `it()` calls
- +1 if any `it()` contains `expect_error` or `pcall`
- +1 if the describe block has a `-- @evidence` annotation

Use this system to prioritize which modules to improve: a module averaging <2/4 needs more error tests or evidence.

---

## 14. Integration Test Rules

Integration tests live in `tests/lua/integration/` and target two or more **named modules** in one scenario. Rules:

- Both module namespaces must appear in the file (`lurek.physics.*` AND `lurek.timer.*`, for example)
- Name the file `test_<module1>_<module2>[_<module3>].lua`
- Register a corresponding `#[test] fn lua_test_integration_<name>()` in harness.rs
- Three-way integrations (three modules) are high-value — prioritize those over simple two-way repeats
- Do not use this category for single-module lifecycle tests — those belong in `tests/lua/unit/`

Current volume target: **58+ integration tests** (Phase 1: 29 done; Phase 2: 29 planned).

---

## 15. Test Scope Decision Rules

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

### Evidence Tests — Content Only

Evidence test files (`tests/lua/evidence/`) prove that side-effect-producing APIs actually produce output. Rules:

- **Create content only** — call the API, produce the side effect (file, screenshot, audio output)
- **Never add assertions** about the content itself — that is the golden test's job
- Think of evidence tests as "does it run without error and produce something?"

```lua
-- CORRECT: evidence test creates content
it("drawCircle produces a canvas with non-zero pixels", function()
    local canvas = lurek.gfx.newCanvas(64, 64)
    canvas:renderTo(function()
        lurek.gfx.circle("fill", 32, 32, 16)
    end)
    -- evidence: canvas was created and renderTo ran without error
end)
```

### Golden Tests — Compare Only

Golden test files (`tests/lua/golden/`) verify that deterministic output matches an expected baseline. Rules:

- **Compare content only** — read or receive the output and compare against expected
- **Never create or produce** the content in the golden test itself — that is the evidence test's job
- Golden tests assert that output hasn't regressed, not that output can be produced

```lua
-- CORRECT: golden test compares already-produced content
it("JSON encoding matches baseline", function()
    local data = { name = "test", value = 42 }
    local json = lurek.data.encode(data, "json")
    expect_equal('{"name":"test","value":42}', json)
end)
```

### `@covers` Markers — Required

Every Lua test file must declare its coverage at the top of the file using `-- @covers` markers:

```lua
-- @covers lurek.physics.newWorld
-- @covers lurek.physics.newBody
-- @covers lurek.physics.step
```

These markers are consumed by `tools/audit/lua_api_test_coverage.py` and are mandatory for accurate coverage reporting.
