-- examples/math.lua
-- Luna2D luna.math API Reference
-- This file is documentation code, not a runnable game.
-- Every luna.math function is demonstrated with inline comments.

-- ─────────────────────────────────────────────────────────────────────────────
-- Basic Math Functions
-- ─────────────────────────────────────────────────────────────────────────────

-- Clamp a value to a range
local clamped = luna.math.clamp(1.5, 0, 1)   -- → 1
local clamped2 = luna.math.clamp(-5, 0, 100) -- → 0

-- Linear interpolation between two values
local blend = luna.math.lerp(0, 100, 0.25)   -- → 25

-- Distance between two points
local dist = luna.math.distance(0, 0, 3, 4)  -- → 5

-- Angle from point A to point B (in radians)
local ang = luna.math.angle(0, 0, 1, 0)      -- → 0 (facing right)
local ang2 = luna.math.angle(0, 0, 0, 1)     -- → math.pi/2 (facing down)

-- Normalize a 2D vector (returns unit vector components)
local nx, ny = luna.math.normalize(3, 4)     -- → 0.6, 0.8

-- Dot product of two 2D vectors
local d = luna.math.dot(1, 0, 0, 1)          -- → 0 (perpendicular)

-- Convert from polar (magnitude, angle) to Cartesian (x, y)
local x, y = luna.math.fromPolar(10, math.pi / 4) -- → 7.07, 7.07

-- Convert from Cartesian to polar (magnitude, angle)
local r, theta = luna.math.toPolar(1, 1)     -- → 1.41, 0.785

-- ─────────────────────────────────────────────────────────────────────────────
-- Standard Math (also available as normal Lua math.*)
-- ─────────────────────────────────────────────────────────────────────────────
local a1 = luna.math.abs(-7)        -- → 7
local a2 = luna.math.floor(3.9)     -- → 3
local a3 = luna.math.ceil(3.1)      -- → 4
local a4 = luna.math.sqrt(16)       -- → 4
local a5 = luna.math.sin(math.pi)   -- → ~0
local a6 = luna.math.cos(0)         -- → 1
local a7 = luna.math.atan2(1, 0)    -- → pi/2
local a8 = luna.math.max(3, 7, 2)   -- → 7
local a9 = luna.math.min(3, 7, 2)   -- → 2
local pi  = luna.math.pi            -- → 3.14159...

-- ─────────────────────────────────────────────────────────────────────────────
-- Color Space Conversion
-- ─────────────────────────────────────────────────────────────────────────────

-- sRGB gamma → linear (for physically correct blending)
local lr, lg, lb, la = luna.math.gammaToLinear(0.5, 0.5, 0.5, 1.0)

-- Linear → sRGB gamma (for display output)
local gr, gg, gb, ga = luna.math.linearToGamma(0.21, 0.21, 0.21, 1.0)

-- ─────────────────────────────────────────────────────────────────────────────
-- Random Numbers (global state)
-- ─────────────────────────────────────────────────────────────────────────────

-- Seedless random (integer 1–100)
local roll = luna.math.random(1, 100)

-- Float in range
local speed = luna.math.randomFloat(0.5, 2.0)

-- ─────────────────────────────────────────────────────────────────────────────
-- RandomGenerator (local seeded instance)
-- ─────────────────────────────────────────────────────────────────────────────

local rng = luna.math.newRandomGenerator(42)

local n1 = rng:random()              -- float in [0, 1)
local n2 = rng:random(1, 6)          -- integer in [1, 6]
local n3 = rng:randomFloat(-1, 1)    -- float in [-1, 1]
local n4 = rng:randomInt(0, 255)     -- integer in [0, 255]
local n5 = rng:randomNormal(1.0)     -- normal distribution, stddev=1
local n6 = rng:randomNormal(2.0, 5.0)-- normal distribution, stddev=2, mean=5

-- Reproducibility: save and restore state
local seed = rng:getSeed()
local state = rng:getState()
rng:setSeed(12345)
rng:setState(state) -- restore to saved point

-- ─────────────────────────────────────────────────────────────────────────────
-- Easing Functions  (luna.math.easing table)
-- ─────────────────────────────────────────────────────────────────────────────
-- All easing functions: f(t) where t ∈ [0, 1] → value ∈ [0, 1]
-- Apply to lerp for smooth interpolation

