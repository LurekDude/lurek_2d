# light - Agent Reference

## Module Info

- Module: light
- Group: Platform Services
- Spec: docs/specs/light.md
- Lua API: src/lua_api/light_api.rs
- Rust tests: tests/rust/unit/light_tests.rs
- Lua tests: tests/lua/unit/test_light.lua, tests/lua/stress/test_light_stress.lua, tests/lua/integration/test_light_graphics.lua, tests/lua/evidence/test_evidence_light.lua

## Module Purpose

The light module owns the CPU-side 2D lighting model. It defines individual lights, occluders, attenuation, falloff, flicker, blend behavior, shadow filtering, and the LightWorld container that groups active lighting state into keyed pools for the renderer to consume later.

This module keeps lighting data and rules separate from shader execution. It describes what lights and occluders exist and how they should behave, but it does not perform shadow rendering, final compositing, or scene ownership. That boundary keeps the lighting state testable and lets the renderer decide how to turn these descriptions into an actual lighting pass.

## Files

- mod.rs: Declares the lighting submodules and re-exports the public light types.
- light2d.rs: Defines Light2D, the main per-light data record with position, radius, color, intensity, masks, shadows, geometry, attenuation, flicker, and grouping.
- light_world.rs: Defines LightWorld, the keyed container for active lights, occluders, ambient color, limits, and group operations.
- occluder.rs: Defines Occluder, a polygon shadow caster with transform, opacity, mask, and enabled state.
- light_type.rs: Defines the geometric light-type enum for point, directional, and spot lights.
- blend_mode.rs: Defines how light mixes with the scene.
- falloff.rs: Defines the high-level radial falloff enum.
- attenuation.rs: Defines coefficient-based attenuation for custom distance decay.
- flicker.rs: Defines flicker configuration and phase advancement helpers.
- shadow.rs: Defines the shadow edge-filter enum.

## Key Types

- Light2D: Main per-light data container used by Lua and the renderer-facing lighting world.
- LightWorld: Owner of the light and occluder pools, ambient settings, limits, and group operations.
- Occluder: Polygon shadow caster with vertices, transform, opacity, mask, and enabled state.
- LightType: Enum distinguishing point, directional, and spot light behavior.
- LightBlendMode: Enum controlling additive, subtractive, or mixed scene contribution.
- FalloffMode: Enum describing how intensity decays from center to edge.
- Attenuation: Coefficient-based custom falloff model.
- FlickerConfig: Time-varying intensity modulation for torches, unstable lights, and similar effects.
- ShadowFilter: Enum selecting the shadow edge filtering quality.
