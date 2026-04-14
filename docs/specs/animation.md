# animation

## General Info

- Module group: `Feature Systems`
- Source path: `src/animation/`
- Lua API path(s): `src/lua_api/animation_api.rs`
- Primary Lua namespace: `lurek.animation`
- Rust test path(s): tests/rust/unit/animation_tests.rs
- Lua test path(s): tests/lua/unit/test_animation.lua, tests/lua/stress/test_animation_stress.lua, tests/lua/integration/test_tween_animation.lua, tests/lua/integration/test_graphics_animation.lua, tests/lua/integration/test_animation_timer.lua, tests/lua/golden/test_animation_golden.lua

## Summary

The `animation` module provides Lurek2D's sprite animation system — the dedicated subsystem for describing how a textured sprite changes its source rectangle over time. It is a Foundations tier module that imports only from `crate::math`, making it usable in tests and non-rendering contexts without importing any platform services.

The core type is `Animation`, a controller that owns a flat pool of `AnimFrame` entries and any number of named `AnimClip` objects. A frame stores a source rectangle (the UV quad into the sprite sheet) and an optional per-frame duration override. A clip stores an ordered list of frame indices, a default frames-per-second rate, and a looping flag. Game code calls `add_frame` (or `add_frames_from_grid` for regular grids), registers clips with `add_clip`, then calls `play(clip_name)` each time a sprite state changes. On each game tick `update(dt)` advances the frame timer, emits `AnimEvent` notifications through a pending queue (for events like `ClipEnd` or `FrameReached`), and optionally performs crossfade transitions between clips.

Beyond the basic controller, the module ships: an `AnimStateMachine` for parameter-driven transitions between clips — named `AnimParamValue` parameters and `ConditionOp` comparisons drive `AnimTransition` edges; an Aseprite JSON parser (`aseprite.rs`) that loads Aseprite-exported frames and tags into the engine's native types; and `AnimRenderParams`, a lightweight struct packaging all information the render pipeline needs to draw one animated sprite frame.

The animation module has no knowledge of texture handles, entity IDs, or scene transforms — it works entirely with source rectangles and float timers.

**Scope boundary**: Foundations tier. Depends only on `math`. Lua bridge in `src/lua_api/animation_api.rs`.

## Files

- `aseprite.rs`: Aseprite JSON export parser for sprite animation data.
- `clip.rs`: Defines AnimClip, the named sequence of frame indices with clip FPS and looping behavior.
- `controller.rs`: Defines Animation, the main playback controller for frames, clips, speed, current state, and pending events.
- `event.rs`: Defines AnimEvent, the event enum emitted for frame changes, loops, and completion.
- `frame.rs`: Defines AnimFrame plus the AnimationFrame compatibility alias.
- `mod.rs`: Declares the animation submodules and re-exports the public frame, clip, controller, event, and render parameter types.
- `render.rs`: Converts the current animation frame into renderer-facing DrawQuad command data.
- `state_machine.rs`: Finite-state machine for sprite animation: states, transitions, and parameter-driven switching.

## Types

- `AsepriteFrameData` (`struct`, `aseprite.rs`): Pixel-level frame rectangle extracted from an Aseprite JSON export.
- `AsepriteDirection` (`enum`, `aseprite.rs`): Playback direction of an Aseprite frame tag.
- `AsepriteTagData` (`struct`, `aseprite.rs`): Frame tag (named clip range) from an Aseprite JSON export.
- `AsepriteParsed` (`struct`, `aseprite.rs`): Result of parsing an Aseprite JSON export.
- `AnimClip` (`struct`, `clip.rs`): Named ordered frame sequence with clip-local FPS and looping configuration.
- `Animation` (`struct`, `controller.rs`): Main playback controller that owns frames, clips, speed, timers, and pending events.
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

## Functions

- `load_aseprite_json` (`aseprite.rs`): Parses an Aseprite JSON export string into an [`AsepriteParsed`] result.
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

## Lua API Reference

- Binding path(s): `src/lua_api/animation_api.rs`
- Namespace: `lurek.animation`

### Module Functions
- `lurek.animation.new`: Creates a new, empty Animation controller.
- `lurek.animation.fromAseprite`: Parses an Aseprite JSON export string and builds an Animation with clips and frames.
- `lurek.animation.newStateMachine`: Creates an animation FSM from an Animation controller and an initial state name.

### `AnimStateMachine` Methods
- `AnimStateMachine:update`: Advances the FSM by `dt` seconds, evaluating transitions.
- `AnimStateMachine:getState`: Returns the name of the currently active state.
- `AnimStateMachine:forceState`: Immediately jumps to the named state, bypassing transition conditions.
- `AnimStateMachine:getQuad`: Returns the source quad for the current animation frame, or nil.

### `Animation` Methods
- `Animation:addFrame`: Adds a single frame to the frame pool by source rectangle.
- `Animation:addFramesFromGrid`: Slices a sprite-sheet grid into frames and appends them.
- `Animation:addClip`: Adds a named clip from explicit frame indices.
- `Animation:addClipFromGrid`: Adds a named clip sliced from a sprite-sheet grid.
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

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from ``Feature Systems`` into `Platform Services`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/animation/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
