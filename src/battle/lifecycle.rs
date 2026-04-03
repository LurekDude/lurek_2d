//! CombatBattle: manages full turn-based battle lifecycle with turn ordering and action resolution.
//!
//! This module is part of Luna2D's `battle` subsystem and provides the implementation
//! details for battle-related operations and data management.
//! Key types exported from this module: `CombatBattle`.
//! Primary functions: `new()`, `add_combatant()`, `get_combatant()`, `get_combatant_mut()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

use crate::battle::combatant::Combatant;
use crate::battle::types::CombatResult;

/// Manages a full turn-based battle with turn ordering and action resolution.
///
/// Holds the combatant list, tracks turn order (sorted by speed descending),
/// maintains a running log, and resolves `CombatAction` applications including
/// hit-check, damage calculation, and death detection. A battle ends when all
/// combatants on one team are defeated.
///
/// # Fields
/// - `name` — `String`.
/// - `combatants` — `Vec<Combatant>`.
/// - `turn_index` — `usize`.
/// - `turn_count` — `u32`.
/// - `over` — `bool`.
/// - `winner_team` — `Option<String>`.
/// - `log` — `Vec<String>`.
#[derive(Debug)]
pub struct CombatBattle {
    pub name: String,
    combatants: Vec<Combatant>,
    pub turn_index: usize,
    pub turn_count: u32,
    pub over: bool,
    pub winner_team: Option<String>,
    pub log: Vec<String>,
}

