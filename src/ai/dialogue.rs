//! Dialogue topic and branch scoring for AI conversations.
//! Owns `DialogueBranch`, `DialogueTopic`, and `DialogueAI`.
//! Does not own rendering or UI; it only selects topic and branch identifiers.
//! Depends on `HashMap` for utility score lookup.
use std::collections::HashMap;
#[derive(Debug, Clone)]
/// Single branch inside a topic.
pub struct DialogueBranch {
    /// Branch identifier.
    pub id: String,
    /// Base branch weight.
    pub weight: f32,
    /// Required FSM state, if any.
    pub required_fsm_state: Option<String>,
    /// Required behavior-tree status, if any.
    pub required_bt_status: Option<String>,
    /// Optional utility score lookup key.
    pub utility_key: Option<String>,
}
#[derive(Debug, Clone)]
/// Top-level dialogue topic with an ordered set of branches.
pub struct DialogueTopic {
    /// Topic identifier.
    pub id: String,
    /// Base topic weight.
    pub weight: f32,
    /// Required FSM state, if any.
    pub required_fsm_state: Option<String>,
    /// Required behavior-tree status, if any.
    pub required_bt_status: Option<String>,
    /// Optional utility score lookup key.
    pub utility_key: Option<String>,
    /// Candidate branches under this topic.
    pub branches: Vec<DialogueBranch>,
}
/// Topic and branch selector with gate checks and utility scoring.
pub struct DialogueAI {
    /// All registered topics.
    pub topics: Vec<DialogueTopic>,
    /// Current FSM state gate.
    pub fsm_state: Option<String>,
    /// Current behavior-tree status gate.
    pub bt_status: Option<String>,
    /// Utility scores keyed by topic or branch name.
    pub utility_scores: HashMap<String, f32>,
}
impl DialogueAI {
    /// Create an empty dialogue selector.
    pub fn new() -> Self {
        Self {
            topics: Vec::new(),
            fsm_state: None,
            bt_status: None,
            utility_scores: HashMap::new(),
        }
    }
    /// Set the FSM state gate used by topic and branch selection.
    pub fn set_fsm_state(&mut self, state: Option<String>) {
        self.fsm_state = state;
    }
    /// Set the behavior-tree status gate used by topic and branch selection.
    pub fn set_bt_status(&mut self, status: Option<String>) {
        self.bt_status = status;
    }
    /// Store a utility score under `key`.
    pub fn set_utility_score(&mut self, key: String, score: f32) {
        self.utility_scores.insert(key, score);
    }
    /// Remove all cached utility scores.
    pub fn clear_utility_scores(&mut self) {
        self.utility_scores.clear();
    }
    /// Add a topic with optional gate requirements and utility key.
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
    /// Add a branch to the named topic; returns `false` if the topic is missing.
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
    /// Return the best matching topic id, or `None` when no topic matches.
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
    /// Return the best matching branch id for `topic_id`, or `None` when none matches.
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
    /// Return the number of registered topics.
    pub fn topic_count(&self) -> usize {
        self.topics.len()
    }
    /// Return topic score when gates pass; `None` when gates fail.
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
    /// Return branch score when gates pass; `None` when gates fail.
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
    /// Return `true` when the required FSM and BT gates both match the current state.
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
