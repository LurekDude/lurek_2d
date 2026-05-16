-- content/examples/math.lua
-- lurek.math API examples.
-- Run: cargo run -- content/examples/math.lua

--@api-stub: lurek.math.newRandomGenerator
-- Creates a deterministic random generator with an optional seed
do
  local rng = lurek.math.newRandomGenerator(1337)
  local loot_roll = rng:randomInt(1, 100)
  lurek.log.info("loot roll=" .. loot_roll, "rng")
end

--@api-stub: lurek.math.newTransform
-- Creates a 2D transform
do
  local t = lurek.math.newTransform(100, 50, math.pi / 4, 2, 2)
  local wx, wy = t:transformPoint(8, 0)
  lurek.log.debug("rotated corner at " .. wx .. "," .. wy, "xform")
end

--@api-stub: lurek.math.newBezierCurve
-- Creates a Bezier curve from a flat point table
do
  local curve = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local mid_x, mid_y = curve:evaluate(0.5)
  local d_x, d_y = curve:evaluateAtDistance(120)
  lurek.log.info("bezier midpoint " .. mid_x .. "," .. mid_y, "anim")
  lurek.log.debug("bezier distance sample " .. d_x .. "," .. d_y, "anim")
end

--@api-stub: lurek.math.newTween
-- Creates a tween with a duration and optional easing name
do
  local tw = lurek.math.newTween(0.5, "outQuad")
  tw:addValue(0, 200)
  function lurek.process(dt) tw:update(dt) end
end

--@api-stub: lurek.math.newSpatialHash
-- Creates a spatial hash index with a cell size
do
  local hash = lurek.math.newSpatialHash(64)
  hash:insert("player", 100, 100, 32, 32)
  local hits = hash:queryCircle(110, 110, 50)
end

