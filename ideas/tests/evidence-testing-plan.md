# Evidence-Based Testing Plan

**Status**: ✅ PARTIALLY IMPLEMENTED — Evidence Tier 1 (headless state readback) and Tier 2 (13 evidence test files in `tests/lua/evidence/`) are done. Canvas pixel readback (`expect_canvas_pixel()` helper) added to `tests/lua/init.lua`. Tier 3 (runtime smoke tests for light/particle/postfx/audio) partially done via `tests/rust/ext/`. Runtime screenshot smoke tests for complex GPU effects remain as future work.

**Purpose**: Define which APIs need runtime evidence artifacts to prove they actually work, and how to collect that evidence.

## The Problem

Many Lurek2D APIs pass headless tests by verifying:
- The function exists (`expect_type("function", ...)`)
- It accepts the right arguments (`expect_no_error(function() ... end)`)
- It returns a non-nil value (`expect_not_nil(result)`)

But this does NOT prove the API actually works. For example:
- `lurek.render.rectangle("fill", 10, 10, 100, 50)` — passes headless but draws nothing
- `lurek.light.newPointLight(100, 100, 200)` — returns an object but may not illuminate anything
- `lurek.audio.play("sound.wav")` — returns a source handle but may not produce audio

## Evidence Categories

### Category 1: Visual Evidence (Screenshot/Pixel Verification)

APIs that produce visible output. Evidence: screenshot saved to disk, verified for non-black pixels or expected color regions.

| Module | APIs | Evidence Method |
|--------|------|-----------------|
| **graphic** | `rectangle`, `circle`, `ellipse`, `line`, `polygon`, `arc`, `print` (text), `draw` (texture), `setColor`, `setBackgroundColor` | Screenshot → verify colored pixels at expected coordinates |
| **graphic** | `Canvas:renderTo`, `Canvas:getPixel` | Create canvas, draw to it, read pixels back — **this works headless** via pixel readback |
| **light** | `newPointLight`, `newSpotLight`, `newDirectionalLight`, `setAmbient` | Screenshot → verify brightness differs from unlit scene |
| **particle** | `ParticleEmitter:emit`, `ParticleEmitter:start` | Screenshot after N frames → verify non-empty particle pixels |
| **tilemap** | `TileMap:draw`, `TileLayer:draw` | Screenshot → verify tile grid pattern |
| **minimap** | `Minimap:draw`, `Minimap:update` | Screenshot → verify minimap overlay |
| **postfx** | `PostFX:apply`, effect chain | Screenshot with/without effect → verify pixel difference |
| **spine** | `Spine:draw`, `Spine:setAnimation` | Screenshot → verify skeleton renders |
| **raycaster** | `Raycaster:render` | Screenshot → verify 2.5D view renders |
| **gui/ui** | `Button:draw`, `Label:draw`, `Panel:draw` | Screenshot → verify UI widgets visible |
| **overlay** | `Overlay:draw` | Screenshot → verify overlay compositing |
| **effect** | `Effect:draw` (various visual effects) | Screenshot → verify effect output |

**Headless Alternative**: For modules that support `Canvas:getPixel()`, pixel data can be read in-memory without GPU rendering. This allows partial visual verification in headless tests:

```lua
-- Headless pixel evidence using Canvas
local canvas = lurek.render.newCanvas(100, 100)
canvas:renderTo(function()
    lurek.render.setColor(1, 0, 0)
    lurek.render.rectangle("fill", 0, 0, 100, 100)
end)
local r, g, b, a = canvas:getPixel(50, 50)
expect_near(1.0, r, 0.01) -- red pixel confirms rectangle was drawn
```

### Category 2: Audio Evidence

APIs that produce audio output. Evidence: no crash + log confirmation + optional saved WAV.

| Module | APIs | Evidence Method |
|--------|------|-----------------|
| **audio** | `play`, `playLooping`, `Source:play`, `Source:pause`, `Source:stop` | Run with audio device → log confirms playback started; optional `saveToFile` |
| **audio** | `setBus`, `getBus`, `setVolume`, `getVolume` | Run → verify bus routing via mixer state query |
| **audio** | MidiPlayer all methods | Run MIDI file → log confirms note events; verify duration > 0 |
| **audio** | DSP effects (setLowpass, setHighpass, etc.) | Apply filter → verify Source state reflects filter params |

