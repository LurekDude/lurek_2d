//! Resource economy system: named resources with capacity, flow rates, decay,
//! interest, upkeep, overflow policies, reservations, and conversions.
//!
//! Designed for RTS, management, survival, and RPG economy patterns where
//! the game tracks multiple named numeric values (gold, wood, mana, food)
//! that change over time with configurable rates.

use std::collections::HashMap;

/// Policy governing what happens when adding exceeds capacity.
#[derive(Debug, Clone, PartialEq)]
pub enum OverflowPolicy {
    /// Excess is lost; value is clamped to capacity (default).
    Clamp,
    /// The entire addition is rejected if it would exceed capacity.
    Lose,
    /// Value wraps around from minimum.
    Wrap,
}

impl OverflowPolicy {
    /// Returns the string name of this policy.
    pub fn as_str(&self) -> &'static str {
        match self {
            OverflowPolicy::Clamp => "clamp",
            OverflowPolicy::Lose => "lose",
            OverflowPolicy::Wrap => "wrap",
        }
    }

    /// Parses a string into an OverflowPolicy. Defaults to Clamp for unknown strings.
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Self {
        match s {
            "lose" => OverflowPolicy::Lose,
            "wrap" => OverflowPolicy::Wrap,
            _ => OverflowPolicy::Clamp,
        }
    }
}

/// A single named numeric resource with rates, capacity, overflow policy, and reservation.
#[derive(Debug, Clone)]
pub struct Resource {
    name: String,
    value: f64,
    capacity: f64,
    minimum: f64,
    flow_rate: f64,
    decay_rate: f64,
    decay_percent: f64,
    interest_rate: f64,
    upkeep: f64,
    overflow: OverflowPolicy,
    group: String,
    enabled: bool,
    visible: bool,
    locked: bool,
    reserved: f64,
}

impl Resource {
    /// Creates a new resource with the given name and capacity (-1 = unlimited).
    pub fn new(name: &str, capacity: f64) -> Self {
        Resource {
            name: name.to_string(),
            value: 0.0,
            capacity,
            minimum: 0.0,
            flow_rate: 0.0,
            decay_rate: 0.0,
            decay_percent: 0.0,
            interest_rate: 0.0,
            upkeep: 0.0,
            overflow: OverflowPolicy::Clamp,
            group: String::new(),
            enabled: true,
            visible: true,
            locked: false,
            reserved: 0.0,
        }
    }

    /// Returns the resource name.
    pub fn name(&self) -> &str {
        &self.name
    }

    /// Returns the current value.
    pub fn value(&self) -> f64 {
        self.value
    }

    /// Sets the value, clamped to [minimum, capacity].
    pub fn set_value(&mut self, v: f64) {
        self.value = self.clamp(v);
    }

    /// Returns the capacity (-1 = unlimited).
    pub fn capacity(&self) -> f64 {
        self.capacity
    }

    /// Sets the capacity.
    pub fn set_capacity(&mut self, c: f64) {
        self.capacity = c;
        self.value = self.clamp(self.value);
    }

    /// Returns the minimum value.
    pub fn minimum(&self) -> f64 {
        self.minimum
    }

    /// Sets the minimum value.
    pub fn set_minimum(&mut self, m: f64) {
        self.minimum = m;
        self.value = self.clamp(self.value);
    }

    /// Returns the overflow policy.
    pub fn overflow(&self) -> &OverflowPolicy {
        &self.overflow
    }

    /// Sets the overflow policy.
    pub fn set_overflow(&mut self, policy: OverflowPolicy) {
        self.overflow = policy;
    }

    /// Returns the per-second flow rate (income).
    pub fn flow_rate(&self) -> f64 {
        self.flow_rate
    }

    /// Sets the per-second flow rate.
    pub fn set_flow_rate(&mut self, r: f64) {
        self.flow_rate = r;
    }

    /// Returns the per-second flat decay rate.
    pub fn decay_rate(&self) -> f64 {
        self.decay_rate
    }

    /// Sets the per-second flat decay rate.
    pub fn set_decay_rate(&mut self, r: f64) {
        self.decay_rate = r;
    }

