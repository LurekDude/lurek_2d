# Test Marker Annotation Design

**Status**: ✅ IMPLEMENTED — `-- @covers lurek.<module>.<function>` markers are in active use across unit tests. Scanner integrated in `tools/audit/lua_api_test_coverage.py`.

**Purpose**: Replace heuristic substring matching with precise, machine-parseable API coverage markers in Lua test files.

## Problem Statement

Current `test_coverage.py` uses substring matching to detect API coverage:
- `setColor` in test file → matches even if it's `gfx.setColor` in a physics test
- Short names like `set`, `get`, `add` produce widespread false positives
- No way to distinguish "intentionally tested" from "incidentally mentioned"
- Estimated 12–18% false-positive rate inflates coverage numbers

## Marker Syntax

### `@covers` — API Coverage Marker

```lua
-- @covers lurek.math.sin
-- @covers lurek.math.cos
-- @covers lurek.math.tan
describe("trigonometric functions", function()
    it("sin returns correct values", function()
        expect_near(0.0, lurek.math.sin(0), 1e-10)
        expect_near(1.0, lurek.math.sin(lurek.math.pi / 2), 1e-10)
    end)
end)
```

### Rules

1. **Syntax**: `-- @covers lurek.<module>.<function>` or `-- @covers <ClassName>:<methodName>`
2. **Placement**: Before `describe()` or `it()` — applies to the block that immediately follows
3. **Scope**: A `@covers` on `describe` applies to ALL `it()` blocks inside it
4. **Multiplicity**: Multiple `@covers` lines can appear before a single block
5. **Granularity**: Always specify the exact function/method name — never just the module
6. **Regex**: `^--\s*@covers\s+(lurek\.\w+\.\w+|[\w]+:[\w]+)\s*$`

### Additional Tags

```lua
-- @covers lurek.graphics.saveScreenshot
-- @evidence file:save/screenshot.png
-- @evidence log:screenshot saved
describe("screenshot saving", function() ... end)
```

| Tag | Meaning | Values |
|-----|---------|--------|
| `@covers` | Which API function/method this test exercises | `lurek.module.fn` or `Class:method` |
| `@evidence` | What runtime artifact proves it works | `file:<path>`, `screenshot:<path>`, `audio:<path>`, `log:<pattern>` |
| `@golden` | This test produces deterministic output for snapshot comparison | `golden:<baseline_file>` |
| `@stress` | This test measures throughput | `stress:<metric_name>` |

### Backward Compatibility

- **Existing tests without markers continue to work** — the scanner falls back to heuristic matching for unmarked files
- `--strict` mode only counts `@covers` markers, ignoring heuristic matches
- New tests SHOULD have markers; existing tests get markers added incrementally

## Examples

### Before (current)
```lua
describe("lurek.gfx color functions", function()
    it("setColor accepts 3 args", function()
        expect_no_error(function()
            lurek.gfx.setColor(1, 0, 0)
        end)
    end)
end)
```

### After (with markers)
```lua
-- @covers lurek.gfx.setColor
-- @covers lurek.gfx.setBackgroundColor
describe("lurek.gfx color functions", function()
    it("setColor accepts 3 args", function()
        expect_no_error(function()
            lurek.gfx.setColor(1, 0, 0)
        end)
    end)
    
    it("setBackgroundColor accepts 3 args", function()
        expect_no_error(function()
            lurek.gfx.setBackgroundColor(0.1, 0.1, 0.1)
        end)
    end)
end)
```

### Method Coverage Example
```lua
-- @covers Vec2:length
-- @covers Vec2:normalize
-- @covers Vec2:dot
describe("Vec2 operations", function()
    it("length of unit vector is 1", function()
        local v = lurek.math.newVec2(1, 0)
        expect_near(1.0, v:length(), 1e-10)
    end)
    
    it("normalize produces unit length", function()
        local v = lurek.math.newVec2(3, 4)
        local n = v:normalize()
        expect_near(1.0, n:length(), 1e-10)
    end)
end)
```

### Evidence Test Example
```lua
-- @covers lurek.gfx.rectangle
-- @evidence log:DrawCommand::Rectangle
describe("rectangle drawing", function()
    it("rectangle produces draw command", function()
        lurek.gfx.rectangle("fill", 10, 10, 100, 50)
        -- In headless mode, verify the draw command was queued
        -- Evidence: log output confirms DrawCommand was created
    end)
end)
```

## Scanner Integration

The new `tools/audit/lua_api_test_coverage.py` script will:

1. Load `docs/logs/lua_api_data.json` for the canonical API function list
2. Scan all `tests/lua/**/*.lua` files for `-- @covers` markers
3. Match markers against the canonical list
4. Report: total covered, per-module coverage, orphaned markers (typos)
5. Fall back to heuristic for unmarked files (unless `--strict`)
6. Output JSON to `docs/logs/lua_api_test_coverage.json`

### Scanner Output Schema

```json
{
  "meta": {
    "generated": "2026-04-09T...",
    "mode": "hybrid|strict",
    "total_api_functions": 2588,
    "marker_covered": 450,
    "heuristic_covered": 1693,
    "total_covered": 2143,
    "coverage_pct": 82.8
  },
  "modules": {
    "math": {
      "total": 132,
      "marker_covered": 20,
      "heuristic_covered": 34,
      "uncovered": ["Vec2:set", "Mat3:inverse", ...],
      "test_files": ["test_math.lua", "test_math_golden.lua"]
    }
  },
  "orphaned_markers": [
    {"file": "test_foo.lua", "line": 5, "marker": "lurek.foo.nonexistent"}
  ]
}
```

## Implementation Priority

1. **Phase 1**: Define marker regex and scanner script (no test file changes)
2. **Phase 2**: Add markers to lowest-coverage modules first (system, math, log, network, modding)
3. **Phase 3**: Add markers to all remaining unit tests
4. **Phase 4**: Make `--strict` mode the default in CI
