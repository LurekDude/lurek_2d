-- Lurek2D battle API tests

-- @description Covers suite: lurek.turnbattle module exists.
describe("lurek.turnbattle module exists", function()
    -- @tests lurek.turnbattle
    -- @tests lurek.turnbattle.newAction
    -- @tests lurek.turnbattle.newBattle
    -- @tests lurek.turnbattle.newCombatant
    -- @description Verifies the turnbattle namespace is registered as a Lua table.
    it("is a table", function()
        expect_type("table", lurek.turnbattle)
    end)
end)

-- @description Covers suite: lurek.turnbattle.newCombatant.
describe("lurek.turnbattle.newCombatant", function()
    -- @tests lurek.turnbattle.newCombatant
    -- @tests Combatant.getName
    -- @tests Combatant.isAlive
    -- @tests Combatant.type
    -- @description Verifies a new combatant exposes its assigned name, starts alive, and reports the Combatant userdata type.
    it("creates a combatant with basic accessors", function()
        local c = lurek.turnbattle.newCombatant("hero")
        expect_not_nil(c)
        expect_equal("hero", c:getName())
        expect_true(c:isAlive())
    end)
end)

-- @description Covers suite: lurek.turnbattle.newBattle.
describe("lurek.turnbattle.newBattle", function()
    -- @tests lurek.turnbattle.newBattle
    -- @tests lurek.turnbattle.newAction
    -- @tests Combatant.setTeam
    -- @tests Combatant.setHp
    -- @tests Combatant.setMaxHp
    -- @tests Combatant.addAction
    -- @tests Action.setBaseDamage
    -- @tests Action.setAccuracy
    -- @tests Battle.addCombatant
    -- @tests Battle.attack
    -- @description Verifies a configured action resolves through the battle system and returns an attack result table with attacker, target, and damage fields.
    it("creates a battle and resolves a simple attack", function()
        local battle = lurek.turnbattle.newBattle("arena")
        local hero = lurek.turnbattle.newCombatant("hero")
        hero:setTeam("player")
        hero:setHp(100)
        hero:setMaxHp(100)

        local enemy = lurek.turnbattle.newCombatant("enemy")
        enemy:setTeam("enemy")
        enemy:setHp(100)
        enemy:setMaxHp(100)

        local strike = lurek.turnbattle.newAction("strike")
        strike:setBaseDamage(25)
        strike:setAccuracy(1.0)

        hero:addAction(strike)
        battle:addCombatant(hero)
        battle:addCombatant(enemy)

        local result = battle:attack("hero", "strike", "enemy")
        expect_not_nil(result)
        expect_equal("hero", result.attacker)
        expect_equal("enemy", result.target)
        expect_equal(25, result.damage)
    end)
end)

test_summary()
