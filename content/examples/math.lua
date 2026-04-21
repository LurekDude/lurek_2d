-- content/examples/math.lua
-- Lurek2D lurek.math API Reference
-- Run with: cargo run -- content/examples/math
--
-- Scenario: A comprehensive demonstration of the math library used throughout
-- game development — easing for UI animations, noise for terrain generation,
-- spatial hashing for broad-phase collision, geometry for level editor tools,
-- transforms for hierarchical scene graphs, and vector math for gameplay.

print("=== lurek.math — Math Library ===\n")

-- =============================================================================
-- Factory Functions — Object Creation
-- =============================================================================

--@api-stub: lurek.math.newRandomGenerator
local rng = lurek.math.newRandomGenerator()

--@api-stub: lurek.math.newTransform
local tf = lurek.math.newTransform()

--@api-stub: lurek.math.newBezierCurve
local bez = lurek.math.newBezierCurve({0,0, 100,50, 200,0})

--@api-stub: lurek.math.newTween
local tween = lurek.math.newTween(1.0, "outQuad")

--@api-stub: lurek.math.newSpatialHash
local shash = lurek.math.newSpatialHash(64)

--@api-stub: lurek.math.newNoiseGenerator
local noise = lurek.math.newNoiseGenerator()

-- =============================================================================
-- Vectors
-- =============================================================================

--@api-stub: lurek.math.vec2
local v = lurek.math.vec2(3, 4)

--@api-stub: lurek.math.Vec2
local v2 = lurek.math.Vec2(1, 0)

--@api-stub: Vec2:x
print("v.x: " .. v:x())

--@api-stub: Vec2:y
print("v.y: " .. v:y())

--@api-stub: Vec2:dot
print("dot: " .. v:dot(v2))

--@api-stub: Vec2:length
print("length: " .. v:length())

--@api-stub: Vec2:lengthSquared
print("lengthSq: " .. v:lengthSquared())

--@api-stub: Vec2:normalize
v:normalize()

--@api-stub: Vec2:normalized
local n = v:normalized()

--@api-stub: Vec2:lerp
local mid = v:lerp(v2, 0.5)

--@api-stub: Vec2:distance
print("dist: " .. v:distance(v2))

--@api-stub: Vec2:angle
print("angle: " .. v:angle())

--@api-stub: Vec2:rotate
local rotated = v:rotate(math.pi / 4)

--@api-stub: Vec2:perpendicular
local perp = v:perpendicular()

--@api-stub: Vec2:cross
print("cross: " .. v:cross(v2))

--@api-stub: lurek.math.vec3
local v3 = lurek.math.vec3(1, 2, 3)

--@api-stub: lurek.math.Vec3
local v3b = lurek.math.Vec3(4, 5, 6)

--@api-stub: Vec3:length
print("v3 length: " .. v3:length())

--@api-stub: Vec3:lengthSquared
print("v3 lengthSq: " .. v3:lengthSquared())

--@api-stub: Vec3:normalize
v3:normalize()

--@api-stub: Vec3:dot
print("v3 dot: " .. v3:dot(v3b))

--@api-stub: Vec3:cross
local v3cross = v3:cross(v3b)

--@api-stub: Vec3:lerp
local v3mid = v3:lerp(v3b, 0.5)

--@api-stub: Vec3:distance
print("v3 dist: " .. v3:distance(v3b))

--@api-stub: Vec3:add
local v3sum = v3:add(v3b)

--@api-stub: Vec3:sub
local v3diff = v3:sub(v3b)

--@api-stub: Vec3:scale
local v3scaled = v3:scale(2.0)

-- =============================================================================
-- Transform — 2D affine transforms
-- =============================================================================

--@api-stub: Transform:translate
tf:translate(100, 50)

--@api-stub: Transform:rotate
tf:rotate(math.pi / 6)

--@api-stub: Transform:scale
tf:scale(2, 2)

--@api-stub: Transform:shear
tf:shear(0.1, 0)

--@api-stub: Transform:reset
tf:reset()

