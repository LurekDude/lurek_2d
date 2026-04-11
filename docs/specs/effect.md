# `effect` — Agent Reference

| Property       | Value                                               |
|----------------|-----------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extensions                          |
| **Status**     | Implemented — Full                                  |
| **Lua API**    | `lurek.overlay` / `lurek.postfx`                         |
| **Source**      | `src/render/effect/`                                    |
| **Rust Tests** | `tests/rust/unit/fx_tests.rs`                       |
| **Lua Tests**  | —                                                   |
| **Architecture** | —                                                 |

## Summary

The `effect` module is a Tier 2 Engine Extension that provides composable visual effects as
pure CPU data models. It contains no wgpu code and no GPU resource handles — all rendering
is performed by the `lua_api` bridge layer, which reads the data models each frame.

The module is split into two families that address different categories of visual feedback:

**Post-processing effects** (image-space pipeline): `PostFxEffectType` enumerates 16 built-in
shader pass kinds (bloom, blur, CRT, chromatic aberration, colour grading, sepia, grayscale,
invert, scanlines, edge detection, hue shift, noise, godrays, vignette, pixelate) plus a
`Custom` variant for user-provided shaders. `PostFxEffect` is the per-effect parameter bag
stored as a `HashMap<String, f32>` so new shader uniforms can be added without changing the
struct layout. `PostFxStack` is an ordered pipeline of effect indices with per-slot enable
flags and ping-pong canvas dimensions; Lua calls `beginCapture()` then draws then `endCapture()`
then `apply()` each frame. `ImageEffect` is a lighter-weight per-image effect chain that
converts its entries to `ShaderPassDescriptor` values for embedding into `RenderCommand` variants.

**Screen overlays** (world-simulation effects): `Overlay` aggregates twelve independently
toggled subsystems — ambient lighting with time-of-day colour cycling (`AmbientState`),
weather particle simulation (`WeatherState` with 8 particle types), cloud shadow scrolling
(`CloudState`), atmospheric fog (`FogState`), heat haze distortion (`HeatHazeState`), vignette
darkening (`VignetteState`), film grain noise (`FilmGrainState`), lightning flash
(`LightningState`), and three one-shot screen effects: flash (`FlashState`), shake
(`ShakeState`), and fade (`FadeState`). All subsystems start inactive and are advanced by a
single `Overlay::update(dt)` call each frame.

**Scope boundary**: `effect` models effect state only.


## Architecture

```
lurek.effect (Lua)
    |
    v
src/lua_api/effect_api.rs          <-- bridge: wraps data models as UserData
    |
    v
src/effect/ (Tier 2 data models)
    |
    +-- Post-processing pipeline ------------------------------------------
    |   +-- effect_type.rs       PostFxEffectType enum (16 built-in + Custom)
    |   +-- effect.rs            PostFxEffect — parameter bag per shader pass
    |   +-- stack.rs             PostFxStack — ordered pipeline with enable flags
    |   +-- image_effect.rs      ImageEffect — per-image effect chain -> ShaderPassDescriptor
    |
    +-- Screen overlays ---------------------------------------------------
        +-- ambient.rs           AmbientState — time-of-day colour cycling
        +-- atmosphere.rs        CloudState, FogState, HeatHazeState,
        |                        VignetteState, FilmGrainState, LightningState
        +-- screen_effects.rs    FlashState, ShakeState, FadeState
        +-- weather.rs           WeatherType, WeatherParticle, WeatherState
        +-- overlay.rs           Overlay — aggregates all overlay subsystems
```

## Source Files

