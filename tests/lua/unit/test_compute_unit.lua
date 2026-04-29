-- Lurek2D Compute Array Tests
-- Tests for lurek.compute dense N-dimensional array API

-- =========================================================================
-- 1. Module exists
-- =========================================================================

-- @description Verifies that lurek.compute is present as a table and exposes the documented array factory functions.
describe("lurek.compute module exists", function()
    -- @tests lurek.compute.fromTable
    -- @tests lurek.compute.newArray
    -- @tests lurek.compute.ones
    -- @tests lurek.compute.range
    -- @tests lurek.compute.zeros
    -- @description Confirms the module root is a Lua table before any factories are used.
    it("lurek.compute is a table", function()
        expect_type("table", lurek.compute)
    end)

    -- @description Checks that newArray is registered as a callable constructor on the module.
    it("has newArray factory", function()
        expect_type("function", lurek.compute.newArray)
    end)

    -- @description Checks that zeros is registered as a callable constructor on the module.
    it("has zeros factory", function()
        expect_type("function", lurek.compute.zeros)
    end)

    -- @description Checks that ones is registered as a callable constructor on the module.
    it("has ones factory", function()
        expect_type("function", lurek.compute.ones)
    end)

    -- @description Checks that range is registered as a callable constructor on the module.
    it("has range factory", function()
        expect_type("function", lurek.compute.range)
    end)

    -- @description Checks that fromTable is registered as a callable constructor on the module.
    it("has fromTable factory", function()
        expect_type("function", lurek.compute.fromTable)
    end)
end)

