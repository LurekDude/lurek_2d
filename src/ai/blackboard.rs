//! Typed key-value store with optional parent chain for hierarchical lookup.
//!
//! Blackboards are the primary mechanism for sharing named data between AI
//! subsystems in Lurek2D. Each [`Agent`](crate::ai::agent::Agent) has a local
//! blackboard; each [`Squad`](crate::ai::squad::Squad) has a squad-level
//! blackboard; and the [`AIWorld`](crate::ai::world::AIWorld) has a global one.
//!
//! ## Hierarchical Lookup
//!
//! Blackboards can be chained: an agent's blackboard has the world's global
//! blackboard as its parent. When reading a key, the lookup walks the parent
//! chain until a match is found or the chain ends. Writes always target the
//! local store — they never propagate to parents.
//!
//! ## Supported Value Types
//!
//! Three value types are supported via [`BlackboardValue`]:
//! - `Number(f64)` — numeric values
//! - `Bool(bool)` — boolean flags
//! - `Text(String)` — string data
//!
//! Each type has dedicated get/set methods that enforce type safety at the
//! Rust level. The Lua API layer provides a unified `bb:get(key)` interface.

use std::collections::HashMap;

use crate::engine::log_messages::{BB01, BB02, BB03};
use crate::log_msg;

/// A typed value stored in a blackboard slot.
///
/// Three types are supported, matching the primitive types commonly passed
/// between Lua callbacks and the AI subsystem. Complex data structures should
/// be decomposed into multiple blackboard entries rather than stored as a
/// single serialized blob.
///
/// # Variants
/// - `Number` — Number variant.
/// - `Bool` — Bool variant.
/// - `Text` — Text variant.
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
///
/// Used by agents, squads, and the AI world to communicate without direct
/// coupling. For example, an FSM state callback can write `"target_x"` to the
/// agent's blackboard, and a steering behavior can read it to compute forces.
///
/// ## Lookup Rules
///
/// - `get_*` methods first check local entries, then walk the parent chain.
/// - `set_*` methods always write to the local store only.
/// - `has()` checks both local and parent stores.
/// - `remove()` and `clear()` affect only the local store.
///
/// ## Cloning
///
/// Blackboards implement `Clone`. Cloning creates a deep copy including the
/// parent chain. This is used when snapshotting state but should be avoided
/// in per-frame code due to allocation cost.
///
/// # Fields
/// - `entries` — `HashMap<String, BlackboardValue>`.
/// - `parent` — `Option<Box<Blackboard>>`.
#[derive(Clone)]
pub struct Blackboard {
    /// Local key-value entries. Keys are case-sensitive strings.
    pub(crate) entries: HashMap<String, BlackboardValue>,
    /// Optional parent blackboard for hierarchical read-through.
    /// Writes never propagate to the parent.
    pub(crate) parent: Option<Box<Blackboard>>,
}

impl Blackboard {
    /// Creates an empty Blackboard with no parent.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        log_msg!(debug, BB01);
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
        log_msg!(trace, BB02, "{}", key);
        self.entries.remove(key);
    }

    /// Clears all local entries. Parent is unaffected.
    pub fn clear(&mut self) {
        let count = self.entries.len();
        self.entries.clear();
        log_msg!(debug, BB03, "{}", count);
    }

    /// Returns all local key names.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn keys(&self) -> Vec<String> {
        self.entries.keys().cloned().collect()
    }

    /// Returns the number of local entries. Runs in O(1) time.
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

#[cfg(test)]
mod tests {
    use super::*;

    // ── Number ─────────────────────────────────────────────────────────────────

    #[test]
    fn set_get_number_roundtrip() {
        let mut bb = Blackboard::new();
        bb.set_number("hp", 100.0);
        let v = bb.get_number("hp", 0.0);
        assert!((v - 100.0).abs() < 1e-10);
    }

    #[test]
    fn missing_number_returns_default() {
        let bb = Blackboard::new();
        assert!((bb.get_number("missing", 42.0) - 42.0).abs() < 1e-10);
    }

    // ── Bool ──────────────────────────────────────────────────────────────────

    #[test]
    fn set_get_bool_roundtrip() {
        let mut bb = Blackboard::new();
        bb.set_bool("alert", true);
        assert!(bb.get_bool("alert", false));
    }

    #[test]
    fn missing_bool_returns_default() {
        let bb = Blackboard::new();
        assert!(!bb.get_bool("missing", false));
    }

    // ── String ────────────────────────────────────────────────────────────────

    #[test]
    fn set_get_string_roundtrip() {
        let mut bb = Blackboard::new();
        bb.set_string("state", "attack");
        assert_eq!(bb.get_string("state", ""), "attack");
    }

    #[test]
    fn missing_string_returns_default() {
        let bb = Blackboard::new();
        assert_eq!(bb.get_string("missing", "default"), "default");
    }

    // ── Has / Remove / Clear ─────────────────────────────────────────────────

    #[test]
    fn has_existing_key_true() {
        let mut bb = Blackboard::new();
        bb.set_number("x", 1.0);
        assert!(bb.has("x"));
    }

    #[test]
    fn has_missing_key_false() {
        let bb = Blackboard::new();
        assert!(!bb.has("none"));
    }

    #[test]
    fn remove_clears_key() {
        let mut bb = Blackboard::new();
        bb.set_number("y", 5.0);
        bb.remove("y");
        assert!(!bb.has("y"));
    }

    #[test]
    fn clear_empties_local_store() {
        let mut bb = Blackboard::new();
        bb.set_number("a", 1.0);
        bb.set_bool("b", true);
        bb.clear();
        assert_eq!(bb.size(), 0);
    }

    // ── Parent lookup ────────────────────────────────────────────────────────

    #[test]
    fn parent_lookup_reads_parent_value() {
        let mut parent = Blackboard::new();
        parent.set_number("shared", 99.0);
        let mut child = Blackboard::new();
        child.set_parent(parent);
        let v = child.get_number("shared", 0.0);
        assert!((v - 99.0).abs() < 1e-10);
    }
}
