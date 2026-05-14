
use std::collections::HashSet;
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
    /// Unregister all services.
    pub fn clear(&mut self) {
        self.services.clear();
    }
}
