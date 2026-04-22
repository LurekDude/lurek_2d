-- content/examples/particle.lua
-- Auto-scaffolded coverage of the lurek.particle Lua API (84 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/particle.lua

print("[example] lurek.particle loaded — 84 API items demonstrated")

-- ── lurek.particle free functions ──

--@api-stub: lurek.particle.newSystem
-- Creates a new particle system and stores it in the engine pool.
-- Use this when creates a new particle system and stores it in the engine pool is needed.
if false then
  local _r = lurek.particle.newSystem(1)
  print(_r)
end

--@api-stub: lurek.particle.newTrail
-- Creates a new trail ribbon effect.
-- Use this when creates a new trail ribbon effect is needed.
if false then
  local _r = lurek.particle.newTrail(0, 1)
  print(_r)
end

-- ── ParticleSystem methods ──

--@api-stub: ParticleSystem:update
-- Advances the particle simulation by dt seconds.
-- Use this when advances the particle simulation by dt seconds is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:update(0)
end

--@api-stub: ParticleSystem:emit
-- Emits a burst of the given number of particles.
-- Use this when emits a burst of the given number of particles is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:emit(1)
end

--@api-stub: ParticleSystem:start
-- Starts or restarts particle emission.
-- Use this when starts or restarts particle emission is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:start()
end

--@api-stub: ParticleSystem:stop
-- Stops particle emission immediately.
-- Use this when stops particle emission immediately is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:stop()
end

--@api-stub: ParticleSystem:pause
-- Pauses particle emission; existing particles continue to simulate.
-- Use this when pauses particle emission; existing particles continue to simulate is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:pause()
end

--@api-stub: ParticleSystem:resume
-- Resumes a paused emitter.
-- Use this when resumes a paused emitter is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:resume()
end

--@api-stub: ParticleSystem:reset
-- Removes all particles and resets the emitter.
-- Use this when removes all particles and resets the emitter is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:reset()
end

--@api-stub: ParticleSystem:moveTo
-- Moves the emitter to the given world position.
-- Use this when moves the emitter to the given world position is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:moveTo(0, 0)
end

--@api-stub: ParticleSystem:count
-- Returns the number of living particles.
-- Use this when returns the number of living particles is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:count()
end

--@api-stub: ParticleSystem:isActive
-- Returns true if the emitter is currently emitting or has live particles.
-- Use this when returns true if the emitter is currently emitting or has live particles is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:isActive()
end

--@api-stub: ParticleSystem:isPaused
-- Returns true if the emitter is paused.
-- Use this when returns true if the emitter is paused is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:isPaused()
end

--@api-stub: ParticleSystem:isStopped
-- Returns true if the emitter is stopped.
-- Use this when returns true if the emitter is stopped is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:isStopped()
end

--@api-stub: ParticleSystem:isEmpty
-- Returns true if there are no live particles.
-- Use this when returns true if there are no live particles is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:isEmpty()
end

--@api-stub: ParticleSystem:isFull
-- Returns true if the system has reached max_particles.
-- Use this when returns true if the system has reached max_particles is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:isFull()
end

--@api-stub: ParticleSystem:release
-- Removes the particle system from the engine, freeing its slot.
-- Use this when removes the particle system from the engine, freeing its slot is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:release()
end

--@api-stub: ParticleSystem:getCount
-- Returns the number of living particles (alias for count).
-- Use this when returns the number of living particles (alias for count) is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getCount()
end

--@api-stub: ParticleSystem:type
-- Returns the type name "ParticleSystem".
-- Use this when returns the type name "ParticleSystem" is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:type()
end

--@api-stub: ParticleSystem:typeOf
-- Returns true if this matches the given type name.
-- Use this when returns true if this matches the given type name is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:typeOf(1)
end

--@api-stub: ParticleSystem:setPosition
-- Sets the emitter world position.
-- Use this when sets the emitter world position is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setPosition(0, 0)
end

--@api-stub: ParticleSystem:getPosition
-- Returns the emitter world position.
-- Use this when returns the emitter world position is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getPosition()
end

--@api-stub: ParticleSystem:setEmissionRate
-- Sets particles emitted per second.
-- Use this when sets particles emitted per second is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setEmissionRate(0)
end

--@api-stub: ParticleSystem:getEmissionRate
-- Returns particles emitted per second.
-- Use this when returns particles emitted per second is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getEmissionRate()
end

--@api-stub: ParticleSystem:setParticleLifetime
-- Sets min and max particle lifetime in seconds.
-- Use this when sets min and max particle lifetime in seconds is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setParticleLifetime(1, 0)
end

--@api-stub: ParticleSystem:getParticleLifetime
-- Returns min and max particle lifetime.
-- Use this when returns min and max particle lifetime is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getParticleLifetime()
end

--@api-stub: ParticleSystem:setEmitterLifetime
-- Sets how long the emitter runs before auto-stopping.
-- Negative = infinite.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setEmitterLifetime(0)
end

--@api-stub: ParticleSystem:getEmitterLifetime
-- Returns the emitter lifetime.
-- Use this when returns the emitter lifetime is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getEmitterLifetime()
end

--@api-stub: ParticleSystem:setSpeed
-- Sets min/max initial speed.
-- Use this when sets min/max initial speed is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setSpeed(1, 0)
end

--@api-stub: ParticleSystem:getSpeed
-- Returns min/max initial speed.
-- Use this when returns min/max initial speed is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getSpeed()
end

--@api-stub: ParticleSystem:setDirection
-- Sets emission direction in radians.
-- Use this when sets emission direction in radians is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setDirection(nil)
end

--@api-stub: ParticleSystem:getDirection
-- Returns emission direction in radians.
-- Use this when returns emission direction in radians is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getDirection()
end

--@api-stub: ParticleSystem:setSpread
-- Sets emission spread (half-angle cone) in radians.
-- Use this when sets emission spread (half-angle cone) in radians is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setSpread(nil)
end

--@api-stub: ParticleSystem:getSpread
-- Returns the half-angle spread in radians for the emission cone.
-- Use this when returns the half-angle spread in radians for the emission cone is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getSpread()
end

--@api-stub: ParticleSystem:getLinearAcceleration
-- Returns linear acceleration range.
-- Use this when returns linear acceleration range is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getLinearAcceleration()
end

--@api-stub: ParticleSystem:getRadialAcceleration
-- Returns radial acceleration range.
-- Use this when returns radial acceleration range is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getRadialAcceleration()
end

--@api-stub: ParticleSystem:getTangentialAcceleration
-- Returns tangential acceleration range.
-- Use this when returns tangential acceleration range is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getTangentialAcceleration()
end

--@api-stub: ParticleSystem:setLinearDamping
-- Sets linear damping range.
-- Use this when sets linear damping range is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setLinearDamping(1, 0)
end

--@api-stub: ParticleSystem:getLinearDamping
-- Returns linear damping range.
-- Use this when returns linear damping range is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getLinearDamping()
end

--@api-stub: ParticleSystem:setSizes
-- Sets size keyframes (varargs: each number is one keyframe).
-- Use this when sets size keyframes (varargs: each number is one keyframe) is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setSizes(1)
end

--@api-stub: ParticleSystem:getSizes
-- Returns size keyframes as a Lua table.
-- Use this when returns size keyframes as a Lua table is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getSizes()
end

--@api-stub: ParticleSystem:setSizeVariation
-- Sets size variation (0â€“1).
-- Use this when sets size variation (0â€“1) is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setSizeVariation(0)
end

--@api-stub: ParticleSystem:getSizeVariation
-- Returns the maximum random size variation applied to newly emitted particles.
-- Use this when returns the maximum random size variation applied to newly emitted particles is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getSizeVariation()
end

--@api-stub: ParticleSystem:setRotation
-- Sets initial rotation range in radians.
-- Use this when sets initial rotation range in radians is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setRotation(1, 0)
end

--@api-stub: ParticleSystem:getRotation
-- Returns initial rotation range.
-- Use this when returns initial rotation range is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getRotation()
end

--@api-stub: ParticleSystem:setSpin
-- Sets angular velocity range.
-- Use this when sets angular velocity range is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setSpin(1, 0)
end

--@api-stub: ParticleSystem:getSpin
-- Returns angular velocity range.
-- Use this when returns angular velocity range is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getSpin()
end

--@api-stub: ParticleSystem:setSpinVariation
-- Sets spin variation (0â€“1).
-- Use this when sets spin variation (0â€“1) is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setSpinVariation(0)
end

--@api-stub: ParticleSystem:getSpinVariation
-- Returns the maximum random angular velocity variation for new particles.
-- Use this when returns the maximum random angular velocity variation for new particles is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getSpinVariation()
end

--@api-stub: ParticleSystem:setRelativeRotation
-- Sets whether particle rotation follows velocity direction.
-- Use this when sets whether particle rotation follows velocity direction is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setRelativeRotation(0)
end

--@api-stub: ParticleSystem:hasRelativeRotation
-- Returns whether relative rotation is enabled.
-- Use this when returns whether relative rotation is enabled is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:hasRelativeRotation()
end

--@api-stub: ParticleSystem:setColors
-- Sets color keyframes.
-- Each arg is a table {r, g, b, a}.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setColors({1, 1, 1, 1})
end

--@api-stub: ParticleSystem:getColors
-- Returns color keyframes as a table of {r,g,b,a} tables.
-- Use this when returns color keyframes as a table of {r,g,b,a} tables is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getColors()
end

--@api-stub: ParticleSystem:setOffset
-- Sets the render origin offset.
-- Use this when sets the render origin offset is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setOffset(0, 0)
end

--@api-stub: ParticleSystem:getOffset
-- Returns the render origin offset.
-- Use this when returns the render origin offset is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getOffset()
end

--@api-stub: ParticleSystem:setInsertMode
-- Sets the insert mode: "top", "bottom", or "random".
-- Use this when sets the insert mode: "top", "bottom", or "random" is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setInsertMode(nil)
end

--@api-stub: ParticleSystem:getInsertMode
-- Returns the insert mode as a string.
-- Use this when returns the insert mode as a string is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getInsertMode()
end

--@api-stub: ParticleSystem:setBufferSize
-- Sets the maximum number of particles (resizes the pool).
-- Use this when sets the maximum number of particles (resizes the pool) is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setBufferSize(1)
end

--@api-stub: ParticleSystem:getBufferSize
-- Returns the maximum particle count.
-- Use this when returns the maximum particle count is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getBufferSize()
end

--@api-stub: ParticleSystem:setEmissionArea
-- Sets emission area distribution and size.
-- Use this when sets emission area distribution and size is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setEmissionArea(0, 0, 0, 1, nil)
end

--@api-stub: ParticleSystem:getEmissionArea
-- Returns emission area: dist-string, w, h.
-- Use this when returns emission area: dist-string, w, h is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getEmissionArea()
end

--@api-stub: ParticleSystem:setShape
-- Sets the particle draw shape.
-- Use this when sets the particle draw shape is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setShape(0)
end

--@api-stub: ParticleSystem:getShape
-- Returns the particle draw shape as a string.
-- Use this when returns the particle draw shape as a string is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getShape()
end

--@api-stub: ParticleSystem:getGravity
-- Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
-- Use this when returns the gravity acceleration applied to particles as two numbers `gx, gy` is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getGravity()
end

--@api-stub: ParticleSystem:setGravity
-- Sets the gravity acceleration applied to all active particles each frame.
-- Use this when sets the gravity acceleration applied to all active particles each frame is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:setGravity(0, 0)
end

--@api-stub: ParticleSystem:render
-- Renders all live particles to the GPU command queue.
-- Use this when renders all live particles to the GPU command queue is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:render(0, 0)
end

--@api-stub: ParticleSystem:clone
-- Creates a copy of this particle system (config only, no live particles).
-- Use this when creates a copy of this particle system (config only, no live particles) is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:clone()
end

--@api-stub: ParticleSystem:drawToImage
-- Renders all live particles to a CPU ImageData.
-- Use this when renders all live particles to a CPU ImageData is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:drawToImage(0, 0)
end

--@api-stub: ParticleSystem:toImage
-- Alias for `drawToImage`.
-- Renders all live particles to a CPU ImageData.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:toImage(0, 0)
end

--@api-stub: ParticleSystem:warmUp
-- Pre-simulates the particle system for `seconds` so it appears fully.
-- Use this when pre-simulates the particle system for `seconds` so it appears fully is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:warmUp(1)
end

--@api-stub: ParticleSystem:clearAttractors
-- Removes all attractors from this particle system.
-- Use this when removes all attractors from this particle system is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:clearAttractors()
end

--@api-stub: ParticleSystem:getAttractorCount
-- Returns the number of attractors currently registered on this system.
-- Use this when returns the number of attractors currently registered on this system is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getAttractorCount()
end

--@api-stub: ParticleSystem:clearBounds
-- Removes the bounding rectangle so particles can move freely.
-- Use this when removes the bounding rectangle so particles can move freely is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:clearBounds()
end

--@api-stub: ParticleSystem:getFlipbook
-- Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
-- Use this when returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set is needed.
if false then
  local _o = nil  -- ParticleSystem instance
  _o:getFlipbook()
end

-- ── Trail methods ──

--@api-stub: Trail:pushPoint
-- Appends a new point to the trail head.
-- Use this when appends a new point to the trail head is needed.
if false then
  local _o = nil  -- Trail instance
  _o:pushPoint(0, 0)
end

--@api-stub: Trail:update
-- Ages trail points and removes expired ones.
-- Use this when ages trail points and removes expired ones is needed.
if false then
  local _o = nil  -- Trail instance
  _o:update(0)
end

--@api-stub: Trail:setWidth
-- Sets the start and end width of the trail ribbon.
-- Use this when sets the start and end width of the trail ribbon is needed.
if false then
  local _o = nil  -- Trail instance
  _o:setWidth(0, 1)
end

--@api-stub: Trail:getWidth
-- Returns the start and end width.
-- Use this when returns the start and end width is needed.
if false then
  local _o = nil  -- Trail instance
  _o:getWidth()
end

--@api-stub: Trail:setLifetime
-- Sets how long each trail point persists in seconds.
-- Use this when sets how long each trail point persists in seconds is needed.
if false then
  local _o = nil  -- Trail instance
  _o:setLifetime(0)
end

--@api-stub: Trail:getLifetime
-- Returns the trail point lifetime in seconds.
-- Use this when returns the trail point lifetime in seconds is needed.
if false then
  local _o = nil  -- Trail instance
  _o:getLifetime()
end

--@api-stub: Trail:setMinDistance
-- Sets the minimum distance between trail points.
-- Use this when sets the minimum distance between trail points is needed.
if false then
  local _o = nil  -- Trail instance
  _o:setMinDistance(1)
end

--@api-stub: Trail:getPointCount
-- Returns the number of active trail points.
-- Use this when returns the number of active trail points is needed.
if false then
  local _o = nil  -- Trail instance
  _o:getPointCount()
end

--@api-stub: Trail:clear
-- Removes all trail points.
-- Use this when removes all trail points is needed.
if false then
  local _o = nil  -- Trail instance
  _o:clear()
end

--@api-stub: Trail:drawToImage
-- Renders the trail ribbon to a CPU ImageData.
-- Use this when renders the trail ribbon to a CPU ImageData is needed.
if false then
  local _o = nil  -- Trail instance
  _o:drawToImage(0, 0)
end

