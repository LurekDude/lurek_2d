-- content/examples/math.lua
-- Hand-written coverage of the lurek.math API (204 items).
--
-- The lurek.math namespace bundles vectors, transforms, splines, easing,
-- noise generators, geometry tests, polygon clipping, color conversion,
-- random number generators, and a few broad-phase spatial structures.
-- Free helpers like lurek.math.sin/cos/clamp delegate to Lua's math.* so
-- you can drop the stdlib in favour of a single namespace per project.
--
-- Run: cargo run -- content/examples/math.lua

-- ── lurek.math.* functions ──

--@api-stub: lurek.math.newRandomGenerator
-- Creates a new random number generator with an optional seed.
-- Pass a seed for deterministic level generation; omit it to draw a fresh seed from system entropy.
do  -- lurek.math.newRandomGenerator
  local rng = lurek.math.newRandomGenerator(1337)
  local loot_roll = rng:randomInt(1, 100)
  lurek.log.info("loot roll=" .. loot_roll, "rng")
end

--@api-stub: lurek.math.newTransform
-- Creates a new Transform, optionally initialised from full parameters.
-- Use to compose translate/rotate/scale once and reuse instead of multiplying matrices each frame.
do  -- lurek.math.newTransform
  local t = lurek.math.newTransform(100, 50, math.pi / 4, 2, 2)
  local wx, wy = t:transformPoint(8, 0)
  lurek.log.debug("rotated corner at " .. wx .. "," .. wy, "xform")
end

--@api-stub: lurek.math.newBezierCurve
-- Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
-- Pass a flat {x,y,x,y,...} table of at least two points; cubic curves need four.
do  -- lurek.math.newBezierCurve
  local curve = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local mid_x, mid_y = curve:evaluate(0.5)
  lurek.log.info("bezier midpoint " .. mid_x .. "," .. mid_y, "anim")
end

--@api-stub: lurek.math.newTween
-- Creates a new Tween with the given duration and easing name.
-- Drive a tween with lurek.math.newTween then call :update(dt) every frame and read :getValue().
do  -- lurek.math.newTween
  local tw = lurek.math.newTween(0.5, "outQuad")
  tw:addValue(0, 200)
  function lurek.process(dt) tw:update(dt) end
end

--@api-stub: lurek.math.newSpatialHash
-- Creates a new SpatialHash with the given cell size.
-- Pick a cell size roughly equal to the typical entity radius; smaller cells = more cells per query.
do  -- lurek.math.newSpatialHash
  local hash = lurek.math.newSpatialHash(64)
  hash:insert("player", 100, 100, 32, 32)
  local hits = hash:queryCircle(110, 110, 50)
end

--@api-stub: lurek.math.newNoiseGenerator
-- Creates a new seeded noise generator.
-- Cache one generator per noise channel (terrain, clouds, caves) so seeds stay isolated.
do  -- lurek.math.newNoiseGenerator
  local terrain = lurek.math.newNoiseGenerator(20260422)
  local h = terrain:perlin2d(3.5, 7.25)
  lurek.log.debug("terrain h=" .. h, "noise")
end

--@api-stub: lurek.math.perlin2d
-- Returns 2D Perlin noise at (x, y) with the given seed.
-- Stateless Perlin sampler; if you need many samples with the same seed, prefer newNoiseGenerator.
do  -- lurek.math.perlin2d
  local n = lurek.math.perlin2d(0.5, 1.25, 42)
  if n > 0.6 then
    lurek.log.info("hill peak", "terrain")
  end
end

--@api-stub: lurek.math.perlin3d
-- Returns 3D Perlin noise at (x, y, z) with the given seed.
-- Use the third axis for time to animate 2D noise without seams.
do  -- lurek.math.perlin3d
  local t = 0
  function lurek.process(dt)
    t = t + dt
    local cloud = lurek.math.perlin3d(0.1, 0.2, t, 7)
    lurek.log.debug("cloud=" .. cloud, "sky")
  end
end

--@api-stub: lurek.math.simplex2d
-- Returns 2D Simplex noise at (x, y) with the given seed.
-- Faster and less directional than Perlin; preferred for organic textures and flow fields.
do  -- lurek.math.simplex2d
  local s = lurek.math.simplex2d(2.0, 3.0, 99)
  if s > 0 then
    lurek.log.debug("simplex above zero", "noise")
  end
end

--@api-stub: lurek.math.fbm
-- Returns fractal Brownian motion noise at (x, y).
-- Stack octaves of noise for natural-looking terrain; lacunarity~2 and gain~0.5 are sane defaults.
do  -- lurek.math.fbm
  local h = lurek.math.fbm(4.5, 2.0, 12345, 6, 2.0, 0.5)
  local altitude = math.floor(h * 1000)
  lurek.log.info("fbm altitude=" .. altitude, "world")
end

--@api-stub: lurek.math.applyEasing
-- Applies a named easing function to progress value t.
-- Lookup-by-name lets you store easings in level data; raises an error on unknown names.
do  -- lurek.math.applyEasing
  local name = "outBounce"
  local eased = lurek.math.applyEasing(name, 0.75)
  lurek.log.debug(name .. "(0.75)=" .. eased, "tween")
end

--@api-stub: lurek.math.linear
-- Linear easing (identity).
-- Identity easing — useful as a default tween shape that is later swapped for a curved one.
do  -- lurek.math.linear
  local t = 0.42
  local v = lurek.math.linear(t)
  lurek.log.debug("linear " .. t .. "=" .. v, "easing")
end

--@api-stub: lurek.math.inQuad
-- Quadratic ease-in — acceleration that starts at zero and increases.
-- Slow-start motion suited to objects accelerating from rest, like falling debris.
do  -- lurek.math.inQuad
  local progress = 0.3
  local y = lurek.math.inQuad(progress) * 200
  lurek.log.debug("falling y=" .. y, "anim")
end

--@api-stub: lurek.math.outQuad
-- Quadratic ease-out — deceleration that starts fast and ends at zero.
-- Decelerating motion good for UI elements that glide into their final position.
do  -- lurek.math.outQuad
  local x = lurek.math.outQuad(0.6) * 480
  lurek.log.debug("panel x=" .. x, "ui")
end

--@api-stub: lurek.math.inOutQuad
-- Quadratic ease-in-out — slow start, fast middle, slow end.
-- Symmetric ease-in-out for camera pans where both ends should feel soft.
do  -- lurek.math.inOutQuad
  local t = 0.5
  local cam_x = 100 + lurek.math.inOutQuad(t) * 400
  lurek.log.debug("cam x=" .. cam_x, "cam")
end

--@api-stub: lurek.math.inCubic
-- Cubic ease-in — acceleration starts slowly then increases sharply.
-- Stronger acceleration than inQuad; great for charge-up indicators.
do  -- lurek.math.inCubic
  local charge = lurek.math.inCubic(0.4)
  if charge > 0.5 then
    lurek.log.info("charge ready", "combat")
  end
end

--@api-stub: lurek.math.outCubic
-- Cubic ease-out — rapid deceleration using a cubic power curve.
-- Strong deceleration — ideal for tooltips that snap into view.
do  -- lurek.math.outCubic
  local opacity = lurek.math.outCubic(0.8)
  lurek.log.debug("tooltip alpha=" .. opacity, "ui")
end

--@api-stub: lurek.math.inOutCubic
-- Cubic ease-in-out — slow start and end with fast cubic middle.
-- Smoother S-curve than quad; standard easing for menu transitions.
do  -- lurek.math.inOutCubic
  local t = lurek.math.inOutCubic(0.25)
  local panel_y = 600 - t * 400
  lurek.log.debug("panel y=" .. panel_y, "ui")
end

--@api-stub: lurek.math.inQuart
-- Quartic ease-in — strongly delayed acceleration using a power-of-4 curve.
-- Very late acceleration; use for power-up wind-ups that linger then snap.
do  -- lurek.math.inQuart
  local v = lurek.math.inQuart(0.7)
  lurek.log.debug("inQuart=" .. v, "easing")
end

--@api-stub: lurek.math.outQuart
-- Quartic ease-out — rapid deceleration using a power-of-4 curve.
-- Sharp early motion that quickly settles; useful for slammed doors closing.
do  -- lurek.math.outQuart
  local v = lurek.math.outQuart(0.2)
  lurek.log.debug("outQuart=" .. v, "easing")
end

--@api-stub: lurek.math.inOutQuart
-- Quartic ease-in-out — very slow start and end with a sharp middle peak.
-- Long flat ends with a steep middle — good for dramatic camera dolly-ins.
do  -- lurek.math.inOutQuart
  local v = lurek.math.inOutQuart(0.5)
  lurek.log.debug("inOutQuart=" .. v, "easing")
end

--@api-stub: lurek.math.inSine
-- Sinusoidal ease-in — gentle acceleration based on a sine curve.
-- Gentle quarter-circle ramp; matches natural breathing or pulsing animations.
do  -- lurek.math.inSine
  local pulse = lurek.math.inSine(0.4)
  lurek.log.debug("pulse=" .. pulse, "fx")
end

--@api-stub: lurek.math.outSine
-- Sinusoidal ease-out — gentle deceleration based on a cosine curve.
-- Soft deceleration based on cosine — good fit for icons fading in.
do  -- lurek.math.outSine
  local v = lurek.math.outSine(0.6)
  lurek.log.debug("icon alpha=" .. v, "ui")
end

--@api-stub: lurek.math.inOutSine
-- Sinusoidal ease-in-out — smooth S-curve based on cosine interpolation.
-- Symmetric and very subtle; perfect for ambient parallax drift.
do  -- lurek.math.inOutSine
  local v = lurek.math.inOutSine(0.5)
  lurek.log.debug("drift=" .. v, "bg")
end

--@api-stub: lurek.math.inExpo
-- Exponential ease-in — very slow start that accelerates sharply near the end.
-- Almost flat then explosive; use sparingly for impact build-up.
do  -- lurek.math.inExpo
  local v = lurek.math.inExpo(0.85)
  lurek.log.debug("inExpo=" .. v, "fx")
end

--@api-stub: lurek.math.outExpo
-- Exponential ease-out — sharp initial speed that decelerates exponentially.
-- Snaps to peak then settles — feels like a sword swing recoiling.
do  -- lurek.math.outExpo
  local v = lurek.math.outExpo(0.15)
  lurek.log.debug("outExpo=" .. v, "fx")