impl CombatBattle {
    /// Creates an empty battle with the provided display name.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            combatants: Vec::new(),
            turn_index: 0,
            turn_count: 0,
            over: false,
            winner_team: None,
            log: Vec::new(),
        }
    }

    /// Adds a combatant to the battle. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `combatant` — `Combatant`.
    pub fn add_combatant(&mut self, combatant: Combatant) {
        self.combatants.push(combatant);
    }

    /// Returns an immutable combatant reference by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&Combatant>`.
    pub fn get_combatant(&self, name: &str) -> Option<&Combatant> {
        self.combatants
            .iter()
            .find(|combatant| combatant.name == name)
    }

    /// Returns a mutable combatant reference by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut Combatant>`.
    pub fn get_combatant_mut(&mut self, name: &str) -> Option<&mut Combatant> {
        self.combatants
            .iter_mut()
            .find(|combatant| combatant.name == name)
    }

    /// Returns the total number of combatants, alive or dead.
    ///
    /// # Returns
    /// `usize`.
    pub fn count(&self) -> usize {
        self.combatants.len()
    }

    /// Returns the names of all currently alive combatants.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn alive_names(&self) -> Vec<String> {
        self.combatants
            .iter()
            .filter(|combatant| combatant.is_alive())
            .map(|combatant| combatant.name.clone())
            .collect()
    }

    /// Sorts combatants by speed descending for initiative order.
    pub fn sort_initiative(&mut self) {
        self.combatants.sort_by(|left, right| {
            right
                .speed
                .partial_cmp(&left.speed)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
    }

    /// Returns the combatant whose turn is currently active.
    ///
    /// # Returns
    /// `Option<&Combatant>`.
    pub fn current_combatant(&self) -> Option<&Combatant> {
        let alive: Vec<&Combatant> = self
            .combatants
            .iter()
            .filter(|combatant| combatant.is_alive())
            .collect();
        if alive.is_empty() {
            return None;
        }
        Some(alive[self.turn_index % alive.len()])
    }

    /// Advances the turn order and returns false when the battle is already over.
    ///
    /// # Returns
    /// `bool` — `false` once all combatants on one side are defeated.
    pub fn next_turn(&mut self) -> bool {
        let alive_count = self
            .combatants
            .iter()
            .filter(|combatant| combatant.is_alive())
            .count();
        if alive_count == 0 {
            return false;
        }
        self.turn_index = (self.turn_index + 1) % alive_count;
        self.turn_count += 1;
        self.check_battle_over();
        !self.over
    }

    /// Executes an action from one combatant against another.
    ///
    /// # Parameters
    /// - `attacker_name` — `&str`.
    /// - `action_name` — `&str`.
    /// - `target_name` — `&str`.
    ///
    /// # Returns
    /// `Option<CombatResult>` — `None` if attacker/action/target are not found
    /// or the action is on cooldown.
    pub fn attack(
        &mut self,
        attacker_name: &str,
        action_name: &str,
        target_name: &str,
    ) -> Option<CombatResult> {
        let (damage, damage_type, hit, action_name_owned) = {
            let attacker = self
                .combatants
                .iter_mut()
                .find(|combatant| combatant.name == attacker_name)?;
            let action = attacker.get_action_mut(action_name)?;
            if !action.is_ready() {
                return None;
            }
            let hit = fastrand::f64() <= action.accuracy;
            let damage = if hit { action.base_damage } else { 0.0 };
            let damage_type = action.damage_type.clone();
            let action_name_owned = action.name.clone();
            action.use_action();
            (damage, damage_type, hit, action_name_owned)
        };

        let target = self
            .combatants
            .iter_mut()
            .find(|combatant| combatant.name == target_name)?;
        let actual_damage = if hit {
            target.take_damage(damage, &damage_type)
        } else {
            0.0
        };
        let died = !target.is_alive();

        let result = CombatResult {
            attacker: attacker_name.to_string(),
            target: target_name.to_string(),
            action: action_name_owned,
            hit,
            damage: actual_damage,
            damage_type,
            target_died: died,
            message: if hit {
                format!(
                    "{} dealt {:.1} to {}",
                    attacker_name, actual_damage, target_name
                )
            } else {
                format!("{} missed {}", attacker_name, target_name)
            },
        };

        self.check_battle_over();
        Some(result)
    }

    fn check_battle_over(&mut self) {
        let mut teams_alive: HashMap<String, bool> = HashMap::new();
        for combatant in &self.combatants {
            if combatant.is_alive() {
                teams_alive.insert(combatant.team.clone(), true);
            }
        }
        if teams_alive.len() <= 1 {
            self.over = true;
            self.winner_team = teams_alive.into_keys().next();
        }
    }

    /// Returns true when the battle has ended. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_over(&self) -> bool {
        self.over
    }

    /// Returns the winning team name when the battle is over.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn winner(&self) -> Option<&str> {
        self.winner_team.as_deref()
    }

    /// Returns the names of all combatants in the battle.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_all_names(&self) -> Vec<String> {
        self.combatants
            .iter()
            .map(|combatant| combatant.name.clone())
            .collect()
    }

    /// Appends a message to the battle log. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `sg` — `impl Into<String>`.
    pub fn push_log(&mut self, msg: impl Into<String>) {
        self.log.push(msg.into());
    }

    /// Returns all combat log messages. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&[String]`.
    pub fn get_log(&self) -> &[String] {
        &self.log
    }

    /// Removes a combatant by name and returns true when one was removed.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_combatant(&mut self, name: &str) -> bool {
        if let Some(position) = self
            .combatants
            .iter()
            .position(|combatant| combatant.name == name)
        {
            self.combatants.remove(position);
            true
        } else {
            false
        }
    }

    /// Marks the battle over and optionally records a winner.
    ///
    /// # Parameters
    /// - `winner` — `Option<String>`.
    pub fn force_end(&mut self, winner: Option<String>) {
        self.over = true;
        self.winner_team = winner;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::battle::action::CombatAction;

    #[test]
    fn combatant_basic() {
        let mut combatant = Combatant::new("hero");
        combatant.hp = 50.0;
        combatant.max_hp = 100.0;
        let healed = combatant.heal(30.0);
        assert!((healed - 30.0).abs() < f64::EPSILON);
        assert!((combatant.hp - 80.0).abs() < f64::EPSILON);
    }

    #[test]
    fn battle_attack() {
        let mut battle = CombatBattle::new("test");
        let mut hero = Combatant::new("hero");
        let mut action = CombatAction::new("punch");
        action.base_damage = 50.0;
        action.accuracy = 1.0;
        hero.add_action(action);
        let enemy = Combatant::new("goblin");
        battle.add_combatant(hero);
        battle.add_combatant(enemy);
        let result = battle.attack("hero", "punch", "goblin").unwrap();
        assert!(result.hit);
        assert!((result.damage - 50.0).abs() < f64::EPSILON);
    }
}