    /// Returns the per-second proportional decay (0.1 = 10%/s).
    pub fn decay_percent(&self) -> f64 {
        self.decay_percent
    }

    /// Sets the per-second proportional decay.
    pub fn set_decay_percent(&mut self, p: f64) {
        self.decay_percent = p;
    }

    /// Returns the per-second proportional interest rate.
    pub fn interest_rate(&self) -> f64 {
        self.interest_rate
    }

    /// Sets the per-second proportional interest rate.
    pub fn set_interest_rate(&mut self, r: f64) {
        self.interest_rate = r;
    }

    /// Returns the per-second upkeep cost.
    pub fn upkeep(&self) -> f64 {
        self.upkeep
    }

    /// Sets the per-second upkeep cost.
    pub fn set_upkeep(&mut self, u: f64) {
        self.upkeep = u;
    }

    /// Returns the group tag.
    pub fn group(&self) -> &str {
        &self.group
    }

    /// Sets the group tag.
    pub fn set_group(&mut self, g: &str) {
        self.group = g.to_string();
    }

    /// Returns whether tick processing is enabled.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }

    /// Enables or disables tick processing.
    pub fn set_enabled(&mut self, e: bool) {
        self.enabled = e;
    }

    /// Returns the UI visibility hint.
    pub fn is_visible(&self) -> bool {
        self.visible
    }

    /// Sets the UI visibility hint.
    pub fn set_visible(&mut self, v: bool) {
        self.visible = v;
    }

    /// Returns whether modifications (add/spend) are blocked.
    pub fn is_locked(&self) -> bool {
        self.locked
    }

    /// Locks or unlocks modifications.
    pub fn set_locked(&mut self, l: bool) {
        self.locked = l;
    }

    /// Returns the reserved amount.
    pub fn reserved(&self) -> f64 {
        self.reserved
    }

    /// Returns the available amount (value - reserved).
    pub fn available(&self) -> f64 {
        self.value - self.reserved
    }

    /// Computes the net rate: flowRate - decayRate - upkeep + (value * interest) - (value * decay%).
    pub fn net_rate(&self) -> f64 {
        self.flow_rate - self.decay_rate - self.upkeep + (self.value * self.interest_rate)
            - (self.value * self.decay_percent)
    }

    /// Adds amount to the resource. Returns the excess that did not fit.
    /// Returns the full amount if locked.
    pub fn add(&mut self, amount: f64) -> f64 {
        if self.locked {
            return amount;
        }
        match self.overflow {
            OverflowPolicy::Clamp => {
                let new_val = self.value + amount;
                let clamped = self.clamp(new_val);
                let excess = (new_val - clamped).max(0.0);
                self.value = clamped;
                excess
            }
            OverflowPolicy::Lose => {
                let new_val = self.value + amount;
                if self.capacity >= 0.0 && new_val > self.capacity {
                    amount
                } else {
                    self.value = self.clamp(new_val);
                    0.0
                }
            }
            OverflowPolicy::Wrap => {
                let new_val = self.value + amount;
                if self.capacity >= 0.0 && new_val > self.capacity {
                    let range = self.capacity - self.minimum;
                    if range > 0.0 {
                        self.value = self.minimum + ((new_val - self.minimum) % range);
                    } else {
                        self.value = self.minimum;
                    }
                } else {
                    self.value = self.clamp(new_val);
                }
                0.0
            }
        }
    }

    /// Spends the given amount if available >= amount. Returns false if locked or insufficient.
    pub fn spend(&mut self, amount: f64) -> bool {
        if self.locked || self.available() < amount {
            return false;
        }
        self.value -= amount;
        true
    }

    /// Returns true if available >= amount.
    pub fn can_afford(&self, amount: f64) -> bool {
        !self.locked && self.available() >= amount
    }

    /// Increases the reserved amount.
    pub fn reserve(&mut self, amount: f64) {
        self.reserved += amount;
    }

    /// Decreases the reserved amount (floored at 0).
    pub fn unreserve(&mut self, amount: f64) {
        self.reserved = (self.reserved - amount).max(0.0);
    }

