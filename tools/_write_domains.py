"""Write src/combat/mod.rs, src/crafting/mod.rs, stub api files, test files"""
import os

# ── combat/mod.rs ─────────────────────────────────────────────────────────────
combat_mod = r"""//! Turn-based combat system: combatants, actions, damage types, teams, and turn order.
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
"""

os.makedirs('src/combat', exist_ok=True)
with open('src/combat/mod.rs', 'w', encoding='utf-8') as f:
    f.write(combat_mod)
print('combat/mod.rs written')


# ── crafting/mod.rs ───────────────────────────────────────────────────────────
crafting_mod = r"""//! Crafting system: recipes, ingredients, stations, skill progression, and craft queues.
//!
//! Exposed to Lua via `luna.crafting.*`.

use std::collections::HashMap;

// ─────────────────────────────────────────────────────────────────────────────
// Quality
// ─────────────────────────────────────────────────────────────────────────────

/// Output quality tiers for crafted items.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Quality {
    Normal = 0,
    Fine = 1,
    Superior = 2,
    Excellent = 3,
    Masterwork = 4,
    Legendary = 5,
}

impl Quality {
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "normal" => Some(Self::Normal),
            "fine" => Some(Self::Fine),
            "superior" => Some(Self::Superior),
            "excellent" => Some(Self::Excellent),
            "masterwork" => Some(Self::Masterwork),
            "legendary" => Some(Self::Legendary),
            _ => None,
        }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            Self::Normal => "normal",
            Self::Fine => "fine",
            Self::Superior => "superior",
            Self::Excellent => "excellent",
            Self::Masterwork => "masterwork",
            Self::Legendary => "legendary",
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient
// ─────────────────────────────────────────────────────────────────────────────

/// An ingredient required by a recipe.
#[derive(Debug, Clone)]
pub struct Ingredient {
    pub item_type: String,
    pub quantity: u32,
    /// If true, consumes the ingredient; if false, requires it present but doesn't consume.
    pub consumed: bool,
}

impl Ingredient {
    pub fn new(item_type: impl Into<String>, quantity: u32) -> Self {
        Self { item_type: item_type.into(), quantity, consumed: true }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// RecipeOutput
// ─────────────────────────────────────────────────────────────────────────────

/// Output of a recipe.
#[derive(Debug, Clone)]
pub struct RecipeOutput {
    pub item_type: String,
    pub quantity: u32,
    pub quality: Quality,
}

impl RecipeOutput {
    pub fn new(item_type: impl Into<String>, quantity: u32) -> Self {
        Self { item_type: item_type.into(), quantity, quality: Quality::Normal }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe
// ─────────────────────────────────────────────────────────────────────────────

/// Defines how inputs are combined to produce outputs.
#[derive(Debug, Clone)]
pub struct Recipe {
    pub id: String,
    pub recipe_type: String,   // "shaped", "shapeless", "smelting", "currency"
    pub name: String,
    pub description: String,
    pub station_type: String,  // "" = any station
    pub station_level: u32,
    pub time: f64,             // seconds to craft
    pub ingredients: Vec<Ingredient>,
    pub outputs: Vec<RecipeOutput>,
    pub skill: String,         // skill requirement name, empty = none
    pub skill_level: u32,
    pub skill_xp: f64,         // XP granted on craft
    pub enabled: bool,
    pub tags: Vec<String>,
    pub metadata: HashMap<String, String>,
}

impl Recipe {
    pub fn new(id: impl Into<String>, recipe_type: impl Into<String>) -> Self {
        let id = id.into();
        let name = id.clone();
        Self {
            id,
            recipe_type: recipe_type.into(),
            name,
            description: String::new(),
            station_type: String::new(),
            station_level: 0,
            time: 1.0,
            ingredients: Vec::new(),
            outputs: Vec::new(),
            skill: String::new(),
            skill_level: 0,
            skill_xp: 0.0,
            enabled: true,
            tags: Vec::new(),
            metadata: HashMap::new(),
        }
    }

    pub fn add_ingredient(&mut self, ingredient: Ingredient) {
        self.ingredients.push(ingredient);
    }

    pub fn add_output(&mut self, output: RecipeOutput) {
        self.outputs.push(output);
    }

    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// RecipeRegistry
// ─────────────────────────────────────────────────────────────────────────────

/// Central registry for all known recipes.
#[derive(Debug, Default)]
pub struct RecipeRegistry {
    recipes: HashMap<String, Recipe>,
    order: Vec<String>,
}

impl RecipeRegistry {
    pub fn new() -> Self { Self::default() }

    pub fn add(&mut self, recipe: Recipe) {
        if !self.order.contains(&recipe.id) {
            self.order.push(recipe.id.clone());
        }
        self.recipes.insert(recipe.id.clone(), recipe);
    }

    pub fn get(&self, id: &str) -> Option<&Recipe> { self.recipes.get(id) }
    pub fn get_mut(&mut self, id: &str) -> Option<&mut Recipe> { self.recipes.get_mut(id) }
    pub fn remove(&mut self, id: &str) -> bool {
        self.order.retain(|s| s != id);
        self.recipes.remove(id).is_some()
    }
    pub fn count(&self) -> usize { self.recipes.len() }
    pub fn ids(&self) -> &[String] { &self.order }

    /// Find recipes whose outputs include the given item type.
    pub fn find_by_output(&self, item_type: &str) -> Vec<&str> {
        self.order.iter()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .filter(|r| r.outputs.iter().any(|o| o.item_type == item_type))
            .map(|r| r.id.as_str())
            .collect()
    }

    /// Find recipes that need the given ingredient.
    pub fn find_by_ingredient(&self, item_type: &str) -> Vec<&str> {
        self.order.iter()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .filter(|r| r.ingredients.iter().any(|i| i.item_type == item_type))
            .map(|r| r.id.as_str())
            .collect()
    }

    /// Filter by station type.
    pub fn for_station(&self, station_type: &str) -> Vec<&str> {
        self.order.iter()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .filter(|r| r.station_type.is_empty() || r.station_type == station_type)
            .map(|r| r.id.as_str())
            .collect()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Station
// ─────────────────────────────────────────────────────────────────────────────

/// A crafting station that processes recipes.
#[derive(Debug, Clone)]
pub struct Station {
    pub station_type: String,
    pub level: u32,
    pub speed_multiplier: f64,
    pub name: String,
    pub active: bool,
    pub metadata: HashMap<String, String>,
}

impl Station {
    pub fn new(station_type: impl Into<String>, level: u32) -> Self {
        let station_type = station_type.into();
        let name = station_type.clone();
        Self {
            station_type,
            level,
            speed_multiplier: 1.0,
            name,
            active: true,
            metadata: HashMap::new(),
        }
    }

    pub fn can_process(&self, recipe: &Recipe) -> bool {
        self.active
            && (recipe.station_type.is_empty() || recipe.station_type == self.station_type)
            && self.level >= recipe.station_level
    }

    pub fn effective_time(&self, recipe: &Recipe) -> f64 {
        recipe.time / self.speed_multiplier.max(0.001)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CraftSkill
// ─────────────────────────────────────────────────────────────────────────────

/// Player crafting skill with XP and level progression.
#[derive(Debug, Clone)]
pub struct CraftSkill {
    pub name: String,
    pub xp: f64,
    pub level: u32,
    pub level_thresholds: Vec<f64>,  // xp needed to reach each level index
    pub metadata: HashMap<String, String>,
}

impl CraftSkill {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            xp: 0.0,
            level: 1,
            level_thresholds: (1..=100).map(|l| (l as f64) * 100.0).collect(),
            metadata: HashMap::new(),
        }
    }

    pub fn add_xp(&mut self, amount: f64) -> u32 {
        self.xp += amount;
        let mut leveled = 0u32;
        while {
            let needed = self.level_thresholds
                .get(self.level as usize)
                .copied()
                .unwrap_or(f64::MAX);
            self.xp >= needed && self.level < 100
        } {
            self.level += 1;
            leveled += 1;
        }
        leveled
    }

    pub fn get_xp_to_next(&self) -> f64 {
        let needed = self.level_thresholds
            .get(self.level as usize)
            .copied()
            .unwrap_or(f64::MAX);
        (needed - self.xp).max(0.0)
    }

    pub fn can_use(&self, recipe: &Recipe) -> bool {
        recipe.skill.is_empty() || (recipe.skill == self.name && self.level >= recipe.skill_level)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CraftJob / CraftQueue
// ─────────────────────────────────────────────────────────────────────────────

/// A queued crafting job.
#[derive(Debug, Clone)]
pub struct CraftJob {
    pub id: u32,
    pub recipe_id: String,
    pub progress: f64,     // seconds elapsed
    pub total_time: f64,   // seconds required
    pub quantity: u32,
    pub completed: bool,
    pub paused: bool,
}

impl CraftJob {
    pub fn new(id: u32, recipe_id: impl Into<String>, total_time: f64, quantity: u32) -> Self {
        Self { id, recipe_id: recipe_id.into(), progress: 0.0, total_time, quantity, completed: false, paused: false }
    }

    pub fn advance(&mut self, dt: f64) -> bool {
        if self.completed || self.paused { return false; }
        self.progress += dt;
        if self.progress >= self.total_time {
            self.completed = true;
            true
        } else {
            false
        }
    }

    pub fn percent(&self) -> f64 {
        if self.total_time <= 0.0 { 1.0 } else { (self.progress / self.total_time).min(1.0) }
    }
}

/// A queue that holds and processes craft jobs.
#[derive(Debug)]
pub struct CraftQueue {
    jobs: Vec<CraftJob>,
    max_jobs: usize,
    next_id: u32,
}

impl CraftQueue {
    pub fn new(max_jobs: usize) -> Self {
        Self { jobs: Vec::new(), max_jobs, next_id: 1 }
    }

    pub fn enqueue(&mut self, recipe_id: impl Into<String>, total_time: f64, quantity: u32) -> Option<u32> {
        if self.jobs.len() >= self.max_jobs { return None; }
        let id = self.next_id;
        self.next_id += 1;
        self.jobs.push(CraftJob::new(id, recipe_id, total_time, quantity));
        Some(id)
    }

    pub fn cancel(&mut self, id: u32) -> bool {
        let start_len = self.jobs.len();
        self.jobs.retain(|j| j.id != id);
        self.jobs.len() < start_len
    }

    pub fn update(&mut self, dt: f64) -> Vec<u32> {
        let mut finished = Vec::new();
        for job in &mut self.jobs {
            if job.advance(dt) {
                finished.push(job.id);
            }
        }
        finished
    }

    pub fn get_job(&self, id: u32) -> Option<&CraftJob> {
        self.jobs.iter().find(|j| j.id == id)
    }

    pub fn get_job_mut(&mut self, id: u32) -> Option<&mut CraftJob> {
        self.jobs.iter_mut().find(|j| j.id == id)
    }

    pub fn count(&self) -> usize { self.jobs.len() }
    pub fn is_full(&self) -> bool { self.jobs.len() >= self.max_jobs }
    pub fn max_jobs(&self) -> usize { self.max_jobs }

    /// Remove completed jobs and return their ids.
    pub fn collect_completed(&mut self) -> Vec<u32> {
        let mut ids = Vec::new();
        self.jobs.retain(|j| {
            if j.completed { ids.push(j.id); false } else { true }
        });
        ids
    }

    pub fn ids(&self) -> Vec<u32> {
        self.jobs.iter().map(|j| j.id).collect()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// UpgradeNode / UpgradeTree
// ─────────────────────────────────────────────────────────────────────────────

/// A single node in an upgrade tree.
#[derive(Debug, Clone)]
pub struct UpgradeNode {
    pub id: String,
    pub name: String,
    pub description: String,
    pub cost: HashMap<String, u32>,  // item_type -> quantity
    pub prerequisites: Vec<String>,
    pub unlocked: bool,
    pub metadata: HashMap<String, String>,
}

impl UpgradeNode {
    pub fn new(id: impl Into<String>, name: impl Into<String>) -> Self {
        Self {
            id: id.into(), name: name.into(), description: String::new(),
            cost: HashMap::new(), prerequisites: Vec::new(), unlocked: false, metadata: HashMap::new(),
        }
    }
}

/// DAG of upgrades for weapons or items.
#[derive(Debug, Default)]
pub struct UpgradeTree {
    pub name: String,
    nodes: HashMap<String, UpgradeNode>,
    order: Vec<String>,
}

impl UpgradeTree {
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), nodes: HashMap::new(), order: Vec::new() }
    }

    pub fn add_node(&mut self, node: UpgradeNode) {
        if !self.order.contains(&node.id) { self.order.push(node.id.clone()); }
        self.nodes.insert(node.id.clone(), node);
    }

    pub fn get_node(&self, id: &str) -> Option<&UpgradeNode> { self.nodes.get(id) }
    pub fn get_node_mut(&mut self, id: &str) -> Option<&mut UpgradeNode> { self.nodes.get_mut(id) }

    pub fn can_unlock(&self, id: &str) -> bool {
        if let Some(node) = self.nodes.get(id) {
            if node.unlocked { return false; }
            node.prerequisites.iter().all(|p| {
                self.nodes.get(p.as_str()).map(|n| n.unlocked).unwrap_or(false)
            })
        } else {
            false
        }
    }

    pub fn unlock(&mut self, id: &str) -> bool {
        if self.can_unlock(id) {
            if let Some(node) = self.nodes.get_mut(id) {
                node.unlocked = true;
                return true;
            }
        }
        false
    }

    pub fn node_ids(&self) -> &[String] { &self.order }
    pub fn count(&self) -> usize { self.nodes.len() }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recipe_basic() {
        let mut r = Recipe::new("sword", "shaped");
        r.add_ingredient(Ingredient::new("iron", 3));
        r.add_output(RecipeOutput::new("iron_sword", 1));
        assert_eq!(r.ingredients.len(), 1);
        assert_eq!(r.outputs.len(), 1);
    }

    #[test]
    fn craft_queue() {
        let mut q = CraftQueue::new(5);
        let id = q.enqueue("sword", 2.0, 1).unwrap();
        q.update(1.0);
        assert!(!q.get_job(id).unwrap().completed);
        q.update(1.5);
        assert!(q.get_job(id).unwrap().completed);
    }

    #[test]
    fn upgrade_tree() {
        let mut tree = UpgradeTree::new("weapon");
        let root = UpgradeNode::new("forge1", "Basic Forge");
        tree.add_node(root);
        assert!(tree.can_unlock("forge1"));
        tree.unlock("forge1");
        assert!(!tree.can_unlock("forge1"));
    }
}
"""

os.makedirs('src/crafting', exist_ok=True)
with open('src/crafting/mod.rs', 'w', encoding='utf-8') as f:
    f.write(crafting_mod)
print('crafting/mod.rs written')

print('All domain modules written')
