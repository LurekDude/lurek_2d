--- BDD tests for library.stats
--- Matches coverage of src/stats/ Rust tests.

require("tests/lua/init")
local Stats = require("library.stats")

--                  Attribute

-- @description Verifies attribute defaults and optional base-value initialization for simple numeric stats.
describe("Attribute", function()
    -- @covers library.stats.newAttribute
    -- @description Verifies attributes preserve an explicit base value and start with zero regen and growth.
    it("should create with base value", function()
        local a = Stats.newAttribute(50)
        expect_equal(a.base, 50)
        expect_equal(a.regen, 0)
        expect_equal(a.growth, 0)
    end)

    -- @covers library.stats.newAttribute
    -- @description Confirms attributes default their base value to zero when none is supplied.
    it("should default base to 0", function()
        local a = Stats.newAttribute()
        expect_equal(a.base, 0)
    end)
end)

--                  Buff

-- @description Covers buff defaults, source metadata, and expiration behavior for timed and permanent modifiers.
describe("Buff", function()
    -- @covers library.stats.newBuff
    -- @description Verifies new buffs capture stat, additive value, multiplier, duration, and source defaults.
    it("should create with defaults", function()
        local b = Stats.newBuff("hp", 10)
        expect_equal(b.stat, "hp")
        expect_equal(b.add, 10)
        expect_equal(b.mul, 1)
        expect_equal(b.duration, -1)
        expect_equal(b.source, "")
    end)

    -- @covers library.stats.newBuff
    -- @description Checks finite buffs report expired only after their remaining duration reaches zero.
    it("should track expiration", function()
        local b = Stats.newBuff("hp", 5, 1, 3, "potion")
        expect_equal(b:isExpired(), false)
        b.remaining = 0
        expect_equal(b:isExpired(), true)
    end)

    -- @covers library.stats.newBuff
    -- @description Confirms permanent buffs never expire even if remaining is driven below zero.
    it("permanent buff never expires", function()
        local b = Stats.newBuff("hp", 5, 1, -1, "trait")
        expect_equal(b:isExpired(), false)
        b.remaining = -999
        expect_equal(b:isExpired(), false)
    end)
end)

--                  Skill

-- @description Tests skill defaults and option-based overrides for max level, resource costs, and cooldown metadata.
describe("Skill", function()
    -- @covers library.stats.newSkill
    -- @description Verifies new skills expose the documented default level cap, resource, cost, and cooldown values.
    it("should create with defaults", function()
        local sk = Stats.newSkill()
        expect_equal(sk.level, 0)
        expect_equal(sk.max_level, 10)
        expect_equal(sk.resource, "")
        expect_equal(sk.cost, 0)
        expect_equal(sk.cooldown, 0)
    end)

    -- @covers library.stats.newSkill
    -- @description Confirms skill option tables override max level, resource, cost, and cooldown metadata.
    it("should accept options", function()
        local sk = Stats.newSkill({ max_level = 5, resource = "mana", cost = 20, cooldown = 3 })
        expect_equal(sk.max_level, 5)
        expect_equal(sk.resource, "mana")
        expect_equal(sk.cost, 20)
        expect_equal(sk.cooldown, 3)
    end)
end)

--                  Perk

-- @description Verifies perk defaults and option-driven requirement or trait metadata.
describe("Perk", function()
    -- @covers library.stats.newPerk
    -- @description Verifies perks start with default level requirements, no trait binding, and an unacquired state.
    it("should create with defaults", function()
        local p = Stats.newPerk()
        expect_equal(p.require_level, 0)
        expect_equal(p.trait_name, nil)
        expect_equal(p.acquired, false)
    end)

    -- @covers library.stats.newPerk
    -- @description Confirms perk option tables override level requirements and trait linkage.
    it("should create with options", function()
        local p = Stats.newPerk({ require_level = 5, trait_name = "tough" })
        expect_equal(p.require_level, 5)
        expect_equal(p.trait_name, "tough")
    end)
end)

--                  ActionPoints

