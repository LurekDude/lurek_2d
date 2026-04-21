-- content/examples/physics.lua
-- Lurek2D lurek.physics API Reference
-- Run with: cargo run -- content/examples/physics
--
Scenario: A 2D platformer with rigid body physics — a player character,
-- platforms, projectiles, destructible terrain, cellular automata for cave
-- generation, gravity zones, joints, and collision event handling.

print("=== lurek.physics — 2D Physics Simulation ===\n")

-- =============================================================================
-- World Creation & Configuration
-- =============================================================================

-- Create a physics world with gravity pointing down.
local world = lurek.physics.newWorld(0, 9.81)
print("world created with gravity (0, 9.81)")

-- =============================================================================
-- World Methods — simulation control
-- =============================================================================

world:setGravity(0, 20.0)

local gx, gy = world:getGravity()
print("gravity: " .. gx .. ", " .. gy)

-- Set the pixels-per-meter scale (default 64).
world:setMeter(64)

print("meter scale: " .. world:getMeter() .. " px/m")

local px, py = world:toPhysics(320, 480)
print("pixel (320,480) = physics (" .. px .. "," .. py .. ")")

local sx, sy = world:toPixels(5, 7.5)
print("physics (5,7.5) = pixel (" .. sx .. "," .. sy .. ")")

-- =============================================================================
-- Body Creation & Management
-- =============================================================================

-- Dynamic body for the player character.
local player_body = world:newBody("dynamic", 200, 100)

-- Static platform.
local platform = world:newBody("static", 400, 500)

-- Kinematic moving platform.
local elevator = world:newBody("kinematic", 600, 400)

Alternative: create a body via module function.
local crate = lurek.physics.newBody(world, "dynamic", 300, 200)

local fetched = lurek.physics.getBody(world, 1)
print("body 1: " .. tostring(fetched))

print("bodies: " .. world:getBodyCount())

