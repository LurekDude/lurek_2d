//! Fixed-capacity ring buffer storing numeric or string entries with tags.
//! When full, the oldest entry is evicted on push. Supports sum and average over numeric entries.

use std::collections::VecDeque;

/// Fixed-capacity ring buffer of `RingEntry` values.
#[derive(Debug)]
pub struct Ring {
    /// Debug name.
    pub name: String,
    /// Maximum number of entries; always >= 1.
    pub capacity: usize,
    /// Circular entry storage.
    entries: VecDeque<RingEntry>,
    /// Next entry id to assign.
    next_id: u64,
    /// Monotonically increasing count of all pushes including evicted entries.
    pub total_pushed: u64,
}
/// A single entry in a `Ring`.
#[derive(Debug, Clone)]
pub struct RingEntry {
    /// Unique entry id.
    pub id: u64,
    /// Numeric value when the entry holds a number.
    pub value_f64: Option<f64>,
    /// String value when the entry holds text.
    pub value_str: Option<String>,
    /// Caller-assigned tag.
    pub tag: String,
}
/// All methods for `Ring`.
impl Ring {
    /// Create a ring buffer named `name` with `capacity` (clamped to minimum 1).
    pub fn new(name: &str, capacity: usize) -> Self {
        Self {
            name: name.to_string(),
            capacity: capacity.max(1),
            entries: VecDeque::with_capacity(capacity.max(1)),
            next_id: 1,
            total_pushed: 0,
        }
    }
    /// Push a numeric entry with `tag`; evict oldest when full; return entry id.
    pub fn push_number(&mut self, value: f64, tag: &str) -> u64 {
        self.push_entry(Some(value), None, tag)
    }
    /// Push a string entry with `tag`; evict oldest when full; return entry id.
    pub fn push_string(&mut self, value: String, tag: &str) -> u64 {
        self.push_entry(None, Some(value), tag)
    }
    /// Internal helper that inserts a new entry, evicting the front when at capacity.
    fn push_entry(&mut self, vf: Option<f64>, vs: Option<String>, tag: &str) -> u64 {
        if self.entries.len() >= self.capacity {
            self.entries.pop_front();
        }
        let id = self.next_id;
        self.next_id += 1;
        self.total_pushed += 1;
        self.entries.push_back(RingEntry {
            id,
            value_f64: vf,
            value_str: vs,
            tag: tag.to_string(),
        });
        id
    }
    /// Return an iterator over all entries from oldest to newest.
    pub fn iter(&self) -> impl Iterator<Item = &RingEntry> {
        self.entries.iter()
    }
    /// Return the most recently pushed entry.
    pub fn latest(&self) -> Option<&RingEntry> {
        self.entries.back()
    }
    /// Return the oldest entry still in the buffer.
    pub fn oldest(&self) -> Option<&RingEntry> {
        self.entries.front()
    }
    /// Return the current number of entries.
    pub fn len(&self) -> usize {
        self.entries.len()
    }
    /// Return true when the buffer holds no entries.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
    /// Return true when the buffer has reached capacity.
    pub fn is_full(&self) -> bool {
        self.entries.len() >= self.capacity
    }
    /// Remove all entries.
    pub fn clear(&mut self) {
        self.entries.clear();
    }
    /// Return the sum of all numeric entries; non-numeric entries are ignored.
    pub fn sum(&self) -> f64 {
        self.entries.iter().filter_map(|e| e.value_f64).sum()
    }
    /// Return the arithmetic mean of all numeric entries; return `0.0` when none exist.
    pub fn average(&self) -> f64 {
        let nums: Vec<f64> = self.entries.iter().filter_map(|e| e.value_f64).collect();
        if nums.is_empty() {
            0.0
        } else {
            nums.iter().sum::<f64>() / nums.len() as f64
        }
    }
}
