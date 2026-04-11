# `math` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundations |
| **Status** | Implemented |
| **Lua API** | `lurek.math` |
| **Source** | `src/math/` |
| **Rust Tests** | `tests/rust/unit/math_tests.rs`; inline tests in `src/math/vec2.rs`, `src/math/mat3.rs`, `src/math/rect.rs`, `src/math/color.rs`, `src/math/bezier.rs`, `src/math/easing.rs`, `src/math/geometry.rs`, `src/math/noise_functions.rs`, `src/math/noise_generator.rs`, `src/math/polygon.rs`, `src/math/random.rs`, `src/math/spatial_hash.rs`, `src/math/transform.rs`, `src/math/tween.rs` |
| **Lua Tests** | `tests/lua/unit/test_math.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Foundations` |

---

## Summary

The `math` module is Lurek2D's shared foundation for numeric types and algorithms that many higher-level systems depend on. It owns the engine's core 2D value types such as vectors, matrices, rectangles, and colors, plus reusable geometric helpers, easing curves, seeded randomness, procedural noise, and broad-phase spatial indexing.

This module exists so rendering, physics, animation, UI, pathfinding, and Lua bindings can share one consistent set of primitives instead of re-implementing math logic in each subsystem. Its APIs are mostly pure, lightweight, and allocation-conscious, which makes them safe to use in hot update and render paths.

`math` intentionally does not own engine state, ECS data, resource handles, scene objects, or frame scheduling. It provides building blocks like `Tween`, `Transform`, and `SpatialHash`, but it does not own the higher-level animation system in `src/tween/`, scene transforms, or gameplay orchestration.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Foundations responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.math.* (Lua API — src/lua_api/math_api.rs)
    |
    v
src/math/mod.rs
    |- bezier.rs - bezier
    |- color.rs - color
    |- easing.rs - easing
    |- geometry.rs - geometry
    |- mat3.rs - mat3
    |- noise_functions.rs - noise_functions
    |- noise_generator.rs - noise_generator
    |- polygon.rs - polygon
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `bezier.rs` | Implements arbitrary-order Bezier curves with evaluation, derivative, editing, rendering, and transform helpers. |
| `color.rs` | Defines the shared RGBA value type plus byte conversion, packed RGB output, HSV conversion, and gamma helpers. |
| `easing.rs` | Houses the named easing curve functions and the string-based dispatcher used by tweening code and Lua bindings. |
| `geometry.rs` | Collects free-standing geometry utilities such as circle tests, polygon measurements, segment tests, line rasterization, convex hull, and triangulation helpers. |
| `mat3.rs` | Implements the 3x3 affine matrix used for 2D transforms, point transforms, composition, and inversion. |
| `mod.rs` | Re-exports the public math surface so other modules and the Lua bridge can depend on one stable module root. |
| `noise_functions.rs` | Exposes standalone Perlin, Simplex, and FBM helpers for callers that do not need a reusable generator object. |
| `noise_generator.rs` | Owns the seeded `NoiseGenerator` and the richer procedural toolset for Perlin, Simplex, Worley, fractal layering, domain warping, and map generation. |
| `polygon.rs` | Provides polygon-specific helpers centered on convexity testing and ear-clipping triangulation. |
| `random.rs` | Wraps `fastrand` in a deterministic, serializable RNG API that matches engine and Lua expectations. |
| `rect.rs` | Provides axis-aligned rectangles for overlap, containment, and intersection queries used across gameplay and rendering code. |
| `spatial_hash.rs` | Implements a uniform-grid broad-phase index for fast rectangle, circle, and segment spatial queries. |
| `transform.rs` | Wraps `Mat3` in a mutable 2D transform object with chainable translate, rotate, scale, and shear operations. |
| `tween.rs` | Implements low-level numeric interpolation over one or more values and explicitly stays below the higher-level `src/tween/` feature system. |
| `vec2.rs` | Defines the engine's primary 2D vector type and common arithmetic, direction, interpolation, and geometric helpers. |

---

## Submodules

