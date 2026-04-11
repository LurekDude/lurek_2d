# `effect` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Engine Extensions |
| **Status** | Implemented — Full |
| **Lua API** | `lurek.overlay` / `lurek.postfx` (aliased to the same table) |
| **Source** | `src/effect/` |
| **Lua API File** | `src/lua_api/effect_api.rs` |
| **Rust Tests** | `tests/rust/unit/fx_tests.rs` |
| **Lua Tests** | — |
| **Architecture** | — |

## Summary

The `effect` module is Lurek2D's composable visual effects layer. It provides two families of
effects — post-processing image-space pipelines and screen-space overlays — as pure CPU data
models. The module contains **no wgpu code and no GPU resource handles**; all rendering is
performed by the `lua_api` bridge layer which reads the data models each frame.

**Post-processing effects** (image-space pipeline): `PostFxEffectType` enumerates 16 built-in
shader pass kinds (bloom, blur, CRT, chromatic aberration, colour grading, sepia, grayscale,
invert, scanlines, edge detection, hue shift, noise, godrays, vignette, pixelate) plus a
`Custom` variant for user-provided shaders. `PostFxEffect` is the per-effect parameter bag
stored as a `HashMap<String, f32>` so new shader uniforms can be added without changing the
struct layout. `PostFxStack` is an ordered pipeline of effect indices with per-slot enable
flags and ping-pong canvas dimensions. `ImageEffect` is a lighter-weight per-image effect
chain that converts its entries to `ShaderPassDescriptor` values for embedding into
`RenderCommand` variants.

**Screen overlays** (world-simulation effects): `Overlay` aggregates twelve independently
toggled subsystems — ambient lighting with time-of-day colour cycling (`AmbientState`),
weather particle simulation (`WeatherState` with 8 particle types), cloud shadow scrolling
(`CloudState`), atmospheric fog (`FogState`), heat haze distortion (`HeatHazeState`), vignette
darkening (`VignetteState`), film grain noise (`FilmGrainState`), lightning flash
(`LightningState`), and three one-shot screen effects: flash (`FlashState`), shake
(`ShakeState`), and fade (`FadeState`). All subsystems start inactive and are advanced by a
single `Overlay::update(dt)` call each frame.

**Scope boundary**: `effect` models effect state only. It has no GPU, audio, window,
filesystem, or physics dependencies. It depends only on `math` and `runtime` (Baseline).
`image_effect.rs` imports `ShaderPassDescriptor` from the render module (Tier 1).

## Architecture

```
lurek.overlay / lurek.postfx  (Lua API)
    │
    ▼
src/lua_api/effect_api.rs          ← bridge: wraps data models as UserData
    │
    ▼
src/effect/mod.rs  (re-exports all submodules)
    │
    ├── Post-processing pipeline ────────────────────────────────
    │   ├── effect_type.rs      PostFxEffectType enum (16 built-in + Custom)
    │   ├── effect.rs           PostFxEffect — parameter bag per shader pass
    │   ├── stack.rs            PostFxStack — ordered pipeline with enable flags
    │   └── image_effect.rs     ImageEffect — per-image effect chain → ShaderPassDescriptor
    │
    └── Screen overlays ─────────────────────────────────────────
        ├── ambient.rs          AmbientState — time-of-day colour cycling
        ├── atmosphere.rs       CloudState, FogState, HeatHazeState,
        │                       VignetteState, FilmGrainState, LightningState
        ├── screen_effects.rs   FlashState, ShakeState, FadeState
        ├── overlay.rs          Overlay — aggregates all overlay subsystems
        └── weather.rs          WeatherType, WeatherParticle, WeatherState
```

## Source Files

| File | Purpose |
|------|---------|
| `ambient.rs` | Ambient lighting state with time-of-day colour cycling (night → dawn → day → dusk). Provides `AmbientState` with `compute_color_from_time()`. |
| `atmosphere.rs` | Data-only structs for atmospheric effects: `CloudState` (scrolling shadow blobs), `FogState` (uniform translucent tint), `HeatHazeState` (sine-wave UV distortion), `VignetteState` (radial edge darkening), `FilmGrainState` (per-pixel noise), `LightningState` (single-shot hard flash). |
| `effect.rs` | `PostFxEffect` — a single post-processing shader pass with a `HashMap<String, f32>` parameter bag, builder helpers, and type introspection. |
| `effect_type.rs` | `PostFxEffectType` enum — 16 built-in effect kinds plus `Custom`. Provides `from_name`/`name` round-trip parsing and `default_params()` preset maps. |
| `image_effect.rs` | `ImageEffect` — an ordered chain of `Rc<RefCell<PostFxEffect>>` entries. Converts to `Vec<ShaderPassDescriptor>` via `to_passes()` for embedding into `RenderCommand` variants. |
| `mod.rs` | Module root — re-exports all submodules. |
| `overlay.rs` | `Overlay` — aggregates all 12 screen-effect subsystems. `update(dt)` advances ambient, weather, flash, shake, fade, clouds, and lightning. Trigger and query methods. |
| `screen_effects.rs` | Three one-shot screen effects: `FlashState` (colour burst fading to transparent), `ShakeState` (decaying xorshift PRNG pixel offset), `FadeState` (alpha interpolation between start and target). |
| `stack.rs` | `PostFxStack` — ordered chain of effect indices with parallel `enabled` flags. Manages ping-pong canvas dimensions. 1-based position insertion, per-index enable/disable, and `enabled_effects()` for the GPU layer. |
| `weather.rs` | `WeatherType` enum (8 variants: None, Rain, Snow, Hail, Dust, Leaves, Ash, Pollen), `WeatherParticle` (position, velocity, size, alpha), and `WeatherState` (spawn timer, wind, intensity, live particle pool). |

