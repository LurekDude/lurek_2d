//! Turn-based battle system: combatants, actions, damage types, teams, and turn order.
//!
//! Exposed to Lua via `luna.battle.*`.
//!
//! # Module Structure
//! - [`types`]     — `DamageType`, `StatusEffect`, `CombatResult`
//! - [`action`]    — `CombatAction`
//! - [`combatant`] — `Combatant`
//! - [`battle`]    — `CombatBattle`
//!
//! # Integration with `stats`
//!
//! `battle` and `stats` are both Tier 3 gameplay modules. Neither imports the
//! other directly; they communicate through Lua.

/// Turn-based battle primitive types.
pub mod types;
/// Turn-based actions and ability data.
pub mod action;
/// Turn-based battle participants.
pub mod combatant;
/// Turn-based battle lifecycle and turn order.
pub mod lifecycle;

pub use action::CombatAction;
pub use lifecycle::CombatBattle;
pub use combatant::Combatant;
pub use types::{CombatResult, DamageType, StatusEffect};
