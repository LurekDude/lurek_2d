-- Lurek2D Physics + one-way-platform integration test
-- Tests lurek.physics interacting with a one-way floor setup:
-- a dynamic body falls toward a one-way static platform.
-- Requires both lurek.physics and the extension methods.

-- @description Covers suite: one-way platform + dynamic body integration.
describe("one-way platform integration", function()
    local world, floor, player

    before_each(function()
        -- Gravity pointing down (+Y).
        world  = lurek.physics.newWorld(0, 200)
        -- A wide static floor at y=500.
        floor  = lurek.physics.newBody(world, 400, 500, "static")
        -- Mark the floor as one-way: normal points upward (0, -1)
        -- so bodies approaching from above are blocked.
        world:setBodyOneWay(floor:getId(), 0, -1)
        -- A dynamic player above the floor.
        player = lurek.physics.newBody(world, 400, 100, "dynamic")
    end)

    -- @covers lurek.physics.World:setBodyOneWay
    -- @covers lurek.physics.World:getBodyOneWay
    -- @description Verifies the floor has the expected one-way normal.
    it("floor has correct one-way normal", function()
        local nx, ny = world:getBodyOneWay(floor:getId())
        expect_near(0,  nx, 1e-5)
        expect_near(-1, ny, 1e-5)
    end)

    -- @covers lurek.physics.World:step
    -- @covers lurek.physics.World:setBodyOneWay
    -- @description Verifies a world with one-way bodies can step without error.
    it("world steps without error with one-way bodies", function()
        expect_no_error(function()
            for _ = 1, 10 do
                world:step(1/60)
            end
        end)
    end)
end)

-- @description Covers suite: contact callbacks + sleeping integration.
describe("contact callbacks and sleeping integration", function()
    local world
    local began, ended

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
        began = 0
        ended = 0
        world:setBeginContact(function(a, b)
            began = began + 1
        end)
        world:setEndContact(function(a, b)
            ended = ended + 1
        end)
    end)

    -- @covers lurek.physics.World:setBeginContact
    -- @covers lurek.physics.World:setEndContact
    -- @covers lurek.physics.World:step
    -- @description Verifies stepping with callbacks registered does not error.
    it("world steps without error when callbacks are registered", function()
        local b1 = lurek.physics.newBody(world, 0, 0, "dynamic")
        local b2 = lurek.physics.newBody(world, 50, 0, "static")
        expect_no_error(function()
            for _ = 1, 5 do
                world:step(1/60)
            end
        end)
    end)

    -- @covers lurek.physics.World:clearBeginContact
    -- @covers lurek.physics.World:clearEndContact
    -- @description Verifies clearing callbacks and then stepping does not error.
    it("stepping after clearing callbacks does not error", function()
        world:clearBeginContact()
        world:clearEndContact()
        expect_no_error(function()
            world:step(1/60)
        end)
    end)

    -- @covers lurek.physics.World:sleepBody
    -- @covers lurek.physics.World:wakeUpBody
    -- @covers lurek.physics.World:step
    -- @description Verifies callback + sleep + wake round-trip works cleanly.
    it("sleep then wake then step does not error", function()
        local b = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:sleepBody(b:getId())
        world:wakeUpBody(b:getId())
        expect_no_error(function()
            world:step(1/60)
        end)
    end)
end)

-- @description Covers suite: batch body creation integration.
describe("batch body creation integration", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
    end)

    -- @covers lurek.physics.World:newBodies
    -- @covers lurek.physics.World:step
    -- @description Verifies batch-created bodies can be stepped without error.
    it("batch-created bodies can be stepped", function()
        local ids = world:newBodies({
            {0,   0, "dynamic"},
            {100, 0, "static"},
            {200, 0, "kinematic"},
        })
        expect_equal(3, #ids)
        expect_no_error(function()
            for _ = 1, 5 do
                world:step(1/60)
            end
        end)
    end)

    -- @covers lurek.physics.World:newBodies
    -- @covers lurek.physics.World:setSolverIterations
    -- @description Verifies batch creation works with a non-default solver count.
    it("batch creation works with custom solver iterations", function()
        world:setSolverIterations(6)
        local ids = world:newBodies({{0, 0, "dynamic"}, {50, 0, "dynamic"}})
        expect_equal(2, #ids)
        expect_equal(6, world:getSolverIterations())
    end)
end)

test_summary()
