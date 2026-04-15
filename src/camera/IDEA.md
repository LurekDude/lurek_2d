# IDEA.md — `camera` module

> Migrated from `ideas/features/camera.md`.
> Status checked against `src/camera/` and `src/lua_api/camera_api.rs`.

---

## Features

### ✅ DONE — Camera Viewport Sub-Rectangle (Split Screen foundation)
**Source**: features/camera.md — Feature Gaps #1 / Suggestions #4

`setViewport(x, y, w, h)` method found in `camera_api.rs` (line ~78). This enables rendering
a camera to a sub-region of the screen — a building block for split-screen.

Full split-screen (simultaneously rendering two cameras to different viewports per frame) still
requires multi-pass render support. Verify integration with the render pipeline.

---

### ✅ DONE — Camera Paths (Cutscene Sequences)
**Source**: features/camera.md — Feature Gaps #2 / Suggestions #2

`cam:followPath(points, duration)` implemented in `camera_api.rs`. `points` is a flat array of
`{x, y}` pairs. Call `cam:updatePath(dt)` each frame; it returns `true` while running.
`cam:stopPath()` cancels. `cam:pathProgress()` returns `[0,1]` progress.
```lua
cam:followPath({{10,20},{50,80},{100,30}}, 3.0)
function lurek.process(dt)
  if cam:updatePath(dt) then ... end
end
```

---

### ✅ DONE — Smooth Zoom Transition
**Source**: features/camera.md — Feature Gaps #5 / Suggestions #3

`cam:zoomTo(target_zoom, duration)` implemented in `camera_api.rs`. Linear tween.
Call `cam:updateZoom(dt)` each frame; `cam:stopZoom()` cancels.
```lua
cam:zoomTo(2.0, 1.5)   -- smooth zoom to 2× over 1.5 seconds
```

---

### ✅ DONE — Parallax Layer Factor
**Source**: features/camera.md — Feature Gaps #6 / Suggestions #4

`cam:setParallaxFactor(layer, factor)` / `cam:getParallaxFactor(layer)` /
`cam:clearParallaxFactors()` implemented in `camera_api.rs`. Per-layer multiplier
stored in the `LuaCamera2D` wrapper.
```lua
cam:setParallaxFactor("bg", 0.3)    -- background scrolls at 30% of camera speed
cam:setParallaxFactor("clouds", 0.1)
```

---

### ✅ DONE — Extended Camera Effects (Zoom Pulse, Sway, Breathing)
**Source**: features/camera.md — Feature Gaps #3

Three cinematic effects added to `Camera2D` in `src/camera/effects.rs`:

- **Zoom Pulse** (`cam:zoomPulse(amplitude, duration)`) — brief sine-envelope zoom-in that
  decays back to the base zoom. Great for hit impacts.
- **Sway** (`cam:startSway(amp_x, amp_y, frequency, decay?)` / `cam:stopSway()`) —
  sinusoidal x/y offset oscillation with optional amplitude decay. Useful for boat rocking
  or underwater environments.
- **Breathing** (`cam:startBreathing(amplitude?, rate?)` / `cam:stopBreathing()`) — subtle
  periodic zoom oscillation for a "living camera" feel.

Query helpers: `cam:getEffectiveZoom()` returns base zoom + pulse + breathing deltas;
`cam:getEffectOffset()` returns the current sway `dx, dy`. State predicates:
`cam:isSway()`, `cam:isBreathing()`.

---

### 🤔 CONSIDER — Consolidate Screen Shake
**Source**: features/camera.md — Structural Issues

Screen shake is implemented in both the `camera` module and the `effect`/`fx` overlay system.
Two independent shake systems is confusing. Pick one canonical location — camera shake is
the more natural home — and deprecate the other.
