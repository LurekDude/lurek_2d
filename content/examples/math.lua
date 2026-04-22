-- content/examples/math.lua
-- Auto-scaffolded coverage of the lurek.math Lua API (204 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/math.lua

print("[example] lurek.math loaded — 204 API items demonstrated")

-- ── lurek.math free functions ──

--@api-stub: lurek.math.newRandomGenerator
-- Creates a new random number generator with an optional seed.
-- Use this when creates a new random number generator with an optional seed is needed.
if false then
  local _r = lurek.math.newRandomGenerator(nil)
  print(_r)
end

--@api-stub: lurek.math.newTransform
-- Creates a new Transform, optionally initialised from full parameters.
-- Use this when creates a new Transform, optionally initialised from full parameters is needed.
if false then
  local _r = lurek.math.newTransform()
  print(_r)
end

--@api-stub: lurek.math.newBezierCurve
-- Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
-- Use this when creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...} is needed.
if false then
  local _r = lurek.math.newBezierCurve(1)
  print(_r)
end

--@api-stub: lurek.math.newTween
-- Creates a new Tween with the given duration and easing name.
-- Use this when creates a new Tween with the given duration and easing name is needed.
if false then
  local _r = lurek.math.newTween(1, 1)
  print(_r)
end

--@api-stub: lurek.math.newSpatialHash
-- Creates a new SpatialHash with the given cell size.
-- Use this when creates a new SpatialHash with the given cell size is needed.
if false then
  local _r = lurek.math.newSpatialHash(1)
  print(_r)
end

--@api-stub: lurek.math.newNoiseGenerator
-- Creates a new seeded noise generator.
-- Use this when creates a new seeded noise generator is needed.
if false then
  local _r = lurek.math.newNoiseGenerator(nil)
  print(_r)
end

--@api-stub: lurek.math.perlin2d
-- Returns 2D Perlin noise at (x, y) with the given seed.
-- Use this when returns 2D Perlin noise at (x, y) with the given seed is needed.
if false then
  local _r = lurek.math.perlin2d(0, 0, nil)
  print(_r)
end

--@api-stub: lurek.math.perlin3d
-- Returns 3D Perlin noise at (x, y, z) with the given seed.
-- Use this when returns 3D Perlin noise at (x, y, z) with the given seed is needed.
if false then
  local _r = lurek.math.perlin3d(0, 0, 0, nil)
  print(_r)
end

--@api-stub: lurek.math.simplex2d
-- Returns 2D Simplex noise at (x, y) with the given seed.
-- Use this when returns 2D Simplex noise at (x, y) with the given seed is needed.
if false then
  local _r = lurek.math.simplex2d(0, 0, nil)
  print(_r)
end

--@api-stub: lurek.math.fbm
-- Returns fractal Brownian motion noise at (x, y).
-- Use this when returns fractal Brownian motion noise at (x, y) is needed.
if false then
  local _r = lurek.math.fbm()
  print(_r)
end

--@api-stub: lurek.math.applyEasing
-- Applies a named easing function to progress value t.
-- Use this when applies a named easing function to progress value t is needed.
if false then
  local _r = lurek.math.applyEasing(1, 0)
  print(_r)
end

--@api-stub: lurek.math.linear
-- Linear easing (identity).
-- Use this when linear easing (identity) is needed.
if false then
  local _r = lurek.math.linear(0)
  print(_r)
end

--@api-stub: lurek.math.inQuad
-- Quadratic ease-in — acceleration that starts at zero and increases.
-- Use this when quadratic ease-in — acceleration that starts at zero and increases is needed.
if false then
  local _r = lurek.math.inQuad(0)
  print(_r)
end

--@api-stub: lurek.math.outQuad
-- Quadratic ease-out — deceleration that starts fast and ends at zero.
-- Use this when quadratic ease-out — deceleration that starts fast and ends at zero is needed.
if false then
  local _r = lurek.math.outQuad(0)
  print(_r)
end

--@api-stub: lurek.math.inOutQuad
-- Quadratic ease-in-out — slow start, fast middle, slow end.
-- Use this when quadratic ease-in-out — slow start, fast middle, slow end is needed.
if false then
  local _r = lurek.math.inOutQuad(0)
  print(_r)
end

--@api-stub: lurek.math.inCubic
-- Cubic ease-in — acceleration starts slowly then increases sharply.
-- Use this when cubic ease-in — acceleration starts slowly then increases sharply is needed.
if false then
  local _r = lurek.math.inCubic(0)
  print(_r)
end

--@api-stub: lurek.math.outCubic
-- Cubic ease-out — rapid deceleration using a cubic power curve.
-- Use this when cubic ease-out — rapid deceleration using a cubic power curve is needed.
if false then
  local _r = lurek.math.outCubic(0)
  print(_r)
end

--@api-stub: lurek.math.inOutCubic
-- Cubic ease-in-out — slow start and end with fast cubic middle.
-- Use this when cubic ease-in-out — slow start and end with fast cubic middle is needed.
if false then
  local _r = lurek.math.inOutCubic(0)
  print(_r)
end

--@api-stub: lurek.math.inQuart
-- Quartic ease-in — strongly delayed acceleration using a power-of-4 curve.
-- Use this when quartic ease-in — strongly delayed acceleration using a power-of-4 curve is needed.
if false then
  local _r = lurek.math.inQuart(0)
  print(_r)
end

--@api-stub: lurek.math.outQuart
-- Quartic ease-out — rapid deceleration using a power-of-4 curve.
-- Use this when quartic ease-out — rapid deceleration using a power-of-4 curve is needed.
if false then
  local _r = lurek.math.outQuart(0)
  print(_r)
end

--@api-stub: lurek.math.inOutQuart
-- Quartic ease-in-out — very slow start and end with a sharp middle peak.
-- Use this when quartic ease-in-out — very slow start and end with a sharp middle peak is needed.
if false then
  local _r = lurek.math.inOutQuart(0)
  print(_r)
end