| File | Purpose |
|------|---------|
| `ambient.rs` | Ambient lighting state with time-of-day colour cycling (night to dawn to day to dusk). Provides `AmbientState` with `compute_color_from_time()`. |
| `atmosphere.rs` | Data-only structs for atmospheric effects: `CloudState` (scrolling shadow blobs), `FogState` (uniform translucent tint), `HeatHazeState` (sine-wave UV distortion), `VignetteState` (radial edge darkening), `FilmGrainState` (per-pixel noise), `LightningState` (single-shot hard flash). |
| `effect.rs` | `PostFxEffect` — a single post-processing shader pass with a `HashMap<String, f32>` parameter bag, builder helpers, and type introspection. |
| `effect_type.rs` | `PostFxEffectType` enum — 16 built-in effect kinds plus `Custom`. Provides `from_name`/`name` round-trip parsing and `default_params()` preset maps. |
| `image_effect.rs` | `ImageEffect` — an ordered chain of `Rc<RefCell<PostFxEffect>>` entries. Converts to `Vec<ShaderPassDescriptor>` via `to_passes()` for embedding into `RenderCommand` variants. Imports from `crate::graphics` (Tier 1). |
| `overlay.rs` | `Overlay` — aggregates all 12 screen-effect subsystems. `update(dt)` advances ambient, weather, flash, shake, fade, clouds, and lightning. Trigger methods for flash, shake, fade, and lightning. Query methods for shake offset and flash/lightning alpha. |
| `screen_effects.rs` | Three one-shot screen effects: `FlashState` (colour burst fading to transparent), `ShakeState` (decaying xorshift PRNG pixel offset), `FadeState` (alpha interpolation between start and target). |
| `stack.rs` | `PostFxStack` — ordered chain of effect indices with parallel `enabled` flags. Manages ping-pong canvas dimensions. 1-based position insertion, per-index enable/disable, and `enabled_effects()` for the GPU layer. |
| `weather.rs` | `WeatherType` enum (8 variants: None, Rain, Snow, Hail, Dust, Leaves, Ash, Pollen), `WeatherParticle` (position, velocity, size, alpha), and `WeatherState` (spawn timer, wind, intensity, live particle pool). |

## Submodules

### `fx::ambient`

Ambient lighting state with time-of-day colour cycling. Provides `AmbientState` for gradual ambient colour transitions driven by an in-game clock.

- **`AmbientState`** (struct): Time-of-day ambient lighting controller with `enabled`, `color`, and `time_of_day` fields; auto-computes colour via a five-segment curve (night/dawn/day/dusk/night).

### `fx::atmosphere`

Atmospheric visual effects data models. Contains data-only structs for clouds, fog, vignette, lightning, film grain, and heat haze — all consumed by the overlay renderer.

- **`CloudState`** (struct): Scrolling cloud shadow overlay with `count`, `speed`, `scale`, `opacity`, and internal `offset` accumulator.
- **`FogState`** (struct): Uniform translucent colour rectangle simulating atmospheric haze with `density` (0.0–1.0) and `color` fields.
- **`HeatHazeState`** (struct): UV-space shimmer distortion with `intensity` controlling peak displacement in pixels.
- **`VignetteState`** (struct): Radial screen-edge darkening with `strength` (0.0–1.0).
- **`FilmGrainState`** (struct): Randomised per-pixel luminance noise overlay with `intensity` (0.0–1.0) controlling grain amplitude.
- **`LightningState`** (struct): Single-shot hard flash (default 0.15 s) with `active`, `color`, `elapsed`, and `duration` fields.

### `fx::effect`

Post-processing effect data model. Defines `PostFxEffect` — a single named effect with typed parameters for the post-processing pipeline.

- **`PostFxEffect`** (struct): Parameter bag for one shader pass with `effect_type`, `params` (HashMap), `enabled` flag, and optional `shader_id` for custom shaders. Constructor, parameter get/set/has/list, type introspection, and disabled-start builder.

### `fx::effect_type`

Built-in post-processing effect type definitions. Enumerates all shader passes recognised by the engine's post-processing pipeline and provides parameter presets for each.

- **`PostFxEffectType`** (enum): 16 built-in effect variants (Bloom, Blur, Crt, Godrays, Vignette, ColourGrade, Chromatic, Pixelate, Sepia, Grayscale, Invert, Scanlines, EdgeDetect, HueShift, Noise) plus `Custom`. Provides `from_name`/`name` round-trip and `default_params()`.

### `fx::image_effect`

Per-image effect chain. Groups one or more `PostFxEffect` entries and converts them to lightweight `ShaderPassDescriptor` values via `to_passes()`. Imports from `crate::graphics` (Tier 1).

