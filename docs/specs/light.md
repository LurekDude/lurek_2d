# `light` ÔÇö Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 ÔÇö Engine Extension                            |
| **Status**     | Implemented ÔÇö Full                                   |
| **Lua API**    | `lurek.light`                                         |
| **Source**      | `src/render/light/`                                  |
| **Rust Tests** | `tests/rust/unit/light_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_light.lua`                      |
| **Architecture** | ÔÇö                                                  |

## Summary

The `light` module provides a CPU-side 2D dynamic lighting data model for Lurek2D. It stores all state needed to describe point, directional, and spot light sources in 2D space ÔÇö position, radius, colour, intensity, falloff curves, shadow settings, flicker effects, attenuation coefficients, bitmask-based filtering, and group management. It also provides `Occluder` polygons that define shadow-casting geometry and `LightWorld`, a SlotMap-based resource pool that aggregates all lights and occluders for a scene.

The module is purely a data container layer. It holds no GPU resources, performs no rendering, and issues no draw commands. The renderer reads `LightWorld` state each frame and produces the actual lighting pass via `RenderCommand` variants in the graphics pipeline. This separation means the light module can be tested headlessly without a GPU context.

Key design decisions: (1) `Light2D` is a flat struct with 23 public fields covering all light parameters ÔÇö no inheritance or trait hierarchy. (2) `LightWorld` uses `SlotMap<LightKey, Light2D>` and `SlotMap<OccluderKey, Occluder>` for O(1) insert/remove/lookup with generational key safety. (3) The system auto-enables when the first light is added. (4) Bitmask fields (`light_mask`, `shadow_mask`) control per-light/per-occluder interaction filtering. (5) `FlickerConfig` provides built-in sinusoidal intensity modulation driven by `advance_flickers(dt)` on the world. (6) Group operations (`set_group_enabled`, `set_group_intensity`, `set_group_color`) allow batch control of lights sharing a `group_id`.

Scope boundary: GPU shadow mapping, ray-marching, and rendering live in `graphics` and `lua_api`. The `light` module does not import `graphics` ÔÇö it only imports `math` (for `Vec2`, `Color`) and `engine` (for `SlotMap` keys and log messages). Volumetric scattering is flagged via `Light2D::volumetric` but not implemented at the data level ÔÇö the renderer decides how to use the hint.

## Architecture

```
LightWorld (resource pool)
ÔöťÔöÇÔöÇ lights: SlotMap<LightKey, Light2D>
Ôöé   ÔööÔöÇÔöÇ Light2D
Ôöé       ÔöťÔöÇÔöÇ position (x, y)
Ôöé       ÔöťÔöÇÔöÇ radius, color, intensity, enabled, energy
Ôöé       ÔöťÔöÇÔöÇ blend_mode  Ôćĺ LightBlendMode (Add | Sub | Mix)
Ôöé       ÔöťÔöÇÔöÇ falloff     Ôćĺ FalloffMode (Linear | Smooth | Constant)
Ôöé       ÔöťÔöÇÔöÇ light_type  Ôćĺ LightType (Point | Directional | Spot)
Ôöé       Ôöé   ÔöťÔöÇÔöÇ direction (radians)
Ôöé       Ôöé   ÔööÔöÇÔöÇ inner_angle, outer_angle (for Spot)
Ôöé       ÔöťÔöÇÔöÇ attenuation Ôćĺ Attenuation (constant, linear, quadratic)
Ôöé       ÔöťÔöÇÔöÇ flicker     Ôćĺ FlickerConfig (speed, strength, phase)
Ôöé       ÔöťÔöÇÔöÇ shadow_enabled, shadow_color, shadow_filter, shadow_smooth
Ôöé       ÔöťÔöÇÔöÇ light_mask, shadow_mask (u16 bitmasks)
Ôöé       ÔööÔöÇÔöÇ group_id, volumetric
Ôöé
ÔöťÔöÇÔöÇ occluders: SlotMap<OccluderKey, Occluder>
Ôöé   ÔööÔöÇÔöÇ Occluder
Ôöé       ÔöťÔöÇÔöÇ vertices: Vec<Vec2> (3..=256)
Ôöé       ÔöťÔöÇÔöÇ position: Vec2
Ôöé       ÔöťÔöÇÔöÇ opacity: f32
Ôöé       ÔöťÔöÇÔöÇ light_mask: u16
Ôöé       ÔööÔöÇÔöÇ enabled: bool
Ôöé
ÔöťÔöÇÔöÇ ambient: Color
ÔöťÔöÇÔöÇ enabled: bool
ÔööÔöÇÔöÇ max_lights: u16

Data flow:
  Lua scripts Ôćĺ lurek.light.* (light_api.rs)
    Ôćĺ mutates LightWorld in SharedState
      Ôćĺ renderer reads LightWorld during render_frame()
        Ôćĺ produces lighting pass via RenderCommand queue
```

