use crate::log_msg;
use crate::runtime::log_messages::{
    SC01_STACK_INIT, SC02_SCENE_PUSH, SC03_SCENE_POP, SC04_STACK_CLEAR,
};
use crate::scene::transition::{ActiveTransition, EasingType, TransitionType};
use std::collections::{HashMap, HashSet, VecDeque};
pub type SceneId = u64;
pub struct SceneStack {
    stack: Vec<SceneId>,
    registry: HashMap<String, SceneId>,
    data_keys: HashMap<String, SceneId>,
    transition: Option<ActiveTransition>,
    transition_queue: VecDeque<(TransitionType, f32, EasingType)>,
    scene_layers: HashMap<SceneId, i32>,
    next_id: u64,
    overlay_ids: HashSet<SceneId>,
}
impl SceneStack {
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
    pub fn next_scene_id(&mut self) -> SceneId {
        let id = self.next_id;
        self.next_id += 1;
        id
    }
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
    pub fn clear(&mut self) -> Vec<SceneId> {
        log_msg!(info, SC04_STACK_CLEAR);
        self.transition = None;
        self.transition_queue.clear();
        self.overlay_ids.clear();
        self.scene_layers.clear();
        std::mem::take(&mut self.stack)
    }
    pub fn pop_to(&self, name: &str) -> Option<SceneId> {
        self.registry.get(name).copied()
    }
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
    pub fn get_stack_size(&self) -> usize {
        self.stack.len()
    }
    pub fn is_empty(&self) -> bool {
        self.stack.is_empty()
    }
    pub fn get_current(&self) -> Option<SceneId> {
        self.stack.last().copied()
    }
    pub fn get_all(&self) -> &[SceneId] {
        &self.stack
    }
    pub fn is_transitioning(&self) -> bool {
        self.transition.is_some()
    }
    pub fn get_transition_progress(&self) -> f32 {
        self.transition.as_ref().map_or(0.0, |t| t.progress())
    }
    pub fn get_transition_progress_eased(&self) -> f32 {
        self.transition.as_ref().map_or(0.0, |t| t.progress_eased())
    }
    pub fn queue_transition(
        &mut self,
        transition_type: TransitionType,
        duration: f32,
        easing: EasingType,
    ) {
        self.enqueue_or_start_transition(transition_type, duration, easing);
    }
    pub fn queued_transition_count(&self) -> usize {
        self.transition_queue.len()
    }
    pub fn clear_transition_queue(&mut self) {
        self.transition_queue.clear();
    }
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
    pub fn is_overlay(&self, scene_id: SceneId) -> bool {
        self.overlay_ids.contains(&scene_id)
    }
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
    pub fn set_scene_layer(&mut self, scene_id: SceneId, layer: i32) {
        self.scene_layers.insert(scene_id, layer);
    }
    pub fn get_scene_layer(&self, scene_id: SceneId) -> i32 {
        self.scene_layers.get(&scene_id).copied().unwrap_or(0)
    }
    pub fn get_active_ids_ordered_by_layer(&self) -> Vec<SceneId> {
        let mut indexed: Vec<(usize, SceneId)> =
            self.get_active_ids().iter().copied().enumerate().collect();
        indexed.sort_by_key(|(idx, id)| (self.get_scene_layer(*id), *idx));
        indexed.into_iter().map(|(_, id)| id).collect()
    }
    pub fn register_scene(&mut self, name: String, scene_id: SceneId) {
        self.registry.insert(name, scene_id);
    }
    pub fn get_registered(&self, name: &str) -> Option<SceneId> {
        self.registry.get(name).copied()
    }
    pub fn has_registered(&self, name: &str) -> bool {
        self.registry.contains_key(name)
    }
    pub fn unregister_scene(&mut self, name: &str) {
        self.registry.remove(name);
    }
    pub fn get_registered_names(&self) -> Vec<String> {
        self.registry.keys().cloned().collect()
    }
    pub fn set_data(&mut self, key: String, value_id: SceneId) {
        self.data_keys.insert(key, value_id);
    }
    pub fn get_data(&self, key: &str) -> Option<SceneId> {
        self.data_keys.get(key).copied()
    }
    pub fn has_data(&self, key: &str) -> bool {
        self.data_keys.contains_key(key)
    }
    pub fn remove_data(&mut self, key: &str) {
        self.data_keys.remove(key);
    }
}
impl Default for SceneStack {
    fn default() -> Self {
        Self::new()
    }
}
