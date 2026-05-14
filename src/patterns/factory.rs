
use std::collections::HashSet;
/// Registry of named constructable types with optional string aliases.
#[derive(Debug, Default)]
pub struct Factory {
    /// Canonical type names that have been registered.
    pub types: HashSet<String>,
    /// Alias-to-canonical-name mapping.
    pub aliases: std::collections::HashMap<String, String>,
}
/// Registration and lookup methods for `Factory`.
impl Factory {
    /// Create an empty factory.
    pub fn new() -> Self {
        Self::default()
    }
    /// Register `name` as a known type.
    pub fn register(&mut self, name: &str) {
        self.types.insert(name.to_string());
    }
    /// Remove `name` and any aliases pointing to it; return true when the type existed.
    pub fn unregister(&mut self, name: &str) -> bool {
        self.aliases.retain(|_, v| v != name);
        self.types.remove(name)
    }
    /// Return true when `name` is a registered type or a known alias.
    pub fn has(&self, name: &str) -> bool {
        self.types.contains(name) || self.aliases.contains_key(name)
    }
    /// Return the canonical name for `name`, following one level of alias if present.
    pub fn resolve<'a>(&'a self, name: &'a str) -> &'a str {
        self.aliases.get(name).map(String::as_str).unwrap_or(name)
    }
    /// Map `alias` to `canonical`; overwrites any previous mapping for that alias.
    pub fn add_alias(&mut self, alias: &str, canonical: &str) {
        self.aliases
            .insert(alias.to_string(), canonical.to_string());
    }
    /// Return all registered canonical type names sorted alphabetically.
    pub fn type_names(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.types.iter().map(String::as_str).collect();
        names.sort();
        names
    }
    /// Remove all types and aliases.
    pub fn clear(&mut self) {
        self.types.clear();
        self.aliases.clear();
    }
}
