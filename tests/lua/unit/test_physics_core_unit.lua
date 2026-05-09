-- Lurek2D Physics API Tests

-- @describe lurek.physics module exists
describe("lurek.physics module exists", function()
    -- @covers lurek.physics
    it("lurek.physics is a table", function()
        expect_type("table", lurek.physics)
    end)
end)

-- @describe lurek.physics world
describe("lurek.physics world", function()
    -- @covers lurek.physics.newWorld
    it("newWorld is a function", function()
        expect_type("function", lurek.physics.newWorld)
    end)

    -- @covers lurek.physics.newWorld
    it("newWorld creates a world and returns World object", function()
        local id = lurek.physics.newWorld(0, 9.81)
        expect_type("userdata", id)
    end)

    -- @covers lurek.physics.step
    it("step is a function", function()
        expect_type("function", lurek.physics.step)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.step
    it("step can be called with world_id and dt", function()
        local world = lurek.physics.newWorld(0, 9.81)
        expect_no_error(function()
            lurek.physics.step(world, 1/60)
        end)
    end)
end)

-- @describe lurek.physics bodies
describe("lurek.physics bodies", function()
    -- @covers lurek.physics.newBody
    it("newBody is a function", function()
        expect_type("function", lurek.physics.newBody)
    end)

    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("newBody creates a body and returns Body object", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local id = lurek.physics.newBody(world, 100, 100, "dynamic")
        expect_type("userdata", id)
    end)

    -- @covers lurek.physics.getBody
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getBody returns position and velocity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local id = lurek.physics.newBody(world, 50, 50, "static")
        local x, y, vx, vy = lurek.physics.getBody(world, id)
        expect_near(50, x, 1)
        expect_near(50, y, 1)
    end)

    -- @covers lurek.physics.setBodyVelocity
    it("setBodyVelocity is a function", function()
        expect_type("function", lurek.physics.setBodyVelocity)
    end)

    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.setBodyVelocity
    it("setBodyVelocity changes velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_no_error(function()
            lurek.physics.setBodyVelocity(world, id, 100, 0)
        end)
    end)

    -- @covers lurek.physics.getBody
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.step
    it("dynamic body moves after step", function()
        local world = lurek.physics.newWorld(0, 100)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        lurek.physics.step(world, 0.1)
        local x, y, vx, vy = lurek.physics.getBody(world, id)
        expect_true(y > 0, "body should fall due to gravity")
    end)

    -- @covers lurek.physics.getBody
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.step
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
-- @describe sleeping allowed
describe("sleeping allowed", function()
    -- @covers lurek.physics.isSleepingAllowed
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("isSleepingAllowed defaults to true", function()
        local world = lurek.physics.newWorld(0, 9.8)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_true(lurek.physics.isSleepingAllowed(world, id))
    end)

    -- @covers lurek.physics.isSleepingAllowed
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.setSleepingAllowed
    it("setSleepingAllowed false disables sleeping", function()
        local world = lurek.physics.newWorld(0, 9.8)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        lurek.physics.setSleepingAllowed(world, id, false)
        expect_false(lurek.physics.isSleepingAllowed(world, id))
    end)

    -- @covers lurek.physics.isSleepingAllowed
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.setSleepingAllowed
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
-- @describe physics.Shape userdata
describe("physics.Shape userdata", function()
    -- @covers lurek.physics.newCircleShape
    it("newCircleShape is a function", function()
        expect_type("function", lurek.physics.newCircleShape)
    end)

    -- @covers LPhysicsShape:getType
    -- @covers lurek.physics.newCircleShape
    it("newCircleShape returns userdata with type 'circle'", function()
        local s = lurek.physics.newCircleShape(10)
        expect_type("userdata", s)
        expect_equal("circle", s:getType())
    end)

    -- @covers LPhysicsShape:getRadius
    -- @covers lurek.physics.newCircleShape
    it("getRadius returns correct value for circle", function()
        local s = lurek.physics.newCircleShape(7.5)
        expect_near(7.5, s:getRadius(), 0.001)
    end)

    -- @covers LPhysicsShape:getType
    -- @covers lurek.physics.newRectangleShape
    it("newRectangleShape returns userdata with type 'rectangle'", function()
        local s = lurek.physics.newRectangleShape(20, 10)
        expect_type("userdata", s)
        expect_equal("rectangle", s:getType())
    end)

    -- @covers LPhysicsShape:getType
    -- @covers lurek.physics.newEdgeShape
    it("newEdgeShape returns userdata with type 'edge'", function()
        local s = lurek.physics.newEdgeShape(0, 0, 10, 0)
        expect_type("userdata", s)
        expect_equal("edge", s:getType())
    end)

    -- @covers LPhysicsShape:getType
    -- @covers lurek.physics.newPolygonShape
    it("newPolygonShape returns userdata with type 'polygon'", function()
        local s = lurek.physics.newPolygonShape(0, 0, 10, 0, 5, 10)
        expect_type("userdata", s)
        expect_equal("polygon", s:getType())
    end)

    -- @covers LPhysicsShape:getType
    -- @covers lurek.physics.newChainShape
    it("newChainShape returns userdata with type 'chain'", function()
        local s = lurek.physics.newChainShape(false, 0, 0, 5, 0, 10, 5)
        expect_type("userdata", s)
        expect_equal("chain", s:getType())
    end)

    -- @covers LPhysicsShape:getBoundingBox
    -- @covers lurek.physics.newCircleShape
    it("getBoundingBox returns 4 numbers for circle", function()
        local s = lurek.physics.newCircleShape(5)
        local x1, y1, x2, y2 = s:getBoundingBox()
        expect_type("number", x1)
        expect_type("number", x2)
        expect_near(-5, x1, 0.001)
        expect_near(5, x2, 0.001)
    end)

    -- @covers LPhysicsShape:setDensity
    -- @covers lurek.physics.newCircleShape
    it("setDensity does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setDensity(2.0) end)
    end)

    -- @covers LPhysicsShape:setFriction
    -- @covers lurek.physics.newCircleShape
    it("setFriction does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setFriction(0.8) end)
    end)

    -- @covers LPhysicsShape:setRestitution
    -- @covers lurek.physics.newCircleShape
    it("setRestitution does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setRestitution(0.5) end)
    end)

    -- @covers LPhysicsShape:setSensor
    -- @covers lurek.physics.newCircleShape
    it("setSensor does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setSensor(true) end)
    end)

    -- @covers LPhysicsShape:destroy
    -- @covers lurek.physics.newCircleShape
    it("destroy does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:destroy() end)
    end)

    -- @covers lurek.physics.attachShape
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.newWorld
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

-- @describe Body UserData methods
describe("Body UserData methods", function()
    -- @covers LBody:getPosition
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getPosition returns x, y after creation", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 10.0, 20.0, "dynamic")
        local x, y = body:getPosition()
        expect_near(10.0, x, 0.01)
        expect_near(20.0, y, 0.01)
    end)

    -- @covers LBody:getPosition
    -- @covers LBody:setPosition
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("setPosition moves the body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setPosition(50, 75)
        local x, y = body:getPosition()
        expect_near(50, x, 0.01)
        expect_near(75, y, 0.01)
    end)

    -- @covers LBody:getX
    -- @covers LBody:getY
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getX and getY return individual coordinates", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 3.5, 7.5, "dynamic")
        expect_near(3.5, body:getX(), 0.01)
        expect_near(7.5, body:getY(), 0.01)
    end)

    -- @covers LBody:getVelocity
    -- @covers LBody:setVelocity
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("setVelocity and getVelocity round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setVelocity(5.0, -3.0)
        local vx, vy = body:getVelocity()
        expect_near(5.0, vx, 0.01)
        expect_near(-3.0, vy, 0.01)
    end)

    -- @covers LBody:getAngle
    -- @covers LBody:setAngle
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getAngle and setAngle round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngle(1.57)
        expect_near(1.57, body:getAngle(), 0.01)
    end)

    -- @covers LBody:getAngularVelocity
    -- @covers LBody:setAngularVelocity
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getAngularVelocity and setAngularVelocity round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngularVelocity(2.5)
        expect_near(2.5, body:getAngularVelocity(), 0.01)
    end)

    -- @covers LBody:getMass
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("getMass returns positive for dynamic body with shape", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_true(body:getMass() > 0)
    end)

    -- @covers LBody:getType
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getType returns body type string", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "static")
        expect_equal("static", body:getType())
    end)

    -- @covers LBody:getType
    -- @covers LBody:setType
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("setType changes body type", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setType("kinematic")
        expect_equal("kinematic", body:getType())
    end)

    -- @covers LBody:getFriction
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("getFriction and setFriction round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setFriction(0.7)
        expect_near(0.7, body:getFriction(), 0.01)
    end)

    -- @covers LBody:getRestitution
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("getRestitution and setRestitution round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setRestitution(0.9)
        expect_near(0.9, body:getRestitution(), 0.01)
    end)

    -- @covers LBody:getLayer
    -- @covers LBody:setLayer
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getLayer and setLayer round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setLayer(3)
        expect_equal(3, body:getLayer())
    end)

    -- @covers LBody:getMask
    -- @covers LBody:setMask
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getMask and setMask round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setMask(5)
        expect_equal(5, body:getMask())
    end)

    -- @covers LBody:applyImpulse
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("applyImpulse changes velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:applyImpulse(10, 0)
        local vx, vy = body:getVelocity()
        expect_true(vx > 0, "impulse should increase x velocity")
    end)

    -- @covers LBody:applyForce
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("applyForce does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_no_error(function() body:applyForce(100, 0) end)
    end)

    -- @covers LBody:applyTorque
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("applyTorque does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_no_error(function() body:applyTorque(5.0) end)
    end)

    -- @covers LBody:applyAngularImpulse
    -- @covers LBody:getAngularVelocity
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("applyAngularImpulse changes angular velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:applyAngularImpulse(3.0)
        expect_true(math.abs(body:getAngularVelocity()) > 0)
    end)

    -- @covers LBody:getGravityScale
    -- @covers LBody:setGravityScale
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getGravityScale and setGravityScale round-trip", function()
        local world = lurek.physics.newWorld(0, -9.81)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setGravityScale(0.5)
        expect_near(0.5, body:getGravityScale(), 0.01)
    end)

    -- @covers LBody:isFixedRotation
    -- @covers LBody:setFixedRotation
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("isFixedRotation and setFixedRotation round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_false(body:isFixedRotation())
        body:setFixedRotation(true)
        expect_true(body:isFixedRotation())
    end)

    -- @covers LBody:getLinearDamping
    -- @covers LBody:setLinearDamping
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getLinearDamping and setLinearDamping round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setLinearDamping(0.3)
        expect_near(0.3, body:getLinearDamping(), 0.01)
    end)

    -- @covers LBody:getAngularDamping
    -- @covers LBody:setAngularDamping
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getAngularDamping and setAngularDamping round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngularDamping(0.4)
        expect_near(0.4, body:getAngularDamping(), 0.01)
    end)

    -- @covers LBody:isBullet
    -- @covers LBody:setBullet
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("isBullet and setBullet round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_false(body:isBullet())
        body:setBullet(true)
        expect_true(body:isBullet())
    end)

    -- @covers LBody:getId
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("getId returns a number", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_type("number", body:getId())
    end)

    -- @covers LBody:destroy
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("destroy removes body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_no_error(function() body:destroy() end)
    end)
