---
applyTo: "tests/**"
---

# Tests Instructions

Luna2D has a **two-layer test system**: Rust integration tests in `tests/*.rs` and Lua BDD tests in `tests/lua/`. Both layers run via `cargo test`. Tests must pass before any commit.

## Test Architecture

```
tests/
├── *.rs                  ← Rust integration tests (auto-discovered by Cargo)
├── golden_tests.rs       ← binary golden-file comparison harness
├── stress/               ← slow Rust stress tests (registered via [[test]] in Cargo.toml)
├── lua/
│   ├── init.lua          ← BDD framework: describe/it/expect_* globals (read-only)
│   ├── harness.rs        ← Rust dispatcher — one #[test] per Lua file
│   ├── unit/             ← Lua unit tests (test_<module>.lua)
│   ├── integration/      ← cross-module Lua integration tests
│   ├── stress/           ← performance Lua stress tests
│   ├── validation/       ← negative-path / contract Lua tests
│   └── golden/           ← deterministic golden output Lua tests
└── golden/
    ├── expected/         ← committed baseline files
    └── actual/           ← runtime outputs (.gitignore-d)
```

## Adding a New Rust Integration Test File

1. Create `tests/<module>_tests.rs` — Cargo auto-discovers it.
2. Add a module-level doc: `//! Integration tests for luna2d::<module>.`
3. Import from crate root: `use luna2d::<module>::Type;`
4. Follow naming: `fn <subject>_<scenario>_<expected>()` (no `test_` prefix).
5. Run: `cargo test --test <module>_tests`

## Adding a New Lua Test File

### Unit test (`tests/lua/unit/test_<module>.lua`)
1. Create the file — framework globals (`describe`, `it`, `expect_*`) require no import.
2. Write using BDD structure (see below).
3. End the file with `test_summary()`.
4. Register in `tests/lua/harness.rs`:
   ```rust
   #[test]
   fn lua_test_<module>() {
       run_lua_test("unit/test_<module>.lua");
   }
   ```
5. Run: `cargo test lua_test_<module>` (from the `lua_tests` test binary)

### Integration test (`tests/lua/integration/test_<a>_<b>.lua`)
Same pattern but place in `integration/` and register as `lua_integration_<a>_<b>`.

### Stress test (`tests/lua/stress/test_<name>_stress.lua`)
Same but register as `lua_stress_<name>`.

### Validation test (`tests/lua/validation/test_<name>.lua`)
Same but register as `lua_validation_<name>`.

## Lua BDD Framework API

The framework is loaded automatically by `harness.rs` from `tests/lua/init.lua`.

```lua
describe("luna.math trigonometry", function()
    it("sin(pi/2) = 1", function()
        expect_near(1, luna.math.sin(luna.math.pi / 2), 0.0001)
    end)
end)

test_summary()  -- required at end of every Lua test file
```

**Assertion functions:**
| Function | Purpose |
|---|---|
| `expect_equal(expected, actual, msg)` | Exact equality (strings, ints, bools) |
| `expect_not_equal(a, b, msg)` | Assert differing |
| `expect_near(expected, actual, tol, msg)` | Float comparison; default `tol=0.0001` |
| `expect_true(val, msg)` | Value is truthy |
| `expect_false(val, msg)` | Value is falsy |
| `expect_nil(val, msg)` | Value is nil |
| `expect_not_nil(val, msg)` | Value is not nil |
| `expect_type(type_str, val, msg)` | `type(val) == type_str` |
| `expect_error(fn, msg)` | Function must raise an error |
| `expect_no_error(fn, msg)` | Function must not raise an error |

## Core Rules

- **Integration tests import from crate root**: `use luna2d::math::Vec2;` — never `use luna2d::src::math::Vec2`
- **Float comparisons in Rust**: `assert!((val - expected).abs() < 1e-5)` — **never** `assert_eq!` on `f32`/`f64`
- **Float comparisons in Lua**: `expect_near(expected, actual, 0.0001)` — **never** `expect_equal` on floats
- **One concern per test**: each `fn` or `it()` checks one logical scenario; failure message must identify what broke
- **No `#[should_panic]` without a message**: `#[should_panic(expected = "out of bounds")]`
- **Deterministic**: no random inputs, no timing dependencies, no global mutable state between tests

## Layer / Boundary Rules

- `tests/math_tests.rs` → tests `luna2d::math` public API only
- `tests/physics_tests.rs` → tests `luna2d::physics` public API only
- `tests/graphics_tests.rs` → Color, DrawCommand, Renderer (no window or GPU required)
- `tests/input_tests.rs` → KeyboardState, MouseState in isolation (no event loop)
- `tests/audio_tests.rs` → Mixer load path (playback silently fails without audio HW — OK)
- Never create a winit `Window` or wgpu `Surface` — they require a display and GPU
- Lua headless tests: `create_test_vm()` is windowless — do NOT call `luna.graphics.draw*`

## Quality Compliance

- Every new public `struct` / `fn` added to the engine requires at least one test before merge
- Physics tests using gravity: set `World::new(gx, gy)` — do not hardcode gravity
- Tests must not write to disk except in `tests/golden/actual/` or a `tempfile::tempdir()`
- `tests/lua/harness.rs` must have a `#[test]` dispatcher for every `.lua` file in `tests/lua/`

## Quality Tools

### Development Loop — use these during implementation (fast, scoped)

Never run `cargo build` or `cargo test` (full) while developing a module.
Never consume the full CPU during development — other agents or the user may be working in parallel.

```powershell
# Step 1 — type-check only (no codegen, fastest, ~2-5s incremental)
cargo check

# Step 2 — test only the module you are working on
cargo test --test <module>_tests -- --nocapture
cargo test lua_test_<module> -- --nocapture

# Lint scoped to the library (no test binaries)
cargo clippy --lib 2>&1 | Select-String "^error|^warning"
```

**Rule**: `cargo check` validates the whole codebase type-system in one pass without linking.
No separate `cargo build` step is ever needed before `cargo test` — Cargo builds what it needs automatically.

### Final Gate — only at commit time (full, slow)

Run these **once**, after all development on a task is complete, before `git commit`:

```powershell
cargo test                                    # Run all tests — must exit 0
cargo clippy -- -D warnings                   # Lint — must be clean
# cargo build is only needed for dist/install — never needed for tests or CI
```

### Single-module commands reference

```powershell
cargo check                                   # Fast type-check (no binary output)
cargo test --test <module>_tests              # Run one Rust test file
cargo test lua_test_<module>                  # Run one Lua test by dispatcher name
cargo test lua_test_<module> -- --nocapture   # Show lua print() output
cargo clippy --lib                            # Lint lib only (fast)
python tools/test_coverage.py                 # Coverage analytics → docs/API/test_coverage.json
python tools/integration_coverage.py          # Check Lua integration test coverage
python tools/collect_docs.py --report-missing # List undocumented public items
```

## Avoid

- `std::thread::sleep` — use deterministic `clock.tick()` with fixed dt
- Network I/O of any kind
- `#[ignore]` without a comment explaining when to re-enable
- Testing private functions from integration tests — use `pub(crate)` or an inline `#[cfg(test)]`
- Depending on test execution order — each test must be independently runnable
- Registering a Lua test file in `harness.rs` without creating the actual `.lua` file
