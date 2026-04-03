//! Combatant: a single participant in a turn-based battle with HP, MP, statuses, and actions.
//!
//! This module is part of Luna2D's `battle` subsystem and provides the implementation
//! details for combatant-related operations and data management.
//! Key types exported from this module: `Combatant`.
//! Primary functions: `new()`, `is_alive()`, `take_damage()`, `heal()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

use crate::battle::action::CombatAction;
use crate::battle::types::StatusEffect;

/// A participant in turn-based battle. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Holds HP/MP pools, speed (used for turn ordering), level, team affiliation,
/// elemental resistances, active status effects, and a list of available
/// `CombatAction` instances. Combatants are managed by `CombatBattle` and
/// their field values are accessible from Lua via `luna.battle.*`.
///
/// # Fields
/// - `name` — `String`.
/// - `team` — `String`.
/// - `hp` — `f64`.
/// - `max_hp` — `f64`.
/// - `mp` — `f64`.
/// - `max_mp` — `f64`.
/// - `speed` — `f64`.
/// - `level` — `u32`.
/// - `alive` — `bool`.
/// - `stats` — `HashMap<String, f64>`.
/// - `resistances` — `HashMap<String, f64>`.
/// - `status_effects` — `Vec<StatusEffect>`.
/// - `actions` — `Vec<CombatAction>`.
/// - `metadata` — `HashMap<String, String>`.
#[derive(Debug, Clone)]
pub struct Combatant {
    pub name: String,
    pub team: String,
    pub hp: f64,
    pub max_hp: f64,
    pub mp: f64,
    pub max_mp: f64,
    pub speed: f64,
    pub level: u32,
    pub alive: bool,
    pub stats: HashMap<String, f64>,
    pub resistances: HashMap<String, f64>,
    pub status_effects: Vec<StatusEffect>,
    pub actions: Vec<CombatAction>,
    pub metadata: HashMap<String, String>,
}

impl Combatant {
    /// Creates a combatant with default HP, MP, speed, and no actions.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            team: "player".to_string(),
            hp: 100.0,
            max_hp: 100.0,
            mp: 50.0,
            max_mp: 50.0,
            speed: 10.0,
            level: 1,
            alive: true,
            stats: HashMap::new(),
            resistances: HashMap::new(),
            status_effects: Vec::new(),
            actions: Vec::new(),
            metadata: HashMap::new(),
        }
    }

    /// Returns true while the combatant is still alive.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_alive(&self) -> bool {
        self.alive && self.hp > 0.0
    }

    /// Applies damage after resistance and returns the net damage dealt.
    ///
    /// # Parameters
    /// - `amount` — `f64`.
    /// - `damage_type` — `&str`.
    ///
    /// # Returns
    /// `f64` — actual damage after resistance multiplier.
    pub fn take_damage(&mut self, amount: f64, damage_type: &str) -> f64 {
        let resistance = *self.resistances.get(damage_type).unwrap_or(&1.0);
        let actual = (amount * resistance).max(0.0);
        self.hp = (self.hp - actual).max(0.0);
        if self.hp <= 0.0 {
            self.alive = false;
        }
        actual
    }

    /// Heals HP and returns the amount actually restored.
    ///
    /// # Parameters
    /// - `amount` — `f64`.
    ///
    /// # Returns
    /// `f64` — actual HP restored (capped at max_hp).
    pub fn heal(&mut self, amount: f64) -> f64 {
        let before = self.hp;
        self.hp = (self.hp + amount).min(self.max_hp);
        self.hp - before
    }

    /// Adds a status effect, stacking when one with the same name already exists.
    ///
    /// # Parameters
    /// - `effect` — `StatusEffect`.
    pub fn add_status(&mut self, effect: StatusEffect) {
        if let Some(existing) = self
            .status_effects
            .iter_mut()
            .find(|e| e.name == effect.name)
        {
            existing.stacks += 1;
            if effect.duration > existing.duration {
                existing.duration = effect.duration;
            }
        } else {
            self.status_effects.push(effect);
        }
    }

    /// Removes a status effect by name. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn remove_status(&mut self, name: &str) {
        self.status_effects.retain(|e| e.name != name);
    }

    /// Returns true when a named status effect is active.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_status(&self, name: &str) -> bool {
        self.status_effects.iter().any(|e| e.name == name)
    }

    /// Ticks all statuses and returns the names of the ones that expired.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn tick_statuses(&mut self) -> Vec<String> {
        let mut expired = Vec::new();
        for effect in &mut self.status_effects {
            if effect.tick_turn() {
                expired.push(effect.name.clone());
            }
        }
        self.status_effects.retain(|effect| !effect.is_expired());
        expired
    }

    /// Adds an action to this combatant's action list.
    ///
    /// # Parameters
    /// - `action` — `CombatAction`.
    pub fn add_action(&mut self, action: CombatAction) {
        self.actions.push(action);
    }

    /// Returns an immutable action reference by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&CombatAction>`.
    pub fn get_action(&self, name: &str) -> Option<&CombatAction> {
        self.actions.iter().find(|action| action.name == name)
    }

    /// Returns a mutable action reference by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut CombatAction>`.
    pub fn get_action_mut(&mut self, name: &str) -> Option<&mut CombatAction> {
        self.actions.iter_mut().find(|action| action.name == name)
    }

    /// Returns a named stat value, defaulting to zero.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `f64`.
    pub fn get_stat(&self, name: &str) -> f64 {
        *self.stats.get(name).unwrap_or(&0.0)
    }

    /// Sets a named stat value. Replaces the current stat value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `name` — `String`.
    /// - `value` — `f64`.
    pub fn set_stat(&mut self, name: String, value: f64) {
        self.stats.insert(name, value);
    }

    /// Returns the names of all loaded combat actions.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn action_names(&self) -> Vec<String> {
        self.actions
            .iter()
            .map(|action| action.name.clone())
            .collect()
    }

    /// Returns the names of all active status effects.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn status_names(&self) -> Vec<String> {
        self.status_effects
            .iter()
            .map(|status| status.name.clone())
            .collect()
    }

    /// Returns HP as a percentage in the range 0..=100.
    ///
    /// # Returns
    /// `f64`.
    pub fn hp_percent(&self) -> f64 {
        if self.max_hp <= 0.0 {
            return 0.0;
        }
        (self.hp / self.max_hp * 100.0).clamp(0.0, 100.0)
    }

    /// Returns MP as a percentage in the range 0..=100.
    ///
    /// # Returns
    /// `f64`.
    pub fn mp_percent(&self) -> f64 {
        if self.max_mp <= 0.0 {
            return 0.0;
        }
        (self.mp / self.max_mp * 100.0).clamp(0.0, 100.0)
    }
}
