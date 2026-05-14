
use std::collections::HashSet;
pub struct SimpleState {
    /// All declared state names.
    states: HashSet<String>,
    /// The currently active state, if any.
    current: Option<String>,
}
/// All methods for `SimpleState`.
impl SimpleState {
    /// Create an empty state set with no current state.
    pub fn new() -> Self {
        Self {
            states: HashSet::new(),
            current: None,
        }
    }
    /// Add `name` to the known set; return true when it was newly inserted.
    pub fn add(&mut self, name: &str) -> bool {
        self.states.insert(name.to_string())
    }
    /// Remove `name` and clear current if it matches; return true when it existed.
    pub fn remove(&mut self, name: &str) -> bool {
        let removed = self.states.remove(name);
        if self.current.as_deref() == Some(name) {
            self.current = None;
        }
        removed
    }
    /// Return true when `name` is in the known set.
    pub fn has(&self, name: &str) -> bool {
        self.states.contains(name)
    }
    /// Return the current state name, or `None`.
    pub fn current(&self) -> Option<&str> {
        self.current.as_deref()
    }
    /// Set current to `name`; return false when `name` is not in the known set.
    pub fn set_current(&mut self, name: &str) -> bool {
        if !self.states.contains(name) {
            return false;
        }
        self.current = Some(name.to_string());
        true
    }
    /// Clear the current state without removing it from the set.
    pub fn clear_current(&mut self) {
        self.current = None;
    }
    /// Return all known state names in sorted order.
    pub fn states(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.states.iter().map(String::as_str).collect();
        names.sort_unstable();
        names
    }
    /// Return the total number of known states.
    pub fn state_count(&self) -> usize {
        self.states.len()
    }
}
/// Delegates to `Self::new()`.
impl Default for SimpleState {
    fn default() -> Self {
        Self::new()
    }
}
