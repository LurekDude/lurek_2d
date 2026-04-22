-- content/examples/physics.lua
-- Practical usage examples for the lurek.physics API (147 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.physics.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/physics.lua

print("[example] lurek.physics — 147 API entries")

-- ── lurek.physics.* free functions ──

--@api-stub: lurek.physics.newWorld
-- Creates a new physics world with the given gravity vector.
-- Call when you need to create a new world.
local ok, obj = pcall(function() return lurek.physics.newWorld(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.physics.newWorld ok=", ok)

--@api-stub: lurek.physics.step
-- Advances the physics world by dt seconds.
-- Call when you need to invoke step.
local ok, result = pcall(function() return lurek.physics.step(nil, 1.0) end)
if not ok then print("action skipped:", result) end
print("lurek.physics.step fired=", ok)

--@api-stub: lurek.physics.destroyWorld
-- Marks a physics world for destruction.
-- Subsequent operations on the world.
local ok, err = pcall(function() lurek.physics.destroyWorld(nil) end)
if not ok then print("skipped:", err) end
print("lurek.physics.destroyWorld cleared=", ok)

--@api-stub: lurek.physics.newBody
-- Creates a new rectangular body in the given world.
-- Call when you need to create a new body.
local ok, obj = pcall(function() return lurek.physics.newBody(nil, 0, 0, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.physics.newBody ok=", ok)

--@api-stub: lurek.physics.getBody
-- Returns the position and velocity of a body (x, y, vx, vy).
-- Call when you need to read body.
local ok, value = pcall(function() return lurek.physics.getBody(nil, nil) end)
local v = ok and value or "(unavailable)"
print("lurek.physics.getBody ->", v)

--@api-stub: lurek.physics.setBodyVelocity
-- Sets the velocity of a body.
-- Call when you need to assign body velocity.
local ok, err = pcall(function() lurek.physics.setBodyVelocity(nil, nil, 0, 0) end)
if not ok then print("set skipped:", err) end
print("lurek.physics.setBodyVelocity applied=", ok)

--@api-stub: lurek.physics.isSleepingAllowed
-- Returns whether the body is allowed to sleep.
-- Call when you need to check is sleeping allowed.
local ok, result = pcall(function() return lurek.physics.isSleepingAllowed(nil, nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.physics.isSleepingAllowed ok=", ok)

--@api-stub: lurek.physics.setSleepingAllowed
-- Sets whether the body is allowed to sleep.
-- Call when you need to assign sleeping allowed.
local ok, err = pcall(function() lurek.physics.setSleepingAllowed(nil, nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.physics.setSleepingAllowed applied=", ok)

--@api-stub: lurek.physics.newRectangleShape
-- Creates a rectangle shape userdata.
-- Call when you need to create a new rectangle shape.
local ok, obj = pcall(function() return lurek.physics.newRectangleShape(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.physics.newRectangleShape ok=", ok)

--@api-stub: lurek.physics.newCircleShape
-- Creates a circle shape userdata.
-- Call when you need to create a new circle shape.
local ok, obj = pcall(function() return lurek.physics.newCircleShape(1) end)
if ok and obj then print("created:", obj) end
print("lurek.physics.newCircleShape ok=", ok)

--@api-stub: lurek.physics.newEdgeShape
-- Creates an edge (line segment) shape userdata.
-- Call when you need to create a new edge shape.
local ok, obj = pcall(function() return lurek.physics.newEdgeShape(nil, nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.physics.newEdgeShape ok=", ok)

--@api-stub: lurek.physics.newPolygonShape
-- Creates a convex polygon shape userdata from flat variadic vertex pairs.
-- Call when you need to create a new polygon shape.
local ok, obj = pcall(function() return lurek.physics.newPolygonShape() end)
if ok and obj then print("created:", obj) end
print("lurek.physics.newPolygonShape ok=", ok)

--@api-stub: lurek.physics.newChainShape
-- Creates a chain shape userdata from flat variadic vertex pairs.
-- Call when you need to create a new chain shape.
local ok, obj = pcall(function() return lurek.physics.newChainShape(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.physics.newChainShape ok=", ok)

--@api-stub: lurek.physics.attachShape
-- Attaches a standalone shape to a body as an additional fixture.
-- Call when you need to invoke attach shape.
local ok, err = pcall(function() lurek.physics.attachShape(nil, nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.physics.attachShape done=", ok)

--@api-stub: lurek.physics.getCollisions
-- Returns all collision events from the last simulation step.
-- Call when you need to read collisions.
local ok, value = pcall(function() return lurek.physics.getCollisions(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.physics.getCollisions ->", v)

--@api-stub: lurek.physics.debugDraw
-- Enables or disables the physics debug overlay (AABB boxes and velocity vectors).
-- Call when you need to invoke debug draw.
local ok, result = pcall(function() return lurek.physics.debugDraw(nil) end)
if ok then print("lurek.physics.debugDraw ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.physics.drawDebugGpu
-- Extracts collider geometry from a World and queues a GPU physics debug.
-- Call when you need to render debug gpu.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.physics.drawDebugGpu(nil, {}) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.physics.drawDebugGpu drawn=", ok)

--@api-stub: lurek.physics.newTerrain
-- Creates a destructible terrain grid.
-- Call when you need to create a new terrain.
local ok, obj = pcall(function() return lurek.physics.newTerrain(100, 100, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.physics.newTerrain ok=", ok)

--@api-stub: lurek.physics.newCellular
-- Creates a falling-sand cellular automaton grid.
-- Call when you need to create a new cellular.
local ok, obj = pcall(function() return lurek.physics.newCellular(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.physics.newCellular ok=", ok)

-- ── World methods ──

--@api-stub: World:step
-- Advances the physics simulation by dt seconds, firing onBeginContact /.
-- Call when you need to invoke step.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:step(1.0) end)
  print("World:step ->", ok, result)
end

--@api-stub: World:clear
-- Resets the world, removing all bodies and joints.
-- Call when you need to invoke clear.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("World:clear ->", ok, result)
end

--@api-stub: World:getGravity
-- Returns the gravity vector (gx, gy).
-- Call when you need to read gravity.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getGravity() end)
  print("World:getGravity ->", ok, result)
end

--@api-stub: World:setGravity
-- Sets the world gravity vector; default is `(0, 9.81)` (downward).
-- Call when you need to assign gravity.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:setGravity(nil, nil) end)
  print("World:setGravity ->", ok, result)
end

--@api-stub: World:setMeter
-- Sets the pixels-per-meter scaling factor.
-- Call when you need to assign meter.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:setMeter(nil) end)
  print("World:setMeter ->", ok, result)
end

--@api-stub: World:getMeter
-- Returns the pixels-per-meter scaling factor.
-- Call when you need to read meter.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getMeter() end)
  print("World:getMeter ->", ok, result)
end

--@api-stub: World:toPhysics
-- Converts a pixel value to physics units.
-- Call when you need to invoke to physics.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:toPhysics(nil) end)
  print("World:toPhysics ->", ok, result)
end

--@api-stub: World:toPixels
-- Converts a physics-unit value to pixels.
-- Call when you need to invoke to pixels.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:toPixels(nil) end)
  print("World:toPixels ->", ok, result)
end

--@api-stub: World:getBodyCount
-- Returns the total number of bodies in the world.
-- Call when you need to read body count.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getBodyCount() end)
  print("World:getBodyCount ->", ok, result)
end

--@api-stub: World:getBodyIds
-- Returns all body IDs in the world.
-- Call when you need to read body ids.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getBodyIds() end)
  print("World:getBodyIds ->", ok, result)
end

--@api-stub: World:destroyBody
-- Removes a body from the world.
-- Call when you need to invoke destroy body.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:destroyBody(1) end)
  print("World:destroyBody ->", ok, result)
end

--@api-stub: World:newBody
-- Creates a new rectangular body and adds it to the world.
-- Call when you need to create a new body.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:newBody(0, 0, nil) end)
  print("World:newBody ->", ok, result)
end

--@api-stub: World:fixtureCount
-- Returns the number of fixtures on a body.
-- Call when you need to invoke fixture count.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:fixtureCount(1) end)
  print("World:fixtureCount ->", ok, result)
end

--@api-stub: World:jointCount
-- Returns the total number of joints.
-- Call when you need to invoke joint count.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:jointCount() end)
  print("World:jointCount ->", ok, result)
end

--@api-stub: World:getJointIds
-- Returns a table of integer IDs for every joint attached to this world.
-- Call when you need to read joint ids.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getJointIds() end)
  print("World:getJointIds ->", ok, result)
end

--@api-stub: World:getJointBodies
-- Returns the two body IDs connected by a joint.
-- Call when you need to read joint bodies.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getJointBodies(1) end)
  print("World:getJointBodies ->", ok, result)
end

--@api-stub: World:destroyJoint
-- Removes a joint from the world.
-- Call when you need to invoke destroy joint.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:destroyJoint(1) end)
  print("World:destroyJoint ->", ok, result)
end

--@api-stub: World:getJointType
-- Returns the type name of a joint.
-- Call when you need to read joint type.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getJointType(1) end)
  print("World:getJointType ->", ok, result)
end

--@api-stub: World:getJointMotorSpeed
-- Returns the motor speed on a joint's angular axis.
-- Call when you need to read joint motor speed.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getJointMotorSpeed(1) end)
  print("World:getJointMotorSpeed ->", ok, result)
end

--@api-stub: World:getJointLimits
-- Returns the angular limits on a joint.
-- Call when you need to read joint limits.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getJointLimits(1) end)
  print("World:getJointLimits ->", ok, result)
end

--@api-stub: World:getBodyAtPoint
-- Returns the body ID at a world-space point, or nil.
-- Call when you need to read body at point.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getBodyAtPoint(0, 0) end)
  print("World:getBodyAtPoint ->", ok, result)
end

--@api-stub: World:getCollisionEvents
-- Returns collision events from the last step.
-- Call when you need to read collision events.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getCollisionEvents() end)
  print("World:getCollisionEvents ->", ok, result)
end

--@api-stub: World:getBeginContactEvents
-- Returns begin-contact events from the last step.
-- Call when you need to read begin contact events.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getBeginContactEvents() end)
  print("World:getBeginContactEvents ->", ok, result)
end

--@api-stub: World:getEndContactEvents
-- Returns end-contact events from the last step.
-- Call when you need to read end contact events.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getEndContactEvents() end)
  print("World:getEndContactEvents ->", ok, result)
end

--@api-stub: World:getContacts
-- Returns all contact pairs from the narrow phase.
-- Call when you need to read contacts.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getContacts() end)
  print("World:getContacts ->", ok, result)
