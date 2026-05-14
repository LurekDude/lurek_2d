
//! - Defines the Monte Carlo Tree Search data used by the AI module to configure
//!   search, store arena-backed tree nodes, and track rollout statistics.
//! - Owns the selection, expansion, rollout, and backpropagation flow that scores
//!   actions from a root state through repeated bounded simulations.
//! - Keeps the small internal random helper and UCT scoring logic that drive node
//!   choice, untried-action expansion, and rollout action sampling.

/// Configuration for one MCTS search run.
pub struct MCTSConfig {
    /// Number of iterations to execute.
    pub iterations: u32,
    /// Exploration constant used by UCT.
    pub uct_c: f32,
    /// Maximum rollout depth.
    pub rollout_depth: usize,
    /// RNG seed.
    pub seed: u64,
}
/// `Default` provides the standard search parameters.
impl Default for MCTSConfig {
    /// Build the standard search parameters.
    fn default() -> Self {
        Self {
            iterations: 100,
            uct_c: 1.414,
            rollout_depth: 10,
            seed: 42,
        }
    }
}
/// Internal tree node used by `MCTSEngine`.
struct MCTSNode {
    /// Parent node index.
    parent: Option<usize>,
    /// Child node indices.
    children: Vec<usize>,
    /// Action that produced this node.
    action: Option<i32>,
    /// Visit count.
    visits: u32,
    /// Accumulated rollout score.
    total_score: f64,
    /// Actions not yet expanded from this node.
    untried_actions: Vec<i32>,
}
impl MCTSNode {
    /// Create a new node with the supplied untried actions.
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
    /// Return the UCT score for this node.
    fn uct(&self, parent_visits: u32, c: f32) -> f64 {
        if self.visits == 0 {
            return f64::INFINITY;
        }
        let q = self.total_score / self.visits as f64;
        let u = c as f64 * ((parent_visits as f64).ln() / self.visits as f64).sqrt();
        q + u
    }
    /// Return `true` when no untried actions remain.
    fn is_fully_expanded(&self) -> bool {
        self.untried_actions.is_empty()
    }
}
/// MCTS search engine with an internal arena-backed tree.
pub struct MCTSEngine {
    /// Search configuration.
    pub config: MCTSConfig,
    /// Arena of nodes for the current search.
    arena: Vec<MCTSNode>,
    /// Internal RNG state.
    rng: u64,
}
impl MCTSEngine {
    /// Create a search engine with the provided config.
    pub fn new(config: MCTSConfig) -> Self {
        let rng = config.seed;
        Self {
            config,
            arena: Vec::new(),
            rng,
        }
    }
    /// Return the active config.
    pub fn config(&self) -> &MCTSConfig {
        &self.config
    }
    /// Search for the best action and return its id, or `None` when no actions exist.
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
        if root_actions.is_empty() {
            return None;
        }
        self.arena.push(MCTSNode::new(None, None, root_actions));
        for _ in 0..self.config.iterations {
            let (node_idx, state) = self.select(0, root_state.clone(), apply_action);
            let (node_idx, state) = self.expand(node_idx, state, get_actions, apply_action);
            let score = self.rollout(&state, get_actions, apply_action, evaluate);
            self.backpropagate(node_idx, score as f64);
        }
        let root = &self.arena[0];
        root.children
            .iter()
            .max_by_key(|&&c| self.arena[c].visits)
            .and_then(|&c| self.arena[c].action)
    }
    /// Follow UCT until an expandable node is reached.
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
            let best_child = *node
                .children
                .iter()
                .max_by(|&&a, &&b| {
                    self.arena[a]
                        .uct(parent_visits, c)
                        .partial_cmp(&self.arena[b].uct(parent_visits, c))
                        .unwrap()
                })
                .unwrap();
            let action = self.arena[best_child].action.unwrap();
            state = apply_action(&state, action);
            idx = best_child;
        }
    }
    /// Expand one untried action from `node_idx`.
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
        self.arena
            .push(MCTSNode::new(Some(node_idx), Some(action), child_actions));
        self.arena[node_idx].children.push(child_idx);
        (child_idx, new_state)
    }
    /// Run a random rollout from `state` and return the evaluated score.
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
            if actions.is_empty() {
                break;
            }
            let i = self.rand_usize(actions.len());
            cur = apply_action(&cur, actions[i]);
        }
        evaluate(&cur)
    }
    /// Propagate a rollout score back to the root.
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
    /// Sample a random index in `[0, n)`.
    fn rand_usize(&mut self, n: usize) -> usize {
        self.rng ^= self.rng << 13;
        self.rng ^= self.rng >> 7;
        self.rng ^= self.rng << 17;
        (self.rng as usize) % n
    }
}
