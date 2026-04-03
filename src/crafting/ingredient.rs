//! Recipe ingredients and output definitions.
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for ingredient-related operations and data management.
//! Key types exported from this module: `Ingredient`, `RecipeOutput`.
//! Primary functions: `new()`, `new_tag()`, `is_tag()`, `new()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use super::quality::Quality;

/// An ingredient required by a recipe. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `item_type`: Concrete item ID required by the recipe when `tag` is empty.
/// - `quantity`: Number of matching items required.
/// - `consumed`: Whether the ingredient is spent when the craft completes.
/// - `tag`: Tag selector that can match multiple item IDs when non-empty.
#[derive(Debug, Clone)]
pub struct Ingredient {
    pub item_type: String,
    pub quantity: u32,
    /// If true, consumes the ingredient on craft; false = required present but not consumed.
    pub consumed: bool,
    /// If non-empty, any item with this tag satisfies the ingredient (e.g. `"#planks"`).
    pub tag: String,
}

impl Ingredient {
    /// Create a normal ingredient that is consumed on craft.
    ///
    /// # Parameters
    /// - `item_type`: Concrete item ID the recipe requires.
    /// - `quantity`: Number of items required.
    ///
    /// # Returns
    /// A consumed ingredient targeting a specific item type.
    pub fn new(item_type: impl Into<String>, quantity: u32) -> Self {
        Self {
            item_type: item_type.into(),
            quantity,
            consumed: true,
            tag: String::new(),
        }
    }

    /// Create a tag-based ingredient (any matching item satisfies it).
    ///
    /// # Parameters
    /// - `tag`: Tag selector, such as `"#planks"`.
    /// - `quantity`: Number of matching items required.
    ///
    /// # Returns
    /// A consumed ingredient resolved by tag instead of item ID.
    pub fn new_tag(tag: impl Into<String>, quantity: u32) -> Self {
        Self {
            item_type: String::new(),
            quantity,
            consumed: true,
            tag: tag.into(),
        }
    }

    /// Returns true if this is a tag-based ingredient.
    ///
    /// # Returns
    /// `true` when `tag` is non-empty.
    pub fn is_tag(&self) -> bool {
        !self.tag.is_empty()
    }
}

/// Output produced by a recipe. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `item_type`: Item ID granted by the recipe.
/// - `quantity`: Number of items produced.
/// - `quality`: Quality tier assigned to the output.
/// - `chance`: Probability in the inclusive range `[0.0, 1.0]`.
/// - `is_byproduct`: Whether this output is an auxiliary result instead of the main result.
#[derive(Debug, Clone)]
pub struct RecipeOutput {
    pub item_type: String,
    pub quantity: u32,
    pub quality: Quality,
    /// Probability (0.0–1.0) that this output is included. 1.0 = always.
    pub chance: f64,
    /// If true, this is a byproduct independent of the main output.
    pub is_byproduct: bool,
}

impl RecipeOutput {
    /// Create a guaranteed recipe output with normal quality.
    ///
    /// # Parameters
    /// - `item_type`: Item ID granted by the recipe.
    /// - `quantity`: Number of items produced.
    ///
    /// # Returns
    /// A non-byproduct output with `Quality::Normal` and `chance = 1.0`.
    pub fn new(item_type: impl Into<String>, quantity: u32) -> Self {
        Self {
            item_type: item_type.into(),
            quantity,
            quality: Quality::Normal,
            chance: 1.0,
            is_byproduct: false,
        }
    }

    /// Create a probabilistic output (0.0–1.0 chance per craft).
    ///
    /// # Parameters
    /// - `item_type`: Item ID granted by the recipe.
    /// - `quantity`: Number of items produced when the roll succeeds.
    /// - `chance`: Requested inclusion probability, clamped into `[0.0, 1.0]`.
    ///
    /// # Returns
    /// A non-byproduct output with `Quality::Normal` and the clamped chance value.
    pub fn with_chance(item_type: impl Into<String>, quantity: u32, chance: f64) -> Self {
        Self {
            item_type: item_type.into(),
            quantity,
            quality: Quality::Normal,
            chance: chance.clamp(0.0, 1.0),
            is_byproduct: false,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recipe_tag_input() {
        let ingredient = Ingredient::new_tag("#planks", 4);
        assert!(ingredient.is_tag());
        assert_eq!(ingredient.tag, "#planks");
        assert_eq!(ingredient.quantity, 4);
    }

    #[test]
    fn recipe_probabilistic_output() {
        let output = RecipeOutput::with_chance("rare_gem", 1, 0.1);
        assert!((output.chance - 0.1).abs() < 1e-5);
    }
}
