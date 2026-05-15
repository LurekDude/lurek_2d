# automation

## General Info

- Module group: `Feature Systems`
- Source path: `src/automation/`
- Lua API path(s): `src/lua_api/automation_api.rs`
- Primary Lua namespace: `lurek.automation`
- Rust test path(s): tests/rust/unit/automation_tests.rs
- Lua test path(s): tests/lua/unit/test_automation_core_unit.lua, tests/lua/integration/test_automation_event.lua

## Summary

The `automation` module is Lurek2D's automated input simulation engine — a Feature Systems tier subsystem for loading, recording, and playing back scripted input sequences. It is primarily used for headless integration tests, QA regression replay, speedrun verification, and development session recording.

**Core model.** The central type is `Simulator`, a playback engine that owns a named registry of `Script` objects. Each `Script` contains a time-sorted `Vec<Step>` where every `Step` pairs an `Action` variant with a timestamp (in seconds from script start) and optional parameters. `Action` variants include standard input events plus orchestration actions: `Repeat`, `CallMacro`, `Assert`, and `VisualAssert`. Scripts are capped at `MAX_STEPS` entries (module-wide default, overridable per-script) to prevent unbounded memory use.

**Playback.** `Simulator::update(dt)` advances an internal deterministic microsecond clock and dispatches all steps whose timestamp is reached by pushing synthetic `Event` values into the engine's `EventQueue` through the same `push()` path as real hardware events. Time accumulation now uses the shared `timer::accumulate_scaled_micros` helper (fixed-point carry) instead of local float accumulation. The simulator exposes `update_with_sink` via a sink trait for unit tests that do not want to instantiate `EventQueue`. The playback state machine now includes failure handling: `Idle → Running → Paused → Running → Complete | Failed`.

**Script lifecycle.** Scripts can be created programmatically from Lua tables or loaded from TOML files via `Script::from_toml(string)`. Each script carries: name, optional description string, the step list, and an optional per-script step limit via `set_step_limit` / `get_step_limit` (independent of the module-wide `MAX_STEPS` cap).

**Macro system.** `Simulator` includes an inline macro recording and playback manager: `save_macro(name, steps)` stores a named step sequence; `play_macro(name)` appends it to the active timeline; `has_macro(name)` / `list_macros()` query the registry. This enables composable test sequences from reusable input fragments.

**Time scaling.** `set_playback_speed(factor)` / `get_playback_speed()` controls the rate at which the internal clock advances relative to wall-clock dt. Values greater than 1.0 fast-forward replay, enabling rapid regression sweeps. Values less than 1.0 slow-motion the replay for debugging timing-sensitive steps.

**Highlight mode.** `set_highlight_mode(bool)` / `is_highlight_mode()` toggles visual input feedback during replay — useful for demo recording and QA review sessions where reviewers need to see which input is being simulated.

**`waitUntil` primitive.** The Lua surface exposes `lurek.automation.waitUntil(predicate)`, a synchronisation step that inserts a blocking sentinel into the timeline. The simulator fires the predicate each tick and only advances to the next step when it returns true. This enables `waitUntil(function() return boss:isDead() end)` style synchronisation without hard-coded timestamps.

**Lua surface.** Script management: `load(name, data)`, `loadFromToml(name, toml)`, `unload(name)`, `hasScript(name)`, `getScripts()`. Playback: `start(name)`, `stop()`, `pause()`, `resume()`, `isComplete()`, `isRunning()`, `isPaused()`, `isFailed()`, `getLastError()`, `update(dt)`. Extended API: `setStepLimit(name, n)`, `getStepLimit(name)`, `setPlaybackSpeed(f)`, `getPlaybackSpeed()`, `saveMacro(name, scriptName)`, `playMacro(name)`, `hasMacro(name)`, `listMacros()`, `setCondition(name, value)`, `getCondition(name)`, `setHighlightMode(bool)`, `isHighlightMode()`, `waitUntil(fn, timeout)`. `when` and `assert` step fields now accept boolean expressions (`!`, `&&`, `||`, parentheses) over named conditions.

**Scope boundary.** Core Runtime tier (uses runtime event infrastructure). Depends on `event`, `runtime`. Lua bridge in `src/lua_api/automation_api.rs`.

## Files

- `mod.rs`: Module root that documents the automation surface and re-exports Script, Simulator, Action, and Step. This is the shortest entry point for understanding what the module exposes to other Rust code.
- `script.rs`: Defines Script, the named container for a time-sorted list of Steps. It also enforces the step-count cap and supports TOML-based script loading.
- `simulator.rs`: Defines Simulator and its internal playback state machine. This is the runtime engine that loads scripts, starts and stops playback, advances elapsed time, and pushes synthetic events into the EventQueue.
- `step.rs`: Defines the Action enum and Step record that describe a single timed automation action. This file is the schema for every script entry regardless of whether it comes from Lua, TOML, or Rust-side tests.

## Types

