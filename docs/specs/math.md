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

**Noise.** `noise_functions.rs` provides standalone Perlin, Simplex, and FBM helpers. `noise_generator.rs` wraps these in `NoiseGenerator` — a seeded, configurable object with named presets (terrain, cloud, wood grain, marble), domain-warping, fractal layering, and Worley cellular noise. `NoiseField` is the simplified Lua-facing wrapper.

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
- `noise_functions.rs`: Exposes standalone Perlin, Simplex, and FBM helpers for callers that do not need a reusable generator object.
- `noise_generator.rs`: Owns the seeded `NoiseGenerator` and the richer procedural toolset for Perlin, Simplex, Worley, fractal layering, domain warping, and map generation.
- `polygon.rs`: Provides polygon-specific helpers centered on convexity testing and ear-clipping triangulation.
- `random.rs`: Wraps `fastrand` in a deterministic, serializable RNG API that matches engine and Lua expectations.
- `rect.rs`: Provides axis-aligned rectangles for overlap, containment, and intersection queries used across gameplay and rendering code.
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

- `AabbTree::new` (`aabb_tree.rs`): Creates an empty AABB tree.
- `AabbTree::insert` (`aabb_tree.rs`): Inserts an entry with the given AABB into the tree.
- `AabbTree::remove` (`aabb_tree.rs`): Removes the entry with the given `id` from the tree.
- `AabbTree::query` (`aabb_tree.rs`): Returns the ids of all entries whose AABBs overlap the query rectangle.
- `AabbTree::query_point` (`aabb_tree.rs`): Returns the ids of all entries whose AABBs contain the point `(x, y)`.
- `AabbTree::query_circle` (`aabb_tree.rs`): Returns the ids of all entries whose AABBs overlap the given circle.
- `AabbTree::query_segment` (`aabb_tree.rs`): Returns the ids of all entries whose AABBs overlap the line segment from `(x1, y1)` to `(x2, y2)`.
- `AabbTree::update` (`aabb_tree.rs`): - `min_x`, `min_y` — New minimum corner.
- `AabbTree::contains` (`aabb_tree.rs`): Returns `true` if an entry with the given `id` exists in the tree.
- `AabbTree::len` (`aabb_tree.rs`): Returns the number of entries currently in the tree.
- `AabbTree::is_empty` (`aabb_tree.rs`): Returns `true` if the tree contains no entries.
- `AabbTree::clear` (`aabb_tree.rs`): Removes all entries and resets the tree to the empty state.
- `BezierCurve::new` (`bezier.rs`): Create a new Bezier curve from control points.
- `BezierCurve::evaluate` (`bezier.rs`): Evaluate the curve at parameter `t` using De Casteljau's algorithm.
- `BezierCurve::render` (`bezier.rs`): Render the curve as a polyline with the given number of segments.
- `BezierCurve::render_segment` (`bezier.rs`): Render a portion of the curve between `t_start` and `t_end`.
- `BezierCurve::get_derivative` (`bezier.rs`): Compute the derivative curve (one degree lower than the current curve).
- `BezierCurve::get_control_point` (`bezier.rs`): Get a control point by 0-based index.
- `BezierCurve::set_control_point` (`bezier.rs`): Set a control point by 0-based index.
- `BezierCurve::insert_control_point` (`bezier.rs`): Insert a control point at a given index, or append if `index` is `None`.
- `BezierCurve::remove_control_point` (`bezier.rs`): Remove a control point by 0-based index.
- `BezierCurve::get_control_point_count` (`bezier.rs`): Get the number of control points.
- `BezierCurve::translate` (`bezier.rs`): Translate all control points by `(dx, dy)`.
- `BezierCurve::rotate` (`bezier.rs`): Rotate all control points around a pivot `(ox, oy)` by `angle` radians.
- `BezierCurve::scale` (`bezier.rs`): Scale all control points around a pivot `(ox, oy)` by factor `s`.
- `BezierCurve::length` (`bezier.rs`): Approximate the total arc length of the curve.
- `BezierCurve::get_interpolated_position` (`bezier.rs`): Evaluate the curve position at parameter `t` and return it as an `(x, y)` tuple.
- `BezierCurve::get_interpolated_angle` (`bezier.rs`): Return the angle of the curve tangent at parameter `t` in radians.
- `Circle::new` (`circle.rs`): Creates a new `Circle` centred at `(x, y)` with the given `radius`.
- `Circle::center` (`circle.rs`): Returns the centre as a `Vec2`.
- `Circle::area` (`circle.rs`): Returns the area of the circle (`π r²`).
- `Circle::perimeter` (`circle.rs`): Returns the perimeter (circumference) of the circle (`2 π r`).
- `Circle::contains` (`circle.rs`): Returns `true` if the point `(px, py)` lies inside or on the boundary of this circle.
- `Circle::intersects` (`circle.rs`): Returns `true` if this circle overlaps with `other`.
- `Circle::aabb` (`circle.rs`): Returns the axis-aligned bounding box of this circle as `(min_x, min_y, max_x, max_y)`.
- `Color::new` (`color.rs`): Creates a color from `f32` RGBA components in `[0.0, 1.0]`.
- `Color::from_u8` (`color.rs`): Creates a color from `u8` RGBA components in `[0, 255]`, normalizing to `[0.0, 1.0]`.
- `Color::to_u8` (`color.rs`): Converts the color to `u8` RGBA components, each in `[0, 255]`.
- `Color::to_rgb_u32` (`color.rs`): Converts the color to a packed `u32` RGB value suitable for packed pixel buffers.
- `Color::from_hex` (`color.rs`): Creates a color from a hex string such as `"#FF8000"`, `"#FF8000FF"`, or `"FF8000"`.
- `Color::to_hsl` (`color.rs`): Converts the color to HSL (hue, saturation, lightness).
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
- `Mat3::identity` (`mat3.rs`): Returns the 3×3 identity matrix.
- `Mat3::from_row_major` (`mat3.rs`): Creates a `Mat3` from a flat 9-element array in row-major order.
- `Mat3::from_translation` (`mat3.rs`): Creates a translation matrix that moves points by `(t.x, t.y)`.
- `Mat3::from_rotation` (`mat3.rs`): Creates a rotation matrix for a counter-clockwise rotation of `angle` radians.
- `Mat3::from_shear` (`mat3.rs`): Creates a shear (skew) matrix.
- `Mat3::from_scale` (`mat3.rs`): Creates a non-uniform scale matrix with the given per-axis factors.
- `Mat3::inverse` (`mat3.rs`): Compute the inverse of this 3×3 matrix.
- `Mat3::transform_point` (`mat3.rs`): Applies the matrix transform to a 2D point using homogeneous coordinates.
- `lerp` (`mod.rs`): Linear interpolation between `a` and `b` by factor `t` in [0, 1].
- `remap` (`mod.rs`): Remap `v` from `[in_min, in_max]` to `[out_min, out_max]`.
- `clamp` (`mod.rs`): Clamp `v` to the range `[min, max]`.
- `sign` (`mod.rs`): Returns the sign of `v`: `1.0` if positive, `-1.0` if negative, `0.0` if zero.
- `smoothstep` (`mod.rs`): Hermite smooth interpolation between 0 and 1 when `x` is in `[edge0, edge1]`.
- `inverse_lerp` (`mod.rs`): Inverse linear interpolation: returns the `t` factor such that `lerp(a, b, t) ≈ v`.
- `perlin2d` (`noise_functions.rs`): Generates 2D Perlin noise at the given coordinates.
- `simplex2d` (`noise_functions.rs`): Generates 2D Simplex noise at the given coordinates.
- `simplex_noise_2d` (`noise_functions.rs`): Returns 2D simplex noise for the given coordinates using seed 0.
- `simplex_noise_3d` (`noise_functions.rs`): Returns 3D simplex noise for the given coordinates using seed 0.
- `fbm` (`noise_functions.rs`): Generates fractal Brownian motion noise by layering multiple octaves of Perlin noise.
- `fade` (`noise_functions.rs`): Quintic fade curve for smooth interpolation: 6t^5 - 15t^4 + 10t^3.
- `perlin3d` (`noise_functions.rs`): Generates 3D Perlin noise at the given coordinates.
- `perlin4d` (`noise_functions.rs`): Generates 4D Perlin noise at the given coordinates.
- `NoiseGenerator::new` (`noise_generator.rs`): Creates a new generator with the given seed.
- `NoiseGenerator::set_seed` (`noise_generator.rs`): Replaces the seed and rebuilds the permutation table.
- `NoiseGenerator::seed` (`noise_generator.rs`): Returns the current seed.
- `NoiseGenerator::perlin_1d` (`noise_generator.rs`): 1D Perlin noise.
- `NoiseGenerator::perlin_2d` (`noise_generator.rs`): 2D Perlin noise.
- `NoiseGenerator::perlin_3d` (`noise_generator.rs`): 3D Perlin noise.
- `NoiseGenerator::perlin_4d` (`noise_generator.rs`): 4D Perlin noise.
- `NoiseGenerator::simplex_1d` (`noise_generator.rs`): 1D Simplex noise.
- `NoiseGenerator::simplex_2d` (`noise_generator.rs`): 2D Simplex noise.
- `NoiseGenerator::simplex_3d` (`noise_generator.rs`): 3D Simplex noise.
- `NoiseGenerator::worley_2d` (`noise_generator.rs`): 2D Worley (cellular) noise.
- `NoiseGenerator::worley_3d` (`noise_generator.rs`): 3D Worley (cellular) noise.
- `NoiseGenerator::fbm` (`noise_generator.rs`): Fractal Brownian motion — sum of octaves with decreasing amplitude.
- `NoiseGenerator::ridged` (`noise_generator.rs`): Ridged multi-fractal — sharp ridges from `1 - |noise|`.
- `NoiseGenerator::turbulence` (`noise_generator.rs`): Turbulence noise — sum of `|noise|` per octave.
- `NoiseGenerator::warp_domain` (`noise_generator.rs`): Domain warping — offsets the input coordinates by noise, producing organic distortion.
- `NoiseGenerator::generate_map` (`noise_generator.rs`): Generates a 2D noise map of `width * height` values using the given options.
- `triangulate` (`polygon.rs`): Triangulate a simple polygon using the ear-clipping algorithm.
- `is_convex` (`polygon.rs`): Check if a polygon is convex.
- `polygon_clip` (`polygon.rs`): Clip a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
- `polygon_intersection` (`polygon.rs`): Clips polygon `subject` against the convex polygon `clip` using the Sutherland-Hodgman algorithm and returns the intersection region.
- `polygon_union` (`polygon.rs`): Returns an approximation of the union of two convex polygons by computing the convex hull of all their vertices.
- `polygon_difference` (`polygon.rs`): Returns an approximation of the difference `A - B` by clipping `A` against the **reversed** edges of `B` (i.e.
- `RandomGenerator::new` (`random.rs`): Create a new generator with a random seed.
- `RandomGenerator::with_seed` (`random.rs`): Create with a specific seed for deterministic sequences.
- `RandomGenerator::random` (`random.rs`): Sample a uniform random value in `[0.0, 1.0)`.
- `RandomGenerator::random_int` (`random.rs`): Sample a uniform random integer in `[min, max]` (inclusive).
- `RandomGenerator::random_float` (`random.rs`): Sample a uniform random float in `[min, max)`.
- `RandomGenerator::random_normal` (`random.rs`): Random number from normal (Gaussian) distribution using Box-Muller transform.
- `RandomGenerator::set_seed` (`random.rs`): Set the seed, fully resetting the generator state.
- `RandomGenerator::get_seed` (`random.rs`): Get the seed that was used to initialise (or last reset) this generator.
- `RandomGenerator::get_state` (`random.rs`): Serialise the generator state as a string for later restoration.
- `RandomGenerator::set_state` (`random.rs`): Restore the generator state from a previously serialised string.
- `Rect::new` (`rect.rs`): Creates a new `Rect` at `(x, y)` with the given `width` and `height`.
- `Rect::center` (`rect.rs`): Returns the center point of the rectangle.
- `Rect::area` (`rect.rs`): Returns the area of the rectangle.
- `Rect::contains` (`rect.rs`): Returns `true` if the given point lies within or on the boundary of the rectangle.
- `Rect::intersects` (`rect.rs`): Returns `true` if this rectangle overlaps with `other`.
- `Rect::intersect` (`rect.rs`): Computes the rectangle intersection of `self` and `other`.
- `Rect::union` (`rect.rs`): Returns the smallest rectangle that contains both `self` and `other`.
- `Rect::from_center` (`rect.rs`): Creates a rectangle centered at `(cx, cy)` with the given width and height.
- `Rect::from_points` (`rect.rs`): Creates the smallest axis-aligned bounding rectangle that contains all given points.
- `SpatialHash::new` (`spatial_hash.rs`): Creates an empty spatial hash with the given cell size.
- `SpatialHash::cell_size` (`spatial_hash.rs`): Returns the cell size.
- `SpatialHash::item_count` (`spatial_hash.rs`): Returns the number of items in the hash.
- `SpatialHash::insert` (`spatial_hash.rs`): Inserts an item with the given AABB.
- `SpatialHash::remove` (`spatial_hash.rs`): Removes an item by its ID.
- `SpatialHash::update` (`spatial_hash.rs`): Updates an existing item's AABB.
- `SpatialHash::clear` (`spatial_hash.rs`): Removes all items and clears all buckets.
- `SpatialHash::query_rect` (`spatial_hash.rs`): Returns the IDs of all items whose AABBs overlap the query rectangle.
- `SpatialHash::query_circle` (`spatial_hash.rs`): Returns the IDs of all items whose AABBs overlap the query circle.
- `SpatialHash::query_segment` (`spatial_hash.rs`): Returns the IDs of all items whose AABBs are intersected by a line
- `Mat3x3::identity` (`sphere.rs`): 3Ã—3 identity.
- `Mat3x3::from_cols` (`sphere.rs`): Construct from three column vectors.
- `Mat3x3::mul_vec` (`sphere.rs`): Apply this rotation to a `Vec3`: returns `M * v`.
- `Mat3x3::mul_mat` (`sphere.rs`): Matrix product `self * other`.
- `lat_lon_to_unit` (`sphere.rs`): Convert (latitude_deg, longitude_deg) on the unit sphere to a 3D unit vector.
- `unit_to_lat_lon` (`sphere.rs`): Inverse of `lat_lon_to_unit`.
- `great_circle_distance` (`sphere.rs`): Great-circle distance in radians between two lat/lon points on a unit sphere.
- `great_circle_path` (`sphere.rs`): Sample `n` points along the great circle between two lat/lon endpoints.
- `ray_sphere_intersect` (`sphere.rs`): Rayâ€“sphere intersection.
- `axial_tilt_mat` (`sphere.rs`): Rotation matrix around the X axis (axial-tilt convention).
- `rot_x` (`sphere.rs`): Rotation about the X axis by `angle_deg` degrees.
- `rot_y` (`sphere.rs`): Rotation about the Y axis (longitude / orbit yaw) by `angle_deg` degrees.
- `rot_z` (`sphere.rs`): Rotation about the Z axis by `angle_deg` degrees.
- `CatmullRomSpline::new` (`spline.rs`): Create a spline from the given control points.
- `CatmullRomSpline::sample` (`spline.rs`): Sample the spline at a global parameter `t` in [0, 1] spanning the whole curve.
- `CatmullRomSpline::sample_segment` (`spline.rs`): Sample a specific segment by index at local parameter `t` in [0, 1].
- `CatmullRomSpline::len` (`spline.rs`): Number of control points.
- `CatmullRomSpline::is_empty` (`spline.rs`): Returns `true` if there are no control points.
- `CatmullRomSpline::add_point` (`spline.rs`): Appends a control point to the end of the spline.
- `CatmullRomSpline::remove_point` (`spline.rs`): Removes the control point at the given index.
- `HermiteSpline::new` (`spline.rs`): Create a Hermite spline with explicit endpoints and tangents.
- `HermiteSpline::sample` (`spline.rs`): Evaluate the spline at parameter `t` in [0, 1].
- `Transform::new` (`transform.rs`): Create an identity transform (no translation, rotation, or scale).
- `Transform::from_components` (`transform.rs`): Create from full transformation parameters (standard parameter order).
- `Transform::translate` (`transform.rs`): Apply translation to the transform.
- `Transform::rotate` (`transform.rs`): Apply a rotation to the transform.
- `Transform::scale` (`transform.rs`): Apply non-uniform scaling to the transform.
- `Transform::shear` (`transform.rs`): Apply shear to the transform (standard convention).
- `Transform::reset` (`transform.rs`): Reset the transform to the identity matrix.
- `Transform::set_transformation` (`transform.rs`): Replace the current state with full transformation parameters.
- `Transform::transform_point` (`transform.rs`): Transform a point from local space to world space.
- `Transform::inverse_transform_point` (`transform.rs`): Transform a point from world space back to local space.
- `Transform::inverse` (`transform.rs`): Compute the inverse of this transform.
- `Transform::matrix` (`transform.rs`): Get the internal matrix (for renderer integration).
- `Transform::decompose` (`transform.rs`): Decomposes this transform's matrix into translation, rotation, and scale.
- `Tween::new` (`tween.rs`): Creates a new tween with the given duration and easing name.
- `Tween::add_value` (`tween.rs`): Adds a value to interpolate.
- `Tween::update` (`tween.rs`): Advances the clock by `dt` seconds.
- `Tween::get_value` (`tween.rs`): Returns the interpolated value at the given index.
- `Tween::get_all_values` (`tween.rs`): Returns all interpolated values.
- `Tween::reset` (`tween.rs`): Resets the clock to 0.
- `Tween::set_time` (`tween.rs`): Sets the clock to a specific time, clamped to [0, duration].
- `Tween::is_complete` (`tween.rs`): Returns true if the tween has completed.
- `Tween::value_count` (`tween.rs`): Returns the number of values in this tween.
- `Tween::easing_name` (`tween.rs`): Returns the easing name.
- `Tween::duration` (`tween.rs`): Returns the duration.
- `Tween::clock` (`tween.rs`): Returns the current clock time.
- `Vec2::new` (`vec2.rs`): Creates a new vector from `x` and `y` components.
- `Vec2::zero` (`vec2.rs`): Returns the zero vector `(0.0, 0.0)`.
- `Vec2::splat` (`vec2.rs`): Creates a vector with both components set to `v`.
- `Vec2::dot` (`vec2.rs`): Returns the dot product of this vector and `other`.
- `Vec2::length` (`vec2.rs`): Returns the Euclidean length (magnitude) of the vector.
- `Vec2::length_squared` (`vec2.rs`): Returns the squared Euclidean length of the vector.
- `Vec2::normalize` (`vec2.rs`): Returns a unit vector in the same direction, or the original vector if its length is zero.
- `Vec2::distance` (`vec2.rs`): Returns the Euclidean distance between this point and `other`.
- `Vec2::lerp` (`vec2.rs`): Linearly interpolates between `self` and `other` by factor `t`.
- `Vec2::angle` (`vec2.rs`): Returns the angle of the vector in radians, measured from the positive X axis.
- `Vec2::rotate` (`vec2.rs`): Returns a copy of this vector rotated by `angle` radians around the origin.
- `Vec2::perpendicular` (`vec2.rs`): Returns the perpendicular (normal) vector, rotated 90° counter-clockwise.
- `Vec2::cross` (`vec2.rs`): Returns the 2D cross product (perpendicular dot product) with `other`.
- `Vec2::from_angle` (`vec2.rs`): Creates a unit vector from an angle in radians, measured from the positive X axis.
- `Vec2::reflect` (`vec2.rs`): Reflects this vector about a surface normal (normal must be unit length).
- `Vec3::new` (`vec3.rs`): Create a new vector with the given components.
- `Vec3::zero` (`vec3.rs`): The zero vector (0, 0, 0).
- `Vec3::one` (`vec3.rs`): The unit vector (1, 1, 1).
- `Vec3::splat` (`vec3.rs`): Creates a vector with all three components set to `v`.
- `Vec3::dot` (`vec3.rs`): Dot product of this vector and `other`.
- `Vec3::cross` (`vec3.rs`): Cross product of this vector and `other`.
- `Vec3::length` (`vec3.rs`): Euclidean length (magnitude) of this vector.
- `Vec3::length_squared` (`vec3.rs`): Squared Euclidean length.
- `Vec3::normalize` (`vec3.rs`): Returns a unit-length version of this vector, or the zero vector if length is zero.
- `Vec3::lerp` (`vec3.rs`): Linear interpolation between this vector and `other` by factor `t` in [0, 1].
- `Vec3::distance` (`vec3.rs`): Euclidean distance to `other`.
- `Vec3::project` (`vec3.rs`): Project this vector onto `onto`.
- `Vec3::reflect` (`vec3.rs`): Reflect this vector about `normal` (normal must be unit length).
- `voronoi_from_points` (`voronoi.rs`): Compute the Voronoi diagram for `points`.

## Lua API Reference

- Binding path(s): `src/lua_api/math_api.rs`
- Namespace: `lurek.math`

### Module Functions
- `lurek.math.newRandomGenerator`: Creates a new random number generator with an optional seed.
- `lurek.math.newTransform`: Creates a new Transform, optionally initialised from full parameters.
- `lurek.math.newBezierCurve`: Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
- `lurek.math.newTween`: Creates a new Tween with the given duration and easing name.
- `lurek.math.newSpatialHash`: Creates a new SpatialHash with the given cell size.
- `lurek.math.newNoiseGenerator`: Creates a new seeded noise generator.
- `lurek.math.perlin2d`: Returns 2D Perlin noise at (x, y) with the given seed.
- `lurek.math.perlin3d`: Returns 3D Perlin noise at (x, y, z) with the given seed.
- `lurek.math.simplex2d`: Returns 2D Simplex noise at (x, y) with the given seed.
- `lurek.math.fbm`: Returns fractal Brownian motion noise at (x, y).
- `lurek.math.applyEasing`: Applies a named easing function to progress value t.
- `lurek.math.linear`: Linear easing (identity).
- `lurek.math.inQuad`: Quadratic ease-in — acceleration that starts at zero and increases.
- `lurek.math.outQuad`: Quadratic ease-out — deceleration that starts fast and ends at zero.
- `lurek.math.inOutQuad`: Quadratic ease-in-out — slow start, fast middle, slow end.
- `lurek.math.inCubic`: Cubic ease-in — acceleration starts slowly then increases sharply.
- `lurek.math.outCubic`: Cubic ease-out — rapid deceleration using a cubic power curve.
- `lurek.math.inOutCubic`: Cubic ease-in-out — slow start and end with fast cubic middle.
- `lurek.math.inQuart`: Quartic ease-in — strongly delayed acceleration using a power-of-4 curve.
- `lurek.math.outQuart`: Quartic ease-out — rapid deceleration using a power-of-4 curve.
- `lurek.math.inOutQuart`: Quartic ease-in-out — very slow start and end with a sharp middle peak.
- `lurek.math.inSine`: Sinusoidal ease-in — gentle acceleration based on a sine curve.
- `lurek.math.outSine`: Sinusoidal ease-out — gentle deceleration based on a cosine curve.
- `lurek.math.inOutSine`: Sinusoidal ease-in-out — smooth S-curve based on cosine interpolation.
- `lurek.math.inExpo`: Exponential ease-in — very slow start that accelerates sharply near the end.
- `lurek.math.outExpo`: Exponential ease-out — sharp initial speed that decelerates exponentially.
- `lurek.math.inOutExpo`: Exponential ease-in-out — very slow start and end with an exponential surge.
- `lurek.math.inElastic`: Elastic ease-in — spring-like overshoot at the beginning of the motion.
- `lurek.math.outElastic`: Elastic ease-out — spring-like oscillation that settles at the target.
- `lurek.math.outBounce`: Bounce ease-out — simulates a ball bouncing against the target value.
- `lurek.math.inBounce`: Bounce ease-in — reverse bounce effect that accelerates into the motion.
- `lurek.math.inBack`: Back ease-in — overshoots slightly before settling at the target.
- `lurek.math.outBack`: Back ease-out — overshoots the target then snaps back into place.
- `lurek.math.inOutElastic`: Elastic ease-in-out — spring-like oscillation on both ends.
- `lurek.math.inOutBounce`: Bounce ease-in-out — bouncing motion on both ends.
- `lurek.math.inOutBack`: Back ease-in-out — overshoot on both ends.
- `lurek.math.triangulate`: Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
- `lurek.math.isConvex`: Returns true if the polygon (flat table {x1,y1,...}) is convex.
- `lurek.math.gammaToLinear`: Converts a gamma-encoded sRGB value to linear space.
- `lurek.math.linearToGamma`: Converts a linear-space value to gamma-encoded sRGB.
- `lurek.math.angleBetween`: Returns the angle in radians from (x1, y1) to (x2, y2).
- `lurek.math.circleContainsPoint`: Returns true if the point (px, py) lies inside the circle.
- `lurek.math.circleIntersectsCircle`: Returns true if two circles overlap.
- `lurek.math.circleIntersectsLine`: Tests an infinite line against a circle. Returns hit, then two optional hit-point pairs.
- `lurek.math.circleIntersectsSegment`: Tests a line segment against a circle. Returns hit, then two optional hit-point pairs.
- `lurek.math.closestPointOnSegment`: Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
- `lurek.math.convexHull`: Computes the convex hull of a flat {x1,y1,...} point list. Returns a flat table.
- `lurek.math.delaunayTriangulate`: Delaunay triangulation of a flat {x1,y1,...} point list. Returns a table of flat 6-number triangle tables.
- `lurek.math.lineIntersect`: Infinite line intersection. Returns (x, y) or (nil, nil) if lines are parallel.
- `lurek.math.pointInPolygon`: Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
- `lurek.math.polygonArea`: Returns the signed area of a polygon given as a flat {x1,y1,...} table.
- `lurek.math.polygonCentroid`: Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
- `lurek.math.segmentIntersectsSegment`: Tests if two line segments intersect. Returns (hit, ix?, iy?).
- `lurek.math.bresenham`: Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm. Returns a table of {x,y} tables.
- `lurek.math.rad`: Converts degrees to radians.
- `lurek.math.deg`: Converts radians to degrees.
- `lurek.math.sin`: Returns the sine of x (radians).
- `lurek.math.cos`: Returns the cosine of x (radians).
- `lurek.math.tan`: Returns the tangent of x (radians).
- `lurek.math.asin`: Returns the arcsine of x, in radians.
- `lurek.math.acos`: Returns the arccosine of x, in radians.
- `lurek.math.atan`: Returns the arctangent of x (or atan2(y, x) when two args given).
- `lurek.math.atan2`: Returns atan(y/x) using the signs of both args to determine the quadrant.
- `lurek.math.sqrt`: Returns the square root of x.
- `lurek.math.abs`: Returns the absolute value of x.
- `lurek.math.floor`: Returns the largest integer ≤ x.
- `lurek.math.ceil`: Returns the smallest integer ≥ x.
- `lurek.math.round`: Returns x rounded to the nearest integer (half-up).
- `lurek.math.exp`: Returns e raised to the power x.
- `lurek.math.log`: Returns the natural log of x, or log base b if b is supplied.
- `lurek.math.pow`: Returns x raised to the power y.
- `lurek.math.min`: Returns the smallest of the supplied numbers.
- `lurek.math.max`: Returns the largest of the supplied numbers.
- `lurek.math.fmod`: Returns the remainder of x / y (fmod).
- `lurek.math.distance`: Returns the Euclidean distance between (x1,y1) and (x2,y2).
- `lurek.math.distanceSq`: Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
- `lurek.math.random`: Returns a pseudo-random number using Lua's built-in `math.random` behavior.
- `lurek.math.randomInt`: Returns a pseudo-random integer in [lo, hi] (inclusive).
- `lurek.math.simplexNoise`: Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
- `lurek.math.vec2`: Creates a 2D vector with x and y components.
- `lurek.math.Vec2`: Compatibility alias for `vec2`.
- `lurek.math.vec3`: Creates a 3D vector `{x, y, z}` table with numeric components.
- `lurek.math.Vec3`: Compatibility alias for `vec3`.
- `lurek.math.catmullRom`: Creates a Catmull-Rom spline through the given control points.
- `lurek.math.hermite`: Creates a Hermite spline defined by two endpoints and tangents.
- `lurek.math.lerp`: Linear interpolation between two numbers: a + (b - a) * t.
- `lurek.math.remap`: Remaps `v` from [in_min, in_max] to [out_min, out_max].
- `lurek.math.clamp`: Clamps `v` between `min` and `max`.
- `lurek.math.sign`: Returns -1, 0, or 1 depending on the sign of `v`.
- `lurek.math.smoothstep`: Hermite smoothstep between `edge0` and `edge1`.
- `lurek.math.inverseLerp`: Returns the interpolation parameter t for `v` in [a, b].
- `lurek.math.hslToRgb`: Converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats.
- `lurek.math.fromHex`: Parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats.
- `lurek.math.rgbToHsl`: Converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1).
- `lurek.math.rectUnion`: Returns the union (bounding box) of two rectangles.
- `lurek.math.rectFromCenter`: Creates a rectangle centered at (cx, cy) with the given width and height.
- `lurek.math.polygonClip`: Clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
- `lurek.math.aabbTree`: Creates a new empty AABB tree for efficient broad-phase overlap queries.
- `lurek.math.newCircle`: Creates a new Circle value type with the given centre and radius.
- `lurek.math.polygonIntersection`: Computes the intersection of two convex polygons.
- `lurek.math.polygonUnion`: Computes the approximate union of two convex polygons as a convex hull.
- `lurek.math.polygonDifference`: Computes the approximate difference `A - B` for convex polygon inputs.
- `lurek.math.voronoi`: Computes the Voronoi diagram for a list of 2-D seed points.

