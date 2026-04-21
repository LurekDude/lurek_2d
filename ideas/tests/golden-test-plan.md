# Golden Test Plan

**Status**: ✅ FULLY IMPLEMENTED — All 13 golden test files created (`tests/lua/golden/`): math, data, dataframe, pathfinding, graph, serial, compute, procgen, physics, ai, entity, tilemap, animation. All registered in `tests/lua/harness.rs`.

**Purpose**: Expand golden test coverage from 1 test (math) to comprehensive deterministic output verification across all modules with reproducible output.

## What Makes a Good Golden Test Candidate

1. **Deterministic**: Same input → same output every run (no randomness unless seeded)
2. **Serializable**: Output can be captured as text/binary
3. **Stable**: Output format unlikely to change between engine versions (unless API changes)
4. **Meaningful**: A change in output indicates a real regression, not just formatting noise

## Golden Test Architecture

### Directory Structure

```
tests/lua/golden/
├── test_math_golden.lua              (existing)
├── test_data_golden.lua              (NEW)
├── test_dataframe_golden.lua         (NEW)
├── test_pathfind_golden_grid.lua       (NEW)
├── test_graph_golden.lua             (NEW)
├── test_serial_golden.lua            (NEW)
├── test_compute_golden.lua           (NEW)
├── test_procgen_golden.lua           (NEW)
├── test_physics_golden.lua           (NEW)
├── test_tilemap_golden.lua           (NEW)
├── test_ai_golden.lua                (NEW)
├── test_ecs_golden.lua            (NEW)
└── expected/                         (baseline files)
    ├── math_constants.txt
    ├── data_json_roundtrip.txt
    ├── dataframe_operations.txt
    ├── pathfinding_astar.txt
    ├── graph_algorithms.txt
    ├── serial_encode.bin
    ├── compute_results.txt
    ├── procgen_noise.txt
    ├── physics_simulation.txt
    ├── tilemap_collision.txt
    ├── ai_fsm_trace.txt
    └── entity_hierarchy.txt
```

### Comparison Method

```lua
-- Golden test helper function (add to tests/lua/init.lua)
function expect_golden(name, actual_content)
    local golden_path = "tests/lua/golden/expected/" .. name
    local golden_file = io.open(golden_path, "r")
    if golden_file then
        local expected = golden_file:read("*a")
        golden_file:close()
        expect_equal(expected, actual_content, "golden mismatch: " .. name)
    else
        -- First run: create baseline
        local out = io.open(golden_path, "w")
        if out then
            out:write(actual_content)
            out:close()
            print("[GOLDEN] Created baseline: " .. golden_path)
        end
        -- Don't fail on first run
    end
end
```

**Note**: Due to headless Lua test constraints, golden comparisons will use string matching within the test rather than file I/O (which requires GameFS). The baseline values are hardcoded in the test file itself using `expect_equal`.

---

## Planned Golden Tests

### 1. Math Golden (existing — expand)

**File**: `test_math_golden.lua`
**Current**: Only trig identities (sin²+cos²=1)
**Expand with**:

| Test | Input | Expected Output | Tolerance |
|------|-------|-----------------|-----------|
| π constant | `lurek.math.pi` | `3.141592653589793` | exact (15 digits) |
| e constant | `lurek.math.exp(1)` | `2.718281828459045` | exact |
| √2 | `lurek.math.sqrt(2)` | `1.414213562373095` | exact |
| sin/cos table | 0°–360° at 15° steps | Fixed table of 25 values | 1e-10 |
| Vec2 normalize | `(3,4).normalize()` | `(0.6, 0.8)` | 1e-10 |
| Vec2 dot product | `(1,2)·(3,4)` | `11` | exact |
| Mat3 identity × point | `I × (5,7)` | `(5, 7)` | 1e-10 |
| Noise at fixed coords | `perlin(0.5, 0.5)` | Fixed value (seed-dependent) | 1e-6 |
| Bezier at t=0.5 | cubic bezier midpoint | Fixed coordinates | 1e-6 |
| Lerp values | lerp(0, 100, 0.25) | 25.0 | exact |

### 2. Data Serialization Golden (NEW)

**File**: `test_data_golden.lua`
**Verifies**: JSON/TOML/MessagePack round-trip produces identical output