- `Script` (`struct`, `script.rs`): Named automation script with optional human-readable metadata and an ordered Vec of Step values. It is the durable unit loaded into the simulator and reused across playback runs.
- `StepEventSink` (`trait`, `simulator.rs`): Sink for events produced by the simulator during step dispatch.
- `Simulator` (`struct`, `simulator.rs`): Playback engine that owns the script registry, current script selection, elapsed time, next-step index, and running or paused state. This is the type to inspect when behavior changes around script lifecycle, event dispatch timing, or completion rules.
- `Action` (`enum`, `step.rs`): Enum of supported automation actions such as keypress, mousemove, mousepress, and wait. It is the boundary between script data and concrete EventQueue dispatch behavior.
- `Step` (`struct`, `step.rs`): One timed automation record with optional fields for key names, scancodes, mouse coordinates, wheel deltas, button data, and text input. It is intentionally flexible so a single structure can represent all supported synthetic input events.

## Functions

- `Script::new` (`script.rs`): Create a `Script` from a name and raw steps: expands repeats, sorts by time, caps to `MAX_STEPS`.
- `Script::with_description` (`script.rs`): Create a `Script` identical to `new` but also sets the human-readable `description` field.
- `Script::step_count` (`script.rs`): Return the total number of steps in this script.
- `Script::set_step_limit` (`script.rs`): Clamp and apply a new step limit, truncating the step list if it exceeds `limit`; range 1..=MAX_STEPS.
- `Script::get_step_limit` (`script.rs`): Return the current step limit for this script.
- `Script::from_toml` (`script.rs`): Parse a TOML string and construct a `Script`; return an error string on invalid TOML or unknown action.
- `Simulator::new` (`simulator.rs`): Create a new idle `Simulator` with no scripts, macros, or conditions loaded.
- `Simulator::load` (`simulator.rs`): Register a `Script` by name; replaces any existing script with the same name.
- `Simulator::unload` (`simulator.rs`): Remove the named script; stop playback if it is currently active.
- `Simulator::has_script` (`simulator.rs`): Return `true` if a script with `name` is registered.
- `Simulator::get_scripts` (`simulator.rs`): Return the names of all currently loaded scripts.
- `Simulator::start` (`simulator.rs`): Begin playback of the named script from the start; error if the script is not loaded.
- `Simulator::stop` (`simulator.rs`): Halt playback and reset all playback state to idle.
- `Simulator::pause` (`simulator.rs`): Suspend playback; time stops advancing until `resume()` is called.
- `Simulator::resume` (`simulator.rs`): Resume a paused script; no-op if not in `Paused` state.
- `Simulator::is_running` (`simulator.rs`): Return `true` when the script is actively advancing time.
- `Simulator::is_paused` (`simulator.rs`): Return `true` when the script is suspended.
- `Simulator::is_complete` (`simulator.rs`): Return `true` when all steps have been dispatched without error.
- `Simulator::is_failed` (`simulator.rs`): Return `true` when playback halted due to an assertion or macro error.
- `Simulator::last_error` (`simulator.rs`): Return the error message from the most recent failure, or `None` if no failure.
- `Simulator::current_step` (`simulator.rs`): Return the index of the next step that will be evaluated on the next `update()`.
- `Simulator::step_count` (`simulator.rs`): Return the total step count of the active script, or 0 when none is active.
- `Simulator::current_script` (`simulator.rs`): Return the name of the currently active script, or `None` when idle.
- `Simulator::elapsed_time` (`simulator.rs`): Return elapsed playback time in seconds (scaled by `playback_speed`).
- `Simulator::set_condition` (`simulator.rs`): Set a named boolean condition used by `when` and `assert` step expressions.
- `Simulator::get_condition` (`simulator.rs`): Return the current value of a named condition, or `None` if not set.
- `Simulator::get_script` (`simulator.rs`): Return a clone of the registered script with `name`, or `None` if not loaded.
- `Simulator::get_script_step_limit` (`simulator.rs`): Return the step limit of the named script, or `None` if the script is not loaded.
- `Simulator::set_script_step_limit` (`simulator.rs`): Apply a new step limit to the named script; return `true` if the script exists.
- `Simulator::save_macro` (`simulator.rs`): Register a named macro `Script` that can be inlined by `CallMacro` steps.
- `Simulator::play_macro` (`simulator.rs`): Load the named macro as a regular script and start it immediately.
- `Simulator::has_macro` (`simulator.rs`): Return `true` if a macro named `name` is registered.
- `Simulator::list_macros` (`simulator.rs`): Return the names of all registered macros.
- `Simulator::set_playback_speed` (`simulator.rs`): Set the playback speed multiplier; clamped to >= 0.0.
- `Simulator::get_playback_speed` (`simulator.rs`): Return the current playback speed multiplier.
- `Simulator::set_highlight_mode` (`simulator.rs`): Enable or disable visual step-highlight mode used by debug tooling.
- `Simulator::is_highlight_mode` (`simulator.rs`): Return `true` when visual step-highlight mode is active.
- `Simulator::update` (`simulator.rs`): Advance the simulator by `dt` seconds and dispatch due steps into `event_queue`.
- `Simulator::update_with_sink` (`simulator.rs`): Advance the simulator by `dt` seconds and dispatch due steps into the provided sink.
- `Action::parse_action` (`step.rs`): Parse a lowercase action string (e.g.
- `Action::as_str` (`step.rs`): Return the canonical lowercase string key for this variant; default to "wait" if not found.
- `Step::new` (`step.rs`): Create a `Step` at `time` seconds with the given `action`; all optional fields default to `None`.
- `Step::effective_scancode` (`step.rs`): Return `scancode` if set, otherwise fall back to `key`; `None` when both are absent.

## Lua API Reference

- Binding path(s): `src/lua_api/automation_api.rs`
- Namespace: `lurek.automation`

### Module Functions
- `lurek.automation.load`: Loads an automation script from a Lua table of steps and optional metadata.
- `lurek.automation.unload`: Unloads a named automation script.
- `lurek.automation.hasScript`: Returns whether a script is loaded.
- `lurek.automation.getScripts`: Returns the names of loaded automation scripts.
- `lurek.automation.start`: Starts playback of a loaded automation script.
- `lurek.automation.stop`: Stops the current automation script.
- `lurek.automation.pause`: Pauses automation playback.
- `lurek.automation.resume`: Resumes automation playback.
- `lurek.automation.update`: Advances automation playback and dispatches generated input events.
- `lurek.automation.isRunning`: Returns whether automation playback is running.
- `lurek.automation.isPaused`: Returns whether automation playback is paused.
- `lurek.automation.isComplete`: Returns whether the current automation script completed.
- `lurek.automation.isFailed`: Returns whether the current automation script failed.
- `lurek.automation.getLastError`: Returns the last automation error message when one exists.
- `lurek.automation.setCondition`: Sets a named boolean condition used by automation steps.
- `lurek.automation.getCondition`: Returns a named automation condition value.
- `lurek.automation.getCurrentStep`: Returns the current step index of the active script.
- `lurek.automation.getStepCount`: Returns the number of steps in the active script.
- `lurek.automation.getCurrentScript`: Returns the current script name when a script is active.
- `lurek.automation.getElapsedTime`: Returns elapsed playback time for the current script.
- `lurek.automation.loadFromToml`: Loads an automation script from TOML text.
- `lurek.automation.getStepLimit`: Returns the configured step limit for a loaded script.
- `lurek.automation.setStepLimit`: Sets the maximum step count for a loaded script.
- `lurek.automation.saveMacro`: Saves a loaded script as a named macro.
- `lurek.automation.playMacro`: Starts playback of a saved macro.
- `lurek.automation.hasMacro`: Returns whether a macro is saved.
- `lurek.automation.listMacros`: Returns the names of saved macros.
- `lurek.automation.setPlaybackSpeed`: Sets automation playback speed multiplier.
- `lurek.automation.getPlaybackSpeed`: Returns automation playback speed multiplier.
- `lurek.automation.setHighlightMode`: Enables or disables automation highlight mode.
- `lurek.automation.isHighlightMode`: Returns whether automation highlight mode is enabled.
- `lurek.automation.waitUntil`: Suspends automation updates until a predicate returns true or a timeout elapses.

## References

- `event`: Imports or references `event` from `src/event/`.
- `input`: Imports or references `src/input/`. Cross-group dependency from `Feature Systems` into `Platform Services`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.
- `timer`: Imports or references `src/timer/`. Cross-group dependency from `Feature Systems` into `Core Runtime`.

## Notes

- Keep this module reference synchronized with `src/automation/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### New in 0.14.1

- `Simulator.highlight_mode: bool` (default `false`) — hint flag for game-side replay overlays.
- `Simulator::set_highlight_mode(enable: bool)` / `is_highlight_mode() -> bool`.
- Lua: `lurek.automation.setHighlightMode(enable)` / `isHighlightMode()`.

### New in 1.0.9-fix.48

- Added script orchestration actions: `repeat`, `callmacro`, `assert`, `visualassert`.
- Added step-level fields: `repeat`, `repeatInterval`, `macro`, `when`, `assert`, `baseline`, `actual`, `maxDiff`.
- Added deterministic microsecond time accumulation in `Simulator::update` to reduce floating-drift behavior in long scripts.
- Added sink abstraction (`StepEventSink`) and `Simulator::update_with_sink` for isolated event-emission tests.
- Added runtime condition table and Lua APIs: `setCondition`, `getCondition`, `isFailed`, `getLastError`.

### New in 1.0.9-fix.78

- Added expression-capable condition checks for `when` and `assert` fields (`!`, `&&`, `||`, parentheses).
- Added shared timer integration via `timer::accumulate_scaled_micros` for replay time progression.
- Deduplicated automation event-name literals to `input` module constants.
