//! Weighted item-type pool for random selection.
//!
//! An `ItemPool` holds a set of item type names each with a relative draw
//! weight.  Useful for loot tables, draft formats, booster generation, or any
//! weighted-random-choice scenario.

use crate::item::item::Item;

/// A single entry in an item pool. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `type_name` — `String`.
/// - `weight` — `u32`.
#[derive(Debug, Clone)]
pub struct PoolEntry {
    /// Item type identifier.
    pub type_name: String,
    /// Relative draw weight (minimum 1).
    pub weight: u32,
}

/// A pool of item types for weighted random draws.
///
/// # Fields
/// - `name` — `String`.
/// - `entries` — `Vec<PoolEntry>`.
#[derive(Debug, Clone)]
pub struct ItemPool {
    /// Pool name.
    pub name: String,
    /// Weighted entries.
    pub entries: Vec<PoolEntry>,
}

impl ItemPool {
    /// Create an empty item pool. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), entries: Vec::new() }
    }

    /// Add a type with the given weight (clamped to minimum 1).
    ///
    /// # Parameters
    /// - `ype_name` — `impl Into<String>`.
    /// - `weight` — `u32`.
    pub fn add(&mut self, type_name: impl Into<String>, weight: u32) {
        self.entries.push(PoolEntry { type_name: type_name.into(), weight: weight.max(1) });
    }

    /// Remove all entries for `type_name`. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `ype_name` — `&str`.
    pub fn remove(&mut self, type_name: &str) {
        self.entries.retain(|e| e.type_name != type_name);
    }

    /// Set the weight for an existing entry.  No-op if not found.
    ///
    /// # Parameters
    /// - `ype_name` — `&str`.
    /// - `weight` — `u32`.
    pub fn set_weight(&mut self, type_name: &str, weight: u32) {
        if let Some(e) = self.entries.iter_mut().find(|e| e.type_name == type_name) {
            e.weight = weight.max(1);
        }
    }

    /// Sum of all entry weights. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u64`.
    pub fn total_weight(&self) -> u64 {
        self.entries.iter().map(|e| e.weight as u64).sum()
    }

    /// Number of distinct entries in the pool. Runs in O(1) time.
    ///
    /// # Returns
    /// `usize`.
    pub fn size(&self) -> usize {
        self.entries.len()
    }

    /// Returns `true` if the pool has no entries.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    // ── Draw ──────────────────────────────────────────────────────────────────

    /// Draw `n` type names **with replacement** according to weights.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn draw_types(&self, n: usize) -> Vec<String> {
        if self.entries.is_empty() { return Vec::new(); }
        let total = self.total_weight();
        (0..n).map(|_| {
            let mut roll = fastrand::u64(0..total);
            let mut chosen = self.entries.last().unwrap().type_name.clone();
            for e in &self.entries {
                if roll < e.weight as u64 {
                    chosen = e.type_name.clone();
                    break;
                }
                roll -= e.weight as u64;
            }
            chosen
        }).collect()
    }

    /// Draw `n` type names **without replacement**.  Returns at most `entries.len()` results.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn draw_unique_types(&self, n: usize) -> Vec<String> {
        let mut pool: Vec<PoolEntry> = self.entries.clone();
        let mut results = Vec::new();
        for _ in 0..n {
            if pool.is_empty() { break; }
            let total: u64 = pool.iter().map(|e| e.weight as u64).sum();
            let mut roll = fastrand::u64(0..total);
            let mut chosen_idx = pool.len() - 1;
            for (i, e) in pool.iter().enumerate() {
                if roll < e.weight as u64 { chosen_idx = i; break; }
                roll -= e.weight as u64;
            }
            results.push(pool.remove(chosen_idx).type_name);
        }
        results
    }

    /// Draw `n` item instances (with replacement) — convenience wrapper that calls `Item::new`.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<Item>`.
    pub fn draw_items(&self, n: usize) -> Vec<Item> {
        self.draw_types(n).into_iter().map(Item::new).collect()
    }

    /// Draw `n` item instances without replacement.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<Item>`.
    pub fn draw_unique_items(&self, n: usize) -> Vec<Item> {
        self.draw_unique_types(n).into_iter().map(Item::new).collect()
    }
}
