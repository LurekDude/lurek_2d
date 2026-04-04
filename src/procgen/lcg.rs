//! Linear congruential generator for deterministic procgen.
//!
//! Internal helper used by cellular automata, Voronoi, and Poisson disk modules.

/// Simple LCG (Linear Congruential Generator) for deterministic random numbers.
pub(crate) struct Lcg {
    state: u64,
}

impl Lcg {
    /// Creates a new LCG seeded with the given value.
    pub(crate) fn new(seed: u64) -> Self {
        Self {
            state: seed.wrapping_add(1),
        }
    }

    /// Returns the next pseudo-random `u64`.
    pub(crate) fn next(&mut self) -> u64 {
        self.state = self
            .state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        self.state
    }

    /// Returns the next pseudo-random `f32` in [0, 1).
    pub(crate) fn next_f32(&mut self) -> f32 {
        (self.next() >> 33) as f32 / (1u64 << 31) as f32
    }
}
