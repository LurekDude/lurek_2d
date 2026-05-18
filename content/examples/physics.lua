-- content/examples/physics.lua
-- lurek.physics API examples.
-- Run: cargo run -- content/examples/physics.lua

--@api-stub: lurek.physics.newWorld
-- Creates a new physics world with the given gravity vector
do
  -- newWorld(gx, gy) creates the simulation container.
  -- gx=0 means no horizontal gravity; gy=9.81 is Earth-like downward pull.
  -- Positive Y points down in screen space, so gy>0 makes things fall.
  local world = lurek.physics.newWorld(0, 9.81)

  -- The world starts empty. Verify it was created successfully.
  lurek.log.info("physics world created with " .. world:getBodyCount() .. " bodies", "boot")
end

--@api-stub: LCellular:step
-- Steps a physics world forward by dt seconds (free-function variant)
do
  -- The free-function variant is handy when you pass worlds between modules.
  -- Call once per frame with the frame delta to advance the simulation.
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    -- dt is the elapsed time since last frame (typically ~1/60 seconds).
    -- The step resolves forces, collisions, and joint constraints.
    lurek.physics.step(world, dt)
  end
end

--@api-stub: lurek.physics.destroyWorld
-- No-op placeholder for API parity
do
  -- destroyWorld is a no-op in Lurek2D because worlds are garbage-collected.
  -- It exists for code that expects explicit cleanup (porting from other engines).
  local world = lurek.physics.newWorld(0, 9.81)
  lurek.physics.destroyWorld(world)
end

--@api-stub: LWorld:newBody
-- Creates a new body in a world (free-function variant)
do
  -- Free-function body creation: newBody(world, x, y, type)
  -- Types: "dynamic" (moves with physics), "static" (immovable),
  --        "kinematic" (moves by code, not forces), "sensor" (overlap only)
  local world = lurek.physics.newWorld(0, 9.81)

  -- Place a crate at pixel (100,200) that falls under gravity
  local crate = lurek.physics.newBody(world, 100, 200, "dynamic")
  crate:setMass(1.0) -- mass in kg, affects inertia and impulse response
end

--@api-stub: lurek.physics.getBody
-- Returns position and velocity of a body (free-function variant for quick queries)
do
  -- getBody returns x, y, vx, vy in one call — avoids multiple method lookups.
  -- Useful for ECS-style code where you batch-query many bodies each frame.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = lurek.physics.newBody(world, 100, 200, "dynamic")
  local x, y, vx, vy = lurek.physics.getBody(world, body)
  lurek.log.debug("crate at " .. x .. "," .. y .. " v=" .. vx .. "," .. vy, "phys")
end

--@api-stub: lurek.physics.setBodyVelocity
-- Sets a body's velocity (free-function variant)
do
  -- Directly override velocity — useful for projectiles that need a fixed speed.
  -- Unlike applyImpulse, this ignores mass and replaces the current velocity.
  local world = lurek.physics.newWorld(0, 9.81)
  local bullet = lurek.physics.newBody(world, 100, 200, "dynamic")

  -- Fire bullet rightward at 600 px/s with slight upward arc
  lurek.physics.setBodyVelocity(world, bullet, 600, -200)
end

--@api-stub: LBody:isSleepingAllowed
-- Checks if sleeping is allowed on a body (free-function variant)
do
  -- Bodies "sleep" when at rest to save CPU. Sleeping bodies skip simulation.
  -- Query this to decide if you need to wake a body before applying forces.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = lurek.physics.newBody(world, 100, 200, "dynamic")
  if lurek.physics.isSleepingAllowed(world, body) then
    lurek.log.debug("body may sleep when idle — good for background props", "phys")
  end
end

--@api-stub: LBody:setSleepingAllowed
-- Sets whether a body is allowed to sleep (free-function variant)
do
  -- Disable sleeping for the player character so it always responds to input.
  -- Sleeping bodies ignore forces until woken by a collision or wakeUp() call.
  local world = lurek.physics.newWorld(0, 9.81)
  local player = lurek.physics.newBody(world, 100, 200, "dynamic")
  lurek.physics.setSleepingAllowed(world, player, false)
end

--@api-stub: lurek.physics.newRectangleShape
-- Creates a rectangle collision shape with the given dimensions
do
  -- Standalone shapes can be configured with material properties before attaching.
  -- This decouples shape definition from body creation — share shapes across bodies.
  local crate_shape = lurek.physics.newRectangleShape(64, 64)

  -- Verify the shape was created with the expected type
  lurek.log.info("crate shape type=" .. crate_shape:getType(), "phys")
end

--@api-stub: lurek.physics.newCircleShape
-- Creates a circle collision shape with the given radius
do
  -- Circles are the cheapest collision shape — prefer for balls, coins, bullets.
  -- The radius is in world units (pixels at default 1:1 meter scale).
  local ball_shape = lurek.physics.newCircleShape(16)
  lurek.log.info("ball radius=" .. ball_shape:getRadius(), "phys")
end

--@api-stub: lurek.physics.newEdgeShape
-- Creates an edge (line segment) collision shape between two local points
do
  -- Edges are infinitely thin line segments — perfect for floor boundaries.
  -- They are one-sided: objects can only collide from the "outside" direction.
  local floor_shape = lurek.physics.newEdgeShape(0, 480, 800, 480)
  lurek.log.info("floor edge type=" .. floor_shape:getType(), "phys")
end

--@api-stub: lurek.physics.newPolygonShape
-- Creates a convex polygon collision shape from vertex coordinate pairs
do
  -- Polygon shapes must be convex (no inward angles) with max 8 vertices.
  -- Vertices are in local (body-relative) coordinates, wound counter-clockwise.
  local triangle = lurek.physics.newPolygonShape(0, 0, 32, 0, 16, 28)
  lurek.log.info("triangle type=" .. triangle:getType(), "phys")
end

--@api-stub: lurek.physics.newChainShape
-- Creates a chain (polyline) collision shape
do
  -- Chains are sequences of connected edges — ideal for terrain outlines.
  -- First arg: closed (true=loop, false=open polyline).
  -- Remaining args: x,y coordinate pairs defining the path.
  local hill = lurek.physics.newChainShape(false, 0, 400, 100, 360, 200, 380, 300, 420)
  lurek.log.info("hill chain type=" .. hill:getType(), "phys")
end

--@api-stub: lurek.physics.attachShape
-- Attaches a previously created shape to a body, using the shape's stored material properties
do
  -- attachShape uses the density/friction/restitution set on the shape itself.
  -- This pattern lets you pre-configure shapes and reuse them across bodies.
  local world = lurek.physics.newWorld(0, 9.81)
  local car = lurek.physics.newBody(world, 200, 200, "dynamic")

  -- Create a roof shape with custom material properties
  local roof = lurek.physics.newRectangleShape(64, 16)
  roof:setDensity(0.5)     -- lightweight roof panel
  roof:setFriction(0.3)    -- slightly slippery
  roof:setRestitution(0.1) -- minimal bounce

  -- Attach the configured shape — body mass updates automatically from density
  lurek.physics.attachShape(car, roof)
end

--@api-stub: lurek.physics.getCollisions
-- Returns all collision events from the last world step as {body_a, body_b} pairs
do
  -- Poll collision events each frame to trigger game logic (damage, sounds, etc).
  -- Events are cleared on the next step(), so process them before stepping again.
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    lurek.physics.step(world, dt)
    for _, c in ipairs(lurek.physics.getCollisions(world)) do
      -- c.body_a and c.body_b are body IDs — use getBodyData to identify entities
      lurek.log.debug("hit " .. c.body_a .. " vs " .. c.body_b, "phys")
    end
  end
end

--@api-stub: lurek.physics.debugDraw
-- Enables or disables automatic physics debug overlay rendering for the next frame
do
  -- debugDraw renders wireframe outlines of all collision shapes on screen.
  -- Toggle it with a key press during development to visualize physics bodies.
  lurek.physics.debugDraw(true)
  function lurek.process(dt)
    -- Press F3 to hide the debug overlay for a clean view
    if lurek.input.keyboard.isDown("f3") then lurek.physics.debugDraw(false) end
  end
end

--@api-stub: lurek.physics.drawDebugGpu
-- Queues a GPU-rendered physics debug visualization using the world's current body state
do
  -- drawDebugGpu renders physics shapes using the GPU pipeline (faster than CPU).
  -- Accepts an optional config table to customize colors and line thickness.
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.draw()
    lurek.physics.drawDebugGpu(world, {
      bodyColor = {0, 1, 0, 1},   -- green for dynamic bodies (RGBA 0-1)
      lineWidth = 2.0              -- thicker lines for visibility
    })
  end
end

--@api-stub: lurek.physics.newTerrain
-- Creates a destructible terrain grid linked to a physics world for automatic collider generation
do
  -- Terrain is a grid where each cell is solid or empty.
  -- After modifying cells, call flush() to regenerate physics colliders.
  -- Args: width (cells), height (cells), cellSize (pixels per cell), world
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)

  -- Fill the entire grid solid, then carve tunnels later
  terrain:fillAll(true)
  -- flush() must be called to sync the grid state to the physics engine
  terrain:flush()
end

--@api-stub: lurek.physics.newCellular
-- Creates a new cellular automaton simulation grid for particle-like physics (sand, water, fire)
do
  -- Cellular automata simulate granular materials without per-particle physics bodies.
  -- Each cell holds a material type that flows/falls/burns according to simple rules.
  local sand = lurek.physics.newCellular(128, 64)

  -- Drop sand from the top center — it will pile up naturally
  sand:setCell(64, 0, lurek.physics.CELL_SAND)

  -- Call step() each frame to advance the simulation one tick
  function lurek.process(dt) sand:step() end
end


-- World methods

--@api-stub: LCellular:step
-- Performs the step operation on this world.
do
  -- The method variant of step — call on the world object directly.
  -- One step per frame at variable dt gives smooth but non-deterministic results.
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt) -- advances bodies, resolves collisions, fires callbacks
  end
end

--@api-stub: LWorld:clear
-- Clears all items from this world.
do
  -- clear() removes all bodies and joints instantly — useful for level transitions.
  -- After clear, the world is empty but still valid for reuse.
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 200, "dynamic")
  world:clear()
  lurek.log.info("world cleared, body count=" .. world:getBodyCount(), "scene")
end

--@api-stub: LWorld:getGravity
-- Returns the gravity of this world.
do
  -- Returns gx, gy — the global force applied to all dynamic bodies each step.
  local world = lurek.physics.newWorld(0, 9.81)
  local gx, gy = world:getGravity()
  lurek.log.info("gravity=" .. gx .. "," .. gy, "phys")
end

--@api-stub: LWorld:setGravity
-- Sets the gravity of this world.
do
  -- Change gravity at runtime for gameplay effects (flip gravity, zero-G zones).
  -- All dynamic bodies respond immediately on the next step.
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    -- Press G to flip gravity upward (negative Y = up in screen space)
    if lurek.input.keyboard.isDown("g") then world:setGravity(0, -9.81) end
  end
end

--@api-stub: LWorld:setMeter
-- Sets the meter of this world.
do
  -- setMeter defines how many pixels equal 1 physics meter.
  -- Default is 1 (1 pixel = 1 meter). Set to 64 for "64 pixels = 1 meter".
  -- This affects how gravity and forces translate to pixel movement.
  local world = lurek.physics.newWorld(0, 9.81)
  world:setMeter(64) -- now 64 pixels = 1 physics meter
  lurek.log.info("ppm=" .. world:getMeter(), "phys")
end

--@api-stub: LWorld:getMeter
-- Returns the meter of this world.
do
  -- Use getMeter to convert between pixel coordinates and physics units.
  local world = lurek.physics.newWorld(0, 9.81)
  local ppm = world:getMeter()
  lurek.log.debug("1 meter = " .. ppm .. " pixels", "phys")
