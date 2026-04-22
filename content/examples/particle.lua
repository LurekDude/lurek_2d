-- content/examples/particle.lua
-- Practical usage examples for the lurek.particle API (84 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.particle.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/particle.lua

print("[example] lurek.particle — 84 API entries")

-- ── lurek.particle.* free functions ──

--@api-stub: lurek.particle.newSystem
-- Creates a new particle system and stores it in the engine pool.
-- Call when you need to create a new system.
local ok, obj = pcall(function() return lurek.particle.newSystem({}) end)
if ok and obj then print("created:", obj) end
print("lurek.particle.newSystem ok=", ok)

--@api-stub: lurek.particle.newTrail
-- Creates a new trail ribbon effect.
-- Call when you need to create a new trail.
local ok, obj = pcall(function() return lurek.particle.newTrail(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.particle.newTrail ok=", ok)

-- ── ParticleSystem methods ──

--@api-stub: ParticleSystem:update
-- Advances the particle simulation by dt seconds.
-- Call when you need to invoke update.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("ParticleSystem:update ->", ok, result)
end

--@api-stub: ParticleSystem:emit
-- Emits a burst of the given number of particles.
-- Call when you need to invoke emit.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:emit(10) end)
  print("ParticleSystem:emit ->", ok, result)
end

--@api-stub: ParticleSystem:start
-- Starts or restarts particle emission.
-- Call when you need to invoke start.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:start() end)
  print("ParticleSystem:start ->", ok, result)
end

--@api-stub: ParticleSystem:stop
-- Stops particle emission immediately.
-- Call when you need to invoke stop.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:stop() end)
  print("ParticleSystem:stop ->", ok, result)
end

--@api-stub: ParticleSystem:pause
-- Pauses particle emission; existing particles continue to simulate.
-- Call when you need to invoke pause.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:pause() end)
  print("ParticleSystem:pause ->", ok, result)
end

--@api-stub: ParticleSystem:resume
-- Resumes a paused emitter.
-- Call when you need to invoke resume.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:resume() end)
  print("ParticleSystem:resume ->", ok, result)
end

--@api-stub: ParticleSystem:reset
-- Removes all particles and resets the emitter.
-- Call when you need to invoke reset.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("ParticleSystem:reset ->", ok, result)
end

--@api-stub: ParticleSystem:moveTo
-- Moves the emitter to the given world position.
-- Call when you need to invoke move to.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:moveTo(0, 0) end)
  print("ParticleSystem:moveTo ->", ok, result)
end

--@api-stub: ParticleSystem:count
-- Returns the number of living particles.
-- Call when you need to invoke count.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:count() end)
  print("ParticleSystem:count ->", ok, result)
end

--@api-stub: ParticleSystem:isActive
-- Returns true if the emitter is currently emitting or has live particles.
-- Call when you need to check is active.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:isActive() end)
  print("ParticleSystem:isActive ->", ok, result)
end

--@api-stub: ParticleSystem:isPaused
-- Returns true if the emitter is paused.
-- Call when you need to check is paused.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:isPaused() end)
  print("ParticleSystem:isPaused ->", ok, result)
end

--@api-stub: ParticleSystem:isStopped
-- Returns true if the emitter is stopped.
-- Call when you need to check is stopped.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:isStopped() end)
  print("ParticleSystem:isStopped ->", ok, result)
end

--@api-stub: ParticleSystem:isEmpty
-- Returns true if there are no live particles.
-- Call when you need to check is empty.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("ParticleSystem:isEmpty ->", ok, result)
end

--@api-stub: ParticleSystem:isFull
-- Returns true if the system has reached max_particles.
-- Call when you need to check is full.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:isFull() end)
  print("ParticleSystem:isFull ->", ok, result)
end

--@api-stub: ParticleSystem:release
-- Removes the particle system from the engine, freeing its slot.
-- Call when you need to invoke release.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("ParticleSystem:release ->", ok, result)
end

--@api-stub: ParticleSystem:getCount
-- Returns the number of living particles (alias for count).
-- Call when you need to read count.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("ParticleSystem:getCount ->", ok, result)
end

--@api-stub: ParticleSystem:type
-- Returns the type name "ParticleSystem".
-- Call when you need to invoke type.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("ParticleSystem:type ->", ok, result)
end

--@api-stub: ParticleSystem:typeOf
-- Returns true if this matches the given type name.
-- Call when you need to invoke type of.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("ParticleSystem:typeOf ->", ok, result)
end

--@api-stub: ParticleSystem:setPosition
-- Sets the emitter world position.
-- Call when you need to assign position.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(0, 0) end)
  print("ParticleSystem:setPosition ->", ok, result)
end

--@api-stub: ParticleSystem:getPosition
-- Returns the emitter world position.
-- Call when you need to read position.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getPosition() end)
  print("ParticleSystem:getPosition ->", ok, result)
