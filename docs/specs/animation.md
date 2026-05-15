# animation

## General Info

- Module group: `Feature Systems`
- Source path: `src/animation/`
- Lua API path(s): `src/lua_api/animation_api.rs`
- Primary Lua namespace: `lurek.animation`
- Rust test path(s): tests/rust/unit/animation_tests.rs
- Lua test path(s): tests/lua/unit/test_animation.lua, tests/lua/stress/test_animation_stress.lua, tests/lua/integration/test_tween_animation.lua, tests/lua/integration/test_render_animation.lua, tests/lua/integration/test_animation_timer.lua, tests/lua/golden/test_animation_golden.lua

## Summary

The `animation` module is Lurek2D's sprite animation system — a Foundations tier subsystem dedicated to describing how a textured sprite changes its source rectangle over time. It imports only from `crate::math`, so it can run in unit tests and non-rendering contexts without any platform services or GPU state.

**Core playback.** `Animation` is the main controller. It owns a flat pool of `AnimFrame` entries (each a source rectangle into a sprite sheet with an optional per-frame duration override) and any number of named `AnimClip` objects (an ordered list of frame indices, a default FPS rate, a looping flag, and an explicit playback mode: `forward`, `reverse`, or `pingpong`). Typical usage: `add_frame` or `add_frames_from_grid` for atlas layouts, then `add_clip` to register named states, then `play(clip_name)` when sprite state changes. `update(dt)` advances the frame timer, emits `AnimEvent` notifications via a pending queue (`ClipEnd`, `FrameReached`, `ClipLoop`), and applies crossfade transitions between clips.

**State machine.** `AnimStateMachine` provides parameter-driven transitions between clips. `AnimParamValue` holds boolean, integer, or float values. `AnimTransition` edges carry a `TransitionCondition` (parameter name, `ConditionOp`, threshold) — the machine evaluates all outgoing transitions from the current state each update tick and switches automatically when a condition fires. `AnimStateConfig` stores per-state clip name, transition priority, and optional blend-in duration.

**Blend layers.** `BlendLayerSet` composites multiple animation clips on a single sprite with per-layer blend weights and optional `BlendMask` bone-subset filtering. Layers are ordered and evaluated additively, enabling upper/lower body split animations or damage-overlay blending without a separate entity.

**Animation curves.** `AnimCurve` is a keyframe-based procedural animation curve. Keyframes store (time, value) pairs; adjacent pairs define segments with a configurable `EasingKind` interpolation mode (Linear, QuadIn, QuadOut, QuadInOut, CubicIn, CubicOut, CubicInOut, Sine, Bounce, Custom). Curves drive rotation, scale, alpha, or any float property independently of sprite-sheet frames.

