# camera — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/camera.md`
**Files**: Camera2D, follow, deadzone, shake, viewport

## Purpose

2D camera system: position, zoom, rotation, target following with deadzone, screen shake, and viewport coordinate mapping.

## Current Feature Summary

- `Camera2D`: position, zoom, rotation
- Target following with smoothing (lerp factor)
- Deadzone: rectangular region where camera doesn't track
- Screen shake: duration, intensity, decay
- Viewport: world↔screen coordinate conversion
- Camera bounds: constrain camera to world rectangle
- Push/pop camera state for HUD/UI rendering
- Zoom limits (min/max)
- Multiple named cameras (but only one active)

## Feature Gaps

1. **No multi-camera rendering**: Can't render two cameras side-by-side (split screen). Must switch active camera per frame.
2. **No camera paths**: Can't follow a predefined path (Bezier, waypoints) for cutscenes.
3. **No camera effects beyond shake**: No zoom pulse, pan drift, sway, breathing, or cinematic effects.
4. **No camera groups/layers**: Can't assign camera to specific render layers.
5. **No smooth zoom**: Zoom changes are instant. `zoomTo(level, duration, easing)` would be useful.
6. **No parallax integration**: No built-in parallax scrolling support (different scroll speeds for background/foreground).
7. **No camera constraints beyond bounds**: No "soft bounds" (elastic pullback) or axis locking.

## Structural Issues

- **Viewport overlap with window module**: Window manages viewport scaling modes (letterbox, pixel-perfect). Camera manages world-to-screen mapping. The boundary is correct but should be documented more clearly.
- **Shake duplication**: Camera shake is implemented here, but `fx` module also has screen shake via Overlay. Two independent shake systems is confusing.

## Suggestions

1. **Consolidate shake**: Remove camera shake OR overlay shake. Keep one canonical `shake(intensity, duration, decay)` in one place. Camera shake is more natural (it's the camera that shakes).
2. **Add camera paths**: `camera:followPath(points, duration, easing)` — for cutscenes and scripted sequences. Pair with Bezier curves from math module.
3. **Add smooth zoom**: `camera:zoomTo(level, duration, easing)` — animated zoom transitions.
4. **Add parallax helper**: `camera:setParallaxFactor(layer, factor)` — multiply camera offset by factor for that layer. Extremely common in 2D sidescrollers.
5. **Add split screen**: `camera:setViewport(x, y, w, h)` — render this camera to a sub-rectangle of the screen. Enables split-screen multiplayer.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Gideros |
|---|---|---|---|---|
| Camera follow | ✅ | ❌ (manual) | ❌ (manual) | ❌ |
| Deadzone | ✅ | ❌ | ❌ | ❌ |
| Shake | ✅ | ❌ | ❌ | ❌ |
| Bounds | ✅ | ❌ | ❌ | ❌ |
| Camera paths | ❌ | ❌ | ❌ | ❌ |
| Parallax | ❌ | ❌ | ✅ (groups) | ✅ |
| Split screen | ❌ | ❌ | ❌ | ❌ |

## Priority

**MEDIUM** — Camera is already better than most 2D engines. Shake consolidation (with fx module) is a structural fix. Camera paths and parallax are valuable additions.
