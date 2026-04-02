//! Generic player model.
//!
//! A player owns resources (user-defined named pools), a score, and arbitrary
//! status/metadata.  The engine attaches no meaning to resource names or
//! status values — those are entirely game-designer defined.

use std::collections::HashMap;

/// A single participant in a card game.
///
/// All numeric fields (score, resources) are fully generic.  The game
/// designer decides what `"mana"`, `"chips"`, `"vp"`, etc. mean.
#[derive(Debug, Clone)]
pub struct Player {
    /// Unique player identifier.
    pub id: String,
    /// Display name.
    pub name: String,
    /// Accumulated score (`f64` to support fractional scoring).
    pub score: f64,
    /// Named resource pools (user-defined, e.g. `"mana"`, `"gold"`, `"chips"`).
    pub resources: HashMap<String, f64>,
    /// Arbitrary status string — user-defined (e.g. `"active"`, `"eliminated"`, `"passing"`).
    pub status: String,
    /// Arbitrary string metadata.
    pub metadata: HashMap<String, String>,
}

impl Player {
    /// Create a new player with the given ID.  The display name defaults to the ID.
    pub fn new(id: impl Into<String>) -> Self {
        let id = id.into();
        Self {
            name: id.clone(),
            id,
            score: 0.0,
            resources: HashMap::new(),
            status: String::new(),
            metadata: HashMap::new(),
        }
    }

    /// Create a player with separate ID and display name.
    pub fn with_name(id: impl Into<String>, name: impl Into<String>) -> Self {
        let mut p = Self::new(id);
        p.name = name.into();
        p
    }

    // ── Score ────────────────────────────────────────────────────────────────

    /// Add `delta` to the player's score and return the new total.
    pub fn add_score(&mut self, delta: f64) -> f64 {
        self.score += delta;
        self.score
    }

    /// Set the player's score directly.
    pub fn set_score(&mut self, score: f64) {
        self.score = score;
    }

    // ── Resources ────────────────────────────────────────────────────────────

    /// Get the current value of a named resource (`0.0` if not set).
    pub fn get_resource(&self, key: &str) -> f64 {
        *self.resources.get(key).unwrap_or(&0.0)
    }

    /// Set a named resource to an exact value.
    pub fn set_resource(&mut self, key: impl Into<String>, amount: f64) {
        self.resources.insert(key.into(), amount);
    }

    /// Add `amount` to a named resource and return the new value.
    pub fn add_resource(&mut self, key: impl Into<String>, amount: f64) -> f64 {
        let k = key.into();
        let v = self.resources.entry(k).or_insert(0.0);
        *v += amount;
        *v
    }

    /// Spend `amount` from a named resource.
    ///
    /// Returns `Ok(remaining)` on success, or `Err` if insufficient funds.
    pub fn spend_resource(&mut self, key: &str, amount: f64) -> Result<f64, String> {
        let v = self.resources.entry(key.to_owned()).or_insert(0.0);
        if *v < amount {
            return Err(format!(
                "Insufficient '{}': need {}, have {}",
                key, amount, v
            ));
        }
        *v -= amount;
        Ok(*v)
    }

    /// Return all (resource_name, amount) pairs.
    pub fn get_all_resources(&self) -> Vec<(String, f64)> {
        self.resources.iter().map(|(k, v)| (k.clone(), *v)).collect()
    }

    // ── Metadata ─────────────────────────────────────────────────────────────

    /// Get a metadata string value.
    pub fn get_meta(&self, key: &str) -> Option<&str> {
        self.metadata.get(key).map(String::as_str)
    }

    /// Set a metadata string value.
    pub fn set_meta(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.metadata.insert(key.into(), value.into());
    }
}
