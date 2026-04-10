-- Lurek2D Stress Test: Light System Operations
-- Measures light create, update, and query throughput.
-- @stress lurek.light.newLight
-- @stress lurek.light.setPosition
-- @stress lurek.light.setIntensity

describe("stress: light creation throughput", function()
    it("create 1000 point lights in <5s", function()
        local COUNT  = 1000
        local lights = {}

        local elapsed = measure("light.newLight x" .. COUNT, COUNT, function()
            local l = lurek.light.newLight("point")
            lights[#lights + 1] = l
        end)

        expect_true(elapsed < 5.0, "light creation budget: " .. elapsed .. "s")
        expect_equal(COUNT, #lights, "all lights created")
    end)
end)

describe("stress: light position update throughput", function()
    it("1000 lights × 100 position updates each: <10s", function()
        local N_LIGHTS  = 1000
        local N_UPDATES = 100
        local lights    = {}

        for _ = 1, N_LIGHTS do
            local l = lurek.light.newLight("point")
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

describe("stress: mixed light operations", function()
    it("1000 create + setPosition + setRadius + setColor cycles: <5s", function()
        local COUNT   = 1000
        local elapsed = measure("light full-config cycle x" .. COUNT, COUNT, function()
            local l = lurek.light.newLight("point")
            lurek.light.setPosition(l, math.random() * 1920, math.random() * 1080)
            lurek.light.setRadius(l, 50 + math.random() * 200)
            lurek.light.setColor(l, math.random(), math.random(), math.random(), 1.0)
            lurek.light.setIntensity(l, math.random())
        end)

        expect_true(elapsed < 5.0, "light full-config budget: " .. elapsed .. "s")
    end)
end)

test_summary()
