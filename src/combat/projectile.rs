//! Projectile and ProjectilePool for efficient projectile management.
//!
//! Projectiles are pre-allocated in pools to avoid per-frame heap allocation.
//! Each pool manages a fixed set of projectile slots that can be spawned and
//! released as needed.

use crate::combat::weapon::ProjectileType;

/// Maximum number of projectiles in a single pool.
pub const MAX_POOL_SIZE: usize = 1024;

/// A single in-flight projectile. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `body_id` — `usize`.
/// - `active` — `bool`.
/// - `lifetime` — `f32`.
/// - `distance_traveled` — `f32`.
/// - `max_range` — `f32`.
/// - `speed` — `f32`.
/// - `projectile_type` — `ProjectileType`.
/// - `damage_amount` — `f32`.
/// - `damage_type` — `String`.
/// - `source_weapon_name` — `String`.
/// - `target_pos` — `Option<(f32`.
/// - `target_body` — `Option<usize>`.
/// - `tracking_strength` — `f32`.
/// - `turn_rate` — `f32`.
#[derive(Clone)]
pub struct Projectile {
    /// Physics body ID for this projectile.
    pub body_id: usize,
    /// Whether this projectile slot is currently active.
    pub active: bool,
    /// Seconds this projectile has been alive.
    pub lifetime: f32,
    /// Total distance traveled in world units.
    pub distance_traveled: f32,
    /// Maximum range before the projectile expires.
    pub max_range: f32,
    /// Travel speed in world units per second.
    pub speed: f32,
    /// Type of projectile.
    pub projectile_type: ProjectileType,
    /// Damage dealt on hit.
    pub damage_amount: f32,
    /// Damage type tag.
    pub damage_type: String,
    /// Name of the weapon that fired this projectile.
    pub source_weapon_name: String,
    /// Target position for homing projectiles.
    pub target_pos: Option<(f32, f32)>,
    /// Target body ID for homing projectiles.
    pub target_body: Option<usize>,
    /// Homing tracking strength (0.0–1.0).
    pub tracking_strength: f32,
    /// Homing turn rate in radians per second.
    pub turn_rate: f32,
}

impl Projectile {
    /// Resets this projectile to its default inactive state.
    pub fn reset(&mut self) {
        self.active = false;
        self.lifetime = 0.0;
        self.distance_traveled = 0.0;
        self.max_range = 0.0;
        self.speed = 0.0;
        self.projectile_type = ProjectileType::Ballistic;
        self.damage_amount = 0.0;
        self.damage_type.clear();
        self.source_weapon_name.clear();
        self.target_pos = None;
        self.target_body = None;
        self.tracking_strength = 0.0;
        self.turn_rate = 0.0;
    }

    /// Updates lifetime and distance based on current frame delta and position.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    /// - `_body_x` — `f32`.
    /// - `_body_y` — `f32`.
    /// - `_body_angle` — `f32`.
    pub fn update(&mut self, dt: f32, _body_x: f32, _body_y: f32, _body_angle: f32) {
        if !self.active {
            return;
        }
        self.lifetime += dt;
        self.distance_traveled += self.speed * dt;
    }
}

impl Default for Projectile {
    fn default() -> Self {
        Self {
            body_id: 0,
            active: false,
            lifetime: 0.0,
            distance_traveled: 0.0,
            max_range: 0.0,
            speed: 0.0,
            projectile_type: ProjectileType::Ballistic,
            damage_amount: 0.0,
            damage_type: String::new(),
            source_weapon_name: String::new(),
            target_pos: None,
            target_body: None,
            tracking_strength: 0.0,
            turn_rate: 0.0,
        }
    }
}