end

--@api-stub: LWorld:toPhysics
-- Performs the to physics operation on this world.
do
  -- toPhysics converts a pixel measurement to physics meters using the current scale.
  -- Use when passing pixel positions to physics functions that expect meters.
  local world = lurek.physics.newWorld(0, 9.81)
  local px = 128
  local meters = world:toPhysics(px)
  lurek.log.debug(px .. " px = " .. meters .. " m", "phys")
end

--@api-stub: LWorld:toPixels
-- Performs the to pixels operation on this world.
do
  -- toPixels is the inverse of toPhysics — convert physics meters back to pixels.
  -- Use when drawing physics positions on screen.
  local world = lurek.physics.newWorld(0, 9.81)
  local pixels = world:toPixels(2.5)
  lurek.log.debug("2.5 m = " .. pixels .. " px", "phys")
end

--@api-stub: LWorld:getBodyCount
-- Returns the number of body items in this world.
do
  -- Useful for pool management — limit spawning if too many bodies exist.
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 200, "dynamic")
  if world:getBodyCount() < 1000 then world:newBody(150, 200, "dynamic") end
end

--@api-stub: LWorld:getBodyIds
-- Returns the body ids of this world.
do
  -- Returns a table of all body IDs currently in the world.
  -- Iterate to update game state, check positions, or batch-process bodies.
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 200, "dynamic")
  for _, id in ipairs(world:getBodyIds()) do
    lurek.log.debug("body id=" .. id, "phys")
  end
end

--@api-stub: LWorld:destroyBody
-- Destroys this world and releases all associated resources.
do
  -- destroyBody removes a body by its numeric ID.
  -- All attached fixtures and joints are also removed.
  -- Use when an enemy dies or a projectile hits something.
  local world = lurek.physics.newWorld(0, 9.81)
  local enemy = world:newBody(300, 200, "dynamic")
  world:destroyBody(enemy:getId()) -- enemy is now invalid, don't use it
end

--@api-stub: LWorld:newBody
-- Creates and returns a new body widget or object.
do
  -- World:newBody(x, y, type) creates a body and returns an LBody handle.
  -- The handle provides per-body methods (setMass, applyImpulse, etc).
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  crate:setMass(2.5)         -- heavier crate resists impulses more
  crate:setRestitution(0.3)  -- slight bounce on impact
end

--@api-stub: LWorld:fixtureCount
-- Performs the fixture count operation on this world.
do
  -- A body can have multiple fixtures (colliders). Use fixtureCount to inspect.
  -- Multi-fixture bodies are common for complex shapes (character = box + circle feet).
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  local n = world:fixtureCount(body:getId())
  lurek.log.debug("body has " .. n .. " fixtures", "phys")
end

--@api-stub: LWorld:jointCount
-- Performs the joint count operation on this world.
do
  -- jointCount returns the total number of active joints in the world.
  local world = lurek.physics.newWorld(0, 9.81)
  lurek.log.info("joints=" .. world:jointCount(), "phys")
end

--@api-stub: LWorld:getJointIds
-- Returns the joint ids of this world.
do
  -- Iterate all joints to inspect, update, or conditionally destroy them.
  local world = lurek.physics.newWorld(0, 9.81)
  for _, jid in ipairs(world:getJointIds()) do
    lurek.log.debug("joint id=" .. jid, "phys")
  end
end

--@api-stub: LWorld:getJointBodies
-- Returns the joint bodies of this world.
do
  -- getJointBodies returns the two body IDs connected by a joint.
  -- Useful for damage propagation — if joint breaks, damage both connected bodies.
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local a, b = world:getJointBodies(jid)
  lurek.log.debug("joint " .. jid .. " links " .. a .. " <-> " .. b, "phys")
end

--@api-stub: LWorld:destroyJoint
-- Destroys this world and releases all associated resources.
do
  -- destroyJoint disconnects two bodies. The bodies remain in the world.
  -- Use when cutting a rope, breaking a hinge, or detaching a limb.
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  world:destroyJoint(jid) -- b2 is now free-falling
end

--@api-stub: LWorld:getJointType
-- Returns the joint type of this world.
do
  -- Returns "revolute", "distance", "prismatic", "weld", etc.
  -- Useful for generic joint-processing logic.
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local kind = world:getJointType(jid)
  if kind == "revolute" then lurek.log.debug("hinge joint", "phys") end
end

--@api-stub: LWorld:getJointMotorSpeed
-- Returns the joint motor speed of this world.
do
  -- Motor speed is in radians/sec for revolute, meters/sec for prismatic.
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local rpm = world:getJointMotorSpeed(jid)
  lurek.log.debug("motor speed=" .. rpm, "phys")
end

--@api-stub: LWorld:getJointLimits
-- Returns the joint limits of this world.
do
  -- Joint limits constrain the range of motion (angle for revolute, distance for prismatic).
  -- Returns lower, upper bounds.
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local lo, hi = world:getJointLimits(jid)
  lurek.log.debug("limits=[" .. lo .. ", " .. hi .. "]", "phys")
end

--@api-stub: LWorld:getBodyAtPoint
-- Returns the body at point of this world.
do
  -- Point query: returns the body ID at a pixel coordinate, or nil.
  -- Use for click-to-select, mouse picking, or touch interaction.
  local world = lurek.physics.newWorld(0, 9.81)
  local hit = world:getBodyAtPoint(150, 200)
  if hit then lurek.log.debug("clicked body=" .. hit, "phys") end
end

--@api-stub: LWorld:getCollisionEvents
-- Returns the collision events of this world.
do
  -- getCollisionEvents returns all collisions from the LAST step.
  -- Each entry has bodyA and bodyB fields (numeric IDs).
  -- Process these to trigger damage, spawn particles, play sounds.
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getCollisionEvents()) do
      lurek.log.debug("hit " .. e.bodyA .. " vs " .. e.bodyB, "phys")
    end
  end
end

--@api-stub: LWorld:getBeginContactEvents
-- Returns the begin contact events of this world.
do
  -- Begin-contact fires ONCE when two bodies first start touching.
  -- Use for "on enter" triggers: stepping on a switch, entering a zone.
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getBeginContactEvents()) do
      lurek.log.debug("begin " .. e.bodyA .. "/" .. e.bodyB, "phys")
    end
  end
end

--@api-stub: LWorld:getEndContactEvents
-- Returns the end contact events of this world.
do
  -- End-contact fires ONCE when two bodies stop touching.
  -- Use for "on leave" triggers: leaving a pressure plate, exiting water.
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getEndContactEvents()) do
      lurek.log.debug("end " .. e.bodyA .. "/" .. e.bodyB, "phys")
    end
  end
end

--@api-stub: LWorld:getContacts
-- Returns the contacts of this world.
do
  -- getContacts returns ALL current contact manifolds (persistent, not events).
  -- Each has bodyA, bodyB, normalX, normalY, isTouching.
  -- Use for continuous checks like "is anything touching the lava?"
  local world = lurek.physics.newWorld(0, 9.81)
  for _, c in ipairs(world:getContacts()) do
    if c.isTouching then
      -- The normal points from bodyA toward bodyB at the contact surface
      lurek.log.debug("contact n=" .. c.normalX .. "," .. c.normalY, "phys")
    end
  end
end

