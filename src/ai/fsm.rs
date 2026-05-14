
//! - Defines the finite-state-machine data used by the AI module to store named
//!   states, callback hooks, transition rules, and current runtime state selection.
//! - Owns the callback bundles for state entry, update, and exit together with the
//!   transition records that route between states by priority and optional guards.
//! - Keeps the mutable machine state that tracks the current state, initial state,
//!   elapsed time in state, and raw registration helpers used by the Lua-facing layer.

use crate::log_msg;
use crate::runtime::log_messages::{FN01, FN02};
use mlua::RegistryKey;
use std::collections::HashMap;
/// Lua callback set attached to one FSM state.
pub struct StateCallbacks {
    /// Registry key of the Lua callback invoked when entering this state.
    pub on_enter: Option<RegistryKey>,
    /// Registry key of the Lua callback invoked each tick while in this state.
    pub on_update: Option<RegistryKey>,
    /// Registry key of the Lua callback invoked when leaving this state.
    pub on_exit: Option<RegistryKey>,
}
/// One transition rule between FSM states.
pub struct Transition {
    /// Source state name; `"*"` matches any state.
    pub from: String,
    /// Destination state name activated when the guard passes.
    pub to: String,
    /// Optional Lua guard predicate; `None` means the transition is unconditional.
    pub guard: Option<RegistryKey>,
    /// Evaluation order; higher priority transitions are tested first.
    pub priority: i32,
}
#[allow(dead_code)]
/// Finite-state-machine storage for states, transitions, and runtime selection.
pub struct StateMachine {
    /// Map from state name to its enter/update/exit callbacks.
    pub(crate) states: HashMap<String, StateCallbacks>,
    /// All registered transitions, sorted descending by priority.
    pub(crate) transitions: Vec<Transition>,
    /// Name of the currently active state; `None` before first tick.
    pub(crate) current_state: Option<String>,
    /// State name to activate on the first tick if none is active.
    pub(crate) initial_state: Option<String>,
    /// Elapsed time in seconds since the current state was entered.
    pub(crate) time_in_state: f32,
}
impl StateMachine {
    /// Create an empty state machine with no states or transitions.
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
    /// Register a transition and re-sort the transition list by descending priority.
    pub fn add_transition(&mut self, transition: Transition) {
        log_msg!(debug, FN02);
        self.transitions.push(transition);
        self.transitions.sort_by(|a, b| b.priority.cmp(&a.priority));
    }
    /// Return the name of the currently active state, or `None` before the first tick.
    pub fn current_state(&self) -> Option<&str> {
        self.current_state.as_deref()
    }
    /// Return elapsed seconds since the current state was entered.
    pub fn time_in_state(&self) -> f32 {
        self.time_in_state
    }
    /// Register a state by name with optional enter, update, and exit registry keys.
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
    /// Build a `Transition` from raw parts and add it via `add_transition`.
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
    /// Set the state name that will be activated on the first tick.
    pub fn set_initial_state(&mut self, name: String) {
        self.initial_state = Some(name);
    }
}
/// `Default` delegates to `StateMachine::new`.
impl Default for StateMachine {
    /// `Default` delegates to `StateMachine::new`.
    fn default() -> Self {
        Self::new()
    }
}