--@api-stub: lurek.math.newNoiseGenerator
-- Creates a procedural noise generator with an optional seed
do
  local terrain = lurek.math.newNoiseGenerator(20260422)
  local h = terrain:perlin2d(3.5, 7.25)
  local map = terrain:generateMapCompute(16, 16, {octaves = 3})
  lurek.log.debug("terrain h=" .. h, "noise")
  lurek.log.debug("terrain map samples=" .. #map, "noise")
end

--@api-stub: lurek.math.newRectPacker
-- Creates a rectangle packer
do
  local packer = lurek.math.newRectPacker(256, 256, 2)
  local x, y = packer:pack(64, 64, "hero")
  lurek.log.info("packed hero at " .. tostring(x) .. "," .. tostring(y), "atlas")
end

--@api-stub: RectPacker:pack
-- Performs the pack operation on this rect packer.
do
  local packer = lurek.math.newRectPacker(128, 128, 2)
  local x, y = packer:pack(32, 24, "btn_ok")
  if x and y then
    lurek.log.debug("packed btn_ok at " .. x .. "," .. y, "atlas")
  end
end

--@api-stub: RectPacker:getPacked
-- Returns the packed of this rect packer.
do
  local packer = lurek.math.newRectPacker(128, 128, 2)
  packer:pack(20, 20, "icon_a")
  packer:pack(30, 18, "icon_b")
  local packed = packer:getPacked()
  lurek.log.debug("packed count=" .. #packed, "atlas")
end

--@api-stub: RectPacker:occupancy
-- Performs the occupancy operation on this rect packer.
do
  local packer = lurek.math.newRectPacker(128, 128, 2)
  packer:pack(32, 32, "slot1")
  local occ = packer:occupancy()
  lurek.log.debug("occupancy=" .. occ, "atlas")
end

--@api-stub: RectPacker:clear
-- Clears all items from this rect packer.
do
  local packer = lurek.math.newRectPacker(128, 128, 2)
  packer:pack(40, 16, "tmp")
  packer:clear()
  lurek.log.debug("atlas cleared", "atlas")
end

--@api-stub: lurek.math.perlin2d
-- Samples stateless 2D Perlin noise
do
  local n = lurek.math.perlin2d(0.5, 1.25, 42)
  if n > 0.6 then
    lurek.log.info("hill peak", "terrain")
  end
end

--@api-stub: lurek.math.perlin3d
-- Samples stateless 3D Perlin noise
do
  local t = 0
  function lurek.process(dt)
    t = t + dt
    local cloud = lurek.math.perlin3d(0.1, 0.2, t, 7)
    lurek.log.debug("cloud=" .. cloud, "sky")
  end
end

--@api-stub: lurek.math.simplex2d
-- Samples stateless 2D simplex noise
do
  local s = lurek.math.simplex2d(2.0, 3.0, 99)
  if s > 0 then
    lurek.log.debug("simplex above zero", "noise")
  end
end

--@api-stub: lurek.math.fbm
-- Samples stateless fractal Brownian motion noise
do
  local h = lurek.math.fbm(4.5, 2.0, 12345, 6, 2.0, 0.5)
  local altitude = math.floor(h * 1000)
  lurek.log.info("fbm altitude=" .. altitude, "world")
end

--@api-stub: lurek.math.applyEasing
-- Applies a named easing function to a normalized value
do
  local name = "outBounce"
  local eased = lurek.math.applyEasing(name, 0.75)
  lurek.log.debug(name .. "(0.75)=" .. eased, "tween")
end

--@api-stub: lurek.math.linear
-- Applies linear easing
do
  local t = 0.42
  local v = lurek.math.linear(t)
  lurek.log.debug("linear " .. t .. "=" .. v, "easing")
end

--@api-stub: lurek.math.inQuad
-- Applies quadratic ease-in
do
  local progress = 0.3
  local y = lurek.math.inQuad(progress) * 200
  lurek.log.debug("falling y=" .. y, "anim")
end

--@api-stub: lurek.math.outQuad
-- Applies quadratic ease-out
do
  local x = lurek.math.outQuad(0.6) * 480
  lurek.log.debug("panel x=" .. x, "ui")
end

--@api-stub: lurek.math.inOutQuad
-- Applies quadratic ease-in-out
do
  local t = 0.5
  local cam_x = 100 + lurek.math.inOutQuad(t) * 400
  lurek.log.debug("cam x=" .. cam_x, "cam")
end

--@api-stub: lurek.math.inCubic
-- Applies cubic ease-in
do
  local charge = lurek.math.inCubic(0.4)
  if charge > 0.5 then
    lurek.log.info("charge ready", "combat")
  end
end

--@api-stub: lurek.math.outCubic
-- Applies cubic ease-out
do
  local opacity = lurek.math.outCubic(0.8)
  lurek.log.debug("tooltip alpha=" .. opacity, "ui")
end

--@api-stub: lurek.math.inOutCubic
-- Applies cubic ease-in-out
do
  local t = lurek.math.inOutCubic(0.25)
  local panel_y = 600 - t * 400
  lurek.log.debug("panel y=" .. panel_y, "ui")
end

--@api-stub: lurek.math.inQuart
-- Applies quartic ease-in
do
  local v = lurek.math.inQuart(0.7)
  lurek.log.debug("inQuart=" .. v, "easing")
end

--@api-stub: lurek.math.outQuart
-- Applies quartic ease-out
do
  local v = lurek.math.outQuart(0.2)
  lurek.log.debug("outQuart=" .. v, "easing")
end

--@api-stub: lurek.math.inOutQuart
-- Applies quartic ease-in-out
do
  local v = lurek.math.inOutQuart(0.5)
  lurek.log.debug("inOutQuart=" .. v, "easing")
end

--@api-stub: lurek.math.inSine
-- Applies sine ease-in
do
  local pulse = lurek.math.inSine(0.4)
  lurek.log.debug("pulse=" .. pulse, "fx")
end

--@api-stub: lurek.math.outSine
-- Applies sine ease-out
do
  local v = lurek.math.outSine(0.6)
  lurek.log.debug("icon alpha=" .. v, "ui")
end

--@api-stub: lurek.math.inOutSine
-- Applies sine ease-in-out
do
  local v = lurek.math.inOutSine(0.5)
  lurek.log.debug("drift=" .. v, "bg")
end

--@api-stub: lurek.math.inExpo
-- Applies exponential ease-in
do
  local v = lurek.math.inExpo(0.85)
  lurek.log.debug("inExpo=" .. v, "fx")
end

--@api-stub: lurek.math.outExpo
-- Applies exponential ease-out
do
  local v = lurek.math.outExpo(0.15)
  lurek.log.debug("outExpo=" .. v, "fx")
end

--@api-stub: lurek.math.inOutExpo
-- Applies exponential ease-in-out
do
  local v = lurek.math.inOutExpo(0.5)
  lurek.log.debug("inOutExpo=" .. v, "fx")
end

--@api-stub: lurek.math.inElastic
-- Applies elastic ease-in
do
  local v = lurek.math.inElastic(0.8)
  lurek.log.debug("inElastic=" .. v, "anim")
end

--@api-stub: lurek.math.outElastic
-- Applies elastic ease-out
do
  local v = lurek.math.outElastic(0.6)
  lurek.log.debug("button bounce=" .. v, "ui")
end

--@api-stub: lurek.math.outBounce
-- Applies bounce ease-out
do
  local h = lurek.math.outBounce(0.3) * 100
  lurek.log.debug("bounce h=" .. h, "fx")
end

--@api-stub: lurek.math.inBounce
-- Applies bounce ease-in
do
  local v = lurek.math.inBounce(0.7)
  lurek.log.debug("inBounce=" .. v, "fx")
end

--@api-stub: lurek.math.inBack
-- Applies back ease-in
do
  local v = lurek.math.inBack(0.5)
  lurek.log.debug("inBack=" .. v, "ui")
end

--@api-stub: lurek.math.outBack
-- Applies back ease-out
do
  local v = lurek.math.outBack(0.5)
  lurek.log.debug("outBack=" .. v, "ui")
end

--@api-stub: lurek.math.inOutElastic
-- Applies elastic ease-in-out
do
  local v = lurek.math.inOutElastic(0.4)
  lurek.log.debug("inOutElastic=" .. v, "fx")
end

--@api-stub: lurek.math.inOutBounce
-- Applies bounce ease-in-out
do
  local v = lurek.math.inOutBounce(0.5)
  lurek.log.debug("inOutBounce=" .. v, "fx")
end

--@api-stub: lurek.math.inOutBack
-- Applies back ease-in-out
do
  local v = lurek.math.inOutBack(0.5)
  lurek.log.debug("inOutBack=" .. v, "fx")
end

--@api-stub: lurek.math.triangulate
-- Triangulates a flat polygon point table
do
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local tris = lurek.math.triangulate(poly)
  lurek.log.info("triangulated into " .. #tris .. " triangles", "geo")
end

--@api-stub: lurek.math.isConvex
-- Returns whether a flat polygon point table is convex
do
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  if lurek.math.isConvex(poly) then
    lurek.log.debug("polygon is convex", "geo")
  end
end

--@api-stub: lurek.math.gammaToLinear
-- Converts a gamma-space channel to linear space
do
  local linear = lurek.math.gammaToLinear(0.5)
  lurek.log.debug("0.5 sRGB -> " .. linear .. " linear", "color")
end

--@api-stub: lurek.math.linearToGamma
-- Converts a linear-space channel to gamma space
do
  local srgb = lurek.math.linearToGamma(0.214)
  lurek.log.debug("linear 0.214 -> " .. srgb .. " sRGB", "color")
end

--@api-stub: lurek.math.angleBetween
-- Returns the angle between two points
do
  local rad = lurek.math.angleBetween(0, 0, 100, 100)
  lurek.log.debug("angle=" .. lurek.math.deg(rad) .. " deg", "geo")
end

--@api-stub: lurek.math.circleContainsPoint
-- Returns whether a circle contains a point
do
  if lurek.math.circleContainsPoint(0, 0, 50, 30, 20) then
    lurek.log.info("inside aura", "trigger")
  end
end

--@api-stub: lurek.math.circleIntersectsCircle
-- Returns whether two circles intersect
do
  if lurek.math.circleIntersectsCircle(0, 0, 10, 8, 6, 5) then
    lurek.log.warn("orbs collided", "physics")
  end
end

--@api-stub: lurek.math.circleIntersectsLine
-- Returns circle-line intersection state and hit points when present
do
  local hit, ix, iy = lurek.math.circleIntersectsLine(0, 0, 50, -100, 0, 100, 0)
  if hit then
    lurek.log.info("laser hit at " .. ix .. "," .. iy, "fx")
  end
end

--@api-stub: lurek.math.circleIntersectsSegment
-- Returns circle-segment intersection state and hit points when present
do
  local hit, ix, iy = lurek.math.circleIntersectsSegment(20, 0, 5, 0, 0, 40, 0)
  if hit then
    lurek.log.info("bullet impact " .. ix .. "," .. iy, "combat")
  end
end

--@api-stub: lurek.math.closestPointOnSegment
-- Returns the closest point on a segment to an input point
do
  local cx, cy = lurek.math.closestPointOnSegment(50, 30, 0, 0, 100, 0)
  lurek.log.debug("nearest=" .. cx .. "," .. cy, "ai")
end

--@api-stub: lurek.math.convexHull
-- Computes the convex hull for a flat point table
do
  local pts = {0, 0, 100, 0, 50, 50, 100, 100, 0, 100}
  local hull = lurek.math.convexHull(pts)
  lurek.log.info("hull verts=" .. (#hull / 2), "geo")
end

--@api-stub: lurek.math.delaunayTriangulate
-- Computes Delaunay triangles for a flat point table
do
  local pts = {0, 0, 100, 0, 50, 80, 60, 30}
  local tris = lurek.math.delaunayTriangulate(pts)
  lurek.log.info("delaunay tris=" .. #tris, "geo")
end

--@api-stub: lurek.math.lineIntersect
-- Returns intersection point for two infinite lines when present
do
  local ix, iy = lurek.math.lineIntersect(0, 0, 100, 100, 0, 100, 100, 0)
  if ix then
    lurek.log.debug("cross at " .. ix .. "," .. iy, "geo")
  end
end

--@api-stub: lurek.math.pointInPolygon
-- Returns whether a point lies inside a polygon
do
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  if lurek.math.pointInPolygon(poly, 50, 50) then
    lurek.log.info("inside zone", "trigger")
  end
end

--@api-stub: lurek.math.polygonArea
-- Computes signed area for a flat polygon point table
do
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local area = lurek.math.polygonArea(poly)
  lurek.log.info("polygon area=" .. math.abs(area), "geo")
end

--@api-stub: lurek.math.polygonCentroid
-- Computes the centroid for a flat polygon point table
do
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local cx, cy = lurek.math.polygonCentroid(poly)
  lurek.log.debug("centroid " .. cx .. "," .. cy, "geo")
end

--@api-stub: lurek.math.segmentIntersectsSegment
-- Returns whether two segments intersect and their intersection point when present
do
  local hit, ix, iy = lurek.math.segmentIntersectsSegment(0, 0, 100, 0, 50, -50, 50, 50)
  if hit then
    lurek.log.info("blade crossed " .. ix .. "," .. iy, "combat")
  end
end

--@api-stub: lurek.math.bresenham
-- Returns integer grid points along a Bresenham line
do
  local pts = lurek.math.bresenham(0, 0, 5, 3)
  lurek.log.info("bresenham steps=" .. #pts, "tile")
end

--@api-stub: lurek.math.rad
-- Converts degrees to radians
do
  local turn_deg = 90
  local turn_rad = lurek.math.rad(turn_deg)
  lurek.log.debug(turn_deg .. " deg = " .. turn_rad .. " rad", "math")
end

--@api-stub: lurek.math.deg
-- Converts radians to degrees
do
  local heading = lurek.math.deg(math.pi / 2)
  lurek.log.info("heading=" .. heading .. " deg", "compass")
end

--@api-stub: lurek.math.sin
-- Returns sine of an angle
do
  local t = 0
  function lurek.process(dt)
    t = t + dt
    local bob = lurek.math.sin(t * 2) * 8
    lurek.log.debug("bob=" .. bob, "fx")
  end
end

--@api-stub: lurek.math.cos
-- Returns cosine of an angle
do
  local t = 1.5
  local x = lurek.math.cos(t) * 50
  lurek.log.debug("orbit x=" .. x, "fx")
end

--@api-stub: lurek.math.tan
-- Returns tangent of an angle
do
  local slope = lurek.math.tan(math.pi / 6)
  lurek.log.debug("30deg slope=" .. slope, "math")
end

--@api-stub: lurek.math.asin
-- Returns arcsine of a value
do
  local angle = lurek.math.asin(0.5)
  lurek.log.debug("asin(0.5)=" .. lurek.math.deg(angle), "math")
end

--@api-stub: lurek.math.acos
-- Returns arccosine of a value
do
  local angle = lurek.math.acos(0.0)
  lurek.log.debug("acos(0)=" .. lurek.math.deg(angle), "math")
end

--@api-stub: lurek.math.atan
-- Returns arctangent or two-argument arctangent
do
  local a = lurek.math.atan(1.0)
  local b = lurek.math.atan(1.0, -1.0)
  lurek.log.debug("atan results " .. a .. " " .. b, "math")
end

--@api-stub: lurek.math.atan2
-- Returns two-argument arctangent
do
  local dx, dy = 100 - 0, 50 - 0
  local heading = lurek.math.atan2(dy, dx)
  lurek.log.info("heading rad=" .. heading, "ai")
end

--@api-stub: lurek.math.sqrt
-- Returns square root of a value
do
  local hyp = lurek.math.sqrt(3 * 3 + 4 * 4)
  lurek.log.debug("hyp=" .. hyp, "math")
end

--@api-stub: lurek.math.abs
-- Returns absolute value
do
  local axis = -0.7
  if lurek.math.abs(axis) > 0.2 then
    lurek.log.debug("axis active", "input")
  end
end

--@api-stub: lurek.math.floor
-- Returns floor of a value
do
  local raw_x = 123.7
  local pixel_x = lurek.math.floor(raw_x)
  lurek.log.debug("pixel x=" .. pixel_x, "render")
end

--@api-stub: lurek.math.ceil
-- Returns ceiling of a value
do
  local dmg = lurek.math.ceil(2.3)
  lurek.log.info("damage=" .. dmg, "combat")
end

--@api-stub: lurek.math.round
-- Returns rounded value
do
  local snapped = lurek.math.round(127.5)
  lurek.log.debug("rounded=" .. snapped, "ui")
end

--@api-stub: lurek.math.exp
-- Returns exponential of a value
do
  local decay = lurek.math.exp(-0.5)
  lurek.log.debug("decay=" .. decay, "math")
end

--@api-stub: lurek.math.log
-- Returns natural logarithm or logarithm with a supplied base
do
  local db = 20 * lurek.math.log(0.5, 10)
  lurek.log.debug("0.5 -> " .. db .. " dB", "audio")
end

--@api-stub: lurek.math.pow
-- Raises a value to a power
do
  local energy = lurek.math.pow(2.0, 8)
  lurek.log.debug("2^8=" .. energy, "math")
end

--@api-stub: lurek.math.min
-- Returns the smallest supplied value
do
  local function current_hp_or_default(v) return v end
  local clamp_hp = lurek.math.min(100, current_hp_or_default(85), 90)
  lurek.log.debug("hp=" .. clamp_hp, "combat")
end

--@api-stub: lurek.math.max
-- Returns the largest supplied value
do
  local final = lurek.math.max(1, 5 - 7)
  lurek.log.debug("final dmg=" .. final, "combat")
end

--@api-stub: lurek.math.clamp
-- Clamps a value to a range
do
  local volume = lurek.math.clamp(1.4, 0, 1)
  lurek.log.debug("clamped vol=" .. volume, "audio")
end

--@api-stub: lurek.math.sign
-- Returns the sign of a value
do
  local axis = -0.4
  local dir = lurek.math.sign(axis)
  lurek.log.debug("walk dir=" .. dir, "input")
end

--@api-stub: lurek.math.fmod
-- Returns floating-point remainder
do
  local wrapped = lurek.math.fmod(7.5, lurek.math.tau)
  lurek.log.debug("wrapped=" .. wrapped, "math")
end

--@api-stub: lurek.math.lerp
-- Linearly interpolates between two values
do
  local hp_bar = lurek.math.lerp(0, 200, 0.42)
  lurek.log.debug("hp bar pixels=" .. hp_bar, "ui")
end

--@api-stub: lurek.math.distance
-- Returns Euclidean distance between two points
do
  local d = lurek.math.distance(0, 0, 3, 4)
  if d < 10 then
    lurek.log.debug("near target", "ai")
  end
end

--@api-stub: lurek.math.distanceSq
-- Returns squared Euclidean distance between two points
do
  local d2 = lurek.math.distanceSq(0, 0, 3, 4)
  if d2 < 100 then
    lurek.log.debug("within 10 units", "ai")
  end
end

--@api-stub: lurek.math.random
-- Returns a Lua math random value, optionally scaled to one or two bounds
do
  local rolled = lurek.math.random(1, 6)
  lurek.log.info("dice=" .. rolled, "rng")
end

--@api-stub: lurek.math.randomInt
-- Returns a Lua math random integer in an inclusive range
do
  local slot = lurek.math.randomInt(1, 8)
  lurek.log.debug("loot slot=" .. slot, "rng")
end

--@api-stub: lurek.math.simplexNoise
-- Samples 2D or 3D simplex noise
do
  local n = lurek.math.simplexNoise(0.5, 1.5, 0.0)
  lurek.log.debug("simplex=" .. n, "noise")
end

--@api-stub: lurek.math.vec2
-- Creates a 2D vector
do
  local pos = lurek.math.vec2(3, 4)
  local len = pos:length()
  lurek.log.debug("pos length=" .. len, "math")
end

--@api-stub: lurek.math.Vec2
-- Creates a 2D vector
do
  local v = lurek.math.Vec2(10, 20)
  local n = v:normalize()
  lurek.log.debug("normalised x=" .. n.x, "math")
end

--@api-stub: lurek.math.vec3
-- Creates a 3D vector
do
  ---@type LVec3
  local p = lurek.math.vec3(1, 2, 3)
  local len = p:length()
  lurek.log.debug("vec3 len=" .. len, "math")
end

--@api-stub: lurek.math.Vec3
-- Creates a 3D vector
do
  ---@type LVec3
  local p = lurek.math.Vec3(0, 0, 1)
  local s = p:scale(5)
  lurek.log.debug("scaled z=" .. s.z, "math")
end

--@api-stub: lurek.math.catmullRom
-- Creates a Catmull-Rom spline from point tables
do
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=100,y=200},{x=300,y=200},{x=400,y=0}})
  local x, y = cr:sample(0.5)
  lurek.log.debug("catmull mid " .. x .. "," .. y, "spline")
end

--@api-stub: lurek.math.hermite
-- Creates a Hermite spline from endpoints and tangents
do
  ---@type LHermite
  local h = lurek.math.hermite(0, 0, 100, 100, 50, 0, 0, 50)
  local mx, my = h:sample(0.5)
  lurek.log.debug("hermite mid " .. mx .. "," .. my, "spline")
end

--@api-stub: lurek.math.remap
-- Remaps a value from one range to another
do
  local mapped = lurek.math.remap(127, 0, 255, 0, 1)
  lurek.log.debug("normalised input=" .. mapped, "input")
end

--@api-stub: lurek.math.smoothstep
-- Applies smoothstep interpolation between two edges
do
  local fade = lurek.math.smoothstep(50, 100, 75)
  lurek.log.debug("fade=" .. fade, "fx")
end

--@api-stub: lurek.math.inverseLerp
-- Returns the interpolation factor of a value between two bounds
do
  local t = lurek.math.inverseLerp(0, 200, 50)
  lurek.log.debug("t=" .. t, "math")
end

--@api-stub: lurek.math.hslToRgb
-- Converts HSL color values to RGBA channels
do
  local r, g, b, a = lurek.math.hslToRgb(200, 0.7, 0.5)
  lurek.log.debug("rgb " .. r .. "," .. g .. "," .. b, "color")
end

--@api-stub: lurek.math.fromHex
-- Converts a hex color string to RGBA channels
do
  local r, g, b, a = lurek.math.fromHex("#ff8800")
  lurek.log.debug("hex -> " .. r .. "," .. g .. "," .. b, "color")
end

--@api-stub: lurek.math.rgbToHsl
-- Converts RGB channels to HSL values
do
  local h, s, l = lurek.math.rgbToHsl(1.0, 0.5, 0.0)
  lurek.log.debug("hsl " .. h .. "," .. s .. "," .. l, "color")
end

--@api-stub: lurek.math.rectUnion
-- Returns the union rectangle for two rectangles
do
  local x, y, w, h = lurek.math.rectUnion(0, 0, 50, 50, 30, 30, 60, 60)
  lurek.log.debug("union " .. w .. "x" .. h, "ui")
end

--@api-stub: lurek.math.rectFromCenter
-- Creates a rectangle tuple from center coordinates and size
do
  local x, y, w, h = lurek.math.rectFromCenter(100, 100, 32, 32)
  lurek.log.debug("rect " .. x .. "," .. y, "geo")
end

--@api-stub: lurek.math.polygonClip
-- Clips a flat polygon point table against a plane
do
  local poly = {0, 0, 100, 0, 100, 100, 0, 100}
  local clipped = lurek.math.polygonClip(poly, 1, 0, 50)
  lurek.log.debug("clipped verts=" .. (#clipped / 2), "geo")
end

--@api-stub: lurek.math.aabbTree
-- Creates an empty AABB tree
do
  local tree = lurek.math.aabbTree()
  tree:insert(1, 0, 0, 32, 32)
  lurek.log.debug("tree size=" .. tree:len(), "physics")
end

--@api-stub: lurek.math.newCircle
-- Creates a circle primitive
do
  local c = lurek.math.newCircle(0, 0, 25)
  if c:contains(10, 5) then
    lurek.log.debug("inside circle", "geo")
  end
end

--@api-stub: lurek.math.polygonIntersection
-- Returns polygon intersection points for two polygon tables
do
  local a = {{x=0,y=0},{x=100,y=0},{x=100,y=100},{x=0,y=100}}
  local b = {{x=50,y=50},{x=150,y=50},{x=150,y=150},{x=50,y=150}}
  local hit = lurek.math.polygonIntersection(a, b)
  lurek.log.info("overlap verts=" .. #hit, "geo")
end

--@api-stub: lurek.math.polygonUnion
-- Returns polygon union points for two polygon tables
do
  local a = {{x=0,y=0},{x=100,y=0},{x=100,y=100},{x=0,y=100}}
  local b = {{x=80,y=80},{x=180,y=80},{x=180,y=180},{x=80,y=180}}
  local u = lurek.math.polygonUnion(a, b)
  lurek.log.info("union verts=" .. #u, "geo")
end

--@api-stub: lurek.math.polygonDifference
-- Returns polygon difference points for two polygon tables
do
  local a = {{x=0,y=0},{x=100,y=0},{x=100,y=100},{x=0,y=100}}
  local b = {{x=20,y=20},{x=80,y=20},{x=80,y=80},{x=20,y=80}}
  local diff = lurek.math.polygonDifference(a, b)
  lurek.log.info("diff verts=" .. #diff, "geo")
end

--@api-stub: lurek.math.voronoi
-- Builds Voronoi cells from a polygon-style point table
do
  local seeds = {{x=0,y=0},{x=100,y=0},{x=50,y=80}}
  local cells = lurek.math.voronoi(seeds)
  lurek.log.info("voronoi cells=" .. #cells, "geo")
end

--@api-stub: Vec2:dot
-- Performs the dot operation on this vec2.
do
  local a = lurek.math.vec2(1, 0)
  local b = lurek.math.vec2(0, 1)
  lurek.log.debug("dot=" .. a:dot(b), "math")
end

--@api-stub: Vec2:length
-- Performs the length operation on this vec2.
do
  local v = lurek.math.vec2(3, 4)
  local len = v:length()
  lurek.log.info("len=" .. len, "math")
end

--@api-stub: Vec2:x
-- Performs the x operation on this vec2.
do
  local v = lurek.math.vec2(7, 9)
  local x = v.x
  lurek.log.debug("x=" .. x, "math")
end

--@api-stub: Vec2:y
-- Performs the y operation on this vec2.
do
  local v = lurek.math.vec2(7, 9)
  local y = v.y
  lurek.log.debug("y=" .. y, "math")
end

--@api-stub: Vec2:lengthSquared
-- Performs the length squared operation on this vec2.
do
  local v = lurek.math.vec2(3, 4)
  if v:lengthSquared() > 25 then
    lurek.log.debug("vector longer than 5", "math")
  end
end

--@api-stub: Vec2:normalize
-- Performs the normalize operation on this vec2.
do
  local dir = lurek.math.vec2(10, 0):normalize()
  lurek.log.debug("dir x=" .. dir.x, "math")
end

--@api-stub: Vec2:normalized
-- Performs the normalized operation on this vec2.
do
  local n = lurek.math.vec2(0, 5):normalized()
  lurek.log.debug("n.y=" .. n.y, "math")
end

--@api-stub: Vec2:lerp
-- Performs the lerp operation on this vec2.
do
  local a = lurek.math.vec2(0, 0)
  local b = lurek.math.vec2(100, 0)
  local mid = a:lerp(b, 0.5)
  lurek.log.debug("mid x=" .. mid.x, "math")
end

--@api-stub: Vec2:distance
-- Performs the distance operation on this vec2.
do
  local a = lurek.math.vec2(0, 0)
  local b = lurek.math.vec2(3, 4)
  lurek.log.info("dist=" .. a:distance(b), "math")
end

--@api-stub: Vec2:angle
-- Performs the angle operation on this vec2.
do
  local v = lurek.math.vec2(0, 1)
  lurek.log.debug("angle=" .. lurek.math.deg(v:angle()), "math")
end

--@api-stub: Vec2:rotate
-- Performs the rotate operation on this vec2.
do
  local v = lurek.math.vec2(10, 0)
  local r = v:rotate(math.pi / 2)
  lurek.log.debug("rotated x=" .. r.x .. " y=" .. r.y, "math")
end

--@api-stub: Vec2:perpendicular
-- Performs the perpendicular operation on this vec2.
do
  local n = lurek.math.vec2(1, 0):perpendicular()
  lurek.log.debug("perp y=" .. n.y, "math")
end

--@api-stub: Vec2:cross
-- Performs the cross operation on this vec2.
do
  local a = lurek.math.vec2(1, 0)
  local b = lurek.math.vec2(0, 1)
  lurek.log.debug("cross=" .. a:cross(b), "math")
end

--@api-stub: Vec2:reflect
-- Performs the reflect operation on this vec2.
do
  local incoming = lurek.math.vec2(1, -1)
  local floor = lurek.math.vec2(0, 1)
  local bounced = incoming:reflect(floor)
  lurek.log.debug("bounce y=" .. bounced.y, "physics")
end

--@api-stub: Vec3:length
-- Performs the length operation on this vec3.
do
  ---@type LVec3
  local v = lurek.math.vec3(1, 2, 2)
  lurek.log.debug("len=" .. v:length(), "math")
end

--@api-stub: Vec3:lengthSquared
-- Performs the length squared operation on this vec3.
do
  ---@type LVec3
  local v = lurek.math.vec3(2, 2, 1)
  lurek.log.debug("len2=" .. v:lengthSquared(), "math")
end

--@api-stub: Vec3:normalize
-- Performs the normalize operation on this vec3.
do
  ---@type LVec3
  local v = lurek.math.vec3(0, 0, 5)
  local n = v:normalize()
  lurek.log.debug("n.z=" .. n.z, "math")
end

--@api-stub: Vec3:dot
-- Performs the dot operation on this vec3.
do
  ---@type LVec3
  local n = lurek.math.vec3(0, 1, 0)
  ---@type LVec3
  local l = lurek.math.vec3(0, 1, 0)
  lurek.log.debug("ndotl=" .. n:dot(l), "light")
end

--@api-stub: Vec3:cross
-- Performs the cross operation on this vec3.
do
  ---@type LVec3
  local x = lurek.math.vec3(1, 0, 0)
  ---@type LVec3
  local y = lurek.math.vec3(0, 1, 0)
  local z = x:cross(y)
  lurek.log.debug("z.z=" .. z.z, "math")
end

--@api-stub: Vec3:lerp
-- Performs the lerp operation on this vec3.
do
  ---@type LVec3
  local a = lurek.math.vec3(0, 0, 0)
  ---@type LVec3
  local b = lurek.math.vec3(10, 10, 10)
  local m = a:lerp(b, 0.5)
  lurek.log.debug("mid.x=" .. m.x, "math")
end

--@api-stub: Vec3:distance
-- Performs the distance operation on this vec3.
do
  ---@type LVec3
  local a = lurek.math.vec3(0, 0, 0)
  ---@type LVec3
  local b = lurek.math.vec3(3, 4, 0)
  lurek.log.info("dist=" .. a:distance(b), "math")
end

--@api-stub: Vec3:add
-- Adds a  to this vec3.
do
  ---@type LVec3
  local a = lurek.math.vec3(1, 2, 3)
  ---@type LVec3
  local b = lurek.math.vec3(10, 0, 0)
  local s = a:add(b)
  lurek.log.debug("sum.x=" .. s.x, "math")
end

--@api-stub: Vec3:sub
-- Performs the sub operation on this vec3.
do
  ---@type LVec3
  local a = lurek.math.vec3(5, 5, 5)
  ---@type LVec3
  local b = lurek.math.vec3(1, 2, 3)
  local d = a:sub(b)
  lurek.log.debug("diff.z=" .. d.z, "math")
end

--@api-stub: Vec3:scale
-- Performs the scale operation on this vec3.
do
  ---@type LVec3
  local base = lurek.math.vec3(1, 0, 0)
  local v = base:scale(9.81)
  lurek.log.debug("scaled.x=" .. v.x, "physics")
end

--@api-stub: CatmullRom:sample
-- Performs the sample operation on this catmull rom.
do
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=100,y=200},{x=300,y=200},{x=400,y=0}})
  local x, y = cr:sample(0.25)
  lurek.log.debug("sample " .. x .. "," .. y, "spline")
end

--@api-stub: CatmullRom:sampleSegment
-- Performs the sample segment operation on this catmull rom.
do
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=20},{x=100,y=0},{x=150,y=20}})
  local x, y = cr:sampleSegment(0, 0.5)
  lurek.log.debug("seg0 mid " .. x .. "," .. y, "spline")
end

--@api-stub: CatmullRom:len
-- Performs the len operation on this catmull rom.
do
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=10,y=10},{x=20,y=0},{x=30,y=10}})
  lurek.log.info("control points=" .. cr:len(), "spline")
end

--@api-stub: CatmullRom:addPoint
-- Adds a point to this catmull rom.
do
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=50},{x=100,y=0},{x=150,y=50}})
  cr:addPoint(200, 0)
  lurek.log.debug("after add count=" .. cr:len(), "spline")
