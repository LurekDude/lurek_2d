//! LIFO scene stack with registry and inter-scene data store.

use std::collections::HashMap;

use crate::scene::transition::{ActiveTransition, TransitionType};

/// Unique identifier for a scene in the stack.
pub type SceneId = u64;

/// The scene stack manages a LIFO stack of scene references.
///
/// Scenes are identified by `SceneId` values. The Lua API layer maps these
/// to `mlua::RegistryKey` references for actual Lua table access.
pub struct SceneStack {
    /// The scene stack, bottom-to-top.
    stack: Vec<SceneId>,
    /// Named scene registry mapping names to scene IDs.
    registry: HashMap<String, SceneId>,
    /// Inter-scene data store mapping string keys to scene IDs (used as data value refs).
    data_keys: HashMap<String, SceneId>,
    /// Active visual transition, if any.
    transition: Option<ActiveTransition>,
    /// Next available scene ID.
    next_id: u64,
}

impl SceneStack {
    /// Create a new empty scene stack.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            stack: Vec::new(),
            registry: HashMap::new(),
            data_keys: HashMap::new(),
            transition: None,
            next_id: 1,
        }
    }

    /// Allocate a new unique scene ID.
    ///
    /// # Returns
    /// `SceneId`.
    pub fn next_scene_id(&mut self) -> SceneId {
        let id = self.next_id;
        self.next_id += 1;
        id
    }

    /// Push a scene ID onto the stack and start a transition.
    ///
    /// # Parameters
    /// - `scene_id` — `SceneId`.
    /// - `transition_type` — `TransitionType`.
    /// - `duration` — `f32`.
    ///
    /// # Returns
    /// `Option<SceneId>`.
    ///
    /// Returns the previous top scene ID (if any) so the caller can invoke `pause()` on it.
    pub fn push(
        &mut self,
        scene_id: SceneId,
        transition_type: TransitionType,
        duration: f32,
    ) -> Option<SceneId> {
        let prev = self.stack.last().copied();
        if transition_type != TransitionType::None && duration > 0.0 {
            self.transition = Some(ActiveTransition::new(transition_type, duration));
        }
        self.stack.push(scene_id);
        prev
    }

    /// Pop the top scene from the stack.
    ///
    /// # Parameters
    /// - `transition_type` — `TransitionType`.
    /// - `duration` — `f32`.
    ///
    /// # Returns
    /// `Result<(SceneId, Option<SceneId>), String>`.
    ///
    /// Returns `(popped_id, revealed_id)` — the removed scene and the newly exposed top.
    /// Returns `Err` if the stack is empty.
    pub fn pop(
        &mut self,
        transition_type: TransitionType,
        duration: f32,
    ) -> Result<(SceneId, Option<SceneId>), String> {
        if self.stack.is_empty() {
            return Err("Cannot pop from an empty scene stack".to_string());
        }
        let popped = self.stack.pop().unwrap();
        let revealed = self.stack.last().copied();
        if transition_type != TransitionType::None && duration > 0.0 {
            self.transition = Some(ActiveTransition::new(transition_type, duration));
        }
        Ok((popped, revealed))
    }

    /// Replace the top scene with a new one.
    ///
    /// # Parameters
    /// - `scene_id` — `SceneId`.
    /// - `transition_type` — `TransitionType`.
    /// - `duration` — `f32`.
    ///
    /// # Returns
    /// `Option<SceneId>`.
    ///
    /// Returns the old top scene ID so the caller can invoke `leave()` on it.
    /// If the stack is empty, just pushes the new scene.
    pub fn switch_to(
        &mut self,
        scene_id: SceneId,
        transition_type: TransitionType,
        duration: f32,
    ) -> Option<SceneId> {
        let old = if !self.stack.is_empty() {
            Some(self.stack.pop().unwrap())
        } else {
            None
        };
        if transition_type != TransitionType::None && duration > 0.0 {
            self.transition = Some(ActiveTransition::new(transition_type, duration));
        }
        self.stack.push(scene_id);
        old
    }

    /// Remove all scenes from the stack. Returns all removed scene IDs.
    ///
    /// # Returns
    /// `Vec<SceneId>`.
    pub fn clear(&mut self) -> Vec<SceneId> {
        self.transition = None;
        std::mem::take(&mut self.stack)
    }

    /// Look up a registered scene ID by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<SceneId>`.
    ///
    /// Returns the scene ID if found, or `None` if the name is not registered.
    pub fn pop_to(&self, name: &str) -> Option<SceneId> {
        self.registry.get(name).copied()
    }

    /// Pop scenes until `target_id` is on top of the stack.
    ///
    /// # Parameters
    /// - `target_id` — `SceneId`.
    ///
    /// # Returns
    /// `Vec<SceneId>`.
    ///
    /// Returns the list of popped scene IDs.
    pub fn pop_until(&mut self, target_id: SceneId) -> Vec<SceneId> {
        let mut popped = Vec::new();
        while let Some(&top) = self.stack.last() {
            if top == target_id {
                break;
            }
            popped.push(self.stack.pop().unwrap());
        }
        popped
    }

    /// Number of scenes on the stack.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_stack_size(&self) -> usize {
        self.stack.len()
    }

    /// Whether the stack is empty.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.stack.is_empty()
    }

    /// Get the top scene ID, or `None` if empty.
    ///
    /// # Returns
    /// `Option<SceneId>`.
    pub fn get_current(&self) -> Option<SceneId> {
        self.stack.last().copied()
    }

    /// Get all scene IDs in the stack, bottom-to-top.
    ///
    /// # Returns
    /// `&[SceneId]`.
    pub fn get_all(&self) -> &[SceneId] {
        &self.stack
    }

    // -- Transition --

    /// Whether a transition is currently active.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_transitioning(&self) -> bool {
        self.transition.is_some()
    }

    /// Get transition progress [0, 1], or 0 if no transition.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_transition_progress(&self) -> f32 {
        self.transition.as_ref().map_or(0.0, |t| t.progress())
    }

    /// Update the active transition timer. Returns true if the transition just completed.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn update_transition(&mut self, dt: f32) -> bool {
        if let Some(ref mut t) = self.transition {
            t.update(dt);
            if t.is_complete() {
                self.transition = None;
                return true;
            }
        }
        false
    }

    // -- Registry --

    /// Register a scene by name.
    ///
    /// # Parameters
    /// - `name` — `String`.
    /// - `scene_id` — `SceneId`.
    pub fn register_scene(&mut self, name: String, scene_id: SceneId) {
        self.registry.insert(name, scene_id);
    }

    /// Get a registered scene ID by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<SceneId>`.
    pub fn get_registered(&self, name: &str) -> Option<SceneId> {
        self.registry.get(name).copied()
    }

    /// Check if a name is registered.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_registered(&self, name: &str) -> bool {
        self.registry.contains_key(name)
    }

    /// Unregister a scene by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn unregister_scene(&mut self, name: &str) {
        self.registry.remove(name);
    }

    /// Get all registered scene names.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_registered_names(&self) -> Vec<String> {
        self.registry.keys().cloned().collect()
    }

    // -- Data store --

    /// Store a data value reference by key.
    ///
    /// # Parameters
    /// - `key` — `String`.
    /// - `value_id` — `SceneId`.
    pub fn set_data(&mut self, key: String, value_id: SceneId) {
        self.data_keys.insert(key, value_id);
    }

    /// Get a stored data value reference by key.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `Option<SceneId>`.
    pub fn get_data(&self, key: &str) -> Option<SceneId> {
        self.data_keys.get(key).copied()
    }

    /// Check if a data key exists.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_data(&self, key: &str) -> bool {
        self.data_keys.contains_key(key)
    }

    /// Remove a data value by key.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    pub fn remove_data(&mut self, key: &str) {
        self.data_keys.remove(key);
    }
}

impl Default for SceneStack {
    fn default() -> Self {
        Self::new()
    }
}
