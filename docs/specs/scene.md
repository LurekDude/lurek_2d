# scene

## General Info

- Module group: `Feature Systems`
- Source path: `src/scene/`
- Lua API path(s): `src/lua_api/scene_api.rs`
- Primary Lua namespace: `lurek.scene`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Summary

The `scene` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `image`, `render`, `runtime`. Its responsibility should stay inside the Feature Systems group rather than absorb behavior owned by those neighbors.

## Files

- `depth_sorter.rs`: Per-frame depth-ordered callback batcher used by the Lua scene layer.
- `easing.rs`: - Easing curve helpers for scene transitions and tween interpolation.
- `mod.rs`: Module root and re-export surface for the stack, transition, and depth-sorting types.
- `render.rs`: Empty render-command and simple CPU-image helpers so `SceneStack` fits shared engine interfaces.
- `stack.rs`: Scene stack, registry, shared-data bookkeeping, and transition state ownership.
- `transition.rs`: Transition-type enum plus active transition progress and timer logic.

## Types

- `DepthEntry` (`struct`, `depth_sorter.rs`): Individual depth-sorted entry stored inside `DepthSorter`.
- `DepthSorter` (`struct`, `depth_sorter.rs`): Per-frame sorter for scene draw callbacks or scene objects.
- `SceneId` (`type`, `stack.rs`): Stable integer identifier used by the Rust stack while Lua owns the actual scene tables.
- `SceneStack` (`struct`, `stack.rs`): Main scene-flow owner for stack order, registry lookups, stored data keys, and active transition state.
- `TransitionType` (`enum`, `transition.rs`): Enum for no transition, fade, and slide directions.
- `EasingType` (`enum`, `transition.rs`): Easing curve applied to normalized transition progress.
- `ActiveTransition` (`struct`, `transition.rs`): Timer and progress record for one transition in flight.

## Functions

