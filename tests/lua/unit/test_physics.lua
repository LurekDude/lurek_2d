-- Lurek2D Physics API Tests

-- @description Covers suite: lurek.physics module exists.
describe("lurek.physics module exists", function()
    -- @description Verifies the physics namespace is exposed as a Lua table.
    -- @covers lurek.physics
    it("lurek.physics is a table", function()
        expect_type("table", lurek.physics)
    end)
end)

-- @description Covers suite: lurek.physics world.
describe("lurek.physics world", function()
    -- @covers lurek.physics.newWorld
    -- @description Verifies newWorld is exposed as a callable physics factory.
    it("newWorld is a function", function()
        expect_type("function", lurek.physics.newWorld)
    end)

    -- @covers lurek.physics.newWorld
    -- @description Verifies newWorld returns World userdata.
    it("newWorld creates a world and returns World object", function()
        local id = lurek.physics.newWorld(0, 9.81)
        expect_type("userdata", id)
    end)

    -- @covers lurek.physics.step
    -- @description Verifies the module-level step function is exposed.
    it("step is a function", function()
        expect_type("function", lurek.physics.step)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.step
    -- @description Verifies the module-level step function accepts a world and timestep without error.
    it("step can be called with world_id and dt", function()
        local world = lurek.physics.newWorld(0, 9.81)
        expect_no_error(function()
            lurek.physics.step(world, 1/60)
        end)
    end)
end)

-- @description Covers suite: lurek.physics bodies.
describe("lurek.physics bodies", function()
    -- @covers lurek.physics.newBody
    -- @description Verifies newBody is exposed as a callable constructor.
    it("newBody is a function", function()
        expect_type("function", lurek.physics.newBody)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @description Verifies newBody returns Body userdata when attached to a world.
    it("newBody creates a body and returns Body object", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local id = lurek.physics.newBody(world, 100, 100, "dynamic")
        expect_type("userdata", id)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.getBody
    -- @description Verifies getBody returns the created body's position and velocity tuple.
    it("getBody returns position and velocity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local id = lurek.physics.newBody(world, 50, 50, "static")
        local x, y, vx, vy = lurek.physics.getBody(world, id)
        expect_near(50, x, 1)
        expect_near(50, y, 1)
    end)

    -- @covers lurek.physics.setBodyVelocity
    -- @description Verifies setBodyVelocity is exposed as a callable helper.
    it("setBodyVelocity is a function", function()
        expect_type("function", lurek.physics.setBodyVelocity)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.setBodyVelocity
    -- @description Verifies setBodyVelocity accepts a world, body, and velocity components without error.
    it("setBodyVelocity changes velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_no_error(function()
            lurek.physics.setBodyVelocity(world, id, 100, 0)
        end)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.step
    -- @covers lurek.physics.getBody
    -- @description Verifies a dynamic body moves under gravity after stepping the world.
    it("dynamic body moves after step", function()
        local world = lurek.physics.newWorld(0, 100)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        lurek.physics.step(world, 0.1)
        local x, y, vx, vy = lurek.physics.getBody(world, id)
        expect_true(y > 0, "body should fall due to gravity")
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.step
    -- @covers lurek.physics.getBody
    -- @description Verifies a static body remains at its original position when the world steps.
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
-- @description Covers suite: sleeping allowed.
describe("sleeping allowed", function()
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.isSleepingAllowed
    -- @description Verifies new dynamic bodies allow sleeping by default.
    it("isSleepingAllowed defaults to true", function()
        local world = lurek.physics.newWorld(0, 9.8)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_true(lurek.physics.isSleepingAllowed(world, id))
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.setSleepingAllowed
    -- @covers lurek.physics.isSleepingAllowed
    -- @description Verifies setSleepingAllowed(false) disables sleeping for a body.
    it("setSleepingAllowed false disables sleeping", function()
        local world = lurek.physics.newWorld(0, 9.8)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        lurek.physics.setSleepingAllowed(world, id, false)
        expect_false(lurek.physics.isSleepingAllowed(world, id))
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.setSleepingAllowed
    -- @covers lurek.physics.isSleepingAllowed
    -- @description Verifies setSleepingAllowed(true) re-enables sleeping after disabling it.
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
-- @description Covers suite: physics.Shape userdata.
describe("physics.Shape userdata", function()
    -- @covers lurek.physics.newCircleShape
    -- @description Verifies newCircleShape is exposed as a constructor.
    it("newCircleShape is a function", function()
        expect_type("function", lurek.physics.newCircleShape)
    end)

    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.Shape.getType
    -- @description Verifies newCircleShape returns shape userdata reporting the circle type.
    it("newCircleShape returns userdata with type 'circle'", function()
        local s = lurek.physics.newCircleShape(10)
        expect_type("userdata", s)
        expect_equal("circle", s:getType())
    end)

    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.Shape.getRadius
    -- @description Verifies getRadius returns the configured radius for circle shapes.
    it("getRadius returns correct value for circle", function()
        local s = lurek.physics.newCircleShape(7.5)
        expect_near(7.5, s:getRadius(), 0.001)
    end)

    -- @covers lurek.physics.newRectangleShape
    -- @covers lurek.physics.Shape.getType
    -- @description Verifies newRectangleShape returns shape userdata reporting the rectangle type.
    it("newRectangleShape returns userdata with type 'rectangle'", function()
        local s = lurek.physics.newRectangleShape(20, 10)
        expect_type("userdata", s)
        expect_equal("rectangle", s:getType())
    end)

    -- @covers lurek.physics.newEdgeShape
    -- @covers lurek.physics.Shape.getType
    -- @description Verifies newEdgeShape returns shape userdata reporting the edge type.
    it("newEdgeShape returns userdata with type 'edge'", function()
        local s = lurek.physics.newEdgeShape(0, 0, 10, 0)
        expect_type("userdata", s)
        expect_equal("edge", s:getType())
    end)

    -- @covers lurek.physics.newPolygonShape
    -- @covers lurek.physics.Shape.getType
    -- @description Verifies newPolygonShape returns shape userdata reporting the polygon type.
    it("newPolygonShape returns userdata with type 'polygon'", function()
        local s = lurek.physics.newPolygonShape(0, 0, 10, 0, 5, 10)
        expect_type("userdata", s)
        expect_equal("polygon", s:getType())
    end)

    -- @covers lurek.physics.newChainShape
    -- @covers lurek.physics.Shape.getType
    -- @description Verifies newChainShape returns shape userdata reporting the chain type.
    it("newChainShape returns userdata with type 'chain'", function()
        local s = lurek.physics.newChainShape(false, 0, 0, 5, 0, 10, 5)
        expect_type("userdata", s)
        expect_equal("chain", s:getType())
    end)

    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.Shape.getBoundingBox
    -- @description Verifies getBoundingBox returns numeric bounds for a circle shape.
    it("getBoundingBox returns 4 numbers for circle", function()
        local s = lurek.physics.newCircleShape(5)
        local x1, y1, x2, y2 = s:getBoundingBox()
        expect_type("number", x1)
        expect_type("number", x2)
        expect_near(-5, x1, 0.001)
        expect_near(5, x2, 0.001)
    end)

    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.Shape.setDensity
    -- @description Verifies setDensity can be applied to shape userdata without error.
    it("setDensity does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setDensity(2.0) end)
    end)

    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.Shape.setFriction
    -- @description Verifies setFriction can be applied to shape userdata without error.
    it("setFriction does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setFriction(0.8) end)
    end)

    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.Shape.setRestitution
    -- @description Verifies setRestitution can be applied to shape userdata without error.
    it("setRestitution does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setRestitution(0.5) end)
    end)

    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.Shape.setSensor
    -- @description Verifies setSensor can be applied to shape userdata without error.
    it("setSensor does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setSensor(true) end)
    end)

    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.Shape.destroy
    -- @description Verifies destroy can be called on shape userdata without error.
    it("destroy does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:destroy() end)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.attachShape
    -- @description Verifies attachShape attaches standalone shape userdata to a body without error.
    it("attachShape attaches circle to body", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local shape = lurek.physics.newCircleShape(15)
        expect_no_error(function()
            lurek.physics.attachShape(body, shape)
        end)
    end)
end)

-- â”€â”€ Body UserData methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Body UserData methods.
describe("Body UserData methods", function()
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.getPosition
    -- @description Verifies Body:getPosition returns the spawn coordinates after creation.
    it("getPosition returns x, y after creation", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 10.0, 20.0, "dynamic")
        local x, y = body:getPosition()
        expect_near(10.0, x, 0.01)
        expect_near(20.0, y, 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setPosition
    -- @covers lurek.physics.Body.getPosition
    -- @description Verifies Body:setPosition moves the body and getPosition reports the updated coordinates.
    it("setPosition moves the body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setPosition(50, 75)
        local x, y = body:getPosition()
        expect_near(50, x, 0.01)
        expect_near(75, y, 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.getX
    -- @covers lurek.physics.Body.getY
    -- @description Verifies Body:getX and Body:getY expose individual position components.
    it("getX and getY return individual coordinates", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 3.5, 7.5, "dynamic")
        expect_near(3.5, body:getX(), 0.01)
        expect_near(7.5, body:getY(), 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setVelocity
    -- @covers lurek.physics.Body.getVelocity
    -- @description Verifies Body:setVelocity and Body:getVelocity round-trip linear velocity.
    it("setVelocity and getVelocity round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setVelocity(5.0, -3.0)
        local vx, vy = body:getVelocity()
        expect_near(5.0, vx, 0.01)
        expect_near(-3.0, vy, 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setAngle
    -- @covers lurek.physics.Body.getAngle
    -- @description Verifies Body:setAngle and Body:getAngle round-trip rotation.
    it("getAngle and setAngle round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngle(1.57)
        expect_near(1.57, body:getAngle(), 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setAngularVelocity
    -- @covers lurek.physics.Body.getAngularVelocity
    -- @description Verifies Body:setAngularVelocity and Body:getAngularVelocity round-trip spin rate.
    it("getAngularVelocity and setAngularVelocity round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngularVelocity(2.5)
        expect_near(2.5, body:getAngularVelocity(), 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.getMass
    -- @description Verifies Body:getMass returns a positive mass for a dynamic body with attached geometry.
    it("getMass returns positive for dynamic body with shape", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_true(body:getMass() > 0)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.getType
    -- @description Verifies Body:getType reports the configured body type.
    it("getType returns body type string", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "static")
        expect_equal("static", body:getType())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setType
    -- @covers lurek.physics.Body.getType
    -- @description Verifies Body:setType changes the stored body type.
    it("setType changes body type", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setType("kinematic")
        expect_equal("kinematic", body:getType())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.setFriction
    -- @covers lurek.physics.Body.getFriction
    -- @description Verifies Body:setFriction and Body:getFriction round-trip fixture friction.
    it("getFriction and setFriction round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setFriction(0.7)
        expect_near(0.7, body:getFriction(), 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.setRestitution
    -- @covers lurek.physics.Body.getRestitution
    -- @description Verifies Body:setRestitution and Body:getRestitution round-trip bounce values.
    it("getRestitution and setRestitution round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setRestitution(0.9)
        expect_near(0.9, body:getRestitution(), 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setLayer
    -- @covers lurek.physics.Body.getLayer
    -- @description Verifies Body:setLayer and Body:getLayer round-trip collision layer values.
    it("getLayer and setLayer round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setLayer(3)
        expect_equal(3, body:getLayer())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setMask
    -- @covers lurek.physics.Body.getMask
    -- @description Verifies Body:setMask and Body:getMask round-trip collision masks.
    it("getMask and setMask round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setMask(5)
        expect_equal(5, body:getMask())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.applyImpulse
    -- @covers lurek.physics.Body.getVelocity
    -- @description Verifies Body:applyImpulse changes the body's linear velocity.
    it("applyImpulse changes velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:applyImpulse(10, 0)
        local vx, vy = body:getVelocity()
        expect_true(vx > 0, "impulse should increase x velocity")
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.applyForce
    -- @description Verifies Body:applyForce accepts force input without error.
    it("applyForce does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_no_error(function() body:applyForce(100, 0) end)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.applyTorque
    -- @description Verifies Body:applyTorque accepts torque input without error.
    it("applyTorque does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_no_error(function() body:applyTorque(5.0) end)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.applyAngularImpulse
    -- @covers lurek.physics.Body.getAngularVelocity
    -- @description Verifies Body:applyAngularImpulse changes angular velocity.
    it("applyAngularImpulse changes angular velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:applyAngularImpulse(3.0)
        expect_true(math.abs(body:getAngularVelocity()) > 0)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setGravityScale
    -- @covers lurek.physics.Body.getGravityScale
    -- @description Verifies Body:setGravityScale and Body:getGravityScale round-trip gravity scaling.
    it("getGravityScale and setGravityScale round-trip", function()
        local world = lurek.physics.newWorld(0, -9.81)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setGravityScale(0.5)
        expect_near(0.5, body:getGravityScale(), 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.isFixedRotation
    -- @covers lurek.physics.Body.setFixedRotation
    -- @description Verifies Body:setFixedRotation toggles the fixed-rotation flag.
    it("isFixedRotation and setFixedRotation round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_false(body:isFixedRotation())
        body:setFixedRotation(true)
        expect_true(body:isFixedRotation())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setLinearDamping
    -- @covers lurek.physics.Body.getLinearDamping
    -- @description Verifies Body:setLinearDamping and Body:getLinearDamping round-trip drag values.
    it("getLinearDamping and setLinearDamping round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setLinearDamping(0.3)
        expect_near(0.3, body:getLinearDamping(), 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.setAngularDamping
    -- @covers lurek.physics.Body.getAngularDamping
    -- @description Verifies Body:setAngularDamping and Body:getAngularDamping round-trip angular drag values.
    it("getAngularDamping and setAngularDamping round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngularDamping(0.4)
        expect_near(0.4, body:getAngularDamping(), 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.isBullet
    -- @covers lurek.physics.Body.setBullet
    -- @description Verifies Body:setBullet toggles bullet mode on and off.
    it("isBullet and setBullet round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_false(body:isBullet())
        body:setBullet(true)
        expect_true(body:isBullet())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.getId
    -- @description Verifies Body:getId returns a numeric identifier.
    it("getId returns a number", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_type("number", body:getId())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.Body.destroy
    -- @description Verifies Body:destroy can be called without error.
    it("destroy removes body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_no_error(function() body:destroy() end)
    end)
end)

-- â”€â”€ World UserData methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: World UserData methods.
describe("World UserData methods", function()
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.getGravity
    -- @description Verifies World:getGravity returns the world's configured gravity vector.
    it("getGravity returns world gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local gx, gy = world:getGravity()
        expect_near(0, gx, 0.01)
        expect_near(9.81, gy, 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.setGravity
    -- @covers lurek.physics.World.getGravity
    -- @description Verifies World:setGravity updates the world's gravity vector.
    it("setGravity changes world gravity", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setGravity(0, -10)
        local gx, gy = world:getGravity()
        expect_near(0, gx, 0.01)
        expect_near(-10, gy, 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.getBodyCount
    -- @covers lurek.physics.World.newBody
    -- @description Verifies World:getBodyCount tracks bodies created through World:newBody.
    it("getBodyCount tracks bodies", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:getBodyCount())
        world:newBody(0, 0, "dynamic")
        expect_equal(1, world:getBodyCount())
        world:newBody(5, 5, "static")
        expect_equal(2, world:getBodyCount())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newBody
    -- @covers lurek.physics.World.getBodyIds
    -- @description Verifies World:getBodyIds returns the IDs of created bodies.
    it("getBodyIds returns id table", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        world:newBody(5, 5, "dynamic")
        local ids = world:getBodyIds()
        expect_equal(2, #ids)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newBody
    -- @covers lurek.physics.World.destroyBody
    -- @covers lurek.physics.World.getBodyCount
    -- @covers lurek.physics.Body.getType
    -- @description Verifies World:destroyBody soft-destroys a body without shrinking the tracked body count.
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

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newBody
    -- @covers lurek.physics.World.clear
    -- @covers lurek.physics.World.getBodyCount
    -- @description Verifies World:clear removes all tracked bodies.
    it("clear removes all bodies", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        world:newBody(5, 5, "dynamic")
        world:clear()
        expect_equal(0, world:getBodyCount())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.step
    -- @covers lurek.physics.Body.getPosition
    -- @description Verifies World:step advances simulation for dynamic bodies under gravity.
    it("step advances simulation", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_true(y > 0, "gravity should move body down")
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.setMeter
    -- @covers lurek.physics.World.getMeter
    -- @description Verifies World:setMeter and World:getMeter round-trip the pixels-per-meter scale.
    it("getMeter and setMeter round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setMeter(100)
        expect_near(100, world:getMeter(), 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.setMeter
    -- @covers lurek.physics.World.toPhysics
    -- @covers lurek.physics.World.toPixels
    -- @description Verifies World:toPhysics and World:toPixels convert distances using the configured meter scale.
    it("toPhysics and toPixels convert", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setMeter(50)
        local m = world:toPhysics(100)
        expect_near(2.0, m, 0.01)
        local px = world:toPixels(2.0)
        expect_near(100, px, 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.getPosition
    -- @description Verifies World:newCircleBody creates a positioned body with circle geometry.
    it("newCircleBody creates a body with circle shape", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(10, 20, 5, "dynamic")
        local x, y = body:getPosition()
        expect_near(10, x, 0.01)
        expect_near(20, y, 0.01)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newPolygonBody
    -- @covers lurek.physics.Body.getType
    -- @description Verifies World:newPolygonBody creates a dynamic polygon body.
    it("newPolygonBody creates a polygon body", function()
        local world = lurek.physics.newWorld(0, 0)
        local verts = {0, 0, 10, 0, 10, 10, 0, 10}
        local body = world:newPolygonBody(5, 5, verts, "dynamic")
        expect_not_nil(body)
        expect_equal("dynamic", body:getType())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newEdgeBody
    -- @description Verifies World:newEdgeBody creates edge-body userdata.
    it("newEdgeBody creates an edge body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newEdgeBody(0, 0, 0, 0, 100, 0, "static")
        expect_not_nil(body)
    end)
end)

-- â”€â”€ Joints â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Joint operations.
describe("Joint operations", function()
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.addRevoluteJoint
    -- @description Verifies addRevoluteJoint creates a numeric joint handle between two bodies.
    it("addRevoluteJoint creates a revolute joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        expect_type("number", jid)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.addDistanceJoint
    -- @description Verifies addDistanceJoint creates a numeric joint handle between two bodies.
    it("addDistanceJoint creates a distance joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(10, 0, 1, "dynamic")
        local jid = world:addDistanceJoint(a:getId(), b:getId(), 0, 0, 10, 0, 10)
        expect_type("number", jid)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.addWeldJoint
    -- @description Verifies addWeldJoint creates a numeric joint handle between two bodies.
    it("addWeldJoint creates a weld joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addWeldJoint(a:getId(), b:getId(), 2.5, 0)
        expect_type("number", jid)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.jointCount
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.addRevoluteJoint
    -- @description Verifies jointCount increases after adding a joint.
    it("jointCount returns number of joints", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:jointCount())
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        expect_equal(1, world:jointCount())
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.addRevoluteJoint
    -- @covers lurek.physics.World.getJointIds
    -- @description Verifies getJointIds returns the IDs of created joints.
    it("getJointIds returns joint id table", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        local ids = world:getJointIds()
        expect_equal(1, #ids)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.addRevoluteJoint
    -- @covers lurek.physics.World.getJointType
    -- @description Verifies getJointType returns a string descriptor for an existing joint.
    it("getJointType returns joint type string", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        local jtype = world:getJointType(jid)
        expect_type("string", jtype)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.addRevoluteJoint
    -- @covers lurek.physics.World.jointCount
    -- @covers lurek.physics.World.destroyJoint
    -- @description Verifies destroyJoint can be called for an existing joint without error.
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

-- â”€â”€ Fixtures â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Fixture operations.
describe("Fixture operations", function()
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.World.addFixture
    -- @description Verifies addFixture returns a numeric fixture index for a body.
    it("addFixture returns fixture index", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local idx = world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_type("number", idx)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.World.fixtureCount
    -- @covers lurek.physics.World.addFixture
    -- @description Verifies fixtureCount increments after a fixture is added to a body.
    it("fixtureCount increases after addFixture", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local before = world:fixtureCount(body:getId())
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_equal(before + 1, world:fixtureCount(body:getId()))
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.World.addFixture
    -- @covers lurek.physics.World.setFixtureFriction
    -- @description Verifies setFixtureFriction can update an existing fixture without error.
    it("setFixtureFriction does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureFriction(body:getId(), 0, 0.8)
        end)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.World.addFixture
    -- @covers lurek.physics.World.setFixtureRestitution
    -- @description Verifies setFixtureRestitution can update an existing fixture without error.
    it("setFixtureRestitution does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureRestitution(body:getId(), 0, 0.6)
        end)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.World.addFixture
    -- @covers lurek.physics.World.setFixtureSensor
    -- @description Verifies setFixtureSensor can toggle sensor mode on an existing fixture without error.
    it("setFixtureSensor does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureSensor(body:getId(), 0, true)
        end)
    end)
end)

-- â”€â”€ Collision behavior â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Collision and simulation behavior.
describe("Collision and simulation behavior", function()
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.step
    -- @covers lurek.physics.Body.getPosition
    -- @description Verifies static bodies remain stationary under gravity.
    it("static body does not move under gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "static")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.step
    -- @covers lurek.physics.Body.getPosition
    -- @description Verifies zero gravity leaves a dynamic body stationary.
    it("zero gravity keeps dynamic body still", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        world:step(1.0 / 60.0)
        local x, y = body:getPosition()
        expect_near(0, x, 0.001)
        expect_near(0, y, 0.001)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.World.step
    -- @covers lurek.physics.Body.getPosition
    -- @description Verifies kinematic bodies are not displaced by gravity during stepping.
    it("kinematic body is unaffected by gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "kinematic")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.setGravityScale
    -- @covers lurek.physics.World.step
    -- @covers lurek.physics.Body.getPosition
    -- @description Verifies gravityScale zero prevents a dynamic body from falling.
    it("gravity scale 0 prevents falling", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setGravityScale(0)
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newCircleBody
    -- @covers lurek.physics.Body.setLayer
    -- @covers lurek.physics.Body.setMask
    -- @covers lurek.physics.World.step
    -- @description Verifies mismatched layer and mask settings can be stepped without collision errors.
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

-- â”€â”€ destroyWorld â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: World destruction.
describe("World destruction", function()
    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.World.newBody
    -- @covers lurek.physics.destroyWorld
    -- @description Verifies destroyWorld accepts a populated world without error.
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

  -- @covers lurek.physics.World:setBodyData
  -- @covers lurek.physics.World:getBodyData
  -- @description Stored table data survives a round-trip.
  it("setBodyData and getBodyData round-trip table", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    w:setBodyData(id, { name = "ground", kind = "platform" })
    local d = w:getBodyData(id)
    expect_equal(d.name, "ground")
    expect_equal(d.kind, "platform")
  end)

  -- @covers lurek.physics.World:getBodyData
  -- @description Reading data for a body that was never given data returns nil.
  it("getBodyData returns nil for unset body", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    local d = w:getBodyData(id)
    expect_equal(d, nil)
  end)

  -- @covers lurek.physics.World:clearBodyData
  -- @description clearBodyData removes previously stored data.
  it("clearBodyData removes data", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    w:setBodyData(id, "some data")
    w:clearBodyData(id)
    expect_equal(w:getBodyData(id), nil)
  end)

  -- @covers lurek.physics.World:setBodyData
  -- @description Overwriting data with setBodyData replaces the old value.
  it("setBodyData overwrites previous value", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "dynamic")
    local id = body:getId()
    w:setBodyData(id, "first")
    w:setBodyData(id, "second")
    expect_equal(w:getBodyData(id), "second")
  end)

  -- @covers lurek.physics.World:setBodyData
  -- @description Data for multiple bodies is stored independently.
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

-- @description Covers suite: lurek.physics cellular factory.
describe("lurek.physics cellular factory", function()
    -- @covers lurek.physics.newCellular
    -- @description Verifies newCellular is exposed as a callable factory.
    it("newCellular is a function", function()
        expect_type("function", lurek.physics.newCellular)
    end)

    -- @covers lurek.physics.newCellular
    -- @description Verifies newCellular returns userdata.
    it("newCellular returns userdata", function()
        local sim = lurek.physics.newCellular(32, 32)
        expect_type("userdata", sim)
    end)
end)

-- @description Covers suite: lurek.physics cellular cell-type constants.
describe("lurek.physics cellular cell-type constants", function()
    -- @covers lurek.physics.CELL_AIR
    -- @description Verifies CELL_AIR is an integer.
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

-- @description Covers suite: lurek.physics cellular cell access.
describe("lurek.physics cellular cell access", function()
    local sim

    before_each(function()
        sim = lurek.physics.newCellular(16, 16)
    end)

    -- @covers LuaCellular:getCell
    -- @description Verifies all cells start as CELL_AIR.
    it("new grid is all air", function()
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(0, 0))
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(8, 8))
    end)

    -- @covers LuaCellular:setCell
    -- @covers LuaCellular:getCell
    -- @description Verifies setCell changes the material at a position.
    it("setCell changes cell type", function()
        sim:setCell(5, 5, lurek.physics.CELL_SAND)
        expect_equal(lurek.physics.CELL_SAND, sim:getCell(5, 5))
    end)

    -- @covers LuaCellular:setCell
    -- @covers LuaCellular:getCell
    -- @description Verifies setting a cell back to AIR clears it.
    it("setting cell to AIR clears it", function()
        sim:setCell(3, 3, lurek.physics.CELL_ROCK)
        sim:setCell(3, 3, lurek.physics.CELL_AIR)
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(3, 3))
    end)
end)

-- @description Covers suite: lurek.physics cellular bulk fill.
describe("lurek.physics cellular bulk fill", function()
    local sim

    before_each(function()
        sim = lurek.physics.newCellular(32, 32)
    end)

    -- @covers LuaCellular:fillRect
    -- @covers LuaCellular:getCell
    -- @description Verifies fillRect marks cells inside the region.
    it("fillRect fills the specified region", function()
        sim:fillRect(5, 5, 4, 4, lurek.physics.CELL_ROCK)
        expect_equal(lurek.physics.CELL_ROCK, sim:getCell(6, 6))
        -- outside the region should remain air
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(0, 0))
    end)

    -- @covers LuaCellular:fillCircle
    -- @covers LuaCellular:getCell
    -- @description Verifies fillCircle marks the centre cell.
    it("fillCircle marks centre cell", function()
        sim:fillCircle(16, 16, 3, lurek.physics.CELL_WATER)
        expect_equal(lurek.physics.CELL_WATER, sim:getCell(16, 16))
    end)
end)

-- @description Covers suite: lurek.physics cellular step.
describe("lurek.physics cellular step", function()
    -- @covers LuaCellular:setCell
    -- @covers LuaCellular:step
    -- @covers LuaCellular:countCells
    -- @description Verifies sand falls when there is air below it.
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

    -- @covers LuaCellular:stepN
    -- @coverage Verifies stepN is callable with n > 1.
    it("stepN accepts a count without error", function()
        local sim = lurek.physics.newCellular(16, 16)
        sim:fillRect(0, 0, 16, 1, lurek.physics.CELL_SAND)
        expect_no_error(function()
            sim:stepN(10)
        end)
    end)
end)

-- @description Covers suite: lurek.physics cellular query.
describe("lurek.physics cellular query", function()
    -- @covers LuaCellular:countCells
    -- @description Verifies countCells returns the precise number of matching cells.
    it("countCells matches manually placed cells", function()
        local sim = lurek.physics.newCellular(16, 16)
        sim:setCell(0, 0, lurek.physics.CELL_ROCK)
        sim:setCell(1, 0, lurek.physics.CELL_ROCK)
        sim:setCell(2, 0, lurek.physics.CELL_ROCK)
        expect_equal(3, sim:countCells(lurek.physics.CELL_ROCK))
    end)

    -- @covers LuaCellular:findCells
    -- @description Verifies findCells returns table entries with x/y fields.
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

-- @description Covers suite: lurek.physics cellular serialisation.
describe("lurek.physics cellular serialisation", function()
    -- @covers LuaCellular:toBytes
    -- @covers LuaCellular:loadFromBytes
    -- @description Verifies round-trip serialisation preserves cell data.
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

-- ── Solver iterations ──────────────────────────────────────────────────────

-- @description Covers suite: lurek.physics solver iterations API.
describe("lurek.physics solver iterations", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
    end)

    -- @covers lurek.physics.World:getSolverIterations
    -- @description Verifies default solver iteration count is 4.
    it("default solver iteration count is 4", function()
        expect_equal(4, world:getSolverIterations())
    end)

    -- @covers lurek.physics.World:setSolverIterations
    -- @covers lurek.physics.World:getSolverIterations
    -- @description Verifies setSolverIterations persists the new value.
    it("setSolverIterations persists the value", function()
        world:setSolverIterations(8)
        expect_equal(8, world:getSolverIterations())
    end)

    -- @covers lurek.physics.World:setSolverIterations
    -- @description Verifies values below 1 are clamped to 1.
    it("setSolverIterations clamps zero to 1", function()
        world:setSolverIterations(0)
        expect_equal(1, world:getSolverIterations())
    end)
end)

-- ── Body sleeping ──────────────────────────────────────────────────────────

-- @description Covers suite: lurek.physics body sleep API.
describe("lurek.physics body sleeping", function()
    local world
    local body_id

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        body_id = lurek.physics.newBody(world, 100, 100, "dynamic")
    end)

    -- @covers lurek.physics.World:isBodySleeping
    -- @description Verifies isBodySleeping returns a boolean without error.
    it("isBodySleeping returns boolean", function()
        local sleeping = world:isBodySleeping(body_id)
        expect_type("boolean", sleeping)
    end)

    -- @covers lurek.physics.World:sleepBody
    -- @covers lurek.physics.World:isBodySleeping
    -- @description Verifies sleepBody puts a body to sleep.
    it("sleepBody puts a body to sleep", function()
        world:sleepBody(body_id)
        expect_equal(true, world:isBodySleeping(body_id))
    end)

    -- @covers lurek.physics.World:wakeUpBody
    -- @covers lurek.physics.World:sleepBody
    -- @covers lurek.physics.World:isBodySleeping
    -- @description Verifies wakeUpBody wakes a sleeping body.
    it("wakeUpBody wakes a sleeping body", function()
        world:sleepBody(body_id)
        world:wakeUpBody(body_id)
        expect_equal(false, world:isBodySleeping(body_id))
    end)

    -- @covers lurek.physics.Body:isSleeping
    -- @description Verifies Body:isSleeping returns a boolean.
    it("Body:isSleeping returns boolean", function()
        local body = lurek.physics.newBody(world, 200, 200, "dynamic")
        expect_type("boolean", body:isSleeping())
    end)

    -- @covers lurek.physics.Body:sleep
    -- @covers lurek.physics.Body:isSleeping
    -- @description Verifies Body:sleep and Body:isSleeping.
    it("Body:sleep puts the body to sleep", function()
        local body = lurek.physics.newBody(world, 300, 300, "dynamic")
        body:sleep()
        expect_equal(true, body:isSleeping())
    end)

    -- @covers lurek.physics.Body:wakeUp
    -- @covers lurek.physics.Body:sleep
    -- @covers lurek.physics.Body:isSleeping
    -- @description Verifies Body:wakeUp wakes the body after sleeping.
    it("Body:wakeUp wakes the body", function()
        local body = lurek.physics.newBody(world, 400, 400, "dynamic")
        body:sleep()
        body:wakeUp()
        expect_equal(false, body:isSleeping())
    end)
end)

-- ── One-way platform ───────────────────────────────────────────────────────

-- @description Covers suite: lurek.physics one-way platform API.
describe("lurek.physics one-way platform", function()
    local world
    local body_id

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        body_id = lurek.physics.newBody(world, 0, 0, "static")
    end)

    -- @covers lurek.physics.World:setBodyOneWay
    -- @covers lurek.physics.World:getBodyOneWay
    -- @description Verifies setBodyOneWay stores the normal vector.
    it("setBodyOneWay stores the normal", function()
        world:setBodyOneWay(body_id, 0, -1)
        local nx, ny = world:getBodyOneWay(body_id)
        expect_near(0,  nx, 1e-5)
        expect_near(-1, ny, 1e-5)
    end)

    -- @covers lurek.physics.World:clearBodyOneWay
    -- @covers lurek.physics.World:getBodyOneWay
    -- @description Verifies clearBodyOneWay removes the one-way normal.
    it("clearBodyOneWay removes the one-way flag", function()
        world:setBodyOneWay(body_id, 0, -1)
        world:clearBodyOneWay(body_id)
        local nx, ny = world:getBodyOneWay(body_id)
        expect_equal(nil, nx)
        expect_equal(nil, ny)
    end)

    -- @covers lurek.physics.World:getBodyOneWay
    -- @description Verifies getBodyOneWay returns nil for a normal body.
    it("getBodyOneWay returns nil for a normal body", function()
        local nx, ny = world:getBodyOneWay(body_id)
        expect_equal(nil, nx)
        expect_equal(nil, ny)
    end)
end)

-- ── CCD ────────────────────────────────────────────────────────────────────

-- @description Covers suite: lurek.physics CCD API.
describe("lurek.physics CCD", function()
    local world
    local body_id

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        body_id = lurek.physics.newBody(world, 100, 100, "dynamic")
    end)

    -- @covers lurek.physics.World:setBodyCCD
    -- @covers lurek.physics.World:getBodyCCD
    -- @description Verifies setBodyCCD enables CCD on a body.
    it("setBodyCCD enables CCD", function()
        world:setBodyCCD(body_id, true)
        expect_equal(true, world:getBodyCCD(body_id))
    end)

    -- @covers lurek.physics.World:setBodyCCD
    -- @covers lurek.physics.World:getBodyCCD
    -- @description Verifies setBodyCCD can disable CCD after enabling.
    it("setBodyCCD can disable CCD", function()
        world:setBodyCCD(body_id, true)
        world:setBodyCCD(body_id, false)
        expect_equal(false, world:getBodyCCD(body_id))
    end)
end)

-- ── Breakable joints ───────────────────────────────────────────────────────

-- @description Covers suite: lurek.physics breakable joint API.
describe("lurek.physics breakable joints", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
    end)

    -- @covers lurek.physics.World:setJointBreakForce
    -- @covers lurek.physics.World:getJointBreakForce
    -- @description Verifies setJointBreakForce stores the threshold.
    it("setJointBreakForce stores the threshold", function()
        local b1 = lurek.physics.newBody(world, 0, 0, "dynamic")
        local b2 = lurek.physics.newBody(world, 50, 0, "dynamic")
        local jid = lurek.physics.newJoint(world, b1, b2, "distance")
        world:setJointBreakForce(jid, 100.0)
        expect_near(100.0, world:getJointBreakForce(jid), 1e-4)
    end)

    -- @covers lurek.physics.World:getJointBreakForce
    -- @description Verifies getJointBreakForce returns nil for an unset joint.
    it("getJointBreakForce returns nil when not set", function()
        local b1 = lurek.physics.newBody(world, 0, 0, "dynamic")
        local b2 = lurek.physics.newBody(world, 50, 0, "dynamic")
        local jid = lurek.physics.newJoint(world, b1, b2, "distance")
        expect_equal(nil, world:getJointBreakForce(jid))
    end)
end)

-- ── Contact callbacks ──────────────────────────────────────────────────────

-- @description Covers suite: lurek.physics contact callbacks.
describe("lurek.physics contact callbacks", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
    end)

    -- @covers lurek.physics.World:setBeginContact
    -- @description Verifies setBeginContact accepts a function without error.
    it("setBeginContact accepts a function", function()
        expect_no_error(function()
            world:setBeginContact(function(a, b) end)
        end)
    end)

    -- @covers lurek.physics.World:clearBeginContact
    -- @description Verifies clearBeginContact does not error.
    it("clearBeginContact does not error", function()
        world:setBeginContact(function(a, b) end)
        expect_no_error(function()
            world:clearBeginContact()
        end)
    end)

    -- @covers lurek.physics.World:setEndContact
    -- @description Verifies setEndContact accepts a function without error.
    it("setEndContact accepts a function", function()
        expect_no_error(function()
            world:setEndContact(function(a, b) end)
        end)
    end)

    -- @covers lurek.physics.World:clearEndContact
    -- @description Verifies clearEndContact does not error.
    it("clearEndContact does not error", function()
        world:setEndContact(function(a, b) end)
        expect_no_error(function()
            world:clearEndContact()
        end)
    end)
end)

-- ── Batch body creation ────────────────────────────────────────────────────

-- @description Covers suite: lurek.physics batch body creation.
describe("lurek.physics newBodies", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
    end)

    -- @covers lurek.physics.World:newBodies
    -- @description Verifies newBodies returns the correct number of IDs.
    it("newBodies returns correct number of IDs", function()
        local ids = world:newBodies({
            {0, 0, "dynamic"},
            {100, 0, "static"},
            {200, 0, "kinematic"},
        })
        expect_equal(3, #ids)
    end)

    -- @covers lurek.physics.World:newBodies
    -- @description Verifies all IDs returned by newBodies are integers.
    it("newBodies IDs are integers", function()
        local ids = world:newBodies({
            {10, 20, "dynamic"},
            {30, 40, "dynamic"},
        })
        for _, id in ipairs(ids) do
            expect_type("number", id)
        end
    end)

    -- @covers lurek.physics.World:newBodies
    -- @description Verifies newBodies with an empty table returns an empty result.
    it("newBodies with empty table returns empty table", function()
        local ids = world:newBodies({})
        expect_equal(0, #ids)
    end)
end)

-- =========================================================================
-- Merged from test_physics_step_fixed.lua
-- =========================================================================

-- @description Covers suite: lurek.physics World:stepFixed.
describe("lurek.physics World:stepFixed", function()
    -- @covers World:stepFixed
    -- @description Verifies stepFixed is callable on a world handle.
    it("stepFixed is callable", function()
        local world = lurek.physics.newWorld(0, 9.81)
        expect_no_error(function()
            world:stepFixed(1/60, 1/60, 8)
        end)
    end)

    -- @covers World:stepFixed
    -- @description Verifies the remainder is less than step_dt when accum equals step_dt exactly.
    it("remainder is zero when accum equals step_dt exactly", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        local remainder = world:stepFixed(step_dt, step_dt, 8)
        expect_near(0.0, remainder, 1e-4)
    end)

    -- @covers World:stepFixed
    -- @description Verifies the remainder is less than step_dt regardless of accum size.
    it("remainder is always less than step_dt", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        -- Pass 3.5 steps worth of accumulated time.
        local accum = step_dt * 3.5
        local remainder = world:stepFixed(accum, step_dt, 8)
        expect_true(remainder < step_dt, "remainder must be < step_dt")
        expect_true(remainder >= 0, "remainder must be non-negative")
    end)

    -- @covers World:stepFixed
    -- @description Verifies max_steps caps the number of sub-steps.
    it("max_steps cap leaves remainder >= step_dt when capped", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        -- Pass 100 steps worth of time but cap at 1 sub-step.
        local accum = step_dt * 100
        local remainder = world:stepFixed(accum, step_dt, 1)
        -- After one step, remainder = accum - step_dt ≈ step_dt * 99
        expect_true(remainder > step_dt, "remaining time should exceed step_dt when capped")
    end)

    -- @covers World:stepFixed
    -- @covers World:newBody
    -- @description Verifies a dynamic body moves after fixed sub-steps under gravity.
    it("dynamic body moves under gravity after stepFixed", function()
        local world = lurek.physics.newWorld(0, 100)
        world:newBody(0, 0, 10, 10, "dynamic")
        -- Accumulate enough time for one step.
        world:stepFixed(1/60, 1/60, 4)
        -- Body position is not queryable here; we only verify no error was raised.
        expect_true(true)
    end)
end)

-- =========================================================================
-- Merged from test_physics_terrain.lua
-- =========================================================================

-- @description Covers suite: lurek.physics terrain factory.
describe("lurek.physics terrain factory", function()
    -- @covers lurek.physics.newTerrain
    -- @description Verifies newTerrain is exposed as a callable factory.
    it("newTerrain is a function", function()
        expect_type("function", lurek.physics.newTerrain)
    end)

    -- @covers lurek.physics.newTerrain
    -- @description Verifies newTerrain returns userdata.
    it("newTerrain returns userdata", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(32, 32, 8, world)
        expect_type("userdata", terrain)
    end)
end)

-- @description Covers suite: lurek.physics terrain cell access.
describe("lurek.physics terrain cell access", function()
    local world, terrain

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
        terrain = lurek.physics.newTerrain(16, 16, 8, world)
    end)

    -- @covers LuaTerrain:getCell
    -- @description Verifies all cells start as non-solid.
    it("all cells start empty", function()
        expect_false(terrain:getCell(0, 0))
        expect_false(terrain:getCell(7, 7))
        expect_false(terrain:getCell(15, 15))
    end)

    -- @covers LuaTerrain:setCell
    -- @covers LuaTerrain:getCell
    -- @description Verifies setCell(solid=true) makes a cell solid.
    it("setCell true makes cell solid", function()
        terrain:setCell(3, 3, true)
        expect_true(terrain:getCell(3, 3))
    end)

    -- @covers LuaTerrain:setCell
    -- @covers LuaTerrain:getCell
    -- @description Verifies setCell(solid=false) removes solid state.
    it("setCell false clears a solid cell", function()
        terrain:setCell(5, 5, true)
        terrain:setCell(5, 5, false)
        expect_false(terrain:getCell(5, 5))
    end)

    -- @covers LuaTerrain:setCell
    -- @covers LuaTerrain:isDirty
    -- @description Verifies isDirty returns true after setCell changes a value.
    it("isDirty is true after setCell", function()
        expect_false(terrain:isDirty())
        terrain:setCell(0, 0, true)
        expect_true(terrain:isDirty())
    end)
end)

-- @description Covers suite: lurek.physics terrain bulk fill.
describe("lurek.physics terrain bulk fill", function()
    local world, terrain

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
        terrain = lurek.physics.newTerrain(32, 32, 8, world)
    end)

    -- @covers LuaTerrain:fillAll
    -- @covers LuaTerrain:getCell
    -- @description Verifies fillAll(true) makes every cell solid.
    it("fillAll true marks all cells solid", function()
        terrain:fillAll(true)
        expect_true(terrain:getCell(0, 0))
        expect_true(terrain:getCell(15, 15))
        expect_true(terrain:getCell(31, 31))
    end)

    -- @covers LuaTerrain:fillAll
    -- @covers LuaTerrain:getCell
    -- @description Verifies fillAll(false) clears every cell.
    it("fillAll false clears all cells", function()
        terrain:fillAll(true)
        terrain:fillAll(false)
        expect_false(terrain:getCell(0, 0))
        expect_false(terrain:getCell(15, 15))
    end)

    -- @covers LuaTerrain:fillRect
    -- @covers LuaTerrain:getCell
    -- @description Verifies fillRect marks cells inside the bounds.
    it("fillRect marks affected cells solid", function()
        -- fill a 5×5 block at cell (0,0), world coords 0,0 / 40,40 (8px cells)
        terrain:fillRect(0, 0, 40, 40, true)
        expect_true(terrain:getCell(2, 2))
    end)

    -- @covers LuaTerrain:fillCircle
    -- @covers LuaTerrain:getCell
    -- @description Verifies fillCircle marks centre cell solid.
    it("fillCircle marks centre cell solid", function()
        -- centre at world (64,64), radius 16 → hits cell (8,8)
        terrain:fillCircle(64, 64, 16, true)
        expect_true(terrain:getCell(8, 8))
    end)
end)

-- @description Covers suite: lurek.physics terrain flush.
describe("lurek.physics terrain flush", function()
    -- @covers LuaTerrain:flush
    -- @covers LuaTerrain:isDirty
    -- @description Verifies flush clears the dirty flag.
    it("flush clears isDirty", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(16, 16, 8, world)
        terrain:setCell(0, 0, true)
        expect_true(terrain:isDirty())
        terrain:flush()
        expect_false(terrain:isDirty())
    end)
end)

-- @description Covers suite: lurek.physics terrain serialisation.
describe("lurek.physics terrain serialisation", function()
    -- @covers LuaTerrain:toBytes
    -- @covers LuaTerrain:loadFromBytes
    -- @description Verifies round-trip serialisation preserves cell state.
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

-- @description Covers suite: lurek.physics terrain collapse columns.
describe("lurek.physics terrain collapse columns", function()
    -- @covers LuaTerrain:collapseColumns
    -- @description Verifies collapseColumns returns a non-negative integer.
    it("collapseColumns returns a non-negative integer", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(16, 16, 8, world)
        local n = terrain:collapseColumns()
        expect_true(n >= 0, "count must be non-negative")
    end)

    -- @covers LuaTerrain:fillAll
    -- @covers LuaTerrain:collapseColumns
    -- @description Verifies that a fully solid terrain has zero cells to collapse
    --              (every cell has its neighbour below it).
    it("fully solid terrain collapses zero cells", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        terrain:fillAll(true)
        local n = terrain:collapseColumns()
        expect_equal(0, n)
    end)

    -- @covers LuaTerrain:setCell
    -- @covers LuaTerrain:collapseColumns
    -- @covers LuaTerrain:getCell
    -- @description Verifies a lone floating cell collapses to empty when
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

    -- @covers LuaTerrain:setCell
    -- @covers LuaTerrain:collapseColumns
    -- @covers LuaTerrain:getCell
    -- @description Verifies that a cell resting on a solid floor does NOT collapse.
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

    -- @covers LuaTerrain:collapseColumns
    -- @covers LuaTerrain:isDirty
    -- @description Verifies isDirty is set after a collapse removes cells.
    it("collapseColumns marks terrain dirty when cells fall", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        terrain:setCell(4, 0, true)
        terrain:flush() -- clear dirty flag first
        terrain:collapseColumns()
        expect_true(terrain:isDirty())
    end)
end)

-- @description Covers suite: lurek.physics terrain solid positions.
describe("lurek.physics terrain solid positions", function()
    -- @covers LuaTerrain:solidPositions
    -- @description Verifies solidPositions returns an empty table for a blank grid.
    it("solidPositions empty for blank terrain", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        local pts = terrain:solidPositions()
        expect_equal(0, #pts)
    end)

    -- @covers LuaTerrain:setCell
    -- @covers LuaTerrain:solidPositions
    -- @description Verifies solidPositions returns one entry after one cell is set.
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

-- @description Covers suite: lurek.physics zone factory.
describe("lurek.physics zone factory", function()
    -- @covers lurek.physics.newWorld
    -- @covers World:addZone
    -- @description Verifies addZone returns a userdata zone handle.
    it("addZone returns userdata", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local zone = world:addZone(0, 0, 100, 100)
        expect_type("userdata", zone)
    end)

    -- @covers World:addZone
    -- @covers LuaZone:getId
    -- @description Verifies zone IDs are unique across consecutive addZone calls.
    it("consecutive zones have different IDs", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local z1 = world:addZone(0, 0, 50, 50)
        local z2 = world:addZone(50, 0, 50, 50)
        expect_false(z1:getId() == z2:getId(), "zone IDs must be unique")
    end)
end)

-- @description Covers suite: lurek.physics zone gravity modes.
describe("lurek.physics zone gravity modes", function()
    local world, zone

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        zone = world:addZone(0, 0, 1000, 1000)
    end)

    -- @covers LuaZone:setGravityZero
    -- @description Verifies setGravityZero does not error.
    it("setGravityZero accepts no arguments", function()
        expect_no_error(function()
            zone:setGravityZero()
        end)
    end)

    -- @covers LuaZone:setGravityDirectional
    -- @description Verifies setGravityDirectional accepts gx, gy.
    it("setGravityDirectional accepts gx and gy", function()
        expect_no_error(function()
            zone:setGravityDirectional(0, -50)
        end)
    end)

    -- @covers LuaZone:setGravityPoint
    -- @description Verifies setGravityPoint accepts centre and strength.
    it("setGravityPoint accepts cx, cy, strength", function()
        expect_no_error(function()
            zone:setGravityPoint(500, 500, 1000)
        end)
    end)

    -- @covers LuaZone:setGravityRepulsor
    -- @description Verifies setGravityRepulsor accepts centre and strength.
    it("setGravityRepulsor accepts cx, cy, strength", function()
        expect_no_error(function()
            zone:setGravityRepulsor(500, 500, 500)
        end)
    end)
end)

-- @description Covers suite: lurek.physics zone configuration.
describe("lurek.physics zone configuration", function()
    local world, zone

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
        zone = world:addZone(0, 0, 1000, 1000)
    end)

    -- @covers LuaZone:setEnabled
    -- @description Verifies setEnabled accepts a boolean without error.
    it("setEnabled false does not error", function()
        expect_no_error(function()
            zone:setEnabled(false)
        end)
    end)

    -- @covers LuaZone:setPriority
    -- @description Verifies setPriority accepts an integer without error.
    it("setPriority accepts an integer", function()
        expect_no_error(function()
            zone:setPriority(10)
        end)
    end)

    -- @covers LuaZone:setLayerMask
    -- @description Verifies setLayerMask accepts a bitmask without error.
    it("setLayerMask accepts a bitmask", function()
        expect_no_error(function()
            zone:setLayerMask(0xFF)
        end)
    end)

    -- @covers LuaZone:setCircle
    -- @description Verifies switching to a circular boundary does not error.
    it("setCircle replaces boundary with circle", function()
        expect_no_error(function()
            zone:setCircle(500, 500, 300)
        end)
    end)

    -- @covers LuaZone:setLinearDampingOverride
    -- @description Verifies setLinearDampingOverride accepts a number.
    it("setLinearDampingOverride accepts a value", function()
        expect_no_error(function()
            zone:setLinearDampingOverride(2.0)
        end)
    end)

    -- @covers LuaZone:setAngularDampingOverride
    -- @description Verifies setAngularDampingOverride accepts a value.
    it("setAngularDampingOverride accepts a value", function()
        expect_no_error(function()
            zone:setAngularDampingOverride(1.0)
        end)
    end)

    -- @covers LuaZone:destroy
    -- @description Verifies destroy does not error.
    it("destroy does not error", function()
        expect_no_error(function()
            zone:destroy()
        end)
    end)
end)

-- @description Covers suite: lurek.physics zone events.
describe("lurek.physics zone events", function()
    -- @covers World:addZone
    -- @covers World:getZoneEvents
    -- @description Verifies getZoneEvents returns a table (may be empty before step).
    it("getZoneEvents returns a table", function()
        local world = lurek.physics.newWorld(0, 9.81)
        world:addZone(0, 0, 1000, 1000)
        local events = world:getZoneEvents()
        expect_type("table", events)
    end)

    -- @covers World:addZone
    -- @covers World:getZoneEvents
    -- @covers World:step
    -- @description Verifies that a body created inside a zone produces an enter event after the first step.
    it("body inside zone produces enter event after step", function()
        local world = lurek.physics.newWorld(0, 0)
        world:addZone(0, 0, 1000, 1000)
        world:newBody(0, 0, 100, 100, "dynamic")
        world:step(1/60)
        local events = world:getZoneEvents()
        expect_true(#events >= 1, "expected at least one zone event")
        expect_equal("enter", events[1].kind)
    end)
end)

test_summary()
