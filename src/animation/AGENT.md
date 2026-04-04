# `animation` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Core Engine Subsystems |
| **Lua API** | `luna.graphics.newAnimation()` (via `src/lua_api/sprite_api.rs`) |
| **Source** | `src/animation/mod.rs` |
| **Rust Tests** | `tests/unit/animation_tests.rs` — 14 tests |
| **Lua Tests** | None (animation is tested indirectly via `test_graphics.lua`) |
| **Status** | Implemented — Full |

## Summary

The `animation` module provides a sprite animation runtime for Luna2D: named playback
clips, a shared frame pool, per-frame duration overrides, variable speed, and an event
queue for script notifications.

An [`Animation`] stores a pool of [`AnimFrame`] entries (each holding a source rectangle
into a sprite-sheet texture and an optional per-frame duration).  Named [`AnimClip`]s
reference frames by index into the pool and carry FPS and looping settings.  Calling
[`Animation::play`] selects the active clip; [`Animation::update`] advances the timer
and pushes [`AnimEvent`] variants onto an internal queue; [`Animation::drain_events`]
lets the caller react to `Finished`, `FrameChanged`, and `Looped` transitions.

## Architecture

```
animation/
  │
  └── Animation ── main controller
        │
        ├── frames: Vec<AnimFrame>   ── source quads + optional duration
        ├── clips:  HashMap<String, AnimClip>  ── named playback definitions
        └── Playback state
              ├── current_clip, current_frame_pos, timer
              ├── playing, speed
              └── drain_events() → Vec<AnimEvent>
```

## Architecture Note

`animation` was extracted from `src/graphics/animation.rs` during the graphics-module-split
session.  It is a Tier 1 module that imports only from `crate::math` (specifically `Rect`).

The backward-compatibility alias `AnimationFrame = AnimFrame` is preserved so that callers
that previously imported `AnimationFrame` from `crate::graphics` continue to compile.

The Lua binding in `src/lua_api/sprite_api.rs` wraps `Animation` in a `LuaAnimation`
userdata and registers it on the `luna.graphics` table (e.g. `luna.graphics.newAnimation()`).
There is no separate `luna.animation` module — all animation functions are accessed through
`luna.graphics` or through an animation object returned by `newAnimation()`.

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Entire animation module — `AnimFrame`, `AnimClip`, `AnimEvent`, `Animation` |

## Key Types

| Type | Kind | Description |
|------|------|-------------|
| `Animation` | struct | Sprite animation controller with named clips, speed, and event queue |
| `AnimFrame` | struct | Single frame: source `Rect` quad and optional duration override |
| `AnimClip` | struct | Named clip: frame index list, FPS, and looping flag |
| `AnimEvent` | enum | Playback notification: `Finished`, `FrameChanged { frame_index }`, `Looped` |
| `AnimationFrame` | type alias | Backward-compatible alias for `AnimFrame` |

## Lua API Summary

Animation is exposed as an object returned by `luna.graphics.newAnimation()`.

| Function | Description |
|----------|-------------|
| `luna.graphics.newAnimation()` | Creates a new empty `Animation` object |
| `anim:addFrame(quad, duration?)` | Adds a frame (source rect) to the frame pool |
| `anim:addClip(name, frames, fps, loop)` | Registers a named clip |
| `anim:play(name)` | Starts playback of a named clip |
| `anim:stop()` | Stops playback |
| `anim:update(dt)` | Advances the animation timer |
| `anim:getQuad()` | Returns the current source quad (Rect) |
| `anim:setSpeed(factor)` | Scales playback speed |
| `anim:getEvents()` | Returns and clears pending events |
