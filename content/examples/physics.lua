-- content/examples/physics.lua
-- lurek.physics API examples.
-- Run: cargo run -- content/examples/physics.lua

--@api-stub: lurek.physics.newWorld
-- Creates a new physics world with the given gravity vector
do
  local world = lurek.physics.newWorld(0, 9.81)
  lurek.log.info("physics world created with " .. world:getBodyCount() .. " bodies", "boot")
end

--@api-stub: lurek.physics.step
-- Steps a physics world forward by dt seconds (free-function variant)
do
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    lurek.physics.step(world, dt)
  end
end

--@api-stub: lurek.physics.destroyWorld
-- No-op placeholder for API parity
do
  local world = lurek.physics.newWorld(0, 9.81)
  lurek.physics.destroyWorld(world)
  world = nil --[[@type any]]
end

--@api-stub: lurek.physics.newBody
-- Creates a new body in a world (free-function variant)
do
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = lurek.physics.newBody(world, 100, 200, "dynamic")
  crate:setMass(1.0)
end

--@api-stub: lurek.physics.getBody
-- Returns position and velocity of a body (free-function variant for quick queries)
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = lurek.physics.newBody(world, 100, 200, "dynamic")
  local x, y, vx, vy = lurek.physics.getBody(world, body)
  lurek.log.debug("crate at " .. x .. "," .. y .. " v=" .. vx .. "," .. vy, "phys")
end

--@api-stub: lurek.physics.setBodyVelocity
-- Sets a body's velocity (free-function variant)
do
  local world = lurek.physics.newWorld(0, 9.81)
  local bullet = lurek.physics.newBody(world, 100, 200, "dynamic")
  lurek.physics.setBodyVelocity(world, bullet, 600, -200)
end

--@api-stub: lurek.physics.isSleepingAllowed
-- Checks if sleeping is allowed on a body (free-function variant)
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = lurek.physics.newBody(world, 100, 200, "dynamic")
  if lurek.physics.isSleepingAllowed(world, body) then
    lurek.log.debug("body may sleep when idle", "phys")
  end
end

--@api-stub: lurek.physics.setSleepingAllowed
-- Sets whether a body is allowed to sleep (free-function variant)
do
  local world = lurek.physics.newWorld(0, 9.81)
  local player = lurek.physics.newBody(world, 100, 200, "dynamic")
  lurek.physics.setSleepingAllowed(world, player, false)
end

--@api-stub: lurek.physics.newRectangleShape
-- Creates a rectangle collision shape with the given dimensions
do
  local crate_shape = lurek.physics.newRectangleShape(64, 64)
  lurek.log.info("crate shape type=" .. crate_shape:getType(), "phys")
end

--@api-stub: lurek.physics.newCircleShape
-- Creates a circle collision shape with the given radius
do
  local ball_shape = lurek.physics.newCircleShape(16)
  lurek.log.info("ball radius=" .. ball_shape:getRadius(), "phys")
end

--@api-stub: lurek.physics.newEdgeShape
-- Creates an edge (line segment) collision shape between two local points
do
  local floor_shape = lurek.physics.newEdgeShape(0, 480, 800, 480)
  lurek.log.info("floor edge type=" .. floor_shape:getType(), "phys")
end

--@api-stub: lurek.physics.newPolygonShape
-- Creates a convex polygon collision shape from vertex coordinate pairs
do
  local triangle = lurek.physics.newPolygonShape(0, 0, 32, 0, 16, 28)
  lurek.log.info("triangle type=" .. triangle:getType(), "phys")
end

--@api-stub: lurek.physics.newChainShape
-- Creates a chain (polyline) collision shape
do
  local hill = lurek.physics.newChainShape(false, 0, 400, 100, 360, 200, 380, 300, 420)
  lurek.log.info("hill chain type=" .. hill:getType(), "phys")
end

--@api-stub: lurek.physics.attachShape
-- Attaches a previously created shape to a body, using the shape's stored material properties
do
  local world = lurek.physics.newWorld(0, 9.81)
  local car = lurek.physics.newBody(world, 200, 200, "dynamic")
  local roof = lurek.physics.newRectangleShape(64, 16)
  lurek.physics.attachShape(car, roof)
end

--@api-stub: lurek.physics.getCollisions
-- Returns all collision events from the last world step as {body_a, body_b} pairs
do
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    lurek.physics.step(world, dt)
    for _, c in ipairs(lurek.physics.getCollisions(world)) do
      lurek.log.debug("hit " .. c.body_a .. " vs " .. c.body_b, "phys")
    end
  end
end

--@api-stub: lurek.physics.debugDraw
-- Enables or disables automatic physics debug overlay rendering for the next frame
do
  lurek.physics.debugDraw(true)
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("f3") then lurek.physics.debugDraw(false) end
  end
end

--@api-stub: lurek.physics.drawDebugGpu
-- Queues a GPU-rendered physics debug visualization using the world's current body state
do
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.draw()
    lurek.physics.drawDebugGpu(world, { bodyColor = {0, 1, 0, 1}, lineWidth = 2.0 })
  end
end

--@api-stub: lurek.physics.newTerrain
-- Creates a destructible terrain grid linked to a physics world for automatic collider generation
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  terrain:flush()
end

--@api-stub: lurek.physics.newCellular
-- Creates a new cellular automaton simulation grid for particle-like physics (sand, water, fire)
do
  local sand = lurek.physics.newCellular(128, 64)
  sand:setCell(64, 0, lurek.physics.CELL_SAND)
  function lurek.process(dt) sand:step() end
end


-- World methods

--@api-stub: World:step
-- Performs the step operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
  end
end

--@api-stub: World:clear
-- Clears all items from this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 200, "dynamic")
  world:clear()
  lurek.log.info("world cleared, body count=" .. world:getBodyCount(), "scene")
end