    /// Applies all rates for dt seconds. No-op when disabled.
    pub fn tick(&mut self, dt: f64) {
        if !self.enabled {
            return;
        }
        let delta = self.net_rate() * dt;
        self.value = self.clamp(self.value + delta);
    }

    fn clamp(&self, v: f64) -> f64 {
        let v = v.max(self.minimum);
        if self.capacity >= 0.0 {
            v.min(self.capacity)
        } else {
            v
        }
    }
}

/// Modifier type for conversion rules.
#[derive(Debug, Clone, PartialEq)]
pub enum ModifierType {
    /// Multiplies the conversion rate.
    Multiply,
    /// Adds to the conversion rate.
    Add,
    /// Overrides the conversion rate.
    Set,
}

impl ModifierType {
    /// Returns the string name of this modifier type.
    pub fn as_str(&self) -> &'static str {
        match self {
            ModifierType::Multiply => "multiply",
            ModifierType::Add => "add",
            ModifierType::Set => "set",
        }
    }

    /// Parses a string into a ModifierType.
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Self {
        match s {
            "add" => ModifierType::Add,
            "set" => ModifierType::Set,
            _ => ModifierType::Multiply,
        }
    }
}

/// A rate modifier that can be attached to conversion rules.
#[derive(Debug, Clone)]
pub struct Modifier {
    mod_type: ModifierType,
    value: f64,
    duration: f64,
    remaining: f64,
    source: String,
    target: String,
}

impl Modifier {
    /// Creates a new modifier.
    pub fn new(mod_type: ModifierType, value: f64, duration: f64, source: &str) -> Self {
        Modifier {
            mod_type,
            value,
            duration,
            remaining: if duration > 0.0 { duration } else { 0.0 },
            source: source.to_string(),
            target: String::new(),
        }
    }

    /// Returns the modifier type.
    pub fn mod_type(&self) -> &ModifierType {
        &self.mod_type
    }

    /// Returns the modifier value.
    pub fn value(&self) -> f64 {
        self.value
    }

    /// Sets the modifier value.
    pub fn set_value(&mut self, v: f64) {
        self.value = v;
    }

    /// Returns the total duration.
    pub fn duration(&self) -> f64 {
        self.duration
    }

    /// Returns the remaining time.
    pub fn remaining(&self) -> f64 {
        self.remaining
    }

    /// Returns the source tag.
    pub fn source(&self) -> &str {
        &self.source
    }

    /// Returns the target identifier.
    pub fn target(&self) -> &str {
        &self.target
    }

    /// Sets the target identifier.
    pub fn set_target(&mut self, t: &str) {
        self.target = t.to_string();
    }

    /// Returns true if the modifier has expired.
    pub fn is_expired(&self) -> bool {
        self.duration > 0.0 && self.remaining <= 0.0
    }

    /// Returns true if the modifier is permanent (duration <= 0).
    pub fn is_permanent(&self) -> bool {
        self.duration <= 0.0
    }

    /// Advances the expiry countdown.
    pub fn update(&mut self, dt: f64) {
        if self.duration > 0.0 {
            self.remaining = (self.remaining - dt).max(0.0);
        }
    }
}

/// A rule for converting one resource type to another.
#[derive(Debug, Clone)]
pub struct ConversionRule {
    from: String,
    to: String,
    rate: f64,
    fee: f64,
    cooldown: f64,
    cooldown_remaining: f64,
    min_amount: f64,
    max_amount: f64,
    modifiers: Vec<Modifier>,
}

impl ConversionRule {
    /// Creates a new conversion rule.
    pub fn new(from: &str, to: &str, rate: f64) -> Self {
        ConversionRule {
            from: from.to_string(),
            to: to.to_string(),
            rate,
            fee: 0.0,
            cooldown: 0.0,
            cooldown_remaining: 0.0,
            min_amount: 0.0,
            max_amount: f64::MAX,
            modifiers: Vec::new(),
        }
    }

    /// Returns the source resource name.
    pub fn from(&self) -> &str {
        &self.from
    }