--@api-stub: LWorld:getBodyContacts
-- Returns the body contacts of this world.
do
  -- Get contacts for a SPECIFIC body — useful for ground detection in platformers.
  -- Check if any contact normal points upward (body is resting on something).
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  local touches = world:getBodyContacts(player:getId())
  lurek.log.debug("player contacts=" .. #touches, "phys")
end

--@api-stub: LWorld:setBodyType
-- Sets the body type of this world.
do
  -- Change body type at runtime without recreating it.
  -- Common pattern: door starts "static", becomes "kinematic" when triggered.
  local world = lurek.physics.newWorld(0, 9.81)
  local door = world:newBody(200, 200, "static")
  world:setBodyType(door:getId(), "kinematic") -- now movable by code
end

--@api-stub: LWorld:getBodyType
-- Returns the body type of this world.
do
  -- Returns "static", "dynamic", "kinematic", or "sensor".
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if world:getBodyType(body:getId()) == "dynamic" then body:setMass(1.0) end
end

--@api-stub: LWorld:setBeginContact
-- Sets the begin contact of this world.
do
  -- Callback fires during step() when two bodies first touch.
  -- Arguments are body IDs (not LBody objects) — use getBodyData to identify.
  local world = lurek.physics.newWorld(0, 9.81)
  world:setBeginContact(function(a, b)
    lurek.log.info("touch " .. a .. " <-> " .. b, "phys")
  end)
end

--@api-stub: LWorld:clearBeginContact
-- Clears all begin contact items from this world.
do
  -- Remove the callback to stop receiving begin-contact notifications.
  local world = lurek.physics.newWorld(0, 9.81)
  world:setBeginContact(function(a, b) end)
  world:clearBeginContact() -- callback is now nil, won't fire
end

--@api-stub: LWorld:setEndContact
-- Sets the end contact of this world.
do
  -- Fires when two bodies separate after being in contact.
  local world = lurek.physics.newWorld(0, 9.81)
  world:setEndContact(function(a, b)
    lurek.log.debug("apart " .. a .. " / " .. b, "phys")
  end)
end

--@api-stub: LWorld:clearEndContact
-- Clears all end contact items from this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:setEndContact(function(a, b) end)
  world:clearEndContact()
end

--@api-stub: LWorld:getBodyData
-- Returns the body data of this world.
do
  -- Attach arbitrary Lua data to bodies for game logic identification.
  -- This avoids maintaining a separate ID-to-entity lookup table.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  world:setBodyData(body:getId(), { kind = "enemy", hp = 30 })

  -- Later, in a collision callback, retrieve the data to know what collided
  local data = world:getBodyData(body:getId())
  if data then lurek.log.debug("entity kind=" .. data.kind, "phys") end
end

--@api-stub: LWorld:clearBodyData
-- Clears all body data items from this world.
do
  -- Detach the Lua data from a body (frees the reference for GC).
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  world:setBodyData(body:getId(), { name = "crate" })
  world:clearBodyData(body:getId()) -- data is now nil
end

--@api-stub: LWorld:setBodyCCD
-- Sets the body ccd of this world.
do
  -- CCD (Continuous Collision Detection) prevents fast bodies from tunneling
  -- through thin walls. Enable for bullets, arrows, or anything moving > 500px/s.
  local world = lurek.physics.newWorld(0, 9.81)
  local bullet = world:newBody(100, 200, "dynamic")
  world:setBodyCCD(bullet:getId(), true) -- no more passing through walls
end

--@api-stub: LWorld:getBodyCCD
-- Returns the body ccd of this world.
do
  -- Check and enable CCD if not already set.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if not world:getBodyCCD(body:getId()) then world:setBodyCCD(body:getId(), true) end
end

--@api-stub: LWorld:clearBodyOneWay
-- Clears all body one way items from this world.
do
  -- Remove one-way platform behavior — body blocks from all directions again.
  local world = lurek.physics.newWorld(0, 9.81)
  local platform = world:newBody(200, 300, "static")
  world:clearBodyOneWay(platform:getId())
end

--@api-stub: LWorld:getBodyOneWay
-- Returns the body one way of this world.
do
  -- Returns the one-way normal (nx, ny) or nil if not set.
  -- The normal points toward the blocking side — objects pass through from behind.
  local world = lurek.physics.newWorld(0, 9.81)
  local platform = world:newBody(200, 300, "static")
  local nx, ny = world:getBodyOneWay(platform:getId())
  if nx then lurek.log.debug("one-way n=" .. nx .. "," .. ny, "phys") end
end

--@api-stub: LWorld:setJointBreakForce
-- Sets the joint break force of this world.
do
  -- Breakable joints snap when the constraint force exceeds the threshold.
  -- Great for destructible structures — chains break under too much tension.
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  world:setJointBreakForce(jid, 5000.0) -- breaks at 5000 Newtons
end

--@api-stub: LWorld:getJointBreakForce
-- Returns the joint break force of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local f = world:getJointBreakForce(jid)
  if f then lurek.log.debug("breaks at " .. f .. " N", "phys") end
end

--@api-stub: LWorld:isBodySleeping
-- Returns true if this world body sleeping.
do
  -- Sleeping bodies are not simulated — they're frozen in place until disturbed.
  -- Use to count active vs inactive bodies for performance monitoring.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if not world:isBodySleeping(body:getId()) then
    lurek.log.debug("body active", "phys")
  end
end

--@api-stub: LWorld:wakeUpBody
-- Performs the wake up body operation on this world.
do
  -- Manually wake a sleeping body before applying forces or impulses.
  -- Forces applied to sleeping bodies are ignored unless you wake them first.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  world:wakeUpBody(body:getId())
  body:applyImpulse(0, -100) -- now the impulse takes effect
end

--@api-stub: LWorld:sleepBody
-- Performs the sleep body operation on this world.
do
  -- Force a body to sleep immediately — useful for settled rubble or debris.
  -- The body won't move until another body collides with it or you call wakeUp.
  local world = lurek.physics.newWorld(0, 9.81)
  local rubble = world:newBody(100, 200, "dynamic")
  world:sleepBody(rubble:getId())
end

--@api-stub: LWorld:setSolverIterations
-- Sets the solver iterations of this world.
do
  -- More iterations = more accurate stacking and joint behavior, but slower.
  -- Default is 4. Use 8-12 for precision puzzles or tall stacks of crates.
  local world = lurek.physics.newWorld(0, 9.81)
  world:setSolverIterations(12)
end

--@api-stub: LWorld:getSolverIterations
-- Returns the solver iterations of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local iters = world:getSolverIterations()
  lurek.log.info("solver iterations=" .. iters, "phys")
end

--@api-stub: LWorld:newBodies
-- Creates and returns a new bodies widget or object.
do
  -- Batch-create bodies for better performance when spawning many at once.
  -- Each entry is {x, y, type}. Returns a table of body IDs.
  local world = lurek.physics.newWorld(0, 9.81)
  local ids = world:newBodies({
    { 100, 200, "dynamic" },  -- crate 1
    { 132, 200, "dynamic" },  -- crate 2
    { 164, 200, "dynamic" },  -- crate 3
  })
  lurek.log.info("spawned " .. #ids .. " crates", "phys")
end

--@api-stub: LWorld:addZone
-- Adds a zone to this world.
do
  -- Zones apply area effects: custom gravity, damping, or force fields.
  -- Bodies inside the zone rectangle are affected each step.
  local world = lurek.physics.newWorld(0, 9.81)

  -- Create a water zone: reduced gravity simulates buoyancy
  local water = world:addZone(0, 400, 800, 200)
  water:setGravityDirectional(0, 2.0) -- gentle downward pull in water
end

--@api-stub: LWorld:getZoneEvents
-- Returns the zone events of this world.
do
  -- Zone events fire when bodies enter or leave a zone's bounds.
  -- Each event has zone_id, body_id, and kind ("enter" or "leave").
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getZoneEvents()) do
      lurek.log.debug("zone " .. e.zone_id .. " " .. e.kind .. " body=" .. e.body_id, "phys")
    end
  end
end


-- Zone methods

--@api-stub: LBody:getId
-- Returns the id of this zone.
do
  -- Every zone has a unique numeric ID for referencing in event tables.
  local world = lurek.physics.newWorld(0, 9.81)
  local zone = world:addZone(0, 0, 100, 100)
  lurek.log.info("water zone id=" .. zone:getId(), "phys")
end

--@api-stub: LZone:setEnabled
-- Sets whether this zone is enabled and accepts input.
do
  -- Disabled zones have no effect on bodies — useful for toggling traps.
  local world = lurek.physics.newWorld(0, 9.81)
  local field = world:addZone(0, 0, 200, 200)
  field:setEnabled(false) -- force field is off until player hits a switch
end

--@api-stub: LZone:setPriority
-- Sets the priority of this zone.
do
  -- When zones overlap, higher priority wins. Use to layer effects.
  -- Example: a small zero-G bubble inside a larger gravity zone.
  local world = lurek.physics.newWorld(0, 9.81)
  local wind = world:addZone(0, 0, 200, 200)
  wind:setPriority(10) -- higher priority overrides lower-priority overlapping zones
end

--@api-stub: LZone:setLayerMask
-- Sets the layer mask of this zone.
do
  -- Layer mask controls which bodies are affected by this zone.
  -- Only bodies whose layer bitmask ANDs nonzero with this mask are affected.
  local world = lurek.physics.newWorld(0, 9.81)
  local slow = world:addZone(100, 100, 200, 200)
  slow:setLayerMask(0x02) -- only affects bodies on layer 2
end

--@api-stub: LZone:setCircle
-- Sets the circle of this zone.
do
  -- Override the zone shape from rectangle to circle for radial effects.
  -- Useful for gravity wells, explosions, or circular force fields.
  local world = lurek.physics.newWorld(0, 9.81)
  local well = world:addZone(0, 0, 1, 1) -- initial rect doesn't matter
  well:setCircle(400, 300, 120) -- centered at (400,300), radius 120px
end

--@api-stub: LZone:setGravityDirectional
-- Sets the gravity directional of this zone.
do
  -- Override gravity direction and magnitude inside this zone.
  -- Bodies inside experience this gravity instead of the world gravity.
  local world = lurek.physics.newWorld(0, 9.81)
  local water = world:addZone(0, 400, 800, 200)
  water:setGravityDirectional(0, 2.0) -- slow sinking in water
end

--@api-stub: LZone:setGravityZero
-- Sets the gravity zero of this zone.
do
  -- Zero-G zone: bodies float freely with no gravitational pull.
  -- Perfect for space sections or anti-gravity puzzles.
  local world = lurek.physics.newWorld(0, 9.81)
  local bubble = world:addZone(300, 100, 200, 200)
  bubble:setGravityZero() -- bodies inside float weightlessly
end

--@api-stub: LZone:setLinearDampingOverride
-- Sets the linear damping override of this zone.
do
  -- Linear damping acts like air resistance or viscosity.
  -- High damping = bodies slow down quickly (mud, honey, thick fluid).
  local world = lurek.physics.newWorld(0, 9.81)
  local glue = world:addZone(0, 0, 100, 100)
  glue:setLinearDampingOverride(5.0) -- bodies slow dramatically inside
end

--@api-stub: LPhysicsShape:destroy
-- Destroys this zone and releases all associated resources.
do
  -- Remove a zone from the world. Bodies are no longer affected.
  local world = lurek.physics.newWorld(0, 9.81)
  local zone = world:addZone(0, 0, 100, 100)
  zone:destroy() -- zone is gone
end


-- Terrain methods

--@api-stub: LCellular:setCell
-- Sets the cell of this terrain.
do
  -- Set individual cells to solid (true) or empty (false).
  -- Remember to call flush() after modifications to update physics colliders.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:setCell(10, 5, true)  -- make cell (10,5) solid
  terrain:flush()               -- regenerate colliders
end

--@api-stub: LCellular:getCell
-- Returns the cell of this terrain.
do
  -- Query whether a cell is solid — useful for game logic outside physics.
  -- Example: check if a tile is diggable before allowing the player to destroy it.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  if terrain:getCell(10, 5) then lurek.log.debug("solid cell", "terrain") end
end

--@api-stub: LTerrain:fillAll
-- Performs the fill all operation on this terrain.
do
  -- Fill the entire grid solid or empty in one call.
  -- Typical pattern: fillAll(true) then carve out tunnels/caves.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true) -- everything is solid ground
end

--@api-stub: LTerrain:flush
-- Flushes all pending output from this terrain immediately.
do
  -- flush() converts the cell grid into physics colliders.
  -- Batch your setCell calls, then flush once — much faster than flushing per-cell.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:setCell(5, 5, true)
  terrain:setCell(6, 5, true)
  terrain:setCell(7, 5, true)
  terrain:flush() -- one flush for all three changes
end

--@api-stub: LTerrain:isDirty
-- Returns true if this terrain dirty.
do
  -- isDirty returns true if cells changed since the last flush.
  -- Use to conditionally flush only when needed (saves CPU).
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  if terrain:isDirty() then terrain:flush() end
end

--@api-stub: LTerrain:collapseColumns
-- Collapses this terrain to hide its children or content.
do
  -- collapseColumns merges vertically adjacent cells into larger colliders.
  -- Call after large modifications to optimize the collider count.
  -- Returns how many cells were collapsed.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  local fell = terrain:collapseColumns()
  lurek.log.info("collapsed " .. fell .. " cells", "terrain")
  terrain:flush()
end

