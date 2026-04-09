# `light` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extension                            |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.light`                                         |
| **Source**      | `src/light/`                                         |
| **Rust Tests** | `tests/rust/unit/light_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_light.lua`                      |
| **Architecture** | —                                                  |

## Purpose

The `light` module provides a CPU-side 2D dynamic lighting data model for Lurek2D. It stores all state needed to describe point, directional, and spot light sources in 2D space — position, radius, colour, intensity, falloff curves, shadow settings, flicker effects, attenuation coefficients, bitmask-based filtering, and group management. It also provides `Occluder` polygons that define shadow-casting geometry and `LightWorld`, a SlotMap-based resource pool that aggregates all lights and occluders for a scene.

## Source Files

| File              | Purpose                                                        |
|-------------------|----------------------------------------------------------------|
| `mod.rs`          | Module root — re-exports all public types, declares submodules |
| `attenuation.rs`  | `Attenuation` struct — custom distance falloff coefficients    |
| `blend_mode.rs`   | `LightBlendMode` enum — additive / subtractive / mix blending  |
| `falloff.rs`      | `FalloffMode` enum — linear / smooth / constant intensity decay|
| `flicker.rs`      | `FlickerConfig` struct — sinusoidal intensity modulation       |
| `light2d.rs`      | `Light2D` struct — primary light data container (23 fields)    |
| `light_type.rs`   | `LightType` enum — point / directional / spot geometry         |
| `light_world.rs`  | `LightWorld` struct — SlotMap pool for lights and occluders    |
| `occluder.rs`     | `Occluder` struct — polygon shadow caster definition           |
| `shadow.rs`       | `ShadowFilter` enum — shadow edge quality (none / PCF5 / PCF13)|

## Key Types

| Type | Description |
|------|-------------|
| `Attenuation` | Principal type for the `light` module. |
| `LightBlendMode` | Principal type for the `light` module. |
| `FalloffMode` | Principal type for the `light` module. |
| `FlickerConfig` | Principal type for the `light` module. |
| `Light2D` | Principal type for the `light` module. |
| `LightType` | Principal type for the `light` module. |
| `LightWorld` | Principal type for the `light` module. |
| `Occluder` | Principal type for the `light` module. |
| `ShadowFilter` | Principal type for the `light` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.light.newLight()` | See `docs/specs/light.md`. |
| `lurek.light.newOccluder()` | See `docs/specs/light.md`. |
| `lurek.light.setAmbient()` | See `docs/specs/light.md`. |
| `lurek.light.getAmbient()` | See `docs/specs/light.md`. |
| `lurek.light.setEnabled()` | See `docs/specs/light.md`. |
| `lurek.light.isEnabled()` | See `docs/specs/light.md`. |
| `lurek.light.getLightCount()` | See `docs/specs/light.md`. |
| `lurek.light.getOccluderCount()` | See `docs/specs/light.md`. |
| `lurek.light.getMaxLights()` | See `docs/specs/light.md`. |
| `lurek.light.setMaxLights()` | See `docs/specs/light.md`. |
| `lurek.light.clear()` | See `docs/specs/light.md`. |
| `lurek.light.setGroupEnabled()` | See `docs/specs/light.md`. |
| `lurek.light.setGroupIntensity()` | See `docs/specs/light.md`. |
| `lurek.light.setGroupColor()` | See `docs/specs/light.md`. |
| `lurek.light.getGroupCount()` | See `docs/specs/light.md`. |
| `lurek.light.advanceFlickers()` | See `docs/specs/light.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/light.md`](../../docs/specs/light.md)

_Update both this file **and** `docs/specs/light.md` whenever source files, public types, or Lua bindings change._
