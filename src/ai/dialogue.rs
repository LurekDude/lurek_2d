//! Dialogue AI helper that combines FSM/BT/Utility signals to choose
//! conversation topics and branches.
//!
//! The module is intentionally data-driven: game code feeds current decision
//! context (FSM state, BT status, utility action scores), then asks the planner
//! to choose the best topic/branch.

use std::collections::HashMap;

/// One branch candidate under a dialogue topic.
///
/// # Fields
/// - `id` — `String`.
/// - `weight` — `f32`.
/// - `required_fsm_state` — `Option<String>`.
/// - `required_bt_status` — `Option<String>`.
/// - `utility_key` — `Option<String>`.
#[derive(Debug, Clone)]
pub struct DialogueBranch {
    /// Branch identifier returned to Lua/game logic.
    pub id: String,
    /// Baseline branch weight.
    pub weight: f32,
    /// Optional FSM-state gate.
    pub required_fsm_state: Option<String>,
    /// Optional BT-status gate.
    pub required_bt_status: Option<String>,
    /// Optional utility score key that contributes to branch ranking.
    pub utility_key: Option<String>,
}

/// One dialogue topic with weighted branch options.
///
/// # Fields
/// - `id` — `String`.
/// - `weight` — `f32`.
/// - `required_fsm_state` — `Option<String>`.
/// - `required_bt_status` — `Option<String>`.
/// - `utility_key` — `Option<String>`.
/// - `branches` — `Vec<DialogueBranch>`.
#[derive(Debug, Clone)]
pub struct DialogueTopic {
    /// Topic identifier returned to Lua/game logic.
    pub id: String,
    /// Baseline topic weight.
    pub weight: f32,
    /// Optional FSM-state gate.
    pub required_fsm_state: Option<String>,
    /// Optional BT-status gate.
    pub required_bt_status: Option<String>,
    /// Optional utility score key that contributes to topic ranking.
    pub utility_key: Option<String>,
    /// Branch candidates under this topic.
    pub branches: Vec<DialogueBranch>,
}

/// Dialogue planner state and scoring context.
///
/// # Fields
/// - `topics` — `Vec<DialogueTopic>`.
/// - `fsm_state` — `Option<String>`.
/// - `bt_status` — `Option<String>`.
/// - `utility_scores` — `HashMap<String, f32>`.
pub struct DialogueAI {
    /// Registered dialogue topics.
    pub topics: Vec<DialogueTopic>,
    /// Current FSM state fed from gameplay logic.
    pub fsm_state: Option<String>,
    /// Current BT status fed from gameplay logic.
    pub bt_status: Option<String>,
    /// Utility scores keyed by action/topic labels.
    pub utility_scores: HashMap<String, f32>,
}

