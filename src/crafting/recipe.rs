//! Recipe definition and the central recipe registry.
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for recipe-related operations and data management.
//! Key types exported from this module: `Recipe`, `RecipeRegistry`.
//! Primary functions: `new()`, `add_ingredient()`, `add_output()`, `clear_ingredients()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;
use super::ingredient::{Ingredient, RecipeOutput};

/// Defines how inputs are combined to produce outputs.
///
/// # Fields
/// - `id`, `name`, `description`: Stable identifier and display text.
/// - `recipe_type`, `category`, `tags`: Recipe classification metadata.
/// - `station_type`, `station_level`, `required_nearby_stations`, `required_biome`, `required_location`: Station and environment requirements.
/// - `time`, `cooldown`, `fuel_consumption_rate`: Craft duration and fuel costs.
/// - `ingredients`, `outputs`, `remainder_item`: Input and output definitions.
/// - `skill`, `skill_level`, `skill_xp`, `skill_up_curve`, `orange_threshold`, `yellow_threshold`, `green_threshold`, `grey_threshold`: Skill gating and progression values.
/// - `enabled`, `hand_craftable`, `knowledge_mode`, `discovery_hint`: Availability and discovery behavior.
/// - `grid_width`, `grid_height`, `grid_slots`, `grid_mirror`, `grid_rotation`: Shaped recipe matching data.
/// - `upgrade_from`, `upgrade_to`, `alternatives`: Links to related recipes.
/// - `output_quality_scaling`, `random_modifier_pool`, `conditions`, `metadata`: Output modifiers and custom data.
#[derive(Debug, Clone)]
pub struct Recipe {
    pub id: String,
    /// Recipe processing mode: `"shapeless"`, `"shaped"`, `"smelting"`, `"modification"`,
    /// `"upgrade"`, `"combination"`, `"disassembly"`, `"aging"`, `"transmutation"`.
    pub recipe_type: String,
    pub name: String,
    pub description: String,
    /// UI category for grouping (e.g. `"weapons"`, `"food"`).
    pub category: String,
    pub station_type: String,
    pub station_level: u32,
    pub time: f64,
    pub cooldown: f64,
    /// Fuel consumed per second during timed crafting.
    pub fuel_consumption_rate: f64,
    pub ingredients: Vec<Ingredient>,
    pub outputs: Vec<RecipeOutput>,
    /// Item returned to inventory after craft (e.g. empty bucket).
    pub remainder_item: String,
    /// Skill name required, empty = none.
    pub skill: String,
    pub skill_level: u32,
    pub skill_xp: f64,
    pub enabled: bool,
    pub hand_craftable: bool,
    pub tags: Vec<String>,
    /// How the recipe is discovered: `"always"`, `"on_pickup"`, `"blueprint"`, `"prototype"`,
    /// `"skill_level"`, `"quest"`, `"discovery"`.
    pub knowledge_mode: String,
    /// Hint text shown before recipe is discovered.
    pub discovery_hint: String,
    /// For shaped recipes: grid width.
    pub grid_width: u32,
    /// For shaped recipes: grid height.
    pub grid_height: u32,
    /// Grid slot assignments: (x, y) → item_type (1-based).
    pub grid_slots: HashMap<(u32, u32), String>,
    /// Allow horizontal mirror matching for shaped recipes.
    pub grid_mirror: bool,
    /// Allow rotation matching for shaped recipes.
    pub grid_rotation: bool,
    /// Additional station types that must be nearby (Terraria union pattern).
    pub required_nearby_stations: Vec<String>,
    pub required_biome: String,
    pub required_location: String,
    /// WoW color-band thresholds for skill-up probability.
    pub orange_threshold: u32,
    pub yellow_threshold: u32,
    pub green_threshold: u32,
    pub grey_threshold: u32,
    /// ID of the recipe this one upgrades from (MHW tree pattern).
    pub upgrade_from: String,
    /// IDs of recipes this output can be upgraded to.
    pub upgrade_to: Vec<String>,
    /// Alternative recipe IDs producing equivalent output.
    pub alternatives: Vec<String>,
    /// Whether output quality scales with skill level.
    pub output_quality_scaling: bool,
    /// ID of the modifier pool to roll on completion.
    pub random_modifier_pool: String,
    /// XP curve name for skill-up: `"linear"`, `"quadratic"`, `"exponential"`.
    pub skill_up_curve: String,
    /// Conditions required to craft: `(condition_type, value)` pairs.
    pub conditions: Vec<(String, String)>,
    pub metadata: HashMap<String, String>,
}