/// Pre-allocated pool of projectiles for efficient spawn/release cycling.
///
/// # Fields
/// - `projectiles` — `Vec<Projectile>`.
/// - `pool_size` — `usize`.
/// - `body_ids` — `Vec<usize>`.
/// - `free_indices` — `Vec<usize>`.
/// - `projectile_type` — `ProjectileType`.
/// - `collision_group` — `String`.
#[derive(Clone)]
pub struct ProjectilePool {
    /// All projectile slots in this pool.
    pub projectiles: Vec<Projectile>,
    /// Configured pool capacity.
    pub pool_size: usize,
    /// Pre-created physics body IDs (one per slot).
    pub body_ids: Vec<usize>,
    /// Indices of free (inactive) slots.
    pub free_indices: Vec<usize>,
    /// The type of projectiles this pool manages.
    pub projectile_type: ProjectileType,
    /// Collision group name for projectiles in this pool.
    pub collision_group: String,
}

impl ProjectilePool {
    /// Creates a new projectile pool with the given capacity (capped at
    /// [`MAX_POOL_SIZE`]).
    ///
    /// # Parameters
    /// - `pool_size` — `usize`.
    /// - `projectile_type` — `ProjectileType`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(pool_size: usize, projectile_type: ProjectileType) -> Self {
        let size = pool_size.min(MAX_POOL_SIZE);
        let projectiles: Vec<Projectile> = (0..size).map(|_| Projectile::default()).collect();
        let free_indices: Vec<usize> = (0..size).rev().collect();

        Self {
            projectiles,
            pool_size: size,
            body_ids: Vec::new(),
            free_indices,
            projectile_type,
            collision_group: String::new(),
        }
    }

    /// Spawns a projectile from the pool. Returns a typed key that can be used to look up or remove the resource.
    ///
    /// Returns the projectile index, or `None` if the pool is exhausted.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `_angle` — `f32`.
    /// - `speed` — `f32`.
    /// - `damage` — `f32`.
    /// - `damage_type` — `&str`.
    /// - `range` — `f32`.
    ///
    /// # Returns
    /// `Option<usize>`.
    #[allow(clippy::too_many_arguments)]
    pub fn spawn(
        &mut self,
        x: f32,
        y: f32,
        _angle: f32,
        speed: f32,
        damage: f32,
        damage_type: &str,
        range: f32,
    ) -> Option<usize> {
        let idx = self.free_indices.pop()?;
        let proj = &mut self.projectiles[idx];
        proj.reset();
        proj.active = true;
        proj.speed = speed;
        proj.damage_amount = damage;
        proj.damage_type = damage_type.to_string();
        proj.max_range = range;
        proj.projectile_type = self.projectile_type;
        // Position is set via physics body externally; store initial values
        let _ = (x, y); // consumed by caller to position physics body
        Some(idx)
    }

    /// Returns a projectile slot to the free pool.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    pub fn release(&mut self, index: usize) {
        if index < self.projectiles.len() && self.projectiles[index].active {
            self.projectiles[index].reset();
            self.free_indices.push(index);
        }
    }

    /// Returns the number of currently active projectiles.
    ///
    /// # Returns
    /// `usize`.
    pub fn active_count(&self) -> usize {
        self.pool_size - self.free_indices.len()
    }

    /// Returns the number of free slots. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `usize`.
    pub fn free_count(&self) -> usize {
        self.free_indices.len()
    }

    /// Returns the indices of all active projectiles.
    ///
    /// # Returns
    /// `Vec<usize>`.
    pub fn get_active(&self) -> Vec<usize> {
        self.projectiles
            .iter()
            .enumerate()
            .filter(|(_, p)| p.active)
            .map(|(i, _)| i)
            .collect()
    }

    /// Returns a reference to the projectile at the given index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&Projectile>`.
    pub fn get(&self, index: usize) -> Option<&Projectile> {
        self.projectiles.get(index)
    }

    /// Returns a mutable reference to the projectile at the given index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&mut Projectile>`.
    pub fn get_mut(&mut self, index: usize) -> Option<&mut Projectile> {
        self.projectiles.get_mut(index)
    }

    /// Releases all active projectiles back to the pool.
    pub fn reset(&mut self) {
        for proj in &mut self.projectiles {
            proj.reset();
        }
        self.free_indices.clear();
        for i in (0..self.pool_size).rev() {
            self.free_indices.push(i);
        }
    }
}
