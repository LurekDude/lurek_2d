-- content/examples/math.lua
-- Comprehensive lurek.math API examples: vectors, transforms, noise, easing, geometry, and more.
-- Run: cargo run -- content/examples/math.lua

--@api-stub: lurek.math.newRandomGenerator
-- Creates a deterministic random generator with an optional seed
do
  -- Seeded RNG gives repeatable results across runs — essential for replays,
  -- procedural generation, and deterministic testing.
  local rng = lurek.math.newRandomGenerator(1337)
  -- Roll a loot drop between 1 and 100
  local loot_roll = rng:randomInt(1, 100)
  lurek.log.info("loot roll=" .. loot_roll, "rng")
  -- Same seed always produces the same sequence
  local rng2 = lurek.math.newRandomGenerator(1337)
  local same_roll = rng2:randomInt(1, 100)
  lurek.log.debug("same seed same roll=" .. same_roll, "rng")
end

--@api-stub: lurek.math.newTransform
-- Creates a 2D transform
do
  -- A transform encapsulates translation, rotation, and scale into a single matrix.
  -- Useful for positioning sprites, cameras, and hierarchical scene objects.
  -- Args: x, y, angle (radians), scaleX, scaleY
  local t = lurek.math.newTransform(100, 50, math.pi / 4, 2, 2)
  -- Transform a local-space point into world-space
  local wx, wy = t:transformPoint(8, 0)
  lurek.log.debug("rotated corner at " .. wx .. "," .. wy, "xform")
end

--@api-stub: lurek.math.newBezierCurve
-- Creates a Bezier curve from a flat point table
do
  -- Flat table format: {x1,y1, x2,y2, x3,y3, x4,y4}
  -- Bezier curves are great for smooth paths, projectile arcs, and UI animations.
  local curve = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  -- evaluate(t) samples the curve at normalized t in [0..1]
  local mid_x, mid_y = curve:evaluate(0.5)
  -- evaluateAtDistance gives a point at an arc-length distance (more uniform spacing)
  local d_x, d_y = curve:evaluateAtDistance(120)
  lurek.log.info("bezier midpoint " .. mid_x .. "," .. mid_y, "anim")
  lurek.log.debug("bezier distance sample " .. d_x .. "," .. d_y, "anim")
end

--@api-stub: lurek.math.newTween
-- Creates a tween with a duration and optional easing name
do
  -- Tweens interpolate values over time with easing.
  -- Useful for UI animations, camera transitions, health bar changes.
  local tw = lurek.math.newTween(0.5, "outQuad")
  -- addValue defines a track: start=0, target=200
  tw:addValue(0, 200)
  -- In a real game loop, call tw:update(dt) each frame
  function lurek.process(dt) tw:update(dt) end
end

