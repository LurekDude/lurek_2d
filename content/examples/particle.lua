-- content/examples/particle.lua
-- lurek.particle API examples.
-- Run: cargo run -- content/examples/particle.lua

--@api-stub: lurek.particle.newSystem
-- Creates a particle system from an optional config table
do
  -- newSystem() is the primary constructor. Pass a config table to set initial
  -- parameters, or call with no args / empty table for defaults.
  -- Config keys: maxParticles, emissionRate, lifetimeMin, lifetimeMax,
  --              speedMin, speedMax, direction, spread, gravityX, gravityY, etc.
  -- Returns an LParticleSystem handle.

  -- Example: campfire effect — particles rise upward with slight horizontal drift
  local fire = lurek.particle.newSystem({
    maxParticles = 256,    -- pool size (pre-allocated, no runtime alloc)
    emissionRate = 60,     -- particles per second when running
    lifetimeMin = 0.4,     -- shortest particle life in seconds
    lifetimeMax = 0.9,     -- longest particle life in seconds
    speedMin = 40,         -- minimum launch speed (pixels/sec)
    speedMax = 80,         -- maximum launch speed (pixels/sec)
    direction = -math.pi/2, -- emit upward (negative Y is up in screen space)
    spread = 0.3,          -- cone half-angle in radians (approx 17 degrees)
  })
  -- Position the emitter at screen center
  fire:setPosition(320, 240)
  -- start() begins continuous emission at the configured rate
  fire:start()
end

--@api-stub: lurek.particle.newPreset
-- Creates a particle system from a named preset
do
  -- Presets are built-in configurations for common effects.
  -- Available presets: "fire", "smoke", "rain", "snow", "sparks"
  -- Each preset returns a fully configured LParticleSystem ready to use.
  -- You can override any property after creation.

  -- Example: add a smoke layer behind a fire for depth
  local smoke = lurek.particle.newPreset("smoke")
  smoke:setPosition(300, 260)
  -- Offset the smoke slightly below the fire origin for visual layering
  smoke:start()
end

--@api-stub: ParticleSystem:setCollidesWithPhysics
-- Sets the collides with physics of this particle system.
do
  -- Enables per-particle collision against a physics world.
  -- Particles will bounce off static and dynamic bodies.
  -- Args: world handle, optional probe_radius (default 1.0), optional restitution (0-1)
  -- Use this for rain splashing on platforms or debris bouncing off walls.

  local world = lurek.physics.newWorld(0, 9.81)
  -- setCollidesWithPhysics links the emitter to a physics world.
  -- Particles bounce off static and dynamic bodies in that world.
  -- Args: world handle, optional probe_radius (default 1.0), optional restitution (0-1).
  -- No body creation needed in this stub; the world reference is enough.
  local rain = lurek.particle.newPreset("rain")
  rain:setPosition(400, 0)
  rain:setCollidesWithPhysics(world, 1.0, 0.4)
  rain:start()

  local rain = lurek.particle.newPreset("rain")
  rain:setPosition(400, 0)
  -- probe_radius=1.0: how far ahead each particle checks for collisions
  -- restitution=0.4: 40% energy retained on bounce (0=stick, 1=perfect bounce)
  rain:setCollidesWithPhysics(world, 1.0, 0.4)
  rain:start()
end

--@api-stub: ParticleSystem:hasCollidesWithPhysics
-- Returns true if this particle system has a collides with physics.
do
  -- Use this to check if physics collision was previously enabled.
  -- Useful in game state transitions where you conditionally disable effects.

  local world = lurek.physics.newWorld(0, 9.81)
  local ps = lurek.particle.newSystem({ maxParticles = 64 })
  ps:setCollidesWithPhysics(world)
  local enabled = ps:hasCollidesWithPhysics()  -- true
  lurek.log.debug("physics collision enabled=" .. tostring(enabled), "particle")
end

--@api-stub: ParticleSystem:clearCollidesWithPhysics
-- Clears all collides with physics items from this particle system.
do
  -- Disables particle-physics collision. Particles will pass through bodies again.
  -- Call this when transitioning to a scene without physics or to save CPU.

  local world = lurek.physics.newWorld(0, 9.81)
  local ps = lurek.particle.newSystem({ maxParticles = 64 })
  ps:setCollidesWithPhysics(world)
  -- Player entered a cutscene — disable expensive collision checks
  ps:clearCollidesWithPhysics()
end

--@api-stub: lurek.particle.newTrail
-- Creates a trail effect
do
  -- newTrail(lifetime, start_width) creates a line trail that fades over time.
  -- lifetime: how long each trail point persists (seconds)
  -- start_width: width in pixels at the head of the trail
  -- Trails are ideal for sword swings, projectile paths, and cursor effects.

  -- Example: glowing sword slash trail
  local sword_trail = lurek.particle.newTrail(0.35, 12.0)
  -- Head color: bright yellow-white at the slash origin
  sword_trail:setHeadColor(1.0, 0.95, 0.6, 1.0)
  -- Tail color: fades to orange and fully transparent
  sword_trail:setTailColor(1.0, 0.4, 0.0, 0.0)
  -- Push points each frame as the weapon tip moves
  sword_trail:pushPoint(100, 200)
end

-- ParticleSystem methods

--@api-stub: ParticleSystem:update
-- Advances this particle system by the given delta time.
do
  -- update(dt) must be called every frame to advance particle simulation.
  -- It moves particles, applies gravity/acceleration, ages them, and removes dead ones.
  -- Also triggers physics collision and callbacks if configured.

  local sys = lurek.particle.newSystem({ maxParticles = 128, emissionRate = 30 })
  sys:start()
  function lurek.process(dt)
    -- Pass the frame delta time; particles simulate in real-time
    sys:update(dt)
  end
end

--@api-stub: ParticleSystem:emit
-- Performs the emit operation on this particle system.
do
  -- emit(count) spawns exactly `count` particles in one burst.
  -- Unlike continuous emission via start(), this is a one-shot effect.
  -- Perfect for impacts, explosions, or hit sparks.

  -- Example: hit spark burst when a bullet strikes a wall
  local hit = lurek.particle.newSystem({
    maxParticles = 64,
    lifetimeMin = 0.1, lifetimeMax = 0.3,
    speedMin = 100, speedMax = 250,
    spread = math.pi,  -- full circle burst
  })
  hit:setPosition(160, 120)   -- spawn at the impact point
  hit:setColors({1, 1, 0.5, 1}, {1, 0.3, 0, 0})  -- yellow to orange fade
  hit:setSizes(3, 1)          -- shrink as they die
  hit:emit(24)                -- burst 24 sparks instantly
end

--@api-stub: ParticleSystem:start
-- Starts the operation managed by this particle system.
do
  -- start() begins continuous particle emission at the configured emissionRate.
  -- Emission continues until stop() is called or emitterLifetime expires.
  -- The system must also be update()d each frame to actually simulate particles.

  -- Example: rain falling across the full screen width
  local rain = lurek.particle.newSystem({
    maxParticles = 512, emissionRate = 200,
    lifetimeMin = 0.8, lifetimeMax = 1.2,
    speedMin = 300, speedMax = 450,
    direction = math.pi/2,  -- fall downward
    spread = 0.05,
  })
  rain:setPosition(400, 0)
  -- Emit across the full screen width using a uniform emission area
  rain:setEmissionArea("uniform", 800, 1)
  rain:start()
end

--@api-stub: ParticleSystem:stop
-- Stops the current operation or playback on this particle system.
do
  -- stop() halts emission immediately. Already-alive particles continue until they die.
  -- Use this when an effect should end gracefully (existing particles fade out).

  -- Example: rocket thruster that stops when player releases the key
  local jet = lurek.particle.newSystem({
    emissionRate = 100, maxParticles = 200,
    speedMin = 80, speedMax = 140,
    direction = math.pi/2, spread = 0.2,
  })
  jet:start()
  function lurek.process(dt)
    -- Release space to let the jet fade naturally
    if not lurek.input.keyboard.isDown("space") then
      jet:stop()
    end
    jet:update(dt)
  end
end

--@api-stub: ParticleSystem:pause
-- Pauses the current operation or playback on this particle system.
do
  -- pause() freezes all particle movement and emission in place.
  -- Time stops for this system — particles hold their position and lifetime.
  -- Useful for pause menus or freeze-frame effects.

  local steam = lurek.particle.newSystem({ emissionRate = 40 })
  steam:start()
  -- When game pauses, freeze the particle simulation
  if lurek.input.keyboard.isDown("escape") then
    steam:pause()
  end
end

--@api-stub: ParticleSystem:resume
-- Resumes a previously paused operation or playback on this particle system.
do
  -- resume() unpauses a frozen system. Particles continue exactly where they were.
  -- Pair with pause() for clean pause/unpause game states.

  local fog = lurek.particle.newSystem({ emissionRate = 20 })
  fog:start()
  fog:pause()
  -- Player unpauses the game
  fog:resume()  -- fog continues from its frozen state
end

--@api-stub: ParticleSystem:reset
-- Resets this particle system to its default state.
do
  -- reset() kills all live particles and resets the emitter timer.
  -- The system returns to its initial state as if freshly created.
  -- Use this when recycling a system for a new effect instance.

  -- Example: reuse an explosion system for multiple detonations
  local sparks = lurek.particle.newSystem({ maxParticles = 128, emissionRate = 80 })
  sparks:start()
  sparks:emit(60)
  -- After the explosion fades, reset for the next one
  sparks:reset()  -- all particles killed, emitter timer zeroed
end

