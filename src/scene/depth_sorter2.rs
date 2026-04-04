//! Per-frame depth-sorted draw batcher.
//!
//! This module is part of Luna2D's `scene` subsystem and provides the implementation
//! details for depth sorter-related operations and data management.
//! Key types exported from this module: `DepthEntry`, `DepthSorter`.
//! Primary functions: `new()`, `add()`, `add_object()`, `sort()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Entry in the depth-sorted draw queue. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `depth` — `f32`.
/// - `callback_index` — `usize`.
/// - `is_object` — `bool`.
pub struct DepthEntry {
    /// Depth value — lower values are drawn first.
    pub depth: f32,
    /// Index into an external callback storage (managed by Lua API layer).
    pub callback_index: usize,
    /// If true, the callback is an object with a `:drawSorted()` method.
    pub is_object: bool,
}

/// Per-frame depth-sorted draw batcher. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Collects draw callbacks with depth values, sorts them, and flushes
/// them in ascending depth order each frame.
///
/// # Fields
/// - `entries` — `Vec<DepthEntry>`.
pub struct DepthSorter {
    /// Pending draw entries.
    entries: Vec<DepthEntry>,
}

impl DepthSorter {
    /// Create a new empty depth sorter. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
        }
    }

    /// Add a callback at the given depth. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `callback_index` — `usize`.
    /// - `depth` — `f32`.
    pub fn add(&mut self, callback_index: usize, depth: f32) {
        self.entries.push(DepthEntry {
            depth,
            callback_index,
            is_object: false,
        });
    }

    /// Add an object with a `:drawSorted()` method at the given depth.
    ///
    /// # Parameters
    /// - `callback_index` — `usize`.
    /// - `depth` — `f32`.
    pub fn add_object(&mut self, callback_index: usize, depth: f32) {
        self.entries.push(DepthEntry {
            depth,
            callback_index,
            is_object: true,
        });
    }

    /// Sort entries by depth ascending (lower depth = drawn first). Does NOT call or clear.
    pub fn sort(&mut self) {
        self.entries.sort_by(|a, b| {
            a.depth
                .partial_cmp(&b.depth)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
    }

    /// Get the sorted entries for external processing (sort + return refs).
    ///
    /// # Returns
    /// `&[DepthEntry]`.
    pub fn sorted_entries(&mut self) -> &[DepthEntry] {
        self.sort();
        &self.entries
    }

    /// Clear all entries without calling them. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.entries.clear();
    }

    /// Number of queued entries. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_count(&self) -> usize {
        self.entries.len()
    }
}

impl Default for DepthSorter {
    fn default() -> Self {
        Self::new()
    }
}