-- @description Confirms action-point objects start at their configured maximum value.
describe("ActionPoints", function()
    -- @covers library.stats.newActionPoints
    -- @description Checks action-point objects start with current points equal to their configured maximum.
    it("should start at max", function()
        local ap = Stats.newActionPoints(6)
        expect_equal(ap.current, 6)
        expect_equal(ap.max, 6)
    end)
end)

--                  Morale

-- @description Verifies morale defaults including current, max, and threshold values for panic and berserk states.
describe("Morale", function()
    -- @covers library.stats.newMorale
    -- @description Verifies morale objects start full and expose the documented panic and berserk thresholds.
    it("should start at max", function()
        local m = Stats.newMorale(100)
        expect_equal(m.current, 100)
        expect_equal(m.max, 100)
        expect_equal(m.panic_threshold, 25)
        expect_equal(m.berserk_threshold, 10)
    end)
end)

--                  LevelThresholds

-- @description Exercises table-based and linear level-threshold calculators across known and out-of-range levels.
describe("LevelThresholds", function()
    -- @covers library.stats.newTableThresholds
    -- @covers library.stats.newLinearThresholds
    -- @description Checks table-based thresholds return exact configured values and infinity for out-of-range levels.
    it("table thresholds", function()
        local t = Stats.newTableThresholds({ 100, 200, 400 })
        expect_equal(t:thresholdFor(1), 100)
        expect_equal(t:thresholdFor(2), 200)
        expect_equal(t:thresholdFor(3), 400)
        expect_equal(t:thresholdFor(99), math.huge)
    end)

    -- @covers library.stats.newLinearThresholds
    -- @description Verifies linear thresholds scale level requirements by the configured base and step amounts.
    it("linear thresholds", function()
        local t = Stats.newLinearThresholds(100, 100)
        expect_equal(t:thresholdFor(1), 100)
        expect_equal(t:thresholdFor(2), 200)
        expect_equal(t:thresholdFor(5), 500)
    end)
end)

--                  Sheet basics