## Source Files

| File              | Purpose                                                        |
|-------------------|----------------------------------------------------------------|
| `mod.rs`          | Module root ÔÇö re-exports all public types, declares submodules |
| `attenuation.rs`  | `Attenuation` struct ÔÇö custom distance falloff coefficients    |
| `blend_mode.rs`   | `LightBlendMode` enum ÔÇö additive / subtractive / mix blending  |
| `falloff.rs`      | `FalloffMode` enum ÔÇö linear / smooth / constant intensity decay|
| `flicker.rs`      | `FlickerConfig` struct ÔÇö sinusoidal intensity modulation       |
| `light2d.rs`      | `Light2D` struct ÔÇö primary light data container (23 fields)    |
| `light_type.rs`   | `LightType` enum ÔÇö point / directional / spot geometry         |
| `light_world.rs`  | `LightWorld` struct ÔÇö SlotMap pool for lights and occluders    |
| `occluder.rs`     | `Occluder` struct ÔÇö polygon shadow caster definition           |
| `shadow.rs`       | `ShadowFilter` enum ÔÇö shadow edge quality (none / PCF5 / PCF13)|

## Submodules

### `light::attenuation`

Custom attenuation coefficients for light falloff curves.

- **`Attenuation`** (struct): Three-coefficient (constant, linear, quadratic) model controlling how light intensity decays with distance. Computes `1 / (c + l*d + q*d┬▓)`.

### `light::blend_mode`

Light blend mode enum for controlling how light color mixes with the scene.

- **`LightBlendMode`** (enum): Selects compositing strategy ÔÇö `Add` (brightens), `Sub` (darkens), or `Mix` (lerp by intensity). Default: `Add`.

### `light::falloff`

Falloff mode enum for controlling how light intensity decays over distance.

- **`FalloffMode`** (enum): Selects radial decay shape ÔÇö `Linear` (ramp to zero), `Smooth` (quadratic ease-out), or `Constant` (full intensity with hard cutoff). Default: `Linear`.

### `light::flicker`

Built-in flicker effect configuration for lights.

- **`FlickerConfig`** (struct): Drives sinusoidal intensity modulation via `speed` (rad/s), `strength` (amplitude fraction), and an auto-advancing `phase`. Computes multiplier as `1 + strength * sin(phase)`.

### `light::light2d`

2D point light data container ÔÇö the primary type in this module.

- **`Light2D`** (struct): Flat data container with 23 public fields describing a 2D light source: position, radius, color, intensity, enabled, energy, blend mode, falloff, shadow settings, masks, light type, direction, cone angles, attenuation, flicker, group ID, and volumetric flag.

### `light::light_type`

Geometric light type variants.

- **`LightType`** (enum): `Point` (omnidirectional), `Directional` (parallel rays, no positional falloff), or `Spot` (cone defined by inner/outer angles). Default: `Point`.

### `light::light_world`

Resource pool and state for the 2D lighting system.

- **`LightWorld`** (struct): Owns `SlotMap<LightKey, Light2D>` and `SlotMap<OccluderKey, Occluder>` pools, plus global ambient color, enabled flag, and max_lights cap. Provides add/remove/get/clear operations, group batch operations, and `advance_flickers(dt)`.

### `light::occluder`

Polygon shadow caster for the 2D lighting system.

- **`Occluder`** (struct): Convex or concave polygon (3ÔÇô256 vertices) in local space with a translation offset, opacity (0ÔÇô1), light interaction bitmask, and enabled flag. Panics if vertex count is outside 3..=256.

