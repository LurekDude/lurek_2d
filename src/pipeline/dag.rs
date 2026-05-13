use crate::log_msg;
use crate::pipeline::result::{PipelineResult, PipelineStatus};
use crate::pipeline::step::{PipelineStep, StepStatus};
use crate::runtime::log_messages::{PL01_PIPELINE_INIT, PL02_STEP_ADD};
use std::collections::{HashMap, HashSet, VecDeque};
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ErrorMode {
    Abort,
    Continue,
}
impl ErrorMode {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Abort => "abort",
            Self::Continue => "continue",
        }
    }
    pub fn from_str_lua(s: &str) -> Result<Self, String> {
        match s {
            "abort" => Ok(Self::Abort),
            "continue" => Ok(Self::Continue),
            _ => Err(format!(
                "setErrorMode: unknown mode '{}', expected 'abort' or 'continue'",
                s
            )),
        }
    }
}
#[derive(Debug, Clone)]
pub struct Pipeline {
    pub name: String,
    steps: HashMap<String, PipelineStep>,
    pub error_mode: ErrorMode,
}
impl Pipeline {
    pub fn new(name: impl Into<String>) -> Self {
        log_msg!(debug, PL01_PIPELINE_INIT);
        Self {
            name: name.into(),
            steps: HashMap::new(),
            error_mode: ErrorMode::Abort,
        }
    }
    pub fn add_step(&mut self, step: PipelineStep) -> Result<(), String> {
        if self.steps.contains_key(&step.name) {
            return Err(format!(
                "step '{}' already exists in pipeline '{}'",
                step.name, self.name
            ));
        }
        self.steps.insert(step.name.clone(), step);
        log_msg!(debug, PL02_STEP_ADD);
        Ok(())
    }
    pub fn remove_step(&mut self, name: &str) -> bool {
        if self.steps.remove(name).is_none() {
            return false;
        }
        for step in self.steps.values_mut() {
            step.deps.retain(|d| d != name);
        }
        true
    }
    pub fn get_step(&self, name: &str) -> Option<&PipelineStep> {
        self.steps.get(name)
    }
    pub fn get_step_mut(&mut self, name: &str) -> Option<&mut PipelineStep> {
        self.steps.get_mut(name)
    }
    pub fn get_steps(&self) -> impl Iterator<Item = &PipelineStep> {
        self.steps.values()
    }
    pub fn get_step_count(&self) -> usize {
        self.steps.len()
    }
    pub fn clear(&mut self) {
        self.steps.clear();
    }
    pub fn validate(&self) -> (bool, Vec<String>) {
        let mut errors: Vec<String> = Vec::new();
        for step in self.steps.values() {
            for dep in &step.deps {
                if !self.steps.contains_key(dep.as_str()) {
                    errors.push(format!(
                        "step '{}' depends on '{}' which does not exist",
                        step.name, dep
                    ));
                }
            }
        }
        if errors.is_empty() {
            if let Err(cycle_msg) = self.get_execution_order() {
                errors.push(cycle_msg);
            }
        }
        let is_valid = errors.is_empty();
        (is_valid, errors)
    }
    pub fn get_execution_order(&self) -> Result<Vec<String>, String> {
        let order_refs = self.get_execution_order_refs()?;
        Ok(order_refs.into_iter().map(str::to_owned).collect())
    }
    fn get_execution_order_refs(&self) -> Result<Vec<&str>, String> {
        let mut in_degree: HashMap<&str, usize> = HashMap::new();
        let mut dependents: HashMap<&str, Vec<&str>> = HashMap::new();
        for name in self.steps.keys() {
            in_degree.entry(name.as_str()).or_insert(0);
            dependents.entry(name.as_str()).or_default();
        }
        for step in self.steps.values() {
            for dep in &step.deps {
                if self.steps.contains_key(dep.as_str()) {
                    *in_degree.entry(step.name.as_str()).or_insert(0) += 1;
                    dependents
                        .entry(dep.as_str())
                        .or_default()
                        .push(step.name.as_str());
                }
            }
        }
        let mut queue: VecDeque<&str> = in_degree
            .iter()
            .filter(|(_, &deg)| deg == 0)
            .map(|(&name, _)| name)
            .collect();
        let mut order: Vec<&str> = Vec::with_capacity(self.steps.len());
        while let Some(current) = queue.pop_front() {
            order.push(current);
            if let Some(deps_of) = dependents.get(current) {
                for &dependent in deps_of {
                    let deg = in_degree
                        .get_mut(dependent)
                        .unwrap_or_else(|| unreachable!("dependent key missing from in_degree"));
                    *deg -= 1;
                    if *deg == 0 {
                        queue.push_back(dependent);
                    }
                }
            }
        }
        if order.len() < self.steps.len() {
            let remaining: Vec<&str> = in_degree
                .iter()
                .filter(|(_, &deg)| deg > 0)
                .map(|(&name, _)| name)
                .collect();
            return Err(format!(
                "cycle detected involving: {}",
                remaining.join(", ")
            ));
        }
        Ok(order)
    }
    pub fn get_parallel_groups(&self) -> Result<Vec<Vec<String>>, String> {
        let topo = self.get_execution_order_refs()?;
        let mut levels: HashMap<&str, usize> = HashMap::new();
        for name in &topo {
            let step = self
                .steps
                .get(*name)
                .unwrap_or_else(|| unreachable!("step name from topo order not found in steps"));
            let level = step
                .deps
                .iter()
                .filter(|dep| self.steps.contains_key(dep.as_str()))
                .map(|dep| levels.get(dep.as_str()).copied().unwrap_or(0) + 1)
                .max()
                .unwrap_or(0);
            levels.insert(*name, level);
        }
        let max_level = levels.values().copied().max().unwrap_or(0);
        let mut groups: Vec<Vec<String>> = vec![Vec::new(); max_level + 1];
        for (name, &level) in &levels {
            groups[level].push((*name).to_owned());
        }
        let topo_index: HashMap<&str, usize> =
            topo.iter().enumerate().map(|(i, n)| (*n, i)).collect();
        for group in &mut groups {
            group.sort_by_key(|n| topo_index.get(n.as_str()).copied().unwrap_or(0));
        }
        groups.retain(|g| !g.is_empty());
        Ok(groups)
    }
    pub fn reset(&mut self) {
        for step in self.steps.values_mut() {
            step.reset();
        }
    }
    pub fn are_deps_satisfied(
        &self,
        step_name: &str,
        statuses: &HashMap<String, StepStatus>,
    ) -> Result<bool, String> {
        let step = match self.get_step(step_name) {
            Some(s) => s,
            None => return Err(format!("step '{}' not found", step_name)),
        };
        for dep_name in &step.deps {
            let dep_status = match statuses.get(dep_name) {
                Some(s) => s.clone(),
                None => return Ok(false),
            };
            match dep_status {
                StepStatus::Completed => {}
                StepStatus::Skipped | StepStatus::Failed => {
                    let is_optional = self.get_step(dep_name).map(|s| s.optional).unwrap_or(false);
                    if !is_optional {
                        return Ok(false);
                    }
                }
                _ => {
                    return Err(format!(
                        "dep '{}' of '{}' is still in state {:?}",
                        dep_name, step_name, dep_status
                    ));
                }
            }
        }
        Ok(true)
    }
    pub fn collect_result(
        &self,
        step_statuses: &HashMap<String, (StepStatus, Option<String>)>,
        duration: f32,
    ) -> PipelineResult {
        let mut result = PipelineResult::new();
        result.total_duration = duration;
        for (name, (status, error_msg)) in step_statuses {
            match status {
                StepStatus::Completed => result.completed.push(name.clone()),
                StepStatus::Failed => {
                    result.failed.push(name.clone());
                    if let Some(msg) = error_msg {
                        result.errors.push((name.clone(), msg.clone()));
                    }
                }
                StepStatus::Skipped => result.skipped.push(name.clone()),
                StepStatus::Cancelled => result.cancelled.push(name.clone()),
                _ => {}
            }
        }
        result.status = if result.failed.is_empty() {
            PipelineStatus::Completed
        } else {
            PipelineStatus::Failed
        };
        result
    }
    pub fn to_ascii_diagram(&self) -> String {
        let mut lines = Vec::new();
        lines.push(format!("Pipeline: \"{}\"", self.name));
        match self.get_parallel_groups() {
            Ok(groups) => {
                for (level, group) in groups.iter().enumerate() {
                    let slots: Vec<String> = group
                        .iter()
                        .map(|n| {
                            let deps = self
                                .steps
                                .get(n)
                                .map(|s| s.deps.join(","))
                                .unwrap_or_default();
                            if deps.is_empty() {
                                format!("[{}]", n)
                            } else {
                                format!("[{} <-- {}]", n, deps)
                            }
                        })
                        .collect();
                    lines.push(format!("  L{}: {}", level, slots.join(" || ")));
                }
                if groups.is_empty() {
                    lines.push("  (empty pipeline)".to_string());
                }
            }
            Err(e) => lines.push(format!("  (cycle detected: {})", e)),
        }
        lines.join("\n")
    }
    pub fn add_sub_pipeline(
        &mut self,
        sub: Pipeline,
        alias: &str,
        outer_deps: Vec<String>,
    ) -> Result<(), String> {
        for dep in &outer_deps {
            if !self.steps.contains_key(dep.as_str()) {
                return Err(format!(
                    "add_sub_pipeline: outer dependency '{}' does not exist in pipeline '{}'",
                    dep, self.name
                ));
            }
        }
        let sub_entry_points: HashSet<String> = sub
            .steps
            .values()
            .filter(|s| s.deps.is_empty())
            .map(|s| s.name.clone())
            .collect();
        for mut step in sub.steps.into_values() {
            let prefixed_name = format!("{}/{}", alias, step.name);
            step.deps = step
                .deps
                .into_iter()
                .map(|d| format!("{}/{}", alias, d))
                .collect();
            if sub_entry_points.contains(&step.name) {
                step.deps.extend(outer_deps.clone());
            }
            step.name = prefixed_name;
            self.add_step(step)?;
        }
        Ok(())
    }
    #[allow(dead_code)]
    fn dependents_of(&self, root: &str) -> HashSet<String> {
        let mut result = HashSet::new();
        for step in self.steps.values() {
            if step.deps.iter().any(|d| d == root) {
                result.insert(step.name.clone());
            }
        }
        result
    }
}