### `LAabbTree` Methods
- `LAabbTree:insert`: Inserts an entry with the given AABB into the tree.
- `LAabbTree:remove`: Removes the entry with the given id.
- `LAabbTree:query`: Returns the ids of all entries whose AABBs overlap the query rectangle.
- `LAabbTree:queryPoint`: Returns the ids of all entries whose AABBs contain the given point.
- `LAabbTree:update`: Updates the AABB for an existing entry.
- `LAabbTree:contains`: Returns true if an entry with the given id exists in the tree.
- `LAabbTree:len`: Returns the number of entries in the tree.
- `LAabbTree:isEmpty`: Returns true if the tree contains no entries.
- `LAabbTree:clear`: Removes all entries from the tree.
- `LAabbTree:type`: Returns the type name of this object.
- `LAabbTree:typeOf`: Returns true if this object is of the given type.

### `LBezierCurve` Methods
- `LBezierCurve:evaluate`: Evaluates the curve at parameter t, returning (x, y).
- `LBezierCurve:render`: Renders the curve as a polyline with the given number of segments.
- `LBezierCurve:getDerivative`: Returns a new BezierCurve representing the first derivative.
- `LBezierCurve:getControlPoint`: Returns the control point at 1-based index as (x, y), or nil.
- `LBezierCurve:setControlPoint`: Sets the control point at 1-based index.
- `LBezierCurve:insertControlPoint`: Inserts a control point. If index is given (1-based), inserts at that position.
- `LBezierCurve:removeControlPoint`: Removes a control point at 1-based index.
- `LBezierCurve:getControlPointCount`: Returns the number of control points.
- `LBezierCurve:length`: Returns the approximate arc length of the curve.
- `LBezierCurve:translate`: Translates all control points by (dx, dy).
- `LBezierCurve:rotate`: Rotates all control points around a pivot by angle radians.
- `LBezierCurve:scale`: Scales all control points around a pivot by factor s.
- `LBezierCurve:type`: Returns the type name of this object.
- `LBezierCurve:typeOf`: Returns true if this object is of the given type.