- **`ImageEffect`** (struct): Ordered chain of `Rc<RefCell<PostFxEffect>>` with add, remove (by index or name), clear, count, and `to_passes()` conversion.

### `fx::overlay`

Composable per-frame overlay system. `Overlay` aggregates ambient, atmospheric, weather, and screen effect sub-states and ticks them each frame.

- **`Overlay`** (struct): Top-level controller aggregating 12 subsystems (weather, ambient, flash, shake, fade, clouds, fog, heat_haze, vignette, film_grain, lightning). Trigger, query, update, resize, clear, and `is_active` methods.

### `fx::screen_effects`

Full-screen transient effects. Provides `FlashState`, `FadeState`, and `ShakeState` for brief screen-wide visual feedback.

- **`FlashState`** (struct): Colour burst that fades linearly from initial alpha to zero over `duration` seconds.
- **`ShakeState`** (struct): Camera-shake with decaying xorshift PRNG offsets (`offset_x`, `offset_y`) scaled by `intensity` and linear decay.
- **`FadeState`** (struct): Full-screen colour fade interpolating `color[3]` from `start_alpha` to `target_alpha` over `duration` seconds.

### `fx::stack`

Post-processing effect stack. `PostFxStack` manages an ordered chain of effect indices with parallel enable flags and internal canvas dimensions.

- **`PostFxStack`** (struct): Ordered `Vec<usize>` of effect indices with parallel `Vec<bool>` enable flags. Canvas dimensions for ping-pong rendering. Add, remove, insert (1-based), enable/disable, query, resize, and clear operations.

### `fx::weather`

Weather particle system data. Defines `WeatherType`, `WeatherParticle`, and `WeatherState`.

- **`WeatherParticle`** (struct): Single particle with position (`x`, `y`), velocity (`vx`, `vy`), `size`, and `alpha`.
- **`WeatherState`** (struct): Weather subsystem state with `weather_type`, `intensity`, wind direction/speed, live `particles` pool, and internal `spawn_timer`.
- **`WeatherType`** (enum): 8 variants — None, Rain, Snow, Hail, Dust, Leaves, Ash, Pollen. Each variant tunes particle speed, size, and opacity via `Overlay::spawn_particle`.

## Key Types

### Structs

#### `fx::ambient::AmbientState`

Ambient lighting state with time-of-day colour cycling. When `enabled` is `true`, `Overlay::update` calls `compute_color_from_time()` each frame, overwriting `color` with a five-segment curve: night (0–5h, dark blue) to dawn (5–7h) to day (7–17h) to dusk (17–19h) to night (19–24h). To set the tint manually, disable cycling and write directly to `color`. Fields: `enabled: bool`, `color: [f32; 4]`, `time_of_day: f32`. Key method: `compute_color_from_time() -> [f32; 4]`.

#### `fx::atmosphere::CloudState`

Cloud shadow overlay state. Renders `count` soft shadow blobs drifting horizontally at `speed` px/s. `offset` is an internal scroll accumulator advanced each frame; the renderer wraps it modulo screen width. Fields: `enabled`, `count: u32`, `speed: f32`, `scale: f32`, `opacity: f32`, `offset: f32`. Default: 5 blobs, speed 20, scale 1.0, opacity 0.3.

#### `fx::atmosphere::FogState`

Atmospheric fog as a uniform translucent colour rectangle. `density` maps linearly to blend alpha (1.0 = solid `color`, 0.0 = invisible). No distance-based depth fog. Fields: `enabled`, `density: f32`, `color: [f32; 4]`. Default: density 0.3, grey-blue tint.

#### `fx::atmosphere::HeatHazeState`

UV-space shimmer distortion driven by a sine wave. `intensity` scales peak UV offset in screen-space pixels (typical 0.2–2.0 for subtle mirage, higher for extreme distortion). GPU layer animates sine phase from game time. Fields: `enabled`, `intensity: f32`. Default: intensity 0.5.

#### `fx::atmosphere::VignetteState`

