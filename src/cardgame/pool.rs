//! Weighted card pool for drafting and booster-pack generation.

/// A single entry in a card pool.
#[derive(Debug, Clone)]
pub struct CardPoolEntry {
    /// Card type identifier.
    pub card_type: String,
    /// Relative draw weight (minimum 1).
    pub weight: u32,
}

/// A pool of card types for weighted random draws.
///
/// Useful for booster packs, loot drops, and draft formats.
#[derive(Debug, Clone)]
pub struct CardPool {
    /// Pool name.
    pub name: String,
    /// Weighted entries.
    pub entries: Vec<CardPoolEntry>,
}

impl CardPool {
    /// Create an empty card pool.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), entries: Vec::new() }
    }

    /// Add a card type with a given weight (minimum 1).
    pub fn add(&mut self, card_type: impl Into<String>, weight: u32) {
        self.entries.push(CardPoolEntry {
            card_type: card_type.into(),
            weight: weight.max(1),
        });
    }

    /// Remove all entries for `card_type`.
    pub fn remove(&mut self, card_type: &str) {
        self.entries.retain(|e| e.card_type != card_type);
    }

    /// Set the weight of an existing entry (no-op if not found).
    pub fn set_weight(&mut self, card_type: &str, weight: u32) {
        if let Some(e) = self.entries.iter_mut().find(|e| e.card_type == card_type) {
            e.weight = weight.max(1);
        }
    }

    /// Sum of all entry weights.
    pub fn total_weight(&self) -> u64 {
        self.entries.iter().map(|e| e.weight as u64).sum()
    }

    /// Draw `n` card types (with replacement) according to their weights.
    pub fn draw(&self, n: usize) -> Vec<String> {
        if self.entries.is_empty() {
            return Vec::new();
        }
        let total = self.total_weight();
        (0..n)
            .map(|_| {
                let mut roll = fastrand::u64(0..total);
                let mut chosen = self.entries.last().unwrap().card_type.clone();
                for e in &self.entries {
                    if roll < e.weight as u64 {
                        chosen = e.card_type.clone();
                        break;
                    }
                    roll -= e.weight as u64;
                }
                chosen
            })
            .collect()
    }

    /// Draw `n` card types **without** replacement.
    ///
    /// Returns at most `entries.len()` results.
    pub fn draw_unique(&self, n: usize) -> Vec<String> {
        let mut pool: Vec<CardPoolEntry> = self.entries.clone();
        let mut result = Vec::new();
        for _ in 0..n {
            let total: u64 = pool.iter().map(|e| e.weight as u64).sum();
            if total == 0 {
                break;
            }
            let mut roll = fastrand::u64(0..total);
            let mut chosen_idx = pool.len() - 1;
            for (i, e) in pool.iter().enumerate() {
                if roll < e.weight as u64 {
                    chosen_idx = i;
                    break;
                }
                roll -= e.weight as u64;
            }
            result.push(pool.remove(chosen_idx).card_type);
        }
        result
    }

    /// Number of entries.
    pub fn size(&self) -> usize {
        self.entries.len()
    }

    /// Returns `true` if the pool has no entries.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Return all registered card type strings.
    pub fn get_types(&self) -> Vec<String> {
        self.entries.iter().map(|e| e.card_type.clone()).collect()
    }
}