**Headless Alternative**: Most audio state (volume, pan, bus assignment, filter params) can be verified headless by reading back properties. Only actual sound output requires a device.

### Category 3: File/IO Evidence

APIs that produce file output. Evidence: verify file exists with expected content.

| Module | APIs | Evidence Method |
|--------|------|-----------------|
| **filesystem** | `write`, `append`, `mkdir`, `remove` | Write file → read back → verify content matches |
| **savegame** | `SaveManager:save`, `SaveManager:load` | Save game state → load → verify round-trip data integrity |
| **serial** | `encode`, `decode` | Encode data → decode → verify round-trip |
| **data** | `toJSON`, `fromJSON`, `toTOML`, `fromTOML`, `compress`, `decompress` | Encode → decode → verify equality |
| **image** | `Image:save` | Save image → verify file exists with correct size |
| **graphic** | `saveScreenshot` | Take screenshot → verify PNG file exists |

**These are ALL testable headless** — file I/O doesn't need GPU/audio.

### Category 4: Log/State Evidence

APIs where behavior is proven by observable state changes.

| Module | APIs | Evidence Method |
|--------|------|-----------------|
| **log** | `info`, `warn`, `error`, `debug` | Capture log output → verify message appears |
| **window** | `setTitle`, `setSize`, `setFullscreen` | Read back property → verify state changed |
| **input** | `isKeyDown`, `getMousePosition` | Simulate input state → verify query returns expected values |
| **timer** | Timer callbacks, `getDelta`, `getFPS` | Verify timing values are plausible (delta > 0, FPS > 0) |
| **system** | `getOS`, `getArch`, etc. | Verify returns non-empty string of expected format |
| **camera** | `setPosition`, `setZoom`, `shake` | Set → get → verify value changed |
| **entity** | Component add/remove/query | Add component → has component → verify true |
| **scene** | node add/remove/transform | Add node → query → verify present |

**All testable headless** — pure state machine verification.

---

## Implementation Architecture

### Evidence Tier 1: Headless (tests/lua/)

Expand existing Lua unit tests with state readback assertions:

```lua
-- @covers lurek.render.setColor
-- @evidence state:color_changed
describe("gfx.setColor changes state", function()
    it("stores the active color", function()
        lurek.render.setColor(0.5, 0.3, 0.7, 1.0)
        local r, g, b, a = lurek.render.getColor()
        expect_near(0.5, r, 0.01)
        expect_near(0.3, g, 0.01)
    end)
end)
```

### Evidence Tier 2: Canvas Pixel Readback (tests/lua/)

For modules that support Canvas:

```lua
-- @covers lurek.render.circle
-- @evidence pixel:canvas_readback
describe("circle draws pixels", function()
    it("circle center has fill color", function()
        local canvas = lurek.render.newCanvas(200, 200)
        canvas:renderTo(function()
            lurek.render.setColor(1, 0, 0, 1)
            lurek.render.circle("fill", 100, 100, 50)
        end)
        local r, g, b, a = canvas:getPixel(100, 100)
        expect_near(1.0, r, 0.05, "circle center should be red")
    end)
end)
```

### Evidence Tier 3: Runtime Smoke Tests (tests/rust/ext/)

For APIs that truly need a window/GPU/audio device:

```
tests/rust/ext/
├── smoke_support.rs          (existing helper)
├── graphics_runtime_smoke_tests.rs  (existing)
├── light_smoke_tests.rs      (NEW)
├── particle_smoke_tests.rs   (NEW)
├── audio_smoke_tests.rs      (NEW)
├── postfx_smoke_tests.rs     (NEW)
```

Each smoke test:
1. Copies an example to a temp directory
2. Runs the engine binary with `--smoke-*` flags
3. Waits for screenshot/log output
4. Asserts expected artifacts exist

---

## Priority Matrix

