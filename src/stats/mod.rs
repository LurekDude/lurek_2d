//! RPG character sheet and stat system.
//!
//! Provides a flexible attribute system with buffs, derived stats, traits,
//! skills, perks, XP/levelling, action points, morale, and resistances.

use std::collections::HashMap;

/// How a buff stacks with existing buffs of the same name.
#[derive(Debug, Clone, PartialEq)]
pub enum StackMode {
    /// Reapplying the effect resets its duration.
    None,
    /// Reapplying extends the remaining duration.
    Duration,
    /// Reapplying adds a stack count (up to max_stacks).
    Intensity,
}

/// A single stat modifier attached to an attribute.
#[derive(Debug, Clone)]
pub struct Buff {
    /// Which attribute this buff modifies.
    pub stat: String,
    /// Additive bonus (added before multiply).
    pub add: f64,
    /// Multiplicative factor (default 1.0).
    pub mul: f64,
    /// Seconds until expiry. -1 = permanent.
    pub duration: f64,
    /// Descriptive source string.
    pub source: String,
    /// Remaining time in seconds.
    pub remaining: f64,
}

impl Buff {
    /// Create a new permanent buff.
    pub fn new(stat: &str, add: f64, mul: f64, duration: f64, source: &str) -> Self {
        let remaining = if duration < 0.0 { f64::NEG_INFINITY } else { duration };
        Self {
            stat: stat.to_string(),
            add,
            mul,
            duration,
            source: source.to_string(),
            remaining,
        }
    }

    /// Whether this buff has expired.
    pub fn is_expired(&self) -> bool {
        self.duration >= 0.0 && self.remaining <= 0.0
    }
}

/// A named stat attribute with base value, constraints, and regen.
#[derive(Debug, Clone)]
pub struct Attribute {
    /// Base value before buffs.
    pub base: f64,
    /// Minimum effective value.
    pub min: f64,
    /// Maximum effective value. None = unbounded.
    pub max: Option<f64>,
    /// Regeneration per second (applied during `update`).
    pub regen: f64,
    /// Growth per use (use-based levelling).
    pub growth: f64,
}

impl Attribute {
    /// Create a new attribute with the given base value.
    pub fn new(base: f64) -> Self {
        Self {
            base,
            min: f64::NEG_INFINITY,
            max: None,
            regen: 0.0,
            growth: 0.0,
        }
    }
}

/// A named skill with cooldown, resource cost, and level tracking.
#[derive(Debug, Clone)]
pub struct Skill {
    /// Current level (0 = not learned).
    pub level: u32,
    /// Maximum level.
    pub max_level: u32,
    /// Resource name consumed on use.
    pub resource: String,
    /// Amount of resource consumed.
    pub cost: f64,
    /// Cooldown in seconds.
    pub cooldown: f64,
    /// Remaining cooldown in seconds.
    pub cooldown_remaining: f64,
    /// Whether passive is currently active.
    pub passive_active: bool,
}

impl Skill {
    /// Create a new skill definition.
    pub fn new(max_level: u32, resource: &str, cost: f64, cooldown: f64) -> Self {
        Self {
            level: 0,
            max_level,
            resource: resource.to_string(),
            cost,
            cooldown,
            cooldown_remaining: 0.0,
            passive_active: false,
        }
    }
}

/// A named perk requiring a minimum level to acquire.
#[derive(Debug, Clone)]
pub struct Perk {
    /// Minimum character level required to acquire.
    pub require_level: u32,
    /// Optional trait applied when acquired.
    pub trait_name: Option<String>,
    /// Whether this perk has been acquired.
    pub acquired: bool,
}

impl Perk {
    /// Create a new perk definition.
    pub fn new(require_level: u32, trait_name: Option<String>) -> Self {
        Self {
            require_level,
            trait_name,
            acquired: false,
        }
    }
}

/// A named trait definition (a bundle of buff descriptors).
#[derive(Debug, Clone)]
pub struct TraitDef {
    /// Buff descriptors: (stat, add, mul) tuples.
    pub buffs: Vec<(String, f64, f64)>,
}

/// Action point tracking for turn-based games.
#[derive(Debug, Clone)]
pub struct ActionPoints {
    /// Current action points available.
    pub current: f64,
    /// Maximum action points.
    pub max: f64,
}

impl ActionPoints {
    /// Create action points with the given max.
    pub fn new(max: f64) -> Self {
        Self { current: max, max }
    }
}

/// Morale state with panic/berserk thresholds.
#[derive(Debug, Clone)]
pub struct Morale {
    /// Current morale value.
    pub current: f64,
    /// Maximum morale value.
    pub max: f64,
    /// Morale below which the unit panics.
    pub panic_threshold: f64,
    /// Morale below which the unit goes berserk.
    pub berserk_threshold: f64,
}

impl Morale {
    /// Create morale with the given max (current starts at max).
    pub fn new(max: f64) -> Self {
        Self {
            current: max,
            max,
            panic_threshold: 25.0,
            berserk_threshold: 10.0,
        }
    }
}

/// Level threshold setting: either a static table or a formula.
#[derive(Debug, Clone)]
pub enum LevelThresholds {
    /// XP required to reach each level (1-indexed: thresholds[0] = XP for level 2).
    Table(Vec<f64>),
    /// Linear formula: base + (level - 1) * increment.
    Linear { base: f64, increment: f64 },
}

impl LevelThresholds {
    /// Default: 100 XP per level.
    pub fn default_linear() -> Self {
        Self::Linear { base: 100.0, increment: 100.0 }
    }

