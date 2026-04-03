//! Recipe knowledge tracking and UI grouping for crafting.
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for knowledge-related operations and data management.
//! Key types exported from this module: `RecipeKnowledge`, `RecipeGroup`.
//! Primary functions: `new()`, `discover()`, `forget()`, `is_known()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

/// Tracks which recipes a player has discovered or unlocked.
///
/// # Fields
/// - `known` — `HashMap<String`.
/// - `auto_discover` — `bool`.
/// - `prototyped` — `std::collections::HashSet<String>`.
/// - `research_costs` — `HashMap<String`.
#[derive(Debug, Default)]
pub struct RecipeKnowledge {
    /// recipe_id → discovery source (e.g. `"pickup"`, `"blueprint"`, `"quest"`).
    known: HashMap<String, String>,
    auto_discover: bool,
    /// Prototyped recipes (Don't Starve pattern): recipe_id → true if permanently learned.
    prototyped: std::collections::HashSet<String>,
    /// Research costs for blueprint system (Rust pattern): recipe_id → scrap cost.
    research_costs: HashMap<String, f64>,
}

impl RecipeKnowledge {
    /// Create an empty knowledge tracker. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// A tracker with no known recipes, no prototypes, and auto-discovery disabled.
    pub fn new() -> Self { Self::default() }

    /// Mark a recipe as known with an optional discovery source.
    ///
    /// # Parameters
    /// - `recipe_id`: Stable recipe identifier to mark as known.
    /// - `source`: Discovery source label such as `"pickup"` or `"blueprint"`.
    pub fn discover(&mut self, recipe_id: impl Into<String>, source: impl Into<String>) {
        self.known.insert(recipe_id.into(), source.into());
    }

    /// Remove knowledge of a recipe (wipe mechanic, e.g. Rust death).
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to forget.
    ///
    /// # Returns
    /// `true` if the recipe had recorded knowledge.
    pub fn forget(&mut self, recipe_id: &str) -> bool {
        self.known.remove(recipe_id).is_some()
    }

    /// Check if a recipe is known (auto-discover bypasses individual knowledge).
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to query.
    ///
    /// # Returns
    /// `true` if auto-discovery is enabled or the recipe is explicitly known.
    pub fn is_known(&self, recipe_id: &str) -> bool {
        self.auto_discover || self.known.contains_key(recipe_id)
    }

    /// Returns all known recipe IDs. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// A vector of known recipe IDs in arbitrary hash-map order.
    pub fn get_known(&self) -> Vec<&str> {
        self.known.keys().map(|s| s.as_str()).collect()
    }

    /// Returns the number of known recipes. Runs in O(1) time.
    ///
    /// # Returns
    /// The count of explicitly known recipes.
    pub fn count(&self) -> usize { self.known.len() }

    /// Enable/disable auto-discovery (all recipes always visible).
    ///
    /// # Parameters
    /// - `enabled`: Whether every recipe should be treated as visible.
    pub fn set_auto_discover(&mut self, enabled: bool) { self.auto_discover = enabled; }

    /// Whether auto-discover is enabled. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `true` if all recipes should be considered known.
    pub fn is_auto_discover(&self) -> bool { self.auto_discover }

    /// Get the discovery source for a recipe. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to query.
    ///
    /// # Returns
    /// The recorded source label, if the recipe is explicitly known.
    pub fn get_source(&self, recipe_id: &str) -> Option<&str> {
        self.known.get(recipe_id).map(|s| s.as_str())
    }

