-- examples/physics.lua
-- Lurek2D lurek.physics API Reference
-- Demonstrates world creation, bodies, shapes, joints, queries, and events.

-- ─────────────────────────────────────────────────────────────────────────────
-- Creating a Physics World
-- ─────────────────────────────────────────────────────────────────────────────

-- Create a world with gravity (pixels-per-second² in each axis)
-- Positive Y is downward in screen space.
local world = lurek.physics.newWorld(0, 980)  -- standard Earth gravity

-- Scale factor: how many pixels equal 1 physics metre (default = 64)
world:setMeter(64)
local ppm = world:getMeter()  -- pixels per metre

-- Convert between physics units and screen pixels
local px = world:toPixels(1.5)    -- 1.5 metres → pixels
local m  = world:toPhysics(96)    -- 96 pixels  → metres

-- Change gravity at runtime (e.g., zero-G power-up)
world:setGravity(0, 0)
local gx, gy = world:getGravity()

-- Step the simulation (call once per frame from lurek.process)
function lurek.process(dt)
    world:step(dt)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Body Types
-- ─────────────────────────────────────────────────────────────────────────────

-- Body types:
"dynamic"  -- fully simulated; affected by gravity and forces
"static"  -- immovable; used for terrain, walls, platforms
"kinematic"  -- moved manually via setPosition/setVelocity; ignores gravity

-- ─────────────────────────────────────────────────────────────────────────────
-- Creating Bodies
-- ─────────────────────────────────────────────────────────────────────────────

-- Axis-aligned rectangle body (x, y = centre position, width, height, type)
-- Returns a Body userdata object.
local player = world:newBody(400, 300, "dynamic")

-- Circle body (x, y = centre, radius, type)
local ball = world:newCircleBody(200, 100, 20, "dynamic")

-- Convex polygon body (vertices as flat {x1,y1, x2,y2, ...} list)
local triangle = world:newPolygonBody(500, 200, {
    -30,  30,
      0, -30,
     30,  30,
}, "dynamic")

-- Static edge (line segment: body origin + two endpoints)
local floor = world:newEdgeBody(0, 500, 0, 0, 800, 0, "static")

-- Chain of line segments (open or closed polygon, typically static)
local hill = world:newChainBody(0, 0, {
    0, 400, 200, 350, 400, 380, 600, 300, 800, 400
}, false, "static")  -- false = open chain

-- ─────────────────────────────────────────────────────────────────────────────
-- Body Position & Motion
-- ─────────────────────────────────────────────────────────────────────────────

-- Position
player:setPosition(400, 300)
local x, y = player:getPosition()
local px2 = player:getX()
local py2 = player:getY()

-- Linear velocity (pixels/s)
player:setVelocity(100, 0)
local vx, vy = player:getVelocity()

-- Angle (radians, counter-clockwise positive)
player:setAngle(math.pi / 4)   -- 45 degrees
local angle = player:getAngle()

-- Angular velocity (radians/s)
player:setAngularVelocity(1.0)
local omega = player:getAngularVelocity()

-- ─────────────────────────────────────────────────────────────────────────────
-- Forces & Impulses
-- ─────────────────────────────────────────────────────────────────────────────

-- Apply a continuous force (world-space, at the body centre)
player:applyForce(0, -5000)  -- push upward

-- Apply force at a world-space point (creates torque if offset from centre)
player:applyForce(100, 0,  player:getX() + 10, player:getY())

-- Apply an instant velocity impulse (e.g., for a jump)
player:applyImpulse(0, -300)

-- Apply torque (continuous rotational force)
player:applyTorque(50)

-- Apply angular impulse (instant spin)
player:applyAngularImpulse(0.5)

-- ─────────────────────────────────────────────────────────────────────────────
-- Body Properties
-- ─────────────────────────────────────────────────────────────────────────────

local mass    = player:getMass()
local inertia = player:getInertia()

player:setMass(5.0)     -- override computed mass

player:setGravityScale(0.5)  -- half gravity for this body
local gs = player:getGravityScale()

player:setLinearDamping(0.2)   -- air resistance
player:setAngularDamping(0.1)

player:setFixedRotation(true)  -- prevent rotation (common for characters)
player:setBullet(true)         -- enable CCD for fast-moving objects

