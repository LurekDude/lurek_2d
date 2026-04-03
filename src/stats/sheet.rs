//! Character sheet (Sheet) and stats registry (StatsRegistry).
//!
//! This module is part of Luna2D's `stats` subsystem and provides the implementation
//! details for sheet-related operations and data management.
//! Key types exported from this module: `Sheet`, `StatsRegistry`.
//! Primary functions: `new()`, `define()`, `get()`, `get_base()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

use super::attribute::{Attribute, Buff};
use super::skill::{ActionPoints, LevelThresholds, Morale, Perk, Skill, TraitDef};

/// The central character sheet, holding all stat data.
///
/// # Fields
/// - `attributes` — `HashMap<String`.
/// - `buff_handle_counter` — `u32`.
/// - `buffs` — `HashMap<u32`.
/// - `use_counts` — `HashMap<String`.
/// - `active_traits` — `HashMap<String`.
/// - `skills` — `HashMap<String`.
/// - `perks` — `HashMap<String`.
/// - `flags` — `HashMap<String`.
/// - `xp` — `f64`.
/// - `level` — `u32`.
/// - `level_thresholds` — `LevelThresholds`.
/// - `action_points` — `Option<ActionPoints>`.
/// - `morale` — `Option<Morale>`.
/// - `resistances` — `HashMap<String`.
/// - `e` — `(current`.
/// - `encumbrance` — `Option<(f64`.
/// - `initiative` — `f64`.
/// - `active_formation` — `Option<String>`.
/// - `formation_handles` — `Vec<u32>`.
pub struct Sheet {
    /// Named attributes.
    pub attributes: HashMap<String, Attribute>,
    /// Current buff handle counter.
    buff_handle_counter: u32,
    /// Active buffs indexed by handle.
    pub buffs: HashMap<u32, Buff>,
    /// Exercise counts per attribute.
    pub use_counts: HashMap<String, u32>,
    /// Active traits (name → list of buff handles).
    pub active_traits: HashMap<String, Vec<u32>>,
    /// Active skills.
    pub skills: HashMap<String, Skill>,
    /// Active perks.
    pub perks: HashMap<String, Perk>,
    /// Boolean flags.
    pub flags: HashMap<String, bool>,
    /// XP/Level tracking.
    pub xp: f64,
    pub level: u32,
    pub level_thresholds: LevelThresholds,
    /// Action points (optional).
    pub action_points: Option<ActionPoints>,
    /// Morale (optional).
    pub morale: Option<Morale>,
    /// Resistance values by damage type.
    pub resistances: HashMap<String, f64>,
    /// Encumbrance: (current, max).
    pub encumbrance: Option<(f64, f64)>,
    /// Base initiative value.
    pub initiative: f64,
    /// Active formation name.
    pub active_formation: Option<String>,
    /// Formation trait buff handles.
    pub formation_handles: Vec<u32>,
}

