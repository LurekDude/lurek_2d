-- content/examples/particle.lua
-- Hand-written coverage of the lurek.particle API (84 items).
--
-- Particle systems are emitter-based pools rendered each frame; trails are
-- ribbon strips with per-point lifetime. Build the system in lurek.init,
-- step it in lurek.process(dt), and draw it in lurek.render(). All position
-- units are pixels, angles are radians, and times are seconds.
--
-- Run: cargo run -- content/examples/particle.lua

-- â”€â”€ lurek.particle.* functions â”€â”€


--@api-stub: lurek.particle.newSystem
-- Creates a new particle system and stores it in the engine pool.
-- Pass a config table at creation so emission rate, lifetime, and shape are baked in before start().
do -- lurek.particle.newSystem
  local fire = lurek.particle.newSystem({
    maxParticles = 256, emissionRate = 60,
    lifetimeMin = 0.4, lifetimeMax = 0.9,
    speedMin = 40, speedMax = 80, direction = -math.pi/2, spread = 0.3,
  })
  fire:setPosition(320, 240)
  fire:start()
end

--@api-stub: lurek.particle.newPreset
-- Creates a new particle system from a built-in preset.
do -- lurek.particle.newPreset
  local smoke = lurek.particle.newPreset("smoke")
  smoke:setPosition(300, 260)
  smoke:start()
end

--@api-stub: LParticleSystem:setCollidesWithPhysics
-- Enables particle collision response against a physics world.
do -- ParticleSystem:setCollidesWithPhysics
  local world = lurek.physics.newWorld(0, 9.81)
  local rain = lurek.particle.newPreset("rain")
  rain:setCollidesWithPhysics(world, 1.0, 0.4)
  if rain:hasCollidesWithPhysics() then
    rain:clearCollidesWithPhysics()
  end
end

--@api-stub: LParticleSystem:hasCollidesWithPhysics
-- Returns true if particle-vs-physics collision response is enabled.
do -- ParticleSystem:hasCollidesWithPhysics
  local world = lurek.physics.newWorld(0, 9.81)
  local ps = lurek.particle.newSystem({ maxParticles = 64 })
  ps:setCollidesWithPhysics(world)
  local enabled = ps:hasCollidesWithPhysics()
  lurek.log.debug("physics collision enabled=" .. tostring(enabled), "particle")
end

--@api-stub: LParticleSystem:clearCollidesWithPhysics
-- Disables particle-vs-physics collision response.
do -- ParticleSystem:clearCollidesWithPhysics
  local world = lurek.physics.newWorld(0, 9.81)
  local ps = lurek.particle.newSystem({ maxParticles = 64 })
  ps:setCollidesWithPhysics(world)
  ps:clearCollidesWithPhysics()
end

--@api-stub: lurek.particle.newTrail
-- Creates a new trail ribbon effect.
-- Create one trail per moving entity at startup; pass (lifetime_seconds, start_width_pixels).
do -- lurek.particle.newTrail
  local sword_trail = lurek.particle.newTrail(0.35, 12.0)
  sword_trail:setHeadColor(1.0, 0.95, 0.6, 1.0)
  sword_trail:setTailColor(1.0, 0.4, 0.0, 0.0)
  sword_trail:pushPoint(100, 200)
end

-- â”€â”€ ParticleSystem methods â”€â”€

--@api-stub: LParticleSystem:update
-- Advances the particle simulation by dt seconds.
-- Call inside lurek.process(dt); skip when the system isStopped to save the borrow.
do -- ParticleSystem:update
  local sys = lurek.particle.newSystem({ maxParticles = 128, emissionRate = 30 })
  sys:start()
  function lurek.process(dt)
    sys:update(dt)
  end
end

--@api-stub: LParticleSystem:emit
-- Emits a burst of the given number of particles.
-- Use for one-shot bursts (explosions, hit sparks); does not require start() to be running.
do -- ParticleSystem:emit
  local hit = lurek.particle.newSystem({ maxParticles = 64, lifetimeMin = 0.2, lifetimeMax = 0.4 })
  hit:setPosition(160, 120)
  hit:emit(24)
end

--@api-stub: LParticleSystem:start
-- Starts or restarts particle emission.
-- Begins continuous emission at emissionRate; idempotent if already running.
do -- ParticleSystem:start
  local rain = lurek.particle.newSystem({ maxParticles = 512, emissionRate = 200 })
  rain:setPosition(400, 0)
  rain:setEmissionArea("uniform", 800, 1)
  rain:start()
end

--@api-stub: LParticleSystem:stop
-- Stops particle emission immediately.
-- Stops new emission immediately; live particles continue until their lifetime expires.
do -- ParticleSystem:stop
  local jet = lurek.particle.newSystem({ emissionRate = 100 })
  jet:start()
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("space") then jet:stop() end
  end
end

--@api-stub: LParticleSystem:pause
-- Pauses particle emission; existing particles continue to simulate.
-- Freezes both emission and simulation; useful when a menu opens mid-game.
do -- ParticleSystem:pause
  local steam = lurek.particle.newSystem({ emissionRate = 40 })
  steam:start()
  if lurek.input.keyboard.isDown("escape") then steam:pause() end
end

--@api-stub: LParticleSystem:resume
-- Resumes a paused emitter.
-- Restarts a paused system from where it left off; no-op if it was never paused.
do -- ParticleSystem:resume
  local fog = lurek.particle.newSystem({ emissionRate = 20 })
  fog:start()
  fog:pause()
  fog:resume()
end

--@api-stub: LParticleSystem:reset
-- Removes all particles and resets the emitter.
-- Drops every live particle and rewinds the emitter; use on level reload.
do -- ParticleSystem:reset
  local sparks = lurek.particle.newSystem({ maxParticles = 128, emissionRate = 80 })
  sparks:start()
  sparks:emit(60)
  sparks:reset()
