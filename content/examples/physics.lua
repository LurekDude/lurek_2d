-- content/examples/physics.lua
-- Hand-written coverage of the lurek.physics API (147 items).
--
-- The lurek.physics namespace wraps a 2D rigid-body simulator with bodies,
-- shapes, joints, sensor zones, destructible terrain grids, and a falling-
-- sand cellular automaton. Build a world once, step it from lurek.process,
-- and drain collision / zone events between steps to drive game logic.
--
-- Run: cargo run -- content/examples/physics.lua

-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ lurek.physics.* functions Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

--@api-stub: lurek.physics.newWorld
-- Creates a new physics world with the given gravity vector.
-- Build the world once at startup; pass it to body factories and step it every frame.
-- if false then -- lurek.physics.newWorld
--   local world = lurek.physics.newWorld(0, 9.81)
--   lurek.log.info("physics world created with " .. world:getBodyCount() .. " bodies", "boot")
-- end

--@api-stub: lurek.physics.step
-- Advances the physics world by dt seconds.
-- Use this flat form when you do not need the contact callbacks fired by World:step.
-- if false then -- lurek.physics.step
--   local world = lurek.physics.newWorld(0, 9.81)
--   function lurek.process(dt)
--     lurek.physics.step(world, dt)
--   end
-- end

--@api-stub: lurek.physics.destroyWorld
-- Marks a physics world for destruction.
-- Drop your last reference to the world or call this on scene unload to release colliders.
-- if false then -- lurek.physics.destroyWorld
--   local world = lurek.physics.newWorld(0, 9.81)
--   lurek.physics.destroyWorld(world)
--   world = nil --[[@type any]]
-- end

--@api-stub: lurek.physics.newBody
-- Creates a new rectangular body in the given world.
-- Pass body type as one of "dynamic" / "static" / "kinematic"; rectangular fixture is implicit.
-- if false then -- lurek.physics.newBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local crate = lurek.physics.newBody(world, 100, 200, "dynamic")
--   crate:setMass(1.0)
-- end

--@api-stub: lurek.physics.getBody
-- Returns the position and velocity of a body (x, y, vx, vy).
-- Returns x, y, vx, vy in one call Ă˘â‚¬â€ť handy for syncing a sprite to its body each frame.
-- if false then -- lurek.physics.getBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = lurek.physics.newBody(world, 100, 200, "dynamic")
--   local x, y, vx, vy = lurek.physics.getBody(world, body)
--   lurek.log.debug("crate at " .. x .. "," .. y .. " v=" .. vx .. "," .. vy, "phys")
-- end

--@api-stub: lurek.physics.setBodyVelocity
-- Sets the velocity of a body.
-- Use to launch a projectile or apply a one-shot velocity change without stacking impulses.
-- if false then -- lurek.physics.setBodyVelocity
--   local world = lurek.physics.newWorld(0, 9.81)
--   local bullet = lurek.physics.newBody(world, 100, 200, "dynamic")
--   lurek.physics.setBodyVelocity(world, bullet, 600, -200)
-- end

--@api-stub: lurek.physics.isSleepingAllowed
-- Returns whether the body is allowed to sleep.
-- Branch on this before applying ambient forces Ă˘â‚¬â€ť woken bodies cost solver time.
-- if false then -- lurek.physics.isSleepingAllowed
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = lurek.physics.newBody(world, 100, 200, "dynamic")
--   if lurek.physics.isSleepingAllowed(world, body) then
--     lurek.log.debug("body may sleep when idle", "phys")
--   end
-- end

--@api-stub: lurek.physics.setSleepingAllowed
-- Sets whether the body is allowed to sleep.
-- Disable sleeping on bodies you constantly poll (player, vehicle) to avoid wake-up jitter.
-- if false then -- lurek.physics.setSleepingAllowed
--   local world = lurek.physics.newWorld(0, 9.81)
--   local player = lurek.physics.newBody(world, 100, 200, "dynamic")
--   lurek.physics.setSleepingAllowed(world, player, false)
-- end

--@api-stub: lurek.physics.newRectangleShape
-- Creates a rectangle shape userdata.
-- Attach to a body via lurek.physics.attachShape Ă˘â‚¬â€ť width and height are in world units.
-- if false then -- lurek.physics.newRectangleShape
--   local crate_shape = lurek.physics.newRectangleShape(64, 64)
--   lurek.log.info("crate shape type=" .. crate_shape:getType(), "phys")
-- end

--@api-stub: lurek.physics.newCircleShape
-- Creates a circle shape userdata.
-- Use for balls, wheels, or grenades; cheaper to test for collisions than polygons.
-- if false then -- lurek.physics.newCircleShape
--   local ball_shape = lurek.physics.newCircleShape(16)
--   lurek.log.info("ball radius=" .. ball_shape:getRadius(), "phys")
-- end

--@api-stub: lurek.physics.newEdgeShape
-- Creates an edge (line segment) shape userdata.
-- Use for thin walls or sloped floors that should not have inside-corner ghost collisions.
-- if false then -- lurek.physics.newEdgeShape
--   local floor_shape = lurek.physics.newEdgeShape(0, 480, 800, 480)
--   lurek.log.info("floor edge type=" .. floor_shape:getType(), "phys")
-- end

--@api-stub: lurek.physics.newPolygonShape
-- Creates a convex polygon shape userdata from flat variadic vertex pairs.
-- Pass at least 3 vertex pairs (6 numbers) winding counter-clockwise; must be convex.
-- if false then -- lurek.physics.newPolygonShape
--   local triangle = lurek.physics.newPolygonShape(0, 0, 32, 0, 16, 28)
--   lurek.log.info("triangle type=" .. triangle:getType(), "phys")
-- end

--@api-stub: lurek.physics.newChainShape
-- Creates a chain shape userdata from flat variadic vertex pairs.
-- Use for terrain outlines; pass closed=true for a loop, false for an open polyline.
-- if false then -- lurek.physics.newChainShape
--   local hill = lurek.physics.newChainShape(false, 0, 400, 100, 360, 200, 380, 300, 420)
--   lurek.log.info("hill chain type=" .. hill:getType(), "phys")
-- end

--@api-stub: lurek.physics.attachShape
-- Attaches a standalone shape to a body as an additional fixture.
-- Use to give a body a compound collider (e.g. car body + wheel arches) after creation.
-- if false then -- lurek.physics.attachShape
--   local world = lurek.physics.newWorld(0, 9.81)
--   local car = lurek.physics.newBody(world, 200, 200, "dynamic")
--   local roof = lurek.physics.newRectangleShape(64, 16)
--   lurek.physics.attachShape(car, roof)
-- end

--@api-stub: lurek.physics.getCollisions
-- Returns all collision events from the last simulation step.
-- Drain once per frame after step; entries are {body_a, body_b} index pairs.
-- if false then -- lurek.physics.getCollisions
--   local world = lurek.physics.newWorld(0, 9.81)
--   function lurek.process(dt)
--     lurek.physics.step(world, dt)
--     for _, c in ipairs(lurek.physics.getCollisions(world)) do
--       lurek.log.debug("hit " .. c.body_a .. " vs " .. c.body_b, "phys")
--     end
--   end
-- end

--@api-stub: lurek.physics.debugDraw
-- Enables or disables the physics debug overlay (AABB boxes and velocity vectors).
-- Toggle from a debug key; the engine renders AABBs and velocity arrows when enabled.
-- if false then -- lurek.physics.debugDraw
--   lurek.physics.debugDraw(true)
--   function lurek.process(dt)
--     if lurek.input.keyboard.isDown("f3") then lurek.physics.debugDraw(false) end
--   end
-- end

--@api-stub: lurek.physics.drawDebugGpu
-- Extracts collider geometry from a World and queues a GPU physics debug.
-- Call from lurek.render to overlay collider outlines via the GPU pipeline (no ImageData needed).
-- if false then -- lurek.physics.drawDebugGpu
--   local world = lurek.physics.newWorld(0, 9.81)
--   function lurek.draw()
--     lurek.physics.drawDebugGpu(world, { bodyColor = {0, 1, 0, 1}, lineWidth = 2.0 })
--   end
-- end

--@api-stub: lurek.physics.newTerrain
-- Creates a destructible terrain grid.
-- Build a destructible voxel grid bound to a physics world; flush() to push colliders.
-- if false then -- lurek.physics.newTerrain
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   terrain:fillAll(true)
--   terrain:flush()
-- end

--@api-stub: lurek.physics.newCellular
-- Creates a falling-sand cellular automaton grid.
-- Spin up a falling-sand grid; step it every frame, paint with setCell or fillCircle.
-- if false then -- lurek.physics.newCellular
--   local sand = lurek.physics.newCellular(128, 64)
--   sand:setCell(64, 0, lurek.physics.CELL_SAND)
--   function lurek.process(dt) sand:step() end
-- end


-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ World methods Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

--@api-stub: LWorld:step
-- Advances the physics simulation by dt seconds, firing onBeginContact /.
-- Call every frame from lurek.process(dt); contact callbacks fire as a side effect.
-- if false then -- World:step
--   local world = lurek.physics.newWorld(0, 9.81)
--   function lurek.process(dt)
--     world:step(dt)
--   end
-- end

--@api-stub: LWorld:clear
-- Resets the world, removing all bodies and joints.
-- Use when transitioning between levels to wipe all bodies and joints in one call.
-- if false then -- World:clear
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:newBody(100, 200, "dynamic")
--   world:clear()
--   lurek.log.info("world cleared, body count=" .. world:getBodyCount(), "scene")
-- end

--@api-stub: LWorld:getGravity
-- Returns the gravity vector (gx, gy).
-- Read the current gravity vector Ă˘â‚¬â€ť useful when toggling underwater / zero-g modes.
-- if false then -- World:getGravity
--   local world = lurek.physics.newWorld(0, 9.81)
--   local gx, gy = world:getGravity()
--   lurek.log.info("gravity=" .. gx .. "," .. gy, "phys")
-- end

--@api-stub: LWorld:setGravity
-- Sets the world gravity vector; default is `(0, 9.81)` (downward).
-- Mutate gravity at runtime to enter water (gy=2.0), zero-g (0,0), or invert it (0,-9.81).
-- if false then -- World:setGravity
--   local world = lurek.physics.newWorld(0, 9.81)
--   function lurek.process(dt)
--     if lurek.input.keyboard.isDown("g") then world:setGravity(0, -9.81) end
--   end
-- end

