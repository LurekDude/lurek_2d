-- Lurek2D Golden Test: Entity Hierarchy Operations
-- Tests entity hierarchy operations produce deterministic results.
-- @golden lurek.entity.newUniverse

describe("golden: entity spawn IDs are sequential/unique", function()
    it("10 spawned entities have unique IDs", function()
        local universe = lurek.entity.newUniverse()
        local ids = {}
        local id_set = {}

        for i = 1, 10 do
            local id = universe:spawn()
            ids[i] = id
            expect_equal(nil, id_set[id], "entity " .. i .. " ID is unique")
            id_set[id] = true
        end

        expect_equal(10, #ids, "10 entities spawned")
    end)
end)

describe("golden: entity component read-back", function()
    it("multiple component values round-trip correctly", function()
        local universe = lurek.entity.newUniverse()
        local id = universe:spawn()

        -- Write components
        universe:set(id, "x",       123.456)
        universe:set(id, "y",       -78.9)
        universe:set(id, "name",    "player")
        universe:set(id, "alive",   true)
        universe:set(id, "level",   7)

        -- Read back and verify exact values
        expect_near(123.456, universe:get(id, "x"),     0.001, "x component")
        expect_near(-78.9,   universe:get(id, "y"),     0.001, "y component")
        expect_equal("player", universe:get(id, "name"),       "name component")
        expect_equal(true,     universe:get(id, "alive"),      "alive component")
        expect_equal(7,        universe:get(id, "level"),      "level component")
    end)

    it("overwriting component reflects new value", function()
        local universe = lurek.entity.newUniverse()
        local id = universe:spawn()

        universe:set(id, "hp", 100)
        expect_equal(100, universe:get(id, "hp"), "initial hp = 100")

        universe:set(id, "hp", 75)
        expect_equal(75, universe:get(id, "hp"), "hp after damage = 75")
    end)
end)

describe("golden: entity parent-child hierarchy", function()
    it("child stores exact parent ID", function()
        local universe = lurek.entity.newUniverse()
        local parent   = universe:spawn()
        local child    = universe:spawn()

        universe:set(child, "parent", parent)
        local stored_parent = universe:get(child, "parent")
        expect_equal(parent, stored_parent, "child stores correct parent ID")
    end)

    it("3-level deep hierarchy IDs are all distinct", function()
        local universe = lurek.entity.newUniverse()
        local root     = universe:spawn()
        local mid      = universe:spawn()
        local leaf     = universe:spawn()

        universe:set(mid,  "parent", root)
        universe:set(leaf, "parent", mid)

        expect_not_nil(root, "root exists")
        expect_not_nil(mid,  "mid exists")
        expect_not_nil(leaf, "leaf exists")
        expect_true(root ~= mid,  "root != mid")
        expect_true(mid  ~= leaf, "mid != leaf")
        expect_true(root ~= leaf, "root != leaf")
    end)
end)

describe("golden: mass entity operations deterministic", function()
    it("100 entities: sum of index component == 5050", function()
        local universe = lurek.entity.newUniverse()
        local ids = {}
        for i = 1, 100 do
            local id = universe:spawn()
            universe:set(id, "idx", i)
            ids[i] = id
        end

        local total = 0
        for _, id in ipairs(ids) do
            total = total + universe:get(id, "idx")
        end
        expect_equal(5050, total, "sum 1..100 = 5050")
    end)
end)

test_summary()
