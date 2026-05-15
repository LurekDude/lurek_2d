
//! - Named observer pattern with per-key subscription lists and wildcard support.
//! - One-shot (`once`) and persistent subscription modes with auto-cleanup on dispatch.
//! - Key-scoped and global clear operations for lifecycle management.

use std::collections::HashMap;
#[derive(Debug, Clone)]
/// Defines the public observer entry data type used by this module.
pub struct ObserverEntry {
    /// Unique subscription id.
    pub id: u64,
    /// Key this entry is registered under.
    pub key: String,
    /// When true, the entry is removed after its first dispatch.
    pub once: bool,
}
/// Named observer managing per-key subscription lists.
#[derive(Debug)]
pub struct Observer {
    /// Debug name.
    pub name: String,
    /// Next subscription id to assign.
    next_id: u64,
    /// Per-key subscription lists.
    subscriptions: HashMap<String, Vec<ObserverEntry>>,
}
/// All methods for `Observer`.
impl Observer {
    /// Create a named empty observer.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            next_id: 1,
            subscriptions: HashMap::new(),
        }
    }
    /// Register a subscription for `key`; when `once` is true it fires once then is removed; return its id.
    pub fn subscribe(&mut self, key: &str, once: bool) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        let entry = ObserverEntry {
            id,
            key: key.to_string(),
            once,
        };
        self.subscriptions
            .entry(key.to_string())
            .or_default()
            .push(entry);
        id
    }
    /// Remove subscription with `id` across all keys; return true when it was found.
    pub fn unsubscribe(&mut self, id: u64) -> bool {
        let mut found = false;
        for subs in self.subscriptions.values_mut() {
            let before = subs.len();
            subs.retain(|e| e.id != id);
            if subs.len() < before {
                found = true;
            }
        }
        found
    }
    /// Return ids of all watchers for `key` (plus `"*"` wildcards), removing any once-subscriptions.
    pub fn watchers_for(&mut self, key: &str) -> Vec<u64> {
        let mut ids = Vec::new();
        let mut once_ids = Vec::new();
        if let Some(subs) = self.subscriptions.get(key) {
            for e in subs {
                ids.push(e.id);
                if e.once {
                    once_ids.push(e.id);
                }
            }
        }
        if let Some(subs) = self.subscriptions.get("*") {
            for e in subs {
                ids.push(e.id);
                if e.once {
                    once_ids.push(e.id);
                }
            }
        }
        for id in once_ids {
            self.unsubscribe(id);
        }
        ids
    }
    /// Remove all subscriptions for `key`.
    pub fn clear_key(&mut self, key: &str) {
        self.subscriptions.remove(key);
    }
    /// Remove all subscriptions. This function is part of the public API.
    pub fn clear_all(&mut self) {
        self.subscriptions.clear();
    }
    /// Return the total number of active subscriptions across all keys.
    pub fn subscription_count(&self) -> usize {
        self.subscriptions.values().map(Vec::len).sum()
    }
}