--@api-stub: LWorld:setMeter
-- Sets the pixels-per-meter scaling factor.
-- Tune pixels-per-meter once at startup so 1 game-meter matches your sprite size.
-- if false then -- World:setMeter
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:setMeter(64)
--   lurek.log.info("ppm=" .. world:getMeter(), "phys")
-- end

--@api-stub: LWorld:getMeter
-- Returns the pixels-per-meter scaling factor.
-- Read PPM when converting between sprite pixel sizes and physics-world units.
-- if false then -- World:getMeter
--   local world = lurek.physics.newWorld(0, 9.81)
--   local ppm = world:getMeter()
--   lurek.log.debug("1 meter = " .. ppm .. " pixels", "phys")
-- end

--@api-stub: LWorld:toPhysics
-- Converts a pixel value to physics units.
-- Convert pixel measurements (sprite size, mouse position) into physics units before passing in.
-- if false then -- World:toPhysics
--   local world = lurek.physics.newWorld(0, 9.81)
--   local px = 128
--   local meters = world:toPhysics(px)
--   lurek.log.debug(px .. " px = " .. meters .. " m", "phys")
-- end

--@api-stub: LWorld:toPixels
-- Converts a physics-unit value to pixels.
-- Convert physics-unit body positions back to pixels for sprite drawing.
-- if false then -- World:toPixels
--   local world = lurek.physics.newWorld(0, 9.81)
--   local pixels = world:toPixels(2.5)
--   lurek.log.debug("2.5 m = " .. pixels .. " px", "phys")
-- end

--@api-stub: LWorld:getBodyCount
-- Returns the total number of bodies in the world.
-- Use as a sanity check when loading levels or to gate spawning under a cap.
-- if false then -- World:getBodyCount
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:newBody(100, 200, "dynamic")
--   if world:getBodyCount() < 1000 then world:newBody(150, 200, "dynamic") end
-- end

--@api-stub: LWorld:getBodyIds
-- Returns all body IDs in the world.
-- Iterate to query or destroy every body; each id can be passed to setBodyType etc.
-- if false then -- World:getBodyIds
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:newBody(100, 200, "dynamic")
--   for _, id in ipairs(world:getBodyIds()) do
--     lurek.log.debug("body id=" .. id, "phys")
--   end
-- end

--@api-stub: LWorld:destroyBody
-- Removes a body from the world.
-- Remove a body when its game entity dies; subsequent operations on the id are no-ops.
-- if false then -- World:destroyBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local enemy = world:newBody(300, 200, "dynamic")
--   world:destroyBody(enemy:getId())
-- end

--@api-stub: LWorld:newBody
-- Creates a new rectangular body and adds it to the world.
-- Returns a Body userdata you can call methods on; type is dynamic/static/kinematic.
-- if false then -- World:newBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local crate = world:newBody(100, 200, "dynamic")
--   crate:setMass(2.5)
--   crate:setRestitution(0.3)
-- end

--@api-stub: LWorld:fixtureCount
-- Returns the number of fixtures on a body.
-- Use to verify a body has all expected colliders attached after attachShape calls.
-- if false then -- World:fixtureCount
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   local n = world:fixtureCount(body:getId())
--   lurek.log.debug("body has " .. n .. " fixtures", "phys")
-- end

--@api-stub: LWorld:jointCount
-- Returns the total number of joints.
-- Useful when serialising a level to allocate the joint table up-front.
-- if false then -- World:jointCount
--   local world = lurek.physics.newWorld(0, 9.81)
--   lurek.log.info("joints=" .. world:jointCount(), "phys")
-- end

--@api-stub: LWorld:getJointIds
-- Returns a table of integer IDs for every joint attached to this world.
-- Iterate to inspect or destroy every joint (e.g. when respawning a vehicle).
-- if false then -- World:getJointIds
--   local world = lurek.physics.newWorld(0, 9.81)
--   for _, jid in ipairs(world:getJointIds()) do
--     lurek.log.debug("joint id=" .. jid, "phys")
--   end
-- end

--@api-stub: LWorld:getJointBodies
-- Returns the two body IDs connected by a joint.
-- Use to find which bodies a joint connects when reacting to a break event.
-- if false then -- World:getJointBodies
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b1 = world:newBody(0, 0, "static")
--   local b2 = world:newBody(0, 100, "dynamic")
--   local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
--   local a, b = world:getJointBodies(jid)
--   lurek.log.debug("joint " .. jid .. " links " .. a .. " <-> " .. b, "phys")
-- end

--@api-stub: LWorld:destroyJoint
-- Removes a joint from the world.
-- Call when an entity disassembles (vehicle wreck, broken chain) to free constraint solver work.
-- if false then -- World:destroyJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b1 = world:newBody(0, 0, "static")
--   local b2 = world:newBody(0, 100, "dynamic")
--   local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
--   world:destroyJoint(jid)
-- end

--@api-stub: LWorld:getJointType
-- Returns the type name of a joint.
-- Branch on the type string when you have a heterogeneous joint registry.
-- if false then -- World:getJointType
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b1 = world:newBody(0, 0, "static")
--   local b2 = world:newBody(0, 100, "dynamic")
--   local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
--   local kind = world:getJointType(jid)
--   if kind == "revolute" then lurek.log.debug("hinge joint", "phys") end
-- end

--@api-stub: LWorld:getJointMotorSpeed
-- Returns the motor speed on a joint's angular axis.
-- Read motor speed for HUD telemetry or to drive sound pitch on a powered joint.
-- if false then -- World:getJointMotorSpeed
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b1 = world:newBody(0, 0, "static")
--   local b2 = world:newBody(0, 100, "dynamic")
--   local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
--   local rpm = world:getJointMotorSpeed(jid)
--   lurek.log.debug("motor speed=" .. rpm, "phys")
-- end

--@api-stub: LWorld:getJointLimits
-- Returns the angular limits on a joint.
-- Use when serialising joint state or rendering a limit indicator in editor mode.
-- if false then -- World:getJointLimits
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b1 = world:newBody(0, 0, "static")
--   local b2 = world:newBody(0, 100, "dynamic")
--   local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
--   local lo, hi = world:getJointLimits(jid)
--   lurek.log.debug("limits=[" .. lo .. ", " .. hi .. "]", "phys")
-- end

--@api-stub: LWorld:getBodyAtPoint
-- Returns the body ID at a world-space point, or nil.
-- Use for click-to-select tools; returns nil when nothing under the cursor.
-- if false then -- World:getBodyAtPoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local hit = world:getBodyAtPoint(150, 200)
--   if hit then lurek.log.debug("clicked body=" .. hit, "phys") end
-- end

--@api-stub: LWorld:getCollisionEvents
-- Returns collision events from the last step.
-- Drain once per step and react to gameplay-meaningful pairs (player vs pickup etc.).
-- if false then -- World:getCollisionEvents
--   local world = lurek.physics.newWorld(0, 9.81)
--   function lurek.process(dt)
--     world:step(dt)
--     for _, e in ipairs(world:getCollisionEvents()) do
--       lurek.log.debug("hit " .. e.bodyA .. " vs " .. e.bodyB, "phys")
--     end
--   end
-- end

--@api-stub: LWorld:getBeginContactEvents
-- Returns begin-contact events from the last step.
-- Use the begin-only stream for one-shot triggers like pickup-on-touch logic.
-- if false then -- World:getBeginContactEvents
--   local world = lurek.physics.newWorld(0, 9.81)
--   function lurek.process(dt)
--     world:step(dt)
--     for _, e in ipairs(world:getBeginContactEvents()) do
--       lurek.log.debug("begin " .. e.bodyA .. "/" .. e.bodyB, "phys")
--     end
--   end
-- end

--@api-stub: LWorld:getEndContactEvents
-- Returns end-contact events from the last step.
-- Use to detect when objects part Ă˘â‚¬â€ť e.g. removing a temporary glue effect.
-- if false then -- World:getEndContactEvents
--   local world = lurek.physics.newWorld(0, 9.81)
--   function lurek.process(dt)
--     world:step(dt)
--     for _, e in ipairs(world:getEndContactEvents()) do
--       lurek.log.debug("end " .. e.bodyA .. "/" .. e.bodyB, "phys")
--     end
--   end
-- end

--@api-stub: LWorld:getContacts
-- Returns all contact pairs from the narrow phase.
-- Includes contact normals Ă˘â‚¬â€ť use to push bodies apart manually or to spawn impact FX.
-- if false then -- World:getContacts
--   local world = lurek.physics.newWorld(0, 9.81)
--   for _, c in ipairs(world:getContacts()) do
--     if c.isTouching then
--       lurek.log.debug("contact n=" .. c.normalX .. "," .. c.normalY, "phys")
--     end
--   end
-- end

