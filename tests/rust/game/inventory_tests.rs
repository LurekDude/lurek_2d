//! Integration tests for `lurek.inventory.*` Lua API.

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

// ── Item ─────────────────────────────────────────────────────────────────────

#[test]
fn inventory_new_item_default_type() {
    let lua = make_vm();
    let result: String = lua
        .load(
            r#"
        local item = luna.inventory.newItem("sword")
        return item:getType()
    "#,
        )
        .eval()
        .unwrap();
    assert_eq!(result, "sword");
}

#[test]
fn inventory_item_weight() {
    let lua = make_vm();
    let w: f64 = lua
        .load(
            r#"
        local item = luna.inventory.newItem("rock")
        item:setWeight(3.5)
        return item:getWeight()
    "#,
        )
        .eval()
        .unwrap();
    assert!((w - 3.5).abs() < 1e-5);
}

#[test]
fn inventory_item_size() {
    let lua = make_vm();
    let (w, h): (u32, u32) = lua
        .load(
            r#"
        local item = luna.inventory.newItem("potion")
        item:setSize(2, 3)
        return item:getSize()
    "#,
        )
        .eval()
        .unwrap();
    assert_eq!((w, h), (2, 3));
}

#[test]
fn inventory_item_stack_limit() {
    let lua = make_vm();
    let n: u32 = lua
        .load(
            r#"
        local item = luna.inventory.newItem("arrow")
        item:setStackLimit(99)
        return item:getStackLimit()
    "#,
        )
        .eval()
        .unwrap();
    assert_eq!(n, 99);
}

#[test]
fn inventory_item_tags() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local item = luna.inventory.newItem("sword")
        item:addTag("weapon")
        item:addTag("metal")
        return item:hasTag("weapon") and not item:hasTag("armor")
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_item_remove_tag() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local item = luna.inventory.newItem("sword")
        item:addTag("weapon")
        item:removeTag("weapon")
        return item:hasTag("weapon")
    "#,
        )
        .eval()
        .unwrap();
    assert!(!res);
}

#[test]
fn inventory_item_clone() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local item = luna.inventory.newItem("sword")
        item:setWeight(5.0)
        local copy = item:clone()
        copy:setWeight(1.0)
        return item:getWeight() == 5.0 and copy:getWeight() == 1.0
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_item_type_method() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local item = luna.inventory.newItem("bow")
        return item:type() == "Item"
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

// ── ItemStack ─────────────────────────────────────────────────────────────────

#[test]
fn inventory_itemstack_new() {
    let lua = make_vm();
    let qty: u32 = lua
        .load(
            r#"
        local item = luna.inventory.newItem("potion")
        item:setStackLimit(10)
        local stack = luna.inventory.newItemStack(item, 5)
        return stack:getQuantity()
    "#,
        )
        .eval()
        .unwrap();
    assert_eq!(qty, 5);
}

#[test]
fn inventory_itemstack_add_remove() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local item = luna.inventory.newItem("potion")
        item:setStackLimit(10)
        local stack = luna.inventory.newItemStack(item, 5, 10)
        local leftover = stack:add(3)
        local removed = stack:remove(2)
        return stack:getQuantity() == 6 and leftover == 0 and removed == 2
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_itemstack_is_full() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local item = luna.inventory.newItem("coin")
        item:setStackLimit(10)
        local stack = luna.inventory.newItemStack(item, 10, 10)
        return stack:isFull()
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_itemstack_split() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local item = luna.inventory.newItem("gem")
        item:setStackLimit(20)
        local stack = luna.inventory.newItemStack(item, 8, 20)
        local half = stack:split(4)
        return stack:getQuantity() == 4 and half ~= nil and half:getQuantity() == 4
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_itemstack_merge() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local item = luna.inventory.newItem("coin")
        item:setStackLimit(10)
        local a = luna.inventory.newItemStack(item, 4, 10)
        local b = luna.inventory.newItemStack(item, 3, 10)
        local leftover = a:merge(b)
        return a:getQuantity() == 7 and leftover == 0
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

// ── Slot ──────────────────────────────────────────────────────────────────────

#[test]
fn inventory_slot_new_and_state() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local slot = luna.inventory.newSlot("weapon", "active")
        return slot:getType() == "weapon" and slot:getState() == "active"
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_slot_can_accept() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local slot = luna.inventory.newSlot("any", "active")
        slot:setCapacity(1, 1)
        local item = luna.inventory.newItem("sword")
        item:setSize(1, 1)
        return slot:canAccept(item)
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_slot_set_and_clear() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local slot = luna.inventory.newSlot("any", "active")
        slot:setCapacity(2, 2)
        local item = luna.inventory.newItem("potion")
        item:setSize(1, 1)
        item:setStackLimit(5)
        local stack = luna.inventory.newItemStack(item, 1, 5)
        local placed = slot:setStack(stack)
        local empty_before = slot:isEmpty()
        slot:clear()
        return placed and not empty_before and slot:isEmpty()
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

