//! RPG character sheet and stat system.
//!
//! Provides a flexible attribute system with buffs, derived stats, traits,
//! skills, perks, XP/levelling, action points, morale, and resistances.

//! # Integration with `combat`
//!
//! `stats` and `combat` are both Tier 3 gameplay modules.  Neither imports the
//! other — they communicate through Lua.
//!
//! Typical pattern:
//! ```lua
//! local sheet   = luna.stats.newSheet()
//! local fighter = luna.combat.newCombatant(
//!     "Hero",
//!     sheet:getStat("hp"),   -- pull HP from the stat sheet
//!     sheet:getStat("mp")
//! )
//! ```
//!
//! Any stat change during a battle (damage, healing) must be mirrored back to
//! the sheet by Lua; the engine does not synchronise them automatically.


/// How a buff stacks with existing buffs of the same name.
/// Stat attributes, buffs, and stack modes.
pub mod attribute;
pub use attribute::*;

/// Skills, perks, traits, action points, morale, level thresholds.
pub mod skill;
pub use skill::*;

/// Character sheet and stats registry.
pub mod sheet;
pub use sheet::*;
