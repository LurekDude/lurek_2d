# Lua Test Improvement Suggestions

**Status**: 🔶 PARTIALLY IMPLEMENTED
- ✅ Item 5: `before_each` / `after_each` helpers added to `tests/lua/init.lua`
- ✅ Item 10: `measure()` helper added to `tests/lua/init.lua` (stress test standardization)
- ✅ Item 11: `expect_canvas_pixel()` helper added to `tests/lua/init.lua`
- ✅ Item 13: golden tests use inline `string.format("%.6f", ...)` for cross-platform determinism
- ✅ Item 9: integration tests verified to exercise 2+ lurek.* namespaces
- ❌ Item 1: error-path describe blocks for physics/graphics/entity/tilemap/audio — not yet done
- ❌ Item 2: systematic nil-argument audit — not yet done
- ❌ Item 6: float comparison audit across all tests — not yet done
- ❌ Item 12: splitting large test files (test_physics.lua, test_ai.lua) — not yet done
- ❌ Item 15: test data factory helpers (`make_test_world()` etc.) — not yet done

**Purpose**: General quality improvements for the Lua test suite beyond coverage gaps.

## 1. Error-Path Testing

**Problem**: Most tests only verify the happy path. Lua scripts in production will pass invalid arguments, nil values, and garbage data.

**Recommendation**: Every module's unit test should have a dedicated `describe("error handling", ...)` block that:

- Passes nil where a table is expected → expects LuaError
- Passes wrong types (string where number expected) → expects LuaError
- Passes out-of-range values (negative sizes, NaN, infinity) → expects error or graceful handling
- Calls methods on destroyed/released objects → expects error

**Example**:
```lua
-- @covers lurek.physics.newBody
describe("lurek.physics error handling", function()
    it("newBody rejects nil world", function()
        expect_error(function() lurek.physics.newBody(nil, 0, 0) end)
    end)
    it("newBody rejects NaN position", function()
        expect_error(function() lurek.physics.newBody(world, 0/0, 0) end)
    end)
end)
```

**Priority modules**: physics, graphics, entity, tilemap, audio — these have UserData objects that can be stale/destroyed.

## 2. Nil-Argument Coverage

**Problem**: Some APIs silently accept nil and return nil or defaults, others crash. Behavior is inconsistent.

**Recommendation**: Add a systematic nil-argument audit. For each API function with parameters, test:
```lua
it("handles nil gracefully", function()
    -- Should either return nil/default or throw a descriptive error
    -- Must NOT crash the VM or panic
    local ok, err = pcall(function() lurek.module.fn(nil) end)
    -- Either ok is true (graceful) or err contains a descriptive message
    if not ok then
        expect_type("string", err)
    end
end)
```

## 3. Type Coercion Edge Cases

**Problem**: LuaJIT auto-coerces strings to numbers in some contexts. Tests should verify the engine handles this correctly.

**Recommendation**: Test string-to-number coercion for numeric APIs:
```lua
it("accepts numeric strings", function()
    -- This may work due to Lua coercion, or fail with a clear error
    local ok = pcall(function() lurek.math.sin("1.5") end)
    -- Document the expected behavior
end)
```

## 4. Deterministic Seed Patterns

**Problem**: Random/procedural APIs are non-deterministic by default, making tests flaky.

**Recommendation**: Always use fixed seeds in tests:
```lua
describe("noise functions", function()
    before_each(function()
        lurek.math.setSeed(42)  -- deterministic seed
    end)
    it("perlin noise is reproducible with same seed", function()
        local a = lurek.math.noise(0.5, 0.5)
        lurek.math.setSeed(42)
        local b = lurek.math.noise(0.5, 0.5)
        expect_equal(a, b)
    end)
end)
```

## 5. before_each / after_each Usage

**Problem**: Many tests create shared state at the top of describe blocks without proper cleanup, risking test coupling.

**Recommendation**: Use `before_each` for setup and `after_each` for cleanup:
```lua
describe("entity system", function()
    local world
    before_each(function()
        world = lurek.ecs.newWorld()
    end)
    after_each(function()
        if world then world:destroy() end
    end)
end)
```

## 6. Float Comparison Consistency

**Problem**: Some tests use `expect_equal` for floats, which can fail due to precision.

