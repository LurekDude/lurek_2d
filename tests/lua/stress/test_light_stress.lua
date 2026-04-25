-- Lurek2D Stress Test: Light System Operations
-- Measures light create, update, and query throughput.

-- @description Covers suite: stress: light creation throughput.
describe("stress: light creation throughput", function()
    -- @covers lurek.light.newLight
    -- @stress Allocates 1000 point lights in one measured creation loop.
    -- @description Stresses light-object construction throughput by repeatedly creating point lights and storing them in a Lua array.
    xit("create 1000 point lights in <5s", function()
        local COUNT  = 1000
        local lights = {}

        local elapsed = measure("light.newLight x" .. COUNT, COUNT, function()
            local l = lurek.light.newLight(0, 0, 100)
            lights[#lights + 1] = l
        end)

        expect_true(elapsed < 5.0, "light creation budget: " .. elapsed .. "s")
        expect_equal(COUNT, #lights, "all lights created")
    end)
end)

-- @description Covers suite: stress: light position update throughput.
describe("stress: light position update throughput", function()
    -- @covers lurek.light.newLight
    -- @covers lurek.light.setIntensity
    -- @covers lurek.light.setPosition
    -- @stress Builds 1000 lights, presets intensity once, then performs 100 position-update passes across the full set.
    -- @description Stresses bulk positional mutation by iterating over a large light pool and rewriting coordinates with randomized values in nested loops.
    xit("1000 lights       100 position updates each: <10s", function()
        local N_LIGHTS  = 1000
        local N_UPDATES = 100
        local lights    = {}

        for _ = 1, N_LIGHTS do
            local l = lurek.light.newLight(0, 0, 100)
            lurek.light.setIntensity(l, 0.8)
            lights[#lights + 1] = l
        end

        local start = os.clock()
        for _ = 1, N_UPDATES do
            for _, l in ipairs(lights) do
                lurek.light.setPosition(l,
                    math.random() * 1920,
                    math.random() * 1080)
            end
        end
        local elapsed = os.clock() - start
        local ops     = N_LIGHTS * N_UPDATES
        print(string.format("[STRESS] %d light.setPosition calls in %.4fs (%.0f/sec)",
            ops, elapsed, ops / elapsed))

        expect_true(elapsed < 10.0, "light update budget: " .. elapsed .. "s")
    end)
end)

-- @description Covers suite: stress: mixed light operations.
describe("stress: mixed light operations", function()
    -- @covers lurek.light.newLight
    -- @covers lurek.light.setPosition
    -- @covers lurek.light.setRadius
    -- @covers lurek.light.setColor
    -- @covers lurek.light.setIntensity
    -- @stress Runs 1000 full create-and-configure cycles covering position, radius, color, and intensity.
    -- @description Stresses mixed light setup throughput by constructing a new point light every iteration and mutating all major runtime properties before discarding it.
    xit("1000 create + setPosition + setRadius + setColor cycles: <5s", function()
        local COUNT   = 1000
        local elapsed = measure("light full-config cycle x" .. COUNT, COUNT, function()
            local l = lurek.light.newLight(0, 0, 100)
            lurek.light.setPosition(l, math.random() * 1920, math.random() * 1080)
            lurek.light.setRadius(l, 50 + math.random() * 200)
            lurek.light.setColor(l, math.random(), math.random(), math.random(), 1.0)
            lurek.light.setIntensity(l, math.random())
        end)

        expect_true(elapsed < 5.0, "light full-config budget: " .. elapsed .. "s")
    end)
end)

test_summary()