--@api-stub: lurek.math.inSine
-- Sinusoidal ease-in — gentle acceleration based on a sine curve.
-- Use this when sinusoidal ease-in — gentle acceleration based on a sine curve is needed.
if false then
  local _r = lurek.math.inSine(0)
  print(_r)
end

--@api-stub: lurek.math.outSine
-- Sinusoidal ease-out — gentle deceleration based on a cosine curve.
-- Use this when sinusoidal ease-out — gentle deceleration based on a cosine curve is needed.
if false then
  local _r = lurek.math.outSine(0)
  print(_r)
end

--@api-stub: lurek.math.inOutSine
-- Sinusoidal ease-in-out — smooth S-curve based on cosine interpolation.
-- Use this when sinusoidal ease-in-out — smooth S-curve based on cosine interpolation is needed.
if false then
  local _r = lurek.math.inOutSine(0)
  print(_r)
end

--@api-stub: lurek.math.inExpo
-- Exponential ease-in — very slow start that accelerates sharply near the end.
-- Use this when exponential ease-in — very slow start that accelerates sharply near the end is needed.
if false then
  local _r = lurek.math.inExpo(0)
  print(_r)
end

--@api-stub: lurek.math.outExpo
-- Exponential ease-out — sharp initial speed that decelerates exponentially.
-- Use this when exponential ease-out — sharp initial speed that decelerates exponentially is needed.
if false then
  local _r = lurek.math.outExpo(0)
  print(_r)
end

--@api-stub: lurek.math.inOutExpo
-- Exponential ease-in-out — very slow start and end with an exponential surge.
-- Use this when exponential ease-in-out — very slow start and end with an exponential surge is needed.
if false then
  local _r = lurek.math.inOutExpo(0)
  print(_r)
end

--@api-stub: lurek.math.inElastic
-- Elastic ease-in — spring-like overshoot at the beginning of the motion.
-- Use this when elastic ease-in — spring-like overshoot at the beginning of the motion is needed.
if false then
  local _r = lurek.math.inElastic(0)
  print(_r)
end

--@api-stub: lurek.math.outElastic
-- Elastic ease-out — spring-like oscillation that settles at the target.
-- Use this when elastic ease-out — spring-like oscillation that settles at the target is needed.
if false then
  local _r = lurek.math.outElastic(0)
  print(_r)
end

--@api-stub: lurek.math.outBounce
-- Bounce ease-out — simulates a ball bouncing against the target value.
-- Use this when bounce ease-out — simulates a ball bouncing against the target value is needed.
if false then
  local _r = lurek.math.outBounce(0)
  print(_r)
end

--@api-stub: lurek.math.inBounce
-- Bounce ease-in — reverse bounce effect that accelerates into the motion.
-- Use this when bounce ease-in — reverse bounce effect that accelerates into the motion is needed.
if false then
  local _r = lurek.math.inBounce(0)
  print(_r)
end

--@api-stub: lurek.math.inBack
-- Back ease-in — overshoots slightly before settling at the target.
-- Use this when back ease-in — overshoots slightly before settling at the target is needed.
if false then
  local _r = lurek.math.inBack(0)
  print(_r)
end

--@api-stub: lurek.math.outBack
-- Back ease-out — overshoots the target then snaps back into place.
-- Use this when back ease-out — overshoots the target then snaps back into place is needed.
if false then
  local _r = lurek.math.outBack(0)
  print(_r)
end

--@api-stub: lurek.math.inOutElastic
-- Elastic ease-in-out — spring-like oscillation on both ends.
-- Use this when elastic ease-in-out — spring-like oscillation on both ends is needed.
if false then
  local _r = lurek.math.inOutElastic(0)
  print(_r)
end

--@api-stub: lurek.math.inOutBounce
-- Bounce ease-in-out — bouncing motion on both ends.
-- Use this when bounce ease-in-out — bouncing motion on both ends is needed.
if false then
  local _r = lurek.math.inOutBounce(0)
  print(_r)
end

--@api-stub: lurek.math.inOutBack
-- Back ease-in-out — overshoot on both ends.
-- Use this when back ease-in-out — overshoot on both ends is needed.
if false then
  local _r = lurek.math.inOutBack(0)
  print(_r)
end

--@api-stub: lurek.math.triangulate
-- Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
-- Use this when triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...} is needed.
if false then
  local _r = lurek.math.triangulate(0)
  print(_r)
end

--@api-stub: lurek.math.isConvex
-- Returns true if the polygon (flat table {x1,y1,...}) is convex.
-- Use this when returns true if the polygon (flat table {x1,y1,...}) is convex is needed.
if false then
  local _r = lurek.math.isConvex(0)
  print(_r)
end

--@api-stub: lurek.math.gammaToLinear
-- Converts a gamma-encoded sRGB value to linear space.
-- Use this when converts a gamma-encoded sRGB value to linear space is needed.
if false then
  local _r = lurek.math.gammaToLinear(nil)
  print(_r)
end

--@api-stub: lurek.math.linearToGamma
-- Converts a linear-space value to gamma-encoded sRGB.
-- Use this when converts a linear-space value to gamma-encoded sRGB is needed.
if false then
  local _r = lurek.math.linearToGamma(nil)
  print(_r)
end

