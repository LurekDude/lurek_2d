-- test_evidence_scene.lua
-- Evidence test: lurek.scene DepthSorter API
-- Produces: tests/output/scene/depth_sort_order.txt
--           tests/output/scene/stable_sort_order.txt
--
-- Litmus: if DepthSorter's sort logic or flush order is broken, the output
-- file will contain depths in the wrong order and all golden comparisons fail.

local OUT = "tests/output/scene/"

-- @describe Evidence: lurek.scene DepthSorter sort order
describe("Evidence: lurek.scene DepthSorter sort order", function()

    --   order, and writes the call order to a text file. If the sort is wrong the
    --   file will differ from its golden sample.
    -- @evidence file
    it("depth_sort_order.txt: items sorted ascending by depth", function()
        local ds = lurek.scene.newDepthSorter()

        local call_order = {}

        -- Add entries in reverse order so sort has work to do.
        ds:add(function() call_order[#call_order + 1] = 30 end, 30.0)
        ds:add(function() call_order[#call_order + 1] = 10 end, 10.0)
        ds:add(function() call_order[#call_order + 1] = 50 end, 50.0)
        ds:add(function() call_order[#call_order + 1] = -5 end, -5.0)
        ds:add(function() call_order[#call_order + 1] = 20 end, 20.0)

        ds:flush() -- triggers sort + invokes callbacks in depth order

        -- Write the call order as a comma-separated text file.
        local lines = {}
        for _, v in ipairs(call_order) do
            lines[#lines + 1] = tostring(v)
        end
        local content = table.concat(lines, "\n") .. "\n"


        -- In-test verification: depths must be ascending in the call order.
        local prev = -math.huge
        for _, v in ipairs(call_order) do
            expect_true(v >= prev, "depth sort order violated: got " .. v .. " after " .. prev)
            prev = v
        end
        expect_equal(#call_order, 5)
    end)

    --   and flushes. Stable mode must preserve insertion order for equal depths.
    -- @evidence file
    it("stable_sort_order.txt: equal depths preserve insertion order", function()
        local ds = lurek.scene.newDepthSorter()
        ds:setStable(true)

        local call_order = {}

        -- Three items at the same depth â€” insertion order must be preserved.
        ds:add(function() call_order[#call_order + 1] = "A" end, 5.0)
        ds:add(function() call_order[#call_order + 1] = "B" end, 5.0)
        ds:add(function() call_order[#call_order + 1] = "C" end, 5.0)

        ds:flush()

        local content = table.concat(call_order, "\n") .. "\n"


        expect_equal(#call_order, 3)
        expect_equal(call_order[1], "A")
        expect_equal(call_order[2], "B")
        expect_equal(call_order[3], "C")
    end)

    -- @evidence file
    it("object entries flush in depth order", function()
        local ds = lurek.scene.newDepthSorter()

        local call_order = {}

        local obj1 = {
            depth = 2.0,
            drawSorted = function(self) call_order[#call_order + 1] = 2 end
        }
        local obj2 = {
            depth = 1.0,
            drawSorted = function(self) call_order[#call_order + 1] = 1 end
        }

        ds:addObject(obj1)
        ds:addObject(obj2)
        ds:flush()

        expect_equal(#call_order, 2)
        expect_equal(call_order[1], 1) -- depth 1.0 first
        expect_equal(call_order[2], 2) -- depth 2.0 second
        ds:clear()
    end)
end)




-- ================================================================
-- Merged from: test_evidence_scene.lua
-- ================================================================

-- test_evidence_scene.lua
-- Evidence test: lurek.scene DepthSorter API
-- Produces: tests/output/scene/depth_sort_order.txt
--           tests/output/scene/stable_sort_order.txt
--
-- Litmus: if DepthSorter's sort logic or flush order is broken, the output
-- file will contain depths in the wrong order and all golden comparisons fail.

local OUT = "tests/output/scene/"

-- @describe Evidence: lurek.scene DepthSorter sort order
describe("Evidence: lurek.scene DepthSorter sort order", function()

    --   order, and writes the call order to a text file. If the sort is wrong the
    --   file will differ from its golden sample.
    -- @evidence file
    it("depth_sort_order.txt: items sorted ascending by depth", function()
        local ds = lurek.scene.newDepthSorter()

        local call_order = {}

        -- Add entries in reverse order so sort has work to do.
        ds:add(function() call_order[#call_order + 1] = 30 end, 30.0)
        ds:add(function() call_order[#call_order + 1] = 10 end, 10.0)
        ds:add(function() call_order[#call_order + 1] = 50 end, 50.0)
        ds:add(function() call_order[#call_order + 1] = -5 end, -5.0)
        ds:add(function() call_order[#call_order + 1] = 20 end, 20.0)

        ds:flush() -- triggers sort + invokes callbacks in depth order

        -- Write the call order as a comma-separated text file.
        local lines = {}
        for _, v in ipairs(call_order) do
            lines[#lines + 1] = tostring(v)
        end
        local content = table.concat(lines, "\n") .. "\n"


        -- In-test verification: depths must be ascending in the call order.
        local prev = -math.huge
        for _, v in ipairs(call_order) do
            expect_true(v >= prev, "depth sort order violated: got " .. v .. " after " .. prev)
            prev = v
        end
        expect_equal(#call_order, 5)
    end)

    --   and flushes. Stable mode must preserve insertion order for equal depths.
    -- @evidence file
    it("stable_sort_order.txt: equal depths preserve insertion order", function()
        local ds = lurek.scene.newDepthSorter()
        ds:setStable(true)

        local call_order = {}

        -- Three items at the same depth â€” insertion order must be preserved.
        ds:add(function() call_order[#call_order + 1] = "A" end, 5.0)
        ds:add(function() call_order[#call_order + 1] = "B" end, 5.0)
        ds:add(function() call_order[#call_order + 1] = "C" end, 5.0)

        ds:flush()

        local content = table.concat(call_order, "\n") .. "\n"


        expect_equal(#call_order, 3)
        expect_equal(call_order[1], "A")
        expect_equal(call_order[2], "B")
        expect_equal(call_order[3], "C")
    end)

    -- @evidence file
    it("object entries flush in depth order", function()
        local ds = lurek.scene.newDepthSorter()

        local call_order = {}

        local obj1 = {
            depth = 2.0,
            drawSorted = function(self) call_order[#call_order + 1] = 2 end
        }
        local obj2 = {
            depth = 1.0,
            drawSorted = function(self) call_order[#call_order + 1] = 1 end
        }

        ds:addObject(obj1)
        ds:addObject(obj2)
        ds:flush()

        expect_equal(#call_order, 2)
        expect_equal(call_order[1], 1) -- depth 1.0 first
        expect_equal(call_order[2], 2) -- depth 2.0 second
        ds:clear()
    end)
end)
test_summary()
