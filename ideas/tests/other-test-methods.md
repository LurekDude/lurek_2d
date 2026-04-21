# Other Testing Methodologies

**Status**: 🔶 PARTIALLY IMPLEMENTED
- ✅ Property-based tests: `tests/lua/unit/test_math_property.lua` created and registered
- ❌ Data/serial/image/physics property tests: not yet created
- ❌ Fuzz testing file `tests/lua/security/test_api_fuzz.lua`: exists but may need expansion
- ❌ Mutation testing, contract testing: not yet implemented

**Purpose**: Document additional testing strategies not yet used in Lurek2D that would improve coverage quality, discover edge-case bugs, and increase confidence in correctness.

---

## 1. Property-Based Testing

**What it is**: Generate random inputs and verify invariant properties hold, rather than checking fixed expected values.

**Why it matters**: Fixed tests reveal bugs only where the author thought to look. Property tests probe the full input space.

**Applicability to Lurek2D**: High — many math/physics functions have mathematical invariants.

### Example Properties to Test

| Module | Property | Invariant |
|--------|----------|-----------|
| `math` | `Vec2:normalized()` | Length always ≈ 1.0 |
| `math` | `lerp(a,b,0)` | Always == a |
| `math` | `lerp(a,b,1)` | Always == b |
| `physics` | Apply impulse then measure velocity | `v = impulse / mass` (within tolerance) |
| `data` | `encode(decode(x)) == x` | Round-trip for any serializable table |
| `serial` | Encrypt → Decrypt | Always recovers original bytes |
| `image` | `getPixel(setPixel(x,y,c))` | Returns c for any valid color |
| `math` | `easing.*` at t=0 | Always ≈ 0; at t=1 always ≈ 1 |
| `tilemap` | `getTile(setTile(x,y,id))` | Returns id for any valid coordinate |
| `camera` | `worldToScreen(screenToWorld(p))` | Round-trip ≈ p |

### Implementation (Lua)

```lua
-- tests/lua/unit/test_math_property.lua
-- Property-based: random Vec2 normalization invariant

local function random_vec2(scale)
    scale = scale or 100
    return lurek.math.vec2(
        (math.random() - 0.5) * scale,
        (math.random() - 0.5) * scale
    )
end

describe("Vec2:normalized property", function()
    -- @covers Vec2:normalized
    it("always has length ≈ 1.0 for any non-zero input", function()
        math.randomseed(42)  -- fixed seed for reproducibility
        for i = 1, 200 do
            local v = random_vec2(100)
            if v:length() > 0.0001 then  -- skip near-zero
                local n = v:normalized()
                expect_near(1.0, n:length(), 0.001,
                    string.format("iteration %d: length should be 1", i))
            end
        end
    end)

    it("lerp at t=0 always returns start value", function()
        math.randomseed(99)
        for i = 1, 100 do
            local a = random_vec2()
            local b = random_vec2()
            local result = lurek.math.lerp(a, b, 0.0)
            expect_near(a.x, result.x, 0.0001)
            expect_near(a.y, result.y, 0.0001)
        end
    end)
end)
test_summary()
```

### Recommended New Test Files

- `tests/lua/unit/test_math_property.lua` — Vec2/Mat3/Rect invariants
- `tests/lua/unit/test_data_property.lua` — encode/decode round-trips for all supported types
- `tests/lua/unit/test_serial_property.lua` — encrypt/decrypt invariant with random key+data
- `tests/lua/unit/test_image_property.lua` — pixel get/set round-trip for all color components
- `tests/lua/unit/test_physics_property.lua` — impulse/velocity, AABB containment

---

## 2. Fuzz Testing (Nil/Type Spam)

**What it is**: Pass invalid, extreme, or unexpected inputs to every API function to find crashes, panics, and bypass failures.

**Why it matters**: Lua's dynamic type system means users can pass anything. The engine must degrade gracefully, not panic.

**Lurek2D constraint**: The Lua sandbox must never allow Lua code to trigger a Rust panic or bypass security checks.

### Fuzzing Strategy

Three categories of fuzz inputs:

| Category | Inputs |
|----------|--------|
| Nil spam | Pass `nil` for every required argument |
| Wrong type | Pass string where number expected, table where string expected, etc. |
| Extreme values | `math.huge`, `-math.huge`, `0`, `2^53`, negative radii, NaN |

### Example Fuzz Test

