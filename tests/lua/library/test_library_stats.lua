--- BDD tests for library.stats
--- Matches coverage of src/stats/ Rust tests.

require("tests.lua.init")
local Stats = require("library.stats")

-- ── Attribute ─────────────────────────────────────────────────────────────

describe("Attribute", function()
    it("should create with base value", function()
        local a = Stats.newAttribute(50)
        expect_equal(a.base, 50)
        expect_equal(a.regen, 0)
        expect_equal(a.growth, 0)
    end)

    it("should default base to 0", function()
        local a = Stats.newAttribute()
        expect_equal(a.base, 0)
    end)
end)

-- ── Buff ──────────────────────────────────────────────────────────────────

describe("Buff", function()
    it("should create with defaults", function()
        local b = Stats.newBuff("hp", 10)
        expect_equal(b.stat, "hp")
        expect_equal(b.add, 10)
        expect_equal(b.mul, 1)
        expect_equal(b.duration, -1)
        expect_equal(b.source, "")
    end)

    it("should track expiration", function()
        local b = Stats.newBuff("hp", 5, 1, 3, "potion")
        expect_equal(b:isExpired(), false)
        b.remaining = 0
        expect_equal(b:isExpired(), true)
    end)

    it("permanent buff never expires", function()
        local b = Stats.newBuff("hp", 5, 1, -1, "trait")
        expect_equal(b:isExpired(), false)
        b.remaining = -999
        expect_equal(b:isExpired(), false)
    end)
end)

-- ── Skill ─────────────────────────────────────────────────────────────────

describe("Skill", function()
    it("should create with defaults", function()
        local sk = Stats.newSkill()
        expect_equal(sk.level, 0)
        expect_equal(sk.max_level, 10)
        expect_equal(sk.resource, "")
        expect_equal(sk.cost, 0)
        expect_equal(sk.cooldown, 0)
    end)

    it("should accept options", function()
        local sk = Stats.newSkill({ max_level = 5, resource = "mana", cost = 20, cooldown = 3 })
        expect_equal(sk.max_level, 5)
        expect_equal(sk.resource, "mana")
        expect_equal(sk.cost, 20)
        expect_equal(sk.cooldown, 3)
    end)
end)

-- ── Perk ──────────────────────────────────────────────────────────────────

describe("Perk", function()
    it("should create with defaults", function()
        local p = Stats.newPerk()
        expect_equal(p.require_level, 0)
        expect_equal(p.trait_name, nil)
        expect_equal(p.acquired, false)
    end)

    it("should create with options", function()
        local p = Stats.newPerk({ require_level = 5, trait_name = "tough" })
        expect_equal(p.require_level, 5)
        expect_equal(p.trait_name, "tough")
    end)
end)

-- ── ActionPoints ──────────────────────────────────────────────────────────

describe("ActionPoints", function()
    it("should start at max", function()
        local ap = Stats.newActionPoints(6)
        expect_equal(ap.current, 6)
        expect_equal(ap.max, 6)
    end)
end)

-- ── Morale ────────────────────────────────────────────────────────────────

describe("Morale", function()
    it("should start at max", function()
        local m = Stats.newMorale(100)
        expect_equal(m.current, 100)
        expect_equal(m.max, 100)
        expect_equal(m.panic_threshold, 25)
        expect_equal(m.berserk_threshold, 10)
    end)
end)

-- ── LevelThresholds ───────────────────────────────────────────────────────

describe("LevelThresholds", function()
    it("table thresholds", function()
        local t = Stats.newTableThresholds({ 100, 200, 400 })
        expect_equal(t:thresholdFor(1), 100)
        expect_equal(t:thresholdFor(2), 200)
        expect_equal(t:thresholdFor(3), 400)
        expect_equal(t:thresholdFor(99), math.huge)
    end)

    it("linear thresholds", function()
        local t = Stats.newLinearThresholds(100, 100)
        expect_equal(t:thresholdFor(1), 100)
        expect_equal(t:thresholdFor(2), 200)
        expect_equal(t:thresholdFor(5), 500)
    end)
end)

