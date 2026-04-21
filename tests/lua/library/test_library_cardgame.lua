--- BDD tests for library.cardgame
--- Covers: CardTypeDef, Card, Stack, Slot, CardPool, StackManager,
---         DeckBuilder, StackHistory, CardGroup, and the module registry.

package.path = "./content/library/?/init.lua;" .. package.path

local cg = require("library.cardgame")


-- â”€â”€ Registry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises registry lifecycle operations including define, lookup, sorted name enumeration, and full reset of registered card types.
describe("Registry", function()
    -- @covers library.cardgame.defineCardType
    -- @description Verifies case: defineCardType and getCardType round-trip.
    it("defineCardType and getCardType round-trip", function()
        cg.clearCardTypes()
        local def = cg.newCardTypeDef("Fireball")
        def.category = "spell"
        def.rarity   = "rare"
        def.base_stats = { damage = 5 }
        cg.defineCardType("Fireball", def)
        local got = cg.getCardType("Fireball")
        expect_equal(got.name, "Fireball")
        expect_equal(got.category, "spell")
        expect_equal(got.base_stats.damage, 5)
    end)

    -- @description Verifies case: getCardTypeNames returns sorted list.
    it("getCardTypeNames returns sorted list", function()
        cg.clearCardTypes()
        cg.defineCardType("Zap", cg.newCardTypeDef("Zap"))
        cg.defineCardType("Arrow", cg.newCardTypeDef("Arrow"))
        local names = cg.getCardTypeNames()
        expect_equal(names[1], "Arrow")
        expect_equal(names[2], "Zap")
    end)

    -- @description Verifies case: clearCardTypes empties registry.
    it("clearCardTypes empties registry", function()
        cg.clearCardTypes()
        cg.defineCardType("X", cg.newCardTypeDef("X"))
        cg.clearCardTypes()
        expect_equal(cg.getCardType("X"), nil)
        expect_equal(#cg.getCardTypeNames(), 0)
    end)
end)

-- â”€â”€ Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies cards inherit registry defaults and support stat, tag, counter, metadata, reset, identity, and default presentation fields.
describe("Card", function()
    -- @covers library.cardgame.newCard
    -- @description Verifies case: seeds fields from registry.
    it("seeds fields from registry", function()
        cg.clearCardTypes()
        local def = cg.newCardTypeDef("Goblin")
        def.category = "creature"
        def.base_stats = { hp = 3, atk = 1 }
        def.base_tags  = { "green" }
        cg.defineCardType("Goblin", def)

        local c = cg.newCard("Goblin")
        expect_equal(c.category, "creature")
        expect_equal(c:getStat("hp"), 3)
        expect_equal(c:hasTag("green"), true)
    end)

    -- @description Verifies case: stat operations.
    it("stat operations", function()
        cg.clearCardTypes()
        local c = cg.newCard("plain")
        c:setStat("atk", 5)
        expect_equal(c:getStat("atk"), 5)
        expect_equal(c:addStat("atk", 3), 8)
        c:removeStat("atk")
        expect_equal(c:getStat("atk"), 0)
    end)

    -- @description Verifies case: tag operations.
    it("tag operations", function()
        cg.clearCardTypes()
        local c = cg.newCard("plain")
        c:addTag("flying")
        expect_equal(c:hasTag("flying"), true)
        expect_equal(c:removeTag("flying"), true)
        expect_equal(c:hasTag("flying"), false)
        expect_equal(c:removeTag("flying"), false)
    end)

    -- @description Verifies case: counter operations.
    it("counter operations", function()
        cg.clearCardTypes()
        local c = cg.newCard("plain")
        expect_equal(c:getCounter("charge"), 0)
        c:setCounter("charge", 3)
        expect_equal(c:addCounter("charge", -1), 2)
        c:removeCounter("charge")
        expect_equal(c:getCounter("charge"), 0)
    end)

    -- @description Verifies case: metadata operations.
    it("metadata operations", function()
        cg.clearCardTypes()
        local c = cg.newCard("plain")
        c:setMeta("artist", "da Vinci")
        expect_equal(c:getMeta("artist"), "da Vinci")
        expect_equal(c:getMeta("missing"), nil)
    end)

    -- @description Verifies case: resetStats restores type defaults.
    it("resetStats restores type defaults", function()
        cg.clearCardTypes()
        local def = cg.newCardTypeDef("Knight")
        def.base_stats = { hp = 10 }
        cg.defineCardType("Knight", def)
        local c = cg.newCard("Knight")
        c:setStat("hp", 999)
        c:resetStats()
        expect_equal(c:getStat("hp"), 10)
    end)

    -- @description Verifies case: unique ids.
    it("unique ids", function()
        cg.clearCardTypes()
        local a = cg.newCard("x")
        local b = cg.newCard("x")
        expect_equal(a.id ~= b.id, true)
    end)

    -- @description Verifies case: default tile dimensions.
    it("default tile dimensions", function()
        cg.clearCardTypes()
        local c = cg.newCard("x")
        expect_equal(c.tile_w, 1)
        expect_equal(c.tile_h, 1)
        expect_equal(c.face_up, false)
        expect_equal(c.tapped, false)
    end)
end)

-- â”€â”€ Stack â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers ordered stack behavior including push and pop variants, capacity, search and counting helpers, sorting, shuffling, snapshots, and zone flags.
describe("Stack", function()
    -- @covers library.cardgame.newStack
    -- @description Verifies case: push and pop from top.
    it("push and pop from top", function()
        cg.clearCardTypes()
        local s = cg.newStack("hand")
        local c1 = cg.newCard("a")
        local c2 = cg.newCard("b")
        expect_equal(s:pushTop(c1), true)
        expect_equal(s:pushTop(c2), true)
        expect_equal(s:size(), 2)
        local popped = s:popTop()
        expect_equal(popped.card_type, "b")
        expect_equal(s:size(), 1)
    end)

    -- @description Verifies case: push and pop from bottom.
    it("push and pop from bottom", function()
        cg.clearCardTypes()
        local s = cg.newStack("deck")
        s:pushTop(cg.newCard("a"))
        s:pushBottom(cg.newCard("b"))
        local popped = s:popBottom()
        expect_equal(popped.card_type, "b")
    end)

    -- @description Verifies case: capacity enforcement.
    it("capacity enforcement", function()
        cg.clearCardTypes()
        local s = cg.newStackWithCapacity("tiny", 2)
        expect_equal(s:pushTop(cg.newCard("a")), true)
        expect_equal(s:pushTop(cg.newCard("b")), true)
        expect_equal(s:isFull(), true)
        expect_equal(s:pushTop(cg.newCard("c")), false)
    end)

    -- @description Verifies case: popMany removes from top.
    it("popMany removes from top", function()
        cg.clearCardTypes()
        local s = cg.newStack("deck")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("b"))
        s:pushTop(cg.newCard("c"))
        local popped = s:popMany(2)
        expect_equal(#popped, 2)
        expect_equal(s:size(), 1)
    end)

    -- @description Verifies case: peek operations.
    it("peek operations", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("b"))
        expect_equal(s:peekTop().card_type, "b")
        expect_equal(s:peekBottom().card_type, "a")
        expect_equal(s:peekAt(1).card_type, "a")
    end)

    -- @description Verifies case: insertAt and removeAt.
    it("insertAt and removeAt", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("c"))
        s:insertAt(2, cg.newCard("b"))
        expect_equal(s:peekAt(2).card_type, "b")
        local removed = s:removeAt(2)
        expect_equal(removed.card_type, "b")
    end)

    -- @description Verifies case: moveWithin.
    it("moveWithin", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("b"))
        s:pushTop(cg.newCard("c"))
        expect_equal(s:moveWithin(1, 3), true)
        expect_equal(s:peekAt(3).card_type, "a")
    end)

    -- @description Verifies case: search by type, tag, category.
    it("search by type, tag, category", function()
        cg.clearCardTypes()
        local def_s = cg.newCardTypeDef("spell")
        def_s.category = "magic"
        cg.defineCardType("spell", def_s)
        local s = cg.newStack("z")
        local c1 = cg.newCard("spell")
        c1:addTag("fire")
        s:pushTop(c1)
        s:pushTop(cg.newCard("other"))

        expect_equal(#s:searchByType("spell"), 1)
        expect_equal(#s:searchByTag("fire"), 1)
        expect_equal(#s:searchByCategory("magic"), 1)
    end)

    -- @description Verifies case: findByType and findByTag.
    it("findByType and findByTag", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        local c = cg.newCard("target")
        c:addTag("special")
        s:pushTop(cg.newCard("filler"))
        s:pushTop(c)

        expect_equal(s:findByType("target"), 2)
        expect_equal(s:findByTag("special"), 2)
        expect_equal(s:findByType("missing"), nil)
    end)

    -- @description Verifies case: removeById and containsId.
    it("removeById and containsId", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        local c = cg.newCard("x")
        local id = c.id
        s:pushTop(c)
        expect_equal(s:containsId(id), true)
        local removed = s:removeById(id)
        expect_equal(removed.id, id)
        expect_equal(s:containsId(id), false)
    end)

    -- @description Verifies case: count by type/category/tag.
    it("count by type/category/tag", function()
        cg.clearCardTypes()
        local def = cg.newCardTypeDef("goblin")
        def.category = "creature"
        cg.defineCardType("goblin", def)
        local s = cg.newStack("z")
        local c1 = cg.newCard("goblin"); c1:addTag("green")
        local c2 = cg.newCard("goblin"); c2:addTag("green")
        s:pushTop(c1); s:pushTop(c2); s:pushTop(cg.newCard("other"))

        expect_equal(s:countByType("goblin"), 2)
        expect_equal(s:countByCategory("creature"), 2)
        expect_equal(s:countByTag("green"), 2)
    end)

    -- @description Verifies case: sort by stat ascending.
    it("sort by stat ascending", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        local c1 = cg.newCard("a"); c1:setStat("cost", 5)
        local c2 = cg.newCard("b"); c2:setStat("cost", 1)
        local c3 = cg.newCard("c"); c3:setStat("cost", 3)
        s:pushTop(c1); s:pushTop(c2); s:pushTop(c3)
        s:sortByStat("cost")
        expect_equal(s:peekAt(1):getStat("cost"), 1)
        expect_equal(s:peekAt(3):getStat("cost"), 5)
    end)

    -- @description Verifies case: sort by name.
    it("sort by name", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        local c1 = cg.newCard("c"); c1.name = "Charlie"
        local c2 = cg.newCard("a"); c2.name = "Alpha"
        s:pushTop(c1); s:pushTop(c2)
        s:sortByName()
        expect_equal(s:peekAt(1).name, "Alpha")
    end)

    -- @description Verifies case: shuffle changes order (probabilistic).
    it("shuffle changes order (probabilistic)", function()
        cg.clearCardTypes()
        math.randomseed(42)
        local s = cg.newStack("z")
        for i = 1, 20 do
            local c = cg.newCard("c" .. i)
            s:pushTop(c)
        end
        local before = {}
        for _, c in ipairs(s:items()) do before[#before+1] = c.card_type end
        s:shuffle()
        local changed = false
        for i, c in ipairs(s:items()) do
            if c.card_type ~= before[i] then changed = true break end
        end
        expect_equal(changed, true)
    end)

    -- @description Verifies case: peekTopNTypes.
    it("peekTopNTypes", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("b"))
        s:pushTop(cg.newCard("c"))
        local types = s:peekTopNTypes(2)
        expect_equal(#types, 2)
        expect_equal(types[1], "c")
        expect_equal(types[2], "b")
    end)

    -- @description Verifies case: snapshot and restore.
    it("snapshot and restore", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("b"))
        local snap = s:snapshotCards()
        s:clear()
        expect_equal(s:size(), 0)
        s:restoreCards(snap)
        expect_equal(s:size(), 2)
    end)

    -- @description Verifies case: zone properties.
    it("zone properties", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        expect_equal(s:isOrdered(), true)
        expect_equal(s:isPublic(), false)
        s:setOrdered(false)
        s:setPublic(true)
        expect_equal(s:isOrdered(), false)
        expect_equal(s:isPublic(), true)
    end)

    -- @description Verifies case: clear returns cards.
    it("clear returns cards", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("b"))
        local old = s:clear()
        expect_equal(#old, 2)
        expect_equal(s:isEmpty(), true)
    end)

    -- @description Verifies case: findByCategoryAll and findByTypeAll.
    it("findByCategoryAll and findByTypeAll", function()
        cg.clearCardTypes()
        local def = cg.newCardTypeDef("goblin")
        def.category = "creature"
        cg.defineCardType("goblin", def)
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("goblin"))
        s:pushTop(cg.newCard("goblin"))
        s:pushTop(cg.newCard("other"))
        expect_equal(#s:findByCategoryAll("creature"), 2)
        expect_equal(#s:findByTypeAll("goblin"), 2)
    end)
end)

-- â”€â”€ Slot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests slot-style containers for push and pop flow, capacity checks, tag or type predicates, and full clearing semantics.
describe("Slot", function()
    -- @covers library.cardgame.newSlot
    -- @description Verifies case: push and pop.
    it("push and pop", function()
        cg.clearCardTypes()
        local s = cg.newSlot("weapon")
        local ok = s:push(cg.newCard("sword"))
        expect_equal(ok, true)
        expect_equal(s:size(), 1)
        local card = s:pop()
        expect_equal(card.card_type, "sword")
    end)

    -- @description Verifies case: capacity enforcement.
    it("capacity enforcement", function()
        cg.clearCardTypes()
        local s = cg.newSlotWithCapacity("ring", 1)
        s:push(cg.newCard("ruby"))
        expect_equal(s:isFull(), true)
        local ok = s:push(cg.newCard("sapphire"))
        expect_equal(ok, false)
    end)

    -- @description Verifies case: has_item_with_tag and has_item_of_type.
    it("has_item_with_tag and has_item_of_type", function()
        cg.clearCardTypes()
        local s = cg.newSlot("z")
        local c = cg.newCard("bow")
        c:addTag("ranged")
        s:push(c)
        expect_equal(s:hasItemWithTag("ranged"), true)
        expect_equal(s:hasItemOfType("bow"), true)
        expect_equal(s:hasItemWithTag("melee"), false)
    end)

    -- @description Verifies case: clear returns items.
    it("clear returns items", function()
        cg.clearCardTypes()
        local s = cg.newSlot("z")
        s:push(cg.newCard("a"))
        s:push(cg.newCard("b"))
        local old = s:clear()
        expect_equal(#old, 2)
        expect_equal(s:isEmpty(), true)
    end)
end)

-- â”€â”€ CardPool â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates weighted card pools for repeated draws, unique draws, card instantiation, weight updates, name listing, and rarity-filtered pulls.
describe("CardPool", function()
    -- @covers library.cardgame.newCardPool
    -- @description Verifies case: add and draw types.
    it("add and draw types", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("loot")
        pool:add("gold", 10)
        pool:add("gem", 1)
        expect_equal(pool:size(), 2)
        expect_equal(pool:totalWeight(), 11)
        math.randomseed(1)
        local result = pool:drawTypes(5)
        expect_equal(#result, 5)
    end)

    -- @description Verifies case: draw unique types.
    it("draw unique types", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        pool:add("a", 1)
        pool:add("b", 1)
        pool:add("c", 1)
        local result = pool:drawUniqueTypes(3)
        expect_equal(#result, 3)
        -- all unique
        local seen = {}
        for _, t in ipairs(result) do
            expect_equal(seen[t], nil)
            seen[t] = true
        end
    end)

    -- @description Verifies case: draw items creates Card instances.
    it("draw items creates Card instances", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        pool:add("warrior", 5)
        math.randomseed(1)
        local items = pool:drawItems(3)
        expect_equal(#items, 3)
        expect_equal(items[1].card_type, "warrior")
    end)

    -- @description Verifies case: remove and set_weight.
    it("remove and set_weight", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        pool:add("a", 5)
        pool:add("b", 3)
        pool:setWeight("a", 10)
        expect_equal(pool:getWeight("a"), 10)
        pool:remove("b")
        expect_equal(pool:size(), 1)
    end)

    -- @description Verifies case: getTypeNames returns all types.
    it("getTypeNames returns all types", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        pool:add("x", 1)
        pool:add("y", 1)
        local names = pool:getTypeNames()
        expect_equal(#names, 2)
    end)

    -- @description Verifies case: drawByRarity filters by rarity.
    it("drawByRarity filters by rarity", function()
        cg.clearCardTypes()
        local def_c = cg.newCardTypeDef("common_card")
        def_c.rarity = "common"
        cg.defineCardType("common_card", def_c)
        local def_r = cg.newCardTypeDef("rare_card")
        def_r.rarity = "rare"
        cg.defineCardType("rare_card", def_r)

        local pool = cg.newCardPool("z")
        pool:add("common_card", 5)
        pool:add("rare_card", 5)
        math.randomseed(1)
        local result = pool:drawByRarity({ common = 2, rare = 1 })
        expect_equal(#result, 3)
    end)
end)

-- â”€â”€ StackManager â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises stack manager orchestration for creating stacks, moving top cards or typed cards, counting totals, and removing named stacks.
describe("StackManager", function()
    -- @covers library.cardgame.newStackManager
    -- @description Verifies case: create and manage stacks.
    it("create and manage stacks", function()
        cg.clearCardTypes()
        local mgr = cg.newStackManager()
        mgr:createStack("hand")
        mgr:createStackCapped("discard", 10)
        expect_equal(mgr:hasStack("hand"), true)
        expect_equal(#mgr:stackNames(), 2)
    end)

    -- @description Verifies case: moveTop transfers card.
    it("moveTop transfers card", function()
        cg.clearCardTypes()
        local mgr = cg.newStackManager()
        mgr:createStack("deck")
        mgr:createStack("hand")
        mgr:getStack("deck"):pushTop(cg.newCard("a"))
        mgr:getStack("deck"):pushTop(cg.newCard("b"))
        local card = mgr:moveTop("deck", "hand")
        expect_equal(card.card_type, "b")
        expect_equal(mgr:getStack("hand"):size(), 1)
        expect_equal(mgr:getStack("deck"):size(), 1)
    end)

    -- @description Verifies case: moveItemByType transfers first match.
    it("moveItemByType transfers first match", function()
        cg.clearCardTypes()
        local mgr = cg.newStackManager()
        mgr:createStack("src")
        mgr:createStack("dst")
        mgr:getStack("src"):pushTop(cg.newCard("x"))
        mgr:getStack("src"):pushTop(cg.newCard("target"))
        mgr:getStack("src"):pushTop(cg.newCard("y"))
        local card = mgr:moveItemByType("src", "target", "dst")
        expect_equal(card.card_type, "target")
        expect_equal(mgr:getStack("dst"):size(), 1)
    end)

    -- @description Verifies case: totalItems sums all stacks.
    it("totalItems sums all stacks", function()
        cg.clearCardTypes()
        local mgr = cg.newStackManager()
        mgr:createStack("a")
        mgr:createStack("b")
        mgr:getStack("a"):pushTop(cg.newCard("c"))
        mgr:getStack("b"):pushTop(cg.newCard("d"))
        mgr:getStack("b"):pushTop(cg.newCard("e"))
        expect_equal(mgr:totalItems(), 3)
    end)

    -- @description Verifies case: removeStack returns the stack.
    it("removeStack returns the stack", function()
        cg.clearCardTypes()
        local mgr = cg.newStackManager()
        mgr:createStack("x")
        mgr:getStack("x"):pushTop(cg.newCard("z"))
        local s = mgr:removeStack("x")
        expect_equal(s:size(), 1)
        expect_equal(mgr:hasStack("x"), false)
    end)
end)

-- â”€â”€ DeckBuilder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers deck builder recipes that add entries, expand quantities, and produce stacks populated with the expected card types.
describe("DeckBuilder", function()
    -- @covers library.cardgame.newDeckBuilder
    -- @description Verifies case: build creates stack with entries.
    it("build creates stack with entries", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("test_deck")
        db:add("fire_spell", 3)
        db:add("ice_spell", 2)
        local deck = db:build()
        expect_equal(deck:size(), 5)
        expect_equal(deck.name, "test_deck")
    end)

    -- @description Verifies case: buildNamed uses custom name.
    it("buildNamed uses custom name", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("template")
        db:add("card", 2)
        local deck = db:buildNamed("player_deck")
        expect_equal(deck.name, "player_deck")
    end)

    -- @description Verifies case: shuffle_on_build shuffles the result.
    it("shuffle_on_build shuffles the result", function()
        cg.clearCardTypes()
        math.randomseed(42)
        local db = cg.newDeckBuilder("shuffled")
        db.shuffle_on_build = true
        for i = 1, 20 do db:add("c" .. i, 1) end
        local deck = db:build()
        expect_equal(deck:size(), 20)
    end)

    -- @description Verifies case: addWith applies stat overrides and extra tags.
    it("addWith applies stat overrides and extra tags", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db:addWith("warrior", 1, { hp = 99 }, { "elite" })
        local deck = db:build()
        local c = deck:peekTop()
        expect_equal(c:getStat("hp"), 99)
        expect_equal(c:hasTag("elite"), true)
    end)

    -- @description Verifies case: validateEntries detects banned types.
    it("validateEntries detects banned types", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db:banType("banned")
        db:add("banned", 1)
        local errs = db:validateEntries()
        expect_equal(#errs > 0, true)
    end)

    -- @description Verifies case: validateEntries detects min/max size violation.
    it("validateEntries detects min/max size violation", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db.min_size = 10
        db:add("card", 3)
        local errs = db:validateEntries()
        expect_equal(#errs > 0, true)
    end)

    -- @description Verifies case: validateEntries detects missing required types.
    it("validateEntries detects missing required types", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db:requireType("must_have")
        db:add("other", 5)
        local errs = db:validateEntries()
        expect_equal(#errs > 0, true)
    end)

    -- @description Verifies case: removeBannedType removes from ban list.
    it("removeBannedType removes from ban list", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db:banType("x")
        expect_equal(db:removeBannedType("x"), true)
        expect_equal(db:removeBannedType("x"), false)
    end)
end)

-- â”€â”€ StackHistory â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: StackHistory.
describe("StackHistory", function()
    -- @description Verifies case: record and retrieve entries.
    it("record and retrieve entries", function()
        local h = cg.newStackHistory()
        h:record("deck", cg.HistoryAction.pushed("spell", "Fireball"), 5)
        h:record("deck", cg.HistoryAction.shuffled(), 5)
        expect_equal(h:len(), 2)
        expect_equal(h:last().action.kind, "shuffled")
    end)

    -- @description Verifies case: entriesFor filters by stack name.
    it("entriesFor filters by stack name", function()
        local h = cg.newStackHistory()
        h:record("deck", cg.HistoryAction.pushed("a", "A"), 1)
        h:record("hand", cg.HistoryAction.pushed("b", "B"), 1)
        h:record("deck", cg.HistoryAction.popped("a", "A"), 0)
        local deck_entries = h:entriesFor("deck")
        expect_equal(#deck_entries, 2)
    end)

    -- @description Verifies case: max_size evicts oldest entries.
    it("max_size evicts oldest entries", function()
        local h = cg.newStackHistoryWithMaxSize(3)
        for i = 1, 5 do
            h:record("s", cg.HistoryAction.custom("e" .. i), i)
        end
        expect_equal(h:len(), 3)
        expect_equal(h:entries()[1].action.label, "e3")
    end)

    -- @description Verifies case: recordCustom and clear.
    it("recordCustom and clear", function()
        local h = cg.newStackHistory()
        h:recordCustom("deck", "manual_shuffle", 10)
        expect_equal(h:len(), 1)
        expect_equal(h:last().action.kind, "custom")
        expect_equal(h:last().action.label, "manual_shuffle")
        h:clear()
        expect_equal(h:isEmpty(), true)
    end)

    -- @description Verifies case: history actions cover all variants.
    it("history actions cover all variants", function()
        local a1 = cg.HistoryAction.pushed("t", "n")
        expect_equal(a1.kind, "pushed")
        local a2 = cg.HistoryAction.popped("t", "n")
        expect_equal(a2.kind, "popped")
        local a3 = cg.HistoryAction.moved("t", "n", "a", "b")
        expect_equal(a3.kind, "moved")
        expect_equal(a3.from_stack, "a")
        local a4 = cg.HistoryAction.sorted("cost")
        expect_equal(a4.by, "cost")
        local a5 = cg.HistoryAction.cleared()
        expect_equal(a5.kind, "cleared")
        local a6 = cg.HistoryAction.built(40)
        expect_equal(a6.count, 40)
    end)
end)

-- â”€â”€ CardGroup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: CardGroup.
describe("CardGroup", function()
    -- @description Verifies case: itemsFrom collects cards by index.
    it("itemsFrom collects cards by index", function()
        cg.clearCardTypes()
        local cards = { cg.newCard("a"), cg.newCard("b"), cg.newCard("c") }
        local g = cg.newCardGroup("pair", { 1, 3 }, 10)
        local items = g:itemsFrom(cards)
        expect_equal(#items, 2)
        expect_equal(items[1].card_type, "a")
        expect_equal(items[2].card_type, "c")
        expect_equal(g.score, 10)
    end)
end)

-- â”€â”€ Analysis helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Analysis helpers.
describe("Analysis helpers", function()
    -- @description Verifies case: groupByStat buckets by integer stat value.
    it("groupByStat buckets by integer stat value", function()
        cg.clearCardTypes()
        local cards = {}
        for _, v in ipairs({3, 1, 3, 2}) do
            local c = cg.newCard("x")
            c:setStat("cost", v)
            cards[#cards+1] = c
        end
        local groups = cg.groupByStat(cards, "cost")
        expect_equal(#groups[3], 2)
        expect_equal(#groups[1], 1)
        expect_equal(#groups[2], 1)
    end)

    -- @description Verifies case: groupByTagPrefix buckets by tag suffix.
    it("groupByTagPrefix buckets by tag suffix", function()
        cg.clearCardTypes()
        local cards = {}
        for _, tag in ipairs({"suit:hearts", "suit:spades", "suit:hearts", "rank:5"}) do
            local c = cg.newCard("x")
            c:addTag(tag)
            cards[#cards+1] = c
        end
        local groups = cg.groupByTagPrefix(cards, "suit")
        expect_equal(#groups["hearts"], 2)
        expect_equal(#groups["spades"], 1)
        expect_equal(groups["rank"], nil)
    end)

    -- @description Verifies case: groupByTagPrefix ignores cards without matching prefix.
    it("groupByTagPrefix ignores cards without matching prefix", function()
        cg.clearCardTypes()
        local c = cg.newCard("x")
        c:addTag("noprefix")
        local groups = cg.groupByTagPrefix({c}, "suit")
        local count = 0
        for _ in pairs(groups) do count = count + 1 end
        expect_equal(count, 0)
    end)

    -- @description Verifies case: findNOfStat returns exact-n groups.
    it("findNOfStat returns exact-n groups", function()
        cg.clearCardTypes()
        local cards = {}
        for _, v in ipairs({5, 5, 5, 3, 3, 7}) do
            local c = cg.newCard("x")
            c:setStat("val", v)
            cards[#cards+1] = c
        end
        local groups3 = cg.findNOfStat(cards, "val", 3)
        expect_equal(#groups3, 1)
        expect_equal(#groups3[1].indices, 3)
        local groups2 = cg.findNOfStat(cards, "val", 2)
        expect_equal(#groups2, 1)
        expect_equal(#groups2[1].indices, 2)
        local groups4 = cg.findNOfStat(cards, "val", 4)
        expect_equal(#groups4, 0)
    end)

    -- @description Verifies case: findNOfStat CardGroup label includes stat name.
    it("findNOfStat CardGroup label includes stat name", function()
        cg.clearCardTypes()
        local cards = {}
        for _ = 1, 2 do
            local c = cg.newCard("x"); c:setStat("rank", 4)
            cards[#cards+1] = c
        end
        local groups = cg.findNOfStat(cards, "rank", 2)
        expect_equal(#groups, 1)
        expect_equal(groups[1].label:find("rank") ~= nil, true)
    end)

    -- @description Verifies case: findSequences finds consecutive runs.
    it("findSequences finds consecutive runs", function()
        cg.clearCardTypes()
        local cards = {}
        for _, v in ipairs({1, 2, 3, 7, 8}) do
            local c = cg.newCard("x"); c:setStat("rank", v)
            cards[#cards+1] = c
        end
        local seqs3 = cg.findSequences(cards, "rank", 3)
        expect_equal(#seqs3, 1)
        expect_equal(#seqs3[1].indices, 3)
        local seqs2 = cg.findSequences(cards, "rank", 2)
        expect_equal(#seqs2, 2)
    end)

    -- @description Verifies case: findSequences returns empty for min_run larger than any run.
    it("findSequences returns empty for min_run larger than any run", function()
        cg.clearCardTypes()
        local cards = {}
        for _, v in ipairs({1, 2, 5, 6}) do
            local c = cg.newCard("x"); c:setStat("rank", v)
            cards[#cards+1] = c
        end
        local seqs = cg.findSequences(cards, "rank", 5)
        expect_equal(#seqs, 0)
    end)

    -- @description Verifies case: findSequences on empty list returns empty.
    it("findSequences on empty list returns empty", function()
        local seqs = cg.findSequences({}, "rank", 2)
        expect_equal(#seqs, 0)
    end)
end)

-- ── ID counter ──────────────────────────────────────────────────────────

-- @description Covers ID counter inspection and session reset behavior.
describe("ID counter", function()
    -- @description Verifies case: getIdCounter returns current value.
    it("getIdCounter returns current value", function()
        cg.clearCardTypes()
        local before = cg.getIdCounter()
        cg.newCard("x")
        expect_equal(cg.getIdCounter(), before + 1)
    end)

    -- @description Verifies case: resetIdCounter resets to 1.
    it("resetIdCounter resets to 1", function()
        cg.clearCardTypes()
        cg.newCard("x")
        cg.newCard("y")
        cg.resetIdCounter()
        expect_equal(cg.getIdCounter(), 1)
        local c = cg.newCard("z")
        expect_equal(c.id, 1)
    end)

    -- @description Verifies case: IDs are sequential after reset.
    it("IDs are sequential after reset", function()
        cg.clearCardTypes()
        cg.resetIdCounter()
        local c1 = cg.newCard("a")
        local c2 = cg.newCard("b")
        expect_equal(c2.id, c1.id + 1)
    end)
end)

-- ── Search return types ─────────────────────────────────────────────────

-- @description Verifies search/find return types are consistent: searchBy* returns indices, findBy*All returns objects.
describe("Search return types", function()
    -- @description Verifies case: searchByType returns indices (numbers).
    it("searchByType returns indices (numbers)", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("a"))
        local result = s:searchByType("a")
        expect_equal(type(result[1]), "number")
        expect_equal(result[1], 1)
        expect_equal(result[2], 2)
    end)

    -- @description Verifies case: searchByTag returns indices (numbers).
    it("searchByTag returns indices (numbers)", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        local c = cg.newCard("a"); c:addTag("fire")
        s:pushTop(c)
        local result = s:searchByTag("fire")
        expect_equal(type(result[1]), "number")
        expect_equal(result[1], 1)
    end)

    -- @description Verifies case: findByTypeAll returns Card objects.
    it("findByTypeAll returns Card objects", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("goblin"))
        s:pushTop(cg.newCard("goblin"))
        local result = s:findByTypeAll("goblin")
        expect_equal(type(result[1]), "table")
        expect_equal(result[1].card_type, "goblin")
    end)

    -- @description Verifies case: findByTagAll returns Card objects.
    it("findByTagAll returns Card objects", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        local c1 = cg.newCard("a"); c1:addTag("magic")
        local c2 = cg.newCard("b"); c2:addTag("magic")
        s:pushTop(c1)
        s:pushTop(c2)
        local result = s:findByTagAll("magic")
        expect_equal(#result, 2)
        expect_equal(result[1].card_type, "a")
    end)

    -- @description Verifies case: searchByType on empty stack returns empty.
    it("searchByType on empty stack returns empty", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        expect_equal(#s:searchByType("x"), 0)
    end)

    -- @description Verifies case: findByTagAll on empty stack returns empty.
    it("findByTagAll on empty stack returns empty", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        expect_equal(#s:findByTagAll("x"), 0)
    end)
end)

-- ── CardTypeDef fields ──────────────────────────────────────────────────

-- @description Verifies CardTypeDef has all documented fields with correct defaults.
describe("CardTypeDef fields", function()
    -- @description Verifies case: newCardTypeDef has all documented fields.
    it("newCardTypeDef has all documented fields", function()
        local def = cg.newCardTypeDef("test")
        expect_equal(def.name, "test")
        expect_equal(def.category, "")
        expect_equal(def.subtype, "")
        expect_equal(def.rarity, "")
        expect_equal(type(def.base_stats), "table")
        expect_equal(type(def.base_tags), "table")
        expect_equal(type(def.metadata), "table")
        expect_equal(def.max_per_deck, nil)
    end)

    -- @description Verifies case: newCardTypeDef rejects empty name.
    it("newCardTypeDef rejects empty name", function()
        local ok, _ = pcall(cg.newCardTypeDef, "")
        expect_equal(ok, false)
    end)
end)

-- ── Empty stack / pool edge cases ───────────────────────────────────────

-- @description Tests edge cases on empty stacks, slots, and pools.
describe("Empty edge cases", function()
    -- @description Verifies case: popTop on empty stack returns nil.
    it("popTop on empty stack returns nil", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        expect_equal(s:popTop(), nil)
    end)

    -- @description Verifies case: popBottom on empty stack returns nil.
    it("popBottom on empty stack returns nil", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        expect_equal(s:popBottom(), nil)
    end)

    -- @description Verifies case: popMany on empty stack returns empty table.
    it("popMany on empty stack returns empty table", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        local result = s:popMany(5)
        expect_equal(#result, 0)
    end)

    -- @description Verifies case: peekTop on empty stack returns nil.
    it("peekTop on empty stack returns nil", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        expect_equal(s:peekTop(), nil)
    end)

    -- @description Verifies case: drawTypes from empty pool returns empty.
    it("drawTypes from empty pool returns empty", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        local result = pool:drawTypes(5)
        expect_equal(#result, 0)
    end)

    -- @description Verifies case: drawUniqueTypes from empty pool returns empty.
    it("drawUniqueTypes from empty pool returns empty", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        local result = pool:drawUniqueTypes(3)
        expect_equal(#result, 0)
    end)

    -- @description Verifies case: drawItems from empty pool returns empty.
    it("drawItems from empty pool returns empty", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        local result = pool:drawItems(3)
        expect_equal(#result, 0)
    end)

    -- @description Verifies case: Slot pop on empty returns nil.
    it("Slot pop on empty returns nil", function()
        cg.clearCardTypes()
        local s = cg.newSlot("z")
        expect_equal(s:pop(), nil)
    end)

    -- @description Verifies case: Stack clear on empty returns empty table.
    it("Stack clear on empty returns empty table", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        local result = s:clear()
        expect_equal(#result, 0)
    end)
end)

-- ── Input validation ────────────────────────────────────────────────────

-- @description Tests that constructors and mutators reject invalid inputs.
describe("Input validation", function()
    -- @description Verifies case: defineCardType rejects non-string name.
    it("defineCardType rejects non-string name", function()
        cg.clearCardTypes()
        local ok = pcall(cg.defineCardType, 42, {})
        expect_equal(ok, false)
    end)

    -- @description Verifies case: defineCardType rejects empty name.
    it("defineCardType rejects empty name", function()
        cg.clearCardTypes()
        local ok = pcall(cg.defineCardType, "", {})
        expect_equal(ok, false)
    end)

    -- @description Verifies case: newCard rejects non-string type.
    it("newCard rejects non-string type", function()
        local ok = pcall(cg.newCard, 123)
        expect_equal(ok, false)
    end)

    -- @description Verifies case: newStackWithCapacity rejects zero capacity.
    it("newStackWithCapacity rejects zero capacity", function()
        local ok = pcall(cg.newStackWithCapacity, "z", 0)
        expect_equal(ok, false)
    end)

    -- @description Verifies case: newStackWithCapacity rejects negative capacity.
    it("newStackWithCapacity rejects negative capacity", function()
        local ok = pcall(cg.newStackWithCapacity, "z", -1)
        expect_equal(ok, false)
    end)

    -- @description Verifies case: newSlotWithCapacity rejects zero capacity.
    it("newSlotWithCapacity rejects zero capacity", function()
        local ok = pcall(cg.newSlotWithCapacity, "z", 0)
        expect_equal(ok, false)
    end)

    -- @description Verifies case: CardPool add rejects empty type_name.
    it("CardPool add rejects empty type_name", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        local ok = pcall(function() pool:add("", 1) end)
        expect_equal(ok, false)
    end)

    -- @description Verifies case: DeckBuilder add rejects count < 1.
    it("DeckBuilder add rejects count < 1", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        local ok = pcall(function() db:add("card", 0) end)
        expect_equal(ok, false)
    end)
end)

test_summary()