### `LCatmullRom` Methods
- `LCatmullRom:sample`: Samples the spline at global parameter `t` in `[0, 1]`.
- `LCatmullRom:sampleSegment`: Samples one segment at local parameter `t` in `[0, 1]`.
- `LCatmullRom:len`: Number of control points.
- `LCatmullRom:addPoint`: Appends a control point to the spline.
- `LCatmullRom:removePoint`: Removes the control point at `index` (0-based) and returns it.
- `LCatmullRom:type`: Returns the type name of this object.
- `LCatmullRom:typeOf`: Returns true if this object is of the given type.

### `LCircle` Methods
- `LCircle:area`: Returns the area of the circle (π r²).
- `LCircle:perimeter`: Returns the circumference of the circle (2 π r).
- `LCircle:contains`: Returns true if the point (px, py) lies inside or on the boundary.
- `LCircle:intersects`: Returns true if this circle overlaps another circle.
- `LCircle:aabb`: Returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y).
- `LCircle:x`: Returns the circle centre X.
- `LCircle:y`: Returns the circle centre Y.
- `LCircle:radius`: Returns the circle radius.
- `LCircle:type`: Returns the type name of this object.
- `LCircle:typeOf`: Returns true if this object is of the given type.

### `LHermite` Methods
- `LHermite:sample`: Samples the spline at parameter `t` in `[0, 1]`.
- `LHermite:type`: Returns the type name of this object.
- `LHermite:typeOf`: Returns true if this object is of the given type.

