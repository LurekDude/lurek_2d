//! Handle-based pub-sub signal system.
//!
//! `Signal` provides a lightweight event bus where listeners subscribe by
//! name and receive a monotonically increasing handle ID for later removal.
//! Callbacks fire in registration order.

use crate::engine::log_messages::{SG01, SG02};
use crate::log_msg;
use std::collections::HashMap;

/// A single subscription entry in a [`Signal`].
///
/// # Fields
/// - `handle` — `u64`.
/// - `name` — `String`.
#[derive(Debug, Clone)]
#[allow(dead_code)]
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
///
/// # Fields
/// - `next_handle` — `u64`.
/// - `subscriptions` — `HashMap<String`.
/// - `handle_to_name` — `HashMap<u64`.
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
    /// Creates a new empty signal dispatcher. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        log_msg!(debug, SG01);
        Self {
            next_handle: 1,
            subscriptions: HashMap::new(),
            handle_to_name: HashMap::new(),
        }
    }

    /// Registers a subscription for the given event name.
    ///
    /// Returns a unique handle ID that can be used with [`remove`](Self::remove).
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `u64`.
    pub fn subscribe(&mut self, name: &str) -> u64 {
        let handle = self.next_handle;
        self.next_handle += 1;
        self.subscriptions
            .entry(name.to_string())
            .or_default()
            .push(handle);
        self.handle_to_name.insert(handle, name.to_string());
        log_msg!(debug, SG02, "{}", name);
        handle
    }

    /// Removes a subscription by its handle ID.
    ///
    /// Returns `true` if the handle existed and was removed.
    ///
    /// # Parameters
    /// - `handle` — `u64`.
    ///
    /// # Returns
    /// `bool`.
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
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `usize`.
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
    ///
    /// # Returns
    /// `usize`.
    pub fn clear_all(&mut self) -> usize {
        let count = self.handle_to_name.len();
        self.subscriptions.clear();
        self.handle_to_name.clear();
        count
    }

    /// Returns the handles registered for the given event name (in registration order).
    ///
    /// Returns an empty slice if no subscriptions exist for the name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Vec<u64>`.
    pub fn get_handles(&self, name: &str) -> Vec<u64> {
        self.subscriptions.get(name).cloned().unwrap_or_default()
    }

    /// Returns the number of subscriptions for the given event name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_count(&self, name: &str) -> usize {
        self.subscriptions.get(name).map_or(0, |v| v.len())
    }

    /// Returns the total number of subscriptions across all event names.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_total_count(&self) -> usize {
        self.handle_to_name.len()
    }
}

impl Default for Signal {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Subscribe ───────────────────────────────────────────────────────────

    #[test]
    fn subscribe_returns_incrementing_handles() {
        let mut s = Signal::new();
        let h1 = s.subscribe("click");
        let h2 = s.subscribe("click");
        assert!(h2 > h1);
    }

    #[test]
    fn get_count_after_subscribe() {
        let mut s = Signal::new();
        s.subscribe("fire");
        s.subscribe("fire");
        assert_eq!(s.get_count("fire"), 2);
    }

    #[test]
    fn subscribe_two_events_independent() {
        let mut s = Signal::new();
        s.subscribe("a");
        s.subscribe("b");
        s.subscribe("b");
        assert_eq!(s.get_count("a"), 1);
        assert_eq!(s.get_count("b"), 2);
    }

    // ── Remove ────────────────────────────────────────────────────────────────

    #[test]
    fn remove_decrements_count() {
        let mut s = Signal::new();
        let h = s.subscribe("update");
        assert_eq!(s.get_count("update"), 1);
        let removed = s.remove(h);
        assert!(removed);
        assert_eq!(s.get_count("update"), 0);
    }

    #[test]
    fn remove_nonexistent_handle_returns_false() {
        let mut s = Signal::new();
        assert!(!s.remove(999));
    }

    // ── Clear ─────────────────────────────────────────────────────────────────

    #[test]
    fn clear_empties_named_event() {
        let mut s = Signal::new();
        s.subscribe("draw");
        s.subscribe("draw");
        s.clear("draw");
        assert_eq!(s.get_count("draw"), 0);
    }

    #[test]
    fn clear_all_removes_everything() {
        let mut s = Signal::new();
        s.subscribe("a");
        s.subscribe("b");
        s.clear_all();
        assert_eq!(s.get_total_count(), 0);
    }
}