end

--@api-stub: World:getBodyContacts
-- Returns contacts involving a specific body.
-- Call when you need to read body contacts.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getBodyContacts(1) end)
  print("World:getBodyContacts ->", ok, result)
end

--@api-stub: World:setBodyType
-- Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
-- Call when you need to assign body type.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:setBodyType(1, nil) end)
  print("World:setBodyType ->", ok, result)
end

--@api-stub: World:getBodyType
-- Returns the body type as a string.
-- Call when you need to read body type.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getBodyType(1) end)
  print("World:getBodyType ->", ok, result)
end

--@api-stub: World:setBeginContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- Call when you need to assign begin contact.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:setBeginContact(nil) end)
  print("World:setBeginContact ->", ok, result)
end

--@api-stub: World:clearBeginContact
-- Removes the begin-contact callback.
-- Call when you need to invoke clear begin contact.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:clearBeginContact() end)
  print("World:clearBeginContact ->", ok, result)
end

--@api-stub: World:setEndContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- Call when you need to assign end contact.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:setEndContact(nil) end)
  print("World:setEndContact ->", ok, result)
end

--@api-stub: World:clearEndContact
-- Removes the end-contact callback.
-- Call when you need to invoke clear end contact.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:clearEndContact() end)
  print("World:clearEndContact ->", ok, result)