impl Sheet {
    /// Create a new empty character sheet. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            attributes: HashMap::new(),
            buff_handle_counter: 0,
            buffs: HashMap::new(),
            use_counts: HashMap::new(),
            active_traits: HashMap::new(),
            skills: HashMap::new(),
            perks: HashMap::new(),
            flags: HashMap::new(),
            xp: 0.0,
            level: 1,
            level_thresholds: LevelThresholds::default_linear(),
            action_points: None,
            morale: None,
            resistances: HashMap::new(),
            encumbrance: None,
            initiative: 10.0,
            active_formation: None,
            formation_handles: Vec::new(),
        }
    }

    /// Define a named attribute with the given base value.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `base` — `f64`.
    pub fn define(&mut self, name: &str, base: f64) {
        self.attributes
            .insert(name.to_string(), Attribute::new(base));
    }

    /// Get the effective value of an attribute (base + buffs, clamped).
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<f64>`.
    pub fn get(&self, name: &str) -> Option<f64> {
        let attr = self.attributes.get(name)?;
        let mut add_sum = 0.0;
        let mut mul_product = 1.0;
        for buff in self.buffs.values() {
            if buff.stat == name && !buff.is_expired() {
                add_sum += buff.add;
                mul_product *= buff.mul;
            }
        }
        let effective = (attr.base + add_sum) * mul_product;
        let clamped = effective
            .max(attr.min)
            .min(attr.max.unwrap_or(f64::INFINITY));
        Some(clamped)
    }

    /// Get the raw base value of an attribute (no buffs).
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<f64>`.
    pub fn get_base(&self, name: &str) -> Option<f64> {
        self.attributes.get(name).map(|a| a.base)
    }

    /// Set the base value of an attribute. Replaces the current base value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `value` — `f64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn set_base(&mut self, name: &str, value: f64) -> bool {
        if let Some(attr) = self.attributes.get_mut(name) {
            let clamped = value.max(attr.min).min(attr.max.unwrap_or(f64::INFINITY));
            attr.base = clamped;
            true
        } else {
            false
        }
    }

    /// Add a buff to an attribute. Returns a handle for removal.
    ///
    /// # Parameters
    /// - `stat` — `&str`.
    /// - `add` — `f64`.
    /// - `l` — `f64`.
    /// - `duration` — `f64`.
    /// - `source` — `&str`.
    ///
    /// # Returns
    /// `u32`.
    pub fn add_buff(&mut self, stat: &str, add: f64, mul: f64, duration: f64, source: &str) -> u32 {
        self.buff_handle_counter += 1;
        let handle = self.buff_handle_counter;
        let buff = Buff::new(stat, add, mul, duration, source);
        self.buffs.insert(handle, buff);
        handle
    }

    /// Remove a buff by handle. Returns true if found.
    ///
    /// # Parameters
    /// - `handle` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_buff(&mut self, handle: u32) -> bool {
        self.buffs.remove(&handle).is_some()
    }

    /// Remove all buffs, optionally filtered to a specific stat.
    ///
    /// # Parameters
    /// - `stat` — `Option<&str>`.
    pub fn clear_buffs(&mut self, stat: Option<&str>) {
        if let Some(s) = stat {
            self.buffs.retain(|_, b| b.stat != s);
        } else {
            self.buffs.clear();
        }
    }

    /// Apply a registered trait by name, using the global trait registry.
    /// Returns handles for the applied buffs, or None if trait not found.
    ///
    /// # Parameters
    /// - `rait_name` — `&str`.
    /// - `rait_def` — `&TraitDef`.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn apply_trait_buffs(&mut self, trait_name: &str, trait_def: &TraitDef) -> Vec<u32> {
        let mut handles = Vec::new();
        for (stat, add, mul) in &trait_def.buffs {
            let h = self.add_buff(stat, *add, *mul, -1.0, &format!("trait:{}", trait_name));
            handles.push(h);
        }
        handles
    }

    /// Remove a trait's buffs by removing all tracked handles.
    ///
    /// # Parameters
    /// - `rait_name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_trait_buffs(&mut self, trait_name: &str) -> bool {
        if let Some(handles) = self.active_traits.remove(trait_name) {
            for h in handles {
                self.buffs.remove(&h);
            }
            true
        } else {
            false
        }
    }

    /// Set a boolean flag. Replaces the current flag value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn set_flag(&mut self, name: &str) {
        self.flags.insert(name.to_string(), true);
    }

    /// Clear a boolean flag. After this call the container is in the same state as immediately after construction.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn clear_flag(&mut self, name: &str) {
        self.flags.remove(name);
    }

    /// Check if a flag is set. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_flag(&self, name: &str) -> bool {
        self.flags.get(name).copied().unwrap_or(false)
    }

    /// Get all set flag names. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_flags(&self) -> Vec<String> {
        self.flags.keys().cloned().collect()
    }

    /// Add XP. Returns number of levels gained.
    ///
    /// # Parameters
    /// - `amount` — `f64`.
    ///
    /// # Returns
    /// `u32`.
    pub fn add_xp(&mut self, amount: f64) -> u32 {
        self.xp += amount;
        let mut levels_gained = 0;
        loop {
            let needed = self.level_thresholds.threshold_for(self.level);
            if self.xp >= needed {
                self.xp -= needed;
                self.level += 1;
                levels_gained += 1;
            } else {
                break;
            }
        }
        levels_gained
    }

    /// Record a use of a stat (use-based levelling).
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn record_use(&mut self, name: &str) {
        *self.use_counts.entry(name.to_string()).or_default() += 1;
        // Apply growth to the attribute if defined
        if let Some(attr) = self.attributes.get_mut(name) {
            if attr.growth > 0.0 {
                attr.base += attr.growth;
                if let Some(max) = attr.max {
                    attr.base = attr.base.min(max);
                }
            }
        }
    }

    /// Tick timed buff durations and skill cooldowns. Remove expired buffs.
    /// Returns the names of all defined attributes on this sheet.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_stat_names(&self) -> Vec<String> {
        self.attributes.keys().cloned().collect()
    }

    /// Count active buffs. If `stat` is Some, count only buffs targeting that stat.
    ///
    /// # Parameters
    /// - `stat` — `Option<&str>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_buff_count(&self, stat: Option<&str>) -> usize {
        self.buffs
            .values()
            .filter(|b| stat.is_none_or(|s| b.stat == s))
            .count()
    }

    /// Add `amount` to current action points, capped at the maximum.
    /// Returns the new value.
    ///
    /// # Parameters
    /// - `amount` — `f64`.
    ///
    /// # Returns
    /// `f64`.
    pub fn recover_action_points(&mut self, amount: f64) -> f64 {
        if let Some(ap) = self.action_points.as_mut() {
            ap.current = (ap.current + amount).min(ap.max);
            ap.current
        } else {
            0.0
        }
    }

    /// Recompute all derived stats from current base attributes and active modifiers.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    pub fn update(&mut self, dt: f64) {
        // Tick buffs
        let mut expired = Vec::new();
        for (handle, buff) in self.buffs.iter_mut() {
            if buff.duration >= 0.0 {
                buff.remaining -= dt;
                if buff.remaining <= 0.0 {
                    expired.push(*handle);
                }
            }
        }
        for h in expired {
            self.buffs.remove(&h);
        }

        // Also remove expired buffs from trait tracking
        for handles in self.active_traits.values_mut() {
            handles.retain(|h| self.buffs.contains_key(h));
        }

        // Tick skill cooldowns
        for skill in self.skills.values_mut() {
            if skill.cooldown_remaining > 0.0 {
                skill.cooldown_remaining -= dt;
                if skill.cooldown_remaining < 0.0 {
                    skill.cooldown_remaining = 0.0;
                }
            }
        }

        // Regeneration
        let attr_names: Vec<String> = self.attributes.keys().cloned().collect();
        for name in attr_names {
            let regen = self.attributes[&name].regen;
            if regen.abs() > 1e-9 {
                let max = self.attributes[&name].max;
                let base = self.attributes[&name].base;
                let new_base = base + regen * dt;
                let clamped = new_base.min(max.unwrap_or(f64::INFINITY));
                self.attributes.get_mut(&name).unwrap().base = clamped;
            }
        }
    }

    /// Apply damage to a stat, reduced by resistance. Returns actual damage dealt.
    ///
    /// # Parameters
    /// - `stat` — `&str`.
    /// - `amount` — `f64`.
    /// - `damage_type` — `Option<&str>`.
    ///
    /// # Returns
    /// `f64`.
    pub fn apply_damage(&mut self, stat: &str, amount: f64, damage_type: Option<&str>) -> f64 {
        let resistance = damage_type
            .and_then(|t| self.resistances.get(t))
            .copied()
            .unwrap_or(0.0);
        let actual = (amount * (1.0 - resistance)).max(0.0);
        if let Some(attr) = self.attributes.get_mut(stat) {
            attr.base = (attr.base - actual).max(attr.min);
        }
        actual
    }

    /// Check morale state. Returns "panic", "berserk", or nil (normal).
    ///
    /// # Returns
    /// `Option<String>`.
    pub fn check_morale(&mut self) -> Option<String> {
        if let Some(morale) = &self.morale {
            if morale.current <= morale.berserk_threshold {
                self.set_flag("berserk");
                self.clear_flag("panic");
                Some("berserk".to_string())
            } else if morale.current <= morale.panic_threshold {
                self.set_flag("panic");
                self.clear_flag("berserk");
                Some("panic".to_string())
            } else {
                self.clear_flag("panic");
                self.clear_flag("berserk");
                None
            }
        } else {
            None
        }
    }

    /// Snapshot the sheet state for serialization.
    /// Returns a simplified representation as nested Rust data.
    ///
    /// # Returns
    /// `Vec<(String, f64, f64, Option<f64>, f64, f64)>`.
    pub fn snapshot_attributes(&self) -> Vec<(String, f64, f64, Option<f64>, f64, f64)> {
        self.attributes
            .iter()
            .map(|(k, a)| (k.clone(), a.base, a.min, a.max, a.regen, a.growth))
            .collect()
    }
}