--@api-stub: lurek.math.newSpatialHash
-- Creates a spatial hash index with a cell size
do
  -- Spatial hashing divides the world into a grid for fast broad-phase queries.
  -- Cell size should be close to the average entity size for best performance.
  local hash = lurek.math.newSpatialHash(64)
  -- Insert entities with id, x, y, width, height
  hash:insert("player", 100, 100, 32, 32)
  hash:insert("enemy", 130, 110, 32, 32)
  -- Query all entities within a circle (center + radius)
  local hits = hash:queryCircle(110, 110, 50)
  lurek.log.debug("nearby entities=" .. #hits, "spatial")
end

--@api-stub: lurek.math.newNoiseGenerator
-- Creates a procedural noise generator with an optional seed
do
  -- Noise generators produce coherent random values for terrain, clouds, textures.
  -- The seed makes output deterministic across runs.
  local terrain = lurek.math.newNoiseGenerator(20260422)
  -- perlin2d returns smooth noise in roughly [-1..1] range
  local h = terrain:perlin2d(3.5, 7.25)
  -- generateMapCompute produces a flat array of noise values (GPU-accelerated)
  local map = terrain:generateMapCompute(16, 16, {octaves = 3})
  lurek.log.debug("terrain h=" .. h, "noise")
  lurek.log.debug("terrain map samples=" .. #map, "noise")
end

--@api-stub: lurek.math.newRectPacker
-- Creates a rectangle packer
do
  -- Rectangle packing places sprites into a texture atlas with minimal waste.
  -- Args: atlas width, atlas height, padding between rects
  local packer = lurek.math.newRectPacker(256, 256, 2)
  -- pack(width, height, id) returns top-left position or nil if it does not fit
  local x, y = packer:pack(64, 64, "hero")
  lurek.log.info("packed hero at " .. tostring(x) .. "," .. tostring(y), "atlas")
end

--@api-stub: LRectPacker:pack
-- Performs the pack operation on this rect packer.
do
  -- pack returns nil,nil if the rectangle does not fit in the remaining space
  local packer = lurek.math.newRectPacker(128, 128, 2)
  local x, y = packer:pack(32, 24, "btn_ok")
  if x and y then
    lurek.log.debug("packed btn_ok at " .. x .. "," .. y, "atlas")
  else
    lurek.log.warn("btn_ok did not fit!", "atlas")
  end
end

--@api-stub: LRectPacker:getPacked
-- Returns the packed of this rect packer.
do
  -- getPacked returns all successfully placed rects with their coordinates
  local packer = lurek.math.newRectPacker(128, 128, 2)
  packer:pack(20, 20, "icon_a")
  packer:pack(30, 18, "icon_b")
  local packed = packer:getPacked()
  -- Each entry has x, y, w, h, and optional id fields
  lurek.log.debug("packed count=" .. #packed, "atlas")
end

--@api-stub: LRectPacker:occupancy
-- Performs the occupancy operation on this rect packer.
do
  -- occupancy() returns the ratio of used space (0..1)
  -- Useful for deciding when to allocate a new atlas page
  local packer = lurek.math.newRectPacker(128, 128, 2)
  packer:pack(32, 32, "slot1")
  local occ = packer:occupancy()
  lurek.log.debug("occupancy=" .. occ, "atlas")
end

--@api-stub: LAabbTree:clear
-- Clears all items from this rect packer.
do
  -- Resets the packer so you can reuse it for a new atlas layout pass
  local packer = lurek.math.newRectPacker(128, 128, 2)
  packer:pack(40, 16, "tmp")
  packer:clear()
  lurek.log.debug("atlas cleared", "atlas")
end

--@api-stub: LNoiseGenerator:perlin2d
-- Samples stateless 2D Perlin noise
do
  -- Stateless version: no generator object needed, pass seed directly.
  -- Good for one-off samples or shader-like usage.
  local n = lurek.math.perlin2d(0.5, 1.25, 42)
  if n > 0.6 then
    lurek.log.info("hill peak", "terrain")
  end
end

--@api-stub: LNoiseGenerator:perlin3d
-- Samples stateless 3D Perlin noise
do
  -- 3D Perlin: the Z axis can be time for animated effects like clouds or water
  local t = 0
  function lurek.process(dt)
    t = t + dt
    -- Scroll through noise space over time for animated cloud density
    local cloud = lurek.math.perlin3d(0.1, 0.2, t, 7)
    lurek.log.debug("cloud=" .. cloud, "sky")
  end
end

--@api-stub: LNoiseGenerator:simplex2d
-- Samples stateless 2D simplex noise
do
  -- Simplex noise has fewer directional artifacts than Perlin and is slightly faster
  local s = lurek.math.simplex2d(2.0, 3.0, 99)
  if s > 0 then
    lurek.log.debug("simplex above zero", "noise")
  end
end

--@api-stub: LNoiseGenerator:fbm
-- Samples stateless fractal Brownian motion noise
do
  -- FBM layers multiple octaves of noise for natural-looking detail.
  -- Args: x, y, seed, octaves, lacunarity (frequency multiplier), gain (amplitude decay)
  -- More octaves = more detail but slower.
  local h = lurek.math.fbm(4.5, 2.0, 12345, 6, 2.0, 0.5)
  local altitude = math.floor(h * 1000)
  lurek.log.info("fbm altitude=" .. altitude, "world")
end

--@api-stub: lurek.math.applyEasing
-- Applies a named easing function to a normalized value
do
  -- applyEasing lets you select easing by name at runtime (from config or UI).
  -- t must be in [0..1]. Returns eased value, typically also in [0..1].
  local name = "outBounce"
  local eased = lurek.math.applyEasing(name, 0.75)
  lurek.log.debug(name .. "(0.75)=" .. eased, "tween")
end

--@api-stub: lurek.math.linear
-- Applies linear easing
do
  -- Linear: no acceleration. Output equals input.
  local t = 0.42
  local v = lurek.math.linear(t)
  lurek.log.debug("linear " .. t .. "=" .. v, "easing")
end

--@api-stub: lurek.math.inQuad
-- Applies quadratic ease-in
do
  -- inQuad: starts slow, accelerates. Good for objects starting to fall.
  local progress = 0.3
  -- Multiply eased value by travel distance for pixel position
  local y = lurek.math.inQuad(progress) * 200
  lurek.log.debug("falling y=" .. y, "anim")
end

--@api-stub: lurek.math.outQuad
-- Applies quadratic ease-out
do
  -- outQuad: fast start, decelerates. Good for UI panels sliding into place.
  local x = lurek.math.outQuad(0.6) * 480
  lurek.log.debug("panel x=" .. x, "ui")
end

--@api-stub: lurek.math.inOutQuad
-- Applies quadratic ease-in-out
do
  -- inOutQuad: smooth start and end. Good for camera transitions.
  local t = 0.5
  local cam_x = 100 + lurek.math.inOutQuad(t) * 400
  lurek.log.debug("cam x=" .. cam_x, "cam")
end

--@api-stub: lurek.math.inCubic
-- Applies cubic ease-in
do
  -- inCubic: stronger acceleration than inQuad. Good for charge-up effects.
  local charge = lurek.math.inCubic(0.4)
  if charge > 0.5 then
    lurek.log.info("charge ready", "combat")
  end
end

--@api-stub: lurek.math.outCubic
-- Applies cubic ease-out
do
  -- outCubic: fast deceleration. Good for tooltip fade-in.
  local opacity = lurek.math.outCubic(0.8)
  lurek.log.debug("tooltip alpha=" .. opacity, "ui")
end

--@api-stub: lurek.math.inOutCubic
-- Applies cubic ease-in-out
do
  -- inOutCubic: smoother than inOutQuad, good for cinematic movements
  local t = lurek.math.inOutCubic(0.25)
  local panel_y = 600 - t * 400
  lurek.log.debug("panel y=" .. panel_y, "ui")
end

--@api-stub: lurek.math.inQuart
-- Applies quartic ease-in
do
  -- inQuart: even more aggressive than cubic. Good for dramatic acceleration.
  local v = lurek.math.inQuart(0.7)
  lurek.log.debug("inQuart=" .. v, "easing")
end

--@api-stub: lurek.math.outQuart
-- Applies quartic ease-out
do
  -- outQuart: very rapid deceleration at the end
  local v = lurek.math.outQuart(0.2)
  lurek.log.debug("outQuart=" .. v, "easing")
end

--@api-stub: lurek.math.inOutQuart
-- Applies quartic ease-in-out
do
  -- inOutQuart: very flat at ends, steep in middle
  local v = lurek.math.inOutQuart(0.5)
  lurek.log.debug("inOutQuart=" .. v, "easing")
end

--@api-stub: lurek.math.inSine
-- Applies sine ease-in
do
  -- inSine: gentle start based on sine curve. Good for heartbeat or pulse effects.
  local pulse = lurek.math.inSine(0.4)
  lurek.log.debug("pulse=" .. pulse, "fx")
end

--@api-stub: lurek.math.outSine
-- Applies sine ease-out
do
  -- outSine: gentle deceleration. Good for icon fade-in.
  local v = lurek.math.outSine(0.6)
  lurek.log.debug("icon alpha=" .. v, "ui")
end

--@api-stub: lurek.math.inOutSine
-- Applies sine ease-in-out
do
  -- inOutSine: smooth oscillation feel, like a pendulum
  local v = lurek.math.inOutSine(0.5)
  lurek.log.debug("drift=" .. v, "bg")
end

--@api-stub: lurek.math.inExpo
-- Applies exponential ease-in
do
  -- inExpo: nearly flat at start, explosive at end. Good for explosions building up.
  local v = lurek.math.inExpo(0.85)
  lurek.log.debug("inExpo=" .. v, "fx")
end

--@api-stub: lurek.math.outExpo
-- Applies exponential ease-out
do
  -- outExpo: extremely fast start, then asymptotically approaches 1
  local v = lurek.math.outExpo(0.15)
  lurek.log.debug("outExpo=" .. v, "fx")
end

--@api-stub: lurek.math.inOutExpo
-- Applies exponential ease-in-out
do
  -- inOutExpo: dramatic pause at start and end, very steep middle
  local v = lurek.math.inOutExpo(0.5)
  lurek.log.debug("inOutExpo=" .. v, "fx")
end

--@api-stub: lurek.math.inElastic
-- Applies elastic ease-in
do
  -- inElastic: overshoots with spring-like oscillation. Good for wind-up effects.
  local v = lurek.math.inElastic(0.8)
  lurek.log.debug("inElastic=" .. v, "anim")
end

--@api-stub: lurek.math.outElastic
-- Applies elastic ease-out
do
  -- outElastic: bouncy overshoot at the end. Good for button pop-in.
  local v = lurek.math.outElastic(0.6)
  lurek.log.debug("button bounce=" .. v, "ui")
end

--@api-stub: lurek.math.outBounce
-- Applies bounce ease-out
do
  -- outBounce: simulates a ball bouncing to rest. Good for item drops.
  local h = lurek.math.outBounce(0.3) * 100
  lurek.log.debug("bounce h=" .. h, "fx")
end

--@api-stub: lurek.math.inBounce
-- Applies bounce ease-in
do
  -- inBounce: reverse bounce, builds up before settling
  local v = lurek.math.inBounce(0.7)
  lurek.log.debug("inBounce=" .. v, "fx")
end

--@api-stub: lurek.math.inBack
-- Applies back ease-in
do
  -- inBack: pulls back slightly before moving forward (like a slingshot wind-up)
  local v = lurek.math.inBack(0.5)
  lurek.log.debug("inBack=" .. v, "ui")
end

--@api-stub: lurek.math.outBack
-- Applies back ease-out
do
  -- outBack: overshoots target then settles back. Good for menu items popping in.
  local v = lurek.math.outBack(0.5)
  lurek.log.debug("outBack=" .. v, "ui")
end

--@api-stub: lurek.math.inOutElastic
-- Applies elastic ease-in-out
do
  -- inOutElastic: elastic spring at both ends. Use sparingly — very dramatic.
  local v = lurek.math.inOutElastic(0.4)
  lurek.log.debug("inOutElastic=" .. v, "fx")
end

--@api-stub: lurek.math.inOutBounce
-- Applies bounce ease-in-out
do
  -- inOutBounce: bounces at start and end. Good for attention-grabbing effects.
  local v = lurek.math.inOutBounce(0.5)
  lurek.log.debug("inOutBounce=" .. v, "fx")
end

--@api-stub: lurek.math.inOutBack
-- Applies back ease-in-out
do
  -- inOutBack: pulls back at start, overshoots at end, then settles
  local v = lurek.math.inOutBack(0.5)
  lurek.log.debug("inOutBack=" .. v, "fx")
end

--@api-stub: lurek.math.triangulate
-- Triangulates a flat polygon point table
do
  -- Breaks a polygon into triangles for rendering or physics decomposition.
  -- Input: flat table {x1,y1, x2,y2, ...} with at least 3 points.
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local tris = lurek.math.triangulate(poly)
  lurek.log.info("triangulated into " .. #tris .. " triangles", "geo")
end

--@api-stub: lurek.math.isConvex
-- Returns whether a flat polygon point table is convex
do
  -- Convex polygons are simpler for collision detection and rendering.
  -- Use this check to decide whether to decompose a shape.
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  if lurek.math.isConvex(poly) then
    lurek.log.debug("polygon is convex", "geo")
  end
end

--@api-stub: lurek.math.gammaToLinear
-- Converts a gamma-space channel to linear space
do
  -- sRGB displays use gamma encoding. Convert to linear for correct math
  -- (blending, lighting calculations) then convert back for display.
  local linear = lurek.math.gammaToLinear(0.5)
  lurek.log.debug("0.5 sRGB -> " .. linear .. " linear", "color")
end

--@api-stub: lurek.math.linearToGamma
-- Converts a linear-space channel to gamma space
do
  -- After doing lighting math in linear space, convert back to gamma for display
  local srgb = lurek.math.linearToGamma(0.214)
  lurek.log.debug("linear 0.214 -> " .. srgb .. " sRGB", "color")
end

--@api-stub: lurek.math.angleBetween
-- Returns the angle between two points
do
  -- Returns angle in radians from point 1 to point 2.
  -- Useful for aiming projectiles or rotating sprites toward a target.
  local rad = lurek.math.angleBetween(0, 0, 100, 100)
  lurek.log.debug("angle=" .. lurek.math.deg(rad) .. " deg", "geo")
end

--@api-stub: lurek.math.circleContainsPoint
-- Returns whether a circle contains a point
do
  -- Fast point-in-circle test. Good for aura/range checks.
  -- Args: circle center x, y, radius, point x, y
  if lurek.math.circleContainsPoint(0, 0, 50, 30, 20) then
    lurek.log.info("inside aura", "trigger")
  end
end

--@api-stub: lurek.math.circleIntersectsCircle
-- Returns whether two circles intersect
do
  -- Circle-circle overlap test. Fastest 2D collision primitive.
  -- Args: x1, y1, r1, x2, y2, r2
  if lurek.math.circleIntersectsCircle(0, 0, 10, 8, 6, 5) then
    lurek.log.warn("orbs collided", "physics")
  end
end

--@api-stub: lurek.math.circleIntersectsLine
-- Returns circle-line intersection state and hit points when present
do
  -- Tests an infinite line against a circle. Returns hit flag and up to 2 intersection points.
  -- Useful for laser/beam effects or line-of-sight checks.
  local hit, ix, iy = lurek.math.circleIntersectsLine(0, 0, 50, -100, 0, 100, 0)
  if hit then
    lurek.log.info("laser hit at " .. ix .. "," .. iy, "fx")
  end
end

--@api-stub: lurek.math.circleIntersectsSegment
-- Returns circle-segment intersection state and hit points when present
do
  -- Same as line test but limited to a finite segment.
  -- Better for bullets, swords, or finite-length beams.
  local hit, ix, iy = lurek.math.circleIntersectsSegment(20, 0, 5, 0, 0, 40, 0)
  if hit then
    lurek.log.info("bullet impact " .. ix .. "," .. iy, "combat")
  end
end

--@api-stub: lurek.math.closestPointOnSegment
-- Returns the closest point on a segment to an input point
do
  -- Find the nearest point on a wall or path to an AI agent.
  -- Useful for steering behaviors and distance-to-obstacle calculations.
  local cx, cy = lurek.math.closestPointOnSegment(50, 30, 0, 0, 100, 0)
  lurek.log.debug("nearest=" .. cx .. "," .. cy, "ai")
end

--@api-stub: lurek.math.convexHull
-- Computes the convex hull for a flat point table
do
  -- Convex hull wraps a minimal polygon around scattered points.
  -- Useful for generating bounding shapes from sprite outlines or particle clusters.
  local pts = {0, 0, 100, 0, 50, 50, 100, 100, 0, 100}
  local hull = lurek.math.convexHull(pts)
  lurek.log.info("hull verts=" .. (#hull / 2), "geo")
end

--@api-stub: lurek.math.delaunayTriangulate
-- Computes Delaunay triangles for a flat point table
do
  -- Delaunay triangulation maximizes minimum angles — good for terrain mesh,
  -- navigation meshes, or Voronoi dual graphs.
  local pts = {0, 0, 100, 0, 50, 80, 60, 30}
  local tris = lurek.math.delaunayTriangulate(pts)
  lurek.log.info("delaunay tris=" .. #tris, "geo")
end

--@api-stub: lurek.math.lineIntersect
-- Returns intersection point for two infinite lines when present
do
  -- Find where two infinite lines cross. Returns nil if parallel.
  -- Lines defined by two points each: (x1,y1)-(x2,y2) and (x3,y3)-(x4,y4).
  local ix, iy = lurek.math.lineIntersect(0, 0, 100, 100, 0, 100, 100, 0)
  if ix then
    lurek.log.debug("cross at " .. ix .. "," .. iy, "geo")
  end
end

--@api-stub: lurek.math.pointInPolygon
-- Returns whether a point lies inside a polygon
do
  -- Point-in-polygon test using ray casting. Works for any simple polygon.
  -- Args: flat point table, then point x, y.
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  if lurek.math.pointInPolygon(poly, 50, 50) then
    lurek.log.info("inside zone", "trigger")
  end
end

--@api-stub: lurek.math.polygonArea
-- Computes signed area for a flat polygon point table
do
  -- Signed area: positive = counter-clockwise winding, negative = clockwise.
  -- Use abs() for the actual area value.
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local area = lurek.math.polygonArea(poly)
  lurek.log.info("polygon area=" .. math.abs(area), "geo")
end

--@api-stub: lurek.math.polygonCentroid
-- Computes the centroid for a flat polygon point table
do
  -- Centroid is the geometric center — good for label placement or pivot points.
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local cx, cy = lurek.math.polygonCentroid(poly)
  lurek.log.debug("centroid " .. cx .. "," .. cy, "geo")
end

--@api-stub: lurek.math.segmentIntersectsSegment
-- Returns whether two segments intersect and their intersection point when present
do
  -- Finite segment intersection. Returns hit flag and point if they cross.
  -- Useful for sword slash vs wall, or rope vs obstacle.
  local hit, ix, iy = lurek.math.segmentIntersectsSegment(0, 0, 100, 0, 50, -50, 50, 50)
  if hit then
    lurek.log.info("blade crossed " .. ix .. "," .. iy, "combat")
  end
end

--@api-stub: lurek.math.bresenham
-- Returns integer grid points along a Bresenham line
do
  -- Bresenham line rasterization: returns all tile coordinates a line passes through.
  -- Essential for tile-based line-of-sight, fog of war reveal, or laser grids.
  local pts = lurek.math.bresenham(0, 0, 5, 3)
  lurek.log.info("bresenham steps=" .. #pts, "tile")
end

--@api-stub: lurek.math.rad
-- Converts degrees to radians
do
  -- Most math functions use radians. Convert user-facing degree values here.
  local turn_deg = 90
  local turn_rad = lurek.math.rad(turn_deg)
  lurek.log.debug(turn_deg .. " deg = " .. turn_rad .. " rad", "math")
end

--@api-stub: lurek.math.deg
-- Converts radians to degrees
do
  -- Convert internal radian angles to degrees for display or debugging
  local heading = lurek.math.deg(math.pi / 2)
  lurek.log.info("heading=" .. heading .. " deg", "compass")
end

--@api-stub: lurek.math.sin
-- Returns sine of an angle
do
  -- Sine is fundamental for oscillation: bobbing items, waves, circular motion.
  local t = 0
  function lurek.process(dt)
    t = t + dt
    -- Gentle floating effect: 8 pixels amplitude, 2 Hz frequency
    local bob = lurek.math.sin(t * 2) * 8
    lurek.log.debug("bob=" .. bob, "fx")
  end
end

--@api-stub: lurek.math.cos
-- Returns cosine of an angle
do
  -- Cosine paired with sine gives circular motion (orbits, radar sweeps)
  local t = 1.5
  local x = lurek.math.cos(t) * 50
  lurek.log.debug("orbit x=" .. x, "fx")
end

--@api-stub: lurek.math.tan
-- Returns tangent of an angle
do
  -- Tangent gives the slope of a line at an angle. Useful for ramp calculations.
  local slope = lurek.math.tan(math.pi / 6)
  lurek.log.debug("30deg slope=" .. slope, "math")
end

--@api-stub: lurek.math.asin
-- Returns arcsine of a value
do
  -- Arcsine: inverse of sin. Input must be in [-1..1].
  local angle = lurek.math.asin(0.5)
  lurek.log.debug("asin(0.5)=" .. lurek.math.deg(angle), "math")
end

--@api-stub: lurek.math.acos
-- Returns arccosine of a value
do
  -- Arccosine: inverse of cos. Returns angle in [0..pi].
  local angle = lurek.math.acos(0.0)
  lurek.log.debug("acos(0)=" .. lurek.math.deg(angle), "math")
end

--@api-stub: lurek.math.atan
-- Returns arctangent or two-argument arctangent
do
  -- Single arg: classic atan. Two args: atan2 behavior (full 360-degree range).
  local a = lurek.math.atan(1.0)
  local b = lurek.math.atan(1.0, -1.0)
  lurek.log.debug("atan results " .. a .. " " .. b, "math")
end

--@api-stub: lurek.math.atan2
-- Returns two-argument arctangent
do
  -- atan2(dy, dx) gives the angle from origin to a point in full [-pi..pi] range.
  -- Essential for aiming at a target.
  local dx, dy = 100 - 0, 50 - 0
  local heading = lurek.math.atan2(dy, dx)
  lurek.log.info("heading rad=" .. heading, "ai")
end

--@api-stub: lurek.math.sqrt
-- Returns square root of a value
do
  -- Classic Pythagorean distance: sqrt(a^2 + b^2)
  local hyp = lurek.math.sqrt(3 * 3 + 4 * 4)
  lurek.log.debug("hyp=" .. hyp, "math")
end

--@api-stub: lurek.math.abs
-- Returns absolute value
do
  -- Absolute value removes sign. Useful for dead-zone checks on joystick axes.
  local axis = -0.7
  if lurek.math.abs(axis) > 0.2 then
    lurek.log.debug("axis active", "input")
  end
end

--@api-stub: lurek.math.floor
-- Returns floor of a value
do
  -- Floor snaps down to integer. Good for pixel-perfect positioning.
  local raw_x = 123.7
  local pixel_x = lurek.math.floor(raw_x)
  lurek.log.debug("pixel x=" .. pixel_x, "render")
end

--@api-stub: lurek.math.ceil
-- Returns ceiling of a value
do
  -- Ceil rounds up. Useful for minimum damage (always at least 1).
  local dmg = lurek.math.ceil(2.3)
  lurek.log.info("damage=" .. dmg, "combat")
end

--@api-stub: lurek.math.round
-- Returns rounded value
do
  -- Round to nearest integer. Good for snapping to grid.
  local snapped = lurek.math.round(127.5)
  lurek.log.debug("rounded=" .. snapped, "ui")
end

--@api-stub: lurek.math.exp
-- Returns exponential of a value
do
  -- Exponential decay: e^(-rate * time). Common for smooth damping.
  local decay = lurek.math.exp(-0.5)
  lurek.log.debug("decay=" .. decay, "math")
end

--@api-stub: lurek.math.log
-- Returns natural logarithm or logarithm with a supplied base
do
  -- log(x) = natural log; log(x, base) = arbitrary base.
  -- Convert amplitude ratio to decibels: 20 * log10(ratio)
  local db = 20 * lurek.math.log(0.5, 10)
  lurek.log.debug("0.5 -> " .. db .. " dB", "audio")
end

--@api-stub: lurek.math.pow
-- Raises a value to a power
do
  -- Power function. Good for exponential scaling or gamma correction.
  local energy = lurek.math.pow(2.0, 8)
  lurek.log.debug("2^8=" .. energy, "math")
end

--@api-stub: lurek.math.min
-- Returns the smallest supplied value
do
  -- min() accepts multiple values. Use to cap a value at a maximum.
  local function current_hp_or_default(v) return v end
  local clamp_hp = lurek.math.min(100, current_hp_or_default(85), 90)
  lurek.log.debug("hp=" .. clamp_hp, "combat")
end

--@api-stub: lurek.math.max
-- Returns the largest supplied value
do
  -- max() ensures a floor. Damage can never go below 1.
  local final = lurek.math.max(1, 5 - 7)
  lurek.log.debug("final dmg=" .. final, "combat")
end

--@api-stub: lurek.math.clamp
-- Clamps a value to a range
do
  -- clamp(value, min, max) restricts a value to [min..max].
  -- Safer than separate min/max calls. Common for volume, HP, position bounds.
  local volume = lurek.math.clamp(1.4, 0, 1)
  lurek.log.debug("clamped vol=" .. volume, "audio")
end

--@api-stub: lurek.math.sign
-- Returns the sign of a value
do
  -- sign() returns -1, 0, or 1. Useful for movement direction from input axis.
  local axis = -0.4
  local dir = lurek.math.sign(axis)
  lurek.log.debug("walk dir=" .. dir, "input")
end

--@api-stub: lurek.math.fmod
-- Returns floating-point remainder
do
  -- fmod wraps a value within a period. Useful for looping angles.
  local wrapped = lurek.math.fmod(7.5, lurek.math.tau)
  lurek.log.debug("wrapped=" .. wrapped, "math")
end

--@api-stub: LVec3:lerp
-- Linearly interpolates between two values
do
  -- lerp(a, b, t) blends between a and b. t=0 gives a, t=1 gives b.
  -- The workhorse of animation: smoothly move between any two numeric values.
  local hp_bar = lurek.math.lerp(0, 200, 0.42)
  lurek.log.debug("hp bar pixels=" .. hp_bar, "ui")
end

--@api-stub: LVec3:distance
-- Returns Euclidean distance between two points
do
  -- Straight-line distance. Use for range checks, AI proximity, etc.
  local d = lurek.math.distance(0, 0, 3, 4)
  if d < 10 then
    lurek.log.debug("near target", "ai")
  end
end

--@api-stub: lurek.math.distanceSq
-- Returns squared Euclidean distance between two points
do
  -- Squared distance avoids expensive sqrt. Compare against threshold^2.
  -- Faster than distance() when you only need relative comparisons.
  local d2 = lurek.math.distanceSq(0, 0, 3, 4)
  if d2 < 100 then  -- equivalent to distance < 10
    lurek.log.debug("within 10 units", "ai")
  end
end

--@api-stub: LRandomGenerator:random
-- Returns a Lua math random value, optionally scaled to one or two bounds
do
  -- random() with no args: float in [0..1)
  -- random(n): integer in [1..n]
  -- random(a, b): integer in [a..b]
  local rolled = lurek.math.random(1, 6)
  lurek.log.info("dice=" .. rolled, "rng")
end

--@api-stub: LRandomGenerator:randomInt
-- Returns a Lua math random integer in an inclusive range
do
  -- Explicit integer random in [lo..hi]. Clearer intent than random(a,b).
  local slot = lurek.math.randomInt(1, 8)
  lurek.log.debug("loot slot=" .. slot, "rng")
end

--@api-stub: lurek.math.simplexNoise
-- Samples 2D or 3D simplex noise
do
  -- Convenience function: pass 2 args for 2D, 3 args for 3D simplex noise.
  -- Uses a global seed. For deterministic results, use newNoiseGenerator instead.
  local n = lurek.math.simplexNoise(0.5, 1.5, 0.0)
  lurek.log.debug("simplex=" .. n, "noise")
end

--@api-stub: lurek.math.vec2
-- Creates a 2D vector
do
  -- LVec2 is a lightweight 2D vector with dot, length, normalize, rotate, etc.
  -- Use for positions, velocities, directions.
  local pos = lurek.math.vec2(3, 4)
  local len = pos:length()
  lurek.log.debug("pos length=" .. len, "math")
end

--@api-stub: lurek.math.Vec2
-- Creates a 2D vector
do
  -- Vec2 (capital V) is an alias for vec2. Both create the same LVec2 object.
  local v = lurek.math.Vec2(10, 20)
  local n = v:normalize()
  lurek.log.debug("normalised x=" .. n.x, "math")
end

--@api-stub: lurek.math.vec3
-- Creates a 3D vector
do
  -- LVec3 provides basic 3D math: dot, cross, normalize, lerp, distance.
  -- Useful for lighting calculations, 3D audio positioning, or isometric math.
  ---@type LVec3
  local p = lurek.math.vec3(1, 2, 3)
  local len = p:length()
  lurek.log.debug("vec3 len=" .. len, "math")
end

--@api-stub: lurek.math.Vec3
-- Creates a 3D vector
do
  -- Vec3 (capital V) is an alias for vec3.
  ---@type LVec3
  local p = lurek.math.Vec3(0, 0, 1)
  local s = p:scale(5)
  lurek.log.debug("scaled z=" .. s.z, "math")
end

--@api-stub: lurek.math.catmullRom
-- Creates a Catmull-Rom spline from point tables
do
  -- Catmull-Rom passes through all control points — no "pulling" like Bezier.
  -- Great for enemy patrol paths, camera rails, or river courses.
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=100,y=200},{x=300,y=200},{x=400,y=0}})
  local x, y = cr:sample(0.5)
  lurek.log.debug("catmull mid " .. x .. "," .. y, "spline")
end

--@api-stub: lurek.math.hermite
-- Creates a Hermite spline from endpoints and tangents
do
  -- Hermite spline: define start point, end point, and tangent directions at each end.
  -- Gives explicit control over entry/exit velocity of the curve.
  ---@type LHermite
  local h = lurek.math.hermite(0, 0, 100, 100, 50, 0, 0, 50)
  local mx, my = h:sample(0.5)
  lurek.log.debug("hermite mid " .. mx .. "," .. my, "spline")
end

--@api-stub: lurek.math.remap
-- Remaps a value from one range to another
do
  -- remap(v, in_min, in_max, out_min, out_max) scales v from input range to output range.
  -- Useful for converting joystick [-1..1] to screen coordinates, etc.
  local mapped = lurek.math.remap(127, 0, 255, 0, 1)
  lurek.log.debug("normalised input=" .. mapped, "input")
end

--@api-stub: lurek.math.smoothstep
-- Applies smoothstep interpolation between two edges
do
  -- smoothstep(edge0, edge1, x): hermite interpolation between 0 and 1.
  -- Smoother than lerp — no abrupt start/stop. Good for fog fading.
  local fade = lurek.math.smoothstep(50, 100, 75)
  lurek.log.debug("fade=" .. fade, "fx")
end

--@api-stub: lurek.math.inverseLerp
-- Returns the interpolation factor of a value between two bounds
do
  -- inverseLerp(a, b, v): the reverse of lerp. Returns t such that lerp(a, b, t) == v.
  -- Useful for progress bars or normalizing a range.
  local t = lurek.math.inverseLerp(0, 200, 50)
  lurek.log.debug("t=" .. t, "math")
end

--@api-stub: lurek.math.hslToRgb
-- Converts HSL color values to RGBA channels
do
  -- HSL is intuitive for color pickers: hue=angle, saturation, lightness.
  -- Returns r,g,b,a in [0..1] range.
  local r, g, b, a = lurek.math.hslToRgb(200, 0.7, 0.5)
  lurek.log.debug("rgb " .. r .. "," .. g .. "," .. b, "color")
end

--@api-stub: lurek.math.fromHex
-- Converts a hex color string to RGBA channels
do
  -- Parse CSS-style hex colors. Supports #RGB, #RRGGBB, #RRGGBBAA.
  local r, g, b, a = lurek.math.fromHex("#ff8800")
  lurek.log.debug("hex -> " .. r .. "," .. g .. "," .. b, "color")
end

--@api-stub: lurek.math.rgbToHsl
-- Converts RGB channels to HSL values
do
  -- Convert RGB back to HSL for hue shifting or saturation adjustments
  local h, s, l = lurek.math.rgbToHsl(1.0, 0.5, 0.0)
  lurek.log.debug("hsl " .. h .. "," .. s .. "," .. l, "color")
end

--@api-stub: lurek.math.rectUnion
-- Returns the union rectangle for two rectangles
do
  -- Union computes the smallest rect containing both input rects.
  -- Useful for computing bounding boxes of multiple sprites.
  local x, y, w, h = lurek.math.rectUnion(0, 0, 50, 50, 30, 30, 60, 60)
  lurek.log.debug("union " .. w .. "x" .. h, "ui")
end

--@api-stub: lurek.math.rectFromCenter
-- Creates a rectangle tuple from center coordinates and size
do
  -- Convert center+size to top-left+size format for drawing or collision.
  local x, y, w, h = lurek.math.rectFromCenter(100, 100, 32, 32)
  lurek.log.debug("rect " .. x .. "," .. y, "geo")
end

--@api-stub: lurek.math.polygonClip
-- Clips a flat polygon point table against a plane
do
  -- Sutherland-Hodgman clipping: cuts a polygon along a plane defined by (nx, ny, d).
  -- The plane normal (nx, ny) points toward the kept half-space.
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local clipped = lurek.math.polygonClip(poly, 1, 0, 50)
  lurek.log.debug("clipped verts=" .. (#clipped / 2), "geo")
end

--@api-stub: lurek.math.aabbTree
-- Creates an empty AABB tree
do
  -- AABB tree is a bounding-volume hierarchy for fast spatial queries.
  -- Better than spatial hash for objects of varying size or sparse distributions.
  local tree = lurek.math.aabbTree()
  tree:insert(1, 0, 0, 32, 32)
  lurek.log.debug("tree size=" .. tree:len(), "physics")
end

--@api-stub: lurek.math.newCircle
-- Creates a circle primitive
do
  -- Circle object with contains, intersects, area, perimeter, and aabb methods.
  -- Lightweight geometry handle for collision or trigger zones.
  local c = lurek.math.newCircle(0, 0, 25)
  if c:contains(10, 5) then
    lurek.log.debug("inside circle", "geo")
  end
end

--@api-stub: lurek.math.polygonIntersection
-- Returns polygon intersection points for two polygon tables
do
  -- Boolean intersection (AND): returns the overlapping region of two polygons.
  -- Input format: array of {x=, y=} tables.
  local a = {{x=0,y=0},{x=100,y=0},{x=100,y=100},{x=0,y=100}}
  local b = {{x=50,y=50},{x=150,y=50},{x=150,y=150},{x=50,y=150}}
  local hit = lurek.math.polygonIntersection(a, b)
  lurek.log.info("overlap verts=" .. #hit, "geo")
end

--@api-stub: lurek.math.polygonUnion
-- Returns polygon union points for two polygon tables
do
  -- Boolean union (OR): merges two polygons into their combined outline.
  local a = {{x=0,y=0},{x=100,y=0},{x=100,y=100},{x=0,y=100}}
  local b = {{x=80,y=80},{x=180,y=80},{x=180,y=180},{x=80,y=180}}
  local u = lurek.math.polygonUnion(a, b)
  lurek.log.info("union verts=" .. #u, "geo")
end

--@api-stub: lurek.math.polygonDifference
-- Returns polygon difference points for two polygon tables
do
  -- Boolean difference (A minus B): cuts polygon B out of polygon A.
  -- Useful for destructible terrain or hole-punching effects.
  local a = {{x=0,y=0},{x=100,y=0},{x=100,y=100},{x=0,y=100}}
  local b = {{x=20,y=20},{x=80,y=20},{x=80,y=80},{x=20,y=80}}
  local diff = lurek.math.polygonDifference(a, b)
  lurek.log.info("diff verts=" .. #diff, "geo")
end

--@api-stub: lurek.math.voronoi
-- Builds Voronoi cells from a polygon-style point table
do
  -- Voronoi diagram: partitions space into cells closest to each seed point.
  -- Great for territory maps, crystal textures, or shatter patterns.
  local seeds = {{x=0,y=0},{x=100,y=0},{x=50,y=80}}
  local cells = lurek.math.voronoi(seeds)
  lurek.log.info("voronoi cells=" .. #cells, "geo")
end

--@api-stub: LVec3:dot
-- Performs the dot operation on this vec2.
do
  -- Dot product measures alignment: 1 = same direction, 0 = perpendicular, -1 = opposite.
  -- Use to check if an enemy is facing the player.
  local a = lurek.math.vec2(1, 0)
  local b = lurek.math.vec2(0, 1)
  lurek.log.debug("dot=" .. a:dot(b), "math")
end

--@api-stub: LBezierCurve:length
-- Performs the length operation on this vec2.
do
  -- length() returns the magnitude (Euclidean norm) of the vector.
  local v = lurek.math.vec2(3, 4)
  local len = v:length()
  lurek.log.info("len=" .. len, "math")
end

--@api-stub: LCircle:x
-- Performs the x operation on this vec2.
do
  -- Access x component directly via .x field
  local v = lurek.math.vec2(7, 9)
  local x = v.x
  lurek.log.debug("x=" .. x, "math")
end

--@api-stub: LCircle:y
-- Performs the y operation on this vec2.
do
  -- Access y component directly via .y field
  local v = lurek.math.vec2(7, 9)
  local y = v.y
  lurek.log.debug("y=" .. y, "math")
end

--@api-stub: LVec3:lengthSquared
-- Performs the length squared operation on this vec2.
do
  -- lengthSquared() avoids sqrt — use for distance comparisons.
  local v = lurek.math.vec2(3, 4)
  if v:lengthSquared() > 25 then
    lurek.log.debug("vector longer than 5", "math")
  end
end

--@api-stub: LVec3:normalize
-- Performs the normalize operation on this vec2.
do
  -- normalize() returns a unit vector (length=1) pointing in the same direction.
  -- Essential for converting velocity to direction.
  local dir = lurek.math.vec2(10, 0):normalize()
  lurek.log.debug("dir x=" .. dir.x, "math")
end

--@api-stub: LVec2:normalized
-- Performs the normalized operation on this vec2.
do
  -- normalized() is an alias for normalize() — same result.
  local n = lurek.math.vec2(0, 5):normalized()
  lurek.log.debug("n.y=" .. n.y, "math")
end

--@api-stub: LVec3:lerp
-- Performs the lerp operation on this vec2.
do
  -- Vector lerp smoothly blends between two positions.
  -- t=0 gives vector a, t=1 gives vector b.
  local a = lurek.math.vec2(0, 0)
  local b = lurek.math.vec2(100, 0)
  local mid = a:lerp(b, 0.5)
  lurek.log.debug("mid x=" .. mid.x, "math")
end

--@api-stub: LVec3:distance
-- Performs the distance operation on this vec2.
do
  -- Object-oriented distance: a:distance(b) instead of lurek.math.distance(...)
  local a = lurek.math.vec2(0, 0)
  local b = lurek.math.vec2(3, 4)
  lurek.log.info("dist=" .. a:distance(b), "math")
end

--@api-stub: LVec2:angle
-- Performs the angle operation on this vec2.
do
  -- angle() returns the angle of this vector from the positive X axis (in radians).
  local v = lurek.math.vec2(0, 1)
  lurek.log.debug("angle=" .. lurek.math.deg(v:angle()), "math")
end

--@api-stub: LBezierCurve:rotate
-- Performs the rotate operation on this vec2.
do
  -- rotate(angle) returns a new vector rotated by the given radians.
  -- Useful for aiming projectiles at an offset angle.
  local v = lurek.math.vec2(10, 0)
  local r = v:rotate(math.pi / 2)
  lurek.log.debug("rotated x=" .. r.x .. " y=" .. r.y, "math")
end

--@api-stub: LVec2:perpendicular
-- Performs the perpendicular operation on this vec2.
do
  -- perpendicular() returns a vector rotated 90 degrees (surface normal).
  -- Use for wall sliding or reflection normal computation.
  local n = lurek.math.vec2(1, 0):perpendicular()
  lurek.log.debug("perp y=" .. n.y, "math")
end

--@api-stub: LVec3:cross
-- Performs the cross operation on this vec2.
do
  -- 2D cross product: returns a scalar (the Z component of the 3D cross).
  -- Positive = b is counter-clockwise from a. Useful for winding order checks.
  local a = lurek.math.vec2(1, 0)
  local b = lurek.math.vec2(0, 1)
  lurek.log.debug("cross=" .. a:cross(b), "math")
end

--@api-stub: LVec2:reflect
-- Performs the reflect operation on this vec2.
do
  -- reflect(normal) bounces this vector off a surface defined by the normal.
  -- Essential for projectile bouncing, mirror effects, or ball physics.
  local incoming = lurek.math.vec2(1, -1)
  local floor = lurek.math.vec2(0, 1)
  local bounced = incoming:reflect(floor)
  lurek.log.debug("bounce y=" .. bounced.y, "physics")
end

--@api-stub: LBezierCurve:length
-- Performs the length operation on this vec3.
do
  ---@type LVec3
  local v = lurek.math.vec3(1, 2, 2)
  lurek.log.debug("len=" .. v:length(), "math")
end

--@api-stub: LVec3:lengthSquared
-- Performs the length squared operation on this vec3.
do
  ---@type LVec3
  local v = lurek.math.vec3(2, 2, 1)
  lurek.log.debug("len2=" .. v:lengthSquared(), "math")
end

--@api-stub: LVec3:normalize
-- Performs the normalize operation on this vec3.
do
  ---@type LVec3
  local v = lurek.math.vec3(0, 0, 5)
  local n = v:normalize()
  lurek.log.debug("n.z=" .. n.z, "math")
end

--@api-stub: LVec3:dot
-- Performs the dot operation on this vec3.
do
  -- 3D dot product: used in lighting (N dot L), projection, and angle checks.
  ---@type LVec3
  local n = lurek.math.vec3(0, 1, 0)
  ---@type LVec3
  local l = lurek.math.vec3(0, 1, 0)
  lurek.log.debug("ndotl=" .. n:dot(l), "light")
end

--@api-stub: LVec3:cross
-- Performs the cross operation on this vec3.
do
  -- 3D cross product: returns a vector perpendicular to both inputs.
  -- Defines surface normals from two edge vectors.
  ---@type LVec3
  local x = lurek.math.vec3(1, 0, 0)
  ---@type LVec3
  local y = lurek.math.vec3(0, 1, 0)
  local z = x:cross(y)
  lurek.log.debug("z.z=" .. z.z, "math")
end

--@api-stub: LVec3:lerp
-- Performs the lerp operation on this vec3.
do
  -- 3D vector interpolation: blend between two 3D positions
  ---@type LVec3
  local a = lurek.math.vec3(0, 0, 0)
  ---@type LVec3
  local b = lurek.math.vec3(10, 10, 10)
  local m = a:lerp(b, 0.5)
  lurek.log.debug("mid.x=" .. m.x, "math")
end

--@api-stub: LVec3:distance
-- Performs the distance operation on this vec3.
do
  ---@type LVec3
  local a = lurek.math.vec3(0, 0, 0)
  ---@type LVec3
  local b = lurek.math.vec3(3, 4, 0)
  lurek.log.info("dist=" .. a:distance(b), "math")
end

--@api-stub: LVec3:add
-- Adds a  to this vec3.
do
  -- add() returns a new vector: sum of this and other. Does not mutate.
  ---@type LVec3
  local a = lurek.math.vec3(1, 2, 3)
  ---@type LVec3
  local b = lurek.math.vec3(10, 0, 0)
  local s = a:add(b)
  lurek.log.debug("sum.x=" .. s.x, "math")
end

--@api-stub: LVec3:sub
-- Performs the sub operation on this vec3.
do
  -- sub() returns the difference: this minus other.
  ---@type LVec3
  local a = lurek.math.vec3(5, 5, 5)
  ---@type LVec3
  local b = lurek.math.vec3(1, 2, 3)
  local d = a:sub(b)
  lurek.log.debug("diff.z=" .. d.z, "math")
end

--@api-stub: LBezierCurve:scale
-- Performs the scale operation on this vec3.
do
  -- scale(s) multiplies all components by scalar s. Good for velocity * speed.
  ---@type LVec3
  local base = lurek.math.vec3(1, 0, 0)
  local v = base:scale(9.81)
  lurek.log.debug("scaled.x=" .. v.x, "physics")
end

--@api-stub: LHermite:sample
-- Performs the sample operation on this catmull rom.
do
  -- sample(t) evaluates the spline at normalized t in [0..1].
  -- t=0 is the first point, t=1 is the last.
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=100,y=200},{x=300,y=200},{x=400,y=0}})
  local x, y = cr:sample(0.25)
  lurek.log.debug("sample " .. x .. "," .. y, "spline")
end

--@api-stub: LCatmullRom:sampleSegment
-- Performs the sample segment operation on this catmull rom.
do
  -- sampleSegment(seg, t) samples one specific segment by zero-based index.
  -- Useful for per-segment animation or drawing.
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=20},{x=100,y=0},{x=150,y=20}})
  local x, y = cr:sampleSegment(0, 0.5)
  lurek.log.debug("seg0 mid " .. x .. "," .. y, "spline")
end

--@api-stub: LAabbTree:len
-- Performs the len operation on this catmull rom.
do
  -- len() returns the number of control points in the spline.
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=10,y=10},{x=20,y=0},{x=30,y=10}})
  lurek.log.info("control points=" .. cr:len(), "spline")
end

--@api-stub: LCatmullRom:addPoint
-- Adds a point to this catmull rom.
do
  -- addPoint(x, y) appends a new control point, extending the spline.
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=50},{x=100,y=0},{x=150,y=50}})
  cr:addPoint(200, 0)
  lurek.log.debug("after add count=" .. cr:len(), "spline")
