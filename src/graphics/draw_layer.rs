//! Z-ordered draw layer for controlling render order.
//!
//! Entries are queued with a z-order value and flushed in ascending order
//! so that lower z-values are drawn first (back-to-front).

/// A queued draw entry with its z-order.
pub struct LayerEntry {
    /// Sorting key — lower values draw first.
    pub z_order: f64,
    /// Opaque handle used by the caller to identify the associated callback.
    pub callback_id: usize,
}

/// Z-ordered draw callback queue.
///
/// Collects entries during the draw phase and flushes them in z-order
/// so that rendering happens back-to-front.
pub struct DrawLayer {
    /// Pending entries waiting to be flushed.
    entries: Vec<LayerEntry>,
    /// Monotonically increasing ID counter.
    next_id: usize,
}

impl DrawLayer {
    /// Creates an empty draw layer.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            next_id: 0,
        }
    }

    /// Queues an entry with the given z-order.
    ///
    /// Returns a unique `callback_id` that the caller can use to associate
    /// a draw callback with this entry.
    pub fn queue(&mut self, z_order: f64) -> usize {
        let id = self.next_id;
        self.next_id += 1;
        self.entries.push(LayerEntry {
            z_order,
            callback_id: id,
        });
        id
    }

    /// Sorts entries by z-order ascending and drains the queue.
    ///
    /// Returns all entries in draw order. The internal list is left empty.
    pub fn flush(&mut self) -> Vec<LayerEntry> {
        self.entries.sort_by(|a, b| {
            a.z_order
                .partial_cmp(&b.z_order)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        std::mem::take(&mut self.entries)
    }

    /// Discards all queued entries.
    pub fn clear(&mut self) {
        self.entries.clear();
    }

    /// Returns the number of queued entries.
    pub fn get_count(&self) -> usize {
        self.entries.len()
    }
}

impl Default for DrawLayer {
    fn default() -> Self {
        Self::new()
    }
}