--@api-stub: World:getGravity
-- Returns the gravity of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local gx, gy = world:getGravity()
  lurek.log.info("gravity=" .. gx .. "," .. gy, "phys")
end

--@api-stub: World:setGravity
-- Sets the gravity of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("g") then world:setGravity(0, -9.81) end
  end
end

--@api-stub: World:setMeter
-- Sets the meter of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:setMeter(64)
  lurek.log.info("ppm=" .. world:getMeter(), "phys")
end

--@api-stub: World:getMeter
-- Returns the meter of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local ppm = world:getMeter()
  lurek.log.debug("1 meter = " .. ppm .. " pixels", "phys")
end

--@api-stub: World:toPhysics
-- Performs the to physics operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local px = 128
  local meters = world:toPhysics(px)
  lurek.log.debug(px .. " px = " .. meters .. " m", "phys")
end

--@api-stub: World:toPixels
-- Performs the to pixels operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local pixels = world:toPixels(2.5)
  lurek.log.debug("2.5 m = " .. pixels .. " px", "phys")
end

--@api-stub: World:getBodyCount
-- Returns the number of body items in this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 200, "dynamic")
  if world:getBodyCount() < 1000 then world:newBody(150, 200, "dynamic") end
end

--@api-stub: World:getBodyIds
-- Returns the body ids of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(100, 200, "dynamic")
  for _, id in ipairs(world:getBodyIds()) do
    lurek.log.debug("body id=" .. id, "phys")
  end
end

--@api-stub: World:destroyBody
-- Destroys this world and releases all associated resources.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local enemy = world:newBody(300, 200, "dynamic")
  world:destroyBody(enemy:getId())
end

--@api-stub: World:newBody
-- Creates and returns a new body widget or object.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  crate:setMass(2.5)
  crate:setRestitution(0.3)
end

--@api-stub: World:fixtureCount
-- Performs the fixture count operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  local n = world:fixtureCount(body:getId())
  lurek.log.debug("body has " .. n .. " fixtures", "phys")
end

--@api-stub: World:jointCount
-- Performs the joint count operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  lurek.log.info("joints=" .. world:jointCount(), "phys")
end

--@api-stub: World:getJointIds
-- Returns the joint ids of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  for _, jid in ipairs(world:getJointIds()) do
    lurek.log.debug("joint id=" .. jid, "phys")
  end
end

--@api-stub: World:getJointBodies
-- Returns the joint bodies of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local a, b = world:getJointBodies(jid)
  lurek.log.debug("joint " .. jid .. " links " .. a .. " <-> " .. b, "phys")
end

--@api-stub: World:destroyJoint
-- Destroys this world and releases all associated resources.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  world:destroyJoint(jid)
end

--@api-stub: World:getJointType
-- Returns the joint type of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local kind = world:getJointType(jid)
  if kind == "revolute" then lurek.log.debug("hinge joint", "phys") end
end

--@api-stub: World:getJointMotorSpeed
-- Returns the joint motor speed of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local rpm = world:getJointMotorSpeed(jid)
  lurek.log.debug("motor speed=" .. rpm, "phys")
end

--@api-stub: World:getJointLimits
-- Returns the joint limits of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local lo, hi = world:getJointLimits(jid)
  lurek.log.debug("limits=[" .. lo .. ", " .. hi .. "]", "phys")
end

--@api-stub: World:getBodyAtPoint
-- Returns the body at point of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local hit = world:getBodyAtPoint(150, 200)
  if hit then lurek.log.debug("clicked body=" .. hit, "phys") end
end

--@api-stub: World:getCollisionEvents
-- Returns the collision events of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getCollisionEvents()) do
      lurek.log.debug("hit " .. e.bodyA .. " vs " .. e.bodyB, "phys")
    end
  end
end

--@api-stub: World:getBeginContactEvents
-- Returns the begin contact events of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getBeginContactEvents()) do
      lurek.log.debug("begin " .. e.bodyA .. "/" .. e.bodyB, "phys")
    end
  end
end

--@api-stub: World:getEndContactEvents
-- Returns the end contact events of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getEndContactEvents()) do
      lurek.log.debug("end " .. e.bodyA .. "/" .. e.bodyB, "phys")
    end
  end
end

--@api-stub: World:getContacts
-- Returns the contacts of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  for _, c in ipairs(world:getContacts()) do
    if c.isTouching then
      lurek.log.debug("contact n=" .. c.normalX .. "," .. c.normalY, "phys")
    end
  end
end