impl Recipe {
    /// Create a new recipe with default crafting metadata.
    ///
    /// # Parameters
    /// - `id`: Stable recipe identifier.
    /// - `recipe_type`: Processing mode such as `"shapeless"` or `"smelting"`.
    ///
    /// # Returns
    /// A recipe initialized with sensible defaults and empty collections.
    pub fn new(id: impl Into<String>, recipe_type: impl Into<String>) -> Self {
        let id = id.into();
        let name = id.clone();
        Self {
            id,
            recipe_type: recipe_type.into(),
            name,
            description: String::new(),
            category: String::new(),
            station_type: String::new(),
            station_level: 0,
            time: 1.0,
            cooldown: 0.0,
            fuel_consumption_rate: 0.0,
            ingredients: Vec::new(),
            outputs: Vec::new(),
            remainder_item: String::new(),
            skill: String::new(),
            skill_level: 0,
            skill_xp: 0.0,
            enabled: true,
            hand_craftable: true,
            tags: Vec::new(),
            knowledge_mode: "always".into(),
            discovery_hint: String::new(),
            grid_width: 0,
            grid_height: 0,
            grid_slots: HashMap::new(),
            grid_mirror: false,
            grid_rotation: false,
            required_nearby_stations: Vec::new(),
            required_biome: String::new(),
            required_location: String::new(),
            orange_threshold: 0,
            yellow_threshold: 0,
            green_threshold: 0,
            grey_threshold: 0,
            upgrade_from: String::new(),
            upgrade_to: Vec::new(),
            alternatives: Vec::new(),
            output_quality_scaling: false,
            random_modifier_pool: String::new(),
            skill_up_curve: "linear".into(),
            conditions: Vec::new(),
            metadata: HashMap::new(),
        }
    }

    /// Append an ingredient requirement to the recipe.
    ///
    /// # Parameters
    /// - `ingredient`: Ingredient definition to append.
    pub fn add_ingredient(&mut self, ingredient: Ingredient) {
        self.ingredients.push(ingredient);
    }

    /// Append an output definition to the recipe.
    ///
    /// # Parameters
    /// - `output`: Output definition to append.
    pub fn add_output(&mut self, output: RecipeOutput) {
        self.outputs.push(output);
    }

    /// Remove all ingredients from this recipe.
    pub fn clear_ingredients(&mut self) {
        self.ingredients.clear();
    }

    /// Remove all outputs from this recipe. After this call the container is in the same state as immediately after construction.
    pub fn clear_outputs(&mut self) {
        self.outputs.clear();
    }

    /// Returns all tags on this recipe. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// A slice of recipe tag strings.
    pub fn get_tags(&self) -> &[String] { &self.tags }

    /// Check whether the recipe carries a tag. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `tag`: Tag string to test.
    ///
    /// # Returns
    /// `true` if the tag is present on the recipe.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }

    /// Set a grid slot for shaped recipe matching (1-based x, y).
    ///
    /// # Parameters
    /// - `x`: One-based grid column.
    /// - `y`: One-based grid row.
    /// - `item_type`: Item ID expected in the slot.
    pub fn set_grid_slot(&mut self, x: u32, y: u32, item_type: impl Into<String>) {
        self.grid_slots.insert((x, y), item_type.into());
    }

    /// Add a byproduct output to this recipe. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `item_type`: Item ID granted as a byproduct.
    /// - `quantity`: Number of items produced on success.
    /// - `chance`: Probability in `[0.0, 1.0]` that the byproduct is added.
    pub fn add_byproduct(&mut self, item_type: impl Into<String>, quantity: u32, chance: f64) {
        self.outputs.push(RecipeOutput {
            item_type: item_type.into(),
            quantity,
            quality: super::quality::Quality::Normal,
            chance,
            is_byproduct: true,
        });
    }

