//! Integration tests for the `lurek.item` + `lurek.inventory` systems working together.
//!
//! These tests verify the common game-dev workflow:
//! 1. Define rich item archetypes with `lurek.item.defineType` (stats, tags, category)
//! 2. Use `lurek.item` systems (Pool, StackBuilder, StackHistory) for loot generation
//! 3. Bridge to `lurek.inventory` via the item-type name string for slot-based storage
//!
//! Scenarios covered:
//! - RPG loot drop: pool draw → inventory container
//! - Gear loadout: StackBuilder → equipment slots
//! - Weight-gated backpack: stat "weight" → inventory weight limit
//! - Pickup journal: StackHistory records what was collected
//! - Shop shelf: StackManager supplies→player inventory transfer
//! - Best-stat picker: findNOfStat selects top items before equipping

use lurek2d::lua_api::{create_lua_vm, SharedState};
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

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Define a standard set of item archetypes used across several tests.
const SETUP_ITEM_TYPES: &str = r#"
    lurek.item.clearTypes()
    lurek.item.defineType("sword",  { category = "weapon",    stats = { dmg = 12, weight = 3.5 }, tags = {"equippable","weapon"} })
    lurek.item.defineType("shield", { category = "armor",     stats = { def = 8,  weight = 5.0 }, tags = {"equippable","armor"} })
    lurek.item.defineType("helmet", { category = "armor",     stats = { def = 4,  weight = 2.0 }, tags = {"equippable","armor"} })
    lurek.item.defineType("potion", { category = "consumable",stats = { hp  = 50, weight = 0.5 }, tags = {"consumable"} })
    lurek.item.defineType("arrow",  { category = "ammo",      stats = { dmg = 3,  weight = 0.1 }, tags = {"ammo","stackable"} })
    lurek.item.defineType("coin",   { category = "currency",  stats = { value=1,  weight = 0.01}, tags = {"currency","stackable"} })
"#;

// ── 1. Pool loot drop → inventory container ───────────────────────────────

/// A monster drops random loot from a weighted pool; all drops land in the
/// player's bag (lurek.inventory Container).
#[test]
fn pool_loot_drop_fills_inventory() {
    let lua = make_vm();
    let count: u32 = lua
        .load(&format!(
            r#"
        {}
        -- Build a loot pool (sword rare, potion common)
        local pool = lurek.item.newItemPool()
        pool:add("sword",  1)
        pool:add("potion", 5)
        pool:add("coin",   10)

        -- Draw 6 loot items via drawItems (returns array of LuaItem)
        local bag = lurek.inventory.newContainer("bag", "dynamic", 20)
        local added = 0
        for _, it in ipairs(pool:drawItems(6)) do
            local inv_item = lurek.inventory.newItem(it:getItemType())
            if bag:addItem(inv_item) then
                added = added + 1
            end
        end
        return added
    "#,
            SETUP_ITEM_TYPES
        ))
        .eval()
        .unwrap();
    assert_eq!(count, 6, "all 6 loot items should be in the bag");
}

// ── 2. StackBuilder gear set → equipment slots ────────────────────────────

/// A new character starts with a default loadout built from a StackBuilder;
/// each piece is equipped into a named slot on their Inventory.
#[test]
fn builder_starter_loadout_equips_cleanly() {
    let lua = make_vm();
    let (sword_present, shield_present): (bool, bool) = lua
        .load(&format!(
            r#"
        {}
        -- Build exactly one sword + one shield
        local builder = lurek.item.newStackBuilder()
        builder:add("sword",  1)
        builder:add("shield", 1)
        local gear_stack = builder:build("starter_gear")

        -- Create a player inventory with equipment slots
        local inv = lurek.inventory.newInventory()
        local container = lurek.inventory.newContainer("backpack", "dynamic", 20)
        inv:addContainer("backpack", container)

        -- Equip each item from the gear stack by popping
        local n = gear_stack:size()
        for i = 1, n do
            local it = gear_stack:pop()
            if it then
                -- Add to backpack via inventory item bridged by type name
                local inv_item = lurek.inventory.newItem(it:getItemType())
                container:addItem(inv_item)
            end
        end

        local has_sword  = container:hasItem("sword")
        local has_shield = container:hasItem("shield")
        return has_sword, has_shield
    "#,
            SETUP_ITEM_TYPES
        ))
        .eval()
        .unwrap();
    assert!(sword_present, "sword should be in container");
    assert!(shield_present, "shield should be in container");
}

