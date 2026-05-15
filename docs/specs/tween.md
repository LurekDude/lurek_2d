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

- `TweenEngine::new` (`engine.rs`): Create an empty engine with no active animations and no custom easings.
- `TweenEngine::update` (`engine.rs`): Advance all active tweens, sequences, and parallels by `dt` seconds; remove completed entries from the registry; return error on Lua fault.
- `TweenEngine::cancel_all` (`engine.rs`): Cancel and remove all active tweens, sequences, and parallels; fires `on_cancel` callbacks; return error on Lua fault.
- `TweenEngine::active_count` (`engine.rs`): Return the total count of active tweens, sequences, parallels, and springs.
- `LuaTween::new` (`handle.rs`): Create a new active tween targeting `fields` of `target` over `duration` seconds using `easing_name`.
- `LuaTween::tick_with` (`handle.rs`): Advance the tween by `dt` seconds, write interpolated values to the target table, fire `on_update`, handle repeats and yoyo; return true when fully done.
- `LuaTween::fire_on_complete` (`handle.rs`): Consume and call the `on_complete` registry callback if one is set.
- `LuaTween::set_relative` (`handle.rs`): Set whether `end_values` are absolute targets or offsets from start; resets start capture.
- `LuaTween::add_waiter` (`handle.rs`): Push a coroutine registry key to be resumed when this tween completes.
- `LuaTween::resume_waiters` (`handle.rs`): Resume all registered waiter coroutines and remove their registry entries.
- `LuaTween::progress` (`handle.rs`): Return the raw (uneased) progress in [0.0, 1.0] as of the last tick.
- `LuaTween::elapsed` (`handle.rs`): Return elapsed seconds since the tween started.
- `LuaTween::remaining` (`handle.rs`): Return seconds remaining until the tween completes; clamped to >= 0.0.
- `LuaTweenSequence::new` (`handle.rs`): Create an empty, inactive sequence with no steps or callbacks.
- `LuaTweenSequence::tick_with` (`handle.rs`): Advance the sequence by `dt` seconds, consuming as many steps as time allows; return true when all steps are done.
- `LuaTweenSequence::progress_ratio` (`handle.rs`): Return the fraction [0.0, 1.0] of steps completed; 1.0 when inactive or empty.
- `LuaTweenSequence::add_waiter` (`handle.rs`): Push a coroutine registry key to be resumed when this sequence completes.
- `LuaTweenSequence::resume_waiters` (`handle.rs`): Resume all registered waiter coroutines and remove their registry entries.
- `LuaTweenParallel::new` (`handle.rs`): Create an empty, inactive parallel group.
- `LuaTweenParallel::tick_with` (`handle.rs`): Advance all incomplete lanes by `dt` seconds; return true when every lane is done.
- `SpringAxis::new` (`spring.rs`): Create a new spring axis; `settled` is set immediately if `|position - target| < precision`.
- `SpringAxis::update` (`spring.rs`): Advance the spring by `dt` seconds; snap to target and zero velocity when settled.
- `SpringAxis::is_settled` (`spring.rs`): Return true if the spring has settled within `precision` of its target.
- `SpringAxis::reset` (`spring.rs`): Teleport the spring to `position`, set a new `target`, and clear velocity.
- `SpringAxis::set_target` (`spring.rs`): Update the target and mark the spring as unsettled so simulation resumes.
- `SpringSystem::new` (`spring.rs`): Create a new spring system with the given default parameters and no axes.
- `SpringSystem::add_axis` (`spring.rs`): Add a named axis with `position` and `target`, using the system's default spring parameters.
- `SpringSystem::update` (`spring.rs`): Advance all axes by `dt` seconds.
- `SpringSystem::is_settled` (`spring.rs`): Return true if every axis in the system has settled.
- `SpringSystem::set_target` (`spring.rs`): Set the target for the axis named `key`; no-op if the key does not exist.
- `SpringSystem::get_position` (`spring.rs`): Return the current position of the axis named `key`, or `None` if not found.
- `TweenState::new` (`state.rs`): Create a new state with the given `duration` and easing name; falls back to linear on unknown names.
- `TweenState::tick` (`state.rs`): Advance elapsed time by `dt` when not paused; return true if the tween has reached or passed its duration.
- `TweenState::reset` (`state.rs`): Reset `elapsed` to zero so the tween plays from the beginning.
- `TweenState::t_raw` (`state.rs`): Return raw (uneased) progress in [0.0, 1.0]; returns 1.0 when duration is zero.
- `TweenState::t_eased` (`state.rs`): Return eased progress in [0.0, 1.0] by applying the resolved easing function to `t_raw`.
- `TweenState::lerp` (`state.rs`): Return `start + (end - start) * t_eased()`.
- `TweenState::is_complete` (`state.rs`): Return true when elapsed >= duration.
- `resolve_easing` (`state.rs`): Resolves a named easing function to a function pointer.
- `builtin_easing_names` (`state.rs`): Returns all built-in easing names as a static slice.

