//! LIFO scene stack with registry and inter-scene data store.
//!
//! This module is part of Lurek2D's `scene` subsystem and provides the implementation
//! details for stack-related operations and data management.
//! Key types exported from this module: `SceneStack`.
//! Primary functions: `new()`, `next_scene_id()`, `push()`, `pop()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::{HashMap, HashSet, VecDeque};

use crate::log_msg;
use crate::runtime::log_messages::{
    SC01_STACK_INIT, SC02_SCENE_PUSH, SC03_SCENE_POP, SC04_STACK_CLEAR,
};
use crate::scene::transition::{ActiveTransition, EasingType, TransitionType};

/// Unique identifier for a scene in the stack.
pub type SceneId = u64;

/// The scene stack manages a LIFO stack of scene references.
///
/// Scenes are identified by `SceneId` values. The Lua API layer maps these
/// to `mlua::RegistryKey` references for actual Lua table access.
///
/// **Overlay mode**: when scenes are pushed with `push_overlay`, they are stored in
/// `overlay_ids`.  Every scene below the current top stays active â€” its `process`,
/// `process_physics`, and `render` callbacks continue firing each frame.  Calling
/// `pop()` on an overlay removes only the effect; the background scene is unaffected.
///
/// # Fields
/// - `stack` â€” `Vec<SceneId>`. LIFO scene stack, bottom-to-top.
/// - `registry` â€” `HashMap<String, SceneId>`. Named scene registry.
/// - `data_keys` â€” `HashMap<String, SceneId>`. Inter-scene data store.
/// - `transition` â€” `Option<ActiveTransition>`. Active visual transition, if any.
/// - `next_id` â€” `u64`. Next available scene ID counter.
/// - `overlay_ids` â€” `HashSet<SceneId>`. IDs pushed via `push_overlay`.
pub struct SceneStack {
    /// The scene stack, bottom-to-top.
    stack: Vec<SceneId>,
    /// Named scene registry mapping names to scene IDs.
    registry: HashMap<String, SceneId>,
    /// Inter-scene data store mapping string keys to scene IDs (used as data value refs).
    data_keys: HashMap<String, SceneId>,
    /// Active visual transition, if any.
    transition: Option<ActiveTransition>,
    /// Queued transitions chained by the scene sequencer.
    transition_queue: VecDeque<(TransitionType, f32, EasingType)>,
    /// Per-scene logical layer used to order process callbacks.
    scene_layers: HashMap<SceneId, i32>,
    /// Next available scene ID.
    next_id: u64,
    /// IDs pushed via `push_overlay`; scenes in this set do not pause the scene below.
    overlay_ids: HashSet<SceneId>,
}

impl SceneStack {
    /// Create a new empty scene stack. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
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

    /// Allocate a new unique scene ID.
    ///
    /// # Returns
    /// `SceneId`.
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

    /// Push a scene ID onto the stack and start an optional transition.
    ///
    /// The previous top scene receives `pause()` in the Lua API layer; it does not
    /// continue to receive `process` or `render` calls.  For a non-pausing overlay
    /// push, use `push_overlay` instead.
    ///
    /// # Parameters
    /// - `scene_id` â€” `SceneId`.
    /// - `transition_type` â€” `TransitionType`.
    /// - `duration` â€” `f32`.
    /// - `easing` â€” `EasingType`. Curve applied to transition progress.
    ///
    /// # Returns
    /// `Option<SceneId>`. Previous top scene ID, so the caller can invoke `pause()` on it.
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

