//! Resource definition with capacity, flow, decay, and overflow policy.
//!
//! This module is part of Luna2D's `resource` subsystem and provides the implementation
//! details for resource-related operations and data management.
//! Key types exported from this module: `OverflowPolicy`, `Resource`.
//! Primary functions: `as_str()`, `from_str()`, `new()`, `name()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.



/// Policy governing what happens when adding exceeds capacity.
///
/// # Variants
/// - `Excess` — Excess variant.
/// - `Clamp` — Clamp variant.
/// - `The` — The variant.
/// - `Lose` — Lose variant.
/// - `Value` — Value variant.
/// - `Wrap` — Wrap variant.
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
    /// Returns the string name of this policy. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            OverflowPolicy::Clamp => "clamp",
            OverflowPolicy::Lose => "lose",
            OverflowPolicy::Wrap => "wrap",
        }
    }

    /// Parses a string into an OverflowPolicy. Defaults to Clamp for unknown strings.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
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
///
/// # Fields
/// - `name` — `String`.
/// - `value` — `f64`.
/// - `capacity` — `f64`.
/// - `minimum` — `f64`.
/// - `flow_rate` — `f64`.
/// - `decay_rate` — `f64`.
/// - `decay_percent` — `f64`.
/// - `interest_rate` — `f64`.
/// - `upkeep` — `f64`.
/// - `overflow` — `OverflowPolicy`.
/// - `group` — `String`.
/// - `enabled` — `bool`.
/// - `visible` — `bool`.
/// - `locked` — `bool`.
/// - `reserved` — `f64`.
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
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `capacity` — `f64`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Returns the resource name. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&str`.
    pub fn name(&self) -> &str {
        &self.name
    }

    /// Returns the current value. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn value(&self) -> f64 {
        self.value
    }

    /// Sets the value, clamped to [minimum, capacity].
    ///
    /// # Parameters
    /// - `v` — `f64`.
    pub fn set_value(&mut self, v: f64) {
        self.value = self.clamp(v);
    }

    /// Returns the capacity (-1 = unlimited). Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn capacity(&self) -> f64 {
        self.capacity
    }

    /// Sets the capacity. Replaces the current capacity value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `c` — `f64`.
    pub fn set_capacity(&mut self, c: f64) {
        self.capacity = c;
        self.value = self.clamp(self.value);
    }

    /// Returns the minimum value. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn minimum(&self) -> f64 {
        self.minimum
    }

    /// Sets the minimum value. Replaces the current minimum value; callers hold responsibility for maintaining consistency with related fields.
///
/// # Parameters
/// - `m` — `f64`
    pub fn set_minimum(&mut self, m: f64) {
        self.minimum = m;
        self.value = self.clamp(self.value);
    }

    /// Returns the overflow policy. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&OverflowPolicy`.
    pub fn overflow(&self) -> &OverflowPolicy {
        &self.overflow
    }

    /// Sets the overflow policy. Replaces the current overflow value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `policy` — `OverflowPolicy`.
    pub fn set_overflow(&mut self, policy: OverflowPolicy) {
        self.overflow = policy;
    }

    /// Returns the per-second flow rate (income).
    ///
    /// # Returns
    /// `f64`.
    pub fn flow_rate(&self) -> f64 {
        self.flow_rate
    }

    /// Sets the per-second flow rate. Replaces the current flow rate value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `r` — `f64`.
    pub fn set_flow_rate(&mut self, r: f64) {
        self.flow_rate = r;
    }

    /// Returns the per-second flat decay rate. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn decay_rate(&self) -> f64 {
        self.decay_rate
    }

    /// Sets the per-second flat decay rate. Replaces the current decay rate value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `r` — `f64`.
    pub fn set_decay_rate(&mut self, r: f64) {
        self.decay_rate = r;
    }

    /// Returns the per-second proportional decay (0.1 = 10%/s).
    ///
    /// # Returns
    /// `f64`.
    pub fn decay_percent(&self) -> f64 {
        self.decay_percent
    }

    /// Sets the per-second proportional decay. Replaces the current decay percent value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `p` — `f64`.
    pub fn set_decay_percent(&mut self, p: f64) {
        self.decay_percent = p;
    }

    /// Returns the per-second proportional interest rate.
    ///
    /// # Returns
    /// `f64`.
    pub fn interest_rate(&self) -> f64 {
        self.interest_rate
    }

    /// Sets the per-second proportional interest rate.
    ///
    /// # Parameters
    /// - `r` — `f64`.
    pub fn set_interest_rate(&mut self, r: f64) {
        self.interest_rate = r;
    }

    /// Returns the per-second upkeep cost. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn upkeep(&self) -> f64 {
        self.upkeep
    }

    /// Sets the per-second upkeep cost. Replaces the current upkeep value; callers hold responsibility for maintaining consistency with related fields.
