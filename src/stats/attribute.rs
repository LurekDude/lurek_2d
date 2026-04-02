//! Stat attributes, stack mode, and buff descriptors.


/// How a buff stacks with existing buffs of the same name.
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
    /// Create a new permanent buff.
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

    /// Whether this buff has expired.
    pub fn is_expired(&self) -> bool {
        self.duration >= 0.0 && self.remaining <= 0.0
    }
}

/// A named stat attribute with base value, constraints, and regen.
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