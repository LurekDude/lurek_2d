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
- `AnimClip` (`struct`, `clip.rs`): Named ordered frame sequence with clip-local FPS and looping configuration.
- `Animation` (`struct`, `controller.rs`): Main playback controller that owns frames, clips, speed, timers, and pending events.
- `EasingKind` (`enum`, `curve.rs`): Interpolation mode applied between each pair of consecutive keyframes.
- `AnimCurve` (`struct`, `curve.rs`): A keyframe-based animation curve.
- `AnimEvent` (`enum`, `event.rs`): Playback event enum used to report frame changes, loops, and finished clips.
- `AnimFrame` (`struct`, `frame.rs`): One source rectangle plus an optional per-frame duration override.
- `AnimationFrame` (`type`, `frame.rs`): Backward-compatible alias for [`AnimFrame`].
- `AnimRenderParams` (`struct`, `render.rs`): Caller-supplied texture and transform bundle used when generating render commands.
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
- `BlendMask::all` (`blend.rs`): Creates a mask that affects all bones (no filtering).
- `BlendMask::from_bones` (`blend.rs`): Creates a mask restricted to the given bone names.
- `BlendMask::includes` (`blend.rs`): Returns `true` if this mask applies to the given bone name.
- `BlendLayer::new` (`blend.rs`): Creates a new blend layer.
- `BlendLayerSet::new` (`blend.rs`): Creates an empty blend layer set.
- `BlendLayerSet::len` (`blend.rs`): Returns the number of layers currently in the set.
- `BlendLayerSet::is_empty` (`blend.rs`): Returns `true` if the set contains no layers.
- `BlendLayerSet::add_layer` (`blend.rs`): Appends a new layer.
- `BlendLayerSet::remove_layer` (`blend.rs`): Removes a layer by name.
- `BlendLayerSet::set_weight` (`blend.rs`): Sets the blend weight of a layer.
- `BlendLayerSet::get_weight` (`blend.rs`): Returns the current weight of a layer, or `None` if not found.
- `BlendLayerSet::set_mask` (`blend.rs`): Replaces the bone mask of a layer.
- `BlendLayerSet::layers` (`blend.rs`): Returns a reference to the ordered layer list.
- `BlendLayerSet::get_layer` (`blend.rs`): Returns an immutable reference to a named layer, or `None`.
- `Animation::new` (`controller.rs`): Creates a new, empty animation with no frames or clips.
- `Animation::add_frame` (`controller.rs`): Adds a single frame and returns its 0-based index.
- `Animation::add_frames_from_grid` (`controller.rs`): Slices a sprite-sheet grid into frames and appends them.
- `Animation::add_clip` (`controller.rs`): Registers a named clip.
- `Animation::add_clip_from_grid` (`controller.rs`): Convenience method: adds grid-sliced frames then creates a clip referencing them.
- `Animation::play` (`controller.rs`): Starts playing a clip by name.
- `Animation::stop` (`controller.rs`): Stops playback and resets to frame 0.
- `Animation::pause` (`controller.rs`): Pauses playback at the current frame.
- `Animation::resume` (`controller.rs`): Resumes playback from the current frame.
- `Animation::update` (`controller.rs`): Advances the animation by `dt` seconds (scaled by [`speed`](Self::get_speed)).
- `Animation::current_quad` (`controller.rs`): Returns the source rectangle of the current frame, or `None` if no clip is active or the frame pool is empty.
- `Animation::current_frame` (`controller.rs`): Returns the current position within the active clip's frame list (0-based).
- `Animation::get_current_clip` (`controller.rs`): Returns the name of the currently active clip, if any.
- `Animation::is_playing` (`controller.rs`): Returns `true` if the animation is currently playing.
- `Animation::is_looping` (`controller.rs`): Returns `true` if the current clip is set to loop.
- `Animation::get_speed` (`controller.rs`): Returns the playback speed multiplier.
- `Animation::set_speed` (`controller.rs`): Sets the playback speed multiplier.
- `Animation::get_frame_count` (`controller.rs`): Returns the total number of frames in the animation's frame pool.
- `Animation::get_clip_count` (`controller.rs`): Returns the number of registered clips.
- `Animation::drain_events` (`controller.rs`): Returns and clears all pending animation events.
- `Animation::set_frame` (`controller.rs`): Sets the playback position within the current clip.
- `Animation::crossfade` (`controller.rs`): Starts a crossfade to another clip over the given duration in seconds.
- `Animation::get_blend_state` (`controller.rs`): Returns the current crossfade state as `(from_quad, to_quad, blend_weight)`.
- `Animation::draw_to_image` (`controller.rs`): Renders the current animation frame as a debug image.
- `Animation::load_from_aseprite` (`controller.rs`): Creates an [`Animation`] from an [`AsepriteParsed`] result.
- `AnimCurve::new` (`curve.rs`): Creates an empty `AnimCurve` with [`EasingKind::Linear`] interpolation.
- `AnimCurve::with_easing` (`curve.rs`): Creates an empty `AnimCurve` with the given easing kind.
- `AnimCurve::add_keyframe` (`curve.rs`): Adds a keyframe, keeping the internal list sorted by time.
- `AnimCurve::keyframe_count` (`curve.rs`): Returns the number of keyframes.
- `AnimCurve::clear` (`curve.rs`): Removes all keyframes.
- `AnimCurve::eval` (`curve.rs`): Evaluates the curve at the given time.
- `AnimEvent::type_name` (`event.rs`): Returns the event type as a Lua-friendly string.
- `AnimEvent::frame_index` (`event.rs`): Returns the frame index for `FrameChanged` events, or `None`.
- `Animation::generate_render_command` (`render.rs`): Produces a single `DrawQuad` render command for the current frame.
- `quad_to_draw_command` (`render.rs`): Converts a source quad and render parameters into a `DrawQuad` command.
- `AnimStateMachine::new` (`state_machine.rs`): Creates a new state machine with an owned animation and a named initial state.
- `AnimStateMachine::add_state` (`state_machine.rs`): Registers a named state mapping to a clip.
- `AnimStateMachine::add_transition` (`state_machine.rs`): Adds a transition rule by parsing a condition string.
- `AnimStateMachine::set_param_float` (`state_machine.rs`): Sets a float parameter.
- `AnimStateMachine::set_param_bool` (`state_machine.rs`): Sets a boolean parameter.
- `AnimStateMachine::set_param_int` (`state_machine.rs`): Sets an integer parameter.
- `AnimStateMachine::get_param` (`state_machine.rs`): Returns a reference to the current value of a named parameter.
- `AnimStateMachine::update` (`state_machine.rs`): Advances the animation by `dt` seconds and evaluates transitions.
- `AnimStateMachine::get_state` (`state_machine.rs`): Returns the name of the currently active state.
- `AnimStateMachine::force_state` (`state_machine.rs`): Forces a transition to the named state, playing the associated clip.
- `AnimStateMachine::get_animation` (`state_machine.rs`): Returns an immutable reference to the owned animation.
- `AnimStateMachine::get_animation_mut` (`state_machine.rs`): Returns a mutable reference to the owned animation.
- `compare_nums` (`state_machine.rs`): Applies a comparison operator to two `f32` values.
- `parse_condition` (`state_machine.rs`): Parses a condition string such as `"speed > 0.1"` or `"jumping == true"`.
- `AnimSyncGroup::new` (`sync_group.rs`): Creates an empty `AnimSyncGroup`.
- `AnimSyncGroup::add` (`sync_group.rs`): Adds an animation key to the group.
- `AnimSyncGroup::remove` (`sync_group.rs`): Removes an animation key from the group.
- `AnimSyncGroup::clear` (`sync_group.rs`): Removes all members from the group.
- `AnimSyncGroup::member_count` (`sync_group.rs`): Returns the number of animation keys currently in the group.
- `AnimSyncGroup::members` (`sync_group.rs`): Returns a reference to the member key slice.

