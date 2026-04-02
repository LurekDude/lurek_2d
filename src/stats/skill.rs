//! Skills, perks, trait definitions, action points, morale, and level thresholds.

/// A named skill with cooldown, resource cost, and level tracking.
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
    /// Create a new skill definition.
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
    /// Create a new perk definition.
    pub fn new(require_level: u32, trait_name: Option<String>) -> Self {
        Self {
            require_level,
            trait_name,
            acquired: false,
        }
    }
}

/// A named trait definition (a bundle of buff descriptors).
#[derive(Debug, Clone)]
pub struct TraitDef {
    /// Buff descriptors: (stat, add, mul) tuples.
    pub buffs: Vec<(String, f64, f64)>,
}

/// Action point tracking for turn-based games.
#[derive(Debug, Clone)]
pub struct ActionPoints {
    /// Current action points available.
    pub current: f64,
    /// Maximum action points.
    pub max: f64,
}

impl ActionPoints {
    /// Create action points with the given max.
    pub fn new(max: f64) -> Self {
        Self { current: max, max }
    }
}

/// Morale state with panic/berserk thresholds.
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
#[derive(Debug, Clone)]
pub enum LevelThresholds {
    /// XP required to reach each level (1-indexed: thresholds[0] = XP for level 2).
    Table(Vec<f64>),
    /// Linear formula: base + (level - 1) * increment.
    Linear { base: f64, increment: f64 },
}

impl LevelThresholds {
    /// Default: 100 XP per level.
    pub fn default_linear() -> Self {
        Self::Linear {
            base: 100.0,
            increment: 100.0,
        }
    }

    /// Get the XP threshold for the given level (level 1 = index 0 → returns threshold for level 2).
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