player:setSleepingAllowed(false)  -- never auto-sleep
player:setAwake(true)

player:setActive(false)  -- remove body from simulation temporarily

-- ─────────────────────────────────────────────────────────────────────────────
-- Fixtures (collision shapes attached to a body)
-- ─────────────────────────────────────────────────────────────────────────────
-- A body has no collision until you add at least one fixture.

-- addFixture(bodyId, shapeType, density, friction, restitution, sensor, ...shape_args)
local body_id = player:getId()

-- Rectangle fixture: add last args = width, height
world:addFixture(body_id, "box", 1.0, 0.3, 0.2, false, 30, 50)

-- Circle fixture: last arg = radius
world:addFixture(body_id, "circle", 1.0, 0.3, 0.0, false, 15)

-- Sensor fixture (detects overlaps without pushing): sensor = true
world:addFixture(body_id, "box", 0, 0, 0, true, 64, 64)  -- trigger zone

-- Fixture count on a body
local fn = world:fixtureCount(body_id)

-- Modify fixture properties by index (1-based)
world:setFixtureFriction(body_id, 1, 0.8)
world:setFixtureRestitution(body_id, 1, 0.5)  -- bounciness [0,1]
world:setFixtureSensor(body_id, 1, false)

-- Per-body friction/restitution convenience
player:setFriction(0.5)
player:setRestitution(0.3)
player:setDensity(1.2)
player:setSensor(false)

local friction    = player:getFriction()
local restitution = player:getRestitution()
local density     = player:getDensity()
local sensor      = player:isSensor()

-- ─────────────────────────────────────────────────────────────────────────────
-- Mass Data
-- ─────────────────────────────────────────────────────────────────────────────

-- Get computed mass data: mass, cx (centre x), cy (centre y), rotationalInertia
local mass2, cx, cy, rotI = player:getMassData()

-- Override mass data (advanced: breaks physics realism)
player:setMassData(5.0, 0, 0, 10.0)

-- Recompute from fixtures (undo manual setMassData)
player:resetMassData()

-- ─────────────────────────────────────────────────────────────────────────────
-- Body Queries
-- ─────────────────────────────────────────────────────────────────────────────

-- Coordinate space helpers
local wx2, wy2 = player:getWorldPoint(0, -10)       -- local → world (pivot offset)
local lx2, ly2 = player:getLocalPoint(wx2, wy2)     -- world → local
local wvx, wvy = player:getWorldVector(0, -1)       -- local direction → world
local lvx, lvy = player:getLocalVector(0, -1)       -- world direction → local

-- Velocity of a world-space point ON the body (includes angular velocity contribution)
local pvx, pvy = player:getLinearVelocityFromWorldPoint(wx2, wy2)

-- User data (arbitrary Lua value stored with the body)
player:setUserData({ type = "player", hp = 100 })
local data = player:getUserData()

-- Body type read/change at runtime
player:setBodyType("kinematic")  -- "dynamic"/"static"/"kinematic"
local btype = player:getBodyType()

-- ─────────────────────────────────────────────────────────────────────────────
-- Body Lifecycle
-- ─────────────────────────────────────────────────────────────────────────────

-- Count and enumerate all bodies in the world
local body_count = world:getBodyCount()
local body_ids   = world:getBodyIds()  -- table of numeric ids

-- Destroy a body by id (removes it from the simulation)
local enemy_id = ball:getId()
world:destroyBody(enemy_id)

-- Remove all bodies and joints
world:clear()

-- ─────────────────────────────────────────────────────────────────────────────
-- Joints
-- ─────────────────────────────────────────────────────────────────────────────
-- Joints constrain the relative motion of two bodies.

local box_a = world:newBody(300, 200, "dynamic")
local box_b = world:newBody(350, 200, "dynamic")
local id_a  = box_a:getId()
local id_b  = box_b:getId()
world:addFixture(id_a, "box", 1.0, 0.3, 0.0, false, 30, 30)
world:addFixture(id_b, "box", 1.0, 0.3, 0.0, false, 30, 30)

-- Revolute joint (pivot/hinge) — anchor in world space
local rev_id = world:addRevoluteJoint(id_a, id_b, 325, 200)

