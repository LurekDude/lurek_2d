# Describe-Block Coverage Tracking

**Status**: ❌ NOT YET IMPLEMENTED — This is a design document for a scanner extension that would parse `describe("lurek.x.y", ...)` naming conventions. The naming convention itself is partially adopted; the automated scanner extension has not been built yet.

**Purpose**: Design a convention and tooling for tracking per-method test coverage directly from the `describe()` call hierarchy in Lua test files. Rather than post-hoc scanning, the test structure itself declares what is being tested.

---

## The Core Idea

The BDD `describe()` call name becomes the coverage declaration when it follows a specific naming convention:

```lua
describe("lurek.audio.newBus", function()    -- 1 method under test
    it("creates a new audio bus", function() ... end)
    it("bus has volume 1.0 by default", function() ... end)
    it("bus name must not be empty", function() ... end)
end)

describe("AudioBus:setVolume", function()    -- 1 method under test
    it("sets volume between 0 and 1", function() ... end)
    it("volume clamped to 0 below", function() ... end)
end)
```

A scanner can parse the string argument of `describe()` and recognize patterns like:
- `"lurek.<module>.<function>"` → module-level function
- `"<ClassName>:<method>"` → UserData method
- `"lurek.<module> error handling"` → error tests for entire module (no specific method)
- Any other string → general describe block, not mapped to API

---

## Benefits Over `@covers` Markers

| Approach | Pros | Cons |
|----------|------|------|
| `-- @covers` before block | Explicit, grep-able, decoupled from structure | Requires separate annotation, easy to forget |
| `describe("lurek.x.y", ...)` naming | Tests are self-documenting, works with existing tools | Changes describe display names, requires naming discipline |
| **Both combined** | `-- @covers` for inline `it()` tests; `describe()` name convention for method grouping | Small redundancy | 

**Recommendation**: Use both. `describe("lurek.audio.newBus", ...)` is the primary declaration. `-- @covers` is used within `it()` blocks when a single `it()` tests multiple API functions.

---

## Naming Convention

### Recognized Patterns

```
"lurek.<module>.<function>"          → maps to that exact function
"<ClassName>:<method>"               → maps to UserData method
"lurek.<module> -- <anything>"       → module-scoped, all functions (partial declaration)
"<method> on <ClassName>"            → UserData method (alternative style, avoid)
```

### Examples

```lua
-- Module function
describe("lurek.physics.newWorld", function()
    it("creates world with gravity vector", ...)
    it("default gravity is (0, 980)", ...)
    it("accepts nil gravity for zero-g world", ...)
    it("rejects negative max body count", ...)
end)

-- UserData method
describe("PhysicsWorld:addBody", function()
    it("adds body to world", ...)
    it("duplicate add is idempotent", ...)
end)

-- Error handling group (module-scoped)
describe("lurek.physics error handling", function()
    it("newWorld rejects NaN gravity", ...)
    it("newBody rejects destroyed world", ...)
end)
```

### What NOT to name describes

```lua
-- Too vague — not scannable:
describe("physics tests", ...)
describe("basic operations", ...)
describe("world tests", ...)

-- Correct:
describe("lurek.physics.newWorld", ...)
describe("lurek.physics.stepWorld", ...)
```

---

## Count Tracking per Describe

Each `describe("lurek.x.y", ...)` block automatically contributes:
- **Covered**: 1 (the function is tested)
- **Test count**: number of `it()` calls inside (depth-1 children)
- **Error tests**: boolean (does any `it()` use `expect_error` or `pcall`)
- **Evidence type**: inferred from `-- @evidence` annotation on the describe or its `it()` calls

### Scanner Output per Method

```json
{
  "lurek.physics.newWorld": {
    "test_count": 4,
    "has_error_tests": true,
    "has_nil_tests": true,
    "evidence_types": [],
    "files": ["tests/lua/unit/test_physics.lua"],
    "describe_line": 12
  },
  "PhysicsWorld:addBody": {
    "test_count": 2,
    "has_error_tests": false,
    "has_nil_tests": false,
    "evidence_types": [],
    "files": ["tests/lua/unit/test_physics.lua"],
    "describe_line": 45
  }
}
```

---

## What "Well-Covered" Means — Scoring

A function is **well-covered** when its `describe` block meets:

| Criterion | Minimum | Good | Excellent |
|-----------|---------|------|-----------|
| Tests count | ≥1 | ≥3 | ≥5 |
| Error test | No | Yes | Yes |
| Nil/boundary | No | No | Yes |
| Evidence | None | State | Pixel/File |

**Coverage score per method** (0–4):
- +1 test exists
- +1 has ≥3 tests
- +1 has error test
- +1 has evidence (any tier)

**Module coverage score**: average across all methods × 25 = 0–100%.

---

## Python Scanner Extension: Describe-Name Parsing

Extend `tools/audit/lua_api_test_coverage.py` with a new scan mode:

