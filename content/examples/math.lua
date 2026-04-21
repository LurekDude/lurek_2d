-- content/examples/math.lua
-- Lurek2D lurek.math API Reference
-- Run with: cargo run -- content/examples/math
--
Scenario: A comprehensive demonstration of the math library used throughout
-- game development — easing for UI animations, noise for terrain generation,
-- spatial hashing for broad-phase collision, geometry for level editor tools,
-- transforms for hierarchical scene graphs, and vector math for gameplay.

print("=== lurek.math — Math Library ===\n")

-- =============================================================================
-- Factory Functions — Object Creation
-- =============================================================================

local rng = lurek.math.newRandomGenerator()

local tf = lurek.math.newTransform()

local bez = lurek.math.newBezierCurve({0,0, 100,50, 200,0})

local tween = lurek.math.newTween(1.0, "outQuad")

local shash = lurek.math.newSpatialHash(64)

local noise = lurek.math.newNoiseGenerator()

-- =============================================================================
-- Vectors
-- =============================================================================

local v = lurek.math.vec2(3, 4)

local v2 = lurek.math.Vec2(1, 0)

print("v.x: " .. v:x())

print("v.y: " .. v:y())

print("dot: " .. v:dot(v2))

print("length: " .. v:length())

print("lengthSq: " .. v:lengthSquared())

v:normalize()

local n = v:normalized()

local mid = v:lerp(v2, 0.5)

print("dist: " .. v:distance(v2))

print("angle: " .. v:angle())

local rotated = v:rotate(math.pi / 4)

local perp = v:perpendicular()

print("cross: " .. v:cross(v2))

local v3 = lurek.math.vec3(1, 2, 3)

local v3b = lurek.math.Vec3(4, 5, 6)

print("v3 length: " .. v3:length())

print("v3 lengthSq: " .. v3:lengthSquared())

v3:normalize()

print("v3 dot: " .. v3:dot(v3b))

local v3cross = v3:cross(v3b)

local v3mid = v3:lerp(v3b, 0.5)

print("v3 dist: " .. v3:distance(v3b))

local v3sum = v3:add(v3b)

local v3diff = v3:sub(v3b)

local v3scaled = v3:scale(2.0)

-- =============================================================================
-- Transform — 2D affine transforms
-- =============================================================================

tf:translate(100, 50)

tf:rotate(math.pi / 6)

tf:scale(2, 2)

tf:shear(0.1, 0)

tf:reset()

local px, py = tf:transformPoint(10, 20)
print("transformed: " .. px .. "," .. py)

local ipx, ipy = tf:inverseTransformPoint(px, py)
print("inverse: " .. ipx .. "," .. ipy)

local inv = tf:inverse()

local tf_copy = tf:clone()

local m = tf:getMatrix()

-- =============================================================================
-- Bezier Curves
-- =============================================================================

local bx, by = bez:evaluate(0.5)
print("bezier at t=0.5: " .. bx .. "," .. by)

-- Render as line segments (5 segments).
local points = bez:render(5)

local deriv = bez:getDerivative()

local cpx, cpy = bez:getControlPoint(1)
print("control point 1: " .. cpx .. "," .. cpy)

bez:removeControlPoint(2)

print("control points: " .. bez:getControlPointCount())

print("bezier length: " .. bez:length())

bez:translate(10, 0)

bez:rotate(0.1)

bez:scale(1.5)

-- =============================================================================
-- Spline Interpolation
-- =============================================================================

-- Catmull-Rom spline through 4 control points.
local cr = lurek.math.catmullRom({0,0, 100,50, 200,30, 300,0})

local sx, sy = cr:sample(0.5)
print("catmull at 0.5: " .. sx .. "," .. sy)

local ssx, ssy = cr:sampleSegment(1, 0.5)

print("catmull segments: " .. cr:len())

local herm = lurek.math.hermite({0,0, 100,50, 200,0, 300,50})

local hx, hy = herm:sample(0.5)
print("hermite at 0.5: " .. hx .. "," .. hy)

