# Lurek2D — Test Framework Architecture

> **Source of truth** for the test suite structure, naming conventions, BDD framework, and CI quality gates.
> Companion documents: [engine-architecture.md](engine-architecture.md) (runtime module structure) · [philosophy.md](philosophy.md) (principles + design assumptions).

---

## Table of Contents

1. [Overview](#overview)
2. [Test placement](#test-placement)
3. [Two-Layer Test Model](#two-layer-test-model)
4. [Directory Layout](#directory-layout)
5. [Rust Test Suites](#rust-test-suites)
6. [Lua BDD Test Framework](#lua-bdd-test-framework)
7. [Lua Test Documentation Standard](#lua-test-documentation-standard)
8. [Golden Tests](#golden-tests)
9. [VM Helpers](#vm-helpers)
10. [Naming Conventions](#naming-conventions)
11. [Float Comparison Rules](#float-comparison-rules)
12. [Test Constraints](#test-constraints)
13. [Adding a New Rust Test](#adding-a-new-rust-test)
14. [Adding a New Lua Test](#adding-a-new-lua-test)
15. [Running Tests](#running-tests)
16. [Quality Gates](#quality-gates)
17. [Test Coverage Tooling](#test-coverage-tooling)
18. [Test-Driven Development Workflow](#test-driven-development-workflow)
19. [Marker Annotations for API Coverage](#marker-annotations-for-api-coverage)
20. [Evidence-Based Testing](#evidence-based-testing)
21. [Stress Test Standardization](#stress-test-standardization)
22. [Integration Tests](#integration-tests)
23. [Describe-Block Coverage Tracking](#describe-block-coverage-tracking)
24. [Advanced Analytics](#advanced-analytics)
25. [Problem Areas and Known Issues](#problem-areas-and-known-issues)

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
| Format | Single-file, heavily commented | Folder with `main.lua` and optional `conf.toml` |

Examples are not tested. They exist to document API usage and are not expected to execute in a test harness. **Demos must all pass CI** — each demo has exactly one test file in `tests/lua/content/demos/`.

---

## Test placement

Test placement is governed by binding constraints **TST-01** through **TST-06**. See [philosophy.md § Testing Constraints](philosophy.md#testing-constraints) for the canonical text.

| Constraint | Rule |
|---|---|
| **TST-01** | Lua-first: behaviour reachable via `lurek.*` must be tested in Lua. |
| **TST-02** | Rust unit tests are centralised in `tests/rust/unit/` — no inline `#[cfg(test)]` in `src/`. |
| **TST-03** | `src/lua_api/*_api.rs` holds only `impl LuaUserData`, registration, and conversions. |
| **TST-04** | `mod.rs` holds only `pub mod`, `pub use`, attributes, and doc comments. |
| **TST-05** | Demo/game tests: headless Lua tests live in `tests/lua/content/demos/` (one file per demo, name `test_<name>.lua`); binary screenshot tests live in `tests/demo_smoke_tests.rs` (`#[ignore]`). Never put demo tests in `tests/lua/unit/`. |
| **TST-06** | Every Lua test layer has exactly **one file per module** (`test_<module>.lua` or `test_<modA>_<modB>.lua` for integration). This applies to `unit/`, `evidence/`, `golden/`, `stress/`, `security/`, and `config/`. No split per-sub-feature files (e.g. `test_effect_overlay.lua` alongside `test_effect_evidence.lua`). Merge into the single module file. |

> **Migration note (2026-04-20).** This project previously tolerated inline `#[cfg(test)] mod tests` blocks inside `src/**/*.rs` for private-helper coverage. That recommendation is **superseded by TST-02**, effective 2026-04-20. Existing inline blocks are tracked for relocation under session [`testing-cleanup-20260420`](../../work/testing-cleanup-20260420/reports/plan.md); no new inline blocks are accepted.

### Decision tree — where does a test go?

1. **Is the behaviour reachable via any `lurek.*` function, userdata, or callback?**
   → Write a **Lua test** under [`tests/lua/unit/test_<module>.lua`](../../tests/lua/unit/) (single-module surface), or under [`tests/lua/integration/test_<a>_<b>.lua`](../../tests/lua/integration/) when the test exercises two or more `lurek.*` namespaces. This is **TST-01**; it is the default path.

2. **Otherwise, is it a pure internal helper** — private module, `pub(crate)` surface, free function, or algorithm with no Lua exposure?
   → Write a **Rust unit test** under [`tests/rust/unit/<module>_tests.rs`](../../tests/rust/unit/). Register the binary in `Cargo.toml` if the file is new. This is **TST-02**; inline `#[cfg(test)]` blocks inside `src/` are banned.

3. **Is it a test of a game demo in `content/games/`?**
   → Write a **headless Lua test** under [`tests/lua/content/demos/test_<name>.lua`](../../tests/lua/content/demos/) using static analysis + `dofile()`. This is **TST-05**. Additionally, add a `#[ignore]` binary screenshot test to [`tests/demo_smoke_tests.rs`](../../tests/demo_smoke_tests.rs) for GPU-rendered validation. Do NOT put demo tests in `tests/lua/unit/`.

4. **Anything else** — integration across Rust + Lua, golden snapshot comparisons, stress / throughput runs, evidence artefact production, config loading, sandbox probes — goes in the existing `tests/rust/` or `tests/lua/` subfolder for that concern (see [Directory Layout](#directory-layout)). The subfolder choice is unchanged by TST-01..TST-06.

If both branch 1 and branch 2 appear to apply, choose branch 1 (Lua-first). Promote private helpers to `pub(crate)` and cover them through the Lua surface unless there is a specific reason they are Rust-only.

### Banned patterns

The following are rejected at code review and by the audit scripts below:

- **`#[cfg(test)] mod tests` inside any `src/**/*.rs` file** — violates **TST-02**. Relocate to `tests/rust/unit/<module>_tests.rs`.
- **Business logic in `src/lua_api/*_api.rs`** — loops beyond argument unpacking, arithmetic beyond type conversion, branching on game state, state machines. Violates **TST-03**. Move the logic to `src/<module>/*.rs` as a pure-Rust function exposed crate-publicly, then call it from the thin wrapper.
- **`fn`, `struct`, `enum`, `trait`, or `impl` definitions in any `mod.rs`** — violates **TST-04**. Move to a sibling file (`facade.rs`, `register.rs`, `types.rs`, or similar). `mod.rs` keeps only `pub mod X;`, `pub use X::*;`, module-level `#![...]` attributes, and doc comments.
- **Duplicating a `lurek.*`-reachable test in Rust** — violates **TST-01**. Delete the Rust duplicate; keep the Lua test as the source of truth.
- **Demo tests in `tests/lua/unit/`** — violates **TST-05**. Demo tests belong in `tests/lua/content/demos/`.
- **Split per-sub-feature test files across any layer** (e.g. `test_effect_overlay_evidence.lua` alongside `test_effect_evidence.lua`, or `test_terrain_render_evidence.lua` alongside `test_render_evidence.lua`) — violates **TST-06**. Merge into the single canonical `test_<module>_<layer>.lua` file. One file per module per layer.

### Enforcement — audit scripts

Three Python audit scripts under [`tools/audit/`](../../tools/audit/) enforce TST-02..TST-04. They are authored in session `testing-cleanup-20260420` (phase P3) and emit machine-readable JSON alongside a text summary:

- [`tools/audit/inline_test_audit.py`](../../tools/audit/inline_test_audit.py) — lists every inline `#[cfg(test)]` block with a suggested relocation target. Enforces **TST-02**.
- [`tools/audit/thin_wrapper_audit.py`](../../tools/audit/thin_wrapper_audit.py) — flags business-logic violations inside `src/lua_api/*_api.rs`. Enforces **TST-03**.
- [`tools/audit/thin_modrs_audit.py`](../../tools/audit/thin_modrs_audit.py) — flags disallowed definitions inside any `mod.rs`. Enforces **TST-04**.

TST-01 is enforced by `Reviewer` sign-off and by [`tools/audit/test_coverage.py`](../../tools/audit/test_coverage.py), which reports undercovered `lurek.*` surface.

### Harness registration

Lua tests are registered manually in [`tests/lua/harness.rs`](../../tests/lua/harness.rs) — auto-discovery is intentionally not used. Follow the registration procedure documented in [handbook.md § 9 Testing](../handbook.md#9-testing) and the repo-memory note on the manual harness pattern.

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
          ├── library/        One file per Lunasome library
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
- **Library tests** (`tests/lua/library/`) exclusively test Lunasome pure-Lua libraries (`library/`). These were formerly tested via `tests/rust/game/` which is now retired — game systems (battle, cardgame, combat, crafting, inventory, quest, stats) live in `library/` — they are Lunasome libraries, not engine modules.

---

## Directory Layout

```
tests/
├── fixtures/                        Shared test assets (images, audio, data files)
├── output/                          Evidence test artefact output (git-ignored)
├── samples/                         Golden comparison baseline files (committed)
│
├── rust/                            Rust test binaries (all registered in Cargo.toml)
│   ├── unit/                        One file per engine module — Rust struct invariants
│   │   ├── math_tests.rs
│   │   ├── render_tests.rs
│   │   ├── audio_tests.rs
│   │   ├── physics_tests.rs
│   │   ├── input_tests.rs
│   │   ├── time_tests.rs
│   │   ├── filesystem_tests.rs
│   │   ├── compute_tests.rs
│   │   ├── data_tests.rs
│   │   ├── image_tests.rs
│   │   ├── sound_tests.rs
│   │   ├── event_tests.rs
│   │   ├── ecs_tests.rs
│   │   ├── window_tests.rs
│   │   ├── task_tests.rs
│   │   ├── animation_tests.rs
│   │   ├── particle_tests.rs
│   │   ├── tilemap_tests.rs
│   │   ├── scene_tests.rs
│   │   ├── save_tests.rs
│   │   ├── mods_tests.rs
│   │   ├── graph_tests.rs
│   │   ├── nav_tests.rs
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
    │   ├── test_render.lua
    │   ├── test_audio.lua
    │   ├── test_physics.lua
    │   ├── test_input.lua
    │   ├── test_timer.lua
    │   ├── test_fileapp.lua
    │   ├── test_data.lua
    │   ├── test_image.lua
    │   ├── test_sound.lua
    │   ├── test_event.lua
    │   ├── test_particle.lua
    │   ├── test_scene.lua
    │   ├── test_tilemap.lua
    │   ├── test_nav.lua
    │   ├── test_ai.lua
    │   ├── test_terminal.lua
    │   └── ...
    │
    ├── library/                     One file per Lunasome library in library/
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
    │   ├── test_ecs_ai.lua
    │   ├── test_math_render.lua
    │   ├── test_math_physics.lua
    │   ├── test_physics_timer.lua
    │   ├── test_save_ecs.lua
    │   ├── test_tilemap_physics.lua
    │   └── ...
    │
    ├── stress/                      Throughput + security from Lua perspective
    │   ├── test_physics_stress.lua
    │   ├── test_math_stress.lua
    │   ├── test_ecs_stress.lua
    │   ├── test_particle_stress.lua
    │   └── ...
    │
    ├── security/                    Lua sandbox + input validation tests
    │   ├── test_invalid_args.lua    nil spam, wrong types at API boundary
    │   ├── test_mount_traversal.lua path-traversal attempts via GameFS
    │   ├── test_save_validation.lua
    │   └── test_toml_validation.lua
    │
    ├── golden/                      Deterministic output Lua tests
    │   └── test_<module>_golden.lua  Compares against tests/samples/ baseline files
    │
    ├── config/                      Configuration loading tests (conf.toml only)
    │   └── test_config.lua
    │
    └── content/demos/                       One test file per demo in content/games/
        │   Rule: every game demo must have exactly one test here (TST-05)
        │   Name format: test_<name>.lua
        │   Shared helper: _common_checks.lua  (static analysis + dofile load)
        ├── _common_checks.lua
        ├── test_globe_demo.lua
        ├── test_hello_world.lua
        ├── test_physics_demo.lua
        ├── test_sprites.lua
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

[[test]]
name = "demo_smoke_tests"
path = "tests/demo_smoke_tests.rs"
```

### Demo Screenshot Smoke Tests

`tests/demo_smoke_tests.rs` is a Rust integration test that **spawns the real `lurek2d` binary** with `--screenshot=<abs_path> --screenshot-frames=180` and asserts the output PNG is valid.

All functions in this file are `#[ignore]` by default so they do not run in normal `cargo test`. They require a pre-built binary and a real display (GPU + window).

Run with:
```bash
# All demo screenshot tests:
cargo test --test demo_smoke_tests -- --include-ignored

# Single demo:
cargo test --test demo_smoke_tests demo_smoke_globe_demo -- --include-ignored
```

The screenshot is written to `<demo_dir>/screenshot_smoke.png` (relative to repo root). Each test:
1. Deletes any stale `screenshot_smoke.png` from a previous run.
2. Spawns `lurek2d <demo_abs_path> --screenshot=<abs_path> --screenshot-frames=180`.
3. Waits up to 45 seconds for the binary to exit (the engine exits automatically after capturing).
4. Asserts the PNG exists, is > 2 KiB, and starts with the PNG magic bytes `\x89PNG`.

**Key parameters:** `--screenshot-frames=180` = 3 seconds at 60 FPS. The engine saves the screenshot and requests shutdown after the Nth rendered frame.

### Demo Lua Tests vs Screenshot Tests

| Concern | Lua test (`tests/lua/content/demos/`) | Screenshot test (`tests/demo_smoke_tests.rs`) |
|---|---|---|
| Runs in headless VM? | ✅ Yes | ❌ No — needs real GPU |
| Runs in CI by default? | ✅ Yes | ❌ No (`#[ignore]`) |
| Catches wrong callback names? | ✅ Via static analysis | ❌ Not specifically |
| Catches crash at frame 180? | ❌ No — headless only | ✅ Yes |
| Verifies rendered output? | ❌ No | ✅ PNG magic bytes + size check |

### tests/rust/game/ — Retired

`tests/rust/game/` previously held Rust tests for game systems (battle, cardgame, combat, crafting, inventory, quest, stats). Those systems are now **pure-Lua libraries** in `library/`. Their tests live in `tests/lua/library/`. Do not add new files to `tests/rust/game/`.

---

## Rust Test Suites

### Scope Rule

**All public API methods must be tested in Lua** — even when Rust tests would be faster. The Lua layer is the user-facing surface and must be proven correct from the user's perspective.

**Rust tests are for private/internal code only** — struct invariants, internal algorithms, resource lifecycle, and implementation details that have no `lurek.*` surface. If a type or method is `pub` and exposed to Lua, its primary test coverage must be in Lua.

### Suite Categories

| Category | Path | Scope | Example |
|---|---|---|---|
| **Integration** | `tests/rust/integration/` | Internal Rust types and private methods not exposed to Lua | `physics_tests.rs`: `BodyShape` enum match, `bounding_box()` |
| **Stress** | `tests/rust/stress/` | Raw Rust-level throughput (no Lua boundary) | `physics_stress_tests.rs`: 10K body world |
| **Golden** | `tests/rust/golden/` | Byte-level snapshot comparison at renderer level | Compare PNG byte-for-byte |
| **Config** | `tests/rust/config/` | TOML config loading + validation | `config_tests.rs`: TOML parsing |
| **Security** | `tests/rust/security/` | Sandbox audit, path-traversal guards | `security_tests.rs`: GameFS escapes |
| **Ext** | `tests/rust/ext/` | Cross-module Rust smoke tests | `graphics_ext_tests.rs`: mesh + texture |

> **Note**: `tests/rust/game/` is retired. Game systems (battle, cardgame, combat, crafting, inventory, quest, stats) are now pure-Lua libraries tested in `tests/lua/library/`.

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
| **Library** | `tests/lua/library/` | One Lunasome library per file | One `.lua` per `library/<name>` |
| **Integration** | `tests/lua/integration/` | Tests between ≥2 modules | Name: `test_<moduleA>_<moduleB>.lua` |
| **Stress** | `tests/lua/stress/` | Throughput + allocation from Lua | High iteration counts, timing checks |
| **Security** | `tests/lua/security/` | Sandboxing + input validation | Nil spam, path traversal, bad types |
| **Golden** | `tests/lua/golden/` | Deterministic output comparison | Compare against saved reference data |
| **Config** | `tests/lua/config/` | Configuration loading | `conf.toml` keys, defaults, missing fields, invalid TOML |
| **Demos** | `tests/lua/content/demos/` | One file per demo in `content/games/` | Name: `test_<name>.lua`; shared: `_common_checks.lua` |

### Framework API

| Function | Purpose |
|---|---|
| `describe(name, fn)` | Group related tests under a named section |
| `it(name, fn)` | Define a single test case |
| `before_each(fn)` | Run before each `it()` in the enclosing `describe()` |
| `after_each(fn)` | Run after each `it()` in the enclosing `describe()` |
| `expect_equal(expected, actual, msg)` | Assert strict equality (strings, integers, booleans) |
| `expect_not_equal(a, b, msg)` | Assert values differ |
| `expect_near(expected, actual, tol, msg)` | Assert float proximity; `tol` defaults to `1e-5` |
| `expect_true(val, msg)` | Assert truthy |
| `expect_false(val, msg)` | Assert falsy |
| `expect_nil(val, msg)` | Assert nil |
| `expect_not_nil(val, msg)` | Assert not nil |
| `expect_type(type_str, val, msg)` | Assert `type(val) == type_str` (e.g., `"table"`, `"number"`) |
| `expect_error(fn, msg)` | Assert fn raises a Lua error |
| `expect_no_error(fn, msg)` | Assert fn does not raise a Lua error |
| `expect_greater(a, b, msg)` | Assert `a > b` |
| `expect_less(a, b, msg)` | Assert `a < b` |
| `expect_in_range(val, min, max, msg)` | Assert `min <= val <= max` |
| `expect_contains(tbl, value, msg)` | Assert value appears in table |
| `expect_match(str, pattern, msg)` | Assert Lua string pattern matches |
| `expect_length(tbl, n, msg)` | Assert `#tbl == n` |
| `expect_deep_equal(expected, actual, msg)` | Recursive table equality |
| `measure(name, count, fn)` | Run fn, print `[PERF]` line, return `elapsed, ops_per_sec` |
| `expect_golden(name, data, expected)` | Deterministic comparison against inline expected string |
| `expect_canvas_pixel(canvas, x, y, r, g, b, a, tol, msg)` | Verify Canvas pixel RGBA within tolerance |
| `test_summary()` | **MANDATORY** — must be the last call in every file |

### Lua Test Documentation Standard

Lua test files use three distinct comment layers. Do not mix them.

1. **File header** — plain human-written prose comments at the top of the file. This header explains what the file covers and any headless constraints or evidence outputs. **Do not use `@description` for the file header.**
2. **Suite description** — every `describe()` block must have exactly one `-- @description ...` line immediately above the block's contiguous comment group.
3. **Case description** — every `it()` block must have exactly one `-- @description ...` line immediately above the block's contiguous comment group.

#### Required rules

- File header comments are plain `-- ...` prose only. No `-- @description` and no `-- @category` in the file header.
- Keep the file header short and human-readable. It is prose, not a metadata/docstring block.
- Use the exact syntax `-- @description <text>` without a colon.
- `-- @category: ...` markers are forbidden.
- Every `describe()` block may carry only one metadata line: `-- @description ...`.
- Marker ownership belongs to `it()` blocks. Put `@covers`, `@evidence`, `@golden`, and similar markers on the specific case that proves or compares the behavior.
- `test_summary()` is mandatory in every Lua test file and must be the **last non-empty line** in the file.
- `return test_summary()` is forbidden. Use a bare `test_summary()` call.
- `describe()` may be nested inside `describe()` when the nesting reflects a real API grouping. Keep nesting shallow; **two levels is the preferred maximum**.
- Every nested `describe()` still requires its own `-- @description ...` line.

#### Standard example

```lua
-- tests/lua/unit/test_modulename.lua
-- Exercises lurek.modulename constructors, error handling, and edge cases.
-- Headless-safe: no window, GPU, or audio required.

-- @description Groups namespace-level constructor and surface checks for lurek.modulename.
describe("lurek.modulename", function()
    -- @description Covers constructor behavior and default object state.
    describe("new()", function()
        -- @covers lurek.modulename.new
        -- @description Verifies new() returns a userdata object with the expected type.
        it("returns a userdata object", function()
            local value = lurek.modulename.new()
            expect_not_nil(value)
        end)
    end)
end)

test_summary()
```

#### Audit tool

Use the dedicated structure audit to check these rules:

```powershell
python tools/audit/lua_test_structure_audit.py
python tools/audit/lua_test_structure_audit.py --fix
python tools/audit/lua_test_structure_audit.py --allow-legacy-describe-markers
```

### Lua Test File Template

```lua
-- tests/lua/unit/test_modulename.lua
-- Tests for lurek.modulename API.
-- Covers namespace surface, constructor behavior, and boundary handling.

-- @description Groups top-level API checks for lurek.modulename.
describe("lurek.modulename", function()
    -- @description Covers someFunction behavior and edge cases.
    describe("someFunction", function()
        -- @description Verifies someFunction doubles a valid numeric input.
        it("should return expected result", function()
            local result = lurek.modulename.someFunction(42)
            expect_equal(84, result)
        end)

        -- @description Verifies someFunction rejects nil input with a Lua error.
        it("should handle edge cases", function()
            expect_error(function()
                lurek.modulename.someFunction(nil)
            end)
        end)
    end)

    -- @description Covers anotherFunction default-parameter behavior.
    describe("anotherFunction", function()
        -- @description Verifies anotherFunction can be called without arguments and still returns a number.
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

Library tests live in `tests/lua/library/` and use `require()` to load from `library/`.

```lua
-- tests/lua/library/test_library_combat.lua
-- Tests for the Lunasome combat library

local combat = require("library/combat")

-- @description Groups combat-library attack resolution cases.
describe("combat library", function()
    -- @description Covers resolve_attack result-shape and numeric damage expectations.
    describe("resolve_attack", function()
        -- @description Verifies resolve_attack returns positive damage that does not exceed the base attack value.
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
-- Integration: lurek.physics + lurek.timer (two distinct namespaces)

describe("physics + timer integration", function()
    it("should simulate body movement over elapsed time", function()
        -- uses lurek.physics AND lurek.timer
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
        expect_not_nil(lurek)
        -- load callback runs cleanly
        dofile("content/demos/hello_world/main.lua")
    end)
end)

test_summary()
```

### Harness Dispatch

The Lua harness (`tests/lua/harness.rs`) is maintained manually. Every new Lua test file must get a matching `#[test]` entry that calls `run_lua_test("...")`.

If the `.lua` file exists but is not registered in `tests/lua/harness.rs`, Cargo will never execute it.

---

## Golden Tests

Golden tests compare evidence output against committed baseline samples. **Golden tests do NOT create content** — they rely on evidence tests to produce the output, then compare it against a committed golden sample.

### Rules

1. **Golden tests ONLY compare.** They read an evidence file and a golden sample, then assert they match. No content creation.
2. **Evidence tests must run first.** If the evidence file doesn't exist, the golden test fails with a clear message.
3. **Golden samples live in `tests/lua/golden/samples/<module>/`** — committed to git, reviewed by humans before acceptance.
4. **Migrated Rust text/binary baselines now live under `tests/lua/golden/samples/migrated_rust/`** when the compare contract belongs to the Lua golden layer.
5. **Golden tests must not call `lurek.*` APIs, `savePNG`, `saveWAV`, or write files.** Any content creation belongs in the evidence layer.
6. **Use `tools/audit/lua_evidence_golden_contract_audit.py`** to detect mixed evidence suites and golden files that still generate content.
7. **Every golden test uses BDD structure** and the `-- @golden` marker.
8. **Use `expect_golden_file_match()` for binary comparison** (PNG, WAV) or `expect_golden_text_match()` for text (normalizes whitespace/line endings).

### Directory Structure

```
tests/lua/golden/
├── test_math_golden.lua              Golden test script
├── test_physics_golden.lua           Golden test script
├── samples/                          Committed baseline files (git-tracked)
│   ├── math/
│   │   └── constants.txt
│   ├── physics/
│   │   └── draw_debug.png
│   └── audio/
│       └── sine_440hz.wav
```

```
tests/lua/evidence/output/            Generated during test run (git-ignored)
├── math/
│   └── constants.txt
├── physics/
│   └── draw_debug.png
└── audio/
    └── sine_440hz.wav
```

### Golden Test Template

```lua
-- Golden test: <module> <what it compares>
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

### Golden Helpers (defined in init.lua)

| Function | Purpose |
|---|---|
| `expect_golden_file_match(evidence_path, golden_path)` | Binary-exact comparison |
| `expect_golden_text_match(evidence_path, golden_path)` | Text comparison (normalizes whitespace/line endings) |

### Updating Golden Samples

When evidence output intentionally changes (e.g., algorithm improvement, font update):

1. Run the evidence test: `cargo test --test lua_tests <evidence_test_name> -- --nocapture`
2. Review the new output in the evidence path used by that suite.
3. Copy the reviewed artifact into `tests/lua/golden/samples/<module>/`.
4. Commit the updated golden sample with a clear commit message

### Rust Golden Tests

The Rust golden harness (`tests/rust/golden/harness.rs`) now focuses on engine-internal image/raycaster style baselines. Lua-facing text snapshots, TOML round-trips, encode/hash baselines, and migrated compare-only contracts belong under `tests/lua/golden/`.

```
tests/rust/golden/
├── harness.rs                 Rust harness
├── expected/                  Committed reference files
│   ├── image/                 Expected PNG snapshots
│   ├── audio/                 Expected waveform data
│   ├── text/                  Expected rendered text
│   └── ...                    Renderer- or engine-internal baselines only
└── actual/                    Generated during test run (git-ignored)
```

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
- `describe()` blocks named after the API namespace: `"lurek.math"`, `"lurek.render"`
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
| A Lunasome library in `library/` | **library** | `tests/lua/library/test_library_<name>.lua` |
| Interaction between ≥2 modules | **integration** | `tests/lua/integration/test_<a>_<b>.lua` |
| High-load / many iterations | **stress** | `tests/lua/stress/test_<topic>_stress.lua` |
| Nil spam / bad inputs / sandbox | **security** | `tests/lua/security/test_<topic>.lua` |
| Config file loading | **config** | `tests/lua/config/test_config.lua` |
| Creating output artifacts (PNG, WAV, text) | **evidence** | `tests/lua/evidence/test_evidence_<module>.lua` |
| Comparing evidence against golden samples | **golden** | `tests/lua/golden/test_<module>_golden.lua` |
| A demo in `content/demos/` | **demos** | `tests/lua/content/demos/test_demo_<name>.lua` |

Steps for all categories:
1. Create the `.lua` file in the correct subdirectory using the template
2. End the file with `test_summary()`
3. The harness auto-discovers test files via `build.rs` — no manual registration needed
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
| `python tools/audit/test_coverage.py` | Test coverage analytics | `logs/test_coverage.json` |
| `python tools/audit/test_coverage.py --suggest` | Generate stubs for uncovered items | stdout |
| `python tools/audit/module_audit.py` | Full module audit (includes test status) | stdout |
| `python tools/audit/audit_module.py <name>` | Single module quality audit | PASS/WARN/ERROR |
| `python tools/audit/lua_api_test_coverage.py` | Per-function API coverage (marker + heuristic) | stdout / JSON |
| `python tools/audit/lua_api_test_coverage.py --json` | JSON export for CI/tooling | `logs/lua_api_test_coverage.json` |
| `python tools/audit/lua_api_test_coverage.py --markdown` | Markdown report | stdout |
| `python tools/audit/lua_api_test_coverage.py --suggest` | Suggest missing `@covers` markers | stdout |
| `python tools/audit/lua_api_test_coverage.py --strict --threshold 40` | Exit 1 if coverage below 40% | — |

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

## Marker Annotations for API Coverage

Lua test files can declare which `lurek.*` API functions they cover using `-- @covers` annotations. The coverage scanner (`tools/audit/lua_api_test_coverage.py`) reads these markers to produce accurate per-function coverage data, replacing the heuristic substring-matching approach.

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

### Placement Rules

- Place `-- @covers` lines **before** the `describe` or `it` block that tests the function
- Prefer the closest block that actually owns the assertion. Do not use unrelated file-global `@covers` lists.
- One function per `-- @covers` line
- Module-level functions: `-- @covers lurek.<module>.<function>`
- UserData methods: `-- @covers <ClassName>:<method>`
- The regex pattern: `^--\s*@covers\s+((?:lurek\.\w+\.\w+)|(?:\w+:\w+))\s*$`

### Additional Tags (Planned)

| Tag | Purpose |
|---|---|
| `-- @covers lurek.x.y` | Marks function coverage |
| `-- @evidence file` | Test produces file-based evidence (saved output) |
| `-- @evidence pixel` | Test uses Canvas pixel readback for visual evidence |
| `-- @golden` | Test compares against a golden baseline |
| `-- @stress` | Test measures throughput performance |

### Coverage Scanner

```powershell
# Basic run — prints per-module coverage bars
python tools/audit/lua_api_test_coverage.py

# JSON output for CI/tooling
python tools/audit/lua_api_test_coverage.py --json

# Markdown report
python tools/audit/lua_api_test_coverage.py --markdown

# Suggest missing coverage
python tools/audit/lua_api_test_coverage.py --suggest

# Strict mode — exit 1 if below threshold
python tools/audit/lua_api_test_coverage.py --strict --threshold 40
```

The scanner uses a **hybrid approach**: explicit `-- @covers` markers when present, heuristic substring matching as fallback for unmarked files. As markers are added, heuristic coverage is gradually replaced by verified marker coverage.

Output: `logs/lua_api_test_coverage.json`

---

## Evidence-Based Testing

Evidence tests create output artifacts (PNG, WAV, OBJ, text files) that prove an API function produces correct observable results. **Evidence tests do NOT assert values** — they only create files and verify the file was created. A human reviewer or a golden test evaluates the content.

### Rules

1. **Evidence tests ONLY create files.** No `expect_equal`, `expect_near`, or any value comparison. The only assertion is `expect_evidence_created(path)` which checks the file exists and is non-empty.
2. **Every evidence test uses BDD structure** (`describe`/`it`) — never a plain script.
3. **Evidence output goes to `tests/lua/evidence/output/<module>/`** via `evidence_output_dir(category)`.
4. **Evidence tests use `-- @evidence file` marker** on every `it()` block that writes an artifact.
5. **Evidence tests end with `test_summary()`** like all other tests.
6. **Evidence file headers remain plain prose comments**. The root `describe()` block still requires its own `-- @description ...` line.
7. **Do not mix unit-style API sanity checks into evidence files.** Constructor/return-type assertions belong in `tests/lua/unit/`; evidence suites should contain artifact-producing cases only.
8. **Run `python tools/audit/lua_evidence_golden_contract_audit.py` after evidence/golden edits** to catch mixed suites and compare-only violations.

### Evidence Test Template

```lua
-- Evidence test: <module> <what it produces>
-- @evidence file
-- @covers lurek.<module>.<function>

describe("evidence: <module> <description>", function()
    it("creates <artifact description>", function()
        ensure_evidence_dir("<module>")
        local path = evidence_output_dir("<module>") .. "<filename>"

        -- Create content using lurek.* APIs
        local img = lurek.image.newImageData(256, 256)
        -- ... populate img ...
        img:savePNG(path)

        -- Only check file was created — never assert pixel values
        expect_evidence_created(path)
    end)
end)

test_summary()
```

### Evidence Helpers (defined in init.lua)

| Function | Purpose |
|---|---|
| `evidence_output_dir(category)` | Returns `"tests/lua/evidence/output/<category>/"` |
| `ensure_evidence_dir(category)` | Creates the evidence output directory if missing |
| `expect_evidence_created(path)` | Asserts the file exists and is non-empty |

---

### Evidence Test Contract (MANDATORY)

An evidence test is valid **only if** removing the `lurek.*` module being tested would make the test produce wrong or missing output.

> **Litmus test:** "If I deleted this module's Lua API, would the evidence file look different?"
> If the answer is **no**, the test is **invalid**. You are only testing `newImageData` and `setPixel`, not the module.

Every valid evidence test follows this four-step structure:

```
1. CREATE   — instantiate module object via lurek.* API
              e.g. lurek.particle.newSystem(), lurek.minimap.new()
2. CONFIGURE — set up the module via its Lua API methods
              e.g. sys:setRate(50), mm:setFogLevel(x, y, 2)
3. EXECUTE   — run module logic to advance state
              e.g. sys:update(dt), mm:step(), grid:findPath()
4. DUMP      — output what the module produced to a file
              e.g. sys:drawToImage(w, h) → savePNG, or visualize API-returned data
```

#### Module categories and how to produce evidence

| Module type | How to produce valid evidence |
|---|---|
| Has `drawToImage()` | Call `module:drawToImage(w, h)` and save the result. Do **NOT** draw anything manually on top. |
| Pure data / computation | Run the algorithm; visualize the **data returned by the API** using basic drawing helpers. The algorithm result must be the source — not hand-crafted geometry. |
| Audio DSP | Save audio file or export waveform/spectrogram PNG. Samples must come from the DSP module's output. |
| Config / state snapshot | Serialize module state to text using `lurek.serial` or `tostring`. No manual string construction. |

#### Invalid patterns — must be replaced or deleted

```lua
-- WRONG: tests nothing — draws shapes manually without touching any module API
it("polygon gallery", function()
    local img = lurek.image.newImageData(256, 256)
    img:fill(20, 20, 30, 255)
    for _, s in ipairs(shapes) do
        for i = 0, s.sides - 1 do
            -- ... manual trig + setPixel loop ...
        end                              -- no lurek.* domain module called!
    end
    lurek.image.savePNG(img, OUT .. "shapes.png")  -- proves nothing about any module
end)

-- WRONG: only tests newImageData and setPixel — not any domain module
it("gradient fills the image", function()
    local img = lurek.image.newImageData(256, 256)
    for y = 0, 255 do
        for x = 0, 255 do img:setPixel(x, y, x, y, 128, 255) end
    end
    lurek.image.savePNG(img, OUT .. "gradient.png")
end)
```

#### Valid patterns

```lua
-- RIGHT: particle system is the subject; drawToImage proves it works
it("emitter spawns particles after update", function()
    local sys = lurek.particle.newSystem()      -- 1. CREATE via API
    sys:setRate(50)                              -- 2. CONFIGURE via API
    for _ = 1, 30 do sys:update(1/60) end        -- 3. EXECUTE via API
    local img = sys:drawToImage(256, 256)        -- 4. DUMP module output
    lurek.image.savePNG(img, OUT .. "emitter_basic.png")
    expect_evidence_created(OUT .. "emitter_basic.png")
end)

-- RIGHT: pathfinding data visualized — data came from the API, not hand-crafted
it("A-star path from (0,0) to (19,19)", function()
    local grid = lurek.pathfind.newGrid(20, 20)  -- 1. CREATE
    grid:setWalkable(10, 5, false)               -- 2. CONFIGURE
    local path = grid:findPath(0, 0, 19, 19)    -- 3. EXECUTE
    local img = lurek.image.newImageData(200, 200) -- 4. DUMP: visualize API result
    img:fill(40, 40, 40, 255)
    for _, pt in ipairs(path) do
        img:setPixel(pt.x * 10, pt.y * 10, 0, 255, 0, 255)
    end
    lurek.image.savePNG(img, OUT .. "pathfind_astar.png")
    expect_evidence_created(OUT .. "pathfind_astar.png")
end)
```

---

### Model-Level `draw_to_image()` Evidence (Headless, No GPU)

Some domain modules provide a `draw_to_image()` function that produces a
CPU pixel buffer (`ImageData`) by software-rasterizing the module's output.
This enables **headless visual evidence testing** without any GPU or window.

**The `draw_to_image()` function lives in the model** (`src/<module>/draw.rs`),
NOT in the renderer. It is a testing and debugging utility, not the
production render path.

| Module | Evidence Function | What it Produces |
|---|---|---|
| `raycaster` | `draw_to_image(scene, width, height)` | CPU-rasterized first-person view from `RaycasterScene` quads |
| `tilemap` | `draw_to_image(map, viewport)` (planned) | CPU-rasterized tile grid for golden tests |
| `minimap` | `draw_to_image(minimap)` (planned) | CPU-rasterized minimap overview |

### Priority Modules for Evidence Testing

- **P0**: `gfx` (shapes, colors), `light` (illumination), `particle` (emission), `raycaster` (2.5D scene)
- **P1**: `camera` (viewport), `tilemap` (tile rendering), `ecs` (draw components)
- **P2**: `animation` (frame display), `postfx` (shader effects), `ui` (widget rendering)

---

## Stress Test Standardization

### Standard Output Format

All stress tests should print performance data in a parseable format:

```lua
-- [PERF] test_name: count ops in Xs (Y ops/sec)
print(string.format("[PERF] entity_create: %d ops in %.3fs (%.0f ops/sec)",
    count, elapsed, count / elapsed))
```

### Measurement Helper

The `measure()` function in `tests/lua/init.lua` standardizes stress-test timing output:

```lua
-- measure(name, count, fn) returns elapsed, ops_per_sec and prints a [PERF] line
local elapsed, ops = measure("entity_create", 10000, function()
    for i = 1, 10000 do lurek.ecs.newEntity() end
end)
expect_less(elapsed, 2.0, "10k entity creates must finish under 2s")
```

Output format: `[PERF] entity_create: 10000 ops in 0.142s (70423 ops/sec)`

Use `expect_less(elapsed, threshold)` to turn performance measurements into hard test assertions. Stress tests without a timing assertion are informational only.

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
| Heuristic-only API coverage | Existing `test_coverage.py` uses substring matching — 12-18% false-positive rate | Medium — coverage numbers are inflated |
| No `@covers` markers | Zero test files have explicit API coverage markers — all coverage is heuristic | Medium — prevents accurate per-function tracking |
| Light module evidence gap | Light tests pass by checking API existence, not visual output | High — lights may not work and tests still pass |
| Integration test misplacement | 4 integration tests (system, devtools, debugbridge, docs) are single-module tests | Low — wrong category, inflates integration count |

---

## Integration Tests

Integration tests are located in `tests/lua/integration/` and test two or more modules working together in one scenario. Single-module scenarios belong in `tests/lua/unit/`.

### Volume Target: 58+ integration tests across two phases

**Phase 1 (complete)** — 43 integration tests across the core module grid. Each test exercises at least two modules; see the `tests/lua/integration/` directory for the current set.

**Phase 2 (planned)** — additional integration tests covering more complex module combinations, including three-way interactions. Planned groups:

| Group | Tests | Key Combinations |
|-------|-------|-----------------|
| Graphics Pipeline | 9 | gfx+camera, gfx+light, gfx+effect, gfx+animation, gfx+particle, gfx+tilemap, canvas+postfx, image+gfx, spine+animation |
| Audio | 4 | audio+timer, audio+event, audio+data, audio+filesystem |
| AI/Behavior | 5 | ai+entity+scene, ai+signal, pathfinding+entity, pathfinding+tilemap+entity, ai+scene+camera |
| Persistence | 5 | savegame+entity+scene, savegame+animation, data+compute, thread+filesystem, savegame+modding |
| UI/Input | 4 | ui+input, ui+localization+data, gui+animation, input+tween |
| Procedural/Rendering | 6 | procgen+tilemap, procgen+entity, tween+animation, postfx+camera, minimap+tilemap+camera, raycaster+tilemap |

Three-way integration tests (three modules exercised in one test) are the highest-value targets — they Surface emergent bugs that two-way tests miss.

### Naming Convention

```
tests/lua/integration/test_<primary>_<secondary>[_<tertiary>].lua
```

Example: `test_ai_ecs_scene.lua` tests `lurek.ai`, `lurek.ecs`, and `lurek.scene` in one scenario.

---

## Describe-Block Coverage Tracking

Beyond `-- @covers` markers, the naming convention of `describe()` blocks enables automatic coverage tracking at the method level.

### Convention

Name every `describe()` block that targets a specific API function after that function:

```lua
describe("lurek.audio.newBus", function()   -- module function
    it("creates bus with given name", ...)
    it("rejects empty name", ...)
end)

describe("AudioBus:setVolume", function()   -- UserData method
    it("stores volume", ...)
    it("clamps to [0,1]", ...)
end)
```

**Recognized patterns** (scanner extracts these):
- `"lurek.<module>.<function>"` → module-level function
- `"<ClassName>:<method>"` → UserData method
- `"lurek.<module> error handling"` → module-scoped, no specific function

### Coverage Score per Method

A function's describe block earns a score of 0–4:
- +1 if the block has ≥1 `it()` calls
- +1 if the block has ≥3 `it()` calls
- +1 if any `it()` uses `expect_error` or `pcall`
- +1 if the test has any `-- @evidence` tag

A module's **describe coverage score** is the average score across all its API functions, scaled to 0–100%.

### Migration Plan

1. Start with `lurek.audio.*` — rename all existing describe blocks to follow the convention
2. Extend `tools/audit/lua_api_test_coverage.py` to parse describe-block names
3. Report describe coverage score alongside existing heuristic and marker coverage
4. Set CI gate: modules with describe coverage score < 25% emit a warning

---

## Advanced Analytics

The planned `tools/audit/test_analytics.py` script aggregates all coverage data sources into a unified report.

### Data Sources Combined

| Source | Data |
|--------|------|
| `lua_api_data.json` | Complete API surface (48 modules, 2588 functions) |
| `-- @covers` markers | Explicit per-function coverage |
| `describe()` naming | Per-method test count, error tests, nil tests |
| `-- @evidence` tags | Evidence tier per function |
| `-- @stress` / `-- @golden` | Stress and golden coverage flags |

### Invocation

```powershell
python tools/audit/test_analytics.py                   # full stdout report
python tools/audit/test_analytics.py --html            # HTML dashboard → docs/quality/test_analytics.html
python tools/audit/test_analytics.py --json            # JSON → logs/test_analytics.json
python tools/audit/test_analytics.py --module physics  # single module deep-dive
python tools/audit/test_analytics.py --worst 10        # 10 lowest-scoring modules
python tools/audit/test_analytics.py --trend           # compare to last run (fail if regression)
```

### Module Grading

Each module scores 0–10 based on: heuristic coverage (20%), marker coverage (25%), evidence count (20%), error test count (15%), stress test presence (10%), golden test presence (10%).

Grades: A (9–10), B (7–8), C (5–6), D (3–4) ⚠, F (0–2) 🚨

### Output Files

- `docs/quality/test_analytics.html` — browsable dashboard with sortable module table, category charts, uncovered function explorer
- `logs/test_analytics.json` — git-tracked for trend comparison across runs
