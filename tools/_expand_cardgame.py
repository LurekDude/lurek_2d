"""Expand cardgame module with:
Domain: Deck::count_by_type, reveal_top; Zone::count_by_type, get_all_types;
         Card::get_all_counters; CardPool::get_types
API: Deck.countByType, revealTop; Zone.countByType, getAllTypes; Card.getAllCounters;
     CardPool.getTypes
Tests: 5 new tests
"""

MOD = r"src\cardgame\mod.rs"
with open(MOD, "r", encoding="utf-8") as f:
    dom = f.read()

# Add to Deck impl
deck_extra = """
    /// Returns the number of cards of a specific type in the deck.
    pub fn count_by_type(&self, card_type: &str) -> usize {
        self.cards.iter().filter(|c| c.card_type == card_type).count()
    }

    /// Peek at the top `n` cards (without removing) and return their types.
    pub fn reveal_top(&self, n: usize) -> Vec<String> {
        self.cards.iter().rev().take(n)
            .map(|c| c.card_type.clone())
            .collect()
    }
"""

# Find end of Deck impl — the `draw_bottom` or `get_cards` method is last
dom = dom.replace(
    "\n    pub fn get_cards(&self) -> &[Card] { &self.cards }\n}\n",
    "\n    pub fn get_cards(&self) -> &[Card] { &self.cards }\n" + deck_extra + "\n}\n",
    1,
)

# Add to Zone impl
zone_extra = """
    /// Returns the number of cards of a specific type in the zone.
    pub fn count_by_type(&self, card_type: &str) -> usize {
        self.cards.iter().filter(|c| c.card_type == card_type).count()
    }

    /// Returns the types of all cards in the zone.
    pub fn get_all_types(&self) -> Vec<String> {
        self.cards.iter().map(|c| c.card_type.clone()).collect()
    }
"""

# Find end of Zone impl
dom = dom.replace(
    "\n    pub fn get_cards(&self) -> &[Card] { &self.cards }\n}\n\n// ",
    "\n    pub fn get_cards(&self) -> &[Card] { &self.cards }\n" + zone_extra + "\n}\n\n// ",
    1,
)

# Add to Card impl  — get_all_counters
card_counter_extra = """
    /// Returns a copy of all counter (kind, count) pairs on this card.
    pub fn get_all_counters(&self) -> Vec<(String, i32)> {
        self.counters.iter().map(|(k, v)| (k.clone(), *v)).collect()
    }
"""

# Find end of Card impl — tap/untap/is_tapped are last... look for set_controller then clone
dom = dom.replace(
    "\n    pub fn clone_card(&self) -> Card { self.clone() }\n}",
    card_counter_extra + "\n    pub fn clone_card(&self) -> Card { self.clone() }\n}",
    1,
)

# Add to CardPool impl — get_types
card_pool_extra = """
    /// Returns the list of all card types currently in the pool.
    pub fn get_types(&self) -> Vec<String> {
        self.entries.iter().map(|(t, _)| t.clone()).collect()
    }
"""

# Find end of CardPool impl — draw is last
dom = dom.replace(
    "\n    pub fn draw(&mut self) -> Option<String> {",
    card_pool_extra + "\n    pub fn draw(&mut self) -> Option<String> {",
    1,
)

with open(MOD, "w", encoding="utf-8") as f:
    f.write(dom)
print("cardgame/mod.rs updated")

# ---- Lua API ----------------------------------------------------------------
API = r"src\lua_api\cardgame_api.rs"
with open(API, "r", encoding="utf-8") as f:
    api = f.read()

deck_api_extra = '''        methods.add_method("countByType", |_, this, card_type: String| {
            Ok(this.0.borrow().count_by_type(&card_type))
        });
        methods.add_method("revealTop", |lua, this, n: usize| {
            let types = this.0.borrow().reveal_top(n);
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() {
                t.set(i + 1, ct)?;
            }
            Ok(t)
        });
'''

zone_api_extra = '''        methods.add_method("countByType", |_, this, card_type: String| {
            Ok(this.0.borrow().count_by_type(&card_type))
        });
        methods.add_method("getAllTypes", |lua, this, ()| {
            let types = this.0.borrow().get_all_types();
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() {
                t.set(i + 1, ct)?;
            }
            Ok(t)
        });
'''

card_api_extra = '''        methods.add_method("getAllCounters", |lua, this, ()| {
            let counters = this.0.borrow().get_all_counters();
            let t = lua.create_table()?;
            for (kind, count) in counters {
                t.set(kind, count)?;
            }
            Ok(t)
        });
'''

cardpool_api_extra = '''        methods.add_method("getTypes", |lua, this, ()| {
            let types = this.0.borrow().get_types();
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() {
                t.set(i + 1, ct)?;
            }
            Ok(t)
        });
'''

# Insert Deck extras before getCards binding
api = api.replace(
    '        methods.add_method("getCards", |lua, this, ()| {\n            let t = lua.create_table()?;\n            for (i, card) in this.0.borrow().get_cards()',
    deck_api_extra + '        methods.add_method("getCards", |lua, this, ()| {\n            let t = lua.create_table()?;\n            for (i, card) in this.0.borrow().get_cards()',
    1,
)

# Insert Zone extras before getCards binding for Zone (it also has getCards)
# We need to be careful not to hit the Deck one again.
# The Zone's getCards comes after the Deck's getCards in the file.
# Split into parts above/below already-updated Deck getCards to avoid double-replace.
# Actually - each type has its own impl block, so the second `getCards` belongs to Zone.
# We can count occurrences or be more specific.
# Let's find "findByType" before Zone's getCards:
api = api.replace(
    '        methods.add_method("findByType", |lua, this, card_type: String| {',
    zone_api_extra + '        methods.add_method("findByType", |lua, this, card_type: String| {',
    1,
)

# Insert Card extras before `clone` binding
api = api.replace(
    '        methods.add_method("clone", |_, this, ()| {',
    card_api_extra + '        methods.add_method("clone", |_, this, ()| {',
    1,
)

# Insert CardPool extras before `draw` binding
api = api.replace(
    '        methods.add_method("draw", |_, this, ()| {',
    cardpool_api_extra + '        methods.add_method("draw", |_, this, ()| {',
    1,
)

with open(API, "w", encoding="utf-8") as f:
    f.write(api)
print("cardgame_api.rs updated")

# ---- Tests ----------------------------------------------------------------
TEST = r"tests\cardgame_tests.rs"
with open(TEST, "r", encoding="utf-8") as f:
    tst = f.read()

new_tests = r'''
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
'''

tst = tst.rstrip() + "\n" + new_tests
with open(TEST, "w", encoding="utf-8") as f:
    f.write(tst)
print("cardgame_tests.rs updated")
print("Done - cardgame module expanded")