### `light::shadow`

Shadow filter enum for controlling edge quality of shadow boundaries.

- **`ShadowFilter`** (enum): `None` (hard edges), `Pcf5` (5-tap percentage-closer filtering), or `Pcf13` (13-tap PCF for smoother edges). Default: `None`.

## Key Types

### Structs

#### `light::attenuation::Attenuation`

Custom attenuation coefficients controlling light intensity decay. Three fields: `constant` (f32, default 1.0), `linear` (f32, default 0.0), `quadratic` (f32, default 0.0). The effective intensity at distance `d` is `intensity / (constant + linear * d + quadratic * d┬▓)`. Provides `new(c, l, q)` constructor and `factor(distance) -> f32` for computing the attenuation multiplier. Implements `Default` (no custom attenuation).

#### `light::flicker::FlickerConfig`

Built-in flicker effect that modulates light intensity over time. Fields: `enabled` (bool), `speed` (f32, default 8.0 rad/s), `strength` (f32, default 0.15), `phase` (f32, auto-advances). Provides `new(speed, strength)` (creates enabled config), `multiplier() -> f32` (returns current intensity scale), and `advance(dt)` (advances phase, wraps at 2¤Ç). Implements `Default` (disabled).

#### `light::light2d::Light2D`

2D point light with position, radius, color, intensity, and shadow settings. Contains 23 public fields covering all light parameters. Constructor `new(x, y, radius)` creates a white, enabled, point light at the given position. Provides getter/setter pairs for every field: position, radius, color, intensity, enabled, energy, blend_mode, falloff, shadow_enabled, shadow_color, shadow_filter, shadow_smooth, light_mask, shadow_mask, light_type, direction, inner_angle, outer_angle, attenuation, group_id, volumetric. Also provides `flicker()` and `flicker_mut()` for direct flicker config access.

#### `light::light_world::LightWorld`

Resource pool and state for the 2D lighting system. Owns `SlotMap<LightKey, Light2D>` and `SlotMap<OccluderKey, Occluder>` plus `ambient` color, `enabled` flag, and `max_lights` cap (default 64). Auto-enables when the first light is added. Provides: `add_light`, `add_occluder`, `remove_light`, `remove_occluder`, `get_light`, `get_light_mut`, `get_occluder`, `get_occluder_mut`, `light_count`, `occluder_count`, `clear`, `has_active_lights`, `set_group_enabled`, `set_group_intensity`, `set_group_color`, `group_count`, `advance_flickers`. Implements `Default`.

#### `light::occluder::Occluder`

Polygon shadow caster that blocks light. Fields: `vertices` (Vec\<Vec2\>, 3ÔÇô256 verts), `position` (Vec2), `opacity` (f32, 0ÔÇô1), `light_mask` (u16), `enabled` (bool). Constructor `new(vertices)` panics if vertex count is outside 3..=256. Provides getter/setter pairs for vertices, position, opacity, light_mask, and enabled.

### Enums

#### `light::blend_mode::LightBlendMode`

How light color mixes with the scene. Variants: `Add` (additive, default ÔÇö brightens), `Sub` (subtractive ÔÇö darkens), `Mix` (lerp by intensity). Implements `Default` (Add).

#### `light::falloff::FalloffMode`

How light intensity decays from center to edge. Variants: `Linear` (default ÔÇö ramp to zero), `Smooth` (quadratic ease-out for soft falloff), `Constant` (full intensity with hard cutoff at edge). Implements `Default` (Linear).

#### `light::light_type::LightType`

The geometric shape of a light source. Variants: `Point` (default ÔÇö omnidirectional), `Directional` (parallel rays, no positional falloff), `Spot` (cone defined by direction + inner/outer angles). Implements `Default` (Point).

#### `light::shadow::ShadowFilter`

Edge quality for shadow boundaries. Variants: `None` (default ÔÇö hard edges), `Pcf5` (5-tap percentage-closer filtering for soft edges), `Pcf13` (13-tap PCF for smoother edges). Implements `Default` (None).

## Lua API

Exposed under `lurek.light.*` by `src/lua_api/light_api.rs`. The API provides two UserData types (`Light` and `Occluder`) and module-level functions for world management.

