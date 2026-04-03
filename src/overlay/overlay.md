# overlay — Screen Effects & Environmental Overlay Module

> **Lua namespace:** `luna.overlay`
> **C++ module:** `src/modules/overlay/`
> **Purpose:** Provides a composable overlay system for weather effects (rain, snow, hail, dust, leaves, ash, pollen), ambient lighting with time-of-day, screen effects (flash, shake, fade), cloud shadows, atmospheric fog, heat haze distortion, vignette, film grain, and lightning. The overlay is updated per-frame and drawn on top of the scene.

## Reimplementation Notes

- The Overlay is a self-contained render object — it manages its own internal state for all subsystems
- Each subsystem (weather, fog, clouds, vignette, etc.) can be independently enabled/disabled
- Weather particles are simulated with wind direction + speed and intensity
- Time-of-day drives ambient color cycling (0–24 hour float)
- Screen effects (flash, shake, fade) are one-shot animations with a duration — `update(dt)` advances them
- Cloud shadows, fog, heat haze, vignette, film grain require shader-based rendering
- Lightning is a triggered one-shot flash effect with configurable color
- The `draw()` method renders all active effects into the current render target — call after drawing your scene
- `getShakeOffset()` returns pixel offsets to apply to your camera transform for screen shake

## Dependencies

- `luna.graphics` (for rendering effects — defaults to window dimensions if not provided)

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newOverlay` | `width?: int, height?: int` | `Overlay` | Create a new overlay. Defaults to `luna.graphics.getDimensions()` if not provided |

---

## Type: Overlay

A composable overlay managing multiple visual subsystems.

**Created by:** `luna.overlay.newOverlay(width?, height?)`

### Core Lifecycle

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `update` | `dt: number` | — | Advance all active effects by delta time. Call every frame |
| `draw` | — | — | Render all active effects to screen. Call after drawing your scene |
| `resize` | `width, height` | — | Update internal dimensions (e.g., on window resize) |
| `getWidth` | — | `int` | Get overlay width |
| `getHeight` | — | `int` | Get overlay height |
| `getDimensions` | — | `int, int` | Get width and height |
| `clear` | — | — | Reset all effects to inactive defaults |
| `isActive` | — | `boolean` | True if any effect is currently active |

### Ambient Lighting

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setAmbientColor` | `r, g, b, a?` | — | Set the ambient tint color (alpha defaults to 1.0) |
| `getAmbientColor` | — | `r, g, b, a` | Get the ambient tint color |
| `setTimeOfDay` | `hour: number` | — | Set time of day (0.0–24.0 float). Drives ambient color cycling |
| `getTimeOfDay` | — | `number` | Get current time of day |
| `setAmbientEnabled` | `enabled: boolean` | — | Enable/disable ambient lighting |
| `isAmbientEnabled` | — | `boolean` | Check if ambient lighting is enabled |

### Weather System

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setWeather` | `type: string` | — | Set weather type (see WeatherType enum) |
| `getWeather` | — | `string` | Get current weather type name |
| `setWeatherIntensity` | `intensity: number` | — | Set particle density/intensity |
| `getWeatherIntensity` | — | `number` | Get weather intensity |
| `setWindDirection` | `angle: number` | — | Set wind angle in radians |
| `getWindDirection` | — | `number` | Get wind direction |
| `setWindSpeed` | `speed: number` | — | Set wind speed |
| `getWindSpeed` | — | `number` | Get wind speed |
| `setWeatherEnabled` | `enabled: boolean` | — | Enable/disable weather particles |
| `isWeatherEnabled` | — | `boolean` | Check if weather is enabled |

### Screen Effects

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `flash` | `r, g, b, a?, duration?` | — | Trigger a screen flash. Alpha defaults to 1.0, duration to 0.2s |
| `shake` | `intensity, duration?` | — | Trigger screen shake. Duration defaults to 0.5s |
| `fade` | `r, g, b, targetAlpha?, duration?` | — | Fade to a color. Target alpha defaults to 1.0, duration to 1.0s |
| `getShakeOffset` | — | `x, y` | Get current shake pixel offset (apply to your camera) |
| `isFlashing` | — | `boolean` | True if a flash is active |
| `isShaking` | — | `boolean` | True if a shake is active |
| `isFading` | — | `boolean` | True if a fade is in progress |

### Cloud Shadows

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setCloudShadows` | `enabled: boolean` | — | Enable/disable cloud shadow overlay |
| `isCloudShadowsEnabled` | — | `boolean` | Check if cloud shadows are enabled |
| `setCloudCount` | `count: int` | — | Number of cloud shadow blobs |
| `getCloudCount` | — | `int` | Get cloud count |
| `setCloudSpeed` | `speed: number` | — | Cloud movement speed |
| `getCloudSpeed` | — | `number` | Get cloud speed |
| `setCloudScale` | `scale: number` | — | Cloud shadow blob size |
| `getCloudScale` | — | `number` | Get cloud scale |
| `setCloudOpacity` | `opacity: number` | — | Shadow darkness (0.0 = invisible, 1.0 = fully dark) |
| `getCloudOpacity` | — | `number` | Get cloud opacity |

