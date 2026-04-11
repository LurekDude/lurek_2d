# `effect` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Platform Services |
| **Status** | Implemented |
| **Lua API** | `lurek.effect` |
| **Source** | `src/effect/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Platform Services` |

---

## Summary

The effect module owns CPU-side visual effect state. It covers two adjacent areas: post-processing descriptions such as PostFxEffect, PostFxStack, and ImageEffect, and full-screen overlay state such as ambient tint, weather, fog, flash, shake, fade, and lightning.

This module exists so effect behavior can be configured, updated, and tested without tying the code to a specific GPU implementation. It describes what effects are active and how they evolve over time, while leaving shader execution, render targets, and final compositing to the renderer and Lua bridge.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.effect.* (Lua API — src/lua_api/effect_api.rs)
    |
    v
src/effect/mod.rs
    |- ambient.rs - ambient
    |- atmosphere.rs - atmosphere
    |- draw.rs - draw
    |- effect.rs - effect
    |- effect_type.rs - effect_type
    |- image_effect.rs - image_effect
    |- overlay.rs - overlay
    |- render.rs - render
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `ambient.rs` | Defines time-of-day ambient lighting state. |
| `atmosphere.rs` | Defines cloud, fog, heat haze, vignette, film grain, and lightning state structs. |
| `draw.rs` | Provides CPU-side fallback drawing helpers for post-processing stacks. |
| `effect.rs` | Defines PostFxEffect, the parameter bag for a single post-processing pass. |
| `effect_type.rs` | Defines PostFxEffectType and the default parameter presets for built-in effect kinds. |
| `image_effect.rs` | Defines ImageEffect, a smaller effect chain attached to individual image draws. |
| `mod.rs` | Declares the effect submodules and re-exports the public post-processing and overlay types. |
| `overlay.rs` | Defines Overlay, the top-level screen-effect controller that aggregates ambient, atmospheric, weather, and transient screen effects. |
| `render.rs` | Generates render-command markers for beginning, ending, and applying post-processing capture. |
| `screen_effects.rs` | Defines flash, shake, and fade state. |
| `stack.rs` | Defines PostFxStack, the ordered full-frame post-processing pipeline container. |
| `weather.rs` | Defines weather particle types, live particles, and weather simulation state. |

---

## Submodules

### `effect::ambient`

Defines time-of-day ambient lighting state.

- **`AmbientState`** (struct): Ambient lighting state with time-of-day colour cycling.

### `effect::atmosphere`

Defines cloud, fog, heat haze, vignette, film grain, and lightning state structs.

- **`CloudState`** (struct): Cloud shadow overlay state.
- **`FogState`** (struct): Atmospheric fog state.
- **`HeatHazeState`** (struct): Heat haze distortion state.
- **`VignetteState`** (struct): Vignette screen-edge darkening state.
- **`FilmGrainState`** (struct): Film grain noise overlay state.
- **`LightningState`** (struct): Lightning flash state.

### `effect::draw`

Provides CPU-side fallback drawing helpers for post-processing stacks.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `effect::effect`

Defines PostFxEffect, the parameter bag for a single post-processing pass.

- **`PostFxEffect`** (struct): A single post-processing effect with named float parameters.

### `effect::effect_type`

Defines PostFxEffectType and the default parameter presets for built-in effect kinds.

- **`PostFxEffectType`** (enum): Built-in effect types for the post-processing pipeline.

### `effect::image_effect`

Defines ImageEffect, a smaller effect chain attached to individual image draws.

- **`ImageEffect`** (struct): An ordered shader-effect chain to apply when drawing a single image.

### `effect::overlay`

Defines Overlay, the top-level screen-effect controller that aggregates ambient, atmospheric, weather, and transient screen effects.

- **`Overlay`** (struct): Composable per-frame screen-effect overlay managing multiple visual subsystems.

### `effect::render`

Generates render-command markers for beginning, ending, and applying post-processing capture.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `effect::screen_effects`

Defines flash, shake, and fade state.

- **`FlashState`** (struct): Flash screen effect state.
- **`ShakeState`** (struct): Shake screen effect state.
- **`FadeState`** (struct): Fade screen effect state.

### `effect::stack`

