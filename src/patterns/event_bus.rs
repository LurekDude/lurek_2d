//! Priority-ordered event bus with one-shot subscriptions and wildcard `*` matching.
//! Stores subscription metadata only; dispatch is performed by callers using returned listener IDs.

use std::collections::HashMap;
/// Metadata for a single event subscription.
#[derive(Debug, Clone)]
pub struct Subscription {
    /// Unique subscription identifier.
    pub id: u64,
    /// Event name this subscription listens to; `"*"` matches all events.
    pub event: String,
    /// Higher values are dispatched first.
    pub priority: i64,
    /// When true, the subscription is removed after the first dispatch.
    pub once: bool,
}
/// Named event router that tracks subscriptions and returns ordered listener ID lists.
#[derive(Debug)]
pub struct EventBus {
    /// Debug name for this bus instance.
    pub name: String,
    /// When false, `get_listeners` returns an empty list.
    pub enabled: bool,
    /// Next subscription identifier to assign.
    next_id: u64,
    /// Active subscriptions keyed by id.
    subs: HashMap<u64, Subscription>,
}
/// All methods for `EventBus`.
impl EventBus {
    /// Create an enabled bus named `name`.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            enabled: true,
            next_id: 1,
            subs: HashMap::new(),
        }
    }
    /// Register a listener for `event` with `priority` and `once` flag; return the subscription id.
    pub fn subscribe(&mut self, event: &str, priority: i64, once: bool) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        self.subs.insert(
            id,
            Subscription {
                id,
                event: event.to_string(),
                priority,
                once,
            },
        );
        id
    }
    /// Remove the subscription with `id`; return true when it existed.
    pub fn unsubscribe(&mut self, id: u64) -> bool {
        self.subs.remove(&id).is_some()
    }
    /// Return listener IDs for `event` sorted by descending priority; empty when bus is disabled.
    pub fn get_listeners(&self, event: &str) -> Vec<u64> {
        if !self.enabled {
            return Vec::new();
        }
        let mut listeners: Vec<&Subscription> = self
            .subs
            .values()
            .filter(|s| s.event == event || s.event == "*")
            .collect();
        listeners.sort_by(|a, b| b.priority.cmp(&a.priority));
        listeners.iter().map(|s| s.id).collect()
    }
    /// Remove all `once` subscriptions from `ids` and return the removed ids.
    pub fn drain_once(&mut self, ids: &[u64]) -> Vec<u64> {
        let once: Vec<u64> = ids
            .iter()
            .copied()
            .filter(|id| self.subs.get(id).map(|s| s.once).unwrap_or(false))
            .collect();
        for id in &once {
            self.subs.remove(id);
        }
        once
    }
    /// Remove all subscriptions for `event`; return the removed ids.
    pub fn clear_event(&mut self, event: &str) -> Vec<u64> {
        let ids: Vec<u64> = self
            .subs
            .values()
            .filter(|s| s.event == event)
            .map(|s| s.id)
            .collect();
        for id in &ids {
            self.subs.remove(id);
        }
        ids
    }
    /// Remove all subscriptions; return all removed ids.
    pub fn clear_all(&mut self) -> Vec<u64> {
        let ids: Vec<u64> = self.subs.keys().copied().collect();
        self.subs.clear();
        ids
    }
    /// Return the number of active subscriptions for exactly `event`.
    pub fn listener_count(&self, event: &str) -> usize {
        self.subs.values().filter(|s| s.event == event).count()
    }
    /// Return all distinct event names with at least one subscriber, sorted alphabetically.
    pub fn event_names(&self) -> Vec<String> {
        let mut events: Vec<String> = self
            .subs
            .values()
            .map(|s| s.event.clone())
            .collect::<std::collections::HashSet<_>>()
            .into_iter()
            .collect();
        events.sort();
        events
    }
    /// Return the total number of active subscriptions across all events.
    pub fn total_count(&self) -> usize {
        self.subs.len()
    }
}