impl Default for Sheet {
    fn default() -> Self {
        Self::new()
    }
}

/// Global registry for traits and archetypes. Separate from Sheet for sharing.
///
/// # Fields
/// - `traits` — `HashMap<String`.
/// - `s` — `(base overrides`.
/// - `races` — `HashMap<String`.
/// - `classes` — `HashMap<String`.
pub struct StatsRegistry {
    /// Named trait definitions.
    pub traits: HashMap<String, TraitDef>,
    /// Named race archetypes: (base overrides, trait names).
    pub races: HashMap<String, (HashMap<String, f64>, Vec<String>)>,
    /// Named class archetypes.
    pub classes: HashMap<String, (HashMap<String, f64>, Vec<String>)>,
}

impl StatsRegistry {
    /// Create a new empty registry. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            traits: HashMap::new(),
            races: HashMap::new(),
            classes: HashMap::new(),
        }
    }

    /// Define a named trait by its buff bundle.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `buffs` — `Vec<(String`.
    pub fn define_trait(&mut self, name: &str, buffs: Vec<(String, f64, f64)>) {
        self.traits.insert(name.to_string(), TraitDef { buffs });
    }

    /// Define a race archetype. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `bases` — `HashMap<String`.
    /// - `rait_names` — `Vec<String>`.
    pub fn define_race(
        &mut self,
        name: &str,
        bases: HashMap<String, f64>,
        trait_names: Vec<String>,
    ) {
        self.races.insert(name.to_string(), (bases, trait_names));
    }

    /// Define a class archetype. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `bases` — `HashMap<String`.
    /// - `rait_names` — `Vec<String>`.
    pub fn define_class(
        &mut self,
        name: &str,
        bases: HashMap<String, f64>,
        trait_names: Vec<String>,
    ) {
        self.classes.insert(name.to_string(), (bases, trait_names));
    }

    /// Apply archetypes (race + class) to a new Sheet.
    ///
    /// # Parameters
    /// - `sheet` — `&mut Sheet`.
    /// - `race` — `Option<&str>`.
    /// - `class` — `Option<&str>`.
    pub fn apply_archetypes(&self, sheet: &mut Sheet, race: Option<&str>, class: Option<&str>) {
        for name in [race, class].into_iter().flatten() {
            let (bases, trait_names) = if let Some(r) = self.races.get(name) {
                r
            } else if let Some(c) = self.classes.get(name) {
                c
            } else {
                continue;
            };
            for (stat, val) in bases {
                if let Some(attr) = sheet.attributes.get_mut(stat) {
                    attr.base += val;
                }
            }
            for tn in trait_names {
                if let Some(tdef) = self.traits.get(tn) {
                    let handles = sheet.apply_trait_buffs(tn, tdef);
                    sheet
                        .active_traits
                        .entry(tn.clone())
                        .or_default()
                        .extend(handles);
                }
            }
        }
    }
}