--@api-stub: LWorld:getBodyContacts
-- Returns contacts involving a specific body.
-- Filter to one body when you only care about a specific entity (player ground check).
-- if false then -- World:getBodyContacts
--   local world = lurek.physics.newWorld(0, 9.81)
--   local player = world:newBody(100, 200, "dynamic")
--   local touches = world:getBodyContacts(player:getId())
--   lurek.log.debug("player contacts=" .. #touches, "phys")
-- end

--@api-stub: LWorld:setBodyType
-- Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
-- Switch a body to kinematic for cutscenes, then back to dynamic when control resumes.
-- if false then -- World:setBodyType
--   local world = lurek.physics.newWorld(0, 9.81)
--   local door = world:newBody(200, 200, "static")
--   world:setBodyType(door:getId(), "kinematic")
-- end

--@api-stub: LWorld:getBodyType
-- Returns the body type as a string.
-- Read before mutating mass or velocity Ă˘â‚¬â€ť only dynamic bodies respond to those.
-- if false then -- World:getBodyType
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   if world:getBodyType(body:getId()) == "dynamic" then body:setMass(1.0) end
-- end

--@api-stub: LWorld:setBeginContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- Register once at boot; the callback runs from inside step() so do minimal work there.
-- if false then -- World:setBeginContact
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:setBeginContact(function(a, b)
--     lurek.log.info("touch " .. a .. " <-> " .. b, "phys")
--   end)
-- end

--@api-stub: LWorld:clearBeginContact
-- Removes the begin-contact callback.
-- Call when leaving a scene to drop the closure and any captured upvalues.
-- if false then -- World:clearBeginContact
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:setBeginContact(function(a, b) end)
--   world:clearBeginContact()
-- end

--@api-stub: LWorld:setEndContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- Use to clean up state attached on begin (sound stops, particle emitter off).
-- if false then -- World:setEndContact
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:setEndContact(function(a, b)
--     lurek.log.debug("apart " .. a .. " / " .. b, "phys")
--   end)
-- end

--@api-stub: LWorld:clearEndContact
-- Removes the end-contact callback.
-- Pair with clearBeginContact when unloading a level to drop callbacks.
-- if false then -- World:clearEndContact
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:setEndContact(function(a, b) end)
--   world:clearEndContact()
-- end

--@api-stub: LWorld:getBodyData
-- Returns the Lua data previously attached to a body, or nil if none is set.
-- Use to recover the Lua entity (table, name) from a body id inside a contact callback.
-- if false then -- World:getBodyData
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   world:setBodyData(body:getId(), { kind = "enemy", hp = 30 })
--   local data = world:getBodyData(body:getId())
--   if data then lurek.log.debug("entity kind=" .. data.kind, "phys") end
-- end

--@api-stub: LWorld:clearBodyData
-- Removes the Lua data attached to a body.
-- Call when an entity dies but the body is recycled, to avoid stale references.
-- if false then -- World:clearBodyData
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   world:setBodyData(body:getId(), { name = "crate" })
--   world:clearBodyData(body:getId())
-- end

--@api-stub: LWorld:setBodyCCD
-- Enables or disables Continuous Collision Detection for a body.
-- Enable on bullets and fast-moving projectiles to prevent tunnelling through walls.
-- if false then -- World:setBodyCCD
--   local world = lurek.physics.newWorld(0, 9.81)
--   local bullet = world:newBody(100, 200, "dynamic")
--   world:setBodyCCD(bullet:getId(), true)
-- end

--@api-stub: LWorld:getBodyCCD
-- Returns whether CCD is enabled for a body.
-- Branch on this when applying very high impulses to prefer CCD-enabled bodies.
-- if false then -- World:getBodyCCD
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   if not world:getBodyCCD(body:getId()) then world:setBodyCCD(body:getId(), true) end
-- end

--@api-stub: LWorld:clearBodyOneWay
-- Removes the one-way platform flag from a body.
-- Call when a one-way platform should become solid from both sides (e.g. boss arena).
-- if false then -- World:clearBodyOneWay
--   local world = lurek.physics.newWorld(0, 9.81)
--   local platform = world:newBody(200, 300, "static")
--   world:clearBodyOneWay(platform:getId())
-- end

--@api-stub: LWorld:getBodyOneWay
-- Returns the one-way normal for a body, or nil if not configured.
-- Use to render an indicator arrow showing which way bodies pass through the platform.
-- if false then -- World:getBodyOneWay
--   local world = lurek.physics.newWorld(0, 9.81)
--   local platform = world:newBody(200, 300, "static")
--   local nx, ny = world:getBodyOneWay(platform:getId())
--   if nx then lurek.log.debug("one-way n=" .. nx .. "," .. ny, "phys") end
-- end

--@api-stub: LWorld:setJointBreakForce
-- Sets the relative-velocity threshold above which a joint breaks.
-- Use to model destructible vehicle joints Ă˘â‚¬â€ť the engine destroys the joint when exceeded.
-- if false then -- World:setJointBreakForce
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b1 = world:newBody(0, 0, "static")
--   local b2 = world:newBody(0, 100, "dynamic")
--   local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
--   world:setJointBreakForce(jid, 5000.0)
-- end

--@api-stub: LWorld:getJointBreakForce
-- Returns the break threshold for a joint, or nil if not set.
-- Read for HUD / damage display; returns nil when no break threshold has been set.
-- if false then -- World:getJointBreakForce
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b1 = world:newBody(0, 0, "static")
--   local b2 = world:newBody(0, 100, "dynamic")
--   local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
--   local f = world:getJointBreakForce(jid)
--   if f then lurek.log.debug("breaks at " .. f .. " N", "phys") end
-- end

--@api-stub: LWorld:isBodySleeping
-- Returns true if a body is currently sleeping (inactive).
-- Use to skip per-frame work on inactive bodies (AI updates, sound emission).
-- if false then -- World:isBodySleeping
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   if not world:isBodySleeping(body:getId()) then
--     lurek.log.debug("body active", "phys")
--   end
-- end

--@api-stub: LWorld:wakeUpBody
-- Forcibly wakes up a sleeping body.
-- Wake before applying impulses or forces Ă˘â‚¬â€ť sleeping bodies ignore them.
-- if false then -- World:wakeUpBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   world:wakeUpBody(body:getId())
--   body:applyImpulse(0, -100)
-- end

--@api-stub: LWorld:sleepBody
-- Puts a body to sleep immediately.
-- Force-sleep statically positioned dynamic bodies (a settled debris pile) to save CPU.
-- if false then -- World:sleepBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local rubble = world:newBody(100, 200, "dynamic")
--   world:sleepBody(rubble:getId())
-- end

--@api-stub: LWorld:setSolverIterations
-- Sets the number of constraint solver iterations per step.
-- Bump for stacking-heavy scenes; 8 is the default, 16 trades CPU for stability.
-- if false then -- World:setSolverIterations
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:setSolverIterations(12)
-- end

--@api-stub: LWorld:getSolverIterations
-- Returns the current number of solver iterations per step.
-- Read for tuning UI or to log the current accuracy budget at startup.
-- if false then -- World:getSolverIterations
--   local world = lurek.physics.newWorld(0, 9.81)
--   local iters = world:getSolverIterations()
--   lurek.log.info("solver iterations=" .. iters, "phys")
-- end

--@api-stub: LWorld:newBodies
-- Creates multiple bodies in one call.
-- Use for bulk spawning a particle storm or grid of crates with a single round-trip.
-- if false then -- World:newBodies
--   local world = lurek.physics.newWorld(0, 9.81)
--   local ids = world:newBodies({
--     { 100, 200, "dynamic" },
--     { 132, 200, "dynamic" },
--     { 164, 200, "dynamic" },
--   })
--   lurek.log.info("spawned " .. #ids .. " crates", "phys")
-- end

--@api-stub: LWorld:addZone
-- Creates a rectangular gravity/damping zone and returns a LuaZone handle.
-- Returns a Zone handle; configure gravity / damping override before bodies enter it.
-- if false then -- World:addZone
--   local world = lurek.physics.newWorld(0, 9.81)
--   local water = world:addZone(0, 400, 800, 200)
--   water:setGravityDirectional(0, 2.0)
-- end

--@api-stub: LWorld:getZoneEvents
-- Returns zone enter/leave events produced by the most recent step.
-- Drain after step to spawn splash particles on enter and bubble trails on leave.
-- if false then -- World:getZoneEvents
--   local world = lurek.physics.newWorld(0, 9.81)
--   function lurek.process(dt)
--     world:step(dt)
--     for _, e in ipairs(world:getZoneEvents()) do
--       lurek.log.debug("zone " .. e.zone_id .. " " .. e.kind .. " body=" .. e.body_id, "phys")
--     end
--   end
-- end


-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ Zone methods Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

--@api-stub: LZone:getId
-- Returns the zone's integer ID.
-- Capture the id at startup so you can match it against zone events later.
-- if false then -- Zone:getId
--   local world = lurek.physics.newWorld(0, 9.81)
--   local zone = world:addZone(0, 0, 100, 100)
--   lurek.log.info("water zone id=" .. zone:getId(), "phys")
-- end

--@api-stub: LZone:setEnabled
-- Enables or disables the zone.
-- Toggle from gameplay (close a force-field gate) without destroying the zone.
-- if false then -- Zone:setEnabled
--   local world = lurek.physics.newWorld(0, 9.81)
--   local field = world:addZone(0, 0, 200, 200)
--   field:setEnabled(false)
-- end

--@api-stub: LZone:setPriority
-- Sets the zone priority; higher values win over lower when zones overlap.
-- Higher priority wins when zones overlap Ă˘â‚¬â€ť use to layer a wind tunnel above ambient water.
-- if false then -- Zone:setPriority
--   local world = lurek.physics.newWorld(0, 9.81)
--   local wind = world:addZone(0, 0, 200, 200)
--   wind:setPriority(10)
-- end

--@api-stub: LZone:setLayerMask
-- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
-- Restrict the zone to certain body layers (e.g. only enemies feel the slow field).
-- if false then -- Zone:setLayerMask
--   local world = lurek.physics.newWorld(0, 9.81)
--   local slow = world:addZone(100, 100, 200, 200)
--   slow:setLayerMask(0x02)
-- end

--@api-stub: LZone:setCircle
-- Replaces the zone boundary with a circle.
-- Switch from rectangle to circular boundary Ă˘â‚¬â€ť useful for blast radii or planet wells.
-- if false then -- Zone:setCircle
--   local world = lurek.physics.newWorld(0, 9.81)
--   local well = world:addZone(0, 0, 1, 1)
--   well:setCircle(400, 300, 120)
-- end

--@api-stub: LZone:setGravityDirectional
-- Sets directional gravity inside the zone.
-- Use for water (light downward pull) or wind tunnels (sideways pull).
-- if false then -- Zone:setGravityDirectional
--   local world = lurek.physics.newWorld(0, 9.81)
--   local water = world:addZone(0, 400, 800, 200)
--   water:setGravityDirectional(0, 2.0)
-- end

--@api-stub: LZone:setGravityZero
-- Suppresses gravity inside the zone (zero-g pocket).
-- Make a zero-g pocket inside the level (space station chamber, magic bubble).
-- if false then -- Zone:setGravityZero
--   local world = lurek.physics.newWorld(0, 9.81)
--   local bubble = world:addZone(300, 100, 200, 200)
--   bubble:setGravityZero()
-- end

--@api-stub: LZone:setLinearDampingOverride
-- Sets an optional linear damping override for bodies inside the zone.
-- Use to slow projectiles inside molasses; pass nil to clear and restore body damping.
-- if false then -- Zone:setLinearDampingOverride
--   local world = lurek.physics.newWorld(0, 9.81)
--   local glue = world:addZone(0, 0, 100, 100)
--   glue:setLinearDampingOverride(5.0)
-- end

--@api-stub: LZone:destroy
-- Removes the zone from the world.
-- Call when the trigger area despawns (door closed, level changed) to free zone memory.
-- if false then -- Zone:destroy
--   local world = lurek.physics.newWorld(0, 9.81)
--   local zone = world:addZone(0, 0, 100, 100)
--   zone:destroy()
-- end


-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ Terrain methods Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

--@api-stub: LTerrain:setCell
-- Sets a single terrain cell to solid or empty.
-- Use for surgical edits like spawning a single block; bulk dig with fillCircle.
-- if false then -- Terrain:setCell
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   terrain:setCell(10, 5, true)
--   terrain:flush()
-- end

--@api-stub: LTerrain:getCell
-- Returns whether a cell is solid.
-- Probe before placing a structure Ă˘â‚¬â€ť fail early when target cells are not solid.
-- if false then -- Terrain:getCell
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   if terrain:getCell(10, 5) then lurek.log.debug("solid cell", "terrain") end
-- end

--@api-stub: LTerrain:fillAll
-- Sets every cell in the grid to `solid`.
-- Initialise an empty world (false) or a fully-buried one (true) before sculpting.
-- if false then -- Terrain:fillAll
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   terrain:fillAll(true)
-- end

--@api-stub: LTerrain:flush
-- Rebuilds physics bodies for all dirty chunks.
-- Call after every batch of edits, before world:step, to push collider changes to physics.
-- if false then -- Terrain:flush
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   terrain:setCell(5, 5, true)
--   terrain:flush()
-- end

--@api-stub: LTerrain:isDirty
-- Returns `true` when at least one chunk needs flushing.
-- Skip flush() when nothing changed this frame Ă˘â‚¬â€ť saves chunk rebuild work.
-- if false then -- Terrain:isDirty
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   if terrain:isDirty() then terrain:flush() end
-- end

--@api-stub: LTerrain:collapseColumns
-- Removes unsupported cells, returning the number of cells that fell.
-- Run after explosions / digging to drop unsupported cells; returns count for VFX scaling.
-- if false then -- Terrain:collapseColumns
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   local fell = terrain:collapseColumns()
--   lurek.log.info("collapsed " .. fell .. " cells", "terrain")
--   terrain:flush()
-- end

--@api-stub: LTerrain:solidPositions
-- Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
-- Iterate result to snapshot the terrain (e.g. spawn debris from a dug-out region).
-- if false then -- Terrain:solidPositions
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   terrain:fillAll(true)
--   local positions = terrain:solidPositions()
--   lurek.log.debug("solid cells=" .. #positions, "terrain")
-- end

--@api-stub: LTerrain:toBytes
-- Serialises the terrain grid to a byte string for save/load.
-- Serialize the terrain grid; pair with lurek.fs.write to persist to a save slot.
-- if false then -- Terrain:toBytes
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   local bytes = terrain:toBytes()
--   lurek.log.info("terrain blob=" .. #bytes .. " bytes", "save")
-- end

--@api-stub: LTerrain:loadFromBytes
-- Loads terrain cell data from bytes produced by `toBytes`.
-- Restore from a save blob; remember to flush() afterwards to rebuild colliders.
-- if false then -- Terrain:loadFromBytes
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
--   local snapshot = terrain:toBytes()
--   terrain:loadFromBytes(snapshot)
--   terrain:flush()
-- end


-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ Cellular methods Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

--@api-stub: LCellular:setCell
-- Sets the material of a cell.
-- Use to spawn material (sand, water) at a specific cell Ă˘â‚¬â€ť typically from a player tool.
-- if false then -- Cellular:setCell
--   local sand = lurek.physics.newCellular(128, 64)
--   sand:setCell(64, 0, lurek.physics.CELL_SAND)
--   sand:setCell(65, 0, lurek.physics.CELL_WATER)
-- end

--@api-stub: LCellular:getCell
-- Returns the material at `(cx, cy)` as an integer constant.
-- Probe before placing a barrier Ă˘â‚¬â€ť only act when the source cell is empty.
-- if false then -- Cellular:getCell
--   local sand = lurek.physics.newCellular(128, 64)
--   if sand:getCell(10, 10) == lurek.physics.CELL_AIR then
--     sand:setCell(10, 10, lurek.physics.CELL_ROCK)
--   end
-- end

--@api-stub: LCellular:step
-- Advances the simulation by one tick.
-- Drive the simulation each frame from lurek.process Ă˘â‚¬â€ť sand falls, water spreads.
-- if false then -- Cellular:step
--   local sand = lurek.physics.newCellular(128, 64)
--   function lurek.process(dt)
--     sand:step()
--   end
-- end

--@api-stub: LCellular:stepN
-- Advances the simulation by `n` ticks.
-- Use to fast-forward (e.g. 30 ticks at scene load) to settle freshly poured material.
-- if false then -- Cellular:stepN
--   local sand = lurek.physics.newCellular(128, 64)
--   sand:stepN(30)
-- end

--@api-stub: LCellular:toImageData
-- Returns the full grid as an RGBA byte string using the default colour palette.
-- Render the grid as a texture each frame for cheap visualisation of millions of cells.
-- if false then -- Cellular:toImageData
--   local sand = lurek.physics.newCellular(128, 64)
--   local rgba = sand:toImageData()
--   lurek.log.debug("cellular bytes=" .. #rgba, "cell")
-- end

--@api-stub: LCellular:countCells
-- Counts cells of the given material type.
-- Use for HUD counters (water level, sand remaining) or victory conditions.
-- if false then -- Cellular:countCells
--   local sand = lurek.physics.newCellular(128, 64)
--   local water = sand:countCells(lurek.physics.CELL_WATER)
--   lurek.log.debug("water cells=" .. water, "cell")
-- end

--@api-stub: LCellular:findCells
-- Returns positions of all cells of the given material as an array of `{x, y}` tables.
-- Iterate to spawn dynamic bodies on every fire cell (e.g. flame particle system).
-- if false then -- Cellular:findCells
--   local sand = lurek.physics.newCellular(128, 64)
--   for _, p in ipairs(sand:findCells(lurek.physics.CELL_FIRE)) do
--     lurek.log.debug("fire at " .. p.x .. "," .. p.y, "cell")
--   end
-- end

--@api-stub: LCellular:toBytes
-- Serialises the grid to a byte string.
-- Serialize for save game; pairs with loadFromBytes to round-trip the grid.
-- if false then -- Cellular:toBytes
--   local sand = lurek.physics.newCellular(128, 64)
--   local blob = sand:toBytes()
--   lurek.log.info("cellular blob=" .. #blob .. " bytes", "save")
-- end

--@api-stub: LCellular:loadFromBytes
-- Loads grid data from bytes produced by `toBytes`.
-- Restore on level load; returns false when the byte string is corrupt or wrong size.
-- if false then -- Cellular:loadFromBytes
--   local sand = lurek.physics.newCellular(128, 64)
--   local blob = sand:toBytes()
--   local ok = sand:loadFromBytes(blob)
--   lurek.log.info("cellular reload ok=" .. tostring(ok), "save")
-- end


-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ Body methods Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

--@api-stub: LBody:getId
-- Returns the body's integer ID.
-- Capture the id when you need to refer to the body across save/load or RPC boundaries.
-- if false then -- Body:getId
--   local world = lurek.physics.newWorld(0, 9.81)
--   local crate = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("crate id=" .. crate:getId(), "phys")
-- end

--@api-stub: LBody:getPosition
-- Returns the body position (x, y).
-- Read inside lurek.process to sync sprite position to physics every frame.
-- if false then -- Body:getPosition
--   local world = lurek.physics.newWorld(0, 9.81)
--   local crate = world:newBody(100, 200, "dynamic")
--   local x, y = crate:getPosition()
--   lurek.log.debug("crate at " .. x .. "," .. y, "phys")
-- end

--@api-stub: LBody:setPosition
-- Teleports the body to the given world-space position, bypassing collision.
-- Use for teleports / respawns; bypasses collision so prefer applyImpulse for normal motion.
-- if false then -- Body:setPosition
--   local world = lurek.physics.newWorld(0, 9.81)
--   local player = world:newBody(100, 200, "dynamic")
--   player:setPosition(400, 300)
-- end

--@api-stub: LBody:getX
-- Returns the body X position.
-- Use the single-axis form when you only need one coordinate (left/right culling check).
-- if false then -- Body:getX
--   local world = lurek.physics.newWorld(0, 9.81)
--   local enemy = world:newBody(900, 200, "dynamic")
--   if enemy:getX() > 800 then enemy:destroy() end
-- end

--@api-stub: LBody:getY
-- Returns the body Y position.
-- Use to detect falling out of the world (death plane below screen).
-- if false then -- Body:getY
--   local world = lurek.physics.newWorld(0, 9.81)
--   local player = world:newBody(100, 200, "dynamic")
--   if player:getY() > 1000 then player:setPosition(100, 200) end
-- end

--@api-stub: LBody:getVelocity
-- Returns the body velocity (vx, vy).
-- Use to compute screen-shake intensity, motion blur, or attack-direction logic.
-- if false then -- Body:getVelocity
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   local vx, vy = body:getVelocity()
--   lurek.log.debug("v=" .. vx .. "," .. vy, "phys")
-- end

--@api-stub: LBody:setVelocity
-- Sets the body's linear velocity in world units per second.
-- Use for character controllers that override physics each frame (top-down movement).
-- if false then -- Body:setVelocity
--   local world = lurek.physics.newWorld(0, 9.81)
--   local player = world:newBody(100, 200, "dynamic")
--   function lurek.process(dt)
--     player:setVelocity(150, 0)
--   end
-- end

--@api-stub: LBody:getAngle
-- Returns the body angle in radians.
-- Use to drive sprite rotation; angle is in radians, multiply by math.deg if needed.
-- if false then -- Body:getAngle
--   local world = lurek.physics.newWorld(0, 9.81)
--   local crate = world:newBody(100, 200, "dynamic")
--   local rad = crate:getAngle()
--   lurek.log.debug("angle=" .. rad .. " rad", "phys")
-- end

--@api-stub: LBody:setAngle
-- Sets the body angle in radians.
-- Snap orientation for cutscenes; pair with setAngularVelocity(0) to stop spin.
-- if false then -- Body:setAngle
--   local world = lurek.physics.newWorld(0, 9.81)
--   local sign = world:newBody(200, 200, "static")
--   sign:setAngle(math.pi / 4)
-- end

--@api-stub: LBody:getAngularVelocity
-- Returns the angular velocity in radians/s.
-- Use to detect overspin (e.g. a top-down car drifting) and apply braking torque.
-- if false then -- Body:getAngularVelocity
--   local world = lurek.physics.newWorld(0, 9.81)
--   local wheel = world:newBody(100, 200, "dynamic")
--   if math.abs(wheel:getAngularVelocity()) > 30 then
--     wheel:applyTorque(-5)
--   end
-- end

--@api-stub: LBody:setAngularVelocity
-- Sets the angular velocity.
-- Use to spin a turret to a target rate without applying torque every frame.
-- if false then -- Body:setAngularVelocity
--   local world = lurek.physics.newWorld(0, 9.81)
--   local turret = world:newBody(200, 200, "kinematic")
--   turret:setAngularVelocity(1.5)
-- end

--@api-stub: LBody:getMass
-- Returns the body mass in kilograms used for force and impulse calculations.
-- Use to compute kinetic energy or HUD weight readouts (forklift demo).
-- if false then -- Body:getMass
--   local world = lurek.physics.newWorld(0, 9.81)
--   local crate = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("crate mass=" .. crate:getMass() .. " kg", "phys")
-- end

--@api-stub: LBody:setMass
-- Sets the body mass; affects how forces and impulses change velocity.
-- Override the mass derived from shape density Ă˘â‚¬â€ť use for game-feel tuning.
-- if false then -- Body:setMass
--   local world = lurek.physics.newWorld(0, 9.81)
--   local heavy = world:newBody(100, 200, "dynamic")
--   heavy:setMass(50.0)
-- end

--@api-stub: LBody:getType
-- Returns the body type as a string.
-- Branch on the type before applying impulses Ă˘â‚¬â€ť only dynamic bodies respond.
-- if false then -- Body:getType
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   if body:getType() == "dynamic" then body:applyImpulse(0, -50) end
-- end

--@api-stub: LBody:setType
-- Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
-- Promote a static prop to dynamic when destroyed (a wall becomes rubble).
-- if false then -- Body:setType
--   local world = lurek.physics.newWorld(0, 9.81)
--   local wall = world:newBody(200, 200, "static")
--   wall:setType("dynamic")
-- end

--@api-stub: LBody:getWidth
-- Returns the width of this body's primary collider shape in world units.
-- Use to size a debug AABB or to centre a sprite over a body of unknown extent.
-- if false then -- Body:getWidth
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("body width=" .. body:getWidth(), "phys")
-- end

--@api-stub: LBody:getHeight
-- Returns the height of this body's primary collider shape in world units.
-- Pair with getWidth to drive sprite scale or bounding-box outline rendering.
-- if false then -- Body:getHeight
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("body height=" .. body:getHeight(), "phys")
-- end

--@api-stub: LBody:getFriction
-- Returns the body friction coefficient.
-- Compare to a target value before mutating Ă˘â‚¬â€ť avoid wakes on bodies already at the right value.
-- if false then -- Body:getFriction
--   local world = lurek.physics.newWorld(0, 9.81)
--   local crate = world:newBody(100, 200, "dynamic")
--   if crate:getFriction() < 0.5 then crate:setFriction(0.7) end
-- end

--@api-stub: LBody:setFriction
-- Sets the body friction coefficient.
-- Use 0.0 for ice, 0.7 for wood, 1.0+ for rubber Ă˘â‚¬â€ť tune for the surface material.
-- if false then -- Body:setFriction
--   local world = lurek.physics.newWorld(0, 9.81)
--   local ice = world:newBody(100, 200, "dynamic")
--   ice:setFriction(0.05)
-- end

--@api-stub: LBody:getRestitution
-- Returns the body restitution (bounciness).
-- Use to drive impact sound volume: bouncier collisions deserve louder thuds.
-- if false then -- Body:getRestitution
--   local world = lurek.physics.newWorld(0, 9.81)
--   local ball = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("ball bounce=" .. ball:getRestitution(), "phys")
-- end

--@api-stub: LBody:setRestitution
-- Sets the body restitution (bounciness).
-- 0.0 = no bounce, 1.0 = perfectly elastic; rubber balls sit around 0.8.
-- if false then -- Body:setRestitution
--   local world = lurek.physics.newWorld(0, 9.81)
--   local ball = world:newBody(100, 200, "dynamic")
--   ball:setRestitution(0.8)
-- end

--@api-stub: LBody:getLayer
-- Returns the collision layer bitmask.
-- Read to verify a body is on the right collision layer (pickup vs solid).
-- if false then -- Body:getLayer
--   local world = lurek.physics.newWorld(0, 9.81)
--   local pickup = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("layer=" .. pickup:getLayer(), "phys")
-- end

--@api-stub: LBody:setLayer
-- Sets the collision layer bitmask.
-- Use bitmask layers (1=player, 2=enemy, 4=pickup) for filterable collision groups.
-- if false then -- Body:setLayer
--   local world = lurek.physics.newWorld(0, 9.81)
--   local pickup = world:newBody(100, 200, "dynamic")
--   pickup:setLayer(0x04)
-- end

--@api-stub: LBody:getMask
-- Returns the collision mask bitmask.
-- Read to debug collision filtering Ă˘â‚¬â€ť body sees layers in the mask, ignores others.
-- if false then -- Body:getMask
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("mask=" .. body:getMask(), "phys")
-- end

--@api-stub: LBody:setMask
-- Sets the collision mask bitmask.
-- Restrict who this body collides with (e.g. ghost passes through enemies but hits walls).
-- if false then -- Body:setMask
--   local world = lurek.physics.newWorld(0, 9.81)
--   local ghost = world:newBody(100, 200, "dynamic")
--   ghost:setMask(0x01)
-- end

--@api-stub: LBody:applyImpulse
-- Applies a linear impulse to the body.
-- Use for instantaneous velocity changes (jump, blast knockback, projectile fire).
-- if false then -- Body:applyImpulse
--   local world = lurek.physics.newWorld(0, 9.81)
--   local player = world:newBody(100, 200, "dynamic")
--   function lurek.process(dt)
--     if lurek.input.keyboard.isDown("space") then player:applyImpulse(0, -300) end
--   end
-- end

--@api-stub: LBody:applyForce
-- Applies a continuous force to the body.
-- Use for continuous forces (thrust, wind); call every frame inside lurek.process.
-- if false then -- Body:applyForce
--   local world = lurek.physics.newWorld(0, 9.81)
--   local rocket = world:newBody(100, 200, "dynamic")
--   function lurek.process(dt)
--     rocket:applyForce(0, -200)
--   end
-- end

--@api-stub: LBody:applyTorque
-- Applies a torque (rotational force).
-- Use to spin up a wheel or give a thrown object a tumble Ă˘â‚¬â€ť accumulates over the step.
-- if false then -- Body:applyTorque
--   local world = lurek.physics.newWorld(0, 9.81)
--   local wheel = world:newBody(100, 200, "dynamic")
--   wheel:applyTorque(50.0)
-- end

--@api-stub: LBody:applyAngularImpulse
-- Applies an angular impulse.
-- Use for one-shot spin changes (e.g. a hit that sends a top spinning).
-- if false then -- Body:applyAngularImpulse
--   local world = lurek.physics.newWorld(0, 9.81)
--   local top = world:newBody(100, 200, "dynamic")
--   top:applyAngularImpulse(2.5)
-- end

--@api-stub: LBody:getGravityScale
-- Returns the per-body gravity multiplier.
-- Read for HUD (gravity boots indicator) or to verify a buoyancy effect was applied.
-- if false then -- Body:getGravityScale
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("g-scale=" .. body:getGravityScale(), "phys")
-- end

--@api-stub: LBody:setGravityScale
-- Sets the per-body gravity multiplier.
-- Use 0 for floaty objects (balloons, magic), 2 for heavy ones (anvils).
-- if false then -- Body:setGravityScale
--   local world = lurek.physics.newWorld(0, 9.81)
--   local balloon = world:newBody(100, 200, "dynamic")
--   balloon:setGravityScale(-0.5)
-- end

--@api-stub: LBody:isFixedRotation
-- Returns whether rotation is locked.
-- Branch before setting; locking rotation again is a no-op but force adjustments are not.
-- if false then -- Body:isFixedRotation
--   local world = lurek.physics.newWorld(0, 9.81)
--   local player = world:newBody(100, 200, "dynamic")
--   if not player:isFixedRotation() then player:setFixedRotation(true) end
-- end

--@api-stub: LBody:setFixedRotation
-- Locks or unlocks rotation.
-- Lock player / NPC bodies upright so they do not topple over after a hit.
-- if false then -- Body:setFixedRotation
--   local world = lurek.physics.newWorld(0, 9.81)
--   local player = world:newBody(100, 200, "dynamic")
--   player:setFixedRotation(true)
-- end

--@api-stub: LBody:getLinearDamping
-- Returns the linear damping coefficient.
-- Read for tuning UI; higher damping bleeds velocity faster (drag).
-- if false then -- Body:getLinearDamping
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("damping=" .. body:getLinearDamping(), "phys")
-- end

--@api-stub: LBody:setLinearDamping
-- Sets the linear damping coefficient.
-- Use 0 for vacuum, 0.5 for air, 5+ for water Ă˘â‚¬â€ť simulates fluid drag without a zone.
-- if false then -- Body:setLinearDamping
--   local world = lurek.physics.newWorld(0, 9.81)
--   local fish = world:newBody(100, 200, "dynamic")
--   fish:setLinearDamping(2.0)
-- end

--@api-stub: LBody:getAngularDamping
-- Returns the angular damping coefficient.
-- Read to debug bodies that keep spinning forever Ă˘â‚¬â€ť usually damping=0 is the cause.
-- if false then -- Body:getAngularDamping
--   local world = lurek.physics.newWorld(0, 9.81)
--   local top = world:newBody(100, 200, "dynamic")
--   lurek.log.debug("ang damping=" .. top:getAngularDamping(), "phys")
-- end

--@api-stub: LBody:setAngularDamping
-- Sets the angular damping coefficient.
-- Apply moderate damping (0.5) to thrown objects so they settle within a few seconds.
-- if false then -- Body:setAngularDamping
--   local world = lurek.physics.newWorld(0, 9.81)
--   local crate = world:newBody(100, 200, "dynamic")
--   crate:setAngularDamping(0.5)
-- end

--@api-stub: LBody:isBullet
-- Returns whether CCD is enabled.
-- Check before relying on CCD-only logic (e.g. armour-piercing rules).
-- if false then -- Body:isBullet
--   local world = lurek.physics.newWorld(0, 9.81)
--   local proj = world:newBody(100, 200, "dynamic")
--   if proj:isBullet() then lurek.log.debug("CCD on", "phys") end
-- end

--@api-stub: LBody:setBullet
-- Enables or disables continuous collision detection (CCD) for fast-moving bodies.
-- Enable on bullets, arrows, and high-velocity debris to prevent tunnelling.
-- if false then -- Body:setBullet
--   local world = lurek.physics.newWorld(0, 9.81)
--   local arrow = world:newBody(100, 200, "dynamic")
--   arrow:setBullet(true)
-- end

--@api-stub: LBody:isSleepingAllowed
-- Returns whether the body can sleep.
-- Read before disabling Ă˘â‚¬â€ť gameplay-critical bodies should never sleep.
-- if false then -- Body:isSleepingAllowed
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   if body:isSleepingAllowed() then body:setSleepingAllowed(false) end
-- end

--@api-stub: LBody:setSleepingAllowed
-- Sets whether the body can sleep.
-- Disable on the player and active enemies; allow on world clutter to save CPU.
-- if false then -- Body:setSleepingAllowed
--   local world = lurek.physics.newWorld(0, 9.81)
--   local player = world:newBody(100, 200, "dynamic")
--   player:setSleepingAllowed(false)
-- end

--@api-stub: LBody:destroy
-- Removes this body from the world.
-- Call on entity death; the underlying world body is removed and id becomes invalid.
-- if false then -- Body:destroy
--   local world = lurek.physics.newWorld(0, 9.81)
--   local enemy = world:newBody(100, 200, "dynamic")
--   enemy:destroy()
-- end

--@api-stub: LBody:isSleeping
-- Returns true if this body is currently sleeping (inactive).
-- Use to gate per-frame work (AI, sound) on inactive bodies Ă˘â‚¬â€ť saves frame budget.
-- if false then -- Body:isSleeping
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   if not body:isSleeping() then lurek.log.debug("active", "phys") end
-- end

--@api-stub: LBody:wakeUp
-- Forcibly wakes up this body.
-- Call before applyForce / setVelocity if a body might be sleeping; otherwise the call is ignored.
-- if false then -- Body:wakeUp
--   local world = lurek.physics.newWorld(0, 9.81)
--   local body = world:newBody(100, 200, "dynamic")
--   body:wakeUp()
--   body:applyImpulse(0, -100)
-- end

--@api-stub: LBody:sleep
-- Puts this body to sleep immediately.
-- Force-sleep stationary debris piles to remove them from the active solver set.
-- if false then -- Body:sleep
--   local world = lurek.physics.newWorld(0, 9.81)
--   local rubble = world:newBody(100, 200, "dynamic")
--   rubble:sleep()
-- end


-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ PhysicsShape methods Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

--@api-stub: LPhysicsShape:getType
-- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
-- Branch on the type string when serialising or rendering shape-specific debug overlays.
-- if false then -- PhysicsShape:getType
--   local shape = lurek.physics.newCircleShape(16)
--   if shape:getType() == "circle" then
--     lurek.log.debug("ball-shape r=" .. shape:getRadius(), "phys")
--   end
-- end

--@api-stub: LPhysicsShape:getRadius
-- Returns the radius.
-- Only meaningful for circle shapes; returns 0 (or fails) on rectangles and polygons.
-- if false then -- PhysicsShape:getRadius
--   local ball = lurek.physics.newCircleShape(16)
--   lurek.log.debug("radius=" .. ball:getRadius(), "phys")
-- end

--@api-stub: LPhysicsShape:getBoundingBox
-- Returns the axis-aligned bounding box (x1, y1, x2, y2).
-- Use to size an outline draw or to test broad-phase overlap before doing a precise check.
-- if false then -- PhysicsShape:getBoundingBox
--   local crate_shape = lurek.physics.newRectangleShape(64, 32)
--   local x1, y1, x2, y2 = crate_shape:getBoundingBox()
--   lurek.log.debug("aabb " .. x1 .. "," .. y1 .. "->" .. x2 .. "," .. y2, "phys")
-- end

--@api-stub: LPhysicsShape:setDensity
-- Sets the density for this shape (used when attaching to a body).
-- Set BEFORE attachShape Ă˘â‚¬â€ť once attached, density does not retro-actively re-derive mass.
-- if false then -- PhysicsShape:setDensity
--   local shape = lurek.physics.newRectangleShape(32, 32)
--   shape:setDensity(2.0)
-- end

--@api-stub: LPhysicsShape:setFriction
-- Sets the friction coefficient.
-- Use to make ice (0.05), wood (0.7), or rubber (1.2) shape-by-shape.
-- if false then -- PhysicsShape:setFriction
--   local shape = lurek.physics.newRectangleShape(32, 32)
--   shape:setFriction(0.7)
-- end

--@api-stub: LPhysicsShape:setRestitution
-- Sets the restitution (bounciness) coefficient.
-- 0.0 for no bounce, 0.8 for rubber ball; usually paired with low friction for physics toys.
-- if false then -- PhysicsShape:setRestitution
--   local ball = lurek.physics.newCircleShape(16)
--   ball:setRestitution(0.85)
-- end

--@api-stub: LPhysicsShape:setSensor
-- Sets whether this shape is a sensor (non-colliding trigger).
-- Use for trigger volumes (pickup zones, kill planes) Ă˘â‚¬â€ť fires events but does not block.
-- if false then -- PhysicsShape:setSensor
--   local trigger = lurek.physics.newRectangleShape(64, 64)
--   trigger:setSensor(true)
-- end

--@api-stub: LPhysicsShape:destroy
-- Releases this shape handle (GC handles cleanup).
-- Manual destroy is rarely needed; GC drops the shape when no Lua / body holds a reference.
-- if false then -- PhysicsShape:destroy
--   local shape = lurek.physics.newRectangleShape(32, 32)
--   shape:destroy()
--   shape = nil --[[@type any]]
-- end

--@api-stub: lurek.physics.testAABB
-- Test overlap between two axis-aligned bounding boxes.
-- Returns true if the boxes overlap; false otherwise.
-- if false then -- lurek.physics.testAABB
--   if lurek.physics.testAABB then
--     local hit = lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 20, 20)
--     lurek.log.debug("AABB overlap=" .. tostring(hit), "physics")
--   end
-- end

--@api-stub: lurek.physics.testCircles
-- Test overlap between two circles defined by centre and radius.
-- Returns true if the circles overlap.
-- if false then -- lurek.physics.testCircles
--   if lurek.physics.testCircles then
--     local hit = lurek.physics.testCircles(0, 0, 5, 3, 3, 5)
--     lurek.log.debug("circles overlap=" .. tostring(hit), "physics")
--   end
-- end

--@api-stub: lurek.physics.testCircleAABB
-- Test overlap between a circle and an AABB.
-- Returns true if the shapes overlap.
-- if false then -- lurek.physics.testCircleAABB
--   if lurek.physics.testCircleAABB then
--     local hit = lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10)
--     lurek.log.debug("circle-AABB overlap=" .. tostring(hit), "physics")
--   end
-- end

--@api-stub: lurek.physics.testPoint
-- Test whether a point lies inside an AABB.
-- Returns true if the point is within the box.
-- if false then -- lurek.physics.testPoint
--   if lurek.physics.testPoint then
--     local hit = lurek.physics.testPoint(5, 5, 0, 0, 10, 10)
--     lurek.log.debug("point-in-AABB=" .. tostring(hit), "physics")
--   end
-- end

--@api-stub: LWorld:addDistanceJoint
-- Creates a distance joint keeping two bodies at a fixed separation.
-- damping and frequency control spring-like oscillation; 0 damping = rigid rod.
-- if false then -- World:addDistanceJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(100, 100, "dynamic")
--   local b = world:newBody(200, 100, "dynamic")
--   local jid = world:addDistanceJoint(a:getId(), b:getId(), 100, 100, 200, 100, 100)
--   lurek.log.info("distance joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addFixture
-- Attaches a shape fixture to an existing body with friction and restitution.
-- Multiple fixtures give a body a composite collision shape.
-- if false then -- World:addFixture
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newBody(200, 200, "dynamic")
--   local fid = world:addFixture(b:getId(), "circle", 1.0, 0.4, 0.3, false, 16.0)
--   lurek.log.info("fixture id: " .. fid, "physics")
-- end

--@api-stub: LWorld:addFrictionJoint
-- Creates a friction joint that resists relative linear and angular motion.
-- maxForce and maxTorque cap the damping; use for ice-skating or surface drag.
-- if false then -- World:addFrictionJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(100, 100, "dynamic")
--   local b = world:newBody(100, 100, "static")
--   local jid = world:addFrictionJoint(a:getId(), b:getId(), 100, 100, 50, 10)
--   lurek.log.info("friction joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addGearJoint
-- Links two revolute or prismatic joints so their motion stays coupled by a ratio.
-- Simulates gear trains; both joints must already exist in the same world.
-- if false then -- World:addGearJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(100, 200, "dynamic")
--   local b = world:newBody(200, 200, "dynamic")
--   local c = world:newBody(150, 200, "static")
--   local j1 = world:addRevoluteJoint(c:getId(), a:getId(), 100, 200)
--   local j2 = world:addRevoluteJoint(c:getId(), b:getId(), 200, 200)
--   local jid = world:addGearJoint(a:getId(), b:getId(), 150, 200)
--   lurek.log.info("gear joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addMotorJoint
-- Creates a motor joint that drives one body to match the position/angle of another.
-- maxForce and maxTorque control how aggressively the motor corrects offset.
-- if false then -- World:addMotorJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(100, 100, "dynamic")
--   local b = world:newBody(200, 200, "dynamic")
--   local jid = world:addMotorJoint(a:getId(), b:getId(), 0.3)
--   lurek.log.info("motor joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addMouseJoint
-- Creates a spring-like joint from a body to a moving screen position (drag-and-drop).
-- maxForce prevents the joint from exploding when the target moves quickly.
-- if false then -- World:addMouseJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newBody(200, 200, "dynamic")
--   local jid = world:addMouseJoint(b:getId(), 200, 200, 1000)
--   lurek.log.info("mouse joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addPrismaticJoint
-- Creates a prismatic joint allowing translation along one axis only.
-- Use for sliding doors, pistons, or elevator platforms.
-- if false then -- World:addPrismaticJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(100, 300, "static")
--   local b = world:newBody(100, 200, "dynamic")
--   local jid = world:addPrismaticJoint(a:getId(), b:getId(), 100, 300, 0, -1)
--   lurek.log.info("prismatic joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addPulleyJoint
-- Creates a pulley joint constraining two bodies through a fixed rope length.
-- lengthA + lengthB == total rope; a ratio != 1 simulates a block-and-tackle.
-- if false then -- World:addPulleyJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(100, 200, "dynamic")
--   local b = world:newBody(300, 200, "dynamic")
--   local jid = world:addPulleyJoint(a:getId(), b:getId(), 100, 100)
--   lurek.log.info("pulley joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addRevoluteJoint
-- Creates a revolute (hinge) joint at a world-space anchor point.
-- Bodies can rotate freely about the anchor; add limits to constrain the angle.
-- if false then -- World:addRevoluteJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local door = world:newBody(200, 200, "dynamic")
--   local wall  = world:newBody(200, 200, "static")
--   local jid = world:addRevoluteJoint(wall:getId(), door:getId(), 200, 200)
--   lurek.log.info("revolute joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addRopeJoint
-- Creates a rope joint that prevents two bodies from exceeding a max distance.
-- Slack means bodies can be closer; maxLength is the hard upper limit.
-- if false then -- World:addRopeJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(100, 100, "dynamic")
--   local b = world:newBody(100, 200, "dynamic")
--   local jid = world:addRopeJoint(a:getId(), b:getId(), 100, 100, 100, 200, 120)
--   lurek.log.info("rope joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addWeldJoint
-- Welds two bodies together at their current relative positions.
-- frequency and damping add slight spring flexibility to prevent solver jitter.
-- if false then -- World:addWeldJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(150, 200, "dynamic")
--   local b = world:newBody(170, 200, "dynamic")
--   local jid = world:addWeldJoint(a:getId(), b:getId(), 160, 200)
--   lurek.log.info("weld joint: " .. jid, "physics")
-- end

--@api-stub: LWorld:addWheelJoint
-- Creates a wheel joint for vehicle suspension: translation + rotation + motor.
-- Adjust frequency and damping to tune suspension stiffness and bounce.
-- if false then -- World:addWheelJoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local chassis = world:newBody(200, 200, "dynamic")
--   local wheel   = world:newBody(200, 240, "dynamic")
--   local jid = world:addWheelJoint(chassis:getId(), wheel:getId(), 200, 240, 0, -1)
--   lurek.log.info("wheel joint: " .. jid, "physics")
-- end

--@api-stub: LBody:applyForceAtPoint
-- Applies a force at an off-centre world-space point, generating torque.
-- Use for realistic drag, thrust, or projectile impact forces.
-- if false then -- Body:applyForceAtPoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newBody(200, 200, "dynamic")
--   b:applyForceAtPoint(100, 0, 220, 200)
--   lurek.log.info("force at point applied", "physics")
-- end

--@api-stub: LWorld:drawDebug
-- Renders physics shapes, joints, and AABBs using the engine's debug draw API.
-- Call inside lurek.draw() to overlay the physics debug visualisation.
-- if false then -- World:drawDebug
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:newBody(200, 200, "static")
--   local debug_img = lurek.image.newImageData(400, 400)
--   function lurek.draw()
--     world:drawDebug(debug_img)
--   end
--   lurek.log.info("drawDebug hooked", "physics")
-- end

--@api-stub: LTerrain:fillCircle
-- Fills a circular region of the destructible terrain with a given cell value.
-- Used to create craters; value=0 makes cells empty (air), 1=solid.
-- if false then -- Terrain:fillCircle
--   local _world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 64, 8, _world)
--   terrain:fillAll(true)
--   terrain:fillCircle(32, 32, 10, false)
--   terrain:flush()
--   lurek.log.info("terrain crater dug", "physics")
-- end

--@api-stub: LCellular:fillCircle
-- Fills a circular region of a cellular automaton grid with a given state value.
-- Useful for initialising cave seeds or spawning growth patches.
-- if false then -- Cellular:fillCircle
--   local ca = lurek.physics.newCellular(64, 64)
--   ca:fillCircle(32, 32, 20, 1)
--   lurek.log.info("cellular circle filled", "physics")
-- end

--@api-stub: LTerrain:fillRect
-- Fills a rectangular region of the destructible terrain with the given cell value.
-- value=1 places solid material; value=0 removes it.
-- if false then -- Terrain:fillRect
--   local _world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(64, 64, 8, _world)
--   terrain:fillRect(10, 10, 40, 40, true)
--   terrain:flush()
--   lurek.log.info("terrain rect filled", "physics")
-- end

--@api-stub: LCellular:fillRect
-- Fills a rectangular region of a cellular automaton grid with a given state.
-- Use to create initial conditions for cave generation or life simulations.
-- if false then -- Cellular:fillRect
--   local ca = lurek.physics.newCellular(32, 32)
--   ca:fillRect(4, 4, 28, 28, 1)
--   lurek.log.info("cellular rect filled", "physics")
-- end

--@api-stub: LWorld:newChainBody
-- Creates a chain-shape body from a sequence of vertices.
-- Chain shapes are one-sided and ideal for long terrain contours or platforms.
-- if false then -- World:newChainBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local verts = {0,400, 200,380, 400,400, 600,390, 800,400}
--   local b = world:newChainBody(0, 0, verts, false, "static")
--   lurek.log.info("chain body: " .. b:getId(), "physics")
-- end

--@api-stub: LWorld:newCircleBody
-- Creates a circle-shaped body at (x, y) with the given radius and type.
-- Faster and more stable than polygon approximations for round objects.
-- if false then -- World:newCircleBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newCircleBody(300, 200, 20, "dynamic")
--   lurek.log.info("circle body: " .. b:getId(), "physics")
-- end

--@api-stub: LWorld:newEdgeBody
-- Creates a single one-sided edge between two points as a static body.
-- Use for thin walls, platforms, or invisible boundaries.
-- if false then -- World:newEdgeBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newEdgeBody(0, 0, 0, 400, 800, 400, "static")
--   lurek.log.info("edge body: " .. b:getId(), "physics")
-- end

--@api-stub: LWorld:newPolygonBody
-- Creates a convex polygon body from a vertex table (max 8 vertices).
-- Vertices must be in counter-clockwise order; Box2D auto-computes the centroid.
-- if false then -- World:newPolygonBody
--   local world = lurek.physics.newWorld(0, 9.81)
--   local verts = {-20,-10, 20,-10, 20,10, -20,10}
--   local b = world:newPolygonBody(300, 200, verts, "dynamic")
--   lurek.log.info("polygon body: " .. b:getId(), "physics")
-- end

--@api-stub: LWorld:queryAABB
-- Returns all body IDs whose fixtures overlap the given axis-aligned bounding box.
-- Use for cheap broad-phase spatial queries before narrow-phase shape tests.
-- if false then -- World:queryAABB
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:newCircleBody(100, 100, 20, "static")
--   local hits = world:queryAABB(80, 80, 130, 130)
--   lurek.log.info("AABB hits: " .. #hits, "physics")
-- end

--@api-stub: LWorld:raycast
-- Fires a ray and returns the first hit body id, normal, and fraction.
-- Returns nil if no body is hit; fraction is in [0,1] along the ray.
-- if false then -- World:raycast
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:newCircleBody(200, 200, 30, "static")
--   local id, nx, ny, frac = world:raycast(0, 200, 400, 200)
--   lurek.log.info("raycast hit: " .. tostring(id), "physics")
-- end

--@api-stub: LWorld:raycastAll
-- Returns all bodies hit by a ray as a table of {id, normal, fraction} records.
-- Sorted by fraction (nearest first); useful for piercing shots.
-- if false then -- World:raycastAll
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:newCircleBody(100, 200, 20, "static")
--   world:newCircleBody(300, 200, 20, "static")
--   local hits = world:raycastAll(0, 200, 1, 0, 400)
--   lurek.log.info("all hits: " .. #hits, "physics")
-- end

--@api-stub: LWorld:raycastClosest
-- Returns only the closest body hit by a ray as {id, normal, fraction}.
-- Faster than raycastAll when only the nearest obstacle matters.
-- if false then -- World:raycastClosest
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:newCircleBody(150, 200, 20, "static")
--   local hit = world:raycastClosest(0, 200, 1, 0, 400)
--   lurek.log.info("closest hit: " .. tostring(hit and hit.id), "physics")
-- end

--@api-stub: LZone:setAngularDampingOverride
-- Sets an angular damping coefficient applied to all bodies inside this zone.
-- Override is only active while the body remains within the zone boundary.
-- if false then -- Zone:setAngularDampingOverride
--   local world = lurek.physics.newWorld(0, 9.81)
--   local z = world:addZone(100, 100, 300, 300)
--   z:setAngularDampingOverride(5.0)
--   lurek.log.info("zone angular damping set", "physics")
-- end

--@api-stub: LWorld:setBodyData
-- Attaches arbitrary Lua data to a body for retrieval in collision callbacks.
-- Common use: store the entity id or component table that owns the body.
-- if false then -- World:setBodyData
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newBody(200, 200, "dynamic")
--   world:setBodyData(b:getId(), {entityId=42, type="player"})
--   lurek.log.info("body data set", "physics")
-- end

--@api-stub: LWorld:setBodyOneWay
-- Marks a body as a one-way platform: only collides from one direction.
-- Pass the allowed normal direction (0,-1 = top surface; 0,1 = bottom).
-- if false then -- World:setBodyOneWay
--   local world = lurek.physics.newWorld(0, 9.81)
--   local platform = world:newBody(400, 300, "static")
--   world:setBodyOneWay(platform:getId(), 0, -1)
--   lurek.log.info("one-way platform set", "physics")
-- end

--@api-stub: LWorld:setFixtureFriction
-- Sets the friction coefficient on an existing fixture by its id.
-- Values in [0,1]; 0=ice, 1=rubber; default is 0.5.
-- if false then -- World:setFixtureFriction
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newBody(200, 200, "dynamic")
--   local fid = world:addFixture(b:getId(), "rectangle", 1.0, 0.5, 0.0, false, 32.0, 32.0)
--   world:setFixtureFriction(b:getId(), fid, 0.1)
--   lurek.log.info("fixture friction set", "physics")
-- end

--@api-stub: LWorld:setFixtureRestitution
-- Sets the restitution (bounciness) on an existing fixture.
-- 0 = completely inelastic; 1 = perfectly elastic bounce.
-- if false then -- World:setFixtureRestitution
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newBody(200, 200, "dynamic")
--   local fid = world:addFixture(b:getId(), "circle", 1.0, 0.5, 0.8, false, 16.0)
--   world:setFixtureRestitution(b:getId(), fid, 0.8)
--   lurek.log.info("restitution set", "physics")
-- end

--@api-stub: LWorld:setFixtureSensor
-- Marks a fixture as a sensor so it receives collision events but exerts no force.
-- Sensors detect overlaps without preventing movement; ideal for trigger zones.
-- if false then -- World:setFixtureSensor
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newBody(200, 200, "static")
--   local fid = world:addFixture(b:getId(), "circle", 0.0, 0.0, 0.0, true, 40.0)
--   world:setFixtureSensor(b:getId(), fid, true)
--   lurek.log.info("sensor fixture set", "physics")
-- end

--@api-stub: LZone:setGravityPoint
-- Sets gravity in the zone to pull bodies toward a point attractor.
-- strength > 0 pulls inward (planet gravity); < 0 pushes outward (explosion).
-- if false then -- Zone:setGravityPoint
--   local world = lurek.physics.newWorld(0, 9.81)
--   local z = world:addZone(0, 0, 800, 600)
--   z:setGravityPoint(400, 300, 500)
--   lurek.log.info("gravity point set", "physics")
-- end

--@api-stub: LZone:setGravityRepulsor
-- Sets gravity in the zone to push bodies away from a repulsor point.
-- strength controls force magnitude; useful for explosive force zones.
-- if false then -- Zone:setGravityRepulsor
--   local world = lurek.physics.newWorld(0, 9.81)
--   local z = world:addZone(200, 200, 600, 400)
--   z:setGravityRepulsor(400, 300, 300)
--   lurek.log.info("gravity repulsor set", "physics")
-- end

--@api-stub: LWorld:setJointLimits
-- Sets the angular or linear limits for an existing constrained joint.
-- For revolute joints: min/max are angles in radians; for prismatic: metres.
-- if false then -- World:setJointLimits
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(100, 200, "static")
--   local b = world:newBody(100, 100, "dynamic")
--   local jid = world:addRevoluteJoint(a:getId(), b:getId(), 100, 200)
--   world:setJointLimits(jid, -math.pi/4, math.pi/4)
--   lurek.log.info("joint limits set", "physics")
-- end

--@api-stub: LWorld:setJointLimitsEnabled
-- Enables or disables the angular/linear limits on an existing joint.
-- Toggle without removing the joint to implement retractable constraints.
-- if false then -- World:setJointLimitsEnabled
--   local world = lurek.physics.newWorld(0, 9.81)
--   local a = world:newBody(100, 200, "static")
--   local b = world:newBody(100, 100, "dynamic")
--   local jid = world:addRevoluteJoint(a:getId(), b:getId(), 100, 200)
--   world:setJointLimitsEnabled(jid, true)
--   lurek.log.info("joint limits enabled", "physics")
-- end

--@api-stub: LWorld:setJointMotorSpeed
-- Sets the motor speed for a revolute or prismatic joint motor.
-- Positive and negative values drive in opposite directions.
-- if false then -- World:setJointMotorSpeed
--   local world = lurek.physics.newWorld(0, 9.81)
--   local axle = world:newBody(200, 200, "static")
--   local wheel = world:newBody(200, 240, "dynamic")
--   local jid = world:addRevoluteJoint(axle:getId(), wheel:getId(), 200, 220)
--   world:setJointMotorSpeed(jid, 2.0)
--   lurek.log.info("motor speed: 2.0 rad/s", "physics")
-- end

--@api-stub: LWorld:setMouseJointTarget
-- Updates the target world position for an existing mouse joint each frame.
-- Call inside lurek.process(dt) with the current mouse world coordinates.
-- if false then -- World:setMouseJointTarget
--   local world = lurek.physics.newWorld(0, 9.81)
--   local b = world:newBody(300, 200, "dynamic")
--   local jid = world:addMouseJoint(b:getId(), 300, 200, 2000)
--   world:setMouseJointTarget(jid, 350, 250)
--   lurek.log.info("mouse joint target updated", "physics")
-- end

--@api-stub: LTerrain:spawnDebris
-- Spawns dynamic debris bodies for cells removed from the terrain.
-- Returns a table of new body ids; debris bodies settle under gravity.
-- if false then -- Terrain:spawnDebris
--   local world = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(32, 32, 8, world)
--   terrain:fillAll(true)
--   terrain:fillCircle(16, 16, 6, false)
--   terrain:flush()
--   local positions = terrain:solidPositions()
--   local debris = terrain:spawnDebris(positions, 1.0, 0.5)
--   lurek.log.info("debris count: " .. #debris, "physics")
-- end

--@api-stub: LWorld:stepFixed
-- Advances the physics world by a fixed timestep with an optional substep count.
-- Use instead of step() for deterministic simulations requiring fixed-rate updates.
-- if false then -- World:stepFixed
--   local world = lurek.physics.newWorld(0, 9.81)
--   world:stepFixed(1/60, 6, 2)
--   lurek.log.info("fixed step done", "physics")
-- end

--@api-stub: LTerrain:toImageData
-- Converts the terrain cell grid to an ImageData for rendering or saving.
-- Solid cells are opaque white; empty cells are transparent black.
-- if false then -- Terrain:toImageData
--   local _w = lurek.physics.newWorld(0, 9.81)
--   local terrain = lurek.physics.newTerrain(32, 32, 8, _w)
--   terrain:fillAll(true)
--   terrain:fillCircle(16, 16, 8, false)
--   terrain:flush()
--   local bytes = terrain:toImageData(255, 255, 255, 0, 0, 0)
--   lurek.log.info("terrain image: " .. #bytes .. " bytes", "physics")
-- end

--@api-stub: LCellular:toImageDataRegion
-- Converts a rectangular sub-region of the cellular grid to an ImageData.
-- More efficient than toImageData() when only part of the grid needs rendering.
-- if false then -- Cellular:toImageDataRegion
--   local ca = lurek.physics.newCellular(64, 64)
--   ca:fillRect(0, 0, 63, 63, 1)
--   local img = ca:toImageDataRegion(10, 10, 40, 40)
--   lurek.log.info("region img: " .. #img .. " bytes", "physics")
-- end

-- =============================================================================
-- STUBS: 12 uncovered lurek.physics API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Zone methods
-- -----------------------------------------------------------------------------

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
-- Useful for runtime type inspection.
-- if false then -- LBody:type
--   local w = lurek.physics.newWorld(0, 9.81)
--   local body_obj = w:newBody(0, 0, "dynamic")
--   local t = body_obj:type()
--   lurek.log.info("LBody:type = " .. t, "physics")
-- end
--@api-stub: LBody:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LBody:typeOf
--   local w2 = lurek.physics.newWorld(0, 9.81)
--   local body_obj2 = w2:newBody(0, 0, "dynamic")
--   lurek.log.info("is LBody: " .. tostring(body_obj2 and body_obj2:typeOf("LBody") or false), "physics")
--   lurek.log.info("is wrong: " .. tostring(body_obj2 and body_obj2:typeOf("Unknown") or false), "physics")
-- end
--@api-stub: LCellular:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LCellular:type
--   local cellular_obj = lurek.physics.newCellular(32, 32)
--   local t = cellular_obj:type()
--   lurek.log.info("LCellular:type = " .. t, "physics")
-- end
--@api-stub: LCellular:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LCellular:typeOf
--   local cellular_obj = lurek.physics.newCellular(32, 32)
--   lurek.log.info("is LCellular: " .. tostring(cellular_obj:typeOf("LCellular")), "physics")
--   lurek.log.info("is wrong: " .. tostring(cellular_obj:typeOf("Unknown")), "physics")
-- end
--@api-stub: LPhysicsShape:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LPhysicsShape:type
--   local physics_shape_obj = lurek.physics.newRectangleShape(32, 32)
--   local t = physics_shape_obj:type()
--   lurek.log.info("LPhysicsShape:type = " .. t, "physics")
-- end
--@api-stub: LPhysicsShape:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LPhysicsShape:typeOf
--   local physics_shape_obj = lurek.physics.newRectangleShape(32, 32)
--   lurek.log.info("is LPhysicsShape: " .. tostring(physics_shape_obj:typeOf("LPhysicsShape")), "physics")
--   lurek.log.info("is wrong: " .. tostring(physics_shape_obj:typeOf("Unknown")), "physics")
-- end
--@api-stub: LTerrain:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LTerrain:type
--   local _tw = lurek.physics.newWorld(0, 9.81)
--   local terrain_obj = lurek.physics.newTerrain(32, 32, 1.0, _tw)
--   local t = terrain_obj:type()
--   lurek.log.info("LTerrain:type = " .. t, "physics")
-- end
--@api-stub: LTerrain:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LTerrain:typeOf
--   local _tw2 = lurek.physics.newWorld(0, 9.81)
--   local terrain_obj = lurek.physics.newTerrain(32, 32, 1.0, _tw2)
--   lurek.log.info("is LTerrain: " .. tostring(terrain_obj:typeOf("LTerrain")), "physics")
--   lurek.log.info("is wrong: " .. tostring(terrain_obj:typeOf("Unknown")), "physics")
-- end
--@api-stub: LWorld:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LWorld:type
--   local world_obj = lurek.physics.newWorld(0, 9.81)
--   local t = world_obj:type()
--   lurek.log.info("LWorld:type = " .. t, "physics")
-- end
--@api-stub: LWorld:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LWorld:typeOf
--   local world_obj = lurek.physics.newWorld(0, 9.81)
--   lurek.log.info("is LWorld: " .. tostring(world_obj:typeOf("LWorld")), "physics")
--   lurek.log.info("is wrong: " .. tostring(world_obj:typeOf("Unknown")), "physics")
-- end
--@api-stub: LZone:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LZone:type
--   local world = lurek.physics.newWorld(0, 9.81)
--     local zone = world:addZone(0, 0, 100, 100)
--   local t = world:type()
--   lurek.log.info("LZone:type = " .. t, "physics")
-- end
--@api-stub: LZone:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LZone:typeOf
--   local world = lurek.physics.newWorld(0, 9.81)
--     local zone = world:addZone(0, 0, 100, 100)
--   lurek.log.info("is LZone: " .. tostring(world:typeOf("LZone")), "physics")
--   lurek.log.info("is wrong: " .. tostring(world:typeOf("Unknown")), "physics")
-- end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


