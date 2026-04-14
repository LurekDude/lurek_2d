//! Strategic AI — high-level goal evaluation and throttled decision-making.
//!
//! Provides a turn-like strategic planner for AI controllers that operate at a
//! slow update cadence (every N seconds) rather than every frame. Typical uses:
//! - RTS faction AI deciding where to expand or attack.
//! - RPG boss AI re-evaluating its phase/strategy.
//! - City simulation resource allocation decisions.
//!
//! ## Architecture
//!
//! - [`StrategicGoal`] is a named candidate plan with an estimate score and
//!   optional precondition tags.
//! - [`StrategicEvaluator`] is a trait exposing `score_goal` — implement this
//!   in a game struct to provide context-sensitive scoring.
//! - [`StrategyAI`] owns the goal list and a cooldown timer. `update(dt)` counts
//!   down the timer; when it fires, `evaluate_all` scores every goal and sets
//!   the best as the active goal.
//!
//! ## Typical Usage Sequence
//!
//! 1. Create `StrategyAI::new(update_interval)`.
//! 2. Add goals with `add_goal`.
//! 3. Each frame call `update(dt)` and pass a state snapshot for scoring.
//! 4. Read `active_goal()` to drive the agent's tactical layer.

// ────────────────────────────────────────────────────────────────────────────
// StrategicGoal
// ────────────────────────────────────────────────────────────────────────────

/// Named strategic goal with cost/benefit estimates.
///
/// # Fields
/// - `name` — `String`.
/// - `score` — `f32`.
/// - `precondition_tags` — `Vec<String>`.
/// - `enabled` — `bool`.
/// - `priority` — `f32`.
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
    /// Creates a new goal with full priority and no preconditions.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            score: 0.0,
            precondition_tags: Vec::new(),
            enabled: true,
            priority: 1.0,
        }
    }

    /// Adds a precondition tag requirement.
    ///
    /// # Parameters
    /// - `tag` — `&str`.
    pub fn require_tag(&mut self, tag: &str) {
        self.precondition_tags.push(tag.to_string());
    }

    /// Returns `true` if all precondition tags are present in `active_tags`.
    ///
    /// # Parameters
    /// - `active_tags` — `&[String]`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_eligible(&self, active_tags: &[String]) -> bool {
        self.enabled && self.precondition_tags.iter()
            .all(|t| active_tags.iter().any(|at| at == t))
    }
}

// ────────────────────────────────────────────────────────────────────────────
// StrategyAI
// ────────────────────────────────────────────────────────────────────────────

/// Throttled strategic goal evaluator.
///
/// Re-evaluates after `update_interval` seconds have elapsed or after a
/// `force_evaluate` call. Outside scoring closures provide the actual utility
/// estimate so the engine module stays game-agnostic.
///
/// # Fields
/// - `goals` — `Vec<StrategicGoal>`.
/// - `update_interval` — `f32`.
/// - `timer` — `f32`.
/// - `active_goal` — `Option<String>`.
/// - `active_tags` — `Vec<String>`.
/// - `total_evaluations` — `u32`.
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
    /// Creates a new strategy AI with the given evaluation interval in seconds.
    ///
    /// # Parameters
    /// - `update_interval` — `f32`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Adds a goal to the evaluator.
    ///
    /// # Parameters
    /// - `goal` — `StrategicGoal`.
    pub fn add_goal(&mut self, goal: StrategicGoal) {
        self.goals.push(goal);
    }

    /// Convenience: adds a named goal with default settings.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn add_goal_named(&mut self, name: &str) {
        self.add_goal(StrategicGoal::new(name));
    }

    /// Sets the active world-state tags used to filter goal eligibility.
    ///
    /// # Parameters
    /// - `tags` — `Vec<String>`.
    pub fn set_tags(&mut self, tags: Vec<String>) {
        self.active_tags = tags;
    }

    /// Adds a single active tag.
    ///
    /// # Parameters
    /// - `tag` — `&str`.
    pub fn add_tag(&mut self, tag: &str) {
        if !self.active_tags.iter().any(|t| t == tag) {
            self.active_tags.push(tag.to_string());
        }
    }

    /// Removes a tag.
    ///
    /// # Parameters
    /// - `tag` — `&str`.
    pub fn remove_tag(&mut self, tag: &str) {
        self.active_tags.retain(|t| t != tag);
    }

    /// Returns the name of the currently active goal, or `None` if no evaluation
    /// has run yet.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn active_goal(&self) -> Option<&str> {
        self.active_goal.as_deref()
    }

    /// Advances the timer by `dt` and evaluates goals when the interval expires.
    ///
    /// # Returns
    /// `f32,`.
    /// The scorer closure receives each goal's name and should return a utility
    /// in `[0.0, 1.0]`.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    /// - `scorer` — `FnMut(&str) -> f32`.
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
    ///
    /// # Returns
    /// `f32,`.
    ///
    /// # Parameters
    /// - `scorer` — `FnMut(&str) -> f32`.
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

    /// Returns the number of registered goals.
    ///
    /// # Returns
    /// `usize`.
    pub fn goal_count(&self) -> usize { self.goals.len() }

    /// Returns seconds remaining until the next scheduled evaluation.
    ///
    /// # Returns
    /// `f32`.
    pub fn time_until_next(&self) -> f32 {
        (self.update_interval - self.timer).max(0.0)
    }
}
