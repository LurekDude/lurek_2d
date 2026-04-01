# src/math/

2D math utilities used as the foundational math layer across all modules.

## What This Module Contains

Vec2 (2D vector), Mat3 (3x3 affine matrix), Rect (axis-aligned rectangle). Bezier curves, easing functions (30+ curves), noise generation (Perlin, simplex), polygon operations (convex hull, triangulation, containment), spatial hashing, sRGB gamma conversions, transforms, tweens, raycasting math, procedural generation, and Grid for 2D pathfinding.

## Files

| File | Purpose |
|------|---------|
| `bezier.rs` | `Bezier` implementation |
| `easing.rs` | `Easing` implementation |
| `geometry.rs` | `Geometry` implementation |
| `grid.rs` | `Grid` implementation |
| `mat3.rs` | `Mat3` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `noise.rs` | `Noise` implementation |
| `polygon.rs` | `Polygon` implementation |
| `procgen.rs` | `Procgen` implementation |
| `random.rs` | `Random` implementation |
| `raycasting.rs` | `Raycasting` implementation |
| `rect.rs` | `Rect` implementation |
| `spatial_hash.rs` | `SpatialHash` implementation |
| `srgb.rs` | `Srgb` implementation |
| `transform.rs` | `Transform` implementation |
| `tween.rs` | `Tween` implementation |
| `vec2.rs` | `Vec2` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/math_tests.rs, tests/math_ext_tests.rs`
- **Lua API bindings**: `src/lua_api/math_api.rs, src/lua_api/math_ext_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
