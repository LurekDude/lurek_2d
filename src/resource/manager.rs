//! ResourceManager: multi-resource economy coordinator.

use std::collections::HashMap;

use super::modifier::ConversionRule;
use super::resource::Resource;

/// A manager that owns named resources and provides bulk operations and conversions.
#[derive(Debug)]
pub struct ResourceManager {
    resources: HashMap<String, Resource>,
    conversion_rules: Vec<ConversionRule>,
}

impl ResourceManager {
    /// Creates a new empty resource manager.
    pub fn new() -> Self {
        ResourceManager {
            resources: HashMap::new(),
            conversion_rules: Vec::new(),
        }
    }

    /// Creates and registers a new resource. Returns a mutable reference.
    pub fn new_resource(&mut self, name: &str, capacity: f64) -> &mut Resource {
        self.resources
            .entry(name.to_string())
            .or_insert_with(|| Resource::new(name, capacity))
    }

    /// Returns a reference to a resource by name.
    pub fn get_resource(&self, name: &str) -> Option<&Resource> {
        self.resources.get(name)
    }

    /// Returns a mutable reference to a resource by name.
    pub fn get_resource_mut(&mut self, name: &str) -> Option<&mut Resource> {
        self.resources.get_mut(name)
    }

    /// Returns true if a resource with the given name exists.
    pub fn has_resource(&self, name: &str) -> bool {
        self.resources.contains_key(name)
    }

    /// Returns all resource names.
    pub fn resource_names(&self) -> Vec<&str> {
        self.resources.keys().map(|s| s.as_str()).collect()
    }

    /// Removes a resource by name.
    pub fn remove_resource(&mut self, name: &str) {
        self.resources.remove(name);
    }

    /// Ticks all enabled resources.
    pub fn tick(&mut self, dt: f64) {
        for r in self.resources.values_mut() {
            r.tick(dt);
        }
        for rule in &mut self.conversion_rules {
            rule.update_cooldown(dt);
            for m in rule.modifiers_mut().iter_mut() {
                m.update(dt);
            }
        }
    }

    /// Convenience for tick(1.0) — designed for turn-based games.
    pub fn turn(&mut self) {
        self.tick(1.0);
    }

    /// Adds a conversion rule.
    pub fn add_conversion_rule(&mut self, rule: ConversionRule) {
        self.conversion_rules.push(rule);
    }

    /// Returns a reference to all conversion rules.
    pub fn conversion_rules(&self) -> &[ConversionRule] {
        &self.conversion_rules
    }

    /// Converts resources using the first matching rule for (from, to).
    /// Returns true if successful.
    pub fn convert(&mut self, from: &str, to: &str, amount: f64) -> bool {
        // Find matching rule
        let rule_idx = self
            .conversion_rules
            .iter()
            .position(|r| r.from() == from && r.to() == to);

        let rule_idx = match rule_idx {
            Some(i) => i,
            None => return false,
        };

        // Check cooldown and amount constraints
        let rule = &self.conversion_rules[rule_idx];
        if rule.is_on_cooldown() {
            return false;
        }
        if amount < rule.min_amount() || amount > rule.max_amount() {
            return false;
        }

        let effective_rate = rule.effective_rate();
        let fee = rule.fee();
        let total_cost = amount + fee;

        // Check source can afford
        let from_avail = self
            .resources
            .get(from)
            .map(|r| r.available())
            .unwrap_or(0.0);
        if from_avail < total_cost {
            return false;
        }

        let output = amount * effective_rate;

        // Execute conversion
        if let Some(src) = self.resources.get_mut(from) {
            src.spend(total_cost);
        }
        if let Some(dst) = self.resources.get_mut(to) {
            dst.add(output);
        }

        // Start cooldown
        self.conversion_rules[rule_idx].start_cooldown();

        true
    }

    /// Atomic exchange between two managers. Both sides must afford their amounts.
    pub fn exchange(
        &mut self,
        other: &mut ResourceManager,
        give_name: &str,
        give_amount: f64,
        get_name: &str,
        get_amount: f64,
    ) -> bool {
        let can_give = self
            .resources
            .get(give_name)
            .map(|r| r.can_afford(give_amount))
            .unwrap_or(false);
        let can_get = other
            .resources
            .get(get_name)
            .map(|r| r.can_afford(get_amount))
            .unwrap_or(false);

        if !can_give || !can_get {
            return false;
        }

        self.resources
            .get_mut(give_name)
            .unwrap()
            .spend(give_amount);
        other.resources.get_mut(get_name).unwrap().spend(get_amount);

        if let Some(r) = self.resources.get_mut(get_name) {
            r.add(get_amount);
        }
        if let Some(r) = other.resources.get_mut(give_name) {
            r.add(give_amount);
        }

        true
    }

    /// Returns the total value of all resources in the given group.
    pub fn total_by_group(&self, group: &str) -> f64 {
        self.resources
            .values()
            .filter(|r| r.group() == group)
            .map(|r| r.value())
            .sum()
    }