### `LNoiseGenerator` Methods
- `LNoiseGenerator:perlin1d`: Returns 1D Perlin noise at x.
- `LNoiseGenerator:perlin2d`: Returns 2D Perlin noise at (x, y).
- `LNoiseGenerator:perlin3d`: Returns 3D Perlin noise at (x, y, z).
- `LNoiseGenerator:perlin4d`: Returns 4D Perlin noise at (x, y, z, w).
- `LNoiseGenerator:simplex1d`: Returns 1D Simplex noise at x.
- `LNoiseGenerator:simplex2d`: Returns 2D Simplex noise at (x, y).
- `LNoiseGenerator:simplex3d`: Returns 3D Simplex noise at (x, y, z).
- `LNoiseGenerator:worley2d`: Returns 2D Worley (cellular) noise at (x, y).
- `LNoiseGenerator:worley3d`: Returns 3D Worley (cellular) noise at (x, y, z).
- `LNoiseGenerator:fbm`: Returns fractal Brownian motion noise at (x, y).
- `LNoiseGenerator:ridged`: Returns ridged multi-fractal noise at (x, y).
- `LNoiseGenerator:turbulence`: Returns turbulence noise at (x, y).
- `LNoiseGenerator:warpDomain`: Applies domain warping, returning offset (x, y).
- `LNoiseGenerator:generateMap`: Generates a 2D noise map as a flat table (row-major).
- `LNoiseGenerator:getSeed`: Returns the current seed.
- `LNoiseGenerator:setSeed`: Sets the seed and rebuilds the permutation table.
- `LNoiseGenerator:type`: Returns the type name of this object.
- `LNoiseGenerator:typeOf`: Returns true if this object is of the given type.