--@api-stub: Transform:transformPoint
local px, py = tf:transformPoint(10, 20)
print("transformed: " .. px .. "," .. py)

--@api-stub: Transform:inverseTransformPoint
local ipx, ipy = tf:inverseTransformPoint(px, py)
print("inverse: " .. ipx .. "," .. ipy)

--@api-stub: Transform:inverse
local inv = tf:inverse()

--@api-stub: Transform:clone
local tf_copy = tf:clone()

--@api-stub: Transform:getMatrix
local m = tf:getMatrix()

-- =============================================================================
-- Bezier Curves
-- =============================================================================

--@api-stub: BezierCurve:evaluate
local bx, by = bez:evaluate(0.5)
print("bezier at t=0.5: " .. bx .. "," .. by)

--@api-stub: BezierCurve:render
-- Render as line segments (5 segments).
local points = bez:render(5)

--@api-stub: BezierCurve:getDerivative
local deriv = bez:getDerivative()

--@api-stub: BezierCurve:getControlPoint
local cpx, cpy = bez:getControlPoint(1)
print("control point 1: " .. cpx .. "," .. cpy)

--@api-stub: BezierCurve:removeControlPoint
-- bez:removeControlPoint(2)

--@api-stub: BezierCurve:getControlPointCount
print("control points: " .. bez:getControlPointCount())

--@api-stub: BezierCurve:length
print("bezier length: " .. bez:length())

--@api-stub: BezierCurve:translate
bez:translate(10, 0)

--@api-stub: BezierCurve:rotate
bez:rotate(0.1)

--@api-stub: BezierCurve:scale
bez:scale(1.5)

-- =============================================================================
-- Spline Interpolation
-- =============================================================================

--@api-stub: lurek.math.catmullRom
-- Catmull-Rom spline through 4 control points.
local cr = lurek.math.catmullRom({0,0, 100,50, 200,30, 300,0})

--@api-stub: CatmullRom:sample
local sx, sy = cr:sample(0.5)
print("catmull at 0.5: " .. sx .. "," .. sy)

--@api-stub: CatmullRom:sampleSegment
local ssx, ssy = cr:sampleSegment(1, 0.5)

--@api-stub: CatmullRom:len
print("catmull segments: " .. cr:len())

--@api-stub: lurek.math.hermite
local herm = lurek.math.hermite({0,0, 100,50, 200,0, 300,50})

--@api-stub: Hermite:sample
local hx, hy = herm:sample(0.5)
print("hermite at 0.5: " .. hx .. "," .. hy)

-- =============================================================================
-- Tweens & Easing
-- =============================================================================

--@api-stub: Tween:update
tween:update(0.016)

--@api-stub: Tween:getValue
print("tween value: " .. tween:getValue())

--@api-stub: Tween:getAllValues
local vals = tween:getAllValues()

--@api-stub: Tween:isComplete
print("complete: " .. tostring(tween:isComplete()))

--@api-stub: Tween:reset
tween:reset()

--@api-stub: Tween:getValueCount
print("value count: " .. tween:getValueCount())

--@api-stub: Tween:getEasingName
print("easing: " .. tween:getEasingName())

--@api-stub: Tween:getDuration
print("duration: " .. tween:getDuration())

--@api-stub: Tween:getTime
print("time: " .. tween:getTime())

--@api-stub: Tween:getClock
print("clock: " .. tween:getClock())

--@api-stub: Tween:setTime
tween:setTime(0.5)

--@api-stub: Tween:set
tween:set(0.0, 1.0, 2.0, "outQuad")

--@api-stub: Tween:addValue
tween:addValue(0.0, 100.0)

-- Easing function reference: call directly with t in [0, 1].

--@api-stub: lurek.math.applyEasing
print("outQuad(0.5): " .. lurek.math.applyEasing("outQuad", 0.5))

--@api-stub: lurek.math.linear
print("linear(0.5): " .. lurek.math.linear(0.5))

--@api-stub: lurek.math.inQuad
print("inQuad: " .. lurek.math.inQuad(0.5))