| Priority | Module | Evidence Type | Effort | Value |
|----------|--------|---------------|--------|-------|
| **P0** | graphic (basic drawing) | Canvas pixel readback | Medium | Highest — proves core 2D rendering |
| **P0** | filesystem (write/read) | File existence + content | Low | Proves I/O works |
| **P0** | data (JSON/TOML) | Round-trip equality | Low | Proves serialization |
| **P1** | light | Runtime screenshot | Medium | Currently untested visually |
| **P1** | particle | Runtime screenshot | Medium | Currently untested visually |
| **P1** | savegame | File round-trip | Low | Proves save/load cycle |
| **P1** | image (save) | File existence | Low | Proves image export |
| **P2** | audio (playback) | Runtime log | High | Requires audio device |
| **P2** | postfx | Runtime screenshot | High | Complex multi-pass rendering |
| **P2** | tilemap (draw) | Canvas pixel readback | Medium | Visual tile pattern |
| **P3** | spine | Runtime screenshot | High | Requires Spine assets |
| **P3** | raycaster | Runtime screenshot | High | Complex 2.5D rendering |
| **P3** | gui/ui | Runtime screenshot | High | Many widget types |

---

## Which APIs MUST Have Visual Evidence

These APIs are the highest risk for "passes tests but doesn't actually work":

### CRITICAL: Known Risk (light module example)
The user specifically noted that the light system may not produce any visible output. This is the pattern we're solving:

1. `lurek.light.newPointLight(x, y, radius)` — test creates light, verifies it returns non-nil → **passes**
2. But: Does the light actually illuminate anything? Does it cast shadows? → **unknown without visual evidence**

**Required evidence test**:
```
1. Create a dark scene (background = black)
2. Place a white rectangle at known coordinates
3. Place a point light at the rectangle's position
4. Screenshot → verify pixels at rectangle location are brighter than pixels far from light
5. Compare: screenshot WITH light vs screenshot WITHOUT light → pixel difference > threshold
```

### APIs Requiring Visual Evidence (cannot be tested headless)

| API | What to Verify |
|-----|---------------|
| `lurek.light.newPointLight` | Illuminated pixels are brighter than non-illuminated |
| `lurek.light.newSpotLight` | Cone of light visible in expected direction |
| `lurek.light.setAmbient` | Changing ambient changes overall scene brightness |
| `lurek.render.rectangle` / `circle` / `line` | Pixels at expected coordinates have expected color |
| `lurek.particle.newEmitter` + `emit` | Particles visible after N frames |
| `Canvas:renderTo` | Canvas captures rendered content (canvas pixel readback — CAN be headless) |
| `lurek.effect.*` | Post-processing visibly changes output pixels |
| `Shader:send` | Custom shader produces expected pixel output |
| `BlendMode` changes | Different blend modes produce different pixel values for same geometry |
| `lurek.render.draw` (Texture) | Image pixels appear at correct screen location |

---

## Phase 2 — Expanded Evidence Coverage

### Full Visual Module Coverage

#### graphic — Complete Canvas Evidence Tests

Every drawing primitive needs canvas pixel evidence:

| Primitive | Canvas Test | What to verify |
|-----------|-------------|----------------|
| `rectangle("fill")` | 64×64, draw 32×32 | Center pixel == fill color; corner outside transparent |
| `rectangle("line")` | 64×64, draw outline | Border pixels == color; interior transparent |
| `circle("fill")` | 64×64, center at 32,32 r=20 | Center pixel colored; 4 corners transparent |
| `circle("line")` | 64×64 | Circle edge pixels colored; center transparent |
| `ellipse("fill")` | 64×64, 3:2 aspect | Wider than tall in pixel distribution |
| `line` | 64×64, diagonal | Start + end pixel colored; midpoint colored |
| `polygon` | Triangle on canvas | Interior sample colored; exterior transparent |
| `arc` | 64×64, 90° arc | Arc pixels colored; rest transparent |
| `print` (text) | Render "X" | At least 1 non-transparent pixel in canvas |
| `draw` (Texture) | Load test texture, draw at (0,0) | top-left pixel matches texture (0,0) color |
| `setColor(r,g,b,a)` | Draw rect then getPixel | Pixel matches set color |
| `setBackgroundColor` | Clear canvas | Background pixel matches set color |
| `ColorTransform` | Apply tint | Pixels shifted toward tint color |
| Blend: `"add"` | Red + green | Result brighter (r+g) |
| Blend: `"multiply"` | 0.5 gray × colored | Darkened result |
| Blend: `"screen"` | Two half-brightness | Brighter than either alone |

