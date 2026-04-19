# IDEA — math

| Field         | Value      |
| ------------- | ---------- |
| Module        | math       |
| Path          | src/math/  |
| Last Reviewed | 2026-04-18 |
| Plugin Tier   | CORE-KEEP  |

## Mission Summary

The `math` module is Lurek2D's foundational mathematics library — the leaf of the engine dependency graph with zero internal dependencies. It provides all core value types (Vec2, Vec3, Mat3, Color, Rect, Transform), curve evaluation (Bezier, Catmull-Rom, Hermite), spatial indexing (SpatialHash, AabbTree), procedural noise (Perlin, Simplex, Worley, FBM), random number generation, polygon operations, Voronoi tessellation, and 30+ easing functions used across every engine subsystem.

## Existing Strengths

- Comprehensive 2D math surface: Vec2, Mat3, Transform, Rect cover the standard 2D game engine needs
- Full easing library with string-based lookup — matches LÖVE/Godot/Solar2D feature parity
- Two broad-phase spatial structures (SpatialHash for uniform sizes, AabbTree for variable sizes)
- Deterministic seedable RNG with state save/restore for reproducible gameplay
- Rich noise generation: Perlin/Simplex 1D–4D, Worley, FBM/ridged/turbulence, domain warping, map generation
- Voronoi tessellation with Bowyer-Watson Delaunay triangulation
- Polygon clipping, intersection, union, difference via Sutherland-Hodgman
- All value types are Copy/Clone with no heap allocations (except spline control point vectors)
- Well-documented with consistent parameter/return doc patterns

## Gap List

1. No `clamp` free function in mod.rs (libraries like `content/library/stats/init.lua` re-implement it)
2. No `sign` / `smoothstep` / `inverseLerp` utility functions
3. Vec2 lacks `from_angle` constructor and `reflect` method
4. Vec3 lacks `splat` constructor
5. Color lacks HSL conversion and `from_hex` constructor (only HSV→RGB exists)
6. No `Rect::union` method (only intersection)
7. No `Rect::from_center` / `Rect::from_points` constructors
8. CatmullRomSpline lacks `add_point` / `remove_point` mutation methods
9. Transform lacks `decompose()` to extract position/rotation/scale back out
10. No `Circle` value type for collision geometry
11. AabbTree lacks `query_circle` and `query_segment` (SpatialHash has both)
12. Easing module lacks `inOutElastic` and `inOutBounce` curves

## Feature Ideas

1. **Bezier path following with constant-speed parameterization** — current `evaluate(t)` is not arc-length parameterized, causing uneven speed along curves. An `evaluate_at_distance(d)` method would enable smooth camera rails and entity path following. [LÖVE: love.math has no built-in arc-length param — this would exceed parity. Godot: `Curve2D.sample_baked()` provides arc-length param — https://docs.godotengine.org/en/stable/classes/class_curve2d.html]
2. **Noise map GPU compute offload** — `NoiseGenerator::generate_2d_map()` is CPU-only and single-threaded. A compute shader path via `lurek.compute` would accelerate large map generation (512×512+). [Godot: FastNoiseLite with GPU compute — https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html]
3. **Rect packing algorithm** — useful for texture atlas generation and UI layout. [Defold: uses rectpack2D for atlas packing — https://defold.com/manuals/atlas/]

## Performance / Reliability / Quality Ideas

- `BezierCurve::evaluate()` clones the entire control_points Vec per call — consider a scratch buffer to avoid per-call allocation
- `SpatialHash::query_rect` / `query_circle` allocate a new HashSet+Vec per call — consider reusable buffers
- `NoiseGenerator` 4D Perlin has 16 gradient lookups per sample — cache-friendly access pattern not guaranteed
- `AabbTree::find_best_sibling` could be optimized with a priority queue instead of a flat stack
- `polygon_clip` allocates a new Vec per clipping edge — could reuse double-buffered Vecs
- Consider adding `#[inline]` to Vec2/Vec3 arithmetic operator impls for hot-path performance
- SIMD acceleration for batch noise generation (via `std::simd` or `packed_simd2`) — LOW priority, profile first

## Test Coverage Gaps

- `src/math/aabb_tree.rs` — no inline tests (tests added to sibling `aabb_tree_tests.rs` this session)
- `src/math/spline.rs` — no inline tests (tests added this session)
- `src/math/vec3.rs` — no inline tests (tests added this session)
- `src/math/mod.rs` — no inline tests for `lerp`/`remap` (tests added this session)
- `noise_generator.rs` — Worley noise, domain warping, and map generation methods have tests but fractal combinator edge cases (0 octaves, negative persistence) are uncovered
- `geometry.rs` — `delaunay_triangulate` and `convex_hull` lack edge-case tests for collinear inputs

## Cross-Module Overlap

TODO(dedup): graph::Vec2 — graph module may define its own vector type; verify and consolidate
TODO(dedup): tween::* — math/tween.rs (low-level numeric interpolator) and src/tween/ (frame-by-frame property animation) have overlapping easing resolution code (`resolve_easing` in tween.rs duplicates `easing::apply` logic)
TODO(dedup): noise_functions.rs vs noise_generator.rs — standalone `perlin2d`/`simplex2d`/`fbm` functions duplicate algorithms that `NoiseGenerator` also implements with a permutation table; callers may be confused about which to use

## Engine-Level Helper Candidates

TODO(helper): clamp — content/library/stats/init.lua:32 re-implements clamp with lurek.math fallback; should be a first-class `lurek.math.clamp`
TODO(helper): seedable_rng — content/library/battle/init.lua:649 uses `math.random()` with a TODO to switch to `lurek.math.newRng()`; confirms the engine RNG API is needed but under-adopted

## Plugin Candidacy

TODO(plugin): CORE-KEEP — math is foundational to every engine subsystem (render, physics, input, camera, tilemap, ai, particle, etc.); cannot be made optional

## References

- docs/specs/math.md
- src/lua_api/math_api.rs
- content/library/stats/init.lua (clamp/lerp fallback pattern)
- content/library/battle/init.lua (RNG TODO)