### `math::bezier`

Implements arbitrary-order Bezier curves with evaluation, derivative, editing, rendering, and transform helpers.

- **`BezierCurve`** (struct): A Bezier curve defined by control points.

### `math::color`

Defines the shared RGBA value type plus byte conversion, packed RGB output, HSV conversion, and gamma helpers.

- **`Color`** (struct): RGBA color stored as `f32` components in the range `[0.0, 1.0]`.

### `math::easing`

Houses the named easing curve functions and the string-based dispatcher used by tweening code and Lua bindings.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `math::geometry`

Collects free-standing geometry utilities such as circle tests, polygon measurements, segment tests, line rasterization, convex hull, and triangulation helpers.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `math::mat3`

Implements the 3x3 affine matrix used for 2D transforms, point transforms, composition, and inversion.

- **`Mat3`** (struct): A 3×3 column-major matrix used for 2D affine transforms (translation, rotation, scale).

### `math::noise_functions`

Exposes standalone Perlin, Simplex, and FBM helpers for callers that do not need a reusable generator object.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `math::noise_generator`

Owns the seeded `NoiseGenerator` and the richer procedural toolset for Perlin, Simplex, Worley, fractal layering, domain warping, and map generation.

- **`DistType`** (enum): Distance metric for Worley noise.
- **`NoiseKind`** (enum): Noise algorithm kind used by fractal combinators.
- **`FractalType`** (enum): Fractal type for multi-octave noise.
- **`MapGenOptions`** (struct): Options for 2D noise map generation.
- **`NoiseGenerator`** (struct): Seeded procedural noise generator.

### `math::polygon`

Provides polygon-specific helpers centered on convexity testing and ear-clipping triangulation.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `math::random`

Wraps `fastrand` in a deterministic, serializable RNG API that matches engine and Lua expectations.

- **`RandomGenerator`** (struct): Seedable random number generator exposed as a Lua object.

### `math::rect`

Provides axis-aligned rectangles for overlap, containment, and intersection queries used across gameplay and rendering code.

- **`Rect`** (struct): An axis-aligned rectangle defined by its top-left corner and dimensions.

### `math::spatial_hash`

Implements a uniform-grid broad-phase index for fast rectangle, circle, and segment spatial queries.

- **`SpatialItem`** (struct): Entry in the spatial hash.
- **`SpatialHash`** (struct): Spatial hash for AABB queries.

### `math::transform`

Wraps `Mat3` in a mutable 2D transform object with chainable translate, rotate, scale, and shear operations.

- **`Transform`** (struct): 2D affine transform exposed as a Lua object.

### `math::tween`

Implements low-level numeric interpolation over one or more values and explicitly stays below the higher-level `src/tween/` feature system.

- **`TweenValue`** (struct): A start-to-target value pair for interpolation.
- **`Tween`** (struct): Value interpolator using easing functions.

### `math::vec2`

Defines the engine's primary 2D vector type and common arithmetic, direction, interpolation, and geometric helpers.

- **`Vec2`** (struct): A 2D floating-point vector used throughout the engine for positions, velocities, and directions.

---

## Key Types

### Public Types

#### `Vec2`

Core 2D vector used pervasively for positions, directions, offsets, and interpolation.

#### `Mat3`

Affine 2D matrix for transform composition and point mapping.

#### `Rect`

Axis-aligned rectangle for cheap containment and overlap checks.

#### `Color`

Shared RGBA value type for color transport across rendering-facing APIs.

#### `BezierCurve`

Editable Bezier curve object for path sampling, tangents, and authorable curve manipulation.

#### `RandomGenerator`

Deterministic RNG wrapper with seed and state control.

#### `NoiseGenerator`

Seeded procedural noise engine with multiple algorithms and fractal modes.

#### `NoiseKind`

Selects the base noise family for generator and fractal operations.

#### `FractalType`

Selects how multiple octaves are combined when generating layered noise.

#### `DistType`

Selects the distance metric used by Worley noise queries.

#### `MapGenOptions`

