# math — Feature Analysis

**Tier**: Baseline (leaf module, no internal deps)
**Spec**: `specs/math.md`
**Files**: 15 source files

## Purpose

Foundational math primitives shared by the entire engine: `Vec2`, `Mat3`, `Rect`, `Color`, `Noise`, `Easing`, `Random`, `Transform`, `Bezier`, `SpatialHash`, `Tween`, `Triangulation`, `Delaunay`.

## Current Feature Summary

- 2D vector and 3×3 matrix algebra
- Rectangle with full collision/query API
- Color (RGBA f32, hex, HSL, palette LUT, named colors)
- 44 easing functions
- Perlin noise (1D/2D/3D) with advanced generators (FBM, ridged, turbulence, domain-warped)
- PRNG (Xorshift64, seeded, distributions)
- Transform stack (translate, rotate, scale, push/pop)
- Quadratic/Cubic Bezier with evaluation, splitting, arc length
- Delaunay triangulation with Bowyer-Watson
- SpatialHash for broad-phase spatial queries
- Tween with 44 easing functions + built-in types (number, Vec2, Color)

## Feature Gaps

1. **No Vec3/Mat4**: Only 2D math. Even for isometric or pseudo-3D (raycaster wall heights), a Vec3 + Mat4 would help. The spec mentions a Vec3 stub — it should be completed.
2. **No polygon boolean operations**: Union, intersection, difference of polygons (useful for destructible terrain, visibility polygons, CSG).
3. **No spline types beyond Bezier**: Catmull-Rom, B-splines, Hermite. These are standard for path animation and procedural curves.
4. **No curve fitting/regression**: Least squares, polynomial fitting. Useful for data analysis demos.
5. **No Voronoi generation**: Delaunay exists but no dual Voronoi diagram. `procgen` has Voronoi but it's brute-force — math should own the algorithmic primitive.
6. **No polygon clipping**: Sutherland-Hodgman or similar for view frustum clipping of polygons.
7. **No AABB tree**: SpatialHash is grid-based; an AABB tree would handle variable-size objects better.
8. **No matrix decomposition**: SVD, eigenvalues — probably not needed for a 2D game engine.

## Structural Issues

- **SpatialHash imports `engine::log_messages`**: This breaks the "leaf module" claim. Either remove the logging dependency or accept math is not truly a leaf.
- **Tween overlap with animation module**: Both `math::Tween` and `animation` module handle property animation over time. Should clarify: math owns the interpolation function, animation owns the frame/clip system.
- **15 files is borderline large**: Each file is focused, so splitting is not needed. But the module is the backbone of the engine — keep it tight.

## Suggestions

1. **Complete Vec3**: Even a minimal Vec3 (x, y, z + basic ops) would unlock pseudo-3D math for raycasters and isometric.
2. **Add Catmull-Rom spline**: Very common for smooth path generation and animation curves. Love2D has this via BézierCurve but Catmull-Rom is more intuitive for point-following paths.
3. **Add polygon utilities**: Point-in-polygon (currently exists?), polygon area, centroid, convex hull. These pair well with physics and tilemap feature.
4. **Consider `math.lerp(a, b, t)`**: A simple scalar lerp exposed to Lua — trivial but eliminates `a + (b - a) * t` boilerplate in every game script.
5. **Remove SpatialHash → engine dependency**: Use a callback or feature-flag the logging to maintain true leaf status.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Vec2 | ✅ | ❌ (no type) | ❌ | ✅ (Vec2/Vec3/Vec4) |
| Matrix | ✅ (3×3) | ✅ (4×4) | ❌ | ✅ (Mat2/3/4) |
| Bezier | ✅ | ✅ | ❌ | ✅ |
| Noise | ✅ (advanced) | ✅ (basic) | ❌ | ✅ (via crate) |
| Easing | ✅ (44!) | ❌ | ✅ (51) | ✅ |
| Triangulation | ✅ | ✅ | ❌ | ❌ |
| Splines | ❌ | ✅ | ❌ | ✅ |

## Priority

**LOW** — Module is already very complete. Vec3 completion and Catmull-Rom spline are nice-to-haves. Fix the SpatialHash dependency on engine is a correctness issue.
