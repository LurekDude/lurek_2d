
//! - Name-based service registry for runtime feature discovery.
//! - Register, unregister, and query string-keyed services.
//! - Sorted enumeration of all active service names.

use std::collections::HashSet;

/// String-keyed service registry for runtime feature queries.
#[derive(Debug, Default)]
pub struct ServiceLocator {
    /// Set of currently registered service names.
    pub services: HashSet<String>,
}
/// All methods for `ServiceLocator`.
impl ServiceLocator {
    /// Create an empty service locator.
    pub fn new() -> Self {
        Self::default()
    }
    /// Add `name` to the registered set.
    pub fn register(&mut self, name: &str) {
        self.services.insert(name.to_string());
    }
    /// Remove `name`; return true when it existed.
    pub fn unregister(&mut self, name: &str) -> bool {
        self.services.remove(name)
    }
    /// Return true when `name` is registered.
    pub fn has(&self, name: &str) -> bool {
        self.services.contains(name)
    }
    /// Return all registered names in sorted order.
    pub fn names(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.services.iter().map(String::as_str).collect();
        names.sort();
        names
    }
    /// Unregister all services. This function is part of the public API.
    pub fn clear(&mut self) {
        self.services.clear();
    }
}