--@api-stub: ParticleSystem:moveTo
-- Performs the move to operation on this particle system.
do
  -- moveTo(x, y) teleports the emitter to a new position.
  -- Unlike setPosition(), moveTo smoothly interpolates emission between the old
  -- and new positions so fast-moving emitters don't leave gaps.
  -- Always prefer moveTo() for moving objects (ships, projectiles, characters).

  -- Example: rocket exhaust that follows the ship without gaps
  local exhaust = lurek.particle.newSystem({
    emissionRate = 50, lifetimeMin = 0.3, lifetimeMax = 0.6,
    speedMin = 20, speedMax = 60, direction = math.pi/2, spread = 0.3,
  })
  exhaust:setColors({1, 0.8, 0.3, 1}, {0.3, 0.1, 0, 0})
  exhaust:start()
  local ship = { x = 200, y = 300 }
  function lurek.process(dt)
    -- moveTo interpolates emission points between frames
    exhaust:moveTo(ship.x, ship.y + 16)
    exhaust:update(dt)
  end
end

--@api-stub: ParticleSystem:count
-- Returns the total count of items held by this particle system.
do
  -- count() returns the number of currently alive particles.
  -- Use this for performance monitoring or conditional burst logic.

  -- Example: maintain a minimum smoke density
  local smoke = lurek.particle.newSystem({ maxParticles = 200, emissionRate = 10 })
  smoke:start()
  -- If wind blew particles away too fast, burst more
  if smoke:count() < 50 then
    smoke:emit(10)
  end
end

--@api-stub: ParticleSystem:isActive
-- Returns true if this particle system is currently active.
do
  -- isActive() returns true if the system has live particles OR is still emitting.
  -- A burst system with emitterLifetime=0.1 becomes inactive once all particles die.
  -- Use this to know when a one-shot effect is fully finished.

  -- Example: clean up explosion effect after it completes
  local explosion = lurek.particle.newSystem({
    emitterLifetime = 0.1, maxParticles = 80,
    emissionRate = 800,  -- short burst of many particles
    speedMin = 100, speedMax = 300, spread = math.pi,
  })
  explosion:start()
  -- Later in the game loop, check if the explosion is done
  if not explosion:isActive() then
    explosion:release()  -- free resources once fully faded
  end
end

--@api-stub: ParticleSystem:isPaused
-- Returns true if this particle system paused.
do
  -- isPaused() returns true only if pause() was called and resume() has not.

  local fountain = lurek.particle.newSystem({ emissionRate = 30 })
  fountain:start()
  fountain:pause()
  if fountain:isPaused() then
    lurek.log.info("fountain frozen — game is paused", "fx")
  end
end

--@api-stub: ParticleSystem:isStopped
-- Returns true if this particle system stopped.
do
  -- isStopped() returns true if emission has not started or was stopped.
  -- Note: a stopped system may still have live particles if stop() was just called.

  local burst = lurek.particle.newSystem({})
  -- Systems start in the stopped state
  if burst:isStopped() then
    burst:start()
  end
end

--@api-stub: ParticleSystem:isEmpty
-- Returns true if this particle system contains no items.
do
  -- isEmpty() returns true when zero particles are alive.
  -- Combine with isStopped() to know when a system is fully done.

  -- Example: release system resources once a one-shot burst fully fades
  local trail_fx = lurek.particle.newSystem({ emissionRate = 0, maxParticles = 32 })
  trail_fx:emit(5)
  -- After some frames...
  if trail_fx:isEmpty() then
    trail_fx:release()  -- safe to free, nothing visible
  end
end

--@api-stub: ParticleSystem:isFull
-- Returns true if this particle system full.
do
  -- isFull() returns true when alive particle count equals maxParticles.
  -- New emissions are silently dropped when full.
  -- Use this to throttle emission rate or increase buffer size dynamically.

  local heavy = lurek.particle.newSystem({ maxParticles = 32, emissionRate = 200 })
  heavy:start()
  function lurek.process(dt)
    heavy:update(dt)
    -- Throttle emission if pool is saturated
    if heavy:isFull() then
      heavy:setEmissionRate(50)
    end
  end
end

--@api-stub: ParticleSystem:release
-- Performs the release operation on this particle system.
do
  -- release() removes the system from shared storage and frees GPU resources.
  -- After release(), the handle is invalid — do not call any methods on it.
  -- Use this for one-shot effects that should not persist.

  local oneshot = lurek.particle.newSystem({ maxParticles = 16 })
  oneshot:emit(10)
  -- Once we know the effect won't be reused:
  oneshot:release()
end

--@api-stub: ParticleSystem:getCount
-- Returns the total count of items held by this particle system.
do
  -- getCount() is an alias for count(). Both return the live particle count.
  -- Errors if the handle was already released (use count() if you want nil-safe).

  local plume = lurek.particle.newSystem({ emissionRate = 25 })
  plume:start()
  local n = plume:getCount()
  lurek.log.debug("plume live=" .. n, "fx")
end

--@api-stub: ParticleSystem:type
-- Returns the Lua-visible type name string for this particle system handle.
do
  -- type() always returns "LParticleSystem" for particle system handles.
  -- Use typeOf() for duck-typing checks (e.g., "Drawable", "Object").

  local sys = lurek.particle.newSystem({})
  local t = sys:type()  -- "LParticleSystem"
  lurek.log.debug("handle type: " .. t, "fx")
end

--@api-stub: ParticleSystem:typeOf
-- Returns true if this particle system handle matches the given type name string.
do
  -- typeOf(name) checks if this handle is compatible with a given type.
  -- Recognized names: "LParticleSystem", "ParticleSystem", "Drawable", "Object"
  -- Use this for polymorphic drawable lists.

  local sys = lurek.particle.newSystem({})
  if sys:typeOf("Drawable") then
    -- Can safely pass to any function expecting a Drawable
    lurek.log.info("particle system is drawable", "fx")
  end
end

--@api-stub: ParticleSystem:setPosition
-- Sets the position of this particle system.
do
  -- setPosition(x, y) places the emitter at absolute screen coordinates.
  -- For stationary effects (campfires, torches, vents) this is fine.
  -- For moving objects, prefer moveTo() to avoid emission gaps.

  -- Example: muzzle flash at a gun barrel position
  local muzzle = lurek.particle.newSystem({
    emissionRate = 0, maxParticles = 32,
    lifetimeMin = 0.05, lifetimeMax = 0.12,
    speedMin = 200, speedMax = 400, spread = 0.3,
  })
  muzzle:setPosition(220, 180)
  muzzle:setColors({1, 1, 0.8, 1}, {1, 0.5, 0, 0})
  muzzle:emit(12)  -- single burst on fire
end

--@api-stub: ParticleSystem:getPosition
-- Returns the position of this particle system.
do
  -- getPosition() returns the emitter's current x, y coordinates.

  local sys = lurek.particle.newSystem({})
  sys:setPosition(50, 75)
  local x, y = sys:getPosition()
  lurek.log.debug("emitter at " .. x .. "," .. y, "fx")
end

--@api-stub: ParticleSystem:setEmissionRate
-- Sets the emission rate of this particle system.
do
  -- setEmissionRate(rate) sets particles emitted per second during start().
  -- Rate can be changed dynamically — useful for intensity scaling.

  -- Example: rain intensity tied to a weather variable
  local rain = lurek.particle.newSystem({ maxParticles = 400 })
  rain:start()
  local intensity = 0.7  -- 0.0=clear, 1.0=downpour
  rain:setEmissionRate(150 * intensity)  -- 105 particles/sec
end

--@api-stub: ParticleSystem:getEmissionRate
-- Returns the emission rate of this particle system.
do
  -- getEmissionRate() returns the current particles-per-second value.

  local sys = lurek.particle.newSystem({ emissionRate = 80 })
  if sys:getEmissionRate() > 100 then
    sys:setEmissionRate(100)  -- cap for performance
  end
end

--@api-stub: ParticleSystem:setParticleLifetime
-- Sets the particle lifetime of this particle system.
do
  -- setParticleLifetime(min, max) sets the random lifetime range.
  -- Each particle gets a random value between min and max seconds.
  -- Longer lifetimes = more particles alive at once = higher memory/GPU cost.

  -- Example: chimney smoke that lingers
  local smoke = lurek.particle.newSystem({})
  smoke:setParticleLifetime(1.5, 3.0)  -- particles live 1.5-3 seconds
  smoke:setEmissionRate(20)
  smoke:start()
end

--@api-stub: ParticleSystem:getParticleLifetime
-- Returns the particle lifetime of this particle system.
do
  -- getParticleLifetime() returns (min, max) lifetime in seconds.

  local sys = lurek.particle.newSystem({ lifetimeMin = 0.5, lifetimeMax = 1.2 })
  local lo, hi = sys:getParticleLifetime()
  lurek.log.debug("lifetime " .. lo .. " to " .. hi .. " sec", "fx")
end

--@api-stub: ParticleSystem:setEmitterLifetime
-- Sets the emitter lifetime of this particle system.
do
  -- setEmitterLifetime(t) makes the emitter auto-stop after t seconds.
  -- Use negative (-1) for infinite emission. Use short values for bursts.
  -- After the emitter stops, remaining particles still live out their lifetime.

  -- Example: explosion burst that emits for 0.15s then stops
  local explosion = lurek.particle.newSystem({ emissionRate = 200, maxParticles = 100 })
  explosion:setEmitterLifetime(0.15)  -- emit for 150ms then auto-stop
  explosion:setSpeed(100, 300)
  explosion:setSpread(math.pi)  -- full circle
  explosion:start()
end