### Module-level functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.light.newLight` | `(x, y, radius [, opts])` Ôćĺ Light | Creates a point light; opts table overrides defaults |
| `lurek.light.newOccluder` | `(vertices [, opts])` Ôćĺ Occluder | Creates a shadow polygon from flat `{x1,y1,...}` table |
| `lurek.light.setAmbient` | `(r, g, b [, a])` | Sets global ambient light color |
| `lurek.light.getAmbient` | `()` Ôćĺ r, g, b, a | Returns global ambient color |
| `lurek.light.setEnabled` | `(enabled)` | Enables/disables the lighting system |
| `lurek.light.isEnabled` | `()` Ôćĺ bool | Returns lighting system state |
| `lurek.light.getLightCount` | `()` Ôćĺ int | Number of lights in the world |
| `lurek.light.getOccluderCount` | `()` Ôćĺ int | Number of occluders in the world |
| `lurek.light.getMaxLights` | `()` Ôćĺ int | Max lights processed per frame |
| `lurek.light.setMaxLights` | `(n)` | Sets max lights (clamped 1ÔÇô256) |
| `lurek.light.clear` | `()` | Removes all lights and occluders |
| `lurek.light.setGroupEnabled` | `(groupId, enabled)` | Enables/disables all lights in a group |
| `lurek.light.setGroupIntensity` | `(groupId, intensity)` | Sets intensity for a group |
| `lurek.light.setGroupColor` | `(groupId, r, g, b [, a])` | Sets color for a group |
| `lurek.light.getGroupCount` | `(groupId)` Ôćĺ int | Number of lights in a group |
| `lurek.light.advanceFlickers` | `(dt)` | Advances flicker phase for all lights |

### Light UserData methods

`setPosition(x, y)`, `getPosition()`, `setRadius(r)`, `getRadius()`, `setColor(r, g, b [, a])`, `getColor()`, `setIntensity(i)`, `getIntensity()`, `setEnergy(e)`, `getEnergy()`, `setBlendMode(mode)`, `getBlendMode()`, `setFalloff(mode)`, `getFalloff()`, `setShadowEnabled(b)`, `isShadowEnabled()`, `setShadowColor(r, g, b [, a])`, `getShadowColor()`, `setShadowFilter(filter)`, `getShadowFilter()`, `setShadowSmooth(s)`, `getShadowSmooth()`, `setLightMask(mask)`, `getLightMask()`, `setShadowMask(mask)`, `getShadowMask()`, `setEnabled(b)`, `isEnabled()`, `setLightType(t)`, `getLightType()`, `setDirection(dir)`, `getDirection()`, `setInnerAngle(a)`, `getInnerAngle()`, `setOuterAngle(a)`, `getOuterAngle()`, `setAttenuation(c, l, q)`, `getAttenuation()`, `setFlicker(speed, strength)`, `getFlicker()`, `setFlickerEnabled(b)`, `isFlickerEnabled()`, `setGroupId(id)`, `getGroupId()`, `setVolumetric(b)`, `isVolumetric()`, `remove()`, `isValid()`

### Occluder UserData methods

`setVertices(tbl)`, `getVertices()`, `setPosition(x, y)`, `getPosition()`, `setOpacity(o)`, `getOpacity()`, `setLightMask(mask)`, `getLightMask()`, `setEnabled(b)`, `isEnabled()`, `remove()`, `isValid()`

### `newLight` opts table keys

`color` (table `{r,g,b[,a]}`), `intensity`, `energy`, `blend` (`"add"`/`"sub"`/`"mix"`), `falloff` (`"linear"`/`"smooth"`/`"constant"`), `shadowEnabled`, `shadowColor`, `shadowFilter` (`"none"`/`"pcf5"`/`"pcf13"`), `shadowSmooth`, `lightMask`, `shadowMask`, `enabled`, `type` (`"point"`/`"directional"`/`"spot"`), `direction`, `innerAngle`, `outerAngle`, `groupId`, `volumetric`, `flickerSpeed`, `flickerStrength`, `attConstant`, `attLinear`, `attQuadratic`

## Lua Examples