// ── Container ─────────────────────────────────────────────────────────────────

#[test]
fn inventory_container_new_and_slot_count() {
    let lua = make_vm();
    let n: u32 = lua
        .load(
            r#"
        local c = luna.inventory.newContainer("backpack", "fixed", 5)
        return c:getSlotCount()
    "#,
        )
        .eval()
        .unwrap();
    assert_eq!(n, 5);
}

#[test]
fn inventory_container_expand() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local c = luna.inventory.newContainer("chest", "expandable", 3)
        c:setMaxSlots(10)
        local ok = c:expand(4)
        return ok and c:getSlotCount() == 7
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_container_get_slot() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local c = luna.inventory.newContainer("bag", "fixed", 3)
        local slot = c:getSlot(1)
        return slot ~= nil
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_container_weight() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local c = luna.inventory.newContainer("bag", "fixed", 5)
        c:setWeightLimit(20.0)
        local item = luna.inventory.newItem("rock")
        item:setWeight(5.0)
        item:setStackLimit(10)
        c:addItem(item, 2)
        local w = c:getCurrentWeight()
        return w > 0.0 and c:getWeightLimit() == 20.0
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

// ── Inventory ─────────────────────────────────────────────────────────────────

#[test]
fn inventory_add_and_get_container() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local inv = luna.inventory.newInventory()
        local c = luna.inventory.newContainer("backpack", "fixed", 5)
        inv:addContainer("backpack", c)
        local got = inv:getContainer("backpack")
        return got ~= nil and got:getName() == "backpack"
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_equip_and_unequip() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local inv = luna.inventory.newInventory()
        local slot = luna.inventory.newSlot("any", "active")
        slot:setCapacity(2, 2)
        inv:addEquipSlot("mainhand", slot)
        local item = luna.inventory.newItem("sword")
        item:setSize(1, 1)
        item:setStackLimit(1)
        local stack = luna.inventory.newItemStack(item, 1, 1)
        local ok = inv:equip("mainhand", stack)
        local equipped = inv:getEquipped("mainhand")
        inv:unequip("mainhand")
        local gone = inv:getEquipped("mainhand")
        return ok and equipped ~= nil and gone == nil
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_item_set_active() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local inv = luna.inventory.newInventory()
        local slot = luna.inventory.newSlot("any", "active")
        slot:setCapacity(2, 2)
        inv:addEquipSlot("mainhand", slot)
        -- Equip an item with tag "weapon"
        local item = luna.inventory.newItem("sword")
        item:addTag("weapon")
        item:setSize(1, 1)
        item:setStackLimit(1)
        local stack = luna.inventory.newItemStack(item, 1, 1)
        inv:equip("mainhand", stack)
        -- Create set requiring "weapon" in mainhand
        local set = luna.inventory.newItemSet("swordsman")
        set:addRequirement("weapon", "mainhand")
        inv:addItemSet(set)
        local active = inv:getActiveSets()
        return #active == 1 and active[1] == "swordsman"
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_subsystems() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local inv = luna.inventory.newInventory()
        inv:enableSubsystem("weight")
        inv:enableSubsystem("size")
        local w = inv:isSubsystemEnabled("weight")
        local s = inv:isSubsystemEnabled("size")
        inv:disableSubsystem("weight")
        local w2 = inv:isSubsystemEnabled("weight")
        return w and s and not w2
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_transfer_between_containers() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local inv = luna.inventory.newInventory()
        local src = luna.inventory.newContainer("src", "fixed", 3)
        local dst = luna.inventory.newContainer("dst", "fixed", 3)
        local item = luna.inventory.newItem("gem")
        item:setSize(1,1)
        item:setStackLimit(5)
        src:addItem(item, 2)
        inv:addContainer("src", src)
        inv:addContainer("dst", dst)
        local ok = inv:transfer("src", 1, "dst", 1)
        return ok
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn inventory_type_method() {
    let lua = make_vm();
    let res: bool = lua
        .load(
            r#"
        local inv = luna.inventory.newInventory()
        return inv:type() == "Inventory"
    "#,
        )
        .eval()
        .unwrap();
    assert!(res);
}

#[test]
fn container_count_item() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.inventory.newContainer("main")
        c:addItem(luna.inventory.newItem("sword"), 3)
        assert(c:countItem("sword") == 3, "count 3 swords")
        assert(c:countItem("shield") == 0, "0 shields")
    "#).exec().unwrap();
}

