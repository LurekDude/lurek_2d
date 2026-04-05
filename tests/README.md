# Luna2D — Test Suite Overview

Luna2D uses a **two-tier test model**: Rust integration tests and Lua BDD tests.
Both tiers are executed via `cargo test`.

## Quick Run Commands

| Goal | Command |
|---|---|
| Run all tests | `cargo test` |
| Run one Rust module | `cargo test --test <name>_tests` |
| Run one Lua test | `cargo test lua_test_<module>` |
| Run golden tests | `cargo test --test golden_tests` |
| Verbose output | `cargo test -- --nocapture` |
| Debug log during tests | `$env:RUST_LOG = "debug"; cargo test -- --nocapture` |

## Directory Layout

```
tests/
├── README.md              ← this file
├── fixtures/              ← shared test assets (images, audio, data files)
├── rust/                  ← Rust integration tests (see tests/rust/README.md)
│   ├── unit/              ← per-module Rust unit tests
│   ├── ext/               ← extension / Tier-2 module tests
│   ├── game/              ← full game-loop integration tests
│   ├── stress/            ← performance and load tests
│   ├── golden/            ← deterministic output golden tests + screenshots
│   ├── security/          ← security-focused tests
│   ├── config/            ← engine configuration tests
│   └── fixtures/          ← Rust-specific test assets
└── lua/                   ← Lua BDD tests (see tests/lua/README.md)
    ├── harness.rs         ← Rust dispatcher — registers all Lua test entries
    ├── init.lua           ← BDD framework (describe/it/expect_*)
    ├── unit/              ← per-module Lua unit tests
    ├── integration/       ← cross-module Lua integration tests
    ├── library/           ← Lunasome (library/) Lua tests
    ├── stress/            ← Lua performance tests
    ├── security/          ← Lua sandboxing tests
    ├── golden/            ← Lua deterministic output tests
    ├── performance/       ← Lua benchmark helpers
    ├── config/            ← Lua configuration tests
    ├── examples/          ← example validation scripts
    └── fixtures/          ← Lua-specific test assets
```

## Tier 1: Rust Integration Tests

Rust tests live under `tests/rust/` and are registered in `Cargo.toml`.
They import from the crate root and run entirely headless (no GPU, audio, or window).

**Naming convention**: `<subject>_<scenario>_<expected>` — no `test_` prefix.

**Float comparisons**: always `assert!((a - b).abs() < 1e-5)` — never `assert_eq!` on `f32`.

## Tier 2: Lua BDD Tests

Lua tests live under `tests/lua/` and are dispatched by `tests/lua/harness.rs`.
Each `.lua` file must be registered with a `#[test]` entry in `harness.rs`.

**Framework functions** (provided by `tests/lua/init.lua`):

| Function | Purpose |
|---|---|
| `describe(name, fn)` | Test group block |
| `it(name, fn)` | Single test case |
| `expect_equal(a, b)` | Strict equality assertion |
| `expect_near(a, b, tol?)` | Float near-equality (default tol: 1e-5) |
| `expect_type(val, type)` | Type assertion |
| `expect_error(fn)` | Assert function raises an error |
| `expect_not_nil(val)` | Non-nil assertion |
| `test_summary()` | **Mandatory** — prints pass/fail totals at end of file |

**Constraint**: Lua tests must not create windows, play audio, or write outside `target/`.

## Golden Tests

Golden tests capture deterministic output (Debug-formatted structs, ray-cast results) and
compare against expected files in `tests/rust/golden/expected/`.

Visual evidence screenshots are saved in `tests/rust/golden/screenshots/` as PNG files
using the `save_test_screenshot(name, img)` helper.

Expected files are tracked in git. On first run (baseline mode) they are created automatically.
Subsequent runs compare output and fail if anything changes.

## Adding a New Test

### Rust test
1. Add a `#[test]` function to the appropriate file under `tests/rust/unit/` or `tests/rust/ext/`
2. Ensure the file binary is registered in `Cargo.toml` under `[[test]]`
3. Run: `cargo test --test <file_name>`

### Lua BDD test
1. Create `tests/lua/unit/test_<module>.lua` using `describe`/`it`/`expect_*` + `test_summary()`
2. Add `#[test] fn lua_test_<module>() { run_lua_test("unit/test_<module>.lua"); }` to `tests/lua/harness.rs`
3. Run: `cargo test lua_test_<module>`

## Quality Gates

Run these before every commit:

```powershell
cargo test && cargo clippy -- -D warnings
```