-- Distance joint (spring / rod of fixed length)
local dist_id = world:addDistanceJoint(id_a, id_b, 300, 200, 350, 200, 50)

-- Prismatic joint (slider along an axis)
local pris_id = world:addPrismaticJoint(id_a, id_b, 325, 200, 1, 0)  -- axis=(1,0)

-- Weld joint (fixed relative position — like gluing)
local weld_id = world:addWeldJoint(id_a, id_b, 325, 200)

-- Rope joint (limits maximum distance)
local rope_id = world:addRopeJoint(id_a, id_b, 300, 200, 350, 200, 60)

-- Wheel joint (car spring with motor)
local wheel_id = world:addWheelJoint(id_a, id_b, 325, 200, 0, 1)  -- axis=(0,1)

-- Friction joint (air resistance / angular friction between bodies)
local fric_id = world:addFrictionJoint(id_a, id_b, 325, 200, 1000, 1000)

-- Motor joint (force body A to track body B)
local motor_id = world:addMotorJoint(id_a, id_b, 0.5)  -- correction factor

-- Mouse joint (drag a body towards a target point)
local mouse_id = world:addMouseJoint(id_a, 300, 200, 5000)  -- max force

-- Pulley joint (rope over a pulley)
local pulley_id = world:addPulleyJoint(id_a, id_b, gax, gay, gbx, gby, ax, ay, bx, by, ratio)

-- ── Joint Management ────────────────────────────────────────────────────────

-- Count and inspect
local jcount = world:jointCount()
local jids   = world:getJointIds()

-- Get both bodies for a joint
local ba_id, bb_id = world:getJointBodies(rev_id)

-- Joint type: "revolute", "distance", "prismatic", "weld", "rope", "wheel", etc.
local jtype = world:getJointType(rev_id)

-- Destroy a joint
world:destroyJoint(rope_id)

-- ── Motor / Limit Controls (for hinges, sliders) ──────────────────────────

world:setJointMotorSpeed(rev_id, 2.0)       -- radians/s (for revolute)
local ms = world:getJointMotorSpeed(rev_id)

world:setJointLimitsEnabled(rev_id, true)
world:setJointLimits(rev_id, -math.pi/4, math.pi/4)  -- min / max angle
local lo, hi = world:getJointLimits(rev_id)

-- Update mouse joint target (drag the body to a new point)
world:setMouseJointTarget(mouse_id, 350, 250)

-- ─────────────────────────────────────────────────────────────────────────────
-- Spatial Queries
-- ─────────────────────────────────────────────────────────────────────────────

-- Raycast: all intersections along a ray; returns list of {bodyId, x, y, nx, ny, fraction}
local hits = world:raycast(100, 0, 100, 600)

-- Closest intersection only (from origin, direction+length)
local hit = world:raycastClosest(100, 0, 0, 1, 600)  -- (ox,oy, dx,dy, maxDist)
if hit then
    print("hit body:", hit.bodyId, "at", hit.x, hit.y)
end

-- All intersections (alternative form)
local all_hits = world:raycastAll(100, 0, 0, 1, 600)

-- Query all bodies whose AABB overlaps a rectangle
local in_area = world:queryAABB(200, 200, 400, 300)  -- x,y,w,h

-- Get the topmost body at a screen point
local body_at = world:getBodyAtPoint(mouse_x, mouse_y)
if body_at then
    print("body at cursor:", body_at)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Collision Events (process AFTER world:step)
-- ─────────────────────────────────────────────────────────────────────────────

function lurek.process(dt)
    world:step(dt)

    -- All contacts currently active (pair per step)
    local contacts = world:getContacts()  -- {{bodyA, bodyB, nx, ny, impulse}, ...}

    -- New contacts started this step
    for _, ev in ipairs(world:getBeginContactEvents()) do
        print("collision began:", ev.bodyA, ev.bodyB)
    end

    -- Contacts that ended this step
    for _, ev in ipairs(world:getEndContactEvents()) do
        print("collision ended:", ev.bodyA, ev.bodyB)
    end

    -- Filter: all contacts involving a specific body
    local player_contacts = world:getBodyContacts(body_id)

    -- Combined list of begin+end events
    local all_events = world:getCollisionEvents()
    for _, ev in ipairs(all_events) do
        -- ev.type = "begin" or "end"
        -- ev.bodyA, ev.bodyB, ev.nx, ev.ny
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Filter Data (collision categories and masks)
-- ─────────────────────────────────────────────────────────────────────────────
-- category: which group this body belongs to (bitmask)
-- mask:     which groups this body collides with
-- group:    positive = always collide, negative = never collide

