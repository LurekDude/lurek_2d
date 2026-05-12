//! Bridge between [`AnimStateMachine`] and a Spine [`Skeleton`].
//!
//! # Responsibility
//!
//! `SpineAnimBridge` translates FSM state-change events into skeleton animation
//! commands.  It owns the [`Skeleton`] and is updated alongside the state machine
//! every frame.
//!
//! # Ownership boundary
//!
//! - The FSM controls *when* to switch animations and *what parameter values mean*.
//! - The bridge controls *which skeleton animation clip* maps to a given FSM state.
//! - The skeleton controls *how* the clip is applied to bones and world transforms.
//!
//! This separation lets game code share one FSM-parameter system (speed, grounded,
//! attacking …) and drive both the sprite animation and the skeletal rig with the
//! same conditions.
//!
//! # Typical usage
//!
//! ```
//! // Rust side:
//! let mut bridge = SpineAnimBridge::new(skeleton);
//! bridge.map("idle", "skeleton_idle");      // FSM state → skeleton clip name
//! bridge.map("walk", "skeleton_walk");
//!
//! // each frame:
//! bridge.update(dt, &mut state_machine);
//! let slots = bridge.skeleton().slots();    // use slots for rendering
//! ```

use std::collections::HashMap;

use super::state_machine::AnimStateMachine;
use crate::spine::skeleton::Skeleton;

/// Bridge that couples an [`AnimStateMachine`] to a [`Skeleton`].
///
/// When the FSM transitions to a new state the bridge fires `play_animation` on
/// the skeleton for the mapped clip name, then calls `update_animation` and
/// `update_world_transforms` each tick.
///
/// # Fields
/// - `skeleton` — [`Skeleton`]. Owned skeletal rig.
/// - `state_map` — `HashMap<String, String>`. FSM state name → skeleton clip name.
/// - `last_state` — `String`. FSM state observed at the end of the previous tick.
/// - `looping_states` — `HashMap<String, bool>`. Per-state looping override; defaults to `true`.
#[derive(Debug, Clone)]
pub struct SpineAnimBridge {
    skeleton: Skeleton,
    state_map: HashMap<String, String>,
    last_state: String,
    looping_states: HashMap<String, bool>,
}

impl SpineAnimBridge {
    /// Creates a new bridge wrapping the given skeleton.
    ///
    /// No state mappings are registered yet; call [`map`](Self::map) for each
    /// FSM state that should drive a skeleton clip.
    ///
    /// # Parameters
    /// - `skeleton` — [`Skeleton`].
    ///
    /// # Returns
    /// `Self`.
    pub fn new(skeleton: Skeleton) -> Self {
        Self {
            skeleton,
            state_map: HashMap::new(),
            last_state: String::new(),
            looping_states: HashMap::new(),
        }
    }

    /// Registers a mapping from an FSM state name to a skeleton animation clip name.
    ///
    /// # Parameters
    /// - `fsm_state` — `&str`. FSM state name (must match a state registered with [`AnimStateMachine::add_state`]).
    /// - `skeleton_clip` — `&str`. Clip name registered in the skeleton (must match a [`SkeletonAnimation::name`]).
    pub fn map(&mut self, fsm_state: &str, skeleton_clip: &str) {
        self.state_map
            .insert(fsm_state.to_string(), skeleton_clip.to_string());
    }

    /// Registers a mapping with an explicit looping flag.
    ///
    /// # Parameters
    /// - `fsm_state` — `&str`. FSM state name.
    /// - `skeleton_clip` — `&str`. Clip name in the skeleton.
    /// - `looping` — `bool`. Whether the clip loops.
    pub fn map_looping(&mut self, fsm_state: &str, skeleton_clip: &str, looping: bool) {
        self.state_map
            .insert(fsm_state.to_string(), skeleton_clip.to_string());
        self.looping_states.insert(fsm_state.to_string(), looping);
    }

    /// Advances the FSM by `dt`, reacts to state changes, and updates the skeleton.
    ///
    /// Call this once per frame in place of calling `AnimStateMachine::update` directly.
    ///
    /// # Parameters
    /// - `dt` — `f32`. Delta time in seconds.
    /// - `fsm` — `&mut AnimStateMachine`. The state machine to drive.
    pub fn update(&mut self, dt: f32, fsm: &mut AnimStateMachine) {
        let state_before = fsm.get_state().to_string();
        fsm.update(dt);
        let state_after = fsm.get_state().to_string();

        // If FSM transitioned (or this is the first tick), apply the new skeleton clip.
        if state_after != self.last_state {
            self.last_state = state_after.clone();
            if let Some(clip) = self.state_map.get(&state_after) {
                let looping = self
                    .looping_states
                    .get(&state_after)
                    .copied()
                    .unwrap_or(true);
                let _ = self.skeleton.play_animation(clip, looping);
            }
        }

        // Suppress unused-variable warning when the state was the same.
        let _ = state_before;

        // Advance the skeleton independently of the FSM's own animation controller.
        self.skeleton.update_animation(dt);
        self.skeleton.update_world_transforms();
    }

    /// Returns an immutable reference to the owned skeleton.
    ///
    /// # Returns
    /// `&Skeleton`.
    pub fn skeleton(&self) -> &Skeleton {
        &self.skeleton
    }

    /// Returns a mutable reference to the owned skeleton.
    ///
    /// # Returns
    /// `&mut Skeleton`.
    pub fn skeleton_mut(&mut self) -> &mut Skeleton {
        &mut self.skeleton
    }

    /// Returns the FSM state name that was most recently applied to the skeleton.
    ///
    /// Returns an empty string before the first [`update`](Self::update) call.
    ///
    /// # Returns
    /// `&str`.
    pub fn last_applied_state(&self) -> &str {
        &self.last_state
    }

    /// Returns the skeleton clip name mapped for `fsm_state`, or `None` if no mapping exists.
    ///
    /// # Parameters
    /// - `fsm_state` — `&str`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_mapped_clip(&self, fsm_state: &str) -> Option<&str> {
        self.state_map.get(fsm_state).map(String::as_str)
    }
}