### Atmospheric Fog

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setFogEnabled` | `enabled: boolean` | — | Enable/disable atmospheric fog |
| `isFogEnabled` | — | `boolean` | Check if fog is enabled |
| `setFogDensity` | `density: number` | — | Set fog density |
| `getFogDensity` | — | `number` | Get fog density |
| `setFogColor` | `r, g, b, a?` | — | Set fog color (alpha defaults to 1.0) |
| `getFogColor` | — | `r, g, b, a` | Get fog color |

### Heat Haze

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setHeatHazeEnabled` | `enabled: boolean` | — | Enable/disable heat shimmer distortion |
| `isHeatHazeEnabled` | — | `boolean` | Check if heat haze is enabled |
| `setHeatHazeIntensity` | `intensity: number` | — | Set distortion strength |
| `getHeatHazeIntensity` | — | `number` | Get heat haze intensity |

### Vignette

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setVignetteEnabled` | `enabled: boolean` | — | Enable/disable screen edge darkening |
| `isVignetteEnabled` | — | `boolean` | Check if vignette is enabled |
| `setVignetteStrength` | `strength: number` | — | Set darkening intensity |
| `getVignetteStrength` | — | `number` | Get vignette strength |

### Film Grain

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setFilmGrainEnabled` | `enabled: boolean` | — | Enable/disable film grain noise |
| `isFilmGrainEnabled` | — | `boolean` | Check if film grain is enabled |
| `setFilmGrainIntensity` | `intensity: number` | — | Set grain noise intensity |
| `getFilmGrainIntensity` | — | `number` | Get film grain intensity |

### Lightning

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `triggerLightning` | — | — | Trigger a one-shot lightning flash effect |
| `setLightningColor` | `r, g, b, a?` | — | Set the lightning flash color |
| `getLightningColor` | — | `r, g, b, a` | Get the lightning flash color |

---

## Enums

### WeatherType

| Value | String | Description |
|---|---|---|
| 0 | `"none"` | No weather |
| 1 | `"rain"` | Rain particles |
| 2 | `"snow"` | Snow particles |
| 3 | `"hail"` | Hail particles |
| 4 | `"dust"` | Dust/sand particles |
| 5 | `"leaves"` | Falling leaves |
| 6 | `"ash"` | Volcanic ash particles |
| 7 | `"pollen"` | Pollen/floating particles |

---

## Usage Example

```lua
local overlay = luna.overlay.newOverlay()

function luna.update(dt)
    overlay:update(dt)
end

function luna.draw()
    -- Draw your game scene first
    drawWorld()

    -- Apply overlay effects on top
    overlay:draw()
end

function luna.resize(w, h)
    overlay:resize(w, h)
end

-- Set up a rainy night scene
overlay:setAmbientEnabled(true)
overlay:setTimeOfDay(22)  -- 10 PM
overlay:setWeatherEnabled(true)
overlay:setWeather("rain")
overlay:setWeatherIntensity(0.8)
overlay:setWindDirection(math.pi / 4)
overlay:setWindSpeed(50)
overlay:setFogEnabled(true)
overlay:setFogDensity(0.3)
overlay:setVignetteEnabled(true)
overlay:setVignetteStrength(0.5)
```
