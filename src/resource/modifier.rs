//! Resource modifiers and conversion rules.


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

    /// Returns a mutable reference to all modifiers.
    pub fn modifiers_mut(&mut self) -> &mut [Modifier] {
        &mut self.modifiers
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