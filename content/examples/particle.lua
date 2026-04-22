-- content/examples/particle.lua
-- Scaffolded coverage of the lurek.particle API (84 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/particle_api.rs   (Lua binding, arg types, return shape)
--   * src/particle/                 (semantics, side effects)
--   * docs/specs/particle.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/particle.lua

-- ── lurek.particle.* functions ──

--@api-stub: lurek.particle.newSystem
-- Creates a new particle system and stores it in the engine pool.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: lurek.particle.newSystem
  local _todo = "TODO: write a real lurek.particle.newSystem usage example"
  print(_todo)
end

--@api-stub: lurek.particle.newTrail
-- Creates a new trail ribbon effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: lurek.particle.newTrail
  local _todo = "TODO: write a real lurek.particle.newTrail usage example"
  print(_todo)
end

-- ── ParticleSystem methods ──

--@api-stub: ParticleSystem:update
-- Advances the particle simulation by dt seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:update
  local _todo = "TODO: write a real ParticleSystem:update usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:emit
-- Emits a burst of the given number of particles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:emit
  local _todo = "TODO: write a real ParticleSystem:emit usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:start
-- Starts or restarts particle emission.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:start
  local _todo = "TODO: write a real ParticleSystem:start usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:stop
-- Stops particle emission immediately.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:stop
  local _todo = "TODO: write a real ParticleSystem:stop usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:pause
-- Pauses particle emission; existing particles continue to simulate.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:pause
  local _todo = "TODO: write a real ParticleSystem:pause usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:resume
-- Resumes a paused emitter.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:resume
  local _todo = "TODO: write a real ParticleSystem:resume usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:reset
-- Removes all particles and resets the emitter.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:reset
  local _todo = "TODO: write a real ParticleSystem:reset usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:moveTo
-- Moves the emitter to the given world position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:moveTo
  local _todo = "TODO: write a real ParticleSystem:moveTo usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:count
-- Returns the number of living particles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:count
  local _todo = "TODO: write a real ParticleSystem:count usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:isActive
-- Returns true if the emitter is currently emitting or has live particles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:isActive
  local _todo = "TODO: write a real ParticleSystem:isActive usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:isPaused
-- Returns true if the emitter is paused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:isPaused
  local _todo = "TODO: write a real ParticleSystem:isPaused usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:isStopped
-- Returns true if the emitter is stopped.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:isStopped
  local _todo = "TODO: write a real ParticleSystem:isStopped usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:isEmpty
-- Returns true if there are no live particles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:isEmpty
  local _todo = "TODO: write a real ParticleSystem:isEmpty usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:isFull
-- Returns true if the system has reached max_particles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:isFull
  local _todo = "TODO: write a real ParticleSystem:isFull usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:release
-- Removes the particle system from the engine, freeing its slot.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:release
  local _todo = "TODO: write a real ParticleSystem:release usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getCount
-- Returns the number of living particles (alias for count).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getCount
  local _todo = "TODO: write a real ParticleSystem:getCount usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:type
-- Returns the type name "ParticleSystem".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:type
  local _todo = "TODO: write a real ParticleSystem:type usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:typeOf
-- Returns true if this matches the given type name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:typeOf
  local _todo = "TODO: write a real ParticleSystem:typeOf usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setPosition
-- Sets the emitter world position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setPosition
  local _todo = "TODO: write a real ParticleSystem:setPosition usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getPosition
-- Returns the emitter world position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getPosition
  local _todo = "TODO: write a real ParticleSystem:getPosition usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setEmissionRate
-- Sets particles emitted per second.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setEmissionRate
  local _todo = "TODO: write a real ParticleSystem:setEmissionRate usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getEmissionRate
-- Returns particles emitted per second.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getEmissionRate
  local _todo = "TODO: write a real ParticleSystem:getEmissionRate usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setParticleLifetime
-- Sets min and max particle lifetime in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setParticleLifetime
  local _todo = "TODO: write a real ParticleSystem:setParticleLifetime usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getParticleLifetime
-- Returns min and max particle lifetime.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getParticleLifetime
  local _todo = "TODO: write a real ParticleSystem:getParticleLifetime usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setEmitterLifetime
-- Sets how long the emitter runs before auto-stopping.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setEmitterLifetime
  local _todo = "TODO: write a real ParticleSystem:setEmitterLifetime usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getEmitterLifetime
-- Returns the emitter lifetime.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getEmitterLifetime
  local _todo = "TODO: write a real ParticleSystem:getEmitterLifetime usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setSpeed
-- Sets min/max initial speed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setSpeed
  local _todo = "TODO: write a real ParticleSystem:setSpeed usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getSpeed
-- Returns min/max initial speed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getSpeed
  local _todo = "TODO: write a real ParticleSystem:getSpeed usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setDirection
-- Sets emission direction in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setDirection
  local _todo = "TODO: write a real ParticleSystem:setDirection usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getDirection
-- Returns emission direction in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getDirection
  local _todo = "TODO: write a real ParticleSystem:getDirection usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setSpread
-- Sets emission spread (half-angle cone) in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setSpread
  local _todo = "TODO: write a real ParticleSystem:setSpread usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getSpread
-- Returns the half-angle spread in radians for the emission cone.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getSpread
  local _todo = "TODO: write a real ParticleSystem:getSpread usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getLinearAcceleration
-- Returns linear acceleration range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getLinearAcceleration
  local _todo = "TODO: write a real ParticleSystem:getLinearAcceleration usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getRadialAcceleration
-- Returns radial acceleration range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getRadialAcceleration
  local _todo = "TODO: write a real ParticleSystem:getRadialAcceleration usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getTangentialAcceleration
-- Returns tangential acceleration range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getTangentialAcceleration
  local _todo = "TODO: write a real ParticleSystem:getTangentialAcceleration usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setLinearDamping
-- Sets linear damping range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setLinearDamping
  local _todo = "TODO: write a real ParticleSystem:setLinearDamping usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getLinearDamping
-- Returns linear damping range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getLinearDamping
  local _todo = "TODO: write a real ParticleSystem:getLinearDamping usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setSizes
-- Sets size keyframes (varargs: each number is one keyframe).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setSizes
  local _todo = "TODO: write a real ParticleSystem:setSizes usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getSizes
-- Returns size keyframes as a Lua table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getSizes
  local _todo = "TODO: write a real ParticleSystem:getSizes usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setSizeVariation
-- Sets size variation (0â€“1).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setSizeVariation
  local _todo = "TODO: write a real ParticleSystem:setSizeVariation usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getSizeVariation
-- Returns the maximum random size variation applied to newly emitted particles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getSizeVariation
  local _todo = "TODO: write a real ParticleSystem:getSizeVariation usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setRotation
-- Sets initial rotation range in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setRotation
  local _todo = "TODO: write a real ParticleSystem:setRotation usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getRotation
-- Returns initial rotation range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getRotation
  local _todo = "TODO: write a real ParticleSystem:getRotation usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setSpin
-- Sets angular velocity range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setSpin
  local _todo = "TODO: write a real ParticleSystem:setSpin usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getSpin
-- Returns angular velocity range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getSpin
  local _todo = "TODO: write a real ParticleSystem:getSpin usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setSpinVariation
-- Sets spin variation (0â€“1).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setSpinVariation
  local _todo = "TODO: write a real ParticleSystem:setSpinVariation usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getSpinVariation
-- Returns the maximum random angular velocity variation for new particles.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getSpinVariation
  local _todo = "TODO: write a real ParticleSystem:getSpinVariation usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setRelativeRotation
-- Sets whether particle rotation follows velocity direction.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setRelativeRotation
  local _todo = "TODO: write a real ParticleSystem:setRelativeRotation usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:hasRelativeRotation
-- Returns whether relative rotation is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:hasRelativeRotation
  local _todo = "TODO: write a real ParticleSystem:hasRelativeRotation usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setColors
-- Sets color keyframes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setColors
  local _todo = "TODO: write a real ParticleSystem:setColors usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getColors
-- Returns color keyframes as a table of {r,g,b,a} tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getColors
  local _todo = "TODO: write a real ParticleSystem:getColors usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setOffset
-- Sets the render origin offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setOffset
  local _todo = "TODO: write a real ParticleSystem:setOffset usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getOffset
-- Returns the render origin offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getOffset
  local _todo = "TODO: write a real ParticleSystem:getOffset usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setInsertMode
-- Sets the insert mode: "top", "bottom", or "random".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setInsertMode
  local _todo = "TODO: write a real ParticleSystem:setInsertMode usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getInsertMode
-- Returns the insert mode as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getInsertMode
  local _todo = "TODO: write a real ParticleSystem:getInsertMode usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setBufferSize
-- Sets the maximum number of particles (resizes the pool).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setBufferSize
  local _todo = "TODO: write a real ParticleSystem:setBufferSize usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getBufferSize
-- Returns the maximum particle count.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getBufferSize
  local _todo = "TODO: write a real ParticleSystem:getBufferSize usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setEmissionArea
-- Sets emission area distribution and size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setEmissionArea
  local _todo = "TODO: write a real ParticleSystem:setEmissionArea usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getEmissionArea
-- Returns emission area: dist-string, w, h.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getEmissionArea
  local _todo = "TODO: write a real ParticleSystem:getEmissionArea usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setShape
-- Sets the particle draw shape.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setShape
  local _todo = "TODO: write a real ParticleSystem:setShape usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getShape
-- Returns the particle draw shape as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getShape
  local _todo = "TODO: write a real ParticleSystem:getShape usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getGravity
-- Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getGravity
  local _todo = "TODO: write a real ParticleSystem:getGravity usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:setGravity
-- Sets the gravity acceleration applied to all active particles each frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:setGravity
  local _todo = "TODO: write a real ParticleSystem:setGravity usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:render
-- Renders all live particles to the GPU command queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:render
  local _todo = "TODO: write a real ParticleSystem:render usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:clone
-- Creates a copy of this particle system (config only, no live particles).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:clone
  local _todo = "TODO: write a real ParticleSystem:clone usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:drawToImage
-- Renders all live particles to a CPU ImageData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:drawToImage
  local _todo = "TODO: write a real ParticleSystem:drawToImage usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:toImage
-- Alias for `drawToImage`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:toImage
  local _todo = "TODO: write a real ParticleSystem:toImage usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:warmUp
-- Pre-simulates the particle system for `seconds` so it appears fully.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:warmUp
  local _todo = "TODO: write a real ParticleSystem:warmUp usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:clearAttractors
-- Removes all attractors from this particle system.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:clearAttractors
  local _todo = "TODO: write a real ParticleSystem:clearAttractors usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getAttractorCount
-- Returns the number of attractors currently registered on this system.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getAttractorCount
  local _todo = "TODO: write a real ParticleSystem:getAttractorCount usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:clearBounds
-- Removes the bounding rectangle so particles can move freely.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:clearBounds
  local _todo = "TODO: write a real ParticleSystem:clearBounds usage example"
  print(_todo)
end

--@api-stub: ParticleSystem:getFlipbook
-- Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: ParticleSystem:getFlipbook
  local _todo = "TODO: write a real ParticleSystem:getFlipbook usage example"
  print(_todo)
end

-- ── Trail methods ──

--@api-stub: Trail:pushPoint
-- Appends a new point to the trail head.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:pushPoint
  local _todo = "TODO: write a real Trail:pushPoint usage example"
  print(_todo)
end

--@api-stub: Trail:update
-- Ages trail points and removes expired ones.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:update
  local _todo = "TODO: write a real Trail:update usage example"
  print(_todo)
end

--@api-stub: Trail:setWidth
-- Sets the start and end width of the trail ribbon.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:setWidth
  local _todo = "TODO: write a real Trail:setWidth usage example"
  print(_todo)
end

--@api-stub: Trail:getWidth
-- Returns the start and end width.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:getWidth
  local _todo = "TODO: write a real Trail:getWidth usage example"
  print(_todo)
end

--@api-stub: Trail:setLifetime
-- Sets how long each trail point persists in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:setLifetime
  local _todo = "TODO: write a real Trail:setLifetime usage example"
  print(_todo)
end

--@api-stub: Trail:getLifetime
-- Returns the trail point lifetime in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:getLifetime
  local _todo = "TODO: write a real Trail:getLifetime usage example"
  print(_todo)
end

--@api-stub: Trail:setMinDistance
-- Sets the minimum distance between trail points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:setMinDistance
  local _todo = "TODO: write a real Trail:setMinDistance usage example"
  print(_todo)
end

--@api-stub: Trail:getPointCount
-- Returns the number of active trail points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:getPointCount
  local _todo = "TODO: write a real Trail:getPointCount usage example"
  print(_todo)
end

--@api-stub: Trail:clear
-- Removes all trail points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:clear
  local _todo = "TODO: write a real Trail:clear usage example"
  print(_todo)
end

--@api-stub: Trail:drawToImage
-- Renders the trail ribbon to a CPU ImageData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/particle_api.rs and docs/specs/particle.md).
do  -- TODO: Trail:drawToImage
  local _todo = "TODO: write a real Trail:drawToImage usage example"
  print(_todo)
end

