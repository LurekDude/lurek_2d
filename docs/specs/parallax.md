# parallax — Parallax Background Layer System

## 1. Purpose

The `parallax` module implements a CPU-driven, multi-layer 2D scrolling
background system for the Lurek2D engine.  Each layer scrolls at a configurable
speed relative to a world camera position, supports autonomous drift (autoscroll),
horizontal and/or vertical tiling, z-ordering, opacity, per-layer blend modes,
and tint.  Multiple layers can be grouped into a `ParallaxSet` for scene-level
management and batch update/draw calls.


## Source Files

| File        | Purpose                                                           |
|-------------|-------------------------------------------------------------------|
| `layer.rs`  | `ParallaxLayer`, `ParallaxDrawBatch` — pure Rust, no mlua            |
| `mod.rs`    | Module root; re-exports `ParallaxLayer`, `ParallaxDrawBatch`      |

## 2. Architecture

```
src/parallax/layer.rs          → domain module: pure Rust, no mlua
src/parallax/mod.rs            → re-exports ParallaxLayer, ParallaxDrawBatch
src/lua_api/parallax_api.rs    → Lua bridge: LuaParallaxLayer, LuaParallaxSet
```

**Tier 2** — imports `crate::engine` (TextureKey, SharedState) and
`crate::graphics` (BlendMode, RenderCommand).  Zero imports of any Tier 1
domain module.

**No new RenderCommand variant** — V1 uses the existing `DrawImageEx` variant with
multiple tile copies per repeat axis.  A future `DrawTiledImage` GPU path would
reduce the draw call count for wide tiling scenarios.

## 3. Scroll Formula

```
autoscroll_accum += autoscroll * dt          (rem_euclid to stay bounded)
raw_x = camera_x * scroll_factor_x + offset_x + autoscroll_accum_x
raw_y = camera_y * scroll_factor_y + offset_y + autoscroll_accum_y
raw_x = clamp(raw_x, clamp_min_x, clamp_max_x)    (if clamp active)
start_x = -(raw_x % tex_w * scale_x)              (for repeat_x = true)
```

For repeat axes the renderer tiles from `start_x` across the full screen width
(and similarly for Y).  For non-repeat axes a single draw places the texture at
`start_x`.

## 4. Domain Types (`src/parallax/layer.rs`)

### `ParallaxDrawBatch`

Returned by `ParallaxLayer::build_draw_calls()`.  Consumed by the Lua API bridge
to push `RenderCommand` entries.

| Field | Type | Meaning |
|---|---|---|
| `texture_key` | `TextureKey` | Texture to draw |
| `tiles` | `Vec<(f32, f32)>` | Screen-space (x, y) origins for each tile copy |
| `sx` | `f32` | Horizontal display scale (texture pixels to screen pixels) |
| `sy` | `f32` | Vertical display scale |
| `color` | `[f32; 4]` | Pre-multiplied RGBA from `tint * opacity` |
| `blend_mode` | `BlendMode` | GPU blend mode |

### `ParallaxLayer`

| Field | Type | Default |
|---|---|---|
| `texture_key` | `TextureKey` | — (required) |
| `texture_width` | `f32` | — (from asset) |
| `texture_height` | `f32` | — (from asset) |
| `scroll_factor` | `[f32; 2]` | `[1.0, 0.0]` |
| `offset` | `[f32; 2]` | `[0.0, 0.0]` |
| `autoscroll` | `[f32; 2]` | `[0.0, 0.0]` px/s |
| `autoscroll_accum` | `[f32; 2]` | `[0.0, 0.0]` |
| `repeat_x` | `bool` | `true` |
| `repeat_y` | `bool` | `false` |
| `clamp_min` | `Option<[f32; 2]>` | `None` |
| `clamp_max` | `Option<[f32; 2]>` | `None` |
| `z` | `i32` | `0` |
| `opacity` | `f32` | `1.0` |
| `tint` | `[f32; 4]` | `[1, 1, 1, 1]` |
| `blend_mode` | `BlendMode` | `Alpha` |
| `visible` | `bool` | `true` |
| `scale` | `[f32; 2]` | `[1.0, 1.0]` |

### Key Methods