local easing = luna.math.easing

local t = 0.5 -- progress value in [0, 1]

-- Quadratic
local v1 = easing.linear(t)      -- linear (no easing)
local v2 = easing.inQuad(t)      -- slow start
local v3 = easing.outQuad(t)     -- slow end
local v4 = easing.inOutQuad(t)   -- slow start and end

-- Cubic
local v5 = easing.inCubic(t)
local v6 = easing.outCubic(t)
local v7 = easing.inOutCubic(t)

-- Sinusoidal
local v8 = easing.inSine(t)
local v9 = easing.outSine(t)
local v10 = easing.inOutSine(t)

-- Exponential
local v11 = easing.inExpo(t)
local v12 = easing.outExpo(t)
local v13 = easing.inOutExpo(t)

-- Elastic (overshoots)
local v14 = easing.inElastic(t)
local v15 = easing.outElastic(t)
local v16 = easing.inOutElastic(t)

-- Bounce (bounces at destination)
local v17 = easing.inBounce(t)
local v18 = easing.outBounce(t)
local v19 = easing.inOutBounce(t)

-- Back (overshoots then returns)
local v20 = easing.inBack(t)
local v21 = easing.outBack(t)
local v22 = easing.inOutBack(t)

-- Apply easing to lerp:
local smooth_x = luna.math.lerp(0, 800, easing.outQuad(t))

-- ─────────────────────────────────────────────────────────────────────────────
-- Tween (automated value interpolation)
-- ─────────────────────────────────────────────────────────────────────────────

-- Create a tween: duration=1.0s, easing=outQuad, values: from 0→100 and from 0→255
local tw = luna.math.newTween(1.0, luna.math.easing.outQuad, {
    {from = 0,   to = 100},   -- value 1: x position
    {from = 0,   to = 255},   -- value 2: alpha
    {from = 200, to = 50},    -- value 3: size
})

-- Tick the tween forward by dt each frame
local dt = 0.016
tw:update(dt)

-- Read current values
local px = tw:getValue(1)     -- current x
local alpha = tw:getValue(2)  -- current alpha
local sz = tw:getValue(3)     -- current size

-- Or get all values at once
local vals = tw:getAllValues() -- {100, 255, 50} when complete

-- Check completion
if tw:isComplete() then
    -- tween has reached end
end

-- Introspect
local dur = tw:getDuration()   -- → 1.0
local now = tw:getTime()       -- current elapsed time
local name = tw:getEasingName()-- → "outQuad"
local cnt = tw:getValueCount() -- → 3

-- Seek to a specific moment
tw:setTime(0.5)  -- jump to 50% through
tw:reset()       -- restart from beginning

-- Add more values dynamically
tw:addValue(0, 360)  -- add rotation 0→360

-- ─────────────────────────────────────────────────────────────────────────────
-- BezierCurve
-- ─────────────────────────────────────────────────────────────────────────────

-- Define a cubic Bezier with 4 control points {x1,y1, x2,y2, x3,y3, x4,y4}
local curve = luna.math.newBezierCurve({
    0,   0,    -- P0: start
    100, 0,    -- P1: control 1
    100, 200,  -- P2: control 2
    200, 200,  -- P3: end
})

-- Evaluate position at parameter t ∈ [0, 1]
local cx, cy = curve:evaluate(0.5)   -- point at middle of curve

-- Derivative (tangent) at t
local dx, dy = curve:getDerivative(0.5)

-- Approximate arc length
local len = curve:getLength()

-- Get all control points as {x1,y1,...}
local pts = curve:getPoints()

-- Render to polygon points (for drawing), segments = quality
local poly_pts = curve:render(20)  -- 20 line segments

-- ─────────────────────────────────────────────────────────────────────────────
-- Transform (2D affine matrix)
-- ─────────────────────────────────────────────────────────────────────────────

local tf = luna.math.newTransform()

-- Chain transforms
tf:translate(100, 200)
tf:rotate(math.pi / 4)  -- 45 degrees
tf:scale(2, 2)

