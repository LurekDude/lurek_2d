# `camera` — Agent Reference

| Property       | Value                                    |
|----------------|------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems          |
| **Status**     | Implemented — Full                       |
| **Lua API**    | `luna.camera`                            |
| **Source**      | `src/camera/`                            |
| **Rust Tests** | `tests/rust/unit/camera_tests.rs`        |
| **Lua Tests**  | `tests/lua/unit/test_camera.lua`         |
| **Architecture** | —                                      |

## Summary

The `camera` module provides camera and viewport types for 2D rendering. It is a Tier 1 engine module extracted from `src/graphics/` during the graphics-module-split session; it depends only on `crate::math` (Vec2, Mat3, Rect) and never imports wgpu, winit, or any other engine module. `SharedState` holds a `Camera` field accessed by the GPU renderer each frame to apply the view transform to all draw commands.

Two camera types are provided. `Camera` is the original flat camera with position, zoom, and rotation that powers the `luna.graphics.setCamera()` API — it produces a `Mat3` view matrix combining translation, rotation, and uniform scale. `Camera2D` is the full-featured Phase 24 camera with smooth follow (configurable interpolation speed), dead-zone (the camera ignores target movement within a rectangle centred on the camera), look-ahead (velocity-based prediction), world-space bounds clamping (the visible area never extends beyond configured bounds), and screen-shake (deterministic sinusoidal offset that decays over time). `Camera2D` exposes its own `update(dt)` method to advance all simulation and a `view_matrix()` that incorporates shake offset.

Two viewport types handle virtual-resolution mapping. `Viewport` maps a fixed game resolution onto an arbitrary window size using one of three `ScaleMode` strategies (Letterbox, Stretch, PixelPerfect) and provides coordinate conversion between screen and game space. `ViewportScale` extends `Viewport` by additionally tracking `scaled_width` and `scaled_height` — the game area in window pixels after scaling — for integration with the automatic graphics transform stack.

**Scope boundary**: This module contains pure camera math and viewport logic only. Render-pass binding, GPU uniform upload, and wgpu types live in `src/graphics/gpu_renderer.rs`. No external crate dependencies exist beyond the standard library.

## Architecture

```
camera (Tier 1 — depends only on crate::math)
│
├── types.rs
│   ├── Camera          ← position / zoom / rotation → view_matrix() → Mat3
│   │   └── Used by SharedState for luna.graphics.setCamera()
│   │
│   └── Camera2D        ← full 2D camera with simulation
│       ├── Follow system: target → dead zone → look-ahead → smooth lerp
│       ├── Shake system: intensity × decay → offset injected into view_matrix
│       ├── Bounds clamping: half-viewport vs world bounds
│       ├── Coordinate conversion: toWorld / toScreen / getVisibleArea
│       └── update(dt) drives follow + shake + clamp each frame
│
├── viewport.rs
│   ├── ScaleMode       ← Letterbox | Stretch | PixelPerfect
│   └── Viewport        ← game_dims × window_dims → scale + offset
│       └── resize() recomputes; to_game() / to_screen() convert coords
│
└── viewport_scale.rs
    └── ViewportScale   ← extends Viewport with scaled_width / scaled_height
        └── resize() also updates scaled dimensions for transform stack
```

## Source Files

| File                | Purpose                                                                                 |
|---------------------|-----------------------------------------------------------------------------------------|
| `types.rs`          | `Camera` (flat API) and `Camera2D` (smooth follow, dead zone, bounds, shake) structs    |
| `viewport.rs`       | `ScaleMode` enum and `Viewport` struct for virtual-resolution mapping                   |
| `viewport_scale.rs` | `ViewportScale` struct — `Viewport` variant with automatic scaled-dimension tracking     |

## Submodules

### `camera::types`

Camera types for 2D viewport control. Provides the original `Camera` (used by `SharedState` for the flat `luna.graphics.setCamera()` API) and the full-featured `Camera2D` with smooth follow, dead zone, bounds clamping, look-ahead, and screen-shake.

- **`Camera`** (struct): Basic camera with position, zoom, and rotation; produces a `Mat3` view matrix.
- **`Camera2D`** (struct): Full-featured 2D camera with follow system, shake, bounds clamping, and coordinate conversion.

### `camera::viewport`

Virtual-resolution viewport with manual transform application. Maps a fixed game resolution onto an arbitrary window size using letterboxing, stretching, or pixel-perfect scaling.

- **`Viewport`** (struct): Maintains scale and offset for mapping game coordinates to window pixels.
- **`ScaleMode`** (enum): Scale strategy — `Letterbox`, `Stretch`, or `PixelPerfect`.

### `camera::viewport_scale`

Virtual-resolution viewport with automatic scaling and transform-stack integration. Tracks `scaled_width` and `scaled_height` in addition to the base viewport fields.

