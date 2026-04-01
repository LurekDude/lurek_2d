"""Fix crafting_tests.rs to match the actual Lua API:
- ingredient/output table fields are camelCase: itemType (not item_type)
- enqueue takes (recipe_id_string, time, qty) not (recipe_object, qty)
- getJob returns recipeId (not recipe_id), totalTime (not total_time)
- addNode takes (id, name, prereqs?) - 3 args, not 5
- no getNode() method - use isUnlocked/getNodeIds/getNodeCost separately
"""
import re

FILE = r"tests\crafting_tests.rs"

with open(FILE, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# Fix 1: ingredient field item_type -> itemType
content = content.replace(
    'assert(ing[1].item_type == "herb", "first ingredient")',
    'assert(ing[1].itemType == "herb", "first ingredient")'
)

# Fix 2: output field item_type -> itemType
content = content.replace(
    'assert(out[1].item_type == "iron_sword", "output type")',
    'assert(out[1].itemType == "iron_sword", "output type")'
)

# Fix 3: craft_queue_enqueue_and_update - enqueue(recipe_obj, qty) -> enqueue(recipe_id, time, qty)
old_enqueue_test = '''#[test]
fn craft_queue_enqueue_and_update() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(3)
        local r = luna.crafting.newRecipe("potion")
        r:setTime(1.0)
        local id = q:enqueue(r, 1)
        assert(id ~= nil, "got job id")
        assert(q:count() == 1, "1 job")
        local done = q:update(0.5)
        assert(#done == 0, "nothing done at 0.5s")
        done = q:update(0.6)
        assert(#done == 1, "job done after 1.1s total")
        assert(done[1] == id, "correct job id")
    "#).exec().unwrap();
}'''

new_enqueue_test = '''#[test]
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
}'''

content = content.replace(old_enqueue_test, new_enqueue_test)

# Fix 4: craft_queue_cancel - enqueue(r, 1) -> enqueue("slow_item", 9999.0, 1)
old_cancel_test = '''#[test]
fn craft_queue_cancel() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(3)
        local r = luna.crafting.newRecipe("slow_item")
        r:setTime(9999.0)
        local id = q:enqueue(r, 1)
        assert(q:count() == 1, "1 job")
        local ok = q:cancel(id)
        assert(ok, "cancel succeeded")
        assert(q:count() == 0, "0 jobs after cancel")
    "#).exec().unwrap();
}'''

new_cancel_test = '''#[test]
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
}'''

content = content.replace(old_cancel_test, new_cancel_test)

# Fix 5: craft_queue_is_full - enqueue(r, 1) -> enqueue("item", 9999.0, 1)
old_is_full_test = '''#[test]
fn craft_queue_is_full() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(2)
        local r = luna.crafting.newRecipe("item")
        r:setTime(9999.0)
        q:enqueue(r, 1)
        q:enqueue(r, 1)
        assert(q:isFull(), "queue full")
        local id = q:enqueue(r, 1)
        assert(id == nil, "enqueue fails when full")
    "#).exec().unwrap();
}'''

new_is_full_test = '''#[test]
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
}'''

content = content.replace(old_is_full_test, new_is_full_test)

# Fix 6: craft_queue_get_job - enqueue(r, 3) -> enqueue("widget", 10.0, 3) + recipe_id -> recipeId
old_get_job_test = '''#[test]
fn craft_queue_get_job() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.crafting.newCraftQueue(5)
        local r = luna.crafting.newRecipe("widget")
        r:setTime(10.0)
        local id = q:enqueue(r, 3)
        local job = q:getJob(id)
        assert(job ~= nil, "job found")
        assert(job.recipe_id == "widget", "recipe id")
        assert(job.quantity == 3, "quantity 3")
        assert(math.abs(job.progress - 0.0) < 0.001, "0 progress")
    "#).exec().unwrap();
}'''

new_get_job_test = '''#[test]
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
}'''

content = content.replace(old_get_job_test, new_get_job_test)

# Fix 7: craft_skill_can_use_recipe
# The API requires a LuaRecipe userdata object - this should be fine as-is
# But addXp only allows gaining levels up to threshold, let's verify the test is OK:
# sk:addXp(200.0) should give level > 1 since default thresholds start at 100xp
# The test logic seems fine for canUse

# Fix 8: upgrade_tree tests - addNode takes (id, name, prereqs?) - no desc or cost in addNode
# addNode("fire_1", "Fire Affinity", "Deals fire damage", {}, {}) -> addNode("fire_1", "Fire Affinity", nil)
# Note: {} as prereqs would iterate as empty table -> OK, but the API has (id, name, prereqs: Option<LuaTable>)

old_add_unlock = '''#[test]
fn upgrade_tree_add_and_unlock() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.crafting.newUpgradeTree()
        t:addNode("fire_1", "Fire Affinity", "Deals fire damage", {}, {})
        assert(t:count() == 1, "1 node")
        assert(t:canUnlock("fire_1"), "can unlock root node")
        local ok = t:unlock("fire_1")
        assert(ok, "unlock succeeded")
        assert(t:isUnlocked("fire_1"), "fire_1 unlocked")
    "#).exec().unwrap();
}'''

new_add_unlock = '''#[test]
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
}'''

content = content.replace(old_add_unlock, new_add_unlock)

old_prereqs = '''#[test]
fn upgrade_tree_prerequisites() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.crafting.newUpgradeTree()
        t:addNode("base", "Base", "", {}, {})
        t:addNode("adv", "Advanced", "", {}, {"base"})
        assert(not t:canUnlock("adv"), "cannot unlock adv without base")
        t:unlock("base")
        assert(t:canUnlock("adv"), "can unlock adv after base")
    "#).exec().unwrap();
}'''

new_prereqs = '''#[test]
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
}'''

content = content.replace(old_prereqs, new_prereqs)

old_node_ids = '''#[test]
fn upgrade_tree_node_ids() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.crafting.newUpgradeTree()
        for _, id in ipairs({"n1", "n2", "n3"}) do
            t:addNode(id, id, "", {}, {})
        end
        local ids = t:getNodeIds()
        assert(#ids == 3, "3 node ids")
    "#).exec().unwrap();
}'''

new_node_ids = '''#[test]
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
}'''

content = content.replace(old_node_ids, new_node_ids)

# Fix 9: upgrade_tree_get_node - no getNode(), use isUnlocked + setNodeCost + getNodeCost instead
old_get_node = '''#[test]
fn upgrade_tree_get_node() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.crafting.newUpgradeTree()
        t:addNode("speed_boost", "Speed Boost", "Run faster", {gold=50}, {})
        local node = t:getNode("speed_boost")
        assert(node ~= nil, "node found")
        assert(node.name == "Speed Boost", "node name")
        assert(node.description == "Run faster", "description")
        assert(node.cost.gold == 50, "cost gold")
        assert(not node.unlocked, "not unlocked initially")
    "#).exec().unwrap();
}'''

new_get_node = '''#[test]
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
}'''

content = content.replace(old_get_node, new_get_node)

# Check all replacements were applied
changes = sum(1 for a, b in zip(original.split('\n'), content.split('\n')) if a != b)
print(f"Lines changed: {changes}")

if content == original:
    print("WARNING: No changes made!")
else:
    with open(FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"crafting_tests.rs fixed")

    # Verify no Lua-style -- comments outside r# blocks remain in unexpected places
    lines = content.split('\n')
    in_raw = False
    bad = []
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if 'r#"' in line:
            in_raw = True
        if '"#' in line and in_raw:
            in_raw = False
        if not in_raw and stripped.startswith('--'):
            bad.append((i, line))
    if bad:
        print(f"WARNING: {len(bad)} potential Lua comment lines outside raw strings:")
        for ln, l in bad[:5]:
            print(f"  L{ln}: {l}")
    else:
        print("0 bad comment lines")
