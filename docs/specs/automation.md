# `automation` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.automation` |
| **Source** | `src/automation/` |
| **Rust Tests** | tests/rust/unit/automation_tests.rs |
| **Lua Tests** | tests/lua/unit/test_automation.lua |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The automation module replays scripted input into the engine event queue. It exists so tests, demos, and developer tooling can drive the game exactly as if keys, mouse movement, clicks, wheel events, or text input came from real hardware.

Its core abstraction is a named Script made of timed Step records. A Simulator owns those scripts, advances playback over time, and turns each due Step into a synthetic event for the shared EventQueue. That keeps automation compatible with the rest of the input stack instead of inventing a separate test-only path.

This module does not own input state, window events, or general scheduling. Real hardware capture and input state live in input and the app loop, while generic timers and callback scheduling belong in timer. Automation only manages script data, playback state, and event injection.

**Scope boundary**: This module currently depends on `event`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.automation.* (Lua API — src/lua_api/automation_api.rs)
    |
    v
src/automation/mod.rs
    |- script.rs - script
    |- simulator.rs - simulator
    |- step.rs - step
```

---

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root that documents the automation surface and re-exports Script, Simulator, Action, and Step. This is the shortest entry point for understanding what the module exposes to other Rust code. |
| `script.rs` | Defines Script, the named container for a time-sorted list of Steps. It also enforces the step-count cap and supports TOML-based script loading. |
| `simulator.rs` | Defines Simulator and its internal playback state machine. This is the runtime engine that loads scripts, starts and stops playback, advances elapsed time, and pushes synthetic events into the EventQueue. |
| `step.rs` | Defines the Action enum and Step record that describe a single timed automation action. This file is the schema for every script entry regardless of whether it comes from Lua, TOML, or Rust-side tests. |

---

## Submodules

### `automation::script`

Defines Script, the named container for a time-sorted list of Steps. It also enforces the step-count cap and supports TOML-based script loading.

- **`Script`** (struct): A named simulation script containing an ordered sequence of timed steps.

### `automation::simulator`

Defines Simulator and its internal playback state machine. This is the runtime engine that loads scripts, starts and stops playback, advances elapsed time, and pushes synthetic events into the EventQueue.

- **`Simulator`** (struct): Automated input simulation engine.

### `automation::step`

Defines the Action enum and Step record that describe a single timed automation action. This file is the schema for every script entry regardless of whether it comes from Lua, TOML, or Rust-side tests.

- **`Action`** (enum): The action type for a simulation step.
- **`Step`** (struct): A single timed step in a simulation script.

---

## Key Types

### Public Types

#### `Script`

Named automation script with optional human-readable metadata and an ordered Vec of Step values.

#### `Simulator`

Playback engine that owns the script registry, current script selection, elapsed time, next-step index, and running or paused state.

#### `Step`

One timed automation record with optional fields for key names, scancodes, mouse coordinates, wheel deltas, button data, and text input.

#### `Action`

Enum of supported automation actions such as keypress, mousemove, mousepress, and wait.

---

## Lua API

Exposed under `lurek.automation.*` by `src/lua_api/automation_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.automation.load` | Loads a named script from a Lua data table containing a steps array. |
| `lurek.automation.unload` | Removes a loaded script by name, returning true if it existed. |
| `lurek.automation.hasScript` | Returns true if a script with the given name is registered. |
| `lurek.automation.getScripts` | Returns an array of all registered script names. |
| `lurek.automation.start` | Starts playback of the named script from the beginning. |
| `lurek.automation.stop` | Stops playback and resets the simulator to idle. |
| `lurek.automation.pause` | Pauses playback at the current step position. |
| `lurek.automation.resume` | Resumes playback from a paused position. |
| `lurek.automation.update` | Advances the playback clock by dt seconds, dispatching due steps. |
| `lurek.automation.isRunning` | Returns true if the simulator is actively playing a script. |
| `lurek.automation.isPaused` | Returns true if playback is currently paused. |
| `lurek.automation.isComplete` | Returns true if all steps in the active script have been dispatched. |
| `lurek.automation.getCurrentStep` | Returns the index of the next step to be dispatched. |
| `lurek.automation.getStepCount` | Returns the total number of steps in the active script. |
| `lurek.automation.getCurrentScript` | Returns the name of the active script, or nil if idle. |
| `lurek.automation.getElapsedTime` | Returns seconds elapsed since playback started. |
| `lurek.automation.loadFromToml` | Parses a TOML string and registers it as a named script. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.automation.
if lurek.automation then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 3 |
| `enum` | 1 |
| `fn` (Lua API) | 17 |
| **Total** | **21** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `event` | Imports or references `event` from `src/event/`. | Cross-group dependency from Feature Systems to Core Runtime. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/automation/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
