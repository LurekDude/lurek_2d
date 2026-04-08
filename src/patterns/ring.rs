//! Fixed-capacity circular buffer (ring buffer) for history tracking.
//!
//! [`Ring`] stores at most `capacity` values, automatically overwriting the
//! oldest entry when full. Useful for combo detection, damage number histories,
//! rolling input buffers, and recent-action logs in game code.

use std::collections::VecDeque;

// ── Ring ──────────────────────────────────────────────────────────────────

/// Fixed-capacity circular value ring.
///
/// Values are appended with [`push`][Ring::push]. When the ring is full the
/// oldest element is silently dropped. Item ids are monotonically assigned
/// for stable external references.
///
/// # Fields
/// - `name` — `String`.
/// - `capacity` — `usize`.
#[derive(Debug)]
pub struct Ring {
    /// Display name.
    pub name: String,
    /// Maximum number of entries retained.
    pub capacity: usize,
    entries: VecDeque<RingEntry>,
    next_id: u64,
    /// Total number of items ever pushed (including overwritten ones).
    pub total_pushed: u64,
}

/// A single entry in a [`Ring`].
///
/// # Fields
/// - `id` — `u64`.
/// - `value_f64` — `Option<f64>`.
/// - `value_str` — `Option<String>`.
/// - `tag` — `String`.
#[derive(Debug, Clone)]
pub struct RingEntry {
    /// Monotonic insertion id.
    pub id: u64,
    /// Numeric payload (if any).
    pub value_f64: Option<f64>,
    /// String payload (if any).
    pub value_str: Option<String>,
    /// Free-form tag label.
    pub tag: String,
}

impl Ring {
    /// Creates a new ring buffer with the given capacity.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `capacity` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str, capacity: usize) -> Self {
        Self {
            name: name.to_string(),
            capacity: capacity.max(1),
            entries: VecDeque::with_capacity(capacity.max(1)),
            next_id: 1,
            total_pushed: 0,
        }
    }

    /// Pushes a numeric entry. Oldest entry is dropped when at capacity.
    ///
    /// # Parameters
    /// - `value` — `f64`.
    /// - `tag` — `&str`.
    ///
    /// # Returns
    /// `u64`.
    pub fn push_number(&mut self, value: f64, tag: &str) -> u64 {
        self.push_entry(Some(value), None, tag)
    }

    /// Pushes a string entry. Oldest entry is dropped when at capacity.
    ///
    /// # Parameters
    /// - `value` — `String`.
    /// - `tag` — `&str`.
    ///
    /// # Returns
    /// `u64`.
    pub fn push_string(&mut self, value: String, tag: &str) -> u64 {
        self.push_entry(None, Some(value), tag)
    }

    fn push_entry(&mut self, vf: Option<f64>, vs: Option<String>, tag: &str) -> u64 {
        if self.entries.len() >= self.capacity {
            self.entries.pop_front();
        }
        let id = self.next_id;
        self.next_id += 1;
        self.total_pushed += 1;
        self.entries.push_back(RingEntry { id, value_f64: vf, value_str: vs, tag: tag.to_string() });
        id
    }

    /// Returns all entries from oldest to newest.
    ///
    /// # Returns
    /// `impl Iterator<Item = &RingEntry>`.
    pub fn iter(&self) -> impl Iterator<Item = &RingEntry> {
        self.entries.iter()
    }

    /// Returns the most-recently pushed entry.
    ///
    /// # Returns
    /// `Option<&RingEntry>`.
    pub fn latest(&self) -> Option<&RingEntry> {
        self.entries.back()
    }

    /// Returns the oldest retained entry.
    ///
    /// # Returns
    /// `Option<&RingEntry>`.
    pub fn oldest(&self) -> Option<&RingEntry> {
        self.entries.front()
    }

    /// Number of entries currently held.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.entries.len()
    }

    /// Returns `true` when the ring contains no entries.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Returns `true` when the ring is at capacity.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_full(&self) -> bool {
        self.entries.len() >= self.capacity
    }

    /// Clears all entries (does not reset id counter).
    pub fn clear(&mut self) {
        self.entries.clear();
    }

    /// Sum of all numeric values in the ring.
    ///
    /// # Returns
    /// `f64`.
    pub fn sum(&self) -> f64 {
        self.entries.iter().filter_map(|e| e.value_f64).sum()
    }

    /// Average of all numeric values, or `0` when empty.
    ///
    /// # Returns
    /// `f64`.
    pub fn average(&self) -> f64 {
        let nums: Vec<f64> = self.entries.iter().filter_map(|e| e.value_f64).collect();
        if nums.is_empty() { 0.0 } else { nums.iter().sum::<f64>() / nums.len() as f64 }
    }
}