### `LRandomGenerator` Methods
- `LRandomGenerator:random`: Returns a uniform random number in [0, 1).
- `LRandomGenerator:randomFloat`: Returns a uniform random float in [min, max).
- `LRandomGenerator:randomInt`: Returns a uniform random integer in [min, max].
- `LRandomGenerator:randomNormal`: Returns a random number from a normal (Gaussian) distribution.
- `LRandomGenerator:getSeed`: Returns the seed used to initialise this generator.
- `LRandomGenerator:setSeed`: Sets the seed, fully resetting the generator state.
- `LRandomGenerator:getState`: Serialises the generator state as a string for later restoration.
- `LRandomGenerator:setState`: Restores the generator state from a previously serialised string.
- `LRandomGenerator:type`: Returns the type name of this object.
- `LRandomGenerator:typeOf`: Returns true if this object is of the given type.

### `LSpatialHash` Methods
- `LSpatialHash:insert`: Inserts an item with the given AABB.
- `LSpatialHash:update`: Updates an existing item's AABB.
- `LSpatialHash:remove`: Removes an item by its ID.
- `LSpatialHash:clear`: Removes all registered items from this spatial hash, leaving it empty.
- `LSpatialHash:queryRect`: Returns IDs of items overlapping the query rectangle.
- `LSpatialHash:queryCircle`: Returns IDs of items overlapping the query circle.
- `LSpatialHash:querySegment`: Returns IDs of items whose AABBs are intersected by the line segment.
- `LSpatialHash:getCellSize`: Returns the cell size used to partition the spatial hash grid.
- `LSpatialHash:getItemCount`: Returns the number of items in the hash.
- `LSpatialHash:type`: Returns the type name of this object.
- `LSpatialHash:typeOf`: Returns true if this object is of the given type.

