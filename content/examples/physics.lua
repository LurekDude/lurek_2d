-- content/examples/physics.lua
-- Hand-written coverage of the lurek.physics API (147 items).
--
-- The lurek.physics namespace wraps a 2D rigid-body simulator with bodies,
-- shapes, joints, sensor zones, destructible terrain grids, and a falling-
-- sand cellular automaton. Build a world once, step it from lurek.process,
-- and drain collision / zone events between steps to drive game logic.
--
-- Run: cargo run -- content/examples/physics.lua

-- â”€â”€ lurek.physics.* functions â”€â”€

--@api-stub: lurek.physics.newWorld
-- Creates a new physics world with the given gravity vector.
-- Build the world once at startup; pass it to body factories and step it every frame.
do  -- lurek.physics.newWorld
  local world = lurek.physics.newWorld(0, 9.81)
  lurek.log.info("physics world created with " .. world:getBodyCount() .. " bodies", "boot")
end

--@api-stub: lurek.physics.step
-- Advances the physics world by dt seconds.
-- Use this flat form when you do not need the contact callbacks fired by World:step.
do  -- lurek.physics.step
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    lurek.physics.step(world, dt)
  end
end

--@api-stub: lurek.physics.destroyWorld
-- Marks a physics world for destruction.
-- Drop your last reference to the world or call this on scene unload to release colliders.
do  -- lurek.physics.destroyWorld
  local world = lurek.physics.newWorld(0, 9.81)
  lurek.physics.destroyWorld(world)
  world = nil --[[@type any]]
end

--@api-stub: lurek.physics.newBody
-- Creates a new rectangular body in the given world.
-- Pass body type as one of "dynamic" / "static" / "kinematic"; rectangular fixture is implicit.
do  -- lurek.physics.newBody
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = lurek.physics.newBody(world, 100, 200, "dynamic")
  crate:setMass(1.0)
end

--@api-stub: lurek.physics.getBody
-- Returns the position and velocity of a body (x, y, vx, vy).
-- Returns x, y, vx, vy in one call â€” handy for syncing a sprite to its body each frame.
do  -- lurek.physics.getBody
  local world = lurek.physics.newWorld(0, 9.81)
  local body = lurek.physics.newBody(world, 100, 200, "dynamic")
  local x, y, vx, vy = lurek.physics.getBody(world, body)
  lurek.log.debug("crate at " .. x .. "," .. y .. " v=" .. vx .. "," .. vy, "phys")
end

--@api-stub: lurek.physics.setBodyVelocity
-- Sets the velocity of a body.
-- Use to launch a projectile or apply a one-shot velocity change without stacking impulses.
do  -- lurek.physics.setBodyVelocity
  local world = lurek.physics.newWorld(0, 9.81)
  local bullet = lurek.physics.newBody(world, 100, 200, "dynamic")
  lurek.physics.setBodyVelocity(world, bullet, 600, -200)
end

--@api-stub: lurek.physics.isSleepingAllowed
-- Returns whether the body is allowed to sleep.
-- Branch on this before applying ambient forces â€” woken bodies cost solver time.
do  -- lurek.physics.isSleepingAllowed
  local world = lurek.physics.newWorld(0, 9.81)
  local body = lurek.physics.newBody(world, 100, 200, "dynamic")
  if lurek.physics.isSleepingAllowed(world, body) then
    lurek.log.debug("body may sleep when idle", "phys")
  end
end

--@api-stub: lurek.physics.setSleepingAllowed
-- Sets whether the body is allowed to sleep.
-- Disable sleeping on bodies you constantly poll (player, vehicle) to avoid wake-up jitter.
do  -- lurek.physics.setSleepingAllowed
  local world = lurek.physics.newWorld(0, 9.81)
  local player = lurek.physics.newBody(world, 100, 200, "dynamic")
  lurek.physics.setSleepingAllowed(world, player, false)
end

--@api-stub: lurek.physics.newRectangleShape
-- Creates a rectangle shape userdata.
-- Attach to a body via lurek.physics.attachShape â€” width and height are in world units.
do  -- lurek.physics.newRectangleShape
  local crate_shape = lurek.physics.newRectangleShape(64, 64)
  lurek.log.info("crate shape type=" .. crate_shape:getType(), "phys")
end

--@api-stub: lurek.physics.newCircleShape
-- Creates a circle shape userdata.
-- Use for balls, wheels, or grenades; cheaper to test for collisions than polygons.
do  -- lurek.physics.newCircleShape
  local ball_shape = lurek.physics.newCircleShape(16)
  lurek.log.info("ball radius=" .. ball_shape:getRadius(), "phys")
end

--@api-stub: lurek.physics.newEdgeShape
-- Creates an edge (line segment) shape userdata.
-- Use for thin walls or sloped floors that should not have inside-corner ghost collisions.
do  -- lurek.physics.newEdgeShape
  local floor_shape = lurek.physics.newEdgeShape(0, 480, 800, 480)
  lurek.log.info("floor edge type=" .. floor_shape:getType(), "phys")
end

--@api-stub: lurek.physics.newPolygonShape
-- Creates a convex polygon shape userdata from flat variadic vertex pairs.
-- Pass at least 3 vertex pairs (6 numbers) winding counter-clockwise; must be convex.
do  -- lurek.physics.newPolygonShape
  local triangle = lurek.physics.newPolygonShape(0, 0, 32, 0, 16, 28)
  lurek.log.info("triangle type=" .. triangle:getType(), "phys")
end

--@api-stub: lurek.physics.newChainShape
-- Creates a chain shape userdata from flat variadic vertex pairs.
-- Use for terrain outlines; pass closed=true for a loop, false for an open polyline.
do  -- lurek.physics.newChainShape
  local hill = lurek.physics.newChainShape(false, 0, 400, 100, 360, 200, 380, 300, 420)
  lurek.log.info("hill chain type=" .. hill:getType(), "phys")
end

--@api-stub: lurek.physics.attachShape
-- Attaches a standalone shape to a body as an additional fixture.
-- Use to give a body a compound collider (e.g. car body + wheel arches) after creation.
do  -- lurek.physics.attachShape
  local world = lurek.physics.newWorld(0, 9.81)
  local car = lurek.physics.newBody(world, 200, 200, "dynamic")
  local roof = lurek.physics.newRectangleShape(64, 16)
  lurek.physics.attachShape(car, roof)
end

--@api-stub: lurek.physics.getCollisions
-- Returns all collision events from the last simulation step.
-- Drain once per frame after step; entries are {body_a, body_b} index pairs.
do  -- lurek.physics.getCollisions
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    lurek.physics.step(world, dt)
    for _, c in ipairs(lurek.physics.getCollisions(world)) do
      lurek.log.debug("hit " .. c.body_a .. " vs " .. c.body_b, "phys")
    end
  end
end

--@api-stub: lurek.physics.debugDraw
-- Enables or disables the physics debug overlay (AABB boxes and velocity vectors).
-- Toggle from a debug key; the engine renders AABBs and velocity arrows when enabled.
do  -- lurek.physics.debugDraw
  lurek.physics.debugDraw(true)
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("f3") then lurek.physics.debugDraw(false) end
  end
end

--@api-stub: lurek.physics.drawDebugGpu
-- Extracts collider geometry from a World and queues a GPU physics debug.
-- Call from lurek.render to overlay collider outlines via the GPU pipeline (no ImageData needed).
do  -- lurek.physics.drawDebugGpu
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.draw()
    lurek.physics.drawDebugGpu(world, { bodyColor = {0, 1, 0, 1}, lineWidth = 2.0 })
  end
end

--@api-stub: lurek.physics.newTerrain
-- Creates a destructible terrain grid.
-- Build a destructible voxel grid bound to a physics world; flush() to push colliders.
do  -- lurek.physics.newTerrain
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  terrain:flush()
end

--@api-stub: lurek.physics.newCellular
-- Creates a falling-sand cellular automaton grid.
-- Spin up a falling-sand grid; step it every frame, paint with setCell or fillCircle.
do  -- lurek.physics.newCellular
  local sand = lurek.physics.newCellular(128, 64)
  sand:setCell(64, 0, lurek.physics.CELL_SAND)
  function lurek.process(dt) sand:step() end
end


-- â”€â”€ World methods â”€â”€

--@api-stub: World:step
-- Advances the physics simulation by dt seconds, firing onBeginContact /.
-- Call every frame from lurek.process(dt); contact callbacks fire as a side effect.
do  -- World:step
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
  end
end

--@api-stub: World:clear
-- Resets the world, removing all bodies and joints.
-- Use when transitioning between levels to wipe all bodies and joints in one call.
do  -- World:clear
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 200, "dynamic")
  world:clear()
  lurek.log.info("world cleared, body count=" .. world:getBodyCount(), "scene")
end

--@api-stub: World:getGravity
-- Returns the gravity vector (gx, gy).
-- Read the current gravity vector â€” useful when toggling underwater / zero-g modes.
do  -- World:getGravity
  local world = lurek.physics.newWorld(0, 9.81)
  local gx, gy = world:getGravity()
  lurek.log.info("gravity=" .. gx .. "," .. gy, "phys")
end

--@api-stub: World:setGravity
-- Sets the world gravity vector; default is `(0, 9.81)` (downward).
-- Mutate gravity at runtime to enter water (gy=2.0), zero-g (0,0), or invert it (0,-9.81).
do  -- World:setGravity
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("g") then world:setGravity(0, -9.81) end
  end
end

--@api-stub: World:setMeter
-- Sets the pixels-per-meter scaling factor.
-- Tune pixels-per-meter once at startup so 1 game-meter matches your sprite size.
do  -- World:setMeter
  local world = lurek.physics.newWorld(0, 9.81)
  world:setMeter(64)
  lurek.log.info("ppm=" .. world:getMeter(), "phys")
end

--@api-stub: World:getMeter
-- Returns the pixels-per-meter scaling factor.
-- Read PPM when converting between sprite pixel sizes and physics-world units.
do  -- World:getMeter
  local world = lurek.physics.newWorld(0, 9.81)
  local ppm = world:getMeter()
  lurek.log.debug("1 meter = " .. ppm .. " pixels", "phys")
end

--@api-stub: World:toPhysics
-- Converts a pixel value to physics units.
-- Convert pixel measurements (sprite size, mouse position) into physics units before passing in.
do  -- World:toPhysics
  local world = lurek.physics.newWorld(0, 9.81)
  local px = 128
  local meters = world:toPhysics(px)
  lurek.log.debug(px .. " px = " .. meters .. " m", "phys")
end

--@api-stub: World:toPixels
-- Converts a physics-unit value to pixels.
-- Convert physics-unit body positions back to pixels for sprite drawing.
do  -- World:toPixels
  local world = lurek.physics.newWorld(0, 9.81)
  local pixels = world:toPixels(2.5)
  lurek.log.debug("2.5 m = " .. pixels .. " px", "phys")
end

--@api-stub: World:getBodyCount
-- Returns the total number of bodies in the world.
-- Use as a sanity check when loading levels or to gate spawning under a cap.
do  -- World:getBodyCount
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 200, "dynamic")
  if world:getBodyCount() < 1000 then world:newBody(150, 200, "dynamic") end
end

--@api-stub: World:getBodyIds
-- Returns all body IDs in the world.
-- Iterate to query or destroy every body; each id can be passed to setBodyType etc.
do  -- World:getBodyIds
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 200, "dynamic")
  for _, id in ipairs(world:getBodyIds()) do
    lurek.log.debug("body id=" .. id, "phys")
  end
end

--@api-stub: World:destroyBody
-- Removes a body from the world.
-- Remove a body when its game entity dies; subsequent operations on the id are no-ops.
do  -- World:destroyBody
  local world = lurek.physics.newWorld(0, 9.81)
  local enemy = world:newBody(300, 200, "dynamic")
  world:destroyBody(enemy:getId())
end

--@api-stub: World:newBody
-- Creates a new rectangular body and adds it to the world.
-- Returns a Body userdata you can call methods on; type is dynamic/static/kinematic.
do  -- World:newBody
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  crate:setMass(2.5)
  crate:setRestitution(0.3)
end

--@api-stub: World:fixtureCount
-- Returns the number of fixtures on a body.
-- Use to verify a body has all expected colliders attached after attachShape calls.
do  -- World:fixtureCount
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  local n = world:fixtureCount(body:getId())
  lurek.log.debug("body has " .. n .. " fixtures", "phys")
end

--@api-stub: World:jointCount
-- Returns the total number of joints.
-- Useful when serialising a level to allocate the joint table up-front.
do  -- World:jointCount
  local world = lurek.physics.newWorld(0, 9.81)
  lurek.log.info("joints=" .. world:jointCount(), "phys")
end

--@api-stub: World:getJointIds
-- Returns a table of integer IDs for every joint attached to this world.
-- Iterate to inspect or destroy every joint (e.g. when respawning a vehicle).
do  -- World:getJointIds
  local world = lurek.physics.newWorld(0, 9.81)
  for _, jid in ipairs(world:getJointIds()) do
    lurek.log.debug("joint id=" .. jid, "phys")
  end
end

