-- tests/lua/library/test_library_loot.lua
-- BDD tests for library/loot/init.lua — alias sampler, drop DSL, pity, modifier.

local loot = require("library.loot")

describe("library.loot", function()

    describe("LootTable.sample distribution", function()
        it("samples respect declared weights within ±3% over 50k draws", function()
            local rng = lurek.math.newRandomGenerator()
            rng:setSeed(424242)
            loot.setDefaultRng(rng)

            local tbl = loot.fromList({
                { id = "a", weight = 70 },
                { id = "b", weight = 20 },
                { id = "c", weight = 10 },
            })
            local hits = { a = 0, b = 0, c = 0 }
            local N = 50000
            for _ = 1, N do
                local id = tbl:sample()
                hits[id] = hits[id] + 1
            end
            expect_near(0.70, hits.a / N, 0.03)
            expect_near(0.20, hits.b / N, 0.03)
            expect_near(0.10, hits.c / N, 0.03)
        end)

        it("alias rebuilds after add/remove", function()
            local tbl = loot.newTable()
            tbl:add("x", 10)
            tbl:sample()                      -- forces build
            expect_equal(false, tbl._dirty)
            tbl:add("y", 5)
            expect_equal(true, tbl._dirty)
            tbl:sample()
            expect_equal(false, tbl._dirty)
            tbl:remove("y")
            expect_equal(true, tbl._dirty)
        end)
    end)

    describe("LootTable.sampleN unique", function()
        it("never repeats with unique=true", function()
            local tbl = loot.fromList({
                {id="a", weight=1},{id="b", weight=1},
                {id="c", weight=1},{id="d", weight=1},
            })
            local out = tbl:sampleN(4, nil, { unique = true })
            expect_length(out, 4)
            local seen = {}
            for _, id in ipairs(out) do
                expect_nil(seen[id], "duplicate "..id)
                seen[id] = true
            end
        end)

        it("errors when unique=true and n > entries", function()
            local tbl = loot.fromList({{id="a",weight=1},{id="b",weight=1}})
            expect_error(function()
                tbl:sampleN(3, nil, { unique = true })
            end)
        end)
    end)

    describe("LootTable utilities", function()
        it("probability returns normalised weight", function()
            local t = loot.fromList({{id="a",weight=30},{id="b",weight=70}})
            expect_near(0.30, t:probability("a"), 1e-9)
            expect_near(0.70, t:probability("b"), 1e-9)
            expect_equal(0, t:probability("nope"))
        end)

        it("clone produces independent copy", function()
            local t = loot.fromList({{id="a",weight=10},{id="b",weight=20}})
            local c = t:clone()
            c:add("a", 100)
            expect_equal(10,  t:weightOf("a"))
            expect_equal(110, c:weightOf("a"))
        end)

        it("merge sums weights for duplicate ids", function()
            local a = loot.fromList({{id="x",weight=5},{id="y",weight=5}})
            local b = loot.fromList({{id="x",weight=10},{id="z",weight=2}})
            local m = loot.merge(a, b)
            expect_equal(15, m:weightOf("x"))
            expect_equal(5,  m:weightOf("y"))
            expect_equal(2,  m:weightOf("z"))
        end)
    end)

    describe("DropSet", function()
        it("guarantee always emits the requested count", function()
            local drop = loot.newDrop():guarantee("recall", 3)
            local out = drop:resolve({})
            expect_length(out, 1)
            expect_equal("recall", out[1].id)
            expect_equal(3, out[1].count)
        end)

        it("when-predicate excludes nested clauses when false", function()
            local tbl = loot.fromList({{id="x",weight=1}})
            local drop = loot.newDrop()
                :guarantee("base", 1)
                :when(function(c) return c.boss end)
                    :roll(tbl, {count=2})
            local resolved = drop:resolve({ boss = false })
            expect_length(resolved, 1)
            expect_equal("base", resolved[1].id)
        end)
    end)

    describe("Pity", function()
        it("primes after threshold misses and resets on hit", function()
            local p = loot.newPity("rare", 3)
            p:notice("a"); p:notice("b"); p:notice("c")
            expect_true(p:isPrimed())
            expect_equal(3, p:getCounter())
            p:notice("rare")
            expect_false(p:isPrimed())
            expect_equal(0, p:getCounter())
        end)

        it("save/restore round-trips counter", function()
            local p = loot.newPity("rare", 5)
            p:notice("a"); p:notice("b")
            local blob = p:save()
            local p2 = loot.newPity("rare", 5):restore(blob)
            expect_equal(2, p2:getCounter())
        end)
    end)

    describe("Modifier", function()
        it("apply yields independent table — original untouched", function()
            local base = loot.fromList({{id="a",weight=10},{id="b",weight=10}})
            local mf = loot.newModifier():add("boost",
                function(e) return e.id == "a" and 5 or 1 end)
            local view = mf:apply(base, {})
            expect_equal(10, base:weightOf("a"))
            expect_equal(50, view:weightOf("a"))
            expect_equal(10, view:weightOf("b"))
        end)
    end)

    describe("error paths", function()
        it("fromToml raises on missing engine bindings", function()
            -- lurek.filesystem.read may not be wired in headless test VM — either way it must error
            -- on a path that does not exist or on missing binding.
            expect_error(function()
                loot.fromToml("nonexistent_file_for_loot_test_xyz.toml")
            end)
        end)

        it("add raises on non-positive weight", function()
            local t = loot.newTable()
            expect_error(function() t:add("x", 0) end)
            expect_error(function() t:add("x", -1) end)
        end)
    end)
end)

test_summary()
