
-- Lurek2D battle API tests.
-- Verifies the current turnbattle contract for builds where the module may be absent.

if not lurek.turnbattle then
    -- @describe fallback when turnbattle is unavailable
    describe("lurek.turnbattle", function()
        -- @covers lurek.turnbattle
        it("module is unavailable in this runtime build", function()
            expect_type("table", lurek)
            expect_nil(lurek.turnbattle)
        end)
    end)
else
    -- @describe turnbattle module table checks
    describe("lurek.turnbattle module exists", function()
        -- @covers lurek.turnbattle
        it("is a table", function()
            expect_type("table", lurek.turnbattle)
        end)
    end)

    -- @describe newCombatant factory behavior
    describe("lurek.turnbattle.newCombatant", function()
        -- @covers LCombatant:getName
        -- @covers LCombatant:isAlive
        -- @covers lurek.turnbattle.newCombatant
        it("creates a combatant with basic accessors", function()
            local c = lurek.turnbattle.newCombatant("hero")
            expect_not_nil(c)
            expect_equal("hero", c:getName())
            expect_true(c:isAlive())
        end)
    end)

    -- @describe battle creation and attack flow
    describe("lurek.turnbattle.newBattle", function()
        -- @covers LBattle:addCombatant
        -- @covers LBattle:attack
        -- @covers LCombatant:addAction
        -- @covers LCombatant:setHp
        -- @covers LCombatant:setMaxHp
        -- @covers LCombatant:setTeam
        -- @covers LTurnAction:setAccuracy
        -- @covers LTurnAction:setBaseDamage
        -- @covers lurek.turnbattle.newAction
        -- @covers lurek.turnbattle.newBattle
        -- @covers lurek.turnbattle.newCombatant
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
end
test_summary()
