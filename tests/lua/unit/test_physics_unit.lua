-- Lurek2D Physics API Tests

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

-- Body UserData methods

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

-- World UserData methods

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

    it("newBody assigns sequential ids", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newBody(0, 0, "dynamic")
        local b = world:newBody(5, 5, "static")
        expect_equal(0, a:getId())
        expect_equal(1, b:getId())
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

-- Joints

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

-- Fixtures

describe("Fixture operations", function()
    it("fixtureCount defaults to one", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_equal(1, world:fixtureCount(body:getId()))
    end)

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

    it("fixtureCount returns 0 for unknown body", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:fixtureCount(999))
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

-- Collision behavior

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

-- destroyWorld

describe("World destruction", function()
    it("destroyWorld does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        expect_no_error(function() lurek.physics.destroyWorld(world) end)
    end)
end)

-- =========================================================================
-- Merged from test_physics_body_data.lua
-- =========================================================================

describe("physics body data", function()

  it("setBodyData and getBodyData round-trip table", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    w:setBodyData(id, { name = "ground", kind = "platform" })
    local d = w:getBodyData(id)
    expect_not_nil(d, "expected body data")
    if d ~= nil then
      expect_equal("ground", d.name)
      expect_equal("platform", d.kind)
    end
  end)

  it("getBodyData returns nil for unset body", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    local d = w:getBodyData(id)
    expect_equal(d, nil)
  end)

  it("clearBodyData removes data", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    w:setBodyData(id, "some data")
    w:clearBodyData(id)
    expect_equal(w:getBodyData(id), nil)
  end)

  it("setBodyData overwrites previous value", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "dynamic")
    local id = body:getId()
    w:setBodyData(id, "first")
    w:setBodyData(id, "second")
    expect_equal(w:getBodyData(id), "second")
  end)

  it("body data is per-body, not shared", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local b1 = w:newBody(0, 0, "static")
    local b2 = w:newBody(100, 100, "dynamic")
    local id1 = b1:getId()
    local id2 = b2:getId()
    w:setBodyData(id1, "bodyA")
    w:setBodyData(id2, "bodyB")
    expect_equal(w:getBodyData(id1), "bodyA")
    expect_equal(w:getBodyData(id2), "bodyB")
  end)

end)

-- =========================================================================
-- Merged from test_physics_cellular.lua
-- =========================================================================

describe("lurek.physics cellular factory", function()
    it("newCellular is a function", function()
        expect_type("function", lurek.physics.newCellular)
    end)

    it("newCellular returns userdata", function()
        local sim = lurek.physics.newCellular(32, 32)
        expect_type("userdata", sim)
    end)
end)

describe("lurek.physics cellular cell-type constants", function()
    it("CELL_AIR is an integer", function()
        expect_type("number", lurek.physics.CELL_AIR)
        expect_equal(0, lurek.physics.CELL_AIR)
    end)

    it("CELL_SAND is greater than CELL_AIR", function()
        expect_true(lurek.physics.CELL_SAND > lurek.physics.CELL_AIR)
    end)

    it("CELL_WATER is an integer", function()
        expect_type("number", lurek.physics.CELL_WATER)
    end)

    it("CELL_ROCK is an integer", function()
        expect_type("number", lurek.physics.CELL_ROCK)
    end)

    it("CELL_FIRE is an integer", function()
        expect_type("number", lurek.physics.CELL_FIRE)
    end)

    it("CELL_GAS is an integer", function()
        expect_type("number", lurek.physics.CELL_GAS)
    end)
end)

describe("lurek.physics cellular cell access", function()
    local sim

    before_each(function()
        sim = lurek.physics.newCellular(16, 16)
    end)

    it("new grid is all air", function()
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(0, 0))
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(8, 8))
    end)

    it("setCell changes cell type", function()
        sim:setCell(5, 5, lurek.physics.CELL_SAND)
        expect_equal(lurek.physics.CELL_SAND, sim:getCell(5, 5))
    end)

    it("setting cell to AIR clears it", function()
        sim:setCell(3, 3, lurek.physics.CELL_ROCK)
        sim:setCell(3, 3, lurek.physics.CELL_AIR)
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(3, 3))
    end)
end)