```lua
-- tests/lua/security/test_api_fuzz.lua
-- Nil-spam and type fuzz for core APIs

local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    expect_true(ok or type(err) == "string",
        "function must not panic (non-string error is a panic indicator)")
    if not ok then
        expect_true(type(err) == "string", "error must be a descriptive string, not: " .. type(err))
    end
end

describe("lurek.render nil/fuzz safety", function()
    it("rectangle rejects nil args without panic", function()
        safe(lurek.render.rectangle, nil, nil, nil, nil, nil)
    end)
    it("rectangle rejects wrong types", function()
        safe(lurek.render.rectangle, "fill", "not_a_number", "nope", 10, 10)
    end)
    it("rectangle with NaN dimensions", function()
        safe(lurek.render.rectangle, "fill", 0/0, 0/0, 0/0, 0/0)
    end)
    it("setColor with extreme values", function()
        safe(lurek.render.setColor, math.huge, -math.huge, 2, -1)
    end)
end)

describe("lurek.physics nil/fuzz safety", function()
    it("newWorld with nil gravity", function()
        safe(lurek.physics.newWorld, nil)
    end)
    it("newBody with wrong table shape", function()
        safe(lurek.physics.newBody, {not_a_world = true})
    end)
end)

test_summary()
```

### Where to Focus Fuzz Tests

Priority modules ranked by attack surface (see `ideas/tests/security-testing-plan.md`):
1. `lurek.filesystem.*` — path traversal risk
2. `lurek.render.*` — resource loading
3. `lurek.audio.*` — file decoding
4. `lurek.data.*` — parser injection
5. `lurek.serial.*` — encryption inputs
6. `lurek.lua_api` — UserData lifetime and double-release

---

## 3. Mutation Testing

**What it is**: Introduce small code mutations (flip a `<` to `<=`, change a constant, negate a boolean) and verify that existing tests detect the mutation (i.e., at least one test fails).

**Why it matters**: If tests pass after a mutation, they are not testing the behavior the mutation affects. This measures "test strength" beyond coverage.

**Tool recommendation for Rust**: Use `cargo-mutants` (cargo install cargo-mutants) to automatically mutate Rust code and report which mutations survive.

### How to Run

```powershell
cargo install cargo-mutants
cargo mutants --test-output=auto --module math   # mutate only math module
cargo mutants --jobs 4 --module physics          # parallel mutation testing
```

### Mutation Testing Workflow

1. Run `cargo mutants --module <module>` on a module
2. Review "survived mutants" — any mutation that doesn't fail a test is a gap
3. Write new tests that target the exact behavior the surviving mutant exercises
4. Re-run to confirm the mutant is now caught

### Priority Modules for Mutation Testing

- `src/math/` — pure functions, ideal for mutation testing
- `src/physics/` — AABB overlap, collision resolution
- `src/engine/config.rs` — config parsing boundary conditions
- `src/lua_api/*.rs` — Lua validation boundaries (nil checks, range clamps)

---

## 4. Load Testing (Sustained 60 FPS Budget)

**What it is**: Run the engine under realistic game workloads for an extended period (10–60 minutes) and verify that frame time stays within budget, no memory leaks occur, and no performance degradation appears.

**Differs from stress tests**: Stress tests measure peak throughput. Load tests measure sustained operation stability.

### Load Test Scenarios

| Scenario | Duration | Budget |
|----------|----------|--------|
| 500 entities + full physics | 10 min | ≤16ms/frame |
| 200 particles + 10 lights | 5 min | ≤16ms/frame |
| 50k tiles + camera pan | 10 min | ≤16ms/frame |
| Audio bus + 20 sources | 5 min | ≤16ms/frame |
| AI grid pathfinding × 100 agents | 5 min | ≤16ms/frame |

### Implementation

Load tests are runtime-only (full engine, no headless). Create `tests/rust/ext/load_tests.rs` with environment-guarded tests:

```rust
#[test]
#[cfg(feature = "load_tests")]  // behind a feature flag — not run in normal CI
fn sustained_entity_physics_60fps_10min() {
    // Run example, capture frame times, assert p99 < 16ms, no GC stall > 16ms
}
```

Enable with: `cargo test --features load_tests -- load_`

---

## 5. Visual Regression Testing

**What it is**: Capture screenshots of known-good rendering states, commit them as baselines, and fail the build if a future render differs beyond a tolerance.

**Differs from golden tests**: Golden tests compare exact bytes (encoding, hashes). Visual regression tests compare images with a pixel-diff tolerance to allow minor rendering variations across GPU drivers.

### Tool Recommendation

Use `imagemagick compare` or a pure-Rust image diff crate (`image` + pixel RMSE calculation).

### Workflow

```powershell
# 1. Generate baseline (first run / intentional update)
cargo run --features smoke -- content/demos/hello_world --save-screenshot tests/rust/golden/expected/visual/hello_world.png

# 2. Normal CI run — compare to baseline
cargo test --test visual_regression_tests
```