end

--@api-stub: lurek.math.inOutExpo
-- Exponential ease-in-out — very slow start and end with an exponential surge.
-- Long flat regions with a sharp middle; reserve for cinematic flashes.
do  -- lurek.math.inOutExpo
  local v = lurek.math.inOutExpo(0.5)
  lurek.log.debug("inOutExpo=" .. v, "fx")
end

--@api-stub: lurek.math.inElastic
-- Elastic ease-in — spring-like overshoot at the beginning of the motion.
-- Spring overshoot at the start; good for cartoon wind-ups.
do  -- lurek.math.inElastic
  local v = lurek.math.inElastic(0.8)
  lurek.log.debug("inElastic=" .. v, "anim")
end

--@api-stub: lurek.math.outElastic
-- Elastic ease-out — spring-like oscillation that settles at the target.
-- Final spring jiggle; great for buttons that pop in and oscillate.
do  -- lurek.math.outElastic
  local v = lurek.math.outElastic(0.6)
  lurek.log.debug("button bounce=" .. v, "ui")
end

--@api-stub: lurek.math.outBounce
-- Bounce ease-out — simulates a ball bouncing against the target value.
-- Mimics a ball settling on the floor; lovely for trophy drop-ins.
do  -- lurek.math.outBounce
  local h = lurek.math.outBounce(0.3) * 100
  lurek.log.debug("bounce h=" .. h, "fx")
end

--@api-stub: lurek.math.inBounce
-- Bounce ease-in — reverse bounce effect that accelerates into the motion.
-- Reverse bounce — the object hops up before launching.
do  -- lurek.math.inBounce
  local v = lurek.math.inBounce(0.7)
  lurek.log.debug("inBounce=" .. v, "fx")
end

--@api-stub: lurek.math.inBack
-- Back ease-in — overshoots slightly before settling at the target.
-- Pulls back before moving forward; useful for menu buttons winding up.
do  -- lurek.math.inBack
  local v = lurek.math.inBack(0.5)
  lurek.log.debug("inBack=" .. v, "ui")
end

--@api-stub: lurek.math.outBack
-- Back ease-out — overshoots the target then snaps back into place.
-- Overshoots target then settles — a classic for HUD pop-in.
do  -- lurek.math.outBack
  local v = lurek.math.outBack(0.5)
  lurek.log.debug("outBack=" .. v, "ui")
end

--@api-stub: lurek.math.inOutElastic
-- Elastic ease-in-out — spring-like oscillation on both ends.
-- Both ends spring; flashy and best reserved for celebration moments.
do  -- lurek.math.inOutElastic
  local v = lurek.math.inOutElastic(0.4)
  lurek.log.debug("inOutElastic=" .. v, "fx")
end

--@api-stub: lurek.math.inOutBounce
-- Bounce ease-in-out — bouncing motion on both ends.
-- Bounces at both ends; rare in production but great for victory screens.
do  -- lurek.math.inOutBounce
  local v = lurek.math.inOutBounce(0.5)
  lurek.log.debug("inOutBounce=" .. v, "fx")
end

--@api-stub: lurek.math.inOutBack
-- Back ease-in-out — overshoot on both ends.
-- Symmetric overshoot; balanced anticipation followed by overshoot.
do  -- lurek.math.inOutBack
  local v = lurek.math.inOutBack(0.5)
  lurek.log.debug("inOutBack=" .. v, "fx")
end

