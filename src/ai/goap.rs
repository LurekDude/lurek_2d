//! Goal-Oriented Action Planning (GOAP) using A★ search over boolean world state.
//!
//! GOAP is a planning system where the agent has a set of actions (each with
//! boolean preconditions and effects) and a set of goals (target boolean world
//! states). The planner uses A★ search to find the cheapest sequence of actions
//! that transforms the current world state into one that satisfies the
//! highest-priority goal.
//!
//! ## How Planning Works
//!
//! 1. The planner picks the highest-priority [`GOAPGoal`] (by `priority` field).
//! 2. It initializes an A★ search with the current world state as the start node.
//! 3. For each node, it tries every action whose preconditions are met, generating
//!    successor nodes by applying the action's effects.
//! 4. The heuristic counts unsatisfied goal conditions (admissible: never overestimates).
//! 5. The first path that satisfies all goal conditions is returned as a list of
//!    action names in execution order.
//!
//! ## Search Limits
//!
//! The planner enforces two depth/iteration limits:
//! - `max_depth` — maximum number of actions in a plan (prevents infinite chains).
//! - Hard limit of 10,000 A★ iterations (prevents runaway computation on large
//!   action spaces).
//!
//! ## Lua Integration
//!
//! Actions can have optional Lua callbacks (`GOAPAction::callback`) that are
//! executed when the game loop processes the planned action sequence. The planner
//! itself is pure logic — it never calls Lua during planning.

use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};

use crate::engine::log_messages::{GP01, GP02, GP03};
use crate::log_msg;
use mlua::RegistryKey;

/// A single GOAP action with boolean preconditions and effects.
///
/// Actions are the building blocks of GOAP plans. Each action declares:
/// - What must be true before it can execute (preconditions).
/// - What becomes true after it executes (effects).
/// - How expensive it is (cost), used by A★ to prefer cheaper plans.
///
/// The planner never modifies actions — they are reference data used during
/// the search phase.
///
/// # Fields
/// - `name` — `String`.
/// - `cost` — `f64`.
/// - `callback` — `Option<RegistryKey>`.
/// - `preconditions` — `HashMap<String, bool>`.
/// - `effects` — `HashMap<String, bool>`.
pub struct GOAPAction {
    /// Human-readable action name, returned in plan results (e.g., `"chop_tree"`, `"craft_axe"`).
    pub name: String,
    /// Numeric cost used by A★ to prefer cheaper action sequences.
    /// Lower is better. Must be non-negative.
    pub cost: f64,
    /// Optional Lua callback invoked when this action is executed during plan playback.
    /// Not called during planning — planning is pure logic only.
    pub callback: Option<RegistryKey>,
    /// Boolean conditions that must all be true in the world state for this
    /// action to be considered during planning.
    pub preconditions: HashMap<String, bool>,
    /// Boolean effects applied to the world state after this action executes.
    /// Each key-value pair overwrites the corresponding world-state entry.
    pub effects: HashMap<String, bool>,
}

/// A planning goal expressed as a desired boolean world state.
///
/// Goals represent what the agent wants to achieve. The planner selects the
/// highest-priority goal and searches for an action sequence that transforms
/// the current world state to satisfy all conditions in `state`.
///
/// # Fields
/// - `name` — `String`.
/// - `priority` — `f64`.
/// - `state` — `HashMap<String, bool>`.
pub struct GOAPGoal {
    /// Human-readable goal name (e.g., `"survive"`, `"build_shelter"`).
    pub name: String,
    /// Priority for goal selection. The planner picks the goal with the highest
    /// priority value. When priorities are equal, the last-added goal wins.
    pub priority: f64,
    /// Target boolean world state. All entries must match for the goal to be
    /// considered satisfied.
    pub state: HashMap<String, bool>,
}

/// Node in the GOAP A★ search.
#[derive(Clone)]
struct PlanNode {
    state: HashMap<String, bool>,
    actions: Vec<usize>,
    cost: f64,
    heuristic: f64,
}

impl PartialEq for PlanNode {
    fn eq(&self, other: &Self) -> bool {
        self.total() == other.total()
    }
}
impl Eq for PlanNode {}
impl PartialOrd for PlanNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for PlanNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .total()
            .partial_cmp(&self.total())
            .unwrap_or(Ordering::Equal)
    }
}

impl PlanNode {
    fn total(&self) -> f64 {
        self.cost + self.heuristic
    }
}

/// A★ planner that finds optimal action sequences to satisfy goals over boolean world state.
///
/// The planner holds a set of available [`GOAPAction`]s and a set of [`GOAPGoal`]s.
/// When `plan()` is called, it selects the highest-priority goal and uses A★ search
/// to find the cheapest sequence of actions whose cumulative effects satisfy all
/// goal conditions from the given world state.
///
/// The planner is stateless between calls — it does not cache search results.
/// Each `plan()` call performs a fresh search. For real-time games, call `plan()`
/// only when conditions change, not every frame.
///
/// # Fields
/// - `actions` — `Vec<GOAPAction>`.
/// - `goals` — `Vec<GOAPGoal>`.
pub struct GOAPPlanner {
    /// Available actions the planner can compose into sequences.
    pub actions: Vec<GOAPAction>,
    /// Goals the planner can target, selected by highest priority.
    pub goals: Vec<GOAPGoal>,
}

