# `animation` � Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 � Core Engine Subsystems                      |
| **Status**     | Implemented � Full                                   |
| **Lua API**    | `lurek.animation`                                     |
| **Source**     | `src/animation/`                                     |
| **Rust Tests** | `tests/rust/unit/animation_tests.rs`                 |
| **Lua Tests**  | `tests/lua/unit/test_animation.lua`                  |
| **Architecture** | �                                                  |

## Summary

The `animation` module provides frame-based sprite animation for 2D sprite-sheets. It manages a pool of `AnimFrame` source-rectangles and named `AnimClip` sequences (FPS, looping flag, frame-index list). The `Animation` controller advances frames on `update(dt)`, emits events (`Finished`, `FrameChanged`, `Looped`) via `drain_events()`, and exposes `current_quad()` for the draw rectangle. Speed multiplier scales delta time globally; per-frame duration overrides override clip FPS.

Scripts call `lurek.animation.new()` to create a `LuaAnimation` UserData with 20 methods. Depends only on `math` and `engine` — no GPU, audio, or physics code. Distinct from `spine` (bone-hierarchy animation); the two modules are independent.

## Architecture

```
lurek.animation.new()
        -
        �
-����������������������������������������������������������
-                    Animation                            -
-                 (controller.rs)                         -
-                                                         -
-  frames: Vec<AnimFrame>     <�� addFrame / addFrames-  -
-                                   FromGrid              -
-  clips: HashMap<String,     <�� addClip / addClip-     -
-          AnimClip>                FromGrid              -
-                                                         -
-  play("walk") ��> current_clip ��> update(dt)          -
-                    current_frame_pos                     -
-                    timer (accumulator)                   -
-                    speed (multiplier)                    -
-                                                         -
-  update(dt) ��> pending_events: Vec<AnimEvent>          -
-                  +�� FrameChanged { frame_index }       -
-                  +�� Looped                              -
-                  L�� Finished                            -
-                                                         -
-  current_quad() ��> Option<Rect>                        -
-  drain_events() ��> Vec<AnimEvent>                      -
L���������������������������������������������������������-
        -                       -
        �                       �
  -������������          -�������������
  - AnimFrame -          -  AnimClip  -
  - (frame.rs)-          - (clip.rs)  -
  -           -          -            -
  - quad: Rect-          - name       -
  - duration  -          - frame_idx[]-
  L�����������-          - fps        -
                         - looping    -
                         L������������-
```

## Source Files

| File            | Purpose                                                                  |
|-----------------|--------------------------------------------------------------------------|
| `mod.rs`        | Module root � declares submodules and re-exports `AnimClip`, `Animation`, `AnimEvent`, `AnimFrame`, `AnimationFrame`. |
| `clip.rs`       | `AnimClip` � a named animation clip with frame indices, FPS, and loop flag. |
| `controller.rs` | `Animation` � the main playback controller with frame pool, clip registry, update loop, and event queue. |
| `event.rs`      | `AnimEvent` � enum of playback events (`Finished`, `FrameChanged`, `Looped`). |
| `frame.rs`      | `AnimFrame` � a single frame with a source rectangle and optional duration override. Also defines `AnimationFrame` type alias. |

## Submodules

### `animation::clip`

Named animation clip referencing frames by index into the parent `Animation`'s frame pool.

- **`AnimClip`** (struct): A clip with a `name`, `frame_indices` (Vec of 0-based indices), `fps` playback rate, and `looping` flag.

### `animation::controller`

Main animation controller that owns the frame pool, clip registry, and drives playback.

- **`Animation`** (struct): Playback controller with frame pool, named clips, speed multiplier, timer accumulator, and pending event queue. Provides 21 public methods for frame/clip management, playback control, and state queries.

### `animation::event`

Events emitted by `Animation::update()` during frame advancement.

- **`AnimEvent`** (enum): Playback notification � `Finished` (non-looping clip ended), `FrameChanged { frame_index }` (frame advanced), `Looped` (looping clip wrapped).

### `animation::frame`

Single animation frame data.

- **`AnimFrame`** (struct): Source rectangle (`quad: Rect`) and optional per-frame `duration` override in seconds.
- **`AnimationFrame`** (type alias): Backward-compatible alias for `AnimFrame`.

## Key Types

### Structs

#### `animation::clip::AnimClip`