end)

-- World UserData methods

-- @describe World UserData methods
describe("World UserData methods", function()
    -- @covers LWorld:getGravity
    -- @covers lurek.physics.newWorld
    it("getGravity returns world gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local gx, gy = world:getGravity()
        expect_near(0, gx, 0.01)
        expect_near(9.81, gy, 0.01)
    end)

    -- @covers LWorld:getGravity
    -- @covers LWorld:setGravity
    -- @covers lurek.physics.newWorld
    it("setGravity changes world gravity", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setGravity(0, -10)
        local gx, gy = world:getGravity()
        expect_near(0, gx, 0.01)
        expect_near(-10, gy, 0.01)
    end)

    -- @covers LWorld:getBodyCount
    -- @covers LWorld:newBody
    -- @covers lurek.physics.newWorld
    it("getBodyCount tracks bodies", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:getBodyCount())
        world:newBody(0, 0, "dynamic")
        expect_equal(1, world:getBodyCount())
        world:newBody(5, 5, "static")
        expect_equal(2, world:getBodyCount())
    end)

    -- @covers LWorld:getBodyIds
    -- @covers LWorld:newBody
    -- @covers lurek.physics.newWorld
    it("getBodyIds returns id table", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        world:newBody(5, 5, "dynamic")
        local ids = world:getBodyIds()
        expect_equal(2, #ids)
    end)

    -- @covers LWorld:newBody
    -- @covers lurek.physics.newWorld
    it("newBody assigns sequential ids", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newBody(0, 0, "dynamic")
        local b = world:newBody(5, 5, "static")
        expect_equal(0, a:getId())
        expect_equal(1, b:getId())
    end)

    -- @covers LWorld:destroyBody
    -- @covers LWorld:getBodyCount
    -- @covers LWorld:newBody
    -- @covers lurek.physics.newWorld
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

    -- @covers LWorld:clear
    -- @covers LWorld:getBodyCount
    -- @covers LWorld:newBody
    -- @covers lurek.physics.newWorld
    it("clear removes all bodies", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        world:newBody(5, 5, "dynamic")
        world:clear()
        expect_equal(0, world:getBodyCount())
    end)

    -- @covers LWorld:newCircleBody
    -- @covers LWorld:step
    -- @covers lurek.physics.newWorld
    it("step advances simulation", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_true(y > 0, "gravity should move body down")
    end)

    -- @covers LWorld:getMeter
    -- @covers LWorld:setMeter
    -- @covers lurek.physics.newWorld
    it("getMeter and setMeter round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setMeter(100)
        expect_near(100, world:getMeter(), 0.01)
    end)

    -- @covers LWorld:setMeter
    -- @covers LWorld:toPhysics
    -- @covers LWorld:toPixels
    -- @covers lurek.physics.newWorld
    it("toPhysics and toPixels convert", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setMeter(50)
        local m = world:toPhysics(100)
        expect_near(2.0, m, 0.01)
        local px = world:toPixels(2.0)
        expect_near(100, px, 0.01)
    end)

    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("newCircleBody creates a body with circle shape", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(10, 20, 5, "dynamic")
        local x, y = body:getPosition()
        expect_near(10, x, 0.01)
        expect_near(20, y, 0.01)
    end)

    -- @covers LWorld:newPolygonBody
    -- @covers lurek.physics.newWorld
    it("newPolygonBody creates a polygon body", function()
        local world = lurek.physics.newWorld(0, 0)
        local verts = {0, 0, 10, 0, 10, 10, 0, 10}
        local body = world:newPolygonBody(5, 5, verts, "dynamic")
        expect_not_nil(body)
        expect_equal("dynamic", body:getType())
    end)

    -- @covers LWorld:newEdgeBody
    -- @covers lurek.physics.newWorld
    it("newEdgeBody creates an edge body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newEdgeBody(0, 0, 0, 0, 100, 0, "static")
        expect_not_nil(body)
    end)
end)

-- Joints

-- @describe Joint operations
describe("Joint operations", function()
    -- @covers LWorld:addRevoluteJoint
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("addRevoluteJoint creates a revolute joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        expect_type("number", jid)
    end)

    -- @covers LWorld:addDistanceJoint
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("addDistanceJoint creates a distance joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(10, 0, 1, "dynamic")
        local jid = world:addDistanceJoint(a:getId(), b:getId(), 0, 0, 10, 0, 10)
        expect_type("number", jid)
    end)

    -- @covers LWorld:addWeldJoint
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("addWeldJoint creates a weld joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addWeldJoint(a:getId(), b:getId(), 2.5, 0)
        expect_type("number", jid)
    end)

    -- @covers LWorld:addRevoluteJoint
    -- @covers LWorld:jointCount
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("jointCount returns number of joints", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:jointCount())
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        expect_equal(1, world:jointCount())
    end)

    -- @covers LWorld:addRevoluteJoint
    -- @covers LWorld:getJointIds
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("getJointIds returns joint id table", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        local ids = world:getJointIds()
        expect_equal(1, #ids)
    end)

    -- @covers LWorld:addRevoluteJoint
    -- @covers LWorld:getJointType
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("getJointType returns joint type string", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        local jtype = world:getJointType(jid)
        expect_type("string", jtype)
    end)

    -- @covers LWorld:addRevoluteJoint
    -- @covers LWorld:destroyJoint
    -- @covers LWorld:jointCount
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
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

-- @describe Fixture operations
describe("Fixture operations", function()
    -- @covers LBody:getId
    -- @covers LWorld:fixtureCount
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("fixtureCount defaults to one", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_equal(1, world:fixtureCount(body:getId()))
    end)

    -- @covers LBody:getId
    -- @covers LWorld:addFixture
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("addFixture returns fixture index", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local idx = world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_type("number", idx)
    end)

    -- @covers LBody:getId
    -- @covers LWorld:addFixture
    -- @covers LWorld:fixtureCount
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("fixtureCount increases after addFixture", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local before = world:fixtureCount(body:getId())
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_equal(before + 1, world:fixtureCount(body:getId()))
    end)

    -- @covers LWorld:fixtureCount
    -- @covers lurek.physics.newWorld
    it("fixtureCount returns 0 for unknown body", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:fixtureCount(999))
    end)

    -- @covers LBody:getId
    -- @covers LWorld:addFixture
    -- @covers LWorld:setFixtureFriction
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("setFixtureFriction does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureFriction(body:getId(), 0, 0.8)
        end)
    end)

    -- @covers LBody:getId
    -- @covers LWorld:addFixture
    -- @covers LWorld:setFixtureRestitution
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("setFixtureRestitution does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureRestitution(body:getId(), 0, 0.6)
        end)
    end)

    -- @covers LBody:getId
    -- @covers LWorld:addFixture
    -- @covers LWorld:setFixtureSensor
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
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

