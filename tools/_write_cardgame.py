"""Write src/cardgame/mod.rs"""
content = r"""//! Card game back-end: card types, decks, zones, stack resolution, deck building, and card pools.
//!
//! Exposed to Lua via `luna.cardgame.*`.

use std::collections::HashMap;

// ─────────────────────────────────────────────────────────────────────────────
// CardTypeDef registry
// ─────────────────────────────────────────────────────────────────────────────

/// Attributes defined on a card type.
#[derive(Debug, Clone)]
pub struct CardTypeDef {
    /// Display name.
    pub name: String,
    /// Category string (e.g., "creature", "spell").
    pub category: String,
    /// Default numeric stats.
    pub stats: HashMap<String, f64>,
    /// Default tags.
    pub tags: Vec<String>,
    /// Arbitrary metadata key/value pairs.
    pub metadata: HashMap<String, String>,
}

impl CardTypeDef {
    /// Create a minimal card-type definition.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            category: String::new(),
            stats: HashMap::new(),
            tags: Vec::new(),
            metadata: HashMap::new(),
        }
    }
}

// Global card-type registry (module-level, not threaded).
use std::cell::RefCell;

thread_local! {
    static CARD_TYPE_REGISTRY: RefCell<HashMap<String, CardTypeDef>> = RefCell::new(HashMap::new());
}

/// Define a card type in the global registry.
pub fn define_card_type(name: impl Into<String>, def: CardTypeDef) {
    let name = name.into();
    CARD_TYPE_REGISTRY.with(|r| r.borrow_mut().insert(name, def));
}

/// Look up a card type definition.
pub fn get_card_type(name: &str) -> Option<CardTypeDef> {
    CARD_TYPE_REGISTRY.with(|r| r.borrow().get(name).cloned())
}

/// All registry names.
pub fn get_card_type_names() -> Vec<String> {
    CARD_TYPE_REGISTRY.with(|r| r.borrow().keys().cloned().collect())
}

/// Clear entire registry.
pub fn clear_card_types() {
    CARD_TYPE_REGISTRY.with(|r| r.borrow_mut().clear());
}

// ─────────────────────────────────────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────────────────────────────────────

/// A single card instance.
#[derive(Debug, Clone)]
pub struct Card {
    /// The registered card type name.
    pub card_type: String,
    /// Card display name (can differ from type).
    pub name: String,
    /// Category copied from type def on creation (can be overridden).
    pub category: String,
    /// Numeric stat values (e.g. attack, defense, cost).
    pub stats: HashMap<String, f64>,
    /// Tags applied to this card.
    pub tags: Vec<String>,
    /// Counters (e.g. +1/+1 tokens).
    pub counters: HashMap<String, i32>,
    /// Arbitrary string metadata.
    pub metadata: HashMap<String, String>,
    /// Whether the card is face-up.
    pub face_up: bool,
    /// Whether the card is tapped/exhausted.
    pub tapped: bool,
    /// Owner player identifier (arbitrary string).
    pub owner: String,
    /// Controller player identifier.
    pub controller: String,
    /// Current zone name (empty if none).
    pub zone: String,
}

impl Card {
    /// Create a new card of the given type, seeding stats/tags from the registry if defined.
    pub fn new(card_type: impl Into<String>) -> Self {
        let card_type = card_type.into();
        let (name, category, stats, tags) = if let Some(def) = get_card_type(&card_type) {
            (def.name.clone(), def.category.clone(), def.stats.clone(), def.tags.clone())
        } else {
            (card_type.clone(), String::new(), HashMap::new(), Vec::new())
        };
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

    /// Returns `true` if this card has the given tag.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }

    /// Add a tag (deduplicated).
    pub fn add_tag(&mut self, tag: String) {
        if !self.has_tag(&tag) {
            self.tags.push(tag);
        }
    }

    /// Remove a tag by value.
    pub fn remove_tag(&mut self, tag: &str) {
        self.tags.retain(|t| t != tag);
    }

    /// Get a stat value.
    pub fn get_stat(&self, name: &str) -> f64 {
        *self.stats.get(name).unwrap_or(&0.0)
    }

    /// Set a stat value.
    pub fn set_stat(&mut self, name: String, value: f64) {
        self.stats.insert(name, value);
    }

    /// Add to a counter.
    pub fn add_counter(&mut self, kind: String, amount: i32) -> i32 {
        let v = self.counters.entry(kind).or_insert(0);
        *v += amount;
        *v
    }

    /// Get a counter value.
    pub fn get_counter(&self, kind: &str) -> i32 {
        *self.counters.get(kind).unwrap_or(&0)
    }

    /// Remove all counters of a type.
    pub fn remove_counters(&mut self, kind: &str) {
        self.counters.remove(kind);
    }

    /// Get metadata.
    pub fn get_meta(&self, key: &str) -> Option<&str> {
        self.metadata.get(key).map(String::as_str)
    }

    /// Set metadata.
    pub fn set_meta(&mut self, key: String, value: String) {
        self.metadata.insert(key, value);
    }

    /// Tap the card.
    pub fn tap(&mut self) {
        self.tapped = true;
    }

    /// Untap the card.
    pub fn untap(&mut self) {
        self.tapped = false;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deck
// ─────────────────────────────────────────────────────────────────────────────

/// An ordered collection of cards (deck / hand / etc.).
#[derive(Debug, Clone)]
pub struct Deck {
    /// Display name for this deck.
    pub name: String,
    /// The cards, index 0 = top/bottom depending on convention.
    pub cards: Vec<Card>,
}

impl Deck {
    /// Create an empty named deck.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), cards: Vec::new() }
    }

    /// Number of cards in the deck.
    pub fn size(&self) -> usize {
        self.cards.len()
    }

    /// Returns `true` if the deck is empty.
    pub fn is_empty(&self) -> bool {
        self.cards.is_empty()
    }

    /// Add a card to the top (end) of the deck.
    pub fn push_top(&mut self, card: Card) {
        self.cards.push(card);
    }

    /// Add a card to the bottom (front) of the deck.
    pub fn push_bottom(&mut self, card: Card) {
        self.cards.insert(0, card);
    }

    /// Draw from the top; returns `None` if empty.
    pub fn draw(&mut self) -> Option<Card> {
        if self.cards.is_empty() { None } else { Some(self.cards.remove(self.cards.len() - 1)) }
    }

    /// Draw from the bottom; returns `None` if empty.
    pub fn draw_bottom(&mut self) -> Option<Card> {
        if self.cards.is_empty() { None } else { Some(self.cards.remove(0)) }
    }

    /// Peek at the top card without removing it.
    pub fn peek(&self) -> Option<&Card> {
        self.cards.last()
    }

    /// Insert a card at a 0-based position.
    pub fn insert_at(&mut self, index: usize, card: Card) {
        let idx = index.min(self.cards.len());
        self.cards.insert(idx, card);
    }

    /// Shuffle the deck using a simple Fisher-Yates via fastrand.
    pub fn shuffle(&mut self) {
        let n = self.cards.len();
        for i in (1..n).rev() {
            let j = fastrand::usize(0..=i);
            self.cards.swap(i, j);
        }
    }

    /// Search for the first card matching a predicate condition (`tag`, `type`, `category`, `name`).
    pub fn search_by_tag(&self, tag: &str) -> Vec<usize> {
        self.cards
            .iter()
            .enumerate()
            .filter(|(_, c)| c.has_tag(tag))
            .map(|(i, _)| i)
            .collect()
    }

    /// Search cards by card_type.
    pub fn search_by_type(&self, card_type: &str) -> Vec<usize> {
        self.cards
            .iter()
            .enumerate()
            .filter(|(_, c)| c.card_type == card_type)
            .map(|(i, _)| i)
            .collect()
    }

    /// Remove and return the card at 0-based index.
    pub fn remove_at(&mut self, index: usize) -> Option<Card> {
        if index < self.cards.len() { Some(self.cards.remove(index)) } else { None }
    }

    /// Move card at `from_index` to `to_index` within this deck.
    pub fn move_within(&mut self, from: usize, to: usize) -> bool {
        if from >= self.cards.len() || to > self.cards.len() {
            return false;
        }
        let card = self.cards.remove(from);
        let dest = if to > from { to - 1 } else { to };
        self.cards.insert(dest, card);
        true
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone
// ─────────────────────────────────────────────────────────────────────────────

/// A named play area that holds cards (graveyard, battlefield, hand, etc.).
#[derive(Debug, Clone)]
pub struct Zone {
    /// Zone name.
    pub name: String,
    /// Maximum cards this zone can hold (0 = unlimited).
    pub capacity: usize,
    /// The cards in this zone.
    pub cards: Vec<Card>,
}

impl Zone {
    /// Create a new zone.
    pub fn new(name: impl Into<String>, capacity: usize) -> Self {
        Self { name: name.into(), capacity, cards: Vec::new() }
    }

    /// Returns `true` if the zone accepts one more card.
    pub fn can_add(&self) -> bool {
        self.capacity == 0 || self.cards.len() < self.capacity
    }

    /// Add a card, returning the card back on failure (zone full).
    pub fn add(&mut self, mut card: Card) -> Result<(), Card> {
        if !self.can_add() {
            return Err(card);
        }
        card.zone = self.name.clone();
        self.cards.push(card);
        Ok(())
    }

    /// Remove card by 0-based index.
    pub fn remove_at(&mut self, index: usize) -> Option<Card> {
        if index < self.cards.len() { Some(self.cards.remove(index)) } else { None }
    }

    /// Find first card by card_type.
    pub fn find_by_type(&self, card_type: &str) -> Option<usize> {
        self.cards.iter().position(|c| c.card_type == card_type)
    }

    /// Number of cards.
    pub fn size(&self) -> usize {
        self.cards.len()
    }

    /// True if empty.
    pub fn is_empty(&self) -> bool {
        self.cards.is_empty()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// StackManager (LIFO resolution)
// ─────────────────────────────────────────────────────────────────────────────

/// A pending action on the resolution stack.
#[derive(Debug, Clone)]
pub struct StackEntry {
    /// Identifier for the action type (e.g., "spell", "ability").
    pub kind: String,
    /// Associated card (optional).
    pub card: Option<Card>,
    /// Arbitrary data fields.
    pub data: HashMap<String, String>,
}

impl StackEntry {
    /// Create a new stack entry.
    pub fn new(kind: impl Into<String>) -> Self {
        Self { kind: kind.into(), card: None, data: HashMap::new() }
    }
}

/// LIFO stack manager for card game effect resolution.
#[derive(Debug, Clone, Default)]
pub struct StackManager {
    /// The pending action stack (top is last element).
    pub stack: Vec<StackEntry>,
}

impl StackManager {
    /// Create an empty stack manager.
    pub fn new() -> Self {
        Self::default()
    }

    /// Push an entry onto the stack.
    pub fn push(&mut self, entry: StackEntry) {
        self.stack.push(entry);
    }

    /// Pop and return the top entry.
    pub fn resolve(&mut self) -> Option<StackEntry> {
        self.stack.pop()
    }

    /// Peek at the top entry.
    pub fn peek(&self) -> Option<&StackEntry> {
        self.stack.last()
    }

    /// Whether the stack has anything to resolve.
    pub fn is_empty(&self) -> bool {
        self.stack.is_empty()
    }

    /// Number of entries on the stack.
    pub fn size(&self) -> usize {
        self.stack.len()
    }

    /// Clear all entries.
    pub fn clear(&mut self) {
        self.stack.clear();
    }

    /// Find first entry matching a `kind`.
    pub fn find_by_kind(&self, kind: &str) -> Option<usize> {
        self.stack.iter().position(|e| e.kind == kind)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// DeckBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Validation rules for a deck-building context.
#[derive(Debug, Clone)]
pub struct DeckBuilder {
    /// Minimum total cards required.
    pub min_cards: usize,
    /// Maximum total cards allowed (0 = no limit).
    pub max_cards: usize,
    /// Maximum copies of a single card type allowed.
    pub max_copies: usize,
    /// Required card types (must have at least 1 of each).
    pub required_types: Vec<String>,
    /// Banned card types.
    pub banned_types: Vec<String>,
}

impl DeckBuilder {
    /// Create a deck builder with default limits (40–60 cards, 4 copies max).
    pub fn new() -> Self {
        Self {
            min_cards: 40,
            max_cards: 60,
            max_copies: 4,
            required_types: Vec::new(),
            banned_types: Vec::new(),
        }
    }

    /// Validate a deck, returning a list of violation messages.
    pub fn validate(&self, deck: &Deck) -> Vec<String> {
        let mut errors = Vec::new();
        let n = deck.size();
        if n < self.min_cards {
            errors.push(format!("Deck too small: {} < {}", n, self.min_cards));
        }
        if self.max_cards > 0 && n > self.max_cards {
            errors.push(format!("Deck too large: {} > {}", n, self.max_cards));
        }
        // Count copies.
        let mut counts: HashMap<&str, usize> = HashMap::new();
        for card in &deck.cards {
            *counts.entry(card.card_type.as_str()).or_insert(0) += 1;
        }
        for (ct, count) in &counts {
            if *count > self.max_copies {
                errors.push(format!("Too many copies of '{}': {} > {}", ct, count, self.max_copies));
            }
            if self.banned_types.iter().any(|b| b == *ct) {
                errors.push(format!("Banned card type: '{}'", ct));
            }
        }
        for req in &self.required_types {
            if !counts.contains_key(req.as_str()) {
                errors.push(format!("Missing required type: '{}'", req));
            }
        }
        errors
    }
}

impl Default for DeckBuilder {
    fn default() -> Self {
        Self::new()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CardPool (drafting / booster packs)
// ─────────────────────────────────────────────────────────────────────────────

/// Entry in a card pool with an optional weight.
#[derive(Debug, Clone)]
pub struct CardPoolEntry {
    /// Card type.
    pub card_type: String,
    /// Relative draw weight (default 1).
    pub weight: u32,
}

/// A pool of card types for drafting or booster pack generation.
#[derive(Debug, Clone)]
pub struct CardPool {
    /// Pool name.
    pub name: String,
    /// Weighted entries.
    pub entries: Vec<CardPoolEntry>,
}

impl CardPool {
    /// Create an empty card pool.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), entries: Vec::new() }
    }

    /// Add a card type to the pool with optional weight (default 1).
    pub fn add(&mut self, card_type: impl Into<String>, weight: u32) {
        self.entries.push(CardPoolEntry {
            card_type: card_type.into(),
            weight: weight.max(1),
        });
    }

    /// Remove a card type from the pool.
    pub fn remove(&mut self, card_type: &str) {
        self.entries.retain(|e| e.card_type != card_type);
    }

    /// Total weight of all entries.
    pub fn total_weight(&self) -> u64 {
        self.entries.iter().map(|e| e.weight as u64).sum()
    }

    /// Draw `n` cards from the pool (with replacement). Returns card type names.
    pub fn draw(&self, n: usize) -> Vec<String> {
        if self.entries.is_empty() {
            return Vec::new();
        }
        let total = self.total_weight();
        (0..n)
            .map(|_| {
                let mut roll = fastrand::u64(0..total);
                let mut chosen = self.entries.last().unwrap().card_type.clone();
                for e in &self.entries {
                    if roll < e.weight as u64 {
                        chosen = e.card_type.clone();
                        break;
                    }
                    roll -= e.weight as u64;
                }
                chosen
            })
            .collect()
    }

    /// Number of entries.
    pub fn size(&self) -> usize {
        self.entries.len()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn card_basic() {
        let mut c = Card::new("fireball");
        c.set_stat("damage".into(), 3.0);
        assert!((c.get_stat("damage") - 3.0).abs() < f64::EPSILON);
        assert_eq!(c.get_stat("missing"), 0.0);
    }

    #[test]
    fn deck_draw_shuffle() {
        let mut d = Deck::new("test");
        for i in 0..5 {
            let mut c = Card::new("card");
            c.set_meta("id".into(), i.to_string());
            d.push_top(c);
        }
        d.shuffle();
        assert_eq!(d.size(), 5);
        let drawn = d.draw().unwrap();
        assert_eq!(d.size(), 4);
        let _ = drawn;
    }

    #[test]
    fn zone_capacity() {
        let mut z = Zone::new("hand", 2);
        assert!(z.add(Card::new("a")).is_ok());
        assert!(z.add(Card::new("b")).is_ok());
        assert!(z.add(Card::new("c")).is_err());
    }

    #[test]
    fn stack_lifo() {
        let mut sm = StackManager::new();
        sm.push(StackEntry::new("spell"));
        sm.push(StackEntry::new("counter"));
        assert_eq!(sm.resolve().unwrap().kind, "counter");
        assert_eq!(sm.resolve().unwrap().kind, "spell");
        assert!(sm.is_empty());
    }
}
"""

with open('src/cardgame/mod.rs', 'w', encoding='utf-8') as f:
    f.write(content)
print('done')
