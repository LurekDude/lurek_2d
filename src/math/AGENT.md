# `math` — Agent Reference

| Property         | Value                                                                         |
|------------------|-------------------------------------------------------------------------------|
| **Tier**         | Baseline — leaf of the dependency graph                                       |
| **Status**       | Implemented — Full                                                            |
| **Lua API**      | `lurek.math` (60+ functions, 6 UserData types)                                |
| **Source**       | `src/math/`                                                                   |
| **Rust Tests**   | `tests/rust/unit/math_tests.rs`, inline tests in `easing.rs`, `tween.rs`, `spatial_hash.rs`, `geometry.rs`, `noise_generator.rs` |
| **Lua Tests**    | `tests/lua/unit/test_math.lua`                                                |
| **Architecture** | `docs/architecture/engine-architecture.md` § Baseline Tier                   |

## Purpose

`src/math/` is the leaf of the Lurek2D dependency graph — it has zero internal
Lurek2D module dependencies (other than `crate::runtime::log_messages` in
`spatial_hash.rs`). Every other module may freely import it. It provides core
mathematical primitives (`Vec2`, `Mat3`, `Rect`, `Color`), procedural generation
(`NoiseGenerator`, `RandomGenerator`), interpolation (`Tween`, easing functions),
geometry algorithms, and spatial indexing. The Lua bridge lives in
`src/lua_api/math_api.rs`.

## Source Files

| File                | Purpose                                                              |
|---------------------|----------------------------------------------------------------------|
| `mod.rs`            | Module root — re-exports all public items from submodules.           |
| `vec2.rs`           | `Vec2` — 2D vector with arithmetic overloads and directional constants. |
| `mat3.rs`           | `Mat3` — 3×3 row-major affine matrix.                               |
| `rect.rs`           | `Rect` — AABB with contains/intersects.                              |
| `color.rs`          | `Color` — sRGB `[f32; 4]` with named constants and gamma conversion. |
| `bezier.rs`         | `BezierCurve` — arbitrary-order De Casteljau evaluation.             |
| `easing.rs`         | 22 easing functions + case-insensitive `apply(name, t)` dispatcher.  |
| `geometry.rs`       | Free functions: angles, circle tests, polygon ops, Bresenham, etc.   |
| `noise_functions.rs`| Standalone: `perlin2d/3d/4d`, `simplex2d`, `fbm`.                   |
| `noise_generator.rs`| `NoiseGenerator` with Perlin/Simplex/Worley/fractal/map generation.  |
| `polygon.rs`        | `triangulate` (ear-clipping), `is_convex`.                           |
| `random.rs`         | `RandomGenerator` — fastrand wrapper with normal distribution.       |
| `spatial_hash.rs`   | `SpatialHash`, `SpatialItem` — grid-based broad-phase spatial index. |
| `transform.rs`      | `Transform` — fluent `Mat3` wrapper with translate/rotate/scale API. |
| `tween.rs`          | `Tween`, `TweenValue` — math-level multi-value interpolation.        |

## Full Specification

Full spec: [`docs/specs/math.md`](../../../docs/specs/math.md)