-- =============================================================================
-- Tweens & Easing
-- =============================================================================

tween:update(0.016)

print("tween value: " .. tween:getValue())

local vals = tween:getAllValues()

print("complete: " .. tostring(tween:isComplete()))

tween:reset()

print("value count: " .. tween:getValueCount())

print("easing: " .. tween:getEasingName())

print("duration: " .. tween:getDuration())

print("time: " .. tween:getTime())

print("clock: " .. tween:getClock())

tween:setTime(0.5)

tween:set(0.0, 1.0, 2.0, "outQuad")

tween:addValue(0.0, 100.0)

-- Easing function reference: call directly with t in [0, 1].

print("outQuad(0.5): " .. lurek.math.applyEasing("outQuad", 0.5))

print("linear(0.5): " .. lurek.math.linear(0.5))

print("inQuad: " .. lurek.math.inQuad(0.5))

print("outQuad: " .. lurek.math.outQuad(0.5))

print("inOutQuad: " .. lurek.math.inOutQuad(0.5))

print("inCubic: " .. lurek.math.inCubic(0.5))

print("outCubic: " .. lurek.math.outCubic(0.5))

print("inOutCubic: " .. lurek.math.inOutCubic(0.5))

print("inQuart: " .. lurek.math.inQuart(0.5))

print("outQuart: " .. lurek.math.outQuart(0.5))

print("inOutQuart: " .. lurek.math.inOutQuart(0.5))

print("inSine: " .. lurek.math.inSine(0.5))

print("outSine: " .. lurek.math.outSine(0.5))

print("inOutSine: " .. lurek.math.inOutSine(0.5))

print("inExpo: " .. lurek.math.inExpo(0.5))

print("outExpo: " .. lurek.math.outExpo(0.5))

print("inOutExpo: " .. lurek.math.inOutExpo(0.5))

print("inElastic: " .. lurek.math.inElastic(0.5))

print("outElastic: " .. lurek.math.outElastic(0.5))

print("outBounce: " .. lurek.math.outBounce(0.5))

print("inBounce: " .. lurek.math.inBounce(0.5))

print("inBack: " .. lurek.math.inBack(0.5))

print("outBack: " .. lurek.math.outBack(0.5))

-- =============================================================================
-- Noise Generation
-- =============================================================================

print("perlin2d: " .. lurek.math.perlin2d(1.5, 2.3))

print("perlin3d: " .. lurek.math.perlin3d(1.5, 2.3, 0.5))

print("simplex2d: " .. lurek.math.simplex2d(1.5, 2.3))

print("simplexNoise: " .. lurek.math.simplexNoise(1.5, 2.3))

-- Fractal Brownian Motion: layered noise for terrain heightmaps.
print("fbm: " .. lurek.math.fbm(1.5, 2.3, 6, 0.5))

print("noise.perlin1d: " .. noise:perlin1d(0.5))

print("noise.perlin2d: " .. noise:perlin2d(1.0, 2.0))

print("noise.perlin3d: " .. noise:perlin3d(1.0, 2.0, 3.0))

print("noise.perlin4d: " .. noise:perlin4d(1.0, 2.0, 3.0, 4.0))

print("noise.simplex1d: " .. noise:simplex1d(0.5))

print("noise.simplex2d: " .. noise:simplex2d(1.0, 2.0))

print("noise.simplex3d: " .. noise:simplex3d(1.0, 2.0, 3.0))

print("noise seed: " .. noise:getSeed())

noise:setSeed(42)

-- =============================================================================
-- Random Generator
-- =============================================================================

print("random: " .. rng:random())

print("float [0.5, 1.5]: " .. rng:randomFloat(0.5, 1.5))

print("int [1, 100]: " .. rng:randomInt(1, 100))

print("rng seed: " .. rng:getSeed())

rng:setSeed(12345)

local state = rng:getState()

rng:setState(state)

-- =============================================================================
-- Spatial Hash — broad-phase collision
-- =============================================================================

shash:remove("enemy1")

shash:clear()

print("cell size: " .. shash:getCellSize())