--@api-stub: lurek.math.triangulate
-- Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
-- Pass a flat {x,y,...} polygon (>=3 verts); use the returned triangles to feed a mesh batch.
do  -- lurek.math.triangulate
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local tris = lurek.math.triangulate(poly)
  lurek.log.info("triangulated into " .. #tris .. " triangles", "geo")
end

--@api-stub: lurek.math.isConvex
-- Returns true if the polygon (flat table {x1,y1,...}) is convex.
-- Cheap convexity check before sending a polygon to a SAT collision routine.
do  -- lurek.math.isConvex
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  if lurek.math.isConvex(poly) then
    lurek.log.debug("polygon is convex", "geo")
  end
end

--@api-stub: lurek.math.gammaToLinear
-- Converts a gamma-encoded sRGB value to linear space.
-- Convert sRGB texel values before lighting math; engine textures are usually already linear.
do  -- lurek.math.gammaToLinear
  local linear = lurek.math.gammaToLinear(0.5)
  lurek.log.debug("0.5 sRGB -> " .. linear .. " linear", "color")
end

--@api-stub: lurek.math.linearToGamma
-- Converts a linear-space value to gamma-encoded sRGB.
-- Convert lit color back to sRGB before storing in a screenshot or 8-bit asset.
do  -- lurek.math.linearToGamma
  local srgb = lurek.math.linearToGamma(0.214)
  lurek.log.debug("linear 0.214 -> " .. srgb .. " sRGB", "color")
end

--@api-stub: lurek.math.angleBetween
-- Returns the angle in radians from (x1, y1) to (x2, y2).
-- Returns radians; use lurek.math.deg() to convert before showing to the player.
do  -- lurek.math.angleBetween
  local rad = lurek.math.angleBetween(0, 0, 100, 100)
  lurek.log.debug("angle=" .. lurek.math.deg(rad) .. " deg", "geo")
end

--@api-stub: lurek.math.circleContainsPoint
-- Returns true if the point (px, py) lies inside the circle.
-- Cheap inclusive hit test for radial pickups, auras, or trigger volumes.
do  -- lurek.math.circleContainsPoint
  if lurek.math.circleContainsPoint(0, 0, 50, 30, 20) then
    lurek.log.info("inside aura", "trigger")
  end
end

--@api-stub: lurek.math.circleIntersectsCircle
-- Returns true if two circles overlap.
-- Used in broad-phase collision when both shapes are well-approximated by spheres.
do  -- lurek.math.circleIntersectsCircle
  if lurek.math.circleIntersectsCircle(0, 0, 10, 8, 6, 5) then
    lurek.log.warn("orbs collided", "physics")
  end
end

--@api-stub: lurek.math.circleIntersectsLine
-- Tests an infinite line against a circle.
-- Returns hit then up to two intersection coords; use for laser beam vs shield.
do  -- lurek.math.circleIntersectsLine
  local hit, ix, iy = lurek.math.circleIntersectsLine(0, 0, 50, -100, 0, 100, 0)
  if hit then
    lurek.log.info("laser hit at " .. ix .. "," .. iy, "fx")
  end
end

--@api-stub: lurek.math.circleIntersectsSegment
-- Tests a line segment against a circle.
-- Like circleIntersectsLine but bounded to the segment endpoints — use for bullet vs target.
do  -- lurek.math.circleIntersectsSegment
  local hit, ix, iy = lurek.math.circleIntersectsSegment(20, 0, 5, 0, 0, 40, 0)
  if hit then
    lurek.log.info("bullet impact " .. ix .. "," .. iy, "combat")
  end
end

--@api-stub: lurek.math.closestPointOnSegment
-- Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
-- Useful for snapping a cursor to the nearest road or finding the closest patrol path point.
do  -- lurek.math.closestPointOnSegment
  local cx, cy = lurek.math.closestPointOnSegment(50, 30, 0, 0, 100, 0)
  lurek.log.debug("nearest=" .. cx .. "," .. cy, "ai")
end

--@api-stub: lurek.math.convexHull
-- Computes the convex hull of a flat {x1,y1,...} point list.
-- Use to wrap a particle cloud or a list of unit positions in a tight convex outline.
do  -- lurek.math.convexHull
  local pts = {0, 0, 100, 0, 50, 50, 100, 100, 0, 100}
  local hull = lurek.math.convexHull(pts)
  lurek.log.info("hull verts=" .. (#hull / 2), "geo")
end

--@api-stub: lurek.math.delaunayTriangulate
-- Delaunay triangulation of a flat {x1,y1,...} point list.
-- Use for navmesh generation, terrain meshing, or Voronoi seed processing.
do  -- lurek.math.delaunayTriangulate
  local pts = {0, 0, 100, 0, 50, 80, 60, 30}
  local tris = lurek.math.delaunayTriangulate(pts)
  lurek.log.info("delaunay tris=" .. #tris, "geo")
end

--@api-stub: lurek.math.lineIntersect
-- Infinite line intersection.
-- Returns nil for parallel lines; treat that case as no hit before reading ix/iy.
do  -- lurek.math.lineIntersect
  local ix, iy = lurek.math.lineIntersect(0, 0, 100, 100, 0, 100, 100, 0)
  if ix then
    lurek.log.debug("cross at " .. ix .. "," .. iy, "geo")
  end
end

--@api-stub: lurek.math.pointInPolygon
-- Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
-- Use the ray-cast test for arbitrary polygons; convex shapes can use cheaper SAT instead.
do  -- lurek.math.pointInPolygon
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  if lurek.math.pointInPolygon(poly, 50, 50) then
    lurek.log.info("inside zone", "trigger")
  end
end

--@api-stub: lurek.math.polygonArea
-- Returns the signed area of a polygon given as a flat {x1,y1,...} table.
-- Returns signed area; absolute value is the area, sign tells you the winding order.
do  -- lurek.math.polygonArea
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local area = lurek.math.polygonArea(poly)
  lurek.log.info("polygon area=" .. math.abs(area), "geo")
end

--@api-stub: lurek.math.polygonCentroid
-- Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
-- Use as the natural pivot for rotating a polygon or anchoring a label on its surface.
do  -- lurek.math.polygonCentroid
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local cx, cy = lurek.math.polygonCentroid(poly)
  lurek.log.debug("centroid " .. cx .. "," .. cy, "geo")
end

--@api-stub: lurek.math.segmentIntersectsSegment
-- Tests if two line segments intersect.
-- Bounded version of lineIntersect — use for laser-beam-vs-wall or sword swing arcs.
do  -- lurek.math.segmentIntersectsSegment
  local hit, ix, iy = lurek.math.segmentIntersectsSegment(0, 0, 100, 0, 50, -50, 50, 50)
  if hit then
    lurek.log.info("blade crossed " .. ix .. "," .. iy, "combat")
  end
end

--@api-stub: lurek.math.bresenham
-- Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm.
-- Returns integer-coord points; perfect for line-of-sight on a tile grid.
do  -- lurek.math.bresenham
  local pts = lurek.math.bresenham(0, 0, 5, 3)
  lurek.log.info("bresenham steps=" .. #pts, "tile")
end

--@api-stub: lurek.math.rad
-- Converts degrees to radians.
-- Convert UI-friendly degrees to engine-friendly radians once at config-load time.
do  -- lurek.math.rad
  local turn_deg = 90
  local turn_rad = lurek.math.rad(turn_deg)
  lurek.log.debug(turn_deg .. " deg = " .. turn_rad .. " rad", "math")
end

--@api-stub: lurek.math.deg
-- Converts radians to degrees.
-- Convert radians back to degrees when displaying compass headings to the player.
do  -- lurek.math.deg
  local heading = lurek.math.deg(math.pi / 2)
  lurek.log.info("heading=" .. heading .. " deg", "compass")
end

--@api-stub: lurek.math.sin
-- Returns the sine of x (radians).
-- Use for oscillating bobs, springs, or waveform generation — period is 2*pi.
do  -- lurek.math.sin
  local t = 0
  function lurek.process(dt)
    t = t + dt
    local bob = lurek.math.sin(t * 2) * 8
    lurek.log.debug("bob=" .. bob, "fx")
  end
end

--@api-stub: lurek.math.cos
-- Returns the cosine of x (radians).
-- Pair with sin for circular motion; cos starts at 1, sin at 0.
do  -- lurek.math.cos
  local t = 1.5
  local x = lurek.math.cos(t) * 50
  lurek.log.debug("orbit x=" .. x, "fx")
end

--@api-stub: lurek.math.tan
-- Returns the tangent of x (radians).
-- Avoid near pi/2 + k*pi where it diverges; use atan2 for safe angle work.
do  -- lurek.math.tan
  local slope = lurek.math.tan(math.pi / 6)
  lurek.log.debug("30deg slope=" .. slope, "math")
end

--@api-stub: lurek.math.asin
-- Returns the arcsine of x, in radians.
-- Input must be in [-1, 1] or NaN results; clamp first if computed from a dot product.
do  -- lurek.math.asin
  local angle = lurek.math.asin(0.5)
  lurek.log.debug("asin(0.5)=" .. lurek.math.deg(angle), "math")
end

--@api-stub: lurek.math.acos
-- Returns the arccosine of x, in radians.
-- Use to recover an angle from the dot product of two unit vectors.
do  -- lurek.math.acos
  local angle = lurek.math.acos(0.0)
  lurek.log.debug("acos(0)=" .. lurek.math.deg(angle), "math")
end

--@api-stub: lurek.math.atan
-- Returns the arctangent of x (or atan2(y, x) when two args given).
-- Two-arg form is full-quadrant atan2; one-arg form returns [-pi/2, pi/2].
do  -- lurek.math.atan
  local a = lurek.math.atan(1.0)
  local b = lurek.math.atan(1.0, -1.0)
  lurek.log.debug("atan results " .. a .. " " .. b, "math")
end

--@api-stub: lurek.math.atan2
-- Returns atan(y/x) using the signs of both args to determine the quadrant.
-- Use atan2(dy, dx) to compute the heading from one point to another.
do  -- lurek.math.atan2
  local dx, dy = 100 - 0, 50 - 0
  local heading = lurek.math.atan2(dy, dx)
  lurek.log.info("heading rad=" .. heading, "ai")
end

--@api-stub: lurek.math.sqrt
-- Returns the square root of x.
-- Avoid sqrt in hot loops; lurek.math.distanceSq is enough for ranking comparisons.
do  -- lurek.math.sqrt
  local hyp = lurek.math.sqrt(3 * 3 + 4 * 4)
  lurek.log.debug("hyp=" .. hyp, "math")
end

--@api-stub: lurek.math.abs
-- Returns the absolute value of x.
-- Strip the sign before comparing magnitudes — handy when reading axis input.
do  -- lurek.math.abs
  local axis = -0.7
  if lurek.math.abs(axis) > 0.2 then
    lurek.log.debug("axis active", "input")
  end
end

--@api-stub: lurek.math.floor
-- Returns the largest integer ≤ x.
-- Snap world-space coords to integer pixels for crisp pixel-art rendering.
do  -- lurek.math.floor
  local raw_x = 123.7
  local pixel_x = lurek.math.floor(raw_x)
  lurek.log.debug("pixel x=" .. pixel_x, "render")
end

--@api-stub: lurek.math.ceil
-- Returns the smallest integer ≥ x.
-- Round damage up so a tiny attack always shaves at least one HP.
do  -- lurek.math.ceil
  local dmg = lurek.math.ceil(2.3)
  lurek.log.info("damage=" .. dmg, "combat")
end

--@api-stub: lurek.math.round
-- Returns x rounded to the nearest integer (half-up).
-- Half-up rounding; pair with /scale for snapping mouse coords to a UI grid.
do  -- lurek.math.round
  local snapped = lurek.math.round(127.5)
  lurek.log.debug("rounded=" .. snapped, "ui")
end

--@api-stub: lurek.math.exp
-- Returns e raised to the power x.
-- Natural exponential; useful for time-decay shaping like 1 - exp(-k*t).
do  -- lurek.math.exp
  local decay = lurek.math.exp(-0.5)
  lurek.log.debug("decay=" .. decay, "math")
end

--@api-stub: lurek.math.log
-- Returns the natural log of x, or log base b if b is supplied.
-- One-arg returns ln; pass a base for log_b. Use for log-scale audio sliders.
do  -- lurek.math.log
  local db = 20 * lurek.math.log(0.5, 10)
  lurek.log.debug("0.5 -> " .. db .. " dB", "audio")
end

--@api-stub: lurek.math.pow
-- Returns x raised to the power y.
-- Prefer x*x for squaring; pow shines when the exponent is fractional or variable.
do  -- lurek.math.pow
  local energy = lurek.math.pow(2.0, 8)
  lurek.log.debug("2^8=" .. energy, "math")
end

--@api-stub: lurek.math.min
-- Returns the smallest of the supplied numbers.
-- Variadic; handy for clamping a damage roll against several caps at once.
do  -- lurek.math.min
  local function current_hp_or_default(v) return v end
  local clamp_hp = lurek.math.min(100, current_hp_or_default(85), 90)
  lurek.log.debug("hp=" .. clamp_hp, "combat")
end

--@api-stub: lurek.math.max
-- Returns the largest of the supplied numbers.
-- Use to enforce a floor — e.g. damage taken cannot drop below 1.
do  -- lurek.math.max
  local final = lurek.math.max(1, 5 - 7)
  lurek.log.debug("final dmg=" .. final, "combat")
end

--@api-stub: lurek.math.clamp
-- Clamps `v` between `min` and `max`.
-- Use to keep camera or audio volume inside its valid range each frame.
do  -- lurek.math.clamp
  local volume = lurek.math.clamp(1.4, 0, 1)
  lurek.log.debug("clamped vol=" .. volume, "audio")
end

--@api-stub: lurek.math.sign
-- Returns -1, 0, or 1 depending on the sign of `v`.
-- Returns -1, 0, or 1; use to derive movement direction from an analogue stick.
do  -- lurek.math.sign
  local axis = -0.4
  local dir = lurek.math.sign(axis)
  lurek.log.debug("walk dir=" .. dir, "input")
end

--@api-stub: lurek.math.fmod
-- Returns the remainder of x / y (fmod).
-- Wrap an angle into [0, 2*pi) by fmod(angle, lurek.math.tau).
do  -- lurek.math.fmod
  local wrapped = lurek.math.fmod(7.5, lurek.math.tau)
  lurek.log.debug("wrapped=" .. wrapped, "math")
end

--@api-stub: lurek.math.lerp
-- Linear interpolation between two numbers: a + (b - a) * t.
-- First-class linear blend; t outside [0,1] extrapolates rather than clamping.
do  -- lurek.math.lerp
  local hp_bar = lurek.math.lerp(0, 200, 0.42)
  lurek.log.debug("hp bar pixels=" .. hp_bar, "ui")
end

--@api-stub: lurek.math.distance
-- Returns the Euclidean distance between (x1,y1) and (x2,y2).
-- Use only when you need the actual length; ranking by closeness only needs distanceSq.
do  -- lurek.math.distance
  local d = lurek.math.distance(0, 0, 3, 4)
  if d < 10 then
    lurek.log.debug("near target", "ai")
  end
end

--@api-stub: lurek.math.distanceSq
-- Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
-- Skip the sqrt by comparing squared distances against a squared threshold.
do  -- lurek.math.distanceSq
  local d2 = lurek.math.distanceSq(0, 0, 3, 4)
  if d2 < 100 then
    lurek.log.debug("within 10 units", "ai")
  end
end

--@api-stub: lurek.math.random
-- Returns a pseudo-random number in [0,1) with no args,.
-- Wrappers Lua's math.random; seed via lurek.math.newRandomGenerator for determinism.
do  -- lurek.math.random
  local rolled = lurek.math.random(1, 6)
  lurek.log.info("dice=" .. rolled, "rng")
end

--@api-stub: lurek.math.randomInt
-- Returns a pseudo-random integer in [lo, hi] (inclusive).
-- Inclusive on both ends; ideal for dice rolls and inventory slot picks.
do  -- lurek.math.randomInt
  local slot = lurek.math.randomInt(1, 8)
  lurek.log.debug("loot slot=" .. slot, "rng")
end

--@api-stub: lurek.math.simplexNoise
-- Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
-- Stateless 2D/3D simplex; pass z to animate over time without seam artefacts.
do  -- lurek.math.simplexNoise
  local n = lurek.math.simplexNoise(0.5, 1.5, 0.0)
  lurek.log.debug("simplex=" .. n, "noise")
end

--@api-stub: lurek.math.vec2
-- Creates a 2D vector with x and y components.
-- Use to create a Vec2 userdata; supports +, -, *, length, normalize, etc.
do  -- lurek.math.vec2
  local pos = lurek.math.vec2(3, 4)
  local len = pos:length()
  lurek.log.debug("pos length=" .. len, "math")
end

--@api-stub: lurek.math.Vec2
-- Compatibility alias for `vec2`.
-- PascalCase alias for vec2 to match style guides that capitalise type-like constructors.
do  -- lurek.math.Vec2
  local v = lurek.math.Vec2(10, 20)
  local n = v:normalize()
  lurek.log.debug("normalised x=" .. n.x, "math")
end

--@api-stub: lurek.math.vec3
-- Creates a 3D vector `{x, y, z}` table with numeric components.
-- Make a 3D point; required for the few APIs (e.g. light direction) that work in 3-space.
do  -- lurek.math.vec3
  ---@type Vec3
  local p = lurek.math.vec3(1, 2, 3)
  local len = p:length()
  lurek.log.debug("vec3 len=" .. len, "math")
end

--@api-stub: lurek.math.Vec3
-- Compatibility alias for `vec3`.
-- PascalCase alias for vec3 for code that prefers the constructor convention.
do  -- lurek.math.Vec3
  ---@type Vec3
  local p = lurek.math.Vec3(0, 0, 1)
  local s = p:scale(5)
  lurek.log.debug("scaled z=" .. s.z, "math")
end

--@api-stub: lurek.math.catmullRom
-- Creates a Catmull-Rom spline through the given control points.
-- Pass {x=..,y=..} or {x,y} tables; the spline interpolates THROUGH every control point.
do  -- lurek.math.catmullRom
  ---@type CatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=100,y=200},{x=300,y=200},{x=400,y=0}})
  local x, y = cr:sample(0.5)
  lurek.log.debug("catmull mid " .. x .. "," .. y, "spline")
end

--@api-stub: lurek.math.hermite
-- Creates a Hermite spline defined by two endpoints and tangents.
-- Endpoints + tangents define the curve; double-check tangent magnitude for arc length sense.
do  -- lurek.math.hermite
  ---@type Hermite
  local h = lurek.math.hermite(0, 0, 100, 100, 50, 0, 0, 50)
  local mx, my = h:sample(0.5)
  lurek.log.debug("hermite mid " .. mx .. "," .. my, "spline")
end

--@api-stub: lurek.math.lerp
-- Linear interpolation between two numbers: a + (b - a) * t.
-- f32 overload of lerp; functionally identical for most game-data values.
do  -- lurek.math.lerp
  local v = lurek.math.lerp(10.0, 20.0, 0.25)
  lurek.log.debug("lerp v=" .. v, "math")
end

--@api-stub: lurek.math.remap
-- Remaps `v` from [in_min, in_max] to [out_min, out_max].
-- Maps a value across two ranges in one call — handy for scaling sensor input to UI sliders.
do  -- lurek.math.remap
  local mapped = lurek.math.remap(127, 0, 255, 0, 1)
  lurek.log.debug("normalised input=" .. mapped, "input")
end

--@api-stub: lurek.math.clamp
-- Clamps `v` between `min` and `max`.
-- f32 overload — pin a control value into [min, max] without branching.
do  -- lurek.math.clamp
  local angle = lurek.math.clamp(2.5, -math.pi, math.pi)
  lurek.log.debug("clamped angle=" .. angle, "math")
end

--@api-stub: lurek.math.sign
-- Returns -1, 0, or 1 depending on the sign of `v`.
-- f32 overload returning -1, 0, or 1 from the sign of v.
do  -- lurek.math.sign
  local s = lurek.math.sign(-3.7)
  lurek.log.debug("sign=" .. s, "math")
end

--@api-stub: lurek.math.smoothstep
-- Hermite smoothstep between `edge0` and `edge1`.
-- Hermite smoothstep; returns 0 below edge0, 1 above edge1, smooth between.
do  -- lurek.math.smoothstep
  local fade = lurek.math.smoothstep(50, 100, 75)
  lurek.log.debug("fade=" .. fade, "fx")
end

--@api-stub: lurek.math.inverseLerp
-- Returns the interpolation parameter t for `v` in [a, b].
-- Inverse of lerp — recover the t parameter that interpolates a to b into v.
do  -- lurek.math.inverseLerp
  local t = lurek.math.inverseLerp(0, 200, 50)
  lurek.log.debug("t=" .. t, "math")
end

--@api-stub: lurek.math.hslToRgb
-- Converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats.
-- Hue is degrees [0, 360]; saturation and lightness are [0, 1].
do  -- lurek.math.hslToRgb
  local r, g, b, a = lurek.math.hslToRgb(200, 0.7, 0.5)
  lurek.log.debug("rgb " .. r .. "," .. g .. "," .. b, "color")
end

--@api-stub: lurek.math.fromHex
-- Parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats.
-- Accepts #RRGGBB or #RRGGBBAA; raises if the string is malformed, so validate config first.
do  -- lurek.math.fromHex
  local r, g, b, a = lurek.math.fromHex("#ff8800")
  lurek.log.debug("hex -> " .. r .. "," .. g .. "," .. b, "color")
end

--@api-stub: lurek.math.rgbToHsl
-- Converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1).
-- Round-trip via hslToRgb to verify; useful for procedural palette shifts.
do  -- lurek.math.rgbToHsl
  local h, s, l = lurek.math.rgbToHsl(1.0, 0.5, 0.0)
  lurek.log.debug("hsl " .. h .. "," .. s .. "," .. l, "color")
end

--@api-stub: lurek.math.rectUnion
-- Returns the union (bounding box) of two rectangles.
-- Use to grow a dirty-rect tracker each frame, then redraw only the union.
do  -- lurek.math.rectUnion
  local x, y, w, h = lurek.math.rectUnion(0, 0, 50, 50, 30, 30, 60, 60)
  lurek.log.debug("union " .. w .. "x" .. h, "ui")
end

--@api-stub: lurek.math.rectFromCenter
-- Creates a rectangle centered at (cx, cy) with the given width and height.
-- Convenient when an enemy hitbox is described by centre + size rather than top-left.
do  -- lurek.math.rectFromCenter
  local x, y, w, h = lurek.math.rectFromCenter(100, 100, 32, 32)
  lurek.log.debug("rect " .. x .. "," .. y, "geo")
end

--@api-stub: lurek.math.polygonClip
-- Clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
-- Clips against a single half-plane (nx*x + ny*y >= d); call repeatedly to clip against a frustum.
do  -- lurek.math.polygonClip
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local clipped = lurek.math.polygonClip(poly, 1, 0, 50)
  lurek.log.debug("clipped verts=" .. (#clipped / 2), "geo")
end

--@api-stub: lurek.math.aabbTree
-- Creates a new empty AABB tree for efficient broad-phase overlap queries.
-- Builds an empty broad-phase tree; add bodies with :insert and :update each tick.
do  -- lurek.math.aabbTree
  local tree = lurek.math.aabbTree()
  tree:insert(1, 0, 0, 32, 32)
  lurek.log.debug("tree size=" .. tree:len(), "physics")
end

--@api-stub: lurek.math.newCircle
-- Creates a new Circle value type with the given centre and radius.
-- Negative radii are clamped to 0; pass world coords for the centre.
do  -- lurek.math.newCircle
  local c = lurek.math.newCircle(0, 0, 25)
  if c:contains(10, 5) then
    lurek.log.debug("inside circle", "geo")
  end
end

--@api-stub: lurek.math.polygonIntersection
-- Computes the intersection of two convex polygons using the Sutherland-Hodgman.
-- Both inputs must be arrays of {x=..,y=..} tables; result is the overlapping convex region.
do  -- lurek.math.polygonIntersection
  local a = {{x=0,y=0},{x=100,y=0},{x=100,y=100},{x=0,y=100}}
  local b = {{x=50,y=50},{x=150,y=50},{x=150,y=150},{x=50,y=150}}
  local hit = lurek.math.polygonIntersection(a, b)
  lurek.log.info("overlap verts=" .. #hit, "geo")
end

--@api-stub: lurek.math.polygonUnion
-- Computes the approximate union of two convex polygons as the convex hull of.
-- Approximated as the convex hull of all vertices — fine for visualisations, not for area math.
do  -- lurek.math.polygonUnion
  local a = {{x=0,y=0},{x=100,y=0},{x=100,y=100},{x=0,y=100}}
  local b = {{x=80,y=80},{x=180,y=80},{x=180,y=180},{x=80,y=180}}
  local u = lurek.math.polygonUnion(a, b)
  lurek.log.info("union verts=" .. #u, "geo")
end

--@api-stub: lurek.math.polygonDifference
-- Computes the approximate difference `A - B` (the part of A not covered by B).
-- Approximate A - B (best when B is convex); use for fog-of-war erosion.
do  -- lurek.math.polygonDifference
  local a = {{x=0,y=0},{x=100,y=0},{x=100,y=100},{x=0,y=100}}
  local b = {{x=20,y=20},{x=80,y=20},{x=80,y=80},{x=20,y=80}}
  local diff = lurek.math.polygonDifference(a, b)
  lurek.log.info("diff verts=" .. #diff, "geo")
end

--@api-stub: lurek.math.voronoi
-- Computes the Voronoi diagram for a list of 2-D seed points.
-- Returns one cell per seed; hull cells are open (no infinite rays clipped).
do  -- lurek.math.voronoi
  local seeds = {{x=0,y=0},{x=100,y=0},{x=50,y=80}}
  local cells = lurek.math.voronoi(seeds)
  lurek.log.info("voronoi cells=" .. #cells, "geo")
end

--@api-stub: Vec2:dot
-- Returns the dot product with another vector.
-- Dot product of two unit vectors gives cos(angle); use for view-cone tests.
do  -- Vec2:dot
  local a = lurek.math.vec2(1, 0)
  local b = lurek.math.vec2(0, 1)
  lurek.log.debug("dot=" .. a:dot(b), "math")
end

--@api-stub: Vec2:length
-- Returns the Euclidean length of the vector.
-- O(sqrt) — prefer lengthSquared for ordering comparisons.
do  -- Vec2:length
  local v = lurek.math.vec2(3, 4)
  local len = v:length()
  lurek.log.info("len=" .. len, "math")
end

--@api-stub: Vec2:x
-- Returns the horizontal component of the vector.
-- Method form of the x field; useful when chaining or storing accessors.
do  -- Vec2:x
  local v = lurek.math.vec2(7, 9)
  local x = v.x
  lurek.log.debug("x=" .. x, "math")
end

--@api-stub: Vec2:y
-- Returns the vertical component of the vector.
-- Method form of the y field; mirrors :x() for consistency.
do  -- Vec2:y
  local v = lurek.math.vec2(7, 9)
  local y = v.y
  lurek.log.debug("y=" .. y, "math")
end

--@api-stub: Vec2:lengthSquared
-- Returns the squared length of the vector (faster than length).
-- Avoids the sqrt; ideal for radius-squared comparisons inside hot loops.
do  -- Vec2:lengthSquared
  local v = lurek.math.vec2(3, 4)
  if v:lengthSquared() > 25 then
    lurek.log.debug("vector longer than 5", "math")
  end
end

--@api-stub: Vec2:normalize
-- Returns a unit-length copy of this vector.
-- Returns a new unit-length vector; zero-length input yields the zero vector.
do  -- Vec2:normalize
  local dir = lurek.math.vec2(10, 0):normalize()
  lurek.log.debug("dir x=" .. dir.x, "math")
end

--@api-stub: Vec2:normalized
-- Compatibility alias for `normalize`.
-- Compatibility alias for normalize() to ease porting code from other engines.
do  -- Vec2:normalized
  local n = lurek.math.vec2(0, 5):normalized()
  lurek.log.debug("n.y=" .. n.y, "math")
end

--@api-stub: Vec2:lerp
-- Returns a linearly interpolated vector between this and other at parameter t.
-- Returns a new vector blending self toward other by parameter t.
do  -- Vec2:lerp
  local a = lurek.math.vec2(0, 0)
  local b = lurek.math.vec2(100, 0)
  local mid = a:lerp(b, 0.5)
  lurek.log.debug("mid x=" .. mid.x, "math")
end

--@api-stub: Vec2:distance
-- Returns the Euclidean distance from this vector to another.
-- Convenience wrapper for (other - self):length().
do  -- Vec2:distance
  local a = lurek.math.vec2(0, 0)
  local b = lurek.math.vec2(3, 4)
  lurek.log.info("dist=" .. a:distance(b), "math")
end

--@api-stub: Vec2:angle
-- Returns the angle of this vector in radians (atan2(y, x)).
-- Returns atan2(y, x) in radians; useful for sprite facing.
do  -- Vec2:angle
  local v = lurek.math.vec2(0, 1)
  lurek.log.debug("angle=" .. lurek.math.deg(v:angle()), "math")
end

--@api-stub: Vec2:rotate
-- Returns a new vector rotated by the given angle in radians.
-- Returns a new vector; positive angle rotates counter-clockwise in screen-up space.
do  -- Vec2:rotate
  local v = lurek.math.vec2(10, 0)
  local r = v:rotate(math.pi / 2)
  lurek.log.debug("rotated x=" .. r.x .. " y=" .. r.y, "math")
end

--@api-stub: Vec2:perpendicular
-- Returns the perpendicular vector (-y, x).
-- Returns (-y, x) — a 90-degree CCW rotation; double-apply to get the negation.
do  -- Vec2:perpendicular
  local n = lurek.math.vec2(1, 0):perpendicular()
  lurek.log.debug("perp y=" .. n.y, "math")
end

--@api-stub: Vec2:cross
-- Returns the 2D cross product (scalar) with another vector.
-- 2D cross is a scalar; sign tells you which side of self the other vector is on.
do  -- Vec2:cross
  local a = lurek.math.vec2(1, 0)
  local b = lurek.math.vec2(0, 1)
  lurek.log.debug("cross=" .. a:cross(b), "math")
end

--@api-stub: Vec2:reflect
-- Reflects this vector off a surface with the given normal.
-- Reflects self off a surface with the given (unit) normal — used for bouncing balls.
do  -- Vec2:reflect
  local incoming = lurek.math.vec2(1, -1)
  local floor = lurek.math.vec2(0, 1)
  local bounced = incoming:reflect(floor)
  lurek.log.debug("bounce y=" .. bounced.y, "physics")
end

--@api-stub: Vec3:length
-- Returns the Euclidean length of the vector.
-- Euclidean length in 3D; use for camera-to-actor distance in 2.5D scenes.
do  -- Vec3:length
  ---@type Vec3
  local v = lurek.math.vec3(1, 2, 2)
  lurek.log.debug("len=" .. v:length(), "math")
end

--@api-stub: Vec3:lengthSquared
-- Returns the squared Euclidean length (avoids sqrt).
-- Squared length — avoid the sqrt when sorting things by distance.
do  -- Vec3:lengthSquared
  ---@type Vec3
  local v = lurek.math.vec3(2, 2, 1)
  lurek.log.debug("len2=" .. v:lengthSquared(), "math")
end

--@api-stub: Vec3:normalize
-- Returns a unit-length version of this vector.
-- Returns a new unit-length Vec3; required when computing reflection or lighting.
do  -- Vec3:normalize
  ---@type Vec3
  local v = lurek.math.vec3(0, 0, 5)
  local n = v:normalize()
  lurek.log.debug("n.z=" .. n.z, "math")
end

--@api-stub: Vec3:dot
-- Dot product with another Vec3.
-- Cosine of angle between unit vectors; use for diffuse light shading.
do  -- Vec3:dot
  ---@type Vec3
  local n = lurek.math.vec3(0, 1, 0)
  ---@type Vec3
  local l = lurek.math.vec3(0, 1, 0)
  lurek.log.debug("ndotl=" .. n:dot(l), "light")
end

--@api-stub: Vec3:cross
-- Cross product with another Vec3.
-- Right-hand rule cross; use to derive a perpendicular axis for rotations.
do  -- Vec3:cross
  ---@type Vec3
  local x = lurek.math.vec3(1, 0, 0)
  ---@type Vec3
  local y = lurek.math.vec3(0, 1, 0)
  local z = x:cross(y)
  lurek.log.debug("z.z=" .. z.z, "math")
end

--@api-stub: Vec3:lerp
-- Linear interpolation towards another Vec3.
-- Returns a new vector; component-wise linear blend.
do  -- Vec3:lerp
  ---@type Vec3
  local a = lurek.math.vec3(0, 0, 0)
  ---@type Vec3
  local b = lurek.math.vec3(10, 10, 10)
  local m = a:lerp(b, 0.5)
  lurek.log.debug("mid.x=" .. m.x, "math")
end

--@api-stub: Vec3:distance
-- Euclidean distance to another Vec3.
-- Plain Euclidean distance between two Vec3.
do  -- Vec3:distance
  ---@type Vec3
  local a = lurek.math.vec3(0, 0, 0)
  ---@type Vec3
  local b = lurek.math.vec3(3, 4, 0)
  lurek.log.info("dist=" .. a:distance(b), "math")
end

--@api-stub: Vec3:add
-- Add another Vec3 and return the result.
-- Returns a new Vec3 — does not mutate self.
do  -- Vec3:add
  ---@type Vec3
  local a = lurek.math.vec3(1, 2, 3)
  ---@type Vec3
  local b = lurek.math.vec3(10, 0, 0)
  local s = a:add(b)
  lurek.log.debug("sum.x=" .. s.x, "math")
end

--@api-stub: Vec3:sub
-- Subtract another Vec3 and return the result.
-- Returns a new Vec3 representing self - other.
do  -- Vec3:sub
  ---@type Vec3
  local a = lurek.math.vec3(5, 5, 5)
  ---@type Vec3
  local b = lurek.math.vec3(1, 2, 3)
  local d = a:sub(b)
  lurek.log.debug("diff.z=" .. d.z, "math")
end

--@api-stub: Vec3:scale
-- Scale this vector by a scalar and return the result.
-- Returns self * scalar without mutating; useful in physics impulse calc.
do  -- Vec3:scale
  ---@type Vec3
  local base = lurek.math.vec3(1, 0, 0)
  local v = base:scale(9.81)
  lurek.log.debug("scaled.x=" .. v.x, "physics")
end

--@api-stub: CatmullRom:sample
-- Sample the spline at global t in [0, 1].
-- t in [0, 1] runs the whole curve; useful for moving an actor along a path.
do  -- CatmullRom:sample
  ---@type CatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=100,y=200},{x=300,y=200},{x=400,y=0}})
  local x, y = cr:sample(0.25)
  lurek.log.debug("sample " .. x .. "," .. y, "spline")
end

--@api-stub: CatmullRom:sampleSegment
-- Sample a specific segment at local t in [0, 1].
-- 0-based segment index; useful when stepping per segment for variable speed.
do  -- CatmullRom:sampleSegment
  ---@type CatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=20},{x=100,y=0},{x=150,y=20}})
  local x, y = cr:sampleSegment(0, 0.5)
  lurek.log.debug("seg0 mid " .. x .. "," .. y, "spline")
end

--@api-stub: CatmullRom:len
-- Number of control points.
-- Returns the control-point count, not arc length; pre-allocate dot arrays from this.
do  -- CatmullRom:len
  ---@type CatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=10,y=10},{x=20,y=0},{x=30,y=10}})
  lurek.log.info("control points=" .. cr:len(), "spline")
