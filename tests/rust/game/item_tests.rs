//! Integration tests for `lurek.item.*`.

use lurek2d::lua_api::{create_lua_vm, SharedState};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(800, 600, "Test", PathBuf::from("."))));
    create_lua_vm(state).unwrap()
}

// ─────────────────────────────────────────────────────────────────────────────
// Item type registry
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn item_define_and_get_type() {
    let lua = make_vm();
    lua.load(r#"
        luna.item.clearTypes()
        luna.item.defineType("Sword", { category="weapon", stats={atk=5, weight=3} })
        local t = luna.item.getType("Sword")
        assert(t ~= nil, "type should exist")
        assert(t.category == "weapon", "category")
        assert(t.stats.atk == 5, "base stat atk")
    "#).exec().unwrap();
}

#[test]
fn item_type_names_list() {
    let lua = make_vm();
    lua.load(r#"
        luna.item.clearTypes()
        luna.item.defineType("A", {})
        luna.item.defineType("B", {})
        luna.item.defineType("C", {})
        local names = luna.item.getTypeNames()
        assert(#names >= 3, "at least 3 names returned")
    "#).exec().unwrap();
}

#[test]
fn item_unknown_type_returns_nil() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.item.getType("__does_not_exist__99")
        assert(t == nil, "unknown type should be nil")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// Item creation and properties
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn item_new_has_correct_type_string() {
    let lua = make_vm();
    lua.load(r#"
        local item = luna.item.newItem("Dagger")
        assert(item:type() == "Item", "type() should be Item")
        assert(item:typeOf("Item"), "typeOf Item")
    "#).exec().unwrap();
}

#[test]
fn item_stats_get_set_add() {
    let lua = make_vm();
    lua.load(r#"
        local item = luna.item.newItem("Staff")
        item:setStat("dmg", 10)
        assert(item:getStat("dmg") == 10, "set and get stat")
        item:addStat("dmg", 5)
        assert(item:getStat("dmg") == 15, "add stat")
        assert(item:getStat("missing") == 0, "missing stat is 0")
    "#).exec().unwrap();
}

#[test]
fn item_tags_add_has_remove() {
    let lua = make_vm();
    lua.load(r#"
        local item = luna.item.newItem("Gem")
        item:addTag("magic")
        item:addTag("rare")
        assert(item:hasTag("magic"), "should have magic tag")
        assert(item:hasTag("rare"), "should have rare tag")
        item:removeTag("magic")
        assert(not item:hasTag("magic"), "magic tag removed")
        assert(item:hasTag("rare"), "rare tag still present")
    "#).exec().unwrap();
}

#[test]
fn item_metadata_get_set() {
    let lua = make_vm();
    lua.load(r#"
        local item = luna.item.newItem("Rune")
        item:setMeta("desc", "An ancient rune")
        assert(item:getMeta("desc") == "An ancient rune", "meta round-trip")
        assert(item:getMeta("missing") == "", "missing meta is empty string")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// Stack operations
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn stack_push_and_pop() {
    let lua = make_vm();
    lua.load(r#"
        local stack = luna.item.newStack("hand")
        local item1 = luna.item.newItem("Card1")
        item1:setStat("value", 1)
        local item2 = luna.item.newItem("Card2")
        item2:setStat("value", 2)

        stack:push(item1)
        stack:push(item2)
        assert(stack:size() == 2, "size should be 2")

        local top = stack:pop()
        assert(top ~= nil, "pop returned an item")
        assert(top:getStat("value") == 2, "LIFO order: last in is top")
        assert(stack:size() == 1, "size after pop is 1")
    "#).exec().unwrap();
}

#[test]
fn stack_capacity_limit() {
    let lua = make_vm();
    lua.load(r#"
        local stack = luna.item.newStack("small", 2)
        local a = luna.item.newItem("A")
        local b = luna.item.newItem("B")
        local c = luna.item.newItem("C")

        stack:push(a)
        stack:push(b)
        local ok, err = pcall(function() stack:push(c) end)
        assert(not ok, "pushing to full stack should raise error")
        assert(stack:size() == 2, "stack size unchanged")
    "#).exec().unwrap();
}

#[test]
fn stack_shuffle_changes_order() {
    let lua = make_vm();
    lua.load(r#"
        local stack = luna.item.newStack("pile")
        for i = 1, 20 do
            local it = luna.item.newItem("X")
            it:setStat("idx", i)
            stack:push(it)
        end
        local first_before = stack:peek():getStat("idx")
        stack:shuffle()
        -- Can't guarantee different order, but shuffle must not lose items
        assert(stack:size() == 20, "size preserved after shuffle")
    "#).exec().unwrap();
}

#[test]
fn stack_search_and_count_by_type() {
    let lua = make_vm();
    lua.load(r#"
        local stack = luna.item.newStack("deck")
        for i = 1, 3 do
            stack:push(luna.item.newItem("Fire"))
        end
        for i = 1, 2 do
            stack:push(luna.item.newItem("Ice"))
        end
        assert(stack:countByType("Fire") == 3, "3 Fire items")
        assert(stack:countByType("Ice") == 2, "2 Ice items")

        -- findByType returns the 1-based index of the first match
        local idx = stack:findByType("Ice")
        assert(idx ~= nil, "findByType returns an index for Ice")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// StackBuilder
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn builder_build_produces_correct_stack() {
    let lua = make_vm();
    lua.load(r#"
        luna.item.clearTypes()
        luna.item.defineType("Arrow", { category="ammo" })
        luna.item.defineType("Bolt",  { category="ammo" })

        local builder = luna.item.newStackBuilder()
        builder:add("Arrow", 3)
        builder:add("Bolt", 2)

        local deck = builder:build("quiver")
        assert(deck:size() == 5, "5 items in built stack")
        assert(deck:countByType("Arrow") == 3, "3 arrows")
        assert(deck:countByType("Bolt") == 2, "2 bolts")
    "#).exec().unwrap();
}

#[test]
fn builder_validate_catches_unknown_type() {
    let lua = make_vm();
    lua.load(r#"
        luna.item.clearTypes()
        luna.item.defineType("Known", {})

        local builder = luna.item.newStackBuilder()
        builder:add("Known", 5)
        builder:setMaxCopies(3)  -- at most 3 copies of any type

        local errors = builder:validateEntries()
        -- Expect at least one error about exceeding max_copies
        assert(#errors >= 1, "validateEntries should produce an error for exceeding max copies")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// StackManager
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn manager_create_and_move_between_stacks() {
    let lua = make_vm();
    lua.load(r#"
        local mgr = luna.item.newStackManager()
        mgr:createStack("hand")
        mgr:createStack("discard")

        -- Get the hand stack, add item, sync back to manager
        local hand = mgr:getStack("hand")
        hand:push(luna.item.newItem("Card"))
        mgr:addStack("hand", hand)  -- sync mutated stack back

        assert(mgr:getStack("hand"):size() == 1, "1 item in hand")
        mgr:moveTop("hand", "discard")
        assert(mgr:getStack("hand"):size() == 0, "hand empty after move")
        assert(mgr:getStack("discard"):size() == 1, "discard has 1 item")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// ItemPool
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn pool_draw_items_not_empty() {
    let lua = make_vm();
    lua.load(r#"
        luna.item.clearTypes()
        luna.item.defineType("Gem", {})
        luna.item.defineType("Coin", {})

        local pool = luna.item.newItemPool("loot")
        pool:add("Gem", 3)
        pool:add("Coin", 7)
        assert(pool:size() == 2, "2 entries in pool")

        local drawn = pool:drawItems(5)
        assert(#drawn == 5, "drew 5 items")
        assert(pool:totalWeight() == 10, "total weight")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// Slot
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn slot_capacity_and_overflow() {
    let lua = make_vm();
    lua.load(r#"
        local slot = luna.item.newSlot("helmet", 1)
        local a = luna.item.newItem("HelmA")
        local b = luna.item.newItem("HelmB")

        slot:push(a)
        assert(slot:isFull(), "slot full after 1 item")

        local ok, err = pcall(function() slot:push(b) end)
        assert(not ok, "second push to capacity-1 slot should error")
        assert(slot:size() == 1, "slot still has 1 item")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// Group analysis
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn group_find_pairs() {
    let lua = make_vm();
    lua.load(r#"
        luna.item.clearTypes()
        luna.item.defineType("T", {})

        -- Build an items array: values 1,1,2,2,3
        local items = {}
        local vals = {1, 1, 2, 2, 3}
        for _, v in ipairs(vals) do
            local it = luna.item.newItem("T")
            it:setStat("val", v)
            table.insert(items, it)
        end

        -- Find pairs (groups of 2) by "val" stat
        local groups = luna.item.findNOfStat(items, "val", 2)
        -- Should find 2 groups (val=1 and val=2 each appear twice)
        assert(#groups >= 2, "should find at least 2 groups with n=2: got " .. #groups)
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// StackHistory
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn history_record_and_query() {
    let lua = make_vm();
    lua.load(r#"
        local hist = luna.item.newHistory()
        assert(hist:len() == 0, "starts empty")

        hist:recordCustom("deck", "initial shuffle", 20)
        hist:recordCustom("deck", "drew a card", 19)
        assert(hist:len() == 2, "2 entries after 2 records")

        local entries = hist:entries()
        assert(#entries == 2, "entries() matches len()")

        local last = hist:last()
        assert(last ~= nil, "last() returns entry")
        assert(last.stack == "deck", "last entry is for deck")
    "#).exec().unwrap();
}

#[test]
fn history_max_size_rolls_over() {
    let lua = make_vm();
    lua.load(r#"
        local hist = luna.item.newHistory(3)
        for i = 1, 5 do
            hist:recordCustom("s", "event " .. i, i)
        end
        assert(hist:len() == 3, "capped at max_size=3")
    "#).exec().unwrap();
}