end

--@api-stub: ParticleSystem:setEmissionRate
-- Sets particles emitted per second.
-- Call when you need to assign emission rate.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setEmissionRate(nil) end)
  print("ParticleSystem:setEmissionRate ->", ok, result)
end

--@api-stub: ParticleSystem:getEmissionRate
-- Returns particles emitted per second.
-- Call when you need to read emission rate.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getEmissionRate() end)
  print("ParticleSystem:getEmissionRate ->", ok, result)
end

--@api-stub: ParticleSystem:setParticleLifetime
-- Sets min and max particle lifetime in seconds.
-- Call when you need to assign particle lifetime.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setParticleLifetime(0, 100) end)
  print("ParticleSystem:setParticleLifetime ->", ok, result)
end

--@api-stub: ParticleSystem:getParticleLifetime
-- Returns min and max particle lifetime.
-- Call when you need to read particle lifetime.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getParticleLifetime() end)
  print("ParticleSystem:getParticleLifetime ->", ok, result)
end

--@api-stub: ParticleSystem:setEmitterLifetime
-- Sets how long the emitter runs before auto-stopping.
-- Negative = infinite.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setEmitterLifetime(nil) end)
  print("ParticleSystem:setEmitterLifetime ->", ok, result)
end

--@api-stub: ParticleSystem:getEmitterLifetime
-- Returns the emitter lifetime.
-- Call when you need to read emitter lifetime.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getEmitterLifetime() end)
  print("ParticleSystem:getEmitterLifetime ->", ok, result)
end

--@api-stub: ParticleSystem:setSpeed
-- Sets min/max initial speed.
-- Call when you need to assign speed.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setSpeed(0, 100) end)
  print("ParticleSystem:setSpeed ->", ok, result)
end

--@api-stub: ParticleSystem:getSpeed
-- Returns min/max initial speed.
-- Call when you need to read speed.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getSpeed() end)
  print("ParticleSystem:getSpeed ->", ok, result)
end

--@api-stub: ParticleSystem:setDirection
-- Sets emission direction in radians.
-- Call when you need to assign direction.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setDirection("dir") end)
  print("ParticleSystem:setDirection ->", ok, result)
end

--@api-stub: ParticleSystem:getDirection
-- Returns emission direction in radians.
-- Call when you need to read direction.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getDirection() end)
  print("ParticleSystem:getDirection ->", ok, result)
end

--@api-stub: ParticleSystem:setSpread
-- Sets emission spread (half-angle cone) in radians.
-- Call when you need to assign spread.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setSpread(nil) end)
  print("ParticleSystem:setSpread ->", ok, result)
end

--@api-stub: ParticleSystem:getSpread
-- Returns the half-angle spread in radians for the emission cone.
-- Call when you need to read spread.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getSpread() end)
  print("ParticleSystem:getSpread ->", ok, result)
end

--@api-stub: ParticleSystem:getLinearAcceleration
-- Returns linear acceleration range.
-- Call when you need to read linear acceleration.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getLinearAcceleration() end)
  print("ParticleSystem:getLinearAcceleration ->", ok, result)
end

--@api-stub: ParticleSystem:getRadialAcceleration
-- Returns radial acceleration range.
-- Call when you need to read radial acceleration.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getRadialAcceleration() end)
  print("ParticleSystem:getRadialAcceleration ->", ok, result)
end

--@api-stub: ParticleSystem:getTangentialAcceleration
-- Returns tangential acceleration range.
-- Call when you need to read tangential acceleration.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getTangentialAcceleration() end)
  print("ParticleSystem:getTangentialAcceleration ->", ok, result)
end

--@api-stub: ParticleSystem:setLinearDamping
-- Sets linear damping range.
-- Call when you need to assign linear damping.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setLinearDamping(0, 100) end)
  print("ParticleSystem:setLinearDamping ->", ok, result)
end

--@api-stub: ParticleSystem:getLinearDamping
-- Returns linear damping range.
-- Call when you need to read linear damping.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getLinearDamping() end)
  print("ParticleSystem:getLinearDamping ->", ok, result)
end

--@api-stub: ParticleSystem:setSizes
-- Sets size keyframes (varargs: each number is one keyframe).
-- Call when you need to assign sizes.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setSizes(nil) end)
  print("ParticleSystem:setSizes ->", ok, result)
end

--@api-stub: ParticleSystem:getSizes
-- Returns size keyframes as a Lua table.
-- Call when you need to read sizes.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getSizes() end)
  print("ParticleSystem:getSizes ->", ok, result)
end

--@api-stub: ParticleSystem:setSizeVariation
-- Sets size variation (0â€“1).
-- Call when you need to assign size variation.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setSizeVariation(nil) end)
  print("ParticleSystem:setSizeVariation ->", ok, result)