end

--@api-stub: LCatmullRom:removePoint
-- Removes a point from this catmull rom.
do
  -- removePoint(idx) removes a control point by zero-based index.
  -- Returns the removed point's coordinates.
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=50},{x=100,y=0},{x=150,y=50}})
  local rx, ry = cr:removePoint(1)
  lurek.log.debug("removed " .. rx .. "," .. ry, "spline")
end

--@api-stub: LHermite:sample
-- Performs the sample operation on this hermite.
do
  -- Same as CatmullRom:sample — evaluates at normalized t.
  ---@type LHermite
  local h = lurek.math.hermite(0, 0, 100, 100, 50, 0, 0, 50)
  local x, y = h:sample(0.5)
  lurek.log.debug("hermite mid " .. x .. "," .. y, "spline")
end

--@api-stub: LRandomGenerator:random
-- Performs the random operation on this random generator.
do
  -- random() returns a float in [0..1). Every call advances the generator state.
  local rng = lurek.math.newRandomGenerator(42)
  local v = rng:random()
  lurek.log.debug("u01=" .. v, "rng")
end

--@api-stub: LRandomGenerator:randomFloat
-- Performs the random float operation on this random generator.
do
  -- randomFloat(min, max) returns a float in [min..max].
  -- Good for random angles, spawn offsets, or color variation.
  local rng = lurek.math.newRandomGenerator(7)
  local angle = rng:randomFloat(0, math.pi * 2)
  lurek.log.debug("angle=" .. angle, "rng")
