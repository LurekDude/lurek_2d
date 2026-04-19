# IDEA.md — `light`

| Field  | Value             |
| ------ | ----------------- |
| Module | `light`           |
| Path   | `src/light/`      |
| Date   | 2026-04-18        |
| Tier   | Platform Services |

---

## Mission

Provide a pure-data 2D lighting model (point, directional, spot) with shadow
occluders, attenuation curves, flicker effects, and group operations. The
renderer drives GPU passes from `RenderCommand` variants; this module holds no
GPU state.

## Strengths

- Clean data-only design: `Light2D`, `Occluder`, `LightWorld` carry zero GPU
  coupling — all rendering is deferred to `RenderCommand` emission.
- Rich parameter surface: blend modes, falloff curves, custom attenuation
  coefficients, flicker configs, bitmask-based light/shadow masks, and
  volumetric hints cover a wide range of 2D lighting scenarios.
- Group operations (`set_group_enabled`, `set_group_intensity`,
  `set_group_color`) allow batch control without iterating from Lua.
- `LightTransition` provides frame-driven smooth interpolation for color,
  intensity, and radius without requiring a tween module dependency.

## Gaps

- **No soft shadows / penumbra**: Only hard shadow edges; no multi-sample or
  blur-based soft shadow pass. Competitors offer configurable penumbra width.
- **Ambient duplication**: `LightWorld.ambient` and the `effect` module's
  `AmbientState` are independent — no bridge or priority system to reconcile
  conflicting ambient values.
- **No normal-map lighting**: 2D normal-map illumination (used by Godot
  CanvasItem shaders) is absent. Would require per-pixel direction data.

## Features (max 3 competitor cites)

1. **Point / Directional / Spot geometry** — Godot Light2D supports all three
   via `Light2D` node types; LÖVE uses a third-party library (e.g. `light_world`).
2. **Shadow occluders with bitmask filtering** — Godot `LightOccluder2D` has
   `occluder_light_mask`; Solar2D lacks built-in 2D shadow casting.
3. **Flicker effect with sinusoidal modulation** — Bevy has no built-in flicker;
   Godot requires AnimationPlayer or shader; Lurek2D provides `FlickerConfig`
   natively on the light data.

## Perf / Quality

- `LightWorld::advance_flickers` iterates all lights each frame even if only a
  few have flicker enabled. A secondary index of flickering lights would reduce
  overhead in scenes with many static lights.
- `draw_to_image` (CPU lightmap) uses per-pixel quadratic falloff with no
  spatial acceleration — fine for small diagnostic images but O(W×H×N) for N
  lights.

## Test Gaps

- `light2d.rs` has 2 unit tests; getters/setters for shadow, blend, falloff,
  attenuation, and flicker are untested at the Rust level (covered partially by
  Lua tests).
- `light_world.rs` group operations, `advance_flickers`, and
  `directional_light_hints` lacked Rust-level tests (now added).
- `transition.rs` had no tests (now added).

## TODO(dedup): entries

- `TODO(dedup): effect::AmbientState vs light::LightWorld.ambient` — two
  independent ambient colour systems. Unify or create a priority bridge.

## TODO(helper): entries

- `TODO(helper): parse_blend_mode / parse_falloff / parse_shadow_filter /
  parse_light_type` in `light2d.rs` are Lua-facing string parsers that belong
  in `lua_api/light_api.rs` per the Thin Wrapper Rule.

## TODO(plugin): entries

- `TODO(plugin): normal-map lighting` — candidate for a `light-normalmap`
  plugin that adds per-pixel directional illumination (requires shader support).

## References

- `docs/specs/light.md` — canonical module spec.
- `src/lua_api/light_api.rs` — Lua bridge.
- `tests/lua/unit/test_light.lua` — primary Lua test suite.
- Godot Light2D docs: https://docs.godotengine.org/en/stable/classes/class_light2d.html