///
/// # Parameters
/// - `u` — `f64`
    pub fn set_upkeep(&mut self, u: f64) {
        self.upkeep = u;
    }

    /// Returns the group tag. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&str`.
    pub fn group(&self) -> &str {
        &self.group
    }

    /// Sets the group tag. Replaces the current group value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `g` — `&str`.
    pub fn set_group(&mut self, g: &str) {
        self.group = g.to_string();
    }

    /// Returns whether tick processing is enabled.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }

    /// Enables or disables tick processing. Replaces the current enabled value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `e` — `bool`.
    pub fn set_enabled(&mut self, e: bool) {
        self.enabled = e;
    }

    /// Returns the UI visibility hint. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_visible(&self) -> bool {
        self.visible
    }

    /// Sets the UI visibility hint. Replaces the current visible value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `v` — `bool`.
    pub fn set_visible(&mut self, v: bool) {
        self.visible = v;
    }

    /// Returns whether modifications (add/spend) are blocked.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_locked(&self) -> bool {
        self.locked
    }

    /// Locks or unlocks modifications. Replaces the current locked value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `l` — `bool`.
    pub fn set_locked(&mut self, l: bool) {
        self.locked = l;
    }

    /// Returns the reserved amount. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn reserved(&self) -> f64 {
        self.reserved
    }

    /// Returns the available amount (value - reserved).
    ///
    /// # Returns
    /// `f64`.
    pub fn available(&self) -> f64 {
        self.value - self.reserved
    }

    /// Computes the net rate: flowRate - decayRate - upkeep + (value * interest) - (value * decay%).
    ///
    /// # Returns
    /// `f64`.
    pub fn net_rate(&self) -> f64 {
        self.flow_rate - self.decay_rate - self.upkeep + (self.value * self.interest_rate)
            - (self.value * self.decay_percent)
    }

    /// Adds amount to the resource. Returns the excess that did not fit.
    /// Returns the full amount if locked.
    ///
    /// # Parameters
    /// - `amount` — `f64`.
    ///
    /// # Returns
    /// `f64`.
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
    ///
    /// # Parameters
    /// - `amount` — `f64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn spend(&mut self, amount: f64) -> bool {
        if self.locked || self.available() < amount {
            return false;
        }
        self.value -= amount;
        true
    }

    /// Returns true if available >= amount. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `amount` — `f64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn can_afford(&self, amount: f64) -> bool {
        !self.locked && self.available() >= amount
    }

    /// Increases the reserved amount. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `amount` — `f64`.
    pub fn reserve(&mut self, amount: f64) {
        self.reserved += amount;
    }

    /// Decreases the reserved amount (floored at 0).
    ///
    /// # Parameters
    /// - `amount` — `f64`.
    pub fn unreserve(&mut self, amount: f64) {
        self.reserved = (self.reserved - amount).max(0.0);
    }

    /// Applies all rates for dt seconds. No-op when disabled.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
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