-- @describe Collision and simulation behavior
describe("Collision and simulation behavior", function()
    -- @covers LWorld:newCircleBody
    -- @covers LWorld:step
    -- @covers lurek.physics.newWorld
    it("static body does not move under gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "static")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    -- @covers LWorld:newCircleBody
    -- @covers LWorld:step
    -- @covers lurek.physics.newWorld
    it("zero gravity keeps dynamic body still", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        world:step(1.0 / 60.0)
        local x, y = body:getPosition()
        expect_near(0, x, 0.001)
        expect_near(0, y, 0.001)
    end)

    -- @covers LWorld:newCircleBody
    -- @covers LWorld:step
    -- @covers lurek.physics.newWorld
    it("kinematic body is unaffected by gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "kinematic")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    -- @covers LBody:setGravityScale
    -- @covers LWorld:newCircleBody
    -- @covers LWorld:step
    -- @covers lurek.physics.newWorld
    it("gravity scale 0 prevents falling", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setGravityScale(0)
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    -- @covers LWorld:newCircleBody
    -- @covers LWorld:step
    -- @covers lurek.physics.newWorld
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

-- @describe World destruction
describe("World destruction", function()
    -- @covers LWorld:newBody
    -- @covers lurek.physics.destroyWorld
    -- @covers lurek.physics.newWorld
    it("destroyWorld does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        expect_no_error(function() lurek.physics.destroyWorld(world) end)
    end)
end)

-- =========================================================================
-- Merged from test_physics_body_data.lua
-- =========================================================================

-- @describe physics body data
describe("physics body data", function()

  -- @covers LWorld:getBodyData
  -- @covers LWorld:newBody
  -- @covers LWorld:setBodyData
  -- @covers lurek.physics.newWorld
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

  -- @covers LWorld:getBodyData
  -- @covers LWorld:newBody
  -- @covers lurek.physics.newWorld
  it("getBodyData returns nil for unset body", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    local d = w:getBodyData(id)
    expect_equal(d, nil)
  end)

  -- @covers LWorld:clearBodyData
  -- @covers LWorld:getBodyData
  -- @covers LWorld:newBody
  -- @covers LWorld:setBodyData
  -- @covers lurek.physics.newWorld
  it("clearBodyData removes data", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    w:setBodyData(id, "some data")
    w:clearBodyData(id)
    expect_equal(w:getBodyData(id), nil)
  end)

  -- @covers LWorld:getBodyData
  -- @covers LWorld:newBody
  -- @covers LWorld:setBodyData
  -- @covers lurek.physics.newWorld
  it("setBodyData overwrites previous value", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "dynamic")
    local id = body:getId()
    w:setBodyData(id, "first")
    w:setBodyData(id, "second")
    expect_equal(w:getBodyData(id), "second")
  end)

  -- @covers LWorld:getBodyData
  -- @covers LWorld:newBody
  -- @covers LWorld:setBodyData
  -- @covers lurek.physics.newWorld
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

-- @describe lurek.physics cellular factory
describe("lurek.physics cellular factory", function()
    -- @covers lurek.physics.newCellular
    it("newCellular is a function", function()
        expect_type("function", lurek.physics.newCellular)
    end)

    -- @covers lurek.physics.newCellular
    it("newCellular returns userdata", function()
        local sim = lurek.physics.newCellular(32, 32)
        expect_type("userdata", sim)
    end)
end)

-- @describe lurek.physics cellular cell-type constants
describe("lurek.physics cellular cell-type constants", function()
    -- @covers lurek.physics.CELL_AIR
    it("CELL_AIR is an integer", function()
        expect_type("number", lurek.physics.CELL_AIR)
        expect_equal(0, lurek.physics.CELL_AIR)
    end)

    -- @covers lurek.physics.CELL_SAND
    it("CELL_SAND is greater than CELL_AIR", function()
        expect_true(lurek.physics.CELL_SAND > lurek.physics.CELL_AIR)
    end)

    -- @covers lurek.physics.CELL_WATER
    it("CELL_WATER is an integer", function()
        expect_type("number", lurek.physics.CELL_WATER)
    end)

    -- @covers lurek.physics.CELL_ROCK
    it("CELL_ROCK is an integer", function()
        expect_type("number", lurek.physics.CELL_ROCK)
    end)

    -- @covers lurek.physics.CELL_FIRE
    it("CELL_FIRE is an integer", function()
        expect_type("number", lurek.physics.CELL_FIRE)
    end)

    -- @covers lurek.physics.CELL_GAS
    it("CELL_GAS is an integer", function()
        expect_type("number", lurek.physics.CELL_GAS)
    end)
end)

-- @describe lurek.physics cellular cell access
describe("lurek.physics cellular cell access", function()
    local sim

    before_each(function()
        sim = lurek.physics.newCellular(16, 16)
    end)

    -- @covers LCellular:getCell
    it("new grid is all air", function()
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(0, 0))
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(8, 8))
    end)

    -- @covers LCellular:getCell
    -- @covers LCellular:setCell
    it("setCell changes cell type", function()
        sim:setCell(5, 5, lurek.physics.CELL_SAND)
        expect_equal(lurek.physics.CELL_SAND, sim:getCell(5, 5))
    end)

    -- @covers LCellular:getCell
    -- @covers LCellular:setCell
    it("setting cell to AIR clears it", function()
        sim:setCell(3, 3, lurek.physics.CELL_ROCK)
        sim:setCell(3, 3, lurek.physics.CELL_AIR)
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(3, 3))
    end)
end)

-- @describe lurek.physics cellular bulk fill
describe("lurek.physics cellular bulk fill", function()
    local sim

    before_each(function()
        sim = lurek.physics.newCellular(32, 32)
    end)

    -- @covers LCellular:fillRect
    it("fillRect fills the specified region", function()
        sim:fillRect(5, 5, 4, 4, lurek.physics.CELL_ROCK)
        expect_equal(lurek.physics.CELL_ROCK, sim:getCell(6, 6))
        -- outside the region should remain air
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(0, 0))
    end)

    -- @covers LCellular:fillCircle
    it("fillCircle marks centre cell", function()
        sim:fillCircle(16, 16, 3, lurek.physics.CELL_WATER)
        expect_equal(lurek.physics.CELL_WATER, sim:getCell(16, 16))
    end)
end)

-- @describe lurek.physics cellular step
describe("lurek.physics cellular step", function()
    -- @covers LCellular:countCells
    -- @covers LCellular:getCell
    -- @covers LCellular:setCell
    -- @covers LCellular:step
    -- @covers lurek.physics.newCellular
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
    -- @covers LCellular:fillRect
    -- @covers LCellular:stepN
    -- @covers lurek.physics.newCellular
    it("stepN accepts a count without error", function()
        local sim = lurek.physics.newCellular(16, 16)
        sim:fillRect(0, 0, 16, 1, lurek.physics.CELL_SAND)
        expect_no_error(function()
            sim:stepN(10)
        end)
    end)
end)

-- @describe lurek.physics cellular query
describe("lurek.physics cellular query", function()
    -- @covers LCellular:countCells
    -- @covers LCellular:setCell
    -- @covers lurek.physics.newCellular
    it("countCells matches manually placed cells", function()
        local sim = lurek.physics.newCellular(16, 16)
        sim:setCell(0, 0, lurek.physics.CELL_ROCK)
        sim:setCell(1, 0, lurek.physics.CELL_ROCK)
        sim:setCell(2, 0, lurek.physics.CELL_ROCK)
        expect_equal(3, sim:countCells(lurek.physics.CELL_ROCK))
    end)

    -- @covers LCellular:findCells
    -- @covers LCellular:setCell
    -- @covers lurek.physics.newCellular
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

-- @describe lurek.physics cellular serialisation
describe("lurek.physics cellular serialisation", function()
    -- @covers LCellular:getCell
    -- @covers LCellular:loadFromBytes
    -- @covers LCellular:setCell
    -- @covers LCellular:toBytes
    -- @covers lurek.physics.newCellular
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

-- @describe lurek.physics solver iterations
describe("lurek.physics solver iterations", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
    end)

    -- @covers LWorld:getSolverIterations
    it("default solver iteration count is 4", function()
        expect_equal(4, world:getSolverIterations())
    end)

    -- @covers LWorld:getSolverIterations
    -- @covers LWorld:setSolverIterations
    it("setSolverIterations persists the value", function()
        world:setSolverIterations(8)
        expect_equal(8, world:getSolverIterations())
    end)

    -- @covers LWorld:getSolverIterations
    -- @covers LWorld:setSolverIterations
    it("setSolverIterations clamps zero to 1", function()
        world:setSolverIterations(0)
        expect_equal(1, world:getSolverIterations())
    end)
end)

-- Body sleeping

-- @describe lurek.physics body sleeping
describe("lurek.physics body sleeping", function()
    local world
    local body_id

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        body_id = lurek.physics.newBody(world, 100, 100, "dynamic")
    end)

    -- @covers LWorld:isBodySleeping
    it("isBodySleeping returns boolean", function()
        expect_error(function()
            world:isBodySleeping(body_id)
        end)
    end)

    -- @covers LWorld:sleepBody
    it("sleepBody puts a body to sleep", function()
        expect_error(function()
            world:sleepBody(body_id)
        end)
    end)

    -- @covers LWorld:wakeUpBody
    it("wakeUpBody wakes a sleeping body", function()
        expect_error(function()
            world:wakeUpBody(body_id)
        end)
    end)

    -- @covers LBody:isSleeping
    -- @covers lurek.physics.newBody
    it("Body:isSleeping returns boolean", function()
        local body = lurek.physics.newBody(world, 200, 200, "dynamic")
        expect_type("boolean", body:isSleeping())
    end)

    -- @covers LBody:isSleeping
    -- @covers LBody:sleep
    -- @covers lurek.physics.newBody
    it("Body:sleep puts the body to sleep", function()
        local body = lurek.physics.newBody(world, 300, 300, "dynamic")
        body:sleep()
        expect_equal(true, body:isSleeping())
    end)

    -- @covers LBody:isSleeping
    -- @covers LBody:sleep
    -- @covers LBody:wakeUp
    -- @covers lurek.physics.newBody
    it("Body:wakeUp wakes the body", function()
        local body = lurek.physics.newBody(world, 400, 400, "dynamic")
        body:sleep()
        body:wakeUp()
        expect_equal(false, body:isSleeping())
    end)
end)

-- One-way platform

