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

### ❌ TODO — Infinite Tiling (Seamless Wrap)
**Source**: features/graphics.md implied by parallax context

No explicit API for ensuring seamless horizontal/vertical tiling when layer texture
does not fill the screen. Must manually tile using multiple draw calls.

---

### ❌ TODO — Depth-Sorted Layer Rendering via Named Groups
**Source**: features/graphics.md — Feature Gaps #4 (render layers)

No named depth ordering within `ParallaxSet`. Layers render in insertion order only.
A `layer:setDepth(z)` or explicit sort step would allow reordering without rebuilding the set.

---

### ❌ TODO — Per-Layer Blend Mode at Creation Time
**Source**: features/graphics.md — general

Blend mode must be specified per draw call. A layer-level default blend mode
(additive, multiply) for layered atmospheric effects would be useful.

---

### 🔇 LOW — Stripe-Band Optimisation for Background Layers
**Source**: performance/02-gpu-rendering.md (implied by frustum culling discussion)

Parallax layers that tile horizontally could skip render calls for strips outside the
viewport. Low priority — parallax layers are typically 1–4 draws per frame.