impl DialogueAI {
    /// Creates a new empty dialogue planner.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            topics: Vec::new(),
            fsm_state: None,
            bt_status: None,
            utility_scores: HashMap::new(),
        }
    }

    /// Sets the current FSM state used by topic/branch gate checks.
    ///
    /// # Parameters
    /// - `state` — `Option<String>`.
    pub fn set_fsm_state(&mut self, state: Option<String>) {
        self.fsm_state = state;
    }

    /// Sets the current BT status used by topic/branch gate checks.
    ///
    /// # Parameters
    /// - `status` — `Option<String>`.
    pub fn set_bt_status(&mut self, status: Option<String>) {
        self.bt_status = status;
    }

    /// Sets one utility score used when ranking topics/branches.
    ///
    /// # Parameters
    /// - `key` — `String`.
    /// - `score` — `f32`.
    pub fn set_utility_score(&mut self, key: String, score: f32) {
        self.utility_scores.insert(key, score);
    }

    /// Clears all utility scores.
    pub fn clear_utility_scores(&mut self) {
        self.utility_scores.clear();
    }

    /// Adds a dialogue topic.
    ///
    /// # Parameters
    /// - `id` — `String`.
    /// - `weight` — `f32`.
    /// - `required_fsm_state` — `Option<String>`.
    /// - `required_bt_status` — `Option<String>`.
    /// - `utility_key` — `Option<String>`.
    pub fn add_topic(
        &mut self,
        id: String,
        weight: f32,
        required_fsm_state: Option<String>,
        required_bt_status: Option<String>,
        utility_key: Option<String>,
    ) {
        self.topics.push(DialogueTopic {
            id,
            weight,
            required_fsm_state,
            required_bt_status,
            utility_key,
            branches: Vec::new(),
        });
    }

    /// Adds a branch under an existing topic.
    ///
    /// # Parameters
    /// - `topic_id` — `&str`.
    /// - `id` — `String`.
    /// - `weight` — `f32`.
    /// - `required_fsm_state` — `Option<String>`.
    /// - `required_bt_status` — `Option<String>`.
    /// - `utility_key` — `Option<String>`.
    ///
    /// # Returns
    /// `bool` — true if topic exists and branch was added.
    pub fn add_branch(
        &mut self,
        topic_id: &str,
        id: String,
        weight: f32,
        required_fsm_state: Option<String>,
        required_bt_status: Option<String>,
        utility_key: Option<String>,
    ) -> bool {
        if let Some(topic) = self.topics.iter_mut().find(|t| t.id == topic_id) {
            topic.branches.push(DialogueBranch {
                id,
                weight,
                required_fsm_state,
                required_bt_status,
                utility_key,
            });
            return true;
        }
        false
    }

    /// Selects the best topic for the current context.
    ///
    /// # Returns
    /// `Option<String>`.
    pub fn select_topic(&self) -> Option<String> {
        let mut best: Option<(&DialogueTopic, f32)> = None;
        for topic in &self.topics {
            if let Some(score) = self.topic_score(topic) {
                match best {
                    Some((_, best_score)) if score <= best_score => {}
                    _ => best = Some((topic, score)),
                }
            }
        }
        best.map(|(topic, _)| topic.id.clone())
    }

    /// Selects the best branch for a given topic id and current context.
    ///
    /// # Parameters
    /// - `topic_id` — `&str`.
    ///
    /// # Returns
    /// `Option<String>`.
    pub fn select_branch(&self, topic_id: &str) -> Option<String> {
        let topic = self.topics.iter().find(|t| t.id == topic_id)?;
        let mut best: Option<(&DialogueBranch, f32)> = None;
        for branch in &topic.branches {
            if let Some(score) = self.branch_score(branch) {
                match best {
                    Some((_, best_score)) if score <= best_score => {}
                    _ => best = Some((branch, score)),
                }
            }
        }
        best.map(|(branch, _)| branch.id.clone())
    }

    /// Returns the number of registered topics.
    ///
    /// # Returns
    /// `usize`.
    pub fn topic_count(&self) -> usize {
        self.topics.len()
    }

    fn topic_score(&self, topic: &DialogueTopic) -> Option<f32> {
        if !self.matches_gate(
            topic.required_fsm_state.as_deref(),
            topic.required_bt_status.as_deref(),
        ) {
            return None;
        }
        let utility = topic
            .utility_key
            .as_ref()
            .and_then(|k| self.utility_scores.get(k).copied())
            .unwrap_or(0.0);
        Some(topic.weight + utility)
    }

    fn branch_score(&self, branch: &DialogueBranch) -> Option<f32> {
        if !self.matches_gate(
            branch.required_fsm_state.as_deref(),
            branch.required_bt_status.as_deref(),
        ) {
            return None;
        }
        let utility = branch
            .utility_key
            .as_ref()
            .and_then(|k| self.utility_scores.get(k).copied())
            .unwrap_or(0.0);
        Some(branch.weight + utility)
    }

    fn matches_gate(&self, required_fsm: Option<&str>, required_bt: Option<&str>) -> bool {
        if let Some(req) = required_fsm {
            if self.fsm_state.as_deref() != Some(req) {
                return false;
            }
        }
        if let Some(req) = required_bt {
            if self.bt_status.as_deref() != Some(req) {
                return false;
            }
        }
        true
    }
}

impl Default for DialogueAI {
    fn default() -> Self {
        Self::new()
    }
}