## Lua API Reference

- Binding path(s): `src/lua_api/tween_api.rs`
- Namespace: `lurek.tween`

### Module Functions
- `lurek.tween.update`: Advances all active tweens, sequences, parallels, and springs by the given delta time. Call once per frame.
- `lurek.tween.tween`: Creates and starts a property tween that smoothly interpolates numeric fields on the target table over the given duration.
- `lurek.tween.sequence`: Creates a new empty tween sequence. Chain `.tween()`, `.delay()`, and `.callback()` steps, then call `:start()`.
- `lurek.tween.parallel`: Creates a new empty parallel tween group. Add tweens with `:tween()` or `:add()`, then call `:start()` to run them simultaneously.
- `lurek.tween.delay`: Creates a one-shot delay. After the specified seconds elapse, the optional callback is invoked.
- `lurek.tween.cancelAll`: Immediately cancels all active tweens, sequences, parallels, and springs managed by the tween engine.
- `lurek.tween.getActiveCount`: Returns the total number of currently active tweens, sequences, and parallels.
- `lurek.tween.registerEasing`: Registers a custom easing function by name. The function receives a progress value (0..1) and must return an eased value.
- `lurek.tween.getEasingNames`: Returns an array of all available easing function names, including both built-in and custom-registered easings.
- `lurek.tween.newState`: Creates a standalone tween state for manual interpolation. Useful when you need eased progress without automatic property updates.
- `lurek.tween.to`: Creates and starts a property tween with a different parameter order: target first, then fields, duration, easing.
- `lurek.tween.tweenChain`: Creates a sequence from a table of step descriptors. Each step is a table with `duration`, `target`, `fields`, optional `easing`, optional `callback`, or a `delay` key for pauses.
- `lurek.tween.tweenColor`: Creates and starts a color tween that smoothly interpolates r, g, b, and/or a fields on the target table.
- `lurek.tween.spring`: Creates a spring-physics animation that smoothly drives table fields toward target values with bounce and settle behavior.

### `LSpring` Methods
- `LSpring:update`: Manually advances this spring by the given delta time and writes updated positions to the target table. Returns `true` if still animating, `false` if settled.
- `LSpring:isSettled`: Returns whether all spring axes have reached their targets within the precision threshold.
- `LSpring:isActive`: Returns whether this spring is still actively animating.
- `LSpring:setTarget`: Changes the spring target values for one or more axes. Re-activates the spring if it was settled.
- `LSpring:setStiffness`: Sets the spring stiffness for all axes. Higher values make the spring snap faster.
- `LSpring:setDamping`: Sets the spring damping for all axes. Higher values reduce oscillation and overshoot.
- `LSpring:cancel`: Cancels this spring animation and cleans up the on-settle callback if one was registered.
- `LSpring:getPosition`: Returns the current position of the given spring axis, or `nil` if the axis does not exist.
- `LSpring:type`: Returns the type name of this object.
- `LSpring:typeOf`: Checks whether this object matches the given type name.

### `LTween` Methods
- `LTween:cancel`: Cancels this tween immediately, fires the onCancel callback if set, and resumes any coroutines waiting on it.
- `LTween:pause`: Pauses this tween so it stops advancing until resumed.
- `LTween:resume`: Resumes a paused tween so it continues advancing.
- `LTween:isActive`: Returns whether this tween is still running (not cancelled or completed).
- `LTween:getProgress`: Returns the eased progress of this tween as a value from 0.0 to 1.0.
- `LTween:getElapsed`: Returns the number of seconds that have elapsed since the tween started.
- `LTween:getDuration`: Returns the total duration of this tween in seconds.
- `LTween:getRemaining`: Returns the number of seconds remaining until this tween completes.
- `LTween:getFields`: Returns an array of field names being tweened on the target table.
- `LTween:setRelative`: Sets whether the tween end values are relative to the start values instead of absolute.
- `LTween:relative`: Chainable version of `setRelative`. Returns the tween for fluent API usage.
- `LTween:await`: Yields the current coroutine until this tween completes or is cancelled. Must be called from inside a coroutine.
- `LTween:setRepeat`: Sets how many times the tween should repeat after the first play. Use -1 for infinite repeat.
- `LTween:setYoyo`: Enables or disables yoyo mode, which reverses the tween direction on each repeat cycle.
- `LTween:onComplete`: Lua-facing function documented in the binding source.
- `LTween:onUpdate`: Sets a callback to fire every frame while the tween is active. Returns the tween for chaining.
- `LTween:onCancel`: Sets a callback to fire when the tween is cancelled. Returns the tween for chaining.
- `LTween:type`: Returns the type name of this object.
- `LTween:typeOf`: Checks whether this object matches the given type name.

