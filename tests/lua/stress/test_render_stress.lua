-- Lurek2D Stress Test: Graphics Draw Commands
-- Tests throughput of draw command generation (headless, no GPU)

describe("graphics stress: shape throughput", function()
    it("10000 rectangles do not error", function()
        for i = 1, 10000 do
            lurek.render.rectangle("fill", i % 800, i % 600, 10, 10)
        end
        expect_true(true, "10000 rectangles queued")
    end)

    it("10000 circles do not error", function()
        for i = 1, 10000 do
            lurek.render.circle("fill", i % 800, i % 600, 5)
        end
        expect_true(true, "10000 circles queued")
    end)

    it("10000 lines do not error", function()
        for i = 1, 10000 do
            lurek.render.line(0, 0, i % 800, i % 600)
        end
        expect_true(true, "10000 lines queued")
    end)

    it("rapid color changes do not error", function()
        for i = 1, 10000 do
            local r = (i % 256) / 255
            local g = ((i * 7) % 256) / 255
            local b = ((i * 13) % 256) / 255
            lurek.render.setColor(r, g, b, 1.0)
        end
        expect_true(true, "10000 color changes")
    end)
end)

describe("graphics stress: mixed draw commands", function()
    it("alternating shapes at 5000 iterations", function()
        for i = 1, 5000 do
            if i % 3 == 0 then
                lurek.render.rectangle("fill", i % 400, i % 300, 8, 8)
            elseif i % 3 == 1 then
                lurek.render.circle("line", i % 400, i % 300, 4)
            else
                lurek.render.line(i % 400, i % 300, i % 400 + 10, i % 300 + 10)
            end
        end
        expect_true(true, "5000 mixed draw commands")
    end)
end)
test_summary()