end

--@api-stub: CatmullRom:removePoint
-- Removes a point from this catmull rom.
do
  ---@type LCatmullRom
  local cr = lurek.math.catmullRom({{x=0,y=0},{x=50,y=50},{x=100,y=0},{x=150,y=50}})
  local rx, ry = cr:removePoint(1)
  lurek.log.debug("removed " .. rx .. "," .. ry, "spline")
end

--@api-stub: Hermite:sample
-- Performs the sample operation on this hermite.
do
  ---@type LHermite
  local h = lurek.math.hermite(0, 0, 100, 100, 50, 0, 0, 50)
  local x, y = h:sample(0.5)
  lurek.log.debug("hermite mid " .. x .. "," .. y, "spline")
end

--@api-stub: RandomGenerator:random
-- Performs the random operation on this random generator.
do
  local rng = lurek.math.newRandomGenerator(42)
  local v = rng:random()
  lurek.log.debug("u01=" .. v, "rng")
end

--@api-stub: RandomGenerator:randomFloat
-- Performs the random float operation on this random generator.
do
  local rng = lurek.math.newRandomGenerator(7)
  local angle = rng:randomFloat(0, math.pi * 2)
  lurek.log.debug("angle=" .. angle, "rng")
end

--@api-stub: RandomGenerator:randomInt
-- Performs the random int operation on this random generator.
do
  local rng = lurek.math.newRandomGenerator(99)
  local roll = rng:randomInt(1, 20)
  lurek.log.info("d20=" .. roll, "rng")
