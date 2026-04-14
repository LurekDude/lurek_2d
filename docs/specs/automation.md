# automation

## General Info

- Module group: `Feature Systems`
- Source path: `src/automation/`
- Lua API path(s): `src/lua_api/automation_api.rs`
- Primary Lua namespace: `lurek.automation`
- Rust test path(s): tests/rust/unit/automation_tests.rs
- Lua test path(s): tests/lua/unit/test_automation.lua

## Summary

The `automation` module provides Lurek2D's automated input simulation engine for loading and playing back recorded input sequences. Its primary use-cases are headless integration tests, QA regression replay, speedrun verification, and recorded developer input sessions.

The central type is `Simulator`, a playback engine that drives named `Script` objects. Each `Script` contains an ordered, time-sorted sequence of `Step` records, each holding an `Action` variant (one of 8 kinds: key-press, key-release, mouse-move, mouse-press, mouse-release, text-input, scroll, and wait) plus a timestamp and a parameters map. Scripts are capped at `MAX_STEPS` entries to prevent unbounded memory use.

During playback, `simulator.update(dt)` advances an internal clock and fires all steps whose timestamp has been reached by injecting synthetic `Event` values into the engine's `EventQueue` through the same `push()` path as real hardware events. This makes automation playback completely transparent to downstream Lua callbacks — they cannot distinguish replayed input from real user input.

Scripts can be loaded programmatically from Lua tables or from serialized TOML files. The `Simulator` tracks playback status (idle, running, paused, complete) and provides `start()`, `stop()`, `pause()`, `resume()`, and `is_complete()` controls.

**Scope boundary**: Core Runtime tier. Depends on `event`, `runtime`. Lua bridge in `src/lua_api/automation_api.rs`.

## Files

- `mod.rs`: Module root that documents the automation surface and re-exports Script, Simulator, Action, and Step. This is the shortest entry point for understanding what the module exposes to other Rust code.
- `script.rs`: Defines Script, the named container for a time-sorted list of Steps. It also enforces the step-count cap and supports TOML-based script loading.
- `simulator.rs`: Defines Simulator and its internal playback state machine. This is the runtime engine that loads scripts, starts and stops playback, advances elapsed time, and pushes synthetic events into the EventQueue.
- `step.rs`: Defines the Action enum and Step record that describe a single timed automation action. This file is the schema for every script entry regardless of whether it comes from Lua, TOML, or Rust-side tests.

## Types

- `Script` (`struct`, `script.rs`): Named automation script with optional human-readable metadata and an ordered Vec of Step values. It is the durable unit loaded into the simulator and reused across playback runs.
- `Simulator` (`struct`, `simulator.rs`): Playback engine that owns the script registry, current script selection, elapsed time, next-step index, and running or paused state. This is the type to inspect when behavior changes around script lifecycle, event dispatch timing, or completion rules.
- `Action` (`enum`, `step.rs`): Enum of supported automation actions such as keypress, mousemove, mousepress, and wait. It is the boundary between script data and concrete EventQueue dispatch behavior.
- `Step` (`struct`, `step.rs`): One timed automation record with optional fields for key names, scancodes, mouse coordinates, wheel deltas, button data, and text input. It is intentionally flexible so a single structure can represent all supported synthetic input events.

## Functions

- `Script::new` (`script.rs`): Create a new script with the given name and steps.
- `Script::with_description` (`script.rs`): Create a script with an explicit description string.
- `Script::step_count` (`script.rs`): Return the number of steps in this script.
- `Script::from_toml` (`script.rs`): Parse a Script from a TOML string.
- `Simulator::new` (`simulator.rs`): Create a new `Simulator` with an empty script registry.
- `Simulator::load` (`simulator.rs`): Load a script into the simulator, replacing any script with the same name.
- `Simulator::unload` (`simulator.rs`): Remove a loaded script by name.
- `Simulator::has_script` (`simulator.rs`): Return `true` if a script with the given name is registered.
- `Simulator::get_scripts` (`simulator.rs`): Return the names of all loaded scripts.
- `Simulator::start` (`simulator.rs`): Start playback of the named script from the beginning.
- `Simulator::stop` (`simulator.rs`): Stop playback and reset the simulator to `Idle`.
- `Simulator::pause` (`simulator.rs`): Pause playback, freezing `elapsed` and the step index.
- `Simulator::resume` (`simulator.rs`): Resume paused playback from the current position.
- `Simulator::is_running` (`simulator.rs`): Return `true` if the simulator is in the `Running` state.
- `Simulator::is_paused` (`simulator.rs`): Return `true` if the simulator is in the `Paused` state.
- `Simulator::is_complete` (`simulator.rs`): Return `true` if all steps in the active script have been dispatched.
- `Simulator::current_step` (`simulator.rs`): Return the index of the next step to be dispatched.
- `Simulator::step_count` (`simulator.rs`): Return the total number of steps in the active script.
- `Simulator::current_script` (`simulator.rs`): Return the name of the currently active script.
- `Simulator::elapsed_time` (`simulator.rs`): Return the seconds elapsed since playback started.
- `Simulator::update` (`simulator.rs`): Advance the playback clock by `dt` seconds and dispatch all due steps.
- `Action::parse_action` (`step.rs`): Parse an action string into the corresponding variant.
- `Action::as_str` (`step.rs`): Return the canonical lowercase string representation of this action.
- `Step::new` (`step.rs`): Create a new Step with required fields set and all optional fields at defaults.
- `Step::effective_scancode` (`step.rs`): Return the effective scancode for a key event.

## Lua API Reference

- Binding path(s): `src/lua_api/automation_api.rs`
- Namespace: `lurek.automation`

### Module Functions
- `lurek.automation.load`: Loads a named script from a Lua data table containing a steps array.
- `lurek.automation.unload`: Removes a loaded script by name, returning true if it existed.
- `lurek.automation.hasScript`: Returns true if a script with the given name is registered.
- `lurek.automation.getScripts`: Returns an array of all registered script names.
- `lurek.automation.start`: Starts playback of the named script from the beginning.
- `lurek.automation.stop`: Stops playback and resets the simulator to idle.
- `lurek.automation.pause`: Pauses playback at the current step position.
- `lurek.automation.resume`: Resumes playback from a paused position.
- `lurek.automation.update`: Advances the playback clock by dt seconds, dispatching due steps.
- `lurek.automation.isRunning`: Returns true if the simulator is actively playing a script.
- `lurek.automation.isPaused`: Returns true if playback is currently paused.
- `lurek.automation.isComplete`: Returns true if all steps in the active script have been dispatched.
- `lurek.automation.getCurrentStep`: Returns the index of the next step to be dispatched.
- `lurek.automation.getStepCount`: Returns the total number of steps in the active script.
- `lurek.automation.getCurrentScript`: Returns the name of the active script, or nil if idle.
- `lurek.automation.getElapsedTime`: Returns seconds elapsed since playback started.
- `lurek.automation.loadFromToml`: Parses a TOML string and registers it as a named script.

## References

- `event`: Imports or references `event` from `src/event/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/automation/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
