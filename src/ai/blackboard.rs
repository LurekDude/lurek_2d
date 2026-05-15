//! - Lightweight hierarchical blackboard storing per-agent facts as numbers, booleans, and strings.
//! - Local entry map with optional parent chain and read/write resolution through fallback hierarchy.
//! - Key removal, board clearing, key listing, size reporting, and parent attachment operations.
//! - Parent-chain walk for reads giving child boards transparent access to shared data.
//! - Structured runtime logging for creation, removal, and clear events.

use crate::log_msg;
use crate::runtime::log_messages::{BB01, BB02, BB03};
use std::collections::HashMap;
/// Value stored inside a blackboard entry.
#[derive(Debug, Clone)]
pub enum BlackboardValue {
    /// 64-bit floating-point numeric value.
    Number(f64),
    /// Boolean flag value.
    Bool(bool),
    /// UTF-8 string value.
    Text(String),
}
/// Blackboard storage for one agent with optional parent fallback.
#[derive(Clone)]
pub struct Blackboard {
    /// Local key/value entries owned by this board.
    pub(crate) entries: HashMap<String, BlackboardValue>,
    /// Optional parent board consulted when a key is absent locally.
    pub(crate) parent: Option<Box<Blackboard>>,
}
impl Blackboard {
    /// Create an empty blackboard with no parent.
    pub fn new() -> Self {
        log_msg!(debug, BB01);
        Self {
            entries: HashMap::new(),
            parent: None,
        }
    }
    /// Write a `Number` value under `key`, overwriting any existing entry.
    pub fn set_number(&mut self, key: &str, value: f64) {
        self.entries
            .insert(key.to_string(), BlackboardValue::Number(value));
    }
    /// Read a `Number` by key; walks the parent chain, returns `default` if absent.
    pub fn get_number(&self, key: &str, default: f64) -> f64 {
        if let Some(BlackboardValue::Number(v)) = self.entries.get(key) {
            return *v;
        }
        if let Some(ref parent) = self.parent {
            return parent.get_number(key, default);
        }
        default
    }
    /// Write a `Bool` value under `key`, overwriting any existing entry.
    pub fn set_bool(&mut self, key: &str, value: bool) {
        self.entries
            .insert(key.to_string(), BlackboardValue::Bool(value));
    }
    /// Read a `Bool` by key; walks the parent chain, returns `default` if absent.
    pub fn get_bool(&self, key: &str, default: bool) -> bool {
        if let Some(BlackboardValue::Bool(v)) = self.entries.get(key) {
            return *v;
        }
        if let Some(ref parent) = self.parent {
            return parent.get_bool(key, default);
        }
        default
    }
    /// Write a `Text` value under `key`, overwriting any existing entry.
    pub fn set_string(&mut self, key: &str, value: &str) {
        self.entries
            .insert(key.to_string(), BlackboardValue::Text(value.to_string()));
    }
    /// Read a `Text` by key; walks the parent chain, returns `default` if absent.
    pub fn get_string(&self, key: &str, default: &str) -> String {
        if let Some(BlackboardValue::Text(v)) = self.entries.get(key) {
            return v.clone();
        }
        if let Some(ref parent) = self.parent {
            return parent.get_string(key, default);
        }
        default.to_string()
    }
    /// Return `true` if `key` exists in this board or any ancestor.
    pub fn has(&self, key: &str) -> bool {
        if self.entries.contains_key(key) {
            return true;
        }
        if let Some(ref parent) = self.parent {
            return parent.has(key);
        }
        false
    }
    /// Remove `key` from the local entries only; parent is not affected.
    pub fn remove(&mut self, key: &str) {
        log_msg!(trace, BB02, "{}", key);
        self.entries.remove(key);
    }
    /// Remove all local entries; parent is not affected.
    pub fn clear(&mut self) {
        let count = self.entries.len();
        self.entries.clear();
        log_msg!(debug, BB03, "{}", count);
    }
    /// Return all local key names as a new `Vec`; does not include parent keys.
    pub fn keys(&self) -> Vec<String> {
        self.entries.keys().cloned().collect()
    }
    /// Return the number of entries in the local board, excluding the parent.
    pub fn size(&self) -> usize {
        self.entries.len()
    }
    /// Attach a parent board; looked up when a local key is missing.
    pub fn set_parent(&mut self, parent: Blackboard) {
        self.parent = Some(Box::new(parent));
    }
    /// Return a reference to the parent board, or `None` if none is set.
    pub fn parent(&self) -> Option<&Blackboard> {
        self.parent.as_deref()
    }
}
/// `Default` delegates to `Blackboard::new`.
impl Default for Blackboard {
    /// `Default` delegates to `Blackboard::new`.
    fn default() -> Self {
        Self::new()
    }
}
