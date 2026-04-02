//! Slot — a bounded named position that holds a small set of items.
//!
//! A slot is like a named cell on a board: it has an optional capacity limit
//! and enforces it on push.  Useful for equipment slots, board positions,
//! hand slots, or any place where "there can only be N items here" matters.

use crate::item::item::Item;

/// A bounded named position holding zero or more items.
///
/// Semantics (what "this slot" means) are entirely user-defined.
#[derive(Debug, Clone)]
pub struct Slot {
    /// Slot name — user-defined (e.g. `"weapon_slot"`, `"board[2][3]"`, `"hand[0]"`).
    pub name: String,
    /// Optional capacity (`None` = unlimited).
    capacity: Option<usize>,
    /// Items held in this slot.
    items: Vec<Item>,
}

impl Slot {
    /// Create an empty slot with no capacity limit.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), capacity: None, items: Vec::new() }
    }

    /// Create an empty slot with a fixed capacity.
    pub fn with_capacity(name: impl Into<String>, capacity: usize) -> Self {
        Self { name: name.into(), capacity: Some(capacity), items: Vec::new() }
    }

    /// Returns `true` if the slot is empty.
    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }

    /// Returns `true` if the slot is at capacity.
    pub fn is_full(&self) -> bool {
        self.capacity.is_some_and(|cap| self.items.len() >= cap)
    }

    /// Number of items currently in the slot.
    pub fn size(&self) -> usize {
        self.items.len()
    }

    /// The capacity, or `None` if unlimited.
    pub fn capacity(&self) -> Option<usize> {
        self.capacity
    }

    /// Set or remove the capacity limit.
    pub fn set_capacity(&mut self, cap: Option<usize>) {
        self.capacity = cap;
    }

    /// Add an item to the slot.  Returns `Err` if at capacity.
    pub fn push(&mut self, item: Item) -> Result<(), String> {
        if self.is_full() {
            return Err(format!("slot '{}' is full (capacity = {})", self.name, self.capacity.unwrap()));
        }
        self.items.push(item);
        Ok(())
    }

    /// Remove and return the last item, or `None` if empty.
    pub fn pop(&mut self) -> Option<Item> {
        self.items.pop()
    }

    /// Remove and return the item at 0-based `index`, or `None` if out of range.
    pub fn remove_at(&mut self, index: usize) -> Option<Item> {
        if index < self.items.len() { Some(self.items.remove(index)) } else { None }
    }

    /// Peek at the last item without removing it.
    pub fn peek(&self) -> Option<&Item> {
        self.items.last()
    }

    /// Peek at the item at `index` without removing it.
    pub fn peek_at(&self, index: usize) -> Option<&Item> {
        self.items.get(index)
    }

    /// Remove all items and return them.
    pub fn clear(&mut self) -> Vec<Item> {
        std::mem::take(&mut self.items)
    }

    /// Read-only view of all items.
    pub fn items(&self) -> &[Item] {
        &self.items
    }

    /// Returns `true` if any item carries the given tag.
    pub fn has_item_with_tag(&self, tag: &str) -> bool {
        self.items.iter().any(|i| i.has_tag(tag))
    }

    /// Returns `true` if any item is of the given type.
    pub fn has_item_of_type(&self, item_type: &str) -> bool {
        self.items.iter().any(|i| i.item_type == item_type)
    }
}
