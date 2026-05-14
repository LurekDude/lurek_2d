//! Linear Congruential Generator (LCG) for `src/procgen` procedural algorithms.
//! Owns the `Lcg` struct and its integer and float output methods. Does not own
//! higher-level noise or dungeon algorithms — those consume `Lcg` from other files.

/// 64-bit LCG RNG seeded deterministically; used throughout `procgen` for reproducible results.
pub struct Lcg {
    /// Current generator state; mutated by each call to `next`.
    state: u64,
}

impl Lcg {
    /// Create an LCG seeded with `seed` (internal state = seed + 1 to avoid zero-state).
    pub fn new(seed: u64) -> Self {
        Self {
            state: seed.wrapping_add(1),
        }
    }

    /// Advance the LCG by one step and return the next raw `u64` output.
    #[allow(clippy::should_implement_trait)]
    pub fn next(&mut self) -> u64 {
        self.state = self
            .state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        self.state
    }

    /// Advance and return a uniform float in 0.0–1.0 using the upper 31 bits.
    pub fn next_f32(&mut self) -> f32 {
        (self.next() >> 33) as f32 / (1u64 << 31) as f32
    }
}
impl Lcg {
    pub fn new(seed: u64) -> Self {
        Self {
            state: seed.wrapping_add(1),
        }
    }
    #[allow(clippy::should_implement_trait)]
    pub fn next(&mut self) -> u64 {
        self.state = self
            .state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        self.state
    }
    pub fn next_f32(&mut self) -> f32 {
        (self.next() >> 33) as f32 / (1u64 << 31) as f32
    }
}