#### light — Full Visual Evidence (ALL methods need runtime tests)

```
tests/rust/ext/light_smoke_tests.rs
```

Each light test:
1. Render scene WITHOUT the light feature → save `no_light.png`
2. Render scene WITH the light feature → save `with_light.png`
3. Compare pixel brightness at the illuminated region: `with_light` must be brighter

| Method | Test Scenario | Pixel Evidence |
|--------|---------------|----------------|
| `newPointLight(x,y,r)` | White rect, black background, light at rect center | Rect pixels brighter WITH light |
| `newSpotLight(x,y,dir,angle)` | Spot aimed at rect | Pixels inside cone brighter |
| `newDirectionalLight(dx,dy)` | Global directional | Whole scene brighter |
| `setAmbient(r,g,b)` | Change ambient light | Average brightness proportional to ambient |
| `setColor(r,g,b)` | Red point light | Lit area has reddish tint |
| `setIntensity(v)` | High vs low intensity | Higher intensity = brighter pixels |
| `setRadius(r)` | Small vs large radius | Larger radius = wider bright circle |
| `setFalloff(mode)` | Linear vs quadratic | Edge brightness matches expected falloff |
| Shadow casting | Solid occluder between light and wall | Shadow area darker than direct-lit area |

**Expected outcome**: At least 7 light evidence tests passing proves the light system renders output.

#### particle — Canvas + Runtime Evidence

Headless (Canvas pixel readback):
```lua
-- Verify at least 1 particle is drawn after emission
local canvas = lurek.render.newCanvas(200, 200)
local emitter = lurek.particle.newEmitter()
emitter:setPosition(100, 100)
emitter:setRate(100) -- 100 particles/sec
canvas:renderTo(function()
    emitter:emit(10) -- emit 10 particles immediately
    -- Draw particles at their current positions
    emitter:draw()
end)
-- Check that at least 1 pixel is non-transparent
local nonEmpty = false
for x = 0, 199, 4 do
    for y = 0, 199, 4 do
        local r, g, b, a = canvas:getPixel(x, y)
        if a > 0.01 then nonEmpty = true end
    end
end
expect_true(nonEmpty, "at least one particle must be visible")
```

Runtime smoke (`tests/rust/ext/particle_smoke_tests.rs`):
- Burst emitter → screenshot → verify particle region has colored pixels
- Gravity effect: particle y positions increase over time (state readback)
- Color-over-life: early particle redder, late particle bluer (canvas pixel at different times)

#### audio — Full Functional Evidence

Audio is hard to test without a device. Expanded evidence strategy:

**Category A: State-based (fully headless)**

| Method | Evidence |
|--------|---------|
| `newSource(file, type)` | Returns Source object; `source:isLoaded()` == true |
| `source:play()` | `source:isPlaying()` == true immediately after call |
| `source:pause()` | `source:isPaused()` == true; `isPlaying()` == false |
| `source:stop()` | `source:isStopped()` == true; `getOffset()` == 0 |
| `source:seek(t)` | `source:getOffset()` ~== t (within 5ms) |
| `source:setVolume(v)` | `source:getVolume()` == v |
| `source:setPitch(p)` | `source:getPitch()` == p |
| `source:setPan(p)` | `source:getPan()` == p |
| `source:setLooping(true)` | `source:isLooping()` == true |
| `newBus(name)` | Bus registered; `getBus(name)` returns same bus |
| `bus:setVolume(v)` | `bus:getVolume()` == v |
| `source:setBus(bus)` | `source:getBus()` == bus |
| DSP chain | `source:addEffect(type)` → effect count increases |
| `getActiveSources()` | Count increases after play; decreases after stop |
| `getMasterVolume()` | Returns value between 0 and 1 |

**Category B: Functional (CI audio device optional)**

| Method | Evidence |
|--------|---------|
| `source:play()` (actual output) | Runtime: audio device present → log confirms playback; `source:getOffset()` > 0 after 100ms |
| `source:getWaveformData()` | Returns non-empty array of floats |
| Fade in/out | Measure volume at t=0, t=0.5, t=1 — verify linear progression |
| Bus send/return | Mix two buses → output level reflects both |

**Category C: File-based (headless)**

