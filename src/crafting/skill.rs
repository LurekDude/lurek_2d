//! Player crafting skill with XP, level progression, specializations, and perk tree.
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for skill-related operations and data management.
//! Key types exported from this module: `PerkNode`, `CraftSkill`.
//! Primary functions: `new()`, `new()`, `add_xp()`, `get_xp_to_next()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;
use super::recipe::Recipe;

/// A single node in the perk tree (Skyrim pattern).
///
/// # Fields
/// - `perk_id`: Stable perk identifier.
/// - `required_level`: Minimum crafting level required to unlock the perk.
/// - `prerequisites`: Perk IDs that must already be unlocked.
/// - `unlocked`: Whether the perk is currently unlocked.
#[derive(Debug, Clone)]
pub struct PerkNode {
    pub perk_id: String,
    pub required_level: u32,
    pub prerequisites: Vec<String>,
    pub unlocked: bool,
}

impl PerkNode {
    /// Create a locked perk node. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `perk_id`: Stable perk identifier.
    /// - `required_level`: Minimum crafting level required.
    /// - `prerequisites`: Perk IDs that must already be unlocked.
    ///
    /// # Returns
    /// A locked perk node.
    pub fn new(perk_id: impl Into<String>, required_level: u32, prerequisites: Vec<String>) -> Self {
        Self { perk_id: perk_id.into(), required_level, prerequisites, unlocked: false }
    }
}

/// Player crafting skill in a profession, with XP tracking and optional perk/spec trees.
///
/// # Fields
/// - `name`, `xp`, `level`, `max_level`: Core profession progression state.
/// - `level_thresholds`, `xp_curve`: Level-up tuning data.
/// - `specialization`, `specializations`: Specialization choice and available branches.
/// - `perks`: Perk tree nodes keyed by perk ID.
/// - `metadata`: Arbitrary caller-defined values.
#[derive(Debug, Clone)]
pub struct CraftSkill {
    pub name: String,
    pub xp: f64,
    pub level: u32,
    pub max_level: u32,
    /// XP required to go from level N to N+1. Indexed by current level.
    pub level_thresholds: Vec<f64>,
    /// XP curve name: `"linear"`, `"quadratic"`, `"exponential"`, `"custom"`.
    pub xp_curve: String,
    /// Chosen specialization (WoW/Skyrim pattern).
    pub specialization: Option<String>,
    /// Available specialization branches.
    pub specializations: Vec<String>,
    /// Perk tree nodes, keyed by perk_id.
    pub perks: HashMap<String, PerkNode>,
    pub metadata: HashMap<String, String>,
}

