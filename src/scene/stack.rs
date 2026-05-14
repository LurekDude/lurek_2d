//! SceneStack and SceneId: push/pop/switch lifecycle for game scenes with queued transitions.
//! Owns stack state, scene registry, overlay set, scene-layer ordering, and per-scene data keys.
//! Does not own transition math or render commands — those live in transition.rs and render.rs.
//! Key dependencies: ActiveTransition, EasingType, TransitionType from transition.rs.

use crate::log_msg;
use crate::runtime::log_messages::{
    SC01_STACK_INIT, SC02_SCENE_PUSH, SC03_SCENE_POP, SC04_STACK_CLEAR,
};
use crate::scene::transition::{ActiveTransition, EasingType, TransitionType};
use std::collections::{HashMap, HashSet, VecDeque};
/// Unique identifier for a scene; assigned by SceneStack::next_scene_id.
pub type SceneId = u64;

/// Stack-based scene manager with push/pop/switch, overlay support, transition queuing, and layer ordering.
pub struct SceneStack {
    /// Active scene order; top element is the current scene.
    stack: Vec<SceneId>,
    /// Named scene registry mapping string names to SceneId.
    registry: HashMap<String, SceneId>,
    /// Per-scene data slot: maps string keys to SceneId-encoded values.
    data_keys: HashMap<String, SceneId>,
    /// Running transition, if any; None when no transition is active.
    transition: Option<ActiveTransition>,
    /// Pending transitions waiting for the active one to complete.
    transition_queue: VecDeque<(TransitionType, f32, EasingType)>,
    /// Draw layer priority per scene; used by get_active_ids_ordered_by_layer.
    scene_layers: HashMap<SceneId, i32>,
    /// Monotonic counter for SceneId generation; starts at 1.
    next_id: u64,
    /// Set of scene IDs marked as overlays; affects get_active_ids visibility rules.
    overlay_ids: HashSet<SceneId>,
}
impl SceneStack {
    /// Create an empty SceneStack with no active scenes and no pending transitions.
    pub fn new() -> Self {
        log_msg!(debug, SC01_STACK_INIT);
        Self {
            stack: Vec::new(),
            registry: HashMap::new(),
            data_keys: HashMap::new(),
            transition: None,
            transition_queue: VecDeque::new(),
            scene_layers: HashMap::new(),
            next_id: 1,
            overlay_ids: HashSet::new(),
        }
    }
    /// Allocate and return the next monotonically increasing SceneId.
    pub fn next_scene_id(&mut self) -> SceneId {
        let id = self.next_id;
        self.next_id += 1;
        id
    }
    /// Start transition immediately if none is active; otherwise enqueue it for later.
    fn enqueue_or_start_transition(
        &mut self,
        transition_type: TransitionType,
        duration: f32,
        easing: EasingType,
    ) {
        if transition_type == TransitionType::None || duration <= 0.0 {
            return;
        }
        if self.transition.is_some() {
            self.transition_queue
                .push_back((transition_type, duration, easing));
        } else {
            self.transition = Some(ActiveTransition::new_with_easing(
                transition_type,
                duration,
                easing,
            ));
        }
    }
    /// Pop the front item from the transition queue and start it if no transition is active.
    fn start_next_transition_from_queue(&mut self) {
        if self.transition.is_some() {
            return;
        }
        if let Some((transition_type, duration, easing)) = self.transition_queue.pop_front() {
            self.transition = Some(ActiveTransition::new_with_easing(
                transition_type,
                duration,
                easing,
            ));
        }
    }
    /// Push scene_id onto the stack, optionally starting a transition; returns the previously active SceneId.
    pub fn push(
        &mut self,
        scene_id: SceneId,
        transition_type: TransitionType,
        duration: f32,
        easing: EasingType,
    ) -> Option<SceneId> {
        log_msg!(info, SC02_SCENE_PUSH);
        let prev = self.stack.last().copied();
        self.enqueue_or_start_transition(transition_type, duration, easing);
        self.stack.push(scene_id);
        self.scene_layers.entry(scene_id).or_insert(0);
        prev
    }
    /// Pop the top scene, optionally starting a transition; returns (popped_id, newly_revealed_id) or Err when empty.
    pub fn pop(
        &mut self,
        transition_type: TransitionType,
        duration: f32,
        easing: EasingType,
    ) -> Result<(SceneId, Option<SceneId>), String> {
        if self.stack.is_empty() {
            return Err("Cannot pop from an empty scene stack".to_string());
        }
        log_msg!(info, SC03_SCENE_POP);
        let popped = self.stack.pop().unwrap();
        self.overlay_ids.remove(&popped);
        self.scene_layers.remove(&popped);
        let revealed = self.stack.last().copied();
        self.enqueue_or_start_transition(transition_type, duration, easing);
        Ok((popped, revealed))
    }
    /// Replace the top scene with scene_id and start the given transition; returns the replaced SceneId.
    pub fn switch_to(
        &mut self,
        scene_id: SceneId,
        transition_type: TransitionType,
        duration: f32,
        easing: EasingType,
    ) -> Option<SceneId> {
        let old = if !self.stack.is_empty() {
            let old_id = self.stack.pop().unwrap();
            self.overlay_ids.remove(&old_id);
            self.scene_layers.remove(&old_id);
            Some(old_id)
        } else {
            None
        };
        self.enqueue_or_start_transition(transition_type, duration, easing);
        self.stack.push(scene_id);
        self.scene_layers.entry(scene_id).or_insert(0);
        old
    }
    /// Clear all scenes, cancel transitions and queue, and return the drained scene IDs.
    pub fn clear(&mut self) -> Vec<SceneId> {
        log_msg!(info, SC04_STACK_CLEAR);
        self.transition = None;
        self.transition_queue.clear();
        self.overlay_ids.clear();
        self.scene_layers.clear();
        std::mem::take(&mut self.stack)
    }
    /// Look up registered scene id by name; does not modify the stack.
    pub fn pop_to(&self, name: &str) -> Option<SceneId> {
        self.registry.get(name).copied()
    }
    /// Pop scenes until target_id is on top; returns all popped IDs in pop order.
    pub fn pop_until(&mut self, target_id: SceneId) -> Vec<SceneId> {
        let mut popped = Vec::new();
        while let Some(&top) = self.stack.last() {
            if top == target_id {
                break;
            }
            let id = self.stack.pop().unwrap();
            self.overlay_ids.remove(&id);
            self.scene_layers.remove(&id);
            popped.push(id);
        }
        popped
    }
    /// Return the number of scenes currently on the stack.
    pub fn get_stack_size(&self) -> usize {
        self.stack.len()
    }
    /// Return true when the stack has no scenes.
    pub fn is_empty(&self) -> bool {
        self.stack.is_empty()
    }
    /// Return the top SceneId or None when the stack is empty.
    pub fn get_current(&self) -> Option<SceneId> {
        self.stack.last().copied()
    }
    /// Return all stacked SceneIds in push order (first = bottom, last = top).
    pub fn get_all(&self) -> &[SceneId] {
        &self.stack
    }
    /// Return true when a transition is currently running.
    pub fn is_transitioning(&self) -> bool {
        self.transition.is_some()
    }
    /// Return the raw (linear) transition progress in [0, 1]; 0.0 when no transition is active.
    pub fn get_transition_progress(&self) -> f32 {
        self.transition.as_ref().map_or(0.0, |t| t.progress())
    }
    /// Return the eased transition progress in [0, 1]; 0.0 when no transition is active.
    pub fn get_transition_progress_eased(&self) -> f32 {
        self.transition.as_ref().map_or(0.0, |t| t.progress_eased())
    }
    /// Enqueue a transition to start after the current one completes.
    pub fn queue_transition(
        &mut self,
        transition_type: TransitionType,
        duration: f32,
        easing: EasingType,
    ) {
        self.enqueue_or_start_transition(transition_type, duration, easing);
    }
    /// Return the number of transitions waiting in the queue.
    pub fn queued_transition_count(&self) -> usize {
        self.transition_queue.len()
    }
    /// Remove all pending transitions from the queue without affecting the active transition.
    pub fn clear_transition_queue(&mut self) {
        self.transition_queue.clear();
    }
    /// Advance the active transition by dt seconds; starts the next queued transition on completion; returns true when a transition just finished.
    pub fn update_transition(&mut self, dt: f32) -> bool {
        if let Some(ref mut t) = self.transition {
            t.update(dt);
            if t.is_complete() {
                self.transition = None;
                self.start_next_transition_from_queue();
                return true;
            }
        } else {
            self.start_next_transition_from_queue();
        }
        false
    }
    /// Push scene_id as an overlay (layer=100) that renders above all non-overlay scenes; returns previous top SceneId.
    pub fn push_overlay(
        &mut self,
        scene_id: SceneId,
        transition_type: TransitionType,
        duration: f32,
        easing: EasingType,
    ) -> Option<SceneId> {
        log_msg!(info, SC02_SCENE_PUSH);
        let prev = self.stack.last().copied();
        self.overlay_ids.insert(scene_id);
        self.enqueue_or_start_transition(transition_type, duration, easing);
        self.stack.push(scene_id);
        self.scene_layers.entry(scene_id).or_insert(100);
        prev
    }
    /// Return true when scene_id was pushed via push_overlay.
    pub fn is_overlay(&self, scene_id: SceneId) -> bool {
        self.overlay_ids.contains(&scene_id)
    }
    /// Return active scene IDs: all stacked IDs when any overlay is present, otherwise only the top scene.
    pub fn get_active_ids(&self) -> &[SceneId] {
        if self.stack.iter().any(|id| self.overlay_ids.contains(id)) {
            &self.stack
        } else {
            match self.stack.last() {
                Some(_) => &self.stack[self.stack.len() - 1..],
                None => &[],
            }
        }
    }
    /// Set the draw layer priority for scene_id; higher values draw on top of lower values.
    pub fn set_scene_layer(&mut self, scene_id: SceneId, layer: i32) {
        self.scene_layers.insert(scene_id, layer);
    }
    /// Return the draw layer for scene_id; 0 when not set.
    pub fn get_scene_layer(&self, scene_id: SceneId) -> i32 {
        self.scene_layers.get(&scene_id).copied().unwrap_or(0)
    }
    /// Return active scene IDs sorted by (layer, insertion index) ascending — front-to-back draw order.
    pub fn get_active_ids_ordered_by_layer(&self) -> Vec<SceneId> {
        let mut indexed: Vec<(usize, SceneId)> =
            self.get_active_ids().iter().copied().enumerate().collect();
        indexed.sort_by_key(|(idx, id)| (self.get_scene_layer(*id), *idx));
        indexed.into_iter().map(|(_, id)| id).collect()
    }
    /// Associate a string name with a SceneId in the named registry.
    pub fn register_scene(&mut self, name: String, scene_id: SceneId) {
        self.registry.insert(name, scene_id);
    }
    /// Look up a SceneId by name; returns None when not registered.
    pub fn get_registered(&self, name: &str) -> Option<SceneId> {
        self.registry.get(name).copied()
    }
    /// Return true when a scene is registered under the given name.
    pub fn has_registered(&self, name: &str) -> bool {
        self.registry.contains_key(name)
    }
    /// Remove a scene name from the registry; no-op when name is absent.
    pub fn unregister_scene(&mut self, name: &str) {
        self.registry.remove(name);
    }
    /// Return all registered scene names; order is unspecified.
    pub fn get_registered_names(&self) -> Vec<String> {
        self.registry.keys().cloned().collect()
    }
    /// Store a SceneId-encoded data value under the given key.
    pub fn set_data(&mut self, key: String, value_id: SceneId) {
        self.data_keys.insert(key, value_id);
    }
    /// Return the SceneId-encoded data stored under key, or None.
    pub fn get_data(&self, key: &str) -> Option<SceneId> {
        self.data_keys.get(key).copied()
    }
    /// Return true when a data value is stored under the given key.
    pub fn has_data(&self, key: &str) -> bool {
        self.data_keys.contains_key(key)
    }
    /// Remove the data entry for key; no-op when absent.
    pub fn remove_data(&mut self, key: &str) {
        self.data_keys.remove(key);
    }
}
/// Default delegates to new().
impl Default for SceneStack {
    fn default() -> Self {
        Self::new()
    }
}
