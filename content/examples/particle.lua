-- content/examples/particle.lua
-- Lurek2D lurek.particle API Reference
-- Run with: cargo run -- content/examples/particle
--
Scenario: A spell-casting RPG with fire explosions, smoke trails, magic
-- sparkles, and weapon swing trails. Demonstrates particle system lifecycle,
-- emission control, visual properties, and trail rendering.

print("=== lurek.particle — Particle System ===\n")

-- =============================================================================
-- System & Trail Creation
-- =============================================================================

local fire = lurek.particle.newSystem(500)

local sword_trail = lurek.particle.newTrail()

-- =============================================================================
-- Position & Movement
-- =============================================================================

fire:setPosition(400, 300)

local px, py = fire:getPosition()
print("fire at: " .. px .. "," .. py)

-- Smoothly reposition without teleporting particles.
fire:moveTo(420, 310)

-- =============================================================================
-- Emission Control
-- =============================================================================

fire:setEmissionRate(50)

print("rate: " .. fire:getEmissionRate())

-- Emitter lives for 2 seconds (burst effect).
fire:setEmitterLifetime(2.0)

print("emitter life: " .. fire:getEmitterLifetime())

-- Burst-emit 20 particles for an explosion.
fire:emit(20)

fire:setBufferSize(1000)

print("buffer: " .. fire:getBufferSize())

fire:setInsertMode("top")

print("insert mode: " .. fire:getInsertMode())

-- =============================================================================
-- Particle Lifetime & Speed
-- =============================================================================

fire:setParticleLifetime(0.5, 1.5)

local minl, maxl = fire:getParticleLifetime()
print("life: " .. minl .. "-" .. maxl)

fire:setSpeed(50, 150)

local mins, maxs = fire:getSpeed()
print("speed: " .. mins .. "-" .. maxs)

fire:setDirection(math.pi * 1.5)  -- upward

print("direction: " .. fire:getDirection())

fire:setSpread(math.pi / 4)

print("spread: " .. fire:getSpread())

-- =============================================================================
-- Acceleration & Damping
-- =============================================================================

local ax1, ay1, ax2, ay2 = fire:getLinearAcceleration()

local rmin, rmax = fire:getRadialAcceleration()

local tmin, tmax = fire:getTangentialAcceleration()

fire:setLinearDamping(0.5, 1.0)

local dmin, dmax = fire:getLinearDamping()
print("damping: " .. dmin .. "-" .. dmax)

fire:setGravity(0, -50)

local gx, gy = fire:getGravity()
print("gravity: " .. gx .. "," .. gy)

-- =============================================================================
-- Size
-- =============================================================================

-- Size over lifetime: start big, shrink to nothing.
fire:setSizes(2.0, 1.5, 0.5, 0.0)

local sizes = fire:getSizes()
print("size steps: " .. #sizes)

fire:setSizeVariation(0.3)

print("size variation: " .. fire:getSizeVariation())

-- =============================================================================
-- Rotation & Spin
-- =============================================================================

fire:setRotation(0, math.pi * 2)

local rmin2, rmax2 = fire:getRotation()

fire:setSpin(-2, 2)

local smin, smax = fire:getSpin()

fire:setSpinVariation(0.5)

print("spin var: " .. fire:getSpinVariation())

fire:setRelativeRotation(true)

print("relative rot: " .. tostring(fire:hasRelativeRotation()))

-- =============================================================================
-- Colors
-- =============================================================================

-- Fire gradient: white → yellow → orange → red → transparent.
fire:setColors(
    1.0, 1.0, 1.0, 1.0,
    1.0, 0.9, 0.3, 1.0,
    1.0, 0.5, 0.1, 0.8,
    0.8, 0.2, 0.0, 0.0
)

local colors = fire:getColors()
print("color stops: " .. #colors / 4)

-- =============================================================================
-- Emission Shape & Area
-- =============================================================================

fire:setEmissionArea("uniform", 20, 20)

local shape, w, h = fire:getEmissionArea()
print("emission: " .. shape .. " " .. w .. "x" .. h)

fire:setShape("circle")

print("shape: " .. fire:getShape())

fire:setOffset(0, -10)

local ofx, ofy = fire:getOffset()
print("offset: " .. ofx .. "," .. ofy)

-- =============================================================================
-- Lifecycle
-- =============================================================================

fire:start()

print("active: " .. tostring(fire:isActive()))

fire:update(1/60)

print("alive particles: " .. fire:count())

print("count: " .. fire:getCount())

fire:pause()

print("paused: " .. tostring(fire:isPaused()))

fire:resume()

fire:stop()

print("stopped: " .. tostring(fire:isStopped()))

print("empty: " .. tostring(fire:isEmpty()))

print("full: " .. tostring(fire:isFull()))

fire:reset()

-- =============================================================================
-- Rendering
-- =============================================================================

fire:render()

local img = fire:drawToImage(256, 256)

local snap = fire:toImage()

-- =============================================================================
-- Advanced Features
-- =============================================================================

-- Clone the fire system for multiple spell effects.
local fire2 = fire:clone()
fire2:setPosition(600, 300)

-- Pre-simulate particles so system doesn't start empty.
fire:warmUp(0.5)

fire:clearAttractors()

print("attractors: " .. fire:getAttractorCount())

fire:clearBounds()

-- Spawn smoke sub-particles when fire particles die.
fire:addSubEmitter("death", smoke_system)

fire:setFlipbook(4, 4, 16)

local cols, rows, frames = fire:getFlipbook()
print("flipbook: " .. cols .. "x" .. rows .. " (" .. frames .. " frames)")

fire:release()

print("type: " .. fire:type())

print("is ParticleSystem: " .. tostring(fire:typeOf("ParticleSystem")))

-- =============================================================================
-- Trail — Sword swing trail
-- =============================================================================

sword_trail:setWidth(8.0)

print("trail width: " .. sword_trail:getWidth())

sword_trail:setLifetime(0.3)

print("trail life: " .. sword_trail:getLifetime())

-- Minimum distance between trail points (avoids clutter).
sword_trail:setMinDistance(4.0)

-- Push trail points each frame along the sword tip path.
sword_trail:pushPoint(100, 200)
sword_trail:pushPoint(120, 180)
sword_trail:pushPoint(140, 165)

print("trail points: " .. sword_trail:getPointCount())

sword_trail:update(1/60)

local trail_img = sword_trail:drawToImage(256, 256)

sword_trail:clear()

print("\n-- particle.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ParticleSystem methods
-- -----------------------------------------------------------------------------

-- Removes the particle system from the engine, freeing its slot.
particleSystem_stub:release()