## Submodules

### `effect::ambient`

Ambient lighting state with time-of-day colour cycling. Provides `AmbientState` for gradual
ambient colour transitions driven by an in-game clock.

- **`AmbientState`** (struct): Time-of-day ambient lighting controller with `enabled`, `color`, and `time_of_day` fields; auto-computes colour via a five-segment curve (night/dawn/day/dusk/night).

### `effect::atmosphere`

Atmospheric visual effects data models. Contains data-only structs for clouds, fog, vignette,
lightning, film grain, and heat haze — all consumed by the overlay renderer.

- **`CloudState`** (struct): Scrolling cloud shadow overlay with `count`, `speed`, `scale`, `opacity`, and internal `offset` accumulator.
- **`FogState`** (struct): Uniform translucent colour rectangle simulating atmospheric haze with `density` (0.0–1.0) and `color` fields.
- **`HeatHazeState`** (struct): UV-space shimmer distortion with `intensity` controlling peak displacement in pixels.
- **`VignetteState`** (struct): Radial screen-edge darkening with `strength` (0.0–1.0).
- **`FilmGrainState`** (struct): Randomised per-pixel luminance noise overlay with `intensity` (0.0–1.0) controlling grain amplitude.
- **`LightningState`** (struct): Single-shot full-screen hard flash (default 0.15 s) with `active`, `color`, `elapsed`, and `duration` fields.

### `effect::effect`

Post-processing effect data model. Defines `PostFxEffect` — a single named effect with typed
parameters for the post-processing pipeline.

- **`PostFxEffect`** (struct): Parameter bag for one shader pass with `effect_type`, `params` (HashMap), `enabled` flag, and optional `shader_id` for custom shaders. Constructor, parameter get/set/has/list, type introspection, and disabled-start builder.

### `effect::effect_type`

Built-in post-processing effect type definitions. Enumerates all shader passes recognised by
the engine's post-processing pipeline and provides parameter presets for each.

- **`PostFxEffectType`** (enum): 16 built-in effect variants (Bloom, Blur, Crt, Godrays, Vignette, ColourGrade, Chromatic, Pixelate, Sepia, Grayscale, Invert, Scanlines, EdgeDetect, HueShift, Noise) plus `Custom`. Provides `from_name`/`name` round-trip and `default_params()`.

### `effect::image_effect`

Per-image effect chain. Groups one or more `PostFxEffect` entries and converts them to
lightweight `ShaderPassDescriptor` values via `to_passes()`.

- **`ImageEffect`** (struct): Ordered chain of `Rc<RefCell<PostFxEffect>>` with add, remove (by index or name), clear, count, and `to_passes()` conversion.

### `effect::overlay`

Composable per-frame overlay system. `Overlay` aggregates ambient, atmospheric, weather, and
screen effect sub-states and ticks them each frame.

- **`Overlay`** (struct): Top-level controller aggregating 12 subsystems (weather, ambient, flash, shake, fade, clouds, fog, heat_haze, vignette, film_grain, lightning). Trigger, query, update, resize, clear, and `is_active` methods.

### `effect::screen_effects`

Full-screen transient effects. Provides `FlashState`, `FadeState`, and `ShakeState` for brief
screen-wide visual feedback.

- **`FlashState`** (struct): Colour burst that fades linearly from initial alpha to zero over `duration` seconds.
- **`ShakeState`** (struct): Camera-shake with decaying xorshift PRNG offsets (`offset_x`, `offset_y`) scaled by `intensity` and linear decay.
- **`FadeState`** (struct): Full-screen colour fade interpolating `color[3]` from `start_alpha` to `target_alpha` over `duration` seconds.

### `effect::stack`

Post-processing effect stack. `PostFxStack` manages an ordered chain of effect indices with
parallel enable flags and internal canvas dimensions.

- **`PostFxStack`** (struct): Ordered `Vec<usize>` of effect indices with parallel `Vec<bool>` enable flags. Canvas dimensions for ping-pong rendering. Add, remove, insert (1-based), enable/disable, query, resize, and clear operations.

### `effect::weather`

Weather particle system data. Defines `WeatherType`, `WeatherParticle`, and `WeatherState`.

- **`WeatherParticle`** (struct): Single particle with position (`x`, `y`), velocity (`vx`, `vy`), `size`, and `alpha`.
- **`WeatherState`** (struct): Weather subsystem state with `weather_type`, `intensity`, wind direction/speed, live `particles` pool, and internal `spawn_timer`.
- **`WeatherType`** (enum): 8 variants — None, Rain, Snow, Hail, Dust, Leaves, Ash, Pollen. Each variant tunes particle speed, size, and opacity via `Overlay::spawn_particle`.

## Key Types

### Structs

#### `effect::ambient::AmbientState`

Ambient lighting state with time-of-day colour cycling. When `enabled` is `true`,
`Overlay::update` calls `compute_color_from_time()` each frame, overwriting `color` with a
five-segment curve: night (0–5 h, dark blue) → dawn (5–7 h) → day (7–17 h) → dusk (17–19 h) →
night (19–24 h). To set the tint manually, disable cycling and write directly to `color`.
Fields: `enabled: bool`, `color: [f32; 4]`, `time_of_day: f32`.
Key method: `compute_color_from_time() -> [f32; 4]`.