### `LTransform` Methods
- `LTransform:translate`: Applies translation to the transform.
- `LTransform:rotate`: Applies a rotation in radians.
- `LTransform:scale`: Applies non-uniform scaling.
- `LTransform:shear`: Applies horizontal and vertical shear factors to this transform matrix.
- `LTransform:reset`: Resets the transform to identity.
- `LTransform:setTransformation`: Replaces the transform with full transformation parameters.
- `LTransform:transformPoint`: Transforms a point from local space to world space.
- `LTransform:inverseTransformPoint`: Transforms a point from world space back to local space.
- `LTransform:inverse`: Returns a new Transform that undoes this transform.
- `LTransform:clone`: Returns a copy of this transform.
- `LTransform:getMatrix`: Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
- `LTransform:decompose`: Decomposes this transform into translation, rotation, and scale.
- `LTransform:type`: Returns the type name of this object.
- `LTransform:typeOf`: Returns true if this object is of the given type.

### `LTween` Methods
- `LTween:update`: Advances the clock by dt seconds. Returns true when complete.
- `LTween:reset`: Resets the tween elapsed time to zero, restarting the animation.
- `LTween:getValue`: Returns the interpolated value at 1-based index, or all values when no index is given.
- `LTween:getAllValues`: Returns all interpolated values as a table.
- `LTween:isComplete`: Returns true if the tween has finished.
- `LTween:getValueCount`: Returns the number of values in this tween.
- `LTween:getEasingName`: Returns the easing function name.
- `LTween:getDuration`: Returns the tween duration in seconds.
- `LTween:getTime`: Returns the current clock time.
- `LTween:getClock`: Alias for getTime(). Returns the current clock time.
- `LTween:setTime`: Sets the clock to a specific time, clamped to [0, duration].
- `LTween:set`: Alias for setTime(). Sets the clock to t, clamped to [0, duration].
- `LTween:addValue`: Adds a start/target value pair. Returns the 1-based index.
- `LTween:type`: Returns the type name of this object.
- `LTween:typeOf`: Returns true if this object is of the given type.

