# tween

## General Info

- Module group: `Feature Systems`
- Source path: `src/tween/`
- Lua API path(s): `src/lua_api/tween_api.rs`
- Primary Lua namespace: `lurek.tween`
- Rust test path(s): tests/rust/unit/tween_tests.rs
- Lua test path(s): tests/lua/unit/test_tween.lua, tests/lua/stress/test_tween_stress.lua, tests/lua/integration/test_tween_ecs.lua, tests/lua/integration/test_tween_camera.lua, tests/lua/integration/test_tween_animation.lua

## Summary

The `tween` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `math`. Its responsibility should stay inside the Feature Systems group rather than absorb behavior owned by those neighbors.

## Files

- `engine.rs`: Defines `TweenEngine`, the active-object pool that ticks live tween handles and releases them when done.
- `handle.rs`: Defines the Lua-backed domain handle types for single tweens, sequences, parallel groups, and their step or entry records.
- `mod.rs`: Declares the tween submodules and re-exports the core timing state, handle types, and engine.
- `spring.rs`: Physics-based spring interpolation for the `lurek.tween` system.
- `state.rs`: Defines `TweenState` plus built-in easing lookup and easing-name enumeration.

## Types

- `TweenEngine` (`struct`, `engine.rs`): The active tween pool that updates all registered tweens, sequences, and parallel groups each frame.
- `LuaTween` (`struct`, `handle.rs`): The single-property-group tween handle that animates named numeric fields on a Lua table.
- `SequenceStep` (`enum`, `handle.rs`): The enum-like workflow step container used inside sequences.
- `LuaTweenSequence` (`struct`, `handle.rs`): The ordered step runner that executes tween, delay, and callback steps one after another.
- `ParallelEntry` (`struct`, `handle.rs`): The per-arm tween record stored inside a parallel group.
- `LuaTweenParallel` (`struct`, `handle.rs`): The grouped runner that executes multiple tween entries at the same time.
- `SpringAxis` (`struct`, `spring.rs`): Single-axis spring simulation driven by a damped differential equation.
- `SpringSystem` (`struct`, `spring.rs`): Named collection of [`SpringAxis`] values that all share the same parameters.
- `TweenState` (`struct`, `state.rs`): The pure timing and easing core that tracks elapsed time, completion, and interpolation progress without Lua dependencies.

## Functions

- `TweenEngine::new` (`engine.rs`): Creates an empty `TweenEngine` with no active objects.
- `TweenEngine::update` (`engine.rs`): Advances all active tweens, sequences, and parallels by `dt` seconds.
- `TweenEngine::cancel_all` (`engine.rs`): Cancels and removes all active tweens, sequences, and parallels.
- `TweenEngine::active_count` (`engine.rs`): Returns the total number of currently tracked objects (tweens + seqs + pars + springs).
- `LuaTween::new` (`handle.rs`): Creates a `LuaTween` that animates named fields of a Lua table.
- `LuaTween::tick_with` (`handle.rs`): Advances the tween by `dt` seconds, writing interpolated values to the target table.
- `LuaTween::fire_on_complete` (`handle.rs`): Fires the `on_complete` callback if one is set, then frees the registry key.
- `LuaTweenSequence::new` (`handle.rs`): Creates an empty, inactive `LuaTweenSequence`.
- `LuaTweenSequence::tick_with` (`handle.rs`): Advances the sequence by `dt` seconds.
- `LuaTweenParallel::new` (`handle.rs`): Creates an empty, inactive `LuaTweenParallel`.
- `LuaTweenParallel::tick_with` (`handle.rs`): Advances all child entries by `dt` seconds.
- `SpringAxis::new` (`spring.rs`): Creates a `SpringAxis` with the given initial position and target.
- `SpringAxis::update` (`spring.rs`): Advances the spring simulation by `dt` seconds.
- `SpringAxis::is_settled` (`spring.rs`): Returns `true` when the axis has settled within `precision` of the target.
- `SpringAxis::reset` (`spring.rs`): Teleports to a new position and target, clearing velocity and the settled flag.
- `SpringAxis::set_target` (`spring.rs`): Updates the target without resetting velocity or position.
- `SpringSystem::new` (`spring.rs`): Creates an empty `SpringSystem` with the given parameters.
- `SpringSystem::add_axis` (`spring.rs`): Adds a named axis with the given starting position and target.
- `SpringSystem::update` (`spring.rs`): Advances all axes by `dt` seconds.
- `SpringSystem::is_settled` (`spring.rs`): Returns `true` when every axis has settled.
- `SpringSystem::set_target` (`spring.rs`): Sets the target for a named axis without resetting velocity.
- `SpringSystem::get_position` (`spring.rs`): Returns the current position of a named axis, or `None` if not found.
- `TweenState::new` (`state.rs`): Creates a new tween state with the given duration and easing name.
- `TweenState::tick` (`state.rs`): Advances the elapsed time by `dt` seconds.
- `TweenState::reset` (`state.rs`): Resets elapsed time to 0 so the tween plays from the beginning.
- `TweenState::t_raw` (`state.rs`): Returns the raw (un-eased) 0..=1 progress factor.
- `TweenState::t_eased` (`state.rs`): Returns the eased 0..=1 progress factor using the chosen easing function.
- `TweenState::lerp` (`state.rs`): Linearly interpolates from `start` to `end` using the eased progress factor.
- `TweenState::is_complete` (`state.rs`): Returns `true` if elapsed has reached or exceeded the duration.
- `resolve_easing` (`state.rs`): Resolves a named easing function to a function pointer.
- `builtin_easing_names` (`state.rs`): Returns all built-in easing names as a static slice.

