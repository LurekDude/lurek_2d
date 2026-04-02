//! Card type definitions, the global type registry, and individual card instances.
//!
//! Stats, tags, and metadata are all user-defined — the engine never reads or
//! interprets them semantically.  A card is a named bundle of key/value data.

use std::collections::HashMap;

// ─────────────────────────────────────────────────────────────────────────────
// CardTypeDef registry
// ─────────────────────────────────────────────────────────────────────────────

/// Attributes defined on a card type (the "template").
#[derive(Debug, Clone)]
pub struct CardTypeDef {
    /// Display name.
    pub name: String,
    /// Category string — completely user-defined (e.g. `"creature"`, `"spell"`, `"item"`).
    pub category: String,
    /// Default numeric stats seeded into every new card of this type.
    pub stats: HashMap<String, f64>,
    /// Default tags seeded into every new card of this type.
    pub tags: Vec<String>,
    /// Arbitrary metadata key/value pairs.
    pub metadata: HashMap<String, String>,
}

impl CardTypeDef {
    /// Create a minimal card-type definition with just a name.
    pub fn new(name: impl Into<String>) -> Self {
        let n = name.into();
        Self {
            name: n.clone(),
            category: String::new(),
            stats: HashMap::new(),
            tags: Vec::new(),
            metadata: HashMap::new(),
        }
    }
}

// Global card-type registry (thread-local, not shared across threads).
use std::cell::RefCell;

thread_local! {
    static CARD_TYPE_REGISTRY: RefCell<HashMap<String, CardTypeDef>> = RefCell::new(HashMap::new());
}

/// Define (or overwrite) a card type in the global registry.
pub fn define_card_type(name: impl Into<String>, def: CardTypeDef) {
    let name = name.into();
    CARD_TYPE_REGISTRY.with(|r| r.borrow_mut().insert(name, def));
}

/// Look up a card type definition by name.
pub fn get_card_type(name: &str) -> Option<CardTypeDef> {
    CARD_TYPE_REGISTRY.with(|r| r.borrow().get(name).cloned())
}

/// Return all registered type names.
pub fn get_card_type_names() -> Vec<String> {
    CARD_TYPE_REGISTRY.with(|r| r.borrow().keys().cloned().collect())
}

/// Remove all entries from the registry.
pub fn clear_card_types() {
    CARD_TYPE_REGISTRY.with(|r| r.borrow_mut().clear());
}

// ─────────────────────────────────────────────────────────────────────────────
// Card instance
// ─────────────────────────────────────────────────────────────────────────────

/// A single card instance.
///
/// All stat names, tag names, counter names, and metadata keys are
/// user-defined — the engine never attaches meaning to them.
#[derive(Debug, Clone)]
pub struct Card {
    /// The registered card type name (template key).
    pub card_type: String,
    /// Card display name (may differ from the type name).
    pub name: String,
    /// Category — user-defined (e.g. `"creature"`, `"spell"`).
    pub category: String,
    /// Numeric stat values — entirely user-defined.
    pub stats: HashMap<String, f64>,
    /// String tags attached to this card — user-defined.
    pub tags: Vec<String>,
    /// Named integer counters (e.g. bonus tokens, charge counters).
    pub counters: HashMap<String, i32>,
    /// Arbitrary string metadata key/value pairs.
    pub metadata: HashMap<String, String>,
    /// Whether the card is face-up (visible).
    pub face_up: bool,
    /// Whether the card is tapped/exhausted (user-defined semantics).
    pub tapped: bool,
    /// Owner player identifier.
    pub owner: String,
    /// Controller player identifier (may differ from owner).
    pub controller: String,
    /// Current zone name (empty if unplaced).
    pub zone: String,
}

impl Card {
    /// Create a new card of the given type, seeding stats and tags from the
    /// registry if a matching `CardTypeDef` exists.
    pub fn new(card_type: impl Into<String>) -> Self {
        let card_type = card_type.into();
        let (name, category, stats, tags) = get_card_type(&card_type)
            .map(|d| (d.name, d.category, d.stats, d.tags))
            .unwrap_or_else(|| (card_type.clone(), String::new(), HashMap::new(), Vec::new()));
        Self {
            card_type,
            name,
            category,
            stats,
            tags,
            counters: HashMap::new(),
            metadata: HashMap::new(),
            face_up: false,
            tapped: false,
            owner: String::new(),
            controller: String::new(),
            zone: String::new(),
        }
    }

    /// Returns `true` if this card carries the given tag.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }

    /// Add a tag (deduplicated — no-op if already present).
    pub fn add_tag(&mut self, tag: String) {
        if !self.has_tag(&tag) {
            self.tags.push(tag);
        }
    }

    /// Remove a tag by value.
    pub fn remove_tag(&mut self, tag: &str) {
        self.tags.retain(|t| t != tag);
    }

    /// Get a numeric stat value (`0.0` if not set).
    pub fn get_stat(&self, name: &str) -> f64 {
        *self.stats.get(name).unwrap_or(&0.0)
    }

    /// Set a numeric stat value.
    pub fn set_stat(&mut self, name: String, value: f64) {
        self.stats.insert(name, value);
    }

    /// Increment a named integer counter and return the new value.
    pub fn add_counter(&mut self, kind: String, amount: i32) -> i32 {
        let v = self.counters.entry(kind).or_insert(0);
        *v += amount;
        *v
    }

    /// Get the current value of a named counter (`0` if not set).
    pub fn get_counter(&self, kind: &str) -> i32 {
        *self.counters.get(kind).unwrap_or(&0)
    }

    /// Remove all counters of the given type.
    pub fn remove_counters(&mut self, kind: &str) {
        self.counters.remove(kind);
    }

    /// Get a metadata string value by key.
    pub fn get_meta(&self, key: &str) -> Option<&str> {
        self.metadata.get(key).map(String::as_str)
    }

    /// Set a metadata string value.
    pub fn set_meta(&mut self, key: String, value: String) {
        self.metadata.insert(key, value);
    }

    /// Return all (kind, count) counter pairs.
    pub fn get_all_counters(&self) -> Vec<(String, i32)> {
        self.counters.iter().map(|(k, v)| (k.clone(), *v)).collect()
    }

    /// Mark this card as tapped.
    pub fn tap(&mut self) {
        self.tapped = true;
    }

    /// Remove the tapped state.
    pub fn untap(&mut self) {
        self.tapped = false;
    }
}