end

--@api-stub: RandomGenerator:getSeed
-- Returns the seed of this random generator.
do
  local rng = lurek.math.newRandomGenerator(20260422)
  local seed = rng:getSeed()
  lurek.log.info("rng seed=" .. seed, "rng")
end

--@api-stub: RandomGenerator:setSeed
-- Sets the seed of this random generator.
do
  local rng = lurek.math.newRandomGenerator(0)
  rng:setSeed(12345)
  lurek.log.debug("after reseed=" .. rng:randomInt(1, 6), "rng")
end

--@api-stub: RandomGenerator:getState
-- Returns the state of this random generator.
do
  local rng = lurek.math.newRandomGenerator(77)
  local snapshot = rng:getState()
  lurek.log.debug("state bytes=" .. #snapshot, "rng")
end

--@api-stub: RandomGenerator:setState
-- Sets the state of this random generator.
do
  local rng = lurek.math.newRandomGenerator(77)
  local snap = rng:getState()
  rng:random()
  rng:setState(snap)
end

--@api-stub: Transform:translate
-- Performs the translate operation on this transform.
do
  local t = lurek.math.newTransform()
  t:translate(50, -10)
  lurek.log.debug("translated", "xform")
end

--@api-stub: Transform:rotate
-- Performs the rotate operation on this transform.
do
  local t = lurek.math.newTransform()
  t:rotate(math.pi / 4)
  lurek.log.debug("rotated 45deg", "xform")
end

--@api-stub: Transform:scale
-- Performs the scale operation on this transform.
do
  local t = lurek.math.newTransform()
  t:scale(2, 0.5)
  lurek.log.debug("scaled", "xform")
end

--@api-stub: Transform:shear
-- Performs the shear operation on this transform.
do
  local t = lurek.math.newTransform()
  t:shear(0.2, 0)
  lurek.log.debug("sheared", "xform")
end

--@api-stub: Transform:reset
-- Resets this transform to its default state.
do
  local t = lurek.math.newTransform(10, 20, 0.5)
  t:reset()
  lurek.log.debug("reset to identity", "xform")
end

--@api-stub: Transform:transformPoint
-- Performs the transform point operation on this transform.
do
  local t = lurek.math.newTransform(100, 50, math.pi / 2)
  local wx, wy = t:transformPoint(10, 0)
  lurek.log.debug("world " .. wx .. "," .. wy, "xform")
end

--@api-stub: Transform:inverseTransformPoint
-- Performs the inverse transform point operation on this transform.
do
  local t = lurek.math.newTransform(50, 50, math.pi / 4)
  local lx, ly = t:inverseTransformPoint(100, 50)
  lurek.log.debug("local " .. lx .. "," .. ly, "xform")
end

--@api-stub: Transform:inverse
-- Performs the inverse operation on this transform.
do
  local t = lurek.math.newTransform(10, 20, 0.3)
  local inv = t:inverse()
  lurek.log.debug("got inverse", "xform")
end

--@api-stub: Transform:clone
-- Performs the clone operation on this transform.
do
  local t = lurek.math.newTransform(10, 20)
  local dup = t:clone()
  dup:translate(5, 0)
end

--@api-stub: Transform:getMatrix
-- Returns the matrix of this transform.
do
  local t = lurek.math.newTransform(0, 0, math.pi / 2)
  local m = t:getMatrix()
  lurek.log.debug("matrix elems=" .. #m, "xform")
end

--@api-stub: Transform:decompose
-- Performs the decompose operation on this transform.
do
  local t = lurek.math.newTransform(100, 50, math.pi / 4, 2, 2)
  local x, y, angle, sx, sy = t:decompose()
  lurek.log.info("xform " .. x .. "," .. y .. " a=" .. angle, "xform")
end

--@api-stub: BezierCurve:evaluate
-- Performs the evaluate operation on this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local x, y = c:evaluate(0.25)
  lurek.log.debug("eval " .. x .. "," .. y, "spline")
end

--@api-stub: BezierCurve:evaluateAtDistance
-- Performs the evaluate at distance operation on this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local x, y = c:evaluateAtDistance(120, 128)
  lurek.log.debug("eval@dist " .. x .. "," .. y, "spline")
end

--@api-stub: BezierCurve:render
-- Draws or renders this bezier curve to the current render target.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local pts = c:render(32)
  lurek.log.info("polyline points=" .. #pts, "spline")
end

--@api-stub: BezierCurve:getDerivative
-- Returns the derivative of this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local d = c:getDerivative()
  lurek.log.debug("derivative ready", "spline")
end

--@api-stub: BezierCurve:getControlPoint
-- Returns the control point of this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local x, y = c:getControlPoint(2)
  lurek.log.debug("cp2=" .. x .. "," .. y, "spline")
end

--@api-stub: BezierCurve:removeControlPoint
-- Removes a control point from this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local ok = c:removeControlPoint(3)
  lurek.log.debug("removed=" .. tostring(ok), "spline")
end

--@api-stub: BezierCurve:getControlPointCount
-- Returns the number of control point items in this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local n = c:getControlPointCount()
  lurek.log.info("cp count=" .. n, "spline")
end

--@api-stub: BezierCurve:length
-- Performs the length operation on this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  local len = c:length()
  lurek.log.info("arc len=" .. len, "spline")
end

--@api-stub: BezierCurve:translate
-- Performs the translate operation on this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  c:translate(10, 5)
  lurek.log.debug("translated", "spline")
end

--@api-stub: BezierCurve:rotate
-- Performs the rotate operation on this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  c:rotate(math.pi / 6, 0, 0)
  lurek.log.debug("rotated", "spline")
end

--@api-stub: BezierCurve:scale
-- Performs the scale operation on this bezier curve.
do
  local c = lurek.math.newBezierCurve({0, 0, 100, 200, 300, 200, 400, 0})
  c:scale(2.0, 0, 0)
  lurek.log.debug("scaled", "spline")
end
-- do  -- Tween:update
--   local tw = lurek.math.newTween(1.0, "outQuad")
--   function lurek.process(dt)
--     if tw:update(dt) then lurek.log.info("done", "tween") end
--   end
-- end

--@api-stub: Tween:reset
-- Resets this tween to its default state.
do
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 100)
  tw:reset()
end

--@api-stub: Tween:getValue
-- Returns the value of this tween.
do
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 200)
  local v = tw:getValue(1)
  lurek.log.debug("value=" .. v, "tween")
end

--@api-stub: Tween:getAllValues
-- Returns all values values associated with this tween.
do
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 1)
  local all = tw:getAllValues()
  lurek.log.debug("count=" .. #all, "tween")
end

--@api-stub: Tween:isComplete
-- Returns true if this tween complete.
do
  local tw = lurek.math.newTween(0.2)
  if tw:isComplete() then
    lurek.log.debug("ready", "tween")
  end
end

--@api-stub: Tween:getValueCount
-- Returns the number of value items in this tween.
do
  local tw = lurek.math.newTween(0.5)
  tw:addValue(0, 10)
  lurek.log.info("count=" .. tw:getValueCount(), "tween")
end

--@api-stub: Tween:getEasingName
-- Returns the easing name of this tween.
do
  local tw = lurek.math.newTween(0.5, "outBack")
  lurek.log.debug("easing=" .. tw:getEasingName(), "tween")
end

--@api-stub: Tween:getTime
-- Returns the time of this tween.
do
  local tw = lurek.math.newTween(1.0)
  local pct = tw:getTime() / tw:getDuration()
  lurek.log.debug("pct=" .. pct, "tween")
end

--@api-stub: Tween:getClock
-- Returns the clock of this tween.
do
  local tw = lurek.math.newTween(1.0)
  local now = tw:getClock()
  lurek.log.debug("now=" .. now, "tween")
end

--@api-stub: Tween:setTime
-- Sets the time of this tween.
do
  local tw = lurek.math.newTween(1.0)
  tw:setTime(0.5)
  lurek.log.debug("seeked to 0.5", "tween")
end

--@api-stub: Tween:set
-- Sets the  of this tween.
do
  local tw = lurek.math.newTween(1.0)
  tw:set(0.25)
  lurek.log.debug("clock set", "tween")
end

--@api-stub: Tween:addValue
-- Adds a value to this tween.
do
  local tw = lurek.math.newTween(0.5, "outQuad")
  local idx = tw:addValue(0, 200)
  lurek.log.info("value idx=" .. idx, "tween")
end

--@api-stub: SpatialHash:remove
-- Removes a  from this spatial hash.
do
  local h = lurek.math.newSpatialHash(64)
  h:insert("npc", 0, 0, 32, 32)
  h:remove("npc")
end

--@api-stub: SpatialHash:clear
-- Clears all items from this spatial hash.
do
  local h = lurek.math.newSpatialHash(64)
  h:insert("a", 0, 0, 16, 16)
  h:clear()
end

--@api-stub: SpatialHash:getCellSize
-- Returns the cell size of this spatial hash.
do
  local h = lurek.math.newSpatialHash(96)
  local cs = h:getCellSize()
  lurek.log.debug("cell=" .. cs, "spatial")
end

--@api-stub: SpatialHash:getItemCount
-- Returns the number of item items in this spatial hash.
do
  local h = lurek.math.newSpatialHash(64)
  h:insert("a", 0, 0, 16, 16)
  lurek.log.info("items=" .. h:getItemCount(), "spatial")
end

--@api-stub: NoiseGenerator:perlin1d
-- Performs the perlin1d operation on this noise generator.
do
  local n = lurek.math.newNoiseGenerator(1)
  local wind = n:perlin1d(0.4)
  lurek.log.debug("wind=" .. wind, "weather")
end

--@api-stub: NoiseGenerator:perlin2d
-- Performs the perlin2d operation on this noise generator.
do
  local n = lurek.math.newNoiseGenerator(2)
  local h = n:perlin2d(2.5, 4.5)
  lurek.log.debug("h=" .. h, "noise")
end

--@api-stub: NoiseGenerator:perlin3d
-- Performs the perlin3d operation on this noise generator.
do
  local n = lurek.math.newNoiseGenerator(3)
  local v = n:perlin3d(1.0, 2.0, 3.0)
  lurek.log.debug("v=" .. v, "noise")
end

--@api-stub: NoiseGenerator:perlin4d
-- Performs the perlin4d operation on this noise generator.
do
  local n = lurek.math.newNoiseGenerator(4)
  local v = n:perlin4d(0.1, 0.2, 0.3, 0.4)
  lurek.log.debug("v4=" .. v, "noise")
end

--@api-stub: NoiseGenerator:simplex1d
-- Performs the simplex1d operation on this noise generator.
do
  local n = lurek.math.newNoiseGenerator(5)
  local s = n:simplex1d(0.7)
  lurek.log.debug("s1=" .. s, "noise")
end

--@api-stub: NoiseGenerator:simplex2d
-- Performs the simplex2d operation on this noise generator.
do
  local n = lurek.math.newNoiseGenerator(6)
  local s = n:simplex2d(0.4, 0.6)
  lurek.log.debug("s2=" .. s, "noise")
end

--@api-stub: NoiseGenerator:simplex3d
-- Performs the simplex3d operation on this noise generator.
do
  local n = lurek.math.newNoiseGenerator(7)
  local s = n:simplex3d(0.1, 0.2, 0.3)
  lurek.log.debug("s3=" .. s, "noise")
end

--@api-stub: NoiseGenerator:getSeed
-- Returns the seed of this noise generator.
do
  local n = lurek.math.newNoiseGenerator(2026)
  lurek.log.info("noise seed=" .. n:getSeed(), "noise")
end

--@api-stub: NoiseGenerator:setSeed
-- Sets the seed of this noise generator.
do
  local n = lurek.math.newNoiseGenerator(0)
  n:setSeed(99)
  lurek.log.debug("re-seeded", "noise")
end

--@api-stub: Circle:area
-- Performs the area operation on this circle.
do
  local c = lurek.math.newCircle(0, 0, 5)
  lurek.log.debug("area=" .. c:area(), "geo")
end

--@api-stub: Circle:perimeter
-- Performs the perimeter operation on this circle.
do
  local c = lurek.math.newCircle(0, 0, 10)
  lurek.log.debug("perimeter=" .. c:perimeter(), "geo")
end

--@api-stub: Circle:contains
-- Performs the contains operation on this circle.
do
  local c = lurek.math.newCircle(50, 50, 25)
  if c:contains(60, 60) then
    lurek.log.debug("inside", "geo")
  end
end

--@api-stub: Circle:intersects
-- Performs the intersects operation on this circle.
do
  local a = lurek.math.newCircle(0, 0, 10)
  local b = lurek.math.newCircle(15, 0, 10)
  lurek.log.debug("hit=" .. tostring(a:intersects(b)), "geo")
end

--@api-stub: Circle:aabb
-- Performs the aabb operation on this circle.
do
  local c = lurek.math.newCircle(50, 30, 10)
  local x1, y1, x2, y2 = c:aabb()
  lurek.log.debug("aabb " .. x1 .. "," .. y1 .. " to " .. x2 .. "," .. y2, "geo")
end

--@api-stub: Circle:x
-- Performs the x operation on this circle.
do
  local c = lurek.math.newCircle(72, 18, 5)
  lurek.log.debug("x=" .. c:x(), "geo")
end

--@api-stub: Circle:y
-- Performs the y operation on this circle.
do
  local c = lurek.math.newCircle(72, 18, 5)
  lurek.log.debug("y=" .. c:y(), "geo")
end

--@api-stub: Circle:radius
-- Performs the radius operation on this circle.
do
  local c = lurek.math.newCircle(0, 0, 12)
  lurek.log.info("radius=" .. c:radius(), "geo")
end

--@api-stub: AabbTree:remove
-- Removes a  from this aabb tree.
do
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 32, 32)
  local ok = t:remove(1)
  lurek.log.debug("removed=" .. tostring(ok), "physics")
