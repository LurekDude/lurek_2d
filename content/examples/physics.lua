-- content/examples/physics.lua
-- Scaffolded coverage of the lurek.physics API (147 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/physics_api.rs   (Lua binding, arg types, return shape)
--   * src/physics/                 (semantics, side effects)
--   * docs/specs/physics.md        (canonical reference)
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
-- Run: cargo run -- content/examples/physics.lua

-- ── lurek.physics.* functions ──

--@api-stub: lurek.physics.newWorld
-- Creates a new physics world with the given gravity vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.newWorld
  local _todo = "TODO: write a real lurek.physics.newWorld usage example"
  print(_todo)
end

--@api-stub: lurek.physics.step
-- Advances the physics world by dt seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.step
  local _todo = "TODO: write a real lurek.physics.step usage example"
  print(_todo)
end

--@api-stub: lurek.physics.destroyWorld
-- Marks a physics world for destruction.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.destroyWorld
  local _todo = "TODO: write a real lurek.physics.destroyWorld usage example"
  print(_todo)
end

--@api-stub: lurek.physics.newBody
-- Creates a new rectangular body in the given world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.newBody
  local _todo = "TODO: write a real lurek.physics.newBody usage example"
  print(_todo)
end

--@api-stub: lurek.physics.getBody
-- Returns the position and velocity of a body (x, y, vx, vy).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.getBody
  local _todo = "TODO: write a real lurek.physics.getBody usage example"
  print(_todo)
end

--@api-stub: lurek.physics.setBodyVelocity
-- Sets the velocity of a body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.setBodyVelocity
  local _todo = "TODO: write a real lurek.physics.setBodyVelocity usage example"
  print(_todo)
end

--@api-stub: lurek.physics.isSleepingAllowed
-- Returns whether the body is allowed to sleep.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.isSleepingAllowed
  local _todo = "TODO: write a real lurek.physics.isSleepingAllowed usage example"
  print(_todo)
end

--@api-stub: lurek.physics.setSleepingAllowed
-- Sets whether the body is allowed to sleep.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.setSleepingAllowed
  local _todo = "TODO: write a real lurek.physics.setSleepingAllowed usage example"
  print(_todo)
end

--@api-stub: lurek.physics.newRectangleShape
-- Creates a rectangle shape userdata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.newRectangleShape
  local _todo = "TODO: write a real lurek.physics.newRectangleShape usage example"
  print(_todo)
end

--@api-stub: lurek.physics.newCircleShape
-- Creates a circle shape userdata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.newCircleShape
  local _todo = "TODO: write a real lurek.physics.newCircleShape usage example"
  print(_todo)
end

--@api-stub: lurek.physics.newEdgeShape
-- Creates an edge (line segment) shape userdata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.newEdgeShape
  local _todo = "TODO: write a real lurek.physics.newEdgeShape usage example"
  print(_todo)
end

--@api-stub: lurek.physics.newPolygonShape
-- Creates a convex polygon shape userdata from flat variadic vertex pairs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.newPolygonShape
  local _todo = "TODO: write a real lurek.physics.newPolygonShape usage example"
  print(_todo)
end

--@api-stub: lurek.physics.newChainShape
-- Creates a chain shape userdata from flat variadic vertex pairs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.newChainShape
  local _todo = "TODO: write a real lurek.physics.newChainShape usage example"
  print(_todo)
end

--@api-stub: lurek.physics.attachShape
-- Attaches a standalone shape to a body as an additional fixture.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.attachShape
  local _todo = "TODO: write a real lurek.physics.attachShape usage example"
  print(_todo)
end

--@api-stub: lurek.physics.getCollisions
-- Returns all collision events from the last simulation step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.getCollisions
  local _todo = "TODO: write a real lurek.physics.getCollisions usage example"
  print(_todo)
end

--@api-stub: lurek.physics.debugDraw
-- Enables or disables the physics debug overlay (AABB boxes and velocity vectors).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.debugDraw
  local _todo = "TODO: write a real lurek.physics.debugDraw usage example"
  print(_todo)
end

--@api-stub: lurek.physics.drawDebugGpu
-- Extracts collider geometry from a World and queues a GPU physics debug.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.drawDebugGpu
  local _todo = "TODO: write a real lurek.physics.drawDebugGpu usage example"
  print(_todo)
end

--@api-stub: lurek.physics.newTerrain
-- Creates a destructible terrain grid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.newTerrain
  local _todo = "TODO: write a real lurek.physics.newTerrain usage example"
  print(_todo)
end

--@api-stub: lurek.physics.newCellular
-- Creates a falling-sand cellular automaton grid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: lurek.physics.newCellular
  local _todo = "TODO: write a real lurek.physics.newCellular usage example"
  print(_todo)
end

-- ── World methods ──

--@api-stub: World:step
-- Advances the physics simulation by dt seconds, firing onBeginContact /.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:step
  local _todo = "TODO: write a real World:step usage example"
  print(_todo)
end

--@api-stub: World:clear
-- Resets the world, removing all bodies and joints.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:clear
  local _todo = "TODO: write a real World:clear usage example"
  print(_todo)
end

--@api-stub: World:getGravity
-- Returns the gravity vector (gx, gy).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getGravity
  local _todo = "TODO: write a real World:getGravity usage example"
  print(_todo)
end

--@api-stub: World:setGravity
-- Sets the world gravity vector; default is `(0, 9.81)` (downward).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:setGravity
  local _todo = "TODO: write a real World:setGravity usage example"
  print(_todo)
end

--@api-stub: World:setMeter
-- Sets the pixels-per-meter scaling factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:setMeter
  local _todo = "TODO: write a real World:setMeter usage example"
  print(_todo)
end

--@api-stub: World:getMeter
-- Returns the pixels-per-meter scaling factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getMeter
  local _todo = "TODO: write a real World:getMeter usage example"
  print(_todo)
end

--@api-stub: World:toPhysics
-- Converts a pixel value to physics units.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:toPhysics
  local _todo = "TODO: write a real World:toPhysics usage example"
  print(_todo)
end

--@api-stub: World:toPixels
-- Converts a physics-unit value to pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:toPixels
  local _todo = "TODO: write a real World:toPixels usage example"
  print(_todo)
end

--@api-stub: World:getBodyCount
-- Returns the total number of bodies in the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getBodyCount
  local _todo = "TODO: write a real World:getBodyCount usage example"
  print(_todo)
end

--@api-stub: World:getBodyIds
-- Returns all body IDs in the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getBodyIds
  local _todo = "TODO: write a real World:getBodyIds usage example"
  print(_todo)
end

--@api-stub: World:destroyBody
-- Removes a body from the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:destroyBody
  local _todo = "TODO: write a real World:destroyBody usage example"
  print(_todo)
end

--@api-stub: World:newBody
-- Creates a new rectangular body and adds it to the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:newBody
  local _todo = "TODO: write a real World:newBody usage example"
  print(_todo)
end

--@api-stub: World:fixtureCount
-- Returns the number of fixtures on a body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:fixtureCount
  local _todo = "TODO: write a real World:fixtureCount usage example"
  print(_todo)
end

--@api-stub: World:jointCount
-- Returns the total number of joints.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:jointCount
  local _todo = "TODO: write a real World:jointCount usage example"
  print(_todo)
end

--@api-stub: World:getJointIds
-- Returns a table of integer IDs for every joint attached to this world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getJointIds
  local _todo = "TODO: write a real World:getJointIds usage example"
  print(_todo)
end

--@api-stub: World:getJointBodies
-- Returns the two body IDs connected by a joint.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getJointBodies
  local _todo = "TODO: write a real World:getJointBodies usage example"
  print(_todo)
end

--@api-stub: World:destroyJoint
-- Removes a joint from the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:destroyJoint
  local _todo = "TODO: write a real World:destroyJoint usage example"
  print(_todo)
end

--@api-stub: World:getJointType
-- Returns the type name of a joint.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getJointType
  local _todo = "TODO: write a real World:getJointType usage example"
  print(_todo)
end

--@api-stub: World:getJointMotorSpeed
-- Returns the motor speed on a joint's angular axis.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getJointMotorSpeed
  local _todo = "TODO: write a real World:getJointMotorSpeed usage example"
  print(_todo)
end

--@api-stub: World:getJointLimits
-- Returns the angular limits on a joint.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getJointLimits
  local _todo = "TODO: write a real World:getJointLimits usage example"
  print(_todo)
end

--@api-stub: World:getBodyAtPoint
-- Returns the body ID at a world-space point, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getBodyAtPoint
  local _todo = "TODO: write a real World:getBodyAtPoint usage example"
  print(_todo)
end

--@api-stub: World:getCollisionEvents
-- Returns collision events from the last step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getCollisionEvents
  local _todo = "TODO: write a real World:getCollisionEvents usage example"
  print(_todo)
end

--@api-stub: World:getBeginContactEvents
-- Returns begin-contact events from the last step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getBeginContactEvents
  local _todo = "TODO: write a real World:getBeginContactEvents usage example"
  print(_todo)
end

--@api-stub: World:getEndContactEvents
-- Returns end-contact events from the last step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getEndContactEvents
  local _todo = "TODO: write a real World:getEndContactEvents usage example"
  print(_todo)
end

--@api-stub: World:getContacts
-- Returns all contact pairs from the narrow phase.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getContacts
  local _todo = "TODO: write a real World:getContacts usage example"
  print(_todo)
end

--@api-stub: World:getBodyContacts
-- Returns contacts involving a specific body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getBodyContacts
  local _todo = "TODO: write a real World:getBodyContacts usage example"
  print(_todo)
end

--@api-stub: World:setBodyType
-- Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:setBodyType
  local _todo = "TODO: write a real World:setBodyType usage example"
  print(_todo)
end

--@api-stub: World:getBodyType
-- Returns the body type as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getBodyType
  local _todo = "TODO: write a real World:getBodyType usage example"
  print(_todo)
end

--@api-stub: World:setBeginContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:setBeginContact
  local _todo = "TODO: write a real World:setBeginContact usage example"
  print(_todo)
end

--@api-stub: World:clearBeginContact
-- Removes the begin-contact callback.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:clearBeginContact
  local _todo = "TODO: write a real World:clearBeginContact usage example"
  print(_todo)
end

--@api-stub: World:setEndContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:setEndContact
  local _todo = "TODO: write a real World:setEndContact usage example"
  print(_todo)
end

--@api-stub: World:clearEndContact
-- Removes the end-contact callback.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:clearEndContact
  local _todo = "TODO: write a real World:clearEndContact usage example"
  print(_todo)
end

--@api-stub: World:getBodyData
-- Returns the Lua data previously attached to a body, or nil if none is set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getBodyData
  local _todo = "TODO: write a real World:getBodyData usage example"
  print(_todo)
end

--@api-stub: World:clearBodyData
-- Removes the Lua data attached to a body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:clearBodyData
  local _todo = "TODO: write a real World:clearBodyData usage example"
  print(_todo)
end

--@api-stub: World:setBodyCCD
-- Enables or disables Continuous Collision Detection for a body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:setBodyCCD
  local _todo = "TODO: write a real World:setBodyCCD usage example"
  print(_todo)
end

--@api-stub: World:getBodyCCD
-- Returns whether CCD is enabled for a body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getBodyCCD
  local _todo = "TODO: write a real World:getBodyCCD usage example"
  print(_todo)
end

--@api-stub: World:clearBodyOneWay
-- Removes the one-way platform flag from a body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:clearBodyOneWay
  local _todo = "TODO: write a real World:clearBodyOneWay usage example"
  print(_todo)
end

--@api-stub: World:getBodyOneWay
-- Returns the one-way normal for a body, or nil if not configured.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getBodyOneWay
  local _todo = "TODO: write a real World:getBodyOneWay usage example"
  print(_todo)
end

--@api-stub: World:setJointBreakForce
-- Sets the relative-velocity threshold above which a joint breaks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:setJointBreakForce
  local _todo = "TODO: write a real World:setJointBreakForce usage example"
  print(_todo)
end

--@api-stub: World:getJointBreakForce
-- Returns the break threshold for a joint, or nil if not set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getJointBreakForce
  local _todo = "TODO: write a real World:getJointBreakForce usage example"
  print(_todo)
end

--@api-stub: World:isBodySleeping
-- Returns true if a body is currently sleeping (inactive).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:isBodySleeping
  local _todo = "TODO: write a real World:isBodySleeping usage example"
  print(_todo)
end

--@api-stub: World:wakeUpBody
-- Forcibly wakes up a sleeping body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:wakeUpBody
  local _todo = "TODO: write a real World:wakeUpBody usage example"
  print(_todo)
end

--@api-stub: World:sleepBody
-- Puts a body to sleep immediately.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:sleepBody
  local _todo = "TODO: write a real World:sleepBody usage example"
  print(_todo)
end

--@api-stub: World:setSolverIterations
-- Sets the number of constraint solver iterations per step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:setSolverIterations
  local _todo = "TODO: write a real World:setSolverIterations usage example"
  print(_todo)
end

--@api-stub: World:getSolverIterations
-- Returns the current number of solver iterations per step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getSolverIterations
  local _todo = "TODO: write a real World:getSolverIterations usage example"
  print(_todo)
end

--@api-stub: World:newBodies
-- Creates multiple bodies in one call.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:newBodies
  local _todo = "TODO: write a real World:newBodies usage example"
  print(_todo)
end

--@api-stub: World:addZone
-- Creates a rectangular gravity/damping zone and returns a LuaZone handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:addZone
  local _todo = "TODO: write a real World:addZone usage example"
  print(_todo)
end

--@api-stub: World:getZoneEvents
-- Returns zone enter/leave events produced by the most recent step.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: World:getZoneEvents
  local _todo = "TODO: write a real World:getZoneEvents usage example"
  print(_todo)
end

-- ── Zone methods ──

--@api-stub: Zone:getId
-- Returns the zone's integer ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Zone:getId
  local _todo = "TODO: write a real Zone:getId usage example"
  print(_todo)
end

--@api-stub: Zone:setEnabled
-- Enables or disables the zone.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Zone:setEnabled
  local _todo = "TODO: write a real Zone:setEnabled usage example"
  print(_todo)
end

--@api-stub: Zone:setPriority
-- Sets the zone priority; higher values win over lower when zones overlap.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Zone:setPriority
  local _todo = "TODO: write a real Zone:setPriority usage example"
  print(_todo)
end

--@api-stub: Zone:setLayerMask
-- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Zone:setLayerMask
  local _todo = "TODO: write a real Zone:setLayerMask usage example"
  print(_todo)
end

--@api-stub: Zone:setCircle
-- Replaces the zone boundary with a circle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Zone:setCircle
  local _todo = "TODO: write a real Zone:setCircle usage example"
  print(_todo)
end

--@api-stub: Zone:setGravityDirectional
-- Sets directional gravity inside the zone.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Zone:setGravityDirectional
  local _todo = "TODO: write a real Zone:setGravityDirectional usage example"
  print(_todo)
end

--@api-stub: Zone:setGravityZero
-- Suppresses gravity inside the zone (zero-g pocket).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Zone:setGravityZero
  local _todo = "TODO: write a real Zone:setGravityZero usage example"
  print(_todo)
end

--@api-stub: Zone:setLinearDampingOverride
-- Sets an optional linear damping override for bodies inside the zone.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Zone:setLinearDampingOverride
  local _todo = "TODO: write a real Zone:setLinearDampingOverride usage example"
  print(_todo)
end

--@api-stub: Zone:destroy
-- Removes the zone from the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Zone:destroy
  local _todo = "TODO: write a real Zone:destroy usage example"
  print(_todo)
end

-- ── Terrain methods ──

--@api-stub: Terrain:setCell
-- Sets a single terrain cell to solid or empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Terrain:setCell
  local _todo = "TODO: write a real Terrain:setCell usage example"
  print(_todo)
end

--@api-stub: Terrain:getCell
-- Returns whether a cell is solid.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Terrain:getCell
  local _todo = "TODO: write a real Terrain:getCell usage example"
  print(_todo)
end

--@api-stub: Terrain:fillAll
-- Sets every cell in the grid to `solid`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Terrain:fillAll
  local _todo = "TODO: write a real Terrain:fillAll usage example"
  print(_todo)
end

--@api-stub: Terrain:flush
-- Rebuilds physics bodies for all dirty chunks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Terrain:flush
  local _todo = "TODO: write a real Terrain:flush usage example"
  print(_todo)
end

--@api-stub: Terrain:isDirty
-- Returns `true` when at least one chunk needs flushing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Terrain:isDirty
  local _todo = "TODO: write a real Terrain:isDirty usage example"
  print(_todo)
end

--@api-stub: Terrain:collapseColumns
-- Removes unsupported cells, returning the number of cells that fell.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Terrain:collapseColumns
  local _todo = "TODO: write a real Terrain:collapseColumns usage example"
  print(_todo)
end

--@api-stub: Terrain:solidPositions
-- Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Terrain:solidPositions
  local _todo = "TODO: write a real Terrain:solidPositions usage example"
  print(_todo)
end

--@api-stub: Terrain:toBytes
-- Serialises the terrain grid to a byte string for save/load.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Terrain:toBytes
  local _todo = "TODO: write a real Terrain:toBytes usage example"
  print(_todo)
end

--@api-stub: Terrain:loadFromBytes
-- Loads terrain cell data from bytes produced by `toBytes`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Terrain:loadFromBytes
  local _todo = "TODO: write a real Terrain:loadFromBytes usage example"
  print(_todo)
end

-- ── Cellular methods ──

--@api-stub: Cellular:setCell
-- Sets the material of a cell.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Cellular:setCell
  local _todo = "TODO: write a real Cellular:setCell usage example"
  print(_todo)
end

--@api-stub: Cellular:getCell
-- Returns the material at `(cx, cy)` as an integer constant.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Cellular:getCell
  local _todo = "TODO: write a real Cellular:getCell usage example"
  print(_todo)
end

--@api-stub: Cellular:step
-- Advances the simulation by one tick.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Cellular:step
  local _todo = "TODO: write a real Cellular:step usage example"
  print(_todo)
end

--@api-stub: Cellular:stepN
-- Advances the simulation by `n` ticks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Cellular:stepN
  local _todo = "TODO: write a real Cellular:stepN usage example"
  print(_todo)
end

--@api-stub: Cellular:toImageData
-- Returns the full grid as an RGBA byte string using the default colour palette.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Cellular:toImageData
  local _todo = "TODO: write a real Cellular:toImageData usage example"
  print(_todo)
end

--@api-stub: Cellular:countCells
-- Counts cells of the given material type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Cellular:countCells
  local _todo = "TODO: write a real Cellular:countCells usage example"
  print(_todo)
end

--@api-stub: Cellular:findCells
-- Returns positions of all cells of the given material as an array of `{x, y}` tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Cellular:findCells
  local _todo = "TODO: write a real Cellular:findCells usage example"
  print(_todo)
end

--@api-stub: Cellular:toBytes
-- Serialises the grid to a byte string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Cellular:toBytes
  local _todo = "TODO: write a real Cellular:toBytes usage example"
  print(_todo)
end

--@api-stub: Cellular:loadFromBytes
-- Loads grid data from bytes produced by `toBytes`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Cellular:loadFromBytes
  local _todo = "TODO: write a real Cellular:loadFromBytes usage example"
  print(_todo)
end

-- ── Body methods ──

--@api-stub: Body:getId
-- Returns the body's integer ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getId
  local _todo = "TODO: write a real Body:getId usage example"
  print(_todo)
end

--@api-stub: Body:getPosition
-- Returns the body position (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getPosition
  local _todo = "TODO: write a real Body:getPosition usage example"
  print(_todo)
end

--@api-stub: Body:setPosition
-- Teleports the body to the given world-space position, bypassing collision.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setPosition
  local _todo = "TODO: write a real Body:setPosition usage example"
  print(_todo)
end

--@api-stub: Body:getX
-- Returns the body X position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getX
  local _todo = "TODO: write a real Body:getX usage example"
  print(_todo)
end

--@api-stub: Body:getY
-- Returns the body Y position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getY
  local _todo = "TODO: write a real Body:getY usage example"
  print(_todo)
end

--@api-stub: Body:getVelocity
-- Returns the body velocity (vx, vy).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getVelocity
  local _todo = "TODO: write a real Body:getVelocity usage example"
  print(_todo)
end

--@api-stub: Body:setVelocity
-- Sets the body's linear velocity in world units per second.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setVelocity
  local _todo = "TODO: write a real Body:setVelocity usage example"
  print(_todo)
end

--@api-stub: Body:getAngle
-- Returns the body angle in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getAngle
  local _todo = "TODO: write a real Body:getAngle usage example"
  print(_todo)
end

--@api-stub: Body:setAngle
-- Sets the body angle in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setAngle
  local _todo = "TODO: write a real Body:setAngle usage example"
  print(_todo)
end

--@api-stub: Body:getAngularVelocity
-- Returns the angular velocity in radians/s.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getAngularVelocity
  local _todo = "TODO: write a real Body:getAngularVelocity usage example"
  print(_todo)
end

--@api-stub: Body:setAngularVelocity
-- Sets the angular velocity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setAngularVelocity
  local _todo = "TODO: write a real Body:setAngularVelocity usage example"
  print(_todo)
end

--@api-stub: Body:getMass
-- Returns the body mass in kilograms used for force and impulse calculations.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getMass
  local _todo = "TODO: write a real Body:getMass usage example"
  print(_todo)
end

--@api-stub: Body:setMass
-- Sets the body mass; affects how forces and impulses change velocity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setMass
  local _todo = "TODO: write a real Body:setMass usage example"
  print(_todo)
end

--@api-stub: Body:getType
-- Returns the body type as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getType
  local _todo = "TODO: write a real Body:getType usage example"
  print(_todo)
end

--@api-stub: Body:setType
-- Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setType
  local _todo = "TODO: write a real Body:setType usage example"
  print(_todo)
end

--@api-stub: Body:getWidth
-- Returns the width of this body's primary collider shape in world units.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getWidth
  local _todo = "TODO: write a real Body:getWidth usage example"
  print(_todo)
end

--@api-stub: Body:getHeight
-- Returns the height of this body's primary collider shape in world units.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getHeight
  local _todo = "TODO: write a real Body:getHeight usage example"
  print(_todo)
end

--@api-stub: Body:getFriction
-- Returns the body friction coefficient.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getFriction
  local _todo = "TODO: write a real Body:getFriction usage example"
  print(_todo)
end

--@api-stub: Body:setFriction
-- Sets the body friction coefficient.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setFriction
  local _todo = "TODO: write a real Body:setFriction usage example"
  print(_todo)
end

--@api-stub: Body:getRestitution
-- Returns the body restitution (bounciness).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getRestitution
  local _todo = "TODO: write a real Body:getRestitution usage example"
  print(_todo)
end

--@api-stub: Body:setRestitution
-- Sets the body restitution (bounciness).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setRestitution
  local _todo = "TODO: write a real Body:setRestitution usage example"
  print(_todo)
end

--@api-stub: Body:getLayer
-- Returns the collision layer bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getLayer
  local _todo = "TODO: write a real Body:getLayer usage example"
  print(_todo)
end

--@api-stub: Body:setLayer
-- Sets the collision layer bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setLayer
  local _todo = "TODO: write a real Body:setLayer usage example"
  print(_todo)
end

--@api-stub: Body:getMask
-- Returns the collision mask bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getMask
  local _todo = "TODO: write a real Body:getMask usage example"
  print(_todo)
end

--@api-stub: Body:setMask
-- Sets the collision mask bitmask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setMask
  local _todo = "TODO: write a real Body:setMask usage example"
  print(_todo)
end

--@api-stub: Body:applyImpulse
-- Applies a linear impulse to the body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:applyImpulse
  local _todo = "TODO: write a real Body:applyImpulse usage example"
  print(_todo)
end

--@api-stub: Body:applyForce
-- Applies a continuous force to the body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:applyForce
  local _todo = "TODO: write a real Body:applyForce usage example"
  print(_todo)
end

--@api-stub: Body:applyTorque
-- Applies a torque (rotational force).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:applyTorque
  local _todo = "TODO: write a real Body:applyTorque usage example"
  print(_todo)
end

--@api-stub: Body:applyAngularImpulse
-- Applies an angular impulse.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:applyAngularImpulse
  local _todo = "TODO: write a real Body:applyAngularImpulse usage example"
  print(_todo)
end

--@api-stub: Body:getGravityScale
-- Returns the per-body gravity multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getGravityScale
  local _todo = "TODO: write a real Body:getGravityScale usage example"
  print(_todo)
end

--@api-stub: Body:setGravityScale
-- Sets the per-body gravity multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setGravityScale
  local _todo = "TODO: write a real Body:setGravityScale usage example"
  print(_todo)
end

--@api-stub: Body:isFixedRotation
-- Returns whether rotation is locked.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:isFixedRotation
  local _todo = "TODO: write a real Body:isFixedRotation usage example"
  print(_todo)
end

--@api-stub: Body:setFixedRotation
-- Locks or unlocks rotation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setFixedRotation
  local _todo = "TODO: write a real Body:setFixedRotation usage example"
  print(_todo)
end

--@api-stub: Body:getLinearDamping
-- Returns the linear damping coefficient.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getLinearDamping
  local _todo = "TODO: write a real Body:getLinearDamping usage example"
  print(_todo)
end

--@api-stub: Body:setLinearDamping
-- Sets the linear damping coefficient.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setLinearDamping
  local _todo = "TODO: write a real Body:setLinearDamping usage example"
  print(_todo)
end

--@api-stub: Body:getAngularDamping
-- Returns the angular damping coefficient.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:getAngularDamping
  local _todo = "TODO: write a real Body:getAngularDamping usage example"
  print(_todo)
end

--@api-stub: Body:setAngularDamping
-- Sets the angular damping coefficient.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setAngularDamping
  local _todo = "TODO: write a real Body:setAngularDamping usage example"
  print(_todo)
end

--@api-stub: Body:isBullet
-- Returns whether CCD is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:isBullet
  local _todo = "TODO: write a real Body:isBullet usage example"
  print(_todo)
end

--@api-stub: Body:setBullet
-- Enables or disables continuous collision detection (CCD) for fast-moving bodies.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setBullet
  local _todo = "TODO: write a real Body:setBullet usage example"
  print(_todo)
end

--@api-stub: Body:isSleepingAllowed
-- Returns whether the body can sleep.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:isSleepingAllowed
  local _todo = "TODO: write a real Body:isSleepingAllowed usage example"
  print(_todo)
end

--@api-stub: Body:setSleepingAllowed
-- Sets whether the body can sleep.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:setSleepingAllowed
  local _todo = "TODO: write a real Body:setSleepingAllowed usage example"
  print(_todo)
end

--@api-stub: Body:destroy
-- Removes this body from the world.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:destroy
  local _todo = "TODO: write a real Body:destroy usage example"
  print(_todo)
end

--@api-stub: Body:isSleeping
-- Returns true if this body is currently sleeping (inactive).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:isSleeping
  local _todo = "TODO: write a real Body:isSleeping usage example"
  print(_todo)
end

--@api-stub: Body:wakeUp
-- Forcibly wakes up this body.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:wakeUp
  local _todo = "TODO: write a real Body:wakeUp usage example"
  print(_todo)
end

--@api-stub: Body:sleep
-- Puts this body to sleep immediately.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: Body:sleep
  local _todo = "TODO: write a real Body:sleep usage example"
  print(_todo)
end

-- ── PhysicsShape methods ──

--@api-stub: PhysicsShape:getType
-- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: PhysicsShape:getType
  local _todo = "TODO: write a real PhysicsShape:getType usage example"
  print(_todo)
end

--@api-stub: PhysicsShape:getRadius
-- Returns the radius.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: PhysicsShape:getRadius
  local _todo = "TODO: write a real PhysicsShape:getRadius usage example"
  print(_todo)
end

--@api-stub: PhysicsShape:getBoundingBox
-- Returns the axis-aligned bounding box (x1, y1, x2, y2).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: PhysicsShape:getBoundingBox
  local _todo = "TODO: write a real PhysicsShape:getBoundingBox usage example"
  print(_todo)
end

--@api-stub: PhysicsShape:setDensity
-- Sets the density for this shape (used when attaching to a body).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: PhysicsShape:setDensity
  local _todo = "TODO: write a real PhysicsShape:setDensity usage example"
  print(_todo)
end

--@api-stub: PhysicsShape:setFriction
-- Sets the friction coefficient.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: PhysicsShape:setFriction
  local _todo = "TODO: write a real PhysicsShape:setFriction usage example"
  print(_todo)
end

--@api-stub: PhysicsShape:setRestitution
-- Sets the restitution (bounciness) coefficient.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: PhysicsShape:setRestitution
  local _todo = "TODO: write a real PhysicsShape:setRestitution usage example"
  print(_todo)
end

--@api-stub: PhysicsShape:setSensor
-- Sets whether this shape is a sensor (non-colliding trigger).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: PhysicsShape:setSensor
  local _todo = "TODO: write a real PhysicsShape:setSensor usage example"
  print(_todo)
end

--@api-stub: PhysicsShape:destroy
-- Releases this shape handle (GC handles cleanup).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/physics_api.rs and docs/specs/physics.md).
do  -- TODO: PhysicsShape:destroy
  local _todo = "TODO: write a real PhysicsShape:destroy usage example"
  print(_todo)
end

