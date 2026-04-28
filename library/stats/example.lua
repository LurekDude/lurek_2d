--- Example usage for library.stats.
-- Run with: lua content/library/stats/example.lua
-- Demonstrates stat sheets: defining attributes, applying buffs,
-- ticking durations, snapshot/restore, and optional JSON round-trip
-- via lurek.serial.
-- @module example.stats

local M = require("library.stats")

-- ── 1. Build a fresh stat sheet for an RPG hero ───────────────────────────────
local hero = M.newSheet()
hero:define("hp",       50, { min = 0, max = 50, regen = 1 })
hero:define("attack",   10)
hero:define("defense",   5, { min = 0, max = 100 })
hero:setActionPoints(6)
hero:setMorale(100)

local ap_current, ap_max = hero:getActionPoints()

print(string.format("[example.stats] hero hp=%d attack=%d defense=%d AP=%d/%d",
    hero:get("hp"), hero:get("attack"), hero:get("defense"),
    ap_current, ap_max))

-- ── 2. Apply buffs — flat add and multiplicative — observe effective stat ─────
local strength_buff = hero:addBuff("attack",  5,  1.0, 10, "potion")     -- +5 for 10s
local rage_buff     = hero:addBuff("attack",  0,  1.5,  3, "rage_skill") -- x1.5 for 3s
print(string.format("[example.stats] under buffs: attack=%d (base=%d, buff_count=%d)",
    hero:get("attack"), hero:getBase("attack"), hero:getBuffCount("attack")))

-- ── 3. Damage and resistances ─────────────────────────────────────────────────
hero:setResistance("fire", 0.5)  -- 50% fire resist
hero:applyDamage("hp", 20, "fire")
print(string.format("[example.stats] after 20 fire damage: hp=%d (50%% resist)", hero:get("hp")))

-- ── 4. Tick durations forward — short buff (rage) expires first ───────────────
hero:update(4)  -- 4 seconds elapse
print(string.format("[example.stats] +4s: attack=%d buff_count=%d (rage expired)",
    hero:get("attack"), hero:getBuffCount("attack")))

-- Use the handles to silence "unused" warnings and demonstrate manual removal:
hero:removeBuff(rage_buff)
local _ = strength_buff

-- ── 5. Action points and turn cycle ───────────────────────────────────────────
hero:spendActionPoints(4)
local ap_after_spend = select(1, hero:getActionPoints())
print(string.format("[example.stats] spent 4 AP -> %d remaining",
    ap_after_spend))
hero:beginTurn()
local ap_after_begin_turn = select(1, hero:getActionPoints())
print(string.format("[example.stats] after beginTurn: AP=%d (refilled)",
    ap_after_begin_turn))

-- ── 6. XP, levelling, flags ───────────────────────────────────────────────────
hero:setLevelThresholds(M.newLinearThresholds(100, 50))  -- L2=100, L3=150, L4=200...
hero:addXP(120)
hero:setFlag("met_king")
print(string.format("[example.stats] xp=%d level=%d met_king=%s",
    hero:getXP(), hero:getLevel(), tostring(hero:hasFlag("met_king"))))

-- ── 7. Snapshot / restore ─────────────────────────────────────────────────────
local snap = hero:snapshot()
hero:applyDamage("hp", 25, "physical")    -- mutate
print(string.format("[example.stats] post-mutate hp=%d", hero:get("hp")))
hero:restore(snap)
print(string.format("[example.stats] post-restore hp=%d (snapshot reverted)", hero:get("hp")))

-- ── 8. Optional JSON snapshot via lurek.serial (guarded) ───────────────────────
local lurek_ok = pcall(function() return lurek and lurek.serial end)
if lurek_ok and lurek and lurek.serial and lurek.serial.toJson then
    local s    = M.snapshotToJson(snap)
    local back = M.snapshotFromJson(s)
    print(string.format("[example.stats] JSON snapshot len=%d xp_back=%s",
        #s, tostring(back and back.xp)))
else
    print("[example.stats] lurek.serial unavailable; in-memory snapshot only")
end

print("[example.stats] done.")