-- Apply transform to a point
local wx, wy = tf:transformPoint(0, 0)  -- in world space
local lx, ly = tf:inverseTransformPoint(wx, wy)  -- back to local

-- Get/set matrix directly
local m = tf:getMatrix()         -- 9 numbers, row-major 3x3
tf:setMatrix(1,0,0, 0,1,0, 0,0,1) -- identity

-- Reset to identity
tf:reset()

-- Clone
local tf2 = tf:clone()

-- Concatenate two transforms
tf:apply(tf2)  -- tf = tf * tf2

-- ─────────────────────────────────────────────────────────────────────────────
-- SpatialHash (broad-phase collision grid)
-- ─────────────────────────────────────────────────────────────────────────────

-- Create grid with cell size 64 pixels
local grid = luna.math.newSpatialHash(64)

-- Insert objects by an arbitrary id and AABB
grid:insert("player",       100, 100, 32, 48)
grid:insert("enemy_1",      200, 150, 32, 32)
grid:insert("powerup",      300, 300, 16, 16)

-- Update a moving object's AABB
grid:update("player", 110, 100, 32, 48)

-- Query all objects whose AABB overlaps a rectangle
local hits = grid:queryRect(80, 80, 100, 80)
-- hits = {"player", "enemy_1"}  (or may be empty)

-- Query within a circle radius
local nearby = grid:queryCircle(200, 200, 100)

-- Remove an object
grid:remove("powerup")

-- Stats
local cell_sz = grid:getCellSize()   -- → 64
local count   = grid:getItemCount()  -- number of tracked objects

-- Clear all
grid:clear()

-- ─────────────────────────────────────────────────────────────────────────────
-- NoiseGenerator
-- ─────────────────────────────────────────────────────────────────────────────

local noise = luna.math.newNoiseGenerator(42) -- optional seed

-- 1D noise (t = time or position along a line)
local n = noise:perlin1d(0.5)   -- → float in roughly [-1, 1]
local s = noise:simplex1d(0.5)

-- 2D noise (terrain, texture generation)
local h = noise:perlin2d(x, y)
local h2 = noise:simplex2d(x, y)

-- 3D noise (animated 2D; add time as z)
local h3 = noise:perlin3d(x, y, 0.0)
local h4 = noise:simplex3d(x, y, 0.0)

-- 4D noise
local h5 = noise:perlin4d(x, y, z, w)

-- Worley / cellular noise (returns distance to nearest cell center)
local d1 = noise:worley2d(x, y)
local d2 = noise:worley3d(x, y, z)

-- Fractal Brownian Motion (layered noise, more natural)
local fbm = noise:fbm(x, y)          -- default octaves/lacunarity/gain
local fbm2 = noise:fbm(x, y, 6, 2.0, 0.5) -- explicit: octaves, lacunarity, gain

-- Ridged multifractal (mountain ridges)
local ridge = noise:ridged(x, y)

-- Turbulence (absolute value of FBM, good for clouds)
local turb = noise:turbulence(x, y)

-- Domain warping (distorted FBM for organic shapes)
local warped = noise:warpDomain(x, y)

-- Generate a 2D noise map as a flat table of floats
local map = noise:generateMap(256, 256) -- {float, ...} row-major
local map2 = noise:generateMap(128, 128, {
    type = "fbm",         -- "perlin", "simplex", "fbm", "ridged", "worley"
    scale = 0.01,         -- frequency (larger = more zoomed out)
    octaves = 6,
    lacunarity = 2.0,
    gain = 0.5,
    normalize = true,     -- remap to [0, 1]
})

noise:setSeed(99)
local seed2 = noise:getSeed()

-- ─────────────────────────────────────────────────────────────────────────────
-- Polygon Triangulation (ear-clipping)
-- ─────────────────────────────────────────────────────────────────────────────

-- Input: flat list of 2D vertices {x1,y1, x2,y2, ...}
local polygon = {
    0, 0,
    100, 0,
    100, 100,
    50,  150,
    0,   100,
}