    /// Add a crafting condition (e.g. biome, weather, time-of-day).
    ///
    /// # Parameters
    /// - `condition_type`: Condition category such as `"biome"`.
    /// - `value`: Required value for the condition.
    pub fn add_condition(&mut self, condition_type: impl Into<String>, value: impl Into<String>) {
        self.conditions.push((condition_type.into(), value.into()));
    }

    /// Returns all crafting conditions as `(type, value)` pairs.
    ///
    /// # Returns
    /// A slice of condition pairs in insertion order.
    pub fn get_conditions(&self) -> &[(String, String)] { &self.conditions }
}

// ─────────────────────────────────────────────────────────────────────────────
// RecipeRegistry
// ─────────────────────────────────────────────────────────────────────────────

/// Central registry for all known recipes. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `recipes` — `HashMap<String`.
/// - `order` — `Vec<String>`.
#[derive(Debug, Default)]
pub struct RecipeRegistry {
    recipes: HashMap<String, Recipe>,
    order: Vec<String>,
}

impl RecipeRegistry {
    /// Create an empty recipe registry. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// A registry with no stored recipes.
    pub fn new() -> Self { Self::default() }

    /// Insert or replace a recipe in the registry.
    ///
    /// # Parameters
    /// - `recipe`: Recipe definition to store.
    pub fn add(&mut self, recipe: Recipe) {
        if !self.order.contains(&recipe.id) {
            self.order.push(recipe.id.clone());
        }
        self.recipes.insert(recipe.id.clone(), recipe);
    }

    /// Get an immutable recipe reference by ID.
    ///
    /// # Parameters
    /// - `id`: Recipe identifier to query.
    ///
    /// # Returns
    /// The stored recipe, if present.
    pub fn get(&self, id: &str) -> Option<&Recipe> { self.recipes.get(id) }

    /// Get a mutable recipe reference by ID. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id`: Recipe identifier to query.
    ///
    /// # Returns
    /// A mutable reference to the stored recipe, if present.
    pub fn get_mut(&mut self, id: &str) -> Option<&mut Recipe> { self.recipes.get_mut(id) }

    /// Remove a recipe from the registry. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id`: Recipe identifier to remove.
    ///
    /// # Returns
    /// `true` if the registry contained the recipe.
    pub fn remove(&mut self, id: &str) -> bool {
        self.order.retain(|s| s != id);
        self.recipes.remove(id).is_some()
    }

    /// Return the number of stored recipes. Runs in O(1) time.
    ///
    /// # Returns
    /// The total recipe count.
    pub fn count(&self) -> usize { self.recipes.len() }

    /// Return recipe IDs in insertion order. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// A slice of recipe IDs in registry order.
    pub fn ids(&self) -> &[String] { &self.order }

    /// Find recipe IDs whose outputs include the given item type.
    ///
    /// # Parameters
    /// - `item_type`: Output item ID to match.
    ///
    /// # Returns
    /// Matching recipe IDs in registry order.
    pub fn find_by_output(&self, item_type: &str) -> Vec<&str> {
        self.order.iter()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .filter(|r| r.outputs.iter().any(|o| o.item_type == item_type))
            .map(|r| r.id.as_str())
            .collect()
    }

    /// Find recipe IDs that require the given ingredient.
    ///
    /// # Parameters
    /// - `item_type`: Ingredient item ID to match.
    ///
    /// # Returns
    /// Matching recipe IDs in registry order.
    pub fn find_by_ingredient(&self, item_type: &str) -> Vec<&str> {
        self.order.iter()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .filter(|r| r.ingredients.iter().any(|i| i.item_type == item_type))
            .map(|r| r.id.as_str())
            .collect()
    }

    /// Find recipe IDs that have a specific tag.
    ///
    /// # Parameters
    /// - `tag`: Recipe tag to match.
    ///
    /// # Returns
    /// Matching recipe IDs in arbitrary hash-map order.
    pub fn find_by_tag(&self, tag: &str) -> Vec<&str> {
        self.recipes.iter()
            .filter(|(_, r)| r.tags.contains(&tag.to_string()))
            .map(|(id, _)| id.as_str())
            .collect()
    }