Bundles the parameters for 2D map generation into one stable config object.

#### `SpatialItem`

Stored record for an object indexed by `SpatialHash`.

#### `SpatialHash`

Broad-phase query structure for coarse spatial lookup by AABB, circle, or segment.

#### `Transform`

Mutable 2D transform object that exposes a script-friendly API over `Mat3`.

#### `TweenValue`

Holds one start-target numeric pair inside a low-level tween.

#### `Tween`

Low-level multi-channel numeric interpolator driven by easing functions and an internal clock.

---

## Lua API

Exposed under `lurek.math.*` by `src/lua_api/math_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.math.newRandomGenerator` | Creates a new random number generator with an optional seed. |
| `lurek.math.newTransform` | Creates a new Transform, optionally initialised from full parameters. |
| `lurek.math.newBezierCurve` | Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}. |
| `lurek.math.newTween` | Creates a new Tween with the given duration and easing name. |
| `lurek.math.newSpatialHash` | Creates a new SpatialHash with the given cell size. |
| `lurek.math.newNoiseGenerator` | Creates a new seeded noise generator. |
| `lurek.math.perlin2d` | Returns 2D Perlin noise at (x, y) with the given seed. |
| `lurek.math.perlin3d` | Returns 3D Perlin noise at (x, y, z) with the given seed. |
| `lurek.math.simplex2d` | Returns 2D Simplex noise at (x, y) with the given seed. |
| `lurek.math.fbm` | Returns fractal Brownian motion noise at (x, y). |
| `lurek.math.applyEasing` | Applies a named easing function to progress value t. |
| `lurek.math.linear` | Linear easing (identity). |
| `lurek.math.inQuad` | Quadratic ease-in. |
| `lurek.math.outQuad` | Quadratic ease-out. |
| `lurek.math.inOutQuad` | Quadratic ease-in-out. |
| `lurek.math.inCubic` | Cubic ease-in — acceleration starts slowly then increases sharply. |
| `lurek.math.outCubic` | Cubic ease-out. |
| `lurek.math.inOutCubic` | Cubic ease-in-out. |
| `lurek.math.inQuart` | Quartic ease-in. |
| `lurek.math.outQuart` | Quartic ease-out. |
| `lurek.math.inOutQuart` | Quartic ease-in-out. |
| `lurek.math.inSine` | Sinusoidal ease-in. |
| `lurek.math.outSine` | Sinusoidal ease-out. |
| `lurek.math.inOutSine` | Sinusoidal ease-in-out. |
| `lurek.math.inExpo` | Exponential ease-in. |
| `lurek.math.outExpo` | Exponential ease-out. |
| `lurek.math.inOutExpo` | Exponential ease-in-out. |
| `lurek.math.inElastic` | Elastic ease-in. |
| `lurek.math.outElastic` | Elastic ease-out. |
| `lurek.math.outBounce` | Bounce ease-out. |
| `lurek.math.inBounce` | Bounce ease-in. |
| `lurek.math.inBack` | Back ease-in — overshoots slightly before settling at the target. |
| `lurek.math.outBack` | Back ease-out — overshoots the target then snaps back into place. |
| `lurek.math.triangulate` | Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}. |
| `lurek.math.isConvex` | Returns true if the polygon (flat table {x1,y1,...}) is convex. |
| `lurek.math.gammaToLinear` | Converts a gamma-encoded sRGB value to linear space. |
| `lurek.math.linearToGamma` | Converts a linear-space value to gamma-encoded sRGB. |
| `lurek.math.angleBetween` | Returns the angle in radians from (x1, y1) to (x2, y2). |
| `lurek.math.circleContainsPoint` | Returns true if the point (px, py) lies inside the circle. |
| `lurek.math.circleIntersectsCircle` | Returns true if two circles overlap. |
| `lurek.math.circleIntersectsLine` | Tests an infinite line against a circle. Returns hit, then two optional hit-point pairs. |
| `lurek.math.circleIntersectsSegment` | Tests a line segment against a circle. Returns hit, then two optional hit-point pairs. |
| `lurek.math.closestPointOnSegment` | Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py). |
| `lurek.math.convexHull` | Computes the convex hull of a flat {x1,y1,...} point list. Returns a flat table. |
| `lurek.math.delaunayTriangulate` | Delaunay triangulation of a flat {x1,y1,...} point list. Returns a table of flat 6-number triangle tables. |
| `lurek.math.lineIntersect` | Infinite line intersection. Returns (x, y) or (nil, nil) if lines are parallel. |
| `lurek.math.pointInPolygon` | Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table. |
| `lurek.math.polygonArea` | Returns the signed area of a polygon given as a flat {x1,y1,...} table. |
| `lurek.math.polygonCentroid` | Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table. |
| `lurek.math.segmentIntersectsSegment` | Tests if two line segments intersect. Returns (hit, ix?, iy?). |
| `lurek.math.bresenham` | Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm. Returns a table of {x,y} tables. |
| `lurek.math.rad` | Converts degrees to radians. |
| `lurek.math.deg` | Converts radians to degrees. |
| `lurek.math.sin` | Returns the sine of x (radians). |
| `lurek.math.cos` | Returns the cosine of x (radians). |
| `lurek.math.tan` | Returns the tangent of x (radians). |
| `lurek.math.asin` | Returns the arcsine of x, in radians. |
| `lurek.math.acos` | Returns the arccosine of x, in radians. |
| `lurek.math.atan` | Returns the arctangent of x (or atan2(y, x) when two args given). |
| `lurek.math.atan2` | Returns atan(y/x) using the signs of both args to determine the quadrant. |
| `lurek.math.sqrt` | Returns the square root of x. |
| `lurek.math.abs` | Returns the absolute value of x. |
| `lurek.math.floor` | Returns the largest integer ≤ x. |
| `lurek.math.ceil` | Returns the smallest integer ≥ x. |
| `lurek.math.round` | Returns x rounded to the nearest integer (half-up). |
| `lurek.math.exp` | Returns e raised to the power x. |
| `lurek.math.log` | Returns the natural log of x, or log base b if b is supplied. |
| `lurek.math.pow` | Returns x raised to the power y. |
| `lurek.math.min` | Returns the smallest of the supplied numbers. |
| `lurek.math.max` | Returns the largest of the supplied numbers. |
| `lurek.math.clamp` | Returns x clamped to [lo, hi]. |
| `lurek.math.sign` | Returns -1, 0, or 1 depending on the sign of x. |
| `lurek.math.fmod` | Returns the remainder of x / y (fmod). |
| `lurek.math.lerp` | Linear interpolation between a and b by fraction t. |
| `lurek.math.distance` | Returns the Euclidean distance between (x1,y1) and (x2,y2). |
| `lurek.math.distanceSq` | Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt). |
| `lurek.math.random` | Returns a pseudo-random number in [0,1) with no args, |
| `lurek.math.randomInt` | Returns a pseudo-random integer in [lo, hi] (inclusive). |
| `lurek.math.simplexNoise` | Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates. |

