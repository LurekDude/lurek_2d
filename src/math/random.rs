use fastrand::Rng;
pub struct RandomGenerator {
    rng: Rng,
    seed: u64,
}
impl RandomGenerator {
    pub fn new() -> Self {
        let rng = Rng::new();
        Self { seed: 0, rng }
    }
    pub fn with_seed(seed: u64) -> Self {
        let rng = Rng::with_seed(seed);
        Self { seed, rng }
    }
    pub fn random(&mut self) -> f64 {
        self.rng.f64()
    }
    pub fn random_int(&mut self, min: i64, max: i64) -> i64 {
        if min >= max {
            return min;
        }
        let range = (max - min + 1) as u64;
        min + (self.rng.u64(0..range)) as i64
    }
    pub fn random_float(&mut self, min: f64, max: f64) -> f64 {
        min + self.rng.f64() * (max - min)
    }
    pub fn random_normal(&mut self, stddev: f64, mean: f64) -> f64 {
        let u1 = self.rng.f64().max(f64::MIN_POSITIVE);
        let u2 = self.rng.f64();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos();
        mean + z * stddev
    }
    pub fn set_seed(&mut self, seed: u64) {
        self.seed = seed;
        self.rng = Rng::with_seed(seed);
    }
    pub fn get_seed(&self) -> u64 {
        self.seed
    }
    pub fn get_state(&self) -> String {
        format!("{}", self.seed)
    }
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
