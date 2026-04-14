# math

## General Info

- Module group: `Foundations`
- Source path: `src/math/`
- Lua API path(s): `src/lua_api/math_api.rs`
- Primary Lua namespace: `lurek.math`
- Rust test path(s): tests/rust/unit/math_tests.rs; inline tests in src/math/vec2.rs, src/math/mat3.rs, src/math/rect.rs, src/math/color.rs, src/math/bezier.rs, src/math/easing.rs, src/math/geometry.rs, src/math/noise_functions.rs, src/math/noise_generator.rs, src/math/polygon.rs, src/math/random.rs, src/math/spatial_hash.rs, src/math/transform.rs, src/math/tween.rs
- Lua test path(s): tests/lua/unit/test_math.lua

## Summary

The `math` module is Lurek2D's foundational mathematics library — the leaf of the engine's dependency graph with zero Lurek2D module dependencies of its own. Every other module that needs 2D math, geometry, or color types imports from here.

Core value types: `Vec2` (2D f32 vector with arithmetic operators, swizzling, dot/cross/normalize/lerp/distance helpers), `Vec3` (3D f32 vector with equivalent ops), `Mat3` (3×3 column-major affine transform matrix supporting translate, rotate, scale application and matrix multiplication), `Transform` (chainable builder wrapping `Mat3`), `Rect` (AABB with contains/overlaps/union/intersection), `Color` (the engine's canonical sRGB `[f32; 4]` type with named constants, `u8` and `f32` constructors, and packed `u32` output — all engine code must use this, not custom color structs).

Curve and spline types: `BezierCurve` (De Casteljau evaluation), `CatmullRomSpline` and `HermiteSpline` (smooth interpolating splines for animation paths).

Utility types: `RandomGenerator` (seedable deterministic linear congruential RNG for reproducible sequences), `SpatialHash` (grid-based broad-phase AABB collision query), `EasingType` enum with 30+ easing functions as both named functions and an enum for serialization, `geometry` module with ear-clipping triangulation, convex hull, point-in-polygon test, line-segment intersection, and rasterization helpers.

All types are plain-old data with `#[derive(Debug, Clone, Copy)]`; none hold heap allocations except spline control-point vectors.

**Scope boundary**: Foundations tier. Zero Lurek2D dependencies. Lua bridge in `src/lua_api/math_api.rs`.

## Files

- `bezier.rs`: Implements arbitrary-order Bezier curves with evaluation, derivative, editing, rendering, and transform helpers.
- `color.rs`: Defines the shared RGBA value type plus byte conversion, packed RGB output, HSV conversion, and gamma helpers.
- `easing.rs`: Houses the named easing curve functions and the string-based dispatcher used by tweening code and Lua bindings.
- `geometry.rs`: Collects free-standing geometry utilities such as circle tests, polygon measurements, segment tests, line rasterization, convex hull, and triangulation helpers.
- `mat3.rs`: Implements the 3x3 affine matrix used for 2D transforms, point transforms, composition, and inversion.
- `mod.rs`: Re-exports the public math surface so other modules and the Lua bridge can depend on one stable module root.
- `noise_functions.rs`: Exposes standalone Perlin, Simplex, and FBM helpers for callers that do not need a reusable generator object.
- `noise_generator.rs`: Owns the seeded `NoiseGenerator` and the richer procedural toolset for Perlin, Simplex, Worley, fractal layering, domain warping, and map generation.
- `polygon.rs`: Provides polygon-specific helpers centered on convexity testing and ear-clipping triangulation.
- `random.rs`: Wraps `fastrand` in a deterministic, serializable RNG API that matches engine and Lua expectations.
- `rect.rs`: Provides axis-aligned rectangles for overlap, containment, and intersection queries used across gameplay and rendering code.
- `spatial_hash.rs`: Implements a uniform-grid broad-phase index for fast rectangle, circle, and segment spatial queries.
- `spline.rs`: Interpolating and approximating splines: Catmull-Rom and Hermite.
- `transform.rs`: Wraps `Mat3` in a mutable 2D transform object with chainable translate, rotate, scale, and shear operations.
- `tween.rs`: Implements low-level numeric interpolation over one or more values and explicitly stays below the higher-level `src/tween/` feature system.
- `vec2.rs`: Defines the engine's primary 2D vector type and common arithmetic, direction, interpolation, and geometric helpers.
- `vec3.rs`: 3D floating-point vector with arithmetic operators and common helpers.

## Types

- `BezierCurve` (`struct`, `bezier.rs`): Editable Bezier curve object for path sampling, tangents, and authorable curve manipulation. It supports both math-heavy tooling and Lua scripting use cases.
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
- `CatmullRomSpline` (`struct`, `spline.rs`): A Catmull-Rom spline through a sequence of control points.
- `HermiteSpline` (`struct`, `spline.rs`): A cubic Hermite spline segment defined by two endpoints and their tangents.
- `Transform` (`struct`, `transform.rs`): Mutable 2D transform object that exposes a script-friendly API over `Mat3`. It is the ergonomic surface for composition and point conversion.
- `TweenValue` (`struct`, `tween.rs`): Holds one start-target numeric pair inside a low-level tween. It is intentionally minimal and exists mainly to support `Tween`.
- `Tween` (`struct`, `tween.rs`): Low-level multi-channel numeric interpolator driven by easing functions and an internal clock. It does not own callbacks, sequences, or property animation workflows.
- `Vec2` (`struct`, `vec2.rs`): Core 2D vector used pervasively for positions, directions, offsets, and interpolation. It is the default math currency for most engine subsystems.
- `Vec3` (`struct`, `vec3.rs`): A 3D floating-point vector.

## Functions

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
- `Color::new` (`color.rs`): Creates a color from `f32` RGBA components in `[0.0, 1.0]`.
- `Color::from_u8` (`color.rs`): Creates a color from `u8` RGBA components in `[0, 255]`, normalizing to `[0.0, 1.0]`.
- `Color::to_u8` (`color.rs`): Converts the color to `u8` RGBA components, each in `[0, 255]`.
- `Color::to_rgb_u32` (`color.rs`): Converts the color to a packed `u32` RGB value suitable for packed pixel buffers.
- `hsv_to_rgb` (`color.rs`): Convert an HSV color to RGB byte components.
- `gamma_to_linear` (`color.rs`): Convert a single sRGB gamma-space color component to linear space.
- `linear_to_gamma` (`color.rs`): Convert a single linear-space color component to sRGB gamma space.
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
- `ease_out_bounce` (`easing.rs`): Bounce ease-out — simulates a bouncing ball landing.
- `ease_in_bounce` (`easing.rs`): Bounce ease-in — simulates a bouncing ball launching.
- `ease_in_back` (`easing.rs`): Back ease-in — pulls back before accelerating past the start.
- `ease_out_back` (`easing.rs`): Back ease-out — overshoots the target then settles back.
- `apply` (`easing.rs`): Looks up an easing function by name and applies it to progress value `t`.
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
- `perlin2d` (`noise_functions.rs`): Generates 2D Perlin noise at the given coordinates.
- `simplex2d` (`noise_functions.rs`): Generates 2D Simplex noise at the given coordinates.
- `simplex_noise_2d` (`noise_functions.rs`): Returns 2D simplex noise for the given coordinates using seed 0.
- `simplex_noise_3d` (`noise_functions.rs`): Returns 3D simplex noise for the given coordinates using seed 0.
- `fbm` (`noise_functions.rs`): Generates fractal Brownian motion noise by layering multiple octaves of Perlin noise.
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
- `CatmullRomSpline::new` (`spline.rs`): Create a spline from the given control points.
- `CatmullRomSpline::sample` (`spline.rs`): Sample the spline at a global parameter `t` in [0, 1] spanning the whole curve.
- `CatmullRomSpline::sample_segment` (`spline.rs`): Sample a specific segment by index at local parameter `t` in [0, 1].
- `CatmullRomSpline::len` (`spline.rs`): Number of control points.
- `CatmullRomSpline::is_empty` (`spline.rs`): Returns `true` if there are no control points.
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
- `Vec3::new` (`vec3.rs`): Create a new vector with the given components.
- `Vec3::zero` (`vec3.rs`): The zero vector (0, 0, 0).
- `Vec3::one` (`vec3.rs`): The unit vector (1, 1, 1).
- `Vec3::dot` (`vec3.rs`): Dot product of this vector and `other`.
- `Vec3::cross` (`vec3.rs`): Cross product of this vector and `other`.
- `Vec3::length` (`vec3.rs`): Euclidean length (magnitude) of this vector.
- `Vec3::length_squared` (`vec3.rs`): Squared Euclidean length.
- `Vec3::normalize` (`vec3.rs`): Returns a unit-length version of this vector, or the zero vector if length is zero.
- `Vec3::lerp` (`vec3.rs`): Linear interpolation between this vector and `other` by factor `t` in [0, 1].
- `Vec3::distance` (`vec3.rs`): Euclidean distance to `other`.
- `Vec3::project` (`vec3.rs`): Project this vector onto `onto`.
- `Vec3::reflect` (`vec3.rs`): Reflect this vector about `normal` (normal must be unit length).

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
- `lurek.math.inQuad`: Quadratic ease-in.
- `lurek.math.outQuad`: Quadratic ease-out.
- `lurek.math.inOutQuad`: Quadratic ease-in-out.
- `lurek.math.inCubic`: Cubic ease-in — acceleration starts slowly then increases sharply.
- `lurek.math.outCubic`: Cubic ease-out.
- `lurek.math.inOutCubic`: Cubic ease-in-out.
- `lurek.math.inQuart`: Quartic ease-in.
- `lurek.math.outQuart`: Quartic ease-out.
- `lurek.math.inOutQuart`: Quartic ease-in-out.
- `lurek.math.inSine`: Sinusoidal ease-in.
- `lurek.math.outSine`: Sinusoidal ease-out.
- `lurek.math.inOutSine`: Sinusoidal ease-in-out.
- `lurek.math.inExpo`: Exponential ease-in.
- `lurek.math.outExpo`: Exponential ease-out.
- `lurek.math.inOutExpo`: Exponential ease-in-out.
- `lurek.math.inElastic`: Elastic ease-in.
- `lurek.math.outElastic`: Elastic ease-out.
- `lurek.math.outBounce`: Bounce ease-out.
- `lurek.math.inBounce`: Bounce ease-in.
- `lurek.math.inBack`: Back ease-in — overshoots slightly before settling at the target.
- `lurek.math.outBack`: Back ease-out — overshoots the target then snaps back into place.
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
- `lurek.math.clamp`: Returns x clamped to [lo, hi].
- `lurek.math.sign`: Returns -1, 0, or 1 depending on the sign of x.
- `lurek.math.fmod`: Returns the remainder of x / y (fmod).
- `lurek.math.lerp`: Linear interpolation between a and b by fraction t.
- `lurek.math.distance`: Returns the Euclidean distance between (x1,y1) and (x2,y2).
- `lurek.math.distanceSq`: Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
- `lurek.math.random`: Returns a pseudo-random number in [0,1) with no args,
- `lurek.math.randomInt`: Returns a pseudo-random integer in [lo, hi] (inclusive).
- `lurek.math.simplexNoise`: Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
- `lurek.math.vec2`: Creates a 2D vector with x and y components.
- `lurek.math.Vec2`: Compatibility alias for `vec2`.
- `lurek.math.vec3`: Creates a 3D vector.
- `lurek.math.Vec3`: Compatibility alias for `vec3`.
- `lurek.math.catmullRom`: Creates a Catmull-Rom spline through the given control points.
- `lurek.math.hermite`: Creates a Hermite spline defined by two endpoints and tangents.
- `lurek.math.lerp`: Linear interpolation between two numbers: a + (b - a) * t.
- `lurek.math.remap`: Remaps `v` from [in_min, in_max] to [out_min, out_max].

### `BezierCurve` Methods
- `BezierCurve:evaluate`: Evaluates the curve at parameter t, returning (x, y).
- `BezierCurve:render`: Renders the curve as a polyline with the given number of segments.
- `BezierCurve:getDerivative`: Returns a new BezierCurve representing the first derivative.
- `BezierCurve:getControlPoint`: Returns the control point at 1-based index as (x, y), or nil.
- `BezierCurve:removeControlPoint`: Removes a control point at 1-based index.
- `BezierCurve:getControlPointCount`: Returns the number of control points.
- `BezierCurve:length`: Returns the approximate arc length of the curve.
- `BezierCurve:translate`: Translates all control points by (dx, dy).
- `BezierCurve:rotate`: Rotates all control points around a pivot by angle radians.
- `BezierCurve:scale`: Scales all control points around a pivot by factor s.

### `CatmullRom` Methods
- `CatmullRom:sample`: Sample the spline at global t in [0, 1].
- `CatmullRom:sampleSegment`: Sample a specific segment at local t in [0, 1].
- `CatmullRom:len`: Number of control points.

### `Hermite` Methods
- `Hermite:sample`: Evaluate the spline at parameter t in [0, 1].

### `NoiseGenerator` Methods
- `NoiseGenerator:perlin1d`: Returns 1D Perlin noise at x.
- `NoiseGenerator:perlin2d`: Returns 2D Perlin noise at (x, y).
- `NoiseGenerator:perlin3d`: Returns 3D Perlin noise at (x, y, z).
- `NoiseGenerator:perlin4d`: Returns 4D Perlin noise at (x, y, z, w).
- `NoiseGenerator:simplex1d`: Returns 1D Simplex noise at x.
- `NoiseGenerator:simplex2d`: Returns 2D Simplex noise at (x, y).
- `NoiseGenerator:simplex3d`: Returns 3D Simplex noise at (x, y, z).
- `NoiseGenerator:getSeed`: Returns the current seed.
- `NoiseGenerator:setSeed`: Sets the seed and rebuilds the permutation table.

### `RandomGenerator` Methods
- `RandomGenerator:random`: Returns a uniform random number in [0, 1).
- `RandomGenerator:randomFloat`: Returns a uniform random float in [min, max).
- `RandomGenerator:randomInt`: Returns a uniform random integer in [min, max].
- `RandomGenerator:getSeed`: Returns the seed used to initialise this generator.
- `RandomGenerator:setSeed`: Sets the seed, fully resetting the generator state.
- `RandomGenerator:getState`: Serialises the generator state as a string for later restoration.
- `RandomGenerator:setState`: Restores the generator state from a previously serialised string.

### `SpatialHash` Methods
- `SpatialHash:remove`: Removes an item by its ID.
- `SpatialHash:clear`: Removes all items.
- `SpatialHash:getCellSize`: Returns the cell size.
- `SpatialHash:getItemCount`: Returns the number of items in the hash.

### `Transform` Methods
- `Transform:translate`: Applies translation to the transform.
- `Transform:rotate`: Applies a rotation in radians.
- `Transform:scale`: Applies non-uniform scaling.
- `Transform:shear`: Applies shear factors.
- `Transform:reset`: Resets the transform to identity.
- `Transform:transformPoint`: Transforms a point from local space to world space.
- `Transform:inverseTransformPoint`: Transforms a point from world space back to local space.
- `Transform:inverse`: Returns a new Transform that undoes this transform.
- `Transform:clone`: Returns a copy of this transform.
- `Transform:getMatrix`: Returns the 3x3 matrix as a flat table of 9 numbers (row-major).

### `Tween` Methods
- `Tween:update`: Advances the clock by dt seconds. Returns true when complete.
- `Tween:reset`: Resets the clock to 0.
- `Tween:getValue`: Returns the interpolated value at 1-based index, or all values as a
- `Tween:getAllValues`: Returns all interpolated values as a table.
- `Tween:isComplete`: Returns true if the tween has finished.
- `Tween:getValueCount`: Returns the number of values in this tween.
- `Tween:getEasingName`: Returns the easing function name.
- `Tween:getDuration`: Returns the tween duration in seconds.
- `Tween:getTime`: Returns the current clock time.
- `Tween:getClock`: Alias for getTime(). Returns the current clock time.
- `Tween:setTime`: Sets the clock to a specific time, clamped to [0, duration].
- `Tween:set`: Alias for setTime(). Sets the clock to t, clamped to [0, duration].
- `Tween:addValue`: Adds a start/target value pair. Returns the 1-based index.

### `Vec2` Methods
- `Vec2:dot`: Returns the dot product with another vector.
- `Vec2:length`: Returns the Euclidean length of the vector.
- `Vec2:x`: Returns the horizontal component of the vector.
- `Vec2:y`: Returns the vertical component of the vector.
- `Vec2:lengthSquared`: Returns the squared length of the vector (faster than length).
- `Vec2:normalize`: Returns a unit-length copy of this vector. Returns zero if length is zero.
- `Vec2:normalized`: Compatibility alias for `normalize`.
- `Vec2:lerp`: Returns a linearly interpolated vector between this and other at parameter t.
- `Vec2:distance`: Returns the Euclidean distance from this vector to another.
- `Vec2:angle`: Returns the angle of this vector in radians (atan2(y, x)).
- `Vec2:rotate`: Returns a new vector rotated by the given angle in radians.
- `Vec2:perpendicular`: Returns the perpendicular vector (-y, x).
- `Vec2:cross`: Returns the 2D cross product (scalar) with another vector.

### `Vec3` Methods
- `Vec3:length`: Returns the Euclidean length of the vector.
- `Vec3:lengthSquared`: Returns the squared Euclidean length (avoids sqrt).
- `Vec3:normalize`: Returns a unit-length version of this vector.
- `Vec3:dot`: Dot product with another Vec3.
- `Vec3:cross`: Cross product with another Vec3.
- `Vec3:lerp`: Linear interpolation towards another Vec3.
- `Vec3:distance`: Euclidean distance to another Vec3.
- `Vec3:add`: Add another Vec3 and return the result.
- `Vec3:sub`: Subtract another Vec3 and return the result.
- `Vec3:scale`: Scale this vector by a scalar and return the result.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/math/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
