//! high-level strategic goal scoring and selection state.
// ---- Type: StrategicGoal ----

/// Named strategic goal with cost/benefit estimates.
#[derive(Clone)]
pub struct StrategicGoal {
    /// Unique goal name (e.g. `"expand_east"`, `"reinforce_base"`).
    pub name: String,
    /// Last computed utility score. Set by `evaluate_all`.
    pub score: f32,
    /// Tags that must be present in the active-tags set for this goal to be eligible.
    pub precondition_tags: Vec<String>,
    /// When `false`, this goal is skipped during evaluation.
    pub enabled: bool,
    /// Multiplier applied to the raw score to bias specific goals.
    pub priority: f32,
}

impl StrategicGoal {
    /// Create a new goal with full priority and no preconditions.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            score: 0.0,
            precondition_tags: Vec::new(),
            enabled: true,
            priority: 1.0,
        }
    }

    /// Add a precondition tag requirement.
    pub fn require_tag(&mut self, tag: &str) {
        self.precondition_tags.push(tag.to_string());
    }

    /// Return `true` if all precondition tags are present in `active_tags`.
    pub fn is_eligible(&self, active_tags: &[String]) -> bool {
        self.enabled
            && self
                .precondition_tags
                .iter()
                .all(|t| active_tags.iter().any(|at| at == t))
    }
}

// ---- Type: StrategyAI ----

/// Throttled strategic goal evaluator.
pub struct StrategyAI {
    /// All registered strategic goals.
    pub goals: Vec<StrategicGoal>,
    /// Seconds between strategy re-evaluations.
    pub update_interval: f32,
    timer: f32,
    active_goal: Option<String>,
    /// Set of tags describing current world state (used for goal preconditions).
    pub active_tags: Vec<String>,
    /// Total number of evaluation cycles completed.
    pub total_evaluations: u32,
}

impl StrategyAI {
    /// Create a new strategy AI with the given evaluation interval in seconds.
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

    /// Add a goal to the evaluator.
    pub fn add_goal(&mut self, goal: StrategicGoal) {
        self.goals.push(goal);
    }

    /// Convenience: adds a named goal with default settings.
    pub fn add_goal_named(&mut self, name: &str) {
        self.add_goal(StrategicGoal::new(name));
    }

    /// Set the active world-state tags used to filter goal eligibility.
    pub fn set_tags(&mut self, tags: Vec<String>) {
        self.active_tags = tags;
    }

    /// Add a single active tag.
    pub fn add_tag(&mut self, tag: &str) {
        if !self.active_tags.iter().any(|t| t == tag) {
            self.active_tags.push(tag.to_string());
        }
    }

    /// Remove a tag.
    pub fn remove_tag(&mut self, tag: &str) {
        self.active_tags.retain(|t| t != tag);
    }

    /// Return the name of the currently active goal, or `None` if no evaluation
    pub fn active_goal(&self) -> Option<&str> {
        self.active_goal.as_deref()
    }

    /// Advances the timer by `dt` and evaluates goals when the interval expires.
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

    /// Forces an immediate re-evaluation outside the normal interval.
    pub fn force_evaluate<F>(&mut self, scorer: &mut F)
    where
        F: FnMut(&str) -> f32,
    {
        self.timer = 0.0;
        self.evaluate_all(scorer);
    }

    /// Evaluates all eligible goals, updates their scores, and picks the best.
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

    /// Return the number of registered goals.
    pub fn goal_count(&self) -> usize {
        self.goals.len()
    }

    /// Return seconds remaining until the next scheduled evaluation.
    pub fn time_until_next(&self) -> f32 {
        (self.update_interval - self.timer).max(0.0)
    }
}