--@api-stub: World:getBodyContacts
-- Returns the body contacts of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  local touches = world:getBodyContacts(player:getId())
  lurek.log.debug("player contacts=" .. #touches, "phys")
end

--@api-stub: World:setBodyType
-- Sets the body type of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local door = world:newBody(200, 200, "static")
  world:setBodyType(door:getId(), "kinematic")
end

--@api-stub: World:getBodyType
-- Returns the body type of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if world:getBodyType(body:getId()) == "dynamic" then body:setMass(1.0) end
end

--@api-stub: World:setBeginContact
-- Sets the begin contact of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:setBeginContact(function(a, b)
    lurek.log.info("touch " .. a .. " <-> " .. b, "phys")
  end)
end

--@api-stub: World:clearBeginContact
-- Clears all begin contact items from this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:setBeginContact(function(a, b) end)
  world:clearBeginContact()
end

--@api-stub: World:setEndContact
-- Sets the end contact of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:setEndContact(function(a, b)
    lurek.log.debug("apart " .. a .. " / " .. b, "phys")
  end)
end

--@api-stub: World:clearEndContact
-- Clears all end contact items from this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:setEndContact(function(a, b) end)
  world:clearEndContact()
end

--@api-stub: World:getBodyData
-- Returns the body data of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  world:setBodyData(body:getId(), { kind = "enemy", hp = 30 })
  local data = world:getBodyData(body:getId())
  if data then lurek.log.debug("entity kind=" .. data.kind, "phys") end
end

--@api-stub: World:clearBodyData
-- Clears all body data items from this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  world:setBodyData(body:getId(), { name = "crate" })
  world:clearBodyData(body:getId())
end

--@api-stub: World:setBodyCCD
-- Sets the body ccd of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local bullet = world:newBody(100, 200, "dynamic")
  world:setBodyCCD(bullet:getId(), true)
end

--@api-stub: World:getBodyCCD
-- Returns the body ccd of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if not world:getBodyCCD(body:getId()) then world:setBodyCCD(body:getId(), true) end
end

--@api-stub: World:clearBodyOneWay
-- Clears all body one way items from this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local platform = world:newBody(200, 300, "static")
  world:clearBodyOneWay(platform:getId())
end

--@api-stub: World:getBodyOneWay
-- Returns the body one way of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local platform = world:newBody(200, 300, "static")
  local nx, ny = world:getBodyOneWay(platform:getId())
  if nx then lurek.log.debug("one-way n=" .. nx .. "," .. ny, "phys") end
end

--@api-stub: World:setJointBreakForce
-- Sets the joint break force of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  world:setJointBreakForce(jid, 5000.0)
end

--@api-stub: World:getJointBreakForce
-- Returns the joint break force of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b1 = world:newBody(0, 0, "static")
  local b2 = world:newBody(0, 100, "dynamic")
  local jid = world:addRevoluteJoint(b1:getId(), b2:getId(), 0, 50)
  local f = world:getJointBreakForce(jid)
  if f then lurek.log.debug("breaks at " .. f .. " N", "phys") end
end

--@api-stub: World:isBodySleeping
-- Returns true if this world body sleeping.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if not world:isBodySleeping(body:getId()) then
    lurek.log.debug("body active", "phys")
  end
end

--@api-stub: World:wakeUpBody
-- Performs the wake up body operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  world:wakeUpBody(body:getId())
  body:applyImpulse(0, -100)
end

--@api-stub: World:sleepBody
-- Performs the sleep body operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local rubble = world:newBody(100, 200, "dynamic")
  world:sleepBody(rubble:getId())
end

--@api-stub: World:setSolverIterations
-- Sets the solver iterations of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:setSolverIterations(12)
end

--@api-stub: World:getSolverIterations
-- Returns the solver iterations of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local iters = world:getSolverIterations()
  lurek.log.info("solver iterations=" .. iters, "phys")
end

--@api-stub: World:newBodies
-- Creates and returns a new bodies widget or object.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local ids = world:newBodies({
    { 100, 200, "dynamic" },
    { 132, 200, "dynamic" },
    { 164, 200, "dynamic" },
  })
  lurek.log.info("spawned " .. #ids .. " crates", "phys")
end

--@api-stub: World:addZone
-- Adds a zone to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local water = world:addZone(0, 400, 800, 200)
  water:setGravityDirectional(0, 2.0)
end

--@api-stub: World:getZoneEvents
-- Returns the zone events of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  function lurek.process(dt)
    world:step(dt)
    for _, e in ipairs(world:getZoneEvents()) do
      lurek.log.debug("zone " .. e.zone_id .. " " .. e.kind .. " body=" .. e.body_id, "phys")
    end
  end
end


-- Zone methods

--@api-stub: Zone:getId
-- Returns the id of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local zone = world:addZone(0, 0, 100, 100)
  lurek.log.info("water zone id=" .. zone:getId(), "phys")
end

--@api-stub: Zone:setEnabled
-- Sets whether this zone is enabled and accepts input.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local field = world:addZone(0, 0, 200, 200)
  field:setEnabled(false)
end

--@api-stub: Zone:setPriority
-- Sets the priority of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local wind = world:addZone(0, 0, 200, 200)
  wind:setPriority(10)
end

--@api-stub: Zone:setLayerMask
-- Sets the layer mask of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local slow = world:addZone(100, 100, 200, 200)
  slow:setLayerMask(0x02)
end

--@api-stub: Zone:setCircle
-- Sets the circle of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local well = world:addZone(0, 0, 1, 1)
  well:setCircle(400, 300, 120)
end

--@api-stub: Zone:setGravityDirectional
-- Sets the gravity directional of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local water = world:addZone(0, 400, 800, 200)
  water:setGravityDirectional(0, 2.0)
end

--@api-stub: Zone:setGravityZero
-- Sets the gravity zero of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local bubble = world:addZone(300, 100, 200, 200)
  bubble:setGravityZero()
end

--@api-stub: Zone:setLinearDampingOverride
-- Sets the linear damping override of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local glue = world:addZone(0, 0, 100, 100)
  glue:setLinearDampingOverride(5.0)
end

--@api-stub: Zone:destroy
-- Destroys this zone and releases all associated resources.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local zone = world:addZone(0, 0, 100, 100)
  zone:destroy()
end


-- Terrain methods

--@api-stub: Terrain:setCell
-- Sets the cell of this terrain.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:setCell(10, 5, true)
  terrain:flush()
end

--@api-stub: Terrain:getCell
-- Returns the cell of this terrain.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  if terrain:getCell(10, 5) then lurek.log.debug("solid cell", "terrain") end
end

--@api-stub: Terrain:fillAll
-- Performs the fill all operation on this terrain.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
end

--@api-stub: Terrain:flush
-- Flushes all pending output from this terrain immediately.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:setCell(5, 5, true)
  terrain:flush()
end

--@api-stub: Terrain:isDirty
-- Returns true if this terrain dirty.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  if terrain:isDirty() then terrain:flush() end
end

--@api-stub: Terrain:collapseColumns
-- Collapses this terrain to hide its children or content.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  local fell = terrain:collapseColumns()
  lurek.log.info("collapsed " .. fell .. " cells", "terrain")
  terrain:flush()
end

--@api-stub: Terrain:solidPositions
-- Performs the solid positions operation on this terrain.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  terrain:fillAll(true)
  local positions = terrain:solidPositions()
  lurek.log.debug("solid cells=" .. #positions, "terrain")
end

--@api-stub: Terrain:toBytes
-- Performs the to bytes operation on this terrain.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  local bytes = terrain:toBytes()
  lurek.log.info("terrain blob=" .. #bytes .. " bytes", "save")
end

--@api-stub: Terrain:loadFromBytes
-- Loads from bytes into this terrain.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 32, 8.0, world)
  local snapshot = terrain:toBytes()
  terrain:loadFromBytes(snapshot)
  terrain:flush()
end


-- Cellular methods

--@api-stub: Cellular:setCell
-- Sets the cell of this cellular.
do
  local sand = lurek.physics.newCellular(128, 64)
  sand:setCell(64, 0, lurek.physics.CELL_SAND)
  sand:setCell(65, 0, lurek.physics.CELL_WATER)
end

--@api-stub: Cellular:getCell
-- Returns the cell of this cellular.
do
  local sand = lurek.physics.newCellular(128, 64)
  if sand:getCell(10, 10) == lurek.physics.CELL_AIR then
    sand:setCell(10, 10, lurek.physics.CELL_ROCK)
  end
end

--@api-stub: Cellular:step
-- Performs the step operation on this cellular.
do
  local sand = lurek.physics.newCellular(128, 64)
  function lurek.process(dt)
    sand:step()
  end
end

--@api-stub: Cellular:stepN
-- Performs the step n operation on this cellular.
do
  local sand = lurek.physics.newCellular(128, 64)
  sand:stepN(30)
end

--@api-stub: Cellular:toImageData
-- Performs the to image data operation on this cellular.
do
  local sand = lurek.physics.newCellular(128, 64)
  local rgba = sand:toImageData()
  lurek.log.debug("cellular bytes=" .. #rgba, "cell")
end

--@api-stub: Cellular:countCells
-- Performs the count cells operation on this cellular.
do
  local sand = lurek.physics.newCellular(128, 64)
  local water = sand:countCells(lurek.physics.CELL_WATER)
  lurek.log.debug("water cells=" .. water, "cell")
end

--@api-stub: Cellular:findCells
-- Finds and returns the cells in this cellular by name or id.
do
  local sand = lurek.physics.newCellular(128, 64)
  for _, p in ipairs(sand:findCells(lurek.physics.CELL_FIRE)) do
    lurek.log.debug("fire at " .. p.x .. "," .. p.y, "cell")
  end
end

--@api-stub: Cellular:toBytes
-- Performs the to bytes operation on this cellular.
do
  local sand = lurek.physics.newCellular(128, 64)
  local blob = sand:toBytes()
  lurek.log.info("cellular blob=" .. #blob .. " bytes", "save")
end

--@api-stub: Cellular:loadFromBytes
-- Loads from bytes into this cellular.
do
  local sand = lurek.physics.newCellular(128, 64)
  local blob = sand:toBytes()
  local ok = sand:loadFromBytes(blob)
  lurek.log.info("cellular reload ok=" .. tostring(ok), "save")
end


-- Body methods

--@api-stub: Body:getId
-- Returns the id of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  lurek.log.debug("crate id=" .. crate:getId(), "phys")
end

--@api-stub: Body:getPosition
-- Returns the position of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  local x, y = crate:getPosition()
  lurek.log.debug("crate at " .. x .. "," .. y, "phys")
end

--@api-stub: Body:setPosition
-- Sets the position of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  player:setPosition(400, 300)
end

--@api-stub: Body:getX
-- Returns the x of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local enemy = world:newBody(900, 200, "dynamic")
  if enemy:getX() > 800 then enemy:destroy() end
end

--@api-stub: Body:getY
-- Returns the y of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  if player:getY() > 1000 then player:setPosition(100, 200) end
end

--@api-stub: Body:getVelocity
-- Returns the velocity of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  local vx, vy = body:getVelocity()
  lurek.log.debug("v=" .. vx .. "," .. vy, "phys")
end

--@api-stub: Body:setVelocity
-- Sets the velocity of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  function lurek.process(dt)
    player:setVelocity(150, 0)
  end
end

--@api-stub: Body:getAngle
-- Returns the angle of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  local rad = crate:getAngle()
  lurek.log.debug("angle=" .. rad .. " rad", "phys")
end

--@api-stub: Body:setAngle
-- Sets the angle of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local sign = world:newBody(200, 200, "static")
  sign:setAngle(math.pi / 4)
end

--@api-stub: Body:getAngularVelocity
-- Returns the angular velocity of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local wheel = world:newBody(100, 200, "dynamic")
  if math.abs(wheel:getAngularVelocity()) > 30 then
    wheel:applyTorque(-5)
  end
end

--@api-stub: Body:setAngularVelocity
-- Sets the angular velocity of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local turret = world:newBody(200, 200, "kinematic")
  turret:setAngularVelocity(1.5)
end

--@api-stub: Body:getMass
-- Returns the mass of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  lurek.log.debug("crate mass=" .. crate:getMass() .. " kg", "phys")
end

--@api-stub: Body:setMass
-- Sets the mass of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local heavy = world:newBody(100, 200, "dynamic")
  heavy:setMass(50.0)
end

--@api-stub: Body:getType
-- Returns the type of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if body:getType() == "dynamic" then body:applyImpulse(0, -50) end
end

--@api-stub: Body:setType
-- Sets the type of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local wall = world:newBody(200, 200, "static")
  wall:setType("dynamic")
end

--@api-stub: Body:getWidth
-- Returns the width of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("body width=" .. body:getWidth(), "phys")
end

--@api-stub: Body:getHeight
-- Returns the height of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("body height=" .. body:getHeight(), "phys")
end

--@api-stub: Body:getFriction
-- Returns the friction of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  if crate:getFriction() < 0.5 then crate:setFriction(0.7) end
end

--@api-stub: Body:setFriction
-- Sets the friction of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local ice = world:newBody(100, 200, "dynamic")
  ice:setFriction(0.05)
end

--@api-stub: Body:getRestitution
-- Returns the restitution of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local ball = world:newBody(100, 200, "dynamic")
  lurek.log.debug("ball bounce=" .. ball:getRestitution(), "phys")
end

--@api-stub: Body:setRestitution
-- Sets the restitution of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local ball = world:newBody(100, 200, "dynamic")
  ball:setRestitution(0.8)
end

--@api-stub: Body:getLayer
-- Returns the layer of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local pickup = world:newBody(100, 200, "dynamic")
  lurek.log.debug("layer=" .. pickup:getLayer(), "phys")
end

--@api-stub: Body:setLayer
-- Sets the layer of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local pickup = world:newBody(100, 200, "dynamic")
  pickup:setLayer(0x04)
end

--@api-stub: Body:getMask
-- Returns the mask of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("mask=" .. body:getMask(), "phys")
end

--@api-stub: Body:setMask
-- Sets the mask of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local ghost = world:newBody(100, 200, "dynamic")
  ghost:setMask(0x01)
end

--@api-stub: Body:applyImpulse
-- Applies impulse to this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("space") then player:applyImpulse(0, -300) end
  end
end

--@api-stub: Body:applyForce
-- Applies force to this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local rocket = world:newBody(100, 200, "dynamic")
  function lurek.process(dt)
    rocket:applyForce(0, -200)
  end
end

--@api-stub: Body:applyTorque
-- Applies torque to this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local wheel = world:newBody(100, 200, "dynamic")
  wheel:applyTorque(50.0)
end

--@api-stub: Body:applyAngularImpulse
-- Applies angular impulse to this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local top = world:newBody(100, 200, "dynamic")
  top:applyAngularImpulse(2.5)
end

--@api-stub: Body:getGravityScale
-- Returns the gravity scale of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("g-scale=" .. body:getGravityScale(), "phys")
end

--@api-stub: Body:setGravityScale
-- Sets the gravity scale of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local balloon = world:newBody(100, 200, "dynamic")
  balloon:setGravityScale(-0.5)
end

--@api-stub: Body:isFixedRotation
-- Returns true if this body fixed rotation.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  if not player:isFixedRotation() then player:setFixedRotation(true) end
end

--@api-stub: Body:setFixedRotation
-- Sets the fixed rotation of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  player:setFixedRotation(true)
end

--@api-stub: Body:getLinearDamping
-- Returns the linear damping of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  lurek.log.debug("damping=" .. body:getLinearDamping(), "phys")
end

--@api-stub: Body:setLinearDamping
-- Sets the linear damping of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local fish = world:newBody(100, 200, "dynamic")
  fish:setLinearDamping(2.0)
end

--@api-stub: Body:getAngularDamping
-- Returns the angular damping of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local top = world:newBody(100, 200, "dynamic")
  lurek.log.debug("ang damping=" .. top:getAngularDamping(), "phys")
end

--@api-stub: Body:setAngularDamping
-- Sets the angular damping of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local crate = world:newBody(100, 200, "dynamic")
  crate:setAngularDamping(0.5)
end

--@api-stub: Body:isBullet
-- Returns true if this body bullet.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local proj = world:newBody(100, 200, "dynamic")
  if proj:isBullet() then lurek.log.debug("CCD on", "phys") end
end

--@api-stub: Body:setBullet
-- Sets the bullet of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local arrow = world:newBody(100, 200, "dynamic")
  arrow:setBullet(true)
end

--@api-stub: Body:isSleepingAllowed
-- Returns true if this body sleeping allowed.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if body:isSleepingAllowed() then body:setSleepingAllowed(false) end
end

--@api-stub: Body:setSleepingAllowed
-- Sets the sleeping allowed of this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local player = world:newBody(100, 200, "dynamic")
  player:setSleepingAllowed(false)
end

--@api-stub: Body:destroy
-- Destroys this body and releases all associated resources.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local enemy = world:newBody(100, 200, "dynamic")
  enemy:destroy()
end

--@api-stub: Body:isSleeping
-- Returns true if this body sleeping.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  if not body:isSleeping() then lurek.log.debug("active", "phys") end
end

--@api-stub: Body:wakeUp
-- Performs the wake up operation on this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local body = world:newBody(100, 200, "dynamic")
  body:wakeUp()
  body:applyImpulse(0, -100)
end

--@api-stub: Body:sleep
-- Performs the sleep operation on this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local rubble = world:newBody(100, 200, "dynamic")
  rubble:sleep()
end


-- PhysicsShape methods

--@api-stub: PhysicsShape:getType
-- Returns the type of this physics shape.
do
  local shape = lurek.physics.newCircleShape(16)
  if shape:getType() == "circle" then
    lurek.log.debug("ball-shape r=" .. shape:getRadius(), "phys")
  end
end

--@api-stub: PhysicsShape:getRadius
-- Returns the radius of this physics shape.
do
  local ball = lurek.physics.newCircleShape(16)
  lurek.log.debug("radius=" .. ball:getRadius(), "phys")
end

--@api-stub: PhysicsShape:getBoundingBox
-- Returns the bounding box of this physics shape.
do
  local crate_shape = lurek.physics.newRectangleShape(64, 32)
  local x1, y1, x2, y2 = crate_shape:getBoundingBox()
  lurek.log.debug("aabb " .. x1 .. "," .. y1 .. "->" .. x2 .. "," .. y2, "phys")
end

--@api-stub: PhysicsShape:setDensity
-- Sets the density of this physics shape.
do
  local shape = lurek.physics.newRectangleShape(32, 32)
  shape:setDensity(2.0)
end

--@api-stub: PhysicsShape:setFriction
-- Sets the friction of this physics shape.
do
  local shape = lurek.physics.newRectangleShape(32, 32)
  shape:setFriction(0.7)
end

--@api-stub: PhysicsShape:setRestitution
-- Sets the restitution of this physics shape.
do
  local ball = lurek.physics.newCircleShape(16)
  ball:setRestitution(0.85)
end

--@api-stub: PhysicsShape:setSensor
-- Sets the sensor of this physics shape.
do
  local trigger = lurek.physics.newRectangleShape(64, 64)
  trigger:setSensor(true)
end

--@api-stub: PhysicsShape:destroy
-- Destroys this physics shape and releases all associated resources.
do
  local shape = lurek.physics.newRectangleShape(32, 32)
  shape:destroy()
  shape = nil --[[@type any]]
end

--@api-stub: lurek.physics.testAABB
-- Tests whether two axis-aligned bounding boxes overlap
do
  if lurek.physics.testAABB then
    local hit = lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 20, 20)
    lurek.log.debug("AABB overlap=" .. tostring(hit), "physics")
  end
end

--@api-stub: lurek.physics.testCircles
-- Tests whether two circles overlap
do
  if lurek.physics.testCircles then
    local hit = lurek.physics.testCircles(0, 0, 5, 3, 3, 5)
    lurek.log.debug("circles overlap=" .. tostring(hit), "physics")
  end
end

--@api-stub: lurek.physics.testCircleAABB
-- Tests whether a circle overlaps an AABB
do
  if lurek.physics.testCircleAABB then
    local hit = lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10)
    lurek.log.debug("circle-AABB overlap=" .. tostring(hit), "physics")
  end
end

--@api-stub: lurek.physics.testPoint
-- Tests whether a point lies inside an AABB
do
  if lurek.physics.testPoint then
    local hit = lurek.physics.testPoint(5, 5, 0, 0, 10, 10)
    lurek.log.debug("point-in-AABB=" .. tostring(hit), "physics")
  end
end

--@api-stub: World:addDistanceJoint
-- Adds a distance joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(200, 100, "dynamic")
  local jid = world:addDistanceJoint(a:getId(), b:getId(), 100, 100, 200, 100, 100)
  lurek.log.info("distance joint: " .. jid, "physics")
end

--@api-stub: World:addFixture
-- Adds a fixture to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local fid = world:addFixture(b:getId(), "circle", 1.0, 0.4, 0.3, false, 16.0)
  lurek.log.info("fixture id: " .. fid, "physics")
end

--@api-stub: World:addFrictionJoint
-- Adds a friction joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(100, 100, "static")
  local jid = world:addFrictionJoint(a:getId(), b:getId(), 100, 100, 50, 10)
  lurek.log.info("friction joint: " .. jid, "physics")
end

--@api-stub: World:addGearJoint
-- Adds a gear joint to this world.
do
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
-- Adds a motor joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(200, 200, "dynamic")
  local jid = world:addMotorJoint(a:getId(), b:getId(), 0.3)
  lurek.log.info("motor joint: " .. jid, "physics")
end

--@api-stub: World:addMouseJoint
-- Adds a mouse joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local jid = world:addMouseJoint(b:getId(), 200, 200, 1000)
  lurek.log.info("mouse joint: " .. jid, "physics")
end

--@api-stub: World:addPrismaticJoint
-- Adds a prismatic joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 300, "static")
  local b = world:newBody(100, 200, "dynamic")
  local jid = world:addPrismaticJoint(a:getId(), b:getId(), 100, 300, 0, -1)
  lurek.log.info("prismatic joint: " .. jid, "physics")
end

--@api-stub: World:addPulleyJoint
-- Adds a pulley joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "dynamic")
  local b = world:newBody(300, 200, "dynamic")
  local jid = world:addPulleyJoint(a:getId(), b:getId(), 100, 100)
  lurek.log.info("pulley joint: " .. jid, "physics")
end

--@api-stub: World:addRevoluteJoint
-- Adds a revolute joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local door = world:newBody(200, 200, "dynamic")
  local wall  = world:newBody(200, 200, "static")
  local jid = world:addRevoluteJoint(wall:getId(), door:getId(), 200, 200)
  lurek.log.info("revolute joint: " .. jid, "physics")
end

--@api-stub: World:addRopeJoint
-- Adds a rope joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 100, "dynamic")
  local b = world:newBody(100, 200, "dynamic")
  local jid = world:addRopeJoint(a:getId(), b:getId(), 100, 100, 100, 200, 120)
  lurek.log.info("rope joint: " .. jid, "physics")