end

--@api-stub: CatmullRom:addPoint
-- Appends a control point to the spline.
-- Appends a control point; the curve auto-extends so plan tangent continuity at the join.
do  -- CatmullRom:addPoint
  ---@type CatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=50},{x=100,y=0},{x=150,y=50}})
  cr:addPoint(200, 0)
  lurek.log.debug("after add count=" .. cr:len(), "spline")
end

--@api-stub: CatmullRom:removePoint
-- Removes the control point at `index` (0-based) and returns it.
-- 0-based index; returns the removed (x, y) pair or errors if out of bounds.
do  -- CatmullRom:removePoint
  ---@type CatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=50},{x=100,y=0},{x=150,y=50}})
  local rx, ry = cr:removePoint(1)
  lurek.log.debug("removed " .. rx .. "," .. ry, "spline")
end

--@api-stub: Hermite:sample
-- Evaluate the spline at parameter t in [0, 1].
-- t in [0, 1] traverses the segment; outside that range extrapolates the polynomial.
do  -- Hermite:sample
  ---@type Hermite
  local h = lurek.math.hermite(0, 0, 100, 100, 50, 0, 0, 50)
  local x, y = h:sample(0.5)
  lurek.log.debug("hermite mid " .. x .. "," .. y, "spline")
end

