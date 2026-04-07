# light — Feature Analysis

**Tier**: 2 (Extension) — note: `mod.rs` claims Tier 1 but spec and architecture say Tier 2
**Spec**: `specs/light.md`
**Files**: 2D lighting system

## Purpose

2D lighting engine: point/directional/spot lights, shadow casting via occluders, ambient lighting, flicker effects. CPU-only data model — rendering delegated to graphics module.

## Current Feature Summary

- `LightWorld`: container for lights + occluders, manages SlotMap pools
- `Light2D`: 23 fields — position, color, intensity, radius, falloff, angle, cone
- 3 light types: Point, Directional, Spot
- `Occluder`: line segments that cast shadows
- Shadow casting via edge ray projection
- Light attenuation curves (linear, quadratic, custom)
- Flicker effects: configurable noise-based intensity variation
- Bitmask filtering: lights affect only matching layers
- Ambient color: global scene base lighting
- Max 256 lights per world
- Light color blending modes

## Feature Gaps

1. **No global illumination / radiosity**: No light bouncing. Direct illumination only.
2. **No light cookies/patterns**: Can't project patterns through lights (gobo/cookie textures). Common for streetlamps, stained glass.
3. **No dynamic shadows from moving occluders**: Occluders must be updated manually when geometry changes.
4. **No animated light paths**: Can't make lights follow paths (e.g., patrolling searchlight).
5. **No light probes**: No pre-computed lighting for static scenes.
6. **No volumetric light**: No light shaft / god ray effects (though PostFx has GodRays — potential integration).
7. **No shadow softness**: Hard shadows only. No penumbra/soft shadow falloff.
8. **No integration with fx ambient overlay**: FX module's ambient time-of-day changes ambient color, light module has its own ambient. Should be unified.
9. **No light groups**: Can't batch-control groups of lights (e.g., "all indoor lights").

## Structural Issues

- **Tier mismatch**: Source code says Tier 1 but architecture docs and spec say Tier 2. Fix the source code comment.
- **CPU-only data model**: Light data is computed on CPU, rendering is in graphics. This is architecturally correct but may limit performance for many lights.
- **No integration with fx**: Light ambient and fx ambient overlay are independent. Should be connected.
- **256 light limit**: Hard ceiling. Fine for most 2D games but could be limiting for large scenes.

## Suggestions

1. **Fix tier label**: Update `mod.rs` to correctly document Tier 2.
2. **Bridge with fx ambient**: Connect `LightWorld.ambient_color` with fx overlay's ambient time-of-day. One source of truth for ambient lighting.
3. **Add soft shadows**: `light:setShadowSoftness(factor)` — penumbra via blur or multi-sample.
4. **Add light cookies**: `light:setCookie(imageData)` — project pattern through light for atmospheric effects.
5. **Add light groups**: `lightWorld:createGroup("indoor", {light1, light2})` / `lightWorld:setGroupIntensity("indoor", 0.5)`.
6. **Add light transition**: `light:transitionTo({color=..., intensity=...}, duration)` — animated light changes for day/night, alarm triggers.
7. **Integrate with PostFx GodRays**: Connect light positions with the PostFx god ray effect for directional volumetric light.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| 2D lights | ✅ | ❌ (libs) | ❌ | ✅ |
| Shadow casting | ✅ | ❌ | ❌ | ✅ |
| Light types | 3 | N/A | N/A | 3 |
| Occluders | ✅ | ❌ | ❌ | ✅ |
| Flicker | ✅ | N/A | N/A | ❌ |
| Bitmask filter | ✅ | N/A | N/A | ✅ |
| Soft shadows | ❌ | N/A | N/A | ✅ |
| Light cookies | ❌ | N/A | N/A | ❌ |

Luna2D has a strong built-in lighting system — uncommon for 2D Lua engines.

## Priority

**MEDIUM** — Tier label fix is immediate. FX ambient integration creates a cohesive visual system. Soft shadows and light groups improve quality and workflow.
