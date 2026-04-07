//! Seedable random number generator for reproducible sequences.
//!
//! Wraps `fastrand::Rng` with engine-compatible API including
//! seeding, state save/restore, and normal distribution sampling.
//!
//! This module is part of Luna2D's `math` subsystem and provides the implementation
//! details for random-related operations and data management.
//! Key types exported from this module: `RandomGenerator`.
//! Primary functions: `new()`, `with_seed()`, `random()`, `random_int()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use fastrand::Rng;

/// Seedable random number generator exposed as a Lua object.
///
/// Wraps `fastrand::Rng` with engine-compatible API for deterministic
/// random number generation, normal distribution, and state management.
///
/// # Fields
/// - `rng` — `Rng`.
/// - `seed` — `u64`.
pub struct RandomGenerator {
    /// The underlying fast RNG.
    rng: Rng,
    /// Stored seed for `get_seed()` compatibility.
    seed: u64,
}

impl RandomGenerator {
    /// Create a new generator with a random seed.
    ///
    /// # Returns
    /// A `RandomGenerator` seeded from OS entropy.
    pub fn new() -> Self {
        let rng = Rng::new();
        Self { seed: 0, rng }
    }

    /// Create with a specific seed for deterministic sequences.
    ///
    /// # Parameters
    /// - `seed` — 64-bit seed; the same seed produces identical sequences
    ///
    /// # Returns
    /// A `RandomGenerator` with the given seed.
    pub fn with_seed(seed: u64) -> Self {
        let rng = Rng::with_seed(seed);
        Self { seed, rng }
    }

    /// Sample a uniform random value in `[0.0, 1.0)`.
    ///
    /// # Returns
    /// A `f64` in the half-open interval `[0.0, 1.0)`.
    pub fn random(&mut self) -> f64 {
        self.rng.f64()
    }

    /// Sample a uniform random integer in `[min, max]` (inclusive).
    ///
    /// # Parameters
    /// - `min` — lower bound (inclusive)
    /// - `max` — upper bound (inclusive)
    ///
    /// # Returns
    /// A random `i64` in `[min, max]`; returns `min` if `min >= max`.
    pub fn random_int(&mut self, min: i64, max: i64) -> i64 {
        if min >= max {
            return min;
        }
        let range = (max - min + 1) as u64;
        min + (self.rng.u64(0..range)) as i64
    }

    /// Sample a uniform random float in `[min, max)`.
    ///
    /// # Parameters
    /// - `min` — lower bound (inclusive)
    /// - `max` — upper bound (exclusive)
    ///
    /// # Returns
    /// A `f64` uniformly distributed in `[min, max)`.
    pub fn random_float(&mut self, min: f64, max: f64) -> f64 {
        min + self.rng.f64() * (max - min)
    }

    /// Random number from normal (Gaussian) distribution using Box-Muller transform.
    ///
    /// # Parameters
    /// - `stddev` — standard deviation of the distribution
    /// - `mean` — mean (centre) of the distribution
    ///
    /// # Returns
    /// A `f64` sampled from N(mean, stddev²).
    pub fn random_normal(&mut self, stddev: f64, mean: f64) -> f64 {
        let u1 = self.rng.f64().max(f64::MIN_POSITIVE); // avoid ln(0)
        let u2 = self.rng.f64();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos();
        mean + z * stddev
    }

    /// Set the seed, fully resetting the generator state.
    ///
    /// # Parameters
    /// - `seed` — new 64-bit seed
    pub fn set_seed(&mut self, seed: u64) {
        self.seed = seed;
        self.rng = Rng::with_seed(seed);
    }

    /// Get the seed that was used to initialise (or last reset) this generator.
    ///
    /// # Returns
    /// The 64-bit seed value.
    pub fn get_seed(&self) -> u64 {
        self.seed
    }

    /// Serialise the generator state as a string for later restoration.
    ///
    /// # Returns
    /// An opaque string that can be passed to `set_state()` to reproduce the same sequence.
    pub fn get_state(&self) -> String {
        format!("{}", self.seed)
    }

    /// Restore the generator state from a previously serialised string.
    ///
    /// # Parameters
    /// - `state` — string previously returned by `get_state()`
    ///
    /// # Returns
    /// `Ok(())` on success; `Err(String)` if the string cannot be parsed.
    pub fn set_state(&mut self, state: &str) -> Result<(), String> {
        let seed: u64 = state
            .parse()
            .map_err(|_| format!("Invalid state string: {}", state))?;
        self.set_seed(seed);
        Ok(())
    }
}

impl Clone for RandomGenerator {
    fn clone(&self) -> Self {
        Self::with_seed(self.seed)
    }
}

impl Default for RandomGenerator {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Seeded determinism ──────────────────────────────────────────────────────

    #[test]
    fn same_seed_same_first_value() {
        let mut r1 = RandomGenerator::with_seed(42);
        let mut r2 = RandomGenerator::with_seed(42);
        let v1 = r1.random();
        let v2 = r2.random();
        assert!((v1 - v2).abs() < f64::EPSILON);
    }

    #[test]
    fn get_seed_returns_stored_seed() {
        let r = RandomGenerator::with_seed(1234);
        assert_eq!(r.get_seed(), 1234);
    }

    #[test]
    fn set_seed_resets_sequence() {
        let mut r = RandomGenerator::with_seed(99);
        let first = r.random();
        r.set_seed(99);
        let again = r.random();
        assert!((first - again).abs() < f64::EPSILON);
    }

    // ── Float range ────────────────────────────────────────────────────────────

    #[test]
    fn random_float_in_range_never_below_min() {
        let mut r = RandomGenerator::with_seed(7);
        for _ in 0..1000 {
            let v = r.random_float(0.0, 1.0);
            assert!(v >= 0.0);
        }
    }

    #[test]
    fn random_float_in_range_never_above_max() {
        let mut r = RandomGenerator::with_seed(7);
        for _ in 0..1000 {
            let v = r.random_float(0.0, 1.0);
            assert!(v < 1.0);
        }
    }

    // ── Int range ──────────────────────────────────────────────────────────────

    #[test]
    fn random_int_never_below_min() {
        let mut r = RandomGenerator::with_seed(3);
        for _ in 0..1000 {
            let v = r.random_int(0, 9);
            assert!(v >= 0);
        }
    }

    #[test]
    fn random_int_never_above_max_inclusive() {
        let mut r = RandomGenerator::with_seed(3);
        for _ in 0..1000 {
            let v = r.random_int(0, 9);
            assert!(v <= 9);
        }
    }

    #[test]
    fn random_int_min_equals_max_returns_min() {
        let mut r = RandomGenerator::with_seed(1);
        let v = r.random_int(5, 5);
        assert_eq!(v, 5);
    }
}
