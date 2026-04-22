-- content/examples/math.lua
-- Scaffolded coverage of the lurek.math API (204 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/math_api.rs   (Lua binding, arg types, return shape)
--   * src/math/                 (semantics, side effects)
--   * docs/specs/math.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/math.lua

-- ── lurek.math.* functions ──

--@api-stub: lurek.math.newRandomGenerator
-- Creates a new random number generator with an optional seed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.newRandomGenerator
  local _todo = "TODO: write a real lurek.math.newRandomGenerator usage example"
  print(_todo)
end

--@api-stub: lurek.math.newTransform
-- Creates a new Transform, optionally initialised from full parameters.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.newTransform
  local _todo = "TODO: write a real lurek.math.newTransform usage example"
  print(_todo)
end

--@api-stub: lurek.math.newBezierCurve
-- Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.newBezierCurve
  local _todo = "TODO: write a real lurek.math.newBezierCurve usage example"
  print(_todo)
end

--@api-stub: lurek.math.newTween
-- Creates a new Tween with the given duration and easing name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.newTween
  local _todo = "TODO: write a real lurek.math.newTween usage example"
  print(_todo)
end

--@api-stub: lurek.math.newSpatialHash
-- Creates a new SpatialHash with the given cell size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.newSpatialHash
  local _todo = "TODO: write a real lurek.math.newSpatialHash usage example"
  print(_todo)
end

--@api-stub: lurek.math.newNoiseGenerator
-- Creates a new seeded noise generator.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.newNoiseGenerator
  local _todo = "TODO: write a real lurek.math.newNoiseGenerator usage example"
  print(_todo)
end

--@api-stub: lurek.math.perlin2d
-- Returns 2D Perlin noise at (x, y) with the given seed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.perlin2d
  local _todo = "TODO: write a real lurek.math.perlin2d usage example"
  print(_todo)
end

--@api-stub: lurek.math.perlin3d
-- Returns 3D Perlin noise at (x, y, z) with the given seed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.perlin3d
  local _todo = "TODO: write a real lurek.math.perlin3d usage example"
  print(_todo)
end

--@api-stub: lurek.math.simplex2d
-- Returns 2D Simplex noise at (x, y) with the given seed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.simplex2d
  local _todo = "TODO: write a real lurek.math.simplex2d usage example"
  print(_todo)
end

--@api-stub: lurek.math.fbm
-- Returns fractal Brownian motion noise at (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.fbm
  local _todo = "TODO: write a real lurek.math.fbm usage example"
  print(_todo)
end

--@api-stub: lurek.math.applyEasing
-- Applies a named easing function to progress value t.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.applyEasing
  local _todo = "TODO: write a real lurek.math.applyEasing usage example"
  print(_todo)
end

--@api-stub: lurek.math.linear
-- Linear easing (identity).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.linear
  local _todo = "TODO: write a real lurek.math.linear usage example"
  print(_todo)
end

--@api-stub: lurek.math.inQuad
-- Quadratic ease-in — acceleration that starts at zero and increases.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inQuad
  local _todo = "TODO: write a real lurek.math.inQuad usage example"
  print(_todo)
end

--@api-stub: lurek.math.outQuad
-- Quadratic ease-out — deceleration that starts fast and ends at zero.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.outQuad
  local _todo = "TODO: write a real lurek.math.outQuad usage example"
  print(_todo)
end

--@api-stub: lurek.math.inOutQuad
-- Quadratic ease-in-out — slow start, fast middle, slow end.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inOutQuad
  local _todo = "TODO: write a real lurek.math.inOutQuad usage example"
  print(_todo)
end

--@api-stub: lurek.math.inCubic
-- Cubic ease-in — acceleration starts slowly then increases sharply.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inCubic
  local _todo = "TODO: write a real lurek.math.inCubic usage example"
  print(_todo)
end

--@api-stub: lurek.math.outCubic
-- Cubic ease-out — rapid deceleration using a cubic power curve.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.outCubic
  local _todo = "TODO: write a real lurek.math.outCubic usage example"
  print(_todo)
end

--@api-stub: lurek.math.inOutCubic
-- Cubic ease-in-out — slow start and end with fast cubic middle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inOutCubic
  local _todo = "TODO: write a real lurek.math.inOutCubic usage example"
  print(_todo)
end

--@api-stub: lurek.math.inQuart
-- Quartic ease-in — strongly delayed acceleration using a power-of-4 curve.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inQuart
  local _todo = "TODO: write a real lurek.math.inQuart usage example"
  print(_todo)
end

--@api-stub: lurek.math.outQuart
-- Quartic ease-out — rapid deceleration using a power-of-4 curve.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.outQuart
  local _todo = "TODO: write a real lurek.math.outQuart usage example"
  print(_todo)
end

--@api-stub: lurek.math.inOutQuart
-- Quartic ease-in-out — very slow start and end with a sharp middle peak.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inOutQuart
  local _todo = "TODO: write a real lurek.math.inOutQuart usage example"
  print(_todo)
end

--@api-stub: lurek.math.inSine
-- Sinusoidal ease-in — gentle acceleration based on a sine curve.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inSine
  local _todo = "TODO: write a real lurek.math.inSine usage example"
  print(_todo)
end

--@api-stub: lurek.math.outSine
-- Sinusoidal ease-out — gentle deceleration based on a cosine curve.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.outSine
  local _todo = "TODO: write a real lurek.math.outSine usage example"
  print(_todo)
end

--@api-stub: lurek.math.inOutSine
-- Sinusoidal ease-in-out — smooth S-curve based on cosine interpolation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inOutSine
  local _todo = "TODO: write a real lurek.math.inOutSine usage example"
  print(_todo)
end

--@api-stub: lurek.math.inExpo
-- Exponential ease-in — very slow start that accelerates sharply near the end.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inExpo
  local _todo = "TODO: write a real lurek.math.inExpo usage example"
  print(_todo)
end

--@api-stub: lurek.math.outExpo
-- Exponential ease-out — sharp initial speed that decelerates exponentially.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.outExpo
  local _todo = "TODO: write a real lurek.math.outExpo usage example"
  print(_todo)
end

--@api-stub: lurek.math.inOutExpo
-- Exponential ease-in-out — very slow start and end with an exponential surge.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inOutExpo
  local _todo = "TODO: write a real lurek.math.inOutExpo usage example"
  print(_todo)
end

--@api-stub: lurek.math.inElastic
-- Elastic ease-in — spring-like overshoot at the beginning of the motion.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inElastic
  local _todo = "TODO: write a real lurek.math.inElastic usage example"
  print(_todo)
end

--@api-stub: lurek.math.outElastic
-- Elastic ease-out — spring-like oscillation that settles at the target.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.outElastic
  local _todo = "TODO: write a real lurek.math.outElastic usage example"
  print(_todo)
end

--@api-stub: lurek.math.outBounce
-- Bounce ease-out — simulates a ball bouncing against the target value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.outBounce
  local _todo = "TODO: write a real lurek.math.outBounce usage example"
  print(_todo)
end

--@api-stub: lurek.math.inBounce
-- Bounce ease-in — reverse bounce effect that accelerates into the motion.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inBounce
  local _todo = "TODO: write a real lurek.math.inBounce usage example"
  print(_todo)
end

--@api-stub: lurek.math.inBack
-- Back ease-in — overshoots slightly before settling at the target.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inBack
  local _todo = "TODO: write a real lurek.math.inBack usage example"
  print(_todo)
end

--@api-stub: lurek.math.outBack
-- Back ease-out — overshoots the target then snaps back into place.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.outBack
  local _todo = "TODO: write a real lurek.math.outBack usage example"
  print(_todo)
end

--@api-stub: lurek.math.inOutElastic
-- Elastic ease-in-out — spring-like oscillation on both ends.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inOutElastic
  local _todo = "TODO: write a real lurek.math.inOutElastic usage example"
  print(_todo)
end

--@api-stub: lurek.math.inOutBounce
-- Bounce ease-in-out — bouncing motion on both ends.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inOutBounce
  local _todo = "TODO: write a real lurek.math.inOutBounce usage example"
  print(_todo)
end

--@api-stub: lurek.math.inOutBack
-- Back ease-in-out — overshoot on both ends.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inOutBack
  local _todo = "TODO: write a real lurek.math.inOutBack usage example"
  print(_todo)
end

--@api-stub: lurek.math.triangulate
-- Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.triangulate
  local _todo = "TODO: write a real lurek.math.triangulate usage example"
  print(_todo)
end

--@api-stub: lurek.math.isConvex
-- Returns true if the polygon (flat table {x1,y1,...}) is convex.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.isConvex
  local _todo = "TODO: write a real lurek.math.isConvex usage example"
  print(_todo)
end

--@api-stub: lurek.math.gammaToLinear
-- Converts a gamma-encoded sRGB value to linear space.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.gammaToLinear
  local _todo = "TODO: write a real lurek.math.gammaToLinear usage example"
  print(_todo)
end

--@api-stub: lurek.math.linearToGamma
-- Converts a linear-space value to gamma-encoded sRGB.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.linearToGamma
  local _todo = "TODO: write a real lurek.math.linearToGamma usage example"
  print(_todo)
end

--@api-stub: lurek.math.angleBetween
-- Returns the angle in radians from (x1, y1) to (x2, y2).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.angleBetween
  local _todo = "TODO: write a real lurek.math.angleBetween usage example"
  print(_todo)
end

--@api-stub: lurek.math.circleContainsPoint
-- Returns true if the point (px, py) lies inside the circle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.circleContainsPoint
  local _todo = "TODO: write a real lurek.math.circleContainsPoint usage example"
  print(_todo)
end

--@api-stub: lurek.math.circleIntersectsCircle
-- Returns true if two circles overlap.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.circleIntersectsCircle
  local _todo = "TODO: write a real lurek.math.circleIntersectsCircle usage example"
  print(_todo)
end

--@api-stub: lurek.math.circleIntersectsLine
-- Tests an infinite line against a circle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.circleIntersectsLine
  local _todo = "TODO: write a real lurek.math.circleIntersectsLine usage example"
  print(_todo)
end

--@api-stub: lurek.math.circleIntersectsSegment
-- Tests a line segment against a circle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.circleIntersectsSegment
  local _todo = "TODO: write a real lurek.math.circleIntersectsSegment usage example"
  print(_todo)
end

--@api-stub: lurek.math.closestPointOnSegment
-- Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.closestPointOnSegment
  local _todo = "TODO: write a real lurek.math.closestPointOnSegment usage example"
  print(_todo)
end

--@api-stub: lurek.math.convexHull
-- Computes the convex hull of a flat {x1,y1,...} point list.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.convexHull
  local _todo = "TODO: write a real lurek.math.convexHull usage example"
  print(_todo)
end

--@api-stub: lurek.math.delaunayTriangulate
-- Delaunay triangulation of a flat {x1,y1,...} point list.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.delaunayTriangulate
  local _todo = "TODO: write a real lurek.math.delaunayTriangulate usage example"
  print(_todo)
end

--@api-stub: lurek.math.lineIntersect
-- Infinite line intersection.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.lineIntersect
  local _todo = "TODO: write a real lurek.math.lineIntersect usage example"
  print(_todo)
end

--@api-stub: lurek.math.pointInPolygon
-- Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.pointInPolygon
  local _todo = "TODO: write a real lurek.math.pointInPolygon usage example"
  print(_todo)
end

--@api-stub: lurek.math.polygonArea
-- Returns the signed area of a polygon given as a flat {x1,y1,...} table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.polygonArea
  local _todo = "TODO: write a real lurek.math.polygonArea usage example"
  print(_todo)
end

--@api-stub: lurek.math.polygonCentroid
-- Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.polygonCentroid
  local _todo = "TODO: write a real lurek.math.polygonCentroid usage example"
  print(_todo)
end

--@api-stub: lurek.math.segmentIntersectsSegment
-- Tests if two line segments intersect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.segmentIntersectsSegment
  local _todo = "TODO: write a real lurek.math.segmentIntersectsSegment usage example"
  print(_todo)
end

--@api-stub: lurek.math.bresenham
-- Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.bresenham
  local _todo = "TODO: write a real lurek.math.bresenham usage example"
  print(_todo)
end

--@api-stub: lurek.math.rad
-- Converts degrees to radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.rad
  local _todo = "TODO: write a real lurek.math.rad usage example"
  print(_todo)
end

--@api-stub: lurek.math.deg
-- Converts radians to degrees.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.deg
  local _todo = "TODO: write a real lurek.math.deg usage example"
  print(_todo)
end

--@api-stub: lurek.math.sin
-- Returns the sine of x (radians).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.sin
  local _todo = "TODO: write a real lurek.math.sin usage example"
  print(_todo)
end

--@api-stub: lurek.math.cos
-- Returns the cosine of x (radians).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.cos
  local _todo = "TODO: write a real lurek.math.cos usage example"
  print(_todo)
end

--@api-stub: lurek.math.tan
-- Returns the tangent of x (radians).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.tan
  local _todo = "TODO: write a real lurek.math.tan usage example"
  print(_todo)
end

--@api-stub: lurek.math.asin
-- Returns the arcsine of x, in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.asin
  local _todo = "TODO: write a real lurek.math.asin usage example"
  print(_todo)
end

--@api-stub: lurek.math.acos
-- Returns the arccosine of x, in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.acos
  local _todo = "TODO: write a real lurek.math.acos usage example"
  print(_todo)
end

--@api-stub: lurek.math.atan
-- Returns the arctangent of x (or atan2(y, x) when two args given).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.atan
  local _todo = "TODO: write a real lurek.math.atan usage example"
  print(_todo)
end

--@api-stub: lurek.math.atan2
-- Returns atan(y/x) using the signs of both args to determine the quadrant.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.atan2
  local _todo = "TODO: write a real lurek.math.atan2 usage example"
  print(_todo)
end

--@api-stub: lurek.math.sqrt
-- Returns the square root of x.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.sqrt
  local _todo = "TODO: write a real lurek.math.sqrt usage example"
  print(_todo)
end

--@api-stub: lurek.math.abs
-- Returns the absolute value of x.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.abs
  local _todo = "TODO: write a real lurek.math.abs usage example"
  print(_todo)
end

--@api-stub: lurek.math.floor
-- Returns the largest integer ≤ x.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.floor
  local _todo = "TODO: write a real lurek.math.floor usage example"
  print(_todo)
end

--@api-stub: lurek.math.ceil
-- Returns the smallest integer ≥ x.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.ceil
  local _todo = "TODO: write a real lurek.math.ceil usage example"
  print(_todo)
end

--@api-stub: lurek.math.round
-- Returns x rounded to the nearest integer (half-up).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.round
  local _todo = "TODO: write a real lurek.math.round usage example"
  print(_todo)
end

--@api-stub: lurek.math.exp
-- Returns e raised to the power x.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.exp
  local _todo = "TODO: write a real lurek.math.exp usage example"
  print(_todo)
end

--@api-stub: lurek.math.log
-- Returns the natural log of x, or log base b if b is supplied.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.log
  local _todo = "TODO: write a real lurek.math.log usage example"
  print(_todo)
end

--@api-stub: lurek.math.pow
-- Returns x raised to the power y.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.pow
  local _todo = "TODO: write a real lurek.math.pow usage example"
  print(_todo)
end

--@api-stub: lurek.math.min
-- Returns the smallest of the supplied numbers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.min
  local _todo = "TODO: write a real lurek.math.min usage example"
  print(_todo)
end

--@api-stub: lurek.math.max
-- Returns the largest of the supplied numbers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.max
  local _todo = "TODO: write a real lurek.math.max usage example"
  print(_todo)
end

--@api-stub: lurek.math.clamp
-- Returns x clamped to [lo, hi].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.clamp
  local _todo = "TODO: write a real lurek.math.clamp usage example"
  print(_todo)
end

--@api-stub: lurek.math.sign
-- Returns -1, 0, or 1 depending on the sign of x.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.sign
  local _todo = "TODO: write a real lurek.math.sign usage example"
  print(_todo)
end

--@api-stub: lurek.math.fmod
-- Returns the remainder of x / y (fmod).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.fmod
  local _todo = "TODO: write a real lurek.math.fmod usage example"
  print(_todo)
end

--@api-stub: lurek.math.lerp
-- Linear interpolation between a and b by fraction t.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.lerp
  local _todo = "TODO: write a real lurek.math.lerp usage example"
  print(_todo)
end

--@api-stub: lurek.math.distance
-- Returns the Euclidean distance between (x1,y1) and (x2,y2).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.distance
  local _todo = "TODO: write a real lurek.math.distance usage example"
  print(_todo)
end

--@api-stub: lurek.math.distanceSq
-- Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.distanceSq
  local _todo = "TODO: write a real lurek.math.distanceSq usage example"
  print(_todo)
end

--@api-stub: lurek.math.random
-- Returns a pseudo-random number in [0,1) with no args,.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.random
  local _todo = "TODO: write a real lurek.math.random usage example"
  print(_todo)
end

--@api-stub: lurek.math.randomInt
-- Returns a pseudo-random integer in [lo, hi] (inclusive).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.randomInt
  local _todo = "TODO: write a real lurek.math.randomInt usage example"
  print(_todo)
end

--@api-stub: lurek.math.simplexNoise
-- Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.simplexNoise
  local _todo = "TODO: write a real lurek.math.simplexNoise usage example"
  print(_todo)
end

--@api-stub: lurek.math.vec2
-- Creates a 2D vector with x and y components.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.vec2
  local _todo = "TODO: write a real lurek.math.vec2 usage example"
  print(_todo)
end

--@api-stub: lurek.math.Vec2
-- Compatibility alias for `vec2`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.Vec2
  local _todo = "TODO: write a real lurek.math.Vec2 usage example"
  print(_todo)
end

--@api-stub: lurek.math.vec3
-- Creates a 3D vector `{x, y, z}` table with numeric components.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.vec3
  local _todo = "TODO: write a real lurek.math.vec3 usage example"
  print(_todo)
end

--@api-stub: lurek.math.Vec3
-- Compatibility alias for `vec3`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.Vec3
  local _todo = "TODO: write a real lurek.math.Vec3 usage example"
  print(_todo)
end

--@api-stub: lurek.math.catmullRom
-- Creates a Catmull-Rom spline through the given control points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.catmullRom
  local _todo = "TODO: write a real lurek.math.catmullRom usage example"
  print(_todo)
end

--@api-stub: lurek.math.hermite
-- Creates a Hermite spline defined by two endpoints and tangents.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.hermite
  local _todo = "TODO: write a real lurek.math.hermite usage example"
  print(_todo)
end

--@api-stub: lurek.math.lerp
-- Linear interpolation between two numbers: a + (b - a) * t.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.lerp
  local _todo = "TODO: write a real lurek.math.lerp usage example"
  print(_todo)
end

--@api-stub: lurek.math.remap
-- Remaps `v` from [in_min, in_max] to [out_min, out_max].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.remap
  local _todo = "TODO: write a real lurek.math.remap usage example"
  print(_todo)
end

--@api-stub: lurek.math.clamp
-- Clamps `v` between `min` and `max`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.clamp
  local _todo = "TODO: write a real lurek.math.clamp usage example"
  print(_todo)
end

--@api-stub: lurek.math.sign
-- Returns -1, 0, or 1 depending on the sign of `v`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.sign
  local _todo = "TODO: write a real lurek.math.sign usage example"
  print(_todo)
end

--@api-stub: lurek.math.smoothstep
-- Hermite smoothstep between `edge0` and `edge1`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.smoothstep
  local _todo = "TODO: write a real lurek.math.smoothstep usage example"
  print(_todo)
end

--@api-stub: lurek.math.inverseLerp
-- Returns the interpolation parameter t for `v` in [a, b].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.inverseLerp
  local _todo = "TODO: write a real lurek.math.inverseLerp usage example"
  print(_todo)
end

--@api-stub: lurek.math.hslToRgb
-- Converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.hslToRgb
  local _todo = "TODO: write a real lurek.math.hslToRgb usage example"
  print(_todo)
end

--@api-stub: lurek.math.fromHex
-- Parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.fromHex
  local _todo = "TODO: write a real lurek.math.fromHex usage example"
  print(_todo)
end

--@api-stub: lurek.math.rgbToHsl
-- Converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.rgbToHsl
  local _todo = "TODO: write a real lurek.math.rgbToHsl usage example"
  print(_todo)
end

--@api-stub: lurek.math.rectUnion
-- Returns the union (bounding box) of two rectangles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.rectUnion
  local _todo = "TODO: write a real lurek.math.rectUnion usage example"
  print(_todo)
end

--@api-stub: lurek.math.rectFromCenter
-- Creates a rectangle centered at (cx, cy) with the given width and height.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.rectFromCenter
  local _todo = "TODO: write a real lurek.math.rectFromCenter usage example"
  print(_todo)
end

--@api-stub: lurek.math.polygonClip
-- Clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.polygonClip
  local _todo = "TODO: write a real lurek.math.polygonClip usage example"
  print(_todo)
end

--@api-stub: lurek.math.aabbTree
-- Creates a new empty AABB tree for efficient broad-phase overlap queries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.aabbTree
  local _todo = "TODO: write a real lurek.math.aabbTree usage example"
  print(_todo)
end

--@api-stub: lurek.math.newCircle
-- Creates a new Circle value type with the given centre and radius.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.newCircle
  local _todo = "TODO: write a real lurek.math.newCircle usage example"
  print(_todo)
end

--@api-stub: lurek.math.polygonIntersection
-- Computes the intersection of two convex polygons using the Sutherland-Hodgman.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.polygonIntersection
  local _todo = "TODO: write a real lurek.math.polygonIntersection usage example"
  print(_todo)
end

--@api-stub: lurek.math.polygonUnion
-- Computes the approximate union of two convex polygons as the convex hull of.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.polygonUnion
  local _todo = "TODO: write a real lurek.math.polygonUnion usage example"
  print(_todo)
end

--@api-stub: lurek.math.polygonDifference
-- Computes the approximate difference `A - B` (the part of A not covered by B).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.polygonDifference
  local _todo = "TODO: write a real lurek.math.polygonDifference usage example"
  print(_todo)
end

--@api-stub: lurek.math.voronoi
-- Computes the Voronoi diagram for a list of 2-D seed points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: lurek.math.voronoi
  local _todo = "TODO: write a real lurek.math.voronoi usage example"
  print(_todo)
end

-- ── Vec2 methods ──

--@api-stub: Vec2:dot
-- Returns the dot product with another vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:dot
  local _todo = "TODO: write a real Vec2:dot usage example"
  print(_todo)
end

--@api-stub: Vec2:length
-- Returns the Euclidean length of the vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:length
  local _todo = "TODO: write a real Vec2:length usage example"
  print(_todo)
end

--@api-stub: Vec2:x
-- Returns the horizontal component of the vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:x
  local _todo = "TODO: write a real Vec2:x usage example"
  print(_todo)
end

--@api-stub: Vec2:y
-- Returns the vertical component of the vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:y
  local _todo = "TODO: write a real Vec2:y usage example"
  print(_todo)
end

--@api-stub: Vec2:lengthSquared
-- Returns the squared length of the vector (faster than length).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:lengthSquared
  local _todo = "TODO: write a real Vec2:lengthSquared usage example"
  print(_todo)
end

--@api-stub: Vec2:normalize
-- Returns a unit-length copy of this vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:normalize
  local _todo = "TODO: write a real Vec2:normalize usage example"
  print(_todo)
end

--@api-stub: Vec2:normalized
-- Compatibility alias for `normalize`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:normalized
  local _todo = "TODO: write a real Vec2:normalized usage example"
  print(_todo)
end

--@api-stub: Vec2:lerp
-- Returns a linearly interpolated vector between this and other at parameter t.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:lerp
  local _todo = "TODO: write a real Vec2:lerp usage example"
  print(_todo)
end

--@api-stub: Vec2:distance
-- Returns the Euclidean distance from this vector to another.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:distance
  local _todo = "TODO: write a real Vec2:distance usage example"
  print(_todo)
end

--@api-stub: Vec2:angle
-- Returns the angle of this vector in radians (atan2(y, x)).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:angle
  local _todo = "TODO: write a real Vec2:angle usage example"
  print(_todo)
end

--@api-stub: Vec2:rotate
-- Returns a new vector rotated by the given angle in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:rotate
  local _todo = "TODO: write a real Vec2:rotate usage example"
  print(_todo)
end

--@api-stub: Vec2:perpendicular
-- Returns the perpendicular vector (-y, x).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:perpendicular
  local _todo = "TODO: write a real Vec2:perpendicular usage example"
  print(_todo)
end

--@api-stub: Vec2:cross
-- Returns the 2D cross product (scalar) with another vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:cross
  local _todo = "TODO: write a real Vec2:cross usage example"
  print(_todo)
end

--@api-stub: Vec2:reflect
-- Reflects this vector off a surface with the given normal.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec2:reflect
  local _todo = "TODO: write a real Vec2:reflect usage example"
  print(_todo)
end

-- ── Vec3 methods ──

--@api-stub: Vec3:length
-- Returns the Euclidean length of the vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:length
  local _todo = "TODO: write a real Vec3:length usage example"
  print(_todo)
end

--@api-stub: Vec3:lengthSquared
-- Returns the squared Euclidean length (avoids sqrt).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:lengthSquared
  local _todo = "TODO: write a real Vec3:lengthSquared usage example"
  print(_todo)
end

--@api-stub: Vec3:normalize
-- Returns a unit-length version of this vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:normalize
  local _todo = "TODO: write a real Vec3:normalize usage example"
  print(_todo)
end

--@api-stub: Vec3:dot
-- Dot product with another Vec3.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:dot
  local _todo = "TODO: write a real Vec3:dot usage example"
  print(_todo)
end

--@api-stub: Vec3:cross
-- Cross product with another Vec3.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:cross
  local _todo = "TODO: write a real Vec3:cross usage example"
  print(_todo)
end

--@api-stub: Vec3:lerp
-- Linear interpolation towards another Vec3.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:lerp
  local _todo = "TODO: write a real Vec3:lerp usage example"
  print(_todo)
end

--@api-stub: Vec3:distance
-- Euclidean distance to another Vec3.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:distance
  local _todo = "TODO: write a real Vec3:distance usage example"
  print(_todo)
end

--@api-stub: Vec3:add
-- Add another Vec3 and return the result.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:add
  local _todo = "TODO: write a real Vec3:add usage example"
  print(_todo)
end

--@api-stub: Vec3:sub
-- Subtract another Vec3 and return the result.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:sub
  local _todo = "TODO: write a real Vec3:sub usage example"
  print(_todo)
end

--@api-stub: Vec3:scale
-- Scale this vector by a scalar and return the result.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Vec3:scale
  local _todo = "TODO: write a real Vec3:scale usage example"
  print(_todo)
end

-- ── CatmullRom methods ──

--@api-stub: CatmullRom:sample
-- Sample the spline at global t in [0, 1].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: CatmullRom:sample
  local _todo = "TODO: write a real CatmullRom:sample usage example"
  print(_todo)
end

--@api-stub: CatmullRom:sampleSegment
-- Sample a specific segment at local t in [0, 1].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: CatmullRom:sampleSegment
  local _todo = "TODO: write a real CatmullRom:sampleSegment usage example"
  print(_todo)
end

--@api-stub: CatmullRom:len
-- Number of control points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: CatmullRom:len
  local _todo = "TODO: write a real CatmullRom:len usage example"
  print(_todo)
end

--@api-stub: CatmullRom:addPoint
-- Appends a control point to the spline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: CatmullRom:addPoint
  local _todo = "TODO: write a real CatmullRom:addPoint usage example"
  print(_todo)
end

--@api-stub: CatmullRom:removePoint
-- Removes the control point at `index` (0-based) and returns it.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: CatmullRom:removePoint
  local _todo = "TODO: write a real CatmullRom:removePoint usage example"
  print(_todo)
end

-- ── Hermite methods ──

--@api-stub: Hermite:sample
-- Evaluate the spline at parameter t in [0, 1].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Hermite:sample
  local _todo = "TODO: write a real Hermite:sample usage example"
  print(_todo)
end

-- ── RandomGenerator methods ──

--@api-stub: RandomGenerator:random
-- Returns a uniform random number in [0, 1).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: RandomGenerator:random
  local _todo = "TODO: write a real RandomGenerator:random usage example"
  print(_todo)
end

--@api-stub: RandomGenerator:randomFloat
-- Returns a uniform random float in [min, max).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: RandomGenerator:randomFloat
  local _todo = "TODO: write a real RandomGenerator:randomFloat usage example"
  print(_todo)
end

--@api-stub: RandomGenerator:randomInt
-- Returns a uniform random integer in [min, max].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: RandomGenerator:randomInt
  local _todo = "TODO: write a real RandomGenerator:randomInt usage example"
  print(_todo)
end

--@api-stub: RandomGenerator:getSeed
-- Returns the seed used to initialise this generator.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: RandomGenerator:getSeed
  local _todo = "TODO: write a real RandomGenerator:getSeed usage example"
  print(_todo)
end

--@api-stub: RandomGenerator:setSeed
-- Sets the seed, fully resetting the generator state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: RandomGenerator:setSeed
  local _todo = "TODO: write a real RandomGenerator:setSeed usage example"
  print(_todo)
end

--@api-stub: RandomGenerator:getState
-- Serialises the generator state as a string for later restoration.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: RandomGenerator:getState
  local _todo = "TODO: write a real RandomGenerator:getState usage example"
  print(_todo)
end

--@api-stub: RandomGenerator:setState
-- Restores the generator state from a previously serialised string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: RandomGenerator:setState
  local _todo = "TODO: write a real RandomGenerator:setState usage example"
  print(_todo)
end

-- ── Transform methods ──

--@api-stub: Transform:translate
-- Applies translation to the transform.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:translate
  local _todo = "TODO: write a real Transform:translate usage example"
  print(_todo)
end

--@api-stub: Transform:rotate
-- Applies a rotation in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:rotate
  local _todo = "TODO: write a real Transform:rotate usage example"
  print(_todo)
end

--@api-stub: Transform:scale
-- Applies non-uniform scaling.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:scale
  local _todo = "TODO: write a real Transform:scale usage example"
  print(_todo)
end

--@api-stub: Transform:shear
-- Applies horizontal and vertical shear factors to this transform matrix.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:shear
  local _todo = "TODO: write a real Transform:shear usage example"
  print(_todo)
end

--@api-stub: Transform:reset
-- Resets the transform to identity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:reset
  local _todo = "TODO: write a real Transform:reset usage example"
  print(_todo)
end

--@api-stub: Transform:transformPoint
-- Transforms a point from local space to world space.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:transformPoint
  local _todo = "TODO: write a real Transform:transformPoint usage example"
  print(_todo)
end

--@api-stub: Transform:inverseTransformPoint
-- Transforms a point from world space back to local space.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:inverseTransformPoint
  local _todo = "TODO: write a real Transform:inverseTransformPoint usage example"
  print(_todo)
end

--@api-stub: Transform:inverse
-- Returns a new Transform that undoes this transform.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:inverse
  local _todo = "TODO: write a real Transform:inverse usage example"
  print(_todo)
end

--@api-stub: Transform:clone
-- Returns a copy of this transform.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:clone
  local _todo = "TODO: write a real Transform:clone usage example"
  print(_todo)
end

--@api-stub: Transform:getMatrix
-- Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:getMatrix
  local _todo = "TODO: write a real Transform:getMatrix usage example"
  print(_todo)
end

--@api-stub: Transform:decompose
-- Decomposes this transform into translation, rotation, and scale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Transform:decompose
  local _todo = "TODO: write a real Transform:decompose usage example"
  print(_todo)
end

-- ── BezierCurve methods ──

--@api-stub: BezierCurve:evaluate
-- Evaluates the curve at parameter t, returning (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:evaluate
  local _todo = "TODO: write a real BezierCurve:evaluate usage example"
  print(_todo)
end

--@api-stub: BezierCurve:render
-- Renders the curve as a polyline with the given number of segments.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:render
  local _todo = "TODO: write a real BezierCurve:render usage example"
  print(_todo)
end

--@api-stub: BezierCurve:getDerivative
-- Returns a new BezierCurve representing the first derivative.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:getDerivative
  local _todo = "TODO: write a real BezierCurve:getDerivative usage example"
  print(_todo)
end

--@api-stub: BezierCurve:getControlPoint
-- Returns the control point at 1-based index as (x, y), or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:getControlPoint
  local _todo = "TODO: write a real BezierCurve:getControlPoint usage example"
  print(_todo)
end

--@api-stub: BezierCurve:removeControlPoint
-- Removes a control point at 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:removeControlPoint
  local _todo = "TODO: write a real BezierCurve:removeControlPoint usage example"
  print(_todo)
end

--@api-stub: BezierCurve:getControlPointCount
-- Returns the number of control points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:getControlPointCount
  local _todo = "TODO: write a real BezierCurve:getControlPointCount usage example"
  print(_todo)
end

--@api-stub: BezierCurve:length
-- Returns the approximate arc length of the curve.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:length
  local _todo = "TODO: write a real BezierCurve:length usage example"
  print(_todo)
end

--@api-stub: BezierCurve:translate
-- Translates all control points by (dx, dy).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:translate
  local _todo = "TODO: write a real BezierCurve:translate usage example"
  print(_todo)
end

--@api-stub: BezierCurve:rotate
-- Rotates all control points around a pivot by angle radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:rotate
  local _todo = "TODO: write a real BezierCurve:rotate usage example"
  print(_todo)
end

--@api-stub: BezierCurve:scale
-- Scales all control points around a pivot by factor s.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: BezierCurve:scale
  local _todo = "TODO: write a real BezierCurve:scale usage example"
  print(_todo)
end

-- ── Tween methods ──

--@api-stub: Tween:update
-- Advances the clock by dt seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:update
  local _todo = "TODO: write a real Tween:update usage example"
  print(_todo)
end

--@api-stub: Tween:reset
-- Resets the tween elapsed time to zero, restarting the animation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:reset
  local _todo = "TODO: write a real Tween:reset usage example"
  print(_todo)
end

--@api-stub: Tween:getValue
-- Returns the interpolated value at 1-based index, or all values as a.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:getValue
  local _todo = "TODO: write a real Tween:getValue usage example"
  print(_todo)
end

--@api-stub: Tween:getAllValues
-- Returns all interpolated values as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:getAllValues
  local _todo = "TODO: write a real Tween:getAllValues usage example"
  print(_todo)
end

--@api-stub: Tween:isComplete
-- Returns true if the tween has finished.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:isComplete
  local _todo = "TODO: write a real Tween:isComplete usage example"
  print(_todo)
end

--@api-stub: Tween:getValueCount
-- Returns the number of values in this tween.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:getValueCount
  local _todo = "TODO: write a real Tween:getValueCount usage example"
  print(_todo)
end

--@api-stub: Tween:getEasingName
-- Returns the easing function name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:getEasingName
  local _todo = "TODO: write a real Tween:getEasingName usage example"
  print(_todo)
end

--@api-stub: Tween:getDuration
-- Returns the tween duration in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:getDuration
  local _todo = "TODO: write a real Tween:getDuration usage example"
  print(_todo)
end

--@api-stub: Tween:getTime
-- Returns the current clock time.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:getTime
  local _todo = "TODO: write a real Tween:getTime usage example"
  print(_todo)
end

--@api-stub: Tween:getClock
-- Alias for getTime().
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:getClock
  local _todo = "TODO: write a real Tween:getClock usage example"
  print(_todo)
end

--@api-stub: Tween:setTime
-- Sets the clock to a specific time, clamped to [0, duration].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:setTime
  local _todo = "TODO: write a real Tween:setTime usage example"
  print(_todo)
end

--@api-stub: Tween:set
-- Alias for setTime().
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:set
  local _todo = "TODO: write a real Tween:set usage example"
  print(_todo)
end

--@api-stub: Tween:addValue
-- Adds a start/target value pair.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Tween:addValue
  local _todo = "TODO: write a real Tween:addValue usage example"
  print(_todo)
end

-- ── SpatialHash methods ──

--@api-stub: SpatialHash:remove
-- Removes an item by its ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: SpatialHash:remove
  local _todo = "TODO: write a real SpatialHash:remove usage example"
  print(_todo)
end

--@api-stub: SpatialHash:clear
-- Removes all registered items from this spatial hash, leaving it empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: SpatialHash:clear
  local _todo = "TODO: write a real SpatialHash:clear usage example"
  print(_todo)
end

--@api-stub: SpatialHash:getCellSize
-- Returns the cell size used to partition the spatial hash grid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: SpatialHash:getCellSize
  local _todo = "TODO: write a real SpatialHash:getCellSize usage example"
  print(_todo)
end

--@api-stub: SpatialHash:getItemCount
-- Returns the number of items in the hash.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: SpatialHash:getItemCount
  local _todo = "TODO: write a real SpatialHash:getItemCount usage example"
  print(_todo)
end

-- ── NoiseGenerator methods ──

--@api-stub: NoiseGenerator:perlin1d
-- Returns 1D Perlin noise at x.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: NoiseGenerator:perlin1d
  local _todo = "TODO: write a real NoiseGenerator:perlin1d usage example"
  print(_todo)
end

--@api-stub: NoiseGenerator:perlin2d
-- Returns 2D Perlin noise at (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: NoiseGenerator:perlin2d
  local _todo = "TODO: write a real NoiseGenerator:perlin2d usage example"
  print(_todo)
end

--@api-stub: NoiseGenerator:perlin3d
-- Returns 3D Perlin noise at (x, y, z).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: NoiseGenerator:perlin3d
  local _todo = "TODO: write a real NoiseGenerator:perlin3d usage example"
  print(_todo)
end

--@api-stub: NoiseGenerator:perlin4d
-- Returns 4D Perlin noise at (x, y, z, w).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: NoiseGenerator:perlin4d
  local _todo = "TODO: write a real NoiseGenerator:perlin4d usage example"
  print(_todo)
end

--@api-stub: NoiseGenerator:simplex1d
-- Returns 1D Simplex noise at x.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: NoiseGenerator:simplex1d
  local _todo = "TODO: write a real NoiseGenerator:simplex1d usage example"
  print(_todo)
end

--@api-stub: NoiseGenerator:simplex2d
-- Returns 2D Simplex noise at (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: NoiseGenerator:simplex2d
  local _todo = "TODO: write a real NoiseGenerator:simplex2d usage example"
  print(_todo)
end

--@api-stub: NoiseGenerator:simplex3d
-- Returns 3D Simplex noise at (x, y, z).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: NoiseGenerator:simplex3d
  local _todo = "TODO: write a real NoiseGenerator:simplex3d usage example"
  print(_todo)
end

--@api-stub: NoiseGenerator:getSeed
-- Returns the current seed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: NoiseGenerator:getSeed
  local _todo = "TODO: write a real NoiseGenerator:getSeed usage example"
  print(_todo)
end

--@api-stub: NoiseGenerator:setSeed
-- Sets the seed and rebuilds the permutation table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: NoiseGenerator:setSeed
  local _todo = "TODO: write a real NoiseGenerator:setSeed usage example"
  print(_todo)
end

-- ── Circle methods ──

--@api-stub: Circle:area
-- Returns the area of the circle (π r²).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Circle:area
  local _todo = "TODO: write a real Circle:area usage example"
  print(_todo)
end

--@api-stub: Circle:perimeter
-- Returns the circumference of the circle (2 π r).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Circle:perimeter
  local _todo = "TODO: write a real Circle:perimeter usage example"
  print(_todo)
end

--@api-stub: Circle:contains
-- Returns true if the point (px, py) lies inside or on the boundary.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Circle:contains
  local _todo = "TODO: write a real Circle:contains usage example"
  print(_todo)
end

--@api-stub: Circle:intersects
-- Returns true if this circle overlaps another circle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Circle:intersects
  local _todo = "TODO: write a real Circle:intersects usage example"
  print(_todo)
end

--@api-stub: Circle:aabb
-- Returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Circle:aabb
  local _todo = "TODO: write a real Circle:aabb usage example"
  print(_todo)
end

--@api-stub: Circle:x
-- Returns the circle centre X.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Circle:x
  local _todo = "TODO: write a real Circle:x usage example"
  print(_todo)
end

--@api-stub: Circle:y
-- Returns the circle centre Y.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Circle:y
  local _todo = "TODO: write a real Circle:y usage example"
  print(_todo)
end

--@api-stub: Circle:radius
-- Returns the circle radius.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: Circle:radius
  local _todo = "TODO: write a real Circle:radius usage example"
  print(_todo)
end

-- ── AabbTree methods ──

--@api-stub: AabbTree:remove
-- Removes the entry with the given id.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: AabbTree:remove
  local _todo = "TODO: write a real AabbTree:remove usage example"
  print(_todo)
end

--@api-stub: AabbTree:queryPoint
-- Returns the ids of all entries whose AABBs contain the given point.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: AabbTree:queryPoint
  local _todo = "TODO: write a real AabbTree:queryPoint usage example"
  print(_todo)
end

--@api-stub: AabbTree:contains
-- Returns true if an entry with the given id exists in the tree.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: AabbTree:contains
  local _todo = "TODO: write a real AabbTree:contains usage example"
  print(_todo)
end

--@api-stub: AabbTree:len
-- Returns the number of entries in the tree.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: AabbTree:len
  local _todo = "TODO: write a real AabbTree:len usage example"
  print(_todo)
end

--@api-stub: AabbTree:isEmpty
-- Returns true if the tree contains no entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: AabbTree:isEmpty
  local _todo = "TODO: write a real AabbTree:isEmpty usage example"
  print(_todo)
end

--@api-stub: AabbTree:clear
-- Removes all entries from the tree.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/math_api.rs and docs/specs/math.md).
do  -- TODO: AabbTree:clear
  local _todo = "TODO: write a real AabbTree:clear usage example"
  print(_todo)
end

