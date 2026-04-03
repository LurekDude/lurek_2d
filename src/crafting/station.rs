//! Crafting station: type, level, proximity, modules, attachments, and fuel.
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for station-related operations and data management.
//! Key types exported from this module: `Station`.
//! Primary functions: `new()`, `can_process()`, `effective_time()`, `effective_level()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;
use super::recipe::Recipe;

/// A crafting station that filters and processes recipes.
///
/// # Fields
/// - `station_type`, `name`, `metadata`: Station identity and caller-defined metadata.
/// - `level`, `max_level`, `attachments`: Station progression state.
/// - `speed_multiplier`, `quality_bonus`, `output_multiplier`: Craft processing modifiers.
/// - `active`, `requires_cover`, `has_cover`: Operational state flags.
/// - `x`, `y`, `proximity_radius`: World-space placement and range.
/// - `fuel_level`, `fuel_capacity`: Fuel storage state.
/// - `modules`: Optional module items installed in slots.
#[derive(Debug, Clone)]
pub struct Station {
    pub station_type: String,
    pub level: u32,
    pub max_level: u32,
    pub speed_multiplier: f64,
    pub quality_bonus: f64,
    pub output_multiplier: f64,
    pub name: String,
    pub active: bool,
    pub x: f64,
    pub y: f64,
    pub proximity_radius: f64,
    pub fuel_level: f64,
    pub fuel_capacity: f64,
    /// Module slots (Factorio pattern). `None` = empty slot.
    pub modules: Vec<Option<String>>,
    /// Physical attachment upgrades (Valheim pattern), e.g. `"chopping_block"`.
    pub attachments: Vec<String>,
    /// Whether the station requires cover/roof (Valheim pattern).
    pub requires_cover: bool,
    /// Whether the station currently has cover.
    pub has_cover: bool,
    pub metadata: HashMap<String, String>,
}

impl Station {
    /// Create a crafting station with default operational state.
    ///
    /// # Parameters
    /// - `station_type`: Stable station type such as `"forge"`.
    /// - `level`: Initial station level.
    ///
    /// # Returns
    /// An active station with default multipliers and no modules or attachments.
    pub fn new(station_type: impl Into<String>, level: u32) -> Self {
        let station_type = station_type.into();
        let name = station_type.clone();
        Self {
            station_type,
            level,
            max_level: 10,
            speed_multiplier: 1.0,
            quality_bonus: 0.0,
            output_multiplier: 1.0,
            name,
            active: true,
            x: 0.0,
            y: 0.0,
            proximity_radius: 0.0,
            fuel_level: 0.0,
            fuel_capacity: 100.0,
            modules: Vec::new(),
            attachments: Vec::new(),
            requires_cover: false,
            has_cover: false,
            metadata: HashMap::new(),
        }
    }

    /// Returns `true` if this station can process the given recipe.
    ///
    /// # Parameters
    /// - `recipe`: Recipe to validate against this station.
    ///
    /// # Returns
    /// `true` if the station is active and meets the recipe's type and level requirements.
    pub fn can_process(&self, recipe: &Recipe) -> bool {
        self.active
            && (recipe.station_type.is_empty() || recipe.station_type == self.station_type)
            && self.effective_level() >= recipe.station_level
    }

    /// Effective craft time after applying the station speed multiplier.
    ///
    /// # Parameters
    /// - `recipe`: Recipe whose base craft time should be adjusted.
    ///
    /// # Returns
    /// The adjusted craft duration in seconds.
    pub fn effective_time(&self, recipe: &Recipe) -> f64 {
        recipe.time / self.speed_multiplier.max(0.001)
    }

    /// Effective level = base level + number of attachments (Valheim pattern).
    ///
    /// # Returns
    /// Base station level plus one level per attachment.
    pub fn effective_level(&self) -> u32 {
        self.level + self.attachments.len() as u32
    }

    /// Increment the station level by 1. Returns `false` if already at max.
    ///
    /// # Returns
    /// `true` if the level increased.
    pub fn upgrade(&mut self) -> bool {
        if self.level < self.max_level {
            self.level += 1;
            true
        } else {
            false
        }
    }

    /// Check whether a world position is within this station's proximity radius.
    ///
    /// # Parameters
    /// - `px`: World-space x-coordinate to test.
    /// - `py`: World-space y-coordinate to test.
    ///
    /// # Returns
    /// `true` if the point lies within the station's interaction radius.
    pub fn is_in_range(&self, px: f64, py: f64) -> bool {
        let dx = self.x - px;
        let dy = self.y - py;
        dx * dx + dy * dy <= self.proximity_radius * self.proximity_radius
    }

    /// Add fuel, clamped to fuel capacity. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `amount`: Fuel amount to add.
    pub fn add_fuel(&mut self, amount: f64) {
        self.fuel_level = (self.fuel_level + amount).min(self.fuel_capacity);
    }

