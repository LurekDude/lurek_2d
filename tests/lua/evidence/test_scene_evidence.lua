-- test_evidence_scene.lua
-- Evidence test: lurek.scene DepthSorter API
-- Produces: tests/output/scene/depth_sort_order.txt
--           tests/output/scene/stable_sort_order.txt
--
-- Litmus: if DepthSorter's sort logic or flush order is broken, the output
-- file will contain depths in the wrong order and all golden comparisons fail.

local OUT = "tests/output/scene/"

-- @description Evidence suite: lurek.scene DepthSorter produces correct sort order.
describe("Evidence: lurek.scene DepthSorter sort order", function()

    -- @covers lurek.scene.newDepthSorter
    -- @covers lurek.scene.DepthSorter:add
    -- @covers lurek.scene.DepthSorter:flush
    -- @covers lurek.scene.DepthSorter:getCount
    -- @evidence file
    -- @description Creates a DepthSorter, adds items at known depths, flushes in
    --   order, and writes the call order to a text file. If the sort is wrong the
    --   file will differ from its golden sample.
    xit("depth_sort_order.txt: items sorted ascending by depth", function()
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

        lurek.filesystem.mkdir(OUT)
        lurek.filesystem.write(OUT .. "depth_sort_order.txt", content)

        -- In-test verification: depths must be ascending in the call order.
        local prev = -math.huge
        for _, v in ipairs(call_order) do
            expect_true(v >= prev, "depth sort order violated: got " .. v .. " after " .. prev)
            prev = v
        end
        expect_equal(#call_order, 5)
    end)

    -- @covers lurek.scene.DepthSorter:setStable
    -- @covers lurek.scene.DepthSorter:flush
    -- @evidence file
    -- @description Creates a DepthSorter in stable mode, adds equal-depth items,
    --   and flushes. Stable mode must preserve insertion order for equal depths.
    xit("stable_sort_order.txt: equal depths preserve insertion order", function()
        local ds = lurek.scene.newDepthSorter()
        ds:setStable(true)

        local call_order = {}

        -- Three items at the same depth â€” insertion order must be preserved.
        ds:add(function() call_order[#call_order + 1] = "A" end, 5.0)
        ds:add(function() call_order[#call_order + 1] = "B" end, 5.0)
        ds:add(function() call_order[#call_order + 1] = "C" end, 5.0)

        ds:flush()

        local content = table.concat(call_order, "\n") .. "\n"

        lurek.filesystem.mkdir(OUT)
        lurek.filesystem.write(OUT .. "stable_sort_order.txt", content)

        expect_equal(#call_order, 3)
        expect_equal(call_order[1], "A")
        expect_equal(call_order[2], "B")
        expect_equal(call_order[3], "C")
    end)

    -- @covers lurek.scene.newDepthSorter
    -- @covers lurek.scene.DepthSorter:addObject
    -- @covers lurek.scene.DepthSorter:flush
    -- @evidence file
    -- @description Adds objects via addObject, confirms they flush in depth order.
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

-- @description Evidence suite: lurek.scene DepthSorter produces correct sort order.
describe("Evidence: lurek.scene DepthSorter sort order", function()

    -- @covers lurek.scene.newDepthSorter
    -- @covers lurek.scene.DepthSorter:add
    -- @covers lurek.scene.DepthSorter:flush
    -- @covers lurek.scene.DepthSorter:getCount
    -- @evidence file
    -- @description Creates a DepthSorter, adds items at known depths, flushes in
    --   order, and writes the call order to a text file. If the sort is wrong the
    --   file will differ from its golden sample.
    xit("depth_sort_order.txt: items sorted ascending by depth", function()
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

        lurek.filesystem.mkdir(OUT)
        local f = io.open(lurek.filesystem.toAbsolutePath(OUT .. "depth_sort_order.txt"), "w")
        if f then
            f:write(content)
            f:close()
        end

        -- In-test verification: depths must be ascending in the call order.
        local prev = -math.huge
        for _, v in ipairs(call_order) do
            expect_true(v >= prev, "depth sort order violated: got " .. v .. " after " .. prev)
            prev = v
        end
        expect_equal(#call_order, 5)
    end)

    -- @covers lurek.scene.DepthSorter:setStable
    -- @covers lurek.scene.DepthSorter:flush
    -- @evidence file
    -- @description Creates a DepthSorter in stable mode, adds equal-depth items,
    --   and flushes. Stable mode must preserve insertion order for equal depths.
    xit("stable_sort_order.txt: equal depths preserve insertion order", function()
        local ds = lurek.scene.newDepthSorter()
        ds:setStable(true)

        local call_order = {}

        -- Three items at the same depth â€” insertion order must be preserved.
        ds:add(function() call_order[#call_order + 1] = "A" end, 5.0)
        ds:add(function() call_order[#call_order + 1] = "B" end, 5.0)
        ds:add(function() call_order[#call_order + 1] = "C" end, 5.0)

        ds:flush()

        local content = table.concat(call_order, "\n") .. "\n"

        lurek.filesystem.mkdir(OUT)
        local f = io.open(lurek.filesystem.toAbsolutePath(OUT .. "stable_sort_order.txt"), "w")
        if f then
            f:write(content)
            f:close()
        end

        expect_equal(#call_order, 3)
        expect_equal(call_order[1], "A")
        expect_equal(call_order[2], "B")
        expect_equal(call_order[3], "C")
    end)

    -- @covers lurek.scene.newDepthSorter
    -- @covers lurek.scene.DepthSorter:addObject
    -- @covers lurek.scene.DepthSorter:flush
    -- @evidence file
    -- @description Adds objects via addObject, confirms they flush in depth order.
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
