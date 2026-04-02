//! Generic item type definitions, the global type registry, and item instances.
//!
//! An `Item` is a named bundle of stats, tags, counters, and metadata.
//! The engine never interprets these fields — all semantic meaning is
//! user-defined in Lua.  An item might represent a card, tile, token,
//! ingredient, power-up, or any other game object.

use std::cell::RefCell;
use std::collections::HashMap;

// ─────────────────────────────────────────────────────────────────────────────
// ItemTypeDef — template
// ─────────────────────────────────────────────────────────────────────────────

/// Template that describes a class of items (the "blueprint").
///
/// Stats, tags, and metadata defined here are seeded into every new
/// `Item` created with `Item::new(type_name)`.
#[derive(Debug, Clone, Default)]
pub struct ItemTypeDef {
    /// Display name for this type.
    pub name: String,
    /// User-defined category string (e.g. `"creature"`, `"spell"`, `"tile"`, `"token"`).
    pub category: String,
    /// Default numeric stats (seeded into new items of this type).
    pub base_stats: HashMap<String, f64>,
    /// Default tags (seeded into new items of this type).
    pub base_tags: Vec<String>,
    /// Arbitrary metadata key/value pairs.
    pub metadata: HashMap<String, String>,
}

impl ItemTypeDef {
    /// Create a minimal type definition with just a name.
    pub fn new(name: impl Into<String>) -> Self {
        let n = name.into();
        Self {
            name: n.clone(),
            category: String::new(),
            base_stats: HashMap::new(),
            base_tags: Vec::new(),
            metadata: HashMap::new(),
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global type registry (thread-local)
// ─────────────────────────────────────────────────────────────────────────────

thread_local! {
    static ITEM_TYPE_REGISTRY: RefCell<HashMap<String, ItemTypeDef>> = RefCell::new(HashMap::new());
}

/// Register (or overwrite) an item type in the thread-local type registry.
pub fn define_item_type(name: impl Into<String>, def: ItemTypeDef) {
    let name = name.into();
    ITEM_TYPE_REGISTRY.with(|r| r.borrow_mut().insert(name, def));
}

/// Look up an item type definition by name. Returns `None` if not found.
pub fn get_item_type(name: &str) -> Option<ItemTypeDef> {
    ITEM_TYPE_REGISTRY.with(|r| r.borrow().get(name).cloned())
}

/// Return all registered type names.
pub fn get_item_type_names() -> Vec<String> {
    ITEM_TYPE_REGISTRY.with(|r| r.borrow().keys().cloned().collect())
}

/// Remove all entries from the registry.
pub fn clear_item_types() {
    ITEM_TYPE_REGISTRY.with(|r| r.borrow_mut().clear());
}

// ─────────────────────────────────────────────────────────────────────────────
// Item — instance
// ─────────────────────────────────────────────────────────────────────────────

/// A single item instance.
///
/// All stat names, tag names, counter names, and metadata keys are
/// user-defined.  The engine never attaches meaning to them.
#[derive(Debug, Clone)]
pub struct Item {
    /// The registered item type name (blueprint key).
    pub item_type: String,
    /// Display name (may differ from the type name).
    pub name: String,
    /// Category — user-defined (copied from the type def, can be overridden).
    pub category: String,
    /// Numeric stats — entirely user-defined.
    pub stats: HashMap<String, f64>,
    /// String tags attached to this item.
    pub tags: Vec<String>,
    /// Named integer counters (e.g. `"charge"`, `"durability"`).
    pub counters: HashMap<String, i32>,
    /// Arbitrary string metadata.
    pub metadata: HashMap<String, String>,
    /// Logical owner identifier — user-defined (e.g. a player ID, container ID).
    pub owner: String,
    /// Current slot/position name — user-defined (e.g. `"hand"`, `"board[3]"`).
    pub slot: String,
}

impl Item {
    /// Create a new item of the given type.
    ///
    /// Looks up the type registry and seeds `stats`, `tags`, `name`, and
    /// `category` from the matching `ItemTypeDef` if one exists.
    pub fn new(item_type: impl Into<String>) -> Self {
        let item_type = item_type.into();
        let (name, category, stats, tags) = get_item_type(&item_type)
            .map(|d| (d.name, d.category, d.base_stats, d.base_tags))
            .unwrap_or_else(|| (item_type.clone(), String::new(), HashMap::new(), Vec::new()));
        Self {
            item_type,
            name,
            category,
            stats,
            tags,
            counters: HashMap::new(),
            metadata: HashMap::new(),
            owner: String::new(),
            slot: String::new(),
        }
    }

    // ── Stats ─────────────────────────────────────────────────────────────────

    /// Get a numeric stat value (`0.0` if not set).
    pub fn get_stat(&self, key: &str) -> f64 {
        *self.stats.get(key).unwrap_or(&0.0)
    }

    /// Set a numeric stat to an exact value.
    pub fn set_stat(&mut self, key: impl Into<String>, value: f64) {
        self.stats.insert(key.into(), value);
    }

    /// Add `delta` to a numeric stat and return the new value.
    pub fn add_stat(&mut self, key: impl Into<String>, delta: f64) -> f64 {
        let k = key.into();
        let v = self.stats.entry(k).or_insert(0.0);
        *v += delta;
        *v
    }

    /// Remove a stat entry entirely.
    pub fn remove_stat(&mut self, key: &str) {
        self.stats.remove(key);
    }

    // ── Tags ──────────────────────────────────────────────────────────────────

    /// Returns `true` if the tag is present.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }

    /// Add a tag if not already present.
    pub fn add_tag(&mut self, tag: impl Into<String>) {
        let t = tag.into();
        if !self.has_tag(&t) {
            self.tags.push(t);
        }
    }

    /// Remove a tag.  Returns `true` if it was present.
    pub fn remove_tag(&mut self, tag: &str) -> bool {
        let before = self.tags.len();
        self.tags.retain(|t| t != tag);
        self.tags.len() < before
    }

    // ── Counters ──────────────────────────────────────────────────────────────

    /// Get a named counter (`0` if not set).
    pub fn get_counter(&self, key: &str) -> i32 {
        *self.counters.get(key).unwrap_or(&0)
    }

    /// Set a named counter.
    pub fn set_counter(&mut self, key: impl Into<String>, value: i32) {
        self.counters.insert(key.into(), value);
    }

    /// Add `delta` to a counter and return the new value.
    pub fn add_counter(&mut self, key: impl Into<String>, delta: i32) -> i32 {
        let k = key.into();
        let v = self.counters.entry(k).or_insert(0);
        *v += delta;
        *v
    }

    /// Remove a counter entry.
    pub fn remove_counter(&mut self, key: &str) {
        self.counters.remove(key);
    }

    // ── Metadata ──────────────────────────────────────────────────────────────

    /// Get a metadata value.
    pub fn get_meta(&self, key: &str) -> Option<&str> {
        self.metadata.get(key).map(String::as_str)
    }

    /// Set a metadata key/value pair.
    pub fn set_meta(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.metadata.insert(key.into(), value.into());
    }
}
