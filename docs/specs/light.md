# `light` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Platform Services |
| **Status** | Implemented |
| **Lua API** | `lurek.light` |
| **Source** | `src/light/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Platform Services` |

---

## Summary

The light module owns the CPU-side 2D lighting model. It defines individual lights, occluders, attenuation, falloff, flicker, blend behavior, shadow filtering, and the LightWorld container that groups active lighting state into keyed pools for the renderer to consume later.

This module keeps lighting data and rules separate from shader execution. It describes what lights and occluders exist and how they should behave, but it does not perform shadow rendering, final compositing, or scene ownership. That boundary keeps the lighting state testable and lets the renderer decide how to turn these descriptions into an actual lighting pass.

**Scope boundary**: This module currently depends on `image`, `math`, `runtime`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.light.* (Lua API — src/lua_api/light_api.rs)
    |
    v
src/light/mod.rs
    |- attenuation.rs - attenuation
    |- blend_mode.rs - blend_mode
    |- falloff.rs - falloff
    |- flicker.rs - flicker
    |- light2d.rs - light2d
    |- light_type.rs - light_type
    |- light_world.rs - light_world
    |- occluder.rs - occluder
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `attenuation.rs` | Defines coefficient-based attenuation for custom distance decay. |
| `blend_mode.rs` | Defines how light mixes with the scene. |
| `falloff.rs` | Defines the high-level radial falloff enum. |
| `flicker.rs` | Defines flicker configuration and phase advancement helpers. |
| `light2d.rs` | Defines Light2D, the main per-light data record with position, radius, color, intensity, masks, shadows, geometry, attenuation, flicker, and grouping. |
| `light_type.rs` | Defines the geometric light-type enum for point, directional, and spot lights. |
| `light_world.rs` | Defines LightWorld, the keyed container for active lights, occluders, ambient color, limits, and group operations. |
| `mod.rs` | Declares the lighting submodules and re-exports the public light types. |
| `occluder.rs` | Defines Occluder, a polygon shadow caster with transform, opacity, mask, and enabled state. |
| `shadow.rs` | Defines the shadow edge-filter enum. |

---

## Submodules

### `light::attenuation`

Defines coefficient-based attenuation for custom distance decay.

- **`Attenuation`** (struct): Custom attenuation coefficients controlling light intensity decay.

### `light::blend_mode`

Defines how light mixes with the scene.

- **`LightBlendMode`** (enum): How light color mixes with the scene.

### `light::falloff`

Defines the high-level radial falloff enum.

- **`FalloffMode`** (enum): How light intensity decays from center to edge.

### `light::flicker`

Defines flicker configuration and phase advancement helpers.

- **`FlickerConfig`** (struct): Built-in flicker effect that modulates light intensity over time.

### `light::light2d`

Defines Light2D, the main per-light data record with position, radius, color, intensity, masks, shadows, geometry, attenuation, flicker, and grouping.

- **`Light2D`** (struct): 2D point light with position, radius, color, intensity, and shadow settings.

### `light::light_type`

Defines the geometric light-type enum for point, directional, and spot lights.

- **`LightType`** (enum): The geometric shape of a light source.

### `light::light_world`

Defines LightWorld, the keyed container for active lights, occluders, ambient color, limits, and group operations.

- **`LightWorld`** (struct): Resource pool and state for the 2D lighting system.

### `light::occluder`

Defines Occluder, a polygon shadow caster with transform, opacity, mask, and enabled state.

- **`Occluder`** (struct): Polygon shadow caster that blocks light.

### `light::shadow`

Defines the shadow edge-filter enum.

- **`ShadowFilter`** (enum): Edge quality for shadow boundaries.

---

## Key Types

### Public Types

#### `Light2D`

Main per-light data container used by Lua and the renderer-facing lighting world.

#### `LightWorld`

Owner of the light and occluder pools, ambient settings, limits, and group operations.

#### `Occluder`

Polygon shadow caster with vertices, transform, opacity, mask, and enabled state.

#### `LightType`

Enum distinguishing point, directional, and spot light behavior.

#### `LightBlendMode`

Enum controlling additive, subtractive, or mixed scene contribution.

#### `FalloffMode`

Enum describing how intensity decays from center to edge.

#### `Attenuation`

Coefficient-based custom falloff model.

#### `FlickerConfig`

Time-varying intensity modulation for torches, unstable lights, and similar effects.

#### `ShadowFilter`

Enum selecting the shadow edge filtering quality.

---

## Lua API

Exposed under `lurek.light.*` by `src/lua_api/light_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.light.newLight` | Creates a new light at (x, y) with the given radius and optional settings. |
| `lurek.light.newOccluder` | Creates a new shadow occluder from a vertex table and optional settings. |
| `lurek.light.setAmbient` | Sets the global ambient light color. |
| `lurek.light.getAmbient` | Returns the global ambient light color as (r, g, b, a). |
| `lurek.light.setEnabled` | Sets whether the lighting system is active. |
| `lurek.light.isEnabled` | Returns whether the lighting system is active. |
| `lurek.light.getLightCount` | Returns the number of lights in the world. |
| `lurek.light.getOccluderCount` | Returns the number of occluders in the world. |
| `lurek.light.getMaxLights` | Returns the maximum number of lights processed per frame. |
| `lurek.light.setMaxLights` | Sets the maximum number of lights processed per frame (clamped 1–256). |
| `lurek.light.clear` | Removes all lights and occluders, resets ambient to default. |
| `lurek.light.setGroupEnabled` | Sets the enabled state for all lights in the given group. |
| `lurek.light.setGroupIntensity` | Sets the intensity for all lights in the given group. |
| `lurek.light.setGroupColor` | Sets the color for all lights in the given group. |
| `lurek.light.getGroupCount` | Returns the number of lights in the given group. |
| `lurek.light.advanceFlickers` | Advances flicker phase for all lights with flicker enabled. |

