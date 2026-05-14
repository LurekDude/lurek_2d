
use std::collections::HashMap;
use std::hash::Hash;
/// Hash map with O(1) lookups in both directions using mirrored forward and reverse tables.
#[derive(Debug, Clone)]
pub struct BiMap<K, V> {
    /// Forward map: key → value.
    fwd: HashMap<K, V>,
    /// Reverse map: value → key.
    rev: HashMap<V, K>,
}
/// All methods for `BiMap`.
impl<K: Clone + Hash + Eq, V: Clone + Hash + Eq> BiMap<K, V> {
    /// Create an empty `BiMap`.
    pub fn new() -> Self {
        Self {
            fwd: HashMap::new(),
            rev: HashMap::new(),
        }
    }
    /// Insert the `key`/`value` pair, removing any existing pair that shares the same key or value.
    pub fn insert(&mut self, key: K, value: V) {
        if let Some(old_val) = self.fwd.get(&key) {
            self.rev.remove(old_val);
        }
        if let Some(old_key) = self.rev.get(&value) {
            self.fwd.remove(old_key);
        }
        self.fwd.insert(key.clone(), value.clone());
        self.rev.insert(value, key);
    }
    /// Return the value associated with `key`, or `None`.
    pub fn get_by_key(&self, key: &K) -> Option<&V> {
        self.fwd.get(key)
    }
    /// Return the key associated with `value`, or `None`.
    pub fn get_by_value(&self, value: &V) -> Option<&K> {
        self.rev.get(value)
    }
    /// Return true when `key` is present.
    pub fn contains_key(&self, key: &K) -> bool {
        self.fwd.contains_key(key)
    }
    /// Return true when `value` is present.
    pub fn contains_value(&self, value: &V) -> bool {
        self.rev.contains_key(value)
    }
    /// Remove the pair identified by `key`; return `(key, value)` or `None` when absent.
    pub fn remove_by_key(&mut self, key: &K) -> Option<(K, V)> {
        if let Some(val) = self.fwd.remove(key) {
            self.rev.remove(&val);
            Some((key.clone(), val))
        } else {
            None
        }
    }
    /// Remove the pair identified by `value`; return `(key, value)` or `None` when absent.
    pub fn remove_by_value(&mut self, value: &V) -> Option<(K, V)> {
        if let Some(key) = self.rev.remove(value) {
            self.fwd.remove(&key);
            Some((key, value.clone()))
        } else {
            None
        }
    }
    /// Return the number of key-value pairs.
    pub fn len(&self) -> usize {
        self.fwd.len()
    }
    /// Return true when the map contains no pairs.
    pub fn is_empty(&self) -> bool {
        self.fwd.is_empty()
    }
    /// Remove all pairs from the map.
    pub fn clear(&mut self) {
        self.fwd.clear();
        self.rev.clear();
    }
}
/// Delegates to `Self::new()`.
impl<K: Clone + Hash + Eq, V: Clone + Hash + Eq> Default for BiMap<K, V> {
    fn default() -> Self {
        Self::new()
    }
}