| Method | Evidence |
|--------|---------|
| `source:save("out.wav")` | File exists, size > 0, parseable as WAV |
| `lurek.audio.getMixerState()` | Returns serializable table with volume, active, etc. |

#### effect — Canvas Evidence

| Effect | Canvas Test |
|--------|-------------|
| Fade in/out | Canvas at t=0 fully transparent; at t=1 fully opaque |
| Color flash | Canvas at peak: full red; after: decay toward original |
| Shake | Position offset > 0 during shake; returns to 0 after |
| Dissolve | Canvas pixels disappear progressively (count decreases each frame) |
| Wipe left | Left side disappears first; right side last |
| Zoom burst | Central pixels expand outward |

#### animation — Frame-advance Evidence

```lua
describe("animation frame advances correctly", function()
    -- @covers Animation:getFrame
    -- @covers Animation:update
    -- @evidence state:frame_change
    it("frame changes after sufficient dt", function()
        local anim = lurek.animation.new("test_sheet", {frames=4, fps=8})
        anim:play()
        expect_equal(0, anim:getFrame())
        anim:update(0.125) -- 1/8 second
        expect_equal(1, anim:getFrame())
        anim:update(0.125)
        expect_equal(2, anim:getFrame())
    end)
end)
```

Canvas evidence for animation:
```lua
-- Different frames draw different pixel regions
local canvas = lurek.render.newCanvas(64, 64)
-- Frame 0: draw top-left 32×32 region
canvas:renderTo(function() anim:draw(0, 0) end)
local r0, g0 = canvas:getPixel(16, 16)
-- Advance to frame 1: draws different region of atlas
anim:update(0.125)
canvas:renderTo(function() anim:draw(0, 0) end)
local r1, g1 = canvas:getPixel(16, 16)
-- Pixels should differ between frames (different atlas regions)
-- (This is the "different frame draws different content" assertion)
```

#### spine — Bone Position Evidence

```lua
describe("spine bone positions change with animation", function()
    -- @covers Skeleton:setAnimation
    -- @covers Skeleton:update
    -- @evidence state:bone_transform_change
    it("bone world position changes when animation advances", function()
        local skeleton = lurek.spine.load("test_skeleton")
        skeleton:setAnimation(0, "walk", true)
        skeleton:update(0) -- bind pose
        local x0, y0 = skeleton:getBoneWorldPosition("foot_bone")
        skeleton:update(0.25) -- quarter second
        local x1, y1 = skeleton:getBoneWorldPosition("foot_bone")
        -- Bone must have moved (walk animation changes foot position)
        local moved = (x0 - x1)^2 + (y0 - y1)^2 > 0.01
        expect_true(moved, "bone should move during walk animation")
    end)
end)
```

#### postfx — Canvas and Runtime Evidence

Headless:
```lua
-- Desaturate effect: red input → gray output
local canvas_in = lurek.render.newCanvas(32, 32)
canvas_in:renderTo(function()
    lurek.render.setColor(1, 0, 0, 1)
    lurek.render.rectangle("fill", 0, 0, 32, 32)
end)
local canvas_out = lurek.render.newCanvas(32, 32)
canvas_out:renderTo(function()
    local fx = lurek.effect.new()
    fx:addDesaturate(1.0) -- fully desaturate
    fx:apply(canvas_in, canvas_out)
end)
local r, g, b = canvas_out:getPixel(16, 16)
-- All channels should be equal (gray)
expect_near(r, g, 0.05, "desaturated R≈G")
expect_near(g, b, 0.05, "desaturated G≈B")
```

Runtime smoke tests for GPU-required effects (blur, bloom, chromatic aberration):
- Render white circle on black → apply blur → sample pixels near edge → verify they are gray (blur spread)
- Apply bloom → bright areas spill light → sample just outside bright circle → non-zero

#### gui/ui — Canvas + Input Simulation Evidence

```lua
-- Widget renders non-empty content
local canvas = lurek.render.newCanvas(200, 50)
canvas:renderTo(function()
    lurek.gui.button("Click Me", 10, 10, 180, 30)
end)
local hasPixels = false
for x = 10, 190, 5 do
    local r, g, b, a = canvas:getPixel(x, 25)
    if a > 0.01 then hasPixels = true end
end
expect_true(hasPixels, "button must render visible pixels")
```

