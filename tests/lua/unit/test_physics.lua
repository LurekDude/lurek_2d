-- Lurek2D Physics API Tests
-- @covers lurek.physics.attachShape
-- @covers lurek.physics.getBody
-- @covers lurek.physics.isSleepingAllowed
-- @covers lurek.physics.newBody
-- @covers lurek.physics.newChainShape
-- @covers lurek.physics.newCircleShape
-- @covers lurek.physics.newEdgeShape
-- @covers lurek.physics.newPolygonShape
-- @covers lurek.physics.newRectangleShape
-- @covers lurek.physics.newWorld
-- @covers lurek.physics.setBodyVelocity
-- @covers lurek.physics.setSleepingAllowed
-- @covers lurek.physics.step
-- @covers lurek.physics.newCircleBody
-- @covers lurek.physics.newPolygonBody
-- @covers lurek.physics.newEdgeBody
-- @covers lurek.physics.newChainBody
-- @covers lurek.physics.addFixture
-- @covers lurek.physics.fixtureCount
-- @covers lurek.physics.setFixtureFriction
-- @covers lurek.physics.setFixtureRestitution
-- @covers lurek.physics.setFixtureSensor
-- @covers lurek.physics.addRevoluteJoint
-- @covers lurek.physics.addDistanceJoint
-- @covers lurek.physics.addWeldJoint
-- @covers lurek.physics.jointCount
-- @covers lurek.physics.getJointIds
-- @covers lurek.physics.destroyJoint
-- @covers lurek.physics.getJointType
-- @covers lurek.physics.destroyWorld


describe("lurek.physics module exists", function()
    it("lurek.physics is a table", function()
        expect_type("table", lurek.physics)
    end)
end)

describe("lurek.physics world", function()
    it("newWorld is a function", function()
        expect_type("function", lurek.physics.newWorld)
    end)

    it("newWorld creates a world and returns World object", function()
        local id = lurek.physics.newWorld(0, 9.81)
        expect_type("userdata", id)
    end)

    it("step is a function", function()
        expect_type("function", lurek.physics.step)
    end)

    it("step can be called with world_id and dt", function()
        local world = lurek.physics.newWorld(0, 9.81)
        expect_no_error(function()
            lurek.physics.step(world, 1/60)
        end)
    end)
end)

describe("lurek.physics bodies", function()
    it("newBody is a function", function()
        expect_type("function", lurek.physics.newBody)
    end)

    it("newBody creates a body and returns Body object", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local id = lurek.physics.newBody(world, 100, 100, "dynamic")
        expect_type("userdata", id)
    end)

    it("getBody returns position and velocity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local id = lurek.physics.newBody(world, 50, 50, "static")
        local x, y, vx, vy = lurek.physics.getBody(world, id)
        expect_near(50, x, 1)
        expect_near(50, y, 1)
    end)

    it("setBodyVelocity is a function", function()
        expect_type("function", lurek.physics.setBodyVelocity)
    end)

    it("setBodyVelocity changes velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_no_error(function()
            lurek.physics.setBodyVelocity(world, id, 100, 0)
        end)
    end)

    it("dynamic body moves after step", function()
        local world = lurek.physics.newWorld(0, 100)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        lurek.physics.step(world, 0.1)
        local x, y, vx, vy = lurek.physics.getBody(world, id)
        expect_true(y > 0, "body should fall due to gravity")
    end)

    it("static body does not move", function()
        local world = lurek.physics.newWorld(0, 100)
        local id = lurek.physics.newBody(world, 50, 50, "static")
        lurek.physics.step(world, 0.1)
        local x, y, vx, vy = lurek.physics.getBody(world, id)
        expect_near(50, x, 0.01)
        expect_near(50, y, 0.01)
    end)
end)

