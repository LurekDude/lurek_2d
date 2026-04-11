# `parallax` — Parallax Background Layer System

| Property       | Value                                                                  |
|----------------|------------------------------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extensions                                             |
| **Status**     | Implemented — Full                                                     |
| **Lua API**    | `lurek.parallax` (25 functions, 2 UserData types)                      |
| **Source**     | `src/parallax/`                                                        |
| **Rust Tests** | inline in `src/parallax/layer.rs`                                      |
| **Lua Tests**  | `tests/lua/unit/test_parallax.lua`, `tests/lua/integration/test_parallax_camera.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md` § Tier 2 Modules         |

## Summary

`src/parallax/` implements a CPU-driven, multi-layer 2D scrolling background system for Lurek2D.
Each `ParallaxLayer` scrolls at a configurable speed relative to a world camera position, supports
autonomous drift (autoscroll), horizontal and/or vertical tiling, z-ordering, opacity, per-layer
blend modes, and tint. Multiple layers can be grouped into a `ParallaxSet` for scene-level
management and batch update/draw calls.

The module is split into a pure-Rust domain layer (`src/parallax/layer.rs`) and a Lua bridge
(`src/lua_api/parallax_api.rs`). The domain layer performs scroll mathematics and produces a
`ParallaxDrawBatch` — a plain Rust value containing the tile positions and draw parameters. The
Lua bridge converts the batch into `RenderCommand::DrawImageEx` entries pushed into the deferred
render queue.

Internally, the scroll position is computed as:

```
autoscroll_accum += autoscroll_velocity * dt   (rem_euclid to stay bounded)
raw_x = camera_x * scroll_factor_x + offset_x + autoscroll_accum_x
start_x = -(raw_x % tex_w * scale_x)          (for repeat_x = true)
```

For repeat axes the renderer tiles from `start_x` across the full screen width.
For non-repeat axes a single draw places the texture at `start_x`.

The current GPU path uses the existing `DrawImageEx` command (one draw call per tile copy).
A future `DrawTiledImage` variant would collapse this to one draw call per layer.
This module lives at **Tier 2** — it depends on `crate::runtime` (SharedState, TextureKey)
and `crate::render` (BlendMode, RenderCommand), but has no Tier 1 ↔ Tier 1 cross-imports.

## Architecture

```
lurek.parallax.*  (src/lua_api/parallax_api.rs — thin Lua bridge)
   │  newLayer(opts) → LuaParallaxLayer
   │  newSet(name)   → LuaParallaxSet
   │
   ├── LuaParallaxLayer  (Rc<RefCell<ParallaxLayer>> + Rc<RefCell<SharedState>>)
   │       │  :update(dt)          → advances autoscroll_accum
   │       │  :draw(cam_x, cam_y)  → calls build_draw_calls → push RenderCommand
   │       └── ParallaxLayer::build_draw_calls()  (pure Rust, no mlua)
   │
   └── LuaParallaxSet  (Vec<Rc<RefCell<ParallaxLayer>>>)
           │  :update(dt)         → calls layer.update for each layer
           └── :draw(cam_x, cam_y)→ calls layer.draw for each layer (z-sorted)

Domain module  (src/parallax/)
   layer.rs  → ParallaxLayer, ParallaxDrawBatch   (pure Rust, no mlua)
   mod.rs    → re-exports

Render integration:
   ParallaxDrawBatch → RenderCommand::SetColor + RenderCommand::DrawImageEx (×N tiles)
```

## Source Files

| File       | Purpose                                                              |
|------------|----------------------------------------------------------------------|
| `mod.rs`   | Module root; re-exports `ParallaxLayer` and `ParallaxDrawBatch`.     |
| `layer.rs` | `ParallaxLayer` scroll logic, `ParallaxDrawBatch`, 9 inline unit tests. |

## Submodules

