//! Lua bindings for `luna.cardgame.*`.
//!
//! Exposes Card, Stack, StackBuilder, StackManager, CardPool, Slot, StackHistory,
//! and group-analysis utilities to Lua scripts via the `luna.cardgame` namespace.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for cardgame api-related operations and data management.
//! Key types exported from this module: `LuaCard`, `LuaStack`, `LuaDeckBuilder`, `LuaZoneManager`, `LuaCardPool`.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::cardgame::{
    Card, CardTypeDef, Stack, DeckBuilder, BuildEntry, StackManager,
    CardPool, Slot, StackHistory,
    define_card_type, get_card_type, get_card_type_names, clear_card_types,
    group_by_stat, group_by_category, group_by_tag_prefix,
    find_n_of_stat, find_at_least_n_of_stat, find_sequences, find_tag_groups,
};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ─────────────────────────────────────────────────────────────────────────────
// LuaItem
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Card` userdata with per-instance script and asset storage.
///
/// # Fields
/// - `inner` — `Rc<RefCell<Card>>`.
/// - `s` — `event \u2192 function (stored via registry key).`.
/// - `scripts` — `Rc<RefCell<std::collections::HashMap<String`.
/// - `e` — `key \u2192 value (stored via registry key).`.
/// - `assets` — `Rc<RefCell<std::collections::HashMap<String`.
/// - `cost_check` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `cost_pay` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
pub struct LuaCard {
    /// The underlying card data.
    pub inner: Rc<RefCell<Card>>,
    /// Per-instance script hooks: event \u2192 function (stored via registry key).
    pub scripts: Rc<RefCell<std::collections::HashMap<String, LuaRegistryKey>>>,
    /// Per-instance asset storage: key \u2192 value (stored via registry key).
    pub assets: Rc<RefCell<std::collections::HashMap<String, LuaRegistryKey>>>,
    /// Optional cost-check function override.
    pub cost_check: Rc<RefCell<Option<LuaRegistryKey>>>,
    /// Optional cost-pay function override.
    pub cost_pay: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl Clone for LuaCard {
    fn clone(&self) -> Self {
        LuaCard {
            inner: Rc::clone(&self.inner),
            scripts: Rc::clone(&self.scripts),
            assets: Rc::clone(&self.assets),
            cost_check: Rc::clone(&self.cost_check),
            cost_pay: Rc::clone(&self.cost_pay),
        }
    }
}

/// Create a fresh LuaCard wrapping a card with empty script/asset storage.
fn lua_card_new(card: Card) -> LuaCard {
    LuaCard {
        inner: Rc::new(RefCell::new(card)),
        scripts: Rc::new(RefCell::new(std::collections::HashMap::new())),
        assets: Rc::new(RefCell::new(std::collections::HashMap::new())),
        cost_check: Rc::new(RefCell::new(None)),
        cost_pay: Rc::new(RefCell::new(None)),
    }
}

impl LunaType for LuaCard {
    const TYPE_NAME: &'static str = "Card";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Card"];
}

impl LuaUserData for LuaCard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the type identifier string for this card.
        /// @return any
        methods.add_method("getCardType", |_, this, ()| {
            Ok(this.inner.borrow().card_type.clone())
        });
        /// Returns the display name of this card.
        /// @return any
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });
        /// Sets the card's display name.
        /// @param name : string
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().name = name; Ok(())
        });
        /// Returns the category string.
        /// @return any
        methods.add_method("getCategory", |_, this, ()| {
            Ok(this.inner.borrow().category.clone())
        });
        /// Sets the category string.
        /// @param cat : string
        methods.add_method("setCategory", |_, this, cat: String| {
            this.inner.borrow_mut().category = cat; Ok(())
        });
        /// Returns the owner identifier.
        /// @return any
        methods.add_method("getOwner", |_, this, ()| {
            Ok(this.inner.borrow().owner.clone())
        });
        /// Sets the owner identifier.
        /// @param owner : string
        methods.add_method("setOwner", |_, this, owner: String| {
            this.inner.borrow_mut().owner = owner; Ok(())
        });
        /// Returns the current slot identifier.
        /// @return any
        methods.add_method("getSlot", |_, this, ()| {
            Ok(this.inner.borrow().slot.clone())
        });
        /// Sets the current slot identifier.
        /// @param slot : string
        methods.add_method("setSlot", |_, this, slot: String| {
            this.inner.borrow_mut().slot = slot; Ok(())
        });

        // ── Subtype / Rarity / Controller ──────────────────────────────────
        /// Returns the subtype string.
        /// @return any
        methods.add_method("getSubtype", |_, this, ()| {
            Ok(this.inner.borrow().subtype.clone())
        });
        /// Sets the subtype string.
        /// @param s : string
        methods.add_method("setSubtype", |_, this, s: String| {
            this.inner.borrow_mut().subtype = s; Ok(())
        });
        /// Returns the rarity tier string.
        /// @return any
        methods.add_method("getRarity", |_, this, ()| {
            Ok(this.inner.borrow().rarity.clone())
        });
        /// Sets the rarity tier string.
        /// @param r : string
        methods.add_method("setRarity", |_, this, r: String| {
            this.inner.borrow_mut().rarity = r; Ok(())
        });
        /// Returns the controller identifier (may differ from owner).
        /// @return any
        methods.add_method("getController", |_, this, ()| {
            Ok(this.inner.borrow().controller.clone())
        });
        /// Sets the controller identifier.
        /// @param c : string
        methods.add_method("setController", |_, this, c: String| {
            this.inner.borrow_mut().controller = c; Ok(())
        });

        // ── Face-up / Tapped state ─────────────────────────────────────────
        /// Returns `true` if the card is face-up.
        /// @return any
        methods.add_method("isFaceUp", |_, this, ()| {
            Ok(this.inner.borrow().face_up)
        });
        /// Sets face-up state.
        /// @param v : boolean
        methods.add_method("setFaceUp", |_, this, v: bool| {
            this.inner.borrow_mut().face_up = v; Ok(())
        });
        /// Returns `true` if the card is tapped/exhausted.
        /// @return any
        methods.add_method("isTapped", |_, this, ()| {
            Ok(this.inner.borrow().tapped)
        });
        /// Sets tapped/exhausted state.
        /// @param v : boolean
        methods.add_method("setTapped", |_, this, v: bool| {
            this.inner.borrow_mut().tapped = v; Ok(())
        });

        // ── Tile position (board-based games) ──────────────────────────────
        /// Returns tile position as (x, y).
        /// @return any
        methods.add_method("getTilePosition", |_, this, ()| {
            let c = this.inner.borrow();
            Ok((c.tile_x, c.tile_y))
        });
        /// Sets tile position.
        /// @param x : integer
        /// @param y : integer
        methods.add_method("setTilePosition", |_, this, (x, y): (i32, i32)| {
            let mut c = this.inner.borrow_mut();
            c.tile_x = x; c.tile_y = y; Ok(())
        });
        /// Returns tile footprint as (w, h).
        /// @return any
        methods.add_method("getTileSize", |_, this, ()| {
            let c = this.inner.borrow();
            Ok((c.tile_w, c.tile_h))
        });
        /// Sets tile footprint.
        /// @param w : integer
        /// @param h : integer
        methods.add_method("setTileSize", |_, this, (w, h): (i32, i32)| {
            let mut c = this.inner.borrow_mut();
            c.tile_w = w; c.tile_h = h; Ok(())
        });

        // ── Reset / Clone ──────────────────────────────────────────────────
        /// Resets all stats to the card type defaults.
        methods.add_method("resetStats", |_, this, ()| {
            this.inner.borrow_mut().reset_stats(); Ok(())
        });
        /// Deep-copies the card (new instance, same stats/tags/counters).
        /// @return Card
        methods.add_method("clone", |_, this, ()| {
            Ok(lua_card_new(this.inner.borrow().clone()))
        });

        // ── Stats ──────────────────────────────────────────────────────────
        /// Returns the value of a named numeric stat (0 if absent).
        /// @param name : string
        /// @return any
        methods.add_method("getStat", |_, this, name: String| {
            Ok(this.inner.borrow().get_stat(&name))
        });
        /// Sets a named numeric stat.
        /// @param name : string
        /// @param value : number
        methods.add_method("setStat", |_, this, (name, value): (String, f64)| {
            this.inner.borrow_mut().set_stat(name, value); Ok(())
        });
        /// Adds `delta` to a named stat (creates it at `delta` if absent).
        /// @param name : string
        /// @param delta : number
        methods.add_method("addStat", |_, this, (name, delta): (String, f64)| {
            this.inner.borrow_mut().add_stat(&name, delta); Ok(())
        });
        /// Returns all stats as a `{key=value}` table.
        /// @return table
        methods.add_method("getStats", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (k, v) in &this.inner.borrow().stats { tbl.set(k.clone(), *v)?; }
            Ok(tbl)
        });

        // ── Tags ───────────────────────────────────────────────────────────
        /// Returns `true` if the card has the given tag.
        /// @param tag : string
        /// @return any
        methods.add_method("hasTag", |_, this, tag: String| {
            Ok(this.inner.borrow().has_tag(&tag))
        });
        /// Adds a tag if not already present.
        /// @param tag : string
        methods.add_method("addTag", |_, this, tag: String| {
            this.inner.borrow_mut().add_tag(tag); Ok(())
        });
        /// Removes a tag.
        /// @param tag : string
        methods.add_method("removeTag", |_, this, tag: String| {
            this.inner.borrow_mut().remove_tag(&tag); Ok(())
        });
        /// Returns all tags as an array table.
        /// @return table
        methods.add_method("getTags", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, t) in this.inner.borrow().tags.iter().enumerate() {
                tbl.set(i + 1, t.clone())?;
            }
            Ok(tbl)
        });

        // ── Counters ───────────────────────────────────────────────────────
        /// Returns an integer counter (0 if absent).
        /// @param name : string
        /// @return any
        methods.add_method("getCounter", |_, this, name: String| {
            Ok(this.inner.borrow().get_counter(&name))
        });
        /// Sets an integer counter.
        /// @param name : string
        /// @param value : integer
        methods.add_method("setCounter", |_, this, (name, value): (String, i32)| {
            this.inner.borrow_mut().set_counter(name, value); Ok(())
        });
        /// Adds `delta` to a counter.
        /// @param name : string
        /// @param delta : integer
        methods.add_method("addCounter", |_, this, (name, delta): (String, i32)| {
            this.inner.borrow_mut().add_counter(&name, delta); Ok(())
        });

        // ── Metadata ──────────────────────────────────────────────────────
        /// Returns a metadata string value (empty string if absent).
        /// @param key : string
        /// @return any
        methods.add_method("getMeta", |_, this, key: String| {
            Ok(this.inner.borrow().get_meta(&key).unwrap_or_default().to_string())
        });
        /// Sets a metadata string value.
        /// @param key : string
        /// @param value : string
        methods.add_method("setMeta", |_, this, (key, value): (String, String)| {
            this.inner.borrow_mut().set_meta(key, value); Ok(())
        });
        /// Returns all metadata as a `{key=value}` table.
        /// @return table
        methods.add_method("getAllMeta", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (k, v) in &this.inner.borrow().metadata { tbl.set(k.clone(), v.clone())?; }
            Ok(tbl)
        });

        // ── Additional stat helpers ────────────────────────────────────────
        /// Returns `true` if the named stat is explicitly set.
        /// @param name : string
        /// @return any
        methods.add_method("hasStat", |_, this, name: String| {
            Ok(this.inner.borrow().stats.contains_key(&name))
        });
        /// Adds `delta` to a stat and returns the new value.
        /// @param name : string
        /// @param delta : number
        /// @return any
        methods.add_method("modifyStat", |_, this, (name, delta): (String, f64)| {
            Ok(this.inner.borrow_mut().add_stat(name, delta))
        });
        /// Returns all stats as a `{key=value}` table.
        /// @return table
        methods.add_method("getStats", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (k, v) in &this.inner.borrow().stats { tbl.set(k.clone(), *v)?; }
            Ok(tbl)
        });

        // ── Counter helpers ────────────────────────────────────────────────
        /// Returns all counters as a `{key=value}` table.
        /// @return table
        methods.add_method("getCounters", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (k, v) in &this.inner.borrow().counters { tbl.set(k.clone(), *v)?; }
            Ok(tbl)
        });
        /// Clears all counters.
        methods.add_method("clearCounters", |_, this, ()| {
            this.inner.borrow_mut().counters.clear(); Ok(())
        });
        /// Adds `delta` to a counter and returns the new value.
        /// @param name : string
        /// @param delta : integer
        /// @return any
        methods.add_method("modifyCounter", |_, this, (name, delta): (String, i32)| {
            Ok(this.inner.borrow_mut().add_counter(name, delta))
        });

        // ── Zone / slot alias ─────────────────────────────────────────────
        /// Returns the current zone/slot string.
        /// @return any
        methods.add_method("getZone", |_, this, ()| {
            Ok(this.inner.borrow().slot.clone())
        });
        /// Sets the current zone/slot string.
        /// @param zone : string
        methods.add_method("setZone", |_, this, zone: String| {
            this.inner.borrow_mut().slot = zone; Ok(())
        });

        // ── Instance scripts ───────────────────────────────────────────────
        /// Sets a per-instance script hook: `setScript("onPlay", function(card) ... end)`.
        /// @param event : string
        /// @param func : function
        methods.add_method("setScript", |lua, this, (event, func): (String, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            this.scripts.borrow_mut().insert(event, key);
            Ok(())
        });
        /// Returns the script function for an event, or `nil`.
        /// @param event : string
        /// @return any
        methods.add_method("getScript", |lua, this, event: String| {
            if let Some(key) = this.scripts.borrow().get(&event) {
                let f: LuaFunction = lua.registry_value(key)?;
                Ok(LuaValue::Function(f))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        /// Fires a named script hook with optional extra arguments.
        /// @param event : string
        /// @param args : MultiValue
        /// @return any
        ///
        /// Looks up the instance script first; if not set, looks up the type-level
        /// script in the global `_LUNA_CG_SCRIPTS[card_type][event]` table.
        methods.add_method("fireScript", |lua, this, (event, args): (String, LuaMultiValue)| {
            // Try instance script first
            let maybe_key = {
                if let Some(k) = this.scripts.borrow().get(&event) {
                    Some(lua.registry_value::<LuaFunction>(k)?)
                } else {
                    None
                }
            };
            if let Some(func) = maybe_key {
                return func.call::<_, LuaMultiValue>(args);
            }
            // Try type-level script
            let card_type = this.inner.borrow().card_type.clone();
            let scripts_tbl: Option<LuaTable> = lua
                .globals()
                .get::<_, Option<LuaTable>>("_LUNA_CG_SCRIPTS")?
                .and_then(|t| t.get::<_, Option<LuaTable>>(card_type).ok().flatten());
            if let Some(tbl) = scripts_tbl {
                if let Ok(func) = tbl.get::<_, LuaFunction>(event) {
                    return func.call::<_, LuaMultiValue>(args);
                }
            }
            Ok(LuaMultiValue::new())
        });

        // ── Cost system ────────────────────────────────────────────────────
        /// Sets a custom cost-check function: `setCostCheck(function(card, ctx) return bool end)`.
        /// @param func : function
        methods.add_method("setCostCheck", |lua, this, func: LuaFunction| {
            let key = lua.create_registry_value(func)?;
            *this.cost_check.borrow_mut() = Some(key);
            Ok(())
        });
        /// Sets a custom cost-pay function.
        /// @param func : function
        methods.add_method("setCostPay", |lua, this, func: LuaFunction| {
            let key = lua.create_registry_value(func)?;
            *this.cost_pay.borrow_mut() = Some(key);
            Ok(())
        });
        /// Returns whether this card can be played.  Calls cost_check if set; returns `true` otherwise.
        /// @param ctx : any
        /// @return boolean
        methods.add_method("canPlay", |lua, this, ctx: LuaValue| {
            if let Some(key) = this.cost_check.borrow().as_ref() {
                let f: LuaFunction = lua.registry_value(key)?;
                return f.call::<_, bool>((lua_card_new(this.inner.borrow().clone()), ctx));
            }
            Ok(true)
        });
        /// Pays the card's cost.  Calls cost_pay if set; no-op otherwise.
        /// @param ctx : any
        methods.add_method("payCost", |lua, this, ctx: LuaValue| {
            if let Some(key) = this.cost_pay.borrow().as_ref() {
                let f: LuaFunction = lua.registry_value(key)?;
                f.call::<_, ()>((lua_card_new(this.inner.borrow().clone()), ctx))?;
            }
            Ok(())
        });

        // ── Asset storage ─────────────────────────────────────────────────
        /// Stores an arbitrary Lua value under `key`.
        /// @param key : string
        /// @param value : any
        methods.add_method("setAsset", |lua, this, (key, value): (String, LuaValue)| {
            let reg_key = lua.create_registry_value(value)?;
            this.assets.borrow_mut().insert(key, reg_key);
            Ok(())
        });
        /// Retrieves an asset value, or `nil` if not set.
        /// @param key : string
        /// @return any
        methods.add_method("getAsset", |lua, this, key: String| {
            if let Some(k) = this.assets.borrow().get(&key) {
                lua.registry_value::<LuaValue>(k)
            } else {
                Ok(LuaValue::Nil)
            }
        });

        // ── Snapshot / Restore ────────────────────────────────────────────
        /// Serializes this card to a Lua table (data fields only, no functions).
        /// @return table
        methods.add_method("snapshot", |lua, this, ()| {
            let c = this.inner.borrow();
            let tbl = lua.create_table()?;
            tbl.set("id", c.id)?;
            tbl.set("cardType", c.card_type.clone())?;
            tbl.set("name", c.name.clone())?;
            tbl.set("category", c.category.clone())?;
            tbl.set("subtype", c.subtype.clone())?;
            tbl.set("rarity", c.rarity.clone())?;
            tbl.set("owner", c.owner.clone())?;
            tbl.set("controller", c.controller.clone())?;
            tbl.set("slot", c.slot.clone())?;
            tbl.set("faceUp", c.face_up)?;
            tbl.set("tapped", c.tapped)?;
            tbl.set("tileX", c.tile_x)?;
            tbl.set("tileY", c.tile_y)?;
            tbl.set("tileW", c.tile_w)?;
            tbl.set("tileH", c.tile_h)?;
            let stats = lua.create_table()?;
            for (k, v) in &c.stats { stats.set(k.clone(), *v)?; }
            tbl.set("stats", stats)?;
            let tags = lua.create_table()?;
            for (i, t) in c.tags.iter().enumerate() { tags.set(i + 1, t.clone())?; }
            tbl.set("tags", tags)?;
            let counters = lua.create_table()?;
            for (k, v) in &c.counters { counters.set(k.clone(), *v)?; }
            tbl.set("counters", counters)?;
            let meta = lua.create_table()?;
            for (k, v) in &c.metadata { meta.set(k.clone(), v.clone())?; }
            tbl.set("meta", meta)?;
            Ok(tbl)
        });
        /// Restores data fields from a snapshot table (as returned by `snapshot()`).
        /// @param snap : table
        methods.add_method("restore", |_, this, snap: LuaTable| {
            let mut c = this.inner.borrow_mut();
            if let Ok(v) = snap.get::<_, String>("cardType") { c.card_type = v; }
            if let Ok(v) = snap.get::<_, String>("name") { c.name = v; }
            if let Ok(v) = snap.get::<_, String>("category") { c.category = v; }
            if let Ok(v) = snap.get::<_, String>("subtype") { c.subtype = v; }
            if let Ok(v) = snap.get::<_, String>("rarity") { c.rarity = v; }
            if let Ok(v) = snap.get::<_, String>("owner") { c.owner = v; }
            if let Ok(v) = snap.get::<_, String>("controller") { c.controller = v; }
            if let Ok(v) = snap.get::<_, String>("slot") { c.slot = v; }
            if let Ok(v) = snap.get::<_, bool>("faceUp") { c.face_up = v; }
            if let Ok(v) = snap.get::<_, bool>("tapped") { c.tapped = v; }
            if let Ok(v) = snap.get::<_, i32>("tileX") { c.tile_x = v; }
            if let Ok(v) = snap.get::<_, i32>("tileY") { c.tile_y = v; }
            if let Ok(v) = snap.get::<_, i32>("tileW") { c.tile_w = v; }
            if let Ok(v) = snap.get::<_, i32>("tileH") { c.tile_h = v; }
            if let Ok(stats) = snap.get::<_, LuaTable>("stats") {
                c.stats.clear();
                for (k, v) in stats.pairs::<String, f64>().flatten() { c.stats.insert(k, v); }
            }
            if let Ok(tags) = snap.get::<_, LuaTable>("tags") {
                c.tags.clear();
                for t in tags.sequence_values::<String>().flatten() { c.tags.push(t); }
            }
            if let Ok(counters) = snap.get::<_, LuaTable>("counters") {
                c.counters.clear();
                for (k, v) in counters.pairs::<String, i32>().flatten() { c.counters.insert(k, v); }
            }
            if let Ok(meta) = snap.get::<_, LuaTable>("meta") {
                c.metadata.clear();
                for (k, v) in meta.pairs::<String, String>().flatten() { c.metadata.insert(k, v); }
            }
            Ok(())
        });
        /// Returns the unique instance ID of this card.
        /// @return any
        methods.add_method("getId", |_, this, ()| {
            Ok(this.inner.borrow().id)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaStack
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Stack` userdata. Consult the module-level documentation for the broader usage context and preconditions.
#[derive(Clone)]
pub struct LuaStack(pub Rc<RefCell<Stack>>);

