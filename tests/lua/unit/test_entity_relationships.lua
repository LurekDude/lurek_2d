-- Lurek2D Lua BDD tests for lurek.patterns.newRelationshipManager
-- Headless: no GPU, no audio, no window.

-- @description Covers suite: lurek.patterns RelationshipManager.
describe("lurek.patterns.RelationshipManager", function()
    -- @covers lurek.patterns.newRelationshipManager
    -- @covers lurek.patterns.RelationshipManager.setValue
    -- @covers lurek.patterns.RelationshipManager.getValue
    -- @description Verifies basic numeric relationship storage.
    it("stores and retrieves numeric values between entity pairs", function()
        local rm = lurek.patterns.newRelationshipManager()
        local a, b = 1, 2
        rm:setValue(a, b, 75.0)
        expect_near(75.0, rm:getValue(a, b), 1e-5)
    end)

    -- @covers lurek.patterns.RelationshipManager.adjustValue
    -- @description Verifies that adjustValue changes the stored value by the delta.
    it("adjustValue changes the value by delta", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:setValue(1, 2, 50.0)
        rm:adjustValue(1, 2, -10.0)
        expect_near(40.0, rm:getValue(1, 2), 1e-5)
    end)

    -- @covers lurek.patterns.RelationshipManager.defineType
    -- @covers lurek.patterns.RelationshipManager.setLevel
    -- @covers lurek.patterns.RelationshipManager.getLevel
    -- @description Verifies that named relationship levels can be defined and retrieved.
    it("supports named relationship type levels", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Faction", {"enemy", "neutral", "ally"}, "neutral")
        local ok = rm:setLevel(1, 2, "Faction", "ally")
        expect_equal(true, ok)
        expect_equal("ally", rm:getLevel(1, 2, "Faction"))
    end)

    -- @covers lurek.patterns.RelationshipManager.removePair
    -- @covers lurek.patterns.RelationshipManager.pairCount
    -- @description Verifies that removePair removes both numeric and level data.
    it("removePair resets to defaults and decrements pairCount", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:setValue(1, 2, 100.0)
        expect_equal(1, rm:pairCount())
        rm:removePair(1, 2)
        expect_equal(0, rm:pairCount())
        expect_near(0.0, rm:getValue(1, 2), 1e-5)
    end)

    -- @covers lurek.patterns.RelationshipManager.typeNames
    -- @description Verifies that typeNames returns all defined relationship type names.
    it("typeNames returns all defined type names", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Friendship", {"stranger","friend","bestfriend"})
        rm:defineType("Faction", {"enemy","ally"})
        local names = rm:typeNames()
        expect_equal(2, #names)
    end)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- ECS Universe directed relationship API
-- ──────────────────────────────────────────────────────────────────────────
-- @description Covers the directed named-link methods on lurek.entity Universe.
describe("lurek.entity Universe directed relationships", function()

    -- @covers lurek.entity.addRelation
    -- @covers lurek.entity.getRelated
    -- @description Verifies basic add and retrieval of a directed named link.
    it("addRelation and getRelated round-trip", function()
        local u = lurek.entity.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "owns", e2)
        local related = u:getRelated(e1, "owns")
        expect_equal(1, #related)
        expect_equal(e2, related[1])
    end)

    -- @covers lurek.entity.hasRelation
    -- @description hasRelation returns true when the link was added.
    it("hasRelation returns true when relation exists", function()
        local u = lurek.entity.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "enemy", e2)
        expect_equal(true, u:hasRelation(e1, "enemy", e2))
    end)

    -- @covers lurek.entity.hasRelation
    -- @description hasRelation returns false before any link is added.
    it("hasRelation returns false when relation does not exist", function()
        local u = lurek.entity.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        expect_equal(false, u:hasRelation(e1, "ally", e2))
    end)

    -- @covers lurek.entity.removeRelation
    -- @description removeRelation removes only the targeted link.
    it("removeRelation removes a specific link", function()
        local u = lurek.entity.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "ally", e2)
        u:removeRelation(e1, "ally", e2)
        expect_equal(false, u:hasRelation(e1, "ally", e2))
    end)

    -- @covers lurek.entity.clearRelations
    -- @description clearRelations removes all links of the given type.
    it("clearRelations removes all links of a type", function()
        local u = lurek.entity.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        local e3 = u:spawn()
        u:addRelation(e1, "friend", e2)
        u:addRelation(e1, "friend", e3)
        u:clearRelations(e1, "friend")
        expect_equal(0, #u:getRelated(e1, "friend"))
    end)

    -- @covers lurek.entity.addRelation
    -- @description Adding the same relation twice does not create duplicates.
    it("addRelation is idempotent — no duplicate links", function()
        local u = lurek.entity.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "link", e2)
        u:addRelation(e1, "link", e2)
        expect_equal(1, #u:getRelated(e1, "link"))
    end)

    -- @covers lurek.entity.addRelation
    -- @description Directed links are one-way — the reverse is not automatically added.
    it("directed links are not symmetric", function()
        local u = lurek.entity.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "owns", e2)
        expect_equal(0, #u:getRelated(e2, "owns"))
    end)

end)
test_summary()
