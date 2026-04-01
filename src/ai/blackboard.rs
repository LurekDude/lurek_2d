//! Typed key-value store with optional parent chain for hierarchical lookup.

use std::collections::HashMap;

/// Typed value stored in a Blackboard slot.
///
/// # Variants
/// - `Number` — Number variant.
/// - `Bool` — Bool variant.
/// - `Text` — Text variant.
#[derive(Debug, Clone)]
pub enum BlackboardValue {
    /// Numeric value (f64).
    Number(f64),
    /// Boolean value.
    Bool(bool),
    /// String value.
    Text(String),
}

/// Key-value store with optional parent chain for hierarchical lookup.
///
/// # Fields
/// - `entries` — `HashMap<String, BlackboardValue>`.
/// - `parent` — `Option<Box<Blackboard>>`.
///
/// Used by agents, squads, and worlds to share named data.
/// `get*` walks the parent chain; `set*` writes locally only.
#[derive(Clone)]
pub struct Blackboard {
    /// Local key-value entries.
    pub(crate) entries: HashMap<String, BlackboardValue>,
    /// Optional parent for hierarchical lookup. Never propagates writes.
    pub(crate) parent: Option<Box<Blackboard>>,
}

impl Blackboard {
    /// Creates an empty Blackboard with no parent.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            entries: HashMap::new(),
            parent: None,
        }
    }

    /// Sets a number value in the local store.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `value` — `f64`.
    pub fn set_number(&mut self, key: &str, value: f64) {
        self.entries
            .insert(key.to_string(), BlackboardValue::Number(value));
    }

    /// Gets a number value, walking the parent chain. Returns `default` if not found.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `default` — `f64`.
    ///
    /// # Returns
    /// `f64`.
    pub fn get_number(&self, key: &str, default: f64) -> f64 {
        if let Some(BlackboardValue::Number(v)) = self.entries.get(key) {
            return *v;
        }
        if let Some(ref parent) = self.parent {
            return parent.get_number(key, default);
        }
        default
    }

    /// Sets a boolean value in the local store.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `value` — `bool`.
    pub fn set_bool(&mut self, key: &str, value: bool) {
        self.entries
            .insert(key.to_string(), BlackboardValue::Bool(value));
    }

    /// Gets a boolean value, walking the parent chain. Returns `default` if not found.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `default` — `bool`.
    ///
    /// # Returns
    /// `bool`.
    pub fn get_bool(&self, key: &str, default: bool) -> bool {
        if let Some(BlackboardValue::Bool(v)) = self.entries.get(key) {
            return *v;
        }
        if let Some(ref parent) = self.parent {
            return parent.get_bool(key, default);
        }
        default
    }

    /// Sets a string value in the local store.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `value` — `&str`.
    pub fn set_string(&mut self, key: &str, value: &str) {
        self.entries
            .insert(key.to_string(), BlackboardValue::Text(value.to_string()));
    }

    /// Gets a string value, walking the parent chain. Returns `default` if not found.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `default` — `&str`.
    ///
    /// # Returns
    /// `String`.
    pub fn get_string(&self, key: &str, default: &str) -> String {
        if let Some(BlackboardValue::Text(v)) = self.entries.get(key) {
            return v.clone();
        }
        if let Some(ref parent) = self.parent {
            return parent.get_string(key, default);
        }
        default.to_string()
    }

    /// Checks if a key exists locally or in any ancestor.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has(&self, key: &str) -> bool {
        if self.entries.contains_key(key) {
            return true;
        }
        if let Some(ref parent) = self.parent {
            return parent.has(key);
        }
        false
    }

    /// Removes a key from the local store only.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    pub fn remove(&mut self, key: &str) {
        self.entries.remove(key);
    }

    /// Clears all local entries. Parent is unaffected.
    pub fn clear(&mut self) {
        self.entries.clear();
    }

    /// Returns all local key names.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn keys(&self) -> Vec<String> {
        self.entries.keys().cloned().collect()
    }

    /// Returns the number of local entries.
    ///
    /// # Returns
    /// `usize`.
    pub fn size(&self) -> usize {
        self.entries.len()
    }

    /// Sets the parent Blackboard for hierarchical lookup.
    ///
    /// # Parameters
    /// - `parent` — `Blackboard`.
    pub fn set_parent(&mut self, parent: Blackboard) {
        self.parent = Some(Box::new(parent));
    }

    /// Returns a reference to the parent Blackboard, if any.
    ///
    /// # Returns
    /// `Option<&Blackboard>`.
    pub fn parent(&self) -> Option<&Blackboard> {
        self.parent.as_deref()
    }
}

impl Default for Blackboard {
    fn default() -> Self {
        Self::new()
    }
}