end

--@api-stub: LParticleSystem:moveTo
-- Moves the emitter to the given world position.
-- Snap the emitter to a new world position; track an entity by calling each frame.
do -- ParticleSystem:moveTo
  local exhaust = lurek.particle.newSystem({ emissionRate = 50, lifetimeMin = 0.3, lifetimeMax = 0.6 })
  exhaust:start()
  local ship = { x = 200, y = 300 }
  function lurek.process(dt)
    exhaust:moveTo(ship.x, ship.y + 16)
    exhaust:update(dt)
  end
end

--@api-stub: LParticleSystem:count
-- Returns the number of living particles.
-- Branch on this to spawn extra effects only when the pool has headroom.
do -- ParticleSystem:count
  local smoke = lurek.particle.newSystem({ maxParticles = 200 })
  smoke:start()
  if smoke:count() < 50 then smoke:emit(10) end
end

--@api-stub: LParticleSystem:isActive
-- Returns true if the emitter is currently emitting or has live particles.
-- True while emitting OR while particles remain alive; use to delay scene cleanup.
do -- ParticleSystem:isActive
  local explosion = lurek.particle.newSystem({ emitterLifetime = 0.1 })
  explosion:emit(80)
  if explosion:isActive() then
    lurek.log.debug("explosion still has live particles", "fx")
  end
end

--@api-stub: LParticleSystem:isPaused
-- Returns true if the emitter is paused.
-- Use to display a paused-overlay icon over the emitter without polling state externally.
do -- ParticleSystem:isPaused
  local fountain = lurek.particle.newSystem({ emissionRate = 30 })
  fountain:start()
  fountain:pause()
  if fountain:isPaused() then lurek.log.info("fountain frozen", "fx") end
end

--@api-stub: LParticleSystem:isStopped
-- Returns true if the emitter is stopped.
-- Returns true after stop() and before start(); also true for a never-started new system.
do -- ParticleSystem:isStopped
  local burst = lurek.particle.newSystem({})
  if burst:isStopped() then burst:start() end
end

--@api-stub: LParticleSystem:isEmpty
-- Returns true if there are no live particles.
-- True when no particles are alive; pair with isStopped to know it is safe to release.
do -- ParticleSystem:isEmpty
  local trail_fx = lurek.particle.newSystem({ emissionRate = 0 })
  trail_fx:emit(5)
  if trail_fx:isEmpty() then trail_fx:release() end
end

--@api-stub: LParticleSystem:isFull
-- Returns true if the system has reached max_particles.
-- Buffer is at maxParticles; new emissions overwrite the oldest particle.
do -- ParticleSystem:isFull
  local heavy = lurek.particle.newSystem({ maxParticles = 32, emissionRate = 200 })
  heavy:start()
  function lurek.process(dt)
    heavy:update(dt)
    if heavy:isFull() then heavy:setEmissionRate(50) end
  end
end

--@api-stub: LParticleSystem:release
-- Removes the particle system from the engine, freeing its slot.
-- Frees the engine slot; the userdata becomes a dead handle and further calls error.
do -- ParticleSystem:release
  local oneshot = lurek.particle.newSystem({ maxParticles = 16 })
  oneshot:emit(10)
  oneshot:release()
end

--@api-stub: LParticleSystem:getCount
-- Returns the number of living particles (alias for count).
-- Same value as count(); errors if the system was released, so wrap in a check.
do -- ParticleSystem:getCount
  local plume = lurek.particle.newSystem({ emissionRate = 25 })
  plume:start()
  local n = plume:getCount()
  lurek.log.debug("plume live=" .. n, "fx")
end

--@api-stub: LParticleSystem:type
-- Returns the type name "LParticleSystem".
-- Discriminator string useful when a callback receives a generic Drawable userdata.
do -- ParticleSystem:type
  local sys = lurek.particle.newSystem({})
  if sys:type() == "LParticleSystem" then
    sys:start()
  end
end

--@api-stub: LParticleSystem:typeOf
-- Returns true if this matches the given type name.
-- Accepts "LParticleSystem", "ParticleSystem", "Drawable", or "Object".
do -- ParticleSystem:typeOf
  local sys = lurek.particle.newSystem({})
  if sys:typeOf("Drawable") then
    lurek.log.info("particle system is drawable", "fx")
  end
end

--@api-stub: LParticleSystem:setPosition
-- Sets the emitter world position.
-- Equivalent to moveTo; use whichever reads better in your code.
do -- ParticleSystem:setPosition
  local muzzle = lurek.particle.newSystem({ emissionRate = 0 })
  muzzle:setPosition(220, 180)
  muzzle:emit(12)
end

--@api-stub: LParticleSystem:getPosition
-- Returns the emitter world position.
-- Returns two numbers (x, y); useful for aligning UI tooltips with the emitter.
do -- ParticleSystem:getPosition
  local sys = lurek.particle.newSystem({})
  sys:setPosition(50, 75)
  local x, y = sys:getPosition()
  lurek.log.debug("emitter at " .. x .. "," .. y, "fx")
end

--@api-stub: LParticleSystem:setEmissionRate
-- Sets particles emitted per second.
-- Particles per second; ramp up/down for engine throttle, weather intensity, etc.
do -- ParticleSystem:setEmissionRate
  local rain = lurek.particle.newSystem({ maxParticles = 400 })
  rain:start()
  local intensity = 0.7
  rain:setEmissionRate(150 * intensity)
end

--@api-stub: LParticleSystem:getEmissionRate
-- Returns particles emitted per second.
-- Read it back to drive a debug overlay or validate that a config load took effect.
do -- ParticleSystem:getEmissionRate
  local sys = lurek.particle.newSystem({ emissionRate = 80 })
  if sys:getEmissionRate() > 100 then
    sys:setEmissionRate(100)
  end
end

