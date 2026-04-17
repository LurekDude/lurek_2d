-- content/examples/physics.lua
-- Lurek2D lurek.physics API Reference
-- Run with: cargo run -- content/examples/physics
--
-- Scenario: A 2D platformer with rigid body physics — a player character,
-- platforms, projectiles, destructible terrain, cellular automata for cave
-- generation, gravity zones, joints, and collision event handling.

print("=== lurek.physics — 2D Physics Simulation ===\n")

-- =============================================================================
-- World Creation & Configuration
-- =============================================================================

--@api-stub: lurek.physics.newWorld
-- Create a physics world with gravity pointing down.
local world = lurek.physics.newWorld(0, 9.81)
print("world created with gravity (0, 9.81)")

-- =============================================================================
-- World Methods — simulation control
-- =============================================================================

--@api-stub: World:setGravity
world:setGravity(0, 20.0)

--@api-stub: World:getGravity
local gx, gy = world:getGravity()
print("gravity: " .. gx .. ", " .. gy)

--@api-stub: World:setMeter
-- Set the pixels-per-meter scale (default 64).
world:setMeter(64)

--@api-stub: World:getMeter
print("meter scale: " .. world:getMeter() .. " px/m")

--@api-stub: World:toPhysics
local px, py = world:toPhysics(320, 480)
print("pixel (320,480) = physics (" .. px .. "," .. py .. ")")

--@api-stub: World:toPixels
local sx, sy = world:toPixels(5, 7.5)
print("physics (5,7.5) = pixel (" .. sx .. "," .. sy .. ")")

-- =============================================================================
-- Body Creation & Management
-- =============================================================================

--@api-stub: World:newBody
-- Dynamic body for the player character.
local player_body = world:newBody("dynamic", 200, 100)

-- Static platform.
local platform = world:newBody("static", 400, 500)

-- Kinematic moving platform.
local elevator = world:newBody("kinematic", 600, 400)

--@api-stub: lurek.physics.newBody
-- Alternative: create a body via module function.
local crate = lurek.physics.newBody(world, "dynamic", 300, 200)

--@api-stub: lurek.physics.getBody
local fetched = lurek.physics.getBody(world, 1)
print("body 1: " .. tostring(fetched))

--@api-stub: World:getBodyCount
print("bodies: " .. world:getBodyCount())