local ids = world:getBodyIds()
print("body IDs: " .. #ids)

-- =============================================================================
-- Body Properties
-- =============================================================================

print("player ID: " .. player_body:getId())

local bx, by = player_body:getPosition()
print("player pos: " .. bx .. "," .. by)

player_body:setPosition(200, 100)

print("x: " .. player_body:getX())

print("y: " .. player_body:getY())

local vx, vy = player_body:getVelocity()
print("velocity: " .. vx .. "," .. vy)

player_body:setVelocity(100, -200)

lurek.physics.setBodyVelocity(world, player_body:getId(), 50, 0)

print("angle: " .. player_body:getAngle())

player_body:setAngle(0)

print("angular vel: " .. player_body:getAngularVelocity())

player_body:setAngularVelocity(0)

print("mass: " .. player_body:getMass())

player_body:setMass(1.5)

print("type: " .. player_body:getType())

player_body:setType("dynamic")

print("width: " .. player_body:getWidth())

print("height: " .. player_body:getHeight())

-- =============================================================================
-- Body Material Properties
-- =============================================================================

print("friction: " .. player_body:getFriction())

player_body:setFriction(0.3)

print("bounce: " .. player_body:getRestitution())

player_body:setRestitution(0.1)

-- =============================================================================
-- Collision Layers & Masks
-- =============================================================================

print("layer: " .. player_body:getLayer())

player_body:setLayer(1)

print("mask: " .. player_body:getMask())

player_body:setMask(0xFFFF)

-- =============================================================================
-- Forces & Impulses
-- =============================================================================

Jump: apply upward impulse.
player_body:applyImpulse(0, -500)

-- Wind pushes player right.
player_body:applyForce(100, 0)

player_body:applyTorque(10)

player_body:applyAngularImpulse(5)

-- =============================================================================
-- Body Advanced Properties
-- =============================================================================

print("gravity scale: " .. player_body:getGravityScale())

player_body:setGravityScale(1.0)

print("fixed rotation: " .. tostring(player_body:isFixedRotation()))

player_body:setFixedRotation(true)

print("linear damping: " .. player_body:getLinearDamping())

player_body:setLinearDamping(0.1)

print("angular damping: " .. player_body:getAngularDamping())

player_body:setAngularDamping(0.05)

print("CCD: " .. tostring(player_body:isBullet()))

-- Enable continuous collision detection for fast projectiles.
player_body:setBullet(false)

-- =============================================================================
-- Body Sleep State
-- =============================================================================

print("sleeping allowed: " .. tostring(player_body:isSleepingAllowed()))

player_body:setSleepingAllowed(true)

print("sleeping: " .. tostring(player_body:isSleeping()))

player_body:wakeUp()

player_body:sleep()

crate:destroy()  -- commented: still needed

-- =============================================================================
-- World Body Management
-- =============================================================================

world:setBodyType(player_body:getId(), "dynamic")

print("world body type: " .. world:getBodyType(player_body:getId()))

world:setBodyData(player_body:getId(), {name = "player", hp = 100})

local bdata = world:getBodyData(player_body:getId())
print("body data: " .. tostring(bdata))

world:clearBodyData(player_body:getId())

world:setBodyCCD(player_body:getId(), false)

print("body CCD: " .. tostring(world:getBodyCCD(player_body:getId())))

-- One-way platform: player passes through from below.
world:setBodyOneWay(platform:getId(), true)

print("one-way: " .. tostring(world:getBodyOneWay(platform:getId())))

world:clearBodyOneWay(platform:getId())

print("world body sleeping: " .. tostring(world:isBodySleeping(player_body:getId())))

world:wakeUpBody(player_body:getId())

world:sleepBody(crate:getId())

world:destroyBody(crate:getId())

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

local box_shape = lurek.physics.newRectangleShape(32, 48)

local ball_shape = lurek.physics.newCircleShape(16)

local ground_edge = lurek.physics.newEdgeShape(0, 0, 800, 0)

local tri_shape = lurek.physics.newPolygonShape({0,-20, 15,10, -15,10})

local terrain_chain = lurek.physics.newChainShape(false, {0,500, 200,480, 400,500, 600,470, 800,500})

lurek.physics.attachShape(world, player_body:getId(), box_shape)

-- =============================================================================
-- PhysicsShape Methods
-- =============================================================================

print("shape type: " .. box_shape:getType())

print("ball radius: " .. ball_shape:getRadius())

local x1, y1, x2, y2 = box_shape:getBoundingBox()
print("AABB: (" .. x1 .. "," .. y1 .. ") to (" .. x2 .. "," .. y2 .. ")")

box_shape:setDensity(1.0)

box_shape:setFriction(0.5)

box_shape:setRestitution(0.2)

Sensor: detects overlap without physical collision (trigger zones).
ball_shape:setSensor(false)

box_shape:destroy()  -- commented: still in use

-- =============================================================================
-- Simulation
-- =============================================================================

world:step(1/60)

lurek.physics.step(world, 1/60)

-- Fixed timestep stepping with accumulator.
world:stepFixed(1/60, 3)

world:setSolverIterations(8)

print("solver iterations: " .. world:getSolverIterations())

-- =============================================================================
-- Sleeping Configuration (module-level)
-- =============================================================================

print("sleeping allowed: " .. tostring(lurek.physics.isSleepingAllowed(world)))

lurek.physics.setSleepingAllowed(world, true)

-- =============================================================================
-- Collision Detection
-- =============================================================================

local collisions = lurek.physics.getCollisions(world)
print("collisions this frame: " .. #collisions)

local events2 = world:getCollisionEvents()
print("collision events: " .. #events2)

local begins = world:getBeginContactEvents()
print("begin contacts: " .. #begins)

local ends = world:getEndContactEvents()
print("end contacts: " .. #ends)

local contacts = world:getContacts()
print("active contacts: " .. #contacts)

local body_contacts = world:getBodyContacts(player_body:getId())
print("player contacts: " .. #body_contacts)

-- Point query: which body is at this pixel position?
local hit = world:getBodyAtPoint(200, 100)
print("body at (200,100): " .. tostring(hit))

-- =============================================================================
-- Collision Callbacks
-- =============================================================================

world:setBeginContact(function(id_a, id_b)
    print("contact begin: " .. id_a .. " <-> " .. id_b)
end)

world:clearBeginContact()

world:setEndContact(function(id_a, id_b)
    print("contact end: " .. id_a .. " <-> " .. id_b)
end)

world:clearEndContact()

-- =============================================================================
-- Joints
-- =============================================================================

print("fixtures: " .. world:fixtureCount())

print("joints: " .. world:jointCount())

local joint_ids = world:getJointIds()
print("joint IDs: " .. #joint_ids)

-- Get the two bodies connected by a joint.
-- local b1, b2 = world:getJointBodies(joint_id)

-- local jtype = world:getJointType(joint_id)

-- local speed = world:getJointMotorSpeed(joint_id)

-- local lo, hi = world:getJointLimits(joint_id)

world:destroyJoint(joint_id)

world:setJointBreakForce(joint_id, 500)

-- local force = world:getJointBreakForce(joint_id)

-- =============================================================================
-- Gravity Zones
-- =============================================================================

local zone_id = world:addZone()
print("zone added: " .. tostring(zone_id))

local zone_events = world:getZoneEvents()
print("zone events: " .. #zone_events)

-- Assume zone is returned from addZone
-- print("zone id: " .. zone:getId())

zone:setEnabled(true)

zone:setPriority(10)

zone:setLayerMask(0xFFFF)

-- Circular gravity zone (black hole effect).
zone:setCircle(400, 300, 200)

-- Constant directional gravity override.
zone:setGravityDirectional(0, -15)

-- Point gravity (attract toward center).
zone:setGravityPoint(400, 300, 500)

-- Repel bodies away from a center point.
zone:setGravityRepulsor(400, 300, 300)

-- Zero-gravity zone (space section).
zone:setGravityZero()

zone:setLinearDampingOverride(2.0)

zone:setAngularDampingOverride(1.0)

zone:destroy()

-- =============================================================================
-- Debug Rendering
-- =============================================================================

lurek.physics.debugDraw(world)

lurek.physics.drawDebugGpu(world)

-- =============================================================================
-- Terrain — destructible voxel-like terrain
-- =============================================================================

local terrain = lurek.physics.newTerrain(100, 50)

terrain:setCell(10, 5, 1)

print("cell (10,5): " .. terrain:getCell(10, 5))

-- Explosion crater: clear a circular area.
terrain:fillCircle(50, 25, 8, 0)

terrain:fillRect(0, 45, 100, 5, 1)

terrain:fillAll(1)

-- Sync terrain changes to the physics world.
terrain:flush()

print("terrain dirty: " .. tostring(terrain:isDirty()))

-- Simulate gravity on terrain cells (sand/gravel falling).
terrain:collapseColumns()

local solids = terrain:solidPositions()
print("solid cells: " .. #solids)

-- Turn destroyed cells into dynamic body debris.
terrain:spawnDebris(50, 25, 5)

local terrain_img = terrain:toImageData()
print("terrain image: " .. tostring(terrain_img))

local terrain_bytes = terrain:toBytes()
print("terrain bytes: " .. #terrain_bytes)

terrain:loadFromBytes(terrain_bytes)

-- =============================================================================
-- Cellular Automata — cave generation
-- =============================================================================

local cave = lurek.physics.newCellular(80, 60)

cave:setCell(40, 30, 1)

print("cave (40,30): " .. cave:getCell(40, 30))

-- Fill the border with solid walls.
cave:fillRect(0, 0, 80, 1, 1)

-- Carve out a circular room.
cave:fillCircle(40, 30, 10, 0)

-- Run one cellular automata iteration (smoothing pass).
cave:step()

-- Run 5 iterations at once for cave generation.
cave:stepN(5)

local cave_img = cave:toImageData()
print("cave image: " .. tostring(cave_img))

local region = cave:toImageDataRegion(20, 15, 40, 30)
print("cave region: " .. tostring(region))

print("solid cells: " .. cave:countCells(1))

local open = cave:findCells(0)
print("open cells: " .. #open)

local cave_bytes = cave:toBytes()
print("cave bytes: " .. #cave_bytes)

cave:loadFromBytes(cave_bytes)

-- =============================================================================
-- World Cleanup
-- =============================================================================

world:clear()

lurek.physics.destroyWorld(world)

print("\n-- physics.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Body methods
-- -----------------------------------------------------------------------------

-- Removes this body from the world.
body:destroy()
-- -----------------------------------------------------------------------------
-- PhysicsShape methods
-- -----------------------------------------------------------------------------

-- Releases this shape handle (GC handles cleanup).
physicsShape_stub:destroy()
-- -----------------------------------------------------------------------------
-- World methods
-- -----------------------------------------------------------------------------

-- Removes a body from the world.
world:destroyBody(1)
-- Returns the two body IDs connected by a joint.
world:getJointBodies(jid)  -- -> integer
-- Removes a joint from the world.
world:destroyJoint(jid)
-- Returns the type name of a joint.
world:getJointType(jid)  -- -> string
-- Returns the motor speed on a joint's angular axis.
world:getJointMotorSpeed(jid)  -- -> number
-- Returns the angular limits on a joint.
world:getJointLimits(jid)  -- -> number
-- Sets the relative-velocity threshold above which a joint breaks.
world:setJointBreakForce(jid, f)
-- Returns the break threshold for a joint, or nil if not set.
world:getJointBreakForce(jid)
-- -----------------------------------------------------------------------------
-- Zone methods
-- -----------------------------------------------------------------------------

-- Enables or disables the zone.
zone:setEnabled(true)
-- Sets the zone priority; higher values win over lower when zones overlap.
zone:setPriority(priority)
-- Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
zone:setLayerMask(mask)
-- Replaces the zone boundary with a circle.
zone:setCircle(cx, cy, 24.0)
-- Sets directional gravity inside the zone.
zone:setGravityDirectional(gx, gy)
-- Suppresses gravity inside the zone (zero-g pocket).
zone:setGravityZero()
-- Sets an optional linear damping override for bodies inside the zone.
zone:setLinearDampingOverride([value])
-- Removes the zone from the world.
zone:destroy()