end

--@api-stub: World:addWeldJoint
-- Adds a weld joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(150, 200, "dynamic")
  local b = world:newBody(170, 200, "dynamic")
  local jid = world:addWeldJoint(a:getId(), b:getId(), 160, 200)
  lurek.log.info("weld joint: " .. jid, "physics")
end

--@api-stub: World:addWheelJoint
-- Adds a wheel joint to this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local chassis = world:newBody(200, 200, "dynamic")
  local wheel   = world:newBody(200, 240, "dynamic")
  local jid = world:addWheelJoint(chassis:getId(), wheel:getId(), 200, 240, 0, -1)
  lurek.log.info("wheel joint: " .. jid, "physics")
end

--@api-stub: Body:applyForceAtPoint
-- Applies force at point to this body.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  b:applyForceAtPoint(100, 0, 220, 200)
  lurek.log.info("force at point applied", "physics")
end

--@api-stub: World:drawDebug
-- Draws or renders this world to the current render target.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:newBody(200, 200, "static")
  local debug_img = lurek.image.newImageData(400, 400)
  function lurek.draw()
    world:drawDebug(debug_img)
  end
  lurek.log.info("drawDebug hooked", "physics")
end

--@api-stub: Terrain:fillCircle
-- Performs the fill circle operation on this terrain.
do
  local _world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 64, 8, _world)
  terrain:fillAll(true)
  terrain:fillCircle(32, 32, 10, false)
  terrain:flush()
  lurek.log.info("terrain crater dug", "physics")
