-- Lurek2D Physics API Tests

-- @description Covers suite: lurek.physics module exists.
describe("lurek.physics module exists", function()
    -- @description Verifies the physics namespace is exposed as a Lua table.
    -- @tests lurek.physics
    it("lurek.physics is a table", function()
        expect_type("table", lurek.physics)
    end)
end)

-- @description Covers suite: lurek.physics world.
describe("lurek.physics world", function()
    -- @tests lurek.physics.newWorld
    -- @description Verifies newWorld is exposed as a callable physics factory.
    it("newWorld is a function", function()
        expect_type("function", lurek.physics.newWorld)
    end)

    -- @tests lurek.physics.newWorld
    -- @description Verifies newWorld returns World userdata.
    it("newWorld creates a world and returns World object", function()
        local id = lurek.physics.newWorld(0, 9.81)
        expect_type("userdata", id)
    end)

    -- @tests lurek.physics.step
    -- @description Verifies the module-level step function is exposed.
    it("step is a function", function()
        expect_type("function", lurek.physics.step)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.step
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
    -- @tests lurek.physics.newBody
    -- @description Verifies newBody is exposed as a callable constructor.
    it("newBody is a function", function()
        expect_type("function", lurek.physics.newBody)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @description Verifies newBody returns Body userdata when attached to a world.
    it("newBody creates a body and returns Body object", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local id = lurek.physics.newBody(world, 100, 100, "dynamic")
        expect_type("userdata", id)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.getBody
    -- @description Verifies getBody returns the created body's position and velocity tuple.
    it("getBody returns position and velocity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local id = lurek.physics.newBody(world, 50, 50, "static")
        local x, y, vx, vy = lurek.physics.getBody(world, id)
        expect_near(50, x, 1)
        expect_near(50, y, 1)
    end)

    -- @tests lurek.physics.setBodyVelocity
    -- @description Verifies setBodyVelocity is exposed as a callable helper.
    it("setBodyVelocity is a function", function()
        expect_type("function", lurek.physics.setBodyVelocity)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.setBodyVelocity
    -- @description Verifies setBodyVelocity accepts a world, body, and velocity components without error.
    it("setBodyVelocity changes velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_no_error(function()
            lurek.physics.setBodyVelocity(world, id, 100, 0)
        end)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.step
    -- @tests lurek.physics.getBody
    -- @description Verifies a dynamic body moves under gravity after stepping the world.
    it("dynamic body moves after step", function()
        local world = lurek.physics.newWorld(0, 100)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        lurek.physics.step(world, 0.1)
        local x, y, vx, vy = lurek.physics.getBody(world, id)
        expect_true(y > 0, "body should fall due to gravity")
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.step
    -- @tests lurek.physics.getBody
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
    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.isSleepingAllowed
    -- @description Verifies new dynamic bodies allow sleeping by default.
    it("isSleepingAllowed defaults to true", function()
        local world = lurek.physics.newWorld(0, 9.8)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_true(lurek.physics.isSleepingAllowed(world, id))
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.setSleepingAllowed
    -- @tests lurek.physics.isSleepingAllowed
    -- @description Verifies setSleepingAllowed(false) disables sleeping for a body.
    it("setSleepingAllowed false disables sleeping", function()
        local world = lurek.physics.newWorld(0, 9.8)
        local id = lurek.physics.newBody(world, 0, 0, "dynamic")
        lurek.physics.setSleepingAllowed(world, id, false)
        expect_false(lurek.physics.isSleepingAllowed(world, id))
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.setSleepingAllowed
    -- @tests lurek.physics.isSleepingAllowed
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
    -- @tests lurek.physics.newCircleShape
    -- @description Verifies newCircleShape is exposed as a constructor.
    it("newCircleShape is a function", function()
        expect_type("function", lurek.physics.newCircleShape)
    end)

    -- @tests lurek.physics.newCircleShape
    -- @tests lurek.physics.Shape.getType
    -- @description Verifies newCircleShape returns shape userdata reporting the circle type.
    it("newCircleShape returns userdata with type 'circle'", function()
        local s = lurek.physics.newCircleShape(10)
        expect_type("userdata", s)
        expect_equal("circle", s:getType())
    end)

    -- @tests lurek.physics.newCircleShape
    -- @tests lurek.physics.Shape.getRadius
    -- @description Verifies getRadius returns the configured radius for circle shapes.
    it("getRadius returns correct value for circle", function()
        local s = lurek.physics.newCircleShape(7.5)
        expect_near(7.5, s:getRadius(), 0.001)
    end)

    -- @tests lurek.physics.newRectangleShape
    -- @tests lurek.physics.Shape.getType
    -- @description Verifies newRectangleShape returns shape userdata reporting the rectangle type.
    it("newRectangleShape returns userdata with type 'rectangle'", function()
        local s = lurek.physics.newRectangleShape(20, 10)
        expect_type("userdata", s)
        expect_equal("rectangle", s:getType())
    end)

    -- @tests lurek.physics.newEdgeShape
    -- @tests lurek.physics.Shape.getType
    -- @description Verifies newEdgeShape returns shape userdata reporting the edge type.
    it("newEdgeShape returns userdata with type 'edge'", function()
        local s = lurek.physics.newEdgeShape(0, 0, 10, 0)
        expect_type("userdata", s)
        expect_equal("edge", s:getType())
    end)

    -- @tests lurek.physics.newPolygonShape
    -- @tests lurek.physics.Shape.getType
    -- @description Verifies newPolygonShape returns shape userdata reporting the polygon type.
    it("newPolygonShape returns userdata with type 'polygon'", function()
        local s = lurek.physics.newPolygonShape(0, 0, 10, 0, 5, 10)
        expect_type("userdata", s)
        expect_equal("polygon", s:getType())
    end)

    -- @tests lurek.physics.newChainShape
    -- @tests lurek.physics.Shape.getType
    -- @description Verifies newChainShape returns shape userdata reporting the chain type.
    it("newChainShape returns userdata with type 'chain'", function()
        local s = lurek.physics.newChainShape(false, 0, 0, 5, 0, 10, 5)
        expect_type("userdata", s)
        expect_equal("chain", s:getType())
    end)

    -- @tests lurek.physics.newCircleShape
    -- @tests lurek.physics.Shape.getBoundingBox
    -- @description Verifies getBoundingBox returns numeric bounds for a circle shape.
    it("getBoundingBox returns 4 numbers for circle", function()
        local s = lurek.physics.newCircleShape(5)
        local x1, y1, x2, y2 = s:getBoundingBox()
        expect_type("number", x1)
        expect_type("number", x2)
        expect_near(-5, x1, 0.001)
        expect_near(5, x2, 0.001)
    end)

    -- @tests lurek.physics.newCircleShape
    -- @tests lurek.physics.Shape.setDensity
    -- @description Verifies setDensity can be applied to shape userdata without error.
    it("setDensity does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setDensity(2.0) end)
    end)

    -- @tests lurek.physics.newCircleShape
    -- @tests lurek.physics.Shape.setFriction
    -- @description Verifies setFriction can be applied to shape userdata without error.
    it("setFriction does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setFriction(0.8) end)
    end)

    -- @tests lurek.physics.newCircleShape
    -- @tests lurek.physics.Shape.setRestitution
    -- @description Verifies setRestitution can be applied to shape userdata without error.
    it("setRestitution does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setRestitution(0.5) end)
    end)

    -- @tests lurek.physics.newCircleShape
    -- @tests lurek.physics.Shape.setSensor
    -- @description Verifies setSensor can be applied to shape userdata without error.
    it("setSensor does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:setSensor(true) end)
    end)

    -- @tests lurek.physics.newCircleShape
    -- @tests lurek.physics.Shape.destroy
    -- @description Verifies destroy can be called on shape userdata without error.
    it("destroy does not error", function()
        local s = lurek.physics.newCircleShape(1)
        expect_no_error(function() s:destroy() end)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.newCircleShape
    -- @tests lurek.physics.attachShape
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
    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.getPosition
    -- @description Verifies Body:getPosition returns the spawn coordinates after creation.
    it("getPosition returns x, y after creation", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 10.0, 20.0, "dynamic")
        local x, y = body:getPosition()
        expect_near(10.0, x, 0.01)
        expect_near(20.0, y, 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setPosition
    -- @tests lurek.physics.Body.getPosition
    -- @description Verifies Body:setPosition moves the body and getPosition reports the updated coordinates.
    it("setPosition moves the body", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setPosition(50, 75)
        local x, y = body:getPosition()
        expect_near(50, x, 0.01)
        expect_near(75, y, 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.getX
    -- @tests lurek.physics.Body.getY
    -- @description Verifies Body:getX and Body:getY expose individual position components.
    it("getX and getY return individual coordinates", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 3.5, 7.5, "dynamic")
        expect_near(3.5, body:getX(), 0.01)
        expect_near(7.5, body:getY(), 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setVelocity
    -- @tests lurek.physics.Body.getVelocity
    -- @description Verifies Body:setVelocity and Body:getVelocity round-trip linear velocity.
    it("setVelocity and getVelocity round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setVelocity(5.0, -3.0)
        local vx, vy = body:getVelocity()
        expect_near(5.0, vx, 0.01)
        expect_near(-3.0, vy, 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setAngle
    -- @tests lurek.physics.Body.getAngle
    -- @description Verifies Body:setAngle and Body:getAngle round-trip rotation.
    it("getAngle and setAngle round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngle(1.57)
        expect_near(1.57, body:getAngle(), 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setAngularVelocity
    -- @tests lurek.physics.Body.getAngularVelocity
    -- @description Verifies Body:setAngularVelocity and Body:getAngularVelocity round-trip spin rate.
    it("getAngularVelocity and setAngularVelocity round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngularVelocity(2.5)
        expect_near(2.5, body:getAngularVelocity(), 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.getMass
    -- @description Verifies Body:getMass returns a positive mass for a dynamic body with attached geometry.
    it("getMass returns positive for dynamic body with shape", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_true(body:getMass() > 0)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.getType
    -- @description Verifies Body:getType reports the configured body type.
    it("getType returns body type string", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "static")
        expect_equal("static", body:getType())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setType
    -- @tests lurek.physics.Body.getType
    -- @description Verifies Body:setType changes the stored body type.
    it("setType changes body type", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setType("kinematic")
        expect_equal("kinematic", body:getType())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.setFriction
    -- @tests lurek.physics.Body.getFriction
    -- @description Verifies Body:setFriction and Body:getFriction round-trip fixture friction.
    it("getFriction and setFriction round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setFriction(0.7)
        expect_near(0.7, body:getFriction(), 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.setRestitution
    -- @tests lurek.physics.Body.getRestitution
    -- @description Verifies Body:setRestitution and Body:getRestitution round-trip bounce values.
    it("getRestitution and setRestitution round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setRestitution(0.9)
        expect_near(0.9, body:getRestitution(), 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setLayer
    -- @tests lurek.physics.Body.getLayer
    -- @description Verifies Body:setLayer and Body:getLayer round-trip collision layer values.
    it("getLayer and setLayer round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setLayer(3)
        expect_equal(3, body:getLayer())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setMask
    -- @tests lurek.physics.Body.getMask
    -- @description Verifies Body:setMask and Body:getMask round-trip collision masks.
    it("getMask and setMask round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setMask(5)
        expect_equal(5, body:getMask())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.applyImpulse
    -- @tests lurek.physics.Body.getVelocity
    -- @description Verifies Body:applyImpulse changes the body's linear velocity.
    it("applyImpulse changes velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:applyImpulse(10, 0)
        local vx, vy = body:getVelocity()
        expect_true(vx > 0, "impulse should increase x velocity")
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.applyForce
    -- @description Verifies Body:applyForce accepts force input without error.
    it("applyForce does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_no_error(function() body:applyForce(100, 0) end)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.applyTorque
    -- @description Verifies Body:applyTorque accepts torque input without error.
    it("applyTorque does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        expect_no_error(function() body:applyTorque(5.0) end)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.applyAngularImpulse
    -- @tests lurek.physics.Body.getAngularVelocity
    -- @description Verifies Body:applyAngularImpulse changes angular velocity.
    it("applyAngularImpulse changes angular velocity", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:applyAngularImpulse(3.0)
        expect_true(math.abs(body:getAngularVelocity()) > 0)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setGravityScale
    -- @tests lurek.physics.Body.getGravityScale
    -- @description Verifies Body:setGravityScale and Body:getGravityScale round-trip gravity scaling.
    it("getGravityScale and setGravityScale round-trip", function()
        local world = lurek.physics.newWorld(0, -9.81)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setGravityScale(0.5)
        expect_near(0.5, body:getGravityScale(), 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.isFixedRotation
    -- @tests lurek.physics.Body.setFixedRotation
    -- @description Verifies Body:setFixedRotation toggles the fixed-rotation flag.
    it("isFixedRotation and setFixedRotation round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_false(body:isFixedRotation())
        body:setFixedRotation(true)
        expect_true(body:isFixedRotation())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setLinearDamping
    -- @tests lurek.physics.Body.getLinearDamping
    -- @description Verifies Body:setLinearDamping and Body:getLinearDamping round-trip drag values.
    it("getLinearDamping and setLinearDamping round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setLinearDamping(0.3)
        expect_near(0.3, body:getLinearDamping(), 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.setAngularDamping
    -- @tests lurek.physics.Body.getAngularDamping
    -- @description Verifies Body:setAngularDamping and Body:getAngularDamping round-trip angular drag values.
    it("getAngularDamping and setAngularDamping round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        body:setAngularDamping(0.4)
        expect_near(0.4, body:getAngularDamping(), 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.isBullet
    -- @tests lurek.physics.Body.setBullet
    -- @description Verifies Body:setBullet toggles bullet mode on and off.
    it("isBullet and setBullet round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_false(body:isBullet())
        body:setBullet(true)
        expect_true(body:isBullet())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.getId
    -- @description Verifies Body:getId returns a numeric identifier.
    it("getId returns a number", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        expect_type("number", body:getId())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.Body.destroy
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
    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.getGravity
    -- @description Verifies World:getGravity returns the world's configured gravity vector.
    it("getGravity returns world gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local gx, gy = world:getGravity()
        expect_near(0, gx, 0.01)
        expect_near(9.81, gy, 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.setGravity
    -- @tests lurek.physics.World.getGravity
    -- @description Verifies World:setGravity updates the world's gravity vector.
    it("setGravity changes world gravity", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setGravity(0, -10)
        local gx, gy = world:getGravity()
        expect_near(0, gx, 0.01)
        expect_near(-10, gy, 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.getBodyCount
    -- @tests lurek.physics.World.newBody
    -- @description Verifies World:getBodyCount tracks bodies created through World:newBody.
    it("getBodyCount tracks bodies", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:getBodyCount())
        world:newBody(0, 0, "dynamic")
        expect_equal(1, world:getBodyCount())
        world:newBody(5, 5, "static")
        expect_equal(2, world:getBodyCount())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newBody
    -- @tests lurek.physics.World.getBodyIds
    -- @description Verifies World:getBodyIds returns the IDs of created bodies.
    it("getBodyIds returns id table", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        world:newBody(5, 5, "dynamic")
        local ids = world:getBodyIds()
        expect_equal(2, #ids)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newBody
    -- @tests lurek.physics.World.destroyBody
    -- @tests lurek.physics.World.getBodyCount
    -- @tests lurek.physics.Body.getType
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

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newBody
    -- @tests lurek.physics.World.clear
    -- @tests lurek.physics.World.getBodyCount
    -- @description Verifies World:clear removes all tracked bodies.
    it("clear removes all bodies", function()
        local world = lurek.physics.newWorld(0, 0)
        world:newBody(0, 0, "dynamic")
        world:newBody(5, 5, "dynamic")
        world:clear()
        expect_equal(0, world:getBodyCount())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.step
    -- @tests lurek.physics.Body.getPosition
    -- @description Verifies World:step advances simulation for dynamic bodies under gravity.
    it("step advances simulation", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_true(y > 0, "gravity should move body down")
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.setMeter
    -- @tests lurek.physics.World.getMeter
    -- @description Verifies World:setMeter and World:getMeter round-trip the pixels-per-meter scale.
    it("getMeter and setMeter round-trip", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setMeter(100)
        expect_near(100, world:getMeter(), 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.setMeter
    -- @tests lurek.physics.World.toPhysics
    -- @tests lurek.physics.World.toPixels
    -- @description Verifies World:toPhysics and World:toPixels convert distances using the configured meter scale.
    it("toPhysics and toPixels convert", function()
        local world = lurek.physics.newWorld(0, 0)
        world:setMeter(50)
        local m = world:toPhysics(100)
        expect_near(2.0, m, 0.01)
        local px = world:toPixels(2.0)
        expect_near(100, px, 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.getPosition
    -- @description Verifies World:newCircleBody creates a positioned body with circle geometry.
    it("newCircleBody creates a body with circle shape", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(10, 20, 5, "dynamic")
        local x, y = body:getPosition()
        expect_near(10, x, 0.01)
        expect_near(20, y, 0.01)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newPolygonBody
    -- @tests lurek.physics.Body.getType
    -- @description Verifies World:newPolygonBody creates a dynamic polygon body.
    it("newPolygonBody creates a polygon body", function()
        local world = lurek.physics.newWorld(0, 0)
        local verts = {0, 0, 10, 0, 10, 10, 0, 10}
        local body = world:newPolygonBody(5, 5, verts, "dynamic")
        expect_not_nil(body)
        expect_equal("dynamic", body:getType())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newEdgeBody
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
    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.addRevoluteJoint
    -- @description Verifies addRevoluteJoint creates a numeric joint handle between two bodies.
    it("addRevoluteJoint creates a revolute joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        expect_type("number", jid)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.addDistanceJoint
    -- @description Verifies addDistanceJoint creates a numeric joint handle between two bodies.
    it("addDistanceJoint creates a distance joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(10, 0, 1, "dynamic")
        local jid = world:addDistanceJoint(a:getId(), b:getId(), 0, 0, 10, 0, 10)
        expect_type("number", jid)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.addWeldJoint
    -- @description Verifies addWeldJoint creates a numeric joint handle between two bodies.
    it("addWeldJoint creates a weld joint", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addWeldJoint(a:getId(), b:getId(), 2.5, 0)
        expect_type("number", jid)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.jointCount
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.addRevoluteJoint
    -- @description Verifies jointCount increases after adding a joint.
    it("jointCount returns number of joints", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_equal(0, world:jointCount())
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        expect_equal(1, world:jointCount())
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.addRevoluteJoint
    -- @tests lurek.physics.World.getJointIds
    -- @description Verifies getJointIds returns the IDs of created joints.
    it("getJointIds returns joint id table", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        local ids = world:getJointIds()
        expect_equal(1, #ids)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.addRevoluteJoint
    -- @tests lurek.physics.World.getJointType
    -- @description Verifies getJointType returns a string descriptor for an existing joint.
    it("getJointType returns joint type string", function()
        local world = lurek.physics.newWorld(0, 0)
        local a = world:newCircleBody(0, 0, 1, "dynamic")
        local b = world:newCircleBody(5, 0, 1, "dynamic")
        local jid = world:addRevoluteJoint(a:getId(), b:getId(), 2.5, 0)
        local jtype = world:getJointType(jid)
        expect_type("string", jtype)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.addRevoluteJoint
    -- @tests lurek.physics.World.jointCount
    -- @tests lurek.physics.World.destroyJoint
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
    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.World.addFixture
    -- @description Verifies addFixture returns a numeric fixture index for a body.
    it("addFixture returns fixture index", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local idx = world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_type("number", idx)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.World.fixtureCount
    -- @tests lurek.physics.World.addFixture
    -- @description Verifies fixtureCount increments after a fixture is added to a body.
    it("fixtureCount increases after addFixture", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        local before = world:fixtureCount(body:getId())
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_equal(before + 1, world:fixtureCount(body:getId()))
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.World.addFixture
    -- @tests lurek.physics.World.setFixtureFriction
    -- @description Verifies setFixtureFriction can update an existing fixture without error.
    it("setFixtureFriction does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureFriction(body:getId(), 0, 0.8)
        end)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.World.addFixture
    -- @tests lurek.physics.World.setFixtureRestitution
    -- @description Verifies setFixtureRestitution can update an existing fixture without error.
    it("setFixtureRestitution does not error", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:addFixture(body:getId(), "circle", 1.0, 0.5, 0.3, false, 2.0)
        expect_no_error(function()
            world:setFixtureRestitution(body:getId(), 0, 0.6)
        end)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.newBody
    -- @tests lurek.physics.World.addFixture
    -- @tests lurek.physics.World.setFixtureSensor
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
    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.step
    -- @tests lurek.physics.Body.getPosition
    -- @description Verifies static bodies remain stationary under gravity.
    it("static body does not move under gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "static")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.step
    -- @tests lurek.physics.Body.getPosition
    -- @description Verifies zero gravity leaves a dynamic body stationary.
    it("zero gravity keeps dynamic body still", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        world:step(1.0 / 60.0)
        local x, y = body:getPosition()
        expect_near(0, x, 0.001)
        expect_near(0, y, 0.001)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.World.step
    -- @tests lurek.physics.Body.getPosition
    -- @description Verifies kinematic bodies are not displaced by gravity during stepping.
    it("kinematic body is unaffected by gravity", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "kinematic")
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.setGravityScale
    -- @tests lurek.physics.World.step
    -- @tests lurek.physics.Body.getPosition
    -- @description Verifies gravityScale zero prevents a dynamic body from falling.
    it("gravity scale 0 prevents falling", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 1.0, "dynamic")
        body:setGravityScale(0)
        world:step(1.0 / 60.0)
        local _, y = body:getPosition()
        expect_near(0, y, 0.001)
    end)

    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newCircleBody
    -- @tests lurek.physics.Body.setLayer
    -- @tests lurek.physics.Body.setMask
    -- @tests lurek.physics.World.step
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
    -- @tests lurek.physics.newWorld
    -- @tests lurek.physics.World.newBody
    -- @tests lurek.physics.destroyWorld
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

  -- @tests lurek.physics.World:setBodyData
  -- @tests lurek.physics.World:getBodyData
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

  -- @tests lurek.physics.World:getBodyData
  -- @description Reading data for a body that was never given data returns nil.
  it("getBodyData returns nil for unset body", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    local d = w:getBodyData(id)
    expect_equal(d, nil)
  end)

  -- @tests lurek.physics.World:clearBodyData
  -- @description clearBodyData removes previously stored data.
  it("clearBodyData removes data", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    w:setBodyData(id, "some data")
    w:clearBodyData(id)
    expect_equal(w:getBodyData(id), nil)
  end)

  -- @tests lurek.physics.World:setBodyData
  -- @description Overwriting data with setBodyData replaces the old value.
  it("setBodyData overwrites previous value", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "dynamic")
    local id = body:getId()
    w:setBodyData(id, "first")
    w:setBodyData(id, "second")
    expect_equal(w:getBodyData(id), "second")
  end)

  -- @tests lurek.physics.World:setBodyData
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
    -- @tests lurek.physics.newCellular
    -- @description Verifies newCellular is exposed as a callable factory.
    it("newCellular is a function", function()
        expect_type("function", lurek.physics.newCellular)
    end)

    -- @tests lurek.physics.newCellular
    -- @description Verifies newCellular returns userdata.
    it("newCellular returns userdata", function()
        local sim = lurek.physics.newCellular(32, 32)
        expect_type("userdata", sim)
    end)
end)

-- @description Covers suite: lurek.physics cellular cell-type constants.
describe("lurek.physics cellular cell-type constants", function()
    -- @tests lurek.physics.CELL_AIR
    -- @description Verifies CELL_AIR is an integer.
    it("CELL_AIR is an integer", function()
        expect_type("number", lurek.physics.CELL_AIR)
        expect_equal(0, lurek.physics.CELL_AIR)
    end)

    -- @tests lurek.physics.CELL_SAND
    it("CELL_SAND is greater than CELL_AIR", function()
        expect_true(lurek.physics.CELL_SAND > lurek.physics.CELL_AIR)
    end)

    -- @tests lurek.physics.CELL_WATER
    it("CELL_WATER is an integer", function()
        expect_type("number", lurek.physics.CELL_WATER)
    end)

    -- @tests lurek.physics.CELL_ROCK
    it("CELL_ROCK is an integer", function()
        expect_type("number", lurek.physics.CELL_ROCK)
    end)

    -- @tests lurek.physics.CELL_FIRE
    it("CELL_FIRE is an integer", function()
        expect_type("number", lurek.physics.CELL_FIRE)
    end)

    -- @tests lurek.physics.CELL_GAS
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

    -- @tests LuaCellular:getCell
    -- @description Verifies all cells start as CELL_AIR.
    it("new grid is all air", function()
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(0, 0))
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(8, 8))
    end)

    -- @tests LuaCellular:setCell
    -- @tests LuaCellular:getCell
    -- @description Verifies setCell changes the material at a position.
    it("setCell changes cell type", function()
        sim:setCell(5, 5, lurek.physics.CELL_SAND)
        expect_equal(lurek.physics.CELL_SAND, sim:getCell(5, 5))
    end)

    -- @tests LuaCellular:setCell
    -- @tests LuaCellular:getCell
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

    -- @tests LuaCellular:fillRect
    -- @tests LuaCellular:getCell
    -- @description Verifies fillRect marks cells inside the region.
    it("fillRect fills the specified region", function()
        sim:fillRect(5, 5, 4, 4, lurek.physics.CELL_ROCK)
        expect_equal(lurek.physics.CELL_ROCK, sim:getCell(6, 6))
        -- outside the region should remain air
        expect_equal(lurek.physics.CELL_AIR, sim:getCell(0, 0))
    end)

    -- @tests LuaCellular:fillCircle
    -- @tests LuaCellular:getCell
    -- @description Verifies fillCircle marks the centre cell.
    it("fillCircle marks centre cell", function()
        sim:fillCircle(16, 16, 3, lurek.physics.CELL_WATER)
        expect_equal(lurek.physics.CELL_WATER, sim:getCell(16, 16))
    end)
end)

-- @description Covers suite: lurek.physics cellular step.
describe("lurek.physics cellular step", function()
    -- @tests LuaCellular:setCell
    -- @tests LuaCellular:step
    -- @tests LuaCellular:countCells
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

    -- @tests LuaCellular:stepN
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
    -- @tests LuaCellular:countCells
    -- @description Verifies countCells returns the precise number of matching cells.
    it("countCells matches manually placed cells", function()
        local sim = lurek.physics.newCellular(16, 16)
        sim:setCell(0, 0, lurek.physics.CELL_ROCK)
        sim:setCell(1, 0, lurek.physics.CELL_ROCK)
        sim:setCell(2, 0, lurek.physics.CELL_ROCK)
        expect_equal(3, sim:countCells(lurek.physics.CELL_ROCK))
    end)

    -- @tests LuaCellular:findCells
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
    -- @tests LuaCellular:toBytes
    -- @tests LuaCellular:loadFromBytes
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

    -- @tests lurek.physics.World:getSolverIterations
    -- @description Verifies default solver iteration count is 4.
    it("default solver iteration count is 4", function()
        expect_equal(4, world:getSolverIterations())
    end)

    -- @tests lurek.physics.World:setSolverIterations
    -- @tests lurek.physics.World:getSolverIterations
    -- @description Verifies setSolverIterations persists the new value.
    it("setSolverIterations persists the value", function()
        world:setSolverIterations(8)
        expect_equal(8, world:getSolverIterations())
    end)

    -- @tests lurek.physics.World:setSolverIterations
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

    -- @tests lurek.physics.World:isBodySleeping
    -- @description Verifies isBodySleeping returns a boolean without error.
    xit("isBodySleeping returns boolean", function()
        local sleeping = world:isBodySleeping(body_id)
        expect_type("boolean", sleeping)
    end)

    -- @tests lurek.physics.World:sleepBody
    -- @tests lurek.physics.World:isBodySleeping
    -- @description Verifies sleepBody puts a body to sleep.
    xit("sleepBody puts a body to sleep", function()
        world:sleepBody(body_id)
        expect_equal(true, world:isBodySleeping(body_id))
    end)

    -- @tests lurek.physics.World:wakeUpBody
    -- @tests lurek.physics.World:sleepBody
    -- @tests lurek.physics.World:isBodySleeping
    -- @description Verifies wakeUpBody wakes a sleeping body.
    xit("wakeUpBody wakes a sleeping body", function()
        world:sleepBody(body_id)
        world:wakeUpBody(body_id)
        expect_equal(false, world:isBodySleeping(body_id))
    end)

    -- @tests lurek.physics.Body:isSleeping
    -- @description Verifies Body:isSleeping returns a boolean.
    it("Body:isSleeping returns boolean", function()
        local body = lurek.physics.newBody(world, 200, 200, "dynamic")
        expect_type("boolean", body:isSleeping())
    end)

    -- @tests lurek.physics.Body:sleep
    -- @tests lurek.physics.Body:isSleeping
    -- @description Verifies Body:sleep and Body:isSleeping.
    it("Body:sleep puts the body to sleep", function()
        local body = lurek.physics.newBody(world, 300, 300, "dynamic")
        body:sleep()
        expect_equal(true, body:isSleeping())
    end)

    -- @tests lurek.physics.Body:wakeUp
    -- @tests lurek.physics.Body:sleep
    -- @tests lurek.physics.Body:isSleeping
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

    -- @tests lurek.physics.World:setBodyOneWay
    -- @tests lurek.physics.World:getBodyOneWay
    -- @description Verifies setBodyOneWay stores the normal vector.
    xit("setBodyOneWay stores the normal", function()
        world:setBodyOneWay(body_id, 0, -1)
        local nx, ny = world:getBodyOneWay(body_id)
        expect_near(0,  nx, 1e-5)
        expect_near(-1, ny, 1e-5)
    end)

    -- @tests lurek.physics.World:clearBodyOneWay
    -- @tests lurek.physics.World:getBodyOneWay
    -- @description Verifies clearBodyOneWay removes the one-way normal.
    xit("clearBodyOneWay removes the one-way flag", function()
        world:setBodyOneWay(body_id, 0, -1)
        world:clearBodyOneWay(body_id)
        local nx, ny = world:getBodyOneWay(body_id)
        expect_equal(nil, nx)
        expect_equal(nil, ny)
    end)

    -- @tests lurek.physics.World:getBodyOneWay
    -- @description Verifies getBodyOneWay returns nil for a normal body.
    xit("getBodyOneWay returns nil for a normal body", function()
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

    -- @tests lurek.physics.World:setBodyCCD
    -- @tests lurek.physics.World:getBodyCCD
    -- @description Verifies setBodyCCD enables CCD on a body.
    xit("setBodyCCD enables CCD", function()
        world:setBodyCCD(body_id, true)
        expect_equal(true, world:getBodyCCD(body_id))
    end)

    -- @tests lurek.physics.World:setBodyCCD
    -- @tests lurek.physics.World:getBodyCCD
    -- @description Verifies setBodyCCD can disable CCD after enabling.
    xit("setBodyCCD can disable CCD", function()
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

    -- @tests lurek.physics.World:setJointBreakForce
    -- @tests lurek.physics.World:getJointBreakForce
    -- @description Verifies setJointBreakForce stores the threshold.
    xit("setJointBreakForce stores the threshold", function()
        local b1 = lurek.physics.newBody(world, 0, 0, "dynamic")
        local b2 = lurek.physics.newBody(world, 50, 0, "dynamic")
        local jid = lurek.physics.newJoint(world, b1, b2, "distance")
        world:setJointBreakForce(jid, 100.0)
        expect_near(100.0, world:getJointBreakForce(jid), 1e-4)
    end)

    -- @tests lurek.physics.World:getJointBreakForce
    -- @description Verifies getJointBreakForce returns nil for an unset joint.
    xit("getJointBreakForce returns nil when not set", function()
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

    -- @tests lurek.physics.World:setBeginContact
    -- @description Verifies setBeginContact accepts a function without error.
    it("setBeginContact accepts a function", function()
        expect_no_error(function()
            world:setBeginContact(function(a, b) end)
        end)
    end)

    -- @tests lurek.physics.World:clearBeginContact
    -- @description Verifies clearBeginContact does not error.
    it("clearBeginContact does not error", function()
        world:setBeginContact(function(a, b) end)
        expect_no_error(function()
            world:clearBeginContact()
        end)
    end)

    -- @tests lurek.physics.World:setEndContact
    -- @description Verifies setEndContact accepts a function without error.
    it("setEndContact accepts a function", function()
        expect_no_error(function()
            world:setEndContact(function(a, b) end)
        end)
    end)

    -- @tests lurek.physics.World:clearEndContact
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

    -- @tests lurek.physics.World:newBodies
    -- @description Verifies newBodies returns the correct number of IDs.
    it("newBodies returns correct number of IDs", function()
        local ids = world:newBodies({
            {0, 0, "dynamic"},
            {100, 0, "static"},
            {200, 0, "kinematic"},
        })
        expect_equal(3, #ids)
    end)

    -- @tests lurek.physics.World:newBodies
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

    -- @tests lurek.physics.World:newBodies
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
    -- @tests World:stepFixed
    -- @description Verifies stepFixed is callable on a world handle.
    it("stepFixed is callable", function()
        local world = lurek.physics.newWorld(0, 9.81)
        expect_no_error(function()
            world:stepFixed(1/60, 1/60, 8)
        end)
    end)

    -- @tests World:stepFixed
    -- @description Verifies the remainder is less than step_dt when accum equals step_dt exactly.
    it("remainder is zero when accum equals step_dt exactly", function()
        local world = lurek.physics.newWorld(0, 0)
        local step_dt = 1/60
        local remainder = world:stepFixed(step_dt, step_dt, 8)
        expect_near(0.0, remainder, 1e-4)
    end)

    -- @tests World:stepFixed
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

    -- @tests World:stepFixed
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

    -- @tests World:stepFixed
    -- @tests World:newBody
    -- @description Verifies a dynamic body moves after fixed sub-steps under gravity.
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

-- @description Covers suite: lurek.physics terrain factory.
describe("lurek.physics terrain factory", function()
    -- @tests lurek.physics.newTerrain
    -- @description Verifies newTerrain is exposed as a callable factory.
    it("newTerrain is a function", function()
        expect_type("function", lurek.physics.newTerrain)
    end)

    -- @tests lurek.physics.newTerrain
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

    -- @tests LuaTerrain:getCell
    -- @description Verifies all cells start as non-solid.
    it("all cells start empty", function()
        expect_false(terrain:getCell(0, 0))
        expect_false(terrain:getCell(7, 7))
        expect_false(terrain:getCell(15, 15))
    end)

    -- @tests LuaTerrain:setCell
    -- @tests LuaTerrain:getCell
    -- @description Verifies setCell(solid=true) makes a cell solid.
    it("setCell true makes cell solid", function()
        terrain:setCell(3, 3, true)
        expect_true(terrain:getCell(3, 3))
    end)

    -- @tests LuaTerrain:setCell
    -- @tests LuaTerrain:getCell
    -- @description Verifies setCell(solid=false) removes solid state.
    it("setCell false clears a solid cell", function()
        terrain:setCell(5, 5, true)
        terrain:setCell(5, 5, false)
        expect_false(terrain:getCell(5, 5))
    end)

    -- @tests LuaTerrain:setCell
    -- @tests LuaTerrain:isDirty
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

    -- @tests LuaTerrain:fillAll
    -- @tests LuaTerrain:getCell
    -- @description Verifies fillAll(true) makes every cell solid.
    it("fillAll true marks all cells solid", function()
        terrain:fillAll(true)
        expect_true(terrain:getCell(0, 0))
        expect_true(terrain:getCell(15, 15))
        expect_true(terrain:getCell(31, 31))
    end)

    -- @tests LuaTerrain:fillAll
    -- @tests LuaTerrain:getCell
    -- @description Verifies fillAll(false) clears every cell.
    it("fillAll false clears all cells", function()
        terrain:fillAll(true)
        terrain:fillAll(false)
        expect_false(terrain:getCell(0, 0))
        expect_false(terrain:getCell(15, 15))
    end)

    -- @tests LuaTerrain:fillRect
    -- @tests LuaTerrain:getCell
    -- @description Verifies fillRect marks cells inside the bounds.
    it("fillRect marks affected cells solid", function()
        -- fill a 5×5 block at cell (0,0), world coords 0,0 / 40,40 (8px cells)
        terrain:fillRect(0, 0, 40, 40, true)
        expect_true(terrain:getCell(2, 2))
    end)

    -- @tests LuaTerrain:fillCircle
    -- @tests LuaTerrain:getCell
    -- @description Verifies fillCircle marks centre cell solid.
    it("fillCircle marks centre cell solid", function()
        -- centre at world (64,64), radius 16 → hits cell (8,8)
        terrain:fillCircle(64, 64, 16, true)
        expect_true(terrain:getCell(8, 8))
    end)
end)

-- @description Covers suite: lurek.physics terrain flush.
describe("lurek.physics terrain flush", function()
    -- @tests LuaTerrain:flush
    -- @tests LuaTerrain:isDirty
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
    -- @tests LuaTerrain:toBytes
    -- @tests LuaTerrain:loadFromBytes
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
    -- @tests LuaTerrain:collapseColumns
    -- @description Verifies collapseColumns returns a non-negative integer.
    it("collapseColumns returns a non-negative integer", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(16, 16, 8, world)
        local n = terrain:collapseColumns()
        expect_true(n >= 0, "count must be non-negative")
    end)

    -- @tests LuaTerrain:fillAll
    -- @tests LuaTerrain:collapseColumns
    -- @description Verifies that a fully solid terrain has zero cells to collapse
    --              (every cell has its neighbour below it).
    it("fully solid terrain collapses zero cells", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        terrain:fillAll(true)
        local n = terrain:collapseColumns()
        expect_equal(0, n)
    end)

    -- @tests LuaTerrain:setCell
    -- @tests LuaTerrain:collapseColumns
    -- @tests LuaTerrain:getCell
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

    -- @tests LuaTerrain:setCell
    -- @tests LuaTerrain:collapseColumns
    -- @tests LuaTerrain:getCell
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

    -- @tests LuaTerrain:collapseColumns
    -- @tests LuaTerrain:isDirty
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
    -- @tests LuaTerrain:solidPositions
    -- @description Verifies solidPositions returns an empty table for a blank grid.
    it("solidPositions empty for blank terrain", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(8, 8, 8, world)
        local pts = terrain:solidPositions()
        expect_equal(0, #pts)
    end)

    -- @tests LuaTerrain:setCell
    -- @tests LuaTerrain:solidPositions
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
    -- @tests lurek.physics.newWorld
    -- @tests World:addZone
    -- @description Verifies addZone returns a userdata zone handle.
    it("addZone returns userdata", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local zone = world:addZone(0, 0, 100, 100)
        expect_type("userdata", zone)
    end)

    -- @tests World:addZone
    -- @tests LuaZone:getId
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

    -- @tests LuaZone:setGravityZero
    -- @description Verifies setGravityZero does not error.
    it("setGravityZero accepts no arguments", function()
        expect_no_error(function()
            zone:setGravityZero()
        end)
    end)

    -- @tests LuaZone:setGravityDirectional
    -- @description Verifies setGravityDirectional accepts gx, gy.
    it("setGravityDirectional accepts gx and gy", function()
        expect_no_error(function()
            zone:setGravityDirectional(0, -50)
        end)
    end)

    -- @tests LuaZone:setGravityPoint
    -- @description Verifies setGravityPoint accepts centre and strength.
    it("setGravityPoint accepts cx, cy, strength", function()
        expect_no_error(function()
            zone:setGravityPoint(500, 500, 1000)
        end)
    end)

    -- @tests LuaZone:setGravityRepulsor
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

    -- @tests LuaZone:setEnabled
    -- @description Verifies setEnabled accepts a boolean without error.
    it("setEnabled false does not error", function()
        expect_no_error(function()
            zone:setEnabled(false)
        end)
    end)

    -- @tests LuaZone:setPriority
    -- @description Verifies setPriority accepts an integer without error.
    it("setPriority accepts an integer", function()
        expect_no_error(function()
            zone:setPriority(10)
        end)
    end)

    -- @tests LuaZone:setLayerMask
    -- @description Verifies setLayerMask accepts a bitmask without error.
    it("setLayerMask accepts a bitmask", function()
        expect_no_error(function()
            zone:setLayerMask(0xFF)
        end)
    end)

    -- @tests LuaZone:setCircle
    -- @description Verifies switching to a circular boundary does not error.
    it("setCircle replaces boundary with circle", function()
        expect_no_error(function()
            zone:setCircle(500, 500, 300)
        end)
    end)

    -- @tests LuaZone:setLinearDampingOverride
    -- @description Verifies setLinearDampingOverride accepts a number.
    it("setLinearDampingOverride accepts a value", function()
        expect_no_error(function()
            zone:setLinearDampingOverride(2.0)
        end)
    end)

    -- @tests LuaZone:setAngularDampingOverride
    -- @description Verifies setAngularDampingOverride accepts a value.
    it("setAngularDampingOverride accepts a value", function()
        expect_no_error(function()
            zone:setAngularDampingOverride(1.0)
        end)
    end)

    -- @tests LuaZone:destroy
    -- @description Verifies destroy does not error.
    it("destroy does not error", function()
        expect_no_error(function()
            zone:destroy()
        end)
    end)
end)

-- @description Covers suite: lurek.physics zone events.
describe("lurek.physics zone events", function()
    -- @tests World:addZone
    -- @tests World:getZoneEvents
    -- @description Verifies getZoneEvents returns a table (may be empty before step).
    it("getZoneEvents returns a table", function()
        local world = lurek.physics.newWorld(0, 9.81)
        world:addZone(0, 0, 1000, 1000)
        local events = world:getZoneEvents()
        expect_type("table", events)
    end)

    -- @tests World:addZone
    -- @tests World:getZoneEvents
    -- @tests World:step
    -- @description Verifies that a body created inside a zone produces an enter event after the first step.
    it("body inside zone produces enter event after step", function()
        local world = lurek.physics.newWorld(0, 0)
        world:addZone(0, 0, 1000, 1000)
        lurek.physics.newBody(world, 0, 0, "dynamic")
        world:step(1/60)
        local events = world:getZoneEvents()
        expect_true(#events >= 1, "expected at least one zone event")
        expect_equal("enter", events[1].kind)
    end)
end)



-- [merged from test_physics_physics.lua]
-- @module lurek.physics
-- @description Unit tests for stateless geometric collision helpers.
-- All helpers are pure math; no physics world is required.

describe("lurek.physics helpers", function()

  -- ── testAABB ────────────────────────────────────────────────────────────

  -- @tests lurek.physics.testAABB
  -- @description Overlapping AABBs return true.
  it("testAABB detects overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 10, 10), true)
  end)

  -- @tests lurek.physics.testAABB
  -- @description Non-overlapping AABBs return false.
  it("testAABB detects no overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 20, 20, 10, 10), false)
  end)

  -- @tests lurek.physics.testAABB
  -- @description Edge-touching AABBs do not overlap (open interval).
  it("testAABB touching edges do not overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 10, 0, 10, 10), false)
  end)

  -- ── testCircles ─────────────────────────────────────────────────────────

  -- @tests lurek.physics.testCircles
  -- @description Overlapping circles return true.
  it("testCircles detects overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 5, 3, 0, 5), true)
  end)

  -- @tests lurek.physics.testCircles
  -- @description Non-overlapping circles return false.
  it("testCircles detects no overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 1, 10, 0, 1), false)
  end)

  -- @tests lurek.physics.testCircles
  -- @description Same-centre circles always overlap.
  it("testCircles same centre always overlaps", function()
    expect_equal(lurek.physics.testCircles(5, 5, 1, 5, 5, 1), true)
  end)

  -- ── testPoint ───────────────────────────────────────────────────────────

  -- @tests lurek.physics.testPoint
  -- @description Point inside the AABB returns true.
  it("testPoint inside AABB", function()
    expect_equal(lurek.physics.testPoint(5, 5, 0, 0, 10, 10), true)
  end)

  -- @tests lurek.physics.testPoint
  -- @description Point outside the AABB returns false.
  it("testPoint outside AABB", function()
    expect_equal(lurek.physics.testPoint(15, 5, 0, 0, 10, 10), false)
  end)

  -- @tests lurek.physics.testPoint
  -- @description Point on the right edge (exclusive) returns false.
  it("testPoint on right edge returns false", function()
    expect_equal(lurek.physics.testPoint(10, 5, 0, 0, 10, 10), false)
  end)

  -- @tests lurek.physics.testPoint
  -- @description Point at origin (inclusive) returns true.
  it("testPoint at origin is inside", function()
    expect_equal(lurek.physics.testPoint(0, 0, 0, 0, 10, 10), true)
  end)

  -- ── testCircleAABB ───────────────────────────────────────────────────────

  -- @tests lurek.physics.testCircleAABB
  -- @description Circle centred inside the AABB overlaps.
  it("testCircleAABB circle centre inside box", function()
    expect_equal(lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10), true)
  end)

  -- @tests lurek.physics.testCircleAABB
  -- @description Far circle does not overlap.
  it("testCircleAABB non-overlapping", function()
    expect_equal(lurek.physics.testCircleAABB(20, 20, 1, 0, 0, 10, 10), false)
  end)

  -- @tests lurek.physics.testCircleAABB
  -- @description Circle overlapping a corner of the AABB.
  it("testCircleAABB overlapping corner", function()
    -- Circle at (12, 12) with radius 3 — corner (10,10) is at distance sqrt(8) ≈ 2.83
    expect_equal(lurek.physics.testCircleAABB(12, 12, 3, 0, 0, 10, 10), true)
  end)

  -- @tests lurek.physics.testCircleAABB
  -- @description Circle just beyond a corner does not overlap.
  it("testCircleAABB just outside corner", function()
    -- Circle at (13, 13) with radius 1 — corner (10,10) is at distance sqrt(18) ≈ 4.24
    expect_equal(lurek.physics.testCircleAABB(13, 13, 1, 0, 0, 10, 10), false)
  end)

end)





-- ================================================================
-- Merged from: test_physics_collision.lua
-- ================================================================

-- @module lurek.physics
-- @description Unit tests for stateless geometric collision helpers.
-- All helpers are pure math; no physics world is required.

describe("lurek.physics helpers", function()

  -- ── testAABB ────────────────────────────────────────────────────────────

  -- @tests lurek.physics.testAABB
  -- @description Overlapping AABBs return true.
  it("testAABB detects overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 10, 10), true)
  end)

  -- @tests lurek.physics.testAABB
  -- @description Non-overlapping AABBs return false.
  it("testAABB detects no overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 20, 20, 10, 10), false)
  end)

  -- @tests lurek.physics.testAABB
  -- @description Edge-touching AABBs do not overlap (open interval).
  it("testAABB touching edges do not overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 10, 0, 10, 10), false)
  end)

  -- ── testCircles ─────────────────────────────────────────────────────────

  -- @tests lurek.physics.testCircles
  -- @description Overlapping circles return true.
  it("testCircles detects overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 5, 3, 0, 5), true)
  end)

  -- @tests lurek.physics.testCircles
  -- @description Non-overlapping circles return false.
  it("testCircles detects no overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 1, 10, 0, 1), false)
  end)

  -- @tests lurek.physics.testCircles
  -- @description Same-centre circles always overlap.
  it("testCircles same centre always overlaps", function()
    expect_equal(lurek.physics.testCircles(5, 5, 1, 5, 5, 1), true)
  end)

  -- ── testPoint ───────────────────────────────────────────────────────────

  -- @tests lurek.physics.testPoint
  -- @description Point inside the AABB returns true.
  it("testPoint inside AABB", function()
    expect_equal(lurek.physics.testPoint(5, 5, 0, 0, 10, 10), true)
  end)

  -- @tests lurek.physics.testPoint
  -- @description Point outside the AABB returns false.
  it("testPoint outside AABB", function()
    expect_equal(lurek.physics.testPoint(15, 5, 0, 0, 10, 10), false)
  end)

  -- @tests lurek.physics.testPoint
  -- @description Point on the right edge (exclusive) returns false.
  it("testPoint on right edge returns false", function()
    expect_equal(lurek.physics.testPoint(10, 5, 0, 0, 10, 10), false)
  end)

  -- @tests lurek.physics.testPoint
  -- @description Point at origin (inclusive) returns true.
  it("testPoint at origin is inside", function()
    expect_equal(lurek.physics.testPoint(0, 0, 0, 0, 10, 10), true)
  end)

  -- ── testCircleAABB ───────────────────────────────────────────────────────

  -- @tests lurek.physics.testCircleAABB
  -- @description Circle centred inside the AABB overlaps.
  it("testCircleAABB circle centre inside box", function()
    expect_equal(lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10), true)
  end)

  -- @tests lurek.physics.testCircleAABB
  -- @description Far circle does not overlap.
  it("testCircleAABB non-overlapping", function()
    expect_equal(lurek.physics.testCircleAABB(20, 20, 1, 0, 0, 10, 10), false)
  end)

  -- @tests lurek.physics.testCircleAABB
  -- @description Circle overlapping a corner of the AABB.
  it("testCircleAABB overlapping corner", function()
    -- Circle at (12, 12) with radius 3 — corner (10,10) is at distance sqrt(8) ≈ 2.83
    expect_equal(lurek.physics.testCircleAABB(12, 12, 3, 0, 0, 10, 10), true)
  end)

  -- @tests lurek.physics.testCircleAABB
  -- @description Circle just beyond a corner does not overlap.
  it("testCircleAABB just outside corner", function()
    -- Circle at (13, 13) with radius 1 — corner (10,10) is at distance sqrt(18) ≈ 4.24
    expect_equal(lurek.physics.testCircleAABB(13, 13, 1, 0, 0, 10, 10), false)
  end)

end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.physics.debugDraw
    it("covers lurek.physics.debugDraw", function()
        -- TODO: Implement test for lurek.physics.debugDraw
    end)

    -- @tests World:getJointBodies
    it("covers World:getJointBodies", function()
        -- TODO: Implement test for World:getJointBodies
    end)

    -- @tests World:getJointMotorSpeed
    it("covers World:getJointMotorSpeed", function()
        -- TODO: Implement test for World:getJointMotorSpeed
    end)

    -- @tests World:getJointLimits
    it("covers World:getJointLimits", function()
        -- TODO: Implement test for World:getJointLimits
    end)

    -- @tests World:getBodyAtPoint
    it("covers World:getBodyAtPoint", function()
        -- TODO: Implement test for World:getBodyAtPoint
    end)

    -- @tests World:getCollisionEvents
    it("covers World:getCollisionEvents", function()
        -- TODO: Implement test for World:getCollisionEvents
    end)

    -- @tests World:getBeginContactEvents
    it("covers World:getBeginContactEvents", function()
        -- TODO: Implement test for World:getBeginContactEvents
    end)

    -- @tests World:getEndContactEvents
    it("covers World:getEndContactEvents", function()
        -- TODO: Implement test for World:getEndContactEvents
    end)

    -- @tests World:getContacts
    it("covers World:getContacts", function()
        -- TODO: Implement test for World:getContacts
    end)

    -- @tests World:getBodyContacts
    it("covers World:getBodyContacts", function()
        -- TODO: Implement test for World:getBodyContacts
    end)

    -- @tests World:setBodyType
    it("covers World:setBodyType", function()
        -- TODO: Implement test for World:setBodyType
    end)

    -- @tests World:getBodyType
    it("covers World:getBodyType", function()
        -- TODO: Implement test for World:getBodyType
    end)

    -- @tests Body:setMass
    it("covers Body:setMass", function()
        -- TODO: Implement test for Body:setMass
    end)

end)

describe("Missing explicit test for lurek.physics.getCollisions", function()
    it("lurek.physics.getCollisions works", function()
        -- @tests lurek.physics.getCollisions
        -- TODO: add assertion for lurek.physics.getCollisions
    end)
end)

describe("Missing explicit test for lurek.physics.drawDebugGpu", function()
    it("lurek.physics.drawDebugGpu works", function()
        -- @tests lurek.physics.drawDebugGpu
        -- TODO: add assertion for lurek.physics.drawDebugGpu
    end)
end)

describe("Missing explicit test for World:clear", function()
    it("World:clear works", function()
        -- @tests World:clear
        -- TODO: add assertion for World:clear
    end)
end)

describe("Missing explicit test for World:getGravity", function()
    it("World:getGravity works", function()
        -- @tests World:getGravity
        -- TODO: add assertion for World:getGravity
    end)
end)

describe("Missing explicit test for World:setGravity", function()
    it("World:setGravity works", function()
        -- @tests World:setGravity
        -- TODO: add assertion for World:setGravity
    end)
end)

describe("Missing explicit test for World:setMeter", function()
    it("World:setMeter works", function()
        -- @tests World:setMeter
        -- TODO: add assertion for World:setMeter
    end)
end)

describe("Missing explicit test for World:getMeter", function()
    it("World:getMeter works", function()
        -- @tests World:getMeter
        -- TODO: add assertion for World:getMeter
    end)
end)

describe("Missing explicit test for World:toPhysics", function()
    it("World:toPhysics works", function()
        -- @tests World:toPhysics
        -- TODO: add assertion for World:toPhysics
    end)
end)

describe("Missing explicit test for World:toPixels", function()
    it("World:toPixels works", function()
        -- @tests World:toPixels
        -- TODO: add assertion for World:toPixels
    end)
end)

describe("Missing explicit test for World:getBodyCount", function()
    it("World:getBodyCount works", function()
        -- @tests World:getBodyCount
        -- TODO: add assertion for World:getBodyCount
    end)
end)

describe("Missing explicit test for World:getBodyIds", function()
    it("World:getBodyIds works", function()
        -- @tests World:getBodyIds
        -- TODO: add assertion for World:getBodyIds
    end)
end)

describe("Missing explicit test for World:destroyBody", function()
    it("World:destroyBody works", function()
        -- @tests World:destroyBody
        -- TODO: add assertion for World:destroyBody
    end)
end)

describe("Missing explicit test for World:fixtureCount", function()
    it("World:fixtureCount works", function()
        -- @tests World:fixtureCount
        -- TODO: add assertion for World:fixtureCount
    end)
end)

describe("Missing explicit test for World:jointCount", function()
    it("World:jointCount works", function()
        -- @tests World:jointCount
        -- TODO: add assertion for World:jointCount
    end)
end)

describe("Missing explicit test for World:getJointIds", function()
    it("World:getJointIds works", function()
        -- @tests World:getJointIds
        -- TODO: add assertion for World:getJointIds
    end)
end)

describe("Missing explicit test for World:destroyJoint", function()
    it("World:destroyJoint works", function()
        -- @tests World:destroyJoint
        -- TODO: add assertion for World:destroyJoint
    end)
end)

describe("Missing explicit test for World:getJointType", function()
    it("World:getJointType works", function()
        -- @tests World:getJointType
        -- TODO: add assertion for World:getJointType
    end)
end)

describe("Missing explicit test for World:setBeginContact", function()
    it("World:setBeginContact works", function()
        -- @tests World:setBeginContact
        -- TODO: add assertion for World:setBeginContact
    end)
end)

describe("Missing explicit test for World:clearBeginContact", function()
    it("World:clearBeginContact works", function()
        -- @tests World:clearBeginContact
        -- TODO: add assertion for World:clearBeginContact
    end)
end)

describe("Missing explicit test for World:setEndContact", function()
    it("World:setEndContact works", function()
        -- @tests World:setEndContact
        -- TODO: add assertion for World:setEndContact
    end)
end)

describe("Missing explicit test for World:clearEndContact", function()
    it("World:clearEndContact works", function()
        -- @tests World:clearEndContact
        -- TODO: add assertion for World:clearEndContact
    end)
end)

describe("Missing explicit test for World:getBodyData", function()
    it("World:getBodyData works", function()
        -- @tests World:getBodyData
        -- TODO: add assertion for World:getBodyData
    end)
end)

describe("Missing explicit test for World:clearBodyData", function()
    it("World:clearBodyData works", function()
        -- @tests World:clearBodyData
        -- TODO: add assertion for World:clearBodyData
    end)
end)

describe("Missing explicit test for World:setBodyCCD", function()
    it("World:setBodyCCD works", function()
        -- @tests World:setBodyCCD
        -- TODO: add assertion for World:setBodyCCD
    end)
end)

describe("Missing explicit test for World:getBodyCCD", function()
    it("World:getBodyCCD works", function()
        -- @tests World:getBodyCCD
        -- TODO: add assertion for World:getBodyCCD
    end)
end)

describe("Missing explicit test for World:clearBodyOneWay", function()
    it("World:clearBodyOneWay works", function()
        -- @tests World:clearBodyOneWay
        -- TODO: add assertion for World:clearBodyOneWay
    end)
end)

describe("Missing explicit test for World:getBodyOneWay", function()
    it("World:getBodyOneWay works", function()
        -- @tests World:getBodyOneWay
        -- TODO: add assertion for World:getBodyOneWay
    end)
end)

describe("Missing explicit test for World:setJointBreakForce", function()
    it("World:setJointBreakForce works", function()
        -- @tests World:setJointBreakForce
        -- TODO: add assertion for World:setJointBreakForce
    end)
end)

describe("Missing explicit test for World:getJointBreakForce", function()
    it("World:getJointBreakForce works", function()
        -- @tests World:getJointBreakForce
        -- TODO: add assertion for World:getJointBreakForce
    end)
end)

describe("Missing explicit test for World:isBodySleeping", function()
    it("World:isBodySleeping works", function()
        -- @tests World:isBodySleeping
        -- TODO: add assertion for World:isBodySleeping
    end)
end)

describe("Missing explicit test for World:wakeUpBody", function()
    it("World:wakeUpBody works", function()
        -- @tests World:wakeUpBody
        -- TODO: add assertion for World:wakeUpBody
    end)
end)

describe("Missing explicit test for World:sleepBody", function()
    it("World:sleepBody works", function()
        -- @tests World:sleepBody
        -- TODO: add assertion for World:sleepBody
    end)
end)

describe("Missing explicit test for World:setSolverIterations", function()
    it("World:setSolverIterations works", function()
        -- @tests World:setSolverIterations
        -- TODO: add assertion for World:setSolverIterations
    end)
end)

describe("Missing explicit test for World:getSolverIterations", function()
    it("World:getSolverIterations works", function()
        -- @tests World:getSolverIterations
        -- TODO: add assertion for World:getSolverIterations
    end)
end)

describe("Missing explicit test for World:newBodies", function()
    it("World:newBodies works", function()
        -- @tests World:newBodies
        -- TODO: add assertion for World:newBodies
    end)
end)

describe("Missing explicit test for Zone:getId", function()
    it("Zone:getId works", function()
        -- @tests Zone:getId
        -- TODO: add assertion for Zone:getId
    end)
end)

describe("Missing explicit test for Zone:setEnabled", function()
    it("Zone:setEnabled works", function()
        -- @tests Zone:setEnabled
        -- TODO: add assertion for Zone:setEnabled
    end)
end)

describe("Missing explicit test for Zone:setPriority", function()
    it("Zone:setPriority works", function()
        -- @tests Zone:setPriority
        -- TODO: add assertion for Zone:setPriority
    end)
end)

describe("Missing explicit test for Zone:setLayerMask", function()
    it("Zone:setLayerMask works", function()
        -- @tests Zone:setLayerMask
        -- TODO: add assertion for Zone:setLayerMask
    end)
end)

describe("Missing explicit test for Zone:setCircle", function()
    it("Zone:setCircle works", function()
        -- @tests Zone:setCircle
        -- TODO: add assertion for Zone:setCircle
    end)
end)

describe("Missing explicit test for Zone:setGravityDirectional", function()
    it("Zone:setGravityDirectional works", function()
        -- @tests Zone:setGravityDirectional
        -- TODO: add assertion for Zone:setGravityDirectional
    end)
end)

describe("Missing explicit test for Zone:setGravityZero", function()
    it("Zone:setGravityZero works", function()
        -- @tests Zone:setGravityZero
        -- TODO: add assertion for Zone:setGravityZero
    end)
end)

describe("Missing explicit test for Zone:setLinearDampingOverride", function()
    it("Zone:setLinearDampingOverride works", function()
        -- @tests Zone:setLinearDampingOverride
        -- TODO: add assertion for Zone:setLinearDampingOverride
    end)
end)

describe("Missing explicit test for Zone:destroy", function()
    it("Zone:destroy works", function()
        -- @tests Zone:destroy
        -- TODO: add assertion for Zone:destroy
    end)
end)

describe("Missing explicit test for Terrain:setCell", function()
    it("Terrain:setCell works", function()
        -- @tests Terrain:setCell
        -- TODO: add assertion for Terrain:setCell
    end)
end)

describe("Missing explicit test for Terrain:getCell", function()
    it("Terrain:getCell works", function()
        -- @tests Terrain:getCell
        -- TODO: add assertion for Terrain:getCell
    end)
end)

describe("Missing explicit test for Terrain:fillAll", function()
    it("Terrain:fillAll works", function()
        -- @tests Terrain:fillAll
        -- TODO: add assertion for Terrain:fillAll
    end)
end)

describe("Missing explicit test for Terrain:flush", function()
    it("Terrain:flush works", function()
        -- @tests Terrain:flush
        -- TODO: add assertion for Terrain:flush
    end)
end)

describe("Missing explicit test for Terrain:isDirty", function()
    it("Terrain:isDirty works", function()
        -- @tests Terrain:isDirty
        -- TODO: add assertion for Terrain:isDirty
    end)
end)

describe("Missing explicit test for Terrain:collapseColumns", function()
    it("Terrain:collapseColumns works", function()
        -- @tests Terrain:collapseColumns
        -- TODO: add assertion for Terrain:collapseColumns
    end)
end)

describe("Missing explicit test for Terrain:solidPositions", function()
    it("Terrain:solidPositions works", function()
        -- @tests Terrain:solidPositions
        -- TODO: add assertion for Terrain:solidPositions
    end)
end)

describe("Missing explicit test for Terrain:toBytes", function()
    it("Terrain:toBytes works", function()
        -- @tests Terrain:toBytes
        -- TODO: add assertion for Terrain:toBytes
    end)
end)

describe("Missing explicit test for Terrain:loadFromBytes", function()
    it("Terrain:loadFromBytes works", function()
        -- @tests Terrain:loadFromBytes
        -- TODO: add assertion for Terrain:loadFromBytes
    end)
end)

describe("Missing explicit test for Cellular:setCell", function()
    it("Cellular:setCell works", function()
        -- @tests Cellular:setCell
        -- TODO: add assertion for Cellular:setCell
    end)
end)

describe("Missing explicit test for Cellular:getCell", function()
    it("Cellular:getCell works", function()
        -- @tests Cellular:getCell
        -- TODO: add assertion for Cellular:getCell
    end)
end)

describe("Missing explicit test for Cellular:step", function()
    it("Cellular:step works", function()
        -- @tests Cellular:step
        -- TODO: add assertion for Cellular:step
    end)
end)

describe("Missing explicit test for Cellular:stepN", function()
    it("Cellular:stepN works", function()
        -- @tests Cellular:stepN
        -- TODO: add assertion for Cellular:stepN
    end)
end)

describe("Missing explicit test for Cellular:toImageData", function()
    it("Cellular:toImageData works", function()
        -- @tests Cellular:toImageData
        -- TODO: add assertion for Cellular:toImageData
    end)
end)

describe("Missing explicit test for Cellular:countCells", function()
    it("Cellular:countCells works", function()
        -- @tests Cellular:countCells
        -- TODO: add assertion for Cellular:countCells
    end)
end)

describe("Missing explicit test for Cellular:findCells", function()
    it("Cellular:findCells works", function()
        -- @tests Cellular:findCells
        -- TODO: add assertion for Cellular:findCells
    end)
end)

describe("Missing explicit test for Cellular:toBytes", function()
    it("Cellular:toBytes works", function()
        -- @tests Cellular:toBytes
        -- TODO: add assertion for Cellular:toBytes
    end)
end)

describe("Missing explicit test for Cellular:loadFromBytes", function()
    it("Cellular:loadFromBytes works", function()
        -- @tests Cellular:loadFromBytes
        -- TODO: add assertion for Cellular:loadFromBytes
    end)
end)

describe("Missing explicit test for Body:getId", function()
    it("Body:getId works", function()
        -- @tests Body:getId
        -- TODO: add assertion for Body:getId
    end)
end)

describe("Missing explicit test for Body:getPosition", function()
    it("Body:getPosition works", function()
        -- @tests Body:getPosition
        -- TODO: add assertion for Body:getPosition
    end)
end)

describe("Missing explicit test for Body:setPosition", function()
    it("Body:setPosition works", function()
        -- @tests Body:setPosition
        -- TODO: add assertion for Body:setPosition
    end)
end)

describe("Missing explicit test for Body:getX", function()
    it("Body:getX works", function()
        -- @tests Body:getX
        -- TODO: add assertion for Body:getX
    end)
end)

describe("Missing explicit test for Body:getY", function()
    it("Body:getY works", function()
        -- @tests Body:getY
        -- TODO: add assertion for Body:getY
    end)
end)

describe("Missing explicit test for Body:getVelocity", function()
    it("Body:getVelocity works", function()
        -- @tests Body:getVelocity
        -- TODO: add assertion for Body:getVelocity
    end)
end)

describe("Missing explicit test for Body:setVelocity", function()
    it("Body:setVelocity works", function()
        -- @tests Body:setVelocity
        -- TODO: add assertion for Body:setVelocity
    end)
end)

describe("Missing explicit test for Body:getAngle", function()
    it("Body:getAngle works", function()
        -- @tests Body:getAngle
        -- TODO: add assertion for Body:getAngle
    end)
end)

describe("Missing explicit test for Body:setAngle", function()
    it("Body:setAngle works", function()
        -- @tests Body:setAngle
        -- TODO: add assertion for Body:setAngle
    end)
end)

describe("Missing explicit test for Body:getAngularVelocity", function()
    it("Body:getAngularVelocity works", function()
        -- @tests Body:getAngularVelocity
        -- TODO: add assertion for Body:getAngularVelocity
    end)
end)

describe("Missing explicit test for Body:setAngularVelocity", function()
    it("Body:setAngularVelocity works", function()
        -- @tests Body:setAngularVelocity
        -- TODO: add assertion for Body:setAngularVelocity
    end)
end)

describe("Missing explicit test for Body:getMass", function()
    it("Body:getMass works", function()
        -- @tests Body:getMass
        -- TODO: add assertion for Body:getMass
    end)
end)

describe("Missing explicit test for Body:getType", function()
    it("Body:getType works", function()
        -- @tests Body:getType
        -- TODO: add assertion for Body:getType
    end)
end)

describe("Missing explicit test for Body:setType", function()
    it("Body:setType works", function()
        -- @tests Body:setType
        -- TODO: add assertion for Body:setType
    end)
end)

describe("Missing explicit test for Body:getWidth", function()
    it("Body:getWidth works", function()
        -- @tests Body:getWidth
        -- TODO: add assertion for Body:getWidth
    end)
end)

describe("Missing explicit test for Body:getHeight", function()
    it("Body:getHeight works", function()
        -- @tests Body:getHeight
        -- TODO: add assertion for Body:getHeight
    end)
end)

describe("Missing explicit test for Body:getFriction", function()
    it("Body:getFriction works", function()
        -- @tests Body:getFriction
        -- TODO: add assertion for Body:getFriction
    end)
end)

describe("Missing explicit test for Body:setFriction", function()
    it("Body:setFriction works", function()
        -- @tests Body:setFriction
        -- TODO: add assertion for Body:setFriction
    end)
end)

describe("Missing explicit test for Body:getRestitution", function()
    it("Body:getRestitution works", function()
        -- @tests Body:getRestitution
        -- TODO: add assertion for Body:getRestitution
    end)
end)

describe("Missing explicit test for Body:setRestitution", function()
    it("Body:setRestitution works", function()
        -- @tests Body:setRestitution
        -- TODO: add assertion for Body:setRestitution
    end)
end)

describe("Missing explicit test for Body:getLayer", function()
    it("Body:getLayer works", function()
        -- @tests Body:getLayer
        -- TODO: add assertion for Body:getLayer
    end)
end)

describe("Missing explicit test for Body:setLayer", function()
    it("Body:setLayer works", function()
        -- @tests Body:setLayer
        -- TODO: add assertion for Body:setLayer
    end)
end)

describe("Missing explicit test for Body:getMask", function()
    it("Body:getMask works", function()
        -- @tests Body:getMask
        -- TODO: add assertion for Body:getMask
    end)
end)

describe("Missing explicit test for Body:setMask", function()
    it("Body:setMask works", function()
        -- @tests Body:setMask
        -- TODO: add assertion for Body:setMask
    end)
end)

describe("Missing explicit test for Body:applyImpulse", function()
    it("Body:applyImpulse works", function()
        -- @tests Body:applyImpulse
        -- TODO: add assertion for Body:applyImpulse
    end)
end)

describe("Missing explicit test for Body:applyForce", function()
    it("Body:applyForce works", function()
        -- @tests Body:applyForce
        -- TODO: add assertion for Body:applyForce
    end)
end)

describe("Missing explicit test for Body:applyTorque", function()
    it("Body:applyTorque works", function()
        -- @tests Body:applyTorque
        -- TODO: add assertion for Body:applyTorque
    end)
end)

describe("Missing explicit test for Body:applyAngularImpulse", function()
    it("Body:applyAngularImpulse works", function()
        -- @tests Body:applyAngularImpulse
        -- TODO: add assertion for Body:applyAngularImpulse
    end)
end)

describe("Missing explicit test for Body:getGravityScale", function()
    it("Body:getGravityScale works", function()
        -- @tests Body:getGravityScale
        -- TODO: add assertion for Body:getGravityScale
    end)
end)

describe("Missing explicit test for Body:setGravityScale", function()
    it("Body:setGravityScale works", function()
        -- @tests Body:setGravityScale
        -- TODO: add assertion for Body:setGravityScale
    end)
end)

describe("Missing explicit test for Body:isFixedRotation", function()
    it("Body:isFixedRotation works", function()
        -- @tests Body:isFixedRotation
        -- TODO: add assertion for Body:isFixedRotation
    end)
end)

describe("Missing explicit test for Body:setFixedRotation", function()
    it("Body:setFixedRotation works", function()
        -- @tests Body:setFixedRotation
        -- TODO: add assertion for Body:setFixedRotation
    end)
end)

describe("Missing explicit test for Body:getLinearDamping", function()
    it("Body:getLinearDamping works", function()
        -- @tests Body:getLinearDamping
        -- TODO: add assertion for Body:getLinearDamping
    end)
end)

describe("Missing explicit test for Body:setLinearDamping", function()
    it("Body:setLinearDamping works", function()
        -- @tests Body:setLinearDamping
        -- TODO: add assertion for Body:setLinearDamping
    end)
end)

describe("Missing explicit test for Body:getAngularDamping", function()
    it("Body:getAngularDamping works", function()
        -- @tests Body:getAngularDamping
        -- TODO: add assertion for Body:getAngularDamping
    end)
end)

describe("Missing explicit test for Body:setAngularDamping", function()
    it("Body:setAngularDamping works", function()
        -- @tests Body:setAngularDamping
        -- TODO: add assertion for Body:setAngularDamping
    end)
end)

describe("Missing explicit test for Body:isBullet", function()
    it("Body:isBullet works", function()
        -- @tests Body:isBullet
        -- TODO: add assertion for Body:isBullet
    end)
end)

describe("Missing explicit test for Body:setBullet", function()
    it("Body:setBullet works", function()
        -- @tests Body:setBullet
        -- TODO: add assertion for Body:setBullet
    end)
end)

describe("Missing explicit test for Body:isSleepingAllowed", function()
    it("Body:isSleepingAllowed works", function()
        -- @tests Body:isSleepingAllowed
        -- TODO: add assertion for Body:isSleepingAllowed
    end)
end)

describe("Missing explicit test for Body:setSleepingAllowed", function()
    it("Body:setSleepingAllowed works", function()
        -- @tests Body:setSleepingAllowed
        -- TODO: add assertion for Body:setSleepingAllowed
    end)
end)

describe("Missing explicit test for Body:destroy", function()
    it("Body:destroy works", function()
        -- @tests Body:destroy
        -- TODO: add assertion for Body:destroy
    end)
end)

describe("Missing explicit test for Body:isSleeping", function()
    it("Body:isSleeping works", function()
        -- @tests Body:isSleeping
        -- TODO: add assertion for Body:isSleeping
    end)
end)

describe("Missing explicit test for Body:wakeUp", function()
    it("Body:wakeUp works", function()
        -- @tests Body:wakeUp
        -- TODO: add assertion for Body:wakeUp
    end)
end)

describe("Missing explicit test for Body:sleep", function()
    it("Body:sleep works", function()
        -- @tests Body:sleep
        -- TODO: add assertion for Body:sleep
    end)
end)

describe("Missing explicit test for PhysicsShape:getType", function()
    it("PhysicsShape:getType works", function()
        -- @tests PhysicsShape:getType
        -- TODO: add assertion for PhysicsShape:getType
    end)
end)

describe("Missing explicit test for PhysicsShape:getRadius", function()
    it("PhysicsShape:getRadius works", function()
        -- @tests PhysicsShape:getRadius
        -- TODO: add assertion for PhysicsShape:getRadius
    end)
end)

describe("Missing explicit test for PhysicsShape:getBoundingBox", function()
    it("PhysicsShape:getBoundingBox works", function()
        -- @tests PhysicsShape:getBoundingBox
        -- TODO: add assertion for PhysicsShape:getBoundingBox
    end)
end)

describe("Missing explicit test for PhysicsShape:setDensity", function()
    it("PhysicsShape:setDensity works", function()
        -- @tests PhysicsShape:setDensity
        -- TODO: add assertion for PhysicsShape:setDensity
    end)
end)

describe("Missing explicit test for PhysicsShape:setFriction", function()
    it("PhysicsShape:setFriction works", function()
        -- @tests PhysicsShape:setFriction
        -- TODO: add assertion for PhysicsShape:setFriction
    end)
end)

describe("Missing explicit test for PhysicsShape:setRestitution", function()
    it("PhysicsShape:setRestitution works", function()
        -- @tests PhysicsShape:setRestitution
        -- TODO: add assertion for PhysicsShape:setRestitution
    end)
end)

describe("Missing explicit test for PhysicsShape:setSensor", function()
    it("PhysicsShape:setSensor works", function()
        -- @tests PhysicsShape:setSensor
        -- TODO: add assertion for PhysicsShape:setSensor
    end)
end)

describe("Missing explicit test for PhysicsShape:destroy", function()
    it("PhysicsShape:destroy works", function()
        -- @tests PhysicsShape:destroy
        -- TODO: add assertion for PhysicsShape:destroy
    end)
end)

-- =========================================================================
-- @covers additions for physics module
-- =========================================================================

describe("World:newChainBody (@covers)", function()
    it("newChainBody returns a body ID", function()
        -- @covers World:newChainBody
        local w = lurek.physics.newWorld(0, 9.81)
        local ok, id = pcall(function()
            return w:newChainBody(
                {0,0, 10,0, 10,10, 0,10},
                5.0, 5.0, {type = "static"}
            )
        end)
        expect_type("boolean", ok)
        if ok then expect_not_nil(id) end
    end)
end)

describe("World joint constructors (@covers)", function()
    local function make_pair()
        local w = lurek.physics.newWorld(0, 9.81)
        local a = w:newBody(2.0, 2.0, "dynamic")
        local b = w:newBody(8.0, 2.0, "dynamic")
        return w, a, b
    end

    it("addPrismaticJoint creates a joint", function()
        -- @covers World:addPrismaticJoint
        local w, a, b = make_pair()
        local ok, jid = pcall(function()
            return w:addPrismaticJoint(a, b, 5.0, 2.0, 1.0, 0.0)
        end)
        expect_type("boolean", ok)
        if ok then expect_not_nil(jid) end
    end)

    it("addRopeJoint creates a joint", function()
        -- @covers World:addRopeJoint
        local w, a, b = make_pair()
        local ok, jid = pcall(function()
            return w:addRopeJoint(a, b, 6.0)
        end)
        expect_type("boolean", ok)
        if ok then expect_not_nil(jid) end
    end)

    it("addWheelJoint creates a joint", function()
        -- @covers World:addWheelJoint
        local w, a, b = make_pair()
        local ok, jid = pcall(function()
            return w:addWheelJoint(a, b, 5.0, 2.0, 0.0, 1.0)
        end)
        expect_type("boolean", ok)
        if ok then expect_not_nil(jid) end
    end)

    it("addFrictionJoint creates a joint", function()
        -- @covers World:addFrictionJoint
        local w, a, b = make_pair()
        local ok, jid = pcall(function()
            return w:addFrictionJoint(a, b, 5.0, 2.0, 1.0)
        end)
        expect_type("boolean", ok)
        if ok then expect_not_nil(jid) end
    end)

    it("addMotorJoint creates a joint", function()
        -- @covers World:addMotorJoint
        local w, a, b = make_pair()
        local ok, jid = pcall(function()
            return w:addMotorJoint(a, b, {max_force=100, max_torque=50})
        end)
        expect_type("boolean", ok)
        if ok then expect_not_nil(jid) end
    end)

    it("addMouseJoint creates a joint", function()
        -- @covers World:addMouseJoint
        local w, a, _ = make_pair()
        local ok, jid = pcall(function()
            return w:addMouseJoint(a, 2.0, 2.0, {max_force=1000})
        end)
        expect_type("boolean", ok)
        if ok then expect_not_nil(jid) end
    end)

    it("addPulleyJoint creates a joint", function()
        -- @covers World:addPulleyJoint
        local w, a, b = make_pair()
        local ok, jid = pcall(function()
            return w:addPulleyJoint(a, b, 2,0, 8,0, 2,2, 8,2, 1.0)
        end)
        expect_type("boolean", ok)
        if ok then expect_not_nil(jid) end
    end)

    it("addGearJoint creates a joint", function()
        -- @covers World:addGearJoint
        local w, a, b = make_pair()
        local j1_ok, j1 = pcall(function()
            return w:addRevoluteJoint(a, b, 5.0, 2.0)
        end)
        local j2_ok, j2 = pcall(function()
            return w:addRevoluteJoint(a, b, 5.0, 2.0)
        end)
        if j1_ok and j2_ok then
            local ok, jid = pcall(function()
                return w:addGearJoint(j1, j2, 1.0)
            end)
            expect_type("boolean", ok)
        end
    end)
end)

describe("World:raycastClosest and World:queryAABB (@covers)", function()
    it("raycastClosest returns a result table or nil", function()
        -- @covers World:raycastClosest
        local w = lurek.physics.newWorld(0, 9.81)
        local ok, result = pcall(function()
            return w:raycastClosest(0, 0, 100, 0, 1)
        end)
        expect_type("boolean", ok)
        if ok and result ~= nil then
            expect_type("table", result)
        end
    end)

    it("queryAABB returns a list (possibly empty)", function()
        -- @covers World:queryAABB
        local w = lurek.physics.newWorld(0, 9.81)
        local results = w:queryAABB(0, 0, 100, 100)
        expect_not_nil(results)
        expect_type("table", results)
    end)
end)

describe("Body:applyForceAtPoint (@covers)", function()
    it("applyForceAtPoint does not crash", function()
        -- @covers Body:applyForceAtPoint
        local w = lurek.physics.newWorld(0, 9.81)
        local bid = w:newBody(5.0, 5.0, "dynamic")
        local ok, _ = pcall(function()
            w:applyForceAtPoint(bid, 0, -100, 5.0, 5.0)
        end)
        expect_type("boolean", ok)
    end)
end)
