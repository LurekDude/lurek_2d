//! CombatBattle: manages full battle lifecycle with turn ordering and action resolution.

use std::collections::HashMap;
use crate::combat::types::CombatResult;
use crate::combat::combatant::Combatant;

/// Manages a full battle with turn ordering, combatant sets, and action resolution.
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

    pub fn add_combatant(&mut self, c: Combatant) {
        self.combatants.push(c);
    }

    pub fn get_combatant(&self, name: &str) -> Option<&Combatant> {
        self.combatants.iter().find(|c| c.name == name)
    }

    pub fn get_combatant_mut(&mut self, name: &str) -> Option<&mut Combatant> {
        self.combatants.iter_mut().find(|c| c.name == name)
    }

    pub fn count(&self) -> usize { self.combatants.len() }

    pub fn alive_names(&self) -> Vec<String> {
        self.combatants.iter().filter(|c| c.is_alive()).map(|c| c.name.clone()).collect()
    }

    /// Sort combatants by speed descending for initiative.
    pub fn sort_initiative(&mut self) {
        self.combatants.sort_by(|a, b| b.speed.partial_cmp(&a.speed).unwrap_or(std::cmp::Ordering::Equal));
    }

    /// Current combatant name (turn order cycles through alive ones).
    pub fn current_combatant(&self) -> Option<&Combatant> {
        let alive: Vec<&Combatant> = self.combatants.iter().filter(|c| c.is_alive()).collect();
        if alive.is_empty() { return None; }
        Some(alive[self.turn_index % alive.len()])
    }

    /// Advance to the next turn.
    pub fn next_turn(&mut self) -> bool {
        let alive_count = self.combatants.iter().filter(|c| c.is_alive()).count();
        if alive_count == 0 { return false; }
        self.turn_index = (self.turn_index + 1) % alive_count;
        self.turn_count += 1;
        self.check_battle_over();
        !self.over
    }

    /// Execute an attack: attacker uses action on target.
    pub fn attack(&mut self, attacker_name: &str, action_name: &str, target_name: &str) -> Option<CombatResult> {
        let (damage, damage_type, hit, action_name_s) = {
            let attacker = self.combatants.iter_mut().find(|c| c.name == attacker_name)?;
            let action = attacker.get_action_mut(action_name)?;
            if !action.is_ready() { return None; }
            let hit = fastrand::f64() <= action.accuracy;
            let dmg = if hit { action.base_damage } else { 0.0 };
            let dtype = action.damage_type.clone();
            let aname = action.name.clone();
            action.use_action();
            (dmg, dtype, hit, aname)
        };

        let target = self.combatants.iter_mut().find(|c| c.name == target_name)?;
        let actual_damage = if hit { target.take_damage(damage, &damage_type) } else { 0.0 };
        let died = !target.is_alive();

        let result = CombatResult {
            attacker: attacker_name.to_string(),
            target: target_name.to_string(),
            action: action_name_s,
            hit,
            damage: actual_damage,
            damage_type,
            target_died: died,
            message: if hit {
                format!("{} dealt {:.1} to {}", attacker_name, actual_damage, target_name)
            } else {
                format!("{} missed {}", attacker_name, target_name)
            },
        };

        self.check_battle_over();
        Some(result)
    }

    fn check_battle_over(&mut self) {
        let mut teams_alive: HashMap<String, bool> = HashMap::new();
        for c in &self.combatants {
            if c.is_alive() {
                teams_alive.insert(c.team.clone(), true);
            }
        }
        if teams_alive.len() <= 1 {
            self.over = true;
            self.winner_team = teams_alive.into_keys().next();
        }
    }

    pub fn is_over(&self) -> bool { self.over }
    pub fn winner(&self) -> Option<&str> { self.winner_team.as_deref() }

    pub fn get_all_names(&self) -> Vec<String> {
        self.combatants.iter().map(|c| c.name.clone()).collect()
    }

    /// Append a message to the combat log.
    pub fn push_log(&mut self, msg: impl Into<String>) {
        self.log.push(msg.into());
    }

    /// Return all combat log messages.
    pub fn get_log(&self) -> &[String] {
        &self.log
    }

    /// Remove a combatant by name. Returns true if found and removed.
    pub fn remove_combatant(&mut self, name: &str) -> bool {
        if let Some(pos) = self.combatants.iter().position(|c| c.name == name) {
            self.combatants.remove(pos);
            true
        } else {
            false
        }
    }

    /// Manually end the battle with an optional winning team.
    pub fn force_end(&mut self, winner: Option<String>) {
        self.over = true;
        self.winner_team = winner;
    }

}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::combat::action::CombatAction;

    #[test]
    fn combatant_basic() {
        let mut c = Combatant::new("hero");
        c.hp = 50.0; c.max_hp = 100.0;
        let healed = c.heal(30.0);
        assert!((healed - 30.0).abs() < f64::EPSILON);
        assert!((c.hp - 80.0).abs() < f64::EPSILON);
    }

    #[test]
    fn battle_attack() {
        let mut b = CombatBattle::new("test");
        let mut hero = Combatant::new("hero");
        let mut action = CombatAction::new("punch");
        action.base_damage = 50.0;
        action.accuracy = 1.0;
        hero.add_action(action);
        let enemy = Combatant::new("goblin");
        b.add_combatant(hero);
        b.add_combatant(enemy);
        let result = b.attack("hero", "punch", "goblin").unwrap();
        assert!(result.hit);
        assert!((result.damage - 50.0).abs() < f64::EPSILON);
    }
}