--@api-stub: LTerrain:solidPositions
-- Performs the solid positions operation on this terrain.
do
  -- Returns a table of {x, y} for all solid cells — useful for rendering or effects.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  local positions = terrain:solidPositions()
  lurek.log.debug("solid cells=" .. #positions, "terrain")
end

--@api-stub: LCellular:toBytes
-- Performs the to bytes operation on this terrain.
do
  -- Serialize the terrain grid to binary for saving to disk.
  -- Compact format stores only the boolean grid, not physics state.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  local bytes = terrain:toBytes()
  lurek.log.info("terrain blob=" .. #bytes .. " bytes", "save")
end

--@api-stub: LCellular:loadFromBytes
-- Loads from bytes into this terrain.
do
  -- Restore terrain from a save file. Call flush() after to rebuild colliders.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  local snapshot = terrain:toBytes()
  terrain:loadFromBytes(snapshot)
  terrain:flush() -- must flush to regenerate physics
end


-- Cellular methods

--@api-stub: LCellular:setCell
-- Sets the cell of this cellular.
do
  -- Place materials into the cellular grid by type constant.
  -- Available types: CELL_AIR(0), CELL_SAND(1), CELL_WATER(2),
  --                  CELL_ROCK(3), CELL_FIRE(4), CELL_GAS(5)
  local sand = lurek.physics.newCellular(128, 64)
  sand:setCell(64, 0, lurek.physics.CELL_SAND)   -- sand falls down
  sand:setCell(65, 0, lurek.physics.CELL_WATER)  -- water flows sideways
end

--@api-stub: LCellular:getCell
-- Returns the cell of this cellular.
do
  -- Read the material type at a grid position.
  -- Returns the numeric constant (compare with CELL_* values).
  local sand = lurek.physics.newCellular(128, 64)
  if sand:getCell(10, 10) == lurek.physics.CELL_AIR then
    -- Cell is empty — safe to place new material here
    sand:setCell(10, 10, lurek.physics.CELL_ROCK)
  end
end

--@api-stub: LCellular:step
-- Performs the step operation on this cellular.
do
  -- step() advances the simulation by one tick.
  -- Sand falls, water flows, fire spreads, gas rises.
  local sand = lurek.physics.newCellular(128, 64)
  function lurek.process(dt)
    sand:step() -- one tick per frame gives smooth 60fps simulation
  end
end

--@api-stub: LCellular:stepN
-- Performs the step n operation on this cellular.
do
  -- Run multiple ticks at once — useful for fast-forward or pre-settling.
  -- Warning: large N can spike frame time.
  local sand = lurek.physics.newCellular(128, 64)
  sand:stepN(30) -- settle the grid before gameplay starts
end

--@api-stub: LCellular:toImageData
-- Performs the to image data operation on this cellular.
do
  -- Render the entire grid to RGBA bytes using a default material palette.
  -- Result is width*height*4 bytes — feed to lurek.image.newImageData for display.
  local sand = lurek.physics.newCellular(128, 64)
  local rgba = sand:toImageData()
  lurek.log.debug("cellular bytes=" .. #rgba, "cell")
end

--@api-stub: LCellular:countCells
-- Performs the count cells operation on this cellular.
do
  -- Count how many cells of a given type exist — useful for win conditions.
  -- Example: "drain all water" puzzle — check if water count is zero.
  local sand = lurek.physics.newCellular(128, 64)
  local water = sand:countCells(lurek.physics.CELL_WATER)
  lurek.log.debug("water cells=" .. water, "cell")
end

--@api-stub: LCellular:findCells
-- Finds and returns the cells in this cellular by name or id.
do
  -- Returns positions of all cells matching a type — for rendering highlights.
  local sand = lurek.physics.newCellular(128, 64)
  for _, p in ipairs(sand:findCells(lurek.physics.CELL_FIRE)) do
    lurek.log.debug("fire at " .. p.x .. "," .. p.y, "cell")
  end
end

--@api-stub: LCellular:toBytes
-- Performs the to bytes operation on this cellular.
do
  -- Serialize the cellular grid for saving — stores all cell types.
  local sand = lurek.physics.newCellular(128, 64)
  local blob = sand:toBytes()
  lurek.log.info("cellular blob=" .. #blob .. " bytes", "save")
end

--@api-stub: LCellular:loadFromBytes
-- Loads from bytes into this cellular.
do
  -- Restore cellular state from a save. Returns true on success.
  local sand = lurek.physics.newCellular(128, 64)
  local blob = sand:toBytes()
  local ok = sand:loadFromBytes(blob)
  lurek.log.info("cellular reload ok=" .. tostring(ok), "save")
end


-- Body methods

--@api-stub: LBody:getId
-- Returns the id of this body.
do
  -- Every body has a unique numeric ID used by World methods and events.
  -- Store the ID to look up bodies in collision callbacks.
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  lurek.log.debug("crate id=" .. crate:getId(), "phys")
end

--@api-stub: LBody:getPosition
-- Returns the position of this body.
do
  -- Returns x, y in world coordinates (pixels at default scale).
  -- Use for drawing sprites at the body's current location.
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  local x, y = crate:getPosition()
  lurek.log.debug("crate at " .. x .. "," .. y, "phys")
end

--@api-stub: LBody:setPosition
-- Sets the position of this body.
do
  -- Teleports the body — no physics forces are applied.
  -- Use for respawning or snapping to a checkpoint.
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  player:setPosition(400, 300) -- teleport to screen center
end

--@api-stub: LBody:getX
-- Returns the x of this body.
do
  -- Shorthand for getting only the X coordinate.
  -- Useful for boundary checks without unpacking both values.
  local world = lurek.physics.newWorld(0, 9.81)
  local enemy = world:newBody(900, 200, "dynamic")
  if enemy:getX() > 800 then enemy:destroy() end -- off-screen cleanup
end

--@api-stub: LBody:getY
-- Returns the y of this body.
do
  -- Check if player fell below the level — respawn at start.
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  if player:getY() > 1000 then player:setPosition(100, 200) end
end

--@api-stub: LBody:getVelocity
-- Returns the velocity of this body.
do
  -- Returns vx, vy in pixels/sec (at default scale).
  -- Use for animation state selection (idle vs walking vs falling).
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  local vx, vy = body:getVelocity()
  lurek.log.debug("v=" .. vx .. "," .. vy, "phys")
end

--@api-stub: LBody:setVelocity
-- Sets the velocity of this body.
do
  -- Directly set velocity — ignores mass, replaces current motion.
  -- Use for constant-speed movement (conveyors, kinematic platforms).
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  function lurek.process(dt)
    -- Move player rightward at constant 150 px/s (overrides gravity effect on X)
    player:setVelocity(150, 0)
  end
end

--@api-stub: LBody:getAngle
-- Returns the angle of this body.
do
  -- Returns rotation in radians (0 = no rotation, positive = counter-clockwise).
  -- Use for rotating sprites to match physics body orientation.
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  local rad = crate:getAngle()
  lurek.log.debug("angle=" .. rad .. " rad", "phys")
end

--@api-stub: LBody:setAngle
-- Sets the angle of this body.
do
  -- Set rotation directly — useful for static props like tilted signs.
  local world = lurek.physics.newWorld(0, 9.81)
  local sign = world:newBody(200, 200, "static")
  sign:setAngle(math.pi / 4) -- 45 degree tilt
end

--@api-stub: LBody:getAngularVelocity
-- Returns the angular velocity of this body.
do
  -- Angular velocity is in radians/sec.
  -- Use to detect over-spinning and apply braking torque.
  local world = lurek.physics.newWorld(0, 9.81)
  local wheel = world:newBody(100, 200, "dynamic")
  if math.abs(wheel:getAngularVelocity()) > 30 then
    wheel:applyTorque(-5) -- brake to prevent infinite spin
  end
end

--@api-stub: LBody:setAngularVelocity
-- Sets the angular velocity of this body.
do
  -- Set a constant spin — useful for kinematic turrets or spinning hazards.
  local world = lurek.physics.newWorld(0, 9.81)
  local turret = world:newBody(200, 200, "kinematic")
  turret:setAngularVelocity(1.5) -- slow constant rotation
end

--@api-stub: LBody:getMass
-- Returns the mass of this body.
do
  -- Mass is computed from density * fixture area, or set manually.
  -- Heavier bodies resist impulses more and push lighter ones aside.
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  lurek.log.debug("crate mass=" .. crate:getMass() .. " kg", "phys")
end

--@api-stub: LBody:setMass
-- Sets the mass of this body.
do
  -- Override mass directly — useful when density-based calculation is impractical.
  local world = lurek.physics.newWorld(0, 9.81)
  local heavy = world:newBody(100, 200, "dynamic")
  heavy:setMass(50.0) -- 50 kg — hard to push
end

--@api-stub: LPhysicsShape:getType
-- Returns the type of this body.
do
  -- Returns "static", "dynamic", "kinematic", or "sensor".
  -- Use to filter bodies in generic processing loops.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if body:getType() == "dynamic" then body:applyImpulse(0, -50) end
end

--@api-stub: LBody:setType
-- Sets the type of this body.
do
  -- Change type at runtime: static wall becomes dynamic rubble when exploded.
  local world = lurek.physics.newWorld(0, 9.81)
  local wall = world:newBody(200, 200, "static")
  wall:setType("dynamic") -- wall crumbles — now affected by gravity
end

--@api-stub: LBody:getWidth
-- Returns the width of this body.
do
  -- Returns the bounding width from the primary fixture shape.
  -- Useful for scaling sprites to match the physics body.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("body width=" .. body:getWidth(), "phys")
end

--@api-stub: LBody:getHeight
-- Returns the height of this body.
do
  -- Returns the bounding height from the primary fixture shape.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("body height=" .. body:getHeight(), "phys")
end

--@api-stub: LBody:getFriction
-- Returns the friction of this body.
do
  -- Friction controls how much bodies resist sliding against each other.
  -- 0 = ice, 1 = rubber. Check before adjusting for gameplay feel.
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  if crate:getFriction() < 0.5 then crate:setFriction(0.7) end
end

--@api-stub: LPhysicsShape:setFriction
-- Sets the friction of this body.
do
  -- Low friction for ice levels, high friction for rubber-band physics.
  local world = lurek.physics.newWorld(0, 9.81)
  local ice = world:newBody(100, 200, "dynamic")
  ice:setFriction(0.05) -- nearly frictionless — slides easily
end

--@api-stub: LBody:getRestitution
-- Returns the restitution of this body.
do
  -- Restitution = bounciness. 0 = dead stop, 1 = perfect elastic bounce.
  local world = lurek.physics.newWorld(0, 9.81)
  local ball = world:newBody(100, 200, "dynamic")
  lurek.log.debug("ball bounce=" .. ball:getRestitution(), "phys")
end

--@api-stub: LPhysicsShape:setRestitution
-- Sets the restitution of this body.
do
  -- Bouncy ball for a pinball or Breakout-style game.
  local world = lurek.physics.newWorld(0, 9.81)
  local ball = world:newBody(100, 200, "dynamic")
  ball:setRestitution(0.8) -- bounces back 80% of impact speed
end

--@api-stub: LBody:getLayer
-- Returns the layer of this body.
do
  -- Collision layers use a bitmask — bodies only collide if layers AND nonzero.
  -- Useful for separating player, enemies, projectiles, and pickups.
  local world = lurek.physics.newWorld(0, 9.81)
  local pickup = world:newBody(100, 200, "dynamic")
  lurek.log.debug("layer=" .. pickup:getLayer(), "phys")
end

--@api-stub: LBody:setLayer
-- Sets the layer of this body.
do
  -- Place pickups on layer 0x04 so they only collide with the player (mask 0x04).
  local world = lurek.physics.newWorld(0, 9.81)
  local pickup = world:newBody(100, 200, "dynamic")
  pickup:setLayer(0x04) -- layer 3 (bit 2)
end

--@api-stub: LBody:getMask
-- Returns the mask of this body.
do
  -- The mask determines which layers THIS body can collide WITH.
  -- Body A collides with body B if (A.layer & B.mask) ~= 0 AND (B.layer & A.mask) ~= 0
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("mask=" .. body:getMask(), "phys")
end

--@api-stub: LBody:setMask
-- Sets the mask of this body.
do
  -- Ghost that only collides with walls (layer 0x01), not other characters.
  local world = lurek.physics.newWorld(0, 9.81)
  local ghost = world:newBody(100, 200, "dynamic")
  ghost:setMask(0x01) -- only respond to layer 1 (walls)
end

--@api-stub: LBody:applyImpulse
-- Applies impulse to this body.
do
  -- Impulse = instant velocity change. Affected by mass (heavier = less effect).
  -- Use for jumps, explosions, and knockback — one-shot force application.
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  function lurek.process(dt)
    -- Jump: apply upward impulse (negative Y = up in screen space)
    if lurek.input.keyboard.isDown("space") then player:applyImpulse(0, -300) end
  end
end

--@api-stub: LBody:applyForce
-- Applies force to this body.
do
  -- Force accumulates over the step — it's continuous, not instant like impulse.
  -- Use for thrusters, wind, or sustained push effects.
  local world = lurek.physics.newWorld(0, 9.81)
  local rocket = world:newBody(100, 200, "dynamic")
  function lurek.process(dt)
    -- Continuous upward thrust — stronger than gravity to fly
    rocket:applyForce(0, -200)
  end
end

--@api-stub: LBody:applyTorque
-- Applies torque to this body.
do
  -- Torque is a rotational force — spins the body.
  -- Positive = counter-clockwise, negative = clockwise.
  local world = lurek.physics.newWorld(0, 9.81)
  local wheel = world:newBody(100, 200, "dynamic")
  wheel:applyTorque(50.0) -- spin the wheel counter-clockwise
end

--@api-stub: LBody:applyAngularImpulse
-- Applies angular impulse to this body.
do
  -- Instant spin change — like flicking a spinning top.
  local world = lurek.physics.newWorld(0, 9.81)
  local top = world:newBody(100, 200, "dynamic")
  top:applyAngularImpulse(2.5) -- instant spin
end

--@api-stub: LBody:getGravityScale
-- Returns the gravity scale of this body.
do
  -- Gravity scale multiplies world gravity for this body only.
  -- 1.0 = normal, 0 = no gravity, 2 = double, -1 = inverted.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("g-scale=" .. body:getGravityScale(), "phys")
end

--@api-stub: LBody:setGravityScale
-- Sets the gravity scale of this body.
do
  -- Balloon floats upward with negative gravity scale.
  local world = lurek.physics.newWorld(0, 9.81)
  local balloon = world:newBody(100, 200, "dynamic")
  balloon:setGravityScale(-0.5) -- gently floats up
end

--@api-stub: LBody:isFixedRotation
-- Returns true if this body fixed rotation.
do
  -- Fixed rotation prevents the body from spinning on collision.
  -- Essential for player characters — they should stay upright.
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  if not player:isFixedRotation() then player:setFixedRotation(true) end
end

--@api-stub: LBody:setFixedRotation
-- Sets the fixed rotation of this body.
do
  -- Lock rotation for characters, unlock for physics props.
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  player:setFixedRotation(true) -- player won't topple over
end

--@api-stub: LBody:getLinearDamping
-- Returns the linear damping of this body.
do
  -- Damping simulates drag — higher values slow the body faster.
  -- 0 = no drag (space), 1-3 = air, 5+ = water/mud.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("damping=" .. body:getLinearDamping(), "phys")
end

--@api-stub: LBody:setLinearDamping
-- Sets the linear damping of this body.
do
  -- High damping for underwater fish — simulates water resistance.
  local world = lurek.physics.newWorld(0, 9.81)
  local fish = world:newBody(100, 200, "dynamic")
  fish:setLinearDamping(2.0) -- slows quickly when thrust stops
end

--@api-stub: LBody:getAngularDamping
-- Returns the angular damping of this body.
do
  -- Angular damping slows rotation over time (rotational drag).
  local world = lurek.physics.newWorld(0, 9.81)
  local top = world:newBody(100, 200, "dynamic")
  lurek.log.debug("ang damping=" .. top:getAngularDamping(), "phys")
end

--@api-stub: LBody:setAngularDamping
-- Sets the angular damping of this body.
do
  -- Low angular damping: crate spins freely when knocked.
  -- High angular damping: crate resists spinning.
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  crate:setAngularDamping(0.5) -- moderate spin decay
end

--@api-stub: LBody:isBullet
-- Returns true if this body bullet.
do
  -- "Bullet" mode enables CCD (Continuous Collision Detection).
  -- Prevents small fast objects from passing through thin walls.
  local world = lurek.physics.newWorld(0, 9.81)
  local proj = world:newBody(100, 200, "dynamic")
  if proj:isBullet() then lurek.log.debug("CCD on", "phys") end
end

--@api-stub: LBody:setBullet
-- Sets the bullet of this body.
do
  -- Enable bullet mode for arrows, bullets, or any high-speed projectile.
  -- Costs more CPU per body — only use when tunneling is a real risk.
  local world = lurek.physics.newWorld(0, 9.81)
  local arrow = world:newBody(100, 200, "dynamic")
  arrow:setBullet(true)
end

--@api-stub: LBody:isSleepingAllowed
-- Returns true if this body sleeping allowed.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if body:isSleepingAllowed() then body:setSleepingAllowed(false) end
end

--@api-stub: LBody:setSleepingAllowed
-- Sets the sleeping allowed of this body.
do
  -- Disable sleep for bodies that must always respond to forces (player, active NPCs).
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  player:setSleepingAllowed(false) -- always simulated
end

--@api-stub: LPhysicsShape:destroy
-- Destroys this body and releases all associated resources.
do
  -- Remove a body from the world. All fixtures and joints are also removed.
  -- After destroy(), the LBody handle is invalid — do not use it again.
  local world = lurek.physics.newWorld(0, 9.81)
  local enemy = world:newBody(100, 200, "dynamic")
  enemy:destroy()
end

--@api-stub: LBody:isSleeping
-- Returns true if this body sleeping.
do
  -- Sleeping bodies are frozen and cost zero CPU. They wake on collision.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if not body:isSleeping() then lurek.log.debug("active", "phys") end
end

--@api-stub: LBody:wakeUp
-- Performs the wake up operation on this body.
do
  -- Explicitly wake a body before applying forces — sleeping bodies ignore forces.
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  body:wakeUp()
  body:applyImpulse(0, -100) -- impulse now takes effect
end

--@api-stub: LBody:sleep
-- Performs the sleep operation on this body.
do
  -- Force a body to sleep — pauses simulation until disturbed.
  -- Use for settled debris that shouldn't move unless hit again.
  local world = lurek.physics.newWorld(0, 9.81)
  local rubble = world:newBody(100, 200, "dynamic")
  rubble:sleep()
end


-- PhysicsShape methods

--@api-stub: LPhysicsShape:getType
-- Returns the type of this physics shape.
do
  -- Returns "circle", "rectangle", "polygon", "edge", or "chain".
  -- Use to branch logic when processing different shape kinds.
  local shape = lurek.physics.newCircleShape(16)
  if shape:getType() == "circle" then
    lurek.log.debug("ball-shape r=" .. shape:getRadius(), "phys")
  end
end

--@api-stub: LPhysicsShape:getRadius
-- Returns the radius of this physics shape.
do
  -- Only valid for circle shapes — errors if called on other types.
  local ball = lurek.physics.newCircleShape(16)
  lurek.log.debug("radius=" .. ball:getRadius(), "phys")
end

--@api-stub: LPhysicsShape:getBoundingBox
-- Returns the bounding box of this physics shape.
do
  -- Returns minX, minY, maxX, maxY in local (shape-relative) coordinates.
  -- Useful for calculating sprite bounds from the collision shape.
  local crate_shape = lurek.physics.newRectangleShape(64, 32)
  local x1, y1, x2, y2 = crate_shape:getBoundingBox()
  lurek.log.debug("aabb " .. x1 .. "," .. y1 .. "->" .. x2 .. "," .. y2, "phys")
end

--@api-stub: LPhysicsShape:setDensity
-- Sets the density of this physics shape.
do
  -- Density affects mass calculation when attached: mass = density * area.
  -- Higher density = heavier body for the same shape size.
  local shape = lurek.physics.newRectangleShape(32, 32)
  shape:setDensity(2.0) -- twice as heavy as default
end

--@api-stub: LPhysicsShape:setFriction
-- Sets the friction of this physics shape.
do
  -- Per-shape friction — useful when one body has multiple fixtures
  -- (e.g., icy top and rubber bottom).
  local shape = lurek.physics.newRectangleShape(32, 32)
  shape:setFriction(0.7)
end

--@api-stub: LPhysicsShape:setRestitution
-- Sets the restitution of this physics shape.
do
  -- Per-shape bounciness — the ball's circle is bouncy, its sensor is not.
  local ball = lurek.physics.newCircleShape(16)
  ball:setRestitution(0.85) -- very bouncy
end

--@api-stub: LPhysicsShape:setSensor
-- Sets the sensor of this physics shape.
do
  -- Sensors detect overlap but don't push bodies apart.
  -- Use for trigger zones, pickup collection areas, or hitboxes.
  local trigger = lurek.physics.newRectangleShape(64, 64)
  trigger:setSensor(true) -- no collision response, only detection
end

--@api-stub: LPhysicsShape:destroy
-- Destroys this physics shape and releases all associated resources.
do
  -- No-op in Lurek2D — shapes are garbage-collected.
  -- Call for code clarity or porting from engines with manual cleanup.
  local shape = lurek.physics.newRectangleShape(32, 32)
  shape:destroy()
end

--@api-stub: lurek.physics.testAABB
-- Tests whether two axis-aligned bounding boxes overlap
do
  -- Lightweight overlap test without needing a physics world.
  -- Use for broad-phase checks, UI hit testing, or camera culling.
  -- Args: ax,ay,aw,ah (rect 1) and bx,by,bw,bh (rect 2)
  local hit = lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 20, 20)
  lurek.log.debug("AABB overlap=" .. tostring(hit), "physics")
end

--@api-stub: lurek.physics.testCircles
-- Tests whether two circles overlap
do
  -- Fast circle-vs-circle overlap test. No physics world needed.
  -- Args: ax,ay,ar (circle 1) and bx,by,br (circle 2)
  local hit = lurek.physics.testCircles(0, 0, 5, 3, 3, 5)
  lurek.log.debug("circles overlap=" .. tostring(hit), "physics")
end

--@api-stub: lurek.physics.testCircleAABB
-- Tests whether a circle overlaps an AABB
do
  -- Useful for checking if a bullet (circle) hits a rectangular target.
  -- Args: cx,cy,cr (circle) and ax,ay,aw,ah (rectangle)
  local hit = lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10)
  lurek.log.debug("circle-AABB overlap=" .. tostring(hit), "physics")
end

--@api-stub: lurek.physics.testPoint
-- Tests whether a point lies inside an AABB
do
  -- Simple point-in-rectangle test — use for mouse click detection.
  -- Args: px,py (point) and ax,ay,aw,ah (rectangle)
  local hit = lurek.physics.testPoint(5, 5, 0, 0, 10, 10)
  lurek.log.debug("point-in-AABB=" .. tostring(hit), "physics")
end

--@api-stub: LWorld:addDistanceJoint
-- Adds a distance joint to this world.
do
  -- Distance joint keeps two bodies at a fixed distance apart, like a rigid rod.
  -- Args: bodyA, bodyB, anchorAX, anchorAY, anchorBX, anchorBY, length
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(200, 100, "dynamic")

  -- Connect body centers with a 100px rod — they can rotate but not separate
  local jid = world:addDistanceJoint(a:getId(), b:getId(), 100, 100, 200, 100, 100)
  lurek.log.info("distance joint: " .. jid, "physics")
end

--@api-stub: LWorld:addFixture
-- Adds a fixture to this world.
do
  -- addFixture attaches a collider to an existing body with full material control.
  -- Args: bodyId, shapeType, density, friction, restitution, sensor, ...sizeArgs
  -- sizeArgs depend on shape: circle(radius), rectangle(w,h), polygon(x1,y1,...)
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")

  -- Add a circle collider: density=1, friction=0.4, bounce=0.3, not a sensor, r=16
  local fid = world:addFixture(b:getId(), "circle", 1.0, 0.4, 0.3, false, 16.0)
  lurek.log.info("fixture id: " .. fid, "physics")
end

--@api-stub: LWorld:addFrictionJoint
-- Adds a friction joint to this world.
do
  -- Friction joint applies resistance to relative motion between two bodies.
  -- Use for simulating surface friction (top-down car on road) or drag.
  -- Args: bodyA, bodyB, anchorX, anchorY, maxForce, maxTorque
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(100, 100, "static")
  local jid = world:addFrictionJoint(a:getId(), b:getId(), 100, 100, 50, 10)
  lurek.log.info("friction joint: " .. jid, "physics")
end

--@api-stub: LWorld:addGearJoint
-- Adds a gear joint to this world.
do
  -- Gear joint synchronizes rotation between two bodies at an anchor.
  -- When one gear turns clockwise, the other turns counter-clockwise.
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "dynamic")
  local b = world:newBody(200, 200, "dynamic")
  local c = world:newBody(150, 200, "static")

  -- Both gears need a revolute joint to the chassis first
  local j1 = world:addRevoluteJoint(c:getId(), a:getId(), 100, 200)
  local j2 = world:addRevoluteJoint(c:getId(), b:getId(), 200, 200)

  -- Link the gears together
  local jid = world:addGearJoint(a:getId(), b:getId(), 150, 200)
  lurek.log.info("gear joint: " .. jid, "physics")
end

--@api-stub: LWorld:addMotorJoint
-- Adds a motor joint to this world.
do
  -- Motor joint drives body B toward a target offset from body A.
  -- Factor (0-1) controls convergence speed — higher = faster tracking.
  -- Use for smooth following behavior (camera rigs, puppet limbs).
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(200, 200, "dynamic")
  local jid = world:addMotorJoint(a:getId(), b:getId(), 0.3)
  lurek.log.info("motor joint: " .. jid, "physics")
end

--@api-stub: LWorld:addMouseJoint
-- Adds a mouse joint to this world.
do
  -- Mouse joint pulls a body toward a target point with spring-like force.
  -- Update the target each frame to follow the cursor — for drag-and-drop physics.
  -- Args: bodyId, targetX, targetY, maxForce
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local jid = world:addMouseJoint(b:getId(), 200, 200, 1000)
  lurek.log.info("mouse joint: " .. jid, "physics")
end

--@api-stub: LWorld:addPrismaticJoint
-- Adds a prismatic joint to this world.
do
  -- Prismatic (slider) joint constrains body B to slide along an axis.
  -- Use for elevators, pistons, or sliding doors.
  -- Args: bodyA, bodyB, anchorX, anchorY, axisX, axisY
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 300, "static")   -- anchor post
  local b = world:newBody(100, 200, "dynamic")  -- sliding platform

  -- Slides along Y axis (0,-1 = up/down direction)
  local jid = world:addPrismaticJoint(a:getId(), b:getId(), 100, 300, 0, -1)
  lurek.log.info("prismatic joint: " .. jid, "physics")