| Test | Input | Method | Verify |
|------|-------|--------|--------|
| JSON round-trip | `{name="test", items={1,2,3}, nested={x=1}}` | `toJSON` → `fromJSON` → `toJSON` | output₁ == output₂ |
| TOML round-trip | `{[section]={key="value"}}` | `toTOML` → `fromTOML` → `toTOML` | output₁ == output₂ |
| JSON pretty print | fixed table | `toJSON(data, true)` | exact string match against baseline |
| Compression round-trip | 1000-char repeated string | `compress` → `decompress` | decompressed == original |
| MessagePack round-trip | `{1, "two", 3.0, true, nil}` | `pack` → `unpack` | values equal |

### 3. Dataframe Golden (NEW)

**File**: `test_dataframe_golden.lua`
**Verifies**: Column operations produce deterministic results

| Test | Operation | Verify |
|------|-----------|--------|
| Column sum | `df:sum("values")` on [1,2,3,4,5] | == 15 |
| Column mean | `df:mean("values")` on [1,2,3,4,5] | == 3.0 |
| Filter | `df:filter("x > 3")` on [1,2,3,4,5] | == [4,5] |
| Sort | `df:sort("name")` on ["c","a","b"] | == ["a","b","c"] |
| Group by + aggregate | group by category, sum values | exact match to baseline |
| Join | inner join on key column | exact match to baseline |

### 4. Pathfinding Golden (NEW)

**File**: `test_pathfind_golden_grid.lua`
**Verifies**: A* produces identical paths on fixed grids

| Test | Grid | Start→End | Expected Path |
|------|------|-----------|---------------|
| Simple 5×5 open | no walls | (0,0)→(4,4) | diagonal or L-shaped (deterministic) |
| 5×5 with wall | wall at row 2 | (0,0)→(4,4) | specific path around wall |
| 10×10 maze | fixed maze | (0,0)→(9,9) | specific path through maze |
| No path | surrounded start | (0,0)→(9,9) | nil/empty |
| Path cost | weighted grid | (0,0)→(4,4) | exact cost value |

### 5. Graph Algorithms Golden (NEW)

**File**: `test_graph_golden.lua`
**Verifies**: Graph algorithm results on fixed graphs

| Test | Graph | Algorithm | Expected |
|------|-------|-----------|----------|
| BFS order | 7-node tree | BFS from root | exact traversal order |
| DFS order | 7-node tree | DFS from root | exact traversal order |
| Shortest path | weighted 6-node | Dijkstra A→F | exact path + cost |
| Topological sort | 6-node DAG | topo sort | exact ordering |
| Connected components | 8-node, 3 components | find components | exact partition |
| Cycle detection | DAG vs cyclic | has_cycle | false, true |

### 6. Serial Encode Golden (NEW)

**File**: `test_serial_golden.lua`
**Verifies**: Binary encoding produces identical byte sequences

| Test | Input | Verify |
|------|-------|--------|
| u8 encoding | 42 | exact byte sequence |
| i32 encoding | -12345 | exact byte sequence |
| f64 encoding | 3.14159 | exact byte sequence |
| string encoding | "hello world" | exact byte sequence |
| table encoding | {1, "two", 3.0} | exact byte sequence |
| Nested table | {a={b={c=1}}} | exact byte sequence |

### 7. Compute Golden (NEW)

**File**: `test_compute_golden.lua`
**Verifies**: GPU compute operations produce deterministic results

| Test | Operation | Verify |
|------|-----------|--------|
| Vector add | [1,2,3] + [4,5,6] | == [5,7,9] |
| Matrix multiply | 2×2 × 2×2 | exact result |
| Reduction sum | sum([1..100]) | == 5050 |
| Map operation | map(x → x²) on [1..10] | == [1,4,9,...,100] |

### 8. Procgen Golden (NEW)

**File**: `test_procgen_golden.lua`
**Verifies**: Procedural generation with fixed seeds produces identical output

| Test | Generator | Seed | Verify |
|------|-----------|------|--------|
| Perlin noise 2D | 10×10 grid | seed=42 | exact value table |
| Simplex noise 2D | 10×10 grid | seed=42 | exact value table |
| Random dungeon | 20×20 | seed=123 | exact room positions |
| Name generator | 5 names | seed=456 | exact name list |

### 9. Physics Simulation Golden (NEW)

**File**: `test_physics_golden.lua`
**Verifies**: Physics simulation produces deterministic results for N steps