end

--@api-stub: Cellular:fillCircle
-- Performs the fill circle operation on this cellular.
do
  local ca = lurek.physics.newCellular(64, 64)
  ca:fillCircle(32, 32, 20, 1)
  lurek.log.info("cellular circle filled", "physics")
end

--@api-stub: Terrain:fillRect
-- Performs the fill rect operation on this terrain.
do
  local _world = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(64, 64, 8, _world)
  terrain:fillRect(10, 10, 40, 40, true)
  terrain:flush()
  lurek.log.info("terrain rect filled", "physics")
end

--@api-stub: Cellular:fillRect
-- Performs the fill rect operation on this cellular.
do
  local ca = lurek.physics.newCellular(32, 32)
  ca:fillRect(4, 4, 28, 28, 1)
  lurek.log.info("cellular rect filled", "physics")
end

--@api-stub: World:newChainBody
-- Creates and returns a new chain body widget or object.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local verts = {0,400, 200,380, 400,400, 600,390, 800,400}
  local b = world:newChainBody(0, 0, verts, false, "static")
  lurek.log.info("chain body: " .. b:getId(), "physics")
end

--@api-stub: World:newCircleBody
-- Creates and returns a new circle body widget or object.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newCircleBody(300, 200, 20, "dynamic")
  lurek.log.info("circle body: " .. b:getId(), "physics")