end

--@api-stub: AabbTree:queryPoint
-- Performs the query point operation on this aabb tree.
do
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 32, 32)
  local ids = t:queryPoint(10, 10)
  lurek.log.info("hits=" .. #ids, "physics")
end

--@api-stub: AabbTree:contains
-- Performs the contains operation on this aabb tree.
do
  local t = lurek.math.aabbTree()
  t:insert(42, 0, 0, 16, 16)
  if t:contains(42) then
    lurek.log.debug("entry exists", "physics")
  end
end

--@api-stub: AabbTree:len
-- Performs the len operation on this aabb tree.
do
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 8, 8)
  lurek.log.info("aabb tree size=" .. t:len(), "physics")
end

--@api-stub: AabbTree:isEmpty
-- Returns true if this aabb tree contains no items.
do
  local t = lurek.math.aabbTree()
  if t:isEmpty() then
    lurek.log.debug("tree empty", "physics")
  end
end

--@api-stub: AabbTree:clear
-- Clears all items from this aabb tree.
do
  local t = lurek.math.aabbTree()
  t:insert(1, 0, 0, 16, 16)
  t:clear()
end

--@api-stub: NoiseGenerator:fbm
-- Performs the fbm operation on this noise generator.
do
  local ng = lurek.math.newNoiseGenerator(42)
  local v = ng:fbm(0.3, 0.7, 6, 2.0, 0.5)
  lurek.log.info("fbm noise: " .. v, "math")
