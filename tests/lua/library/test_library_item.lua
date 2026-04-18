--- BDD tests for library.item
-- @module tests.lua.library.test_library_item

local item = require("library.item")

-- ─── Type registry ────────────────────────────────────────────────────────────

-- @description Covers item type registry definition, lookup, name enumeration, and clearing of registered item archetypes.
describe("TypeRegistry", function()
    -- @covers library.item.defineType
    -- @covers library.item.getType
    -- @description Verifies case: clearTypes resets registry.
    it("clearTypes resets registry", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={} })
        item.clearTypes()
        expect_equal(item.getType("sword"), nil)
    end)

    -- @description Verifies case: defineType and getType round-trip.
    it("defineType and getType round-trip", function()
        item.clearTypes()
        item.defineType("axe", { category="weapon", base_stats={dmg=15}, base_tags={"equippable"} })
        local def = item.getType("axe")
        expect_equal(def.category, "weapon")
        expect_equal(def.base_stats.dmg, 15)
    end)

    -- @description Verifies case: getTypeNames returns sorted names.
    it("getTypeNames returns sorted names", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={}, base_tags={} })
        item.defineType("axe",   { category="weapon", base_stats={}, base_tags={} })
        item.defineType("bow",   { category="ranged", base_stats={}, base_tags={} })
        local names = item.getTypeNames()
        expect_equal(names[1], "axe")
        expect_equal(names[2], "bow")
        expect_equal(names[3], "sword")
    end)
end)

-- ─── Item object ──────────────────────────────────────────────────────────────

-- @description Verifies item defaults and mutation helpers for stats, tags, counters, cloning, naming, slot assignment, and registry-seeded fields.
describe("Item", function()
    -- @covers library.item.newItem
    -- @description Verifies case: stats from base_stats.
    it("stats from base_stats", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10, spd=5}, base_tags={} })
        local it = item.newItem("sword")
        expect_equal(it:getStat("dmg"), 10)
        expect_equal(it:getStat("spd"), 5)
    end)

    -- @description Verifies case: setStat overrides base stat.
    it("setStat overrides base stat", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={} })
        local it = item.newItem("sword")
        it:setStat("dmg", 99)
        expect_equal(it:getStat("dmg"), 99)
    end)

    -- @description Verifies case: addStat accumulates delta.
    it("addStat accumulates delta", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={} })
        local it = item.newItem("sword")
        it:addStat("dmg", 5)
        expect_equal(it:getStat("dmg"), 15)
    end)

    -- @description Verifies case: removeStat clears the stat.
    it("removeStat clears the stat", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={} })
        local it = item.newItem("sword")
        it:removeStat("dmg")
        expect_equal(it:getStat("dmg"), nil)
    end)

    -- @description Verifies case: getStats returns shallow copy.
    it("getStats returns shallow copy", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={} })
        local it  = item.newItem("sword")
        local all = it:getStats()
        expect_equal(all.dmg, 10)
    end)

    -- @description Verifies case: base_tags copied per instance.
    it("base_tags copied per instance", function()
        item.clearTypes()
        item.defineType("ring", { category="acc", base_stats={}, base_tags={"equippable","magic"} })
        local a = item.newItem("ring")
        local b = item.newItem("ring")
        a:addTag("cursed")
        expect_equal(b:hasTag("cursed"), false)
        expect_equal(a:hasTag("equippable"), true)
    end)

    -- @description Verifies case: addTag / removeTag / getTags.
    it("addTag / removeTag / getTags", function()
        item.clearTypes()
        local it = item.newItem("gem")
        it:addTag("rare")
        it:addTag("blue")
        expect_equal(it:hasTag("rare"), true)
        local tags = it:getTags()
        expect_equal(#tags, 2)
        it:removeTag("rare")
        expect_equal(it:hasTag("rare"), false)
    end)

    -- @description Verifies case: getCategory returns registry category.
    it("getCategory returns registry category", function()
        item.clearTypes()
        item.defineType("wand", { category="magic", base_stats={}, base_tags={} })
        local it = item.newItem("wand")
        expect_equal(it:getCategory(), "magic")
    end)

    -- @description Verifies case: setMeta / getMeta round-trip.
    it("setMeta / getMeta round-trip", function()
        item.clearTypes()
        local it = item.newItem("ancient_tome")
        it:setMeta("origin", "library")
        expect_equal(it:getMeta("origin"), "library")
    end)

    -- @description Verifies case: setOwner / getOwner.
    it("setOwner / getOwner", function()
        item.clearTypes()
        local it = item.newItem("coin")
        local player = { name="hero" }
        it:setOwner(player)
        expect_equal(it:getOwner(), player)
    end)

    -- @description Verifies case: clone creates independent copy (stats, tags, meta).
    it("clone creates independent copy (stats, tags, meta)", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={"equippable"} })
        local it = item.newItem("sword")
        it:addTag("fire")
        it:setMeta("quality", "rare")
        local c = it:clone()
        expect_equal(c:getStat("dmg"), 10)
        expect_equal(c:hasTag("fire"), true)
        expect_equal(c:getMeta("quality"), "rare")
        -- modify original -> clone unaffected
        it:setStat("dmg", 99)
        expect_equal(c:getStat("dmg"), 10)
    end)

    -- @description Verifies case: getStats mutations don't affect item.
    it("getStats mutations don't affect item", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=5}, base_tags={} })
        local it  = item.newItem("sword")
        local all = it:getStats()
        all.dmg   = 100
        expect_equal(it:getStat("dmg"), 5)
    end)
end)

-- ─── Stack ────────────────────────────────────────────────────────────────────

