# IDEA.md — `parallax` module

> Migrated from `ideas/features/graphics.md` (parallax sections) and `ideas/performance/02-gpu-rendering.md`.
> Status checked against `src/parallax/` and `src/lua_api/parallax_api.rs`.
> Lua namespace: `lurek.parallax`.

---

## Features

### ✅ DONE — ParallaxLayer with Speed Factor
**Source**: features/graphics.md — Summary

`lurek.parallax.newLayer(opts)` → `LuaParallaxLayer` with `parallaxFactor` control.
`parallaxFactor = 0` → fully fixed (sky); `1` → moves 1:1 with camera.

---

### ✅ DONE — ParallaxSet (Multi-Layer Group)
**Source**: Summary

`lurek.parallax.newSet(name)` for managing multiple layers as a named unit.

---

### ✅ DONE — Autonomous Scroll (`renderAuto`)
**Source**: `parallax_api.rs:146`

`layer:renderAuto()` — auto-scroll using accumulated delta time. `layer:resetAutoscroll()` resets.

---

### ✅ DONE — Camera-Driven Scroll (`render`)
**Source**: `parallax_api.rs:134`

`layer:render(cam_x, cam_y)` — manual camera position drives scroll offset.

---

### ✅ DONE — Infinite Tiling (Seamless Wrap)
**Source**: features/graphics.md implied by parallax context

`layer:setTiling(true/false)` enables seamless tiling on both axes simultaneously.
`layer:setTileSize(w, h)` overrides the tile dimensions (defaults to scaled texture size).
`layer:getTiling()` returns the current enabled state.

---

### ✅ DONE — Depth-Sorted Layer Rendering via Named Groups
**Source**: features/graphics.md — Feature Gaps #4 (render layers)

`layer:setDepth(z)` / `layer:getDepth()` exposes a `depth: f32` field alongside
the existing integer `z`. Complements `setZ`/`getZ` for fractional ordering.

---

### ✅ DONE — Per-Layer Blend Mode at Creation Time
**Source**: features/graphics.md — general

Blend mode is stored per-layer as `blend_mode: BlendMode`.  Canonical string names
are `"normal"` (alpha), `"additive"`, `"multiply"`, `"replace"`, `"screen"`.
Legacy aliases `"alpha"` and `"add"` are accepted as inputs.
`setBlendMode` errors on unrecognised strings.

---

### 🔇 LOW — Stripe-Band Optimisation for Background Layers
**Source**: performance/02-gpu-rendering.md (implied by frustum culling discussion)

Parallax layers that tile horizontally could skip render calls for strips outside the
viewport. Low priority — parallax layers are typically 1–4 draws per frame.