Radial darkening from transparent centre to opaque-black corners. `strength` controls aggressiveness (0.0 = none, 0.5 = film-like, 1.0 = near-black corners). Fields: `enabled`, `strength: f32`. Default: strength 0.5.

#### `fx::atmosphere::FilmGrainState`

Per-pixel luminance noise overlay. Noise pattern is regenerated every frame by the GPU layer. `intensity` scales peak amplitude (0.1–0.3 subtle, >0.5 heavy). Fields: `enabled`, `intensity: f32`. Default: intensity 0.3.

#### `fx::atmosphere::LightningState`

Single-shot full-screen hard flash (distinct from `FlashState`) with very short default duration (0.15 s). Triggered by `Overlay::trigger_lightning`; deactivates when `elapsed >= duration`. Fields: `active`, `color: [f32; 4]`, `elapsed: f32`, `duration: f32`. Default: pale blue-white (0.9, 0.9, 1.0, 0.8).

#### `fx::effect::PostFxEffect`

A single post-processing effect with named float parameters stored in `HashMap<String, f32>`. Acts as a parameter bag describing one shader pass — holds no GPU resource. Constructors: `new(effect_type)` (built-in with defaults), `new_custom(shader_id)`, `new_disabled(effect_type)`. Parameter access: `set_parameter`, `get_parameter`, `has_parameter`, `get_parameter_names`. Introspection: `get_type_name`, `is_built_in`. Fields: `effect_type`, `params`, `enabled`, `shader_id`.

#### `fx::image_effect::ImageEffect`

Ordered chain of `Rc<RefCell<PostFxEffect>>` entries for per-image draw calls. Effects are applied in insertion order through each enabled pass. `to_passes()` converts the chain to `Vec<ShaderPassDescriptor>` for embedding into `RenderCommand` variants. Methods: `new(name)`, `add_effect`, `get_effect_by_index`, `get_effect_by_name`, `remove_by_index`, `remove_by_name`, `clear`, `effect_count`, `to_passes`.

#### `fx::overlay::Overlay`

Top-level per-frame overlay controller aggregating 12 visual subsystems: `weather`, `ambient`, `flash`, `shake`, `fade`, `clouds`, `fog`, `heat_haze`, `vignette`, `film_grain`, `lightning`, plus `width`/`height` for particle bounds. All subsystems start inactive. `update(dt)` advances all active subsystems. Trigger methods: `trigger_flash`, `trigger_shake`, `trigger_fade`, `trigger_lightning`. Query methods: `get_shake_offset`, `get_flash_alpha`, `get_lightning_alpha`, `is_active`. Lifecycle: `clear`, `resize`, dimension getters.

#### `fx::screen_effects::FlashState`

Colour burst overlay fading linearly from `color[3]` to zero over `duration` seconds. Read-back via `Overlay::get_flash_alpha()`. Calling `trigger_flash` while active restarts from the new colour. Fields: `active`, `color: [f32; 4]`, `duration: f32`, `elapsed: f32`. Default: white, 0.2 s.

#### `fx::screen_effects::ShakeState`

Camera-shake with per-frame pixel offsets generated by a xorshift PRNG. Intensity decays linearly over `duration`. Fields: `active`, `intensity: f32`, `duration: f32`, `elapsed: f32`, `offset_x: f32`, `offset_y: f32`, `seed: u32` (private). Default: intensity 5.0 px, duration 0.5 s. Internal method: `next_random() -> f32` (pub(crate)).

#### `fx::screen_effects::FadeState`

Full-screen alpha fade interpolating `color[3]` from `start_alpha` to `target_alpha` over `duration` seconds. `start_alpha` is captured automatically from the current alpha when `trigger_fade` is called, enabling seamless chained fades. Fields: `active`, `color: [f32; 4]`, `target_alpha: f32`, `duration: f32`, `elapsed: f32`, `start_alpha: f32`. Default: black, 1.0 s.

#### `fx::stack::PostFxStack`