--@api-stub: ParticleSystem:getEmitterLifetime
-- Returns the emitter lifetime of this particle system.
do
  -- getEmitterLifetime() returns the configured emitter duration.
  -- Negative values mean infinite (emit forever until stop() is called).

  local sys = lurek.particle.newSystem({ emitterLifetime = 2.0 })
  if sys:getEmitterLifetime() < 0 then
    lurek.log.info("emitter runs forever", "fx")
  end
end

--@api-stub: ParticleSystem:setSpeed
-- Sets the speed of this particle system.
do
  -- setSpeed(min, max) sets the initial launch speed range in pixels/second.
  -- Each particle gets a random speed between min and max at birth.
  -- Higher speed = particles travel farther before dying.

  -- Example: geyser shooting upward at high speed
  local geyser = lurek.particle.newSystem({ emissionRate = 80, maxParticles = 200 })
  geyser:setSpeed(180, 260)            -- fast upward burst
  geyser:setDirection(-math.pi/2)      -- up
  geyser:setSpread(0.15)               -- narrow cone
  geyser:setGravity(0, 400)            -- gravity pulls them back down
  geyser:start()
end

--@api-stub: ParticleSystem:getSpeed
-- Returns the speed of this particle system.
do
  -- getSpeed() returns (min, max) speed in pixels/second.

  local sys = lurek.particle.newSystem({ speedMin = 40, speedMax = 90 })
  local lo, hi = sys:getSpeed()
  lurek.log.debug("speed range: " .. lo .. " to " .. hi .. " px/s", "fx")
end

--@api-stub: ParticleSystem:setDirection
-- Sets the direction of this particle system.
do
  -- setDirection(dir) sets the base emission angle in radians.
  -- 0 = right, pi/2 = down, pi = left, -pi/2 = up (screen space)
  -- Combine with setSpread() to create a cone of emission.

  -- Example: horizontal jet engine exhaust pointing left
  local jet = lurek.particle.newSystem({ emissionRate = 60, maxParticles = 100 })
  jet:setDirection(math.pi)  -- emit leftward
  jet:setSpeed(120, 160)
  jet:start()
end

--@api-stub: ParticleSystem:getDirection
-- Returns the direction of this particle system.
do
  -- getDirection() returns the base emission angle in radians.

  local sys = lurek.particle.newSystem({ direction = math.pi/4 })
  local dir = sys:getDirection()
  lurek.log.debug("emit dir=" .. string.format("%.2f", dir) .. " rad", "fx")
end

--@api-stub: ParticleSystem:setSpread
-- Sets the spread of this particle system.
do
  -- setSpread(angle) sets the emission cone half-angle in radians.
  -- 0 = perfectly straight line, pi = full 360-degree circle.
  -- The total cone is direction ± spread.

  -- Example: snowfall with slight horizontal drift
  local snow = lurek.particle.newSystem({ emissionRate = 80, maxParticles = 300 })
  snow:setDirection(math.pi/2)  -- fall downward
  snow:setSpread(0.25)          -- slight random horizontal component
  snow:setSpeed(30, 60)
  snow:start()
end

--@api-stub: ParticleSystem:getSpread
-- Returns the spread of this particle system.
do
  -- getSpread() returns the cone half-angle in radians.
  -- Full cone width = spread * 2.

  local sys = lurek.particle.newSystem({ spread = 0.4 })
  local cone = sys:getSpread() * 2
  lurek.log.debug("full cone=" .. string.format("%.2f", cone) .. " rad", "fx")
end

--@api-stub: ParticleSystem:getLinearAcceleration
-- Returns the linear acceleration of this particle system.
do
  -- getLinearAcceleration() returns (xmin, ymin, xmax, ymax).
  -- Each particle gets a random acceleration in this range at birth.

  local sys = lurek.particle.newSystem({})
  sys:setLinearAcceleration(-10, 0, 10, 100)
  local xmn, ymn, xmx, ymx = sys:getLinearAcceleration()
  lurek.log.debug("accel x=[" .. xmn .. "," .. xmx .. "] y=[" .. ymn .. "," .. ymx .. "]", "fx")
end

--@api-stub: ParticleSystem:getRadialAcceleration
-- Returns the radial acceleration of this particle system.
do
  -- getRadialAcceleration() returns (min, max).
  -- Radial acceleration pulls particles toward (negative) or away from (positive)
  -- the emitter origin. Use negative values for implosion effects.

  local sys = lurek.particle.newSystem({ radialAccelMin = -50, radialAccelMax = -20 })
  local lo, hi = sys:getRadialAcceleration()
  if hi < 0 then
    lurek.log.info("particles implode toward emitter", "fx")
  end
end

--@api-stub: ParticleSystem:getTangentialAcceleration
-- Returns the tangential acceleration of this particle system.
do
  -- getTangentialAcceleration() returns (min, max).
  -- Tangential acceleration pushes particles perpendicular to their radial direction,
  -- creating swirl or orbit effects.

  local sys = lurek.particle.newSystem({ tangentialAccelMin = 30, tangentialAccelMax = 60 })
  local lo, hi = sys:getTangentialAcceleration()
  lurek.log.debug("swirl force " .. lo .. ".." .. hi, "fx")
end

--@api-stub: ParticleSystem:setLinearDamping
-- Sets the linear damping of this particle system.
do
  -- setLinearDamping(min, max) applies friction to particles over time.
  -- Higher values = particles slow down faster. Good for dust settling.
  -- Each particle gets a random damping value at birth.

  -- Example: dust cloud that settles quickly
  local dust = lurek.particle.newSystem({ emissionRate = 40, maxParticles = 100 })
  dust:setLinearDamping(1.5, 2.5)  -- high friction → particles decelerate fast
  dust:setSpeed(60, 100)
  dust:setSpread(math.pi)  -- radial burst
  dust:start()
end

--@api-stub: ParticleSystem:getLinearDamping
-- Returns the linear damping of this particle system.
do
  -- getLinearDamping() returns (min, max) damping coefficients.

  local sys = lurek.particle.newSystem({ linearDampingMin = 1.0, linearDampingMax = 2.0 })
  local lo, hi = sys:getLinearDamping()
  lurek.log.debug("damping " .. lo .. ".." .. hi, "fx")
end

--@api-stub: ParticleSystem:setSizes
-- Sets the sizes of this particle system.
do
  -- setSizes(...) sets size keyframes that particles interpolate through.
  -- Pass 2+ values: particle lerps from first to last over its lifetime.
  -- Example: (2, 8, 16, 4) → grow from 2, peak at 16, then shrink to 4.

  -- Example: smoke puff that grows then dissipates
  local puff = lurek.particle.newSystem({ emissionRate = 30, maxParticles = 64 })
  puff:setSizes(2, 8, 16, 4)  -- small → expand → shrink
  puff:setShape("circle")
  puff:start()
end