A named animation clip that references frames by index into the parent `Animation`'s frame pool. Fields: `name: String` (human-readable clip name), `frame_indices: Vec<usize>` (0-based indices into `Animation::frames`), `fps: f32` (playback speed in frames per second), `looping: bool` (whether the clip wraps after the last frame). Derives `Debug, Clone`.

#### `animation::controller::Animation`

Sprite animation controller with named clips, speed control, and playback events. Stores a `frames: Vec<AnimFrame>` pool, a `clips: HashMap<String, AnimClip>` registry, and playback state: `current_clip: Option<String>`, `current_frame_pos: usize`, `timer: f32`, `playing: bool`, `speed: f32`, `pending_events: Vec<AnimEvent>`. All fields are private � access is through public methods.

Key public methods:
- **Frame management**: `add_frame(quad) � usize`, `add_frames_from_grid(tex_w, tex_h, frame_w, frame_h, start, count) � usize`
- **Clip management**: `add_clip(name, frame_indices, fps, looping)`, `add_clip_from_grid(name, tex_w, tex_h, frame_w, frame_h, start, count, fps, looping)`
- **Playback**: `play(name) � bool`, `stop()`, `pause()`, `resume()`, `update(dt)`, `set_frame(index)`
- **Queries**: `current_quad() � Option<Rect>`, `current_frame() � usize`, `get_current_clip() � Option<&str>`, `is_playing() � bool`, `is_looping() � bool`, `get_speed() � f32`, `set_speed(f32)`, `get_frame_count() � usize`, `get_clip_count() � usize`, `drain_events() � Vec<AnimEvent>`

Implements `Default` (delegates to `new()`).

#### `animation::frame::AnimFrame`

