//! Integration tests for `luna.turnbattle.*`.

use luna2d::lua_api::{create_lua_vm, SharedState};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    create_lua_vm(state).unwrap()
}

// ─────────────────────────────────────────────────────────────────────────────
// Combatant
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn combatant_type_method() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("hero")
        assert(c:type() == "Combatant", "type()")
        assert(c:typeOf("Combatant"), "typeOf")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_name_and_team() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("hero")
        assert(c:getName() == "hero", "name")
        c:setTeam("player")
        assert(c:getTeam() == "player", "team")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_hp_and_mp() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("hero")
        c:setMaxHp(100)
        c:setHp(100)
        c:setMaxMp(50)
        c:setMp(50)
        assert(c:getHp() == 100, "hp")
        assert(c:getMp() == 50, "mp")
        assert(c:isAlive(), "alive")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_take_damage() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("goblin")
        c:setHp(100) ; c:setMaxHp(100)
        local dealt = c:takeDamage(30, "physical")
        assert(dealt == 30, "30 damage dealt")
        assert(c:getHp() == 70, "70 hp remaining")
        assert(c:isAlive(), "still alive")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_death_from_damage() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("slime")
        c:setHp(10) ; c:setMaxHp(10)
        c:takeDamage(100, "fire")
        assert(not c:isAlive(), "dead")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_heal() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("paladin")
        c:setMaxHp(100) ; c:setHp(40)
        local healed = c:heal(25)
        assert(healed == 25, "healed 25")
        assert(c:getHp() == 65, "65 hp")
        c:heal(1000)
        assert(c:getHp() == 100, "capped at max_hp")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_resistance() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("fire_elemental")
        c:setMaxHp(100) ; c:setHp(100)
        c:setResistance("fire", 0.0)
        local dealt = c:takeDamage(50, "fire")
        assert(dealt == 0, "immune to fire")
        assert(c:getHp() == 100, "no damage taken")
        local def = c:getResistance("ice")
        assert(def == 1.0, "default resistance 1.0")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_stats() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("warrior")
        c:setStat("str", 15)
        assert(c:getStat("str") == 15, "str stat")
        assert(c:getStat("missing") == 0, "missing stat = 0")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_status_effects() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("rogue")
        assert(not c:hasStatus("poison"), "no poison initially")
        c:addStatus("poison", 3)
        assert(c:hasStatus("poison"), "has poison")
        local statuses = c:getStatuses()
        assert(#statuses == 1, "one status")
        assert(statuses[1].name == "poison", "status name")
        assert(statuses[1].duration == 3, "duration 3")
        c:removeStatus("poison")
        assert(not c:hasStatus("poison"), "removed")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_status_tick() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("zombie")
        c:addStatus("burn", 2)
        c:tickStatuses()
        local statuses = c:getStatuses()
        assert(#statuses == 1, "still has burn after 1 tick")
        assert(statuses[1].duration == 1, "1 turn left")
        local expired = c:tickStatuses()
        assert(#expired == 1, "burn expired")
        assert(expired[1] == "burn", "burn in expired list")
    "#,
    )
    .exec()
    .unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// CombatAction
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn action_type_method() {
    let lua = make_vm();
    lua.load(
        r#"
        local a = luna.turnbattle.newAction("slash")
        assert(a:type() == "CombatAction", "type()")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn action_properties() {
    let lua = make_vm();
    lua.load(
        r#"
        local a = luna.turnbattle.newAction("fireball")
        a:setBaseDamage(50)
        a:setDamageType("fire")
        a:setAccuracy(0.9)
        a:setCooldown(3)
        a:setCostMp(20)
        assert(a:getBaseDamage() == 50, "damage")
        assert(a:getDamageType() == "fire", "type")
        assert(a:getAccuracy() == 0.9, "accuracy")
        assert(a:getCooldown() == 3, "cooldown")
        assert(a:getCostMp() == 20, "mp cost")
        assert(a:isReady(), "ready initially")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn action_cooldown_tick() {
    let lua = make_vm();
    lua.load(
        r#"
        local a = luna.turnbattle.newAction("slam")
        a:setCooldown(2)
        assert(a:isReady(), "ready initially")
        a:tickCooldown()
        a:tickCooldown()
        assert(a:isReady(), "still ready when not triggered")
    "#,
    )
    .exec()
    .unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusEffect (standalone)
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn status_effect_type_method() {
    let lua = make_vm();
    lua.load(
        r#"
        local e = luna.turnbattle.newStatusEffect("slow", 5)
        assert(e:type() == "StatusEffect", "type()")
        assert(e:getName() == "slow", "name")
        assert(e:getDuration() == 5, "duration 5")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn status_effect_stacks() {
    let lua = make_vm();
    lua.load(
        r#"
        local e = luna.turnbattle.newStatusEffect("bleed", 10)
        assert(e:getStacks() == 1, "1 stack init")
        e:setStacks(3)
        assert(e:getStacks() == 3, "3 stacks")
    "#,
    )
    .exec()
    .unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// CombatBattle
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn battle_type_method() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle("arena")
        assert(b:type() == "CombatBattle", "type()")
        assert(b:getName() == "arena", "name")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_add_combatant() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle()
        local hero = luna.turnbattle.newCombatant("hero")
        hero:setHp(100) ; hero:setMaxHp(100)
        b:addCombatant(hero)
        assert(b:getCount() == 1, "1 combatant")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_attack() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle()
        local hero = luna.turnbattle.newCombatant("hero")
        hero:setMaxHp(100) ; hero:setHp(100) ; hero:setTeam("players")
        local punch = luna.turnbattle.newAction("punch")
        punch:setBaseDamage(40) ; punch:setAccuracy(1.0)
        hero:addAction(punch)
        local goblin = luna.turnbattle.newCombatant("goblin")
        goblin:setMaxHp(100) ; goblin:setHp(100) ; goblin:setTeam("enemies")
        b:addCombatant(hero)
        b:addCombatant(goblin)
        local result = b:attack("hero", "punch", "goblin")
        assert(result ~= nil, "result not nil")
        assert(result.hit, "hit is true (accuracy=1)")
        assert(result.damage == 40, "40 damage")
        assert(result.attacker == "hero", "attacker name")
        assert(result.target == "goblin", "target name")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_over_when_team_wiped() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle()
        local hero = luna.turnbattle.newCombatant("hero")
        hero:setMaxHp(100) ; hero:setHp(100) ; hero:setTeam("players")
        local punch = luna.turnbattle.newAction("kill")
        punch:setBaseDamage(9999) ; punch:setAccuracy(1.0)
        hero:addAction(punch)
        local boss = luna.turnbattle.newCombatant("boss")
        boss:setMaxHp(100) ; boss:setHp(100) ; boss:setTeam("enemies")
        b:addCombatant(hero) ; b:addCombatant(boss)
        assert(not b:isOver(), "not over yet")
        b:attack("hero", "kill", "boss")
        assert(b:isOver(), "over after boss dies")
        assert(b:getWinner() == "players", "players win")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_turn_management() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle()
        for i = 1, 3 do
            local c = luna.turnbattle.newCombatant("fighter"..i)
            c:setMaxHp(100) ; c:setHp(100) ; c:setTeam("team"..i)
            b:addCombatant(c)
        end
        assert(b:getTurnCount() == 0, "0 turns initially")
        b:nextTurn()
        assert(b:getTurnCount() == 1, "1 turn after nextTurn")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_alive_names() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle()
        for _, name in ipairs({"a", "b", "c"}) do
            local c = luna.turnbattle.newCombatant(name)
            c:setMaxHp(100) ; c:setHp(100) ; c:setTeam("t")
            b:addCombatant(c)
        end
        local alive = b:getAliveNames()
        assert(#alive == 3, "3 alive")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_meta() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("bard")
        c:setMeta("guild", "thieves")
        assert(c:getMeta("guild") == "thieves", "meta value")
        assert(c:getMeta("missing") == nil, "missing meta = nil")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_hp_mp_percent() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("hero")
        c:setHp(50.0)
        c:setMaxHp(200.0)
        c:setMp(25.0)
        c:setMaxMp(100.0)
        assert(math.abs(c:getHpPercent() - 25.0) < 0.01, "hp 25%")
        assert(math.abs(c:getMpPercent() - 25.0) < 0.01, "mp 25%")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_action_names() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("knight")
        local a1 = luna.turnbattle.newAction("slash")
        local a2 = luna.turnbattle.newAction("shield_bash")
        c:addAction(a1)
        c:addAction(a2)
        local names = c:getActionNames()
        assert(#names == 2, "2 actions")
        local found = {}
        for _, n in ipairs(names) do found[n] = true end
        assert(found["slash"], "slash present")
        assert(found["shield_bash"], "shield_bash present")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combatant_status_names() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.turnbattle.newCombatant("enemy")
        c:addStatus("poison", 3)
        c:addStatus("slow", 2)
        local names = c:getStatusNames()
        assert(#names == 2, "2 statuses")
        local found = {}
        for _, n in ipairs(names) do found[n] = true end
        assert(found["poison"], "poison present")
        assert(found["slow"], "slow present")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_combat_log() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle("log_test")
        b:addToLog("battle started")
        b:addToLog("hero attacks goblin")
        local log = b:getLog()
        assert(#log == 2, "2 log entries")
        assert(log[1] == "battle started", "first message")
        assert(log[2] == "hero attacks goblin", "second message")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_remove_combatant() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle()
        local c1 = luna.turnbattle.newCombatant("hero")
        local c2 = luna.turnbattle.newCombatant("goblin")
        b:addCombatant(c1)
        b:addCombatant(c2)
        assert(b:getCount() == 2, "2 combatants")
        local ok = b:removeCombatant("goblin")
        assert(ok, "removed ok")
        assert(b:getCount() == 1, "1 after remove")
        local ok2 = b:removeCombatant("orc")
        assert(not ok2, "false for nonexistent")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_force_end() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle()
        assert(not b:isOver(), "not over initially")
        b:forceEnd("heroes")
        assert(b:isOver(), "over after forceEnd")
        assert(b:getWinner() == "heroes", "winner correct")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_force_end_no_winner() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle()
        b:forceEnd(nil)
        assert(b:isOver(), "over")
        assert(b:getWinner() == nil, "no winner")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn battle_log_from_attack() {
    let lua = make_vm();
    lua.load(
        r#"
        local b = luna.turnbattle.newBattle()
        local hero = luna.turnbattle.newCombatant("hero")
        local goblin = luna.turnbattle.newCombatant("goblin")
        goblin:setTeam("enemy")
        local atk = luna.turnbattle.newAction("strike")
        atk:setAccuracy(1.0)
        hero:addAction(atk)
        b:addCombatant(hero)
        b:addCombatant(goblin)
        b:addToLog("combat begin")
        local result = b:attack("hero", "strike", "goblin")
        assert(result ~= nil, "attack returned result")
        local log = b:getLog()
        assert(#log >= 1, "log has entries")
        assert(log[1] == "combat begin", "first entry preserved")
    "#,
    )
    .exec()
    .unwrap();
}