- **`ViewportScale`** (struct): Extends the viewport concept with cached scaled content dimensions.

## Key Types

### Structs

#### `camera::types::Camera`

Basic camera with position, zoom, and rotation. Used by `SharedState` for the flat `luna.graphics.setCamera()` API. Exposes `view_matrix()` which combines translation (negate position), rotation, and scale (zoom) into a single `Mat3`. Default state is origin position, zoom 1.0, rotation 0.0.

Public methods: `new(position, zoom, rotation)`, `view_matrix()`, `set_position(pos)`, `set_zoom(zoom)`, `set_rotation(rotation)`.

#### `camera::types::Camera2D`

Full-featured 2D camera with smooth follow, dead zone, look-ahead, world-space bounds clamping, and screen-shake. Constructed with viewport dimensions via `Camera2D::new(viewport_w, viewport_h)`. Call `update(dt)` each frame to advance the follow interpolation, bounds clamping, and shake decay. Call `view_matrix()` to obtain the final transform (including shake offset) for rendering.

Fields include: `position`, `zoom`, `rotation`, `viewport` (Rect), `bounds` (Option<Rect>), `target` (Option<Vec2>), `follow_smooth`, `dead_zone` (Option<(f32, f32)>), `look_ahead`.

Public methods: `new`, `set_position`, `get_position`, `set_zoom`, `get_zoom`, `set_rotation`, `get_rotation`, `set_viewport`, `get_viewport`, `set_bounds`, `get_bounds`, `remove_bounds`, `has_bounds`, `move_by`, `look_at`, `to_world_coords`, `to_screen_coords`, `get_visible_area`, `set_dead_zone`, `get_dead_zone`, `set_target`, `get_target`, `clear_target`, `set_follow_smooth`, `get_follow_smooth`, `set_look_ahead`, `get_look_ahead`, `shake`, `update`, `view_matrix`.

#### `camera::viewport::Viewport`

Virtual-resolution viewport that maps a fixed game coordinate space onto the actual window pixel dimensions. Maintains `scale_x`, `scale_y`, `offset_x`, `offset_y` computed by `resize(window_width, window_height)` according to the active `ScaleMode`. Provides `to_game(screen_x, screen_y)` and `to_screen(game_x, game_y)` for coordinate conversion.

Public methods: `new`, `resize`, `get_scale`, `get_offset`, `get_game_dimensions`, `get_scale_mode`, `set_scale_mode`, `to_game`, `to_screen`.

#### `camera::viewport_scale::ViewportScale`

Extends the basic viewport concept by also computing `scaled_width` and `scaled_height`, which represent the game area in window pixels after scaling. Useful for transform-stack integration where the renderer needs the actual pixel footprint of the game area.

Public methods: `new`, `resize`, `get_game_dimensions`, `get_scaled_dimensions`, `get_offset`, `get_scale`, `get_mode`, `to_game_coords`, `to_screen_coords`.

### Enums

#### `camera::viewport::ScaleMode`

Scale mode for virtual-resolution mapping.

- `Letterbox` — Uniform scale with black bars to preserve aspect ratio.
- `Stretch` — Non-uniform scale that fills the entire window.
- `PixelPerfect` — Integer-only scale for crisp pixel art.

## Lua API

Exposed under `luna.camera.*` by `src/lua_api/camera_api.rs`.

The Lua API provides a `Camera2D` userdata object created via `luna.camera.new(viewport_w, viewport_h)`. The userdata wraps a `Camera2D` instance behind `Rc<RefCell<Camera2D>>` and exposes methods for position, zoom, rotation, viewport, bounds, follow system, shake, coordinate conversion, and per-frame update.

**Note**: The flat `Camera` struct is not directly exposed via `luna.camera`; it is used internally by `SharedState` and accessible through `luna.graphics.setCamera()` / `luna.graphics.getCamera()`.

### Module-level functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `luna.camera.new` | `(viewport_w, viewport_h) → Camera2D` | Creates a new Camera2D userdata |