### `layer` — Scroll Domain Logic
- `ParallaxLayer` — Full scroll state: scroll factor, offset, autoscroll, tiling, z, opacity, tint, blend mode, scale, clamp.
- `ParallaxDrawBatch` — Output of `build_draw_calls()`; contains tile origins, scale, color, and blend mode for the Lua bridge to push as `RenderCommand` entries.

---

## Key Types

### Structs

#### `ParallaxLayer` (`src/parallax/layer.rs`)

Pure-Rust scroll state for a single background layer. No mlua dependency.

| Field              | Type                  | Default       |
|--------------------|-----------------------|---------------|
| `texture_key`      | `TextureKey`          | (required)    |
| `texture_width`    | `f32`                 | (from asset)  |
| `texture_height`   | `f32`                 | (from asset)  |
| `scroll_factor`    | `[f32; 2]`            | `[1.0, 0.0]`  |
| `offset`           | `[f32; 2]`            | `[0.0, 0.0]`  |
| `autoscroll`       | `[f32; 2]`            | `[0.0, 0.0]` px/s |
| `autoscroll_accum` | `[f32; 2]`            | `[0.0, 0.0]`  |
| `repeat_x`         | `bool`                | `true`        |
| `repeat_y`         | `bool`                | `false`       |
| `clamp_min`        | `Option<[f32; 2]>`    | `None`        |
| `clamp_max`        | `Option<[f32; 2]>`    | `None`        |
| `z`                | `i32`                 | `0`           |
| `opacity`          | `f32`                 | `1.0`         |
| `tint`             | `[f32; 4]`            | `[1,1,1,1]`   |
| `blend_mode`       | `BlendMode`           | `Alpha`       |
| `visible`          | `bool`                | `true`        |
| `scale`            | `[f32; 2]`            | `[1.0, 1.0]`  |

Key methods: `new(key, w, h)`, `update(dt)`, `compute_pixel_offset(cam_x, cam_y)`, `build_draw_calls(cx, cy, sw, sh) -> Option<ParallaxDrawBatch>`, `reset_autoscroll()`.

#### `ParallaxDrawBatch` (`src/parallax/layer.rs`)

Output value from `ParallaxLayer::build_draw_calls()`. Consumed by the Lua bridge to push `RenderCommand` entries.

| Field         | Type             | Meaning                                      |
|---------------|------------------|----------------------------------------------|
| `texture_key` | `TextureKey`     | Texture to draw.                             |
| `tiles`       | `Vec<(f32, f32)>`| Screen-space `(x, y)` origins for each tile. |
| `sx`          | `f32`            | Horizontal display scale.                    |
| `sy`          | `f32`            | Vertical display scale.                      |
| `color`       | `[f32; 4]`       | Pre-multiplied RGBA from `tint × opacity`.   |
| `blend_mode`  | `BlendMode`      | GPU blend mode.                              |

### Enums

_No public enums in `src/parallax/`. Blend mode is imported from `crate::render::BlendMode`._

---

## Lua API

Registered by `src/lua_api/parallax_api.rs` as `lurek.parallax`.

### Module Functions

| Function                    | Signature                   | Returns              |
|-----------------------------|-----------------------------|----------------------|
| `lurek.parallax.newLayer`   | `(opts: table)`             | `LuaParallaxLayer`   |
| `lurek.parallax.newSet`     | `(name: string)`            | `LuaParallaxSet`     |

**`newLayer` options table:**

| Key              | Type      | Default | Description                              |
|------------------|-----------|---------|------------------------------------------|
| `texture`        | `LuaImage`| —       | Required loaded texture.                 |
| `scroll_factor_x`| number    | `1.0`   | Horizontal parallax factor.              |
| `scroll_factor_y`| number    | `0.0`   | Vertical parallax factor.                |
| `offset_x/y`     | number    | `0.0`   | Initial pixel offset.                    |
| `autoscroll_x/y` | number    | `0.0`   | Autonomous scroll velocity (px/s).       |
| `repeat_x/y`     | boolean   | `true/false` | Tiling axis flags.                  |
| `z`              | integer   | `0`     | Draw order (lower = further back).       |
| `opacity`        | number    | `1.0`   | Layer alpha `[0, 1]`.                    |
| `tint_r/g/b/a`   | number    | `1.0`   | Layer tint per channel.                  |
| `blend_mode`     | string    | `"alpha"` | Blend mode name.                       |
| `scale_x/y`      | number    | `1.0`   | Display scale.                           |
| `visible`        | boolean   | `true`  | Initial visibility.                      |