-- @description Exercises generic item stacks for push or pop flow, indexing, filtering, sorting, snapshots, and capacity-aware behaviors.
describe("Stack", function()
    -- @covers library.item.newStack
    -- @description Verifies case: push / size / peek round-trip.
    it("push / size / peek round-trip", function()
        local s = item.newStack("test")
        local a = item.newItem("coin")
        s:push(a)
        expect_equal(s:size(), 1)
        expect_equal(s:peek(), a)
    end)

    -- @description Verifies case: pop removes top.
    it("pop removes top", function()
        local s = item.newStack("test")
        local a = item.newItem("a"); local b = item.newItem("b")
        s:push(a); s:push(b)
        local top = s:pop()
        expect_equal(top, b)
        expect_equal(s:size(), 1)
    end)

    -- @description Verifies case: popBottom removes first item.
    it("popBottom removes first item", function()
        local s = item.newStack("test")
        local a = item.newItem("a"); local b = item.newItem("b")
        s:push(a); s:push(b)
        local bot = s:popBottom()
        expect_equal(bot, a)
        expect_equal(s:size(), 1)
    end)

    -- @description Verifies case: pushBottom inserts at index 1.
    it("pushBottom inserts at index 1", function()
        local s = item.newStack("test")
        local a = item.newItem("a"); local b = item.newItem("b")
        s:push(a)
        s:pushBottom(b)
        expect_equal(s:popBottom(), b)
    end)

    -- @description Verifies case: peekAt by 1-based index.
    it("peekAt by 1-based index", function()
        local s = item.newStack("test")
        local a = item.newItem("a"); local b = item.newItem("b"); local c = item.newItem("c")
        s:push(a); s:push(b); s:push(c)
        expect_equal(s:peekAt(2), b)
    end)

    -- @description Verifies case: removeAt removes specific index.
    it("removeAt removes specific index", function()
        local s = item.newStack("test")
        local a = item.newItem("a"); local b = item.newItem("b"); local c = item.newItem("c")
        s:push(a); s:push(b); s:push(c)
        local removed = s:removeAt(2)
        expect_equal(removed, b)
        expect_equal(s:size(), 2)
    end)

    -- @description Verifies case: insertAt inserts at position.
    it("insertAt inserts at position", function()
        local s = item.newStack("test")
        local a = item.newItem("a"); local b = item.newItem("b"); local x = item.newItem("x")
        s:push(a); s:push(b)
        expect_equal(s:insertAt(2, x), true)
        expect_equal(s:peekAt(2), x)
        expect_equal(s:size(), 3)
    end)

    -- @description Verifies case: findFirst returns matching item.
    it("findFirst returns matching item", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={} })
        item.defineType("potion", { category="consumable", base_stats={}, base_tags={} })
        local s = item.newStack("test")
        local p = item.newItem("potion")
        local sw = item.newItem("sword")
        s:push(p); s:push(sw)
        local found = s:findFirst(function(i) return i:getType() == "sword" end)
        expect_equal(found, sw)
    end)

    -- @description Verifies case: getItems returns bottom-to-top copy.
    it("getItems returns bottom-to-top copy", function()
        local s = item.newStack("test")
        local a = item.newItem("a"); local b = item.newItem("b")
        s:push(a); s:push(b)
        local all = s:getItems()
        expect_equal(#all, 2)
        expect_equal(all[1], a)
        expect_equal(all[2], b)
    end)

    -- @description Verifies case: capacity limits push.
    it("capacity limits push", function()
        local s = item.newStack("tiny", 2)
        s:push(item.newItem("a"))
        s:push(item.newItem("b"))
        expect_equal(s:isFull(), true)
        expect_equal(s:push(item.newItem("c")), false)
    end)

    -- @description Verifies case: clear empties stack.
    it("clear empties stack", function()
        local s = item.newStack("test")
        s:push(item.newItem("a"))
        s:clear()
        expect_equal(s:size(), 0)
    end)
end)

-- ─── ItemPool ─────────────────────────────────────────────────────────────────

