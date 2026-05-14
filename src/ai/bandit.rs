//! - Implements a compact multi-armed bandit that stores per-arm reward history,
//!   posterior parameters, and the shared counters needed for online choice updates.
//! - Owns the strategy switch for epsilon-greedy, UCB1, and Thompson sampling,
//!   along with the local random and distribution helpers those policies require.
//! - Keeps selection, reward ingestion, and reset behavior in one place so higher
//!   AI systems can use adaptive arm choice without a larger planning framework.

/// A single bandit arm with accumulated reward statistics.
#[derive(Clone)]
pub struct BanditArm {
    /// Number of times this arm has been selected.
    pub pulls: u32,
    /// Sum of all observed rewards.
    pub total_reward: f64,
    /// Beta-distribution alpha parameter used by Thompson sampling.
    pub alpha: f64,
    /// Beta-distribution beta parameter used by Thompson sampling.
    pub beta: f64,
    /// Optional label for debug or UI display.
    pub label: Option<String>,
}
impl BanditArm {
    /// Return the empirical mean reward; returns 0.5 before the first pull.
    pub fn mean_reward(&self) -> f64 {
        if self.pulls == 0 {
            0.5
        } else {
            self.total_reward / self.pulls as f64
        }
    }
}
/// Selection strategy used by `Bandit`.
#[derive(Clone, Copy, Debug)]
pub enum BanditStrategy {
    /// Random exploration with probability `epsilon`, otherwise greedy selection.
    EpsilonGreedy {
        /// Exploration rate in `[0, 1]`.
        epsilon: f32,
    },
    /// Upper Confidence Bound strategy.
    UCB1,
    /// Thompson sampling over Beta-distributed arm posteriors.
    ThompsonSampling,
}
/// Complete bandit agent with one strategy and a mutable set of arms.
pub struct Bandit {
    /// All arms available to the bandit.
    pub arms: Vec<BanditArm>,
    /// Current selection strategy.
    pub strategy: BanditStrategy,
    /// Total number of pulls across all arms.
    pub total_pulls: u64,
    /// Internal RNG state.
    rng: u64,
}
impl Bandit {
    /// Create a bandit with `arm_count` arms and a fixed RNG seed.
    pub fn new(arm_count: usize, strategy: BanditStrategy, seed: u64) -> Self {
        let arms = (0..arm_count)
            .map(|_| BanditArm {
                pulls: 0,
                total_reward: 0.0,
                alpha: 1.0,
                beta: 1.0,
                label: None,
            })
            .collect();
        Self {
            arms,
            strategy,
            total_pulls: 0,
            rng: seed,
        }
    }
    /// Return the number of available arms.
    pub fn arm_count(&self) -> usize {
        self.arms.len()
    }
    /// Select an arm index according to the current strategy.
    pub fn select(&mut self) -> usize {
        let n = self.arms.len();
        match self.strategy {
            BanditStrategy::EpsilonGreedy { epsilon } => {
                if self.rand_f32() < epsilon {
                    self.rand_usize(n)
                } else {
                    self.best_arm()
                }
            }
            BanditStrategy::UCB1 => {
                if let Some(i) = self.arms.iter().position(|a| a.pulls == 0) {
                    return i;
                }
                let total = self.total_pulls as f64;
                (0..n)
                    .max_by(|&a, &b| {
                        let ucb = |arm: &BanditArm| {
                            arm.mean_reward() + (2.0 * total.ln() / arm.pulls as f64).sqrt()
                        };
                        ucb(&self.arms[a]).partial_cmp(&ucb(&self.arms[b])).unwrap()
                    })
                    .unwrap_or(0)
            }
            BanditStrategy::ThompsonSampling => {
                let arm_data: Vec<(f64, f64)> =
                    self.arms.iter().map(|a| (a.alpha, a.beta)).collect();
                let samples: Vec<f64> = arm_data
                    .iter()
                    .map(|&(alpha, beta)| self.beta_sample(alpha, beta))
                    .collect();
                samples
                    .iter()
                    .enumerate()
                    .max_by(|a, b| a.1.partial_cmp(b.1).unwrap())
                    .map(|(i, _)| i)
                    .unwrap_or(0)
            }
        }
    }
    /// Update the chosen arm with an observed reward in the range `[0, 1]`.
    pub fn update(&mut self, index: usize, reward: f64) {
        if index >= self.arms.len() {
            return;
        }
        let arm = &mut self.arms[index];
        arm.pulls += 1;
        arm.total_reward += reward;
        arm.alpha += reward;
        arm.beta += 1.0 - reward;
        self.total_pulls += 1;
    }
    /// Return the greedy best arm by empirical mean reward.
    pub fn best_arm(&self) -> usize {
        (0..self.arms.len())
            .max_by(|&a, &b| {
                self.arms[a]
                    .mean_reward()
                    .partial_cmp(&self.arms[b].mean_reward())
                    .unwrap()
            })
            .unwrap_or(0)
    }
    /// Reset all arm statistics and the total pull counter.
    pub fn reset(&mut self) {
        for arm in &mut self.arms {
            arm.pulls = 0;
            arm.total_reward = 0.0;
            arm.alpha = 1.0;
            arm.beta = 1.0;
        }
        self.total_pulls = 0;
    }
    /// Sample a random index in `[0, n)` using the internal RNG.
    fn rand_usize(&mut self, n: usize) -> usize {
        self.rng = xorshift64(self.rng);
        (self.rng as usize) % n
    }
    /// Sample a uniform float in `[0, 1)` using the internal RNG.
    fn rand_f32(&mut self) -> f32 {
        self.rng = xorshift64(self.rng);
        (self.rng >> 11) as f32 * (1.0 / (1u64 << 53) as f32)
    }
    /// Sample from a Beta distribution using gamma sampling.
    fn beta_sample(&mut self, alpha: f64, beta: f64) -> f64 {
        let ga = self.gamma_sample(alpha);
        let gb = self.gamma_sample(beta);
        if ga + gb < 1e-15 {
            0.5
        } else {
            ga / (ga + gb)
        }
    }
    /// Sample from a Gamma distribution with the given shape parameter.
    fn gamma_sample(&mut self, shape: f64) -> f64 {
        if shape < 1.0 {
            return self.gamma_sample(1.0 + shape) * self.rand_f64().powf(1.0 / shape);
        }
        let d = shape - 1.0 / 3.0;
        let c = 1.0 / (9.0 * d).sqrt();
        loop {
            let z = self.normal_f64();
            let v_raw = 1.0 + c * z;
            if v_raw <= 0.0 {
                continue;
            }
            let v = v_raw * v_raw * v_raw;
            let u = self.rand_f64();
            if u < 1.0 - 0.0331 * z * z * z * z {
                return d * v;
            }
            if u.ln() < 0.5 * z * z + d * (1.0 - v + v.ln()) {
                return d * v;
            }
        }
    }
    /// Sample a uniform float in `[0, 1)` using the internal RNG.
    fn rand_f64(&mut self) -> f64 {
        self.rng = xorshift64(self.rng);
        (self.rng >> 11) as f64 * (1.0 / (1u64 << 53) as f64)
    }
    /// Sample a standard normal value using Box-Muller.
    fn normal_f64(&mut self) -> f64 {
        let u1 = self.rand_f64().max(1e-15);
        let u2 = self.rand_f64();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}
/// Xorshift64 RNG step used by the bandit sampler.
fn xorshift64(mut x: u64) -> u64 {
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    x
}