#### `effect::atmosphere::CloudState`

Cloud shadow overlay state. Renders `count` soft shadow blobs drifting horizontally at `speed`
px/s. `offset` is an internal scroll accumulator advanced each frame; the renderer wraps it
modulo screen width. Fields: `enabled`, `count: u32`, `speed: f32`, `scale: f32`,
`opacity: f32`, `offset: f32`. Default: 5 blobs, speed 20, scale 1.0, opacity 0.3.

#### `effect::atmosphere::FogState`

Atmospheric fog as a uniform translucent colour rectangle. `density` maps linearly to blend
alpha (1.0 = solid `color`, 0.0 = invisible). No distance-based depth fog.
Fields: `enabled`, `density: f32`, `color: [f32; 4]`. Default: density 0.3, grey-blue tint.

#### `effect::atmosphere::HeatHazeState`

UV-space shimmer distortion driven by a sine wave. `intensity` scales peak UV offset in
screen-space pixels (typical 0.2–2.0 for subtle mirage, higher for extreme distortion). GPU
layer animates sine phase from game time.
Fields: `enabled`, `intensity: f32`. Default: intensity 0.5.

#### `effect::atmosphere::VignetteState`

Radial darkening from transparent centre to opaque-black corners. `strength` controls
aggressiveness (0.0 = none, 0.5 = film-like, 1.0 = near-black corners).
Fields: `enabled`, `strength: f32`. Default: strength 0.5.

#### `effect::atmosphere::FilmGrainState`

Per-pixel luminance noise overlay. Noise pattern is regenerated every frame by the GPU layer.
`intensity` scales peak amplitude (0.1–0.3 subtle, >0.5 heavy).
Fields: `enabled`, `intensity: f32`. Default: intensity 0.3.

#### `effect::atmosphere::LightningState`

Single-shot full-screen hard flash (distinct from `FlashState`) with very short default duration
(0.15 s). Triggered by `Overlay::trigger_lightning`; deactivates when `elapsed >= duration`.
Fields: `active`, `color: [f32; 4]`, `elapsed: f32`, `duration: f32`.
Default: pale blue-white (0.9, 0.9, 1.0, 0.8).

#### `effect::effect::PostFxEffect`

A single post-processing effect with named float parameters stored in `HashMap<String, f32>`.
Acts as a parameter bag describing one shader pass — holds no GPU resource.
Constructors: `new(effect_type)` (built-in with defaults), `new_custom(shader_id)`,
`new_disabled(effect_type)`.
Parameter access: `set_parameter`, `get_parameter`, `has_parameter`, `get_parameter_names`.
Introspection: `get_type_name`, `is_built_in`.
Fields: `effect_type`, `params`, `enabled`, `shader_id`.

#### `effect::image_effect::ImageEffect`

Ordered chain of `Rc<RefCell<PostFxEffect>>` entries for per-image draw calls. Effects are
applied in insertion order through each enabled pass. `to_passes()` converts the chain to
`Vec<ShaderPassDescriptor>` for embedding into `RenderCommand` variants.
Methods: `new(name)`, `add_effect`, `add_effect_rc`, `get_effect_by_index`,
`get_effect_by_name`, `remove_by_index`, `remove_by_name`, `clear`, `effect_count`, `to_passes`.

#### `effect::overlay::Overlay`

Top-level per-frame overlay controller aggregating 12 visual subsystems: `weather`, `ambient`,
`flash`, `shake`, `fade`, `clouds`, `fog`, `heat_haze`, `vignette`, `film_grain`, `lightning`,
plus `width`/`height` for particle bounds. All subsystems start inactive.
`update(dt)` advances all active subsystems. Trigger methods: `trigger_flash`, `trigger_shake`,
`trigger_fade`, `trigger_lightning`. Query methods: `get_shake_offset`, `get_flash_alpha`,
`get_lightning_alpha`, `is_active`. Lifecycle: `clear`, `resize`, `build_render_commands`,
`draw_state_to_image`, dimension getters.

#### `effect::screen_effects::FlashState`

Colour burst overlay fading linearly from `color[3]` to zero over `duration` seconds. Read-back
via `Overlay::get_flash_alpha()`. Calling `trigger_flash` while active restarts from the new
colour. Fields: `active`, `color: [f32; 4]`, `duration: f32`, `elapsed: f32`.
Default: white, 0.2 s.

#### `effect::screen_effects::ShakeState`

Camera-shake with per-frame pixel offsets generated by a xorshift PRNG. Intensity decays
linearly over `duration`. Fields: `active`, `intensity: f32`, `duration: f32`, `elapsed: f32`,
`offset_x: f32`, `offset_y: f32`, `seed: u32` (private). Default: intensity 5.0 px,
duration 0.5 s. Internal method: `next_random() -> f32` (pub(crate)).

#### `effect::screen_effects::FadeState`

Full-screen alpha fade interpolating `color[3]` from `start_alpha` to `target_alpha` over
`duration` seconds. `start_alpha` is captured automatically from the current alpha when
`trigger_fade` is called, enabling seamless chained fades.
Fields: `active`, `color: [f32; 4]`, `target_alpha: f32`, `duration: f32`, `elapsed: f32`,
`start_alpha: f32`. Default: black, 1.0 s.

