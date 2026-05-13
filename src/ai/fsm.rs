//! finite-state machine runtime for named state transitions.
use std::collections::HashMap;

use crate::log_msg;
use crate::runtime::log_messages::{FN01, FN02};
use mlua::RegistryKey;

/// Lua lifecycle hooks for a single FSM state.
pub struct StateCallbacks {
    /// Called once when the FSM transitions into this state. Signature: `fn(agent)`.
    pub on_enter: Option<RegistryKey>,
    /// Called every frame while this state is active. Signature: `fn(agent, dt)`.
    pub on_update: Option<RegistryKey>,
    /// Called once when the FSM transitions out of this state. Signature: `fn(agent)`.
    pub on_exit: Option<RegistryKey>,
}

/// A directed edge in the FSM state graph with an optional guard predicate.
pub struct Transition {
    /// Name of the source state this transition leaves from.
    pub from: String,
    /// Name of the destination state this transition goes to.
    pub to: String,
    /// Optional guard predicate: `fn(agent, dt) -> bool`.
    pub guard: Option<RegistryKey>,
    /// Priority for evaluation ordering. Higher values are checked first.
    pub priority: i32,
}

/// A finite state machine that manages named states with lifecycle callbacks (enter/update/exit) and guarded transitions.
#[allow(dead_code)]
pub struct StateMachine {
    /// Named states with their lifecycle callbacks (enter/update/exit).
    pub(crate) states: HashMap<String, StateCallbacks>,
    /// All transitions, maintained sorted by descending priority so the first match is the highest-priority eligible transition.
    pub(crate) transitions: Vec<Transition>,
    /// The currently active state name, or `None` if the machine hasn't started yet.
    pub(crate) current_state: Option<String>,
    /// The initial state assigned via `setInitialState`. The machine transitions here on its first update call.
    pub(crate) initial_state: Option<String>,
    /// Accumulated time (in seconds) spent in the current state. Resets to `0.0` on every state transition.
    pub(crate) time_in_state: f32,
}

impl StateMachine {
    /// Create a new empty state machine.
    pub fn new() -> Self {
        log_msg!(debug, FN01);
        Self {
            states: HashMap::new(),
            transitions: Vec::new(),
            current_state: None,
            initial_state: None,
            time_in_state: 0.0,
        }
    }

    /// Add a transition and re-sorts by descending priority.
    pub fn add_transition(&mut self, transition: Transition) {
        log_msg!(debug, FN02);
        self.transitions.push(transition);
        self.transitions.sort_by(|a, b| b.priority.cmp(&a.priority));
    }

    /// Return the current state name, if any.
    pub fn current_state(&self) -> Option<&str> {
        self.current_state.as_deref()
    }

    /// Return the time spent in the current state in seconds.
    pub fn time_in_state(&self) -> f32 {
        self.time_in_state
    }

    /// Add a named state with optional lifecycle callbacks. Used by the Lua API.
    pub fn add_state_raw(
        &mut self,
        name: String,
        on_enter: Option<RegistryKey>,
        on_update: Option<RegistryKey>,
        on_exit: Option<RegistryKey>,
    ) {
        self.states.insert(
            name,
            StateCallbacks {
                on_enter,
                on_update,
                on_exit,
            },
        );
    }

    /// Add a transition with optional guard callback. Used by the Lua API.
    pub fn add_transition_raw(
        &mut self,
        from: String,
        to: String,
        priority: i32,
        guard: Option<RegistryKey>,
    ) {
        self.add_transition(Transition {
            from,
            to,
            guard,
            priority,
        });
    }

    /// Set the initial state name. The machine transitions here on its first update.
    pub fn set_initial_state(&mut self, name: String) {
        self.initial_state = Some(name);
    }
}

impl Default for StateMachine {
    fn default() -> Self {
        Self::new()
    }
}