    /// Pop the top scene from the stack.
    ///
    /// If the popped scene was an overlay, its overlay flag is cleared.  The newly
    /// revealed scene is NOT resumed here â€” the Lua API layer decides whether to call
    /// `resume()` based on whether the popped scene was an overlay.
    ///
    /// # Parameters
    /// - `transition_type` â€” `TransitionType`.
    /// - `duration` â€” `f32`.
    /// - `easing` â€” `EasingType`.
    ///
    /// # Returns
    /// `Result<(SceneId, Option<SceneId>), String>`.
    ///
    /// `(popped_id, revealed_id)` â€” the removed scene and the newly exposed top.
    /// Returns `Err` if the stack is empty.
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
        // Clear the effect flag if this scene was pushed as an overlay.
        self.overlay_ids.remove(&popped);
        self.scene_layers.remove(&popped);
        let revealed = self.stack.last().copied();
        self.enqueue_or_start_transition(transition_type, duration, easing);
        Ok((popped, revealed))
    }

    /// Replace the top scene with a new one.
    ///
    /// The old scene receives `leave()` in the Lua API layer.  Any overlay flag
    /// attached to the old top is also cleared.
    ///
    /// # Parameters
    /// - `scene_id` â€” `SceneId`.
    /// - `transition_type` â€” `TransitionType`.
    /// - `duration` â€” `f32`.
    /// - `easing` â€” `EasingType`.
    ///
    /// # Returns
    /// `Option<SceneId>`. Old top scene ID, so the caller can invoke `leave()` on it.
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

    /// Remove all scenes from the stack and clear all overlay flags.
    ///
    /// The caller is responsible for invoking `leave()` on each returned scene.
    ///
    /// # Returns
    /// `Vec<SceneId>`. All removed scene IDs in their original bottom-to-top order.
    pub fn clear(&mut self) -> Vec<SceneId> {
        log_msg!(info, SC04_STACK_CLEAR);
        self.transition = None;
        self.transition_queue.clear();
        self.overlay_ids.clear();
        self.scene_layers.clear();
        std::mem::take(&mut self.stack)
    }

    /// Look up a registered scene ID by name.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
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
    /// Overlay flags for each removed scene are cleared.  The target scene itself
    /// is NOT popped.
    ///
    /// # Parameters
    /// - `target_id` â€” `SceneId`.
    ///
    /// # Returns
    /// `Vec<SceneId>`. Removed scene IDs, in pop order (most recent first).
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

    /// Number of scenes on the stack. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_stack_size(&self) -> usize {
        self.stack.len()
    }

    /// Whether the stack is empty. This accessor incurs no allocation; call it freely in hot paths.
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

    /// Get easing-adjusted transition progress in [0, 1], or 0 if no transition.
    ///
    /// Uses the `EasingType` stored in the active `ActiveTransition`.  For a linear
    /// transition this is identical to `get_transition_progress()`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_transition_progress_eased(&self) -> f32 {
        self.transition.as_ref().map_or(0.0, |t| t.progress_eased())
    }

    /// Queue an additional transition to run after the current transition finishes.
    ///
    /// If there is no active transition, the queued transition starts immediately.
    ///
    /// # Parameters
    /// - `transition_type` — `TransitionType`.
    /// - `duration` — `f32`.
    /// - `easing` — `EasingType`.
    pub fn queue_transition(
        &mut self,
        transition_type: TransitionType,
        duration: f32,
        easing: EasingType,
    ) {
        self.enqueue_or_start_transition(transition_type, duration, easing);
    }

    /// Number of queued transitions waiting behind the current one.
    ///
    /// # Returns
    /// `usize`.
    pub fn queued_transition_count(&self) -> usize {
        self.transition_queue.len()
    }

    /// Clear all transitions queued in the sequencer.
    pub fn clear_transition_queue(&mut self) {
        self.transition_queue.clear();
    }

    /// Update the active transition timer. Returns true if the transition just completed.
    ///
    /// # Parameters
    /// - `dt` â€” `f32`.
    ///
    /// # Returns
    /// `bool`.
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

    // -- Overlay ---------------------------------------------------------------

    /// Push a scene as a non-pausing overlay over the current top scene.
    ///
    /// Unlike `push()`, the current scene below the effect continues to receive
    /// `process` and `render` calls every frame.  Neither `pause()` nor `resume()`
    /// is called on the underlying scene.
    ///
    /// On `pop()` the effect flag for the removed scene is cleared.
    ///
    /// # Parameters
    /// - `scene_id` â€” `SceneId`. The scene to push on top as an overlay.
    /// - `transition_type` â€” `TransitionType`.
    /// - `duration` â€” `f32`.
    /// - `easing` â€” `EasingType`.
    ///
    /// # Returns
    /// `Option<SceneId>`. Current top scene ID (the scene that becomes the background).
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

    /// Return `true` when `scene_id` was pushed via `push_overlay`.
    ///
    /// # Parameters
    /// - `scene_id` â€” `SceneId`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_overlay(&self, scene_id: SceneId) -> bool {
        self.overlay_ids.contains(&scene_id)
    }

    /// Return the scene IDs that should receive lifecycle callbacks this frame.
    ///
    /// When at least one overlay scene is present in the stack, ALL stack entries
    /// are considered active.  When no overlays exist, only the top scene is active.
    ///
    /// This slice is used by the Lua API layer to iterate `process`, `render`, and
    /// related callbacks.
    ///
    /// # Returns
    /// `&[SceneId]`. Bottom-to-top slice of active scene IDs.
    pub fn get_active_ids(&self) -> &[SceneId] {
        if self.stack.iter().any(|id| self.overlay_ids.contains(id)) {
            // At least one overlay â€” all scenes in the stack are active.
            &self.stack
        } else {
            // Normal mode â€” only the top scene is active.
            match self.stack.last() {
                Some(_) => &self.stack[self.stack.len() - 1..],
                None => &[],
            }
        }
    }
    /// Set logical processing layer for a scene.
    ///
    /// Lower values run first during `process*` callbacks.
    ///
    /// # Parameters
    /// - `scene_id` — `SceneId`.
    /// - `layer` — `i32`.
    pub fn set_scene_layer(&mut self, scene_id: SceneId, layer: i32) {
        self.scene_layers.insert(scene_id, layer);
    }

    /// Get logical processing layer for a scene.
    ///
    /// # Parameters
    /// - `scene_id` — `SceneId`.
    ///
    /// # Returns
    /// `i32`.
    pub fn get_scene_layer(&self, scene_id: SceneId) -> i32 {
        self.scene_layers.get(&scene_id).copied().unwrap_or(0)
    }

    /// Return active scene IDs ordered by logical layer and stack order.
    ///
    /// Lower layer values are processed first. When two scenes share a layer,
    /// their relative order follows stack insertion order (bottom-to-top).
    ///
    /// # Returns
    /// `Vec<SceneId>`.
    pub fn get_active_ids_ordered_by_layer(&self) -> Vec<SceneId> {
        let mut indexed: Vec<(usize, SceneId)> =
            self.get_active_ids().iter().copied().enumerate().collect();
        indexed.sort_by_key(|(idx, id)| (self.get_scene_layer(*id), *idx));
        indexed.into_iter().map(|(_, id)| id).collect()
    }
    // -- Registry --

    /// Register a scene by name. Panics in debug mode if the same entity is registered twice.
    ///
    /// # Parameters
    /// - `name` â€” `String`.
    /// - `scene_id` â€” `SceneId`.
    pub fn register_scene(&mut self, name: String, scene_id: SceneId) {
        self.registry.insert(name, scene_id);
    }

    /// Get a registered scene ID by name. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
    ///
    /// # Returns
    /// `Option<SceneId>`.
    pub fn get_registered(&self, name: &str) -> Option<SceneId> {
        self.registry.get(name).copied()
    }

    /// Check if a name is registered. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_registered(&self, name: &str) -> bool {
        self.registry.contains_key(name)
    }

    /// Unregister a scene by name.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
    pub fn unregister_scene(&mut self, name: &str) {
        self.registry.remove(name);
    }

    /// Get all registered scene names. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_registered_names(&self) -> Vec<String> {
        self.registry.keys().cloned().collect()
    }

    // -- Data store --

    /// Store a data value reference by key. Replaces the current data value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `key` â€” `String`.
    /// - `value_id` â€” `SceneId`.
    pub fn set_data(&mut self, key: String, value_id: SceneId) {
        self.data_keys.insert(key, value_id);
    }

    /// Get a stored data value reference by key.
    ///
    /// # Parameters
    /// - `key` â€” `&str`.
    ///
    /// # Returns
    /// `Option<SceneId>`.
    pub fn get_data(&self, key: &str) -> Option<SceneId> {
        self.data_keys.get(key).copied()
    }

    /// Check if a data key exists. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `key` â€” `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_data(&self, key: &str) -> bool {
        self.data_keys.contains_key(key)
    }

    /// Remove a data value by key. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `key` â€” `&str`.
    pub fn remove_data(&mut self, key: &str) {
        self.data_keys.remove(key);
    }
}

impl Default for SceneStack {
    fn default() -> Self {
        Self::new()
    }
}

// Tests migrated to tests/rust/unit/scene_tests.rs