#### `effect::stack::PostFxStack`

Ordered pipeline of post-processing effect indices with per-slot enable flags and internal
canvas dimensions. Effects are referenced by `usize` indices into external storage.
Methods: `new(w, h)`, `add`, `remove`, `insert` (1-based), `set_enabled`, `is_enabled`,
`get_effect_count`, `get_effect` (1-based), `enabled_effects`, `resize`, dimension getters,
`len`, `is_empty`, `clear`.
Fields: `effects: Vec<usize>`, `enabled: Vec<bool>`, `width`, `height`, `capturing`.

#### `effect::weather::WeatherParticle`

A single weather particle in the overlay system. Created by `Overlay::spawn_particle`, moved
each frame by `update_weather`, and culled when off-screen.
Fields: `x`, `y`, `vx`, `vy`, `size`, `alpha` (all `f32`).

#### `effect::weather::WeatherState`

Weather subsystem state controlling particle simulation. `intensity` (0.0–1.0) scales max
particle count (up to 200) and spawn rate. Wind adds a global velocity offset to all particles.
Fields: `enabled`, `weather_type: WeatherType`, `intensity: f32`, `wind_direction: f32`,
`wind_speed: f32`, `particles: Vec<WeatherParticle>`, `spawn_timer: f32` (internal).

### Enums

#### `effect::effect_type::PostFxEffectType`

Built-in effect types for the post-processing pipeline. 16 shader pass variants:
- **Bloom** — HDR bloom with `threshold` + `intensity` parameters.
- **Blur** — Gaussian blur with configurable `radius` and `strength`.
- **Crt** — CRT monitor simulation with `scanline_strength`.
- **Godrays** — Light ray screen-space effect with `intensity`.
- **Vignette** — Screen edge darkening with configurable `strength`.
- **ColourGrade** — Colour grading with `brightness`, `contrast`, and `saturation`.
- **Chromatic** — Chromatic aberration with pixel `offset`.
- **Pixelate** — Block pixelation effect with configurable `block_size`.
- **Sepia** — Warm sepia tone mapping with configurable `strength`.
- **Grayscale** — Desaturate to greyscale with configurable `strength`.
- **Invert** — Colour inversion with configurable `strength`.
- **Scanlines** — Horizontal scanline bars with `strength` and `spacing`.
- **EdgeDetect** — Sobel edge detection outline with configurable `strength`.
- **HueShift** — Hue rotation in degrees via `angle`.
- **Noise** — Random per-pixel noise with configurable `strength`.
- **Custom** — User-provided shader pass created via `newPass()` / `newCustomEffect()`.

Methods: `from_name(&str) -> Option<Self>`, `name() -> &'static str`,
`default_params() -> HashMap<String, f32>`.

#### `effect::weather::WeatherType`

Weather particle types:
- **None** — No weather particles.
- **Rain** — Fast narrow streaks.
- **Snow** — Slow large dots.
- **Hail** — Very fast opaque pellets.
- **Dust** — Slow small low-opacity motes.
- **Leaves** — Medium large blobs.
- **Ash** — Slow small flakes.
- **Pollen** — Extremely slow tiny specks.

Each variant tunes spawn velocity, size, and alpha.
Methods: `from_name(&str) -> Option<Self>`, `name() -> &'static str`.

## Lua API