### `BezierCurve` Methods

| Method | Description |
|--------|-------------|
| `beziercurve:evaluate(...)` | Evaluates the curve at parameter t, returning (x, y). |
| `beziercurve:render(...)` | Renders the curve as a polyline with the given number of segments. |
| `beziercurve:getDerivative(...)` | Returns a new BezierCurve representing the first derivative. |
| `beziercurve:getControlPoint(...)` | Returns the control point at 1-based index as (x, y), or nil. |
| `beziercurve:removeControlPoint(...)` | Removes a control point at 1-based index. |
| `beziercurve:getControlPointCount(...)` | Returns the number of control points. |
| `beziercurve:length(...)` | Returns the approximate arc length of the curve. |
| `beziercurve:translate(...)` | Translates all control points by (dx, dy). |
| `beziercurve:rotate(...)` | Rotates all control points around a pivot by angle radians. |
| `beziercurve:scale(...)` | Scales all control points around a pivot by factor s. |

### `NoiseGenerator` Methods

| Method | Description |
|--------|-------------|
| `noisegenerator:perlin1d(...)` | Returns 1D Perlin noise at x. |
| `noisegenerator:perlin2d(...)` | Returns 2D Perlin noise at (x, y). |
| `noisegenerator:perlin3d(...)` | Returns 3D Perlin noise at (x, y, z). |
| `noisegenerator:perlin4d(...)` | Returns 4D Perlin noise at (x, y, z, w). |
| `noisegenerator:simplex1d(...)` | Returns 1D Simplex noise at x. |
| `noisegenerator:simplex2d(...)` | Returns 2D Simplex noise at (x, y). |
| `noisegenerator:simplex3d(...)` | Returns 3D Simplex noise at (x, y, z). |
| `noisegenerator:getSeed(...)` | Returns the current seed. |
| `noisegenerator:setSeed(...)` | Sets the seed and rebuilds the permutation table. |

