//! Per-frame depth-sorted draw batcher.

/// Entry in the depth-sorted draw queue.
pub struct DepthEntry {
    /// Depth value — lower values are drawn first.
    pub depth: f32,
    /// Index into an external callback storage (managed by Lua API layer).
    pub callback_index: usize,
    /// If true, the callback is an object with a `:drawSorted()` method.
    pub is_object: bool,
}

/// Per-frame depth-sorted draw batcher.
///
/// Collects draw callbacks with depth values, sorts them, and flushes
/// them in ascending depth order each frame.
pub struct DepthSorter {
    /// Pending draw entries.
    entries: Vec<DepthEntry>,
}

impl DepthSorter {
    /// Create a new empty depth sorter.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
        }
    }

    /// Add a callback at the given depth.
    pub fn add(&mut self, callback_index: usize, depth: f32) {
        self.entries.push(DepthEntry {
            depth,
            callback_index,
            is_object: false,
        });
    }

    /// Add an object with a `:drawSorted()` method at the given depth.
    pub fn add_object(&mut self, callback_index: usize, depth: f32) {
        self.entries.push(DepthEntry {
            depth,
            callback_index,
            is_object: true,
        });
    }

    /// Sort entries by depth ascending (lower depth = drawn first). Does NOT call or clear.
    pub fn sort(&mut self) {
        self.entries
            .sort_by(|a, b| a.depth.partial_cmp(&b.depth).unwrap_or(std::cmp::Ordering::Equal));
    }

    /// Get the sorted entries for external processing (sort + return refs).
    pub fn sorted_entries(&mut self) -> &[DepthEntry] {
        self.sort();
        &self.entries
    }

    /// Clear all entries without calling them.
    pub fn clear(&mut self) {
        self.entries.clear();
    }

    /// Number of queued entries.
    pub fn get_count(&self) -> usize {
        self.entries.len()
    }
}

impl Default for DepthSorter {
    fn default() -> Self {
        Self::new()
    }
}
