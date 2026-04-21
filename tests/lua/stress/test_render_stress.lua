-- Lurek2D Stress Test: Graphics Draw Commands
-- Tests throughput of draw command generation (headless, no GPU)

-- @description Covers suite: graphics stress: shape throughput.
describe("graphics stress: shape throughput", function()
    -- @covers lurek.render.rectangle
    -- @stress Queues 10000 filled rectangle draw commands in one loop.
    -- @description Stresses draw-command generation throughput by issuing a large batch of rectangle primitives without any rendering or readback.
    it("10000 rectangles do not error", function()
        for i = 1, 10000 do
            lurek.render.rectangle("fill", i % 800, i % 600, 10, 10)
        end
        expect_true(true, "10000 rectangles queued")
    end)

    -- @covers lurek.render.circle
    -- @stress Queues 10000 filled circle draw commands in one loop.
    -- @description Stresses primitive command emission by repeatedly enqueueing circle draws with changing positions.
    it("10000 circles do not error", function()
        for i = 1, 10000 do
            lurek.render.circle("fill", i % 800, i % 600, 5)
        end
        expect_true(true, "10000 circles queued")
    end)

    -- @covers lurek.render.line
    -- @stress Queues 10000 line draw commands in one loop.
    -- @description Stresses line-command generation by issuing a large batch of simple segment draws with varying endpoints.
    it("10000 lines do not error", function()
        for i = 1, 10000 do
            lurek.render.line(0, 0, i % 800, i % 600)
        end
        expect_true(true, "10000 lines queued")
    end)

    -- @covers lurek.render.setColor
    -- @stress Performs 10000 consecutive color-state changes.
    -- @description Stresses render-state mutation throughput by updating the active draw color with rapidly changing channel values in a tight loop.
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

-- @description Covers suite: graphics stress: mixed draw commands.
describe("graphics stress: mixed draw commands", function()
    -- @covers lurek.render.rectangle
    -- @covers lurek.render.circle
    -- @covers lurek.render.line
    -- @stress Alternates among three primitive types for 5000 iterations.
    -- @description Stresses mixed command dispatch by switching primitive kinds every iteration while keeping all work on the headless draw-command path.
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
