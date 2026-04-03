//! Stat attributes, stack mode, and buff descriptors.
//!
//! This module is part of Luna2D's `stats` subsystem and provides the implementation
//! details for attribute-related operations and data management.
//! Key types exported from this module: `StackMode`, `Buff`, `Attribute`.
//! Primary functions: `new()`, `is_expired()`, `new()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.


/// How a buff stacks with existing buffs of the same name.
///
/// # Variants
/// - `Reapplying` — Reapplying variant.
/// - `None` — None variant.
/// - `Duration` — Duration variant.
/// - `Intensity` — Intensity variant.
#[derive(Debug, Clone, PartialEq)]
pub enum StackMode {
    /// Reapplying the effect resets its duration.
    None,
    /// Reapplying extends the remaining duration.
    Duration,
    /// Reapplying adds a stack count (up to max_stacks).
    Intensity,
}

/// A single stat modifier attached to an attribute.
///
/// # Fields
/// - `stat` — `String`.
/// - `add` — `f64`.
/// - `mul` — `f64`.
/// - `duration` — `f64`.
/// - `source` — `String`.
/// - `remaining` — `f64`.
#[derive(Debug, Clone)]
pub struct Buff {
    /// Which attribute this buff modifies.
    pub stat: String,
    /// Additive bonus (added before multiply).
    pub add: f64,
    /// Multiplicative factor (default 1.0).
    pub mul: f64,
    /// Seconds until expiry. -1 = permanent.
    pub duration: f64,
    /// Descriptive source string.
    pub source: String,
    /// Remaining time in seconds.
    pub remaining: f64,
}

impl Buff {
    /// Create a new permanent buff. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `stat` — `&str`.
    /// - `add` — `f64`.
    /// - `l` — `f64`.
    /// - `duration` — `f64`.
    /// - `source` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(stat: &str, add: f64, mul: f64, duration: f64, source: &str) -> Self {
        let remaining = if duration < 0.0 {
            f64::NEG_INFINITY
        } else {
            duration
        };
        Self {
            stat: stat.to_string(),
            add,
            mul,
            duration,
            source: source.to_string(),
            remaining,
        }
    }

    /// Whether this buff has expired. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_expired(&self) -> bool {
        self.duration >= 0.0 && self.remaining <= 0.0
    }
}

/// A named stat attribute with base value, constraints, and regen.
///
/// # Fields
/// - `base` — `f64`.
/// - `min` — `f64`.
/// - `max` — `Option<f64>`.
/// - `regen` — `f64`.
/// - `growth` — `f64`.
#[derive(Debug, Clone)]
pub struct Attribute {
    /// Base value before buffs.
    pub base: f64,
    /// Minimum effective value.
    pub min: f64,
    /// Maximum effective value. None = unbounded.
    pub max: Option<f64>,
    /// Regeneration per second (applied during `update`).
    pub regen: f64,
    /// Growth per use (use-based levelling).
    pub growth: f64,
}

impl Attribute {
    /// Create a new attribute with the given base value.
    ///
    /// # Parameters
    /// - `base` — `f64`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(base: f64) -> Self {
        Self {
            base,
            min: f64::NEG_INFINITY,
            max: None,
            regen: 0.0,
            growth: 0.0,
        }
    }
}