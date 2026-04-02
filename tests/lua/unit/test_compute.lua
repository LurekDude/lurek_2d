-- Luna2D Compute Array Tests
-- Tests for luna.compute dense N-dimensional array API

-- =========================================================================
-- 1. Module exists
-- =========================================================================
describe("luna.compute module exists", function()
    it("luna.compute is a table", function()
        expect_type("table", luna.compute)
    end)

    it("has newArray factory", function()
        expect_type("function", luna.compute.newArray)
    end)

    it("has zeros factory", function()
        expect_type("function", luna.compute.zeros)
    end)

    it("has ones factory", function()
        expect_type("function", luna.compute.ones)
    end)

    it("has range factory", function()
        expect_type("function", luna.compute.range)
    end)

    it("has fromTable factory", function()
        expect_type("function", luna.compute.fromTable)
    end)
end)

-- =========================================================================
-- 2. Construction
-- =========================================================================
describe("construction", function()
    it("zeros creates array with correct shape", function()
        local a = luna.compute.zeros({3, 3})
        local s = a:getShape()
        expect_equal(3, s[1])
        expect_equal(3, s[2])
    end)

    it("zeros creates array with correct size", function()
        local a = luna.compute.zeros({3, 3})
        expect_equal(9, a:getSize())
    end)

    it("zeros creates array with correct dimensions", function()
        local a = luna.compute.zeros({3, 3})
        expect_equal(2, a:getDimensions())
    end)

    it("zeros default dtype is float32", function()
        local a = luna.compute.zeros({2, 2})
        expect_equal("float32", a:getDataType())
    end)

    it("zeros elements are all zero", function()
        local a = luna.compute.zeros({3})
        for i = 1, 3 do
            expect_near(0.0, a:get(i), 1e-5)
        end
    end)

    it("ones creates array with all elements 1.0", function()
        local a = luna.compute.ones({2, 3})
        for i = 1, 2 do
            for j = 1, 3 do
                expect_near(1.0, a:get(i, j), 1e-5)
            end
        end
    end)

    it("ones has correct shape", function()
        local a = luna.compute.ones({2, 3})
        expect_equal(6, a:getSize())
        expect_equal(2, a:getDimensions())
    end)

    it("range produces correct sequence", function()
        local a = luna.compute.range(1, 4)
        expect_equal(3, a:getSize())
        expect_near(1.0, a:get(1), 1e-5)
        expect_near(2.0, a:get(2), 1e-5)
        expect_near(3.0, a:get(3), 1e-5)
    end)

    it("range with step produces correct sequence", function()
        local a = luna.compute.range(0, 10, 2)
        expect_equal(5, a:getSize())
        expect_near(0.0, a:get(1), 1e-5)
        expect_near(2.0, a:get(2), 1e-5)
        expect_near(4.0, a:get(3), 1e-5)
        expect_near(6.0, a:get(4), 1e-5)
        expect_near(8.0, a:get(5), 1e-5)
    end)

    it("fromTable creates 1D array", function()
        local a = luna.compute.fromTable({10, 20, 30})
        expect_equal(3, a:getSize())
        expect_near(10.0, a:get(1), 1e-5)
        expect_near(20.0, a:get(2), 1e-5)
        expect_near(30.0, a:get(3), 1e-5)
    end)

    it("fromTable with shape reshapes", function()
        local a = luna.compute.fromTable({1, 2, 3, 4}, {2, 2})
        expect_equal(4, a:getSize())
        expect_equal(2, a:getDimensions())
        expect_near(1.0, a:get(1, 1), 1e-5)
        expect_near(2.0, a:get(1, 2), 1e-5)
        expect_near(3.0, a:get(2, 1), 1e-5)
        expect_near(4.0, a:get(2, 2), 1e-5)
    end)

    it("newArray creates zero-initialized array", function()
        local a = luna.compute.newArray({2, 2})
        expect_equal(4, a:getSize())
        expect_near(0.0, a:get(1, 1), 1e-5)
    end)

    it("float64 dtype works", function()
        local a = luna.compute.zeros({3}, "float64")
        expect_equal("float64", a:getDataType())
    end)

    it("int32 dtype works", function()
        local a = luna.compute.zeros({3}, "int32")
        expect_equal("int32", a:getDataType())
    end)

    it("3D array construction", function()
        local a = luna.compute.zeros({2, 3, 4})
        expect_equal(3, a:getDimensions())
        expect_equal(24, a:getSize())
        local s = a:getShape()
        expect_equal(2, s[1])
        expect_equal(3, s[2])
        expect_equal(4, s[3])
    end)
end)