## Lua API Reference

- Binding path(s): `src/lua_api/animation_api.rs`
- Namespace: `lurek.animation`

### Module Functions
- `lurek.animation.new`: Creates a new, empty Animation controller.
- `lurek.animation.fromAseprite`: Parses an Aseprite JSON export string and builds an animation.
- `lurek.animation.newStateMachine`: Creates an animation FSM from an Animation controller and an initial state name.
- `lurek.animation.newCurve`: Creates a new empty animation curve with linear interpolation.
- `lurek.animation.newSyncGroup`: Creates a new empty animation sync group.
- `lurek.animation.newBlendLayerSet`: Creates a new empty blend layer set for compositing multiple animation clips.
- `lurek.animation.buildCharacter`: Builds an `Animation` plus optional `AnimStateMachine` from one config table.

### `LAnimCurve` Methods
- `LAnimCurve:addKeyframe`: Inserts or replaces a keyframe at the given time.
- `LAnimCurve:eval`: Returns the interpolated curve value at the given time.
- `LAnimCurve:setEasing`: Sets the easing kind applied between all keyframe segments.
- `LAnimCurve:keyframeCount`: Returns the number of keyframes currently stored.
- `LAnimCurve:setCustomEasing`: Sets or clears a custom Lua easing function for this curve.
- `LAnimCurve:clear`: Removes all keyframes from this animation curve, resetting it to empty.
- `LAnimCurve:type`: Returns the type name of this object.
- `LAnimCurve:typeOf`: Returns true if this object is of the given type.