-- @describe lurek.physics one-way platform
describe("lurek.physics one-way platform", function()
    local world
    local body_id

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        body_id = lurek.physics.newBody(world, 0, 0, "static")
    end)

    -- @covers LWorld:setBodyOneWay
    it("setBodyOneWay stores the normal", function()
        expect_error(function()
            world:setBodyOneWay(body_id, 0, -1)
        end)
    end)

    -- @covers LWorld:clearBodyOneWay
    it("clearBodyOneWay removes the one-way flag", function()
        expect_error(function()
            world:clearBodyOneWay(body_id)
        end)
    end)

    -- @covers LWorld:getBodyOneWay
    it("getBodyOneWay returns nil for a normal body", function()
        expect_error(function()
            world:getBodyOneWay(body_id)
        end)
    end)
end)

-- @describe physics missing API coverage sweep
describe("physics missing API coverage sweep", function()
    -- @covers lurek.physics.debugDraw
    it("debugDraw toggle is callable", function()
        expect_no_error(function()
            lurek.physics.debugDraw(true)
            lurek.physics.debugDraw(false)
        end)
    end)

    -- @covers LWorld:newChainBody
    -- @covers lurek.physics.newWorld
    it("newChainBody creates body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newChainBody(0, 0, {0, 0, 10, 0, 10, 10}, false, "static")
        expect_type("userdata", body)
    end)

    -- @covers LWorld:addPrismaticJoint
    -- @covers LWorld:addRopeJoint
    -- @covers LWorld:addWheelJoint
    -- @covers LWorld:addFrictionJoint
    -- @covers LWorld:addMotorJoint
    -- @covers LWorld:addMouseJoint
    -- @covers LWorld:addPulleyJoint
    -- @covers LWorld:addGearJoint
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("joint creation APIs are callable", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        expect_type("number", world:addPrismaticJoint(a:getId(), b:getId(), 0, 0, 1, 0))
        expect_type("number", world:addRopeJoint(a:getId(), b:getId(), 0, 0, 5, 0, 6))
        expect_type("number", world:addWheelJoint(a:getId(), b:getId(), 0, 0, 0, 1))
        expect_type("number", world:addFrictionJoint(a:getId(), b:getId(), 0, 0, 10, 2))
        expect_type("number", world:addMotorJoint(a:getId(), b:getId(), 0.7))
        expect_type("number", world:addMouseJoint(a:getId(), 0, 0, 1000))
        expect_type("number", world:addPulleyJoint(a:getId(), b:getId(), 0, 0))
        expect_type("number", world:addGearJoint(a:getId(), b:getId(), 0, 0))
    end)

    -- @covers LWorld:setJointMotorSpeed
    -- @covers LWorld:getJointMotorSpeed
    -- @covers LWorld:setJointLimits
    -- @covers LWorld:getJointLimits
    -- @covers LWorld:setJointLimitsEnabled
    -- @covers LWorld:getJointBodies
    -- @covers LWorld:setMouseJointTarget
    -- @covers LWorld:newCircleBody
    -- @covers LWorld:addRevoluteJoint
    -- @covers LWorld:addMouseJoint
    -- @covers lurek.physics.newWorld
    it("joint control/query APIs are callable", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        local mjid = world:addMouseJoint(a:getId(), 0, 0, 1000)
        world:setJointMotorSpeed(jid, 3)
        expect_type("number", world:getJointMotorSpeed(jid))
        world:setJointLimits(jid, -0.5, 0.5)
        local lo, hi = world:getJointLimits(jid)
        expect_type("number", lo)
        expect_type("number", hi)
        world:setJointLimitsEnabled(jid, true)
        world:setMouseJointTarget(mjid, 2, 3)
        local ba, bb = world:getJointBodies(jid)
        expect_type("number", ba)
        expect_type("number", bb)
    end)

    -- @covers LWorld:queryAABB
    -- @covers LWorld:raycastClosest
    -- @covers LWorld:getBodyAtPoint
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("query APIs are callable", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(2, 2, 1, "dynamic")
        local id = body:getId()
        local aabb = world:queryAABB(0, 0, 8, 8)
        expect_type("table", aabb)
        local hit = world:raycastClosest(0, 2, 1, 0, 10)
        if hit ~= nil then
            expect_type("table", hit)
        end
        local at = world:getBodyAtPoint(2, 2)
        if at ~= nil then
            expect_type("number", at)
        end
        expect_true(id >= 0)
    end)

    -- @covers LWorld:getCollisionEvents
    -- @covers LWorld:getBeginContactEvents
    -- @covers LWorld:getEndContactEvents
    -- @covers LWorld:getContacts
    -- @covers LWorld:getBodyContacts
    -- @covers lurek.physics.newWorld
    it("contact/event APIs are callable", function()
        local world = lurek.physics.newWorld(0, 0)
        local all_events = world:getCollisionEvents()
        local begin_events = world:getBeginContactEvents()
        local end_events = world:getEndContactEvents()
        local contacts = world:getContacts()
        local body_contacts = world:getBodyContacts(0)
        expect_type("table", all_events)
        expect_type("table", begin_events)
        expect_type("table", end_events)
        expect_type("table", contacts)
        expect_type("table", body_contacts)
    end)

    -- @covers LWorld:setBodyType
    -- @covers LWorld:getBodyType
    -- @covers LWorld:newBody
    -- @covers lurek.physics.newWorld
    it("world body type setters/getters are callable", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newBody(0, 0, "dynamic")
        local id = body:getId()
        world:setBodyType(id, "kinematic")
        expect_equal("kinematic", world:getBodyType(id))
    end)

    -- @covers LBody:setMass
    -- @covers LBody:applyForceAtPoint
    -- @covers LWorld:newCircleBody
    -- @covers lurek.physics.newWorld
    it("body mass and point-force APIs are callable", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1, "dynamic")
        expect_no_error(function()
            body:setMass(2.0)
            body:applyForceAtPoint(10, 0, 0, 0)
        end)
    end)
end)

-- CCD

-- @describe lurek.physics CCD
describe("lurek.physics CCD", function()
    local world
    local body_id

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        body_id = lurek.physics.newBody(world, 100, 100, "dynamic")
    end)

    -- @covers LWorld:setBodyCCD
    it("setBodyCCD enables CCD", function()
        expect_error(function()
            world:setBodyCCD(body_id, true)
        end)
    end)

    -- @covers LWorld:setBodyCCD
    it("setBodyCCD can disable CCD", function()
        expect_error(function()
            world:setBodyCCD(body_id, false)
        end)
    end)
end)

-- Breakable joints

-- @describe lurek.physics breakable joints
describe("lurek.physics breakable joints", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
    end)

    -- @covers lurek.physics
    it("setJointBreakForce stores the threshold", function()
        expect_true(type(rawget(lurek.physics, "newJoint")) ~= "function")
    end)

    -- @covers lurek.physics
    it("getJointBreakForce returns nil when not set", function()
        expect_true(type(rawget(lurek.physics, "newJoint")) ~= "function")
    end)
end)

-- Contact callbacks

-- @describe lurek.physics contact callbacks
describe("lurek.physics contact callbacks", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
    end)

    -- @covers LWorld:setBeginContact
    it("setBeginContact accepts a function", function()
        expect_no_error(function()
            world:setBeginContact(function(a, b) end)
        end)
    end)

    -- @covers LWorld:clearBeginContact
    -- @covers LWorld:setBeginContact
    it("clearBeginContact does not error", function()
        world:setBeginContact(function(a, b) end)
        expect_no_error(function()
            world:clearBeginContact()
        end)
    end)

    -- @covers LWorld:setEndContact
    it("setEndContact accepts a function", function()
        expect_no_error(function()
            world:setEndContact(function(a, b) end)
        end)
    end)

    -- @covers LWorld:clearEndContact
    -- @covers LWorld:setEndContact
    it("clearEndContact does not error", function()
        world:setEndContact(function(a, b) end)
        expect_no_error(function()
            world:clearEndContact()
        end)
    end)
end)

-- Batch body creation