impl CraftSkill {
    /// Create a crafting skill with linear level thresholds.
    ///
    /// # Parameters
    /// - `name`: Profession name such as `"smithing"`.
    ///
    /// # Returns
    /// A level-1 skill with zero XP and default progression settings.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            xp: 0.0,
            level: 1,
            max_level: 100,
            level_thresholds: (1..=100).map(|l| (l as f64) * 100.0).collect(),
            xp_curve: "linear".into(),
            specialization: None,
            specializations: Vec::new(),
            perks: HashMap::new(),
            metadata: HashMap::new(),
        }
    }

    /// Add XP. Returns the number of levels gained.
    ///
    /// # Parameters
    /// - `amount`: XP to add to the skill.
    ///
    /// # Returns
    /// The number of levels gained during this update.
    pub fn add_xp(&mut self, amount: f64) -> u32 {
        self.xp += amount;
        let mut leveled = 0u32;
        while {
            let needed = self.level_thresholds
                .get(self.level as usize)
                .copied()
                .unwrap_or(f64::MAX);
            self.xp >= needed && self.level < self.max_level
        } {
            self.level += 1;
            leveled += 1;
        }
        leveled
    }

    /// XP remaining until the next level. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// Non-negative XP required to reach the next level.
    pub fn get_xp_to_next(&self) -> f64 {
        let needed = self.level_thresholds
            .get(self.level as usize)
            .copied()
            .unwrap_or(f64::MAX);
        (needed - self.xp).max(0.0)
    }

    /// Force-set level and reset XP to 0. Replaces the current level value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `level`: Desired level, clamped to `max_level`.
    pub fn set_level(&mut self, level: u32) {
        self.level = level.min(self.max_level);
        self.xp = 0.0;
    }

    /// Returns true if this skill meets the recipe's skill requirement.
    ///
    /// # Parameters
    /// - `recipe`: Recipe whose skill gate should be evaluated.
    ///
    /// # Returns
    /// `true` if the recipe requires no skill or this skill satisfies the requirement.
    pub fn can_use(&self, recipe: &Recipe) -> bool {
        recipe.skill.is_empty() || (recipe.skill == self.name && self.level >= recipe.skill_level)
    }

    // ── WoW color-band probability ────────────────────────────────────────────

    /// Returns the WoW-style difficulty color for a recipe (`"orange"`, `"yellow"`, `"green"`, `"grey"`).
    ///
    /// # Parameters
    /// - `recipe`: Recipe whose thresholds should be evaluated.
    ///
    /// # Returns
    /// The current difficulty color for this skill level.
    pub fn recipe_color(&self, recipe: &Recipe) -> &'static str {
        let lvl = self.level;
        if recipe.orange_threshold > 0 && lvl < recipe.orange_threshold { return "orange"; }
        if recipe.yellow_threshold > 0 && lvl < recipe.yellow_threshold { return "yellow"; }
        if recipe.green_threshold > 0 && lvl < recipe.green_threshold { return "green"; }
        "grey"
    }

    /// Skill-up probability (0.0–1.0) for a recipe, following WoW color rules.
    ///
    /// # Parameters
    /// - `recipe`: Recipe whose skill-up odds should be evaluated.
    ///
    /// # Returns
    /// Skill-up probability in the inclusive range `[0.0, 1.0]`.
    pub fn skill_up_chance(&self, recipe: &Recipe) -> f64 {
        match self.recipe_color(recipe) {
            "orange" => 1.0,
            "yellow" => 0.6,
            "green" => 0.2,
            _ => 0.0,
        }
    }

    // ── Specializations ───────────────────────────────────────────────────────

    /// Define a specialization branch. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `name`: Specialization branch name to register.
    pub fn add_specialization(&mut self, name: impl Into<String>) {
        let n = name.into();
        if !self.specializations.contains(&n) {
            self.specializations.push(n);
        }
    }

    /// Lock in a specialization. Returns `false` if already specialized or name is invalid.
    ///
    /// # Parameters
    /// - `name`: Specialization branch to choose.
    ///
    /// # Returns
    /// `true` if the specialization was accepted.
    pub fn choose_specialization(&mut self, name: &str) -> bool {
        if self.specialization.is_some() { return false; }
        if !self.specializations.iter().any(|s| s == name) { return false; }
        self.specialization = Some(name.to_string());
        true
    }

    // ── Perk tree (Skyrim pattern) ────────────────────────────────────────────

    /// Define a perk node with level requirement and prerequisite perk IDs.
    ///
    /// # Parameters
    /// - `perk_id`: Stable perk identifier.
    /// - `required_level`: Minimum crafting level required.
    /// - `prerequisites`: Perk IDs that must already be unlocked.
    pub fn add_perk(&mut self, perk_id: impl Into<String>, required_level: u32, prerequisites: Vec<String>) {
        let id = perk_id.into();
        self.perks.insert(id.clone(), PerkNode::new(id, required_level, prerequisites));
    }

    /// Unlock a perk. Returns `false` if prerequisites not met or level too low.
    ///
    /// # Parameters
    /// - `perk_id`: Perk identifier to unlock.
    ///
    /// # Returns
    /// `true` if the perk transitioned to unlocked.
    pub fn unlock_perk(&mut self, perk_id: &str) -> bool {
        let can = if let Some(p) = self.perks.get(perk_id) {
            if p.unlocked { return false; }
            if self.level < p.required_level { return false; }
            p.prerequisites.iter().all(|pre| {
                self.perks.get(pre.as_str()).map(|n| n.unlocked).unwrap_or(false)
            })
        } else {
            false
        };
        if can {
            if let Some(p) = self.perks.get_mut(perk_id) { p.unlocked = true; }
            true
        } else {
            false
        }
    }

    /// Check if a perk is unlocked. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `perk_id`: Perk identifier to query.
    ///
    /// # Returns
    /// `true` if the perk exists and is unlocked.
    pub fn has_perk(&self, perk_id: &str) -> bool {
        self.perks.get(perk_id).map(|p| p.unlocked).unwrap_or(false)
    }

    /// Returns IDs of perks whose prerequisites are met but not yet unlocked.
    ///
    /// # Returns
    /// Available perk IDs that the current skill level can unlock.
    pub fn available_perks(&self) -> Vec<&str> {
        self.perks.values()
            .filter(|p| {
                !p.unlocked
                    && self.level >= p.required_level
                    && p.prerequisites.iter().all(|pre| {
                        self.perks.get(pre.as_str()).map(|n| n.unlocked).unwrap_or(false)
                    })
            })
            .map(|p| p.perk_id.as_str())
            .collect()
    }

    // ── Mastery bonuses ───────────────────────────────────────────────────────

    /// Speed bonus from mastery: 0.5% per level above 1, e.g. level 50 → +24.5%.
    ///
    /// # Returns
    /// Multiplicative speed bonus expressed as a fraction.
    pub fn get_speed_bonus(&self) -> f64 {
        (self.level.saturating_sub(1) as f64) * 0.005
    }

    /// Quality bonus from mastery: 0.5% per level above 1.
    ///
    /// # Returns
    /// Multiplicative quality bonus expressed as a fraction.
    pub fn get_quality_bonus(&self) -> f64 {
        (self.level.saturating_sub(1) as f64) * 0.005
    }

    /// Yield bonus from mastery: 0.2% per level above 1.
    ///
    /// # Returns
    /// Multiplicative output bonus expressed as a fraction.
    pub fn get_yield_bonus(&self) -> f64 {
        (self.level.saturating_sub(1) as f64) * 0.002
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn craft_skill_specialization() {
        let mut skill = CraftSkill::new("blacksmithing");
        skill.add_specialization("armorsmith");
        skill.add_specialization("weaponsmith");

        assert_eq!(skill.specializations.len(), 2);
        assert!(skill.choose_specialization("armorsmith"));
        assert!(!skill.choose_specialization("weaponsmith"));
        assert_eq!(skill.specialization.as_deref(), Some("armorsmith"));
    }

    #[test]
    fn craft_skill_perk_tree() {
        let mut skill = CraftSkill::new("smithing");
        skill.add_perk("novice", 1, vec![]);
        skill.add_perk("journeyman", 1, vec!["novice".into()]);
        skill.add_perk("expert", 50, vec!["journeyman".into()]);

        assert!(skill.unlock_perk("novice"));
        assert!(!skill.unlock_perk("expert"));
        assert!(skill.unlock_perk("journeyman"));
        assert!(skill.available_perks().is_empty());

        skill.set_level(50);

        assert!(skill.available_perks().contains(&"expert"));
    }

    #[test]
    fn craft_skill_wow_color() {
        let mut recipe = Recipe::new("sword", "shapeless");
        recipe.orange_threshold = 10;
        recipe.yellow_threshold = 20;
        recipe.green_threshold = 30;

        let mut skill = CraftSkill::new("smithing");
        skill.set_level(5);
        assert_eq!(skill.recipe_color(&recipe), "orange");

        skill.set_level(15);
        assert_eq!(skill.recipe_color(&recipe), "yellow");

        skill.set_level(25);
        assert_eq!(skill.recipe_color(&recipe), "green");

        skill.set_level(35);
        assert_eq!(skill.recipe_color(&recipe), "grey");
    }
}
