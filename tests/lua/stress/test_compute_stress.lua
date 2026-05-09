-- Lurek2D Stress Test: Heavy Compute Operations
-- Tests NdArray at scale: large matrix ops, reductions, broadcasting

-- @describe compute stress: large array creation
describe("compute stress: large array creation", function()
    -- @stress LArray:getShape
    -- @stress LArray:getSize
    -- @stress lurek.compute.zeros
    it("creates and fills a 1000-element array", function()
        local arr = lurek.compute.zeros({1000}, "float32")
        local shape = arr:getShape()
        expect_equal(1, #shape, "1D array")
        expect_equal(1000, shape[1], "correct size")
        expect_equal(1000, arr:getSize(), "total elements")
    end)

    -- @stress LArray:getSize
    -- @stress LArray:sum
    -- @stress lurek.compute.ones
    it("creates a 100x100 matrix", function()
        local arr = lurek.compute.ones({100, 100}, "float32")
        expect_equal(10000, arr:getSize(), "100x100 = 10000 elements")

        -- Verify all ones
        local sum = arr:sum()
        expect_near(10000, sum, 0.1, "sum of ones = 10000")
    end)

    -- @stress LArray:getSize
    -- @stress lurek.compute.range
    it("range creates large sequence", function()
        local arr = lurek.compute.range(0, 5000, 1, "float32")
        expect_equal(5000, arr:getSize(), "5000 element range")
    end)
end)

-- @describe compute stress: element-wise operations
describe("compute stress: element-wise operations", function()
    -- @stress LArray:add
    -- @stress lurek.compute.ones
    it("adds two 10000-element arrays", function()
        local a = lurek.compute.ones({10000}, "float32")
        local b = lurek.compute.ones({10000}, "float32")
        local c = a:add(b)
        expect_equal(10000, c:getSize(), "result size matches")

        -- Check sum is doubled
        local sum = c:sum()
        expect_near(20000, sum, 1.0, "1+1 summed 10000 times")
    end)

    -- @stress LArray:mul
    -- @stress lurek.compute.range
    it("multiplies large arrays element-wise", function()
        local a = lurek.compute.range(1, 1001, 1, "float32")
        local b = lurek.compute.range(1, 1001, 1, "float32")
        local c = a:mul(b)
        expect_equal(1000, c:getSize(), "result has 1000 elements")
    end)

    -- @stress LArray:add
    -- @stress LArray:mul
    -- @stress lurek.compute.ones
    it("chains multiple operations", function()
        local a = lurek.compute.ones({5000}, "float32")
        -- Chain: add        mul        sub
        local b = a:add(a)       -- 2
        local c = b:mul(b)       -- 4
        local d = c:sub(a)       -- 3
        local sum = d:sum()
        expect_near(15000, sum, 1.0, "chain ops result")
    end)
end)

-- @describe compute stress: reductions
describe("compute stress: reductions", function()
    -- @stress LArray:sum
    -- @stress lurek.compute.ones
    it("sum of large array", function()
        local arr = lurek.compute.ones({10000}, "float32")
        expect_near(10000, arr:sum(), 1.0, "sum of 10000 ones")
    end)

    -- @stress LArray:max
    -- @stress LArray:min
    -- @stress lurek.compute.range
    it("min/max of range", function()
        local arr = lurek.compute.range(1, 10001, 1, "float32")
        expect_near(1, arr:min(), 0.1, "min of range")
        expect_near(10000, arr:max(), 0.1, "max of range")
    end)

    -- @stress LArray:mean
    -- @stress lurek.compute.ones
    it("mean of uniform array", function()
        local arr = lurek.compute.ones({5000}, "float32")
        local mean = arr:mean()
        expect_near(1.0, mean, 0.001, "mean of ones")
    end)

    -- @stress LArray:getSize
    -- @stress LArray:sum
    -- @stress lurek.compute.range
    it("sum of 20000-element arithmetic sequence", function()
        local arr = lurek.compute.range(1, 20001, 1, "float32")
        expect_equal(20000, arr:getSize(), "range size matches")

        local sum = arr:sum()
        local expected = (20000 * 20001) / 2
        expect_near(expected, sum, expected * 0.001, "arithmetic sum is stable at scale")
    end)
end)
test_summary()