Exposed under **`lurek.overlay`** and **`lurek.postfx`** (both alias the same table) by
`src/lua_api/effect_api.rs`. The API provides 7 module-level factory functions, plus 4 UserData
types with a total of 113 registered methods.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.overlay.newEffect(type_name)` | Creates a built-in post-processing effect by name (e.g. `"bloom"`, `"blur"`, `"crt"`). Returns a `PostFxEffect`. Errors on unknown names. |
| `lurek.overlay.newCustomEffect(shader_id)` | Creates a custom shader post-processing effect referencing the given shader ID. Returns a `PostFxEffect`. |
| `lurek.overlay.newStack(width?, height?)` | Creates a new post-processing pipeline stack. Dimensions default to window size when omitted. Returns a `PostFxStack`. |
| `lurek.overlay.newPass(shader_id)` | Alias for `newCustomEffect`. Creates a custom-shader post-processing effect. Returns a `PostFxEffect`. |
| `lurek.overlay.getEffectTypes()` | Returns a table listing all 15 built-in post-processing effect type name strings. |
| `lurek.overlay.newImageEffect(...)` | Creates a per-image effect chain. Accepts: no args (empty chain), `"name"` (single effect), `"name", {params}` (single with parameters), or `{{type="name",...}, ...}` (chain from table). Returns an `ImageEffect`. |
| `lurek.overlay.newOverlay(width?, height?)` | Creates a screen overlay controller for weather, flash, shake, fade, and atmospheric effects. Dimensions default to 800×600 when omitted. Returns an `Overlay`. |

### PostFxEffect Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `:getTypeName()` | `() -> string` | Returns the display name of this effect type. |
| `:isBuiltIn()` | `() -> boolean` | Returns `true` if this is a built-in effect, `false` if custom. |
| `:isEnabled()` | `() -> boolean` | Returns whether this effect is currently active. |
| `:setEnabled(enabled)` | `(boolean) -> nil` | Enables or disables this effect. |
| `:setParameter(name, value)` | `(string, number) -> nil` | Sets a named float parameter on this effect. |
| `:getParameter(name, default?)` | `(string, number?) -> number` | Returns a parameter value, or `default` (default 0.0) if not set. |
| `:hasParameter(name)` | `(string) -> boolean` | Returns `true` if the named parameter exists. |
| `:getParameterNames()` | `() -> table` | Returns a sorted list of all parameter names. |
| `:getEffectType()` | `() -> string` | Returns the type name of this effect (alias for `getTypeName`). |
| `:getType()` | `() -> string` | Returns the type name of this effect (alias for `getTypeName`). |
| `:type()` | `() -> string` | Returns the string `"PostFxEffect"`. |
| `:typeOf(name)` | `(string) -> boolean` | Returns `true` when `name` is `"PostFxEffect"` or `"Object"`. |
| `:setThreshold(value)` | `(number) -> nil` | Convenience setter: sets the `"threshold"` parameter. |
| `:setIntensity(value)` | `(number) -> nil` | Convenience setter: sets the `"intensity"` parameter. |
| `:setRadius(value)` | `(number) -> nil` | Convenience setter: sets the `"radius"` parameter. |
| `:setStrength(value)` | `(number) -> nil` | Convenience setter: sets the `"strength"` parameter. |
| `:setScanlineStrength(value)` | `(number) -> nil` | Convenience setter: sets the `"scanline_strength"` parameter. |
| `:setOffset(value)` | `(number) -> nil` | Convenience setter: sets the `"offset"` parameter. |
| `:setBrightness(value)` | `(number) -> nil` | Convenience setter: sets the `"brightness"` parameter. |
| `:setContrast(value)` | `(number) -> nil` | Convenience setter: sets the `"contrast"` parameter. |
| `:setSaturation(value)` | `(number) -> nil` | Convenience setter: sets the `"saturation"` parameter. |

### PostFxStack Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `:add(effect)` | `(PostFxEffect) -> nil` | Appends a `PostFxEffect` to the end of the pipeline. |
| `:remove(effect)` | `(PostFxEffect) -> boolean` | Removes the given `PostFxEffect` from the pipeline by identity. Returns `true` if found. |
| `:insert(position, effect)` | `(integer, PostFxEffect) -> nil` | Inserts a `PostFxEffect` at a 1-based position in the pipeline. |
| `:setEnabled(position, enabled)` | `(integer, boolean) -> nil` | Enables or disables the effect at the given 1-based position. |
| `:isEnabled(position)` | `(integer) -> boolean` | Returns whether the effect at the given 1-based position is enabled. |
| `:getEffectCount()` | `() -> integer` | Returns the number of effects in the pipeline. |
| `:getEffect(index)` | `(integer) -> PostFxEffect?` | Returns the effect at the given 1-based position, or nil. |
| `:getEnabledEffects()` | `() -> table` | Returns a table of currently enabled `PostFxEffect` objects. |
| `:getWidth()` | `() -> integer` | Returns the canvas width. |
| `:getHeight()` | `() -> integer` | Returns the canvas height. |
| `:getDimensions()` | `() -> integer, integer` | Returns canvas width and height. |
| `:resize(width, height)` | `(integer, integer) -> nil` | Resizes the internal canvas dimensions. |
| `:len()` | `() -> integer` | Returns the total number of effect slots. |
| `:isEmpty()` | `() -> boolean` | Returns `true` if the pipeline is empty. |
| `:clear()` | `() -> nil` | Removes all effects from the pipeline. |
| `:isCapturing()` | `() -> boolean` | Returns whether the stack is currently capturing the scene. |
| `:type()` | `() -> string` | Returns the string `"PostFxStack"`. |
| `:typeOf(name)` | `(string) -> boolean` | Returns `true` when `name` is `"PostFxStack"` or `"Object"`. |

### ImageEffect Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `:addEffect(name)` | `(string) -> PostFxEffect` | Creates a new effect by type name, appends it to the chain, and returns the shared `PostFxEffect`. |
| `:getEffect(key)` | `(integer\|string) -> PostFxEffect?` | Returns the effect at the given 1-based index or with the given type name, or nil. |
| `:removeEffect(key)` | `(integer\|string) -> boolean` | Removes the effect at the given 1-based index or with the given type name. |
| `:clearEffects()` | `() -> nil` | Removes all effects from the chain. |
| `:clear()` | `() -> nil` | Alias for `clearEffects`. |
| `:effectCount()` | `() -> integer` | Returns the number of effects in the chain. |
| `:getEffectCount()` | `() -> integer` | Alias for `effectCount`. |
| `:clone()` | `() -> ImageEffect` | Returns a deep copy of this ImageEffect chain. |
| `:save()` | `() -> boolean` | Stub: no-op serialisation placeholder. Always returns `true`. |
| `:type()` | `() -> string` | Returns the string `"ImageEffect"`. |
| `:typeOf(name)` | `(string) -> boolean` | Returns `true` when `name` is `"ImageEffect"` or `"Object"`. |
| `:removeByIndex(idx)` | `(integer) -> boolean` | Removes the effect at the given 0-based index. Legacy method. |
| `:removeByName(name)` | `(string) -> boolean` | Removes the first effect matching the given type name. Legacy method. |

### Overlay Methods

#### Core Lifecycle

| Method | Signature | Description |
|--------|-----------|-------------|
| `:update(dt)` | `(number) -> nil` | Advances all overlay subsystems by delta time. |
| `:isActive()` | `() -> boolean` | Returns `true` if any subsystem is active. |
| `:clear()` | `() -> nil` | Resets all subsystems to inactive defaults. |
| `:resize(width, height)` | `(integer, integer) -> nil` | Updates overlay dimensions for particle bounds. |
| `:getWidth()` | `() -> integer` | Returns the overlay width. |
| `:getHeight()` | `() -> integer` | Returns the overlay height. |
| `:getDimensions()` | `() -> integer, integer` | Returns overlay width and height. |
| `:type()` | `() -> string` | Returns the string `"Overlay"`. |
| `:typeOf(name)` | `(string) -> boolean` | Returns `true` when `name` is `"Overlay"` or `"Object"`. |

#### Screen Effects — Long-Form Triggers

| Method | Signature | Description |
|--------|-----------|-------------|
| `:triggerFlash(r, g, b, a, duration)` | `(number×5) -> nil` | Triggers a screen-wide colour flash. |
| `:triggerShake(intensity, duration)` | `(number, number) -> nil` | Triggers a screen shake effect. |
| `:triggerFade(r, g, b, target_alpha, duration)` | `(number×5) -> nil` | Triggers a screen fade to the given colour and alpha. |
| `:triggerLightning()` | `() -> nil` | Triggers a lightning flash effect. |

#### Screen Effects — Shorthand Triggers

| Method | Signature | Description |
|--------|-----------|-------------|
| `:flash(r, g, b, a?, duration?)` | `(number, number, number, number?, number?) -> nil` | Triggers a flash; alpha defaults to 1.0, duration to 0.2 s. |
| `:shake(intensity, duration?)` | `(number, number?) -> nil` | Triggers a shake; duration defaults to 0.5 s. |
| `:fade(r, g, b, alpha?, duration?)` | `(number, number, number, number?, number?) -> nil` | Triggers a fade; alpha defaults to 1.0, duration to 1.0 s. |

#### Screen Effects — State Queries

| Method | Signature | Description |
|--------|-----------|-------------|
| `:getShakeOffset()` | `() -> number, number` | Returns current shake displacement (x, y). |
| `:getFlashAlpha()` | `() -> number` | Returns the current flash overlay alpha (0.0 when inactive). |
| `:getLightningAlpha()` | `() -> number` | Returns the current lightning overlay alpha (0.0 when inactive). |
| `:isFlashing()` | `() -> boolean` | Returns `true` while a flash effect is in progress. |
| `:isShaking()` | `() -> boolean` | Returns `true` while a shake effect is in progress. |
| `:isFading()` | `() -> boolean` | Returns `true` while a fade effect is in progress. |

#### Ambient Lighting

| Method | Signature | Description |
|--------|-----------|-------------|
| `:setAmbientEnabled(enabled)` | `(boolean) -> nil` | Enables or disables the ambient light layer. |
| `:isAmbientEnabled()` | `() -> boolean` | Returns whether the ambient light layer is active. |
| `:setAmbientColor(r, g, b, a?)` | `(number, number, number, number?) -> nil` | Sets the ambient light tint colour; alpha defaults to 1.0. |
| `:getAmbientColor()` | `() -> number, number, number, number` | Returns the current ambient tint as r, g, b, a. |
| `:setTimeOfDay(hour)` | `(number) -> nil` | Sets the simulated time-of-day (0–24) which drives ambient colour. |
| `:getTimeOfDay()` | `() -> number` | Returns the current simulated time-of-day (0–24). |

#### Fog

| Method | Signature | Description |
|--------|-----------|-------------|
| `:setFogEnabled(enabled)` | `(boolean) -> nil` | Enables or disables the fog layer. |
| `:isFogEnabled()` | `() -> boolean` | Returns whether the fog layer is active. |
| `:setFogDensity(density)` | `(number) -> nil` | Sets the fog density (0.0 = clear, 1.0 = fully opaque). |
| `:getFogDensity()` | `() -> number` | Returns the current fog density. |
| `:setFogColor(r, g, b, a?)` | `(number, number, number, number?) -> nil` | Sets the fog tint colour; alpha defaults to 1.0. |
| `:getFogColor()` | `() -> number, number, number, number` | Returns the current fog tint as r, g, b, a. |

#### Heat Haze

| Method | Signature | Description |
|--------|-----------|-------------|
| `:setHeatHazeEnabled(enabled)` | `(boolean) -> nil` | Enables or disables the heat-haze distortion layer. |
| `:isHeatHazeEnabled()` | `() -> boolean` | Returns whether the heat-haze layer is active. |
| `:setHeatHazeIntensity(intensity)` | `(number) -> nil` | Sets the heat-haze distortion intensity. |
| `:getHeatHazeIntensity()` | `() -> number` | Returns the current heat-haze distortion intensity. |

#### Vignette

| Method | Signature | Description |
|--------|-----------|-------------|
| `:setVignetteEnabled(enabled)` | `(boolean) -> nil` | Enables or disables the screen-edge vignette layer. |
| `:isVignetteEnabled()` | `() -> boolean` | Returns whether the vignette layer is active. |
| `:setVignetteStrength(strength)` | `(number) -> nil` | Sets the vignette darkening strength (0.0–1.0). |
| `:getVignetteStrength()` | `() -> number` | Returns the current vignette strength. |

#### Film Grain

| Method | Signature | Description |
|--------|-----------|-------------|
| `:setFilmGrainEnabled(enabled)` | `(boolean) -> nil` | Enables or disables the film-grain noise layer. |
| `:isFilmGrainEnabled()` | `() -> boolean` | Returns whether the film-grain layer is active. |
| `:setFilmGrainIntensity(intensity)` | `(number) -> nil` | Sets the film-grain noise intensity (0.0–1.0). |
| `:getFilmGrainIntensity()` | `() -> number` | Returns the current film-grain intensity. |

#### Cloud Shadows

| Method | Signature | Description |
|--------|-----------|-------------|
| `:setCloudShadows(enabled)` | `(boolean) -> nil` | Enables or disables scrolling cloud-shadow projection. |
| `:isCloudShadowsEnabled()` | `() -> boolean` | Returns whether cloud shadows are active. |
| `:setCloudCount(count)` | `(integer) -> nil` | Sets the number of cloud shadow instances to render. |
| `:getCloudCount()` | `() -> integer` | Returns the current cloud shadow instance count. |
| `:setCloudSpeed(speed)` | `(number) -> nil` | Sets the horizontal scroll speed of cloud shadows in px/s. |
| `:getCloudSpeed()` | `() -> number` | Returns the current cloud shadow scroll speed. |
| `:setCloudScale(scale)` | `(number) -> nil` | Sets the scale multiplier applied to each cloud shadow. |
| `:getCloudScale()` | `() -> number` | Returns the current cloud shadow scale. |
| `:setCloudOpacity(opacity)` | `(number) -> nil` | Sets the opacity of cloud shadows (0.0–1.0). |
| `:getCloudOpacity()` | `() -> number` | Returns the current cloud shadow opacity. |

#### Weather

| Method | Signature | Description |
|--------|-----------|-------------|
| `:setWeatherEnabled(enabled)` | `(boolean) -> nil` | Enables or disables the weather particle system. |
| `:isWeatherEnabled()` | `() -> boolean` | Returns whether the weather particle system is active. |
| `:setWeather(name)` | `(string) -> nil` | Sets the active weather type by name (`"none"`, `"rain"`, `"snow"`, `"hail"`, `"dust"`, `"leaves"`, `"ash"`, `"pollen"`). Errors on unknown names. |
| `:getWeather()` | `() -> string` | Returns the name of the current weather type. |
| `:setWeatherIntensity(intensity)` | `(number) -> nil` | Sets the particle spawn rate multiplier (0.0–1.0). |
| `:getWeatherIntensity()` | `() -> number` | Returns the current weather intensity. |
| `:setWindDirection(radians)` | `(number) -> nil` | Sets the wind direction in radians (0 = right, π/2 = down). |
| `:getWindDirection()` | `() -> number` | Returns the current wind direction in radians. |
| `:setWindSpeed(speed)` | `(number) -> nil` | Sets the wind speed applied to weather particles (units/s). |
| `:getWindSpeed()` | `() -> number` | Returns the current wind speed. |

#### Lightning

| Method | Signature | Description |
|--------|-----------|-------------|
| `:setLightningColor(r, g, b, a?)` | `(number, number, number, number?) -> nil` | Sets the lightning flash tint colour; alpha defaults to 1.0. |
| `:getLightningColor()` | `() -> number, number, number, number` | Returns the lightning flash tint as r, g, b, a. |

#### Rendering

| Method | Signature | Description |
|--------|-----------|-------------|
| `:render()` | `() -> nil` | Emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette) into the frame render queue. Call inside `lurek.render_ui`. |
| `:drawToImage(width, height)` | `(integer, integer) -> ImageData` | Renders the overlay state to a CPU `ImageData`. |

## Lua Examples

```lua
-- Post-processing: bloom + CRT scanlines pipeline
local bloom = lurek.overlay.newEffect("bloom")
bloom:setThreshold(0.6)
bloom:setIntensity(1.5)