**Sync groups.** `AnimSyncGroup` coordinates playback timing across multiple `Animation` instances so separate sprites (e.g., a character's body and shadow) advance in lock-step. `set_phase(t)` and `advance(dt)` synchronise all registered handles.

**Aseprite importer.** `aseprite.rs` parses Aseprite JSON export strings (`load_aseprite_json`) into `AsepriteParsed` — a list of `AsepriteFrameData` source rectangles and `AsepriteTagData` named clip ranges — and then populates the engine's native `Animation` type.

**Render integration.** `AnimRenderParams` packages all data the render pipeline needs to draw one frame: texture key, source rect, destination transform, and flip flags. The module itself never issues draw calls; it only produces parameters consumed by `render`.

**Lua surface.** `lurek.animation.new()` creates an `Animation`. `lurek.animation.newStateMachine()`, `lurek.animation.newCurve()`, `lurek.animation.newSyncGroup()`, and `lurek.animation.newBlendLayerSet()` expose the additional subsystems. `lurek.animation.fromAseprite(json_string)` parses Aseprite exports. `lurek.animation.buildCharacter(cfg)` builds a common animation+FSM bundle from one configuration table. All returned userdatas are fully scriptable with their complete method sets.

**Scope boundary.** Foundations tier. Depends only on `math`. Lua bridge in `src/lua_api/animation_api.rs`.

## Files

- `aseprite.rs`: Aseprite JSON export parser for sprite animation data.
- `blend.rs`: Blend-layer system for compositing multiple animation clips on a single sprite.
- `clip.rs`: Defines AnimClip, the named sequence of frame indices with clip FPS and looping behavior.
- `controller.rs`: Defines Animation, the main playback controller for frames, clips, speed, current state, and pending events.
- `curve.rs`: Keyframe-based animation curves with per-segment easing.
- `event.rs`: Defines AnimEvent, the event enum emitted for frame changes, loops, and completion.
- `frame.rs`: Defines AnimFrame plus the AnimationFrame compatibility alias.
- `mod.rs`: Declares the animation submodules and re-exports the public frame, clip, controller, event, and render parameter types.
- `render.rs`: Converts the current animation frame into renderer-facing DrawQuad command data.
- `spine_bridge.rs`: - Bridges a Spine skeleton to an animation state machine via name mapping.
- `state_machine.rs`: Finite-state machine for sprite animation: states, transitions, and parameter-driven switching.
- `sync_group.rs`: Named animation synchronisation groups.

## Types

- `AsepriteFrameData` (`struct`, `aseprite.rs`): Pixel-level frame rectangle extracted from an Aseprite JSON export.
- `AsepriteDirection` (`enum`, `aseprite.rs`): Playback direction of an Aseprite frame tag.
- `AsepriteTagData` (`struct`, `aseprite.rs`): Frame tag (named clip range) from an Aseprite JSON export.
- `AsepriteParsed` (`struct`, `aseprite.rs`): Result of parsing an Aseprite JSON export.
- `BlendMask` (`struct`, `blend.rs`): Restricts a [`BlendLayer`] to a named subset of bone or joint identifiers.
- `BlendLayer` (`struct`, `blend.rs`): One layer in a [`BlendLayerSet`]: a named clip at a given blend weight.
- `BlendLayerSet` (`struct`, `blend.rs`): Ordered set of blend layers for a single sprite's animation.
- `ClipPlaybackMode` (`enum`, `clip.rs`): Supported clip playback modes.
- `AnimClip` (`struct`, `clip.rs`): Named ordered frame sequence with clip-local FPS and looping configuration.
- `Animation` (`struct`, `controller.rs`): Main playback controller that owns frames, clips, speed, timers, and pending events.
- `EasingKind` (`enum`, `curve.rs`): Interpolation mode applied between each pair of consecutive keyframes.
- `AnimCurve` (`struct`, `curve.rs`): A keyframe-based animation curve.
- `AnimPropertyTimeline` (`struct`, `curve.rs`): Sparse multi-property timeline keyed by property name.
- `AnimEvent` (`enum`, `event.rs`): Playback event enum used to report frame changes, loops, and finished clips.
- `AnimFrame` (`struct`, `frame.rs`): One source rectangle plus an optional per-frame duration override.
- `AnimationFrame` (`type`, `frame.rs`): Backward-compatible alias for [`AnimFrame`].
- `AnimRenderParams` (`struct`, `render.rs`): Caller-supplied texture and transform bundle used when generating render commands.
- `SpineAnimBridge` (`struct`, `spine_bridge.rs`): Maps FSM state names to Spine animation clips.
- `AnimParamValue` (`enum`, `state_machine.rs`): Value held by an animation parameter.
- `ConditionOp` (`enum`, `state_machine.rs`): Comparison operator for a transition condition.
- `ConditionValue` (`enum`, `state_machine.rs`): Right-hand side value for a transition condition.
- `TransitionCondition` (`struct`, `state_machine.rs`): A single condition on one named parameter.
- `AnimTransition` (`struct`, `state_machine.rs`): A directed state transition with a single condition.
- `AnimStateConfig` (`struct`, `state_machine.rs`): Configuration for a single state in the state machine.
- `AnimStateMachine` (`struct`, `state_machine.rs`): Parameter-driven finite-state machine for animation control.
- `AnimSyncGroup` (`struct`, `sync_group.rs`): A named set of animation keys that advance in lock-step.

## Functions

- `load_aseprite_json` (`aseprite.rs`): Parses an Aseprite JSON export string into an [`AsepriteParsed`] result.
- `BlendMask::all` (`blend.rs`): Create a mask that includes all bones.
- `BlendMask::from_bones` (`blend.rs`): Create a mask from an explicit bone list.
- `BlendMask::includes` (`blend.rs`): Return `true` when the mask includes `bone`.
- `BlendLayer::new` (`blend.rs`): Create a blend layer with clamped weight.
- `BlendLayerSet::new` (`blend.rs`): Create an empty layer set.
- `BlendLayerSet::len` (`blend.rs`): Return the number of layers.
- `BlendLayerSet::is_empty` (`blend.rs`): Return `true` when no layers are stored.
- `BlendLayerSet::add_layer` (`blend.rs`): Add a layer; returns an error when the name already exists.
- `BlendLayerSet::remove_layer` (`blend.rs`): Remove a layer by name.
- `BlendLayerSet::set_weight` (`blend.rs`): Set a layer's weight and clamp it to `[0, 1]`.
- `BlendLayerSet::get_weight` (`blend.rs`): Return a layer's weight, or `None` when missing.
- `BlendLayerSet::set_mask` (`blend.rs`): Replace a layer's mask.
- `BlendLayerSet::layers` (`blend.rs`): Return the stored layers.
- `BlendLayerSet::get_layer` (`blend.rs`): Return a layer by name.
- `Animation::new` (`controller.rs`): Create an empty animation controller.
- `Animation::add_frame` (`controller.rs`): Append a frame and return its index.
- `Animation::add_frames_from_grid` (`controller.rs`): Append frames from a texture grid and return the number added.
- `Animation::add_frames_from_rects` (`controller.rs`): Append a list of frame rectangles and return the number added.
- `Animation::add_clip` (`controller.rs`): Add a forward-playing clip.
- `Animation::add_clip_with_mode` (`controller.rs`): Add a clip with an explicit playback mode.
- `Animation::add_clip_from_grid` (`controller.rs`): Create frames from a grid and register a clip that references them.
- `Animation::play` (`controller.rs`): Start playing a named clip; returns `false` when the clip is missing.
- `Animation::stop` (`controller.rs`): Stop playback and reset the frame position.
- `Animation::pause` (`controller.rs`): Pause playback without resetting the frame position.
- `Animation::resume` (`controller.rs`): Resume playback.
- `Animation::update` (`controller.rs`): Advance playback timers and emit frame events.
- `Animation::current_quad` (`controller.rs`): Return the current frame quad, or `None` when playback is unset.
- `Animation::current_frame` (`controller.rs`): Return the current frame index inside the clip.
- `Animation::get_current_clip` (`controller.rs`): Return the current clip name.
- `Animation::is_playing` (`controller.rs`): Return `true` when playback is active.
- `Animation::is_looping` (`controller.rs`): Return `true` when the active clip loops.
- `Animation::get_speed` (`controller.rs`): Return the playback speed multiplier.
- `Animation::set_speed` (`controller.rs`): Set the playback speed multiplier.
- `Animation::get_frame_count` (`controller.rs`): Return the number of loaded frames.
- `Animation::get_frame_quad` (`controller.rs`): Return the quad for frame `index`.
- `Animation::get_clip_count` (`controller.rs`): Return the number of registered clips.
- `Animation::get_clip` (`controller.rs`): Return a clip by name.
- `Animation::get_clip_mut` (`controller.rs`): Return a clip by name mutably.
- `Animation::drain_events` (`controller.rs`): Drain and return the pending playback events.
- `Animation::set_frame` (`controller.rs`): Force the current clip frame index.
- `Animation::crossfade` (`controller.rs`): Start a crossfade to another clip; returns `false` if the clip is missing.
- `Animation::get_blend_state` (`controller.rs`): Return the active crossfade state as `(from, to, blend)` when a blend is running.
- `Animation::draw_to_image` (`controller.rs`): Draw a simple preview image for the current frame.
- `Animation::draw_preview_grid` (`controller.rs`): Draw a grid preview of all loaded frames.
- `Animation::load_from_aseprite` (`controller.rs`): Build an `Animation` from parsed Aseprite metadata.
- `AnimCurve::new` (`curve.rs`): Create an empty curve with linear easing.
- `AnimCurve::with_easing` (`curve.rs`): Create an empty curve with the given easing.
- `AnimCurve::add_keyframe` (`curve.rs`): Insert or replace a keyframe while keeping the list sorted.
- `AnimCurve::keyframe_count` (`curve.rs`): Return the number of keyframes.
- `AnimCurve::clear` (`curve.rs`): Remove all keyframes.
- `AnimCurve::eval` (`curve.rs`): Evaluate the curve at time `t`.
- `AnimPropertyTimeline::new` (`curve.rs`): Create an empty timeline with linear easing.
- `AnimPropertyTimeline::add_keyframe` (`curve.rs`): Insert a keyframe with one or more property values.
- `AnimPropertyTimeline::property_names` (`curve.rs`): Return the list of property names.
- `AnimPropertyTimeline::keyframe_count` (`curve.rs`): Return the number of timeline keyframes.
- `AnimPropertyTimeline::eval_property` (`curve.rs`): Evaluate one property at time `t`.
- `AnimPropertyTimeline::eval_all` (`curve.rs`): Evaluate all properties at time `t`.
- `AnimEvent::type_name` (`event.rs`): Return the canonical event type name.
- `AnimEvent::frame_index` (`event.rs`): Return the frame index for `FrameChanged`, or `None` for other events.
- `AnimFrame::new` (`frame.rs`): Create a new animation frame.
- `Animation::generate_render_command` (`render.rs`): Build a draw command for the current frame when the animation has an active quad.
- `quad_to_draw_command` (`render.rs`): Converts a source quad and render parameters into a `DrawQuad` command.
- `SpineAnimBridge::new` (`spine_bridge.rs`): Create a bridge for a skeleton.
- `SpineAnimBridge::map` (`spine_bridge.rs`): Map a FSM state to a skeleton clip.
- `SpineAnimBridge::map_looping` (`spine_bridge.rs`): Map a FSM state to a skeleton clip and set its looping override.
- `SpineAnimBridge::update` (`spine_bridge.rs`): Advance the FSM and play the mapped Spine animation when the state changes.
- `SpineAnimBridge::skeleton` (`spine_bridge.rs`): Return the current skeleton.
- `SpineAnimBridge::skeleton_mut` (`spine_bridge.rs`): Return the skeleton mutably.
- `SpineAnimBridge::last_applied_state` (`spine_bridge.rs`): Return the last applied FSM state.
- `SpineAnimBridge::get_mapped_clip` (`spine_bridge.rs`): Return the mapped clip for a FSM state.
- `AnimStateMachine::new` (`state_machine.rs`): Create a state machine with an initial state name.
- `AnimStateMachine::add_state` (`state_machine.rs`): Register a state and its clip mapping.
- `AnimStateMachine::add_transition` (`state_machine.rs`): Parse and register a transition condition.
- `AnimStateMachine::set_param_float` (`state_machine.rs`): Set a float parameter.
- `AnimStateMachine::set_param_bool` (`state_machine.rs`): Set a bool parameter.
- `AnimStateMachine::set_param_int` (`state_machine.rs`): Set an integer parameter.
- `AnimStateMachine::get_param` (`state_machine.rs`): Return a parameter by name.
- `AnimStateMachine::update` (`state_machine.rs`): Advance the animation and process transition chains.
- `AnimStateMachine::get_state` (`state_machine.rs`): Return the current state name.
- `AnimStateMachine::force_state` (`state_machine.rs`): Force a transition to `name`; returns `false` when the state is unknown or clip play fails.
- `AnimStateMachine::get_animation` (`state_machine.rs`): Return the owned animation controller.
- `AnimStateMachine::get_animation_mut` (`state_machine.rs`): Return the owned animation controller mutably.
- `compare_nums` (`state_machine.rs`): Applies a comparison operator to two `f32` values.
- `parse_condition` (`state_machine.rs`): Parses a condition string such as `"speed > 0.1"` or `"jumping == true"`.
- `AnimSyncGroup::new` (`sync_group.rs`): Create an empty sync group.
- `AnimSyncGroup::add` (`sync_group.rs`): Add `key` when it is not already present.
- `AnimSyncGroup::remove` (`sync_group.rs`): Remove `key` from the group.
- `AnimSyncGroup::clear` (`sync_group.rs`): Remove all members.
- `AnimSyncGroup::member_count` (`sync_group.rs`): Return the number of members.
- `AnimSyncGroup::members` (`sync_group.rs`): Return the member slice.

## Lua API Reference

- Binding path(s): `src/lua_api/animation_api.rs`
- Namespace: `lurek.animation`

### Module Functions
- `lurek.animation.new`: Creates an empty animation with no frames or clips.
- `lurek.animation.fromAseprite`: Loads an animation from an Aseprite JSON export string.
- `lurek.animation.newStateMachine`: Creates an animation state machine by consuming an animation handle.
- `lurek.animation.newCurve`: Creates an empty animation curve.
- `lurek.animation.newSyncGroup`: Creates an empty animation synchronization group.
- `lurek.animation.newBlendLayerSet`: Creates an empty blend layer set for layered animation playback.
- `lurek.animation.buildCharacter`: Builds a character animation bundle from grid frame and clip configuration.

### `LAnimCurve` Methods
- `LAnimCurve:addKeyframe`: Adds a keyframe to the curve.
- `LAnimCurve:eval`: Evaluates the curve at a time or normalized position.
- `LAnimCurve:setEasing`: Sets the built-in easing mode used between keyframes.
- `LAnimCurve:keyframeCount`: Returns the number of keyframes stored in this curve.
- `LAnimCurve:setCustomEasing`: Sets or clears a Lua callback used to evaluate custom easing.
- `LAnimCurve:clear`: Removes all keyframes from this curve.
- `LAnimCurve:type`: Returns the Lua-visible type name for this animation curve handle.
- `LAnimCurve:typeOf`: Returns whether this animation curve handle matches a supported type name.

### `LAnimStateMachine` Methods
- `LAnimStateMachine:update`: Advances the animation state machine and its owned animation playback.
- `LAnimStateMachine:getState`: Returns the current animation state name.
- `LAnimStateMachine:forceState`: Forces the state machine into a named state.
- `LAnimStateMachine:addState`: Adds a state that plays a named animation clip.
- `LAnimStateMachine:addTransition`: Adds a named-condition transition between two animation states.
- `LAnimStateMachine:setParam`: Sets a boolean, integer, or numeric state machine parameter.
- `LAnimStateMachine:getQuad`: Returns the current frame rectangle from the state machine's owned animation.
- `LAnimStateMachine:type`: Returns the Lua-visible type name for this animation state machine handle.
- `LAnimStateMachine:typeOf`: Returns whether this animation state machine handle matches a supported type name.

### `LAnimSyncGroup` Methods
- `LAnimSyncGroup:add`: Adds an animation-like handle to the sync group.
- `LAnimSyncGroup:remove`: Removes an animation-like handle from the sync group.
- `LAnimSyncGroup:clear`: Removes all members from the sync group.
- `LAnimSyncGroup:memberCount`: Returns the number of handles tracked by the sync group.
- `LAnimSyncGroup:type`: Returns the Lua-visible type name for this animation sync group handle.
- `LAnimSyncGroup:typeOf`: Returns whether this animation sync group handle matches a supported type name.

### `LAnimation` Methods
- `LAnimation:addFrame`: Adds one frame rectangle to this animation.
- `LAnimation:addFramesFromGrid`: Adds frames by slicing a texture grid.
- `LAnimation:addFramesFromRects`: Adds frames from an array of rectangle tables.
- `LAnimation:addClip`: Adds a named clip using existing frame indices.
- `LAnimation:setClipMode`: Changes the playback mode for an existing clip.
- `LAnimation:getClipMode`: Returns the playback mode name for a clip when it exists.
- `LAnimation:addClipFromGrid`: Adds frames from a texture grid and creates a clip that references the new frames.
- `LAnimation:play`: Starts playback of a named clip.
- `LAnimation:stop`: Stops playback and resets animation playback state.
- `LAnimation:pause`: Pauses animation playback without changing the current clip.
- `LAnimation:resume`: Resumes playback of a paused animation.
- `LAnimation:update`: Advances animation playback and records any frame or clip events.
- `LAnimation:getQuad`: Returns the current frame rectangle as a table.
- `LAnimation:pollEvents`: Drains animation events produced since the previous poll.
- `LAnimation:isPlaying`: Returns whether this animation is currently playing.
- `LAnimation:isLooping`: Returns whether the current clip loops.
- `LAnimation:getClip`: Returns the current clip name when a clip is active.
- `LAnimation:getSpeed`: Returns the animation playback speed multiplier.
- `LAnimation:setSpeed`: Sets the animation playback speed multiplier.
- `LAnimation:getFrameCount`: Returns the number of frame rectangles stored in this animation.
- `LAnimation:getClipCount`: Returns the number of named clips stored in this animation.
- `LAnimation:getCurrentFrame`: Returns the current frame index.
- `LAnimation:setFrame`: Sets the current frame index directly.
- `LAnimation:crossfade`: Starts a crossfade from the current clip to another clip.
- `LAnimation:getBlendState`: Returns current crossfade rectangles and blend factor when a crossfade is active.
- `LAnimation:drawToImage`: Rasterizes the current animation frame into an image userdata.
- `LAnimation:drawPreviewGrid`: Rasterizes all animation frames into a preview grid image.
- `LAnimation:type`: Returns the Lua-visible type name for this animation handle.
- `LAnimation:typeOf`: Returns whether this animation handle matches a supported type name.

### `LBlendLayerSet` Methods
- `LBlendLayerSet:addLayer`: Adds a weighted animation blend layer with an optional bone mask.
- `LBlendLayerSet:removeLayer`: Removes a blend layer by name.
- `LBlendLayerSet:setWeight`: Sets the blend weight for an existing layer.
- `LBlendLayerSet:getWeight`: Returns the weight for a blend layer when it exists.
- `LBlendLayerSet:setMask`: Replaces a layer bone mask from a table of bone names.
- `LBlendLayerSet:listLayers`: Returns all blend layers with names, clip names, weights, and bone masks.
- `LBlendLayerSet:len`: Returns the number of blend layers.
- `LBlendLayerSet:type`: Returns the Lua-visible type name for this blend layer set handle.
- `LBlendLayerSet:typeOf`: Returns whether this blend layer set handle matches a supported type name.

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from ``Feature Systems`` into `Platform Services`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.
- `spine`: Imports or references `src/spine/`. Dependency stays inside `Feature Systems` and should remain acyclic.

## Notes

- Keep this module reference synchronized with `src/animation/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