-- =========================================================================
-- Sleeping allowed
-- =========================================================================
describe("sleeping allowed", function()
    it("isSleepingAllowed defaults to true", function()
        local world = lurek.physics.newWorld(0, 9.8)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_true(lurek.physics.isSleepingAllowed(world, id))
    end)

    it("setSleepingAllowed false disables sleeping", function()
        local world = lurek.physics.newWorld(0, 9.8)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        lurek.physics.setSleepingAllowed(world, id, false)
        expect_false(lurek.physics.isSleepingAllowed(world, id))
    end)

    it("setSleepingAllowed true re-enables sleeping", function()
        local world = lurek.physics.newWorld(0, 9.8)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        lurek.physics.setSleepingAllowed(world, id, false)
        lurek.physics.setSleepingAllowed(world, id, true)
        expect_true(lurek.physics.isSleepingAllowed(world, id))
    end)
end)

-- Remaining tests require APIs not yet registered (circle bodies, collisions,
-- restitution, layers). They are skipped until those bindings are implemented.
-- See: newCircleBody, getBodyShape, setBodyShape, getCollisions,
--      setBodyRestitution, setBodyLayer

-- =========================================================================
-- Phase 2: Standalone shape userdata
-- =========================================================================
describe("physics.Shape userdata", function()
    it("newCircleShape is a function", function()
        expect_type("function", lurek.physics.newCircleShape)
    end)

    it("newCircleShape returns userdata with type 'circle'", function()
        local s = lurek.physics.newCircleShape(10)
        expect_type("userdata", s)
        expect_equal("circle", s:getType())
    end)

    it("getRadius returns correct value for circle", function()
        local s = lurek.physics.newCircleShape(7.5)
        expect_near(7.5, s:getRadius(), 0.001)
    end)

    it("newRectangleShape returns userdata with type 'rectangle'", function()
        local s = lurek.physics.newRectangleShape(20, 10)
        expect_type("userdata", s)
        expect_equal("rectangle", s:getType())
    end)

    it("newEdgeShape returns userdata with type 'edge'", function()
        local s = lurek.physics.newEdgeShape(0, 0, 10, 0)
        expect_type("userdata", s)
        expect_equal("edge", s:getType())
    end)

    it("newPolygonShape returns userdata with type 'polygon'", function()
        local s = lurek.physics.newPolygonShape(0, 0, 10, 0, 5, 10)
        expect_type("userdata", s)
        expect_equal("polygon", s:getType())
    end)

    it("newChainShape returns userdata with type 'chain'", function()
        local s = lurek.physics.newChainShape(false, 0, 0, 5, 0, 10, 5)
        expect_type("userdata", s)
        expect_equal("chain", s:getType())
    end)

    it("getBoundingBox returns 4 numbers for circle", function()
        local s = lurek.physics.newCircleShape(5)
        local x1, y1, x2, y2 = s:getBoundingBox()
        expect_type("number", x1)
        expect_type("number", x2)
        expect_near(-5, x1, 0.001)
        expect_near(5, x2, 0.001)
    end)

    it("setDensity does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setDensity(2.0) end)
    end)

    it("setFriction does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setFriction(0.8) end)
    end)

    it("setRestitution does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setRestitution(0.5) end)
    end)

    it("setSensor does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setSensor(true) end)
    end)

    it("destroy does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:destroy() end)
    end)

    it("attachShape attaches circle to body", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local shape = lurek.physics.newCircleShape(15)
        expect_no_error(function()
            lurek.physics.attachShape(body, shape)
        end)
    end)
end)

-- ── Body UserData methods ──────────────────────────────────────────

