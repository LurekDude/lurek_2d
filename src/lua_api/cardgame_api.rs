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
        /// Returns the card type.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current card type.
        methods.add_method("getCardType", |_, this, ()| {
            Ok(this.0.borrow().card_type.clone())
        });
        /// Returns the name.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the name.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("setName", |_, this, name: String| {
            this.0.borrow_mut().name = name;
            Ok(())
        });
        /// Returns the category.
        ///
        /// # Parameters
        /// - `cat` — `string`.
        ///
        /// # Returns
        /// The current category.
        methods.add_method("getCategory", |_, this, ()| {
            Ok(this.0.borrow().category.clone())
        });
        /// Sets the category.
        ///
        /// # Parameters
        /// - `cat` — `string`.
        methods.add_method("setCategory", |_, this, cat: String| {
            this.0.borrow_mut().category = cat;
            Ok(())
        });

        // Stats
        /// Returns the stat.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `value` — `number`.
        ///
        /// # Returns
        /// The current stat.
        methods.add_method("getStat", |_, this, name: String| {
            Ok(this.0.borrow().get_stat(&name))
        });
        /// Sets the stat.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `value` — `number`.
        methods.add_method("setStat", |_, this, (name, value): (String, f64)| {
            this.0.borrow_mut().set_stat(name, value);
            Ok(())
        });
        /// Returns the stats.
        ///
        /// # Returns
        /// The current stats.
        methods.add_method("getStats", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (k, v) in &borrow.stats {
                t.set(k.as_str(), *v)?;
            }
            Ok(t)
        });

        // Tags
        /// Adds tag to the collection.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().add_tag(tag);
            Ok(())
        });
        /// Removes tag from the collection.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        methods.add_method("removeTag", |_, this, tag: String| {
            this.0.borrow_mut().remove_tag(&tag);
            Ok(())
        });
        /// Returns `true` if tag.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTag", |_, this, tag: String| {
            Ok(this.0.borrow().has_tag(&tag))
        });
        /// Returns the tags.
        ///
        /// # Parameters
        /// - `kind` — `string`.
        /// - `amount` — `integer`.
        ///
        /// # Returns
        /// The current tags.
        methods.add_method("getTags", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_sequence_from(borrow.tags.iter().cloned())?;
            Ok(t)
        });

        // Counters
        /// Adds counter to the collection.
        ///
        /// # Parameters
        /// - `kind` — `string`.
        /// - `amount` — `integer`.
        methods.add_method("addCounter", |_, this, (kind, amount): (String, i32)| {
            Ok(this.0.borrow_mut().add_counter(kind, amount))
        });
        /// Returns the counter.
        ///
        /// # Parameters
        /// - `kind` — `string`.
        ///
        /// # Returns
        /// The current counter.
        methods.add_method("getCounter", |_, this, kind: String| {
            Ok(this.0.borrow().get_counter(&kind))
        });
        /// Removes counters from the collection.
        ///
        /// # Parameters
        /// - `kind` — `string`.
        methods.add_method("removeCounters", |_, this, kind: String| {
            this.0.borrow_mut().remove_counters(&kind);
            Ok(())
        });

        // State flags
        /// Tap on this Card.
        ///
        /// # Returns
        /// The result.
        methods.add_method("tap", |_, this, ()| {
            this.0.borrow_mut().tap();
            Ok(())
        });
        /// Untap on this Card.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        methods.add_method("untap", |_, this, ()| {
            this.0.borrow_mut().untap();
            Ok(())
        });
        /// Returns `true` if tapped.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isTapped", |_, this, ()| Ok(this.0.borrow().tapped));
        /// Returns `true` if face up.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isFaceUp", |_, this, ()| Ok(this.0.borrow().face_up));
        /// Sets the face up.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        methods.add_method("setFaceUp", |_, this, v: bool| {
            this.0.borrow_mut().face_up = v;
            Ok(())
        });
        /// Returns the owner.
        ///
        /// # Parameters
        /// - `v` — `string`.
        ///
        /// # Returns
        /// The current owner.
        methods.add_method("getOwner", |_, this, ()| Ok(this.0.borrow().owner.clone()));
        /// Sets the owner.
        ///
        /// # Parameters
        /// - `v` — `string`.
        methods.add_method("setOwner", |_, this, v: String| {
            this.0.borrow_mut().owner = v;
            Ok(())
        });
        /// Returns the controller.
        ///
        /// # Parameters
        /// - `v` — `string`.
        ///
        /// # Returns
        /// The current controller.
        methods.add_method("getController", |_, this, ()| {
            Ok(this.0.borrow().controller.clone())
        });
        /// Sets the controller.
        ///
        /// # Parameters
        /// - `v` — `string`.
        methods.add_method("setController", |_, this, v: String| {
            this.0.borrow_mut().controller = v;
            Ok(())
        });
        /// Returns the zone.
        ///
        /// # Parameters
        /// - `key` — `string`.
        ///
        /// # Returns
        /// The current zone.
        methods.add_method("getZone", |_, this, ()| Ok(this.0.borrow().zone.clone()));

        // Metadata
        /// Returns the meta.
        ///
        /// # Parameters
        /// - `k` — `string`.
        /// - `v` — `string`.
        ///
        /// # Returns
        /// The current meta.
        methods.add_method("getMeta", |_, this, key: String| {
            let borrow = this.0.borrow();
            let val = borrow.get_meta(&key).map(String::from);
            drop(borrow);
            Ok(val)
        });
        /// Sets the meta.
        ///
        /// # Parameters
        /// - `k` — `string`.
        /// - `v` — `string`.
        methods.add_method("setMeta", |_, this, (k, v): (String, String)| {
            this.0.borrow_mut().set_meta(k, v);
            Ok(())
        });

        // Clone
        /// Returns the all counters.
        ///
        /// # Returns
        /// The current all counters.
        methods.add_method("getAllCounters", |lua, this, ()| {
            let counters = this.0.borrow().get_all_counters();
            let t = lua.create_table()?;
            for (kind, count) in counters {
                t.set(kind, count)?;
            }
            Ok(t)
        });
        /// Returns a deep copy of this object.
        ///
        /// # Returns
        /// The result.
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

        /// Returns the name.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the size.
        ///
        /// # Returns
        /// The current size.
        methods.add_method("getSize", |_, this, ()| Ok(this.0.borrow().size()));
        /// Returns `true` if empty.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Randomly reorders the collection.
        ///
        /// # Returns
        /// The result.
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
        /// Adds at to the collection.
        ///
        /// # Parameters
        /// - `card` — `userdata`.
        /// - `index` — `integer`.
        methods.add_method("insertAt", |_, this, (card, index): (LuaAnyUserData, usize)| {
            let card_clone = card.borrow::<LuaCard>()?.0.borrow().clone();
            this.0.borrow_mut().insert_at(index.saturating_sub(1), card_clone);
            Ok(())
        });

        // Drawing
        /// Draws to the current render target.
        ///
        /// # Returns
        /// The result.
        methods.add_method("draw", |_, this, ()| {
            let drawn = this.0.borrow_mut().draw();
            Ok(drawn.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });
        /// Draw bottom on this Deck.
        ///
        /// # Returns
        /// The result.
        methods.add_method("drawBottom", |_, this, ()| {
            let drawn = this.0.borrow_mut().draw_bottom();
            Ok(drawn.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });
        /// Peek on this Deck.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        methods.add_method("peek", |_, this, ()| {
            let borrow = this.0.borrow();
            let card = borrow.peek().cloned();
            drop(borrow);
            Ok(card.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });
        /// Removes at from the collection.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        methods.add_method("removeAt", |_, this, index: usize| {
            let removed = this.0.borrow_mut().remove_at(index.saturating_sub(1));
            Ok(removed.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });

        // Search
        /// Search by tag on this Deck.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        methods.add_method("searchByTag", |lua, this, tag: String| {
            let borrow = this.0.borrow();
            let indices = borrow.search_by_tag(&tag);
            let t = lua.create_sequence_from(indices.into_iter().map(|i| i + 1))?;
            Ok(t)
        });
        /// Search by type on this Deck.
        ///
        /// # Parameters
        /// - `ct` — `string`.
        methods.add_method("searchByType", |lua, this, ct: String| {
            let borrow = this.0.borrow();
            let indices = borrow.search_by_type(&ct);
            let t = lua.create_sequence_from(indices.into_iter().map(|i| i + 1))?;
            Ok(t)
        });

        // Get all cards as Lua table
        /// Returns the number of by type.
        ///
        /// # Parameters
        /// - `card_type` — `string`.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("countByType", |_, this, card_type: String| {
            Ok(this.0.borrow().count_by_type(&card_type))
        });
        /// Reveal top on this Deck.
        ///
        /// # Parameters
        /// - `n` — `integer`.
        methods.add_method("revealTop", |lua, this, n: usize| {
            let types = this.0.borrow().reveal_top(n);
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() { t.set(i + 1, ct)?; }
            Ok(t)
        });
        /// Returns the cards.
        ///
        /// # Returns
        /// The current cards.
        methods.add_method("getCards", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, card) in borrow.cards.iter().enumerate() {
                t.set(i + 1, LuaCard(Rc::new(RefCell::new(card.clone()))))?;
            }
            Ok(t)
        });

        /// Move within on this Deck.
        ///
        /// # Parameters
        /// - `from` — `integer`.
        /// - `to` — `integer`.
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

        /// Returns the name.
        ///
        /// # Parameters
        /// - `card` — `userdata`.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the size.
        ///
        /// # Parameters
        /// - `card` — `userdata`.
        ///
        /// # Returns
        /// The current size.
        methods.add_method("getSize", |_, this, ()| Ok(this.0.borrow().size()));
        /// Returns `true` if empty.
        ///
        /// # Parameters
        /// - `card` — `userdata`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Returns the capacity.
        ///
        /// # Parameters
        /// - `card` — `userdata`.
        ///
        /// # Returns
        /// The current capacity.
        methods.add_method("getCapacity", |_, this, ()| Ok(this.0.borrow().capacity));
        /// Returns `true` if add.
        ///
        /// # Parameters
        /// - `card` — `userdata`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canAdd", |_, this, ()| Ok(this.0.borrow().can_add()));

        /// Adds an entry to the collection.
        ///
        /// # Parameters
        /// - `card` — `userdata`.
        methods.add_method("add", |_, this, card: LuaAnyUserData| {
            let card_clone = card.borrow::<LuaCard>()?.0.borrow().clone();
            this.0.borrow_mut().add(card_clone).map_err(|_| {
                LuaError::RuntimeError("Zone is full".to_string())
            })?;
            Ok(())
        });
        /// Removes at from the collection.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        methods.add_method("removeAt", |_, this, index: usize| {
            let removed = this.0.borrow_mut().remove_at(index.saturating_sub(1));
            Ok(removed.map(|c| LuaCard(Rc::new(RefCell::new(c)))))
        });
        /// Returns the number of by type.
        ///
        /// # Parameters
        /// - `card_type` — `string`.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("countByType", |_, this, card_type: String| {
            Ok(this.0.borrow().count_by_type(&card_type))
        });
        /// Returns the all types.
        ///
        /// # Parameters
        /// - `ct` — `string`.
        ///
        /// # Returns
        /// The current all types.
        methods.add_method("getAllTypes", |lua, this, ()| {
            let types = this.0.borrow().get_all_types();
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() { t.set(i + 1, ct)?; }
            Ok(t)
        });
        /// Find by type on this Zone.
        ///
        /// # Parameters
        /// - `ct` — `string`.
        methods.add_method("findByType", |_, this, ct: String| {
            let borrow = this.0.borrow();
            Ok(borrow.find_by_type(&ct).map(|i| i + 1))
        });
        /// Returns the cards.
        ///
        /// # Returns
        /// The current cards.
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

        /// Adds an entry to the collection.
        ///
        /// # Parameters
        /// - `kind` — `string`.
        methods.add_method("push", |_, this, kind: String| {
            this.0.borrow_mut().push(StackEntry::new(kind));
            Ok(())
        });
        /// Resolve on this StackManager.
        ///
        /// # Returns
        /// The result.
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
        /// Peek on this StackManager.
        ///
        /// # Returns
        /// The result.
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
        /// Returns `true` if empty.
        ///
        /// # Parameters
        /// - `kind` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Returns the size.
        ///
        /// # Parameters
        /// - `kind` — `string`.
        ///
        /// # Returns
        /// The current size.
        methods.add_method("getSize", |_, this, ()| Ok(this.0.borrow().size()));
        /// Removes all entries.
        ///
        /// # Parameters
        /// - `kind` — `string`.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });
        /// Find by kind on this StackManager.
        ///
        /// # Parameters
        /// - `kind` — `string`.
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