-- ── Sheet basics ──────────────────────────────────────────────────────────

describe("Sheet basics", function()
    it("should create empty sheet", function()
        local s = Stats.newSheet()
        expect_equal(s.level, 1)
        expect_equal(s.xp, 0)
    end)

    it("should define and get attribute", function()
        local s = Stats.newSheet()
        s:define("hp", 100)
        expect_equal(s:get("hp"), 100)
        expect_equal(s:getBase("hp"), 100)
    end)

    it("should return nil for undefined attribute", function()
        local s = Stats.newSheet()
        expect_equal(s:get("nope"), nil)
        expect_equal(s:getBase("nope"), nil)
    end)

    it("should set base value", function()
        local s = Stats.newSheet()
        s:define("hp", 100, { max = 200 })
        s:setBase("hp", 150)
        expect_equal(s:getBase("hp"), 150)
    end)

    it("should clamp base to min/max", function()
        local s = Stats.newSheet()
        s:define("hp", 50, { min = 0, max = 100 })
        s:setBase("hp", 200)
        expect_equal(s:getBase("hp"), 100)
        s:setBase("hp", -10)
        expect_equal(s:getBase("hp"), 0)
    end)

    it("getStatNames returns sorted names", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:define("agi", 12)
        s:define("int", 14)
        local names = s:getStatNames()
        expect_equal(names[1], "agi")
        expect_equal(names[2], "int")
        expect_equal(names[3], "str")
    end)

    it("min/max/regen accessors", function()
        local s = Stats.newSheet()
        s:define("hp", 100)
        s:setMin("hp", 0)
        s:setMax("hp", 200)
        s:setRegen("hp", 5)
        expect_equal(s:getMin("hp"), 0)
        expect_equal(s:getMax("hp"), 200)
        expect_equal(s:getRegen("hp"), 5)
    end)
end)

-- ── Buffs on Sheet ────────────────────────────────────────────────────────

describe("Sheet buffs", function()
    it("addBuff adjusts effective value", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, -1, "blessing")
        expect_equal(s:get("str"), 15)
    end)

    it("multiplicative buff", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 0, 2, -1, "double")
        expect_equal(s:get("str"), 20)
    end)

    it("removeBuff restores value", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        local h = s:addBuff("str", 5, 1, -1, "x")
        expect_equal(s:get("str"), 15)
        s:removeBuff(h)
        expect_equal(s:get("str"), 10)
    end)

    it("clearBuffs removes all", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, -1, "x")
        s:addBuff("str", 3, 1, -1, "y")
        s:clearBuffs()
        expect_equal(s:get("str"), 10)
    end)

    it("clearBuffs by stat", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:define("agi", 8)
        s:addBuff("str", 5, 1, -1, "x")
        s:addBuff("agi", 3, 1, -1, "y")
        s:clearBuffs("str")
        expect_equal(s:get("str"), 10)
        expect_equal(s:get("agi"), 11)
    end)

    it("getBuffs returns active buffs", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, -1, "x")
        local buffs = s:getBuffs("str")
        expect_equal(#buffs, 1)
        expect_equal(buffs[1].add, 5)
    end)

    it("getBuffCount", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, -1, "x")
        s:addBuff("str", 3, 1, -1, "y")
        s:addBuff("agi", 1, 1, -1, "z")
        expect_equal(s:getBuffCount("str"), 2)
        expect_equal(s:getBuffCount(), 3)
    end)
end)

-- ── Traits ────────────────────────────────────────────────────────────────

