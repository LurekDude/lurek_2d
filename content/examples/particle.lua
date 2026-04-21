-- content/examples/particle.lua
-- Lurek2D lurek.particle API Reference
-- Run with: cargo run -- content/examples/particle
--
-- Scenario: A spell-casting RPG with fire explosions, smoke trails, magic
-- sparkles, and weapon swing trails. Demonstrates particle system lifecycle,
-- emission control, visual properties, and trail rendering.

print("=== lurek.particle — Particle System ===\n")

-- =============================================================================
-- System & Trail Creation
-- =============================================================================

--@api-stub: lurek.particle.newSystem
local fire = lurek.particle.newSystem(500)

--@api-stub: lurek.particle.newTrail
local sword_trail = lurek.particle.newTrail()

-- =============================================================================
-- Position & Movement
-- =============================================================================

--@api-stub: ParticleSystem:setPosition
fire:setPosition(400, 300)

--@api-stub: ParticleSystem:getPosition
local px, py = fire:getPosition()
print("fire at: " .. px .. "," .. py)

--@api-stub: ParticleSystem:moveTo
-- Smoothly reposition without teleporting particles.
fire:moveTo(420, 310)

-- =============================================================================
-- Emission Control
-- =============================================================================

--@api-stub: ParticleSystem:setEmissionRate
fire:setEmissionRate(50)

--@api-stub: ParticleSystem:getEmissionRate
print("rate: " .. fire:getEmissionRate())

--@api-stub: ParticleSystem:setEmitterLifetime
-- Emitter lives for 2 seconds (burst effect).
fire:setEmitterLifetime(2.0)

--@api-stub: ParticleSystem:getEmitterLifetime
print("emitter life: " .. fire:getEmitterLifetime())

--@api-stub: ParticleSystem:emit
-- Burst-emit 20 particles for an explosion.
fire:emit(20)

--@api-stub: ParticleSystem:setBufferSize
fire:setBufferSize(1000)

--@api-stub: ParticleSystem:getBufferSize
print("buffer: " .. fire:getBufferSize())

--@api-stub: ParticleSystem:setInsertMode
fire:setInsertMode("top")

--@api-stub: ParticleSystem:getInsertMode
print("insert mode: " .. fire:getInsertMode())

-- =============================================================================
-- Particle Lifetime & Speed
-- =============================================================================

--@api-stub: ParticleSystem:setParticleLifetime
fire:setParticleLifetime(0.5, 1.5)

--@api-stub: ParticleSystem:getParticleLifetime
local minl, maxl = fire:getParticleLifetime()
print("life: " .. minl .. "-" .. maxl)

--@api-stub: ParticleSystem:setSpeed
fire:setSpeed(50, 150)

--@api-stub: ParticleSystem:getSpeed
local mins, maxs = fire:getSpeed()
print("speed: " .. mins .. "-" .. maxs)

--@api-stub: ParticleSystem:setDirection
fire:setDirection(math.pi * 1.5)  -- upward

--@api-stub: ParticleSystem:getDirection
print("direction: " .. fire:getDirection())

--@api-stub: ParticleSystem:setSpread
fire:setSpread(math.pi / 4)

--@api-stub: ParticleSystem:getSpread
print("spread: " .. fire:getSpread())

-- =============================================================================
-- Acceleration & Damping
-- =============================================================================

--@api-stub: ParticleSystem:getLinearAcceleration
local ax1, ay1, ax2, ay2 = fire:getLinearAcceleration()

--@api-stub: ParticleSystem:getRadialAcceleration
local rmin, rmax = fire:getRadialAcceleration()

--@api-stub: ParticleSystem:getTangentialAcceleration
local tmin, tmax = fire:getTangentialAcceleration()

--@api-stub: ParticleSystem:setLinearDamping
fire:setLinearDamping(0.5, 1.0)

--@api-stub: ParticleSystem:getLinearDamping
local dmin, dmax = fire:getLinearDamping()
print("damping: " .. dmin .. "-" .. dmax)

--@api-stub: ParticleSystem:setGravity
fire:setGravity(0, -50)

--@api-stub: ParticleSystem:getGravity
local gx, gy = fire:getGravity()
print("gravity: " .. gx .. "," .. gy)

-- =============================================================================
-- Size
-- =============================================================================

--@api-stub: ParticleSystem:setSizes
-- Size over lifetime: start big, shrink to nothing.
fire:setSizes(2.0, 1.5, 0.5, 0.0)