### `LAnimStateMachine` Methods
- `LAnimStateMachine:update`: Advances the FSM by `dt` seconds, evaluating transitions.
- `LAnimStateMachine:getState`: Returns the name of the currently active state.
- `LAnimStateMachine:forceState`: Immediately jumps to the named state, bypassing transition conditions.
- `LAnimStateMachine:addState`: Registers a new named state that plays a clip from the embedded animation.
- `LAnimStateMachine:addTransition`: Adds a conditional transition between two states using a condition string like "speed > 0.5".
- `LAnimStateMachine:setParam`: Sets an FSM parameter value (number, boolean, or integer supported).
- `LAnimStateMachine:getQuad`: Returns the source quad for the current animation frame.
- `LAnimStateMachine:type`: Returns the type name of this object.
- `LAnimStateMachine:typeOf`: Returns true if this object is of the given type.

### `LAnimSyncGroup` Methods
- `LAnimSyncGroup:add`: Adds an animation handle to the group.
- `LAnimSyncGroup:remove`: Removes an animation handle from the group.
- `LAnimSyncGroup:clear`: Removes all animation handles from the group.
- `LAnimSyncGroup:memberCount`: Returns the number of animations currently in the group.
- `LAnimSyncGroup:type`: Returns the type name of this object.
- `LAnimSyncGroup:typeOf`: Returns true if this object is of the given type.

### `LAnimation` Methods
- `LAnimation:addFrame`: Adds a single frame to the frame pool by source rectangle.
- `LAnimation:addFramesFromGrid`: Slices a sprite-sheet grid into frames and appends them.
- `LAnimation:addFramesFromRects`: Appends frames from pre-computed source rectangles.
- `LAnimation:addClip`: Adds a named clip from explicit frame indices, optionally including playback mode.
- `LAnimation:addClipFromGrid`: Adds a named clip sliced from a sprite-sheet grid.
- `LAnimation:setClipMode`: Sets playback mode for a named clip.
- `LAnimation:getClipMode`: Returns playback mode for a named clip.
- `LAnimation:play`: Starts playback of the named clip.
- `LAnimation:stop`: Stops playback and resets to frame 0.
- `LAnimation:pause`: Pauses playback at the current frame.
- `LAnimation:resume`: Resumes playback from the current frame.
- `LAnimation:update`: Advances the animation by dt seconds.
- `LAnimation:getQuad`: Returns the source quad for the current frame.
- `LAnimation:pollEvents`: Drains and returns all pending animation events as a table.
- `LAnimation:isPlaying`: Returns true if a clip is currently playing.
- `LAnimation:isLooping`: Returns true if the current clip is set to loop.
- `LAnimation:getClip`: Returns the name of the currently playing clip.
- `LAnimation:getSpeed`: Returns the playback speed multiplier.
- `LAnimation:setSpeed`: Sets the playback speed multiplier.
- `LAnimation:getFrameCount`: Returns the total number of frames in the frame pool.
- `LAnimation:getClipCount`: Returns the number of registered clips.
- `LAnimation:getCurrentFrame`: Returns the current position within the active clip (0-based).
- `LAnimation:setFrame`: Sets the playback position within the current clip.
- `LAnimation:crossfade`: Begins a smooth crossfade from the current clip to a new named clip.
- `LAnimation:getBlendState`: Returns the active crossfade state.
- `LAnimation:drawToImage`: Renders the current animation frame into a new ImageData (white bg, blue frame rect).
- `LAnimation:drawPreviewGrid`: Renders all animation frames into a grid preview ImageData.
- `LAnimation:type`: Returns the type name of this object.
- `LAnimation:typeOf`: Returns true if this object is of the given type.

### `LBlendLayerSet` Methods
- `LBlendLayerSet:addLayer`: Appends a new blend layer.
- `LBlendLayerSet:removeLayer`: Removes a blend layer by name.
- `LBlendLayerSet:setWeight`: Sets the blend weight of a named layer (clamped to [0, 1]).
- `LBlendLayerSet:getWeight`: Returns the blend weight of a named layer.
- `LBlendLayerSet:setMask`: Replaces the bone mask of a layer.
- `LBlendLayerSet:listLayers`: Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
- `LBlendLayerSet:len`: Returns the number of blend layers.
- `LBlendLayerSet:type`: Returns the type name of this object.
- `LBlendLayerSet:typeOf`: Returns true if this object is of the given type.

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from ``Feature Systems`` into `Platform Services`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/animation/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
