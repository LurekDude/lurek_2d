--- Example usage for library.battle.
-- Run from project root with: lua content/library/battle/example.lua
-- @module example.battle

-- Bootstrap: locate library.* when launched directly via stand-alone Lua.
package.path = "content/?.lua;content/?/init.lua;" .. package.path

local battle = require("library.battle")

-- Deterministic output for reproducible runs.
math.randomseed(42)

print("[example.battle] === Scenario 1: build combatants and a battle ===")

local hero = battle.newCombatant("Hero")
hero:setTeam("player")
hero:setMaxHp(120); hero:setHp(120)
hero:setSpeed(15)
hero:setResistance(battle.DamageType.Fire, 0.5)  -- 50% fire resistance

local goblin = battle.newCombatant("Goblin")
goblin:setTeam("enemy")
goblin:setMaxHp(40); goblin:setHp(40)
goblin:setSpeed(8)

local slash = battle.newAction("slash")
slash:setBaseDamage(18)
slash:setDamageType(battle.DamageType.Physical)
slash:setAccuracy(1.0)  -- always hit, for deterministic demo
slash:addTag("melee")

local fireball = battle.newAction("fireball")
fireball:setBaseDamage(25)
fireball:setDamageType(battle.DamageType.Fire)
fireball:setAccuracy(1.0)
fireball:setCooldown(2)

hero:addAction(slash)
hero:addAction(fireball)
goblin:addAction(slash)

local arena = battle.newBattle("demo-arena")
arena:addCombatant(hero)
arena:addCombatant(goblin)
arena:sortInitiative()

print(string.format("  combatants in arena: %d  first up: %s",
    arena:getCount(), arena:getCurrentCombatant():getName()))

print("[example.battle] === Scenario 2: trade attacks until someone falls ===")

local turn = 0
while not arena:isOver() and turn < 10 do
    turn = turn + 1
    local actor = arena:getCurrentCombatant()
    local target_name = (actor:getTeam() == "player") and "Goblin" or "Hero"
    local action_name = (actor:getName() == "Hero" and turn == 1) and "fireball" or "slash"
    local r = arena:attack(actor:getName(), action_name, target_name)
    if r then
        print(string.format("  turn %d: %s", turn, r.message))
    end
    arena:resolve()        -- tick statuses + cooldowns
    arena:nextTurn()
end
print(string.format("  battle over=%s winner=%s",
    tostring(arena:isOver()), tostring(arena:getWinner())))

print("[example.battle] === Scenario 3: status effects with stacking ===")

local mage = battle.newCombatant("Mage")
mage:setMaxHp(60); mage:setHp(60)
mage:addStatus("burning", 3)   -- 3 turns
mage:addStatus("burning", 2)   -- stacks: stacks=2, duration extended
mage:addStatus("shielded", -1) -- permanent
print(string.format("  statuses: %d, hasBurning=%s",
    #mage:getStatuses(), tostring(mage:hasStatus("burning"))))

local expired = mage:tickStatuses()
print(string.format("  after one tick: expired=%d remaining=%d",
    #expired, #mage:getStatuses()))

print("[example.battle] === Scenario 4: damage + resistance ===")

local dummy = battle.newCombatant("Dummy")
dummy:setMaxHp(100); dummy:setHp(100)
dummy:setResistance(battle.DamageType.Fire, 0.25)   -- only 25% fire damage
dummy:setResistance(battle.DamageType.Ice,  2.0)    -- weak to ice (2x)

local fire_dealt = dummy:takeDamage(40, battle.DamageType.Fire)
local ice_dealt  = dummy:takeDamage(20, battle.DamageType.Ice)
print(string.format("  fire 40 -> %.1f dealt, ice 20 -> %.1f dealt, hp=%.0f",
    fire_dealt, ice_dealt, dummy:getHp()))

print("[example.battle] === Scenario 5: action tags & metadata ===")

slash:setMeta("animation", "swing_horizontal")
slash:setMeta("sfx", "blade_hit")
slash:addTag("starter")
print(string.format("  slash tags: %s, anim=%s",
    table.concat(slash:getTags(), ","), slash:getMeta("animation")))

print("[example.battle] === Scenario 6: battle log ===")

print(string.format("  log entries: %d", #arena:getLog()))
for i, line in ipairs(arena:getLog()) do
    print(string.format("    %02d  %s", i, line))
    if i >= 4 then print("    ..."); break end
end

print("[example.battle] done.")
