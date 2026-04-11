# `animation` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.animation` |
| **Source** | `src/animation/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The animation module owns frame-based sprite playback. It stores reusable frame definitions, named clips, playback state, speed control, and emitted animation events while staying independent from scene ownership, textures, and gameplay rules.

This module exists to answer one narrow question well: given frames and clips, which frame should be active now and what events should fire as playback advances. Rendering integration lives in helper methods that turn the current frame into render-command data, but the module does not own GPU work, sprite assets, or non-frame-based animation systems such as tweening or skeletal animation.

**Scope boundary**: This module currently depends on `math`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.animation.* (Lua API — src/lua_api/animation_api.rs)
    |
    v
src/animation/mod.rs
    |- clip.rs - clip
    |- controller.rs - controller
    |- event.rs - event
    |- frame.rs - frame
    |- render.rs - render
```

---

## Source Files

| File | Purpose |
|------|---------|
| `clip.rs` | Defines AnimClip, the named sequence of frame indices with clip FPS and looping behavior. |
| `controller.rs` | Defines Animation, the main playback controller for frames, clips, speed, current state, and pending events. |
| `event.rs` | Defines AnimEvent, the event enum emitted for frame changes, loops, and completion. |
| `frame.rs` | Defines AnimFrame plus the AnimationFrame compatibility alias. |
| `mod.rs` | Declares the animation submodules and re-exports the public frame, clip, controller, event, and render parameter types. |
| `render.rs` | Converts the current animation frame into renderer-facing DrawQuad command data. |

---

## Submodules

### `animation::clip`

Defines AnimClip, the named sequence of frame indices with clip FPS and looping behavior.

- **`AnimClip`** (struct): A named animation clip that references frames by index into the parent

### `animation::controller`

Defines Animation, the main playback controller for frames, clips, speed, current state, and pending events.

- **`Animation`** (struct): Sprite animation with named clips, speed control, and playback events.

### `animation::event`

Defines AnimEvent, the event enum emitted for frame changes, loops, and completion.

- **`AnimEvent`** (enum): Events emitted by [`Animation::update`](crate::animation::Animation::update).

### `animation::frame`

Defines AnimFrame plus the AnimationFrame compatibility alias.

- **`AnimFrame`** (struct): A single animation frame with a source rectangle and optional duration.
- **`AnimationFrame`** (type): Backward-compatible alias for [`AnimFrame`].

### `animation::render`

Converts the current animation frame into renderer-facing DrawQuad command data.

- **`AnimRenderParams`** (struct): Parameters for rendering an animated sprite.

---

## Key Types

### Public Types

#### `Animation`

Main playback controller that owns frames, clips, speed, timers, and pending events.

#### `AnimClip`

Named ordered frame sequence with clip-local FPS and looping configuration.

#### `AnimFrame`

One source rectangle plus an optional per-frame duration override.

#### `AnimEvent`

Playback event enum used to report frame changes, loops, and finished clips.

#### `AnimRenderParams`

Caller-supplied texture and transform bundle used when generating render commands.

---

## Lua API

Exposed under `lurek.animation.*` by `src/lua_api/animation_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.animation.new` | Creates a new, empty Animation controller. |

### `Animation` Methods

| Method | Description |
|--------|-------------|
| `animation:addFrame(...)` | Adds a single frame to the frame pool by source rectangle. |
| `animation:play(...)` | Starts playback of the named clip. |
| `animation:stop(...)` | Stops playback and resets to frame 0. |
| `animation:pause(...)` | Pauses playback at the current frame. |
| `animation:resume(...)` | Resumes playback from the current frame. |
| `animation:update(...)` | Advances the animation by dt seconds. |
| `animation:getQuad(...)` | Returns the source quad (x, y, w, h) for the current frame, or nil. |
| `animation:pollEvents(...)` | Drains and returns all pending animation events as a table. |
| `animation:isPlaying(...)` | Returns true if a clip is currently playing. |
| `animation:isLooping(...)` | Returns true if the current clip is set to loop. |
| `animation:getClip(...)` | Returns the name of the currently playing clip, or nil. |
| `animation:getSpeed(...)` | Returns the playback speed multiplier. |
| `animation:setSpeed(...)` | Sets the playback speed multiplier. |
| `animation:getFrameCount(...)` | Returns the total number of frames in the frame pool. |
| `animation:getClipCount(...)` | Returns the number of registered clips. |
| `animation:getCurrentFrame(...)` | Returns the current position within the active clip (0-based). |
| `animation:setFrame(...)` | Sets the playback position within the current clip. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.animation.
if lurek.animation then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 1 |
| `fn` (Lua API) | 18 |
| **Total** | **23** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Feature Systems to Foundations. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/animation/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
