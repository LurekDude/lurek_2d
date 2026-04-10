//! Integration tests for the RPG stats system (`lurek.stats`).

use lurek2d::lua_api::{create_lua_vm, SharedState};
use lurek2d::engine::config::Config;
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
    create_lua_vm(state, &Config::default().modules).unwrap()
}

#[test]
fn stats_new_sheet() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        assert(sheet ~= nil, "sheet should not be nil")
        assert(sheet:type() == "Sheet", "type should be Sheet, got " .. sheet:type())
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_define_and_get() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("strength", 10.0)
        local v = sheet:get("strength")
        assert(math.abs(v - 10.0) < 1e-5, "expected 10.0, got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_get_base() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("dex", 15.0)
        local base = sheet:getBase("dex")
        assert(math.abs(base - 15.0) < 1e-5, "expected 15.0, got " .. base)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_set_base() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("hp", 100.0)
        sheet:setBase("hp", 120.0)
        local v = sheet:get("hp")
        assert(math.abs(v - 120.0) < 1e-5, "expected 120.0, got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_buff_add() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("str", 10.0)
        local h = sheet:addBuff("str", 5.0, 1.0, -1.0, "test")
        assert(h ~= nil, "buff handle should not be nil")
        local v = sheet:get("str")
        assert(math.abs(v - 15.0) < 1e-5, "expected 15.0 (10+5), got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_buff_mul() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("atk", 10.0)
        sheet:addBuff("atk", 0.0, 2.0, -1.0, "rage")
        local v = sheet:get("atk")
        assert(math.abs(v - 20.0) < 1e-5, "expected 20.0 (10*2), got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_buff_add_and_mul() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("pow", 10.0)
        sheet:addBuff("pow", 5.0, 2.0, -1.0, "combined")
        -- (10 + 5) * 2 = 30
        local v = sheet:get("pow")
        assert(math.abs(v - 30.0) < 1e-5, "expected 30.0, got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_buff_remove() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("spd", 20.0)
        local h = sheet:addBuff("spd", 10.0, 1.0, -1.0, "")
        local v = sheet:get("spd")
        assert(math.abs(v - 30.0) < 1e-5, "expected 30.0 after buff, got " .. v)
        local removed = sheet:removeBuff(h)
        assert(removed == true, "removeBuff should return true")
        local v2 = sheet:get("spd")
        assert(math.abs(v2 - 20.0) < 1e-5, "expected 20.0 after remove, got " .. v2)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_buff_clear_all() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("a", 10.0)
        sheet:define("b", 5.0)
        sheet:addBuff("a", 10.0, 1.0, -1.0, "")
        sheet:addBuff("b", 5.0, 1.0, -1.0, "")
        sheet:clearBuffs()
        assert(math.abs(sheet:get("a") - 10.0) < 1e-5, "a should be back to base")
        assert(math.abs(sheet:get("b") - 5.0) < 1e-5, "b should be back to base")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_buff_clear_by_stat() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("x", 10.0)
        sheet:define("y", 10.0)
        sheet:addBuff("x", 5.0, 1.0, -1.0, "")
        sheet:addBuff("y", 5.0, 1.0, -1.0, "")
        sheet:clearBuffs("x")
        assert(math.abs(sheet:get("x") - 10.0) < 1e-5, "x buff should be cleared")
        assert(math.abs(sheet:get("y") - 15.0) < 1e-5, "y buff should remain")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_buff_timed_expires() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("temp", 10.0)
        sheet:addBuff("temp", 5.0, 1.0, 1.0, "timed")  -- 1 second buff
        assert(math.abs(sheet:get("temp") - 15.0) < 1e-5, "buff should be active")
        sheet:update(2.0)  -- advance 2 seconds
        assert(math.abs(sheet:get("temp") - 10.0) < 1e-5, "buff should have expired")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_get_buffs() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("stat", 10.0)
        sheet:addBuff("stat", 3.0, 1.0, -1.0, "src1")
        sheet:addBuff("stat", 2.0, 1.0, -1.0, "src2")
        local buffs = sheet:getBuffs("stat")
        assert(#buffs == 2, "expected 2 buffs, got " .. #buffs)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_max_clamp() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("hp", 100.0, {max = 150.0})
        sheet:addBuff("hp", 200.0, 1.0, -1.0, "")
        local v = sheet:get("hp")
        assert(math.abs(v - 150.0) < 1e-5, "expected 150.0 (capped at max), got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_min_clamp() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("morale", 50.0, {min = 0.0})
        sheet:addBuff("morale", -200.0, 1.0, -1.0, "")
        local v = sheet:get("morale")
        assert(v >= 0.0, "expected >= 0.0 (clamped at min), got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_define_trait() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("str", 10.0)
        lurek.stats.defineTrait("strong", {
            buffs = { {stat="str", add=5.0, mul=1.0} }
        })
        sheet:addTrait("strong")
        local v = sheet:get("str")
        assert(math.abs(v - 15.0) < 1e-5, "trait buff should apply, got " .. v)
        assert(sheet:hasTrait("strong"), "should have trait")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_remove_trait() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("int", 10.0)
        lurek.stats.defineTrait("smart", {
            buffs = { {stat="int", add=10.0, mul=1.0} }
        })
        sheet:addTrait("smart")
        assert(math.abs(sheet:get("int") - 20.0) < 1e-5, "trait should apply")
        local removed = sheet:removeTrait("smart")
        assert(removed == true, "removeTrait should return true")
        assert(math.abs(sheet:get("int") - 10.0) < 1e-5, "trait buff should be removed")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_flags() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        assert(sheet:hasFlag("poisoned") == false, "flag should not be set initially")
        sheet:setFlag("poisoned")
        assert(sheet:hasFlag("poisoned") == true, "flag should be set")
        sheet:clearFlag("poisoned")
        assert(sheet:hasFlag("poisoned") == false, "flag should be cleared")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_get_flags() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:setFlag("burning")
        sheet:setFlag("slowed")
        local flags = sheet:getFlags()
        assert(#flags == 2, "expected 2 flags, got " .. #flags)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_add_xp_levelup() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:setLevelThresholds({100, 200, 400})
        assert(sheet:getLevel() == 1, "should start at level 1")
        local gained = sheet:addXP(150.0)
        assert(gained >= 1, "should have gained at least 1 level")
        assert(sheet:getLevel() >= 2, "level should be at least 2")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_skill_define_and_use() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:defineSkill("slash", {maxLevel=5, cooldown=0.0})
        sheet:learnSkill("slash")
        assert(sheet:getSkillLevel("slash") == 1, "skill should be level 1")
        local cd = sheet:useSkill("slash")
        assert(cd == 0.0, "cooldown should be 0 when no cooldown set")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_skill_cooldown() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:defineSkill("fireball", {maxLevel=3, cooldown=2.0})
        sheet:learnSkill("fireball")
        local cd = sheet:useSkill("fireball")
        assert(math.abs(cd - 2.0) < 1e-5, "cooldown should be 2.0 after use")
        local ok, err = pcall(function() sheet:useSkill("fireball") end)
        assert(not ok, "using skill on cooldown should fail")
        sheet:update(3.0)
        local remaining = sheet:getCooldownRemaining("fireball")
        assert(remaining <= 0.0, "cooldown should expire after update")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_action_points() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:setActionPoints(3.0)
        local cur, max = sheet:getActionPoints()
        assert(math.abs(max - 3.0) < 1e-5, "max AP should be 3")
        assert(math.abs(cur - 3.0) < 1e-5, "initial cur AP should be 3")
        local remaining = sheet:spendActionPoints(1.0)
        assert(math.abs(remaining - 2.0) < 1e-5, "remaining AP should be 2")
        sheet:beginTurn()
        local cur2, _ = sheet:getActionPoints()
        assert(math.abs(cur2 - 3.0) < 1e-5, "beginTurn should restore AP")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_morale() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:setMorale(100.0)
        local cur, max = sheet:getMorale()
        assert(math.abs(max - 100.0) < 1e-5, "max morale should be 100")
        local new_cur = sheet:adjustMorale(-80.0)
        assert(math.abs(new_cur - 20.0) < 1e-5, "morale should be 20 after -80")
        local state = sheet:checkMorale()
        assert(state == "panic" or state == nil, "morale at 20 should be panic or nil (based on threshold)")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_resistance_and_damage() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("hp", 100.0)
        sheet:setResistance("fire", 0.5)
        local resist = sheet:getResistance("fire")
        assert(math.abs(resist - 0.5) < 1e-5, "fire resistance should be 0.5")
        local actual = sheet:applyDamage("hp", 40.0, "fire")
        -- 40 * (1 - 0.5) = 20
        assert(math.abs(actual - 20.0) < 1e-5, "actual damage should be 20, got " .. actual)
        local hp = sheet:get("hp")
        assert(math.abs(hp - 80.0) < 1e-5, "hp reduced by 20, got " .. hp)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_snapshot_restore() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("vigor", 50.0)
        sheet:setFlag("cursed")
        sheet:addXP(10.0)
        local snap = sheet:snapshot()
        assert(snap ~= nil, "snapshot should not be nil")
        -- Modify sheet
        sheet:setBase("vigor", 999.0)
        sheet:clearFlag("cursed")
        -- Restore
        sheet:restore(snap)
        assert(math.abs(sheet:get("vigor") - 50.0) < 1e-5, "restore should reset vigor")
        assert(sheet:hasFlag("cursed"), "restore should re-set flag")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_regen() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("mana", 50.0, {max = 100.0})
        sheet:setBase("mana", 50.0)
        sheet:setRegen("mana", 10.0)  -- 10 per second
        sheet:update(2.0)             -- advance 2 seconds
        local v = sheet:get("mana")
        assert(v > 50.0, "mana should have regenerated, got " .. v)
        assert(v <= 100.0, "mana should not exceed max")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_define_race_and_class() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("str", 10.0)
        sheet:define("int", 10.0)
        lurek.stats.defineRace("elf", {
            bases = {str = -2.0, int = 3.0},
            traits = {}
        })
        lurek.stats.defineClass("mage", {
            bases = {int = 5.0},
            traits = {}
        })
        local races = lurek.stats.getRaceNames()
        local classes = lurek.stats.getClassNames()
        assert(#races >= 1, "should have at least one race")
        assert(#classes >= 1, "should have at least one class")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_encumbrance() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:setEncumbrance(5.0, 10.0)
        local cur, max = sheet:getEncumbrance()
        assert(math.abs(cur - 5.0) < 1e-5, "current enc should be 5")
        assert(math.abs(max - 10.0) < 1e-5, "max enc should be 10")
        assert(sheet:isEncumbered() == false, "5 < 10 so not encumbered")
        sheet:setEncumbrance(15.0, 10.0)
        assert(sheet:isEncumbered() == true, "15 > 10 so encumbered")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_initiative() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:setInitiative(7.5)
        local init = sheet:getInitiative()
        assert(math.abs(init - 7.5) < 1e-5, "initiative should be 7.5")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_use_count() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("swords", 0.0)
        assert(sheet:getUseCount("swords") == 0, "initial use count should be 0")
        sheet:recordUse("swords")
        sheet:recordUse("swords")
        assert(sheet:getUseCount("swords") == 2, "use count should be 2")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn stats_linear_level_thresholds() {
    let lua = make_vm();
    lua.load(
        r#"
        local sheet = lurek.stats.newSheet()
        sheet:setLevelThresholds({base=100, increment=50})
        local gained = sheet:addXP(110.0)
        assert(gained >= 1, "should level up at 100 xp")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn sheet_get_stat_names() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("strength", 10.0)
        sheet:define("agility", 8.0)
        sheet:define("wisdom", 12.0)
        local names = sheet:getStatNames()
        assert(#names == 3, "3 stat names")
        local found = {}
        for _, n in ipairs(names) do found[n] = true end
        assert(found["strength"], "strength present")
        assert(found["agility"], "agility present")
        assert(found["wisdom"], "wisdom present")
    "#).exec().unwrap();
}

#[test]
fn sheet_get_buff_count() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("attack", 10.0)
        sheet:define("defense", 5.0)
        sheet:addBuff("attack", 2.0, 1.0, -1)
        sheet:addBuff("attack", 1.5, 1.0, -1)
        sheet:addBuff("defense", 1.0, 1.0, -1)
        local total = sheet:getBuffCount(nil)
        assert(total == 3, "3 total buffs")
        local atk_buffs = sheet:getBuffCount("attack")
        assert(atk_buffs == 2, "2 attack buffs")
        local def_buffs = sheet:getBuffCount("defense")
        assert(def_buffs == 1, "1 defense buff")
    "#).exec().unwrap();
}

#[test]
fn sheet_recover_action_points() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:setActionPoints(10.0)
        sheet:spendActionPoints(7.0)
        local current = sheet:getActionPoints()
        assert(math.abs(current - 3.0) < 0.01, "3 AP remaining")
        local new_val = sheet:recoverActionPoints(4.0)
        assert(math.abs(new_val - 7.0) < 0.01, "recovered to 7")
        -- recovery capped at max
        local capped = sheet:recoverActionPoints(100.0)
        assert(math.abs(capped - 10.0) < 0.01, "capped at max 10")
    "#).exec().unwrap();
}

// ── Additional stats coverage ────────────────────────────────────────────────

#[test]
fn sheet_update_ticks_regen() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("hp", 50.0)
        sheet:setMax("hp", 100.0)
        sheet:setRegen("hp", 10.0)  -- 10 hp/s
        sheet:update(1.0)
        local hp = sheet:get("hp")
        assert(math.abs(hp - 60.0) < 0.01, "hp should be 60 after 1s regen, got " .. hp)
    "#).exec().unwrap();
}

#[test]
fn sheet_snapshot_restore_roundtrip() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("str", 15.0)
        sheet:define("agi", 12.0)
        local snap = sheet:snapshot()
        -- change values
        sheet:setBase("str", 99.0)
        sheet:setBase("agi", 1.0)
        -- restore
        sheet:restore(snap)
        assert(math.abs(sheet:get("str") - 15.0) < 0.01, "str restored")
        assert(math.abs(sheet:get("agi") - 12.0) < 0.01, "agi restored")
    "#).exec().unwrap();
}

#[test]
fn sheet_set_and_get_xp_and_level() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:setXP(0.0)
        sheet:setLevel(5)
        assert(sheet:getLevel() == 5, "level is 5")
    "#).exec().unwrap();
}

#[test]
fn sheet_begin_turn_restores_action_points() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:setActionPoints(4.0)
        sheet:spendActionPoints(3.0)
        assert(math.abs(sheet:getActionPoints() - 1.0) < 0.01, "1 AP left")
        sheet:beginTurn()
        assert(math.abs(sheet:getActionPoints() - 4.0) < 0.01, "AP restored after beginTurn")
    "#).exec().unwrap();
}

#[test]
fn sheet_setmin_clamps_value() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("armor", 5.0)
        sheet:setMin("armor", 0.0)
        sheet:setBase("armor", -10.0)  -- below minimum
        local val = sheet:get("armor")
        assert(val >= 0.0, "armor clamped to min, got " .. val)
    "#).exec().unwrap();
}

#[test]
fn sheet_setmax_clamps_value() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:define("speed", 10.0)
        sheet:setMax("speed", 20.0)
        sheet:setBase("speed", 50.0)  -- above maximum
        local val = sheet:get("speed")
        assert(val <= 20.0, "speed clamped to max, got " .. val)
    "#).exec().unwrap();
}

#[test]
fn sheet_has_trait_returns_false_if_not_added() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        assert(sheet:hasTrait("warrior") == false, "trait not present")
    "#).exec().unwrap();
}

#[test]
fn sheet_record_use_increments_count() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = lurek.stats.newSheet()
        sheet:recordUse("fireball")
        sheet:recordUse("fireball")
        sheet:recordUse("fireball")
        assert(sheet:getUseCount("fireball") == 3, "use count is 3")
        assert(sheet:getUseCount("unknown") == 0, "unknown is 0")
    "#).exec().unwrap();
}