### `LTweenParallel` Methods
- `LTweenParallel:add`: Adds an existing tween handle to this parallel group. The tween becomes owned by the group.
- `LTweenParallel:tween`: Creates and adds a new tween step directly to this parallel group.
- `LTweenParallel:start`: Starts all tweens in this parallel group simultaneously.
- `LTweenParallel:cancel`: Cancels all tweens in this parallel group immediately.
- `LTweenParallel:isActive`: Returns whether this parallel group is still running.
- `LTweenParallel:onComplete`: Sets a callback to fire when all tweens in this parallel group have finished. Returns the group for chaining.
- `LTweenParallel:type`: Returns the type name of this object.
- `LTweenParallel:typeOf`: Checks whether this object matches the given type name.

### `LTweenSequence` Methods
- `LTweenSequence:tween`: Appends a tween step to this sequence that animates numeric fields on the target table.
- `LTweenSequence:delay`: Appends a delay step to this sequence. Optionally fires a callback when the delay elapses.
- `LTweenSequence:callback`: Appends a callback step to this sequence that fires when reached during playback.
- `LTweenSequence:start`: Starts playback of this sequence from the first step.
- `LTweenSequence:cancel`: Cancels this sequence immediately and resumes any coroutines waiting on it.
- `LTweenSequence:isActive`: Returns whether this sequence is still running.
- `LTweenSequence:getProgress`: Returns the overall progress ratio of this sequence from 0.0 to 1.0.
- `LTweenSequence:await`: Yields the current coroutine until this sequence completes or is cancelled. Must be called from inside a coroutine.
- `LTweenSequence:onComplete`: Sets a callback to fire when the sequence finishes all steps. Returns the sequence for chaining.
- `LTweenSequence:type`: Returns the type name of this object.
- `LTweenSequence:typeOf`: Checks whether this object matches the given type name.

### `LTweenState` Methods
- `LTweenState:tick`: Advances the tween state by the given delta time and returns the eased interpolation value (0..1).
- `LTweenState:isComplete`: Returns whether this tween state has finished its full duration.
- `LTweenState:t`: Returns the raw (un-eased) progress value from 0.0 to 1.0.
- `LTweenState:lerp`: Linearly interpolates between two values using the current eased progress.
- `LTweenState:reset`: Resets the tween state to the beginning so it can be replayed.
- `LTweenState:type`: Returns the type name of this object.
- `LTweenState:typeOf`: Checks whether this object matches the given type name.

## References

- `math`: Imports or references `math` from `src/math/`.

## Notes

- Keep this module reference synchronized with `src/tween/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### Recent sync (1.0.9-fix.73)

- Added relative tween mode:
  - `LTween:setRelative(enabled)` and chain alias `LTween:relative(enabled)`.
  - Relative mode interprets tween field values as deltas from captured start values.
- Added runtime introspection for active tweens:
  - `LTween:getElapsed`, `LTween:getDuration`, `LTween:getRemaining`, `LTween:getFields`.
- Added coroutine completion waits:
  - `LTween:await()` and `LTweenSequence:await()` resume suspended coroutine when object completes/cancels.
  - `LTweenSequence:getProgress()` exposes step-completion ratio.
- Added helper constructors:
  - `lurek.tween.tweenChain(steps)` for declarative sequences.
  - `lurek.tween.tweenColor(duration, target, color, easing?)` for RGBA animation.
- Reliability update:
  - explicit waiter cleanup/resume on tween and sequence cancel/complete paths.
- Boundary clarification (`tween` vs `animation`):
  - `tween` owns runtime numeric interpolation and per-frame easing.
  - `animation` owns clip/timeline playback authoring semantics.