end

--@api-stub: World:getBodyData
-- Returns the Lua data previously attached to a body, or nil if none is set.
-- Call when you need to read body data.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getBodyData(1) end)
  print("World:getBodyData ->", ok, result)
end

--@api-stub: World:clearBodyData
-- Removes the Lua data attached to a body.
-- Call when you need to invoke clear body data.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:clearBodyData(1) end)
  print("World:clearBodyData ->", ok, result)
end

--@api-stub: World:setBodyCCD
-- Enables or disables Continuous Collision Detection for a body.
-- Call when you need to assign body c c d.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:setBodyCCD(1, nil) end)
  print("World:setBodyCCD ->", ok, result)
end

--@api-stub: World:getBodyCCD
-- Returns whether CCD is enabled for a body.
-- Call when you need to read body c c d.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getBodyCCD(1) end)
  print("World:getBodyCCD ->", ok, result)
end

--@api-stub: World:clearBodyOneWay
-- Removes the one-way platform flag from a body.
-- Call when you need to invoke clear body one way.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:clearBodyOneWay(1) end)
  print("World:clearBodyOneWay ->", ok, result)
end

--@api-stub: World:getBodyOneWay
-- Returns the one-way normal for a body, or nil if not configured.
-- Call when you need to read body one way.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getBodyOneWay(1) end)
  print("World:getBodyOneWay ->", ok, result)
end

--@api-stub: World:setJointBreakForce
-- Sets the relative-velocity threshold above which a joint breaks.
-- Call when you need to assign joint break force.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:setJointBreakForce(1, nil) end)
  print("World:setJointBreakForce ->", ok, result)