end

--@api-stub: World:newEdgeBody
-- Creates and returns a new edge body widget or object.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newEdgeBody(0, 0, 0, 400, 800, 400, "static")
  lurek.log.info("edge body: " .. b:getId(), "physics")
end

--@api-stub: World:newPolygonBody
-- Creates and returns a new polygon body widget or object.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local verts = {-20,-10, 20,-10, 20,10, -20,10}
  local b = world:newPolygonBody(300, 200, verts, "dynamic")
  lurek.log.info("polygon body: " .. b:getId(), "physics")
end

--@api-stub: World:queryAABB
-- Performs the query aabb operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(100, 100, 20, "static")
  local hits = world:queryAABB(80, 80, 130, 130)
  lurek.log.info("AABB hits: " .. #hits, "physics")
end

--@api-stub: World:raycast
-- Performs the raycast operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(200, 200, 30, "static")
  local id, nx, ny, frac = world:raycast(0, 200, 400, 200)
  lurek.log.info("raycast hit: " .. tostring(id), "physics")
end

--@api-stub: World:raycastAll
-- Performs the raycast all operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(100, 200, 20, "static")
  world:newCircleBody(300, 200, 20, "static")
  local hits = world:raycastAll(0, 200, 1, 0, 400)
  lurek.log.info("all hits: " .. #hits, "physics")
end

--@api-stub: World:raycastClosest
-- Performs the raycast closest operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:newCircleBody(150, 200, 20, "static")
  local hit = world:raycastClosest(0, 200, 1, 0, 400)
  lurek.log.info("closest hit: " .. tostring(hit and hit.id), "physics")
end

--@api-stub: Zone:setAngularDampingOverride
-- Sets the angular damping override of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local z = world:addZone(100, 100, 300, 300)
  z:setAngularDampingOverride(5.0)
  lurek.log.info("zone angular damping set", "physics")
end

--@api-stub: World:setBodyData
-- Sets the body data of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  world:setBodyData(b:getId(), {entityId=42, type="player"})
  lurek.log.info("body data set", "physics")
end

--@api-stub: World:setBodyOneWay
-- Sets the body one way of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local platform = world:newBody(400, 300, "static")
  world:setBodyOneWay(platform:getId(), 0, -1)
  lurek.log.info("one-way platform set", "physics")
end

--@api-stub: World:setFixtureFriction
-- Sets the fixture friction of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local fid = world:addFixture(b:getId(), "rectangle", 1.0, 0.5, 0.0, false, 32.0, 32.0)
  world:setFixtureFriction(b:getId(), fid, 0.1)
  lurek.log.info("fixture friction set", "physics")
end

--@api-stub: World:setFixtureRestitution
-- Sets the fixture restitution of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "dynamic")
  local fid = world:addFixture(b:getId(), "circle", 1.0, 0.5, 0.8, false, 16.0)
  world:setFixtureRestitution(b:getId(), fid, 0.8)
  lurek.log.info("restitution set", "physics")
end

--@api-stub: World:setFixtureSensor
-- Sets the fixture sensor of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(200, 200, "static")
  local fid = world:addFixture(b:getId(), "circle", 0.0, 0.0, 0.0, true, 40.0)
  world:setFixtureSensor(b:getId(), fid, true)
  lurek.log.info("sensor fixture set", "physics")
end

--@api-stub: Zone:setGravityPoint
-- Sets the gravity point of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local z = world:addZone(0, 0, 800, 600)
  z:setGravityPoint(400, 300, 500)
  lurek.log.info("gravity point set", "physics")
end

--@api-stub: Zone:setGravityRepulsor
-- Sets the gravity repulsor of this zone.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local z = world:addZone(200, 200, 600, 400)
  z:setGravityRepulsor(400, 300, 300)
  lurek.log.info("gravity repulsor set", "physics")
end

--@api-stub: World:setJointLimits
-- Sets the joint limits of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "static")
  local b = world:newBody(100, 100, "dynamic")
  local jid = world:addRevoluteJoint(a:getId(), b:getId(), 100, 200)
  world:setJointLimits(jid, -math.pi/4, math.pi/4)
  lurek.log.info("joint limits set", "physics")