--@api-stub: lurek.math.outQuad
print("outQuad: " .. lurek.math.outQuad(0.5))

--@api-stub: lurek.math.inOutQuad
print("inOutQuad: " .. lurek.math.inOutQuad(0.5))

--@api-stub: lurek.math.inCubic
print("inCubic: " .. lurek.math.inCubic(0.5))

--@api-stub: lurek.math.outCubic
print("outCubic: " .. lurek.math.outCubic(0.5))

--@api-stub: lurek.math.inOutCubic
print("inOutCubic: " .. lurek.math.inOutCubic(0.5))

--@api-stub: lurek.math.inQuart
print("inQuart: " .. lurek.math.inQuart(0.5))

--@api-stub: lurek.math.outQuart
print("outQuart: " .. lurek.math.outQuart(0.5))

--@api-stub: lurek.math.inOutQuart
print("inOutQuart: " .. lurek.math.inOutQuart(0.5))

--@api-stub: lurek.math.inSine
print("inSine: " .. lurek.math.inSine(0.5))

--@api-stub: lurek.math.outSine
print("outSine: " .. lurek.math.outSine(0.5))

--@api-stub: lurek.math.inOutSine
print("inOutSine: " .. lurek.math.inOutSine(0.5))

--@api-stub: lurek.math.inExpo
print("inExpo: " .. lurek.math.inExpo(0.5))

--@api-stub: lurek.math.outExpo
print("outExpo: " .. lurek.math.outExpo(0.5))

--@api-stub: lurek.math.inOutExpo
print("inOutExpo: " .. lurek.math.inOutExpo(0.5))

--@api-stub: lurek.math.inElastic
print("inElastic: " .. lurek.math.inElastic(0.5))

--@api-stub: lurek.math.outElastic
print("outElastic: " .. lurek.math.outElastic(0.5))

--@api-stub: lurek.math.outBounce
print("outBounce: " .. lurek.math.outBounce(0.5))

--@api-stub: lurek.math.inBounce
print("inBounce: " .. lurek.math.inBounce(0.5))

--@api-stub: lurek.math.inBack
print("inBack: " .. lurek.math.inBack(0.5))

--@api-stub: lurek.math.outBack
print("outBack: " .. lurek.math.outBack(0.5))

-- =============================================================================
-- Noise Generation
-- =============================================================================

--@api-stub: lurek.math.perlin2d
print("perlin2d: " .. lurek.math.perlin2d(1.5, 2.3))

--@api-stub: lurek.math.perlin3d
print("perlin3d: " .. lurek.math.perlin3d(1.5, 2.3, 0.5))

--@api-stub: lurek.math.simplex2d
print("simplex2d: " .. lurek.math.simplex2d(1.5, 2.3))

--@api-stub: lurek.math.simplexNoise
print("simplexNoise: " .. lurek.math.simplexNoise(1.5, 2.3))

--@api-stub: lurek.math.fbm
-- Fractal Brownian Motion: layered noise for terrain heightmaps.
print("fbm: " .. lurek.math.fbm(1.5, 2.3, 6, 0.5))

--@api-stub: NoiseGenerator:perlin1d
print("noise.perlin1d: " .. noise:perlin1d(0.5))

--@api-stub: NoiseGenerator:perlin2d
print("noise.perlin2d: " .. noise:perlin2d(1.0, 2.0))

--@api-stub: NoiseGenerator:perlin3d
print("noise.perlin3d: " .. noise:perlin3d(1.0, 2.0, 3.0))

--@api-stub: NoiseGenerator:perlin4d
print("noise.perlin4d: " .. noise:perlin4d(1.0, 2.0, 3.0, 4.0))

--@api-stub: NoiseGenerator:simplex1d
print("noise.simplex1d: " .. noise:simplex1d(0.5))

--@api-stub: NoiseGenerator:simplex2d
print("noise.simplex2d: " .. noise:simplex2d(1.0, 2.0))

--@api-stub: NoiseGenerator:simplex3d
print("noise.simplex3d: " .. noise:simplex3d(1.0, 2.0, 3.0))