### `LVec2` Methods
- `LVec2:dot`: Returns the dot product with another vector.
- `LVec2:length`: Returns the Euclidean length of the vector.
- `LVec2:x`: Returns the horizontal component of the vector.
- `LVec2:y`: Returns the vertical component of the vector.
- `LVec2:lengthSquared`: Returns the squared length of the vector (faster than length).
- `LVec2:normalize`: Returns a unit-length copy of this vector. Returns zero if length is zero.
- `LVec2:normalized`: Compatibility alias for `normalize`.
- `LVec2:lerp`: Returns a linearly interpolated vector between this and other at parameter t.
- `LVec2:distance`: Returns the Euclidean distance from this vector to another.
- `LVec2:angle`: Returns the angle of this vector in radians (atan2(y, x)).
- `LVec2:rotate`: Returns a new vector rotated by the given angle in radians.
- `LVec2:perpendicular`: Returns the perpendicular vector (-y, x).
- `LVec2:cross`: Returns the 2D cross product (scalar) with another vector.
- `LVec2:fromAngle`: Creates a unit vector from an angle in radians.
- `LVec2:reflect`: Reflects this vector off a surface with the given normal.
- `LVec2:type`: Returns the type name of this object.
- `LVec2:typeOf`: Returns true if this object is of the given type.

### `LVec3` Methods
- `LVec3:length`: Returns the Euclidean length of the vector.
- `LVec3:lengthSquared`: Returns the squared Euclidean length (avoids sqrt).
- `LVec3:normalize`: Returns a unit-length version of this vector.
- `LVec3:dot`: Dot product with another Vec3.
- `LVec3:cross`: Cross product with another Vec3.
- `LVec3:lerp`: Linear interpolation towards another Vec3.
- `LVec3:distance`: Euclidean distance to another Vec3.
- `LVec3:add`: Add another Vec3 and return the result.
- `LVec3:sub`: Subtract another Vec3 and return the result.
- `LVec3:scale`: Scale this vector by a scalar and return the result.
- `LVec3:splat`: Creates a Vec3 with all components set to `v`.
- `LVec3:type`: Returns the type name of this object.
- `LVec3:typeOf`: Returns true if this object is of the given type.

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