end

--@api-stub: ParticleSystem:getSizeVariation
-- Returns the maximum random size variation applied to newly emitted particles.
-- Call when you need to read size variation.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getSizeVariation() end)
  print("ParticleSystem:getSizeVariation ->", ok, result)
end

--@api-stub: ParticleSystem:setRotation
-- Sets initial rotation range in radians.
-- Call when you need to assign rotation.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setRotation(0, 100) end)
  print("ParticleSystem:setRotation ->", ok, result)
end

--@api-stub: ParticleSystem:getRotation
-- Returns initial rotation range.
-- Call when you need to read rotation.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getRotation() end)
  print("ParticleSystem:getRotation ->", ok, result)
end

--@api-stub: ParticleSystem:setSpin
-- Sets angular velocity range.
-- Call when you need to assign spin.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setSpin(0, 100) end)
  print("ParticleSystem:setSpin ->", ok, result)
end

--@api-stub: ParticleSystem:getSpin
-- Returns angular velocity range.
-- Call when you need to read spin.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getSpin() end)
  print("ParticleSystem:getSpin ->", ok, result)
end

--@api-stub: ParticleSystem:setSpinVariation
-- Sets spin variation (0â€“1).
-- Call when you need to assign spin variation.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setSpinVariation(nil) end)
  print("ParticleSystem:setSpinVariation ->", ok, result)
end

--@api-stub: ParticleSystem:getSpinVariation
-- Returns the maximum random angular velocity variation for new particles.
-- Call when you need to read spin variation.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getSpinVariation() end)
  print("ParticleSystem:getSpinVariation ->", ok, result)
end

--@api-stub: ParticleSystem:setRelativeRotation
-- Sets whether particle rotation follows velocity direction.
-- Call when you need to assign relative rotation.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setRelativeRotation(nil) end)
  print("ParticleSystem:setRelativeRotation ->", ok, result)
end

--@api-stub: ParticleSystem:hasRelativeRotation
-- Returns whether relative rotation is enabled.
-- Call when you need to check has relative rotation.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:hasRelativeRotation() end)
  print("ParticleSystem:hasRelativeRotation ->", ok, result)
end

--@api-stub: ParticleSystem:setColors
-- Sets color keyframes.
-- Each arg is a table {r, g, b, a}.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setColors({1, 1, 1, 1}) end)
  print("ParticleSystem:setColors ->", ok, result)
end

--@api-stub: ParticleSystem:getColors
-- Returns color keyframes as a table of {r,g,b,a} tables.
-- Call when you need to read colors.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getColors() end)
  print("ParticleSystem:getColors ->", ok, result)
end

--@api-stub: ParticleSystem:setOffset
-- Sets the render origin offset.
-- Call when you need to assign offset.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setOffset(nil, nil) end)
  print("ParticleSystem:setOffset ->", ok, result)
end

--@api-stub: ParticleSystem:getOffset
-- Returns the render origin offset.
-- Call when you need to read offset.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getOffset() end)
  print("ParticleSystem:getOffset ->", ok, result)
end

--@api-stub: ParticleSystem:setInsertMode
-- Sets the insert mode: "top", "bottom", or "random".
-- Call when you need to assign insert mode.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setInsertMode(nil) end)
  print("ParticleSystem:setInsertMode ->", ok, result)
end

--@api-stub: ParticleSystem:getInsertMode
-- Returns the insert mode as a string.
-- Call when you need to read insert mode.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getInsertMode() end)
  print("ParticleSystem:getInsertMode ->", ok, result)
end

--@api-stub: ParticleSystem:setBufferSize
-- Sets the maximum number of particles (resizes the pool).
-- Call when you need to assign buffer size.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setBufferSize(10) end)
  print("ParticleSystem:setBufferSize ->", ok, result)
end

--@api-stub: ParticleSystem:getBufferSize
-- Returns the maximum particle count.
-- Call when you need to read buffer size.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getBufferSize() end)
  print("ParticleSystem:getBufferSize ->", ok, result)
end

--@api-stub: ParticleSystem:setEmissionArea
-- Sets emission area distribution and size.
-- Call when you need to assign emission area.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setEmissionArea(nil, 100, 100, 0, "dir_rel") end)
  print("ParticleSystem:setEmissionArea ->", ok, result)
end

--@api-stub: ParticleSystem:getEmissionArea
-- Returns emission area: dist-string, w, h.
-- Call when you need to read emission area.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getEmissionArea() end)
  print("ParticleSystem:getEmissionArea ->", ok, result)
end

--@api-stub: ParticleSystem:setShape
-- Sets the particle draw shape.
-- Call when you need to assign shape.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setShape(nil) end)
  print("ParticleSystem:setShape ->", ok, result)
end