**Recommendation**: Audit all `expect_equal` calls on floating-point values. Replace with `expect_near(expected, actual, tolerance)`. Default tolerance: 1e-5 for most operations, 1e-3 for physics simulations, 1e-10 for pure math.

## 7. Test Organization Headers

**Problem**: Long test files lack visual structure.

**Recommendation**: Use section comment headers:
```lua
-- ── Constructor Tests ─────────────────────
describe("constructors", function() ... end)

-- ── Property Tests ────────────────────────
describe("properties", function() ... end)

-- ── Method Tests ──────────────────────────
describe("methods", function() ... end)

-- ── Error Handling ────────────────────────
describe("error handling", function() ... end)
```

## 8. Pending/Skip Documentation

**Problem**: `xit()` and `pending()` are used without explaining why a test is skipped.

**Recommendation**: Always provide a reason string:
```lua
xit("should handle streaming audio", function()
    -- pending: streaming audio not yet implemented (issue #123)
end)
pending("MIDI support requires SoundFont loading")
```

## 9. Integration Test Purity

**Problem**: 4 integration tests are actually single-module tests (system, devtools, debugbridge, docs).

**Recommendation**: Move these to `tests/lua/unit/` or merge into existing unit test files. Integration tests should always exercise 2+ distinct `lurek.*` namespaces.

## 10. Stress Test Standardization

**Problem**: Stress tests use ad-hoc timing and reporting. No standard output format.

**Recommendation**: Add a `measure()` helper to `tests/lua/init.lua`:
```lua
function measure(name, count, fn)
    local start = lurek.timer.getTime()
    fn()
    local elapsed = lurek.timer.getTime() - start
    local ops_per_sec = count / elapsed
    print(string.format("[PERF] %s: %d ops in %.3fs (%.0f ops/sec)",
        name, count, elapsed, ops_per_sec))
    return elapsed, ops_per_sec
end
```

## 11. Canvas-Based Evidence for Headless Tests

**Problem**: Graphics tests only verify function existence, not visual output.

**Recommendation**: Use `Canvas:renderTo` + `Canvas:getPixel` for headless visual verification:
```lua
-- Draw red rectangle and verify red pixels exist
local canvas = lurek.render.newCanvas(100, 100)
canvas:renderTo(function()
    lurek.render.setColor(1, 0, 0)
    lurek.render.rectangle("fill", 0, 0, 100, 100)
end)
local r, g, b, a = canvas:getPixel(50, 50)
expect_near(1.0, r, 0.01) -- red pixel proves rectangle was drawn
```

**This is the single most impactful improvement** — it turns graphics tests from existence checks into functional evidence tests.

## 12. Test File Size Limits

**Problem**: Some unit test files are very large (test_physics.lua, test_ai.lua).

**Recommendation**: Split files exceeding 500 lines into focused sub-tests:
- `test_physics.lua` → `test_physics_body.lua`, `test_physics_joint.lua`, `test_physics_world.lua`
- `test_ai.lua` → `test_ai_fsm.lua`, `test_ai_bt.lua`, `test_ai_goap.lua`

## 13. Cross-Platform Determinism

**Problem**: Float formatting and line endings may differ across Windows/Linux/macOS.

**Recommendation for golden tests**: Use `string.format("%.6f", value)` with fixed precision. Normalize line endings in comparison helpers. Store golden baselines as inline data in tests (not external files) to avoid encoding issues.

## 14. Test Data Factory Patterns

**Problem**: Tests duplicate setup code for creating test fixtures (worlds, entities, grids).

**Recommendation**: Add test helpers for common fixtures:
```lua
-- In tests/lua/init.lua or a helpers module
function make_test_world()
    local world = lurek.physics.newWorld(0, 980)
    return world
end

function make_test_grid(w, h)
    local grid = lurek.pathfind.newGrid(w, h)
    return grid
end
```

## 15. Boundary Value Testing

**Problem**: Tests often use "normal" values but miss boundary conditions.

**Recommendation**: Systematically test:
- Zero values: `0, 0.0, ""`
- Minimum/maximum: `math.huge, -math.huge, 2^31-1`
- Empty collections: `{}, "", nil`
- Single-element: `{1}`, single character strings
- Special floats: `0/0 (NaN), 1/0 (inf), -1/0 (-inf)`
