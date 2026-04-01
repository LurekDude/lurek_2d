//! A★ planner over boolean world state for multi-step tactical planning.

use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};

use mlua::RegistryKey;

/// A single GOAP action with boolean preconditions and effects.
///
/// # Fields
/// - `name` — `String`.
/// - `cost` — `f64`.
/// - `callback` — `Option<RegistryKey>`.
/// - `preconditions` — `HashMap<String, bool>`.
/// - `effects` — `HashMap<String, bool>`.
pub struct GOAPAction {
    /// Action name.
    pub name: String,
    /// Cost of performing this action.
    pub cost: f64,
    /// Optional Lua callback executed when this action is performed.
    pub callback: Option<RegistryKey>,
    /// Boolean preconditions that must be true to execute.
    pub preconditions: HashMap<String, bool>,
    /// Boolean effects applied after execution.
    pub effects: HashMap<String, bool>,
}

/// A planning goal expressed as a target boolean world state.
///
/// # Fields
/// - `name` — `String`.
/// - `priority` — `f64`.
/// - `state` — `HashMap<String, bool>`.
pub struct GOAPGoal {
    /// Goal name.
    pub name: String,
    /// Priority (higher = preferred when planning).
    pub priority: f64,
    /// Target boolean world state.
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

/// A★ planner over boolean world state for multi-step tactical planning.
///
/// # Fields
/// - `actions` — `Vec<GOAPAction>`.
/// - `goals` — `Vec<GOAPGoal>`.
pub struct GOAPPlanner {
    /// Available actions.
    pub actions: Vec<GOAPAction>,
    /// Planning goals.
    pub goals: Vec<GOAPGoal>,
}

impl GOAPPlanner {
    /// Creates a new empty GOAP planner.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
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
}

impl Default for GOAPPlanner {
    fn default() -> Self {
        Self::new()
    }
}
