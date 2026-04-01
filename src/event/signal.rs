//! Handle-based pub-sub signal system.
//!
//! `Signal` provides a lightweight event bus where listeners subscribe by
//! name and receive a monotonically increasing handle ID for later removal.
//! Callbacks fire in registration order.

use std::collections::HashMap;

/// A single subscription entry in a [`Signal`].
#[derive(Debug, Clone)]
pub struct Subscription {
    /// Unique handle ID (monotonic, per-Signal instance).
    pub handle: u64,
    /// The event name this subscription listens to.
    pub name: String,
}

/// Handle-based pub-sub signal dispatcher.
///
/// Listeners register for named events and receive a unique handle ID.
/// When an event is emitted, all matching callbacks fire in registration order.
/// The actual callback functions are stored externally (e.g. in the Lua registry);
/// this struct tracks only the subscription metadata.
#[derive(Debug)]
pub struct Signal {
    /// Next handle ID to assign (monotonically increasing).
    next_handle: u64,
    /// Maps event names to ordered lists of subscription handles.
    subscriptions: HashMap<String, Vec<u64>>,
    /// Maps handle IDs to their event name (for removal by handle).
    handle_to_name: HashMap<u64, String>,
}

impl Signal {
    /// Creates a new empty signal dispatcher.
    pub fn new() -> Self {
        Self {
            next_handle: 1,
            subscriptions: HashMap::new(),
            handle_to_name: HashMap::new(),
        }
    }

    /// Registers a subscription for the given event name.
    ///
    /// Returns a unique handle ID that can be used with [`remove`](Self::remove).
    pub fn subscribe(&mut self, name: &str) -> u64 {
        let handle = self.next_handle;
        self.next_handle += 1;
        self.subscriptions
            .entry(name.to_string())
            .or_default()
            .push(handle);
        self.handle_to_name.insert(handle, name.to_string());
        handle
    }

    /// Removes a subscription by its handle ID.
    ///
    /// Returns `true` if the handle existed and was removed.
    pub fn remove(&mut self, handle: u64) -> bool {
        if let Some(name) = self.handle_to_name.remove(&handle) {
            if let Some(handles) = self.subscriptions.get_mut(&name) {
                handles.retain(|&h| h != handle);
                if handles.is_empty() {
                    self.subscriptions.remove(&name);
                }
            }
            true
        } else {
            false
        }
    }

    /// Removes all subscriptions for the given event name.
    ///
    /// Returns the number of subscriptions removed.
    pub fn clear(&mut self, name: &str) -> usize {
        if let Some(handles) = self.subscriptions.remove(name) {
            let count = handles.len();
            for h in &handles {
                self.handle_to_name.remove(h);
            }
            count
        } else {
            0
        }
    }

    /// Removes all subscriptions across all event names.
    ///
    /// Returns the total number of subscriptions removed.
    pub fn clear_all(&mut self) -> usize {
        let count = self.handle_to_name.len();
        self.subscriptions.clear();
        self.handle_to_name.clear();
        count
    }

    /// Returns the handles registered for the given event name (in registration order).
    ///
    /// Returns an empty slice if no subscriptions exist for the name.
    pub fn get_handles(&self, name: &str) -> Vec<u64> {
        self.subscriptions.get(name).cloned().unwrap_or_default()
    }

    /// Returns the number of subscriptions for the given event name.
    pub fn get_count(&self, name: &str) -> usize {
        self.subscriptions.get(name).map_or(0, |v| v.len())
    }

    /// Returns the total number of subscriptions across all event names.
    pub fn get_total_count(&self) -> usize {
        self.handle_to_name.len()
    }
}

impl Default for Signal {
    fn default() -> Self {
        Self::new()
    }
}
