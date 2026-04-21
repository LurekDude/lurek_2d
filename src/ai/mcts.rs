//! Monte Carlo Tree Search (MCTS) for AI decision-making.
//!
//! Implements the canonical MCTS algorithm (Selection → Expansion → Simulation
//! → Backpropagation) with a configurable UCT exploration constant. The planner
//! is game-agnostic: callers supply three closures at search time — `get_actions`,
//! `apply_action`, and `evaluate` — so no Lua state is stored inside the engine.
//!
//! ## Architecture
//!
//! - [`MCTSConfig`] controls iteration budget, UCT constant, rollout depth, and
//!   a reproducible PRNG seed.
//! - [`MCTSNode`] is an arena-allocated tree node carrying visit count, total
//!   score, parent index, child indices, and the action that reached this node.
//! - [`MCTSEngine`] owns the node arena and drives the four-phase algorithm.
//!   Each call to `search` returns the best `i32` action index from the root.
//!
//! ## Closures
//!
//! The engine is called with pure Rust closures representing the game logic:
//! - `get_actions(state) -> Vec<i32>` — returns valid action IDs for a state.
//! - `apply_action(state, action) -> S` — returns the successor state.
//! - `evaluate(state) -> f32` — returns the heuristic value `[0, 1]` of a state.
//!
//! The Lua bridge (`ai_api.rs`) wraps Lua functions into these closures.
//!
//! ## Typical Usage Sequence
//!
//! 1. Create `MCTSEngine::new(config)`.
//! 2. Call `engine.search(root_state, &mut get_actions, &mut apply_action, &mut evaluate)`.
//! 3. Use the returned `Option<i32>` action ID in the agent's FSM/BT.

// ────────────────────────────────────────────────────────────────────────────
// MCTSConfig
// ────────────────────────────────────────────────────────────────────────────

/// Configuration for the MCTS engine.
///
/// # Fields
/// - `iterations` — `u32`.
/// - `uct_c` — `f32`.
/// - `rollout_depth` — `usize`.
/// - `seed` — `u64`.
pub struct MCTSConfig {
    /// Number of MCTS iterations per `search` call.
    pub iterations: u32,
    /// UCT exploration constant (√2 ≈ 1.414 is the standard default).
    pub uct_c: f32,
    /// Maximum depth for random rollout simulation.
    pub rollout_depth: usize,
    /// Seed for the internal PRNG.
    pub seed: u64,
}

