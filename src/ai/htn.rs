//! hierarchical task network planner with recursive decomposition.
use std::collections::HashMap;

// World State

/// Snapshot of agent/world boolean and numeric state used during HTN planning.
pub type WorldState = HashMap<String, f32>;

// ---- Type: HTNTask ----

/// A hierarchical task - either a compound task (decomposable) or a primitive task (executable).
pub enum HTNTask {
    /// A compound task that must be decomposed via its methods.
    Compound {
        /// Unique name of this compound task.
        name: String,
        /// Ordered list of decomposition methods; first applicable method wins.
        methods: Vec<HTNMethod>,
    },
    /// A directly executable primitive task with optional state effects.
    Primitive {
        /// Unique name of this primitive task (returned in the plan output).
        name: String,
        /// World-state keys that must be `>= 0.5` to include this task.
        preconditions: Vec<String>,
        /// World-state keys set to `1.0` after executing this primitive.
        effects: Vec<String>,
        /// World-state keys set to `0.0` after executing this primitive.
        effects_clear: Vec<String>,
    },
}

impl HTNTask {
    /// Return the name of this task.
    pub fn name(&self) -> &str {
        match self {
            Self::Compound { name, .. } => name.as_str(),
            Self::Primitive { name, .. } => name.as_str(),
        }
    }

    /// Return `true` if this is a primitive task.
    pub fn is_primitive(&self) -> bool {
        matches!(self, Self::Primitive { .. })
    }

    /// Check whether a primitiv's preconditions are satisfied in the given state.
    pub fn preconditions_met(&self, state: &WorldState) -> bool {
        match self {
            Self::Primitive { preconditions, .. } => preconditions
                .iter()
                .all(|k| state.get(k).copied().unwrap_or(0.0) >= 0.5),
            Self::Compound { .. } => true,
        }
    }

    /// Applies this primitiv's effects to a mutable world-state clone.
    pub fn apply_effects(&self, state: &mut WorldState) {
        if let Self::Primitive {
            effects,
            effects_clear,
            ..
        } = self
        {
            for k in effects {
                state.insert(k.clone(), 1.0);
            }
            for k in effects_clear {
                state.insert(k.clone(), 0.0);
            }
        }
    }
}

// ---- Type: HTNMethod ----

/// One decomposition pathway for a compound task.
pub struct HTNMethod {
    /// Descriptive name for this method (used for debug/logging).
    pub name: String,
    /// World-state keys that must be `>= 0.5` for this method to trigger.
    pub preconditions: Vec<String>,
    /// Ordered task names to push onto the planning stack when this method applies.
    pub sub_tasks: Vec<String>,
}

impl HTNMethod {
    /// Create a method with no preconditions (always applicable).
    pub fn always(name: &str, sub_tasks: Vec<&str>) -> Self {
        Self {
            name: name.to_string(),
            preconditions: Vec::new(),
            sub_tasks: sub_tasks.into_iter().map(|s| s.to_string()).collect(),
        }
    }

    /// Create a method with preconditions.
    pub fn with_preconditions(name: &str, preconditions: Vec<&str>, sub_tasks: Vec<&str>) -> Self {
        Self {
            name: name.to_string(),
            preconditions: preconditions.into_iter().map(|s| s.to_string()).collect(),
            sub_tasks: sub_tasks.into_iter().map(|s| s.to_string()).collect(),
        }
    }

    /// Return `true` if this metho's preconditions are satisfied in `state`.
    pub fn is_applicable(&self, state: &WorldState) -> bool {
        self.preconditions
            .iter()
            .all(|k| state.get(k).copied().unwrap_or(0.0) >= 0.5)
    }
}

// ---- Type: HTNDomain ----

/// Registry of all HTN tasks for an agent archetype.
#[derive(Default)]
pub struct HTNDomain {
    tasks: HashMap<String, HTNTask>,
}

impl HTNDomain {
    /// Create an empty domain.
    pub fn new() -> Self {
        Self::default()
    }

    /// Registers an `HTNTask` in the domain. Overwrites any existing task with the same name.
    pub fn register(&mut self, task: HTNTask) {
        self.tasks.insert(task.name().to_string(), task);
    }

    /// Convenience: registers a primitive task with given preconditions and effects.
    pub fn add_primitive(
        &mut self,
        name: &str,
        preconditions: Vec<&str>,
        effects: Vec<&str>,
        effects_clear: Vec<&str>,
    ) {
        self.register(HTNTask::Primitive {
            name: name.to_string(),
            preconditions: preconditions.into_iter().map(|s| s.to_string()).collect(),
            effects: effects.into_iter().map(|s| s.to_string()).collect(),
            effects_clear: effects_clear.into_iter().map(|s| s.to_string()).collect(),
        });
    }

    /// Convenience: registers a compound task with a list of methods.
    pub fn add_compound(&mut self, name: &str, methods: Vec<HTNMethod>) {
        self.register(HTNTask::Compound {
            name: name.to_string(),
            methods,
        });
    }

    /// Looks up a task by name.
    pub fn get(&self, name: &str) -> Option<&HTNTask> {
        self.tasks.get(name)
    }

    /// Return the number of registered tasks.
    pub fn task_count(&self) -> usize {
        self.tasks.len()
    }
}

// ---- Type: HTNPlanner ----

/// Stateless HTN planner. Executes planning via recursive decomposition.
pub struct HTNPlanner;

impl HTNPlanner {
    /// Plans from `root_task` against `domain` and `initial_state`.
    pub fn plan(
        domain: &HTNDomain,
        root_task: &str,
        initial_state: &WorldState,
    ) -> Option<Vec<String>> {
        let mut plan = Vec::new();
        let mut state = initial_state.clone();
        let stack: Vec<String> = vec![root_task.to_string()];
        if Self::decompose(domain, stack, &mut state, &mut plan, 0) {
            Some(plan)
        } else {
            None
        }
    }

    /// Internal recursive decomposition. Returns `true` when the stack is fully resolved.
    fn decompose(
        domain: &HTNDomain,
        mut stack: Vec<String>,
        state: &mut WorldState,
        plan: &mut Vec<String>,
        depth: usize,
    ) -> bool {
        if depth > 128 {
            return false;
        }
        while let Some(task_name) = stack.last().cloned() {
            stack.pop();
            let task = match domain.get(&task_name) {
                Some(t) => t,
                None => return false, // Unknown task
            };

            match task {
                HTNTask::Primitive { .. } => {
                    if !task.preconditions_met(state) {
                        return false;
                    }
                    task.apply_effects(state);
                    plan.push(task.name().to_string());
                }
                HTNTask::Compound { methods, .. } => {
                    let applicable: &HTNMethod =
                        match methods.iter().find(|m| m.is_applicable(state)) {
                            Some(m) => m,
                            None => return false,
                        };
                    // Push sub-tasks in reverse so the stack pops them left-to-right
                    let mut subtasks: Vec<String> = applicable.sub_tasks.clone();
                    subtasks.reverse();
                    stack.extend(subtasks);
                    // Recurse for the remaining stack
                    return Self::decompose(domain, stack, state, plan, depth + 1);
                }
            }
        }
        true
    }
}

