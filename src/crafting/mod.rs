//! Crafting system: recipes, ingredients, stations, skill progression, and craft queues.
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

    /// Returns all tags on this recipe.
    pub fn get_tags(&self) -> &[String] { &self.tags }

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
    /// Find recipe IDs that have a specific tag.
    pub fn find_by_tag(&self, tag: &str) -> Vec<&str> {
        self.recipes.iter()
            .filter(|(_, r)| r.tags.contains(&tag.to_string()))
            .map(|(id, _)| id.as_str())
            .collect()
    }

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

    /// Force-set the skill level and reset XP to 0.
    pub fn set_level(&mut self, level: u32) {
        self.level = level;
        self.xp = 0.0;
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

    /// Cancel all jobs in the queue.
    pub fn clear(&mut self) {
        self.jobs.clear();
    }

    /// Return all job summaries as (id, recipe_id, quantity, progress, paused) tuples.
    pub fn all_jobs(&self) -> Vec<(u32, String, u32, f64, bool)> {
        self.jobs.iter()
            .map(|j| (j.id, j.recipe_id.clone(), j.quantity, j.progress, j.paused))
            .collect()
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

    /// Re-lock a previously unlocked node. Returns false if node not found.
    pub fn reset_node(&mut self, id: &str) -> bool {
        if let Some(node) = self.nodes.get_mut(id) {
            node.unlocked = false;
            true
        } else { false }
    }

    /// Returns all currently unlocked node IDs.
    pub fn get_unlocked_ids(&self) -> Vec<String> {
        self.nodes.iter().filter(|(_, n)| n.unlocked).map(|(id, _)| id.clone()).collect()
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