-- Returns a flat list of triangles: {x1,y1, x2,y2, x3,y3, ...}
-- Each consecutive group of 6 floats is one triangle.
local triangles = luna.math.triangulate(polygon)
for i = 1, #triangles, 6 do
    local tx1, ty1 = triangles[i],   triangles[i+1]
    local tx2, ty2 = triangles[i+2], triangles[i+3]
    local tx3, ty3 = triangles[i+4], triangles[i+5]
    -- draw triangle (tx1,ty1) → (tx2,ty2) → (tx3,ty3)
end

-- ─── BezierCurve (supplemental) ──────────────────────────────────────────────

-- Introspect and mutate a curve built in the BezierCurve section above.

local cp_x, cp_y = beziercurve:getControlPoint(2)      -- → (x, y) of the 2nd control point (1-based index)
local cp_count   = beziercurve:getControlPointCount()  -- → total number of control points (4 for a cubic curve)
local arc_len    = beziercurve:length()                -- → approximate arc length; divide by speed to find travel time

beziercurve:removeControlPoint(cp_count)               -- drop the last control point, converting cubic → quadratic

-- ─── Transform (supplemental) ────────────────────────────────────────────────

-- inverse() returns a new Transform whose matrix undoes the original's
-- translate/rotate/scale.  Use it to map world-space coordinates (e.g. a mouse
-- click) back into an object's local frame.
local inv = transform:inverse()                        -- → new Transform; applying it reverses transform's effect
local local_x, local_y = inv:transformPoint(400, 300)  -- world mouse pos → local object coords

-- shear() skews axes independently — useful for drop shadows, italic slants,
-- and parallax tilt effects.  sx skews X per unit of Y; sy skews Y per unit of X.
transform:shear(0.3, 0.0)                              -- lean rightward 0.3 per Y unit; no vertical skew

-- ─── Tween (supplemental) ────────────────────────────────────────────────────

-- getClock / set are symmetry aliases for getTime / setTime.
local elapsed = tween:getClock()                          -- → playhead position in seconds (same as getTime())
tween:set(tween:getDuration() * 0.5)                      -- jump tween to its midpoint without stopping it

-- ─── Easing (standalone functions) ───────────────────────────────────────────

-- All easing functions map a normalised progress t ∈ [0, 1] to a shaped output.
-- Elastic and Back variants may briefly exceed the [0, 1] range.
--
--   Ease-IN      → slow start, fast finish  — good for elements entering the scene
--   Ease-OUT     → fast start, slow finish  — good for elements settling or landing
--   Ease-IN-OUT  → slow–fast–slow           — good for camera pans and UI transitions

local t = 0.6   -- example progress value

-- Linear (no shaping)
local v_linear    = luna.math.linear(t)          -- → 0.6  (identity; use when no easing is needed)

-- Quadratic — gentle, almost imperceptible at low t
local v_inQuad    = luna.math.inQuad(t)          -- → 0.36  gentle acceleration
local v_outQuad   = luna.math.outQuad(t)         -- → 0.84  gentle deceleration; most common for UI
local v_inOutQuad = luna.math.inOutQuad(t)       -- → 0.72  smooth symmetric feel

-- Cubic — more pronounced than quadratic
local v_inCubic    = luna.math.inCubic(t)        -- → 0.216 sharper acceleration
local v_outCubic   = luna.math.outCubic(t)       -- → 0.936 crisp deceleration
local v_inOutCubic = luna.math.inOutCubic(t)     -- → 0.648 balanced snap

-- Quartic — strong, cinematic feel
local v_inQuart    = luna.math.inQuart(t)        -- → 0.130 dramatic slow start
local v_outQuart   = luna.math.outQuart(t)       -- → 0.974 very fast start, then sudden stop
local v_inOutQuart = luna.math.inOutQuart(t)     -- → 0.741 punchy middle

-- Sinusoidal — the softest of the power easings; follows a cosine curve
local v_inSine    = luna.math.inSine(t)          -- → subtle acceleration; good for breathing animations
local v_outSine   = luna.math.outSine(t)         -- → subtle deceleration
local v_inOutSine = luna.math.inOutSine(t)       -- → very gentle overall arc

-- Exponential — nearly flat then explosive (or vice versa)
local v_inExpo    = luna.math.inExpo(t)          -- → barely moves then launches hard
local v_outExpo   = luna.math.outExpo(t)         -- → explosive start, nearly stops; good for projectiles
local v_inOutExpo = luna.math.inOutExpo(t)       -- → symmetric exponential snap

