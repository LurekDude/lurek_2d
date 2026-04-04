-- Luna2D Stress Test: Data Structure Operations
-- Tests large tables, string operations, and data encoding at scale

describe("data stress: large tables", function()
    it("creates table with 10000 entries", function()
        local t = {}
        for i = 1, 10000 do
            t[i] = { x = i, y = i * 2, name = "entity_" .. i }
        end
        expect_equal(10000, #t, "table has 10000 entries")
        expect_equal(5000, t[5000].x, "middle entry is correct")
    end)

    it("sorts 5000 entries", function()
        local t = {}
        for i = 1, 5000 do
            t[i] = luna.math.random(1, 100000)
        end

        table.sort(t)

        -- Verify sorted
        local sorted = true
        for i = 2, #t do
            if t[i] < t[i - 1] then
                sorted = false
                break
            end
        end
        expect_true(sorted, "table is sorted")
    end)

    it("hash table with 5000 string keys", function()
        local t = {}
        for i = 1, 5000 do
            t["key_" .. i] = i
        end

        -- Verify lookup
        expect_equal(1, t["key_1"], "first key")
        expect_equal(5000, t["key_5000"], "last key")
        expect_equal(nil, t["key_5001"], "missing key")
    end)
end)

describe("data stress: string operations", function()
    it("builds 1000 strings", function()
        local parts = {}
        for i = 1, 1000 do
            parts[i] = string.format("item_%04d", i)
        end
        local result = table.concat(parts, ",")
        expect_true(#result > 8000, "concatenated string is long")
    end)

    it("pattern matching 1000 times", function()
        local count = 0
        local text = "Luna2D game engine version 0.4.0 built with Rust"
        for i = 1, 1000 do
            if string.find(text, "Luna2D") then
                count = count + 1
            end
        end
        expect_equal(1000, count, "all pattern matches succeeded")
    end)
end)

describe("data stress: nested structures", function()
    it("10 levels of nesting", function()
        local root = {}
        local current = root
        for depth = 1, 10 do
            current.child = { depth = depth, data = {} }
            for i = 1, 100 do
                current.child.data[i] = depth * 100 + i
            end
            current = current.child
        end

        -- Walk back up
        current = root
        local max_depth = 0
        while current.child do
            current = current.child
            max_depth = current.depth
        end
        expect_equal(10, max_depth, "reached depth 10")
    end)
end)
