# math

## General Info

- Module group: `Foundations`
- Source path: `src/math/`
- Lua API path(s): `src/lua_api/math_api.rs`
- Primary Lua namespace: `lurek.math`
- Rust test path(s): tests/rust/unit/math_tests.rs; inline tests in src/math/vec2.rs, src/math/vec3.rs, src/math/mat3.rs, src/math/rect.rs, src/math/color.rs, src/math/bezier.rs, src/math/easing.rs, src/math/geometry.rs, src/math/noise_functions.rs, src/math/noise_generator.rs, src/math/polygon.rs, src/math/random.rs, src/math/spatial_hash.rs, src/math/transform.rs, src/math/tween.rs, src/math/voronoi.rs, src/math/mod.rs; sibling test file src/math/aabb_tree_tests.rs; inline tests in src/math/spline.rs
- Lua test path(s): tests/lua/unit/test_math.lua

## Summary

The `math` module is Lurek2D's foundational mathematics library — a Foundations tier module at the leaf of the engine's dependency graph with zero Lurek2D module dependencies of its own. Every other module that needs 2D math, geometry, or colour types imports from here.

**Core value types.** `Vec2` (2D f32 vector with arithmetic operators, swizzling, dot/cross/normalise/lerp/distance), `Vec3` (3D f32 vector with equivalent ops), `Mat3` (3x3 column-major affine transform matrix supporting translate, rotate, scale composition and multiplication), `Transform` (chainable builder wrapping `Mat3`), `Rect` (AABB with contains/overlaps/union/intersection), `Color` (the engine's canonical sRGB `[f32; 4]` type with named constants, `u8` and `f32` constructors, packed `u32` output, HSV conversion, and gamma helpers — all engine colour handling must use this type).

**Curve and spline types.** `BezierCurve` (arbitrary-order De Casteljau evaluation with tangent and arc-length queries), `CatmullRomSpline` (smooth interpolating spline for animation paths), `HermiteSpline` (tension-controlled interpolation). These underpin animation, camera paths, and UI transitions.

**Geometry utilities.** `geometry.rs` provides free-standing geometry helpers: circle/point containment, AABB overlap, line segment intersection, Bresenham rasterisation, convex hull (Andrew's monotone chain), ear-clipping polygon triangulation, and polygon area/centroid. `polygon.rs` focuses on convexity testing and triangulation quality. `Circle` and `Sphere` are lightweight value types for game-code collision geometry.

**Spatial index.** `SpatialHash` is a uniform-grid broad-phase AABB index: `insert(id, rect)`, `query_rect(rect)` returns a set of IDs, `remove(id)`. `AabbTree` is a dynamic BVH for the same query surface with better worst-case complexity for non-uniformly distributed objects.

**Noise.** `noise_generator.rs` is the canonical implementation (`NoiseGenerator`) for seeded Perlin/Simplex/Worley + fractal/map generation. `noise_functions.rs` remains as a compatibility free-function surface and delegates to `NoiseGenerator` to keep both APIs behaviorally aligned. `NoiseField` is the simplified Lua-facing wrapper.

**Voronoi tessellation.** `voronoi.rs` implements Fortune's sweep-line algorithm. `VoronoiDiagram::new(points)` computes the tessellation; `cells()` iterates `VoronoiCell` entries with polygon boundary vertices and neighbour indices. Used for procedural territory maps, dungeon partitioning, and noise dithering.

**Transform algebra.** `Transform2D` in `transform.rs` is a mutable 2D transform wrapper around `Mat3` with chainable `translate(dx, dy)`, `rotate(angle)`, `scale(sx, sy)`, `shear(sx, sy)` operations and `world_to_local(p)` / `local_to_world(p)` point conversion. This simplifies 2D scene-graph transform accumulation without manually composing Mat3 calls.

**Easing.** `EasingType` enum covers 30+ named easing functions (linear, quad, cubic, quart, quint, sine, expo, circ, bounce, back, elastic — all in/out/in-out variants), addressable both by enum variant and by string name for serialisation. `easing.rs` also contains the numeric interpolation primitives in `tween.rs` used by the `tween` feature module.

**Randomisation.** `RandomGenerator` wraps `fastrand` in a seedable, serialisable deterministic RNG. `seed(n)`, `float()`, `int_range(min, max)`, `bool_chance(p)`, `pick(table)`, `shuffle(table)`. Used wherever reproducible sequences are needed (procedural generation, test fixtures, AI noise).

**Math facade.** `facade.rs` exposes free functions: `lerp(a, b, t)`, `remap(v, in_min, in_max, out_min, out_max)`, `clamp(v, lo, hi)`, `sign(v)`, `smoothstep(e0, e1, x)`, `inverse_lerp(a, b, v)`.

**Lua surface.** `lurek.math.*` exposes Vec2/Vec3/Mat3/Color constructors and full method sets; `Rect`, `BezierCurve`, `Transform2D`, `NoiseField`, `VoronoiDiagram`, `SpatialHash` userdata; easing functions via `lurek.math.ease(type, t)`, random via `lurek.math.newRand(seed)` and free functions (lerp, clamp, remap, etc.).

**Scope boundary.** Foundations tier. Zero Lurek2D dependencies. Lua bridge in `src/lua_api/math_api.rs`.

## Files

- `aabb_tree.rs`: Dynamic axis-aligned bounding box (AABB) tree for broad-phase queries.
- `bezier.rs`: Implements arbitrary-order Bezier curves with evaluation, derivative, editing, rendering, and transform helpers.
- `circle.rs`: Circle value type for 2D collision geometry and containment queries.
- `color.rs`: Defines the shared RGBA value type plus byte conversion, packed RGB output, HSV conversion, and gamma helpers.
- `easing.rs`: Houses the named easing curve functions and the string-based dispatcher used by tweening code and Lua bindings.
- `facade.rs`: Foundational math free functions: `lerp`, `remap`, `clamp`, `sign`, `smoothstep`, `inverse_lerp`.
- `geometry.rs`: Collects free-standing geometry utilities such as circle tests, polygon measurements, segment tests, line rasterization, convex hull, and triangulation helpers.
- `mat3.rs`: Implements the 3x3 affine matrix used for 2D transforms, point transforms, composition, and inversion.
- `mod.rs`: Re-exports the public math surface so other modules and the Lua bridge can depend on one stable module root.
- `noise_functions.rs`: Compatibility free-function layer (`perlin2d`, `simplex2d`, `fbm`, ...) delegating to `NoiseGenerator`.
- `noise_generator.rs`: Owns the seeded `NoiseGenerator` and the richer procedural toolset for Perlin, Simplex, Worley, fractal layering, domain warping, and map generation.
- `polygon.rs`: Provides polygon-specific helpers centered on convexity testing and ear-clipping triangulation.
- `random.rs`: Wraps `fastrand` in a deterministic, serializable RNG API that matches engine and Lua expectations.
- `rect.rs`: Provides axis-aligned rectangles for overlap, containment, and intersection queries used across gameplay and rendering code.
- `rect_packing.rs`: - Shelf-first rectangle packing for texture atlas layout.
- `spatial_hash.rs`: Implements a uniform-grid broad-phase index for fast rectangle, circle, and segment spatial queries.
- `sphere.rs`: Spherical math helpers used by `src/globe/`.
- `spline.rs`: Interpolating and approximating splines: Catmull-Rom and Hermite.
- `transform.rs`: Wraps `Mat3` in a mutable 2D transform object with chainable translate, rotate, scale, and shear operations.
- `tween.rs`: Implements low-level numeric interpolation over one or more values and explicitly stays below the higher-level `src/tween/` feature system.
- `vec2.rs`: Defines the engine's primary 2D vector type and common arithmetic, direction, interpolation, and geometric helpers.
- `vec3.rs`: 3D floating-point vector with arithmetic operators and common helpers.
- `voronoi.rs`: Voronoi tessellation from a set of 2-D seed points.

## Types

- `AabbEntry` (`struct`, `aabb_tree.rs`): A single entry stored at a leaf node of the AABB tree.
- `AabbTree` (`struct`, `aabb_tree.rs`): A dynamic bounding-volume hierarchy for efficient AABB overlap queries.
- `BezierCurve` (`struct`, `bezier.rs`): Editable Bezier curve object for path sampling, tangents, and authorable curve manipulation. It supports both math-heavy tooling and Lua scripting use cases.
- `Circle` (`struct`, `circle.rs`): A circle defined by its centre and radius.
- `Color` (`struct`, `color.rs`): Shared RGBA value type for color transport across rendering-facing APIs. It keeps color conversion logic out of renderer-specific code.
- `Mat3` (`struct`, `mat3.rs`): Affine 2D matrix for transform composition and point mapping. Higher-level transform code builds on this instead of rolling custom matrix math.
- `DistType` (`enum`, `noise_generator.rs`): Selects the distance metric used by Worley noise queries. This lets callers choose the visual character of cellular patterns without changing generator internals.
- `NoiseKind` (`enum`, `noise_generator.rs`): Selects the base noise family for generator and fractal operations. It keeps algorithm switching explicit at call sites.
- `FractalType` (`enum`, `noise_generator.rs`): Selects how multiple octaves are combined when generating layered noise. It distinguishes smooth FBM from ridged or turbulence-style outputs.
- `MapGenOptions` (`struct`, `noise_generator.rs`): Bundles the parameters for 2D map generation into one stable config object. It prevents wide argument lists in higher-level generation code.
- `NoiseGenerator` (`struct`, `noise_generator.rs`): Seeded procedural noise engine with multiple algorithms and fractal modes. It centralizes world-generation style noise work instead of scattering implementations.
- `RandomGenerator` (`struct`, `random.rs`): Deterministic RNG wrapper with seed and state control. It exists so engine code and Lua scripts can reproduce runs reliably.
- `Rect` (`struct`, `rect.rs`): Axis-aligned rectangle for cheap containment and overlap checks. It is the basic AABB type used by layout and collision-adjacent code.
- `PackedRect` (`struct`, `rect_packing.rs`): Placement record produced by runtime rectangle packing.
- `RectPacker` (`struct`, `rect_packing.rs`): Deterministic shelf-based runtime rectangle packer for atlas/UI layout.
- `SpatialItem` (`struct`, `spatial_hash.rs`): Stored record for an object indexed by `SpatialHash`. It keeps the query structure decoupled from any particular gameplay object type.
- `SpatialHash` (`struct`, `spatial_hash.rs`): Broad-phase query structure for coarse spatial lookup by AABB, circle, or segment. It is a utility index, not a full collision or physics system.
- `Mat3x3` (`struct`, `sphere.rs`): Column-major 3Ã—3 rotation matrix, used for camera orbit and axial tilt.
- `CatmullRomSpline` (`struct`, `spline.rs`): A Catmull-Rom spline through a sequence of control points.
- `HermiteSpline` (`struct`, `spline.rs`): A cubic Hermite spline segment defined by two endpoints and their tangents.
- `Transform` (`struct`, `transform.rs`): Mutable 2D transform object that exposes a script-friendly API over `Mat3`. It is the ergonomic surface for composition and point conversion.
- `TweenValue` (`struct`, `tween.rs`): Holds one start-target numeric pair inside a low-level tween. It is intentionally minimal and exists mainly to support `Tween`.
- `Tween` (`struct`, `tween.rs`): Low-level multi-channel numeric interpolator driven by easing functions and an internal clock. It does not own callbacks, sequences, or property animation workflows.
- `Vec2` (`struct`, `vec2.rs`): Core 2D vector used pervasively for positions, directions, offsets, and interpolation. It is the default math currency for most engine subsystems.
- `Vec3` (`struct`, `vec3.rs`): A 3D floating-point vector.
- `VoronoiCell` (`struct`, `voronoi.rs`): One cell of a Voronoi diagram.

## Functions

- `AabbTree::new` (`aabb_tree.rs`): Construct an empty AABB tree with no entries.
- `AabbTree::insert` (`aabb_tree.rs`): Insert or replace entry `id` with the given AABB, refitting the tree upward.
- `AabbTree::remove` (`aabb_tree.rs`): Remove entry `id`; returns `true` when the entry existed.
- `AabbTree::query` (`aabb_tree.rs`): Return ids of all entries whose AABB overlaps the given query box.
- `AabbTree::query_point` (`aabb_tree.rs`): Return ids of all entries whose AABB contains the point (x, y).
- `AabbTree::query_circle` (`aabb_tree.rs`): Return ids of all entries whose AABB overlaps the circle, verified with exact circle test.
- `AabbTree::query_segment` (`aabb_tree.rs`): Return ids of all entries whose AABB overlaps the segment, verified with exact slab test.
- `AabbTree::update` (`aabb_tree.rs`): Remove and re-insert entry `id` with updated bounds; returns `false` when id is not present.
- `AabbTree::contains` (`aabb_tree.rs`): Return true when entry `id` is currently stored in this tree.
- `AabbTree::len` (`aabb_tree.rs`): Return the number of entries currently stored.
- `AabbTree::is_empty` (`aabb_tree.rs`): Return true when the tree contains no entries.
- `AabbTree::clear` (`aabb_tree.rs`): Remove all entries and reset the node pool.
- `BezierCurve::new` (`bezier.rs`): Construct a Bézier curve from `points`; panics when fewer than 2 are supplied.
- `BezierCurve::evaluate` (`bezier.rs`): Evaluate the curve at parameter `t` (clamped to `[0,1]`) using Bernstein basis.
- `BezierCurve::render` (`bezier.rs`): Sample the full curve at `segments+1` evenly spaced parameter values.
- `BezierCurve::render_segment` (`bezier.rs`): Sample the curve between `t_start` and `t_end` at `segments+1` evenly spaced values.
- `BezierCurve::get_derivative` (`bezier.rs`): Return the first derivative curve as a new `BezierCurve` with degree reduced by one.
- `BezierCurve::get_control_point` (`bezier.rs`): Return the control point at `index`, or `None` when out of range.
- `BezierCurve::set_control_point` (`bezier.rs`): Set control point at `index`; returns `false` when out of range.
- `BezierCurve::insert_control_point` (`bezier.rs`): Insert `point` at `index`, or append when `index` is `None` or out of range.
- `BezierCurve::remove_control_point` (`bezier.rs`): Remove the control point at `index`; returns `false` when fewer than 3 points remain or index is out of range.
- `BezierCurve::get_control_point_count` (`bezier.rs`): Return the number of control points.
- `BezierCurve::translate` (`bezier.rs`): Translate all control points by `(dx, dy)`.
- `BezierCurve::rotate` (`bezier.rs`): Rotate all control points by `angle` radians around origin `(ox, oy)`.
- `BezierCurve::scale` (`bezier.rs`): Scale all control points by factor `s` relative to origin `(ox, oy)`.
- `BezierCurve::length` (`bezier.rs`): Return the approximate arc length via 100-sample numeric integration.
- `BezierCurve::get_interpolated_position` (`bezier.rs`): Return the evaluated point as `(x, y)` at parameter `t`.
- `BezierCurve::evaluate_at_distance` (`bezier.rs`): Return the point at arc-length `distance` from t=0 via `samples`-step linear walk.
- `BezierCurve::get_interpolated_angle` (`bezier.rs`): Return the tangent angle in radians at parameter `t` using the derivative curve.
- `Circle::new` (`circle.rs`): Construct a Circle; radius is clamped to >= 0.
- `Circle::center` (`circle.rs`): Return the center as a Vec2.
- `Circle::area` (`circle.rs`): Return π × r².
- `Circle::perimeter` (`circle.rs`): Return 2 × π × r.
- `Circle::contains` (`circle.rs`): Return true when `(px, py)` lies inside or on the boundary of this circle.
- `Circle::intersects` (`circle.rs`): Return true when this circle and `other` overlap (touching counts as intersection).
- `Circle::aabb` (`circle.rs`): Return the axis-aligned bounding box as `(min_x, min_y, max_x, max_y)`.
- `Color::new` (`color.rs`): Construct a Color from four f32 components.
- `Color::from_u8` (`color.rs`): Construct a Color from four u8 components, normalising each to [0, 1].
- `Color::to_u8` (`color.rs`): Return the four components as clamped u8 values (r, g, b, a).
- `Color::to_rgb_u32` (`color.rs`): Return the color packed as a 24-bit RGB u32 (alpha discarded).
- `Color::from_hex` (`color.rs`): Parse a hex color string (`#RRGGBB` or `#RRGGBBAA`); returns None on parse failure.
- `Color::to_hsl` (`color.rs`): Return this color converted to `(hue_degrees, saturation, lightness)` tuple.
- `hsv_to_rgb` (`color.rs`): Convert an HSV color to RGB byte components.
- `gamma_to_linear` (`color.rs`): Convert a single sRGB gamma-space color component to linear space.
- `linear_to_gamma` (`color.rs`): Convert a single linear-space color component to sRGB gamma space.
- `hsl_to_rgb` (`color.rs`): Convert an HSL color to a `Color` (alpha defaults to 1.0).
- `linear` (`easing.rs`): Linear interpolation — no easing.
- `ease_in_quad` (`easing.rs`): Quadratic ease-in — starts slow, accelerates.
- `ease_out_quad` (`easing.rs`): Quadratic ease-out — starts fast, decelerates.
- `ease_in_out_quad` (`easing.rs`): Quadratic ease-in-out — slow start and end, fast middle.
- `ease_in_cubic` (`easing.rs`): Cubic ease-in — starts slow, accelerates sharply.
- `ease_out_cubic` (`easing.rs`): Cubic ease-out — starts fast, decelerates sharply.
- `ease_in_out_cubic` (`easing.rs`): Cubic ease-in-out — smooth S-curve.
- `ease_in_quart` (`easing.rs`): Quartic ease-in — very slow start.
- `ease_out_quart` (`easing.rs`): Quartic ease-out — very slow end.
- `ease_in_out_quart` (`easing.rs`): Quartic ease-in-out — pronounced S-curve.
- `ease_in_sine` (`easing.rs`): Sinusoidal ease-in — gentle sine-based acceleration.
- `ease_out_sine` (`easing.rs`): Sinusoidal ease-out — gentle sine-based deceleration.
- `ease_in_out_sine` (`easing.rs`): Sinusoidal ease-in-out — gentle S-curve.
- `ease_in_expo` (`easing.rs`): Exponential ease-in — very slow start, rapid acceleration.
- `ease_out_expo` (`easing.rs`): Exponential ease-out — rapid start, very slow end.
- `ease_in_out_expo` (`easing.rs`): Exponential ease-in-out — sharp S-curve with exponential tails.
- `ease_in_elastic` (`easing.rs`): Elastic ease-in — spring-like overshoot at the start.
- `ease_out_elastic` (`easing.rs`): Elastic ease-out — spring-like overshoot at the end.
- `ease_in_out_elastic` (`easing.rs`): Elastic ease-in-out — spring-like overshoot at both ends.
- `ease_out_bounce` (`easing.rs`): Bounce ease-out — simulates a bouncing ball landing.
- `ease_in_bounce` (`easing.rs`): Bounce ease-in — simulates a bouncing ball launching.
- `ease_in_out_bounce` (`easing.rs`): Bounce ease-in-out — bouncing at both ends.
- `ease_in_back` (`easing.rs`): Back ease-in — pulls back before accelerating past the start.
- `ease_out_back` (`easing.rs`): Back ease-out — overshoots the target then settles back.
- `ease_in_out_back` (`easing.rs`): Back ease-in-out — pulls back at start, overshoots at end.
- `apply` (`easing.rs`): Looks up an easing function by name and applies it to progress value `t`.
- `resolve_easing_fn` (`easing.rs`): Return the function pointer for a named easing function; returns None when unrecognised.
- `lerp` (`facade.rs`): Linear interpolation between `a` and `b` by factor `t` in [0, 1].
- `remap` (`facade.rs`): Remap `v` from `[in_min, in_max]` to `[out_min, out_max]`.
- `clamp` (`facade.rs`): Clamp `v` to the range `[min, max]`.
- `sign` (`facade.rs`): Returns the sign of `v`: `1.0` if positive, `-1.0` if negative, `0.0` if zero.
- `smoothstep` (`facade.rs`): Hermite smooth interpolation between 0 and 1 when `x` is in `[edge0, edge1]`.
- `inverse_lerp` (`facade.rs`): Inverse linear interpolation: returns the `t` factor such that `lerp(a, b, t) ≈ v`.
- `angle_between` (`geometry.rs`): Returns the angle in radians from (x1, y1) to (x2, y2).
- `circle_contains_point` (`geometry.rs`): Returns true if the point (px, py) is inside the circle centered at (cx, cy) with radius r.
- `circle_intersects_circle` (`geometry.rs`): Returns true if two circles overlap.
- `circle_intersects_line` (`geometry.rs`): Line-circle intersection.
- `circle_intersects_segment` (`geometry.rs`): Segment-circle intersection.
- `polygon_area` (`geometry.rs`): Computes the signed area of a polygon using the Shoelace formula.
- `polygon_centroid` (`geometry.rs`): Computes the centroid of a polygon.
- `segment_intersects_segment` (`geometry.rs`): Tests if two line segments intersect.
- `closest_point_on_segment` (`geometry.rs`): Returns the closest point on a line segment to a given point.
- `point_in_polygon` (`geometry.rs`): Tests if a point is inside a polygon using the ray casting algorithm.
- `line_intersect` (`geometry.rs`): Infinite line intersection.
- `bresenham` (`geometry.rs`): Bresenham line rasterization from (x1, y1) to (x2, y2).
- `convex_hull` (`geometry.rs`): Computes the convex hull of a set of 2D points using Andrew's monotone chain algorithm.
- `delaunay_triangulate` (`geometry.rs`): Delaunay triangulation using the Bowyer-Watson algorithm.
- `Mat3::identity` (`mat3.rs`): Return the 3×3 identity matrix.
- `Mat3::from_row_major` (`mat3.rs`): Construct from a flat row-major 9-element slice.
- `Mat3::from_translation` (`mat3.rs`): Construct a pure translation matrix for offset `t`.
- `Mat3::from_rotation` (`mat3.rs`): Construct a pure rotation matrix for the given `angle` in radians.
- `Mat3::from_shear` (`mat3.rs`): Construct a shear matrix with horizontal factor `kx` and vertical factor `ky`.
- `Mat3::from_scale` (`mat3.rs`): Construct a non-uniform scale matrix from `scale`.
- `Mat3::inverse` (`mat3.rs`): Return the matrix inverse; returns identity when the determinant is near zero.
- `Mat3::transform_point` (`mat3.rs`): Apply this affine transform to a 2D point `p` and return the transformed point.
- `fade` (`noise_functions.rs`): Quintic fade curve for smooth interpolation: 6t^5 - 15t^4 + 10t^3.
- `perlin2d` (`noise_functions.rs`): Generates 2D Perlin noise at the given coordinates.
- `perlin3d` (`noise_functions.rs`): Generates 3D Perlin noise at the given coordinates.
- `perlin4d` (`noise_functions.rs`): Generates 4D Perlin noise at the given coordinates.
- `simplex2d` (`noise_functions.rs`): Generates 2D Simplex noise at the given coordinates.
- `simplex_noise_2d` (`noise_functions.rs`): Returns 2D simplex noise for the given coordinates using seed 0.
- `simplex_noise_3d` (`noise_functions.rs`): Returns 3D simplex noise for the given coordinates using seed 0.
- `fbm` (`noise_functions.rs`): Generates fractal Brownian motion noise by layering multiple octaves of Perlin noise.
- `NoiseGenerator::new` (`noise_generator.rs`): Construct a generator from `seed`, immediately building its permutation table.
- `NoiseGenerator::set_seed` (`noise_generator.rs`): Replace the current seed and rebuild the permutation table.
- `NoiseGenerator::seed` (`noise_generator.rs`): Return the current seed value.
- `NoiseGenerator::perlin_1d` (`noise_generator.rs`): Return 1-D Perlin noise in approximately `[-1, 1]`.
- `NoiseGenerator::perlin_2d` (`noise_generator.rs`): Return 2-D Perlin noise in approximately `[-1, 1]`.
- `NoiseGenerator::perlin_3d` (`noise_generator.rs`): Return 3-D Perlin noise in approximately `[-1, 1]`.
- `NoiseGenerator::perlin_4d` (`noise_generator.rs`): Return 4-D Perlin noise in approximately `[-1, 1]` via 16-corner trilinear interpolation.
- `NoiseGenerator::simplex_1d` (`noise_generator.rs`): Return 1-D Simplex noise in approximately `[-1, 1]`.
- `NoiseGenerator::simplex_2d` (`noise_generator.rs`): Return 2-D Simplex noise in approximately `[-1, 1]`.
- `NoiseGenerator::simplex_3d` (`noise_generator.rs`): Return 3-D Simplex noise in approximately `[-1, 1]`.
- `NoiseGenerator::worley_2d` (`noise_generator.rs`): Return 2-D Worley (cell) noise using `dist` metric; returns F2-F1 when `f2` is true.
- `NoiseGenerator::worley_3d` (`noise_generator.rs`): Return 3-D Worley (cell) noise using `dist` metric; returns F2-F1 when `f2` is true.
- `NoiseGenerator::fbm` (`noise_generator.rs`): Return amplitude-normalised fBm noise summing `octaves` layers of `kind`.
- `NoiseGenerator::ridged` (`noise_generator.rs`): Return amplitude-normalised ridged multifractal noise summing `octaves` inverted absolute layers.
- `NoiseGenerator::turbulence` (`noise_generator.rs`): Return amplitude-normalised turbulence noise summing `octaves` absolute-value layers.
- `NoiseGenerator::warp_domain` (`noise_generator.rs`): Apply domain warping using Perlin offsets, returning the displaced coordinate pair.
- `NoiseGenerator::generate_map` (`noise_generator.rs`): Generate a `width × height` heightmap using `opts`; returns row-major `f64` values in `[-1, 1]`.
- `NoiseGenerator::generate_map_compute` (`noise_generator.rs`): Alias for `generate_map`; future versions may dispatch to a compute shader.
- `triangulate` (`polygon.rs`): Triangulate a simple polygon using the ear-clipping algorithm.
- `is_convex` (`polygon.rs`): Check if a polygon is convex.
- `polygon_clip` (`polygon.rs`): Clip a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
- `polygon_intersection` (`polygon.rs`): Clips polygon `subject` against the convex polygon `clip` using the Sutherland-Hodgman algorithm and returns the intersection region.
- `polygon_union` (`polygon.rs`): Returns an approximation of the union of two convex polygons by computing the convex hull of all their vertices.
- `polygon_difference` (`polygon.rs`): Returns an approximation of the difference `A - B` by clipping `A` against the **reversed** edges of `B` (i.e.
- `RandomGenerator::new` (`random.rs`): Construct a generator with an arbitrary unseeded initial state (seed stored as 0).
- `RandomGenerator::with_seed` (`random.rs`): Construct a generator from an explicit `seed`.
- `RandomGenerator::random` (`random.rs`): Return a uniform random `f64` in `[0.0, 1.0)`.
- `RandomGenerator::random_int` (`random.rs`): Return a uniform random integer in the closed range `[min, max]`; returns `min` when `min >= max`.
- `RandomGenerator::random_float` (`random.rs`): Return a uniform random `f64` in `[min, max)`.
- `RandomGenerator::random_normal` (`random.rs`): Return a Gaussian-distributed `f64` with `mean` and `stddev` using Box-Muller transform.
- `RandomGenerator::set_seed` (`random.rs`): Re-seed the generator, resetting both the stored seed and the RNG state.
- `RandomGenerator::get_seed` (`random.rs`): Return the seed last set via `with_seed` or `set_seed`.
- `RandomGenerator::get_state` (`random.rs`): Serialise the current seed to a string for save-file persistence.
- `RandomGenerator::set_state` (`random.rs`): Restore the seed from a previously serialised state string; returns error on parse failure.
- `Rect::new` (`rect.rs`): Construct a Rect from top-left position and size.
- `Rect::center` (`rect.rs`): Return the center point of this rectangle.
- `Rect::area` (`rect.rs`): Return the area (width × height).
- `Rect::contains` (`rect.rs`): Return true when `(point_x, point_y)` lies inside or on the boundary of this rect.
- `Rect::intersects` (`rect.rs`): Return true when this rect overlaps `other` (touching edges count as overlap).
- `Rect::intersect` (`rect.rs`): Return the overlapping region of `self` and `other`; returns zero-size rect when disjoint.
- `Rect::union` (`rect.rs`): Return the smallest rect that contains both `self` and `other`.
- `Rect::from_center` (`rect.rs`): Construct a rect centered at `(cx, cy)` with given `w` and `h`.
- `Rect::from_points` (`rect.rs`): Return the tight bounding rect around a slice of `(x, y)` points; returns zero rect for empty slice.
- `RectPacker::new` (`rect_packing.rs`): Construct a packer with the given atlas `width × height` and uniform `padding`.
- `RectPacker::pack` (`rect_packing.rs`): Place a `w × h` rectangle with optional `id` label; returns placement or `None` when no space remains.
- `RectPacker::clear` (`rect_packing.rs`): Remove all placed rects and reset shelves, keeping atlas dimensions unchanged.
- `RectPacker::packed_rects` (`rect_packing.rs`): Return a slice of all successfully placed rects in insertion order.
- `RectPacker::occupancy` (`rect_packing.rs`): Return the fraction `[0,1]` of the atlas area covered by placed rects, excluding padding.
- `RectPacker::size` (`rect_packing.rs`): Return the atlas dimensions as `(width, height)` in pixels.
- `RectPacker::padding` (`rect_packing.rs`): Return the uniform padding value used during packing.
- `SpatialHash::new` (`spatial_hash.rs`): Construct an empty hash with the given uniform `cell_size`.
- `SpatialHash::cell_size` (`spatial_hash.rs`): Return the world-space cell size.
- `SpatialHash::item_count` (`spatial_hash.rs`): Return the number of items currently registered.
- `SpatialHash::insert` (`spatial_hash.rs`): Register or replace item `id` with AABB `(x, y, w, h)`, inserting it into all overlapping cells.
- `SpatialHash::remove` (`spatial_hash.rs`): Remove item `id` from all grid cells and delete it.
- `SpatialHash::update` (`spatial_hash.rs`): Replace item `id`'s AABB; equivalent to `insert` (re-registers in new cells).
- `SpatialHash::clear` (`spatial_hash.rs`): Remove all items and clear all cell buckets.
- `SpatialHash::query_rect` (`spatial_hash.rs`): Return ids of all items whose AABB overlaps the query rectangle, deduplicated.
- `SpatialHash::query_circle` (`spatial_hash.rs`): Return ids of all items whose AABB overlaps the circle, verified by nearest-point distance.
- `SpatialHash::query_segment` (`spatial_hash.rs`): Return ids of all items whose AABB the segment (x1,y1)-(x2,y2) passes through, using a slab test.
- `Mat3x3::identity` (`sphere.rs`): Return the identity matrix.
- `Mat3x3::from_cols` (`sphere.rs`): Construct a matrix from three column arrays.
- `Mat3x3::mul_vec` (`sphere.rs`): Multiply this matrix by column vector `v`.
- `Mat3x3::mul_mat` (`sphere.rs`): Return the product of this matrix and `other`.
- `lat_lon_to_unit` (`sphere.rs`): Convert (latitude_deg, longitude_deg) on the unit sphere to a 3D unit vector.
- `unit_to_lat_lon` (`sphere.rs`): Inverse of `lat_lon_to_unit`.
- `great_circle_distance` (`sphere.rs`): Great-circle distance in radians between two lat/lon points on a unit sphere.
- `great_circle_path` (`sphere.rs`): Sample `n` points along the great circle between two lat/lon endpoints.
- `ray_sphere_intersect` (`sphere.rs`): Rayâ€“sphere intersection.
- `axial_tilt_mat` (`sphere.rs`): Rotation matrix around the X axis (axial-tilt convention).
- `rot_x` (`sphere.rs`): Rotation about the X axis by `angle_deg` degrees.
- `rot_y` (`sphere.rs`): Rotation about the Y axis (longitude / orbit yaw) by `angle_deg` degrees.
- `rot_z` (`sphere.rs`): Rotation about the Z axis by `angle_deg` degrees.
- `CatmullRomSpline::new` (`spline.rs`): Construct a spline from a Vec of `(x, y)` control points.
- `CatmullRomSpline::sample` (`spline.rs`): Sample the full spline at normalized parameter `t` in `[0,1]`, mapping to the appropriate segment.
- `CatmullRomSpline::sample_segment` (`spline.rs`): Sample segment `seg` at local parameter `t` in `[0,1]` using 4-point Catmull-Rom weights.
- `CatmullRomSpline::len` (`spline.rs`): Return the number of control points.
- `CatmullRomSpline::is_empty` (`spline.rs`): Return true when the spline has no control points.
- `CatmullRomSpline::add_point` (`spline.rs`): Append a control point to the end of the spline.
- `CatmullRomSpline::remove_point` (`spline.rs`): Remove and return the control point at `index`, or `None` when out of range.
- `HermiteSpline::new` (`spline.rs`): Construct a Hermite segment from endpoints `p0`, `p1` and tangents `m0`, `m1`.
- `HermiteSpline::sample` (`spline.rs`): Sample the segment at `t` in `[0,1]` using Hermite basis polynomials.
- `Transform::new` (`transform.rs`): Return an identity transform.
- `Transform::from_components` (`transform.rs`): Construct a transform from position, rotation, scale, origin offset, and shear components.
- `Transform::translate` (`transform.rs`): Post-multiply a translation by `(dx, dy)` and return `&mut self` for chaining.
- `Transform::rotate` (`transform.rs`): Post-multiply a rotation by `angle` radians and return `&mut self` for chaining.
- `Transform::scale` (`transform.rs`): Post-multiply a non-uniform scale by `(sx, sy)` and return `&mut self` for chaining.
- `Transform::shear` (`transform.rs`): Post-multiply a shear by `(kx, ky)` and return `&mut self` for chaining.
- `Transform::reset` (`transform.rs`): Reset to identity and return `&mut self` for chaining.
- `Transform::set_transformation` (`transform.rs`): Replace this transform with a fresh one built from the given SRT+origin+shear components.
- `Transform::transform_point` (`transform.rs`): Apply this transform to `(x, y)` and return the resulting point.
- `Transform::inverse_transform_point` (`transform.rs`): Apply the inverse of this transform to `(x, y)` and return the resulting point.
- `Transform::inverse` (`transform.rs`): Return a new transform that is the matrix inverse of this one.
- `Transform::matrix` (`transform.rs`): Return a reference to the underlying Mat3.
- `Transform::decompose` (`transform.rs`): Decompose into `(tx, ty, rotation_rad, sx, sy)`; shear is not separated.
- `Tween::new` (`tween.rs`): Create a new Tween with the given `duration` (seconds) and named easing; falls back to linear when name is unknown.
- `Tween::add_value` (`tween.rs`): Register a `(start, target)` channel and return its index.
- `Tween::update` (`tween.rs`): Advance the clock by `dt` seconds; returns true when the tween has completed.
- `Tween::get_value` (`tween.rs`): Return the interpolated value for channel `index`; returns 0.0 for out-of-range index.
- `Tween::get_all_values` (`tween.rs`): Return interpolated values for all registered channels.
- `Tween::reset` (`tween.rs`): Reset the clock to zero without clearing channels.
- `Tween::set_time` (`tween.rs`): Set the clock to a specific time `t`, clamped to `[0, duration]`.
- `Tween::is_complete` (`tween.rs`): Return true when the clock has reached or passed the duration.
- `Tween::value_count` (`tween.rs`): Return the number of registered value channels.
- `Tween::easing_name` (`tween.rs`): Return the easing name string this tween was constructed with.
- `Tween::duration` (`tween.rs`): Return the total duration in seconds.
- `Tween::clock` (`tween.rs`): Return the current elapsed clock time in seconds.
- `Vec2::new` (`vec2.rs`): Construct a new Vec2 from `x` and `y` components.
- `Vec2::zero` (`vec2.rs`): Return the zero vector; alias for `Vec2::ZERO`.
- `Vec2::splat` (`vec2.rs`): Construct a Vec2 with both components set to `v`.
- `Vec2::dot` (`vec2.rs`): Return the dot product of `self` and `other`.
- `Vec2::length` (`vec2.rs`): Return the Euclidean length of this vector.
- `Vec2::length_squared` (`vec2.rs`): Return the squared length; cheaper than `length()` when only comparison is needed.
- `Vec2::normalize` (`vec2.rs`): Return a unit-length copy; returns self unchanged when length is zero.
- `Vec2::distance` (`vec2.rs`): Return the Euclidean distance from `self` to `other`.
- `Vec2::lerp` (`vec2.rs`): Linearly interpolate from `self` to `other` by scalar `t`.
- `Vec2::angle` (`vec2.rs`): Return the angle of this vector in radians (atan2 of y over x).
- `Vec2::rotate` (`vec2.rs`): Return this vector rotated by `angle` radians counter-clockwise.
- `Vec2::perpendicular` (`vec2.rs`): Return the left-perpendicular vector (-y, x).
- `Vec2::cross` (`vec2.rs`): Return the 2D cross product (scalar z-component of the 3D cross product).
- `Vec2::from_angle` (`vec2.rs`): Return a unit direction vector for the given angle in radians.
- `Vec2::reflect` (`vec2.rs`): Return this vector reflected across a surface with the given unit `normal`.
- `Vec3::new` (`vec3.rs`): Construct a Vec3 from `x`, `y`, `z`.
- `Vec3::zero` (`vec3.rs`): Return the zero vector (0, 0, 0).
- `Vec3::one` (`vec3.rs`): Return the unit vector (1, 1, 1).
- `Vec3::splat` (`vec3.rs`): Construct a Vec3 with all components set to `v`.
- `Vec3::dot` (`vec3.rs`): Return the dot product of `self` and `other`.
- `Vec3::cross` (`vec3.rs`): Return the cross product of `self` × `other`.
- `Vec3::length` (`vec3.rs`): Return the Euclidean length of this vector.
- `Vec3::length_squared` (`vec3.rs`): Return the squared length; avoids a sqrt when only comparison is needed.
- `Vec3::normalize` (`vec3.rs`): Return a unit-length copy; returns zero vector when length is below 1e-7.
- `Vec3::lerp` (`vec3.rs`): Linearly interpolate from `self` to `other` by factor `t`.
- `Vec3::distance` (`vec3.rs`): Return the Euclidean distance from `self` to `other`.
- `Vec3::project` (`vec3.rs`): Return the projection of `self` onto `onto`; returns zero vector when `onto` is near-zero.
- `Vec3::reflect` (`vec3.rs`): Return this vector reflected across a surface with the given unit `normal`.
- `voronoi_from_points` (`voronoi.rs`): Compute the Voronoi diagram for `points`.

## Lua API Reference

- Binding path(s): `src/lua_api/math_api.rs`
- Namespace: `lurek.math`

### Module Functions
- `lurek.math.newRandomGenerator`: Creates a deterministic random generator with an optional seed.
- `lurek.math.newTransform`: Creates an identity transform or a transform from optional components.
- `lurek.math.newBezierCurve`: Creates a Bezier curve from a flat point table.
- `lurek.math.newTween`: Creates a tween with a duration and optional easing name.
- `lurek.math.newSpatialHash`: Creates a spatial hash index with a cell size.
- `lurek.math.newNoiseGenerator`: Creates a procedural noise generator with an optional seed.
- `lurek.math.newRectPacker`: Creates a rectangle packer.
- `lurek.math.perlin2d`: Samples stateless 2D Perlin noise.
- `lurek.math.perlin3d`: Samples stateless 3D Perlin noise.
- `lurek.math.simplex2d`: Samples stateless 2D simplex noise.
- `lurek.math.fbm`: Samples stateless fractal Brownian motion noise.
- `lurek.math.applyEasing`: Applies a named easing function to a normalized value.
- `lurek.math.linear`: Applies linear easing.
- `lurek.math.inQuad`: Applies quadratic ease-in.
- `lurek.math.outQuad`: Applies quadratic ease-out.
- `lurek.math.inOutQuad`: Applies quadratic ease-in-out.
- `lurek.math.inCubic`: Applies cubic ease-in.
- `lurek.math.outCubic`: Applies cubic ease-out.
- `lurek.math.inOutCubic`: Applies cubic ease-in-out.
- `lurek.math.inQuart`: Applies quartic ease-in.
- `lurek.math.outQuart`: Applies quartic ease-out.
- `lurek.math.inOutQuart`: Applies quartic ease-in-out.
- `lurek.math.inSine`: Applies sine ease-in.
- `lurek.math.outSine`: Applies sine ease-out.
- `lurek.math.inOutSine`: Applies sine ease-in-out.
- `lurek.math.inExpo`: Applies exponential ease-in.
- `lurek.math.outExpo`: Applies exponential ease-out.
- `lurek.math.inOutExpo`: Applies exponential ease-in-out.
- `lurek.math.inElastic`: Applies elastic ease-in.
- `lurek.math.outElastic`: Applies elastic ease-out.
- `lurek.math.outBounce`: Applies bounce ease-out.
- `lurek.math.inBounce`: Applies bounce ease-in.
- `lurek.math.inBack`: Applies back ease-in.
- `lurek.math.outBack`: Applies back ease-out.
- `lurek.math.inOutElastic`: Applies elastic ease-in-out.
- `lurek.math.inOutBounce`: Applies bounce ease-in-out.
- `lurek.math.inOutBack`: Applies back ease-in-out.
- `lurek.math.triangulate`: Triangulates a flat polygon point table.
- `lurek.math.isConvex`: Returns whether a flat polygon point table is convex.
- `lurek.math.gammaToLinear`: Converts a gamma-space channel to linear space.
- `lurek.math.linearToGamma`: Converts a linear-space channel to gamma space.
- `lurek.math.angleBetween`: Returns the angle between two points.
- `lurek.math.circleContainsPoint`: Returns whether a circle contains a point.
- `lurek.math.circleIntersectsCircle`: Returns whether two circles intersect.
- `lurek.math.circleIntersectsLine`: Returns circle-line intersection state and hit points when present.
- `lurek.math.circleIntersectsSegment`: Returns circle-segment intersection state and hit points when present.
- `lurek.math.closestPointOnSegment`: Returns the closest point on a segment to an input point.
- `lurek.math.convexHull`: Computes the convex hull for a flat point table.
- `lurek.math.delaunayTriangulate`: Computes Delaunay triangles for a flat point table.
- `lurek.math.lineIntersect`: Returns intersection point for two infinite lines when present.
- `lurek.math.pointInPolygon`: Returns whether a point lies inside a polygon.
- `lurek.math.polygonArea`: Computes signed area for a flat polygon point table.
- `lurek.math.polygonCentroid`: Computes the centroid for a flat polygon point table.
- `lurek.math.segmentIntersectsSegment`: Returns whether two segments intersect and their intersection point when present.
- `lurek.math.bresenham`: Returns integer grid points along a Bresenham line.
- `lurek.math.rad`: Converts degrees to radians.
- `lurek.math.deg`: Converts radians to degrees.
- `lurek.math.sin`: Returns sine of an angle.
- `lurek.math.cos`: Returns cosine of an angle.
- `lurek.math.tan`: Returns tangent of an angle.
- `lurek.math.asin`: Returns arcsine of a value.
- `lurek.math.acos`: Returns arccosine of a value.
- `lurek.math.atan`: Returns arctangent or two-argument arctangent.
- `lurek.math.atan2`: Returns two-argument arctangent.
- `lurek.math.sqrt`: Returns square root of a value.
- `lurek.math.abs`: Returns absolute value.
- `lurek.math.floor`: Returns floor of a value.
- `lurek.math.ceil`: Returns ceiling of a value.
- `lurek.math.round`: Returns rounded value.
- `lurek.math.exp`: Returns exponential of a value.
- `lurek.math.log`: Returns natural logarithm or logarithm with a supplied base.
- `lurek.math.pow`: Raises a value to a power.
- `lurek.math.min`: Returns the smallest supplied value.
- `lurek.math.max`: Returns the largest supplied value.
- `lurek.math.fmod`: Returns floating-point remainder.
- `lurek.math.distance`: Returns Euclidean distance between two points.
- `lurek.math.distanceSq`: Returns squared Euclidean distance between two points.
- `lurek.math.random`: Returns a Lua math random value, optionally scaled to one or two bounds.
- `lurek.math.randomInt`: Returns a Lua math random integer in an inclusive range.
- `lurek.math.simplexNoise`: Samples 2D or 3D simplex noise.
- `lurek.math.vec2`: Creates a 2D vector.
- `lurek.math.Vec2`: Creates a 2D vector.
- `lurek.math.vec3`: Creates a 3D vector.
- `lurek.math.Vec3`: Creates a 3D vector.
- `lurek.math.catmullRom`: Creates a Catmull-Rom spline from point tables.
- `lurek.math.hermite`: Creates a Hermite spline from endpoints and tangents.
- `lurek.math.lerp`: Linearly interpolates between two values.
- `lurek.math.remap`: Remaps a value from one range to another.
- `lurek.math.clamp`: Clamps a value to a range.
- `lurek.math.sign`: Returns the sign of a value.
- `lurek.math.smoothstep`: Applies smoothstep interpolation between two edges.
- `lurek.math.inverseLerp`: Returns the interpolation factor of a value between two bounds.
- `lurek.math.hslToRgb`: Converts HSL color values to RGBA channels.
- `lurek.math.fromHex`: Converts a hex color string to RGBA channels.
- `lurek.math.rgbToHsl`: Converts RGB channels to HSL values.
- `lurek.math.rectUnion`: Returns the union rectangle for two rectangles.
- `lurek.math.rectFromCenter`: Creates a rectangle tuple from center coordinates and size.
- `lurek.math.polygonClip`: Clips a flat polygon point table against a plane.
- `lurek.math.aabbTree`: Creates an empty AABB tree.
- `lurek.math.newCircle`: Creates a circle primitive.
- `lurek.math.polygonIntersection`: Returns polygon intersection points for two polygon tables.
- `lurek.math.polygonUnion`: Returns polygon union points for two polygon tables.
- `lurek.math.polygonDifference`: Returns polygon difference points for two polygon tables.
- `lurek.math.voronoi`: Builds Voronoi cells from a polygon-style point table.

### `LAabbTree` Methods
- `LAabbTree:insert`: Inserts an AABB by id.
- `LAabbTree:remove`: Removes an AABB by id.
- `LAabbTree:query`: Queries ids intersecting an AABB.
- `LAabbTree:queryPoint`: Queries ids containing a point.
- `LAabbTree:update`: Updates an AABB by id.
- `LAabbTree:contains`: Returns whether the tree contains an id.
- `LAabbTree:len`: Returns the number of items in the tree.
- `LAabbTree:isEmpty`: Returns whether the tree has no items.
- `LAabbTree:clear`: Clears all items from the tree.
- `LAabbTree:type`: Returns the Lua-visible type name for this AABB tree handle.
- `LAabbTree:typeOf`: Returns whether this AABB tree handle matches a supported type name.

### `LBezierCurve` Methods
- `LBezierCurve:evaluate`: Evaluates this curve at normalized parameter `t`.
- `LBezierCurve:render`: Returns sampled points along this curve.
- `LBezierCurve:getDerivative`: Returns the derivative curve for this Bezier curve.
- `LBezierCurve:getControlPoint`: Returns a control point by one-based index.
- `LBezierCurve:setControlPoint`: Sets a control point by one-based index.
- `LBezierCurve:insertControlPoint`: Inserts a control point, optionally before a one-based index.
- `LBezierCurve:removeControlPoint`: Removes a control point by one-based index.
- `LBezierCurve:getControlPointCount`: Returns the number of control points in this curve.
- `LBezierCurve:length`: Returns the approximate curve length.
- `LBezierCurve:evaluateAtDistance`: Evaluates this curve at an approximate distance along the curve.
- `LBezierCurve:translate`: Translates all control points.
- `LBezierCurve:rotate`: Rotates all control points around an origin.
- `LBezierCurve:scale`: Scales all control points around an origin.
- `LBezierCurve:type`: Returns the Lua-visible type name for this Bezier curve handle.
- `LBezierCurve:typeOf`: Returns whether this Bezier curve handle matches a supported type name.

### `LCatmullRom` Methods
- `LCatmullRom:sample`: Samples the spline at normalized parameter `t`.
- `LCatmullRom:sampleSegment`: Samples one spline segment at local parameter `t`.
- `LCatmullRom:len`: Returns the number of points in the spline.
- `LCatmullRom:addPoint`: Adds a point to the spline.
- `LCatmullRom:removePoint`: Removes a point by zero-based index and returns its coordinates.
- `LCatmullRom:type`: Returns the Lua-visible type name for this spline handle.
- `LCatmullRom:typeOf`: Returns whether this spline handle matches a supported type name.

### `LCircle` Methods
- `LCircle:area`: Returns this circle area.
- `LCircle:perimeter`: Returns this circle perimeter.
- `LCircle:contains`: Returns whether this circle contains a point.
- `LCircle:intersects`: Returns whether this circle intersects another circle.
- `LCircle:aabb`: Returns this circle axis-aligned bounding box.
- `LCircle:x`: Returns this circle center x coordinate.
- `LCircle:y`: Returns this circle center y coordinate.
- `LCircle:radius`: Returns this circle radius.
- `LCircle:type`: Returns the Lua-visible type name for this circle handle.
- `LCircle:typeOf`: Returns whether this circle handle matches a supported type name.

### `LHermite` Methods
- `LHermite:sample`: Samples the spline at normalized parameter `t`.
- `LHermite:type`: Returns the Lua-visible type name for this spline handle.
- `LHermite:typeOf`: Returns whether this spline handle matches a supported type name.

### `LNoiseGenerator` Methods
- `LNoiseGenerator:perlin1d`: Samples 1D Perlin noise.
- `LNoiseGenerator:perlin2d`: Samples 2D Perlin noise.
- `LNoiseGenerator:perlin3d`: Samples 3D Perlin noise.
- `LNoiseGenerator:perlin4d`: Samples 4D Perlin noise.
- `LNoiseGenerator:simplex1d`: Samples 1D simplex noise.
- `LNoiseGenerator:simplex2d`: Samples 2D simplex noise.
- `LNoiseGenerator:simplex3d`: Samples 3D simplex noise.
- `LNoiseGenerator:worley2d`: Samples 2D Worley noise.
- `LNoiseGenerator:worley3d`: Samples 3D Worley noise.
- `LNoiseGenerator:fbm`: Samples fractal Brownian motion noise.
- `LNoiseGenerator:ridged`: Samples ridged fractal noise.
- `LNoiseGenerator:turbulence`: Samples turbulence fractal noise.
- `LNoiseGenerator:warpDomain`: Samples domain-warped noise coordinates.
- `LNoiseGenerator:generateMap`: Generates a noise map and returns it as a flat array table.
- `LNoiseGenerator:generateMapCompute`: Generates a noise map through the compute backend and returns it as a flat array table.
- `LNoiseGenerator:getSeed`: Returns this noise generator seed.
- `LNoiseGenerator:setSeed`: Sets this noise generator seed.
- `LNoiseGenerator:type`: Returns the Lua-visible type name for this noise generator handle.
- `LNoiseGenerator:typeOf`: Returns whether this noise generator handle matches a supported type name.

### `LRandomGenerator` Methods
- `LRandomGenerator:random`: Returns a random floating-point value from the generator.
- `LRandomGenerator:randomFloat`: Returns a random floating-point value in a range.
- `LRandomGenerator:randomInt`: Returns a random integer in a range.
- `LRandomGenerator:randomNormal`: Returns a normally distributed random value.
- `LRandomGenerator:getSeed`: Returns this generator seed.
- `LRandomGenerator:setSeed`: Resets this generator to a seed value.
- `LRandomGenerator:getState`: Returns this generator serialized state string.
- `LRandomGenerator:setState`: Restores this generator from a serialized state string.
- `LRandomGenerator:type`: Returns the Lua-visible type name for this random generator handle.
- `LRandomGenerator:typeOf`: Returns whether this random generator handle matches a supported type name.

### `LRectPacker` Methods
- `LRectPacker:pack`: Attempts to pack a rectangle and returns its placement coordinates.
- `LRectPacker:clear`: Clears packed rectangles from this packer.
- `LRectPacker:occupancy`: Returns occupied area ratio.
- `LRectPacker:getPacked`: Returns packed rectangle records.

### `LSpatialHash` Methods
- `LSpatialHash:insert`: Inserts an item rectangle into the spatial hash.
- `LSpatialHash:update`: Updates an item rectangle in the spatial hash.
- `LSpatialHash:remove`: Removes an item from the spatial hash.
- `LSpatialHash:clear`: Clears all items from the spatial hash.
- `LSpatialHash:queryRect`: Returns ids intersecting a query rectangle.
- `LSpatialHash:queryCircle`: Returns ids intersecting a query circle.
- `LSpatialHash:querySegment`: Returns ids intersecting a query line segment.
- `LSpatialHash:getCellSize`: Returns the spatial hash cell size.
- `LSpatialHash:getItemCount`: Returns the number of items in the spatial hash.
- `LSpatialHash:type`: Returns the Lua-visible type name for this spatial hash handle.
- `LSpatialHash:typeOf`: Returns whether this spatial hash handle matches a supported type name.

### `LTransform` Methods
- `LTransform:translate`: Applies a translation to this transform.
- `LTransform:rotate`: Applies a rotation to this transform.
- `LTransform:scale`: Applies scale to this transform.
- `LTransform:shear`: Applies shear to this transform.
- `LTransform:reset`: Resets this transform to identity.
- `LTransform:setTransformation`: Replaces this transform from position, rotation, scale, origin, and shear components.
- `LTransform:transformPoint`: Transforms a point by this transform.
- `LTransform:inverseTransformPoint`: Transforms a point by this transform's inverse.
- `LTransform:inverse`: Returns this transform's inverse.
- `LTransform:clone`: Returns a copy of this transform.
- `LTransform:getMatrix`: Returns this transform matrix as a flat array table.
- `LTransform:decompose`: Decomposes this transform into component values.
- `LTransform:type`: Returns the Lua-visible type name for this transform handle.
- `LTransform:typeOf`: Returns whether this transform handle matches a supported type name.

### `LTween` Methods
- `LTween:update`: Advances the tween clock and returns whether it is complete.
- `LTween:reset`: Resets the tween clock to the beginning.
- `LTween:getValue`: Returns one tween value by one-based index or all values when no index is provided.
- `LTween:getAllValues`: Returns all current tween values.
- `LTween:isComplete`: Returns whether this tween is complete.
- `LTween:getValueCount`: Returns the number of values animated by this tween.
- `LTween:getEasingName`: Returns this tween easing function name.
- `LTween:getDuration`: Returns this tween duration.
- `LTween:getTime`: Returns this tween clock time.
- `LTween:getClock`: Returns this tween clock time.
- `LTween:setTime`: Sets this tween clock time.
- `LTween:set`: Sets this tween clock time.
- `LTween:addValue`: Adds a value track to this tween.
- `LTween:type`: Returns the Lua-visible type name for this tween handle.
- `LTween:typeOf`: Returns whether this tween handle matches a supported type name.

### `LVec2` Methods
- `LVec2:dot`: Returns the dot product with another vector.
- `LVec2:length`: Returns this vector length.
- `LVec2:x`: Returns this vector x component.
- `LVec2:y`: Returns this vector y component.
- `LVec2:lengthSquared`: Returns this vector squared length.
- `LVec2:normalize`: Returns a normalized copy of this vector.
- `LVec2:normalized`: Returns a normalized copy of this vector.
- `LVec2:lerp`: Returns a vector interpolated toward another vector.
- `LVec2:distance`: Returns distance to another vector.
- `LVec2:angle`: Returns this vector angle.
- `LVec2:rotate`: Returns this vector rotated by an angle.
- `LVec2:perpendicular`: Returns a perpendicular vector.
- `LVec2:cross`: Returns the scalar 2D cross product with another vector.
- `LVec2:fromAngle`: Creates a unit vector from an angle.
- `LVec2:reflect`: Returns this vector reflected around a normal vector.
- `LVec2:type`: Returns the Lua-visible type name for this vector handle.
- `LVec2:typeOf`: Returns whether this vector handle matches a supported type name.

### `LVec3` Methods
- `LVec3:length`: Returns this vector length.
- `LVec3:lengthSquared`: Returns this vector squared length.
- `LVec3:normalize`: Returns a normalized copy of this vector.
- `LVec3:dot`: Returns the dot product with another vector.
- `LVec3:cross`: Returns the 3D cross product with another vector.
- `LVec3:lerp`: Returns a vector interpolated toward another vector.
- `LVec3:distance`: Returns distance to another vector.
- `LVec3:add`: Returns the sum with another vector.
- `LVec3:sub`: Returns the difference from another vector.
- `LVec3:scale`: Returns this vector multiplied by a scalar.
- `LVec3:splat`: Creates a vector with all components set to one value.
- `LVec3:type`: Returns the Lua-visible type name for this vector handle.
- `LVec3:typeOf`: Returns whether this vector handle matches a supported type name.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/math/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### New in 0.14.1

- `src/math/voronoi.rs` — Bowyer–Watson Delaunay triangulation and Voronoi dual.
  - `VoronoiCell { site: (f32, f32), vertices: Vec<(f32, f32)> }` — one cell per site.
  - `voronoi_from_points(points: &[(f32, f32)]) -> Vec<VoronoiCell>` — near-duplicate deduplication, CCW vertex ordering.
  - Lua: `lurek.math.voronoi({{x,y},…})` → `{{site={x,y}, vertices={{x,y},…}},…}`.
  - Re-exported as `crate::math::VoronoiCell` and `crate::math::voronoi_from_points`.

### New in 0.15.0

**Free functions (scalar utilities)**
- `lurek.math.sign(v)` — Returns `1`, `-1`, or `0` based on the sign of `v`.
- `lurek.math.smoothstep(e0, e1, x)` — Hermite interpolation clamped to `[0, 1]`.
- `lurek.math.inverseLerp(a, b, v)` — Inverse of lerp: returns `t` such that `lerp(a, b, t) == v`.

**Colour utilities**
- `lurek.math.hslToRgb(h, s, l)` — Converts HSL (0–1 range each) to RGBA. Returns `r, g, b, a` (a = 1.0).
- `lurek.math.rgbToHsl(r, g, b)` — Converts RGB to HSL. Returns `h, s, l`.
- `lurek.math.fromHex(hex)` — Parses a hex colour string (`#RRGGBB` or `#RRGGBBAA`). Returns `r, g, b, a` or `nil` on failure.

**Rect constructors**
- `lurek.math.rectUnion(x1, y1, w1, h1, x2, y2, w2, h2)` — Returns the bounding union rect `x, y, w, h`.
- `lurek.math.rectFromCenter(cx, cy, w, h)` — Returns a rect whose centre is `(cx, cy)`, returning `x, y, w, h`.

**Vec2 additions**
- `Vec2.fromAngle(radians)` — Creates a unit Vec2 pointing in the given direction (class function).
- `Vec2:reflect(normal)` — Returns this vector reflected about the given unit normal Vec2.

**Vec3 additions**
- `Vec3.splat(v)` — Creates a Vec3 with all components equal to `v` (class function).

**Transform additions**
- `Transform:decompose()` — Returns five numbers `tx, ty, angle, scale_x, scale_y` extracted from the matrix.

**Easing additions**
- `lurek.math.inOutElastic(t)` — In-out elastic ease. Symmetric: `f(1-t) == 1 - f(t)`.
- `lurek.math.inOutBounce(t)` — In-out bounce ease.
- `lurek.math.inOutBack(t)` — In-out back (overshoot) ease.

**CatmullRomSpline mutations**
- `CatmullRomSpline:addPoint(x, y)` — Appends a control point to the spline.
- `CatmullRomSpline:removePoint(index)` — Removes the control point at the given 1-based index. Out-of-range is a no-op.
