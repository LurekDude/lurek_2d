//! GOAP planning over symbolic world-state facts and action effects.
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};

use crate::log_msg;
use crate::runtime::log_messages::{GP01, GP02, GP03};
use mlua::RegistryKey;

/// A single GOAP action with boolean preconditions and effects.
pub struct GOAPAction {
    /// Human-readable action name, returned in plan results (e.g., `"chop_tree"`, `"craft_axe"`).
    pub name: String,
    /// Numeric cost used by A* to prefer cheaper action sequences.
    pub cost: f64,
    /// Optional Lua callback invoked when this action is executed during plan playback.
    pub callback: Option<RegistryKey>,
    /// Boolean conditions that must all be true in the world state for this action to be applicable during planning.
    pub preconditions: HashMap<String, bool>,
    /// Boolean effects applied to the world state after this action executes.
    pub effects: HashMap<String, bool>,
}

/// A planning goal expressed as a desired boolean world state.
pub struct GOAPGoal {
    /// Human-readable goal name (e.g., `"survive"`, `"build_shelter"`).
    pub name: String,
    /// Priority for goal selection. The planner picks the goal with the highest priority when `plan()` is called without a specific goal index.
    pub priority: f64,
    /// Target boolean world state. All entries must match for the goal to be considered satisfied and the plan complete.
    pub state: HashMap<String, bool>,
}

/// Node in the GOAP A* search.
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

/// A* planner that finds optimal action sequences to satisfy goals over boolean world state.
pub struct GOAPPlanner {
    /// Available actions the planner can compose into sequences.
    pub actions: Vec<GOAPAction>,
    /// Goals the planner can target, selected by highest priority.
    pub goals: Vec<GOAPGoal>,
    /// Maximum A* iterations per planning call. Default 10 000. Zero is treated as unlimited.
    pub max_iterations: usize,
}

impl GOAPPlanner {
    /// Create a new empty GOAP planner.
    pub fn new() -> Self {
        log_msg!(debug, GP01);
        Self {
            actions: Vec::new(),
            goals: Vec::new(),
            max_iterations: 10_000,
        }
    }

    /// Plans a sequence of actions to satisfy the highest-priority goal.
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

    /// Plans an action sequence to satisfy the goal at `goal_idx`, using the provided `world_state` as the starting point. Returns an empty vec if the index is out of range.
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
        let max_iterations = self.max_iterations;

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

    /// Add an action with the given cost and optional Lua callback. Used by the Lua API.
    pub fn add_action(&mut self, name: String, cost: f64, callback: Option<RegistryKey>) {
        self.actions.push(GOAPAction {
            name,
            cost,
            callback,
            preconditions: HashMap::new(),
            effects: HashMap::new(),
        });
    }

    /// Add a boolean precondition to the named action. No-op if action not found.
    pub fn add_precondition(&mut self, action_name: &str, key: String, value: bool) {
        if let Some(a) = self.actions.iter_mut().find(|a| a.name == action_name) {
            a.preconditions.insert(key, value);
        }
    }

    /// Add a boolean effect to the named action. No-op if action not found.
    pub fn add_effect(&mut self, action_name: &str, key: String, value: bool) {
        if let Some(a) = self.actions.iter_mut().find(|a| a.name == action_name) {
            a.effects.insert(key, value);
        }
    }

    /// Add a goal with the given name and priority. Used by the Lua API.
    pub fn add_goal(&mut self, name: String, priority: f64) {
        self.goals.push(GOAPGoal {
            name,
            priority,
            state: HashMap::new(),
        });
    }

    /// Set a boolean condition on the named goal. No-op if goal not found.
    pub fn set_goal_state(&mut self, goal_name: &str, key: String, value: bool) {
        if let Some(g) = self.goals.iter_mut().find(|g| g.name == goal_name) {
            g.state.insert(key, value);
        }
    }

    /// Return the maximum A* planning iterations.
    pub fn get_max_iterations(&self) -> usize {
        self.max_iterations
    }

    /// Set the maximum A* planning iterations. A value of `0` means unlimited.
    pub fn set_max_iterations(&mut self, n: usize) {
        self.max_iterations = n;
    }
}

impl Default for GOAPPlanner {
    fn default() -> Self {
        Self::new()
    }
}