--@api-stub: NoiseGenerator:getSeed
print("noise seed: " .. noise:getSeed())

--@api-stub: NoiseGenerator:setSeed
noise:setSeed(42)

-- =============================================================================
-- Random Generator
-- =============================================================================

--@api-stub: RandomGenerator:random
print("random: " .. rng:random())

--@api-stub: RandomGenerator:randomFloat
print("float [0.5, 1.5]: " .. rng:randomFloat(0.5, 1.5))

--@api-stub: RandomGenerator:randomInt
print("int [1, 100]: " .. rng:randomInt(1, 100))

--@api-stub: RandomGenerator:getSeed
print("rng seed: " .. rng:getSeed())

--@api-stub: RandomGenerator:setSeed
rng:setSeed(12345)

--@api-stub: RandomGenerator:getState
local state = rng:getState()

--@api-stub: RandomGenerator:setState
rng:setState(state)

-- =============================================================================
-- Spatial Hash — broad-phase collision
-- =============================================================================

--@api-stub: SpatialHash:remove
shash:remove("enemy1")

--@api-stub: SpatialHash:clear
shash:clear()

--@api-stub: SpatialHash:getCellSize
print("cell size: " .. shash:getCellSize())

--@api-stub: SpatialHash:getItemCount
print("items: " .. shash:getItemCount())

-- =============================================================================
-- AABB Tree
-- =============================================================================

--@api-stub: lurek.math.aabbTree
local tree = lurek.math.aabbTree()

--@api-stub: AabbTree:remove
tree:remove("obj1")

