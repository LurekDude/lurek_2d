use std::collections::HashMap;
use std::hash::Hash;
#[derive(Debug, Clone)]
pub struct BiMap<K, V> {
    fwd: HashMap<K, V>,
    rev: HashMap<V, K>,
}
impl<K: Clone + Hash + Eq, V: Clone + Hash + Eq> BiMap<K, V> {
    pub fn new() -> Self {
        Self {
            fwd: HashMap::new(),
            rev: HashMap::new(),
        }
    }
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
    pub fn get_by_key(&self, key: &K) -> Option<&V> {
        self.fwd.get(key)
    }
    pub fn get_by_value(&self, value: &V) -> Option<&K> {
        self.rev.get(value)
    }
    pub fn contains_key(&self, key: &K) -> bool {
        self.fwd.contains_key(key)
    }
    pub fn contains_value(&self, value: &V) -> bool {
        self.rev.contains_key(value)
    }
    pub fn remove_by_key(&mut self, key: &K) -> Option<(K, V)> {
        if let Some(val) = self.fwd.remove(key) {
            self.rev.remove(&val);
            Some((key.clone(), val))
        } else {
            None
        }
    }
    pub fn remove_by_value(&mut self, value: &V) -> Option<(K, V)> {
        if let Some(key) = self.rev.remove(value) {
            self.fwd.remove(&key);
            Some((key, value.clone()))
        } else {
            None
        }
    }
    pub fn len(&self) -> usize {
        self.fwd.len()
    }
    pub fn is_empty(&self) -> bool {
        self.fwd.is_empty()
    }
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