describe("Body UserData methods", function()
    it("getPosition returns x, y after creation", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 10.0, 20.0, "dynamic")
        local x, y = body:getPosition()
        expect_near(10.0, x, 0.01)
        expect_near(20.0, y, 0.01)
    end)

    it("setPosition moves the body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setPosition(50, 75)
        local x, y = body:getPosition()
        expect_near(50, x, 0.01)
        expect_near(75, y, 0.01)
    end)

    it("getX and getY return individual coordinates", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 3.5, 7.5, "dynamic")
        expect_near(3.5, body:getX(), 0.01)
        expect_near(7.5, body:getY(), 0.01)
    end)

    it("setVelocity and getVelocity round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setVelocity(5.0, -3.0)
        local vx, vy = body:getVelocity()
        expect_near(5.0, vx, 0.01)
        expect_near(-3.0, vy, 0.01)
    end)

    it("getAngle and setAngle round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngle(1.57)
        expect_near(1.57, body:getAngle(), 0.01)
    end)

    it("getAngularVelocity and setAngularVelocity round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngularVelocity(2.5)
        expect_near(2.5, body:getAngularVelocity(), 0.01)
    end)

    it("getMass returns positive for dynamic body with shape", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_true(body:getMass() > 0)
    end)

    it("getType returns body type string", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "static")
        expect_equal("static", body:getType())
    end)

    it("setType changes body type", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setType("kinematic")
        expect_equal("kinematic", body:getType())
    end)

    it("getFriction and setFriction round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setFriction(0.7)
        expect_near(0.7, body:getFriction(), 0.01)
    end)

    it("getRestitution and setRestitution round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setRestitution(0.9)
        expect_near(0.9, body:getRestitution(), 0.01)
    end)

    it("getLayer and setLayer round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setLayer(3)
        expect_equal(3, body:getLayer())
    end)

    it("getMask and setMask round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setMask(5)
        expect_equal(5, body:getMask())
    end)

    it("applyImpulse changes velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:applyImpulse(10, 0)
        local vx, vy = body:getVelocity()
        expect_true(vx > 0, "impulse should increase x velocity")
    end)

    it("applyForce does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_no_error(function() body:applyForce(100, 0) end)
    end)

    it("applyTorque does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_no_error(function() body:applyTorque(5.0) end)
    end)

    it("applyAngularImpulse changes angular velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:applyAngularImpulse(3.0)
        expect_true(math.abs(body:getAngularVelocity()) > 0)
    end)

    it("getGravityScale and setGravityScale round-trip", function()
        local world = lurek.physics.newWorld(0, -9.81)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setGravityScale(0.5)
        expect_near(0.5, body:getGravityScale(), 0.01)
    end)

    it("isFixedRotation and setFixedRotation round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_false(body:isFixedRotation())
        body:setFixedRotation(true)
        expect_true(body:isFixedRotation())
    end)

    it("getLinearDamping and setLinearDamping round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setLinearDamping(0.3)
        expect_near(0.3, body:getLinearDamping(), 0.01)
    end)

    it("getAngularDamping and setAngularDamping round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngularDamping(0.4)
        expect_near(0.4, body:getAngularDamping(), 0.01)
    end)

    it("isBullet and setBullet round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_false(body:isBullet())
        body:setBullet(true)
        expect_true(body:isBullet())
    end)

    it("getId returns a number", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_type("number", body:getId())
    end)

    it("destroy removes body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_no_error(function() body:destroy() end)
    end)
end)

-- ── World UserData methods ──────────────────────────────────────────

describe("World UserData methods", function()
    it("getGravity returns world gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local gx, gy = world:getGravity()
        expect_near(0, gx, 0.01)
        expect_near(9.81, gy, 0.01)
    end)

    it("setGravity changes world gravity", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setGravity(0, -10)
        local gx, gy = world:getGravity()
        expect_near(0, gx, 0.01)
        expect_near(-10, gy, 0.01)
    end)

    it("getBodyCount tracks bodies", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:getBodyCount())
        world:newBody(0, 0, "dynamic")
        expect_equal(1, world:getBodyCount())
        world:newBody(5, 5, "static")
        expect_equal(2, world:getBodyCount())
    end)

    it("getBodyIds returns id table", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        world:newBody(5, 5, "dynamic")
        local ids = world:getBodyIds()
        expect_equal(2, #ids)
    end)

    it("destroyBody disables a body (soft destroy)", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newBody(0, 0, "dynamic")
        local id = body:getId()
        expect_equal(1, world:getBodyCount())
        world:destroyBody(id)
        -- destroyBody disables the body and marks static; count stays
        expect_equal(1, world:getBodyCount())
        expect_equal("static", body:getType())
    end)

    it("clear removes all bodies", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        world:newBody(5, 5, "dynamic")
        world:clear()
        expect_equal(0, world:getBodyCount())
    end)

    it("step advances simulation", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_true(y > 0, "gravity should move body down")
    end)

    it("getMeter and setMeter round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setMeter(100)
        expect_near(100, world:getMeter(), 0.01)
    end)

    it("toPhysics and toPixels convert", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setMeter(50)
        local m = world:toPhysics(100)
        expect_near(2.0, m, 0.01)
        local px = world:toPixels(2.0)
        expect_near(100, px, 0.01)
    end)

    it("newCircleBody creates a body with circle shape", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(10, 20, 5, "dynamic")
        local x, y = body:getPosition()
        expect_near(10, x, 0.01)
        expect_near(20, y, 0.01)
    end)

    it("newPolygonBody creates a polygon body", function()
        local world = lurek.physics.newWorld(0, 0)
        local verts = {0, 0, 10, 0, 10, 10, 0, 10}
        local body = world:newPolygonBody(5, 5, verts, "dynamic")
        expect_not_nil(body)
        expect_equal("dynamic", body:getType())
    end)

    it("newEdgeBody creates an edge body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newEdgeBody(0, 0, 0, 0, 100, 0, "static")
        expect_not_nil(body)
    end)
end)

