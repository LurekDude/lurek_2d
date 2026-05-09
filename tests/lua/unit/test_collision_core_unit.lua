-- test_collision_core_unit.lua
--
-- lurek.collision is NOT a standalone module.
-- Collision detection is provided by lurek.physics (see test_physics_core_unit.lua).
-- These tests document that fact and verify the physics-side collision surface exists.

-- @describe lurek.collision - not a standalone module
describe("lurek.collision - not a standalone module", function()
    -- @covers lurek.collision
    it("lurek.collision is nil (no separate collision module)", function()
        expect_nil(lurek.collision)
    end)
end)

-- @describe collision surface available via lurek.physics
describe("collision surface available via lurek.physics", function()
    -- @covers lurek.physics.newWorld
    it("lurek.physics is a table with newWorld", function()
        expect_type("table", lurek.physics)
        expect_type("function", lurek.physics.newWorld)
    end)

    -- @covers lurek.physics.newWorld
    it("newWorld returns userdata instance", function()
        local world = lurek.physics.newWorld(0, 9.81)
        expect_type("userdata", world)
    end)

    -- @covers LWorld:getCollisionEvents
    it("getCollisionEvents returns a table on a fresh world", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local events = world:getCollisionEvents()
        expect_type("table", events)
    end)

    -- @covers LWorld:getCollisionEvents
    -- @covers LWorld:step
    it("getCollisionEvents is empty after step with no bodies", function()
        local world = lurek.physics.newWorld(0, 9.81)
        world:step(1 / 60)
        local events = world:getCollisionEvents()
        expect_equal(0, #events)
    end)

    -- @covers LBody:getLayer
    -- @covers LBody:setLayer
    it("getLayer / setLayer round-trip", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 5.0, "dynamic")
        body:setLayer(3)
        expect_equal(3, body:getLayer())
    end)

    -- @covers LBody:getMask
    -- @covers LBody:setMask
    it("getMask / setMask round-trip", function()
        local world = lurek.physics.newWorld(0, 9.81)
        local body = world:newCircleBody(0, 0, 5.0, "dynamic")
        body:setMask(7)
        expect_equal(7, body:getMask())
    end)
end)

test_summary()