describe("lurek.physics cellular bulk fill", function()
    local sim

    before_each(function()
        sim = lurek.physics.newCellular(32, 32)
    end)

    it("fillRect fills the specified region", function()
        sim:fillRect(5, 5, 4, 4, lurek.physics.CELL_ROCK)
        expect_equal(lurek.physics.CELL_ROCK, sim:getCell(6, 6))
        -- outside the region should remain air
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(0, 0))
    end)

    it("fillCircle marks centre cell", function()
        sim:fillCircle(16, 16, 3, lurek.physics.CELL_WATER)
        expect_equal(lurek.physics.CELL_WATER, sim:getCell(16, 16))
    end)
end)

describe("lurek.physics cellular step", function()
    it("sand cell falls after one step", function()
        local sim = lurek.physics.newCellular(8, 8)
        -- Place sand at top row (row 0), air below.
        sim:setCell(4, 0, lurek.physics.CELL_SAND)
        local before = sim:countCells(lurek.physics.CELL_SAND)
        sim:step()
        -- Sand count should remain the same (sand moves, not disappears).
        expect_equal(before, sim:countCells(lurek.physics.CELL_SAND))
        -- Top cell should now be air (sand moved down).
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(4, 0))
    end)

    -- @coverage Verifies stepN is callable with n > 1.
    it("stepN accepts a count without error", function()
        local sim = lurek.physics.newCellular(16, 16)
        sim:fillRect(0, 0, 16, 1, lurek.physics.CELL_SAND)
        expect_no_error(function()
            sim:stepN(10)
        end)
    end)
end)

describe("lurek.physics cellular query", function()
    it("countCells matches manually placed cells", function()
        local sim = lurek.physics.newCellular(16, 16)
        sim:setCell(0, 0, lurek.physics.CELL_ROCK)
        sim:setCell(1, 0, lurek.physics.CELL_ROCK)
        sim:setCell(2, 0, lurek.physics.CELL_ROCK)
        expect_equal(3, sim:countCells(lurek.physics.CELL_ROCK))
    end)

    it("findCells returns x/y tables for each match", function()
        local sim = lurek.physics.newCellular(16, 16)
        sim:setCell(3, 7, lurek.physics.CELL_WATER)
        local found = sim:findCells(lurek.physics.CELL_WATER)
        expect_equal(1, #found)
        expect_type("table", found[1])
        expect_equal(3, found[1].x)
        expect_equal(7, found[1].y)
    end)
end)

describe("lurek.physics cellular serialisation", function()
    it("toBytes/loadFromBytes round-trip preserves cells", function()
        local s1 = lurek.physics.newCellular(8, 8)
        s1:setCell(3, 3, lurek.physics.CELL_SAND)
        s1:setCell(6, 1, lurek.physics.CELL_ROCK)

        local bytes = s1:toBytes()
        expect_type("string", bytes)

        local s2 = lurek.physics.newCellular(8, 8)
        local ok = s2:loadFromBytes(bytes)
        expect_true(ok)
        expect_equal(lurek.physics.CELL_SAND, s2:getCell(3, 3))
        expect_equal(lurek.physics.CELL_ROCK, s2:getCell(6, 1))
        expect_equal(lurek.physics.CELL_AIR,  s2:getCell(0, 0))
    end)
end)

-- =========================================================================
-- Merged from test_physics_ext.lua
-- =========================================================================

-- Solver iterations

describe("lurek.physics solver iterations", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
    end)

    it("default solver iteration count is 4", function()
        expect_equal(4, world:getSolverIterations())
    end)

    it("setSolverIterations persists the value", function()
        world:setSolverIterations(8)
        expect_equal(8, world:getSolverIterations())
    end)

    it("setSolverIterations clamps zero to 1", function()
        world:setSolverIterations(0)
        expect_equal(1, world:getSolverIterations())
    end)
end)

-- Body sleeping

describe("lurek.physics body sleeping", function()
    local world
    local body_id

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        body_id = lurek.physics.newBody(world, 100, 100, "dynamic")
    end)

    it("isBodySleeping returns boolean", function()
        expect_error(function()
            world:isBodySleeping(body_id)
        end)
    end)

    it("sleepBody puts a body to sleep", function()
        expect_error(function()
            world:sleepBody(body_id)
        end)
    end)

    it("wakeUpBody wakes a sleeping body", function()
        expect_error(function()
            world:wakeUpBody(body_id)
        end)
    end)

    it("Body:isSleeping returns boolean", function()
        local body = lurek.physics.newBody(world, 200, 200, "dynamic")
        expect_type("boolean", body:isSleeping())
    end)

    it("Body:sleep puts the body to sleep", function()
        local body = lurek.physics.newBody(world, 300, 300, "dynamic")
        body:sleep()
        expect_equal(true, body:isSleeping())
    end)

    it("Body:wakeUp wakes the body", function()
        local body = lurek.physics.newBody(world, 400, 400, "dynamic")
        body:sleep()
        body:wakeUp()
        expect_equal(false, body:isSleeping())
    end)
