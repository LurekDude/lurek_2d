//! Shared key-value blackboard for AI and game systems coordination.
//!
//! [`Blackboard`] is a named data store where multiple game systems (enemy AI,
//! goal selectors, dialogue conditions, etc.) can read and write shared facts
//! without direct coupling. Watchers are notified by the Lua API layer.

use std::collections::HashMap;
use std::fmt;

// ── BlackboardValue ───────────────────────────────────────────────────────

/// A value that can be stored on a [`Blackboard`].
///
/// # Variants
/// - `Bool` — Boolean fact.
/// - `Number` — Floating-point fact.
/// - `Text` — String fact.
/// - `Nil` — Absent / cleared fact.
#[derive(Debug, Clone, PartialEq)]
pub enum BlackboardValue {
    /// Boolean fact.
    Bool(bool),
    /// Floating-point fact.
    Number(f64),
    /// String fact.
    Text(String),
    /// Absent fact (explicit nil).
    Nil,
}

impl fmt::Display for BlackboardValue {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            BlackboardValue::Bool(b) => write!(f, "{b}"),
            BlackboardValue::Number(n) => write!(f, "{n}"),
            BlackboardValue::Text(s) => write!(f, "{s}"),
            BlackboardValue::Nil => write!(f, "nil"),
        }
    }
}

// ── Blackboard ────────────────────────────────────────────────────────────

/// Shared key-value data store for coordinating AI and game subsystems.
///
/// Stores typed facts (booleans, numbers, strings, nil) under string keys and
/// records a change-sequence counter so watchers can poll for updates without
/// storing the full history. Watcher callbacks are handled in the Lua API layer.
///
/// # Fields
/// - `name` — `String`.
/// - `revision` — `u64`.
#[derive(Debug)]
pub struct Blackboard {
    /// Display name for logging and debugging.
    pub name: String,
    /// Monotonically increasing counter incremented on every write.
    pub revision: u64,
    data: HashMap<String, BlackboardValue>,
    /// Per-key revision at which each fact last changed.
    key_revisions: HashMap<String, u64>,
}

impl Blackboard {
    /// Creates an empty blackboard with the given name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            revision: 0,
            data: HashMap::new(),
            key_revisions: HashMap::new(),
        }
    }

    /// Sets a boolean fact.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `value` — `bool`.
    pub fn set_bool(&mut self, key: &str, value: bool) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data.insert(key.to_string(), BlackboardValue::Bool(value));
    }

    /// Sets a numeric fact.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `value` — `f64`.
    pub fn set_number(&mut self, key: &str, value: f64) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data.insert(key.to_string(), BlackboardValue::Number(value));
    }

    /// Sets a string fact.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `value` — `String`.
    pub fn set_text(&mut self, key: &str, value: String) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data.insert(key.to_string(), BlackboardValue::Text(value));
    }

    /// Clears (sets to nil) a fact.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    pub fn clear(&mut self, key: &str) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data.remove(key);
    }

    /// Returns the current value for a key, or `None` if absent.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `Option<&BlackboardValue>`.
    pub fn get(&self, key: &str) -> Option<&BlackboardValue> {
        self.data.get(key)
    }

    /// Returns all keys currently set on the blackboard.
    ///
    /// # Returns
    /// `Vec<&str>`.
    pub fn keys(&self) -> Vec<&str> {
        self.data.keys().map(String::as_str).collect()
    }

    /// Returns all key-value pairs as a snapshot.
    ///
    /// # Returns
    /// `Vec<(&str, &BlackboardValue)>`.
    pub fn snapshot(&self) -> Vec<(&str, &BlackboardValue)> {
        self.data.iter().map(|(k, v)| (k.as_str(), v)).collect()
    }

    /// Returns `true` when the key holds any non-nil value.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has(&self, key: &str) -> bool {
        self.data.contains_key(key)
    }

    /// Returns the board revision when `key` was last written, or `0` if never.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `u64`.
    pub fn key_revision(&self, key: &str) -> u64 {
        self.key_revisions.get(key).copied().unwrap_or(0)
    }

    /// Clears all facts and resets the blackboard.
    pub fn clear_all(&mut self) {
        self.revision += 1;
        self.data.clear();
        self.key_revisions.clear();
    }

    /// Returns the number of facts currently stored.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.data.len()
    }

    /// Returns `true` when no facts are stored.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }
}
