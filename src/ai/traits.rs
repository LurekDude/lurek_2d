//! personality trait profiles and timed trait modifiers.
use std::collections::HashMap;

// ---- Type: TraitModifier ----

/// A temporary or permanent additive delta applied on top of a base trait value.
pub struct TraitModifier {
    /// Name of the trait this modifier affects.
    pub trait_name: String,
    /// Additive delta in `[-1.0, 1.0]`. May bring the effective trait value outside its base range before the final clamp.
    pub delta: f32,
    /// Remaining seconds until this modifier expires, or `None` for permanent.
    pub remaining: Option<f32>,
    /// Human-readable label identifying the source (e.g. `"berserk_buff"`, `"potion_courage"`). Used for targeted modifier removal.
    pub source: String,
}

impl TraitModifier {
    /// Create a new modifier.
    pub fn new(trait_name: &str, delta: f32, duration: Option<f32>, source: &str) -> Self {
        Self {
            trait_name: trait_name.to_string(),
            delta,
            remaining: duration,
            source: source.to_string(),
        }
    }

    /// Return `true` if a timed modifier has expired (remaining 0).
    pub fn is_expired(&self) -> bool {
        self.remaining.map(|r| r <= 0.0).unwrap_or(false)
    }

    /// Advances the modifier timer. Has no effect on permanent modifiers.
    pub fn tick(&mut self, dt: f32) {
        if let Some(ref mut rem) = self.remaining {
            *rem -= dt;
        }
    }
}

// ---- Type: TraitProfile ----

/// Named float trait profile for an AI agent.
#[derive(Default)]
pub struct TraitProfile {
    /// Base trait values, each in `[0.0, 1.0]`.
    pub(crate) base_values: HashMap<String, f32>,
    /// Active additive modifiers (timed or permanent).
    pub(crate) modifiers: Vec<TraitModifier>,
    /// Optional archetype name this profile was instantiated from.
    pub(crate) archetype: Option<String>,
}

impl TraitProfile {
    /// Create a new empty trait profile with no base traits and no modifiers.
    pub fn new() -> Self {
        Self::default()
    }

    /// Create a trait profile from a named archetype with optional variance jitter.
    pub fn from_archetype(archetypes: &TraitArchetypes, name: &str, variance: f32) -> Option<Self> {
        let base = archetypes.get(name)?;
        let mut profile = Self::new();
        profile.archetype = Some(name.to_string());
        for (trait_name, &value) in base {
            let jitter = if variance > 0.0 {
                // Deterministic per-trait jitter based on trait name hash
                let h = simple_hash(trait_name);
                let normalized = (h % 10001) as f32 / 10000.0; // [0,1]
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

    /// Set the base value for a trait, clamped to `[0.0, 1.0]`.
    pub fn set(&mut self, name: &str, value: f32) {
        self.base_values
            .insert(name.to_string(), value.clamp(0.0, 1.0));
    }

    /// Return the effective trait value (base + all active modifier deltas), clamped to `[0.0, 1.0]`.
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

    /// Return the raw base value for a trait without applying modifiers.
    pub fn get_base(&self, name: &str) -> f32 {
        self.base_values.get(name).copied().unwrap_or(0.0)
    }

    /// Add an additive modifier to a trait with optional duration.
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

    /// Remove all modifiers whose `source` field matches the given string.
    pub fn remove_modifiers_by_source(&mut self, source: &str) {
        self.modifiers.retain(|m| m.source != source);
    }

    /// Advances modifier timers by `dt` seconds and removes expired timed modifiers.
    pub fn update(&mut self, dt: f32) {
        for m in &mut self.modifiers {
            m.tick(dt);
        }
        self.modifiers.retain(|m| !m.is_expired());
    }

    /// Return a `Vec` of all base trait names defined in this profile.
    pub fn trait_names(&self) -> Vec<&str> {
        self.base_values.keys().map(|s| s.as_str()).collect()
    }

    /// Return the number of base traits defined in this profile.
    pub fn trait_count(&self) -> usize {
        self.base_values.len()
    }

    /// Return `true` if a base value for `name` has been set.
    pub fn has(&self, name: &str) -> bool {
        self.base_values.contains_key(name)
    }

    /// Linearly interpolates all base trait values toward those of `other` by factor `t`, clamped to `[0.0, 1.0]`.
    pub fn lerp_toward(&mut self, other: &TraitProfile, t: f32) {
        let t = t.clamp(0.0, 1.0);
        for (name, &target) in &other.base_values {
            let current = self.base_values.get(name).copied().unwrap_or(0.0);
            self.base_values
                .insert(name.clone(), current + (target - current) * t);
        }
    }

    /// Return the archetype name this profile was created from, if any.
    pub fn archetype(&self) -> Option<&str> {
        self.archetype.as_deref()
    }
}

// ---- Type: TraitArchetypes ----

/// Registry of named archetypal trait profiles used for agent instantiation.
#[derive(Default)]
pub struct TraitArchetypes {
    archetypes: HashMap<String, HashMap<String, f32>>,
}

impl TraitArchetypes {
    /// Create an empty archetype registry.
    pub fn new() -> Self {
        Self::default()
    }

    /// Registers a named archetype with its trait values.
    pub fn register(&mut self, name: &str, traits: HashMap<String, f32>) {
        let clamped: HashMap<String, f32> = traits
            .into_iter()
            .map(|(k, v)| (k, v.clamp(0.0, 1.0)))
            .collect();
        self.archetypes.insert(name.to_string(), clamped);
    }

    /// Return the trait map for a named archetype, or `None` if not found.
    pub fn get(&self, name: &str) -> Option<&HashMap<String, f32>> {
        self.archetypes.get(name)
    }

    /// Return a list of all registered archetype names.
    pub fn names(&self) -> Vec<&str> {
        self.archetypes.keys().map(|s| s.as_str()).collect()
    }

    /// Return the number of registered archetypes.
    pub fn count(&self) -> usize {
        self.archetypes.len()
    }
}

// ---- Type: Helpers ----

/// Minimal deterministic hash for a string - used for variance jitter only.
fn simple_hash(s: &str) -> u64 {
    let mut h: u64 = 0xcbf29ce484222325;
    for byte in s.bytes() {
        h ^= byte as u64;
        h = h.wrapping_mul(0x100000001b3);
    }
    h
}