end

--@api-stub: World:getJointBreakForce
-- Returns the break threshold for a joint, or nil if not set.
-- Call when you need to read joint break force.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getJointBreakForce(1) end)
  print("World:getJointBreakForce ->", ok, result)
end

--@api-stub: World:isBodySleeping
-- Returns true if a body is currently sleeping (inactive).
-- Call when you need to check is body sleeping.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:isBodySleeping(1) end)
  print("World:isBodySleeping ->", ok, result)
end

--@api-stub: World:wakeUpBody
-- Forcibly wakes up a sleeping body.
-- Call when you need to invoke wake up body.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:wakeUpBody(1) end)
  print("World:wakeUpBody ->", ok, result)
end

--@api-stub: World:sleepBody
-- Puts a body to sleep immediately.
-- Call when you need to invoke sleep body.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:sleepBody(1) end)
  print("World:sleepBody ->", ok, result)
end

--@api-stub: World:setSolverIterations
-- Sets the number of constraint solver iterations per step.
-- Call when you need to assign solver iterations.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:setSolverIterations(10) end)
  print("World:setSolverIterations ->", ok, result)
end

--@api-stub: World:getSolverIterations
-- Returns the current number of solver iterations per step.
-- Call when you need to read solver iterations.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getSolverIterations() end)
  print("World:getSolverIterations ->", ok, result)
end

--@api-stub: World:newBodies
-- Creates multiple bodies in one call.
-- Call when you need to create a new bodies.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:newBodies(nil) end)
  print("World:newBodies ->", ok, result)
end

--@api-stub: World:addZone
-- Creates a rectangular gravity/damping zone and returns a LuaZone handle.
-- Call when you need to add zone.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:addZone(0, 0, 100, 100) end)
  print("World:addZone ->", ok, result)
end

--@api-stub: World:getZoneEvents
-- Returns zone enter/leave events produced by the most recent step.
-- Call when you need to read zone events.
-- Build a World via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newWorld(...)
if instance then
  local ok, result = pcall(function() return instance:getZoneEvents() end)
  print("World:getZoneEvents ->", ok, result)
end

-- ── Zone methods ──

--@api-stub: Zone:getId
-- Returns the zone's integer ID.
-- Call when you need to read id.
-- Build a Zone via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newZone(...)
if instance then
  local ok, result = pcall(function() return instance:getId() end)
  print("Zone:getId ->", ok, result)
end

--@api-stub: Zone:setEnabled
-- Enables or disables the zone.
-- Call when you need to assign enabled.
-- Build a Zone via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newZone(...)
if instance then
  local ok, result = pcall(function() return instance:setEnabled(nil) end)
  print("Zone:setEnabled ->", ok, result)
end

--@api-stub: Zone:setPriority
-- Sets the zone priority; higher values win over lower when zones overlap.
-- Call when you need to assign priority.
-- Build a Zone via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newZone(...)
if instance then
  local ok, result = pcall(function() return instance:setPriority(nil) end)
  print("Zone:setPriority ->", ok, result)
end

--@api-stub: Zone:setLayerMask
-- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
-- Call when you need to assign layer mask.
-- Build a Zone via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newZone(...)
if instance then
  local ok, result = pcall(function() return instance:setLayerMask(nil) end)
  print("Zone:setLayerMask ->", ok, result)
end

--@api-stub: Zone:setCircle
-- Replaces the zone boundary with a circle.
-- Call when you need to assign circle.
-- Build a Zone via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newZone(...)
if instance then
  local ok, result = pcall(function() return instance:setCircle(nil, nil, nil) end)
  print("Zone:setCircle ->", ok, result)
end

--@api-stub: Zone:setGravityDirectional
-- Sets directional gravity inside the zone.
-- Call when you need to assign gravity directional.
-- Build a Zone via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newZone(...)
if instance then
  local ok, result = pcall(function() return instance:setGravityDirectional(nil, nil) end)
  print("Zone:setGravityDirectional ->", ok, result)
end

--@api-stub: Zone:setGravityZero
-- Suppresses gravity inside the zone (zero-g pocket).
-- Call when you need to assign gravity zero.
-- Build a Zone via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newZone(...)
if instance then
  local ok, result = pcall(function() return instance:setGravityZero() end)
  print("Zone:setGravityZero ->", ok, result)
end

