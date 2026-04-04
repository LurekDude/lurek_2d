--- BDD tests for library.cardgame
--- Covers: CardTypeDef, Card, Stack, Slot, CardPool, StackManager,
---         DeckBuilder, StackHistory, CardGroup, and the module registry.

package.path = "./library/?/init.lua;" .. package.path

local cg = require("library.cardgame")

dofile("tests/lua/init.lua")

-- ── Registry ──────────────────────────────────────────────────────────────

describe("Registry", function()
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

    it("getCardTypeNames returns sorted list", function()
        cg.clearCardTypes()
        cg.defineCardType("Zap", cg.newCardTypeDef("Zap"))
        cg.defineCardType("Arrow", cg.newCardTypeDef("Arrow"))
        local names = cg.getCardTypeNames()
        expect_equal(names[1], "Arrow")
        expect_equal(names[2], "Zap")
    end)

    it("clearCardTypes empties registry", function()
        cg.clearCardTypes()
        cg.defineCardType("X", cg.newCardTypeDef("X"))
        cg.clearCardTypes()
        expect_equal(cg.getCardType("X"), nil)
        expect_equal(#cg.getCardTypeNames(), 0)
    end)
end)

-- ── Card ──────────────────────────────────────────────────────────────────

describe("Card", function()
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

    it("stat operations", function()
        cg.clearCardTypes()
        local c = cg.newCard("plain")
        c:setStat("atk", 5)
        expect_equal(c:getStat("atk"), 5)
        expect_equal(c:addStat("atk", 3), 8)
        c:removeStat("atk")
        expect_equal(c:getStat("atk"), 0)
    end)

    it("tag operations", function()
        cg.clearCardTypes()
        local c = cg.newCard("plain")
        c:addTag("flying")
        expect_equal(c:hasTag("flying"), true)
        expect_equal(c:removeTag("flying"), true)
        expect_equal(c:hasTag("flying"), false)
        expect_equal(c:removeTag("flying"), false)
    end)

    it("counter operations", function()
        cg.clearCardTypes()
        local c = cg.newCard("plain")
        expect_equal(c:getCounter("charge"), 0)
        c:setCounter("charge", 3)
        expect_equal(c:addCounter("charge", -1), 2)
        c:removeCounter("charge")
        expect_equal(c:getCounter("charge"), 0)
    end)

    it("metadata operations", function()
        cg.clearCardTypes()
        local c = cg.newCard("plain")
        c:setMeta("artist", "da Vinci")
        expect_equal(c:getMeta("artist"), "da Vinci")
        expect_equal(c:getMeta("missing"), nil)
    end)

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

    it("unique ids", function()
        cg.clearCardTypes()
        local a = cg.newCard("x")
        local b = cg.newCard("x")
        expect_equal(a.id ~= b.id, true)
    end)

    it("default tile dimensions", function()
        cg.clearCardTypes()
        local c = cg.newCard("x")
        expect_equal(c.tile_w, 1)
        expect_equal(c.tile_h, 1)
        expect_equal(c.face_up, false)
        expect_equal(c.tapped, false)
    end)
end)

-- ── Stack ─────────────────────────────────────────────────────────────────

describe("Stack", function()
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

    it("push and pop from bottom", function()
        cg.clearCardTypes()
        local s = cg.newStack("deck")
        s:pushTop(cg.newCard("a"))
        s:pushBottom(cg.newCard("b"))
        local popped = s:popBottom()
        expect_equal(popped.card_type, "b")
    end)

    it("capacity enforcement", function()
        cg.clearCardTypes()
        local s = cg.newStackWithCapacity("tiny", 2)
        expect_equal(s:pushTop(cg.newCard("a")), true)
        expect_equal(s:pushTop(cg.newCard("b")), true)
        expect_equal(s:isFull(), true)
        expect_equal(s:pushTop(cg.newCard("c")), false)
    end)

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

    it("peek operations", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("b"))
        expect_equal(s:peekTop().card_type, "b")
        expect_equal(s:peekBottom().card_type, "a")
        expect_equal(s:peekAt(1).card_type, "a")
    end)

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

    it("moveWithin", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("b"))
        s:pushTop(cg.newCard("c"))
        expect_equal(s:moveWithin(1, 3), true)
        expect_equal(s:peekAt(3).card_type, "a")
    end)

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

    it("sort by name", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        local c1 = cg.newCard("c"); c1.name = "Charlie"
        local c2 = cg.newCard("a"); c2.name = "Alpha"
        s:pushTop(c1); s:pushTop(c2)
        s:sortByName()
        expect_equal(s:peekAt(1).name, "Alpha")
    end)

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

    it("clear returns cards", function()
        cg.clearCardTypes()
        local s = cg.newStack("z")
        s:pushTop(cg.newCard("a"))
        s:pushTop(cg.newCard("b"))
        local old = s:clear()
        expect_equal(#old, 2)
        expect_equal(s:isEmpty(), true)
    end)

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

-- ── Slot ──────────────────────────────────────────────────────────────────

describe("Slot", function()
    it("push and pop", function()
        cg.clearCardTypes()
        local s = cg.newSlot("weapon")
        local ok = s:push(cg.newCard("sword"))
        expect_equal(ok, true)
        expect_equal(s:size(), 1)
        local card = s:pop()
        expect_equal(card.card_type, "sword")
    end)

    it("capacity enforcement", function()
        cg.clearCardTypes()
        local s = cg.newSlotWithCapacity("ring", 1)
        s:push(cg.newCard("ruby"))
        expect_equal(s:isFull(), true)
        local ok = s:push(cg.newCard("sapphire"))
        expect_equal(ok, false)
    end)

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

-- ── CardPool ──────────────────────────────────────────────────────────────

describe("CardPool", function()
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

    it("draw items creates Card instances", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        pool:add("warrior", 5)
        math.randomseed(1)
        local items = pool:drawItems(3)
        expect_equal(#items, 3)
        expect_equal(items[1].card_type, "warrior")
    end)

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

    it("getTypeNames returns all types", function()
        cg.clearCardTypes()
        local pool = cg.newCardPool("z")
        pool:add("x", 1)
        pool:add("y", 1)
        local names = pool:getTypeNames()
        expect_equal(#names, 2)
    end)

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

-- ── StackManager ──────────────────────────────────────────────────────────

describe("StackManager", function()
    it("create and manage stacks", function()
        cg.clearCardTypes()
        local mgr = cg.newStackManager()
        mgr:createStack("hand")
        mgr:createStackCapped("discard", 10)
        expect_equal(mgr:hasStack("hand"), true)
        expect_equal(#mgr:stackNames(), 2)
    end)

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

-- ── DeckBuilder ───────────────────────────────────────────────────────────

describe("DeckBuilder", function()
    it("build creates stack with entries", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("test_deck")
        db:add("fire_spell", 3)
        db:add("ice_spell", 2)
        local deck = db:build()
        expect_equal(deck:size(), 5)
        expect_equal(deck.name, "test_deck")
    end)

    it("buildNamed uses custom name", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("template")
        db:add("card", 2)
        local deck = db:buildNamed("player_deck")
        expect_equal(deck.name, "player_deck")
    end)

    it("shuffle_on_build shuffles the result", function()
        cg.clearCardTypes()
        math.randomseed(42)
        local db = cg.newDeckBuilder("shuffled")
        db.shuffle_on_build = true
        for i = 1, 20 do db:add("c" .. i, 1) end
        local deck = db:build()
        expect_equal(deck:size(), 20)
    end)

    it("addWith applies stat overrides and extra tags", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db:addWith("warrior", 1, { hp = 99 }, { "elite" })
        local deck = db:build()
        local c = deck:peekTop()
        expect_equal(c:getStat("hp"), 99)
        expect_equal(c:hasTag("elite"), true)
    end)

    it("validateEntries detects banned types", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db:banType("banned")
        db:add("banned", 1)
        local errs = db:validateEntries()
        expect_equal(#errs > 0, true)
    end)

    it("validateEntries detects min/max size violation", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db.min_size = 10
        db:add("card", 3)
        local errs = db:validateEntries()
        expect_equal(#errs > 0, true)
    end)

    it("validateEntries detects missing required types", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db:requireType("must_have")
        db:add("other", 5)
        local errs = db:validateEntries()
        expect_equal(#errs > 0, true)
    end)

    it("removeBannedType removes from ban list", function()
        cg.clearCardTypes()
        local db = cg.newDeckBuilder("z")
        db:banType("x")
        expect_equal(db:removeBannedType("x"), true)
        expect_equal(db:removeBannedType("x"), false)
    end)
end)

-- ── StackHistory ──────────────────────────────────────────────────────────

describe("StackHistory", function()
    it("record and retrieve entries", function()
        local h = cg.newStackHistory()
        h:record("deck", cg.HistoryAction.pushed("spell", "Fireball"), 5)
        h:record("deck", cg.HistoryAction.shuffled(), 5)
        expect_equal(h:len(), 2)
        expect_equal(h:last().action.kind, "shuffled")
    end)

    it("entriesFor filters by stack name", function()
        local h = cg.newStackHistory()
        h:record("deck", cg.HistoryAction.pushed("a", "A"), 1)
        h:record("hand", cg.HistoryAction.pushed("b", "B"), 1)
        h:record("deck", cg.HistoryAction.popped("a", "A"), 0)
        local deck_entries = h:entriesFor("deck")
        expect_equal(#deck_entries, 2)
    end)

    it("max_size evicts oldest entries", function()
        local h = cg.newStackHistoryWithMaxSize(3)
        for i = 1, 5 do
            h:record("s", cg.HistoryAction.custom("e" .. i), i)
        end
        expect_equal(h:len(), 3)
        expect_equal(h:entries()[1].action.label, "e3")
    end)

    it("recordCustom and clear", function()
        local h = cg.newStackHistory()
        h:recordCustom("deck", "manual_shuffle", 10)
        expect_equal(h:len(), 1)
        expect_equal(h:last().action.kind, "custom")
        expect_equal(h:last().action.label, "manual_shuffle")
        h:clear()
        expect_equal(h:isEmpty(), true)
    end)

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

-- ── CardGroup ─────────────────────────────────────────────────────────────

describe("CardGroup", function()
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


-- ── Analysis helpers ─────────────────────────────────────────────────────

describe("Analysis helpers", function()
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

    it("groupByTagPrefix ignores cards without matching prefix", function()
        cg.clearCardTypes()
        local c = cg.newCard("x")
        c:addTag("noprefix")
        local groups = cg.groupByTagPrefix({c}, "suit")
        local count = 0
        for _ in pairs(groups) do count = count + 1 end
        expect_equal(count, 0)
    end)

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

    it("findSequences on empty list returns empty", function()
        local seqs = cg.findSequences({}, "rank", 2)
        expect_equal(#seqs, 0)
    end)
end)

test_summary()