--@api-stub: World:getJointBodies
-- Returns the two body IDs connected by a joint.
-- Use to find which bodies a joint connects when reacting to a break event.
do  -- World:getJointBodies
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local a, b = world:getJointBodies(jid)
  lurek.log.debug("joint " .. jid .. " links " .. a .. " <-> " .. b, "phys")
end

--@api-stub: World:destroyJoint
-- Removes a joint from the world.
-- Call when an entity disassembles (vehicle wreck, broken chain) to free constraint solver work.
do  -- World:destroyJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  world:destroyJoint(jid)
end

--@api-stub: World:getJointType
-- Returns the type name of a joint.
-- Branch on the type string when you have a heterogeneous joint registry.
do  -- World:getJointType
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local kind = world:getJointType(jid)
  if kind == "revolute" then lurek.log.debug("hinge joint", "phys") end
end

--@api-stub: World:getJointMotorSpeed
-- Returns the motor speed on a joint's angular axis.
-- Read motor speed for HUD telemetry or to drive sound pitch on a powered joint.
do  -- World:getJointMotorSpeed
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local rpm = world:getJointMotorSpeed(jid)
  lurek.log.debug("motor speed=" .. rpm, "phys")
end

--@api-stub: World:getJointLimits
-- Returns the angular limits on a joint.
-- Use when serialising joint state or rendering a limit indicator in editor mode.
do  -- World:getJointLimits
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local lo, hi = world:getJointLimits(jid)
  lurek.log.debug("limits=[" .. lo .. ", " .. hi .. "]", "phys")
end

--@api-stub: World:getBodyAtPoint
-- Returns the body ID at a world-space point, or nil.
-- Use for click-to-select tools; returns nil when nothing under the cursor.
do  -- World:getBodyAtPoint
  local world = lurek.physics.newWorld(0, 9.81)
  local hit = world:getBodyAtPoint(150, 200)
  if hit then lurek.log.debug("clicked body=" .. hit, "phys") end
end

--@api-stub: World:getCollisionEvents
-- Returns collision events from the last step.
-- Drain once per step and react to gameplay-meaningful pairs (player vs pickup etc.).
do  -- World:getCollisionEvents
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getCollisionEvents()) do
      lurek.log.debug("hit " .. e.bodyA .. " vs " .. e.bodyB, "phys")
    end
  end
end

--@api-stub: World:getBeginContactEvents
-- Returns begin-contact events from the last step.
-- Use the begin-only stream for one-shot triggers like pickup-on-touch logic.
do  -- World:getBeginContactEvents
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getBeginContactEvents()) do
      lurek.log.debug("begin " .. e.bodyA .. "/" .. e.bodyB, "phys")
    end
  end
end

--@api-stub: World:getEndContactEvents
-- Returns end-contact events from the last step.
-- Use to detect when objects part â€” e.g. removing a temporary glue effect.
do  -- World:getEndContactEvents
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getEndContactEvents()) do
      lurek.log.debug("end " .. e.bodyA .. "/" .. e.bodyB, "phys")
    end
  end
end

--@api-stub: World:getContacts
-- Returns all contact pairs from the narrow phase.
-- Includes contact normals â€” use to push bodies apart manually or to spawn impact FX.
do  -- World:getContacts
  local world = lurek.physics.newWorld(0, 9.81)
  for _, c in ipairs(world:getContacts()) do
    if c.isTouching then
      lurek.log.debug("contact n=" .. c.normalX .. "," .. c.normalY, "phys")
    end
  end
end