--@api-stub: Zone:setLinearDampingOverride
-- Sets an optional linear damping override for bodies inside the zone.
-- Call when you need to assign linear damping override.
-- Build a Zone via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newZone(...)
if instance then
  local ok, result = pcall(function() return instance:setLinearDampingOverride(nil) end)
  print("Zone:setLinearDampingOverride ->", ok, result)
end

--@api-stub: Zone:destroy
-- Removes the zone from the world.
-- Call when you need to invoke destroy.
-- Build a Zone via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newZone(...)
if instance then
  local ok, result = pcall(function() return instance:destroy() end)
  print("Zone:destroy ->", ok, result)
end

-- ── Terrain methods ──

--@api-stub: Terrain:setCell
-- Sets a single terrain cell to solid or empty.
-- Call when you need to assign cell.
-- Build a Terrain via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newTerrain(...)
if instance then
  local ok, result = pcall(function() return instance:setCell(nil, nil, 1) end)
  print("Terrain:setCell ->", ok, result)
end

--@api-stub: Terrain:getCell
-- Returns whether a cell is solid.
-- Call when you need to read cell.
-- Build a Terrain via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newTerrain(...)
if instance then
  local ok, result = pcall(function() return instance:getCell(nil, nil) end)
  print("Terrain:getCell ->", ok, result)
end

--@api-stub: Terrain:fillAll
-- Sets every cell in the grid to `solid`.
-- Call when you need to invoke fill all.
-- Build a Terrain via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newTerrain(...)
if instance then
  local ok, result = pcall(function() return instance:fillAll(1) end)
  print("Terrain:fillAll ->", ok, result)
end

--@api-stub: Terrain:flush
-- Rebuilds physics bodies for all dirty chunks.
-- Call when you need to invoke flush.
-- Build a Terrain via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newTerrain(...)
if instance then
  local ok, result = pcall(function() return instance:flush() end)
  print("Terrain:flush ->", ok, result)
end

--@api-stub: Terrain:isDirty
-- Returns `true` when at least one chunk needs flushing.
-- Call when you need to check is dirty.
-- Build a Terrain via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newTerrain(...)
if instance then
  local ok, result = pcall(function() return instance:isDirty() end)
  print("Terrain:isDirty ->", ok, result)
end

--@api-stub: Terrain:collapseColumns
-- Removes unsupported cells, returning the number of cells that fell.
-- Call when you need to invoke collapse columns.
-- Build a Terrain via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newTerrain(...)
if instance then
  local ok, result = pcall(function() return instance:collapseColumns() end)
  print("Terrain:collapseColumns ->", ok, result)
end

--@api-stub: Terrain:solidPositions
-- Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
-- Call when you need to invoke solid positions.
-- Build a Terrain via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newTerrain(...)
if instance then
  local ok, result = pcall(function() return instance:solidPositions() end)
  print("Terrain:solidPositions ->", ok, result)
end

--@api-stub: Terrain:toBytes
-- Serialises the terrain grid to a byte string for save/load.
-- Call when you need to invoke to bytes.
-- Build a Terrain via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newTerrain(...)
if instance then
  local ok, result = pcall(function() return instance:toBytes() end)
  print("Terrain:toBytes ->", ok, result)
end

--@api-stub: Terrain:loadFromBytes
-- Loads terrain cell data from bytes produced by `toBytes`.
-- Call when you need to load from bytes.
-- Build a Terrain via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newTerrain(...)
if instance then
  local ok, result = pcall(function() return instance:loadFromBytes({}) end)
  print("Terrain:loadFromBytes ->", ok, result)
end

-- ── Cellular methods ──

--@api-stub: Cellular:setCell
-- Sets the material of a cell.
-- Call when you need to assign cell.
-- Build a Cellular via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newCellular(...)
if instance then
  local ok, result = pcall(function() return instance:setCell(nil, nil, nil) end)
  print("Cellular:setCell ->", ok, result)
end

--@api-stub: Cellular:getCell
-- Returns the material at `(cx, cy)` as an integer constant.
-- Call when you need to read cell.
-- Build a Cellular via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newCellular(...)
if instance then
  local ok, result = pcall(function() return instance:getCell(nil, nil) end)
  print("Cellular:getCell ->", ok, result)
end

--@api-stub: Cellular:step
-- Advances the simulation by one tick.
-- Call when you need to invoke step.
-- Build a Cellular via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newCellular(...)
if instance then
  local ok, result = pcall(function() return instance:step() end)
  print("Cellular:step ->", ok, result)
end

--@api-stub: Cellular:stepN
-- Advances the simulation by `n` ticks.
-- Call when you need to invoke step n.
-- Build a Cellular via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newCellular(...)
if instance then
  local ok, result = pcall(function() return instance:stepN(10) end)
  print("Cellular:stepN ->", ok, result)