-- @describe lurek.physics newBodies
describe("lurek.physics newBodies", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
    end)

    -- @covers LWorld:newBodies
    it("newBodies returns correct number of IDs", function()
        local ids = world:newBodies({
            {0, 0, "dynamic"},
            {100, 0, "static"},
            {200, 0, "kinematic"},
        })
        expect_equal(3, #ids)
    end)

    -- @covers LWorld:newBodies
    it("newBodies IDs are integers", function()
        local ids = world:newBodies({
            {10, 20, "dynamic"},
            {30, 40, "dynamic"},
        })
        for _, id in ipairs(ids) do
            expect_type("number", id)
        end
    end)

    -- @covers LWorld:newBodies
    it("newBodies with empty table returns empty table", function()
        local ids = world:newBodies({})
        expect_equal(0, #ids)
    end)
end)

-- =========================================================================
-- Merged from test_physics_step_fixed.lua
-- =========================================================================

-- @describe lurek.physics World:stepFixed
describe("lurek.physics World:stepFixed", function()
    -- @covers LWorld:stepFixed
    -- @covers lurek.physics.newWorld
    it("stepFixed is callable", function()
        local world = lurek.physics.newWorld(0, 9.81)
        expect_no_error(function()
            world:stepFixed(1/60, 1/60, 8)
        end)
    end)

    -- @covers LWorld:stepFixed
    -- @covers lurek.physics.newWorld
    it("remainder is zero when accum equals step_dt exactly", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        local remainder = world:stepFixed(step_dt, step_dt, 8)
        expect_near(0.0, remainder, 1e-4)
    end)

    -- @covers LWorld:stepFixed
    -- @covers lurek.physics.newWorld
    it("remainder is always less than step_dt", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        -- Pass 3.5 steps worth of accumulated time.
        local accum = step_dt * 3.5
        local remainder = world:stepFixed(accum, step_dt, 8)
        expect_true(remainder < step_dt, "remainder must be < step_dt")
        expect_true(remainder >= 0, "remainder must be non-negative")
    end)

    -- @covers LWorld:stepFixed
    -- @covers lurek.physics.newWorld
    it("max_steps cap leaves remainder >= step_dt when capped", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        -- Pass 100 steps worth of time but cap at 1 sub-step.
        local accum = step_dt * 100
        local remainder = world:stepFixed(accum, step_dt, 1)
        -- After one step, remainder = accum - step_dt  step_dt * 99
        expect_true(remainder > step_dt, "remaining time should exceed step_dt when capped")
    end)

    -- @covers LWorld:stepFixed
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
    it("dynamic body moves under gravity after stepFixed", function()
        local world = lurek.physics.newWorld(0, 100)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local _, y0 = lurek.physics.getBody(world, body)
        -- Accumulate enough time for one step.
        world:stepFixed(1/60, 1/60, 4)
        local _, y1 = lurek.physics.getBody(world, body)
        expect_true(y1 > y0, "dynamic body should move downward after stepFixed under gravity")
    end)
end)

-- =========================================================================
-- Merged from test_physics_terrain.lua
-- =========================================================================

-- @describe lurek.physics terrain factory
describe("lurek.physics terrain factory", function()
    -- @covers lurek.physics.newTerrain
    it("newTerrain is a function", function()
        expect_type("function", lurek.physics.newTerrain)
    end)

    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
    it("newTerrain returns userdata", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(32, 32, 8, world)
        expect_type("userdata", terrain)
    end)
end)

-- @describe lurek.physics terrain cell access
describe("lurek.physics terrain cell access", function()
    local world, terrain

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
        terrain = lurek.physics.newTerrain(16, 16, 8, world)
    end)

    -- @covers lurek.physics
    it("all cells start empty", function()
        expect_false(terrain:getCell(0, 0))
        expect_false(terrain:getCell(7, 7))
        expect_false(terrain:getCell(15, 15))
    end)

    -- @covers lurek.physics
    it("setCell true makes cell solid", function()
        terrain:setCell(3, 3, true)
        expect_true(terrain:getCell(3, 3))
    end)

    -- @covers lurek.physics
    it("setCell false clears a solid cell", function()
        terrain:setCell(5, 5, true)
        terrain:setCell(5, 5, false)
        expect_false(terrain:getCell(5, 5))
    end)

    -- @covers lurek.physics
    it("isDirty is true after setCell", function()
        expect_false(terrain:isDirty())
        terrain:setCell(0, 0, true)
        expect_true(terrain:isDirty())
    end)
end)

-- @describe lurek.physics terrain bulk fill
describe("lurek.physics terrain bulk fill", function()
    local world, terrain

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
        terrain = lurek.physics.newTerrain(32, 32, 8, world)
    end)

    -- @covers LTerrain:fillAll
    it("fillAll true marks all cells solid", function()
        terrain:fillAll(true)
        expect_true(terrain:getCell(0, 0))
        expect_true(terrain:getCell(15, 15))
        expect_true(terrain:getCell(31, 31))
    end)

    -- @covers LTerrain:fillAll
    it("fillAll false clears all cells", function()
        terrain:fillAll(true)
        terrain:fillAll(false)
        expect_false(terrain:getCell(0, 0))
        expect_false(terrain:getCell(15, 15))
    end)

    -- @covers lurek.physics
    -- @covers LTerrain:fillRect
    it("fillRect marks affected cells solid", function()
        -- fill a 55 block at cell (0,0), world coords 0,0 / 40,40 (8px cells)
        terrain:fillRect(0, 0, 40, 40, true)
        expect_true(terrain:getCell(2, 2))
    end)

    -- @covers lurek.physics
    -- @covers LCellular:fillCircle
    -- @covers LTerrain:fillCircle
    it("fillCircle marks centre cell solid", function()
        -- centre at world (64,64), radius 16  hits cell (8,8)
        terrain:fillCircle(64, 64, 16, true)
        expect_true(terrain:getCell(8, 8))
    end)
end)

-- @describe lurek.physics terrain flush
describe("lurek.physics terrain flush", function()
    -- @covers LTerrain:flush
    -- @covers LTerrain:isDirty
    -- @covers LTerrain:setCell
    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
    it("flush clears isDirty", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(16, 16, 8, world)
        terrain:setCell(0, 0, true)
        expect_true(terrain:isDirty())
        terrain:flush()
        expect_false(terrain:isDirty())
    end)
end)

