
//! - High-level strategy selection scoring named goals against current tag context over time.
//! - Goal records with eligibility tags, priority scaling, enable state, and computed scores.
//! - Timed evaluation flow querying external scorers and storing the active strategic choice.

/// One strategic goal considered by the planner.
#[derive(Clone)]
pub struct StrategicGoal {
    /// Goal name.
    pub name: String,
    /// Latest computed score.
    pub score: f32,
    /// Required tags that must be active for this goal.
    pub precondition_tags: Vec<String>,
    /// Whether the goal participates in evaluation.
    pub enabled: bool,
    /// Priority multiplier applied to the raw score.
    pub priority: f32,
}
impl StrategicGoal {
    /// Create an enabled goal with default priority.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            score: 0.0,
            precondition_tags: Vec::new(),
            enabled: true,
            priority: 1.0,
        }
    }
    /// Add a required tag.
    pub fn require_tag(&mut self, tag: &str) {
        self.precondition_tags.push(tag.to_string());
    }
    /// Return `true` when all required tags are present and the goal is enabled.
    pub fn is_eligible(&self, active_tags: &[String]) -> bool {
        self.enabled
            && self
                .precondition_tags
                .iter()
                .all(|t| active_tags.iter().any(|at| at == t))
    }
}
/// Periodic goal scorer that keeps the currently active goal name.
pub struct StrategyAI {
    /// Registered goals.
    pub goals: Vec<StrategicGoal>,
    /// Seconds between evaluations.
    pub update_interval: f32,
    /// Accumulated time since the last evaluation.
    timer: f32,
    /// Name of the currently active goal.
    active_goal: Option<String>,
    /// Tags used for eligibility checks.
    pub active_tags: Vec<String>,
    /// Number of evaluations performed.
    pub total_evaluations: u32,
}
impl StrategyAI {
    /// Create a strategy AI that evaluates every `update_interval` seconds.
    pub fn new(update_interval: f32) -> Self {
        Self {
            goals: Vec::new(),
            update_interval: update_interval.max(0.01),
            timer: 0.0,
            active_goal: None,
            active_tags: Vec::new(),
            total_evaluations: 0,
        }
    }
    /// Add a goal to the evaluation set.
    pub fn add_goal(&mut self, goal: StrategicGoal) {
        self.goals.push(goal);
    }
    /// Add a goal with the given name.
    pub fn add_goal_named(&mut self, name: &str) {
        self.add_goal(StrategicGoal::new(name));
    }
    /// Replace the active tag set.
    pub fn set_tags(&mut self, tags: Vec<String>) {
        self.active_tags = tags;
    }
    /// Add a tag if it is not already present.
    pub fn add_tag(&mut self, tag: &str) {
        if !self.active_tags.iter().any(|t| t == tag) {
            self.active_tags.push(tag.to_string());
        }
    }
    /// Remove a tag if it exists.
    pub fn remove_tag(&mut self, tag: &str) {
        self.active_tags.retain(|t| t != tag);
    }
    /// Return the name of the active goal, or `None` when nothing is selected.
    pub fn active_goal(&self) -> Option<&str> {
        self.active_goal.as_deref()
    }
    /// Advance the timer and evaluate goals when the update interval elapses.
    pub fn update<F>(&mut self, dt: f32, scorer: &mut F)
    where
        F: FnMut(&str) -> f32,
    {
        self.timer += dt;
        if self.timer >= self.update_interval {
            self.timer -= self.update_interval;
            self.evaluate_all(scorer);
        }
    }
    /// Force immediate evaluation and reset the timer.
    pub fn force_evaluate<F>(&mut self, scorer: &mut F)
    where
        F: FnMut(&str) -> f32,
    {
        self.timer = 0.0;
        self.evaluate_all(scorer);
    }
    /// Evaluate all goals and store the highest-scoring eligible goal.
    fn evaluate_all<F>(&mut self, scorer: &mut F)
    where
        F: FnMut(&str) -> f32,
    {
        let mut best_name: Option<String> = None;
        let mut best_score = f32::NEG_INFINITY;
        for goal in &mut self.goals {
            if !goal.is_eligible(&self.active_tags) {
                goal.score = 0.0;
                continue;
            }
            let raw = scorer(&goal.name);
            goal.score = raw * goal.priority;
            if goal.score > best_score {
                best_score = goal.score;
                best_name = Some(goal.name.clone());
            }
        }
        self.active_goal = best_name;
        self.total_evaluations += 1;
    }
    /// Return the number of goals.
    pub fn goal_count(&self) -> usize {
        self.goals.len()
    }
    /// Return the remaining time until the next scheduled evaluation.
    pub fn time_until_next(&self) -> f32 {
        (self.update_interval - self.timer).max(0.0)
    }
}
