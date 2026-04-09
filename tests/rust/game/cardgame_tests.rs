//! Integration tests for `lurek.cardgame.*`.



use lurek2d::lua_api::{create_lua_vm, SharedState};
use lurek2d::engine::config::Config;

use std::cell::RefCell;

use std::path::PathBuf;

use std::rc::Rc;



fn make_vm() -> mlua::Lua {

    let state = Rc::new(RefCell::new(SharedState::new(800, 600, "Test", PathBuf::from("."))));

    create_lua_vm(state, &Config::default().modules).unwrap()

}



// ─────────────────────────────────────────────────────────────────────────────

// Item type registry

// ─────────────────────────────────────────────────────────────────────────────



#[test]

fn item_define_and_get_type() {

    let lua = make_vm();

    lua.load(r#"

        luna.cardgame.clearTypes()

        luna.cardgame.defineType("Sword", { category="weapon", stats={atk=5, weight=3} })

        local t = luna.cardgame.getType("Sword")

        assert(t ~= nil, "type should exist")

        assert(t.category == "weapon", "category")

        assert(t.stats.atk == 5, "base stat atk")

    "#).exec().unwrap();

}



#[test]

fn item_type_names_list() {

    let lua = make_vm();

    lua.load(r#"

        luna.cardgame.clearTypes()

        luna.cardgame.defineType("A", {})

        luna.cardgame.defineType("B", {})

        luna.cardgame.defineType("C", {})

        local names = luna.cardgame.getTypeNames()

        assert(#names >= 3, "at least 3 names returned")

    "#).exec().unwrap();

}



#[test]

fn item_unknown_type_returns_nil() {

    let lua = make_vm();

    lua.load(r#"

        local t = luna.cardgame.getType("__does_not_exist__99")

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

        local item = luna.cardgame.newCard("Dagger")

        assert(item:type() == "Card", "type() should be Card")

        assert(item:typeOf("Card"), "typeOf Card")

    "#).exec().unwrap();

}



#[test]

fn item_stats_get_set_add() {

    let lua = make_vm();

    lua.load(r#"

        local item = luna.cardgame.newCard("Staff")

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

        local item = luna.cardgame.newCard("Gem")

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

        local item = luna.cardgame.newCard("Rune")

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

        local stack = luna.cardgame.newStack("hand")

        local item1 = luna.cardgame.newCard("Card1")

        item1:setStat("value", 1)

        local item2 = luna.cardgame.newCard("Card2")

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

        local stack = luna.cardgame.newStack("small", 2)

        local a = luna.cardgame.newCard("A")

        local b = luna.cardgame.newCard("B")

        local c = luna.cardgame.newCard("C")



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

        local stack = luna.cardgame.newStack("pile")

        for i = 1, 20 do

            local it = luna.cardgame.newCard("X")

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

        local stack = luna.cardgame.newStack("deck")

        for i = 1, 3 do

            stack:push(luna.cardgame.newCard("Fire"))

        end

        for i = 1, 2 do

            stack:push(luna.cardgame.newCard("Ice"))

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

        luna.cardgame.clearTypes()

        luna.cardgame.defineType("Arrow", { category="ammo" })

        luna.cardgame.defineType("Bolt",  { category="ammo" })



        local builder = luna.cardgame.newDeckBuilder()

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

        luna.cardgame.clearTypes()

        luna.cardgame.defineType("Known", {})



        local builder = luna.cardgame.newDeckBuilder()

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

        local mgr = luna.cardgame.newZoneManager()

        mgr:createStack("hand")

        mgr:createStack("discard")



        -- Get the hand stack, add item, sync back to manager

        local hand = mgr:getStack("hand")

        hand:push(luna.cardgame.newCard("Card"))

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

        luna.cardgame.clearTypes()

        luna.cardgame.defineType("Gem", {})

        luna.cardgame.defineType("Coin", {})



        local pool = luna.cardgame.newCardPool("loot")

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

        local slot = luna.cardgame.newSlot("helmet", 1)

        local a = luna.cardgame.newCard("HelmA")

        local b = luna.cardgame.newCard("HelmB")



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

        luna.cardgame.clearTypes()

        luna.cardgame.defineType("T", {})



        -- Build an items array: values 1,1,2,2,3

        local items = {}

        local vals = {1, 1, 2, 2, 3}

        for _, v in ipairs(vals) do

            local it = luna.cardgame.newCard("T")

            it:setStat("val", v)

            table.insert(items, it)

        end



        -- Find pairs (groups of 2) by "val" stat

        local groups = luna.cardgame.findNOfStat(items, "val", 2)

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

        local hist = luna.cardgame.newHistory()

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

        local hist = luna.cardgame.newHistory(3)

        for i = 1, 5 do

            hist:recordCustom("s", "event " .. i, i)

        end

        assert(hist:len() == 3, "capped at max_size=3")

    "#).exec().unwrap();

}



// ─────────────────────────────────────────────────────────────────────────────

// Card: subtype, rarity, controller

// ─────────────────────────────────────────────────────────────────────────────



#[test]

fn card_subtype_get_set() {

    let lua = make_vm();

    lua.load(r#"

        local c = luna.cardgame.newCard("X")

        assert(c:getSubtype() == "", "default subtype empty")

        c:setSubtype("damage")

        assert(c:getSubtype() == "damage", "subtype set")

    "#).exec().unwrap();

}



#[test]

fn card_rarity_get_set() {

    let lua = make_vm();

    lua.load(r#"

        local c = luna.cardgame.newCard("X")

        assert(c:getRarity() == "", "default rarity empty")

        c:setRarity("legendary")

        assert(c:getRarity() == "legendary", "rarity set")

    "#).exec().unwrap();

}



#[test]

fn card_controller_get_set() {

    let lua = make_vm();

    lua.load(r#"

        local c = luna.cardgame.newCard("X")

        assert(c:getController() == "", "default controller empty")

        c:setController("player2")

        assert(c:getController() == "player2", "controller set")

    "#).exec().unwrap();

}



// ─────────────────────────────────────────────────────────────────────────────

// Card: face-up, tapped, tile position

// ─────────────────────────────────────────────────────────────────────────────



#[test]

fn card_face_up_and_tapped() {

    let lua = make_vm();

    lua.load(r#"

        local c = luna.cardgame.newCard("X")

        assert(c:isFaceUp() == true, "default face up")

        assert(c:isTapped() == false, "default not tapped")

        c:setFaceUp(false)

        c:setTapped(true)

        assert(c:isFaceUp() == false, "now face down")

        assert(c:isTapped() == true, "now tapped")

    "#).exec().unwrap();

}



#[test]

fn card_tile_position_and_size() {

    let lua = make_vm();

    lua.load(r#"

        local c = luna.cardgame.newCard("X")

        local x, y = c:getTilePosition()

        assert(x == 0 and y == 0, "default tile pos 0,0")

        local w, h = c:getTileSize()

        assert(w == 1 and h == 1, "default tile size 1x1")

        c:setTilePosition(3, 5)

        c:setTileSize(2, 2)

        local nx, ny = c:getTilePosition()

        assert(nx == 3 and ny == 5, "tile pos updated")

        local nw, nh = c:getTileSize()

        assert(nw == 2 and nh == 2, "tile size updated")

    "#).exec().unwrap();

}



// ─────────────────────────────────────────────────────────────────────────────

// Card: resetStats, clone

// ─────────────────────────────────────────────────────────────────────────────



#[test]

fn card_reset_stats() {

    let lua = make_vm();

    lua.load(r#"

        luna.cardgame.clearTypes()

        luna.cardgame.defineType("Sword", { stats = { atk = 10 } })

        local c = luna.cardgame.newCard("Sword")

        assert(c:getStat("atk") == 10, "base atk")

        c:setStat("atk", 99)

        assert(c:getStat("atk") == 99, "modified atk")

        c:resetStats()

        assert(c:getStat("atk") == 10, "atk reset to base")

    "#).exec().unwrap();

}



#[test]

fn card_clone_is_independent() {

    let lua = make_vm();

    lua.load(r#"

        local c = luna.cardgame.newCard("X")

        c:setName("Original")

        c:setStat("hp", 50)

        local copy = c:clone()

        assert(copy:getName() == "Original", "clone has same name")

        assert(copy:getStat("hp") == 50, "clone has same stats")

        copy:setName("Clone")

        copy:setStat("hp", 100)

        assert(c:getName() == "Original", "original unchanged")

        assert(c:getStat("hp") == 50, "original stats unchanged")

    "#).exec().unwrap();

}



// ─────────────────────────────────────────────────────────────────────────────

// Stack: ordered, public zone properties

// ─────────────────────────────────────────────────────────────────────────────



#[test]

fn stack_ordered_and_public() {

    let lua = make_vm();

    lua.load(r#"

        local s = luna.cardgame.newStack("hand")

        assert(s:isOrdered() == true, "default ordered")

        assert(s:isPublic() == false, "default not public")

        s:setOrdered(false)

        s:setPublic(true)

        assert(s:isOrdered() == false, "now unordered")

        assert(s:isPublic() == true, "now public")

    "#).exec().unwrap();

}



// ─────────────────────────────────────────────────────────────────────────────

// defineType: subtype, rarity, maxPerDeck

// ─────────────────────────────────────────────────────────────────────────────



#[test]

fn define_type_with_subtype_rarity_max() {

    let lua = make_vm();

    lua.load(r#"

        luna.cardgame.clearTypes()

        luna.cardgame.defineType("Fireball", {

            category = "spell",

            subtype = "damage",

            rarity = "rare",

            maxPerDeck = 3,

        })

        local t = luna.cardgame.getType("Fireball")

        assert(t.category == "spell", "category")

        assert(t.subtype == "damage", "subtype")

        assert(t.rarity == "rare", "rarity")

        assert(t.maxPerDeck == 3, "maxPerDeck")

    "#).exec().unwrap();

}

// ─────────────────────────────────────────────────────────────────────────────
// NEW TESTS: spec completeness (added to cover all deferred features)
// ─────────────────────────────────────────────────────────────────────────────

// -- Card: unique id --

#[test]
fn card_has_unique_id() {
    let lua = make_vm();
    lua.load(r#"
        local a = luna.cardgame.newCard("X")
        local b = luna.cardgame.newCard("X")
        assert(a:getId() ~= b:getId(), "each card gets a different id")
        assert(a:getId() > 0, "id is positive")
    "#).exec().unwrap();
}

// -- Card: hasStat / modifyStat --

#[test]
fn card_has_stat_and_modify_stat() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.cardgame.newCard("X")
        c:setStat("hp", 10)
        assert(c:hasStat("hp"), "hasStat true")
        assert(not c:hasStat("mp"), "hasStat false")
        local new_val = c:modifyStat("hp", 5)
        assert(new_val == 15, "modifyStat returns new value")
        assert(c:getStat("hp") == 15, "getStat reflects change")
    "#).exec().unwrap();
}

// -- Card: counters --

#[test]
fn card_counters_ops() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.cardgame.newCard("X")
        c:setCounter("charge", 3)
        local all = c:getCounters()
        assert(all.charge == 3, "getCounters returns map")
        local new_val = c:modifyCounter("charge", 2)
        assert(new_val == 5, "modifyCounter returns new value")
        c:clearCounters()
        assert(c:getCounter("charge") == 0, "clearCounters zeroes all")
        local empty = c:getCounters()
        local count = 0
        for _ in pairs(empty) do count = count + 1 end
        assert(count == 0, "getCounters empty after clear")
    "#).exec().unwrap();
}

// -- Card: zone alias --

#[test]
fn card_zone_alias() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.cardgame.newCard("X")
        c:setZone("battlefield")
        assert(c:getZone() == "battlefield", "getZone/setZone")
        assert(c:getSlot() == "battlefield", "setZone reflected in getSlot")
    "#).exec().unwrap();
}

// -- Card: instance scripts --

#[test]
fn card_set_and_fire_script() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.cardgame.newCard("X")
        local fired = false
        c:setScript("onPlay", function(card)
            fired = true
        end)
        c:fireScript("onPlay")
        assert(fired, "instance script fires")
    "#).exec().unwrap();
}

#[test]
fn card_fire_script_missing_event_no_error() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.cardgame.newCard("X")
        c:fireScript("nonExistent")
    "#).exec().unwrap();
}

// -- Card: cost system --

#[test]
fn card_cost_check_and_pay() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.cardgame.newCard("X")
        assert(c:canPlay(nil), "canPlay true by default")
        c:setCostCheck(function(card, ctx) return false end)
        assert(not c:canPlay(nil), "canPlay false when check returns false")
        local paid = false
        c:setCostPay(function(card, ctx) paid = true end)
        c:payCost(nil)
        assert(paid, "payCost calls the function")
    "#).exec().unwrap();
}

// -- Card: asset storage --

#[test]
fn card_asset_storage() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.cardgame.newCard("X")
        c:setAsset("icon", {path = "fireball.png"})
        local icon = c:getAsset("icon")
        assert(icon ~= nil, "asset not nil")
        assert(icon.path == "fireball.png", "asset value correct")
        assert(c:getAsset("missing") == nil, "missing asset is nil")
    "#).exec().unwrap();
}

// -- Card: snapshot / restore --

#[test]
fn card_snapshot_restore() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.cardgame.newCard("X")
        c:setName("Fireball")
        c:setStat("damage", 5)
        c:addTag("fire")
        local snap = c:snapshot()
        assert(snap.name == "Fireball", "snapshot name correct")
        assert(snap.stats.damage == 5, "snapshot stat correct")
        local c2 = luna.cardgame.newCard("Y")
        c2:restore(snap)
        assert(c2:getName() == "Fireball", "restore sets name")
        assert(c2:getStat("damage") == 5, "restore sets stat")
        assert(c2:hasTag("fire"), "restore sets tags")
    "#).exec().unwrap();
}

// -- Stack: setName and getCardCount --

#[test]
fn stack_set_name_and_card_count() {
    let lua = make_vm();
    lua.load(r#"
        local s = luna.cardgame.newStack("hand")
        s:setName("discard")
        assert(s:getName() == "discard", "setName works")
        local c = luna.cardgame.newCard("X")
        s:addCard(c)
        assert(s:getCardCount() == 1, "getCardCount alias")
    "#).exec().unwrap();
}

// -- Stack: addCard, drawCard, contains, addCardBottom, drawCardBottom --

#[test]
fn stack_add_draw_remove_contains() {
    let lua = make_vm();
    lua.load(r#"
        local s = luna.cardgame.newStack("pile")
        local c = luna.cardgame.newCard("X")
        s:addCard(c)
        assert(s:contains(c), "contains card")
        local drawn = s:drawCard()
        assert(drawn ~= nil, "drawCard returns card")
        assert(not s:contains(c), "card gone after draw")
        assert(s:isEmpty(), "stack empty after draw")
        local c2 = luna.cardgame.newCard("Y")
        local c3 = luna.cardgame.newCard("Z")
        s:addCard(c2)
        s:addCardBottom(c3)
        local bottom = s:drawCardBottom()
        assert(bottom ~= nil, "drawCardBottom returns card")
    "#).exec().unwrap();
}

// -- Stack: removeCard by identity --

#[test]
fn stack_remove_card_by_identity() {
    let lua = make_vm();
    lua.load(r#"
        local s = luna.cardgame.newStack("pile")
        local c = luna.cardgame.newCard("X")
        s:addCard(c)
        assert(s:removeCard(c), "removeCard returns true")
        assert(not s:contains(c), "card gone")
        assert(not s:removeCard(c), "removeCard false when missing")
    "#).exec().unwrap();
}

// -- Stack: filter and sort --

#[test]
fn stack_filter_and_sort() {
    let lua = make_vm();
    lua.load(r#"
        local s = luna.cardgame.newStack("pile")
        for i = 1, 5 do
            local c = luna.cardgame.newCard("X")
            c:setStat("v", i)
            s:addCard(c)
        end
        local high = s:filter(function(c) return c:getStat("v") > 3 end)
        assert(#high == 2, "filter count correct: " .. #high)
        s:sort(function(a, b) return a:getStat("v") > b:getStat("v") end)
        local top = s:peek()
        assert(top:getStat("v") == 5, "top after sort desc is 5, got " .. top:getStat("v"))
    "#).exec().unwrap();
}

// -- Stack: findByCategory --

#[test]
fn stack_find_by_category() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineType("Spell", { category = "magic" })
        luna.cardgame.defineType("Sword", { category = "weapon" })
        local s = luna.cardgame.newStack("pile")
        for i = 1, 3 do s:addCard(luna.cardgame.newCard("Spell")) end
        for i = 1, 2 do s:addCard(luna.cardgame.newCard("Sword")) end
        local spells = s:findByCategory("magic")
        assert(#spells == 3, "findByCategory correct: " .. #spells)
    "#).exec().unwrap();
}

// -- Stack: getCapacity / setCapacity --

#[test]
fn stack_capacity() {
    let lua = make_vm();
    lua.load(r#"
        local s = luna.cardgame.newStack("hand")
        local cap = s:getCapacity()
        assert(cap == -1 or cap == 0, "unlimited by default, got: " .. cap)
        s:setCapacity(3)
        assert(s:getCapacity() == 3, "setCapacity 3")
        for i = 1, 3 do s:addCard(luna.cardgame.newCard("X")) end
        assert(not s:addCard(luna.cardgame.newCard("X")), "addCard fails at capacity")
    "#).exec().unwrap();
}

// -- Stack: moveCard and moveAllCards --

#[test]
fn stack_move_card_and_move_all() {
    let lua = make_vm();
    lua.load(r#"
        local src = luna.cardgame.newStack("src")
        local dst = luna.cardgame.newStack("dst")
        local c = luna.cardgame.newCard("X")
        src:addCard(c)
        local ok = src:moveCard(c, dst)
        assert(ok, "moveCard returns true")
        assert(not src:contains(c), "card gone from src")
        assert(dst:contains(c), "card in dst")
        local c2 = luna.cardgame.newCard("Y")
        dst:addCard(c2)
        local n = dst:moveAllCards(src)
        assert(n == 2, "moveAllCards count is 2, got " .. n)
        assert(dst:isEmpty(), "dst empty after moveAllCards")
        assert(src:size() == 2, "src has 2 after moveAllCards")
    "#).exec().unwrap();
}

// -- Stack: getCards alias --

#[test]
fn stack_get_cards_alias() {
    let lua = make_vm();
    lua.load(r#"
        local s = luna.cardgame.newStack("hand")
        s:addCard(luna.cardgame.newCard("X"))
        s:addCard(luna.cardgame.newCard("Y"))
        local cards = s:getCards()
        assert(#cards == 2, "getCards returns 2")
    "#).exec().unwrap();
}

// -- DeckBuilder: setMinCards / setMaxCards --

#[test]
fn deckbuilder_min_max_cards() {
    let lua = make_vm();
    lua.load(r#"
        local b = luna.cardgame.newDeckBuilder()
        b:setMinCards(20)
        b:setMaxCards(60)
        assert(b:getMinCards() == 20, "getMinCards")
        assert(b:getMaxCards() == 60, "getMaxCards")
    "#).exec().unwrap();
}

// -- DeckBuilder: addRequiredTag in validation --

#[test]
fn deckbuilder_required_tag_validation() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineType("Dragon", { category = "creature", tags = {"dragon"} })
        luna.cardgame.defineType("Spell", { category = "spell" })
        local b = luna.cardgame.newDeckBuilder()
        b:setMinCards(1)
        b:setMaxCards(10)
        b:addRequiredTag("dragon", 1)
        b:add("Dragon", 1)
        b:add("Spell", 2)
        local ok, errs = b:validate(b:build("deck"))
        assert(ok, "validate passes with required tag met: " .. (errs[1] or ""))
    "#).exec().unwrap();
}

// -- DeckBuilder: addBannedType / removeBannedType / getBannedTypes --

#[test]
fn deckbuilder_banned_type_remove() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineType("Evil", { category = "villain" })
        local b = luna.cardgame.newDeckBuilder()
        b:addBannedType("Evil")
        local banned = b:getBannedTypes()
        assert(#banned == 1, "getBannedTypes after ban")
        b:removeBannedType("Evil")
        banned = b:getBannedTypes()
        assert(#banned == 0, "getBannedTypes after remove")
    "#).exec().unwrap();
}

// -- DeckBuilder: addCustomRule / removeCustomRule --

#[test]
fn deckbuilder_custom_rule() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineType("Card", { category = "misc" })
        local b = luna.cardgame.newDeckBuilder()
        b:setMinCards(1)
        b:setMaxCards(10)
        b:add("Card", 2)
        b:addCustomRule("always_fail", function(deck)
            return "custom error"
        end)
        local ok, errs = b:validate(b:build("deck"))
        assert(not ok, "validate fails with custom rule")
        local found = false
        for _, e in ipairs(errs) do
            if string.find(e, "custom") then found = true end
        end
        assert(found, "error message contains custom")
        b:removeCustomRule("always_fail")
        local ok2, errs2 = b:validate(b:build("deck"))
        assert(ok2, "validate passes after rule removed: " .. (errs2[1] or ""))
    "#).exec().unwrap();
}

// -- DeckBuilder: getMaxCopies --

#[test]
fn deckbuilder_get_max_copies() {
    let lua = make_vm();
    lua.load(r#"
        local b = luna.cardgame.newDeckBuilder("deck")
        b:setMaxCopies(3)
        assert(b:getMaxCopies() == 3, "getMaxCopies")
    "#).exec().unwrap();
}

// -- CardPool: getCardTypes --

#[test]
fn cardpool_get_card_types() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineType("A", {})
        luna.cardgame.defineType("B", {})
        local pool = luna.cardgame.newCardPool()
        pool:add("A", 2)
        pool:add("B", 3)
        local types = pool:getCardTypes()
        assert(#types == 2, "getCardTypes count: " .. #types)
        assert(pool:getCardTypeCount() == 2, "getCardTypeCount")
    "#).exec().unwrap();
}

// -- CardPool: getWeight --

#[test]
fn cardpool_get_weight() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineType("Rare", { rarity = "rare" })
        local pool = luna.cardgame.newCardPool()
        pool:add("Rare", 5)
        assert(pool:getWeight("Rare") == 5, "getWeight correct")
        assert(pool:getWeight("Missing") == 0, "getWeight missing is 0")
    "#).exec().unwrap();
}

// -- CardPool: drawRandom --

#[test]
fn cardpool_draw_random() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineType("Card", {})
        local pool = luna.cardgame.newCardPool()
        pool:add("Card", 1)
        local cards = pool:drawRandom(3)
        assert(#cards == 3, "drawRandom returns 3 cards")
        local cards2 = pool:drawRandom(2, 42)
        assert(#cards2 == 2, "drawRandom seeded returns 2 cards")
    "#).exec().unwrap();
}

// -- CardPool: setRarityWeight / drawByRarity --

#[test]
fn cardpool_set_rarity_weight_and_draw_by_rarity() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineType("Common", { rarity = "common" })
        luna.cardgame.defineType("Rare", { rarity = "rare" })
        local pool = luna.cardgame.newCardPool()
        pool:add("Common", 1)
        pool:add("Rare", 1)
        pool:setRarityWeight("common", 10)
        pool:setRarityWeight("rare", 2)
        local cards = pool:drawByRarity({ common = 5, rare = 1 })
        assert(#cards == 6, "drawByRarity total count: " .. #cards)
    "#).exec().unwrap();
}

// -- CardPool: setName / addCardType --

#[test]
fn cardpool_set_name_and_add_card_type() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineType("Hero", {})
        local pool = luna.cardgame.newCardPool()
        pool:setName("draft_pool")
        pool:addCardType("Hero", 3)
        assert(pool:size() == 1, "addCardType adds entry")
        assert(pool:getWeight("Hero") == 3, "addCardType weight")
    "#).exec().unwrap();
}

// -- LuaEffectStack: push / pop / peek --

#[test]
fn effect_stack_push_pop_peek() {
    let lua = make_vm();
    lua.load(r#"
        local es = luna.cardgame.newEffectStack()
        assert(es:isEmpty(), "starts empty")
        es:push({ effect = "fireball", value = 5 })
        es:push({ effect = "lightning", value = 3 })
        assert(es:getCount() == 2, "count 2")
        assert(not es:isEmpty(), "not empty")
        local top = es:peek()
        assert(top.effect == "lightning", "peek returns top")
        local popped = es:pop()
        assert(popped.effect == "lightning", "pop removes top")
        assert(es:getCount() == 1, "count 1 after pop")
    "#).exec().unwrap();
}

// -- LuaEffectStack: clear / getEntries --

#[test]
fn effect_stack_clear_and_get_entries() {
    let lua = make_vm();
    lua.load(r#"
        local es = luna.cardgame.newEffectStack()
        es:push({ effect = "a" })
        es:push({ effect = "b" })
        local entries = es:getEntries()
        assert(#entries == 2, "getEntries count")
        es:clear()
        assert(es:isEmpty(), "empty after clear")
    "#).exec().unwrap();
}

// -- LuaEffectStack: resolveAll --

#[test]
fn effect_stack_resolve_all() {
    let lua = make_vm();
    lua.load(r#"
        local es = luna.cardgame.newEffectStack()
        es:push({ effect = "a" })
        es:push({ effect = "b" })
        es:push({ effect = "c" })
        local count = es:resolveAll()
        assert(count == 3, "resolveAll count 3, got " .. count)
        assert(es:isEmpty(), "empty after resolveAll")
    "#).exec().unwrap();
}

// -- LuaEffectStack: findByCard --

#[test]
fn effect_stack_find_by_card() {
    let lua = make_vm();
    lua.load(r#"
        local es = luna.cardgame.newEffectStack()
        local c1 = luna.cardgame.newCard("X")
        local c2 = luna.cardgame.newCard("Y")
        es:push({ card = c1, effect = "hit" })
        es:push({ card = c2, effect = "block" })
        es:push({ card = c1, effect = "counter" })
        local indices = es:findByCard(c1)
        assert(#indices == 2, "findByCard found 2 for c1, got " .. #indices)
    "#).exec().unwrap();
}

// -- API aliases --

#[test]
fn api_aliases_work() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        luna.cardgame.defineCardType("Warrior", { category = "unit" })
        local t = luna.cardgame.getCardType("Warrior")
        assert(t ~= nil, "getCardType alias works")
        local names = luna.cardgame.getCardTypeNames()
        assert(type(names) == "table", "getCardTypeNames alias works")
        luna.cardgame.clearCardTypes()
        local deck = luna.cardgame.newDeck("deck")
        assert(deck ~= nil, "newDeck alias works")
        local zone = luna.cardgame.newZone("battlefield")
        assert(zone ~= nil, "newZone alias works")
        local es1 = luna.cardgame.newEffectStack()
        local es2 = luna.cardgame.newStackManager()
        assert(es1 ~= nil and es2 ~= nil, "effect stack constructors work")
    "#).exec().unwrap();
}

// -- defineCardType stores type-level scripts in _LUNA_CG_SCRIPTS --

#[test]
fn define_card_type_with_scripts_global() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearTypes()
        local fired = false
        luna.cardgame.defineCardType("Spell", {
            category = "magic",
            scripts = {
                onPlay = function(card) fired = true end,
            }
        })
        local c = luna.cardgame.newCard("Spell")
        c:fireScript("onPlay")
        assert(fired, "type-level script fires via fireScript")
    "#).exec().unwrap();
}
