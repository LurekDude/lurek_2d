//! AI level-of-detail tiers for update throttling and thinking distance.
//! Owns `LodTier` and `AILod`.
//! Does not own scheduling; callers decide how to use the chosen tier.
/// One LOD bucket for AI work.
#[derive(Clone)]
pub struct LodTier {
    /// Tier name used for debug and display.
    pub name: String,
    /// Maximum distance covered by this tier.
    pub max_distance: f32,
    /// Update cadence in frames; 0 means never.
    pub update_every: u32,
    /// Distance at which the AI should still think.
    pub think_distance: f32,
}
impl LodTier {
    /// Create a tier with the given parameters.
    pub fn new(name: &str, max_distance: f32, update_every: u32, think_distance: f32) -> Self {
        Self {
            name: name.to_string(),
            max_distance,
            update_every,
            think_distance,
        }
    }
}
/// Ordered LOD tier set.
pub struct AILod {
    /// Sorted tiers from near to far.
    pub tiers: Vec<LodTier>,
}
impl AILod {
    /// Sort tiers by distance and build an `AILod`.
    pub fn new(mut tiers: Vec<LodTier>) -> Self {
        tiers.sort_by(|a, b| a.max_distance.partial_cmp(&b.max_distance).unwrap());
        Self { tiers }
    }
    /// Return tier `i` if it exists.
    pub fn tier(&self, i: usize) -> Option<&LodTier> {
        self.tiers.get(i)
    }
    /// Return the number of tiers.
    pub fn tier_count(&self) -> usize {
        self.tiers.len()
    }
    /// Return the tier index for `agent_pos` relative to `ref_pos`.
    pub fn tier_for(&self, agent_pos: (f32, f32), ref_pos: (f32, f32)) -> usize {
        let dx = agent_pos.0 - ref_pos.0;
        let dy = agent_pos.1 - ref_pos.1;
        let dist = (dx * dx + dy * dy).sqrt();
        for (i, tier) in self.tiers.iter().enumerate() {
            if dist <= tier.max_distance {
                return i;
            }
        }
        self.tiers.len().saturating_sub(1)
    }
    /// Return one tier index per agent position.
    pub fn assign_tiers(&self, agent_positions: &[(f32, f32)], ref_pos: (f32, f32)) -> Vec<usize> {
        agent_positions
            .iter()
            .map(|&p| self.tier_for(p, ref_pos))
            .collect()
    }
    /// Return `true` when tier `tier` should update on `frame_number`.
    pub fn should_update(&self, tier: usize, frame_number: u64) -> bool {
        match self.tiers.get(tier) {
            Some(t) => {
                if t.update_every == 0 {
                    false
                } else {
                    frame_number.is_multiple_of(t.update_every as u64)
                }
            }
            None => false,
        }
    }
}
/// `Default` creates near, mid, and far tiers.
/// `Default` builds the near, mid, and far tier set.
impl Default for AILod {
    fn default() -> Self {
        Self::new(vec![
            LodTier::new("near", 400.0, 1, 400.0),
            LodTier::new("mid", 800.0, 4, 600.0),
            LodTier::new("far", f32::INFINITY, 16, 2000.0),
        ])
    }
}