--@api-stub: ParticleSystem:getShape
-- Returns the particle draw shape as a string.
-- Call when you need to read shape.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getShape() end)
  print("ParticleSystem:getShape ->", ok, result)
end

--@api-stub: ParticleSystem:getGravity
-- Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
-- Call when you need to read gravity.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getGravity() end)
  print("ParticleSystem:getGravity ->", ok, result)
end

--@api-stub: ParticleSystem:setGravity
-- Sets the gravity acceleration applied to all active particles each frame.
-- Call when you need to assign gravity.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:setGravity(nil, nil) end)
  print("ParticleSystem:setGravity ->", ok, result)
end

--@api-stub: ParticleSystem:render
-- Renders all live particles to the GPU command queue.
-- Call when you need to invoke render.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:render(nil, nil) end)
  print("ParticleSystem:render ->", ok, result)
end

--@api-stub: ParticleSystem:clone
-- Creates a copy of this particle system (config only, no live particles).
-- Call when you need to invoke clone.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:clone() end)
  print("ParticleSystem:clone ->", ok, result)
end

--@api-stub: ParticleSystem:drawToImage
-- Renders all live particles to a CPU ImageData.
-- Call when you need to render to image.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage(100, 100) end)
  print("ParticleSystem:drawToImage ->", ok, result)
end

--@api-stub: ParticleSystem:toImage
-- Alias for `drawToImage`.
-- Renders all live particles to a CPU ImageData.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:toImage(100, 100) end)
  print("ParticleSystem:toImage ->", ok, result)
end

--@api-stub: ParticleSystem:warmUp
-- Pre-simulates the particle system for `seconds` so it appears fully.
-- Call when you need to invoke warm up.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:warmUp(1.0) end)
  print("ParticleSystem:warmUp ->", ok, result)
end

--@api-stub: ParticleSystem:clearAttractors
-- Removes all attractors from this particle system.
-- Call when you need to invoke clear attractors.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:clearAttractors() end)
  print("ParticleSystem:clearAttractors ->", ok, result)
end

--@api-stub: ParticleSystem:getAttractorCount
-- Returns the number of attractors currently registered on this system.
-- Call when you need to read attractor count.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getAttractorCount() end)
  print("ParticleSystem:getAttractorCount ->", ok, result)
end

--@api-stub: ParticleSystem:clearBounds
-- Removes the bounding rectangle so particles can move freely.
-- Call when you need to invoke clear bounds.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:clearBounds() end)
  print("ParticleSystem:clearBounds ->", ok, result)
end

--@api-stub: ParticleSystem:getFlipbook
-- Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
-- Call when you need to read flipbook.
-- Build a ParticleSystem via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newParticleSystem(...)
if instance then
  local ok, result = pcall(function() return instance:getFlipbook() end)
  print("ParticleSystem:getFlipbook ->", ok, result)
end

-- ── Trail methods ──

--@api-stub: Trail:pushPoint
-- Appends a new point to the trail head.
-- Call when you need to invoke push point.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:pushPoint(0, 0) end)
  print("Trail:pushPoint ->", ok, result)
end

--@api-stub: Trail:update
-- Ages trail points and removes expired ones.
-- Call when you need to invoke update.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Trail:update ->", ok, result)
end

--@api-stub: Trail:setWidth
-- Sets the start and end width of the trail ribbon.
-- Call when you need to assign width.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:setWidth(nil, nil) end)
  print("Trail:setWidth ->", ok, result)
end

--@api-stub: Trail:getWidth
-- Returns the start and end width.
-- Call when you need to read width.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("Trail:getWidth ->", ok, result)
end

--@api-stub: Trail:setLifetime
-- Sets how long each trail point persists in seconds.
-- Call when you need to assign lifetime.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:setLifetime(nil) end)
  print("Trail:setLifetime ->", ok, result)
end

--@api-stub: Trail:getLifetime
-- Returns the trail point lifetime in seconds.
-- Call when you need to read lifetime.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:getLifetime() end)
  print("Trail:getLifetime ->", ok, result)
end

--@api-stub: Trail:setMinDistance
-- Sets the minimum distance between trail points.
-- Call when you need to assign min distance.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:setMinDistance(nil) end)
  print("Trail:setMinDistance ->", ok, result)
end

--@api-stub: Trail:getPointCount
-- Returns the number of active trail points.
-- Call when you need to read point count.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:getPointCount() end)
  print("Trail:getPointCount ->", ok, result)
end

--@api-stub: Trail:clear
-- Removes all trail points.
-- Call when you need to invoke clear.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Trail:clear ->", ok, result)
end

--@api-stub: Trail:drawToImage
-- Renders the trail ribbon to a CPU ImageData.
-- Call when you need to render to image.
-- Build a Trail via the appropriate lurek.particle.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.particle.newTrail(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage(100, 100) end)
  print("Trail:drawToImage ->", ok, result)
end