---

## Evidence Coverage Summary

| Module | Headless State | Canvas Pixel | Runtime Screenshot | Audio Device | File I/O |
|--------|---------------|-------------|-------------------|-------------|----------|
| graphic | Full | **Full** (16+ primitives) | Optional | — | screenshot |
| light | Partial (query) | Limited | **Required** (all 8 methods) | — | — |
| particle | Partial | **Via emitter draw** | Supplementary | — | — |
| audio | **Full** (state only) | — | — | Supplementary | WAV export |
| effect | Partial | **For visual effects** | — | — | — |
| animation | **Full** (frame advance) | **Frame draws** | — | — | — |
| spine | **Full** (bone positions) | Limited | Supplementary | — | — |
| postfx | **Partial** (params) | **Headless effects** | GPU effects only | — | — |
| gui/ui | **Partial** (widget state) | **Widget rendering** | Supplementary | — | — |
| image | **Full** (CPU ops) | **Pixel manipulation** | — | — | Save/load |
| tilemap | Partial | **Tile pixels** | Supplementary | — | — |
| camera | **Full** (transforms) | Via scene render | — | — | — |
| savegame | — | — | — | — | **Full** |
| filesystem | — | — | — | — | **Full** |
| data | — | — | — | — | Round-trip |

---

## Phase 2 — Expanded Evidence Coverage

### Full Visual Module Coverage

#### graphic — Complete Canvas Evidence Tests

Every drawing primitive needs canvas pixel evidence:

| Primitive | Canvas Test | What to verify |
|-----------|-------------|----------------|
| `rectangle("fill")` | 64×64, draw 32×32 | Center pixel == fill color; corner outside transparent |
| `rectangle("line")` | 64×64, draw outline | Border pixels == color; interior transparent |
| `circle("fill")` | 64×64, center at 32,32 r=20 | Center pixel colored; 4 corners transparent |
| `circle("line")` | 64×64 | Circle edge pixels colored; center transparent |
| `ellipse("fill")` | 64×64, 3:2 aspect | Wider than tall in pixel distribution |
| `line` | 64×64, diagonal | Start + end pixel colored; midpoint colored |
| `polygon` | Triangle on canvas | Interior sample colored; exterior transparent |
| `arc` | 64×64, 90° arc | Arc pixels colored; rest transparent |
| `print` (text) | Render "X" | At least 1 non-transparent pixel in canvas |
| `draw` (Texture) | Load test texture, draw at (0,0) | top-left pixel matches texture (0,0) color |
| `setColor(r,g,b,a)` | Draw rect then getPixel | Pixel matches set color |
| `setBackgroundColor` | Clear canvas | Background pixel matches set color |
| `ColorTransform` | Apply tint | Pixels shifted toward tint color |
| Blend: `"add"` | Red + green | Result brighter (r+g) |
| Blend: `"multiply"` | 0.5 gray × colored | Darkened result |
| Blend: `"screen"` | Two half-brightness | Brighter than either alone |

#### light — Full Visual Evidence (ALL methods need runtime tests)

```
tests/rust/ext/light_smoke_tests.rs
```

Each light test:
1. Render scene WITHOUT the light feature → save `no_light.png`
2. Render scene WITH the light feature → save `with_light.png`
3. Compare pixel brightness at the illuminated region: `with_light` must be brighter

| Method | Test Scenario | Pixel Evidence |
|--------|---------------|----------------|
| `newPointLight(x,y,r)` | White rect, black background, light at rect center | Rect pixels brighter WITH light |
| `newSpotLight(x,y,dir,angle)` | Spot aimed at rect | Pixels inside cone brighter |
| `newDirectionalLight(dx,dy)` | Global directional | Whole scene brighter |
| `setAmbient(r,g,b)` | Change ambient light | Average brightness proportional to ambient |
| `setColor(r,g,b)` | Red point light | Lit area has reddish tint |
| `setIntensity(v)` | High vs low intensity | Higher intensity = brighter pixels |
| `setRadius(r)` | Small vs large radius | Larger radius = wider bright circle |
| `setFalloff(mode)` | Linear vs quadratic | Edge brightness matches expected falloff |
| Shadow casting | Solid occluder between light and wall | Shadow area darker than direct-lit area |