end

--@api-stub: NoiseGenerator:generateMap
-- Performs the generate map operation on this noise generator.
do
  local ng = lurek.math.newNoiseGenerator(99)
  local map = ng:generateMap(32, 32, { scale = 0.05, offsetX = 0.0, offsetY = 0.0 })
  lurek.log.info("map size: " .. #map, "math")
end

--@api-stub: NoiseGenerator:generateMapCompute
-- Performs the generate map compute operation on this noise generator.
do
  local ng = lurek.math.newNoiseGenerator(101)
  local map = ng:generateMapCompute(16, 16, { octaves = 3, lacunarity = 2.0, gain = 0.5 })
  lurek.log.info("compute map size: " .. #map, "math")
end

--@api-stub: SpatialHash:insert
-- Performs the insert operation on this spatial hash.
do
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("entity_01", 100, 100, 32, 32)
  sh:insert("entity_02", 200, 150, 32, 32)
  lurek.log.info("items: " .. sh:getItemCount(), "math")
end

--@api-stub: AabbTree:insert
-- Performs the insert operation on this aabb tree.
do
  local tree = lurek.math.aabbTree()
  tree:insert(1, 10, 10, 50, 50)
  tree:insert(2, 80, 80, 120, 120)
  lurek.log.info("tree len: " .. tree:len(), "math")
end

--@api-stub: BezierCurve:insertControlPoint
-- Performs the insert control point operation on this bezier curve.
do
  local bc = lurek.math.newBezierCurve({0,0, 100,50, 200,0})
  bc:insertControlPoint(100, 25, 0.5)
  lurek.log.info("ctrl pts: " .. bc:getControlPointCount(), "math")
end

--@api-stub: AabbTree:query
-- Performs the query operation on this aabb tree.
do
  local tree = lurek.math.aabbTree()
  tree:insert(1, 0, 0, 40, 40)
  tree:insert(2, 60, 60, 100, 100)
  local hits = tree:query(10, 10, 50, 50)
  lurek.log.info("hits: " .. #hits, "math")
end

--@api-stub: SpatialHash:queryCircle
-- Performs the query circle operation on this spatial hash.
do
  local sh = lurek.math.newSpatialHash(32)
  sh:insert("e1", 100, 100, 16, 16)
  sh:insert("e2", 500, 500, 16, 16)
  local hits = sh:queryCircle(110, 110, 50)
  lurek.log.info("circle hits: " .. #hits, "math")
end

--@api-stub: SpatialHash:queryRect
-- Performs the query rect operation on this spatial hash.
do
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("player", 100, 100, 32, 32)
  sh:insert("enemy", 128, 100, 32, 32)
  local hits = sh:queryRect(90, 90, 170, 150)
  lurek.log.info("rect hits: " .. #hits, "math")
end

--@api-stub: SpatialHash:querySegment
-- Performs the query segment operation on this spatial hash.
do
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("wall", 200, 100, 240, 300)
  local hits = sh:querySegment(0, 200, 400, 200)
  lurek.log.info("segment hits: " .. #hits, "math")
end

--@api-stub: RandomGenerator:randomNormal
-- Performs the random normal operation on this random generator.
do
  local rng = lurek.math.newRandomGenerator(12345)
  local v = rng:randomNormal(0, 1)
  lurek.log.info("normal sample: " .. v, "math")
end

--@api-stub: NoiseGenerator:ridged
-- Performs the ridged operation on this noise generator.
do
  local ng = lurek.math.newNoiseGenerator(7)
  local v = ng:ridged(0.5, 0.5, 5, 2.0, 0.5)
  lurek.log.info("ridged: " .. v, "math")
end

--@api-stub: BezierCurve:setControlPoint
-- Sets the control point of this bezier curve.
do
  local bc = lurek.math.newBezierCurve({0,0, 100,0, 200,0})
  bc:setControlPoint(2, 100, 80)
  local cx, cy = bc:getControlPoint(2)
  lurek.log.info("ctrl pt 2: " .. cx .. "," .. cy, "math")
end

--@api-stub: Transform:setTransformation
-- Sets the transformation of this transform.
do
  local t = lurek.math.newTransform()
  t:setTransformation(100, 200, 0.5, 2.0, 2.0, 16, 16, 0, 0)
  local x, y = t:transformPoint(0, 0)
  lurek.log.info("transformed origin: " .. x .. "," .. y, "math")
end

--@api-stub: NoiseGenerator:turbulence
-- Performs the turbulence operation on this noise generator.
do
  local ng = lurek.math.newNoiseGenerator(55)
  local v = ng:turbulence(0.4, 0.6, 5, 2.0, 0.5)
  lurek.log.info("turbulence: " .. v, "math")
end

--@api-stub: Tween:update
-- Advances this tween by the given delta time.
do
  local tw = lurek.math.newTween(1.0, "inOutQuad")
  tw:addValue(0, 200)
  tw:update(0.5)
  lurek.log.info("x at t=0.5: " .. tw:getValue(1), "math")
end

--@api-stub: SpatialHash:update
-- Advances this spatial hash by the given delta time.
do
  local sh = lurek.math.newSpatialHash(64)
  sh:insert("player", 100, 100, 32, 32)
  sh:update("player", 110, 105, 32, 32)
  lurek.log.info("player position updated", "math")
end

--@api-stub: NoiseGenerator:warpDomain
-- Performs the warp domain operation on this noise generator.
do
  local ng = lurek.math.newNoiseGenerator(101)
  local wx, wy = ng:warpDomain(0.3, 0.3, 0.8)
  wx = wx or 0.0
  wy = wy or 0.0
  local v = ng:perlin2d(wx, wy)
  lurek.log.info("warped: " .. v, "math")
end

--@api-stub: NoiseGenerator:worley2d
-- Performs the worley2d operation on this noise generator.
do
  local ng = lurek.math.newNoiseGenerator(321)
  local v = ng:worley2d(0.25, 0.75)
  lurek.log.info("worley2d: " .. v, "math")
end

--@api-stub: NoiseGenerator:worley3d
-- Performs the worley3d operation on this noise generator.
do
  local ng = lurek.math.newNoiseGenerator(654)
  local v = ng:worley3d(0.1, 0.5, 0.9)
  lurek.log.info("worley3d: " .. v, "math")
end

--@api-stub: AabbTree:update
-- Advances this aabb tree by the given delta time.
do
  local tree = lurek.math.aabbTree()
  local id = 1
  tree:insert(id, 100, 100, 132, 132)
  tree:update(id, 110, 110, 142, 142)
  lurek.log.info("AABB tree updated", "math")
end

-- -----------------------------------------------------------------------------
-- Vec3 methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LAabbTree methods
-- -----------------------------------------------------------------------------

--@api-stub: LAabbTree:type
-- Returns the Lua-visible type name for this AABB tree handle
do
  local aabb_tree_obj = lurek.math.aabbTree()
  local t = aabb_tree_obj:type()
  lurek.log.info("LAabbTree:type = " .. t, "math")
end
--@api-stub: LAabbTree:typeOf
-- Returns whether this AABB tree handle matches a supported type name
do
  local aabb_tree_obj = lurek.math.aabbTree()
  lurek.log.info("is LAabbTree: " .. tostring(aabb_tree_obj:typeOf("LAabbTree")), "math")
  lurek.log.info("is wrong: " .. tostring(aabb_tree_obj:typeOf("Unknown")), "math")
end
--@api-stub: LBezierCurve:type
-- Returns the Lua-visible type name for this Bezier curve handle
do
  local bezier_curve_obj = lurek.math.newBezierCurve({0,0, 100,50, 200,0})
  local t = bezier_curve_obj:type()
  lurek.log.info("LBezierCurve:type = " .. t, "math")
end
--@api-stub: LBezierCurve:typeOf
-- Returns whether this Bezier curve handle matches a supported type name
do
  local bezier_curve_obj = lurek.math.newBezierCurve({0,0, 100,50, 200,0})
  lurek.log.info("is LBezierCurve: " .. tostring(bezier_curve_obj:typeOf("LBezierCurve")), "math")
  lurek.log.info("is wrong: " .. tostring(bezier_curve_obj:typeOf("Unknown")), "math")
end
--@api-stub: LCatmullRom:type
-- Returns the Lua-visible type name for this spline handle
do
  local catmull_rom_obj = lurek.math.catmullRom({{0,0},{100,50},{200,0},{300,50}})
  local t = catmull_rom_obj:type()
  lurek.log.info("LCatmullRom:type = " .. t, "math")
end
--@api-stub: LCatmullRom:typeOf
-- Returns whether this spline handle matches a supported type name
do
  local catmull_rom_obj = lurek.math.catmullRom({{0,0},{100,50},{200,0},{300,50}})
  lurek.log.info("is LCatmullRom: " .. tostring(catmull_rom_obj:typeOf("LCatmullRom")), "math")
  lurek.log.info("is wrong: " .. tostring(catmull_rom_obj:typeOf("Unknown")), "math")
end
--@api-stub: LCircle:type
-- Returns the Lua-visible type name for this circle handle
do
  local circle_obj = lurek.math.newCircle(0, 0, 50)
  local t = circle_obj:type()
  lurek.log.info("LCircle:type = " .. t, "math")
end
--@api-stub: LCircle:typeOf
-- Returns whether this circle handle matches a supported type name
do
  local circle_obj = lurek.math.newCircle(0, 0, 50)
  lurek.log.info("is LCircle: " .. tostring(circle_obj:typeOf("LCircle")), "math")
  lurek.log.info("is wrong: " .. tostring(circle_obj:typeOf("Unknown")), "math")
end
--@api-stub: LHermite:type
-- Returns the Lua-visible type name for this spline handle
do
  local hermite_obj = lurek.math.hermite(0, 0, 1, 0, 100, 0, 1, 0)
  local t = hermite_obj:type()
  lurek.log.info("LHermite:type = " .. t, "math")
end
--@api-stub: LHermite:typeOf
-- Returns whether this spline handle matches a supported type name
do
  local hermite_obj = lurek.math.hermite(0, 0, 1, 0, 100, 0, 1, 0)
  lurek.log.info("is LHermite: " .. tostring(hermite_obj:typeOf("LHermite")), "math")
  lurek.log.info("is wrong: " .. tostring(hermite_obj:typeOf("Unknown")), "math")
end
--@api-stub: LNoiseGenerator:type
-- Returns the Lua-visible type name for this noise generator handle
do
  local noise_generator_obj = lurek.math.newNoiseGenerator(42)
  local t = noise_generator_obj:type()
  lurek.log.info("LNoiseGenerator:type = " .. t, "math")
end
--@api-stub: LNoiseGenerator:typeOf
-- Returns whether this noise generator handle matches a supported type name
do
  local noise_generator_obj = lurek.math.newNoiseGenerator(42)
  lurek.log.info("is LNoiseGenerator: " .. tostring(noise_generator_obj:typeOf("LNoiseGenerator")), "math")
  lurek.log.info("is wrong: " .. tostring(noise_generator_obj:typeOf("Unknown")), "math")
end
--@api-stub: LRandomGenerator:type
-- Returns the Lua-visible type name for this random generator handle
do
  local random_generator_obj = lurek.math.newRandomGenerator(42)
  local t = random_generator_obj:type()
  lurek.log.info("LRandomGenerator:type = " .. t, "math")
end
--@api-stub: LRandomGenerator:typeOf
-- Returns whether this random generator handle matches a supported type name
do
  local random_generator_obj = lurek.math.newRandomGenerator(42)
  lurek.log.info("is LRandomGenerator: " .. tostring(random_generator_obj:typeOf("LRandomGenerator")), "math")
  lurek.log.info("is wrong: " .. tostring(random_generator_obj:typeOf("Unknown")), "math")
end
--@api-stub: LSpatialHash:type
-- Returns the Lua-visible type name for this spatial hash handle
do
  local spatial_hash_obj = lurek.math.newSpatialHash(64)
  local t = spatial_hash_obj:type()
  lurek.log.info("LSpatialHash:type = " .. t, "math")
end
--@api-stub: LSpatialHash:typeOf
-- Returns whether this spatial hash handle matches a supported type name
do
  local spatial_hash_obj = lurek.math.newSpatialHash(64)
  lurek.log.info("is LSpatialHash: " .. tostring(spatial_hash_obj:typeOf("LSpatialHash")), "math")
  lurek.log.info("is wrong: " .. tostring(spatial_hash_obj:typeOf("Unknown")), "math")
end
--@api-stub: LTransform:type
-- Returns the Lua-visible type name for this transform handle
do
  local transform_obj = lurek.math.newTransform()
  local t = transform_obj:type()
  lurek.log.info("LTransform:type = " .. t, "math")
end
--@api-stub: LTransform:typeOf
-- Returns whether this transform handle matches a supported type name
do
  local transform_obj = lurek.math.newTransform()
  lurek.log.info("is LTransform: " .. tostring(transform_obj:typeOf("LTransform")), "math")
  lurek.log.info("is wrong: " .. tostring(transform_obj:typeOf("Unknown")), "math")
end
--@api-stub: LTween:type
-- Returns the type name of this object
do
  local tween_obj = lurek.tween.tween(0.5, {x=0}, {x=100})
  local t = tween_obj:type()
  lurek.log.info("LTween:type = " .. t, "math")
end
--@api-stub: LTween:typeOf
-- Checks whether this object matches the given type name
do
  local tween_obj = lurek.tween.tween(0.5, {x=0}, {x=100})
  lurek.log.info("is LTween: " .. tostring(tween_obj:typeOf("LTween")), "math")
  lurek.log.info("is wrong: " .. tostring(tween_obj:typeOf("Unknown")), "math")
end
--@api-stub: LVec2:fromAngle
-- Performs the from angle operation on this vec2.
do
  local v = lurek.math.vec2(1, 0)
  local angle = math.pi / 4   -- 45 degrees (northeast)
  local dir = lurek.math.vec2(1, 0).fromAngle(angle)
  lurek.log.info("dir.x=" .. dir.x .. " dir.y=" .. dir.y, "math")
end
--@api-stub: LVec2:type
-- Returns the Lua-visible type name for this vector handle
do
  local vec2_obj = lurek.math.vec2(0, 0)
  local t = vec2_obj:type()
  lurek.log.info("LVec2:type = " .. t, "math")
end
--@api-stub: LVec2:typeOf
-- Returns whether this vector handle matches a supported type name
do
  local vec2_obj = lurek.math.vec2(0, 0)
  lurek.log.info("is LVec2: " .. tostring(vec2_obj:typeOf("LVec2")), "math")
  lurek.log.info("is wrong: " .. tostring(vec2_obj:typeOf("Unknown")), "math")
end
--@api-stub: LVec3:splat
-- Performs the splat operation on this vec3.
do
  local v = lurek.math.vec3(0, 0, 0)
  local ones = lurek.math.vec3(1.0, 1.0, 1.0).splat(1.0)
  lurek.log.info("splat=" .. ones.x .. "," .. ones.y .. "," .. ones.z, "math")
end
--@api-stub: LVec3:type
-- Returns the Lua-visible type name for this vector handle
do
  local vec3_obj = lurek.math.vec3(0, 0, 0)
  local t = vec3_obj:type()
  lurek.log.info("LVec3:type = " .. t, "math")
end
--@api-stub: LVec3:typeOf
-- Returns whether this vector handle matches a supported type name
do
  local vec3_obj = lurek.math.vec3(0, 0, 0)
  lurek.log.info("is LVec3: " .. tostring(vec3_obj:typeOf("LVec3")), "math")
  lurek.log.info("is wrong: " .. tostring(vec3_obj:typeOf("Unknown")), "math")
end


