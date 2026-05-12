//! Weighted random selector for loot, spawn tables, and probability-weighted choices.

/// A single entry in a weighted pool.
#[derive(Debug, Clone)]
pub struct WeightedEntry {
    /// Unique ID assigned when the entry is added.
    pub id: u64,
    /// Non-negative weight; higher weight means higher selection probability.
    pub weight: f64,
    /// Optional label for the entry.
    pub label: String,
}

/// A pool of weighted entries. Items are selected proportionally to their weight.
///
/// Weights must be non-negative. Entries with weight `0.0` are never selected.
#[derive(Debug, Clone)]
pub struct WeightedRandom {
    entries: Vec<WeightedEntry>,
    next_id: u64,
    /// Monotonic counter incremented on every structural change (add / remove / update weight).
    pub revision: u64,
}

impl WeightedRandom {
    /// Creates an empty [`WeightedRandom`] pool.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            next_id: 1,
            revision: 0,
        }
    }

    /// Adds an entry with the given weight and optional label.
    ///
    /// Returns the assigned entry ID.
    pub fn add(&mut self, weight: f64, label: &str) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        self.entries.push(WeightedEntry {
            id,
            weight: weight.max(0.0),
            label: label.to_string(),
        });
        self.revision += 1;
        id
    }

    /// Removes the entry with the given ID. Returns `true` when the entry was found and removed.
    pub fn remove(&mut self, id: u64) -> bool {
        if let Some(pos) = self.entries.iter().position(|e| e.id == id) {
            self.entries.swap_remove(pos);
            self.revision += 1;
            true
        } else {
            false
        }
    }

    /// Updates the weight of the entry with the given ID.
    /// Returns `true` when the entry was found.
    pub fn set_weight(&mut self, id: u64, weight: f64) -> bool {
        if let Some(e) = self.entries.iter_mut().find(|e| e.id == id) {
            e.weight = weight.max(0.0);
            self.revision += 1;
            true
        } else {
            false
        }
    }

    /// Returns the total sum of all entry weights.
    pub fn total_weight(&self) -> f64 {
        self.entries.iter().map(|e| e.weight).sum()
    }

    /// Selects one entry ID using a sample in `[0, 1)`.
    ///
    /// The caller must supply the random sample — this keeps the struct
    /// free of any RNG dependency and deterministic under replay.
    ///
    /// Returns `None` when the pool is empty or all weights are zero.
    pub fn pick(&self, sample: f64) -> Option<u64> {
        let total = self.total_weight();
        if total <= 0.0 {
            return None;
        }
        let target = (sample.clamp(0.0, 1.0) * total).min(total - f64::EPSILON);
        let mut acc = 0.0;
        for e in &self.entries {
            acc += e.weight;
            if target < acc {
                return Some(e.id);
            }
        }
        self.entries.last().map(|e| e.id)
    }

    /// Selects up to `count` distinct entry IDs without replacement.
    ///
    /// `samples` must have at least `count` values in `[0, 1)`.
    /// Returns as many IDs as possible (may be fewer than `count` if the pool is smaller).
    pub fn pick_n(&self, count: usize, samples: &[f64]) -> Vec<u64> {
        if count == 0 || self.entries.is_empty() {
            return Vec::new();
        }
        // Clone weights into a scratch buffer for removal-without-replacement.
        let mut scratch: Vec<(u64, f64)> = self.entries.iter().map(|e| (e.id, e.weight)).collect();
        let mut out = Vec::with_capacity(count.min(scratch.len()));
        for &s in samples.iter().take(count) {
            let total: f64 = scratch.iter().map(|(_, w)| w).sum();
            if total <= 0.0 {
                break;
            }
            let target = (s.clamp(0.0, 1.0) * total).min(total - f64::EPSILON);
            let mut acc = 0.0;
            let mut chosen = scratch.len() - 1;
            for (i, &(_, w)) in scratch.iter().enumerate() {
                acc += w;
                if target < acc {
                    chosen = i;
                    break;
                }
            }
            let (id, _) = scratch.swap_remove(chosen);
            out.push(id);
        }
        out
    }

    /// Returns a slice of all entries.
    pub fn entries(&self) -> &[WeightedEntry] {
        &self.entries
    }

    /// Returns the number of entries in the pool.
    pub fn len(&self) -> usize {
        self.entries.len()
    }

    /// Returns `true` when the pool has no entries.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Returns the entry for the given ID, or `None`.
    pub fn get(&self, id: u64) -> Option<&WeightedEntry> {
        self.entries.iter().find(|e| e.id == id)
    }

    /// Removes all entries.
    pub fn clear(&mut self) {
        self.entries.clear();
        self.revision += 1;
    }
}

impl Default for WeightedRandom {
    fn default() -> Self {
        Self::new()
    }
}