- `DepthSorter::new` (`depth_sorter.rs`): Create an empty DepthSorter with dirty=false and stable=false.
- `DepthSorter::set_stable` (`depth_sorter.rs`): Set whether sort() uses stable ordering; stable preserves insertion order for equal depths.
- `DepthSorter::is_stable` (`depth_sorter.rs`): Return current stable flag value.
- `DepthSorter::add` (`depth_sorter.rs`): Append a plain layer draw entry at the given depth and mark the sorter dirty.
- `DepthSorter::add_object` (`depth_sorter.rs`): Append a scene-object draw entry (is_object=true) at the given depth and mark dirty.
- `DepthSorter::sort` (`depth_sorter.rs`): Sort entries using the best available strategy; delegates to parallel, radix, stable, or unstable.
- `DepthSorter::sort_radix` (`depth_sorter.rs`): Sort with four 8-bit radix passes; falls back to unstable sort when preconditions fail; returns true on radix path.
- `DepthSorter::sort_parallel` (`depth_sorter.rs`): Sort using rayon par_sort_unstable_by; used when entry count exceeds PARALLEL_SORT_THRESHOLD.
- `DepthSorter::sorted_entries` (`depth_sorter.rs`): Return sorted entry slice, triggering sort() first if dirty.
- `DepthSorter::clear` (`depth_sorter.rs`): Clear all entries and reset dirty to false.
- `DepthSorter::get_count` (`depth_sorter.rs`): Return entry count without sorting.
- `bounce_out` (`easing.rs`): Evaluate the bounce-out easing curve for t in [0, 1]; returns 1 at t=1.
- `SceneStack::generate_render_commands` (`render.rs`): Collect and return RenderCommand list for the current scene; returns empty vec when no scene is active.
- `SceneStack::draw_to_image` (`render.rs`): Render the active scene into a new ImageData of the given pixel dimensions; fills with background colour when empty.
- `SceneStack::new` (`stack.rs`): Create an empty SceneStack with no active scenes and no pending transitions.
- `SceneStack::next_scene_id` (`stack.rs`): Allocate and return the next monotonically increasing SceneId.
- `SceneStack::push` (`stack.rs`): Push scene_id onto the stack, optionally starting a transition; returns the previously active SceneId.
- `SceneStack::pop` (`stack.rs`): Pop the top scene, optionally starting a transition; returns (popped_id, newly_revealed_id) or Err when empty.
- `SceneStack::switch_to` (`stack.rs`): Replace the top scene with scene_id and start the given transition; returns the replaced SceneId.
- `SceneStack::clear` (`stack.rs`): Clear all scenes, cancel transitions and queue, and return the drained scene IDs.
- `SceneStack::pop_to` (`stack.rs`): Look up registered scene id by name; does not modify the stack.
- `SceneStack::pop_until` (`stack.rs`): Pop scenes until target_id is on top; returns all popped IDs in pop order.
- `SceneStack::get_stack_size` (`stack.rs`): Return the number of scenes currently on the stack.
- `SceneStack::is_empty` (`stack.rs`): Return true when the stack has no scenes.
- `SceneStack::get_current` (`stack.rs`): Return the top SceneId or None when the stack is empty.
- `SceneStack::get_all` (`stack.rs`): Return all stacked SceneIds in push order (first = bottom, last = top).
- `SceneStack::is_transitioning` (`stack.rs`): Return true when a transition is currently running.
- `SceneStack::get_transition_progress` (`stack.rs`): Return the raw (linear) transition progress in [0, 1]; 0.0 when no transition is active.
- `SceneStack::get_transition_progress_eased` (`stack.rs`): Return the eased transition progress in [0, 1]; 0.0 when no transition is active.
- `SceneStack::queue_transition` (`stack.rs`): Enqueue a transition to start after the current one completes.
- `SceneStack::queued_transition_count` (`stack.rs`): Return the number of transitions waiting in the queue.
- `SceneStack::clear_transition_queue` (`stack.rs`): Remove all pending transitions from the queue without affecting the active transition.
- `SceneStack::update_transition` (`stack.rs`): Advance the active transition by dt seconds; starts the next queued transition on completion; returns true when a transition just finished.
- `SceneStack::push_overlay` (`stack.rs`): Push scene_id as an overlay (layer=100) that renders above all non-overlay scenes; returns previous top SceneId.
- `SceneStack::is_overlay` (`stack.rs`): Return true when scene_id was pushed via push_overlay.
- `SceneStack::get_active_ids` (`stack.rs`): Return active scene IDs: all stacked IDs when any overlay is present, otherwise only the top scene.
- `SceneStack::set_scene_layer` (`stack.rs`): Set the draw layer priority for scene_id; higher values draw on top of lower values.
- `SceneStack::get_scene_layer` (`stack.rs`): Return the draw layer for scene_id; 0 when not set.
- `SceneStack::get_active_ids_ordered_by_layer` (`stack.rs`): Return active scene IDs sorted by (layer, insertion index) ascending — front-to-back draw order.
- `SceneStack::register_scene` (`stack.rs`): Associate a string name with a SceneId in the named registry.
- `SceneStack::get_registered` (`stack.rs`): Look up a SceneId by name; returns None when not registered.
- `SceneStack::has_registered` (`stack.rs`): Return true when a scene is registered under the given name.
- `SceneStack::unregister_scene` (`stack.rs`): Remove a scene name from the registry; no-op when name is absent.
- `SceneStack::get_registered_names` (`stack.rs`): Return all registered scene names; order is unspecified.
- `SceneStack::set_data` (`stack.rs`): Store a SceneId-encoded data value under the given key.
- `SceneStack::get_data` (`stack.rs`): Return the SceneId-encoded data stored under key, or None.
- `SceneStack::has_data` (`stack.rs`): Return true when a data value is stored under the given key.
- `SceneStack::remove_data` (`stack.rs`): Remove the data entry for key; no-op when absent.
- `TransitionType::from_lua_str` (`transition.rs`): Parse a Lua string to TransitionType; unrecognised values return None.
- `EasingType::from_lua_str` (`transition.rs`): Parse a Lua string to EasingType; unrecognised values return Linear.
- `EasingType::apply` (`transition.rs`): Evaluate this easing curve for t in [0, 1]; clamps input and returns value in approximately [0, 1].
- `ActiveTransition::new` (`transition.rs`): Create an ActiveTransition with Linear easing and elapsed=0.
- `ActiveTransition::new_with_easing` (`transition.rs`): Create an ActiveTransition with explicit easing and elapsed=0.
- `ActiveTransition::set_easing` (`transition.rs`): Replace the easing curve without resetting elapsed.
- `ActiveTransition::get_easing` (`transition.rs`): Return the current easing curve.
- `ActiveTransition::progress` (`transition.rs`): Return linear progress in [0, 1]; returns 1.0 when duration <= 0.
- `ActiveTransition::progress_eased` (`transition.rs`): Return eased progress by applying self.easing to linear progress.
- `ActiveTransition::is_complete` (`transition.rs`): Return true when elapsed >= duration; logs TR02 on first completion check.
- `ActiveTransition::update` (`transition.rs`): Advance elapsed by dt seconds; ignores non-positive dt.