```lua
-- Basic point light with flicker and an occluder casting shadows
local torch, wall

function lurek.init()
    -- Create a warm torch light with flicker
    torch = lurek.light.newLight(400, 300, 200, {
        color = {1.0, 0.8, 0.4},
        intensity = 1.2,
        falloff = "smooth",
        shadowEnabled = true,
        flickerSpeed = 10,
        flickerStrength = 0.2,
    })

    -- Create a rectangular occluder (wall)
    wall = lurek.light.newOccluder({
        100, 200,   -- top-left
        200, 200,   -- top-right
        200, 400,   -- bottom-right
        100, 400,   -- bottom-left
    })

    -- Set dim ambient so unlit areas are not pitch black
    lurek.light.setAmbient(0.05, 0.05, 0.1)
end

function lurek.process(dt)
    -- Move the torch to follow the mouse
    local mx, my = lurek.mouse.getPosition()
    torch:setPosition(mx, my)

    -- Advance all flicker effects
    lurek.light.advanceFlickers(dt)
end

function lurek.render()
    -- Draw your scene; the lighting system composites automatically
    lurek.graphic.print("Move the mouse to move the torch", 10, 10)
end
```

```lua
-- Spot light with group management
function lurek.init()
    -- Create three spot lights in group 1
    for i = 1, 3 do
        lurek.light.newLight(200 * i, 300, 150, {
            type = "spot",
            direction = math.pi / 2,
            innerAngle = math.pi / 8,
            outerAngle = math.pi / 4,
            groupId = 1,
        })
    end

    -- Dim the entire group at once
    lurek.light.setGroupIntensity(1, 0.5)
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 5     |
| `enum`     | 4     |
| `fn`       | 78    |
| **Total**  | **87**|

## References

| Module      | Relationship | Notes                                                    |
|-------------|--------------|----------------------------------------------------------|
| `math`      | Imports from | Uses `Vec2` (occluder vertices/position) and `Color` (light tint, ambient, shadow color) |
| `engine`    | Imports from | Uses `LightKey`, `OccluderKey` (SlotMap keys from `resource_keys.rs`), log message constants |
| `lua_api`   | Imported by  | `light_api.rs` exposes `lurek.light.*` ÔÇö provides `LuaLight` and `LuaOccluder` UserData types |
| `graphics`  | Related      | Renderer reads `LightWorld` from `SharedState` to produce the lighting pass; light module does not import graphics |
| `particle`  | Similar      | Both are Tier 2 modules with SlotMap resource pools; particle owns visual emission, light owns illumination data |

## Notes

- **CPU-only data model**: The `light` module holds zero GPU resources. All rendering is performed by the graphics pipeline reading `LightWorld` from `SharedState`. This makes the module fully testable without a GPU context.
- **Auto-enable behaviour**: `LightWorld::add_light()` sets `enabled = true` automatically when the first light is inserted. Scripts do not need to call `lurek.light.setEnabled(true)` explicitly.
- **Occluder vertex limits**: `Occluder::new()` panics (Rust-side assert) if the vertex count is outside 3..=256. The Lua API (`parse_vertex_table`) validates 6..=512 flat elements (i.e., 3..=256 vertices) before reaching the Rust constructor.
- **Bitmask filtering**: `light_mask` and `shadow_mask` on both `Light2D` and `Occluder` default to `0xFFFF` (all bits set), meaning all lights interact with all occluders by default. Custom masks allow selective light-occluder filtering without removing objects.
- **Flicker phase wrapping**: `FlickerConfig::advance()` wraps `phase` at `2¤Ç` to prevent float overflow during long-running sessions.
- **Max lights cap**: `LightWorld::max_lights` defaults to 64 and is clamped to 1ÔÇô256 by the Lua API. The renderer uses this to limit per-frame processing.
- **No `Default` on `Light2D`**: `Light2D` does not implement `Default` ÔÇö use `Light2D::new(x, y, radius)` which provides sensible defaults for all other fields (white, intensity 1.0, enabled, point type, no shadows, no flicker).
- **Module tier**: Although `mod.rs` states "Tier 1", the module is classified as **Tier 2 ÔÇö Engine Extension** in the architecture docs because it builds on top of Baseline functionality to provide a reusable lighting abstraction.