--@api-stub: RandomGenerator:random
-- Returns a uniform random number in [0, 1).
-- Uniform [0,1) — bedrock for everything else; combine with multipliers for ranges.
do  -- RandomGenerator:random
  local rng = lurek.math.newRandomGenerator(42)
  local v = rng:random()
  lurek.log.debug("u01=" .. v, "rng")
end

--@api-stub: RandomGenerator:randomFloat
-- Returns a uniform random float in [min, max).
-- Inclusive lower bound, exclusive upper — matches Python's random.uniform half-open.
do  -- RandomGenerator:randomFloat
  local rng = lurek.math.newRandomGenerator(7)
  local angle = rng:randomFloat(0, math.pi * 2)
  lurek.log.debug("angle=" .. angle, "rng")
end

--@api-stub: RandomGenerator:randomInt
-- Returns a uniform random integer in [min, max].
-- Inclusive on both ends — perfect for d20 rolls and grid coordinates.
do  -- RandomGenerator:randomInt
  local rng = lurek.math.newRandomGenerator(99)
  local roll = rng:randomInt(1, 20)
  lurek.log.info("d20=" .. roll, "rng")
end

--@api-stub: RandomGenerator:getSeed
-- Returns the seed used to initialise this generator.
-- Returns the seed used at construction; useful to log for replay reproduction.
do  -- RandomGenerator:getSeed
  local rng = lurek.math.newRandomGenerator(20260422)
  local seed = rng:getSeed()
  lurek.log.info("rng seed=" .. seed, "rng")