describe("Traits", function()
    it("apply and remove trait buffs", function()
        Stats.defineTrait("tough", { buffs = { { stat = "hp", add = 20, mul = 1 } } })
        local s = Stats.newSheet()
        s:define("hp", 100)
        s:applyTraitBuffs("tough")
        expect_equal(s:get("hp"), 120)
        expect_equal(s:hasTrait("tough"), true)

        s:removeTraitBuffs("tough")
        expect_equal(s:get("hp"), 100)
        expect_equal(s:hasTrait("tough"), false)
    end)

    it("getActiveTraits", function()
        Stats.defineTrait("fast", { buffs = { { stat = "agi", add = 5, mul = 1 } } })
        local s = Stats.newSheet()
        s:define("agi", 10)
        s:applyTraitBuffs("fast")
        local traits = s:getActiveTraits()
        expect_equal(#traits, 1)
        expect_equal(traits[1], "fast")
    end)
end)

-- ── Skills ────────────────────────────────────────────────────────────────

describe("Skills", function()
    it("define and learn skill", function()
        local s = Stats.newSheet()
        s:defineSkill("fireball", { max_level = 5, resource = "mana", cost = 20, cooldown = 2 })
        expect_equal(s:getSkillLevel("fireball"), 0)
        expect_equal(s:learnSkill("fireball"), true)
        expect_equal(s:getSkillLevel("fireball"), 1)
    end)

    it("cannot exceed max level", function()
        local s = Stats.newSheet()
        s:defineSkill("slash", { max_level = 1 })
        expect_equal(s:learnSkill("slash"), true)
        expect_equal(s:learnSkill("slash"), false)
    end)

    it("useSkill costs resource and starts cooldown", function()
        local s = Stats.newSheet()
        s:define("mana", 100)
        s:defineSkill("heal", { max_level = 5, resource = "mana", cost = 30, cooldown = 5 })
        s:learnSkill("heal")
        local ok = s:useSkill("heal")
        expect_equal(ok, true)
        expect_equal(s:getBase("mana"), 70)
        expect_near(s:getCooldownRemaining("heal"), 5, 0.01)
    end)

    it("useSkill fails when on cooldown", function()
        local s = Stats.newSheet()
        s:define("mana", 100)
        s:defineSkill("heal", { max_level = 5, resource = "mana", cost = 10, cooldown = 5 })
        s:learnSkill("heal")
        s:useSkill("heal")
        local ok, reason = s:useSkill("heal")
        expect_equal(ok, false)
        expect_equal(reason, "on cooldown")
    end)

    it("useSkill fails when not enough resource", function()
        local s = Stats.newSheet()
        s:define("mana", 10)
        s:defineSkill("mega", { max_level = 5, resource = "mana", cost = 50 })
        s:learnSkill("mega")
        local ok, reason = s:useSkill("mega")
        expect_equal(ok, false)
        expect_equal(reason, "not enough resource")
    end)
end)

-- ── Perks ─────────────────────────────────────────────────────────────────

describe("Perks", function()
    it("define and acquire perk", function()
        local s = Stats.newSheet()
        s:definePerk("iron_skin", { require_level = 3 })
        expect_equal(s:hasPerk("iron_skin"), false)
        s.level = 3
        expect_equal(s:acquirePerk("iron_skin"), true)
        expect_equal(s:hasPerk("iron_skin"), true)
    end)

    it("cannot acquire if level too low", function()
        local s = Stats.newSheet()
        s:definePerk("iron_skin", { require_level = 5 })
        expect_equal(s:acquirePerk("iron_skin"), false)
    end)

    it("cannot acquire twice", function()
        local s = Stats.newSheet()
        s:definePerk("lucky", {})
        s:acquirePerk("lucky")
        expect_equal(s:acquirePerk("lucky"), false)
    end)

    it("perk with trait applies buffs", function()
        Stats.defineTrait("armor_up", { buffs = { { stat = "def", add = 10, mul = 1 } } })
        local s = Stats.newSheet()
        s:define("def", 5)
        s:definePerk("tank", { trait_name = "armor_up" })
        s:acquirePerk("tank")
        expect_equal(s:get("def"), 15)
    end)
end)

-- ── Flags ─────────────────────────────────────────────────────────────────

describe("Flags", function()
    it("set/clear/has/get", function()
        local s = Stats.newSheet()
        s:setFlag("poisoned")
        expect_equal(s:hasFlag("poisoned"), true)
        s:clearFlag("poisoned")
        expect_equal(s:hasFlag("poisoned"), false)
    end)

    it("getFlags returns sorted list", function()
        local s = Stats.newSheet()
        s:setFlag("burned")
        s:setFlag("alive")
        local f = s:getFlags()
        expect_equal(f[1], "alive")
        expect_equal(f[2], "burned")
    end)
end)

-- ── XP / Level ────────────────────────────────────────────────────────────

describe("XP and Levelling", function()
    it("addXP gains levels with linear thresholds", function()
        local s = Stats.newSheet()
        s:setLevelThresholds(Stats.newLinearThresholds(100, 100))
        local gained = s:addXP(250)
        -- Level 1 threshold = 100: 250 >= 100 → level 2, xp = 150
        -- Level 2 threshold = 200: 150 < 200 → stop
        expect_equal(gained, 1)
        expect_equal(s:getLevel(), 2)
        expect_equal(s:getXP(), 150)
    end)

    it("addXP gains levels with table thresholds", function()
        local s = Stats.newSheet()
        s:setLevelThresholds(Stats.newTableThresholds({ 50, 100, 200 }))
        local gained = s:addXP(160)
        expect_equal(gained, 2)
        expect_equal(s:getLevel(), 3)
        expect_equal(s:getXP(), 10)
    end)

    it("setXP and setLevel directly", function()
        local s = Stats.newSheet()
        s:setXP(42)
        expect_equal(s:getXP(), 42)
        s:setLevel(10)
        expect_equal(s:getLevel(), 10)
    end)
end)

-- ── Use tracking ──────────────────────────────────────────────────────────

describe("Use tracking", function()
    it("recordUse increments count", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:recordUse("str")
        s:recordUse("str")
        expect_equal(s:getUseCount("str"), 2)
    end)

    it("recordUse applies growth", function()
        local s = Stats.newSheet()
        s:define("str", 10, { growth = 0.5, max = 12 })
        s:recordUse("str")
        expect_near(s:getBase("str"), 10.5, 0.01)
        s:recordUse("str")
        expect_near(s:getBase("str"), 11.0, 0.01)
        s:recordUse("str")
        expect_near(s:getBase("str"), 11.5, 0.01)
        s:recordUse("str")
        expect_near(s:getBase("str"), 12.0, 0.01) -- capped at max
    end)
end)

-- ── Action Points ─────────────────────────────────────────────────────────

describe("Action Points", function()
    it("setActionPoints and spend", function()
        local s = Stats.newSheet()
        s:setActionPoints(6)
        local cur, max = s:getActionPoints()
        expect_equal(cur, 6)
        expect_equal(max, 6)
        expect_equal(s:spendActionPoints(4), true)
        cur, max = s:getActionPoints()
        expect_equal(cur, 2)
    end)

    it("cannot overspend", function()
        local s = Stats.newSheet()
        s:setActionPoints(3)
        expect_equal(s:spendActionPoints(4), false)
    end)

    it("beginTurn resets to max", function()
        local s = Stats.newSheet()
        s:setActionPoints(6)
        s:spendActionPoints(4)
        s:beginTurn()
        local cur = s:getActionPoints()
        expect_equal(cur, 6)
    end)

    it("recoverActionPoints partial recovery", function()
        local s = Stats.newSheet()
        s:setActionPoints(6)
        s:spendActionPoints(4)
        s:recoverActionPoints(2)
        local cur = s:getActionPoints()
        expect_equal(cur, 4)
    end)
end)

-- ── Morale ────────────────────────────────────────────────────────────────

describe("Morale system", function()
    it("adjustMorale and checkMorale", function()
        local s = Stats.newSheet()
        s:setMorale(100)
        s:adjustMorale(-80)
        local cur = s:getMorale()
        expect_equal(cur, 20)
        local state = s:checkMorale()
        expect_equal(state, "panic")
        expect_equal(s:hasFlag("panic"), true)
    end)

    it("berserk at low morale", function()
        local s = Stats.newSheet()
        s:setMorale(100)
        s:adjustMorale(-95)
        local state = s:checkMorale()
        expect_equal(state, "berserk")
        expect_equal(s:hasFlag("berserk"), true)
    end)

    it("nil when morale is fine", function()
        local s = Stats.newSheet()
        s:setMorale(100)
        local state = s:checkMorale()
        expect_equal(state, nil)
    end)

    it("custom thresholds", function()
        local s = Stats.newSheet()
        s:setMorale(100)
        s:setPanicThreshold(50)
        s:setBerserkThreshold(20)
        s:adjustMorale(-60)
        local state = s:checkMorale()
        expect_equal(state, "panic")
    end)
end)

-- ── Resistances ───────────────────────────────────────────────────────────

describe("Resistances", function()
    it("setResistance and getResistance", function()
        local s = Stats.newSheet()
        s:setResistance("fire", 0.5)
        expect_near(s:getResistance("fire"), 0.5, 0.01)
        expect_near(s:getResistance("ice"), 0.0, 0.01)
    end)

    it("applyDamage reduced by resistance", function()
        local s = Stats.newSheet()
        s:define("hp", 100)
        s:setResistance("fire", 0.25)
        local actual = s:applyDamage("hp", 40, "fire")
        expect_near(actual, 30, 0.01)
        expect_near(s:getBase("hp"), 70, 0.01)
    end)

    it("applyDamage without type ignores resistances", function()
        local s = Stats.newSheet()
        s:define("hp", 100)
        s:setResistance("fire", 0.5)
        local actual = s:applyDamage("hp", 20)
        expect_near(actual, 20, 0.01)
        expect_near(s:getBase("hp"), 80, 0.01)
    end)
end)

-- ── Encumbrance ───────────────────────────────────────────────────────────

describe("Encumbrance", function()
    it("setEncumbrance and isEncumbered", function()
        local s = Stats.newSheet()
        s:setEncumbrance(50, 100)
        local cur, max = s:getEncumbrance()
        expect_equal(cur, 50)
        expect_equal(max, 100)
        expect_equal(s:isEncumbered(), false)
    end)

    it("over encumbrance limit", function()
        local s = Stats.newSheet()
        s:setEncumbrance(150, 100)
        expect_equal(s:isEncumbered(), true)
    end)
end)

-- ── Initiative ────────────────────────────────────────────────────────────

describe("Initiative", function()
    it("setInitiative and getInitiative", function()
        local s = Stats.newSheet()
        expect_equal(s:getInitiative(), 10) -- default
        s:setInitiative(25)
        expect_equal(s:getInitiative(), 25)
    end)
end)

-- ── Update (tick) ─────────────────────────────────────────────────────────

describe("Update tick", function()
    it("expires timed buffs", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, 2, "potion")
        expect_equal(s:get("str"), 15)
        s:update(3) -- 3 seconds passes, buff had 2s duration
        expect_equal(s:get("str"), 10)
    end)

    it("ticks skill cooldowns", function()
        local s = Stats.newSheet()
        s:defineSkill("heal", { max_level = 5, cooldown = 5 })
        s:learnSkill("heal")
        s:useSkill("heal")
        s:update(3)
        expect_near(s:getCooldownRemaining("heal"), 2, 0.01)
        s:update(3)
        expect_near(s:getCooldownRemaining("heal"), 0, 0.01)
    end)

    it("applies regen", function()
        local s = Stats.newSheet()
        s:define("hp", 80, { max = 100, regen = 10 })
        s:update(1) -- 1 second, regen 10/s
        expect_near(s:getBase("hp"), 90, 0.01)
    end)

    it("regen clamped to max", function()
        local s = Stats.newSheet()
        s:define("hp", 95, { max = 100, regen = 10 })
        s:update(1)
        expect_near(s:getBase("hp"), 100, 0.01)
    end)
end)

