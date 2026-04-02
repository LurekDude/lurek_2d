//! Lua bindings for `luna.cardgame.*`.
//!
//! Exposes Card, Deck, Zone, StackManager, DeckBuilder, CardPool, Player,
//! ScoreBoard, ResourcePool, Pot, TurnManager, TrickState, TrickHistory,
//! EventLog, GameRules, and hand-evaluation utilities to Lua.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::cardgame::{
    Card, CardPool, CardTypeDef, Deck, DeckBuilder, StackEntry, StackManager, Zone,
    clear_card_types, define_card_type, get_card_type, get_card_type_names,
    // New types
    EventLog, GameEvent, GameRules,
    Player,
    Pot, ResourcePool,
    ScoreBoard,
    TrickHistory, TrickState,
    TurnManager,
    // hand-eval utilities
    find_at_least_n_of_a_kind, find_flush_groups, find_n_of_a_kind, find_sequences,
};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ─────────────────────────────────────────────────────────────────────────────
// LuaCard
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Card` userdata.
#[derive(Clone)]
pub struct LuaCard(pub Rc<RefCell<Card>>);

impl LunaType for LuaCard {
    const TYPE_NAME: &'static str = "Card";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Card"];
}

impl LuaUserData for LuaCard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // Read-only identity
        /// Returns the type identifier string for this card.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getCardType", |_, this, ()| {
            Ok(this.0.borrow().card_type.clone())
        });
        /// Returns the display name of this card.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the card's display name.
        ///
        /// # Parameters
        /// - `name` — `string`: New name.
        methods.add_method("setName", |_, this, name: String| {
            this.0.borrow_mut().name = name;
            Ok(())
        });
        /// Returns the category tag for this card (e.g. `'spell'`, `'creature'`).
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getCategory", |_, this, ()| {
            Ok(this.0.borrow().category.clone())
        });
        /// Sets the category tag for this card.
        ///
        /// # Parameters
        /// - `category` — `string`: New category.
        methods.add_method("setCategory", |_, this, cat: String| {
            this.0.borrow_mut().category = cat;
            Ok(())
        });

        // Stats
        /// Returns the value of the named numeric stat.
        ///
        /// # Parameters
        /// - `key` — `string`: Stat name (e.g. `'attack'`, `'defense'`).
        ///
        /// # Returns
        /// `number` — stat value, or `0` if not set.
        methods.add_method("getStat", |_, this, name: String| {
            Ok(this.0.borrow().get_stat(&name))
        });
        /// Sets a numeric stat on this card.
        ///
        /// # Parameters
        /// - `key` — `string`: Stat name.
        /// - `value` — `number`: Stat value.
        methods.add_method("setStat", |_, this, (name, value): (String, f64)| {
            this.0.borrow_mut().set_stat(name, value);
            Ok(())
        });
        /// Returns all numeric stats as a key-value table.
        ///
        /// # Returns
        /// `table` of `{stat: number}` pairs.
        methods.add_method("getStats", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (k, v) in &borrow.stats {
                t.set(k.as_str(), *v)?;
            }
            Ok(t)
        });

        // Tags
        /// Attaches a tag to this card.
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to add.
        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().add_tag(tag);
            Ok(())
        });
        /// Removes a tag from this card.
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to remove.
        methods.add_method("removeTag", |_, this, tag: String| {
            this.0.borrow_mut().remove_tag(&tag);
            Ok(())
        });
        /// Returns `true` if this card carries the given tag.
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to test.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTag", |_, this, tag: String| {
            Ok(this.0.borrow().has_tag(&tag))
        });
        /// Returns a list of all tags attached to this card.
        ///
        /// # Returns
        /// `table` of `string` tags.
        methods.add_method("getTags", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_sequence_from(borrow.tags.iter().cloned())?;
            Ok(t)
        });

        // Counters
        /// Increments the named counter by `amount` (default `1`).
        ///
        /// # Parameters
        /// - `name` — `string`: Counter name.
        /// - `amount` — `integer`: Amount to add (optional, default `1`).
        methods.add_method("addCounter", |_, this, (kind, amount): (String, i32)| {
            Ok(this.0.borrow_mut().add_counter(kind, amount))
        });
        /// Returns the current value of the named counter.
        ///
        /// # Parameters
        /// - `name` — `string`: Counter name.
        ///
        /// # Returns
        /// `integer` — counter value.
        methods.add_method("getCounter", |_, this, kind: String| {
            Ok(this.0.borrow().get_counter(&kind))
        });
        /// Removes all counters of the given name.
        ///
        /// # Parameters
        /// - `name` — `string`: Counter name to clear.
        methods.add_method("removeCounters", |_, this, kind: String| {
            this.0.borrow_mut().remove_counters(&kind);
            Ok(())
        });

        // State flags
        /// Marks this card as tapped. A tapped card cannot be tapped again until untapped.
        methods.add_method("tap", |_, this, ()| {
            this.0.borrow_mut().tap();
            Ok(())
        });
        /// Removes the tapped state from this card.
        methods.add_method("untap", |_, this, ()| {
            this.0.borrow_mut().untap();
            Ok(())
        });
        /// Returns `true` if this card is currently tapped.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isTapped", |_, this, ()| Ok(this.0.borrow().tapped));
        /// Returns `true` if this card is face-up (visible).
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isFaceUp", |_, this, ()| Ok(this.0.borrow().face_up));
        /// Sets whether this card is face-up (`true`) or face-down (`false`).
        ///
        /// # Parameters
        /// - `face_up` — `boolean`: Face state.
        methods.add_method("setFaceUp", |_, this, v: bool| {
            this.0.borrow_mut().face_up = v;
            Ok(())
        });
        /// Returns the owner identifier string, or `nil` if unowned.
        ///
        /// # Returns
        /// `string` or `nil`.
        methods.add_method("getOwner", |_, this, ()| Ok(this.0.borrow().owner.clone()));
        /// Sets the owner identifier for this card.
        ///
        /// # Parameters
        /// - `owner` — `string`: Owner identifier.
        methods.add_method("setOwner", |_, this, v: String| {
            this.0.borrow_mut().owner = v;
            Ok(())
        });
        /// Returns the controller identifier (the player currently controlling this card).
        ///
        /// # Returns
        /// `string` or `nil`.
        methods.add_method("getController", |_, this, ()| {
            Ok(this.0.borrow().controller.clone())
        });
        /// Sets the controller for this card.
        ///
        /// # Parameters
        /// - `controller` — `string`: Controller identifier.
        methods.add_method("setController", |_, this, v: String| {
            this.0.borrow_mut().controller = v;
            Ok(())
        });
        /// Returns the name of the zone this card currently occupies.
        ///
        /// # Returns
        /// `string` — zone name.
        methods.add_method("getZone", |_, this, ()| Ok(this.0.borrow().zone.clone()));

        // Metadata
        /// Returns the metadata value for `key`, or `nil` if not set.
        ///
        /// # Parameters
        /// - `key` — `string`: Metadata key.
        ///
        /// # Returns
        /// The stored value or `nil`.
        methods.add_method("getMeta", |_, this, key: String| {
            let borrow = this.0.borrow();
            let val = borrow.get_meta(&key).map(String::from);
            drop(borrow);
            Ok(val)
        });
        /// Stores an arbitrary metadata value on this card.
        ///
        /// # Parameters
        /// - `key` — `string`: Metadata key.
        /// - `value` — `any`: Value to store.
        methods.add_method("setMeta", |_, this, (k, v): (String, String)| {
            this.0.borrow_mut().set_meta(k, v);
            Ok(())
        });

        // Clone
        /// Returns a key-value table of all counters on this card.
        ///
        /// # Returns
        /// `table` of `{name: integer}` counter pairs.
        methods.add_method("getAllCounters", |lua, this, ()| {
            let counters = this.0.borrow().get_all_counters();
            let t = lua.create_table()?;
            for (kind, count) in counters {
                t.set(kind, count)?;
            }
            Ok(t)
        });
        /// Creates and returns a deep copy of this card with identical stats, tags, and counters.
        ///
        /// # Returns
        /// `Card` — the new copy.
        methods.add_method("clone", |_, this, ()| {
            let cloned = this.0.borrow().clone();
            Ok(LuaCard(Rc::new(RefCell::new(cloned))))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaDeck
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Deck` userdata.
#[derive(Clone)]
pub struct LuaDeck(pub Rc<RefCell<Deck>>);

