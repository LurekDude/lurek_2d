//! Finite State Machine with priority-ordered guarded transitions.

use std::collections::HashMap;

use mlua::RegistryKey;

/// Lua lifecycle hooks for a single FSM state.
///
/// # Fields
/// - `on_enter` — `Option<RegistryKey>`.
/// - `on_update` — `Option<RegistryKey>`.
/// - `on_exit` — `Option<RegistryKey>`.
pub struct StateCallbacks {
    /// Called once when entering this state.
    pub on_enter: Option<RegistryKey>,
    /// Called every frame while in this state.
    pub on_update: Option<RegistryKey>,
    /// Called once when leaving this state.
    pub on_exit: Option<RegistryKey>,
}

/// Guarded edge in the state graph.
///
/// # Fields
/// - `from` — `String`.
/// - `to` — `String`.
/// - `guard` — `Option<RegistryKey>`.
/// - `priority` — `i32`.
pub struct Transition {
    /// Source state name.
    pub from: String,
    /// Destination state name.
    pub to: String,
    /// Optional guard predicate: `fn(agent, dt) → bool`. None means always true.
    pub guard: Option<RegistryKey>,
    /// Priority for ordering (higher = checked first).
    pub priority: i32,
}

/// Finite State Machine with priority-ordered guarded transitions.
///
/// # Fields
/// - `states` — `HashMap<String, StateCallbacks>`.
/// - `transitions` — `Vec<Transition>`.
/// - `current_state` — `Option<String>`.
/// - `initial_state` — `Option<String>`.
/// - `time_in_state` — `f32`.
///
/// States have optional enter/update/exit Lua callbacks.
/// Transitions are checked in descending priority order each frame.
#[allow(dead_code)]
pub struct StateMachine {
    /// Named states with their lifecycle callbacks.
    pub(crate) states: HashMap<String, StateCallbacks>,
    /// All transitions, sorted descending by priority.
    pub(crate) transitions: Vec<Transition>,
    /// Currently active state, or None if not started.
    pub(crate) current_state: Option<String>,
    /// Initial state set via `setInitialState`.
    pub(crate) initial_state: Option<String>,
    /// Seconds spent in the current state.
    pub(crate) time_in_state: f32,
}

impl StateMachine {
    /// Creates a new empty state machine.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            states: HashMap::new(),
            transitions: Vec::new(),
            current_state: None,
            initial_state: None,
            time_in_state: 0.0,
        }
    }

    /// Adds a transition and re-sorts by descending priority.
    ///
    /// # Parameters
    /// - `transition` — `Transition`.
    pub fn add_transition(&mut self, transition: Transition) {
        self.transitions.push(transition);
        self.transitions.sort_by(|a, b| b.priority.cmp(&a.priority));
    }

    /// Returns the current state name, if any.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn current_state(&self) -> Option<&str> {
        self.current_state.as_deref()
    }

    /// Returns the time spent in the current state in seconds.
    ///
    /// # Returns
    /// `f32`.
    pub fn time_in_state(&self) -> f32 {
        self.time_in_state
    }
}

impl Default for StateMachine {
    fn default() -> Self {
        Self::new()
    }
}
