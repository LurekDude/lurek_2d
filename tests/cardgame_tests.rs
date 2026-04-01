//! Integration tests for `luna.cardgame.*`.

use luna2d::lua_api::{create_lua_vm, SharedState};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(800, 600, "Test", PathBuf::from("."))));
    create_lua_vm(state).unwrap()
}

// ─────────────────────────────────────────────────────────────────────────────
// Card type registry
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn define_and_get_card_type() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearCardTypes()
        luna.cardgame.defineCardType("Soldier", { category="unit", stats={atk=2, hp=3} })
        local t = luna.cardgame.getCardType("Soldier")
        assert(t ~= nil, "type exists")
        assert(t.category == "unit", "category")
    "#).exec().unwrap();
}

#[test]
fn get_card_type_names() {
    let lua = make_vm();
    lua.load(r#"
        luna.cardgame.clearCardTypes()
        luna.cardgame.defineCardType("A", {})
        luna.cardgame.defineCardType("B", {})
        local names = luna.cardgame.getCardTypeNames()
        assert(#names == 2 or #names >= 2, "at least 2 names")
    "#).exec().unwrap();
}

#[test]
fn get_unknown_card_type_returns_nil() {
    let lua = make_vm();
    lua.load(r#"
        local t = luna.cardgame.getCardType("__nonexistent__12345")
        assert(t == nil, "should be nil")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// Card creation and basic ops
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn new_card_type_method() {
    let lua = make_vm();
    lua.load(r#"
        local card = luna.cardgame.newCard("Warrior")
        assert(card:type() == "Card", "type()")
        assert(card:typeOf("Card"), "typeOf")
    "#).exec().unwrap();
}

#[test]
fn card_name_and_category() {
    let lua = make_vm();
    lua.load(r#"
        local card = luna.cardgame.newCard("Warrior")
        card:setName("Sir Aldric")
        assert(card:getName() == "Sir Aldric", "getName after setName")
        card:setCategory("hero")
        assert(card:getCategory() == "hero", "category")
    "#).exec().unwrap();
}

#[test]
fn card_stats() {
    let lua = make_vm();
    lua.load(r#"
        local card = luna.cardgame.newCard("Mage")
        card:setStat("atk", 5.0)
        card:setStat("def", 2.0)
        assert(card:getStat("atk") == 5.0, "atk")
        assert(card:getStat("def") == 2.0, "def")
        assert(card:getStat("hp") == 0.0, "missing stat = 0")
        local stats = card:getStats()
        assert(stats.atk == 5.0, "getStats atk")
    "#).exec().unwrap();
}

#[test]
fn card_tags() {
    let lua = make_vm();
    lua.load(r#"
        local card = luna.cardgame.newCard("Dragon")
        card:addTag("flying")
        card:addTag("fire")
        assert(card:hasTag("flying"), "has flying")
        assert(card:hasTag("fire"), "has fire")
        assert(not card:hasTag("water"), "no water")
        card:removeTag("fire")
        assert(not card:hasTag("fire"), "fire removed")
        local tags = card:getTags()
        assert(#tags == 1, "one tag left")
    "#).exec().unwrap();
}

#[test]
fn card_counters() {
    let lua = make_vm();
    lua.load(r#"
        local card = luna.cardgame.newCard("Elf")
        card:addCounter("+1/+1", 3)
        assert(card:getCounter("+1/+1") == 3, "3 counters")
        card:addCounter("+1/+1", 2)
        assert(card:getCounter("+1/+1") == 5, "5 counters after add")
        card:removeCounters("+1/+1")
        assert(card:getCounter("+1/+1") == 0, "0 after removeCounters")
    "#).exec().unwrap();
}

#[test]
fn card_state_flags() {
    let lua = make_vm();
    lua.load(r#"
        local card = luna.cardgame.newCard("Knight")
        assert(not card:isTapped(), "not tapped initially")
        card:tap()
        assert(card:isTapped(), "tapped")
        card:untap()
        assert(not card:isTapped(), "untapped")
        assert(not card:isFaceUp(), "face down by default")
        card:setFaceUp(true)
        assert(card:isFaceUp(), "face up")
    "#).exec().unwrap();
}

#[test]
fn card_owner_and_zone() {
    let lua = make_vm();
    lua.load(r#"
        local card = luna.cardgame.newCard("Goblin")
        card:setOwner("player1")
        card:setController("player2")
        assert(card:getOwner() == "player1", "owner")
        assert(card:getController() == "player2", "controller")
        assert(card:getZone() == "", "no zone initially")
    "#).exec().unwrap();
}

#[test]
fn card_metadata() {
    let lua = make_vm();
    lua.load(r#"
        local card = luna.cardgame.newCard("Wizard")
        card:setMeta("flavor", "Ancient and wise")
        assert(card:getMeta("flavor") == "Ancient and wise", "metadata")
    "#).exec().unwrap();
}

#[test]
fn card_clone() {
    let lua = make_vm();
    lua.load(r#"
        local card = luna.cardgame.newCard("Archer")
        card:setStat("atk", 3.0)
        local clone = card:clone()
        assert(clone:getStat("atk") == 3.0, "clone has same stat")
        clone:setStat("atk", 99.0)
        assert(card:getStat("atk") == 3.0, "original unchanged")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// Deck
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn deck_push_and_draw() {
    let lua = make_vm();
    lua.load(r#"
        local deck = luna.cardgame.newDeck("main")
        assert(deck:getName() == "main", "deck name")
        assert(deck:isEmpty(), "empty initially")
        local card1 = luna.cardgame.newCard("A")
        local card2 = luna.cardgame.newCard("B")
        deck:push(card1)
        deck:push(card2)
        assert(deck:getSize() == 2, "size 2")
        local drawn = deck:draw()
        assert(drawn ~= nil, "drew a card")
        assert(deck:getSize() == 1, "size 1 after draw")
    "#).exec().unwrap();
}

#[test]
fn deck_peek() {
    let lua = make_vm();
    lua.load(r#"
        local deck = luna.cardgame.newDeck()
        local card = luna.cardgame.newCard("PeekCard")
        deck:push(card)
        local peeked = deck:peek()
        assert(peeked ~= nil, "peek not nil")
        assert(deck:getSize() == 1, "size unchanged after peek")
    "#).exec().unwrap();
}

#[test]
fn deck_shuffle() {
    let lua = make_vm();
    lua.load(r#"
        local deck = luna.cardgame.newDeck()
        for i = 1, 20 do
            deck:push(luna.cardgame.newCard("Card"..i))
        end
        assert(deck:getSize() == 20, "20 cards before shuffle")
        deck:shuffle()
        assert(deck:getSize() == 20, "20 cards after shuffle")
    "#).exec().unwrap();
}

#[test]
fn deck_search_by_type() {
    let lua = make_vm();
    lua.load(r#"
        local deck = luna.cardgame.newDeck()
        local a = luna.cardgame.newCard("Dragon")
        local b = luna.cardgame.newCard("Knight")
        local c = luna.cardgame.newCard("Dragon")
        deck:push(a) ; deck:push(b) ; deck:push(c)
        local found = deck:searchByType("Dragon")
        assert(#found == 2, "found 2 dragons")
    "#).exec().unwrap();
}

#[test]
fn deck_get_cards() {
    let lua = make_vm();
    lua.load(r#"
        local deck = luna.cardgame.newDeck()
        for i = 1, 5 do deck:push(luna.cardgame.newCard("C"..i)) end
        local cards = deck:getCards()
        assert(#cards == 5, "getCards returns 5")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn zone_add_and_remove() {
    let lua = make_vm();
    lua.load(r#"
        local zone = luna.cardgame.newZone("hand")
        assert(zone:getName() == "hand", "zone name")
        assert(zone:isEmpty(), "empty initially")
        local card = luna.cardgame.newCard("X")
        zone:add(card)
        assert(zone:getSize() == 1, "size 1")
        zone:removeAt(1)
        assert(zone:isEmpty(), "empty after remove")
    "#).exec().unwrap();
}

#[test]
fn zone_capacity_limit() {
    let lua = make_vm();
    lua.load(r#"
        local zone = luna.cardgame.newZone("hand", 2)
        assert(zone:getCapacity() == 2, "capacity 2")
        local c1 = luna.cardgame.newCard("A")
        local c2 = luna.cardgame.newCard("B")
        local c3 = luna.cardgame.newCard("C")
        zone:add(c1) ; zone:add(c2)
        local ok, err = pcall(function() zone:add(c3) end)
        assert(not ok, "add errors when full")
        assert(zone:getSize() == 2, "still 2 cards")
    "#).exec().unwrap();
}

#[test]
fn zone_move_card() {
    let lua = make_vm();
    lua.load(r#"
        local src = luna.cardgame.newZone("src")
        local dst = luna.cardgame.newZone("dst")
        src:add(luna.cardgame.newCard("Mover"))
        assert(src:getSize() == 1, "src has card")
        src:moveCard(1, dst)
        assert(src:getSize() == 0, "src empty after move")
        assert(dst:getSize() == 1, "dst has card after move")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// StackManager
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn stack_manager_lifo() {
    let lua = make_vm();
    lua.load(r#"
        local stack = luna.cardgame.newStackManager()
        stack:push("cast")
        stack:push("counter")
        assert(stack:getSize() == 2, "size 2")
        local top = stack:resolve()
        assert(top ~= nil, "resolved")
        assert(top.kind == "counter", "LIFO order")
        assert(stack:getSize() == 1, "size 1 after resolve")
    "#).exec().unwrap();
}

#[test]
fn stack_manager_peek_and_clear() {
    let lua = make_vm();
    lua.load(r#"
        local stack = luna.cardgame.newStackManager()
        stack:push("effect")
        local p = stack:peek()
        assert(p ~= nil, "peek")
        assert(stack:getSize() == 1, "peek doesn't remove")
        stack:clear()
        assert(stack:isEmpty(), "cleared")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// DeckBuilder
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn deck_builder_validate() {
    let lua = make_vm();
    lua.load(r#"
        local builder = luna.cardgame.newDeckBuilder()
        builder:setMinCards(2)
        builder:setMaxCards(4)
        builder:setMaxCopies(2)
        local deck = luna.cardgame.newDeck()
        local errors = builder:validate(deck)
        assert(#errors > 0, "empty deck fails min cards")
        for i = 1, 3 do deck:push(luna.cardgame.newCard("Card"..i)) end
        errors = builder:validate(deck)
        assert(builder:isValid(deck), "valid deck")
    "#).exec().unwrap();
}

// ─────────────────────────────────────────────────────────────────────────────
// CardPool
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fn card_pool_draw() {
    let lua = make_vm();
    lua.load(r#"
        local pool = luna.cardgame.newCardPool("booster")
        assert(pool:getName() == "booster", "pool name")
        pool:add("Common", 60)
        pool:add("Rare", 30)
        pool:add("Epic", 10)
        assert(pool:getSize() == 3, "3 entries")
        assert(pool:getTotalWeight() == 100, "total weight 100")
        local drawn = pool:draw(5)
        assert(#drawn == 5, "drew 5")
    "#).exec().unwrap();
}

#[test]
fn card_pool_remove() {
    let lua = make_vm();
    lua.load(r#"
        local pool = luna.cardgame.newCardPool()
        pool:add("A", 50)
        pool:add("B", 50)
        assert(pool:getSize() == 2, "2 entries")
        pool:remove("A")
        assert(pool:getSize() == 1, "1 entry after remove")
    "#).exec().unwrap();
}

#[test]
fn deck_count_by_type() {
    let lua = make_vm();
    lua.load(r#"
        local d = luna.cardgame.newDeck("test")
        d:insertAt(luna.cardgame.newCard("warrior"), 1)
        d:insertAt(luna.cardgame.newCard("warrior"), 1)
        d:insertAt(luna.cardgame.newCard("mage"), 1)
        assert(d:countByType("warrior") == 2, "2 warriors")
        assert(d:countByType("mage") == 1, "1 mage")
        assert(d:countByType("rogue") == 0, "0 rogues")
    "#).exec().unwrap();
}

#[test]
fn deck_reveal_top() {
    let lua = make_vm();
    lua.load(r#"
        local d = luna.cardgame.newDeck("reveal")
        d:insertAt(luna.cardgame.newCard("a"), 1)
        d:insertAt(luna.cardgame.newCard("b"), 1)
        d:insertAt(luna.cardgame.newCard("c"), 1)
        local top = d:revealTop(2)
        assert(#top == 2, "revealed 2 cards")
        assert(d:getSize() == 3, "deck unchanged")
    "#).exec().unwrap();
}

#[test]
fn zone_count_by_type_all_types() {
    let lua = make_vm();
    lua.load(r#"
        local z = luna.cardgame.newZone("battlefield", 10)
        z:add(luna.cardgame.newCard("knight"))
        z:add(luna.cardgame.newCard("knight"))
        z:add(luna.cardgame.newCard("dragon"))
        assert(z:countByType("knight") == 2, "2 knights")
        assert(z:countByType("dragon") == 1, "1 dragon")
        local types = z:getAllTypes()
        assert(#types == 3, "3 cards total")
    "#).exec().unwrap();
}

#[test]
fn card_get_all_counters() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.cardgame.newCard("creature")
        c:addCounter("damage", 3)
        c:addCounter("power", 1)
        local all = c:getAllCounters()
        assert(all.damage == 3, "damage counter")
        assert(all.power == 1, "power counter")
    "#).exec().unwrap();
}

#[test]
fn cardpool_get_types() {
    let lua = make_vm();
    lua.load(r#"
        local pool = luna.cardgame.newCardPool("loot")
        pool:add("sword", 30)
        pool:add("shield", 20)
        pool:add("ring", 10)
        local types = pool:getTypes()
        assert(#types == 3, "3 types in pool")
        local found = {}
        for _, t in ipairs(types) do found[t] = true end
        assert(found["sword"], "sword in pool")
        assert(found["ring"], "ring in pool")
    "#).exec().unwrap();
}