Defines PostFxStack, the ordered full-frame post-processing pipeline container.

- **`PostFxStack`** (struct): An ordered chain of effects that captures and processes the rendered scene.

### `effect::weather`

Defines weather particle types, live particles, and weather simulation state.

- **`WeatherType`** (enum): Weather particle types supported by the overlay system.
- **`WeatherParticle`** (struct): A single weather particle in the overlay's weather system.
- **`WeatherState`** (struct): Weather subsystem state.

---

## Key Types

### Public Types

#### `PostFxEffect`

One post-processing pass with effect type, parameter map, enabled flag, and optional custom shader handle.

#### `PostFxEffectType`

Enum naming the built-in post-processing pass types and their default parameter sets.

#### `PostFxStack`

Ordered full-frame post-processing pipeline with per-pass enabled flags and capture dimensions.

#### `ImageEffect`

Ordered per-image effect chain that converts to lightweight shader pass descriptors.

#### `Overlay`

Top-level per-frame overlay state that updates ambient, weather, flashes, fades, shake, and atmospheric effects together.

#### `AmbientState`

Time-of-day ambient tint controller used by Overlay.

#### `WeatherState`

Weather particle simulation state including type, wind, intensity, and live particles.

#### `FlashState, ShakeState, FadeState`

Short-lived screen-space feedback effects.

---

## Lua API

Exposed under `lurek.effect.*` by `src/lua_api/effect_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.effect.newEffect` | Creates a new built-in post-processing effect by type name. |
| `lurek.effect.newCustomEffect` | Creates a custom shader post-processing effect. |
| `lurek.effect.newStack` | Creates a new post-processing pipeline stack. |
| `lurek.effect.newPass` | Creates a custom-shader post-processing effect (alias for newCustomEffect). |
| `lurek.effect.getEffectTypes` | Returns the list of all built-in effect type names. |
| `lurek.effect.newImageEffect` | Creates a new per-image effect chain. Accepts: |
| `lurek.effect.newOverlay` | Creates a new screen overlay controller for weather, flash, shake, and fade effects. |

### `ImageEffect` Methods

| Method | Description |
|--------|-------------|
| `imageeffect:addEffect(...)` | Creates a new effect by type name, appends it, and returns the shared PostFxEffect. |
| `imageeffect:getEffect(...)` | Returns the effect at the given 1-based index or with the given type name. |
| `imageeffect:removeEffect(...)` | Removes the effect at the given 1-based index or with the given type name. |
| `imageeffect:clearEffects(...)` | Removes all effects from the chain. |
| `imageeffect:clear(...)` | Removes all effects from the chain (alias for clearEffects). |
| `imageeffect:effectCount(...)` | Returns the number of effects in the chain. |
| `imageeffect:getEffectCount(...)` | Returns the number of effects in the chain (alias for effectCount). |
| `imageeffect:clone(...)` | Returns a deep copy of this ImageEffect chain. |
| `imageeffect:save(...)` | Stub: no-op serialisation placeholder. |
| `imageeffect:type(...)` | Returns the type name "ImageEffect". |
| `imageeffect:typeOf(...)` | Returns true when the given name matches "ImageEffect" or a parent type. |
| `imageeffect:removeByIndex(...)` | Removes the effect at the given 0-based index from the chain. |
| `imageeffect:removeByName(...)` | Removes the first effect matching the given type name. |

### `Overlay` Methods

