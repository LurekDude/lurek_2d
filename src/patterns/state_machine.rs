use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct TransitionRule {
    pub from: String,
    pub to: String,
    pub label: String,
    pub has_guard: bool,
}
#[derive(Debug)]
pub struct StateMachine {
    pub current: String,
    pub previous: Option<String>,
    pub history_cap: usize,
    states: HashMap<String, StateInfo>,
    transitions: Vec<TransitionRule>,
    history: Vec<String>,
}
#[derive(Debug, Default)]
struct StateInfo {
    #[allow(dead_code)]
    has_enter: bool,
    #[allow(dead_code)]
    has_exit: bool,
    has_update: bool,
}
impl StateMachine {
    pub fn new(initial: &str) -> Self {
        let mut states = HashMap::new();
        states.insert(initial.to_string(), StateInfo::default());
        Self {
            current: initial.to_string(),
            previous: None,
            history_cap: 100,
            states,
            transitions: Vec::new(),
            history: vec![initial.to_string()],
        }
    }
    pub fn add_state(&mut self, name: &str, has_enter: bool, has_exit: bool, has_update: bool) {
        self.states.insert(
            name.to_string(),
            StateInfo {
                has_enter,
                has_exit,
                has_update,
            },
        );
    }
    pub fn has_state(&self, name: &str) -> bool {
        self.states.contains_key(name)
    }
    pub fn state_names(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.states.keys().map(String::as_str).collect();
        names.sort();
        names
    }
    pub fn add_transition(&mut self, from: &str, to: &str, label: &str, has_guard: bool) {
        self.transitions.push(TransitionRule {
            from: from.to_string(),
            to: to.to_string(),
            label: label.to_string(),
            has_guard,
        });
    }
    pub fn can_transition(&self, from: &str, to: &str) -> bool {
        self.transitions
            .iter()
            .any(|t| t.from == from && t.to == to)
            || self.transitions.is_empty()
    }
    pub fn get_transition<'a>(&'a self, from: &str, to: &str) -> Option<&'a TransitionRule> {
        self.transitions
            .iter()
            .find(|t| t.from == from && t.to == to)
    }
    pub fn transition_to(&mut self, to: &str) -> bool {
        if !self.can_transition(&self.current.clone(), to) {
            return false;
        }
        let prev = self.current.clone();
        self.current = to.to_string();
        self.previous = Some(prev.clone());
        self.states.entry(to.to_string()).or_default();
        self.history.push(to.to_string());
        if self.history.len() > self.history_cap {
            self.history.remove(0);
        }
        true
    }
    pub fn history(&self) -> &[String] {
        &self.history
    }
    pub fn reachable_from<'a>(&'a self, from: &str) -> Vec<&'a str> {
        self.transitions
            .iter()
            .filter(|t| t.from == from)
            .map(|t| t.to.as_str())
            .collect()
    }
    pub fn has_update_callback(&self, state: &str) -> bool {
        self.states
            .get(state)
            .map(|s| s.has_update)
            .unwrap_or(false)
    }
}