end

--@api-stub: LRandomGenerator:randomInt
-- Performs the random int operation on this random generator.
do
  -- randomInt(min, max) returns an integer in [min..max] inclusive.
  -- Classic d20 roll for tabletop-style games.
  local rng = lurek.math.newRandomGenerator(99)
  local roll = rng:randomInt(1, 20)
  lurek.log.info("d20=" .. roll, "rng")
end

--@api-stub: LNoiseGenerator:getSeed
-- Returns the seed of this random generator.
do
  -- getSeed() retrieves the seed this generator was created with.
  local rng = lurek.math.newRandomGenerator(20260422)
  local seed = rng:getSeed()
  lurek.log.info("rng seed=" .. seed, "rng")
end

--@api-stub: LNoiseGenerator:setSeed
-- Sets the seed of this random generator.
do
  -- setSeed() resets the generator to produce the same sequence from this seed.
  -- Use to replay a procedural level with a known seed.
  local rng = lurek.math.newRandomGenerator(0)
  rng:setSeed(12345)
  lurek.log.debug("after reseed=" .. rng:randomInt(1, 6), "rng")
end

--@api-stub: LRandomGenerator:getState
-- Returns the state of this random generator.
do
  -- getState() serializes the full internal state as a string.
  -- Use for save-game snapshots of RNG position.
  local rng = lurek.math.newRandomGenerator(77)
  local snapshot = rng:getState()
  lurek.log.debug("state bytes=" .. #snapshot, "rng")
end

--@api-stub: LRandomGenerator:setState
-- Sets the state of this random generator.
do
  -- setState() restores a previously saved state, resuming the exact sequence.
  local rng = lurek.math.newRandomGenerator(77)
  local snap = rng:getState()
  rng:random()  -- advance the state
  rng:setState(snap)  -- rewind to the snapshot
  -- Next call will produce the same value as before the advance
end

--@api-stub: LBezierCurve:translate
-- Performs the translate operation on this transform.
do
  -- translate(dx, dy) shifts the transform. Compounds with existing translation.
  local t = lurek.math.newTransform()
  t:translate(50, -10)
  lurek.log.debug("translated", "xform")
end

--@api-stub: LBezierCurve:rotate
-- Performs the rotate operation on this transform.
do
  -- rotate(angle) adds rotation in radians. Compounds with existing rotation.
  local t = lurek.math.newTransform()
  t:rotate(math.pi / 4)
  lurek.log.debug("rotated 45deg", "xform")
end

--@api-stub: LBezierCurve:scale
-- Performs the scale operation on this transform.
do
  -- scale(sx, sy) multiplies the current scale. sy defaults to sx if omitted.
  local t = lurek.math.newTransform()
  t:scale(2, 0.5)
  lurek.log.debug("scaled", "xform")
end

--@api-stub: LTransform:shear
-- Performs the shear operation on this transform.
do
  -- shear(kx, ky) applies skew. Useful for italic text or wind effects.
  local t = lurek.math.newTransform()
  t:shear(0.2, 0)
  lurek.log.debug("sheared", "xform")
end

--@api-stub: LTween:reset
-- Resets this transform to its default state.
do
  -- reset() returns the transform to identity (no translation, rotation, or scale).
  local t = lurek.math.newTransform(10, 20, 0.5)
  t:reset()
  lurek.log.debug("reset to identity", "xform")
end

--@api-stub: LTransform:transformPoint
-- Performs the transform point operation on this transform.
do
  -- transformPoint(x, y) converts a local-space point to world-space.
  -- The core operation for sprite hierarchy positioning.
  local t = lurek.math.newTransform(100, 50, math.pi / 2)
  local wx, wy = t:transformPoint(10, 0)
  lurek.log.debug("world " .. wx .. "," .. wy, "xform")
end

--@api-stub: LTransform:inverseTransformPoint
-- Performs the inverse transform point operation on this transform.
do
  -- inverseTransformPoint: converts world-space back to local-space.
  -- Useful for mouse picking in a rotated/scaled coordinate system.
  local t = lurek.math.newTransform(50, 50, math.pi / 4)
  local lx, ly = t:inverseTransformPoint(100, 50)
  lurek.log.debug("local " .. lx .. "," .. ly, "xform")
end

--@api-stub: LTransform:inverse
-- Performs the inverse operation on this transform.
do
  -- inverse() returns a new transform that undoes this one.
  -- Applying both in sequence gives identity.
  local t = lurek.math.newTransform(10, 20, 0.3)
  local inv = t:inverse()
  lurek.log.debug("got inverse", "xform")
end

--@api-stub: LTransform:clone
-- Performs the clone operation on this transform.
do
  -- clone() creates an independent copy. Modifying the clone does not affect the original.
  local t = lurek.math.newTransform(10, 20)
  local dup = t:clone()
  dup:translate(5, 0)
end

--@api-stub: LTransform:getMatrix
-- Returns the matrix of this transform.
do
  -- getMatrix() returns the underlying 3x3 matrix as a flat table.
  -- Row-major order, useful for custom shader uniforms.
  local t = lurek.math.newTransform(0, 0, math.pi / 2)
  local m = t:getMatrix()
  lurek.log.debug("matrix elems=" .. #m, "xform")
end

--@api-stub: LTransform:decompose
-- Performs the decompose operation on this transform.
do
  -- decompose() extracts translation, rotation, and scale from the matrix.
  -- Returns x, y, angle, scaleX, scaleY.
  local t = lurek.math.newTransform(100, 50, math.pi / 4, 2, 2)
  local x, y, angle, sx, sy = t:decompose()
  lurek.log.info("xform " .. x .. "," .. y .. " a=" .. angle, "xform")
end

--@api-stub: LBezierCurve:evaluate
-- Performs the evaluate operation on this bezier curve.
do
  -- evaluate(t) samples the curve at normalized parameter t in [0..1].
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local x, y = c:evaluate(0.25)
  lurek.log.debug("eval " .. x .. "," .. y, "spline")
end

--@api-stub: LBezierCurve:evaluateAtDistance
-- Performs the evaluate at distance operation on this bezier curve.
do
  -- evaluateAtDistance(dist, samples) gives a point at an arc-length distance.
  -- More uniform spacing than evaluate(t) which is parametric, not arc-length.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local x, y = c:evaluateAtDistance(120, 128)
  lurek.log.debug("eval@dist " .. x .. "," .. y, "spline")
end

--@api-stub: LBezierCurve:render
-- Draws or renders this bezier curve to the current render target.
do
  -- render(segments) returns sampled points as a polyline for drawing.
  -- More segments = smoother curve but more vertices.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local pts = c:render(32)
  lurek.log.info("polyline points=" .. #pts, "spline")
end

--@api-stub: LBezierCurve:getDerivative
-- Returns the derivative of this bezier curve.
do
  -- getDerivative() returns a new curve representing the tangent direction.
  -- Evaluate it to get velocity at any point along the original curve.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local d = c:getDerivative()
  lurek.log.debug("derivative ready", "spline")
end

--@api-stub: LBezierCurve:getControlPoint
-- Returns the control point of this bezier curve.
do
  -- getControlPoint(index) returns x, y for a 1-based control point.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local x, y = c:getControlPoint(2)
  lurek.log.debug("cp2=" .. x .. "," .. y, "spline")
end

--@api-stub: LBezierCurve:removeControlPoint
-- Removes a control point from this bezier curve.
do
  -- removeControlPoint(index) removes a 1-based control point.
  -- Returns true if the point existed.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local ok = c:removeControlPoint(3)
  lurek.log.debug("removed=" .. tostring(ok), "spline")
end

--@api-stub: LBezierCurve:getControlPointCount
-- Returns the number of control point items in this bezier curve.
do
  -- Useful for iteration or validation before editing control points.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local n = c:getControlPointCount()
  lurek.log.info("cp count=" .. n, "spline")
end

--@api-stub: LBezierCurve:length
-- Performs the length operation on this bezier curve.
do
  -- length() approximates the arc length of the entire curve.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local len = c:length()
  lurek.log.info("arc len=" .. len, "spline")
end

--@api-stub: LBezierCurve:translate
-- Performs the translate operation on this bezier curve.
do
  -- translate(dx, dy) moves all control points by the given offset.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  c:translate(10, 5)
  lurek.log.debug("translated", "spline")
end

--@api-stub: LBezierCurve:rotate
-- Performs the rotate operation on this bezier curve.
do
  -- rotate(angle, ox, oy) rotates all control points around an origin.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  c:rotate(math.pi / 6, 0, 0)
  lurek.log.debug("rotated", "spline")
end

--@api-stub: LBezierCurve:scale
-- Performs the scale operation on this bezier curve.
do
  -- scale(factor, ox, oy) scales all control points relative to an origin.
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  c:scale(2.0, 0, 0)
  lurek.log.debug("scaled", "spline")
end

--@api-stub: LTween:reset
-- Resets this tween to its default state.
do
  -- reset() rewinds the tween clock to 0. Values return to their start positions.
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 100)
  tw:reset()
end

--@api-stub: LTween:getValue
-- Returns the value of this tween.
do
  -- getValue(index) returns the current interpolated value for a 1-based track.
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 200)
  local v = tw:getValue(1)
  lurek.log.debug("value=" .. v, "tween")
end

--@api-stub: LTween:getAllValues
-- Returns all values values associated with this tween.
do
  -- getAllValues() returns a table of all current track values at once.
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 1)
  local all = tw:getAllValues()
  lurek.log.debug("count=" .. #all, "tween")
end

--@api-stub: LTween:isComplete
-- Returns true if this tween complete.
do
  -- isComplete() checks if the tween has reached its full duration.
  local tw = lurek.math.newTween(0.2)
  if tw:isComplete() then
    lurek.log.debug("ready", "tween")
  end
end

--@api-stub: LTween:getValueCount
-- Returns the number of value items in this tween.
do
  -- getValueCount() tells how many tracks were added via addValue().
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 10)
  lurek.log.info("count=" .. tw:getValueCount(), "tween")