A single animation frame with a source rectangle and optional duration. Fields: `quad: Rect` (source rectangle within the sprite-sheet texture), `duration: f32` (per-frame duration override in seconds; when `> 0.0` takes priority over the clip's FPS, otherwise `1.0 / clip.fps` is used). Derives `Debug, Clone`.

### Enums

#### `animation::event::AnimEvent`

Events emitted by `Animation::update()`. Derives `Debug, Clone, PartialEq`.

Variants:
- **`Finished`** � A non-looping clip reached its final frame and stopped playback.
- **`FrameChanged { frame_index: usize }`** � The active frame changed to `frame_index` (0-based position within the clip's `frame_indices` list).
- **`Looped`** � A looping clip wrapped back to its first frame.

Public methods:
- `type_name() � &'static str` � Returns `"finished"`, `"frameChanged"`, or `"looped"`.
- `frame_index() � Option<usize>` � Returns the frame index for `FrameChanged`, or `None` for other variants.

## Lua API

Exposed under `lurek.animation.*` by `src/lua_api/animation_api.rs`.

The Lua API provides a single constructor on the module table and 20 methods on the returned `Animation` UserData object. The `LuaAnimation` wrapper owns its `Animation` directly (no SlotMap key).

### Module functions

| Function | Returns | Description |
|----------|---------|-------------|
| `lurek.animation.new()` | `Animation` | Creates a new, empty Animation controller. |

### Animation UserData methods

#### Frame management

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `addFrame(x, y, w, h)` | `number � 4` | `integer` | Adds a single frame by source rectangle and returns its 0-based index. |
| `addFramesFromGrid(tex_w, tex_h, frame_w, frame_h, start, count)` | `integer � 6` | `integer` | Slices a sprite-sheet grid into frames, appends them, returns count added. |

#### Clip management

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `addClip(name, indices, fps, looping)` | `string, table, number, boolean` | `nil` | Registers a named clip from explicit frame index table. |
| `addClipFromGrid(name, tex_w, tex_h, frame_w, frame_h, start, count, fps, looping)` | `string, int�4, int�2, number, boolean` | `nil` | Slices grid frames and creates a clip in one call. |

#### Playback control

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `play(name)` | `string` | `boolean` | Starts playback of the named clip. Returns `false` if clip not found. |
| `stop()` | � | `nil` | Stops playback and resets to frame 0. |
| `pause()` | � | `nil` | Pauses playback at the current frame. |
| `resume()` | � | `nil` | Resumes playback from the current frame. |
| `update(dt)` | `number` | `nil` | Advances the animation by `dt` seconds (scaled by speed). |
| `setFrame(index)` | `integer` | `nil` | Sets the playback position within the current clip (clamped). |

#### Queries

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `getQuad()` | � | `table?` | Returns `{x, y, w, h}` for the current frame, or `nil`. |
| `pollEvents()` | � | `table` | Drains pending events as `{{type="...", frame=N}, ...}`. |
| `isPlaying()` | � | `boolean` | Returns `true` if a clip is currently playing. |
| `isLooping()` | � | `boolean` | Returns `true` if the current clip loops. |
| `getClip()` | � | `string?` | Returns the name of the current clip, or `nil`. |
| `getSpeed()` | � | `number` | Returns the playback speed multiplier. |
| `setSpeed(speed)` | `number` | `nil` | Sets the playback speed multiplier. |
| `getFrameCount()` | � | `integer` | Returns the total number of frames in the pool. |
| `getClipCount()` | � | `integer` | Returns the number of registered clips. |
| `getCurrentFrame()` | � | `integer` | Returns the current position within the active clip (0-based). |

## Lua Examples

```lua
-- Sprite-sheet animation: walk cycle from a 4-frame grid
local anim

function lurek.init()
    anim = lurek.animation.new()

    -- Slice a 128�32 sprite-sheet into 4 cells of 32�32
    anim:addClipFromGrid("walk", 128, 32, 32, 32, 0, 4, 10, true)

    -- Add a second clip manually
    anim:addFrame(0, 64, 32, 32)   -- frame 4
    anim:addFrame(32, 64, 32, 32)  -- frame 5
    anim:addClip("idle", {4, 5}, 2, true)

    anim:play("walk")
end

function lurek.process(dt)
    anim:update(dt)

    -- Check for playback events
    local events = anim:pollEvents()
    for _, ev in ipairs(events) do
        if ev.type == "looped" then
            print("Walk cycle looped!")
        end
    end

    -- Switch clip on keypress
    if lurek.keyboard.isDown("space") then
        anim:play("idle")
    end
end

function lurek.render()
    local q = anim:getQuad()
    if q then
        -- Use the source quad with lurek.gfx.drawq()
        -- lurek.gfx.drawq(spriteSheet, q.x, q.y, q.w, q.h, drawX, drawY)
    end
end
```

## Item Summary

| Kind       | Count  |
|------------|--------|
| `struct`   | 3      |
| `enum`     | 1      |
| `fn`       | 23     |
| **Total**  | **27** |

## References

| Module     | Relationship | Notes                                                                 |
|------------|--------------|-----------------------------------------------------------------------|
| `math`     | Imports from | Uses `Rect` for frame source quads.                                  |
| `engine`   | Imports from | Uses `log_messages` for structured debug/warn log entries.            |
| `lua_api`  | Imported by  | `animation_api.rs` wraps `Animation` as `LuaAnimation` UserData.     |
| `graphics` | Related      | Not a code dependency. Scripts use animation quads with `lurek.gfx.draw()` / `drawq()`. |

**Similar modules**: `animation` handles frame-based sprite animation (sequences of source-rect quads). For skeletal/bone-hierarchy animation — where joints are driven by transforms rather than discrete sprite frames — use `spine` instead. `animation` is also distinct from `particle` (emitter-based particle effects) and from `graphics::sprite` (sprite draw state without timeline or clip logic).

## Notes

- **No GPU dependency**: The module produces `Rect` source quads only. It never touches textures, draw commands, or the GPU pipeline. This means it runs fully in headless/test environments.
- **Per-frame duration override**: If `AnimFrame::duration > 0.0`, it takes priority over the clip's FPS for that frame. This allows variable-speed frames within a single clip (e.g., holding a keyframe longer).
- **Speed is clamped**: `set_speed()` clamps the value to `? 0.0`. Negative speed (reverse playback) is not supported.
- **Clip FPS floor**: `add_clip()` enforces `fps > 0.0`, defaulting to `1.0` if a non-positive value is passed.
- **Event draining**: `drain_events()` / `pollEvents()` clears the event queue. Events not read before the next `update()` are lost, since `update()` calls `self.pending_events.clear()` first.
- **No reverse playback**: Clips always play forward. To simulate reverse, supply frame indices in reverse order.
- **Frame indices are not validated**: `add_clip()` does not check that frame indices are within the frame pool bounds. Out-of-range indices will cause `current_quad()` to return `None`.
- **Backward-compatibility alias**: `AnimationFrame` is a type alias for `AnimFrame`, kept for code that previously imported `AnimationFrame` from `crate::graphics`.
- **Breaking change surface**: Renaming UserData methods (e.g., `addClip`, `getQuad`, `pollEvents`) will break Lua game scripts. The Rust API (`add_clip`, `current_quad`, `drain_events`) uses snake_case while the Lua API uses camelCase.
