
//! - Need-tracking model with normalized internal drives, urgency settings, and external advertisements.
//! - Per-need decay, urgency scoring, satisfaction updates, and cooldown-aware advertisement scoring.
//! - System-level operations for adding needs, time-based updates, and most-urgent drive selection.
//! - Best-advertisement selection weighted by distance, cooldown, and need priority.

/// One tracked need with a normalized value.
pub struct Need {
    /// Need name.
    pub name: String,
    /// Current need value in `[0, 1]`.
    pub value: f32,
    /// Decay per second.
    pub decay_rate: f32,
    /// Threshold below which the need is considered urgent.
    pub urgency_threshold: f32,
    /// Weight used to compute urgency score.
    pub urgency_factor: f32,
    /// Whether this need participates in scoring.
    pub enabled: bool,
}
impl Need {
    /// Create a need with value initialized to 1.0.
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
    /// Return `true` when the need is enabled and below its urgency threshold.
    pub fn is_urgent(&self) -> bool {
        self.enabled && self.value < self.urgency_threshold
    }
    /// Return a score used for prioritising needs.
    pub fn urgency_score(&self) -> f32 {
        if !self.enabled {
            return 0.0;
        }
        self.urgency_factor * (1.0 - self.value)
    }
    /// Increase the need value and clamp it to `[0, 1]`.
    pub fn satisfy(&mut self, amount: f32) {
        self.value = (self.value + amount).clamp(0.0, 1.0);
    }
    /// Decrease the need value and clamp it at 0.
    pub fn deprive(&mut self, amount: f32) {
        self.value = (self.value - amount).max(0.0);
    }
    /// Apply passive decay over `dt` seconds.
    pub fn update(&mut self, dt: f32) {
        if self.decay_rate > 0.0 {
            self.value = (self.value - self.decay_rate * dt).max(0.0);
        }
    }
}
/// Local advertisement that satisfies a specific need.
pub struct NeedAdvertisement {
    /// Need name this ad satisfies.
    pub need_name: String,
    /// Satisfaction amount in `[0, 1]`.
    pub satisfaction: f32,
    /// World position of the ad.
    pub position: (f32, f32),
    /// Name of the advertiser or source.
    pub advertiser_name: String,
    /// Cooldown time after use.
    pub cooldown: f32,
    /// Remaining cooldown time.
    pub remaining_cooldown: f32,
}
impl NeedAdvertisement {
    /// Create a new advertisement at `(x, y)`.
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
    /// Return `true` when the ad is off cooldown.
    pub fn is_available(&self) -> bool {
        self.remaining_cooldown <= 0.0
    }
    /// Start the cooldown timer when the ad has a positive cooldown.
    pub fn use_it(&mut self) {
        if self.cooldown > 0.0 {
            self.remaining_cooldown = self.cooldown;
        }
    }
    /// Advance the cooldown timer.
    pub fn update(&mut self, dt: f32) {
        if self.remaining_cooldown > 0.0 {
            self.remaining_cooldown = (self.remaining_cooldown - dt).max(0.0);
        }
    }
    /// Return a distance-weighted score for the ad.
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
/// Collection of named needs for one agent.
#[derive(Default)]
pub struct NeedSystem {
    /// Tracked needs.
    needs: Vec<Need>,
}
impl NeedSystem {
    /// Create an empty need system.
    pub fn new() -> Self {
        Self::default()
    }
    /// Add or replace a need by name.
    pub fn add_need(&mut self, need: Need) {
        if let Some(existing) = self.needs.iter_mut().find(|n| n.name == need.name) {
            *existing = need;
        } else {
            self.needs.push(need);
        }
    }
    /// Return a need by name, or `None` if missing.
    pub fn get(&self, name: &str) -> Option<&Need> {
        self.needs.iter().find(|n| n.name == name)
    }
    /// Return a mutable need by name, or `None` if missing.
    pub fn get_mut(&mut self, name: &str) -> Option<&mut Need> {
        self.needs.iter_mut().find(|n| n.name == name)
    }
    /// Advance all needs by `dt` seconds.
    pub fn update(&mut self, dt: f32) {
        for n in &mut self.needs {
            n.update(dt);
        }
    }
    /// Return the most urgent enabled need name, or `None` when none are enabled.
    pub fn most_urgent(&self) -> Option<&str> {
        self.needs
            .iter()
            .filter(|n| n.enabled)
            .max_by(|a, b| a.urgency_score().partial_cmp(&b.urgency_score()).unwrap())
            .map(|n| n.name.as_str())
    }
    /// Increase the named need when present.
    pub fn satisfy(&mut self, name: &str, amount: f32) {
        if let Some(need) = self.get_mut(name) {
            need.satisfy(amount);
        }
    }
    /// Return all tracked need names.
    pub fn need_names(&self) -> Vec<&str> {
        self.needs.iter().map(|n| n.name.as_str()).collect()
    }
    /// Return the current value of the named need, or 1.0 if missing.
    pub fn value_of(&self, name: &str) -> f32 {
        self.get(name).map(|n| n.value).unwrap_or(1.0)
    }
    /// Return the best-scoring available advertisement, or `None` if none score positive.
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