| Test | Setup | Steps | Verify |
|------|-------|-------|--------|
| Free fall | ball at y=100, gravity=980 | 60 steps at 1/60s | y position at each step (tolerance 1e-4) |
| Collision | two balls approaching | 120 steps | final positions (tolerance 1e-3) |
| Joint constraint | pendulum | 60 steps | angle at each step (tolerance 1e-3) |

**Note**: Physics golden tests use `expect_near` with tolerance due to floating-point accumulation across steps.

### 10. AI FSM Trace Golden (NEW)

**File**: `test_ai_golden.lua`
**Verifies**: FSM transitions produce deterministic state sequences

| Test | FSM | Events | Expected States |
|------|-----|--------|-----------------|
| Simple 3-state | idle→walk→run | ["start","speed_up"] | ["idle","walk","run"] |
| With conditions | patrol→chase→attack | ["see_enemy","in_range"] | ["patrol","chase","attack"] |
| Behavior tree | sequence of 3 actions | tick 3 times | [Running, Running, Success] |

### 11. Entity Hierarchy Golden (NEW)

**File**: `test_ecs_golden.lua`
**Verifies**: Entity component operations produce deterministic results

| Test | Setup | Verify |
|------|-------|--------|
| Add/remove components | entity with 3 components | component list matches |
| Parent-child hierarchy | 4-node tree | traversal order matches |
| System iteration | 10 entities, 2 systems | update order matches |

### 12. Tilemap Collision Golden (NEW)

**File**: `test_tilemap_golden.lua`
**Verifies**: Tilemap collision detection produces deterministic results

| Test | Map | Query | Expected |
|------|-----|-------|----------|
| Tile at position | 10×10 map | getTile(3,4) | specific tile ID |
| Collision tiles | 10×10 with walls | getCollisionTiles(rect) | specific tile list |
| Layer visibility | 3-layer map | toggle layers | specific visible state |

---

## Total: 21 golden test files (11 new algorithmic + 9 new visual/audio domain + 1 expanded)

---

## Phase 2 — Visual & Rendering Domain Golden Tests

These golden tests cover graphics processing, post-effects, image transforms, animation frame sequences, and Spine skeleton output. Because they involve pixel-level verification they use Canvas pixel readback (headless) or Rust golden harness PNG comparison (GPU required).

### Architecture Decision: Two-Track Approach

| Track | Location | Requires GPU? | Method |
|-------|----------|---------------|--------|
| State golden | `tests/lua/golden/` | No | Headless: compare draw-command lists or state snapshots as strings |
| Pixel golden | `tests/rust/golden/expected/image/` | Yes (ext smoke) | PNG byte comparison via Rust golden harness |

**Lua track** verifies the engine _generates_ the right draw commands and state. **Rust track** verifies the GPU _renders_ those commands to expected pixels.

---

### 13. Graphics Processing Golden (NEW)

**File**: `tests/lua/golden/test_render_golden.lua`
**Rust Golden**: `tests/rust/golden/expected/image/graphics_shapes.png`

#### State Golden (Headless — Lua)
Verify draw-command queue contents after graphics calls:

| Test | Call | Verify |
|------|------|--------|
| setColor | `setColor(0.5, 0.3, 0.7, 1)` | getColor() returns exact (0.5, 0.3, 0.7, 1) |
| rectangle state | `rectangle("fill", 10, 20, 100, 50)` | draw list contains 1 rect cmd at (10,20,100,50) |
| circle state | `circle("fill", 50, 50, 30)` | draw list contains 1 circle cmd at (50,50,r=30) |
| line state | `line(0,0,100,100)` | draw list contains 1 line cmd (0,0)→(100,100) |
| Color stack | push(red) → push(blue) → pop → getColor | getColor == red |
| Layer ordering | draw at z=5 then z=2 | draw list sorted by z ascending |
| Transform stack | translate(10,10) → draw at (0,0) → pop | draw position = (10,10) |

#### Canvas Pixel Golden (Headless — Lua)
```lua
describe("graphics.rectangle pixel evidence", function()
    it("fills red rectangle at known position", function()
        local canvas = lurek.render.newCanvas(64, 64)
        canvas:renderTo(function()
            lurek.render.setColor(1, 0, 0, 1)
            lurek.render.rectangle("fill", 16, 16, 32, 32)
        end)
        -- Inside rect — must be red
        local r, g, b, a = canvas:getPixel(32, 32)
        expect_near(1.0, r, 0.02)
        expect_near(0.0, g, 0.02)
        -- Outside rect — must be transparent
        local r2, g2, b2, a2 = canvas:getPixel(4, 4)
        expect_near(0.0, a2, 0.02)
    end)
end)
```