local crt = lurek.overlay.newEffect("crt")
crt:setScanlineStrength(0.4)

local stack = lurek.overlay.newStack() -- uses window dimensions
stack:add(bloom)
stack:add(crt)

-- Check available effect types
local types = lurek.overlay.getEffectTypes()
for _, name in ipairs(types) do
    print(name) -- "bloom", "blur", "crt", ...
end
```

```lua
-- Per-image effect chain (single effect with params)
local fx = lurek.overlay.newImageEffect("bloom", { threshold = 0.5, intensity = 1.2 })

-- Or build incrementally:
local fx2 = lurek.overlay.newImageEffect()
local blur = fx2:addEffect("blur")
blur:setRadius(3)
blur:setStrength(0.8)
print(fx2:effectCount()) -- 1

-- Effect chain from table
local chain = lurek.overlay.newImageEffect({
    { type = "bloom", threshold = 0.4, intensity = 1.0 },
    { type = "blur",  radius = 2, strength = 0.5 },
})
```

```lua
-- Screen overlays: weather + flash + shake + ambient
local overlay = lurek.overlay.newOverlay(800, 600)

-- Configure weather
overlay:setWeather("rain")
overlay:setWeatherEnabled(true)
overlay:setWeatherIntensity(0.7)
overlay:setWindDirection(0.3)
overlay:setWindSpeed(50)

