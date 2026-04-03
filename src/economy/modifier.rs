//! Resource modifiers and conversion rules.
//!
//! This module is part of Luna2D's `resource` subsystem and provides the implementation
//! details for modifier-related operations and data management.
//! Key types exported from this module: `ModifierType`, `Modifier`, `ConversionRule`.
//! Primary functions: `as_str()`, `from_str()`, `new()`, `mod_type()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.


/// Modifier type for conversion rules. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Multiplies` — Multiplies variant.
/// - `Multiply` — Multiply variant.
/// - `Adds` — Adds variant.
/// - `Add` — Add variant.
/// - `Overrides` — Overrides variant.
/// - `Set` — Set variant.
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
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            ModifierType::Multiply => "multiply",
            ModifierType::Add => "add",
            ModifierType::Set => "set",
        }
    }

    /// Parses a string into a ModifierType. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
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
///
/// # Fields
/// - `mod_type` — `ModifierType`.
/// - `value` — `f64`.
/// - `duration` — `f64`.
/// - `remaining` — `f64`.
/// - `source` — `String`.
/// - `target` — `String`.
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
    /// Creates a new modifier. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `od_type` — `ModifierType`.
    /// - `value` — `f64`.
    /// - `duration` — `f64`.
    /// - `source` — `&str`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Returns the modifier type. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&ModifierType`.
    pub fn mod_type(&self) -> &ModifierType {
        &self.mod_type
    }

    /// Returns the modifier value. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn value(&self) -> f64 {
        self.value
    }

    /// Sets the modifier value. Replaces the current value value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `v` — `f64`.
    pub fn set_value(&mut self, v: f64) {
        self.value = v;
    }

    /// Returns the total duration. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn duration(&self) -> f64 {
        self.duration
    }

    /// Returns the remaining time. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn remaining(&self) -> f64 {
        self.remaining
    }

    /// Returns the source tag. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&str`.
    pub fn source(&self) -> &str {
        &self.source
    }

    /// Returns the target identifier. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&str`.
    pub fn target(&self) -> &str {
        &self.target
    }

    /// Sets the target identifier. Replaces the current target value; callers hold responsibility for maintaining consistency with related fields.
///
/// # Parameters
/// - `t` — `&str`
    pub fn set_target(&mut self, t: &str) {
        self.target = t.to_string();
    }

    /// Returns true if the modifier has expired.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_expired(&self) -> bool {
        self.duration > 0.0 && self.remaining <= 0.0
    }

    /// Returns true if the modifier is permanent (duration <= 0).
    ///
    /// # Returns
    /// `bool`.
    pub fn is_permanent(&self) -> bool {
        self.duration <= 0.0
    }

    /// Advances the expiry countdown. Call once per frame with the elapsed time in seconds.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    pub fn update(&mut self, dt: f64) {
        if self.duration > 0.0 {
            self.remaining = (self.remaining - dt).max(0.0);
        }
    }
}

/// A rule for converting one resource type to another.
///
/// # Fields
/// - `from` — `String`.
/// - `to` — `String`.
/// - `rate` — `f64`.
/// - `fee` — `f64`.
/// - `cooldown` — `f64`.
/// - `cooldown_remaining` — `f64`.
/// - `min_amount` — `f64`.
/// - `max_amount` — `f64`.
/// - `modifiers` — `Vec<Modifier>`.
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
    /// Creates a new conversion rule. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `from` — `&str`.
    /// - `o` — `&str`.
    /// - `rate` — `f64`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Returns the source resource name. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&str`.
    pub fn from(&self) -> &str {
        &self.from
    }

    /// Returns the destination resource name. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&str`.
    pub fn to(&self) -> &str {
        &self.to
    }

    /// Returns the base conversion rate. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn rate(&self) -> f64 {
        self.rate
    }

    /// Sets the base conversion rate. Replaces the current rate value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `r` — `f64`.
    pub fn set_rate(&mut self, r: f64) {
        self.rate = r;
    }

    /// Returns the fee applied per conversion. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn fee(&self) -> f64 {
        self.fee
    }

    /// Sets the fee. Replaces the current fee value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `f` — `f64`.
    pub fn set_fee(&mut self, f: f64) {
        self.fee = f;
    }

    /// Returns the cooldown duration in seconds.
    ///
    /// # Returns
    /// `f64`.
    pub fn cooldown(&self) -> f64 {
        self.cooldown
    }

    /// Sets the cooldown duration. Replaces the current cooldown value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `c` — `f64`.
    pub fn set_cooldown(&mut self, c: f64) {
        self.cooldown = c;
    }

    /// Returns the minimum conversion amount. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn min_amount(&self) -> f64 {
        self.min_amount
    }

    /// Sets the minimum conversion amount. Replaces the current min amount value; callers hold responsibility for maintaining consistency with related fields.
///
/// # Parameters
/// - `m` — `f64`
    pub fn set_min_amount(&mut self, m: f64) {
        self.min_amount = m;
    }

    /// Returns the maximum conversion amount. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn max_amount(&self) -> f64 {
        self.max_amount
    }

    /// Sets the maximum conversion amount. Replaces the current max amount value; callers hold responsibility for maintaining consistency with related fields.
///
/// # Parameters
/// - `m` — `f64`
    pub fn set_max_amount(&mut self, m: f64) {
        self.max_amount = m;
    }

    /// Returns true if the rule is on cooldown.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_on_cooldown(&self) -> bool {
        self.cooldown_remaining > 0.0
    }

    /// Resets the cooldown timer. Consult the module-level documentation for the broader usage context and preconditions.
    pub fn reset_cooldown(&mut self) {
        self.cooldown_remaining = 0.0;
    }

    /// Triggers the cooldown period. Consult the module-level documentation for the broader usage context and preconditions.
    pub fn start_cooldown(&mut self) {
        self.cooldown_remaining = self.cooldown;
    }

    /// Updates the cooldown timer. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    pub fn update_cooldown(&mut self, dt: f64) {
        if self.cooldown_remaining > 0.0 {
            self.cooldown_remaining = (self.cooldown_remaining - dt).max(0.0);
        }
    }

    /// Adds a modifier to this rule. The insertion is O(1) amortised unless a resize is triggered.
///
/// # Parameters
/// - `m` — `Modifier`
    pub fn add_modifier(&mut self, m: Modifier) {
        self.modifiers.push(m);
    }

    /// Removes a modifier by index. Returns true if removed.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_modifier(&mut self, index: usize) -> bool {
        if index < self.modifiers.len() {
            self.modifiers.remove(index);
            true
        } else {
            false
        }
    }

    /// Returns a reference to all modifiers. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&[Modifier]`.
    pub fn modifiers(&self) -> &[Modifier] {
        &self.modifiers
    }

    /// Returns a mutable reference to all modifiers.
    ///
    /// # Returns
    /// `&mut [Modifier]`.
    pub fn modifiers_mut(&mut self) -> &mut [Modifier] {
        &mut self.modifiers
    }

    /// Clears all modifiers. After this call the container is in the same state as immediately after construction.
    pub fn clear_modifiers(&mut self) {
        self.modifiers.clear();
    }

    /// Computes the effective rate after applying all non-expired modifiers.
    ///
    /// # Returns
    /// `f64`.
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