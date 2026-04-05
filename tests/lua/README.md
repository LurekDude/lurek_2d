# Luna2D — Lua BDD Tests

Lua tests exercise the `luna.*` API surface through a Behaviour-Driven Development framework.
They run headless inside a minimal Lua VM — no GPU, audio, or window is required.

## Quick Run

```powershell
# Run a specific Lua test
cargo test lua_test_<module>

# Run all Lua tests
cargo test lua_test_

# Verbose output (print statements visible)
cargo test lua_test_<module> -- --nocapture
```

## Directory Layout

| Directory | Purpose |
|---|---|
| `harness.rs` | Rust dispatcher — one `#[test]` entry per `.lua` file |
| `init.lua` | BDD framework — `describe`, `it`, `expect_*`, `test_summary` |
| `unit/` | Per-module tests for a single `luna.*` namespace |
| `integration/` | Tests that span multiple `luna.*` modules |
| `library/` | Tests for `library/` Lunasome modules |
| `stress/` | Performance and capacity tests |
| `security/` | Lua sandbox and input validation tests |
| `golden/` | Deterministic output comparison tests |
| `performance/` | Benchmark helpers and timing tests |
| `config/` | Engine configuration tests |
| `examples/` | Example validation scripts |
| `fixtures/` | Shared Lua test assets (data files, scripts) |

## BDD Framework API

All functions are provided by `tests/lua/init.lua` and available globally in every test file.

### Structure

```lua
describe("module.subfeature", function()
    it("does the expected thing", function()
        -- assertions here
    end)
end)

test_summary()  -- REQUIRED — must be the last line in every test file
```

### Assertion Functions

| Function | What it checks |
|---|---|
| `expect_equal(a, b)` | `a == b` (strict equality) |
| `expect_not_equal(a, b)` | `a ~= b` |
| `expect_near(a, b, tol?)` | `math.abs(a-b) < tol` (default tol: 1e-5) |
| `expect_true(v)` | `v` is truthy |
| `expect_false(v)` | `v` is falsy |
| `expect_nil(v)` | `v == nil` |
| `expect_not_nil(v)` | `v ~= nil` |
| `expect_type(v, t)` | `type(v) == t` |
| `expect_error(fn)` | `fn()` raises an error |
| `expect_no_error(fn)` | `fn()` does not raise |
| `expect_contains(str, sub)` | `string.find(str, sub)` succeeds |

### `test_summary()`

**Mandatory** — must be the last statement in every test file. Prints total/pass/fail counts.
If any test failed, the Rust harness marks the test as failed.

## Adding a New Test

1. Create `tests/lua/unit/test_<module>.lua`:

```lua
describe("<module> basic API", function()
    it("creates an object", function()
        local obj = luna.<module>.new()
        expect_not_nil(obj)
    end)

    it("returns expected value", function()
        local result = luna.<module>.compute(1, 2)
        expect_equal(result, 3)
    end)
end)

test_summary()
```

2. Register in `tests/lua/harness.rs`:

```rust
#[test]
fn lua_test_<module>() {
    run_lua_test("unit/test_<module>.lua");
}
```

3. Run: `cargo test lua_test_<module>`

## Constraints

- Lua tests **must not** call `luna.graphics.draw*`, `luna.audio.*`, or anything requiring a window
- Tests must not write files outside `target/`
- Every test file **must** end with `test_summary()`
- New `luna.*` API functions require at least one Lua test before merge

## Test Naming Conventions

- File: `test_<module>.lua` — matches the `luna.<module>` namespace
- `describe` block: `"<module>.<subfeature>"` or `"<module> <behaviour>"`
- `it` block: starts with a verb — `"creates"`, `"returns"`, `"raises an error when"`, `"does not"`, ...

## Library Tests (`library/`)

Tests for `library/` Lunasome modules live in `tests/lua/library/`:

```
tests/lua/library/test_library_<name>.lua
```

These use the same BDD framework and are registered in `harness.rs` as:

```rust
#[test]
fn lua_test_library_<name>() {
    run_lua_test("library/test_library_<name>.lua");
}
```
