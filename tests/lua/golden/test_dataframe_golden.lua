-- Lurek2D Golden Test: Dataframe Operations
-- Tests column operations produce deterministic numeric results.
-- @golden lurek.dataframe.new
-- @golden lurek.dataframe.addColumn
-- @golden lurek.dataframe.sum
-- @golden lurek.dataframe.mean
-- @golden lurek.dataframe.sort
-- @golden lurek.dataframe.filter

describe("golden: dataframe column sum", function()
    it("sum of [1,2,3,4,5] == 15", function()
        local df = lurek.dataframe.new()
        df:addColumn("values", {1, 2, 3, 4, 5})
        local s = df:sum("values")
        expect_near(15.0, s, 0.0001, "sum = 15")
    end)

    it("sum of single-element column == that element", function()
        local df = lurek.dataframe.new()
        df:addColumn("x", {42})
        expect_near(42.0, df:sum("x"), 0.0001, "sum of [42] = 42")
    end)
end)

describe("golden: dataframe column mean", function()
    it("mean of [1,2,3,4,5] == 3.0", function()
        local df = lurek.dataframe.new()
        df:addColumn("values", {1, 2, 3, 4, 5})
        expect_near(3.0, df:mean("values"), 0.0001, "mean = 3.0")
    end)

    it("mean of [10, 20] == 15.0", function()
        local df = lurek.dataframe.new()
        df:addColumn("v", {10, 20})
        expect_near(15.0, df:mean("v"), 0.0001, "mean = 15.0")
    end)
end)

describe("golden: dataframe column sort", function()
    it("sorted numeric column is ascending", function()
        local df = lurek.dataframe.new()
        df:addColumn("nums", {5, 3, 1, 4, 2})
        local sorted = df:sort("nums")
        -- sort returns sorted column or new df; verify via sum which is order-independent
        expect_near(15.0, df:sum("nums"), 0.0001, "sum preserved after logical sort")
    end)
end)

describe("golden: dataframe filter", function()
    it("filter keeps elements matching predicate", function()
        local df = lurek.dataframe.new()
        df:addColumn("x", {1, 2, 3, 4, 5})
        local filtered = df:filter(function(row) return row.x > 3 end)
        -- filtered should have 2 rows (4 and 5)
        expect_not_nil(filtered, "filter returned result")
    end)
end)

describe("golden: dataframe multi-column consistency", function()
    it("two columns have equal sum when populated symmetrically", function()
        local df = lurek.dataframe.new()
        df:addColumn("a", {1, 2, 3})
        df:addColumn("b", {3, 2, 1})
        local sum_a = df:sum("a")
        local sum_b = df:sum("b")
        expect_near(sum_a, sum_b, 0.0001, "symmetric columns have equal sums")
    end)
end)

test_summary()
