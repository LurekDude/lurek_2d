
use crate::log_msg;
use crate::runtime::log_messages::{GP01, GP02, GP03};
use mlua::RegistryKey;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
pub struct GOAPAction {
    /// Unique name identifying this action.
    pub name: String,
    /// Path cost used by the A* planner; lower cost preferred.
    pub cost: f64,
    /// Optional Lua callback invoked when this action is executed.
    pub callback: Option<RegistryKey>,
    /// World-state conditions that must be true before this action can run.
    pub preconditions: HashMap<String, bool>,
    /// World-state changes applied after this action completes successfully.
    pub effects: HashMap<String, bool>,
}
pub struct GOAPGoal {
    /// Unique name identifying this goal.
    pub name: String,
    /// Selection weight; the highest-priority unsatisfied goal is planned for.
    pub priority: f64,
    /// Desired world state this goal requires to be satisfied.
    pub state: HashMap<String, bool>,
}
#[derive(Clone)]
struct PlanNode {
    /// World state at this search node.
    state: HashMap<String, bool>,
    /// Sequence of action indices selected to reach this node.
    actions: Vec<usize>,
    /// Accumulated action cost from the start.
    cost: f64,
    /// Estimated remaining cost to goal; counts unsatisfied goal conditions.
    heuristic: f64,
}
impl PartialEq for PlanNode {
    /// Equal when `total()` values are equal (used for heap ordering only).
    fn eq(&self, other: &Self) -> bool {
        self.total() == other.total()
    }
}
impl Eq for PlanNode {}
impl PartialOrd for PlanNode {
    /// Delegate to `Ord::cmp`.
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for PlanNode {
    /// Min-heap ordering: lower `total()` wins, ties resolved as `Equal`.
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .total()
            .partial_cmp(&self.total())
            .unwrap_or(Ordering::Equal)
    }
}
impl PlanNode {
    /// Return the combined f-score `cost + heuristic`.
    fn total(&self) -> f64 {
        self.cost + self.heuristic
    }
}
pub struct GOAPPlanner {
    /// All registered actions available to the planner.
    pub actions: Vec<GOAPAction>,
    /// All registered goals; the highest-priority goal is selected at plan time.
    pub goals: Vec<GOAPGoal>,
    /// Hard cap on A* iterations to prevent runaway planning; default 10 000.
    pub max_iterations: usize,
}
impl GOAPPlanner {
    /// Create a planner with an empty action and goal lists and `max_iterations = 10 000`.
    pub fn new() -> Self {
        log_msg!(debug, GP01);
        Self {
            actions: Vec::new(),
            goals: Vec::new(),
            max_iterations: 10_000,
        }
    }
    /// Plan for the highest-priority goal; return ordered action name list or empty on failure.
    pub fn plan(&self, world_state: &HashMap<String, bool>, max_depth: usize) -> Vec<String> {
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
    /// Plan for the goal at `goal_idx`; return ordered action name list or empty on failure.
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
    /// A* search from `world_state` toward `goal_state` up to `max_depth` actions.
    fn plan_for_goal(
        &self,
        goal_state: &HashMap<String, bool>,
        world_state: &HashMap<String, bool>,
        max_depth: usize,
    ) -> Vec<String> {
        if self.goal_satisfied(goal_state, world_state) {
            return Vec::new();
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
        Vec::new()
    }
    /// Return `true` when every goal condition is met in `state`.
    fn goal_satisfied(&self, goal: &HashMap<String, bool>, state: &HashMap<String, bool>) -> bool {
        goal.iter().all(|(k, v)| state.get(k) == Some(v))
    }
    /// Return `true` when every precondition is satisfied by `state`.
    fn preconditions_met(
        &self,
        preconds: &HashMap<String, bool>,
        state: &HashMap<String, bool>,
    ) -> bool {
        preconds.iter().all(|(k, v)| state.get(k) == Some(v))
    }
    /// Count unsatisfied goal conditions as a distance-to-goal estimate.
    fn heuristic(&self, goal: &HashMap<String, bool>, state: &HashMap<String, bool>) -> f64 {
        goal.iter()
            .filter(|(k, v)| state.get(*k) != Some(*v))
            .count() as f64
    }
    /// Register a new action with an empty precondition and effect set.
    pub fn add_action(&mut self, name: String, cost: f64, callback: Option<RegistryKey>) {
        self.actions.push(GOAPAction {
            name,
            cost,
            callback,
            preconditions: HashMap::new(),
            effects: HashMap::new(),
        });
    }
    /// Add a precondition entry to the named action; no-op if the action is not found.
    pub fn add_precondition(&mut self, action_name: &str, key: String, value: bool) {
        if let Some(a) = self.actions.iter_mut().find(|a| a.name == action_name) {
            a.preconditions.insert(key, value);
        }
    }
    /// Add an effect entry to the named action; no-op if the action is not found.
    pub fn add_effect(&mut self, action_name: &str, key: String, value: bool) {
        if let Some(a) = self.actions.iter_mut().find(|a| a.name == action_name) {
            a.effects.insert(key, value);
        }
    }
    /// Register a new goal with an empty desired state map.
    pub fn add_goal(&mut self, name: String, priority: f64) {
        self.goals.push(GOAPGoal {
            name,
            priority,
            state: HashMap::new(),
        });
    }
    /// Add a desired world-state entry to the named goal; no-op if goal is not found.
    pub fn set_goal_state(&mut self, goal_name: &str, key: String, value: bool) {
        if let Some(g) = self.goals.iter_mut().find(|g| g.name == goal_name) {
            g.state.insert(key, value);
        }
    }
    /// Return the current A* iteration cap.
    pub fn get_max_iterations(&self) -> usize {
        self.max_iterations
    }
    /// Set the A* iteration cap to `n`.
    pub fn set_max_iterations(&mut self, n: usize) {
        self.max_iterations = n;
    }
}
/// `Default` delegates to `GOAPPlanner::new`.
impl Default for GOAPPlanner {
    /// `Default` delegates to `GOAPPlanner::new`.
    fn default() -> Self {
        Self::new()
    }
}