impl LunaType for LuaDeck {
    const TYPE_NAME: &'static str = "Deck";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Deck"];
}

impl LuaUserData for LuaDeck {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the deck's name.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the number of cards currently in this deck.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getSize", |_, this, ()| Ok(this.0.borrow().size()));
        /// Returns `true` if the deck contains no cards.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Shuffles the deck in-place using a Fisher–Yates shuffle.
        methods.add_method("shuffle", |_, this, ()| {
            this.0.borrow_mut().shuffle();
            Ok(())
        });

        // Adding cards
        methods.add_method(
            "push",
            |_, this, (card, position): (LuaAnyUserData, Option<String>)| {
                let card_clone = card.borrow::<LuaCard>()?.0.borrow().clone();
                match position.as_deref() {
                    Some("bottom") => this.0.borrow_mut().push_bottom(card_clone),
                    _ => this.0.borrow_mut().push_top(card_clone),
                }
                Ok(())
            },
        );
        /// Inserts `card` at position `index` (1-based). Use index `1` for top, or the deck size for bottom.
        ///
        /// # Parameters
        /// - `index` — `integer`: 1-based insertion position.
        /// - `card` — `Card`: Card to insert.
        methods.add_method("insertAt", |_, this, (card, index): (LuaAnyUserData, usize)| {
            let card_clone = card.borrow::<LuaCard>()?.0.borrow().clone();
            this.0.borrow_mut().insert_at(index.saturating_sub(1), card_clone);
            Ok(())
        });

        // Drawing
        /// Removes and returns the top card of the deck, or `nil` if empty.
        ///
        /// # Returns
        /// `Card` or `nil`.
        methods.add_method("draw", |_, this, ()| {
            let drawn = this.0.borrow_mut().draw();
            Ok(drawn.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });
        /// Removes and returns the bottom card of the deck, or `nil` if empty.
        ///
        /// # Returns
        /// `Card` or `nil`.
        methods.add_method("drawBottom", |_, this, ()| {
            let drawn = this.0.borrow_mut().draw_bottom();
            Ok(drawn.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });
        /// Returns the top card without removing it, or `nil` if empty.
        ///
        /// # Returns
        /// `Card` or `nil`.
        methods.add_method("peek", |_, this, ()| {
            let borrow = this.0.borrow();
            let card = borrow.peek().cloned();
            drop(borrow);
            Ok(card.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });
        /// Removes and returns the card at 1-based `index`.
        ///
        /// # Parameters
        /// - `index` — `integer`: 1-based position.
        ///
        /// # Returns
        /// `Card` or `nil`.
        methods.add_method("removeAt", |_, this, index: usize| {
            let removed = this.0.borrow_mut().remove_at(index.saturating_sub(1));
            Ok(removed.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });

        // Search
        /// Returns a list of all cards in this deck that carry the given tag.
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to search for.
        ///
        /// # Returns
        /// `table` of `Card` objects.
        methods.add_method("searchByTag", |lua, this, tag: String| {
            let borrow = this.0.borrow();
            let indices = borrow.search_by_tag(&tag);
            let t = lua.create_sequence_from(indices.into_iter().map(|i| i + 1))?;
            Ok(t)
        });
        /// Returns a list of all cards of the given type.
        ///
        /// # Parameters
        /// - `card_type` — `string`: Card type identifier to match.
        ///
        /// # Returns
        /// `table` of `Card` objects.
        methods.add_method("searchByType", |lua, this, ct: String| {
            let borrow = this.0.borrow();
            let indices = borrow.search_by_type(&ct);
            let t = lua.create_sequence_from(indices.into_iter().map(|i| i + 1))?;
            Ok(t)
        });

        // Get all cards as Lua table
        /// Returns the count of cards matching the given type.
        ///
        /// # Parameters
        /// - `card_type` — `string`: Card type to count.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("countByType", |_, this, card_type: String| {
            Ok(this.0.borrow().count_by_type(&card_type))
        });
        /// Returns the top `n` cards without removing them.
        ///
        /// # Parameters
        /// - `n` — `integer`: Number of cards to reveal.
        ///
        /// # Returns
        /// `table` of `Card` objects (may be fewer than `n` if the deck is small).
        methods.add_method("revealTop", |lua, this, n: usize| {
            let types = this.0.borrow().reveal_top(n);
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() { t.set(i + 1, ct)?; }
            Ok(t)
        });
        /// Returns the full ordered list of cards in this deck (top to bottom).
        ///
        /// # Returns
        /// `table` of `Card` objects.
        methods.add_method("getCards", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, card) in borrow.cards.iter().enumerate() {
                t.set(i + 1, LuaCard(Rc::new(RefCell::new(card.clone()))))?;
            }
            Ok(t)
        });

