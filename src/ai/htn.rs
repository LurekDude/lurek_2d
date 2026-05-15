//! - HTN planning model representing symbolic world state, tasks, methods, and the task registry.
//! - Primitive tasks mutating state directly and compound tasks expanding through methods.
//! - Recursive decomposition of a root task into a linear primitive plan with precondition checks.
//! - Float-threshold preconditions on world-state keys expressing partial satisfaction.
//! - Recursion depth cap at 128 levels preventing infinite expansion in cyclic task domains.

use std::collections::HashMap;
/// Symbolic world state keyed by string names.
pub type WorldState = HashMap<String, f32>;
/// Compound or primitive task in an HTN domain.
pub enum HTNTask {
    /// Compound task with a set of alternative methods.
    Compound {
        /// Task name.
        name: String,
        /// Methods that can decompose this task.
        methods: Vec<HTNMethod>,
    },
    /// Primitive task that directly changes world state.
    Primitive {
        /// Task name.
        name: String,
        /// Preconditions that must be satisfied.
        preconditions: Vec<String>,
        /// Effects that set keys to 1.0.
        effects: Vec<String>,
        /// Effects that set keys to 0.0.
        effects_clear: Vec<String>,
    },
}
impl HTNTask {
    /// Return the task name.
    pub fn name(&self) -> &str {
        match self {
            Self::Compound { name, .. } => name.as_str(),
            Self::Primitive { name, .. } => name.as_str(),
        }
    }
    /// Return `true` for primitive tasks.
    pub fn is_primitive(&self) -> bool {
        matches!(self, Self::Primitive { .. })
    }
    /// Return `true` when the task preconditions are satisfied.
    pub fn preconditions_met(&self, state: &WorldState) -> bool {
        match self {
            Self::Primitive { preconditions, .. } => preconditions
                .iter()
                .all(|k| state.get(k).copied().unwrap_or(0.0) >= 0.5),
            Self::Compound { .. } => true,
        }
    }
    /// Apply primitive effects to the world state.
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
/// One method that decomposes a compound task into subtasks.
pub struct HTNMethod {
    /// Method name.
    pub name: String,
    /// Preconditions that must be satisfied for the method to apply.
    pub preconditions: Vec<String>,
    /// Subtasks produced by the method.
    pub sub_tasks: Vec<String>,
}
impl HTNMethod {
    /// Create a method with no preconditions.
    pub fn always(name: &str, sub_tasks: Vec<&str>) -> Self {
        Self {
            name: name.to_string(),
            preconditions: Vec::new(),
            sub_tasks: sub_tasks.into_iter().map(|s| s.to_string()).collect(),
        }
    }
    /// Create a method with explicit preconditions.
    pub fn with_preconditions(name: &str, preconditions: Vec<&str>, sub_tasks: Vec<&str>) -> Self {
        Self {
            name: name.to_string(),
            preconditions: preconditions.into_iter().map(|s| s.to_string()).collect(),
            sub_tasks: sub_tasks.into_iter().map(|s| s.to_string()).collect(),
        }
    }
    /// Return `true` when the method preconditions are satisfied.
    pub fn is_applicable(&self, state: &WorldState) -> bool {
        self.preconditions
            .iter()
            .all(|k| state.get(k).copied().unwrap_or(0.0) >= 0.5)
    }
}
/// Task registry that stores the named HTN tasks available to planning.
#[derive(Default)]
pub struct HTNDomain {
    /// Registered tasks by name.
    tasks: HashMap<String, HTNTask>,
}
impl HTNDomain {
    /// Create an empty domain.
    pub fn new() -> Self {
        Self::default()
    }
    /// Register a task by its name.
    pub fn register(&mut self, task: HTNTask) {
        self.tasks.insert(task.name().to_string(), task);
    }
    /// Add a primitive task.
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
    /// Add a compound task.
    pub fn add_compound(&mut self, name: &str, methods: Vec<HTNMethod>) {
        self.register(HTNTask::Compound {
            name: name.to_string(),
            methods,
        });
    }
    /// Return a task by name.
    pub fn get(&self, name: &str) -> Option<&HTNTask> {
        self.tasks.get(name)
    }
    /// Return the number of tasks in the domain.
    pub fn task_count(&self) -> usize {
        self.tasks.len()
    }
}
/// HTN planner that expands a root task into a primitive task sequence.
pub struct HTNPlanner;
impl HTNPlanner {
    /// Plan from `root_task` and return a primitive task sequence, or `None` on failure.
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
    /// Recursively decompose a stack of tasks into primitives.
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
                None => return false,
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
                    let mut subtasks: Vec<String> = applicable.sub_tasks.clone();
                    subtasks.reverse();
                    stack.extend(subtasks);
                    return Self::decompose(domain, stack, state, plan, depth + 1);
                }
            }
        }
        true
    }
}
