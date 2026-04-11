# `effect` � Agent Reference

| Property       | Value                                               |
|----------------|-----------------------------------------------------|
| **Tier**       | Tier 2 � Engine Extensions                          |
| **Status**     | Implemented � Full                                  |
| **Lua API**    | `lurek.effect`                                           |
| **Source**      | `src/effect/`                                               |
| **Rust Tests** | `tests/rust/unit/fx_tests.rs`                       |
| **Lua Tests**  | �                                                   |
| **Architecture** | �                                                 |

## Purpose

The `effect` module is a Tier 2 Engine Extension that provides composable visual effects as
pure CPU data models. It contains no wgpu code and no GPU resource handles � all rendering
is performed by the `lua_api` bridge layer, which reads the data models each frame.

## Source Files

| File | Purpose |
|------|---------|
| `ambient.rs` | Ambient lighting state with time-of-day colour cycling (night to dawn to day to dusk). Provides `AmbientState` with `compute_color_from_time()`. |
| `atmosphere.rs` | Data-only structs for atmospheric effects: `CloudState` (scrolling shadow blobs), `FogState` (uniform translucent tint), `HeatHazeState` (sine-wave UV distortion), `VignetteState` (radial edge darkening), `FilmGrainState` (per-pixel noise), `LightningState` (single-shot hard flash). |
| `effect.rs` | `PostFxEffect` � a single post-processing shader pass with a `HashMap<String, f32>` parameter bag, builder helpers, and type introspection. |
| `effect_type.rs` | `PostFxEffectType` enum � 16 built-in effect kinds plus `Custom`. Provides `from_name`/`name` round-trip parsing and `default_params()` preset maps. |
| `image_effect.rs` | `ImageEffect` � an ordered chain of `Rc<RefCell<PostFxEffect>>` entries. Converts to `Vec<ShaderPassDescriptor>` via `to_passes()` for embedding into `RenderCommand` variants. Imports from `crate::graphics` (Tier 1). |
| `overlay.rs` | `Overlay` � aggregates all 12 screen-effect subsystems. `update(dt)` advances ambient, weather, flash, shake, fade, clouds, and lightning. Trigger methods for flash, shake, fade, and lightning. Query methods for shake offset and flash/lightning alpha. |
| `screen_effects.rs` | Three one-shot screen effects: `FlashState` (colour burst fading to transparent), `ShakeState` (decaying xorshift PRNG pixel offset), `FadeState` (alpha interpolation between start and target). |
| `stack.rs` | `PostFxStack` � ordered chain of effect indices with parallel `enabled` flags. Manages ping-pong canvas dimensions. 1-based position insertion, per-index enable/disable, and `enabled_effects()` for the GPU layer. |
| `weather.rs` | `WeatherType` enum (8 variants: None, Rain, Snow, Hail, Dust, Leaves, Ash, Pollen), `WeatherParticle` (position, velocity, size, alpha), and `WeatherState` (spawn timer, wind, intensity, live particle pool). |

## Key Types

| Type | Description |
|------|-------------|
| `AmbientState` | Principal type for the `effect` module. |
| `CloudState` | Principal type for the `effect` module. |
| `FogState` | Principal type for the `effect` module. |
| `HeatHazeState` | Principal type for the `effect` module. |
| `VignetteState` | Principal type for the `effect` module. |
| `FilmGrainState` | Principal type for the `effect` module. |
| `LightningState` | Principal type for the `effect` module. |
| `PostFxEffect` | Principal type for the `effect` module. |
| `PostFxEffectType` | Principal type for the `effect` module. |
| `ImageEffect` | Principal type for the `effect` module. |
| `Overlay` | Principal type for the `effect` module. |
| `FlashState` | Principal type for the `effect` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.fx.newEffect()` | See `docs/specs/effect.md`. |
| `lurek.fx.newCustomEffect()` | See `docs/specs/effect.md`. |
| `lurek.fx.newStack()` | See `docs/specs/effect.md`. |
| `lurek.fx.newPass()` | See `docs/specs/effect.md`. |
| `lurek.fx.getEffectTypes()` | See `docs/specs/effect.md`. |
| `lurek.fx.newImageEffect()` | See `docs/specs/effect.md`. |
| `lurek.fx.newOverlay()` | See `docs/specs/effect.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

� [`docs/specs/effect.md`](../../docs/specs/effect.md)

_Update both this file **and** `docs/specs/effect.md` whenever source files, public types, or Lua bindings change._