| Method | Description |
|--------|-------------|
| `overlay:update(...)` | Advances all overlay subsystems by the given delta time. |
| `overlay:triggerLightning(...)` | Triggers a lightning flash effect. |
| `overlay:getShakeOffset(...)` | Returns the current shake displacement as x, y. |
| `overlay:isActive(...)` | Returns true if any overlay subsystem is currently active. |
| `overlay:clear(...)` | Resets all overlay subsystems to their default inactive state. |
| `overlay:resize(...)` | Resizes the overlay to match new window dimensions. |
| `overlay:getWidth(...)` | Returns the overlay width. |
| `overlay:getHeight(...)` | Returns the overlay height. |
| `overlay:getDimensions(...)` | Returns the overlay width and height. |
| `overlay:getFlashAlpha(...)` | Returns the current flash overlay alpha value. |
| `overlay:getLightningAlpha(...)` | Returns the current lightning overlay alpha value. |
| `overlay:setAmbientEnabled(...)` | Enables or disables the ambient light layer. |
| `overlay:isAmbientEnabled(...)` | Returns whether the ambient light layer is active. |
| `overlay:getAmbientColor(...)` | Returns the current ambient tint as r, g, b, a components. |
| `overlay:setTimeOfDay(...)` | Sets the simulated time-of-day (0–24) which drives ambient colour. |
| `overlay:getTimeOfDay(...)` | Returns the current simulated time-of-day (0–24). |
| `overlay:setFogEnabled(...)` | Enables or disables the fog layer. |
| `overlay:isFogEnabled(...)` | Returns whether the fog layer is active. |
| `overlay:setFogDensity(...)` | Sets the fog density (0.0 = clear, 1.0 = fully opaque). |
| `overlay:getFogDensity(...)` | Returns the current fog density. |
| `overlay:getFogColor(...)` | Returns the current fog tint as r, g, b, a components. |
| `overlay:setHeatHazeEnabled(...)` | Enables or disables the heat-haze distortion layer. |
| `overlay:isHeatHazeEnabled(...)` | Returns whether the heat-haze layer is active. |
| `overlay:setHeatHazeIntensity(...)` | Sets the heat-haze distortion intensity (0.0–1.0). |
| `overlay:getHeatHazeIntensity(...)` | Returns the current heat-haze distortion intensity. |
| `overlay:setVignetteEnabled(...)` | Enables or disables the screen-edge vignette layer. |
| `overlay:isVignetteEnabled(...)` | Returns whether the vignette layer is active. |
| `overlay:setVignetteStrength(...)` | Sets the vignette darkening strength (0.0–1.0). |
| `overlay:getVignetteStrength(...)` | Returns the current vignette strength. |
| `overlay:setFilmGrainEnabled(...)` | Enables or disables the film-grain noise layer. |
| `overlay:isFilmGrainEnabled(...)` | Returns whether the film-grain layer is active. |
| `overlay:setFilmGrainIntensity(...)` | Sets the film-grain noise intensity (0.0–1.0). |
| `overlay:getFilmGrainIntensity(...)` | Returns the current film-grain intensity. |
| `overlay:setCloudShadows(...)` | Enables or disables scrolling cloud-shadow projection. |
| `overlay:isCloudShadowsEnabled(...)` | Returns whether cloud shadows are active. |
| `overlay:setCloudCount(...)` | Sets the number of cloud shadow instances to render. |
| `overlay:getCloudCount(...)` | Returns the current cloud shadow instance count. |
| `overlay:setCloudSpeed(...)` | Sets the horizontal scroll speed of cloud shadows in pixels per second. |
| `overlay:getCloudSpeed(...)` | Returns the current cloud shadow scroll speed. |
| `overlay:setCloudScale(...)` | Sets the scale multiplier applied to each cloud shadow. |
| `overlay:getCloudScale(...)` | Returns the current cloud shadow scale. |
| `overlay:setCloudOpacity(...)` | Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark). |
| `overlay:getCloudOpacity(...)` | Returns the current cloud shadow opacity. |
| `overlay:setWeatherEnabled(...)` | Enables or disables the weather particle system. |
| `overlay:isWeatherEnabled(...)` | Returns whether the weather particle system is active. |
| `overlay:setWeather(...)` | Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen"). |
| `overlay:getWeather(...)` | Returns the name of the current weather type. |
| `overlay:setWeatherIntensity(...)` | Sets the particle spawn rate multiplier (0.0–1.0). |
| `overlay:getWeatherIntensity(...)` | Returns the current weather intensity. |
| `overlay:setWindDirection(...)` | Sets the wind direction in radians (0 = right, π/2 = down). |
| `overlay:getWindDirection(...)` | Returns the current wind direction in radians. |
| `overlay:setWindSpeed(...)` | Sets the wind speed applied to weather particles in units per second. |
| `overlay:getWindSpeed(...)` | Returns the current wind speed. |
| `overlay:getLightningColor(...)` | Returns the lightning flash tint as r, g, b, a components. |
| `overlay:isFlashing(...)` | Returns true while a flash effect is in progress. |
| `overlay:shake(...)` | Triggers a camera shake; duration defaults to 0.5 s. |
| `overlay:isShaking(...)` | Returns true while a shake effect is in progress. |
| `overlay:isFading(...)` | Returns true while a fade effect is in progress. |
| `overlay:render(...)` | Emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette). |
| `overlay:drawToImage(...)` | Renders the overlay state (flash, fade, effects) to a CPU ImageData. |
| `overlay:type(...)` | Returns the type name of this object ("Overlay"). |
| `overlay:typeOf(...)` | Returns true if this object is of the given type ("Object" or "Overlay"). |

