# IDEA.md — `effect`

| Field  | Value             |
| ------ | ----------------- |
| Module | `effect`          |
| Path   | `src/effect/`     |
| Date   | 2026-04-18        |
| Tier   | Platform Services |

---

## Mission

Provide composable post-processing effects (bloom, blur, CRT, colour grading,
custom WGSL shaders) and full-screen overlays (ambient, weather, flash, shake,
fade, lightning, fog, vignette, film grain, water distortion) as pure CPU data
models. GPU application is handled by `lua_api/effect_api.rs`.

## Strengths

- **Two-family architecture**: post-processing (`PostFxStack` + `PostFxEffect`)
  is cleanly separated from world-simulation overlays (`Overlay` + subsystems),
  avoiding coupling between image-space and world-space effects.
- **24 built-in effect types** with sensible default parameters — games get
  bloom, blur, CRT, vignette, colour grading, chromatic aberration, pixelation,
  sepia, grayscale, edge detection, depth-of-field, motion blur, and more
  out-of-the-box.
- **Named presets** (`retro_tv`, `horror`, `dream`, `neon`, `sepia_age`) give
  instant visual themes with one function call.
- **Screen transitions** (fade, wipe, iris-wipe, dissolve) as a dedicated
  `ScreenTransition` state machine with forward/reverse playback.
- **Weather particle system** with 8 weather types (rain, snow, hail, dust,
  leaves, ash, pollen) and wind influence.
- Pure data models with no GPU coupling — all render commands are generated
  via `render.rs` and `Overlay::build_render_commands`.

## Gaps

- **No per-sprite / per-layer effects**: `PostFxStack` is full-screen only.
  Applying bloom to one sprite requires a per-sprite mini-canvas (not yet
  implemented).
- **Shader compile error display**: Lua toggle exists (`setShaderErrorDisplay`)
  but the GPU-side render path hookup is incomplete — custom shader compile
  errors fail silently.
- **Screen shake duplication**: shake lives in both `effect::Overlay` and
  `camera` module — one should be canonical.

## Features (max 3 competitor cites)

1. **Named preset stacks** — Godot requires manual CanvasLayer + Shader setup;
   LÖVE has no built-in presets (uses third-party `moonshine`). Lurek2D's
   `build_preset("horror", w, h)` is one-call.
2. **24 built-in post-processing types** — Solar2D has a limited set of
   built-in filters; Defold requires custom render scripts for each effect.
3. **Weather particle overlay with 8 types + wind** — Godot has `GPUParticles2D`
   but no built-in weather presets; LÖVE requires manual particle emitters.

## Perf / Quality

- `Overlay::update_weather` uses `swap_remove` for O(1) particle culling —
  good for high particle counts.
- `PostFxStack::dedup_indices` prevents redundant shader passes.
- Weather spawner uses a deterministic golden-ratio hash instead of a PRNG
  crate — lightweight but may produce visible patterns at high particle
  density.

## Test Gaps

- `overlay.rs` had no Rust-level tests for `update`, `trigger_*`, `clear`, or
  `build_render_commands` (now added).
- `stack.rs` had no direct struct tests (only via `draw.rs` and `render.rs`);
  now added.
- `image_effect.rs` cannot be fully unit-tested without `ShaderPassDescriptor`
  from `render` crate — integration tests cover `to_passes()`.

## TODO(dedup): entries

- `TODO(dedup): effect::AmbientState vs light::LightWorld.ambient` — two
  independent ambient colour systems. See also `src/light/IDEA.md`.
- `TODO(dedup): effect::Overlay.shake vs camera shake` — screen shake lives in
  both overlay and camera modules. Pick one canonical location.
- `TODO(dedup): particle↔effect overlap` — weather particles in `effect` vs
  general particles in `particle` module share spawn/move/cull patterns.

## TODO(helper): entries

- `TODO(helper): PostFxEffectType string ↔ enum` — `from_name` / `name` are
  repeated 24× in two match arms. A macro or const table would reduce
  maintenance cost.

## TODO(plugin): entries

- `TODO(plugin): per-sprite effects` — candidate for a `sprite-fx` plugin that
  adds per-sprite mini-canvas post-processing chains.
- `TODO(plugin): advanced weather` — candidate for a `weather-advanced` plugin
  with wind turbulence, accumulation textures, and puddle reflections.

## References

- `docs/specs/effect.md` — canonical module spec.
- `src/lua_api/effect_api.rs` — Lua bridge.
- `tests/lua/unit/test_image_effect.lua` — primary Lua test suite.
- Godot CanvasItem shaders: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html
