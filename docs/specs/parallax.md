# `parallax` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.parallax` |
| **Source** | `src/parallax/` |
| **Rust Tests** | inline tests in `src/parallax/layer.rs`, `src/parallax/render.rs`, and `src/parallax/draw.rs` |
| **Lua Tests** | `tests/lua/unit/test_parallax.lua`, `tests/lua/integration/test_parallax_camera.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `parallax` module provides CPU-side scrolling background layers for side views, overhead views, and atmospheric scene dressing. It computes how a textured layer should move relative to camera motion, optional autoscroll, tiling, opacity, tint, and blend mode.

It exists to keep background-layer math and batching separate from the renderer and from game scripts. Scripts decide which layers exist and when to draw them, while the module turns layer state into concrete draw batches or render commands.

It intentionally does not own texture loading, GPU resources, or camera state itself. Those concerns remain in shared runtime state and in the render pipeline; `parallax` just interprets them to produce scroll-aware draw data.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.parallax.* (Lua API — src/lua_api/parallax_api.rs)
    |
    v
src/parallax/mod.rs
    |- draw.rs - draw
    |- layer.rs - layer
    |- render.rs - render
```

---

## Source Files

| File | Purpose |
|------|---------|
| `draw.rs` | Implements CPU-side image drawing for headless and test-friendly parallax output without depending on the GPU path. |
| `layer.rs` | Defines `ParallaxLayer` state, scroll calculations, autoscroll behavior, and batch-building logic. |
| `mod.rs` | Declares the parallax submodules and re-exports the main layer and batch types. |
| `render.rs` | Converts parallax batches into `RenderCommand` sequences with color, blend mode, and repeated image draws. |

---

## Submodules

### `parallax::draw`

Implements CPU-side image drawing for headless and test-friendly parallax output without depending on the GPU path.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `parallax::layer`

Defines `ParallaxLayer` state, scroll calculations, autoscroll behavior, and batch-building logic.

- **`ParallaxDrawBatch`** (struct): Computed draw batch for a single parallax layer, produced by [`ParallaxLayer::build_draw_calls`].
- **`ParallaxLayer`** (struct): A single scrolling background layer in a parallax background system.

### `parallax::render`

Converts parallax batches into `RenderCommand` sequences with color, blend mode, and repeated image draws.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `ParallaxLayer`

The main scrolling background layer.

#### `ParallaxDrawBatch`

A CPU-side batch description generated from a layer so the Lua bridge or renderer can issue the actual draw commands.

---

## Lua API

Exposed under `lurek.parallax.*` by `src/lua_api/parallax_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.parallax.newLayer` | Creates a new parallax background layer from an options table. |
| `lurek.parallax.newSet` | Creates a new empty parallax set with the given name. |

### `ParallaxLayer` Methods

| Method | Description |
|--------|-------------|
| `parallaxlayer:type(...)` | Returns the type name of this object. |
| `parallaxlayer:update(...)` | Advances the autonomous scroll accumulator by `dt` seconds. |
| `parallaxlayer:render(...)` | Draws the layer using an explicit camera world position. |
| `parallaxlayer:renderAuto(...)` | Draws the layer using the engine active camera position automatically. |
| `parallaxlayer:resetAutoscroll(...)` | Resets the autonomous scroll accumulator to zero. |
| `parallaxlayer:setScrollFactor(...)` | Sets the scroll factor relative to camera movement on each axis. |
| `parallaxlayer:getScrollFactor(...)` | Returns the scroll factor as `(x, y)`. |
| `parallaxlayer:setOffset(...)` | Sets the static world-pixel position bias added on top of camera scroll. |
| `parallaxlayer:getOffset(...)` | Returns the static offset as `(x, y)`. |
| `parallaxlayer:setAutoscroll(...)` | Sets the autonomous scroll velocity in world-pixels per second. |
| `parallaxlayer:getAutoscroll(...)` | Returns the autoscroll velocity as `(vx, vy)`. |
| `parallaxlayer:setRepeat(...)` | Sets whether the layer tiles on the X and Y axes. |
| `parallaxlayer:setScale(...)` | Sets the texture display scale factor on each axis. |
| `parallaxlayer:setZ(...)` | Sets the draw-order depth. Lower values render first (further back). |
| `parallaxlayer:getZ(...)` | Returns the draw-order depth. |
| `parallaxlayer:setOpacity(...)` | Sets the layer-wide opacity override in `[0.0, 1.0]`. |
| `parallaxlayer:getOpacity(...)` | Returns the current opacity. |
| `parallaxlayer:setTint(...)` | Sets the multiplicative RGBA tint applied to all pixels of this layer. |
| `parallaxlayer:getTint(...)` | Returns the current tint as `(r, g, b, a)`. |
| `parallaxlayer:setBlendMode(...)` | Sets the GPU blend mode for this layer. |
| `parallaxlayer:getBlendMode(...)` | Returns the current blend mode as a string. |
| `parallaxlayer:setVisible(...)` | Shows or hides this layer. |
| `parallaxlayer:isVisible(...)` | Returns `true` if the layer is currently visible. |
| `parallaxlayer:clearClamp(...)` | Removes scroll clamping so the layer scrolls freely. |

### `ParallaxSet` Methods

| Method | Description |
|--------|-------------|
| `parallaxset:type(...)` | Returns the type name of this object. |
| `parallaxset:addLayer(...)` | Adds a layer to this set. |
| `parallaxset:removeLayerAt(...)` | Removes the layer at the given 1-based index. |
| `parallaxset:layerCount(...)` | Returns the number of layers in this set. |
| `parallaxset:sortByZ(...)` | Re-sorts all layers by ascending `z` value. |
| `parallaxset:setVisible(...)` | Shows or hides all layers in this set. |
| `parallaxset:isVisible(...)` | Returns `true` if the set is currently visible. |
| `parallaxset:update(...)` | Advances the autoscroll accumulator of every layer by `dt` seconds. |
| `parallaxset:render(...)` | Draws all visible layers in ascending `z` order using an explicit camera position. |
| `parallaxset:renderAuto(...)` | Draws all visible layers using the engine active camera position. |
| `parallaxset:getName(...)` | Returns the name of this set. |
| `parallaxset:setName(...)` | Sets the name of this set. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.parallax.
if lurek.parallax then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 2 |
| `enum` | 0 |
| `fn` (Lua API) | 38 |
| **Total** | **40** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/parallax/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