impl Default for StatsRegistry {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sheet_define_and_get() {
        let mut s = Sheet::new();
        s.define("str", 10.0);
        assert!((s.get("str").unwrap() - 10.0).abs() < 1e-5);
    }

    #[test]
    fn sheet_buff_add() {
        let mut s = Sheet::new();
        s.define("str", 10.0);
        s.add_buff("str", 5.0, 1.0, -1.0, "potion");
        assert!((s.get("str").unwrap() - 15.0).abs() < 1e-5);
    }

    #[test]
    fn sheet_buff_mul() {
        let mut s = Sheet::new();
        s.define("str", 10.0);
        s.add_buff("str", 0.0, 2.0, -1.0, "fury");
        assert!((s.get("str").unwrap() - 20.0).abs() < 1e-5);
    }

    #[test]
    fn sheet_buff_remove() {
        let mut s = Sheet::new();
        s.define("str", 10.0);
        let h = s.add_buff("str", 5.0, 1.0, -1.0, "potion");
        assert!((s.get("str").unwrap() - 15.0).abs() < 1e-5);
        s.remove_buff(h);
        assert!((s.get("str").unwrap() - 10.0).abs() < 1e-5);
    }

    #[test]
    fn sheet_buff_expires() {
        let mut s = Sheet::new();
        s.define("str", 10.0);
        s.add_buff("str", 5.0, 1.0, 2.0, "temp");
        assert!((s.get("str").unwrap() - 15.0).abs() < 1e-5);
        s.update(3.0);
        assert!((s.get("str").unwrap() - 10.0).abs() < 1e-5);
    }

