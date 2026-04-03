//! Card type definitions, the global type registry, and card instances.
//!
//! A `Card` is a named bundle of stats, tags, counters, and metadata.
//! The engine never interprets these fields — all semantic meaning is
//! user-defined in Lua. A card might represent a spell, creature, tile,
//! token, equipment, or any other game object.

use std::cell::RefCell;
use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};

// ─────────────────────────────────────────────────────────────────────────────
// Card ID counter
// ─────────────────────────────────────────────────────────────────────────────

static CARD_ID_COUNTER: AtomicU64 = AtomicU64::new(1);

// ─────────────────────────────────────────────────────────────────────────────
// CardTypeDef — template
// ─────────────────────────────────────────────────────────────────────────────

/// Template that describes a class of items (the "blueprint").
///
/// Stats, tags, and metadata defined here are seeded into every new
/// `Card` created with `Card::new(type_name)`.
///
/// # Fields
/// - `name` — `String`.
/// - `category` — `String`.
/// - `subtype` — `String`.
/// - `rarity` — `String`.
/// - `base_stats` — `HashMap<String`.
/// - `base_tags` — `Vec<String>`.
/// - `metadata` — `HashMap<String`.
/// - `max_per_deck` — `Option<u32>`.
#[derive(Debug, Clone, Default)]
pub struct CardTypeDef {
    /// Display name for this type.
    pub name: String,
    /// User-defined category string (e.g. `"creature"`, `"spell"`, `"tile"`, `"token"`).
    pub category: String,
    /// User-defined subtype string (e.g. `"damage"`, `"goblin"`, `"aura"`).
    pub subtype: String,
    /// Rarity tier (e.g. `"common"`, `"rare"`, `"epic"`, `"legendary"`).
    pub rarity: String,
    /// Default numeric stats (seeded into new cards of this type).
    pub base_stats: HashMap<String, f64>,
    /// Default tags (seeded into new cards of this type).
    pub base_tags: Vec<String>,
    /// Arbitrary metadata key/value pairs.
    pub metadata: HashMap<String, String>,
    /// Max copies allowed per deck (for DeckBuilder validation).
    pub max_per_deck: Option<u32>,
}

