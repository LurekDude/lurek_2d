//! Integration tests for `luna.crafting.*`.

use luna2d::lua_api::{create_lua_vm, SharedState};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(800, 600, "Test", PathBuf::from("."))));
    create_lua_vm(state).unwrap()
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn recipe_type_method() {
    let lua = make_vm();
    lua.load(r#"
        local r = luna.crafting.newRecipe("sword_recipe", "craft")
        assert(r:type() == "Recipe", "type()")
        assert(r:typeOf("Recipe"), "typeOf")
    "#).exec().unwrap();
}

#[test]
fn recipe_id_and_name() {
    let lua = make_vm();
    lua.load(r#"
        local r = luna.crafting.newRecipe("iron_sword")
        assert(r:getId() == "iron_sword", "id")
        r:setName("Iron Sword")
        assert(r:getName() == "Iron Sword", "name")
    "#).exec().unwrap();
}

#[test]
fn recipe_ingredients() {
    let lua = make_vm();
    lua.load(r#"
        local r = luna.crafting.newRecipe("potion")
        r:addIngredient("herb", 3, true)
        r:addIngredient("water", 1, true)
        r:addIngredient("vial", 1, false)
        local ing = r:getIngredients()
        assert(#ing == 3, "3 ingredients")
        assert(ing[1].itemType == "herb", "first ingredient")
        assert(ing[1].quantity == 3, "quantity 3")
        assert(ing[3].consumed == false, "vial not consumed")
    "#).exec().unwrap();
}

#[test]
fn recipe_outputs() {
    let lua = make_vm();
    lua.load(r#"
        local r = luna.crafting.newRecipe("sword")
        r:addOutput("iron_sword", 1, "superior")
        local out = r:getOutputs()
        assert(#out == 1, "1 output")
        assert(out[1].itemType == "iron_sword", "output type")
        assert(out[1].quantity == 1, "quantity 1")
        assert(out[1].quality == "superior", "quality")
    "#).exec().unwrap();
}

#[test]
fn recipe_time_and_station() {
    let lua = make_vm();
    lua.load(r#"
        local r = luna.crafting.newRecipe("armor")
        r:setTime(30.0)
        r:setStationType("forge")
        r:setStationLevel(2)
        assert(r:getTime() == 30.0, "time")
        assert(r:getStationType() == "forge", "station type")
        assert(r:getStationLevel() == 2, "station level")
    "#).exec().unwrap();
}

#[test]
fn recipe_skill_requirements() {
    let lua = make_vm();
    lua.load(r#"
        local r = luna.crafting.newRecipe("mithril_sword")
        r:setSkill("smithing", 5)
        r:setSkillXp(25.0)
        assert(r:getSkill() == "smithing", "skill")
        assert(r:getSkillXp() == 25.0, "skill xp")
    "#).exec().unwrap();
}

#[test]
fn recipe_tags() {
    let lua = make_vm();
    lua.load(r#"
        local r = luna.crafting.newRecipe("bread")
        r:addTag("food")
        r:addTag("cooking")
        assert(r:hasTag("food"), "has food")
        assert(not r:hasTag("weapon"), "no weapon")
    "#).exec().unwrap();
}

#[test]
fn recipe_enabled_toggle() {
    let lua = make_vm();
    lua.load(r#"
        local r = luna.crafting.newRecipe("steak")
        assert(r:isEnabled(), "enabled by default")
        r:setEnabled(false)
        assert(not r:isEnabled(), "disabled")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// RecipeRegistry
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn registry_type_method() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        assert(reg:type() == "RecipeRegistry", "type()")
    "#).exec().unwrap();
}

#[test]
fn registry_add_and_get() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        local r = luna.crafting.newRecipe("potion")
        reg:add(r)
        assert(reg:count() == 1, "1 recipe")
        local got = reg:get("potion")
        assert(got ~= nil, "got recipe")
        assert(got:getId() == "potion", "id matches")
    "#).exec().unwrap();
}

#[test]
fn registry_remove() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        reg:add(luna.crafting.newRecipe("r1"))
        reg:add(luna.crafting.newRecipe("r2"))
        assert(reg:count() == 2, "2 before remove")
        reg:remove("r1")
        assert(reg:count() == 1, "1 after remove")
        assert(reg:get("r1") == nil, "r1 gone")
    "#).exec().unwrap();
}

#[test]
fn registry_ids() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        for _, id in ipairs({"a", "b", "c"}) do
            reg:add(luna.crafting.newRecipe(id))
        end
        local ids = reg:getIds()
        assert(#ids == 3, "3 ids")
    "#).exec().unwrap();
}

#[test]
fn registry_find_by_output() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        local r = luna.crafting.newRecipe("sword_r")
        r:addOutput("iron_sword", 1, "normal")
        reg:add(r)
        local found = reg:findByOutput("iron_sword")
        assert(#found == 1, "found 1")
        assert(found[1] == "sword_r", "recipe id")
    "#).exec().unwrap();
}

#[test]
fn registry_for_station() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        local r1 = luna.crafting.newRecipe("anvil_r") ; r1:setStationType("anvil")
        local r2 = luna.crafting.newRecipe("bench_r") ; r2:setStationType("workbench")
        reg:add(r1) ; reg:add(r2)
        local ids = reg:forStation("anvil")
        assert(#ids == 1, "1 anvil recipe")
        assert(ids[1] == "anvil_r", "correct recipe")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// Station
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn station_type_method() {
    let lua = make_vm();
    lua.load(r#"
        local s = luna.crafting.newStation("forge", 3)
        assert(s:type() == "Station", "type()")
        assert(s:getType() == "forge", "station type")
        assert(s:getLevel() == 3, "level")
    "#).exec().unwrap();
}

#[test]
fn station_can_process_matching() {
    let lua = make_vm();
    lua.load(r#"
        local station = luna.crafting.newStation("forge", 2)
        local r = luna.crafting.newRecipe("sword")
        r:setStationType("forge")
        r:setStationLevel(2)
        assert(station:canProcess(r), "can process matching recipe")
        local r2 = luna.crafting.newRecipe("master_sword")
        r2:setStationType("forge")
        r2:setStationLevel(5)
        assert(not station:canProcess(r2), "cannot process level 5 recipe")
    "#).exec().unwrap();
}

#[test]
fn station_speed_multiplier() {
    let lua = make_vm();
    lua.load(r#"
        local station = luna.crafting.newStation("forge", 1)
        local r = luna.crafting.newRecipe("shield")
        r:setStationType("forge")
        r:setStationLevel(1)
        r:setTime(20.0)
        local base_time = station:effectiveTime(r)
        station:setSpeedMultiplier(2.0)
        local fast_time = station:effectiveTime(r)
        assert(fast_time < base_time, "faster with higher multiplier")
        assert(math.abs(fast_time - 10.0) < 0.001, "half the time at 2x speed")
    "#).exec().unwrap();
}

#[test]
fn station_active_flag() {
    let lua = make_vm();
    lua.load(r#"
        local s = luna.crafting.newStation("bench")
        assert(s:isActive(), "active by default")
        s:setActive(false)
        assert(not s:isActive(), "inactive")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// CraftSkill
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn craft_skill_type_method() {
    let lua = make_vm();
    lua.load(r#"
        local sk = luna.crafting.newCraftSkill("smithing")
        assert(sk:type() == "CraftSkill", "type()")
        assert(sk:getName() == "smithing", "name")
    "#).exec().unwrap();
}

#[test]
fn craft_skill_level_up() {
    let lua = make_vm();
    lua.load(r#"
        local sk = luna.crafting.newCraftSkill("tailoring")
        assert(sk:getLevel() == 1, "starts level 1")
        assert(sk:getXp() == 0.0, "starts 0 xp")
        local leveled = sk:addXp(200.0)
        assert(leveled >= 1, "at least 1 level up")
        assert(sk:getLevel() > 1, "leveled up")
    "#).exec().unwrap();
}

#[test]
fn craft_skill_can_use_recipe() {
    let lua = make_vm();
    lua.load(r#"
        local sk = luna.crafting.newCraftSkill("cooking")
        sk:addXp(200.0)
        local r = luna.crafting.newRecipe("bread")
        r:setSkill("cooking", 1)
        assert(sk:canUse(r), "can use level 1 recipe")
        local r2 = luna.crafting.newRecipe("master_feast")
        r2:setSkill("cooking", 100)
        assert(not sk:canUse(r2), "cannot use level 100 recipe yet")
    "#).exec().unwrap();
}

#[test]
fn craft_skill_xp_to_next() {
    let lua = make_vm();
    lua.load(r#"
        local sk = luna.crafting.newCraftSkill("alchemy")
        local xp_needed = sk:getXpToNext()
        assert(xp_needed > 0, "xp needed > 0")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// CraftQueue
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn craft_queue_type_method() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(5)
        assert(q:type() == "CraftQueue", "type()")
        assert(q:getMaxJobs() == 5, "max jobs")
    "#).exec().unwrap();
}

#[test]
fn craft_queue_enqueue_and_update() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(3)
        local id = q:enqueue("potion", 1.0, 1)
        assert(id ~= nil, "got job id")
        assert(q:count() == 1, "1 job")
        local done = q:update(0.5)
        assert(#done == 0, "nothing done at 0.5s")
        done = q:update(0.6)
        assert(#done == 1, "job done after 1.1s total")
        assert(done[1] == id, "correct job id")
    "#).exec().unwrap();
}

#[test]
fn craft_queue_cancel() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(3)
        local id = q:enqueue("slow_item", 9999.0, 1)
        assert(q:count() == 1, "1 job")
        local ok = q:cancel(id)
        assert(ok, "cancel succeeded")
        assert(q:count() == 0, "0 jobs after cancel")
    "#).exec().unwrap();
}

#[test]
fn craft_queue_is_full() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(2)
        q:enqueue("item", 9999.0, 1)
        q:enqueue("item", 9999.0, 1)
        assert(q:isFull(), "queue full")
        local id = q:enqueue("item", 9999.0, 1)
        assert(id == nil, "enqueue fails when full")
    "#).exec().unwrap();
}

#[test]
fn craft_queue_get_job() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(5)
        local id = q:enqueue("widget", 10.0, 3)
        local job = q:getJob(id)
        assert(job ~= nil, "job found")
        assert(job.recipeId == "widget", "recipe id")
        assert(job.quantity == 3, "quantity 3")
        assert(math.abs(job.progress - 0.0) < 0.001, "0 progress")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// UpgradeTree
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn upgrade_tree_type_method() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.crafting.newUpgradeTree("skills")
        assert(t:type() == "UpgradeTree", "type()")
        assert(t:getName() == "skills", "name")
    "#).exec().unwrap();
}

#[test]
fn upgrade_tree_add_and_unlock() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.crafting.newUpgradeTree()
        t:addNode("fire_1", "Fire Affinity")
        assert(t:count() == 1, "1 node")
        assert(t:canUnlock("fire_1"), "can unlock root node")
        local ok = t:unlock("fire_1")
        assert(ok, "unlock succeeded")
        assert(t:isUnlocked("fire_1"), "fire_1 unlocked")
    "#).exec().unwrap();
}

#[test]
fn upgrade_tree_prerequisites() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.crafting.newUpgradeTree()
        t:addNode("base", "Base")
        t:addNode("adv", "Advanced", {"base"})
        assert(not t:canUnlock("adv"), "cannot unlock adv without base")
        t:unlock("base")
        assert(t:canUnlock("adv"), "can unlock adv after base")
    "#).exec().unwrap();
}

#[test]
fn upgrade_tree_node_ids() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.crafting.newUpgradeTree()
        for _, id in ipairs({"n1", "n2", "n3"}) do
            t:addNode(id, id)
        end
        local ids = t:getNodeIds()
        assert(#ids == 3, "3 node ids")
    "#).exec().unwrap();
}

#[test]
fn upgrade_tree_get_node() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.crafting.newUpgradeTree()
        t:addNode("speed_boost", "Speed Boost")
        t:setNodeCost("speed_boost", {gold=50})
        local cost = t:getNodeCost("speed_boost")
        assert(cost ~= nil, "cost found")
        assert(cost.gold == 50, "cost gold")
        assert(not t:isUnlocked("speed_boost"), "not unlocked initially")
        assert(t:canUnlock("speed_boost"), "can unlock root")
    "#).exec().unwrap();
}

#[test]
fn recipe_get_tags() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        local r = luna.crafting.newRecipe("sword")
        r:addTag("weapon")
        r:addTag("metal")
        reg:add(r)
        local tags = reg:get("sword"):getTags()
        assert(#tags == 2, "2 tags")
        local found = {}
        for _, tag in ipairs(tags) do found[tag] = true end
        assert(found["weapon"], "weapon tag")
        assert(found["metal"], "metal tag")
    "#).exec().unwrap();
}

#[test]
fn registry_find_by_tag() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        local r1 = luna.crafting.newRecipe("sword"); r1:addTag("weapon"); reg:add(r1)
        local r2 = luna.crafting.newRecipe("axe"); r2:addTag("weapon"); reg:add(r2)
        local r3 = luna.crafting.newRecipe("potion"); r3:addTag("consumable"); reg:add(r3)
        local weapons = reg:findByTag("weapon")
        assert(#weapons == 2, "2 weapons")
        local consumables = reg:findByTag("consumable")
        assert(#consumables == 1, "1 consumable")
    "#).exec().unwrap();
}

#[test]
fn craftskill_set_level() {
    let lua = make_vm();
    lua.load(r#"
        local skill = luna.crafting.newCraftSkill("smithing")
        skill:addXp(900.0)
        local lvl_before = skill:getLevel()
        skill:setLevel(1)
        assert(skill:getLevel() == 1, "level set to 1")
        assert(skill:getXp() == 0.0, "xp reset to 0")
    "#).exec().unwrap();
}

#[test]
fn upgrade_tree_reset_node() {
    let lua = make_vm();
    lua.load(r#"
        local tree = luna.crafting.newUpgradeTree("tech")
        tree:addNode("forge", 5)
        tree:unlock("forge")
        assert(tree:isUnlocked("forge"), "forge unlocked")
        local ok = tree:resetNode("forge")
        assert(ok, "reset ok")
        assert(not tree:isUnlocked("forge"), "forge re-locked")
        local unlocked = tree:getUnlockedIds()
        assert(#unlocked == 0, "no unlocked nodes")
    "#).exec().unwrap();
}

#[test]
fn craft_queue_clear() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(3)
        q:enqueue("plank", 10.0, 1)
        q:enqueue("plank", 10.0, 1)
        assert(q:count() == 2, "2 jobs")
        q:clear()
        assert(q:count() == 0, "0 after clear")
    "#).exec().unwrap();
}

#[test]
fn craft_queue_get_all_jobs() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(5)
        q:enqueue("bolt", 5.0, 1)
        q:enqueue("nut", 3.0, 1)
        local jobs = q:getAllJobs()
        assert(#jobs == 2, "2 jobs in getAllJobs")
        local recipes = {}
        for _, j in ipairs(jobs) do
            recipes[j.recipeId] = true
            assert(j.id ~= nil, "job has id")
            assert(j.quantity >= 1, "job has quantity")
        end
        assert(recipes["bolt"], "bolt job present")
        assert(recipes["nut"], "nut job present")
    "#).exec().unwrap();
}
