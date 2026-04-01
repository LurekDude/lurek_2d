//! Tabular epsilon-greedy Q-learner.

/// Tabular epsilon-greedy Q-learner for reinforcement learning.
///
/// # Fields
/// - `state_count` — `usize`.
/// - `action_count` — `usize`.
/// - `qtable` — `Vec<f64>`.
/// - `alpha` — `f64`.
/// - `gamma` — `f64`.
/// - `epsilon` — `f64`.
/// - `epsilon_decay` — `f64`.
/// - `episode_count` — `u64`.
///
/// Q-table is a flat `Vec<f64>` indexed as `state * action_count + action`.
/// Uses Bellman update: Q(s,a) ← Q(s,a) + α\[r + γ max_a' Q(s',a') - Q(s,a)\]
pub struct QLearner {
    /// Number of discrete states.
    pub(crate) state_count: usize,
    /// Number of discrete actions.
    pub(crate) action_count: usize,
    /// Flat Q-table: state_count × action_count.
    pub(crate) qtable: Vec<f64>,
    /// Learning rate α ∈ (0,1].
    pub(crate) alpha: f64,
    /// Discount factor γ ∈ [0,1].
    pub(crate) gamma: f64,
    /// Exploration rate ε ∈ [0,1].
    pub(crate) epsilon: f64,
    /// Decay multiplier applied to epsilon after each episode.
    pub(crate) epsilon_decay: f64,
    /// Number of completed episodes.
    pub(crate) episode_count: u64,
}

impl QLearner {
    /// Creates a new Q-learner with the given state and action counts.
    ///
    /// # Parameters
    /// - `state_count` — `usize`.
    /// - `action_count` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(state_count: usize, action_count: usize) -> Self {
        Self {
            state_count,
            action_count,
            qtable: vec![0.0; state_count * action_count],
            alpha: 0.1,
            gamma: 0.9,
            epsilon: 0.1,
            epsilon_decay: 0.995,
            episode_count: 0,
        }
    }

    /// Epsilon-greedy action selection.
    ///
    /// # Parameters
    /// - `state` — `usize`.
    ///
    /// # Returns
    /// `usize`.
    pub fn choose_action(&self, state: usize) -> usize {
        if state >= self.state_count {
            return 0;
        }
        if fastrand::f64() < self.epsilon {
            fastrand::usize(..self.action_count)
        } else {
            self.best_action(state)
        }
    }

    /// Returns the action with the highest Q-value for the given state.
    ///
    /// # Parameters
    /// - `state` — `usize`.
    ///
    /// # Returns
    /// `usize`.
    pub fn best_action(&self, state: usize) -> usize {
        if state >= self.state_count {
            return 0;
        }
        let base = state * self.action_count;
        let mut best_idx = 0;
        let mut best_val = f64::NEG_INFINITY;
        for a in 0..self.action_count {
            let val = self.qtable[base + a];
            if val > best_val {
                best_val = val;
                best_idx = a;
            }
        }
        best_idx
    }

    /// Bellman update: Q(s,a) ← Q(s,a) + α\[r + γ max Q(s',a') - Q(s,a)\]
    ///
    /// # Parameters
    /// - `state` — `usize`.
    /// - `action` — `usize`.
    /// - `reward` — `f64`.
    /// - `next_state` — `usize`.
    pub fn learn(&mut self, state: usize, action: usize, reward: f64, next_state: usize) {
        if state >= self.state_count
            || action >= self.action_count
            || next_state >= self.state_count
        {
            return;
        }
        let idx = state * self.action_count + action;
        let max_next = self.max_q(next_state);
        let old = self.qtable[idx];
        self.qtable[idx] = old + self.alpha * (reward + self.gamma * max_next - old);
    }

    /// Ends the current episode: applies epsilon decay and increments episode count.
    pub fn end_episode(&mut self) {
        self.epsilon *= self.epsilon_decay;
        self.episode_count += 1;
    }

    /// Gets the Q-value for a state-action pair.
    ///
    /// # Parameters
    /// - `state` — `usize`.
    /// - `action` — `usize`.
    ///
    /// # Returns
    /// `f64`.
    pub fn get_q(&self, state: usize, action: usize) -> f64 {
        if state >= self.state_count || action >= self.action_count {
            return 0.0;
        }
        self.qtable[state * self.action_count + action]
    }

    /// Sets the Q-value for a state-action pair.
    ///
    /// # Parameters
    /// - `state` — `usize`.
    /// - `action` — `usize`.
    /// - `value` — `f64`.
    pub fn set_q(&mut self, state: usize, action: usize, value: f64) {
        if state >= self.state_count || action >= self.action_count {
            return;
        }
        self.qtable[state * self.action_count + action] = value;
    }

    fn max_q(&self, state: usize) -> f64 {
        let base = state * self.action_count;
        let mut max_val = f64::NEG_INFINITY;
        for a in 0..self.action_count {
            let val = self.qtable[base + a];
            if val > max_val {
                max_val = val;
            }
        }
        max_val
    }

    /// Serializes the Q-table to a JSON string.
    ///
    /// # Returns
    /// `String`.
    pub fn serialize(&self) -> String {
        let mut out = String::from("[");
        for s in 0..self.state_count {
            if s > 0 {
                out.push(',');
            }
            out.push('[');
            let base = s * self.action_count;
            for a in 0..self.action_count {
                if a > 0 {
                    out.push(',');
                }
                out.push_str(&format!("{}", self.qtable[base + a]));
            }
            out.push(']');
        }
        out.push(']');
        out
    }

    /// Deserializes a Q-table from a JSON string. Errors if dimensions mismatch.
    ///
    /// # Parameters
    /// - `json` — `&str`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn deserialize(&mut self, json: &str) -> Result<(), String> {
        let trimmed = json.trim();
        if !trimmed.starts_with('[') || !trimmed.ends_with(']') {
            return Err("Invalid JSON: expected outer array".into());
        }
        let inner = &trimmed[1..trimmed.len() - 1];
        let mut states: Vec<Vec<f64>> = Vec::new();
        let mut depth = 0;
        let mut start = 0;
        for (i, ch) in inner.char_indices() {
            match ch {
                '[' => {
                    if depth == 0 {
                        start = i + 1;
                    }
                    depth += 1;
                }
                ']' => {
                    depth -= 1;
                    if depth == 0 {
                        let row_str = &inner[start..i];
                        let row: Vec<f64> = row_str
                            .split(',')
                            .filter_map(|s| s.trim().parse().ok())
                            .collect();
                        states.push(row);
                    }
                }
                _ => {}
            }
        }
        if states.len() != self.state_count {
            return Err(format!(
                "State count mismatch: expected {}, got {}",
                self.state_count,
                states.len()
            ));
        }
        for (s, row) in states.iter().enumerate() {
            if row.len() != self.action_count {
                return Err(format!(
                    "Action count mismatch in state {}: expected {}, got {}",
                    s,
                    self.action_count,
                    row.len()
                ));
            }
            let base = s * self.action_count;
            for (a, &val) in row.iter().enumerate() {
                self.qtable[base + a] = val;
            }
        }
        Ok(())
    }
}
