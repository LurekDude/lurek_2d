//! Bidirectional key–value map.
//!
//! `BiMap<K, V>` maintains two `HashMap`s: forward (`K → V`) and reverse
//! (`V → K`). Both `K` and `V` must be `Clone + Hash + Eq`. Insert, lookup
//! from either direction, and remove are all O(1) average.

use std::collections::HashMap;
use std::hash::Hash;

/// Bidirectional key–value map where look-ups can be made from either side.
///
/// Enforces bijection: each key maps to exactly one value, and no two keys
/// map to the same value. Inserting a key that already maps to a different
/// value replaces the old mapping **and** removes the old reverse entry.
///
/// # Type Parameters
/// - `K` — Key type, must implement `Clone + Hash + Eq`.
/// - `V` — Value type, must implement `Clone + Hash + Eq`.
#[derive(Debug, Clone)]
pub struct BiMap<K, V> {
    /// Forward direction: key → value.
    fwd: HashMap<K, V>,
    /// Reverse direction: value → key.
    rev: HashMap<V, K>,
}

impl<K: Clone + Hash + Eq, V: Clone + Hash + Eq> BiMap<K, V> {
    /// Creates a new empty bidirectional map.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            fwd: HashMap::new(),
            rev: HashMap::new(),
        }
    }

    /// Inserts a key–value pair.
    ///
    /// If the key already maps to a different value, the old value's reverse
    /// entry is removed. If the value is already mapped from a different key,
    /// that key's forward entry is removed.
    ///
    /// # Parameters
    /// - `key` — `K`.
    /// - `value` — `V`.
    pub fn insert(&mut self, key: K, value: V) {
        // Remove stale reverse entry for old value at this key.
        if let Some(old_val) = self.fwd.get(&key) {
            self.rev.remove(old_val);
        }
        // Remove stale forward entry for old key at this value.
        if let Some(old_key) = self.rev.get(&value) {
            self.fwd.remove(old_key);
        }
        self.fwd.insert(key.clone(), value.clone());
        self.rev.insert(value, key);
    }

    /// Returns the value mapped to `key`, if any.
    ///
    /// # Parameters
    /// - `key` — `&K`.
    ///
    /// # Returns
    /// `Option<&V>`.
    pub fn get_by_key(&self, key: &K) -> Option<&V> {
        self.fwd.get(key)
    }

    /// Returns the key mapped to `value`, if any.
    ///
    /// # Parameters
    /// - `value` — `&V`.
    ///
    /// # Returns
    /// `Option<&K>`.
    pub fn get_by_value(&self, value: &V) -> Option<&K> {
        self.rev.get(value)
    }

    /// Returns `true` if `key` is present in the forward map.
    ///
    /// # Parameters
    /// - `key` — `&K`.
    ///
    /// # Returns
    /// `bool`.
    pub fn contains_key(&self, key: &K) -> bool {
        self.fwd.contains_key(key)
    }

    /// Returns `true` if `value` is present in the reverse map.
    ///
    /// # Parameters
    /// - `value` — `&V`.
    ///
    /// # Returns
    /// `bool`.
    pub fn contains_value(&self, value: &V) -> bool {
        self.rev.contains_key(value)
    }

    /// Removes the entry associated with `key` (and its reverse entry).
    ///
    /// Returns the removed `(K, V)` pair if the key existed.
    ///
    /// # Parameters
    /// - `key` — `&K`.
    ///
    /// # Returns
    /// `Option<(K, V)>`.
    pub fn remove_by_key(&mut self, key: &K) -> Option<(K, V)> {
        if let Some(val) = self.fwd.remove(key) {
            self.rev.remove(&val);
            Some((key.clone(), val))
        } else {
            None
        }
    }

    /// Removes the entry associated with `value` (and its forward entry).
    ///
    /// Returns the removed `(K, V)` pair if the value existed.
    ///
    /// # Parameters
    /// - `value` — `&V`.
    ///
    /// # Returns
    /// `Option<(K, V)>`.
    pub fn remove_by_value(&mut self, value: &V) -> Option<(K, V)> {
        if let Some(key) = self.rev.remove(value) {
            self.fwd.remove(&key);
            Some((key, value.clone()))
        } else {
            None
        }
    }

    /// Returns the number of key–value pairs.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.fwd.len()
    }

    /// Returns `true` if the map contains no entries.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.fwd.is_empty()
    }

    /// Removes all entries.
    pub fn clear(&mut self) {
        self.fwd.clear();
        self.rev.clear();
    }
}

impl<K: Clone + Hash + Eq, V: Clone + Hash + Eq> Default for BiMap<K, V> {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bimap_insert_get_by_key_returns_value() {
        let mut m: BiMap<&str, u32> = BiMap::new();
        m.insert("health", 42);
        assert_eq!(m.get_by_key(&"health"), Some(&42));
    }

    #[test]
    fn bimap_get_by_value_returns_key() {
        let mut m: BiMap<&str, u32> = BiMap::new();
        m.insert("health", 42);
        assert_eq!(m.get_by_value(&42), Some(&"health"));
    }

    #[test]
    fn bimap_insert_same_key_removes_old_reverse() {
        let mut m: BiMap<&str, u32> = BiMap::new();
        m.insert("stat", 1);
        m.insert("stat", 2);
        assert!(!m.contains_value(&1));
        assert_eq!(m.get_by_key(&"stat"), Some(&2));
    }

    #[test]
    fn bimap_remove_by_key_removes_both_sides() {
        let mut m: BiMap<&str, u32> = BiMap::new();
        m.insert("x", 10);
        m.remove_by_key(&"x");
        assert!(!m.contains_key(&"x"));
        assert!(!m.contains_value(&10));
    }
}
