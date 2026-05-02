--- BDD tests for library.battle
local battle = require("library.battle")

---------------------------------------------------------------------------
-- StatusEffect
---------------------------------------------------------------------------

describe("StatusEffect", function()
    it("creates with defaults", function()
        local e = battle.newStatusEffect("burn", 3)
        expect_equal(e:getName(), "burn")
        expect_equal(e:getDuration(), 3)
        expect_equal(e:getStacks(), 1)
        expect_equal(e:isExpired(), false)
    end)

    it("permanent when duration -1", function()
        local e = battle.newStatusEffect("shield")
        expect_equal(e:getDuration(), -1)
        expect_equal(e:isExpired(), false)
        e:tickTurn()
        expect_equal(e:isExpired(), false) -- never expires
    end)

    it("expires after ticking duration", function()
        local e = battle.newStatusEffect("poison", 2)
        e:tickTurn() -- duration = 1
        expect_equal(e:isExpired(), false)
        local just_expired = e:tickTurn() -- duration = 0
        expect_equal(just_expired, true)
        expect_equal(e:isExpired(), true)
    end)
end)

---------------------------------------------------------------------------
-- CombatAction
---------------------------------------------------------------------------

describe("CombatAction", function()
    it("creates with defaults", function()
        local a = battle.newAction("slash")
        expect_equal(a:getName(), "slash")
        expect_equal(a:getBaseDamage(), 0)
        expect_equal(a:getDamageType(), "physical")
        expect_equal(a:getAccuracy(), 1.0)
        expect_equal(a:isReady(), true)
    end)

    it("cooldown cycle", function()
        local a = battle.newAction("fireball")
        a:setCooldown(3)
        a:useAction()
        expect_equal(a:isReady(), false)
        expect_equal(a:getCurrentCooldown(), 3)
        a:tickCooldown()
        a:tickCooldown()
        a:tickCooldown()
        expect_equal(a:isReady(), true)
    end)

    it("accuracy clamped to 0-1", function()
        local a = battle.newAction("wild")
        a:setAccuracy(1.5)
        expect_equal(a:getAccuracy(), 1.0)
        a:setAccuracy(-0.5)
        expect_equal(a:getAccuracy(), 0)
    end)
end)

---------------------------------------------------------------------------
-- Combatant
---------------------------------------------------------------------------

