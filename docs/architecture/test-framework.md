# Lurek2D — Test Framework Architecture

> **Source of truth** for the test suite structure, naming conventions, BDD framework, and CI quality gates.
> Companion documents: [engine-architecture.md](engine-architecture.md) (runtime module structure) · [philosophy.md](philosophy.md) (principles + design assumptions).

---

## Table of Contents

1. [Overview](#overview)
2. [Two-Layer Test Model](#two-layer-test-model)
3. [Directory Layout](#directory-layout)
4. [Rust Test Suites](#rust-test-suites)
5. [Lua BDD Test Framework](#lua-bdd-test-framework)
6. [Golden Tests](#golden-tests)
7. [VM Helpers](#vm-helpers)
8. [Naming Conventions](#naming-conventions)
9. [Float Comparison Rules](#float-comparison-rules)
10. [Test Constraints](#test-constraints)
11. [Adding a New Rust Test](#adding-a-new-rust-test)
12. [Adding a New Lua Test](#adding-a-new-lua-test)
13. [Running Tests](#running-tests)
14. [Quality Gates](#quality-gates)
15. [Test Coverage Tooling](#test-coverage-tooling)
16. [Test-Driven Development Workflow](#test-driven-development-workflow)
17. [Problem Areas and Known Issues](#problem-areas-and-known-issues)

---

## Overview

Lurek2D uses a **two-layer test system** executed entirely through `cargo test`:

1. **Rust tests** — compiled Rust test binaries that exercise engine modules directly via crate imports (unit, stress, golden, config, security, ext).
2. **Lua BDD tests** — `.lua` scripts using a custom `describe`/`it`/`expect_*` framework, dispatched by a Rust harness (unit, library, integration, stress, security, golden, config, demos).

Both layers run headless — no window, no GPU, no audio device required. This enables CI/CD and parallel execution without display servers.

### Examples vs Demos

| | `content/examples/` | `content/demos/` |
|---|---|---|
| Purpose | Documentation — shows one `lurek.*` API in isolation | Fully functional game showcases |
| Testable? | **No** — these are read-only reference scripts | **Yes** — every demo must have a test |
| Format | Single-file, heavily commented | Folder with `main.lua` and optional `conf.lua` |

Examples are not tested. They exist to document API usage and are not expected to execute in a test harness. **Demos must all pass CI** — each demo has exactly one test file in `tests/lua/content/demos/`.

---

## Two-Layer Test Model

```
cargo test
  │
  ├── Rust Test Binaries ─────────────────────────────────────────┐
  │   ├── tests/rust/unit/          Engine module Rust contracts   │
  │   ├── tests/rust/stress/        Throughput + allocation tests  │
  │   ├── tests/rust/golden/        Snapshot: graphics/audio/text  │
  │   ├── tests/rust/config/        Config loading + validation    │
  │   ├── tests/rust/security/      Sandbox audit, path traversal  │
  │   └── tests/rust/ext/           Cross-module Rust smoke tests  │
  │                                                                │
  ├── Golden Harness ──────────────────────────────────────────────┤
  │   └── tests/rust/golden/harness.rs                             │
  │       └── compares actual output against golden/expected/      │
  │                                                                │
  └── Lua BDD Harness ─────────────────────────────────────────────┘
      └── tests/lua/harness.rs
          ├── unit/           One file per engine module (API surface)
          ├── content/library/        One file per Lunasome library
          ├── integration/    Tests BETWEEN two or more modules
          ├── stress/         Throughput + allocation Lua tests
          ├── security/       Lua sandboxing + input validation
          ├── golden/         Deterministic output comparison
          ├── config/         Configuration loading tests
          └── content/demos/          One file per demo in content/demos/
```

### Why Two Layers?

- **Rust tests** cover internal engine contracts: struct invariants, error handling, resource lifecycle, mathematical correctness. Direct crate access allows testing private-via-crate internals.
- **Lua tests** cover the public `lurek.*` API surface: function signatures, return types, error messages, and end-to-end workflows. They run in the same VM game scripts use, catching API regressions from the user's perspective.
- **Library tests** (`tests/lua/content/library/`) exclusively test Tier 3 Lunasome pure-Lua libraries. These were formerly tested via `tests/rust/game/` which is now retired — game systems (battle, cardgame, combat, crafting, inventory, quest, stats) live in `content/library/` not in the engine.

---

## Directory Layout

```
tests/
├── fixtures/                        Shared test assets (images, audio, data files)
│
├── rust/                            Rust test binaries (all registered in Cargo.toml)
│   ├── unit/                        One file per engine module — Rust struct invariants
│   │   ├── math_tests.rs
│   │   ├── graphics_tests.rs
│   │   ├── audio_tests.rs
│   │   ├── physics_tests.rs
│   │   ├── input_tests.rs
│   │   ├── timer_tests.rs
│   │   ├── filesystem_tests.rs
│   │   ├── compute_tests.rs
│   │   ├── data_tests.rs
│   │   ├── image_tests.rs
│   │   ├── sound_tests.rs
│   │   ├── event_tests.rs
│   │   ├── entity_tests.rs
│   │   ├── window_tests.rs
│   │   ├── thread_tests.rs
│   │   ├── animation_tests.rs
│   │   ├── camera_tests.rs
│   │   ├── particle_tests.rs
│   │   ├── tilemap_tests.rs
│   │   ├── scene_tests.rs
│   │   ├── savegame_tests.rs
│   │   ├── modding_tests.rs
│   │   ├── graph_tests.rs
│   │   ├── pathfinding_tests.rs
│   │   ├── ai_tests.rs
│   │   ├── terminal_tests.rs
│   │   └── ...
│   │
│   ├── stress/                      Throughput + allocation pressure — Rust level
│   │   ├── compute_stress_tests.rs  e.g. 10K parallel tasks
│   │   ├── data_stress_tests.rs     e.g. 1M JSON parse cycles
│   │   ├── image_stress_tests.rs    e.g. batch decode + encode
│   │   └── physics_stress_tests.rs  e.g. 10K rigid body world
│   │
│   ├── golden/                      Snapshot tests — committed expected files
│   │   ├── harness.rs               Rust harness dispatching golden tests
│   │   ├── expected/                Expected output files (committed to git)
│   │   │   ├── image/               Expected PNG snapshots (graphics golden)
│   │   │   ├── audio/               Expected waveform data (audio golden)
│   │   │   ├── text/                Expected rendered text (text processing golden)
│   │   │   ├── hash/                Expected hash digests
│   │   │   ├── encode/              Expected encoded strings
│   │   │   ├── compress/            Expected compressed bytes
│   │   │   └── data/                Expected binary data
│   │   └── actual/                  Generated during test run (git-ignored)
│   │
│   ├── config/                      Config loading + validation tests
│   │   └── config_tests.rs
│   │
│   ├── security/                    Sandbox + path-traversal audits
│   │   └── security_tests.rs
│   │
│   └── ext/                         Cross-module Rust smoke tests
│       ├── graphics_ext_tests.rs
│       ├── math_ext_tests.rs
│       └── graphics_runtime_smoke_tests.rs
│
└── lua/                             Lua BDD tests
    ├── harness.rs                   Rust harness — one #[test] per .lua file
    ├── init.lua                     BDD framework (describe/it/expect_*)
    │
    ├── unit/                        One file per engine module (lurek.* API surface)
    │   ├── test_math.lua
    │   ├── test_graphics.lua
    │   ├── test_audio.lua
    │   ├── test_physics.lua
    │   ├── test_input.lua
    │   ├── test_timer.lua
    │   ├── test_filesystem.lua
    │   ├── test_data.lua
    │   ├── test_image.lua
    │   ├── test_sound.lua
    │   ├── test_event.lua
    │   ├── test_particle.lua
    │   ├── test_scene.lua
    │   ├── test_tilemap.lua
    │   ├── test_pathfinding.lua
    │   ├── test_ai.lua
    │   ├── test_terminal.lua
    │   └── ...
    │
    ├── content/library/                     One file per Lunasome library in content/library/
    │   ├── test_library_battle.lua
    │   ├── test_library_cardgame.lua
    │   ├── test_library_combat.lua
    │   ├── test_library_crafting.lua
    │   ├── test_library_dialog.lua
    │   ├── test_library_doll.lua
    │   ├── test_library_economy.lua
    │   ├── test_library_inventory.lua
    │   ├── test_library_item.lua
    │   ├── test_library_province_map.lua
    │   ├── test_library_quest.lua
    │   └── test_library_stats.lua
    │
    ├── integration/                 Tests BETWEEN modules A + B (or A + B + C)
    │   │   Rule: every test here must exercise ≥2 distinct lurek.* namespaces.
    │   │   Name format: test_<moduleA>_<moduleB>.lua
    │   ├── test_ai_physics.lua
    │   ├── test_entity_ai.lua
    │   ├── test_math_graphics.lua
    │   ├── test_math_physics.lua
    │   ├── test_physics_timer.lua
    │   ├── test_save_entity.lua
    │   ├── test_tilemap_physics.lua
    │   └── ...
    │
    ├── stress/                      Throughput + security from Lua perspective
    │   ├── test_physics_stress.lua
    │   ├── test_math_stress.lua
    │   ├── test_entity_stress.lua
    │   ├── test_particle_stress.lua
    │   └── ...
    │
    ├── security/                    Lua sandbox + input validation tests
    │   ├── test_invalid_args.lua    nil spam, wrong types at API boundary
    │   ├── test_mount_traversal.lua path-traversal attempts via GameFS
    │   ├── test_savegame_validation.lua
    │   └── test_toml_validation.lua
    │
    ├── golden/                      Deterministic output Lua tests
    │   └── test_math_golden.lua
    │
    ├── config/                      Configuration loading tests
    │   └── test_config.lua
    │
    └── content/demos/                       One test file per demo in content/demos/
        │   Rule: every demo in content/demos/ must have a corresponding file here.
        │   Name format: test_demo_<name>.lua
        ├── test_demo_hello_world.lua
        ├── test_demo_physics_demo.lua
        ├── test_demo_sprites.lua
        └── ...
```

### Cargo.toml Registration

All Rust test binaries are **explicitly registered** in `Cargo.toml` under `[[test]]` sections. An unregistered `.rs` file in `tests/` will not be discovered by `cargo test`.

```toml
[[test]]
name = "math_tests"
path = "tests/rust/unit/math_tests.rs"

[[test]]
name = "golden_tests"
path = "tests/rust/golden/harness.rs"

[[test]]
name = "lua_tests"
path = "tests/lua/harness.rs"
```

### tests/rust/game/ — Retired

`tests/rust/game/` previously held Rust tests for game systems (battle, cardgame, combat, crafting, inventory, quest, stats). Those systems are now **pure-Lua libraries** in `content/library/`. Their tests live in `tests/lua/content/library/`. Do not add new files to `tests/rust/game/`.

---

## Rust Test Suites

### Suite Categories

| Category | Path | Scope | Example |
|---|---|---|---|
| **Unit** | `tests/rust/unit/` | One engine module, Rust-side invariants | `math_tests.rs`: Vec2 arithmetic |
| **Stress** | `tests/rust/stress/` | Throughput and allocation pressure | `physics_stress_tests.rs`: 10K body world |
| **Golden** | `tests/rust/golden/` | Snapshot comparison: graphics, audio, text | Compare PNG byte-for-byte |
| **Config** | `tests/rust/config/` | Config loading + validation | `config_tests.rs`: TOML parsing |
| **Security** | `tests/rust/security/` | Sandbox audit, path-traversal guards | `security_tests.rs`: GameFS escapes |
| **Ext** | `tests/rust/ext/` | Cross-module Rust smoke tests | `graphics_ext_tests.rs`: mesh + texture |

> **Note**: `tests/rust/game/` is retired. Game systems (battle, cardgame, combat, crafting, inventory, quest, stats) are now pure-Lua libraries tested in `tests/lua/content/library/`.

### Test Structure Pattern

```rust
// tests/unit/math_tests.rs

use luna2d::math::{Vec2, Mat3, Rect, Color};
use luna2d::math::noise::Noise;
use luna2d::math::random::RandomGenerator;

// ============================================================
// Vec2 Tests
// ============================================================

#[test]
fn vec2_add_returns_component_wise_sum() {
    let a = Vec2::new(1.0, 2.0);
    let b = Vec2::new(3.0, 4.0);
    let result = a + b;
    assert!((result.x - 4.0).abs() < 1e-5);
    assert!((result.y - 6.0).abs() < 1e-5);
}

#[test]
fn vec2_length_of_unit_vector_is_one() {
    let v = Vec2::new(1.0, 0.0);
    assert!((v.length() - 1.0).abs() < 1e-5);
}

// ============================================================
// Color Tests
// ============================================================

#[test]
fn color_new_clamps_to_0_1() {
    let c = Color::new(2.0, -1.0, 0.5, 1.0);
    assert!((c.r - 1.0).abs() < 1e-5);
    assert!((c.g - 0.0).abs() < 1e-5);
}
```

---

## Lua BDD Test Framework

All Lua tests use a custom BDD framework defined in `tests/lua/init.lua`. This framework is loaded automatically by `create_test_vm()`.

### Lua Test Categories

| Category | Path | Scope | Rule |
|---|---|---|---|
| **Unit** | `tests/lua/unit/` | One engine module per file (API surface) | One `.lua` per `lurek.*` namespace |
| **Library** | `tests/lua/content/library/` | One Lunasome library per file | One `.lua` per `content/library/<name>` |
| **Integration** | `tests/lua/integration/` | Tests between ≥2 modules | Name: `test_<moduleA>_<moduleB>.lua` |
| **Stress** | `tests/lua/stress/` | Throughput + allocation from Lua | High iteration counts, timing checks |
| **Security** | `tests/lua/security/` | Sandboxing + input validation | Nil spam, path traversal, bad types |
| **Golden** | `tests/lua/golden/` | Deterministic output comparison | Compare against saved reference data |
| **Config** | `tests/lua/config/` | Configuration loading | TOML keys, defaults, missing fields |
| **Demos** | `tests/lua/content/demos/` | One file per demo in `content/demos/` | Name: `test_demo_<name>.lua` |

### Framework API

| Function | Purpose |
|---|---|
| `describe(name, fn)` | Group related tests under a named section |
| `it(name, fn)` | Define a single test case |
| `expect_equal(expected, actual)` | Assert strict equality |
| `expect_near(expected, actual, tolerance)` | Assert float proximity |
| `expect_type(value, type_name)` | Assert Lua type (`"number"`, `"table"`, etc.) |
| `expect_error(fn)` | Assert fn throws an error |
| `expect_not_nil(value)` | Assert value is not nil |
| `expect_true(value)` | Assert truthy |
| `expect_false(value)` | Assert falsy |
| `expect_gt(a, b)` | Assert `a > b` |
| `expect_lt(a, b)` | Assert `a < b` |
| `expect_gte(a, b)` | Assert `a >= b` |
| `expect_lte(a, b)` | Assert `a <= b` |
| `expect_contains(table, value)` | Assert value in table |
| `expect_match(string, pattern)` | Assert Lua pattern match |
| `test_summary()` | **MANDATORY** — must be the last call in every file |

### Lua Test File Template

```lua
-- tests/lua/unit/test_modulename.lua
-- Tests for lurek.modulename API

describe("lurek.modulename", function()
    describe("someFunction", function()
        it("should return expected result", function()
            local result = lurek.modulename.someFunction(42)
            expect_equal(84, result)
        end)

        it("should handle edge cases", function()
            expect_error(function()
                lurek.modulename.someFunction(nil)
            end)
        end)
    end)

    describe("anotherFunction", function()
        it("should accept default params", function()
            local val = lurek.modulename.anotherFunction()
            expect_not_nil(val)
            expect_type(val, "number")
        end)
    end)
end)

test_summary()
```

### Library Test Template

Library tests live in `tests/lua/content/library/` and use `require()` to load from `content/library/`.

```lua
-- tests/lua/content/library/test_library_combat.lua
-- Tests for the Lunasome combat library

local combat = require("content/library/combat")

describe("combat library", function()
    describe("resolve_attack", function()
        it("should deal damage within expected range", function()
            local result = combat.resolve_attack({ damage = 10 }, { defense = 2 })
            expect_gt(result.damage_dealt, 0)
            expect_lte(result.damage_dealt, 10)
        end)
    end)
end)

test_summary()
```

### Integration Test Rule

An integration test **must** exercise at least two distinct `lurek.*` module namespaces (or one engine module + one library). Testing a single module with complex data does **not** qualify as integration.

```lua
-- tests/lua/integration/test_physics_timer.lua
-- Integration: lurek.physics + lurek.time (two distinct namespaces)

describe("physics + timer integration", function()
    it("should simulate body movement over elapsed time", function()
        -- uses lurek.physics AND lurek.time
    end)
end)

test_summary()
```

### Demo Test Rule

Every folder in `content/demos/` must have exactly one corresponding `test_demo_<name>.lua` in `tests/lua/content/demos/`. The demo test:
- Loads the demo's `main.lua` via `dofile` or `require`
- Verifies that the demo initialises without error
- Runs at least one frame cycle (load + update step)
- Does NOT require GPU, audio, or window

```lua
-- tests/lua/content/demos/test_demo_hello_world.lua
-- Smoke test for content/demos/hello_world

describe("hello_world demo", function()
    it("should load without error", function()
        expect_not_nil(luna)
        -- load callback runs cleanly
        dofile("content/demos/hello_world/main.lua")
    end)
end)

test_summary()
```

### Harness Dispatch

The Lua harness (`tests/lua/harness.rs`) maps each `#[test]` function to a `.lua` file:

```rust
// tests/lua/harness.rs
use luna2d::lua_api::create_test_vm;

fn run_lua_test(path: &str) {
    let vm = create_test_vm();
    // Load init.lua (BDD framework)
    // Execute test file
    // Check _test_results global for failures
    // Assert all tests passed
}

#[test]
fn lua_test_math() { run_lua_test("unit/test_math.lua"); }

#[test]
fn lua_test_library_combat() { run_lua_test("content/library/test_library_combat.lua"); }

#[test]
fn lua_test_integration_physics_timer() { run_lua_test("integration/test_physics_timer.lua"); }

#[test]
fn lua_test_demo_hello_world() { run_lua_test("content/demos/test_demo_hello_world.lua"); }

// ... one entry per Lua test file
```

---

## Golden Tests

Golden tests verify deterministic output by comparing actual results against committed expected files. The Rust golden harness covers graphics, audio, and text processing at the byte level.

### Structure

```
tests/rust/golden/
├── harness.rs                 Rust harness
├── expected/                  Committed reference files
│   ├── image/                 Expected PNG snapshots (graphics golden)
│   ├── audio/                 Expected waveform data (audio golden)
│   ├── text/                  Expected rendered text bitmaps (text processing)
│   ├── hash/                  Expected hash digests
│   ├── encode/                Expected encoded strings
│   ├── compress/              Expected compressed bytes
│   └── data/                  Expected binary data
└── actual/                    Generated during test run (git-ignored)
```

### Flow

1. Test generates output (PNG, waveform bytes, rendered text, hash)
2. Output saved to `tests/rust/golden/actual/`
3. Compared byte-for-byte against `tests/rust/golden/expected/`
4. Pass if identical; fail with diff report if different

### Updating Golden Files

When output intentionally changes (e.g., algorithm improvement or font update), manually copy `actual/` to `expected/` and commit. Always review diffs before committing updated golden files — a silent diff here means a rendering regression was silently accepted.

### Priority Domains for Golden Coverage

| Domain | What to snapshot |
|---|---|
| Graphics | Rasterised shapes, sprite compositing, draw-layer ordering |
| Audio | Rendered waveform bytes from rodio mixer |
| Text | Fontdue glyph rasterisation, layout bounding boxes |

---

## VM Helpers

Two Rust-side helpers create test Lua VMs:

### `create_test_vm()`

Returns a fully-initialized Lua VM with:
- BDD framework (`init.lua`) loaded
- `_test_results` global table ready
- All `lurek.*` API modules registered
- **Headless**: no window, GPU, or audio device

Used by: Lua BDD harness.

### `make_vm()`

Returns `(Rc<RefCell<SharedState>>, Lua)` — a SharedState + Lua VM pair for stateful Rust-side tests that need to:
- Inspect SharedState after Lua calls
- Pre-populate resources before running Lua
- Test resource lifecycle through the Lua boundary

---

## Naming Conventions

### Rust Tests

- **No `test_` prefix** on `#[test]` functions (Rust already knows they are tests).
- Format: `<subject>_<scenario>_<expected_outcome>`
- Section separators: `// ============================================================`

```rust
// GOOD
#[test] fn vec2_normalize_returns_unit_length() { }
#[test] fn world_step_applies_gravity() { }
#[test] fn color_from_hex_parses_6_digit() { }

// BAD
#[test] fn test_vec2_normalize() { }       // has test_ prefix
#[test] fn test1() { }                       // meaningless name
```

### Lua Tests

- File naming: `test_<module>.lua`
- `describe()` blocks named after the API namespace: `"lurek.math"`, `"lurek.gfx"`
- `it()` blocks use natural language: `"should return zero for empty input"`

---

## Float Comparison Rules

**NEVER use `assert_eq!` on `f32` or `f64` values.** Floating-point arithmetic produces representation errors.

### Rust

```rust
// CORRECT
assert!((result - expected).abs() < 1e-5);

// ALSO CORRECT — helper macro
macro_rules! assert_float_eq {
    ($a:expr, $b:expr) => {
        assert!(($a - $b).abs() < 1e-5, "Expected {} ≈ {}", $a, $b);
    };
}

// WRONG — will fail with representation errors
assert_eq!(result, expected);
```

### Lua

```lua
-- CORRECT
expect_near(expected, actual, 0.001)

-- WRONG
expect_equal(1.0, some_float_calc())
```

Default tolerance for `expect_near` is `1e-5` if the third argument is omitted.

---

## Test Constraints

These constraints are **mandatory** and enforced by CI:

| Constraint | Rationale |
|---|---|
| Tests must NOT create a window | CI runners have no display server |
| Tests must NOT use the GPU | CI runners may lack GPU devices |
| Tests must NOT play audio | CI runners may lack audio devices |
| Tests must NOT write outside `build/` | Prevent pollution of working tree |
| Tests must NOT use network I/O | Tests must be reproducible offline |
| New `lurek.*` API functions require ≥1 Lua test | Prevent untested API surface growth |
| Bug fixes require a regression test first | Red → green → refactor cycle |
| Every Lua test file ends with `test_summary()` | Framework validation gate |

---

## Adding a New Rust Test

### For an existing module

Add `#[test]` functions to the existing `tests/rust/unit/<module>_tests.rs` file.

### For a new module

1. Create `tests/rust/unit/<module>_tests.rs`
2. Register it in `Cargo.toml`:
   ```toml
   [[test]]
   name = "<module>_tests"
   path = "tests/rust/unit/<module>_tests.rs"
   ```
3. Add imports: `use luna2d::<module>::TypeName;`
4. Write tests following the naming convention
5. Run: `cargo test --test <module>_tests`

---

## Adding a New Lua Test

Choose the correct category:

| You are testing... | Category | Path |
|---|---|---|
| A `lurek.*` engine API function | **unit** | `tests/lua/unit/test_<module>.lua` |
| A Lunasome library in `content/library/` | **library** | `tests/lua/content/library/test_library_<name>.lua` |
| Interaction between ≥2 modules | **integration** | `tests/lua/integration/test_<a>_<b>.lua` |
| High-load / many iterations | **stress** | `tests/lua/stress/test_<topic>_stress.lua` |
| Nil spam / bad inputs / sandbox | **security** | `tests/lua/security/test_<topic>.lua` |
| Config file loading | **config** | `tests/lua/config/test_config.lua` |
| A demo in `content/demos/` | **demos** | `tests/lua/content/demos/test_demo_<name>.lua` |

Steps for all categories:
1. Create the `.lua` file in the correct subdirectory using the template
2. End the file with `test_summary()`
3. Add a dispatch entry in `tests/lua/harness.rs`:
   ```rust
   #[test]
   fn lua_test_<category>_<name>() { run_lua_test("<category>/test_<name>.lua"); }
   ```
4. Run: `cargo test lua_test_<category>_<name>`

---

## Running Tests

### During Development (scoped — fast)

```powershell
# Type-check only — no compilation, ~2-5s incremental
cargo check

# Test one Rust module
cargo test --test math_tests -- --nocapture

# Test one Lua module
cargo test lua_test_math -- --nocapture

# Lint library only
cargo clippy --lib
```

### Final Gate (full — before commit)

```powershell
cargo test && cargo clippy -- -D warnings
```

### Diagnostic Commands

| What | Command |
|---|---|
| Type-check only | `cargo check` |
| One Rust test suite | `cargo test --test <name>` |
| One Lua test suite | `cargo test lua_test_<module>` |
| See stdout from tests | `cargo test --test <name> -- --nocapture` |
| Debug logging in tests | `$env:RUST_LOG = "debug"; cargo test --test <name> -- --nocapture` |
| Lint library only | `cargo clippy --lib` |
| All tests | `cargo test` |
| Pretty format | `cargo test -- --format pretty` |

**Key rule**: Never run `cargo test` (full) during development. Use scoped `--test <name>` commands. Full suite runs only at commit time.

---

## Quality Gates

Every commit must pass all of these:

| Gate | Command | Must Exit |
|---|---|---|
| All tests pass | `cargo test` | 0 |
| No clippy warnings | `cargo clippy -- -D warnings` | 0 |
| Format check | `cargo fmt --check` | 0 |
| Doc coverage | `python tools/collect_docs.py --report-missing` | 0 |

---

## Test Coverage Tooling

| Tool | Purpose | Output |
|---|---|---|
| `python tools/test_coverage.py` | Test coverage analytics | `docs/logs/test_coverage.json` |
| `python tools/test_coverage.py --suggest` | Generate stubs for uncovered items | stdout |
| `python tools/module_audit.py` | Full module audit (includes test status) | stdout |
| `python tools/audit_module.py <name>` | Single module quality audit | PASS/WARN/ERROR |

---

## Test-Driven Development Workflow

### Rust (Red → Green → Refactor)

1. **Red**: Write a failing test in `tests/rust/unit/<module>_tests.rs` that names the expected behaviour
2. **Run**: `cargo test --test <module>_tests` — confirm it fails with the expected error
3. **Green**: Implement the minimum code in `src/<module>/` to make it pass
4. **Refactor**: Clean up, keeping tests green
5. **Gate**: `cargo clippy --lib` — fix any warnings

### Lua (Describe → Script → Run)

1. **Describe**: Write a `test_<module>.lua` file with `describe`/`it`/`expect_*` blocks
2. **Script**: Write a `main.lua` in `content/examples/` that exercises the new API
3. **Run**: `cargo test lua_test_<module>` — confirm failures
4. **Implement**: Add the Lua binding in `src/lua_api/`
5. **Verify**: Re-run both the test and the example

### Bug Fix Workflow

1. **Reproduce**: Write a test that triggers the bug
2. **Confirm red**: Run the test, verify it fails
3. **Fix**: Apply the minimal fix
4. **Confirm green**: Run the test, verify it passes
5. **Regression**: The test stays in the suite permanently

---

## Problem Areas and Known Issues

These are documented issues in the test suite that should be addressed over time:

| Issue | Description | Impact |
|---|---|---|
| `tests/rust/game/` retirement | Files remain but the category is retired — game systems are now Lua libraries | Medium — stale tests may give false confidence |
| Missing demo tests | Not every demo in `content/demos/` has a corresponding file in `tests/lua/content/demos/` | High — demos are supposed to be fully tested |
| `tests/lua/content/examples/` stale | `tests/lua/content/examples/` should be removed — examples are documentation and not testable | Low — confusing category, misleads contributors |
| Framework consistency | A few Lua test files define local helpers instead of using global `init.lua` | Low — tests pass, but framework is duplicated |
| Missing `test_summary()` | Some older Lua test files may lack the mandatory `test_summary()` call | Medium — framework can't report totals |
| Unregistered test files | `.rs` files in `tests/rust/` not listed in `Cargo.toml` are silently ignored | Medium — tests exist but never run |
| Golden coverage gaps | Graphics, audio, and text processing need golden snapshots in `tests/rust/golden/expected/image/`, `/audio/`, `/text/` | High — no byte-level regression detection for renderer output |
| Lua stress has no perf assertions | Most Lua stress tests measure iteration count but not wall time | Low — tests pass even on degraded hardware |
