//! CombatAction: named attack/skill with cooldown, cost, and accuracy.

use std::collections::HashMap;

/// A combat action that a combatant can take.
#[derive(Debug, Clone)]
pub struct CombatAction {
    pub name: String,
    pub damage_type: String,
    pub base_damage: f64,
    pub accuracy: f64,      // 0.0..1.0
    pub cooldown: u32,
    pub current_cooldown: u32,
    pub cost_hp: f64,
    pub cost_mp: f64,
    pub tags: Vec<String>,
    pub metadata: HashMap<String, String>,
}

impl CombatAction {
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

    pub fn is_ready(&self) -> bool {
        self.current_cooldown == 0
    }

    pub fn use_action(&mut self) {
        self.current_cooldown = self.cooldown;
    }

    pub fn tick_cooldown(&mut self) {
        if self.current_cooldown > 0 {
            self.current_cooldown -= 1;
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Combatant
// ─────────────────────────────────────────────────────────────────────────────

