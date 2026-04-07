# fx — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/fx.md`
**Files**: PostFx effects + Screen overlays (combined module)

## Purpose

Two visual effects families in one module:
1. **Post-processing (PostFx)**: screen-space shader effects applied after rendering (blur, bloom, CRT, vignette, etc.)
2. **Screen overlays**: world-simulation atmospheric effects (weather, ambient lighting, clouds, screen shake, fade, etc.)

## Current Feature Summary

**PostFx Stack:**
- 16 built-in effect types: Blur, Bloom, CRT, Chromatic Aberration, Pixelate, Vignette, Sepia, Invert, Grayscale, Threshold, ColorGrade, Glitch, GodRays, Neon, MotionBlur, DepthOfField
- Custom shader effects via WGSL
- Effect pipeline: ordered stack with per-effect enable/disable
- Per-effect parameter maps (key-value float params)
- Ping-pong canvas for multi-pass processing

**Screen Overlays:**
- 12 subsystems: Ambient (time-of-day), Weather (8 types: rain, snow, fog, storm, sandstorm, ash, fireflies, petals), Clouds, Fog, Heat Haze, Vignette, Film Grain, Lightning, Flash, Shake, Fade, Custom
- Weather types with individual configs
- Screen flash with color/duration
- Screen shake with intensity/decay
- Fade in/out with color
- All CPU-only data models

## Feature Gaps

1. **No palette swap shader**: Common retro effect — remap all colors through a palette LUT at the shader level. Different from image module's PaletteLUT (CPU).
2. **No water/reflection effect**: No screen-space water distortion or reflection (common for top-down water).
3. **No transition effects as PostFx**: Scene transitions (wipe, iris, dissolve) should be expressible as PostFx effects.
4. **No effect presets**: No built-in preset combinations (e.g., "retro_tv" = CRT + scanlines + bloom + chromatic aberration).
5. **No PostFx blend modes**: Effects are opaque passes. No "multiply" or "screen" blending between effect and source.
6. **No runtime shader compilation feedback**: If custom WGSL shader has errors, feedback mechanism is unclear.
7. **No day/night cycle integration with light module**: Ambient TOD overlay should connect to light module's LightWorld, but they're independent.

## Structural Issues

- **Two families in one module is OK**: PostFx and Overlays are both "visual effects applied to the rendered frame." Combining them makes sense. But the Lua API naming could be clearer — `luna.fx.postfx.*` vs `luna.fx.overlay.*`.
- **Shake duplication**: `fx` module has screen shake via Overlay. `camera` module also has screen shake. Two independent shake systems is confusing. **Resolve: one canonical shake.**
- **No separate overlay.md or postfx.md specs**: Both are in `fx.md`. This is correct — they're one module. But the system prompt's tier list mentions "overlay" and "postfx" as separate modules.
- **CPU-only data**: Overlay subsystems are pure data. Rendering is done elsewhere. This is architecturally correct.

## Suggestions

1. **Consolidate shake**: Remove camera shake. Keep shake in `fx` module only (or vice versa). One canonical `luna.fx.shake(intensity, duration)`.
2. **Add effect presets**: `luna.fx.applyPreset("retro")` — pre-configured effect stacks. Reduces boilerplate for common styles.
3. **Add palette swap**: `luna.fx.postfx.addPaletteSwap(paletteImage)` — common in retro and narrative games (time of day, flashback).
4. **Bridge fx ↔ light**: Connect ambient time-of-day overlay with light module's LightWorld ambient color. Currently independent.
5. **Add transition effects**: `luna.fx.transition.wipe(duration, angle)`, `luna.fx.transition.iris(x, y, duration)` — PostFx-based scene transitions.
6. **Add shader error feedback**: `luna.fx.postfx.addCustom(wgsl, onError)` — callback for shader compilation errors.
7. **Update tier list**: System prompt should list `fx` not "overlay" and "postfx" as separate modules.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Post-processing | ✅ (16 effects) | ✅ (shader-based) | ❌ | ✅ |
| Weather effects | ✅ (8 types) | ❌ | ❌ | ❌ |
| Screen shake | ✅ (2 places!) | ❌ | ❌ | ❌ |
| CRT / retro | ✅ | ❌ (manual) | ❌ | ✅ |
| Custom shaders | ✅ (WGSL) | ✅ (GLSL) | ❌ | ✅ (WGSL) |
| Effect presets | ❌ | ❌ | ❌ | ❌ |
| Day/night ambient | ✅ | ❌ | ❌ | ❌ |

Luna2D's fx module is very rich. The 16 built-in PostFx effects + 12 overlay subsystems is unmatched in 2D Lua engines.

## Priority

**MEDIUM** — Shake consolidation is a structural fix. Effect presets and palette swap are high-value features. Day/night + light integration would create a cohesive atmospheric system.