end

--@api-stub: RandomGenerator:setSeed
-- Sets the seed, fully resetting the generator state.
-- Resets internal state — call before deterministic sequences like proc-gen rooms.
do  -- RandomGenerator:setSeed
  local rng = lurek.math.newRandomGenerator(0)
  rng:setSeed(12345)
  lurek.log.debug("after reseed=" .. rng:randomInt(1, 6), "rng")
end

--@api-stub: RandomGenerator:getState
-- Serialises the generator state as a string for later restoration.
-- Returns an opaque string; pair with setState for save/load checkpoints.
do  -- RandomGenerator:getState
  local rng = lurek.math.newRandomGenerator(77)
  local snapshot = rng:getState()
  lurek.log.debug("state bytes=" .. #snapshot, "rng")
end

--@api-stub: RandomGenerator:setState
-- Restores the generator state from a previously serialised string.
-- Restores a previously captured state; enables deterministic re-roll on save load.
do  -- RandomGenerator:setState
  local rng = lurek.math.newRandomGenerator(77)
  local snap = rng:getState()
  rng:random()
  rng:setState(snap)
end

--@api-stub: Transform:translate
-- Applies translation to the transform.
-- Mutates the transform — apply each frame to drift a sprite's local origin.
do  -- Transform:translate
  local t = lurek.math.newTransform()
  t:translate(50, -10)
  lurek.log.debug("translated", "xform")
end

--@api-stub: Transform:rotate
-- Applies a rotation in radians.
-- Angle in radians; rotation is post-multiplied so order with translate matters.
do  -- Transform:rotate
  local t = lurek.math.newTransform()
  t:rotate(math.pi / 4)
  lurek.log.debug("rotated 45deg", "xform")
end

--@api-stub: Transform:scale
-- Applies non-uniform scaling.
-- Pass one arg for uniform scale; two args for non-uniform (sx, sy).
do  -- Transform:scale
  local t = lurek.math.newTransform()
  t:scale(2, 0.5)
  lurek.log.debug("scaled", "xform")
end

--@api-stub: Transform:shear
-- Applies horizontal and vertical shear factors to this transform matrix.
-- Shears the matrix by (kx, ky); rarely used outside of italic-text tricks.
do  -- Transform:shear
  local t = lurek.math.newTransform()
  t:shear(0.2, 0)
  lurek.log.debug("sheared", "xform")
end

--@api-stub: Transform:reset
-- Resets the transform to identity.
-- Drops back to identity — call to recycle a transform across frames without re-allocating.
do  -- Transform:reset
  local t = lurek.math.newTransform(10, 20, 0.5)
  t:reset()
  lurek.log.debug("reset to identity", "xform")
end

--@api-stub: Transform:transformPoint
-- Transforms a point from local space to world space.
-- Goes local -> world; pair with inverseTransformPoint for hit-testing rotated sprites.
do  -- Transform:transformPoint
  local t = lurek.math.newTransform(100, 50, math.pi / 2)
  local wx, wy = t:transformPoint(10, 0)
  lurek.log.debug("world " .. wx .. "," .. wy, "xform")
end

--@api-stub: Transform:inverseTransformPoint
-- Transforms a point from world space back to local space.
-- Goes world -> local; use to convert mouse coords into the sprite's frame.
do  -- Transform:inverseTransformPoint
  local t = lurek.math.newTransform(50, 50, math.pi / 4)
  local lx, ly = t:inverseTransformPoint(100, 50)
  lurek.log.debug("local " .. lx .. "," .. ly, "xform")
end

--@api-stub: Transform:inverse
-- Returns a new Transform that undoes this transform.
-- Returns a fresh inverse Transform; useful to undo a chain of transformations.
do  -- Transform:inverse
  local t = lurek.math.newTransform(10, 20, 0.3)
  local inv = t:inverse()
  lurek.log.debug("got inverse", "xform")
end

--@api-stub: Transform:clone
-- Returns a copy of this transform.
-- Returns a deep copy so the original is not mutated by subsequent ops.
do  -- Transform:clone
  local t = lurek.math.newTransform(10, 20)
  local dup = t:clone()
  dup:translate(5, 0)
end

--@api-stub: Transform:getMatrix
-- Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
-- Flat 9-element row-major table; pass to a custom shader as a uniform.
do  -- Transform:getMatrix
  local t = lurek.math.newTransform(0, 0, math.pi / 2)
  local m = t:getMatrix()
  lurek.log.debug("matrix elems=" .. #m, "xform")
end

--@api-stub: Transform:decompose
-- Decomposes this transform into translation, rotation, and scale.
-- Returns (x, y, angle, sx, sy); handy for serialising a transform back into config.
do  -- Transform:decompose
  local t = lurek.math.newTransform(100, 50, math.pi / 4, 2, 2)
  local x, y, angle, sx, sy = t:decompose()
  lurek.log.info("xform " .. x .. "," .. y .. " a=" .. angle, "xform")
end

--@api-stub: BezierCurve:evaluate
-- Evaluates the curve at parameter t, returning (x, y).
-- Returns (x, y) at parameter t; t may run outside [0,1] but the curve extrapolates.
do  -- BezierCurve:evaluate
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local x, y = c:evaluate(0.25)
  lurek.log.debug("eval " .. x .. "," .. y, "spline")
end

--@api-stub: BezierCurve:render
-- Renders the curve as a polyline with the given number of segments.
-- Returns a polyline as an array of 2-element tables; pass enough segments for visual smoothness.
do  -- BezierCurve:render
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local pts = c:render(32)
  lurek.log.info("polyline points=" .. #pts, "spline")
end

--@api-stub: BezierCurve:getDerivative
-- Returns a new BezierCurve representing the first derivative.
-- Returns a new curve that, when evaluated, gives the tangent vector of the original.
do  -- BezierCurve:getDerivative
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local d = c:getDerivative()
  lurek.log.debug("derivative ready", "spline")
end

--@api-stub: BezierCurve:getControlPoint
-- Returns the control point at 1-based index as (x, y), or nil.
-- 1-based index; returns nil, nil when out of range so guard before use.
do  -- BezierCurve:getControlPoint
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local x, y = c:getControlPoint(2)
  lurek.log.debug("cp2=" .. x .. "," .. y, "spline")
end

--@api-stub: BezierCurve:removeControlPoint
-- Removes a control point at 1-based index.
-- 1-based; returns true on success, false if the index was out of range.
do  -- BezierCurve:removeControlPoint
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local ok = c:removeControlPoint(3)
  lurek.log.debug("removed=" .. tostring(ok), "spline")
end

--@api-stub: BezierCurve:getControlPointCount
-- Returns the number of control points.
-- Useful before iterating control points or when choosing a render segment count.
do  -- BezierCurve:getControlPointCount
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local n = c:getControlPointCount()
  lurek.log.info("cp count=" .. n, "spline")
end

--@api-stub: BezierCurve:length
-- Returns the approximate arc length of the curve.
-- Approximate arc length using internal subdivision; do not call every frame.
do  -- BezierCurve:length
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local len = c:length()
  lurek.log.info("arc len=" .. len, "spline")
end

--@api-stub: BezierCurve:translate
-- Translates all control points by (dx, dy).
-- Mutates by shifting every control point by (dx, dy); use for moving an entire path.
do  -- BezierCurve:translate
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  c:translate(10, 5)
  lurek.log.debug("translated", "spline")
end

--@api-stub: BezierCurve:rotate
-- Rotates all control points around a pivot by angle radians.
-- Rotates around (ox, oy) by angle radians; useful for animating a swung path.
do  -- BezierCurve:rotate
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  c:rotate(math.pi / 6, 0, 0)
  lurek.log.debug("rotated", "spline")
end

--@api-stub: BezierCurve:scale
-- Scales all control points around a pivot by factor s.
-- Scales around (ox, oy) by factor s; combine with translate for arbitrary affine effects.
do  -- BezierCurve:scale
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  c:scale(2.0, 0, 0)
  lurek.log.debug("scaled", "spline")
end

--@api-stub: Tween:update
-- Advances the clock by dt seconds.
-- Returns true on the frame the tween completes — chain follow-ups from that.
do  -- Tween:update
  local tw = lurek.math.newTween(1.0, "outQuad")
  function lurek.process(dt)
    if tw:update(dt) then lurek.log.info("done", "tween") end
  end
end

--@api-stub: Tween:reset
-- Resets the tween elapsed time to zero, restarting the animation.
-- Re-runs the same animation from t=0; call on respawn or animation loop.
do  -- Tween:reset
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 100)
  tw:reset()
end

--@api-stub: Tween:getValue
-- Returns the interpolated value at 1-based index, or all values as a.
-- Pass nil for a list of all values, or 1-based index for a single one.
do  -- Tween:getValue
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 200)
  local v = tw:getValue(1)
  lurek.log.debug("value=" .. v, "tween")
end

--@api-stub: Tween:getAllValues
-- Returns all interpolated values as a table.
-- Returns a flat table; useful when binding many properties to one shared clock.
do  -- Tween:getAllValues
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 1)
  local all = tw:getAllValues()
  lurek.log.debug("count=" .. #all, "tween")
end

--@api-stub: Tween:isComplete
-- Returns true if the tween has finished.
-- Branch on this to enable a button or trigger a follow-up animation.
do  -- Tween:isComplete
  local tw = lurek.math.newTween(0.2)
  if tw:isComplete() then
    lurek.log.debug("ready", "tween")
  end
end

--@api-stub: Tween:getValueCount
-- Returns the number of values in this tween.
-- Returns the number of (start, target) pairs added; pre-iterate before getValue.
do  -- Tween:getValueCount
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 10)
  lurek.log.info("count=" .. tw:getValueCount(), "tween")