-- Example: give player category=2, collide with terrain (1) and enemies (4)
player:setFilterData(0x0002, 0x0001 | 0x0004)

-- Enemy: category=4, collide with player (2) and terrain (1)
ball:setFilterData(0x0004, 0x0002 | 0x0001)

-- ─── Body ──────────────────────────────────────────────────────────────────────

body:destroy()  -- Removes this body from the world
local angular_damping = body:getAngularDamping()  -- Returns the angular damping coefficient
local height = body:getHeight()  -- Returns the body height
local layer = body:getLayer()  -- Returns the collision layer bitmask
local linear_damping = body:getLinearDamping()  -- Returns the linear damping coefficient
local mask = body:getMask()  -- Returns the collision mask bitmask
local type_val = body:getType()  -- Returns the body type as a string
local width = body:getWidth()  -- Returns the body width
local is_bullet = body:isBullet()  -- Returns whether CCD is enabled
local is_fixed_rotation = body:isFixedRotation()  -- Returns whether rotation is locked
local is_sleeping_allowed = body:isSleepingAllowed()  -- Returns whether the body can sleep
body:setLayer(1)  -- Sets the collision layer bitmask
body:setMask(1)  -- Sets the collision mask bitmask
body:setType("type")  -- Sets the body type

-- ─── PhysicsShape ──────────────────────────────────────────────────────────────

physicsshape:destroy()  -- Releases this shape handle (GC handles cleanup)
local bounding_box = physicsshape:getBoundingBox()  -- Returns the axis-aligned bounding box (x1, y1, x2, y2)
local radius = physicsshape:getRadius()  -- Returns the radius. Only valid for circle shapes
local type_val = physicsshape:getType()  -- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain"

-- ─── lurek.physics ──────────────────────────────────────────────────────────────
lurek.physics.attachShape(body, shape)  -- Attaches a standalone shape to a body as an additional fixture
lurek.physics.destroyWorld(world)  -- Marks a physics world for destruction. Subsequent operations on the world
local body = lurek.physics.getBody(world, body)  -- Returns the position and velocity of a body (x, y, vx, vy)
local collisions = lurek.physics.getCollisions(world)  -- Returns all collision events from the last simulation step
local is_sleeping_allowed = lurek.physics.isSleepingAllowed(world, body)  -- Returns whether the body is allowed to sleep
local body = lurek.physics.newBody(world, 1.0, 1.0, "type")  -- Creates a new rectangular body in the given world
local chain_shape = lurek.physics.newChainShape(false)  -- Creates a chain shape userdata from flat variadic vertex pairs
local circle_shape = lurek.physics.newCircleShape(1.0)  -- Creates a circle shape userdata
local edge_shape = lurek.physics.newEdgeShape(1.0, 1.0, 1.0, 1.0)  -- Creates an edge (line segment) shape userdata
local polygon_shape = lurek.physics.newPolygonShape()  -- Creates a convex polygon shape userdata from flat variadic vertex pairs
local rectangle_shape = lurek.physics.newRectangleShape(1.0, 1.0)  -- Creates a rectangle shape userdata
lurek.physics.setBodyVelocity(world, body, 1.0, 1.0)  -- Sets the velocity of a body
lurek.physics.setSleepingAllowed(world, body, false)  -- Sets whether the body is allowed to sleep
lurek.physics.step(world, 1.0)  -- Advances the physics world by dt seconds

-- Raycast result table fields (returned from lurek.physics.raycast)
-- result.normalX   -- X component of surface normal at hit point
-- result.normalY   -- Y component of surface normal at hit point
-- result.toi       -- Time of impact [0,1] along the ray origin-to-endpoint

-- Contact table fields (from world:getContacts() and world:getBodyContacts(bodyId))
-- contact.isTouching  -- true when bodies are in touching contact this frame
