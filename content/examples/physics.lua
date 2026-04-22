-- content/examples/physics.lua
-- Hand-written coverage of the lurek.physics API (147 items).
--
-- The lurek.physics namespace wraps a 2D rigid-body simulator with bodies,
-- shapes, joints, sensor zones, destructible terrain grids, and a falling-
-- sand cellular automaton. Build a world once, step it from lurek.process,
-- and drain collision / zone events between steps to drive game logic.
--
-- Run: cargo run -- content/examples/physics.lua

-- ── lurek.physics.* functions ──

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
  world = nil
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
-- Returns x, y, vx, vy in one call — handy for syncing a sprite to its body each frame.
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
-- Branch on this before applying ambient forces — woken bodies cost solver time.
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
-- Attach to a body via lurek.physics.attachShape — width and height are in world units.
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
    if lurek.input.isKeyPressed("f3") then lurek.physics.debugDraw(false) end
  end
end

--@api-stub: lurek.physics.drawDebugGpu
-- Extracts collider geometry from a World and queues a GPU physics debug.
-- Call from lurek.render to overlay collider outlines via the GPU pipeline (no ImageData needed).
do  -- lurek.physics.drawDebugGpu
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.render()
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


-- ── World methods ──

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
-- Read the current gravity vector — useful when toggling underwater / zero-g modes.
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
    if lurek.input.isKeyPressed("g") then world:setGravity(0, -9.81) end
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
-- Use to detect when objects part — e.g. removing a temporary glue effect.
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
-- Includes contact normals — use to push bodies apart manually or to spawn impact FX.
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
-- Read before mutating mass or velocity — only dynamic bodies respond to those.
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
  lurek.log.debug("entity kind=" .. data.kind, "phys")
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
-- Use to model destructible vehicle joints — the engine destroys the joint when exceeded.
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
-- Wake before applying impulses or forces — sleeping bodies ignore them.
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


-- ── Zone methods ──

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
-- Higher priority wins when zones overlap — use to layer a wind tunnel above ambient water.
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
-- Switch from rectangle to circular boundary — useful for blast radii or planet wells.
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


-- ── Terrain methods ──

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
-- Probe before placing a structure — fail early when target cells are not solid.
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
-- Skip flush() when nothing changed this frame — saves chunk rebuild work.
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


-- ── Cellular methods ──

--@api-stub: Cellular:setCell
-- Sets the material of a cell.
-- Use to spawn material (sand, water) at a specific cell — typically from a player tool.
do  -- Cellular:setCell
  local sand = lurek.physics.newCellular(128, 64)
  sand:setCell(64, 0, lurek.physics.CELL_SAND)
  sand:setCell(65, 0, lurek.physics.CELL_WATER)
end

--@api-stub: Cellular:getCell
-- Returns the material at `(cx, cy)` as an integer constant.
-- Probe before placing a barrier — only act when the source cell is empty.
do  -- Cellular:getCell
  local sand = lurek.physics.newCellular(128, 64)
  if sand:getCell(10, 10) == lurek.physics.CELL_AIR then
    sand:setCell(10, 10, lurek.physics.CELL_ROCK)
  end
end

--@api-stub: Cellular:step
-- Advances the simulation by one tick.
-- Drive the simulation each frame from lurek.process — sand falls, water spreads.
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


-- ── Body methods ──

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
-- Override the mass derived from shape density — use for game-feel tuning.
do  -- Body:setMass
  local world = lurek.physics.newWorld(0, 9.81)
  local heavy = world:newBody(100, 200, "dynamic")
  heavy:setMass(50.0)
end

--@api-stub: Body:getType
-- Returns the body type as a string.
-- Branch on the type before applying impulses — only dynamic bodies respond.
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
-- Compare to a target value before mutating — avoid wakes on bodies already at the right value.
do  -- Body:getFriction
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  if crate:getFriction() < 0.5 then crate:setFriction(0.7) end
end

--@api-stub: Body:setFriction
-- Sets the body friction coefficient.
-- Use 0.0 for ice, 0.7 for wood, 1.0+ for rubber — tune for the surface material.
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
-- Read to debug collision filtering — body sees layers in the mask, ignores others.
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
    if lurek.input.isKeyPressed("space") then player:applyImpulse(0, -300) end
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
-- Use to spin up a wheel or give a thrown object a tumble — accumulates over the step.
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
-- Use 0 for vacuum, 0.5 for air, 5+ for water — simulates fluid drag without a zone.
do  -- Body:setLinearDamping
  local world = lurek.physics.newWorld(0, 9.81)
  local fish = world:newBody(100, 200, "dynamic")
  fish:setLinearDamping(2.0)
end

--@api-stub: Body:getAngularDamping
-- Returns the angular damping coefficient.
-- Read to debug bodies that keep spinning forever — usually damping=0 is the cause.
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
-- Read before disabling — gameplay-critical bodies should never sleep.
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
-- Use to gate per-frame work (AI, sound) on inactive bodies — saves frame budget.
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


-- ── PhysicsShape methods ──

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
-- Set BEFORE attachShape — once attached, density does not retro-actively re-derive mass.
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
-- Use for trigger volumes (pickup zones, kill planes) — fires events but does not block.
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
  shape = nil
end
