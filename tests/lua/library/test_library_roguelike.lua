-- tests/lua/library/test_library_roguelike.lua
-- BDD tests for library/roguelike/init.lua     FOV, scheduler, goal map.

local rl = require("library.roguelike")


describe("Fov", function()
    local function open_blocker(_, _) return false end

    it("origin cell is always visible", function()
        local fov = rl.newFov({range=5}):setBlocker(open_blocker):compute(0, 0)
        expect_true(fov:isVisible(0, 0))
    end)

    it("respects blocker     wall hides cells behind it", function()
        -- Vertical wall at x=2 between origin and target (3,0).
        local function blk(x, _) return x == 2 end
        local fov = rl.newFov({range=8}):setBlocker(blk):compute(0, 0)
        expect_true(fov:isVisible(0, 0))
        expect_true(fov:isVisible(1, 0))
        -- Wall itself is visible (light_walls default true)
        expect_true(fov:isVisible(2, 0))
        -- (3,0) and beyond hidden
        expect_false(fov:isVisible(3, 0))
        expect_false(fov:isVisible(4, 0))
    end)

    it("explored set persists after recompute from a new origin", function()
        local fov = rl.newFov({range=3}):setBlocker(open_blocker):compute(0, 0)
        expect_true(fov:isExplored(2, 0))
        fov:compute(20, 20)
        expect_true(fov:isExplored(2, 0))   -- still remembered
        expect_false(fov:isVisible(2, 0))   -- no longer in current view
    end)

    it("resetExplored clears the persistent set", function()
        local fov = rl.newFov({range=3}):setBlocker(open_blocker):compute(0, 0)
        fov:resetExplored()
        expect_false(fov:isExplored(2, 0))
    end)
end)

describe("Scheduler", function()
    it("faster actor acts more often over many turns", function()
        local sch = rl.newScheduler()
        local fast = { id = "fast" }
        local slow = { id = "slow" }
        sch:add(fast, 20)
        sch:add(slow, 10)
        local fast_count, slow_count = 0, 0
        for _ = 1, 600 do
            local a = sch:next()
            if a == fast then fast_count = fast_count + 1
            else              slow_count = slow_count + 1 end
        end
        -- speed ratio 2:1     roughly 400/200
        expect_in_range(fast_count / 600, 0.55, 0.75)
        expect_in_range(slow_count / 600, 0.25, 0.45)
    end)

    it("remove(actor) prevents future picks", function()
        local sch = rl.newScheduler()
        local a, b = {}, {}
        sch:add(a, 10); sch:add(b, 10)
        sch:remove(a)
        for _ = 1, 5 do
            expect_equal(b, sch:next())
        end
    end)

    it("save / restore round-trips actor energies", function()
        local sch = rl.newScheduler()
        local a = {}; sch:add(a, 25)
        sch:next(); sch:next()  -- advance state
        local blob = sch:save()
        local sch2 = rl.newScheduler()
        sch2:add(a, 25)
        sch2:restore(blob)
        expect_equal(blob.actors[1].speed, 25)
        expect_not_nil(blob.clock)
    end)

    it("add raises on non-positive speed", function()
        local sch = rl.newScheduler()
        expect_error(function() sch:add({}, 0) end)
        expect_error(function() sch:add({}, -1) end)
    end)
end)

describe("GoalMap", function()
    it("gradient points toward nearest source", function()
        local g = rl.newGoalMap(10, 10)
            :setSources({ { 5, 5, 0 } })
            :bake()
        local dx, dy = g:gradientAt(2, 5)
        expect_equal(1, dx)
        expect_equal(0, dy)
    end)

    it("distance increases with hop count", function()
        local g = rl.newGoalMap(10, 10):setSources({{5,5,0}}):bake()
        expect_equal(0, g:distanceAt(5, 5))
        expect_equal(1, g:distanceAt(5, 6))
        expect_equal(3, g:distanceAt(5, 8))
    end)

    it("flee inversion produces a step away from threat", function()
        local g = rl.newGoalMap(10, 10):setSources({{5,5,0}}):bake()
        local dx, dy = g:flee(4, 5, 1.5)
        -- moving away from (5,5) means decreasing x or stepping off-axis
        expect_true(dx ~= 1 or dy ~= 0,
            "flee should not step toward the source")
    end)

    it("bake without sources raises descriptive error", function()
        local g = rl.newGoalMap(5, 5)
        expect_error(function() g:bake() end)
    end)
end)

describe("module helpers", function()
    it("bresenham produces continuous endpoints", function()
        local pts = rl.bresenham(0, 0, 3, 2)
        expect_equal(0, pts[1][1]); expect_equal(0, pts[1][2])
        local last = pts[#pts]
        expect_equal(3, last[1]); expect_equal(2, last[2])
    end)
end)
test_summary()
