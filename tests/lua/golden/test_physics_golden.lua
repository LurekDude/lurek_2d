-- Lurek2D Golden Test: Physics Simulation
-- Verifies physics stepping produces deterministic positions
-- @golden physics determinism

describe("golden: physics freefall determinism", function()
    it("body falls to same position given same setup", function()
        local function simulate_fall(gravity, steps)
            local world = lurek.physics.newWorld(0, gravity)
            local body = lurek.physics.newBody(world, 0, 0, "dynamic")

            for i = 1, steps do
                lurek.physics.step(world, 1.0 / 60.0)
            end

            local x, y = body:getPosition()
            lurek.physics.destroyWorld(world)
            return x, y
        end

        -- Two identical runs
        local x1, y1 = simulate_fall(100, 60)
        local x2, y2 = simulate_fall(100, 60)

        expect_near(x1, x2, 0.0001, "x deterministic")
        expect_near(y1, y2, 0.0001, "y deterministic")
    end)

    it("horizontal velocity is deterministic", function()
        local function simulate_hvel()
            local world = lurek.physics.newWorld(0, 0) -- no gravity
            local body = lurek.physics.newBody(world, 0, 0, "dynamic")
            body:applyImpulse(10, 0)

            for i = 1, 30 do
                lurek.physics.step(world, 1.0 / 60.0)
            end

            local x, y = body:getPosition()
            lurek.physics.destroyWorld(world)
            return x, y
        end

        local x1, y1 = simulate_hvel()
        local x2, y2 = simulate_hvel()

        expect_near(x1, x2, 0.0001, "hvel x deterministic")
        expect_near(y1, y2, 0.0001, "hvel y deterministic")
    end)

    it("multi-body simulation is deterministic", function()
        local function simulate_multi()
            local world = lurek.physics.newWorld(0, 50)
            local b1 = lurek.physics.newBody(world, -5, 0, "dynamic")
            local b2 = lurek.physics.newBody(world, 5, 0, "dynamic")

            for i = 1, 120 do
                lurek.physics.step(world, 1.0 / 60.0)
            end

            local x1, y1 = b1:getPosition()
            local x2, y2 = b2:getPosition()
            lurek.physics.destroyWorld(world)
            return string.format("%.6f,%.6f,%.6f,%.6f", x1, y1, x2, y2)
        end

        local result1 = simulate_multi()
        local result2 = simulate_multi()
        expect_equal(result1, result2, "multi-body deterministic")
    end)
end)

describe("golden: physics gravity variations", function()
    it("different gravity produces different distances", function()
        local function fall_distance(gravity, steps)
            local world = lurek.physics.newWorld(0, gravity)
            local body = lurek.physics.newBody(world, 0, 0, "dynamic")

            for i = 1, steps do
                lurek.physics.step(world, 1.0 / 60.0)
            end

            local _, y = body:getPosition()
            lurek.physics.destroyWorld(world)
            return y
        end

        local y_low = fall_distance(50, 60)
        local y_high = fall_distance(200, 60)

        expect_true(y_high > y_low, "higher gravity → more distance")
    end)
end)

test_summary()