end

--@api-stub: LTween:getEasingName
-- Returns the easing name of this tween.
do
  -- Inspect which easing function is active (useful for debugging/display).
  local tw = lurek.math.newTween(0.5, "outBack")
  lurek.log.debug("easing=" .. tw:getEasingName(), "tween")
end

--@api-stub: LTween:getTime
-- Returns the time of this tween.
do
  -- getTime() returns the current clock position in seconds.
  local tw = lurek.math.newTween(1.0)
  local pct = tw:getTime() / tw:getDuration()
  lurek.log.debug("pct=" .. pct, "tween")
end

--@api-stub: LTween:getClock
-- Returns the clock of this tween.
do
  -- getClock() is an alias for getTime(). Both return current seconds elapsed.
  local tw = lurek.math.newTween(1.0)
  local now = tw:getClock()
  lurek.log.debug("now=" .. now, "tween")
end

--@api-stub: LTween:setTime
-- Sets the time of this tween.
do
  -- setTime(t) seeks the tween to a specific time. Good for scrubbing animations.
  local tw = lurek.math.newTween(1.0)
  tw:setTime(0.5)
  lurek.log.debug("seeked to 0.5", "tween")
end

--@api-stub: LTween:set
-- Sets the  of this tween.
do
  -- set(t) is an alias for setTime(t).
  local tw = lurek.math.newTween(1.0)
  tw:set(0.25)
  lurek.log.debug("clock set", "tween")