end

--@api-stub: World:setJointLimitsEnabled
-- Sets whether this world is enabled and accepts input.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local a = world:newBody(100, 200, "static")
  local b = world:newBody(100, 100, "dynamic")
  local jid = world:addRevoluteJoint(a:getId(), b:getId(), 100, 200)
  world:setJointLimitsEnabled(jid, true)
  lurek.log.info("joint limits enabled", "physics")
end

--@api-stub: World:setJointMotorSpeed
-- Sets the joint motor speed of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local axle = world:newBody(200, 200, "static")
  local wheel = world:newBody(200, 240, "dynamic")
  local jid = world:addRevoluteJoint(axle:getId(), wheel:getId(), 200, 220)
  world:setJointMotorSpeed(jid, 2.0)
  lurek.log.info("motor speed: 2.0 rad/s", "physics")
end

--@api-stub: World:setMouseJointTarget
-- Sets the mouse joint target of this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  local b = world:newBody(300, 200, "dynamic")
  local jid = world:addMouseJoint(b:getId(), 300, 200, 2000)
  world:setMouseJointTarget(jid, 350, 250)
  lurek.log.info("mouse joint target updated", "physics")
end

--@api-stub: Terrain:spawnDebris
-- Performs the spawn debris operation on this terrain.
do
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
-- Performs the step fixed operation on this world.
do
  local world = lurek.physics.newWorld(0, 9.81)
  world:stepFixed(1/60, 6, 2)
  lurek.log.info("fixed step done", "physics")