## Lua API Reference

- Binding path(s): `src/lua_api/tween_api.rs`
- Namespace: `lurek.tween`

### Module Functions
- `lurek.tween.update`: Advances all active tweens, sequences, parallels, and springs by `dt` seconds.
- `lurek.tween.tween`: Creates a property tween and registers it for automatic updating.
- `lurek.tween.sequence`: Creates an empty tween sequence handle.
- `lurek.tween.parallel`: Creates an empty parallel tween handle.
- `lurek.tween.delay`: Creates a started delay sequence that waits and then optionally calls a callback.
- `lurek.tween.cancelAll`: Cancels all active tweens, sequences, parallels, and springs immediately.
- `lurek.tween.getActiveCount`: Returns the number of currently active tween objects.
- `lurek.tween.registerEasing`: Registers a custom easing function under `name`.
- `lurek.tween.getEasingNames`: Returns all available built-in and custom easing names.
- `lurek.tween.newState`: Creates a standalone tween state that is not registered with the engine.
- `lurek.tween.to`: Creates a tween using `target` as the first argument.
- `lurek.tween.spring`: Creates a spring animation that drives named table fields toward target values.

### `LSpring` Methods
- `LSpring:update`: Advances the spring by `dt` seconds.
- `LSpring:isSettled`: Returns whether all spring axes have settled.
- `LSpring:isActive`: Returns whether the spring is still active.
- `LSpring:setTarget`: Updates target values for all fields present in `fields_table`.
- `LSpring:setStiffness`: Updates the stiffness constant on all axes.
- `LSpring:setDamping`: Updates the damping coefficient on all axes.
- `LSpring:cancel`: Stops the spring immediately, clears its settle callback, and leaves the current values at their last simulated positions.
- `LSpring:getPosition`: Returns the current interpolated position for the named field.
- `LSpring:type`: Returns the type name of this object.
- `LSpring:typeOf`: Returns true if this object is of the given type.

### `LTween` Methods
- `LTween:cancel`: Cancels this tween immediately; fires the `onCancel` callback if set.
- `LTween:pause`: Pauses this tween; time stops advancing but the tween is not cancelled.
- `LTween:resume`: Resumes a paused tween, continuing from the position where it was paused.
- `LTween:isActive`: Returns true if the tween is still running (not completed or cancelled).
- `LTween:getProgress`: Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
- `LTween:setRepeat`: Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
- `LTween:setYoyo`: Enables or disables yoyo (ping-pong) on each repeat cycle.
- `LTween:onComplete`: Sets a callback to fire when the tween finishes all cycles.
- `LTween:onUpdate`: Sets a callback called every tick with the current eased progress.
- `LTween:onCancel`: Sets a callback called when the tween is cancelled.
- `LTween:type`: Returns the type name of this object.
- `LTween:typeOf`: Returns true if this object is of the given type.

### `LTweenParallel` Methods
- `LTweenParallel:add`: Adds an existing tween handle to the parallel group.
- `LTweenParallel:tween`: Creates and adds an inline tween entry to the parallel group.
- `LTweenParallel:start`: Marks the parallel as active.
- `LTweenParallel:cancel`: Cancels the parallel group immediately.
- `LTweenParallel:isActive`: Returns true if the parallel is running and not yet complete.
- `LTweenParallel:onComplete`: Sets a callback fired when all child tweens finish.
- `LTweenParallel:type`: Returns the type name of this object.
- `LTweenParallel:typeOf`: Returns true if this object is of the given type.

### `LTweenSequence` Methods
- `LTweenSequence:tween`: Appends a tween step to the sequence.
- `LTweenSequence:delay`: Appends a delay step to the sequence.
- `LTweenSequence:callback`: Appends an immediate callback step to the sequence.
- `LTweenSequence:start`: Marks the sequence as active so `lurek.tween.update(dt)` begins ticking it.
- `LTweenSequence:cancel`: Cancels the sequence and stops all pending steps.
- `LTweenSequence:isActive`: Returns true if the sequence has been started and has not yet completed.
- `LTweenSequence:onComplete`: Sets a callback fired when all steps complete.
- `LTweenSequence:type`: Returns the type name of this object.
- `LTweenSequence:typeOf`: Returns true if this object is of the given type.

### `LTweenState` Methods
- `LTweenState:tick`: Advances the tween state by `dt` seconds.
- `LTweenState:isComplete`: Returns whether the tween state has completed.
- `LTweenState:t`: Returns the raw 0..1 playback progress.
- `LTweenState:lerp`: Interpolates from `start` to `finish` using the eased tween progress.
- `LTweenState:reset`: Resets the tween state to elapsed time zero.
- `LTweenState:type`: Returns the type name of this object.
- `LTweenState:typeOf`: Returns true if this object is of the given type.

## References

- `math`: Imports or references `math` from `src/math/`.

## Notes

- Keep this module reference synchronized with `src/tween/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