    /// Clears all resources and conversion rules.
    /// Returns value as a percentage of capacity (0.0–100.0). Returns 0 if capacity <= 0.
    pub fn percent(&self, name: &str) -> f64 {
        if let Some(r) = self.resources.get(name) {
            if r.capacity() <= 0.0 {
                return 0.0;
            }
            (r.value() / r.capacity() * 100.0).clamp(0.0, 100.0)
        } else {
            0.0
        }
    }

    /// Returns true when the named resource value has reached its capacity.
    pub fn is_full(&self, name: &str) -> bool {
        self.resources
            .get(name)
            .map(|r| r.value() >= r.capacity())
            .unwrap_or(false)
    }

    /// Returns true when the named resource value is at or below its minimum.
    pub fn is_empty(&self, name: &str) -> bool {
        self.resources
            .get(name)
            .map(|r| r.value() <= r.minimum())
            .unwrap_or(true)
    }

    /// Returns true only if every (name, amount) pair can be afforded simultaneously.
    pub fn can_afford_all(&self, needs: &[(&str, f64)]) -> bool {
        needs.iter().all(|(name, amount)| {
            self.resources
                .get(*name)
                .map(|r| r.can_afford(*amount))
                .unwrap_or(false)
        })
    }

    /// Atomically spends all listed amounts. Does nothing and returns false if any
    /// resource cannot afford its portion.
    pub fn spend_all(&mut self, needs: &[(&str, f64)]) -> bool {
        let ok = needs.iter().all(|(name, amount)| {
            self.resources
                .get(*name)
                .map(|r| r.can_afford(*amount))
                .unwrap_or(false)
        });
        if !ok {
            return false;
        }
        for (name, amount) in needs {
            if let Some(r) = self.resources.get_mut(*name) {
                r.spend(*amount);
            }
        }
        true
    }

    pub fn reset(&mut self) {
        self.resources.clear();
        self.conversion_rules.clear();
    }
}

impl Default for ResourceManager {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::resource::modifier::{Modifier, ModifierType};
    use crate::resource::resource::OverflowPolicy;

    #[test]
    fn resource_basic_ops() {
        let mut r = Resource::new("gold", 100.0);
        assert_eq!(r.value(), 0.0);
        r.set_value(50.0);
        assert_eq!(r.value(), 50.0);
        let excess = r.add(60.0);
        assert!((excess - 10.0).abs() < 1e-5);
        assert!((r.value() - 100.0).abs() < 1e-5);
    }

    #[test]
    fn resource_spend_and_afford() {
        let mut r = Resource::new("gold", 100.0);
        r.set_value(50.0);
        assert!(r.can_afford(30.0));
        assert!(r.spend(30.0));
        assert!((r.value() - 20.0).abs() < 1e-5);
        assert!(!r.spend(30.0));
    }

    #[test]
    fn resource_reservation() {
        let mut r = Resource::new("gold", 100.0);
        r.set_value(50.0);
        r.reserve(20.0);
        assert!((r.available() - 30.0).abs() < 1e-5);
        assert!(!r.can_afford(40.0));
        assert!(r.can_afford(30.0));
        r.unreserve(10.0);
        assert!((r.available() - 40.0).abs() < 1e-5);
    }

    #[test]
    fn resource_tick() {
        let mut r = Resource::new("gold", 1000.0);
        r.set_value(100.0);
        r.set_flow_rate(10.0);
        r.set_decay_rate(2.0);
        r.set_upkeep(1.0);
        r.tick(1.0);
        // net = 10 - 2 - 1 + 0 - 0 = 7
        assert!((r.value() - 107.0).abs() < 1e-5);
    }

    #[test]
    fn resource_locked() {
        let mut r = Resource::new("gold", 100.0);
        r.set_value(50.0);
        r.set_locked(true);
        assert!(!r.spend(10.0));
        assert!((r.add(10.0) - 10.0).abs() < 1e-5);
    }

    #[test]
    fn overflow_lose() {
        let mut r = Resource::new("gold", 100.0);
        r.set_value(90.0);
        r.set_overflow(OverflowPolicy::Lose);
        let excess = r.add(20.0);
        assert!((excess - 20.0).abs() < 1e-5);
        assert!((r.value() - 90.0).abs() < 1e-5);
    }

    #[test]
    fn overflow_wrap() {
        let mut r = Resource::new("gold", 100.0);
        r.set_value(90.0);
        r.set_overflow(OverflowPolicy::Wrap);
        r.add(20.0);
        assert!((r.value() - 10.0).abs() < 1e-5);
    }

    #[test]
    fn manager_convert() {
        let mut mgr = ResourceManager::new();
        mgr.new_resource("gold", 1000.0).set_value(500.0);
        mgr.new_resource("gems", 100.0);
        mgr.add_conversion_rule(ConversionRule::new("gold", "gems", 0.1));
        assert!(mgr.convert("gold", "gems", 100.0));
        let gold = mgr.get_resource("gold").unwrap();
        assert!((gold.value() - 400.0).abs() < 1e-5);
        let gems = mgr.get_resource("gems").unwrap();
        assert!((gems.value() - 10.0).abs() < 1e-5);
    }

    #[test]
    fn modifier_expiry() {
        let mut m = Modifier::new(ModifierType::Multiply, 2.0, 5.0, "buff");
        assert!(!m.is_expired());
        m.update(5.0);
        assert!(m.is_expired());
    }
}
