# `overlay` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Engine Extension |
| **Status** | Implemented — Full |
| **Lua API** | `luna.overlay` |
| **Source** | `src/overlay/` |
| **Lua Bindings** | `src/lua_api/overlay_api.rs` |
| **Rust Tests** | `tests/unit/overlay_tests.rs` (78 tests) |
| **Lua Tests** | `tests/lua/unit/test_overlay.lua` (59 BDD tests) |
| **Example** | `examples/overlay_demo/main.lua` |
| **Design Doc** | `docs/API/overlay-design.md` |

## Summary

Composable per-frame screen-effect layer for atmospheric and cinematic game
effects, combining a weather particle system, ambient lighting with
time-of-day colour modulation, one-shot screen animations, and
shader-driven post-processing passes. The module is split into subfiles:
`weather.rs` (WeatherType, WeatherParticle, WeatherState), `ambient.rs`
(AmbientState with time-of-day curve), `effects.rs` (FlashState, ShakeState,
FadeState), `atmosphere.rs` (CloudState, FogState, HeatHazeState,
VignetteState, FilmGrainState, LightningState), and `overlay.rs` (Overlay
struct combining all subsystems). The weather subsystem supports seven
types (Rain, Snow, Hail, Dust, Leaves, Ash, Pollen), each driving a CPU
particle system with configurable wind direction, speed, and intensity.
Ambient lighting reads a `time_of_day` float (0-24) and maps it through a
colour curve to an RGBA tint over the entire scene, enabling smooth
dawn/dusk/night transitions without per-frame Lua math. Screen-effect
animations are one-shot objects with duration and elapsed counters: `Flash`
renders a fullscreen colour overlay, `Shake` produces a camera offset via
`getShakeOffset()`, and `Fade` blends between two colours for scene
transitions. Shader effects — cloud shadows, atmospheric fog, heat-haze
distortion, vignette, film grain, and lightning flashes — are applied as
post-processing passes using `luna.graphics` render targets. All subsystems
share a single `update(dt)` and `draw()` pair.

## Architecture

```
Overlay (composable screen-effect layer)
  │
  ├── Weather subsystem
  │     ├── type: Rain|Snow|Hail|Dust|Leaves|Ash|Pollen
  │     ├── particles: Vec<WeatherParticle { x, y, vx, vy, alpha, size }>
  │     └── wind: { dir, speed }, intensity: f32
  │
  ├── Ambient lighting
  │     ├── time_of_day: f32 (0.0–24.0)
  │     └── compute_color_from_time() → modulates RGBA tint per frame
  │
  ├── Screen effects (one-shot animations with duration + elapsed)
  │     ├── Flash { color, duration, elapsed }
  │     ├── Shake { intensity, duration, elapsed } → get_shake_offset() → (dx, dy)
  │     └── Fade { color, target_alpha, start_alpha, duration, elapsed }
  │
  ├── Atmospheric / shader-driven effects
  │     ├── CloudState  { enabled, count, speed, scale, opacity, offset }
  │     ├── FogState    { enabled, density, color }
  │     ├── HeatHazeState { enabled, intensity }
  │     ├── VignetteState { enabled, strength }
  │     ├── FilmGrainState { enabled, intensity }
  │     └── LightningState { active, color, elapsed, duration }
  │
  ├── update(dt) — advance all subsystem timers; compute ambient color
  └── draw()     — render active effects over current scene (GPU application in overlay_api.rs)

Dependency: luna.graphics (render target, default window dimensions)
```

## Key Types (Rust)

| Type | Purpose |
|------|---------|
| `Overlay` | Root struct; owns all subsystem state |
| `WeatherType` | Enum: None, Rain, Snow, Hail, Dust, Leaves, Ash, Pollen |
| `WeatherParticle` | Per-particle state: position, velocity, alpha, size |
| `WeatherState` | Manages particle vec, spawn timer, intensity, wind |
| `AmbientState` | Holds enabled flag, color, time_of_day |
| `FlashState` | One-shot fullscreen color overlay |
| `ShakeState` | One-shot camera shake with xorshift PRNG offsets |
| `FadeState` | One-shot alpha transition between two colors |
| `CloudState` | Cloud-shadow scroll parameters |
| `FogState` | Atmospheric fog density and color |
| `HeatHazeState` | Heat-shimmer distortion intensity |
| `VignetteState` | Screen edge darkening strength |
| `FilmGrainState` | Film grain noise intensity |
| `LightningState` | Triggered one-shot lightning flash |

## Lua API Summary

The full API reference is in `docs/API/overlay-design.md`.

Factory: `luna.overlay.newOverlay(width?, height?) → Overlay`

Key method groups on an `Overlay` userdata:
- **Lifecycle**: `update(dt)`, `draw()`, `resize(w, h)`, `clear()`, `isActive()`
- **Ambient**: `setAmbientEnabled(b)`, `setTimeOfDay(h)`, `setAmbientColor(r,g,b,a?)`
- **Weather**: `setWeather(type)`, `setWeatherIntensity(n)`, `setWindDirection(r)`, `setWindSpeed(s)`
- **Screen effects**: `flash(r,g,b,a?,dur?)`, `shake(intensity,dur?)`, `fade(r,g,b,alpha?,dur?)`
- **Shake camera**: `getShakeOffset() → x, y`
- **Clouds**: `setCloudShadows(b)`, `setCloudCount(n)`, `setCloudSpeed(s)`, `setCloudOpacity(o)`
- **Fog**: `setFogEnabled(b)`, `setFogDensity(d)`, `setFogColor(r,g,b,a?)`
- **Heat haze**: `setHeatHazeEnabled(b)`, `setHeatHazeIntensity(n)`
- **Vignette**: `setVignetteEnabled(b)`, `setVignetteStrength(s)`
- **Film grain**: `setFilmGrainEnabled(b)`, `setFilmGrainIntensity(n)`
- **Lightning**: `triggerLightning()`, `setLightningColor(r,g,b,a?)`

## Testing

- `tests/unit/overlay_tests.rs` — 78 Rust integration tests covering construction, every subsystem setter/getter, particle simulation, ambient color computation, sequence of update steps, and edge cases (zero dt, immediate triggers)
- `tests/lua/unit/test_overlay.lua` — 59 BDD tests covering factory, all Lua getters and setters, effect sequencing in Lua, and is_active combinations
- Run with: `cargo test overlay`

## Module Boundaries

- **May import**: `math`, `engine` (Tier 2 — Engine Extension)
- **Must NOT import**: other Tier 2 modules, `lua_api`
- This module is a pure CPU data model; GPU rendering is handled exclusively in `src/lua_api/overlay_api.rs`
