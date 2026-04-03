//! Skills, perks, trait definitions, action points, morale, and level thresholds.
//!
//! This module is part of Luna2D's `stats` subsystem and provides the implementation
//! details for skill-related operations and data management.
//! Key types exported from this module: `Skill`, `Perk`, `TraitDef`, `ActionPoints`, `Morale`.
//! Primary functions: `new()`, `new()`, `new()`, `new()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// A named skill with cooldown, resource cost, and level tracking.
///
/// # Fields
/// - `level` — `u32`.
/// - `max_level` — `u32`.
/// - `resource` — `String`.
/// - `cost` — `f64`.
/// - `cooldown` — `f64`.
/// - `cooldown_remaining` — `f64`.
/// - `passive_active` — `bool`.
#[derive(Debug, Clone)]
pub struct Skill {
    /// Current level (0 = not learned).
    pub level: u32,
    /// Maximum level.
    pub max_level: u32,
    /// Resource name consumed on use.
    pub resource: String,
    /// Amount of resource consumed.
    pub cost: f64,
    /// Cooldown in seconds.
    pub cooldown: f64,
    /// Remaining cooldown in seconds.
    pub cooldown_remaining: f64,
    /// Whether passive is currently active.
    pub passive_active: bool,
}

impl Skill {
    /// Create a new skill definition. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `ax_level` — `u32`.
    /// - `resource` — `&str`.
    /// - `cost` — `f64`.
    /// - `cooldown` — `f64`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(max_level: u32, resource: &str, cost: f64, cooldown: f64) -> Self {
        Self {
            level: 0,
            max_level,
            resource: resource.to_string(),
            cost,
            cooldown,
            cooldown_remaining: 0.0,
            passive_active: false,
        }
    }
}

/// A named perk requiring a minimum level to acquire.
///
/// # Fields
/// - `require_level` — `u32`.
/// - `trait_name` — `Option<String>`.
/// - `acquired` — `bool`.
#[derive(Debug, Clone)]
pub struct Perk {
    /// Minimum character level required to acquire.
    pub require_level: u32,
    /// Optional trait applied when acquired.
    pub trait_name: Option<String>,
    /// Whether this perk has been acquired.
    pub acquired: bool,
}

impl Perk {
    /// Create a new perk definition. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `require_level` — `u32`.
    /// - `rait_name` — `Option<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(require_level: u32, trait_name: Option<String>) -> Self {
        Self {
            require_level,
            trait_name,
            acquired: false,
        }
    }
}

/// A named trait definition (a bundle of buff descriptors).
///
/// # Fields
/// - `s` — `(stat`.
/// - `buffs` — `Vec<(String`.
#[derive(Debug, Clone)]
pub struct TraitDef {
    /// Buff descriptors: (stat, add, mul) tuples.
    pub buffs: Vec<(String, f64, f64)>,
}

/// Action point tracking for turn-based games.
///
/// # Fields
/// - `current` — `f64`.
/// - `max` — `f64`.
#[derive(Debug, Clone)]
pub struct ActionPoints {
    /// Current action points available.
    pub current: f64,
    /// Maximum action points.
    pub max: f64,
}

impl ActionPoints {
    /// Create action points with the given max.
    ///
    /// # Parameters
    /// - `ax` — `f64`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(max: f64) -> Self {
        Self { current: max, max }
    }
}

/// Morale state with panic/berserk thresholds.
///
/// # Fields
/// - `current` — `f64`.
/// - `max` — `f64`.
/// - `panic_threshold` — `f64`.
/// - `berserk_threshold` — `f64`.
#[derive(Debug, Clone)]
pub struct Morale {
    /// Current morale value.
    pub current: f64,
    /// Maximum morale value.
    pub max: f64,
    /// Morale below which the unit panics.
    pub panic_threshold: f64,
    /// Morale below which the unit goes berserk.
    pub berserk_threshold: f64,
}

impl Morale {
    /// Create morale with the given max (current starts at max).
    ///
    /// # Parameters
    /// - `ax` — `f64`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(max: f64) -> Self {
        Self {
            current: max,
            max,
            panic_threshold: 25.0,
            berserk_threshold: 10.0,
        }
    }
}

/// Level threshold setting: either a static table or a formula.
///
/// # Variants
/// - `P` — P variant.
/// - `Table` — Table variant.
/// - `Linear` — Linear variant.
#[derive(Debug, Clone)]
pub enum LevelThresholds {
    /// XP required to reach each level (1-indexed: thresholds[0] = XP for level 2).
    Table(Vec<f64>),
    /// Linear formula: base + (level - 1) * increment.
    Linear { base: f64, increment: f64 },
}

impl LevelThresholds {
    /// Default: 100 XP per level. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Self`.
    pub fn default_linear() -> Self {
        Self::Linear {
            base: 100.0,
            increment: 100.0,
        }
    }

    /// Get the XP threshold for the given level (level 1 = index 0 → returns threshold for level 2).
    ///
    /// # Parameters
    /// - `level` — `u32`.
    ///
    /// # Returns
    /// `f64`.
    pub fn threshold_for(&self, level: u32) -> f64 {
        match self {
            Self::Table(v) => {
                let idx = (level as usize).saturating_sub(1);
                if idx < v.len() {
                    v[idx]
                } else {
                    f64::INFINITY
                }
            }
            Self::Linear { base, increment } => base + (level as f64 - 1.0) * increment,
        }
    }
}