#[test]
fn container_has_item() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.inventory.newContainer("main")
        c:addItem(luna.inventory.newItem("potion"), 5)
        assert(c:hasItem("potion"), "has at least 1")
        assert(c:hasItem("potion", 5), "has 5")
        assert(not c:hasItem("potion", 6), "doesn't have 6")
    "#).exec().unwrap();
}

#[test]
fn container_remove_item() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.inventory.newContainer("main")
        c:addItem(luna.inventory.newItem("arrow"), 10)
        local ok = c:removeItem("arrow", 4)
        assert(ok, "remove 4 ok")
        assert(c:countItem("arrow") == 6, "6 arrows left")
        local fail = c:removeItem("arrow", 100)
        assert(not fail, "cannot remove 100")
        assert(c:countItem("arrow") == 6, "still 6 after failed remove")
    "#).exec().unwrap();
}

#[test]
fn container_to_list() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.inventory.newContainer("main")
        c:addItem(luna.inventory.newItem("gem"), 2)
        c:addItem(luna.inventory.newItem("herb"), 7)
        local list = c:toList()
        assert(#list == 2, "2 item entries")
        local found = {}
        for _, entry in ipairs(list) do
            found[entry.itemType] = entry.quantity
        end
        assert(found["gem"] == 2, "gem qty")
        assert(found["herb"] == 7, "herb qty")
    "#).exec().unwrap();
}

#[test]
fn inventory_has_item_cross_container() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory()
        local c1 = luna.inventory.newContainer("main")
        c1:addItem(luna.inventory.newItem("coin"), 5)
        inv:addContainer("main", c1)
        assert(inv:hasItem("coin", 5), "has 5 coins")
        assert(not inv:hasItem("coin", 6), "not 6")
    "#).exec().unwrap();
}

#[test]
fn inventory_remove_from_any() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory()
        local c = luna.inventory.newContainer("main")
        c:addItem(luna.inventory.newItem("grain"), 8)
        inv:addContainer("main", c)
        assert(inv:countItem("grain") == 8, "8 grain")
        local ok = inv:removeFromAny("grain", 5)
        assert(ok, "remove ok")
        assert(inv:countItem("grain") == 3, "3 left")
        local fail = inv:removeFromAny("grain", 10)
        assert(not fail, "cannot remove 10 from 3")
        assert(inv:countItem("grain") == 3, "still 3")
    "#).exec().unwrap();
}

// ── New features ─────────────────────────────────────────────────────────────