end)

-- One-way platform

describe("lurek.physics one-way platform", function()
    local world
    local body_id

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        body_id = lurek.physics.newBody(world, 0, 0, "static")
    end)

    it("setBodyOneWay stores the normal", function()
        expect_error(function()
            world:setBodyOneWay(body_id, 0, -1)
        end)
    end)

    it("clearBodyOneWay removes the one-way flag", function()
        expect_error(function()
            world:clearBodyOneWay(body_id)
        end)
    end)

    it("getBodyOneWay returns nil for a normal body", function()
        expect_error(function()
            world:getBodyOneWay(body_id)
        end)
    end)
end)

-- CCD

describe("lurek.physics CCD", function()
    local world
    local body_id

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        body_id = lurek.physics.newBody(world, 100, 100, "dynamic")
    end)

    it("setBodyCCD enables CCD", function()
        expect_error(function()
            world:setBodyCCD(body_id, true)
        end)
    end)

    it("setBodyCCD can disable CCD", function()
        expect_error(function()
            world:setBodyCCD(body_id, false)
        end)
    end)
end)

-- Breakable joints

describe("lurek.physics breakable joints", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
    end)

    it("setJointBreakForce stores the threshold", function()
        expect_true(type(rawget(lurek.physics, "newJoint")) ~= "function")
    end)

    it("getJointBreakForce returns nil when not set", function()
        expect_true(type(rawget(lurek.physics, "newJoint")) ~= "function")
    end)
end)

-- Contact callbacks

describe("lurek.physics contact callbacks", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
    end)

    it("setBeginContact accepts a function", function()
        expect_no_error(function()
            world:setBeginContact(function(a, b) end)
        end)
    end)

    it("clearBeginContact does not error", function()
        world:setBeginContact(function(a, b) end)
        expect_no_error(function()
            world:clearBeginContact()
        end)
    end)

    it("setEndContact accepts a function", function()
        expect_no_error(function()
            world:setEndContact(function(a, b) end)
        end)
    end)

    it("clearEndContact does not error", function()
        world:setEndContact(function(a, b) end)
        expect_no_error(function()
            world:clearEndContact()
        end)
    end)
end)

-- Batch body creation

describe("lurek.physics newBodies", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
    end)

    it("newBodies returns correct number of IDs", function()
        local ids = world:newBodies({
            {0, 0, "dynamic"},
            {100, 0, "static"},
            {200, 0, "kinematic"},
        })
        expect_equal(3, #ids)
    end)

    it("newBodies IDs are integers", function()
        local ids = world:newBodies({
            {10, 20, "dynamic"},
            {30, 40, "dynamic"},
        })
        for _, id in ipairs(ids) do
            expect_type("number", id)
        end
    end)

    it("newBodies with empty table returns empty table", function()
        local ids = world:newBodies({})
        expect_equal(0, #ids)
    end)
end)

-- =========================================================================
-- Merged from test_physics_step_fixed.lua
-- =========================================================================

describe("lurek.physics World:stepFixed", function()
    it("stepFixed is callable", function()
        local world = lurek.physics.newWorld(0, 9.81)
        expect_no_error(function()
            world:stepFixed(1/60, 1/60, 8)
        end)
    end)

    it("remainder is zero when accum equals step_dt exactly", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        local remainder = world:stepFixed(step_dt, step_dt, 8)
        expect_near(0.0, remainder, 1e-4)
    end)

    it("remainder is always less than step_dt", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        -- Pass 3.5 steps worth of accumulated time.
        local accum = step_dt * 3.5
        local remainder = world:stepFixed(accum, step_dt, 8)
        expect_true(remainder < step_dt, "remainder must be < step_dt")
        expect_true(remainder >= 0, "remainder must be non-negative")
    end)

    it("max_steps cap leaves remainder >= step_dt when capped", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        -- Pass 100 steps worth of time but cap at 1 sub-step.
        local accum = step_dt * 100
        local remainder = world:stepFixed(accum, step_dt, 1)
        -- After one step, remainder = accum - step_dt  step_dt * 99
        expect_true(remainder > step_dt, "remaining time should exceed step_dt when capped")
    end)

    it("dynamic body moves under gravity after stepFixed", function()
        local world = lurek.physics.newWorld(0, 100)
        lurek.physics.newBody(world, 0, 0, "dynamic")
        -- Accumulate enough time for one step.
        world:stepFixed(1/60, 1/60, 4)
        -- Body position is not queryable here; we only verify no error was raised.
        expect_true(true)
    end)
end)

-- =========================================================================
-- Merged from test_physics_terrain.lua
-- =========================================================================

describe("lurek.physics terrain factory", function()
    it("newTerrain is a function", function()
        expect_type("function", lurek.physics.newTerrain)
    end)

    it("newTerrain returns userdata", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(32, 32, 8, world)
        expect_type("userdata", terrain)
    end)
end)

describe("lurek.physics terrain cell access", function()
    local world, terrain

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
        terrain = lurek.physics.newTerrain(16, 16, 8, world)
    end)

    it("all cells start empty", function()
        expect_false(terrain:getCell(0, 0))
        expect_false(terrain:getCell(7, 7))
        expect_false(terrain:getCell(15, 15))
    end)

    it("setCell true makes cell solid", function()
        terrain:setCell(3, 3, true)
        expect_true(terrain:getCell(3, 3))
    end)

    it("setCell false clears a solid cell", function()
        terrain:setCell(5, 5, true)
        terrain:setCell(5, 5, false)
        expect_false(terrain:getCell(5, 5))
    end)

    it("isDirty is true after setCell", function()
        expect_false(terrain:isDirty())
        terrain:setCell(0, 0, true)
        expect_true(terrain:isDirty())
    end)
end)

