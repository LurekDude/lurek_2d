//! Resource definition with capacity, flow, decay, and overflow policy.



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