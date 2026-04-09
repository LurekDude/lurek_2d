# Lurek2D — Test Suite Overview

Lurek2D uses a **two-tier test model**: Rust integration tests and Lua BDD tests.
Both tiers are executed via `cargo test`.

## Quick Run Commands

| Goal | Command |
|---|---|
| Run all tests | `cargo test` |
| Run one Rust module | `cargo test --test <name>_tests` |
| Run one Lua test | `cargo test lua_test_<category>_<name>` |
| Run golden tests | `cargo test --test golden_tests` |
| Verbose output | `cargo test -- --nocapture` |
| Debug log during tests | `$env:RUST_LOG = "debug"; cargo test -- --nocapture` |

## Directory Layout

```
tests/
├── README.md              ← this file
├── fixtures/              ← shared test assets (images, audio, data files)
│
├── rust/                  ← Rust integration tests (all registered in Cargo.toml)
│   ├── unit/              ← per-module Rust unit tests (one file per engine module)
│   ├── stress/            ← throughput + allocation pressure tests
│   ├── golden/            ← deterministic snapshot tests (graphics, audio, text)
│   ├── config/            ← engine configuration loading tests
│   ├── security/          ← sandbox audit, path-traversal tests
│   ├── ext/               ← cross-module Rust smoke tests
│   └── fixtures/          ← Rust-specific test assets
│
└── lua/                   ← Lua BDD tests (dispatched by tests/lua/harness.rs)
    ├── harness.rs         ← Rust dispatcher — one #[test] per .lua file
    ├── init.lua           ← BDD framework (describe/it/expect_*)
    ├── unit/              ← one file per engine module (lurek.* API surface)
    ├── content/library/           ← one file per Lunasome library in content/library/
    ├── integration/       ← tests BETWEEN ≥2 modules (name: test_<a>_<b>.lua)
    ├── stress/            ← Lua throughput tests (high iteration counts)
    ├── security/          ← Lua sandboxing + nil-spam + path-traversal
    ├── golden/            ← deterministic Lua output tests
    ├── config/            ← configuration loading tests
    ├── content/demos/             ← one file per demo in content/demos/
    ├── performance/       ← Lua benchmark helpers
    └── fixtures/          ← Lua-specific test assets
```

> **Note**: `tests/rust/game/` is retired. Game systems (battle, cardgame, combat, crafting, inventory, quest, stats) are pure-Lua libraries and tested in `tests/lua/content/library/`.
> **Note**: `tests/lua/content/examples/` should not be used. Examples are documentation and are not testable in the BDD harness.

## Tier 1: Rust Tests

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

## Lua Test Categories

| Category | Path | Scope |
|---|---|---|
| **unit** | `tests/lua/unit/` | One engine module per file (lurek.* API) |
| **library** | `tests/lua/content/library/` | One Lunasome library per file |
| **integration** | `tests/lua/integration/` | Tests between ≥2 distinct modules |
| **stress** | `tests/lua/stress/` | High-iteration throughput/load tests |
| **security** | `tests/lua/security/` | Sandbox, nil spam, path traversal |
| **golden** | `tests/lua/golden/` | Deterministic output comparison |
| **config** | `tests/lua/config/` | Configuration loading/validation |
| **demos** | `tests/lua/content/demos/` | One smoke test per demo folder |

## Golden Tests

Golden tests capture deterministic output (images, audio, hashes, struct debug output)
and compare against expected files in `tests/rust/golden/expected/`.

**Priority domains**: graphics (PNG snapshots), audio (waveform bytes), text (glyph rasters).

Expected files are tracked in git. Subsequent runs compare output and fail on any change.
To intentionally update: copy `actual/` to `expected/` and commit with a review.

## Adding a New Test

### Rust test
1. Add `#[test]` functions to the appropriate file under `tests/rust/unit/`, `tests/rust/stress/`, etc.
2. Ensure the binary is registered in `Cargo.toml` under `[[test]]`
3. Run: `cargo test --test <file_name>`

### Lua BDD test
1. Create the `.lua` file in the correct category folder using `describe`/`it`/`expect_*` + `test_summary()`
2. Add `#[test] fn lua_test_<category>_<name>() { run_lua_test("<category>/test_<name>.lua"); }` to `tests/lua/harness.rs`
3. Run: `cargo test lua_test_<category>_<name>`

## Quality Gates

Run these before every commit:

```powershell
cargo test && cargo clippy -- -D warnings
```