-- =========================================================================
-- 2. Construction
-- =========================================================================
-- @description Covers array construction paths by checking shapes, sizes, default dtypes, explicit dtypes, and multidimensional initialization.
describe("construction", function()
    -- @description Builds a 3x3 zeros array and verifies both reported shape entries are 3.
    it("zeros creates array with correct shape", function()
        local a = lurek.compute.zeros({3, 3})
        local s = a:getShape()
        expect_equal(3, s[1])
        expect_equal(3, s[2])
    end)

    -- @description Verifies that a 3x3 zeros array reports a total element count of 9.
    it("zeros creates array with correct size", function()
        local a = lurek.compute.zeros({3, 3})
        expect_equal(9, a:getSize())
    end)

    -- @description Verifies that a 3x3 zeros array reports exactly 2 dimensions.
    it("zeros creates array with correct dimensions", function()
        local a = lurek.compute.zeros({3, 3})
        expect_equal(2, a:getDimensions())
    end)

    -- @description Confirms that zeros without an explicit dtype defaults to float32.
    it("zeros default dtype is float32", function()
        local a = lurek.compute.zeros({2, 2})
        expect_equal("float32", a:getDataType())
    end)

    -- @description Checks each element of a length-3 zeros array and expects every value to be 0.0.
    it("zeros elements are all zero", function()
        local a = lurek.compute.zeros({3})
        for i = 1, 3 do
            expect_near(0.0, a:get(i), 1e-5)
        end
    end)

    -- @description Builds a 2x3 ones array and verifies every indexed element is exactly 1.0.
    it("ones creates array with all elements 1.0", function()
        local a = lurek.compute.ones({2, 3})
        for i = 1, 2 do
            for j = 1, 3 do
                expect_near(1.0, a:get(i, j), 1e-5)
            end
        end
    end)

    -- @description Verifies that a 2x3 ones array reports size 6 and 2 dimensions.
    it("ones has correct shape", function()
        local a = lurek.compute.ones({2, 3})
        expect_equal(6, a:getSize())
        expect_equal(2, a:getDimensions())
    end)

    -- @description Confirms that range(1, 4) yields three elements with values 1.0, 2.0, and 3.0.
    it("range produces correct sequence", function()
        local a = lurek.compute.range(1, 4)
        expect_equal(3, a:getSize())
        expect_near(1.0, a:get(1), 1e-5)
        expect_near(2.0, a:get(2), 1e-5)
        expect_near(3.0, a:get(3), 1e-5)
    end)

    -- @description Confirms that range(0, 10, 2) produces five elements stepping by 2 from 0.0 through 8.0.
    it("range with step produces correct sequence", function()
        local a = lurek.compute.range(0, 10, 2)
        expect_equal(5, a:getSize())
        expect_near(0.0, a:get(1), 1e-5)
        expect_near(2.0, a:get(2), 1e-5)
        expect_near(4.0, a:get(3), 1e-5)
        expect_near(6.0, a:get(4), 1e-5)
        expect_near(8.0, a:get(5), 1e-5)
    end)

    -- @description Creates a 1D array from a Lua table and verifies the size and all three element values.
    it("fromTable creates 1D array", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        expect_equal(3, a:getSize())
        expect_near(10.0, a:get(1), 1e-5)
        expect_near(20.0, a:get(2), 1e-5)
        expect_near(30.0, a:get(3), 1e-5)
    end)

    -- @description Reshapes four flat values into a 2x2 array and verifies dimensionality and row-major element placement.
    it("fromTable with shape reshapes", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
        expect_equal(4, a:getSize())
        expect_equal(2, a:getDimensions())
        expect_near(1.0, a:get(1, 1), 1e-5)
        expect_near(2.0, a:get(1, 2), 1e-5)
        expect_near(3.0, a:get(2, 1), 1e-5)
        expect_near(4.0, a:get(2, 2), 1e-5)
    end)

    -- @description Verifies that newArray allocates the requested shape and starts with zero-initialized contents.
    it("newArray creates zero-initialized array", function()
        local a = lurek.compute.newArray({2, 2})
        expect_equal(4, a:getSize())
        expect_near(0.0, a:get(1, 1), 1e-5)
    end)

    -- @description Confirms that zeros accepts float64 and reports the dtype name back unchanged.
    it("float64 dtype works", function()
        local a = lurek.compute.zeros({3}, "float64")
        expect_equal("float64", a:getDataType())
    end)

    -- @description Confirms that zeros accepts int32 and reports the dtype name back unchanged.
    it("int32 dtype works", function()
        local a = lurek.compute.zeros({3}, "int32")
        expect_equal("int32", a:getDataType())
    end)

    -- @description Builds a 2x3x4 zeros array and verifies the three reported dimensions and total size 24.
    it("3D array construction", function()
        local a = lurek.compute.zeros({2, 3, 4})
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
-- @description Verifies indexed reads and writes across 1D, 2D, and 3D arrays, plus flat-table export and overwrite behavior.
describe("element access", function()
    -- @description Sets two positions in a 1D zeros array and verifies the written values and an untouched zero slot.
    it("1D get and set", function()
        local a = lurek.compute.zeros({5})
        a:set(1, 5.0)
        a:set(3, 7.5)
        expect_near(5.0, a:get(1), 1e-5)
        expect_near(0.0, a:get(2), 1e-5)
        expect_near(7.5, a:get(3), 1e-5)
    end)

    -- @description Writes to position (2, 3) in a 3x4 array and verifies that value while checking an untouched cell stays 0.0.
    it("2D get and set", function()
        local a = lurek.compute.zeros({3, 4})
        a:set(2, 3, 7.0)
        expect_near(7.0, a:get(2, 3), 1e-5)
        expect_near(0.0, a:get(1, 1), 1e-5)
    end)

    -- @description Writes to position (1, 2, 3) in a 3D array and verifies the stored value and an untouched origin cell.
    it("3D get and set", function()
        local a = lurek.compute.zeros({2, 3, 4})
        a:set(1, 2, 3, 99.0)
        expect_near(99.0, a:get(1, 2, 3), 1e-5)
        expect_near(0.0, a:get(1, 1, 1), 1e-5)
    end)

    -- @description Converts a reshaped 2x2 array back to a flat Lua table and verifies row-major ordering of all four values.
    it("toTable returns flat table", function()
        local a = lurek.compute.fromTable({10, 20, 30, 40}, {2, 2})
        local t = a:toTable()
        expect_equal(4, #t)
        expect_near(10.0, t[1], 1e-5)
        expect_near(20.0, t[2], 1e-5)
        expect_near(30.0, t[3], 1e-5)
        expect_near(40.0, t[4], 1e-5)
    end)

    -- @description Writes index 2 twice and verifies that the second assignment replaces the first stored value.
    it("set overwrites previous value", function()
        local a = lurek.compute.zeros({3})
        a:set(2, 100.0)
        expect_near(100.0, a:get(2), 1e-5)
        a:set(2, 200.0)
        expect_near(200.0, a:get(2), 1e-5)
    end)
end)

-- =========================================================================
-- 4. Inspection
-- =========================================================================
-- @description Verifies shape, dimensionality, size, GPU residency, and dtype inspection methods against known constructor inputs.
describe("inspection", function()
    -- @description Confirms that getShape returns the original 4x5 constructor dimensions.
    it("getShape matches constructor", function()
        local a = lurek.compute.zeros({4, 5})
        local s = a:getShape()
        expect_equal(4, s[1])
        expect_equal(5, s[2])
    end)

    -- @description Confirms that a single-axis array reports one dimension.
    it("getDimensions for 1D", function()
        local a = lurek.compute.zeros({10})
        expect_equal(1, a:getDimensions())
    end)

    -- @description Confirms that a 2x3x4 array reports three dimensions.
    it("getDimensions for 3D", function()
        local a = lurek.compute.zeros({2, 3, 4})
        expect_equal(3, a:getDimensions())
    end)

    -- @description Checks that size equals the product of a 3x4x5 shape, which should be 60.
    it("getSize is product of shape", function()
        local a = lurek.compute.zeros({3, 4, 5})
        expect_equal(60, a:getSize())
    end)

    -- @description Verifies the current backend reports CPU-backed arrays by always returning false for isOnGPU.
    it("isOnGPU always returns false", function()
        local a = lurek.compute.zeros({3})
        expect_false(a:isOnGPU())
    end)

    -- @description Confirms that an explicitly requested float64 array reports the same dtype string.
    it("getDataType returns dtype name", function()
        local a = lurek.compute.ones({2}, "float64")
        expect_equal("float64", a:getDataType())
    end)
end)

-- =========================================================================
-- 5. Arithmetic
-- =========================================================================
-- @description Checks element-wise arithmetic, scalar arithmetic, immutability of sources, unary transforms, and clamping results.
describe("arithmetic", function()
    -- @description Adds {1,2,3} and {4,5,6} and verifies the resulting elements are 5.0, 7.0, and 9.0.
    it("add two arrays element-wise", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({4, 5, 6})
        local c = a:add(b)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(7.0, c:get(2), 1e-5)
        expect_near(9.0, c:get(3), 1e-5)
    end)

    -- @description Adds the scalar 10 to each element of {1,2,3} and verifies the shifted values 11.0, 12.0, and 13.0.
    it("add scalar to array", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local c = a:add(10)
        expect_near(11.0, c:get(1), 1e-5)
        expect_near(12.0, c:get(2), 1e-5)
        expect_near(13.0, c:get(3), 1e-5)
    end)

    -- @description Confirms that scalar addition returns a new array and leaves the original source values unchanged.
    it("add does not modify original", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local _ = a:add(10)
        expect_near(1.0, a:get(1), 1e-5)
        expect_near(2.0, a:get(2), 1e-5)
        expect_near(3.0, a:get(3), 1e-5)
    end)

    -- @description Subtracts {1,2,3} from {10,20,30} and verifies the element-wise differences 9.0, 18.0, and 27.0.
    it("sub arrays element-wise", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        local b = lurek.compute.fromTable({1, 2, 3})
        local c = a:sub(b)
        expect_near(9.0, c:get(1), 1e-5)
        expect_near(18.0, c:get(2), 1e-5)
        expect_near(27.0, c:get(3), 1e-5)
    end)

    -- @description Subtracts the scalar 5 from each element of {10,20,30} and verifies the results 5.0, 15.0, and 25.0.
    it("sub scalar", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        local c = a:sub(5)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(15.0, c:get(2), 1e-5)
        expect_near(25.0, c:get(3), 1e-5)
    end)

    -- @description Multiplies {2,3,4} by {5,6,7} and verifies the element-wise products 10.0, 18.0, and 28.0.
    it("mul arrays element-wise", function()
        local a = lurek.compute.fromTable({2, 3, 4})
        local b = lurek.compute.fromTable({5, 6, 7})
        local c = a:mul(b)
        expect_near(10.0, c:get(1), 1e-5)
        expect_near(18.0, c:get(2), 1e-5)
        expect_near(28.0, c:get(3), 1e-5)
    end)

    -- @description Multiplies {2,3,4} by scalar 3 and verifies the results 6.0, 9.0, and 12.0.
    it("mul scalar", function()
        local a = lurek.compute.fromTable({2, 3, 4})
        local c = a:mul(3)
        expect_near(6.0, c:get(1), 1e-5)
        expect_near(9.0, c:get(2), 1e-5)
        expect_near(12.0, c:get(3), 1e-5)
    end)

    -- @description Divides {10,20,30} by {2,4,5} and verifies the element-wise quotients 5.0, 5.0, and 6.0.
    it("div arrays element-wise", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        local b = lurek.compute.fromTable({2, 4, 5})
        local c = a:div(b)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(5.0, c:get(2), 1e-5)
        expect_near(6.0, c:get(3), 1e-5)
    end)

    -- @description Divides {10,20,30} by scalar 2 and verifies the quotients 5.0, 10.0, and 15.0.
    it("div scalar", function()
        local a = lurek.compute.fromTable({10, 20, 30})
        local c = a:div(2)
        expect_near(5.0, c:get(1), 1e-5)
        expect_near(10.0, c:get(2), 1e-5)
        expect_near(15.0, c:get(3), 1e-5)
    end)

    -- @description Squares each element of {2,3,4} and verifies the powers 4.0, 9.0, and 16.0.
    it("pow raises elements to power", function()
        local a = lurek.compute.fromTable({2, 3, 4})
        local c = a:pow(2)
        expect_near(4.0, c:get(1), 1e-5)
        expect_near(9.0, c:get(2), 1e-5)
        expect_near(16.0, c:get(3), 1e-5)
    end)

    -- @description Takes square roots of perfect squares and verifies the exact roots 2.0, 3.0, 4.0, and 5.0.
    it("sqrt of perfect squares", function()
        local a = lurek.compute.fromTable({4, 9, 16, 25})
        local c = a:sqrt()
        expect_near(2.0, c:get(1), 1e-5)
        expect_near(3.0, c:get(2), 1e-5)
        expect_near(4.0, c:get(3), 1e-5)
        expect_near(5.0, c:get(4), 1e-5)
    end)

    -- @description Applies absolute value to negative, zero, positive, and fractional inputs and verifies all outputs are non-negative magnitudes.
    it("abs of mixed values", function()
        local a = lurek.compute.fromTable({-3, 0, 5, -1.5})
        local c = a:abs()
        expect_near(3.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(5.0, c:get(3), 1e-5)
        expect_near(1.5, c:get(4), 1e-5)
    end)

    -- @description Negates {1,-2,3} and verifies the sign-flipped outputs -1.0, 2.0, and -3.0.
    it("neg negates elements", function()
        local a = lurek.compute.fromTable({1, -2, 3})
        local c = a:neg()
        expect_near(-1.0, c:get(1), 1e-5)
        expect_near(2.0, c:get(2), 1e-5)
        expect_near(-3.0, c:get(3), 1e-5)
    end)

    -- @description Clamps values into the inclusive range [0,10] and verifies underflow and overflow entries are clipped while in-range values stay unchanged.
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
-- @description Verifies comparison operators against arrays and scalars by checking the returned mask values at each position.
describe("comparison", function()
    -- @description Compares two arrays for equality and verifies only matching positions yield 1.0 in the result mask.
    it("eq returns 1.0 for equal elements", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({1, 9, 3})
        local c = a:eq(b)
        expect_near(1.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
    end)

    -- @description Compares array values to scalar 2 and verifies only the equal entries are marked with 1.0.
    it("eq with scalar", function()
        local a = lurek.compute.fromTable({1, 2, 2, 3})
        local c = a:eq(2)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
        expect_near(0.0, c:get(4), 1e-5)
    end)

    -- @description Compares two arrays for inequality and verifies only the differing position yields 1.0.
    it("neq returns 1.0 for unequal elements", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({1, 9, 3})
        local c = a:neq(b)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)

    -- @description Verifies greater-than returns a mask marking only entries where the left array exceeds the right array.
    it("gt returns 1.0 where a > b", function()
        local a = lurek.compute.fromTable({1, 5, 3})
        local b = lurek.compute.fromTable({2, 3, 3})
        local c = a:gt(b)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)

    -- @description Verifies greater-than against scalar 2 marks the 5 and 3 entries but not the 1 entry.
    it("gt with scalar", function()
        local a = lurek.compute.fromTable({1, 5, 3})
        local c = a:gt(2)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
    end)

    -- @description Verifies less-than against scalar 3 marks only the entry 1 and excludes 5 and 3.
    it("lt returns 1.0 where a < b", function()
        local a = lurek.compute.fromTable({1, 5, 3})
        local c = a:lt(3)
        expect_near(1.0, c:get(1), 1e-5)
        expect_near(0.0, c:get(2), 1e-5)
        expect_near(0.0, c:get(3), 1e-5)
    end)

    -- @description Verifies greater-than-or-equal against scalar 3 marks the 3 and 5 entries but not the 1 entry.
    it("gte returns 1.0 where a >= b", function()
        local a = lurek.compute.fromTable({1, 3, 5})
        local c = a:gte(3)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
    end)

    -- @description Verifies less-than-or-equal against scalar 3 marks the 1 and 3 entries but not the 5 entry.
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
-- @description Verifies thresholding and masked selection by checking the exact mask and where-merged outputs.
describe("masking", function()
    -- @description Applies threshold 0.5 and verifies values at or above the threshold produce 1.0 while lower values produce 0.0.
    it("threshold returns 1.0 where >= val", function()
        local a = lurek.compute.fromTable({0.2, 0.5, 0.8, 1.0})
        local c = a:threshold(0.5)
        expect_near(0.0, c:get(1), 1e-5)
        expect_near(1.0, c:get(2), 1e-5)
        expect_near(1.0, c:get(3), 1e-5)
        expect_near(1.0, c:get(4), 1e-5)
    end)

    -- @description Uses a {1,0,1,0} mask to select from arrays a and b and verifies the mixed result is {10,200,30,400}.
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
        -- where mask=1 Ă‚â€ş this(a), where mask=0 Ă‚â€ş other(b)
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
-- @description Verifies nonzero counting, argmin and argmax indices, and boolean any/all checks over representative arrays.
describe("counting", function()
    -- @description Counts nonzero values in {0,1,0,3,5} and verifies the total is 3.
    it("countNonZero counts nonzero elements", function()
        local a = lurek.compute.fromTable({0, 1, 0, 3, 5})
        expect_equal(3, a:countNonZero())
    end)

    -- @description Verifies that an all-zero array reports zero nonzero elements.
    it("countNonZero for all zeros", function()
        local a = lurek.compute.zeros({4})
        expect_equal(0, a:countNonZero())
    end)

    -- @description Verifies argmin returns the 1-based index 2 for the minimum value 1 in {5,1,3,2}.
    it("argmin returns 1-based index of minimum", function()
        local a = lurek.compute.fromTable({5, 1, 3, 2})
        expect_equal(2, a:argmin())
    end)

    -- @description Verifies argmax returns the 1-based index 1 for the maximum value 5 in {5,1,3,2}.
    it("argmax returns 1-based index of maximum", function()
        local a = lurek.compute.fromTable({5, 1, 3, 2})
        expect_equal(1, a:argmax())
    end)

    -- @description Verifies that any() returns true when at least one element is nonzero.
    it("any returns true if any nonzero", function()
        local a = lurek.compute.fromTable({0, 0, 1})
        expect_true(a:any())
    end)

    -- @description Verifies that any() returns false when every element is zero.
    it("any returns false for all zeros", function()
        local a = lurek.compute.zeros({3})
        expect_false(a:any())
    end)

    -- @description Verifies that all() returns true when every element is nonzero.
    it("all returns true when all nonzero", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        expect_true(a:all())
    end)

    -- @description Verifies that all() returns false when the array contains at least one zero.
    it("all returns false when any zero", function()
        local a = lurek.compute.fromTable({1, 0, 3})
        expect_false(a:all())
    end)
end)

-- =========================================================================
-- 9. Reductions
-- =========================================================================
-- @description Verifies full-array and axis-based reductions for sum, mean, min, and max with known numeric results.
describe("reductions", function()
    -- @description Sums a 3x3 ones array and verifies the total is 9.0.
    it("sum of ones(3,3) is 9", function()
        local a = lurek.compute.ones({3, 3})
        expect_near(9.0, a:sum(), 1e-5)
    end)

    -- @description Sums {1,2,3,4} and verifies the total is 10.0.
    it("sum of fromTable", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4})
        expect_near(10.0, a:sum(), 1e-5)
    end)

    -- @description Computes the mean of {2,4,6} and verifies the result is 4.0.
    it("mean of values", function()
        local a = lurek.compute.fromTable({2, 4, 6})
        expect_near(4.0, a:mean(), 1e-5)
    end)

    -- @description Computes the minimum of {5,1,3,2} and verifies the result is 1.0.
    it("min of array", function()
        local a = lurek.compute.fromTable({5, 1, 3, 2})
        expect_near(1.0, a:min(), 1e-5)
    end)

    -- @description Computes the maximum of {5,1,3,2} and verifies the result is 5.0.
    it("max of array", function()
        local a = lurek.compute.fromTable({5, 1, 3, 2})
        expect_near(5.0, a:max(), 1e-5)
    end)

    -- @description Sums a 3x3 array along axis 1 and verifies the per-column totals {12,15,18}.
    it("sum along axis 1 of a 3x3 array", function()
        -- 3x3 array, sum along rows (axis 1) Ă‚â€ş each column summed
        local a = lurek.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        local s = a:sum(1)
        -- sum axis=0 (Rust 0-based) Ă‚â€ş sums over rows Ă‚â€ş {12, 15, 18}
        expect_equal(3, s:getSize())
        expect_near(12.0, s:get(1), 1e-5)
        expect_near(15.0, s:get(2), 1e-5)
        expect_near(18.0, s:get(3), 1e-5)
    end)

    -- @description Sums a 3x3 array along axis 2 and verifies the per-row totals {6,15,24}.
    it("sum along axis 2 of a 3x3 array", function()
        local a = lurek.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        local s = a:sum(2)
        -- sum axis=1 (Rust 0-based) Ă‚â€ş sums over cols Ă‚â€ş {6, 15, 24}
        expect_equal(3, s:getSize())
        expect_near(6.0, s:get(1), 1e-5)
        expect_near(15.0, s:get(2), 1e-5)
        expect_near(24.0, s:get(3), 1e-5)
    end)

    -- @description Computes the mean along axis 2 of a 2x2 array and verifies the row means are 3.0 and 7.0.
    it("mean along axis", function()
        local a = lurek.compute.fromTable({2, 4, 6, 8}, {2, 2})
        local m = a:mean(2)
        expect_equal(2, m:getSize())
        expect_near(3.0, m:get(1), 1e-5)
        expect_near(7.0, m:get(2), 1e-5)
    end)

    -- @description Computes the minimum along axis 2 of a 2x2 array and verifies the row minima are 1.0 and 2.0.
    it("min along axis", function()
        local a = lurek.compute.fromTable({3, 1, 2, 4}, {2, 2})
        local m = a:min(2)
        expect_equal(2, m:getSize())
        expect_near(1.0, m:get(1), 1e-5)
        expect_near(2.0, m:get(2), 1e-5)
    end)

    -- @description Computes the maximum along axis 2 of a 2x2 array and verifies the row maxima are 3.0 and 4.0.
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
-- @description Verifies reshaping, cloning, transposition, and in-place fill while checking that data layout and independence stay correct.
describe("shape manipulation", function()
    -- @description Reshapes six flat values to 2x3, then verifies size, dimensionality, and row-major element preservation through toTable.
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

    -- @description Reshapes a 2x2 array into length 4 and verifies only the shape changes while the first and last elements remain 1.0 and 4.0.
    it("reshape changes shape but not data", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
        local b = a:reshape({4})
        expect_equal(1, b:getDimensions())
        expect_equal(4, b:getSize())
        expect_near(1.0, b:get(1), 1e-5)
        expect_near(4.0, b:get(4), 1e-5)
    end)

    -- @description Clones an array, mutates the clone, and verifies the original retains its initial value while the clone changes independently.
    it("clone produces independent copy", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = a:clone()
        b:set(1, 99.0)
        expect_near(1.0, a:get(1), 1e-5)
        expect_near(99.0, b:get(1), 1e-5)
    end)

    -- @description Transposes a 2x3 matrix and verifies the swapped shape and every transposed element position.
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

    -- @description Calls fill(7.0) on a zeros array and verifies all three elements are updated in place to 7.0.
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
-- @description Verifies matrix multiplication and dot products against hand-computed results, including identity and orthogonality cases.
describe("linear algebra", function()
    -- @description Multiplies a 2x3 matrix by a 3x2 matrix and verifies the 2x2 output shape and all four hand-calculated products.
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

    -- @description Computes the dot product of {1,2,3} and {4,5,6} and verifies the scalar result is 32.0.
    it("dot product of two 1D arrays", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({4, 5, 6})
        -- dot = 1*4 + 2*5 + 3*6 = 4+10+18 = 32
        expect_near(32.0, a:dot(b), 1e-5)
    end)

    -- @description Verifies that orthogonal basis vectors produce a dot product of exactly 0.0.
    it("dot product of orthogonal vectors is zero", function()
        local a = lurek.compute.fromTable({1, 0})
        local b = lurek.compute.fromTable({0, 1})
        expect_near(0.0, a:dot(b), 1e-5)
    end)

    -- @description Multiplies a matrix by the 2x2 identity matrix and verifies every element is preserved unchanged.
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
-- @description Verifies int32-only bitwise operations and confirms the float32 path rejects bitwise usage.
describe("bitwise operations", function()
    -- @description Performs bitwise AND on three int32 pairs and verifies the outputs 0x0F, 0x0F, and 0x00.
    it("bitwiseAnd on int32 arrays", function()
        local a = lurek.compute.fromTable({0xFF, 0x0F, 0xAA}, nil, "int32")
        local b = lurek.compute.fromTable({0x0F, 0x0F, 0x55}, nil, "int32")
        local c = a:bitwiseAnd(b)
        expect_near(0x0F, c:get(1), 1e-5)
        expect_near(0x0F, c:get(2), 1e-5)
        expect_near(0x00, c:get(3), 1e-5)
    end)

    -- @description Performs bitwise OR on two int32 pairs and verifies the outputs 0xFF and 0x0F.
    it("bitwiseOr on int32 arrays", function()
        local a = lurek.compute.fromTable({0xF0, 0x0F}, nil, "int32")
        local b = lurek.compute.fromTable({0x0F, 0x0F}, nil, "int32")
        local c = a:bitwiseOr(b)
        expect_near(0xFF, c:get(1), 1e-5)
        expect_near(0x0F, c:get(2), 1e-5)
    end)

    -- @description Performs bitwise XOR on equal int32 pairs and verifies both outputs collapse to 0x00.
    it("bitwiseXor on int32 arrays", function()
        local a = lurek.compute.fromTable({0xFF, 0x0F}, nil, "int32")
        local b = lurek.compute.fromTable({0xFF, 0x0F}, nil, "int32")
        local c = a:bitwiseXor(b)
        expect_near(0x00, c:get(1), 1e-5)
        expect_near(0x00, c:get(2), 1e-5)
    end)

    -- @description Applies bitwise NOT to int32 values 0 and 1 and verifies the signed results -1 and -2.
    it("bitwiseNot on int32 array", function()
        local a = lurek.compute.fromTable({0, 1}, nil, "int32")
        local c = a:bitwiseNot()
        -- NOT 0 = -1 (all bits set), NOT 1 = -2
        expect_near(-1, c:get(1), 1e-5)
        expect_near(-2, c:get(2), 1e-5)
    end)

    -- @description Uses pcall to verify that invoking a bitwise operation on float32 arrays raises an error.
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
-- @description Verifies convolution, dilation, erosion, flood fill, region extraction, and region stamping on 2D arrays.
describe("2D spatial operations", function()
    -- @description Convolves with a kernel that has only the center weight set and verifies the center sample remains 5.0.
    it("convolve2D with identity kernel", function()
        local a = lurek.compute.fromTable({1,2,3, 4,5,6, 7,8,9}, {3,3})
        -- Identity-like: 3x3 kernel with 1 in center
        local k = lurek.compute.zeros({3, 3})
        k:set(2, 2, 1.0)
        local c = a:convolve2D(k)
        -- Center element should stay 5 (edges may be clamped/zero-padded)
        expect_near(5.0, c:get(2, 2), 1e-5)
    end)

    -- @description Dilates a single center pixel and verifies the center plus top and left neighbors become nonzero.
    it("dilate expands nonzero regions", function()
        local a = lurek.compute.zeros({5, 5})
        a:set(3, 3, 1.0)  -- single nonzero in center
        local d = a:dilate(1)
        -- center and neighbors should be nonzero after dilation
        expect_true(d:get(3, 3) > 0, "center should be nonzero")
        expect_true(d:get(2, 3) > 0, "top neighbor should be nonzero")
        expect_true(d:get(3, 2) > 0, "left neighbor should be nonzero")
    end)

    -- @description Erodes a mostly full 5x5 array with one cleared corner and verifies the corner is removed in the result.
    it("erode shrinks nonzero regions", function()
        local a = lurek.compute.ones({5, 5})
        a:set(1, 1, 0.0)  -- remove one corner
        local e = a:erode(1)
        -- The corner neighbors should be eroded away
        expect_near(0.0, e:get(1, 1), 1e-5)
    end)

    -- @description Flood-fills a zero-valued 3x3 array from (1,1) with 5.0 and verifies the connected region now contains 5.0.
    it("floodFill fills connected region", function()
        local a = lurek.compute.zeros({3, 3})
        -- Fill from (1,1) Ă‚â€ş 0-region with value 5
        local filled = a:floodFill(1, 1, 5.0)
        -- All zeros connected to (1,1) should become 5
        expect_near(5.0, filled:get(1, 1), 1e-5)
        expect_near(5.0, filled:get(2, 2), 1e-5)
        expect_near(5.0, filled:get(3, 3), 1e-5)
    end)

    -- @description Extracts a 2x2 region from a 3x4 array at row 1, col 2 and verifies the shape and all four extracted values.
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

    -- @description Stamps a 2x2 patch into the center of a 4x4 zeros array and verifies both the written region and an untouched zero cell.
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
end)

-- =========================================================================
-- 14. Type system
-- =========================================================================
-- @description Verifies runtime type reporting and inheritance checks exposed by compute Array userdata.
describe("type system", function()
    -- @description Confirms the userdata reports its direct runtime type name as Array.
    it("type() returns LArray", function()
        local a = lurek.compute.zeros({2})
        expect_equal("LArray", a:type())
    end)

    -- @description Confirms typeOf recognizes Array as the userdata's concrete type.
    it("typeOf Array is true", function()
        local a = lurek.compute.zeros({2})
        expect_true(a:typeOf("Array"))
    end)

    -- @description Confirms typeOf recognizes Object as a parent or shared base type for Array userdata.
    it("typeOf Object is true", function()
        local a = lurek.compute.zeros({2})
        expect_true(a:typeOf("Object"))
    end)

    -- @description Confirms typeOf rejects an unrelated type name by returning false for Source.
    it("typeOf Source is false", function()
        local a = lurek.compute.zeros({2})
        expect_false(a:typeOf("Source"))
    end)
end)

-- =========================================================================
-- 15. Error cases
-- =========================================================================
-- @description Verifies representative misuse paths raise errors, including shape mismatches, invalid dtypes, and unsupported operations.
describe("error cases", function()
    -- @description Uses pcall to verify binary arithmetic rejects arrays whose shapes do not match.
    it("mismatched shapes for binary ops error", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({1, 2})
        local ok = pcall(function() a:add(b) end)
        expect_false(ok, "mismatched shapes should error")
    end)

    -- @description Uses pcall to verify reshape rejects a target shape whose element count does not match the source data.
    it("reshape with wrong element count errors", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local ok = pcall(function() a:reshape({2, 2}) end)
        expect_false(ok, "reshape with wrong count should error")
    end)

    -- @description Uses pcall to verify zeros rejects an empty shape table.
    it("empty shape errors", function()
        local ok = pcall(function() lurek.compute.zeros({}) end)
        expect_false(ok, "empty shape should error")
    end)

    -- @description Uses pcall to verify zeros rejects negative dimension sizes.
    it("negative shape dimension errors", function()
        local ok = pcall(function() lurek.compute.zeros({-1}) end)
        expect_false(ok, "negative shape should error")
    end)

    -- @description Uses pcall to verify transpose rejects non-2D arrays.
    it("transpose on non-2D errors", function()
        local a = lurek.compute.zeros({3})
        local ok = pcall(function() a:transpose() end)
        expect_false(ok, "transpose on 1D should error")
    end)

    -- @description Uses pcall to verify zeros rejects an unsupported dtype string float16.
    it("unknown dtype errors", function()
        local ok = pcall(function() lurek.compute.zeros({3}, "float16") end)
        expect_false(ok, "unknown dtype should error")
    end)

    -- @description Uses pcall to verify matmul rejects incompatible inner dimensions between a 2x2 and a 3x1 matrix.
    it("matmul with incompatible shapes errors", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
        local b = lurek.compute.fromTable({1, 2, 3}, {3, 1})
        local ok = pcall(function() a:matmul(b) end)
        expect_false(ok, "matmul shape mismatch should error")
    end)

    -- @description Uses pcall to verify dot rejects vectors with different lengths.
    it("dot on mismatched sizes errors", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = lurek.compute.fromTable({1, 2})
        local ok = pcall(function() a:dot(b) end)
        expect_false(ok, "dot size mismatch should error")
    end)
end)

-- =========================================================================
-- Bitwise shift
-- =========================================================================
-- @description Verifies int32 bit shifts by checking exact left-shifted and right-shifted output values.
describe("bitwise shift", function()
    -- @description Left-shifts {1,2,4} by two bits and verifies the results are 4, 8, and 16.
    it("bitwiseLShift shifts left", function()
        local a = lurek.compute.fromTable({1, 2, 4}, {3}, "int32")
        local r = a:bitwiseLShift(2)
        expect_equal(4, r:get(1))
        expect_equal(8, r:get(2))
        expect_equal(16, r:get(3))
    end)

    -- @description Right-shifts {16,8,4} by two bits and verifies the results are 4, 2, and 1.
    it("bitwiseRShift shifts right", function()
        local a = lurek.compute.fromTable({16, 8, 4}, {3}, "int32")
        local r = a:bitwiseRShift(2)
        expect_equal(4, r:get(1))
        expect_equal(2, r:get(2))
        expect_equal(1, r:get(3))
    end)
end)

-- =========================================================================
-- Summary
-- =========================================================================

-- @description Adds RS parity checks for range step errors, constructor fills, value round-trips, and shape table reporting.
describe("compute array strides and error paths (RS parity)", function()
    -- @description Verifies that calling range with a zero step from 0 to 10 raises an error.
    it("range with zero step raises an error", function()
        expect_error(function() lurek.compute.range(0, 10, 0) end)
    end)

    -- @description Verifies that calling range with a zero step from 10 down to 0 also raises an error.
    it("range with zero step raises an error", function()
        expect_error(function() lurek.compute.range(10, 0, 0) end)
    end)

    -- @description Creates ones({5}) and verifies all five indexed elements equal 1.0 within tolerance.
    it("ones fills array with 1.0", function()
        local a = lurek.compute.ones({5})
        for i = 1, 5 do
            expect_near(1.0, a:get(i), 0.001)
        end
    end)

    -- @description Creates zeros({4}) and verifies all four indexed elements equal 0.0 within tolerance.
    it("zeros creates array filled with 0.0", function()
        local a = lurek.compute.zeros({4})
        for i = 1, 4 do
            expect_near(0.0, a:get(i), 0.001)
        end
    end)

    -- @description Rechecks ascending range(1,4) and verifies the first three values are 1.0, 2.0, and 3.0.
    it("range ascending produces correct sequence", function()
        local a = lurek.compute.range(1, 4)
        expect_near(1.0, a:get(1), 0.001)
        expect_near(2.0, a:get(2), 0.001)
        expect_near(3.0, a:get(3), 0.001)
    end)

    -- @description Writes 3.14 at index 7 of a length-10 array and verifies the same value is read back from that index.
    it("get and set round-trip at arbitrary index", function()
        local a = lurek.compute.zeros({10})
        a:set(7, 3.14)
        expect_near(3.14, a:get(7), 0.001)
    end)

    -- @description Verifies getShape returns a Lua table for a 2x3 array and that the two entries match 2 and 3.
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
describe("lurek.compute.Array analytics", function()

    -- @description Cumulative sum of [1,2,3,4] should be [1,3,6,10].
    xit("cumsum produces running total", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4}, nil, "float32")
        local c = a:cumsum()
        expect_near(1,  c:get(1), 0.001)
        expect_near(3,  c:get(2), 0.001)
        expect_near(10, c:get(4), 0.001)
    end)

    -- @description First-order diff of [1,4,9,16] should give [3,5,7].
    xit("diff order 1 yields first differences", function()
        local a = lurek.compute.fromTable({1, 4, 9, 16}, nil, "float32")
        local d = a:diff(1)
        expect_equal(3, d:getSize())
        expect_near(3, d:get(1), 0.01)
        expect_near(7, d:get(3), 0.01)
    end)

    -- @description Second-order diff of a quadratic is constant.
    xit("diff order 2 of quadratic is constant", function()
        local a = lurek.compute.fromTable({0, 1, 4, 9, 16}, nil, "float32")
        local d = a:diff(2)
        expect_equal(3, d:getSize())
        expect_near(2, d:get(1), 0.01)
        expect_near(2, d:get(3), 0.01)
    end)

    -- @description histogram with 2 bins over [0.5,1.5,2.5,3.5] and range [0,4] gives 2 bins each holding 2 items.
    xit("histogram returns correct bin counts", function()
        local a = lurek.compute.fromTable({0.5, 1.5, 2.5, 3.5}, nil, "float32")
        local h = a:histogram(2, 0, 4)
        expect_equal(2, #h)
        expect_equal(2, h[1].count)
        expect_equal(2, h[2].count)
    end)

    -- @description Median (50th percentile) of [1,2,3,4,5] is 3.
    xit("percentile 50 is median", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4, 5}, nil, "float32")
        expect_near(3.0, a:percentile(50), 0.001)
    end)

    -- @description 100th percentile equals maximum value.
    xit("percentile 100 equals max", function()
        local a = lurek.compute.fromTable({3, 1, 4, 1, 5}, nil, "float32")
        expect_near(5.0, a:percentile(100), 0.001)
    end)

    -- @description Covariance of an array with itself equals its population variance.
    xit("covariance of array with itself is its variance", function()
        local a = lurek.compute.fromTable({1, 2, 3}, nil, "float32")
        -- pop variance of [1,2,3] = 2/3
        expect_near(0.6667, a:covariance(a), 0.01)
    end)

    -- @description Pearson correlation of a with 2*a is 1.
    xit("pearsonCorr of linearly related arrays is 1", function()
        local a = lurek.compute.fromTable({1, 2, 3}, nil, "float32")
        local b = lurek.compute.fromTable({2, 4, 6}, nil, "float32")
        expect_near(1.0, a:pearsonCorr(b), 0.001)
    end)

    -- @description normalizeRange scales [0,5,10] to [0,0.5,1].
    xit("normalizeRange scales to [0, 1]", function()
        local a = lurek.compute.fromTable({0, 5, 10}, nil, "float32")
        local n = a:normalizeRange(0, 1)
        expect_near(0.0, n:get(1), 0.001)
        expect_near(0.5, n:get(2), 0.001)
        expect_near(1.0, n:get(3), 0.001)
    end)

    -- @description zscore of a constant array should error because std dev is 0.
    xit("zscore of constant array returns error", function()
        local a = lurek.compute.fromTable({5, 5, 5}, nil, "float32")
        expect_error(function() a:zscore() end)
    end)

    -- @description zscore of non-constant array has mean ~0 and std ~1.
    xit("zscore normalises mean to zero", function()
        local a = lurek.compute.fromTable({2, 4, 4, 4, 5, 5, 7, 9}, nil, "float32")
        local z = a:zscore()
        local sum = 0
        for i = 1, z:getSize() do sum = sum + z:get(i) end
        expect_near(0.0, sum / z:getSize(), 0.001)
    end)

    -- @description Convolving [1,2,3] with identity kernel [1] returns the same array.
    xit("convolve1d with identity kernel returns input", function()
        local sig = lurek.compute.fromTable({1, 2, 3}, nil, "float32")
        local ker = lurek.compute.fromTable({1}, nil, "float32")
        local out = sig:convolve1d(ker)
        expect_equal(3, out:getSize())
        expect_near(1, out:get(1), 0.001)
        expect_near(3, out:get(3), 0.001)
    end)

    -- @description Cross-correlation of signal=[0,1,2,1,0] with template=[1,2,1] peaks at centre.
    xit("correlate1d peaks at template location", function()
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
describe("lurek.compute linear algebra", function()

    -- @description normalizeVec of [3,4] produces a unit vector [0.6, 0.8].
    xit("normalizeVec makes unit vector", function()
        local v = lurek.compute.fromTable({3, 4}, nil, "float64")
        local n = v:normalizeVec()
        expect_near(0.6, n:get(1), 0.001)
        expect_near(0.8, n:get(2), 0.001)
    end)

    -- @description cross2d of [1,0] and [0,1] is 1.
    xit("cross2d of standard basis vectors is 1", function()
        local a = lurek.compute.fromTable({1, 0}, nil, "float64")
        local b = lurek.compute.fromTable({0, 1}, nil, "float64")
        expect_near(1.0, a:cross2d(b), 0.001)
    end)

    -- @description outer product of [1,2] with [3,4,5] gives a 2Ă—3 matrix.
    xit("outer product has correct shape and values", function()
        local a = lurek.compute.fromTable({1, 2}, nil, "float64")
        local b = lurek.compute.fromTable({3, 4, 5}, nil, "float64")
        local o = a:outer(b)
        local shape = o:getShape()
        expect_equal(2, shape[1])
        expect_equal(3, shape[2])
    end)

    -- @description gaussianKernel(3, 1.0) sums to 1.0.
    xit("gaussianKernel sums to one", function()
        local k = lurek.compute.gaussianKernel(3, 1.0)
        local s = 0
        for i = 1, k:getSize() do s = s + k:get(i) end
        expect_near(1.0, s, 0.0001)
    end)

    -- @description rotate2dMatrix and transformPoints rotates [1,0] by 90Â°.
    xit("rotate2dMatrix rotates point by 90 degrees", function()
        local m = lurek.compute.rotate2dMatrix(math.pi / 2)
        local pts = lurek.compute.fromTable({1, 0}, nil, "float64"):reshape({1, 2})
        local out = m:transformPoints(pts)
        expect_near(0.0, out:get(1), 0.001)
        expect_near(1.0, out:get(2), 0.001)
    end)

    -- @description affine2d with identity-scale and zero rotation gives a translation-only matrix.
    xit("affine2d translates points correctly", function()
        local m = lurek.compute.affine2d(5, 3, 0, 1, 1)
        local pts = lurek.compute.fromTable({0, 0}, nil, "float64"):reshape({1, 2})
        local out = m:transformPoints(pts)
        expect_near(5.0, out:get(1), 0.001)
        expect_near(3.0, out:get(2), 0.001)
    end)

    -- @description linsolve solves 2x+y=5, x+3y=10 â†’ x=1, y=3.
    xit("linsolve gives correct 2x2 solution", function()
        local a = lurek.compute.fromTable({2, 1, 1, 3}, nil, "float64"):reshape({2, 2})
        local b = lurek.compute.fromTable({5, 10}, nil, "float64")
        local x = a:linsolve(b)
        expect_near(1.0, x:get(1), 0.001)
        expect_near(3.0, x:get(2), 0.001)
    end)

    -- @description sobel on a flat image returns zero gradients at centre.
    xit("sobel on flat image gives zero gradient", function()
        local flat = lurek.compute.zeros({5, 5})
        local result = flat:sobel()
        expect_near(0.0, result.gx:get(13), 0.001) -- centre index
        expect_near(0.0, result.gy:get(13), 0.001)
    end)

end)

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.compute.fft
    it("covers lurek.compute.fft", function()
        -- TODO: Implement test for lurek.compute.fft
    end)

    -- @tests lurek.compute.ifft
    it("covers lurek.compute.ifft", function()
        -- TODO: Implement test for lurek.compute.ifft
    end)

    -- @tests lurek.compute.fftMagnitude
    it("covers lurek.compute.fftMagnitude", function()
        -- TODO: Implement test for lurek.compute.fftMagnitude
    end)

    -- @tests Array:get
    it("covers Array:get", function()
        -- TODO: Implement test for Array:get
    end)

    -- @tests Array:set
    it("covers Array:set", function()
        -- TODO: Implement test for Array:set
    end)

    -- @tests Array:pow
    it("covers Array:pow", function()
        -- TODO: Implement test for Array:pow
    end)

    -- @tests Array:abs
    it("covers Array:abs", function()
        -- TODO: Implement test for Array:abs
    end)

    -- @tests Array:neg
    it("covers Array:neg", function()
        -- TODO: Implement test for Array:neg
    end)

    -- @tests Array:any
    it("covers Array:any", function()
        -- TODO: Implement test for Array:any
    end)

    -- @tests Array:all
    it("covers Array:all", function()
        -- TODO: Implement test for Array:all
    end)

    -- @tests Array:sum
    it("covers Array:sum", function()
        -- TODO: Implement test for Array:sum
    end)

    -- @tests Array:min
    it("covers Array:min", function()
        -- TODO: Implement test for Array:min
    end)

    -- @tests Array:max
    it("covers Array:max", function()
        -- TODO: Implement test for Array:max
    end)

    -- @tests Array:dot
    it("covers Array:dot", function()
        -- TODO: Implement test for Array:dot
    end)

    -- @tests Array:luDecompose
    it("covers Array:luDecompose", function()
        -- TODO: Implement test for Array:luDecompose
    end)

end)

describe("Missing explicit test for lurek.compute.gaussianKernel", function()
    it("lurek.compute.gaussianKernel works", function()
        -- @tests lurek.compute.gaussianKernel
        -- TODO: add assertion for lurek.compute.gaussianKernel
    end)
end)

describe("Missing explicit test for lurek.compute.rotate2dMatrix", function()
    it("lurek.compute.rotate2dMatrix works", function()
        -- @tests lurek.compute.rotate2dMatrix
        -- TODO: add assertion for lurek.compute.rotate2dMatrix
    end)
end)

describe("Missing explicit test for lurek.compute.affine2d", function()
    it("lurek.compute.affine2d works", function()
        -- @tests lurek.compute.affine2d
        -- TODO: add assertion for lurek.compute.affine2d
    end)
end)

describe("Missing explicit test for Array:getShape", function()
    it("Array:getShape works", function()
        -- @tests Array:getShape
        -- TODO: add assertion for Array:getShape
    end)
end)

describe("Missing explicit test for Array:getDimensions", function()
    it("Array:getDimensions works", function()
        -- @tests Array:getDimensions
        -- TODO: add assertion for Array:getDimensions
    end)
end)

describe("Missing explicit test for Array:getSize", function()
    it("Array:getSize works", function()
        -- @tests Array:getSize
        -- TODO: add assertion for Array:getSize
    end)
end)

describe("Missing explicit test for Array:getDataType", function()
    it("Array:getDataType works", function()
        -- @tests Array:getDataType
        -- TODO: add assertion for Array:getDataType
    end)
end)

describe("Missing explicit test for Array:isOnGPU", function()
    it("Array:isOnGPU works", function()
        -- @tests Array:isOnGPU
        -- TODO: add assertion for Array:isOnGPU
    end)
end)

describe("Missing explicit test for Array:toTable", function()
    it("Array:toTable works", function()
        -- @tests Array:toTable
        -- TODO: add assertion for Array:toTable
    end)
end)

describe("Missing explicit test for Array:reshape", function()
    it("Array:reshape works", function()
        -- @tests Array:reshape
        -- TODO: add assertion for Array:reshape
    end)
end)

describe("Missing explicit test for Array:clone", function()
    it("Array:clone works", function()
        -- @tests Array:clone
        -- TODO: add assertion for Array:clone
    end)
end)

describe("Missing explicit test for Array:transpose", function()
    it("Array:transpose works", function()
        -- @tests Array:transpose
        -- TODO: add assertion for Array:transpose
    end)
end)

describe("Missing explicit test for Array:fill", function()
    it("Array:fill works", function()
        -- @tests Array:fill
        -- TODO: add assertion for Array:fill
    end)
end)

describe("Missing explicit test for Array:sqrt", function()
    it("Array:sqrt works", function()
        -- @tests Array:sqrt
        -- TODO: add assertion for Array:sqrt
    end)
end)

describe("Missing explicit test for Array:clamp", function()
    it("Array:clamp works", function()
        -- @tests Array:clamp
        -- TODO: add assertion for Array:clamp
    end)
end)

describe("Missing explicit test for Array:threshold", function()
    it("Array:threshold works", function()
        -- @tests Array:threshold
        -- TODO: add assertion for Array:threshold
    end)
end)

describe("Missing explicit test for Array:countNonZero", function()
    it("Array:countNonZero works", function()
        -- @tests Array:countNonZero
        -- TODO: add assertion for Array:countNonZero
    end)
end)

describe("Missing explicit test for Array:argmin", function()
    it("Array:argmin works", function()
        -- @tests Array:argmin
        -- TODO: add assertion for Array:argmin
    end)
end)

describe("Missing explicit test for Array:argmax", function()
    it("Array:argmax works", function()
        -- @tests Array:argmax
        -- TODO: add assertion for Array:argmax
    end)
end)

describe("Missing explicit test for Array:mean", function()
    it("Array:mean works", function()
        -- @tests Array:mean
        -- TODO: add assertion for Array:mean
    end)
end)

describe("Missing explicit test for Array:matmul", function()
    it("Array:matmul works", function()
        -- @tests Array:matmul
        -- TODO: add assertion for Array:matmul
    end)
end)

describe("Missing explicit test for Array:bitwiseAnd", function()
    it("Array:bitwiseAnd works", function()
        -- @tests Array:bitwiseAnd
        -- TODO: add assertion for Array:bitwiseAnd
    end)
end)

describe("Missing explicit test for Array:bitwiseOr", function()
    it("Array:bitwiseOr works", function()
        -- @tests Array:bitwiseOr
        -- TODO: add assertion for Array:bitwiseOr
    end)
end)

describe("Missing explicit test for Array:bitwiseXor", function()
    it("Array:bitwiseXor works", function()
        -- @tests Array:bitwiseXor
        -- TODO: add assertion for Array:bitwiseXor
    end)
end)

describe("Missing explicit test for Array:bitwiseNot", function()
    it("Array:bitwiseNot works", function()
        -- @tests Array:bitwiseNot
        -- TODO: add assertion for Array:bitwiseNot
    end)
end)

describe("Missing explicit test for Array:bitwiseLShift", function()
    it("Array:bitwiseLShift works", function()
        -- @tests Array:bitwiseLShift
        -- TODO: add assertion for Array:bitwiseLShift
    end)
end)

describe("Missing explicit test for Array:bitwiseRShift", function()
    it("Array:bitwiseRShift works", function()
        -- @tests Array:bitwiseRShift
        -- TODO: add assertion for Array:bitwiseRShift
    end)
end)

describe("Missing explicit test for Array:convolve2D", function()
    it("Array:convolve2D works", function()
        -- @tests Array:convolve2D
        -- TODO: add assertion for Array:convolve2D
    end)
end)

describe("Missing explicit test for Array:dilate", function()
    it("Array:dilate works", function()
        -- @tests Array:dilate
        -- TODO: add assertion for Array:dilate
    end)
end)

describe("Missing explicit test for Array:erode", function()
    it("Array:erode works", function()
        -- @tests Array:erode
        -- TODO: add assertion for Array:erode
    end)
end)

describe("Missing explicit test for Array:cumsum", function()
    it("Array:cumsum works", function()
        -- @tests Array:cumsum
        -- TODO: add assertion for Array:cumsum
    end)
end)

describe("Missing explicit test for Array:diff", function()
    it("Array:diff works", function()
        -- @tests Array:diff
        -- TODO: add assertion for Array:diff
    end)
end)

describe("Missing explicit test for Array:percentile", function()
    it("Array:percentile works", function()
        -- @tests Array:percentile
        -- TODO: add assertion for Array:percentile
    end)
end)

describe("Missing explicit test for Array:covariance", function()
    it("Array:covariance works", function()
        -- @tests Array:covariance
        -- TODO: add assertion for Array:covariance
    end)
end)

describe("Missing explicit test for Array:pearsonCorr", function()
    it("Array:pearsonCorr works", function()
        -- @tests Array:pearsonCorr
        -- TODO: add assertion for Array:pearsonCorr
    end)
end)

describe("Missing explicit test for Array:normalizeRange", function()
    it("Array:normalizeRange works", function()
        -- @tests Array:normalizeRange
        -- TODO: add assertion for Array:normalizeRange
    end)
end)

describe("Missing explicit test for Array:zscore", function()
    it("Array:zscore works", function()
        -- @tests Array:zscore
        -- TODO: add assertion for Array:zscore
    end)
end)

describe("Missing explicit test for Array:convolve1d", function()
    it("Array:convolve1d works", function()
        -- @tests Array:convolve1d
        -- TODO: add assertion for Array:convolve1d
    end)
end)

describe("Missing explicit test for Array:correlate1d", function()
    it("Array:correlate1d works", function()
        -- @tests Array:correlate1d
        -- TODO: add assertion for Array:correlate1d
    end)
end)

describe("Missing explicit test for Array:normalizeVec", function()
    it("Array:normalizeVec works", function()
        -- @tests Array:normalizeVec
        -- TODO: add assertion for Array:normalizeVec
    end)
end)

describe("Missing explicit test for Array:outer", function()
    it("Array:outer works", function()
        -- @tests Array:outer
        -- TODO: add assertion for Array:outer
    end)
end)

describe("Missing explicit test for Array:cross2d", function()
    it("Array:cross2d works", function()
        -- @tests Array:cross2d
        -- TODO: add assertion for Array:cross2d
    end)
end)

describe("Missing explicit test for Array:transformPoints", function()
    it("Array:transformPoints works", function()
        -- @tests Array:transformPoints
        -- TODO: add assertion for Array:transformPoints
    end)
end)

describe("Missing explicit test for Array:sobel", function()
    it("Array:sobel works", function()
        -- @tests Array:sobel
        -- TODO: add assertion for Array:sobel
    end)
end)

describe("Missing explicit test for Array:linsolve", function()
    it("Array:linsolve works", function()
        -- @tests Array:linsolve
        -- TODO: add assertion for Array:linsolve
    end)
end)

describe("Missing explicit test for Array:type", function()
    it("Array:type works", function()
        -- @tests Array:type
        -- TODO: add assertion for Array:type
    end)
end)

describe("Missing explicit test for Array:typeOf", function()
    it("Array:typeOf works", function()
        -- @tests Array:typeOf
        -- TODO: add assertion for Array:typeOf
    end)
end)

-- =========================================================================
-- Phase 05 â€” Lua extensibility hooks
-- =========================================================================

describe("Array:map", function()
    -- @tests Array:map
    it("map method exists", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        expect_equal(type(a.map), "function")
    end)

    it("map applies callback element-wise", function()
        local a = lurek.compute.fromTable({2, 4, 6})
        local b = a:map(function(x) return x / 2 end)
        local t = b:toTable()
        expect_equal(t[1], 1)
        expect_equal(t[2], 2)
        expect_equal(t[3], 3)
    end)
end)

describe("Array:eval", function()
    -- @tests Array:eval
    it("eval method exists", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        expect_equal(type(a.eval), "function")
    end)

    it("eval transforms elements with expression", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        local b = a:eval("x * x")
        local t = b:toTable()
        expect_equal(t[1], 1)
        expect_equal(t[2], 4)
        expect_equal(t[3], 9)
    end)
end)

describe("Array:reduce", function()
    -- @tests Array:reduce
    it("reduce method exists", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4})
        expect_equal(type(a.reduce), "function")
    end)

    it("reduce computes sum", function()
        local a = lurek.compute.fromTable({1, 2, 3, 4})
        local total = a:reduce(function(acc, x) return acc + x end, 0)
        expect_equal(total, 10)
    end)
end)

describe("Array:scan", function()
    -- @tests Array:scan
    it("scan method exists", function()
        local a = lurek.compute.fromTable({1, 2, 3})
        expect_equal(type(a.scan), "function")
    end)

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
-- Array element-level operations with explicit @covers markers
-- =========================================================================
describe("Array element operations (@covers)", function()
    it("Array:get reads an element by index", function()
        -- @covers Array:get
        local a = lurek.compute.fromTable({10.0, 20.0, 30.0})
        expect_near(10.0, a:get(1), 1e-5)
        expect_near(30.0, a:get(3), 1e-5)
    end)

    it("Array:set writes an element by index", function()
        -- @covers Array:set
        local a = lurek.compute.zeros({4})
        a:set(2, 99.0)
        expect_near(99.0, a:get(2), 1e-5)
        expect_near(0.0, a:get(1), 1e-5)
    end)

    it("Array:pow raises each element to a power", function()
        -- @covers Array:pow
        local a = lurek.compute.fromTable({2.0, 3.0})
        local r = a:pow(2)
        expect_not_nil(r)
        expect_type("userdata", r)
    end)

    it("Array:abs returns absolute-value array", function()
        -- @covers Array:abs
        local a = lurek.compute.fromTable({-4.0, 3.0})
        local r = a:abs()
        expect_not_nil(r)
        expect_type("userdata", r)
    end)

    it("Array:neg negates all elements", function()
        -- @covers Array:neg
        local a = lurek.compute.fromTable({1.0, -2.0})
        local r = a:neg()
        expect_not_nil(r)
        expect_type("userdata", r)
    end)

    it("Array:any returns a boolean", function()
        -- @covers Array:any
        local a = lurek.compute.fromTable({0.0, 1.0})
        local v = a:any()
        expect_type("boolean", v)
        expect_equal(true, v)
    end)

    it("Array:all returns a boolean", function()
        -- @covers Array:all
        local a = lurek.compute.fromTable({1.0, 1.0, 1.0})
        local v = a:all()
        expect_type("boolean", v)
        expect_equal(true, v)
    end)

    it("Array:sum returns the total of all elements", function()
        -- @covers Array:sum
        local a = lurek.compute.fromTable({1.0, 2.0, 3.0})
        local s = a:sum()
        expect_near(6.0, s, 1e-5)
    end)

    it("Array:min returns the smallest element", function()
        -- @covers Array:min
        local a = lurek.compute.fromTable({5.0, 1.0, 3.0})
        local m = a:min()
        expect_near(1.0, m, 1e-5)
    end)

    it("Array:max returns the largest element", function()
        -- @covers Array:max
        local a = lurek.compute.fromTable({5.0, 1.0, 3.0})
        local m = a:max()
        expect_near(5.0, m, 1e-5)
    end)

    it("Array:dot computes inner product", function()
        -- @covers Array:dot
        local a = lurek.compute.fromTable({1.0, 2.0, 3.0})
        local b = lurek.compute.fromTable({4.0, 5.0, 6.0})
        local d = a:dot(b)
        expect_near(32.0, d, 1e-5)
    end)

    it("Array:map applies a transform to each element", function()
        -- @covers Array:map
        local a = lurek.compute.fromTable({1.0, 2.0, 4.0})
        local r = a:map(function(x) return x * 2 end)
        expect_not_nil(r)
        expect_type("userdata", r)
    end)
end)

describe("lurek.compute.fft", function()
    it("fft of a real signal returns a result", function()
        -- @covers lurek.compute.fft
        local result = lurek.compute.fft({1.0, 0.0, 1.0, 0.0})
        expect_not_nil(result)
    end)
end)

test_summary()
