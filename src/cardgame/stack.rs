//! LIFO resolution stack for card game effects (MTG-style priority system).

use std::collections::HashMap;
use crate::cardgame::card::Card;

/// A single pending action/effect on the resolution stack.
#[derive(Debug, Clone)]
pub struct StackEntry {
    /// Effect kind identifier — user-defined (e.g. `"spell"`, `"ability"`, `"counter"`).
    pub kind: String,
    /// Associated card, if any.
    pub card: Option<Card>,
    /// Arbitrary data fields attached to this effect.
    pub data: HashMap<String, String>,
}

impl StackEntry {
    /// Create a minimal stack entry with just a kind.
    pub fn new(kind: impl Into<String>) -> Self {
        Self { kind: kind.into(), card: None, data: HashMap::new() }
    }

    /// Attach a card to this entry.
    pub fn with_card(mut self, card: Card) -> Self {
        self.card = Some(card);
        self
    }

    /// Attach a data field.
    pub fn with_data(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.data.insert(key.into(), value.into());
        self
    }
}

/// LIFO stack for card-game effect resolution.
///
/// The last pushed entry is resolved first (standard MTG-style stack).
#[derive(Debug, Clone, Default)]
pub struct StackManager {
    /// Pending entries; `stack.last()` = top.
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

    /// Pop and return the top entry (resolve it), or `None` if empty.
    pub fn resolve(&mut self) -> Option<StackEntry> {
        self.stack.pop()
    }

    /// Peek at the top entry without removing it.
    pub fn peek(&self) -> Option<&StackEntry> {
        self.stack.last()
    }

    /// Returns `true` if there are no pending entries.
    pub fn is_empty(&self) -> bool {
        self.stack.is_empty()
    }

    /// Number of pending entries.
    pub fn size(&self) -> usize {
        self.stack.len()
    }

    /// Discard all entries.
    pub fn clear(&mut self) {
        self.stack.clear();
    }

    /// Return the index of the first entry matching `kind` (from top, 0-based).
    pub fn find_by_kind(&self, kind: &str) -> Option<usize> {
        self.stack.iter().position(|e| e.kind == kind)
    }

    /// Remove and discard all entries matching `kind`.
    pub fn cancel_by_kind(&mut self, kind: &str) {
        self.stack.retain(|e| e.kind != kind);
    }

    /// Return all entries as a slice (bottom to top order).
    pub fn entries(&self) -> &[StackEntry] {
        &self.stack
    }
}