| Method | Signature | Notes |
|---|---|---|
| `new` | `(key, w, h) -> Self` | Sets defaults |
| `update` | `(&mut self, dt: f32)` | Advances autoscroll_accum via `rem_euclid` |
| `compute_pixel_offset` | `(&self, cam_x, cam_y) -> [f32; 2]` | Applies scroll_factor, offset, clamp |
| `build_draw_calls` | `(&self, cx, cy, sw, sh) -> Option<Batch>` | Returns `None` if invisible |
| `reset_autoscroll` | `(&mut self)` | Sets accum to `[0, 0]` — use on scene transition |

## 5. Lua API (`src/lua_api/parallax_api.rs`)

All bindings live under `lurek.parallax`.

### Module-Level Functions

| Function | Signature | Returns |
|---|---|---|
| `newLayer` | `(opts: table) -> LuaParallaxLayer` | New layer from options table |
| `newSet` | `(name: string) -> LuaParallaxSet` | Empty named set |

**`newLayer` options table fields:**

| Field | Type | Default |
|---|---|---|
| `texture` | `LuaImage` (required) | — |
| `scroll_factor_x` | `number` | `1.0` |
| `scroll_factor_y` | `number` | `0.0` |
| `offset_x` | `number` | `0.0` |
| `offset_y` | `number` | `0.0` |
| `autoscroll_x` | `number` | `0.0` |
| `autoscroll_y` | `number` | `0.0` |
| `repeat_x` | `boolean` | `true` |
| `repeat_y` | `boolean` | `false` |
| `z` | `integer` | `0` |
| `opacity` | `number` | `1.0` |
| `tint_r / tint_g / tint_b / tint_a` | `number` | `1.0` each |
| `blend_mode` | `string` | `"alpha"` |
| `visible` | `boolean` | `true` |
| `scale_x / scale_y` | `number` | `1.0` each |

### `LuaParallaxLayer` Methods

| Method | Signature | Notes |
|---|---|---|
| `type` | `() -> string` | `"ParallaxLayer"` |
| `update` | `(dt: number)` | Advance autoscroll accumulator |
| `draw` | `(cam_x, cam_y: number)` | Explicit camera position |
| `drawAuto` | `()` | Uses `SharedState.camera.position` |
| `resetAutoscroll` | `()` | Reset accumulator to zero |
| `setScrollFactor` | `(x, y: number)` | |
| `getScrollFactor` | `() -> number, number` | |
| `setOffset` | `(x, y: number)` | |
| `getOffset` | `() -> number, number` | |
| `setAutoscroll` | `(vx, vy: number)` | Pixels per second |
| `getAutoscroll` | `() -> number, number` | |
| `setRepeat` | `(rx, ry: boolean)` | |
| `setScale` | `(sx, sy: number)` | |
| `setZ` | `(z: integer)` | |
| `getZ` | `() -> integer` | |
| `setOpacity` | `(a: number)` | Clamped to `[0, 1]` |
| `getOpacity` | `() -> number` | |
| `setTint` | `(r, g, b, a: number)` | |
| `getTint` | `() -> number, number, number, number` | |
| `setBlendMode` | `(mode: string)` | `"alpha"/"add"/"multiply"/"replace"/"screen"` |
| `getBlendMode` | `() -> string` | |
| `setVisible` | `(v: boolean)` | |
| `isVisible` | `() -> boolean` | |
| `setClamp` | `(min_x, min_y, max_x, max_y: number)` | |
| `clearClamp` | `()` | |

### `LuaParallaxSet` Methods

| Method | Signature | Notes |
|---|---|---|
| `type` | `() -> string` | `"ParallaxSet"` |
| `addLayer` | `(layer: LuaParallaxLayer)` | Adds by shared Rc; re-sorts by z |
| `removeLayerAt` | `(index: integer) -> boolean` | 1-based index |
| `layerCount` | `() -> integer` | |
| `sortByZ` | `()` | Call after `layer:setZ()` |
| `update` | `(dt: number)` | Advances all layers |
| `draw` | `(cam_x, cam_y: number)` | Draws in z order |
| `drawAuto` | `()` | Uses `SharedState.camera.position` |
| `setVisible` | `(v: boolean)` | |
| `isVisible` | `() -> boolean` | |
| `getName` | `() -> string` | |
| `setName` | `(name: string)` | |

## 6. GPU Optimisation Notes

V1 uses the existing `DrawImageEx` for each tile.  For a typical N≤8 layer
background with 2–4 horizontal tiles per layer the overhead is bounded and
negligible on Intel UHD hardware.