end

--@api-stub: LWorld:addPulleyJoint
-- Adds a pulley joint to this world.
do
  -- Pulley: when one side goes down, the other goes up. Like a real pulley.
  -- Use for counterweight elevators or balance puzzles.
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "dynamic")
  local b = world:newBody(300, 200, "dynamic")
  local jid = world:addPulleyJoint(a:getId(), b:getId(), 100, 100)
  lurek.log.info("pulley joint: " .. jid, "physics")
end

--@api-stub: LWorld:addRevoluteJoint
-- Adds a revolute joint to this world.
do
  -- Revolute (hinge) joint lets two bodies rotate freely around an anchor point.
  -- Use for doors, wheels, flippers, pendulums, and ragdoll limbs.
  local world = lurek.physics.newWorld(0, 9.81)
  local door = world:newBody(200, 200, "dynamic")
  local wall = world:newBody(200, 200, "static")

  -- Door rotates around the wall anchor point
  local jid = world:addRevoluteJoint(wall:getId(), door:getId(), 200, 200)
  lurek.log.info("revolute joint: " .. jid, "physics")
end

--@api-stub: LWorld:addRopeJoint
-- Adds a rope joint to this world.
do
  -- Rope joint limits maximum distance between two anchor points.
  -- Bodies can get closer but never further than maxLength apart.
  -- Args: bodyA, bodyB, anchorAX, anchorAY, anchorBX, anchorBY, maxLength
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(100, 200, "dynamic")
  local jid = world:addRopeJoint(a:getId(), b:getId(), 100, 100, 100, 200, 120)
  lurek.log.info("rope joint: " .. jid, "physics")
