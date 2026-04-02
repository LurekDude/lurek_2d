//! Turn-based combat system: combatants, actions, damage types, teams, and turn order.
//!
//! Exposed to Lua via `luna.combat.*`.

use std::collections::HashMap;

// ─────────────────────────────────────────────────────────────────────────────
// DamageType
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// CombatResult
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