    /// Find recipe IDs whose station type matches (or is empty = any).
    ///
    /// # Parameters
    /// - `station_type`: Station type to match against recipe requirements.
    ///
    /// # Returns
    /// Matching recipe IDs in registry order.
    pub fn for_station(&self, station_type: &str) -> Vec<&str> {
        self.order.iter()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .filter(|r| r.station_type.is_empty() || r.station_type == station_type)
            .map(|r| r.id.as_str())
            .collect()
    }

    /// Find recipe IDs in a given category. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `category`: Category name to match.
    ///
    /// # Returns
    /// Matching recipe IDs in registry order.
    pub fn find_by_category(&self, category: &str) -> Vec<&str> {
        self.order.iter()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .filter(|r| r.category == category)
            .map(|r| r.id.as_str())
            .collect()
    }

    /// Find recipe IDs requiring a specific skill, optionally capped by max required level.
    ///
    /// # Parameters
    /// - `skill_name`: Required skill name to match.
    /// - `max_level`: Optional upper bound for recipe required level.
    ///
    /// # Returns
    /// Matching recipe IDs in registry order.
    pub fn find_by_skill(&self, skill_name: &str, max_level: Option<u32>) -> Vec<&str> {
        self.order.iter()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .filter(|r| {
                r.skill == skill_name
                    && max_level.is_none_or(|max| r.skill_level <= max)
            })
            .map(|r| r.id.as_str())
            .collect()
    }

    /// Find all recipe IDs that can be hand-crafted (no station required).
    ///
    /// # Returns
    /// Hand-craftable recipe IDs in registry order.
    pub fn find_hand_craftable(&self) -> Vec<&str> {
        self.order.iter()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .filter(|r| r.hand_craftable)
            .map(|r| r.id.as_str())
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recipe_basic() {
        let mut recipe = Recipe::new("sword", "shaped");
        recipe.add_ingredient(Ingredient::new("iron", 3));
        recipe.add_output(RecipeOutput::new("iron_sword", 1));
        assert_eq!(recipe.ingredients.len(), 1);
        assert_eq!(recipe.outputs.len(), 1);
    }

    #[test]
    fn recipe_category_and_hand_craftable() {
        let mut recipe = Recipe::new("potion", "shapeless");
        assert!(recipe.category.is_empty());
        recipe.category = "alchemy".into();
        assert_eq!(recipe.category, "alchemy");
        assert!(recipe.hand_craftable);
        recipe.hand_craftable = false;
        assert!(!recipe.hand_craftable);
    }

    #[test]
    fn recipe_cooldown() {
        let mut recipe = Recipe::new("heal", "shapeless");
        assert!((recipe.cooldown - 0.0).abs() < 1e-5);
        recipe.cooldown = 5.0;
        assert!((recipe.cooldown - 5.0).abs() < 1e-5);
    }

    #[test]
    fn recipe_grid_slot() {
        let mut recipe = Recipe::new("pickaxe", "shaped");
        recipe.grid_width = 3;
        recipe.grid_height = 3;
        recipe.set_grid_slot(1, 1, "diamond");
        assert_eq!(
            recipe.grid_slots.get(&(1, 1)).map(|slot| slot.as_str()),
            Some("diamond")
        );
    }

    #[test]
    fn recipe_registry_find_by_category() {
        let mut registry = RecipeRegistry::new();

        let mut sword = Recipe::new("sword", "shapeless");
        sword.category = "weapons".into();

        let mut shield = Recipe::new("shield", "shapeless");
        shield.category = "armor".into();

        registry.add(sword);
        registry.add(shield);

        assert_eq!(registry.find_by_category("weapons"), vec!["sword"]);
        assert_eq!(registry.find_by_category("armor"), vec!["shield"]);
    }

    #[test]
    fn registry_find_by_skill() {
        let mut registry = RecipeRegistry::new();

        let mut mithril = Recipe::new("mithril_sword", "shapeless");
        mithril.skill = "smithing".into();
        mithril.skill_level = 60;

        let mut iron = Recipe::new("iron_sword", "shapeless");
        iron.skill = "smithing".into();
        iron.skill_level = 10;

        registry.add(mithril);
        registry.add(iron);

        assert_eq!(registry.find_by_skill("smithing", None).len(), 2);
        assert_eq!(registry.find_by_skill("smithing", Some(50)).len(), 1);
    }
}
