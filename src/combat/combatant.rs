//! Combatant: a single participant in a battle with HP, MP, statuses, and actions.

use std::collections::HashMap;
use crate::combat::types::StatusEffect;
use crate::combat::action::CombatAction;

/// A participant in combat.
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
    pub resistances: HashMap<String, f64>,   // DamageType.as_str() -> multiplier (0.5 = 50% resist)
    pub status_effects: Vec<StatusEffect>,
    pub actions: Vec<CombatAction>,
    pub metadata: HashMap<String, String>,
}

impl Combatant {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            team: "player".to_string(),
            hp: 100.0, max_hp: 100.0,
            mp: 50.0, max_mp: 50.0,
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

    pub fn is_alive(&self) -> bool {
        self.alive && self.hp > 0.0
    }

    pub fn take_damage(&mut self, amount: f64, damage_type: &str) -> f64 {
        let resistance = *self.resistances.get(damage_type).unwrap_or(&1.0);
        let actual = (amount * resistance).max(0.0);
        self.hp = (self.hp - actual).max(0.0);
        if self.hp <= 0.0 {
            self.alive = false;
        }
        actual
    }

    pub fn heal(&mut self, amount: f64) -> f64 {
        let before = self.hp;
        self.hp = (self.hp + amount).min(self.max_hp);
        self.hp - before
    }

    pub fn add_status(&mut self, effect: StatusEffect) {
        if let Some(existing) = self.status_effects.iter_mut().find(|e| e.name == effect.name) {
            existing.stacks += 1;
            if effect.duration > existing.duration {
                existing.duration = effect.duration;
            }
        } else {
            self.status_effects.push(effect);
        }
    }

    pub fn remove_status(&mut self, name: &str) {
        self.status_effects.retain(|e| e.name != name);
    }

    pub fn has_status(&self, name: &str) -> bool {
        self.status_effects.iter().any(|e| e.name == name)
    }

    pub fn tick_statuses(&mut self) -> Vec<String> {
        let mut expired = Vec::new();
        for e in &mut self.status_effects {
            if e.tick_turn() {
                expired.push(e.name.clone());
            }
        }
        self.status_effects.retain(|e| !e.is_expired());
        expired
    }

    pub fn add_action(&mut self, action: CombatAction) {
        self.actions.push(action);
    }

    pub fn get_action(&self, name: &str) -> Option<&CombatAction> {
        self.actions.iter().find(|a| a.name == name)
    }

    pub fn get_action_mut(&mut self, name: &str) -> Option<&mut CombatAction> {
        self.actions.iter_mut().find(|a| a.name == name)
    }

    pub fn get_stat(&self, name: &str) -> f64 {
        *self.stats.get(name).unwrap_or(&0.0)
    }

    pub fn set_stat(&mut self, name: String, value: f64) {
        self.stats.insert(name, value);
    }

    /// Returns the names of all loaded combat actions.
    pub fn action_names(&self) -> Vec<String> {
        self.actions.iter().map(|a| a.name.clone()).collect()
    }

    /// Returns the names of all active status effects.
    pub fn status_names(&self) -> Vec<String> {
        self.status_effects.iter().map(|s| s.name.clone()).collect()
    }

    /// Returns HP as a percentage 0..=100.
    pub fn hp_percent(&self) -> f64 {
        if self.max_hp <= 0.0 { return 0.0; }
        (self.hp / self.max_hp * 100.0).clamp(0.0, 100.0)
    }

    /// Returns MP as a percentage 0..=100.
    pub fn mp_percent(&self) -> f64 {
        if self.max_mp <= 0.0 { return 0.0; }
        (self.mp / self.max_mp * 100.0).clamp(0.0, 100.0)
    }

}