Ordered pipeline of post-processing effect indices with per-slot enable flags and internal canvas dimensions. Uses `beginCapture -> draw -> endCapture -> apply` lifecycle in Lua. Effects are referenced by `usize` indices into external storage. Methods: `new(w, h)`, `add`, `remove`, `insert` (1-based), `set_enabled`, `is_enabled`, `get_effect_count`, `get_effect` (1-based), `enabled_effects`, `resize`, dimension getters, `len`, `is_empty`, `clear`. Fields: `effects: Vec<usize>`, `enabled: Vec<bool>`, `width`, `height`, `capturing`.

#### `fx::weather::WeatherParticle`

A single weather particle in the overlay system. Created by `Overlay::spawn_particle`, moved each frame by `update_weather`, and culled when off-screen. Fields: `x`, `y`, `vx`, `vy`, `size`, `alpha` (all `f32`).

#### `fx::weather::WeatherState`

Weather subsystem state controlling particle simulation. `intensity` (0.0–1.0) scales max particle count (up to 200) and spawn rate. Wind adds a global velocity offset to all particles. Fields: `enabled`, `weather_type: WeatherType`, `intensity: f32`, `wind_direction: f32`, `wind_speed: f32`, `particles: Vec<WeatherParticle>`, `spawn_timer: f32` (internal).

### Enums

#### `fx::effect_type::PostFxEffectType`

Built-in effect types for the post-processing pipeline. 16 shader pass variants: Bloom (threshold + intensity), Blur (radius + strength), Crt (scanline strength), Godrays (intensity), Vignette (strength), ColourGrade (brightness + contrast + saturation), Chromatic (offset), Pixelate (block size), Sepia (strength), Grayscale (strength), Invert (strength), Scanlines (strength + spacing), EdgeDetect (strength), HueShift (angle), Noise (strength), Custom (external shader). Methods: `from_name(&str) -> Option<Self>`, `name() -> &'static str`, `default_params() -> HashMap<String, f32>`.

#### `fx::weather::WeatherType`

Weather particle types: None, Rain (fast narrow streaks), Snow (slow large dots), Hail (very fast opaque pellets), Dust (slow small low-opacity motes), Leaves (medium large blobs), Ash (slow small flakes), Pollen (extremely slow tiny specks). Each variant tunes spawn velocity, size, and alpha. Methods: `from_name(&str) -> Option<Self>`, `name() -> &'static str`.

## Lua API

The full Lua-facing surface is registered in `src/lua_api/effect_api.rs` under the `lurek.effect` namespace. The module exposes five factory functions and four UserData types.

### Factory Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.effect.newEffect(type_name)` | `(string) -> PostFxEffect` | Creates a built-in post-processing effect by name (e.g. `"bloom"`, `"blur"`, `"crt"`). Errors on unknown names. |
| `lurek.effect.newCustomEffect(shader_id)` | `(integer) -> PostFxEffect` | Creates a custom shader post-processing effect referencing the given shader ID. |
| `lurek.effect.newStack(width, height)` | `(integer, integer) -> PostFxStack` | Creates a new post-processing pipeline stack with the given canvas dimensions. |
| `lurek.effect.newImageEffect(name)` | `(string) -> ImageEffect` | Creates a new per-image effect chain with the given label. |
| `lurek.effect.newOverlay(width, height)` | `(integer, integer) -> Overlay` | Creates a screen overlay controller for weather, flash, shake, fade, and atmospheric effects. |
| `lurek.fx.newPass(shader_name, params)` | Creates a new single-pass post-processing effect using the named shader with optional parameter table. |
| `lurek.fx.getEffectTypes()` | Returns a table listing all built-in post-processing effect type names available. |

### PostFxEffect Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `:getTypeName()` | `() -> string` | Returns the display name of this effect type. |
| `:isBuiltIn()` | `() -> boolean` | Returns `true` if this is a built-in effect, `false` if custom. |
| `:isEnabled()` | `() -> boolean` | Returns whether this effect is currently active. |
| `:setEnabled(enabled)` | `(boolean) -> nil` | Enables or disables this effect. |
| `:setParameter(name, value)` | `(string, number) -> nil` | Sets a named float parameter. |
| `:getParameter(name, default)` | `(string, number) -> number` | Returns a parameter value, or `default` if not set. |
| `:hasParameter(name)` | `(string) -> boolean` | Returns `true` if the named parameter exists. |
| `:getParameterNames()` | `() -> table` | Returns a sorted list of all parameter names. |