```python
DESCRIBE_RE = re.compile(
    r'describe\(\s*["\']('
    r'lurek\.\w+\.\w+'           # lurek.module.function
    r'|[\w]+:[\w]+'              # ClassName:method
    r'|lurek\.\w+\s+\w[^"\']*'  # module-scoped groups
    r')["\']',
    re.MULTILINE
)

def scan_describe_blocks(lua_file: Path) -> list[dict]:
    """
    Return list of describe blocks with method name, test count, and flags.
    """
    text = lua_file.read_text(encoding='utf-8')
    results = []
    for m in DESCRIBE_RE.finditer(text):
        name = m.group(1).strip()
        # find matching closing paren / end
        # count nested `it(` calls (non-nested children only)
        it_count = count_direct_it_children(text, m.start())
        has_error_test = 'expect_error' in get_block_text(text, m.start())
        has_nil_test = 'nil' in get_block_text(text, m.start())
        evidence = extract_evidence_tags(get_block_text(text, m.start()))
        results.append({
            'name': name,
            'file': str(lua_file),
            'line': text[:m.start()].count('\n') + 1,
            'it_count': it_count,
            'has_error_test': has_error_test,
            'has_nil_test': has_nil_test,
            'evidence_types': evidence,
        })
    return results
```

---

## Example: Audio Module Test File Structure

This shows how a well-structured audio test file uses `describe()` naming to be fully scannable:

```lua
-- tests/lua/unit/test_audio.lua
-- Audio module unit tests - describe-named for coverage scanning

-- ── Source Management ─────────────────────────────────────────────
describe("lurek.audio.newSource", function()
    -- @covers lurek.audio.newSource
    it("creates static source from valid file path", function() ... end)
    it("creates streaming source from valid file path", function() ... end)
    it("returns error for non-existent file", function()
        expect_error(function() lurek.audio.newSource("nonexistent.wav") end)
    end)
    it("static source isLoaded() returns true", function() ... end)
end)

describe("AudioSource:play", function()
    -- @covers AudioSource:play
    it("sets isPlaying() to true", function() ... end)
    it("play on already-playing source is idempotent", function() ... end)
end)

describe("AudioSource:pause", function()
    -- @covers AudioSource:pause
    it("sets isPaused() to true", function() ... end)
    it("preserves playback offset", function()
        local s = make_test_source()
        s:play(); s:seek(0.5); s:pause()
        expect_near(0.5, s:getOffset(), 0.01)
    end)
end)

-- ── Bus Management ────────────────────────────────────────────────
describe("lurek.audio.newBus", function()
    -- @covers lurek.audio.newBus
    it("creates bus with given name", function() ... end)
    it("bus is retrievable by name", function() ... end)
    it("rejects empty string name", function()
        expect_error(function() lurek.audio.newBus("") end)
    end)
    it("rejects duplicate bus name", function()
        lurek.audio.newBus("test_bus_dup")
        expect_error(function() lurek.audio.newBus("test_bus_dup") end)
    end)
end)

describe("AudioBus:setVolume", function()
    -- @covers AudioBus:setVolume
    -- @covers AudioBus:getVolume
    it("volume stores and retrieves correctly", function()
        local bus = lurek.audio.newBus("vol_test")
        bus:setVolume(0.7)
        expect_near(0.7, bus:getVolume(), 0.001)
    end)
    it("volume clamped at 0", function()
        local bus = lurek.audio.newBus("clamp_lo")
        bus:setVolume(-1.0)
        expect_near(0.0, bus:getVolume(), 0.001)
    end)
    it("volume clamped at 1", function()
        local bus = lurek.audio.newBus("clamp_hi")
        bus:setVolume(999)
        expect_near(1.0, bus:getVolume(), 0.001)
    end)
end)

-- ── Error Handling ────────────────────────────────────────────────
describe("lurek.audio error handling", function()
    it("play on nil source returns error", function()
        expect_error(function() lurek.audio.newSource(nil) end)
    end)
    it("invalid sample rate raises descriptive error", function()
        local ok, err = pcall(function()
            lurek.audio.newSource("test.wav", {sampleRate = -1})
        end)
        expect_true(not ok, "should error")
        expect_type("string", err)
    end)
end)

test_summary()
```

**When the scanner runs on this file**, it produces:
- `lurek.audio.newSource`: 4 tests, error: yes, nil: no → score 3/4
- `AudioSource:play`: 2 tests, error: no → score 2/4
- `AudioSource:pause`: 2 tests, error: no → score 2/4
- `lurek.audio.newBus`: 4 tests, error: yes → score 3/4
- `AudioBus:setVolume/getVolume`: 3 tests, error: no → score 2/4
- Module error group: 2 tests, error: yes → mapped to module

Total audio coverage score: 5 methods, average score 2.4/4 = 60%.

---

## Migration Path

1. **Phase 1**: Rename existing `describe()` calls to match convention in one module (audio is recommended — most methods)
2. **Phase 2**: Add scanner support to `lua_api_test_coverage.py`
3. **Phase 3**: Display "describe coverage score" per module in analytics
4. **Phase 4**: CI gate on modules with score < 2/4 average
