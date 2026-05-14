//! Seedable pseudo-random number generator backed by `fastrand::Rng`.
//! Exposes uniform float, integer, Gaussian, and seed-state helpers used by
//! procgen, loot, combat, and the `lurek.random` Lua API.
//! Does not own noise — for spatially coherent random use noise_generator.rs.

use fastrand::Rng;

/// Seedable RNG wrapping `fastrand::Rng` with stored seed for serialisation.
pub struct RandomGenerator {
    /// The underlying fast RNG state.
    rng: Rng,
    /// Seed value recorded at construction or last `set_seed` call.
    seed: u64,
}
impl RandomGenerator {
    /// Construct a generator with an arbitrary unseeded initial state (seed stored as 0).
    pub fn new() -> Self {
        let rng = Rng::new();
        Self { seed: 0, rng }
    }
    /// Construct a generator from an explicit `seed`.
    pub fn with_seed(seed: u64) -> Self {
        let rng = Rng::with_seed(seed);
        Self { seed, rng }
    }
    /// Return a uniform random `f64` in `[0.0, 1.0)`.
    pub fn random(&mut self) -> f64 {
        self.rng.f64()
    }
    /// Return a uniform random integer in the closed range `[min, max]`; returns `min` when `min >= max`.
    pub fn random_int(&mut self, min: i64, max: i64) -> i64 {
        if min >= max {
            return min;
        }
        let range = (max - min + 1) as u64;
        min + (self.rng.u64(0..range)) as i64
    }
    /// Return a uniform random `f64` in `[min, max)`.
    pub fn random_float(&mut self, min: f64, max: f64) -> f64 {
        min + self.rng.f64() * (max - min)
    }
    /// Return a Gaussian-distributed `f64` with `mean` and `stddev` using Box-Muller transform.
    pub fn random_normal(&mut self, stddev: f64, mean: f64) -> f64 {
        let u1 = self.rng.f64().max(f64::MIN_POSITIVE);
        let u2 = self.rng.f64();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos();
        mean + z * stddev
    }
    /// Re-seed the generator, resetting both the stored seed and the RNG state.
    pub fn set_seed(&mut self, seed: u64) {
        self.seed = seed;
        self.rng = Rng::with_seed(seed);
    }
    /// Return the seed last set via `with_seed` or `set_seed`.
    pub fn get_seed(&self) -> u64 {
        self.seed
    }
    /// Serialise the current seed to a string for save-file persistence.
    pub fn get_state(&self) -> String {
        format!("{}", self.seed)
    }
    /// Restore the seed from a previously serialised state string; returns error on parse failure.
    pub fn set_state(&mut self, state: &str) -> Result<(), String> {
        let seed: u64 = state
            .parse()
            .map_err(|_| format!("Invalid state string: {}", state))?;
        self.set_seed(seed);
        Ok(())
    }
}
/// Clone by constructing a new generator with the same stored seed.
impl Clone for RandomGenerator {
    fn clone(&self) -> Self {
        Self::with_seed(self.seed)
    }
}
/// Provide a default unseeded generator via `new()`.
impl Default for RandomGenerator {
    fn default() -> Self {
        Self::new()
    }
}
