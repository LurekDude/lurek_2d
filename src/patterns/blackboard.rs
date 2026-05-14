
use std::collections::HashMap;
use std::fmt;
/// Typed value stored in a `Blackboard` entry.
#[derive(Debug, Clone, PartialEq)]
pub enum BlackboardValue {
    /// Boolean flag.
    Bool(bool),
    /// Floating-point number.
    Number(f64),
    /// UTF-8 text.
    Text(String),
    /// Explicit absent value.
    Nil,
}
/// Human-readable string formatting for `BlackboardValue`.
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
/// Shared key-value store with revision tracking used to communicate AI state between systems.
#[derive(Debug)]
pub struct Blackboard {
    /// Debug name for the board instance.
    pub name: String,
    /// Monotonically increasing counter incremented on every write.
    pub revision: u64,
    /// Typed key-value store.
    data: HashMap<String, BlackboardValue>,
    /// Per-key revision at the last write for change detection.
    key_revisions: HashMap<String, u64>,
}
/// Read and write methods for `Blackboard`.
impl Blackboard {
    /// Create an empty blackboard with `name`.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            revision: 0,
            data: HashMap::new(),
            key_revisions: HashMap::new(),
        }
    }
    /// Write a `bool` to `key`, advancing revision counters.
    pub fn set_bool(&mut self, key: &str, value: bool) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data
            .insert(key.to_string(), BlackboardValue::Bool(value));
    }
    /// Write a `f64` to `key`, advancing revision counters.
    pub fn set_number(&mut self, key: &str, value: f64) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data
            .insert(key.to_string(), BlackboardValue::Number(value));
    }
    /// Write a `String` to `key`, advancing revision counters.
    pub fn set_text(&mut self, key: &str, value: String) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data
            .insert(key.to_string(), BlackboardValue::Text(value));
    }
    /// Remove `key` and advance revision counters.
    pub fn clear(&mut self, key: &str) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data.remove(key);
    }
    /// Return the value for `key`, or `None` if not set.
    pub fn get(&self, key: &str) -> Option<&BlackboardValue> {
        self.data.get(key)
    }
    /// Return all keys as a slice of string references.
    pub fn keys(&self) -> Vec<&str> {
        self.data.keys().map(String::as_str).collect()
    }
    /// Return all `(key, value)` pairs as a vector.
    pub fn snapshot(&self) -> Vec<(&str, &BlackboardValue)> {
        self.data.iter().map(|(k, v)| (k.as_str(), v)).collect()
    }
    /// Return true when `key` is set.
    pub fn has(&self, key: &str) -> bool {
        self.data.contains_key(key)
    }
    /// Return the global revision at which `key` was last written, or `0` if never written.
    pub fn key_revision(&self, key: &str) -> u64 {
        self.key_revisions.get(key).copied().unwrap_or(0)
    }
    /// Remove all keys and advance the global revision.
    pub fn clear_all(&mut self) {
        self.revision += 1;
        self.data.clear();
        self.key_revisions.clear();
    }
    /// Return the number of entries currently set.
    pub fn len(&self) -> usize {
        self.data.len()
    }
    /// Return true when no keys are set.
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }
}