-- @description Covers core sheet behavior for defining stats, clamping base values, and querying min, max, regen, and sorted stat names.
describe("Sheet basics", function()
    -- @covers library.stats.newSheet
    -- @description Verifies new stat sheets start at level one with zero accumulated XP.
    it("should create empty sheet", function()
        local s = Stats.newSheet()
        expect_equal(s.level, 1)
        expect_equal(s.xp, 0)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks sheets can define an attribute and return both its effective and base values.
    it("should define and get attribute", function()
        local s = Stats.newSheet()
        s:define("hp", 100)
        expect_equal(s:get("hp"), 100)
        expect_equal(s:getBase("hp"), 100)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms querying an undefined attribute returns nil for both effective and base lookups.
    it("should return nil for undefined attribute", function()
        local s = Stats.newSheet()
        expect_equal(s:get("nope"), nil)
        expect_equal(s:getBase("nope"), nil)
    end)

    -- @covers library.stats.newSheet
    -- @description Verifies setBase updates a defined attribute while respecting its stored constraints.
    it("should set base value", function()
        local s = Stats.newSheet()
        s:define("hp", 100, { max = 200 })
        s:setBase("hp", 150)
        expect_equal(s:getBase("hp"), 150)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks base values clamp to configured minimum and maximum bounds.
    it("should clamp base to min/max", function()
        local s = Stats.newSheet()
        s:define("hp", 50, { min = 0, max = 100 })
        s:setBase("hp", 200)
        expect_equal(s:getBase("hp"), 100)
        s:setBase("hp", -10)
        expect_equal(s:getBase("hp"), 0)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms getStatNames returns defined stat identifiers in sorted order.
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

    -- @covers library.stats.newSheet
    -- @description Verifies min, max, and regen accessors round-trip the configured stat metadata.
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

--                  Buffs on Sheet

-- @description Validates sheet-level buff application, multiplicative modifiers, removal, filtering, and aggregate buff counting.
describe("Sheet buffs", function()
    -- @covers library.stats.newSheet
    -- @description Checks additive buffs increase a stat's effective value while leaving the base intact.
    it("addBuff adjusts effective value", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, -1, "blessing")
        expect_equal(s:get("str"), 15)
    end)

    -- @covers library.stats.newSheet
    -- @description Verifies multiplicative buffs scale the effective stat value.
    it("multiplicative buff", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 0, 2, -1, "double")
        expect_equal(s:get("str"), 20)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms removing a buff restores the effective stat value to its unbuffed amount.
    it("removeBuff restores value", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        local h = s:addBuff("str", 5, 1, -1, "x")
        expect_equal(s:get("str"), 15)
        s:removeBuff(h)
        expect_equal(s:get("str"), 10)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks clearBuffs without a stat argument removes all active buffs from the sheet.
    it("clearBuffs removes all", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, -1, "x")
        s:addBuff("str", 3, 1, -1, "y")
        s:clearBuffs()
        expect_equal(s:get("str"), 10)
    end)

    -- @covers library.stats.newSheet
    -- @description Verifies stat-scoped clearBuffs removes buffs only from the requested stat.
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

    -- @covers library.stats.newSheet
    -- @description Confirms getBuffs returns the active buffs for a specific stat.
    it("getBuffs returns active buffs", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, -1, "x")
        local buffs = s:getBuffs("str")
        expect_equal(#buffs, 1)
        expect_equal(buffs[1].add, 5)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks getBuffCount reports per-stat counts and the total active buff count.
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

--                  Traits

-- @description Tests trait registration and application so trait buffs alter sheet values and can be added or removed cleanly.
describe("Traits", function()
    -- @covers library.stats.defineTrait
    -- @covers library.stats.newSheet
    -- @description Verifies applying a registered trait adds its buffs and removing it restores the original stat values.
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

    -- @covers library.stats.defineTrait
    -- @covers library.stats.newSheet
    -- @description Confirms getActiveTraits reports currently applied traits on the sheet.
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

--                  Skills

-- @description Exercises sheet-managed skills for learning, leveling, resource costs, cooldowns, and ready-state checks.
describe("Skills", function()
    -- @covers library.stats.newSheet
    -- @description Checks sheets can define and learn skills while incrementing their learned level.
    it("define and learn skill", function()
        local s = Stats.newSheet()
        s:defineSkill("fireball", { max_level = 5, resource = "mana", cost = 20, cooldown = 2 })
        expect_equal(s:getSkillLevel("fireball"), 0)
        expect_equal(s:learnSkill("fireball"), true)
        expect_equal(s:getSkillLevel("fireball"), 1)
    end)

    -- @covers library.stats.newSheet
    -- @description Verifies learning a skill stops at the configured maximum level.
    it("cannot exceed max level", function()
        local s = Stats.newSheet()
        s:defineSkill("slash", { max_level = 1 })
        expect_equal(s:learnSkill("slash"), true)
        expect_equal(s:learnSkill("slash"), false)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms using a skill spends the required resource and starts the configured cooldown timer.
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

    -- @covers library.stats.newSheet
    -- @description Checks useSkill reports an on-cooldown error when the skill is used again too soon.
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

    -- @covers library.stats.newSheet
    -- @description Verifies skills cannot be used when the sheet lacks the required resource amount.
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

--                  Perks

-- @description Covers perk acquisition rules, trait side effects, and level-gated unlock behavior on stat sheets.
describe("Perks", function()
    -- @covers library.stats.newSheet
    -- @description Confirms sheets can define and acquire perks once their level requirement is met.
    it("define and acquire perk", function()
        local s = Stats.newSheet()
        s:definePerk("iron_skin", { require_level = 3 })
        expect_equal(s:hasPerk("iron_skin"), false)
        s.level = 3
        expect_equal(s:acquirePerk("iron_skin"), true)
        expect_equal(s:hasPerk("iron_skin"), true)
    end)

    -- @covers library.stats.newSheet
    -- @description Verifies perk acquisition fails while the sheet level remains below the requirement.
    it("cannot acquire if level too low", function()
        local s = Stats.newSheet()
        s:definePerk("iron_skin", { require_level = 5 })
        expect_equal(s:acquirePerk("iron_skin"), false)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks perks cannot be acquired more than once.
    it("cannot acquire twice", function()
        local s = Stats.newSheet()
        s:definePerk("lucky", {})
        s:acquirePerk("lucky")
        expect_equal(s:acquirePerk("lucky"), false)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms perks linked to traits apply the trait buffs when acquired.
    it("perk with trait applies buffs", function()
        Stats.defineTrait("armor_up", { buffs = { { stat = "def", add = 10, mul = 1 } } })
        local s = Stats.newSheet()
        s:define("def", 5)
        s:definePerk("tank", { trait_name = "armor_up" })
        s:acquirePerk("tank")
        expect_equal(s:get("def"), 15)
    end)
end)

--                  Flags

-- @description Verifies generic boolean flag storage for adding, clearing, and testing named status flags.
describe("Flags", function()
    -- @covers library.stats.newSheet
    -- @description Verifies flags can be set, queried, and cleared on a sheet.
    it("set/clear/has/get", function()
        local s = Stats.newSheet()
        s:setFlag("poisoned")
        expect_equal(s:hasFlag("poisoned"), true)
        s:clearFlag("poisoned")
        expect_equal(s:hasFlag("poisoned"), false)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms getFlags returns all active flags in sorted order.
    it("getFlags returns sorted list", function()
        local s = Stats.newSheet()
        s:setFlag("burned")
        s:setFlag("alive")
        local f = s:getFlags()
        expect_equal(f[1], "alive")
        expect_equal(f[2], "burned")
    end)
end)

--                  XP / Level

-- @description Tests XP accumulation, level thresholds, multi-level gains, and threshold assignment on character sheets.
describe("XP and Levelling", function()
    -- @covers library.stats.newSheet
    -- @covers library.stats.newLinearThresholds
    -- @description Checks XP gains against linear thresholds can promote the sheet by one or more levels while carrying leftover XP.
    it("addXP gains levels with linear thresholds", function()
        local s = Stats.newSheet()
        s:setLevelThresholds(Stats.newLinearThresholds(100, 100))
        local gained = s:addXP(250)
        -- Level 1 threshold = 100: 250 >= 100          level 2, xp = 150
        -- Level 2 threshold = 200: 150 < 200          stop
        expect_equal(gained, 1)
        expect_equal(s:getLevel(), 2)
        expect_equal(s:getXP(), 150)
    end)

    -- @covers library.stats.newSheet
    -- @covers library.stats.newTableThresholds
    -- @description Verifies XP gains against table thresholds can cross multiple levels with the correct leftover XP.
    it("addXP gains levels with table thresholds", function()
        local s = Stats.newSheet()
        s:setLevelThresholds(Stats.newTableThresholds({ 50, 100, 200 }))
        local gained = s:addXP(160)
        expect_equal(gained, 2)
        expect_equal(s:getLevel(), 3)
        expect_equal(s:getXP(), 10)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms XP and level setters directly update the stored progression values.
    it("setXP and setLevel directly", function()
        local s = Stats.newSheet()
        s:setXP(42)
        expect_equal(s:getXP(), 42)
        s:setLevel(10)
        expect_equal(s:getLevel(), 10)
    end)
end)

--                  Use tracking

-- @description Covers usage counters and derived proficiency or tracking helpers tied to repeated action use.
describe("Use tracking", function()
    -- @covers library.stats.newSheet
    -- @description Verifies recordUse increments the tracked usage count for a stat.
    it("recordUse increments count", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:recordUse("str")
        s:recordUse("str")
        expect_equal(s:getUseCount("str"), 2)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks recordUse also applies stat growth over time while respecting the stat maximum.
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

--                  Action Points

-- @description Exercises action-point mutation, spending, refreshing, and clamp behavior on the sheet wrapper.
describe("Action Points", function()
    -- @covers library.stats.newSheet
    -- @description Verifies sheets can set action points, spend some, and report the remaining and maximum values.
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

    -- @covers library.stats.newSheet
    -- @description Confirms spending more action points than available fails without changing the state.
    it("cannot overspend", function()
        local s = Stats.newSheet()
        s:setActionPoints(3)
        expect_equal(s:spendActionPoints(4), false)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks beginTurn refreshes current action points back to their maximum.
    it("beginTurn resets to max", function()
        local s = Stats.newSheet()
        s:setActionPoints(6)
        s:spendActionPoints(4)
        s:beginTurn()
        local cur = s:getActionPoints()
        expect_equal(cur, 6)
    end)

    -- @covers library.stats.newSheet
    -- @description Verifies recoverActionPoints restores only part of the missing action points when given a partial amount.
    it("recoverActionPoints partial recovery", function()
        local s = Stats.newSheet()
        s:setActionPoints(6)
        s:spendActionPoints(4)
        s:recoverActionPoints(2)
        local cur = s:getActionPoints()
        expect_equal(cur, 4)
    end)
end)

--                  Morale

-- @description Validates morale changes, threshold overrides, and panic or berserk state detection with flag side effects.
describe("Morale system", function()
    -- @covers library.stats.newSheet
    -- @description Checks morale loss can trigger panic and set the corresponding status flag.
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

    -- @covers library.stats.newSheet
    -- @description Verifies extreme morale loss crosses the berserk threshold and sets the berserk flag.
    it("berserk at low morale", function()
        local s = Stats.newSheet()
        s:setMorale(100)
        s:adjustMorale(-95)
        local state = s:checkMorale()
        expect_equal(state, "berserk")
        expect_equal(s:hasFlag("berserk"), true)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms checkMorale returns nil when morale remains above all danger thresholds.
    it("nil when morale is fine", function()
        local s = Stats.newSheet()
        s:setMorale(100)
        local state = s:checkMorale()
        expect_equal(state, nil)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks custom panic and berserk thresholds change the state returned by morale evaluation.
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

--                  Resistances

-- @description Covers resistance assignment and typed damage application, including fallback behavior when no damage type is supplied.
describe("Resistances", function()
    -- @covers library.stats.newSheet
    -- @description Verifies resistance values can be set and default to zero for unknown damage types.
    it("setResistance and getResistance", function()
        local s = Stats.newSheet()
        s:setResistance("fire", 0.5)
        expect_near(s:getResistance("fire"), 0.5, 0.01)
        expect_near(s:getResistance("ice"), 0.0, 0.01)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks applyDamage scales damage by the configured resistance before subtracting HP.
    it("applyDamage reduced by resistance", function()
        local s = Stats.newSheet()
        s:define("hp", 100)
        s:setResistance("fire", 0.25)
        local actual = s:applyDamage("hp", 40, "fire")
        expect_near(actual, 30, 0.01)
        expect_near(s:getBase("hp"), 70, 0.01)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms damage without a type bypasses resistance modifiers.
    it("applyDamage without type ignores resistances", function()
        local s = Stats.newSheet()
        s:define("hp", 100)
        s:setResistance("fire", 0.5)
        local actual = s:applyDamage("hp", 20)
        expect_near(actual, 20, 0.01)
        expect_near(s:getBase("hp"), 80, 0.01)
    end)
end)

--                  Encumbrance

-- @description Verifies encumbrance tracking and the threshold check that marks a sheet as encumbered.
describe("Encumbrance", function()
    -- @covers library.stats.newSheet
    -- @description Verifies encumbrance values round-trip and remain unencumbered while current load is within the limit.
    it("setEncumbrance and isEncumbered", function()
        local s = Stats.newSheet()
        s:setEncumbrance(50, 100)
        local cur, max = s:getEncumbrance()
        expect_equal(cur, 50)
        expect_equal(max, 100)
        expect_equal(s:isEncumbered(), false)
    end)

    -- @covers library.stats.newSheet
    -- @description Confirms isEncumbered becomes true once current load exceeds the maximum.
    it("over encumbrance limit", function()
        local s = Stats.newSheet()
        s:setEncumbrance(150, 100)
        expect_equal(s:isEncumbered(), true)
    end)
end)

--                  Initiative

-- @description Confirms initiative has a default value and supports direct set or get mutation.
describe("Initiative", function()
    -- @covers library.stats.newSheet
    -- @description Checks initiative starts at the default value and can be updated explicitly.
    it("setInitiative and getInitiative", function()
        local s = Stats.newSheet()
        expect_equal(s:getInitiative(), 10) -- default
        s:setInitiative(25)
        expect_equal(s:getInitiative(), 25)
    end)
end)

--                  Update (tick)

-- @description Exercises periodic update logic for timed buff expiry, cooldown ticking, and regeneration clamped by stat maxima.
describe("Update tick", function()
    -- @covers library.stats.newSheet
    -- @description Verifies timed buffs expire and stop affecting stats once their duration elapses during update.
    it("expires timed buffs", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, 2, "potion")
        expect_equal(s:get("str"), 15)
        s:update(3) -- 3 seconds passes, buff had 2s duration
        expect_equal(s:get("str"), 10)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks update decrements active skill cooldown timers until they reach zero.
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

    -- @covers library.stats.newSheet
    -- @description Confirms update applies per-second regeneration to base stats.
    it("applies regen", function()
        local s = Stats.newSheet()
        s:define("hp", 80, { max = 100, regen = 10 })
        s:update(1) -- 1 second, regen 10/s
        expect_near(s:getBase("hp"), 90, 0.01)
    end)

    -- @covers library.stats.newSheet
    -- @description Verifies regeneration is clamped so base stats never exceed their configured maximum.
    it("regen clamped to max", function()
        local s = Stats.newSheet()
        s:define("hp", 95, { max = 100, regen = 10 })
        s:update(1)
        expect_near(s:getBase("hp"), 100, 0.01)
    end)
end)

--                  Snapshot/Restore

-- @description Tests serializing a sheet snapshot and restoring it after mutations to recover stats, flags, resistances, and XP.
describe("Snapshot and Restore", function()
    -- @covers library.stats.newSheet
    -- @description Checks snapshot captures sheet state and restore reinstates stats, flags, resistances, and XP after mutations.
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

--                  Registry

-- @description Validates registry helpers for traits, races, and classes together with archetype application and sorted name lookups.
describe("StatsRegistry", function()
    -- @covers library.stats.defineTrait
    -- @covers library.stats.defineRace
    -- @covers library.stats.defineClass
    -- @covers library.stats.applyArchetypes
    -- @description Verifies defining a trait makes its name visible through the exported trait registry lookup.
    it("defineTrait and getTraitNames", function()
        Stats.defineTrait("brawler", { buffs = { { stat = "str", add = 3, mul = 1 } } })
        local names = Stats.getTraitNames()
        local found = false
        for _, n in ipairs(names) do if n == "brawler" then found = true end end
        expect_equal(found, true)
    end)

    -- @covers library.stats.defineRace
    -- @description Confirms defined races appear in the exported race-name registry.
    it("defineRace and getRaceNames", function()
        Stats.defineRace("human", { bases = { hp = 10 }, traits = {} })
        Stats.defineRace("elf", { bases = { agi = 5 }, traits = {} })
        local names = Stats.getRaceNames()
        local found = false
        for _, n in ipairs(names) do if n == "human" then found = true end end
        expect_equal(found, true)
    end)

    -- @covers library.stats.applyArchetypes
    -- @covers library.stats.defineRace
    -- @description Checks applying a race archetype adds its base stat adjustments onto an existing sheet.
    it("applyArchetypes applies race bases", function()
        Stats.defineRace("dwarf", { bases = { hp = 20, str = 5 }, traits = {} })
        local s = Stats.newSheet()
        s:define("hp", 100)
        s:define("str", 10)
        Stats.applyArchetypes(s, "dwarf")
        expect_equal(s:getBase("hp"), 120)
        expect_equal(s:getBase("str"), 15)
    end)

    -- @covers library.stats.applyArchetypes
    -- @covers library.stats.defineClass
    -- @description Verifies applying a class archetype adds the class base stats to the sheet.
    it("applyArchetypes applies class", function()
        Stats.defineClass("warrior", { bases = { str = 10 }, traits = {} })
        local s = Stats.newSheet()
        s:define("str", 10)
        Stats.applyArchetypes(s, nil, "warrior")
        expect_equal(s:getBase("str"), 20)
    end)

    -- @covers library.stats.applyArchetypes
    -- @covers library.stats.defineTrait
    -- @covers library.stats.defineRace
    -- @description Confirms race-linked traits are also applied when applying archetypes for that race.
    it("applyArchetypes applies race traits", function()
        Stats.defineTrait("nimble", { buffs = { { stat = "agi", add = 8, mul = 1 } } })
        Stats.defineRace("catfolk", { bases = {}, traits = { "nimble" } })
        local s = Stats.newSheet()
        s:define("agi", 10)
        Stats.applyArchetypes(s, "catfolk")
        expect_equal(s:get("agi"), 18)
    end)

    -- @covers library.stats.defineClass
    -- @description Verifies the class registry exposes defined class names and keeps them in sorted order.
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

--        Buff formula correctness

-- @description Validates the corrected buff formula: base * mul_prod + add_sum.
describe("Buff formula", function()
    -- @covers library.stats.newSheet
    -- @description Verifies that a zero multiplier zeroes only the base, not the additive bonuses.
    it("zero multiplier preserves additive buffs", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 0, -1, "nullify")
        -- Formula: 10 * 0 + 5 = 5 (NOT (10+5)*0 = 0)
        expect_equal(s:get("str"), 5)
    end)

    -- @covers library.stats.newSheet
    -- @description Verifies combined additive and multiplicative buffs use base*mul+add formula.
    it("combined add and mul uses correct order", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 2, -1, "combo")
        -- Formula: 10 * 2 + 5 = 25 (NOT (10+5)*2 = 30)
        expect_equal(s:get("str"), 25)
    end)

    -- @covers library.stats.newSheet
    -- @description Checks multiple buffs stack correctly with the new formula.
    it("multiple buffs stack correctly", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 3, 1, -1, "a")
        s:addBuff("str", 2, 1.5, -1, "b")
        -- add_sum = 3+2 = 5, mul_prod = 1*1.5 = 1.5
        -- Formula: 10 * 1.5 + 5 = 20
        expect_near(s:get("str"), 20, 0.01)
    end)

    -- @covers library.stats.newSheet
    -- @description Verifies pure multiplicative buff without additive component.
    it("pure multiplicative only", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 0, 3, -1, "triple")
        expect_equal(s:get("str"), 30)
    end)
end)

--        Stack mode enforcement

-- @description Tests that StackMode is enforced when adding duplicate buffs.
describe("Buff stack modes", function()
    -- @covers library.stats.newSheet
    -- @description StackMode.None rejects a duplicate buff with the same stat+source.
    it("None rejects duplicate", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        local h1 = s:addBuff("str", 5, 1, -1, "aura", Stats.StackMode.None)
        expect_equal(h1 ~= nil, true)
        local h2 = s:addBuff("str", 5, 1, -1, "aura", Stats.StackMode.None)
        expect_equal(h2, nil)
        expect_equal(s:getBuffCount("str"), 1)
        expect_equal(s:get("str"), 15)
    end)

    -- @covers library.stats.newSheet
    -- @description StackMode.Duration extends the remaining time of an existing duplicate buff.
    it("Duration extends existing buff", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        local h1 = s:addBuff("str", 5, 1, 10, "potion", Stats.StackMode.Duration)
        local h2 = s:addBuff("str", 5, 1, 5, "potion", Stats.StackMode.Duration)
        -- Should return the same handle
        expect_equal(h1, h2)
        -- Should still be one buff
        expect_equal(s:getBuffCount("str"), 1)
        -- Duration should be extended
        local buffs = s:getBuffs("str")
        expect_equal(buffs[1].duration, 15) -- 10 + 5
        expect_equal(buffs[1].remaining, 15) -- 10 + 5
    end)

    -- @covers library.stats.newSheet
    -- @description StackMode.Intensity increases the additive value of an existing duplicate buff.
    it("Intensity increases add value", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        local h1 = s:addBuff("str", 5, 1, -1, "rune", Stats.StackMode.Intensity)
        local h2 = s:addBuff("str", 3, 1, -1, "rune", Stats.StackMode.Intensity)
        -- Should return the same handle
        expect_equal(h1, h2)
        -- Should still be one buff
        expect_equal(s:getBuffCount("str"), 1)
        -- Effective: 10 * 1 + 8 = 18
        expect_equal(s:get("str"), 18)
    end)

    -- @covers library.stats.newSheet
    -- @description Without stack_mode, duplicate buffs are always added (backward compat).
    it("nil stack_mode allows duplicates", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, -1, "aura")
        s:addBuff("str", 5, 1, -1, "aura")
        expect_equal(s:getBuffCount("str"), 2)
        expect_equal(s:get("str"), 20)
    end)

    -- @covers library.stats.newSheet
    -- @description Stack mode only matches same stat AND source; different sources always add.
    it("different sources bypass stack mode", function()
        local s = Stats.newSheet()
        s:define("str", 10)
        s:addBuff("str", 5, 1, -1, "aura_a", Stats.StackMode.None)
        s:addBuff("str", 5, 1, -1, "aura_b", Stats.StackMode.None)
        expect_equal(s:getBuffCount("str"), 2)
    end)
end)

--        Encumbrance update

-- @description Tests that the update tick auto-manages the 'encumbered' flag based on weight.
describe("Encumbrance update", function()
    -- @covers library.stats.newSheet
    -- @description update() sets the 'encumbered' flag when current weight exceeds capacity.
    it("sets encumbered flag when over limit", function()
        local s = Stats.newSheet()
        s:setEncumbrance(150, 100)
        s:update(0)
        expect_equal(s:hasFlag("encumbered"), true)
    end)

    -- @covers library.stats.newSheet
    -- @description update() clears the 'encumbered' flag when weight is within capacity.
    it("clears encumbered flag when under limit", function()
        local s = Stats.newSheet()
        s:setEncumbrance(150, 100)
        s:update(0)
        expect_equal(s:hasFlag("encumbered"), true)
        s:setEncumbrance(50, 100)
        s:update(0)
        expect_equal(s:hasFlag("encumbered"), false)
    end)

    -- @covers library.stats.newSheet
    -- @description No encumbrance set means no flag changes.
    it("no encumbrance means no flag", function()
        local s = Stats.newSheet()
        s:update(0)
        expect_equal(s:hasFlag("encumbered"), false)
    end)
end)

--        Input validation

-- @description Tests input validation at public function boundaries.
describe("Input validation", function()
    -- @covers library.stats.newSheet
    -- @description define() silently ignores non-string stat names.
    it("define ignores nil name", function()
        local s = Stats.newSheet()
        s:define(nil, 10)
        expect_equal(#s:getStatNames(), 0)
    end)

    -- @covers library.stats.newSheet
    -- @description addBuff returns nil for non-string stat names.
    it("addBuff returns nil for nil stat", function()
        local s = Stats.newSheet()
        local h = s:addBuff(nil, 5, 1, -1, "x")
        expect_equal(h, nil)
    end)

    -- @covers library.stats.newSheet
    -- @description addXP rejects negative amounts and returns 0 levels gained.
    it("addXP rejects negative amount", function()
        local s = Stats.newSheet()
        local gained = s:addXP(-100)
        expect_equal(gained, 0)
        expect_equal(s:getXP(), 0)
    end)

    -- @covers library.stats.newSheet
    -- @description addXP handles nil amount gracefully (treats as 0).
    it("addXP handles nil amount", function()
        local s = Stats.newSheet()
        local gained = s:addXP(nil)
        expect_equal(gained, 0)
        expect_equal(s:getXP(), 0)
    end)
end)

test_summary()