### `LuaParallaxLayer` Methods

| Method              | Signature                  | Description                                 |
|---------------------|----------------------------|---------------------------------------------|
| `type`              | `() -> string`             | Returns `"ParallaxLayer"`.                  |
| `update`            | `(dt: number)`             | Advance autoscroll accumulator.             |
| `draw`              | `(cam_x, cam_y: number)`   | Draw with explicit camera position.         |
| `drawAuto`          | `()`                       | Draw using `SharedState.camera.position`.   |
| `resetAutoscroll`   | `()`                       | Reset accumulator to zero.                  |
| `setScrollFactor`   | `(x, y: number)`           | Set parallax factor.                        |
| `getScrollFactor`   | `() -> number, number`     | Get parallax factor.                        |
| `setOffset`         | `(x, y: number)`           | Set pixel offset.                           |
| `getOffset`         | `() -> number, number`     | Get pixel offset.                           |
| `setAutoscroll`     | `(vx, vy: number)`         | Set autonomous velocity (px/s).             |
| `getAutoscroll`     | `() -> number, number`     | Get autonomous velocity.                    |
| `setRepeat`         | `(rx, ry: boolean)`        | Set tiling axes.                            |
| `setScale`          | `(sx, sy: number)`         | Set display scale.                          |
| `setZ`              | `(z: integer)`             | Set draw order.                             |
| `getZ`              | `() -> integer`            | Get draw order.                             |
| `setOpacity`        | `(a: number)`              | Set opacity `[0, 1]`.                       |
| `getOpacity`        | `() -> number`             | Get opacity.                                |
| `setTint`           | `(r, g, b, a: number)`     | Set RGBA tint.                              |
| `getTint`           | `() -> number×4`           | Get RGBA tint.                              |
| `setBlendMode`      | `(mode: string)`           | Set blend mode name.                        |
| `getBlendMode`      | `() -> string`             | Get blend mode name.                        |
| `setVisible`        | `(v: boolean)`             | Set visibility.                             |
| `isVisible`         | `() -> boolean`            | Get visibility.                             |
| `setClamp`          | `(minX, minY, maxX, maxY)` | Clamp scroll range.                         |
| `clearClamp`        | `()`                       | Remove scroll clamping.                     |

### `LuaParallaxSet` Methods

| Method          | Signature                  | Description                                  |
|-----------------|----------------------------|----------------------------------------------|
| `type`          | `() -> string`             | Returns `"ParallaxSet"`.                     |
| `addLayer`      | `(layer: LuaParallaxLayer)`| Add layer; re-sorts by z.                    |
| `removeLayerAt` | `(index: integer) -> bool` | Remove by 1-based index.                     |
| `layerCount`    | `() -> integer`            | Number of layers.                            |
| `sortByZ`       | `()`                       | Re-sort layers by z after `setZ()` calls.    |
| `update`        | `(dt: number)`             | Advance all layers.                          |
| `draw`          | `(cam_x, cam_y: number)`   | Draw all layers in z order.                  |
| `drawAuto`      | `()`                       | Draw using `SharedState.camera.position`.    |
| `setVisible`    | `(v: boolean)`             | Hide/show all layers.                        |
| `isVisible`     | `() -> boolean`            | Visibility of the set.                       |
| `getName`       | `() -> string`             | Get set name.                                |
| `setName`       | `(name: string)`           | Set set name.                                |