--@api-stub: World:getBodyContacts
-- Returns contacts involving a specific body.
-- Filter to one body when you only care about a specific entity (player ground check).
do  -- World:getBodyContacts
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  local touches = world:getBodyContacts(player:getId())
  lurek.log.debug("player contacts=" .. #touches, "phys")
end

--@api-stub: World:setBodyType
-- Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
-- Switch a body to kinematic for cutscenes, then back to dynamic when control resumes.
do  -- World:setBodyType
  local world = lurek.physics.newWorld(0, 9.81)
  local door = world:newBody(200, 200, "static")
  world:setBodyType(door:getId(), "kinematic")
end

--@api-stub: World:getBodyType
-- Returns the body type as a string.
-- Read before mutating mass or velocity â€” only dynamic bodies respond to those.
do  -- World:getBodyType
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if world:getBodyType(body:getId()) == "dynamic" then body:setMass(1.0) end
end

--@api-stub: World:setBeginContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- Register once at boot; the callback runs from inside step() so do minimal work there.
do  -- World:setBeginContact
  local world = lurek.physics.newWorld(0, 9.81)
  world:setBeginContact(function(a, b)
    lurek.log.info("touch " .. a .. " <-> " .. b, "phys")
  end)
end

--@api-stub: World:clearBeginContact
-- Removes the begin-contact callback.
-- Call when leaving a scene to drop the closure and any captured upvalues.
do  -- World:clearBeginContact
  local world = lurek.physics.newWorld(0, 9.81)
  world:setBeginContact(function(a, b) end)
  world:clearBeginContact()
end

--@api-stub: World:setEndContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- Use to clean up state attached on begin (sound stops, particle emitter off).
do  -- World:setEndContact
  local world = lurek.physics.newWorld(0, 9.81)
  world:setEndContact(function(a, b)
    lurek.log.debug("apart " .. a .. " / " .. b, "phys")
  end)
end

--@api-stub: World:clearEndContact
-- Removes the end-contact callback.
-- Pair with clearBeginContact when unloading a level to drop callbacks.
do  -- World:clearEndContact
  local world = lurek.physics.newWorld(0, 9.81)
  world:setEndContact(function(a, b) end)
  world:clearEndContact()
end

--@api-stub: World:getBodyData
-- Returns the Lua data previously attached to a body, or nil if none is set.
-- Use to recover the Lua entity (table, name) from a body id inside a contact callback.
do  -- World:getBodyData
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  world:setBodyData(body:getId(), { kind = "enemy", hp = 30 })
  local data = world:getBodyData(body:getId())
  if data then lurek.log.debug("entity kind=" .. data.kind, "phys") end
end

--@api-stub: World:clearBodyData
-- Removes the Lua data attached to a body.
-- Call when an entity dies but the body is recycled, to avoid stale references.
do  -- World:clearBodyData
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  world:setBodyData(body:getId(), { name = "crate" })
  world:clearBodyData(body:getId())
end

--@api-stub: World:setBodyCCD
-- Enables or disables Continuous Collision Detection for a body.
-- Enable on bullets and fast-moving projectiles to prevent tunnelling through walls.
do  -- World:setBodyCCD
  local world = lurek.physics.newWorld(0, 9.81)
  local bullet = world:newBody(100, 200, "dynamic")
  world:setBodyCCD(bullet:getId(), true)
end

--@api-stub: World:getBodyCCD
-- Returns whether CCD is enabled for a body.
-- Branch on this when applying very high impulses to prefer CCD-enabled bodies.
do  -- World:getBodyCCD
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if not world:getBodyCCD(body:getId()) then world:setBodyCCD(body:getId(), true) end
end

--@api-stub: World:clearBodyOneWay
-- Removes the one-way platform flag from a body.
-- Call when a one-way platform should become solid from both sides (e.g. boss arena).
do  -- World:clearBodyOneWay
  local world = lurek.physics.newWorld(0, 9.81)
  local platform = world:newBody(200, 300, "static")
  world:clearBodyOneWay(platform:getId())
end

--@api-stub: World:getBodyOneWay
-- Returns the one-way normal for a body, or nil if not configured.
-- Use to render an indicator arrow showing which way bodies pass through the platform.
do  -- World:getBodyOneWay
  local world = lurek.physics.newWorld(0, 9.81)
  local platform = world:newBody(200, 300, "static")
  local nx, ny = world:getBodyOneWay(platform:getId())
  if nx then lurek.log.debug("one-way n=" .. nx .. "," .. ny, "phys") end
end

--@api-stub: World:setJointBreakForce
-- Sets the relative-velocity threshold above which a joint breaks.
-- Use to model destructible vehicle joints â€” the engine destroys the joint when exceeded.
do  -- World:setJointBreakForce
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  world:setJointBreakForce(jid, 5000.0)
end

--@api-stub: World:getJointBreakForce
-- Returns the break threshold for a joint, or nil if not set.
-- Read for HUD / damage display; returns nil when no break threshold has been set.
do  -- World:getJointBreakForce
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local f = world:getJointBreakForce(jid)
  if f then lurek.log.debug("breaks at " .. f .. " N", "phys") end
end

--@api-stub: World:isBodySleeping
-- Returns true if a body is currently sleeping (inactive).
-- Use to skip per-frame work on inactive bodies (AI updates, sound emission).
do  -- World:isBodySleeping
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if not world:isBodySleeping(body:getId()) then
    lurek.log.debug("body active", "phys")
  end
end

--@api-stub: World:wakeUpBody
-- Forcibly wakes up a sleeping body.
-- Wake before applying impulses or forces â€” sleeping bodies ignore them.
do  -- World:wakeUpBody
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  world:wakeUpBody(body:getId())
  body:applyImpulse(0, -100)
end

--@api-stub: World:sleepBody
-- Puts a body to sleep immediately.
-- Force-sleep statically positioned dynamic bodies (a settled debris pile) to save CPU.
do  -- World:sleepBody
  local world = lurek.physics.newWorld(0, 9.81)
  local rubble = world:newBody(100, 200, "dynamic")
  world:sleepBody(rubble:getId())
end

--@api-stub: World:setSolverIterations
-- Sets the number of constraint solver iterations per step.
-- Bump for stacking-heavy scenes; 8 is the default, 16 trades CPU for stability.
do  -- World:setSolverIterations
  local world = lurek.physics.newWorld(0, 9.81)
  world:setSolverIterations(12)
end

--@api-stub: World:getSolverIterations
-- Returns the current number of solver iterations per step.
-- Read for tuning UI or to log the current accuracy budget at startup.
do  -- World:getSolverIterations
  local world = lurek.physics.newWorld(0, 9.81)
  local iters = world:getSolverIterations()
  lurek.log.info("solver iterations=" .. iters, "phys")
end

--@api-stub: World:newBodies
-- Creates multiple bodies in one call.
-- Use for bulk spawning a particle storm or grid of crates with a single round-trip.
do  -- World:newBodies
  local world = lurek.physics.newWorld(0, 9.81)
  local ids = world:newBodies({
    { 100, 200, "dynamic" },
    { 132, 200, "dynamic" },
    { 164, 200, "dynamic" },
  })
  lurek.log.info("spawned " .. #ids .. " crates", "phys")
end

--@api-stub: World:addZone
-- Creates a rectangular gravity/damping zone and returns a LuaZone handle.
-- Returns a Zone handle; configure gravity / damping override before bodies enter it.
do  -- World:addZone
  local world = lurek.physics.newWorld(0, 9.81)
  local water = world:addZone(0, 400, 800, 200)
  water:setGravityDirectional(0, 2.0)
end

--@api-stub: World:getZoneEvents
-- Returns zone enter/leave events produced by the most recent step.
-- Drain after step to spawn splash particles on enter and bubble trails on leave.
do  -- World:getZoneEvents
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getZoneEvents()) do
      lurek.log.debug("zone " .. e.zone_id .. " " .. e.kind .. " body=" .. e.body_id, "phys")
    end
  end
end


-- â”€â”€ Zone methods â”€â”€

--@api-stub: Zone:getId
-- Returns the zone's integer ID.
-- Capture the id at startup so you can match it against zone events later.
do  -- Zone:getId
  local world = lurek.physics.newWorld(0, 9.81)
  local zone = world:addZone(0, 0, 100, 100)
  lurek.log.info("water zone id=" .. zone:getId(), "phys")
end

--@api-stub: Zone:setEnabled
-- Enables or disables the zone.
-- Toggle from gameplay (close a force-field gate) without destroying the zone.
do  -- Zone:setEnabled
  local world = lurek.physics.newWorld(0, 9.81)
  local field = world:addZone(0, 0, 200, 200)
  field:setEnabled(false)
end

--@api-stub: Zone:setPriority
-- Sets the zone priority; higher values win over lower when zones overlap.
-- Higher priority wins when zones overlap â€” use to layer a wind tunnel above ambient water.
do  -- Zone:setPriority
  local world = lurek.physics.newWorld(0, 9.81)
  local wind = world:addZone(0, 0, 200, 200)
  wind:setPriority(10)
end

--@api-stub: Zone:setLayerMask
-- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
-- Restrict the zone to certain body layers (e.g. only enemies feel the slow field).
do  -- Zone:setLayerMask
  local world = lurek.physics.newWorld(0, 9.81)
  local slow = world:addZone(100, 100, 200, 200)
  slow:setLayerMask(0x02)
end

--@api-stub: Zone:setCircle
-- Replaces the zone boundary with a circle.
-- Switch from rectangle to circular boundary â€” useful for blast radii or planet wells.
do  -- Zone:setCircle
  local world = lurek.physics.newWorld(0, 9.81)
  local well = world:addZone(0, 0, 1, 1)
  well:setCircle(400, 300, 120)
end

--@api-stub: Zone:setGravityDirectional
-- Sets directional gravity inside the zone.
-- Use for water (light downward pull) or wind tunnels (sideways pull).
do  -- Zone:setGravityDirectional
  local world = lurek.physics.newWorld(0, 9.81)
  local water = world:addZone(0, 400, 800, 200)
  water:setGravityDirectional(0, 2.0)
end

--@api-stub: Zone:setGravityZero
-- Suppresses gravity inside the zone (zero-g pocket).
-- Make a zero-g pocket inside the level (space station chamber, magic bubble).
do  -- Zone:setGravityZero
  local world = lurek.physics.newWorld(0, 9.81)
  local bubble = world:addZone(300, 100, 200, 200)
  bubble:setGravityZero()
end

--@api-stub: Zone:setLinearDampingOverride
-- Sets an optional linear damping override for bodies inside the zone.
-- Use to slow projectiles inside molasses; pass nil to clear and restore body damping.
do  -- Zone:setLinearDampingOverride
  local world = lurek.physics.newWorld(0, 9.81)
  local glue = world:addZone(0, 0, 100, 100)
  glue:setLinearDampingOverride(5.0)
end

--@api-stub: Zone:destroy
-- Removes the zone from the world.
-- Call when the trigger area despawns (door closed, level changed) to free zone memory.
do  -- Zone:destroy
  local world = lurek.physics.newWorld(0, 9.81)
  local zone = world:addZone(0, 0, 100, 100)
  zone:destroy()
end


-- â”€â”€ Terrain methods â”€â”€

--@api-stub: Terrain:setCell
-- Sets a single terrain cell to solid or empty.
-- Use for surgical edits like spawning a single block; bulk dig with fillCircle.
do  -- Terrain:setCell
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:setCell(10, 5, true)
  terrain:flush()
end

--@api-stub: Terrain:getCell
-- Returns whether a cell is solid.
-- Probe before placing a structure â€” fail early when target cells are not solid.
do  -- Terrain:getCell
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  if terrain:getCell(10, 5) then lurek.log.debug("solid cell", "terrain") end
end

--@api-stub: Terrain:fillAll
-- Sets every cell in the grid to `solid`.
-- Initialise an empty world (false) or a fully-buried one (true) before sculpting.
do  -- Terrain:fillAll
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
end

--@api-stub: Terrain:flush
-- Rebuilds physics bodies for all dirty chunks.
-- Call after every batch of edits, before world:step, to push collider changes to physics.
do  -- Terrain:flush
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:setCell(5, 5, true)
  terrain:flush()
end

--@api-stub: Terrain:isDirty
-- Returns `true` when at least one chunk needs flushing.
-- Skip flush() when nothing changed this frame â€” saves chunk rebuild work.
do  -- Terrain:isDirty
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  if terrain:isDirty() then terrain:flush() end
end

--@api-stub: Terrain:collapseColumns
-- Removes unsupported cells, returning the number of cells that fell.
-- Run after explosions / digging to drop unsupported cells; returns count for VFX scaling.
do  -- Terrain:collapseColumns
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  local fell = terrain:collapseColumns()
  lurek.log.info("collapsed " .. fell .. " cells", "terrain")
  terrain:flush()
end

--@api-stub: Terrain:solidPositions
-- Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
-- Iterate result to snapshot the terrain (e.g. spawn debris from a dug-out region).
do  -- Terrain:solidPositions
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  local positions = terrain:solidPositions()
  lurek.log.debug("solid cells=" .. #positions, "terrain")
end

--@api-stub: Terrain:toBytes
-- Serialises the terrain grid to a byte string for save/load.
-- Serialize the terrain grid; pair with lurek.fs.write to persist to a save slot.
do  -- Terrain:toBytes
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  local bytes = terrain:toBytes()
  lurek.log.info("terrain blob=" .. #bytes .. " bytes", "save")
end

--@api-stub: Terrain:loadFromBytes
-- Loads terrain cell data from bytes produced by `toBytes`.
-- Restore from a save blob; remember to flush() afterwards to rebuild colliders.
do  -- Terrain:loadFromBytes
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  local snapshot = terrain:toBytes()
  terrain:loadFromBytes(snapshot)
  terrain:flush()
end


-- â”€â”€ Cellular methods â”€â”€

--@api-stub: Cellular:setCell
-- Sets the material of a cell.
-- Use to spawn material (sand, water) at a specific cell â€” typically from a player tool.
do  -- Cellular:setCell
  local sand = lurek.physics.newCellular(128, 64)
  sand:setCell(64, 0, lurek.physics.CELL_SAND)
  sand:setCell(65, 0, lurek.physics.CELL_WATER)
end

--@api-stub: Cellular:getCell
-- Returns the material at `(cx, cy)` as an integer constant.
-- Probe before placing a barrier â€” only act when the source cell is empty.
do  -- Cellular:getCell
  local sand = lurek.physics.newCellular(128, 64)
  if sand:getCell(10, 10) == lurek.physics.CELL_AIR then
    sand:setCell(10, 10, lurek.physics.CELL_ROCK)
  end
end

--@api-stub: Cellular:step
-- Advances the simulation by one tick.
-- Drive the simulation each frame from lurek.process â€” sand falls, water spreads.
do  -- Cellular:step
  local sand = lurek.physics.newCellular(128, 64)
  function lurek.process(dt)
    sand:step()
  end
end

--@api-stub: Cellular:stepN
-- Advances the simulation by `n` ticks.
-- Use to fast-forward (e.g. 30 ticks at scene load) to settle freshly poured material.
do  -- Cellular:stepN
  local sand = lurek.physics.newCellular(128, 64)
  sand:stepN(30)
end

--@api-stub: Cellular:toImageData
-- Returns the full grid as an RGBA byte string using the default colour palette.
-- Render the grid as a texture each frame for cheap visualisation of millions of cells.
do  -- Cellular:toImageData
  local sand = lurek.physics.newCellular(128, 64)
  local rgba = sand:toImageData()
  lurek.log.debug("cellular bytes=" .. #rgba, "cell")
end

--@api-stub: Cellular:countCells
-- Counts cells of the given material type.
-- Use for HUD counters (water level, sand remaining) or victory conditions.
do  -- Cellular:countCells
  local sand = lurek.physics.newCellular(128, 64)
  local water = sand:countCells(lurek.physics.CELL_WATER)
  lurek.log.debug("water cells=" .. water, "cell")
end

--@api-stub: Cellular:findCells
-- Returns positions of all cells of the given material as an array of `{x, y}` tables.
-- Iterate to spawn dynamic bodies on every fire cell (e.g. flame particle system).
do  -- Cellular:findCells
  local sand = lurek.physics.newCellular(128, 64)
  for _, p in ipairs(sand:findCells(lurek.physics.CELL_FIRE)) do
    lurek.log.debug("fire at " .. p.x .. "," .. p.y, "cell")
  end
end

--@api-stub: Cellular:toBytes
-- Serialises the grid to a byte string.
-- Serialize for save game; pairs with loadFromBytes to round-trip the grid.
do  -- Cellular:toBytes
  local sand = lurek.physics.newCellular(128, 64)
  local blob = sand:toBytes()
  lurek.log.info("cellular blob=" .. #blob .. " bytes", "save")
end

--@api-stub: Cellular:loadFromBytes
-- Loads grid data from bytes produced by `toBytes`.
-- Restore on level load; returns false when the byte string is corrupt or wrong size.
do  -- Cellular:loadFromBytes
  local sand = lurek.physics.newCellular(128, 64)
  local blob = sand:toBytes()
  local ok = sand:loadFromBytes(blob)
  lurek.log.info("cellular reload ok=" .. tostring(ok), "save")
end


-- â”€â”€ Body methods â”€â”€

--@api-stub: Body:getId
-- Returns the body's integer ID.
-- Capture the id when you need to refer to the body across save/load or RPC boundaries.
do  -- Body:getId
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  lurek.log.debug("crate id=" .. crate:getId(), "phys")
end

--@api-stub: Body:getPosition
-- Returns the body position (x, y).
-- Read inside lurek.process to sync sprite position to physics every frame.
do  -- Body:getPosition
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  local x, y = crate:getPosition()
  lurek.log.debug("crate at " .. x .. "," .. y, "phys")
end

--@api-stub: Body:setPosition
-- Teleports the body to the given world-space position, bypassing collision.
-- Use for teleports / respawns; bypasses collision so prefer applyImpulse for normal motion.
do  -- Body:setPosition
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  player:setPosition(400, 300)
end

--@api-stub: Body:getX
-- Returns the body X position.
-- Use the single-axis form when you only need one coordinate (left/right culling check).
do  -- Body:getX
  local world = lurek.physics.newWorld(0, 9.81)
  local enemy = world:newBody(900, 200, "dynamic")
  if enemy:getX() > 800 then enemy:destroy() end
end

--@api-stub: Body:getY
-- Returns the body Y position.
-- Use to detect falling out of the world (death plane below screen).
do  -- Body:getY
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  if player:getY() > 1000 then player:setPosition(100, 200) end
end

--@api-stub: Body:getVelocity
-- Returns the body velocity (vx, vy).
-- Use to compute screen-shake intensity, motion blur, or attack-direction logic.
do  -- Body:getVelocity
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  local vx, vy = body:getVelocity()
  lurek.log.debug("v=" .. vx .. "," .. vy, "phys")
end

--@api-stub: Body:setVelocity
-- Sets the body's linear velocity in world units per second.
-- Use for character controllers that override physics each frame (top-down movement).
do  -- Body:setVelocity
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  function lurek.process(dt)
    player:setVelocity(150, 0)
  end
end

--@api-stub: Body:getAngle
-- Returns the body angle in radians.
-- Use to drive sprite rotation; angle is in radians, multiply by math.deg if needed.
do  -- Body:getAngle
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  local rad = crate:getAngle()
  lurek.log.debug("angle=" .. rad .. " rad", "phys")
end

--@api-stub: Body:setAngle
-- Sets the body angle in radians.
-- Snap orientation for cutscenes; pair with setAngularVelocity(0) to stop spin.
do  -- Body:setAngle
  local world = lurek.physics.newWorld(0, 9.81)
  local sign = world:newBody(200, 200, "static")
  sign:setAngle(math.pi / 4)
end

--@api-stub: Body:getAngularVelocity
-- Returns the angular velocity in radians/s.
-- Use to detect overspin (e.g. a top-down car drifting) and apply braking torque.
do  -- Body:getAngularVelocity
  local world = lurek.physics.newWorld(0, 9.81)
  local wheel = world:newBody(100, 200, "dynamic")
  if math.abs(wheel:getAngularVelocity()) > 30 then
    wheel:applyTorque(-5)
  end
end

--@api-stub: Body:setAngularVelocity
-- Sets the angular velocity.
-- Use to spin a turret to a target rate without applying torque every frame.
do  -- Body:setAngularVelocity
  local world = lurek.physics.newWorld(0, 9.81)
  local turret = world:newBody(200, 200, "kinematic")
  turret:setAngularVelocity(1.5)
end

--@api-stub: Body:getMass
-- Returns the body mass in kilograms used for force and impulse calculations.
-- Use to compute kinetic energy or HUD weight readouts (forklift demo).
do  -- Body:getMass
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  lurek.log.debug("crate mass=" .. crate:getMass() .. " kg", "phys")
end

--@api-stub: Body:setMass
-- Sets the body mass; affects how forces and impulses change velocity.
-- Override the mass derived from shape density â€” use for game-feel tuning.
do  -- Body:setMass
  local world = lurek.physics.newWorld(0, 9.81)
  local heavy = world:newBody(100, 200, "dynamic")
  heavy:setMass(50.0)
end

--@api-stub: Body:getType
-- Returns the body type as a string.
-- Branch on the type before applying impulses â€” only dynamic bodies respond.
do  -- Body:getType
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if body:getType() == "dynamic" then body:applyImpulse(0, -50) end
end

--@api-stub: Body:setType
-- Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
-- Promote a static prop to dynamic when destroyed (a wall becomes rubble).
do  -- Body:setType
  local world = lurek.physics.newWorld(0, 9.81)
  local wall = world:newBody(200, 200, "static")
  wall:setType("dynamic")
end

--@api-stub: Body:getWidth
-- Returns the width of this body's primary collider shape in world units.
-- Use to size a debug AABB or to centre a sprite over a body of unknown extent.
do  -- Body:getWidth
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("body width=" .. body:getWidth(), "phys")
end

--@api-stub: Body:getHeight
-- Returns the height of this body's primary collider shape in world units.
-- Pair with getWidth to drive sprite scale or bounding-box outline rendering.
do  -- Body:getHeight
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("body height=" .. body:getHeight(), "phys")
end

--@api-stub: Body:getFriction
-- Returns the body friction coefficient.
-- Compare to a target value before mutating â€” avoid wakes on bodies already at the right value.
do  -- Body:getFriction
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  if crate:getFriction() < 0.5 then crate:setFriction(0.7) end
end

--@api-stub: Body:setFriction
-- Sets the body friction coefficient.
-- Use 0.0 for ice, 0.7 for wood, 1.0+ for rubber â€” tune for the surface material.
do  -- Body:setFriction
  local world = lurek.physics.newWorld(0, 9.81)
  local ice = world:newBody(100, 200, "dynamic")
  ice:setFriction(0.05)
end

--@api-stub: Body:getRestitution
-- Returns the body restitution (bounciness).
-- Use to drive impact sound volume: bouncier collisions deserve louder thuds.
do  -- Body:getRestitution
  local world = lurek.physics.newWorld(0, 9.81)
  local ball = world:newBody(100, 200, "dynamic")
  lurek.log.debug("ball bounce=" .. ball:getRestitution(), "phys")
end

--@api-stub: Body:setRestitution
-- Sets the body restitution (bounciness).
-- 0.0 = no bounce, 1.0 = perfectly elastic; rubber balls sit around 0.8.
do  -- Body:setRestitution
  local world = lurek.physics.newWorld(0, 9.81)
  local ball = world:newBody(100, 200, "dynamic")
  ball:setRestitution(0.8)
end

--@api-stub: Body:getLayer
-- Returns the collision layer bitmask.
-- Read to verify a body is on the right collision layer (pickup vs solid).
do  -- Body:getLayer
  local world = lurek.physics.newWorld(0, 9.81)
  local pickup = world:newBody(100, 200, "dynamic")
  lurek.log.debug("layer=" .. pickup:getLayer(), "phys")
end

--@api-stub: Body:setLayer
-- Sets the collision layer bitmask.
-- Use bitmask layers (1=player, 2=enemy, 4=pickup) for filterable collision groups.
do  -- Body:setLayer
  local world = lurek.physics.newWorld(0, 9.81)
  local pickup = world:newBody(100, 200, "dynamic")
  pickup:setLayer(0x04)
end

--@api-stub: Body:getMask
-- Returns the collision mask bitmask.
-- Read to debug collision filtering â€” body sees layers in the mask, ignores others.
do  -- Body:getMask
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("mask=" .. body:getMask(), "phys")
end

--@api-stub: Body:setMask
-- Sets the collision mask bitmask.
-- Restrict who this body collides with (e.g. ghost passes through enemies but hits walls).
do  -- Body:setMask
  local world = lurek.physics.newWorld(0, 9.81)
  local ghost = world:newBody(100, 200, "dynamic")
  ghost:setMask(0x01)
end

--@api-stub: Body:applyImpulse
-- Applies a linear impulse to the body.
-- Use for instantaneous velocity changes (jump, blast knockback, projectile fire).
do  -- Body:applyImpulse
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("space") then player:applyImpulse(0, -300) end
  end
end

--@api-stub: Body:applyForce
-- Applies a continuous force to the body.
-- Use for continuous forces (thrust, wind); call every frame inside lurek.process.
do  -- Body:applyForce
  local world = lurek.physics.newWorld(0, 9.81)
  local rocket = world:newBody(100, 200, "dynamic")
  function lurek.process(dt)
    rocket:applyForce(0, -200)
  end
end

--@api-stub: Body:applyTorque
-- Applies a torque (rotational force).
-- Use to spin up a wheel or give a thrown object a tumble â€” accumulates over the step.
do  -- Body:applyTorque
  local world = lurek.physics.newWorld(0, 9.81)
  local wheel = world:newBody(100, 200, "dynamic")
  wheel:applyTorque(50.0)
end

--@api-stub: Body:applyAngularImpulse
-- Applies an angular impulse.
-- Use for one-shot spin changes (e.g. a hit that sends a top spinning).
do  -- Body:applyAngularImpulse
  local world = lurek.physics.newWorld(0, 9.81)
  local top = world:newBody(100, 200, "dynamic")
  top:applyAngularImpulse(2.5)
end

--@api-stub: Body:getGravityScale
-- Returns the per-body gravity multiplier.
-- Read for HUD (gravity boots indicator) or to verify a buoyancy effect was applied.
do  -- Body:getGravityScale
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("g-scale=" .. body:getGravityScale(), "phys")
end

--@api-stub: Body:setGravityScale
-- Sets the per-body gravity multiplier.
-- Use 0 for floaty objects (balloons, magic), 2 for heavy ones (anvils).
do  -- Body:setGravityScale
  local world = lurek.physics.newWorld(0, 9.81)
  local balloon = world:newBody(100, 200, "dynamic")
  balloon:setGravityScale(-0.5)
end

--@api-stub: Body:isFixedRotation
-- Returns whether rotation is locked.
-- Branch before setting; locking rotation again is a no-op but force adjustments are not.
do  -- Body:isFixedRotation
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  if not player:isFixedRotation() then player:setFixedRotation(true) end
end

--@api-stub: Body:setFixedRotation
-- Locks or unlocks rotation.
-- Lock player / NPC bodies upright so they do not topple over after a hit.
do  -- Body:setFixedRotation
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  player:setFixedRotation(true)
end

--@api-stub: Body:getLinearDamping
-- Returns the linear damping coefficient.
-- Read for tuning UI; higher damping bleeds velocity faster (drag).
do  -- Body:getLinearDamping
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("damping=" .. body:getLinearDamping(), "phys")
end

--@api-stub: Body:setLinearDamping
-- Sets the linear damping coefficient.
-- Use 0 for vacuum, 0.5 for air, 5+ for water â€” simulates fluid drag without a zone.
do  -- Body:setLinearDamping
  local world = lurek.physics.newWorld(0, 9.81)
  local fish = world:newBody(100, 200, "dynamic")
  fish:setLinearDamping(2.0)
end

--@api-stub: Body:getAngularDamping
-- Returns the angular damping coefficient.
-- Read to debug bodies that keep spinning forever â€” usually damping=0 is the cause.
do  -- Body:getAngularDamping
  local world = lurek.physics.newWorld(0, 9.81)
  local top = world:newBody(100, 200, "dynamic")
  lurek.log.debug("ang damping=" .. top:getAngularDamping(), "phys")
end

--@api-stub: Body:setAngularDamping
-- Sets the angular damping coefficient.
-- Apply moderate damping (0.5) to thrown objects so they settle within a few seconds.
do  -- Body:setAngularDamping
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  crate:setAngularDamping(0.5)
end

--@api-stub: Body:isBullet
-- Returns whether CCD is enabled.
-- Check before relying on CCD-only logic (e.g. armour-piercing rules).
do  -- Body:isBullet
  local world = lurek.physics.newWorld(0, 9.81)
  local proj = world:newBody(100, 200, "dynamic")
  if proj:isBullet() then lurek.log.debug("CCD on", "phys") end
end

--@api-stub: Body:setBullet
-- Enables or disables continuous collision detection (CCD) for fast-moving bodies.
-- Enable on bullets, arrows, and high-velocity debris to prevent tunnelling.
do  -- Body:setBullet
  local world = lurek.physics.newWorld(0, 9.81)
  local arrow = world:newBody(100, 200, "dynamic")
  arrow:setBullet(true)
end

--@api-stub: Body:isSleepingAllowed
-- Returns whether the body can sleep.
-- Read before disabling â€” gameplay-critical bodies should never sleep.
do  -- Body:isSleepingAllowed
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if body:isSleepingAllowed() then body:setSleepingAllowed(false) end
end

--@api-stub: Body:setSleepingAllowed
-- Sets whether the body can sleep.
-- Disable on the player and active enemies; allow on world clutter to save CPU.
do  -- Body:setSleepingAllowed
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  player:setSleepingAllowed(false)
end

--@api-stub: Body:destroy
-- Removes this body from the world.
-- Call on entity death; the underlying world body is removed and id becomes invalid.
do  -- Body:destroy
  local world = lurek.physics.newWorld(0, 9.81)
  local enemy = world:newBody(100, 200, "dynamic")
  enemy:destroy()
end

--@api-stub: Body:isSleeping
-- Returns true if this body is currently sleeping (inactive).
-- Use to gate per-frame work (AI, sound) on inactive bodies â€” saves frame budget.
do  -- Body:isSleeping
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if not body:isSleeping() then lurek.log.debug("active", "phys") end
end

--@api-stub: Body:wakeUp
-- Forcibly wakes up this body.
-- Call before applyForce / setVelocity if a body might be sleeping; otherwise the call is ignored.
do  -- Body:wakeUp
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  body:wakeUp()
  body:applyImpulse(0, -100)
end

--@api-stub: Body:sleep
-- Puts this body to sleep immediately.
-- Force-sleep stationary debris piles to remove them from the active solver set.
do  -- Body:sleep
  local world = lurek.physics.newWorld(0, 9.81)
  local rubble = world:newBody(100, 200, "dynamic")
  rubble:sleep()
end


-- â”€â”€ PhysicsShape methods â”€â”€

--@api-stub: PhysicsShape:getType
-- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
-- Branch on the type string when serialising or rendering shape-specific debug overlays.
do  -- PhysicsShape:getType
  local shape = lurek.physics.newCircleShape(16)
  if shape:getType() == "circle" then
    lurek.log.debug("ball-shape r=" .. shape:getRadius(), "phys")
  end
end

--@api-stub: PhysicsShape:getRadius
-- Returns the radius.
-- Only meaningful for circle shapes; returns 0 (or fails) on rectangles and polygons.
do  -- PhysicsShape:getRadius
  local ball = lurek.physics.newCircleShape(16)
  lurek.log.debug("radius=" .. ball:getRadius(), "phys")
end

--@api-stub: PhysicsShape:getBoundingBox
-- Returns the axis-aligned bounding box (x1, y1, x2, y2).
-- Use to size an outline draw or to test broad-phase overlap before doing a precise check.
do  -- PhysicsShape:getBoundingBox
  local crate_shape = lurek.physics.newRectangleShape(64, 32)
  local x1, y1, x2, y2 = crate_shape:getBoundingBox()
  lurek.log.debug("aabb " .. x1 .. "," .. y1 .. "->" .. x2 .. "," .. y2, "phys")
end

--@api-stub: PhysicsShape:setDensity
-- Sets the density for this shape (used when attaching to a body).
-- Set BEFORE attachShape â€” once attached, density does not retro-actively re-derive mass.
do  -- PhysicsShape:setDensity
  local shape = lurek.physics.newRectangleShape(32, 32)
  shape:setDensity(2.0)
end

--@api-stub: PhysicsShape:setFriction
-- Sets the friction coefficient.
-- Use to make ice (0.05), wood (0.7), or rubber (1.2) shape-by-shape.
do  -- PhysicsShape:setFriction
  local shape = lurek.physics.newRectangleShape(32, 32)
  shape:setFriction(0.7)
end

--@api-stub: PhysicsShape:setRestitution
-- Sets the restitution (bounciness) coefficient.
-- 0.0 for no bounce, 0.8 for rubber ball; usually paired with low friction for physics toys.
do  -- PhysicsShape:setRestitution
  local ball = lurek.physics.newCircleShape(16)
  ball:setRestitution(0.85)
end

--@api-stub: PhysicsShape:setSensor
-- Sets whether this shape is a sensor (non-colliding trigger).
-- Use for trigger volumes (pickup zones, kill planes) â€” fires events but does not block.
do  -- PhysicsShape:setSensor
  local trigger = lurek.physics.newRectangleShape(64, 64)
  trigger:setSensor(true)
end

--@api-stub: PhysicsShape:destroy
-- Releases this shape handle (GC handles cleanup).
-- Manual destroy is rarely needed; GC drops the shape when no Lua / body holds a reference.
do  -- PhysicsShape:destroy
  local shape = lurek.physics.newRectangleShape(32, 32)
  shape:destroy()
  shape = nil --[[@type any]]
end

--@api-stub: lurek.physics.testAABB
-- Test overlap between two axis-aligned bounding boxes.
-- Returns true if the boxes overlap; false otherwise.
do  -- lurek.physics.testAABB
  if lurek.physics.testAABB then
    local hit = lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 20, 20)
    lurek.log.debug("AABB overlap=" .. tostring(hit), "physics")
  end
end

--@api-stub: lurek.physics.testCircles
-- Test overlap between two circles defined by centre and radius.
-- Returns true if the circles overlap.
do  -- lurek.physics.testCircles
  if lurek.physics.testCircles then
    local hit = lurek.physics.testCircles(0, 0, 5, 3, 3, 5)
    lurek.log.debug("circles overlap=" .. tostring(hit), "physics")
  end
end

--@api-stub: lurek.physics.testCircleAABB
-- Test overlap between a circle and an AABB.
-- Returns true if the shapes overlap.
do  -- lurek.physics.testCircleAABB
  if lurek.physics.testCircleAABB then
    local hit = lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10)
    lurek.log.debug("circle-AABB overlap=" .. tostring(hit), "physics")
  end
end

--@api-stub: lurek.physics.testPoint
-- Test whether a point lies inside an AABB.
-- Returns true if the point is within the box.
do  -- lurek.physics.testPoint
  if lurek.physics.testPoint then
    local hit = lurek.physics.testPoint(5, 5, 0, 0, 10, 10)
    lurek.log.debug("point-in-AABB=" .. tostring(hit), "physics")
  end
end

--@api-stub: World:addDistanceJoint
-- Creates a distance joint keeping two bodies at a fixed separation.
-- damping and frequency control spring-like oscillation; 0 damping = rigid rod.
do  -- World:addDistanceJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(200, 100, "dynamic")
  local jid = world:addDistanceJoint(a:getId(), b:getId(), 100, 100, 200, 100, 100)
  lurek.log.info("distance joint: " .. jid, "physics")
end

--@api-stub: World:addFixture
-- Attaches a shape fixture to an existing body with friction and restitution.
-- Multiple fixtures give a body a composite collision shape.
do  -- World:addFixture
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local fid = world:addFixture(b:getId(), "circle", {radius=16, friction=0.4, restitution=0.3})
  lurek.log.info("fixture id: " .. fid, "physics")
end

--@api-stub: World:addFrictionJoint
-- Creates a friction joint that resists relative linear and angular motion.
-- maxForce and maxTorque cap the damping; use for ice-skating or surface drag.
do  -- World:addFrictionJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(100, 100, "static")
  local jid = world:addFrictionJoint(a:getId(), b:getId(), 100, 100, 50, 10)
  lurek.log.info("friction joint: " .. jid, "physics")
end

--@api-stub: World:addGearJoint
-- Links two revolute or prismatic joints so their motion stays coupled by a ratio.
-- Simulates gear trains; both joints must already exist in the same world.
do  -- World:addGearJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "dynamic")
  local b = world:newBody(200, 200, "dynamic")
  local c = world:newBody(150, 200, "static")
  local j1 = world:addRevoluteJoint(c:getId(), a:getId(), 100, 200)
  local j2 = world:addRevoluteJoint(c:getId(), b:getId(), 200, 200)
  local jid = world:addGearJoint(a:getId(), b:getId(), 150, 200)
  lurek.log.info("gear joint: " .. jid, "physics")
end

--@api-stub: World:addMotorJoint
-- Creates a motor joint that drives one body to match the position/angle of another.
-- maxForce and maxTorque control how aggressively the motor corrects offset.
do  -- World:addMotorJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(200, 200, "dynamic")
  local jid = world:addMotorJoint(a:getId(), b:getId(), 0.3)
  lurek.log.info("motor joint: " .. jid, "physics")
end

--@api-stub: World:addMouseJoint
-- Creates a spring-like joint from a body to a moving screen position (drag-and-drop).
-- maxForce prevents the joint from exploding when the target moves quickly.
do  -- World:addMouseJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local jid = world:addMouseJoint(b:getId(), 200, 200, 1000)
  lurek.log.info("mouse joint: " .. jid, "physics")
end

--@api-stub: World:addPrismaticJoint
-- Creates a prismatic joint allowing translation along one axis only.
-- Use for sliding doors, pistons, or elevator platforms.
do  -- World:addPrismaticJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 300, "static")
  local b = world:newBody(100, 200, "dynamic")
  local jid = world:addPrismaticJoint(a:getId(), b:getId(), 100, 300, 0, -1)
  lurek.log.info("prismatic joint: " .. jid, "physics")
end

--@api-stub: World:addPulleyJoint
-- Creates a pulley joint constraining two bodies through a fixed rope length.
-- lengthA + lengthB == total rope; a ratio != 1 simulates a block-and-tackle.
do  -- World:addPulleyJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "dynamic")
  local b = world:newBody(300, 200, "dynamic")
  local jid = world:addPulleyJoint(a:getId(), b:getId(), 100, 100)
  lurek.log.info("pulley joint: " .. jid, "physics")