        /// Moves the card at `from` to `to` (both 1-based), shifting other cards to fill the gap.
        ///
        /// # Parameters
        /// - `from` — `integer`: Source position.
        /// - `to` — `integer`: Destination position.
        methods.add_method("moveWithin", |_, this, (from, to): (usize, usize)| {
            Ok(this.0.borrow_mut().move_within(from.saturating_sub(1), to.saturating_sub(1)))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaZone
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Zone` userdata.
#[derive(Clone)]
pub struct LuaZone(pub Rc<RefCell<Zone>>);

impl LunaType for LuaZone {
    const TYPE_NAME: &'static str = "Zone";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Zone"];
}

impl LuaUserData for LuaZone {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the zone's name identifier.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the number of cards currently in this zone.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getSize", |_, this, ()| Ok(this.0.borrow().size()));
        /// Returns `true` if this zone holds no cards.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Returns the maximum number of cards this zone can hold (`0` = unlimited).
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getCapacity", |_, this, ()| Ok(this.0.borrow().capacity));
        /// Returns `true` if another card can be added (capacity not yet reached).
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canAdd", |_, this, ()| Ok(this.0.borrow().can_add()));

        /// Adds `card` to this zone. Raises an error if the zone is at capacity.
        ///
        /// # Parameters
        /// - `card` — `Card`: Card to add.
        methods.add_method("add", |_, this, card: LuaAnyUserData| {
            let card_clone = card.borrow::<LuaCard>()?.0.borrow().clone();
            this.0.borrow_mut().add(card_clone).map_err(|_| {
                LuaError::RuntimeError("Zone is full".to_string())
            })?;
            Ok(())
        });
        /// Removes and returns the card at 1-based `index`.
        ///
        /// # Parameters
        /// - `index` — `integer`: 1-based position.
        ///
        /// # Returns
        /// `Card` or `nil`.
        methods.add_method("removeAt", |_, this, index: usize| {
            let removed = this.0.borrow_mut().remove_at(index.saturating_sub(1));
            Ok(removed.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });
        /// Returns the count of cards with the given type in this zone.
        ///
        /// # Parameters
        /// - `card_type` — `string`: Type to count.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("countByType", |_, this, card_type: String| {
            Ok(this.0.borrow().count_by_type(&card_type))
        });
        /// Returns a deduplicated list of all card type strings present in this zone.
        ///
        /// # Returns
        /// `table` of `string` type names.
        methods.add_method("getAllTypes", |lua, this, ()| {
            let types = this.0.borrow().get_all_types();
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() { t.set(i + 1, ct)?; }
            Ok(t)
        });
        /// Returns all cards of the given type in this zone.
        ///
        /// # Parameters
        /// - `card_type` — `string`: Type to search for.
        ///
        /// # Returns
        /// `table` of `Card` objects.
        methods.add_method("findByType", |_, this, ct: String| {
            let borrow = this.0.borrow();
            Ok(borrow.find_by_type(&ct).map(|i| i + 1))
        });
        /// Returns the full ordered list of cards in this zone.
        ///
        /// # Returns
        /// `table` of `Card` objects.
        methods.add_method("getCards", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, card) in borrow.cards.iter().enumerate() {
                t.set(i + 1, LuaCard(Rc::new(RefCell::new(card.clone()))))?;
            }
            Ok(t)
        });

        // moveCard: move card from this zone to another zone by index
        methods.add_method(
            "moveCard",
            |_, this, (index, target): (usize, LuaAnyUserData)| {
                let card = this.0.borrow_mut().remove_at(index.saturating_sub(1));
                if let Some(c) = card {
                    target
                        .borrow::<LuaZone>()?
                        .0
                        .borrow_mut()
                        .add(c)
                        .map_err(|_| LuaError::RuntimeError("Target zone is full".to_string()))?;
                    Ok(true)
                } else {
                    Ok(false)
                }
            },
        );
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaStackManager
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaStackManager(pub Rc<RefCell<StackManager>>);

impl LunaType for LuaStackManager {
    const TYPE_NAME: &'static str = "StackManager";
    const TYPE_HIERARCHY: &'static [&'static str] = &["StackManager"];
}

impl LuaUserData for LuaStackManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Places an effect or action on top of the stack.
        ///
        /// # Parameters
        /// - `kind` — `string`: Effect kind identifier.
        /// - `data` — `table`: Effect data table.
        methods.add_method("push", |_, this, kind: String| {
            this.0.borrow_mut().push(StackEntry::new(kind));
            Ok(())
        });
        /// Removes and returns the top effect from the stack, resolving it.
        ///
        /// # Returns
        /// `table` with `kind` and `data` fields, or `nil` if the stack is empty.
        methods.add_method("resolve", |lua, this, ()| {
            let entry = this.0.borrow_mut().resolve();
            if let Some(e) = entry {
                let t = lua.create_table()?;
                /// Kind on this StackManager.
                ///
                /// # Returns
                /// The result.
                t.set("kind", e.kind)?;
                for (k, v) in &e.data {
                    t.set(k.as_str(), v.as_str())?;
                }
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        /// Returns the top effect without resolving it.
        ///
        /// # Returns
        /// `table` with `kind` and `data` fields, or `nil`.
        methods.add_method("peek", |lua, this, ()| {
            let borrow = this.0.borrow();
            if let Some(e) = borrow.peek() {
                let t = lua.create_table()?;
                /// Kind on this StackManager.
                ///
                /// # Returns
                /// The result.
                t.set("kind", e.kind.clone())?;
                drop(borrow);
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        /// Returns `true` if the stack holds no pending effects.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Returns the number of effects currently on the stack.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getSize", |_, this, ()| Ok(this.0.borrow().size()));
        /// Discards all pending effects on the stack.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });
        /// Returns all effects on the stack matching the given kind identifier.
        ///
        /// # Parameters
        /// - `kind` — `string`: Effect kind to search for.
        ///
        /// # Returns
        /// `table` of effect tables.
        methods.add_method("findByKind", |_, this, kind: String| {
            let borrow = this.0.borrow();
            Ok(borrow.find_by_kind(&kind).map(|i| i + 1))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaDeckBuilder
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaDeckBuilder(pub Rc<RefCell<DeckBuilder>>);

impl LunaType for LuaDeckBuilder {
    const TYPE_NAME: &'static str = "DeckBuilder";
    const TYPE_HIERARCHY: &'static [&'static str] = &["DeckBuilder"];
}

impl LuaUserData for LuaDeckBuilder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Sets the min cards.
        ///
        /// # Parameters
        /// - `v` — `integer`.
        methods.add_method("setMinCards", |_, this, v: usize| {
            this.0.borrow_mut().min_cards = v;
            Ok(())
        });
        /// Returns the min cards.
        ///
        /// # Parameters
        /// - `v` — `integer`.
        ///
        /// # Returns
        /// The current min cards.
        methods.add_method("getMinCards", |_, this, ()| Ok(this.0.borrow().min_cards));
        /// Sets the max cards.
        ///
        /// # Parameters
        /// - `v` — `integer`.
        methods.add_method("setMaxCards", |_, this, v: usize| {
            this.0.borrow_mut().max_cards = v;
            Ok(())
        });
        /// Returns the max cards.
        ///
        /// # Parameters
        /// - `v` — `integer`.
        ///
        /// # Returns
        /// The current max cards.
        methods.add_method("getMaxCards", |_, this, ()| Ok(this.0.borrow().max_cards));
        /// Sets the max copies.
        ///
        /// # Parameters
        /// - `v` — `integer`.
        methods.add_method("setMaxCopies", |_, this, v: usize| {
            this.0.borrow_mut().max_copies = v;
            Ok(())
        });
        /// Returns the max copies.
        ///
        /// # Parameters
        /// - `ct` — `string`.
        ///
        /// # Returns
        /// The current max copies.
        methods.add_method("getMaxCopies", |_, this, ()| Ok(this.0.borrow().max_copies));
        /// Adds required type to the collection.
        ///
        /// # Parameters
        /// - `ct` — `string`.
        methods.add_method("addRequiredType", |_, this, ct: String| {
            this.0.borrow_mut().required_types.push(ct);
            Ok(())
        });
        /// Adds banned type to the collection.
        ///
        /// # Parameters
        /// - `ct` — `string`.
        methods.add_method("addBannedType", |_, this, ct: String| {
            this.0.borrow_mut().banned_types.push(ct);
            Ok(())
        });
        /// Validate on this DeckBuilder.
        ///
        /// # Parameters
        /// - `deck` — `userdata`.
        methods.add_method("validate", |lua, this, deck: LuaAnyUserData| {
            let deck_borrow = deck.borrow::<LuaDeck>()?;
            let deck_inner = deck_borrow.0.borrow();
            let errors = this.0.borrow().validate(&deck_inner);
            let t = lua.create_sequence_from(errors.into_iter())?;
            Ok(t)
        });
        /// Returns `true` if valid.
        ///
        /// # Parameters
        /// - `deck` — `userdata`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isValid", |_, this, deck: LuaAnyUserData| {
            let deck_borrow = deck.borrow::<LuaDeck>()?;
            let deck_inner = deck_borrow.0.borrow();
            Ok(this.0.borrow().validate(&deck_inner).is_empty())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCardPool
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaCardPool(pub Rc<RefCell<CardPool>>);

impl LunaType for LuaCardPool {
    const TYPE_NAME: &'static str = "CardPool";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CardPool"];
}

impl LuaUserData for LuaCardPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the name.
        ///
        /// # Parameters
        /// - `ct` — `string`.
        /// - `weight` — `integer` optional.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Adds an entry to the collection.
        ///
        /// # Parameters
        /// - `ct` — `string`.
        /// - `weight` — `integer` optional.
        methods.add_method("add", |_, this, (ct, weight): (String, Option<u32>)| {
            this.0.borrow_mut().add(ct, weight.unwrap_or(1));
            Ok(())
        });
        /// Removes the entry from the collection.
        ///
        /// # Parameters
        /// - `ct` — `string`.
        methods.add_method("remove", |_, this, ct: String| {
            this.0.borrow_mut().remove(&ct);
            Ok(())
        });
        /// Returns the size.
        ///
        /// # Returns
        /// The current size.
        methods.add_method("getSize", |_, this, ()| Ok(this.0.borrow().size()));
        /// Returns the types.
        ///
        /// # Returns
        /// The current types.
        methods.add_method("getTypes", |lua, this, ()| {
            let types = this.0.borrow().get_types();
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() { t.set(i + 1, ct)?; }
            Ok(t)
        });
        /// Returns the total weight.
        ///
        /// # Parameters
        /// - `n` — `integer` optional.
        ///
        /// # Returns
        /// The current total weight.
        methods.add_method("getTotalWeight", |_, this, ()| {
            Ok(this.0.borrow().total_weight())
        });
        /// Draws to the current render target.
        ///
        /// # Parameters
        /// - `n` — `integer` optional.
        methods.add_method("draw", |lua, this, n: Option<usize>| {
            let drawn = this.0.borrow().draw(n.unwrap_or(1));
            let t = lua.create_sequence_from(drawn.into_iter())?;
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaPlayer
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Player` userdata.
#[derive(Clone)]
pub struct LuaPlayer(pub Rc<RefCell<Player>>);

impl LunaType for LuaPlayer {
    const TYPE_NAME: &'static str = "Player";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Player"];
}

impl LuaUserData for LuaPlayer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns this player's unique identifier.
        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        /// Returns this player's display name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets this player's display name.
        methods.add_method("setName", |_, this, name: String| {
            this.0.borrow_mut().name = name;
            Ok(())
        });
        /// Returns this player's current score.
        methods.add_method("getScore", |_, this, ()| Ok(this.0.borrow().score));
        /// Sets this player's score directly.
        methods.add_method("setScore", |_, this, v: f64| {
            this.0.borrow_mut().set_score(v);
            Ok(())
        });
        /// Adds `delta` to this player's score and returns the new total.
        methods.add_method("addScore", |_, this, delta: f64| {
            Ok(this.0.borrow_mut().add_score(delta))
        });
        /// Returns the value of a named resource (`0` if not set).
        methods.add_method("getResource", |_, this, key: String| {
            Ok(this.0.borrow().get_resource(&key))
        });
        /// Sets a named resource to an exact value.
        methods.add_method("setResource", |_, this, (key, amount): (String, f64)| {
            this.0.borrow_mut().set_resource(key, amount);
            Ok(())
        });
        /// Adds `amount` to a named resource and returns the new value.
        methods.add_method("addResource", |_, this, (key, amount): (String, f64)| {
            Ok(this.0.borrow_mut().add_resource(key, amount))
        });
        /// Spends `amount` from a named resource.  Errors if insufficient.
        methods.add_method("spendResource", |_, this, (key, amount): (String, f64)| {
            this.0.borrow_mut().spend_resource(&key, amount)
                .map_err(LuaError::RuntimeError)
        });
        /// Returns all resources as a `{name: amount}` table.
        methods.add_method("getAllResources", |lua, this, ()| {
            let t = lua.create_table()?;
            for (k, v) in this.0.borrow().get_all_resources() {
                t.set(k, v)?;
            }
            Ok(t)
        });
        /// Returns this player's status string.
        methods.add_method("getStatus", |_, this, ()| Ok(this.0.borrow().status.clone()));
        /// Sets this player's status string (user-defined).
        methods.add_method("setStatus", |_, this, s: String| {
            this.0.borrow_mut().status = s;
            Ok(())
        });
        /// Returns a metadata string value.
        methods.add_method("getMeta", |_, this, key: String| {
            Ok(this.0.borrow().get_meta(&key).map(String::from))
        });
        /// Sets a metadata string value.
        methods.add_method("setMeta", |_, this, (k, v): (String, String)| {
            this.0.borrow_mut().set_meta(k, v);
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaScoreBoard
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `ScoreBoard` userdata.
#[derive(Clone)]
pub struct LuaScoreBoard(pub Rc<RefCell<ScoreBoard>>);

impl LunaType for LuaScoreBoard {
    const TYPE_NAME: &'static str = "ScoreBoard";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ScoreBoard"];
}

impl LuaUserData for LuaScoreBoard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Sets a player's score directly.
        methods.add_method("setScore", |_, this, (pid, score): (String, f64)| {
            this.0.borrow_mut().set_score(pid, score);
            Ok(())
        });
        /// Adds `delta` to a player's score and returns the new total.
        methods.add_method("addScore", |_, this, (pid, delta): (String, f64)| {
            Ok(this.0.borrow_mut().add_score(pid, delta))
        });
        /// Adds `delta` with a `label` to a player's score.
        methods.add_method("addScoreLabeled", |_, this, (pid, delta, label): (String, f64, String)| {
            Ok(this.0.borrow_mut().add_score_labeled(pid, delta, label))
        });
        /// Returns a player's current score (`0` if not on the board).
        methods.add_method("getScore", |_, this, pid: String| {
            Ok(this.0.borrow().get_score(&pid))
        });
        /// Resets a player's score to zero.
        methods.add_method("resetScore", |_, this, pid: String| {
            this.0.borrow_mut().reset_score(pid);
            Ok(())
        });
        /// Returns `{player_id, score}` pairs sorted descending by score.
        methods.add_method("ranking", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, (pid, score)) in this.0.borrow().ranking().into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("player_id", pid)?;
                entry.set("score", score)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
        /// Returns the player ID with the highest score, or `nil`.
        methods.add_method("leader", |_, this, ()| Ok(this.0.borrow().leader()));
        /// Returns the player ID with the lowest score, or `nil`.
        methods.add_method("trailer", |_, this, ()| Ok(this.0.borrow().trailer()));
        /// Returns `true` if two or more players share the top score.
        methods.add_method("isTied", |_, this, ()| Ok(this.0.borrow().is_tied()));
        /// Returns number of players on the board.
        methods.add_method("getPlayerCount", |_, this, ()| Ok(this.0.borrow().player_count()));
        /// Returns all player IDs on the board.
        methods.add_method("getPlayers", |lua, this, ()| {
            let t = lua.create_sequence_from(this.0.borrow().players().into_iter())?;
            Ok(t)
        });
        /// Returns scoring history for a player as a list of `{player_id, delta, new_score, label}` tables.
        methods.add_method("historyFor", |lua, this, pid: String| {
            let t = lua.create_table()?;
            for (i, e) in this.0.borrow().history_for(&pid).into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("player_id", e.player_id.clone())?;
                entry.set("delta", e.delta)?;
                entry.set("new_score", e.new_score)?;
                entry.set("label", e.label.clone())?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaResourcePool
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `ResourcePool` userdata.
#[derive(Clone)]
pub struct LuaResourcePool(pub Rc<RefCell<ResourcePool>>);

impl LunaType for LuaResourcePool {
    const TYPE_NAME: &'static str = "ResourcePool";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ResourcePool"];
}

impl LuaUserData for LuaResourcePool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the resource pool name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets a player's balance directly.
        methods.add_method("set", |_, this, (pid, amount): (String, f64)| {
            this.0.borrow_mut().set(pid, amount);
            Ok(())
        });
        /// Returns a player's balance (`0` if not set).
        methods.add_method("get", |_, this, pid: String| {
            Ok(this.0.borrow().get(&pid))
        });
        /// Adds `amount` to a player's balance and returns the new total.
        methods.add_method("add", |_, this, (pid, amount): (String, f64)| {
            Ok(this.0.borrow_mut().add(pid, amount))
        });
        /// Spends `amount` from a player's balance.  Errors if insufficient.
        methods.add_method("spend", |_, this, (pid, amount): (String, f64)| {
            this.0.borrow_mut().spend(&pid, amount).map_err(LuaError::RuntimeError)
        });
        /// Transfers `amount` from `from` to `to`.  Errors if insufficient.
        methods.add_method("transfer", |_, this, (from, to, amount): (String, String, f64)| {
            this.0.borrow_mut().transfer(&from, &to, amount).map_err(LuaError::RuntimeError)
        });
        /// Returns the sum of all balances.
        methods.add_method("total", |_, this, ()| Ok(this.0.borrow().total()));
        /// Returns all `{player_id, amount}` pairs.
        methods.add_method("allBalances", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, (pid, amt)) in this.0.borrow().all_balances().into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("player_id", pid)?;
                entry.set("amount", amt)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaPot
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Pot` userdata.
#[derive(Clone)]
pub struct LuaPot(pub Rc<RefCell<Pot>>);

impl LunaType for LuaPot {
    const TYPE_NAME: &'static str = "Pot";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Pot"];
}

impl LuaUserData for LuaPot {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the current pot amount.
        methods.add_method("getAmount", |_, this, ()| Ok(this.0.borrow().amount));
        /// Adds `amount` directly to the pot.
        methods.add_method("contribute", |_, this, amount: f64| {
            this.0.borrow_mut().contribute(amount);
            Ok(())
        });
        /// Contributes from a `ResourcePool` player balance.  Errors if insufficient.
        methods.add_method("anteFrom", |_, this, (pool_ud, pid, amount): (LuaAnyUserData, String, f64)| {
            let pool_rc: Rc<RefCell<ResourcePool>> = { pool_ud.borrow::<LuaResourcePool>()?.0.clone() };
            let mut rp = pool_rc.borrow_mut();
            this.0.borrow_mut().ante_from(&mut rp, &pid, amount)
                .map_err(LuaError::RuntimeError)
        });
        /// Awards the entire pot to `player_id` in `pool`, clears the pot, returns amount won.
        methods.add_method("award", |_, this, (pool_ud, pid): (LuaAnyUserData, String)| {
            let pool_rc: Rc<RefCell<ResourcePool>> = { pool_ud.borrow::<LuaResourcePool>()?.0.clone() };
            let mut rp = pool_rc.borrow_mut();
            Ok(this.0.borrow_mut().award(&mut rp, pid))
        });
        /// Splits the pot evenly among `winners` (Lua sequence of player IDs).  Returns share per winner.
        methods.add_method("splitAward", |_, this, (pool_ud, winners_t): (LuaAnyUserData, LuaTable)| {
            let pool_rc: Rc<RefCell<ResourcePool>> = { pool_ud.borrow::<LuaResourcePool>()?.0.clone() };
            let mut winners: Vec<String> = Vec::new();
            for v in winners_t.sequence_values::<String>() { winners.push(v?); }
            let refs: Vec<&str> = winners.iter().map(String::as_str).collect();
            let mut rp = pool_rc.borrow_mut();
            Ok(this.0.borrow_mut().split_award(&mut rp, &refs))
        });
        /// Clears the pot without awarding anyone.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });
        /// Returns `true` if the pot holds nothing.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaTurnManager
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `TurnManager` userdata.
#[derive(Clone)]
pub struct LuaTurnManager(pub Rc<RefCell<TurnManager>>);

impl LunaType for LuaTurnManager {
    const TYPE_NAME: &'static str = "TurnManager";
    const TYPE_HIERARCHY: &'static [&'static str] = &["TurnManager"];
}

impl LuaUserData for LuaTurnManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the current active player ID, or `nil`.
        methods.add_method("currentPlayer", |_, this, ()| {
            Ok(this.0.borrow().current_player().map(String::from))
        });
        /// Returns the next player in turn order without advancing.
        methods.add_method("peekNext", |_, this, ()| {
            Ok(this.0.borrow().peek_next().map(String::from))
        });
        /// Advances to the next player's turn and returns the new active player ID.
        methods.add_method("advanceTurn", |_, this, ()| {
            Ok(this.0.borrow_mut().advance_turn())
        });
        /// Advances to the next phase.  When phases exhaust, turn advances automatically.
        methods.add_method("advancePhase", |_, this, ()| {
            Ok(this.0.borrow_mut().advance_phase())
        });
        /// Returns the current phase name, or `nil`.
        methods.add_method("currentPhase", |_, this, ()| {
            Ok(this.0.borrow().current_phase().map(String::from))
        });
        /// Jumps to a named phase.
        methods.add_method("setPhase", |_, this, phase: String| {
            this.0.borrow_mut().set_phase(&phase);
            Ok(())
        });
        /// Returns the current round number (1-based).
        methods.add_method("getRound", |_, this, ()| Ok(this.0.borrow().current_round()));
        /// Returns the total turns elapsed.
        methods.add_method("getTurn", |_, this, ()| Ok(this.0.borrow().current_turn()));
        /// Marks a player as skipped for this round.
        methods.add_method("skipPlayer", |_, this, pid: String| {
            this.0.borrow_mut().skip_player(&pid);
            Ok(())
        });
        /// Removes the skip mark from a player.
        methods.add_method("unskipPlayer", |_, this, pid: String| {
            this.0.borrow_mut().unskip_player(&pid);
            Ok(())
        });
        /// Returns `true` if `player_id` is currently skipped.
        methods.add_method("isSkipped", |_, this, pid: String| {
            Ok(this.0.borrow().is_skipped(&pid))
        });
        /// Returns the full player order as a list.
        methods.add_method("getPlayerOrder", |lua, this, ()| {
            let t = lua.create_sequence_from(this.0.borrow().player_order().iter().cloned())?;
            Ok(t)
        });
        /// Replaces the player order.
        methods.add_method("setOrder", |_, this, t: LuaTable| {
            let mut order = Vec::new();
            for v in t.sequence_values::<String>() { order.push(v?); }
            this.0.borrow_mut().set_order(order);
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaTrickState
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `TrickState` userdata.
#[derive(Clone)]
pub struct LuaTrickState(pub Rc<RefCell<TrickState>>);

impl LunaType for LuaTrickState {
    const TYPE_NAME: &'static str = "TrickState";
    const TYPE_HIERARCHY: &'static [&'static str] = &["TrickState"];
}

impl LuaUserData for LuaTrickState {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Sets the lead player for this trick.
        methods.add_method("setLead", |_, this, pid: String| {
            this.0.borrow_mut().set_lead(pid);
            Ok(())
        });
        /// Returns the lead player ID.
        methods.add_method("getLead", |_, this, ()| Ok(this.0.borrow().lead_player.clone()));
        /// Sets the trump suit/category (user-defined string).
        methods.add_method("setTrump", |_, this, trump: String| {
            this.0.borrow_mut().set_trump(trump);
            Ok(())
        });
        /// Clears the trump.
        methods.add_method("clearTrump", |_, this, ()| {
            this.0.borrow_mut().clear_trump();
            Ok(())
        });
        /// Returns the trump, or `nil`.
        methods.add_method("getTrump", |_, this, ()| Ok(this.0.borrow().trump.clone()));
        /// Records that `player_id` played `card`.
        methods.add_method("play", |_, this, (pid, card_ud): (String, LuaAnyUserData)| {
            let card = card_ud.borrow::<LuaCard>()?.0.borrow().clone();
            this.0.borrow_mut().play(pid, card);
            Ok(())
        });
        /// Returns `true` if `expected` players have played.
        methods.add_method("isComplete", |_, this, expected: usize| {
            Ok(this.0.borrow().is_complete(expected))
        });
        /// Returns number of cards played.
        methods.add_method("getSize", |_, this, ()| Ok(this.0.borrow().size()));
        /// Returns `true` if no cards have been played.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Clears all played cards.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });
        /// Returns all played slots as `{player_id, card}` tables.
        methods.add_method("getSlots", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, slot) in this.0.borrow().slots().iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("player_id", slot.player_id.clone())?;
                entry.set("card_type", slot.card.card_type.clone())?;
                entry.set("card", LuaCard(Rc::new(RefCell::new(slot.card.clone()))))?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
        /// Returns the card played by `player_id`, or `nil`.
        methods.add_method("slotFor", |lua, this, pid: String| {
            let borrow = this.0.borrow();
            if let Some(slot) = borrow.slot_for(&pid) {
                let entry = lua.create_table()?;
                entry.set("player_id", slot.player_id.clone())?;
                entry.set("card", LuaCard(Rc::new(RefCell::new(slot.card.clone()))))?;
                Ok(LuaValue::Table(entry))
            } else {
                Ok(LuaValue::Nil)
            }
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaTrickHistory
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `TrickHistory` userdata.
#[derive(Clone)]
pub struct LuaTrickHistory(pub Rc<RefCell<TrickHistory>>);

impl LunaType for LuaTrickHistory {
    const TYPE_NAME: &'static str = "TrickHistory";
    const TYPE_HIERARCHY: &'static [&'static str] = &["TrickHistory"];
}

impl LuaUserData for LuaTrickHistory {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Records that `player_id` won trick `n`.
        methods.add_method("record", |_, this, (trick, pid): (usize, String)| {
            this.0.borrow_mut().record(trick, pid);
            Ok(())
        });
        /// Returns how many tricks `player_id` has won.
        methods.add_method("countFor", |_, this, pid: String| {
            Ok(this.0.borrow().count_for(&pid))
        });
        /// Returns the most recent winner, or `nil`.
        methods.add_method("lastWinner", |_, this, ()| {
            Ok(this.0.borrow().last_winner().map(String::from))
        });
        /// Returns total tricks recorded.
        methods.add_method("total", |_, this, ()| Ok(this.0.borrow().total()));
        /// Returns `{player_id, count}` pairs sorted descending.
        methods.add_method("ranking", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, (pid, cnt)) in this.0.borrow().ranking().into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("player_id", pid)?;
                entry.set("count", cnt)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
        /// Clears all recorded tricks.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaEventLog
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `EventLog` userdata.
#[derive(Clone)]
pub struct LuaEventLog(pub Rc<RefCell<EventLog>>);

impl LunaType for LuaEventLog {
    const TYPE_NAME: &'static str = "EventLog";
    const TYPE_HIERARCHY: &'static [&'static str] = &["EventLog"];
}

impl LuaUserData for LuaEventLog {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Appends an event: `log(tag, {player, turn, round, key=value, ...})`.
        methods.add_method("log", |_, this, (tag, opts): (String, Option<LuaTable>)| {
            let mut ev = GameEvent::new(tag);
            if let Some(t) = opts {
                if let Ok(p) = t.get::<_, String>("player") { ev.player_id = p; }
                if let Ok(tn) = t.get::<_, usize>("turn") { ev.turn = tn; }
                if let Ok(r) = t.get::<_, usize>("round") { ev.round = r; }
                for pair in t.pairs::<String, String>() {
                    if let Ok((k, v)) = pair {
                        if k != "player" && k != "turn" && k != "round" {
                            ev.data.insert(k, v);
                        }
                    }
                }
            }
            this.0.borrow_mut().log(ev);
            Ok(())
        });
        /// Returns the number of recorded events.
        methods.add_method("getSize", |_, this, ()| Ok(this.0.borrow().len()));
        /// Returns `true` if empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Clears all events.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });
        /// Returns all events matching `tag` as a list of `{tag, turn, round, player, ...}` tables.
        methods.add_method("filterByTag", |lua, this, tag: String| {
            event_list_to_lua(lua, this.0.borrow().filter_by_tag(&tag))
        });
        /// Returns all events for `player_id`.
        methods.add_method("filterByPlayer", |lua, this, pid: String| {
            event_list_to_lua(lua, this.0.borrow().filter_by_player(&pid))
        });
        /// Returns all events from `round`.
        methods.add_method("filterByRound", |lua, this, round: usize| {
            event_list_to_lua(lua, this.0.borrow().filter_by_round(round))
        });
        /// Returns the most recent event, or `nil`.
        methods.add_method("last", |lua, this, ()| {
            let borrow = this.0.borrow();
            if let Some(ev) = borrow.last() {
                Ok(LuaValue::Table(game_event_to_lua(lua, ev)?))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        /// Returns all events as a list.
        methods.add_method("getAll", |lua, this, ()| {
            event_list_to_lua(lua, this.0.borrow().events().iter().collect())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaGameRules
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `GameRules` userdata.
#[derive(Clone)]
pub struct LuaGameRules(pub Rc<RefCell<GameRules>>);

impl LunaType for LuaGameRules {
    const TYPE_NAME: &'static str = "GameRules";
    const TYPE_HIERARCHY: &'static [&'static str] = &["GameRules"];
}

impl LuaUserData for LuaGameRules {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the list of phase names.
        methods.add_method("getPhases", |lua, this, ()| {
            let t = lua.create_sequence_from(this.0.borrow().phases.iter().cloned())?;
            Ok(t)
        });
        /// Sets the phase list.
        methods.add_method("setPhases", |_, this, t: LuaTable| {
            let mut phases = Vec::new();
            for v in t.sequence_values::<String>() { phases.push(v?); }
            this.0.borrow_mut().phases = phases;
            Ok(())
        });
        /// Returns the starting hand size.
        methods.add_method("getStartingHandSize", |_, this, ()| Ok(this.0.borrow().starting_hand_size));
        /// Sets the starting hand size.
        methods.add_method("setStartingHandSize", |_, this, v: usize| {
            this.0.borrow_mut().starting_hand_size = v;
            Ok(())
        });
        /// Returns the max hand size (`0` = unlimited).
        methods.add_method("getMaxHandSize", |_, this, ()| Ok(this.0.borrow().max_hand_size));
        /// Sets the max hand size.
        methods.add_method("setMaxHandSize", |_, this, v: usize| {
            this.0.borrow_mut().max_hand_size = v;
            Ok(())
        });
        /// Returns the max rounds (`0` = unlimited).
        methods.add_method("getMaxRounds", |_, this, ()| Ok(this.0.borrow().max_rounds));
        /// Sets the max rounds.
        methods.add_method("setMaxRounds", |_, this, v: usize| {
            this.0.borrow_mut().max_rounds = v;
            Ok(())
        });
        /// Returns whether mulligans are allowed.
        methods.add_method("getAllowMulligan", |_, this, ()| Ok(this.0.borrow().allow_mulligan));
        /// Sets whether mulligans are allowed.
        methods.add_method("setAllowMulligan", |_, this, v: bool| {
            this.0.borrow_mut().allow_mulligan = v;
            Ok(())
        });
        /// Returns the mulligan count.
        methods.add_method("getMulliganCount", |_, this, ()| Ok(this.0.borrow().mulligan_count));
        /// Sets the mulligan count.
        methods.add_method("setMulliganCount", |_, this, v: usize| {
            this.0.borrow_mut().mulligan_count = v;
            Ok(())
        });
        /// Gets a named string setting.
        methods.add_method("getSetting", |_, this, key: String| {
            Ok(this.0.borrow().get_setting(&key).map(String::from))
        });
        /// Sets a named string setting.
        methods.add_method("setSetting", |_, this, (k, v): (String, String)| {
            this.0.borrow_mut().set_setting(k, v);
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

fn game_event_to_lua<'lua>(lua: &'lua Lua, ev: &GameEvent) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    t.set("tag", ev.tag.clone())?;
    t.set("turn", ev.turn)?;
    t.set("round", ev.round)?;
    t.set("player", ev.player_id.clone())?;
    for (k, v) in &ev.data {
        t.set(k.as_str(), v.as_str())?;
    }
    Ok(t)
}

fn event_list_to_lua<'lua>(lua: &'lua Lua, events: Vec<&GameEvent>) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    for (i, ev) in events.into_iter().enumerate() {
        t.set(i + 1, game_event_to_lua(lua, ev)?)?;
    }
    Ok(t)
}

// ─────────────────────────────────────────────────────────────────────────────
// Register
// ─────────────────────────────────────────────────────────────────────────────

/// Register the `luna.cardgame.*` table.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    // Factory: Card
    module.set(
        "newCard",
        lua.create_function(|_, card_type: String| {
            Ok(LuaCard(Rc::new(RefCell::new(Card::new(card_type)))))
        })?,
    )?;

    // Factory: Deck
    module.set(
        "newDeck",
        lua.create_function(|_, name: Option<String>| {
            Ok(LuaDeck(Rc::new(RefCell::new(Deck::new(name.unwrap_or_default())))))
        })?,
    )?;

    // Factory: Zone
    module.set(
        "newZone",
        lua.create_function(|_, (name, capacity): (String, Option<usize>)| {
            Ok(LuaZone(Rc::new(RefCell::new(Zone::new(name, capacity.unwrap_or(0))))))
        })?,
    )?;

    // Factory: StackManager
    module.set(
        "newStackManager",
        lua.create_function(|_, ()| {
            Ok(LuaStackManager(Rc::new(RefCell::new(StackManager::new()))))
        })?,
    )?;

    // Factory: DeckBuilder
    module.set(
        "newDeckBuilder",
        lua.create_function(|_, ()| {
            Ok(LuaDeckBuilder(Rc::new(RefCell::new(DeckBuilder::new()))))
        })?,
    )?;

    // Factory: CardPool
    module.set(
        "newCardPool",
        lua.create_function(|_, name: Option<String>| {
            Ok(LuaCardPool(Rc::new(RefCell::new(CardPool::new(name.unwrap_or_default())))))
        })?,
    )?;

    // Card type registry
    module.set(
        "defineCardType",
        lua.create_function(|_, (name, opts): (String, Option<LuaTable>)| {
            let mut def = CardTypeDef::new(name.clone());
            if let Some(t) = opts {
                if let Ok(cat) = t.get::<_, String>("category") { def.category = cat; }
                if let Ok(n) = t.get::<_, String>("name") { def.name = n; }
                if let Ok(stats) = t.get::<_, LuaTable>("stats") {
                    for pair in stats.pairs::<String, f64>() {
                        let (k, v) = pair?;
                        def.stats.insert(k, v);
                    }
                }
                if let Ok(tags) = t.get::<_, LuaTable>("tags") {
                    for v in tags.sequence_values::<String>() {
                        def.tags.push(v?);
                    }
                }
            }
            define_card_type(name, def);
            Ok(())
        })?,
    )?;

    module.set(
        "getCardType",
        lua.create_function(|lua, name: String| {
            if let Some(def) = get_card_type(&name) {
                let t = lua.create_table()?;
                /// Name on this CardPool.
                ///
                /// # Returns
                /// The result.
                t.set("name", def.name.as_str())?;
                /// Category on this CardPool.
                ///
                /// # Returns
                /// The result.
                t.set("category", def.category.as_str())?;
                let st = lua.create_table()?;
                for (k, v) in &def.stats { st.set(k.as_str(), *v)?; }
                /// Stats on this CardPool.
                ///
                /// # Returns
                /// The result.
                t.set("stats", st)?;
                let tags = lua.create_table()?;
                for (i, tag) in def.tags.iter().enumerate() { tags.set(i+1, tag.as_str())?; }
                /// Tags on this CardPool.
                ///
                /// # Returns
                /// The result.
                t.set("tags", tags)?;
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        })?,
    )?;

    module.set(
        "getCardTypeNames",
        lua.create_function(|lua, ()| {
            let names = get_card_type_names();
            let t = lua.create_sequence_from(names.into_iter())?;
            Ok(t)
        })?,
    )?;

    module.set(
        "clearCardTypes",
        lua.create_function(|_, ()| { clear_card_types(); Ok(()) })?,
    )?;

    // ── New factories ──────────────────────────────────────────────────────

    // Factory: Player
    module.set(
        "newPlayer",
        lua.create_function(|_, (id, name): (String, Option<String>)| {
            let p = if let Some(n) = name {
                Player::with_name(id, n)
            } else {
                Player::new(id)
            };
            Ok(LuaPlayer(Rc::new(RefCell::new(p))))
        })?,
    )?;

    // Factory: ScoreBoard
    module.set(
        "newScoreBoard",
        lua.create_function(|_, ()| {
            Ok(LuaScoreBoard(Rc::new(RefCell::new(ScoreBoard::new()))))
        })?,
    )?;

    // Factory: ResourcePool
    module.set(
        "newResourcePool",
        lua.create_function(|_, name: Option<String>| {
            Ok(LuaResourcePool(Rc::new(RefCell::new(ResourcePool::new(name.unwrap_or_default())))))
        })?,
    )?;

    // Factory: Pot
    module.set(
        "newPot",
        lua.create_function(|_, ()| {
            Ok(LuaPot(Rc::new(RefCell::new(Pot::new()))))
        })?,
    )?;

    // Factory: TurnManager
    module.set(
        "newTurnManager",
        lua.create_function(|_, (players_t, phases_t): (LuaTable, Option<LuaTable>)| {
            let mut players: Vec<String> = Vec::new();
            for v in players_t.sequence_values::<String>() { players.push(v?); }
            let mut phases: Vec<String> = Vec::new();
            if let Some(t) = phases_t {
                for v in t.sequence_values::<String>() { phases.push(v?); }
            }
            Ok(LuaTurnManager(Rc::new(RefCell::new(TurnManager::new(players, phases)))))
        })?,
    )?;

    // Factory: TrickState
    module.set(
        "newTrickState",
        lua.create_function(|_, lead: Option<String>| {
            let mut ts = TrickState::new();
            if let Some(l) = lead { ts.set_lead(l); }
            Ok(LuaTrickState(Rc::new(RefCell::new(ts))))
        })?,
    )?;

    // Factory: TrickHistory
    module.set(
        "newTrickHistory",
        lua.create_function(|_, ()| {
            Ok(LuaTrickHistory(Rc::new(RefCell::new(TrickHistory::new()))))
        })?,
    )?;

    // Factory: EventLog
    module.set(
        "newEventLog",
        lua.create_function(|_, max_size: Option<usize>| {
            let log = if let Some(cap) = max_size {
                EventLog::with_capacity(cap)
            } else {
                EventLog::new()
            };
            Ok(LuaEventLog(Rc::new(RefCell::new(log))))
        })?,
    )?;

    // Factory: GameRules
    module.set(
        "newGameRules",
        lua.create_function(|_, ()| {
            Ok(LuaGameRules(Rc::new(RefCell::new(GameRules::default()))))
        })?,
    )?;

    // ── Hand evaluation free functions ─────────────────────────────────────

    /// Find all groups of exactly `n` cards sharing the same value of `stat`.
    module.set(
        "handFindNOfAKind",
        lua.create_function(|lua, (cards_t, stat, n): (LuaTable, String, usize)| {
            let cards = lua_table_to_cards(cards_t)?;
            let groups = find_n_of_a_kind(&cards, &stat, n);
            card_groups_to_lua(lua, &cards, groups)
        })?,
    )?;

    /// Find all groups of `n` or more cards sharing the same value of `stat`.
    module.set(
        "handFindAtLeastNOfAKind",
        lua.create_function(|lua, (cards_t, stat, n): (LuaTable, String, usize)| {
            let cards = lua_table_to_cards(cards_t)?;
            let groups = find_at_least_n_of_a_kind(&cards, &stat, n);
            card_groups_to_lua(lua, &cards, groups)
        })?,
    )?;

    /// Find consecutive runs (length >= `min_run`) sorted by `stat` value.
    module.set(
        "handFindSequences",
        lua.create_function(|lua, (cards_t, stat, min_run): (LuaTable, String, usize)| {
            let cards = lua_table_to_cards(cards_t)?;
            let groups = find_sequences(&cards, &stat, min_run);
            card_groups_to_lua(lua, &cards, groups)
        })?,
    )?;

    /// Find flush groups: runs of `min_size`+ cards with the same `tag_prefix` tag.
    module.set(
        "handFindFlushGroups",
        lua.create_function(|lua, (cards_t, tag_prefix, min_size): (LuaTable, String, usize)| {
            let cards = lua_table_to_cards(cards_t)?;
            let groups = find_flush_groups(&cards, &tag_prefix, min_size);
            card_groups_to_lua(lua, &cards, groups)
        })?,
    )?;

    luna.set("cardgame", module)?;
    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// Hand-eval Lua helpers
// ─────────────────────────────────────────────────────────────────────────────

fn lua_table_to_cards(t: LuaTable<'_>) -> LuaResult<Vec<Card>> {
    let mut cards = Vec::new();
    for v in t.sequence_values::<LuaAnyUserData>() {
        let ud = v?;
        let card = ud.borrow::<LuaCard>()?.0.borrow().clone();
        cards.push(card);
    }
    Ok(cards)
}

fn card_groups_to_lua<'lua>(lua: &'lua Lua, src: &[Card], groups: Vec<crate::cardgame::CardGroup>) -> LuaResult<LuaTable<'lua>> {
    let result = lua.create_table()?;
    for (i, group) in groups.into_iter().enumerate() {
        let g = lua.create_table()?;
        g.set("score", group.score)?;
        g.set("label", group.label)?;
        let cards_t = lua.create_table()?;
        for (j, &idx) in group.indices.iter().enumerate() {
            if let Some(card) = src.get(idx) {
                cards_t.set(j + 1, LuaCard(Rc::new(RefCell::new(card.clone()))))?;
            }
        }
        g.set("cards", cards_t)?;
        result.set(i + 1, g)?;
    }
    Ok(result)
}
