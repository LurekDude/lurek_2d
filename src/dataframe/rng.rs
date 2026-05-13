//! Scope: Deterministic pseudo-random number generation for DataFrame sampling.
//! This file defines the Xorshift64 PRNG type and its state progression.
//! It owns seed initialization and reproducible random selection.

/// Minimal deterministic xorshift64 PRNG used by dataframe helpers.
pub(crate) struct Xorshift64 {
    state: u64,
}

impl Xorshift64 {
    /// Create a new RNG with the given seed. Seed `0` is remapped to `1`.
    pub(crate) fn new(seed: u64) -> Self {
        Self {
            state: if seed == 0 { 1 } else { seed },
        }
    }

    /// Return the next pseudo-random `u64`.
    pub(crate) fn next_u64(&mut self) -> u64 {
        let mut x = self.state;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.state = x;
        x
    }

    /// Return a pseudo-random `f64` in `[0, 1)`.
    pub(crate) fn next_f64(&mut self) -> f64 {
        (self.next_u64() & 0x001F_FFFF_FFFF_FFFF) as f64 / (1u64 << 53) as f64
    }

    /// Return a pseudo-random `usize` in `[0, max)`.
    pub(crate) fn next_usize(&mut self, max: usize) -> usize {
        (self.next_u64() % max as u64) as usize
    }
}