--@api-stub: AabbTree:queryPoint
local hits = tree:queryPoint(50, 50)
print("point query: " .. #hits .. " hits")

--@api-stub: AabbTree:contains
print("contains obj1: " .. tostring(tree:contains("obj1")))

--@api-stub: AabbTree:len
print("tree size: " .. tree:len())

--@api-stub: AabbTree:isEmpty
print("tree empty: " .. tostring(tree:isEmpty()))

--@api-stub: AabbTree:clear
tree:clear()

-- =============================================================================
-- Standard Math Operations (global wrappers)
-- =============================================================================

--@api-stub: lurek.math.rad
print("90 deg -> rad: " .. lurek.math.rad(90))

--@api-stub: lurek.math.deg
print("pi -> deg: " .. lurek.math.deg(math.pi))

--@api-stub: lurek.math.sin
print("sin(pi/4): " .. lurek.math.sin(math.pi/4))

--@api-stub: lurek.math.cos
print("cos(0): " .. lurek.math.cos(0))

--@api-stub: lurek.math.tan
print("tan(pi/4): " .. lurek.math.tan(math.pi/4))

--@api-stub: lurek.math.asin
print("asin(1): " .. lurek.math.asin(1))

--@api-stub: lurek.math.acos
print("acos(0): " .. lurek.math.acos(0))

--@api-stub: lurek.math.atan
print("atan(1): " .. lurek.math.atan(1))

--@api-stub: lurek.math.atan2
print("atan2(1,1): " .. lurek.math.atan2(1, 1))

--@api-stub: lurek.math.sqrt
print("sqrt(144): " .. lurek.math.sqrt(144))

--@api-stub: lurek.math.abs
print("abs(-7): " .. lurek.math.abs(-7))

--@api-stub: lurek.math.floor
print("floor(3.7): " .. lurek.math.floor(3.7))

--@api-stub: lurek.math.ceil
print("ceil(3.2): " .. lurek.math.ceil(3.2))

--@api-stub: lurek.math.round
print("round(3.5): " .. lurek.math.round(3.5))

--@api-stub: lurek.math.exp
print("exp(1): " .. lurek.math.exp(1))

--@api-stub: lurek.math.log
print("log(e): " .. lurek.math.log(math.exp(1)))

--@api-stub: lurek.math.pow
print("pow(2,10): " .. lurek.math.pow(2, 10))

--@api-stub: lurek.math.min
print("min(3,7): " .. lurek.math.min(3, 7))

--@api-stub: lurek.math.max
print("max(3,7): " .. lurek.math.max(3, 7))

--@api-stub: lurek.math.clamp
print("clamp(150,0,100): " .. lurek.math.clamp(150, 0, 100))

--@api-stub: lurek.math.sign
print("sign(-5): " .. lurek.math.sign(-5))

--@api-stub: lurek.math.fmod
print("fmod(7,3): " .. lurek.math.fmod(7, 3))

-- =============================================================================
-- Interpolation & Distance
-- =============================================================================

--@api-stub: lurek.math.lerp
print("lerp(0,100,0.5): " .. lurek.math.lerp(0, 100, 0.5))

--@api-stub: lurek.math.remap
print("remap(5, 0,10, 0,100): " .. lurek.math.remap(5, 0, 10, 0, 100))

--@api-stub: lurek.math.distance
print("dist (0,0)-(3,4): " .. lurek.math.distance(0, 0, 3, 4))

--@api-stub: lurek.math.distanceSq
print("distSq: " .. lurek.math.distanceSq(0, 0, 3, 4))

-- =============================================================================
-- Random (module-level)
-- =============================================================================

--@api-stub: lurek.math.random
print("random: " .. lurek.math.random())

--@api-stub: lurek.math.randomInt
print("randInt [1,6]: " .. lurek.math.randomInt(1, 6))

-- =============================================================================
-- Geometry Utilities — collision, triangulation, clipping
-- =============================================================================

--@api-stub: lurek.math.triangulate
-- Triangulate a polygon for mesh rendering.
local tris = lurek.math.triangulate({0,0, 100,0, 100,100, 0,100})
print("triangles: " .. #tris / 6 .. " triangles")

--@api-stub: lurek.math.isConvex
print("square convex: " .. tostring(lurek.math.isConvex({0,0, 100,0, 100,100, 0,100})))

--@api-stub: lurek.math.convexHull
local hull = lurek.math.convexHull({10,20, 50,80, 90,10, 30,60, 70,50})
print("hull points: " .. #hull / 2)

--@api-stub: lurek.math.delaunayTriangulate
local del = lurek.math.delaunayTriangulate({0,0, 100,0, 50,100, 0,100, 100,100})
print("delaunay triangles: " .. #del / 6)

--@api-stub: lurek.math.angleBetween
print("angle between (0,0)-(1,1): " .. lurek.math.angleBetween(0, 0, 1, 1))

--@api-stub: lurek.math.circleContainsPoint
print("circle contains: " .. tostring(lurek.math.circleContainsPoint(0, 0, 10, 5, 5)))

--@api-stub: lurek.math.circleIntersectsCircle
print("circles intersect: " .. tostring(lurek.math.circleIntersectsCircle(0, 0, 10, 15, 0, 10)))

--@api-stub: lurek.math.circleIntersectsLine
print("circle-line: " .. tostring(lurek.math.circleIntersectsLine(0, 0, 10, -20, 5, 20, 5)))

--@api-stub: lurek.math.circleIntersectsSegment
print("circle-seg: " .. tostring(lurek.math.circleIntersectsSegment(0, 0, 10, -5, 0, 5, 0)))

--@api-stub: lurek.math.closestPointOnSegment
local cpx, cpy = lurek.math.closestPointOnSegment(5, 5, 0, 0, 10, 0)
print("closest on seg: " .. cpx .. "," .. cpy)

--@api-stub: lurek.math.lineIntersect
local lx, ly = lurek.math.lineIntersect(0, 0, 10, 10, 10, 0, 0, 10)
print("line intersect: " .. lx .. "," .. ly)

--@api-stub: lurek.math.pointInPolygon
local inside = lurek.math.pointInPolygon(50, 50, {0,0, 100,0, 100,100, 0,100})
print("point in polygon: " .. tostring(inside))

--@api-stub: lurek.math.polygonArea
print("area: " .. lurek.math.polygonArea({0,0, 100,0, 100,100, 0,100}))

--@api-stub: lurek.math.polygonCentroid
local pcx, pcy = lurek.math.polygonCentroid({0,0, 100,0, 100,100, 0,100})
print("centroid: " .. pcx .. "," .. pcy)

--@api-stub: lurek.math.segmentIntersectsSegment
local sx, sy = lurek.math.segmentIntersectsSegment(0, 0, 10, 10, 10, 0, 0, 10)
print("seg intersect: " .. tostring(sx ~= nil))

--@api-stub: lurek.math.bresenham
-- Bresenham line rasterization for line-of-sight checks.
local cells = lurek.math.bresenham(0, 0, 10, 5)
print("bresenham cells: " .. #cells)

-- =============================================================================
-- Polygon Boolean Operations
-- =============================================================================

--@api-stub: lurek.math.polygonClip
local clipped = lurek.math.polygonClip({0,0, 100,0, 100,100, 0,100}, {50,50, 150,50, 150,150, 50,150})

--@api-stub: lurek.math.polygonIntersection
local inter = lurek.math.polygonIntersection({0,0, 100,0, 100,100, 0,100}, {50,50, 150,50, 150,150, 50,150})

--@api-stub: lurek.math.polygonUnion
local union = lurek.math.polygonUnion({0,0, 100,0, 100,100, 0,100}, {50,50, 150,50, 150,150, 50,150})

--@api-stub: lurek.math.polygonDifference
local diff = lurek.math.polygonDifference({0,0, 100,0, 100,100, 0,100}, {50,50, 150,50, 150,150, 50,150})

-- =============================================================================
-- Voronoi Diagram
-- =============================================================================

--@api-stub: lurek.math.voronoi
-- Generate Voronoi regions for procedural map generation.
local regions = lurek.math.voronoi({50,50, 150,100, 250,50, 100,200}, 0, 0, 300, 300)
print("voronoi regions: " .. #regions)

-- =============================================================================
-- Color Space Conversion
-- =============================================================================

--@api-stub: lurek.math.gammaToLinear
local lin = lurek.math.gammaToLinear(0.5)
print("gamma 0.5 -> linear: " .. lin)

--@api-stub: lurek.math.linearToGamma
local gam = lurek.math.linearToGamma(lin)
print("linear -> gamma: " .. gam)

-- =============================================================================
-- New in 0.15.0: Scalar Utilities
-- =============================================================================

-- sign: returns -1, 0, or 1.
local s1 = lurek.math.sign(-4.5)   -- -1
local s2 = lurek.math.sign(0)      -- 0
local s3 = lurek.math.sign(7)      -- 1
print("sign: " .. s1 .. ", " .. s2 .. ", " .. s3)

-- smoothstep: smooth Hermite interpolation.
local ss = lurek.math.smoothstep(0, 100, 50)
print("smoothstep(0,100,50): " .. ss)

-- inverseLerp: reverse of lerp.
local il = lurek.math.inverseLerp(0, 100, 25)
print("inverseLerp(0,100,25): " .. il)   -- 0.25

-- =============================================================================
-- New in 0.15.0: HSL Colour Utilities
-- =============================================================================

-- fromHex: parse hex colour string.
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

-- rectUnion: bounding rect of two rects.
local ux, uy, uw, uh = lurek.math.rectUnion(0, 0, 40, 40, 20, 20, 40, 40)
print(string.format("rectUnion: x=%s y=%s w=%s h=%s", ux, uy, uw, uh))

-- rectFromCenter: rect whose centre is at (cx, cy).
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
-- STUBS: 2 uncovered lurek.math API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BezierCurve methods
-- -----------------------------------------------------------------------------

-- ---- Stub: BezierCurve:removeControlPoint --------------------------------
--@api-stub: BezierCurve:removeControlPoint
-- Removes a control point at 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- bezierCurve_stub:removeControlPoint(1)  -- -> boolean
-- (replace bezierCurve_stub with your real BezierCurve instance above)

-- -----------------------------------------------------------------------------
-- Circle methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Circle:radius -------------------------------------------------
--@api-stub: Circle:radius
-- Returns the circle radius.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- circle_stub:radius()  -- -> number
-- (replace circle_stub with your real Circle instance above)
