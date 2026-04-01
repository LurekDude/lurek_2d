//! Lua bindings for `luna.cardgame.*`.
//!
//! Exposes Card, Deck, Zone, StackManager, DeckBuilder, and CardPool to Lua.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::cardgame::{
    Card, CardPool, CardTypeDef, Deck, DeckBuilder, StackEntry, StackManager, Zone,
    clear_card_types, define_card_type, get_card_type, get_card_type_names,
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

    /// Cardgame on this CardPool.
    ///
    /// # Returns
    /// The result.
    luna.set("cardgame", module)?;
    Ok(())
}