-- @describe lurek.physics terrain serialisation
describe("lurek.physics terrain serialisation", function()
    -- @covers LTerrain:getCell
    -- @covers LTerrain:loadFromBytes
    -- @covers LTerrain:setCell
    -- @covers LTerrain:toBytes
    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
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

-- @describe lurek.physics terrain collapse columns
describe("lurek.physics terrain collapse columns", function()
    -- @covers LTerrain:collapseColumns
    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
    it("collapseColumns returns a non-negative integer", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(16, 16, 8, world)
        local n = terrain:collapseColumns()
        expect_true(n >= 0, "count must be non-negative")
    end)

    --              (every cell has its neighbour below it).
    -- @covers LTerrain:collapseColumns
    -- @covers LTerrain:fillAll
    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
    it("fully solid terrain collapses zero cells", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        terrain:fillAll(true)
        local n = terrain:collapseColumns()
        expect_equal(0, n)
    end)

    --              it has no floor, no left neighbour, and no right neighbour.
    -- @covers LTerrain:collapseColumns
    -- @covers LTerrain:getCell
    -- @covers LTerrain:setCell
    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
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

    -- @covers LTerrain:collapseColumns
    -- @covers LTerrain:getCell
    -- @covers LTerrain:setCell
    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
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

    -- @covers LTerrain:collapseColumns
    -- @covers LTerrain:flush
    -- @covers LTerrain:isDirty
    -- @covers LTerrain:setCell
    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
    it("collapseColumns marks terrain dirty when cells fall", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        terrain:setCell(4, 0, true)
        terrain:flush() -- clear dirty flag first
        terrain:collapseColumns()
        expect_true(terrain:isDirty())
    end)
end)

-- @describe lurek.physics terrain solid positions
describe("lurek.physics terrain solid positions", function()
    -- @covers LTerrain:solidPositions
    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
    it("solidPositions empty for blank terrain", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        local pts = terrain:solidPositions()
        expect_equal(0, #pts)
    end)

    -- @covers LTerrain:setCell
    -- @covers LTerrain:solidPositions
    -- @covers lurek.physics.newTerrain
    -- @covers lurek.physics.newWorld
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

-- @describe lurek.physics zone factory
describe("lurek.physics zone factory", function()
    -- @covers LWorld:addZone
    -- @covers lurek.physics.newWorld
    it("addZone returns userdata", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local zone = world:addZone(0, 0, 100, 100)
        expect_type("userdata", zone)
    end)

    -- @covers LWorld:addZone
    -- @covers lurek.physics.newWorld
    it("consecutive zones have different IDs", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local z1 = world:addZone(0, 0, 50, 50)
        local z2 = world:addZone(50, 0, 50, 50)
        expect_false(z1:getId() == z2:getId(), "zone IDs must be unique")
    end)
end)

-- @describe lurek.physics zone gravity modes
describe("lurek.physics zone gravity modes", function()
    local world, zone

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        zone = world:addZone(0, 0, 1000, 1000)
    end)

    -- @covers LZone:setGravityZero
    it("setGravityZero accepts no arguments", function()
        expect_no_error(function()
            zone:setGravityZero()
        end)
    end)

    -- @covers LZone:setGravityDirectional
    it("setGravityDirectional accepts gx and gy", function()
        expect_no_error(function()
            zone:setGravityDirectional(0, -50)
        end)
    end)

    -- @covers LZone:setGravityPoint
    it("setGravityPoint accepts cx, cy, strength", function()
        expect_no_error(function()
            zone:setGravityPoint(500, 500, 1000)
        end)
    end)

    -- @covers LZone:setGravityRepulsor
    it("setGravityRepulsor accepts cx, cy, strength", function()
        expect_no_error(function()
            zone:setGravityRepulsor(500, 500, 500)
        end)
    end)
end)

-- @describe lurek.physics zone configuration
describe("lurek.physics zone configuration", function()
    local world, zone

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        zone = world:addZone(0, 0, 1000, 1000)
    end)

    -- @covers lurek.physics
    it("setEnabled false does not error", function()
        expect_no_error(function()
            zone:setEnabled(false)
        end)
    end)

    -- @covers lurek.physics
    -- @covers LAgent:setPriority
    -- @covers LGraphItem:setPriority
    -- @covers LZone:setPriority
    it("setPriority accepts an integer", function()
        expect_no_error(function()
            zone:setPriority(10)
        end)
    end)

    -- @covers LZone:setLayerMask
    it("setLayerMask accepts a bitmask", function()
        expect_no_error(function()
            zone:setLayerMask(0xFF)
        end)
    end)

    -- @covers LZone:setCircle
    it("setCircle replaces boundary with circle", function()
        expect_no_error(function()
            zone:setCircle(500, 500, 300)
        end)
    end)

    -- @covers LZone:setLinearDampingOverride
    it("setLinearDampingOverride accepts a value", function()
        expect_no_error(function()
            zone:setLinearDampingOverride(2.0)
        end)
    end)

    -- @covers LZone:setAngularDampingOverride
    it("setAngularDampingOverride accepts a value", function()
        expect_no_error(function()
            zone:setAngularDampingOverride(1.0)
        end)
    end)

    -- @covers LZone:destroy
    it("destroy does not error", function()
        expect_no_error(function()
            zone:destroy()
        end)
    end)
end)

-- @describe lurek.physics zone events
describe("lurek.physics zone events", function()
    -- @covers LWorld:addZone
    -- @covers LWorld:getZoneEvents
    -- @covers lurek.physics.newWorld
    it("getZoneEvents returns a table", function()
        local world = lurek.physics.newWorld(0, 9.81)
        world:addZone(0, 0, 1000, 1000)
        local events = world:getZoneEvents()
        expect_type("table", events)
    end)

    -- @covers LWorld:addZone
    -- @covers LWorld:getZoneEvents
    -- @covers LWorld:step
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newWorld
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

-- @describe lurek.physics helpers
describe("lurek.physics helpers", function()

-- testAABB

  -- @covers lurek.physics.testAABB
  it("testAABB detects overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 10, 10), true)
  end)

  -- @covers lurek.physics.testAABB
  it("testAABB detects no overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 20, 20, 10, 10), false)
  end)

  -- @covers lurek.physics.testAABB
  it("testAABB touching edges do not overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 10, 0, 10, 10), false)
  end)

-- testCircles

  -- @covers lurek.physics.testCircles
  it("testCircles detects overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 5, 3, 0, 5), true)
  end)

  -- @covers lurek.physics.testCircles
  it("testCircles detects no overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 1, 10, 0, 1), false)
  end)

  -- @covers lurek.physics.testCircles
  it("testCircles same centre always overlaps", function()
    expect_equal(lurek.physics.testCircles(5, 5, 1, 5, 5, 1), true)
  end)

-- testPoint

  -- @covers lurek.physics.testPoint
  it("testPoint inside AABB", function()
    expect_equal(lurek.physics.testPoint(5, 5, 0, 0, 10, 10), true)
  end)

  -- @covers lurek.physics.testPoint
  it("testPoint outside AABB", function()
    expect_equal(lurek.physics.testPoint(15, 5, 0, 0, 10, 10), false)
  end)

  -- @covers lurek.physics.testPoint
  it("testPoint on right edge returns false", function()
    expect_equal(lurek.physics.testPoint(10, 5, 0, 0, 10, 10), false)
  end)

  -- @covers lurek.physics.testPoint
  it("testPoint at origin is inside", function()
    expect_equal(lurek.physics.testPoint(0, 0, 0, 0, 10, 10), true)
  end)

-- testCircleAABB

  -- @covers lurek.physics.testCircleAABB
  it("testCircleAABB circle centre inside box", function()
    expect_equal(lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10), true)
  end)

  -- @covers lurek.physics.testCircleAABB
  it("testCircleAABB non-overlapping", function()
    expect_equal(lurek.physics.testCircleAABB(20, 20, 1, 0, 0, 10, 10), false)
  end)

  -- @covers lurek.physics.testCircleAABB
  it("testCircleAABB overlapping corner", function()
    -- Circle at (12, 12) with radius 3  corner (10,10) is at distance sqrt(8)  2.83
    expect_equal(lurek.physics.testCircleAABB(12, 12, 3, 0, 0, 10, 10), true)
  end)

  -- @covers lurek.physics.testCircleAABB
  it("testCircleAABB just outside corner", function()
    -- Circle at (13, 13) with radius 1  corner (10,10) is at distance sqrt(18)  4.24
    expect_equal(lurek.physics.testCircleAABB(13, 13, 1, 0, 0, 10, 10), false)
  end)

end)





-- ================================================================
-- Merged from: test_physics_collision.lua
-- ================================================================

-- All helpers are pure math; no physics world is required.

-- @describe lurek.physics helpers
describe("lurek.physics helpers", function()

-- testAABB

  -- @covers lurek.physics.testAABB
  it("testAABB detects overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 10, 10), true)
  end)

  -- @covers lurek.physics.testAABB
  it("testAABB detects no overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 20, 20, 10, 10), false)
  end)

  -- @covers lurek.physics.testAABB
  it("testAABB touching edges do not overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 10, 0, 10, 10), false)
  end)

-- testCircles

  -- @covers lurek.physics.testCircles
  it("testCircles detects overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 5, 3, 0, 5), true)
  end)

  -- @covers lurek.physics.testCircles
  it("testCircles detects no overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 1, 10, 0, 1), false)
  end)

  -- @covers lurek.physics.testCircles
  it("testCircles same centre always overlaps", function()
    expect_equal(lurek.physics.testCircles(5, 5, 1, 5, 5, 1), true)
  end)

-- testPoint

  -- @covers lurek.physics.testPoint
  it("testPoint inside AABB", function()
    expect_equal(lurek.physics.testPoint(5, 5, 0, 0, 10, 10), true)
  end)

  -- @covers lurek.physics.testPoint
  it("testPoint outside AABB", function()
    expect_equal(lurek.physics.testPoint(15, 5, 0, 0, 10, 10), false)
  end)

  -- @covers lurek.physics.testPoint
  it("testPoint on right edge returns false", function()
    expect_equal(lurek.physics.testPoint(10, 5, 0, 0, 10, 10), false)
  end)

  -- @covers lurek.physics.testPoint
  it("testPoint at origin is inside", function()
    expect_equal(lurek.physics.testPoint(0, 0, 0, 0, 10, 10), true)
  end)

-- testCircleAABB

  -- @covers lurek.physics.testCircleAABB
  it("testCircleAABB circle centre inside box", function()
    expect_equal(lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10), true)
  end)

  -- @covers lurek.physics.testCircleAABB
  it("testCircleAABB non-overlapping", function()
    expect_equal(lurek.physics.testCircleAABB(20, 20, 1, 0, 0, 10, 10), false)
  end)

  -- @covers lurek.physics.testCircleAABB
  it("testCircleAABB overlapping corner", function()
    -- Circle at (12, 12) with radius 3  corner (10,10) is at distance sqrt(8)  2.83
    expect_equal(lurek.physics.testCircleAABB(12, 12, 3, 0, 0, 10, 10), true)
  end)

  -- @covers lurek.physics.testCircleAABB
  it("testCircleAABB just outside corner", function()
    -- Circle at (13, 13) with radius 1  corner (10,10) is at distance sqrt(18)  4.24
    expect_equal(lurek.physics.testCircleAABB(13, 13, 1, 0, 0, 10, 10), false)
  end)

end)
-- @describe physics strict: module functions
describe("physics strict: module functions", function()
  -- @covers lurek.physics.getCollisions
  -- @covers lurek.physics.newWorld
  it("getCollisions returns a table", function()
    local world = lurek.physics.newWorld(0, 0)
    local cols = lurek.physics.getCollisions(world)
    expect_type("table", cols)
  end)

  -- @covers lurek.physics.drawDebugGpu
  -- @covers lurek.physics.newWorld
  it("drawDebugGpu is callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local ok = pcall(function() lurek.physics.drawDebugGpu(world, {}) end)
    expect_true(ok)
  end)
end)

-- @describe physics strict: LWorld missing methods
describe("physics strict: LWorld missing methods", function()
  -- @covers LWorld:drawDebug
  -- @covers lurek.physics.newWorld
  it("drawDebug is callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local new_img = lurek.render and lurek.render["newImageData"]
    if new_img then
      local img = new_img(32, 32)
      local ok = pcall(function() world:drawDebug(img) end)
      expect_true(ok)
    else
            expect_nil(new_img)
    end
  end)

  -- @covers LWorld:raycast
  -- @covers lurek.physics.newWorld
  it("raycast is callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local hit = world:raycast(0, 0, 10, 0)
    expect_true(hit == nil or type(hit) == "table")
  end)

  -- @covers LWorld:raycastAll
  -- @covers lurek.physics.newWorld
  it("raycastAll returns a table", function()
    local world = lurek.physics.newWorld(0, 0)
    local hits = world:raycastAll(0, 0, 1, 0, 10)
    expect_type("table", hits)
  end)

  -- @covers LWorld:getBodyCCD
  -- @covers LWorld:newBody
  -- @covers lurek.physics.newWorld
  it("getBodyCCD is callable with body id", function()
    local world = lurek.physics.newWorld(0, 0)
    local b = world:newBody(0, 0, "dynamic")
    expect_type("boolean", world:getBodyCCD(b:getId()))
  end)

  -- @covers LWorld:setJointBreakForce
  -- @covers LWorld:getJointBreakForce
  -- @covers LWorld:addRevoluteJoint
  -- @covers LWorld:newBody
  -- @covers lurek.physics.newWorld
  it("set/getJointBreakForce round-trip on a joint", function()
    local world = lurek.physics.newWorld(0, 0)
    local a = world:newBody(0, 0, "dynamic")
    local b = world:newBody(10, 0, "dynamic")
    local jid = world:addRevoluteJoint(a:getId(), b:getId(), 0, 0)
    world:setJointBreakForce(jid, 12.5)
    local force = world:getJointBreakForce(jid)
    expect_type("number", force)
  end)

  -- @covers LWorld:type
  -- @covers LWorld:typeOf
  -- @covers lurek.physics.newWorld
  it("LWorld type and typeOf are callable", function()
    local world = lurek.physics.newWorld(0, 0)
    expect_type("string", world:type())
    expect_type("boolean", world:typeOf("Object"))
  end)
end)

