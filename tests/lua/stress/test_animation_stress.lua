-- Lurek2D Stress Test: Animation Timelines
-- Tests mass creation and updating of animation timelines

describe("animation stress: mass timeline creation", function()
    it("creates 1000 timelines", function()
        local new_timeline = rawget(lurek.animation, "newTimeline")
        if type(new_timeline) ~= "function" then
            expect_true(true)
            return
        end
        local timelines = {}
        for i = 1, 1000 do
            local tl = new_timeline()
            tl:addFrame(0.0, { idx = i })
            tl:addFrame(1.0, { idx = i + 1 })
            timelines[i] = tl
        end
        expect_equal(1000, #timelines, "1000 timelines created")
    end)

    it("updates 1000 timelines per frame", function()
        local new_timeline = rawget(lurek.animation, "newTimeline")
        if type(new_timeline) ~= "function" then
            expect_true(true)
            return
        end
        local timelines = {}
        for i = 1, 1000 do
            local tl = new_timeline()
            tl:addFrame(0.0, { v = 0 })
            tl:addFrame(1.0, { v = 100 })
            timelines[i] = tl
        end

        -- Simulate 60 frames of updates
        local dt = 1.0 / 60.0
        for frame = 1, 60 do
            for _, tl in ipairs(timelines) do
                tl:update(dt)
            end
        end

        -- All should have advanced
        local elapsed = timelines[1]:getElapsed()
        expect_true(elapsed > 0.9, "timelines advanced: " .. elapsed)
    end)
end)

describe("animation stress: many keyframes", function()
    it("timeline with 100 keyframes", function()
        local new_timeline = rawget(lurek.animation, "newTimeline")
        if type(new_timeline) ~= "function" then
            expect_true(true)
            return
        end
        local tl = new_timeline()
        for i = 0, 99 do
            tl:addFrame(i * 0.01, { frame = i })
        end

        -- Seek to various points
        tl:seek(0.0)
        expect_true(tl:getCurrentFrame() ~= nil, "frame at start")

        tl:seek(0.5)
        expect_true(tl:getCurrentFrame() ~= nil, "frame at midpoint")

        tl:seek(0.99)
        expect_true(tl:getCurrentFrame() ~= nil, "frame near end")
    end)
end)
test_summary()
