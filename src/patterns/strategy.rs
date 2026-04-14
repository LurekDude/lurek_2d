//! Strategy pattern — named, swappable behaviours.
//!
//! The [`Strategy`] struct manages a registry of named strategies and tracks which one
//! is currently active.  The actual Lua function callbacks are stored in the Lua API
//! layer; this module only tracks names and the active selection.

use std::collections::HashMap;

// ── Strategy ─────────────────────────────────────────────────────────────────

/// Registry of named, interchangeable behaviours with a single active selection.
#[derive(Debug, Default, Clone)]
pub struct Strategy {
    /// Strategy name → monotonic handler ID (used as registry key in Lua API).
    strategies: HashMap<String, u64>,
    /// Name of the currently selected strategy, or `None`.
    current: Option<String>,
    next_id: u64,
}

impl Strategy {
    /// Creates a new, empty [`Strategy`] registry.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Registers a strategy under `name` and returns its handler ID.
    ///
    /// Re-registering an existing name overwrites the previous entry.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `u64` — handler ID.
    pub fn register(&mut self, name: &str) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        self.strategies.insert(name.to_string(), id);
        id
    }

    /// Sets the active strategy by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool` — `false` if `name` is not registered.
    pub fn set_current(&mut self, name: &str) -> bool {
        if self.strategies.contains_key(name) {
            self.current = Some(name.to_string());
            true
        } else {
            false
        }
    }

    /// Returns the name of the currently active strategy, or `None`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_current(&self) -> Option<&str> {
        self.current.as_deref()
    }

    /// Returns the handler ID of the currently active strategy, or `None`.
    ///
    /// # Returns
    /// `Option<u64>`.
    pub fn get_current_id(&self) -> Option<u64> {
        self.current
            .as_ref()
            .and_then(|n| self.strategies.get(n))
            .copied()
    }

    /// Returns `true` if `name` is registered.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has(&self, name: &str) -> bool {
        self.strategies.contains_key(name)
    }

    /// Removes a strategy by name.  Clears `current` if it matches.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool` — `true` if it was found and removed.
    pub fn remove(&mut self, name: &str) -> bool {
        if self.strategies.remove(name).is_some() {
            if self.current.as_deref() == Some(name) {
                self.current = None;
            }
            true
        } else {
            false
        }
    }

    /// Returns all registered strategy names.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn names(&self) -> Vec<String> {
        self.strategies.keys().cloned().collect()
    }

    /// Removes all strategies and clears the active selection.
    pub fn clear(&mut self) {
        self.strategies.clear();
        self.current = None;
        self.next_id = 0;
    }
}
