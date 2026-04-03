//! Weighted item-type pool for random selection.
//!
//! An `CardPool` holds a set of card type names each with a relative draw
//! weight.  Useful for loot tables, draft formats, booster generation, or any
//! weighted-random-choice scenario.

use crate::cardgame::card::Card;

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

/// A pool of card types for weighted random draws.
///
/// # Fields
/// - `name` — `String`.
/// - `entries` — `Vec<PoolEntry>`.
/// - `rarity_weights` — `std::collections::HashMap<String`.
#[derive(Debug, Clone)]
pub struct CardPool {
    /// Pool name.
    pub name: String,
    /// Weighted entries.
    pub entries: Vec<PoolEntry>,
    /// Per-rarity draw weights for `draw_by_rarity`.
    pub rarity_weights: std::collections::HashMap<String, u32>,
}

impl CardPool {
    /// Create an empty item pool. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), entries: Vec::new(), rarity_weights: std::collections::HashMap::new() }
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

    /// Draw `n` item instances (with replacement) — convenience wrapper that calls `Card::new`.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<Card>`.
    pub fn draw_items(&self, n: usize) -> Vec<Card> {
        self.draw_types(n).into_iter().map(Card::new).collect()
    }

    /// Draw `n` item instances without replacement.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<Card>`.
    pub fn draw_unique_items(&self, n: usize) -> Vec<Card> {
        self.draw_unique_types(n).into_iter().map(Card::new).collect()
    }

    /// Rename this pool. Replaces the current name value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    pub fn set_name(&mut self, name: impl Into<String>) {
        self.name = name.into();
    }

    /// Get the weight for a specific type (0 if not found).
    ///
    /// # Parameters
    /// - `ype_name` — `&str`.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_weight(&self, type_name: &str) -> u32 {
        self.entries.iter().find(|e| e.type_name == type_name).map(|e| e.weight).unwrap_or(0)
    }

    /// Get all type names in the pool. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_type_names(&self) -> Vec<String> {
        self.entries.iter().map(|e| e.type_name.clone()).collect()
    }

    /// Set the draw weight for a rarity tier.
    ///
    /// # Parameters
    /// - `rarity` — `impl Into<String>`.
    /// - `weight` — `u32`.
    pub fn set_rarity_weight(&mut self, rarity: impl Into<String>, weight: u32) {
        self.rarity_weights.insert(rarity.into(), weight.max(1));
    }

    /// Draw `n` items using a seeded random (for reproducibility).
    ///
    /// # Parameters
    /// - `n` — `usize`.
    /// - `seed` — `u64`.
    ///
    /// # Returns
    /// `Vec<Card>`.
    pub fn draw_items_seeded(&self, n: usize, seed: u64) -> Vec<Card> {
        fastrand::seed(seed);
        self.draw_items(n)
    }

    /// Draw cards according to a rarity distribution.
    ///
    /// `distribution` maps rarity name → count.  Cards are drawn from the pool
    /// filtered by rarity, using `draw_unique_types` within each rarity.
    ///
    /// # Parameters
    /// - `distribution` — `&std::collections::HashMap<String`.
    ///
    /// # Returns
    /// `Vec<Card>`.
    pub fn draw_by_rarity(&self, distribution: &std::collections::HashMap<String, usize>) -> Vec<Card> {
        use crate::cardgame::card::get_card_type;
        let mut results = Vec::new();
        for (rarity, &count) in distribution {
            // Build a temporary sub-pool of entries whose type has this rarity
            let sub_entries: Vec<PoolEntry> = self.entries.iter().filter_map(|e| {
                let def = get_card_type(&e.type_name)?;
                if &def.rarity == rarity {
                    Some(e.clone())
                } else {
                    None
                }
            }).collect();

            if sub_entries.is_empty() {
                continue;
            }

            let sub_pool = CardPool {
                name: String::new(),
                entries: sub_entries,
                rarity_weights: std::collections::HashMap::new(),
            };
            results.extend(sub_pool.draw_items(count));
        }
        results
    }
}
