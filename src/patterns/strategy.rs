//! Named-strategy registry: register strategies by name, track which is current.
//! Strategies are identified by opaque `u64` ids; callers dispatch based on the id.

use std::collections::HashMap;

/// Registry of named strategies with a single active selection.
#[derive(Debug, Default, Clone)]
pub struct Strategy {
    /// Registered strategy name → id map.
    strategies: HashMap<String, u64>,
    /// Currently selected strategy name.
    current: Option<String>,
    /// Next id to assign.
    next_id: u64,
}
/// All methods for `Strategy`.
impl Strategy {
    /// Create an empty strategy registry.
    pub fn new() -> Self {
        Self::default()
    }
    /// Register `name` and return its assigned id.
    pub fn register(&mut self, name: &str) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        self.strategies.insert(name.to_string(), id);
        id
    }
    /// Set `name` as current; return false when it is not registered.
    pub fn set_current(&mut self, name: &str) -> bool {
        if self.strategies.contains_key(name) {
            self.current = Some(name.to_string());
            true
        } else {
            false
        }
    }
    /// Return the name of the current strategy, or `None`.
    pub fn get_current(&self) -> Option<&str> {
        self.current.as_deref()
    }
    /// Return the id of the current strategy, or `None`.
    pub fn get_current_id(&self) -> Option<u64> {
        self.current
            .as_ref()
            .and_then(|n| self.strategies.get(n))
            .copied()
    }
    /// Return true when `name` is registered.
    pub fn has(&self, name: &str) -> bool {
        self.strategies.contains_key(name)
    }
    /// Remove `name` and clear current if it matches; return true when it existed.
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
    /// Return all registered strategy names.
    pub fn names(&self) -> Vec<String> {
        self.strategies.keys().cloned().collect()
    }
    /// Remove all strategies, clear current, and reset ids.
    pub fn clear(&mut self) {
        self.strategies.clear();
        self.current = None;
        self.next_id = 0;
    }
}