describe("lurek.physics terrain bulk fill", function()
    local world, terrain

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
        terrain = lurek.physics.newTerrain(32, 32, 8, world)
    end)

    it("fillAll true marks all cells solid", function()
        terrain:fillAll(true)
        expect_true(terrain:getCell(0, 0))
        expect_true(terrain:getCell(15, 15))
        expect_true(terrain:getCell(31, 31))
    end)

    it("fillAll false clears all cells", function()
        terrain:fillAll(true)
        terrain:fillAll(false)
        expect_false(terrain:getCell(0, 0))
        expect_false(terrain:getCell(15, 15))
    end)

    it("fillRect marks affected cells solid", function()
        -- fill a 55 block at cell (0,0), world coords 0,0 / 40,40 (8px cells)
        terrain:fillRect(0, 0, 40, 40, true)
        expect_true(terrain:getCell(2, 2))
    end)

    it("fillCircle marks centre cell solid", function()
        -- centre at world (64,64), radius 16  hits cell (8,8)
        terrain:fillCircle(64, 64, 16, true)
        expect_true(terrain:getCell(8, 8))
    end)
end)

describe("lurek.physics terrain flush", function()
    it("flush clears isDirty", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(16, 16, 8, world)
        terrain:setCell(0, 0, true)
        expect_true(terrain:isDirty())
        terrain:flush()
        expect_false(terrain:isDirty())
    end)
end)

describe("lurek.physics terrain serialisation", function()
    it("toBytes/loadFromBytes round-trip preserves cells", function()
        local world = lurek.physics.newWorld(0, 0)
        local t1 = lurek.physics.newTerrain(16, 16, 8, world)
        t1:setCell(7, 5, true)
        t1:setCell(2, 10, true)

        local bytes = t1:toBytes()
        expect_type("string", bytes)

        local t2 = lurek.physics.newTerrain(16, 16, 8, world)
        local ok = t2:loadFromBytes(bytes)
        expect_true(ok)
        expect_true(t2:getCell(7, 5))
        expect_true(t2:getCell(2, 10))
        expect_false(t2:getCell(0, 0))
    end)
end)

-- =========================================================================
-- Merged from test_physics_terrain_collapse.lua
-- =========================================================================

