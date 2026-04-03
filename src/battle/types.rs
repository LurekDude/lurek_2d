//! Turn-based battle primitive types: damage kinds, status effects, and action results.
//!
//! This module is part of Luna2D's `battle` subsystem and provides the implementation
//! details for types-related operations and data management.
//! Key types exported from this module: `DamageType`, `StatusEffect`, `CombatResult`.
//! Primary functions: `from_str()`, `as_str()`, `new()`, `tick_turn()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

/// Kind of damage used for resistance lookups.
///
/// Matched against a combatant's `resistances` map during `take_damage`.
/// The `Custom` variant accepts any game-defined damage category.
///
/// # Variants
/// - `Physical` — blunt, slash, piercing — unmodified by elemental resist.
/// - `Fire` — fire element.
/// - `Ice` — ice element.
/// - `Lightning` — lightning element.
/// - `Poison` — poison element.
/// - `Arcane` — arcane element.
/// - `Custom(String)` — game-defined damage type string.
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
    /// Creates a damage type from its Lua-facing string representation.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Returns the Lua-facing lowercase string for this damage type.
    ///
    /// # Returns
    /// `&str`.
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

/// An active status effect on a combatant. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Tracks name, remaining duration, stack count, and arbitrary string metadata.
/// Stacks increment when an effect of the same name is applied again; duration
/// is replaced when the new effect has a longer remaining time.
///
/// # Fields
/// - `name` — `String`.
/// - `duration` — `i32`.
/// - `stacks` — `u32`.
/// - `data` — `HashMap<String, String>`.
#[derive(Debug, Clone)]
pub struct StatusEffect {
    pub name: String,
    pub duration: i32,
    pub stacks: u32,
    pub data: HashMap<String, String>,
}

impl StatusEffect {
    /// Creates a new status effect with a name and turn duration.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `duration` — `i32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>, duration: i32) -> Self {
        Self {
            name: name.into(),
            duration,
            stacks: 1,
            data: HashMap::new(),
        }
    }

    /// Ticks one turn and returns true when the effect expires.
    ///
    /// # Returns
    /// `bool` — `true` when duration reaches zero.
    pub fn tick_turn(&mut self) -> bool {
        if self.duration > 0 {
            self.duration -= 1;
        }
        self.duration == 0
    }

    /// Returns true when the effect duration reached zero.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_expired(&self) -> bool {
        self.duration == 0
    }
}

/// Result of a single turn-based combat action.
///
/// Returned by `CombatBattle::resolve_action` and appended to the battle log.
/// Contains the attacker/target names, whether the attack hit, how much damage
/// was dealt, and whether the target died as a result.
///
/// # Fields
/// - `attacker` — `String`.
/// - `target` — `String`.
/// - `action` — `String`.
/// - `hit` — `bool`.
/// - `damage` — `f64`.
/// - `damage_type` — `String`.
/// - `target_died` — `bool`.
/// - `message` — `String`.
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