--@api-stub: ParticleSystem:getSizes
-- Returns the sizes of this particle system.
do
  -- getSizes() returns a table of the configured size keyframes.

  local sys = lurek.particle.newSystem({})
  sys:setSizes(4, 12, 6)
  local sizes = sys:getSizes()
  lurek.log.debug("size keyframes=" .. #sizes, "fx")  -- 3
end

--@api-stub: ParticleSystem:setSizeVariation
-- Sets the size variation of this particle system.
do
  -- setSizeVariation(v) adds randomness to per-particle size interpolation.
  -- v is 0.0 (all particles identical) to 1.0 (maximum variation).
  -- Makes effects look less uniform and more natural.

  -- Example: sparks with varied sizes for realism
  local sparks = lurek.particle.newSystem({ emissionRate = 50, maxParticles = 80 })
  sparks:setSizes(3, 1)          -- shrink over lifetime
  sparks:setSizeVariation(0.4)   -- 40% random size deviation per particle
  sparks:start()
end

--@api-stub: ParticleSystem:getSizeVariation
-- Returns the size variation of this particle system.
do
  -- getSizeVariation() returns the 0-1 variation factor.

  local sys = lurek.particle.newSystem({ sizeVariation = 0.6 })
  local v = sys:getSizeVariation()
  lurek.log.debug("size variation=" .. v, "fx")
end

--@api-stub: ParticleSystem:setRotation
-- Sets the rotation of this particle system.
do
  -- setRotation(min, max) sets the initial rotation range for spawned particles.
  -- Each particle starts at a random angle between min and max radians.
  -- Combine with setSpin() for rotating particles (leaves, debris, confetti).

  -- Example: falling leaves with random initial orientations
  local leaves = lurek.particle.newSystem({ emissionRate = 20, maxParticles = 60 })
  leaves:setRotation(0, math.pi * 2)  -- any starting angle
  leaves:setSpin(-1.0, 1.0)           -- spin both directions
  leaves:setShape("diamond")
  leaves:start()
end

--@api-stub: ParticleSystem:getRotation
-- Returns the rotation of this particle system.
do
  -- getRotation() returns (min, max) initial rotation in radians.

  local sys = lurek.particle.newSystem({ rotationMin = 0, rotationMax = math.pi })
  local lo, hi = sys:getRotation()
  lurek.log.debug("rot " .. lo .. ".." .. hi, "fx")
end

--@api-stub: ParticleSystem:setSpin
-- Sets the spin of this particle system.
do
  -- setSpin(min, max) sets angular velocity in radians/second.
  -- Particles rotate during their lifetime at a random rate in this range.
  -- Negative values spin counter-clockwise.

  -- Example: spinning coins flying out of a chest
  local coins = lurek.particle.newSystem({ emissionRate = 10, maxParticles = 30 })
  coins:setSpin(2.0, 4.0)       -- fast clockwise spin
  coins:setSpeed(80, 120)
  coins:setGravity(0, 300)      -- arc and fall
  coins:setDirection(-math.pi/2)
  coins:start()
end

--@api-stub: ParticleSystem:getSpin
-- Returns the spin of this particle system.
do
  -- getSpin() returns (min, max) angular velocity in rad/s.

  local sys = lurek.particle.newSystem({ spinMin = 0.5, spinMax = 1.5 })
  local lo, hi = sys:getSpin()
  lurek.log.debug("spin " .. lo .. ".." .. hi .. " rad/s", "fx")
end

--@api-stub: ParticleSystem:setSpinVariation
-- Sets the spin variation of this particle system.
do
  -- setSpinVariation(v) adds per-particle randomness to spin speed.
  -- 0.0 = all particles spin at the same rate, 1.0 = maximum jitter.

  -- Example: explosion debris with chaotic spin
  local debris = lurek.particle.newSystem({ emissionRate = 60, maxParticles = 100 })
  debris:setSpin(1.0, 2.0)
  debris:setSpinVariation(0.5)  -- each piece spins differently
  debris:setGravity(0, 500)
  debris:start()
end

--@api-stub: ParticleSystem:getSpinVariation
-- Returns the spin variation of this particle system.
do
  -- getSpinVariation() returns the 0-1 variation factor.

  local sys = lurek.particle.newSystem({ spinVariation = 0.3 })
  if sys:getSpinVariation() > 0 then
    lurek.log.info("spin will jitter per particle", "fx")
  end
end

--@api-stub: ParticleSystem:setRelativeRotation
-- Sets the relative rotation of this particle system.
do
  -- setRelativeRotation(true) makes particle rotation follow movement direction.
  -- Particles automatically face the way they're traveling.
  -- Essential for elongated shapes like arrows, bullets, or rain streaks.

  -- Example: arrow rain where each arrow points along its trajectory
  local arrows = lurek.particle.newSystem({ emissionRate = 30, maxParticles = 60 })
  arrows:setShape("ray")              -- elongated shape
  arrows:setRelativeRotation(true)    -- face movement direction
  arrows:setSpeed(140, 200)
  arrows:setDirection(math.pi * 0.6)  -- downward-right angle
  arrows:start()
end

--@api-stub: ParticleSystem:hasRelativeRotation
-- Returns true if this particle system has a relative rotation.
do
  -- hasRelativeRotation() checks if particles align to their velocity.

  local sys = lurek.particle.newSystem({})
  sys:setRelativeRotation(true)
  if sys:hasRelativeRotation() then
    lurek.log.info("particles align to motion vector", "fx")
  end
end

--@api-stub: ParticleSystem:setColors
-- Sets the colors of this particle system.
do
  -- setColors(...) sets color keyframes as {r, g, b, a} tables.
  -- Particles interpolate through these colors over their lifetime.
  -- Pass 2+ tables: first = birth color, last = death color.

  -- Example: fire gradient — bright yellow → orange → dark red → transparent
  local fire = lurek.particle.newSystem({ emissionRate = 80, maxParticles = 150 })
  fire:setColors(
    {1.0, 1.0, 0.6, 1.0},   -- bright yellow at birth
    {1.0, 0.4, 0.0, 0.8},   -- orange mid-life
    {0.2, 0.0, 0.0, 0.0}    -- dark red, fully transparent at death
  )
  fire:setShape("circle")
  fire:setSizes(6, 10, 4)
  fire:start()
end

--@api-stub: ParticleSystem:getColors
-- Returns the colors of this particle system.
do
  -- getColors() returns the array of {r, g, b, a} color keyframes.

  local sys = lurek.particle.newSystem({})
  sys:setColors({1, 0, 0, 1}, {0, 0, 1, 1})
  local colors = sys:getColors()
  lurek.log.debug("color stops=" .. #colors, "fx")  -- 2
end

--@api-stub: ParticleSystem:setOffset
-- Sets the offset of this particle system.
do
  -- setOffset(ox, oy) shifts where particles are rendered relative to their position.
  -- Does not change physics or emission logic — purely visual.
  -- Useful for centering particles on a sprite that has an off-center anchor.

  local glow = lurek.particle.newSystem({ emissionRate = 25, maxParticles = 40 })
  glow:setOffset(0, -8)   -- render 8px above actual particle position
  glow:setSizes(8, 4)
  glow:start()
end

--@api-stub: ParticleSystem:getOffset
-- Returns the offset of this particle system.
do
  -- getOffset() returns (ox, oy) render offset.

  local sys = lurek.particle.newSystem({ offsetX = 4, offsetY = -2 })
  local ox, oy = sys:getOffset()
  lurek.log.debug("offset " .. ox .. "," .. oy, "fx")
end

--@api-stub: ParticleSystem:setInsertMode
-- Sets the insert mode of this particle system.
do
  -- setInsertMode(mode) controls draw order of new particles.
  -- "top" = newest on top (default), "bottom" = newest behind, "random" = shuffled.
  -- Use "bottom" for smoke so older (larger) puffs render in front.

  -- Example: smoke stack where older puffs are visually in front
  local smoke = lurek.particle.newSystem({ emissionRate = 30, maxParticles = 80 })
  smoke:setInsertMode("bottom")  -- new smoke spawns behind old smoke
  smoke:setColors({1, 1, 1, 0.4}, {0.5, 0.5, 0.5, 0})
  smoke:setSizes(4, 12)
  smoke:start()
end

--@api-stub: ParticleSystem:getInsertMode
-- Returns the insert mode of this particle system.
do
  -- getInsertMode() returns "top", "bottom", or "random".

  local sys = lurek.particle.newSystem({})
  sys:setInsertMode("random")
  local mode = sys:getInsertMode()
  lurek.log.debug("insert mode=" .. mode, "fx")
end

--@api-stub: ParticleSystem:setBufferSize
-- Sets the buffer size of this particle system.
do
  -- setBufferSize(n) resizes the particle pool capacity at runtime.
  -- Use this when you need more particles than initially allocated.
  -- Note: existing particles are preserved if n >= current count.

  -- Example: heavy rain that needs many more particles than default
  local rain = lurek.particle.newSystem({ maxParticles = 64 })
  rain:setBufferSize(1024)         -- expand pool to handle downpour
  rain:setEmissionRate(500)
  rain:start()
end

--@api-stub: ParticleSystem:getBufferSize
-- Returns the buffer size of this particle system.
do
  -- getBufferSize() returns the current maximum particle capacity.

  local sys = lurek.particle.newSystem({ maxParticles = 256 })
  local cap = sys:getBufferSize()
  lurek.log.debug("pool capacity=" .. cap, "fx")
end

--@api-stub: ParticleSystem:setEmissionArea
-- Sets the emission area of this particle system.
do
  -- setEmissionArea(dist, w, h, angle?, dir_rel?) sets where particles spawn.
  -- Distributions: "uniform" (rectangle), "ellipse", "normal" (gaussian), "none"
  -- w, h = area dimensions. angle = rotation of the area. dir_rel = relative to direction.
  -- Use "ellipse" for campfires, "uniform" for rain across a region.

  -- Example: fog bank as an elliptical emission area
  local fog = lurek.particle.newSystem({ emissionRate = 40, maxParticles = 100 })
  fog:setEmissionArea("ellipse", 200, 80)  -- wide, short ellipse
  fog:setSpeed(5, 15)
  fog:setColors({0.8, 0.8, 1.0, 0.3}, {0.8, 0.8, 1.0, 0})
  fog:start()
end

--@api-stub: ParticleSystem:getEmissionArea
-- Returns the emission area of this particle system.
do
  -- getEmissionArea() returns (distribution_name, width, height).

  local sys = lurek.particle.newSystem({})
  sys:setEmissionArea("uniform", 120, 40)
  local kind, w, h = sys:getEmissionArea()
  lurek.log.debug("area=" .. kind .. " " .. w .. "x" .. h, "fx")
end

--@api-stub: ParticleSystem:setShape
-- Sets the shape of this particle system.
do
  -- setShape(name) sets the visual shape of each particle.
  -- Shapes: "square" (default), "circle", "diamond", "ring", "ray", "cross"
  -- Use "ray" for rain/lasers, "circle" for soft effects, "ring" for magic.

  -- Example: twinkling diamond-shaped stars
  local stars = lurek.particle.newSystem({ emissionRate = 20, maxParticles = 60 })
  stars:setShape("diamond")
  stars:setSizes(6, 2)  -- shrink as they twinkle out
  stars:setColors({1, 1, 1, 1}, {0.8, 0.8, 1, 0})
  stars:start()
end

--@api-stub: ParticleSystem:getShape
-- Returns the shape of this particle system.
do
  -- getShape() returns the current shape name string.

  local sys = lurek.particle.newSystem({})
  sys:setShape("ring")
  if sys:getShape() == "ring" then
    lurek.log.info("ring shape selected", "fx")
  end
end

--@api-stub: ParticleSystem:getGravity
-- Returns the gravity of this particle system.
do
  -- getGravity() returns (gx, gy) in pixels/second^2.
  -- Gravity is applied to all particles every frame. (0, 400) = fall down.

  local rain = lurek.particle.newSystem({ gravityX = 0, gravityY = 400 })
  local gx, gy = rain:getGravity()
  lurek.log.debug("gravity=" .. gx .. "," .. gy, "fx")
end

--@api-stub: ParticleSystem:setGravity
-- Sets the gravity of this particle system.
do
  -- setGravity(gx, gy) applies a constant force to all particles.
  -- Use (0, positive) for falling debris, (0, negative) for rising sparks.
  -- Combine with setSpeed for arcing trajectories.

  -- Example: explosion debris that arcs downward
  local debris = lurek.particle.newSystem({ emissionRate = 40, maxParticles = 80 })
  debris:setGravity(0, 600)            -- strong downward pull
  debris:setSpeed(120, 200)            -- fast initial burst
  debris:setSpread(math.pi)            -- radial explosion
  debris:setDirection(-math.pi/2)      -- initial burst upward
  debris:start()
end

--@api-stub: ParticleSystem:render
-- Draws or renders this particle system to the current render target.
do
  -- render(ox?, oy?) enqueues draw commands for all alive particles.
  -- Call this in lurek.draw(). Optional ox, oy offset the entire system.
  -- Particles are drawn in their insert-mode order.

  -- Example: basic particle render loop
  local fx = lurek.particle.newSystem({ maxParticles = 128, emissionRate = 40 })
  fx:setPosition(200, 200)
  fx:setColors({0, 1, 0.5, 1}, {0, 0.5, 1, 0})
  fx:start()
  function lurek.process(dt) fx:update(dt) end
  function lurek.draw()
    fx:render()  -- draw at system position
    -- fx:render(cam_x, cam_y) -- with camera offset
  end
end

--@api-stub: ParticleSystem:clone
-- Performs the clone operation on this particle system.
do
  -- clone() duplicates the entire system configuration into a new handle.
  -- The clone is independent — changing one does not affect the other.
  -- Use this to stamp out many identical effects from a prototype.

  -- Example: create a prototype, then clone for each enemy hit
  local proto = lurek.particle.newSystem({
    emissionRate = 50, maxParticles = 64,
    lifetimeMin = 0.5, lifetimeMax = 1.0,
    speedMin = 60, speedMax = 120, spread = math.pi,
  })
  proto:setColors({1, 0, 0, 1}, {0.5, 0, 0, 0})
  -- Clone for a specific hit location
  local copy = proto:clone()
  copy:setPosition(400, 300)
  copy:emit(30)
end

--@api-stub: ParticleSystem:drawToImage
-- Draws or renders this particle system to the current render target.
do
  -- drawToImage(w, h) renders particles into an image (LImageData).
  -- Useful for baking particle effects into textures or thumbnails.
  -- The image is w x h pixels.

  local sys = lurek.particle.newSystem({ maxParticles = 32 })
  sys:setPosition(64, 64)
  sys:setColors({1, 0.5, 0, 1}, {1, 0, 0, 0})
  sys:emit(20)
  sys:update(0.1)  -- simulate briefly so particles spread
  local img = sys:drawToImage(128, 128)
  lurek.log.debug("baked thumbnail " .. img:getWidth() .. "x" .. img:getHeight(), "fx")
end

--@api-stub: ParticleSystem:toImage
-- Performs the to image operation on this particle system.
do
  -- toImage(w, h) is an alias for drawToImage(). Same behavior.
  -- Both render the current particle state into an image.

  local sys = lurek.particle.newSystem({ maxParticles = 16 })
  sys:emit(8)
  sys:update(0.05)
  local img = sys:toImage(64, 64)
  lurek.log.debug("preview ready " .. img:getWidth() .. "px", "fx")
end

--@api-stub: ParticleSystem:warmUp
-- Performs the warm up operation on this particle system.
do
  -- warmUp(seconds) fast-forwards the simulation without rendering.
  -- Particles are born and die as if time passed — the system looks "lived in".
  -- Use this so effects don't start from empty when a scene loads.

  -- Example: fountain that appears already running when the level starts
  local fountain = lurek.particle.newSystem({
    emissionRate = 60, maxParticles = 200,
    lifetimeMin = 1.0, lifetimeMax = 2.0,
    speedMin = 80, speedMax = 120,
    direction = -math.pi/2, spread = 0.3,
  })
  fountain:setGravity(0, 200)
  fountain:start()
  fountain:warmUp(2.0)  -- simulate 2 seconds so fountain is already flowing
end

--@api-stub: ParticleSystem:clearAttractors
-- Clears all attractors items from this particle system.
do
  -- clearAttractors() removes all attractor points.
  -- Particles will no longer be pulled toward any point.

  local sys = lurek.particle.newSystem({ emissionRate = 30, maxParticles = 64 })
  sys:addAttractor(200, 200, 400, 80)
  -- Remove the attractor when the magnet power-up ends
  sys:clearAttractors()
  sys:start()
end

--@api-stub: ParticleSystem:getAttractorCount
-- Returns the number of attractor items in this particle system.
do
  -- getAttractorCount() returns how many attractors are currently active.

  local sys = lurek.particle.newSystem({})
  sys:addAttractor(100, 100, 250, 60)
  sys:addAttractor(300, 300, 150, 40)
  lurek.log.debug("attractors=" .. sys:getAttractorCount(), "fx")  -- 2
end

--@api-stub: ParticleSystem:clearBounds
-- Clears all bounds items from this particle system.
do
  -- clearBounds() removes collision bounds so particles can fly offscreen.

  local sys = lurek.particle.newSystem({ emissionRate = 20, maxParticles = 50 })
  sys:setBounds(0, 800, 0, 600, 0.6)
  -- Remove bounds when transitioning to an open area
  sys:clearBounds()
  sys:start()
end

--@api-stub: ParticleSystem:getFlipbook
-- Returns the flipbook of this particle system.
do
  -- getFlipbook() returns (cols, rows, fps) or nil if not configured.
  -- Flipbook animates a sprite sheet grid on each particle.

  local sys = lurek.particle.newSystem({})
  sys:setFlipbook(4, 2, 12)
  local cols, rows, fps = sys:getFlipbook()
  if cols then
    lurek.log.debug("flipbook " .. cols .. "x" .. rows .. " @" .. fps .. "fps", "fx")
  end
end

-- Trail methods

--@api-stub: Trail:pushPoint
-- Performs the push point operation on this trail.
do
  -- pushPoint(x, y) adds a new segment to the trail head.
  -- Call this every frame with the object's current position.
  -- Old points fade and disappear based on the trail's lifetime setting.

  -- Example: mouse cursor trail effect
  local trail = lurek.particle.newTrail(0.4, 8.0)
  trail:setHeadColor(0.3, 0.8, 1.0, 1.0)
  trail:setTailColor(0.1, 0.3, 1.0, 0.0)
  function lurek.process(dt)
    local mx, my = lurek.input.getMousePosition()
    trail:pushPoint(mx, my)  -- add current mouse pos each frame
    trail:update(dt)         -- age and remove old points
  end
end

--@api-stub: Trail:update
-- Advances this trail by the given delta time.
do
  -- update(dt) ages all trail points. Points that exceed lifetime are removed.
  -- Must be called every frame, just like ParticleSystem:update().

  local trail = lurek.particle.newTrail(0.5, 10.0)
  trail:pushPoint(100, 100)
  function lurek.process(dt)
    trail:update(dt)  -- age points; old ones fade and vanish
  end
end

--@api-stub: Trail:setWidth
-- Sets the width of this trail.
do
  -- setWidth(start, end?) sets the trail width in pixels.
  -- start = width at the head (newest point).
  -- end = width at the tail (oldest point). Omit for uniform width.
  -- The trail tapers linearly between start and end.

  -- Example: sword slash that tapers from thick to thin
  local trail = lurek.particle.newTrail(0.3, 4.0)
  trail:setWidth(16.0, 2.0)  -- 16px at head, narrows to 2px at tail
  trail:pushPoint(50, 50)
end

--@api-stub: Trail:getWidth
-- Returns the width of this trail.
do
  -- getWidth() returns (start_width, end_width).

  local trail = lurek.particle.newTrail(0.3, 12.0)
  trail:setWidth(12.0, 1.0)
  local sw, ew = trail:getWidth()
  lurek.log.debug("trail w=" .. sw .. " → " .. ew, "fx")
end

--@api-stub: Trail:setLifetime
-- Sets the lifetime of this trail.
do
  -- setLifetime(seconds) changes how long each trail point persists.
  -- Shorter = snappy effect, longer = lingering trail.
  -- Can be changed at runtime for dynamic effects.

  -- Example: speed boost makes trails longer
  local trail = lurek.particle.newTrail(0.2, 6.0)
  trail:setLifetime(0.8)  -- extend trail during boost
  trail:pushPoint(120, 80)
end

--@api-stub: Trail:getLifetime
-- Returns the lifetime of this trail.
do
  -- getLifetime() returns the point lifetime in seconds.

  local trail = lurek.particle.newTrail(0.5, 8.0)
  local life = trail:getLifetime()
  if life > 1.0 then
    trail:setLifetime(1.0)  -- cap for performance
  end
end

--@api-stub: Trail:setMinDistance
-- Sets the min distance of this trail.
do
  -- setMinDistance(pixels) prevents adding points too close together.
  -- Points closer than this distance are ignored by pushPoint().
  -- Reduces vertex count when the object moves slowly.

  -- Example: projectile trail that doesn't waste points at low speed
  local trail = lurek.particle.newTrail(0.4, 8.0)
  trail:setMinDistance(4.0)     -- need at least 4px between points
  trail:pushPoint(200, 100)
  trail:pushPoint(201, 100)    -- ignored: only 1px away
  trail:pushPoint(210, 100)    -- accepted: 10px away
end

--@api-stub: Trail:getPointCount
-- Returns the number of point items in this trail.
do
  -- getPointCount() returns the number of active trail points.
  -- Points are removed as they age past lifetime.

  local trail = lurek.particle.newTrail(0.3, 6.0)
  trail:pushPoint(0, 0)
  trail:pushPoint(20, 0)
  lurek.log.debug("trail points=" .. trail:getPointCount(), "fx")  -- 2
end

--@api-stub: Trail:clear
-- Clears all items from this trail.
do
  -- clear() removes all trail points immediately.
  -- Use this when teleporting an object (so the trail doesn't stretch across the map).

  -- Example: player teleports — clear trail so it doesn't draw a line across the screen
  local trail = lurek.particle.newTrail(0.4, 8.0)
  trail:pushPoint(50, 50)
  trail:pushPoint(60, 60)
  -- Player teleported to a new location
  trail:clear()  -- erase all points, start fresh
end

--@api-stub: Trail:drawToImage
-- Draws or renders this trail to the current render target.
do
  -- drawToImage(w, h) renders the trail into an image (LImageData).
  -- Useful for creating trail textures or visual debugging.

  local trail = lurek.particle.newTrail(0.5, 12.0)
  trail:pushPoint(20, 20)
  trail:pushPoint(80, 60)
  trail:pushPoint(110, 30)
  local img = trail:drawToImage(128, 128)
  lurek.log.debug("baked trail img " .. img:getWidth() .. "px", "fx")
end

-- Phase 03: Lua Extensibility Hooks

--@api-stub: ParticleSystem:addSubSystem
-- Adds a sub system to this particle system.
do
  -- addSubSystem(config) attaches a child particle system to a parent.
  -- Sub-systems emit in sync with the parent (same position/timing).
  -- Returns the 1-based index of the new sub-system.
  -- Use this for layered effects: fire + smoke + sparks as one unit.

  -- Example: fire effect with an attached smoke layer
  local fire = lurek.particle.newSystem({
    maxParticles = 200, emissionRate = 60,
    lifetimeMin = 0.3, lifetimeMax = 0.7,
    speedMin = 40, speedMax = 90,
    direction = -math.pi / 2, spread = 0.4,
  })
  -- Smoke sub-system: slower, longer-lived, larger
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

--@api-stub: ParticleSystem:subSystemCount
-- Performs the sub system count operation on this particle system.
do
  -- subSystemCount() returns how many child systems are attached.

  local ps = lurek.particle.newSystem({ maxParticles = 64 })
  ps:addSubSystem({ maxParticles = 16 })
  ps:addSubSystem({ maxParticles = 16 })
  lurek.log.debug("sub count: " .. ps:subSystemCount(), "fx")  -- 2
end

--@api-stub: ParticleSystem:setCustomEmissionShape
-- Sets the custom emission shape of this particle system.
do
  -- setCustomEmissionShape(callback) provides a Lua function that returns (x, y)
  -- for each spawned particle. The callback is invoked once per new particle.
  -- Use this for complex patterns: spirals, rings, text shapes, etc.

  -- Example: particles spawning in a spiral pattern
  local ps = lurek.particle.newSystem({
    maxParticles = 128, emissionRate = 30,
    lifetimeMin = 0.8, lifetimeMax = 1.5,
    speedMin = 0, speedMax = 0,  -- stationary: position IS the effect
  })
  local angle = 0
  ps:setCustomEmissionShape(function()
    -- Advance the spiral angle each spawn
    angle = angle + 0.3
    local r = 60 + math.sin(angle * 2) * 20  -- pulsing radius
    -- Return offset from emitter position
    return math.cos(angle) * r, math.sin(angle) * r
  end)
  ps:setPosition(400, 300)
  ps:start()
end

--@api-stub: ParticleSystem:setOnDeathBatch
-- Sets the on death batch of this particle system.
do
  -- setOnDeathBatch(callback) registers a function called with a batch of death records.
  -- Each record has: { x, y, vx, vy } — position and velocity at death.
  -- Use this to spawn secondary effects (sub-explosions, blood decals, sound cues).

  -- Example: spawn sparkle particles at each death position
  local ps = lurek.particle.newSystem({
    maxParticles = 64, emissionRate = 10,
    lifetimeMin = 0.5, lifetimeMax = 1.0,
    speedMin = 50, speedMax = 100,
    direction = -math.pi/2, spread = 0.5,
  })
  ps:setOnDeathBatch(function(batch)
    -- batch is an array of {x, y, vx, vy} death records
    for _, entry in ipairs(batch) do
      -- Could spawn a secondary system here at the death point
      lurek.log.debug(
        string.format("particle died at (%.1f, %.1f) vel=(%.1f, %.1f)",
          entry.x, entry.y, entry.vx, entry.vy),
        "fx"
      )
    end
  end)
  ps:setPosition(320, 240)
  ps:start()
end

--@api-stub: lurek.particle.fromTOML
-- Creates a particle system from a TOML config file
do
  -- fromTOML(path) loads a particle system definition from a .toml file.
  -- This is useful for data-driven effects: artists edit TOML, code just loads it.
  -- The path is resolved via GameFS (save/, content/, or absolute).

  -- Example: write a TOML config and load it
  local toml_str = [[
max_particles = 100
emission_rate = 30.0
lifetime_min = 0.5
lifetime_max = 2.0
speed_min = 30.0
speed_max = 80.0
direction = 0.0
spread = 1.57
gravity_y = 200.0
]]
  lurek.filesystem.write("save/particle_test.toml", toml_str)
  local ps = lurek.particle.fromTOML("save/particle_test.toml")
  ps:setPosition(400, 300)
  ps:start()
  lurek.log.debug("fromTOML loaded: " .. tostring(ps), "particle")
end

--@api-stub: ParticleSystem:addAttractor
-- Adds a attractor to this particle system.
do
  -- addAttractor(x, y, strength, radius) creates a force point.
  -- Particles within `radius` pixels of (x, y) are pulled with `strength` force.
  -- Positive strength = attract (pull in), negative = repel (push away).
  -- Use this for black holes, magnets, or wind vortices.

  -- Example: vortex that sucks particles toward center
  local ps = lurek.particle.newSystem({
    maxParticles = 200, emissionRate = 40,
    speedMin = 20, speedMax = 60, spread = math.pi,
  })
  ps:setPosition(400, 300)
  -- Strong attractor at center: pulls particles back in
  ps:addAttractor(400, 300, 300, 120)
  ps:start()
  lurek.log.debug("attractors: " .. ps:getAttractorCount(), "particle")
end

--@api-stub: ParticleSystem:addSubEmitter
-- Adds a sub emitter to this particle system.
do
  -- addSubEmitter(config_tbl, burst_count?) configures a death sub-emitter.
  -- When a parent particle dies, the sub-emitter spawns burst_count particles
  -- at the death position using the given config.
  -- Use this for cascading effects: firework → sparks, blood → drips.

  -- Example: firework that spawns sparks on death
  local parent = lurek.particle.newSystem({
    maxParticles = 200, emissionRate = 5,
    lifetimeMin = 0.8, lifetimeMax = 1.2,
    speedMin = 100, speedMax = 200,
    direction = -math.pi/2, spread = 0.4,
  })
  parent:setGravity(0, 300)
  -- When a parent particle dies, burst 8 tiny sparks
  parent:addSubEmitter({
    maxParticles = 50,
    lifetimeMin = 0.2, lifetimeMax = 0.5,
    speedMin = 30, speedMax = 80,
    spread = math.pi,
  }, 8)
  parent:start()
  lurek.log.debug("sub emitter count: " .. parent:subSystemCount(), "particle")
end

--@api-stub: ParticleSystem:setBounds
-- Sets the bounds of this particle system.
do
  -- setBounds(xmin, xmax, ymin, ymax, restitution) confines particles to a rectangle.
  -- Particles bounce off the bounds with the given restitution (0=stick, 1=full bounce).
  -- Use this for enclosed effects like sparks in a box or snow in a snow globe.

  -- Example: bouncing sparks confined to the screen area
  local ps = lurek.particle.newSystem({
    maxParticles = 500, emissionRate = 60,
    speedMin = 100, speedMax = 250, spread = math.pi,
  })
  ps:setPosition(400, 300)
  -- Confine to screen; particles bounce off edges with 60% energy retention
  ps:setBounds(0, 800, 0, 600, 0.6)
  ps:start()
end

--@api-stub: ParticleSystem:setFlipbook
-- Sets the flipbook of this particle system.
do
  -- setFlipbook(cols, rows, fps) enables sprite-sheet animation per particle.
  -- Each particle cycles through (cols * rows) frames at the given fps.
  -- Requires a texture set on the particle system for visual output.
  -- Use this for animated fire sprites, explosions, or smoke puffs.

  local ps = lurek.particle.newSystem({ maxParticles = 300, emissionRate = 20 })
  ps:setFlipbook(4, 4, 16)  -- 4x4 grid = 16 frames at 16fps
  ps:start()
  lurek.log.debug("flipbook configured", "particle")
end

--@api-stub: Trail:setHeadColor
-- Sets the head color of this trail.
do
  -- setHeadColor(r, g, b, a) sets the color at the trail's newest point (head).
  -- The trail interpolates from head color to tail color along its length.

  -- Example: fire trail — bright at head, dark at tail
  local trail = lurek.particle.newTrail(2.0, 8.0)
  trail:setHeadColor(1.0, 0.8, 0.0, 1.0)   -- bright orange-yellow
  trail:setTailColor(1.0, 0.2, 0.0, 0.0)   -- dark red, fully transparent
end

--@api-stub: ParticleSystem:setLinearAcceleration
-- Sets the linear acceleration of this particle system.
do
  -- setLinearAcceleration(xmin, ymin, xmax, ymax) sets per-particle acceleration.
  -- Each particle gets a random acceleration in the given range at birth.
  -- Use positive Y for falling effects, negative Y for rising.
  -- Unlike gravity (global), this varies per particle for organic motion.

  -- Example: confetti that drifts and flutters
  local ps = lurek.particle.newSystem({ maxParticles = 500, emissionRate = 30 })
  ps:setLinearAcceleration(-20, 50, 20, 150)  -- slight horizontal drift + falling
  ps:setDirection(-math.pi/2)
  ps:setSpeed(40, 80)
  ps:start()
end

--@api-stub: ParticleSystem:setRadialAcceleration
-- Sets the radial acceleration of this particle system.
do
  -- setRadialAcceleration(min, max) sets per-particle radial force.
  -- Positive = push away from emitter origin (explosion dispersal).
  -- Negative = pull toward emitter origin (implosion, vortex).

  -- Example: energy sphere that pulls particles inward
  local ps = lurek.particle.newSystem({ maxParticles = 400, emissionRate = 60 })
  ps:setRadialAcceleration(-80, -40)  -- pull toward center
  ps:setSpeed(60, 120)
  ps:setSpread(math.pi)
  ps:start()
end

--@api-stub: Trail:setTailColor
-- Sets the tail color of this trail.
do
  -- setTailColor(r, g, b, a) sets the color at the trail's oldest point (tail).
  -- Usually set alpha to 0 so the tail fades out smoothly.

  -- Example: ice trail — bright cyan at head, transparent blue at tail
  local trail = lurek.particle.newTrail(2.0, 8.0)
  trail:setHeadColor(0.5, 0.8, 1.0, 1.0)   -- bright cyan
  trail:setTailColor(0.3, 0.5, 1.0, 0.0)   -- fades to transparent blue
end

--@api-stub: ParticleSystem:setTangentialAcceleration
-- Sets the tangential acceleration of this particle system.
do
  -- setTangentialAcceleration(min, max) pushes particles perpendicular to their
  -- radial direction from the emitter. Creates swirl/orbit effects.
  -- Combine with radialAcceleration for orbital motion.

  -- Example: magic portal with swirling particles
  local ps = lurek.particle.newSystem({ maxParticles = 400, emissionRate = 50 })
  ps:setTangentialAcceleration(30, 80)   -- swirl clockwise
  ps:setRadialAcceleration(-20, -10)     -- slight inward pull
  ps:setSpeed(40, 80)
  ps:setSpread(math.pi)
  ps:start()
end

-- -----------------------------------------------------------------------------
-- LTrail methods
-- -----------------------------------------------------------------------------

--@api-stub: LTrail:type
-- Returns the Lua-visible type name for this trail handle
do
  -- type() returns "LTrail" for trail handles.

  local trail = lurek.particle.newTrail(0.4, 8.0)
  local t = trail:type()  -- "LTrail"
  lurek.log.debug("trail type: " .. t, "particle")
end

--@api-stub: LTrail:typeOf
-- Returns whether this trail handle matches a supported type name
do
  -- typeOf(name) checks if this handle matches the given type.
  -- Recognized names: "LTrail", "Object"

  local trail = lurek.particle.newTrail(0.4, 8.0)
  lurek.log.debug("is LTrail: " .. tostring(trail:typeOf("LTrail")), "particle")    -- true
  lurek.log.debug("is Object: " .. tostring(trail:typeOf("Object")), "particle")    -- true
  lurek.log.debug("is unknown: " .. tostring(trail:typeOf("Unknown")), "particle")  -- false
end

print("content/examples/particle.lua")

-- =============================================================================
-- STUBS: 98 uncovered lurek.particle API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LParticleSystem methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LParticleSystem:update ----------------------------------------
--@api-stub: LParticleSystem:update
-- Updates the particle system, applies optional physics collision, and invokes pending callbacks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:update(0.016)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:emit ------------------------------------------
--@api-stub: LParticleSystem:emit
-- Emits particles immediately. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:emit(10)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:start -----------------------------------------
--@api-stub: LParticleSystem:start
-- Starts particle emission. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:start()
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:stop ------------------------------------------
--@api-stub: LParticleSystem:stop
-- Stops particle emission. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:stop()
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:pause -----------------------------------------
--@api-stub: LParticleSystem:pause
-- Pauses particle emission and updates.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:pause()
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:resume ----------------------------------------
--@api-stub: LParticleSystem:resume
-- Resumes a paused particle system. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:resume()
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:reset -----------------------------------------
--@api-stub: LParticleSystem:reset
-- Resets particles and emitter state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:reset()
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:moveTo ----------------------------------------
--@api-stub: LParticleSystem:moveTo
-- Moves the particle emitter. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:moveTo(0.0, 0.0)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:count -----------------------------------------
--@api-stub: LParticleSystem:count
-- Returns the current particle count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:count()  -- -> integer
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:isActive --------------------------------------
--@api-stub: LParticleSystem:isActive
-- Returns whether the particle system is active.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:isActive()  -- -> boolean
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:isPaused --------------------------------------
--@api-stub: LParticleSystem:isPaused
-- Returns whether the particle system is paused.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:isPaused()  -- -> boolean
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:isStopped -------------------------------------
--@api-stub: LParticleSystem:isStopped
-- Returns whether the particle system is stopped or missing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:isStopped()  -- -> boolean
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:isEmpty ---------------------------------------
--@api-stub: LParticleSystem:isEmpty
-- Returns whether the particle system has no particles or is missing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:isEmpty()  -- -> boolean
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:isFull ----------------------------------------
--@api-stub: LParticleSystem:isFull
-- Returns whether the particle system has reached capacity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:isFull()  -- -> boolean
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:release ---------------------------------------
--@api-stub: LParticleSystem:release
-- Releases the particle system from shared storage.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:release()  -- -> boolean
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getCount --------------------------------------
--@api-stub: LParticleSystem:getCount
-- Returns particle count and errors if the handle was released.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getCount()  -- -> integer
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:type ------------------------------------------
--@api-stub: LParticleSystem:type
-- Returns the Lua-visible type name for this particle system handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:type()  -- -> string
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:typeOf ----------------------------------------
--@api-stub: LParticleSystem:typeOf
-- Returns whether this particle system handle matches a supported type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:typeOf("hero")  -- -> boolean
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setPosition -----------------------------------
--@api-stub: LParticleSystem:setPosition
-- Sets emitter position. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setPosition(0.0, 0.0)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getPosition -----------------------------------
--@api-stub: LParticleSystem:getPosition
-- Returns emitter position. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getPosition()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setEmissionRate -------------------------------
--@api-stub: LParticleSystem:setEmissionRate
-- Sets emission rate. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setEmissionRate(rate)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getEmissionRate -------------------------------
--@api-stub: LParticleSystem:getEmissionRate
-- Returns emission rate. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getEmissionRate()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setParticleLifetime ---------------------------
--@api-stub: LParticleSystem:setParticleLifetime
-- Sets particle lifetime range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setParticleLifetime(min, max)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getParticleLifetime ---------------------------
--@api-stub: LParticleSystem:getParticleLifetime
-- Returns particle lifetime range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getParticleLifetime()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setEmitterLifetime ----------------------------
--@api-stub: LParticleSystem:setEmitterLifetime
-- Sets emitter lifetime. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setEmitterLifetime(t)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getEmitterLifetime ----------------------------
--@api-stub: LParticleSystem:getEmitterLifetime
-- Returns emitter lifetime. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getEmitterLifetime()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setSpeed --------------------------------------
--@api-stub: LParticleSystem:setSpeed
-- Sets particle speed range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setSpeed(min, max)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getSpeed --------------------------------------
--@api-stub: LParticleSystem:getSpeed
-- Returns particle speed range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getSpeed()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setDirection ----------------------------------
--@api-stub: LParticleSystem:setDirection
-- Sets emission direction. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setDirection(dir)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getDirection ----------------------------------
--@api-stub: LParticleSystem:getDirection
-- Returns emission direction. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getDirection()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setSpread -------------------------------------
--@api-stub: LParticleSystem:setSpread
-- Sets emission spread. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setSpread(spread)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getSpread -------------------------------------
--@api-stub: LParticleSystem:getSpread
-- Returns emission spread. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getSpread()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setLinearAcceleration -------------------------
--@api-stub: LParticleSystem:setLinearAcceleration
-- Sets linear acceleration range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setLinearAcceleration(xmin, ymin, xmax, ymax)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getLinearAcceleration -------------------------
--@api-stub: LParticleSystem:getLinearAcceleration
-- Returns linear acceleration range.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getLinearAcceleration()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setRadialAcceleration -------------------------
--@api-stub: LParticleSystem:setRadialAcceleration
-- Sets radial acceleration range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setRadialAcceleration(min, max)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getRadialAcceleration -------------------------
--@api-stub: LParticleSystem:getRadialAcceleration
-- Returns radial acceleration range.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getRadialAcceleration()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setTangentialAcceleration ---------------------
--@api-stub: LParticleSystem:setTangentialAcceleration
-- Sets tangential acceleration range.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setTangentialAcceleration(min, max)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getTangentialAcceleration ---------------------
--@api-stub: LParticleSystem:getTangentialAcceleration
-- Returns tangential acceleration range.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getTangentialAcceleration()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setLinearDamping ------------------------------
--@api-stub: LParticleSystem:setLinearDamping
-- Sets linear damping range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setLinearDamping(min, max)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getLinearDamping ------------------------------
--@api-stub: LParticleSystem:getLinearDamping
-- Returns linear damping range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getLinearDamping()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setSizes --------------------------------------
--@api-stub: LParticleSystem:setSizes
-- Sets the particle size keyframes used during a particle's lifetime. Pass two or more values to interpolate between them.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setSizes(...)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getSizes --------------------------------------
--@api-stub: LParticleSystem:getSizes
-- Returns particle size keyframes. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getSizes()  -- -> table
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setSizeVariation ------------------------------
--@api-stub: LParticleSystem:setSizeVariation
-- Sets size variation. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setSizeVariation(1.0)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getSizeVariation ------------------------------
--@api-stub: LParticleSystem:getSizeVariation
-- Returns size variation. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getSizeVariation()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setRotation -----------------------------------
--@api-stub: LParticleSystem:setRotation
-- Sets particle rotation range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setRotation(min, max)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getRotation -----------------------------------
--@api-stub: LParticleSystem:getRotation
-- Returns particle rotation range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getRotation()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setSpin ---------------------------------------
--@api-stub: LParticleSystem:setSpin
-- Sets particle spin range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setSpin(min, max)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getSpin ---------------------------------------
--@api-stub: LParticleSystem:getSpin
-- Returns particle spin range. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getSpin()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setSpinVariation ------------------------------
--@api-stub: LParticleSystem:setSpinVariation
-- Sets spin variation. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setSpinVariation(1.0)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getSpinVariation ------------------------------
--@api-stub: LParticleSystem:getSpinVariation
-- Returns spin variation. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getSpinVariation()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setRelativeRotation ---------------------------
--@api-stub: LParticleSystem:setRelativeRotation
-- Sets whether particle rotation is relative to movement.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setRelativeRotation(1.0)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:hasRelativeRotation ---------------------------
--@api-stub: LParticleSystem:hasRelativeRotation
-- Returns whether relative rotation is enabled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:hasRelativeRotation()  -- -> boolean
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setColors -------------------------------------
--@api-stub: LParticleSystem:setColors
-- Sets particle color keyframes from one or more RGBA tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setColors(...)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getColors -------------------------------------
--@api-stub: LParticleSystem:getColors
-- Returns particle color keyframes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getColors()  -- -> table
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setOffset -------------------------------------
--@api-stub: LParticleSystem:setOffset
-- Sets particle spawn offset. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setOffset(ox, oy)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getOffset -------------------------------------
--@api-stub: LParticleSystem:getOffset
-- Returns particle spawn offset. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getOffset()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setInsertMode ---------------------------------
--@api-stub: LParticleSystem:setInsertMode
-- Sets particle insert mode. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setInsertMode(mode)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getInsertMode ---------------------------------
--@api-stub: LParticleSystem:getInsertMode
-- Returns particle insert mode. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getInsertMode()  -- -> string
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setBufferSize ---------------------------------
--@api-stub: LParticleSystem:setBufferSize
-- Sets maximum particle buffer size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setBufferSize(5)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getBufferSize ---------------------------------
--@api-stub: LParticleSystem:getBufferSize
-- Returns maximum particle buffer size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getBufferSize()  -- -> integer
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setEmissionArea -------------------------------
--@api-stub: LParticleSystem:setEmissionArea
-- Sets emission area distribution and size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setEmissionArea(dist, 64.0, 64.0, [angle], [dir_rel])
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getEmissionArea -------------------------------
--@api-stub: LParticleSystem:getEmissionArea
-- Returns emission area distribution and size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getEmissionArea()  -- -> string
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setShape --------------------------------------
--@api-stub: LParticleSystem:setShape
-- Sets particle shape. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setShape(shape)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getShape --------------------------------------
--@api-stub: LParticleSystem:getShape
-- Returns particle shape. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getShape()  -- -> string
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getGravity ------------------------------------
--@api-stub: LParticleSystem:getGravity
-- Returns particle gravity. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getGravity()  -- -> number
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setGravity ------------------------------------
--@api-stub: LParticleSystem:setGravity
-- Sets particle gravity. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setGravity(gx, gy)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:render ----------------------------------------
--@api-stub: LParticleSystem:render
-- Enqueues particle render commands with an optional offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:render([ox], [oy])
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:clone -----------------------------------------
--@api-stub: LParticleSystem:clone
-- Clones this particle system configuration into a new system handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:clone()  -- -> LParticleSystem
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:drawToImage -----------------------------------
--@api-stub: LParticleSystem:drawToImage
-- Draws particles to image data. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:drawToImage(64.0, 64.0)  -- -> LImageData
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:toImage ---------------------------------------
--@api-stub: LParticleSystem:toImage
-- Draws particles to image data. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:toImage(64.0, 64.0)  -- -> LImageData
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:warmUp ----------------------------------------
--@api-stub: LParticleSystem:warmUp
-- Advances the system by a warm-up duration.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:warmUp(seconds)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:addAttractor ----------------------------------
--@api-stub: LParticleSystem:addAttractor
-- Adds an attractor to the particle system.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:addAttractor(0.0, 0.0, strength, 24.0)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:clearAttractors -------------------------------
--@api-stub: LParticleSystem:clearAttractors
-- Clears all attractors. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:clearAttractors()
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getAttractorCount -----------------------------
--@api-stub: LParticleSystem:getAttractorCount
-- Returns attractor count. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getAttractorCount()  -- -> integer
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setBounds -------------------------------------
--@api-stub: LParticleSystem:setBounds
-- Sets collision bounds for particles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setBounds(xmin, xmax, ymin, ymax, restitution)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:clearBounds -----------------------------------
--@api-stub: LParticleSystem:clearBounds
-- Clears collision bounds. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:clearBounds()
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setCollidesWithPhysics ------------------------
--@api-stub: LParticleSystem:setCollidesWithPhysics
-- Enables particle collision against a physics world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setCollidesWithPhysics(world_ud, [probe_radius], [restitution])
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:clearCollidesWithPhysics ----------------------
--@api-stub: LParticleSystem:clearCollidesWithPhysics
-- Disables particle collision against a physics world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:clearCollidesWithPhysics()
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:hasCollidesWithPhysics ------------------------
--@api-stub: LParticleSystem:hasCollidesWithPhysics
-- Returns whether particle physics collision is enabled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:hasCollidesWithPhysics()  -- -> boolean
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:addSubEmitter ---------------------------------
--@api-stub: LParticleSystem:addSubEmitter
-- Configures a death sub-emitter from a config table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:addSubEmitter(config_tbl, [burst_count])
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setFlipbook -----------------------------------
--@api-stub: LParticleSystem:setFlipbook
-- Sets flipbook grid and frame rate. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setFlipbook(cols, rows, fps)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:getFlipbook -----------------------------------
--@api-stub: LParticleSystem:getFlipbook
-- Returns flipbook grid and frame rate when configured.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:getFlipbook()  -- -> integer
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:addSubSystem ----------------------------------
--@api-stub: LParticleSystem:addSubSystem
-- Adds a particle sub-system from a config table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:addSubSystem(config_tbl)  -- -> integer
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:subSystemCount --------------------------------
--@api-stub: LParticleSystem:subSystemCount
-- Returns particle sub-system count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:subSystemCount()  -- -> integer
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setCustomEmissionShape ------------------------
--@api-stub: LParticleSystem:setCustomEmissionShape
-- Sets a Lua callback for custom emission positions.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setCustomEmissionShape(cb)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- ---- Stub: LParticleSystem:setOnDeathBatch -------------------------------
--@api-stub: LParticleSystem:setOnDeathBatch
-- Sets a Lua callback invoked with batched particle death records.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lParticleSystem_stub:setOnDeathBatch(cb)
-- (replace lParticleSystem_stub with your real LParticleSystem instance above)

-- -----------------------------------------------------------------------------
-- LTrail methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTrail:pushPoint ----------------------------------------------
--@api-stub: LTrail:pushPoint
-- Adds a point to the trail. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:pushPoint(0.0, 0.0)
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:update -------------------------------------------------
--@api-stub: LTrail:update
-- Updates trail point lifetimes. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:update(0.016)
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:setWidth -----------------------------------------------
--@api-stub: LTrail:setWidth
-- Sets trail start and optional end width.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:setWidth(start, [end])
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:getWidth -----------------------------------------------
--@api-stub: LTrail:getWidth
-- Returns trail width settings. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:getWidth()  -- -> LuaValue
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:setLifetime --------------------------------------------
--@api-stub: LTrail:setLifetime
-- Sets trail point lifetime. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:setLifetime(lifetime)
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:getLifetime --------------------------------------------
--@api-stub: LTrail:getLifetime
-- Returns trail point lifetime. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:getLifetime()  -- -> number
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:setMinDistance -----------------------------------------
--@api-stub: LTrail:setMinDistance
-- Sets minimum distance between trail points.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:setMinDistance(distance)
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:setHeadColor -------------------------------------------
--@api-stub: LTrail:setHeadColor
-- Sets trail head color. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:setHeadColor(1.0, 0.8, 0.2, 1.0)
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:setTailColor -------------------------------------------
--@api-stub: LTrail:setTailColor
-- Sets trail tail color. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:setTailColor(1.0, 0.8, 0.2, 1.0)
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:getPointCount ------------------------------------------
--@api-stub: LTrail:getPointCount
-- Returns trail point count. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:getPointCount()  -- -> integer
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:clear --------------------------------------------------
--@api-stub: LTrail:clear
-- Clears all trail points. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:clear()
-- (replace lTrail_stub with your real LTrail instance above)

-- ---- Stub: LTrail:drawToImage --------------------------------------------
--@api-stub: LTrail:drawToImage
-- Draws the trail to image data. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTrail_stub:drawToImage(64.0, 64.0)  -- -> LImageData
-- (replace lTrail_stub with your real LTrail instance above)