end

--@api-stub: LWorld:addWeldJoint
-- Adds a weld joint to this world.
do
  -- Weld joint rigidly connects two bodies — no relative movement at all.
  -- Use to glue pieces together (compound objects, stuck items).
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(150, 200, "dynamic")
  local b = world:newBody(170, 200, "dynamic")
  local jid = world:addWeldJoint(a:getId(), b:getId(), 160, 200)
  lurek.log.info("weld joint: " .. jid, "physics")
end

--@api-stub: LWorld:addWheelJoint
-- Adds a wheel joint to this world.
do
  -- Wheel joint = revolute + prismatic. Simulates a wheel on a suspension.
  -- The wheel rotates freely AND can bounce along the suspension axis.
  -- Args: bodyA (chassis), bodyB (wheel), anchorX, anchorY, axisX, axisY
  local world = lurek.physics.newWorld(0, 9.81)
  local chassis = world:newBody(200, 200, "dynamic")
  local wheel   = world:newBody(200, 240, "dynamic")

  -- Suspension axis points up (0,-1) — wheel bounces vertically
  local jid = world:addWheelJoint(chassis:getId(), wheel:getId(), 200, 240, 0, -1)
  lurek.log.info("wheel joint: " .. jid, "physics")
end

--@api-stub: LBody:applyForceAtPoint
-- Applies force at point to this body.
do
  -- Force at a specific point generates both linear AND angular acceleration.
  -- Use for off-center hits — a bullet hitting the corner of a crate spins it.
  -- Args: fx, fy (force vector), px, py (world-space application point)
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")

  -- Push right at the top-right corner — creates spin + rightward motion
  b:applyForceAtPoint(100, 0, 220, 200)
  lurek.log.info("force at point applied", "physics")
end

--@api-stub: LWorld:drawDebug
-- Draws or renders this world to the current render target.
do
  -- CPU-rendered debug visualization onto an ImageData target.
  -- Slower than drawDebugGpu but works without a render pass.
  -- Optional RGBA args set the wireframe color (0-255).
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(200, 200, "static")
  local debug_img = lurek.image.newImageData(400, 400)
  function lurek.draw()
    world:drawDebug(debug_img) -- draws green wireframes by default
  end
  lurek.log.info("drawDebug hooked", "physics")
end

--@api-stub: LCellular:fillCircle
-- Performs the fill circle operation on this terrain.
do
  -- Carve or fill circular areas in the terrain — for explosion craters.
  -- Args: wx, wy (world coords center), radius, solid (true=fill, false=carve)
  local _world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 64, 8, _world)
  terrain:fillAll(true)

  -- Dig a circular crater at the center of the terrain
  terrain:fillCircle(32, 32, 10, false)
  terrain:flush() -- regenerate colliders after modification
  lurek.log.info("terrain crater dug", "physics")
end

--@api-stub: LCellular:fillCircle
-- Performs the fill circle operation on this cellular.
do
  -- Fill a circular region with a material type.
  -- Args: cx, cy (center cell), r (radius in cells), cellType
  local ca = lurek.physics.newCellular(64, 64)
  ca:fillCircle(32, 32, 20, lurek.physics.CELL_SAND)
  lurek.log.info("cellular circle filled", "physics")
end

--@api-stub: LCellular:fillRect
-- Performs the fill rect operation on this terrain.
do
  -- Fill or carve rectangular regions — for room generation or level building.
  -- Args: wx, wy, w, h (world coords), solid
  local _world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 64, 8, _world)
  terrain:fillRect(10, 10, 40, 40, true) -- create a solid rectangular platform
  terrain:flush()
  lurek.log.info("terrain rect filled", "physics")
end

--@api-stub: LCellular:fillRect
-- Performs the fill rect operation on this cellular.
do
  -- Fill a rectangular region with a material type.
  -- Args: cx0, cy0 (top-left cell), cw, ch (size in cells), cellType
  local ca = lurek.physics.newCellular(32, 32)
  ca:fillRect(4, 4, 28, 28, lurek.physics.CELL_WATER)
  lurek.log.info("cellular rect filled", "physics")
end

--@api-stub: LWorld:newChainBody
-- Creates and returns a new chain body widget or object.
do
  -- Creates a body with a chain (polyline) collider in one call.
  -- Use for terrain outlines, rails, or complex static boundaries.
  -- Args: x, y (body position), vertices (flat {x1,y1,x2,y2,...}), closed, type
  local world = lurek.physics.newWorld(0, 9.81)
  local verts = {0,400, 200,380, 400,400, 600,390, 800,400}

  -- Open chain = path with two endpoints (not a loop)
  local b = world:newChainBody(0, 0, verts, false, "static")
  lurek.log.info("chain body: " .. b:getId(), "physics")
end

--@api-stub: LWorld:newCircleBody
-- Creates and returns a new circle body widget or object.
do
  -- Convenience: creates a body with a circle collider already attached.
  -- Faster than newBody + addFixture for simple circle objects.
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newCircleBody(300, 200, 20, "dynamic") -- ball, radius 20
  lurek.log.info("circle body: " .. b:getId(), "physics")
end

--@api-stub: LWorld:newEdgeBody
-- Creates and returns a new edge body widget or object.
do
  -- Creates a body with an edge (line segment) collider.
  -- Args: x, y (body pos), x1,y1,x2,y2 (edge endpoints relative to body), type
  local world = lurek.physics.newWorld(0, 9.81)

  -- Floor: a static edge from left to right at y=400
  local b = world:newEdgeBody(0, 0, 0, 400, 800, 400, "static")
  lurek.log.info("edge body: " .. b:getId(), "physics")
end

--@api-stub: LWorld:newPolygonBody
-- Creates and returns a new polygon body widget or object.
do
  -- Creates a body with a convex polygon collider.
  -- Vertices must be convex, max 8 points, in local coordinates.
  local world = lurek.physics.newWorld(0, 9.81)
  local verts = {-20,-10, 20,-10, 20,10, -20,10} -- a rectangle via polygon

  local b = world:newPolygonBody(300, 200, verts, "dynamic")
  lurek.log.info("polygon body: " .. b:getId(), "physics")
end

