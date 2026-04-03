//! Turret and Weapon types for fire-rate-based combat.
//!
//! A [`Turret`] is a rotatable mount attached to a chassis slot via a physics
//! revolute joint. A [`Weapon`] handles fire rate, ammo, bursts, and damage
//! parameters.

/// The type of projectile a weapon fires. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Standard` — Standard variant.
/// - `Ballistic` — Ballistic variant.
/// - `Homing` — Homing variant.
/// - `Instant` — Instant variant.
/// - `Ray` — Ray variant.
/// - `Area` — Area variant.
/// - `Sustained` — Sustained variant.
/// - `Beam` — Beam variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProjectileType {
    /// Standard ballistic projectile (travels in a straight line).
    Ballistic,
    /// Homing projectile that tracks a target.
    Homing,
    /// Instant-hit ray (hitscan).
    Ray,
    /// Area-of-effect projectile.
    Area,
    /// Sustained beam weapon.
    Beam,
}

/// A rotatable weapon mount attached to a chassis slot.
///
/// # Fields
/// - `body_id` — `usize`.
/// - `joint_id` — `usize`.
/// - `turn_speed` — `f32`.
/// - `arc_min` — `f32`.
/// - `arc_max` — `f32`.
/// - `target_angle` — `Option<f32>`.
/// - `weapon` — `Option<usize>`.
/// - `chassis_id` — `Option<usize>`.
/// - `size_class` — `String`.
/// - `destroyed` — `bool`.
#[derive(Clone)]
pub struct Turret {
    /// Physics body ID for the turret.
    pub body_id: usize,
    /// Revolute joint ID connecting turret to chassis.
    pub joint_id: usize,
    /// Turret rotation speed in radians per second.
    pub turn_speed: f32,
    /// Minimum rotation limit in radians.
    pub arc_min: f32,
    /// Maximum rotation limit in radians.
    pub arc_max: f32,
    /// Desired target angle, if any.
    pub target_angle: Option<f32>,
    /// Weapon index (managed externally).
    pub weapon: Option<usize>,
    /// Chassis body ID this turret is attached to.
    pub chassis_id: Option<usize>,
    /// Size class of the turret mount.
    pub size_class: String,
    /// Whether this turret has been destroyed.
    pub destroyed: bool,
}

impl Turret {
    /// Creates a new turret with the given physics body and joint IDs.
    ///
    /// # Parameters
    /// - `body_id` — `usize`.
    /// - `joint_id` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(body_id: usize, joint_id: usize) -> Self {
        Self {
            body_id,
            joint_id,
            turn_speed: 1.0,
            arc_min: -std::f32::consts::PI,
            arc_max: std::f32::consts::PI,
            target_angle: None,
            weapon: None,
            chassis_id: None,
            size_class: String::from("medium"),
            destroyed: false,
        }
    }

    /// Updates the turret rotation towards the target angle.
    ///
    /// Returns the desired angular velocity to reach the target, or `None`
    /// if no target is set.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    /// - `current_angle` — `f32`.
    ///
    /// # Returns
    /// `Option<f32>`.
    pub fn update(&self, dt: f32, current_angle: f32) -> Option<f32> {
        let target = self.target_angle?;
        let clamped = self.clamp_to_arc(target);
        let mut diff = clamped - current_angle;

        // Normalise to [-PI, PI]
        while diff > std::f32::consts::PI {
            diff -= std::f32::consts::TAU;
        }
        while diff < -std::f32::consts::PI {
            diff += std::f32::consts::TAU;
        }

        let max_step = self.turn_speed * dt;
        let velocity = if diff.abs() <= max_step {
            diff / dt.max(1e-6)
        } else {
            self.turn_speed * diff.signum()
        };
        Some(velocity)
    }

    /// Sets the desired target angle for the turret.
    ///
    /// # Parameters
    /// - `angle` — `f32`.
    pub fn aim_at_angle(&mut self, angle: f32) {
        self.target_angle = Some(angle);
    }

    /// Returns `true` if the turret is within `tolerance` radians of its target.
    ///
    /// Returns `true` if no target is set (nothing to aim at).
    ///
    /// # Parameters
    /// - `olerance` — `f32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_aimed(&self, tolerance: f32) -> bool {
        match self.target_angle {
            None => true,
            Some(target) => {
                // Without a live current_angle, compare against the clamped target.
                // The caller can also check externally with the physics angle.
                let clamped = self.clamp_to_arc(target);
                // If arc_min == arc_max the turret is fixed, so it's always "aimed".
                (clamped - target).abs() < tolerance
            }
        }
    }

    /// Clamps an angle to the turret's arc limits.
    ///
    /// # Parameters
    /// - `angle` — `f32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn clamp_to_arc(&self, angle: f32) -> f32 {
        angle.clamp(self.arc_min, self.arc_max)
    }
}