### PostFxStack Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `:add(effect_idx)` | `(integer) -> nil` | Appends an effect index to the end of the pipeline. |
| `:remove(effect_idx)` | `(integer) -> boolean` | Removes an effect index from the pipeline. |
| `:insert(position, effect_idx)` | `(integer, integer) -> nil` | Inserts an effect at a 1-based position. |
| `:setEnabled(effect_idx, enabled)` | `(integer, boolean) -> nil` | Enables or disables the effect at the given index. |
| `:isEnabled(effect_idx)` | `(integer) -> boolean` | Returns whether the effect at the given index is enabled. |
| `:getEffectCount()` | `() -> integer` | Returns the number of effects in the pipeline. |
| `:getEffect(index)` | `(integer) -> integer?` | Returns the effect index at the given 1-based position, or nil. |
| `:getEnabledEffects()` | `() -> table` | Returns a list of currently enabled effect indices. |
| `:getWidth()` | `() -> integer` | Returns the canvas width. |
| `:getHeight()` | `() -> integer` | Returns the canvas height. |
| `:getDimensions()` | `() -> integer, integer` | Returns canvas width and height. |
| `:resize(width, height)` | `(integer, integer) -> nil` | Resizes the internal canvas dimensions. |
| `:len()` | `() -> integer` | Returns the total number of effect slots. |
| `:isEmpty()` | `() -> boolean` | Returns `true` if the pipeline is empty. |
| `:clear()` | `() -> nil` | Removes all effects from the pipeline. |

### ImageEffect Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `:addEffect(effect)` | `(PostFxEffect) -> nil` | Appends a post-processing effect to the chain. |
| `:removeByIndex(idx)` | `(integer) -> boolean` | Removes the effect at the given 0-based index. |
| `:removeByName(name)` | `(string) -> boolean` | Removes the first effect matching the given type name. |
| `:clear()` | `() -> nil` | Removes all effects from the chain. |
| `:getEffectCount()` | `() -> integer` | Returns the number of effects in the chain. |

### Overlay Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `:update(dt)` | `(number) -> nil` | Advances all overlay subsystems by delta time. |
| `:triggerFlash(r, g, b, a, duration)` | `(number, number, number, number, number) -> nil` | Triggers a screen-wide colour flash. |
| `:triggerShake(intensity, duration)` | `(number, number) -> nil` | Triggers a screen shake effect. |
| `:triggerFade(r, g, b, target_alpha, duration)` | `(number, number, number, number, number) -> nil` | Triggers a screen fade to the given colour and alpha. |
| `:triggerLightning()` | `() -> nil` | Triggers a lightning flash effect. |
| `:getShakeOffset()` | `() -> number, number` | Returns current shake displacement (x, y). |
| `:isActive()` | `() -> boolean` | Returns `true` if any subsystem is active. |
| `:clear()` | `() -> nil` | Resets all subsystems to inactive defaults. |
| `:resize(width, height)` | `(integer, integer) -> nil` | Updates overlay dimensions for particle bounds. |
| `:getWidth()` | `() -> integer` | Returns the overlay width. |
| `:getHeight()` | `() -> integer` | Returns the overlay height. |
| `:getDimensions()` | `() -> integer, integer` | Returns overlay width and height. |
| `:getFlashAlpha()` | `() -> number` | Returns the current flash overlay alpha (0.0 when inactive). |
| `:getLightningAlpha()` | `() -> number` | Returns the current lightning overlay alpha (0.0 when inactive). |

## Lua Examples