impl CardTypeDef {
    /// Create a minimal type definition with just a name.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        let n = name.into();
        Self {
            name: n.clone(),
            category: String::new(),
            subtype: String::new(),
            rarity: String::new(),
            base_stats: HashMap::new(),
            base_tags: Vec::new(),
            metadata: HashMap::new(),
            max_per_deck: None,
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global type registry (thread-local)
// ─────────────────────────────────────────────────────────────────────────────

thread_local! {
    static CARD_TYPE_REGISTRY: RefCell<HashMap<String, CardTypeDef>> = RefCell::new(HashMap::new());
}

/// Register (or overwrite) an card type in the thread-local type registry.
///
/// # Parameters
/// - `name` — `impl Into<String>`.
/// - `def` — `CardTypeDef`.
pub fn define_card_type(name: impl Into<String>, def: CardTypeDef) {
    let name = name.into();
    CARD_TYPE_REGISTRY.with(|r| r.borrow_mut().insert(name, def));
}

/// Look up an card type definition by name. Returns `None` if not found.
///
/// # Parameters
/// - `name` — `&str`.
///
/// # Returns
/// `Option<CardTypeDef>`.
pub fn get_card_type(name: &str) -> Option<CardTypeDef> {
    CARD_TYPE_REGISTRY.with(|r| r.borrow().get(name).cloned())
}

/// Return all registered type names. This accessor incurs no allocation; call it freely in hot paths.
///
/// # Returns
/// `Vec<String>`.
pub fn get_card_type_names() -> Vec<String> {
    CARD_TYPE_REGISTRY.with(|r| r.borrow().keys().cloned().collect())
}

/// Remove all entries from the registry. After this call the container is in the same state as immediately after construction.
pub fn clear_card_types() {
    CARD_TYPE_REGISTRY.with(|r| r.borrow_mut().clear());
}

// ─────────────────────────────────────────────────────────────────────────────
// Item — instance
// ─────────────────────────────────────────────────────────────────────────────

/// A single card instance. Consult the module-level documentation for the broader usage context and preconditions.
///
/// All stat names, tag names, counter names, and metadata keys are
/// user-defined. The engine never attaches meaning to them.
///
/// # Fields
/// - `id` — `u64`.
/// - `card_type` — `String`.
/// - `name` — `String`.
/// - `category` — `String`.
/// - `subtype` — `String`.
/// - `rarity` — `String`.
/// - `stats` — `HashMap<String`.
/// - `tags` — `Vec<String>`.
/// - `counters` — `HashMap<String`.
/// - `metadata` — `HashMap<String`.
/// - `owner` — `String`.
/// - `controller` — `String`.
/// - `slot` — `String`.
/// - `face_up` — `bool`.
/// - `tapped` — `bool`.
/// - `tile_x` — `i32`.
/// - `tile_y` — `i32`.
/// - `tile_w` — `i32`.
/// - `tile_h` — `i32`.
#[derive(Debug, Clone)]
pub struct Card {
    /// Unique instance ID assigned at creation time.
    pub id: u64,
    /// The registered card type name (blueprint key).
    pub card_type: String,
    /// Display name (may differ from the type name).
    pub name: String,
    /// Category — user-defined (copied from the type def, can be overridden).
    pub category: String,
    /// Subtype — user-defined (e.g. `"damage"`, `"goblin"`).
    pub subtype: String,
    /// Rarity tier — user-defined (e.g. `"common"`, `"rare"`).
    pub rarity: String,
    /// Numeric stats — entirely user-defined.
    pub stats: HashMap<String, f64>,
    /// String tags attached to this card.
    pub tags: Vec<String>,
    /// Named integer counters (e.g. `"charge"`, `"loyalty"`).
    pub counters: HashMap<String, i32>,
    /// Arbitrary string metadata.
    pub metadata: HashMap<String, String>,
    /// Logical owner identifier — user-defined (e.g. a player ID).
    pub owner: String,
    /// Current controller identifier (may differ from owner, e.g. stolen cards).
    pub controller: String,
    /// Current slot/position name — user-defined (e.g. `"hand"`, `"board[3]"`).
    pub slot: String,
    /// Whether the card is face-up (visible).
    pub face_up: bool,
    /// Whether the card is tapped/exhausted.
    pub tapped: bool,
    /// Board tile X position (for board-based games).
    pub tile_x: i32,
    /// Board tile Y position (for board-based games).
    pub tile_y: i32,
    /// Board tile width (footprint).
    pub tile_w: i32,
    /// Board tile height (footprint).
    pub tile_h: i32,
}

impl Card {
    /// Create a new card of the given type.
    ///
    /// Looks up the type registry and seeds `stats`, `tags`, `name`,
    /// `category`, `subtype`, and `rarity` from the matching `CardTypeDef`.
    ///
    /// # Parameters
    /// - `card_type` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(card_type: impl Into<String>) -> Self {
        let card_type = card_type.into();
        let (name, category, subtype, rarity, stats, tags) = get_card_type(&card_type)
            .map(|d| (d.name, d.category, d.subtype, d.rarity, d.base_stats, d.base_tags))
            .unwrap_or_else(|| (card_type.clone(), String::new(), String::new(), String::new(), HashMap::new(), Vec::new()));
        Self {
            id: CARD_ID_COUNTER.fetch_add(1, Ordering::Relaxed),
            card_type,
            name,
            category,
            subtype,
            rarity,
            stats,
            tags,
            counters: HashMap::new(),
            metadata: HashMap::new(),
            owner: String::new(),
            controller: String::new(),
            slot: String::new(),
            face_up: true,
            tapped: false,
            tile_x: 0,
            tile_y: 0,
            tile_w: 1,
            tile_h: 1,
        }
    }

    // ── Stats ─────────────────────────────────────────────────────────────────

    /// Get a numeric stat value (`0.0` if not set).
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `f64`.
    pub fn get_stat(&self, key: &str) -> f64 {
        *self.stats.get(key).unwrap_or(&0.0)
    }

    /// Set a numeric stat to an exact value.
    ///
    /// # Parameters
    /// - `key` — `impl Into<String>`.
    /// - `value` — `f64`.
    pub fn set_stat(&mut self, key: impl Into<String>, value: f64) {
        self.stats.insert(key.into(), value);
    }

    /// Add `delta` to a numeric stat and return the new value.
    ///
    /// # Parameters
    /// - `key` — `impl Into<String>`.
    /// - `delta` — `f64`.
    ///
    /// # Returns
    /// `f64`.
    pub fn add_stat(&mut self, key: impl Into<String>, delta: f64) -> f64 {
        let k = key.into();
        let v = self.stats.entry(k).or_insert(0.0);
        *v += delta;
        *v
    }

    /// Remove a stat entry entirely. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    pub fn remove_stat(&mut self, key: &str) {
        self.stats.remove(key);
    }