Pixel tests to add: circle, ellipse, line (AA edge pixels), polygon, arc, rounded rectangle, gradient fill.

---

### 14. Post-Processing Effects Golden (NEW)

**File**: `tests/lua/golden/test_postfx_golden.lua`
**Rust Golden**: `tests/rust/golden/expected/image/postfx_blur.png`, `postfx_vignette.png`, etc.

#### State Golden (Headless)
Verify PostFX chain configuration is stored correctly:

| Test | Effect | Verify |
|------|--------|--------|
| Blur params | `blur(radius=5)` | getBlurRadius() == 5 |
| Vignette params | `vignette(intensity=0.7, radius=0.8)` | getIntensity() == 0.7 |
| Bloom params | `bloom(threshold=0.6, intensity=1.2)` | stored correctly |
| Chromatic aberration | `chromaticAberration(2.0)` | offset == 2.0 |
| Color grade LUT | `setLUT("warm_lut")` | LUT name stored |
| FX chain order | add blur → add vignette | chain length == 2, order preserved |
| Enable/disable | `fx:disable()` | isEnabled() == false |

#### Pixel Golden (Canvas readback)
For effects that can run on a software Canvas:

| Effect | Input canvas | Expected output |
|--------|-------------|-----------------|
| Desaturate | Colored rect | Grayscale pixels (r≈g≈b) |
| Brightness +0.5 | Mid-gray rect | Brighter pixels |
| Contrast | Gradient | Steeper gradient |
| Pixelate 8px | Smooth gradient | Blocky 8px regions |
| Invert | Red rect | Cyan pixels |

---

### 15. Image Processing Golden (NEW)

**File**: `tests/lua/golden/test_image_golden.lua`

Image operations are deterministic CPU operations — all testable headless.

| Test | Operation | Input | Expected Output |
|------|-----------|-------|-----------------|
| Resize bilinear | 8×8 red → 4×4 | 8×8 solid red | 4×4 solid red (same color) |
| Crop | 16×16 checker → crop(4,4,8,8) | Center 8×8 | Checkerboard subregion |
| Flip horizontal | gradient → flipX | Left-dark gradient | Right-dark gradient |
| Flip vertical | gradient → flipY | Top-dark gradient | Bottom-dark gradient |
| Rotate 90° | 8×8 L-shape → rotate(90) | L-shape | Rotated L-shape pixel map |
| Grayscale | RGB image → toGrayscale | Color image | L channel values |
| Threshold | gray image → threshold(0.5) | Gradient | Binary black/white |
| Channel extract | RGBA image → extractR | | Red channel as grayscale |
| Blend multiply | Red × Green | 50% red, 50% green | 0 (black) multiplied |
| Convolution kernel | gaussian blur 3×3 | Sharp edge | Smooth edge |
| getPixel round-trip | setPixel then getPixel | (r,g,b,a) = (0.5,0.25,1.0,0.7) | Same values back |

---

### 16. Animation Frame Sequence Golden (NEW)

**File**: `tests/lua/golden/test_animation_golden.lua`

Verify frame advancement is deterministic given fixed delta times:

| Test | Animation | DT sequence | Expected frame sequence |
|------|-----------|------------|------------------------|
| 8-FPS spritesheet, advance at 0.125s each | 4-frame loop | [0.125, 0.125, 0.125, 0.125] | [0, 1, 2, 3] |
| Loop wraps at end | 4-frame loop | [0.125 × 6] | [0, 1, 2, 3, 0, 1] |
| ping-pong mode | 4-frame ping-pong | [0.125 × 7] | [0,1,2,3,2,1,0] |
| Pause mid-animation | 4-frame | [0.125, pause, 0.125] | [0, 0, 1] (pause holds) |
| Playback speed ×2 | 4-frame | [0.125 × 4 at speed=2] | [0,2,0,2] (skips frames) |
| One-shot stops at end | 4-frame one-shot | [0.125 × 6] | [0,1,2,3,3,3] (clamped) |
| getFrame() mid-tick | 4-frame | advance(0.05) | partial progress, frame unchanged |
| Event at frame N | frame 2 event listener | advance to frame 2 | event callback fires exactly once |

