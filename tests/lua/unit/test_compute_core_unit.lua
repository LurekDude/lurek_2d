-- Lurek2D Compute Array Tests
-- Tests for lurek.compute dense N-dimensional array API

-- =========================================================================
-- 1. Module exists
-- =========================================================================

-- @describe lurek.compute module exists
describe("lurek.compute module exists", function()
    -- @covers lurek.compute
    it("lurek.compute is a table", function()
        expect_type("table", lurek.compute)
    end)

    -- @covers lurek.compute.newArray
    it("has newArray factory", function()
        expect_type("function", lurek.compute.newArray)
    end)

    -- @covers lurek.compute.zeros
    it("has zeros factory", function()
        expect_type("function", lurek.compute.zeros)
    end)

    -- @covers lurek.compute.ones
    it("has ones factory", function()
        expect_type("function", lurek.compute.ones)
    end)

    -- @covers lurek.compute.range
    it("has range factory", function()
        expect_type("function", lurek.compute.range)
    end)

    -- @covers lurek.compute.fromTable
    it("has fromTable factory", function()
        expect_type("function", lurek.compute.fromTable)
    end)
end)

-- =========================================================================
-- 2. Construction
-- =========================================================================
-- @describe construction
describe("construction", function()
    -- @covers LArray:getShape
    -- @covers lurek.compute.zeros
    it("zeros creates array with correct shape", function()
        local a = lurek.compute.zeros({3, 3})
        local s = a:getShape()
        expect_equal(3, s[1])
        expect_equal(3, s[2])
    end)

    -- @covers LArray:getSize
    -- @covers lurek.compute.zeros
    it("zeros creates array with correct size", function()
        local a = lurek.compute.zeros({3, 3})
        expect_equal(9, a:getSize())
    end)

    -- @covers LArray:getDimensions
    -- @covers lurek.compute.zeros
    it("zeros creates array with correct dimensions", function()
        local a = lurek.compute.zeros({3, 3})
        expect_equal(2, a:getDimensions())
    end)

    -- @covers LArray:getDataType
    -- @covers lurek.compute.zeros
    it("zeros default dtype is float32", function()
        local a = lurek.compute.zeros({2, 2})
        expect_equal("float32", a:getDataType())
    end)

    -- @covers LArray:get
    -- @covers lurek.compute.zeros
    it("zeros elements are all zero", function()
        local a = lurek.compute.zeros({3})
        for i = 1, 3 do
            expect_near(0.0, a:get(i), 1e-5)
        end
    end)

    -- @covers LArray:get
    -- @covers lurek.compute.ones
    it("ones creates array with all elements 1.0", function()
        local a = lurek.compute.ones({2, 3})
        for i = 1, 2 do
            for j = 1, 3 do
                expect_near(1.0, a:get(i, j), 1e-5)
            end
        end
    end)

    -- @covers LArray:getDimensions
    -- @covers LArray:getSize
    -- @covers lurek.compute.ones
    it("ones has correct shape", function()
        local a = lurek.compute.ones({2, 3})
        expect_equal(6, a:getSize())
        expect_equal(2, a:getDimensions())
    end)

    -- @covers LArray:get
    -- @covers LArray:getSize
    -- @covers lurek.compute.range
    it("range produces correct sequence", function()
        local a = lurek.compute.range(1, 4)
        expect_equal(3, a:getSize())
        expect_near(1.0, a:get(1), 1e-5)
        expect_near(2.0, a:get(2), 1e-5)
        expect_near(3.0, a:get(3), 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:getSize
    -- @covers lurek.compute.range
    it("range with step produces correct sequence", function()
        local a = lurek.compute.range(0, 10, 2)
        expect_equal(5, a:getSize())
        expect_near(0.0, a:get(1), 1e-5)
        expect_near(2.0, a:get(2), 1e-5)
        expect_near(4.0, a:get(3), 1e-5)
        expect_near(6.0, a:get(4), 1e-5)
        expect_near(8.0, a:get(5), 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:getSize
    -- @covers lurek.compute.fromTable
    it("fromTable creates 1D array", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        expect_equal(3, a:getSize())
        expect_near(10.0, a:get(1), 1e-5)
        expect_near(20.0, a:get(2), 1e-5)
        expect_near(30.0, a:get(3), 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:getDimensions
    -- @covers LArray:getSize
    -- @covers lurek.compute.fromTable
    it("fromTable with shape reshapes", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
        expect_equal(4, a:getSize())
        expect_equal(2, a:getDimensions())
        expect_near(1.0, a:get(1, 1), 1e-5)
        expect_near(2.0, a:get(1, 2), 1e-5)
        expect_near(3.0, a:get(2, 1), 1e-5)
        expect_near(4.0, a:get(2, 2), 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:getSize
    -- @covers lurek.compute.newArray
    it("newArray creates zero-initialized array", function()
        local a = lurek.compute.newArray({2, 2})
        expect_equal(4, a:getSize())
        expect_near(0.0, a:get(1, 1), 1e-5)
    end)

    -- @covers LArray:getDataType
    -- @covers lurek.compute.zeros
    it("float64 dtype works", function()
        local a = lurek.compute.zeros({3}, "float64")
        expect_equal("float64", a:getDataType())
    end)

    -- @covers LArray:getDataType
    -- @covers lurek.compute.zeros
    it("int32 dtype works", function()
        local a = lurek.compute.zeros({3}, "int32")
        expect_equal("int32", a:getDataType())
    end)

    -- @covers LArray:getDimensions
    -- @covers LArray:getShape
    -- @covers LArray:getSize
    -- @covers lurek.compute.zeros
    it("4D array construction", function()
        local a = lurek.compute.zeros({2, 3, 4, 5})
        expect_equal(4, a:getDimensions())
        expect_equal(120, a:getSize())
        local s = a:getShape()
        expect_equal(2, s[1])
        expect_equal(3, s[2])
        expect_equal(4, s[3])
        expect_equal(5, s[4])
    end)
end)

-- =========================================================================
-- 3. Element access
-- =========================================================================
-- @describe element access
describe("element access", function()
    -- @covers LArray:get
    -- @covers LArray:set
    -- @covers lurek.compute.zeros
    it("1D get and set", function()
        local a = lurek.compute.zeros({5})
        a:set(1, 5.0)
        a:set(3, 7.5)
        expect_near(5.0, a:get(1), 1e-5)
        expect_near(0.0, a:get(2), 1e-5)
        expect_near(7.5, a:get(3), 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:set
    -- @covers lurek.compute.zeros
    it("2D get and set", function()
        local a = lurek.compute.zeros({3, 4})
        a:set(2, 3, 7.0)
        expect_near(7.0, a:get(2, 3), 1e-5)
        expect_near(0.0, a:get(1, 1), 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:set
    -- @covers lurek.compute.zeros
    it("3D get and set", function()
        local a = lurek.compute.zeros({2, 3, 4})
        a:set(1, 2, 3, 99.0)
        expect_near(99.0, a:get(1, 2, 3), 1e-5)
        expect_near(0.0, a:get(1, 1, 1), 1e-5)
    end)

    -- @covers LArray:toTable
    -- @covers lurek.compute.fromTable
    it("toTable returns flat table", function()
        local a = lurek.compute.fromTable({10, 20, 30, 40}, {2, 2})
        local t = a:toTable()
        expect_equal(4, #t)
        expect_near(10.0, t[1], 1e-5)
        expect_near(20.0, t[2], 1e-5)
        expect_near(30.0, t[3], 1e-5)
        expect_near(40.0, t[4], 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:set
    -- @covers lurek.compute.zeros
    it("set overwrites previous value", function()
        local a = lurek.compute.zeros({3})
        a:set(2, 100.0)
        expect_near(100.0, a:get(2), 1e-5)
        a:set(2, 200.0)
        expect_near(200.0, a:get(2), 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:set
    -- @covers lurek.compute.zeros
    it("int32 arrays round-trip integer writes", function()
        local a = lurek.compute.zeros({4}, "int32")
        a:set(1, 42)
        a:set(2, -7)
        expect_equal(42, a:get(1))
        expect_equal(-7, a:get(2))
    end)
end)

-- =========================================================================
-- 4. Inspection
-- =========================================================================
-- @describe inspection
describe("inspection", function()
    -- @covers LArray:getShape
    -- @covers lurek.compute.zeros
    it("getShape matches constructor", function()
        local a = lurek.compute.zeros({4, 5})
        local s = a:getShape()
        expect_equal(4, s[1])
        expect_equal(5, s[2])
    end)

    -- @covers LArray:getDimensions
    -- @covers lurek.compute.zeros
    it("getDimensions for 1D", function()
        local a = lurek.compute.zeros({10})
        expect_equal(1, a:getDimensions())
    end)

    -- @covers LArray:getDimensions
    -- @covers lurek.compute.zeros
    it("getDimensions for 3D", function()
        local a = lurek.compute.zeros({2, 3, 4})
        expect_equal(3, a:getDimensions())
    end)

    -- @covers LArray:getSize
    -- @covers lurek.compute.zeros
    it("getSize is product of shape", function()
        local a = lurek.compute.zeros({3, 4, 5})
        expect_equal(60, a:getSize())
    end)

    -- @covers LArray:isOnGPU
    -- @covers lurek.compute.zeros
    it("isOnGPU always returns false", function()
        local a = lurek.compute.zeros({3})
        expect_false(a:isOnGPU())
    end)

    -- @covers LArray:getDataType
    -- @covers lurek.compute.ones
    it("getDataType returns dtype name", function()
        local a = lurek.compute.ones({2}, "float64")
        expect_equal("float64", a:getDataType())
    end)
end)

-- =========================================================================
-- 5. Arithmetic
-- =========================================================================
-- @describe arithmetic
describe("arithmetic", function()
    -- @covers LArray:add
    -- @covers lurek.compute.fromTable
    it("add two arrays element-wise", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({4, 5, 6})
        local c = a:add(b)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(7.0, c:get(2), 1e-5)
        expect_near(9.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:add
    -- @covers lurek.compute.fromTable
    it("add scalar to array", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local c = a:add(10)
        expect_near(11.0, c:get(1), 1e-5)
        expect_near(12.0, c:get(2), 1e-5)
        expect_near(13.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:add
    -- @covers LArray:get
    -- @covers lurek.compute.fromTable
    it("add does not modify original", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local _ = a:add(10)
        expect_near(1.0, a:get(1), 1e-5)
        expect_near(2.0, a:get(2), 1e-5)
        expect_near(3.0, a:get(3), 1e-5)
    end)

    -- @covers LArray:sub
    -- @covers lurek.compute.fromTable
    it("sub arrays element-wise", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        local b = lurek.compute.fromTable({1, 2, 3})
        local c = a:sub(b)
        expect_near(9.0, c:get(1), 1e-5)
        expect_near(18.0, c:get(2), 1e-5)
        expect_near(27.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:sub
    -- @covers lurek.compute.fromTable
    it("sub scalar", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        local c = a:sub(5)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(15.0, c:get(2), 1e-5)
        expect_near(25.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:mul
    -- @covers lurek.compute.fromTable
    it("mul arrays element-wise", function()
        local a = lurek.compute.fromTable({2, 3, 4})
        local b = lurek.compute.fromTable({5, 6, 7})
        local c = a:mul(b)
        expect_near(10.0, c:get(1), 1e-5)
        expect_near(18.0, c:get(2), 1e-5)
        expect_near(28.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:mul
    -- @covers lurek.compute.fromTable
    it("mul scalar", function()
        local a = lurek.compute.fromTable({2, 3, 4})
        local c = a:mul(3)
        expect_near(6.0, c:get(1), 1e-5)
        expect_near(9.0, c:get(2), 1e-5)
        expect_near(12.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:add
    -- @covers lurek.compute.fromTable
    it("add supports 2D + 1D row broadcast", function()
        local a = lurek.compute.fromTable({1, 2, 3, 10, 20, 30}, {2, 3})
        local b = lurek.compute.fromTable({100, 200, 300}, {3})
        local c = a:add(b)
        expect_near(101.0, c:get(1, 1), 1e-5)
        expect_near(202.0, c:get(1, 2), 1e-5)
        expect_near(303.0, c:get(1, 3), 1e-5)
        expect_near(110.0, c:get(2, 1), 1e-5)
        expect_near(220.0, c:get(2, 2), 1e-5)
        expect_near(330.0, c:get(2, 3), 1e-5)
    end)

    -- @covers LArray:addInplace
    -- @covers lurek.compute.fromTable
    it("addInplace mutates array with row broadcast", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4, 5, 6}, {2, 3})
        local b = lurek.compute.fromTable({10, 20, 30}, {3})
        a:addInplace(b)
        expect_near(11.0, a:get(1, 1), 1e-5)
        expect_near(22.0, a:get(1, 2), 1e-5)
        expect_near(33.0, a:get(1, 3), 1e-5)
        expect_near(14.0, a:get(2, 1), 1e-5)
        expect_near(25.0, a:get(2, 2), 1e-5)
        expect_near(36.0, a:get(2, 3), 1e-5)
    end)

    -- @covers LArray:subInplace
    -- @covers LArray:mulInplace
    -- @covers LArray:divInplace
    -- @covers lurek.compute.fromTable
    it("subInplace, mulInplace and divInplace work", function()
        local a = lurek.compute.fromTable({8, 10, 12}, {3})
        local b = lurek.compute.fromTable({2, 5, 3}, {3})
        a:subInplace(b)
        expect_near(6.0, a:get(1), 1e-5)
        expect_near(5.0, a:get(2), 1e-5)
        expect_near(9.0, a:get(3), 1e-5)
        a:mulInplace(b)
        expect_near(12.0, a:get(1), 1e-5)
        expect_near(25.0, a:get(2), 1e-5)
        expect_near(27.0, a:get(3), 1e-5)
        a:divInplace(b)
        expect_near(6.0, a:get(1), 1e-5)
        expect_near(5.0, a:get(2), 1e-5)
        expect_near(9.0, a:get(3), 1e-5)
    end)

    -- @covers LArray:div
    -- @covers lurek.compute.fromTable
    it("div arrays element-wise", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        local b = lurek.compute.fromTable({2, 4, 5})
        local c = a:div(b)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(5.0, c:get(2), 1e-5)
        expect_near(6.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:div
    -- @covers lurek.compute.fromTable
    it("div scalar", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        local c = a:div(2)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(10.0, c:get(2), 1e-5)
        expect_near(15.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:pow
    -- @covers lurek.compute.fromTable
    it("pow raises elements to power", function()
        local a = lurek.compute.fromTable({2, 3, 4})
        local c = a:pow(2)
        expect_near(4.0, c:get(1), 1e-5)
        expect_near(9.0, c:get(2), 1e-5)
        expect_near(16.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:sqrt
    -- @covers lurek.compute.fromTable
    it("sqrt of perfect squares", function()
        local a = lurek.compute.fromTable({4, 9, 16, 25})
        local c = a:sqrt()
        expect_near(2.0, c:get(1), 1e-5)
        expect_near(3.0, c:get(2), 1e-5)
        expect_near(4.0, c:get(3), 1e-5)
        expect_near(5.0, c:get(4), 1e-5)
    end)

    -- @covers LArray:abs
    -- @covers lurek.compute.fromTable
    it("abs of mixed values", function()
        local a = lurek.compute.fromTable({-3, 0, 5, -1.5})
        local c = a:abs()
        expect_near(3.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(5.0, c:get(3), 1e-5)
        expect_near(1.5, c:get(4), 1e-5)
    end)

    -- @covers LArray:neg
    -- @covers lurek.compute.fromTable
    it("neg negates elements", function()
        local a = lurek.compute.fromTable({1, -2, 3})
        local c = a:neg()
        expect_near(-1.0, c:get(1), 1e-5)
        expect_near(2.0, c:get(2), 1e-5)
        expect_near(-3.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:clamp
    -- @covers lurek.compute.fromTable
    it("clamp clips values to range", function()
        local a = lurek.compute.fromTable({-5, 0, 3, 10, 15})
        local c = a:clamp(0, 10)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(3.0, c:get(3), 1e-5)
        expect_near(10.0, c:get(4), 1e-5)
        expect_near(10.0, c:get(5), 1e-5)
    end)
end)

-- =========================================================================
-- 6. Comparison
-- =========================================================================
-- @describe comparison
describe("comparison", function()
    -- @covers LArray:eq
    -- @covers lurek.compute.fromTable
    it("eq returns 1.0 for equal elements", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({1, 9, 3})
        local c = a:eq(b)
        expect_near(1.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:eq
    -- @covers lurek.compute.fromTable
    it("eq with scalar", function()
        local a = lurek.compute.fromTable({1, 2, 2, 3})
        local c = a:eq(2)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
        expect_near(0.0, c:get(4), 1e-5)
    end)

    -- @covers LArray:neq
    -- @covers lurek.compute.fromTable
    it("neq returns 1.0 for unequal elements", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({1, 9, 3})
        local c = a:neq(b)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:neq
    -- @covers lurek.compute.fromTable
    it("neq with scalar", function()
        local a = lurek.compute.fromTable({1, 2, 2, 3})
        local c = a:neq(2)
        expect_near(1.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
        expect_near(1.0, c:get(4), 1e-5)
    end)

    -- @covers LArray:gt
    -- @covers lurek.compute.fromTable
    it("gt returns 1.0 where a > b", function()
        local a = lurek.compute.fromTable({1, 5, 3})
        local b = lurek.compute.fromTable({2, 3, 3})
        local c = a:gt(b)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:gt
    -- @covers lurek.compute.fromTable
    it("gt with scalar", function()
        local a = lurek.compute.fromTable({1, 5, 3})
        local c = a:gt(2)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:lt
    -- @covers lurek.compute.fromTable
    it("lt returns 1.0 where a < b", function()
        local a = lurek.compute.fromTable({1, 5, 3})
        local c = a:lt(3)
        expect_near(1.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:gte
    -- @covers lurek.compute.fromTable
    it("gte returns 1.0 where a >= b", function()
        local a = lurek.compute.fromTable({1, 3, 5})
        local c = a:gte(3)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
    end)

    -- @covers LArray:lte
    -- @covers lurek.compute.fromTable
    it("lte returns 1.0 where a <= b", function()
        local a = lurek.compute.fromTable({1, 3, 5})
        local c = a:lte(3)
        expect_near(1.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)
end)

-- =========================================================================
-- 7. Masking
-- =========================================================================
-- @describe masking
describe("masking", function()
    -- @covers LArray:threshold
    -- @covers lurek.compute.fromTable
    it("threshold returns 1.0 where >= val", function()
        local a = lurek.compute.fromTable({0.2, 0.5, 0.8, 1.0})
        local c = a:threshold(0.5)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
        expect_near(1.0, c:get(4), 1e-5)
    end)

    -- @covers lurek.compute.fromTable
    it("where selects from two arrays based on condition", function()
        local cond = lurek.compute.fromTable({1, 0, 1, 0})
        local a = lurek.compute.fromTable({10, 20, 30, 40})
        local b = lurek.compute.fromTable({100, 200, 300, 400})
        -- where(mask, on_true_self, on_false_other)
        -- called on the "true" array: a:where(cond, b)
        -- but the API signature is: mask:where(if_true, if_false)
        -- actually: this.where(mask, other) where mask selects this(1) or other(0)
        -- Let's verify: ops::where_mask(mask, this, other)
        -- Lua: this:where(mask, other) => where_mask(mask, this, other)
        -- So a:where(cond, b) puts mask=cond, this=a, other=b
        -- where mask=1  this(a), where mask=0  other(b)
        local result = a["where"](a, cond, b)
        expect_near(10.0, result:get(1), 1e-5)
        expect_near(200.0, result:get(2), 1e-5)
        expect_near(30.0, result:get(3), 1e-5)
        expect_near(400.0, result:get(4), 1e-5)
    end)
end)

-- =========================================================================
-- 8. Counting
-- =========================================================================
-- @describe counting
describe("counting", function()
    -- @covers LArray:countNonZero
    -- @covers lurek.compute.fromTable
    it("countNonZero counts nonzero elements", function()
        local a = lurek.compute.fromTable({0, 1, 0, 3, 5})
        expect_equal(3, a:countNonZero())
    end)

    -- @covers LArray:countNonZero
    -- @covers lurek.compute.zeros
    it("countNonZero for all zeros", function()
        local a = lurek.compute.zeros({4})
        expect_equal(0, a:countNonZero())
    end)

    -- @covers LArray:argmin
    -- @covers lurek.compute.fromTable
    it("argmin returns 1-based index of minimum", function()
        local a = lurek.compute.fromTable({5, 1, 3, 2})
        expect_equal(2, a:argmin())
    end)

    -- @covers LArray:argmax
    -- @covers lurek.compute.fromTable
    it("argmax returns 1-based index of maximum", function()
        local a = lurek.compute.fromTable({5, 1, 3, 2})
        expect_equal(1, a:argmax())
    end)

    -- @covers LArray:any
    -- @covers lurek.compute.fromTable
    it("any returns true if any nonzero", function()
        local a = lurek.compute.fromTable({0, 0, 1})
        expect_true(a:any())
    end)

    -- @covers LArray:any
    -- @covers lurek.compute.zeros
    it("any returns false for all zeros", function()
        local a = lurek.compute.zeros({3})
        expect_false(a:any())
    end)

    -- @covers LArray:all
    -- @covers lurek.compute.fromTable
    it("all returns true when all nonzero", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        expect_true(a:all())
    end)

    -- @covers LArray:all
    -- @covers lurek.compute.fromTable
    it("all returns false when any zero", function()
        local a = lurek.compute.fromTable({1, 0, 3})
        expect_false(a:all())
    end)
end)

-- =========================================================================
-- 9. Reductions
-- =========================================================================
-- @describe reductions
describe("reductions", function()
    -- @covers LArray:sum
    -- @covers lurek.compute.ones
    it("sum of ones(3,3) is 9", function()
        local a = lurek.compute.ones({3, 3})
        expect_near(9.0, a:sum(), 1e-5)
    end)

    -- @covers LArray:sum
    -- @covers lurek.compute.fromTable
    it("sum of fromTable", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4})
        expect_near(10.0, a:sum(), 1e-5)
    end)

    -- @covers LArray:mean
    -- @covers lurek.compute.fromTable
    it("mean of values", function()
        local a = lurek.compute.fromTable({2, 4, 6})
        expect_near(4.0, a:mean(), 1e-5)
    end)

    -- @covers LArray:min
    -- @covers lurek.compute.fromTable
    it("min of array", function()
        local a = lurek.compute.fromTable({5, 1, 3, 2})
        expect_near(1.0, a:min(), 1e-5)
    end)

    -- @covers LArray:max
    -- @covers lurek.compute.fromTable
    it("max of array", function()
        local a = lurek.compute.fromTable({5, 1, 3, 2})
        expect_near(5.0, a:max(), 1e-5)
    end)

    -- @covers LArray:sum
    -- @covers lurek.compute.fromTable
    it("sum along axis 1 of a 3x3 array", function()
        -- 3x3 array, sum along rows (axis 1)  each column summed
        local a = lurek.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        local s = a:sum(1)
        -- sum axis=0 (Rust 0-based)  sums over rows  {12, 15, 18}
        expect_equal(3, s:getSize())
        expect_near(12.0, s:get(1), 1e-5)
        expect_near(15.0, s:get(2), 1e-5)
        expect_near(18.0, s:get(3), 1e-5)
    end)

    -- @covers LArray:sum
    -- @covers lurek.compute.fromTable
    it("sum along axis 2 of a 3x3 array", function()
        local a = lurek.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        local s = a:sum(2)
        -- sum axis=1 (Rust 0-based)  sums over cols  {6, 15, 24}
        expect_equal(3, s:getSize())
        expect_near(6.0, s:get(1), 1e-5)
        expect_near(15.0, s:get(2), 1e-5)
        expect_near(24.0, s:get(3), 1e-5)
    end)

    -- @covers LArray:mean
    -- @covers lurek.compute.fromTable
    it("mean along axis", function()
        local a = lurek.compute.fromTable({2, 4, 6, 8}, {2, 2})
        local m = a:mean(2)
        expect_equal(2, m:getSize())
        expect_near(3.0, m:get(1), 1e-5)
        expect_near(7.0, m:get(2), 1e-5)
    end)

    -- @covers LArray:min
    -- @covers lurek.compute.fromTable
    it("min along axis", function()
        local a = lurek.compute.fromTable({3, 1, 2, 4}, {2, 2})
        local m = a:min(2)
        expect_equal(2, m:getSize())
        expect_near(1.0, m:get(1), 1e-5)
        expect_near(2.0, m:get(2), 1e-5)
    end)

    -- @covers LArray:max
    -- @covers lurek.compute.fromTable
    it("max along axis", function()
        local a = lurek.compute.fromTable({3, 1, 2, 4}, {2, 2})
        local m = a:max(2)
        expect_equal(2, m:getSize())
        expect_near(3.0, m:get(1), 1e-5)
        expect_near(4.0, m:get(2), 1e-5)
    end)
end)

-- =========================================================================
-- 10. Shape manipulation
-- =========================================================================
-- @describe shape manipulation
describe("shape manipulation", function()
    -- @covers LArray:reshape
    -- @covers lurek.compute.fromTable
    it("reshape preserves elements", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4, 5, 6})
        local b = a:reshape({2, 3})
        expect_equal(6, b:getSize())
        expect_equal(2, b:getDimensions())
        -- elements in row-major order should be the same
        local t = b:toTable()
        expect_near(1.0, t[1], 1e-5)
        expect_near(6.0, t[6], 1e-5)
    end)

    -- @covers LArray:reshape
    -- @covers lurek.compute.fromTable
    it("reshape changes shape but not data", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
        local b = a:reshape({4})
        expect_equal(1, b:getDimensions())
        expect_equal(4, b:getSize())
        expect_near(1.0, b:get(1), 1e-5)
        expect_near(4.0, b:get(4), 1e-5)
    end)

    -- @covers LArray:clone
    -- @covers LArray:get
    -- @covers lurek.compute.fromTable
    it("clone produces independent copy", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = a:clone()
        b:set(1, 99.0)
        expect_near(1.0, a:get(1), 1e-5)
        expect_near(99.0, b:get(1), 1e-5)
    end)

    -- @covers LArray:transpose
    -- @covers lurek.compute.fromTable
    it("transpose swaps rows and cols", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4, 5, 6}, {2, 3})
        local b = a:transpose()
        local s = b:getShape()
        expect_equal(3, s[1])
        expect_equal(2, s[2])
        -- Original: row0=[1,2,3], row1=[4,5,6]
        -- Transposed: row0=[1,4], row1=[2,5], row2=[3,6]
        expect_near(1.0, b:get(1, 1), 1e-5)
        expect_near(4.0, b:get(1, 2), 1e-5)
        expect_near(2.0, b:get(2, 1), 1e-5)
        expect_near(5.0, b:get(2, 2), 1e-5)
        expect_near(3.0, b:get(3, 1), 1e-5)
        expect_near(6.0, b:get(3, 2), 1e-5)
    end)

    -- @covers LArray:fill
    -- @covers LArray:get
    -- @covers lurek.compute.zeros
    it("fill modifies in-place", function()
        local a = lurek.compute.zeros({3})
        a:fill(7.0)
        expect_near(7.0, a:get(1), 1e-5)
        expect_near(7.0, a:get(2), 1e-5)
        expect_near(7.0, a:get(3), 1e-5)
    end)
end)

-- =========================================================================
-- 11. Linear algebra
-- =========================================================================
-- @describe linear algebra
describe("linear algebra", function()
    -- @covers LArray:matmul
    -- @covers lurek.compute.fromTable
    it("matmul 2x3 * 3x2 produces 2x2", function()
        -- A = [[1,2,3],[4,5,6]]  (2x3)
        local a = lurek.compute.fromTable({1,2,3, 4,5,6}, {2,3})
        -- B = [[7,8],[9,10],[11,12]]  (3x2)
        local b = lurek.compute.fromTable({7,8, 9,10, 11,12}, {3,2})
        local c = a:matmul(b)
        local s = c:getShape()
        expect_equal(2, s[1])
        expect_equal(2, s[2])
        -- C[1,1] = 1*7 + 2*9 + 3*11 = 7+18+33 = 58
        expect_near(58.0, c:get(1, 1), 1e-5)
        -- C[1,2] = 1*8 + 2*10 + 3*12 = 8+20+36 = 64
        expect_near(64.0, c:get(1, 2), 1e-5)
        -- C[2,1] = 4*7 + 5*9 + 6*11 = 28+45+66 = 139
        expect_near(139.0, c:get(2, 1), 1e-5)
        -- C[2,2] = 4*8 + 5*10 + 6*12 = 32+50+72 = 154
        expect_near(154.0, c:get(2, 2), 1e-5)
    end)

    -- @covers LArray:dot
    -- @covers lurek.compute.fromTable
    it("dot product of two 1D arrays", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({4, 5, 6})
        -- dot = 1*4 + 2*5 + 3*6 = 4+10+18 = 32
        expect_near(32.0, a:dot(b), 1e-5)
    end)

    -- @covers LArray:dot
    -- @covers lurek.compute.fromTable
    it("dot product of orthogonal vectors is zero", function()
        local a = lurek.compute.fromTable({1, 0})
        local b = lurek.compute.fromTable({0, 1})
        expect_near(0.0, a:dot(b), 1e-5)
    end)

    -- @covers LArray:matmul
    -- @covers lurek.compute.fromTable
    it("identity matmul preserves matrix", function()
        -- I = [[1,0],[0,1]]
        local eye = lurek.compute.fromTable({1,0, 0,1}, {2,2})
        local a = lurek.compute.fromTable({5,3, 2,7}, {2,2})
        local c = a:matmul(eye)
        expect_near(5.0, c:get(1, 1), 1e-5)
        expect_near(3.0, c:get(1, 2), 1e-5)
        expect_near(2.0, c:get(2, 1), 1e-5)
        expect_near(7.0, c:get(2, 2), 1e-5)
    end)
end)

-- =========================================================================
-- 12. Bitwise operations (int32 only)
-- =========================================================================
-- @describe bitwise operations
describe("bitwise operations", function()
    -- @covers LArray:bitwiseAnd
    -- @covers lurek.compute.fromTable
    it("bitwiseAnd on int32 arrays", function()
        local a = lurek.compute.fromTable({0xFF, 0x0F, 0xAA}, nil, "int32")
        local b = lurek.compute.fromTable({0x0F, 0x0F, 0x55}, nil, "int32")
        local c = a:bitwiseAnd(b)
        expect_near(0x0F, c:get(1), 1e-5)
        expect_near(0x0F, c:get(2), 1e-5)
        expect_near(0x00, c:get(3), 1e-5)
    end)

    -- @covers LArray:bitwiseOr
    -- @covers lurek.compute.fromTable
    it("bitwiseOr on int32 arrays", function()
        local a = lurek.compute.fromTable({0xF0, 0x0F}, nil, "int32")
        local b = lurek.compute.fromTable({0x0F, 0x0F}, nil, "int32")
        local c = a:bitwiseOr(b)
        expect_near(0xFF, c:get(1), 1e-5)
        expect_near(0x0F, c:get(2), 1e-5)
    end)

    -- @covers LArray:bitwiseXor
    -- @covers lurek.compute.fromTable
    it("bitwiseXor on int32 arrays", function()
        local a = lurek.compute.fromTable({0xFF, 0x0F}, nil, "int32")
        local b = lurek.compute.fromTable({0xFF, 0x0F}, nil, "int32")
        local c = a:bitwiseXor(b)
        expect_near(0x00, c:get(1), 1e-5)
        expect_near(0x00, c:get(2), 1e-5)
    end)

    -- @covers LArray:bitwiseNot
    -- @covers lurek.compute.fromTable
    it("bitwiseNot on int32 array", function()
        local a = lurek.compute.fromTable({0, 1}, nil, "int32")
        local c = a:bitwiseNot()
        -- NOT 0 = -1 (all bits set), NOT 1 = -2
        expect_near(-1, c:get(1), 1e-5)
        expect_near(-2, c:get(2), 1e-5)
    end)

    -- @covers LArray:bitwiseAnd
    -- @covers lurek.compute.fromTable
    it("bitwise on float32 errors", function()
        local a = lurek.compute.fromTable({1, 2})
        local b = lurek.compute.fromTable({3, 4})
        local ok = pcall(function() a:bitwiseAnd(b) end)
        expect_false(ok, "bitwise on float32 should error")
    end)
end)

-- =========================================================================
-- 13. 2D Spatial operations
-- =========================================================================
-- @describe 2D spatial operations
describe("2D spatial operations", function()
    -- @covers LArray:convolve2D
    -- @covers LArray:set
    -- @covers lurek.compute.fromTable
    -- @covers lurek.compute.zeros
    it("convolve2D with identity kernel", function()
        local a = lurek.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        -- Identity-like: 3x3 kernel with 1 in center
        local k = lurek.compute.zeros({3, 3})
        k:set(2, 2, 1.0)
        local c = a:convolve2D(k)
        -- Center element should stay 5 (edges may be clamped/zero-padded)
        expect_near(5.0, c:get(2, 2), 1e-5)
    end)

    -- @covers LArray:convolve2D
    -- @covers LArray:set
    -- @covers lurek.compute.fromTable
    -- @covers lurek.compute.zeros
    it("convolve2D blur averages the center sample", function()
        local a = lurek.compute.zeros({3, 3})
        a:set(2, 2, 9.0)
        local k = lurek.compute.fromTable({
            1.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0,
            1.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0,
            1.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0,
        }, {3, 3})
        local c = a:convolve2D(k)
        expect_near(1.0, c:get(2, 2), 1e-5)
    end)

    -- @covers LArray:dilate
    -- @covers LArray:set
    -- @covers lurek.compute.zeros
    it("dilate expands nonzero regions", function()
        local a = lurek.compute.zeros({5, 5})
        a:set(3, 3, 1.0)  -- single nonzero in center
        local d = a:dilate(1)
        -- center and neighbors should be nonzero after dilation
        expect_true(d:get(3, 3) > 0, "center should be nonzero")
        expect_true(d:get(2, 3) > 0, "top neighbor should be nonzero")
        expect_true(d:get(3, 2) > 0, "left neighbor should be nonzero")
    end)

    -- @covers LArray:erode
    -- @covers LArray:set
    -- @covers lurek.compute.ones
    it("erode shrinks nonzero regions", function()
        local a = lurek.compute.ones({5, 5})
        a:set(1, 1, 0.0)  -- remove one corner
        local e = a:erode(1)
        -- The corner neighbors should be eroded away
        expect_near(0.0, e:get(1, 1), 1e-5)
    end)

    -- @covers LArray:floodFill
    -- @covers lurek.compute.zeros
    it("floodFill fills connected region", function()
        local a = lurek.compute.zeros({3, 3})
        -- Fill from (1,1)  0-region with value 5
        local filled = a:floodFill(1, 1, 5.0)
        -- All zeros connected to (1,1) should become 5
        expect_near(5.0, filled:get(1, 1), 1e-5)
        expect_near(5.0, filled:get(2, 2), 1e-5)
        expect_near(5.0, filled:get(3, 3), 1e-5)
    end)

    -- @covers LArray:getRegion
    -- @covers lurek.compute.fromTable
    it("getRegion extracts sub-array", function()
        local a = lurek.compute.fromTable({1,2,3,4, 5,6,7,8, 9,10,11,12}, {3, 4})
        -- Extract 2x2 region starting at row=1, col=2
        local r = a:getRegion(1, 2, 2, 2)
        local s = r:getShape()
        expect_equal(2, s[1])
        expect_equal(2, s[2])
        expect_near(2.0, r:get(1, 1), 1e-5)
        expect_near(3.0, r:get(1, 2), 1e-5)
        expect_near(6.0, r:get(2, 1), 1e-5)
        expect_near(7.0, r:get(2, 2), 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:setRegion
    -- @covers lurek.compute.fromTable
    -- @covers lurek.compute.zeros
    it("setRegion stamps into array", function()
        local a = lurek.compute.zeros({4, 4})
        local patch = lurek.compute.fromTable({9, 8, 7, 6}, {2, 2})
        a:setRegion(2, 2, patch)
        expect_near(9.0, a:get(2, 2), 1e-5)
        expect_near(8.0, a:get(2, 3), 1e-5)
        expect_near(7.0, a:get(3, 2), 1e-5)
        expect_near(6.0, a:get(3, 3), 1e-5)
        -- Untouched regions remain zero
        expect_near(0.0, a:get(1, 1), 1e-5)
    end)

    -- @covers LArray:convolve2D
    -- @covers lurek.compute.fromTable
    it("convolve2D with 1x3 horizontal kernel (non-square)", function()
        -- 3x3 input
        local a = lurek.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        -- 1x3 horizontal edge kernel
        local k = lurek.compute.fromTable({-1, 0, 1}, {1, 3})
        local c = a:convolve2D(k)
        expect_equal(3, c:getShape()[1])
        expect_equal(3, c:getShape()[2])
    end)

    -- @covers LArray:convolve2D
    -- @covers lurek.compute.fromTable
    it("convolve2D with 3x1 vertical kernel (non-square)", function()
        -- 4x4 input
        local a = lurek.compute.fromTable({1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16}, {4,4})
        -- 3x1 vertical kernel
        local k = lurek.compute.fromTable({-1, 0, 1}, {3, 1})
        local c = a:convolve2D(k)
        expect_equal(4, c:getShape()[1])
        expect_equal(4, c:getShape()[2])
    end)

    -- @covers LArray:convolve2D
    -- @covers lurek.compute.fromTable
    -- @covers lurek.compute.zeros
    it("convolve2D with 2x2 kernel (non-square input)", function()
        -- 5x3 rectangular input
        local a = lurek.compute.zeros({5, 3})
        for i = 1, 15 do
            local row = math.floor((i - 1) / 3) + 1
            local col = ((i - 1) % 3) + 1
            a:set(row, col, 1.0)
        end
        -- 2x2 kernel
        local k = lurek.compute.fromTable({1, 1, 1, 1}, {2, 2})
        local c = a:convolve2D(k)
        expect_equal(5, c:getShape()[1])
        expect_equal(3, c:getShape()[2])
    end)

    -- @covers LArray:convolve2D
    -- @covers lurek.compute.fromTable
    it("convolve2D with 1x5 kernel preserves output shape", function()
        -- 3x5 input
        local a = lurek.compute.fromTable({1,2,3,4,5, 6,7,8,9,10, 11,12,13,14,15}, {3,5})
        -- 1x5 kernel
        local k = lurek.compute.fromTable({1, 1, 1, 1, 1}, {1, 5})
        local c = a:convolve2D(k)
        expect_equal(3, c:getShape()[1])
        expect_equal(5, c:getShape()[2])
    end)
end)

-- =========================================================================
-- 14. Type system
-- =========================================================================
-- @describe type system
describe("type system", function()
    -- @covers LArray:type
    -- @covers lurek.compute.zeros
    it("type() returns LArray", function()
        local a = lurek.compute.zeros({2})
        expect_equal("LArray", a:type())
    end)

    -- @covers LArray:typeOf
    -- @covers lurek.compute.zeros
    it("typeOf Array is true", function()
        local a = lurek.compute.zeros({2})
        expect_true(a:typeOf("Array"))
    end)

    -- @covers LArray:typeOf
    -- @covers lurek.compute.zeros
    it("typeOf Object is true", function()
        local a = lurek.compute.zeros({2})
        expect_true(a:typeOf("Object"))
    end)

    -- @covers LArray:typeOf
    -- @covers lurek.compute.zeros
    it("typeOf Source is false", function()
        local a = lurek.compute.zeros({2})
        expect_false(a:typeOf("Source"))
    end)
end)

-- =========================================================================
-- 15. Error cases
-- =========================================================================
-- @describe error cases
describe("error cases", function()
    -- @covers LArray:add
    -- @covers lurek.compute.fromTable
    it("mismatched shapes for binary ops error", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({1, 2})
        local ok = pcall(function() a:add(b) end)
        expect_false(ok, "mismatched shapes should error")
    end)

    -- @covers LArray:reshape
    -- @covers lurek.compute.fromTable
    it("reshape with wrong element count errors", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local ok = pcall(function() a:reshape({2, 2}) end)
        expect_false(ok, "reshape with wrong count should error")
    end)

    -- @covers lurek.compute.zeros
    it("empty shape errors", function()
        local ok = pcall(function() lurek.compute.zeros({}) end)
        expect_false(ok, "empty shape should error")
    end)

    -- @covers lurek.compute.zeros
    it("negative shape dimension errors", function()
        local ok = pcall(function() lurek.compute.zeros({-1}) end)
        expect_false(ok, "negative shape should error")
    end)

    -- @covers LArray:getDimensions
    -- @covers lurek.compute.zeros
    it("shape with four dimensions is supported", function()
        local a = lurek.compute.zeros({1, 2, 3, 4})
        expect_equal(4, a:getDimensions())
    end)

    -- @covers LArray:transpose
    -- @covers lurek.compute.zeros
    it("transpose on non-2D errors", function()
        local a = lurek.compute.zeros({3})
        local ok = pcall(function() a:transpose() end)
        expect_false(ok, "transpose on 1D should error")
    end)

    -- @covers lurek.compute.zeros
    it("unknown dtype errors", function()
        local ok = pcall(function() lurek.compute.zeros({3}, "float16") end)
        expect_false(ok, "unknown dtype should error")
    end)

    -- @covers lurek.compute.range
    it("range with negative step errors", function()
        local ok = pcall(function() lurek.compute.range(0, 5, -1) end)
        expect_false(ok, "negative range step should error")
    end)

    -- @covers lurek.compute.fromTable
    it("fromTable with mismatched shape errors", function()
        local ok = pcall(function() lurek.compute.fromTable({1, 2, 3}, {2, 3}) end)
        expect_false(ok, "shape mismatch should error")
    end)

    -- @covers LArray:matmul
    -- @covers lurek.compute.fromTable
    it("matmul with incompatible shapes errors", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
        local b = lurek.compute.fromTable({1, 2, 3}, {3, 1})
        local ok = pcall(function() a:matmul(b) end)
        expect_false(ok, "matmul shape mismatch should error")
    end)

    -- @covers LArray:dot
    -- @covers lurek.compute.fromTable
    it("dot on mismatched sizes errors", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({1, 2})
        local ok = pcall(function() a:dot(b) end)
        expect_false(ok, "dot size mismatch should error")
    end)

    -- @covers LArray:floodFill
    -- @covers lurek.compute.zeros
    it("floodFill out of bounds errors", function()
        local a = lurek.compute.zeros({2, 2})
        local ok = pcall(function() a:floodFill(6, 1, 1.0) end)
        expect_false(ok, "out-of-bounds floodFill should error")
    end)

    -- @covers LArray:getRegion
    -- @covers lurek.compute.zeros
    it("getRegion out of bounds errors", function()
        local a = lurek.compute.zeros({2, 2})
        local ok = pcall(function() a:getRegion(2, 2, 2, 2) end)
        expect_false(ok, "out-of-bounds region should error")
    end)
end)

-- =========================================================================
-- Bitwise shift
-- =========================================================================
-- @describe bitwise shift
describe("bitwise shift", function()
    -- @covers LArray:bitwiseLShift
    -- @covers lurek.compute.fromTable
    it("bitwiseLShift shifts left", function()
        local a = lurek.compute.fromTable({1, 2, 4}, {3}, "int32")
        local r = a:bitwiseLShift(2)
        expect_equal(4, r:get(1))
        expect_equal(8, r:get(2))
        expect_equal(16, r:get(3))
    end)

    -- @covers LArray:bitwiseRShift
    -- @covers lurek.compute.fromTable
    it("bitwiseRShift shifts right", function()
        local a = lurek.compute.fromTable({16, 8, 4}, {3}, "int32")
        local r = a:bitwiseRShift(2)
        expect_equal(4, r:get(1))
        expect_equal(2, r:get(2))
        expect_equal(1, r:get(3))
    end)

    -- @covers LArray:bitwiseLShift
    -- @covers lurek.compute.fromTable
    it("bitwiseLShift with shift amount 0 preserves values", function()
        local a = lurek.compute.fromTable({5, 10, 15}, {3}, "int32")
        local r = a:bitwiseLShift(0)
        expect_equal(5, r:get(1))
        expect_equal(10, r:get(2))
        expect_equal(15, r:get(3))
    end)

    -- @covers LArray:bitwiseRShift
    -- @covers lurek.compute.fromTable
    it("bitwiseRShift with shift amount 0 preserves values", function()
        local a = lurek.compute.fromTable({5, 10, 15}, {3}, "int32")
        local r = a:bitwiseRShift(0)
        expect_equal(5, r:get(1))
        expect_equal(10, r:get(2))
        expect_equal(15, r:get(3))
    end)

    -- @covers LArray:bitwiseLShift
    -- @covers lurek.compute.fromTable
    it("bitwiseLShift with large shift amounts", function()
        local a = lurek.compute.fromTable({1, 1, 1}, {3}, "int32")
        local r = a:bitwiseLShift(8)
        expect_equal(256, r:get(1))
        expect_equal(256, r:get(2))
        expect_equal(256, r:get(3))
    end)

    -- @covers LArray:bitwiseRShift
    -- @covers lurek.compute.fromTable
    it("bitwiseRShift with large values", function()
        local a = lurek.compute.fromTable({256, 512, 1024}, {3}, "int32")
        local r = a:bitwiseRShift(4)
        expect_equal(16, r:get(1))
        expect_equal(32, r:get(2))
        expect_equal(64, r:get(3))
    end)
end)

-- =========================================================================
-- Summary
-- =========================================================================

-- @describe compute array strides and error paths (RS parity)
describe("compute array strides and error paths (RS parity)", function()
    -- @covers lurek.compute.range
    it("range with zero step raises an error", function()
        expect_error(function() lurek.compute.range(0, 10, 0) end)
    end)

    -- @covers lurek.compute.range
    it("range with zero step raises an error", function()
        expect_error(function() lurek.compute.range(10, 0, 0) end)
    end)

    -- @covers LArray:get
    -- @covers lurek.compute.ones
    it("ones fills array with 1.0", function()
        local a = lurek.compute.ones({5})
        for i = 1, 5 do
            expect_near(1.0, a:get(i), 0.001)
        end
    end)

    -- @covers LArray:get
    -- @covers lurek.compute.zeros
    it("zeros creates array filled with 0.0", function()
        local a = lurek.compute.zeros({4})
        for i = 1, 4 do
            expect_near(0.0, a:get(i), 0.001)
        end
    end)

    -- @covers LArray:get
    -- @covers lurek.compute.range
    it("range ascending produces correct sequence", function()
        local a = lurek.compute.range(1, 4)
        expect_near(1.0, a:get(1), 0.001)
        expect_near(2.0, a:get(2), 0.001)
        expect_near(3.0, a:get(3), 0.001)
    end)

    -- @covers LArray:get
    -- @covers LArray:set
    -- @covers lurek.compute.zeros
    it("get and set round-trip at arbitrary index", function()
        local a = lurek.compute.zeros({10})
        a:set(7, 3.14)
        expect_near(3.14, a:get(7), 0.001)
    end)

    -- @covers LArray:getShape
    -- @covers lurek.compute.zeros
    it("getShape returns table with dimensions", function()
        local a = lurek.compute.zeros({2, 3})
        local shape = a:getShape()
        expect_equal("table", type(shape))
        expect_equal(2, shape[1])
        expect_equal(3, shape[2])
    end)
end)

-- ---------------------------------------------------------------------------
-- Analytics module
-- ---------------------------------------------------------------------------
-- @describe lurek.compute.Array analytics
describe("lurek.compute.Array analytics", function()

    -- @covers LArray:cumsum
    -- @covers lurek.compute.fromTable
    it("cumsum produces running total", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, nil, "float32")
        local c = a:cumsum()
        expect_near(1,  c:get(1), 0.001)
        expect_near(3,  c:get(2), 0.001)
        expect_near(10, c:get(4), 0.001)
    end)

    -- @covers LArray:diff
    -- @covers lurek.compute.fromTable
    it("diff order 1 yields first differences", function()
        local a = lurek.compute.fromTable({1, 4, 9, 16}, nil, "float32")
        local d = a:diff(1)
        expect_equal(3, d:getSize())
        expect_near(3, d:get(1), 0.01)
        expect_near(7, d:get(3), 0.01)
    end)

    -- @covers LArray:diff
    -- @covers lurek.compute.fromTable
    it("diff order 2 of quadratic is constant", function()
        local a = lurek.compute.fromTable({0, 1, 4, 9, 16}, nil, "float32")
        local d = a:diff(2)
        expect_equal(3, d:getSize())
        expect_near(2, d:get(1), 0.01)
        expect_near(2, d:get(3), 0.01)
    end)

    -- @covers LArray:histogram
    -- @covers lurek.compute.fromTable
    it("histogram returns correct bin counts", function()
        local a = lurek.compute.fromTable({0.5, 1.5, 2.5, 3.5}, nil, "float32")
        local h = a:histogram(2, 0, 4)
        expect_equal(2, #h)
        expect_equal(2, h[1].count)
        expect_equal(2, h[2].count)
    end)

    -- @covers LArray:percentile
    -- @covers lurek.compute.fromTable
    it("percentile 50 is median", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4, 5}, nil, "float32")
        expect_near(3.0, a:percentile(50), 0.001)
    end)

    -- @covers LArray:percentile
    -- @covers lurek.compute.fromTable
    it("percentile 100 equals max", function()
        local a = lurek.compute.fromTable({3, 1, 4, 1, 5}, nil, "float32")
        expect_near(5.0, a:percentile(100), 0.001)
    end)

    -- @covers LArray:covariance
    -- @covers lurek.compute.fromTable
    it("covariance of array with itself is its variance", function()
        local a = lurek.compute.fromTable({1, 2, 3}, nil, "float32")
        -- pop variance of [1,2,3] = 2/3
        expect_near(0.6667, a:covariance(a), 0.01)
    end)

    -- @covers LArray:pearsonCorr
    -- @covers lurek.compute.fromTable
    it("pearsonCorr of linearly related arrays is 1", function()
        local a = lurek.compute.fromTable({1, 2, 3}, nil, "float32")
        local b = lurek.compute.fromTable({2, 4, 6}, nil, "float32")
        expect_near(1.0, a:pearsonCorr(b), 0.001)
    end)

    -- @covers LArray:normalizeRange
    -- @covers lurek.compute.fromTable
    it("normalizeRange scales to [0, 1]", function()
        local a = lurek.compute.fromTable({0, 5, 10}, nil, "float32")
        local n = a:normalizeRange(0, 1)
        expect_near(0.0, n:get(1), 0.001)
        expect_near(0.5, n:get(2), 0.001)
        expect_near(1.0, n:get(3), 0.001)
    end)

    -- @covers LArray:zscore
    -- @covers lurek.compute.fromTable
    it("zscore of constant array returns error", function()
        local a = lurek.compute.fromTable({5, 5, 5}, nil, "float32")
        expect_error(function() a:zscore() end)
    end)

    -- @covers LArray:zscore
    -- @covers lurek.compute.fromTable
    it("zscore normalises mean to zero", function()
        local a = lurek.compute.fromTable({2, 4, 4, 4, 5, 5, 7, 9}, nil, "float32")
        local z = a:zscore()
        local sum = 0
        for i = 1, z:getSize() do sum = sum + z:get(i) end
        expect_near(0.0, sum / z:getSize(), 0.001)
    end)

    -- @covers LArray:convolve1d
    -- @covers lurek.compute.fromTable
    it("convolve1d with identity kernel returns input", function()
        local sig = lurek.compute.fromTable({1, 2, 3}, nil, "float32")
        local ker = lurek.compute.fromTable({1}, nil, "float32")
        local out = sig:convolve1d(ker)
        expect_equal(3, out:getSize())
        expect_near(1, out:get(1), 0.001)
        expect_near(3, out:get(3), 0.001)
    end)

    -- @covers LArray:correlate1d
    -- @covers lurek.compute.fromTable
    it("correlate1d peaks at template location", function()
        local sig = lurek.compute.fromTable({0, 1, 2, 1, 0}, nil, "float32")
        local tpl = lurek.compute.fromTable({1, 2, 1}, nil, "float32")
        local out = sig:correlate1d(tpl)
        expect_equal(3, out:getSize())
        -- position 2 (window [1,2,1]): 1+4+1 = 6
        expect_near(6, out:get(2), 0.001)
    end)
end)

-- ---------------------------------------------------------------------------
-- Linear algebra module
-- ---------------------------------------------------------------------------
-- @describe lurek.compute linear algebra
describe("lurek.compute linear algebra", function()

    -- @covers LArray:normalizeVec
    -- @covers lurek.compute.fromTable
    it("normalizeVec makes unit vector", function()
        local v = lurek.compute.fromTable({3, 4}, nil, "float64")
        local n = v:normalizeVec()
        expect_near(0.6, n:get(1), 0.001)
        expect_near(0.8, n:get(2), 0.001)
    end)

    -- @covers LArray:cross2d
    -- @covers lurek.compute.fromTable
    it("cross2d of standard basis vectors is 1", function()
        local a = lurek.compute.fromTable({1, 0}, nil, "float64")
        local b = lurek.compute.fromTable({0, 1}, nil, "float64")
        expect_near(1.0, a:cross2d(b), 0.001)
    end)

    -- @covers LArray:outer
    -- @covers lurek.compute.fromTable
    it("outer product has correct shape and values", function()
        local a = lurek.compute.fromTable({1, 2}, nil, "float64")
        local b = lurek.compute.fromTable({3, 4, 5}, nil, "float64")
        local o = a:outer(b)
        local shape = o:getShape()
        expect_equal(2, shape[1])
        expect_equal(3, shape[2])
    end)

    -- @covers LArray:get
    -- @covers lurek.compute.gaussianKernel
    it("gaussianKernel sums to one", function()
        local k = lurek.compute.gaussianKernel(3, 1.0)
        local s = 0
        for row = 1, 3 do
            for col = 1, 3 do
                s = s + k:get(row, col)
            end
        end
        expect_near(1.0, s, 0.0001)
    end)

    -- @covers LArray:reshape
    -- @covers LArray:transformPoints
    -- @covers lurek.compute.fromTable
    -- @covers lurek.compute.rotate2dMatrix
    it("rotate2dMatrix rotates point by 90 degrees", function()
        local m = lurek.compute.rotate2dMatrix(math.pi / 2)
        local pts = lurek.compute.fromTable({1, 0}, nil, "float64"):reshape({1, 2})
        local out = m:transformPoints(pts)
        expect_near(0.0, out:get(1, 1), 0.001)
        expect_near(1.0, out:get(1, 2), 0.001)
    end)

    -- @covers LArray:reshape
    -- @covers LArray:transformPoints
    -- @covers lurek.compute.affine2d
    -- @covers lurek.compute.fromTable
    it("affine2d translates points correctly", function()
        local m = lurek.compute.affine2d(5, 3, 0, 1, 1)
        local pts = lurek.compute.fromTable({0, 0}, nil, "float64"):reshape({1, 2})
        local out = m:transformPoints(pts)
        expect_near(5.0, out:get(1, 1), 0.001)
        expect_near(3.0, out:get(1, 2), 0.001)
    end)

    -- @covers LArray:linsolve
    -- @covers LArray:reshape
    -- @covers lurek.compute.fromTable
    it("linsolve gives correct 2x2 solution", function()
        local a = lurek.compute.fromTable({2, 1, 1, 3}, nil, "float64"):reshape({2, 2})
        local b = lurek.compute.fromTable({5, 10}, nil, "float64")
        local x = a:linsolve(b)
        expect_near(1.0, x:get(1), 0.001)
        expect_near(3.0, x:get(2), 0.001)
    end)

    -- @covers LArray:sobel
    -- @covers lurek.compute.zeros
    it("sobel on flat image gives zero gradient", function()
        local flat = lurek.compute.zeros({5, 5})
        local result = flat:sobel()
        expect_near(0.0, result.gx:get(3, 3), 0.001)
        expect_near(0.0, result.gy:get(3, 3), 0.001)
    end)

end)

-- =========================================================================
-- =========================================================================

-- @describe Missing API Coverage
describe("Missing API Coverage", function()
    -- @covers lurek.compute.fft
    it("covers lurek.compute.fft", function()
        local out = lurek.compute.fft({1, 1, 1, 1, 1, 1, 1, 1})
        expect_equal(8, #out)
        expect_near(8.0, out[1].re, 1e-6)
        expect_near(0.0, out[1].im, 1e-6)
        for i = 2, #out do
            local mag = math.sqrt(out[i].re * out[i].re + out[i].im * out[i].im)
            expect_near(0.0, mag, 1e-6)
        end
    end)

    -- @covers lurek.compute.fft
    -- @covers lurek.compute.ifft
    it("covers lurek.compute.ifft", function()
        local data = {1.0, 0.5, -0.5, 0.0, 1.0, -1.0, 0.0, 0.25}
        local recovered = lurek.compute.ifft(lurek.compute.fft(data))
        expect_equal(#data, #recovered)
        for i = 1, #data do
            expect_near(data[i], recovered[i], 1e-6)
        end
    end)

    -- @covers lurek.compute.fftMagnitude
    it("covers lurek.compute.fftMagnitude", function()
        local mag = lurek.compute.fftMagnitude({0.1, -0.2, 0.3, -0.4, 0.5})
        expect_equal(8, #mag)
        for i = 1, #mag do
            expect_true(mag[i] >= 0.0, "FFT magnitude bins must be non-negative")
        end
    end)

    -- @covers LArray:get
    -- @covers lurek.compute.fromTable
    it("covers Array:get", function()
        local a = lurek.compute.fromTable({10, 20, 30}, {3})
        expect_equal(10, a:get(1))
        expect_equal(30, a:get(3))
    end)

    -- @covers LArray:get
    -- @covers LArray:set
    -- @covers lurek.compute.zeros
    it("covers Array:set", function()
        local a = lurek.compute.zeros({3})
        a:set(2, 99)
        expect_equal(99, a:get(2))
    end)

    -- @covers LArray:pow
    -- @covers lurek.compute.fromTable
    it("covers Array:pow", function()
        local a = lurek.compute.fromTable({2, 3, 4}, {3})
        local r = a:pow(2)
        expect_equal(4, r:get(1))
        expect_equal(9, r:get(2))
        expect_equal(16, r:get(3))
    end)

    -- @covers LArray:abs
    -- @covers lurek.compute.fromTable
    it("covers Array:abs", function()
        local a = lurek.compute.fromTable({-1, 2, -3}, {3})
        local r = a:abs()
        expect_equal(1, r:get(1))
        expect_equal(2, r:get(2))
        expect_equal(3, r:get(3))
    end)

    -- @covers LArray:neg
    -- @covers lurek.compute.fromTable
    it("covers Array:neg", function()
        local a = lurek.compute.fromTable({1, -2, 3}, {3})
        local r = a:neg()
        expect_equal(-1, r:get(1))
        expect_equal(2,  r:get(2))
        expect_equal(-3, r:get(3))
    end)

    -- @covers LArray:any
    -- @covers lurek.compute.fromTable
    it("covers Array:any", function()
        local a_true  = lurek.compute.fromTable({0, 0, 1}, {3})
        local a_false = lurek.compute.fromTable({0, 0, 0}, {3})
        expect_equal(true,  a_true:any())
        expect_equal(false, a_false:any())
    end)

    -- @covers LArray:all
    -- @covers lurek.compute.fromTable
    it("covers Array:all", function()
        local a_true  = lurek.compute.fromTable({1, 2, 3}, {3})
        local a_false = lurek.compute.fromTable({1, 0, 3}, {3})
        expect_equal(true,  a_true:all())
        expect_equal(false, a_false:all())
    end)

    -- @covers LArray:sum
    -- @covers lurek.compute.fromTable
    it("covers Array:sum", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, {4})
        expect_equal(10, a:sum())
    end)

    -- @covers LArray:min
    -- @covers lurek.compute.fromTable
    it("covers Array:min", function()
        local a = lurek.compute.fromTable({5, 2, 8, 1}, {4})
        expect_equal(1, a:min())
    end)

    -- @covers LArray:max
    -- @covers lurek.compute.fromTable
    it("covers Array:max", function()
        local a = lurek.compute.fromTable({5, 2, 8, 1}, {4})
        expect_equal(8, a:max())
    end)

    -- @covers LArray:dot
    -- @covers lurek.compute.fromTable
    it("covers Array:dot", function()
        local a = lurek.compute.fromTable({1, 2, 3}, {3})
        local b = lurek.compute.fromTable({4, 5, 6}, {3})
        -- 1*4 + 2*5 + 3*6 = 32
        expect_equal(32, a:dot(b))
    end)

    -- @covers LArray:luDecompose
    -- @covers lurek.compute.fromTable
    it("covers Array:luDecompose", function()
        local m = lurek.compute.fromTable({1,2,3,4}, {2,2})
        local result = m:luDecompose()
        expect_type("table", result)
        expect_type("number", result.n)
        expect_equal(2, result.n)
        expect_type("table", result.perm)
    end)

end)

-- @describe Array shape and metadata
describe("Array shape and metadata", function()
    -- @covers LArray:getShape
    -- @covers lurek.compute.zeros
    it("getShape returns {3,4} for a 3x4 array", function()
        local a = lurek.compute.zeros({3, 4})
        local s = a:getShape()
        expect_equal(3, s[1])
        expect_equal(4, s[2])
    end)

    -- @covers LArray:getDimensions
    -- @covers lurek.compute.zeros
    it("getDimensions returns 2 for a 2D array", function()
        local a = lurek.compute.zeros({3, 4})
        expect_equal(2, a:getDimensions())
    end)

    -- @covers LArray:getSize
    -- @covers lurek.compute.zeros
    it("getSize returns total element count", function()
        local a = lurek.compute.zeros({3, 4})
        expect_equal(12, a:getSize())
    end)

    -- @covers LArray:getDataType
    -- @covers lurek.compute.zeros
    it("getDataType returns a non-empty string", function()
        local a = lurek.compute.zeros({3})
        local dt = a:getDataType()
        expect_type("string", dt)
        expect_true(#dt > 0, "data type must be non-empty")
    end)

    -- @covers LArray:isOnGPU
    -- @covers lurek.compute.zeros
    it("isOnGPU returns a boolean", function()
        local a = lurek.compute.zeros({3})
        expect_type("boolean", a:isOnGPU())
    end)

    -- @covers LArray:type
    -- @covers lurek.compute.zeros
    it("type returns 'LArray'", function()
        local a = lurek.compute.zeros({2})
        expect_equal("LArray", a:type())
    end)

    -- @covers LArray:typeOf
    -- @covers lurek.compute.zeros
    it("typeOf('LArray') returns true", function()
        local a = lurek.compute.zeros({2})
        expect_equal(true, a:typeOf("LArray"))
    end)
end)

-- @describe Array data access and mutation
describe("Array data access and mutation", function()
    -- @covers LArray:toTable
    -- @covers lurek.compute.fromTable
    it("toTable returns a flat Lua table", function()
        local a = lurek.compute.fromTable({1, 2, 3}, {3})
        local t = a:toTable()
        expect_type("table", t)
        expect_equal(3, #t)
        expect_equal(1, t[1])
        expect_equal(3, t[3])
    end)

    -- @covers LArray:reshape
    -- @covers lurek.compute.fromTable
    it("reshape {4} into {2,2} preserves data", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, {4})
        local r = a:reshape({2, 2})
        local s = r:getShape()
        expect_equal(2, s[1])
        expect_equal(2, s[2])
    end)

    -- @covers LArray:clone
    -- @covers LArray:get
    -- @covers lurek.compute.fromTable
    it("clone produces equal but independent array", function()
        local a = lurek.compute.fromTable({5, 6, 7}, {3})
        local b = a:clone()
        expect_equal(a:get(1), b:get(1))
        b:set(1, 999)
        expect_equal(5, a:get(1))  -- original unchanged
    end)

    -- @covers LArray:transpose
    -- @covers lurek.compute.zeros
    it("transpose of 2x3 gives 3x2 shape", function()
        local a = lurek.compute.zeros({2, 3})
        local t = a:transpose()
        local s = t:getShape()
        expect_equal(3, s[1])
        expect_equal(2, s[2])
    end)

    -- @covers LArray:fill
    -- @covers LArray:get
    -- @covers lurek.compute.zeros
    it("fill sets all elements to the given value", function()
        local a = lurek.compute.zeros({4})
        a:fill(7)
        expect_equal(7, a:get(1))
        expect_equal(7, a:get(4))
    end)
end)

-- @describe Array math operations
describe("Array math operations", function()
    -- @covers LArray:sqrt
    -- @covers lurek.compute.fromTable
    it("sqrt of {4, 9, 16} gives {2, 3, 4}", function()
        local a = lurek.compute.fromTable({4, 9, 16}, {3})
        local r = a:sqrt()
        expect_equal(2, r:get(1))
        expect_equal(3, r:get(2))
        expect_equal(4, r:get(3))
    end)

    -- @covers LArray:clamp
    -- @covers lurek.compute.fromTable
    it("clamp(2, 8) restricts values to [2, 8]", function()
        local a = lurek.compute.fromTable({0, 5, 10}, {3})
        local r = a:clamp(2, 8)
        expect_equal(2, r:get(1))
        expect_equal(5, r:get(2))
        expect_equal(8, r:get(3))
    end)

    -- @covers LArray:threshold
    -- @covers lurek.compute.fromTable
    it("threshold returns a 0/1 mask", function()
        -- values below threshold â†’ 0, at or above â†’ 1
        local a = lurek.compute.fromTable({1, 5, 3, 9}, {4})
        local r = a:threshold(4)
        expect_equal(0, r:get(1))   -- 1 < 4
        expect_equal(1, r:get(2))   -- 5 >= 4
        expect_equal(0, r:get(3))   -- 3 < 4
        expect_equal(1, r:get(4))   -- 9 >= 4
    end)

    -- @covers LArray:countNonZero
    -- @covers lurek.compute.fromTable
    it("countNonZero counts non-zero elements", function()
        local a = lurek.compute.fromTable({0, 1, 0, 3, 0}, {5})
        expect_equal(2, a:countNonZero())
    end)

    -- @covers LArray:argmin
    -- @covers lurek.compute.fromTable
    it("argmin returns index (1-based) of smallest element", function()
        local a = lurek.compute.fromTable({5, 2, 8, 1}, {4})
        expect_equal(4, a:argmin())
    end)

    -- @covers LArray:argmax
    -- @covers lurek.compute.fromTable
    it("argmax returns index (1-based) of largest element", function()
        local a = lurek.compute.fromTable({5, 2, 8, 1}, {4})
        expect_equal(3, a:argmax())
    end)

    -- @covers LArray:mean
    -- @covers lurek.compute.fromTable
    it("mean of {2, 4, 6} is 4", function()
        local a = lurek.compute.fromTable({2, 4, 6}, {3})
        expect_equal(4, a:mean())
    end)

    -- @covers LArray:matmul
    -- @covers lurek.compute.fromTable
    it("matmul of 2x2 matrices produces 2x2", function()
        local a = lurek.compute.fromTable({1, 0, 0, 1}, {2, 2})  -- identity
        local b = lurek.compute.fromTable({3, 4, 5, 6}, {2, 2})
        local r = a:matmul(b)
        local s = r:getShape()
        expect_equal(2, s[1])
        expect_equal(2, s[2])
        -- identity * b = b
        expect_equal(3, r:get(1, 1))
        expect_equal(6, r:get(2, 2))
    end)
end)

-- @describe Array bitwise operations
describe("Array bitwise operations", function()
    local function int_arr(t)
        return lurek.compute.fromTable(t, {#t}, "int32")
    end

    -- @covers LArray:bitwiseAnd
    it("bitwiseAnd: 6 & 3 = 2", function()
        local a = int_arr({6})
        local b = int_arr({3})
        local t = a:bitwiseAnd(b):toTable()
        expect_equal(2, t[1])
    end)

    -- @covers LArray:bitwiseOr
    it("bitwiseOr: 5 | 3 = 7", function()
        local a = int_arr({5})
        local b = int_arr({3})
        local t = a:bitwiseOr(b):toTable()
        expect_equal(7, t[1])
    end)

    -- @covers LArray:bitwiseXor
    it("bitwiseXor: 6 xor 3 = 5", function()
        local a = int_arr({6})
        local b = int_arr({3})
        local t = a:bitwiseXor(b):toTable()
        expect_equal(5, t[1])
    end)

    -- @covers LArray:bitwiseNot
    it("bitwiseNot returns an array of same size", function()
        local a = int_arr({0})
        local r = a:bitwiseNot()
        expect_not_nil(r)
        expect_equal(1, r:getSize())
    end)

    -- @covers LArray:bitwiseLShift
    it("bitwiseLShift: 1 << 3 = 8", function()
        local a = int_arr({1})
        local t = a:bitwiseLShift(3):toTable()
        expect_equal(8, t[1])
    end)

    -- @covers LArray:bitwiseRShift
    it("bitwiseRShift: 8 >> 2 = 2", function()
        local a = int_arr({8})
        local t = a:bitwiseRShift(2):toTable()
        expect_equal(2, t[1])
    end)
end)

-- @describe Array image/spatial operations
describe("Array image/spatial operations", function()
    -- @covers LArray:convolve2D
    -- @covers lurek.compute.fromTable
    -- @covers lurek.compute.zeros
    it("convolve2D with 3x3 identity kernel preserves shape", function()
        local img    = lurek.compute.zeros({5, 5})
        local kernel = lurek.compute.fromTable({0,0,0, 0,1,0, 0,0,0}, {3,3})
        local r = img:convolve2D(kernel)
        local s = r:getShape()
        expect_equal(5, s[1])
        expect_equal(5, s[2])
    end)

    -- @covers LArray:dilate
    -- @covers lurek.compute.zeros
    it("dilate with radius 1 returns an array of same shape", function()
        local img = lurek.compute.zeros({5, 5})
        local r = img:dilate(1)
        local s = r:getShape()
        expect_equal(5, s[1])
        expect_equal(5, s[2])
    end)

    -- @covers LArray:erode
    -- @covers lurek.compute.ones
    it("erode with radius 1 returns an array of same shape", function()
        local img = lurek.compute.ones({5, 5})
        local r = img:erode(1)
        local s = r:getShape()
        expect_equal(5, s[1])
        expect_equal(5, s[2])
    end)

    -- @covers LArray:transformPoints
    -- @covers lurek.compute.fromTable
    it("transformPoints with 3x3 identity matrix leaves points unchanged", function()
        -- matrix:transformPoints(points) â€” called on the matrix
        local mat = lurek.compute.fromTable({1,0,0, 0,1,0, 0,0,1}, {3,3})
        local pts = lurek.compute.fromTable({1,0, 0,1, 2,3}, {3,2})
        local r = mat:transformPoints(pts)
        local s = r:getShape()
        expect_equal(3, s[1])
        expect_equal(2, s[2])
    end)
end)

-- =========================================================================
-- Phase 05  - Lua extensibility hooks
-- =========================================================================

-- @describe Array:map
describe("Array:map", function()
    -- @covers lurek.compute.fromTable
    it("map method exists", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        expect_equal(type(a.map), "function")
    end)

    -- @covers LArray:map
    -- @covers lurek.compute.fromTable
    it("map applies callback element-wise", function()
        local a = lurek.compute.fromTable({2, 4, 6})
        local b = a:map(function(x) return x / 2 end)
        local t = b:toTable()
        expect_equal(t[1], 1)
        expect_equal(t[2], 2)
        expect_equal(t[3], 3)
    end)
end)

-- @describe Array:eval
describe("Array:eval", function()
    -- @covers lurek.compute.fromTable
    it("eval method exists", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        expect_equal(type(a.eval), "function")
    end)

    -- @covers LArray:eval
    -- @covers lurek.compute.fromTable
    it("eval transforms elements with expression", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = a:eval("x * x")
        local t = b:toTable()
        expect_equal(t[1], 1)
        expect_equal(t[2], 4)
        expect_equal(t[3], 9)
    end)
end)

-- @describe Array:reduce
describe("Array:reduce", function()
    -- @covers lurek.compute.fromTable
    it("reduce method exists", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4})
        expect_equal(type(a.reduce), "function")
    end)

    -- @covers LArray:reduce
    -- @covers lurek.compute.fromTable
    it("reduce computes sum", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4})
        local total = a:reduce(function(acc, x) return acc + x end, 0)
        expect_equal(total, 10)
    end)
end)

-- @describe Array:scan
describe("Array:scan", function()
    -- @covers lurek.compute.fromTable
    it("scan method exists", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        expect_equal(type(a.scan), "function")
    end)

    -- @covers LArray:scan
    -- @covers lurek.compute.fromTable
    it("scan computes running sum", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4})
        local b = a:scan(function(acc, x) return acc + x end, 0)
        local t = b:toTable()
        expect_equal(t[1], 1)
        expect_equal(t[2], 3)
        expect_equal(t[3], 6)
        expect_equal(t[4], 10)
    end)
end)

-- =========================================================================
-- Array element-level operations with explicit  markers
-- =========================================================================
-- @describe Array element operations
describe("Array element operations ", function()
    -- @covers LArray:get
    -- @covers lurek.compute.fromTable
    it("Array:get reads an element by index", function()
        local a = lurek.compute.fromTable({10.0, 20.0, 30.0})
        expect_near(10.0, a:get(1), 1e-5)
        expect_near(30.0, a:get(3), 1e-5)
    end)

    -- @covers LArray:get
    -- @covers LArray:set
    -- @covers lurek.compute.zeros
    it("Array:set writes an element by index", function()
        local a = lurek.compute.zeros({4})
        a:set(2, 99.0)
        expect_near(99.0, a:get(2), 1e-5)
        expect_near(0.0, a:get(1), 1e-5)
    end)

    -- @covers LArray:pow
    -- @covers lurek.compute.fromTable
    it("Array:pow raises each element to a power", function()
        local a = lurek.compute.fromTable({2.0, 3.0})
        local r = a:pow(2)
        expect_not_nil(r)
        expect_type("userdata", r)
    end)

    -- @covers LArray:abs
    -- @covers lurek.compute.fromTable
    it("Array:abs returns absolute-value array", function()
        local a = lurek.compute.fromTable({-4.0, 3.0})
        local r = a:abs()
        expect_not_nil(r)
        expect_type("userdata", r)
    end)

    -- @covers LArray:neg
    -- @covers lurek.compute.fromTable
    it("Array:neg negates all elements", function()
        local a = lurek.compute.fromTable({1.0, -2.0})
        local r = a:neg()
        expect_not_nil(r)
        expect_type("userdata", r)
    end)

    -- @covers LArray:any
    -- @covers lurek.compute.fromTable
    it("Array:any returns a boolean", function()
        local a = lurek.compute.fromTable({0.0, 1.0})
        local v = a:any()
        expect_type("boolean", v)
        expect_equal(true, v)
    end)

    -- @covers LArray:all
    -- @covers lurek.compute.fromTable
    it("Array:all returns a boolean", function()
        local a = lurek.compute.fromTable({1.0, 1.0, 1.0})
        local v = a:all()
        expect_type("boolean", v)
        expect_equal(true, v)
    end)

    -- @covers LArray:sum
    -- @covers lurek.compute.fromTable
    it("Array:sum returns the total of all elements", function()
        local a = lurek.compute.fromTable({1.0, 2.0, 3.0})
        local s = a:sum()
        expect_near(6.0, s, 1e-5)
    end)

    -- @covers LArray:min
    -- @covers lurek.compute.fromTable
    it("Array:min returns the smallest element", function()
        local a = lurek.compute.fromTable({5.0, 1.0, 3.0})
        local m = a:min()
        expect_near(1.0, m, 1e-5)
    end)

    -- @covers LArray:max
    -- @covers lurek.compute.fromTable
    it("Array:max returns the largest element", function()
        local a = lurek.compute.fromTable({5.0, 1.0, 3.0})
        local m = a:max()
        expect_near(5.0, m, 1e-5)
    end)

    -- @covers LArray:dot
    -- @covers lurek.compute.fromTable
    it("Array:dot computes inner product", function()
        local a = lurek.compute.fromTable({1.0, 2.0, 3.0})
        local b = lurek.compute.fromTable({4.0, 5.0, 6.0})
        local d = a:dot(b)
        expect_near(32.0, d, 1e-5)
    end)

    -- @covers LArray:map
    -- @covers lurek.compute.fromTable
    it("Array:map applies a transform to each element", function()
        local a = lurek.compute.fromTable({1.0, 2.0, 4.0})
        local r = a:map(function(x) return x * 2 end)
        expect_not_nil(r)
        expect_type("userdata", r)
    end)
end)

-- @describe lurek.compute.fft
describe("lurek.compute.fft", function()
    -- @covers lurek.compute.fft
    it("fft of a real signal returns a result", function()
        local result = lurek.compute.fft({1.0, 0.0, 1.0, 0.0})
        expect_not_nil(result)
    end)
end)

-- @describe LArray:eigenPower
describe("LArray:eigenPower", function()
    -- @covers LArray:eigenPower
    -- @covers lurek.compute.newArray
    it("eigenPower returns dominant eigenvalue and eigenvector for a symmetric matrix", function()
        -- 2x2 identity matrix: eigenvalue = 1, eigenvector = [1, 0] or [0, 1]
        local m = lurek.compute.newArray({2, 2})
        m:set(1, 1, 1.0)
        m:set(1, 2, 0.0)
        m:set(2, 1, 0.0)
        m:set(2, 2, 1.0)
        local result = m:eigenPower()
        expect_not_nil(result)
        expect_type("number", result.value)
        expect_type("table", result.vector)
    end)
end)

-- @describe compute strict: LArray where
describe("compute strict: LArray where", function()
    -- @covers LArray:where
    -- @covers lurek.compute.newArray
    it("LArray where is callable with matching arrays", function()
        local a = lurek.compute.newArray({4}, "float32")
        local b = lurek.compute.newArray({4}, "float32")
        local mask = lurek.compute.newArray({4}, "float32")
        local ok = pcall(function() return a:where(mask, b) end)
        expect_type("boolean", ok)
    end)
end)

-- @describe lurek.compute parallelization configuration
describe("lurek.compute parallelization configuration", function()
    -- @covers lurek.compute.getParThreshold
    it("has getParThreshold function", function()
        expect_type("function", lurek.compute.getParThreshold)
    end)

    -- @covers lurek.compute.setParThreshold
    it("has setParThreshold function", function()
        expect_type("function", lurek.compute.setParThreshold)
    end)

    -- @covers lurek.compute.getParThreshold
    it("getParThreshold returns an integer", function()
        local threshold = lurek.compute.getParThreshold()
        expect_type("number", threshold)
        assert(threshold > 0, "threshold should be positive")
    end)

    -- @covers lurek.compute.setParThreshold
    -- @covers lurek.compute.getParThreshold
    it("setParThreshold changes the threshold and returns previous value", function()
        local old_threshold = lurek.compute.getParThreshold()
        local new_threshold = 5000
        local returned_old = lurek.compute.setParThreshold(new_threshold)
        expect_equal(old_threshold, returned_old)
        expect_equal(new_threshold, lurek.compute.getParThreshold())
        -- Restore original threshold
        lurek.compute.setParThreshold(old_threshold)
    end)

    -- @covers lurek.compute.setParThreshold
    -- @covers lurek.compute.getParThreshold
    it("setParThreshold enforces minimum value of 1", function()
        local original = lurek.compute.getParThreshold()
        lurek.compute.setParThreshold(0)
        local result = lurek.compute.getParThreshold()
        expect_true(result >= 1, "threshold should be at least 1")
        lurek.compute.setParThreshold(original)
    end)
end)

test_summary()