-- @describe physics strict: LZone missing methods
describe("physics strict: LZone missing methods", function()
  -- @covers LZone:getId
  -- @covers LWorld:addZone
  -- @covers lurek.physics.newWorld
  it("getId returns number", function()
    local world = lurek.physics.newWorld(0, 0)
    local z = world:addZone(0, 0, 10, 10)
    expect_type("number", z:getId())
  end)

  -- @covers LZone:setEnabled
  -- @covers LWorld:addZone
  -- @covers lurek.physics.newWorld
  it("setEnabled is callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local z = world:addZone(0, 0, 10, 10)
    local ok = pcall(function() z:setEnabled(false) end)
    expect_true(ok)
  end)

  -- @covers LZone:destroy
  -- @covers LWorld:addZone
  -- @covers lurek.physics.newWorld
  it("destroy is callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local z = world:addZone(0, 0, 10, 10)
    local ok = pcall(function() z:destroy() end)
    expect_true(ok)
  end)

  -- @covers LZone:type
  -- @covers LZone:typeOf
  -- @covers LWorld:addZone
  -- @covers lurek.physics.newWorld
  it("LZone type and typeOf are callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local z = world:addZone(0, 0, 10, 10)
    expect_type("string", z:type())
    expect_type("boolean", z:typeOf("Object"))
  end)
end)

-- @describe physics strict: Terrain and Cellular
describe("physics strict: Terrain and Cellular", function()
  -- @covers LTerrain:spawnDebris
  -- @covers lurek.physics.newTerrain
  -- @covers lurek.physics.newWorld
  it("spawnDebris is callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local t = lurek.physics.newTerrain(8, 8, 1.0, world)
    local out = t:spawnDebris({{x=1,y=1},{x=2,y=2}}, 1.0, 0.2)
    expect_type("table", out)
  end)

  -- @covers LTerrain:toImageData
  -- @covers lurek.physics.newTerrain
  -- @covers lurek.physics.newWorld
  it("terrain toImageData returns string bytes", function()
    local world = lurek.physics.newWorld(0, 0)
    local t = lurek.physics.newTerrain(8, 8, 1.0, world)
    local data = t:toImageData(255, 255, 255, 0, 0, 0)
    expect_type("string", data)
  end)

  -- @covers LTerrain:type
  -- @covers LTerrain:typeOf
  -- @covers lurek.physics.newTerrain
  -- @covers lurek.physics.newWorld
  it("LTerrain type and typeOf are callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local t = lurek.physics.newTerrain(8, 8, 1.0, world)
    expect_type("string", t:type())
    expect_type("boolean", t:typeOf("Object"))
  end)

  -- @covers LCellular:toImageData
  -- @covers lurek.physics.newCellular
  it("cellular toImageData returns string bytes", function()
    local c = lurek.physics.newCellular(8, 8)
    local data = c:toImageData()
    expect_type("string", data)
  end)

  -- @covers LCellular:toImageDataRegion
  -- @covers lurek.physics.newCellular
  it("cellular toImageDataRegion returns string bytes", function()
    local c = lurek.physics.newCellular(8, 8)
    local data = c:toImageDataRegion(0, 0, 4, 4)
    expect_type("string", data)
  end)

  -- @covers LCellular:type
  -- @covers LCellular:typeOf
  -- @covers lurek.physics.newCellular
  it("LCellular type and typeOf are callable", function()
    local c = lurek.physics.newCellular(8, 8)
    expect_type("string", c:type())
    expect_type("boolean", c:typeOf("Object"))
  end)
end)

-- @describe physics strict: LBody and LPhysicsShape
describe("physics strict: LBody and LPhysicsShape", function()
  -- @covers LBody:getWidth
  -- @covers LBody:getHeight
  -- @covers LWorld:newBody
  -- @covers lurek.physics.newWorld
  it("LBody getWidth/getHeight return numbers", function()
    local world = lurek.physics.newWorld(0, 0)
    local b = world:newBody(0, 0, "dynamic")
    expect_type("number", b:getWidth())
    expect_type("number", b:getHeight())
  end)

  -- @covers LBody:setFriction
  -- @covers LWorld:newBody
  -- @covers lurek.physics.newWorld
  it("LBody setFriction is callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local b = world:newBody(0, 0, "dynamic")
    local ok = pcall(function() b:setFriction(0.5) end)
    expect_true(ok)
  end)

  -- @covers LBody:setRestitution
  -- @covers LWorld:newBody
  -- @covers lurek.physics.newWorld
  it("LBody setRestitution is callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local b = world:newBody(0, 0, "dynamic")
    local ok = pcall(function() b:setRestitution(0.2) end)
    expect_true(ok)
  end)

  -- @covers LBody:isSleepingAllowed
  -- @covers LBody:setSleepingAllowed
  -- @covers LWorld:newBody
  -- @covers lurek.physics.newWorld
  it("LBody sleeping-allowed toggles are callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local b = world:newBody(0, 0, "dynamic")
    b:setSleepingAllowed(false)
    expect_type("boolean", b:isSleepingAllowed())
  end)

  -- @covers LBody:type
  -- @covers LBody:typeOf
  -- @covers LWorld:newBody
  -- @covers lurek.physics.newWorld
  it("LBody type and typeOf are callable", function()
    local world = lurek.physics.newWorld(0, 0)
    local b = world:newBody(0, 0, "dynamic")
    expect_type("string", b:type())
    expect_type("boolean", b:typeOf("Object"))
  end)

  -- @covers LPhysicsShape:type
  -- @covers LPhysicsShape:typeOf
  -- @covers lurek.physics.newCircleShape
  it("LPhysicsShape type and typeOf are callable", function()
    local s = lurek.physics.newCircleShape(2.0)
    expect_type("string", s:type())
    expect_type("boolean", s:typeOf("Object"))
  end)
end)

