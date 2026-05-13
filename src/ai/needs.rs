//! needs and drive simulation for motivation-based decisions.

// ---- Type: Need ----

/// A single named motivational drive for an AI agent.
pub struct Need {
    /// Unique identifier for this need (e.g. `"hunger"`, `"safety"`).
    pub name: String,
    /// Current satisfaction level in `[0.0, 1.0]`. `1.0` = fully satisfied.
    pub value: f32,
    /// Amount subtracted per second during `update(dt)`.
    pub decay_rate: f32,
    /// Value below which this need is considered urgent.
    pub urgency_threshold: f32,
    /// Multiplier for urgency scoring; higher values make this need compete harder.
    pub urgency_factor: f32,
    /// When `false`, this need is skipped in urgency calculations.
    pub enabled: bool,
}

// ---- Implementation: Need ----

impl Need {
    /// Create a new need with full satisfaction and the given parameters.
    pub fn new(name: &str, decay_rate: f32, urgency_threshold: f32, urgency_factor: f32) -> Self {
        Self {
            name: name.to_string(),
            value: 1.0,
            decay_rate,
            urgency_threshold,
            urgency_factor,
            enabled: true,
        }
    }

    /// Return `true` when this need's value is below `urgency_threshold`.
    pub fn is_urgent(&self) -> bool {
        self.enabled && self.value < self.urgency_threshold
    }

    /// Return the urgency score: `urgency_factor * (1.0 - value)`, or `0.0` if this need is disabled.
    pub fn urgency_score(&self) -> f32 {
        if !self.enabled {
            return 0.0;
        }
        self.urgency_factor * (1.0 - self.value)
    }

    /// Add `amount` to the current need value, clamped to `[0.0, 1.0]`.
    pub fn satisfy(&mut self, amount: f32) {
        self.value = (self.value + amount).clamp(0.0, 1.0);
    }

    /// Subtracts `amount` from the current need value (immediate deprivation).
    pub fn deprive(&mut self, amount: f32) {
        self.value = (self.value - amount).max(0.0);
    }

    /// Advances the need decay by `dt` seconds.
    pub fn update(&mut self, dt: f32) {
        if self.decay_rate > 0.0 {
            self.value = (self.value - self.decay_rate * dt).max(0.0);
        }
    }
}

// ---- Type: NeedAdvertisement ----

/// A world-space announcement that an object or location can satisfy a need.
pub struct NeedAdvertisement {
    /// Name of the need this advertisement satisfies.
    pub need_name: String,
    /// Amount of satisfaction provided when the agent interacts with it.
    pub satisfaction: f32,
    /// World-space position of the satisfier.
    pub position: (f32, f32),
    /// Name of the object or entity that provides this satisfaction.
    pub advertiser_name: String,
    /// Time in seconds before this advertisement becomes available again after use (0 = unlimited).
    pub cooldown: f32,
    /// Remaining cooldown seconds. When `> 0` the advertisement is unavailable.
    pub remaining_cooldown: f32,
}

// ---- Implementation: NeedAdvertisement ----

impl NeedAdvertisement {
    /// Create a new need advertisement with no cooldown.
    pub fn new(need_name: &str, satisfaction: f32, x: f32, y: f32, advertiser_name: &str) -> Self {
        Self {
            need_name: need_name.to_string(),
            satisfaction: satisfaction.clamp(0.0, 1.0),
            position: (x, y),
            advertiser_name: advertiser_name.to_string(),
            cooldown: 0.0,
            remaining_cooldown: 0.0,
        }
    }

    /// Return `true` if the advertisement is currently available (no cooldown remaining).
    pub fn is_available(&self) -> bool {
        self.remaining_cooldown <= 0.0
    }

    /// Marks the advertisement as used, starting the cooldown timer. Has no effect when `cooldown` is zero.
    pub fn use_it(&mut self) {
        if self.cooldown > 0.0 {
            self.remaining_cooldown = self.cooldown;
        }
    }

    /// Advances the cooldown timer by `dt` seconds.
    pub fn update(&mut self, dt: f32) {
        if self.remaining_cooldown > 0.0 {
            self.remaining_cooldown = (self.remaining_cooldown - dt).max(0.0);
        }
    }

    /// Scores this advertisement for an agent at `agent_pos` relative to the need's urgency. Distance reduces the score; unavailable ads always score `0.0`.
    pub fn score(&self, agent_pos: (f32, f32), need_urgency: f32) -> f32 {
        if !self.is_available() {
            return 0.0;
        }
        let dx = self.position.0 - agent_pos.0;
        let dy = self.position.1 - agent_pos.1;
        let dist = (dx * dx + dy * dy).sqrt();
        (self.satisfaction * need_urgency) / (1.0 + dist * 0.01)
    }
}

// ---- Type: NeedSystem ----

/// Collection of [`Need`]s for a single agent.
#[derive(Default)]
pub struct NeedSystem {
    needs: Vec<Need>,
}

impl NeedSystem {
    /// Create an empty need system.
    pub fn new() -> Self {
        Self::default()
    }

    /// Add a need to this system. Overwrites any existing need with the same name.
    pub fn add_need(&mut self, need: Need) {
        if let Some(existing) = self.needs.iter_mut().find(|n| n.name == need.name) {
            *existing = need;
        } else {
            self.needs.push(need);
        }
    }

    /// Return a reference to the need with the given name, or `None`.
    pub fn get(&self, name: &str) -> Option<&Need> {
        self.needs.iter().find(|n| n.name == name)
    }

    /// Return a mutable reference to the need with the given name, or `None`.
    pub fn get_mut(&mut self, name: &str) -> Option<&mut Need> {
        self.needs.iter_mut().find(|n| n.name == name)
    }

    /// Advances all needs by `dt` seconds.
    pub fn update(&mut self, dt: f32) {
        for n in &mut self.needs {
            n.update(dt);
        }
    }

    /// Return the name of the most urgent need (highest `urgency_score`).
    pub fn most_urgent(&self) -> Option<&str> {
        self.needs
            .iter()
            .filter(|n| n.enabled)
            .max_by(|a, b| a.urgency_score().partial_cmp(&b.urgency_score()).unwrap())
            .map(|n| n.name.as_str())
    }

    /// Satisfies a named need by `amount`. No-ops silently if the need does not exist.
    pub fn satisfy(&mut self, name: &str, amount: f32) {
        if let Some(need) = self.get_mut(name) {
            need.satisfy(amount);
        }
    }

    /// Return a list of all need names in this system.
    pub fn need_names(&self) -> Vec<&str> {
        self.needs.iter().map(|n| n.name.as_str()).collect()
    }

    /// Return the satisfaction value for a named need, or `1.0` if not found.
    pub fn value_of(&self, name: &str) -> f32 {
        self.get(name).map(|n| n.value).unwrap_or(1.0)
    }

    /// Selects the best available advertisement from a slice, considering the agent's current need urgencies and distances. Returns the index into `ads`, or `None` if all are unavailable.
    pub fn best_advertisement(
        &self,
        agent_pos: (f32, f32),
        ads: &[NeedAdvertisement],
    ) -> Option<usize> {
        ads.iter()
            .enumerate()
            .filter(|(_, ad)| ad.is_available())
            .map(|(i, ad)| {
                let urgency = self
                    .get(&ad.need_name)
                    .map(|n| n.urgency_score())
                    .unwrap_or(0.0);
                (i, ad.score(agent_pos, urgency))
            })
            .filter(|(_, score)| *score > 0.0)
            .max_by(|a, b| a.1.partial_cmp(&b.1).unwrap())
            .map(|(i, _)| i)
    }
}