    /// Returns the destination resource name.
    pub fn to(&self) -> &str {
        &self.to
    }

    /// Returns the base conversion rate.
    pub fn rate(&self) -> f64 {
        self.rate
    }

    /// Sets the base conversion rate.
    pub fn set_rate(&mut self, r: f64) {
        self.rate = r;
    }

    /// Returns the fee applied per conversion.
    pub fn fee(&self) -> f64 {
        self.fee
    }

    /// Sets the fee.
    pub fn set_fee(&mut self, f: f64) {
        self.fee = f;
    }

    /// Returns the cooldown duration in seconds.
    pub fn cooldown(&self) -> f64 {
        self.cooldown
    }

    /// Sets the cooldown duration.
    pub fn set_cooldown(&mut self, c: f64) {
        self.cooldown = c;
    }

    /// Returns the minimum conversion amount.
    pub fn min_amount(&self) -> f64 {
        self.min_amount
    }

    /// Sets the minimum conversion amount.
    pub fn set_min_amount(&mut self, m: f64) {
        self.min_amount = m;
    }

    /// Returns the maximum conversion amount.
    pub fn max_amount(&self) -> f64 {
        self.max_amount
    }

    /// Sets the maximum conversion amount.
    pub fn set_max_amount(&mut self, m: f64) {
        self.max_amount = m;
    }

    /// Returns true if the rule is on cooldown.
    pub fn is_on_cooldown(&self) -> bool {
        self.cooldown_remaining > 0.0
    }

    /// Resets the cooldown timer.
    pub fn reset_cooldown(&mut self) {
        self.cooldown_remaining = 0.0;
    }

    /// Triggers the cooldown period.
    pub fn start_cooldown(&mut self) {
        self.cooldown_remaining = self.cooldown;
    }

    /// Updates the cooldown timer.
    pub fn update_cooldown(&mut self, dt: f64) {
        if self.cooldown_remaining > 0.0 {
            self.cooldown_remaining = (self.cooldown_remaining - dt).max(0.0);
        }
    }

    /// Adds a modifier to this rule.
    pub fn add_modifier(&mut self, m: Modifier) {
        self.modifiers.push(m);
    }

    /// Removes a modifier by index. Returns true if removed.
    pub fn remove_modifier(&mut self, index: usize) -> bool {
        if index < self.modifiers.len() {
            self.modifiers.remove(index);
            true
        } else {
            false
        }
    }

    /// Returns a reference to all modifiers.
    pub fn modifiers(&self) -> &[Modifier] {
        &self.modifiers
    }

    /// Clears all modifiers.
    pub fn clear_modifiers(&mut self) {
        self.modifiers.clear();
    }

    /// Computes the effective rate after applying all non-expired modifiers.
    pub fn effective_rate(&self) -> f64 {
        let mut rate = self.rate;
        let mut add_total = 0.0;
        let mut mul_total = 1.0;
        let mut set_val: Option<f64> = None;

        for m in &self.modifiers {
            if m.is_expired() {
                continue;
            }
            match m.mod_type() {
                ModifierType::Add => add_total += m.value(),
                ModifierType::Multiply => mul_total *= m.value(),
                ModifierType::Set => set_val = Some(m.value()),
            }
        }

        if let Some(sv) = set_val {
            rate = sv;
        } else {
            rate = (rate + add_total) * mul_total;
        }

        rate
    }
}

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
            for m in rule.modifiers.iter_mut() {
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
            if r.capacity <= 0.0 {
                return 0.0;
            }
            (r.value / r.capacity * 100.0).clamp(0.0, 100.0)
        } else {
            0.0
        }
    }

    /// Returns true when the named resource value has reached its capacity.
    pub fn is_full(&self, name: &str) -> bool {
        self.resources
            .get(name)
            .map(|r| r.value >= r.capacity)
            .unwrap_or(false)
    }

    /// Returns true when the named resource value is at or below its minimum.
    pub fn is_empty(&self, name: &str) -> bool {
        self.resources
            .get(name)
            .map(|r| r.value <= r.minimum)
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