print("items: " .. shash:getItemCount())

-- =============================================================================
-- AABB Tree
-- =============================================================================

local tree = lurek.math.aabbTree()

tree:remove("obj1")

local hits = tree:queryPoint(50, 50)
print("point query: " .. #hits .. " hits")

print("contains obj1: " .. tostring(tree:contains("obj1")))

print("tree size: " .. tree:len())

print("tree empty: " .. tostring(tree:isEmpty()))

tree:clear()

-- =============================================================================
-- Standard Math Operations (global wrappers)
-- =============================================================================

print("90 deg -> rad: " .. lurek.math.rad(90))

print("pi -> deg: " .. lurek.math.deg(math.pi))

print("sin(pi/4): " .. lurek.math.sin(math.pi/4))

print("cos(0): " .. lurek.math.cos(0))

print("tan(pi/4): " .. lurek.math.tan(math.pi/4))

print("asin(1): " .. lurek.math.asin(1))

print("acos(0): " .. lurek.math.acos(0))

print("atan(1): " .. lurek.math.atan(1))

print("atan2(1,1): " .. lurek.math.atan2(1, 1))

print("sqrt(144): " .. lurek.math.sqrt(144))

print("abs(-7): " .. lurek.math.abs(-7))

print("floor(3.7): " .. lurek.math.floor(3.7))

print("ceil(3.2): " .. lurek.math.ceil(3.2))

print("round(3.5): " .. lurek.math.round(3.5))

print("exp(1): " .. lurek.math.exp(1))

print("log(e): " .. lurek.math.log(math.exp(1)))

print("pow(2,10): " .. lurek.math.pow(2, 10))

print("min(3,7): " .. lurek.math.min(3, 7))

print("max(3,7): " .. lurek.math.max(3, 7))

print("clamp(150,0,100): " .. lurek.math.clamp(150, 0, 100))

print("sign(-5): " .. lurek.math.sign(-5))

print("fmod(7,3): " .. lurek.math.fmod(7, 3))

-- =============================================================================
-- Interpolation & Distance
-- =============================================================================

print("lerp(0,100,0.5): " .. lurek.math.lerp(0, 100, 0.5))

print("remap(5, 0,10, 0,100): " .. lurek.math.remap(5, 0, 10, 0, 100))

print("dist (0,0)-(3,4): " .. lurek.math.distance(0, 0, 3, 4))

print("distSq: " .. lurek.math.distanceSq(0, 0, 3, 4))

-- =============================================================================
-- Random (module-level)
-- =============================================================================

print("random: " .. lurek.math.random())

print("randInt [1,6]: " .. lurek.math.randomInt(1, 6))

-- =============================================================================
-- Geometry Utilities — collision, triangulation, clipping
-- =============================================================================

-- Triangulate a polygon for mesh rendering.
local tris = lurek.math.triangulate({0,0, 100,0, 100,100, 0,100})
print("triangles: " .. #tris / 6 .. " triangles")

print("square convex: " .. tostring(lurek.math.isConvex({0,0, 100,0, 100,100, 0,100})))

local hull = lurek.math.convexHull({10,20, 50,80, 90,10, 30,60, 70,50})
print("hull points: " .. #hull / 2)

local del = lurek.math.delaunayTriangulate({0,0, 100,0, 50,100, 0,100, 100,100})
print("delaunay triangles: " .. #del / 6)

print("angle between (0,0)-(1,1): " .. lurek.math.angleBetween(0, 0, 1, 1))

print("circle contains: " .. tostring(lurek.math.circleContainsPoint(0, 0, 10, 5, 5)))

print("circles intersect: " .. tostring(lurek.math.circleIntersectsCircle(0, 0, 10, 15, 0, 10)))

print("circle-line: " .. tostring(lurek.math.circleIntersectsLine(0, 0, 10, -20, 5, 20, 5)))

print("circle-seg: " .. tostring(lurek.math.circleIntersectsSegment(0, 0, 10, -5, 0, 5, 0)))

local cpx, cpy = lurek.math.closestPointOnSegment(5, 5, 0, 0, 10, 0)
print("closest on seg: " .. cpx .. "," .. cpy)

local lx, ly = lurek.math.lineIntersect(0, 0, 10, 10, 10, 0, 0, 10)
print("line intersect: " .. lx .. "," .. ly)

local inside = lurek.math.pointInPolygon(50, 50, {0,0, 100,0, 100,100, 0,100})
print("point in polygon: " .. tostring(inside))

print("area: " .. lurek.math.polygonArea({0,0, 100,0, 100,100, 0,100}))

local pcx, pcy = lurek.math.polygonCentroid({0,0, 100,0, 100,100, 0,100})
print("centroid: " .. pcx .. "," .. pcy)

local sx, sy = lurek.math.segmentIntersectsSegment(0, 0, 10, 10, 10, 0, 0, 10)
print("seg intersect: " .. tostring(sx ~= nil))

-- Bresenham line rasterization for line-of-sight checks.
local cells = lurek.math.bresenham(0, 0, 10, 5)
print("bresenham cells: " .. #cells)

-- =============================================================================
-- Polygon Boolean Operations
-- =============================================================================

local clipped = lurek.math.polygonClip({0,0, 100,0, 100,100, 0,100}, {50,50, 150,50, 150,150, 50,150})

local inter = lurek.math.polygonIntersection({0,0, 100,0, 100,100, 0,100}, {50,50, 150,50, 150,150, 50,150})

local union = lurek.math.polygonUnion({0,0, 100,0, 100,100, 0,100}, {50,50, 150,50, 150,150, 50,150})

local diff = lurek.math.polygonDifference({0,0, 100,0, 100,100, 0,100}, {50,50, 150,50, 150,150, 50,150})

-- =============================================================================
-- Voronoi Diagram
-- =============================================================================

-- Generate Voronoi regions for procedural map generation.
local regions = lurek.math.voronoi({50,50, 150,100, 250,50, 100,200}, 0, 0, 300, 300)
print("voronoi regions: " .. #regions)

-- =============================================================================
-- Color Space Conversion
-- =============================================================================

local lin = lurek.math.gammaToLinear(0.5)
print("gamma 0.5 -> linear: " .. lin)

local gam = lurek.math.linearToGamma(lin)
print("linear -> gamma: " .. gam)

-- =============================================================================
-- New in 0.15.0: Scalar Utilities
-- =============================================================================

sign: returns -1, 0, or 1.
local s1 = lurek.math.sign(-4.5)   -- -1
local s2 = lurek.math.sign(0)      -- 0
local s3 = lurek.math.sign(7)      -- 1
print("sign: " .. s1 .. ", " .. s2 .. ", " .. s3)

smoothstep: smooth Hermite interpolation.
local ss = lurek.math.smoothstep(0, 100, 50)
print("smoothstep(0,100,50): " .. ss)

inverseLerp: reverse of lerp.
local il = lurek.math.inverseLerp(0, 100, 25)
print("inverseLerp(0,100,25): " .. il)   -- 0.25

-- =============================================================================
-- New in 0.15.0: HSL Colour Utilities
-- =============================================================================

fromHex: parse hex colour string.
local r, g, b, a = lurek.math.fromHex("#ff8800")
print(string.format("fromHex #ff8800 -> r=%.2f g=%.2f b=%.2f a=%.2f", r, g, b, a))

-- rgbToHsl / hslToRgb roundtrip.
local h, sat, l = lurek.math.rgbToHsl(r, g, b)
print(string.format("rgbToHsl -> h=%.2f s=%.2f l=%.2f", h, sat, l))
local r2, g2, b2 = lurek.math.hslToRgb(h, sat, l)
print(string.format("hslToRgb back -> r=%.2f g=%.2f b=%.2f", r2, g2, b2))

-- =============================================================================
-- New in 0.15.0: Rect Utilities
-- =============================================================================

rectUnion: bounding rect of two rects.
local ux, uy, uw, uh = lurek.math.rectUnion(0, 0, 40, 40, 20, 20, 40, 40)
print(string.format("rectUnion: x=%s y=%s w=%s h=%s", ux, uy, uw, uh))

rectFromCenter: rect whose centre is at (cx, cy).
local rx, ry, rw, rh = lurek.math.rectFromCenter(100, 100, 50, 30)
print(string.format("rectFromCenter(100,100,50,30): x=%s y=%s", rx, ry))

-- =============================================================================
-- New in 0.15.0: Vec2 / Vec3 Extensions
-- =============================================================================

-- Vec2.fromAngle: unit vector from angle (radians).
local dir = lurek.math.Vec2.fromAngle(math.pi / 4)
print(string.format("Vec2.fromAngle(pi/4): x=%.3f y=%.3f", dir.x, dir.y))

-- Vec2:reflect: reflect vector about a normal.
local vel = lurek.math.Vec2.new(1, -1)
local norm = lurek.math.Vec2.new(0, 1)
local refl = vel:reflect(norm)
print(string.format("reflect (1,-1) off (0,1): x=%.1f y=%.1f", refl.x, refl.y))

-- Vec3.splat: fill all components with a single value.
local uniform = lurek.math.Vec3.splat(7)
print(string.format("Vec3.splat(7): x=%s y=%s z=%s", uniform.x, uniform.y, uniform.z))

-- =============================================================================
-- New in 0.15.0: Transform Decompose
-- =============================================================================

local t = lurek.math.Transform.new()
local tx, ty, angle, sx, sy = t:decompose()
print(string.format("Transform.decompose identity: tx=%s ty=%s angle=%s sx=%s sy=%s", tx, ty, angle, sx, sy))

-- =============================================================================
-- New in 0.15.0: Extra Easing Functions
-- =============================================================================

print(string.format("inOutElastic(0.5): %.4f", lurek.math.inOutElastic(0.5)))
print(string.format("inOutBounce(0.5):  %.4f", lurek.math.inOutBounce(0.5)))
print(string.format("inOutBack(0.5):    %.4f", lurek.math.inOutBack(0.5)))

-- =============================================================================
-- New in 0.15.0: CatmullRomSpline Mutations
-- =============================================================================

local spline = lurek.math.CatmullRomSpline.new()
spline:addPoint(0, 0)
spline:addPoint(100, 50)
spline:addPoint(200, 0)
print("spline points after 3 addPoint: " .. spline:count())
spline:removePoint(2)
print("spline points after removePoint(2): " .. spline:count())

-- =============================================================================
-- New in 0.15.0: Circle Value Type
-- =============================================================================

local c = lurek.math.newCircle(0, 0, 5)
print(string.format("Circle area:      %.4f", c:area()))
print(string.format("Circle perimeter: %.4f", c:perimeter()))
print("Circle contains (3,4): " .. tostring(c:contains(3, 4)))
print("Circle contains (6,0): " .. tostring(c:contains(6, 0)))

local c2 = lurek.math.newCircle(8, 0, 5)
print("Circles intersect (d=8, r=5+5): " .. tostring(c:intersects(c2)))

local x1, y1, x2, y2 = c:aabb()
print(string.format("Circle AABB: (%.1f, %.1f, %.1f, %.1f)", x1, y1, x2, y2))

-- =============================================================================
-- New in 0.15.0: AabbTree querySegment
-- =============================================================================

local tree = lurek.math.aabbTree()
tree:insert("platform", 0, 4, 10, 6)
tree:insert("wall",     8, 0, 10, 8)

local hits = tree:querySegment(5, 0, 5, 10)
print("querySegment hits: " .. #hits)
for _, id in ipairs(hits) do
  print("  hit: " .. id)
end

print("\n-- math.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BezierCurve methods
-- -----------------------------------------------------------------------------

-- Removes a control point at 1-based index.
bezierCurve_stub:removeControlPoint(1)  -- -> boolean
-- -----------------------------------------------------------------------------
-- Circle methods
-- -----------------------------------------------------------------------------

-- Returns the circle radius.
circle:radius()  -- -> number
