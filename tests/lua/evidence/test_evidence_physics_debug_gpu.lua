-- test_evidence_physics_debug_gpu.lua
-- Evidence test: lurek.physics.drawDebugGpu queues a GPU physics debug render command.

-- @description Covers suite: Evidence: lurek.physics.drawDebugGpu.
describe("Evidence: lurek.physics.drawDebugGpu", function()

    -- @covers lurek.physics.drawDebugGpu
    it("drawDebugGpu: does not throw on empty world", function()
        local world = lurek.physics.newWorld()
        -- Should not throw — empty world produces zero shapes
        local ok, err = pcall(function()
            lurek.physics.drawDebugGpu(world)
        end)
        expect_equal(ok, true)
    end)

    -- @covers lurek.physics.drawDebugGpu
    it("drawDebugGpu: does not throw on world with dynamic body", function()
        local world = lurek.physics.newWorld()
        lurek.physics.addBody(world, {
            x = 100, y = 200,
            width = 40, height = 30,
            type = "dynamic"
        })
        local ok, err = pcall(function()
            lurek.physics.drawDebugGpu(world)
        end)
        expect_equal(ok, true)
    end)

    -- @covers lurek.physics.drawDebugGpu
    it("drawDebugGpu: does not throw on world with static body", function()
        local world = lurek.physics.newWorld()
        lurek.physics.addBody(world, {
            x = 300, y = 400,
            width = 200, height = 20,
            type = "static"
        })
        local ok, err = pcall(function()
            lurek.physics.drawDebugGpu(world)
        end)
        expect_equal(ok, true)
    end)

    -- @covers lurek.physics.drawDebugGpu
    it("drawDebugGpu: accepts optional config table", function()
        local world = lurek.physics.newWorld()
        lurek.physics.addBody(world, {x = 50, y = 50, width = 20, height = 20, type = "dynamic"})
        local ok, err = pcall(function()
            lurek.physics.drawDebugGpu(world, {
                bodyColor   = {0.0, 1.0, 0.0, 1.0},
                staticColor = {0.5, 0.5, 0.5, 1.0},
                sleepColor  = {0.0, 0.3, 0.0, 1.0},
                sensorColor = {0.0, 1.0, 1.0, 0.8},
                lineWidth   = 2.0,
            })
        end)
        expect_equal(ok, true)
    end)

    -- @covers lurek.physics.drawDebugGpu
    it("drawDebugGpu: accepts nil as config (uses defaults)", function()
        local world = lurek.physics.newWorld()
        local ok, err = pcall(function()
            lurek.physics.drawDebugGpu(world, nil)
        end)
        expect_equal(ok, true)
    end)

    -- @covers lurek.physics.drawDebugGpu
    it("drawDebugGpu: multiple bodies drawn without error", function()
        local world = lurek.physics.newWorld()
        for i = 1, 10 do
            lurek.physics.addBody(world, {
                x = i * 30, y = 100,
                width = 20, height = 20,
                type = (i % 3 == 0) and "static" or "dynamic"
            })
        end
        local ok, err = pcall(function()
            lurek.physics.drawDebugGpu(world)
        end)
        expect_equal(ok, true)
    end)

end)
test_summary()
