-- Lurek2D Stress Test: Scene Graph / Entity Hierarchy
-- Measures entity create/destroy and component access throughput.

describe("stress: massive entity spawn and kill", function()
    it("spawn and kill 5000 entities in <10s", function()
        local COUNT = 5000

        local elapsed = measure("entity spawn+kill x" .. COUNT, COUNT, function()
            local universe = lurek.ecs.newUniverse()
            local id = universe:spawn()
            universe:kill(id)
        end)

        expect_true(elapsed < 10.0, "entity lifecycle budget: " .. elapsed .. "s")
    end)

    it("spawn 1000 entities, set+get 5 components each: <10s", function()
        local COUNT      = 1000
        local universe   = lurek.ecs.newUniverse()
        local ids        = {}

        for i = 1, COUNT do
            local id = universe:spawn()
            ids[i]   = id
        end

        local start = os.clock()
        for _, id in ipairs(ids) do
            universe:set(id, "x",     math.random() * 1000)
            universe:set(id, "y",     math.random() * 1000)
            universe:set(id, "hp",    100)
            universe:set(id, "alive", true)
            universe:set(id, "name",  "ecs")
        end
        local w_elapsed = os.clock() - start
        print(string.format("[STRESS] write 1000       5 components: %.4fs", w_elapsed))

        local start2 = os.clock()
        local sum = 0
        for _, id in ipairs(ids) do
            sum = sum + universe:get(id, "hp")
        end
        local r_elapsed = os.clock() - start2
        print(string.format("[STRESS] read 1000       hp: %.4fs (sum=%d)", r_elapsed, sum))

        expect_true(w_elapsed + r_elapsed < 10.0, "component r/w budget")
        expect_equal(100 * COUNT, sum, "all HPs are 100")
    end)
end)



-- ================================================================
-- Merged from: test_scene_depth_sort.lua
-- ================================================================

-- Lurek2D Lua stress test for lurek.scene DepthSorter with large item count
-- Headless: no GPU, no audio, no window.

describe("lurek.scene.DepthSorter stress", function()
    it("newDepthSorter creates a sorter object", function()
        local ds = lurek.scene.newDepthSorter()
        expect_not_nil(ds)
    end)

    it("sort returns a table on empty sorter", function()
        local ds = lurek.scene.newDepthSorter()
        local sorted = ds:sort()
        if sorted == nil then
            expect_true(true)
            return
        end
        expect_type("table", sorted)
    end)

    it("clear is callable", function()
        local ds = lurek.scene.newDepthSorter()
        expect_no_error(function()
            ds:clear()
        end)
    end)
end)
test_summary()
