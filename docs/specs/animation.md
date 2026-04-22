# animation

## General Info

- Module group: `Feature Systems`
- Source path: `src/animation/`
- Lua API path(s): `src/lua_api/animation_api.rs`
- Primary Lua namespace: `lurek.animation`
- Rust test path(s): tests/rust/unit/animation_tests.rs
- Lua test path(s): tests/lua/unit/test_animation.lua, tests/lua/stress/test_animation_stress.lua, tests/lua/integration/test_tween_animation.lua, tests/lua/integration/test_render_animation.lua, tests/lua/integration/test_animation_timer.lua, tests/lua/golden/test_animation_golden.lua

## Summary

The `animation` module provides Lurek2D's sprite animation system — the dedicated subsystem for describing how a textured sprite changes its source rectangle over time. It is a Foundations tier module that imports only from `crate::math`, making it usable in tests and non-rendering contexts without importing any platform services.

The core type is `Animation`, a controller that owns a flat pool of `AnimFrame` entries and any number of named `AnimClip` objects. A frame stores a source rectangle (the UV quad into the sprite sheet) and an optional per-frame duration override. A clip stores an ordered list of frame indices, a default frames-per-second rate, and a looping flag. Game code calls `add_frame` (or `add_frames_from_grid` for regular grids), registers clips with `add_clip`, then calls `play(clip_name)` each time a sprite state changes. On each game tick `update(dt)` advances the frame timer, emits `AnimEvent` notifications through a pending queue (for events like `ClipEnd` or `FrameReached`), and optionally performs crossfade transitions between clips.

Beyond the basic controller, the module ships: an `AnimStateMachine` for parameter-driven transitions between clips — named `AnimParamValue` parameters and `ConditionOp` comparisons drive `AnimTransition` edges; an Aseprite JSON parser (`aseprite.rs`) that loads Aseprite-exported frames and tags into the engine's native types; and `AnimRenderParams`, a lightweight struct packaging all information the render pipeline needs to draw one animated sprite frame.

The animation module has no knowledge of texture handles, entity IDs, or scene transforms — it works entirely with source rectangles and float timers.

Three new source files extend the module's capabilities. `blend.rs` introduces `BlendMask`, `BlendLayer`, and `BlendLayerSet` for compositing multiple animation clips on a single sprite with per-layer blend weights and optional bone-subset masks. `curve.rs` introduces `AnimCurve` and `EasingKind` for keyframe-based procedural animation curves with per-segment interpolation modes. `sync_group.rs` introduces `AnimSyncGroup` for coordinating playback timing across multiple animation instances, ensuring that separate sprites advance in lock-step. Lua callers access these through `lurek.animation.newCurve()`, `lurek.animation.newSyncGroup()`, and `lurek.animation.newBlendLayerSet()`, each returning a fully scriptable userdata with its own method set.

**Scope boundary**: Foundations tier. Depends only on `math`. Lua bridge in `src/lua_api/animation_api.rs`.

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
- `lurek.animation.fromAseprite`: Parses an Aseprite JSON export string and builds an Animation with clips and frames.
- `lurek.animation.newStateMachine`: Creates an animation FSM from an Animation controller and an initial state name.
- `lurek.animation.newCurve`: Creates a new empty [`AnimCurve`] with linear interpolation.
- `lurek.animation.newSyncGroup`: Creates a new empty [`AnimSyncGroup`].
- `lurek.animation.newBlendLayerSet`: Creates a new empty [`BlendLayerSet`] for compositing multiple animation clips.

### `AnimCurve` Methods
- `AnimCurve:addKeyframe`: Inserts a keyframe at the given time. If a keyframe at the same time already
- `AnimCurve:eval`: Returns the interpolated value at the given time using the curve's easing.
- `AnimCurve:setEasing`: Sets the easing kind applied between all keyframe segments.
- `AnimCurve:keyframeCount`: Returns the number of keyframes currently stored.
- `AnimCurve:setCustomEasing`: Set a custom Lua easing function for this curve.
- `AnimCurve:clear`: Removes all keyframes from this animation curve, resetting it to empty.

### `AnimStateMachine` Methods
- `AnimStateMachine:update`: Advances the FSM by `dt` seconds, evaluating transitions.
- `AnimStateMachine:getState`: Returns the name of the currently active state.
- `AnimStateMachine:forceState`: Immediately jumps to the named state, bypassing transition conditions.
- `AnimStateMachine:setParam`: Sets an FSM parameter value (number, boolean, or integer supported).
- `AnimStateMachine:getQuad`: Returns the source quad for the current animation frame, or nil.

### `AnimSyncGroup` Methods
- `AnimSyncGroup:add`: Adds an animation handle to the group.
- `AnimSyncGroup:remove`: Removes an animation handle from the group.
- `AnimSyncGroup:clear`: Removes all animation handles from the group.
- `AnimSyncGroup:memberCount`: Returns the number of animations currently in the group.

### `Animation` Methods
- `Animation:addFrame`: Adds a single frame to the frame pool by source rectangle.
- `Animation:play`: Starts playback of the named clip.
- `Animation:stop`: Stops playback and resets to frame 0.
- `Animation:pause`: Pauses playback at the current frame.
- `Animation:resume`: Resumes playback from the current frame.
- `Animation:update`: Advances the animation by dt seconds.
- `Animation:getQuad`: Returns the source quad (x, y, w, h) for the current frame, or nil.
- `Animation:pollEvents`: Drains and returns all pending animation events as a table.
- `Animation:isPlaying`: Returns true if a clip is currently playing.
- `Animation:isLooping`: Returns true if the current clip is set to loop.
- `Animation:getClip`: Returns the name of the currently playing clip, or nil.
- `Animation:getSpeed`: Returns the playback speed multiplier.
- `Animation:setSpeed`: Sets the playback speed multiplier.
- `Animation:getFrameCount`: Returns the total number of frames in the frame pool.
- `Animation:getClipCount`: Returns the number of registered clips.
- `Animation:getCurrentFrame`: Returns the current position within the active clip (0-based).
- `Animation:setFrame`: Sets the playback position within the current clip.
- `Animation:getBlendState`: Returns the two quads and blend factor during a crossfade, or nil when not blending.
- `Animation:drawToImage`: Renders the current animation frame into a new ImageData (white bg, blue frame rect).

### `BlendLayerSet` Methods
- `BlendLayerSet:removeLayer`: Removes a blend layer by name.
- `BlendLayerSet:setWeight`: Sets the blend weight of a named layer (clamped to [0, 1]).
- `BlendLayerSet:getWeight`: Returns the blend weight of a named layer, or nil if not found.
- `BlendLayerSet:setMask`: Replaces the bone mask of a layer.
- `BlendLayerSet:listLayers`: Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
- `BlendLayerSet:len`: Returns the number of blend layers.

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from ``Feature Systems`` into `Platform Services`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/animation/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