-- @description Tests weighted item pools for type management, random draws, weight mutation, emptiness checks, and total-weight bookkeeping.
describe("ItemPool", function()
    -- @covers library.item.newItemPool
    -- @description Verifies case: draw returns item from pool.
    it("draw returns item from pool", function()
        item.clearTypes()
        item.defineType("gold", { category="misc", base_stats={}, base_tags={} })
        local pool = item.newItemPool()
        pool:addType("gold", 1.0)
        local drawn = pool:draw()
        expect_equal(drawn:getType(), "gold")
    end)

    -- @description Verifies case: draw returns nil when empty.
    it("draw returns nil when empty", function()
        local pool = item.newItemPool()
        local drawn = pool:draw()
        expect_equal(drawn, nil)
    end)

    -- @description Verifies case: size returns entry count.
    it("size returns entry count", function()
        local pool = item.newItemPool()
        pool:addType("a", 1); pool:addType("b", 2)
        expect_equal(pool:size(), 2)
    end)

    -- @description Verifies case: drawTypes returns n items.
    it("drawTypes returns n items", function()
        item.clearTypes()
        item.defineType("coin", { category="misc", base_stats={}, base_tags={} })
        local pool = item.newItemPool()
        pool:addType("coin", 1.0)
        local drawn = pool:drawTypes(5)
        expect_equal(#drawn, 5)
    end)

    -- @description Verifies case: drawUniqueTypes returns distinct type names.
    it("drawUniqueTypes returns distinct type names", function()
        item.clearTypes()
        item.defineType("a", { category="misc", base_stats={}, base_tags={} })
        item.defineType("b", { category="misc", base_stats={}, base_tags={} })
        item.defineType("c", { category="misc", base_stats={}, base_tags={} })
        local pool = item.newItemPool()
        pool:addType("a", 1); pool:addType("b", 1); pool:addType("c", 1)
        local drawn = pool:drawUniqueTypes(3)
        expect_equal(#drawn, 3)
        local seen = {}
        for _, it in ipairs(drawn) do
            seen[it:getType()] = (seen[it:getType()] or 0) + 1
        end
        for _, v in pairs(seen) do expect_equal(v, 1) end
    end)

    -- @description Verifies case: setWeight updates total.
    it("setWeight updates total", function()
        item.clearTypes()
        local pool = item.newItemPool()
        pool:addType("rare", 1.0)
        pool:setWeight("rare", 5.0)
        local entries = pool:getEntries()
        expect_equal(entries[1].weight, 5.0)
    end)

    -- @description Verifies case: remove decreases size.
    it("remove decreases size", function()
        local pool = item.newItemPool()
        pool:addType("common", 10); pool:addType("rare", 1)
        pool:remove("rare")
        expect_equal(pool:size(), 1)
    end)

    -- @description Verifies case: getEntries returns copy.
    it("getEntries returns copy", function()
        local pool = item.newItemPool()
        pool:addType("x", 2.0)
        local entries = pool:getEntries()
        expect_equal(#entries, 1)
        expect_equal(entries[1].type_name, "x")
    end)
end)

-- ─── StackHistory ─────────────────────────────────────────────────────────────

-- @description Covers history recording, pruning, source filtering, emptiness checks, and access to the latest recorded stack event.
describe("StackHistory", function()
    -- @covers library.item.newStackHistory
    -- @description Verifies case: recordPush creates entry.
    it("recordPush creates entry", function()
        local h = item.newStackHistory(10)
        h:recordPush("bag", "sword", 1)
        local ents = h:entries()
        expect_equal(#ents, 1)
        expect_equal(ents[1].action, item.HistoryAction.Push)
        expect_equal(ents[1].source, "bag")
        expect_equal(ents[1].item_type, "sword")
    end)

    -- @description Verifies case: recordPop creates entry.
    it("recordPop creates entry", function()
        local h = item.newStackHistory(10)
        h:recordPop("bag", "gem", 0)
        local ents = h:entries()
        expect_equal(ents[1].action, item.HistoryAction.Pop)
    end)

    -- @description Verifies case: recordClear creates clear entry.
    it("recordClear creates clear entry", function()
        local h = item.newStackHistory(10)
        h:recordClear("bag")
        local ents = h:entries()
        expect_equal(ents[1].action, item.HistoryAction.Clear)
    end)

    -- @description Verifies case: bounded at max_entries.
    it("bounded at max_entries", function()
        local h = item.newStackHistory(3)
        for i = 1, 5 do h:recordCustom("src", "action_"..i, i) end
        expect_equal(h:count(), 3)
    end)

    -- @description Verifies case: getLastN returns last n entries.
    it("getLastN returns last n entries", function()
        local h = item.newStackHistory(50)
        for i = 1, 5 do h:recordCustom("src", "ev_"..i, i) end
        local last2 = h:getLastN(2)
        expect_equal(#last2, 2)
        expect_equal(last2[2].item_type, "ev_5")
    end)

    -- @description Verifies case: clear resets log.
    it("clear resets log", function()
        local h = item.newStackHistory(10)
        h:recordCustom("x", "y", 1)
        h:clear()
        expect_equal(h:count(), 0)
    end)

    -- @description Verifies case: HistoryAction constants exist.
    it("HistoryAction constants exist", function()
        expect_equal(item.HistoryAction.Push,   "push")
        expect_equal(item.HistoryAction.Pop,    "pop")
        expect_equal(item.HistoryAction.Clear,  "clear")
        expect_equal(item.HistoryAction.Custom, "custom")
    end)
end)

-- ─── StackManager ─────────────────────────────────────────────────────────────

-- @description Verifies stack-manager orchestration for named stacks, movement between stacks, aggregate counting, and existence checks.
describe("StackManager", function()
    -- @covers library.item.newStackManager
    -- @description Verifies case: addStack / getStack round-trip.
    it("addStack / getStack round-trip", function()
        local mgr = item.newStackManager()
        local s   = item.newStack("weapons")
        mgr:addStack("weapons", s)
        expect_equal(mgr:getStack("weapons"), s)
    end)

    -- @description Verifies case: removeStack returns true if existed.
    it("removeStack returns true if existed", function()
        local mgr = item.newStackManager()
        mgr:addStack("x", item.newStack("x"))
        expect_equal(mgr:removeStack("x"), true)
        expect_equal(mgr:getStack("x"), nil)
    end)

    -- @description Verifies case: keys returns sorted names.
    it("keys returns sorted names", function()
        local mgr = item.newStackManager()
        mgr:addStack("zz", item.newStack("zz"))
        mgr:addStack("aa", item.newStack("aa"))
        local keys = mgr:keys()
        expect_equal(keys[1], "aa")
    end)
end)

-- ─── Analysis ─────────────────────────────────────────────────────────────────

-- @description Tests selecting the top-N item indices by stat value while preserving the module's documented 0-based result convention.
describe("findNOfStat", function()
    -- @covers library.item.findNOfStat
    -- @description Verifies case: returns top n indices (0-based).
    it("returns top n indices (0-based)", function()
        item.clearTypes()
        local items = {}
        for _, v in ipairs({3, 9, 1, 7, 5}) do
            local it = item.newItem("thing")
            it:setStat("power", v)
            table.insert(items, it)
        end
        local top2 = item.findNOfStat(items, "power", 2)
        expect_equal(#top2, 2)
        -- index 1 (0-based) = value 9, index 3 (0-based) = value 7
        local set = {}
        for _, i in ipairs(top2) do set[i] = true end
        expect_equal(set[1], true)  -- 0-based index 1 -> value 9
        expect_equal(set[3], true)  -- 0-based index 3 -> value 7
    end)
end)

-- @description Verifies grouping items by stat value yields buckets keyed by each distinct stat.
describe("groupByStat", function()
    -- @covers library.item.groupByStat
    -- @description Verifies case: groups items by stat value.
    it("groups items by stat value", function()
        item.clearTypes()
        local items = {}
        for _, v in ipairs({1, 2, 1, 2, 3}) do
            local it = item.newItem("x")
            it:setStat("tier", v)
            table.insert(items, it)
        end
        local groups = item.groupByStat(items, "tier")
        expect_equal(#groups[1], 2)
        expect_equal(#groups[2], 2)
        expect_equal(#groups[3], 1)
    end)
end)

-- @description Covers grouping items according to tags that share a specific prefix.
describe("groupByTagPrefix", function()
    -- @covers library.item.groupByTagPrefix
    -- @description Verifies case: groups items by tag prefix.
    it("groups items by tag prefix", function()
        item.clearTypes()
        local swords = {}
        for _, suffix in ipairs({"tier:1","tier:1","tier:2"}) do
            local it = item.newItem("sword")
            it:addTag(suffix)
            table.insert(swords, it)
        end
        local groups = item.groupByTagPrefix(swords, "tier:")
        expect_equal(#groups["tier:1"], 2)
        expect_equal(#groups["tier:2"], 1)
    end)
end)

-- @description Exercises sequence detection for consecutive equal stat runs and the empty result case when no runs exist.
describe("findSequences", function()
    -- @covers library.item.findSequences
    -- @description Verifies case: finds consecutive runs of same stat value.
    it("finds consecutive runs of same stat value", function()
        item.clearTypes()
        local items = {}
        for _, v in ipairs({1, 1, 2, 2, 2, 1}) do
            local it = item.newItem("x")
            it:setStat("v", v)
            table.insert(items, it)
        end
        local seqs = item.findSequences(items, "v")
        expect_equal(#seqs, 2)
        expect_equal(seqs[1].value, 1)
        expect_equal(seqs[1].length, 2)
        expect_equal(seqs[2].value, 2)
        expect_equal(seqs[2].length, 3)
    end)

    -- @description Verifies case: returns empty for all-distinct sequence.
    it("returns empty for all-distinct sequence", function()
        item.clearTypes()
        local items = {}
        for _, v in ipairs({1,2,3,4}) do
            local it = item.newItem("x"); it:setStat("v", v); table.insert(items, it)
        end
        expect_equal(#item.findSequences(items, "v"), 0)
    end)
end)

-- @description Validates stack builder recipes, overrides, shuffle-on-build behavior, validation helpers, and named stack creation.
describe("StackBuilder", function()
    -- @covers library.item.newStackBuilder
    -- @description Verifies case: build creates stack from recipe.
    it("build creates stack from recipe", function()
        item.clearTypes()
        item.defineType("arrow", { category="ammo", base_stats={}, base_tags={} })
        item.defineType("coin",  { category="misc", base_stats={}, base_tags={} })
        local b = item.newStackBuilder()
        b:add("arrow", 3)
        b:add("coin", 2)
        local s = b:build("loot")
        expect_equal(s:size(), 5)
    end)

    -- @description Verifies case: addWith applies stat overrides to built items.
    it("addWith applies stat overrides to built items", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=5}, base_tags={} })
        local b = item.newStackBuilder()
        b:addWith("sword", 2, { dmg=99 }, { "shiny" })
        local s = b:build("inv")
        expect_equal(s:size(), 2)
        local items = s:getItems()
        expect_equal(items[1]:getStat("dmg"), 99)
        expect_equal(items[1]:hasTag("shiny"), true)
        expect_equal(items[2]:getStat("dmg"), 99)
    end)

    -- @description Verifies case: setShuffleOnBuild does not lose items.
    it("setShuffleOnBuild does not lose items", function()
        item.clearTypes()
        item.defineType("card", { category="misc", base_stats={}, base_tags={} })
        local b = item.newStackBuilder()
        b:add("card", 5)
        b:setShuffleOnBuild(true)
        local s = b:build("deck")
        expect_equal(s:size(), 5)
    end)

    -- @description Verifies case: validateEntries detects banned types.
    it("validateEntries detects banned types", function()
        item.clearTypes()
        item.defineType("bomb", { category="misc", base_stats={}, base_tags={} })
        local b = item.newStackBuilder()
        b:add("bomb", 1)
        b:banType("bomb")
        local err = b:validateEntries()
        expect_equal(type(err), "string")
    end)

    -- @description Verifies case: validateEntries passes clean recipe.
    it("validateEntries passes clean recipe", function()
        item.clearTypes()
        item.defineType("coin", { category="misc", base_stats={}, base_tags={} })
        local b = item.newStackBuilder()
        b:add("coin", 3)
        local err = b:validateEntries()
        expect_equal(err, nil)
    end)

    -- @description Verifies case: validateStack detects missing required type.
    it("validateStack detects missing required type", function()
        item.clearTypes()
        item.defineType("key", { category="misc", base_stats={}, base_tags={} })
        local b = item.newStackBuilder()
        b:requireType("key")
        local s = item.newStack("empty")
        local err = b:validateStack(s)
        expect_equal(type(err), "string")
    end)

    -- @description Verifies case: buildNamed is alias for build.
    it("buildNamed is alias for build", function()
        item.clearTypes()
        item.defineType("gem", { category="misc", base_stats={}, base_tags={} })
        local b = item.newStackBuilder()
        b:add("gem", 2)
        local s = b:buildNamed("treasure")
        expect_equal(s:size(), 2)
        expect_equal(s:getName(), "treasure")
    end)
end)

-- ─── Item counters ────────────────────────────────────────────────────────────

-- @description Adds focused counter coverage for unset defaults, mutation, deletion, shallow copies, and clone independence.
describe("Item counters", function()
    -- @covers library.item.newItem
    -- @description Verifies case: getCounter returns 0 for unset key.
    it("getCounter returns 0 for unset key", function()
        item.clearTypes()
        local it = item.newItem("thing")
        expect_equal(it:getCounter("charge"), 0)
    end)

    -- @description Verifies case: setCounter / getCounter round-trip.
    it("setCounter / getCounter round-trip", function()
        item.clearTypes()
        local it = item.newItem("thing")
        it:setCounter("charge", 5)
        expect_equal(it:getCounter("charge"), 5)
    end)

    -- @description Verifies case: addCounter accumulates delta.
    it("addCounter accumulates delta", function()
        item.clearTypes()
        local it = item.newItem("thing")
        it:setCounter("durability", 10)
        local new_val = it:addCounter("durability", -3)
        expect_equal(new_val, 7)
        expect_equal(it:getCounter("durability"), 7)
    end)

    -- @description Verifies case: addCounter creates counter at delta when absent.
    it("addCounter creates counter at delta when absent", function()
        item.clearTypes()
        local it = item.newItem("thing")
        local v = it:addCounter("new", 4)
        expect_equal(v, 4)
    end)

    -- @description Verifies case: removeCounter deletes the key.
    it("removeCounter deletes the key", function()
        item.clearTypes()
        local it = item.newItem("thing")
        it:setCounter("temp", 3)
        it:removeCounter("temp")
        expect_equal(it:getCounter("temp"), 0)
    end)

    -- @description Verifies case: getCounters returns shallow copy.
    it("getCounters returns shallow copy", function()
        item.clearTypes()
        local it = item.newItem("thing")
        it:setCounter("a", 1)
        it:setCounter("b", 2)
        local all = it:getCounters()
        expect_equal(all.a, 1)
        expect_equal(all.b, 2)
        -- mutation does not affect item
        all.a = 99
        expect_equal(it:getCounter("a"), 1)
    end)

    -- @description Verifies case: clone copies counters.
    it("clone copies counters", function()
        item.clearTypes()
        local it = item.newItem("thing")
        it:setCounter("hp", 10)
        local c = it:clone()
        expect_equal(c:getCounter("hp"), 10)
        c:setCounter("hp", 99)
        expect_equal(it:getCounter("hp"), 10)
    end)
end)

-- ─── Item name / slot ─────────────────────────────────────────────────────────

-- @description Covers item display names and slot metadata, including registry defaults and clone preservation.
describe("Item name and slot", function()
    -- @covers library.item.newItem
    -- @description Verifies case: getName seeds from type def name.
    it("getName seeds from type def name", function()
        item.clearTypes()
        item.defineType("legendary_sword", { name="Excalibur", category="weapon", base_stats={}, base_tags={} })
        local it = item.newItem("legendary_sword")
        expect_equal(it:getName(), "Excalibur")
    end)

    -- @description Verifies case: getName defaults to type_name when no def name.
    it("getName defaults to type_name when no def name", function()
        item.clearTypes()
        local it = item.newItem("plain_item")
        expect_equal(it:getName(), "plain_item")
    end)

    -- @description Verifies case: setName / getName round-trip.
    it("setName / getName round-trip", function()
        item.clearTypes()
        local it = item.newItem("ring")
        it:setName("Ring of Power")
        expect_equal(it:getName(), "Ring of Power")
    end)

    -- @description Verifies case: getSlot returns empty string by default.
    it("getSlot returns empty string by default", function()
        item.clearTypes()
        local it = item.newItem("coin")
        expect_equal(it:getSlot(), "")
    end)

    -- @description Verifies case: setSlot / getSlot round-trip.
    it("setSlot / getSlot round-trip", function()
        item.clearTypes()
        local it = item.newItem("sword")
        it:setSlot("hand[0]")
        expect_equal(it:getSlot(), "hand[0]")
    end)

    -- @description Verifies case: clone copies slot and name.
    it("clone copies slot and name", function()
        item.clearTypes()
        local it = item.newItem("shield")
        it:setName("Iron Shield")
        it:setSlot("offhand")
        local c = it:clone()
        expect_equal(c:getName(), "Iron Shield")
        expect_equal(c:getSlot(), "offhand")
        -- mutations are independent
        c:setSlot("bag")
        expect_equal(it:getSlot(), "offhand")
    end)
end)

-- ─── Stack.peekBottom ─────────────────────────────────────────────────────────

-- @description Verifies bottom-peek behavior returns the first pushed item without mutating stack contents.
describe("Stack peekBottom", function()
    -- @covers library.item.newStack
    -- @description Verifies case: returns first item without removing it.
    it("returns first item without removing it", function()
        local s = item.newStack("test")
        local a = item.newItem("a")
        local b = item.newItem("b")
        s:push(a)
        s:push(b)
        expect_equal(s:peekBottom(), a)
        expect_equal(s:size(), 2)
    end)

    -- @description Verifies case: returns nil on empty stack.
    it("returns nil on empty stack", function()
        local s = item.newStack("test")
        expect_equal(s:peekBottom(), nil)
    end)
end)

-- ─── ItemPool extras ──────────────────────────────────────────────────────────

-- @description Extends item-pool coverage for empty-state checks and total-weight updates after mutation.
describe("ItemPool isEmpty and totalWeight", function()
    -- @covers library.item.newItemPool
    -- @description Verifies case: isEmpty returns true when empty.
    it("isEmpty returns true when empty", function()
        local pool = item.newItemPool()
        expect_equal(pool:isEmpty(), true)
    end)

    -- @description Verifies case: isEmpty returns false after addType.
    it("isEmpty returns false after addType", function()
        local pool = item.newItemPool()
        pool:addType("coin", 1)
        expect_equal(pool:isEmpty(), false)
    end)

    -- @description Verifies case: totalWeight returns sum of weights.
    it("totalWeight returns sum of weights", function()
        local pool = item.newItemPool()
        pool:addType("common", 3)
        pool:addType("rare",   1)
        expect_equal(pool:totalWeight(), 4)
    end)

    -- @description Verifies case: totalWeight updates after setWeight.
    it("totalWeight updates after setWeight", function()
        local pool = item.newItemPool()
        pool:addType("a", 2)
        pool:setWeight("a", 5)
        expect_equal(pool:totalWeight(), 5)
    end)

    -- @description Verifies case: totalWeight updates after remove.
    it("totalWeight updates after remove", function()
        local pool = item.newItemPool()
        pool:addType("x", 3)
        pool:addType("y", 7)
        pool:remove("x")
        expect_equal(pool:totalWeight(), 7)
    end)
end)

-- ─── StackHistory extras ──────────────────────────────────────────────────────

-- @description Adds history coverage for emptiness, most-recent lookup, and source-based filtering of recorded actions.
describe("StackHistory extras", function()
    -- @covers library.item.newStackHistory
    -- @description Verifies case: isEmpty is true on fresh history.
    it("isEmpty is true on fresh history", function()
        local h = item.newStackHistory(10)
        expect_equal(h:isEmpty(), true)
    end)

    -- @description Verifies case: isEmpty is false after record.
    it("isEmpty is false after record", function()
        local h = item.newStackHistory(10)
        h:recordPush("bag", "coin", 1)
        expect_equal(h:isEmpty(), false)
    end)

    -- @description Verifies case: last returns most recent entry.
    it("last returns most recent entry", function()
        local h = item.newStackHistory(10)
        h:recordPush("bag", "coin", 1)
        h:recordCustom("bag", "special", 1)
        local e = h:last()
        expect_equal(e.item_type, "special")
    end)

    -- @description Verifies case: last returns nil on empty history.
    it("last returns nil on empty history", function()
        local h = item.newStackHistory(10)
        expect_equal(h:last(), nil)
    end)

    -- @description Verifies case: entriesFor filters by source.
    it("entriesFor filters by source", function()
        local h = item.newStackHistory(20)
        h:recordPush("bag",   "coin",  1)
        h:recordPush("chest", "gem",   1)
        h:recordPush("bag",   "arrow", 2)
        local bag_entries = h:entriesFor("bag")
        expect_equal(#bag_entries, 2)
        local chest_entries = h:entriesFor("chest")
        expect_equal(#chest_entries, 1)
    end)
end)

-- ─── StackManager extras ──────────────────────────────────────────────────────

-- @description Extends stack-manager coverage for creation helpers, top moves, typed moves, total counting, and error paths on missing stacks.
describe("StackManager extras", function()
    -- @covers library.item.newStackManager
    -- @description Verifies case: hasStack returns false when missing.
    it("hasStack returns false when missing", function()
        local mgr = item.newStackManager()
        expect_equal(mgr:hasStack("unknown"), false)
    end)

    -- @description Verifies case: hasStack returns true after addStack.
    it("hasStack returns true after addStack", function()
        local mgr = item.newStackManager()
        mgr:addStack("inv", item.newStack("inv"))
        expect_equal(mgr:hasStack("inv"), true)
    end)

    -- @description Verifies case: createStack adds empty unlimited stack.
    it("createStack adds empty unlimited stack", function()
        local mgr = item.newStackManager()
        mgr:createStack("draw")
        local s = mgr:getStack("draw")
        expect_equal(s ~= nil, true)
        expect_equal(s:size(), 0)
    end)

    -- @description Verifies case: createStackCapped respects capacity.
    it("createStackCapped respects capacity", function()
        local mgr = item.newStackManager()
        mgr:createStackCapped("hand", 3)
        local s = mgr:getStack("hand")
        for _ = 1, 3 do s:push(item.newItem("card")) end
        expect_equal(s:isFull(), true)
    end)

    -- @description Verifies case: totalItems sums across all stacks.
    it("totalItems sums across all stacks", function()
        local mgr = item.newStackManager()
        mgr:createStack("a")
        mgr:createStack("b")
        mgr:getStack("a"):push(item.newItem("x"))
        mgr:getStack("a"):push(item.newItem("x"))
        mgr:getStack("b"):push(item.newItem("y"))
        expect_equal(mgr:totalItems(), 3)
    end)

    -- @description Verifies case: moveItem moves item between stacks.
    it("moveItem moves item between stacks", function()
        item.clearTypes()
        item.defineType("coin", { category="misc", base_stats={}, base_tags={} })
        local mgr = item.newStackManager()
        mgr:createStack("src")
        mgr:createStack("dst")
        local coin = item.newItem("coin")
        mgr:getStack("src"):push(coin)
        local moved = mgr:moveItem("src", 1, "dst")
        expect_equal(moved, coin)
        expect_equal(mgr:getStack("src"):size(), 0)
        expect_equal(mgr:getStack("dst"):size(), 1)
    end)

    -- @description Verifies case: moveItem returns error for missing stack.
    it("moveItem returns error for missing stack", function()
        local mgr = item.newStackManager()
        mgr:createStack("src")
        local moved, err = mgr:moveItem("src", 1, "no_such")
        expect_equal(moved, nil)
        expect_equal(type(err), "string")
    end)

    -- @description Verifies case: moveItemByType finds item by type.
    it("moveItemByType finds item by type", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={}, base_tags={} })
        item.defineType("coin",  { category="misc",   base_stats={}, base_tags={} })
        local mgr = item.newStackManager()
        mgr:createStack("inv")
        mgr:createStack("equip")
        mgr:getStack("inv"):push(item.newItem("coin"))
        mgr:getStack("inv"):push(item.newItem("sword"))
        local moved = mgr:moveItemByType("inv", "sword", "equip")
        expect_equal(moved:getType(), "sword")
        expect_equal(mgr:getStack("equip"):size(), 1)
    end)

    -- @description Verifies case: moveItemByType returns error when type not found.
    it("moveItemByType returns error when type not found", function()
        local mgr = item.newStackManager()
        mgr:createStack("src")
        mgr:createStack("dst")
        local moved, err = mgr:moveItemByType("src", "ghost", "dst")
        expect_equal(moved, nil)
        expect_equal(type(err), "string")
    end)

    -- @description Verifies case: moveTop moves the top item.
    it("moveTop moves the top item", function()
        item.clearTypes()
        item.defineType("ball", { category="misc", base_stats={}, base_tags={} })
        local mgr = item.newStackManager()
        mgr:createStack("src")
        mgr:createStack("dst")
        local a = item.newItem("ball")
        local b = item.newItem("ball")
        mgr:getStack("src"):push(a)
        mgr:getStack("src"):push(b)
        local moved = mgr:moveTop("src", "dst")
        expect_equal(moved, b)
        expect_equal(mgr:getStack("src"):peek(), a)
    end)
end)

-- ─── Slot ─────────────────────────────────────────────────────────────────────

-- @description Tests slot containers for bounded capacity, indexed removal, peeking, clearing, and tag or type presence checks.
describe("Slot", function()
    -- @covers library.item.newSlot
    -- @description Verifies case: push / size / peek round-trip.
    it("push / size / peek round-trip", function()
        local s = item.newSlot("weapon_slot")
        local sword = item.newItem("sword")
        expect_equal(s:push(sword), true)
        expect_equal(s:size(), 1)
        expect_equal(s:peek(), sword)
    end)

    -- @description Verifies case: isEmpty returns true when empty.
    it("isEmpty returns true when empty", function()
        local s = item.newSlot("slot")
        expect_equal(s:isEmpty(), true)
    end)

    -- @description Verifies case: isEmpty returns false after push.
    it("isEmpty returns false after push", function()
        local s = item.newSlot("slot")
        s:push(item.newItem("x"))
        expect_equal(s:isEmpty(), false)
    end)

    -- @description Verifies case: isFull blocks push at capacity.
    it("isFull blocks push at capacity", function()
        local s = item.newSlot("hand", 1)
        s:push(item.newItem("sword"))
        expect_equal(s:isFull(), true)
        expect_equal(s:push(item.newItem("shield")), false)
    end)

    -- @description Verifies case: getCapacity / setCapacity round-trip.
    it("getCapacity / setCapacity round-trip", function()
        local s = item.newSlot("ring_slot", 2)
        expect_equal(s:getCapacity(), 2)
        s:setCapacity(4)
        expect_equal(s:getCapacity(), 4)
    end)

    -- @description Verifies case: pop removes last item.
    it("pop removes last item", function()
        local s = item.newSlot("slot")
        local a = item.newItem("a")
        local b = item.newItem("b")
        s:push(a); s:push(b)
        expect_equal(s:pop(), b)
        expect_equal(s:size(), 1)
    end)

    -- @description Verifies case: removeAt removes item at index.
    it("removeAt removes item at index", function()
        local s = item.newSlot("slot")
        local a = item.newItem("a")
        local b = item.newItem("b")
        s:push(a); s:push(b)
        local removed = s:removeAt(1)
        expect_equal(removed, a)
        expect_equal(s:size(), 1)
    end)

    -- @description Verifies case: peekAt peeks without removal.
    it("peekAt peeks without removal", function()
        local s = item.newSlot("slot")
        local a = item.newItem("a")
        local b = item.newItem("b")
        s:push(a); s:push(b)
        expect_equal(s:peekAt(1), a)
        expect_equal(s:size(), 2)
    end)

    -- @description Verifies case: clear returns all items.
    it("clear returns all items", function()
        local s = item.newSlot("slot")
        local a = item.newItem("a")
        local b = item.newItem("b")
        s:push(a); s:push(b)
        local out = s:clear()
        expect_equal(#out, 2)
        expect_equal(s:isEmpty(), true)
    end)

    -- @description Verifies case: items returns shallow copy.
    it("items returns shallow copy", function()
        local s = item.newSlot("slot")
        local a = item.newItem("a")
        s:push(a)
        local all = s:items()
        expect_equal(#all, 1)
        expect_equal(all[1], a)
    end)

    -- @description Verifies case: hasItemWithTag detects tagged items.
    it("hasItemWithTag detects tagged items", function()
        item.clearTypes()
        local s = item.newSlot("slot")
        local it = item.newItem("ring")
        it:addTag("cursed")
        s:push(it)
        expect_equal(s:hasItemWithTag("cursed"), true)
        expect_equal(s:hasItemWithTag("blessed"), false)
    end)

    -- @description Verifies case: hasItemOfType detects item type.
    it("hasItemOfType detects item type", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={}, base_tags={} })
        local s = item.newSlot("slot")
        s:push(item.newItem("sword"))
        expect_equal(s:hasItemOfType("sword"), true)
        expect_equal(s:hasItemOfType("bow"), false)
    end)

    -- @description Verifies case: getName returns the slot name.
    it("getName returns the slot name", function()
        local s = item.newSlot("offhand")
        expect_equal(s:getName(), "offhand")
    end)
end)

-- ─── sortedIndicesByStat descending ──────────────────────────────────────────

-- @description Verifies stat-based index sorting for ascending, descending, and default-order calls.
describe("sortedIndicesByStat descending", function()
    -- @covers library.item.sortedIndicesByStat
    -- @description Verifies case: ascending=false returns highest-first indices.
    it("ascending=false returns highest-first indices", function()
        item.clearTypes()
        local items = {}
        for _, v in ipairs({3, 1, 4, 1, 5}) do
            local it = item.newItem("x")
            it:setStat("val", v)
            table.insert(items, it)
        end
        local desc = item.sortedIndicesByStat(items, "val", false)
        -- index 5 has val=5, index 3 has val=4
        expect_equal(desc[1], 5)
        expect_equal(desc[2], 3)
    end)

    -- @description Verifies case: ascending=true matches original behaviour.
    it("ascending=true matches original behaviour", function()
        item.clearTypes()
        local items = {}
        for _, v in ipairs({10, 1, 5}) do
            local it = item.newItem("x")
            it:setStat("val", v)
            table.insert(items, it)
        end
        local asc = item.sortedIndicesByStat(items, "val", true)
        expect_equal(asc[1], 2)  -- val=1
        expect_equal(asc[3], 1)  -- val=10
    end)

    -- @description Verifies case: nil ascending defaults to ascending.
    it("nil ascending defaults to ascending", function()
        item.clearTypes()
        local items = {}
        for _, v in ipairs({9, 3}) do
            local it = item.newItem("x")
            it:setStat("v", v)
            table.insert(items, it)
        end
        local idx = item.sortedIndicesByStat(items, "v")
        expect_equal(idx[1], 2)  -- 3 first
    end)
end)

-- ─── Bug fix: clearTypes does not affect existing items ───────────────────────

-- @description Verifies that items created before clearTypes retain their stats, tags, and category.
describe("clearTypes isolation", function()
    -- @description Verifies case: existing items keep stats after clearTypes.
    it("existing items keep stats after clearTypes", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={"sharp"} })
        local it = item.newItem("sword")
        item.clearTypes()
        -- item still has its stats and tags from creation time
        expect_equal(it:getStat("dmg"), 10)
        expect_equal(it:hasTag("sharp"), true)
        expect_equal(it:getCategory(), "weapon")
        expect_equal(it:getType(), "sword")
    end)

    -- @description Verifies case: new items after clearTypes get defaults.
    it("new items after clearTypes get defaults", function()
        item.clearTypes()
        item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={} })
        item.clearTypes()
        -- type no longer registered, newItem gives defaults
        local it = item.newItem("sword")
        expect_equal(it:getStat("dmg"), nil)
        expect_equal(it:getCategory(), "misc")
    end)
end)

-- ─── Bug fix: pool draw edge cases ───────────────────────────────────────────

-- @description Verifies pool draw behavior under empty, nil-return, and unique-type-clamping edge cases.
describe("Pool draw edge cases", function()
    -- @description Verifies case: draw returns nil on empty pool.
    it("draw returns nil on empty pool", function()
        local pool = item.newItemPool()
        expect_equal(pool:draw(), nil)
    end)

    -- @description Verifies case: drawTypes on empty pool returns array with nils.
    it("drawTypes on empty pool returns nils", function()
        local pool = item.newItemPool()
        local drawn = pool:drawTypes(3)
        expect_equal(drawn[1], nil)
        expect_equal(drawn[2], nil)
        expect_equal(drawn[3], nil)
    end)

    -- @description Verifies case: drawUniqueTypes clamps to available unique types.
    it("drawUniqueTypes clamps to available unique types", function()
        item.clearTypes()
        item.defineType("a", { category="misc", base_stats={}, base_tags={} })
        item.defineType("b", { category="misc", base_stats={}, base_tags={} })
        local pool = item.newItemPool()
        pool:addType("a", 1)
        pool:addType("b", 1)
        -- request 10 unique types but only 2 exist
        local drawn = pool:drawUniqueTypes(10)
        expect_equal(#drawn, 2)
        local seen = {}
        for _, it in ipairs(drawn) do seen[it:getType()] = true end
        expect_equal(seen["a"], true)
        expect_equal(seen["b"], true)
    end)

    -- @description Verifies case: drawUniqueTypes with n=0 returns empty.
    it("drawUniqueTypes with n=0 returns empty", function()
        local pool = item.newItemPool()
        pool:addType("x", 1)
        local drawn = pool:drawUniqueTypes(0)
        expect_equal(#drawn, 0)
    end)

    -- @description Verifies case: addType rejects zero weight.
    it("addType rejects zero weight", function()
        local pool = item.newItemPool()
        expect_error(function()
            pool:addType("bad", 0)
        end)
    end)

    -- @description Verifies case: addType rejects negative weight.
    it("addType rejects negative weight", function()
        local pool = item.newItemPool()
        expect_error(function()
            pool:addType("bad", -5)
        end)
    end)

    -- @description Verifies case: setWeight rejects zero weight.
    it("setWeight rejects zero weight", function()
        local pool = item.newItemPool()
        pool:addType("x", 1)
        expect_error(function()
            pool:setWeight("x", 0)
        end)
    end)
end)

-- ─── Bug fix: undefined type items ───────────────────────────────────────────

-- @description Verifies that creating items with unregistered types uses safe defaults.
describe("Undefined type items", function()
    -- @description Verifies case: newItem with unregistered type uses misc defaults.
    it("newItem with unregistered type uses misc defaults", function()
        item.clearTypes()
        local it = item.newItem("nonexistent_type")
        expect_equal(it:getType(), "nonexistent_type")
        expect_equal(it:getCategory(), "misc")
        expect_equal(it:getStat("anything"), nil)
    end)

    -- @description Verifies case: newItem with empty string errors.
    it("newItem with empty string errors", function()
        expect_error(function()
            item.newItem("")
        end)
    end)

    -- @description Verifies case: newItem with nil errors.
    it("newItem with nil errors", function()
        expect_error(function()
            item.newItem(nil)
        end)
    end)
end)

-- ─── Input validation ────────────────────────────────────────────────────────

-- @description Verifies that input validation rejects invalid arguments with descriptive errors.
describe("Input validation", function()
    -- @description Verifies case: defineType rejects nil name.
    it("defineType rejects nil name", function()
        expect_error(function()
            item.defineType(nil, {})
        end)
    end)

    -- @description Verifies case: defineType rejects empty string name.
    it("defineType rejects empty string name", function()
        expect_error(function()
            item.defineType("", {})
        end)
    end)

    -- @description Verifies case: defineType rejects non-table def.
    it("defineType rejects non-table def", function()
        expect_error(function()
            item.defineType("valid", "not a table")
        end)
    end)

    -- @description Verifies case: newStack rejects empty name.
    it("newStack rejects empty name", function()
        expect_error(function()
            item.newStack("")
        end)
    end)

    -- @description Verifies case: newStack rejects negative capacity.
    it("newStack rejects negative capacity", function()
        expect_error(function()
            item.newStack("test", -1)
        end)
    end)

    -- @description Verifies case: setStat rejects empty key.
    it("setStat rejects empty key", function()
        item.clearTypes()
        local it = item.newItem("thing")
        expect_error(function()
            it:setStat("", 5)
        end)
    end)

    -- @description Verifies case: addStat rejects empty key.
    it("addStat rejects empty key", function()
        item.clearTypes()
        local it = item.newItem("thing")
        expect_error(function()
            it:addStat("", 5)
        end)
    end)

    -- @description Verifies case: pool addType rejects empty type_name.
    it("pool addType rejects empty type_name", function()
        local pool = item.newItemPool()
        expect_error(function()
            pool:addType("", 1)
        end)
    end)

    -- @description Verifies case: pool addType rejects non-number weight.
    it("pool addType rejects non-number weight", function()
        local pool = item.newItemPool()
        expect_error(function()
            pool:addType("x", "heavy")
        end)
    end)
end)
test_summary()
