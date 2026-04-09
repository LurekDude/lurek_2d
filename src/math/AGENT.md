# math — Foundational Algorithms

| Property           | Value |
|--------------------|-------|
| **Tier**           | Baseline (leaf) |
| **Architecture**   | 15 submodule files, flat layout under `src/math/` |
| **Path**           | `src/math/` |
| **Depends on**     | `fastrand` (external); `crate::engine::log_messages` (log constants in `spatial_hash.rs` only) |
| **Depended on by** | Every other Lurek2D module |
| **Lua API**        | `lurek.math` via `src/lua_api/math_api.rs` |
| **Tests — Rust**   | `tests/unit/math_tests.rs` (~60 tests, 857 lines) |
| **Tests — Lua**    | `tests/lua/unit/test_math.lua` (~20 tests, 128 lines) |
| **Inline tests**   | `easing.rs`, `tween.rs`, `spatial_hash.rs`, `geometry.rs`, `noise_generator.rs` |

## Purpose

`math` is the **leaf of the dependency graph** — it has zero Tier-1+ internal Lurek2D dependencies. Every other module may freely import it. It provides the core mathematical primitives, procedural generation utilities, and interpolation tools used throughout the engine.

## Source Files

| File | Contents |
|------|----------|
| `mod.rs` | Module root — re-exports all public items from submodules |
| `vec2.rs` | `Vec2` struct — arithmetic ops, normalization, dot product, lerp, rotation, directional constants |
| `mat3.rs` | `Mat3` 3×3 matrix — identity, translation, rotation, scale, shear, inverse, multiply |
| `rect.rs` | `Rect` AABB — center, area, contains, intersects |
| `color.rs` | `Color` sRGB — constructors, `from_u8`/`to_u8`/`to_rgb_u32`, named constants, `gamma_to_linear`/`linear_to_gamma` |
| `bezier.rs` | `BezierCurve` — De Casteljau evaluation, render, derivative, arc length, control-point CRUD |
| `easing.rs` | 22 easing functions + `apply(name, t)` case-insensitive lookup with alias support |
| `geometry.rs` | Free geometry functions — angle, circle tests, polygon area/centroid, segment intersection, Bresenham, convex hull, Delaunay, point-in-polygon, line intersect |
| `noise_functions.rs` | Standalone noise — `perlin2d`/`3d`/`4d`, `simplex2d`, `simplex_noise_2d`/`3d`, `fbm` |
| `noise_generator.rs` | `NoiseGenerator` — seeded permutation-table noise with Perlin/Simplex/Worley, fractal combinators, domain warping, 2D map generation; `NoiseKind`, `DistType`, `FractalType`, `MapGenOptions` |
| `polygon.rs` | `triangulate` (ear-clipping, CCW enforcement), `is_convex` |
| `random.rs` | `RandomGenerator` — fastrand wrapper, normal distribution, state serialization |
| `spatial_hash.rs` | `SpatialHash`, `SpatialItem` — grid-based broad-phase with rect/circle/segment queries |
| `transform.rs` | `Transform` — `Mat3` wrapper with fluent translate/rotate/scale/shear/reset API |
| `tween.rs` | `Tween`, `TweenValue` — multi-value interpolation with named easing resolution |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/math.md`](../../docs/specs/math.md)

_Update both this file **and** `docs/specs/math.md` whenever source files, public types, or Lua bindings change._