---

### 17. Spine Skeleton Golden (NEW)

**File**: `tests/lua/golden/test_spine_golden.lua`

Verify Spine skeleton bone transforms are deterministic:

| Test | Skeleton | Action | Verify |
|------|----------|--------|--------|
| Bind pose | any skeleton | no animation | bone positions match bind pose table |
| Animation pose at t=0 | walk animation | setTime(0) | bone positions match keyframe 0 |
| Animation pose at t=0.5s | walk animation | setTime(0.5) | bone positions match 0.5s keyframe |
| Bone child transform | parent bone translated | update | child bone world position = parent + local |
| IK constraint | IK target moves | setIKTarget | IK chain end-effector near target |
| Slot color | setSlotColor("body", r, g, b) | getSlotColor | returns exact color back |
| Attachment change | slot "weapon" → "sword" | getAttachment | returns "sword" |
| Skin switch | setSkin("armor") | getSkin | returns "armor" |
| Event callback | animation has event at 0.5s | advance past it | event callback fires with correct data |

---

### 18. Effect Module Golden (NEW)

**File**: `tests/lua/golden/test_effect_golden.lua`

| Test | Effect | Input | Expected Output |
|------|--------|-------|-----------------|
| Particle effect timing | burst effect | trigger → 5 ticks | particle count increases then decays |
| Color curve | color-over-life | at t=0, t=0.5, t=1 | exact r,g,b,a values from curve |
| Size curve | size-over-life | at 3 time points | size values match curve data |
| Effect chain | chain A→B→C | trigger | all 3 fire in sequence |
| Fade effect | opacity curve | advance t | opacity values deterministic |
| Emitter reset | emit → reset → emit | after reset | identical to first emission (same seed) |

---

### 19-21. Additional Golden Test Suggestions

#### test_serial_golden.lua (EXPANDED — add encryption round-trip)
Add to existing plan:
- `encrypt("aes256", key, "plaintext")` → `decrypt` → original
- Verify ciphertext is NOT the same as plaintext (sanity check)
- HMAC signature over fixed data → fixed signature

#### test_localization_golden.lua (NEW)
| Test | Key | Locale | Expected |
|------|-----|--------|---------|
| Basic key lookup | "ui.ok" | en | "OK" |
| Plural form n=1 | "items.count" n=1 | pl | "1 przedmiot" |
| Plural form n=5 | "items.count" n=5 | pl | "5 przedmiotów" |
| Missing key fallback | "nonexistent" | en | "nonexistent" (raw key) |
| Nested key | "menu.settings.title" | en | "Settings" |
| Format interpolation | "hello {name}" | en | "hello World" (with {name}="World") |

#### test_procgen_extended_golden.lua (EXPANDED)
Add to existing procgen plan:
- Voronoi diagram with seed=99 → exact cell centers
- Poisson disk sampling with seed=7, r=2 → deterministic point set
- Markov chain text generation with seed=42, 3rd-order | 5-word output → exact string

---

## Summary

| Category | Previous Plan | Phase 2 Additions | Total |
|----------|-------------|------------------|-------|
| Algorithmic golden | 12 | 0 | 12 |
| Visual/rendering golden | 0 | 9 (gfx, postfx, image, animation, spine, effect + 3 expanded) | 9 |
| **Total golden** | **12** | **9** | **21** |

### Registration in harness.rs (Phase 2)

```rust
#[test] fn lua_golden_graphics() { run_lua_test("golden/test_render_golden.lua"); }
#[test] fn lua_golden_postfx() { run_lua_test("golden/test_postfx_golden.lua"); }
#[test] fn lua_golden_image() { run_lua_test("golden/test_image_golden.lua"); }
#[test] fn lua_golden_animation() { run_lua_test("golden/test_animation_golden.lua"); }
#[test] fn lua_golden_spine() { run_lua_test("golden/test_spine_golden.lua"); }
#[test] fn lua_golden_effect() { run_lua_test("golden/test_effect_golden.lua"); }
#[test] fn lua_golden_localization() { run_lua_test("golden/test_localization_golden.lua"); }
// Plus Rust pixel golden (GPU required, tests/rust/golden/harness.rs):
// graphics_shapes, postfx_blur, postfx_vignette, image_resize, image_flip, etc.
```