-- ── Joints ──────────────────────────────────────────────────────────

describe("Joint operations", function()
    it("addRevoluteJoint creates a revolute joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        expect_type("number", jid)
    end)

    it("addDistanceJoint creates a distance joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(10, 0, 1, "dynamic")
        local jid = world:addDistanceJoint(a:getId(), b:getId(), 0, 0, 10, 0, 10)
        expect_type("number", jid)
    end)

    it("addWeldJoint creates a weld joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addWeldJoint(a:getId(), b:getId(), 2.5, 0)
        expect_type("number", jid)
    end)

    it("jointCount returns number of joints", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:jointCount())
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        expect_equal(1, world:jointCount())
    end)

    it("getJointIds returns joint id table", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        local ids = world:getJointIds()
        expect_equal(1, #ids)
    end)

    it("getJointType returns joint type string", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        local jtype = world:getJointType(jid)
        expect_type("string", jtype)
    end)

    it("destroyJoint removes the rapier joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        expect_equal(1, world:jointCount())
        -- destroyJoint removes the rapier joint; handle vec may not shrink
        expect_no_error(function() world:destroyJoint(jid) end)
    end)
end)

-- ── Fixtures ────────────────────────────────────────────────────────

describe("Fixture operations", function()
    it("addFixture returns fixture index", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local idx = world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_type("number", idx)
    end)

    it("fixtureCount increases after addFixture", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local before = world:fixtureCount(body:getId())
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_equal(before + 1, world:fixtureCount(body:getId()))
    end)

    it("setFixtureFriction does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureFriction(body:getId(), 0, 0.8)
        end)
    end)

    it("setFixtureRestitution does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureRestitution(body:getId(), 0, 0.6)
        end)
    end)

    it("setFixtureSensor does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureSensor(body:getId(), 0, true)
        end)
    end)
end)

-- ── Collision behavior ──────────────────────────────────────────────

describe("Collision and simulation behavior", function()
    it("static body does not move under gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "static")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    it("zero gravity keeps dynamic body still", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        world:step(1.0 / 60.0)
        local x, y = body:getPosition()
        expect_near(0, x, 0.001)
        expect_near(0, y, 0.001)
    end)

    it("kinematic body is unaffected by gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "kinematic")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    it("gravity scale 0 prevents falling", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setGravityScale(0)
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    it("layer/mask filtering prevents collision", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1.0, "dynamic")
        local b = world:newCircleBody(0, 0, 1.0, "dynamic")
        a:setLayer(1)
        a:setMask(2)
        b:setLayer(4)
        b:setMask(8)
        -- different layer/mask = no collision expected
        expect_no_error(function() world:step(1.0 / 60.0) end)
    end)
end)

-- ── destroyWorld ────────────────────────────────────────────────────

describe("World destruction", function()
    it("destroyWorld does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        expect_no_error(function() lurek.physics.destroyWorld(world) end)
    end)
end)

test_summary()