    /// Consume fuel. Returns `false` if insufficient.
    ///
    /// # Parameters
    /// - `amount`: Fuel amount to consume.
    ///
    /// # Returns
    /// `true` if enough fuel was available.
    pub fn consume_fuel(&mut self, amount: f64) -> bool {
        if self.fuel_level >= amount {
            self.fuel_level -= amount;
            true
        } else {
            false
        }
    }

    // ── Module slots (Factorio pattern) ──────────────────────────────────────

    /// Set the total number of module slots. Replaces the current module slot count value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `count`: Desired slot count.
    pub fn set_module_slot_count(&mut self, count: usize) {
        self.modules.resize(count, None);
    }

    /// Get the number of module slots. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// The current module slot count.
    pub fn module_slot_count(&self) -> usize { self.modules.len() }

    /// Insert a module into a slot (0-based). Returns `false` if slot index is out of range.
    ///
    /// # Parameters
    /// - `slot`: Zero-based module slot index.
    /// - `module_type`: Module identifier to insert.
    ///
    /// # Returns
    /// `true` if the slot existed.
    pub fn insert_module(&mut self, slot: usize, module_type: impl Into<String>) -> bool {
        if let Some(s) = self.modules.get_mut(slot) {
            *s = Some(module_type.into());
            true
        } else {
            false
        }
    }

    /// Remove the module at a slot (0-based). Returns the module type, or `None` if empty.
    ///
    /// # Parameters
    /// - `slot`: Zero-based module slot index.
    ///
    /// # Returns
    /// The removed module identifier, if one was present.
    pub fn remove_module(&mut self, slot: usize) -> Option<String> {
        self.modules.get_mut(slot).and_then(|s| s.take())
    }

    /// Get the module type at a slot (0-based).
    ///
    /// # Parameters
    /// - `slot`: Zero-based module slot index.
    ///
    /// # Returns
    /// The installed module identifier, if the slot is occupied.
    pub fn get_module(&self, slot: usize) -> Option<&str> {
        self.modules.get(slot).and_then(|s| s.as_deref())
    }

    // ── Physical attachments (Valheim pattern) ────────────────────────────────

    /// Add a physical upgrade attachment. Returns `false` if already present.
    ///
    /// # Parameters
    /// - `attachment_type`: Attachment identifier to add.
    ///
    /// # Returns
    /// `true` if the attachment was newly added.
    pub fn add_attachment(&mut self, attachment_type: impl Into<String>) -> bool {
        let t = attachment_type.into();
        if self.attachments.contains(&t) {
            false
        } else {
            self.attachments.push(t);
            true
        }
    }

    /// Remove an attachment. Returns `false` if not found.
    ///
    /// # Parameters
    /// - `attachment_type`: Attachment identifier to remove.
    ///
    /// # Returns
    /// `true` if the attachment existed.
    pub fn remove_attachment(&mut self, attachment_type: &str) -> bool {
        let before = self.attachments.len();
        self.attachments.retain(|a| a != attachment_type);
        self.attachments.len() < before
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn station_modules() {
        let mut station = Station::new("assembler", 1);
        station.set_module_slot_count(4);
        assert_eq!(station.module_slot_count(), 4);
        assert!(station.insert_module(0, "speed"));
        assert_eq!(station.get_module(0), Some("speed"));
        let removed = station.remove_module(0);
        assert_eq!(removed.as_deref(), Some("speed"));
        assert_eq!(station.get_module(0), None);
    }

    #[test]
    fn station_attachments_effective_level() {
        let mut station = Station::new("workbench", 1);
        assert_eq!(station.effective_level(), 1);
        station.add_attachment("chopping_block");
        station.add_attachment("tanning_rack");
        assert_eq!(station.effective_level(), 3);
        station.remove_attachment("chopping_block");
        assert_eq!(station.effective_level(), 2);
        assert!(!station.add_attachment("tanning_rack"));
    }

    #[test]
    fn station_cover() {
        let mut station = Station::new("cauldron", 1);
        station.requires_cover = true;
        assert!(!station.has_cover);
        station.has_cover = true;
        assert!(station.has_cover);
    }

    #[test]
    fn station_upgrade_max() {
        let mut station = Station::new("forge", 3);
        station.max_level = 4;
        assert!(station.upgrade());
        assert_eq!(station.level, 4);
        assert!(!station.upgrade());
    }

    #[test]
    fn station_proximity_check() {
        let mut station = Station::new("anvil", 1);
        station.x = 100.0;
        station.y = 100.0;
        station.proximity_radius = 50.0;
        assert!(station.is_in_range(100.0, 100.0));
        assert!(station.is_in_range(130.0, 100.0));
        assert!(!station.is_in_range(200.0, 100.0));
    }

    #[test]
    fn station_fuel_operations() {
        let mut station = Station::new("furnace", 1);
        station.add_fuel(80.0);
        assert!((station.fuel_level - 80.0).abs() < 1e-5);
        assert!(station.consume_fuel(30.0));
        assert!((station.fuel_level - 50.0).abs() < 1e-5);
        assert!(!station.consume_fuel(100.0));
        station.add_fuel(200.0);
        assert!((station.fuel_level - 100.0).abs() < 1e-5);
    }
}
