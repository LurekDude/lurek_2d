//! Finite State Machine with priority-ordered guarded transitions.
//!
//! The FSM is a classic game AI pattern: the agent is in exactly one named state
//! at a time. Each state has optional Lua lifecycle callbacks (`on_enter`,
//! `on_update`, `on_exit`). Transitions between states are guarded by optional
//! Lua predicates and ordered by descending priority.
//!
//! ## Update Cycle
//!
//! During each `AIWorld::update(dt)` tick for an agent with `DecisionModel::Fsm`:
//!
//! 1. All transitions from the current state are checked in descending priority
//!    order. The first transition whose guard returns `true` (or has no guard)
//!    fires.
//! 2. If a transition fires: the current state's `on_exit` is called, the
//!    current state switches, `time_in_state` resets to 0, and the new state's
//!    `on_enter` is called.
//! 3. The current state's `on_update(dt)` is called.
//!
//! ## Priority Ordering
//!
//! Transitions are stored sorted by descending priority. When multiple transitions
//! from the same source state could fire, the highest-priority one wins. This
//! allows "panic" transitions (e.g., health < 10% → flee) to override normal
//! patrol logic without complex guard nesting.

use std::collections::HashMap;

use crate::engine::log_messages::{FN01, FN02};
use crate::log_msg;
use mlua::RegistryKey;

/// Lua lifecycle hooks for a single FSM state.
///
/// Each state can have up to three callbacks, all optional. The AIWorld calls
/// them at the appropriate lifecycle moments:
/// - `on_enter` — called once when transitioning into this state.
/// - `on_update` — called every frame while this state is active.
/// - `on_exit` — called once when transitioning out of this state.
///
/// Not all states need all callbacks. A "dead" state might only have `on_enter`
/// (to play a death animation) and no `on_update` or `on_exit`.
///
/// # Fields
/// - `on_enter` — `Option<RegistryKey>`.
/// - `on_update` — `Option<RegistryKey>`.
/// - `on_exit` — `Option<RegistryKey>`.
pub struct StateCallbacks {
    /// Called once when the FSM transitions into this state. Signature: `fn(agent)`.
    pub on_enter: Option<RegistryKey>,
    /// Called every frame while this state is active. Signature: `fn(agent, dt)`.
    pub on_update: Option<RegistryKey>,
    /// Called once when the FSM transitions out of this state. Signature: `fn(agent)`.
    pub on_exit: Option<RegistryKey>,
}

/// A directed edge in the FSM state graph with an optional guard predicate.
///
/// Transitions are stored in the [`StateMachine`] and sorted by descending
/// priority. During each update, the machine checks all transitions leaving
/// the current state. The first one whose guard passes (or has no guard)
/// triggers a state change.
///
/// # Fields
/// - `from` — `String`.
/// - `to` — `String`.
/// - `guard` — `Option<RegistryKey>`.
/// - `priority` — `i32`.
pub struct Transition {
    /// Name of the source state this transition leaves from.
    pub from: String,
    /// Name of the destination state this transition goes to.
    pub to: String,
    /// Optional guard predicate: `fn(agent, dt) → bool`.
    /// If `None`, the transition is always allowed (unconditional).
    pub guard: Option<RegistryKey>,
    /// Priority for evaluation ordering. Higher values are checked first.
    /// Use high priorities for emergency transitions (e.g., flee on low health)
    /// that should override normal patrol/idle logic.
    pub priority: i32,
}

/// A finite state machine that manages named states with lifecycle callbacks
/// and priority-ordered guarded transitions.
///
/// The machine is in exactly one state at a time (or `None` before the first
/// transition fires). States are identified by string names and associated with
/// [`StateCallbacks`] for enter/update/exit lifecycle hooks.
///
/// Transitions are sorted by descending priority and evaluated each frame.
/// The first passing guard triggers a state change. This priority-based design
/// allows high-priority "panic" transitions to override normal behavior without
/// complex conditional logic in individual state callbacks.
///
/// `time_in_state` tracks how long the machine has been in the current state,
/// which is useful for time-based guards (e.g., "switch to patrol after 5s idle").
///
/// # Fields
/// - `states` — `HashMap<String, StateCallbacks>`.
/// - `transitions` — `Vec<Transition>`.
/// - `current_state` — `Option<String>`.
/// - `initial_state` — `Option<String>`.
/// - `time_in_state` — `f32`.
#[allow(dead_code)]
pub struct StateMachine {
    /// Named states with their lifecycle callbacks (enter/update/exit).
    pub(crate) states: HashMap<String, StateCallbacks>,
    /// All transitions, maintained sorted by descending priority so the
    /// first matching guard wins during evaluation.
    pub(crate) transitions: Vec<Transition>,
    /// The currently active state name, or `None` if the machine hasn't started yet.
    pub(crate) current_state: Option<String>,
    /// The initial state assigned via `setInitialState`. The machine transitions
    /// to this state on its first update if `current_state` is `None`.
    pub(crate) initial_state: Option<String>,
    /// Accumulated time (in seconds) spent in the current state. Resets to 0
    /// on every state transition.
    pub(crate) time_in_state: f32,
}

impl StateMachine {
    /// Creates a new empty state machine. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
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

    /// Adds a transition and re-sorts by descending priority.
    ///
    /// # Parameters
    /// - `transition` — `Transition`.
    pub fn add_transition(&mut self, transition: Transition) {
        log_msg!(debug, FN02);
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

    /// Adds a named state with optional lifecycle callbacks. Used by the Lua API.
    ///
    /// # Parameters
    /// - `name` — `String`.
    /// - `on_enter` — `Option<RegistryKey>`.
    /// - `on_update` — `Option<RegistryKey>`.
    /// - `on_exit` — `Option<RegistryKey>`.
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

    /// Adds a transition with optional guard callback. Used by the Lua API.
    ///
    /// # Parameters
    /// - `from` — `String`.
    /// - `to` — `String`.
    /// - `priority` — `i32`.
    /// - `guard` — `Option<RegistryKey>`.
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

    /// Sets the initial state name. The machine transitions here on its first update.
    ///
    /// # Parameters
    /// - `name` — `String`.
    pub fn set_initial_state(&mut self, name: String) {
        self.initial_state = Some(name);
    }
}

impl Default for StateMachine {
    fn default() -> Self {
        Self::new()
    }
}
