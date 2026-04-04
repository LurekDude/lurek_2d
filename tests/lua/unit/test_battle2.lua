-- Luna2D battle API tests

describe("luna.turnbattle module exists", function()
    it("is a table", function()
        expect_type("table", luna.turnbattle)
    end)
end)

describe("luna.turnbattle.newCombatant", function()
    it("creates a combatant with basic accessors", function()
        local c = luna.turnbattle.newCombatant("hero")
        expect_not_nil(c)
        expect_equal("hero", c:getName())
        expect_true(c:isAlive())
    end)
end)

describe("luna.turnbattle.newBattle", function()
    it("creates a battle and resolves a simple attack", function()
        local battle = luna.turnbattle.newBattle("arena")
        local hero = luna.turnbattle.newCombatant("hero")
        hero:setTeam("player")
        hero:setHp(100)
        hero:setMaxHp(100)

        local enemy = luna.turnbattle.newCombatant("enemy")
        enemy:setTeam("enemy")
        enemy:setHp(100)
        enemy:setMaxHp(100)

        local strike = luna.turnbattle.newAction("strike")
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