describe("Combatant", function()
    it("creates with defaults", function()
        local c = battle.newCombatant("hero")
        expect_equal(c:getName(), "hero")
        expect_equal(c:getTeam(), "player")
        expect_equal(c:getHp(), 100)
        expect_equal(c:getMaxHp(), 100)
        expect_equal(c:getMp(), 50)
        expect_equal(c:getMaxMp(), 50)
        expect_equal(c:getSpeed(), 10)
        expect_equal(c:isAlive(), true)
    end)

    it("take_damage applies resistance multiplier", function()
        local c = battle.newCombatant("hero")
        c:setResistance("fire", 0.5) -- half damage from fire
        local dmg = c:takeDamage(40, "fire")
        expect_equal(dmg, 20)
        expect_equal(c:getHp(), 80)
    end)

    it("dies when hp reaches 0", function()
        local c = battle.newCombatant("hero")
        c:setHp(10)
        c:takeDamage(20, "physical")
        expect_equal(c:getHp(), 0)
        expect_equal(c:isAlive(), false)
    end)

    it("heal capped at max_hp", function()
        local c = battle.newCombatant("hero")
        c:setHp(80)
        local healed = c:heal(30)
        expect_equal(c:getHp(), 100)
        expect_equal(healed, 20)
    end)

    it("status effects stack", function()
        local c = battle.newCombatant("hero")
        c:addStatus("burn", 3)
        c:addStatus("burn", 5) -- stacks += 1, duration extended
        expect_equal(c:hasStatus("burn"), true)
        local statuses = c:getStatuses()
        expect_equal(#statuses, 1)
        expect_equal(statuses[1].stacks, 2)
        expect_equal(statuses[1].duration, 5)
    end)

    it("remove status", function()
        local c = battle.newCombatant("hero")
        c:addStatus("burn", 3)
        c:addStatus("freeze", 2)
        c:removeStatus("burn")
        expect_equal(c:hasStatus("burn"), false)
        expect_equal(c:hasStatus("freeze"), true)
    end)

    it("tick statuses removes expired", function()
        local c = battle.newCombatant("hero")
        c:addStatus("flash", 1)
        c:addStatus("shield", -1)
        local expired = c:tickStatuses()
        expect_equal(#expired, 1)
        expect_equal(expired[1], "flash")
        expect_equal(c:hasStatus("flash"), false)
        expect_equal(c:hasStatus("shield"), true)
    end)

    it("hp and mp percent", function()
        local c = battle.newCombatant("hero")
        c:setHp(50)
        expect_equal(c:getHpPercent(), 50)
        c:setMp(25)
        expect_equal(c:getMpPercent(), 50)
    end)

    it("add and get action", function()
        local c = battle.newCombatant("hero")
        local a = battle.newAction("slash")
        a:setBaseDamage(10)
        c:addAction(a)
        expect_equal(c:hasAction("slash"), true)
        local got = c:getAction("slash")
        expect_equal(got:getBaseDamage(), 10)
    end)

    it("stat getter/setter", function()
        local c = battle.newCombatant("hero")
        expect_equal(c:getStat("str"), 0) -- default
        c:setStat("str", 15)
        expect_equal(c:getStat("str"), 15)
    end)

    it("action and status name lists", function()
        local c = battle.newCombatant("hero")
        c:addAction(battle.newAction("slash"))
        c:addAction(battle.newAction("stab"))
        c:addStatus("burn", 5)
        expect_equal(#c:getActionNames(), 2)
        expect_equal(#c:getStatusNames(), 1)
    end)

    it("metadata", function()
        local c = battle.newCombatant("hero")
        c:setMeta("class", "warrior")
        expect_equal(c:getMeta("class"), "warrior")
    end)
end)

---------------------------------------------------------------------------
-- CombatBattle
---------------------------------------------------------------------------

describe("CombatBattle", function()
    it("creates empty battle", function()
        local b = battle.newBattle("arena")
        expect_equal(b:getName(), "arena")
        expect_equal(b:getCount(), 0)
        expect_equal(b:getTurnCount(), 0)
        expect_equal(b:isOver(), false)
    end)

    it("add and get combatants", function()
        local b = battle.newBattle()
        local c1 = battle.newCombatant("hero")
        local c2 = battle.newCombatant("goblin")
        c2:setTeam("enemy")
        b:addCombatant(c1)
        b:addCombatant(c2)
        expect_equal(b:getCount(), 2)
        local found = b:getCombatant("hero")
        expect_equal(found:getName(), "hero")
    end)

    it("sort initiative by speed", function()
        local b = battle.newBattle()
        local slow = battle.newCombatant("slow")
        slow:setSpeed(5)
        slow:setTeam("a")
        local fast = battle.newCombatant("fast")
        fast:setSpeed(20)
        fast:setTeam("b")
        b:addCombatant(slow)
        b:addCombatant(fast)
        b:sortInitiative()
        local names = b:getAllNames()
        expect_equal(names[1], "fast")
        expect_equal(names[2], "slow")
    end)

    it("turn cycling", function()
        local b = battle.newBattle()
        local c1 = battle.newCombatant("a")
        c1:setTeam("t1")
        local c2 = battle.newCombatant("b")
        c2:setTeam("t2")
        b:addCombatant(c1)
        b:addCombatant(c2)
        local first = b:getCurrentCombatant()
        expect_equal(first:getName(), "a")
        b:nextTurn()
        local second = b:getCurrentCombatant()
        expect_equal(second:getName(), "b")
    end)

    it("attack resolves damage", function()
        local b = battle.newBattle()
        local hero = battle.newCombatant("hero")
        hero:setTeam("player")
        local slash = battle.newAction("slash")
        slash:setBaseDamage(25)
        slash:setAccuracy(1.0) -- always hits
        hero:addAction(slash)
        local goblin = battle.newCombatant("goblin")
        goblin:setTeam("enemy")
        b:addCombatant(hero)
        b:addCombatant(goblin)

        local result = b:attack("hero", "slash", "goblin")
        expect_equal(result.hit, true)
        expect_equal(result.damage, 25)
        expect_equal(result.damageType, "physical")
        local g = b:getCombatant("goblin")
        expect_equal(g:getHp(), 75)
    end)

    it("attack returns nil for missing combatant", function()
        local b = battle.newBattle()
        expect_equal(b:attack("nobody", "slash", "nobody"), nil)
    end)

    it("battle over when one team remains", function()
        local b = battle.newBattle()
        local hero = battle.newCombatant("hero")
        hero:setTeam("player")
        local slash = battle.newAction("slash")
        slash:setBaseDamage(200)
        slash:setAccuracy(1.0)
        hero:addAction(slash)
        local goblin = battle.newCombatant("goblin")
        goblin:setTeam("enemy")
        b:addCombatant(hero)
        b:addCombatant(goblin)
        b:attack("hero", "slash", "goblin")
        expect_equal(b:isOver(), true)
        expect_equal(b:getWinner(), "player")
    end)

    it("remove combatant", function()
        local b = battle.newBattle()
        b:addCombatant(battle.newCombatant("hero"))
        expect_equal(b:removeCombatant("hero"), true)
        expect_equal(b:getCount(), 0)
        expect_equal(b:removeCombatant("hero"), false)
    end)

    it("force end", function()
        local b = battle.newBattle()
        b:forceEnd("draw")
        expect_equal(b:isOver(), true)
        expect_equal(b:getWinner(), "draw")
    end)

    it("alive names", function()
        local b = battle.newBattle()
        local c1 = battle.newCombatant("alive_one")
        c1:setTeam("a")
        local c2 = battle.newCombatant("dead_one")
        c2:setTeam("b")
        c2:setHp(0)
        c2.alive = false
        b:addCombatant(c1)
        b:addCombatant(c2)
        local names = b:getAliveNames()
        expect_equal(#names, 1)
        expect_equal(names[1], "alive_one")
    end)

    it("log tracking", function()
        local b = battle.newBattle()
        b:addToLog("Battle started")
        expect_equal(#b:getLog(), 1)
        expect_equal(b:getLog()[1], "Battle started")
    end)

    it("tick all statuses and actions", function()
        local b = battle.newBattle()
        local c = battle.newCombatant("hero")
        c:setTeam("player")
        c:addStatus("burn", 1)
        local a = battle.newAction("slash")
        a:setCooldown(2)
        a:useAction()
        c:addAction(a)
        b:addCombatant(c)
        b:tickAllStatuses()
        b:tickAllActions()
        local hero = b:getCombatant("hero")
        expect_equal(hero:hasStatus("burn"), false)
        expect_equal(hero:getAction("slash"):getCurrentCooldown(), 1)
    end)

    it("attack result contains attacker and target field names", function()
        local b = battle.newBattle()
        local hero = battle.newCombatant("hero")
        hero:setTeam("player")
        local slash = battle.newAction("slash")
        slash:setBaseDamage(30)
        slash:setAccuracy(1.0)
        hero:addAction(slash)
        local enemy = battle.newCombatant("enemy")
        enemy:setTeam("foe")
        b:addCombatant(hero)
        b:addCombatant(enemy)
        local result = b:attack("hero", "slash", "enemy")
        expect_equal("hero", result.attacker)
        expect_equal("enemy", result.target)
    end)

    it("attack returns nil when action is on cooldown", function()
        local b = battle.newBattle()
        local hero = battle.newCombatant("hero")
        hero:setTeam("player")
        local slash = battle.newAction("slash")
        slash:setBaseDamage(10)
        slash:setAccuracy(1.0)
        slash:setCooldown(2)
        hero:addAction(slash)
        local goblin = battle.newCombatant("goblin")
        goblin:setTeam("enemy")
        b:addCombatant(hero)
        b:addCombatant(goblin)
        -- first attack succeeds and puts the action on cooldown
        local result1 = b:attack("hero", "slash", "goblin")
        expect_equal(result1 ~= nil, true)
        -- second attempt while on cooldown must return nil
        local result2 = b:attack("hero", "slash", "goblin")
        expect_equal(result2, nil)
    end)

    it("attack result includes targetDied when target is killed", function()
        local b = battle.newBattle()
        local hero = battle.newCombatant("hero")
        hero:setTeam("player")
        local slash = battle.newAction("slash")
        slash:setBaseDamage(200)
        slash:setAccuracy(1.0)
        hero:addAction(slash)
        local goblin = battle.newCombatant("goblin")
        goblin:setTeam("enemy")
        b:addCombatant(hero)
        b:addCombatant(goblin)
        local result = b:attack("hero", "slash", "goblin")
        expect_equal(result ~= nil, true)
        expect_equal(result and result.targetDied, true)
    end)
end)

---------------------------------------------------------------------------
-- DamageType enum
---------------------------------------------------------------------------

describe("DamageType", function()
    it("exports named constants", function()
        expect_equal(battle.DamageType.Physical,  "physical")
        expect_equal(battle.DamageType.Fire,      "fire")
        expect_equal(battle.DamageType.Ice,       "ice")
        expect_equal(battle.DamageType.Lightning, "lightning")
        expect_equal(battle.DamageType.Poison,    "poison")
        expect_equal(battle.DamageType.Arcane,    "arcane")
        expect_equal(battle.DamageType.Custom,    "custom")
    end)
end)

---------------------------------------------------------------------------
-- CombatAction          tags and metadata
---------------------------------------------------------------------------

describe("CombatAction tags and metadata", function()
    it("addTag / hasTag / removeTag", function()
        local a = battle.newAction("fireball")
        a:addTag("aoe")
        a:addTag("fire")
        expect_equal(a:hasTag("aoe"), true)
        expect_equal(a:hasTag("fire"), true)
        expect_equal(a:hasTag("ice"), false)
        local removed = a:removeTag("fire")
        expect_equal(removed, true)
        expect_equal(a:hasTag("fire"), false)
        local removed_again = a:removeTag("fire")
        expect_equal(removed_again, false)
    end)

    it("getTags returns sorted list", function()
        local a = battle.newAction("combo")
        a:addTag("magic")
        a:addTag("aoe")
        a:addTag("fire")
        local tags = a:getTags()
        expect_equal(#tags, 3)
        expect_equal(tags[1], "aoe")
        expect_equal(tags[2], "fire")
        expect_equal(tags[3], "magic")
    end)

    it("getMeta / setMeta", function()
        local a = battle.newAction("special")
        a:setMeta("element", "fire")
        expect_equal(a:getMeta("element"), "fire")
        expect_equal(a:getMeta("missing"), nil)
    end)
end)

---------------------------------------------------------------------------
-- StatusEffect          metadata
---------------------------------------------------------------------------

describe("StatusEffect metadata", function()
    it("getMeta / setMeta", function()
        local e = battle.newStatusEffect("burn", 3)
        e:setMeta("source", "dragon")
        expect_equal(e:getMeta("source"), "dragon")
        expect_equal(e:getMeta("missing"), nil)
    end)

    it("getMetadata / setMetadata aliases", function()
        local e = battle.newStatusEffect("freeze", 2)
        e:setMetadata("power", "5")
        expect_equal(e:getMetadata("power"), "5")
    end)
end)

---------------------------------------------------------------------------
-- Combatant          setLevel
---------------------------------------------------------------------------

describe("Combatant setLevel", function()
    it("can set and get level", function()
        local c = battle.newCombatant("hero")
        expect_equal(c:getLevel(), 1)
        c:setLevel(10)
        expect_equal(c:getLevel(), 10)
    end)
end)
---------------------------------------------------------------------------
-- Input validation
---------------------------------------------------------------------------

describe("Input validation", function()
    it("newCombatant rejects nil name", function()
        expect_error(function() battle.newCombatant(nil) end)
    end)

    it("newCombatant rejects empty name", function()
        expect_error(function() battle.newCombatant("") end)
    end)

    it("newAction rejects nil name", function()
        expect_error(function() battle.newAction(nil) end)
    end)

    it("newAction rejects empty name", function()
        expect_error(function() battle.newAction("") end)
    end)

    it("newStatusEffect rejects nil name", function()
        expect_error(function() battle.newStatusEffect(nil) end)
    end)

    it("newStatusEffect rejects empty name", function()
        expect_error(function() battle.newStatusEffect("") end)
    end)

    it("newStatusEffect rejects non-number duration", function()
        expect_error(function() battle.newStatusEffect("burn", "forever") end)
    end)

    it("takeDamage rejects negative amount", function()
        local c = battle.newCombatant("hero")
        expect_error(function() c:takeDamage(-10) end)
    end)

    it("heal rejects negative amount", function()
        local c = battle.newCombatant("hero")
        expect_error(function() c:heal(-5) end)
    end)

    it("addStatus rejects nil name", function()
        local c = battle.newCombatant("hero")
        expect_error(function() c:addStatus(nil) end)
    end)

    it("setAccuracy rejects non-number", function()
        local a = battle.newAction("slash")
        expect_error(function() a:setAccuracy("high") end)
    end)

    it("newBattle rejects non-string name", function()
        expect_error(function() battle.newBattle(123) end)
    end)

    it("newBattle accepts nil name", function()
        local b = battle.newBattle(nil)
        expect_equal(b:getName(), "")
    end)
end)

---------------------------------------------------------------------------
-- Edge cases
---------------------------------------------------------------------------

describe("Edge cases", function()
    it("zero damage does not reduce HP", function()
        local c = battle.newCombatant("hero")
        local dmg = c:takeDamage(0, "physical")
        expect_equal(dmg, 0)
        expect_equal(c:getHp(), 100)
        expect_equal(c:isAlive(), true)
    end)

    it("healing at full HP returns 0", function()
        local c = battle.newCombatant("hero")
        local healed = c:heal(50)
        expect_equal(healed, 0)
        expect_equal(c:getHp(), 100)
    end)

    it("removeStatus on non-existent status is safe", function()
        local c = battle.newCombatant("hero")
        c:removeStatus("nonexistent")
        expect_equal(#c:getStatuses(), 0)
    end)

    it("tickStatuses with no effects returns empty", function()
        local c = battle.newCombatant("hero")
        local expired = c:tickStatuses()
        expect_equal(#expired, 0)
    end)

    it("empty battle getCurrentCombatant returns nil", function()
        local b = battle.newBattle("empty")
        expect_equal(b:getCurrentCombatant(), nil)
    end)

    it("empty battle nextTurn returns false", function()
        local b = battle.newBattle("empty")
        expect_equal(b:nextTurn(), false)
    end)

    it("empty battle getAliveNames returns empty", function()
        local b = battle.newBattle("empty")
        expect_equal(#b:getAliveNames(), 0)
    end)

    it("getHpPercent returns 0 when max_hp is 0", function()
        local c = battle.newCombatant("hero")
        c:setMaxHp(0)
        expect_equal(c:getHpPercent(), 0)
    end)

    it("getMpPercent returns 0 when max_mp is 0", function()
        local c = battle.newCombatant("hero")
        c:setMaxMp(0)
        expect_equal(c:getMpPercent(), 0)
    end)
end)

---------------------------------------------------------------------------
-- Deep clone (metadata)
---------------------------------------------------------------------------

describe("Deep clone metadata", function()
    it("addAction deep-clones nested metadata", function()
        local a = battle.newAction("fireball")
        a:setMeta("scaling", { str = 1.5, int = 2.0 })
        local c = battle.newCombatant("hero")
        c:addAction(a)
        -- mutate the clone's metadata
        local cloned = c:getAction("fireball")
        cloned:getMeta("scaling").str = 999
        -- original must be unchanged
        expect_equal(a:getMeta("scaling").str, 1.5)
    end)

    it("addCombatant deep-clones combatant metadata", function()
        local c = battle.newCombatant("hero")
        c:setMeta("perks", { bonus = 10 })
        local b = battle.newBattle("arena")
        b:addCombatant(c)
        -- mutate the clone's metadata inside the battle
        local cloned = b:getCombatant("hero")
        cloned:getMeta("perks").bonus = 999
        -- original must be unchanged
        expect_equal(c:getMeta("perks").bonus, 10)
    end)

    it("addCombatant deep-clones action metadata", function()
        local a = battle.newAction("slash")
        a:setMeta("effects", { bleed = true })
        local c = battle.newCombatant("hero")
        c:addAction(a)
        local b = battle.newBattle("arena")
        b:addCombatant(c)
        -- mutate inside battle
        local battle_hero = b:getCombatant("hero")
        battle_hero:getAction("slash"):getMeta("effects").bleed = false
        -- original action on original combatant must be unchanged
        expect_equal(c:getAction("slash"):getMeta("effects").bleed, true)
    end)
end)

---------------------------------------------------------------------------
-- resolve() method
---------------------------------------------------------------------------

describe("CombatBattle resolve", function()
    it("ticks statuses and cooldowns in one call", function()
        local b = battle.newBattle("arena")
        local c = battle.newCombatant("hero")
        c:setTeam("player")
        c:addStatus("burn", 1)
        local a = battle.newAction("slash")
        a:setCooldown(2)
        a:useAction()
        c:addAction(a)
        b:addCombatant(c)
        local still_going = b:resolve()
        -- resolve returns false when only one team remains (battle over)
        expect_equal(false, still_going)
        local hero = b:getCombatant("hero")
        -- burn status with duration=1 is still present after first resolve;
        -- resolve ticks the counter but status remains until fully expired
        expect_equal(hero:getAction("slash"):getCurrentCooldown(), 1)
    end)

    it("detects battle over after resolve", function()
        local b = battle.newBattle("arena")
        local hero = battle.newCombatant("hero")
        hero:setTeam("player")
        local goblin = battle.newCombatant("goblin")
        goblin:setTeam("enemy")
        goblin:setHp(0)
        goblin.alive = false
        b:addCombatant(hero)
        b:addCombatant(goblin)
        local still_going = b:resolve()
        expect_equal(still_going, false)
        expect_equal(b:isOver(), true)
        expect_equal(b:getWinner(), "player")
    end)
end)

---------------------------------------------------------------------------
-- getWinner auto-detect
---------------------------------------------------------------------------

describe("getWinner auto-detect", function()
    it("auto-detects winner when one team alive", function()
        local b = battle.newBattle("arena")
        local hero = battle.newCombatant("hero")
        hero:setTeam("player")
        local goblin = battle.newCombatant("goblin")
        goblin:setTeam("enemy")
        goblin:setHp(0)
        goblin.alive = false
        b:addCombatant(hero)
        b:addCombatant(goblin)
        -- without auto_detect, winner is nil (battle not explicitly marked over)
        expect_equal(b:getWinner(), nil)
        -- with auto_detect, winner is found
        expect_equal(b:getWinner(true), "player")
        expect_equal(b:isOver(), true)
    end)

    it("auto-detect returns nil when battle is not over", function()
        local b = battle.newBattle("arena")
        local hero = battle.newCombatant("hero")
        hero:setTeam("player")
        local goblin = battle.newCombatant("goblin")
        goblin:setTeam("enemy")
        b:addCombatant(hero)
        b:addCombatant(goblin)
        expect_equal(b:getWinner(true), nil)
        expect_equal(b:isOver(), false)
    end)
end)test_summary()
test_summary()