--@api-stub: LParticleSystem:setParticleLifetime
-- Sets min and max particle lifetime in seconds.
-- Pass min == max for uniform lifetimes; range adds visual variety.
do -- ParticleSystem:setParticleLifetime
  local smoke = lurek.particle.newSystem({})
  smoke:setParticleLifetime(1.5, 3.0)
  smoke:setEmissionRate(20)
  smoke:start()
end

--@api-stub: LParticleSystem:getParticleLifetime
-- Returns min and max particle lifetime.
-- Returns (min, max) seconds; use to pre-allocate trails sized to the longest lifetime.
do -- ParticleSystem:getParticleLifetime
  local sys = lurek.particle.newSystem({ lifetimeMin = 0.5, lifetimeMax = 1.2 })
  local lo, hi = sys:getParticleLifetime()
  lurek.log.debug("lifetime " .. lo .. " to " .. hi, "fx")
end

--@api-stub: LParticleSystem:setEmitterLifetime
-- Sets how long the emitter runs before auto-stopping.
-- Negative = infinite (the default); positive auto-stops the emitter after N seconds.
do -- ParticleSystem:setEmitterLifetime
  local explosion = lurek.particle.newSystem({ emissionRate = 200 })
  explosion:setEmitterLifetime(0.15)
  explosion:start()
end

--@api-stub: LParticleSystem:getEmitterLifetime
-- Returns the emitter lifetime.
-- Read back the configured run-time; -1 indicates infinite emission.
do -- ParticleSystem:getEmitterLifetime
  local sys = lurek.particle.newSystem({ emitterLifetime = 2.0 })
  if sys:getEmitterLifetime() < 0 then
    lurek.log.info("emitter runs forever", "fx")
  end
end

--@api-stub: LParticleSystem:setSpeed
-- Sets min/max initial speed.
-- Initial speed range in pixels per second; combine with setDirection / setSpread.
do -- ParticleSystem:setSpeed
  local geyser = lurek.particle.newSystem({})
  geyser:setSpeed(180, 260)
  geyser:setDirection(-math.pi/2)
  geyser:setSpread(0.15)
  geyser:start()
end

--@api-stub: LParticleSystem:getSpeed
-- Returns min/max initial speed.
-- Returns (min, max); use to tune dependent visuals like trail length.
do -- ParticleSystem:getSpeed
  local sys = lurek.particle.newSystem({ speedMin = 40, speedMax = 90 })
  local lo, hi = sys:getSpeed()
  local trail_len = (hi - lo) * 0.1
  lurek.log.debug("derived trail len " .. trail_len, "fx")
end

--@api-stub: LParticleSystem:setDirection
-- Sets emission direction in radians.
-- Radians; 0 = right, -pi/2 = up, pi/2 = down. Matches math.atan2 conventions.
do -- ParticleSystem:setDirection
  local jet = lurek.particle.newSystem({ emissionRate = 60 })
  jet:setDirection(math.pi)  -- shoot left
  jet:setSpeed(120, 160)
  jet:start()
end

--@api-stub: LParticleSystem:getDirection
-- Returns emission direction in radians.
-- Useful when you want to mirror the direction onto another emitter or a hitbox.
do -- ParticleSystem:getDirection
  local sys = lurek.particle.newSystem({ direction = math.pi/4 })
  local dir = sys:getDirection()
  lurek.log.debug("emit dir rad=" .. dir, "fx")
end

--@api-stub: LParticleSystem:setSpread
-- Sets emission spread (half-angle cone) in radians.
-- Half-angle of the cone (radians); 0 = pencil-tight, math.pi = full circle.
do -- ParticleSystem:setSpread
  local snow = lurek.particle.newSystem({ emissionRate = 80 })
  snow:setDirection(math.pi/2)
  snow:setSpread(0.25)
  snow:start()
end

--@api-stub: LParticleSystem:getSpread
-- Returns the half-angle spread in radians for the emission cone.
-- Read to compute the worst-case bounding cone for occlusion culling.
do -- ParticleSystem:getSpread
  local sys = lurek.particle.newSystem({ spread = 0.4 })
  local cone = sys:getSpread() * 2
  lurek.log.debug("full cone rad=" .. cone, "fx")
end

--@api-stub: LParticleSystem:getLinearAcceleration
-- Returns linear acceleration range.
-- Returns (xmin, ymin, xmax, ymax) per-second^2; gravity-like world forces.
do -- ParticleSystem:getLinearAcceleration
  local sys = lurek.particle.newSystem({})
  local xmn, ymn, xmx, ymx = sys:getLinearAcceleration()
  lurek.log.debug("accel x=[" .. xmn .. "," .. xmx .. "]", "fx")
end

--@api-stub: LParticleSystem:getRadialAcceleration
-- Returns radial acceleration range.
-- Returns (min, max); positive pushes particles outward from the emitter, negative inward.
do -- ParticleSystem:getRadialAcceleration
  local sys = lurek.particle.newSystem({ radialAccelMin = -50, radialAccelMax = -20 })
  local lo, hi = sys:getRadialAcceleration()
  if hi < 0 then lurek.log.info("particles implode", "fx") end
end

--@api-stub: LParticleSystem:getTangentialAcceleration
-- Returns tangential acceleration range.
-- Returns (min, max); positive makes particles spiral counter-clockwise around the emitter.
do -- ParticleSystem:getTangentialAcceleration
  local sys = lurek.particle.newSystem({ tangentialAccelMin = 30, tangentialAccelMax = 60 })
  local lo, hi = sys:getTangentialAcceleration()
  lurek.log.debug("swirl " .. lo .. ".." .. hi, "fx")
end

--@api-stub: LParticleSystem:setLinearDamping
-- Sets linear damping range.
-- Per-second drag coefficient range; 0 = no damping, 5 = particles slow rapidly.
do -- ParticleSystem:setLinearDamping
  local dust = lurek.particle.newSystem({ emissionRate = 40 })
  dust:setLinearDamping(1.5, 2.5)
  dust:setSpeed(60, 100)
  dust:start()
