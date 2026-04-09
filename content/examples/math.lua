-- examples/math.lua
-- Lurek2D lurek.math API Reference
-- Every lurek.math function is demonstrated with inline comments.

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Basic Math Functions
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Clamp a value to a range
local clamped = lurek.math.clamp(1.5, 0, 1)   -- â†’ 1
local clamped2 = lurek.math.clamp(-5, 0, 100) -- â†’ 0

-- Linear interpolation between two values
local blend = lurek.math.lerp(0, 100, 0.25)   -- â†’ 25

-- Distance between two points
local dist = lurek.math.distance(0, 0, 3, 4)  -- â†’ 5

-- Angle from point A to point B (in radians)
local ang = lurek.math.angle(0, 0, 1, 0)      -- â†’ 0 (facing right)
local ang2 = lurek.math.angle(0, 0, 0, 1)     -- â†’ math.pi/2 (facing down)

-- Normalize a 2D vector (returns unit vector components)
local nx, ny = lurek.math.normalize(3, 4)     -- â†’ 0.6, 0.8

-- Dot product of two 2D vectors
local d = lurek.math.dot(1, 0, 0, 1)          -- â†’ 0 (perpendicular)

-- Convert from polar (magnitude, angle) to Cartesian (x, y)
local x, y = lurek.math.fromPolar(10, math.pi / 4) -- â†’ 7.07, 7.07

-- Convert from Cartesian to polar (magnitude, angle)
local r, theta = lurek.math.toPolar(1, 1)     -- â†’ 1.41, 0.785

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Standard Math (also available as normal Lua math.*)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local a1 = lurek.math.abs(-7)        -- â†’ 7
local a2 = lurek.math.floor(3.9)     -- â†’ 3
local a3 = lurek.math.ceil(3.1)      -- â†’ 4
local a4 = lurek.math.sqrt(16)       -- â†’ 4
local a5 = lurek.math.sin(math.pi)   -- â†’ ~0
local a6 = lurek.math.cos(0)         -- â†’ 1
local a7 = lurek.math.atan2(1, 0)    -- â†’ pi/2
local a8 = lurek.math.max(3, 7, 2)   -- â†’ 7
local a9 = lurek.math.min(3, 7, 2)   -- â†’ 2
local pi  = lurek.math.pi            -- â†’ 3.14159...

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Color Space Conversion
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- sRGB gamma â†’ linear (for physically correct blending)
local lr, lg, lb, la = lurek.math.gammaToLinear(0.5, 0.5, 0.5, 1.0)

-- Linear â†’ sRGB gamma (for display output)
local gr, gg, gb, ga = lurek.math.linearToGamma(0.21, 0.21, 0.21, 1.0)

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Random Numbers (global state)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Seedless random (integer 1â€“100)
local roll = lurek.math.random(1, 100)

-- Float in range
local speed = lurek.math.randomFloat(0.5, 2.0)

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- RandomGenerator (local seeded instance)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

local rng = lurek.math.newRandomGenerator(42)

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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Easing Functions  (lurek.math.easing table)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- All easing functions: f(t) where t âˆˆ [0, 1] â†’ value âˆˆ [0, 1]
-- Apply to lerp for smooth interpolation

