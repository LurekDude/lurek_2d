//! Named resource economy system: capacity, flow rates, decay, interest,
//! upkeep, overflow policies, reservations, and conversions (Tier 3).
//!
//! Designed for RTS, management, survival, and RPG economy patterns where
//! the game tracks multiple named numeric values (gold, wood, mana, food)
//! that change over time with configurable rates.


/// Resource definition and overflow policy.
#[allow(clippy::module_inception)]
pub mod resource;
pub use resource::*;

/// Resource modifiers and conversion rules.
pub mod modifier;
pub use modifier::*;

/// ResourceManager: multi-resource economy coordinator.
pub mod manager;
pub use manager::*;