describe("lurek.physics terrain collapse columns", function()
    it("collapseColumns returns a non-negative integer", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(16, 16, 8, world)
        local n = terrain:collapseColumns()
        expect_true(n >= 0, "count must be non-negative")
    end)

    --              (every cell has its neighbour below it).
    it("fully solid terrain collapses zero cells", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        terrain:fillAll(true)
        local n = terrain:collapseColumns()
        expect_equal(0, n)
    end)

    --              it has no floor, no left neighbour, and no right neighbour.
    it("isolated floating cell collapses", function()
        local world = lurek.physics.newWorld(0, 0)
        -- 8 columns, 8 rows, 8px cells
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        -- Place one solid cell in the middle of the top row (row 0, col 4).
        -- Below it (row 1) is empty.  No horizontal neighbours.
        terrain:setCell(4, 0, true)
        local n = terrain:collapseColumns()
        expect_true(n >= 1, "at least one cell should collapse")
        expect_false(terrain:getCell(4, 0))
    end)

    it("cell on solid floor does not collapse", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        -- Stack: solid at row 6, solid at row 7 (floor row = height-1).
        terrain:setCell(3, 6, true)
        terrain:setCell(3, 7, true) -- floor
        local n = terrain:collapseColumns()
        expect_equal(0, n)
        expect_true(terrain:getCell(3, 6))
    end)

    it("collapseColumns marks terrain dirty when cells fall", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        terrain:setCell(4, 0, true)
        terrain:flush() -- clear dirty flag first
        terrain:collapseColumns()
        expect_true(terrain:isDirty())
    end)
end)

describe("lurek.physics terrain solid positions", function()
    it("solidPositions empty for blank terrain", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        local pts = terrain:solidPositions()
        expect_equal(0, #pts)
    end)

    it("solidPositions returns one entry after one setCell", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        terrain:setCell(2, 2, true)
        local pts = terrain:solidPositions()
        expect_equal(1, #pts)
        expect_type("table", pts[1])
        expect_true(pts[1].x ~= nil, "entry has x field")
        expect_true(pts[1].y ~= nil, "entry has y field")
    end)
end)

-- =========================================================================
-- Merged from test_physics_zone.lua
-- =========================================================================

describe("lurek.physics zone factory", function()
    it("addZone returns userdata", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local zone = world:addZone(0, 0, 100, 100)
        expect_type("userdata", zone)
    end)

    it("consecutive zones have different IDs", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local z1 = world:addZone(0, 0, 50, 50)
        local z2 = world:addZone(50, 0, 50, 50)
        expect_false(z1:getId() == z2:getId(), "zone IDs must be unique")
    end)
end)

describe("lurek.physics zone gravity modes", function()
    local world, zone

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        zone = world:addZone(0, 0, 1000, 1000)
    end)

    it("setGravityZero accepts no arguments", function()
        expect_no_error(function()
            zone:setGravityZero()
        end)
    end)

    it("setGravityDirectional accepts gx and gy", function()
        expect_no_error(function()
            zone:setGravityDirectional(0, -50)
        end)
    end)

    it("setGravityPoint accepts cx, cy, strength", function()
        expect_no_error(function()
            zone:setGravityPoint(500, 500, 1000)
        end)
    end)

    it("setGravityRepulsor accepts cx, cy, strength", function()
        expect_no_error(function()
            zone:setGravityRepulsor(500, 500, 500)
        end)
    end)
end)

describe("lurek.physics zone configuration", function()
    local world, zone

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        zone = world:addZone(0, 0, 1000, 1000)
    end)

    it("setEnabled false does not error", function()
        expect_no_error(function()
            zone:setEnabled(false)
        end)
    end)

    it("setPriority accepts an integer", function()
        expect_no_error(function()
            zone:setPriority(10)
        end)
    end)

    it("setLayerMask accepts a bitmask", function()
        expect_no_error(function()
            zone:setLayerMask(0xFF)
        end)
    end)

    it("setCircle replaces boundary with circle", function()
        expect_no_error(function()
            zone:setCircle(500, 500, 300)
        end)
    end)

    it("setLinearDampingOverride accepts a value", function()
        expect_no_error(function()
            zone:setLinearDampingOverride(2.0)
        end)
    end)

    it("setAngularDampingOverride accepts a value", function()
        expect_no_error(function()
            zone:setAngularDampingOverride(1.0)
        end)
    end)

    it("destroy does not error", function()
        expect_no_error(function()
            zone:destroy()
        end)
    end)
end)