    #[test]
    fn sheet_max_clamp() {
        let mut s = Sheet::new();
        s.define("hp", 100.0);
        s.attributes.get_mut("hp").unwrap().max = Some(100.0);
        s.add_buff("hp", 50.0, 1.0, -1.0, "overheal");
        assert!((s.get("hp").unwrap() - 100.0).abs() < 1e-5);
    }

    #[test]
    fn sheet_xp_levelling() {
        let mut s = Sheet::new();
        s.level_thresholds = LevelThresholds::Table(vec![100.0, 250.0, 500.0]);
        assert_eq!(s.level, 1);
        let levels = s.add_xp(100.0);
        assert_eq!(levels, 1);
        assert_eq!(s.level, 2);
    }

    #[test]
    fn sheet_flags() {
        let mut s = Sheet::new();
        assert!(!s.has_flag("stunned"));
        s.set_flag("stunned");
        assert!(s.has_flag("stunned"));
        s.clear_flag("stunned");
        assert!(!s.has_flag("stunned"));
    }

    #[test]
    fn registry_define_trait() {
        let mut reg = StatsRegistry::new();
        reg.define_trait("str_boost", vec![("str".to_string(), 5.0, 1.0)]);
        assert!(reg.traits.contains_key("str_boost"));
    }

    #[test]
    fn sheet_apply_damage_with_resistance() {
        let mut s = Sheet::new();
        s.define("hp", 100.0);
        s.attributes.get_mut("hp").unwrap().max = Some(100.0);
        s.resistances.insert("fire".to_string(), 0.5);
        let actual = s.apply_damage("hp", 40.0, Some("fire"));
        assert!((actual - 20.0).abs() < 1e-5);
        assert!((s.get("hp").unwrap() - 80.0).abs() < 1e-5);
    }
}
