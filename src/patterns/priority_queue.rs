//! Priority-ordered task queue for turn-based and agenda-driven game systems.
//!
//! [`PriorityQueue`] stores items with numeric priorities. Higher priority values
//! are returned first. Items with equal priority are returned in insertion order
//! (stable).  The data structure is backed by a sorted insertion model so pops
//! are O(1) and pushes are O(n).  For queues larger than a few hundred entries
//! a binary-heap variant should be considered; game queues are typically small.

// ── PriorityItem ──────────────────────────────────────────────────────────

/// A single queued item record (payload stored in Lua API layer).
///
/// # Fields
/// - `id` — `u64`.
/// - `priority` — `i64`.
/// - `label` — `String`.
#[derive(Debug, Clone)]
pub struct PriorityItem {
    /// Unique stable id.
    pub id: u64,
    /// Numeric priority. Higher values are dequeued first.
    pub priority: i64,
    /// Optional human-readable label for debugging.
    pub label: String,
    /// Sequential insertion counter used to break priority ties (lower = older).
    pub seq: u64,
}

// ── PriorityQueue ─────────────────────────────────────────────────────────

/// Stable priority queue for game tasks, spells, turn orders, and agendas.
///
/// Items are kept in sorted order (descending priority, then ascending seq) so
/// `peek` and `pop` are O(1). Each push is O(n) insertion sort.
///
/// # Fields
/// - `name` — `String`.
#[derive(Debug)]
pub struct PriorityQueue {
    /// Display name for logging.
    pub name: String,
    next_id: u64,
    next_seq: u64,
    /// Sorted descending by (priority, seq) — index 0 is highest priority.
    items: Vec<PriorityItem>,
}

impl PriorityQueue {
    /// Creates an empty priority queue.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            next_id: 1,
            next_seq: 0,
            items: Vec::new(),
        }
    }

    /// Inserts an item with the given priority. Returns its unique id.
    ///
    /// # Parameters
    /// - `priority` — `i64`.
    /// - `label` — `&str`.
    ///
    /// # Returns
    /// `u64`.
    pub fn push(&mut self, priority: i64, label: &str) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        let seq = self.next_seq;
        self.next_seq += 1;
        let item = PriorityItem { id, priority, label: label.to_string(), seq };
        // Find insertion position to keep descending priority order (stable).
        let pos = self.items.partition_point(|x| {
            x.priority > priority || (x.priority == priority && x.seq < seq)
        });
        self.items.insert(pos, item);
        id
    }

    /// Returns a reference to the highest-priority item without removing it.
    ///
    /// # Returns
    /// `Option<&PriorityItem>`.
    pub fn peek(&self) -> Option<&PriorityItem> {
        self.items.first()
    }

    /// Removes and returns the highest-priority item id and priority.
    ///
    /// # Returns
    /// `Option<(u64, i64)>`.
    pub fn pop(&mut self) -> Option<(u64, i64)> {
        if self.items.is_empty() { return None; }
        let item = self.items.remove(0);
        Some((item.id, item.priority))
    }

    /// Removes the item with the given id. Returns `true` if it was found.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove(&mut self, id: u64) -> bool {
        let before = self.items.len();
        self.items.retain(|i| i.id != id);
        self.items.len() < before
    }

    /// Returns the number of items in the queue.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.items.len()
    }

    /// Returns `true` when the queue is empty.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }

    /// Returns all item records ordered by priority (highest first).
    ///
    /// # Returns
    /// `&[PriorityItem]`.
    pub fn items(&self) -> &[PriorityItem] {
        &self.items
    }

    /// Removes all items.
    pub fn clear(&mut self) {
        self.items.clear();
    }
}