/// A weapon that handles fire rate, ammo, burst, and damage.
///
/// # Fields
/// - `name` — `String`.
/// - `fire_rate` — `f32`.
/// - `cooldown_remaining` — `f32`.
/// - `ammo` — `i32`.
/// - `max_ammo` — `i32`.
/// - `burst_size` — `u32`.
/// - `burst_delay` — `f32`.
/// - `burst_remaining` — `u32`.
/// - `spread` — `f32`.
/// - `damage_amount` — `f32`.
/// - `damage_type` — `String`.
/// - `penetration` — `f32`.
/// - `range` — `f32`.
/// - `projectile_speed` — `f32`.
/// - `projectile_type` — `ProjectileType`.
/// - `firing` — `bool`.
#[derive(Clone)]
pub struct Weapon {
    /// Weapon display name.
    pub name: String,
    /// Rounds per second.
    pub fire_rate: f32,
    /// Seconds remaining until the next shot can fire.
    pub cooldown_remaining: f32,
    /// Current ammo count. `-1` means infinite.
    pub ammo: i32,
    /// Maximum ammo capacity.
    pub max_ammo: i32,
    /// Number of rounds in one burst.
    pub burst_size: u32,
    /// Seconds between rounds within a burst.
    pub burst_delay: f32,
    /// Remaining rounds in the current burst.
    pub burst_remaining: u32,
    /// Angular spread in radians.
    pub spread: f32,
    /// Damage dealt per hit.
    pub damage_amount: f32,
    /// Damage type tag (e.g. `"kinetic"`, `"explosive"`).
    pub damage_type: String,
    /// Armor penetration value.
    pub penetration: f32,
    /// Maximum range in world units.
    pub range: f32,
    /// Projectile travel speed in world units per second.
    pub projectile_speed: f32,
    /// Type of projectile this weapon fires.
    pub projectile_type: ProjectileType,
    /// Whether the weapon is currently firing.
    pub firing: bool,
}

impl Weapon {
    /// Creates a new weapon with default values and the given name.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            fire_rate: 1.0,
            cooldown_remaining: 0.0,
            ammo: -1,
            max_ammo: -1,
            burst_size: 1,
            burst_delay: 0.0,
            burst_remaining: 0,
            spread: 0.0,
            damage_amount: 10.0,
            damage_type: String::from("kinetic"),
            penetration: 0.0,
            range: 500.0,
            projectile_speed: 300.0,
            projectile_type: ProjectileType::Ballistic,
            firing: false,
        }
    }

    /// Returns `true` if the weapon is ready to fire (cooldown elapsed and ammo available).
    ///
    /// # Returns
    /// `bool`.
    pub fn can_fire(&self) -> bool {
        self.cooldown_remaining <= 0.0 && !self.is_out_of_ammo()
    }

    /// Attempts to fire the weapon. Returns `true` if a shot was produced.
    ///
    /// Consumes ammo (if not infinite), applies cooldown, and manages burst state.
    ///
    /// # Parameters
    /// - `_dt` — `f32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn fire(&mut self, _dt: f32) -> bool {
        if !self.can_fire() {
            return false;
        }

        // Consume ammo
        if self.ammo > 0 {
            self.ammo -= 1;
        }

        // Handle burst
        if self.burst_remaining > 0 {
            self.burst_remaining -= 1;
            self.cooldown_remaining = self.burst_delay;
        } else {
            self.burst_remaining = self.burst_size.saturating_sub(1);
            if self.burst_remaining > 0 {
                self.cooldown_remaining = self.burst_delay;
            } else {
                self.cooldown_remaining = if self.fire_rate > 0.0 {
                    1.0 / self.fire_rate
                } else {
                    0.0
                };
            }
        }

        true
    }

    /// Start continuous firing. Consult the module-level documentation for the broader usage context and preconditions.
    pub fn start_firing(&mut self) {
        self.firing = true;
    }

    /// Stop continuous firing. Consult the module-level documentation for the broader usage context and preconditions.
    pub fn stop_firing(&mut self) {
        self.firing = false;
        self.burst_remaining = 0;
    }

    /// Returns `true` if the weapon is currently in firing mode.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_firing(&self) -> bool {
        self.firing
    }

    /// Ticks the cooldown timer by `dt` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    pub fn update_cooldown(&mut self, dt: f32) {
        if self.cooldown_remaining > 0.0 {
            self.cooldown_remaining -= dt;
            if self.cooldown_remaining < 0.0 {
                self.cooldown_remaining = 0.0;
            }
        }
    }

    /// Reloads ammo. If `amount` is `None`, refills to max. If `Some(n)`, adds
    /// `n` rounds (clamped to `max_ammo` when positive).
    ///
    /// # Parameters
    /// - `amount` — `Option<i32>`.
    pub fn reload(&mut self, amount: Option<i32>) {
        match amount {
            Some(n) => {
                if self.ammo < 0 {
                    return; // infinite ammo — nothing to reload
                }
                self.ammo = if self.max_ammo > 0 {
                    (self.ammo + n).min(self.max_ammo)
                } else {
                    self.ammo + n
                };
            }
            None => {
                if self.max_ammo > 0 {
                    self.ammo = self.max_ammo;
                }
            }
        }
    }

    /// Returns `true` if the weapon has exhausted its ammo (not infinite).
    ///
    /// # Returns
    /// `bool`.
    pub fn is_out_of_ammo(&self) -> bool {
        self.ammo == 0
    }
}