end

--@api-stub: Cellular:toImageData
-- Returns the full grid as an RGBA byte string using the default colour palette.
-- Call when you need to invoke to image data.
-- Build a Cellular via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newCellular(...)
if instance then
  local ok, result = pcall(function() return instance:toImageData() end)
  print("Cellular:toImageData ->", ok, result)
end

--@api-stub: Cellular:countCells
-- Counts cells of the given material type.
-- Call when you need to invoke count cells.
-- Build a Cellular via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newCellular(...)
if instance then
  local ok, result = pcall(function() return instance:countCells(nil) end)
  print("Cellular:countCells ->", ok, result)
end

--@api-stub: Cellular:findCells
-- Returns positions of all cells of the given material as an array of `{x, y}` tables.
-- Call when you need to invoke find cells.
-- Build a Cellular via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newCellular(...)
if instance then
  local ok, result = pcall(function() return instance:findCells(nil) end)
  print("Cellular:findCells ->", ok, result)
end

--@api-stub: Cellular:toBytes
-- Serialises the grid to a byte string.
-- Call when you need to invoke to bytes.
-- Build a Cellular via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newCellular(...)
if instance then
  local ok, result = pcall(function() return instance:toBytes() end)
  print("Cellular:toBytes ->", ok, result)
end

--@api-stub: Cellular:loadFromBytes
-- Loads grid data from bytes produced by `toBytes`.
-- Call when you need to load from bytes.
-- Build a Cellular via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newCellular(...)
if instance then
  local ok, result = pcall(function() return instance:loadFromBytes({}) end)
  print("Cellular:loadFromBytes ->", ok, result)
end

-- ── Body methods ──

--@api-stub: Body:getId
-- Returns the body's integer ID.
-- Call when you need to read id.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getId() end)
  print("Body:getId ->", ok, result)
end

--@api-stub: Body:getPosition
-- Returns the body position (x, y).
-- Call when you need to read position.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getPosition() end)
  print("Body:getPosition ->", ok, result)
end

--@api-stub: Body:setPosition
-- Teleports the body to the given world-space position, bypassing collision.
-- Call when you need to assign position.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(0, 0) end)
  print("Body:setPosition ->", ok, result)
end

--@api-stub: Body:getX
-- Returns the body X position.
-- Call when you need to read x.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getX() end)
  print("Body:getX ->", ok, result)
end

--@api-stub: Body:getY
-- Returns the body Y position.
-- Call when you need to read y.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getY() end)
  print("Body:getY ->", ok, result)
end

--@api-stub: Body:getVelocity
-- Returns the body velocity (vx, vy).
-- Call when you need to read velocity.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getVelocity() end)
  print("Body:getVelocity ->", ok, result)
end

--@api-stub: Body:setVelocity
-- Sets the body's linear velocity in world units per second.
-- Call when you need to assign velocity.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setVelocity(0, 0) end)
  print("Body:setVelocity ->", ok, result)
end

--@api-stub: Body:getAngle
-- Returns the body angle in radians.
-- Call when you need to read angle.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getAngle() end)
  print("Body:getAngle ->", ok, result)
end

--@api-stub: Body:setAngle
-- Sets the body angle in radians.
-- Call when you need to assign angle.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setAngle(0) end)
  print("Body:setAngle ->", ok, result)
end

--@api-stub: Body:getAngularVelocity
-- Returns the angular velocity in radians/s.
-- Call when you need to read angular velocity.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getAngularVelocity() end)
  print("Body:getAngularVelocity ->", ok, result)
end

--@api-stub: Body:setAngularVelocity
-- Sets the angular velocity.
-- Call when you need to assign angular velocity.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setAngularVelocity(nil) end)
  print("Body:setAngularVelocity ->", ok, result)
end

--@api-stub: Body:getMass
-- Returns the body mass in kilograms used for force and impulse calculations.
-- Call when you need to read mass.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getMass() end)
  print("Body:getMass ->", ok, result)
end

--@api-stub: Body:setMass
-- Sets the body mass; affects how forces and impulses change velocity.
-- Call when you need to assign mass.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setMass(nil) end)
  print("Body:setMass ->", ok, result)
end

--@api-stub: Body:getType
-- Returns the body type as a string.
-- Call when you need to read type.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getType() end)
  print("Body:getType ->", ok, result)
end

--@api-stub: Body:setType
-- Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
-- Call when you need to assign type.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setType(nil) end)
  print("Body:setType ->", ok, result)