end

--@api-stub: World:addRevoluteJoint
-- Creates a revolute (hinge) joint at a world-space anchor point.
-- Bodies can rotate freely about the anchor; add limits to constrain the angle.
do  -- World:addRevoluteJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local door = world:newBody(200, 200, "dynamic")
  local wall  = world:newBody(200, 200, "static")
  local jid = world:addRevoluteJoint(wall:getId(), door:getId(), 200, 200)
  lurek.log.info("revolute joint: " .. jid, "physics")
end

--@api-stub: World:addRopeJoint
-- Creates a rope joint that prevents two bodies from exceeding a max distance.
-- Slack means bodies can be closer; maxLength is the hard upper limit.
do  -- World:addRopeJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(100, 200, "dynamic")
  local jid = world:addRopeJoint(a:getId(), b:getId(), 100, 100, 100, 200, 120)
  lurek.log.info("rope joint: " .. jid, "physics")
end

--@api-stub: World:addWeldJoint
-- Welds two bodies together at their current relative positions.
-- frequency and damping add slight spring flexibility to prevent solver jitter.
do  -- World:addWeldJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(150, 200, "dynamic")
  local b = world:newBody(170, 200, "dynamic")
  local jid = world:addWeldJoint(a:getId(), b:getId(), 160, 200)
  lurek.log.info("weld joint: " .. jid, "physics")