**Expected outcome**: At least 7 light evidence tests passing proves the light system renders output.

#### particle — Canvas + Runtime Evidence

Headless (Canvas pixel readback):
```lua
-- Verify at least 1 particle is drawn after emission
local canvas = lurek.render.newCanvas(200, 200)
local emitter = lurek.particle.newEmitter()
emitter:setPosition(100, 100)
emitter:setRate(100) -- 100 particles/sec
canvas:renderTo(function()
    emitter:emit(10) -- emit 10 particles immediately
    -- Draw particles at their current positions
    emitter:draw()
end)
-- Check that at least 1 pixel is non-transparent
local nonEmpty = false
for x = 0, 199, 4 do
    for y = 0, 199, 4 do
        local r, g, b, a = canvas:getPixel(x, y)
        if a > 0.01 then nonEmpty = true end
    end
end
expect_true(nonEmpty, "at least one particle must be visible")
```

Runtime smoke (`tests/rust/ext/particle_smoke_tests.rs`):
- Burst emitter → screenshot → verify particle region has colored pixels
- Gravity effect: particle y positions increase over time (state readback)
- Color-over-life: early particle redder, late particle bluer (canvas pixel at different times)

#### audio — Full Functional Evidence

Audio is hard to test without a device. Expanded evidence strategy:

**Category A: State-based (fully headless)**

| Method | Evidence |
|--------|---------|
| `newSource(file, type)` | Returns Source object; `source:isLoaded()` == true |
| `source:play()` | `source:isPlaying()` == true immediately after call |
| `source:pause()` | `source:isPaused()` == true; `isPlaying()` == false |
| `source:stop()` | `source:isStopped()` == true; `getOffset()` == 0 |
| `source:seek(t)` | `source:getOffset()` ~== t (within 5ms) |
| `source:setVolume(v)` | `source:getVolume()` == v |
| `source:setPitch(p)` | `source:getPitch()` == p |
| `source:setPan(p)` | `source:getPan()` == p |
| `source:setLooping(true)` | `source:isLooping()` == true |
| `newBus(name)` | Bus registered; `getBus(name)` returns same bus |
| `bus:setVolume(v)` | `bus:getVolume()` == v |
| `source:setBus(bus)` | `source:getBus()` == bus |
| DSP chain | `source:addEffect(type)` → effect count increases |
| `getActiveSources()` | Count increases after play; decreases after stop |
| `getMasterVolume()` | Returns value between 0 and 1 |

**Category B: Functional (CI audio device optional)**

| Method | Evidence |
|--------|---------|
| `source:play()` (actual output) | Runtime: audio device present → log confirms playback; `source:getOffset()` > 0 after 100ms |
| `source:getWaveformData()` | Returns non-empty array of floats |
| Fade in/out | Measure volume at t=0, t=0.5, t=1 — verify linear progression |
| Bus send/return | Mix two buses → output level reflects both |

**Category C: File-based (headless)**

| Method | Evidence |
|--------|---------|
| `source:save("out.wav")` | File exists, size > 0, parseable as WAV |
| `lurek.audio.getMixerState()` | Returns serializable table with volume, active, etc. |

#### effect — Canvas Evidence

| Effect | Canvas Test |
|--------|-------------|
| Fade in/out | Canvas at t=0 fully transparent; at t=1 fully opaque |
| Color flash | Canvas at peak: full red; after: decay toward original |
| Shake | Position offset > 0 during shake; returns to 0 after |
| Dissolve | Canvas pixels disappear progressively (count decreases each frame) |
| Wipe left | Left side disappears first; right side last |
| Zoom burst | Central pixels expand outward |

#### animation — Frame-advance Evidence

```lua
describe("animation frame advances correctly", function()
    -- @covers Animation:getFrame
    -- @covers Animation:update
    -- @evidence state:frame_change
    it("frame changes after sufficient dt", function()
        local anim = lurek.animation.new("test_sheet", {frames=4, fps=8})
        anim:play()
        expect_equal(0, anim:getFrame())
        anim:update(0.125) -- 1/8 second
        expect_equal(1, anim:getFrame())
        anim:update(0.125)
        expect_equal(2, anim:getFrame())
    end)
end)
```