-- Elastic — spring-like oscillation past the end value
local v_inElastic  = luna.math.inElastic(t)      -- → wobbles before leaving; unusual but dramatic
local v_outElastic = luna.math.outElastic(t)     -- → overshoots then settles; great for UI pop-in

-- Bounce — simulates a physical bounce (multiple sub-bounces)
local v_inBounce  = luna.math.inBounce(t)        -- → bounces before the move begins; rarely used
local v_outBounce = luna.math.outBounce(t)       -- → bounces after arriving; classic ball-drop feel

-- Back — slight overshoot, like a rubber-band pull or snap
local v_inBack  = luna.math.inBack(t)            -- → pulls back briefly then launches forward
local v_outBack = luna.math.outBack(t)           -- → flies past target then snaps back; good for menu items

-- applyEasing() resolves an easing by name at runtime — useful for data-driven
-- configurations where the easing curve is stored in a table or script.
local easing_name = "outQuad"
local shaped = luna.math.applyEasing(easing_name, t)   -- → same as outQuad(t); name looked up dynamically

-- ─── Geometry utilities ───────────────────────────────────────────────────────

-- Shared polygon: a simple hexagonal room outline (flat {x, y, ...} list).
-- Many geometry functions accept this format directly.
local room = {
     50,  50,
    350,  50,
    380, 180,
    200, 300,
     20, 180,
}

local player_x, player_y =  120, 180   -- current player position
local enemy_x,  enemy_y  =  280,  90   -- enemy position

-- Angle from player to enemy (use to point a sprite or aim a projectile)
local aim_angle = luna.math.angleBetween(player_x, player_y, enemy_x, enemy_y)  -- → radians

-- Circle-vs-point: is the mouse cursor inside a circular button hitzone?
local inside = luna.math.circleContainsPoint(200, 175, 40, player_x, player_y)  -- → true/false

-- Squared distance: fast broad-phase range check without a sqrt
local dsq = luna.math.distanceSq(player_x, player_y, enemy_x, enemy_y)          -- → squared pixels

-- Circle-vs-circle: rough enemy collision or aggro-range detection
local overlapping = luna.math.circleIntersectsCircle(
    player_x, player_y, 30,
    enemy_x,  enemy_y,  25)                                                      -- → true/false

-- Circle-vs-infinite-line: detect whether a sensor circle crosses an infinite wall
local hit_line, lx1, ly1, lx2, ly2 =
    luna.math.circleIntersectsLine(200, 150, 50,  50, 50, 350, 50)               -- → hit, pt1?, pt2?

-- Circle-vs-segment: same test but capped to the actual wall segment length
local hit_seg, sx1, sy1, sx2, sy2 =
    luna.math.circleIntersectsSegment(200, 150, 50,  50, 50, 350, 50)            -- → hit, pt1?, pt2?

-- Closest point on a wall segment to the player (for push-out or wall sliding)
local cx, cy = luna.math.closestPointOnSegment(
    player_x, player_y,
    50, 50, 350, 50)                                                              -- → (x, y) clamped to segment

-- Convex hull: find the outer boundary of a set of spawn points
local spawn_cloud = { 80,80, 200,40, 320,90, 270,220, 150,260, 60,200, 170,130 }
local hull = luna.math.convexHull(spawn_cloud)        -- → flat {x,y,...} in CCW order

-- isConvex: verify that a hand-authored polygon has no concave notches
local convex = luna.math.isConvex(hull)               -- → true if the hull is convex (it always will be here)

-- Delaunay triangulation: build a nav-mesh or visibility graph from waypoints
local waypoints = { 100,100,  250,80,  300,200,  180,250,  90,210 }
local tri_list  = luna.math.delaunayTriangulate(waypoints)  -- → table of flat 6-float triangle tables
for _, tri in ipairs(tri_list) do
    -- tri = {x1,y1, x2,y2, x3,y3}
end

-- Line intersection: find where two infinite patrol paths cross
local ix, iy = luna.math.lineIntersect(
    50, 50, 350, 50,
    100, 20, 100, 280)                                -- → (x, y) crossing point, or (nil, nil) if parallel

