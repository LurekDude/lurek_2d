--- Example usage for library.combat.
-- Run from project root with: lua content/library/combat/example.lua
-- This example is engine-free: it does NOT call lurek.physics. It exercises
-- the pure-Lua data layer (chassis, mounts, turrets, weapons, projectile pool,
-- collision groups) which a real game would later wire to physics body IDs.
-- @module example.combat

package.path = "content/?.lua;content/?/init.lua;" .. package.path
local combat = require("library.combat")

print("[example.combat] === Scenario 1: collision groups & masks ===")

local groups = combat.newCollisionGroupSet()
local g_player  = groups:defineGroup("player")
local g_enemy   = groups:defineGroup("enemy")
local g_terrain = groups:defineGroup("terrain")
groups:setCollides("player", "enemy", true)
groups:setCollides("player", "terrain", true)
groups:setCollides("enemy", "terrain", true)
print(string.format("  groups=%d, player<->enemy=%s, mask(player)=0x%X",
    groups:groupCount(),
    tostring(groups:getCollides("player", "enemy")),
    groups:computeMask("player")))

print("[example.combat] === Scenario 2: chassis with armor zones ===")

local tank = combat.newChassis(101 --[[fake body_id]], 250)
tank.team = "player"
tank:setArmor("front", 30)
tank:setArmor("rear",   8)
tank:addSlot(combat.newMountSlot("turret_top",  0,   0, "large"))
tank:addSlot(combat.newMountSlot("mg_left",   -10,  4, "small"))
tank:addSlot(combat.newMountSlot("mg_right",   10,  4, "small"))
print(string.format("  tank hp=%.0f/%0.f, slots=%d, front armor=%d",
    tank.hp, tank.max_hp, #tank:getSlots(), tank:getArmor("front")))

print("[example.combat] === Scenario 3: take damage and check destroyed ===")

local dealt = tank:takeDamage(80)
print(string.format("  applied 80, actual=%.0f, hp=%.0f, dead=%s",
    dealt, tank.hp, tostring(tank:isDead())))
tank:heal(20)
print(string.format("  healed 20 -> hp=%.0f", tank.hp))

print("[example.combat] === Scenario 4: weapon firing + cooldown ===")

local cannon = combat.newWeapon("105mm")
cannon.fire_rate     = 0.5  -- one shot per 2s
cannon.damage_amount = 60
cannon.max_ammo      = 8
cannon.ammo          = 8

cannon:startFiring()
local shots = 0
for tick = 1, 6 do
    cannon:updateCooldown(1.0)
    if cannon:fire(1.0) then shots = shots + 1 end
end
print(string.format("  shots fired in 6 ticks: %d, ammo left=%d, cooldown=%.2fs",
    shots, cannon.ammo, cannon.cooldown_remaining))

print("[example.combat] === Scenario 5: turret aim & arc clamp ===")

local turret = combat.newTurret(102 --[[body_id]], 555 --[[joint_id]])
turret.turn_speed = math.pi  -- pi rad/sec
turret.arc_min = -math.pi / 2
turret.arc_max =  math.pi / 2
turret:aimAtAngle(math.pi)   -- target outside arc, will clamp
local angular_v = turret:update(0.1, 0.0)
print(string.format("  turret aiming pi rad, arc [-pi/2, pi/2], angular_v=%.3f rad/s",
    angular_v or 0))

print("[example.combat] === Scenario 6: projectile pool reuse ===")

local pool = combat.newProjectilePool(8, combat.ProjectileType.Ballistic)
local first
for i = 1, 5 do
    local idx = pool:spawn(0, 0, 0, 300, 25, "kinetic", 500)
    first = first or idx
end
print(string.format("  pool size=%d, active=%d, free=%d (first idx=%s)",
    pool.pool_size, pool:activeCount(), pool:freeCount(), tostring(first)))
pool:release(first)
print(string.format("  after release: active=%d, free=%d",
    pool:activeCount(), pool:freeCount()))

print("[example.combat] done.")
