//! CombatWorld: top-level coordinator for the vehicle/weapon/projectile combat system.
//!
//! Manages all combat entities: chassis, turrets, weapons, and projectile pools.
//! The Lua layer coordinates between `CombatWorld` and the physics `World`.

use crate::combat::chassis::Chassis;
use crate::combat::collision_groups::CollisionGroupSet;
use crate::combat::projectile::ProjectilePool;
use crate::combat::weapon::{Turret, Weapon};

/// Manages all combat entities: chassis, turrets, weapons, and projectile pools.
#[derive(Clone)]
pub struct CombatWorld {
    /// All vehicle chassis in the combat world.
    pub chassis_list: Vec<Chassis>,
    /// All turrets (may be attached to chassis or free-standing).
    pub turrets: Vec<Turret>,
    /// All weapons (may be mounted on turrets or used standalone).
    pub weapons: Vec<Weapon>,
    /// Pre-allocated projectile pools.
    pub pools: Vec<ProjectilePool>,
    /// Named collision group configuration.
    pub collision_groups: CollisionGroupSet,
}

impl CombatWorld {
    /// Creates an empty combat world.
    pub fn new() -> Self {
        Self {
            chassis_list: Vec::new(),
            turrets: Vec::new(),
            weapons: Vec::new(),
            pools: Vec::new(),
            collision_groups: CollisionGroupSet::new(),
        }
    }

    /// Adds a chassis and returns its index.
    pub fn add_chassis(&mut self, chassis: Chassis) -> usize {
        self.chassis_list.push(chassis);
        self.chassis_list.len() - 1
    }

    /// Returns a reference to the chassis at the given index.
    pub fn get_chassis(&self, index: usize) -> Option<&Chassis> {
        self.chassis_list.get(index)
    }

    /// Returns a mutable reference to the chassis at the given index.
    pub fn get_chassis_mut(&mut self, index: usize) -> Option<&mut Chassis> {
        self.chassis_list.get_mut(index)
    }

    /// Adds a turret and returns its index.
    pub fn add_turret(&mut self, turret: Turret) -> usize {
        self.turrets.push(turret);
        self.turrets.len() - 1
    }

    /// Returns a reference to the turret at the given index.
    pub fn get_turret(&self, index: usize) -> Option<&Turret> {
        self.turrets.get(index)
    }

    /// Returns a mutable reference to the turret at the given index.
    pub fn get_turret_mut(&mut self, index: usize) -> Option<&mut Turret> {
        self.turrets.get_mut(index)
    }

    /// Adds a weapon and returns its index.
    pub fn add_weapon(&mut self, weapon: Weapon) -> usize {
        self.weapons.push(weapon);
        self.weapons.len() - 1
    }

    /// Returns a reference to the weapon at the given index.
    pub fn get_weapon(&self, index: usize) -> Option<&Weapon> {
        self.weapons.get(index)
    }

    /// Returns a mutable reference to the weapon at the given index.
    pub fn get_weapon_mut(&mut self, index: usize) -> Option<&mut Weapon> {
        self.weapons.get_mut(index)
    }

    /// Adds a projectile pool and returns its index.
    pub fn add_pool(&mut self, pool: ProjectilePool) -> usize {
        self.pools.push(pool);
        self.pools.len() - 1
    }

    /// Returns a reference to the projectile pool at the given index.
    pub fn get_pool(&self, index: usize) -> Option<&ProjectilePool> {
        self.pools.get(index)
    }

    /// Returns a mutable reference to the projectile pool at the given index.
    pub fn get_pool_mut(&mut self, index: usize) -> Option<&mut ProjectilePool> {
        self.pools.get_mut(index)
    }

    /// Returns the total number of active projectiles across all pools.
    pub fn active_projectile_count(&self) -> usize {
        self.pools.iter().map(|p| p.active_count()).sum()
    }

    /// Returns the number of non-destroyed chassis.
    pub fn active_chassis_count(&self) -> usize {
        self.chassis_list.iter().filter(|c| !c.destroyed).count()
    }

    /// Updates all weapons cooldowns and turret rotation targets.
    pub fn update(&mut self, dt: f32) {
        for weapon in &mut self.weapons {
            weapon.update_cooldown(dt);
        }
    }

    /// Clears all combat entities and collision groups.
    pub fn reset(&mut self) {
        self.chassis_list.clear();
        self.turrets.clear();
        self.weapons.clear();
        self.pools.clear();
        self.collision_groups.reset();
    }

    /// Removes destroyed chassis from the list.
    ///
    /// **Note:** This invalidates indices. Callers should update any stored
    /// references after calling this method.
    pub fn cleanup(&mut self) {
        self.chassis_list.retain(|c| !c.destroyed);
    }
}

impl Default for CombatWorld {
    fn default() -> Self {
        Self::new()
    }
}