end

--@api-stub: World:addWheelJoint
-- Creates a wheel joint for vehicle suspension: translation + rotation + motor.
-- Adjust frequency and damping to tune suspension stiffness and bounce.
do  -- World:addWheelJoint
  local world = lurek.physics.newWorld(0, 9.81)
  local chassis = world:newBody(200, 200, "dynamic")
  local wheel   = world:newBody(200, 240, "dynamic")
  local jid = world:addWheelJoint(chassis:getId(), wheel:getId(), 200, 240, 0, -1)
  lurek.log.info("wheel joint: " .. jid, "physics")
end

--@api-stub: Body:applyForceAtPoint
-- Applies a force at an off-centre world-space point, generating torque.
-- Use for realistic drag, thrust, or projectile impact forces.
do  -- Body:applyForceAtPoint
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  b:applyForceAtPoint(100, 0, 220, 200)
  lurek.log.info("force at point applied", "physics")
end

--@api-stub: World:drawDebug
-- Renders physics shapes, joints, and AABBs using the engine's debug draw API.
-- Call inside lurek.draw() to overlay the physics debug visualisation.
do  -- World:drawDebug
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(200, 200, "static")
  local debug_img = lurek.image.newImageData(400, 400)
  function lurek.draw()
    world:drawDebug(debug_img)
  end
  lurek.log.info("drawDebug hooked", "physics")
end

--@api-stub: Terrain:fillCircle
-- Fills a circular region of the destructible terrain with a given cell value.
-- Used to create craters; value=0 makes cells empty (air), 1=solid.
do  -- Terrain:fillCircle
  local _world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 64, 8, _world)
  terrain:fillAll(true)
  terrain:fillCircle(32, 32, 10, false)
  terrain:flush()
  lurek.log.info("terrain crater dug", "physics")
end

--@api-stub: Cellular:fillCircle
-- Fills a circular region of a cellular automaton grid with a given state value.
-- Useful for initialising cave seeds or spawning growth patches.
do  -- Cellular:fillCircle
  local ca = lurek.physics.newCellular(64, 64)
  ca:fillCircle(32, 32, 20, 1)
  lurek.log.info("cellular circle filled", "physics")
end

--@api-stub: Terrain:fillRect
-- Fills a rectangular region of the destructible terrain with the given cell value.
-- value=1 places solid material; value=0 removes it.
do  -- Terrain:fillRect
  local _world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 64, 8, _world)
  terrain:fillRect(10, 10, 40, 40, true)
  terrain:flush()
  lurek.log.info("terrain rect filled", "physics")
end

--@api-stub: Cellular:fillRect
-- Fills a rectangular region of a cellular automaton grid with a given state.
-- Use to create initial conditions for cave generation or life simulations.
do  -- Cellular:fillRect
  local ca = lurek.physics.newCellular(32, 32)
  ca:fillRect(4, 4, 28, 28, 1)
  lurek.log.info("cellular rect filled", "physics")
end

--@api-stub: World:newChainBody
-- Creates a chain-shape body from a sequence of vertices.
-- Chain shapes are one-sided and ideal for long terrain contours or platforms.
do  -- World:newChainBody
  local world = lurek.physics.newWorld(0, 9.81)
  local verts = {0,400, 200,380, 400,400, 600,390, 800,400}
  local b = world:newChainBody(0, 0, verts, false, "static")
  lurek.log.info("chain body: " .. b:getId(), "physics")
end

--@api-stub: World:newCircleBody
-- Creates a circle-shaped body at (x, y) with the given radius and type.
-- Faster and more stable than polygon approximations for round objects.
do  -- World:newCircleBody
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newCircleBody(300, 200, 20, "dynamic")
  lurek.log.info("circle body: " .. b:getId(), "physics")
end

--@api-stub: World:newEdgeBody
-- Creates a single one-sided edge between two points as a static body.
-- Use for thin walls, platforms, or invisible boundaries.
do  -- World:newEdgeBody
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newEdgeBody(0, 0, 0, 400, 800, 400, "static")
  lurek.log.info("edge body: " .. b:getId(), "physics")
end

--@api-stub: World:newPolygonBody
-- Creates a convex polygon body from a vertex table (max 8 vertices).
-- Vertices must be in counter-clockwise order; Box2D auto-computes the centroid.
do  -- World:newPolygonBody
  local world = lurek.physics.newWorld(0, 9.81)
  local verts = {-20,-10, 20,-10, 20,10, -20,10}
  local b = world:newPolygonBody(300, 200, verts, "dynamic")
  lurek.log.info("polygon body: " .. b:getId(), "physics")
end

--@api-stub: World:queryAABB
-- Returns all body IDs whose fixtures overlap the given axis-aligned bounding box.
-- Use for cheap broad-phase spatial queries before narrow-phase shape tests.
do  -- World:queryAABB
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(100, 100, 20, "static")
  local hits = world:queryAABB(80, 80, 130, 130)
  lurek.log.info("AABB hits: " .. #hits, "physics")
end

--@api-stub: World:raycast
-- Fires a ray and returns the first hit body id, normal, and fraction.
-- Returns nil if no body is hit; fraction is in [0,1] along the ray.
do  -- World:raycast
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(200, 200, 30, "static")
  local id, nx, ny, frac = world:raycast(0, 200, 400, 200)
  lurek.log.info("raycast hit: " .. tostring(id), "physics")
end

--@api-stub: World:raycastAll
-- Returns all bodies hit by a ray as a table of {id, normal, fraction} records.
-- Sorted by fraction (nearest first); useful for piercing shots.
do  -- World:raycastAll
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(100, 200, 20, "static")
  world:newCircleBody(300, 200, 20, "static")
  local hits = world:raycastAll(0, 200, 1, 0, 400)
  lurek.log.info("all hits: " .. #hits, "physics")
end

--@api-stub: World:raycastClosest
-- Returns only the closest body hit by a ray as {id, normal, fraction}.
-- Faster than raycastAll when only the nearest obstacle matters.
do  -- World:raycastClosest
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(150, 200, 20, "static")
  local hit = world:raycastClosest(0, 200, 1, 0, 400)
  lurek.log.info("closest hit: " .. tostring(hit and hit.id), "physics")
end

--@api-stub: Zone:setAngularDampingOverride
-- Sets an angular damping coefficient applied to all bodies inside this zone.
-- Override is only active while the body remains within the zone boundary.
do  -- Zone:setAngularDampingOverride
  local world = lurek.physics.newWorld(0, 9.81)
  local z = world:addZone(100, 100, 300, 300)
  z:setAngularDampingOverride(5.0)
  lurek.log.info("zone angular damping set", "physics")
end

--@api-stub: World:setBodyData
-- Attaches arbitrary Lua data to a body for retrieval in collision callbacks.
-- Common use: store the entity id or component table that owns the body.
do  -- World:setBodyData
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  world:setBodyData(b:getId(), {entityId=42, type="player"})
  lurek.log.info("body data set", "physics")
end

--@api-stub: World:setBodyOneWay
-- Marks a body as a one-way platform: only collides from one direction.
-- Pass the allowed normal direction (0,-1 = top surface; 0,1 = bottom).
do  -- World:setBodyOneWay
  local world = lurek.physics.newWorld(0, 9.81)
  local platform = world:newBody(400, 300, "static")
  world:setBodyOneWay(platform:getId(), 0, -1)
  lurek.log.info("one-way platform set", "physics")
end

--@api-stub: World:setFixtureFriction
-- Sets the friction coefficient on an existing fixture by its id.
-- Values in [0,1]; 0=ice, 1=rubber; default is 0.5.
do  -- World:setFixtureFriction
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local fid = world:addFixture(b:getId(), "box", {width=32,height=32})
  world:setFixtureFriction(b:getId(), fid, 0.1)
  lurek.log.info("fixture friction set", "physics")
end

--@api-stub: World:setFixtureRestitution
-- Sets the restitution (bounciness) on an existing fixture.
-- 0 = completely inelastic; 1 = perfectly elastic bounce.
do  -- World:setFixtureRestitution
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local fid = world:addFixture(b:getId(), "circle", {radius=16})
  world:setFixtureRestitution(b:getId(), fid, 0.8)
  lurek.log.info("restitution set", "physics")
end

--@api-stub: World:setFixtureSensor
-- Marks a fixture as a sensor so it receives collision events but exerts no force.
-- Sensors detect overlaps without preventing movement; ideal for trigger zones.
do  -- World:setFixtureSensor
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "static")
  local fid = world:addFixture(b:getId(), "circle", {radius=40})
  world:setFixtureSensor(b:getId(), fid, true)
  lurek.log.info("sensor fixture set", "physics")
end

--@api-stub: Zone:setGravityPoint
-- Sets gravity in the zone to pull bodies toward a point attractor.
-- strength > 0 pulls inward (planet gravity); < 0 pushes outward (explosion).
do  -- Zone:setGravityPoint
  local world = lurek.physics.newWorld(0, 9.81)
  local z = world:addZone(0, 0, 800, 600)
  z:setGravityPoint(400, 300, 500)
  lurek.log.info("gravity point set", "physics")
end

--@api-stub: Zone:setGravityRepulsor
-- Sets gravity in the zone to push bodies away from a repulsor point.
-- strength controls force magnitude; useful for explosive force zones.
do  -- Zone:setGravityRepulsor
  local world = lurek.physics.newWorld(0, 9.81)
  local z = world:addZone(200, 200, 600, 400)
  z:setGravityRepulsor(400, 300, 300)
  lurek.log.info("gravity repulsor set", "physics")
end

--@api-stub: World:setJointLimits
-- Sets the angular or linear limits for an existing constrained joint.
-- For revolute joints: min/max are angles in radians; for prismatic: metres.
do  -- World:setJointLimits
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "static")
  local b = world:newBody(100, 100, "dynamic")
  local jid = world:addRevoluteJoint(a:getId(), b:getId(), 100, 200)
  world:setJointLimits(jid, -math.pi/4, math.pi/4)
  lurek.log.info("joint limits set", "physics")