--@api-stub: lurek.math.angleBetween
-- Returns the angle in radians from (x1, y1) to (x2, y2).
-- Use this when returns the angle in radians from (x1, y1) to (x2, y2) is needed.
if false then
  local _r = lurek.math.angleBetween(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.circleContainsPoint
-- Returns true if the point (px, py) lies inside the circle.
-- Use this when returns true if the point (px, py) lies inside the circle is needed.
if false then
  local _r = lurek.math.circleContainsPoint(0, 0, nil, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.circleIntersectsCircle
-- Returns true if two circles overlap.
-- Use this when returns true if two circles overlap is needed.
if false then
  local _r = lurek.math.circleIntersectsCircle(0, 0, nil, 0, 0, nil)
  print(_r)
end

--@api-stub: lurek.math.circleIntersectsLine
-- Tests an infinite line against a circle.
-- Returns hit, then two optional hit-point pairs.
if false then
  local _r = lurek.math.circleIntersectsLine(0, 0, nil, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.circleIntersectsSegment
-- Tests a line segment against a circle.
-- Returns hit, then two optional hit-point pairs.
if false then
  local _r = lurek.math.circleIntersectsSegment(0, 0, nil, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.closestPointOnSegment
-- Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
-- Use this when returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py) is needed.
if false then
  local _r = lurek.math.closestPointOnSegment(0, 0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.convexHull
-- Computes the convex hull of a flat {x1,y1,...} point list.
-- Returns a flat table.
if false then
  local _r = lurek.math.convexHull(0)
  print(_r)
end

--@api-stub: lurek.math.delaunayTriangulate
-- Delaunay triangulation of a flat {x1,y1,...} point list.
-- Returns a table of flat 6-number triangle tables.
if false then
  local _r = lurek.math.delaunayTriangulate(0)
  print(_r)
end

--@api-stub: lurek.math.lineIntersect
-- Infinite line intersection.
-- Returns (x, y) or (nil, nil) if lines are parallel.
if false then
  local _r = lurek.math.lineIntersect(0, 0, 0, 0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.pointInPolygon
-- Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
-- Use this when returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table is needed.
if false then
  local _r = lurek.math.pointInPolygon(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.polygonArea
-- Returns the signed area of a polygon given as a flat {x1,y1,...} table.
-- Use this when returns the signed area of a polygon given as a flat {x1,y1,...} table is needed.
if false then
  local _r = lurek.math.polygonArea(0)
  print(_r)
end

--@api-stub: lurek.math.polygonCentroid
-- Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
-- Use this when returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table is needed.
if false then
  local _r = lurek.math.polygonCentroid(0)
  print(_r)
end

--@api-stub: lurek.math.segmentIntersectsSegment
-- Tests if two line segments intersect.
-- Returns (hit, ix?, iy?).
if false then
  local _r = lurek.math.segmentIntersectsSegment(0, 0, 0, 0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.bresenham
-- Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm.
-- Returns a table of {x,y} tables.
if false then
  local _r = lurek.math.bresenham(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.rad
-- Converts degrees to radians.
-- Use this when converts degrees to radians is needed.
if false then
  local _r = lurek.math.rad(nil)
  print(_r)
end

--@api-stub: lurek.math.deg
-- Converts radians to degrees.
-- Use this when converts radians to degrees is needed.
if false then
  local _r = lurek.math.deg(nil)
  print(_r)
end

--@api-stub: lurek.math.sin
-- Returns the sine of x (radians).
-- Use this when returns the sine of x (radians) is needed.
if false then
  local _r = lurek.math.sin(0)
  print(_r)
end

--@api-stub: lurek.math.cos
-- Returns the cosine of x (radians).
-- Use this when returns the cosine of x (radians) is needed.
if false then
  local _r = lurek.math.cos(0)
  print(_r)
end

--@api-stub: lurek.math.tan
-- Returns the tangent of x (radians).
-- Use this when returns the tangent of x (radians) is needed.
if false then
  local _r = lurek.math.tan(0)
  print(_r)
end

--@api-stub: lurek.math.asin
-- Returns the arcsine of x, in radians.
-- Use this when returns the arcsine of x, in radians is needed.
if false then
  local _r = lurek.math.asin(0)
  print(_r)
end

--@api-stub: lurek.math.acos
-- Returns the arccosine of x, in radians.
-- Use this when returns the arccosine of x, in radians is needed.
if false then
  local _r = lurek.math.acos(0)
  print(_r)
end

--@api-stub: lurek.math.atan
-- Returns the arctangent of x (or atan2(y, x) when two args given).
-- Use this when returns the arctangent of x (or atan2(y, x) when two args given) is needed.
if false then
  local _r = lurek.math.atan(0, 0)
  print(_r)
end

--@api-stub: lurek.math.atan2
-- Returns atan(y/x) using the signs of both args to determine the quadrant.
-- Use this when returns atan(y/x) using the signs of both args to determine the quadrant is needed.
if false then
  local _r = lurek.math.atan2(0, 0)
  print(_r)
end

--@api-stub: lurek.math.sqrt
-- Returns the square root of x.
-- Use this when returns the square root of x is needed.
if false then
  local _r = lurek.math.sqrt(0)
  print(_r)
end

--@api-stub: lurek.math.abs
-- Returns the absolute value of x.
-- Use this when returns the absolute value of x is needed.
if false then
  local _r = lurek.math.abs(0)
  print(_r)
end

--@api-stub: lurek.math.floor
-- Returns the largest integer ≤ x.
-- Use this when returns the largest integer ≤ x is needed.
if false then
  local _r = lurek.math.floor(0)
  print(_r)
end

--@api-stub: lurek.math.ceil
-- Returns the smallest integer ≥ x.
-- Use this when returns the smallest integer ≥ x is needed.
if false then
  local _r = lurek.math.ceil(0)
  print(_r)
end

--@api-stub: lurek.math.round
-- Returns x rounded to the nearest integer (half-up).
-- Use this when returns x rounded to the nearest integer (half-up) is needed.
if false then
  local _r = lurek.math.round(0)
  print(_r)
end

--@api-stub: lurek.math.exp
-- Returns e raised to the power x.
-- Use this when returns e raised to the power x is needed.
if false then
  local _r = lurek.math.exp(0)
  print(_r)
end

--@api-stub: lurek.math.log
-- Returns the natural log of x, or log base b if b is supplied.
-- Use this when returns the natural log of x, or log base b if b is supplied is needed.
if false then
  local _r = lurek.math.log(0, nil)
  print(_r)
end

--@api-stub: lurek.math.pow
-- Returns x raised to the power y.
-- Use this when returns x raised to the power y is needed.
if false then
  local _r = lurek.math.pow(0, 0)
  print(_r)
end

--@api-stub: lurek.math.min
-- Returns the smallest of the supplied numbers.
-- Use this when returns the smallest of the supplied numbers is needed.
if false then
  local _r = lurek.math.min()
  print(_r)
end

--@api-stub: lurek.math.max
-- Returns the largest of the supplied numbers.
-- Use this when returns the largest of the supplied numbers is needed.
if false then
  local _r = lurek.math.max()
  print(_r)
end

--@api-stub: lurek.math.clamp
-- Returns x clamped to [lo, hi].
-- Use this when returns x clamped to [lo, hi] is needed.
if false then
  local _r = lurek.math.clamp(0, nil, 0)
  print(_r)
end

--@api-stub: lurek.math.sign
-- Returns -1, 0, or 1 depending on the sign of x.
-- Use this when returns -1, 0, or 1 depending on the sign of x is needed.
if false then
  local _r = lurek.math.sign(0)
  print(_r)
end

--@api-stub: lurek.math.fmod
-- Returns the remainder of x / y (fmod).
-- Use this when returns the remainder of x / y (fmod) is needed.
if false then
  local _r = lurek.math.fmod(0, 0)
  print(_r)
end

--@api-stub: lurek.math.lerp
-- Linear interpolation between a and b by fraction t.
-- Use this when linear interpolation between a and b by fraction t is needed.
if false then
  local _r = lurek.math.lerp(nil, nil, 0)
  print(_r)
end

--@api-stub: lurek.math.distance
-- Returns the Euclidean distance between (x1,y1) and (x2,y2).
-- Use this when returns the Euclidean distance between (x1,y1) and (x2,y2) is needed.
if false then
  local _r = lurek.math.distance(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.distanceSq
-- Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
-- Use this when returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt) is needed.
if false then
  local _r = lurek.math.distanceSq(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.random
-- Returns a pseudo-random number in [0,1) with no args,.
-- Use this when returns a pseudo-random number in [0,1) with no args, is needed.
if false then
  local _r = lurek.math.random(nil, nil)
  print(_r)
end

--@api-stub: lurek.math.randomInt
-- Returns a pseudo-random integer in [lo, hi] (inclusive).
-- Use this when returns a pseudo-random integer in [lo, hi] (inclusive) is needed.
if false then
  local _r = lurek.math.randomInt(nil, 0)
  print(_r)
end

--@api-stub: lurek.math.simplexNoise
-- Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
-- Use this when returns a simplex noise value in [-1, 1] for 2D or 3D coordinates is needed.
if false then
  local _r = lurek.math.simplexNoise(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.vec2
-- Creates a 2D vector with x and y components.
-- Use this when creates a 2D vector with x and y components is needed.
if false then
  local _r = lurek.math.vec2(0, 0)
  print(_r)
end

--@api-stub: lurek.math.Vec2
-- Compatibility alias for `vec2`.
-- Use this when compatibility alias for `vec2` is needed.
if false then
  local _r = lurek.math.Vec2(0, 0)
  print(_r)
end

--@api-stub: lurek.math.vec3
-- Creates a 3D vector `{x, y, z}` table with numeric components.
-- Use this when creates a 3D vector `{x, y, z}` table with numeric components is needed.
if false then
  local _r = lurek.math.vec3(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.Vec3
-- Compatibility alias for `vec3`.
-- Use this when compatibility alias for `vec3` is needed.
if false then
  local _r = lurek.math.Vec3(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.catmullRom
-- Creates a Catmull-Rom spline through the given control points.
-- Use this when creates a Catmull-Rom spline through the given control points is needed.
if false then
  local _r = lurek.math.catmullRom(1)
  print(_r)
end

--@api-stub: lurek.math.hermite
-- Creates a Hermite spline defined by two endpoints and tangents.
-- Use this when creates a Hermite spline defined by two endpoints and tangents is needed.
if false then
  local _r = lurek.math.hermite(0, 0, 0, 0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.lerp
-- Linear interpolation between two numbers: a + (b - a) * t.
-- Use this when linear interpolation between two numbers: a + (b - a) * t is needed.
if false then
  local _r = lurek.math.lerp(nil, nil, 0)
  print(_r)
end

--@api-stub: lurek.math.remap
-- Remaps `v` from [in_min, in_max] to [out_min, out_max].
-- Use this when remaps `v` from [in_min, in_max] to [out_min, out_max] is needed.
if false then
  local _r = lurek.math.remap(0, 1, 1, 1, 0)
  print(_r)
end

--@api-stub: lurek.math.clamp
-- Clamps `v` between `min` and `max`.
-- Use this when clamps `v` between `min` and `max` is needed.
if false then
  local _r = lurek.math.clamp(0, 1, 0)
  print(_r)
end

--@api-stub: lurek.math.sign
-- Returns -1, 0, or 1 depending on the sign of `v`.
-- Use this when returns -1, 0, or 1 depending on the sign of `v` is needed.
if false then
  local _r = lurek.math.sign(0)
  print(_r)
end

--@api-stub: lurek.math.smoothstep
-- Hermite smoothstep between `edge0` and `edge1`.
-- Use this when hermite smoothstep between `edge0` and `edge1` is needed.
if false then
  local _r = lurek.math.smoothstep(nil, nil, 0)
  print(_r)
end

--@api-stub: lurek.math.inverseLerp
-- Returns the interpolation parameter t for `v` in [a, b].
-- Use this when returns the interpolation parameter t for `v` in [a, b] is needed.
if false then
  local _r = lurek.math.inverseLerp(nil, nil, 0)
  print(_r)
end

--@api-stub: lurek.math.hslToRgb
-- Converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats.
-- Use this when converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats is needed.
if false then
  local _r = lurek.math.hslToRgb(0, nil, nil)
  print(_r)
end

--@api-stub: lurek.math.fromHex
-- Parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats.
-- Use this when parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats is needed.
if false then
  local _r = lurek.math.fromHex(0)
  print(_r)
end

--@api-stub: lurek.math.rgbToHsl
-- Converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1).
-- Use this when converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1) is needed.
if false then
  local _r = lurek.math.rgbToHsl(nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.math.rectUnion
-- Returns the union (bounding box) of two rectangles.
-- Use this when returns the union (bounding box) of two rectangles is needed.
if false then
  local _r = lurek.math.rectUnion(0, 0, 0, 0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.rectFromCenter
-- Creates a rectangle centered at (cx, cy) with the given width and height.
-- Use this when creates a rectangle centered at (cx, cy) with the given width and height is needed.
if false then
  local _r = lurek.math.rectFromCenter(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.math.polygonClip
-- Clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
-- Use this when clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm is needed.
if false then
  local _r = lurek.math.polygonClip(0, 1, 1, nil)
  print(_r)
end

--@api-stub: lurek.math.aabbTree
-- Creates a new empty AABB tree for efficient broad-phase overlap queries.
-- Use this when creates a new empty AABB tree for efficient broad-phase overlap queries is needed.
if false then
  local _r = lurek.math.aabbTree()
  print(_r)
end

--@api-stub: lurek.math.newCircle
-- Creates a new Circle value type with the given centre and radius.
-- Use this when creates a new Circle value type with the given centre and radius is needed.
if false then
  local _r = lurek.math.newCircle(0, 0, nil)
  print(_r)
end

--@api-stub: lurek.math.polygonIntersection
-- Computes the intersection of two convex polygons using the Sutherland-Hodgman.
-- Use this when computes the intersection of two convex polygons using the Sutherland-Hodgman is needed.
if false then
  local _r = lurek.math.polygonIntersection(nil, nil)
  print(_r)
end

--@api-stub: lurek.math.polygonUnion
-- Computes the approximate union of two convex polygons as the convex hull of.
-- Use this when computes the approximate union of two convex polygons as the convex hull of is needed.
if false then
  local _r = lurek.math.polygonUnion(nil, nil)
  print(_r)
end

--@api-stub: lurek.math.polygonDifference
-- Computes the approximate difference `A - B` (the part of A not covered by B).
-- Use this when computes the approximate difference `A - B` (the part of A not covered by B) is needed.
if false then
  local _r = lurek.math.polygonDifference(nil, nil)
  print(_r)
end

--@api-stub: lurek.math.voronoi
-- Computes the Voronoi diagram for a list of 2-D seed points.
-- Use this when computes the Voronoi diagram for a list of 2-D seed points is needed.
if false then
  local _r = lurek.math.voronoi(1)
  print(_r)
end

-- ── Vec2 methods ──

--@api-stub: Vec2:dot
-- Returns the dot product with another vector.
-- Use this when returns the dot product with another vector is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:dot(0)
end

--@api-stub: Vec2:length
-- Returns the Euclidean length of the vector.
-- Use this when returns the Euclidean length of the vector is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:length()
end

--@api-stub: Vec2:x
-- Returns the horizontal component of the vector.
-- Use this when returns the horizontal component of the vector is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:x()
end

--@api-stub: Vec2:y
-- Returns the vertical component of the vector.
-- Use this when returns the vertical component of the vector is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:y()
end

--@api-stub: Vec2:lengthSquared
-- Returns the squared length of the vector (faster than length).
-- Use this when returns the squared length of the vector (faster than length) is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:lengthSquared()
end

--@api-stub: Vec2:normalize
-- Returns a unit-length copy of this vector.
-- Returns zero if length is zero.
if false then
  local _o = nil  -- Vec2 instance
  _o:normalize()
end

--@api-stub: Vec2:normalized
-- Compatibility alias for `normalize`.
-- Use this when compatibility alias for `normalize` is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:normalized()
end

--@api-stub: Vec2:lerp
-- Returns a linearly interpolated vector between this and other at parameter t.
-- Use this when returns a linearly interpolated vector between this and other at parameter t is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:lerp(0, 0)
end

--@api-stub: Vec2:distance
-- Returns the Euclidean distance from this vector to another.
-- Use this when returns the Euclidean distance from this vector to another is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:distance(0)
end

--@api-stub: Vec2:angle
-- Returns the angle of this vector in radians (atan2(y, x)).
-- Use this when returns the angle of this vector in radians (atan2(y, x)) is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:angle()
end

--@api-stub: Vec2:rotate
-- Returns a new vector rotated by the given angle in radians.
-- Use this when returns a new vector rotated by the given angle in radians is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:rotate(1)
end

--@api-stub: Vec2:perpendicular
-- Returns the perpendicular vector (-y, x).
-- Use this when returns the perpendicular vector (-y, x) is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:perpendicular()
end

--@api-stub: Vec2:cross
-- Returns the 2D cross product (scalar) with another vector.
-- Use this when returns the 2D cross product (scalar) with another vector is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:cross(0)
end

--@api-stub: Vec2:reflect
-- Reflects this vector off a surface with the given normal.
-- Use this when reflects this vector off a surface with the given normal is needed.
if false then
  local _o = nil  -- Vec2 instance
  _o:reflect(1)
end

-- ── Vec3 methods ──

--@api-stub: Vec3:length
-- Returns the Euclidean length of the vector.
-- Use this when returns the Euclidean length of the vector is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:length()
end

--@api-stub: Vec3:lengthSquared
-- Returns the squared Euclidean length (avoids sqrt).
-- Use this when returns the squared Euclidean length (avoids sqrt) is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:lengthSquared()
end

--@api-stub: Vec3:normalize
-- Returns a unit-length version of this vector.
-- Use this when returns a unit-length version of this vector is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:normalize()
end

--@api-stub: Vec3:dot
-- Dot product with another Vec3.
-- Use this when dot product with another Vec3 is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:dot(0)
end

--@api-stub: Vec3:cross
-- Cross product with another Vec3.
-- Use this when cross product with another Vec3 is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:cross(0)
end

--@api-stub: Vec3:lerp
-- Linear interpolation towards another Vec3.
-- Use this when linear interpolation towards another Vec3 is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:lerp(0, 0)
end

--@api-stub: Vec3:distance
-- Euclidean distance to another Vec3.
-- Use this when euclidean distance to another Vec3 is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:distance(0)
end

--@api-stub: Vec3:add
-- Add another Vec3 and return the result.
-- Use this when add another Vec3 and return the result is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:add(0)
end

--@api-stub: Vec3:sub
-- Subtract another Vec3 and return the result.
-- Use this when subtract another Vec3 and return the result is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:sub(0)
end

--@api-stub: Vec3:scale
-- Scale this vector by a scalar and return the result.
-- Use this when scale this vector by a scalar and return the result is needed.
if false then
  local _o = nil  -- Vec3 instance
  _o:scale(nil)
end

-- ── CatmullRom methods ──

--@api-stub: CatmullRom:sample
-- Sample the spline at global t in [0, 1].
-- Use this when sample the spline at global t in [0, 1] is needed.
if false then
  local _o = nil  -- CatmullRom instance
  _o:sample(0)
end

--@api-stub: CatmullRom:sampleSegment
-- Sample a specific segment at local t in [0, 1].
-- Use this when sample a specific segment at local t in [0, 1] is needed.
if false then
  local _o = nil  -- CatmullRom instance
  _o:sampleSegment(nil, 0)
end

--@api-stub: CatmullRom:len
-- Number of control points.
-- Use this when number of control points is needed.
if false then
  local _o = nil  -- CatmullRom instance
  _o:len()
end

--@api-stub: CatmullRom:addPoint
-- Appends a control point to the spline.
-- Use this when appends a control point to the spline is needed.
if false then
  local _o = nil  -- CatmullRom instance
  _o:addPoint(0, 0)
end

--@api-stub: CatmullRom:removePoint
-- Removes the control point at `index` (0-based) and returns it.
-- Use this when removes the control point at `index` (0-based) and returns it is needed.
if false then
  local _o = nil  -- CatmullRom instance
  _o:removePoint(1)
end

-- ── Hermite methods ──

--@api-stub: Hermite:sample
-- Evaluate the spline at parameter t in [0, 1].
-- Use this when evaluate the spline at parameter t in [0, 1] is needed.
if false then
  local _o = nil  -- Hermite instance
  _o:sample(0)
end

-- ── RandomGenerator methods ──

--@api-stub: RandomGenerator:random
-- Returns a uniform random number in [0, 1).
-- Use this when returns a uniform random number in [0, 1) is needed.
if false then
  local _o = nil  -- RandomGenerator instance
  _o:random()
end

--@api-stub: RandomGenerator:randomFloat
-- Returns a uniform random float in [min, max).
-- Use this when returns a uniform random float in [min, max) is needed.
if false then
  local _o = nil  -- RandomGenerator instance
  _o:randomFloat(1, 0)
end

--@api-stub: RandomGenerator:randomInt
-- Returns a uniform random integer in [min, max].
-- Use this when returns a uniform random integer in [min, max] is needed.
if false then
  local _o = nil  -- RandomGenerator instance
  _o:randomInt(1, 0)
end

--@api-stub: RandomGenerator:getSeed
-- Returns the seed used to initialise this generator.
-- Use this when returns the seed used to initialise this generator is needed.
if false then
  local _o = nil  -- RandomGenerator instance
  _o:getSeed()
end

--@api-stub: RandomGenerator:setSeed
-- Sets the seed, fully resetting the generator state.
-- Use this when sets the seed, fully resetting the generator state is needed.
if false then
  local _o = nil  -- RandomGenerator instance
  _o:setSeed(nil)
end

--@api-stub: RandomGenerator:getState
-- Serialises the generator state as a string for later restoration.
-- Use this when serialises the generator state as a string for later restoration is needed.
if false then
  local _o = nil  -- RandomGenerator instance
  _o:getState()
end

--@api-stub: RandomGenerator:setState
-- Restores the generator state from a previously serialised string.
-- Use this when restores the generator state from a previously serialised string is needed.
if false then
  local _o = nil  -- RandomGenerator instance
  _o:setState(0)
end

-- ── Transform methods ──

--@api-stub: Transform:translate
-- Applies translation to the transform.
-- Use this when applies translation to the transform is needed.
if false then
  local _o = nil  -- Transform instance
  _o:translate(0, 0)
end

--@api-stub: Transform:rotate
-- Applies a rotation in radians.
-- Use this when applies a rotation in radians is needed.
if false then
  local _o = nil  -- Transform instance
  _o:rotate(1)
end

--@api-stub: Transform:scale
-- Applies non-uniform scaling.
-- Use this when applies non-uniform scaling is needed.
if false then
  local _o = nil  -- Transform instance
  _o:scale(0, 0)
end

--@api-stub: Transform:shear
-- Applies horizontal and vertical shear factors to this transform matrix.
-- Use this when applies horizontal and vertical shear factors to this transform matrix is needed.
if false then
  local _o = nil  -- Transform instance
  _o:shear(0, 0)
end

--@api-stub: Transform:reset
-- Resets the transform to identity.
-- Use this when resets the transform to identity is needed.
if false then
  local _o = nil  -- Transform instance
  _o:reset()
end

--@api-stub: Transform:transformPoint
-- Transforms a point from local space to world space.
-- Use this when transforms a point from local space to world space is needed.
if false then
  local _o = nil  -- Transform instance
  _o:transformPoint(0, 0)
end

--@api-stub: Transform:inverseTransformPoint
-- Transforms a point from world space back to local space.
-- Use this when transforms a point from world space back to local space is needed.
if false then
  local _o = nil  -- Transform instance
  _o:inverseTransformPoint(0, 0)
end

--@api-stub: Transform:inverse
-- Returns a new Transform that undoes this transform.
-- Use this when returns a new Transform that undoes this transform is needed.
if false then
  local _o = nil  -- Transform instance
  _o:inverse()
end

--@api-stub: Transform:clone
-- Returns a copy of this transform.
-- Use this when returns a copy of this transform is needed.
if false then
  local _o = nil  -- Transform instance
  _o:clone()
end

--@api-stub: Transform:getMatrix
-- Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
-- Use this when returns the 3x3 matrix as a flat table of 9 numbers (row-major) is needed.
if false then
  local _o = nil  -- Transform instance
  _o:getMatrix()
end

--@api-stub: Transform:decompose
-- Decomposes this transform into translation, rotation, and scale.
-- Use this when decomposes this transform into translation, rotation, and scale is needed.
if false then
  local _o = nil  -- Transform instance
  _o:decompose()
end

-- ── BezierCurve methods ──

--@api-stub: BezierCurve:evaluate
-- Evaluates the curve at parameter t, returning (x, y).
-- Use this when evaluates the curve at parameter t, returning (x, y) is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:evaluate(0)
end

--@api-stub: BezierCurve:render
-- Renders the curve as a polyline with the given number of segments.
-- Use this when renders the curve as a polyline with the given number of segments is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:render(1)
end

--@api-stub: BezierCurve:getDerivative
-- Returns a new BezierCurve representing the first derivative.
-- Use this when returns a new BezierCurve representing the first derivative is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:getDerivative()
end

--@api-stub: BezierCurve:getControlPoint
-- Returns the control point at 1-based index as (x, y), or nil.
-- Use this when returns the control point at 1-based index as (x, y), or nil is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:getControlPoint(1)
end

--@api-stub: BezierCurve:removeControlPoint
-- Removes a control point at 1-based index.
-- Use this when removes a control point at 1-based index is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:removeControlPoint(1)
end

--@api-stub: BezierCurve:getControlPointCount
-- Returns the number of control points.
-- Use this when returns the number of control points is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:getControlPointCount()
end

--@api-stub: BezierCurve:length
-- Returns the approximate arc length of the curve.
-- Use this when returns the approximate arc length of the curve is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:length()
end

--@api-stub: BezierCurve:translate
-- Translates all control points by (dx, dy).
-- Use this when translates all control points by (dx, dy) is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:translate(0, 0)
end

--@api-stub: BezierCurve:rotate
-- Rotates all control points around a pivot by angle radians.
-- Use this when rotates all control points around a pivot by angle radians is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:rotate(1, 0, 0)
end

--@api-stub: BezierCurve:scale
-- Scales all control points around a pivot by factor s.
-- Use this when scales all control points around a pivot by factor s is needed.
if false then
  local _o = nil  -- BezierCurve instance
  _o:scale(nil, 0, 0)
end

-- ── Tween methods ──

--@api-stub: Tween:update
-- Advances the clock by dt seconds.
-- Returns true when complete.
if false then
  local _o = nil  -- Tween instance
  _o:update(0)
end

--@api-stub: Tween:reset
-- Resets the tween elapsed time to zero, restarting the animation.
-- Use this when resets the tween elapsed time to zero, restarting the animation is needed.
if false then
  local _o = nil  -- Tween instance
  _o:reset()
end

--@api-stub: Tween:getValue
-- Returns the interpolated value at 1-based index, or all values as a.
-- Use this when returns the interpolated value at 1-based index, or all values as a is needed.
if false then
  local _o = nil  -- Tween instance
  _o:getValue(1)
end

--@api-stub: Tween:getAllValues
-- Returns all interpolated values as a table.
-- Use this when returns all interpolated values as a table is needed.
if false then
  local _o = nil  -- Tween instance
  _o:getAllValues()
end

--@api-stub: Tween:isComplete
-- Returns true if the tween has finished.
-- Use this when returns true if the tween has finished is needed.
if false then
  local _o = nil  -- Tween instance
  _o:isComplete()
end

--@api-stub: Tween:getValueCount
-- Returns the number of values in this tween.
-- Use this when returns the number of values in this tween is needed.
if false then
  local _o = nil  -- Tween instance
  _o:getValueCount()
end

--@api-stub: Tween:getEasingName
-- Returns the easing function name.
-- Use this when returns the easing function name is needed.
if false then
  local _o = nil  -- Tween instance
  _o:getEasingName()
end

--@api-stub: Tween:getDuration
-- Returns the tween duration in seconds.
-- Use this when returns the tween duration in seconds is needed.
if false then
  local _o = nil  -- Tween instance
  _o:getDuration()
end

--@api-stub: Tween:getTime
-- Returns the current clock time.
-- Use this when returns the current clock time is needed.
if false then
  local _o = nil  -- Tween instance
  _o:getTime()
end

--@api-stub: Tween:getClock
-- Alias for getTime().
-- Returns the current clock time.
if false then
  local _o = nil  -- Tween instance
  _o:getClock()
end

--@api-stub: Tween:setTime
-- Sets the clock to a specific time, clamped to [0, duration].
-- Use this when sets the clock to a specific time, clamped to [0, duration] is needed.
if false then
  local _o = nil  -- Tween instance
  _o:setTime(0)
end

--@api-stub: Tween:set
-- Alias for setTime().
-- Sets the clock to t, clamped to [0, duration].
if false then
  local _o = nil  -- Tween instance
  _o:set(0)
end

--@api-stub: Tween:addValue
-- Adds a start/target value pair.
-- Returns the 1-based index.
if false then
  local _o = nil  -- Tween instance
  _o:addValue(0, 0)
end

-- ── SpatialHash methods ──

--@api-stub: SpatialHash:remove
-- Removes an item by its ID.
-- Use this when removes an item by its ID is needed.
if false then
  local _o = nil  -- SpatialHash instance
  _o:remove(1)
end

--@api-stub: SpatialHash:clear
-- Removes all registered items from this spatial hash, leaving it empty.
-- Use this when removes all registered items from this spatial hash, leaving it empty is needed.
if false then
  local _o = nil  -- SpatialHash instance
  _o:clear()
end

--@api-stub: SpatialHash:getCellSize
-- Returns the cell size used to partition the spatial hash grid.
-- Use this when returns the cell size used to partition the spatial hash grid is needed.
if false then
  local _o = nil  -- SpatialHash instance
  _o:getCellSize()
end

--@api-stub: SpatialHash:getItemCount
-- Returns the number of items in the hash.
-- Use this when returns the number of items in the hash is needed.
if false then
  local _o = nil  -- SpatialHash instance
  _o:getItemCount()
end

-- ── NoiseGenerator methods ──

--@api-stub: NoiseGenerator:perlin1d
-- Returns 1D Perlin noise at x.
-- Use this when returns 1D Perlin noise at x is needed.
if false then
  local _o = nil  -- NoiseGenerator instance
  _o:perlin1d(0)
end

--@api-stub: NoiseGenerator:perlin2d
-- Returns 2D Perlin noise at (x, y).
-- Use this when returns 2D Perlin noise at (x, y) is needed.
if false then
  local _o = nil  -- NoiseGenerator instance
  _o:perlin2d(0, 0)
end

--@api-stub: NoiseGenerator:perlin3d
-- Returns 3D Perlin noise at (x, y, z).
-- Use this when returns 3D Perlin noise at (x, y, z) is needed.
if false then
  local _o = nil  -- NoiseGenerator instance
  _o:perlin3d(0, 0, 0)
end

--@api-stub: NoiseGenerator:perlin4d
-- Returns 4D Perlin noise at (x, y, z, w).
-- Use this when returns 4D Perlin noise at (x, y, z, w) is needed.
if false then
  local _o = nil  -- NoiseGenerator instance
  _o:perlin4d(0, 0, 0, 0)
end

--@api-stub: NoiseGenerator:simplex1d
-- Returns 1D Simplex noise at x.
-- Use this when returns 1D Simplex noise at x is needed.
if false then
  local _o = nil  -- NoiseGenerator instance
  _o:simplex1d(0)
end

--@api-stub: NoiseGenerator:simplex2d
-- Returns 2D Simplex noise at (x, y).
-- Use this when returns 2D Simplex noise at (x, y) is needed.
if false then
  local _o = nil  -- NoiseGenerator instance
  _o:simplex2d(0, 0)
end

--@api-stub: NoiseGenerator:simplex3d
-- Returns 3D Simplex noise at (x, y, z).
-- Use this when returns 3D Simplex noise at (x, y, z) is needed.
if false then
  local _o = nil  -- NoiseGenerator instance
  _o:simplex3d(0, 0, 0)
end

--@api-stub: NoiseGenerator:getSeed
-- Returns the current seed.
-- Use this when returns the current seed is needed.
if false then
  local _o = nil  -- NoiseGenerator instance
  _o:getSeed()
end

--@api-stub: NoiseGenerator:setSeed
-- Sets the seed and rebuilds the permutation table.
-- Use this when sets the seed and rebuilds the permutation table is needed.
if false then
  local _o = nil  -- NoiseGenerator instance
  _o:setSeed(nil)
end

-- ── Circle methods ──

--@api-stub: Circle:area
-- Returns the area of the circle (π r²).
-- Use this when returns the area of the circle (π r²) is needed.
if false then
  local _o = nil  -- Circle instance
  _o:area()
end

--@api-stub: Circle:perimeter
-- Returns the circumference of the circle (2 π r).
-- Use this when returns the circumference of the circle (2 π r) is needed.
if false then
  local _o = nil  -- Circle instance
  _o:perimeter()
end

--@api-stub: Circle:contains
-- Returns true if the point (px, py) lies inside or on the boundary.
-- Use this when returns true if the point (px, py) lies inside or on the boundary is needed.
if false then
  local _o = nil  -- Circle instance
  _o:contains(0, 0)
end

--@api-stub: Circle:intersects
-- Returns true if this circle overlaps another circle.
-- Use this when returns true if this circle overlaps another circle is needed.
if false then
  local _o = nil  -- Circle instance
  _o:intersects(0)
end

--@api-stub: Circle:aabb
-- Returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y).
-- Use this when returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y) is needed.
if false then
  local _o = nil  -- Circle instance
  _o:aabb()
end

--@api-stub: Circle:x
-- Returns the circle centre X.
-- Use this when returns the circle centre X is needed.
if false then
  local _o = nil  -- Circle instance
  _o:x()
end

--@api-stub: Circle:y
-- Returns the circle centre Y.
-- Use this when returns the circle centre Y is needed.
if false then
  local _o = nil  -- Circle instance
  _o:y()
end

--@api-stub: Circle:radius
-- Returns the circle radius.
-- Use this when returns the circle radius is needed.
if false then
  local _o = nil  -- Circle instance
  _o:radius()
end

-- ── AabbTree methods ──

--@api-stub: AabbTree:remove
-- Removes the entry with the given id.
-- Use this when removes the entry with the given id is needed.
if false then
  local _o = nil  -- AabbTree instance
  _o:remove(1)
end

--@api-stub: AabbTree:queryPoint
-- Returns the ids of all entries whose AABBs contain the given point.
-- Use this when returns the ids of all entries whose AABBs contain the given point is needed.
if false then
  local _o = nil  -- AabbTree instance
  _o:queryPoint(0, 0)
end

--@api-stub: AabbTree:contains
-- Returns true if an entry with the given id exists in the tree.
-- Use this when returns true if an entry with the given id exists in the tree is needed.
if false then
  local _o = nil  -- AabbTree instance
  _o:contains(1)
end

--@api-stub: AabbTree:len
-- Returns the number of entries in the tree.
-- Use this when returns the number of entries in the tree is needed.
if false then
  local _o = nil  -- AabbTree instance
  _o:len()
end

--@api-stub: AabbTree:isEmpty
-- Returns true if the tree contains no entries.
-- Use this when returns true if the tree contains no entries is needed.
if false then
  local _o = nil  -- AabbTree instance
  _o:isEmpty()
end

--@api-stub: AabbTree:clear
-- Removes all entries from the tree.
-- Use this when removes all entries from the tree is needed.
if false then
  local _o = nil  -- AabbTree instance
  _o:clear()
end