impl Default for MCTSConfig {
    fn default() -> Self {
        Self {
            iterations: 100,
            uct_c: 1.414,
            rollout_depth: 10,
            seed: 42,
        }
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MCTSNode
// ────────────────────────────────────────────────────────────────────────────

/// Arena-allocated MCTS tree node.
///
/// # Fields
/// - `parent` — `Option<usize>`.
/// - `children` — `Vec<usize>`.
/// - `action` — `Option<i32>`.
/// - `visits` — `u32`.
/// - `total_score` — `f64`.
/// - `untried_actions` — `Vec<i32>`.
struct MCTSNode {
    parent: Option<usize>,
    children: Vec<usize>,
    /// Action that led from the parent to this node. `None` for root.
    action: Option<i32>,
    visits: u32,
    total_score: f64,
    untried_actions: Vec<i32>,
}

impl MCTSNode {
    fn new(parent: Option<usize>, action: Option<i32>, actions: Vec<i32>) -> Self {
        Self {
            parent,
            children: Vec::new(),
            action,
            visits: 0,
            total_score: 0.0,
            untried_actions: actions,
        }
    }

    /// UCT score for this node.
    fn uct(&self, parent_visits: u32, c: f32) -> f64 {
        if self.visits == 0 { return f64::INFINITY; }
        let q = self.total_score / self.visits as f64;
        let u = c as f64 * ((parent_visits as f64).ln() / self.visits as f64).sqrt();
        q + u
    }

    /// Returns `true` if all child actions have been tried.
    fn is_fully_expanded(&self) -> bool {
        self.untried_actions.is_empty()
    }
}

// ────────────────────────────────────────────────────────────────────────────
// MCTSEngine
// ────────────────────────────────────────────────────────────────────────────

/// MCTS engine with arena-allocated node tree.
///
/// Resets the tree on every `search` call so intermediate state never leaks
/// between decisions. The arena grows as needed and is cleared at the start
/// of each search.
///
/// # Fields
/// - `config` — `MCTSConfig`.
/// - `arena` — `Vec<MCTSNode>`.
/// - `rng` — `u64`.
pub struct MCTSEngine {
    /// Search configuration.
    pub config: MCTSConfig,
    arena: Vec<MCTSNode>,
    rng: u64,
}

impl MCTSEngine {
    /// Creates a new MCTS engine with the given configuration.
    ///
    /// # Parameters
    /// - `config` — `MCTSConfig`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(config: MCTSConfig) -> Self {
        let rng = config.seed;
        Self { config, arena: Vec::new(), rng }
    }

    /// Returns a reference to the current configuration.
    ///
    /// # Returns
    /// `&MCTSConfig`.
    pub fn config(&self) -> &MCTSConfig { &self.config }

    /// Runs MCTS from `root_state` and returns the best action index, or `None`
    /// if no actions are available from the root.
    ///
    /// The closures must be pure (no side effects on `root_state`):
    /// - `get_actions(state) -> Vec<i32>` — valid action IDs.
    /// - `apply_action(state, action) -> S` — successor state.
    /// - `evaluate(state) -> f32` — heuristic value `[0, 1]`.
    ///
    /// # Parameters
    /// - `root_state` — `S`.
    /// - `get_actions` — `FnMut(&S) -> Vec<i32>`.
    /// - `apply_action` — `FnMut(&S, i32) -> S`.
    /// - `evaluate` — `FnMut(&S) -> f32`.
    ///
    /// # Returns
    /// `Option<i32>`.
    pub fn search<S, FA, FB, FC>(
        &mut self,
        root_state: S,
        get_actions: &mut FA,
        apply_action: &mut FB,
        evaluate: &mut FC,
    ) -> Option<i32>
    where
        S: Clone,
        FA: FnMut(&S) -> Vec<i32>,
        FB: FnMut(&S, i32) -> S,
        FC: FnMut(&S) -> f32,
    {
        self.arena.clear();
        let root_actions = get_actions(&root_state);
        if root_actions.is_empty() { return None; }
        self.arena.push(MCTSNode::new(None, None, root_actions));

        for _ in 0..self.config.iterations {
            // 1. Selection
            let (node_idx, state) = self.select(0, root_state.clone(), apply_action);

            // 2. Expansion
            let (node_idx, state) = self.expand(node_idx, state, get_actions, apply_action);

            // 3. Simulation (rollout)
            let score = self.rollout(&state, get_actions, apply_action, evaluate);

            // 4. Backpropagation
            self.backpropagate(node_idx, score as f64);
        }

        // Choose child of root with highest visit count
        let root = &self.arena[0];
        root.children.iter()
            .max_by_key(|&&c| self.arena[c].visits)
            .and_then(|&c| self.arena[c].action)
    }

    /// Traverses to the most promising node using UCT selection.
    fn select<S, FB>(&self, mut idx: usize, mut state: S, apply_action: &mut FB) -> (usize, S)
    where
        S: Clone,
        FB: FnMut(&S, i32) -> S,
    {
        loop {
            let node = &self.arena[idx];
            if !node.is_fully_expanded() || node.children.is_empty() {
                return (idx, state);
            }
            let parent_visits = node.visits;
            let c = self.config.uct_c;
            let best_child = *node.children.iter()
                .max_by(|&&a, &&b| {
                    self.arena[a].uct(parent_visits, c)
                        .partial_cmp(&self.arena[b].uct(parent_visits, c))
                        .unwrap()
                })
                .unwrap();
            let action = self.arena[best_child].action.unwrap();
            state = apply_action(&state, action);
            idx = best_child;
        }
    }

    /// Expands an untried action from `node_idx`. Returns `(new_node_idx, new_state)`.
    fn expand<S, FA, FB>(
        &mut self,
        node_idx: usize,
        state: S,
        get_actions: &mut FA,
        apply_action: &mut FB,
    ) -> (usize, S)
    where
        S: Clone,
        FA: FnMut(&S) -> Vec<i32>,
        FB: FnMut(&S, i32) -> S,
    {
        if self.arena[node_idx].untried_actions.is_empty() {
            return (node_idx, state);
        }
        let action_idx = self.rand_usize(self.arena[node_idx].untried_actions.len());
        let action = self.arena[node_idx].untried_actions.remove(action_idx);
        let new_state = apply_action(&state, action);
        let child_actions = get_actions(&new_state);
        let child_idx = self.arena.len();
        self.arena.push(MCTSNode::new(Some(node_idx), Some(action), child_actions));
        self.arena[node_idx].children.push(child_idx);
        (child_idx, new_state)
    }

    /// Simulates a random rollout from `state` up to `rollout_depth` steps.
    fn rollout<S, FA, FB, FC>(
        &mut self,
        state: &S,
        get_actions: &mut FA,
        apply_action: &mut FB,
        evaluate: &mut FC,
    ) -> f32
    where
        S: Clone,
        FA: FnMut(&S) -> Vec<i32>,
        FB: FnMut(&S, i32) -> S,
        FC: FnMut(&S) -> f32,
    {
        let mut cur = state.clone();
        for _ in 0..self.config.rollout_depth {
            let actions = get_actions(&cur);
            if actions.is_empty() { break; }
            let i = self.rand_usize(actions.len());
            cur = apply_action(&cur, actions[i]);
        }
        evaluate(&cur)
    }

    /// Propagates `score` up to the root node.
    fn backpropagate(&mut self, mut idx: usize, score: f64) {
        loop {
            self.arena[idx].visits += 1;
            self.arena[idx].total_score += score;
            match self.arena[idx].parent {
                Some(p) => idx = p,
                None => break,
            }
        }
    }

    /// Xorshift64 PRNG returning a `usize` in `[0, n)`.
    fn rand_usize(&mut self, n: usize) -> usize {
        self.rng ^= self.rng << 13;
        self.rng ^= self.rng >> 7;
        self.rng ^= self.rng << 17;
        (self.rng as usize) % n
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_engine_has_config() {
        let cfg = MCTSConfig {
            iterations: 50,
            uct_c: 1.414,
            rollout_depth: 5,
            seed: 42,
        };
        let e = MCTSEngine::new(cfg);
        assert_eq!(e.config().iterations, 50);
    }
}
