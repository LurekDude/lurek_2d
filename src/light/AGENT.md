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

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/light.md`](../../docs/specs/light.md)

_Update both this file **and** `docs/specs/light.md` whenever source files, public types, or Lua bindings change._