**Future path** — Add `RenderCommand::DrawTiledImage { texture_key, sx, sy, u_offset, v_offset }` as a single GPU draw call per layer.  The GPU samples a wrapping texture coordinate (`u = (screen_x / tex_w + u_offset) mod 1.0`) which completely eliminates CPU tiling arithmetic and reduces draw call count from 4× to 1× per layer.  This requires a WGSL shader variant with `address_mode: Repeat` on the sampler.

## 7. Threading Notes

Autoscroll is a simple float accumulation: `pos += vel * dt; pos = pos.rem_euclid(tex_w)`.  There is no data-dependency between layers.  However, the per-frame CPU budget for N≤16 layers is < 5 µs, far below the 500 µs Lua→Rust boundary cost.  Parallelism via `lurek.thread` offers no practical benefit for this module.

If a game spawns hundreds of layers (procedural backgrounds) a Rayon parallel iterator could bring update time from ~50 µs to ~5 µs but this is not required for the target hardware (Intel UHD, 60 FPS at 1080p).

## 8. Physics Integration (Lua Level Only)

Physical forces (wind, water current) are applied to parallax at the **Lua script level** — the `physics` module has no direct connection to `parallax`.

### Wind autoscroll

```lua
-- bg_layer is a ParallaxLayer with autoscroll_x = 0.0 initially
function apply_wind(dt, strength)
    bg_layer:setAutoscroll(strength * 80.0, 0.0)
    bg_layer:update(dt)
end
```

### Physics-body–driven camera

```lua
-- In lurek.process(dt):
local body_x, body_y = player_body:getPosition()
lurek.camera.setPosition(body_x - 400, body_y - 300)  -- centre on player

-- In lurek.render():
local cx, cy = lurek.camera.getPosition()
for _, layer in ipairs(parallax_layers) do
    layer:draw(cx, cy)
end
```

### Water-resistance layer

A deep-water foreground can scroll slightly slower than the camera to suggest
depth.  Set `scroll_factor = 0.95` and give it a blue tint.

## 9. Scene Transition Recipes

### Instant cut

```lua
function on_scene_change()
    local set = active_parallax_set
    set:setVisible(false)
    -- Reset every layer's autoscroll so ambient drift restarts from zero
    for i = 1, set:layerCount() do
        -- Access layers through your own table; set does not expose iteration
    end
    set:setVisible(true)
end
```

### Crossfade (day → night)

```lua
function cross_fade(day_layer, night_layer, t)
    -- t in [0, 1]: 0 = full day, 1 = full night
    day_layer:setOpacity(1.0 - t)
    night_layer:setOpacity(t)
end
```

### Layer swap on scene load

```lua
local scene_sets = {
    forest = lurek.parallax.newSet("forest"),
    cave   = lurek.parallax.newSet("cave"),
}
local active = scene_sets.forest

function switch_scene(name)
    active:setVisible(false)
    active = scene_sets[name]
    active:setVisible(true)
end
```

## 10. Performance Guidance

| Layers | Tiles/layer | Draw calls | Estimated time (Intel UHD) |
|---|---|---|---|
| 4 | 2 | 8 | < 1 µs GPU record |
| 8 | 4 | 32 | ~3 µs GPU record |
| 16 | 4 | 64 | ~6 µs GPU record |

The CPU tiling loop in `build_draw_calls` is O(tiles_x × tiles_y) per layer.
For repeat_x with a 128-px texture on a 1920-px screen: ceil(1920/128) + 1 = 16
tiles.  At 16 layers that is 256 `DrawImageEx` pushes per frame — still well
under the 500 µs total Lua→Rust overhead.

Keep layers below 32 for safety.  Use `setVisible(false)` to skip invisible
layers entirely (the batch builder returns `None` early).

## 11. Cross-Artifact Sync Contract

When modifying this module, also update:

| Changed | Must also update |
|---|---|
| `src/parallax/*.rs` | `src/parallax/AGENT.md` · `docs/specs/parallax.md` |
| `src/lua_api/parallax_api.rs` | `docs/specs/parallax.md` § 5 · `docs/API/lua-api.md` (run `gen_all_docs.py`) |
| Any `lurek.parallax.*` API | `content/examples/parallax.lua` · any demos using parallax |
| Any change at all | `docs/CHANGELOG.md` |