end

--@api-stub: World:setJointLimitsEnabled
-- Enables or disables the angular/linear limits on an existing joint.
-- Toggle without removing the joint to implement retractable constraints.
do  -- World:setJointLimitsEnabled
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "static")
  local b = world:newBody(100, 100, "dynamic")
  local jid = world:addRevoluteJoint(a:getId(), b:getId(), 100, 200)
  world:setJointLimitsEnabled(jid, true)
  lurek.log.info("joint limits enabled", "physics")
end

--@api-stub: World:setJointMotorSpeed
-- Sets the motor speed for a revolute or prismatic joint motor.
-- Positive and negative values drive in opposite directions.
do  -- World:setJointMotorSpeed
  local world = lurek.physics.newWorld(0, 9.81)
  local axle = world:newBody(200, 200, "static")
  local wheel = world:newBody(200, 240, "dynamic")
  local jid = world:addRevoluteJoint(axle:getId(), wheel:getId(), 200, 220)
  world:setJointMotorSpeed(jid, 2.0)
  lurek.log.info("motor speed: 2.0 rad/s", "physics")
end

--@api-stub: World:setMouseJointTarget
-- Updates the target world position for an existing mouse joint each frame.
-- Call inside lurek.process(dt) with the current mouse world coordinates.
do  -- World:setMouseJointTarget
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(300, 200, "dynamic")
  local jid = world:addMouseJoint(b:getId(), 300, 200, 2000)
  world:setMouseJointTarget(jid, 350, 250)
  lurek.log.info("mouse joint target updated", "physics")
end