## Lua API Reference

- Binding path(s): `src/lua_api/scene_api.rs`
- Namespace: `lurek.scene`

### Module Functions
- `lurek.scene.push`: Push a new scene onto the stack, making it the active scene. The previously-active scene receives its `pause()` lifecycle callback and the new scene receives `enter(self, params)`. An optional visual transition (fade, slide, iris, etc.) animates between the two scenes over the specified duration.
- `lurek.scene.pop`: Pop the top scene off the stack and return to the previous one. The popped scene receives `leave()` and the revealed scene receives `resume()` (unless the popped scene was an overlay, in which case the underlying scene was never paused). Use this for "back" navigation, closing menus, or exiting sub-screens.
- `lurek.scene.switchTo`: Replace the current top scene with a different one without changing stack depth. The old scene receives `leave()` and the new scene receives `enter(self, params)`. Unlike `push`, no scene is added to the stack — the old scene is removed and the new one takes its slot. Ideal for transitioning between peer-level game states (e.g. level 1 → level 2).
- `lurek.scene.clear`: Remove all scenes from the stack. Each removed scene receives its `leave()` callback in stack order. After this call the stack is empty and `isEmpty()` returns true. Useful for returning to a title screen or tearing down the entire scene graph.
- `lurek.scene.popTo`: Pop scenes off the stack until the named registered scene is on top. Every popped scene receives `leave()` and the target scene receives `resume()`. The target scene must have been previously added via `registerScene`. Returns false if no scene with that name exists on the stack.
- `lurek.scene.update`: Advance any active transition animation and call `update(self, dt)` on the current top scene. Call this once per frame from your main loop to drive scene logic and transition timing.
- `lurek.scene.process`: Call `ready(self)` once on newly-pushed scenes, then call `process(self, dt)` on every active scene ordered by layer (lowest first). Use this for deterministic game-logic ticks at a fixed time step. Scenes pushed as overlays and underlying scenes all receive this callback.
- `lurek.scene.processPhysics`: Call `process_physics(self, dt)` on every active scene ordered by layer. Run this callback after your physics world step so scenes can react to collision results, apply forces, or synchronize sprite positions with physics bodies.
- `lurek.scene.processLate`: Call `process_late(self, dt)` on every active scene after all other processing. Ideal for camera follow logic, HUD synchronization, deferred cleanup, or any work that depends on the final positions of game objects.
- `lurek.scene.draw`: Call `draw(self)` on every scene in the stack from bottom to top. This is the legacy draw callback — prefer `render` and `renderUi` for world-space and screen-space separation.
- `lurek.scene.render`: Call `render(self)` on every scene in the stack from bottom to top. This is the preferred world-space rendering callback — draw sprites, tilemaps, particles, and other in-world visuals here. Runs before `renderUi`.
- `lurek.scene.renderUi`: Call `render_ui(self)` on every scene in the stack from bottom to top. Use this for screen-space HUD elements, health bars, score displays, menus, and overlays that should draw on top of the world after `render`.
- `lurek.scene.getStackSize`: Returns the total number of scenes currently on the stack, including overlays. Useful for asserting expected navigation depth or debugging scene flow.
- `lurek.scene.depth`: Alias for `getStackSize`. Returns the total number of scenes currently on the stack.
- `lurek.scene.isEmpty`: Returns true if the scene stack contains no scenes at all. Useful for guarding against calling `pop` on an empty stack or for detecting when the game should quit.
- `lurek.scene.getCurrent`: Returns the scene table currently on top of the stack, or nil if the stack is empty. Use this to inspect or call methods on the active scene directly.
- `lurek.scene.setCurrentLayer`: Set the rendering layer of the current top scene. Scenes with higher layer values are processed and drawn after lower-layer scenes. Use layers to control draw order when multiple scenes are active (e.g. game world at layer 0, HUD overlay at layer 10).
- `lurek.scene.getCurrentLayer`: Get the rendering layer of the current top scene. Returns 0 if the stack is empty or if no layer was explicitly set.
- `lurek.scene.isTransitioning`: Returns true if a scene transition animation is currently playing. Use this to block input or skip certain logic during transitions.
- `lurek.scene.getTransitionProgress`: Returns the raw linear progress (0.0 to 1.0) of the current transition animation, ignoring easing. Returns 0 when no transition is active. Use `getTransitionProgressEased` for the eased value.
- `lurek.scene.queueTransition`: Queue a transition to play automatically after the current one finishes. Multiple queued transitions execute in FIFO order, enabling multi-step cinematic sequences (e.g. fade-out then slide-in).
- `lurek.scene.getQueuedTransitionCount`: Returns the number of transitions waiting in the queue behind the currently-playing transition.
- `lurek.scene.clearQueuedTransitions`: Discard all queued transitions without affecting the currently-playing transition (if any). Use this to cancel a planned transition sequence mid-way.
- `lurek.scene.registerScene`: Register a scene table under a unique name for later retrieval via `getRegistered`, navigation via `popTo`, or deferred push via `pushPreloaded`. Registering does not push the scene onto the stack.
- `lurek.scene.getRegistered`: Retrieve a previously registered scene table by its name, or nil if no scene is registered under that name. Does not affect the stack.
- `lurek.scene.hasRegistered`: Check whether a scene is registered under the given name.
- `lurek.scene.unregisterScene`: Remove a scene registration by name. Does not pop the scene if it is currently active on the stack — it only removes the name mapping.
- `lurek.scene.getRegisteredNames`: Returns an array of all currently registered scene name strings. Useful for debugging or building dynamic scene-selection UIs.
- `lurek.scene.setData`: Store an arbitrary Lua value in the scene module's shared data map, keyed by a string name. Scenes can use this to pass information between each other without direct references — for example, passing a selected level index from a menu scene to a gameplay scene.
- `lurek.scene.getData`: Retrieve a value from the shared data map by key, or nil if the key has not been set. Commonly used in a scene's `enter` callback to read parameters set by the previous scene.
- `lurek.scene.hasData`: Check whether a key exists in the shared scene data map without retrieving its value.
- `lurek.scene.removeData`: Remove a key and its associated value from the shared scene data map. No-op if the key does not exist.
- `lurek.scene.newDepthSorter`: Create a new `LDepthSorter` instance for collecting drawable items and flushing them in depth-sorted (painter's algorithm) order. Allocate one per scene or per rendering pass.
- `lurek.scene.new`: Create a new scene instance from an optional prototype table. Sets up metatables so the instance inherits methods from the prototype. Use this for one-off scene creation; use `define` when you need a reusable scene constructor.
- `lurek.scene.define`: Create a reusable scene constructor function from a prototype table. Each call to the returned factory produces a fresh instance that inherits methods from the prototype via metatables. Ideal for defining scene "classes" that can be instantiated multiple times.
- `lurek.scene.getTransitionProgressEased`: Returns the eased progress (0.0 to 1.0) of the current transition, with the selected easing curve applied. Returns 0 when no transition is active. Use this instead of `getTransitionProgress` when you want smooth, non-linear animation values.
- `lurek.scene.pushOverlay`: Push a scene as a transparent overlay on top of the current scene. Unlike `push`, the underlying scene is NOT paused — it continues to receive `process`, `draw`, and `render` callbacks. Use overlays for pause menus, dialog boxes, inventory screens, or debug panels that should draw on top without stopping gameplay.
- `lurek.scene.isOverlay`: Returns true if the current top scene was pushed via `pushOverlay`. Overlay scenes do not pause the scene beneath them, allowing both to update and render simultaneously.
- `lurek.scene.getActiveScenes`: Returns a Lua array of all active scene tables ordered by their layer value (lowest layer first). Includes both regular scenes and overlays. Useful for iterating over all scenes for custom processing or debugging.
- `lurek.scene.preload`: Register a deferred-loading function for a scene. The loader function is NOT called immediately — it runs the first time `pushPreloaded` is called with this name. Use this to spread scene initialization (asset loading, table setup) across loading screens or lazy-load heavy scenes on demand.
- `lurek.scene.isPreloaded`: Returns true if the named preload loader has already been executed at least once. Once a loader runs, subsequent `pushPreloaded` calls skip the loader and push the already-registered scene directly.
- `lurek.scene.pushPreloaded`: Push a preloaded scene onto the stack by name. If the loader registered via `preload` has not yet run, it executes first to create and register the scene. Then the registered scene is pushed with the specified transition. Combines deferred loading with stack navigation in a single call.
- `lurek.scene.getTransitionTypes`: Returns a Lua array of all supported transition type name strings. Use this to discover available transitions at runtime or build a transition picker UI.
- `lurek.scene.serializeScene`: Capture the current scene stack state as a serializable snapshot table. The snapshot contains a `stack` array of registered scene names (in stack order) and a `data` map of shared data key-value pairs. Use this for save/load systems to persist the player's navigation state.
- `lurek.scene.deserializeScene`: Restore shared scene data from a previously-serialized snapshot table. Only the `data` key-value map is restored; the scene stack itself must be rebuilt manually by pushing or registering scenes. Pair with `serializeScene` for save/load workflows.
- `lurek.scene.fade`: Helper sub-table `lurek.scene.transitions` with convenience factory functions that build transition descriptor tables for use with transition-aware APIs.
- `lurek.scene.slide`: Create a directional slide transition descriptor table. The new scene slides in from the specified direction, pushing the old scene out.
- `lurek.scene.wipe`: Create a horizontal wipe transition descriptor table. A wipe bar sweeps across the screen to reveal the new scene.
- `lurek.scene.iris`: Create an iris (circle) transition descriptor table. A circular aperture opens or closes to reveal the new scene, similar to classic cartoon transitions.

### `LDepthSorter` Methods
- `LDepthSorter:add`: Register a draw callback at a given depth value. When `flush` is called, all registered callbacks execute in back-to-front order (lowest depth drawn first, highest depth drawn last / on top). Use this for simple draw calls like sprite rendering where each entity has a depth/z-layer.
- `LDepthSorter:addObject`: Register a game object table for depth-sorted rendering. The object must expose a numeric `depth` field and a `drawSorted(self)` method. During `flush`, each object's `drawSorted` is called in depth order, making this ideal for entity-based architectures where objects manage their own drawing.
- `LDepthSorter:sort`: Sort all registered entries by depth without executing any callbacks. Call this only if you need to inspect the sorted order before drawing; `flush` already sorts automatically.
- `LDepthSorter:flush`: Sort all entries by depth, execute every callback or object's `drawSorted` method in back-to-front order, then clear the sorter for the next frame. This is the standard one-call render path — call it once per frame inside your scene's `draw` or `render` callback.
- `LDepthSorter:setStable`: Enable or disable stable sorting. When stable, items sharing the same depth value retain their insertion order, which prevents visual flickering between overlapping sprites at the same layer. Unstable sort is slightly faster but may swap equal-depth items between frames.
- `LDepthSorter:isStable`: Returns whether the sorter uses stable sorting.
- `LDepthSorter:clear`: Discard all pending entries without executing any draw callbacks. Use this when a scene is interrupted, reset, or destroyed before its normal `flush` call.
- `LDepthSorter:getCount`: Returns the number of draw entries currently queued for the next `flush` call. Useful for debugging or deciding whether to skip an empty render pass.
- `LDepthSorter:type`: Returns the type name string `"LDepthSorter"`.
- `LDepthSorter:typeOf`: Check whether this object matches a given type name. Accepts `"LDepthSorter"` or `"Object"`.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/scene/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
