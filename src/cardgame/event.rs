//! Generic game-event log.
//!
//! Events are simple tagged data records — the engine never interprets their
//! content.  The game designer decides what tags and data fields to use.

use std::collections::HashMap;

/// A single recorded game event.
///
/// All fields are user-defined strings; the engine never parses `tag` or
/// `data`.  Use any scheme you like (e.g. `tag = "card_played"`,
/// `data["player"] = "alice"`).
#[derive(Debug, Clone)]
pub struct GameEvent {
    /// User-defined event type tag (e.g. `"card_played"`, `"turn_start"`, `"score"`).
    pub tag: String,
    /// Absolute turn number when this event occurred.
    pub turn: usize,
    /// Round number when this event occurred.
    pub round: usize,
    /// Primary player associated with this event (may be empty).
    pub player_id: String,
    /// Arbitrary key-value payload.
    pub data: HashMap<String, String>,
}

impl GameEvent {
    /// Create a minimal event with just a tag.
    pub fn new(tag: impl Into<String>) -> Self {
        Self {
            tag: tag.into(),
            turn: 0,
            round: 0,
            player_id: String::new(),
            data: HashMap::new(),
        }
    }

    /// Set the turn number.
    pub fn with_turn(mut self, turn: usize) -> Self {
        self.turn = turn;
        self
    }

    /// Set the round number.
    pub fn with_round(mut self, round: usize) -> Self {
        self.round = round;
        self
    }

    /// Set the primary player.
    pub fn with_player(mut self, player_id: impl Into<String>) -> Self {
        self.player_id = player_id.into();
        self
    }

    /// Attach a data field.
    pub fn with_data(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.data.insert(key.into(), value.into());
        self
    }
}

/// An append-only log of `GameEvent` records with optional size cap.
#[derive(Debug, Clone)]
pub struct EventLog {
    events: Vec<GameEvent>,
    /// Maximum number of events to retain (`0` = unlimited).
    pub max_size: usize,
}

impl EventLog {
    /// Create an unlimited event log.
    pub fn new() -> Self {
        Self { events: Vec::new(), max_size: 0 }
    }

    /// Create an event log capped at `max_size` entries.
    pub fn with_capacity(max_size: usize) -> Self {
        Self { events: Vec::new(), max_size }
    }

    /// Append an event, dropping the oldest entry if the cap is exceeded.
    pub fn log(&mut self, event: GameEvent) {
        if self.max_size > 0 && self.events.len() >= self.max_size {
            self.events.remove(0);
        }
        self.events.push(event);
    }

    /// Return all events (oldest first).
    pub fn events(&self) -> &[GameEvent] {
        &self.events
    }

    /// Number of recorded events.
    pub fn len(&self) -> usize {
        self.events.len()
    }

    /// Returns `true` if the log is empty.
    pub fn is_empty(&self) -> bool {
        self.events.is_empty()
    }

    /// Clear all events.
    pub fn clear(&mut self) {
        self.events.clear();
    }

    /// Return events matching `tag`.
    pub fn filter_by_tag(&self, tag: &str) -> Vec<&GameEvent> {
        self.events.iter().filter(|e| e.tag == tag).collect()
    }

    /// Return events for a specific player.
    pub fn filter_by_player(&self, player_id: &str) -> Vec<&GameEvent> {
        self.events.iter().filter(|e| e.player_id == player_id).collect()
    }

    /// Return events from a specific round.
    pub fn filter_by_round(&self, round: usize) -> Vec<&GameEvent> {
        self.events.iter().filter(|e| e.round == round).collect()
    }

    /// Most recent event, or `None` if empty.
    pub fn last(&self) -> Option<&GameEvent> {
        self.events.last()
    }
}

impl Default for EventLog {
    fn default() -> Self {
        Self::new()
    }
}
