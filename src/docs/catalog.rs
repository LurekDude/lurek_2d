use crate::docs::entry::DocEntry;
pub struct Catalog {
    entries: Vec<DocEntry>,
}
impl Catalog {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
        }
    }
    pub fn from_entries(entries: &[DocEntry]) -> Self {
        let mut cat = Self::new();
        for e in entries {
            cat.add(e.clone());
        }
        cat
    }
    pub fn add(&mut self, entry: DocEntry) {
        self.entries.push(entry);
    }
    pub fn modules(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.entries.iter().map(|e| e.module.as_str()).collect();
        names.sort_unstable();
        names.dedup();
        names
    }
    pub fn all_entries(&self) -> &[DocEntry] {
        &self.entries
    }
    pub fn entries_for_module(&self, module: &str) -> Vec<&DocEntry> {
        self.entries.iter().filter(|e| e.module == module).collect()
    }
    pub fn get_entry(&self, qualified_name: &str) -> Option<&DocEntry> {
        self.entries
            .iter()
            .find(|e| e.qualified_name == qualified_name)
    }
    pub fn entry_count(&self) -> usize {
        self.entries.len()
    }
    pub fn search(&self, query: &str) -> Vec<&DocEntry> {
        let q = query.to_lowercase();
        self.entries
            .iter()
            .filter(|e| {
                e.name.to_lowercase().contains(&q) || e.description.to_lowercase().contains(&q)
            })
            .collect()
    }
    pub fn filter_by_kind(&self, kind: &str) -> Vec<&DocEntry> {
        self.entries.iter().filter(|e| e.kind == kind).collect()
    }
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
    pub fn clear(&mut self) {
        self.entries.clear();
    }
}
impl Default for Catalog {
    fn default() -> Self {
        Self::new()
    }
}
