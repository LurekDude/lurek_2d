//! Weighted modifier pools for random item property rolls (Path of Exile / Minecraft Enchanting pattern).
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for modifier pool-related operations and data management.
//! Key types exported from this module: `ModifierEntry`, `ModifierPool`.
//! Primary functions: `new()`, `new()`, `add_modifier()`, `remove_modifier()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

/// A single weighted entry in a modifier pool.
///
/// # Fields
/// - `name`: Stable modifier name.
/// - `weight`: Relative roll weight used during weighted selection.
/// - `effects`: Numeric effect values applied when the modifier is chosen.
#[derive(Debug, Clone)]
pub struct ModifierEntry {
    /// Unique name for this modifier.
    pub name: String,
    /// Relative weight for random selection. Higher = more likely.
    pub weight: f64,
    /// Named numeric effects produced when this modifier is rolled.
    pub effects: HashMap<String, f64>,
}

impl ModifierEntry {
    /// Create a modifier entry with the given name and weight; effects may be added after.
    ///
    /// # Parameters
    /// - `name`: Stable modifier name.
    /// - `weight`: Relative selection weight.
    ///
    /// # Returns
    /// A modifier entry with an empty effects map.
    pub fn new(name: impl Into<String>, weight: f64) -> Self {
        Self { name: name.into(), weight, effects: HashMap::new() }
    }
}

/// A named pool of weighted modifiers that can be rolled to produce random item properties.
///
/// # Fields
/// - `name`: Display name for the pool.
/// - `entries`: Weighted modifier entries considered during rolls.
#[derive(Debug, Default, Clone)]
pub struct ModifierPool {
    /// Display name for this pool.
    pub name: String,
    entries: Vec<ModifierEntry>,
}

impl ModifierPool {
    /// Create an empty modifier pool with the given name.
    ///
    /// # Parameters
    /// - `name`: Display name for the pool.
    ///
    /// # Returns
    /// An empty modifier pool.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), entries: Vec::new() }
    }

    /// Add a modifier to the pool with a name, weight, and effects map.
    ///
    /// # Parameters
    /// - `name`: Stable modifier name.
    /// - `weight`: Relative selection weight.
    /// - `effects`: Numeric effect map applied when the modifier is rolled.
    pub fn add_modifier(
        &mut self,
        name: impl Into<String>,
        weight: f64,
        effects: HashMap<String, f64>,
    ) {
        self.entries.push(ModifierEntry { name: name.into(), weight, effects });
    }

    /// Remove the modifier with the given name. Returns `true` if it existed.
    ///
    /// # Parameters
    /// - `name`: Modifier name to remove.
    ///
    /// # Returns
    /// `true` if an entry with that name was present.
    pub fn remove_modifier(&mut self, name: &str) -> bool {
        let before = self.entries.len();
        self.entries.retain(|e| e.name != name);
        self.entries.len() < before
    }

    /// Sum of all entry weights. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// The total weight across every entry in the pool.
    pub fn get_total_weight(&self) -> f64 {
        self.entries.iter().map(|e| e.weight).sum()
    }

    /// Returns a read-only slice of all entries.
    ///
    /// # Returns
    /// A slice containing every modifier entry in insertion order.
    pub fn get_modifiers(&self) -> &[ModifierEntry] { &self.entries }

    /// Returns the number of entries in the pool.
    ///
    /// # Returns
    /// The number of weighted entries stored in the pool.
    pub fn count(&self) -> usize { self.entries.len() }

    /// Roll a random modifier using `seed` as a deterministic source.
    ///
    /// # Parameters
    /// - `seed`: Deterministic seed used by the internal LCG.
    ///
    /// # Returns
    /// The chosen modifier entry, or `None` if the pool is empty or has no positive weight.
    pub fn roll(&self, seed: u64) -> Option<&ModifierEntry> {
        if self.entries.is_empty() { return None; }
        let total = self.get_total_weight();
        if total <= 0.0 { return None; }
        // Deterministic LCG derive a value in [0, 1).
        let r = seed
            .wrapping_mul(6_364_136_223_846_793_005)
            .wrapping_add(1_442_695_040_888_963_407);
        let frac = ((r >> 33) as f64) / (u32::MAX as f64 + 1.0);
        let target = frac * total;
        let mut cumulative = 0.0;
        for entry in &self.entries {
            cumulative += entry.weight;
            if cumulative > target { return Some(entry); }
        }
        self.entries.last()
    }
}