end

--@api-stub: Tween:getEasingName
-- Returns the easing function name.
-- Returns the easing string passed to newTween — useful in debug overlays.
do  -- Tween:getEasingName
  local tw = lurek.math.newTween(0.5, "outBack")
  lurek.log.debug("easing=" .. tw:getEasingName(), "tween")
end

--@api-stub: Tween:getDuration
-- Returns the tween duration in seconds.
-- Returns the duration in seconds; pair with getTime to compute progress percentage.
do  -- Tween:getDuration
  local tw = lurek.math.newTween(2.5)
  lurek.log.info("duration=" .. tw:getDuration(), "tween")
end

--@api-stub: Tween:getTime
-- Returns the current clock time.
-- Returns elapsed seconds clamped to duration; divide to get [0, 1] progress.
do  -- Tween:getTime
  local tw = lurek.math.newTween(1.0)
  local pct = tw:getTime() / tw:getDuration()
  lurek.log.debug("pct=" .. pct, "tween")
end

--@api-stub: Tween:getClock
-- Alias for getTime().
-- Alias of getTime() preserved for older scripts.
do  -- Tween:getClock
  local tw = lurek.math.newTween(1.0)
  local now = tw:getClock()
  lurek.log.debug("now=" .. now, "tween")
end

--@api-stub: Tween:setTime
-- Sets the clock to a specific time, clamped to [0, duration].
-- Hard-seek the clock; useful for timeline scrubbers in editors.
do  -- Tween:setTime
  local tw = lurek.math.newTween(1.0)
  tw:setTime(0.5)
  lurek.log.debug("seeked to 0.5", "tween")
end

--@api-stub: Tween:set
-- Alias for setTime().
-- Alias for setTime; both clamp into [0, duration].
do  -- Tween:set
  local tw = lurek.math.newTween(1.0)
  tw:set(0.25)
  lurek.log.debug("clock set", "tween")
end

--@api-stub: Tween:addValue
-- Adds a start/target value pair.
-- Adds a (start, target) pair and returns the 1-based index for later getValue.
do  -- Tween:addValue
  local tw = lurek.math.newTween(0.5, "outQuad")
  local idx = tw:addValue(0, 200)
  lurek.log.info("value idx=" .. idx, "tween")
end

--@api-stub: SpatialHash:remove
-- Removes an item by its ID.
-- Pair every insert with a remove on entity death so stale ids do not leak into queries.
do  -- SpatialHash:remove
  local h = lurek.math.newSpatialHash(64)
  h:insert("npc", 0, 0, 32, 32)
  h:remove("npc")
end

--@api-stub: SpatialHash:clear
-- Removes all registered items from this spatial hash, leaving it empty.
-- Drops every entry — useful at scene transitions to start with a fresh grid.
do  -- SpatialHash:clear
  local h = lurek.math.newSpatialHash(64)
  h:insert("a", 0, 0, 16, 16)
  h:clear()
end

--@api-stub: SpatialHash:getCellSize
-- Returns the cell size used to partition the spatial hash grid.
-- Echo back the cell size so debug HUDs can align grid lines without external storage.
do  -- SpatialHash:getCellSize
  local h = lurek.math.newSpatialHash(96)
  local cs = h:getCellSize()
  lurek.log.debug("cell=" .. cs, "spatial")
end

--@api-stub: SpatialHash:getItemCount
-- Returns the number of items in the hash.
-- Cheap occupancy meter; helpful when tuning cell size against entity density.
do  -- SpatialHash:getItemCount
  local h = lurek.math.newSpatialHash(64)
  h:insert("a", 0, 0, 16, 16)
  lurek.log.info("items=" .. h:getItemCount(), "spatial")
end

--@api-stub: NoiseGenerator:perlin1d
-- Returns 1D Perlin noise at x.
-- Use 1D for animating a single varying parameter like wind strength over time.
do  -- NoiseGenerator:perlin1d
  local n = lurek.math.newNoiseGenerator(1)
  local wind = n:perlin1d(0.4)
  lurek.log.debug("wind=" .. wind, "weather")
end

--@api-stub: NoiseGenerator:perlin2d
-- Returns 2D Perlin noise at (x, y).
-- Standard terrain Perlin; same seed always returns same result for a given (x, y).
do  -- NoiseGenerator:perlin2d
  local n = lurek.math.newNoiseGenerator(2)
  local h = n:perlin2d(2.5, 4.5)
  lurek.log.debug("h=" .. h, "noise")
end

--@api-stub: NoiseGenerator:perlin3d
-- Returns 3D Perlin noise at (x, y, z).
-- Use the third axis for time to seamlessly animate a noise field.
do  -- NoiseGenerator:perlin3d
  local n = lurek.math.newNoiseGenerator(3)
  local v = n:perlin3d(1.0, 2.0, 3.0)
  lurek.log.debug("v=" .. v, "noise")
end

--@api-stub: NoiseGenerator:perlin4d
-- Returns 4D Perlin noise at (x, y, z, w).
-- Useful for tiling 3D textures or for noise that animates AND wraps.
do  -- NoiseGenerator:perlin4d
  local n = lurek.math.newNoiseGenerator(4)
  local v = n:perlin4d(0.1, 0.2, 0.3, 0.4)
  lurek.log.debug("v4=" .. v, "noise")
end

--@api-stub: NoiseGenerator:simplex1d
-- Returns 1D Simplex noise at x.
-- Faster 1D variant; great for animating a single ambient parameter.
do  -- NoiseGenerator:simplex1d
  local n = lurek.math.newNoiseGenerator(5)
  local s = n:simplex1d(0.7)
  lurek.log.debug("s1=" .. s, "noise")
end

--@api-stub: NoiseGenerator:simplex2d
-- Returns 2D Simplex noise at (x, y).
-- Faster than perlin2d with fewer directional artefacts; preferred for organic shapes.
do  -- NoiseGenerator:simplex2d
  local n = lurek.math.newNoiseGenerator(6)
  local s = n:simplex2d(0.4, 0.6)
  lurek.log.debug("s2=" .. s, "noise")
end

--@api-stub: NoiseGenerator:simplex3d
-- Returns 3D Simplex noise at (x, y, z).
-- Use the z dimension for time when you want isotropic 2D animation.
do  -- NoiseGenerator:simplex3d
  local n = lurek.math.newNoiseGenerator(7)
  local s = n:simplex3d(0.1, 0.2, 0.3)
  lurek.log.debug("s3=" .. s, "noise")
end

--@api-stub: NoiseGenerator:getSeed
-- Returns the current seed.
-- Echoes back the active seed; useful for logging deterministic worlds.
do  -- NoiseGenerator:getSeed
  local n = lurek.math.newNoiseGenerator(2026)
  lurek.log.info("noise seed=" .. n:getSeed(), "noise")
end

--@api-stub: NoiseGenerator:setSeed
-- Sets the seed and rebuilds the permutation table.
-- Re-seeds AND rebuilds the permutation table — costlier than a number assignment.
do  -- NoiseGenerator:setSeed
  local n = lurek.math.newNoiseGenerator(0)
  n:setSeed(99)
  lurek.log.debug("re-seeded", "noise")
end

--@api-stub: Circle:area
-- Returns the area of the circle (π r²).
-- Returns pi * r^2; useful when comparing influence radii of abilities.
do  -- Circle:area
  local c = lurek.math.newCircle(0, 0, 5)
  lurek.log.debug("area=" .. c:area(), "geo")
end

--@api-stub: Circle:perimeter
-- Returns the circumference of the circle (2 π r).
-- Returns 2 * pi * r; useful when computing the loop length of a ring path.
do  -- Circle:perimeter
  local c = lurek.math.newCircle(0, 0, 10)
  lurek.log.debug("perimeter=" .. c:perimeter(), "geo")
end

--@api-stub: Circle:contains
-- Returns true if the point (px, py) lies inside or on the boundary.
-- Inclusive of the boundary — a point exactly on the rim returns true.
do  -- Circle:contains
  local c = lurek.math.newCircle(50, 50, 25)
  if c:contains(60, 60) then
    lurek.log.debug("inside", "geo")
  end
end

--@api-stub: Circle:intersects
-- Returns true if this circle overlaps another circle.
-- Pass another Circle; equivalent to circleIntersectsCircle but operates on userdata.
do  -- Circle:intersects
  local a = lurek.math.newCircle(0, 0, 10)
  local b = lurek.math.newCircle(15, 0, 10)
  lurek.log.debug("hit=" .. tostring(a:intersects(b)), "geo")
end

--@api-stub: Circle:aabb
-- Returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y).
-- Returns (min_x, min_y, max_x, max_y); convenient for feeding broad-phase trees.
do  -- Circle:aabb
  local c = lurek.math.newCircle(50, 30, 10)
  local x1, y1, x2, y2 = c:aabb()
  lurek.log.debug("aabb " .. x1 .. "," .. y1 .. " to " .. x2 .. "," .. y2, "geo")
end

--@api-stub: Circle:x
-- Returns the circle centre X.
-- Returns the centre X coord; mirrors Circle.x field for code that prefers methods.
do  -- Circle:x
  local c = lurek.math.newCircle(72, 18, 5)
  lurek.log.debug("x=" .. c:x(), "geo")
end

--@api-stub: Circle:y
-- Returns the circle centre Y.
-- Returns the centre Y coord; pairs with :x().
do  -- Circle:y
  local c = lurek.math.newCircle(72, 18, 5)
  lurek.log.debug("y=" .. c:y(), "geo")
end

--@api-stub: Circle:radius
-- Returns the circle radius.
-- Returns the radius value; clamped to 0 if negative was passed at construction.
do  -- Circle:radius
  local c = lurek.math.newCircle(0, 0, 12)
  lurek.log.info("radius=" .. c:radius(), "geo")
end

--@api-stub: AabbTree:remove
-- Removes the entry with the given id.
-- Returns true if the id existed; pair every insert with a remove on entity destruction.
do  -- AabbTree:remove
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 32, 32)
  local ok = t:remove(1)
  lurek.log.debug("removed=" .. tostring(ok), "physics")
end