-- Configure ambient time-of-day cycling
overlay:setAmbientEnabled(true)
overlay:setTimeOfDay(6.0) -- dawn

-- Enable atmospheric effects
overlay:setFogEnabled(true)
overlay:setFogDensity(0.15)
overlay:setFogColor(0.5, 0.5, 0.6)

overlay:setVignetteEnabled(true)
overlay:setVignetteStrength(0.4)

overlay:setFilmGrainEnabled(true)
overlay:setFilmGrainIntensity(0.15)

function lurek.process(dt)
    overlay:update(dt)

    -- Trigger white flash on spacebar
    if lurek.keyboard.isDown("space") then
        overlay:flash(1, 1, 1)  -- shorthand: alpha=1.0, duration=0.2s
    end

    -- Trigger shake on impact
    if lurek.keyboard.isDown("x") then
        overlay:shake(8.0, 0.4)
    end

    -- Trigger lightning
    if lurek.keyboard.isDown("l") then
        overlay:triggerLightning()
    end

    -- Screen fade to black
    if lurek.keyboard.isDown("f") then
        overlay:fade(0, 0, 0, 1.0, 2.0)
    end
end

function lurek.render()
    -- Apply shake offset to camera
    local sx, sy = overlay:getShakeOffset()
    lurek.graphic.translate(sx, sy)
    -- ... draw world ...