end

--@api-stub: Body:getWidth
-- Returns the width of this body's primary collider shape in world units.
-- Call when you need to read width.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("Body:getWidth ->", ok, result)
end

--@api-stub: Body:getHeight
-- Returns the height of this body's primary collider shape in world units.
-- Call when you need to read height.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("Body:getHeight ->", ok, result)
end

--@api-stub: Body:getFriction
-- Returns the body friction coefficient.
-- Call when you need to read friction.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getFriction() end)
  print("Body:getFriction ->", ok, result)
end

--@api-stub: Body:setFriction
-- Sets the body friction coefficient.
-- Call when you need to assign friction.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setFriction(nil) end)
  print("Body:setFriction ->", ok, result)
end

--@api-stub: Body:getRestitution
-- Returns the body restitution (bounciness).
-- Call when you need to read restitution.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getRestitution() end)
  print("Body:getRestitution ->", ok, result)
end

--@api-stub: Body:setRestitution
-- Sets the body restitution (bounciness).
-- Call when you need to assign restitution.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setRestitution(nil) end)
  print("Body:setRestitution ->", ok, result)
end

--@api-stub: Body:getLayer
-- Returns the collision layer bitmask.
-- Call when you need to read layer.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getLayer() end)
  print("Body:getLayer ->", ok, result)
end

--@api-stub: Body:setLayer
-- Sets the collision layer bitmask.
-- Call when you need to assign layer.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setLayer(nil) end)
  print("Body:setLayer ->", ok, result)
end

--@api-stub: Body:getMask
-- Returns the collision mask bitmask.
-- Call when you need to read mask.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getMask() end)
  print("Body:getMask ->", ok, result)
end

--@api-stub: Body:setMask
-- Sets the collision mask bitmask.
-- Call when you need to assign mask.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setMask(nil) end)
  print("Body:setMask ->", ok, result)
end

--@api-stub: Body:applyImpulse
-- Applies a linear impulse to the body.
-- Call when you need to invoke apply impulse.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:applyImpulse(nil, nil) end)
  print("Body:applyImpulse ->", ok, result)
end

--@api-stub: Body:applyForce
-- Applies a continuous force to the body.
-- Call when you need to invoke apply force.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:applyForce(nil, nil) end)
  print("Body:applyForce ->", ok, result)
end

--@api-stub: Body:applyTorque
-- Applies a torque (rotational force).
-- Call when you need to invoke apply torque.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:applyTorque(nil) end)
  print("Body:applyTorque ->", ok, result)
end

--@api-stub: Body:applyAngularImpulse
-- Applies an angular impulse.
-- Call when you need to invoke apply angular impulse.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:applyAngularImpulse(nil) end)
  print("Body:applyAngularImpulse ->", ok, result)
end

--@api-stub: Body:getGravityScale
-- Returns the per-body gravity multiplier.
-- Call when you need to read gravity scale.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getGravityScale() end)
  print("Body:getGravityScale ->", ok, result)
end

--@api-stub: Body:setGravityScale
-- Sets the per-body gravity multiplier.
-- Call when you need to assign gravity scale.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setGravityScale(1) end)
  print("Body:setGravityScale ->", ok, result)
end

--@api-stub: Body:isFixedRotation
-- Returns whether rotation is locked.
-- Call when you need to check is fixed rotation.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:isFixedRotation() end)
  print("Body:isFixedRotation ->", ok, result)
end

--@api-stub: Body:setFixedRotation
-- Locks or unlocks rotation.
-- Call when you need to assign fixed rotation.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setFixedRotation(nil) end)
  print("Body:setFixedRotation ->", ok, result)
end

--@api-stub: Body:getLinearDamping
-- Returns the linear damping coefficient.
-- Call when you need to read linear damping.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getLinearDamping() end)
  print("Body:getLinearDamping ->", ok, result)
end

--@api-stub: Body:setLinearDamping
-- Sets the linear damping coefficient.
-- Call when you need to assign linear damping.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setLinearDamping(nil) end)
  print("Body:setLinearDamping ->", ok, result)
end

--@api-stub: Body:getAngularDamping
-- Returns the angular damping coefficient.
-- Call when you need to read angular damping.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:getAngularDamping() end)
  print("Body:getAngularDamping ->", ok, result)
end

--@api-stub: Body:setAngularDamping
-- Sets the angular damping coefficient.
-- Call when you need to assign angular damping.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setAngularDamping(nil) end)
  print("Body:setAngularDamping ->", ok, result)
end