#[test]
fn inventory_item_resource_ref() {
    let lua = make_vm();
    lua.load(r#"
        local it = luna.inventory.newItem("sword")
        assert(it:getResourceRef() == nil, "nil by default")
        it:setResourceRef("sprites/sword.png")
        assert(it:getResourceRef() == "sprites/sword.png", "stores string")
        it:setResourceRef({ atlas = "items", frame = 7 })
        local ref = it:getResourceRef()
        assert(type(ref) == "table", "stores table")
        assert(ref.atlas == "items", "table field")
        assert(ref.frame == 7, "table field 2")
    "#).exec().unwrap();
}

#[test]
fn inventory_item_user_data() {
    let lua = make_vm();
    lua.load(r#"
        local it = luna.inventory.newItem("potion")
        assert(it:getUserData() == nil, "nil by default")
        it:setUserData({ heal = 50, cooldown = 3.0 })
        local ud = it:getUserData()
        assert(ud.heal == 50, "heal")
        assert(ud.cooldown == 3.0, "cooldown")
    "#).exec().unwrap();
}

#[test]
fn inventory_item_clone_preserves_type() {
    let lua = make_vm();
    lua.load(r#"
        local it = luna.inventory.newItem("axe")
        it:setWeight(5.0)
        local copy = it:clone()
        assert(copy:getType() == "axe", "type preserved")
        assert(copy:getWeight() == 5.0, "weight preserved")
        copy:setWeight(10.0)
        assert(it:getWeight() == 5.0, "original unchanged")
    "#).exec().unwrap();
}

#[test]
fn inventory_slot_get_item() {
    let lua = make_vm();
    lua.load(r#"
        local slot = luna.inventory.newSlot("any")
        assert(slot:getItem() == nil, "nil when empty")
        local it = luna.inventory.newItem("sword")
        it:setWeight(3.0)
        local stack = luna.inventory.newItemStack(it, 1, 1)
        slot:setStack(stack)
        local got = slot:getItem()
        assert(got ~= nil, "got item")
        assert(got:getType() == "sword", "correct type")
    "#).exec().unwrap();
}

#[test]
fn inventory_itemset_requirement_count() {
    let lua = make_vm();
    lua.load(r#"
        local set = luna.inventory.newItemSet("warrior")
        assert(set:getRequirementCount() == 0, "empty")
        set:addRequirement("heavy_armor", "chest")
        set:addRequirement("heavy_armor", "legs")
        assert(set:getRequirementCount() == 2, "two reqs")
    "#).exec().unwrap();
}

#[test]
fn inventory_itemset_is_active() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory()
        local slot = luna.inventory.newSlot("any", "active")
        inv:addEquipSlot("head", slot)

        local set = luna.inventory.newItemSet("plate")
        set:addRequirement("heavy", "head")

        -- not active yet
        assert(not set:isActive(inv), "not active before equip")

        -- equip an item with "heavy" tag
        local it = luna.inventory.newItem("helm")
        it:addTag("heavy")
        local stack = luna.inventory.newItemStack(it, 1, 1)
        inv:equip("head", stack)

        assert(set:isActive(inv), "active after equip")
    "#).exec().unwrap();
}

#[test]
fn inventory_itemset_bonus_ref() {
    let lua = make_vm();
    lua.load(r#"
        local set = luna.inventory.newItemSet("mage")
        assert(set:getBonusRef() == nil, "nil by default")
        set:setBonusRef({ spell_power = 10, mana_regen = 2 })
        local b = set:getBonusRef()
        assert(b.spell_power == 10, "bonus field")
        assert(b.mana_regen == 2, "bonus field 2")
    "#).exec().unwrap();
}

#[test]
fn inventory_split_stack() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory()
        local c = luna.inventory.newContainer("bag", "fixed", 5)
        local arrow = luna.inventory.newItem("arrow")
        arrow:setStackLimit(20)
        c:addItem(arrow, 20)
        inv:addContainer("bag", c)

        local ok = inv:splitStack("bag", 1, 5)
        assert(ok, "split succeeded")

        -- verify via getContainer
        local bag = inv:getContainer("bag")
        local s1 = bag:getSlot(1)
        local s2 = bag:getSlot(2)
        assert(not s1:isEmpty(), "slot 1 still has items")
        assert(not s2:isEmpty(), "slot 2 has split items")
    "#).exec().unwrap();
}

#[test]
fn inventory_merge_stacks() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory()
        local c = luna.inventory.newContainer("bag", "fixed", 5)
        -- stack_limit=10 so first addItem fills slot 0, second fills slot 1
        local coin = luna.inventory.newItem("coin")
        coin:setStackLimit(10)
        c:addItem(coin, 10)
        c:addItem(coin, 5)
        inv:addContainer("bag", c)

        -- merge slot 2 into slot 1
        local ok = inv:mergeStacks("bag", 2, 1)
        assert(ok, "merge succeeded")
    "#).exec().unwrap();
}

#[test]
fn inventory_get_item_sets() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory()
        local s1 = luna.inventory.newItemSet("warrior")
        local s2 = luna.inventory.newItemSet("mage")
        inv:addItemSet(s1)
        inv:addItemSet(s2)

        local sets = inv:getItemSets()
        assert(#sets == 2, "two sets returned")
        assert(sets[1]:getName() == "warrior", "first is warrior")
        assert(sets[2]:getName() == "mage", "second is mage")
    "#).exec().unwrap();
}

#[test]
fn inventory_callbacks() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory()
        local log = {}

        inv:setCallback("on_equip", function(slot, item)
            table.insert(log, "equip:" .. slot .. ":" .. item)
        end)

        inv:fireCallback("on_equip", "head", "helm")
        assert(#log == 1, "callback fired")
        assert(log[1] == "equip:head:helm", "args passed")

        -- overwrite callback
        inv:setCallback("on_equip", function() table.insert(log, "new") end)
        inv:fireCallback("on_equip")
        assert(log[2] == "new", "replaced callback")

        -- remove callback
        inv:removeCallback("on_equip")
        inv:fireCallback("on_equip")
        assert(#log == 2, "no-op after removal")
    "#).exec().unwrap();
}

#[test]
fn inventory_callback_fire_missing_event() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory()
        -- firing a non-existent callback should not error
        inv:fireCallback("on_magic")
    "#).exec().unwrap();
}

#[test]
fn inventory_split_stack_validates_index() {
    let lua = make_vm();
    let result = lua.load(r#"
        local inv = luna.inventory.newInventory()
        inv:splitStack("bag", 0, 5)
    "#).exec();
    assert!(result.is_err(), "slot index 0 should fail");
}
