
use super::state_machine::AnimStateMachine;
use crate::spine::skeleton::Skeleton;
use std::collections::HashMap;
/// Maps FSM state names to Spine animation clips.
#[derive(Debug, Clone)]
pub struct SpineAnimBridge {
    /// Owned skeleton instance.
    skeleton: Skeleton,
    /// Mapping from FSM state to skeleton clip.
    state_map: HashMap<String, String>,
    /// Last applied FSM state.
    last_state: String,
    /// Looping override per mapped state.
    looping_states: HashMap<String, bool>,
}
impl SpineAnimBridge {
    /// Create a bridge for a skeleton.
    pub fn new(skeleton: Skeleton) -> Self {
        Self {
            skeleton,
            state_map: HashMap::new(),
            last_state: String::new(),
            looping_states: HashMap::new(),
        }
    }
    /// Map a FSM state to a skeleton clip.
    pub fn map(&mut self, fsm_state: &str, skeleton_clip: &str) {
        self.state_map
            .insert(fsm_state.to_string(), skeleton_clip.to_string());
    }
    /// Map a FSM state to a skeleton clip and set its looping override.
    pub fn map_looping(&mut self, fsm_state: &str, skeleton_clip: &str, looping: bool) {
        self.state_map
            .insert(fsm_state.to_string(), skeleton_clip.to_string());
        self.looping_states.insert(fsm_state.to_string(), looping);
    }
    /// Advance the FSM and play the mapped Spine animation when the state changes.
    pub fn update(&mut self, dt: f32, fsm: &mut AnimStateMachine) {
        let state_before = fsm.get_state().to_string();
        fsm.update(dt);
        let state_after = fsm.get_state().to_string();
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
        let _ = state_before;
        self.skeleton.update_animation(dt);
        self.skeleton.update_world_transforms();
    }
    /// Return the current skeleton.
    pub fn skeleton(&self) -> &Skeleton {
        &self.skeleton
    }
    /// Return the skeleton mutably.
    pub fn skeleton_mut(&mut self) -> &mut Skeleton {
        &mut self.skeleton
    }
    /// Return the last applied FSM state.
    pub fn last_applied_state(&self) -> &str {
        &self.last_state
    }
    /// Return the mapped clip for a FSM state.
    pub fn get_mapped_clip(&self, fsm_state: &str) -> Option<&str> {
        self.state_map.get(fsm_state).map(String::as_str)
    }
}
