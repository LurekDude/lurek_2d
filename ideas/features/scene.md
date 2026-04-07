# scene — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/scene.md`
**Files**: Scene stack, transitions, registry

## Purpose

Scene management: push-down automaton for game states (menu, gameplay, pause). Scene transitions, scene registry, depth sorting.

## Current Feature Summary

- `SceneStack`: push/pop/switch scene states
- Scene lifecycle callbacks: enter, exit, update, draw, pause, resume
- Named scene registry: register scenes by name for string-based switching
- Scene transitions: fade, slide, custom
- `DepthSorter`: z-order sorting for draw calls within a scene
- Scene data passing: send data between scenes on transition
- Stack introspection: current scene, stack depth, scene list

## Feature Gaps

1. **No parallel scene updates**: Only the top scene receives update/draw. Can't have a background scene (world simulation) continue updating while pause overlay is shown.
2. **No scene transition library**: Transitions exist as a concept but there's no built-in library of common transitions (wipe, iris, pixelate, crossfade). Must implement manually.
3. **No scene serialization**: Can't save/restore scene state for save games. Must manually handle persistence.
4. **No scene preloading**: No async loading of scene resources before transition. Scene enters with potential loading hitch.
5. **No sub-scenes / scene composition**: Can't embed one scene within another (e.g., minimap scene inside gameplay scene).

## Structural Issues

- **DepthSorter misplaced**: Depth sorting is a rendering concern (graphics module), not a scene concern. It should live in graphics or camera.
- **Transition overlap with fx**: Scene transitions (fade, slide) are visual effects. The `fx` module handles screen fades. Consider unifying transition effects under `fx`.
- **Clean responsibilities**: Aside from DepthSorter, the scene module's scope is well-defined.

## Suggestions

1. **Move DepthSorter to graphics**: It's a rendering primitive, not a scene management concept.
2. **Add parallel scene mode**: `sceneStack:pushOverlay(scene)` — pushed scene receives update, underlying scenes also update but don't draw (or draw underneath).
3. **Add built-in transition library**: `luna.scene.transitions.fade`, `.slide`, `.wipe`, `.iris` — pre-built transition effects. Most 2D engines provide these.
4. **Add scene preloading**: `sceneStack:preload(sceneName, fn)` — load resources before entering. Critical for smooth transitions.
5. **Unify transitions with fx**: Use `fx` module's fade/effects for scene transitions rather than duplicating visual effects.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Gideros |
|---|---|---|---|---|
| Scene stack | ✅ | ❌ (manual) | ❌ (composer) | ✅ (SceneManager) |
| Transitions | ✅ (basic) | ❌ | ✅ (rich library) | ✅ |
| Scene registry | ✅ | N/A | ✅ | ✅ |
| Parallel scenes | ❌ | N/A | ❌ | ❌ |
| Preloading | ❌ | N/A | ✅ | ❌ |

## Priority

**MEDIUM** — DepthSorter placement is a structural fix. Built-in transitions and overlay scenes are high-value features.
