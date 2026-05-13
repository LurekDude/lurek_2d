//! hierarchical blackboard store for typed shared AI data.
use std::collections::HashMap;

use crate::log_msg;
use crate::runtime::log_messages::{BB01, BB02, BB03};

/// A typed value stored in a blackboard slot.
#[derive(Debug, Clone)]
pub enum BlackboardValue {
    /// A 64-bit floating-point number. Used for health, distances, scores, etc.
    Number(f64),
    /// A boolean flag. Used for state flags like "is_alert", "has_weapon".
    Bool(bool),
    /// A string value. Used for state names, target identifiers, etc.
    Text(String),
}

/// A hierarchical key-value store for sharing named data between AI subsystems.
#[derive(Clone)]
pub struct Blackboard {
    /// Local key-value entries. Keys are case-sensitive strings.
    pub(crate) entries: HashMap<String, BlackboardValue>,
    /// Optional parent blackboard for hierarchical read-through.
    pub(crate) parent: Option<Box<Blackboard>>,
}

impl Blackboard {
    /// Create an empty Blackboard with no parent.
    pub fn new() -> Self {
        log_msg!(debug, BB01);
        Self {
            entries: HashMap::new(),
            parent: None,
        }
    }

    /// Set a number value in the local store.
    pub fn set_number(&mut self, key: &str, value: f64) {
        self.entries
            .insert(key.to_string(), BlackboardValue::Number(value));
    }

    /// Gets a number value, walking the parent chain. Returns `default` if not found.
    pub fn get_number(&self, key: &str, default: f64) -> f64 {
        if let Some(BlackboardValue::Number(v)) = self.entries.get(key) {
            return *v;
        }
        if let Some(ref parent) = self.parent {
            return parent.get_number(key, default);
        }
        default
    }

    /// Set a boolean value in the local store.
    pub fn set_bool(&mut self, key: &str, value: bool) {
        self.entries
            .insert(key.to_string(), BlackboardValue::Bool(value));
    }

    /// Gets a boolean value, walking the parent chain. Returns `default` if not found.
    pub fn get_bool(&self, key: &str, default: bool) -> bool {
        if let Some(BlackboardValue::Bool(v)) = self.entries.get(key) {
            return *v;
        }
        if let Some(ref parent) = self.parent {
            return parent.get_bool(key, default);
        }
        default
    }

    /// Set a string value in the local store.
    pub fn set_string(&mut self, key: &str, value: &str) {
        self.entries
            .insert(key.to_string(), BlackboardValue::Text(value.to_string()));
    }

    /// Gets a string value, walking the parent chain. Returns `default` if not found.
    pub fn get_string(&self, key: &str, default: &str) -> String {
        if let Some(BlackboardValue::Text(v)) = self.entries.get(key) {
            return v.clone();
        }
        if let Some(ref parent) = self.parent {
            return parent.get_string(key, default);
        }
        default.to_string()
    }

    /// Check if a key exists locally or in any ancestor.
    pub fn has(&self, key: &str) -> bool {
        if self.entries.contains_key(key) {
            return true;
        }
        if let Some(ref parent) = self.parent {
            return parent.has(key);
        }
        false
    }

    /// Remove a key from the local store only.
    pub fn remove(&mut self, key: &str) {
        log_msg!(trace, BB02, "{}", key);
        self.entries.remove(key);
    }

    /// Clears all local entries. Parent is unaffected.
    pub fn clear(&mut self) {
        let count = self.entries.len();
        self.entries.clear();
        log_msg!(debug, BB03, "{}", count);
    }

    /// Return all local key names.
    pub fn keys(&self) -> Vec<String> {
        self.entries.keys().cloned().collect()
    }

    /// Return the number of local entries. Runs in O(1) time.
    pub fn size(&self) -> usize {
        self.entries.len()
    }

    /// Set the parent Blackboard for hierarchical lookup.
    pub fn set_parent(&mut self, parent: Blackboard) {
        self.parent = Some(Box::new(parent));
    }

    /// Return a reference to the parent Blackboard, if any.
    pub fn parent(&self) -> Option<&Blackboard> {
        self.parent.as_deref()
    }
}

impl Default for Blackboard {
    fn default() -> Self {
        Self::new()
    }
}