```lua
-- Post-processing: apply bloom + CRT scanlines to the scene
local bloom = lurek.effect.newEffect("bloom")
bloom:setParameter("threshold", 0.6)
bloom:setParameter("intensity", 1.5)

local crt = lurek.effect.newEffect("crt")
crt:setParameter("scanline_strength", 0.4)

local stack = lurek.effect.newStack(800, 600)
stack:add(0)  -- bloom at index 0
stack:add(1)  -- crt at index 1

function lurek.render()
    -- stack:beginCapture()
    -- ... draw scene ...
    -- stack:endCapture()
    -- stack:apply()
end
```

```lua
-- Screen overlay: weather + flash + shake
local overlay = lurek.effect.newOverlay(800, 600)

function lurek.process(dt)
    overlay:update(dt)

    -- Trigger a white flash on spacebar
    if lurek.keyboard.isDown("space") then
        overlay:triggerFlash(1, 1, 1, 1, 0.3)
    end

    -- Trigger shake on impact
    if lurek.keyboard.isDown("x") then
        overlay:triggerShake(8.0, 0.4)
    end
end

function lurek.render()
    -- Apply shake offset to camera
    local sx, sy = overlay:getShakeOffset()
    lurek.graphic.translate(sx, sy)

    -- ... draw scene ...

    -- Draw flash overlay
    local flashAlpha = overlay:getFlashAlpha()
    if flashAlpha > 0 then
        lurek.graphic.setColor(1, 1, 1, flashAlpha)
        lurek.graphic.rectangle("fill", 0, 0, 800, 600)
    end
end
```

## Item Summary

| Kind       | Count  |
|------------|--------|
| `struct`   | 16     |
| `enum`     | 2      |
| `fn`       | 57     |
| **Total**  | **75** |

## References

| Module          | Relationship | Notes                                                       |
|-----------------|--------------|-------------------------------------------------------------|
| `math`          | Imports from | Uses float arithmetic; no direct type imports               |
| `engine`        | Imports from | Uses `log_messages` constants for structured logging        |
| `graphic`      | Imports from | `image_effect.rs` imports `ShaderPassDescriptor` (Tier 1)   |
| `lua_api`       | Imported by  | `effect_api.rs` wraps all data models as Lua UserData           |
| `overlay`       | Similar to   | Legacy `src/overlay/` was the predecessor; `fx::overlay` subsumes its role with richer subsystems |
| `postfx`        | Similar to   | Legacy `src/postfx/` was the predecessor; `effect` combines post-processing and overlays in one module |

## Notes

- **No GPU code**: `effect` is a pure data-model module. All wgpu rendering, shader compilation, and canvas management for post-processing and overlays happens in `lua_api/effect_api.rs` and the graphics pipeline. Never add `wgpu` imports to `effect`.
- **Tier 2 import rule**: `effect` may import from `math`, `engine`, and Tier 1 modules (currently only `graphics::ShaderPassDescriptor`). It must not import other Tier 2 modules.
- **HashMap parameters**: `PostFxEffect` uses `HashMap<String, f32>` for shader uniforms. This is intentional — it decouples the data model from specific shader implementations and supports round-trip serialisation. Unknown parameter keys are silently ignored by the GPU layer.
- **Weather particle cap**: `WeatherState` caps live particles at `intensity * 200`. High-intensity weather (`intensity > 0.8`) can produce up to 200 particles per frame. The spawner uses a hash-based pseudo-random for deterministic-ish placement.
- **Overlay update order**: `Overlay::update(dt)` processes subsystems in a fixed order: ambient, weather, flash, shake, fade, clouds, lightning. Inactive subsystems incur only a branch-check overhead.
- **Shake PRNG**: `ShakeState` uses a simple xorshift32 PRNG (seeded at 12345) for deterministic shake sequences. The PRNG is not thread-safe but does not need to be — Lua VM is single-threaded.
- **No Lua BDD tests**: There are currently no Lua-side tests for `lurek.effect`. Rust-side coverage exists in `tests/rust/unit/fx_tests.rs` (27 tests covering effect types, stack operations, overlay defaults, and weather round-trips).
- **Breaking change surface**: Renaming `PostFxEffectType` variant string names (e.g. `"bloom"` to `"glow"`) would break all Lua scripts using `lurek.effect.newEffect()`. The `from_name`/`name` round-trip is a public API contract.