---

## Lua Examples

```lua
-- Single parallax layer with horizontal autoscroll
local sky_img = lurek.graphic.newImage("assets/sky.png")

local sky = lurek.parallax.newLayer({
    texture        = sky_img,
    scroll_factor_x = 0.2,   -- slow parallax
    autoscroll_x   = 30.0,   -- 30 px/s rightward drift
    repeat_x       = true,
    z              = -10,
})

lurek.process = function(dt)
    sky:update(dt)
end

lurek.render = function()
    local cx, cy = lurek.camera.getPosition()
    sky:draw(cx, cy)
end

-- Multi-layer ParallaxSet (far → near layers automatically sorted by z)
local far_img  = lurek.graphic.newImage("assets/mountains.png")
local mid_img  = lurek.graphic.newImage("assets/trees.png")
local near_img = lurek.graphic.newImage("assets/grass.png")

local bg = lurek.parallax.newSet("background")
bg:addLayer(lurek.parallax.newLayer({ texture = far_img,  scroll_factor_x = 0.1, z = -30 }))
bg:addLayer(lurek.parallax.newLayer({ texture = mid_img,  scroll_factor_x = 0.4, z = -20 }))
bg:addLayer(lurek.parallax.newLayer({ texture = near_img, scroll_factor_x = 0.8, z = -10 }))

lurek.process = function(dt) bg:update(dt) end
lurek.render  = function()
    local cx, cy = lurek.camera.getPosition()
    bg:draw(cx, cy)
end

-- Day/night crossfade using opacity
local day_layer   = lurek.parallax.newLayer({ texture = day_img,   z = -5 })
local night_layer = lurek.parallax.newLayer({ texture = night_img, z = -5, opacity = 0.0 })

function set_time_of_day(t)   -- t in [0,1]: 0=day, 1=night
    day_layer:setOpacity(1.0 - t)
    night_layer:setOpacity(t)
end
```

## Item Summary

| Kind                | Count |
|---------------------|-------|
| Structs             | 2     |
| Enums               | 0     |
| Functions (Lua API) | 2     |
| UserData methods    | 25    |
| **Total**           | **29** |

## References

| Module      | Relationship                                                                      |
|-------------|-----------------------------------------------------------------------------------|
| `runtime`   | Imports `SharedState` (camera position for `drawAuto`) and `TextureKey`.          |
| `render`    | Imports `BlendMode` and `RenderCommand::DrawImageEx` / `SetColor` to issue draws. |
| `camera`    | `drawAuto` reads `SharedState::camera.position` for automatic scroll calculation. |
| `lua_api`   | `src/lua_api/parallax_api.rs` owns `LuaParallaxLayer`, `LuaParallaxSet` UserData. |
| `render_api`| `LuaImage` is imported from `render_api` to unwrap the `TextureKey` from the texture option. |

## Notes

- **Tier 2**: `parallax` imports `crate::runtime` and `crate::render` — both Tier 1 — so it sits at Tier 2. It must not be imported by any Tier 1 module.
- **CPU tiling**: The current implementation tiles textures on the CPU by generating multiple `DrawImageEx` commands. For N ≤ 8 layers with ≤ 4 tiles each, the overhead is negligible (<5 µs on Intel UHD).
- **Future GPU path**: A `RenderCommand::DrawTiledImage` variant with `address_mode: Repeat` on the wgpu sampler would reduce draw calls from 4× to 1× per layer.
- **Autoscroll bounds**: `autoscroll_accum` uses `rem_euclid` to stay within `[0, tex_w]` so it never grows unboundedly across long sessions.
- **`drawAuto` vs `draw`**: `drawAuto` borrows `SharedState` internally to read the camera position. Do not hold a `RefMut<SharedState>` while calling `drawAuto`.
- **Breaking change surface**: Changing the `ParallaxDrawBatch` field layout or the `newLayer` options table keys is a breaking change for existing game scripts.