-- ── Snapshot/Restore ──────────────────────────────────────────────────────

describe("Snapshot and Restore", function()
    it("snapshot captures and restores state", function()
        local s = Stats.newSheet()
        s:define("hp", 100, { min = 0, max = 200 })
        s:define("str", 15)
        s:setFlag("alive")
        s:setResistance("fire", 0.3)
        s:setActionPoints(6)
        s:setMorale(100)
        s:addXP(50)

        local snap = s:snapshot()

        -- Mutate
        s:setBase("hp", 1)
        s:clearFlag("alive")
        s:setResistance("fire", 0)
        s:adjustMorale(-90)

        s:restore(snap)
        expect_equal(s:getBase("hp"), 100)
        expect_equal(s:getBase("str"), 15)
        expect_equal(s:hasFlag("alive"), true)
        expect_near(s:getResistance("fire"), 0.3, 0.01)
        expect_equal(s:getXP(), 50)
    end)
end)

-- ── Registry ──────────────────────────────────────────────────────────────

describe("StatsRegistry", function()
    it("defineTrait and getTraitNames", function()
        Stats.defineTrait("brawler", { buffs = { { stat = "str", add = 3, mul = 1 } } })
        local names = Stats.getTraitNames()
        local found = false
        for _, n in ipairs(names) do if n == "brawler" then found = true end end
        expect_equal(found, true)
    end)

    it("defineRace and getRaceNames", function()
        Stats.defineRace("human", { bases = { hp = 10 }, traits = {} })
        Stats.defineRace("elf", { bases = { agi = 5 }, traits = {} })
        local names = Stats.getRaceNames()
        local found = false
        for _, n in ipairs(names) do if n == "human" then found = true end end
        expect_equal(found, true)
    end)

    it("applyArchetypes applies race bases", function()
        Stats.defineRace("dwarf", { bases = { hp = 20, str = 5 }, traits = {} })
        local s = Stats.newSheet()
        s:define("hp", 100)
        s:define("str", 10)
        Stats.applyArchetypes(s, "dwarf")
        expect_equal(s:getBase("hp"), 120)
        expect_equal(s:getBase("str"), 15)
    end)

    it("applyArchetypes applies class", function()
        Stats.defineClass("warrior", { bases = { str = 10 }, traits = {} })
        local s = Stats.newSheet()
        s:define("str", 10)
        Stats.applyArchetypes(s, nil, "warrior")
        expect_equal(s:getBase("str"), 20)
    end)

    it("applyArchetypes applies race traits", function()
        Stats.defineTrait("nimble", { buffs = { { stat = "agi", add = 8, mul = 1 } } })
        Stats.defineRace("catfolk", { bases = {}, traits = { "nimble" } })
        local s = Stats.newSheet()
        s:define("agi", 10)
        Stats.applyArchetypes(s, "catfolk")
        expect_equal(s:get("agi"), 18)
    end)

    it("getClassNames returns registered class names", function()
        Stats.defineClass("mage", { bases = { int = 10 }, traits = {} })
        Stats.defineClass("rogue", { bases = { agi = 8 }, traits = {} })
        local names = Stats.getClassNames()
        local found_mage, found_rogue = false, false
        for _, n in ipairs(names) do
            if n == "mage"  then found_mage  = true end
            if n == "rogue" then found_rogue = true end
        end
        expect_equal(found_mage,  true)
        expect_equal(found_rogue, true)
        -- verify sorted order: mage < rogue
        local mage_pos, rogue_pos = nil, nil
        for i, n in ipairs(names) do
            if n == "mage"  then mage_pos  = i end
            if n == "rogue" then rogue_pos = i end
        end
        expect_equal(mage_pos < rogue_pos, true)
    end)
end)

test_summary()