--@api-stub: ParticleSystem:getSizes
local sizes = fire:getSizes()
print("size steps: " .. #sizes)

--@api-stub: ParticleSystem:setSizeVariation
fire:setSizeVariation(0.3)

--@api-stub: ParticleSystem:getSizeVariation
print("size variation: " .. fire:getSizeVariation())

-- =============================================================================
-- Rotation & Spin
-- =============================================================================

--@api-stub: ParticleSystem:setRotation
fire:setRotation(0, math.pi * 2)

--@api-stub: ParticleSystem:getRotation
local rmin2, rmax2 = fire:getRotation()

--@api-stub: ParticleSystem:setSpin
fire:setSpin(-2, 2)

--@api-stub: ParticleSystem:getSpin
local smin, smax = fire:getSpin()

--@api-stub: ParticleSystem:setSpinVariation
fire:setSpinVariation(0.5)

--@api-stub: ParticleSystem:getSpinVariation
print("spin var: " .. fire:getSpinVariation())

--@api-stub: ParticleSystem:setRelativeRotation
fire:setRelativeRotation(true)

--@api-stub: ParticleSystem:hasRelativeRotation
print("relative rot: " .. tostring(fire:hasRelativeRotation()))

-- =============================================================================
-- Colors
-- =============================================================================

--@api-stub: ParticleSystem:setColors
-- Fire gradient: white → yellow → orange → red → transparent.
fire:setColors(
    1.0, 1.0, 1.0, 1.0,
    1.0, 0.9, 0.3, 1.0,
    1.0, 0.5, 0.1, 0.8,
    0.8, 0.2, 0.0, 0.0
)

--@api-stub: ParticleSystem:getColors
local colors = fire:getColors()
print("color stops: " .. #colors / 4)

-- =============================================================================
-- Emission Shape & Area
-- =============================================================================

--@api-stub: ParticleSystem:setEmissionArea
fire:setEmissionArea("uniform", 20, 20)

--@api-stub: ParticleSystem:getEmissionArea
local shape, w, h = fire:getEmissionArea()
print("emission: " .. shape .. " " .. w .. "x" .. h)

--@api-stub: ParticleSystem:setShape
fire:setShape("circle")

--@api-stub: ParticleSystem:getShape
print("shape: " .. fire:getShape())

--@api-stub: ParticleSystem:setOffset
fire:setOffset(0, -10)

--@api-stub: ParticleSystem:getOffset
local ofx, ofy = fire:getOffset()
print("offset: " .. ofx .. "," .. ofy)

-- =============================================================================
-- Lifecycle
-- =============================================================================

--@api-stub: ParticleSystem:start
fire:start()

--@api-stub: ParticleSystem:isActive
print("active: " .. tostring(fire:isActive()))

--@api-stub: ParticleSystem:update
fire:update(1/60)

--@api-stub: ParticleSystem:count
print("alive particles: " .. fire:count())

--@api-stub: ParticleSystem:getCount
print("count: " .. fire:getCount())

--@api-stub: ParticleSystem:pause
fire:pause()

--@api-stub: ParticleSystem:isPaused
print("paused: " .. tostring(fire:isPaused()))

--@api-stub: ParticleSystem:resume
fire:resume()

--@api-stub: ParticleSystem:stop
fire:stop()

--@api-stub: ParticleSystem:isStopped
print("stopped: " .. tostring(fire:isStopped()))

--@api-stub: ParticleSystem:isEmpty
print("empty: " .. tostring(fire:isEmpty()))

--@api-stub: ParticleSystem:isFull
print("full: " .. tostring(fire:isFull()))

--@api-stub: ParticleSystem:reset
fire:reset()

-- =============================================================================
-- Rendering
-- =============================================================================

--@api-stub: ParticleSystem:render
fire:render()

--@api-stub: ParticleSystem:drawToImage
local img = fire:drawToImage(256, 256)

--@api-stub: ParticleSystem:toImage
local snap = fire:toImage()

-- =============================================================================
-- Advanced Features
-- =============================================================================

--@api-stub: ParticleSystem:clone
-- Clone the fire system for multiple spell effects.
local fire2 = fire:clone()
fire2:setPosition(600, 300)

--@api-stub: ParticleSystem:warmUp
-- Pre-simulate particles so system doesn't start empty.
fire:warmUp(0.5)

--@api-stub: ParticleSystem:clearAttractors
fire:clearAttractors()

--@api-stub: ParticleSystem:getAttractorCount
print("attractors: " .. fire:getAttractorCount())

--@api-stub: ParticleSystem:clearBounds
fire:clearBounds()

--@api-stub: ParticleSystem:addSubEmitter
-- Spawn smoke sub-particles when fire particles die.
-- fire:addSubEmitter("death", smoke_system)

--@api-stub: ParticleSystem:setFlipbook
fire:setFlipbook(4, 4, 16)

--@api-stub: ParticleSystem:getFlipbook
local cols, rows, frames = fire:getFlipbook()
print("flipbook: " .. cols .. "x" .. rows .. " (" .. frames .. " frames)")

--@api-stub: ParticleSystem:release
-- fire:release()

--@api-stub: ParticleSystem:type
print("type: " .. fire:type())

--@api-stub: ParticleSystem:typeOf
print("is ParticleSystem: " .. tostring(fire:typeOf("ParticleSystem")))

-- =============================================================================
-- Trail — Sword swing trail
-- =============================================================================

--@api-stub: Trail:setWidth
sword_trail:setWidth(8.0)

--@api-stub: Trail:getWidth
print("trail width: " .. sword_trail:getWidth())

--@api-stub: Trail:setLifetime
sword_trail:setLifetime(0.3)

--@api-stub: Trail:getLifetime
print("trail life: " .. sword_trail:getLifetime())

--@api-stub: Trail:setMinDistance
-- Minimum distance between trail points (avoids clutter).
sword_trail:setMinDistance(4.0)

--@api-stub: Trail:pushPoint
-- Push trail points each frame along the sword tip path.
sword_trail:pushPoint(100, 200)
sword_trail:pushPoint(120, 180)
sword_trail:pushPoint(140, 165)

--@api-stub: Trail:getPointCount
print("trail points: " .. sword_trail:getPointCount())

--@api-stub: Trail:update
sword_trail:update(1/60)

--@api-stub: Trail:drawToImage
local trail_img = sword_trail:drawToImage(256, 256)

--@api-stub: Trail:clear
sword_trail:clear()

print("\n-- particle.lua example complete --")

-- =============================================================================
-- STUBS: 1 uncovered lurek.particle API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ParticleSystem methods
-- -----------------------------------------------------------------------------

-- ---- Stub: ParticleSystem:release ----------------------------------------
--@api-stub: ParticleSystem:release
-- Removes the particle system from the engine, freeing its slot.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- particleSystem_stub:release()
-- (replace particleSystem_stub with your real ParticleSystem instance above)