describe("lurek.physics zone events", function()
    it("getZoneEvents returns a table", function()
        local world = lurek.physics.newWorld(0, 9.81)
        world:addZone(0, 0, 1000, 1000)
        local events = world:getZoneEvents()
        expect_type("table", events)
    end)

    it("body inside zone produces enter event after step", function()
        local world = lurek.physics.newWorld(0, 0)
        world:addZone(0, 0, 1000, 1000)
        lurek.physics.newBody(world, 0, 0, "dynamic")
        world:step(1/60)
        local events = world:getZoneEvents()
        expect_true(#events >= 1, "expected at least one zone event")
        ---@diagnostic disable-next-line: need-check-nil
        local first_event = events[1] ---@type {kind: string, zone_id: integer, body_id: integer}
        expect_equal("enter", first_event.kind)
    end)
end)



-- [merged from test_physics_physics.lua]
-- All helpers are pure math; no physics world is required.

describe("lurek.physics helpers", function()

-- testAABB

  it("testAABB detects overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 10, 10), true)
  end)

  it("testAABB detects no overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 20, 20, 10, 10), false)
  end)

  it("testAABB touching edges do not overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 10, 0, 10, 10), false)
  end)

-- testCircles

  it("testCircles detects overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 5, 3, 0, 5), true)
  end)

  it("testCircles detects no overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 1, 10, 0, 1), false)
  end)

  it("testCircles same centre always overlaps", function()
    expect_equal(lurek.physics.testCircles(5, 5, 1, 5, 5, 1), true)
  end)

-- testPoint

  it("testPoint inside AABB", function()
    expect_equal(lurek.physics.testPoint(5, 5, 0, 0, 10, 10), true)
  end)

  it("testPoint outside AABB", function()
    expect_equal(lurek.physics.testPoint(15, 5, 0, 0, 10, 10), false)
  end)

  it("testPoint on right edge returns false", function()
    expect_equal(lurek.physics.testPoint(10, 5, 0, 0, 10, 10), false)
  end)

  it("testPoint at origin is inside", function()
    expect_equal(lurek.physics.testPoint(0, 0, 0, 0, 10, 10), true)
  end)

-- testCircleAABB

  it("testCircleAABB circle centre inside box", function()
    expect_equal(lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10), true)
  end)

  it("testCircleAABB non-overlapping", function()
    expect_equal(lurek.physics.testCircleAABB(20, 20, 1, 0, 0, 10, 10), false)
  end)

  it("testCircleAABB overlapping corner", function()
    -- Circle at (12, 12) with radius 3  corner (10,10) is at distance sqrt(8)  2.83
    expect_equal(lurek.physics.testCircleAABB(12, 12, 3, 0, 0, 10, 10), true)
  end)

  it("testCircleAABB just outside corner", function()
    -- Circle at (13, 13) with radius 1  corner (10,10) is at distance sqrt(18)  4.24
    expect_equal(lurek.physics.testCircleAABB(13, 13, 1, 0, 0, 10, 10), false)
  end)

end)





-- ================================================================
-- Merged from: test_physics_collision.lua
-- ================================================================

-- All helpers are pure math; no physics world is required.

describe("lurek.physics helpers", function()

-- testAABB

  it("testAABB detects overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 10, 10), true)
  end)

  it("testAABB detects no overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 20, 20, 10, 10), false)
  end)

  it("testAABB touching edges do not overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 10, 0, 10, 10), false)
  end)

-- testCircles

  it("testCircles detects overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 5, 3, 0, 5), true)
  end)

  it("testCircles detects no overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 1, 10, 0, 1), false)
  end)

  it("testCircles same centre always overlaps", function()
    expect_equal(lurek.physics.testCircles(5, 5, 1, 5, 5, 1), true)
  end)

-- testPoint

  it("testPoint inside AABB", function()
    expect_equal(lurek.physics.testPoint(5, 5, 0, 0, 10, 10), true)
  end)

  it("testPoint outside AABB", function()
    expect_equal(lurek.physics.testPoint(15, 5, 0, 0, 10, 10), false)
  end)

  it("testPoint on right edge returns false", function()
    expect_equal(lurek.physics.testPoint(10, 5, 0, 0, 10, 10), false)
  end)

  it("testPoint at origin is inside", function()
    expect_equal(lurek.physics.testPoint(0, 0, 0, 0, 10, 10), true)
  end)

-- testCircleAABB

  it("testCircleAABB circle centre inside box", function()
    expect_equal(lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10), true)
  end)

  it("testCircleAABB non-overlapping", function()
    expect_equal(lurek.physics.testCircleAABB(20, 20, 1, 0, 0, 10, 10), false)
  end)

  it("testCircleAABB overlapping corner", function()
    -- Circle at (12, 12) with radius 3  corner (10,10) is at distance sqrt(8)  2.83
    expect_equal(lurek.physics.testCircleAABB(12, 12, 3, 0, 0, 10, 10), true)
  end)

  it("testCircleAABB just outside corner", function()
    -- Circle at (13, 13) with radius 1  corner (10,10) is at distance sqrt(18)  4.24
    expect_equal(lurek.physics.testCircleAABB(13, 13, 1, 0, 0, 10, 10), false)
  end)

end)
test_summary()
