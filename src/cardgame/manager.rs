//! Stack manager — organises multiple named `Stack` instances as a unit.
//!
//! Useful for modelling a board where several stacks (draw pile, hand, discard,
//! play area, etc.) coexist and items need to move between them.

use crate::cardgame::card::Card;
use crate::cardgame::stack::Stack;
use std::collections::HashMap;

/// Manages a collection of named `Stack` instances.
///
/// All stack names and their semantics are user-defined.
///
/// # Fields
/// - `stacks` — `HashMap<String`.
#[derive(Debug, Clone, Default)]
pub struct StackManager {
    /// Named stacks.
    stacks: HashMap<String, Stack>,
}

impl StackManager {
    /// Create an empty stack manager. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    // ── Stack lifecycle ───────────────────────────────────────────────────────

    /// Add a pre-built `Stack` under `name`.  Overwrites any existing entry.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `stack` — `Stack`.
    pub fn add_stack(&mut self, name: impl Into<String>, stack: Stack) {
        self.stacks.insert(name.into(), stack);
    }

    /// Create a new empty unlimited stack with the given name.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    pub fn create_stack(&mut self, name: impl Into<String>) {
        let n = name.into();
        self.stacks.insert(n.clone(), Stack::new(n));
    }

    /// Create a new empty stack with a capacity limit.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `capacity` — `usize`.
    pub fn create_stack_capped(&mut self, name: impl Into<String>, capacity: usize) {
        let n = name.into();
        self.stacks
            .insert(n.clone(), Stack::with_capacity(n, capacity));
    }

    /// Remove and return the named stack. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<Stack>`.
    pub fn remove_stack(&mut self, name: &str) -> Option<Stack> {
        self.stacks.remove(name)
    }

    /// Returns `true` if a stack with this name exists.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_stack(&self, name: &str) -> bool {
        self.stacks.contains_key(name)
    }

    /// Return a reference to the named stack. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&Stack>`.
    pub fn get_stack(&self, name: &str) -> Option<&Stack> {
        self.stacks.get(name)
    }

    /// Return a mutable reference to the named stack.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut Stack>`.
    pub fn get_stack_mut(&mut self, name: &str) -> Option<&mut Stack> {
        self.stacks.get_mut(name)
    }

    /// List all stack names. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn stack_names(&self) -> Vec<String> {
        self.stacks.keys().cloned().collect()
    }

    /// Total number of items across all stacks.
    ///
    /// # Returns
    /// `usize`.
    pub fn total_items(&self) -> usize {
        self.stacks.values().map(|s| s.size()).sum()
    }

    // ── Item movement ─────────────────────────────────────────────────────────

    /// Move the item at `index` in `from` to the top of `to`.
    ///
    /// Returns `Err` if either stack is missing, index is out of range,
    /// or the destination is at capacity.
    ///
    /// # Parameters
    /// - `from` — `&str`.
    /// - `index` — `usize`.
    /// - `o` — `&str`.
    ///
    /// # Returns
    /// `Result<Card, String>`.
    pub fn move_item(&mut self, from: &str, index: usize, to: &str) -> Result<Card, String> {
        let item = self
            .stacks
            .get_mut(from)
            .ok_or_else(|| format!("stack '{}' not found", from))?
            .remove_at(index)
            .ok_or_else(|| format!("index {} out of range in '{}'", index, from))?;

        let dest = self
            .stacks
            .get_mut(to)
            .ok_or_else(|| format!("stack '{}' not found", to))?;

        if dest.is_full() {
            // Put item back so nothing is lost
            self.stacks
                .get_mut(from)
                .map(|s| s.insert_at(index, item.clone()));
            return Err(format!("stack '{}' is at capacity", to));
        }
        dest.push_top(item.clone());
        Ok(item)
    }

    /// Move the first item of `card_type` from `from` to the top of `to`.
    ///
    /// Returns `Err` if the type is not found or `to` is full.
    ///
    /// # Parameters
    /// - `from` — `&str`.
    /// - `card_type` — `&str`.
    /// - `o` — `&str`.
    ///
    /// # Returns
    /// `Result<Card, String>`.
    pub fn move_item_by_type(
        &mut self,
        from: &str,
        card_type: &str,
        to: &str,
    ) -> Result<Card, String> {
        let index = self
            .stacks
            .get(from)
            .and_then(|s| s.find_by_type(card_type))
            .ok_or_else(|| format!("type '{}' not found in '{}'", card_type, from))?;
        self.move_item(from, index, to)
    }

    /// Move the top item from `from` to the top of `to`.
    ///
    /// # Parameters
    /// - `from` — `&str`.
    /// - `o` — `&str`.
    ///
    /// # Returns
    /// `Result<Card, String>`.
    pub fn move_top(&mut self, from: &str, to: &str) -> Result<Card, String> {
        let index = self
            .stacks
            .get(from)
            .map(|s| s.size().saturating_sub(1))
            .filter(|_| self.stacks.get(from).is_some_and(|s| !s.is_empty()))
            .ok_or_else(|| format!("stack '{}' is empty or not found", from))?;
        self.move_item(from, index, to)
    }
}