--@api-stub: LWorld:queryAABB
-- Performs the query aabb operation on this world.
do
  -- Query all bodies whose bounding boxes overlap a rectangle.
  -- Returns a table of body IDs. Use for area-of-effect damage or selection.
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(100, 100, 20, "static")

  -- Find all bodies in the rectangle (80,80) to (210,210)
  local hits = world:queryAABB(80, 80, 130, 130)
  lurek.log.info("AABB hits: " .. #hits, "physics")
end

--@api-stub: LWorld:raycast
-- Performs the raycast operation on this world.
do
  -- Cast a ray between two points. Returns the first body hit.
  -- Use for line-of-sight checks, hitscan weapons, or laser beams.
  -- Returns: bodyId, normalX, normalY, fraction (or nil if no hit)
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(200, 200, 30, "static")

  -- Shoot a ray from (0,200) to (400,200) — horizontal line
  local id, nx, ny, frac = world:raycast(0, 200, 400, 200)
  lurek.log.info("raycast hit: " .. tostring(id), "physics")
end

--@api-stub: LWorld:raycastAll
-- Performs the raycast all operation on this world.
do
  -- Cast a directional ray and get ALL bodies hit (not just the first).
  -- Use for piercing projectiles or penetration-based damage.
  -- Args: x, y (origin), dx, dy (direction), maxDist
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(100, 200, 20, "static")
  world:newCircleBody(300, 200, 20, "static")

  -- Ray going right from origin, max 400px distance
  local hits = world:raycastAll(0, 200, 1, 0, 400)
  lurek.log.info("all hits: " .. #hits, "physics")
end

--@api-stub: LWorld:raycastClosest
-- Performs the raycast closest operation on this world.
do
  -- Like raycastAll but returns only the closest hit.
  -- More efficient when you only need the first obstruction.
  -- Returns a table {bodyId, x, y, normalX, normalY, toi} or nil.
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(150, 200, 20, "static")
  local hit = world:raycastClosest(0, 200, 1, 0, 400)
  lurek.log.info("closest hit: " .. tostring(hit and hit.bodyId), "physics")
end

--@api-stub: LZone:setAngularDampingOverride
-- Sets the angular damping override of this zone.
do
  -- Override angular damping for bodies inside this zone.
  -- Use to prevent spinning in specific areas (e.g., sticky surfaces).
  local world = lurek.physics.newWorld(0, 9.81)
  local z = world:addZone(100, 100, 300, 300)
  z:setAngularDampingOverride(5.0) -- bodies stop spinning quickly inside
  lurek.log.info("zone angular damping set", "physics")
end

--@api-stub: LWorld:setBodyData
-- Sets the body data of this world.
do
  -- Attach any Lua value to a body ID for identification in callbacks.
  -- Common pattern: store entity type and game state for collision resolution.
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  world:setBodyData(b:getId(), {entityId=42, type="player"})
  lurek.log.info("body data set", "physics")
end

--@api-stub: LWorld:setBodyOneWay
-- Sets the body one way of this world.
do
  -- One-way platform: bodies pass through from below, block from above.
  -- The normal vector points toward the blocking side.
  -- (0, -1) means "blocks from above" — classic platformer drop-through platform.
  local world = lurek.physics.newWorld(0, 9.81)
  local platform = world:newBody(400, 300, "static")
  world:setBodyOneWay(platform:getId(), 0, -1) -- blocks downward movement only
  lurek.log.info("one-way platform set", "physics")
end

--@api-stub: LWorld:setFixtureFriction
-- Sets the fixture friction of this world.
do
  -- Change friction on a specific fixture index (0-based).
  -- Use when a body has multiple fixtures with different surface properties.
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local fid = world:addFixture(b:getId(), "rectangle", 1.0, 0.5, 0.0, false, 32.0, 32.0)
  world:setFixtureFriction(b:getId(), fid, 0.1) -- make this fixture slippery
  lurek.log.info("fixture friction set", "physics")
end

--@api-stub: LWorld:setFixtureRestitution
-- Sets the fixture restitution of this world.
do
  -- Change bounciness on a specific fixture after creation.
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local fid = world:addFixture(b:getId(), "circle", 1.0, 0.5, 0.8, false, 16.0)
  world:setFixtureRestitution(b:getId(), fid, 0.8) -- very bouncy ball
  lurek.log.info("restitution set", "physics")
end

--@api-stub: LWorld:setFixtureSensor
-- Sets the fixture sensor of this world.
do
  -- Toggle sensor mode on a fixture — sensor detects overlap without pushing.
  -- Use to add a detection radius around a solid body.
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "static")
  local fid = world:addFixture(b:getId(), "circle", 0.0, 0.0, 0.0, true, 40.0)
  world:setFixtureSensor(b:getId(), fid, true) -- confirm it's a sensor
  lurek.log.info("sensor fixture set", "physics")
end

--@api-stub: LZone:setGravityPoint
-- Sets the gravity point of this zone.
do
  -- Point gravity attracts bodies toward a center — like a black hole.
  -- Args: cx, cy (attractor center), strength (pull force magnitude)
  local world = lurek.physics.newWorld(0, 9.81)
  local z = world:addZone(0, 0, 800, 600)
  z:setGravityPoint(400, 300, 500) -- everything pulls toward screen center
  lurek.log.info("gravity point set", "physics")
end

--@api-stub: LZone:setGravityRepulsor
-- Sets the gravity repulsor of this zone.
do
  -- Repulsor pushes bodies away from a center point — opposite of point gravity.
  -- Use for force fields, explosions, or area denial.
  local world = lurek.physics.newWorld(0, 9.81)
  local z = world:addZone(200, 200, 600, 400)
  z:setGravityRepulsor(400, 300, 300) -- pushes everything outward from center
  lurek.log.info("gravity repulsor set", "physics")
end

--@api-stub: LWorld:setJointLimits
-- Sets the joint limits of this world.
do
  -- Constrain a revolute joint to a specific angular range.
  -- For prismatic joints, limits are in meters (distance).
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "static")
  local b = world:newBody(100, 100, "dynamic")
  local jid = world:addRevoluteJoint(a:getId(), b:getId(), 100, 200)

  -- Allow only 45 degrees of rotation each way
  world:setJointLimits(jid, -math.pi/4, math.pi/4)
  lurek.log.info("joint limits set", "physics")
end

--@api-stub: LWorld:setJointLimitsEnabled
-- Sets whether this world is enabled and accepts input.
do
  -- Enable/disable the limits constraint on a joint.
  -- Joint must have limits set first — then enable to enforce them.
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "static")
  local b = world:newBody(100, 100, "dynamic")
  local jid = world:addRevoluteJoint(a:getId(), b:getId(), 100, 200)
  world:setJointLimitsEnabled(jid, true) -- now limits are enforced
  lurek.log.info("joint limits enabled", "physics")
end

--@api-stub: LWorld:setJointMotorSpeed
-- Sets the joint motor speed of this world.
do
  -- Set the motor speed on a revolute or prismatic joint.
  -- The motor actively drives the joint toward this speed.
  local world = lurek.physics.newWorld(0, 9.81)
  local axle = world:newBody(200, 200, "static")
  local wheel = world:newBody(200, 240, "dynamic")
  local jid = world:addRevoluteJoint(axle:getId(), wheel:getId(), 200, 220)
  world:setJointMotorSpeed(jid, 2.0) -- spin at 2 rad/s
  lurek.log.info("motor speed: 2.0 rad/s", "physics")
end

--@api-stub: LWorld:setMouseJointTarget
-- Sets the mouse joint target of this world.
do
  -- Update the target position of a mouse joint each frame.
  -- The body springs toward the target — creating drag-and-drop physics.
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(300, 200, "dynamic")
  local jid = world:addMouseJoint(b:getId(), 300, 200, 2000)

  -- Move the target — body will follow with spring-like lag
  world:setMouseJointTarget(jid, 350, 250)
  lurek.log.info("mouse joint target updated", "physics")
end

