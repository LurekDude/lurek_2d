//! - Xorshift64 pseudo-random number generator for deterministic dataframe sampling
//! - Float, integer, and index generation from 64-bit state
//! - Zero-seed remap to avoid degenerate all-zero output

/// Hold xorshift64 state used by dataframe-local random helpers.
pub(crate) struct Xorshift64 {
    /// Store current PRNG state word.
    state: u64,
}
impl Xorshift64 {
    /// Create generator from seed and remap zero seed to one.
    pub(crate) fn new(seed: u64) -> Self {
        Self {
            state: if seed == 0 { 1 } else { seed },
        }
    }
    /// Advance generator and return next 64-bit pseudo-random value.
    pub(crate) fn next_u64(&mut self) -> u64 {
        let mut x = self.state;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.state = x;
        x
    }
    /// Return pseudo-random float in the half-open range [0, 1).
    pub(crate) fn next_f64(&mut self) -> f64 {
        (self.next_u64() & 0x001F_FFFF_FFFF_FFFF) as f64 / (1u64 << 53) as f64
    }
    /// Return pseudo-random index in the half-open range [0, max).
    pub(crate) fn next_usize(&mut self, max: usize) -> usize {
        (self.next_u64() % max as u64) as usize
    }
}