end

--@api-stub: Terrain:toImageData
-- Performs the to image data operation on this terrain.
do
  local _w = lurek.physics.newWorld(0, 9.81)
  local terrain = lurek.physics.newTerrain(32, 32, 8, _w)
  terrain:fillAll(true)
  terrain:fillCircle(16, 16, 8, false)
  terrain:flush()
  local bytes = terrain:toImageData(255, 255, 255, 0, 0, 0)
  lurek.log.info("terrain image: " .. #bytes .. " bytes", "physics")
end

--@api-stub: Cellular:toImageDataRegion
-- Performs the to image data region operation on this cellular.
do
  local ca = lurek.physics.newCellular(64, 64)
  ca:fillRect(0, 0, 63, 63, 1)
  local img = ca:toImageDataRegion(10, 10, 40, 40)
  lurek.log.info("region img: " .. #img .. " bytes", "physics")
end

-- -----------------------------------------------------------------------------
-- Zone methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LBody methods
-- -----------------------------------------------------------------------------

--@api-stub: LBody:type
-- Returns the type name of this object ("LBody")
do
  local w = lurek.physics.newWorld(0, 9.81)
  local body_obj = w:newBody(0, 0, "dynamic")
  local t = body_obj:type()
  lurek.log.info("LBody:type = " .. t, "physics")
end
--@api-stub: LBody:typeOf
-- Checks if this object is of a given type name
do
  local w2 = lurek.physics.newWorld(0, 9.81)
  local body_obj2 = w2:newBody(0, 0, "dynamic")
  lurek.log.info("is LBody: " .. tostring(body_obj2 and body_obj2:typeOf("LBody") or false), "physics")
  lurek.log.info("is wrong: " .. tostring(body_obj2 and body_obj2:typeOf("Unknown") or false), "physics")
end
--@api-stub: LCellular:type
-- Returns the type name of this object ("LCellular")
do
  local cellular_obj = lurek.physics.newCellular(32, 32)
  local t = cellular_obj:type()
  lurek.log.info("LCellular:type = " .. t, "physics")
end
--@api-stub: LCellular:typeOf
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
--@api-stub: LTerrain:type
-- Returns the type name of this object ("LTerrain")
do
  local _tw = lurek.physics.newWorld(0, 9.81)
  local terrain_obj = lurek.physics.newTerrain(32, 32, 1.0, _tw)
  local t = terrain_obj:type()
  lurek.log.info("LTerrain:type = " .. t, "physics")
end
--@api-stub: LTerrain:typeOf
-- Checks if this object is of a given type name
do
  local _tw2 = lurek.physics.newWorld(0, 9.81)
  local terrain_obj = lurek.physics.newTerrain(32, 32, 1.0, _tw2)
  lurek.log.info("is LTerrain: " .. tostring(terrain_obj:typeOf("LTerrain")), "physics")
  lurek.log.info("is wrong: " .. tostring(terrain_obj:typeOf("Unknown")), "physics")
end
--@api-stub: LWorld:type
-- Returns the type name of this object ("LWorld")
do
  local world_obj = lurek.physics.newWorld(0, 9.81)
  local t = world_obj:type()
  lurek.log.info("LWorld:type = " .. t, "physics")
end
--@api-stub: LWorld:typeOf
-- Checks if this object is of a given type name
do
  local world_obj = lurek.physics.newWorld(0, 9.81)
  lurek.log.info("is LWorld: " .. tostring(world_obj:typeOf("LWorld")), "physics")
  lurek.log.info("is wrong: " .. tostring(world_obj:typeOf("Unknown")), "physics")
end
--@api-stub: LZone:type
-- Returns the type name of this object ("LZone")
do
  local world = lurek.physics.newWorld(0, 9.81)
    local zone = world:addZone(0, 0, 100, 100)
  local t = world:type()
  lurek.log.info("LZone:type = " .. t, "physics")
end
--@api-stub: LZone:typeOf
-- Checks if this object is of a given type name
do
  local world = lurek.physics.newWorld(0, 9.81)
    local zone = world:addZone(0, 0, 100, 100)
  lurek.log.info("is LZone: " .. tostring(world:typeOf("LZone")), "physics")
  lurek.log.info("is wrong: " .. tostring(world:typeOf("Unknown")), "physics")
end

--@api-stub: block
-- Performs the block operation on this .
do
  lurek.log.info("block below with a real scenario. called", "example")
end


