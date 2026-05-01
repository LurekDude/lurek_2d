-- Lurek2D battle API tests

if not lurek.turnbattle then
    describe("lurek.turnbattle", function()
        pending("lurek.turnbattle namespace not yet registered")
    end)
    test_summary()
    return
end

describe("lurek.turnbattle module exists", function()
    -- @tests lurek.turnbattle
    -- @covers lurek.turnbattle.newAction
    -- @covers lurek.turnbattle.newBattle
    -- @covers lurek.turnbattle.newCombatant
    it("is a table", function()
        expect_type("table", lurek.turnbattle)
    end)
end)

describe("lurek.turnbattle.newCombatant", function()
    -- @covers lurek.turnbattle.newCombatant
    -- @tests Combatant.getName
    -- @tests Combatant.isAlive
    -- @tests Combatant.type
    it("creates a combatant with basic accessors", function()
        local c = lurek.turnbattle.newCombatant("hero")
        expect_not_nil(c)
        expect_equal("hero", c:getName())
        expect_true(c:isAlive())
    end)
end)

describe("lurek.turnbattle.newBattle", function()
    -- @covers lurek.turnbattle.newBattle
    -- @covers lurek.turnbattle.newAction
    -- @tests Combatant.setTeam
    -- @tests Combatant.setHp
    -- @tests Combatant.setMaxHp
    -- @tests Combatant.addAction
    -- @tests Action.setBaseDamage
    -- @tests Action.setAccuracy
    -- @tests Battle.addCombatant
    -- @tests Battle.attack
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