local easing = lurek.math.easing

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
local smooth_x = lurek.math.lerp(0, 800, easing.outQuad(t))

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Tween (automated value interpolation)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Create a tween: duration=1.0s, easing=outQuad, values: from 0â†’100 and from 0â†’255
local tw = lurek.math.newTween(1.0, lurek.math.easing.outQuad, {
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
local dur = tw:getDuration()   -- â†’ 1.0
local now = tw:getTime()       -- current elapsed time
local name = tw:getEasingName()-- â†’ "outQuad"
local cnt = tw:getValueCount() -- â†’ 3

-- Seek to a specific moment
tw:setTime(0.5)  -- jump to 50% through
tw:reset()       -- restart from beginning

-- Add more values dynamically
tw:addValue(0, 360)  -- add rotation 0â†’360

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- BezierCurve
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Define a cubic Bezier with 4 control points {x1,y1, x2,y2, x3,y3, x4,y4}
local curve = lurek.math.newBezierCurve({
    0,   0,    -- P0: start
    100, 0,    -- P1: control 1
    100, 200,  -- P2: control 2
    200, 200,  -- P3: end
})

-- Evaluate position at parameter t âˆˆ [0, 1]
local cx, cy = curve:evaluate(0.5)   -- point at middle of curve

-- Derivative (tangent) at t
local dx, dy = curve:getDerivative(0.5)

-- Approximate arc length
local len = curve:getLength()

-- Get all control points as {x1,y1,...}
local pts = curve:getPoints()

-- Render to polygon points (for drawing), segments = quality
local poly_pts = curve:render(20)  -- 20 line segments

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Transform (2D affine matrix)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

local tf = lurek.math.newTransform()

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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- SpatialHash (broad-phase collision grid)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Create grid with cell size 64 pixels
local grid = lurek.math.newSpatialHash(64)

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
local cell_sz = grid:getCellSize()   -- â†’ 64
local count   = grid:getItemCount()  -- number of tracked objects

-- Clear all
grid:clear()

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- NoiseGenerator
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

local noise = lurek.math.newNoiseGenerator(42) -- optional seed

-- 1D noise (t = time or position along a line)
local n = noise:perlin1d(0.5)   -- â†’ float in roughly [-1, 1]
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Polygon Triangulation (ear-clipping)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
local triangles = lurek.math.triangulate(polygon)
for i = 1, #triangles, 6 do
    local tx1, ty1 = triangles[i],   triangles[i+1]
    local tx2, ty2 = triangles[i+2], triangles[i+3]
    local tx3, ty3 = triangles[i+4], triangles[i+5]
    -- draw triangle (tx1,ty1) â†’ (tx2,ty2) â†’ (tx3,ty3)
end

-- â”€â”€â”€ BezierCurve (supplemental) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Introspect and mutate a curve built in the BezierCurve section above.

local cp_x, cp_y = beziercurve:getControlPoint(2)      -- â†’ (x, y) of the 2nd control point (1-based index)
local cp_count   = beziercurve:getControlPointCount()  -- â†’ total number of control points (4 for a cubic curve)
local arc_len    = beziercurve:length()                -- â†’ approximate arc length; divide by speed to find travel time

beziercurve:removeControlPoint(cp_count)               -- drop the last control point, converting cubic â†’ quadratic

-- â”€â”€â”€ Transform (supplemental) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- inverse() returns a new Transform whose matrix undoes the original's
-- translate/rotate/scale.  Use it to map world-space coordinates (e.g. a mouse
-- click) back into an object's local frame.
local inv = transform:inverse()                        -- â†’ new Transform; applying it reverses transform's effect
local local_x, local_y = inv:transformPoint(400, 300)  -- world mouse pos â†’ local object coords

-- shear() skews axes independently â€” useful for drop shadows, italic slants,
-- and parallax tilt effects.  sx skews X per unit of Y; sy skews Y per unit of X.
transform:shear(0.3, 0.0)                              -- lean rightward 0.3 per Y unit; no vertical skew

-- â”€â”€â”€ Tween (supplemental) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- getClock / set are symmetry aliases for getTime / setTime.
local elapsed = tween:getClock()                          -- â†’ playhead position in seconds (same as getTime())
tween:set(tween:getDuration() * 0.5)                      -- jump tween to its midpoint without stopping it

-- â”€â”€â”€ Easing (standalone functions) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- All easing functions map a normalised progress t âˆˆ [0, 1] to a shaped output.
-- Elastic and Back variants may briefly exceed the [0, 1] range.
--
Ease-IN      â†’ slow start, fast finish  -- good for elements entering the scene
Ease-OUT     â†’ fast start, slow finish  -- good for elements settling or landing
Ease-IN-OUT  â†’ slow  -- fast  -- slow  -- good for camera pans and UI transitions

local t = 0.6   -- example progress value

-- Linear (no shaping)
local v_linear    = lurek.math.linear(t)          -- â†’ 0.6  (identity; use when no easing is needed)

-- Quadratic â€” gentle, almost imperceptible at low t
local v_inQuad    = lurek.math.inQuad(t)          -- â†’ 0.36  gentle acceleration
local v_outQuad   = lurek.math.outQuad(t)         -- â†’ 0.84  gentle deceleration; most common for UI
local v_inOutQuad = lurek.math.inOutQuad(t)       -- â†’ 0.72  smooth symmetric feel

-- Cubic â€” more pronounced than quadratic
local v_inCubic    = lurek.math.inCubic(t)        -- â†’ 0.216 sharper acceleration
local v_outCubic   = lurek.math.outCubic(t)       -- â†’ 0.936 crisp deceleration
local v_inOutCubic = lurek.math.inOutCubic(t)     -- â†’ 0.648 balanced snap

-- Quartic â€” strong, cinematic feel
local v_inQuart    = lurek.math.inQuart(t)        -- â†’ 0.130 dramatic slow start
local v_outQuart   = lurek.math.outQuart(t)       -- â†’ 0.974 very fast start, then sudden stop
local v_inOutQuart = lurek.math.inOutQuart(t)     -- â†’ 0.741 punchy middle

-- Sinusoidal â€” the softest of the power easings; follows a cosine curve
local v_inSine    = lurek.math.inSine(t)          -- â†’ subtle acceleration; good for breathing animations
local v_outSine   = lurek.math.outSine(t)         -- â†’ subtle deceleration
local v_inOutSine = lurek.math.inOutSine(t)       -- â†’ very gentle overall arc

-- Exponential â€” nearly flat then explosive (or vice versa)
local v_inExpo    = lurek.math.inExpo(t)          -- â†’ barely moves then launches hard
local v_outExpo   = lurek.math.outExpo(t)         -- â†’ explosive start, nearly stops; good for projectiles
local v_inOutExpo = lurek.math.inOutExpo(t)       -- â†’ symmetric exponential snap

-- Elastic â€” spring-like oscillation past the end value
local v_inElastic  = lurek.math.inElastic(t)      -- â†’ wobbles before leaving; unusual but dramatic
local v_outElastic = lurek.math.outElastic(t)     -- â†’ overshoots then settles; great for UI pop-in

-- Bounce â€” simulates a physical bounce (multiple sub-bounces)
local v_inBounce  = lurek.math.inBounce(t)        -- â†’ bounces before the move begins; rarely used
local v_outBounce = lurek.math.outBounce(t)       -- â†’ bounces after arriving; classic ball-drop feel

-- Back â€” slight overshoot, like a rubber-band pull or snap
local v_inBack  = lurek.math.inBack(t)            -- â†’ pulls back briefly then launches forward
local v_outBack = lurek.math.outBack(t)           -- â†’ flies past target then snaps back; good for menu items

-- applyEasing() resolves an easing by name at runtime â€” useful for data-driven
-- configurations where the easing curve is stored in a table or script.
local easing_name = "outQuad"
local shaped = lurek.math.applyEasing(easing_name, t)   -- â†’ same as outQuad(t); name looked up dynamically

-- â”€â”€â”€ Geometry utilities â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
local aim_angle = lurek.math.angleBetween(player_x, player_y, enemy_x, enemy_y)  -- â†’ radians

-- Circle-vs-point: is the mouse cursor inside a circular button hitzone?
local inside = lurek.math.circleContainsPoint(200, 175, 40, player_x, player_y)  -- â†’ true/false

-- Squared distance: fast broad-phase range check without a sqrt
local dsq = lurek.math.distanceSq(player_x, player_y, enemy_x, enemy_y)          -- â†’ squared pixels

-- Circle-vs-circle: rough enemy collision or aggro-range detection
local overlapping = lurek.math.circleIntersectsCircle(
    player_x, player_y, 30,
    enemy_x,  enemy_y,  25)                                                      -- â†’ true/false

-- Circle-vs-infinite-line: detect whether a sensor circle crosses an infinite wall
local hit_line, lx1, ly1, lx2, ly2 =
    lurek.math.circleIntersectsLine(200, 150, 50,  50, 50, 350, 50)               -- â†’ hit, pt1?, pt2?

-- Circle-vs-segment: same test but capped to the actual wall segment length
local hit_seg, sx1, sy1, sx2, sy2 =
    lurek.math.circleIntersectsSegment(200, 150, 50,  50, 50, 350, 50)            -- â†’ hit, pt1?, pt2?

-- Closest point on a wall segment to the player (for push-out or wall sliding)
local cx, cy = lurek.math.closestPointOnSegment(
    player_x, player_y,
    50, 50, 350, 50)                                                              -- â†’ (x, y) clamped to segment

-- Convex hull: find the outer boundary of a set of spawn points
local spawn_cloud = { 80,80, 200,40, 320,90, 270,220, 150,260, 60,200, 170,130 }
local hull = lurek.math.convexHull(spawn_cloud)        -- â†’ flat {x,y,...} in CCW order

-- isConvex: verify that a hand-authored polygon has no concave notches
local convex = lurek.math.isConvex(hull)               -- â†’ true if the hull is convex (it always will be here)

-- Delaunay triangulation: build a nav-mesh or visibility graph from waypoints
local waypoints = { 100,100,  250,80,  300,200,  180,250,  90,210 }
local tri_list  = lurek.math.delaunayTriangulate(waypoints)  -- â†’ table of flat 6-float triangle tables
for _, tri in ipairs(tri_list) do
    -- tri = {x1,y1, x2,y2, x3,y3}
end

-- Line intersection: find where two infinite patrol paths cross
local ix, iy = lurek.math.lineIntersect(
    50, 50, 350, 50,
    100, 20, 100, 280)                                -- â†’ (x, y) crossing point, or (nil, nil) if parallel

-- Point-in-polygon: is the player standing inside the room?
local in_room = lurek.math.pointInPolygon(room, player_x, player_y)   -- â†’ true/false

-- Polygon area: scale loot drop probability by room size
local area = lurek.math.polygonArea(room)              -- â†’ signed area in pxÂ² (negative = CW winding)

-- Polygon centroid: place the boss or a spotlight at the room's centre of mass
local cent_x, cent_y = lurek.math.polygonCentroid(room)                -- â†’ (cx, cy)

-- Segment-vs-segment: bullet ray vs door segment collision
local bullet_hit, bx, by =
    lurek.math.segmentIntersectsSegment(
        player_x, player_y, enemy_x, enemy_y,
        200, 50, 200, 200)                            -- â†’ hit, ix?, iy?

-- Bresenham: enumerate every integer grid cell a laser crosses (tile-based LOS)
local cells = lurek.math.bresenham(3, 2, 10, 7)        -- â†’ {{x=3,y=2}, {x=4,y=2}, ..., {x=10,y=7}}
for _, cell in ipairs(cells) do
    -- mark tile at (cell.x, cell.y) as visible
end

-- â”€â”€â”€ Math wrappers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Trigonometry (all angles in radians)
local s   = lurek.math.sin(math.pi / 6)        -- â†’ 0.5
local c   = lurek.math.cos(math.pi / 3)        -- â†’ 0.5
local tg  = lurek.math.tan(math.pi / 4)        -- â†’ 1.0
local as  = lurek.math.asin(0.5)               -- â†’ Ï€/6  (inverse sine)
local ac  = lurek.math.acos(0.5)               -- â†’ Ï€/3  (inverse cosine)
local at  = lurek.math.atan(1.0)               -- â†’ Ï€/4  single-argument form
local at2 = lurek.math.atan(1.0, 1.0)          -- â†’ Ï€/4  two-argument form (y, x); use for direction vectors

-- Angle conversion
local deg_val = lurek.math.deg(math.pi)        -- â†’ 180.0  radians â†’ degrees
local rad_val = lurek.math.rad(90)             -- â†’ Ï€/2    degrees â†’ radians

-- Algebra
local sq  = lurek.math.sqrt(144)               -- â†’ 12.0
local ab  = lurek.math.abs(-7.5)               -- â†’ 7.5
local ep  = lurek.math.exp(1)                  -- â†’ e â‰ˆ 2.71828
local ln  = lurek.math.log(math.exp(1))        -- â†’ 1.0    natural log (base e)
local lg  = lurek.math.log(1024, 2)            -- â†’ 10.0   log base 2
local pw  = lurek.math.pow(2, 10)              -- â†’ 1024
local sg  = lurek.math.sign(-42)               -- â†’ -1    ; sign(0) â†’ 0 ; sign(pos) â†’ 1
local fm  = lurek.math.fmod(7.5, 2.0)          -- â†’ 1.5   remainder, same sign as dividend

-- Rounding
local fl  = lurek.math.floor(3.9)              -- â†’ 3
local cl  = lurek.math.ceil(3.1)               -- â†’ 4
local ro  = lurek.math.round(3.5)              -- â†’ 4  (half-up rounding)

-- Scalar utilities
local lo  = lurek.math.min(3, 7)               -- â†’ 3
local hi  = lurek.math.max(3, 7)               -- â†’ 7
local clv = lurek.math.clamp(15, 0, 10)        -- â†’ 10  caps the value to [0, 10]

-- Noise shortcuts â€” use a NoiseGenerator for seeded/repeatable results;
-- these shortcuts use a fixed internal seed and are good for quick prototyping.
local pn2 = lurek.math.perlin2d(0.5, 0.3)           -- â†’ [-1, 1]  2D Perlin
local pn3 = lurek.math.perlin3d(0.5, 0.3, 1.2)      -- â†’ [-1, 1]  3D Perlin (e.g. animated terrain)
local sx2 = lurek.math.simplex2d(0.5, 0.3)           -- â†’ [-1, 1]  2D Simplex; faster than Perlin
local sfbm = lurek.math.fbm(0.5, 0.3)               -- â†’ layered fractal Brownian motion noise
local snz = lurek.math.simplexNoise(0.5, 0.3)        -- â†’ aliased form of simplex2d with alternate signature

-- Random shortcuts â€” use RandomGenerator for reproducible, seeded sequences.
local r  = lurek.math.random()                 -- â†’ float in [0, 1)
local ri = lurek.math.randomInt(1, 6)          -- â†’ integer in [1, 6] inclusive; e.g. a die roll

-- Math constants
local tau_const = lurek.math.tau   -- 2*pi (6.2831...) — full circle in radians
local inf = lurek.math.huge         -- positive infinity (equivalent to math.huge)
