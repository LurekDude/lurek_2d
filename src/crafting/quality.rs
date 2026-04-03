//! Quality tier enum for crafted item outputs.
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for quality-related operations and data management.
//! Key types exported from this module: `Quality`.
//! Primary functions: `from_str()`, `as_str()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Output quality tiers for crafted items. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Normal`: Baseline crafted output.
/// - `Fine`: Slightly improved output.
/// - `Superior`: High-quality crafted output.
/// - `Excellent`: Rare premium output.
/// - `Masterwork`: Expert-tier output.
/// - `Legendary`: Exceptional top-tier output.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Quality {
    Normal = 0,
    Fine = 1,
    Superior = 2,
    Excellent = 3,
    Masterwork = 4,
    Legendary = 5,
}

impl Quality {
    #[allow(clippy::should_implement_trait)]
    /// Parse a lowercase quality name. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `s`: Lowercase quality name such as `"fine"` or `"legendary"`.
    ///
    /// # Returns
    /// The matching quality tier, or `None` if the string is not recognized.
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "normal" => Some(Self::Normal),
            "fine" => Some(Self::Fine),
            "superior" => Some(Self::Superior),
            "excellent" => Some(Self::Excellent),
            "masterwork" => Some(Self::Masterwork),
            "legendary" => Some(Self::Legendary),
            _ => None,
        }
    }

    /// Return the lowercase string name for this quality tier.
    ///
    /// # Returns
    /// The stable lowercase identifier for the quality.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Normal => "normal",
            Self::Fine => "fine",
            Self::Superior => "superior",
            Self::Excellent => "excellent",
            Self::Masterwork => "masterwork",
            Self::Legendary => "legendary",
        }
    }
}
