//! Turn-based combat system: combatants, actions, damage types, teams, and turn order.
//!
//! Exposed to Lua via `luna.combat.*`.
//!
//! # Module Structure
//! - [`types`]     — `DamageType`, `StatusEffect`, `CombatResult`
//! - [`action`]    — `CombatAction`
//! - [`combatant`] — `Combatant`
//! - [`battle`]    — `CombatBattle`

//! # Integration with `stats`
//!
//! `combat` and `stats` are both Tier 3 gameplay modules.  Neither imports the
//! other — they communicate through Lua.
//!
//! A `Combatant` holds its own HP/MP values independently of any `StatSheet`.
//! To seed a combatant from a character sheet, read the sheet values in Lua and
//! pass them to `luna.combat.newCombatant`.  After the battle, write results
//! (e.g. remaining HP) back to the sheet:
//!
//! ```lua
//! -- Before battle
//! fighter:setHp(sheet:getStat("hp"))
//! -- After battle
//! sheet:setStat("hp", fighter:getHp())
//! ```

pub mod types;
pub mod action;
pub mod combatant;
pub mod battle;

pub use types::{DamageType, StatusEffect, CombatResult};
pub use action::CombatAction;
pub use combatant::Combatant;
pub use battle::CombatBattle;
