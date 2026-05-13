//! AI level-of-detail tier assignment and update throttling.

// ---- Type: LodTier ----

/// One distance band in the AI LOD system.
#[derive(Clone)]
pub struct LodTier {
    /// Human-readable tier name (e.g. `"near"`, `"mid"`, `"far"`, `"sleep"`).
    pub name: String,
    /// Maximum distance from the reference point for this tier.
    pub max_distance: f32,
    /// Run the full AI update every `update_every` frames. `1` = every frame.
    pub update_every: u32,
    /// Agents beyond this distance are considered out of "think range". Used by callers to skip expensive planning entirely for distant agents.
    pub think_distance: f32,
}

// ---- Implementation: LodTier ----

impl LodTier {
    /// Create a new LOD tier.
    pub fn new(name: &str, max_distance: f32, update_every: u32, think_distance: f32) -> Self {
        Self {
            name: name.to_string(),
            max_distance,
            update_every,
            think_distance,
        }
    }
}

// ---- Type: AILod ----

/// LOD distance tiers and per-frame assignment engine.
pub struct AILod {
    /// Ordered tier definitions (sorted ascending by `max_distance`).
    pub tiers: Vec<LodTier>,
}

// ---- Implementation: AILod ----

impl AILod {
    /// Create a LOD system from a custom tier list.
    pub fn new(mut tiers: Vec<LodTier>) -> Self {
        tiers.sort_by(|a, b| a.max_distance.partial_cmp(&b.max_distance).unwrap());
        Self { tiers }
    }

    /// Return a reference to the tier at index `i`.
    pub fn tier(&self, i: usize) -> Option<&LodTier> {
        self.tiers.get(i)
    }

    /// Return the number of tiers.
    pub fn tier_count(&self) -> usize {
        self.tiers.len()
    }

    /// Determines the LOD tier index for an agent at `agent_pos` from `ref_pos`.
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

    /// Computes tier indices for a batch of agent positions. Returns a `Vec<usize>` with one entry per input position, each equal to `tier_for(pos, ref_pos)`.
    pub fn assign_tiers(&self, agent_positions: &[(f32, f32)], ref_pos: (f32, f32)) -> Vec<usize> {
        agent_positions
            .iter()
            .map(|&p| self.tier_for(p, ref_pos))
            .collect()
    }

    /// Return `true` if an agent in `tier` should be updated on `frame_number`.
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

// ---- Default Implementation ----

impl Default for AILod {
    /// Create a three-tier default configuration:
    fn default() -> Self {
        Self::new(vec![
            LodTier::new("near", 400.0, 1, 400.0),
            LodTier::new("mid", 800.0, 4, 600.0),
            LodTier::new("far", f32::INFINITY, 16, 2000.0),
        ])
    }
}
