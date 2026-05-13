//! Bridge animation state-machine transitions into Spine skeleton playback.

use std::collections::HashMap;

use super::state_machine::AnimStateMachine;
use crate::spine::skeleton::Skeleton;

// ---- Type: SpineAnimBridge ----

/// Bridge that couples an [`AnimStateMachine`] to a [`Skeleton`].
#[derive(Debug, Clone)]
pub struct SpineAnimBridge {
    skeleton: Skeleton,
    state_map: HashMap<String, String>,
    last_state: String,
    looping_states: HashMap<String, bool>,
}

impl SpineAnimBridge {
    // ---- Implementation: SpineAnimBridge ----
    /// Create a new bridge wrapping the given skeleton.
    pub fn new(skeleton: Skeleton) -> Self {
        Self {
            skeleton,
            state_map: HashMap::new(),
            last_state: String::new(),
            looping_states: HashMap::new(),
        }
    }

    /// Registers a mapping from an FSM state name to a skeleton animation clip name.
    pub fn map(&mut self, fsm_state: &str, skeleton_clip: &str) {
        self.state_map
            .insert(fsm_state.to_string(), skeleton_clip.to_string());
    }

    /// Registers a mapping with an explicit looping flag.
    pub fn map_looping(&mut self, fsm_state: &str, skeleton_clip: &str, looping: bool) {
        self.state_map
            .insert(fsm_state.to_string(), skeleton_clip.to_string());
        self.looping_states.insert(fsm_state.to_string(), looping);
    }

    /// Advances the FSM by `dt`, reacts to state changes, and updates the skeleton.
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

    /// Return an immutable reference to the owned skeleton.
    pub fn skeleton(&self) -> &Skeleton {
        &self.skeleton
    }

    /// Return a mutable reference to the owned skeleton.
    pub fn skeleton_mut(&mut self) -> &mut Skeleton {
        &mut self.skeleton
    }

    /// Return the FSM state name that was most recently applied to the skeleton.
    pub fn last_applied_state(&self) -> &str {
        &self.last_state
    }

    /// Return the skeleton clip name mapped for `fsm_state`, or `None` if no mapping exists.
    pub fn get_mapped_clip(&self, fsm_state: &str) -> Option<&str> {
        self.state_map.get(fsm_state).map(String::as_str)
    }
}