### Camera2D methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `:setPosition` | `(x, y) → nil` | Sets world-space position |
| `:getPosition` | `() → x, y` | Returns world-space position |
| `:setZoom` | `(zoom) → nil` | Sets uniform zoom factor |
| `:getZoom` | `() → number` | Returns current zoom |
| `:setRotation` | `(r) → nil` | Sets rotation in radians |
| `:getRotation` | `() → number` | Returns rotation in radians |
| `:setViewport` | `(x, y, w, h) → nil` | Sets viewport rectangle in screen pixels |
| `:getViewport` | `() → x, y, w, h` | Returns viewport rectangle |
| `:setBounds` | `(x, y, w, h) → nil` | Sets world-space bounds for clamping |
| `:removeBounds` | `() → nil` | Removes world-space bounds |
| `:setTarget` | `(x, y) → nil` | Sets follow target position |
| `:clearTarget` | `() → nil` | Clears the follow target |
| `:setFollowSmooth` | `(speed) → nil` | Sets follow interpolation speed (0 = snap) |
| `:setDeadZone` | `(w, h) → nil` | Sets dead zone half-extents |
| `:setLookAhead` | `(mul) → nil` | Sets look-ahead multiplier |
| `:shake` | `(intensity, duration) → nil` | Starts screen-shake effect |
| `:update` | `(dt) → nil` | Advances follow, shake, and bounds each frame |
| `:toWorld` | `(sx, sy) → wx, wy` | Converts screen coordinates to world |
| `:toScreen` | `(wx, wy) → sx, sy` | Converts world coordinates to screen |
| `:getVisibleArea` | `() → x, y, w, h` | Returns visible world-space AABB |
| `:lookAt` | `(x, y) → nil` | Instantly moves camera to position |
| `:move` | `(dx, dy) → nil` | Translates camera by delta |

## Lua Examples

```lua
-- Basic camera setup with smooth follow
local cam
local player = { x = 400, y = 300 }

function luna.load()
    cam = luna.camera.new(800, 600)
    cam:setFollowSmooth(5.0)
    cam:setDeadZone(50, 30)
    cam:setBounds(0, 0, 2000, 1500)
end

function luna.update(dt)
    -- Move player with arrow keys
    if luna.keyboard.isDown("right") then player.x = player.x + 200 * dt end
    if luna.keyboard.isDown("left")  then player.x = player.x - 200 * dt end
    if luna.keyboard.isDown("down")  then player.y = player.y + 200 * dt end
    if luna.keyboard.isDown("up")    then player.y = player.y - 200 * dt end

    cam:setTarget(player.x, player.y)
    cam:update(dt)
end

function luna.draw()
    -- Use camera transform for drawing
    local wx, wy = cam:toScreen(player.x, player.y)
    luna.graphics.circle("fill", wx, wy, 16)
end
```

```lua
-- Screen shake on key press
function luna.keypressed(key)
    if key == "space" then
        cam:shake(8, 0.3)   -- 8 pixel intensity, 0.3 seconds
    end
end
```

```lua
-- Coordinate conversion: screen click to world position
function luna.mousepressed(x, y, btn)
    local world_x, world_y = cam:toWorld(x, y)
    print("Clicked world position:", world_x, world_y)
end
```

## Item Summary

| Kind      | Count  |
|-----------|--------|
| `struct`  | 4      |
| `enum`    | 1      |
| `fn`      | 53     |
| **Total** | **58** |

## References

| Module     | Relationship | Notes                                                  |
|------------|--------------|--------------------------------------------------------|
| `math`     | Imports from | `Vec2`, `Mat3`, `Rect` — sole dependency of this module |
| `engine`   | Imported by  | `SharedState` holds a `Camera` field                    |
| `graphics` | Related      | GPU renderer reads `Camera` from `SharedState` for view transforms; viewport types were extracted from graphics during module split |
| `lua_api`  | Imported by  | `camera_api.rs` binds `Camera2D` to `luna.camera.*`     |

**Similar modules**:
- `camera` vs `graphics`: Camera owns the math (position, zoom, rotation → `Mat3`); graphics owns the GPU pipeline that consumes the matrix. No wgpu types appear in `camera`.

## Notes

- **Pure math module**: `camera` has zero external crate dependencies. It uses only `crate::math` types (`Vec2`, `Mat3`, `Rect`). This makes it safe to use in headless tests without GPU or window initialization.
- **`Camera` vs `Camera2D`**: `Camera` is the legacy flat struct stored in `SharedState`. `Camera2D` is the full-featured userdata exposed via `luna.camera.new()`. They are independent types — `Camera2D` does not wrap or inherit from `Camera`.
- **Shake determinism**: Screen-shake uses `sin(timer * constant)` for offset calculation, making it frame-rate dependent but deterministic for a given `dt` sequence. The shake decays linearly with remaining time.
- **Dead zone convention**: `set_dead_zone(w, h)` takes full extents but stores half-extents internally. `get_dead_zone()` returns full extents.
- **Bounds clamping edge case**: When the visible area is larger than the bounds (e.g., zoomed out too far), the camera centers on the bounds rather than clamping to corners.
- **Viewport types are not exposed to Lua**: `Viewport` and `ViewportScale` are used internally by the engine. Only `Camera2D` is accessible from Lua via `luna.camera`.
- **Breaking change surface**: Renaming or removing any `Camera2D` method in `camera_api.rs` will break Lua scripts that use `luna.camera.new()` and call methods on the result.