end

--@api-stub: LTween:addValue
-- Adds a value to this tween.
do
  -- addValue(start, target) adds a new interpolation track.
  -- Returns the 1-based index of the new track.
  local tw = lurek.math.newTween(0.5, "outQuad")
  local idx = tw:addValue(0, 200)
  lurek.log.info("value idx=" .. idx, "tween")
end

--@api-stub: LAabbTree:remove
-- Removes a  from this spatial hash.
do
  -- remove(id) takes an entity out of the hash. Call when an entity is destroyed.
  local h = lurek.math.newSpatialHash(64)
  h:insert("npc", 0, 0, 32, 32)
  h:remove("npc")
end

--@api-stub: LAabbTree:clear
-- Clears all items from this spatial hash.
do
  -- clear() empties the entire hash. Use at scene transitions.
  local h = lurek.math.newSpatialHash(64)
  h:insert("a", 0, 0, 16, 16)
  h:clear()
end

--@api-stub: LSpatialHash:getCellSize
-- Returns the cell size of this spatial hash.
do
  -- getCellSize() returns the grid cell dimension used for bucketing.
  local h = lurek.math.newSpatialHash(96)
  local cs = h:getCellSize()
  lurek.log.debug("cell=" .. cs, "spatial")
end

--@api-stub: LSpatialHash:getItemCount
-- Returns the number of item items in this spatial hash.
do
  -- getItemCount() tells how many items are currently inserted.
  local h = lurek.math.newSpatialHash(64)
  h:insert("a", 0, 0, 16, 16)
  lurek.log.info("items=" .. h:getItemCount(), "spatial")
end

--@api-stub: LNoiseGenerator:perlin1d
-- Performs the perlin1d operation on this noise generator.
do
  -- 1D Perlin noise: smooth random values along a single axis.
  -- Great for wind gusts, screen shake intensity, or wave heights.
  local n = lurek.math.newNoiseGenerator(1)
  local wind = n:perlin1d(0.4)
  lurek.log.debug("wind=" .. wind, "weather")
end

--@api-stub: LNoiseGenerator:perlin2d
-- Performs the perlin2d operation on this noise generator.
do
  -- 2D Perlin noise: the classic terrain heightmap generator.
  -- Coordinates scale affects detail level (smaller = smoother, larger = more detail).
  local n = lurek.math.newNoiseGenerator(2)
  local h = n:perlin2d(2.5, 4.5)
  lurek.log.debug("h=" .. h, "noise")
end

--@api-stub: LNoiseGenerator:perlin3d
-- Performs the perlin3d operation on this noise generator.
do
  -- 3D Perlin: use Z as time for animated 2D noise fields.
  local n = lurek.math.newNoiseGenerator(3)
  local v = n:perlin3d(1.0, 2.0, 3.0)
  lurek.log.debug("v=" .. v, "noise")
end

--@api-stub: LNoiseGenerator:perlin4d
-- Performs the perlin4d operation on this noise generator.
do
  -- 4D Perlin: useful for seamless tiling textures or animated 3D noise.
  local n = lurek.math.newNoiseGenerator(4)
  local v = n:perlin4d(0.1, 0.2, 0.3, 0.4)
  lurek.log.debug("v4=" .. v, "noise")
end

--@api-stub: LNoiseGenerator:simplex1d
-- Performs the simplex1d operation on this noise generator.
do
  -- 1D simplex noise: fewer artifacts than Perlin, slightly cheaper.
  local n = lurek.math.newNoiseGenerator(5)
  local s = n:simplex1d(0.7)
  lurek.log.debug("s1=" .. s, "noise")
end

--@api-stub: LNoiseGenerator:simplex2d
-- Performs the simplex2d operation on this noise generator.
do
  -- 2D simplex: better isotropy (less grid-aligned artifacts) than Perlin.
  local n = lurek.math.newNoiseGenerator(6)
  local s = n:simplex2d(0.4, 0.6)
  lurek.log.debug("s2=" .. s, "noise")
end

--@api-stub: LNoiseGenerator:simplex3d
-- Performs the simplex3d operation on this noise generator.
do
  -- 3D simplex: good for volumetric effects or animated 2D patterns.
  local n = lurek.math.newNoiseGenerator(7)
  local s = n:simplex3d(0.1, 0.2, 0.3)
  lurek.log.debug("s3=" .. s, "noise")
end

--@api-stub: LNoiseGenerator:getSeed
-- Returns the seed of this noise generator.
do
  local n = lurek.math.newNoiseGenerator(2026)
  lurek.log.info("noise seed=" .. n:getSeed(), "noise")
end

--@api-stub: LNoiseGenerator:setSeed
-- Sets the seed of this noise generator.
do
  -- Change seed at runtime to generate different worlds from the same code.
  local n = lurek.math.newNoiseGenerator(0)
  n:setSeed(99)
  lurek.log.debug("re-seeded", "noise")
end

--@api-stub: LCircle:area
-- Performs the area operation on this circle.
do
  -- area() returns pi * r^2
  local c = lurek.math.newCircle(0, 0, 5)
  lurek.log.debug("area=" .. c:area(), "geo")
end

--@api-stub: LCircle:perimeter
-- Performs the perimeter operation on this circle.
do
  -- perimeter() returns 2 * pi * r (circumference)
  local c = lurek.math.newCircle(0, 0, 10)
  lurek.log.debug("perimeter=" .. c:perimeter(), "geo")
end

--@api-stub: LAabbTree:contains
-- Performs the contains operation on this circle.
do
  -- contains(px, py) checks if a point is inside this circle.
  local c = lurek.math.newCircle(50, 50, 25)
  if c:contains(60, 60) then
    lurek.log.debug("inside", "geo")
  end
end

--@api-stub: LCircle:intersects
-- Performs the intersects operation on this circle.
do
  -- intersects(other) tests overlap between two circle objects.
  local a = lurek.math.newCircle(0, 0, 10)
  local b = lurek.math.newCircle(15, 0, 10)
  lurek.log.debug("hit=" .. tostring(a:intersects(b)), "geo")
end

--@api-stub: LCircle:aabb
-- Performs the aabb operation on this circle.
do
  -- aabb() returns the axis-aligned bounding box: min_x, min_y, max_x, max_y.
  -- Useful for broad-phase collision before precise circle tests.
  local c = lurek.math.newCircle(50, 30, 10)
  local x1, y1, x2, y2 = c:aabb()
  lurek.log.debug("aabb " .. x1 .. "," .. y1 .. " to " .. x2 .. "," .. y2, "geo")
end

--@api-stub: LCircle:x
-- Performs the x operation on this circle.
do
  -- x() returns the circle center X coordinate.
  local c = lurek.math.newCircle(72, 18, 5)
  lurek.log.debug("x=" .. c:x(), "geo")
end

--@api-stub: LCircle:y
-- Performs the y operation on this circle.
do
  -- y() returns the circle center Y coordinate.
  local c = lurek.math.newCircle(72, 18, 5)
  lurek.log.debug("y=" .. c:y(), "geo")
end

--@api-stub: LCircle:radius
-- Performs the radius operation on this circle.
do
  -- radius() returns the circle radius.
  local c = lurek.math.newCircle(0, 0, 12)
  lurek.log.info("radius=" .. c:radius(), "geo")
end

--@api-stub: LAabbTree:remove
-- Removes a  from this aabb tree.
do
  -- remove(id) deletes an entry. Returns true if the id existed.
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 32, 32)
  local ok = t:remove(1)
  lurek.log.debug("removed=" .. tostring(ok), "physics")
end

--@api-stub: LAabbTree:queryPoint
-- Performs the query point operation on this aabb tree.
do
  -- queryPoint(x, y) returns all ids whose AABBs contain that point.
  -- Fast for mouse picking or point-in-entity checks.
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 32, 32)
  local ids = t:queryPoint(10, 10)
  lurek.log.info("hits=" .. #ids, "physics")
end

--@api-stub: LAabbTree:contains
-- Performs the contains operation on this aabb tree.
do
  -- contains(id) checks if a given numeric id is present in the tree.
  local t = lurek.math.aabbTree()
  t:insert(42, 0, 0, 16, 16)
  if t:contains(42) then
    lurek.log.debug("entry exists", "physics")
  end
end

--@api-stub: LAabbTree:len
-- Performs the len operation on this aabb tree.
do
  -- len() returns total number of entries in the tree.
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 8, 8)
  lurek.log.info("aabb tree size=" .. t:len(), "physics")
end

--@api-stub: LAabbTree:isEmpty
-- Returns true if this aabb tree contains no items.
do
  -- isEmpty() is a convenience check before queries.
  local t = lurek.math.aabbTree()
  if t:isEmpty() then
    lurek.log.debug("tree empty", "physics")
  end
end

--@api-stub: LAabbTree:clear
-- Clears all items from this aabb tree.
do
  -- clear() removes everything. Use during scene transitions.
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 16, 16)
  t:clear()
end

--@api-stub: LNoiseGenerator:fbm
-- Performs the fbm operation on this noise generator.
do
  -- Instance-based FBM: uses the generator's seed internally.
  -- Args: x, y, octaves, lacunarity, persistence
  local ng = lurek.math.newNoiseGenerator(42)
  local v = ng:fbm(0.3, 0.7, 6, 2.0, 0.5)
  lurek.log.info("fbm noise: " .. v, "math")
end

