-- Lurek2D Stress Test: Math Operations
-- Performs thousands of math operations to test throughput

describe("math stress: trigonometry throughput", function()
    it("10000 sin/cos pairs", function()
        local sum = 0
        for i = 1, 10000 do
            local angle = i * 0.001
            sum = sum + lurek.math.sin(angle) + lurek.math.cos(angle)
        end
        expect_true(type(sum) == "number", "computed 10000 sin+cos pairs")
    end)

    it("10000 atan2 calls", function()
        local sum = 0
        for i = 1, 10000 do
            sum = sum + lurek.math.atan2(i, i + 1)
        end
        expect_true(type(sum) == "number", "computed 10000 atan2 calls")
    end)

    it("10000 sqrt calls", function()
        local sum = 0
        for i = 1, 10000 do
            sum = sum + lurek.math.sqrt(i)
        end
        expect_true(sum > 0, "computed 10000 sqrt calls")
    end)
end)

describe("math stress: random number generation", function()
    it("10000 random numbers", function()
        local count = 0
        for i = 1, 10000 do
            local r = lurek.math.random()
            if r >= 0 and r <= 1 then
                count = count + 1
            end
        end
        expect_equal(10000, count, "all random numbers in [0,1]")
    end)

    it("random integer range", function()
        local min_seen = 100
        local max_seen = 0

        for i = 1, 10000 do
            local r = lurek.math.random(1, 10)
            if r < min_seen then min_seen = r end
            if r > max_seen then max_seen = r end
        end

        expect_equal(1, min_seen, "minimum seen")
        expect_equal(10, max_seen, "maximum seen")
    end)
end)

describe("math stress: vector operations", function()
    it("10000 distance calculations", function()
        local sum = 0
        for i = 1, 10000 do
            local x1, y1 = i, i * 2
            local x2, y2 = i + 1, i * 2 + 1
            sum = sum + lurek.math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
        end
        expect_true(sum > 0, "computed 10000 distances")
    end)

    it("10000 normalize operations", function()
        local count = 0
        for i = 1, 10000 do
            local x, y = i, i * 2
            local len = lurek.math.sqrt(x * x + y * y)
            if len > 0 then
                local nx, ny = x / len, y / len
                local check_len = lurek.math.sqrt(nx * nx + ny * ny)
                if lurek.math.abs(check_len - 1.0) < 0.001 then
                    count = count + 1
                end
            end
        end
        expect_equal(10000, count, "all vectors normalized correctly")
    end)
end)