impl LunaType for LuaStack {
    const TYPE_NAME: &'static str = "CardStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CardStack"];
}

impl LuaUserData for LuaStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the name.
        ///
        /// @return any
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the number of items.
        ///
        /// @return integer
        methods.add_method("size", |_, this, ()| Ok(this.0.borrow().size()));
        /// Returns true if empty.
        ///
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Returns true if full.
        ///
        /// @return boolean
        methods.add_method("isFull", |_, this, ()| Ok(this.0.borrow().is_full()));
        /// Capacity.
        ///
        /// @return any
        methods.add_method("capacity", |_, this, ()| {
            Ok(this.0.borrow().capacity().map(|c| c as u64))
        });

        // ── Zone Properties ────────────────────────────────────────────────
        /// Returns true if this zone preserves insertion order.
        /// @return any
        methods.add_method("isOrdered", |_, this, ()| {
            Ok(this.0.borrow().is_ordered())
        });
        /// Sets whether this zone preserves insertion order.
        /// @param v : boolean
        methods.add_method("setOrdered", |_, this, v: bool| {
            this.0.borrow_mut().set_ordered(v); Ok(())
        });
        /// Returns true if cards in this zone are visible to all players.
        /// @return any
        methods.add_method("isPublic", |_, this, ()| {
            Ok(this.0.borrow().is_public())
        });
        /// Sets whether cards are visible to all players.
        /// @param v : boolean
        methods.add_method("setPublic", |_, this, v: bool| {
            this.0.borrow_mut().set_public(v); Ok(())
        });

        /// Pushes a `LuaItem` onto the top of the stack.
        /// @param card : Card
        methods.add_method("push", |_, this, card: LuaAnyUserData| {
            let card_inner = card.borrow::<LuaCard>()?.inner.borrow().clone();
            if !this.0.borrow_mut().push_top(card_inner) {
                Err(LuaError::runtime("stack is full"))
            } else { Ok(()) }
        });
        /// Pushes a `LuaItem` to the bottom of the stack.
        /// @param card : Card
        methods.add_method("pushBottom", |_, this, card: LuaAnyUserData| {
            let card_inner = card.borrow::<LuaCard>()?.inner.borrow().clone();
            if !this.0.borrow_mut().push_bottom(card_inner) {
                Err(LuaError::runtime("stack is full"))
            } else { Ok(()) }
        });
        /// Pops the top card; returns `nil` if empty.
        /// @return Card?
        methods.add_method("pop", |_, this, ()| {
            match this.0.borrow_mut().pop_top() {
                Some(item) => Ok(Some(lua_card_new(item))),
                None => Ok(None),
            }
        });
        /// Pops the bottom card; returns `nil` if empty.
        /// @return Card?
        methods.add_method("popBottom", |_, this, ()| {
            match this.0.borrow_mut().pop_bottom() {
                Some(item) => Ok(Some(lua_card_new(item))),
                None => Ok(None),
            }
        });
        /// Pops `n` items from the top; returns an array table.
        /// @param n : integer
        /// @return table
        methods.add_method("popMany", |lua, this, n: usize| {
            let items = this.0.borrow_mut().pop_many(n);
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() {
                tbl.set(i + 1, lua_card_new(item))?;
            }
            Ok(tbl)
        });
        /// Peeks at the top card without removing it; returns `nil` if empty.
        /// @return Card?
        methods.add_method("peek", |_, this, ()| {
            match this.0.borrow().peek_top() {
                Some(item) => Ok(Some(lua_card_new(item.clone()))),
                None => Ok(None),
            }
        });
        /// Peeks at item at 1-based position from the top without removing it.
        /// @param pos : integer
        /// @return Card?
        methods.add_method("peekAt", |_, this, pos: usize| {
            match this.0.borrow().peek_at(pos.saturating_sub(1)) {
                Some(item) => Ok(Some(lua_card_new(item.clone()))),
                None => Ok(None),
            }
        });
        /// Shuffles the stack in place.
        methods.add_method("shuffle", |_, this, ()| {
            this.0.borrow_mut().shuffle(); Ok(())
        });
        /// Sorts ascending by a named stat.
        /// @param stat : string
        methods.add_method("sortByStat", |_, this, stat: String| {
            this.0.borrow_mut().sort_by_stat(&stat); Ok(())
        });
        /// Sorts descending by a named stat.
        /// @param stat : string
        methods.add_method("sortByStatDesc", |_, this, stat: String| {
            this.0.borrow_mut().sort_by_stat_desc(&stat); Ok(())
        });
        /// Sorts alphabetically by category.
        methods.add_method("sortByCategory", |_, this, ()| {
            this.0.borrow_mut().sort_by_category(); Ok(())
        });
        /// Returns an array table of all items (top is last).
        /// @return table
        methods.add_method("items", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, item) in this.0.borrow().items().iter().enumerate() {
                tbl.set(i + 1, lua_card_new(item.clone()))?;
            }
            Ok(tbl)
        });
        /// Removes item at 1-based index; returns the card or `nil`.
        /// @param idx : integer
        /// @return Card?
        methods.add_method("removeAt", |_, this, idx: usize| {
            match this.0.borrow_mut().remove_at(idx.saturating_sub(1)) {
                Some(item) => Ok(Some(lua_card_new(item))),
                None => Ok(None),
            }
        });
        /// Inserts a card at 1-based index.
        /// @param idx : integer
        /// @param card : Card
        methods.add_method("insertAt", |_, this, (idx, card): (usize, LuaAnyUserData)| {
            let card_inner = card.borrow::<LuaCard>()?.inner.borrow().clone();
            if !this.0.borrow_mut().insert_at(idx.saturating_sub(1), card_inner) {
                Err(LuaError::runtime("stack is full"))
            } else { Ok(()) }
        });
        /// Clears all items from the stack.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear(); Ok(())
        });
        /// Returns the count of items with a given type name.
        /// @param type_name : string
        /// @return any
        methods.add_method("countByType", |_, this, type_name: String| {
            Ok(this.0.borrow().count_by_type(&type_name))
        });
        /// Returns the count of items with a given category.
        /// @param cat : string
        /// @return any
        methods.add_method("countByCategory", |_, this, cat: String| {
            Ok(this.0.borrow().count_by_category(&cat))
        });
        /// Returns the count of items with a given tag.
        /// @param tag : string
        /// @return any
        methods.add_method("countByTag", |_, this, tag: String| {
            Ok(this.0.borrow().count_by_tag(&tag))
        });
        /// Returns the index (1-based) of the first item with the given type name, or `nil`.
        /// @param type_name : string
        /// @return any
        methods.add_method("findByType", |_, this, type_name: String| {
            Ok(this.0.borrow().find_by_type(&type_name).map(|i| i + 1))
        });

        // ── New convenience aliases ──────────────────────────────────────────
        /// Sets the name of this stack.
        /// @param name : string
        methods.add_method("setName", |_, this, name: String| {
            this.0.borrow_mut().set_name(name); Ok(())
        });
        /// Returns the number of cards (alias for `size`).
        /// @return integer
        methods.add_method("getCardCount", |_, this, ()| {
            Ok(this.0.borrow().size())
        });
        /// Returns all cards as an array table (alias for `items`).
        /// @return table
        methods.add_method("getCards", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, item) in this.0.borrow().items().iter().enumerate() {
                tbl.set(i + 1, lua_card_new(item.clone()))?;
            }
            Ok(tbl)
        });
        /// Adds a card to the top; returns `false` if full.
        /// @param card : Card
        /// @return any
        methods.add_method("addCard", |_, this, card: LuaAnyUserData| {
            let card_inner = card.borrow::<LuaCard>()?.inner.borrow().clone();
            Ok(this.0.borrow_mut().push_top(card_inner))
        });
        /// Adds a card to the bottom; returns `false` if full.
        /// @param card : Card
        /// @return any
        methods.add_method("addCardBottom", |_, this, card: LuaAnyUserData| {
            let card_inner = card.borrow::<LuaCard>()?.inner.borrow().clone();
            Ok(this.0.borrow_mut().push_bottom(card_inner))
        });
        /// Draws (pops) the top card; returns `nil` if empty. Alias for `pop`.
        /// @return Card?
        methods.add_method("drawCard", |_, this, ()| {
            match this.0.borrow_mut().pop_top() {
                Some(item) => Ok(Some(lua_card_new(item))),
                None => Ok(None),
            }
        });
        /// Draws (pops) the bottom card; returns `nil` if empty. Alias for `popBottom`.
        /// @return Card?
        methods.add_method("drawCardBottom", |_, this, ()| {
            match this.0.borrow_mut().pop_bottom() {
                Some(item) => Ok(Some(lua_card_new(item))),
                None => Ok(None),
            }
        });
        /// Draws `n` cards from the top; returns an array table. Alias for `popMany`.
        /// @param n : integer
        /// @return table
        methods.add_method("drawCards", |lua, this, n: usize| {
            let items = this.0.borrow_mut().pop_many(n);
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() { tbl.set(i + 1, lua_card_new(item))?; }
            Ok(tbl)
        });
        /// Inserts a card at 1-based index. Alias for `insertAt`.
        /// @param idx : integer
        /// @param card : Card
        /// @return any
        methods.add_method("insertCard", |_, this, (idx, card): (usize, LuaAnyUserData)| {
            let card_inner = card.borrow::<LuaCard>()?.inner.borrow().clone();
            Ok(this.0.borrow_mut().insert_at(idx.saturating_sub(1), card_inner))
        });
        /// Removes a specific card by identity; returns `true` if removed.
        /// @param card : Card
        /// @return boolean
        methods.add_method("removeCard", |_, this, card: LuaAnyUserData| {
            let id = card.borrow::<LuaCard>()?.inner.borrow().id;
            Ok(this.0.borrow_mut().remove_by_id(id).is_some())
        });
        /// Returns `true` if the stack contains the given card (by identity).
        /// @param card : Card
        /// @return any
        methods.add_method("contains", |_, this, card: LuaAnyUserData| {
            let id = card.borrow::<LuaCard>()?.inner.borrow().id;
            Ok(this.0.borrow().contains_id(id))
        });
        /// Returns an array table of cards matching a Lua predicate function.
        /// @param pred : function
        /// @return table
        methods.add_method("filter", |lua, this, pred: LuaFunction| {
            let cards = this.0.borrow().items().iter()
                .map(|c| lua_card_new(c.clone()))
                .collect::<Vec<_>>();
            let tbl = lua.create_table()?;
            let mut idx = 1usize;
            for card in cards {
                let result: bool = pred.call(card.clone())?;
                if result {
                    tbl.set(idx, card)?;
                    idx += 1;
                }
            }
            Ok(tbl)
        });
        /// Sorts the stack using a Lua comparator function `(a, b) -> bool`.
        /// @param cmp : function
        methods.add_method("sort", |_, this, cmp: LuaFunction| {
            let mut cards: Vec<_> = this.0.borrow().items().iter()
                .map(|c| lua_card_new(c.clone()))
                .collect();
            // Bubble sort to avoid borrow conflicts with Lua calls
            let n = cards.len();
            for i in 0..n {
                for j in 0..n-1-i {
                    let less: bool = cmp.call((cards[j+1].clone(), cards[j].clone())).unwrap_or(false);
                    if less { cards.swap(j, j+1); }
                }
            }
            // Stack stores cards bottom (index 0) to top (last index).
            // Lua sort convention: cmp(a,b)=true means a comes "first".
            // To match peek() == first-sorted-element, first must be at last index.
            let new_cards: Vec<crate::cardgame::card::Card> = cards.iter().rev()
                .map(|c| c.inner.borrow().clone())
                .collect();
            this.0.borrow_mut().restore_cards(new_cards);
            Ok(())
        });
        /// Returns all cards of the given category as an array table.
        /// @param cat : string
        /// @return table
        methods.add_method("findByCategory", |lua, this, cat: String| {
            let found = this.0.borrow().find_by_category_all(&cat);
            let tbl = lua.create_table()?;
            for (i, card) in found.into_iter().enumerate() { tbl.set(i + 1, lua_card_new(card))?; }
            Ok(tbl)
        });
        /// Returns the capacity limit, or -1 for unlimited.
        /// @return any
        methods.add_method("getCapacity", |_, this, ()| {
            Ok(this.0.borrow().capacity().map(|c| c as i64).unwrap_or(-1))
        });
        /// Sets the capacity limit (`0` or negative removes the limit).
        /// @param n : integer
        methods.add_method("setCapacity", |_, this, n: i64| {
            let cap = if n <= 0 { None } else { Some(n as usize) };
            this.0.borrow_mut().set_capacity(cap);
            Ok(())
        });
        /// Moves a specific card from this stack to `dst`; returns `true` on success.
        /// @param card : Card
        /// @param dst : Stack
        /// @return boolean
        methods.add_method("moveCard", |_, this, (card, dst): (LuaAnyUserData, LuaAnyUserData)| {
            let id = card.borrow::<LuaCard>()?.inner.borrow().id;
            let removed = this.0.borrow_mut().remove_by_id(id);
            match removed {
                None => Ok(false),
                Some(c) => {
                    dst.borrow::<LuaStack>()?.0.borrow_mut().push_top(c);
                    Ok(true)
                }
            }
        });
        /// Moves all cards from this stack to `dst`; returns the number moved.
        /// @param dst : Stack
        /// @return any
        methods.add_method("moveAllCards", |_, this, dst: LuaAnyUserData| {
            let cards: Vec<_> = this.0.borrow().items().to_vec();
            let n = cards.len();
            this.0.borrow_mut().restore_cards(vec![]);
            for c in cards { dst.borrow::<LuaStack>()?.0.borrow_mut().push_top(c); }
            Ok(n)
        });
        /// Sorts alphabetically by card name.
        methods.add_method("sortByName", |_, this, ()| {
            let mut cards: Vec<_> = this.0.borrow().items().to_vec();
            cards.sort_by(|a, b| a.name.cmp(&b.name));
            this.0.borrow_mut().restore_cards(cards);
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaStackBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `StackBuilder` userdata with optional Lua custom validation rules.
///
/// # Fields
/// - `inner` — `Rc<RefCell<DeckBuilder>>`.
/// - `custom_rules` — `Rc<RefCell<std::collections::HashMap<String`.
pub struct LuaDeckBuilder {
    pub inner: Rc<RefCell<DeckBuilder>>,
    pub custom_rules: Rc<RefCell<std::collections::HashMap<String, LuaRegistryKey>>>,
}

impl Clone for LuaDeckBuilder {
    fn clone(&self) -> Self {
        LuaDeckBuilder {
            inner: Rc::clone(&self.inner),
            custom_rules: Rc::clone(&self.custom_rules),
        }
    }
}

impl LunaType for LuaDeckBuilder {
    const TYPE_NAME: &'static str = "DeckBuilder";
    const TYPE_HIERARCHY: &'static [&'static str] = &["DeckBuilder"];
}

impl LuaUserData for LuaDeckBuilder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Adds `count` copies of `type_name` to the build list.
        /// @param type_name : string
        /// @param count : integer
        methods.add_method("add", |_, this, (type_name, count): (String, usize)| {
            this.inner.borrow_mut().add(type_name, count); Ok(())
        });
        /// Adds `count` copies with per-entry overrides supplied as a table.
        /// @param type_name : string
        /// @param count : integer
        /// @param overrides : table
        ///
        /// The override table may have: `stats = {key=val}`, `tags = {str, ...}`,
        /// `meta = {key=val}`.
        methods.add_method("addWith", |_, this, (type_name, count, overrides): (String, usize, LuaTable)| {
            let mut entry = BuildEntry { type_name, count, ..Default::default() };
            if let Ok(stats) = overrides.get::<_, LuaTable>("stats") {
                for pair in stats.pairs::<String, f64>() {
                    let (k, v) = pair?;
                    entry.stat_overrides.insert(k, v);
                }
            }
            if let Ok(tags) = overrides.get::<_, LuaTable>("tags") {
                for v in tags.sequence_values::<String>() { entry.extra_tags.push(v?); }
            }
            if let Ok(meta) = overrides.get::<_, LuaTable>("meta") {
                for pair in meta.pairs::<String, String>() {
                    let (k, v) = pair?;
                    entry.extra_metadata.insert(k, v);
                }
            }
            this.inner.borrow_mut().entries.push(entry);
            Ok(())
        });
        /// Marks a type as required (must appear in any validated stack).
        /// @param type_name : string
        methods.add_method("requireType", |_, this, type_name: String| {
            this.inner.borrow_mut().require_type(type_name); Ok(())
        });
        /// Marks a type as banned (must not appear).
        /// @param type_name : string
        methods.add_method("banType", |_, this, type_name: String| {
            this.inner.borrow_mut().ban_type(type_name); Ok(())
        });
        /// Sets shuffle-on-build flag.
        /// @param flag : boolean
        methods.add_method("setShuffleOnBuild", |_, this, flag: bool| {
            this.inner.borrow_mut().shuffle_on_build = flag; Ok(())
        });
        /// Sets the minimum stack size for validation.
        /// @param n : integer
        methods.add_method("setMinSize", |_, this, n: usize| {
            this.inner.borrow_mut().min_size = n; Ok(())
        });
        /// Sets the maximum stack size for validation (0 = unlimited).
        /// @param n : integer
        methods.add_method("setMaxSize", |_, this, n: usize| {
            this.inner.borrow_mut().max_size = n; Ok(())
        });
        /// Sets the maximum number of copies of any single type.
        /// @param n : integer
        methods.add_method("setMaxCopies", |_, this, n: usize| {
            this.inner.borrow_mut().max_copies = n; Ok(())
        });
        /// Validates the current build entries.  Returns an array table of error strings.
        /// @return table
        methods.add_method("validateEntries", |lua, this, ()| {
            let errors = this.inner.borrow().validate_entries();
            let tbl = lua.create_table()?;
            for (i, e) in errors.iter().enumerate() { tbl.set(i + 1, e.clone())?; }
            Ok(tbl)
        });
        /// Validates an existing `ItemStack` against the builder's constraints.
        /// @param stack : Stack
        /// @return table
        methods.add_method("validateStack", |lua, this, stack: LuaAnyUserData| {
            let stack_ref = stack.borrow::<LuaStack>()?;
            let errors = this.inner.borrow().validate_stack(&stack_ref.0.borrow());
            let tbl = lua.create_table()?;
            for (i, e) in errors.iter().enumerate() { tbl.set(i + 1, e.clone())?; }
            Ok(tbl)
        });
        /// Builds and returns an `ItemStack`.  Errors if entry types are unknown.
        /// @param name : string?
        /// @return any
        methods.add_method("build", |_, this, name: Option<String>| {
            let name_str = name.unwrap_or_default();
            let stack = this.inner.borrow().build_named(&name_str);
            Ok(LuaStack(Rc::new(RefCell::new(stack))))
        });

        // ── New methods ──────────────────────────────────────────────────────
        /// Sets minimum card count for validation.
        /// @param n : integer
        methods.add_method("setMinCards", |_, this, n: usize| {
            this.inner.borrow_mut().min_size = n; Ok(())
        });
        /// Returns the minimum card count.
        /// @return any
        methods.add_method("getMinCards", |_, this, ()| {
            Ok(this.inner.borrow().min_size)
        });
        /// Sets maximum card count for validation (0 = unlimited).
        /// @param n : integer
        methods.add_method("setMaxCards", |_, this, n: usize| {
            this.inner.borrow_mut().max_size = n; Ok(())
        });
        /// Returns the maximum card count.
        /// @return any
        methods.add_method("getMaxCards", |_, this, ()| {
            Ok(this.inner.borrow().max_size)
        });
        /// Returns the maximum copies of any single type.
        /// @return any
        methods.add_method("getMaxCopies", |_, this, ()| {
            Ok(this.inner.borrow().max_copies)
        });
        /// Sets a per-type copy limit.
        /// @param type_name : string
        /// @param n : integer
        methods.add_method("setMaxCopiesForType", |_, this, (type_name, n): (String, usize)| {
            this.inner.borrow_mut().set_max_copies_for_type(type_name, n); Ok(())
        });
        /// Requires at least `min` cards with the given tag.
        /// @param tag : string
        /// @param min : integer
        methods.add_method("addRequiredTag", |_, this, (tag, min): (String, usize)| {
            this.inner.borrow_mut().add_required_tag(tag, min); Ok(())
        });
        /// Bans a type (alias for `banType`).
        /// @param type_name : string
        methods.add_method("addBannedType", |_, this, type_name: String| {
            this.inner.borrow_mut().ban_type(type_name); Ok(())
        });
        /// Removes a type from the ban list.
        /// @param type_name : string
        methods.add_method("removeBannedType", |_, this, type_name: String| {
            this.inner.borrow_mut().remove_banned_type(&type_name); Ok(())
        });
        /// Returns the list of banned types as an array table.
        /// @return table
        methods.add_method("getBannedTypes", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, t) in this.inner.borrow().banned_types.iter().enumerate() {
                tbl.set(i + 1, t.clone())?;
            }
            Ok(tbl)
        });
        /// Requires cards matching category `cat` appear between `min` and optional `max` times.
        /// @param cat : string
        /// @param min : integer
        /// @param max : integer?
        methods.add_method("addRequiredCategory", |_, this, (cat, min, max): (String, usize, Option<usize>)| {
            this.inner.borrow_mut().add_required_category(cat, min, max); Ok(())
        });
        /// Validates `stack` against all constraints (size, copies, banned, required).
        /// @param stack : Stack
        /// @return any
        /// Returns `(ok: bool, errors: table)`.
        methods.add_method("validate", |lua, this, stack: LuaAnyUserData| {
            let stack_ref = stack.borrow::<LuaStack>()?;
            let borrowed_stack = stack_ref.0.borrow();
            let mut errors: Vec<String> = Vec::new();
            // Size checks
            let size = borrowed_stack.size();
            let b = this.inner.borrow();
            if b.min_size > 0 && size < b.min_size {
                errors.push(format!("deck has {} cards; minimum is {}", size, b.min_size));
            }
            if b.max_size > 0 && size > b.max_size {
                errors.push(format!("deck has {} cards; maximum is {}", size, b.max_size));
            }
            // Banned types
            for banned in &b.banned_types {
                if borrowed_stack.count_by_type(banned) > 0 {
                    errors.push(format!("banned type '{}' found in deck", banned));
                }
            }
            // Required types
            for req in &b.required_types {
                if borrowed_stack.count_by_type(req) == 0 {
                    errors.push(format!("required type '{}' not found in deck", req));
                }
            }
            // Max copies
            if b.max_copies > 0 {
                // collect type counts
                let items = borrowed_stack.items();
                let mut type_counts: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
                for card in items {
                    *type_counts.entry(card.card_type.clone()).or_insert(0) += 1;
                }
                for (t, count) in &type_counts {
                    let limit = b.per_type_limits.get(t).copied().unwrap_or(b.max_copies);
                    if *count > limit {
                        errors.push(format!("type '{}' has {} copies; max is {}", t, count, limit));
                    }
                }
            }
            // Required tags
            for (tag, min) in &b.required_tags {
                let cnt = borrowed_stack.count_by_tag(tag);
                if cnt < *min {
                    errors.push(format!("tag '{}' requires {} cards; found {}", tag, min, cnt));
                }
            }
            // Required categories
            for (cat, min, max_opt) in &b.required_categories {
                let cnt = borrowed_stack.count_by_category(cat);
                if cnt < *min {
                    errors.push(format!("category '{}' requires {} cards; found {}", cat, min, cnt));
                }
                if let Some(max) = max_opt {
                    if cnt > *max {
                        errors.push(format!("category '{}' allows at most {} cards; found {}", cat, max, cnt));
                    }
                }
            }
            drop(b);
            drop(borrowed_stack);
            // Custom rules
            {
                let rules_borrowed = this.custom_rules.borrow();
                for (_name, key) in rules_borrowed.iter() {
                    let rule_fn: LuaFunction = lua.registry_value(key)?;
                    let result: Option<String> = rule_fn.call(stack.clone())?;
                    if let Some(msg) = result {
                        errors.push(msg);
                    }
                }
            }
            let ok = errors.is_empty();
            let tbl = lua.create_table()?;
            for (i, e) in errors.iter().enumerate() { tbl.set(i + 1, e.clone())?; }
            Ok((ok, tbl))
        });
        /// Adds a custom validation rule `fn(stack) -> string|nil`.
        /// @param name : string
        /// @param func : function
        methods.add_method("addCustomRule", |lua, this, (name, func): (String, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            this.custom_rules.borrow_mut().insert(name, key);
            Ok(())
        });
        /// Removes a custom validation rule by name.
        /// @param name : string
        methods.add_method("removeCustomRule", |_, this, name: String| {
            this.custom_rules.borrow_mut().remove(&name);
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaStackManager
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `StackManager` userdata. Consult the module-level documentation for the broader usage context and preconditions.
#[derive(Clone)]
pub struct LuaZoneManager(pub Rc<RefCell<StackManager>>);

impl LunaType for LuaZoneManager {
    const TYPE_NAME: &'static str = "CardStackManager";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CardStackManager"];
}

impl LuaUserData for LuaZoneManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Creates an empty, unbounded stack with the given name.
        /// @param name : string
        methods.add_method("createStack", |_, this, name: String| {
            this.0.borrow_mut().create_stack(name); Ok(())
        });
        /// Creates an empty stack with a capacity cap.
        /// @param name : string
        /// @param cap : integer
        methods.add_method("createStackCapped", |_, this, (name, cap): (String, usize)| {
            this.0.borrow_mut().create_stack_capped(name, cap); Ok(())
        });
        /// Adds an externally-created `ItemStack` into the manager.
        /// @param name : string
        /// @param stack : Stack
        methods.add_method("addStack", |_, this, (name, stack): (String, LuaAnyUserData)| {
            let inner = stack.borrow::<LuaStack>()?.0.borrow().clone();
            this.0.borrow_mut().add_stack(name, inner); Ok(())
        });
        /// Removes a stack by name.
        /// @param name : string
        methods.add_method("removeStack", |_, this, name: String| {
            this.0.borrow_mut().remove_stack(&name); Ok(())
        });
        /// Returns `true` if a stack with this name exists.
        /// @param name : string
        /// @return any
        methods.add_method("hasStack", |_, this, name: String| {
            Ok(this.0.borrow().has_stack(&name))
        });
        /// Returns a snapshot of the named stack as a `LuaStack`.
        /// @param name : string
        /// @return any
        methods.add_method("getStack", |_, this, name: String| {
            match this.0.borrow().get_stack(&name) {
                Some(s) => Ok(Some(LuaStack(Rc::new(RefCell::new(s.clone()))))),
                None => Ok(None),
            }
        });
        /// Returns a list of all stack names.
        /// @return table
        methods.add_method("stackNames", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, n) in this.0.borrow().stack_names().into_iter().enumerate() {
                tbl.set(i + 1, n)?;
            }
            Ok(tbl)
        });
        /// Total items across all stacks.
        /// @return any
        methods.add_method("totalItems", |_, this, ()| {
            Ok(this.0.borrow().total_items())
        });
        /// Moves the card at 1-based `index` from `from_stack` to the top of `to_stack`.
        /// @param from : string
        /// @param idx : integer
        /// @param to : string
        methods.add_method("moveItem", |_, this, (from, idx, to): (String, usize, String)| {
            this.0.borrow_mut().move_item(&from, idx.saturating_sub(1), &to)
                .map(|_| ())
                .map_err(LuaError::runtime)
        });
        /// Moves the first item of `type_name` from `from_stack` to `to_stack`.
        /// @param from : string
        /// @param type_name : string
        /// @param to : string
        methods.add_method("moveItemByType", |_, this, (from, type_name, to): (String, String, String)| {
            this.0.borrow_mut().move_item_by_type(&from, &type_name, &to)
                .map(|_| ())
                .map_err(LuaError::runtime)
        });
        /// Moves the top card of `from_stack` to the top of `to_stack`.
        /// @param from : string
        /// @param to : string
        methods.add_method("moveTop", |_, this, (from, to): (String, String)| {
            this.0.borrow_mut().move_top(&from, &to)
                .map(|_| ())
                .map_err(LuaError::runtime)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCardPool
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `CardPool` userdata. Consult the module-level documentation for the broader usage context and preconditions.
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
        /// @return any
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Adds a type with the given weight.
        /// @param type_name : string
        /// @param weight : integer
        methods.add_method("add", |_, this, (type_name, weight): (String, u32)| {
            this.0.borrow_mut().add(type_name, weight); Ok(())
        });
        /// Removes a type from the pool.
        /// @param type_name : string
        methods.add_method("remove", |_, this, type_name: String| {
            this.0.borrow_mut().remove(&type_name); Ok(())
        });
        /// Sets the weight for an existing entry.
        /// @param type_name : string
        /// @param weight : integer
        methods.add_method("setWeight", |_, this, (type_name, weight): (String, u32)| {
            this.0.borrow_mut().set_weight(&type_name, weight); Ok(())
        });
        /// Returns the number of items.
        ///
        /// @return integer
        methods.add_method("size", |_, this, ()| Ok(this.0.borrow().size()));
        /// Total weight.
        ///
        /// @return any
        methods.add_method("totalWeight", |_, this, ()| Ok(this.0.borrow().total_weight()));
        /// Returns true if empty.
        ///
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Draws `n` type-name strings (with replacement); returns an array table.
        /// @param n : integer
        /// @return table
        methods.add_method("drawTypes", |lua, this, n: usize| {
            let types = this.0.borrow().draw_types(n);
            let tbl = lua.create_table()?;
            for (i, t) in types.iter().enumerate() { tbl.set(i + 1, t.clone())?; }
            Ok(tbl)
        });
        /// Draws up to `n` unique type-name strings; returns an array table.
        /// @param n : integer
        /// @return table
        methods.add_method("drawUniqueTypes", |lua, this, n: usize| {
            let types = this.0.borrow().draw_unique_types(n);
            let tbl = lua.create_table()?;
            for (i, t) in types.iter().enumerate() { tbl.set(i + 1, t.clone())?; }
            Ok(tbl)
        });
        /// Draws `n` items (with replacement) as `LuaItem` values; returns an array table.
        /// @param n : integer
        /// @return table
        methods.add_method("drawItems", |lua, this, n: usize| {
            let items = this.0.borrow().draw_items(n);
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() {
                tbl.set(i + 1, lua_card_new(item))?;
            }
            Ok(tbl)
        });
        /// Draws up to `n` unique items; returns an array table.
        /// @param n : integer
        /// @return table
        methods.add_method("drawUniqueItems", |lua, this, n: usize| {
            let items = this.0.borrow().draw_unique_items(n);
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() {
                tbl.set(i + 1, lua_card_new(item))?;
            }
            Ok(tbl)
        });

        // ── New methods ──────────────────────────────────────────────────────
        /// Sets the pool name.
        /// @param name : string
        methods.add_method("setName", |_, this, name: String| {
            this.0.borrow_mut().set_name(name); Ok(())
        });
        /// Returns the list of type names present in the pool.
        /// @return table
        methods.add_method("getCardTypes", |lua, this, ()| {
            let names = this.0.borrow().get_type_names();
            let tbl = lua.create_table()?;
            for (i, n) in names.iter().enumerate() { tbl.set(i + 1, n.clone())?; }
            Ok(tbl)
        });
        /// Returns the number of distinct card types in the pool.
        /// @return integer
        methods.add_method("getCardTypeCount", |_, this, ()| {
            Ok(this.0.borrow().get_type_names().len())
        });
        /// Returns the weight for `type_name`, or 0 if not present.
        /// @param type_name : string
        /// @return any
        methods.add_method("getWeight", |_, this, type_name: String| {
            Ok(this.0.borrow().get_weight(&type_name))
        });
        /// Sets the rarity-tier weight used by `drawByRarity`.
        /// @param rarity : string
        /// @param weight : integer
        methods.add_method("setRarityWeight", |_, this, (rarity, weight): (String, u32)| {
            this.0.borrow_mut().set_rarity_weight(rarity, weight); Ok(())
        });
        /// Draws `n` cards; optional u64 `seed` makes the draw deterministic.
        /// @param n : integer
        /// @param seed : integer?
        /// @return table
        methods.add_method("drawRandom", |lua, this, (n, seed): (usize, Option<u64>)| {
            let items = match seed {
                Some(s) => this.0.borrow().draw_items_seeded(n, s),
                None    => this.0.borrow().draw_items(n),
            };
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() { tbl.set(i + 1, lua_card_new(item))?; }
            Ok(tbl)
        });
        /// Draws cards by rarity distribution `{rarity_name = count, ...}`.
        /// @param dist : table
        /// @return table
        methods.add_method("drawByRarity", |lua, this, dist: LuaTable| {
            let mut distribution: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
            for pair in dist.pairs::<String, usize>() {
                let (k, v) = pair?;
                distribution.insert(k, v);
            }
            let items = this.0.borrow().draw_by_rarity(&distribution);
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() { tbl.set(i + 1, lua_card_new(item))?; }
            Ok(tbl)
        });
        /// Adds a card type with weight (alias for `add`).
        /// @param type_name : string
        /// @param weight : integer
        methods.add_method("addCardType", |_, this, (type_name, weight): (String, u32)| {
            this.0.borrow_mut().add(type_name, weight); Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaSlot
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Slot` userdata. Consult the module-level documentation for the broader usage context and preconditions.
#[derive(Clone)]
pub struct LuaSlot(pub Rc<RefCell<Slot>>);

impl LunaType for LuaSlot {
    const TYPE_NAME: &'static str = "CardSlot";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CardSlot"];
}

impl LuaUserData for LuaSlot {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the name.
        ///
        /// @return any
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the number of items.
        ///
        /// @return integer
        methods.add_method("size", |_, this, ()| Ok(this.0.borrow().size()));
        /// Returns true if empty.
        ///
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Returns true if full.
        ///
        /// @return boolean
        methods.add_method("isFull", |_, this, ()| Ok(this.0.borrow().is_full()));
        /// Capacity.
        ///
        /// @return any
        methods.add_method("capacity", |_, this, ()| {
            Ok(this.0.borrow().capacity())
        });
        /// Sets the capacity (pass 0 for unlimited).
        /// @param cap : integer
        methods.add_method("setCapacity", |_, this, cap: usize| {
            this.0.borrow_mut().set_capacity(if cap == 0 { None } else { Some(cap) }); Ok(())
        });
        /// Pushes a card into the slot.
        /// @param card : Card
        methods.add_method("push", |_, this, card: LuaAnyUserData| {
            let inner = card.borrow::<LuaCard>()?.inner.borrow().clone();
            this.0.borrow_mut().push(inner).map_err(LuaError::runtime)
        });
        /// Pops a card from the slot.
        /// @return Card?
        methods.add_method("pop", |_, this, ()| {
            match this.0.borrow_mut().pop() {
                Some(item) => Ok(Some(lua_card_new(item))),
                None => Ok(None),
            }
        });
        /// Peeks at the top card without removing it.
        /// @return Card?
        methods.add_method("peek", |_, this, ()| {
            match this.0.borrow().peek() {
                Some(item) => Ok(Some(lua_card_new(item.clone()))),
                None => Ok(None),
            }
        });
        /// Returns all items as an array table.
        /// @return table
        methods.add_method("items", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, item) in this.0.borrow().items().iter().enumerate() {
                tbl.set(i + 1, lua_card_new(item.clone()))?;
            }
            Ok(tbl)
        });
        /// Clears the slot; returns the cards as an array table.
        /// @return table
        methods.add_method("clear", |lua, this, ()| {
            let items = this.0.borrow_mut().clear();
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() {
                tbl.set(i + 1, lua_card_new(item))?;
            }
            Ok(tbl)
        });
        /// Returns true if item with tag.
        ///
        /// @param tag : string
        /// @return any
        methods.add_method("hasItemWithTag", |_, this, tag: String| {
            Ok(this.0.borrow().has_item_with_tag(&tag))
        });
        /// Returns true if item of type.
        ///
        /// @param type_name : string
        /// @return any
        methods.add_method("hasItemOfType", |_, this, type_name: String| {
            Ok(this.0.borrow().has_item_of_type(&type_name))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaHistory
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `StackHistory` userdata. Consult the module-level documentation for the broader usage context and preconditions.
#[derive(Clone)]
pub struct LuaHistory(pub Rc<RefCell<StackHistory>>);

impl LunaType for LuaHistory {
    const TYPE_NAME: &'static str = "StackHistory";
    const TYPE_HIERARCHY: &'static [&'static str] = &["StackHistory"];
}

impl LuaUserData for LuaHistory {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the number of items.
        ///
        /// @return integer
        methods.add_method("len", |_, this, ()| Ok(this.0.borrow().len()));
        /// Returns true if empty.
        ///
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Clears the state.
        ///
        methods.add_method("clear", |_, this, ()| { this.0.borrow_mut().clear(); Ok(()) });
        /// Records a custom event label for a named stack.
        /// @param stack_name : string
        /// @param label : string
        /// @param size_after : integer
        methods.add_method("recordCustom", |_, this, (stack_name, label, size_after): (String, String, usize)| {
            this.0.borrow_mut().record_custom(stack_name, label, size_after); Ok(())
        });
        /// Returns the last entry as a table `{seq, stack, action, sizeAfter}`, or `nil`.
        /// @return any
        methods.add_method("last", |lua, this, ()| {
            match this.0.borrow().last() {
                None => Ok(LuaValue::Nil),
                Some(e) => {
                    let tbl = lua.create_table()?;
                    tbl.set("seq", e.seq)?;
                    tbl.set("stack", e.stack_name.clone())?;
                    tbl.set("action", format!("{:?}", e.action))?;
                    tbl.set("sizeAfter", e.size_after)?;
                    Ok(LuaValue::Table(tbl))
                }
            }
        });
        /// Returns all entries as an array of `{seq, stack, action, sizeAfter}` tables.
        /// @return table
        methods.add_method("entries", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, e) in this.0.borrow().entries().enumerate() {
                let row = lua.create_table()?;
                row.set("seq", e.seq)?;
                row.set("stack", e.stack_name.clone())?;
                row.set("action", format!("{:?}", e.action))?;
                row.set("sizeAfter", e.size_after)?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaEffectStack — LIFO effect resolution stack
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing LIFO effect stack.  Each entry is a Lua table describing an effect.
///
/// # Fields
/// - `entries` — `Rc<RefCell<Vec<LuaRegistryKey>>>`.
#[derive(Clone)]
pub struct LuaEffectStack {
    entries: Rc<RefCell<Vec<LuaRegistryKey>>>,
}

impl LunaType for LuaEffectStack {
    const TYPE_NAME: &'static str = "EffectStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["EffectStack"];
}

impl LuaUserData for LuaEffectStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Pushes an entry table onto the top of the stack.
        /// @param entry : table
        methods.add_method("push", |lua, this, entry: LuaTable| {
            let key = lua.create_registry_value(entry)?;
            this.entries.borrow_mut().push(key);
            Ok(())
        });
        /// Pops and returns the top entry, or `nil` if empty.
        /// @return any
        methods.add_method("pop", |lua, this, ()| {
            match this.entries.borrow_mut().pop() {
                Some(key) => {
                    let tbl: LuaTable = lua.registry_value(&key)?;
                    lua.remove_registry_value(key)?;
                    Ok(LuaValue::Table(tbl))
                }
                None => Ok(LuaValue::Nil),
            }
        });
        /// Peeks at the top entry without removing it, or `nil` if empty.
        /// @return any
        methods.add_method("peek", |lua, this, ()| {
            match this.entries.borrow().last() {
                Some(key) => {
                    let tbl: LuaTable = lua.registry_value(key)?;
                    Ok(LuaValue::Table(tbl))
                }
                None => Ok(LuaValue::Nil),
            }
        });
        /// Resolves the top entry: calls `entry.card:fireScript("onEffect", entry)`.
        /// @return any
        /// Returns the entry table, or `nil` if empty.
        methods.add_method("resolve", |lua, this, ()| {
            let maybe_key = this.entries.borrow_mut().pop();
            match maybe_key {
                None => Ok(LuaValue::Nil),
                Some(key) => {
                    let entry: LuaTable = lua.registry_value(&key)?;
                    lua.remove_registry_value(key)?;
                    // If entry has a `card` field that is a LuaCard, fire "onEffect"
                    if let Ok(card_ud) = entry.get::<_, LuaAnyUserData>("card") {
                        // Fire the "onEffect" instance script if set
                        let maybe_fn: Option<LuaFunction> = card_ud.borrow::<LuaCard>()
                            .ok()
                            .and_then(|c| c.scripts.borrow().get("onEffect")
                                .and_then(|k| lua.registry_value::<LuaFunction>(k).ok()));
                        if let Some(f) = maybe_fn {
                            let _ = f.call::<_, LuaMultiValue>(entry.clone());
                        }
                    }
                    Ok(LuaValue::Table(entry))
                }
            }
        });
        /// Resolves all entries from top to bottom.  Returns the count resolved.
        /// @return any
        methods.add_method("resolveAll", |lua, this, ()| {
            let mut count = 0usize;
            loop {
                let maybe_key = this.entries.borrow_mut().pop();
                match maybe_key {
                    None => break,
                    Some(key) => {
                        let entry: LuaTable = lua.registry_value(&key)?;
                        lua.remove_registry_value(key)?;
                        if let Ok(card_ud) = entry.get::<_, LuaAnyUserData>("card") {
                            if let Ok(card) = card_ud.borrow::<LuaCard>() {
                                if let Some(k) = card.scripts.borrow().get("onEffect") {
                                    if let Ok(f) = lua.registry_value::<LuaFunction>(k) {
                                        let _ = f.call::<_, LuaMultiValue>(entry.clone());
                                    }
                                }
                            }
                        }
                        count += 1;
                    }
                }
            }
            Ok(count)
        });
        /// Returns all entries as an array (top is last).
        /// @return table
        methods.add_method("getEntries", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, key) in this.entries.borrow().iter().enumerate() {
                let entry: LuaTable = lua.registry_value(key)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        });
        /// Returns the number of entries.
        /// @return integer
        methods.add_method("getCount", |_, this, ()| Ok(this.entries.borrow().len()));
        /// Returns `true` if the stack is empty.
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.entries.borrow().is_empty()));
        /// Clears all entries.
        methods.add_method("clear", |lua, this, ()| {
            let keys: Vec<LuaRegistryKey> = this.entries.borrow_mut().drain(..).collect();
            for k in keys { lua.remove_registry_value(k)?; }
            Ok(())
        });
        /// Removes the entry at 1-based index.  Returns `true` if it was present.
        /// @param idx : integer
        /// @return boolean
        methods.add_method("removeEntry", |lua, this, idx: usize| {
            let mut entries = this.entries.borrow_mut();
            // idx is 1-based; entries[0] is bottom (earliest pushed)
            // "top" in our Vec is the last element, so position 1 = last for the user?
            // spec says "1-based from top" so index 1 = last element
            let len = entries.len();
            if idx == 0 || idx > len {
                return Ok(false);
            }
            let rust_idx = len - idx;
            let key = entries.remove(rust_idx);
            drop(entries);
            lua.remove_registry_value(key)?;
            Ok(true)
        });
        /// Inserts an entry at 1-based position from the top.
        /// @param entry : table
        /// @param idx : integer
        methods.add_method("insertEntry", |lua, this, (entry, idx): (LuaTable, usize)| {
            let key = lua.create_registry_value(entry)?;
            let mut entries = this.entries.borrow_mut();
            let len = entries.len();
            let rust_idx = if idx == 0 || idx > len { 0 } else { len - idx + 1 };
            entries.insert(rust_idx, key);
            Ok(())
        });
        /// Returns an array of 1-based indices where `entry.card` matches the given card (by id).
        /// @param card : Card
        /// @return any
        methods.add_method("findByCard", |lua, this, card: LuaAnyUserData| {
            let id = card.borrow::<LuaCard>()?.inner.borrow().id;
            let entries = this.entries.borrow();
            let len = entries.len();
            let result = lua.create_table()?;
            let mut ri = 1usize;
            // iterate from top (last) to bottom (first), reporting 1-based-from-top indices
            for (rust_idx, key) in entries.iter().enumerate().rev() {
                let from_top_idx = len - rust_idx;
                let entry: LuaTable = lua.registry_value(key)?;
                if let Ok(card_ud) = entry.get::<_, LuaAnyUserData>("card") {
                    if let Ok(c) = card_ud.borrow::<LuaCard>() {
                        if c.inner.borrow().id == id {
                            result.set(ri, from_top_idx)?;
                            ri += 1;
                        }
                    }
                }
            }
            Ok(result)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: extract Item slice from a Lua array table
// ─────────────────────────────────────────────────────────────────────────────

fn cards_from_lua_table(tbl: LuaTable) -> LuaResult<Vec<Card>> {
    let mut cards = Vec::new();
    for v in tbl.sequence_values::<LuaAnyUserData>() {
        cards.push(v?.borrow::<LuaCard>()?.inner.borrow().clone());
    }
    Ok(cards)
}

// ─────────────────────────────────────────────────────────────────────────────
// register
// ─────────────────────────────────────────────────────────────────────────────

/// Registers the `luna.cardgame.*` API. Panics in debug mode if the same entity is registered twice.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let item_table = lua.create_table()?;

    // ── Type registry ──────────────────────────────────────────────────────

    /// Defines a card type in the global registry.
    /// @param name : string
    /// @param def_tbl : table
    ///
    /// ```lua
    /// luna.cardgame.defineType("fireball", {
    ///   category = "spell",
    ///   subtype  = "damage",
    ///   rarity   = "rare",
    ///   maxPerDeck = 3,
    ///   stats    = { damage = 10, manaCost = 3 },
    ///   tags     = { "fire", "instant" },
    ///   meta     = { artist = "A. Smith" },
    /// })
    /// ```
    item_table.set("defineType", lua.create_function(|lua, (name, def_tbl): (String, LuaTable)| {
        let mut def = CardTypeDef {
            name: name.clone(),
            ..Default::default()
        };
        if let Ok(cat) = def_tbl.get::<_, String>("category") { def.category = cat; }
        if let Ok(sub) = def_tbl.get::<_, String>("subtype") { def.subtype = sub; }
        if let Ok(rar) = def_tbl.get::<_, String>("rarity") { def.rarity = rar; }
        if let Ok(max) = def_tbl.get::<_, u32>("maxPerDeck") { def.max_per_deck = Some(max); }
        if let Ok(stats) = def_tbl.get::<_, LuaTable>("stats") {
            for pair in stats.pairs::<String, f64>() {
                let (k, v) = pair?; def.base_stats.insert(k, v);
            }
        }
        if let Ok(tags) = def_tbl.get::<_, LuaTable>("tags") {
            for v in tags.sequence_values::<String>() { def.base_tags.push(v?); }
        }
        if let Ok(meta) = def_tbl.get::<_, LuaTable>("meta") {
            for pair in meta.pairs::<String, String>() {
                let (k, v) = pair?; def.metadata.insert(k, v);
            }
        }
        define_card_type(name.clone(), def);
        // Store type-level scripts/costCheck/costPay in the global _LUNA_CG_SCRIPTS table
        if let Ok(scripts_global) = lua.globals().get::<_, LuaTable>("_LUNA_CG_SCRIPTS") {
            let type_scripts = lua.create_table()?;
            if let Ok(scripts_tbl) = def_tbl.get::<_, LuaTable>("scripts") {
                for (event, func) in scripts_tbl.pairs::<String, LuaFunction>().flatten() {
                    type_scripts.set(event, func)?;
                }
            }
            if let Ok(f) = def_tbl.get::<_, LuaFunction>("costCheck") {
                type_scripts.set("costCheck", f)?;
            }
            if let Ok(f) = def_tbl.get::<_, LuaFunction>("costPay") {
                type_scripts.set("costPay", f)?;
            }
            if let Ok(ts) = def_tbl.get::<_, LuaTable>("tileSize") {
                type_scripts.set("tileSize", ts)?;
            }
            scripts_global.set(name, type_scripts)?;
        }
        Ok(())
    })?)?;

    /// Returns the definition table for a registered type, or `nil` if not found.
    /// @param name : string
    /// @return any
    item_table.set("getType", lua.create_function(|lua, name: String| {
        match get_card_type(&name) {
            None => Ok(LuaValue::Nil),
            Some(def) => {
                let tbl = lua.create_table()?;
                tbl.set("name", def.name)?;
                tbl.set("category", def.category)?;
                tbl.set("subtype", def.subtype)?;
                tbl.set("rarity", def.rarity)?;
                if let Some(max) = def.max_per_deck {
                    tbl.set("maxPerDeck", max)?;
                }
                let stats = lua.create_table()?;
                for (k, v) in &def.base_stats { stats.set(k.clone(), *v)?; }
                tbl.set("stats", stats)?;
                let tags = lua.create_table()?;
                for (i, t) in def.base_tags.iter().enumerate() { tags.set(i + 1, t.clone())?; }
                tbl.set("tags", tags)?;
                Ok(LuaValue::Table(tbl))
            }
        }
    })?)?;

    /// Returns an array table of all registered type names.
    /// @return table
    item_table.set("getTypeNames", lua.create_function(|lua, ()| {
        let tbl = lua.create_table()?;
        for (i, n) in get_card_type_names().iter().enumerate() { tbl.set(i + 1, n.clone())?; }
        Ok(tbl)
    })?)?;

    /// Clears all registered item types.
    item_table.set("clearTypes", lua.create_function(|_, ()| {
        clear_card_types(); Ok(())
    })?)?;

    // ── Constructors ───────────────────────────────────────────────────────

    /// Creates a new item by seeding from the registered type.
    /// @param type_name : string
    /// @return Card
    ///
    /// ```lua
    /// local sword = luna.cardgame.newItem("sword")
    /// sword:setStat("damage", 15)
    /// ```
    item_table.set("newCard", lua.create_function(|_, type_name: String| {
        Ok(lua_card_new(Card::new(&type_name)))
    })?)?;

    /// Creates a new empty stack.
    /// @param name : string
    /// @param cap : integer?
    /// @return any
    ///
    /// ```lua
    /// local hand = luna.cardgame.newStack("hand")
    /// local deck = luna.cardgame.newStack("deck", 60)   -- capped at 60
    /// ```
    item_table.set("newStack", lua.create_function(|_, (name, cap): (String, Option<usize>)| {
        let stack = match cap {
            Some(c) => Stack::with_capacity(name, c),
            None => Stack::new(name),
        };
        Ok(LuaStack(Rc::new(RefCell::new(stack))))
    })?)?;

    /// Creates a new `StackBuilder`.
    /// @param name : string?
    /// @return any
    item_table.set("newDeckBuilder", lua.create_function(|_, name: Option<String>| {
        Ok(LuaDeckBuilder {
            inner: Rc::new(RefCell::new(DeckBuilder::new(name.unwrap_or_default()))),
            custom_rules: Rc::new(RefCell::new(std::collections::HashMap::new())),
        })
    })?)?;

    /// Creates a new `StackManager`.
    /// @return any
    item_table.set("newZoneManager", lua.create_function(|_, ()| {
        Ok(LuaZoneManager(Rc::new(RefCell::new(StackManager::new()))))
    })?)?;

    /// Creates a new `CardPool`.
    /// @param name : string?
    /// @return any
    item_table.set("newCardPool", lua.create_function(|_, name: Option<String>| {
        Ok(LuaCardPool(Rc::new(RefCell::new(CardPool::new(name.unwrap_or_default())))))
    })?)?;

    /// Creates a new `Slot`.
    /// @param name : string
    /// @param cap : integer?
    /// @return any
    ///
    /// ```lua
    /// local slot = luna.cardgame.newSlot("weapon_slot", 1)  -- holds 1 item
    /// ```
    item_table.set("newSlot", lua.create_function(|_, (name, cap): (String, Option<usize>)| {
        let slot = match cap {
            Some(c) => Slot::with_capacity(name, c),
            None => Slot::new(name),
        };
        Ok(LuaSlot(Rc::new(RefCell::new(slot))))
    })?)?;

    /// Creates a new `StackHistory`.
    /// @param max_size : integer?
    /// @return any
    ///
    /// ```lua
    /// local h = luna.cardgame.newHistory()
    /// local h = luna.cardgame.newHistory(100)  -- keeps last 100 events
    /// ```
    item_table.set("newHistory", lua.create_function(|_, max_size: Option<usize>| {
        let history = match max_size {
            Some(n) => StackHistory::with_max_size(n),
            None => StackHistory::new(),
        };
        Ok(LuaHistory(Rc::new(RefCell::new(history))))
    })?)?;

    // ── Group / analysis functions ─────────────────────────────────────────

    /// Groups items in an array table by the integer part of a stat.
    /// @param items_tbl : table
    /// @param stat : string
    /// @return any
    ///
    /// Returns `{ [stat_value] = {LuaItem, …}, … }`.
    item_table.set("groupByStat", lua.create_function(|lua, (items_tbl, stat): (LuaTable, String)| {
        let items = cards_from_lua_table(items_tbl)?;
        let groups = group_by_stat(&items, &stat);
        let result = lua.create_table()?;
        for (val, indices) in groups {
            let inner = lua.create_table()?;
            for (i, idx) in indices.iter().enumerate() {
                inner.set(i + 1, lua_card_new(items[*idx].clone()))?;
            }
            result.set(val, inner)?;
        }
        Ok(result)
    })?)?;

    /// Groups items by category.  Returns `{ [category] = {LuaItem, …}, … }`.
    /// @param items_tbl : table
    /// @return any
    item_table.set("groupByCategory", lua.create_function(|lua, items_tbl: LuaTable| {
        let items = cards_from_lua_table(items_tbl)?;
        let groups = group_by_category(&items);
        let result = lua.create_table()?;
        for (cat, indices) in groups {
            let inner = lua.create_table()?;
            for (i, idx) in indices.iter().enumerate() {
                inner.set(i + 1, lua_card_new(items[*idx].clone()))?;
            }
            result.set(cat, inner)?;
        }
        Ok(result)
    })?)?;

    /// Groups items by a tag prefix such as `"suit"`.
    /// @param items_tbl : table
    /// @param prefix : string
    /// @return any
    ///
    /// Returns `{ [value] = {LuaItem, …}, … }` where `value` is the part after the `:`.
    item_table.set("groupByTagPrefix", lua.create_function(|lua, (items_tbl, prefix): (LuaTable, String)| {
        let items = cards_from_lua_table(items_tbl)?;
        let groups = group_by_tag_prefix(&items, &prefix);
        let result = lua.create_table()?;
        for (val, indices) in groups {
            let inner = lua.create_table()?;
            for (i, idx) in indices.iter().enumerate() {
                inner.set(i + 1, lua_card_new(items[*idx].clone()))?;
            }
            result.set(val, inner)?;
        }
        Ok(result)
    })?)?;

    /// Finds groups where exactly `n` items share the same stat integer value.
    /// @param items_tbl : table
    /// @param stat : string
    /// @param n : integer
    /// @return any
    ///
    /// Returns an array of `{label, score, items}` tables.
    item_table.set("findNOfStat", lua.create_function(|lua, (items_tbl, stat, n): (LuaTable, String, usize)| {
        let items = cards_from_lua_table(items_tbl)?;
        let groups = find_n_of_stat(&items, &stat, n);
        let result = lua.create_table()?;
        for (gi, g) in groups.iter().enumerate() {
            let row = lua.create_table()?;
            row.set("label", g.label.clone())?;
            row.set("score", g.score)?;
            let inner = lua.create_table()?;
            for (i, &idx) in g.indices.iter().enumerate() {
                inner.set(i + 1, lua_card_new(items[idx].clone()))?;
            }
            row.set("items", inner)?;
            result.set(gi + 1, row)?;
        }
        Ok(result)
    })?)?;

    /// Finds groups where at least `n` items share the same stat integer value.
    /// @param items_tbl : table
    /// @param stat : string
    /// @param n : integer
    /// @return any
    item_table.set("findAtLeastNOfStat", lua.create_function(|lua, (items_tbl, stat, n): (LuaTable, String, usize)| {
        let items = cards_from_lua_table(items_tbl)?;
        let groups = find_at_least_n_of_stat(&items, &stat, n);
        let result = lua.create_table()?;
        for (gi, g) in groups.iter().enumerate() {
            let row = lua.create_table()?;
            row.set("label", g.label.clone())?;
            row.set("score", g.score)?;
            let inner = lua.create_table()?;
            for (i, &idx) in g.indices.iter().enumerate() {
                inner.set(i + 1, lua_card_new(items[idx].clone()))?;
            }
            row.set("items", inner)?;
            result.set(gi + 1, row)?;
        }
        Ok(result)
    })?)?;

    /// Finds consecutive integer stat sequences of length ≥ `min_run`.
    /// @param items_tbl : table
    /// @param stat : string
    /// @param min_run : integer
    /// @return any
    ///
    /// Returns an array of `{label, score, items}` tables.
    item_table.set("findSequences", lua.create_function(|lua, (items_tbl, stat, min_run): (LuaTable, String, usize)| {
        let items = cards_from_lua_table(items_tbl)?;
        let groups = find_sequences(&items, &stat, min_run);
        let result = lua.create_table()?;
        for (gi, g) in groups.iter().enumerate() {
            let row = lua.create_table()?;
            row.set("label", g.label.clone())?;
            row.set("score", g.score)?;
            let inner = lua.create_table()?;
            for (i, &idx) in g.indices.iter().enumerate() {
                inner.set(i + 1, lua_card_new(items[idx].clone()))?;
            }
            row.set("items", inner)?;
            result.set(gi + 1, row)?;
        }
        Ok(result)
    })?)?;

    /// Finds groups of items sharing a tag-prefix value (flush-style), min size `min_size`.
    /// @param items_tbl : table
    /// @param prefix : string
    /// @param min_size : integer
    /// @return any
    item_table.set("findTagGroups", lua.create_function(|lua, (items_tbl, prefix, min_size): (LuaTable, String, usize)| {
        let items = cards_from_lua_table(items_tbl)?;
        let groups = find_tag_groups(&items, &prefix, min_size);
        let result = lua.create_table()?;
        for (gi, g) in groups.iter().enumerate() {
            let row = lua.create_table()?;
            row.set("label", g.label.clone())?;
            row.set("score", g.score)?;
            let inner = lua.create_table()?;
            for (i, &idx) in g.indices.iter().enumerate() {
                inner.set(i + 1, lua_card_new(items[idx].clone()))?;
            }
            row.set("items", inner)?;
            result.set(gi + 1, row)?;
        }
        Ok(result)
    })?)?;

    // ── Aliases matching the spec's preferred names ────────────────────────
    // Keep existing names; also register under canonical spec names.
    {
        let dt: LuaFunction = item_table.get("defineType")?;
        item_table.set("defineCardType", dt)?;
        let gt: LuaFunction = item_table.get("getType")?;
        item_table.set("getCardType", gt)?;
        let gtn: LuaFunction = item_table.get("getTypeNames")?;
        item_table.set("getCardTypeNames", gtn)?;
        let ct: LuaFunction = item_table.get("clearTypes")?;
        item_table.set("clearCardTypes", ct)?;
        let ns: LuaFunction = item_table.get("newStack")?;
        item_table.set("newDeck", ns.clone())?;
        item_table.set("newZone", ns)?;
    }

    /// Creates a new LIFO `EffectStack` for effect resolution.
    /// @return any
    ///
    /// ```lua
    /// local stack = luna.cardgame.newEffectStack()
    /// stack:push({ card = myCard, effect = "fireball" })
    /// stack:resolveAll()
    /// ```
    item_table.set("newEffectStack", lua.create_function(|_, ()| {
        Ok(LuaEffectStack { entries: Rc::new(RefCell::new(Vec::new())) })
    })?)?;

    /// Alias for `newEffectStack` (LIFO effect resolution stack).
    /// @return any
    item_table.set("newStackManager", lua.create_function(|_, ()| {
        Ok(LuaEffectStack { entries: Rc::new(RefCell::new(Vec::new())) })
    })?)?;

    // Initialise the type-level script registry global
    if lua.globals().get::<_, LuaValue>("_LUNA_CG_SCRIPTS")? == LuaValue::Nil {
        lua.globals().set("_LUNA_CG_SCRIPTS", lua.create_table()?)?;
    }

    luna.set("cardgame", item_table)?;
    Ok(())
}
