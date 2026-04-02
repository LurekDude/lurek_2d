//! Combat primitive types: damage kinds, status effects, and action results.

use std::collections::HashMap;

/// Kind of damage for resistance lookups.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum DamageType {
    Physical,
    Fire,
    Ice,
    Lightning,
    Poison,
    Arcane,
    Custom(String),
}

impl DamageType {
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Self {
        match s {
            "physical" => Self::Physical,
            "fire" => Self::Fire,
            "ice" => Self::Ice,
            "lightning" => Self::Lightning,
            "poison" => Self::Poison,
            "arcane" => Self::Arcane,
            other => Self::Custom(other.to_string()),
        }
    }

    pub fn as_str(&self) -> &str {
        match self {
            Self::Physical => "physical",
            Self::Fire => "fire",
            Self::Ice => "ice",
            Self::Lightning => "lightning",
            Self::Poison => "poison",
            Self::Arcane => "arcane",
            Self::Custom(s) => s.as_str(),
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusEffect
// ─────────────────────────────────────────────────────────────────────────────

/// An active status effect on a combatant.
#[derive(Debug, Clone)]
pub struct StatusEffect {
    pub name: String,
    pub duration: i32,  // turns remaining, -1 = permanent
    pub stacks: u32,
    pub data: HashMap<String, String>,
}

impl StatusEffect {
    pub fn new(name: impl Into<String>, duration: i32) -> Self {
        Self { name: name.into(), duration, stacks: 1, data: HashMap::new() }
    }

    pub fn tick_turn(&mut self) -> bool {
        if self.duration > 0 {
            self.duration -= 1;
        }
        self.duration == 0
    }

    pub fn is_expired(&self) -> bool {
        self.duration == 0
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CombatAction
// ─────────────────────────────────────────────────────────────────────────────


/// Result of a single combat action.
#[derive(Debug, Clone)]
pub struct CombatResult {
    pub attacker: String,
    pub target: String,
    pub action: String,
    pub hit: bool,
    pub damage: f64,
    pub damage_type: String,
    pub target_died: bool,
    pub message: String,
}

// ─────────────────────────────────────────────────────────────────────────────
// CombatBattle
// ─────────────────────────────────────────────────────────────────────────────