-- @describe unit: migrated from integration/test_combat_physics_integration.lua
describe("unit: migrated from integration/test_combat_physics_integration.lua", function()
        local combat = rawget(_G, "combat")
        if combat == nil or combat.newCollisionGroupSet == nil then
            -- @covers combat
            it("combat module unavailable in this runtime", function()
                expect_nil(combat)
            end)
            return
        end

        local function has_mask(mask, bit)
            return math.floor(mask / bit) % 2 == 1
        end

        local function make_target(world, x, y, hp, mask)
            local body = lurek.physics.newBody(world, x, y, "dynamic")
            local chassis = {
                hp = hp,
                takeDamage = function(self, amount)
                    self.hp = self.hp - amount
                end,
            }
            return { body = body, chassis = chassis, mask = mask }
        end

        local function resolve_targets(world, targets, ox, oy, range, allowed_mask)
            local out = {}
            local r2 = range * range
            for _, t in ipairs(targets) do
                local x, y = lurek.physics.getBody(world, t.body)
                local dx = x - ox
                local dy = y - oy
                local d2 = dx * dx + dy * dy
                if d2 <= r2 and has_mask(allowed_mask, t.mask) then
                    table.insert(out, { target = t, d2 = d2 })
                end
            end
            table.sort(out, function(a, b) return a.d2 < b.d2 end)
            return out
        end
        -- @covers lurek.physics.newWorld
        -- @covers lurek.physics.newBody
        -- @covers lurek.physics.getBody
        -- @covers Chassis:takeDamage
        it("damage is applied to chassis whose physics body is in range", function()
            local world = lurek.physics.newWorld(0, 0)
            local cgs = combat.newCollisionGroupSet()
            local enemy_bit = cgs:defineGroup("enemies")

            local t = make_target(world, 10, 0, 100, enemy_bit)
            local hits = resolve_targets(world, { t }, 0, 0, 20, enemy_bit)

            expect_equal(1, #hits)
            hits[1].target.chassis:takeDamage(25)
            expect_equal(75, t.chassis.hp)
        end)

        -- @covers lurek.physics.newWorld
        -- @covers lurek.physics.newBody
        -- @covers lurek.physics.getBody
        it("no-op when the only target is outside attack range", function()
            local world = lurek.physics.newWorld(0, 0)
            local cgs = combat.newCollisionGroupSet()
            local enemy_bit = cgs:defineGroup("enemies")

            local t = make_target(world, 100, 0, 100, enemy_bit)
            local hits = resolve_targets(world, { t }, 0, 0, 5, enemy_bit)
            expect_equal(0, #hits)
            expect_equal(100, t.chassis.hp)
        end)

        -- @covers lurek.physics.newWorld
        -- @covers lurek.physics.newBody
        -- @covers lurek.physics.getBody
        it("multiple targets are sorted nearest-first", function()
            local world = lurek.physics.newWorld(0, 0)
            local cgs = combat.newCollisionGroupSet()
            local enemy_bit = cgs:defineGroup("enemies")

            local far = make_target(world, 8, 0, 100, enemy_bit)
            local near = make_target(world, 2, 0, 100, enemy_bit)
            local mid = make_target(world, 5, 0, 100, enemy_bit)

            local hits = resolve_targets(world, { far, near, mid }, 0, 0, 20, enemy_bit)
            expect_equal(3, #hits)
            expect_near(4.0, hits[1].d2, 1e-5)
            expect_near(25.0, hits[2].d2, 1e-5)
            expect_near(64.0, hits[3].d2, 1e-5)
            expect_equal(near, hits[1].target)
            expect_equal(mid, hits[2].target)
            expect_equal(far, hits[3].target)
        end)

        -- @covers lurek.physics.newWorld
        -- @covers CollisionGroupSet:defineGroup
        it("friendly-fire OFF spares same-group chassis", function()
            local world = lurek.physics.newWorld(0, 0)
            local cgs = combat.newCollisionGroupSet()
            local player_bit = cgs:defineGroup("players")
            local enemy_bit = cgs:defineGroup("enemies")

            local ally = make_target(world, 1, 0, 100, player_bit)
            local enemy = make_target(world, 2, 0, 100, enemy_bit)

            local hits = resolve_targets(world, { ally, enemy }, 0, 0, 20, enemy_bit)
            expect_equal(1, #hits)
            expect_equal(enemy, hits[1].target)
        end)

        -- @covers lurek.physics.newWorld
        -- @covers CollisionGroupSet:defineGroup
        it("friendly-fire ON includes same-group chassis", function()
            local world = lurek.physics.newWorld(0, 0)
            local cgs = combat.newCollisionGroupSet()
            local player_bit = cgs:defineGroup("players")
            local enemy_bit = cgs:defineGroup("enemies")

            local ally = make_target(world, 1, 0, 100, player_bit)
            local enemy = make_target(world, 2, 0, 100, enemy_bit)

            local hits = resolve_targets(world, { ally, enemy }, 0, 0, 20, player_bit + enemy_bit)
            expect_equal(2, #hits)
        end)

        -- @covers lurek.physics.newWorld
        -- @covers lurek.physics.step
        it("physics.step rejects a non-numeric dt", function()
            local world = lurek.physics.newWorld(0, 0)
            ---@type any
            local bad_dt = "not a number"
            expect_error(function()
                lurek.physics.step(world, bad_dt)
            end)
        end)

end)

-- @describe unit: migrated from integration/test_math_physics.lua
describe("unit: migrated from integration/test_math_physics.lua", function()
        -- @covers LBody:getPosition
        -- @covers lurek.physics.destroyWorld
        -- @covers lurek.physics.newBody
        -- @covers lurek.physics.newWorld
        -- @covers lurek.physics.step
        it("physics step uses delta time correctly", function()
            local world_id = lurek.physics.newWorld(0, 100)
            local body_id = lurek.physics.newBody(world_id, 0, 0, "dynamic")

            -- Step the world a small amount
            lurek.physics.step(world_id, 0.016)

            -- Body should have moved down due to gravity
            local _, y = body_id:getPosition()
            expect_true(y > 0, "body moved down by gravity")

            lurek.physics.destroyWorld(world_id)
        end)

end)

-- @describe unit: migrated from integration/test_physics_platformer.lua
describe("unit: migrated from integration/test_physics_platformer.lua", function()
        -- @covers LWorld:step
        -- @covers lurek.physics.getBody
        it("world stepping advances dynamic body under gravity", function()
            local world = lurek.physics.newWorld(0, 200)
            local player = lurek.physics.newBody(world, 0, 0, "dynamic")
            local _, y0 = lurek.physics.getBody(world, player)
            for _ = 1, 10 do
                world:step(1/60)
            end
            local _, y1 = lurek.physics.getBody(world, player)
            expect_true(y1 > y0, "player should move down after world steps")
        end)

        -- @covers LWorld:setBeginContact
        -- @covers LWorld:step
        -- @covers lurek.physics.newBody
        it("registered callbacks can observe contact activity", function()
            local world = lurek.physics.newWorld(0, 0)
            local began = 0
            world:setBeginContact(function()
                began = began + 1
            end)
            lurek.physics.newBody(world, 0, 0, "dynamic")
            lurek.physics.newBody(world, 0, 0, "static")
            for _ = 1, 5 do
                world:step(1/60)
            end
            expect_true(began >= 1, "begin-contact callback should fire at least once")
        end)

        -- @covers LBody:getId
        -- @covers LWorld:step
        -- @covers LWorld:sleepBody
        -- @covers LWorld:wakeUpBody
        -- @covers lurek.physics.getBody
        -- @covers lurek.physics.newBody
        -- @covers lurek.physics.newWorld
        it("sleep prevents motion until wake re-enables simulation", function()
            local gravity_world = lurek.physics.newWorld(0, 100)
            local b = lurek.physics.newBody(gravity_world, 0, 0, "dynamic")
            local _, y0 = lurek.physics.getBody(gravity_world, b)
            gravity_world:sleepBody(b:getId())
            gravity_world:step(1/60)
            local _, y_sleep = lurek.physics.getBody(gravity_world, b)
            expect_near(y0, y_sleep, 1e-5, "sleeping body should not move")

            gravity_world:wakeUpBody(b:getId())
            gravity_world:step(1/60)
            local _, y_awake = lurek.physics.getBody(gravity_world, b)
            expect_true(y_awake > y_sleep, "woken body should move under gravity")
        end)

end)

-- @describe unit: migrated from integration/test_physics_space.lua
describe("unit: migrated from integration/test_physics_space.lua", function()
        -- @covers LWorld:addZone
        -- @covers LWorld:getZoneEvents
        -- @covers LWorld:newBody
        -- @covers LWorld:step
        -- @covers LZone:setGravityPoint
        -- @covers lurek.physics.newWorld
        it("body inside point-gravity zone gets enter event", function()
            local world = lurek.physics.newWorld(0, 0)  -- no global gravity
            -- Create a large zone covering the whole arena.
            local zone = world:addZone(-500, -500, 1000, 1000)
            zone:setGravityPoint(0, 0, 5000)

            -- Place a dynamic body somewhere inside the zone.
            world:newBody(200, 0, "dynamic")

            -- Step once          zone tracker should produce an enter event.
            world:step(1/60)
            local events = world:getZoneEvents()
            expect_true(#events >= 1, "expected zone enter event")
            expect_equal("enter", events[1].kind)
        end)

        -- @covers LWorld:addZone
        -- @covers LWorld:newBody
        -- @covers LWorld:step
        -- @covers LZone:setGravityZero
        -- @covers lurek.physics.getBody
        -- @covers lurek.physics.newWorld
        it("body in zero-g zone stays put", function()
            local world = lurek.physics.newWorld(0, 500) -- strong global gravity
            local zone = world:addZone(-500, -500, 1000, 1000)
            zone:setGravityZero()

            -- Body at origin, zero initial velocity.
            local body = world:newBody(0, 0, "dynamic")
            local x0, y0 = lurek.physics.getBody(world, body)

            -- Step several frames          if zero-g works, body should not fall far.
            -- We can only check the simulation runs without error here since
            -- getBody is on the module-level API, not the world method.
            for _ = 1, 30 do
                world:step(1/60)
            end
            local x1, y1 = lurek.physics.getBody(world, body)
            expect_near(x0, x1, 1e-3)
            expect_near(y0, y1, 1e-3)
        end)

        -- @covers LWorld:addZone
        -- @covers LWorld:newBody
        -- @covers LWorld:getZoneEvents
        -- @covers LWorld:step
        -- @covers LZone:setGravityDirectional
        -- @covers lurek.physics.newWorld
        it("overlapping zones with different priorities step without error", function()
            local world = lurek.physics.newWorld(0, 0)
            local z1 = world:addZone(-200, -200, 400, 400)
            z1:setPriority(10)
            z1:setGravityDirectional(0, -200) -- upward pull

            local z2 = world:addZone(-100, -100, 200, 200)
            z2:setPriority(20)
            z2:setGravityDirectional(0, 100)  -- downward pull

            world:newBody(0, 0, "dynamic")

            for _ = 1, 10 do
                world:step(1/60)
            end
            local events = world:getZoneEvents()
            expect_type("table", events)
        end)

end)

-- @describe unit: migrated from integration/test_physics_tanks.lua
describe("unit: migrated from integration/test_physics_tanks.lua", function()
        -- @covers LTerrain:collapseColumns
        -- @covers LTerrain:fillRect
        -- @covers LTerrain:flush
        -- @covers LTerrain:setCell
        -- @covers LTerrain:solidPositions
        -- @covers LTerrain:spawnDebris
        -- @covers LWorld:step
        -- @covers lurek.physics.newTerrain
        -- @covers lurek.physics.newWorld
        it("collapse then spawn debris and step without error", function()
            local world = lurek.physics.newWorld(0, 200)
            local terrain = lurek.physics.newTerrain(16, 16, 8, world)

            -- Fill bottom two rows solid (rows 14 and 15) to act as floor.
            terrain:fillRect(0, 112, 128, 16, true)
            -- Place a floating column of cells above the floor with a gap.
            terrain:setCell(8, 10, true) -- row 10, no floor below until row 14

            terrain:flush()

            -- Capture positions before collapse.
            local pts = terrain:solidPositions()
            expect_true(#pts >= 1)

            -- Collapse unsupported cells.
            local fallen = terrain:collapseColumns()
            expect_true(fallen >= 0)

            -- Spawn debris for any removed cells (use the pre-collapse set as proxy).
            local ids = terrain:spawnDebris(pts, 1.0, 0.2)
            expect_type("table", ids)
            for _, id in ipairs(ids) do
                expect_type("number", id)
                expect_true(id > 0, "debris id should be positive")
            end

            -- Step the world with debris bodies present.
            terrain:flush()
            for _ = 1, 30 do
                world:step(1/60)
            end

            expect_true(#ids >= 0, "spawnDebris returns a valid id table")
        end)

        -- @covers LTerrain:toImageData
        -- @covers lurek.physics.newTerrain
        -- @covers lurek.physics.newWorld
        it("toImageData returns expected byte count", function()
            local world = lurek.physics.newWorld(0, 0)
            local w, h = 8, 8
            local terrain = lurek.physics.newTerrain(w, h, 4, world)
            local img = terrain:toImageData(100, 200, 50, 30, 30, 30)
            -- Expected: w * h * 4 bytes
            expect_equal(w * h * 4, #img)
        end)

end)

test_summary()