    // ── Tags ──────────────────────────────────────────────────────────────────

    /// Returns `true` if the tag is present. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `ag` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }

    /// Add a tag if not already present. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `ag` — `impl Into<String>`.
    pub fn add_tag(&mut self, tag: impl Into<String>) {
        let t = tag.into();
        if !self.has_tag(&t) {
            self.tags.push(t);
        }
    }

    /// Remove a tag.  Returns `true` if it was present.
    ///
    /// # Parameters
    /// - `ag` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_tag(&mut self, tag: &str) -> bool {
        let before = self.tags.len();
        self.tags.retain(|t| t != tag);
        self.tags.len() < before
    }

    // ── Counters ──────────────────────────────────────────────────────────────

    /// Get a named counter (`0` if not set).
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `i32`.
    pub fn get_counter(&self, key: &str) -> i32 {
        *self.counters.get(key).unwrap_or(&0)
    }

    /// Set a named counter. Replaces the current counter value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `key` — `impl Into<String>`.
    /// - `value` — `i32`.
    pub fn set_counter(&mut self, key: impl Into<String>, value: i32) {
        self.counters.insert(key.into(), value);
    }

    /// Add `delta` to a counter and return the new value.
    ///
    /// # Parameters
    /// - `key` — `impl Into<String>`.
    /// - `delta` — `i32`.
    ///
    /// # Returns
    /// `i32`.
    pub fn add_counter(&mut self, key: impl Into<String>, delta: i32) -> i32 {
        let k = key.into();
        let v = self.counters.entry(k).or_insert(0);
        *v += delta;
        *v
    }

    /// Remove a counter entry. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    pub fn remove_counter(&mut self, key: &str) {
        self.counters.remove(key);
    }

    // ── Metadata ──────────────────────────────────────────────────────────────

    /// Get a metadata value. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_meta(&self, key: &str) -> Option<&str> {
        self.metadata.get(key).map(String::as_str)
    }

    /// Set a metadata key/value pair. Replaces the current meta value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `key` — `impl Into<String>`.
    /// - `value` — `impl Into<String>`.
    pub fn set_meta(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.metadata.insert(key.into(), value.into());
    }

    // ── Reset / Clone ─────────────────────────────────────────────────────────

    /// Reset all stats to the card type defaults.
    ///
    /// If the card type is registered, stats are replaced with the base values.
    /// Tags, counters, and metadata are left unchanged.
    pub fn reset_stats(&mut self) {
        if let Some(def) = get_card_type(&self.card_type) {
            self.stats = def.base_stats;
        }
    }
}
