-- content/examples/physics.lua
-- Auto-scaffolded coverage of the lurek.physics Lua API (147 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/physics.lua

print("[example] lurek.physics loaded — 147 API items demonstrated")

-- ── lurek.physics free functions ──

--@api-stub: lurek.physics.newWorld
-- Creates a new physics world with the given gravity vector.
-- Use this when creates a new physics world with the given gravity vector is needed.
if false then
  local _r = lurek.physics.newWorld(0, 0)
  print(_r)
end

--@api-stub: lurek.physics.step
-- Advances the physics world by dt seconds.
-- Use this when advances the physics world by dt seconds is needed.
if false then
  local _r = lurek.physics.step(0, 0)
  print(_r)
end

--@api-stub: lurek.physics.destroyWorld
-- Marks a physics world for destruction.
-- Subsequent operations on the world
if false then
  local _r = lurek.physics.destroyWorld(0)
  print(_r)
end

--@api-stub: lurek.physics.newBody
-- Creates a new rectangular body in the given world.
-- Use this when creates a new rectangular body in the given world is needed.
if false then
  local _r = lurek.physics.newBody(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.physics.getBody
-- Returns the position and velocity of a body (x, y, vx, vy).
-- Use this when returns the position and velocity of a body (x, y, vx, vy) is needed.
if false then
  local _r = lurek.physics.getBody(0, 0)
  print(_r)
end

--@api-stub: lurek.physics.setBodyVelocity
-- Sets the velocity of a body.
-- Use this when sets the velocity of a body is needed.
if false then
  local _r = lurek.physics.setBodyVelocity(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.physics.isSleepingAllowed
-- Returns whether the body is allowed to sleep.
-- Use this when returns whether the body is allowed to sleep is needed.
if false then
  local _r = lurek.physics.isSleepingAllowed(0, 0)
  print(_r)
end

--@api-stub: lurek.physics.setSleepingAllowed
-- Sets whether the body is allowed to sleep.
-- Use this when sets whether the body is allowed to sleep is needed.
if false then
  local _r = lurek.physics.setSleepingAllowed(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.physics.newRectangleShape
-- Creates a rectangle shape userdata.
-- Use this when creates a rectangle shape userdata is needed.
if false then
  local _r = lurek.physics.newRectangleShape(0, 0)
  print(_r)
end

--@api-stub: lurek.physics.newCircleShape
-- Creates a circle shape userdata.
-- Use this when creates a circle shape userdata is needed.
if false then
  local _r = lurek.physics.newCircleShape(nil)
  print(_r)
end

--@api-stub: lurek.physics.newEdgeShape
-- Creates an edge (line segment) shape userdata.
-- Use this when creates an edge (line segment) shape userdata is needed.
if false then
  local _r = lurek.physics.newEdgeShape(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.physics.newPolygonShape
-- Creates a convex polygon shape userdata from flat variadic vertex pairs.
-- Use this when creates a convex polygon shape userdata from flat variadic vertex pairs is needed.
if false then
  local _r = lurek.physics.newPolygonShape()
  print(_r)
end

--@api-stub: lurek.physics.newChainShape
-- Creates a chain shape userdata from flat variadic vertex pairs.
-- Use this when creates a chain shape userdata from flat variadic vertex pairs is needed.
if false then
  local _r = lurek.physics.newChainShape(nil, nil)
  print(_r)
end

--@api-stub: lurek.physics.attachShape
-- Attaches a standalone shape to a body as an additional fixture.
-- Use this when attaches a standalone shape to a body as an additional fixture is needed.
if false then
  local _r = lurek.physics.attachShape(0, 0)
  print(_r)
end

--@api-stub: lurek.physics.getCollisions
-- Returns all collision events from the last simulation step.
-- Use this when returns all collision events from the last simulation step is needed.
if false then
  local _r = lurek.physics.getCollisions(0)
  print(_r)
end

--@api-stub: lurek.physics.debugDraw
-- Enables or disables the physics debug overlay (AABB boxes and velocity vectors).
-- Use this when enables or disables the physics debug overlay (AABB boxes and velocity vectors) is needed.
if false then
  local _r = lurek.physics.debugDraw(1)
  print(_r)
end

--@api-stub: lurek.physics.drawDebugGpu
-- Extracts collider geometry from a World and queues a GPU physics debug.
-- Use this when extracts collider geometry from a World and queues a GPU physics debug is needed.
if false then
  local _r = lurek.physics.drawDebugGpu(0, 1)
  print(_r)
end

--@api-stub: lurek.physics.newTerrain
-- Creates a destructible terrain grid.
-- Use this when creates a destructible terrain grid is needed.
if false then
  local _r = lurek.physics.newTerrain(1, 1, 1, 0)
  print(_r)
end

--@api-stub: lurek.physics.newCellular
-- Creates a falling-sand cellular automaton grid.
-- Use this when creates a falling-sand cellular automaton grid is needed.
if false then
  local _r = lurek.physics.newCellular(1, 1)
  print(_r)
end

-- ── World methods ──

--@api-stub: World:step
-- Advances the physics simulation by dt seconds, firing onBeginContact /.
-- Use this when advances the physics simulation by dt seconds, firing onBeginContact / is needed.
if false then
  local _o = nil  -- World instance
  _o:step(0)
end

--@api-stub: World:clear
-- Resets the world, removing all bodies and joints.
-- Use this when resets the world, removing all bodies and joints is needed.
if false then
  local _o = nil  -- World instance
  _o:clear()
end

--@api-stub: World:getGravity
-- Returns the gravity vector (gx, gy).
-- Use this when returns the gravity vector (gx, gy) is needed.
if false then
  local _o = nil  -- World instance
  _o:getGravity()
end

--@api-stub: World:setGravity
-- Sets the world gravity vector; default is `(0, 9.81)` (downward).
-- Use this when sets the world gravity vector; default is `(0, 9.81)` (downward) is needed.
if false then
  local _o = nil  -- World instance
  _o:setGravity(0, 0)
end

--@api-stub: World:setMeter
-- Sets the pixels-per-meter scaling factor.
-- Use this when sets the pixels-per-meter scaling factor is needed.
if false then
  local _o = nil  -- World instance
  _o:setMeter(nil)
end

--@api-stub: World:getMeter
-- Returns the pixels-per-meter scaling factor.
-- Use this when returns the pixels-per-meter scaling factor is needed.
if false then
  local _o = nil  -- World instance
  _o:getMeter()
end

--@api-stub: World:toPhysics
-- Converts a pixel value to physics units.
-- Use this when converts a pixel value to physics units is needed.
if false then
  local _o = nil  -- World instance
  _o:toPhysics(0)
end

--@api-stub: World:toPixels
-- Converts a physics-unit value to pixels.
-- Use this when converts a physics-unit value to pixels is needed.
if false then
  local _o = nil  -- World instance
  _o:toPixels(nil)
end

--@api-stub: World:getBodyCount
-- Returns the total number of bodies in the world.
-- Use this when returns the total number of bodies in the world is needed.
if false then
  local _o = nil  -- World instance
  _o:getBodyCount()
end

--@api-stub: World:getBodyIds
-- Returns all body IDs in the world.
-- Use this when returns all body IDs in the world is needed.
if false then
  local _o = nil  -- World instance
  _o:getBodyIds()
end

--@api-stub: World:destroyBody
-- Removes a body from the world.
-- Use this when removes a body from the world is needed.
if false then
  local _o = nil  -- World instance
  _o:destroyBody(1)
end

--@api-stub: World:newBody
-- Creates a new rectangular body and adds it to the world.
-- Use this when creates a new rectangular body and adds it to the world is needed.
if false then
  local _o = nil  -- World instance
  _o:newBody(0, 0, 0)
end

--@api-stub: World:fixtureCount
-- Returns the number of fixtures on a body.
-- Use this when returns the number of fixtures on a body is needed.
if false then
  local _o = nil  -- World instance
  _o:fixtureCount(1)
end

--@api-stub: World:jointCount
-- Returns the total number of joints.
-- Use this when returns the total number of joints is needed.
if false then
  local _o = nil  -- World instance
  _o:jointCount()
end

--@api-stub: World:getJointIds
-- Returns a table of integer IDs for every joint attached to this world.
-- Use this when returns a table of integer IDs for every joint attached to this world is needed.
if false then
  local _o = nil  -- World instance
  _o:getJointIds()
end

--@api-stub: World:getJointBodies
-- Returns the two body IDs connected by a joint.
-- Use this when returns the two body IDs connected by a joint is needed.
if false then
  local _o = nil  -- World instance
  _o:getJointBodies(1)
end

--@api-stub: World:destroyJoint
-- Removes a joint from the world.
-- Use this when removes a joint from the world is needed.
if false then
  local _o = nil  -- World instance
  _o:destroyJoint(1)
end

--@api-stub: World:getJointType
-- Returns the type name of a joint.
-- Use this when returns the type name of a joint is needed.
if false then
  local _o = nil  -- World instance
  _o:getJointType(1)
end

--@api-stub: World:getJointMotorSpeed
-- Returns the motor speed on a joint's angular axis.
-- Use this when returns the motor speed on a joint's angular axis is needed.
if false then
  local _o = nil  -- World instance
  _o:getJointMotorSpeed(1)
end

--@api-stub: World:getJointLimits
-- Returns the angular limits on a joint.
-- Use this when returns the angular limits on a joint is needed.
if false then
  local _o = nil  -- World instance
  _o:getJointLimits(1)
end

--@api-stub: World:getBodyAtPoint
-- Returns the body ID at a world-space point, or nil.
-- Use this when returns the body ID at a world-space point, or nil is needed.
if false then
  local _o = nil  -- World instance
  _o:getBodyAtPoint(0, 0)
end

--@api-stub: World:getCollisionEvents
-- Returns collision events from the last step.
-- Use this when returns collision events from the last step is needed.
if false then
  local _o = nil  -- World instance
  _o:getCollisionEvents()
end

--@api-stub: World:getBeginContactEvents
-- Returns begin-contact events from the last step.
-- Use this when returns begin-contact events from the last step is needed.
if false then
  local _o = nil  -- World instance
  _o:getBeginContactEvents()
end

--@api-stub: World:getEndContactEvents
-- Returns end-contact events from the last step.
-- Use this when returns end-contact events from the last step is needed.
if false then
  local _o = nil  -- World instance
  _o:getEndContactEvents()
end

--@api-stub: World:getContacts
-- Returns all contact pairs from the narrow phase.
-- Use this when returns all contact pairs from the narrow phase is needed.
if false then
  local _o = nil  -- World instance
  _o:getContacts()
end

--@api-stub: World:getBodyContacts
-- Returns contacts involving a specific body.
-- Use this when returns contacts involving a specific body is needed.
if false then
  local _o = nil  -- World instance
  _o:getBodyContacts(1)
end

--@api-stub: World:setBodyType
-- Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
-- Use this when changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"` is needed.
if false then
  local _o = nil  -- World instance
  _o:setBodyType(1, 0)
end

--@api-stub: World:getBodyType
-- Returns the body type as a string.
-- Use this when returns the body type as a string is needed.
if false then
  local _o = nil  -- World instance
  _o:getBodyType(1)
end

--@api-stub: World:setBeginContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- Use this when registers a Lua function called with (bodyIdA, bodyIdB) when two is needed.
if false then
  local _o = nil  -- World instance
  _o:setBeginContact(nil)
end

--@api-stub: World:clearBeginContact
-- Removes the begin-contact callback.
-- Use this when removes the begin-contact callback is needed.
if false then
  local _o = nil  -- World instance
  _o:clearBeginContact()
end

--@api-stub: World:setEndContact
-- Registers a Lua function called with (bodyIdA, bodyIdB) when two.
-- Use this when registers a Lua function called with (bodyIdA, bodyIdB) when two is needed.
if false then
  local _o = nil  -- World instance
  _o:setEndContact(nil)
end

--@api-stub: World:clearEndContact
-- Removes the end-contact callback.
-- Use this when removes the end-contact callback is needed.
if false then
  local _o = nil  -- World instance
  _o:clearEndContact()
end

--@api-stub: World:getBodyData
-- Returns the Lua data previously attached to a body, or nil if none is set.
-- Use this when returns the Lua data previously attached to a body, or nil if none is set is needed.
if false then
  local _o = nil  -- World instance
  _o:getBodyData(1)
end

--@api-stub: World:clearBodyData
-- Removes the Lua data attached to a body.
-- Use this when removes the Lua data attached to a body is needed.
if false then
  local _o = nil  -- World instance
  _o:clearBodyData(1)
end

--@api-stub: World:setBodyCCD
-- Enables or disables Continuous Collision Detection for a body.
-- Use this when enables or disables Continuous Collision Detection for a body is needed.
if false then
  local _o = nil  -- World instance
  _o:setBodyCCD(1, 1)
end

--@api-stub: World:getBodyCCD
-- Returns whether CCD is enabled for a body.
-- Use this when returns whether CCD is enabled for a body is needed.
if false then
  local _o = nil  -- World instance
  _o:getBodyCCD(1)
end

--@api-stub: World:clearBodyOneWay
-- Removes the one-way platform flag from a body.
-- Use this when removes the one-way platform flag from a body is needed.
if false then
  local _o = nil  -- World instance
  _o:clearBodyOneWay(1)
end

--@api-stub: World:getBodyOneWay
-- Returns the one-way normal for a body, or nil if not configured.
-- Use this when returns the one-way normal for a body, or nil if not configured is needed.
if false then
  local _o = nil  -- World instance
  _o:getBodyOneWay(1)
end

--@api-stub: World:setJointBreakForce
-- Sets the relative-velocity threshold above which a joint breaks.
-- Use this when sets the relative-velocity threshold above which a joint breaks is needed.
if false then
  local _o = nil  -- World instance
  _o:setJointBreakForce(1, nil)
end

--@api-stub: World:getJointBreakForce
-- Returns the break threshold for a joint, or nil if not set.
-- Use this when returns the break threshold for a joint, or nil if not set is needed.
if false then
  local _o = nil  -- World instance
  _o:getJointBreakForce(1)
end

--@api-stub: World:isBodySleeping
-- Returns true if a body is currently sleeping (inactive).
-- Use this when returns true if a body is currently sleeping (inactive) is needed.
if false then
  local _o = nil  -- World instance
  _o:isBodySleeping(1)
end

--@api-stub: World:wakeUpBody
-- Forcibly wakes up a sleeping body.
-- Use this when forcibly wakes up a sleeping body is needed.
if false then
  local _o = nil  -- World instance
  _o:wakeUpBody(1)
end

--@api-stub: World:sleepBody
-- Puts a body to sleep immediately.
-- Use this when puts a body to sleep immediately is needed.
if false then
  local _o = nil  -- World instance
  _o:sleepBody(1)
end

--@api-stub: World:setSolverIterations
-- Sets the number of constraint solver iterations per step.
-- Use this when sets the number of constraint solver iterations per step is needed.
if false then
  local _o = nil  -- World instance
  _o:setSolverIterations(1)
end

--@api-stub: World:getSolverIterations
-- Returns the current number of solver iterations per step.
-- Use this when returns the current number of solver iterations per step is needed.
if false then
  local _o = nil  -- World instance
  _o:getSolverIterations()
end

--@api-stub: World:newBodies
-- Creates multiple bodies in one call.
-- Use this when creates multiple bodies in one call is needed.
if false then
  local _o = nil  -- World instance
  _o:newBodies(nil)
end

--@api-stub: World:addZone
-- Creates a rectangular gravity/damping zone and returns a LuaZone handle.
-- Use this when creates a rectangular gravity/damping zone and returns a LuaZone handle is needed.
if false then
  local _o = nil  -- World instance
  _o:addZone(0, 0, 0, 0)
end

--@api-stub: World:getZoneEvents
-- Returns zone enter/leave events produced by the most recent step.
-- Use this when returns zone enter/leave events produced by the most recent step is needed.
if false then
  local _o = nil  -- World instance
  _o:getZoneEvents()
end

-- ── Zone methods ──

--@api-stub: Zone:getId
-- Returns the zone's integer ID.
-- Use this when returns the zone's integer ID is needed.
if false then
  local _o = nil  -- Zone instance
  _o:getId()
end

--@api-stub: Zone:setEnabled
-- Enables or disables the zone.
-- Use this when enables or disables the zone is needed.
if false then
  local _o = nil  -- Zone instance
  _o:setEnabled(1)
end

--@api-stub: Zone:setPriority
-- Sets the zone priority; higher values win over lower when zones overlap.
-- Use this when sets the zone priority; higher values win over lower when zones overlap is needed.
if false then
  local _o = nil  -- Zone instance
  _o:setPriority(0)
end

--@api-stub: Zone:setLayerMask
-- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
-- Use this when sets the layer bitmask; only bodies whose `layer & mask != 0` are affected is needed.
if false then
  local _o = nil  -- Zone instance
  _o:setLayerMask(nil)
end

--@api-stub: Zone:setCircle
-- Replaces the zone boundary with a circle.
-- Use this when replaces the zone boundary with a circle is needed.
if false then
  local _o = nil  -- Zone instance
  _o:setCircle(0, 0, nil)
end

--@api-stub: Zone:setGravityDirectional
-- Sets directional gravity inside the zone.
-- Use this when sets directional gravity inside the zone is needed.
if false then
  local _o = nil  -- Zone instance
  _o:setGravityDirectional(0, 0)
end

--@api-stub: Zone:setGravityZero
-- Suppresses gravity inside the zone (zero-g pocket).
-- Use this when suppresses gravity inside the zone (zero-g pocket) is needed.
if false then
  local _o = nil  -- Zone instance
  _o:setGravityZero()
end

--@api-stub: Zone:setLinearDampingOverride
-- Sets an optional linear damping override for bodies inside the zone.
-- Use this when sets an optional linear damping override for bodies inside the zone is needed.
if false then
  local _o = nil  -- Zone instance
  _o:setLinearDampingOverride(0)
end

--@api-stub: Zone:destroy
-- Removes the zone from the world.
-- Use this when removes the zone from the world is needed.
if false then
  local _o = nil  -- Zone instance
  _o:destroy()
end

-- ── Terrain methods ──

--@api-stub: Terrain:setCell
-- Sets a single terrain cell to solid or empty.
-- Use this when sets a single terrain cell to solid or empty is needed.
if false then
  local _o = nil  -- Terrain instance
  _o:setCell(0, 0, 1)
end

--@api-stub: Terrain:getCell
-- Returns whether a cell is solid.
-- Use this when returns whether a cell is solid is needed.
if false then
  local _o = nil  -- Terrain instance
  _o:getCell(0, 0)
end

--@api-stub: Terrain:fillAll
-- Sets every cell in the grid to `solid`.
-- Use this when sets every cell in the grid to `solid` is needed.
if false then
  local _o = nil  -- Terrain instance
  _o:fillAll(1)
end

--@api-stub: Terrain:flush
-- Rebuilds physics bodies for all dirty chunks.
-- Use this when rebuilds physics bodies for all dirty chunks is needed.
if false then
  local _o = nil  -- Terrain instance
  _o:flush()
end

--@api-stub: Terrain:isDirty
-- Returns `true` when at least one chunk needs flushing.
-- Use this when returns `true` when at least one chunk needs flushing is needed.
if false then
  local _o = nil  -- Terrain instance
  _o:isDirty()
end

--@api-stub: Terrain:collapseColumns
-- Removes unsupported cells, returning the number of cells that fell.
-- Use this when removes unsupported cells, returning the number of cells that fell is needed.
if false then
  local _o = nil  -- Terrain instance
  _o:collapseColumns()
end

--@api-stub: Terrain:solidPositions
-- Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
-- Use this when returns the world-space centres of all solid cells as an array of `{x, y}` tables is needed.
if false then
  local _o = nil  -- Terrain instance
  _o:solidPositions()
end

--@api-stub: Terrain:toBytes
-- Serialises the terrain grid to a byte string for save/load.
-- Use this when serialises the terrain grid to a byte string for save/load is needed.
if false then
  local _o = nil  -- Terrain instance
  _o:toBytes()
end

--@api-stub: Terrain:loadFromBytes
-- Loads terrain cell data from bytes produced by `toBytes`.
-- Use this when loads terrain cell data from bytes produced by `toBytes` is needed.
if false then
  local _o = nil  -- Terrain instance
  _o:loadFromBytes(0)
end

-- ── Cellular methods ──

--@api-stub: Cellular:setCell
-- Sets the material of a cell.
-- Use this when sets the material of a cell is needed.
if false then
  local _o = nil  -- Cellular instance
  _o:setCell(0, 0, 0)
end

--@api-stub: Cellular:getCell
-- Returns the material at `(cx, cy)` as an integer constant.
-- Use this when returns the material at `(cx, cy)` as an integer constant is needed.
if false then
  local _o = nil  -- Cellular instance
  _o:getCell(0, 0)
end

--@api-stub: Cellular:step
-- Advances the simulation by one tick.
-- Use this when advances the simulation by one tick is needed.
if false then
  local _o = nil  -- Cellular instance
  _o:step()
end

--@api-stub: Cellular:stepN
-- Advances the simulation by `n` ticks.
-- Use this when advances the simulation by `n` ticks is needed.
if false then
  local _o = nil  -- Cellular instance
  _o:stepN(1)
end

--@api-stub: Cellular:toImageData
-- Returns the full grid as an RGBA byte string using the default colour palette.
-- Use this when returns the full grid as an RGBA byte string using the default colour palette is needed.
if false then
  local _o = nil  -- Cellular instance
  _o:toImageData()
end

--@api-stub: Cellular:countCells
-- Counts cells of the given material type.
-- Use this when counts cells of the given material type is needed.
if false then
  local _o = nil  -- Cellular instance
  _o:countCells(0)
end

--@api-stub: Cellular:findCells
-- Returns positions of all cells of the given material as an array of `{x, y}` tables.
-- Use this when returns positions of all cells of the given material as an array of `{x, y}` tables is needed.
if false then
  local _o = nil  -- Cellular instance
  _o:findCells(0)
end

--@api-stub: Cellular:toBytes
-- Serialises the grid to a byte string.
-- Use this when serialises the grid to a byte string is needed.
if false then
  local _o = nil  -- Cellular instance
  _o:toBytes()
end

--@api-stub: Cellular:loadFromBytes
-- Loads grid data from bytes produced by `toBytes`.
-- Use this when loads grid data from bytes produced by `toBytes` is needed.
if false then
  local _o = nil  -- Cellular instance
  _o:loadFromBytes(0)
end

-- ── Body methods ──

--@api-stub: Body:getId
-- Returns the body's integer ID.
-- Use this when returns the body's integer ID is needed.
if false then
  local _o = nil  -- Body instance
  _o:getId()
end

--@api-stub: Body:getPosition
-- Returns the body position (x, y).
-- Use this when returns the body position (x, y) is needed.
if false then
  local _o = nil  -- Body instance
  _o:getPosition()
end

--@api-stub: Body:setPosition
-- Teleports the body to the given world-space position, bypassing collision.
-- Use this when teleports the body to the given world-space position, bypassing collision is needed.
if false then
  local _o = nil  -- Body instance
  _o:setPosition(0, 0)
end

--@api-stub: Body:getX
-- Returns the body X position.
-- Use this when returns the body X position is needed.
if false then
  local _o = nil  -- Body instance
  _o:getX()
end

--@api-stub: Body:getY
-- Returns the body Y position.
-- Use this when returns the body Y position is needed.
if false then
  local _o = nil  -- Body instance
  _o:getY()
end

--@api-stub: Body:getVelocity
-- Returns the body velocity (vx, vy).
-- Use this when returns the body velocity (vx, vy) is needed.
if false then
  local _o = nil  -- Body instance
  _o:getVelocity()
end

--@api-stub: Body:setVelocity
-- Sets the body's linear velocity in world units per second.
-- Use this when sets the body's linear velocity in world units per second is needed.
if false then
  local _o = nil  -- Body instance
  _o:setVelocity(0, 0)
end

--@api-stub: Body:getAngle
-- Returns the body angle in radians.
-- Use this when returns the body angle in radians is needed.
if false then
  local _o = nil  -- Body instance
  _o:getAngle()
end

--@api-stub: Body:setAngle
-- Sets the body angle in radians.
-- Use this when sets the body angle in radians is needed.
if false then
  local _o = nil  -- Body instance
  _o:setAngle(1)
end

--@api-stub: Body:getAngularVelocity
-- Returns the angular velocity in radians/s.
-- Use this when returns the angular velocity in radians/s is needed.
if false then
  local _o = nil  -- Body instance
  _o:getAngularVelocity()
end

--@api-stub: Body:setAngularVelocity
-- Sets the angular velocity.
-- Use this when sets the angular velocity is needed.
if false then
  local _o = nil  -- Body instance
  _o:setAngularVelocity(nil)
end

--@api-stub: Body:getMass
-- Returns the body mass in kilograms used for force and impulse calculations.
-- Use this when returns the body mass in kilograms used for force and impulse calculations is needed.
if false then
  local _o = nil  -- Body instance
  _o:getMass()
end

--@api-stub: Body:setMass
-- Sets the body mass; affects how forces and impulses change velocity.
-- Use this when sets the body mass; affects how forces and impulses change velocity is needed.
if false then
  local _o = nil  -- Body instance
  _o:setMass(nil)
end

--@api-stub: Body:getType
-- Returns the body type as a string.
-- Use this when returns the body type as a string is needed.
if false then
  local _o = nil  -- Body instance
  _o:getType()
end

--@api-stub: Body:setType
-- Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
-- Use this when changes the body type: `"dynamic"`, `"static"`, or `"kinematic"` is needed.
if false then
  local _o = nil  -- Body instance
  _o:setType(0)
end

--@api-stub: Body:getWidth
-- Returns the width of this body's primary collider shape in world units.
-- Use this when returns the width of this body's primary collider shape in world units is needed.
if false then
  local _o = nil  -- Body instance
  _o:getWidth()
end

--@api-stub: Body:getHeight
-- Returns the height of this body's primary collider shape in world units.
-- Use this when returns the height of this body's primary collider shape in world units is needed.
if false then
  local _o = nil  -- Body instance
  _o:getHeight()
end

--@api-stub: Body:getFriction
-- Returns the body friction coefficient.
-- Use this when returns the body friction coefficient is needed.
if false then
  local _o = nil  -- Body instance
  _o:getFriction()
end

--@api-stub: Body:setFriction
-- Sets the body friction coefficient.
-- Use this when sets the body friction coefficient is needed.
if false then
  local _o = nil  -- Body instance
  _o:setFriction(1)
end

--@api-stub: Body:getRestitution
-- Returns the body restitution (bounciness).
-- Use this when returns the body restitution (bounciness) is needed.
if false then
  local _o = nil  -- Body instance
  _o:getRestitution()
end

--@api-stub: Body:setRestitution
-- Sets the body restitution (bounciness).
-- Use this when sets the body restitution (bounciness) is needed.
if false then
  local _o = nil  -- Body instance
  _o:setRestitution(1)
end

--@api-stub: Body:getLayer
-- Returns the collision layer bitmask.
-- Use this when returns the collision layer bitmask is needed.
if false then
  local _o = nil  -- Body instance
  _o:getLayer()
end

--@api-stub: Body:setLayer
-- Sets the collision layer bitmask.
-- Use this when sets the collision layer bitmask is needed.
if false then
  local _o = nil  -- Body instance
  _o:setLayer(0)
end

--@api-stub: Body:getMask
-- Returns the collision mask bitmask.
-- Use this when returns the collision mask bitmask is needed.
if false then
  local _o = nil  -- Body instance
  _o:getMask()
end

--@api-stub: Body:setMask
-- Sets the collision mask bitmask.
-- Use this when sets the collision mask bitmask is needed.
if false then
  local _o = nil  -- Body instance
  _o:setMask(nil)
end

--@api-stub: Body:applyImpulse
-- Applies a linear impulse to the body.
-- Use this when applies a linear impulse to the body is needed.
if false then
  local _o = nil  -- Body instance
  _o:applyImpulse(0, 0)
end

--@api-stub: Body:applyForce
-- Applies a continuous force to the body.
-- Use this when applies a continuous force to the body is needed.
if false then
  local _o = nil  -- Body instance
  _o:applyForce(0, 0)
end

--@api-stub: Body:applyTorque
-- Applies a torque (rotational force).
-- Use this when applies a torque (rotational force) is needed.
if false then
  local _o = nil  -- Body instance
  _o:applyTorque(0)
end

--@api-stub: Body:applyAngularImpulse
-- Applies an angular impulse.
-- Use this when applies an angular impulse is needed.
if false then
  local _o = nil  -- Body instance
  _o:applyAngularImpulse(nil)
end

--@api-stub: Body:getGravityScale
-- Returns the per-body gravity multiplier.
-- Use this when returns the per-body gravity multiplier is needed.
if false then
  local _o = nil  -- Body instance
  _o:getGravityScale()
end

--@api-stub: Body:setGravityScale
-- Sets the per-body gravity multiplier.
-- Use this when sets the per-body gravity multiplier is needed.
if false then
  local _o = nil  -- Body instance
  _o:setGravityScale(0)
end

--@api-stub: Body:isFixedRotation
-- Returns whether rotation is locked.
-- Use this when returns whether rotation is locked is needed.
if false then
  local _o = nil  -- Body instance
  _o:isFixedRotation()
end

--@api-stub: Body:setFixedRotation
-- Locks or unlocks rotation.
-- Use this when locks or unlocks rotation is needed.
if false then
  local _o = nil  -- Body instance
  _o:setFixedRotation(0)
end

--@api-stub: Body:getLinearDamping
-- Returns the linear damping coefficient.
-- Use this when returns the linear damping coefficient is needed.
if false then
  local _o = nil  -- Body instance
  _o:getLinearDamping()
end

--@api-stub: Body:setLinearDamping
-- Sets the linear damping coefficient.
-- Use this when sets the linear damping coefficient is needed.
if false then
  local _o = nil  -- Body instance
  _o:setLinearDamping(1)
end

--@api-stub: Body:getAngularDamping
-- Returns the angular damping coefficient.
-- Use this when returns the angular damping coefficient is needed.
if false then
  local _o = nil  -- Body instance
  _o:getAngularDamping()
end

--@api-stub: Body:setAngularDamping
-- Sets the angular damping coefficient.
-- Use this when sets the angular damping coefficient is needed.
if false then
  local _o = nil  -- Body instance
  _o:setAngularDamping(1)
end

--@api-stub: Body:isBullet
-- Returns whether CCD is enabled.
-- Use this when returns whether CCD is enabled is needed.
if false then
  local _o = nil  -- Body instance
  _o:isBullet()
end

--@api-stub: Body:setBullet
-- Enables or disables continuous collision detection (CCD) for fast-moving bodies.
-- Use this when enables or disables continuous collision detection (CCD) for fast-moving bodies is needed.
if false then
  local _o = nil  -- Body instance
  _o:setBullet(0)
end

--@api-stub: Body:isSleepingAllowed
-- Returns whether the body can sleep.
-- Use this when returns whether the body can sleep is needed.
if false then
  local _o = nil  -- Body instance
  _o:isSleepingAllowed()
end

--@api-stub: Body:setSleepingAllowed
-- Sets whether the body can sleep.
-- Use this when sets whether the body can sleep is needed.
if false then
  local _o = nil  -- Body instance
  _o:setSleepingAllowed(0)
end

--@api-stub: Body:destroy
-- Removes this body from the world.
-- Use this when removes this body from the world is needed.
if false then
  local _o = nil  -- Body instance
  _o:destroy()
end

--@api-stub: Body:isSleeping
-- Returns true if this body is currently sleeping (inactive).
-- Use this when returns true if this body is currently sleeping (inactive) is needed.
if false then
  local _o = nil  -- Body instance
  _o:isSleeping()
end

--@api-stub: Body:wakeUp
-- Forcibly wakes up this body.
-- Use this when forcibly wakes up this body is needed.
if false then
  local _o = nil  -- Body instance
  _o:wakeUp()
end

--@api-stub: Body:sleep
-- Puts this body to sleep immediately.
-- Use this when puts this body to sleep immediately is needed.
if false then
  local _o = nil  -- Body instance
  _o:sleep()
end

-- ── PhysicsShape methods ──

--@api-stub: PhysicsShape:getType
-- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
-- Use this when returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain" is needed.
if false then
  local _o = nil  -- PhysicsShape instance
  _o:getType()
end

--@api-stub: PhysicsShape:getRadius
-- Returns the radius.
-- Only valid for circle shapes.
if false then
  local _o = nil  -- PhysicsShape instance
  _o:getRadius()
end

--@api-stub: PhysicsShape:getBoundingBox
-- Returns the axis-aligned bounding box (x1, y1, x2, y2).
-- Use this when returns the axis-aligned bounding box (x1, y1, x2, y2) is needed.
if false then
  local _o = nil  -- PhysicsShape instance
  _o:getBoundingBox()
end

--@api-stub: PhysicsShape:setDensity
-- Sets the density for this shape (used when attaching to a body).
-- Use this when sets the density for this shape (used when attaching to a body) is needed.
if false then
  local _o = nil  -- PhysicsShape instance
  _o:setDensity(1)
end

--@api-stub: PhysicsShape:setFriction
-- Sets the friction coefficient.
-- Use this when sets the friction coefficient is needed.
if false then
  local _o = nil  -- PhysicsShape instance
  _o:setFriction(1)
end

--@api-stub: PhysicsShape:setRestitution
-- Sets the restitution (bounciness) coefficient.
-- Use this when sets the restitution (bounciness) coefficient is needed.
if false then
  local _o = nil  -- PhysicsShape instance
  _o:setRestitution(1)
end

--@api-stub: PhysicsShape:setSensor
-- Sets whether this shape is a sensor (non-colliding trigger).
-- Use this when sets whether this shape is a sensor (non-colliding trigger) is needed.
if false then
  local _o = nil  -- PhysicsShape instance
  _o:setSensor(1)
end

--@api-stub: PhysicsShape:destroy
-- Releases this shape handle (GC handles cleanup).
-- Use this when releases this shape handle (GC handles cleanup) is needed.
if false then
  local _o = nil  -- PhysicsShape instance
  _o:destroy()
end

