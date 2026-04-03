//! Vehicle combat system: chassis, turrets, weapons, projectiles, and collision groups.
//!
//! Exposed to Lua via `luna.combat.*`.
//!
//! # Module Structure
//! - [`collision_groups`] — `CollisionGroupSet`
//! - [`chassis`]          — `Chassis`, `MountSlot`, `ArmorZone`
//! - [`weapon`]           — `Turret`, `Weapon`, `ProjectileType`
//! - [`projectile`]       — `Projectile`, `ProjectilePool`
//! - [`world`]            — `CombatWorld`

/// Named collision groups over physics category bits.
pub mod collision_groups;
/// Vehicle bodies, armor zones, and mount slots.
pub mod chassis;
/// Turrets, weapons, and projectile type metadata.
pub mod weapon;
/// Projectile instances and fixed-size projectile pools.
pub mod projectile;
/// Top-level vehicle combat world coordinator.
pub mod world;

pub use chassis::{ArmorZone, Chassis, MountSlot};
pub use collision_groups::CollisionGroupSet;
pub use projectile::{MAX_POOL_SIZE, Projectile, ProjectilePool};
pub use weapon::{ProjectileType, Turret, Weapon};
pub use world::CombatWorld;