### `Light` Methods

| Method | Description |
|--------|-------------|
| `light:setPosition(...)` | Sets the light's world-space position. |
| `light:getPosition(...)` | Returns the light's world-space position. |
| `light:setRadius(...)` | Sets the light's influence radius. |
| `light:getRadius(...)` | Returns the light's influence radius. |
| `light:setColor(...)` | Sets the light's tint color. |
| `light:getColor(...)` | Returns the light's tint color as (r, g, b, a). |
| `light:setIntensity(...)` | Sets the brightness multiplier. |
| `light:getIntensity(...)` | Returns the brightness multiplier. |
| `light:setEnergy(...)` | Sets the energy scaling factor. |
| `light:getEnergy(...)` | Returns the energy scaling factor. |
| `light:setBlendMode(...)` | Sets the blend mode ('add', 'sub', or 'mix'). |
| `light:getBlendMode(...)` | Returns the blend mode as a string. |
| `light:setFalloff(...)` | Sets the falloff mode ('linear', 'smooth', or 'constant'). |
| `light:getFalloff(...)` | Returns the falloff mode as a string. |
| `light:setShadowEnabled(...)` | Sets whether this light casts shadows. |
| `light:isShadowEnabled(...)` | Returns whether this light casts shadows. |
| `light:getShadowColor(...)` | Returns the shadow region color as (r, g, b, a). |
| `light:setShadowFilter(...)` | Sets the shadow edge filter ('none', 'pcf5', or 'pcf13'). |
| `light:getShadowFilter(...)` | Returns the shadow edge filter as a string. |
| `light:setShadowSmooth(...)` | Sets the shadow edge smoothing factor. |
| `light:getShadowSmooth(...)` | Returns the shadow edge smoothing factor. |
| `light:setLightMask(...)` | Sets the light interaction bitmask. |
| `light:getLightMask(...)` | Returns the light interaction bitmask. |
| `light:setShadowMask(...)` | Sets the shadow casting bitmask. |
| `light:getShadowMask(...)` | Returns the shadow casting bitmask. |
| `light:setEnabled(...)` | Sets whether this light is active. |
| `light:isEnabled(...)` | Returns whether this light is active. |
| `light:setLightType(...)` | Sets the geometric light type ('point', 'directional', or 'spot'). |
| `light:getLightType(...)` | Returns the geometric light type as a string. |
| `light:setDirection(...)` | Sets the direction angle in radians. |
| `light:getDirection(...)` | Returns the direction angle in radians. |
| `light:setInnerAngle(...)` | Sets the inner cone angle in radians for spot lights. |
| `light:getInnerAngle(...)` | Returns the inner cone angle in radians. |
| `light:setOuterAngle(...)` | Sets the outer cone angle in radians for spot lights. |
| `light:getOuterAngle(...)` | Returns the outer cone angle in radians. |
| `light:setAttenuation(...)` | Sets the custom attenuation coefficients (constant, linear, quadratic). |
| `light:getAttenuation(...)` | Returns the custom attenuation coefficients as (constant, linear, quadratic). |
| `light:setFlicker(...)` | Sets the flicker effect speed and strength (enables flicker). |
| `light:getFlicker(...)` | Returns the flicker effect speed and strength. |
| `light:setFlickerEnabled(...)` | Sets whether the flicker effect is active. |
| `light:isFlickerEnabled(...)` | Returns whether the flicker effect is active. |
| `light:setGroupId(...)` | Sets the group identifier for batch operations. |
| `light:getGroupId(...)` | Returns the group identifier. |
| `light:setVolumetric(...)` | Sets whether this light hints at volumetric scattering. |
| `light:isVolumetric(...)` | Returns whether this light hints at volumetric scattering. |
| `light:remove(...)` | Removes this light from the world. |
| `light:isValid(...)` | Returns whether this light handle is still valid. |

### `Occluder` Methods

| Method | Description |
|--------|-------------|
| `occluder:setVertices(...)` | Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}. |
| `occluder:getVertices(...)` | Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}. |
| `occluder:setPosition(...)` | Sets the translation offset applied to all vertices. |
| `occluder:getPosition(...)` | Returns the translation offset as (x, y). |
| `occluder:setOpacity(...)` | Sets the shadow opacity (0.0–1.0). |
| `occluder:getOpacity(...)` | Returns the shadow opacity. |
| `occluder:setLightMask(...)` | Sets the light interaction bitmask. |
| `occluder:getLightMask(...)` | Returns the light interaction bitmask. |
| `occluder:setEnabled(...)` | Sets whether this occluder is active. |
| `occluder:isEnabled(...)` | Returns whether this occluder is active. |
| `occluder:remove(...)` | Removes this occluder from the world. |
| `occluder:isValid(...)` | Returns whether this occluder handle is still valid. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.light.
if lurek.light then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 5 |
| `enum` | 4 |
| `fn` (Lua API) | 75 |
| **Total** | **84** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Platform Services to Foundations. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Platform Services to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/light/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
