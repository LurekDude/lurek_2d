//! Simple string-keyed finite state machine.
//!
//! Tracks a set of named states and an optional current state.  Transitions
//! and callbacks are managed by the Lua API layer; this type holds only the
//! pure-Rust state bookkeeping.

use std::collections::HashSet;

/// Finite state machine that tracks a set of named states and the current one.
///
/// Transitions and callbacks are managed by the Lua API layer; this struct
/// holds only the pure-Rust state bookkeeping — registered state names and
/// the currently active state key.
///
/// # Fields
/// - `states` — `HashSet<String>` — All registered state names.
/// - `current` — `Option<String>` — The active state name, or `None` if no state is set.
pub struct SimpleState {
    states: HashSet<String>,
    current: Option<String>,
}

impl SimpleState {
    /// Creates a new `SimpleState` with no states defined.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            states: HashSet::new(),
            current: None,
        }
    }

    /// Registers a state by name.  Returns `false` if `name` already exists.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn add(&mut self, name: &str) -> bool {
        self.states.insert(name.to_string())
    }

    /// Removes a state by name.  Also clears the current state if it matches.
    ///
    /// Returns `false` when `name` was not registered.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove(&mut self, name: &str) -> bool {
        let removed = self.states.remove(name);
        if self.current.as_deref() == Some(name) {
            self.current = None;
        }
        removed
    }

    /// Returns `true` when `name` is a registered state.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has(&self, name: &str) -> bool {
        self.states.contains(name)
    }

    /// Returns the current state name, or `None` if no state is active.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn current(&self) -> Option<&str> {
        self.current.as_deref()
    }

    /// Transitions to `name`.  Returns `false` when `name` is not registered.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn set_current(&mut self, name: &str) -> bool {
        if !self.states.contains(name) {
            return false;
        }
        self.current = Some(name.to_string());
        true
    }

    /// Clears the current state, leaving the machine in an inactive state.
    pub fn clear_current(&mut self) {
        self.current = None;
    }

    /// Returns all registered state names sorted alphabetically.
    ///
    /// # Returns
    /// `Vec<&str>`.
    pub fn states(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.states.iter().map(String::as_str).collect();
        names.sort_unstable();
        names
    }

    /// Returns the number of registered states.
    ///
    /// # Returns
    /// `usize`.
    pub fn state_count(&self) -> usize {
        self.states.len()
    }
}

impl Default for SimpleState {
    fn default() -> Self {
        Self::new()
    }
}
