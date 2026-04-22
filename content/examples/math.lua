-- content/examples/math.lua
-- Practical usage examples for the lurek.math API (204 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.math.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/math.lua

print("[example] lurek.math — 204 API entries")

-- ── lurek.math.* free functions ──

--@api-stub: lurek.math.newRandomGenerator
-- Creates a new random number generator with an optional seed.
-- Call when you need to create a new random generator.
local ok, obj = pcall(function() return lurek.math.newRandomGenerator(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.math.newRandomGenerator ok=", ok)

--@api-stub: lurek.math.newTransform
-- Creates a new Transform, optionally initialised from full parameters.
-- Call when you need to create a new transform.
local ok, obj = pcall(function() return lurek.math.newTransform() end)
if ok and obj then print("created:", obj) end
print("lurek.math.newTransform ok=", ok)

--@api-stub: lurek.math.newBezierCurve
-- Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
-- Call when you need to create a new bezier curve.
local ok, obj = pcall(function() return lurek.math.newBezierCurve(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.math.newBezierCurve ok=", ok)

--@api-stub: lurek.math.newTween
-- Creates a new Tween with the given duration and easing name.
-- Call when you need to create a new tween.
local ok, obj = pcall(function() return lurek.math.newTween(1.0, "easing_name") end)
if ok and obj then print("created:", obj) end
print("lurek.math.newTween ok=", ok)

--@api-stub: lurek.math.newSpatialHash
-- Creates a new SpatialHash with the given cell size.
-- Call when you need to create a new spatial hash.
local ok, obj = pcall(function() return lurek.math.newSpatialHash(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.math.newSpatialHash ok=", ok)

--@api-stub: lurek.math.newNoiseGenerator
-- Creates a new seeded noise generator.
-- Call when you need to create a new noise generator.
local ok, obj = pcall(function() return lurek.math.newNoiseGenerator(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.math.newNoiseGenerator ok=", ok)

--@api-stub: lurek.math.perlin2d
-- Returns 2D Perlin noise at (x, y) with the given seed.
-- Call when you need to invoke perlin2d.
local ok, result = pcall(function() return lurek.math.perlin2d(0, 0, nil) end)
if ok then print("lurek.math.perlin2d ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.perlin3d
-- Returns 3D Perlin noise at (x, y, z) with the given seed.
-- Call when you need to invoke perlin3d.
local ok, result = pcall(function() return lurek.math.perlin3d(0, 0, 0, nil) end)
if ok then print("lurek.math.perlin3d ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.simplex2d
-- Returns 2D Simplex noise at (x, y) with the given seed.
-- Call when you need to invoke simplex2d.
local ok, result = pcall(function() return lurek.math.simplex2d(0, 0, nil) end)
if ok then print("lurek.math.simplex2d ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.fbm
-- Returns fractal Brownian motion noise at (x, y).
-- Call when you need to invoke fbm.
local ok, result = pcall(function() return lurek.math.fbm() end)
if ok then print("lurek.math.fbm ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.applyEasing
-- Applies a named easing function to progress value t.
-- Call when you need to invoke apply easing.
local ok, err = pcall(function() lurek.math.applyEasing("name", nil) end)
if not ok then print("set skipped:", err) end
print("lurek.math.applyEasing applied=", ok)

--@api-stub: lurek.math.linear
-- Linear easing (identity).
-- Call when you need to invoke linear.
local ok, result = pcall(function() return lurek.math.linear(nil) end)
if ok then print("lurek.math.linear ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inQuad
-- Quadratic ease-in — acceleration that starts at zero and increases.
-- Call when you need to invoke in quad.
local ok, result = pcall(function() return lurek.math.inQuad(nil) end)
if ok then print("lurek.math.inQuad ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.outQuad
-- Quadratic ease-out — deceleration that starts fast and ends at zero.
-- Call when you need to invoke out quad.
local ok, result = pcall(function() return lurek.math.outQuad(nil) end)
if ok then print("lurek.math.outQuad ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inOutQuad
-- Quadratic ease-in-out — slow start, fast middle, slow end.
-- Call when you need to invoke in out quad.
local ok, result = pcall(function() return lurek.math.inOutQuad(nil) end)
if ok then print("lurek.math.inOutQuad ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inCubic
-- Cubic ease-in — acceleration starts slowly then increases sharply.
-- Call when you need to invoke in cubic.
local ok, result = pcall(function() return lurek.math.inCubic(nil) end)
if ok then print("lurek.math.inCubic ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.outCubic
-- Cubic ease-out — rapid deceleration using a cubic power curve.
-- Call when you need to invoke out cubic.
local ok, result = pcall(function() return lurek.math.outCubic(nil) end)
if ok then print("lurek.math.outCubic ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inOutCubic
-- Cubic ease-in-out — slow start and end with fast cubic middle.
-- Call when you need to invoke in out cubic.
local ok, result = pcall(function() return lurek.math.inOutCubic(nil) end)
if ok then print("lurek.math.inOutCubic ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inQuart
-- Quartic ease-in — strongly delayed acceleration using a power-of-4 curve.
-- Call when you need to invoke in quart.
local ok, result = pcall(function() return lurek.math.inQuart(nil) end)
if ok then print("lurek.math.inQuart ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.outQuart
-- Quartic ease-out — rapid deceleration using a power-of-4 curve.
-- Call when you need to invoke out quart.
local ok, result = pcall(function() return lurek.math.outQuart(nil) end)
if ok then print("lurek.math.outQuart ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inOutQuart
-- Quartic ease-in-out — very slow start and end with a sharp middle peak.
-- Call when you need to invoke in out quart.
local ok, result = pcall(function() return lurek.math.inOutQuart(nil) end)
if ok then print("lurek.math.inOutQuart ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inSine
-- Sinusoidal ease-in — gentle acceleration based on a sine curve.
-- Call when you need to invoke in sine.
local ok, result = pcall(function() return lurek.math.inSine(nil) end)
if ok then print("lurek.math.inSine ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.outSine
-- Sinusoidal ease-out — gentle deceleration based on a cosine curve.
-- Call when you need to invoke out sine.
local ok, result = pcall(function() return lurek.math.outSine(nil) end)
if ok then print("lurek.math.outSine ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inOutSine
-- Sinusoidal ease-in-out — smooth S-curve based on cosine interpolation.
-- Call when you need to invoke in out sine.
local ok, result = pcall(function() return lurek.math.inOutSine(nil) end)
if ok then print("lurek.math.inOutSine ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inExpo
-- Exponential ease-in — very slow start that accelerates sharply near the end.
-- Call when you need to invoke in expo.
local ok, result = pcall(function() return lurek.math.inExpo(nil) end)
if ok then print("lurek.math.inExpo ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.outExpo
-- Exponential ease-out — sharp initial speed that decelerates exponentially.
-- Call when you need to invoke out expo.
local ok, result = pcall(function() return lurek.math.outExpo(nil) end)
if ok then print("lurek.math.outExpo ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inOutExpo
-- Exponential ease-in-out — very slow start and end with an exponential surge.
-- Call when you need to invoke in out expo.
local ok, result = pcall(function() return lurek.math.inOutExpo(nil) end)
if ok then print("lurek.math.inOutExpo ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inElastic
-- Elastic ease-in — spring-like overshoot at the beginning of the motion.
-- Call when you need to invoke in elastic.
local ok, result = pcall(function() return lurek.math.inElastic(nil) end)
if ok then print("lurek.math.inElastic ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.outElastic
-- Elastic ease-out — spring-like oscillation that settles at the target.
-- Call when you need to invoke out elastic.
local ok, result = pcall(function() return lurek.math.outElastic(nil) end)
if ok then print("lurek.math.outElastic ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.outBounce
-- Bounce ease-out — simulates a ball bouncing against the target value.
-- Call when you need to invoke out bounce.
local ok, result = pcall(function() return lurek.math.outBounce(nil) end)
if ok then print("lurek.math.outBounce ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inBounce
-- Bounce ease-in — reverse bounce effect that accelerates into the motion.
-- Call when you need to invoke in bounce.
local ok, result = pcall(function() return lurek.math.inBounce(nil) end)
if ok then print("lurek.math.inBounce ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inBack
-- Back ease-in — overshoots slightly before settling at the target.
-- Call when you need to invoke in back.
local ok, result = pcall(function() return lurek.math.inBack(nil) end)
if ok then print("lurek.math.inBack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.outBack
-- Back ease-out — overshoots the target then snaps back into place.
-- Call when you need to invoke out back.
local ok, result = pcall(function() return lurek.math.outBack(nil) end)
if ok then print("lurek.math.outBack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inOutElastic
-- Elastic ease-in-out — spring-like oscillation on both ends.
-- Call when you need to invoke in out elastic.
local ok, result = pcall(function() return lurek.math.inOutElastic(nil) end)
if ok then print("lurek.math.inOutElastic ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inOutBounce
-- Bounce ease-in-out — bouncing motion on both ends.
-- Call when you need to invoke in out bounce.
local ok, result = pcall(function() return lurek.math.inOutBounce(nil) end)
if ok then print("lurek.math.inOutBounce ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inOutBack
-- Back ease-in-out — overshoot on both ends.
-- Call when you need to invoke in out back.
local ok, result = pcall(function() return lurek.math.inOutBack(nil) end)
if ok then print("lurek.math.inOutBack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.triangulate
-- Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
-- Call when you need to invoke triangulate.
local ok, result = pcall(function() return lurek.math.triangulate(nil) end)
if ok then print("lurek.math.triangulate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.isConvex
-- Returns true if the polygon (flat table {x1,y1,...}) is convex.
-- Call when you need to check is convex.
local ok, result = pcall(function() return lurek.math.isConvex(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.math.isConvex ok=", ok)

--@api-stub: lurek.math.gammaToLinear
-- Converts a gamma-encoded sRGB value to linear space.
-- Call when you need to invoke gamma to linear.
local ok, result = pcall(function() return lurek.math.gammaToLinear(nil) end)
if ok then print("lurek.math.gammaToLinear ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.linearToGamma
-- Converts a linear-space value to gamma-encoded sRGB.
-- Call when you need to invoke linear to gamma.
local ok, result = pcall(function() return lurek.math.linearToGamma(nil) end)
if ok then print("lurek.math.linearToGamma ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.angleBetween
-- Returns the angle in radians from (x1, y1) to (x2, y2).
-- Call when you need to invoke angle between.
local ok, result = pcall(function() return lurek.math.angleBetween(nil, nil, nil, nil) end)
if ok then print("lurek.math.angleBetween ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.circleContainsPoint
-- Returns true if the point (px, py) lies inside the circle.
-- Call when you need to invoke circle contains point.
local ok, result = pcall(function() return lurek.math.circleContainsPoint(nil, nil, 1, nil, nil) end)
if ok then print("lurek.math.circleContainsPoint ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.circleIntersectsCircle
-- Returns true if two circles overlap.
-- Call when you need to invoke circle intersects circle.
local ok, result = pcall(function() return lurek.math.circleIntersectsCircle(nil, nil, nil, nil, nil, nil) end)
if ok then print("lurek.math.circleIntersectsCircle ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.circleIntersectsLine
-- Tests an infinite line against a circle.
-- Returns hit, then two optional hit-point pairs.
local ok, result = pcall(function() return lurek.math.circleIntersectsLine(nil, nil, 1, nil, nil, nil, nil) end)
if ok then print("lurek.math.circleIntersectsLine ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.circleIntersectsSegment
-- Tests a line segment against a circle.
-- Returns hit, then two optional hit-point pairs.
local ok, result = pcall(function() return lurek.math.circleIntersectsSegment(nil, nil, 1, nil, nil, nil, nil) end)
if ok then print("lurek.math.circleIntersectsSegment ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.closestPointOnSegment
-- Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
-- Call when you need to invoke closest point on segment.
local ok, result = pcall(function() return lurek.math.closestPointOnSegment(nil, nil, nil, nil, nil, nil) end)
if ok then print("lurek.math.closestPointOnSegment ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.convexHull
-- Computes the convex hull of a flat {x1,y1,...} point list.
-- Returns a flat table.
local ok, result = pcall(function() return lurek.math.convexHull(nil) end)
if ok then print("lurek.math.convexHull ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.delaunayTriangulate
-- Delaunay triangulation of a flat {x1,y1,...} point list.
-- Returns a table of flat 6-number triangle tables.
local ok, result = pcall(function() return lurek.math.delaunayTriangulate(nil) end)
if ok then print("lurek.math.delaunayTriangulate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.lineIntersect
-- Infinite line intersection.
-- Returns (x, y) or (nil, nil) if lines are parallel.
local ok, result = pcall(function() return lurek.math.lineIntersect(nil, nil, nil, nil, nil, nil, nil, nil) end)
if ok then print("lurek.math.lineIntersect ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.pointInPolygon
-- Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
-- Call when you need to invoke point in polygon.
local ok, result = pcall(function() return lurek.math.pointInPolygon(nil, nil, nil) end)
if ok then print("lurek.math.pointInPolygon ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.polygonArea
-- Returns the signed area of a polygon given as a flat {x1,y1,...} table.
-- Call when you need to invoke polygon area.
local ok, result = pcall(function() return lurek.math.polygonArea(nil) end)
if ok then print("lurek.math.polygonArea ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.polygonCentroid
-- Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
-- Call when you need to invoke polygon centroid.
local ok, result = pcall(function() return lurek.math.polygonCentroid(nil) end)
if ok then print("lurek.math.polygonCentroid ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.segmentIntersectsSegment
-- Tests if two line segments intersect.
-- Returns (hit, ix?, iy?).
local ok, result = pcall(function() return lurek.math.segmentIntersectsSegment(nil, nil, nil, nil, nil, nil, nil, nil) end)
if ok then print("lurek.math.segmentIntersectsSegment ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.bresenham
-- Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm.
-- Returns a table of {x,y} tables.
local ok, result = pcall(function() return lurek.math.bresenham(nil, nil, nil, nil) end)
if ok then print("lurek.math.bresenham ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.rad
-- Converts degrees to radians.
-- Call when you need to invoke rad.
local ok, result = pcall(function() return lurek.math.rad(nil) end)
if ok then print("lurek.math.rad ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.deg
-- Converts radians to degrees.
-- Call when you need to invoke deg.
local ok, result = pcall(function() return lurek.math.deg(nil) end)
if ok then print("lurek.math.deg ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.sin
-- Returns the sine of x (radians).
-- Call when you need to invoke sin.
local ok, result = pcall(function() return lurek.math.sin(0) end)
if ok then print("lurek.math.sin ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.cos
-- Returns the cosine of x (radians).
-- Call when you need to invoke cos.
local ok, result = pcall(function() return lurek.math.cos(0) end)
if ok then print("lurek.math.cos ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.tan
-- Returns the tangent of x (radians).
-- Call when you need to invoke tan.
local ok, result = pcall(function() return lurek.math.tan(0) end)
if ok then print("lurek.math.tan ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.asin
-- Returns the arcsine of x, in radians.
-- Call when you need to invoke asin.
local ok, result = pcall(function() return lurek.math.asin(0) end)
if ok then print("lurek.math.asin ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.acos
-- Returns the arccosine of x, in radians.
-- Call when you need to invoke acos.
local ok, result = pcall(function() return lurek.math.acos(0) end)
if ok then print("lurek.math.acos ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.atan
-- Returns the arctangent of x (or atan2(y, x) when two args given).
-- Call when you need to invoke atan.
local ok, result = pcall(function() return lurek.math.atan(0, 0) end)
if ok then print("lurek.math.atan ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.atan2
-- Returns atan(y/x) using the signs of both args to determine the quadrant.
-- Call when you need to invoke atan2.
local ok, result = pcall(function() return lurek.math.atan2(0, 0) end)
if ok then print("lurek.math.atan2 ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.sqrt
-- Returns the square root of x.
-- Call when you need to invoke sqrt.
local ok, result = pcall(function() return lurek.math.sqrt(0) end)
if ok then print("lurek.math.sqrt ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.abs
-- Returns the absolute value of x.
-- Call when you need to invoke abs.
local ok, result = pcall(function() return lurek.math.abs(0) end)
if ok then print("lurek.math.abs ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.floor
-- Returns the largest integer ≤ x.
-- Call when you need to invoke floor.
local ok, result = pcall(function() return lurek.math.floor(0) end)
if ok then print("lurek.math.floor ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.ceil
-- Returns the smallest integer ≥ x.
-- Call when you need to invoke ceil.
local ok, result = pcall(function() return lurek.math.ceil(0) end)
if ok then print("lurek.math.ceil ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.round
-- Returns x rounded to the nearest integer (half-up).
-- Call when you need to invoke round.
local ok, result = pcall(function() return lurek.math.round(0) end)
if ok then print("lurek.math.round ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.exp
-- Returns e raised to the power x.
-- Call when you need to invoke exp.
local ok, result = pcall(function() return lurek.math.exp(0) end)
if ok then print("lurek.math.exp ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.log
-- Returns the natural log of x, or log base b if b is supplied.
-- Call when you need to invoke log.
local ok, result = pcall(function() return lurek.math.log(0, 1) end)
if ok then print("lurek.math.log ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.pow
-- Returns x raised to the power y.
-- Call when you need to invoke pow.
local ok, result = pcall(function() return lurek.math.pow(0, 0) end)
if ok then print("lurek.math.pow ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.min
-- Returns the smallest of the supplied numbers.
-- Call when you need to invoke min.
local ok, result = pcall(function() return lurek.math.min() end)
if ok then print("lurek.math.min ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.max
-- Returns the largest of the supplied numbers.
-- Call when you need to invoke max.
local ok, result = pcall(function() return lurek.math.max() end)
if ok then print("lurek.math.max ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.clamp
-- Returns x clamped to [lo, hi].
-- Call when you need to invoke clamp.
local ok, result = pcall(function() return lurek.math.clamp(0, nil, nil) end)
if ok then print("lurek.math.clamp ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.sign
-- Returns -1, 0, or 1 depending on the sign of x.
-- Call when you need to invoke sign.
local ok, result = pcall(function() return lurek.math.sign(0) end)
if ok then print("lurek.math.sign ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.fmod
-- Returns the remainder of x / y (fmod).
-- Call when you need to invoke fmod.
local ok, result = pcall(function() return lurek.math.fmod(0, 0) end)
if ok then print("lurek.math.fmod ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.lerp
-- Linear interpolation between a and b by fraction t.
-- Call when you need to invoke lerp.
local ok, result = pcall(function() return lurek.math.lerp(1, 1, nil) end)
if ok then print("lurek.math.lerp ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.distance
-- Returns the Euclidean distance between (x1,y1) and (x2,y2).
-- Call when you need to invoke distance.
local ok, result = pcall(function() return lurek.math.distance(nil, nil, nil, nil) end)
if ok then print("lurek.math.distance ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.distanceSq
-- Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
-- Call when you need to invoke distance sq.
local ok, result = pcall(function() return lurek.math.distanceSq(nil, nil, nil, nil) end)
if ok then print("lurek.math.distanceSq ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.random
-- Returns a pseudo-random number in [0,1) with no args,.
-- Call when you need to invoke random.
local ok, result = pcall(function() return lurek.math.random(1, 1) end)
if ok then print("lurek.math.random ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.randomInt
-- Returns a pseudo-random integer in [lo, hi] (inclusive).
-- Call when you need to invoke random int.
local ok, result = pcall(function() return lurek.math.randomInt(nil, nil) end)
if ok then print("lurek.math.randomInt ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.simplexNoise
-- Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
-- Call when you need to invoke simplex noise.
local ok, result = pcall(function() return lurek.math.simplexNoise(0, 0, 0) end)
if ok then print("lurek.math.simplexNoise ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.vec2
-- Creates a 2D vector with x and y components.
-- Call when you need to invoke vec2.
local ok, result = pcall(function() return lurek.math.vec2(0, 0) end)
if ok then print("lurek.math.vec2 ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.Vec2
-- Compatibility alias for `vec2`.
-- Call when you need to invoke vec2.
local ok, result = pcall(function() return lurek.math.Vec2(0, 0) end)
if ok then print("lurek.math.Vec2 ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.vec3
-- Creates a 3D vector `{x, y, z}` table with numeric components.
-- Call when you need to invoke vec3.
local ok, result = pcall(function() return lurek.math.vec3(0, 0, 0) end)
if ok then print("lurek.math.vec3 ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.Vec3
-- Compatibility alias for `vec3`.
-- Call when you need to invoke vec3.
local ok, result = pcall(function() return lurek.math.Vec3(0, 0, 0) end)
if ok then print("lurek.math.Vec3 ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.catmullRom
-- Creates a Catmull-Rom spline through the given control points.
-- Call when you need to invoke catmull rom.
local ok, result = pcall(function() return lurek.math.catmullRom(nil) end)
if ok then print("lurek.math.catmullRom ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.hermite
-- Creates a Hermite spline defined by two endpoints and tangents.
-- Call when you need to invoke hermite.
local ok, result = pcall(function() return lurek.math.hermite(nil, nil, nil, nil, nil, nil, nil, nil) end)
if ok then print("lurek.math.hermite ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.lerp
-- Linear interpolation between two numbers: a + (b - a) * t.
-- Call when you need to invoke lerp.
local ok, result = pcall(function() return lurek.math.lerp(1, 1, nil) end)
if ok then print("lurek.math.lerp ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.remap
-- Remaps `v` from [in_min, in_max] to [out_min, out_max].
-- Call when you need to invoke remap.
local ok, result = pcall(function() return lurek.math.remap(nil, nil, nil, nil, nil) end)
if ok then print("lurek.math.remap ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.clamp
-- Clamps `v` between `min` and `max`.
-- Call when you need to invoke clamp.
local ok, result = pcall(function() return lurek.math.clamp(nil, 0, 100) end)
if ok then print("lurek.math.clamp ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.sign
-- Returns -1, 0, or 1 depending on the sign of `v`.
-- Call when you need to invoke sign.
local ok, result = pcall(function() return lurek.math.sign(nil) end)
if ok then print("lurek.math.sign ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.smoothstep
-- Hermite smoothstep between `edge0` and `edge1`.
-- Call when you need to invoke smoothstep.
local ok, result = pcall(function() return lurek.math.smoothstep(nil, nil, 0) end)
if ok then print("lurek.math.smoothstep ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.inverseLerp
-- Returns the interpolation parameter t for `v` in [a, b].
-- Call when you need to invoke inverse lerp.
local ok, result = pcall(function() return lurek.math.inverseLerp(1, 1, nil) end)
if ok then print("lurek.math.inverseLerp ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.hslToRgb
-- Converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats.
-- Call when you need to invoke hsl to rgb.
local ok, result = pcall(function() return lurek.math.hslToRgb(100, nil, nil) end)
if ok then print("lurek.math.hslToRgb ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.fromHex
-- Parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats.
-- Call when you need to invoke from hex.
local ok, obj = pcall(function() return lurek.math.fromHex(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.math.fromHex ok=", ok)

--@api-stub: lurek.math.rgbToHsl
-- Converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1).
-- Call when you need to invoke rgb to hsl.
local ok, result = pcall(function() return lurek.math.rgbToHsl(1, 1, 1) end)
if ok then print("lurek.math.rgbToHsl ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.rectUnion
-- Returns the union (bounding box) of two rectangles.
-- Call when you need to invoke rect union.
local ok, result = pcall(function() return lurek.math.rectUnion(nil, nil, nil, nil, nil, nil, nil, nil) end)
if ok then print("lurek.math.rectUnion ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.rectFromCenter
-- Creates a rectangle centered at (cx, cy) with the given width and height.
-- Call when you need to invoke rect from center.
local ok, result = pcall(function() return lurek.math.rectFromCenter(nil, nil, 100, 100) end)
if ok then print("lurek.math.rectFromCenter ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.polygonClip
-- Clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
-- Call when you need to invoke polygon clip.
local ok, result = pcall(function() return lurek.math.polygonClip(nil, nil, nil, nil) end)
if ok then print("lurek.math.polygonClip ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.aabbTree
-- Creates a new empty AABB tree for efficient broad-phase overlap queries.
-- Call when you need to invoke aabb tree.
local ok, result = pcall(function() return lurek.math.aabbTree() end)
if ok then print("lurek.math.aabbTree ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.newCircle
-- Creates a new Circle value type with the given centre and radius.
-- Call when you need to create a new circle.
local ok, obj = pcall(function() return lurek.math.newCircle(0, 0, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.math.newCircle ok=", ok)

--@api-stub: lurek.math.polygonIntersection
-- Computes the intersection of two convex polygons using the Sutherland-Hodgman.
-- Call when you need to invoke polygon intersection.
local ok, result = pcall(function() return lurek.math.polygonIntersection(1, 1) end)
if ok then print("lurek.math.polygonIntersection ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.polygonUnion
-- Computes the approximate union of two convex polygons as the convex hull of.
-- Call when you need to invoke polygon union.
local ok, result = pcall(function() return lurek.math.polygonUnion(1, 1) end)
if ok then print("lurek.math.polygonUnion ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.polygonDifference
-- Computes the approximate difference `A - B` (the part of A not covered by B).
-- Call when you need to invoke polygon difference.
local ok, result = pcall(function() return lurek.math.polygonDifference(1, 1) end)
if ok then print("lurek.math.polygonDifference ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.math.voronoi
-- Computes the Voronoi diagram for a list of 2-D seed points.
-- Call when you need to invoke voronoi.
local ok, result = pcall(function() return lurek.math.voronoi(nil) end)
if ok then print("lurek.math.voronoi ->", result)
else print("unavailable:", result) end

-- ── Vec2 methods ──

--@api-stub: Vec2:dot
-- Returns the dot product with another vector.
-- Call when you need to invoke dot.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:dot(nil) end)
  print("Vec2:dot ->", ok, result)
end

--@api-stub: Vec2:length
-- Returns the Euclidean length of the vector.
-- Call when you need to invoke length.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:length() end)
  print("Vec2:length ->", ok, result)
end

--@api-stub: Vec2:x
-- Returns the horizontal component of the vector.
-- Call when you need to invoke x.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:x() end)
  print("Vec2:x ->", ok, result)
end

--@api-stub: Vec2:y
-- Returns the vertical component of the vector.
-- Call when you need to invoke y.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:y() end)
  print("Vec2:y ->", ok, result)
end

--@api-stub: Vec2:lengthSquared
-- Returns the squared length of the vector (faster than length).
-- Call when you need to invoke length squared.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:lengthSquared() end)
  print("Vec2:lengthSquared ->", ok, result)
end

--@api-stub: Vec2:normalize
-- Returns a unit-length copy of this vector.
-- Returns zero if length is zero.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:normalize() end)
  print("Vec2:normalize ->", ok, result)
end

--@api-stub: Vec2:normalized
-- Compatibility alias for `normalize`.
-- Call when you need to invoke normalized.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:normalized() end)
  print("Vec2:normalized ->", ok, result)
end

--@api-stub: Vec2:lerp
-- Returns a linearly interpolated vector between this and other at parameter t.
-- Call when you need to invoke lerp.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:lerp(nil, nil) end)
  print("Vec2:lerp ->", ok, result)
end

--@api-stub: Vec2:distance
-- Returns the Euclidean distance from this vector to another.
-- Call when you need to invoke distance.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:distance(nil) end)
  print("Vec2:distance ->", ok, result)
end

--@api-stub: Vec2:angle
-- Returns the angle of this vector in radians (atan2(y, x)).
-- Call when you need to invoke angle.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:angle() end)
  print("Vec2:angle ->", ok, result)
end

--@api-stub: Vec2:rotate
-- Returns a new vector rotated by the given angle in radians.
-- Call when you need to invoke rotate.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:rotate(0) end)
  print("Vec2:rotate ->", ok, result)
end

--@api-stub: Vec2:perpendicular
-- Returns the perpendicular vector (-y, x).
-- Call when you need to invoke perpendicular.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:perpendicular() end)
  print("Vec2:perpendicular ->", ok, result)
end

--@api-stub: Vec2:cross
-- Returns the 2D cross product (scalar) with another vector.
-- Call when you need to invoke cross.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:cross(nil) end)
  print("Vec2:cross ->", ok, result)
end

--@api-stub: Vec2:reflect
-- Reflects this vector off a surface with the given normal.
-- Call when you need to invoke reflect.
-- Build a Vec2 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec2(...)
if instance then
  local ok, result = pcall(function() return instance:reflect(nil) end)
  print("Vec2:reflect ->", ok, result)
end

-- ── Vec3 methods ──

--@api-stub: Vec3:length
-- Returns the Euclidean length of the vector.
-- Call when you need to invoke length.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:length() end)
  print("Vec3:length ->", ok, result)
end

--@api-stub: Vec3:lengthSquared
-- Returns the squared Euclidean length (avoids sqrt).
-- Call when you need to invoke length squared.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:lengthSquared() end)
  print("Vec3:lengthSquared ->", ok, result)
end

--@api-stub: Vec3:normalize
-- Returns a unit-length version of this vector.
-- Call when you need to invoke normalize.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:normalize() end)
  print("Vec3:normalize ->", ok, result)
end

--@api-stub: Vec3:dot
-- Dot product with another Vec3.
-- Call when you need to invoke dot.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:dot(nil) end)
  print("Vec3:dot ->", ok, result)
end

--@api-stub: Vec3:cross
-- Cross product with another Vec3.
-- Call when you need to invoke cross.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:cross(nil) end)
  print("Vec3:cross ->", ok, result)
end

--@api-stub: Vec3:lerp
-- Linear interpolation towards another Vec3.
-- Call when you need to invoke lerp.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:lerp(nil, nil) end)
  print("Vec3:lerp ->", ok, result)
end

--@api-stub: Vec3:distance
-- Euclidean distance to another Vec3.
-- Call when you need to invoke distance.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:distance(nil) end)
  print("Vec3:distance ->", ok, result)
end

--@api-stub: Vec3:add
-- Add another Vec3 and return the result.
-- Call when you need to invoke add.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:add(nil) end)
  print("Vec3:add ->", ok, result)
end

--@api-stub: Vec3:sub
-- Subtract another Vec3 and return the result.
-- Call when you need to invoke sub.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:sub(nil) end)
  print("Vec3:sub ->", ok, result)
end

--@api-stub: Vec3:scale
-- Scale this vector by a scalar and return the result.
-- Call when you need to invoke scale.
-- Build a Vec3 via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newVec3(...)
if instance then
  local ok, result = pcall(function() return instance:scale(nil) end)
  print("Vec3:scale ->", ok, result)
end

-- ── CatmullRom methods ──

--@api-stub: CatmullRom:sample
-- Sample the spline at global t in [0, 1].
-- Call when you need to invoke sample.
-- Build a CatmullRom via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCatmullRom(...)
if instance then
  local ok, result = pcall(function() return instance:sample(nil) end)
  print("CatmullRom:sample ->", ok, result)
end

--@api-stub: CatmullRom:sampleSegment
-- Sample a specific segment at local t in [0, 1].
-- Call when you need to invoke sample segment.
-- Build a CatmullRom via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCatmullRom(...)
if instance then
  local ok, result = pcall(function() return instance:sampleSegment(nil, nil) end)
  print("CatmullRom:sampleSegment ->", ok, result)
end

--@api-stub: CatmullRom:len
-- Number of control points.
-- Call when you need to invoke len.
-- Build a CatmullRom via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCatmullRom(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("CatmullRom:len ->", ok, result)
end

--@api-stub: CatmullRom:addPoint
-- Appends a control point to the spline.
-- Call when you need to add point.
-- Build a CatmullRom via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCatmullRom(...)
if instance then
  local ok, result = pcall(function() return instance:addPoint(0, 0) end)
  print("CatmullRom:addPoint ->", ok, result)
end

--@api-stub: CatmullRom:removePoint
-- Removes the control point at `index` (0-based) and returns it.
-- Call when you need to remove point.
-- Build a CatmullRom via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCatmullRom(...)
if instance then
  local ok, result = pcall(function() return instance:removePoint(1) end)
  print("CatmullRom:removePoint ->", ok, result)
end

-- ── Hermite methods ──

--@api-stub: Hermite:sample
-- Evaluate the spline at parameter t in [0, 1].
-- Call when you need to invoke sample.
-- Build a Hermite via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newHermite(...)
if instance then
  local ok, result = pcall(function() return instance:sample(nil) end)
  print("Hermite:sample ->", ok, result)
end

-- ── RandomGenerator methods ──

--@api-stub: RandomGenerator:random
-- Returns a uniform random number in [0, 1).
-- Call when you need to invoke random.
-- Build a RandomGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newRandomGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:random() end)
  print("RandomGenerator:random ->", ok, result)
end

--@api-stub: RandomGenerator:randomFloat
-- Returns a uniform random float in [min, max).
-- Call when you need to invoke random float.
-- Build a RandomGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newRandomGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:randomFloat(0, 100) end)
  print("RandomGenerator:randomFloat ->", ok, result)
end

--@api-stub: RandomGenerator:randomInt
-- Returns a uniform random integer in [min, max].
-- Call when you need to invoke random int.
-- Build a RandomGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newRandomGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:randomInt(0, 100) end)
  print("RandomGenerator:randomInt ->", ok, result)
end

--@api-stub: RandomGenerator:getSeed
-- Returns the seed used to initialise this generator.
-- Call when you need to read seed.
-- Build a RandomGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newRandomGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:getSeed() end)
  print("RandomGenerator:getSeed ->", ok, result)
end

--@api-stub: RandomGenerator:setSeed
-- Sets the seed, fully resetting the generator state.
-- Call when you need to assign seed.
-- Build a RandomGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newRandomGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:setSeed(nil) end)
  print("RandomGenerator:setSeed ->", ok, result)
end

--@api-stub: RandomGenerator:getState
-- Serialises the generator state as a string for later restoration.
-- Call when you need to read state.
-- Build a RandomGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newRandomGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:getState() end)
  print("RandomGenerator:getState ->", ok, result)
end

--@api-stub: RandomGenerator:setState
-- Restores the generator state from a previously serialised string.
-- Call when you need to assign state.
-- Build a RandomGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newRandomGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:setState(nil) end)
  print("RandomGenerator:setState ->", ok, result)
end

-- ── Transform methods ──

--@api-stub: Transform:translate
-- Applies translation to the transform.
-- Call when you need to invoke translate.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:translate(0, 0) end)
  print("Transform:translate ->", ok, result)
end

--@api-stub: Transform:rotate
-- Applies a rotation in radians.
-- Call when you need to invoke rotate.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:rotate(0) end)
  print("Transform:rotate ->", ok, result)
end

--@api-stub: Transform:scale
-- Applies non-uniform scaling.
-- Call when you need to invoke scale.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:scale(nil, nil) end)
  print("Transform:scale ->", ok, result)
end

--@api-stub: Transform:shear
-- Applies horizontal and vertical shear factors to this transform matrix.
-- Call when you need to invoke shear.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:shear(nil, nil) end)
  print("Transform:shear ->", ok, result)
end

--@api-stub: Transform:reset
-- Resets the transform to identity.
-- Call when you need to invoke reset.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("Transform:reset ->", ok, result)
end

--@api-stub: Transform:transformPoint
-- Transforms a point from local space to world space.
-- Call when you need to invoke transform point.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:transformPoint(0, 0) end)
  print("Transform:transformPoint ->", ok, result)
end

--@api-stub: Transform:inverseTransformPoint
-- Transforms a point from world space back to local space.
-- Call when you need to invoke inverse transform point.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:inverseTransformPoint(0, 0) end)
  print("Transform:inverseTransformPoint ->", ok, result)
end

--@api-stub: Transform:inverse
-- Returns a new Transform that undoes this transform.
-- Call when you need to invoke inverse.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:inverse() end)
  print("Transform:inverse ->", ok, result)
end

--@api-stub: Transform:clone
-- Returns a copy of this transform.
-- Call when you need to invoke clone.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:clone() end)
  print("Transform:clone ->", ok, result)
end

--@api-stub: Transform:getMatrix
-- Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
-- Call when you need to read matrix.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:getMatrix() end)
  print("Transform:getMatrix ->", ok, result)
end

--@api-stub: Transform:decompose
-- Decomposes this transform into translation, rotation, and scale.
-- Call when you need to invoke decompose.
-- Build a Transform via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTransform(...)
if instance then
  local ok, result = pcall(function() return instance:decompose() end)
  print("Transform:decompose ->", ok, result)
end

-- ── BezierCurve methods ──

--@api-stub: BezierCurve:evaluate
-- Evaluates the curve at parameter t, returning (x, y).
-- Call when you need to invoke evaluate.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:evaluate(nil) end)
  print("BezierCurve:evaluate ->", ok, result)
end

--@api-stub: BezierCurve:render
-- Renders the curve as a polyline with the given number of segments.
-- Call when you need to invoke render.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:render(nil) end)
  print("BezierCurve:render ->", ok, result)
end

--@api-stub: BezierCurve:getDerivative
-- Returns a new BezierCurve representing the first derivative.
-- Call when you need to read derivative.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:getDerivative() end)
  print("BezierCurve:getDerivative ->", ok, result)
end

--@api-stub: BezierCurve:getControlPoint
-- Returns the control point at 1-based index as (x, y), or nil.
-- Call when you need to read control point.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:getControlPoint(1) end)
  print("BezierCurve:getControlPoint ->", ok, result)
end

--@api-stub: BezierCurve:removeControlPoint
-- Removes a control point at 1-based index.
-- Call when you need to remove control point.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:removeControlPoint(1) end)
  print("BezierCurve:removeControlPoint ->", ok, result)
end

--@api-stub: BezierCurve:getControlPointCount
-- Returns the number of control points.
-- Call when you need to read control point count.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:getControlPointCount() end)
  print("BezierCurve:getControlPointCount ->", ok, result)
end

--@api-stub: BezierCurve:length
-- Returns the approximate arc length of the curve.
-- Call when you need to invoke length.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:length() end)
  print("BezierCurve:length ->", ok, result)
end

--@api-stub: BezierCurve:translate
-- Translates all control points by (dx, dy).
-- Call when you need to invoke translate.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:translate(0, 0) end)
  print("BezierCurve:translate ->", ok, result)
end

--@api-stub: BezierCurve:rotate
-- Rotates all control points around a pivot by angle radians.
-- Call when you need to invoke rotate.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:rotate(0, nil, nil) end)
  print("BezierCurve:rotate ->", ok, result)
end

--@api-stub: BezierCurve:scale
-- Scales all control points around a pivot by factor s.
-- Call when you need to invoke scale.
-- Build a BezierCurve via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newBezierCurve(...)
if instance then
  local ok, result = pcall(function() return instance:scale(nil, nil, nil) end)
  print("BezierCurve:scale ->", ok, result)
end

-- ── Tween methods ──

--@api-stub: Tween:update
-- Advances the clock by dt seconds.
-- Returns true when complete.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Tween:update ->", ok, result)
end

--@api-stub: Tween:reset
-- Resets the tween elapsed time to zero, restarting the animation.
-- Call when you need to invoke reset.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("Tween:reset ->", ok, result)
end

--@api-stub: Tween:getValue
-- Returns the interpolated value at 1-based index, or all values as a.
-- Call when you need to read value.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:getValue(1) end)
  print("Tween:getValue ->", ok, result)
end

--@api-stub: Tween:getAllValues
-- Returns all interpolated values as a table.
-- Call when you need to read all values.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:getAllValues() end)
  print("Tween:getAllValues ->", ok, result)
end

--@api-stub: Tween:isComplete
-- Returns true if the tween has finished.
-- Call when you need to check is complete.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:isComplete() end)
  print("Tween:isComplete ->", ok, result)
end

--@api-stub: Tween:getValueCount
-- Returns the number of values in this tween.
-- Call when you need to read value count.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:getValueCount() end)
  print("Tween:getValueCount ->", ok, result)
end

--@api-stub: Tween:getEasingName
-- Returns the easing function name.
-- Call when you need to read easing name.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:getEasingName() end)
  print("Tween:getEasingName ->", ok, result)
end

--@api-stub: Tween:getDuration
-- Returns the tween duration in seconds.
-- Call when you need to read duration.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:getDuration() end)
  print("Tween:getDuration ->", ok, result)
end

--@api-stub: Tween:getTime
-- Returns the current clock time.
-- Call when you need to read time.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:getTime() end)
  print("Tween:getTime ->", ok, result)
end

--@api-stub: Tween:getClock
-- Alias for getTime().
-- Returns the current clock time.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:getClock() end)
  print("Tween:getClock ->", ok, result)
end

--@api-stub: Tween:setTime
-- Sets the clock to a specific time, clamped to [0, duration].
-- Call when you need to assign time.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:setTime(nil) end)
  print("Tween:setTime ->", ok, result)
end

--@api-stub: Tween:set
-- Alias for setTime().
-- Sets the clock to t, clamped to [0, duration].
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:set(nil) end)
  print("Tween:set ->", ok, result)
end

--@api-stub: Tween:addValue
-- Adds a start/target value pair.
-- Returns the 1-based index.
-- Build a Tween via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newTween(...)
if instance then
  local ok, result = pcall(function() return instance:addValue(nil, nil) end)
  print("Tween:addValue ->", ok, result)
end

-- ── SpatialHash methods ──

--@api-stub: SpatialHash:remove
-- Removes an item by its ID.
-- Call when you need to invoke remove.
-- Build a SpatialHash via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newSpatialHash(...)
if instance then
  local ok, result = pcall(function() return instance:remove(1) end)
  print("SpatialHash:remove ->", ok, result)
end

--@api-stub: SpatialHash:clear
-- Removes all registered items from this spatial hash, leaving it empty.
-- Call when you need to invoke clear.
-- Build a SpatialHash via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newSpatialHash(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("SpatialHash:clear ->", ok, result)
end

--@api-stub: SpatialHash:getCellSize
-- Returns the cell size used to partition the spatial hash grid.
-- Call when you need to read cell size.
-- Build a SpatialHash via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newSpatialHash(...)
if instance then
  local ok, result = pcall(function() return instance:getCellSize() end)
  print("SpatialHash:getCellSize ->", ok, result)
end

--@api-stub: SpatialHash:getItemCount
-- Returns the number of items in the hash.
-- Call when you need to read item count.
-- Build a SpatialHash via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newSpatialHash(...)
if instance then
  local ok, result = pcall(function() return instance:getItemCount() end)
  print("SpatialHash:getItemCount ->", ok, result)
end

-- ── NoiseGenerator methods ──

--@api-stub: NoiseGenerator:perlin1d
-- Returns 1D Perlin noise at x.
-- Call when you need to invoke perlin1d.
-- Build a NoiseGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newNoiseGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:perlin1d(0) end)
  print("NoiseGenerator:perlin1d ->", ok, result)
end

--@api-stub: NoiseGenerator:perlin2d
-- Returns 2D Perlin noise at (x, y).
-- Call when you need to invoke perlin2d.
-- Build a NoiseGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newNoiseGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:perlin2d(0, 0) end)
  print("NoiseGenerator:perlin2d ->", ok, result)
end

--@api-stub: NoiseGenerator:perlin3d
-- Returns 3D Perlin noise at (x, y, z).
-- Call when you need to invoke perlin3d.
-- Build a NoiseGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newNoiseGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:perlin3d(0, 0, 0) end)
  print("NoiseGenerator:perlin3d ->", ok, result)
end

--@api-stub: NoiseGenerator:perlin4d
-- Returns 4D Perlin noise at (x, y, z, w).
-- Call when you need to invoke perlin4d.
-- Build a NoiseGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newNoiseGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:perlin4d(0, 0, 0, 100) end)
  print("NoiseGenerator:perlin4d ->", ok, result)
end

--@api-stub: NoiseGenerator:simplex1d
-- Returns 1D Simplex noise at x.
-- Call when you need to invoke simplex1d.
-- Build a NoiseGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newNoiseGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:simplex1d(0) end)
  print("NoiseGenerator:simplex1d ->", ok, result)
end

--@api-stub: NoiseGenerator:simplex2d
-- Returns 2D Simplex noise at (x, y).
-- Call when you need to invoke simplex2d.
-- Build a NoiseGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newNoiseGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:simplex2d(0, 0) end)
  print("NoiseGenerator:simplex2d ->", ok, result)
end

--@api-stub: NoiseGenerator:simplex3d
-- Returns 3D Simplex noise at (x, y, z).
-- Call when you need to invoke simplex3d.
-- Build a NoiseGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newNoiseGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:simplex3d(0, 0, 0) end)
  print("NoiseGenerator:simplex3d ->", ok, result)
end

--@api-stub: NoiseGenerator:getSeed
-- Returns the current seed.
-- Call when you need to read seed.
-- Build a NoiseGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newNoiseGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:getSeed() end)
  print("NoiseGenerator:getSeed ->", ok, result)
end

--@api-stub: NoiseGenerator:setSeed
-- Sets the seed and rebuilds the permutation table.
-- Call when you need to assign seed.
-- Build a NoiseGenerator via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newNoiseGenerator(...)
if instance then
  local ok, result = pcall(function() return instance:setSeed(nil) end)
  print("NoiseGenerator:setSeed ->", ok, result)
end

-- ── Circle methods ──

--@api-stub: Circle:area
-- Returns the area of the circle (π r²).
-- Call when you need to invoke area.
-- Build a Circle via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCircle(...)
if instance then
  local ok, result = pcall(function() return instance:area() end)
  print("Circle:area ->", ok, result)
end

--@api-stub: Circle:perimeter
-- Returns the circumference of the circle (2 π r).
-- Call when you need to invoke perimeter.
-- Build a Circle via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCircle(...)
if instance then
  local ok, result = pcall(function() return instance:perimeter() end)
  print("Circle:perimeter ->", ok, result)
end

--@api-stub: Circle:contains
-- Returns true if the point (px, py) lies inside or on the boundary.
-- Call when you need to invoke contains.
-- Build a Circle via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCircle(...)
if instance then
  local ok, result = pcall(function() return instance:contains(nil, nil) end)
  print("Circle:contains ->", ok, result)
end

--@api-stub: Circle:intersects
-- Returns true if this circle overlaps another circle.
-- Call when you need to invoke intersects.
-- Build a Circle via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCircle(...)
if instance then
  local ok, result = pcall(function() return instance:intersects(nil) end)
  print("Circle:intersects ->", ok, result)
end

--@api-stub: Circle:aabb
-- Returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y).
-- Call when you need to invoke aabb.
-- Build a Circle via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCircle(...)
if instance then
  local ok, result = pcall(function() return instance:aabb() end)
  print("Circle:aabb ->", ok, result)
end

--@api-stub: Circle:x
-- Returns the circle centre X.
-- Call when you need to invoke x.
-- Build a Circle via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCircle(...)
if instance then
  local ok, result = pcall(function() return instance:x() end)
  print("Circle:x ->", ok, result)
end

--@api-stub: Circle:y
-- Returns the circle centre Y.
-- Call when you need to invoke y.
-- Build a Circle via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCircle(...)
if instance then
  local ok, result = pcall(function() return instance:y() end)
  print("Circle:y ->", ok, result)
end

--@api-stub: Circle:radius
-- Returns the circle radius.
-- Call when you need to invoke radius.
-- Build a Circle via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newCircle(...)
if instance then
  local ok, result = pcall(function() return instance:radius() end)
  print("Circle:radius ->", ok, result)
end

-- ── AabbTree methods ──

--@api-stub: AabbTree:remove
-- Removes the entry with the given id.
-- Call when you need to invoke remove.
-- Build a AabbTree via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newAabbTree(...)
if instance then
  local ok, result = pcall(function() return instance:remove(1) end)
  print("AabbTree:remove ->", ok, result)
end

--@api-stub: AabbTree:queryPoint
-- Returns the ids of all entries whose AABBs contain the given point.
-- Call when you need to invoke query point.
-- Build a AabbTree via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newAabbTree(...)
if instance then
  local ok, result = pcall(function() return instance:queryPoint(0, 0) end)
  print("AabbTree:queryPoint ->", ok, result)
end

--@api-stub: AabbTree:contains
-- Returns true if an entry with the given id exists in the tree.
-- Call when you need to invoke contains.
-- Build a AabbTree via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newAabbTree(...)
if instance then
  local ok, result = pcall(function() return instance:contains(1) end)
  print("AabbTree:contains ->", ok, result)
end

--@api-stub: AabbTree:len
-- Returns the number of entries in the tree.
-- Call when you need to invoke len.
-- Build a AabbTree via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newAabbTree(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("AabbTree:len ->", ok, result)
end

--@api-stub: AabbTree:isEmpty
-- Returns true if the tree contains no entries.
-- Call when you need to check is empty.
-- Build a AabbTree via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newAabbTree(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("AabbTree:isEmpty ->", ok, result)
end

--@api-stub: AabbTree:clear
-- Removes all entries from the tree.
-- Call when you need to invoke clear.
-- Build a AabbTree via the appropriate lurek.math.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.math.newAabbTree(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("AabbTree:clear ->", ok, result)
end

