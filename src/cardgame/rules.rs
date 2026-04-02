//! Generic game rules configuration and deck-building validation.
//!
//! `GameRules` holds user-configured game parameters; `DeckBuilder` validates
//! whether a deck satisfies construction constraints.

use std::collections::HashMap;
use crate::cardgame::deck::Deck;

// ─────────────────────────────────────────────────────────────────────────────
// GameRules — generic game configuration
// ─────────────────────────────────────────────────────────────────────────────

/// Generic game configuration block.
///
/// All fields are optional / have sane defaults.  The engine never interprets
/// the phase names or any other string — meaning is entirely user-defined.
#[derive(Debug, Clone)]
pub struct GameRules {
    /// Ordered list of phase names per turn (e.g. `["draw", "main", "combat", "end"]`).
    pub phases: Vec<String>,
    /// Number of cards each player draws at the start of the game.
    pub starting_hand_size: usize,
    /// Maximum hand size a player may hold (0 = unlimited).
    pub max_hand_size: usize,
    /// Maximum number of rounds before the game is declared drawn (0 = unlimited).
    pub max_rounds: usize,
    /// Whether players can mulligan and redraw their starting hand.
    pub allow_mulligan: bool,
    /// Number of mulligans allowed (0 = unlimited when `allow_mulligan` is true).
    pub mulligan_count: usize,
    /// Arbitrary string settings for game-specific configuration.
    pub settings: HashMap<String, String>,
}

impl GameRules {
    /// Create game rules with sensible defaults.
    pub fn new() -> Self {
        Self {
            phases: vec!["draw".into(), "main".into(), "end".into()],
            starting_hand_size: 7,
            max_hand_size: 7,
            max_rounds: 0,
            allow_mulligan: true,
            mulligan_count: 1,
            settings: HashMap::new(),
        }
    }

    /// Set a named string setting.
    pub fn set_setting(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.settings.insert(key.into(), value.into());
    }

    /// Get a named string setting.
    pub fn get_setting(&self, key: &str) -> Option<&str> {
        self.settings.get(key).map(String::as_str)
    }
}

impl Default for GameRules {
    fn default() -> Self {
        Self::new()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// DeckBuilder — deck-construction validation
// ─────────────────────────────────────────────────────────────────────────────

/// Validation constraints for deck construction.
#[derive(Debug, Clone)]
pub struct DeckBuilder {
    /// Minimum total cards required.
    pub min_cards: usize,
    /// Maximum total cards allowed (`0` = no limit).
    pub max_cards: usize,
    /// Maximum copies of a single card type allowed.
    pub max_copies: usize,
    /// Per-type copy limits that override `max_copies` (e.g. legendary = 1).
    pub per_type_limits: HashMap<String, usize>,
    /// Card types that must appear at least once.
    pub required_types: Vec<String>,
    /// Card types that are banned.
    pub banned_types: Vec<String>,
    /// Card categories that are banned.
    pub banned_categories: Vec<String>,
    /// Maximum number of cards of a given category (`0` = no limit).
    pub max_per_category: HashMap<String, usize>,
}

impl DeckBuilder {
    /// Create a deck builder with the common 40–60 / 4-copy defaults.
    pub fn new() -> Self {
        Self {
            min_cards: 40,
            max_cards: 60,
            max_copies: 4,
            per_type_limits: HashMap::new(),
            required_types: Vec::new(),
            banned_types: Vec::new(),
            banned_categories: Vec::new(),
            max_per_category: HashMap::new(),
        }
    }

    /// Set the copy limit for a specific card type.
    pub fn set_type_limit(&mut self, card_type: impl Into<String>, limit: usize) {
        self.per_type_limits.insert(card_type.into(), limit);
    }

    /// Validate `deck` against these constraints.
    ///
    /// Returns a list of human-readable violation messages.  An empty list
    /// means the deck is valid.
    pub fn validate(&self, deck: &Deck) -> Vec<String> {
        let mut errors = Vec::new();
        let n = deck.size();

        if n < self.min_cards {
            errors.push(format!("Deck too small: {} < {}", n, self.min_cards));
        }
        if self.max_cards > 0 && n > self.max_cards {
            errors.push(format!("Deck too large: {} > {}", n, self.max_cards));
        }

        let mut type_counts: HashMap<&str, usize> = HashMap::new();
        let mut cat_counts: HashMap<&str, usize> = HashMap::new();
        for card in &deck.cards {
            *type_counts.entry(card.card_type.as_str()).or_insert(0) += 1;
            if !card.category.is_empty() {
                *cat_counts.entry(card.category.as_str()).or_insert(0) += 1;
            }
        }

        for (ct, count) in &type_counts {
            let limit = self
                .per_type_limits
                .get(*ct)
                .copied()
                .unwrap_or(self.max_copies);
            if *count > limit {
                errors.push(format!(
                    "Too many copies of '{}': {} > {}",
                    ct, count, limit
                ));
            }
            if self.banned_types.iter().any(|b| b == *ct) {
                errors.push(format!("Banned card type: '{}'", ct));
            }
        }

        for (cat, &count) in &cat_counts {
            if self.banned_categories.iter().any(|b| b == *cat) {
                errors.push(format!("Banned category: '{}'", cat));
            }
            if let Some(&max) = self.max_per_category.get(*cat) {
                if max > 0 && count > max {
                    errors.push(format!(
                        "Too many '{}' cards: {} > {}",
                        cat, count, max
                    ));
                }
            }
        }

        for req in &self.required_types {
            if !type_counts.contains_key(req.as_str()) {
                errors.push(format!("Missing required type: '{}'", req));
            }
        }

        errors
    }

    /// Returns `true` if `deck` passes all validation rules.
    pub fn is_valid(&self, deck: &Deck) -> bool {
        self.validate(deck).is_empty()
    }
}

impl Default for DeckBuilder {
    fn default() -> Self {
        Self::new()
    }
}