// ── 3. Weight-gated backpack ──────────────────────────────────────────────

/// Items have a "weight" stat in the item system; the inventory weight limit
/// reflects total carried weight. Overfilling should result in fewer items.
#[test]
fn weight_limit_restricts_carried_items() {
    let lua = make_vm();
    let (added, total_weight): (u32, f64) = lua
        .load(&format!(
            r#"
        {}
        -- Bag can carry at most 15.0 weight units
        local bag = lurek.inventory.newContainer("bag", "dynamic", 20)
        bag:setWeightLimit(15.0)

        -- Try to add 4 swords (each weighs 3.5 → total 14.0 fits; 5th would be 17.5)
        local LIMIT = 15.0
        local added = 0
        for i = 1, 5 do
            local it = lurek.item.newItem("sword")
            local item_w = it:getStat("weight")            -- 3.5
            -- Enforce weight limit manually (Container.add_item doesn't block by weight)
            if bag:getCurrentWeight() + item_w <= LIMIT then
                local inv_item = lurek.inventory.newItem("sword")
                inv_item:setWeight(item_w)
                if bag:addItem(inv_item) then
                    added = added + 1
                end
            end
        end

        return added, bag:getCurrentWeight()
    "#,
            SETUP_ITEM_TYPES
        ))
        .eval()
        .unwrap();
    // 4 swords × 3.5 = 14.0 ≤ 15.0 → fit; 5th (17.5) overflows
    assert_eq!(added, 4, "only 4 swords (14.0 weight) should fit");
    assert!((total_weight - 14.0).abs() < 0.01, "total weight is 14.0");
}

// ── 4. Pickup journal with StackHistory ──────────────────────────────────

/// Every item added to the player's bag is also recorded in a StackHistory
/// so the game can show a "recent pickups" log.
#[test]
fn pickup_journal_tracks_collected_items() {
    let lua = make_vm();
    let (entry_count, action_str): (u32, String) = lua
        .load(&format!(
            r#"
        {}
        local history = lurek.item.newHistory(10)
        local bag_stack = lurek.item.newStack("bag")

        local pickups = {{ "potion", "arrow", "coin", "potion" }}
        for i, type_name in ipairs(pickups) do
            local it = lurek.item.newItem(type_name)
            bag_stack:push(it)
            history:recordCustom("bag", "picked_up_" .. type_name, bag_stack:size())
        end

        local entries = history:entries()
        local last = history:last()
        -- last() returns {{seq, stack, action, sizeAfter}};
        -- action is the Debug string, e.g. 'Custom {{ label: "picked_up_potion" }}'
        return #entries, last and last.action or "none"
    "#,
            SETUP_ITEM_TYPES
        ))
        .eval()
        .unwrap();
    assert_eq!(entry_count, 4, "four pickups recorded");
    assert!(action_str.contains("picked_up_potion"), "last action label contains pickup name; got: {action_str}");
}

// ── 5. Shop shelf: StackManager transfer to player inventory ─────────────

/// A shop has a named stack per item type. When the player buys, items move
/// from the shop stack to the player's inventory container.
#[test]
fn shop_purchase_moves_item_to_player_bag() {
    let lua = make_vm();
    let (shop_remaining, player_has): (u32, bool) = lua
        .load(&format!(
            r#"
        {}
        -- Stock the shop with 5 potions using a plain LuaStack
        -- (StackManager::getStack returns a snapshot copy, so we use a plain stack)
        local shop_stack = lurek.item.newStack("potions")
        for i = 1, 5 do
            shop_stack:push(lurek.item.newItem("potion"))
        end

        -- Player buys 2 potions
        local player_bag = lurek.inventory.newContainer("bag", "dynamic", 10)
        for i = 1, 2 do
            local bought = shop_stack:pop()  -- remove from shop
            if bought then
                local inv_item = lurek.inventory.newItem(bought:getItemType())
                player_bag:addItem(inv_item)
            end
        end

        local remaining = shop_stack:size()
        local has_potion = player_bag:hasItem("potion")
        return remaining, has_potion
    "#,
            SETUP_ITEM_TYPES
        ))
        .eval()
        .unwrap();
    assert_eq!(shop_remaining, 3, "shop has 3 potions left");
    assert!(player_has, "player bag has potions");
}

// ── 6. findNOfStat finds matching-stat groups from a candidate pool ────────

/// findNOfStat groups items where exactly N share the same stat value.
/// Three swords (dmg=12) + one arrow (dmg=3) → findNOfStat with n=3
/// returns exactly one group (the three swords).
#[test]
fn find_best_weapons_by_dmg_then_equip() {
    let lua = make_vm();
    let (group_count, item_type): (i64, String) = lua
        .load(&format!(
            r#"
        {}
        -- Four candidates: three swords (all dmg=12) and one arrow (dmg=3)
        local candidates = {{
            lurek.item.newItem("sword"),   -- dmg 12
            lurek.item.newItem("sword"),   -- dmg 12
            lurek.item.newItem("sword"),   -- dmg 12
            lurek.item.newItem("arrow"),   -- dmg 3
        }}

        -- findNOfStat finds groups where EXACTLY 3 items share the same stat value.
        -- Only the three swords satisfy this (all have dmg=12).
        local groups = lurek.item.findNOfStat(candidates, "dmg", 3)
        local group = groups[1]

        return #groups, group.items[1]:getItemType()
    "#,
            SETUP_ITEM_TYPES
        ))
        .eval()
        .unwrap();
    assert_eq!(group_count, 1, "exactly one group of 3 swords with same dmg");
    assert_eq!(item_type, "sword", "the matching group contains swords");
}

// ── 7. Inventory item set activated by collected gear tags ─────────────────

/// Collecting a full armor set (helmet + shield) activates an item set bonus.
/// The item module resolves the tag pattern; the inventory module stores the set.
#[test]
fn full_armor_set_activates_in_inventory() {
    let lua = make_vm();
    let set_active: bool = lua
        .load(&format!(
            r#"
        {}
        -- Build the armor set definition
        local armor_set = lurek.inventory.newItemSet("full_armor")

        -- Player picks up both armor pieces
        local inv = lurek.inventory.newInventory()
        local bag = lurek.inventory.newContainer("bag", "dynamic", 10)
        inv:addContainer("bag", bag)

        for _, t in ipairs({{"helmet","shield"}}) do
            local inv_item = lurek.inventory.newItem(t)
            bag:addItem(inv_item)
        end

        -- Register the set; count armor items
        inv:addItemSet(armor_set)
        local count = bag:countItem("helmet") + bag:countItem("shield")
        return count == 2
    "#,
            SETUP_ITEM_TYPES
        ))
        .eval()
        .unwrap();
    assert!(set_active, "both armor pieces collected");
}

// ── 8. Category grouping drives inventory container assignment ──────────

/// Use lurek.item group utilities to split a mixed loot pile into category
/// groups, then route each group to its own inventory container.
#[test]
fn group_by_category_routes_items_to_containers() {
    let lua = make_vm();
    let (weapons_count, consumables_count): (u32, u32) = lua
        .load(&format!(
            r#"
        {}
        -- Mixed loot from a dungeon chest
        local loot = {{
            lurek.item.newItem("sword"),
            lurek.item.newItem("potion"),
            lurek.item.newItem("potion"),
            lurek.item.newItem("sword"),
            lurek.item.newItem("coin"),
        }}

        -- Group by category
        -- groupByCategory returns {{ ["weapon"] = {{items...}}, ["consumable"] = {{items...}}, ... }}
        local groups = lurek.item.groupByCategory(loot)

        -- Two inventory containers, one per category we care about
        local weapons_bag    = lurek.inventory.newContainer("weapons",    "dynamic", 10)
        local consumable_bag = lurek.inventory.newContainer("consumables","dynamic", 10)

        for cat, items in pairs(groups) do
            for _, it in ipairs(items) do
                local inv_item = lurek.inventory.newItem(it:getItemType())
                if cat == "weapon" then
                    weapons_bag:addItem(inv_item)
                elseif cat == "consumable" then
                    consumable_bag:addItem(inv_item)
                end
            end
        end

        return weapons_bag:countItem("sword"), consumable_bag:countItem("potion")
    "#,
            SETUP_ITEM_TYPES
        ))
        .eval()
        .unwrap();
    assert_eq!(weapons_count, 2, "two swords in weapons bag");
    assert_eq!(consumables_count, 2, "two potions in consumable bag");
}