    /// Get the XP threshold for the given level (level 1 = index 0 → returns threshold for level 2).
    pub fn threshold_for(&self, level: u32) -> f64 {
        match self {
            Self::Table(v) => {
                let idx = (level as usize).saturating_sub(1);
                if idx < v.len() { v[idx] } else { f64::INFINITY }
            }
            Self::Linear { base, increment } => base + (level as f64 - 1.0) * increment,
        }
    }
}

/// The central character sheet, holding all stat data.
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
    /// Create a new empty character sheet.
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
    pub fn define(&mut self, name: &str, base: f64) {
        self.attributes.insert(name.to_string(), Attribute::new(base));
    }

    /// Get the effective value of an attribute (base + buffs, clamped).
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
        let clamped = effective.max(attr.min).min(attr.max.unwrap_or(f64::INFINITY));
        Some(clamped)
    }

    /// Get the raw base value of an attribute (no buffs).
    pub fn get_base(&self, name: &str) -> Option<f64> {
        self.attributes.get(name).map(|a| a.base)
    }

    /// Set the base value of an attribute.
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
    pub fn add_buff(&mut self, stat: &str, add: f64, mul: f64, duration: f64, source: &str) -> u32 {
        self.buff_handle_counter += 1;
        let handle = self.buff_handle_counter;
        let buff = Buff::new(stat, add, mul, duration, source);
        self.buffs.insert(handle, buff);
        handle
    }

    /// Remove a buff by handle. Returns true if found.
    pub fn remove_buff(&mut self, handle: u32) -> bool {
        self.buffs.remove(&handle).is_some()
    }

    /// Remove all buffs, optionally filtered to a specific stat.
    pub fn clear_buffs(&mut self, stat: Option<&str>) {
        if let Some(s) = stat {
            self.buffs.retain(|_, b| b.stat != s);
        } else {
            self.buffs.clear();
        }
    }

    /// Apply a registered trait by name, using the global trait registry.
    /// Returns handles for the applied buffs, or None if trait not found.
    pub fn apply_trait_buffs(&mut self, trait_name: &str, trait_def: &TraitDef) -> Vec<u32> {
        let mut handles = Vec::new();
        for (stat, add, mul) in &trait_def.buffs {
            let h = self.add_buff(stat, *add, *mul, -1.0, &format!("trait:{}", trait_name));
            handles.push(h);
        }
        handles
    }

    /// Remove a trait's buffs by removing all tracked handles.
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

    /// Set a boolean flag.
    pub fn set_flag(&mut self, name: &str) {
        self.flags.insert(name.to_string(), true);
    }

    /// Clear a boolean flag.
    pub fn clear_flag(&mut self, name: &str) {
        self.flags.remove(name);
    }

    /// Check if a flag is set.
    pub fn has_flag(&self, name: &str) -> bool {
        self.flags.get(name).copied().unwrap_or(false)
    }

    /// Get all set flag names.
    pub fn get_flags(&self) -> Vec<String> {
        self.flags.keys().cloned().collect()
    }

    /// Add XP. Returns number of levels gained.
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
    pub fn get_stat_names(&self) -> Vec<String> {
        self.attributes.keys().cloned().collect()
    }

    /// Count active buffs. If `stat` is Some, count only buffs targeting that stat.
    pub fn get_buff_count(&self, stat: Option<&str>) -> usize {
        self.buffs.values()
            .filter(|b| stat.map_or(true, |s| b.stat == s))
            .count()
    }

    /// Add `amount` to current action points, capped at the maximum.
    /// Returns the new value.
    pub fn recover_action_points(&mut self, amount: f64) -> f64 {
        if let Some(ap) = self.action_points.as_mut() {
            ap.current = (ap.current + amount).min(ap.max);
            ap.current
        } else { 0.0 }
    }

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
pub struct StatsRegistry {
    /// Named trait definitions.
    pub traits: HashMap<String, TraitDef>,
    /// Named race archetypes: (base overrides, trait names).
    pub races: HashMap<String, (HashMap<String, f64>, Vec<String>)>,
    /// Named class archetypes.
    pub classes: HashMap<String, (HashMap<String, f64>, Vec<String>)>,
}

impl StatsRegistry {
    /// Create a new empty registry.
    pub fn new() -> Self {
        Self {
            traits: HashMap::new(),
            races: HashMap::new(),
            classes: HashMap::new(),
        }
    }

    /// Define a named trait by its buff bundle.
    pub fn define_trait(&mut self, name: &str, buffs: Vec<(String, f64, f64)>) {
        self.traits.insert(name.to_string(), TraitDef { buffs });
    }

    /// Define a race archetype.
    pub fn define_race(
        &mut self,
        name: &str,
        bases: HashMap<String, f64>,
        trait_names: Vec<String>,
    ) {
        self.races.insert(name.to_string(), (bases, trait_names));
    }

    /// Define a class archetype.
    pub fn define_class(
        &mut self,
        name: &str,
        bases: HashMap<String, f64>,
        trait_names: Vec<String>,
    ) {
        self.classes.insert(name.to_string(), (bases, trait_names));
    }

    /// Apply archetypes (race + class) to a new Sheet.
    pub fn apply_archetypes(
        &self,
        sheet: &mut Sheet,
        race: Option<&str>,
        class: Option<&str>,
    ) {
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
                    sheet.active_traits.entry(tn.clone()).or_default().extend(handles);
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