impl GOAPPlanner {
    /// Creates a new empty GOAP planner. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        log_msg!(debug, GP01);
        Self {
            actions: Vec::new(),
            goals: Vec::new(),
        }
    }

    /// Plans a sequence of actions to satisfy the highest-priority goal.
    ///
    /// # Parameters
    /// - `world_state` — `&HashMap<String, bool>`.
    /// - `max_depth` — `usize`.
    ///
    /// # Returns
    /// `Vec<String>`.
    /// Returns action names in execution order, or empty if no plan found.
    pub fn plan(&self, world_state: &HashMap<String, bool>, max_depth: usize) -> Vec<String> {
        // Find highest-priority goal
        let best_goal = self.goals.iter().max_by(|a, b| {
            a.priority
                .partial_cmp(&b.priority)
                .unwrap_or(Ordering::Equal)
        });
        let goal = match best_goal {
            Some(g) => g,
            None => return Vec::new(),
        };
        self.plan_for_goal(&goal.state, world_state, max_depth)
    }

    /// Plans for a specific goal index.
    ///
    /// # Parameters
    /// - `goal_idx` — `usize`.
    /// - `world_state` — `&HashMap<String, bool>`.
    /// - `max_depth` — `usize`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn plan_for_goal_idx(
        &self,
        goal_idx: usize,
        world_state: &HashMap<String, bool>,
        max_depth: usize,
    ) -> Vec<String> {
        if goal_idx >= self.goals.len() {
            return Vec::new();
        }
        self.plan_for_goal(&self.goals[goal_idx].state, world_state, max_depth)
    }

    fn plan_for_goal(
        &self,
        goal_state: &HashMap<String, bool>,
        world_state: &HashMap<String, bool>,
        max_depth: usize,
    ) -> Vec<String> {
        if self.goal_satisfied(goal_state, world_state) {
            return Vec::new(); // Already satisfied
        }

        let mut open = BinaryHeap::new();
        open.push(PlanNode {
            state: world_state.clone(),
            actions: Vec::new(),
            cost: 0.0,
            heuristic: self.heuristic(goal_state, world_state),
        });

        let mut iterations = 0;
        let max_iterations = 10_000;

        while let Some(current) = open.pop() {
            iterations += 1;
            if iterations > max_iterations {
                break;
            }
            if current.actions.len() >= max_depth {
                continue;
            }

            for (i, action) in self.actions.iter().enumerate() {
                if !self.preconditions_met(&action.preconditions, &current.state) {
                    continue;
                }
                let mut new_state = current.state.clone();
                for (k, v) in &action.effects {
                    new_state.insert(k.clone(), *v);
                }
                let mut new_actions = current.actions.clone();
                new_actions.push(i);

                if self.goal_satisfied(goal_state, &new_state) {
                    log_msg!(debug, GP03);
                    return new_actions
                        .iter()
                        .map(|&idx| self.actions[idx].name.clone())
                        .collect();
                }

                open.push(PlanNode {
                    heuristic: self.heuristic(goal_state, &new_state),
                    cost: current.cost + action.cost,
                    state: new_state,
                    actions: new_actions,
                });
            }
        }

        log_msg!(warn, GP02);
        Vec::new() // No plan found
    }

    fn goal_satisfied(&self, goal: &HashMap<String, bool>, state: &HashMap<String, bool>) -> bool {
        goal.iter().all(|(k, v)| state.get(k) == Some(v))
    }

    fn preconditions_met(
        &self,
        preconds: &HashMap<String, bool>,
        state: &HashMap<String, bool>,
    ) -> bool {
        preconds.iter().all(|(k, v)| state.get(k) == Some(v))
    }

    fn heuristic(&self, goal: &HashMap<String, bool>, state: &HashMap<String, bool>) -> f64 {
        goal.iter()
            .filter(|(k, v)| state.get(*k) != Some(*v))
            .count() as f64
    }

    /// Adds an action with the given cost and optional Lua callback. Used by the Lua API.
    ///
    /// # Parameters
    /// - `name` — `String`.
    /// - `cost` — `f64`.
    /// - `callback` — `Option<RegistryKey>`.
    pub fn add_action(&mut self, name: String, cost: f64, callback: Option<RegistryKey>) {
        self.actions.push(GOAPAction {
            name,
            cost,
            callback,
            preconditions: HashMap::new(),
            effects: HashMap::new(),
        });
    }

    /// Adds a boolean precondition to the named action. No-op if action not found.
    ///
    /// # Parameters
    /// - `action_name` — `&str`.
    /// - `key` — `String`.
    /// - `value` — `bool`.
    pub fn add_precondition(&mut self, action_name: &str, key: String, value: bool) {
        if let Some(a) = self.actions.iter_mut().find(|a| a.name == action_name) {
            a.preconditions.insert(key, value);
        }
    }

    /// Adds a boolean effect to the named action. No-op if action not found.
    ///
    /// # Parameters
    /// - `action_name` — `&str`.
    /// - `key` — `String`.
    /// - `value` — `bool`.
    pub fn add_effect(&mut self, action_name: &str, key: String, value: bool) {
        if let Some(a) = self.actions.iter_mut().find(|a| a.name == action_name) {
            a.effects.insert(key, value);
        }
    }

    /// Adds a goal with the given name and priority. Used by the Lua API.
    ///
    /// # Parameters
    /// - `name` — `String`.
    /// - `priority` — `f64`.
    pub fn add_goal(&mut self, name: String, priority: f64) {
        self.goals.push(GOAPGoal {
            name,
            priority,
            state: HashMap::new(),
        });
    }

    /// Sets a boolean condition on the named goal. No-op if goal not found.
    ///
    /// # Parameters
    /// - `goal_name` — `&str`.
    /// - `key` — `String`.
    /// - `value` — `bool`.
    pub fn set_goal_state(&mut self, goal_name: &str, key: String, value: bool) {
        if let Some(g) = self.goals.iter_mut().find(|g| g.name == goal_name) {
            g.state.insert(key, value);
        }
    }
}

impl Default for GOAPPlanner {
    fn default() -> Self {
        Self::new()
    }
}