Canvas evidence for animation:
```lua
-- Different frames draw different pixel regions
local canvas = lurek.render.newCanvas(64, 64)
-- Frame 0: draw top-left 32×32 region
canvas:renderTo(function() anim:draw(0, 0) end)
local r0, g0 = canvas:getPixel(16, 16)
-- Advance to frame 1: draws different region of atlas
anim:update(0.125)
canvas:renderTo(function() anim:draw(0, 0) end)
local r1, g1 = canvas:getPixel(16, 16)
-- Pixels should differ between frames (different atlas regions)
-- (This is the "different frame draws different content" assertion)
```

#### spine — Bone Position Evidence

```lua
describe("spine bone positions change with animation", function()
    -- @covers Skeleton:setAnimation
    -- @covers Skeleton:update
    -- @evidence state:bone_transform_change
    it("bone world position changes when animation advances", function()
        local skeleton = lurek.spine.load("test_skeleton")
        skeleton:setAnimation(0, "walk", true)
        skeleton:update(0) -- bind pose
        local x0, y0 = skeleton:getBoneWorldPosition("foot_bone")
        skeleton:update(0.25) -- quarter second
        local x1, y1 = skeleton:getBoneWorldPosition("foot_bone")
        -- Bone must have moved (walk animation changes foot position)
        local moved = (x0 - x1)^2 + (y0 - y1)^2 > 0.01
        expect_true(moved, "bone should move during walk animation")
    end)
end)
```

#### postfx — Canvas and Runtime Evidence

Headless:
```lua
-- Desaturate effect: red input → gray output
local canvas_in = lurek.render.newCanvas(32, 32)
canvas_in:renderTo(function()
    lurek.render.setColor(1, 0, 0, 1)
    lurek.render.rectangle("fill", 0, 0, 32, 32)
end)
local canvas_out = lurek.render.newCanvas(32, 32)
canvas_out:renderTo(function()
    local fx = lurek.effect.new()
    fx:addDesaturate(1.0) -- fully desaturate
    fx:apply(canvas_in, canvas_out)
end)
local r, g, b = canvas_out:getPixel(16, 16)
-- All channels should be equal (gray)
expect_near(r, g, 0.05, "desaturated R≈G")
expect_near(g, b, 0.05, "desaturated G≈B")
```

Runtime smoke tests for GPU-required effects (blur, bloom, chromatic aberration):
- Render white circle on black → apply blur → sample pixels near edge → verify they are gray (blur spread)
- Apply bloom → bright areas spill light → sample just outside bright circle → non-zero

#### gui/ui — Canvas + Input Simulation Evidence

```lua
-- Widget renders non-empty content
local canvas = lurek.render.newCanvas(200, 50)
canvas:renderTo(function()
    lurek.gui.button("Click Me", 10, 10, 180, 30)
end)
local hasPixels = false
for x = 10, 190, 5 do
    local r, g, b, a = canvas:getPixel(x, 25)
    if a > 0.01 then hasPixels = true end
end
expect_true(hasPixels, "button must render visible pixels")
```

---

## Evidence Coverage Summary

| Module | Headless State | Canvas Pixel | Runtime Screenshot | Audio Device | File I/O |
|--------|---------------|-------------|-------------------|-------------|----------|
| graphic | Full | **Full** (16+ primitives) | Optional | — | screenshot |
| light | Partial (query) | Limited | **Required** (all 8 methods) | — | — |
| particle | Partial | **Via emitter draw** | Supplementary | — | — |
| audio | **Full** (state only) | — | — | Supplementary | WAV export |
| effect | Partial | **For visual effects** | — | — | — |
| animation | **Full** (frame advance) | **Frame draws** | — | — | — |
| spine | **Full** (bone positions) | Limited | Supplementary | — | — |
| postfx | **Partial** (params) | **Headless effects** | GPU effects only | — | — |
| gui/ui | **Partial** (widget state) | **Widget rendering** | Supplementary | — | — |
| image | **Full** (CPU ops) | **Pixel manipulation** | — | — | Save/load |
| tilemap | Partial | **Tile pixels** | Supplementary | — | — |
| camera | **Full** (transforms) | Via scene render | — | — | — |
| savegame | — | — | — | — | **Full** |
| filesystem | — | — | — | — | **Full** |
| data | — | — | — | — | Round-trip |
