# IDEA.md — `render` module

> Migrated from `ideas/features/graphics.md` + `ideas/performance/02-gpu-rendering.md`.
> Status checked against `src/render/` and `src/lua_api/render_api.rs` (also `graphic_api.rs`).
> Lua namespace: `lurek.gfx` / `lurek.draw`.

---

## Features

### ✅ DONE — Draw Command Queue (45+ RenderCommand variants)
**Source**: features/graphics.md — Feature Summary

Render commands are deferred and processed after `lurek.render()` callback returns.
No GPU calls inside Lua closures.

---

### ✅ DONE — Sprite Batch
**Source**: features/graphics.md — Summary, `src/graphics/sprite_batch.rs`

`LuaSpriteBatch` type with `impl LuaUserData` in `render_api.rs`.

---

### ✅ DONE — Custom WGSL Shaders with Uniform Passing
**Source**: features/graphics.md — Summary

`LuaShader` type with `impl LuaUserData` in `render_api.rs`.

---

### ✅ DONE — Canvas Render-to-Texture
**Source**: features/graphics.md — Summary

`LuaCanvas` type with `impl LuaUserData`. Via `lurek.gfx.newCanvas(w, h)`.

---

### ✅ DONE — Transform Stack (Push/Pop/Translate/Rotate/Scale)
**Source**: features/graphics.md — Summary

`lurek.gfx.push()`, `pop()`, `translate()`, `rotate()`, `scale()` implemented.

---

### ✅ DONE — Nine-Slice Scaling
**Source**: features/graphics.md — Summary

Nine-slice implemented for UI panels.

---

### ✅ DONE — Texture Atlas (Runtime Build)
**Source**: features/graphics.md — Feature Gaps #1 (NOTE: runtime only, not JSON import)

Runtime atlas construction exists. JSON import lives in `sprite_api.rs` as `parseAtlas` (TexturePacker format) — see `src/sprite/IDEA.md`.

---

### ✅ DONE — Render Layers / Groups
**Source**: features/graphics.md — Feature Gaps #4 / Suggestions #2

Named layer registry implemented in `render_api.rs` (local `Rc<RefCell<HashMap>>` inside
`register`). Provides metadata-level layer management with z-ordering and visibility:
```lua
lurek.graphic.newLayer("background", -10)
lurek.graphic.newLayer("entities", 0)
lurek.graphic.setLayer("entities")     -- set active layer
lurek.graphic.setLayerVisible("background", false)
lurek.graphic.currentLayer()           -- → "entities"
lurek.graphic.getLayerZOrder("background")  -- → -10
```
Note: layer metadata is engine-side only; game scripts should use this to organise draw
calls. A future render-pass upgrade can map layers to GPU render passes.

---

### ❌ TODO — Gradient Fills (Linear / Radial)
**Source**: features/graphics.md — Feature Gaps #2 / Suggestions #3

No gradient draw commands. Suggested API:
```lua
lurek.gfx.drawGradient(x, y, w, h, color1, color2, dir)  -- "horizontal"/"vertical"/"radial"
```
High visual impact for health bars, backgrounds, vignettes, sky gradients.

---

### ✅ DONE — Rich Text (Mixed Fonts / Colors / Sizes)
**Source**: features/graphics.md — Feature Gaps #3 / Suggestions #4

`TextSpan` struct + `RenderCommand::DrawRichText` added to `src/render/renderer.rs`.
`lurek.graphic.printRich(spans, x, y)` registered in `src/lua_api/render_api.rs`.
Each span carries independent `r/g/b/a` colour and `scale` multiplier.

```lua
lurek.graphic.printRich({
  { text = "HP: ",  r=255, g=255, b=255, a=255, scale=1.0 },
  { text = "100",   r=80,  g=200, b=80,  a=255, scale=1.0 },
}, 10, 10)
```

Implemented: 2026-04-15

---

### ❌ TODO — Render Layers / Groups
**Source**: features/graphics.md — Feature Gaps #4 / Suggestions #2

No named render layers with independent sort order and visibility. Must manage draw
order manually. Suggested API:
```lua
lurek.gfx.setLayer("background")
lurek.gfx.setLayer("entities")
lurek.gfx.setLayer("ui")
-- layers rendered in z-order, each with own sort
```

---

### ❌ TODO — Anti-Aliased Lines and Shapes
**Source**: features/graphics.md — Feature Gaps #6

Shapes rasterized without anti-aliasing. Jagged edges visible for rotated rectangles
and small circles.

---

### ❌ TODO — Stencil Buffer Operations
**Source**: features/graphics.md — Feature Gaps #9

No stencil buffer control. Requires wgpu pipeline changes. Enables masking and clipping
to arbitrary shapes.

---

### ❌ TODO — Screenshot to ImageData (CPU Readback)
**Source**: features/graphics.md — Feature Gaps #8

`saveScreenshot` writes to disk only. No frame capture into `lurek.image` for CPU processing.

---

### 🤔 CONSIDER — Module Split (render/core, text, sprite, shader, shape)
**Source**: features/graphics.md — Structural Issues

The render module has 18 source files and 66+ Lua functions — the largest in the engine.
Consider splitting into sub-modules for maintainability. Requires Architect decision.

---

## Performance

### ❌ TODO — Frustum / Viewport Culling (HIGH, Medium Effort)
**Source**: performance/02-gpu-rendering.md — Opportunity 1

All `RenderCommand` entries are tessellated even when off-screen. Adding AABB-vs-viewport
check before tessellation would skip 80%+ of work in scrolling games with many off-screen
sprites.

```rust
// In render_pass.rs main loop — before tessellation
let aabb = cmd.compute_aabb(&transform_stack);
if !camera_viewport.intersects(aabb) { continue; }
```

---

### ❌ TODO — GPU Instancing for Repeated Sprites (HIGH, Medium Effort)
**Source**: performance/02-gpu-rendering.md — Opportunity 2, Solution B

Drawing N identical sprites produces N separate tessellations + N draw calls.
GPU instancing with a single instance buffer would reduce particle-style sprite sets
to 1 draw call with 1 quad template.

---

### ❌ TODO — Geometry Cache / Static Draw Mode (Medium Effort)
**Source**: performance/02-gpu-rendering.md — Opportunity 3

Static background geometry is re-tessellated from `RenderCommand` every frame. A cache
mode would store vertex data across frames and skip re-tessellation:
```lua
local bg = lurek.gfx.newGeometryCache()
bg:begin() ... bg:finish()
function lurek.render() bg:draw() end
```

---

### 🔇 LOW — Dynamic Circle LOD
**Source**: performance/02-gpu-rendering.md — Bottlenecks table

32 segments for all circles regardless of screen size. Adaptive LOD based on rendered
pixel area would save tessellation for tiny circles. Low priority — circles are rarely a bottleneck.

---

### 🔇 LOW — CPU Transform Stack (Per-Vertex Matrix Composition)
**Source**: performance/02-gpu-rendering.md — Bottlenecks table

Transforms composed per vertex on CPU. Pushing to GPU push constants or a UBO would
reduce bus traffic. Only meaningful at very high vertex counts. Measure first.