end

--@api-stub: LParticleSystem:getLinearDamping
-- Returns linear damping range.
-- Read to display tooltips or to clamp damping when stacking with other forces.
do -- ParticleSystem:getLinearDamping
  local sys = lurek.particle.newSystem({ linearDampingMin = 1.0, linearDampingMax = 2.0 })
  local lo, hi = sys:getLinearDamping()
  lurek.log.debug("damping " .. lo .. ".." .. hi, "fx")
end

--@api-stub: LParticleSystem:setSizes
-- Sets size keyframes (varargs: each number is one keyframe).
-- Varargs of size keyframes interpolated over particle life; first = birth, last = death.
do -- ParticleSystem:setSizes
  local puff = lurek.particle.newSystem({ emissionRate = 30 })
  puff:setSizes(2, 8, 16, 4)
  puff:setShape("circle")
  puff:start()
end

--@api-stub: LParticleSystem:getSizes
-- Returns size keyframes as a Lua table.
-- Returns a 1-indexed table; iterate with ipairs to render keyframe markers in a tool.
do -- ParticleSystem:getSizes
  local sys = lurek.particle.newSystem({})
  sys:setSizes(4, 12, 6)
  local sizes = sys:getSizes()
  lurek.log.debug("size keyframes=" .. #sizes, "fx")
end

--@api-stub: LParticleSystem:setSizeVariation
-- Sets size variation (0Ă˘â‚¬â€ś1).
-- 0 = identical sizes, 1 = full random scaling per particle around the keyframe value.
do -- ParticleSystem:setSizeVariation
  local sparks = lurek.particle.newSystem({ emissionRate = 50 })
  sparks:setSizes(3, 1)
  sparks:setSizeVariation(0.4)
  sparks:start()
end

--@api-stub: LParticleSystem:getSizeVariation
-- Returns the maximum random size variation applied to newly emitted particles.
-- Read it back when serialising emitter presets to JSON or TOML.
do -- ParticleSystem:getSizeVariation
  local sys = lurek.particle.newSystem({ sizeVariation = 0.6 })
  local v = sys:getSizeVariation()
  lurek.log.debug("size variation=" .. v, "fx")
end

--@api-stub: LParticleSystem:setRotation
-- Sets initial rotation range in radians.
-- Initial rotation range in radians; randomised at emission, then evolved by spin.
do -- ParticleSystem:setRotation
  local leaves = lurek.particle.newSystem({ emissionRate = 20 })
  leaves:setRotation(0, math.pi * 2)
  leaves:setSpin(-1.0, 1.0)
  leaves:start()
end

--@api-stub: LParticleSystem:getRotation
-- Returns initial rotation range.
-- Returns (min, max) radians; useful when copying configuration to a clone.
do -- ParticleSystem:getRotation
  local sys = lurek.particle.newSystem({ rotationMin = 0, rotationMax = math.pi })
  local lo, hi = sys:getRotation()
  lurek.log.debug("rot " .. lo .. ".." .. hi, "fx")
end

--@api-stub: LParticleSystem:setSpin
-- Sets angular velocity range.
-- Angular velocity range in radians/second applied for the particle lifetime.
do -- ParticleSystem:setSpin
  local coins = lurek.particle.newSystem({ emissionRate = 10 })
  coins:setSpin(2.0, 4.0)
  coins:setSpeed(80, 120)
  coins:start()
end

--@api-stub: LParticleSystem:getSpin
-- Returns angular velocity range.
-- Returns (min, max) radians/second; report on a debug HUD to tune motion feel.
do -- ParticleSystem:getSpin
  local sys = lurek.particle.newSystem({ spinMin = 0.5, spinMax = 1.5 })
  local lo, hi = sys:getSpin()
  lurek.log.debug("spin " .. lo .. ".." .. hi, "fx")
end

--@api-stub: LParticleSystem:setSpinVariation
-- Sets spin variation (0Ă˘â‚¬â€ś1).
-- 0 = uniform spin, 1 = full random per particle around the configured range.
do -- ParticleSystem:setSpinVariation
  local debris = lurek.particle.newSystem({ emissionRate = 60 })
  debris:setSpin(1.0, 2.0)
  debris:setSpinVariation(0.5)
  debris:start()
end

--@api-stub: LParticleSystem:getSpinVariation
-- Returns the maximum random angular velocity variation for new particles.
-- Read after setting to confirm value persisted (useful in unit tests).
do -- ParticleSystem:getSpinVariation
  local sys = lurek.particle.newSystem({ spinVariation = 0.3 })
  if sys:getSpinVariation() > 0 then
    lurek.log.info("spin will jitter per particle", "fx")
  end
end

--@api-stub: LParticleSystem:setRelativeRotation
-- Sets whether particle rotation follows velocity direction.
-- When true, particles rotate to face their velocity vector â€” ideal for arrows or sparks.
do -- ParticleSystem:setRelativeRotation
  local arrows = lurek.particle.newSystem({ emissionRate = 30 })
  arrows:setShape("ray")
  arrows:setRelativeRotation(true)
  arrows:setSpeed(140, 200)
  arrows:start()
end

--@api-stub: LParticleSystem:hasRelativeRotation
-- Returns whether relative rotation is enabled.
-- Branch on this to choose between billboard and oriented rendering paths.
do -- ParticleSystem:hasRelativeRotation
  local sys = lurek.particle.newSystem({})
  sys:setRelativeRotation(true)
  if sys:hasRelativeRotation() then
    lurek.log.info("particles align to motion", "fx")
  end
end

--@api-stub: LParticleSystem:setColors
-- Sets color keyframes.
-- Each arg is a {r,g,b,a} table interpolated over particle life; 0..1 channel range.
do -- ParticleSystem:setColors
  local fire = lurek.particle.newSystem({ emissionRate = 80 })
  fire:setColors({1, 1, 0.6, 1}, {1, 0.4, 0, 0.8}, {0.2, 0.0, 0.0, 0.0})
  fire:setShape("circle")
  fire:start()
end

--@api-stub: LParticleSystem:getColors
-- Returns color keyframes as a table of {r,g,b,a} tables.
-- Returns a list of {r,g,b,a} tables; iterate to render a colour-ramp swatch.
do -- ParticleSystem:getColors
  local sys = lurek.particle.newSystem({})
  sys:setColors({1, 0, 0, 1}, {0, 0, 1, 1})
  local colors = sys:getColors()
  lurek.log.debug("color stops=" .. #colors, "fx")
end

--@api-stub: LParticleSystem:setOffset
-- Sets the render origin offset.
-- Per-particle render-origin offset in pixels; centre by default but useful for tail sprites.
do -- ParticleSystem:setOffset
  local glow = lurek.particle.newSystem({ emissionRate = 25 })
  glow:setOffset(0, -8)
  glow:setSizes(8, 4)
  glow:start()
end

--@api-stub: LParticleSystem:getOffset
-- Returns the render origin offset.
-- Returns (ox, oy); use when re-applying an asset preset to a cloned system.
do -- ParticleSystem:getOffset
  local sys = lurek.particle.newSystem({ offsetX = 4, offsetY = -2 })
  local ox, oy = sys:getOffset()
  lurek.log.debug("offset " .. ox .. "," .. oy, "fx")
end

--@api-stub: LParticleSystem:setInsertMode
-- Sets the insert mode: "top", "bottom", or "random".
-- "top" (newest in front), "bottom" (newest behind), "random" â€” affects draw ordering only.
do -- ParticleSystem:setInsertMode
  local smoke = lurek.particle.newSystem({ emissionRate = 30 })
  smoke:setInsertMode("bottom")
  smoke:setColors({1, 1, 1, 0.4}, {0.5, 0.5, 0.5, 0})
  smoke:start()
end

--@api-stub: LParticleSystem:getInsertMode
-- Returns the insert mode as a string.
-- One of "top" / "bottom" / "random"; persist across sessions when serialising presets.
do -- ParticleSystem:getInsertMode
  local sys = lurek.particle.newSystem({})
  sys:setInsertMode("random")
  local mode = sys:getInsertMode()
  lurek.log.debug("insert mode=" .. mode, "fx")
end

--@api-stub: LParticleSystem:setBufferSize
-- Sets the maximum number of particles (resizes the pool).
-- Resizes the underlying particle pool; do this once at startup, not per frame.
do -- ParticleSystem:setBufferSize
  local rain = lurek.particle.newSystem({ maxParticles = 64 })
  rain:setBufferSize(1024)
  rain:setEmissionRate(500)
  rain:start()
end

--@api-stub: LParticleSystem:getBufferSize
-- Returns the maximum particle count.
-- Read to size dependent buffers (e.g. trail history) without hard-coding the number.
do -- ParticleSystem:getBufferSize
  local sys = lurek.particle.newSystem({ maxParticles = 256 })
  local cap = sys:getBufferSize()
  lurek.log.debug("pool capacity=" .. cap, "fx")
end

--@api-stub: LParticleSystem:setEmissionArea
-- Sets emission area distribution and size.
-- Distribution + (w, h) in pixels; use "uniform" for rectangles, "ellipse" for soft spawns.
do -- ParticleSystem:setEmissionArea
  local fog = lurek.particle.newSystem({ emissionRate = 40 })
  fog:setEmissionArea("ellipse", 200, 80)
  fog:setColors({0.8, 0.8, 1.0, 0.3}, {0.8, 0.8, 1.0, 0})
  fog:start()
end

--@api-stub: LParticleSystem:getEmissionArea
-- Returns emission area: dist-string, w, h.
-- Returns (dist_string, w, h); use to render a debug rectangle around the emitter.
do -- ParticleSystem:getEmissionArea
  local sys = lurek.particle.newSystem({})
  sys:setEmissionArea("uniform", 120, 40)
  local kind, w, h = sys:getEmissionArea()
  lurek.log.debug("area=" .. kind .. " " .. w .. "x" .. h, "fx")
end

--@api-stub: LParticleSystem:setShape
-- Sets the particle draw shape.
-- One of "square","circle","triangle","spark","diamond","shrapnel","ray","puff","ring","capsule".
do -- ParticleSystem:setShape
  local stars = lurek.particle.newSystem({ emissionRate = 20 })
  stars:setShape("diamond")
  stars:setSizes(6, 2)
  stars:start()
end

--@api-stub: LParticleSystem:getShape
-- Returns the particle draw shape as a string.
-- Returns the shape name; useful when rebuilding a UI selector to reflect current state.
do -- ParticleSystem:getShape
  local sys = lurek.particle.newSystem({})
  sys:setShape("ring")
  if sys:getShape() == "ring" then
    lurek.log.info("ring shape selected", "fx")
  end
end

--@api-stub: LParticleSystem:getGravity
-- Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
-- Returns (gx, gy); useful when synchronising particle gravity with world physics.
do -- ParticleSystem:getGravity
  local rain = lurek.particle.newSystem({ gravityX = 0, gravityY = 400 })
  local gx, gy = rain:getGravity()
  lurek.log.debug("g=" .. gx .. "," .. gy, "fx")
end

--@api-stub: LParticleSystem:setGravity
-- Sets the gravity acceleration applied to all active particles each frame.
-- Pixels per second^2; positive Y is downward in screen space.
do -- ParticleSystem:setGravity
  local debris = lurek.particle.newSystem({ emissionRate = 40 })
  debris:setGravity(0, 600)
  debris:setSpeed(120, 200)
  debris:setSpread(math.pi)
  debris:start()
end

--@api-stub: LParticleSystem:render
-- Renders all live particles to the GPU command queue.
-- Must be called inside lurek.render(); optional (ox, oy) shift the whole system in world space.
do -- ParticleSystem:render
  local fx = lurek.particle.newSystem({ maxParticles = 128, emissionRate = 40 })
  fx:setPosition(200, 200)
  fx:start()
  function lurek.process(dt) fx:update(dt) end
  function lurek.draw() fx:render() end
end

--@api-stub: LParticleSystem:clone
-- Creates a copy of this particle system (config only, no live particles).
-- Copies config only â€” no live particles â€” so you can spawn N synchronised emitters cheaply.
do -- ParticleSystem:clone
  local proto = lurek.particle.newSystem({ emissionRate = 50, lifetimeMin = 0.5, lifetimeMax = 1.0 })
  local copy = proto:clone()
  copy:setPosition(400, 300)
  copy:start()
end

--@api-stub: LParticleSystem:drawToImage
-- Renders all live particles to a CPU ImageData.
-- CPU rasterises live particles into ImageData of (w, h); useful for thumbnails and tests.
do -- ParticleSystem:drawToImage
  local sys = lurek.particle.newSystem({ maxParticles = 32 })
  sys:setPosition(64, 64)
  sys:emit(20)
  local img = sys:drawToImage(128, 128)
  lurek.log.debug("baked thumbnail " .. img:getWidth() .. "x" .. img:getHeight(), "fx")
end

--@api-stub: LParticleSystem:toImage
-- Alias for `drawToImage`.
-- Alias for drawToImage; same arguments and return type.
do -- ParticleSystem:toImage
  local sys = lurek.particle.newSystem({ maxParticles = 16 })
  sys:emit(8)
  local img = sys:toImage(64, 64)
  lurek.log.debug("preview ready " .. img:getWidth() .. "px", "fx")
end

--@api-stub: LParticleSystem:warmUp
-- Pre-simulates the particle system for `seconds` so it appears fully.
-- Pre-simulates `seconds` so the emitter looks established at first render; clamped to 30 s.
do -- ParticleSystem:warmUp
  local fountain = lurek.particle.newSystem({ emissionRate = 60, lifetimeMin = 1.0, lifetimeMax = 2.0 })
  fountain:setSpeed(80, 120)
  fountain:start()
  fountain:warmUp(2.0)
end

--@api-stub: LParticleSystem:clearAttractors
-- Removes all attractors from this particle system.
-- Drops every gravity well; pair with addAttractor when scene context changes.
do -- ParticleSystem:clearAttractors
  local sys = lurek.particle.newSystem({ emissionRate = 30 })
  sys:addAttractor(200, 200, 400, 80)
  sys:clearAttractors()
  sys:start()
end

--@api-stub: LParticleSystem:getAttractorCount
-- Returns the number of attractors currently registered on this system.
-- Branch to skip force application logic when the system has no attractors.
do -- ParticleSystem:getAttractorCount
  local sys = lurek.particle.newSystem({})
  sys:addAttractor(100, 100, 250, 60)
  if sys:getAttractorCount() > 0 then
    lurek.log.info("attractors active", "fx")
  end
end

--@api-stub: LParticleSystem:clearBounds
-- Removes the bounding rectangle so particles can move freely.
-- Removes the bounding box added by setBounds; call when switching rooms.
do -- ParticleSystem:clearBounds
  local sys = lurek.particle.newSystem({ emissionRate = 20 })
  sys:setBounds(0, 800, 0, 600, 0.6)
  sys:clearBounds()
  sys:start()
end

--@api-stub: LParticleSystem:getFlipbook
-- Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
-- Returns (cols, rows, fps) or all nil if no flipbook is configured.
do -- ParticleSystem:getFlipbook
  local sys = lurek.particle.newSystem({})
  sys:setFlipbook(4, 2, 12)
  local cols, rows, fps = sys:getFlipbook()
  if cols then lurek.log.debug("flipbook " .. cols .. "x" .. rows .. " @" .. fps, "fx") end
end

-- â”€â”€ Trail methods â”€â”€

--@api-stub: LTrail:pushPoint
-- Appends a new point to the trail head.
-- Append at the head once per frame; the trail interpolates a ribbon between successive points.
do -- Trail:pushPoint
  local trail = lurek.particle.newTrail(0.4, 8.0)
  function lurek.process(dt)
    local mx, my = lurek.input.getMousePosition()
    trail:pushPoint(mx, my)
    trail:update(dt)
  end
end

--@api-stub: LTrail:update
-- Ages trail points and removes expired ones.
-- Ages every point; call once per frame inside lurek.process(dt) before rendering.
do -- Trail:update
  local trail = lurek.particle.newTrail(0.5, 10.0)
  trail:pushPoint(100, 100)
  function lurek.process(dt)
    trail:update(dt)
  end
end

--@api-stub: LTrail:setWidth
-- Sets the start and end width of the trail ribbon.
-- (start_px, end_px) â€” controls ribbon thickness from head to tail; pass nil end to keep current.
do -- Trail:setWidth
  local trail = lurek.particle.newTrail(0.3, 4.0)
  trail:setWidth(16.0, 2.0)
  trail:pushPoint(50, 50)
end

--@api-stub: LTrail:getWidth
-- Returns the start and end width.
-- Returns (start_px, end_px); use for HUD readouts or to drive a tweening animation.
do -- Trail:getWidth
  local trail = lurek.particle.newTrail(0.3, 12.0)
  trail:setWidth(12.0, 1.0)
  local sw, ew = trail:getWidth()
  lurek.log.debug("trail w=" .. sw .. "->" .. ew, "fx")
end

--@api-stub: LTrail:setLifetime
-- Sets how long each trail point persists in seconds.
-- Seconds each point persists; longer = smoother long-tail ribbons but more vertices.
do -- Trail:setLifetime
  local trail = lurek.particle.newTrail(0.2, 6.0)
  trail:setLifetime(0.8)
  trail:pushPoint(120, 80)
end

--@api-stub: LTrail:getLifetime
-- Returns the trail point lifetime in seconds.
-- Read it to derive a sensible point cap or auto-clear when it changes.
do -- Trail:getLifetime
  local trail = lurek.particle.newTrail(0.5, 8.0)
  local life = trail:getLifetime()
  if life > 1.0 then trail:setLifetime(1.0) end
end

--@api-stub: LTrail:setMinDistance
-- Sets the minimum distance between trail points.
-- Minimum pixel gap between points; raise it to skip duplicates when an entity stalls.
do -- Trail:setMinDistance
  local trail = lurek.particle.newTrail(0.4, 8.0)
  trail:setMinDistance(4.0)
  trail:pushPoint(200, 100)
  trail:pushPoint(201, 100)  -- ignored: too close
end

--@api-stub: LTrail:getPointCount
-- Returns the number of active trail points.
-- Use to pre-size GPU buffers or to skip the render call when the trail is empty.
do -- Trail:getPointCount
  local trail = lurek.particle.newTrail(0.3, 6.0)
  trail:pushPoint(0, 0)
  trail:pushPoint(20, 0)
  if trail:getPointCount() < 2 then return end
  lurek.log.debug("trail points=" .. trail:getPointCount(), "fx")
end

--@api-stub: LTrail:clear
-- Removes all trail points.
-- Removes every point instantly; call on player respawn or scene transition.
do -- Trail:clear
  local trail = lurek.particle.newTrail(0.4, 8.0)
  trail:pushPoint(50, 50)
  trail:pushPoint(60, 60)
  trail:clear()
end

--@api-stub: LTrail:drawToImage
-- Renders the trail ribbon to a CPU ImageData.
-- Bakes the ribbon into ImageData(w, h); useful for capturing screenshots in tests.
do -- Trail:drawToImage
  local trail = lurek.particle.newTrail(0.5, 12.0)
  trail:pushPoint(20, 20)
  trail:pushPoint(80, 60)
  local img = trail:drawToImage(128, 128)
  lurek.log.debug("baked trail img " .. img:getWidth() .. "px", "fx")
end

-- â”€â”€ Phase 03: Lua Extensibility Hooks â”€â”€

--@api-stub: LParticleSystem:addSubSystem
-- Attaches a child emitter that updates and renders alongside the parent.
-- Use to build layered effects: e.g. fire with a smoke sub-emitter running at half the rate.
do -- ParticleSystem:addSubSystem
  local fire = lurek.particle.newSystem({
    maxParticles = 200, emissionRate = 60,
    lifetimeMin = 0.3, lifetimeMax = 0.7,
    speedMin = 40, speedMax = 90,
    direction = -math.pi / 2, spread = 0.4,
  })
  local smoke_idx = fire:addSubSystem({
    maxParticles = 80, emissionRate = 20,
    lifetimeMin = 1.0, lifetimeMax = 2.0,
    speedMin = 10, speedMax = 30,
    direction = -math.pi / 2, spread = 0.6,
  })
  lurek.log.debug("smoke sub-system index: " .. smoke_idx, "fx")
  lurek.log.debug("sub-system count: " .. fire:subSystemCount(), "fx")
  fire:setPosition(400, 300)
  fire:start()
end

--@api-stub: LParticleSystem:subSystemCount
-- Returns the number of direct child sub-systems attached to this emitter.
-- Check before indexing to avoid out-of-range accesses.
do -- ParticleSystem:subSystemCount
  local ps = lurek.particle.newSystem({ maxParticles = 64 })
  ps:addSubSystem({ maxParticles = 16 })
  ps:addSubSystem({ maxParticles = 16 })
  lurek.log.debug("sub count: " .. ps:subSystemCount(), "fx")  -- 2
end

--@api-stub: LParticleSystem:setCustomEmissionShape
-- Registers a Lua callback that returns (offset_x, offset_y) for each new particle.
-- The callback fires once per spawned particle; return pixel offsets relative to the emitter.
do -- ParticleSystem:setCustomEmissionShape
  local ps = lurek.particle.newSystem({
    maxParticles = 128, emissionRate = 30,
    lifetimeMin = 0.8, lifetimeMax = 1.5,
    speedMin = 0, speedMax = 0,
  })
  local angle = 0
  ps:setCustomEmissionShape(function()
    angle = angle + 0.3
    local r = 60 + math.sin(angle * 2) * 20
    return math.cos(angle) * r, math.sin(angle) * r
  end)
  ps:setPosition(400, 300)
  ps:start()
end

--@api-stub: LParticleSystem:setOnDeathBatch
-- Registers a Lua callback fired after each update() with all particles that died that frame.
-- Each entry in the batch table has fields: x, y, vx, vy (world-space position and velocity).
do -- ParticleSystem:setOnDeathBatch
  local ps = lurek.particle.newSystem({
    maxParticles = 64, emissionRate = 10,
    lifetimeMin = 0.5, lifetimeMax = 1.0,
    speedMin = 50, speedMax = 100,
  })
  ps:setOnDeathBatch(function(batch)
    for _, entry in ipairs(batch) do
      -- spawn a sparkle at each death position
      lurek.log.debug(
        string.format("death at (%.1f, %.1f) v=(%.1f, %.1f)", entry.x, entry.y, entry.vx, entry.vy),
        "fx"
      )
    end
  end)
  ps:setPosition(320, 240)
  ps:start()
end

--@api-stub: lurek.particle.fromTOML
-- Load a ParticleSystem configuration from a TOML string or file path.
-- Returns a new ParticleSystem configured from the parsed TOML definition.
do -- lurek.particle.fromTOML
  if lurek.particle.fromTOML then
    local toml_str = 'max_particles = 100\nemission_rate = 30.0\nlifetime_min = 0.5\nlifetime_max = 2.0\nspeed_min = 30.0\nspeed_max = 80.0\ndirection = 0.0\nspread = 1.57\ngravity_y = 0.0\n'
    lurek.filesystem.write("save/particle_test.toml", toml_str)
    local ps = lurek.particle.fromTOML("save/particle_test.toml")
    lurek.log.debug("fromTOML: " .. tostring(ps), "particle")
  end
end

--@api-stub: LParticleSystem:addAttractor
-- Adds a point attractor that pulls or repels particles during their lifetime.
-- Negative strength repels; call multiple times to create complex force fields.
do -- ParticleSystem:addAttractor
  local ps = lurek.particle.newSystem({max_particles=1000})
  ps:addAttractor(400, 300, 80, -50)
  ps:start()
  lurek.log.info("attractor added", "particle")
end

--@api-stub: LParticleSystem:addSubEmitter
-- Attaches a child emitter that spawns when each particle from the parent dies.
-- Use for chain explosions: each fragment spawns a spark sub-emitter on death.
do -- ParticleSystem:addSubEmitter
  local parent = lurek.particle.newSystem({max_particles=200})
  local sparks  = lurek.particle.newSystem({max_particles=50})
  parent:addSubEmitter({trigger="on_death", max_particles=50})
  parent:start()
  lurek.log.info("sub emitter count: " .. parent:subSystemCount(), "particle")
end

--@api-stub: LParticleSystem:setBounds
-- Constrains particle movement to a world-space rectangle; particles bounce or die at edges.
-- Pass bounce=true to reflect velocity; false causes particles to be killed on contact.
do -- ParticleSystem:setBounds
  local ps = lurek.particle.newSystem({max_particles=500})
  ps:setBounds(0, 0, 800, 600, 0.0)
  ps:start()
  lurek.log.info("bounds set", "particle")
end

--@api-stub: LParticleSystem:setFlipbook
-- Sets a flipbook animation sheet so particles cycle through sprite frames over their lifetime.
-- cols*rows must equal or exceed the desired frame count.
do -- ParticleSystem:setFlipbook
  local ps = lurek.particle.newSystem({max_particles=300})
  ps:setFlipbook(4, 4, 16)
  ps:start()
  lurek.log.info("flipbook set", "particle")
end

--@api-stub: LTrail:setHeadColor
-- Sets the RGBA colour at the start (head) of a particle trail.
-- The trail interpolates between head and tail colour along its length.
do -- Trail:setHeadColor
  local trail = lurek.particle.newTrail(2.0, 8.0)
  trail:setHeadColor(1.0, 0.8, 0.0, 1.0)
  trail:setTailColor(1.0, 0.2, 0.0, 0.0)
  lurek.log.info("trail head colour set", "particle")
end

--@api-stub: LParticleSystem:setLinearAcceleration
-- Sets a constant linear (x, y) acceleration applied to all particles each frame.
-- Use for gravity (0, 200) or wind effects with a positive x component.
do -- ParticleSystem:setLinearAcceleration
  local ps = lurek.particle.newSystem({max_particles=500})
  ps:setLinearAcceleration(0, 200, 0, 250)
  ps:start()
  lurek.log.info("linear accel set", "particle")
end

--@api-stub: LParticleSystem:setRadialAcceleration
-- Sets a centripetal/centrifugal acceleration along the particle's radial direction.
-- Positive pushes outward from the emitter origin; negative pulls inward.
do -- ParticleSystem:setRadialAcceleration
  local ps = lurek.particle.newSystem({max_particles=400})
  ps:setRadialAcceleration(50, 100)
  ps:start()
  lurek.log.info("radial accel set", "particle")
end

--@api-stub: LTrail:setTailColor
-- Sets the RGBA colour at the end (tail) of a particle trail.
-- Fade the alpha to 0 for a natural dissipating effect.
do -- Trail:setTailColor
  local trail = lurek.particle.newTrail(2.0, 8.0)
  trail:setHeadColor(0.5, 0.8, 1.0, 1.0)
  trail:setTailColor(0.3, 0.5, 1.0, 0.0)
  lurek.log.info("trail tail colour set", "particle")
end

--@api-stub: LParticleSystem:setTangentialAcceleration
-- Sets a tangential (perpendicular to radius) acceleration that curves particle paths.
-- Positive rotates clockwise; negative rotates anticlockwise for spiral effects.
do -- ParticleSystem:setTangentialAcceleration
  local ps = lurek.particle.newSystem({max_particles=400})
  ps:setTangentialAcceleration(30, 80)
  ps:start()
  lurek.log.info("tangential accel set", "particle")
end

-- =============================================================================
-- COVERAGE: 97 uncovered lurek.particle API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LTrail methods
-- -----------------------------------------------------------------------------

-- ---- Example: LTrail:type ---------------------------------------------------
--@api-stub: LTrail:type
-- Returns the type name of this object.
-- lTrail_Example:type()  -- -> string
-- Useful for runtime type inspection and debug logging.
-- do  -- LTrail:type
--   local trail = lurek.particle.newTrail(0.4, 8.0)
--   local t = trail:type()
--   lurek.log.info("LTrail:type = " .. t, "particle")
-- end
--@api-stub: LTrail:typeOf
-- Returns true if this object is of the given type.
-- lTrail_Example:typeOf("hero")  -- -> boolean
-- Use for runtime polymorphism and defensive checks.
-- do  -- LTrail:typeOf
--   local trail = lurek.particle.newTrail(0.4, 8.0)
--   lurek.log.info("is LTrail: " .. tostring(trail:typeOf("LTrail")), "particle")
--   lurek.log.info("is unknown: " .. tostring(trail:typeOf("Unknown")), "particle")
-- end
