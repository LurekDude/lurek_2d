//! Vehicle chassis with mount slots and armor zones.
//!
//! A [`Chassis`] represents a vehicle body in the combat system. It has health,
//! directional armor, and named mount slots where turrets or weapons attach.

use std::collections::HashMap;

/// A slot on the chassis where turrets or weapons attach.
///
/// # Fields
/// - `id` — `String`.
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `t` — ``"small"``.
/// - `size_class` — `String`.
/// - `arc_min` — `f32`.
/// - `arc_max` — `f32`.
#[derive(Clone)]
pub struct MountSlot {
    /// Unique identifier for this slot.
    pub id: String,
    /// Local X offset from chassis centre.
    pub x: f32,
    /// Local Y offset from chassis centre.
    pub y: f32,
    /// Size class constraint: `"small"`, `"medium"`, or `"large"`.
    pub size_class: String,
    /// Minimum arc angle in radians.
    pub arc_min: f32,
    /// Maximum arc angle in radians.
    pub arc_max: f32,
}

/// Armor zone damage multiplier. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Front` — Front variant.
/// - `Rear` — Rear variant.
/// - `Side` — Side variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ArmorZone {
    /// Front-facing armor.
    Front,
    /// Rear-facing armor.
    Rear,
    /// Side armor.
    Side,
}

/// A vehicle chassis with health, armor, and mount slots.
///
/// # Fields
/// - `body_id` — `usize`.
/// - `team` — `String`.
/// - `hp` — `f32`.
/// - `max_hp` — `f32`.
/// - `slots` — `Vec<MountSlot>`.
/// - `armor` — `HashMap<String`.
/// - `turret_ids` — `HashMap<String`.
/// - `destroyed` — `bool`.
/// - `user_data` — `Option<String>`.
#[derive(Clone)]
pub struct Chassis {
    /// Physics body ID for this chassis.
    pub body_id: usize,
    /// Team affiliation.
    pub team: String,
    /// Current hit points.
    pub hp: f32,
    /// Maximum hit points.
    pub max_hp: f32,
    /// Ordered list of mount slots.
    pub slots: Vec<MountSlot>,
    /// Zone name → armor value.
    pub armor: HashMap<String, f32>,
    /// Slot ID → turret index (managed externally).
    pub turret_ids: HashMap<String, usize>,
    /// Whether this chassis has been destroyed.
    pub destroyed: bool,
    /// Optional user-defined data tag.
    pub user_data: Option<String>,
}

impl Chassis {
    /// Creates a new chassis with the given physics body ID and max HP.
    ///
    /// # Parameters
    /// - `body_id` — `usize`.
    /// - `ax_hp` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(body_id: usize, max_hp: f32) -> Self {
        Self {
            body_id,
            team: String::new(),
            hp: max_hp,
            max_hp,
            slots: Vec::new(),
            armor: HashMap::new(),
            turret_ids: HashMap::new(),
            destroyed: false,
            user_data: None,
        }
    }

    /// Adds a mount slot to this chassis. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `slot` — `MountSlot`.
    pub fn add_slot(&mut self, slot: MountSlot) {
        self.slots.push(slot);
    }

    /// Returns a reference to the slot with the given ID, if it exists.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&MountSlot>`.
    pub fn get_slot(&self, id: &str) -> Option<&MountSlot> {
        self.slots.iter().find(|s| s.id == id)
    }

    /// Returns a slice of all mount slots. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&[MountSlot]`.
    pub fn get_slots(&self) -> &[MountSlot] {
        &self.slots
    }

    /// Applies damage to the chassis, clamping HP to zero.
    ///
    /// Returns the actual damage dealt (may be less than `amount` if HP was
    /// already low). Sets `destroyed` if HP reaches zero.
    ///
    /// # Parameters
    /// - `amount` — `f32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn take_damage(&mut self, amount: f32) -> f32 {
        if self.destroyed || amount <= 0.0 {
            return 0.0;
        }
        let actual = amount.min(self.hp);
        self.hp -= actual;
        if self.hp <= 0.0 {
            self.hp = 0.0;
            self.destroyed = true;
        }
        actual
    }

    /// Heals the chassis, clamping HP to `max_hp`.
    ///
    /// Returns the actual amount healed.
    ///
    /// # Parameters
    /// - `amount` — `f32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn heal(&mut self, amount: f32) -> f32 {
        if amount <= 0.0 {
            return 0.0;
        }
        let room = self.max_hp - self.hp;
        let actual = amount.min(room);
        self.hp += actual;
        actual
    }

    /// Returns `true` if the chassis is destroyed (HP ≤ 0).
    ///
    /// # Returns
    /// `bool`.
    pub fn is_dead(&self) -> bool {
        self.destroyed
    }

    /// Returns the armor value for the given zone name. Defaults to `0.0`.
    ///
    /// # Parameters
    /// - `zone` — `&str`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_armor(&self, zone: &str) -> f32 {
        self.armor.get(zone).copied().unwrap_or(0.0)
    }

    /// Sets the armor value for the given zone name.
    ///
    /// # Parameters
    /// - `zone` — `&str`.
    /// - `value` — `f32`.
    pub fn set_armor(&mut self, zone: &str, value: f32) {
        self.armor.insert(zone.to_string(), value);
    }
}
