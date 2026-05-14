
use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct TransitionRule {
    /// Source state name.
    pub from: String,
    /// Destination state name.
    pub to: String,
    /// Caller-assigned label for this transition.
    pub label: String,
    /// When true, caller must evaluate a guard before calling `transition_to`.
    pub has_guard: bool,
}
/// Finite state machine with explicit states, guarded transitions, and bounded history.
#[derive(Debug)]
pub struct StateMachine {
    /// Currently active state name.
    pub current: String,
    /// State active before the last transition.
    pub previous: Option<String>,
    /// Maximum entries kept in the history ring.
    pub history_cap: usize,
    /// All declared states.
    states: HashMap<String, StateInfo>,
    /// Allowed transitions; when empty, all transitions are permitted.
    transitions: Vec<TransitionRule>,
    /// Ordered log of visited states, capped at `history_cap`.
    history: Vec<String>,
}
/// Metadata about enter/exit/update callbacks registered for a state.
#[derive(Debug, Default)]
struct StateInfo {
    /// When true, caller has registered an enter callback for this state.
    #[allow(dead_code)]
    has_enter: bool,
    /// When true, caller has registered an exit callback.
    #[allow(dead_code)]
    has_exit: bool,
    /// When true, caller has registered an update callback.
    has_update: bool,
}
/// All methods for `StateMachine`.
impl StateMachine {
    /// Create a state machine with a single `initial` state as current.
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
    /// Declare a state with callback presence flags.
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
    /// Return true when `name` is a declared state.
    pub fn has_state(&self, name: &str) -> bool {
        self.states.contains_key(name)
    }
    /// Return all declared state names in sorted order.
    pub fn state_names(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.states.keys().map(String::as_str).collect();
        names.sort();
        names
    }
    /// Register a labeled transition from `from` to `to` with an optional guard flag.
    pub fn add_transition(&mut self, from: &str, to: &str, label: &str, has_guard: bool) {
        self.transitions.push(TransitionRule {
            from: from.to_string(),
            to: to.to_string(),
            label: label.to_string(),
            has_guard,
        });
    }
    /// Return true when the transition list allows going from `from` to `to`, or when the list is empty.
    pub fn can_transition(&self, from: &str, to: &str) -> bool {
        self.transitions
            .iter()
            .any(|t| t.from == from && t.to == to)
            || self.transitions.is_empty()
    }
    /// Return the first matching transition rule from `from` to `to`, or `None`.
    pub fn get_transition<'a>(&'a self, from: &str, to: &str) -> Option<&'a TransitionRule> {
        self.transitions
            .iter()
            .find(|t| t.from == from && t.to == to)
    }
    /// Transition to `to` if allowed; update history and `previous`; return false when blocked.
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
    /// Return the bounded history of visited states in chronological order.
    pub fn history(&self) -> &[String] {
        &self.history
    }
    /// Return all states reachable directly from `from` by a registered transition.
    pub fn reachable_from<'a>(&'a self, from: &str) -> Vec<&'a str> {
        self.transitions
            .iter()
            .filter(|t| t.from == from)
            .map(|t| t.to.as_str())
            .collect()
    }
    /// Return true when `state` has a registered update callback.
    pub fn has_update_callback(&self, state: &str) -> bool {
        self.states
            .get(state)
            .map(|s| s.has_update)
            .unwrap_or(false)
    }
}
