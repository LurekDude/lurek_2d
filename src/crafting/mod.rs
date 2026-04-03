//! Mod implementation for the `crafting` subsystem.
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
//! Crafting system: recipes, ingredients, stations, skill progression, and craft queues.
//!
//! Exposed to Lua via `luna.crafting.*`.
//!
//! # Module layout
//!
//! | File | Contents |
//! |------|----------|
//! | `quality.rs` | [`Quality`] tier enum |
//! | `ingredient.rs` | [`Ingredient`], [`RecipeOutput`] |
//! | `recipe.rs` | [`Recipe`], [`RecipeRegistry`] |
//! | `station.rs` | [`Station`] |
//! | `skill.rs` | [`CraftSkill`], [`PerkNode`] |
//! | `queue.rs` | [`CraftJob`], [`CraftQueue`] |
//! | `upgrade.rs` | [`UpgradeNode`], [`UpgradeTree`] |
//! | `knowledge.rs` | [`RecipeKnowledge`], [`RecipeGroup`] |
//! | `modifier_pool.rs` | [`ModifierPool`], [`ModifierEntry`] |

/// Ingredient and recipe output types.
pub mod ingredient;
/// Recipe discovery and grouping types.
pub mod knowledge;
/// Weighted modifier pools for random rolls.
pub mod modifier_pool;
/// Crafted item quality tiers.
pub mod quality;
/// Timed crafting job queue types.
pub mod queue;
/// Recipe definitions and registry types.
pub mod recipe;
/// Crafting skill, perks, and specialization types.
pub mod skill;
/// Crafting station requirements and state.
pub mod station;
/// Upgrade tree types for item progression.
pub mod upgrade;

pub use ingredient::{Ingredient, RecipeOutput};
pub use knowledge::{RecipeGroup, RecipeKnowledge};
pub use quality::Quality;
pub use queue::{CraftJob, CraftQueue};
pub use recipe::{Recipe, RecipeRegistry};
pub use skill::{CraftSkill, PerkNode};
pub use modifier_pool::{ModifierEntry, ModifierPool};
pub use station::Station;
pub use upgrade::{UpgradeNode, UpgradeTree};