--@api-stub: AabbTree:queryPoint
-- Returns the ids of all entries whose AABBs contain the given point.
-- Returns ids of every AABB containing the point; iterate to drive hover detection.
do  -- AabbTree:queryPoint
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 32, 32)
  local ids = t:queryPoint(10, 10)
  lurek.log.info("hits=" .. #ids, "physics")
end

--@api-stub: AabbTree:contains
-- Returns true if an entry with the given id exists in the tree.
-- Cheap presence test; faster than a full query when you only need 'does this id exist?'.
do  -- AabbTree:contains
  local t = lurek.math.aabbTree()
  t:insert(42, 0, 0, 16, 16)
  if t:contains(42) then
    lurek.log.debug("entry exists", "physics")
  end
end

--@api-stub: AabbTree:len
-- Returns the number of entries in the tree.
-- Returns the number of entries; useful for a debug HUD entity counter.
do  -- AabbTree:len
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 8, 8)
  lurek.log.info("aabb tree size=" .. t:len(), "physics")
end

--@api-stub: AabbTree:isEmpty
-- Returns true if the tree contains no entries.
-- Branch on isEmpty() before iterating to avoid setting up unused query state.
do  -- AabbTree:isEmpty
  local t = lurek.math.aabbTree()
  if t:isEmpty() then
    lurek.log.debug("tree empty", "physics")
  end
end

--@api-stub: AabbTree:clear
-- Removes all entries from the tree.
-- Drops every entry; call between scenes to reset broad-phase data.
do  -- AabbTree:clear
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 16, 16)
  t:clear()
end

--@api-stub: NoiseGenerator:fbm
-- Generates fractional Brownian motion noise at (x, y) using multiple octaves.
-- octaves, lacunarity, and gain control detail, frequency growth, and amplitude decay.
do  -- NoiseGenerator:fbm
  local ng = lurek.math.newNoiseGenerator(42)
  local v = ng:fbm(0.3, 0.7, 6, 2.0, 0.5)
  lurek.log.info("fbm noise: " .. v, "math")
end

--@api-stub: NoiseGenerator:generateMap
-- Generates a 2D noise map into a flat table of width*height floats.
-- scale controls zoom; offsets shift the sample window across the noise field.
do  -- NoiseGenerator:generateMap
  local ng = lurek.math.newNoiseGenerator(99)
  local map = ng:generateMap(32, 32, { scale = 0.05, offsetX = 0.0, offsetY = 0.0 })
  lurek.log.info("map size: " .. #map, "math")
end

--@api-stub: SpatialHash:insert
-- Inserts an item with a bounding rectangle into the spatial hash.
-- item can be any value (entity id, table); duplicate inserts accumulate.
do  -- SpatialHash:insert
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("entity_01", 100, 100, 32, 32)
  sh:insert("entity_02", 200, 150, 32, 32)
  lurek.log.info("items: " .. sh:getItemCount(), "math")
end

--@api-stub: AabbTree:insert
-- Inserts an axis-aligned bounding box into the dynamic AABB tree.
-- Returns a proxy id for later update() or remove() calls.
do  -- AabbTree:insert
  local tree = lurek.math.aabbTree()
  tree:insert(1, 10, 10, 50, 50)
  tree:insert(2, 80, 80, 120, 120)
  lurek.log.info("tree len: " .. tree:len(), "math")
end

--@api-stub: BezierCurve:insertControlPoint
-- Inserts a new control point at the given parameter t along the curve.
-- The curve order increases by 1; use for interactive path editing.
do  -- BezierCurve:insertControlPoint
  local bc = lurek.math.newBezierCurve({0,0, 100,50, 200,0})
  bc:insertControlPoint(100, 25, 0.5)
  lurek.log.info("ctrl pts: " .. bc:getControlPointCount(), "math")
end

--@api-stub: AabbTree:query
-- Returns all proxies whose bounding boxes overlap the given AABB query rectangle.
-- Result is a table of user-data values passed to insert().
do  -- AabbTree:query
  local tree = lurek.math.aabbTree()
  tree:insert(1, 0, 0, 40, 40)
  tree:insert(2, 60, 60, 100, 100)
  local hits = tree:query(10, 10, 50, 50)
  lurek.log.info("hits: " .. #hits, "math")
end

--@api-stub: SpatialHash:queryCircle
-- Returns all items whose AABB overlaps a circle with given centre and radius.
-- Faster than a broad-phase distance check for sparse grids of large objects.
do  -- SpatialHash:queryCircle
  local sh = lurek.math.newSpatialHash(32)
  sh:insert("e1", 100, 100, 16, 16)
  sh:insert("e2", 500, 500, 16, 16)
  local hits = sh:queryCircle(110, 110, 50)
  lurek.log.info("circle hits: " .. #hits, "math")
end

--@api-stub: SpatialHash:queryRect
-- Returns all items whose bounding rectangles overlap the query AABB.
-- Use for broad-phase collision detection before narrow-phase checks.
do  -- SpatialHash:queryRect
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("player", 100, 100, 32, 32)
  sh:insert("enemy", 128, 100, 32, 32)
  local hits = sh:queryRect(90, 90, 170, 150)
  lurek.log.info("rect hits: " .. #hits, "math")
end

--@api-stub: SpatialHash:querySegment
-- Returns all items whose bounding rectangles are crossed by a line segment.
-- Use for bullet-traces, line-of-sight culling, and ray-vs-entity checks.
do  -- SpatialHash:querySegment
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("wall", 200, 100, 240, 300)
  local hits = sh:querySegment(0, 200, 400, 200)
  lurek.log.info("segment hits: " .. #hits, "math")
end

--@api-stub: RandomGenerator:randomNormal
-- Returns a normally-distributed random float with the given mean and stddev.
-- Uses the Box-Muller transform; negative values are possible.
do  -- RandomGenerator:randomNormal
  local rng = lurek.math.newRandomGenerator(12345)
  local v = rng:randomNormal(0, 1)
  lurek.log.info("normal sample: " .. v, "math")
end

--@api-stub: NoiseGenerator:ridged
-- Returns ridged multifractal noise value at (x, y); ridge lines appear as sharp peaks.
-- Useful for mountain ranges, lightning bolt textures, and cracks.
do  -- NoiseGenerator:ridged
  local ng = lurek.math.newNoiseGenerator(7)
  local v = ng:ridged(0.5, 0.5, 5, 2.0, 0.5)
  lurek.log.info("ridged: " .. v, "math")
end

--@api-stub: BezierCurve:setControlPoint
-- Moves the control point at the given index to a new (x, y) position.
-- Index is 1-based; changes the curve shape without altering the degree.
do  -- BezierCurve:setControlPoint
  local bc = lurek.math.newBezierCurve({0,0, 100,0, 200,0})
  bc:setControlPoint(2, 100, 80)
  local cx, cy = bc:getControlPoint(2)
  lurek.log.info("ctrl pt 2: " .. cx .. "," .. cy, "math")
end

--@api-stub: Transform:setTransformation
-- Resets and sets all transformation parameters (tx,ty, r, sx,sy, ox,oy, kx,ky).
-- Equivalent to reset() + translate() + rotate() + scale() in one call.
do  -- Transform:setTransformation
  local t = lurek.math.newTransform()
  t:setTransformation(100, 200, 0.5, 2.0, 2.0, 16, 16, 0, 0)
  local x, y = t:transformPoint(0, 0)
  lurek.log.info("transformed origin: " .. x .. "," .. y, "math")
end

--@api-stub: NoiseGenerator:turbulence
-- Returns turbulence noise: sum of |perlin(x*f^i, y*f^i)| across octaves.
-- Produces cloudy, billowing textures suitable for fog or smoke.
do  -- NoiseGenerator:turbulence
  local ng = lurek.math.newNoiseGenerator(55)
  local v = ng:turbulence(0.4, 0.6, 5, 2.0, 0.5)
  lurek.log.info("turbulence: " .. v, "math")
end

--@api-stub: Tween:update
-- Advances the tween by dt seconds and returns the current interpolated value.
-- Call each frame; tween reports isComplete() = true when it reaches the end.
do  -- Tween:update
  local tw = lurek.math.newTween(1.0, "inOutQuad")
  tw:addValue(0, 200)
  tw:update(0.5)
  lurek.log.info("x at t=0.5: " .. tw:getValue(1), "math")
end

--@api-stub: SpatialHash:update
-- Updates the stored AABB for an item already in the hash.
-- Must be called each frame for moving objects to keep queries accurate.
do  -- SpatialHash:update
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("player", 100, 100, 32, 32)
  sh:update("player", 110, 105, 32, 32)
  lurek.log.info("player position updated", "math")
end

--@api-stub: NoiseGenerator:warpDomain
-- Returns domain-warped noise by distorting (x,y) with a secondary noise field.
-- Produces swirling, organic shapes; warp_scale controls the distortion magnitude.
do  -- NoiseGenerator:warpDomain
  local ng = lurek.math.newNoiseGenerator(101)
  local wx, wy = ng:warpDomain(0.3, 0.3, 0.8)
  wx = wx or 0.0
  wy = wy or 0.0
  local v = ng:perlin2d(wx, wy)
  lurek.log.info("warped: " .. v, "math")
end

--@api-stub: NoiseGenerator:worley2d
-- Returns the 2D Worley (cellular) noise F1 distance at (x, y).
-- Lower values near cell centres; use for stone textures, voronoi patterns.
do  -- NoiseGenerator:worley2d
  local ng = lurek.math.newNoiseGenerator(321)
  local v = ng:worley2d(0.25, 0.75)
  lurek.log.info("worley2d: " .. v, "math")
end

--@api-stub: NoiseGenerator:worley3d
-- Returns the 3D Worley (cellular) noise F1 distance at (x, y, z).
-- Use for volumetric textures, animated flowing patterns, or fog density fields.
do  -- NoiseGenerator:worley3d
  local ng = lurek.math.newNoiseGenerator(654)
  local v = ng:worley3d(0.1, 0.5, 0.9)
  lurek.log.info("worley3d: " .. v, "math")
end

--@api-stub: AabbTree:update
-- Advances the dynamic bounding-volume tree, refreshing moved body bounds.
-- Call once per frame after updating body positions to maintain query accuracy.
do  -- AabbTree:update
  local tree = lurek.math.aabbTree()
  local id = 1
  tree:insert(id, 100, 100, 132, 132)
  tree:update(id, 110, 110, 142, 142)
  lurek.log.info("AABB tree updated", "math")
end