--@api-stub: Terrain:spawnDebris
-- Spawns dynamic debris bodies for cells removed from the terrain.
-- Returns a table of new body ids; debris bodies settle under gravity.
do  -- Terrain:spawnDebris
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(32, 32, 8, world)
  terrain:fillAll(true)
  terrain:fillCircle(16, 16, 6, false)
  terrain:flush()
  local positions = terrain:solidPositions()
  local debris = terrain:spawnDebris(positions, 1.0, 0.5)
  lurek.log.info("debris count: " .. #debris, "physics")
end

--@api-stub: World:stepFixed
-- Advances the physics world by a fixed timestep with an optional substep count.
-- Use instead of step() for deterministic simulations requiring fixed-rate updates.
do  -- World:stepFixed
  local world = lurek.physics.newWorld(0, 9.81)
  world:stepFixed(1/60, 6, 2)
  lurek.log.info("fixed step done", "physics")
end

--@api-stub: Terrain:toImageData
-- Converts the terrain cell grid to an ImageData for rendering or saving.
-- Solid cells are opaque white; empty cells are transparent black.
do  -- Terrain:toImageData
  local _w = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(32, 32, 8, _w)
  terrain:fillAll(true)
  terrain:fillCircle(16, 16, 8, false)
  terrain:flush()
  local bytes = terrain:toImageData(255, 255, 255, 0, 0, 0)
  lurek.log.info("terrain image: " .. #bytes .. " bytes", "physics")
end

--@api-stub: Cellular:toImageDataRegion
-- Converts a rectangular sub-region of the cellular grid to an ImageData.
-- More efficient than toImageData() when only part of the grid needs rendering.
do  -- Cellular:toImageDataRegion
  local ca = lurek.physics.newCellular(64, 64)
  ca:fillRect(0, 0, 63, 63, 1)
  local img = ca:toImageDataRegion(10, 10, 40, 40)
  lurek.log.info("region img: " .. #img .. " bytes", "physics")
end

-- =============================================================================
-- STUBS: 12 uncovered lurek.physics API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Body methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Body:type -----------------------------------------------------
--@api-stub: Body:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- body_stub:type()  -- -> string
-- (replace body_stub with your real Body instance above)

-- ---- Stub: Body:typeOf ---------------------------------------------------
--@api-stub: Body:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- body_stub:typeOf("hero")  -- -> boolean
-- (replace body_stub with your real Body instance above)

-- -----------------------------------------------------------------------------
-- Cellular methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Cellular:type -------------------------------------------------
--@api-stub: Cellular:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- cellular_stub:type()  -- -> string
-- (replace cellular_stub with your real Cellular instance above)

-- ---- Stub: Cellular:typeOf -----------------------------------------------
--@api-stub: Cellular:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- cellular_stub:typeOf("hero")  -- -> boolean
-- (replace cellular_stub with your real Cellular instance above)

-- -----------------------------------------------------------------------------
-- PhysicsShape methods
-- -----------------------------------------------------------------------------

-- ---- Stub: PhysicsShape:type ---------------------------------------------
--@api-stub: PhysicsShape:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- physicsShape_stub:type()  -- -> string
-- (replace physicsShape_stub with your real PhysicsShape instance above)

-- ---- Stub: PhysicsShape:typeOf -------------------------------------------
--@api-stub: PhysicsShape:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- physicsShape_stub:typeOf("hero")  -- -> boolean
-- (replace physicsShape_stub with your real PhysicsShape instance above)

-- -----------------------------------------------------------------------------
-- Terrain methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Terrain:type --------------------------------------------------
--@api-stub: Terrain:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- terrain_stub:type()  -- -> string
-- (replace terrain_stub with your real Terrain instance above)

-- ---- Stub: Terrain:typeOf ------------------------------------------------
--@api-stub: Terrain:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- terrain_stub:typeOf("hero")  -- -> boolean
-- (replace terrain_stub with your real Terrain instance above)

-- -----------------------------------------------------------------------------
-- World methods
-- -----------------------------------------------------------------------------

-- ---- Stub: World:type ----------------------------------------------------
--@api-stub: World:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- world_stub:type()  -- -> string
-- (replace world_stub with your real World instance above)

-- ---- Stub: World:typeOf --------------------------------------------------
--@api-stub: World:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- world_stub:typeOf("hero")  -- -> boolean
-- (replace world_stub with your real World instance above)

-- -----------------------------------------------------------------------------
-- Zone methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Zone:type -----------------------------------------------------
--@api-stub: Zone:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- zone_stub:type()  -- -> string
-- (replace zone_stub with your real Zone instance above)

-- ---- Stub: Zone:typeOf ---------------------------------------------------
--@api-stub: Zone:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- zone_stub:typeOf("hero")  -- -> boolean
-- (replace zone_stub with your real Zone instance above)

-- =============================================================================
-- STUBS: 12 uncovered lurek.physics API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LBody methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBody:type ----------------------------------------------------
--@api-stub: LBody:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:type()  -- -> string
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:typeOf --------------------------------------------------
--@api-stub: LBody:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:typeOf("hero")  -- -> boolean
-- (replace lBody_stub with your real LBody instance above)

-- -----------------------------------------------------------------------------
-- LCellular methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCellular:type ------------------------------------------------
--@api-stub: LCellular:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:type()  -- -> string
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:typeOf ----------------------------------------------
--@api-stub: LCellular:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:typeOf("hero")  -- -> boolean
-- (replace lCellular_stub with your real LCellular instance above)

-- -----------------------------------------------------------------------------
-- LPhysicsShape methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPhysicsShape:type --------------------------------------------
--@api-stub: LPhysicsShape:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:type()  -- -> string
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- ---- Stub: LPhysicsShape:typeOf ------------------------------------------
--@api-stub: LPhysicsShape:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:typeOf("hero")  -- -> boolean
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- -----------------------------------------------------------------------------
-- LTerrain methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTerrain:type -------------------------------------------------
--@api-stub: LTerrain:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:type()  -- -> string
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:typeOf -----------------------------------------------
--@api-stub: LTerrain:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:typeOf("hero")  -- -> boolean
-- (replace lTerrain_stub with your real LTerrain instance above)

-- -----------------------------------------------------------------------------
-- LWorld methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LWorld:type ---------------------------------------------------
--@api-stub: LWorld:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:type()  -- -> string
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:typeOf -------------------------------------------------
--@api-stub: LWorld:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:typeOf("hero")  -- -> boolean
-- (replace lWorld_stub with your real LWorld instance above)

-- -----------------------------------------------------------------------------
-- LZone methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LZone:type ----------------------------------------------------
--@api-stub: LZone:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:type()  -- -> string
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:typeOf --------------------------------------------------
--@api-stub: LZone:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:typeOf("hero")  -- -> boolean
-- (replace lZone_stub with your real LZone instance above)

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

-- ---- Stub: LBody:getId ---------------------------------------------------
--@api-stub: LBody:getId
-- Returns the body's integer ID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getId()  -- -> integer
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getPosition ---------------------------------------------
--@api-stub: LBody:getPosition
-- Returns the body position (x, y).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getPosition()  -- -> number, number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setPosition ---------------------------------------------
--@api-stub: LBody:setPosition
-- Teleports the body to the given world-space position, bypassing collision.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setPosition(0.0, 0.0)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getX ----------------------------------------------------
--@api-stub: LBody:getX
-- Returns the body X position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getX()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getY ----------------------------------------------------
--@api-stub: LBody:getY
-- Returns the body Y position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getY()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getVelocity ---------------------------------------------
--@api-stub: LBody:getVelocity
-- Returns the body velocity (vx, vy).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getVelocity()  -- -> number, number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setVelocity ---------------------------------------------
--@api-stub: LBody:setVelocity
-- Sets the body's linear velocity in world units per second.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setVelocity(vx, vy)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getAngle ------------------------------------------------
--@api-stub: LBody:getAngle
-- Returns the body angle in radians.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getAngle()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setAngle ------------------------------------------------
--@api-stub: LBody:setAngle
-- Sets the body angle in radians.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setAngle(0.0)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getAngularVelocity --------------------------------------
--@api-stub: LBody:getAngularVelocity
-- Returns the angular velocity in radians/s.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getAngularVelocity()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setAngularVelocity --------------------------------------
--@api-stub: LBody:setAngularVelocity
-- Sets the angular velocity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setAngularVelocity(omega)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getMass -------------------------------------------------
--@api-stub: LBody:getMass
-- Returns the body mass in kilograms used for force and impulse calculations.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getMass()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setMass -------------------------------------------------
--@api-stub: LBody:setMass
-- Sets the body mass; affects how forces and impulses change velocity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setMass(mass)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getType -------------------------------------------------
--@api-stub: LBody:getType
-- Returns the body type as a string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getType()  -- -> string
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setType -------------------------------------------------
--@api-stub: LBody:setType
-- Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setType(bt)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getWidth ------------------------------------------------
--@api-stub: LBody:getWidth
-- Returns the width of this body's primary collider shape in world units.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getWidth()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getHeight -----------------------------------------------
--@api-stub: LBody:getHeight
-- Returns the height of this body's primary collider shape in world units.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getHeight()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getFriction ---------------------------------------------
--@api-stub: LBody:getFriction
-- Returns the body friction coefficient.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getFriction()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setFriction ---------------------------------------------
--@api-stub: LBody:setFriction
-- Sets the body friction coefficient.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setFriction(friction)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getRestitution ------------------------------------------
--@api-stub: LBody:getRestitution
-- Returns the body restitution (bounciness).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getRestitution()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setRestitution ------------------------------------------
--@api-stub: LBody:setRestitution
-- Sets the body restitution (bounciness).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setRestitution(restitution)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getLayer ------------------------------------------------
--@api-stub: LBody:getLayer
-- Returns the collision layer bitmask.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getLayer()  -- -> integer
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setLayer ------------------------------------------------
--@api-stub: LBody:setLayer
-- Sets the collision layer bitmask.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setLayer(1)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getMask -------------------------------------------------
--@api-stub: LBody:getMask
-- Returns the collision mask bitmask.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getMask()  -- -> integer
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setMask -------------------------------------------------
--@api-stub: LBody:setMask
-- Sets the collision mask bitmask.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setMask(mask)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:applyImpulse --------------------------------------------
--@api-stub: LBody:applyImpulse
-- Applies a linear impulse to the body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:applyImpulse(ix, iy)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:applyForce ----------------------------------------------
--@api-stub: LBody:applyForce
-- Applies a continuous force to the body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:applyForce(fx, fy)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:applyTorque ---------------------------------------------
--@api-stub: LBody:applyTorque
-- Applies a torque (rotational force).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:applyTorque(torque)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:applyForceAtPoint ---------------------------------------
--@api-stub: LBody:applyForceAtPoint
-- Applies a force at a specific world-space point.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:applyForceAtPoint(fx, fy, px, py)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:applyAngularImpulse -------------------------------------
--@api-stub: LBody:applyAngularImpulse
-- Applies an angular impulse.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:applyAngularImpulse(impulse)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getGravityScale -----------------------------------------
--@api-stub: LBody:getGravityScale
-- Returns the per-body gravity multiplier.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getGravityScale()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setGravityScale -----------------------------------------
--@api-stub: LBody:setGravityScale
-- Sets the per-body gravity multiplier.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setGravityScale(1.0)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:isFixedRotation -----------------------------------------
--@api-stub: LBody:isFixedRotation
-- Returns whether rotation is locked.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:isFixedRotation()  -- -> boolean
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setFixedRotation ----------------------------------------
--@api-stub: LBody:setFixedRotation
-- Locks or unlocks rotation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setFixedRotation(fixed)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getLinearDamping ----------------------------------------
--@api-stub: LBody:getLinearDamping
-- Returns the linear damping coefficient.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getLinearDamping()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setLinearDamping ----------------------------------------
--@api-stub: LBody:setLinearDamping
-- Sets the linear damping coefficient.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setLinearDamping(damping)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:getAngularDamping ---------------------------------------
--@api-stub: LBody:getAngularDamping
-- Returns the angular damping coefficient.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:getAngularDamping()  -- -> number
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setAngularDamping ---------------------------------------
--@api-stub: LBody:setAngularDamping
-- Sets the angular damping coefficient.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setAngularDamping(damping)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:isBullet ------------------------------------------------
--@api-stub: LBody:isBullet
-- Returns whether CCD is enabled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:isBullet()  -- -> boolean
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setBullet -----------------------------------------------
--@api-stub: LBody:setBullet
-- Enables or disables continuous collision detection (CCD) for fast-moving bodies.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setBullet(bullet)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:isSleepingAllowed ---------------------------------------
--@api-stub: LBody:isSleepingAllowed
-- Returns whether the body can sleep.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:isSleepingAllowed()  -- -> boolean
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:setSleepingAllowed --------------------------------------
--@api-stub: LBody:setSleepingAllowed
-- Sets whether the body can sleep.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:setSleepingAllowed(allowed)
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:destroy -------------------------------------------------
--@api-stub: LBody:destroy
-- Removes this body from the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:destroy()
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:isSleeping ----------------------------------------------
--@api-stub: LBody:isSleeping
-- Returns true if this body is currently sleeping (inactive).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:isSleeping()  -- -> boolean
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:wakeUp --------------------------------------------------
--@api-stub: LBody:wakeUp
-- Forcibly wakes up this body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:wakeUp()
-- (replace lBody_stub with your real LBody instance above)

-- ---- Stub: LBody:sleep ---------------------------------------------------
--@api-stub: LBody:sleep
-- Puts this body to sleep immediately.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBody_stub:sleep()
-- (replace lBody_stub with your real LBody instance above)

-- -----------------------------------------------------------------------------
-- LCellular methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCellular:setCell ---------------------------------------------
--@api-stub: LCellular:setCell
-- Sets the material of a cell.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:setCell(cx, cy, t)
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:getCell ---------------------------------------------
--@api-stub: LCellular:getCell
-- Returns the material at `(cx, cy)` as an integer constant.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:getCell(cx, cy)  -- -> integer
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:fillRect --------------------------------------------
--@api-stub: LCellular:fillRect
-- Fills a rectangular region of cells with the given material.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:fillRect(cx0, cy0, cw, ch, t)
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:fillCircle ------------------------------------------
--@api-stub: LCellular:fillCircle
-- Fills a circle of cells with the given material.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:fillCircle(cx, cy, 1.0, t)
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:step ------------------------------------------------
--@api-stub: LCellular:step
-- Advances the simulation by one tick.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:step()
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:stepN -----------------------------------------------
--@api-stub: LCellular:stepN
-- Advances the simulation by `n` ticks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:stepN(5)
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:toImageData -----------------------------------------
--@api-stub: LCellular:toImageData
-- Returns the full grid as an RGBA byte string using the default colour palette.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:toImageData()
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:toImageDataRegion -----------------------------------
--@api-stub: LCellular:toImageDataRegion
-- Returns a sub-region as an RGBA byte string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:toImageDataRegion(cx0, cy0, cw, ch)  -- -> string
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:countCells ------------------------------------------
--@api-stub: LCellular:countCells
-- Counts cells of the given material type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:countCells(t)  -- -> integer
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:findCells -------------------------------------------
--@api-stub: LCellular:findCells
-- Returns positions of all cells of the given material as an array of `{x, y}` tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:findCells(t)  -- -> table
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:toBytes ---------------------------------------------
--@api-stub: LCellular:toBytes
-- Serialises the grid to a byte string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:toBytes()  -- -> string
-- (replace lCellular_stub with your real LCellular instance above)

-- ---- Stub: LCellular:loadFromBytes ---------------------------------------
--@api-stub: LCellular:loadFromBytes
-- Loads grid data from bytes produced by `toBytes`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCellular_stub:loadFromBytes(data)
-- (replace lCellular_stub with your real LCellular instance above)

-- -----------------------------------------------------------------------------
-- LPhysicsShape methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPhysicsShape:getType -----------------------------------------
--@api-stub: LPhysicsShape:getType
-- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:getType()  -- -> string
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- ---- Stub: LPhysicsShape:getRadius ---------------------------------------
--@api-stub: LPhysicsShape:getRadius
-- Returns the radius. Only valid for circle shapes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:getRadius()  -- -> number
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- ---- Stub: LPhysicsShape:getBoundingBox ----------------------------------
--@api-stub: LPhysicsShape:getBoundingBox
-- Returns the axis-aligned bounding box (x1, y1, x2, y2).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:getBoundingBox()  -- -> number, number, number, number
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- ---- Stub: LPhysicsShape:setDensity --------------------------------------
--@api-stub: LPhysicsShape:setDensity
-- Sets the density for this shape (used when attaching to a body).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:setDensity(density)
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- ---- Stub: LPhysicsShape:setFriction -------------------------------------
--@api-stub: LPhysicsShape:setFriction
-- Sets the friction coefficient.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:setFriction(friction)
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- ---- Stub: LPhysicsShape:setRestitution ----------------------------------
--@api-stub: LPhysicsShape:setRestitution
-- Sets the restitution (bounciness) coefficient.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:setRestitution(restitution)
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- ---- Stub: LPhysicsShape:setSensor ---------------------------------------
--@api-stub: LPhysicsShape:setSensor
-- Sets whether this shape is a sensor (non-colliding trigger).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:setSensor(sensor)
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- ---- Stub: LPhysicsShape:destroy -----------------------------------------
--@api-stub: LPhysicsShape:destroy
-- Releases this shape handle (GC handles cleanup).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPhysicsShape_stub:destroy()
-- (replace lPhysicsShape_stub with your real LPhysicsShape instance above)

-- -----------------------------------------------------------------------------
-- LTerrain methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTerrain:setCell ----------------------------------------------
--@api-stub: LTerrain:setCell
-- Sets a single terrain cell to solid or empty.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:setCell(cx, cy, solid)
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:getCell ----------------------------------------------
--@api-stub: LTerrain:getCell
-- Returns whether a cell is solid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:getCell(cx, cy)  -- -> boolean
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:fillCircle -------------------------------------------
--@api-stub: LTerrain:fillCircle
-- Fills a circle of cells centred at world position `(wx, wy)`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:fillCircle(wx, wy, 24.0, solid)
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:fillRect ---------------------------------------------
--@api-stub: LTerrain:fillRect
-- Fills a rectangular region of cells.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:fillRect(wx, wy, 64.0, 64.0, solid)
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:fillAll ----------------------------------------------
--@api-stub: LTerrain:fillAll
-- Sets every cell in the grid to `solid`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:fillAll(solid)
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:flush ------------------------------------------------
--@api-stub: LTerrain:flush
-- Rebuilds physics bodies for all dirty chunks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:flush()
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:isDirty ----------------------------------------------
--@api-stub: LTerrain:isDirty
-- Returns `true` when at least one chunk needs flushing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:isDirty()  -- -> boolean
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:collapseColumns --------------------------------------
--@api-stub: LTerrain:collapseColumns
-- Removes unsupported cells, returning the number of cells that fell.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:collapseColumns()
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:solidPositions ---------------------------------------
--@api-stub: LTerrain:solidPositions
-- Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:solidPositions()  -- -> table
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:spawnDebris ------------------------------------------
--@api-stub: LTerrain:spawnDebris
-- Spawns dynamic debris bodies at the given positions.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:spawnDebris(positions, mass, restitution)  -- -> table
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:toImageData ------------------------------------------
--@api-stub: LTerrain:toImageData
-- Returns the terrain as an RGBA byte string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:toImageData(sr, sg, sb, er, eg, eb)  -- -> string
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:toBytes ----------------------------------------------
--@api-stub: LTerrain:toBytes
-- Serialises the terrain grid to a byte string for save/load.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:toBytes()  -- -> string
-- (replace lTerrain_stub with your real LTerrain instance above)

-- ---- Stub: LTerrain:loadFromBytes ----------------------------------------
--@api-stub: LTerrain:loadFromBytes
-- Loads terrain cell data from bytes produced by `toBytes`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerrain_stub:loadFromBytes(data)
-- (replace lTerrain_stub with your real LTerrain instance above)

-- -----------------------------------------------------------------------------
-- LWorld methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LWorld:drawDebug ----------------------------------------------
--@api-stub: LWorld:drawDebug
-- Draws physics objects for debugging
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:drawDebug()
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:step ---------------------------------------------------
--@api-stub: LWorld:step
-- Advances the physics simulation by dt seconds, firing onBeginContact /
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:step(0.016)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:clear --------------------------------------------------
--@api-stub: LWorld:clear
-- Resets the world, removing all bodies and joints.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:clear()
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getGravity ---------------------------------------------
--@api-stub: LWorld:getGravity
-- Returns the gravity vector (gx, gy).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getGravity()  -- -> number, number
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setGravity ---------------------------------------------
--@api-stub: LWorld:setGravity
-- Sets the world gravity vector; default is `(0, 9.81)` (downward).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setGravity(gx, gy)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setMeter -----------------------------------------------
--@api-stub: LWorld:setMeter
-- Sets the pixels-per-meter scaling factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setMeter(ppm)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getMeter -----------------------------------------------
--@api-stub: LWorld:getMeter
-- Returns the pixels-per-meter scaling factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getMeter()  -- -> number
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:toPhysics ----------------------------------------------
--@api-stub: LWorld:toPhysics
-- Converts a pixel value to physics units.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:toPhysics(px)  -- -> number
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:toPixels -----------------------------------------------
--@api-stub: LWorld:toPixels
-- Converts a physics-unit value to pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:toPixels(m)  -- -> number
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getBodyCount -------------------------------------------
--@api-stub: LWorld:getBodyCount
-- Returns the total number of bodies in the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getBodyCount()  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getBodyIds ---------------------------------------------
--@api-stub: LWorld:getBodyIds
-- Returns all body IDs in the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getBodyIds()  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:destroyBody --------------------------------------------
--@api-stub: LWorld:destroyBody
-- Removes a body from the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:destroyBody(1)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:newBody ------------------------------------------------
--@api-stub: LWorld:newBody
-- Creates a new rectangular body and adds it to the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:newBody(0.0, 0.0, bt)  -- -> Body
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:newCircleBody ------------------------------------------
--@api-stub: LWorld:newCircleBody
-- Creates a new circular body and adds it to the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:newCircleBody(0.0, 0.0, 24.0, bt)  -- -> Body
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:newPolygonBody -----------------------------------------
--@api-stub: LWorld:newPolygonBody
-- Creates a new polygon body from a flat vertex table and adds it to the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:newPolygonBody(0.0, 0.0, tbl, bt)  -- -> Body
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:newEdgeBody --------------------------------------------
--@api-stub: LWorld:newEdgeBody
-- Creates a new edge (line segment) body and adds it to the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:newEdgeBody(0.0, 0.0, x1, y1, x2, y2, bt)  -- -> Body
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:newChainBody -------------------------------------------
--@api-stub: LWorld:newChainBody
-- Creates a new chain body from a flat vertex table and adds it to the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:newChainBody(0.0, 0.0, tbl, closed, bt)  -- -> Body
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addFixture ---------------------------------------------
--@api-stub: LWorld:addFixture
-- Adds an extra fixture (collider) to a body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addFixture()  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:fixtureCount -------------------------------------------
--@api-stub: LWorld:fixtureCount
-- Returns the number of fixtures on a body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:fixtureCount(body_id)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setFixtureFriction -------------------------------------
--@api-stub: LWorld:setFixtureFriction
-- Sets friction on a fixture by index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setFixtureFriction(body_id, fix_idx, friction)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setFixtureRestitution ----------------------------------
--@api-stub: LWorld:setFixtureRestitution
-- Sets restitution on a fixture by index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setFixtureRestitution(body_id, fix_idx, restitution)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setFixtureSensor ---------------------------------------
--@api-stub: LWorld:setFixtureSensor
-- Sets whether a fixture is a sensor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setFixtureSensor(body_id, fix_idx, sensor)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addRevoluteJoint ---------------------------------------
--@api-stub: LWorld:addRevoluteJoint
-- Creates a revolute (pin) joint between two bodies.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addRevoluteJoint(1.0, 0.2, ax, ay)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addDistanceJoint ---------------------------------------
--@api-stub: LWorld:addDistanceJoint
-- Creates a distance joint between two bodies.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addDistanceJoint(1.0, 0.2, ax1, ay1, ax2, ay2, len)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addPrismaticJoint --------------------------------------
--@api-stub: LWorld:addPrismaticJoint
-- Creates a prismatic (slider) joint between two bodies.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addPrismaticJoint(1.0, 0.2, ax, ay, axis_x, axis_y)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addWeldJoint -------------------------------------------
--@api-stub: LWorld:addWeldJoint
-- Creates a weld (rigid) joint between two bodies.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addWeldJoint(1.0, 0.2, ax, ay)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addRopeJoint -------------------------------------------
--@api-stub: LWorld:addRopeJoint
-- Creates a rope joint with a maximum distance.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addRopeJoint(1.0, 0.2, ax1, ay1, ax2, ay2, max)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addWheelJoint ------------------------------------------
--@api-stub: LWorld:addWheelJoint
-- Creates a wheel joint (prismatic + rotation).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addWheelJoint(1.0, 0.2, ax, ay, axis_x, axis_y)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addFrictionJoint ---------------------------------------
--@api-stub: LWorld:addFrictionJoint
-- Creates a friction joint that resists relative motion.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addFrictionJoint(1.0, 0.2, ax, ay, max_f, max_t)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addMotorJoint ------------------------------------------
--@api-stub: LWorld:addMotorJoint
-- Creates a motor joint that drives body_b toward body_a.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addMotorJoint(1.0, 0.2, factor)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addMouseJoint ------------------------------------------
--@api-stub: LWorld:addMouseJoint
-- Creates a mouse joint connecting a body to a target point.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addMouseJoint(body_id, tx, ty, max_f)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addPulleyJoint -----------------------------------------
--@api-stub: LWorld:addPulleyJoint
-- Creates a pulley joint (stub — falls back to weld joint).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addPulleyJoint(1.0, 0.2, ax, ay)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addGearJoint -------------------------------------------
--@api-stub: LWorld:addGearJoint
-- Creates a gear joint (stub — falls back to weld joint).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addGearJoint(1.0, 0.2, ax, ay)  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:jointCount ---------------------------------------------
--@api-stub: LWorld:jointCount
-- Returns the total number of joints.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:jointCount()  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getJointIds --------------------------------------------
--@api-stub: LWorld:getJointIds
-- Returns a table of integer IDs for every joint attached to this world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getJointIds()  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getJointBodies -----------------------------------------
--@api-stub: LWorld:getJointBodies
-- Returns the two body IDs connected by a joint.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getJointBodies(jid)  -- -> integer, integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:destroyJoint -------------------------------------------
--@api-stub: LWorld:destroyJoint
-- Removes a joint from the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:destroyJoint(jid)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getJointType -------------------------------------------
--@api-stub: LWorld:getJointType
-- Returns the type name of a joint.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getJointType(jid)  -- -> string
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setJointMotorSpeed -------------------------------------
--@api-stub: LWorld:setJointMotorSpeed
-- Sets the motor speed on a joint's angular axis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setJointMotorSpeed(jid, 120.0)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getJointMotorSpeed -------------------------------------
--@api-stub: LWorld:getJointMotorSpeed
-- Returns the motor speed on a joint's angular axis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getJointMotorSpeed(jid)  -- -> number
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setJointLimitsEnabled ----------------------------------
--@api-stub: LWorld:setJointLimitsEnabled
-- Enables or disables angular limits on a joint.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setJointLimitsEnabled(jid, true)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setJointLimits -----------------------------------------
--@api-stub: LWorld:setJointLimits
-- Sets the angular limits on a joint.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setJointLimits(jid, lower, upper)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getJointLimits -----------------------------------------
--@api-stub: LWorld:getJointLimits
-- Returns the angular limits on a joint.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getJointLimits(jid)  -- -> number, number
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setMouseJointTarget ------------------------------------
--@api-stub: LWorld:setMouseJointTarget
-- Updates the target position of a mouse joint.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setMouseJointTarget(jid, 0.0, 0.0)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:raycast ------------------------------------------------
--@api-stub: LWorld:raycast
-- Casts a ray and returns the nearest hit, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:raycast(x1, y1, x2, y2)  -- -> table|nil
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:raycastClosest -----------------------------------------
--@api-stub: LWorld:raycastClosest
-- Casts a ray and returns the closest hit using the query pipeline.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:raycastClosest(x1, y1, dx, dy, max_dist)  -- -> table|nil
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:raycastAll ---------------------------------------------
--@api-stub: LWorld:raycastAll
-- Casts a ray and returns all hits.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:raycastAll(x1, y1, dx, dy, max_dist)  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:queryAABB ----------------------------------------------
--@api-stub: LWorld:queryAABB
-- Returns body IDs within an axis-aligned bounding box.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:queryAABB(0.0, 0.0, 64.0, 64.0)  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getBodyAtPoint -----------------------------------------
--@api-stub: LWorld:getBodyAtPoint
-- Returns the body ID at a world-space point, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getBodyAtPoint(0.0, 0.0)  -- -> integer|nil
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getCollisionEvents -------------------------------------
--@api-stub: LWorld:getCollisionEvents
-- Returns collision events from the last step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getCollisionEvents()  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getBeginContactEvents ----------------------------------
--@api-stub: LWorld:getBeginContactEvents
-- Returns begin-contact events from the last step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getBeginContactEvents()  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getEndContactEvents ------------------------------------
--@api-stub: LWorld:getEndContactEvents
-- Returns end-contact events from the last step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getEndContactEvents()  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getContacts --------------------------------------------
--@api-stub: LWorld:getContacts
-- Returns all contact pairs from the narrow phase.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getContacts()  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getBodyContacts ----------------------------------------
--@api-stub: LWorld:getBodyContacts
-- Returns contacts involving a specific body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getBodyContacts(body_id)  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setBodyType --------------------------------------------
--@api-stub: LWorld:setBodyType
-- Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setBodyType(1, bt)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getBodyType --------------------------------------------
--@api-stub: LWorld:getBodyType
-- Returns the body type as a string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getBodyType(1)  -- -> string
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setBeginContact ----------------------------------------
--@api-stub: LWorld:setBeginContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setBeginContact(f)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:clearBeginContact --------------------------------------
--@api-stub: LWorld:clearBeginContact
-- Removes the begin-contact callback.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:clearBeginContact()
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setEndContact ------------------------------------------
--@api-stub: LWorld:setEndContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setEndContact(f)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:clearEndContact ----------------------------------------
--@api-stub: LWorld:clearEndContact
-- Removes the end-contact callback.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:clearEndContact()
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setBodyData --------------------------------------------
--@api-stub: LWorld:setBodyData
-- Attaches arbitrary Lua data to a body for retrieval in collision callbacks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setBodyData(1, 42)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getBodyData --------------------------------------------
--@api-stub: LWorld:getBodyData
-- Returns the Lua data previously attached to a body, or nil if none is set.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getBodyData(1)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:clearBodyData ------------------------------------------
--@api-stub: LWorld:clearBodyData
-- Removes the Lua data attached to a body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:clearBodyData(1)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setBodyCCD ---------------------------------------------
--@api-stub: LWorld:setBodyCCD
-- Enables or disables Continuous Collision Detection for a body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setBodyCCD(1, true)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getBodyCCD ---------------------------------------------
--@api-stub: LWorld:getBodyCCD
-- Returns whether CCD is enabled for a body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getBodyCCD(1)  -- -> boolean
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setBodyOneWay ------------------------------------------
--@api-stub: LWorld:setBodyOneWay
-- Marks a body as a one-way platform.  Bodies approaching from the
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setBodyOneWay(1, nx, ny)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:clearBodyOneWay ----------------------------------------
--@api-stub: LWorld:clearBodyOneWay
-- Removes the one-way platform flag from a body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:clearBodyOneWay(1)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getBodyOneWay ------------------------------------------
--@api-stub: LWorld:getBodyOneWay
-- Returns the one-way normal for a body, or nil if not configured.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getBodyOneWay(1)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setJointBreakForce -------------------------------------
--@api-stub: LWorld:setJointBreakForce
-- Sets the relative-velocity threshold above which a joint breaks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setJointBreakForce(jid, f)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getJointBreakForce -------------------------------------
--@api-stub: LWorld:getJointBreakForce
-- Returns the break threshold for a joint, or nil if not set.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getJointBreakForce(jid)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:isBodySleeping -----------------------------------------
--@api-stub: LWorld:isBodySleeping
-- Returns true if a body is currently sleeping (inactive).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:isBodySleeping(1)  -- -> boolean
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:wakeUpBody ---------------------------------------------
--@api-stub: LWorld:wakeUpBody
-- Forcibly wakes up a sleeping body.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:wakeUpBody(1)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:sleepBody ----------------------------------------------
--@api-stub: LWorld:sleepBody
-- Puts a body to sleep immediately.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:sleepBody(1)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:setSolverIterations ------------------------------------
--@api-stub: LWorld:setSolverIterations
-- Sets the number of constraint solver iterations per step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:setSolverIterations(5)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getSolverIterations ------------------------------------
--@api-stub: LWorld:getSolverIterations
-- Returns the current number of solver iterations per step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getSolverIterations()  -- -> integer
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:newBodies ----------------------------------------------
--@api-stub: LWorld:newBodies
-- Creates multiple bodies in one call.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:newBodies(specs)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:stepFixed ----------------------------------------------
--@api-stub: LWorld:stepFixed
-- Steps the world using a fixed sub-step size to consume accumulated time.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:stepFixed(accum, step_dt, max_steps)
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:addZone ------------------------------------------------
--@api-stub: LWorld:addZone
-- Creates a rectangular gravity/damping zone and returns a LuaZone handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:addZone(0.0, 0.0, 64.0, 64.0)  -- -> Zone
-- (replace lWorld_stub with your real LWorld instance above)

-- ---- Stub: LWorld:getZoneEvents ------------------------------------------
--@api-stub: LWorld:getZoneEvents
-- Returns zone enter/leave events produced by the most recent step.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWorld_stub:getZoneEvents()  -- -> table
-- (replace lWorld_stub with your real LWorld instance above)

-- -----------------------------------------------------------------------------
-- LZone methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LZone:getId ---------------------------------------------------
--@api-stub: LZone:getId
-- Returns the zone's integer ID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:getId()  -- -> integer
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setEnabled ----------------------------------------------
--@api-stub: LZone:setEnabled
-- Enables or disables the zone.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setEnabled(true)
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setPriority ---------------------------------------------
--@api-stub: LZone:setPriority
-- Sets the zone priority; higher values win over lower when zones overlap.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setPriority(priority)
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setLayerMask --------------------------------------------
--@api-stub: LZone:setLayerMask
-- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setLayerMask(mask)
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setCircle -----------------------------------------------
--@api-stub: LZone:setCircle
-- Replaces the zone boundary with a circle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setCircle(cx, cy, 24.0)
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setGravityDirectional -----------------------------------
--@api-stub: LZone:setGravityDirectional
-- Sets directional gravity inside the zone.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setGravityDirectional(gx, gy)
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setGravityPoint -----------------------------------------
--@api-stub: LZone:setGravityPoint
-- Sets point-attractor gravity inside the zone.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setGravityPoint(cx, cy, strength)
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setGravityRepulsor --------------------------------------
--@api-stub: LZone:setGravityRepulsor
-- Sets point-repulsor gravity inside the zone.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setGravityRepulsor(cx, cy, strength)
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setGravityZero ------------------------------------------
--@api-stub: LZone:setGravityZero
-- Suppresses gravity inside the zone (zero-g pocket).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setGravityZero()
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setLinearDampingOverride --------------------------------
--@api-stub: LZone:setLinearDampingOverride
-- Sets an optional linear damping override for bodies inside the zone.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setLinearDampingOverride([value])
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:setAngularDampingOverride -------------------------------
--@api-stub: LZone:setAngularDampingOverride
-- Sets an optional angular damping override for bodies inside the zone.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:setAngularDampingOverride([value])
-- (replace lZone_stub with your real LZone instance above)

-- ---- Stub: LZone:destroy -------------------------------------------------
--@api-stub: LZone:destroy
-- Removes the zone from the world.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lZone_stub:destroy()
-- (replace lZone_stub with your real LZone instance above)