### `PostFxEffect` Methods

| Method | Description |
|--------|-------------|
| `postfxeffect:getTypeName(...)` | Returns the display name of this effect type. |
| `postfxeffect:isBuiltIn(...)` | Returns true if this is a built-in effect, false if custom. |
| `postfxeffect:isEnabled(...)` | Returns whether this effect is currently active. |
| `postfxeffect:setEnabled(...)` | Enables or disables this effect. |
| `postfxeffect:setParameter(...)` | Sets a named float parameter on this effect. |
| `postfxeffect:hasParameter(...)` | Returns true if the named parameter exists on this effect. |
| `postfxeffect:getParameterNames(...)` | Returns a list of all parameter names on this effect. |
| `postfxeffect:getEffectType(...)` | Returns the type name of this effect (alias for getTypeName). |
| `postfxeffect:getType(...)` | Returns the type name of this effect (alias for getTypeName). |
| `postfxeffect:type(...)` | Returns the type name "PostFxEffect". |
| `postfxeffect:typeOf(...)` | Returns true when the given name matches "PostFxEffect" or a parent type. |
| `postfxeffect:setThreshold(...)` | Sets the threshold parameter of this effect. |
| `postfxeffect:setIntensity(...)` | Sets the intensity parameter of this effect. |
| `postfxeffect:setRadius(...)` | Sets the radius parameter of this effect. |
| `postfxeffect:setStrength(...)` | Sets the strength parameter of this effect. |
| `postfxeffect:setScanlineStrength(...)` | Sets the scanline strength parameter of this effect. |
| `postfxeffect:setOffset(...)` | Sets the offset parameter of this effect. |
| `postfxeffect:setBrightness(...)` | Sets the brightness parameter of this effect. |
| `postfxeffect:setContrast(...)` | Sets the contrast parameter of this effect. |
| `postfxeffect:setSaturation(...)` | Sets the saturation parameter of this effect. |

### `PostFxStack` Methods

| Method | Description |
|--------|-------------|
| `postfxstack:add(...)` | Appends a PostFxEffect to the end of the pipeline. |
| `postfxstack:remove(...)` | Removes the given PostFxEffect from the pipeline. |
| `postfxstack:isEnabled(...)` | Returns whether the effect at the given 1-based position is enabled. |
| `postfxstack:getEffectCount(...)` | Returns the number of effects in the pipeline. |
| `postfxstack:getEffect(...)` | Returns the effect at the given 1-based position, or nil. |
| `postfxstack:getEnabledEffects(...)` | Returns a list of currently enabled effect objects. |
| `postfxstack:getWidth(...)` | Returns the width of the render target. |
| `postfxstack:getHeight(...)` | Returns the height of the render target. |
| `postfxstack:getDimensions(...)` | Returns width and height of the render target. |
| `postfxstack:resize(...)` | Resizes the render target to the given dimensions. |
| `postfxstack:len(...)` | Returns the total number of effect slots in the pipeline. |
| `postfxstack:isEmpty(...)` | Returns true if the pipeline has no effect slots. |
| `postfxstack:clear(...)` | Removes all effects from the pipeline. |
| `postfxstack:isCapturing(...)` | Returns whether the stack is currently capturing the scene. |
| `postfxstack:type(...)` | Returns the type name "PostFxStack". |
| `postfxstack:typeOf(...)` | Returns true when the given name matches "PostFxStack" or a parent type. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.effect.
if lurek.effect then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 16 |
| `enum` | 2 |
| `fn` (Lua API) | 118 |
| **Total** | **136** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `render` | Imports or references `render` from `src/render/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Platform Services to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/effect/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