--@api-stub: LNoiseGenerator:generateMap
-- Performs the generate map operation on this noise generator.
do
  -- generateMap(w, h, opts) returns a flat array of w*h noise values.
  -- Options: scale, offsetX, offsetY, octaves, kind, fractal, backend.
  local ng = lurek.math.newNoiseGenerator(99)
  local map = ng:generateMap(32, 32, { scale = 0.05, offsetX = 0.0, offsetY = 0.0 })
  lurek.log.info("map size: " .. #map, "math")
end

--@api-stub: LNoiseGenerator:generateMapCompute
-- Performs the generate map compute operation on this noise generator.
do
  -- generateMapCompute uses the GPU compute backend for faster large maps.
  -- Same options as generateMap but processed on the GPU.
  local ng = lurek.math.newNoiseGenerator(101)
  local map = ng:generateMapCompute(16, 16, { octaves = 3, lacunarity = 2.0, gain = 0.5 })
  lurek.log.info("compute map size: " .. #map, "math")
end

--@api-stub: LAabbTree:insert
-- Performs the insert operation on this spatial hash.
do
  -- insert(id, x, y, w, h) adds an entity by string id and bounding rect.
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("entity_01", 100, 100, 32, 32)
  sh:insert("entity_02", 200, 150, 32, 32)
  lurek.log.info("items: " .. sh:getItemCount(), "math")
end

--@api-stub: LAabbTree:insert
-- Performs the insert operation on this aabb tree.
do
  -- insert(id, min_x, min_y, max_x, max_y) adds a bounding box by numeric id.
  local tree = lurek.math.aabbTree()
  tree:insert(1, 10, 10, 50, 50)
  tree:insert(2, 80, 80, 120, 120)
  lurek.log.info("tree len: " .. tree:len(), "math")
end

--@api-stub: LBezierCurve:insertControlPoint
-- Performs the insert control point operation on this bezier curve.
do
  -- insertControlPoint(x, y, index) inserts before a 1-based index.
  -- Omit index to append at the end.
  local bc = lurek.math.newBezierCurve({0,0, 100,50, 200,0})
  bc:insertControlPoint(100, 25, 0.5)
  lurek.log.info("ctrl pts: " .. bc:getControlPointCount(), "math")
end

--@api-stub: LAabbTree:query
-- Performs the query operation on this aabb tree.
do
  -- query(min_x, min_y, max_x, max_y) returns all ids overlapping a rectangle.
  -- Core operation for broad-phase collision detection.
  local tree = lurek.math.aabbTree()
  tree:insert(1, 0, 0, 40, 40)
  tree:insert(2, 60, 60, 100, 100)
  local hits = tree:query(10, 10, 50, 50)
  lurek.log.info("hits: " .. #hits, "math")
end

--@api-stub: LSpatialHash:queryCircle
-- Performs the query circle operation on this spatial hash.
do
  -- queryCircle(cx, cy, radius) finds all entities within a circular area.
  -- Good for explosion radius, aggro range, or area-of-effect spells.
  local sh = lurek.math.newSpatialHash(32)
  sh:insert("e1", 100, 100, 16, 16)
  sh:insert("e2", 500, 500, 16, 16)
  local hits = sh:queryCircle(110, 110, 50)
  lurek.log.info("circle hits: " .. #hits, "math")
end

--@api-stub: LSpatialHash:queryRect
-- Performs the query rect operation on this spatial hash.
do
  -- queryRect(x, y, w, h) finds all entities overlapping a rectangular area.
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("player", 100, 100, 32, 32)
  sh:insert("enemy", 128, 100, 32, 32)
  local hits = sh:queryRect(90, 90, 170, 150)
  lurek.log.info("rect hits: " .. #hits, "math")
end

--@api-stub: LSpatialHash:querySegment
-- Performs the query segment operation on this spatial hash.
do
  -- querySegment(x1, y1, x2, y2) finds entities along a line segment.
  -- Perfect for raycasting, bullet traces, or laser beams.
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("wall", 200, 100, 240, 300)
  local hits = sh:querySegment(0, 200, 400, 200)
  lurek.log.info("segment hits: " .. #hits, "math")
end

--@api-stub: LRandomGenerator:randomNormal
-- Performs the random normal operation on this random generator.
do
  -- randomNormal(stddev, mean) returns a Gaussian-distributed value.
  -- Good for natural variation: enemy stats, spawn spread, or hit scatter.
  local rng = lurek.math.newRandomGenerator(12345)
  local v = rng:randomNormal(0, 1)
  lurek.log.info("normal sample: " .. v, "math")
end

--@api-stub: LNoiseGenerator:ridged
-- Performs the ridged operation on this noise generator.
do
  -- ridged() produces sharp ridges — good for mountain ranges or vein patterns.
  -- Args: x, y, octaves, lacunarity, persistence
  local ng = lurek.math.newNoiseGenerator(7)
  local v = ng:ridged(0.5, 0.5, 5, 2.0, 0.5)
  lurek.log.info("ridged: " .. v, "math")
end

--@api-stub: LBezierCurve:setControlPoint
-- Sets the control point of this bezier curve.
do
  -- setControlPoint(index, x, y) modifies an existing control point in place.
  -- Returns true if the index was valid.
  local bc = lurek.math.newBezierCurve({0,0, 100,0, 200,0})
  bc:setControlPoint(2, 100, 80)
  local cx, cy = bc:getControlPoint(2)
  lurek.log.info("ctrl pt 2: " .. cx .. "," .. cy, "math")
end

--@api-stub: LTransform:setTransformation
-- Sets the transformation of this transform.
do
  -- setTransformation replaces all components at once:
  -- (x, y, angle, sx, sy, ox, oy, kx, ky)
  -- ox, oy = origin offset for rotation/scale; kx, ky = shear.
  local t = lurek.math.newTransform()
  t:setTransformation(100, 200, 0.5, 2.0, 2.0, 16, 16, 0, 0)
  local x, y = t:transformPoint(0, 0)
  lurek.log.info("transformed origin: " .. x .. "," .. y, "math")
end

--@api-stub: LNoiseGenerator:turbulence
-- Performs the turbulence operation on this noise generator.
do
  -- turbulence() takes absolute value of each octave, creating billowy patterns.
  -- Good for smoke, fire, or cloud textures.
  local ng = lurek.math.newNoiseGenerator(55)
  local v = ng:turbulence(0.4, 0.6, 5, 2.0, 0.5)
  lurek.log.info("turbulence: " .. v, "math")
end

--@api-stub: LAabbTree:update
-- Advances this tween by the given delta time.
do
  -- update(dt) advances the clock. Returns true when the tween completes.
  -- Call this every frame in lurek.process(dt).
  local tw = lurek.math.newTween(1.0, "inOutQuad")
  tw:addValue(0, 200)
  tw:update(0.5)
  lurek.log.info("x at t=0.5: " .. tw:getValue(1), "math")
end

--@api-stub: LAabbTree:update
-- Advances this spatial hash by the given delta time.
do
  -- update(id, x, y, w, h) moves an existing entity to a new position.
  -- Call this when entities move instead of remove+insert.
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("player", 100, 100, 32, 32)
  sh:update("player", 110, 105, 32, 32)
  lurek.log.info("player position updated", "math")
end

--@api-stub: LNoiseGenerator:warpDomain
-- Performs the warp domain operation on this noise generator.
do
  -- warpDomain(x, y, strength) distorts coordinates before noise sampling.
  -- Creates organic, flowing patterns (marble, lava, organic growth).
  local ng = lurek.math.newNoiseGenerator(101)
  local wx, wy = ng:warpDomain(0.3, 0.3, 0.8)
  wx = wx or 0.0
  wy = wy or 0.0
  local v = ng:perlin2d(wx, wy)
  lurek.log.info("warped: " .. v, "math")
end

--@api-stub: LNoiseGenerator:worley2d
-- Performs the worley2d operation on this noise generator.
do
  -- worley2d() (cellular noise): produces cell-like patterns.
  -- Good for stone textures, scales, or cracked earth.
  local ng = lurek.math.newNoiseGenerator(321)
  local v = ng:worley2d(0.25, 0.75)
  lurek.log.info("worley2d: " .. v, "math")
end

--@api-stub: LNoiseGenerator:worley3d
-- Performs the worley3d operation on this noise generator.
do
  -- worley3d() extends cellular noise into 3D. Use Z as time for animated cells.
  local ng = lurek.math.newNoiseGenerator(654)
  local v = ng:worley3d(0.1, 0.5, 0.9)
  lurek.log.info("worley3d: " .. v, "math")
end

--@api-stub: LAabbTree:update
-- Advances this aabb tree by the given delta time.
do
  -- update(id, min_x, min_y, max_x, max_y) repositions an existing entry.
  -- Returns true if the id existed. Faster than remove+insert for moving objects.
  local tree = lurek.math.aabbTree()
  local id = 1
  tree:insert(id, 100, 100, 132, 132)
  tree:update(id, 110, 110, 142, 142)
  lurek.log.info("AABB tree updated", "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this AABB tree handle
do
  -- type() returns the string name of this userdata type.
  local aabb_tree_obj = lurek.math.aabbTree()
  local t = aabb_tree_obj:type()
  lurek.log.info("LAabbTree:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this AABB tree handle matches a supported type name
do
  -- typeOf(name) checks type identity. Supports the class name and "Object".
  local aabb_tree_obj = lurek.math.aabbTree()
  lurek.log.info("is LAabbTree: " .. tostring(aabb_tree_obj:typeOf("LAabbTree")), "math")
  lurek.log.info("is wrong: " .. tostring(aabb_tree_obj:typeOf("Unknown")), "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this Bezier curve handle
do
  local bezier_curve_obj = lurek.math.newBezierCurve({0,0, 100,50, 200,0})
  local t = bezier_curve_obj:type()
  lurek.log.info("LBezierCurve:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this Bezier curve handle matches a supported type name
do
  local bezier_curve_obj = lurek.math.newBezierCurve({0,0, 100,50, 200,0})
  lurek.log.info("is LBezierCurve: " .. tostring(bezier_curve_obj:typeOf("LBezierCurve")), "math")
  lurek.log.info("is wrong: " .. tostring(bezier_curve_obj:typeOf("Unknown")), "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this spline handle
do
  local catmull_rom_obj = lurek.math.catmullRom({{0,0},{100,50},{200,0},{300,50}})
  local t = catmull_rom_obj:type()
  lurek.log.info("LCatmullRom:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this spline handle matches a supported type name
do
  local catmull_rom_obj = lurek.math.catmullRom({{0,0},{100,50},{200,0},{300,50}})
  lurek.log.info("is LCatmullRom: " .. tostring(catmull_rom_obj:typeOf("LCatmullRom")), "math")
  lurek.log.info("is wrong: " .. tostring(catmull_rom_obj:typeOf("Unknown")), "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this circle handle
do
  local circle_obj = lurek.math.newCircle(0, 0, 50)
  local t = circle_obj:type()
  lurek.log.info("LCircle:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this circle handle matches a supported type name
do
  local circle_obj = lurek.math.newCircle(0, 0, 50)
  lurek.log.info("is LCircle: " .. tostring(circle_obj:typeOf("LCircle")), "math")
  lurek.log.info("is wrong: " .. tostring(circle_obj:typeOf("Unknown")), "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this spline handle
do
  local hermite_obj = lurek.math.hermite(0, 0, 1, 0, 100, 0, 1, 0)
  local t = hermite_obj:type()
  lurek.log.info("LHermite:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this spline handle matches a supported type name
do
  local hermite_obj = lurek.math.hermite(0, 0, 1, 0, 100, 0, 1, 0)
  lurek.log.info("is LHermite: " .. tostring(hermite_obj:typeOf("LHermite")), "math")
  lurek.log.info("is wrong: " .. tostring(hermite_obj:typeOf("Unknown")), "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this noise generator handle
do
  local noise_generator_obj = lurek.math.newNoiseGenerator(42)
  local t = noise_generator_obj:type()
  lurek.log.info("LNoiseGenerator:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this noise generator handle matches a supported type name
do
  local noise_generator_obj = lurek.math.newNoiseGenerator(42)
  lurek.log.info("is LNoiseGenerator: " .. tostring(noise_generator_obj:typeOf("LNoiseGenerator")), "math")
  lurek.log.info("is wrong: " .. tostring(noise_generator_obj:typeOf("Unknown")), "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this random generator handle
do
  local random_generator_obj = lurek.math.newRandomGenerator(42)
  local t = random_generator_obj:type()
  lurek.log.info("LRandomGenerator:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this random generator handle matches a supported type name
do
  local random_generator_obj = lurek.math.newRandomGenerator(42)
  lurek.log.info("is LRandomGenerator: " .. tostring(random_generator_obj:typeOf("LRandomGenerator")), "math")
  lurek.log.info("is wrong: " .. tostring(random_generator_obj:typeOf("Unknown")), "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this spatial hash handle
do
  local spatial_hash_obj = lurek.math.newSpatialHash(64)
  local t = spatial_hash_obj:type()
  lurek.log.info("LSpatialHash:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this spatial hash handle matches a supported type name
do
  local spatial_hash_obj = lurek.math.newSpatialHash(64)
  lurek.log.info("is LSpatialHash: " .. tostring(spatial_hash_obj:typeOf("LSpatialHash")), "math")
  lurek.log.info("is wrong: " .. tostring(spatial_hash_obj:typeOf("Unknown")), "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this transform handle
do
  local transform_obj = lurek.math.newTransform()
  local t = transform_obj:type()
  lurek.log.info("LTransform:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this transform handle matches a supported type name
do
  local transform_obj = lurek.math.newTransform()
  lurek.log.info("is LTransform: " .. tostring(transform_obj:typeOf("LTransform")), "math")
  lurek.log.info("is wrong: " .. tostring(transform_obj:typeOf("Unknown")), "math")
end

--@api-stub: LAabbTree:type
-- Returns the type name of this object
do
  local tween_obj = lurek.tween.tween(0.5, {x=0}, {x=100})
  local t = tween_obj:type()
  lurek.log.info("LTween:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Checks whether this object matches the given type name
do
  local tween_obj = lurek.tween.tween(0.5, {x=0}, {x=100})
  lurek.log.info("is LTween: " .. tostring(tween_obj:typeOf("LTween")), "math")
  lurek.log.info("is wrong: " .. tostring(tween_obj:typeOf("Unknown")), "math")
end

--@api-stub: LVec2:fromAngle
-- Performs the from angle operation on this vec2.
do
  -- fromAngle(radians) creates a unit direction vector from an angle.
  -- Useful for spawning projectiles in a given direction.
  local angle = math.pi / 4   -- 45 degrees (northeast)
  local dir = lurek.math.vec2(1, 0):fromAngle(angle)
  lurek.log.info("dir.x=" .. dir.x .. " dir.y=" .. dir.y, "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this vector handle
do
  local vec2_obj = lurek.math.vec2(0, 0)
  local t = vec2_obj:type()
  lurek.log.info("LVec2:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this vector handle matches a supported type name
do
  local vec2_obj = lurek.math.vec2(0, 0)
  lurek.log.info("is LVec2: " .. tostring(vec2_obj:typeOf("LVec2")), "math")
  lurek.log.info("is wrong: " .. tostring(vec2_obj:typeOf("Unknown")), "math")
end

--@api-stub: LVec3:splat
-- Performs the splat operation on this vec3.
do
  -- splat(v) creates a Vec3 with all components set to the same value.
  -- Useful for uniform scaling or default initialization.
  local ones = lurek.math.vec3(1.0, 1.0, 1.0):splat(1.0)
  lurek.log.info("splat=" .. ones.x .. "," .. ones.y .. "," .. ones.z, "math")
end

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this vector handle
do
  local vec3_obj = lurek.math.vec3(0, 0, 0)
  local t = vec3_obj:type()
  lurek.log.info("LVec3:type = " .. t, "math")
end

--@api-stub: LAabbTree:typeOf
-- Returns whether this vector handle matches a supported type name
do
  local vec3_obj = lurek.math.vec3(0, 0, 0)
  lurek.log.info("is LVec3: " .. tostring(vec3_obj:typeOf("LVec3")), "math")
  lurek.log.info("is wrong: " .. tostring(vec3_obj:typeOf("Unknown")), "math")
end

print("content/examples/math.lua")

-- =============================================================================
-- Additional coverage stubs (fleshed out)
-- =============================================================================

--@api-stub: LCatmullRom:sample
-- Samples the spline at normalized parameter `t`.
do
  -- Evaluate a patrol path at 25% for enemy position.
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=100},{x=150,y=100},{x=200,y=0}})
  local x, y = cr:sample(0.25)
  lurek.log.debug("patrol pos=" .. x .. "," .. y, "spline")
end

--@api-stub: LCatmullRom:len
-- Returns the number of points in the spline.
do
  -- Check point count before iterating segments.
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=50},{x=100,y=0},{x=150,y=50}})
  lurek.log.info("spline points=" .. cr:len(), "spline")
end

--@api-stub: LCircle:contains
-- Returns whether this circle contains a point.
do
  -- Check if a click is inside a circular button.
  local btn = lurek.math.newCircle(200, 150, 30)
  local inside = btn:contains(210, 145)
  lurek.log.debug("click inside=" .. tostring(inside), "ui")
end

--@api-stub: LRandomGenerator:getSeed
-- Returns this generator seed. This method is available to Lua scripts.
do
  -- Display the world seed on the pause screen for sharing.
  local rng = lurek.math.newRandomGenerator(98765)
  lurek.log.info("world seed=" .. rng:getSeed(), "world")
end

--@api-stub: LRandomGenerator:setSeed
-- Resets this generator to a seed value.
do
  -- Reset RNG to replay a procedural level.
  local rng = lurek.math.newRandomGenerator(0)
  rng:setSeed(42)
  lurek.log.debug("reseeded, first roll=" .. rng:randomInt(1, 100), "rng")
end

--@api-stub: LRectPacker:clear
-- Clears packed rectangles from this packer.
do
  -- Reset atlas packer between texture atlas pages.
  local packer = lurek.math.newRectPacker(256, 256, 1)
  packer:pack(64, 64, "sprite_a")
  packer:clear()
  lurek.log.debug("packer cleared for new page", "atlas")
end

--@api-stub: LSpatialHash:insert
-- Inserts an item rectangle into the spatial hash.
do
  -- Register an enemy in the spatial index for broad-phase queries.
  local hash = lurek.math.newSpatialHash(64)
  hash:insert("goblin", 200, 150, 24, 24)
  lurek.log.debug("goblin inserted into spatial hash", "spatial")
end

--@api-stub: LSpatialHash:update
-- Updates an item rectangle in the spatial hash.
do
  -- Move an entity to a new position in the spatial index.
  local hash = lurek.math.newSpatialHash(64)
  hash:insert("player", 100, 100, 32, 32)
  hash:update("player", 120, 105, 32, 32)
  lurek.log.debug("player position updated in hash", "spatial")
end

--@api-stub: LSpatialHash:remove
-- Removes an item from the spatial hash.
do
  -- Remove a defeated enemy from the spatial index.
  local hash = lurek.math.newSpatialHash(64)
  hash:insert("enemy_1", 50, 50, 16, 16)
  hash:remove("enemy_1")
  lurek.log.debug("enemy removed from spatial hash", "spatial")
end

--@api-stub: LSpatialHash:clear
-- Clears all items from the spatial hash.
do
  -- Reset spatial index between scenes.
  local hash = lurek.math.newSpatialHash(64)
  hash:insert("a", 0, 0, 10, 10)
  hash:insert("b", 50, 50, 10, 10)
  hash:clear()
  lurek.log.debug("spatial hash cleared", "spatial")
end

--@api-stub: LTransform:translate
-- Applies a translation to this transform.
do
  -- Shift a sprite's transform by a velocity vector.
  local t = lurek.math.newTransform()
  t:translate(64, -32)
  local wx, wy = t:transformPoint(0, 0)
  lurek.log.debug("after translate origin at " .. wx .. "," .. wy, "xform")
end

--@api-stub: LTransform:rotate
-- Applies a rotation to this transform.
do
  -- Rotate a turret sprite to face a target.
  local t = lurek.math.newTransform(100, 100)
  t:rotate(math.pi / 3)
  lurek.log.debug("turret rotated 60deg", "xform")
end

--@api-stub: LTransform:scale
-- Applies scale to this transform. This method is available to Lua scripts.
do
  -- Scale a UI element for a zoom-in effect.
  local t = lurek.math.newTransform()
  t:scale(1.5, 1.5)
  lurek.log.debug("scaled 150%", "xform")
end

--@api-stub: LTransform:reset
-- Resets this transform to identity.
do
  -- Clear a transform before applying fresh camera state.
  local t = lurek.math.newTransform(50, 50, 1.0, 2, 2)
  t:reset()
  local wx, wy = t:transformPoint(10, 10)
  lurek.log.debug("after reset, 10,10 -> " .. wx .. "," .. wy, "xform")
end

--@api-stub: LTween:update
-- Advances the tween clock and returns whether it is complete.
do
  -- Advance a health bar tween by one frame's delta time.
  local tw = lurek.math.newTween(1.0, "outQuad")
  tw:addValue(0, 100)
  local done = tw:update(0.5)
  lurek.log.debug("tween done=" .. tostring(done), "anim")
end

--@api-stub: LTween:getDuration
-- Returns this tween duration. This method is available to Lua scripts.
do
  -- Display remaining animation time in a debug HUD.
  local tw = lurek.math.newTween(2.5, "linear")
  lurek.log.info("tween duration=" .. tw:getDuration() .. "s", "anim")
end

--@api-stub: LVec2:dot
-- Returns the dot product with another vector.
do
  -- Check alignment between movement direction and wall normal.
  local move = lurek.math.vec2(1, 0)
  local wall = lurek.math.vec2(0, 1)
  lurek.log.debug("alignment=" .. move:dot(wall), "physics")
end

--@api-stub: LVec2:length
-- Returns this vector length. This method is available to Lua scripts.
do
  -- Check if velocity exceeds speed limit.
  local vel = lurek.math.vec2(3, 4)
  lurek.log.debug("speed=" .. vel:length(), "physics")
end

--@api-stub: LVec2:x
-- Returns this vector x component. This method is available to Lua scripts.
do
  -- Read the horizontal component of a direction vector.
  local dir = lurek.math.vec2(0.7, 0.7)
  lurek.log.debug("dir.x=" .. dir.x, "math")
end

--@api-stub: LVec2:y
-- Returns this vector y component. This method is available to Lua scripts.
do
  -- Read the vertical component for gravity calculations.
  local gravity = lurek.math.vec2(0, 9.81)
  lurek.log.debug("gravity.y=" .. gravity.y, "physics")
end

--@api-stub: LVec2:lengthSquared
-- Returns this vector squared length.
do
  -- Compare distances without expensive sqrt.
  local offset = lurek.math.vec2(5, 5)
  if offset:lengthSquared() < 100 then
    lurek.log.debug("close enough to snap", "ui")
  end
end

--@api-stub: LVec2:normalize
-- Returns a normalized copy of this vector.
do
  -- Get a unit direction for applying speed.
  local raw = lurek.math.vec2(10, 5)
  local dir = raw:normalize()
  lurek.log.debug("unit dir=" .. dir.x .. "," .. dir.y, "math")
end

--@api-stub: LVec2:lerp
-- Returns a vector interpolated toward another vector.
do
  -- Smoothly chase a target position.
  local current = lurek.math.vec2(0, 0)
  local target = lurek.math.vec2(100, 50)
  local step = current:lerp(target, 0.1)
  lurek.log.debug("chase pos=" .. step.x .. "," .. step.y, "ai")
end

--@api-stub: LVec2:distance
-- Returns distance to another vector.
do
  -- Check if a projectile is close enough to detonate.
  local bullet = lurek.math.vec2(95, 48)
  local target = lurek.math.vec2(100, 50)
  lurek.log.debug("dist=" .. bullet:distance(target), "combat")
end

--@api-stub: LVec2:rotate
-- Returns this vector rotated by an angle.
do
  -- Rotate a shot direction by a spread angle for shotgun pellets.
  local base = lurek.math.vec2(1, 0)
  local pellet = base:rotate(0.1)
  lurek.log.debug("pellet dir=" .. pellet.x .. "," .. pellet.y, "combat")
end

--@api-stub: LVec2:cross
-- Returns the scalar 2D cross product with another vector.
do
  -- Determine winding order: positive = counter-clockwise.
  local a = lurek.math.vec2(1, 0)
  local b = lurek.math.vec2(0, 1)
  lurek.log.debug("winding=" .. a:cross(b), "geo")
end

--@api-stub: LVec3:length
-- Returns this vector length. This method is available to Lua scripts.
do
  -- Measure 3D distance for audio attenuation.
  ---@type LVec3
  local pos = lurek.math.vec3(3, 4, 0)
  lurek.log.debug("3d dist=" .. pos:length(), "audio")
end

--@api-stub: LVec3:scale
-- Returns this vector multiplied by a scalar.
do
  -- Apply speed to a normalized direction.
  ---@type LVec3
  local dir = lurek.math.vec3(0, 0, 1)
  local vel = dir:scale(50)
  lurek.log.debug("velocity z=" .. vel.z, "physics")
end
