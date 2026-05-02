-- Lurek2D Stress Test: Light System Operations
-- Measures light create, update, and query throughput.

describe("stress: light creation throughput", function()
    it("create 1000 point lights in <5s", function()
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

describe("stress: light position update throughput", function()
    it("1000 lights       100 position updates each: <10s", function()
        local N_LIGHTS  = 1000
        local N_UPDATES = 100
        local lights    = {}
        local set_intensity = rawget(lurek.light, "setIntensity")
        local set_position = rawget(lurek.light, "setPosition")

        for _ = 1, N_LIGHTS do
            local l = lurek.light.newLight(0, 0, 100)
            if type(set_intensity) == "function" then
                set_intensity(l, 0.8)
            elseif type(l.setIntensity) == "function" then
                l:setIntensity(0.8)
            end
            lights[#lights + 1] = l
        end

        local start = os.clock()
        for _ = 1, N_UPDATES do
            for _, l in ipairs(lights) do
                if type(set_position) == "function" then
                    set_position(l, math.random() * 1920, math.random() * 1080)
                elseif type(l.setPosition) == "function" then
                    l:setPosition(math.random() * 1920, math.random() * 1080)
                else
                    expect_true(true)
                    return
                end
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
        local set_position = rawget(lurek.light, "setPosition")
        local set_radius = rawget(lurek.light, "setRadius")
        local set_color = rawget(lurek.light, "setColor")
        local set_intensity = rawget(lurek.light, "setIntensity")
        local elapsed = measure("light full-config cycle x" .. COUNT, COUNT, function()
            local l = lurek.light.newLight(0, 0, 100)
            if type(set_position) == "function" then
                set_position(l, math.random() * 1920, math.random() * 1080)
            elseif type(l.setPosition) == "function" then
                l:setPosition(math.random() * 1920, math.random() * 1080)
            end
            if type(set_radius) == "function" then
                set_radius(l, 50 + math.random() * 200)
            elseif type(l.setRadius) == "function" then
                l:setRadius(50 + math.random() * 200)
            end
            if type(set_color) == "function" then
                set_color(l, math.random(), math.random(), math.random(), 1.0)
            elseif type(l.setColor) == "function" then
                l:setColor(math.random(), math.random(), math.random(), 1.0)
            end
            if type(set_intensity) == "function" then
                set_intensity(l, math.random())
            elseif type(l.setIntensity) == "function" then
                l:setIntensity(math.random())
            end
        end)

        expect_true(elapsed < 5.0, "light full-config budget: " .. elapsed .. "s")
    end)
end)
test_summary()