-- Point-in-polygon: is the player standing inside the room?
local in_room = luna.math.pointInPolygon(room, player_x, player_y)   -- → true/false

-- Polygon area: scale loot drop probability by room size
local area = luna.math.polygonArea(room)              -- → signed area in px² (negative = CW winding)

-- Polygon centroid: place the boss or a spotlight at the room's centre of mass
local cent_x, cent_y = luna.math.polygonCentroid(room)                -- → (cx, cy)

-- Segment-vs-segment: bullet ray vs door segment collision
local bullet_hit, bx, by =
    luna.math.segmentIntersectsSegment(
        player_x, player_y, enemy_x, enemy_y,
        200, 50, 200, 200)                            -- → hit, ix?, iy?

-- Bresenham: enumerate every integer grid cell a laser crosses (tile-based LOS)
local cells = luna.math.bresenham(3, 2, 10, 7)        -- → {{x=3,y=2}, {x=4,y=2}, ..., {x=10,y=7}}
for _, cell in ipairs(cells) do
    -- mark tile at (cell.x, cell.y) as visible
end

-- ─── Math wrappers ────────────────────────────────────────────────────────────

-- Trigonometry (all angles in radians)
local s   = luna.math.sin(math.pi / 6)        -- → 0.5
local c   = luna.math.cos(math.pi / 3)        -- → 0.5
local tg  = luna.math.tan(math.pi / 4)        -- → 1.0
local as  = luna.math.asin(0.5)               -- → π/6  (inverse sine)
local ac  = luna.math.acos(0.5)               -- → π/3  (inverse cosine)
local at  = luna.math.atan(1.0)               -- → π/4  single-argument form
local at2 = luna.math.atan(1.0, 1.0)          -- → π/4  two-argument form (y, x); use for direction vectors

-- Angle conversion
local deg_val = luna.math.deg(math.pi)        -- → 180.0  radians → degrees
local rad_val = luna.math.rad(90)             -- → π/2    degrees → radians

-- Algebra
local sq  = luna.math.sqrt(144)               -- → 12.0
local ab  = luna.math.abs(-7.5)               -- → 7.5
local ep  = luna.math.exp(1)                  -- → e ≈ 2.71828
local ln  = luna.math.log(math.exp(1))        -- → 1.0    natural log (base e)
local lg  = luna.math.log(1024, 2)            -- → 10.0   log base 2
local pw  = luna.math.pow(2, 10)              -- → 1024
local sg  = luna.math.sign(-42)               -- → -1    ; sign(0) → 0 ; sign(pos) → 1
local fm  = luna.math.fmod(7.5, 2.0)          -- → 1.5   remainder, same sign as dividend

-- Rounding
local fl  = luna.math.floor(3.9)              -- → 3
local cl  = luna.math.ceil(3.1)               -- → 4
local ro  = luna.math.round(3.5)              -- → 4  (half-up rounding)

-- Scalar utilities
local lo  = luna.math.min(3, 7)               -- → 3
local hi  = luna.math.max(3, 7)               -- → 7
local clv = luna.math.clamp(15, 0, 10)        -- → 10  caps the value to [0, 10]

-- Noise shortcuts — use a NoiseGenerator for seeded/repeatable results;
-- these shortcuts use a fixed internal seed and are good for quick prototyping.
local pn2 = luna.math.perlin2d(0.5, 0.3)           -- → [-1, 1]  2D Perlin
local pn3 = luna.math.perlin3d(0.5, 0.3, 1.2)      -- → [-1, 1]  3D Perlin (e.g. animated terrain)
local sx2 = luna.math.simplex2d(0.5, 0.3)           -- → [-1, 1]  2D Simplex; faster than Perlin
local sfbm = luna.math.fbm(0.5, 0.3)               -- → layered fractal Brownian motion noise
local snz = luna.math.simplexNoise(0.5, 0.3)        -- → aliased form of simplex2d with alternate signature

-- Random shortcuts — use RandomGenerator for reproducible, seeded sequences.
local r  = luna.math.random()                 -- → float in [0, 1)
local ri = luna.math.randomInt(1, 6)          -- → integer in [1, 6] inclusive; e.g. a die roll
