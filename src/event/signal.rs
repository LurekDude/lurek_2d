//! Named signal subscriptions with wildcard pattern support.

use crate::log_msg;
use crate::runtime::log_messages::{SG01, SG02};
use std::collections::HashMap;
#[derive(Debug, Clone)]
#[allow(dead_code)]
/// Public snapshot of one subscription handle and its registered name.
pub struct Subscription {
    /// Opaque numeric subscription id used for later removal.
    pub handle: u64,
    /// Exact signal name or wildcard pattern bound to the handle.
    pub name: String,
}
#[derive(Debug)]
/// Stores signal subscriptions by exact name and wildcard pattern.
pub struct Signal {
    /// Monotonic counter used when allocating new subscription ids.
    next_handle: u64,
    /// Exact-name subscriptions keyed by signal name.
    subscriptions: HashMap<String, Vec<u64>>,
    /// Reverse lookup from subscription id to exact signal name or wildcard pattern.
    handle_to_name: HashMap<u64, String>,
    /// Wildcard subscriptions stored as pattern and subscription-id pairs.
    wildcard_subs: Vec<(String, u64)>,
}
impl Signal {
    /// Creates an empty signal registry.
    pub fn new() -> Self {
        log_msg!(debug, SG01);
        Self {
            next_handle: 1,
            subscriptions: HashMap::new(),
            handle_to_name: HashMap::new(),
            wildcard_subs: Vec::new(),
        }
    }
    /// Registers a subscription for one exact signal name and returns its id.
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
    /// Removes a subscription id from exact-name and wildcard storage.
    pub fn remove(&mut self, handle: u64) -> bool {
        if let Some(name) = self.handle_to_name.remove(&handle) {
            if let Some(handles) = self.subscriptions.get_mut(&name) {
                handles.retain(|&h| h != handle);
                if handles.is_empty() {
                    self.subscriptions.remove(&name);
                }
            }
            self.wildcard_subs.retain(|(_, h)| *h != handle);
            true
        } else {
            false
        }
    }
    /// Removes every exact-name subscription registered for the given signal name.
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
    /// Removes every stored subscription and returns the number removed.
    pub fn clear_all(&mut self) -> usize {
        let count = self.handle_to_name.len();
        self.subscriptions.clear();
        self.handle_to_name.clear();
        self.wildcard_subs.clear();
        count
    }
    /// Returns the subscription ids registered for one exact signal name.
    pub fn get_handles(&self, name: &str) -> Vec<u64> {
        self.subscriptions.get(name).cloned().unwrap_or_default()
    }
    /// Returns the number of subscriptions registered for one exact signal name.
    pub fn get_count(&self, name: &str) -> usize {
        self.subscriptions.get(name).map_or(0, |v| v.len())
    }
    /// Returns the total number of registered subscriptions.
    pub fn get_total_count(&self) -> usize {
        self.handle_to_name.len()
    }
    /// Registers a wildcard subscription pattern and returns its id.
    pub fn subscribe_wildcard(&mut self, pattern: &str) -> u64 {
        let handle = self.next_handle;
        self.next_handle += 1;
        self.wildcard_subs.push((pattern.to_string(), handle));
        self.handle_to_name.insert(handle, pattern.to_string());
        handle
    }
    /// Returns wildcard subscription ids whose pattern matches the signal name.
    pub fn get_wildcard_handles(&self, name: &str) -> Vec<u64> {
        self.wildcard_subs
            .iter()
            .filter(|(pat, _)| glob_match(pat, name))
            .map(|(_, h)| *h)
            .collect()
    }
    /// Returns whether a subscription name contains wildcard metacharacters.
    pub fn is_wildcard(pattern: &str) -> bool {
        pattern.contains('*') || pattern.contains('?')
    }
}
impl Default for Signal {
    /// Creates an empty signal registry.
    fn default() -> Self {
        Self::new()
    }
}
/// Matches `*` and `?` wildcards against a candidate signal name.
fn glob_match(pattern: &str, name: &str) -> bool {
    let p = pattern.as_bytes();
    let n = name.as_bytes();
    let mut pi = 0usize;
    let mut ni = 0usize;
    let mut star_pi = usize::MAX;
    let mut star_ni = 0usize;
    while ni < n.len() {
        if pi < p.len() && (p[pi] == b'?' || p[pi] == n[ni]) {
            pi += 1;
            ni += 1;
        } else if pi < p.len() && p[pi] == b'*' {
            star_pi = pi;
            star_ni = ni;
            pi += 1;
        } else if star_pi != usize::MAX {
            pi = star_pi + 1;
            star_ni += 1;
            ni = star_ni;
        } else {
            return false;
        }
    }
    while pi < p.len() && p[pi] == b'*' {
        pi += 1;
    }
    pi == p.len()
}