--@api-stub: World:getBodyIds
local ids = world:getBodyIds()
print("body IDs: " .. #ids)

-- =============================================================================
-- Body Properties
-- =============================================================================

--@api-stub: Body:getId
print("player ID: " .. player_body:getId())

--@api-stub: Body:getPosition
local bx, by = player_body:getPosition()
print("player pos: " .. bx .. "," .. by)

--@api-stub: Body:setPosition
player_body:setPosition(200, 100)

--@api-stub: Body:getX
print("x: " .. player_body:getX())

--@api-stub: Body:getY
print("y: " .. player_body:getY())

--@api-stub: Body:getVelocity
local vx, vy = player_body:getVelocity()
print("velocity: " .. vx .. "," .. vy)

--@api-stub: Body:setVelocity
player_body:setVelocity(100, -200)

--@api-stub: lurek.physics.setBodyVelocity
lurek.physics.setBodyVelocity(world, player_body:getId(), 50, 0)

--@api-stub: Body:getAngle
print("angle: " .. player_body:getAngle())

--@api-stub: Body:setAngle
player_body:setAngle(0)

--@api-stub: Body:getAngularVelocity
print("angular vel: " .. player_body:getAngularVelocity())

--@api-stub: Body:setAngularVelocity
player_body:setAngularVelocity(0)

--@api-stub: Body:getMass
print("mass: " .. player_body:getMass())

--@api-stub: Body:setMass
player_body:setMass(1.5)

--@api-stub: Body:getType
print("type: " .. player_body:getType())

--@api-stub: Body:setType
player_body:setType("dynamic")

--@api-stub: Body:getWidth
print("width: " .. player_body:getWidth())

--@api-stub: Body:getHeight
print("height: " .. player_body:getHeight())

-- =============================================================================
-- Body Material Properties
-- =============================================================================

--@api-stub: Body:getFriction
print("friction: " .. player_body:getFriction())

--@api-stub: Body:setFriction
player_body:setFriction(0.3)

--@api-stub: Body:getRestitution
print("bounce: " .. player_body:getRestitution())

--@api-stub: Body:setRestitution
player_body:setRestitution(0.1)

-- =============================================================================
-- Collision Layers & Masks
-- =============================================================================

--@api-stub: Body:getLayer
print("layer: " .. player_body:getLayer())

--@api-stub: Body:setLayer
player_body:setLayer(1)

--@api-stub: Body:getMask
print("mask: " .. player_body:getMask())

--@api-stub: Body:setMask
player_body:setMask(0xFFFF)

-- =============================================================================
-- Forces & Impulses
-- =============================================================================

--@api-stub: Body:applyImpulse
-- Jump: apply upward impulse.
player_body:applyImpulse(0, -500)

--@api-stub: Body:applyForce
-- Wind pushes player right.
player_body:applyForce(100, 0)

--@api-stub: Body:applyTorque
player_body:applyTorque(10)

--@api-stub: Body:applyAngularImpulse
player_body:applyAngularImpulse(5)

-- =============================================================================
-- Body Advanced Properties
-- =============================================================================

--@api-stub: Body:getGravityScale
print("gravity scale: " .. player_body:getGravityScale())

--@api-stub: Body:setGravityScale
player_body:setGravityScale(1.0)

--@api-stub: Body:isFixedRotation
print("fixed rotation: " .. tostring(player_body:isFixedRotation()))

--@api-stub: Body:setFixedRotation
player_body:setFixedRotation(true)

--@api-stub: Body:getLinearDamping
print("linear damping: " .. player_body:getLinearDamping())

--@api-stub: Body:setLinearDamping
player_body:setLinearDamping(0.1)

--@api-stub: Body:getAngularDamping
print("angular damping: " .. player_body:getAngularDamping())

--@api-stub: Body:setAngularDamping
player_body:setAngularDamping(0.05)

--@api-stub: Body:isBullet
print("CCD: " .. tostring(player_body:isBullet()))

--@api-stub: Body:setBullet
-- Enable continuous collision detection for fast projectiles.
player_body:setBullet(false)

-- =============================================================================
-- Body Sleep State
-- =============================================================================

--@api-stub: Body:isSleepingAllowed
print("sleeping allowed: " .. tostring(player_body:isSleepingAllowed()))

--@api-stub: Body:setSleepingAllowed
player_body:setSleepingAllowed(true)

--@api-stub: Body:isSleeping
print("sleeping: " .. tostring(player_body:isSleeping()))

--@api-stub: Body:wakeUp
player_body:wakeUp()

--@api-stub: Body:sleep
player_body:sleep()

--@api-stub: Body:destroy
-- crate:destroy()  -- commented: still needed

-- =============================================================================
-- World Body Management
-- =============================================================================

--@api-stub: World:setBodyType
world:setBodyType(player_body:getId(), "dynamic")

--@api-stub: World:getBodyType
print("world body type: " .. world:getBodyType(player_body:getId()))

--@api-stub: World:setBodyData
world:setBodyData(player_body:getId(), {name = "player", hp = 100})

--@api-stub: World:getBodyData
local bdata = world:getBodyData(player_body:getId())
print("body data: " .. tostring(bdata))

--@api-stub: World:clearBodyData
world:clearBodyData(player_body:getId())

--@api-stub: World:setBodyCCD
world:setBodyCCD(player_body:getId(), false)

--@api-stub: World:getBodyCCD
print("body CCD: " .. tostring(world:getBodyCCD(player_body:getId())))

--@api-stub: World:setBodyOneWay
-- One-way platform: player passes through from below.
world:setBodyOneWay(platform:getId(), true)

--@api-stub: World:getBodyOneWay
print("one-way: " .. tostring(world:getBodyOneWay(platform:getId())))

--@api-stub: World:clearBodyOneWay
world:clearBodyOneWay(platform:getId())

--@api-stub: World:isBodySleeping
print("world body sleeping: " .. tostring(world:isBodySleeping(player_body:getId())))

--@api-stub: World:wakeUpBody
world:wakeUpBody(player_body:getId())

--@api-stub: World:sleepBody
world:sleepBody(crate:getId())

--@api-stub: World:destroyBody
-- world:destroyBody(crate:getId())

--@api-stub: World:newBodies
-- Batch-create bodies for performance.
local batch_ids = world:newBodies({
    {type = "static", x = 100, y = 500},
    {type = "static", x = 200, y = 500},
    {type = "static", x = 300, y = 500},
})
print("batch created: " .. #batch_ids .. " bodies")

-- =============================================================================
-- Shapes & Fixtures
-- =============================================================================

--@api-stub: lurek.physics.newRectangleShape
local box_shape = lurek.physics.newRectangleShape(32, 48)

--@api-stub: lurek.physics.newCircleShape
local ball_shape = lurek.physics.newCircleShape(16)

--@api-stub: lurek.physics.newEdgeShape
local ground_edge = lurek.physics.newEdgeShape(0, 0, 800, 0)

--@api-stub: lurek.physics.newPolygonShape
local tri_shape = lurek.physics.newPolygonShape({0,-20, 15,10, -15,10})

--@api-stub: lurek.physics.newChainShape
local terrain_chain = lurek.physics.newChainShape(false, {0,500, 200,480, 400,500, 600,470, 800,500})

--@api-stub: lurek.physics.attachShape
lurek.physics.attachShape(world, player_body:getId(), box_shape)

-- =============================================================================
-- PhysicsShape Methods
-- =============================================================================

--@api-stub: PhysicsShape:getType
print("shape type: " .. box_shape:getType())

--@api-stub: PhysicsShape:getRadius
print("ball radius: " .. ball_shape:getRadius())

--@api-stub: PhysicsShape:getBoundingBox
local x1, y1, x2, y2 = box_shape:getBoundingBox()
print("AABB: (" .. x1 .. "," .. y1 .. ") to (" .. x2 .. "," .. y2 .. ")")

--@api-stub: PhysicsShape:setDensity
box_shape:setDensity(1.0)

--@api-stub: PhysicsShape:setFriction
box_shape:setFriction(0.5)

--@api-stub: PhysicsShape:setRestitution
box_shape:setRestitution(0.2)

--@api-stub: PhysicsShape:setSensor
-- Sensor: detects overlap without physical collision (trigger zones).
ball_shape:setSensor(false)

--@api-stub: PhysicsShape:destroy
-- box_shape:destroy()  -- commented: still in use

-- =============================================================================
-- Simulation
-- =============================================================================

--@api-stub: World:step
world:step(1/60)

--@api-stub: lurek.physics.step
lurek.physics.step(world, 1/60)

--@api-stub: World:stepFixed
-- Fixed timestep stepping with accumulator.
world:stepFixed(1/60, 3)

--@api-stub: World:setSolverIterations
world:setSolverIterations(8)

--@api-stub: World:getSolverIterations
print("solver iterations: " .. world:getSolverIterations())

-- =============================================================================
-- Sleeping Configuration (module-level)
-- =============================================================================

--@api-stub: lurek.physics.isSleepingAllowed
print("sleeping allowed: " .. tostring(lurek.physics.isSleepingAllowed(world)))

--@api-stub: lurek.physics.setSleepingAllowed
lurek.physics.setSleepingAllowed(world, true)

-- =============================================================================
-- Collision Detection
-- =============================================================================

--@api-stub: lurek.physics.getCollisions
local collisions = lurek.physics.getCollisions(world)
print("collisions this frame: " .. #collisions)

--@api-stub: World:getCollisionEvents
local events2 = world:getCollisionEvents()
print("collision events: " .. #events2)

--@api-stub: World:getBeginContactEvents
local begins = world:getBeginContactEvents()
print("begin contacts: " .. #begins)

--@api-stub: World:getEndContactEvents
local ends = world:getEndContactEvents()
print("end contacts: " .. #ends)

--@api-stub: World:getContacts
local contacts = world:getContacts()
print("active contacts: " .. #contacts)

--@api-stub: World:getBodyContacts
local body_contacts = world:getBodyContacts(player_body:getId())
print("player contacts: " .. #body_contacts)

--@api-stub: World:getBodyAtPoint
-- Point query: which body is at this pixel position?
local hit = world:getBodyAtPoint(200, 100)
print("body at (200,100): " .. tostring(hit))

-- =============================================================================
-- Collision Callbacks
-- =============================================================================

--@api-stub: World:setBeginContact
world:setBeginContact(function(id_a, id_b)
    print("contact begin: " .. id_a .. " <-> " .. id_b)
end)

--@api-stub: World:clearBeginContact
world:clearBeginContact()

--@api-stub: World:setEndContact
world:setEndContact(function(id_a, id_b)
    print("contact end: " .. id_a .. " <-> " .. id_b)
end)

--@api-stub: World:clearEndContact
world:clearEndContact()

-- =============================================================================
-- Joints
-- =============================================================================

--@api-stub: World:fixtureCount
print("fixtures: " .. world:fixtureCount())

--@api-stub: World:jointCount
print("joints: " .. world:jointCount())

--@api-stub: World:getJointIds
local joint_ids = world:getJointIds()
print("joint IDs: " .. #joint_ids)

--@api-stub: World:getJointBodies
-- Get the two bodies connected by a joint.
-- local b1, b2 = world:getJointBodies(joint_id)

--@api-stub: World:getJointType
-- local jtype = world:getJointType(joint_id)

--@api-stub: World:getJointMotorSpeed
-- local speed = world:getJointMotorSpeed(joint_id)

--@api-stub: World:getJointLimits
-- local lo, hi = world:getJointLimits(joint_id)

--@api-stub: World:destroyJoint
-- world:destroyJoint(joint_id)

--@api-stub: World:setJointBreakForce
-- world:setJointBreakForce(joint_id, 500)

--@api-stub: World:getJointBreakForce
-- local force = world:getJointBreakForce(joint_id)

-- =============================================================================
-- Gravity Zones
-- =============================================================================

--@api-stub: World:addZone
local zone_id = world:addZone()
print("zone added: " .. tostring(zone_id))

--@api-stub: World:getZoneEvents
local zone_events = world:getZoneEvents()
print("zone events: " .. #zone_events)

--@api-stub: Zone:getId
-- Assume zone is returned from addZone
-- print("zone id: " .. zone:getId())

--@api-stub: Zone:setEnabled
-- zone:setEnabled(true)

--@api-stub: Zone:setPriority
-- zone:setPriority(10)

--@api-stub: Zone:setLayerMask
-- zone:setLayerMask(0xFFFF)

--@api-stub: Zone:setCircle
-- Circular gravity zone (black hole effect).
-- zone:setCircle(400, 300, 200)

--@api-stub: Zone:setGravityDirectional
-- Constant directional gravity override.
-- zone:setGravityDirectional(0, -15)

--@api-stub: Zone:setGravityPoint
-- Point gravity (attract toward center).
-- zone:setGravityPoint(400, 300, 500)

--@api-stub: Zone:setGravityRepulsor
-- Repel bodies away from a center point.
-- zone:setGravityRepulsor(400, 300, 300)

--@api-stub: Zone:setGravityZero
-- Zero-gravity zone (space section).
-- zone:setGravityZero()

--@api-stub: Zone:setLinearDampingOverride
-- zone:setLinearDampingOverride(2.0)

--@api-stub: Zone:setAngularDampingOverride
-- zone:setAngularDampingOverride(1.0)

--@api-stub: Zone:destroy
-- zone:destroy()

-- =============================================================================
-- Debug Rendering
-- =============================================================================

--@api-stub: lurek.physics.debugDraw
lurek.physics.debugDraw(world)

--@api-stub: lurek.physics.drawDebugGpu
lurek.physics.drawDebugGpu(world)

-- =============================================================================
-- Terrain — destructible voxel-like terrain
-- =============================================================================

--@api-stub: lurek.physics.newTerrain
local terrain = lurek.physics.newTerrain(100, 50)

--@api-stub: Terrain:setCell
terrain:setCell(10, 5, 1)

--@api-stub: Terrain:getCell
print("cell (10,5): " .. terrain:getCell(10, 5))

--@api-stub: Terrain:fillCircle
-- Explosion crater: clear a circular area.
terrain:fillCircle(50, 25, 8, 0)

--@api-stub: Terrain:fillRect
terrain:fillRect(0, 45, 100, 5, 1)

--@api-stub: Terrain:fillAll
terrain:fillAll(1)

--@api-stub: Terrain:flush
-- Sync terrain changes to the physics world.
terrain:flush()

--@api-stub: Terrain:isDirty
print("terrain dirty: " .. tostring(terrain:isDirty()))

--@api-stub: Terrain:collapseColumns
-- Simulate gravity on terrain cells (sand/gravel falling).
terrain:collapseColumns()

--@api-stub: Terrain:solidPositions
local solids = terrain:solidPositions()
print("solid cells: " .. #solids)

--@api-stub: Terrain:spawnDebris
-- Turn destroyed cells into dynamic body debris.
terrain:spawnDebris(50, 25, 5)

--@api-stub: Terrain:toImageData
local terrain_img = terrain:toImageData()
print("terrain image: " .. tostring(terrain_img))

--@api-stub: Terrain:toBytes
local terrain_bytes = terrain:toBytes()
print("terrain bytes: " .. #terrain_bytes)

--@api-stub: Terrain:loadFromBytes
terrain:loadFromBytes(terrain_bytes)

-- =============================================================================
-- Cellular Automata — cave generation
-- =============================================================================

--@api-stub: lurek.physics.newCellular
local cave = lurek.physics.newCellular(80, 60)

--@api-stub: Cellular:setCell
cave:setCell(40, 30, 1)

--@api-stub: Cellular:getCell
print("cave (40,30): " .. cave:getCell(40, 30))

--@api-stub: Cellular:fillRect
-- Fill the border with solid walls.
cave:fillRect(0, 0, 80, 1, 1)

--@api-stub: Cellular:fillCircle
-- Carve out a circular room.
cave:fillCircle(40, 30, 10, 0)

--@api-stub: Cellular:step
-- Run one cellular automata iteration (smoothing pass).
cave:step()

--@api-stub: Cellular:stepN
-- Run 5 iterations at once for cave generation.
cave:stepN(5)

--@api-stub: Cellular:toImageData
local cave_img = cave:toImageData()
print("cave image: " .. tostring(cave_img))

--@api-stub: Cellular:toImageDataRegion
local region = cave:toImageDataRegion(20, 15, 40, 30)
print("cave region: " .. tostring(region))

--@api-stub: Cellular:countCells
print("solid cells: " .. cave:countCells(1))

--@api-stub: Cellular:findCells
local open = cave:findCells(0)
print("open cells: " .. #open)

--@api-stub: Cellular:toBytes
local cave_bytes = cave:toBytes()
print("cave bytes: " .. #cave_bytes)

--@api-stub: Cellular:loadFromBytes
cave:loadFromBytes(cave_bytes)

-- =============================================================================
-- World Cleanup
-- =============================================================================

--@api-stub: World:clear
world:clear()

--@api-stub: lurek.physics.destroyWorld
lurek.physics.destroyWorld(world)

print("\n-- physics.lua example complete --")