### Tolerance Levels

| Scene Type | Pixel RMSE Tolerance |
|-----------|---------------------|
| UI / text | 1.0 (very strict) |
| Geometric shapes | 2.0 |
| Particle systems | 8.0 (high variance) |
| Full game scenes | 4.0 |

---

## 6. Contract Testing (API vs Documentation)

**What it is**: Verify that every function in `docs/API/lua-api.md` is actually callable and returns the documented type. If the doc says a function returns a `number`, a contract test calls it and asserts `type(result) == "number"`.

**Why it matters**: API breakages between Rust and Lua bindings often happen silently — the function exists but returns the wrong type or uses a renamed field.

### Implementation

Generate contract tests automatically from `lua_api_data.json`:

```python
# tools/gen_contract_tests.py
# For each function in lua_api_data.json that has a return type annotation:
# Emit: it("lurek.X.Y returns documented type", function()
#           local result = lurek.X.Y(minimalArgs)
#           expect_equal("number", type(result))
#       end)
```

The generated file goes to `tests/lua/unit/test_contracts_auto.lua` (generated, git-ignored, run on demand).

### Priority

Run contract tests after every `gen_lua_api_data.py` regeneration to immediately catch binding regressions.

---

## 7. Cross-Platform CI Matrix

**What it is**: Run the full test suite on multiple OS + architecture combinations in CI to catch platform-specific bugs before they reach users.

**Lurek2D constraint (A-02)**: Desktop only — Windows/Linux/macOS x86_64 + ARM.

### Recommended Matrix

| OS | Arch | CI Runner | Priority |
|----|------|-----------|----------|
| Windows 11 | x86_64 | `windows-latest` | P0 (primary dev OS) |
| Ubuntu 24.04 | x86_64 | `ubuntu-latest` | P0 (CI default) |
| macOS 14 | ARM (Apple Silicon) | `macos-latest` | P1 |
| Ubuntu 24.04 | ARM | `ubuntu-24.04-arm` | P2 |

### Tests to Run Per Platform

- `cargo test` (all tests, headless only — no GPU or audio device in CI)
- `cargo clippy -- -D warnings`
- `cargo fmt --check`
- `python tools/validate/cag_validate.py` (CAG validation)

Platform-specific exclusions: tests requiring GPU, audio device, or display are gated behind `#[cfg(feature = "smoke_tests")]`.

---

## 8. Demo Smoke Tests

**What it is**: Each demo in `content/demos/` launches, runs for a short time (3 seconds), and exits successfully without error. This proves demos don't crash on startup and can complete one full update loop.

**Infrastructure**: `tests/rust/ext/` already has smoke test infrastructure. See `tests/rust/ext/smoke_support.rs`.

### Required Coverage

Every demo must have a corresponding smoke test:

```
content/demos/action/         → tests/rust/ext/demo_smoke_action.rs
content/demos/arcade/         → tests/rust/ext/demo_smoke_arcade.rs
content/demos/retro/          → tests/rust/ext/demo_smoke_retro.rs
content/demos/rpg/            → tests/rust/ext/demo_smoke_rpg.rs
content/demos/showcase/       → tests/rust/ext/demo_smoke_showcase.rs
content/demos/simulation/     → tests/rust/ext/demo_smoke_simulation.rs
content/demos/sports/         → tests/rust/ext/demo_smoke_sports.rs
content/demos/strategy/       → tests/rust/ext/demo_smoke_strategy.rs
```

### Smoke Test Pattern

```rust
// tests/rust/ext/demo_smoke_showcase.rs
#[test]
#[cfg(feature = "smoke_tests")]
fn demo_smoke_showcase_hello_world() {
    run_demo_smoke("content/demos/showcase/hello_world", 3_000)
        .expect("hello_world demo must start and run for 3 seconds without error");
}
```

---

## Summary and Priority

| Method | Effort | Impact | Recommended |
|--------|--------|--------|-------------|
| Property-based testing | Low | High | Yes — start with `math` module |
| Fuzz testing (nil/type spam) | Low | High | Yes — run on security-sensitive APIs |
| Mutation testing | Medium | Very High | Yes — after coverage reaches 20%+ marker |
| Load testing | High | Medium | Later — after frame time optimization |
| Visual regression testing | Medium | High | Yes — after canvas pixel evidence done |
| Contract testing | Low | High | Yes — auto-generate from lua_api_data.json |
| Cross-platform CI matrix | Medium | High | Yes — essential for desktop engine |
| Demo smoke tests | Low | High | Yes — each demo must have one |
