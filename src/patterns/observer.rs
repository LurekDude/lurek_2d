//! Reactive property observer for game state change notifications.
//!
//! [`Observer`] is a property bag where game code can subscribe to individual
//! key changes. Unlike the general [`super::EventBus`] which dispatches named
//! events, an Observer tracks named *properties* and fires callbacks only for
//! the specific keys a subscriber has registered interest in. Callbacks are
//! stored in the Lua API layer; this module tracks subscription metadata.

use std::collections::HashMap;

// ── ObserverEntry ─────────────────────────────────────────────────────────

/// A single observer subscription record (metadata only; callback in Lua layer).
///
/// # Fields
/// - `id` — `u64`.
/// - `key` — `String`.
/// - `once` — `bool`.
#[derive(Debug, Clone)]
pub struct ObserverEntry {
    /// Unique subscription id.
    pub id: u64,
    /// The property key this subscription watches. `"*"` watches all keys.
    pub key: String,
    /// When `true` the subscription is removed after first notification.
    pub once: bool,
}

// ── Observer ──────────────────────────────────────────────────────────────

/// Reactive property bag: stores string-keyed string values and tracks
/// subscriptions by property key.
///
/// Watcher callbacks are stored in the Lua API layer. The domain layer only
/// records subscription metadata and produces watcher id lists when asked.
///
/// # Fields
/// - `name` — `String`.
#[derive(Debug)]
pub struct Observer {
    /// Display name for debugging.
    pub name: String,
    next_id: u64,
    subscriptions: HashMap<String, Vec<ObserverEntry>>,
}

impl Observer {
    /// Creates a new observer with the given name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            next_id: 1,
            subscriptions: HashMap::new(),
        }
    }

    /// Registers a watcher for `key` (or `"*"` for all changes).
    ///
    /// # Parameters
    /// - `key` — `&str`.
    /// - `once` — `bool`.
    ///
    /// # Returns
    /// `u64`.
    pub fn subscribe(&mut self, key: &str, once: bool) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        let entry = ObserverEntry { id, key: key.to_string(), once };
        self.subscriptions.entry(key.to_string()).or_default().push(entry);
        id
    }

    /// Removes a subscription by id.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn unsubscribe(&mut self, id: u64) -> bool {
        let mut found = false;
        for subs in self.subscriptions.values_mut() {
            let before = subs.len();
            subs.retain(|e| e.id != id);
            if subs.len() < before { found = true; }
        }
        found
    }

    /// Returns subscriber ids that should fire when `key` changes.
    /// Includes wildcard (`"*"`) subscribers.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `Vec<u64>`.
    pub fn watchers_for(&mut self, key: &str) -> Vec<u64> {
        let mut ids = Vec::new();
        let mut once_ids = Vec::new();

        // Key-specific
        if let Some(subs) = self.subscriptions.get(key) {
            for e in subs {
                ids.push(e.id);
                if e.once { once_ids.push(e.id); }
            }
        }
        // Wildcard
        if let Some(subs) = self.subscriptions.get("*") {
            for e in subs {
                ids.push(e.id);
                if e.once { once_ids.push(e.id); }
            }
        }

        // Remove one-shot subscriptions
        for id in once_ids {
            self.unsubscribe(id);
        }

        ids
    }

    /// Removes all subscriptions for a specific key.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    pub fn clear_key(&mut self, key: &str) {
        self.subscriptions.remove(key);
    }

    /// Removes all subscriptions.
    pub fn clear_all(&mut self) {
        self.subscriptions.clear();
    }

    /// Total number of active subscriptions across all keys.
    ///
    /// # Returns
    /// `usize`.
    pub fn subscription_count(&self) -> usize {
        self.subscriptions.values().map(Vec::len).sum()
    }
}