--@api-stub: Body:isBullet
-- Returns whether CCD is enabled.
-- Call when you need to check is bullet.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:isBullet() end)
  print("Body:isBullet ->", ok, result)
end

--@api-stub: Body:setBullet
-- Enables or disables continuous collision detection (CCD) for fast-moving bodies.
-- Call when you need to assign bullet.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setBullet(nil) end)
  print("Body:setBullet ->", ok, result)
end

--@api-stub: Body:isSleepingAllowed
-- Returns whether the body can sleep.
-- Call when you need to check is sleeping allowed.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:isSleepingAllowed() end)
  print("Body:isSleepingAllowed ->", ok, result)
end

--@api-stub: Body:setSleepingAllowed
-- Sets whether the body can sleep.
-- Call when you need to assign sleeping allowed.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:setSleepingAllowed(nil) end)
  print("Body:setSleepingAllowed ->", ok, result)
end

--@api-stub: Body:destroy
-- Removes this body from the world.
-- Call when you need to invoke destroy.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:destroy() end)
  print("Body:destroy ->", ok, result)
end

--@api-stub: Body:isSleeping
-- Returns true if this body is currently sleeping (inactive).
-- Call when you need to check is sleeping.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:isSleeping() end)
  print("Body:isSleeping ->", ok, result)
end

--@api-stub: Body:wakeUp
-- Forcibly wakes up this body.
-- Call when you need to invoke wake up.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:wakeUp() end)
  print("Body:wakeUp ->", ok, result)
end

--@api-stub: Body:sleep
-- Puts this body to sleep immediately.
-- Call when you need to invoke sleep.
-- Build a Body via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newBody(...)
if instance then
  local ok, result = pcall(function() return instance:sleep() end)
  print("Body:sleep ->", ok, result)
end

-- ── PhysicsShape methods ──

--@api-stub: PhysicsShape:getType
-- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
-- Call when you need to read type.
-- Build a PhysicsShape via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newPhysicsShape(...)
if instance then
  local ok, result = pcall(function() return instance:getType() end)
  print("PhysicsShape:getType ->", ok, result)
end

--@api-stub: PhysicsShape:getRadius
-- Returns the radius.
-- Only valid for circle shapes.
-- Build a PhysicsShape via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newPhysicsShape(...)
if instance then
  local ok, result = pcall(function() return instance:getRadius() end)
  print("PhysicsShape:getRadius ->", ok, result)
end

--@api-stub: PhysicsShape:getBoundingBox
-- Returns the axis-aligned bounding box (x1, y1, x2, y2).
-- Call when you need to read bounding box.
-- Build a PhysicsShape via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newPhysicsShape(...)
if instance then
  local ok, result = pcall(function() return instance:getBoundingBox() end)
  print("PhysicsShape:getBoundingBox ->", ok, result)
end

--@api-stub: PhysicsShape:setDensity
-- Sets the density for this shape (used when attaching to a body).
-- Call when you need to assign density.
-- Build a PhysicsShape via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newPhysicsShape(...)
if instance then
  local ok, result = pcall(function() return instance:setDensity(nil) end)
  print("PhysicsShape:setDensity ->", ok, result)
end

--@api-stub: PhysicsShape:setFriction
-- Sets the friction coefficient.
-- Call when you need to assign friction.
-- Build a PhysicsShape via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newPhysicsShape(...)
if instance then
  local ok, result = pcall(function() return instance:setFriction(nil) end)
  print("PhysicsShape:setFriction ->", ok, result)
end

--@api-stub: PhysicsShape:setRestitution
-- Sets the restitution (bounciness) coefficient.
-- Call when you need to assign restitution.
-- Build a PhysicsShape via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newPhysicsShape(...)
if instance then
  local ok, result = pcall(function() return instance:setRestitution(nil) end)
  print("PhysicsShape:setRestitution ->", ok, result)
end

--@api-stub: PhysicsShape:setSensor
-- Sets whether this shape is a sensor (non-colliding trigger).
-- Call when you need to assign sensor.
-- Build a PhysicsShape via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newPhysicsShape(...)
if instance then
  local ok, result = pcall(function() return instance:setSensor(nil) end)
  print("PhysicsShape:setSensor ->", ok, result)
end

--@api-stub: PhysicsShape:destroy
-- Releases this shape handle (GC handles cleanup).
-- Call when you need to invoke destroy.
-- Build a PhysicsShape via the appropriate lurek.physics.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.physics.newPhysicsShape(...)
if instance then
  local ok, result = pcall(function() return instance:destroy() end)
  print("PhysicsShape:destroy ->", ok, result)
end

