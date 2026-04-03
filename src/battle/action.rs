//! CombatAction: named attack or skill with cooldown, cost, and accuracy.
//!
//! This module is part of Luna2D's `battle` subsystem and provides the implementation
//! details for action-related operations and data management.
//! Key types exported from this module: `CombatAction`.
//! Primary functions: `new()`, `is_ready()`, `use_action()`, `tick_cooldown()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

/// A turn-based combat action that a combatant can take.
///
/// Represents an attack, skill, or ability with damage type, base damage,
/// accuracy, cooldown, resource costs, and arbitrary tag/metadata. Actions
/// are stored on `Combatant` instances and resolved by `CombatBattle`.
///
/// # Fields
/// - `name` — `String`.
/// - `damage_type` — `String`.
/// - `base_damage` — `f64`.
/// - `accuracy` — `f64`.
/// - `cooldown` — `u32`.
/// - `current_cooldown` — `u32`.
/// - `cost_hp` — `f64`.
/// - `cost_mp` — `f64`.
/// - `tags` — `Vec<String>`.
/// - `metadata` — `HashMap<String, String>`.
#[derive(Debug, Clone)]
pub struct CombatAction {
    pub name: String,
    pub damage_type: String,
    pub base_damage: f64,
    pub accuracy: f64,
    pub cooldown: u32,
    pub current_cooldown: u32,
    pub cost_hp: f64,
    pub cost_mp: f64,
    pub tags: Vec<String>,
    pub metadata: HashMap<String, String>,
}

impl CombatAction {
    /// Creates a new action with sensible turn-based defaults.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            damage_type: "physical".to_string(),
            base_damage: 0.0,
            accuracy: 1.0,
            cooldown: 0,
            current_cooldown: 0,
            cost_hp: 0.0,
            cost_mp: 0.0,
            tags: Vec::new(),
            metadata: HashMap::new(),
        }
    }

    /// Returns true when the action is not on cooldown.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_ready(&self) -> bool {
        self.current_cooldown == 0
    }

    /// Consumes the action and starts its cooldown timer.
    pub fn use_action(&mut self) {
        self.current_cooldown = self.cooldown;
    }

    /// Ticks the current cooldown down by one turn.
    pub fn tick_cooldown(&mut self) {
        if self.current_cooldown > 0 {
            self.current_cooldown -= 1;
        }
    }
}