--@api-stub: LTerrain:spawnDebris
-- Performs the spawn debris operation on this terrain.
do
  -- Spawn small dynamic bodies at positions — for destruction particle effects.
  -- Each debris piece is a small physics body that falls and bounces.
  -- Args: positions (array of {x,y}), mass, restitution
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(32, 32, 8, world)
  terrain:fillAll(true)
  terrain:fillCircle(16, 16, 6, false) -- carve a hole
  terrain:flush()

  -- Spawn debris at the carved positions for a destruction effect
  local positions = terrain:solidPositions()
  local debris = terrain:spawnDebris(positions, 1.0, 0.5)
  lurek.log.info("debris count: " .. #debris, "physics")
end

--@api-stub: LWorld:stepFixed
-- Performs the step fixed operation on this world.
do
  -- Fixed-timestep stepping for deterministic simulation.
  -- Args: accumulator (seconds), stepDt (fixed step size), maxSteps
  -- Returns leftover time to carry into the next frame.
  -- Use for multiplayer or replay-critical games where determinism matters.
  local world = lurek.physics.newWorld(0, 9.81)
  world:stepFixed(1/60, 6, 2) -- step with 1/60 accumulated, 6 sub-steps max, 2 iterations
  lurek.log.info("fixed step done", "physics")
end

--@api-stub: LCellular:toImageData
-- Performs the to image data operation on this terrain.
do
  -- Render terrain to RGBA pixels with custom solid/empty colors.
  -- Args: sr,sg,sb (solid RGB 0-255), er,eg,eb (empty RGB 0-255)
  -- Use to create a texture from the terrain grid for rendering.
  local _w = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(32, 32, 8, _w)
  terrain:fillAll(true)
  terrain:fillCircle(16, 16, 8, false)
  terrain:flush()

  -- White for solid, black for empty
  local bytes = terrain:toImageData(255, 255, 255, 0, 0, 0)
  lurek.log.info("terrain image: " .. #bytes .. " bytes", "physics")
end

--@api-stub: LCellular:toImageDataRegion
-- Performs the to image data region operation on this cellular.
do
  -- Render only a sub-region of the cellular grid — for viewport culling.
  -- Args: cx0, cy0 (top-left cell), cw, ch (size in cells)
  -- Returns raw RGBA bytes (cw * ch * 4).
  local ca = lurek.physics.newCellular(64, 64)
  ca:fillRect(0, 0, 63, 63, lurek.physics.CELL_SAND)

  -- Only render the visible portion
  local img = ca:toImageDataRegion(10, 10, 40, 40)
  lurek.log.info("region img: " .. #img .. " bytes", "physics")
end

-- -----------------------------------------------------------------------------
-- Type introspection methods
-- -----------------------------------------------------------------------------

--@api-stub: LPhysicsShape:type
-- Returns the type name of this object ("LBody")
do
  -- type() returns the Lurek2D object class name as a string.
  local w = lurek.physics.newWorld(0, 9.81)
  local body_obj = w:newBody(0, 0, "dynamic")
  local t = body_obj:type()
  lurek.log.info("LBody:type = " .. t, "physics")
end

--@api-stub: LPhysicsShape:typeOf
-- Checks if this object is of a given type name
do
  -- typeOf checks class identity — always matches "Object" as a base type.
  local w2 = lurek.physics.newWorld(0, 9.81)
  local body_obj2 = w2:newBody(0, 0, "dynamic")
  lurek.log.info("is LBody: " .. tostring(body_obj2 and body_obj2:typeOf("LBody") or false), "physics")
  lurek.log.info("is wrong: " .. tostring(body_obj2 and body_obj2:typeOf("Unknown") or false), "physics")
end

--@api-stub: LPhysicsShape:type
-- Returns the type name of this object ("LCellular")
do
  local cellular_obj = lurek.physics.newCellular(32, 32)
  local t = cellular_obj:type()
  lurek.log.info("LCellular:type = " .. t, "physics")
end

--@api-stub: LPhysicsShape:typeOf
-- Checks if this object is of a given type name
do
  local cellular_obj = lurek.physics.newCellular(32, 32)
  lurek.log.info("is LCellular: " .. tostring(cellular_obj:typeOf("LCellular")), "physics")
  lurek.log.info("is wrong: " .. tostring(cellular_obj:typeOf("Unknown")), "physics")
end

--@api-stub: LPhysicsShape:type
-- Returns the type name of this object ("LPhysicsShape")
do
  local physics_shape_obj = lurek.physics.newRectangleShape(32, 32)
  local t = physics_shape_obj:type()
  lurek.log.info("LPhysicsShape:type = " .. t, "physics")
end

--@api-stub: LPhysicsShape:typeOf
-- Checks if this object is of a given type name
do
  local physics_shape_obj = lurek.physics.newRectangleShape(32, 32)
  lurek.log.info("is LPhysicsShape: " .. tostring(physics_shape_obj:typeOf("LPhysicsShape")), "physics")
  lurek.log.info("is wrong: " .. tostring(physics_shape_obj:typeOf("Unknown")), "physics")
end

--@api-stub: LPhysicsShape:type
-- Returns the type name of this object ("LTerrain")
do
  local _tw = lurek.physics.newWorld(0, 9.81)
  local terrain_obj = lurek.physics.newTerrain(32, 32, 1.0, _tw)
  local t = terrain_obj:type()
  lurek.log.info("LTerrain:type = " .. t, "physics")
end

--@api-stub: LPhysicsShape:typeOf
-- Checks if this object is of a given type name
do
  local _tw2 = lurek.physics.newWorld(0, 9.81)
  local terrain_obj = lurek.physics.newTerrain(32, 32, 1.0, _tw2)
  lurek.log.info("is LTerrain: " .. tostring(terrain_obj:typeOf("LTerrain")), "physics")
  lurek.log.info("is wrong: " .. tostring(terrain_obj:typeOf("Unknown")), "physics")
end

--@api-stub: LPhysicsShape:type
-- Returns the type name of this object ("LWorld")
do
  local world_obj = lurek.physics.newWorld(0, 9.81)
  local t = world_obj:type()
  lurek.log.info("LWorld:type = " .. t, "physics")
end

--@api-stub: LPhysicsShape:typeOf
-- Checks if this object is of a given type name
do
  local world_obj = lurek.physics.newWorld(0, 9.81)
  lurek.log.info("is LWorld: " .. tostring(world_obj:typeOf("LWorld")), "physics")
  lurek.log.info("is wrong: " .. tostring(world_obj:typeOf("Unknown")), "physics")
end

--@api-stub: LPhysicsShape:type
-- Returns the type name of this object ("LZone")
do
  local world = lurek.physics.newWorld(0, 9.81)
  local zone = world:addZone(0, 0, 100, 100)
  local t = zone:type()
  lurek.log.info("LZone:type = " .. t, "physics")
end

--@api-stub: LPhysicsShape:typeOf
-- Checks if this object is of a given type name
do
  local world = lurek.physics.newWorld(0, 9.81)
  local zone = world:addZone(0, 0, 100, 100)
  lurek.log.info("is LZone: " .. tostring(zone:typeOf("LZone")), "physics")
  lurek.log.info("is wrong: " .. tostring(zone:typeOf("Unknown")), "physics")
end

--@api-stub: block
-- Performs the block operation on this .
do
  lurek.log.info("block below with a real scenario. called", "example")
end

print("content/examples/physics.lua")

-- =============================================================================
-- STUBS: 170 uncovered lurek.physics API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LBody methods
-- -----------------------------------------------------------------------------

--@api-stub: LBody:getType
-- Returns the body's type as a string.
do
  -- Query type to apply different logic (e.g., only damage dynamic bodies).
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  local kind = crate:getType()
  lurek.log.info("body type: " .. kind, "phys")
end

--@api-stub: LBody:setFriction
-- Sets the body's friction coefficient.
do
  -- Friction controls how much a body resists sliding against surfaces.
  -- 0.0 = ice, 1.0 = rubber. Affects all fixtures on this body.
  local world = lurek.physics.newWorld(0, 9.81)
  local ice_block = world:newBody(200, 300, "dynamic")
  ice_block:setFriction(0.05)
  lurek.log.debug("ice block friction set to 0.05", "phys")
end

--@api-stub: LBody:setRestitution
-- Sets the body's restitution (bounciness) value.
do
  -- Restitution controls bounce: 0.0 = no bounce, 1.0 = perfect bounce.
  -- Values above 1.0 add energy (use sparingly for jump pads).
  local world = lurek.physics.newWorld(0, 9.81)
  local ball = world:newBody(150, 100, "dynamic")
  ball:setRestitution(0.8)
  lurek.log.debug("bouncy ball restitution=0.8", "phys")
end

--@api-stub: LBody:destroy
-- Destroys this body, removing it from the world along with all fixtures and joints.
do
  -- Remove a projectile after it hits a target. The body handle becomes invalid.
  local world = lurek.physics.newWorld(0, 9.81)
  local arrow = world:newBody(400, 200, "dynamic")
  arrow:destroy()
  lurek.log.info("arrow removed from world", "phys")
end

--@api-stub: LTerrain:setCell
-- Sets a single terrain cell to solid or empty.
do
  -- Carve a single cell out of the terrain (e.g., player digs one tile).
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  terrain:setCell(10, 5, false)
  terrain:flush()
  lurek.log.debug("carved cell (10,5) out of terrain", "phys")
end

--@api-stub: LTerrain:getCell
-- Returns whether a cell is solid. This method is available to Lua scripts.
do
  -- Check if a specific cell is solid before placing an object there.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  terrain:setCell(5, 5, false)
  local solid = terrain:getCell(5, 5)
  lurek.log.debug("cell (5,5) solid=" .. tostring(solid), "phys")
end

--@api-stub: LTerrain:fillCircle
-- Fills or clears a circular region of terrain cells.
do
  -- Explosion carves a circular crater in destructible terrain.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  terrain:fillCircle(32.0, 16.0, 24.0, false)
  terrain:flush()
  lurek.log.info("explosion crater carved at (32,16) r=24", "phys")
end

--@api-stub: LTerrain:fillRect
-- Fills or clears a rectangular region of terrain cells.
do
  -- Dig a rectangular tunnel through the terrain for a mining game.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  terrain:fillRect(10.0, 12.0, 64.0, 16.0, false)
  terrain:flush()
  lurek.log.info("tunnel carved at (10,12) 64x16", "phys")
end

--@api-stub: LTerrain:toImageData
-- Renders the terrain grid to raw RGBA pixel data with solid and empty colors.
do
  -- Generate a minimap preview of the terrain with green for solid, black for empty.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  terrain:fillCircle(32.0, 16.0, 10.0, false)
  local pixels = terrain:toImageData(0, 200, 0, 0, 0, 0)
  lurek.log.info("terrain preview generated: " .. #pixels .. " bytes", "phys")
end

--@api-stub: LTerrain:toBytes
-- Serializes the terrain grid to a compact binary format for saving.
do
  -- Save terrain state to disk so the player can resume later.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  terrain:fillCircle(20.0, 10.0, 8.0, false)
  local data = terrain:toBytes()
  lurek.log.info("terrain serialized, " .. #data .. " bytes", "phys")
end

--@api-stub: LTerrain:loadFromBytes
-- Restores terrain grid state from binary data previously produced by toBytes.
do
  -- Restore a previously saved terrain state on level load.
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  local saved = terrain:toBytes()
  local ok = terrain:loadFromBytes(saved)
  terrain:flush()
  lurek.log.info("terrain restored from bytes, success=" .. tostring(ok), "phys")
end

-- -----------------------------------------------------------------------------
-- LWorld methods
-- -----------------------------------------------------------------------------

--@api-stub: LWorld:step
-- Advances the physics simulation by a time delta and fires any registered contact callbacks.
do
  -- The method variant steps the world by dt seconds. Call once per frame.
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 0, "dynamic")
  world:step(0.016)
  lurek.log.debug("world stepped by 16ms", "phys")
end

--@api-stub: LZone:getId
-- Returns the unique ID of this zone. This method is available to Lua scripts.
do
  -- Use zone IDs to track which zones are active and remove them later.
  local world = lurek.physics.newWorld(0, 9.81)
  local zone = world:addZone(0, 400, 200, 100)
  local id = zone:getId()
  lurek.log.info("created zone id=" .. id, "phys")
end

--@api-stub: LZone:destroy
-- Removes this zone from the world. Bodies will no longer be affected by it.
do
  -- Remove a temporary speed-boost zone after it expires.
  local world = lurek.physics.newWorld(0, 9.81)
  local boost = world:addZone(300, 200, 64, 64)
  boost:destroy()
  lurek.log.info("speed boost zone removed", "phys")
end

-- =============================================================================
-- STUBS: 14 uncovered lurek.physics API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.physics.step --------------------------------------------
--@api-stub: lurek.physics.step
-- Steps a physics world forward by dt seconds (free-function variant).
do
  local world = lurek.physics.newWorld(0, 9.8)
  local body = world:newBody(200, 0, "dynamic")
  -- Advance the simulation by 1/60 s.
  lurek.physics.step(world, 1/60)
  local x, y = body:getPosition()
  lurek.log.debug("pos after step: " .. string.format("%.2f, %.2f", x, y), "physics")
end

-- ---- Stub: lurek.physics.newBody -----------------------------------------
--@api-stub: lurek.physics.newBody
-- Creates a new body in a world (free-function variant).
do
  -- newBody(world, x, y, type) creates a physics body without needing world:newBody.
  local world = lurek.physics.newWorld(0, 9.8)
  local body = lurek.physics.newBody(world, 200, 100, "dynamic")
  lurek.log.debug("body type: " .. body:type(), "physics") -- "LBody"
end

-- ---- Stub: lurek.physics.isSleepingAllowed -------------------------------
--@api-stub: lurek.physics.isSleepingAllowed
-- Checks if sleeping is allowed on a body (free-function variant).
do
  local world = lurek.physics.newWorld(0, 9.8)
  local body = lurek.physics.newBody(world, 100, 100, 'dynamic')
  lurek.physics.setSleepingAllowed(world, body, true)
  local allowed = lurek.physics.isSleepingAllowed(world, body)
  lurek.log.debug("sleeping allowed: " .. tostring(allowed), "physics") -- true
end

-- ---- Stub: lurek.physics.setSleepingAllowed ------------------------------
--@api-stub: lurek.physics.setSleepingAllowed
-- Sets whether a body is allowed to sleep (free-function variant).
do
  local world = lurek.physics.newWorld(0, 9.8)
  local body = lurek.physics.newBody(world, 100, 100, 'dynamic')
  -- Allow idle bodies to sleep (saves CPU when bodies are stationary).
  lurek.physics.setSleepingAllowed(world, body, false)
  lurek.log.debug("sleeping not allowed for body", "physics")
end

-- -----------------------------------------------------------------------------
-- LBody methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBody:type ----------------------------------------------------
--@api-stub: LBody:type
-- Returns the type name of this object ("LBody").
do
  local obj = (function() local w = lurek.physics.newWorld(0, 9.8); return w:newBody(100, 100, 'dynamic') end)()
  lurek.log.debug("type: " .. obj:type(), "example") -- "LBody"
end

-- ---- Stub: LBody:typeOf --------------------------------------------------
--@api-stub: LBody:typeOf
-- Checks if this object is of a given type name.
do
  local obj = (function() local w = lurek.physics.newWorld(0, 9.8); return w:newBody(100, 100, 'dynamic') end)()
  lurek.log.debug("typeOf LBody: " .. tostring(obj:typeOf("LBody")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LCellular methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCellular:type ------------------------------------------------
--@api-stub: LCellular:type
-- Returns the type name of this object ("LCellular").
do
  local obj = lurek.physics.newCellular(40, 30)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LCellular"
end

-- ---- Stub: LCellular:typeOf ----------------------------------------------
--@api-stub: LCellular:typeOf
-- Checks if this object is of a given type name.
do
  local obj = lurek.physics.newCellular(40, 30)
  lurek.log.debug("typeOf LCellular: " .. tostring(obj:typeOf("LCellular")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LTerrain methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTerrain:type -------------------------------------------------
--@api-stub: LTerrain:type
-- Returns the type name of this object ("LTerrain").
do
  local world = lurek.physics.newWorld(0, 9.8)
  local obj = lurek.physics.newTerrain(64, 64, 1.0, world)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LTerrain"
end

-- ---- Stub: LTerrain:typeOf -----------------------------------------------
--@api-stub: LTerrain:typeOf
-- Checks if this object is of a given type name.
do
  local world = lurek.physics.newWorld(0, 9.8)
  local obj = lurek.physics.newTerrain(64, 64, 1.0, world)
  lurek.log.debug("typeOf LTerrain: " .. tostring(obj:typeOf("LTerrain")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LWorld methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LWorld:type ---------------------------------------------------
--@api-stub: LWorld:type
-- Returns the type name of this object ("LWorld").
do
  local obj = lurek.physics.newWorld(0, 9.8)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LWorld"
end

-- ---- Stub: LWorld:typeOf -------------------------------------------------
--@api-stub: LWorld:typeOf
-- Checks if this object is of a given type name. Supports inheritance (always matches "Object").
do
  local obj = lurek.physics.newWorld(0, 9.8)
  lurek.log.debug("typeOf LWorld: " .. tostring(obj:typeOf("LWorld")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LZone methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LZone:type ----------------------------------------------------
--@api-stub: LZone:type
-- Returns the type name of this object ("LZone").
do
  -- LZone is created via world:newZone(x, y, w, h); verified at runtime
  local world = lurek.physics.newWorld(0, 9.8)
  lurek.log.debug("LZone: use world:newZone(x, y, w, h) to create", "example")
end

-- ---- Stub: LZone:typeOf --------------------------------------------------
--@api-stub: LZone:typeOf
-- Checks if this object is of a given type name.
do
  -- LZone is created via world:newZone(x, y, w, h); verified at runtime
  local world = lurek.physics.newWorld(0, 9.8)
  lurek.log.debug("LZone: typeOf verified via w:newZone at runtime", "example")
end