    /// Reset all knowledge. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.known.clear();
        self.prototyped.clear();
    }

    // ── Prototype system (Don't Starve pattern) ───────────────────────────────

    /// Permanently learn a recipe via prototyping. Returns `false` if already prototyped.
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to prototype and permanently learn.
    ///
    /// # Returns
    /// `true` if the recipe was newly prototyped.
    pub fn prototype(&mut self, recipe_id: impl Into<String>) -> bool {
        let id = recipe_id.into();
        if self.prototyped.contains(&id) { return false; }
        self.known.insert(id.clone(), "prototype".into());
        self.prototyped.insert(id);
        true
    }

    /// Whether a recipe has been prototyped. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to query.
    ///
    /// # Returns
    /// `true` if the recipe was learned through prototyping.
    pub fn is_prototyped(&self, recipe_id: &str) -> bool {
        self.prototyped.contains(recipe_id)
    }

    // ── Blueprint system (Rust pattern) ──────────────────────────────────────

    /// Set the resource cost required to research a recipe.
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to configure.
    /// - `cost`: Scrap cost required to research the recipe.
    pub fn set_research_cost(&mut self, recipe_id: impl Into<String>, cost: f64) {
        self.research_costs.insert(recipe_id.into(), cost);
    }

    /// Get the research cost for a recipe (0 if not set).
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to query.
    ///
    /// # Returns
    /// The configured research cost, or `0.0` when no cost is set.
    pub fn get_research_cost(&self, recipe_id: &str) -> f64 {
        self.research_costs.get(recipe_id).copied().unwrap_or(0.0)
    }

    /// Attempt to research a recipe by spending `scrap`. Returns `false` if can't afford.
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to research.
    /// - `scrap`: Available research currency.
    ///
    /// # Returns
    /// `true` if the recipe was learned through research.
    pub fn research(&mut self, recipe_id: &str, scrap: f64) -> bool {
        let cost = self.get_research_cost(recipe_id);
        if scrap < cost { return false; }
        self.known.insert(recipe_id.to_string(), "research".into());
        true
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// RecipeGroup
// ─────────────────────────────────────────────────────────────────────────────

/// Named grouping of recipes for UI organisation and bulk operations.
///
/// # Fields
/// - `name`: Stable group name shown in the UI or used for lookups.
/// - `icon`: Optional icon ID associated with the group.
/// - `order`: Sort key for UI ordering.
/// - `recipe_ids`: Recipes assigned to this group in insertion order.
#[derive(Debug, Clone)]
pub struct RecipeGroup {
    pub name: String,
    pub icon: String,
    pub order: i32,
    recipe_ids: Vec<String>,
}

impl RecipeGroup {
    /// Create a new recipe group with the given name.
    ///
    /// # Parameters
    /// - `name`: Stable name for the group.
    ///
    /// # Returns
    /// An empty group with no icon and sort order `0`.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), icon: String::new(), order: 0, recipe_ids: Vec::new() }
    }

    /// Add a recipe ID to this group (no-op if already present).
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to add.
    pub fn add_recipe(&mut self, recipe_id: impl Into<String>) {
        let id = recipe_id.into();
        if !self.recipe_ids.contains(&id) { self.recipe_ids.push(id); }
    }

    /// Remove a recipe ID from this group. Returns `false` if not found.
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to remove.
    ///
    /// # Returns
    /// `true` if the recipe ID existed in the group.
    pub fn remove_recipe(&mut self, recipe_id: &str) -> bool {
        let before = self.recipe_ids.len();
        self.recipe_ids.retain(|s| s != recipe_id);
        self.recipe_ids.len() < before
    }

    /// Returns all recipe IDs in this group. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// A slice of recipe IDs in insertion order.
    pub fn get_recipes(&self) -> &[String] { &self.recipe_ids }

    /// Number of recipes in this group. Runs in O(1) time.
    ///
    /// # Returns
    /// The number of recipe IDs assigned to the group.
    pub fn count(&self) -> usize { self.recipe_ids.len() }

    /// Check whether this group contains a recipe.
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier to test.
    ///
    /// # Returns
    /// `true` if the group already contains the recipe ID.
    pub fn contains(&self, recipe_id: &str) -> bool {
        self.recipe_ids.iter().any(|s| s == recipe_id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recipe_knowledge_prototype() {
        let mut knowledge = RecipeKnowledge::new();
        assert!(knowledge.prototype("long_sword"));
        assert!(!knowledge.prototype("long_sword"));
        assert!(knowledge.is_known("long_sword"));
        assert!(knowledge.is_prototyped("long_sword"));
        assert_eq!(knowledge.get_source("long_sword"), Some("prototype"));
    }

    #[test]
    fn recipe_knowledge_blueprint_research() {
        let mut knowledge = RecipeKnowledge::new();
        knowledge.set_research_cost("ak47", 750.0);
        assert_eq!(knowledge.get_research_cost("ak47"), 750.0);
        assert!(!knowledge.research("ak47", 500.0));
        assert!(knowledge.research("ak47", 750.0));
        assert!(knowledge.is_known("ak47"));
    }

    #[test]
    fn recipe_knowledge_basic() {
        let mut knowledge = RecipeKnowledge::new();
        knowledge.discover("sword", "pickup");
        assert!(knowledge.is_known("sword"));
        assert_eq!(knowledge.get_source("sword"), Some("pickup"));
        assert!(knowledge.forget("sword"));
        assert!(!knowledge.is_known("sword"));
    }

    #[test]
    fn recipe_knowledge_auto_discover() {
        let mut knowledge = RecipeKnowledge::new();
        knowledge.set_auto_discover(true);
        assert!(knowledge.is_known("any_recipe"));
    }

    #[test]
    fn recipe_knowledge_clear() {
        let mut knowledge = RecipeKnowledge::new();
        knowledge.discover("a", "");
        knowledge.discover("b", "");
        knowledge.clear();
        assert_eq!(knowledge.count(), 0);
    }

    #[test]
    fn recipe_group_basic() {
        let mut group = RecipeGroup::new("weapons");
        group.add_recipe("sword");
        group.add_recipe("axe");
        group.add_recipe("sword");
        assert_eq!(group.count(), 2);
        assert!(group.contains("sword"));
        group.remove_recipe("sword");
        assert!(!group.contains("sword"));
    }

    #[test]
    fn recipe_group_icon_and_order() {
        let mut group = RecipeGroup::new("tools");
        group.icon = "hammer_icon".into();
        group.order = 5;
        assert_eq!(group.icon, "hammer_icon");
        assert_eq!(group.order, 5);
    }
}
