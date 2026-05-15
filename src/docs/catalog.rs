//! - Provide in-memory catalog storage for documentation entries collected from Rust source.
//! - Support insertion-order preservation, module grouping, and text search.
//! - Offer merge, filter, and deduplication for multi-source doc aggregation.

use crate::docs::entry::DocEntry;
/// Hold the in-memory list of documentation entries collected from source data.
pub struct Catalog {
    /// Preserve all collected entries in insertion order for export stages.
    entries: Vec<DocEntry>,
}
impl Catalog {
    /// Create an empty catalog and return it for entry aggregation.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
        }
    }
    /// Build a catalog from a slice and return a cloned copy of each entry.
    pub fn from_entries(entries: &[DocEntry]) -> Self {
        let mut cat = Self::new();
        for e in entries {
            cat.add(e.clone());
        }
        cat
    }
    /// Append one entry to the catalog and return unit.
    pub fn add(&mut self, entry: DocEntry) {
        self.entries.push(entry);
    }
    /// Return sorted unique module names referenced by all stored entries.
    pub fn modules(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.entries.iter().map(|e| e.module.as_str()).collect();
        names.sort_unstable();
        names.dedup();
        names
    }
    /// Return an immutable slice of all entries in insertion order.
    pub fn all_entries(&self) -> &[DocEntry] {
        &self.entries
    }
    /// Return all entries that belong to the requested module name.
    pub fn entries_for_module(&self, module: &str) -> Vec<&DocEntry> {
        self.entries.iter().filter(|e| e.module == module).collect()
    }
    /// Return the entry matching a fully qualified name or None when missing.
    pub fn get_entry(&self, qualified_name: &str) -> Option<&DocEntry> {
        self.entries
            .iter()
            .find(|e| e.qualified_name == qualified_name)
    }
    /// Return the number of stored entries.
    pub fn entry_count(&self) -> usize {
        self.entries.len()
    }
    /// Return entries whose lowercase name or description contains the query.
    pub fn search(&self, query: &str) -> Vec<&DocEntry> {
        let q = query.to_lowercase();
        self.entries
            .iter()
            .filter(|e| {
                e.name.to_lowercase().contains(&q) || e.description.to_lowercase().contains(&q)
            })
            .collect()
    }
    /// Return entries with a kind exactly equal to the provided value.
    pub fn filter_by_kind(&self, kind: &str) -> Vec<&DocEntry> {
        self.entries.iter().filter(|e| e.kind == kind).collect()
    }
    /// Merge this catalog with another and return de-duplicated entries by qualified name.
    pub fn merge(&self, other: &Catalog) -> Catalog {
        let mut merged = self.entries.clone();
        for entry in &other.entries {
            if let Some(existing) = merged
                .iter_mut()
                .find(|candidate| candidate.qualified_name == entry.qualified_name)
            {
                *existing = entry.clone();
            } else {
                merged.push(entry.clone());
            }
        }
        Catalog { entries: merged }
    }
    /// Remove all stored entries and return unit.
    pub fn clear(&mut self) {
        self.entries.clear();
    }
}
/// Provide a default empty catalog for callers that rely on Default.
impl Default for Catalog {
    fn default() -> Self {
        Self::new()
    }
}