### `RandomGenerator` Methods

| Method | Description |
|--------|-------------|
| `randomgenerator:random(...)` | Returns a uniform random number in [0, 1). |
| `randomgenerator:randomFloat(...)` | Returns a uniform random float in [min, max). |
| `randomgenerator:randomInt(...)` | Returns a uniform random integer in [min, max]. |
| `randomgenerator:getSeed(...)` | Returns the seed used to initialise this generator. |
| `randomgenerator:setSeed(...)` | Sets the seed, fully resetting the generator state. |
| `randomgenerator:getState(...)` | Serialises the generator state as a string for later restoration. |
| `randomgenerator:setState(...)` | Restores the generator state from a previously serialised string. |

### `SpatialHash` Methods

| Method | Description |
|--------|-------------|
| `spatialhash:remove(...)` | Removes an item by its ID. |
| `spatialhash:clear(...)` | Removes all items. |
| `spatialhash:getCellSize(...)` | Returns the cell size. |
| `spatialhash:getItemCount(...)` | Returns the number of items in the hash. |

### `Transform` Methods

| Method | Description |
|--------|-------------|
| `transform:translate(...)` | Applies translation to the transform. |
| `transform:rotate(...)` | Applies a rotation in radians. |
| `transform:scale(...)` | Applies non-uniform scaling. |
| `transform:shear(...)` | Applies shear factors. |
| `transform:reset(...)` | Resets the transform to identity. |
| `transform:transformPoint(...)` | Transforms a point from local space to world space. |
| `transform:inverseTransformPoint(...)` | Transforms a point from world space back to local space. |
| `transform:inverse(...)` | Returns a new Transform that undoes this transform. |
| `transform:clone(...)` | Returns a copy of this transform. |
| `transform:getMatrix(...)` | Returns the 3x3 matrix as a flat table of 9 numbers (row-major). |

### `Tween` Methods

| Method | Description |
|--------|-------------|
| `tween:update(...)` | Advances the clock by dt seconds. Returns true when complete. |
| `tween:reset(...)` | Resets the clock to 0. |
| `tween:getValue(...)` | Returns the interpolated value at 1-based index, or all values as a |
| `tween:getAllValues(...)` | Returns all interpolated values as a table. |
| `tween:isComplete(...)` | Returns true if the tween has finished. |
| `tween:getValueCount(...)` | Returns the number of values in this tween. |
| `tween:getEasingName(...)` | Returns the easing function name. |
| `tween:getDuration(...)` | Returns the tween duration in seconds. |
| `tween:getTime(...)` | Returns the current clock time. |
| `tween:getClock(...)` | Alias for getTime(). Returns the current clock time. |
| `tween:setTime(...)` | Sets the clock to a specific time, clamped to [0, duration]. |
| `tween:set(...)` | Alias for setTime(). Sets the clock to t, clamped to [0, duration]. |
| `tween:addValue(...)` | Adds a start/target value pair. Returns the 1-based index. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.math.
if lurek.math then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 13 |
| `enum` | 3 |
| `fn` (Lua API) | 132 |
| **Total** | **148** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Foundations to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/math/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