-- =========================================================================
-- 3. Element access
-- =========================================================================
describe("element access", function()
    it("1D get and set", function()
        local a = luna.compute.zeros({5})
        a:set(1, 5.0)
        a:set(3, 7.5)
        expect_near(5.0, a:get(1), 1e-5)
        expect_near(0.0, a:get(2), 1e-5)
        expect_near(7.5, a:get(3), 1e-5)
    end)

    it("2D get and set", function()
        local a = luna.compute.zeros({3, 4})
        a:set(2, 3, 7.0)
        expect_near(7.0, a:get(2, 3), 1e-5)
        expect_near(0.0, a:get(1, 1), 1e-5)
    end)

    it("3D get and set", function()
        local a = luna.compute.zeros({2, 3, 4})
        a:set(1, 2, 3, 99.0)
        expect_near(99.0, a:get(1, 2, 3), 1e-5)
        expect_near(0.0, a:get(1, 1, 1), 1e-5)
    end)

    it("toTable returns flat table", function()
        local a = luna.compute.fromTable({10, 20, 30, 40}, {2, 2})
        local t = a:toTable()
        expect_equal(4, #t)
        expect_near(10.0, t[1], 1e-5)
        expect_near(20.0, t[2], 1e-5)
        expect_near(30.0, t[3], 1e-5)
        expect_near(40.0, t[4], 1e-5)
    end)

    it("set overwrites previous value", function()
        local a = luna.compute.zeros({3})
        a:set(2, 100.0)
        expect_near(100.0, a:get(2), 1e-5)
        a:set(2, 200.0)
        expect_near(200.0, a:get(2), 1e-5)
    end)
end)

-- =========================================================================
-- 4. Inspection
-- =========================================================================
describe("inspection", function()
    it("getShape matches constructor", function()
        local a = luna.compute.zeros({4, 5})
        local s = a:getShape()
        expect_equal(4, s[1])
        expect_equal(5, s[2])
    end)

    it("getDimensions for 1D", function()
        local a = luna.compute.zeros({10})
        expect_equal(1, a:getDimensions())
    end)

    it("getDimensions for 3D", function()
        local a = luna.compute.zeros({2, 3, 4})
        expect_equal(3, a:getDimensions())
    end)

    it("getSize is product of shape", function()
        local a = luna.compute.zeros({3, 4, 5})
        expect_equal(60, a:getSize())
    end)

    it("isOnGPU always returns false", function()
        local a = luna.compute.zeros({3})
        expect_false(a:isOnGPU())
    end)

    it("getDataType returns dtype name", function()
        local a = luna.compute.ones({2}, "float64")
        expect_equal("float64", a:getDataType())
    end)
end)

-- =========================================================================
-- 5. Arithmetic
-- =========================================================================
describe("arithmetic", function()
    it("add two arrays element-wise", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local b = luna.compute.fromTable({4, 5, 6})
        local c = a:add(b)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(7.0, c:get(2), 1e-5)
        expect_near(9.0, c:get(3), 1e-5)
    end)

    it("add scalar to array", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local c = a:add(10)
        expect_near(11.0, c:get(1), 1e-5)
        expect_near(12.0, c:get(2), 1e-5)
        expect_near(13.0, c:get(3), 1e-5)
    end)

    it("add does not modify original", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local _ = a:add(10)
        expect_near(1.0, a:get(1), 1e-5)
        expect_near(2.0, a:get(2), 1e-5)
        expect_near(3.0, a:get(3), 1e-5)
    end)

    it("sub arrays element-wise", function()
        local a = luna.compute.fromTable({10, 20, 30})
        local b = luna.compute.fromTable({1, 2, 3})
        local c = a:sub(b)
        expect_near(9.0, c:get(1), 1e-5)
        expect_near(18.0, c:get(2), 1e-5)
        expect_near(27.0, c:get(3), 1e-5)
    end)

    it("sub scalar", function()
        local a = luna.compute.fromTable({10, 20, 30})
        local c = a:sub(5)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(15.0, c:get(2), 1e-5)
        expect_near(25.0, c:get(3), 1e-5)
    end)

    it("mul arrays element-wise", function()
        local a = luna.compute.fromTable({2, 3, 4})
        local b = luna.compute.fromTable({5, 6, 7})
        local c = a:mul(b)
        expect_near(10.0, c:get(1), 1e-5)
        expect_near(18.0, c:get(2), 1e-5)
        expect_near(28.0, c:get(3), 1e-5)
    end)

    it("mul scalar", function()
        local a = luna.compute.fromTable({2, 3, 4})
        local c = a:mul(3)
        expect_near(6.0, c:get(1), 1e-5)
        expect_near(9.0, c:get(2), 1e-5)
        expect_near(12.0, c:get(3), 1e-5)
    end)

    it("div arrays element-wise", function()
        local a = luna.compute.fromTable({10, 20, 30})
        local b = luna.compute.fromTable({2, 4, 5})
        local c = a:div(b)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(5.0, c:get(2), 1e-5)
        expect_near(6.0, c:get(3), 1e-5)
    end)

    it("div scalar", function()
        local a = luna.compute.fromTable({10, 20, 30})
        local c = a:div(2)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(10.0, c:get(2), 1e-5)
        expect_near(15.0, c:get(3), 1e-5)
    end)

    it("pow raises elements to power", function()
        local a = luna.compute.fromTable({2, 3, 4})
        local c = a:pow(2)
        expect_near(4.0, c:get(1), 1e-5)
        expect_near(9.0, c:get(2), 1e-5)
        expect_near(16.0, c:get(3), 1e-5)
    end)

    it("sqrt of perfect squares", function()
        local a = luna.compute.fromTable({4, 9, 16, 25})
        local c = a:sqrt()
        expect_near(2.0, c:get(1), 1e-5)
        expect_near(3.0, c:get(2), 1e-5)
        expect_near(4.0, c:get(3), 1e-5)
        expect_near(5.0, c:get(4), 1e-5)
    end)

    it("abs of mixed values", function()
        local a = luna.compute.fromTable({-3, 0, 5, -1.5})
        local c = a:abs()
        expect_near(3.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(5.0, c:get(3), 1e-5)
        expect_near(1.5, c:get(4), 1e-5)
    end)

    it("neg negates elements", function()
        local a = luna.compute.fromTable({1, -2, 3})
        local c = a:neg()
        expect_near(-1.0, c:get(1), 1e-5)
        expect_near(2.0, c:get(2), 1e-5)
        expect_near(-3.0, c:get(3), 1e-5)
    end)

    it("clamp clips values to range", function()
        local a = luna.compute.fromTable({-5, 0, 3, 10, 15})
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
describe("comparison", function()
    it("eq returns 1.0 for equal elements", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local b = luna.compute.fromTable({1, 9, 3})
        local c = a:eq(b)
        expect_near(1.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
    end)

    it("eq with scalar", function()
        local a = luna.compute.fromTable({1, 2, 2, 3})
        local c = a:eq(2)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
        expect_near(0.0, c:get(4), 1e-5)
    end)

    it("neq returns 1.0 for unequal elements", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local b = luna.compute.fromTable({1, 9, 3})
        local c = a:neq(b)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)

    it("gt returns 1.0 where a > b", function()
        local a = luna.compute.fromTable({1, 5, 3})
        local b = luna.compute.fromTable({2, 3, 3})
        local c = a:gt(b)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)

    it("gt with scalar", function()
        local a = luna.compute.fromTable({1, 5, 3})
        local c = a:gt(2)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
    end)

    it("lt returns 1.0 where a < b", function()
        local a = luna.compute.fromTable({1, 5, 3})
        local c = a:lt(3)
        expect_near(1.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)

    it("gte returns 1.0 where a >= b", function()
        local a = luna.compute.fromTable({1, 3, 5})
        local c = a:gte(3)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
    end)

    it("lte returns 1.0 where a <= b", function()
        local a = luna.compute.fromTable({1, 3, 5})
        local c = a:lte(3)
        expect_near(1.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)
end)

-- =========================================================================
-- 7. Masking
-- =========================================================================
describe("masking", function()
    it("threshold returns 1.0 where >= val", function()
        local a = luna.compute.fromTable({0.2, 0.5, 0.8, 1.0})
        local c = a:threshold(0.5)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
        expect_near(1.0, c:get(4), 1e-5)
    end)

    it("where selects from two arrays based on condition", function()
        local cond = luna.compute.fromTable({1, 0, 1, 0})
        local a = luna.compute.fromTable({10, 20, 30, 40})
        local b = luna.compute.fromTable({100, 200, 300, 400})
        -- where(mask, on_true_self, on_false_other)
        -- called on the "true" array: a:where(cond, b)
        -- but the API signature is: mask:where(if_true, if_false)
        -- actually: this.where(mask, other) where mask selects this(1) or other(0)
        -- Let's verify: ops::where_mask(mask, this, other)
        -- Lua: this:where(mask, other) => where_mask(mask, this, other)
        -- So a:where(cond, b) puts mask=cond, this=a, other=b
        -- where mask=1 → this(a), where mask=0 → other(b)
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
describe("counting", function()
    it("countNonZero counts nonzero elements", function()
        local a = luna.compute.fromTable({0, 1, 0, 3, 5})
        expect_equal(3, a:countNonZero())
    end)

    it("countNonZero for all zeros", function()
        local a = luna.compute.zeros({4})
        expect_equal(0, a:countNonZero())
    end)

    it("argmin returns 1-based index of minimum", function()
        local a = luna.compute.fromTable({5, 1, 3, 2})
        expect_equal(2, a:argmin())
    end)

    it("argmax returns 1-based index of maximum", function()
        local a = luna.compute.fromTable({5, 1, 3, 2})
        expect_equal(1, a:argmax())
    end)

    it("any returns true if any nonzero", function()
        local a = luna.compute.fromTable({0, 0, 1})
        expect_true(a:any())
    end)

    it("any returns false for all zeros", function()
        local a = luna.compute.zeros({3})
        expect_false(a:any())
    end)

    it("all returns true when all nonzero", function()
        local a = luna.compute.fromTable({1, 2, 3})
        expect_true(a:all())
    end)

    it("all returns false when any zero", function()
        local a = luna.compute.fromTable({1, 0, 3})
        expect_false(a:all())
    end)
end)

-- =========================================================================
-- 9. Reductions
-- =========================================================================
describe("reductions", function()
    it("sum of ones(3,3) is 9", function()
        local a = luna.compute.ones({3, 3})
        expect_near(9.0, a:sum(), 1e-5)
    end)

    it("sum of fromTable", function()
        local a = luna.compute.fromTable({1, 2, 3, 4})
        expect_near(10.0, a:sum(), 1e-5)
    end)

    it("mean of values", function()
        local a = luna.compute.fromTable({2, 4, 6})
        expect_near(4.0, a:mean(), 1e-5)
    end)

    it("min of array", function()
        local a = luna.compute.fromTable({5, 1, 3, 2})
        expect_near(1.0, a:min(), 1e-5)
    end)

    it("max of array", function()
        local a = luna.compute.fromTable({5, 1, 3, 2})
        expect_near(5.0, a:max(), 1e-5)
    end)

    it("sum along axis 1 of a 3x3 array", function()
        -- 3x3 array, sum along rows (axis 1) → each column summed
        local a = luna.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        local s = a:sum(1)
        -- sum axis=0 (Rust 0-based) → sums over rows → {12, 15, 18}
        expect_equal(3, s:getSize())
        expect_near(12.0, s:get(1), 1e-5)
        expect_near(15.0, s:get(2), 1e-5)
        expect_near(18.0, s:get(3), 1e-5)
    end)

    it("sum along axis 2 of a 3x3 array", function()
        local a = luna.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        local s = a:sum(2)
        -- sum axis=1 (Rust 0-based) → sums over cols → {6, 15, 24}
        expect_equal(3, s:getSize())
        expect_near(6.0, s:get(1), 1e-5)
        expect_near(15.0, s:get(2), 1e-5)
        expect_near(24.0, s:get(3), 1e-5)
    end)

    it("mean along axis", function()
        local a = luna.compute.fromTable({2, 4, 6, 8}, {2, 2})
        local m = a:mean(2)
        expect_equal(2, m:getSize())
        expect_near(3.0, m:get(1), 1e-5)
        expect_near(7.0, m:get(2), 1e-5)
    end)

    it("min along axis", function()
        local a = luna.compute.fromTable({3, 1, 2, 4}, {2, 2})
        local m = a:min(2)
        expect_equal(2, m:getSize())
        expect_near(1.0, m:get(1), 1e-5)
        expect_near(2.0, m:get(2), 1e-5)
    end)

    it("max along axis", function()
        local a = luna.compute.fromTable({3, 1, 2, 4}, {2, 2})
        local m = a:max(2)
        expect_equal(2, m:getSize())
        expect_near(3.0, m:get(1), 1e-5)
        expect_near(4.0, m:get(2), 1e-5)
    end)
end)

-- =========================================================================
-- 10. Shape manipulation
-- =========================================================================
describe("shape manipulation", function()
    it("reshape preserves elements", function()
        local a = luna.compute.fromTable({1, 2, 3, 4, 5, 6})
        local b = a:reshape({2, 3})
        expect_equal(6, b:getSize())
        expect_equal(2, b:getDimensions())
        -- elements in row-major order should be the same
        local t = b:toTable()
        expect_near(1.0, t[1], 1e-5)
        expect_near(6.0, t[6], 1e-5)
    end)

    it("reshape changes shape but not data", function()
        local a = luna.compute.fromTable({1, 2, 3, 4}, {2, 2})
        local b = a:reshape({4})
        expect_equal(1, b:getDimensions())
        expect_equal(4, b:getSize())
        expect_near(1.0, b:get(1), 1e-5)
        expect_near(4.0, b:get(4), 1e-5)
    end)

    it("clone produces independent copy", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local b = a:clone()
        b:set(1, 99.0)
        expect_near(1.0, a:get(1), 1e-5)
        expect_near(99.0, b:get(1), 1e-5)
    end)

    it("transpose swaps rows and cols", function()
        local a = luna.compute.fromTable({1, 2, 3, 4, 5, 6}, {2, 3})
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

    it("fill modifies in-place", function()
        local a = luna.compute.zeros({3})
        a:fill(7.0)
        expect_near(7.0, a:get(1), 1e-5)
        expect_near(7.0, a:get(2), 1e-5)
        expect_near(7.0, a:get(3), 1e-5)
    end)
end)

-- =========================================================================
-- 11. Linear algebra
-- =========================================================================
describe("linear algebra", function()
    it("matmul 2x3 * 3x2 produces 2x2", function()
        -- A = [[1,2,3],[4,5,6]]  (2x3)
        local a = luna.compute.fromTable({1,2,3, 4,5,6}, {2,3})
        -- B = [[7,8],[9,10],[11,12]]  (3x2)
        local b = luna.compute.fromTable({7,8, 9,10, 11,12}, {3,2})
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

    it("dot product of two 1D arrays", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local b = luna.compute.fromTable({4, 5, 6})
        -- dot = 1*4 + 2*5 + 3*6 = 4+10+18 = 32
        expect_near(32.0, a:dot(b), 1e-5)
    end)

    it("dot product of orthogonal vectors is zero", function()
        local a = luna.compute.fromTable({1, 0})
        local b = luna.compute.fromTable({0, 1})
        expect_near(0.0, a:dot(b), 1e-5)
    end)

    it("identity matmul preserves matrix", function()
        -- I = [[1,0],[0,1]]
        local eye = luna.compute.fromTable({1,0, 0,1}, {2,2})
        local a = luna.compute.fromTable({5,3, 2,7}, {2,2})
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
describe("bitwise operations", function()
    it("bitwiseAnd on int32 arrays", function()
        local a = luna.compute.fromTable({0xFF, 0x0F, 0xAA}, nil, "int32")
        local b = luna.compute.fromTable({0x0F, 0x0F, 0x55}, nil, "int32")
        local c = a:bitwiseAnd(b)
        expect_near(0x0F, c:get(1), 1e-5)
        expect_near(0x0F, c:get(2), 1e-5)
        expect_near(0x00, c:get(3), 1e-5)
    end)

    it("bitwiseOr on int32 arrays", function()
        local a = luna.compute.fromTable({0xF0, 0x0F}, nil, "int32")
        local b = luna.compute.fromTable({0x0F, 0x0F}, nil, "int32")
        local c = a:bitwiseOr(b)
        expect_near(0xFF, c:get(1), 1e-5)
        expect_near(0x0F, c:get(2), 1e-5)
    end)

    it("bitwiseXor on int32 arrays", function()
        local a = luna.compute.fromTable({0xFF, 0x0F}, nil, "int32")
        local b = luna.compute.fromTable({0xFF, 0x0F}, nil, "int32")
        local c = a:bitwiseXor(b)
        expect_near(0x00, c:get(1), 1e-5)
        expect_near(0x00, c:get(2), 1e-5)
    end)

    it("bitwiseNot on int32 array", function()
        local a = luna.compute.fromTable({0, 1}, nil, "int32")
        local c = a:bitwiseNot()
        -- NOT 0 = -1 (all bits set), NOT 1 = -2
        expect_near(-1, c:get(1), 1e-5)
        expect_near(-2, c:get(2), 1e-5)
    end)

    it("bitwise on float32 errors", function()
        local a = luna.compute.fromTable({1, 2})
        local b = luna.compute.fromTable({3, 4})
        local ok = pcall(function() a:bitwiseAnd(b) end)
        expect_false(ok, "bitwise on float32 should error")
    end)
end)

-- =========================================================================
-- 13. 2D Spatial operations
-- =========================================================================
describe("2D spatial operations", function()
    it("convolve2D with identity kernel", function()
        local a = luna.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        -- Identity-like: 3x3 kernel with 1 in center
        local k = luna.compute.zeros({3, 3})
        k:set(2, 2, 1.0)
        local c = a:convolve2D(k)
        -- Center element should stay 5 (edges may be clamped/zero-padded)
        expect_near(5.0, c:get(2, 2), 1e-5)
    end)

    it("dilate expands nonzero regions", function()
        local a = luna.compute.zeros({5, 5})
        a:set(3, 3, 1.0)  -- single nonzero in center
        local d = a:dilate(1)
        -- center and neighbors should be nonzero after dilation
        expect_true(d:get(3, 3) > 0, "center should be nonzero")
        expect_true(d:get(2, 3) > 0, "top neighbor should be nonzero")
        expect_true(d:get(3, 2) > 0, "left neighbor should be nonzero")
    end)

    it("erode shrinks nonzero regions", function()
        local a = luna.compute.ones({5, 5})
        a:set(1, 1, 0.0)  -- remove one corner
        local e = a:erode(1)
        -- The corner neighbors should be eroded away
        expect_near(0.0, e:get(1, 1), 1e-5)
    end)

    it("floodFill fills connected region", function()
        local a = luna.compute.zeros({3, 3})
        -- Fill from (1,1) → 0-region with value 5
        local filled = a:floodFill(1, 1, 5.0)
        -- All zeros connected to (1,1) should become 5
        expect_near(5.0, filled:get(1, 1), 1e-5)
        expect_near(5.0, filled:get(2, 2), 1e-5)
        expect_near(5.0, filled:get(3, 3), 1e-5)
    end)

    it("getRegion extracts sub-array", function()
        local a = luna.compute.fromTable({1,2,3,4, 5,6,7,8, 9,10,11,12}, {3, 4})
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

    it("setRegion stamps into array", function()
        local a = luna.compute.zeros({4, 4})
        local patch = luna.compute.fromTable({9, 8, 7, 6}, {2, 2})
        a:setRegion(2, 2, patch)
        expect_near(9.0, a:get(2, 2), 1e-5)
        expect_near(8.0, a:get(2, 3), 1e-5)
        expect_near(7.0, a:get(3, 2), 1e-5)
        expect_near(6.0, a:get(3, 3), 1e-5)
        -- Untouched regions remain zero
        expect_near(0.0, a:get(1, 1), 1e-5)
    end)
end)

-- =========================================================================
-- 14. Type system
-- =========================================================================
describe("type system", function()
    it("type() returns Array", function()
        local a = luna.compute.zeros({2})
        expect_equal("Array", a:type())
    end)

    it("typeOf Array is true", function()
        local a = luna.compute.zeros({2})
        expect_true(a:typeOf("Array"))
    end)

    it("typeOf Object is true", function()
        local a = luna.compute.zeros({2})
        expect_true(a:typeOf("Object"))
    end)

    it("typeOf Source is false", function()
        local a = luna.compute.zeros({2})
        expect_false(a:typeOf("Source"))
    end)
end)

-- =========================================================================
-- 15. Error cases
-- =========================================================================
describe("error cases", function()
    it("mismatched shapes for binary ops error", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local b = luna.compute.fromTable({1, 2})
        local ok = pcall(function() a:add(b) end)
        expect_false(ok, "mismatched shapes should error")
    end)

    it("reshape with wrong element count errors", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local ok = pcall(function() a:reshape({2, 2}) end)
        expect_false(ok, "reshape with wrong count should error")
    end)

    it("empty shape errors", function()
        local ok = pcall(function() luna.compute.zeros({}) end)
        expect_false(ok, "empty shape should error")
    end)

    it("negative shape dimension errors", function()
        local ok = pcall(function() luna.compute.zeros({-1}) end)
        expect_false(ok, "negative shape should error")
    end)

    it("transpose on non-2D errors", function()
        local a = luna.compute.zeros({3})
        local ok = pcall(function() a:transpose() end)
        expect_false(ok, "transpose on 1D should error")
    end)

    it("unknown dtype errors", function()
        local ok = pcall(function() luna.compute.zeros({3}, "float16") end)
        expect_false(ok, "unknown dtype should error")
    end)

    it("matmul with incompatible shapes errors", function()
        local a = luna.compute.fromTable({1, 2, 3, 4}, {2, 2})
        local b = luna.compute.fromTable({1, 2, 3}, {3, 1})
        local ok = pcall(function() a:matmul(b) end)
        expect_false(ok, "matmul shape mismatch should error")
    end)

    it("dot on mismatched sizes errors", function()
        local a = luna.compute.fromTable({1, 2, 3})
        local b = luna.compute.fromTable({1, 2})
        local ok = pcall(function() a:dot(b) end)
        expect_false(ok, "dot size mismatch should error")
    end)
end)

-- =========================================================================
-- Bitwise shift
-- =========================================================================
describe("bitwise shift", function()
    it("bitwiseLShift shifts left", function()
        local a = luna.compute.fromTable({1, 2, 4}, {3}, "int32")
        local r = a:bitwiseLShift(2)
        expect_equal(4, r:get(1))
        expect_equal(8, r:get(2))
        expect_equal(16, r:get(3))
    end)

    it("bitwiseRShift shifts right", function()
        local a = luna.compute.fromTable({16, 8, 4}, {3}, "int32")
        local r = a:bitwiseRShift(2)
        expect_equal(4, r:get(1))
        expect_equal(2, r:get(2))
        expect_equal(1, r:get(3))
    end)
end)

-- =========================================================================
-- Summary
-- =========================================================================
test_summary()
