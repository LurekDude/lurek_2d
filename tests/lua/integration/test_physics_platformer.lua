-- Lurek2D Physics + one-way-platform integration test
-- Tests lurek.physics interacting with a one-way floor setup:
-- a dynamic body falls toward a one-way static platform.
-- Requires both lurek.physics and the extension methods.

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

    it("floor has correct one-way normal", function()
        local nx, ny = world:getBodyOneWay(floor:getId())
        expect_near(0,  nx, 1e-5)
        expect_near(-1, ny, 1e-5)
    end)

    it("world steps without error with one-way bodies", function()
        expect_no_error(function()
            for _ = 1, 10 do
                world:step(1/60)
            end
        end)
    end)
end)

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

    it("world steps without error when callbacks are registered", function()
        local b1 = lurek.physics.newBody(world, 0, 0, "dynamic")
        local b2 = lurek.physics.newBody(world, 50, 0, "static")
        expect_no_error(function()
            for _ = 1, 5 do
                world:step(1/60)
            end
        end)
    end)

    it("stepping after clearing callbacks does not error", function()
        world:clearBeginContact()
        world:clearEndContact()
        expect_no_error(function()
            world:step(1/60)
        end)
    end)

    it("sleep then wake then step does not error", function()
        local b = lurek.physics.newBody(world, 0, 0, "dynamic")
        world:sleepBody(b:getId())
        world:wakeUpBody(b:getId())
        expect_no_error(function()
            world:step(1/60)
        end)
    end)
end)

describe("batch body creation integration", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
    end)

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

    it("batch creation works with custom solver iterations", function()
        world:setSolverIterations(6)
        local ids = world:newBodies({{0, 0, "dynamic"}, {50, 0, "dynamic"}})
        expect_equal(2, #ids)
        expect_equal(6, world:getSolverIterations())
    end)
end)
test_summary()
