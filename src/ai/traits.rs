
//! - Defines the personality-trait model used by the AI module to store base
//!   values, temporary modifiers, and reusable archetype presets.
//! - Owns the profile logic that resolves effective trait values, advances and
//!   removes expiring modifiers, interpolates toward other profiles, and tracks origin archetypes.
//! - Keeps the archetype registry and deterministic hash helper used to build
//!   varied profiles from named presets with stable per-trait jitter.

use std::collections::HashMap;

/// Temporary additive change applied to one named trait.
pub struct TraitModifier {
    /// Trait key affected by this modifier.
    pub trait_name: String,
    /// Additive delta applied on top of the base value.
    pub delta: f32,
    /// Remaining lifetime in seconds; `None` means the modifier does not expire.
    pub remaining: Option<f32>,
    /// Human-readable source tag used for bulk removal.
    pub source: String,
}
impl TraitModifier {
    /// Create a modifier for one trait.
    pub fn new(trait_name: &str, delta: f32, duration: Option<f32>, source: &str) -> Self {
        Self {
            trait_name: trait_name.to_string(),
            delta,
            remaining: duration,
            source: source.to_string(),
        }
    }

    /// Return `true` when this modifier has reached zero remaining lifetime.
    pub fn is_expired(&self) -> bool {
        self.remaining.map(|r| r <= 0.0).unwrap_or(false)
    }

    /// Advance the modifier timer by `dt` seconds when it is time-limited.
    pub fn tick(&mut self, dt: f32) {
        if let Some(ref mut rem) = self.remaining {
            *rem -= dt;
        }
    }
}

#[derive(Default)]
/// Base trait values plus active temporary modifiers for one agent.
pub struct TraitProfile {
    /// Base value per trait key.
    pub(crate) base_values: HashMap<String, f32>,
    /// Active temporary modifiers layered on top of the base values.
    pub(crate) modifiers: Vec<TraitModifier>,
    /// Optional archetype name used to initialize this profile.
    pub(crate) archetype: Option<String>,
}
impl TraitProfile {
    /// Create an empty trait profile.
    pub fn new() -> Self {
        Self::default()
    }

    /// Build a profile from a registered archetype and optional deterministic variance.
    pub fn from_archetype(archetypes: &TraitArchetypes, name: &str, variance: f32) -> Option<Self> {
        let base = archetypes.get(name)?;
        let mut profile = Self::new();
        profile.archetype = Some(name.to_string());
        for (trait_name, &value) in base {
            let jitter = if variance > 0.0 {
                let h = simple_hash(trait_name);
                let normalized = (h % 10001) as f32 / 10000.0;
                (normalized * 2.0 - 1.0) * variance
            } else {
                0.0
            };
            profile
                .base_values
                .insert(trait_name.clone(), (value + jitter).clamp(0.0, 1.0));
        }
        Some(profile)
    }

    /// Set the base value for one trait and clamp it to `[0, 1]`.
    pub fn set(&mut self, name: &str, value: f32) {
        self.base_values
            .insert(name.to_string(), value.clamp(0.0, 1.0));
    }

    /// Return the resolved value for one trait after applying active modifiers.
    pub fn get(&self, name: &str) -> f32 {
        let base = self.base_values.get(name).copied().unwrap_or(0.0);
        let delta: f32 = self
            .modifiers
            .iter()
            .filter(|m| m.trait_name == name && !m.is_expired())
            .map(|m| m.delta)
            .sum();
        (base + delta).clamp(0.0, 1.0)
    }

    /// Return the unclamped base value for one trait without modifiers.
    pub fn get_base(&self, name: &str) -> f32 {
        self.base_values.get(name).copied().unwrap_or(0.0)
    }

    /// Add a temporary modifier to one trait.
    pub fn add_modifier(
        &mut self,
        trait_name: &str,
        delta: f32,
        duration: Option<f32>,
        source: &str,
    ) {
        self.modifiers
            .push(TraitModifier::new(trait_name, delta, duration, source));
    }

    /// Remove all modifiers that originated from the given source tag.
    pub fn remove_modifiers_by_source(&mut self, source: &str) {
        self.modifiers.retain(|m| m.source != source);
    }

    /// Advance active modifier timers and discard expired entries.
    pub fn update(&mut self, dt: f32) {
        for m in &mut self.modifiers {
            m.tick(dt);
        }
        self.modifiers.retain(|m| !m.is_expired());
    }

    /// Return all registered trait names.
    pub fn trait_names(&self) -> Vec<&str> {
        self.base_values.keys().map(|s| s.as_str()).collect()
    }

    /// Return the number of base traits stored in this profile.
    pub fn trait_count(&self) -> usize {
        self.base_values.len()
    }

    /// Return `true` when the profile has a base value for the named trait.
    pub fn has(&self, name: &str) -> bool {
        self.base_values.contains_key(name)
    }

    /// Move all shared trait values toward another profile by factor `t`.
    pub fn lerp_toward(&mut self, other: &TraitProfile, t: f32) {
        let t = t.clamp(0.0, 1.0);
        for (name, &target) in &other.base_values {
            let current = self.base_values.get(name).copied().unwrap_or(0.0);
            self.base_values
                .insert(name.clone(), current + (target - current) * t);
        }
    }

    /// Return the archetype name used to initialize this profile, when present.
    pub fn archetype(&self) -> Option<&str> {
        self.archetype.as_deref()
    }
}

#[derive(Default)]
/// Registry of named trait archetypes used to initialize agent profiles.
pub struct TraitArchetypes {
    /// Stored archetype trait maps keyed by archetype name.
    archetypes: HashMap<String, HashMap<String, f32>>,
}
impl TraitArchetypes {
    /// Create an empty archetype registry.
    pub fn new() -> Self {
        Self::default()
    }

    /// Register or replace one named archetype after clamping all values to `[0, 1]`.
    pub fn register(&mut self, name: &str, traits: HashMap<String, f32>) {
        let clamped: HashMap<String, f32> = traits
            .into_iter()
            .map(|(k, v)| (k, v.clamp(0.0, 1.0)))
            .collect();
        self.archetypes.insert(name.to_string(), clamped);
    }

    /// Return the trait map for one named archetype.
    pub fn get(&self, name: &str) -> Option<&HashMap<String, f32>> {
        self.archetypes.get(name)
    }

    /// Return all registered archetype names.
    pub fn names(&self) -> Vec<&str> {
        self.archetypes.keys().map(|s| s.as_str()).collect()
    }

    /// Return the number of registered archetypes.
    pub fn count(&self) -> usize {
        self.archetypes.len()
    }
}

/// Hash a string deterministically for archetype jitter generation.
fn simple_hash(s: &str) -> u64 {
    let mut h: u64 = 0xcbf29ce484222325;
    for byte in s.bytes() {
        h ^= byte as u64;
        h = h.wrapping_mul(0x100000001b3);
    }
    h
}
