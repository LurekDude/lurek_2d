pub struct Lcg {
    state: u64,
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