end

function lurek.render_ui()
    -- Render overlay effects to screen
    overlay:render()
end
```

```lua
-- Cloud shadows and heat haze for outdoor desert scene
local overlay = lurek.overlay.newOverlay()
overlay:setCloudShadows(true)
overlay:setCloudCount(8)
overlay:setCloudSpeed(30)
overlay:setCloudOpacity(0.2)

overlay:setHeatHazeEnabled(true)
overlay:setHeatHazeIntensity(1.5)
```

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 16 |
| `enum` | 2 |
| `fn` (Rust domain) | ~57 |
| Lua module functions | 7 |
| Lua UserData methods | 106 |
| **Total Lua API surface** | **113** |

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `math` | Imports from | Uses float arithmetic; no direct type imports |
| `runtime` | Imports from | Uses `log_messages` constants for structured logging |
| `render` | Imports from | `image_effect.rs` imports `ShaderPassDescriptor` (Tier 1) |
| `lua_api` | Imported by | `effect_api.rs` wraps all data models as Lua UserData |

**Similar modules**:

| Module | Differentiation |
|--------|-----------------|
| `particle` | `particle` is a general-purpose CPU particle emitter system; `effect::weather` is a specialised weather-only particle simulation inside the overlay |
| `render` | `render` owns the GPU pipeline; `effect` is data-only — no wgpu imports except through `ShaderPassDescriptor` |
| `tween` | `tween` interpolates arbitrary values over time; `effect::screen_effects` uses hard-coded linear interpolation for flash/fade/shake |

## Notes

- **No GPU code**: `effect` is a pure data-model module. All wgpu rendering, shader compilation, and canvas management for post-processing and overlays happens in `lua_api/effect_api.rs` and the render pipeline. Never add `wgpu` imports to `effect`.
- **Tier 2 import rule**: `effect` may import from `math`, `runtime`, and Tier 1 modules (currently only `render::ShaderPassDescriptor`). It must not import other Tier 2 modules.
- **Dual Lua namespace**: The API table is registered under both `lurek.overlay` and `lurek.postfx` — both point to the same table. Either name can be used interchangeably in Lua scripts.
- **HashMap parameters**: `PostFxEffect` uses `HashMap<String, f32>` for shader uniforms. This is intentional — it decouples the data model from specific shader implementations and supports round-trip serialisation. Unknown parameter keys are silently ignored by the GPU layer.
- **Weather particle cap**: `WeatherState` caps live particles at `intensity * 200`. High-intensity weather (`intensity > 0.8`) can produce up to 200 particles per frame. The spawner uses a hash-based pseudo-random for deterministic-ish placement.
- **Overlay update order**: `Overlay::update(dt)` processes subsystems in a fixed order: ambient, weather, flash, shake, fade, clouds, lightning. Inactive subsystems incur only a branch-check overhead.
- **Shake PRNG**: `ShakeState` uses a simple xorshift32 PRNG (seeded at 12345) for deterministic shake sequences. The PRNG is not thread-safe but does not need to be — Lua VM is single-threaded.
- **Convenience setters on PostFxEffect**: The 9 convenience setters (`setThreshold`, `setIntensity`, `setRadius`, `setStrength`, `setScanlineStrength`, `setOffset`, `setBrightness`, `setContrast`, `setSaturation`) are syntactic sugar over `setParameter(name, value)`. They exist for ergonomics — users don't need to remember exact parameter key strings.
- **ImageEffect `newImageEffect` overloads**: The factory function accepts three calling conventions: no args (empty chain), single string + optional params table, or a table-of-tables for batch construction. This avoids requiring separate factory functions for different use cases.
- **Overlay `render` method**: Unlike other data-model methods, `:render()` pushes draw commands into the engine's render command queue via `SharedState`. It must be called inside `lurek.render_ui` for correct screen-space layering.
- **No Lua BDD tests**: There are currently no Lua-side tests for `lurek.overlay`/`lurek.postfx`. Rust-side coverage exists in `tests/rust/unit/fx_tests.rs` (27 tests covering effect types, stack operations, overlay defaults, and weather round-trips).
- **Breaking change surface**: Renaming `PostFxEffectType` variant string names (e.g. `"bloom"` to `"glow"`) would break all Lua scripts using `lurek.overlay.newEffect()`. The `from_name`/`name` round-trip is a public API contract. Similarly, `WeatherType::from_name` string names are part of the public API.
