//! Trick-taking game support.
//!
//! A trick is a round in which each player plays one card; the winner is
//! determined by user-defined comparator logic (Lua callback or custom Rust
//! code).  This module provides the state container — it never evaluates
//! who "wins" without being explicitly told.

use crate::cardgame::card::Card;

/// A single card played during a trick.
#[derive(Debug, Clone)]
pub struct TrickSlot {
    /// The player who played this card.
    pub player_id: String,
    /// The card that was played.
    pub card: Card,
}

/// State for one trick (a single round of play in a trick-taking game).
///
/// The caller is responsible for determining the winner via `winner_index`
/// or by inspecting `slots` directly — the engine never interprets card
/// values, suits, or trump rules.
#[derive(Debug, Clone, Default)]
pub struct TrickState {
    /// The player who led (played first) this trick.
    pub lead_player: String,
    /// Name of the current trump suit/category, if any (user-defined).
    pub trump: Option<String>,
    /// Cards played in this trick, in play order.
    pub slots: Vec<TrickSlot>,
}

impl TrickState {
    /// Create a new empty trick.
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the lead player.
    pub fn set_lead(&mut self, player_id: impl Into<String>) {
        self.lead_player = player_id.into();
    }

    /// Set the trump suit/category (user-defined string).
    pub fn set_trump(&mut self, trump: impl Into<String>) {
        self.trump = Some(trump.into());
    }

    /// Clear the trump.
    pub fn clear_trump(&mut self) {
        self.trump = None;
    }

    /// Play a card for `player_id`.
    pub fn play(&mut self, player_id: impl Into<String>, card: Card) {
        self.slots.push(TrickSlot { player_id: player_id.into(), card });
    }

    /// Returns `true` if `expected` players have played this trick.
    pub fn is_complete(&self, expected: usize) -> bool {
        self.slots.len() >= expected
    }

    /// Return all played slots.
    pub fn slots(&self) -> &[TrickSlot] {
        &self.slots
    }

    /// Number of cards played so far.
    pub fn size(&self) -> usize {
        self.slots.len()
    }

    /// Returns `true` if no cards have been played yet.
    pub fn is_empty(&self) -> bool {
        self.slots.is_empty()
    }

    /// Clear all played cards, ready for the next trick.
    pub fn clear(&mut self) {
        self.slots.clear();
        self.lead_player.clear();
    }

    /// Return the player ID at `index` (0-based), if present.
    pub fn player_at(&self, index: usize) -> Option<&str> {
        self.slots.get(index).map(|s| s.player_id.as_str())
    }

    /// Convenience: find the slot played by `player_id`.
    pub fn slot_for(&self, player_id: &str) -> Option<&TrickSlot> {
        self.slots.iter().find(|s| s.player_id == player_id)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// TrickHistory — cumulative trick score tracking
// ─────────────────────────────────────────────────────────────────────────────

/// Tracks which player won each trick so the game can tally trick counts.
#[derive(Debug, Clone, Default)]
pub struct TrickHistory {
    /// (trick_number, winner_player_id) pairs, oldest first.
    tricks: Vec<(usize, String)>,
}

impl TrickHistory {
    /// Create an empty history.
    pub fn new() -> Self {
        Self::default()
    }

    /// Record that `player_id` won trick number `trick`.
    pub fn record(&mut self, trick: usize, player_id: impl Into<String>) {
        self.tricks.push((trick, player_id.into()));
    }

    /// Count how many tricks `player_id` has won.
    pub fn count_for(&self, player_id: &str) -> usize {
        self.tricks.iter().filter(|(_, w)| w == player_id).count()
    }

    /// Most recent trick winner, or `None` if no tricks recorded.
    pub fn last_winner(&self) -> Option<&str> {
        self.tricks.last().map(|(_, w)| w.as_str())
    }

    /// All (trick, winner) pairs.
    pub fn entries(&self) -> &[(usize, String)] {
        &self.tricks
    }

    /// Total tricks recorded.
    pub fn total(&self) -> usize {
        self.tricks.len()
    }

    /// Clear the history.
    pub fn clear(&mut self) {
        self.tricks.clear();
    }

    /// Return all (player_id, trick_count) pairs sorted descending.
    pub fn ranking(&self) -> Vec<(String, usize)> {
        let mut counts: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
        for (_, w) in &self.tricks {
            *counts.entry(w.clone()).or_insert(0) += 1;
        }
        let mut v: Vec<(String, usize)> = counts.into_iter().collect();
        v.sort_by(|a, b| b.1.cmp(&a.1));
        v
    }
}
